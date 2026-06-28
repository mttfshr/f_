# Discrete-item module family: design framework

*Captured 2026-06-27. Emerged from comparative analysis of f_grain, f_masonry, f_weave.*

---

## What this family is

f_grain, f_masonry, f_weave, and f_vf_seeds (planned) share a common identity
distinct from core Vsynth and from the f_vf_ vecfield family: they render **fields
of discrete items** — grain cells, bricks, ink marks, seed marks. Where Vsynth
is primarily waveform generation and the f_vf_ family is vector field processing,
this family is about **spatial arrangement of individual marks**.

The formal differences between them are purely about arrangement topology:

| Module | Arrangement topology | Item type |
|---|---|---|
| f_grain | Stochastic Voronoi, no preferred orientation | Cell (circle↔voronoi blend) |
| f_masonry | Deterministic rows + slots, rectangular | Brick (rect↔round blend) |
| f_weave | Parallel lines, orientation-dominant | Mark/dash on line |
| f_vf_seeds | Vecfield-seeded streamline positions | Streamline mark |

---

## The four control layers

Every module in this family has (or should have) four layers of control:

### 1. Global arrangement
Spacing, density, angle — the parameters that describe the grid topology in the
abstract. These are scalar params in the UI.

*Examples: f_weave `density`/`angle`, f_masonry `courses`/`bond`, f_grain `density`/`size`*

### 2. Local arrangement
Per-item position, presence, or topology distortion. Requires **identity-space
texture** — sampled at each item's stable identity UV, not at screen UV. One
value per discrete item.

*Examples: f_masonry slot-space tex (in2) for per-brick offset/drift. Currently
absent from f_grain and f_weave.*

### 3. Item character
Shape, size, weight, softness, length — what each item looks like. Can be driven
by scalar params (global baseline) or identity-space texture (per-item variation).

*Examples: f_grain `shape`/`softness`/`size_var`, f_masonry `width`/`roundness`/`softness`,
f_weave `weight`/`marklen`*

### 4. Item orientation
Direction of elongated items. Driven by **vecfield inlet** — the field direction
at each pixel sets item orientation. Field magnitude drives a secondary parameter
(density gate or weight).

*Examples: f_weave vecfield inlet (already implemented — bends line orientation).
f_grain vecfield inlet (planned — would elongate/orient cells). f_vf_seeds
vecfield inlet (primary, load-bearing — seeds follow streamlines).*

---

## Standard inlet/outlet specification

All modules in this family should converge on this inlet/outlet pattern:

**Inlets:**
- `in 0` — control/texture (existing Vsynth convention, mixed)
- `in 1` — vecfield (float32 RG, orientation + topology distortion)
- `in 2` — identity texture (sampled at item identity UV, per-item character mod)

**Outlets:**
- `out 0` — composite output (primary)
- `out 1` — item mask (mark/cell/brick mask isolated, for downstream use)
- `out 2` — identity coordinate texture *(new, planned)* — each pixel mapped to
  its item's identity UV. Enables external feedback: use this output to generate
  a texture, feed it back as the identity inlet. Closes the loop between a module's
  spatial structure and its own modulation source.

### Current status per module

| | Vecfield in | Identity tex in | Screen tex in | Mask out | Identity coord out |
|---|---|---|---|---|---|
| f_weave | ✓ (in1, orientation) | — | ✓ (in2, scalar potential) | — | — |
| f_grain | — | — | — | ✓ (out2 raw) | — |
| f_masonry | — | ✓ (in2, slot space) | ✓ (in3 intra-brick, in4 screen) | ✓ (out2) | — |
| f_vf_seeds | ✓ primary | planned | planned | planned | planned |

---

## UI structure implication

If topology + identity + item character params are all reachable from incoming
textures/vecfields, the UI should group them to reflect signal chain logic rather
than parameter category.

Proposed two-section layout for all modules in this family:

**Section 1 — Intrinsic character**
What one item looks like in isolation. Shape, softness, weight/width, marklen.
Performer sets these as a baseline. Standard live.dial vocabulary.

**Section 2 — Field response**
How arrangement and items respond to incoming textures/vecfields. Density/spacing,
orientation, mod depths. UI representation may differ — attenuverters or a compact
matrix rather than full dials — because these values are primarily set by incoming
signals, not tweaked in isolation.

*Note: UI density pass (compound dial widget, panel layout) is the right moment
to implement this properly. Defer layout changes until then; add params in the
interim without restructuring.*

---

## Item shape: texture-in vs. scalar param

The question of whether item shape should be texture-driven in all cases resolved
as: **both, layered**. Scalar param sets the global baseline; identity-space texture
inlet adds per-item variation on top. The codebox pattern is:

```
shape_eff = clamp(shape + id_sample * shape_mod_depth, 0.0, 1.0);
```

Where `id_sample` is the identity texture sampled at the item's stable UV, and
`shape_mod_depth` is a param controlling how much the texture can swing the shape.

This is already proven in f_masonry. The pattern should be adopted uniformly.

---

## Vecfield magnitude: the free second parameter

Vecfields carry two values per pixel: direction and magnitude. Currently f_weave
uses direction only (to bend line orientation). Magnitude is discarded.

For all modules in this family, field magnitude should gate or modulate a second
parameter — the most natural candidates:

- **f_weave:** magnitude → `weight` (thick marks where field is strong)
- **f_grain:** magnitude → cell presence/density gate
- **f_vf_seeds:** magnitude → seed density or trail length

This is free expressive information requiring no additional inlet. Should be added
when each module's vecfield inlet is properly built.

---

## Masonry's mod architecture: deliberately not replicated

Masonry's three-inlet (slot / intra-brick / screen) × per-param mod depth matrix
is powerful but complex. It was built before f_util_matrix existed and before this
family framework was articulated.

For f_grain, f_weave, and f_vf_seeds, the simpler pattern is:
- One identity-space inlet with a single mod depth per modulated param
- One screen-space inlet (optional, may share with other roles)

Masonry's architecture stands as-is. The per-param mod depth approach is still
valid — just don't replicate the full three-inlet complexity by default.

---

## f_vf_seeds: the reference implementation

f_vf_seeds is the planned fourth member and the first to be built with this
framework from the start. See `ideas/f_vf_seeds.md` for full design notes.

Because f_vf_seeds *requires* the vecfield inlet (it can't fall back to a global
angle param meaningfully), it will be the cleanest test of the standard inlet spec.
The identity coordinate output is also planned as a first-class feature from day one,
making it the reference for how other modules should eventually expose their own
coordinate outputs.

---

## Deferred

- **f_grain vecfield inlet** (cell elongation/orientation) — significant codebox
  change, deserves its own session after f_vf_seeds validates the pattern
- **f_weave identity texture inlet** (per-line weight/marklen) — defer until after
  weave softness/shape additions stabilize
- **UI density pass** — the Section 1/Section 2 layout proposal above requires
  the compound dial widget; implement structure then
- **f_masonry identity coord output** — lower priority, masonry is already complex
