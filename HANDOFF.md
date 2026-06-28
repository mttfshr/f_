# HANDOFF — f_ library

Last session: 2026-06-27

## What just happened — full session summary

### Discrete-item family framework — designed and documented
Comparative analysis of f_grain, f_masonry, f_weave produced a design framework
for the module family. Captured in:
- `ideas/discrete_item_family.md` — four control layers, standard inlet/outlet spec,
  UI grouping proposal, vecfield magnitude as free second parameter
- `docs/discrete_item_conventions.md` — regularity, phase, softness, shape conventions

### f_vf_potential + f_vf_flow — built and registered ✓
Both were built in prior sessions but unregistered. Now in f_modules and f_addmod.js.

### f_weave softness + shape params — added ✓
- `softness`: expands outer smoothstep edge (`weight * (1 + softness)`), preserves
  zero behavior exactly. mmax=2.0.
- `shape`: raised cosine mark profile blend. mmax=1.0.

### f_vf_seeds — designed, built, tested, registered ✓
Reference implementation for the discrete-item family architecture.

**Architecture validated:**
- Grid + jitter seed distribution (not Voronoi centroids)
- Vecfield sampled at seed position — gives coherent per-mark orientation
- 3×3 neighbourhood search adequate
- Strength blends to default rightward orientation (avoids basis collapse at strength=0)
- Identity coord output (out2) works — Voronoi UV map per pixel
- Per-seed character modulation via identity tex inlet works
- Composite output (out0) additively blends marks over source texture
- Density scale: `pow(2, density * 7.0 - 1.0)` — up to 64 seeds across at max

**Bugs fixed during testing:**
- Inlet mapping: vecfield on in2 (outer inlet 1), identity on in3 (outer inlet 2)
- Strength collapse: blend toward (1,0) not toward (0,0)
- Composite output: was identical to mask — fixed to sample in1 source texture

**Known refinement opportunities (not bugs):**
- Mark shapes are rough — smoothstep-only AA, no analytical derivatives
- Taper implementation could be more elegant
- Aspect correction on mark geometry may need tuning
- `shape` param (raised cosine) not yet producing strong calligraphic effect

**Status: proof of concept validated. Architecture works.**

---

## What's next — priority order

### 1. f_vf_seeds helpfile
Write `help/f_vf_seeds.maxhelp` following f_droste.maxhelp conventions.
Read `skills/f-helpfile/SKILL.md` first.

### 2. f_vf_seeds mark shape refinement
When ready — improve mark rendering quality:
- Analytical AA via derivatives (`dFdx`/`dFdy` if available in jit.gl.pix GPU path)
- Review taper implementation
- Review aspect correction

### 3. Discrete-item family: next modules
- f_grain: vecfield inlet (cell elongation/orientation) — own session
- f_weave: identity tex mod inlet (per-line weight/marklen) — own session
- Both informed by f_vf_seeds architecture

### 4. UI density pass
Section 1 (intrinsic character) / Section 2 (field response) layout for all
discrete-item modules. Blocked pending compound dial widget design.

---

## Known issues / loose threads

- f_masonry square output at non-square render dimensions — root cause unresolved
- f_hue_processor band drag still broken (do not touch without a plan)
- f_weave: mod inlets (identity tex + screen tex) — deferred
- f_grain: vecfield inlet — deferred
- `rename strength → amount` across modules — parked

---

## Module inventory (current)

**Generators:** f_masonry, f_chladni, f_stipple, f_grain, f_weave
**Processors:** f_droste, f_mobius, f_stereo, f_lens, f_caustic
**Color/Tone:** f_channel_grader, f_hue_processor, f_luma_processor, f_tone_curve
**Utilities:** f_texrouter, f_util_profile
**Vecfield:** f_vf_vortex, f_vf_vortex_multi, f_vf_fieldmap, f_vf_warp,
  f_vf_streak, f_vf_advect, f_vf_glow, f_vf_repulse, f_vf_split, f_vf_chroma,
  f_vf_prism, f_vf_potential, f_vf_flow, f_vf_seeds
