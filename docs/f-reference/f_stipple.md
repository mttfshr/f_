# f_stipple — Bpatcher Spec

_Last updated: 2026-11-06 (stable preflight, offline by Claude; read from the codebox and patcher, not run)_
_Status: Working_

## Concept

A 2D hash field rendered as stipple — no mark geometry, no course structure, pure field operation. Dual-mode: **source mode** (inlet 0 unconnected) generates a standalone black-and-white stipple texture from parameters alone; **processor mode** (texture present on inlet 0) uses the incoming texture to modulate the hash field, with dither threshold modulation and displacement both always computed. The codebox reads only the **red channel** of the input (`sample(in1, norm).r`), so a colored texture steers by its red alone, not by luminance:

- **Dither/density:** incoming red modulates the local threshold — red-bright regions get dense stipple, red-dark regions get sparse (halftone/mezzotint character). Output inherits input color when `colorize=1`.
- **Displacement:** incoming red displaces the sampling coordinates of the displaced-source output (the third outlet) — the resampled input bends around red-bright/red-dark regions, amount set by `threshold`. It does not move the stipple itself, and it does not change the composite or mask outlets.

Mode is auto-detected via `vs_inState` (Vsynth convention: connection-event timing, not alpha/luma) and drives the internal `src_mode` param — not user-facing.

Two orthogonal hash fields — a sin-based directional hash and an arithmetic isotropic hash — are blended by `anisotropy`. At `anisotropy=1`, parallel lines read clearly; at `anisotropy=0`, isotropic grain; in between is the primary expressive zone.

## Parameters

| Name | Type | Range | Default | Description |
|------|------|-------|---------|-------------|
| `freq` | float | 0.0–20.0 | 2.0 | Spatial frequency of the **parallel** hash only; no effect at `anisotropy` 0 |
| `coarseness` | float | 1.0–100.0 | 20.0 | Grain period scale — higher = chunkier grains |
| `anisotropy` | float | 0.0–4.0 | 0.5 | 0=isotropic grain, 1=parallel lines, >1=expressive aliasing. `freq` acts only on the parallel hash (see Algorithm) |
| `angle` | float | -360–360 | 0.0 | Orientation of along/across coordinate frame |
| `zoom` | float | 0.1–4.0 | 1.0 | Scales viewport into hash field — same character, bigger or smaller |
| `threshold` | float | 0.0–2.0 | 0.5 | Source mode: the cutoff (higher = less white). Processor mode: a bias added to the red (higher = more white; 0.5 compares red straight against the hash). Also scales the always-on red displacement of the third outlet |
| `colorize` | float | 0.0–1.0 | 0.0 | Processor only: 0=monochrome dither output, 1=inherit input color |
| `along_phase` | float | -1.0–1.0 | 0.0 | Hash field offset along angle axis; drive externally for drift. Also pans where the third outlet samples the input |
| `across_phase` | float | -1.0–1.0 | 0.0 | Hash field offset perpendicular to angle axis; drive externally for drift. Also pans the third outlet |
| `softness` | float | 0.0–2.0 | 0.1 | Smoothstep width at comparison boundary |
| `src_mode` | internal | 0/1 | — | Driven by `vs_inState`; 0=source, 1=processor. Not user-facing. |
| `bypass` | bypass | 0/1 | 0 | Toggle only (jsui → `prepend param bypass_gate`; no `bypass` message in the route). Source bypass → black. Processor bypass → passthrough, on all three outlets. |

## Signal Chain

```
in0 (texture + ctrl) → routepass jit_gl_texture jit_matrix

routepass out0 → vs_inState → stipple_pix in0   [texture or vs_black; the render trigger when connected]
r draw → gate 1 1 → stipple_pix in0   [the render trigger when NOTHING is connected; see below]
vs_inState outlet 1 (0/1 state) → prepend param src_mode → stipple_pix in0

routepass unmatched → route <10 param names> → live.dial → attrui → stipple_pix in0

bypass jsui → prepend param bypass_gate → stipple_pix in0

stipple_pix out0 (composite) → outlet 0
stipple_pix out1 (stipple mask) → outlet 1
stipple_pix out2 (displaced source) → outlet 2
```

Three outlets: composite (color-graded stipple), stipple mask (raw scalar), and displaced source (input resampled at the displacement-warped UV — always computed regardless of mode). **Numbering:** this doc uses Max outlet numbers 0, 1, 2 for these. Inside the codebox the same outlets are `out1`, `out2`, `out3`, so "out3" (also used in the older notes, banners and `definition.py` comments) is the displaced outlet, the third one, and codebox `out2` is the mask, not the displaced source. They are the same outlet counted from 0 and from 1, not two different ones.

**Source mode: render trigger and size** (2026-11-01). With nothing on inlet 0, `vs_inState` gives the pix nothing to draw from, so source mode has its own trigger: `r draw` → `gate 1 1` → `stipple_pix` inlet 0. The gate starts open and `vs_inState`'s connected flag closes it through `== 0`, so a connected stipple is driven by its texture alone (one render per frame). The pix is `@adapt 0 @dim 256 256` and takes the render size from Vsynth's `dim` broadcast (`render_dim`, size stage only; the codebox reads `norm`, not `dim`, so there are no width/height Params). Before this, the pix adapted to `vs_black`, a 1x1 texture (inferred, not probed), and unconnected source mode was one constant pixel: a solid frame flipping white/black around `threshold` 0.2. The output is always render-sized (the pix `@dim` follows `r dim`), so a connected texture of another size is sampled by normalized coordinates rather than passed through at its own size (the contract bench's 64 x 64 input came out 640 x 640, hence `INPUT_SIZE` in `tests/contracts/bench_modules.py`). Checked offline by Claude (`tests/modules/stipple/test_stipple_static.py` 4/4, drift ok) and live by Matt on 2026-11-01 ("works as expected").

With nothing connected (read from the codebox, not separately observed): `threshold` sets coverage (the hash is 0-1 while `anisotropy` is 0-1, so a `threshold` above about 1 is all black; above `anisotropy` 1 the blend leaves 0-1), `colorize` has no effect, and the displaced outlet is black (the input is `vs_black`, red 0). Alpha is 1.0 on the composite and mask outlets in every mode, and bypass in source mode is black with alpha 1 (code read; the old "alpha unverified" thread is closed on the code, not on a look in Vsynth).

## Algorithm

Coordinate frame rotates by `angle` into `along`/`across` axes; `along_phase`/`across_phase` offset the field for drift. `coarseness` scales the hash's large prime multiplier down to lengthen the grain period (both hashes). `zoom` divides the shifted coordinates once, so it enlarges or shrinks both hashes. Two hash fields — `h_parallel` (sin-based, directional: `sin(along * freq * prime_scale)`) and `h_iso` (arithmetic, combining both axes: `sin((along * 127.1 + across * 311.7) * prime_scale)`, with **no `freq` term**) — blend via `anisotropy`. So `freq` only changes the parallel hash: at `anisotropy` 0 the dial does nothing, and it matters more as `anisotropy` rises. (Documented as the code is; whether `h_iso` should take `freq` is Matt's open question, not decided.) Both hashes are 0-1; the blend stays in 0-1 for `anisotropy` up to 1 and extrapolates beyond that. The stipple field is always evaluated at the unwarped base coordinates: in source mode it is thresholded against `threshold ± softness/2` directly, and in processor mode the incoming red (`input_luma` in the code, but it is `.r`; biased by `threshold - 0.5`) is compared against the field. `src_mode` selects between them; the `input_luma * threshold` warp (added after the zoom divide, so `zoom` does not scale it) feeds only the displaced-source output and runs regardless of `src_mode`:

```
lo = threshold - softness*0.5; hi = threshold + softness*0.5;
source_stipple  = smoothstep(lo, hi, hash_field)
dither_stipple  = smoothstep(hash_field - softness*0.5, hash_field + softness*0.5, input_luma + threshold - 0.5)
stipple = mix(source_stipple, dither_stipple, src_mode)
```

At `softness` 0 both smoothsteps get equal edges, which is undefined in GLSL; expected a hard step, not run (inferred).

Displaced-source output (the third outlet, codebox `out3`) resamples the input at UV coordinates rotated back from the along/across-displaced frame — independent of `src_mode`, always available. The shifted coordinates (`along_phase`/`across_phase`, `angle`) are divided by `zoom` once, then the red warp is added (`across` gets half of it), then the pair is rotated back and clamped to 0.001-0.999. At `zoom` 1, `angle` 0, both phases 0 and red 0 it samples the input unchanged. A 2026-11-06 fix removed a second divide by `zoom` that made this outlet scale by 1/zoom² against the hash's 1/zoom (found offline from the code, fixed by the main session, guard test in `tests/modules/stipple/test_stipple_static.py`). Its look at `zoom` other than 1 has not been seen live.

## Loose Threads

- ~~`proc_mode` (dither vs. displacement sub-mode) described in spec.md as a separate exposed param — the shipped codebox instead computes displacement unconditionally into the third outlet and blends dither vs. source-mode stippling via `src_mode` only. If a live dither/displacement toggle is wanted, it isn't currently wired as its own param.~~ **Resolved 2026-10-12 (maintenance audit, against the current definition.py):** the `proc_mode` header toggle was removed outright — displacement is always available on out3; `src_mode` (source vs. processor) is the only mode param. The doc's param-default rows above were also corrected that day (freq 2.0, coarseness 20.0 — the shipped defaults, previously misdocumented as 5.0/1.0).
- Source-mode alpha handling flagged as unverified in spec.md: read from the codebox 2026-11-06, alpha is 1.0 on the composite and mask outlets (above); not looked at in Vsynth.

## References

Hash-field stippling is an original construction: two orthogonal hash fields (a sin-based directional hash and an arithmetic isotropic hash) blended by `anisotropy`. No external source was consulted. The dual-mode auto-detection (source vs processor via `vs_inState`) follows the `f_grain` convention.

The hash constants (large prime multipliers, `coarseness` scaling) were tuned during development; the displacement mode's `input_luma * threshold` warp is this module's own. The removed `proc_mode` header toggle (displacement is always available on out3 since the 2026-10-05 rewrite) is documented in the Loose Threads above.

See `docs/f-reference/f_stipple.md` (this file) for the full dual-mode algorithm and the source/processor auto-detection.

## Source File

`package/patchers/f_stipple.maxpat`
