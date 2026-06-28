# HANDOFF — f_ library

Last session: 2026-06-27

## What just happened

### f_vf_potential — built and registered ✓
Patcher built from `.specify/f_vf_potential/definition.py`. Two-pix chain
(pass_pix + potential_pix), float32, ping-pong feedback. Params: dt, decay,
strength. Inlets: vecfield, color. Outlet: scalar potential.
Registered in f_modules (Vecfield category) and f_addmod.js SIZES [190, 100].

Signal chain operational: `f_vf_repulse → f_vf_potential → f_weave (scalar in)`

### f_vf_flow — built and registered ✓
Discovered as untracked built patcher. Dual-mode vecfield generator: uniform
direction (angle param) or texture-perturbed direction (spread param). float32.
Registered in f_modules (Vecfield category) and f_addmod.js SIZES [150, 80].

### Discrete-item family framework — captured and committed ✓
- `ideas/discrete_item_family.md` — four control layers, standard inlet/outlet
  spec, UI grouping proposal, vecfield magnitude as free second parameter
- `ideas/f_vf_seeds.md` — full design for fourth module (reference implementation
  for new architecture)

### Commits made this session
```
46684b5 docs: discrete-item family framework and f_vf_seeds design
695c26b feat: build and register f_vf_potential, f_vf_flow
```

Previous pending commits from earlier sessions were already committed (confirmed
via git log — prism, weave scalar inlet, repulse, etc. all present).

---

## What's next — priority order

### 1. f_weave softness + shape params
Codebox-only additions, no patcher restructuring.

**softness** — add `Param softness(0.0)` controlling smoothstep width on both
`dist_to_line` and `dist_to_mark`. Currently both axes are hard-edged; weight
controls thickness only. Separating edge softness from line weight brings weave
into vocabulary alignment with grain and masonry.

Codebox change:
- `dist_to_line` smoothstep: `smoothstep(weight + softness, weight - softness, dist_to_line)`
  (instead of `smoothstep(weight, 0.0, dist_to_line)`)
- `dist_to_mark`: `smoothstep(marklen + softness, marklen - softness, dist_to_mark)`

**shape** — add `Param shape(0.0)` blending mark brightness profile:
- shape=0: flat-top rectangle (current behavior)
- shape=1: raised cosine profile — `cos(dist_to_line / weight * pi * 0.5)` or similar
  Gives calligraphic/ink-on-paper feel; marks brightest at center, taper to edges.

Also needs: live.dial in UI + attrui + route entry. One new row of UI.

### 2. f_vf_seeds — scratch patch
Build and test at `~/Vsynth/patterns/f_vf_seeds_scratch.maxpat`.

Key experiments (from ideas/f_vf_seeds.md):
- Seed distribution: Voronoi centroids vs. regular grid + jitter
- Vecfield sampling: at seed position (stable) vs. at screen pixel (shears mark)
- Mark taper/asymmetry
- Identity coordinate output feasibility

### 3. Docs: regularity distinction + phase convention
Write brief notes in docs/ distinguishing f_weave `regularity` (per-line phase
randomness) from f_masonry `regularity` (per-brick presence regularity).
Document `phase` as the standard animation param name for stateless generators.

---

## Known issues / loose threads

- f_masonry square output at non-square render dimensions — root cause unresolved
- f_hue_processor band drag still broken (do not touch without a plan)
- text_button param type only reliably supports two options
- `rename strength → amount` across modules — parked
- f_weave: vecfield at high field strength produces interference (physical, not bug)
- f_weave: `along` axis in potential mode follows rotation basis, not field gradient
  (deferred — would need gradient of potential)
- f_weave: mod inlets (identity tex + screen tex) — deferred until f_vf_seeds
  validates the pattern
- f_grain: vecfield inlet (cell elongation) — deferred, own session after f_vf_seeds

---

## Module inventory (current working set)

**Generators:** f_masonry, f_chladni, f_stipple, f_grain, f_weave
**Processors:** f_droste, f_mobius, f_stereo, f_lens, f_caustic
**Color/Tone:** f_channel_grader, f_hue_processor, f_luma_processor, f_tone_curve
**Utilities:** f_texrouter, f_util_profile
**Vecfield:** f_vf_vortex, f_vf_vortex_multi, f_vf_fieldmap, f_vf_warp,
  f_vf_streak, f_vf_advect, f_vf_glow, f_vf_repulse, f_vf_split, f_vf_chroma,
  f_vf_prism, f_vf_potential, f_vf_flow
