# f_wave_field

**Type:** Processor with two optional texture inlets (it works alone as a generator) — **temporal / has memory**. Outlets: luma and a gradient vecfield.
**Status:** Built; redesigned 2026-11-04 (outline strike, LFO inlet, held press). Live look passed (Matt, 2026-11-04 22:59, his word only: which sub-checks he looked at is not recorded). Offline mirror and both live benches green 2026-11-04. README lists it with ⚠ Unverified (this doc and the helpfile are new; the cost was not re-measured after the redesign).

_Reference written 2026-11-04 from `src/f_wave_field/` (definition + codeboxes), `.specify/f_wave_field/{spec,tasks}.md` (decisions D1-D14) and the module's tests. Where the 2026-10-23 spec and the shipped module differ, this doc follows the shipped module._

---

## What it does

A spectral **wave field**: ripples, rings and plate waves on a 256 × 256 periodic sheet. The waves travel, interfere, decay, wrap around the frame or die at absorbing borders. Unlike `f_chladni` (a fixed standing figure), `f_ks` (chaos) and `f_vf_fluid` (flow), it propagates interfering waves, and it keeps whatever you strike or push into it.

Two inlets say two different things:

- **Inlet 0 says WHERE.** A texture here is a force field (mid-grey does nothing, brighter pushes up, darker pushes down) and also the shape that **Strike** hits: the strike lands on the *outlines* of the texture (its edges), not on its fill. With nothing connected, Strike hits a point at the frame centre.
- **Inlet 1 says WHEN.** A texture here is an LFO, a time function `T` read per pixel (a uniform texture and a spatial one both work). It scales the texture push and the strike. With no LFO connected `T` = 1.

The module has no internal oscillator. With nothing connected it **rings once from the load strike and decays**; it does not keep going (the 2026-10-23 point sine exciter was removed, D7).

Outlets: **luma** (the height `u`) and a **gradient vecfield** (∇u, for `f_caustic`, `f_vf_warp`, `f_vf_advect`).

The solver is a fixed 256 × 256 float32 grid. Only the last stage follows the render size, so both outlets are normal render-size textures.

---

## Signal Flow

Inlet 0: texture (force / outline source) plus the control messages. Inlet 1: LFO texture. Outlet 1: luma. Outlet 2: vecfield.

```
hold -> pass (in 1)         hold -> real (in 3, read only to keep the inlet; its G is unused)
pass -> fx -> fy -> spec -> iy -> ix -> real       (real -> hold: the feedback edge)
                                         real -> enc (render resolution) -> outlets 1, 2
inlet 0 -> vs_inState -> real (in 2)      inlet 1 -> its own vs_inState -> real (in 4)
```

| Stage | Job |
|---|---|
| `hold` | One-frame delay, the loop break |
| `pass` | Holds last frame's state, or clears it while `reset_gate` is 1. Strips G and A so the DFT sees only `u` (R) and `v` (B) |
| `fx` `fy` `iy` `ix` | Separable DFT, two complex fields per pass (`u` in R,G; `v` in B,A). Generated from the shared template (`src/f_wave_field/gen_dft.py`) |
| `spec` | The exact per-bin step of `u_tt + 2β u_t + ω² u = 0` in all three damping regimes; the k = 0 bin is zeroed |
| `real` | Force inlet, LFO, the strike pin, edge sponge, containment |
| `enc` | Periodic bilinear upsample to render size, `tanh` luma map, `tanh` gradient vecfield, bypass gate |

The `r draw` bang goes to `pass` and `enc`; the feedback arrives on cold inlets, so the loop advances exactly once per rendered frame. The connected flags `src_force` and `src_lfo` (from each inlet's `vs_inState`) gate the two reads: an unconnected inlet is `vs_black` = 0, which would otherwise decode as a full -1 force.

---

## Parameters

| Name | Type | Range | Default | Description |
|---|---|---|---|---|
| `speed` | float | 0–0.5 | 0.25 | Phase velocity at the middle scale (frame widths per second). 0 with `ring` makes independent resonators |
| `damping` | float | 0.001–5 | 0.2 | How fast waves die out. The bottom is a float32 floor (T003), so the field always settles; high values go syrupy |
| `dispersion` | float | 0.5–2 | 1 | How wavelength sets speed: 1 ordinary waves, 2 plate-like (short ripples run ahead), 0.5 long swells outrun short ripples |
| `ring` | float | 0–50 | 0 | A tone every point rings at, whatever the wavelength |
| `edge` | float | 0–1 | 0.5 | Absorbing borders: 0 wraps around, higher dies at the edge without reflecting (internal Param `edge_amt`: `edge` is a Gen operator name) |
| `force` | float | 0–1.5 | 1 | How hard the texture on inlet 0 pushes. Past 1 it boosts a dim texture |
| `strength` | float | 0–1 | 1 | How hard Strike presses: the target height of the pin. 0 = no strike |
| `gain` | float | 0–10 | 1 | Output strength before the soft `tanh` limiter |
| `lmode` | text button | LFO uni / LFO bi | uni | Reads the LFO raw 0..1 (uni, can only add) or rescaled to -1..1 (bi, mid-grey neutral). Modelled on `f_weave`'s `mmode` |
| `strike` | ubutton / message | — | — | A **held press**. The button sends gate 1 on mouse-down and 0 on mouse-up. The `strike` message is a tap; `strike 1` / `strike 0` press and release. Fires once on load |
| `reset` | button / message | — | — | Clears the field. Fires once on load (after 200 ms) |
| `bypass` | toggle | 0/1 | 0 | Luma black alpha 1, vecfield 0.5 / 0.5; the solver keeps running underneath |

Internal, never set by hand: `reset_gate`, `strike_gate`, `src_force`, `src_lfo`, `bypass_gate`. `dt` is a fixed codebox constant (1/60 s per draw, gate G3), not a dial. `X`, `Y`, `Freq`, `Amp` no longer exist.

### Strike and reset logic

- **Press and release.** A `ubutton` over a panel face: outlet 1 (mouse-down) sends `param strike_gate 1`, outlet 0 (mouse-up) starts a release. A release never lands at once: it is applied on the third draw bang after it, so a press is seen by at least two rendered frames (about 33 ms of release latency at 60 fps). A new press cancels a pending release. The `strike` message is decoded by `[sel bang 1 0]`.
- **Load.** After 200 ms the module resets and presses Strike; the press is released after the reset has finished plus the release delay.
- **Reset** holds `reset_gate` for two draw bangs (never a timer); the pin waits while it is on.

---

## Algorithm

Per frame, on `u` (position) and `v = du/dt`:

1. **Spectral step, exact per bin.** `ω² = ring² + (speed·kref·(|k|/kref)^dispersion)²`, `β = damping + ν|k|²` (`ν` = 1e-5, `kref` = 2π·8), then the closed-form damped-oscillator update. Underdamped, critical and overdamped regimes are branch-free (no `sqrt` of a negative). The DC bin is zeroed.
2. **Force.** With inlet 0 connected: `v += force · 2 (tex − 0.5) · T · dt`. A uniform force only feeds the DC bin, which step 1 removes.
3. **The pin (Strike).** While `strike_gate` is 1 and no reset is running: `u += pw (target − u)` and `v *= 1 − pw`, with `target = strength · amp · T`. With inlet 0 connected `pw` is the **outline mask** (`|I(x+1) − I(x−1), I(y+1) − I(y−1)|` of the R channel, one solver texel either side, clamped 0..1) and `amp` = 1; with nothing connected `pw` is a Gaussian at the frame centre (σ = 0.02) and `amp` = 4. So the envelope's attack and decay are the luma of `T` over the held frames, the sustain is how long the button is held, and the release is the solver ringing out at its own Speed and Damp. No gain constant: the amplitude is in field units.
4. **Edge sponge.** `exp(−rate·dt)` on `u` and `v`, rate = `edge`·20 × a smoothstep profile over a 0.12-wide border band.
5. **Containment.** Non-finite or huge values become 0, then ±100.
6. **Encode.** Luma `0.5 + 0.5·tanh(gain · 0.5 · u)`; vecfield R,G `0.5 + 0.5·tanh(gain · 0.05 · ∂u)`, B = 0.5, A = 1 (gate G2; the scales are placeholders that Matt's look accepted: T030, T037).

---

## Notes

- **The pin replaces, it does not add (D13, Matt).** A press on a ringing field overwrites `u` at the pinned texels and kills `v` there, so held outlines behave like a rigid edge and reflect waves. It is idempotent, which is why no strike counter or memory exists.
- **A tap is two to three pinned frames, not one impulse** (inferred from the release delay, not measured). A single pinned frame on a field at rest equals the old one-frame impulse (mirror test).
- **A uni LFO at 0 under a held press pins the outline to rest**, so it acts as a damper rather than doing nothing (inferred from the maths; the mirror pins to `strength·amp·T`). A bi LFO at mid-grey does the same.
- **The connected texture is both the force field and the outline source** (observed offline, 2026-11-04): a black-and-white inlet at Force 1 also pushes the field (black down, white up). Force 0 gives a pure strike. Whether that coupling is wanted is open.
- **Outline band width.** The outline is read at the inlet's own resolution with `nearest()`, so an inlet smaller than 256 gives a band about two solver texels wide at each of *its* texel boundaries (inferred; not covered by the mirror).
- **LFO with no texture on inlet 0** does nothing to the push (no force without inlet 0); it still scales a strike. A spatial LFO that should act as a force field goes on inlet 0.
- **Speed ceiling.** Aliasing at the 256 solver corner limits useful `speed` to about 0.166 (T004 finding); the dial itself reaches 0.5.
- **`dt` appears as a Param in two stages** (fixed per-frame step, G3); the offline contracts list this as a documented KNOWN_ISSUE.
- **Energy.** `damping` has a 1e-3 floor so float32 round-off cannot grow energy; tested over 10,000 frames in the mirror (T003).
- **Cost.** 2.52 ms/frame at 256² on the bench (T020, 2026-10-25), measured BEFORE the redesign. The real stage changed (outline mask, LFO read, pin) and the `@slow` cost bench was not re-run, so the current cost is unmeasured. The M1 is unmeasured.

## Known issues / open

- **Outline-and-force from one texture** (above): Matt's call.
- **Cost after the redesign** and the 100-frame GPU soak (`@slow`) have not been re-run.
- **`bench_modules` (module contract bench)** has not been re-run since the redesign.
- **Spec:** `.specify/f_wave_field/spec.md` carries a 2026-11-04 revision note; the 2026-10-23 sections are kept and marked where superseded.
- **`f_cymascope` front end (T041):** now produces an LFO texture for inlet 1 (and strike triggers) instead of `frequency` and `amplitude`; not started.

## Verification

- `tests/modules/wave_field/test_wave_field.py`: NumPy mirror, 47 tests (the three damping regimes against a float64 matrix exponential, energy conservation, dispersion, superposition, DC zeroing, periodic wrap, sponge, outline mask, LFO uni / bi, the pin: following an enveloped level frame by frame, replace-not-add, release without energy gain).
- `bench_wave_field.py`: GPU against mirror, 11/11 (log `tests/logs/20261104-231254-bench.log`; needed the four-input bench harness added 2026-11-04). `@slow` tests skipped.
- `bench_wave_field_module.py`: the real patcher, 2/2 (field finite, bounded, opaque; the load strike gives contrast and the field evolves).
- `tests/contracts/test_module_contracts.py`: 9/9 offline.

## References

- `.specify/f_wave_field/{spec,tasks}.md` (Phase 0 record, decisions G1-G5 and D1-D14); `ideas/f_wave_field.md` (mined from michaelerule/webgpgpu `Example_24`, `Vision_006`, `Vision_010`, `Vision_014`).
- The DFT stages come from `src/f_vf_fluid/gen_dft.py` through `src/f_wave_field/gen_dft.py`. Related: `f_ks.md` (same solver architecture), `f_chladni.md`, `f_vecfield_type.md`.

## Source Files

`src/f_wave_field/definition.py`, `src/f_wave_field/codebox_{pass,dft_fx,dft_fy,dft_iy,dft_ix,spec,real,enc}.gen`, `package/patchers/f_wave_field.maxpat`, `tests/modules/wave_field/`, `.specify/f_wave_field/{spec,tasks}.md`.
