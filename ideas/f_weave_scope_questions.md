# f_weave: uniqueness, utility and character (open questions)

## Status: OPEN, captured 2026-11-01 for Matt to think about when he has time

Raised by Matt after the three-inlet rebuild (commits a5c9022..0677173): much of what `f_weave` now does could be had by making straight marks and warping them with a vecfield. Part 1 is that discussion. Part 2 (added the same morning) is the larger aim: arrive at a module whose uniqueness and utility are readily apparent and which has a strong character. Nothing here is decided and no code depends on it.

## Decisions and results, 2026-11-01 (Matt, evening)

- **Q1 decided: retire the vecfield inlet** (option C). Removed in commit `508ffc7` (`field_amount`, `fix_blend`, `src_field`, inlet 2); docs, help and README updated the same day. Cause found live: with inlets 0, 1 and 2 all connected the field had no effect, and disconnecting inlet 0 brought it back (a connected scalar replaces the coordinate the field would have rotated). **Q2 (is `f_vf_warp` a drop-in) is still not checked.**
- **Q12 and Q13: tried by looking** on a scratch copy (`f_weave_char`, `scratch/experiments/f_weave_character/`, gitignored): `variant` 0 off, 1 line wobble, 2 smooth along-line modulation of weight and marklen, 3 hashed per-mark jitter, 4 wobble + smooth. Matt: all of them look good and he wants all of them. Not reported: a head-to-head of variant 2 against 3 (does continuous noise stand in for a per-mark index), the `f_droste` check, and the long-mark seam check, so **Q13 is not cleanly answered**. Bringing the variants into the shipped `f_weave` is not done and not scheduled.
- **Q10: direction chosen, prototype works:** modulate `weight`, `irreg` and `marklen` by named textures arriving on inlet 0 (`<param>_tex` tags, depth dials, a unipolar/bipolar `mmode`; `density` stays out because a per-pixel density breaks the line hash). Across and along stay as the untagged scalar inputs. See `ideas/named_mod_textures.md`. No `build_patcher.py` change yet (`P-mod-textures`).
- **Q7 (a real second line family)** not started. **Q5** still open: `angle` is inert once both scalar inlets are connected.

## Part 1: beyond "pattern + warp"

## What was established (reading the codebox, not run)

- Weave evaluates a line-mark pattern per pixel on a coordinate map: across `u` (inlet 0, or the rotated frame), along `v` (inlet 1, or the rotated frame). In principle any such map is a displacement of the straight pattern, so pattern + warp covers it.
- The vecfield inlet is NOT a displacement warp. It sets a local angle and combines it with the global position (`across = x*cos(theta(x,y)) + y*sin(theta(x,y))`), so lines only loosely follow the field and can fold or break. A real warp keeps lines continuous. It acts only on an axis the scalar inlets have not replaced (Matt saw this live).
- Where the module does something the composition does not (argued, not measured): sharper than a resampled raster when stretched; a ramp or camera luma goes in directly as the coordinate (contour lines) with no field-to-displacement step; one pass and one set of analytic dials.
- Where it adds little: the vecfield inlet (with `field_amount` and `fix_blend`, from the 2026-10-13 A/B, `ideas/f_weave_orientation_blend.md`); the library already has `f_vf_warp`.

## Open questions

1. **Keep the vecfield inlet? DECIDED 2026-11-01: retire it (see above).** Options were: keep it as is, or retire it (and `field_amount`, `fix_blend`, the `src_field` gating) and warp the output with `f_vf_warp`. Cost: demos that feed weave a vecfield break (not audited; Matt handles his demo files).
2. **Is `f_vf_warp` a drop-in for the vecfield use?** Not checked. Compare weave-with-vecfield against weave -> `f_vf_warp` on the same field, side by side, live.
3. **Is the sharpness claim real?** Stretch a dense crisp pattern both ways (weave on a stretched coordinate vs a rendered raster through a warp) and look. Compression aliases either way; weave's only antialiasing is the fixed `aa` = 0.01 cell units. Is a derivative-based `aa` worth it?
4. **Scalar input precision at density 64.** `fract(u * 64)` of an 8-bit upstream texture would band. Not checked whether Vsynth scalar sources are float in practice, or what the `@type char` output does to it.
5. **Taxonomy.** Weave is a `processor` with `driving_inlet` that behaves as a generator when unconnected (`P-taxonomy`).

## Part 2: uniqueness, utility, character

The test to aim at: finish the sentence "`f_weave` is the module that ___" so that nobody else in the library could fill the blank. Today the honest answer is something like "draws dashed parallel lines whose positions can follow a field", which is a mechanism, not an identity. The questions below are candidate ways to get from mechanism to identity. Most can be answered by looking at variations in a scratch patch, not by thinking.

**Identity**
6. **What is it, in one line?** Candidates: a mark texture (dashes on ruled lines); an isoline renderer (contour lines of any scalar field, with marks); an engraving / line-screen tool (tone becomes line weight); a woven fabric. Which one is primary decides which features matter and what the demos and helpfile show. (The docs' own "what it does" is the mechanism description. The helpfile test in `module-preflight` asks whether it explains what the module is for.)
7. **Should it actually weave?** The name says interlacing, but there is one set of lines and no over/under crossing. A second line family at its own angle, with over/under alternation where they cross, would be the one thing nothing else in the library does and would earn the name. Alternatively rename it to what it is. Which?
8. **Neighbours, to check before deciding:** `f_tf_hatch` (tensor-driven hatching), `f_masonry` (courses and bond; grid identity), `f_stipple`, `f_grain`, `f_quasi`. For each: what does weave do that it does not, and the reverse? A one-row-per-module comparison would show whether weave's gap is real.

**Utility (what is it for in a patch?)**
9. **Which roles are primary?** (a) A visible texture source; (b) the thing that makes a scalar field readable (`f_vf_potential` -> weave: contour lines of an accumulated field); (c) a line-screen / hatching renderer for a camera or any image; (d) a mask or height source for other modules. Each implies different defaults, outputs and demos.
10. **Can a texture modulate weight, marklen or density? (Direction chosen 2026-11-01: named textures on inlet 0, not density; prototype works, see above.)** Today nothing can: all three are dials only, and the only texture inputs set the geometry (across, along) or the orientation. Letting a scalar (camera luma, a waveform generator, a field) modulate `weight` is what makes engraving and line-screen looks possible: tone becomes line thickness. It may be the single biggest utility gap. This is the `P-mod-textures` convention question (`.specify/gates.md`): which inlet, what scaling, which dials.
11. **Is the output meant to be looked at or used?** It is luminance (white marks on black), with a tint from the across texture only. If it is a building block, is that the right output (alpha, a height channel, a signed distance)? If ink-on-paper is the character, is "color is downstream's job" a feature or a gap?

**Character (the hand-made quality)**
12. **What irregularity belongs to it? (Tried 2026-11-01 on a scratch copy: all five variants kept, see above.)** Today only the per-line phase offset (`regularity`) varies. Every mark on a line has the same length and weight; lines have the same thickness; positions are perfectly straight and evenly spaced. Strong character in mark-making usually comes from controlled irregularity: per-mark length and weight variation, wobble in line position, tapered or calligraphic ends (beyond `shape`), pressure-like variation along a line. Which of these is weave's signature?
13. **Is the "continuous distance field, never grid-quantized" principle the character, or a constraint to revisit? (Partly tried 2026-11-01: continuous-noise variants render fine; comparison with hashed per-mark jitter and the Droste check not reported.)** `swing`, `continuity` and `beats`/`period` were dropped in Phase 1 because they pull toward slot structure (`spec.md`, "What Was Dropped and Why"). Per-mark variation normally needs a per-mark index. Could it be done with continuous noise of the coordinate instead, keeping the Droste-safe property? Or is Droste-safety worth less than the variation?
14. **Do the defaults show it?** Defaults (density 0.5, about 2.8 cells; weight 0.1; marklen 0.3) are what a patcher sees on first load. Does the first look say what the module is, or does it need three dials moved before it does? What are the two or three "hero" dials, and are they the first ones in the UI?
15. **The unresolved quality concern.** `docs/f-reference/f_weave.md` and HANDOFF record Matt's earlier "can't put my finger on it yet" about weave, explicitly not assumed related to anything. Whether question 12 or 13 is where it resolves is a hypothesis, not a finding. Worth asking again after looking at variations.
16. **Motion.** What is its natural animation: marks sliding along their lines (`phase`), lines drifting across, lines breathing in weight? Which one is the module's gesture, and is it one dial away?

**How to decide (suggestion, not a plan)**
- Questions 3, 8, 10, 12 and 14 can be answered by looking: a scratch patch with the variations side by side, no builder changes.
- Questions 1, 6, 7 and 9 are Matt's calls and set which of the rest matter.
- Do 6 and 9 first: they say what to build before any of the rest is worth building.

## Where this is tracked

`.specify/gates.md` row `G-weave-scope` (decider: Matt). Clears when Matt decides question 1.
