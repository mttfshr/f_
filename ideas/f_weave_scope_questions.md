# f_weave: what does it offer beyond "pattern + warp"? (open questions)

## Status: OPEN, captured 2026-11-01 for Matt to think about when he has time

Raised by Matt after the three-inlet rebuild (commits a5c9022..0677173): much of what `f_weave` now does could be had by making straight marks and warping them with a vecfield. These are the questions that came out of that discussion. Nothing here is decided and no code depends on it.

## What was established (reading the codebox, not run)

- Weave evaluates a line-mark pattern per pixel on a coordinate map: across `u` (inlet 0, or the rotated frame), along `v` (inlet 1, or the rotated frame). In principle any such map is a displacement of the straight pattern, so pattern + warp covers it.
- The vecfield inlet is NOT a displacement warp. It sets a local angle and combines it with the global position (`across = x*cos(theta(x,y)) + y*sin(theta(x,y))`), so lines only loosely follow the field and can fold or break. A real warp keeps lines continuous. It acts only on an axis the scalar inlets have not replaced (Matt saw this live).
- Where the module does something the composition does not (argued, not measured): sharper than a resampled raster when stretched; a ramp or camera luma goes in directly as the coordinate (contour lines) with no field-to-displacement step; one pass and one set of analytic dials.
- Where it adds little: the vecfield inlet (with `field_amount` and `fix_blend`, from the 2026-10-13 A/B, `ideas/f_weave_orientation_blend.md`); the library already has `f_vf_warp`.

## Open questions

1. **Keep the vecfield inlet?** Keep it as is, or retire it (and `field_amount`, `fix_blend`, the `src_field` gating) and warp the output with `f_vf_warp`. Cost: demos that feed weave a vecfield break (not audited; Matt handles his demo files).
2. **Is `f_vf_warp` a drop-in for the vecfield use?** Not checked. Compare weave-with-vecfield against weave -> `f_vf_warp` on the same field, side by side, live.
3. **Is the sharpness claim real?** Stretch a dense crisp pattern both ways (weave on a stretched coordinate vs a rendered raster through a warp) and look. Compression aliases either way; weave's only antialiasing is the fixed `aa` = 0.01 cell units. Is a derivative-based `aa` worth it?
4. **Scalar input precision at density 64.** `fract(u * 64)` of an 8-bit upstream texture would band. Not checked whether Vsynth scalar sources are float in practice, or what the `@type char` output does to it.
5. **Taxonomy.** Weave is a `processor` with `driving_inlet` that behaves as a generator when unconnected (`P-taxonomy`).

## Where this is tracked

`.specify/gates.md` row `G-weave-scope` (decider: Matt). Clears when Matt decides question 1.
