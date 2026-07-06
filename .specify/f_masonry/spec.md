# Spec: f_masonry

_Last updated: 2026-05-30_
_Renamed from f_weave — see ideas/scratchpad.md for f_weave resurrection notes_

## What it does

A parametric masonry texture **source** — generates luminance output from parameters alone, no texture inlet. Produces banded textures ranging from crisp mechanical regularity (running bond brick, ashlar stone) to organic broken-course structures, controlled by an orientation field, brick frequency and regularity along each course, a skip gate across courses, and per-course animation with variable drift.

The masonry metaphor is precise: courses are horizontal rows of brick, bond controls how many bricks span a course, mortar controls the brick-to-joint ratio, offset staggers bricks between courses (0 = stacked bond, 0.5 = running bond), and drift shifts individual bricks off their ideal positions.

**Not a fingerprint renderer.** Complex spatial deformation is downstream's job — f_droste, f_mobius, f_lens. f_masonry produces a clean course structure those processors can work on.

**Acceptance criteria:**
- At default settings, produces a visible regular brick texture
- `angle` rotates course orientation continuously across 0–1 with no discontinuity
- `courses` controls course spacing; `bond` independently controls brick frequency along courses
- `regularity` at 1.0 produces evenly spaced bricks on an even grid (nearest-candidate-wins search, no bias); at 0.0 produces genuinely uneven brick spacing as an emergent property of contested territory in the candidate search — **does NOT preserve the same average density at low regularity** (superseded 2026-07-05, see plan.md ADR 7 — accepted tradeoff for expressiveness)
- `drift` shifts bricks off their ideal positions via real migration across slot boundaries (candidate-search architecture, plan.md ADR 7); noticeable at 0.3, dramatic at 0.8 — previously only reshuffled phase within a fixed, never-moving slot, which produced a "sliced barcode" look at high drift rather than genuine displacement (bug found + root-caused 2026-07-05)
- `offset` at 0.0 gives stacked bond; at 0.5 gives running bond
- `skip` at 1.0 gives throughlines (all courses present); at 0.0 courses are fragmentary
- `mortar` scales brick size noticeably relative to joint
- `softness` blends brick edges from hard to soft
- `phase` scrolls bricks along courses; wiring a vs_lfo produces continuous animation
- `speed_var` causes adjacent courses to drift at different rates; at 0 all courses move together
- `bypass` outputs black
- No parameter change causes a hash redraw (stable texture identity across sweeps)

---

## Signal Chain

f_masonry is a **source**: one `jit.gl.pix`, texture+control inlet (routepass pattern — texture pass-through triggers render even though texture is unused by codebox).

```
in0 (texture + ctrl) → routepass jit_gl_texture jit_matrix <params...>

routepass out0 (texture) → pix in0   [render trigger]
routepass param outs → live.dials → prepend param <name> → pix in0

pix out0 → out0 (texture out)
```

Bypass outputs black: `mix(brick_luma, vec4(0.0), bypass)`.

---

## Codebox Architecture

**Prefix:** `masonry`  
**Object name:** `masonry_pix`

### Parameters

| Param | UI Object | Range | Default | Notes |
|---|---|---|---|---|
| `angle` | live.dial | 0.0–1.0 | 0.0 | Mapped to 0–π in codebox |
| `courses` | live.dial | 0.0–1.0 | 0.5 | Log-mapped course spacing (replaces `density`) |
| `bond` | live.dial | 0.0–1.0 | 0.5 | Log-mapped brick frequency along courses (replaces `freq`) |
| `offset` | live.dial | 0.0–1.0 | 0.5 | Phase shift between adjacent courses; 0 = stacked, 0.5 = running bond |
| `mortar` | live.dial | 0.0–1.0 | 0.5 | Brick-to-joint ratio; higher = more brick, less joint (replaces `weight`) |
| `softness` | live.dial | 0.0–1.0 | 0.2 | Brick edge softness |
| `regularity` | live.dial | 0.0–1.0 | 1.0 | 1 = nearest-candidate-wins (even grid), 0 = priority bias lets candidates win contested territory (uneven spacing, density not preserved — ADR 7) |
| `drift` | live.dial | 0.0–4.0 | 0.0 | Per-brick positional displacement; drives real migration across slot boundaries via candidate search (ADR 7). Range confirmed correct 2026-07-05 — this was always 0.0–4.0 in production `definition.py`; this doc previously and incorrectly said 0.0–1.0 |
| `phase` | live.dial | 0.0–1.0 | 0.0 | Global phase offset; intended to be driven by vs_lfo |
| `speed_var` | live.dial | 0.0–1.0 | 0.0 | Per-course speed variation; 0 = all courses same speed |
| `skip` | live.dial | 0.0–1.0 | 1.0 | Course presence gate; 1 = all present, 0 = sparse (replaces `continuity`) |
| `bypass` | live.dial | 0.0–1.0 | 0.0 | Outputs black when 1.0 |
| `width` | live.dial | 0.0–1.0 | 0.5 | Brick aspect ratio (width vs height) |
| `roundness` | live.dial | 0.0–1.0 | 0.0 | Rect to round brick shape blend |
| `course_color` | live.dial | 0.0–1.0 | 0.0 | Per-course color divergence (replaces `band_diverge`) |
| `brick_color` | live.dial | 0.0–1.0 | 0.0 | Per-brick color divergence (replaces `mark_diverge`) |

All params are continuous floats — all `live.dial`.

### Seed params (numbox)

Two integer seed values exposed as `live.numbox` in int mode, for reseeding the hash functions independently:

| Param | UI Object | Range | Default | Notes |
|---|---|---|---|---|
| `course_seed` | live.numbox | 0–999 | 0 | Seeds per-course hash (skip gate, speed variation, course color) |
| `brick_seed` | live.numbox | 0–999 | 0 | Seeds per-brick hash (regularity, drift, brick color) |

---

## Phase 5 — Modulation Inlets

### What it does

Adds three independent texture modulation inlets to `f_masonry`, each sampling
in a distinct coordinate space. Each inlet accepts any texture, samples it in
its space, and applies the result to a performer-chosen parameter with bipolar
depth control.

The three spaces are architecturally distinct and none is redundant:

- **Slot mod** — sampled at brick identity coordinates. One value per brick
  unit, constant within a brick. A profile strip on this inlet gives per-course
  or per-column variation at the resolution of the brick grid.
- **Brick mod** — sampled at intra-brick coordinates. Tiles the texture onto
  every brick face independently. Sub-brick variation that repeats per brick.
- **Pixel mod** — sampled at screen-space coordinates. Continuous across the
  whole field with full 2D spatial coherence. The brick structure articulates
  this field into discrete structural variation.

All three use the same target/depth param model: int chooser (0=none, then
named targets) and bipolar depth float. The `_eff` convention carries forward.

### Inlets

**Inlet 1 — slot mod** (texture in, sampled at brick identity space)
```
slot_sample = sample(in2, vec(slot/bond_scale, band_idx/course_scale)).r
```
One value per brick unit. Quantized — all pixels inside a brick share the
same sample coordinate and therefore the same delta.

**Inlet 2 — brick mod** (texture in, sampled at intra-brick space)
```
brick_sample = sample(in3, vec(along_frac, across_phase)).r
```
`along_frac = along_cont - floor(along_cont)` — fractional position along slot.
`across_phase = wrap(across * course_scale, 0.0, 1.0)` — fractional position
within course. Both are already computed in the geometry block. Tiles the
texture per brick face.

**Inlet 3 — pixel mod** (texture in, sampled at screen space)
```
pixel_sample = sample(in4, norm).r
```
Continuous across the field. The brick structure articulates the resulting
modulation into structural variation — this is not the same as applying a
texture upstream, which gets chopped by the brick mask rather than modulating
brick structure.

### New params

| Param | Type | Range | Default | Description |
|---|---|---|---|---|
| `slot_mod_target` | int chooser | 0–N | 0 | Which param slot-mod drives; 0=none |
| `slot_mod_depth` | float | -1.0–1.0 | 0.0 | Modulation depth; negative inverts |
| `brick_mod_target` | int chooser | 0–N | 0 | Which param brick-mod drives; 0=none |
| `brick_mod_depth` | float | -1.0–1.0 | 0.0 | Modulation depth; negative inverts |
| `pixel_mod_target` | int chooser | 0–N | 0 | Which param pixel-mod drives; 0=none |
| `pixel_mod_depth` | float | -1.0–1.0 | 0.0 | Modulation depth; negative inverts |

Target list is the same for all three inlets. Targets to be confirmed during
codebox development — start with mortar, drift, offset and expand as use cases
emerge.

### Codebox design

Three new `in` objects: `in 2` (slot mod), `in 3` (brick mod), `in 4` (pixel mod).

Centering and depth scaling is identical for all three:
```
slot_delta  = (slot_sample  - 0.5) * slot_mod_depth  * 2.0
brick_delta = (brick_sample - 0.5) * brick_mod_depth * 2.0
pixel_delta = (pixel_sample - 0.5) * pixel_mod_depth * 2.0
```

Each `_eff` variable accumulates deltas from all three inlets for its target:
```
mortar_eff = clamp(mortar + slot_delta  * slot_is_mortar
                          + brick_delta * brick_is_mortar
                          + pixel_delta * pixel_is_mortar, 0.0, 1.0);
```

Geometry block ordering: brick mod requires `along_frac` and `across_phase`,
which depend on the full geometry block. Slot mod requires `band_idx` and
`slot`, which are computed early. Pixel mod requires only `norm`. All three
samples must be taken after sufficient geometry is available — the ordering
established in phase5c (geometry first, then sampling) carries forward.

### Neutral behavior when unconnected

`depth` defaults to 0.0 for all three inlets. Unconnected inlet → black
texture → sample returns 0.0 → delta = -depth = 0.0. Safe at any target.

### Signal chain addition

```
inlet 1 (slot mod)  → pix in 2
inlet 2 (brick mod) → pix in 3
inlet 3 (pixel mod) → pix in 4
route slot_mod_target slot_mod_depth brick_mod_target brick_mod_depth
      pixel_mod_target pixel_mod_depth → prepend param → pix in 0
```

Mod inlets wire directly to pix — no routepass needed.

### Convention carried forward

- Mod inlets wire directly to pix (not through routepass)
- Centering: `(sample - 0.5) * depth * 2.0` for zero-neutral modulation
- Depth defaults to 0.0 — safe with unconnected inlet
- Chooser as int param, 0=none, then named targets
- `_eff` suffix for modulated versions of params in codebox
- Multiple inlets can target the same param — deltas accumulate additively

---

## Open Questions / Deferred

- **Target list partitioning — working hypothesis:** Structural params (offset, drift, speed_var, phase, regularity, skip, quantize) belong to A (slot space) — modulating these from intra-brick or screen space breaks slot quantization or causes circularity. Appearance params (mortar, softness, width, roundness, course_color, brick_color) belong to B and C. This is principled but not final — using B and C in practice may reveal that some appearance params become redundant when pixel-level modulation is available, or that the partition needs refinement. Treat as discovery.
- **Param redundancy:** pixel mod (C) may make some base params unnecessary — e.g. if screen-space mortar modulation gives enough control, a separate mortar base param adds little. To be discovered through use.
- **Angle compensation:** when `angle` is non-zero, slot mod sampling in `band_idx/course_scale` no longer aligns with screen courses. Correcting for angle in the sample coordinate is deferred.
- **Multiple targets per inlet:** currently one mod amount per param per inlet. If simultaneous multi-param modulation from one inlet is needed, revisit.

## jit.gen Operator Notes (confirmed)

- `frac()` not available — use `wrap(x, 0.0, 1.0)`
- `noise()`, `snoise()`, `cycle()` not available — use arithmetic hash: `sin(x * large_prime) * 43758.5`, then `h - floor(h)`
- `vec2`, `float2` not available for noise input — scalar hash is fine
- `select()` not available — use `mix(a, b, step(threshold, val))`
- `sqrt()` may cause compile errors — use `pow(x, 0.5)`
- `shape`, `band`, `cell` are reserved words — avoid as variable names
