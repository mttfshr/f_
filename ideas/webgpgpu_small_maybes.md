# webgpgpu small maybes — five small additions

_Status: ⚪ concept only. Drafted 2026-10-23 from the webgpgpu mining run
(`webgpgpu-ideas-1`). Each item is small and independent; none is specced or tried._

## 1. Mean and variance outlet (extends `f_util_profile` / `f_util_analysis`)

`Example_26_statistical_mipmap` builds a hand-rolled mipmap inside one texture: each pixel
combines four coarser taps, averaging means and variances and adding the variance of the
means (scaled by RESCALE = 8). Whole-frame mean, variance and standard deviation as control
numbers lets a patch react to energy and spread: exposure auto-gain, bang detection,
contrast-driven switching. `f_util_profile` gives row and column means only.
- Tier-1: N * variance = sum of squares - N * mean^2 pooled over the frame.
- Caveats: variances fall outside [0, 1] (fine in float32, the web version quantised to
  8 bits). A verifier noted the source-image fallback region is where the transformed x and y
  are both at least 0.5 (roughly the upper-right), not the whole top quadrant.

## 2. Marching-squares contour glyphs (new module, `f_tf_glyph` family)

`games/lesson_14/15`: read a 2x2 block of binary cells, build a 4-bit case (weights 1, 2, 8, 4)
and pick one of 16 pipe/line tiles from a tile sheet at double grid resolution. `lesson_17`
extends it to junctions: first a 4-bit edge case from the cardinal neighbours, then
corner, T and plus cases patched by reading the four diagonals. Result: contours rendered
as a legible tiled-wall (box-drawing) language, quantised glyphs rather than soft edges.
`f_weave` plus `f_vf_potential` draw isolines through distance fields and `f_tf_glyph`
draws ellipses; nothing draws marching glyphs.
- Needs a glyph atlas texture (authoring and feeding it is the real cost) and a fixed
  grid-to-source ratio.
- Tier-1: enumerate all 16 cases in NumPy and compare to the weighted encoding.
- Caveat: the junction glyph ids run up to about 46, not 31 as the draft stated.

## 3. Sigmoid contrast curve (mode on `f_tone_curve`)

`Example_8`: one pass through a logistic `1 / (1 + exp(gain * (2 - 4c)))`, a smooth
soft clip; small gain lifts midtones, large gain nearly binarises. `lut_curve_and_color_controls.md`
notes `f_tone_curve` is a three-band smoothstep lift and cannot make a single smooth
curve, so this is a genuinely new mode, not a reparameterisation.
- Dials: gain, curve centre, mix with source.
- Tier-1: antisymmetric about the centre, slope gain/4 at the centre.
- Risk: large gain overflows `exp`; clamp the argument first.

## 4. Scalar-to-colormap sampler (relates to the LUT gap)

`lib/colormaps.js` stores 256-entry colormaps as packed integers for upload as a texture.
`f_` has scalars (potential, profiles, `f_ks` and `f_wc` output) but no colormap consumer;
`f_hue_processor` grades existing hue and cannot synthesise colour from a magnitude. A
1x256 LUT sampler (or a closed-form ramp, as the GPU Gems chapter does) turns those scalars
into coloured structure.
- Fold it into the LUT-curve idea (`lut_curve_and_color_controls.md`) rather than a new
  idea; the driving-scalar story (potential, activity) should lead the spec.
- Caveat from the verifier: a bare `sample()` wraps in pix chains, so a 256x1 ramp needs
  texel-centre coordinates and an explicit clamp, not the "clamp-to-edge default" the draft
  assumed.

## 5. Scale-selective gradient for `f_vf_fieldmap` (looked promising in review)

`Vision_009_lowpass_laplacian` blurs before the Laplacian, which gives a noise-robust
derivative whose effective scale is set by the blur radius. `f_vf_fieldmap` extracts a
vecfield at a fixed scale. A blur-radius dial turns it into a difference-of-Gaussians style
band-pass gradient: gradient of small structures versus large blobs on live video.
- Tier-1: Gaussian, then nine-point Laplacian, then central difference; response to a sine
  grating peaks at the dial's chosen scale.
- Caveat: a wide blur at render resolution may need several passes; keep the first version to
  small radii. This item was marked "needs a look" by the run only because its cited
  feasibility quote was the wrong one (about `mod()` banding), not because the idea failed.
- The nine-point Laplacian helper is also listed in `f_wave_field.md`.

## Related

`f_util_analysis.md`, `f_tf_glyph`, `f_tone_curve`, `lut_curve_and_color_controls.md`,
`f_vf_fieldmap`, `f_wave_field.md`.

## Provenance

webgpgpu at 5997061, omp run `webgpgpu-ideas-1`, 2026-10-23. Source drafts in
`f_omp_runs/webgpgpu-ideas-1/ideas_draft/`: 06, 47, 48, 01, 54; item 5 comes from the
run's needs-a-look list (no draft). Verified by subagents against the source files and the
f_ inventory; caveats are from verifier replies.
