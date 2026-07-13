# f_grain — size_mod inlet (scoped design, ready to build)

## Status: designed, not built — small and self-contained

## What was ruled out first
- **Shape-tex inlet** (matching `f_vf_seeds`' architecture) — too disruptive
  to `f_grain`'s core Voronoi identity, not pursued.
- **Vecfield-driven displacement-steering** — on inspection, `displace` only
  offsets the *background sample* under each grain (`uv_d` →
  `sample(in1, uv_d)`); it doesn't move or orient the grain itself. Grain has
  no position/orientation concept for a field to steer. No real anchor for
  this mechanism here.

## The actual design
A plain mod-texture inlet (not vecfield-typed), sampled per-cell at
`(best_gx, best_gy)`, blended into the existing `cell_size` computation:

```
cell_size = mix(1.0, mix(cell_size_a, cell_size_b, svf), size_var);
```

New mod sample blends in at this point, e.g.:

```
cell_size = mix(cell_size, mod_sample, size_mod_depth);
```

with a new `size_mod` (depth) param controlling blend amount.
`size_var` and its existing hash-based variation stay untouched when
nothing's connected to the new inlet — this is additive, not a replacement.

## Scope
One new inlet, one new param, one line of codebox touched. Deliberately
scoped to avoid touching the rest of grain's mechanism (displacement,
era/fade, luma gate, shape).
