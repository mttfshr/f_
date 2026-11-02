# f_weave

**Type:** Generator (two optional inlets: across scalar, along scalar; the vecfield inlet was retired 2026-11-01)
**Status:** Working — listed in README.md's patch table (the 2026-07-05 audit note "not yet listed" is outdated). Maintenance-audited 2026-10-12. The vecfield inlet and its `field_amount`/`fix_blend` dials (orientation-blend A/B, 2026-10-13, `ideas/f_weave_orientation_blend.md`) were retired 2026-11-01 (Matt, `G-weave-scope` Q1): a field warp is `f_vf_warp` downstream. Matt's recorded quality concern is still open (see Notes).

---

## What it does

Parametric line-mark texture generator. Structure is a family of parallel lines running in a direction set by `angle`, with soft marks placed at continuous intervals along each line. Lines are defined as continuous distance fields (`fract`-based), never grid-quantized — this is the key architectural distinction from `f_masonry`: `f_masonry` uses `band_idx`/`slot` as real grid identity (courses and bond), while in `f_weave` the analogous `floor()` term is used *only* as a hash seed for per-line phase variation, never as slot structure. This gives clean UV-transform compatibility (confirmed droste-safe — marks compress toward a Droste singularity without the aliasing `f_masonry`'s grid approach would produce).

Output is luminance (white marks) unless the across inlet (inlet 0, `in1`) is engaged, in which case marks are tinted by that texture's RGB — otherwise color is downstream's job (`f_channel_grader`, colorize elsewhere, etc).

**Taxonomy note (carried from HANDOFF):** despite being labeled `archetype: "processor"` in `definition.py`, f_weave is self-sufficient like f_masonry — no real content dependency on a texture inlet, generator behavior. Flagged alongside f_masonry for correction whenever `build_modules.py`'s CATEGORIES get refined.

---

## Signal Flow

```
inlet 0 (across scalar + control) → routepass jit_gl_texture jit_matrix
routepass out0 → vs_inState → weave_pix in0 (codebox in1)   [src_potential flag — replaces the across coordinate AND tints color]
routepass unmatched → route <params> → live.dials → prepend param <name> → weave_pix in0

inlet 1 (along scalar, optional) → vs_inState → weave_pix in1 (codebox in2)   [src_along flag — replaces the along coordinate; phase / regularity still apply on top]
(no third inlet: the vecfield inlet was retired 2026-11-01)

r draw → gate 1 1 → weave_pix in0   [render trigger when inlet 0 is empty; the gate is closed by inlet 0's connected flag]
weave_pix out0 → out0 (texture out)
Archetype: processor with driving_inlet (mod_inlets across / along). Render size follows the render (render_dim, size_stages only; @adapt 0).

weave_pix out0 → out0 (texture out)
```

---

## Parameters

| Param | Range | Default | Description |
|---|---|---|---|
| `density` | 0–1 | 0.5 | Line spacing and mark frequency (log-mapped: `pow(2, density*5 - 1 + 4*max(density-0.5, 0))`; unchanged up to 0.5, 64 cells across at 1.0) |
| `angle` | 0–1 | 0.0 | Global line orientation (mapped to 0–π) |
| `weight` | 0–1 | 0.1 | Line thickness — across-line mark extent |
| `marklen` | 0–1 | 0.3 | Mark length along line direction |
| `softness` | 0–2 | 0.0 | Edge softness — 0 = crisp edge at `weight`/`marklen`, 1 = feather from the line centre out to 2x, >1 feathers further out (2026-11-01; before that 0 was a ramp from the centre to the edge). |
| `shape` | 0–1 | 0.0 | Mark profile — 0 = flat-top rectangle, 1 = raised cosine (calligraphic). |
| `regularity` | 0–1 | 0.5 | 1=lines in phase (grid-like), 0=fully varied per-line offset |
| `phase` | -1–1 | 0.0 | Animation phase — scrolls marks along line direction |
| `src_potential` | internal | — | Driven by vs_inState on the scalar-potential inlet; not user-facing |
| `bypass` | 0/1 | 0 | Outputs black |

**Prefix:** `weave` — **Object name:** `weave_pix`

---

## Algorithm

```
// orientation: the global `angle` only (the vecfield terms were removed 2026-11-01)
base_angle = angle*π
cs = cos(base_angle); sn = sin(base_angle)
across_rot = uv.x*cs + uv.y*sn
along      = uv.x*(-sn) + uv.y*cs

// scalar potential (in2) can fully override the across coordinate
across_pot = sample(potential, uv).x
across = mix(across_rot, across_pot, src_potential)

density_scale = pow(2, density*5 - 1 + 4*max(density-0.5, 0))   // 2026-11-01: top end 16 -> 64 cells
dist_to_line = |fract(across * density_scale) - 0.5|

line_idx  = floor(across * density_scale)          // hash seed only, NOT grid identity
line_hash = fract(sin(line_idx*127.1)*43758.5453) * (1 - regularity)
pos = along * density_scale + phase + line_hash
dist_to_mark = |fract(pos) - 0.5|

// 2026-11-01: feather band = [w*max(1-softness,0), w*(1+softness)], min band aa = 0.01 (cell units)
outer_across = weight + softness*weight
inner_across = min(weight*max(1-softness,0), outer_across - aa)
outer_along  = marklen + softness*marklen
inner_along  = min(marklen*max(1-softness,0), outer_along - aa)
edge = smoothstep(outer_across, 0, dist_to_line) * smoothstep(outer_along, 0, dist_to_mark)

// shape: 0=flat-top rectangle (smoothstep result), 1=raised cosine across the line
profile = mix(1, cos(clamp(dist_to_line / max(weight, 0.0001), 0, 1) * pi * 0.5), shape)
mark = edge * profile

// color: white unless potential inlet connected, in which case tinted by its RGB
cr,cg,cb = mix(1, sample(potential, uv).rgb, src_potential)
out1 = mix(vec(cr*mark, cg*mark, cb*mark, 1), vec(0,0,0,1), bypass)
```

---

## Changes 2026-11-01 (Matt)

- Nothing connected now draws straight lines at `angle` (before, an empty inlet 0 drew nothing: vs_inState does not make an unconnected pix render, the f_quasi bug).
- Inlets reordered scalars first: 0 across, 1 along (new). A vecfield inlet (2) was added in this reorder and retired later the same day (next section). Saved patches that fed a vecfield to inlet 0 and a scalar to inlet 1 need rewiring.
- `density` reaches 64 cells across (was 16; unchanged below 0.5). `weight` / `marklen` range 0-1 (1.0 fills the cell, edges at half level).
- `softness` 0 = crisp edge, 1 = the old softness-1 feather (the old softness 0, a ramp from the line centre, no longer exists; about 0.5 is nearest).

## Vecfield inlet retired 2026-11-01 (Matt, `G-weave-scope` Q1, option C)

- Removed: the vecfield inlet (inlet 2, codebox `in3`), `field_amount`, `fix_blend` and the `src_field` flag. Orientation is `angle` only. Commit `508ffc7`; static test and drift ok.
- Why: the vecfield only rotated `across_rot` / `along_rot`, which a connected scalar replaces. With inlets 0, 1 and 2 all connected the field had no effect, and disconnecting inlet 0 brought it back (Matt, in Max, same day). By the codebox, with only inlet 0 connected the field would only shift mark positions along each line, and used alone it fans lines from the origin instead of bending them along the field (read from the code, not tested). A real field warp is `f_vf_warp` downstream; `ideas/f_weave_scope_questions.md` Q2 (whether `f_vf_warp` is a drop-in) was not checked.
- Consequence: a patch with anything on weave's old inlet 2 loses that connection. `angle` is also inert once both scalar inlets are connected, because both coordinates are then replaced; that tension is scope question 5.
- History of the removed mechanisms: `ideas/f_weave_orientation_blend.md` (A/B, 2026-10-13), kept as a record.

## Character work, scratch (2026-11-01)

Not in the shipped module. A scratch copy, `f_weave_char` (`scratch/experiments/f_weave_character/`, gitignored, local only), tried irregularity variants and named-texture modulation:
- `variant` 0 off, 1 line wobble, 2 smooth along-line modulation of `weight`/`marklen`, 3 hashed per-mark jitter, 4 wobble + smooth modulation, with `irreg` (depth) and `nscale` (noise frequency). Matt (2026-11-01): all variants look good and he wants all of them; bringing them into the shipped `f_weave` is not done and not yet scheduled. The scratch copy also renamed `regularity` to `offset` (inverted), made `variant` a menu and the modulation mode a Unipolar/Bipolar toggle, and removed `shape` (Matt, 2026-11-01); the shipped module still has `regularity` and `shape`.
- Named-texture modulation of `weight` / `irreg` / `marklen` on inlet 0 (tagged textures, depth dials `*_m`, `mmode`): works live; see `ideas/named_mod_textures.md`. No `build_patcher.py` change yet (`P-mod-textures`).

## Notes — real discrepancy between spec.md and definition.py

- (Moot since 2026-11-01: the vecfield inlet no longer exists.) **`spec.md`'s "Phase 2 — Vecfield inlet" section describes an `atan2`-based scale-factor design** (`vf_angle = atan2(vy-0.5, vx-0.5)`, added to `angle*π` via an undetermined `SCALE` constant) that was still marked open/undecided (`[ ] Scale factor chosen and documented` unchecked in Phase 2's acceptance criteria). **The shipped `definition.py` codebox instead adds `vx`/`vy` directly into the `cos`/`sin` basis** (`cs = cos(angle*π) + (-vy)`, then renormalized) — a different, simpler mechanism than the spec's sketch, with no `atan2` or scale constant anywhere. Whether this represents Phase 2's actual resolution (undocumented) or a further, unspecced iteration isn't clear from the available files.
- **A second inlet (`scalar potential`, `src_potential`) exists in the shipped module with no corresponding entry anywhere in `spec.md`.** This inlet can fully override the `across` coordinate (rather than perturb it) and also tints output color from white to the potential texture's RGB — a capability not mentioned in the spec at all. This is very likely intended to pair with the also-undocumented `f_vf_potential` module (see `docs/f-reference/f_vf_potential.md`), whose own header comment states exactly this pairing (`f_vf_repulse → f_vf_potential → f_weave (scalar in)`). Treat `spec.md`'s Phase 2/3/4 checklists as stale relative to what's actually built.
- Per HANDOFF.md: Matt flagged f_weave with a vague, unresolved quality concern ("can't put my finger on it yet") — logged as a separate open thread from the `f_grain`/`f_vf_seeds` grid-rigidity discussion, explicitly not assumed related until checked.
- `swing`, `continuity`, and `beats`/`period` (Euclidean rhythm) were all deliberately dropped in Phase 1 — each pulls toward grid/slot structure, which conflicts with the continuous-distance-field architecture that makes this module Droste-safe. See `spec.md`'s "What Was Dropped and Why" for the reasoning if revisiting any of them.
- Listed in `README.md`'s patch table under Generators.

## Source File

`patchers/f_weave.maxpat`
