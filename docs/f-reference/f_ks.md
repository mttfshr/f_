# f_ks

**Type:** Generator (no texture inlet, luma out) — **temporal / has memory**
**Status:** Built and benched; tier-3 tuning (output mapping, `rate` feel, name) still open. README lists it with no ⚠.

_Reference written 2026-10-22 from `src/f_ks/` (definition + codeboxes), `.specify/f_ks/{spec,tasks}.md` and the module's tests. Where the spec and the shipped module differ, this doc follows the shipped module._

---

## What it does

A 2D **Kuramoto-Sivashinsky** generator, solved on the GPU: a self-sustaining chaotic pattern (cells, ridges, spiral-ish defects) that keeps evolving with no input and never settles. Nothing needs to drive it. It is the library's only generator with memory and chaos: `f_chladni` is a fixed modal pattern, and the noise generators have no memory.

It outputs a grayscale luma texture. It does not output a vecfield.

Typical use: patch it alone into a preview for a living texture, or use it as a mask, displacement source or `f_vf_fieldmap` input (a scalar texture becomes a vecfield by gradient).

The solver is a fixed **256 × 256** float32 grid on a periodic domain. Only the last stage follows the render size, so the outlet is a normal render-size texture whatever the solver size.

---

## Signal Flow

One control inlet (messages and the draw bang only, no texture), one outlet.

```
hold -> pass (in 1)        seed -> pass (in 2)
pass -> fx -> fy -> spec -> iy -> ix -> nl        (nl -> hold: the feedback edge)
                                          nl -> enc (render resolution) -> outlet
```

| Stage | Job |
|---|---|
| `hold` | Identity. One-frame delay, the loop break |
| `seed` | Deterministic arithmetic hash noise (no `sin()`), changed by `salt` |
| `pass` | Holds last frame's state, or replaces it with `(2·noise − 1)·amp` when `reseed` = 1. Also reseeds any texel of the feedback that is exactly 0 (self-heal, see Notes) |
| `fx` `fy` | Forward DFT, separable, one axis per pass |
| `spec` | The exact linear step per Fourier bin; zeroes the k = 0 bin |
| `iy` `ix` | Inverse DFT, separable |
| `nl` | Real-space nonlinearity plus containment (NaN/Inf zap, ±100 clamp) |
| `enc` | Periodic bilinear upsample to render size, luma map, `sharp` blend, bypass gate |

The `r draw` bang goes to `seed`, `pass` and `enc`; the feedback and the noise arrive on cold inlets, so the loop advances exactly once per rendered frame. The output size follows the render size (`r dim` into `enc`, `@adapt 0`, the `vs_mixer_3` convention).

---

## Parameters

| Name | Type | Range | Default | Description |
|---|---|---|---|---|
| `rate` | float | 0.0–0.0625 | 0.05 | Time step `dt` per frame: how fast the pattern evolves. The top of the range is the measured stability ceiling at N = 256 (0.075 diverged), so no setting blows the solver up |
| `scale` | float | 25–100 | 50 | Domain size `L`. Bigger = finer grain, more cells across the frame; smaller = bold, coarse cells. The pattern re-forms when it moves. 0.0625 held at every L from 25 to 150 and 0.075 up to 100; L = 12.5 is too small to sustain a pattern |
| `sharp` | float | 0.0–1.0 | 0.0 | Edge sharpness in `enc`: 0 = the soft map, 1 = hard-edged cells and ridges |
| `reset` | button / message | — | — | Reseeds the field from fresh noise. Fires once on load (after 200 ms). Also accepted as a `reset` message on the control inlet |
| `bypass` | toggle | 0/1 | 0 | Black, alpha 1, on the outlet. The solver keeps running underneath |

Internal, never set by hand: `reseed`, `salt` (reset logic), `bypass_gate` (bypass jsui). `amp` (the seed amplitude, default 1) is a codebox `Param` with no control, kept so the bench can set it (tasks T021 lists it in KNOWN_ISSUES).

Reset logic: button, `reset` message or load fires `[t b b b]`: restart the frame count, send `param reseed 1` to `pass`, and count up `salt` into `seed` so each reset is a new pattern. `reseed` is held for three draw bangs (never a timer): if rendering has not started yet the reseed waits, and at least two rendered frames see it.

---

## Algorithm

Each frame, on `u` (the state):

1. **Linear step, exact per bin.** `u_hat *= exp((K2 − K2²) · dt)` with `K = 2π·m / L` and `K2 = kx² + ky²`. The k = 0 bin is set to zero every frame.
2. **Nonlinear step, real space.** `u_new = u_lin − dt · 0.5 · |∇u_lin|²`, central differences with periodic indices, `dx = L / N`.
3. **Containment.** A non-finite result becomes 0 and the value is clamped to ±100 (measured |u| is 15 to 20 at the dt ceiling, so the clamp is inactive in normal running).
4. **Encode.** `soft = clamp(0.5 + 0.25·u, 0, 1)`, `crisp = smoothstep(0.46, 0.54, soft)`, `lum = mix(soft, crisp, sharp) · (1 − bypass_gate)`, replicated to RGB, A = 1. Non-finite maps to 0.5.

The mean-zeroing is mandatory, not a toggle: the nonlinearity integrates domain-negative, so the field mean otherwise drifts downward (measured −0.2 to −15 over 200 steps in the spike).

---

## Notes

- **Zero is a fixed point.** Both terms vanish at u = 0, so a zero state sits frozen forever. The module never seeds from zero. `pass` also reseeds any feedback texel that is exactly 0, which a live KS field never holds in float32; this recovers from a fresh module, a GL context rebuilt by a window-mode change (floating ↔ fullscreen) or a texel the `nl` stage zapped.
- **A reset is near-flat for about a second.** White-noise energy sits in wavenumbers the linear step kills, and the unstable band holds about 0.2%. Measured luma std after a reset: 0.011 at frame 30, 0.095 at 240, 0.435 at 600. Seed shape and warm-up are an open tier-3 question (T012).
- **The output map saturates** at luma std 0.435 (the `0.5 + 0.25u` placeholder hard clamp). The final mapping is Matt's call.
- **Bypass** follows `f_chladni`, the other generator with no texture input: black with alpha 1, solver running, so releasing bypass resumes a warm field (decided 2026-10-21).
- **The `rate` dial is `dt` directly.** No patcher-side clamp exists; the dial range ends at the stability ceiling. The dt ceiling depends on resolution: at N = 256, the largest dt that survived every seed was 0.0625 and the smallest that failed any was 0.09375 (`ks-lbm-3`, 2 seeds, 2000 frames, L = 50; the tighter follow-up `ks-limits-2` was queued and `tasks.md` records no result for it). The spec's original dt0 of 0.1 was above the ceiling.
- **Chaos limits verification.** Pixel comparison against the mirror is a short-horizon check (30 frames differ by 4.6e-7, 100 frames by 2.3e-6); longer runs compare statistics.
- **Cost.** 2.39 ms/frame for the whole chain at 256 on the bench (DFT passes about 0.5 ms each; small stages are upper bounds of 0.06–0.10 ms). The 256² versus 128² cost check in a real Vsynth patch (T006) has not been run.

## Known issues / open

- **Name `f_ks` is a placeholder** (T010).
- **Output mapping, `rate` default, reset warm-up** are tier-3 decisions (T012, T030).
- **Render-size following needs a live look:** the output size follows the render size via `r dim`, which still needs a check in Vsynth (T022).
- **Spec drift:** `.specify/f_ks/spec.md` still says "Draft — not yet built", describes a `rate` multiplier with an internal clamp (the shipped `rate` is `dt` itself) and a 128² fallback. `tasks.md` is the live record.
- **No helpfile, no reference doc until this one.** Menu placement and README wording are still T040.

## Verification

- `tests/modules/ks/` — NumPy mirror, 17 tests (closed forms: single-mode rate, mean after the nonlinear update, the u = 0 fixed point), mutants 27/30 (3 survivors are fast-path artifacts, unreviewed).
- `tests/modules/ks/bench_ks.py` — GPU against mirror, 9/9 with `--slow`: spec stage 7.8e-8 relative with the DC bin exactly 0; `nl` 2.4e-7; `enc` 1.6e-6 at off-size render targets.
- `tests/modules/ks/bench_ks_module.py` — the real patcher, 2/2: seeds on load, grows to contrast, evolves.
- Module contract bench: bypass expectation black, A = 1.

## References

- Kuramoto-Sivashinsky equation, solved with the exponential-linear / explicit-nonlinear split. Research notes: `ideas/ceyron_simulation_scripts_notes.md` section 3; stability spike `tests/records/spike_ks_stability.py`, ceiling-versus-L spike `tests/records/spike_ks_ceiling_vs_L.py`.
- The DFT stages are generated by `src/f_ks/gen_dft.py` from `f_vf_fluid`'s template (code lines asserted identical).
- Related: `f_vf_fluid.md` (same solver architecture, ADR-1), `f_chladni.md` (bypass convention).

## Source Files

`src/f_ks/definition.py`, `src/f_ks/codebox_{seed,pass,dft_fx,dft_fy,dft_iy,dft_ix,spec,nl,enc}.gen`, `package/patchers/f_ks.maxpat`, `.specify/f_ks/{spec,tasks}.md`.
