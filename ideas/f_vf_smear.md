# f_vf_smear

_Status: Idea — single-pass version limited; full realization requires multipass. Last updated: 2026-06-09._

## Concept

True spatially-continuous directional blur along field streamlines — the effect f_vf_streak approximates but doesn't fully achieve at longer lengths. At 8 steps, f_vf_streak's discrete sampling becomes visible as overlapping exposures. f_vf_smear addresses this.

## Two approaches

**LIC single-pass variant:** Convolve a procedural noise texture along the streamline rather than sampling source color at each step. Gives continuous-looking streaks at any length because noise provides sub-pixel variation. Source image colors the LIC streaks (multiply or overlay). Visually distinct from averaging source samples — shows field geometry as fiber texture rather than smearing image content. Worth prototyping first as a scratch patch.

**Multipass iterative:** Each pass adds one more step of integration along the streamline. N passes = N effective steps without fixed unroll budget. Step count becomes a runtime parameter. Still single-frame (no temporal memory), just computed incrementally. Requires ping-pong texture setup.

## Relationship to other consumers

- `f_vf_streak` — the single-pass approximation; works well at low-to-mid length
- `f_vf_glow` — single-pass, accumulates luminance not color; different visual register
- `f_vf_smear` — this; true continuous smear
- `f_vf_advect` — temporal transport with feedback; different architecture and visual character

## Notes

- LIC prototype is the right first step — may be sufficient without multipass complexity
- Multipass architecture needs a dedicated design session on Max feedback mechanisms before speccing
- Study Vsynth's own feedback patterns before designing architecture
