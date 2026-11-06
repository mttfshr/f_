# f_vf_stamp

**Type:** Processor: a stateless, gated injector with an optional vecfield inlet. Outlets: ink and an impulse vecfield.
**Status:** Built 2026-11-05. Benches green, live looks passed (Matt, chat, 2026-11-05: "passes - seems to be working really well"; no dial, range or default changed).

_Reference written 2026-11-06 from `src/f_vf_stamp/` (definition and codebox), `.specify/f_vf_stamp/{spec,plan,tasks}.md` (gates G1-G8, ADR-1 to ADR-9) and the module's tests._

---

## What it does

A **stamp**: the missing drop of ink. A texture says where and what colour, a held press says when. While Stamp is held, the stamp's shape flows out as ink and as a push; release and it stops.

- **Inlet 0** is the stamp. Its luma is the mask, its RGB the ink. Control messages arrive here too. The module does not make shapes: they come from upstream (`f_ngon`, `f_grain`, `f_vf_seeds`, a camera).
- **Inlet 1** is an optional vecfield. Connected, the impulse is that field, masked by the stamp. Empty, the impulse comes from the stamp's own edge: **Radial** pushes out from it, **Swirl** turns around it.

The module keeps nothing. Persistence is downstream: `f_vf_advect` keeps the ink, `f_vf_fluid` keeps the momentum. A hold is a faucet or a sustained jet, a tap is a kick. Position is live from the texture, so a moving source with Stamp held paints a trail.

With nothing on inlet 0 it stamps nothing: black ink, a neutral impulse.

---

## Signal Flow

Inlet 0: stamp texture plus the control messages. Inlet 1: vecfield. Outlet 1: ink. Outlet 2: impulse vecfield.

```
r draw -> stamp (first input, a trigger the codebox does not read)
inlet 0 -> vs_inState -> stamp (second input)      inlet 1 -> vs_inState -> stamp (third input)
Stamp button / `stamp` message -> gate -> stamp_gate -> envelope -> `param env` -> stamp
stamp -> outlets 1, 2                              r dim -> stamp (render size)
```

One `jit.gl.pix` stage, float32, at the render size. It renders once per draw, connected or not, because `r draw` is its trigger and the textures sit on cold inputs (plan ADR-9, the `f_wave_field` `enc` pattern). The connected flags `src_stamp` and `src_vec` come from each inlet's `vs_inState`.

---

## Parameters

| Name | Type | Range | Default | Description |
|---|---|---|---|---|
| `threshold` | float | 0–1 | 0.05 | Luma above which the stamp covers. Low, so saturated reds and blues stamp too |
| `softness` | float | 0–1 | 0.1 | Width of the mask's edge, in luma. Does nothing to a hard-edged stamp |
| `amount` | float | 0–4 | 1 | Ink strength. Above 1 lifts a short tap; `f_vf_advect` clamps after adding |
| `force` | float | 0–2 | 1 | Impulse strength, for inlet 1's field and the stamp's own push alike |
| `rim` | float | 0.005–0.05 | 0.015 | Width of the push around the stamp's edge, in frame widths. Inert with a field on inlet 1 |
| `attack` | float | 0–60 | 0 | Envelope rise, in frames. 0 = at once |
| `release` | float | 0–120 | 8 | Envelope fall, in frames. 0 = at once |
| `invert` | text button | Norm / Inv | Norm | Inv stamps where the texture is dark |
| `impulse` | text button | Radial / Swirl | Radial | The push with nothing on inlet 1. Inert with a field connected |
| `stamp` | ubutton / message | — | — | A **held press**. The button is gate 1 on mouse-down and 0 on mouse-up. The `stamp` message is a tap; `stamp 1` / `stamp 0` press and release |
| `bypass` | toggle | 0/1 | 0 | Outlet 1 passes inlet 0, outlet 2 passes inlet 1 (neutral if empty). The gate and envelope are ignored, so **a bypassed stamp hands the whole texture downstream as ink** |

Internal, never set by hand: `env`, `stamp_gate`, `src_stamp`, `src_vec`, `bypass_gate`, `width`, `height`.

### Press and envelope

- **Press.** The `gate_button` schema type (`build/spec.md`): a `ubutton` over a panel face, because a plain button reports no release. A release lands on the third draw bang after it, so any press is seen by at least two rendered frames. A new press cancels a pending release. Counters, never timers. There is no stamp on load.
- **Envelope.** One-pole per draw in the patcher: `env += (gate - env) * k`, `k` = 1 at 0 frames, else `1 - exp(-1 / frames)`, attack's while rising and release's while falling. Below 0.001 `env` snaps to 0, because a one-pole never gets there and the idle outputs should be exact. At `release` 8 a tail lasts about 55 frames.
- `stamp_gate` feeds the envelope only; the codebox reads `env`.

---

## Algorithm

Per pixel, once per draw:

1. **Coverage.** `cov = smoothstep(max(threshold - softness/2, 0), threshold + softness/2, luma)`, Rec.709 luma, flipped by `invert`, forced to 0 with nothing on inlet 0. The clamp at 0 means black never stamps at any `softness`.
2. **Ink.** `(rgb * cov * amount * env, 1)`. RGB carries the mask and A stays 1, because `f_vf_advect` adds all four channels with no alpha gating.
3. **Impulse, field connected.** `(field - 0.5) * 2 * cov * env * force`. The flag decides, never the value: an unconnected inlet is black, which would decode to a full -1 vector.
4. **Impulse, nothing connected.** The plain wide central difference of `cov`, negated, no divide: `v = -(cov(x+s) - cov(x-s), cov(y+s) - cov(y-s))`, `s = max(1, round(rim * width))` texels on both axes, then `* env * force`. Swirl is `(-v.y, v.x)`. Neighbours are integer texel indices with a periodic wrap, read at texel centres.
5. **Encode.** `v * 0.5 + 0.5` clamped to 0..1, B = 0.5, A = 1, so each component clips past the range at high `force`.
6. **Containment.** Non-finite texels are zapped on read (stamp to 0, field to 0.5), also under bypass.

---

## Notes

- **Radial or Swirl into `f_vf_fluid`.** A radial field is curl-free, so `project` at 1 removes it and a swirl survives. That is why both exist. By the projection formula about 10% of radial energy survives at wider reach (mirror only: viscosity and `taps` not modelled).
- **`softness` and `rim` are different things.** `softness` acts in luma, so it changes nothing on a hard-edged stamp; the band's width comes from `rim`, whatever the render size (rim strength is about `2 * rim` in frame units).
- **Saturated colours at the defaults.** Pure blue stamps at 0.81, not full: its luma of 0.0722 sits inside the 0 to 0.1 band (mirror).
- **`softness` past twice `threshold`.** The band's lower edge is clamped at 0, so the band is narrower than `softness` and no longer centred on `threshold`.
- **An irregular edge is upstream's job.** `edge` and `seed` dials were cut: noise on a threshold cannot move a 0-to-1 step.
- **Ink per stamp** is `f_vf_advect`'s `injection` times the envelope's integral; **momentum per stamp** is `f_vf_fluid`'s `force` times it.
- **Cost.** Not measured (NF-001 asks for a 1080p figure). One pass, five coverage reads of three channel samples each.

## Known issues / open

- **Menu category** (G8): placed under Adapters by Claude on Matt's "complete phase 3", with `G-menu` still open; his to move. Moving it is one line in `menu.py` and the README table.
- **Swirl's on-screen direction** against `f_vf_vortex`'s `curl` has not been compared.
- **`tests/contracts/test_module_contracts.py`** lists `stamp` as a known issue: the path to the stage is one hop past the checker's depth of 6. Left as is (Matt, 2026-11-05).
- **`vs_inState`'s `src_stamp`** cannot be proven by the module bench (the harness cannot feed inlet 1 alone); Matt's live look passed it.

## Verification

- `tests/modules/vf_stamp/test_vf_stamp.py`: NumPy mirror, 21 tests (closed forms, idle exactness, linearity, the stencil's identities, periodic wrap, mutations).
- `bench_vf_stamp.py`: GPU against mirror, 10/10, worst error 1.8e-7 (log `tests/logs/20261105-215536-bench.log`). Every Param shown to take a message. Its resampled row only covers a 2:1 upscale.
- `bench_vf_stamp_module.py`: the shipped patcher, 7/7 (log `tests/logs/20261105-215636-bench.log`): hold, release to exact idle, tap, cancel, the envelope, connected field, swirl.
- `tests/contracts/bench_modules.py`: 2/2 (log `tests/logs/20261105-215801-bench.log`), bypass on both outlets.
- `tests/build/test_build_gate_button.py`: the press logic over the built cords, 10/10.
- Live (Matt, 2026-11-05): T030-T032 and the `src_stamp` look.

## References

Original to this library: the module was designed in development and takes no code or formula from an outside source.

- Central differences, smoothstep and the one-pole are standard. Rec.709 luma weights: ITU-R BT.709.
- The Helmholtz reasoning behind Radial and Swirl follows `f_vf_fluid`'s projection (`f_vf_fluid.md`).
- `.specify/f_vf_stamp/{spec,plan,tasks}.md`; `ideas/f_vf_stamp.md` (was `f_splat`). Related: `f_vf_advect.md`, `f_vf_fluid.md`, `f_wave_field.md` (the held press), `f_vecfield_type.md`.

## Source Files

`src/f_vf_stamp/definition.py`, `src/f_vf_stamp/codebox_stamp.gen`, `package/patchers/f_vf_stamp.maxpat`, `tests/modules/vf_stamp/`.
