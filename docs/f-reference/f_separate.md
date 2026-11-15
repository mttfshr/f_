# f_separate

**Type:** Processor: stateless, per pixel. One texture in; four textures out (the composite, then three plates).
**Status:** Built 2026-11-08. Tier 1 and both benches green (Verification below). Tuning looks passed, live by Matt 2026-11-08 (T030, T031). Revised 2026-11-14 (Matt): three inks by default, outlet 0 the composite and 1 to 3 the plates (as `f_halftone`), and the panel an ink table in `f_halftone`'s style with each ink as H, S, L number boxes (the swatches are gone). The revision is built and tested offline; its benches and a live look are owed (Verification).

_Reference written 2026-11-08 from `src/f_separate/` (definition and codebox), `.specify/stable/f_separate/{spec,plan,tasks}.md` and the module's tests._

---

## What it does

Splits a color image into up to three **spot-color plates**, one per ink, on its own outlet. It is the first stage of the print-styles family (`ideas/f_print_styles.md`). Print is a vocabulary here, for screens and projection: nothing in it aims at matching a real press.

The model is **light on black**. There is no paper: the background is black, inks are colors of light, and where they overlap they add. A pixel is `sum_i c_i * k_i`, with `k_i` the ink's color and `c_i` its coverage, 0 to 1.

- **Outlet 1** is the composite, the plates summed. Colors the inks cannot make shift toward ones they can, so choosing inks is a visible decision.
- **Outlets 2 to 4** are the plates. Each is colored: its ink's color times its coverage, so a teal ink gives a teal plate. A plate beyond the `Inks` count is black. The order matches `f_halftone`, whose plate inlets 2-4 take them.

It is not a swizzle: an RGB swizzle gives at most three plates tied to R, G and B, where this takes any three colors.

---

## Signal Flow

Inlet 0: color texture plus the control messages. Outlet 1: composite. Outlets 2 to 4: plates.

```
inlet 0 -> separate_pix -> outlets 1, 2, 3, 4                  r dim -> separate_pix (render size)
Inks, Mode, and the ink table (H, S, L, Gain per ink) -> separate_pix
inkN_h / inkN_s / inkN_l -> hsl2rgb (in the codebox) -> ink color N
```

One `jit.gl.pix` stage, float32, at the render size. Every control is an ordinary Param with its own number box, so the ink colors are saved and can be automated like any other. The hue is in degrees and wraps; the codebox divides it by 360 for `hsl2rgb`.

Before 2026-11-14 the inks were three `swatch` boxes with a saturation dial each, sending RGB to nine internal Params, with a load-timed bang to get the defaults out (in git history). The table replaced all of it.

---

## Parameters

| Name | Type | Range | Default | Description |
|---|---|---|---|---|
| `n_inks` | int | 1-3 | 3 | How many inks are active. Unused plates are exactly black |
| `sep_mode` | menu | Unmix / Nearest / Project | Unmix | How each pixel's coverage is decided (below) |
| `gain1` - `gain3` | float | 0-2 | 1 | Coverage gain per ink, before the clamp. Above 1 saturates a plate faster but never exceeds its ink color |
| `ink1_h` - `ink3_h` | float | 0-360 | 15; 180; 267 | Ink hue in degrees (0 red, 120 green, 240 blue) |
| `ink1_s` - `ink3_s` | float | 0-1 | 1 | Ink saturation (0 is a gray) |
| `ink1_l` - `ink3_l` | float | 0-1 | 0.5; 0.3; 0.5 | Ink lightness (0 black, 0.5 the full color, 1 white). The defaults are the RGB inks (1, 0.25, 0); (0, 0.6, 0.6); (0.45, 0, 1) |
| `bypass` | toggle | 0/1 | 0 | The source on all four outlets. Toggle only: the message route has no `bypass` selector |

Internal, never set by hand: `bypass_gate`.

### Modes

- **Unmix** (default): the best fit of all the inks together. Round-trips exactly for colors the palette can make, but the plates depend on each other: moving one ink changes the others wherever the ink colors overlap.
- **Nearest**: each pixel goes wholly to its nearest ink, or to none when black is nearest. Flat, hard plates.
- **Project**: each ink on its own. A plate depends only on the source and its own ink, so moving one ink never touches another plate. The cost is no exact round trip for overlapping inks: the composite can overshoot and clip, and shared channels bleed (with the default inks a teal patch gives the violet plate 0.50 through shared blue, measured on the mirror). With one ink, or orthogonal inks, Project equals Unmix.

---

## Algorithm

Per pixel, with `x` the source RGB and `K` the 3 x N matrix of active inks:

1. **Containment.** Non-finite source components are zapped to 0, also under bypass.
2. **Coverage.**
   - Unmix: `c = (K^T K + lam I)^-1 K^T x`, the inverse by cofactors, `lam = 1e-4 * trace(K^T K) / N + 1e-8`. The ridge is relative, so a dim ink is not biased, and it keeps duplicate or collinear inks finite. An inactive ink has a zero column and a 1 on the diagonal, so it decouples and comes out 0.
   - Nearest: the smallest squared RGB distance among the active inks and black wins coverage 1. Ties go to the lowest ink, and to an ink over black.
   - Project: `c_i = (k_i . x) / max(k_i . k_i, 1e-8)`.
3. **Gain and clamp.** `c_i = clamp(gain_i * c_i, 0, 1)`: one clamp, after the gain.
4. **Plates.** `plate_i = c_i * k_i`. **Composite:** the sum of the plates, clamped to 0..1. Alpha is the source's on all four.

---

## Notes

- **Reading the composite.** Unmix with fewer than three inks is a projection: what the inks cannot reach is lost and the composite shows it. Where inks sum past 1 in a channel, the composite clips.
- **A black ink** contributes nothing: its plate is black and the solve stays finite. Under Nearest it ties with black and an ink wins the tie, also black.
- **Values as given.** The maths runs on the values it receives, with no linear-light conversion (Matt, 2026-11-08, after the tuning looks).
- **One texture in, no neighbors.** Per-plate halftone, grain and misregistration are other modules' jobs (`f_halftone`, `f_vf_erode`, `f_misregister`, not built); a per-plate tone curve is `f_tone_curve` upstream.
- **Cost.** Unmeasured at 1080p (NF-001; Matt, 2026-11-08). `tests/bench.sh --slow` on `bench_separate.py` measures it. One pass, about 90 statements (per `tasks.md`).

## Known issues / open

- **Console lines.** `method get_filterset called on invalid object`, `method gettype called on invalid object` and `patcher doesn't understand "getattr"` print when this helpfile opens. They are not specific to this module: the first two also print from `f_poincare.maxhelp` (Matt, 2026-11-08). Cause unknown (`P-console` in `.specify/gates.md`).
- **Menu category** (Color / Tone) was placed by Claude, provisional (`G-menu`).
- **Preliminary gates** in `tasks.md` (T004, T006, T007, T011) are Claude's recommendations, not yet Matt's decisions (`G-print-prelim`): the unconstrained solve then clamp is the one most likely to change if the gamut boundary looks wrong.

## Verification

- `tests/modules/separate/test_separate.py`: NumPy mirror, 13/13 (log `tests/logs/20261108-221722-offline.log`, per `tasks.md`).
- `bench_separate.py`: the real codebox against the mirror, 5/5, worst 4.8e-7 (log `tests/logs/20261108-222210-bench.log`, per `tasks.md`).
- `bench_separate_module.py`: the shipped patcher, 5/5, worst 6.6e-7 on the first green run (latest log `tests/logs/20261108-224811-bench.log`): load touching nothing, Mode and ink count, `inkN` messages, gains, the Sat dial.
- `tests/contracts/bench_modules.py`: 2/2 (log `tests/logs/20261108-224839-bench.log`), including bypass passing the source on all four outlets.
- Live (Matt, 2026-11-08): the swatch route (T009), the plates showing after `aeaf7b3`, the tuning looks (T030, T031), the Sat dial, the helpfile, the panel, a plain reopen keeping a changed swatch.
- 2026-11-14 revision (HSL table, outlet order, three inks): offline only so far (Claude): `test_separate.py` 13/13, drift, menu and conventions tests pass (log `tests/logs/20261114-214526-offline.log`). Both benches were rewritten for it (`test_hsl_params` checks the codebox's `hsl2rgb` against the standard model) and have NOT been run; the counts and logs above are from the swatch version. Not seen in Max.

## References

Original to this library: the module was designed in development and takes no code or formula from an outside source.

- Least squares by the normal equations, and ridge (Tikhonov) regularisation, are standard linear algebra.
- The light-on-black ink model and the Nearest and Project modes were decided with Matt (`.specify/stable/f_separate/spec.md`, "Decided with Matt").
- `ideas/f_print_styles.md`; `.specify/stable/f_separate/{spec,plan,tasks}.md`. Related: `f_tone_curve.md`.

## Source Files

`src/f_separate/definition.py`, `src/f_separate/codebox_separate.gen`, `package/patchers/f_separate.maxpat`, `package/help/f_separate.maxhelp`, `tests/modules/separate/`.
