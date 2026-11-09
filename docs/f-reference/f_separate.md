# f_separate

**Type:** Processor: stateless, per pixel. One texture in; four textures out (three plates and their sum).
**Status:** Built 2026-11-08. Tier 1 and both benches green (Verification below). Tuning looks passed, live by Matt 2026-11-08 (T030, T031). The panel was laid out to Matt's direction the same day: Mode in the title bar, Inks at the left, Gain, Sat and Ink in one column per ink (look passed, Matt).

_Reference written 2026-11-08 from `src/f_separate/` (definition and codebox), `.specify/stable/f_separate/{spec,plan,tasks}.md` and the module's tests._

---

## What it does

Splits a color image into up to three **spot-color plates**, one per ink, on its own outlet. It is the first stage of the print-styles family (`ideas/f_print_styles.md`). Print is a vocabulary here, for screens and projection: nothing in it aims at matching a real press.

The model is **light on black**. There is no paper: the background is black, inks are colors of light, and where they overlap they add. A pixel is `sum_i c_i * k_i`, with `k_i` the ink's color and `c_i` its coverage, 0 to 1.

- **Outlets 1 to 3** are the plates. Each is colored: its ink's color times its coverage, so a teal ink gives a teal plate. A plate beyond the `Inks` count is black.
- **Outlet 4** is the preview, the plates summed. Colors the inks cannot make shift toward ones they can, so choosing inks is a visible decision.

It is not a swizzle: an RGB swizzle gives at most three plates tied to R, G and B, where this takes any three colors.

---

## Signal Flow

Inlet 0: color texture plus the control messages. Outlets 1 to 3: plates. Outlet 4: preview.

```
inlet 0 -> separate_pix -> outlets 1, 2, 3, 4                  r dim -> separate_pix (render size)
Inks, Mode, Gain 1-3 dials -> separate_pix
swatch N (or `inkN r g b`) -> unpack -> three `prepend param inkN_c` -> separate_pix
Sat N dial -> [t b f] -> f: `saturation` -> swatch N, then b: bang -> swatch N sends its color again
loadbang -> deferlow -> `set r g b 1.` -> swatch N                       (paints the default, sends nothing)
first r draw -> onebang -> delay 100 -> bang -> swatch N                 (sends the default to the Params)
```

One `jit.gl.pix` stage, float32, at the render size. The swatches drive nine `internal` Params (`ink1_r` ... `ink3_b`), never a dial, so the display and the Params cannot disagree.

The colors go out after the first draw, not at load: a bang at load left all four outlets black on Matt's look (2026-11-08), and timing it off a draw cured that. Why a load-time message fails is inferred (too early for the pix or the swatch); no run isolated it.

---

## Parameters

| Name | Type | Range | Default | Description |
|---|---|---|---|---|
| `n_inks` | int | 1-3 | 2 | How many inks are active. Unused plates are exactly black |
| `sep_mode` | menu | Unmix / Nearest / Project | Unmix | How each pixel's coverage is decided (below) |
| `gain1` - `gain3` | float | 0-2 | 1 | Coverage gain per ink, before the clamp. Above 1 saturates a plate faster but never exceeds its ink color |
| `ink1` - `ink3` | swatch / message | r g b, 0-1 | (1, 0.25, 0); (0, 0.6, 0.6); (0.45, 0, 1) | The ink colors, colors of light. Message form: `ink1 0.2 0 0.8` |
| `sat1` - `sat3` | float | 0-1 | 1 | Saturation of each swatch's color plane: a swatch is hue by lightness at one saturation, so lower this for pastels and grays. Panel-side only, not a codebox Param |
| `bypass` | toggle | 0/1 | 0 | The source on all four outlets. Toggle only: the message route has no `bypass` selector |

Internal, never set by hand: `ink1_r` ... `ink3_b`, `bypass_gate`.

### Modes

- **Unmix** (default): the best fit of all the inks together. Round-trips exactly for colors the palette can make, but the plates depend on each other: moving one ink changes the others wherever the ink colors overlap.
- **Nearest**: each pixel goes wholly to its nearest ink, or to none when black is nearest. Flat, hard plates.
- **Project**: each ink on its own. A plate depends only on the source and its own ink, so moving one swatch never touches another plate. The cost is no exact round trip for overlapping inks: the preview can overshoot and clip, and shared channels bleed (with the default inks a teal patch gives the violet plate 0.50 through shared blue, measured on the mirror). With one ink, or orthogonal inks, Project equals Unmix.

---

## Algorithm

Per pixel, with `x` the source RGB and `K` the 3 x N matrix of active inks:

1. **Containment.** Non-finite source components are zapped to 0, also under bypass.
2. **Coverage.**
   - Unmix: `c = (K^T K + lam I)^-1 K^T x`, the inverse by cofactors, `lam = 1e-4 * trace(K^T K) / N + 1e-8`. The ridge is relative, so a dim ink is not biased, and it keeps duplicate or collinear inks finite. An inactive ink has a zero column and a 1 on the diagonal, so it decouples and comes out 0.
   - Nearest: the smallest squared RGB distance among the active inks and black wins coverage 1. Ties go to the lowest ink, and to an ink over black.
   - Project: `c_i = (k_i . x) / max(k_i . k_i, 1e-8)`.
3. **Gain and clamp.** `c_i = clamp(gain_i * c_i, 0, 1)`: one clamp, after the gain.
4. **Plates.** `plate_i = c_i * k_i`. **Preview:** the sum of the plates, clamped to 0..1. Alpha is the source's on all four.

---

## Notes

- **Reading the preview.** Unmix with fewer than three inks is a projection: what the inks cannot reach is lost and the preview shows it. Where inks sum past 1 in a channel, the preview clips.
- **A black ink** contributes nothing: its plate is black and the solve stays finite. Under Nearest it ties with black and an ink wins the tie, also black.
- **Values as given.** The maths runs on the values it receives, with no linear-light conversion (Matt, 2026-11-08, after the tuning looks).
- **One texture in, no neighbors.** Per-plate halftone, grain and misregistration are other modules' jobs (`f_screen`, `f_ink`, `f_misregister`, not built); a per-plate tone curve is `f_tone_curve` upstream.
- **Cost.** Unmeasured at 1080p (NF-001; Matt, 2026-11-08). `tests/bench.sh --slow` on `bench_separate.py` measures it. One pass, about 90 statements (per `tasks.md`).

## Known issues / open

- **The first Sat dial move shifts an ink slightly and it does not come back.** Ink 1 starts at (1, 0.25, 0) and reads (1, 0.238, 0.004) after Sat 1 goes to 0.5 and back (module bench). Inferred: the bang recomputes the color from the swatch's position. If so, a pastel set by message would also snap to the swatch's plane when its dial moves; not tested.
- **Console lines.** `method get_filterset called on invalid object`, `method gettype called on invalid object` and `patcher doesn't understand "getattr"` print when this helpfile opens. They are not specific to this module: the first two also print from `f_poincare.maxhelp` (Matt, 2026-11-08). Cause unknown (`P-console` in `.specify/gates.md`).
- **Menu category** (Color / Tone) was placed by Claude, provisional (`G-menu`).
- **Preliminary gates** in `tasks.md` (T004, T006, T007, T011) are Claude's recommendations, not yet Matt's decisions (`G-print-prelim`): the unconstrained solve then clamp is the one most likely to change if the gamut boundary looks wrong.

## Verification

- `tests/modules/separate/test_separate.py`: NumPy mirror, 13/13 (log `tests/logs/20261108-221722-offline.log`, per `tasks.md`).
- `bench_separate.py`: the real codebox against the mirror, 5/5, worst 4.8e-7 (log `tests/logs/20261108-222210-bench.log`, per `tasks.md`).
- `bench_separate_module.py`: the shipped patcher, 5/5, worst 6.6e-7 on the first green run (latest log `tests/logs/20261108-224811-bench.log`): load touching nothing, Mode and ink count, `inkN` messages, gains, the Sat dial.
- `tests/contracts/bench_modules.py`: 2/2 (log `tests/logs/20261108-224839-bench.log`), including bypass passing the source on all four outlets.
- Live (Matt, 2026-11-08): the swatch route (T009), the plates showing after `aeaf7b3`, the tuning looks (T030, T031), the Sat dial, the helpfile, the panel, a plain reopen keeping a changed swatch.

## References

Original to this library: the module was designed in development and takes no code or formula from an outside source.

- Least squares by the normal equations, and ridge (Tikhonov) regularisation, are standard linear algebra.
- The light-on-black ink model and the Nearest and Project modes were decided with Matt (`.specify/stable/f_separate/spec.md`, "Decided with Matt").
- `ideas/f_print_styles.md`; `.specify/stable/f_separate/{spec,plan,tasks}.md`. Related: `f_tone_curve.md`.

## Source Files

`src/f_separate/definition.py`, `src/f_separate/codebox_separate.gen`, `package/patchers/f_separate.maxpat`, `package/help/f_separate.maxhelp`, `tests/modules/separate/`.
