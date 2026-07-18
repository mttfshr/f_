# f_vf_chroma — continuity doc
# Session: 2026-06-20

## What this module is supposed to do

A vecfield-driven spectral streak effect. Bright areas (above a luma threshold) emit
a colored streak that follows the field direction. The streak should be rainbow-ordered
— color shifts along the streak length — like a lens flare arm, sundog, or atmospheric
dispersion. The field drives direction, not color.

---

## What we built (v4, pre-retool)

Local per-pixel chromatic aberration — R/B channel splitting laterally along the field.
Two modes: Split (hard 2-sample) and Prism (5-sample spectral spread with weights).

**Why it was wrong:** Local effect, a few pixels wide. Not a streak. No luma threshold
gate. Color came from the source, not from synthesized hue. No accumulation/reach.

---

## Retool decision

Scrap the local CA architecture entirely. Replace with accumulation loop (like f_vf_glow)
with:
- Luma threshold gate (only bright pixels are emitters)
- Synthesized rainbow color from march position (not sampled from source)
- Field drives march direction
- direction toggle (Fwd/Bwd/Bi) consistent with f_vf_glow

---

## Codebox version history

### v5 — accumulation loop, UV-staggered per-channel sampling
- 48-step loop, separate fwd_uv_r/g/b with per-channel distance ratios
- Gate samples luma at each channel's UV
- Color still sampled from source at staggered positions
- **Problem:** Source luma-gated color is monochrome when source is grayscale.
  Per-channel UV stagger produces no visible rainbow on uniform sources.

### v6 — accumulation loop, synthesized hue from march position
- Single march UV per step, luma gate from source
- step_hue = hue + (i/48) * dispersion → hsl2rgb
- Accumulates synthesized color × gate × falloff weight
- **Problem:** With flat falloff, all 48 steps average to gray. Rainbow washes out.
  Per-channel normalization (accum_wr/wg/wb) tried and reverted — made it worse.

### v7 — RGB displacement, synthesized hue, no loop
- Three UV lookups (r_uv, g_uv, b_uv) with per-channel distance ratios
- Per-channel gate at each UV
- Per-channel hue synthesis (r_hue, g_hue, b_hue)
- **Problem:** streak_r = hsl2rgb(r_hue).x — extracting only R component of R's hue.
  Most hues have near-zero R component. Channel output collapses.

### v8 — RGB displacement, full color mixing
- Same 3-UV approach
- Full RGB from each hsl2rgb call, combined across all three: 
  streak_r = (r_col_r * r_gate + g_col_r * g_gate + b_col_r * b_gate) / 3.0
- **Problem:** Averaging all three hue colors at every pixel collapses separation.
  Every pixel gets the same blended color regardless of dispersion.

### v9 — RGB displacement, independent per-channel output
- streak_r = hsl2rgb(r_hue).x * r_gate
- streak_g = hsl2rgb(g_hue).y * g_gate
- streak_b = hsl2rgb(b_hue).z * b_gate
- **Problem:** Same as v7 — single component extraction kills most hues.
  At hue=0.52, R component is nearly zero. dispersion=1 wraps R and B to same hue.

### v10 — back to accumulation loop, synthesized rainbow (current)
- 48-step loop, single march UV
- step_hue = wrap(hue + (i/48) * dispersion, 0, 1) → hsl2rgb (all 3 components)
- Accumulate full synthesized color × gate × falloff weight
- **Status:** Produces color, field-driven, gated. But rainbow separation still
  washes out — averaging across 48 steps blends all hues. "Interesting but not
  what we want."

---

## Core unsolved problem

The accumulation approach inherently averages colors across all steps. A full spectrum
sweep (dispersion=1) produces white/gray because equal-weight hues cancel. A tight
falloff helps (early steps dominate) but the rainbow ordering never clearly separates.

## Key insight from session (painter analogy)

Matt: "If this was a digital painting, we'd paint a rainbow on top with an alpha channel."

The right mental model:
- Gate = alpha mask (where does the rainbow show?)
- Rainbow = fixed gradient painted in field direction
- No averaging — each pixel sees ONE color determined by its position

The accumulation loop averages. That's wrong for this effect.

---

## Proposed direction for next session

**Closest-emitter approach:** For each output pixel, march along the field and find
the FIRST step that passes the gate. Output THAT step's synthesized hue. No averaging.

- streak_color = hue at step i_first_hit
- streak_alpha = gate strength at step i_first_hit × falloff(i_first_hit)

This gives clean rainbow ordering — pixels close to a bright emitter get hue near the
base hue, pixels further away get hue shifted by (distance/radius) * dispersion.
Each pixel sees one color, not an average. The rainbow emerges from distance.

This requires a "first hit" loop — iterate until gate > 0, break. GPU loops with
early exit are valid but use a flag pattern (since `break` may not compile on GPU).

Alternative simpler approach: **single sample, no loop at all**
- March one step at radius distance
- Sample luma there for gate
- Output synthesized hue at that position × gate
- No accumulation, no averaging
- Softness comes from threshold_width (smoothstep gate)
- Trade-off: only one sample distance, no falloff gradient

---

## Current param contract (v10 / definition.py)

- radius (0–0.3) — march distance
- hue (0–1) — base hue, performable
- dispersion (0–1) — hue sweep width
- saturation (0–1) — streak saturation
- falloff (0–0.01) — decay rate along loop
- threshold (0–1) — luma gate floor
- threshold_width (0–0.5) — gate softness
- strength (0–2) — additive composite mix on out1
- direction (Fwd/Bwd/Bi text_button) — march orientation
- bypass

Mod inlets: vecfield (in2), hue mod (in3), dispersion mod (in4)

---

## Signal flow notes

- f_vf_fieldmap as field source: streak stays bounded inside bright area geometry
- f_vf_repulse as field source: streak bleeds outward beyond bright areas → better
  for sundog/flare character. repulse with Turbulent mode gave interesting results.
- Source: jit.gl.bfg with colorize — sufficient color variation for visual interest

---

## Known build system issue

text_button with 3 options (Fwd/Bwd/Bi): build script hardcodes parameter_mmax=1.0
and only reads options[0]/options[1]. Third option "Bi" is registered in parameter_enum
but inaccessible via the toggle. Needs build_patcher.py fix to support n-option toggles.
For now direction=2 (Bi) is unreachable from UI.

---

## Late session observation — vortex field

Swapping f_vf_repulse for f_vf_vortex produced the most compelling result of the
session: tight radial spike arms with visible color gradient along each arm (pink
at base → purple/blue at tips). Very clear flare/sundog character.

Key insight: vortex gives convergent streamlines toward a point — marches from many
surrounding pixels all point toward the same bright center, creating coherent directional
arms. Repulse is divergent — more diffuse, less structured.

The color gradient IS there (dispersion is working to some degree), just compressed
into a narrow hue range due to the averaging collapse. The form is correct. The
spectrum width is the remaining problem.

This is the right starting point for the next session: vortex field + v10 codebox,
then solve the rainbow separation from there.
