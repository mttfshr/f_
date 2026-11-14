# f_halftone

**Type:** Processor: stateless, per pixel. One texture in (plus three optional plate inlets); four textures out (the screen, and its three plates).
**Status:** Built 2026-11-13 to 2026-11-14. Tier 1, codebox bench, module bench and contract bench green (Verification below). Every live look passed (Matt, 2026-11-13 / 14: T030, T031, T032, T036, T039). All preliminary gates confirmed by Matt 2026-11-14; linear light deferred (`G-linear-light`).

_Reference written 2026-11-14 from `src/f_halftone/` (definition and codebox), `.specify/f_halftone/{spec,plan,tasks}.md` and the module's tests._

---

## What it does

Turns tone into marks: dots, lines or a dither, at a fixed screen angle per plate. It is the second stage of the print-styles family (`ideas/f_print_styles.md`), after `f_separate`. Print is a vocabulary here, for screens and projection: nothing in it aims at matching a real press.

- **Outlet 1** is the screen: the three plates summed and clamped. In Channels mode red, green and blue are three plates; in Single the texture is one spot-color plate; in Plates mode inlets 2-4 take `f_separate`'s plates.
- **Outlets 2-4** carry the plates one by one, as a gray mask (default) or in their color, so each plate can go through its own effect (`f_vf_erode`, for one) and be recombined downstream.

The screen is fixed to the frame, not the image: an animated input moves under a still screen.

---

## Signal Flow

```
inlet 0 (texture + control messages) -> halftone_pix in1                r dim -> width / height (render size)
inlets 1-3 (Plates mode: f_separate's plates) -> halftone_pix in2-in4, each with a vs_inState flag (plate1_on ... plate3_on)
loadbang -> jit.matrix (read f_bluenoise64.jxf) -> jit.gl.texture -> halftone_pix in5     (Blue's thresholds, from the package)
halftone_pix out1 -> outlet 0 (screen); out2-out4 -> outlets 1-3 (plates)
Plate menu -> sel 2 -> `set 1 / 2 / 3` or `set R / G / B` -> the plate table's row labels
```

One `jit.gl.pix` stage, float32, at the render size. Each plate is one call of a single `plate_path` function, three calls in every mode: the codebox sits near the GL3 shader transformer's size ceiling (see Notes).

---

## Parameters

| Name | Type | Range | Default | Description |
|---|---|---|---|---|
| `screen` | menu | Dot / Line / Threshold / Bayer / Blue / Random | Dot | The kind of mark (below) |
| `plate_mode` | menu | Channels / Single / Plates | Channels | How the input is read (below) |
| `plate_out` (Out) | button | Gray / Color | Gray | What outlets 2-4 carry |
| `pitch` | float | 0.009-0.2 | 0.012 | Lattice period in frame heights, for all plates. Dot and Line floor each plate's pitch at 0.009 (about 10 pixels at 1080p) |
| `scale_r`, `scale_g`, `scale_b` | float | 0.25-4 | 1 | Per-plate multiplier on Pitch (plate table) |
| `angle_r`, `angle_g`, `angle_b` | float | 0-180 | 15, 75, 45 | Screen angle per plate, degrees (plate table) |
| `phase_r_x` ... `phase_b_y` | float | -1 to 1 | 0 | Per-plate lattice shift in pitches, x and y (plate table) |
| `softness` (Soft) | float | 0-1 | 0.1 | Width of the edge between ink and no ink |
| `dot_shape` (Shape) | float | 0-1 | 0 | Dot only: round to square at the same inked area |
| `jitter` | float | 0-1 | 0 | Dot only: moves each dot off the lattice, at most a quarter cell |
| `seed` | int | 1-256 | 1 | The random pattern for jitter, Blue and Random |
| `level` | float | 0-1 | 0.5 | Threshold only: the cut |
| `levels` | int | 2-16 | 2 | Bayer, Blue, Random: output values per channel (2 is one-bit) |
| `bayer_cell` (Read) | button | Pixel / Cell | Cell | Bayer, Blue, Random: one tone per dither cell, or per pixel |
| `bypass` | toggle | 0/1 | 0 | Outlet 1 passes the source; the plate outlets pass each plate's part of it. Toggle only: the message route has no `bypass` selector |

Internal, never set by hand: `bypass_gate`, `plate1_on` ... `plate3_on`, `width`, `height`.

### Screens

- **Dot**: a lattice of dots, each sized by the tone at its cell center, so the inked area equals the tone.
- **Line**: parallel lines whose width follows the tone at the nearest point on the line.
- **Threshold**: ink where the tone is above Level; Soft widens the cut.
- **Bayer**: an 8 x 8 ordered dither, repeated once per Pitch (a cell is Pitch / 8 in whole pixels).
- **Blue**: a 64 x 64 void-and-cluster blue-noise pattern, shipped as `package/media/f_bluenoise64.jxf`: an even grain with no visible pattern.
- **Random**: white-noise thresholds from a hash: grainier and clumpier than Blue.

### Plate modes

- **Channels**: red, green and blue are three plates, each at its own row of the table.
- **Single**: the texture is one plate, screened at the B row, tone the brightest channel, colored with the source's own color. The plate comes out of outlet 4; outlets 2 and 3 are black.
- **Plates**: inlets 2-4 take `f_separate`'s plates, each screened as Single at rows 1, 2, 3 and summed. An unconnected plate adds nothing; the row labels read 1 / 2 / 3. Inlet 0 is ignored except by bypass.

---

## Algorithm

Per pixel, per plate:

1. **Lattice.** `p` is the pixel in frame heights about the frame center; `q = R(-angle) p / pitch - phase`; the cell is `floor(q + .5)`, the local position `f = q - cell`.
2. **Tone.** One read per cell at its center (Dot), at the nearest point on the line (Line), or per pixel (Threshold; the dithers in Pixel mode). Non-finite values are zapped to 0.
3. **Spot function.** Dot: the area of a radius-r circle inside the unit cell, `A(r)`, solved so the dot's area equals the tone; Shape blends toward a square of the same area. Line: `2 |f_y|`. The edge is a ramp of width `max(Soft / 2, one pixel)` along the spot function's slope; tone 0 and tone 1 are exactly no ink and full ink.
4. **Jitter.** Each cell center moves by up to a quarter cell (a seeded sin hash); the nine cells around the pixel are tested, each mark clipped to its own displaced cell.
5. **Dithers.** The tone is compared with a threshold (Bayer matrix, blue-noise texel, or hash) per cell, then quantized to Levels values.
6. **Output.** Outlet 1: the plates' terms summed and clamped, alpha the source's (Plates: the largest connected plate's). Outlets 2-4: each plate's term (Color) or its brightest channel as gray (Gray).

---

## Notes

- **The pitch floor.** Below about 10 pixels a dot's inked area stops tracking the tone (8% off at 3 pixels; the GPU and the mirror agree to seven digits). Dot and Line hold each plate's pitch at or above 0.009 frame heights; the dithers are exact at any pitch and are not floored.
- **Jitter loses ink above mid-tone.** At jitter 1 a flat 0.9 comes out near 0.79, because each displaced mark is clipped to its own cell (the clip stopped full-tone dots blooming to three cells). Accepted (Matt, 2026-11-13 / 14).
- **Default angles 15 / 75 / 45**, 30 degrees apart to limit moire; 45 for Single, the usual one-plate angle.
- **Plate outlets for effects.** Gray is the plate's coverage, the useful input for `f_vf_erode`'s terrain or amount; Color adds back to outlet 1 wherever outlet 1 is not clipped.
- **Values as given.** The maths runs on the values it receives, with no linear-light conversion (`G-linear-light`, deferred by Matt).
- **Cost.** Dot and Line under about 1.2 ms per pass at 1080p (unresolved at 4K, so an upper bound; `tests/logs/20261114-134434-bench.log`). Dot at jitter 1 (nine cells per plate) is unmeasured: the bench returned "busy" twice; judged by eye at 1080p (Matt).
- **Shader size.** The codebox sits at the GL3 transformer's "too many captures" ceiling. Findings while building it: big-function call sites count toward the budget; per-component `switch` / `zap` calls in a long expression tipped it where plain arithmetic did not; `vec(vec3, scalar)` does not build a four-component vector (take the components one by one); a Param named `shape` never received its value (hence `dot_shape`).

## Known issues / open

- **Bypass in Plates mode** passes the plate inputs' color unzapped to outlets 2-4, and a NaN on a connected plate inlet reaches the plate outlets in any mode (the capture budget ruled out the zap). Outlet 1 is zapped as everywhere.
- **The Blue texture after a GL context rebuild** is untested; a Max launched before the package file existed cannot find it (relaunch Max).
- **Menu category** (Color / Tone, beside `f_separate`) was placed by Claude, provisional (`G-menu`).

## Verification

- Tier 1 (NumPy mirror `tests/modules/halftone/halftone_mirror.py`): `test_halftone.py` 20/20, `test_dithers.py` 11/11, `test_bluenoise.py` 6/6, `test_plate_outlets.py` 9/9 (logs `tests/logs/20261114-135552-offline.log`, `20261114-142210-offline.log`).
- `bench_halftone.py`: the real codebox against the mirror, 20/20 (`tests/logs/20261114-143501-bench.log`). Jitter is compared by means: the sin hash cannot match the mirror per pixel.
- `bench_halftone_module.py`: the shipped patcher, 9/9 (same log).
- `tests/contracts/bench_modules.py`: no `f_halftone` finding (`tests/logs/20261114-144008-bench.log`).
- Live (Matt, 2026-11-13 / 14): first look, the plate table, Bayer Cell, Plates mode, Blue / Random / Levels, the plate outlets through `f_vf_erode`, a print-like chain and a bent use, the tuning.

## References

Classical halftoning; the module's code was written in development from these ideas, not taken from an implementation.

- Amplitude-modulated (AM) screening with rotated per-plate screens and area-preserving spot functions: standard print practice. The round-dot area function `A(r)` (a circle clipped to the unit cell) is derived in development.
- Bayer, B. E. (1973). "An optimum method for two-level rendition of continuous-tone pictures." IEEE International Conference on Communications. The standard 8 x 8 matrix (the mirror checks it against the recursive construction).
- Ulichney, R. (1993). "The void-and-cluster method for dither array generation." Proc. SPIE 1913. The 64 x 64 pattern is generated by `build/generate_bluenoise.py` (sigma 1.5).
- The sin hash `fract(sin(x) * 43758.5453)` is a common shader idiom.
- `ideas/f_print_styles.md`; `.specify/f_halftone/{spec,plan,tasks}.md`. Related: `f_separate.md`, `f_vf_erode.md`.

## Source Files

`src/f_halftone/definition.py`, `src/f_halftone/codebox_halftone.gen`, `package/patchers/f_halftone.maxpat`, `package/media/f_bluenoise64.jxf`, `build/generate_bluenoise.py`, `package/help/f_halftone.maxhelp`, `tests/modules/halftone/`.
