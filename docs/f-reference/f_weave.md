# f_weave

**Type:** Generator (with optional vecfield + scalar-potential inlets)
**Status:** Working — listed in README.md's patch table (the 2026-07-05 audit note "not yet listed" is outdated). Maintenance-audited 2026-10-12. Orientation-blend A/B resolved 2026-10-13 (Matt): not a one-time pick, both mechanisms ship as live `field_amount`/`fix_blend` dials (`ideas/f_weave_orientation_blend.md`). Matt's recorded quality concern is still open (see Notes).

---

## What it does

Parametric line-mark texture generator. Structure is a family of parallel lines running in a direction set by `angle`, with soft marks placed at continuous intervals along each line. Lines are defined as continuous distance fields (`fract`-based), never grid-quantized — this is the key architectural distinction from `f_masonry`: `f_masonry` uses `band_idx`/`slot` as real grid identity (courses and bond), while in `f_weave` the analogous `floor()` term is used *only* as a hash seed for per-line phase variation, never as slot structure. This gives clean UV-transform compatibility (confirmed droste-safe — marks compress toward a Droste singularity without the aliasing `f_masonry`'s grid approach would produce).

Output is luminance (white marks) unless the scalar-potential inlet (in2) is engaged, in which case marks are tinted by that texture's RGB — otherwise color is downstream's job (`f_channel_grader`, colorize elsewhere, etc).

**Taxonomy note (carried from HANDOFF):** despite being labeled `archetype: "processor"` in `definition.py`, f_weave is self-sufficient like f_masonry — no real content dependency on a texture inlet, generator behavior. Flagged alongside f_masonry for correction whenever `build_modules.py`'s CATEGORIES get refined.

---

## Signal Flow

```
in0 (texture + ctrl) → routepass jit_gl_texture jit_matrix
routepass out0 (texture or vs_black) → weave_pix in0   [render trigger]
routepass unmatched → route <params> → live.dials → prepend param <name> → weave_pix in0

in1 (vecfield, optional)         → weave_pix in1   [orientation perturbation]
in2 (scalar potential, optional) → vs_inState → weave_pix in2   [src_potential gate — overrides across-coordinate AND tints color]

weave_pix out0 → out0 (texture out)
```

---

## Parameters

| Param | Range | Default | Description |
|---|---|---|---|
| `density` | 0–1 | 0.5 | Line spacing and mark frequency (log-mapped: `pow(2, density*5-1)`) |
| `angle` | 0–1 | 0.0 | Global line orientation (mapped to 0–π) |
| `weight` | 0–0.5 | 0.1 | Line thickness — across-line mark extent |
| `marklen` | 0–0.5 | 0.3 | Mark length along line direction |
| `regularity` | 0–1 | 0.5 | 1=lines in phase (grid-like), 0=fully varied per-line offset |
| `phase` | -1–1 | 0.0 | Animation phase — scrolls marks along line direction |
| `field_amount` | 0–2 | 1.0 | Vecfield (in1) orientation-contribution depth. 1.0 reproduces the original (pre-2026-10-13) implicit depth exactly. |
| `fix_blend` | 0–1 | 0.0 | Orientation mechanism crossfade: 0 = vector-add + renormalize, 1 = true angular blend (`atan2`-based). Live performance control, not a fixed choice — see `ideas/f_weave_orientation_blend.md`. |
| `src_potential` | internal | — | Driven by vs_inState on the scalar-potential inlet; not user-facing |
| `bypass` | 0/1 | 0 | Outputs black |

**Prefix:** `weave` — **Object name:** `weave_pix`

---

## Algorithm

```
// orientation: two mechanisms, crossfaded by fix_blend (resolved 2026-10-13)
vx, vy = sample(vecfield, uv) - 0.5
base_angle = angle*π

// Mechanism A (fix_blend=0): vector-add + renormalize, field_amount-scaled
csA = cos(base_angle) + field_amount*(-vy); snA = sin(base_angle) + field_amount*vx
normalize (csA, snA)

// Mechanism B (fix_blend=1): true angular blend via atan2, weighted by
// field_amount (depth) and field magnitude (confidence)
field_angle = atan2(vx, -vy)
blend_angle = base_angle + wrap(field_angle - base_angle) * clamp(field_amount * |field| * 2, 0, 1)
csB = cos(blend_angle); snB = sin(blend_angle)

cs = mix(csA, csB, fix_blend); sn = mix(snA, snB, fix_blend)
normalize (cs, sn)
across_rot = uv.x*cs + uv.y*sn
along      = uv.x*(-sn) + uv.y*cs

// scalar potential (in2) can fully override the across coordinate
across_pot = sample(potential, uv).x
across = mix(across_rot, across_pot, src_potential)

density_scale = pow(2, density*5 - 1)
dist_to_line = |fract(across * density_scale) - 0.5|

line_idx  = floor(across * density_scale)          // hash seed only, NOT grid identity
line_hash = fract(sin(line_idx*127.1)*43758.5453) * (1 - regularity)
pos = along * density_scale + phase + line_hash
dist_to_mark = |fract(pos) - 0.5|

// softness expands the feather zone beyond the mark edge; the inner edge stays at weight
outer_across = weight + softness*weight
outer_along  = marklen + softness*marklen
edge = smoothstep(outer_across, 0, dist_to_line) * smoothstep(outer_along, 0, dist_to_mark)

// shape: 0=flat-top rectangle (smoothstep result), 1=raised cosine across the line
profile = mix(1, cos(clamp(dist_to_line / max(weight, 0.0001), 0, 1) * pi * 0.5), shape)
mark = edge * profile

// color: white unless potential inlet connected, in which case tinted by its RGB
cr,cg,cb = mix(1, sample(potential, uv).rgb, src_potential)
out1 = mix(vec(cr*mark, cg*mark, cb*mark, 1), vec(0,0,0,1), bypass)
```

---

## Notes — real discrepancy between spec.md and definition.py

- **`spec.md`'s "Phase 2 — Vecfield inlet" section describes an `atan2`-based scale-factor design** (`vf_angle = atan2(vy-0.5, vx-0.5)`, added to `angle*π` via an undetermined `SCALE` constant) that was still marked open/undecided (`[ ] Scale factor chosen and documented` unchecked in Phase 2's acceptance criteria). **The shipped `definition.py` codebox instead adds `vx`/`vy` directly into the `cos`/`sin` basis** (`cs = cos(angle*π) + (-vy)`, then renormalized) — a different, simpler mechanism than the spec's sketch, with no `atan2` or scale constant anywhere. Whether this represents Phase 2's actual resolution (undocumented) or a further, unspecced iteration isn't clear from the available files.
- **A second inlet (`scalar potential`, `src_potential`) exists in the shipped module with no corresponding entry anywhere in `spec.md`.** This inlet can fully override the `across` coordinate (rather than perturb it) and also tints output color from white to the potential texture's RGB — a capability not mentioned in the spec at all. This is very likely intended to pair with the also-undocumented `f_vf_potential` module (see `docs/f-reference/f_vf_potential.md`), whose own header comment states exactly this pairing (`f_vf_repulse → f_vf_potential → f_weave (scalar in)`). Treat `spec.md`'s Phase 2/3/4 checklists as stale relative to what's actually built.
- Per HANDOFF.md: Matt flagged f_weave with a vague, unresolved quality concern ("can't put my finger on it yet") — logged as a separate open thread from the `f_grain`/`f_vf_seeds` grid-rigidity discussion, explicitly not assumed related until checked.
- `swing`, `continuity`, and `beats`/`period` (Euclidean rhythm) were all deliberately dropped in Phase 1 — each pulls toward grid/slot structure, which conflicts with the continuous-distance-field architecture that makes this module Droste-safe. See `spec.md`'s "What Was Dropped and Why" for the reasoning if revisiting any of them.
- Listed in `README.md`'s patch table under Generators.

## Source File

`patchers/f_weave.maxpat`
