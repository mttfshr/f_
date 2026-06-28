# HANDOFF — f_ library

Last session: 2026-06-27

## What just happened

### f_vf_seeds — built and registered ✓

Scratch patch validated at `~/Vsynth/patterns/f_vf_seeds-scratch.maxpat`.

Open questions resolved:
- Q1: Grid + jitter confirmed (not Voronoi centroids) — simpler, controllable density
- Q2: Taper as param confirmed — asymmetric along-axis endpoints
- Q3: 3×3 neighbourhood search adequate
- Strength fix: blend to default rightward orientation (not toward zero) — avoids basis collapse

Codebox from scratch patch copied to `.specify/f_vf_seeds/codebox_seeds.gen`.
Patcher built from definition.py → `patchers/f_vf_seeds.maxpat`.
Registered in f_modules (Vecfield category) and f_addmod.js SIZES [190, 175].

Structure: 3 inlets (control, vecfield, identity tex), 3 outlets (composite, mask, identity coord).
12 dials: density, jitter, weight, marklen, softness, shape, taper, strength, mag_weight, phase,
weight_mod, marklen_mod.

### Also completed this session
- f_vf_potential registered ✓
- f_vf_flow discovered and registered ✓
- f_weave softness + shape params ✓
- f_weave softness formulation fixed (expand outer edge, not symmetric zone) ✓
- docs/discrete_item_conventions.md written ✓
- ideas/discrete_item_family.md + ideas/f_vf_seeds.md written ✓

---

## What's next

### 1. Test f_vf_seeds in Max
Open `patchers/f_vf_seeds.maxpat` as a bpatcher. Connect:
- f_vf_vortex → in1 (vecfield)
- Nothing on in2 initially
- out0 → vs_output

Things to verify:
- Marks visible and field-following
- identity coord output (out2) produces visible UV map
- Identity tex inlet (in2): connect f_vf_seeds out2 → f_tone_curve → f_vf_seeds in2 for self-modulation test

### 2. f_vf_seeds helpfile
Write `help/f_vf_seeds.maxhelp` following f_droste.maxhelp conventions.
See `skills/f-helpfile/SKILL.md`.

### 3. Remaining discrete-item family work (deferred)
- f_grain: vecfield inlet for cell elongation — own session
- f_weave: identity tex + screen tex mod inlets — after f_vf_seeds validates pattern
- UI density pass (Section 1 / Section 2 layout) — blocked pending compound dial widget

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
