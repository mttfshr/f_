# f_weave

**Type:** Generator (two optional inlets: across scalar, along scalar; plus three tagged modulation textures that arrive on inlet 0; the vecfield inlet was retired 2026-11-01)
**Status:** Working — listed in README.md's patch table (the 2026-07-05 audit note "not yet listed" is outdated). Maintenance-audited 2026-10-12. The vecfield inlet and its `field_amount`/`fix_blend` dials (orientation-blend A/B, 2026-10-13, `ideas/f_weave_orientation_blend.md`) were retired 2026-11-01 (Matt, `G-weave-scope` Q1): a field warp is `f_vf_warp` downstream. Promoted 2026-11-01 from a scratch copy: irregularity variants, texture-modulated weight / irreg / marklen (tagged textures on inlet 0), a compact panel (see "Promoted 2026-11-01"). Matt's recorded quality concern is still open (see Notes).

---

## What it does

Parametric line-mark texture generator. Structure is a family of parallel lines running in a direction set by `angle`, with soft marks placed at continuous intervals along each line. Lines are defined as continuous distance fields (`fract`-based), never grid-quantized — this is the key architectural distinction from `f_masonry`: `f_masonry` uses `band_idx`/`slot` as real grid identity (courses and bond), while in `f_weave` the analogous `floor()` term is used *only* as a hash seed for per-line phase variation, never as slot structure. This gives clean UV-transform compatibility (confirmed droste-safe — marks compress toward a Droste singularity without the aliasing `f_masonry`'s grid approach would produce).

Output is luminance (white marks) unless the across inlet (inlet 0, `in1`) is engaged, in which case marks are tinted by that texture's RGB — otherwise color is downstream's job (`f_channel_grader`, colorize elsewhere, etc).

**Taxonomy note (carried from HANDOFF):** despite being labeled `archetype: "processor"` in `definition.py`, f_weave is self-sufficient like f_masonry — no real content dependency on a texture inlet, generator behavior. Flagged alongside f_masonry for correction whenever `build_modules.py`'s CATEGORIES get refined.

---

## Signal Flow

```
inlet 0 (across scalar + control + tagged textures) → routepass jit_gl_texture jit_matrix
routepass out0 → vs_inState → weave_pix in0 (codebox in1)   [src_potential flag — replaces the across coordinate AND tints color]
routepass unmatched → route <params> → live.dials → prepend param <name> → weave_pix in0
  scalar route's reject outlet → route weight_tex irreg_tex marklen_tex   (the tag demux, mod_inlets "tag")
    weight_tex  → vs_inState → weave_pix in2 (codebox in3)   [src_weight flag]
    irreg_tex   → vs_inState → weave_pix in3 (codebox in4)   [src_irreg flag]
    marklen_tex → vs_inState → weave_pix in4 (codebox in5)   [src_marklen flag]

inlet 1 (along scalar, optional) → vs_inState → weave_pix in1 (codebox in2)   [src_along flag — replaces the along coordinate; phase / offset still apply on top]

r draw → gate 1 1 → weave_pix in0   [render trigger when inlet 0 is empty; the gate is closed by inlet 0's connected flag]
weave_pix out0 → out0 (texture out)
Archetype: processor with driving_inlet (mod_inlets across / along, plus three TAGGED entries with no outer inlet of their own). Render size follows the render (render_dim, size_stages only; @adapt 0).
```

A texture is tagged upstream with `prepend weight_tex` (or `irreg_tex`, `marklen_tex`) and cabled into inlet 0 next to the untagged scalar; an untagged texture on inlet 0 is still the across scalar. A target nothing is tagged for leaves its dial alone.

---

## Parameters

| Param | Range | Default | Description |
|---|---|---|---|
| `density` | 0–1 | 0.5 | Line spacing and mark frequency (log-mapped: `pow(2, density*5 - 1 + 4*max(density-0.5, 0))`; unchanged up to 0.5, 64 cells across at 1.0) |
| `angle` | 0–1 | 0.0 | Global line orientation (mapped to 0–π) |
| `weight` | 0–1 | 0.1 | Line thickness — across-line mark extent |
| `marklen` | 0–1 | 0.3 | Mark length along line direction |
| `offset` | 0–1 | 0.5 | Per-line offset along the line: 0 = marks line up across lines (grid-like), 1 = each line fully offset. The old `regularity`, inverted (`offset = 1 - regularity`; the default looks the same). |
| `phase` | -1–1 | 0.0 | Animation phase — scrolls marks along line direction |
| `softness` (label Soft) | 0–2 | 0.0 | Edge softness — 0 = crisp edge at `weight`/`marklen`, 1 = feather from the line centre out to 2x, >1 feathers further out. |
| `variant` | menu 0–4 | Off | Irregularity: Off, Wobble (smooth noise nudges the line position), Smooth (continuous noise along each line modulates weight and marklen), Hashed (one random value per mark; grid-leaning), Both (wobble + smooth). |
| `irreg` | 0–1 | 0.5 | Irregularity depth for the chosen variant (the irreg_tex texture adds to it). |
| `nscale` (label Noise) | 0–1 | 0.5 | Noise frequency, log-mapped from one change per 8 cells (0) to 4 per cell (1); about 0.6 is one change per mark. |
| `weight_m`, `marklen_m`, `irreg_m` | 0–1 | 0.0 | Depth of the texture tagged `weight_tex` / `marklen_tex` / `irreg_tex` on inlet 0. A numbox under the dial it modulates. 0 = ignored. |
| `mmode` (Tex uni / Tex bi) | 0/1 | 0 | How a tagged texture is read: uni = raw 0..1 (can only add), bi = rescaled to -1..1 (mid-gray = no change, dark subtracts). Modelled on `vs_displacement`'s mode switch (its polarity naming was not verified). |
| `src_potential`, `src_along`, `src_weight`, `src_irreg`, `src_marklen` | internal | — | Connected flags from the `vs_inState` of each inlet / tagged texture; not user-facing |
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

// scalar potential (in1) can fully override the across coordinate; the along scalar (in2) the along one
across_pot = sample(potential, uv).x
across = mix(across_rot, across_pot, src_potential)

density_scale = pow(2, density*5 - 1 + 4*max(density-0.5, 0))   // 2026-11-01: top end 16 -> 64 cells

// tagged modulation textures (in3..in5): effective = dial + connected_flag * depth * texture
tw = mix(t3, t3*2 - 1, mmode)        // mmode 0 raw 0..1, 1 rescaled to -1..1; same for ti (in4), tl (in5)
weight_g = clamp(weight + src_weight*weight_m*tw, 0, 1)
irreg_g = clamp(irreg + src_irreg*irreg_m*ti, 0, 1)
marklen_g = clamp(marklen + src_marklen*marklen_m*tl, 0, 1)

// variant weights: Off 0/0/0, Wobble 1/0/0, Smooth 0/1/0, Hashed 0/0/1, Both 1/1/0  (wobble / smooth / hashed)
// wobble: smooth 2D noise of the cell coordinates nudges the line position across by up to 0.4 cell
u = u0 + wob*irreg_g*0.4*w_wob          // the line index and distance below use the DISPLACED u
dist_to_line = |fract(u) - 0.5|
line_idx  = floor(u)                    // hash seed only, NOT grid identity
line_hash = fract(sin(line_idx*127.1)*43758.5453) * offset
pos = along*density_scale + phase + line_hash
dist_to_mark = |fract(pos) - 0.5|

// mark irregularity: smooth (continuous 1D noise along the line, its own stream per line, no slot index)
// or hashed (one value per mark from floor(pos): a seam appears once a mark is longer than half a cell)
weight_e  = clamp(weight_g  * (1 + irreg_g*mod_w), 0, 1)
marklen_e = clamp(marklen_g * (1 + irreg_g*mod_l), 0, 1)

// 2026-11-01: feather band = [w*max(1-softness,0), w*(1+softness)], min band aa = 0.01 (cell units), on weight_e / marklen_e
edge = smoothstep(outer_across, inner_across, dist_to_line) * smoothstep(outer_along, inner_along, dist_to_mark)
mark = edge                              // flat-top: the raised-cosine `shape` option was removed 2026-11-01

// color: white unless the across inlet is connected, in which case tinted by its RGB
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

## Promoted 2026-11-01 (Matt): irregularity, tagged modulation textures, compact panel

Everything tried on a scratch copy (`f_weave_char`, `scratch/experiments/f_weave_character/`, local only) is now in the shipped module.
- **Params:** `regularity` became `offset` (inverted), `shape` was removed (only its raised-cosine option is lost; the default was flat-top), and `variant` (menu), `irreg`, `nscale`, `weight_m` / `marklen_m` / `irreg_m` and the `mmode` toggle were added. Saved patches that use `regularity` or `shape`, and presets of them, break; the new params start at their defaults.
- **Tagged textures:** built by the new `mod_inlets` `tag` key in `build/build_patcher.py` (`build/spec.md`, `tests/build/test_build_tag_key.py`), which replaces the scratch copy's post-processing. First consumer. Prototype results (live, Matt): two tagged streams share inlet 0, a pulled cord returns the target to its dial, `mmode` reads as described, an untagged texture alongside tagged ones works, the pix hop did not reproduce (`ideas/named_mod_textures.md`).
- **Panel (232 x 180):** two rows of dials (density, angle, offset, phase, soft / marklen, weight, irreg, noise), a depth numbox under each of weight, marklen and irreg (as in `f_grain`; tinted blue, no label of their own: the hint names the tag), the Variant menu and the Tex uni/bi toggle in the title bar (the menu has no label), the title just "Weave". Hand layout is `patcher["overrides"]` in `definition.py`.
- **Header:** `signal_type` removed (it said `∇ in`); both type dots are the "neither" gray. The panel border stays the standard dark blue.
- **Checked offline:** `tests/modules/weave/test_weave_static.py` (11 checks), the full offline suite, `drift -v f_weave`. **Not checked:** how it looks and behaves in Max with the shipped patch; the live contract bench (`f_weave` is in `INPUT_SIZE`; it has five pix inlets now); a head-to-head of Smooth against Hashed, the `f_droste` check and the long-mark seam check on the variants; T5 (inlet ceiling, three tagged targets only).

## Notes — real discrepancy between spec.md and definition.py

- (Moot since 2026-11-01: the vecfield inlet no longer exists.) **`spec.md`'s "Phase 2 — Vecfield inlet" section describes an `atan2`-based scale-factor design** (`vf_angle = atan2(vy-0.5, vx-0.5)`, added to `angle*π` via an undetermined `SCALE` constant) that was still marked open/undecided (`[ ] Scale factor chosen and documented` unchecked in Phase 2's acceptance criteria). **The shipped `definition.py` codebox instead adds `vx`/`vy` directly into the `cos`/`sin` basis** (`cs = cos(angle*π) + (-vy)`, then renormalized) — a different, simpler mechanism than the spec's sketch, with no `atan2` or scale constant anywhere. Whether this represents Phase 2's actual resolution (undocumented) or a further, unspecced iteration isn't clear from the available files.
- **A second inlet (`scalar potential`, `src_potential`) exists in the shipped module with no corresponding entry anywhere in `spec.md`.** This inlet can fully override the `across` coordinate (rather than perturb it) and also tints output color from white to the potential texture's RGB — a capability not mentioned in the spec at all. This is very likely intended to pair with the also-undocumented `f_vf_potential` module (see `docs/f-reference/f_vf_potential.md`), whose own header comment states exactly this pairing (`f_vf_repulse → f_vf_potential → f_weave (scalar in)`). Treat `spec.md`'s Phase 2/3/4 checklists as stale relative to what's actually built.
- Per HANDOFF.md: Matt flagged f_weave with a vague, unresolved quality concern ("can't put my finger on it yet") — logged as a separate open thread from the `f_grain`/`f_vf_seeds` grid-rigidity discussion, explicitly not assumed related until checked.
- `swing`, `continuity`, and `beats`/`period` (Euclidean rhythm) were all deliberately dropped in Phase 1 — each pulls toward grid/slot structure, which conflicts with the continuous-distance-field architecture that makes this module Droste-safe. See `spec.md`'s "What Was Dropped and Why" for the reasoning if revisiting any of them.
- Listed in `README.md`'s patch table under Generators.

## Source File

`patchers/f_weave.maxpat`
