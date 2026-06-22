# HANDOFF — f_ library

Last session: 2026-06-21

## What just happened

### f_vf_repulse edge artifact — FIXED, committed
Ring samples now operate in [reach, 1-reach] UV space (zu/zv remap), ensuring all 16
ring positions stay within [0,1] for every output pixel. Eliminates edge bands caused
by OOB clamp artifact. Full diagnosis documented in jit-gen-codebox skill.

### f_vf_prism — WORKING, registered, committed
Architecture: three-UV angular dispersion + 11-tap Gaussian blur of gate values
perpendicular to the field direction. Registered in f_modules menu.

Best with: f_vf_repulse as field source, bright-on-dark source (jit.gl.bfg + colorize).

### Empirical boundmode test scratch patch
`~/Vsynth/patterns/boundmode_test.maxpat` — tests OOB sample behavior in jit.gl.pix.
Use as template for future GPU behavior verification.

## What's next

1. **Write help file** for f_vf_prism (f-helpfile skill)
2. **Audit in1/in2 bug** — check other f_vf_ consumer modules (f_vf_warp, f_vf_streak,
   f_vf_glow, f_vf_advect) for the same in1/in2 mixup found in f_caustic
3. **f_vf_chroma** — decide whether to continue or leave parked

## Known issues / loose threads

- f_masonry square output at non-square render dimensions still unresolved
- f_hue_processor band drag still broken (do not touch without a plan)
- text_button param type only reliably supports two options (three-option limitation)
- `rename strength → amount` across modules still parked

## Key learnings from this session (added to jit-gen-codebox skill)

- **sample() default boundmode is CLAMP** — empirically verified 2026-06-21 with literal
  OOB coordinate (vec(1.3, norm.y) produces solid stripe)
- **Stored scalars silently fail inside vec()** — `oob_u = 1.3; sample(in1, vec(oob_u, norm.y))`
  samples at norm.x instead of oob_u. Use literals or norm.x/norm.y directly
- **norm.x/norm.y must be used directly** — `uv = norm; uv.x` silently returns 0
- **Ring accumulation OOB fix: UV zoom** — remap sample center to [reach, 1-reach]
  so ring positions never go OOB. Cleaner than edge crop or OOB gate alone
