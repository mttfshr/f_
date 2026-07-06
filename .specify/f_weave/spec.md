# f_weave — Spec

## Status: Phase 1 complete — scratch patch verified

## Concept

Parametric line-mark texture generator. Structure is a family of parallel lines running
in a direction set by `angle`, with soft marks placed at intervals along each line. Lines
are defined as continuous distance fields — not grid lanes or indexed bands. Each line
gets a hash-derived phase offset controlled by `regularity`, breaking the mechanical
alignment of marks into row-like structures.

The key architectural insight from Phase 1: **band_idx as grid identity is a masonry
concern, not a weave concern**. Weave lines have no slot structure — marks are placed
along continuous lines using fract-based distance fields. This gives UV-transform
compatibility (droste-safe) without any grid quantization.

Spatial variation of band curvature (fingerprint/contour character) is deferred to the
vecfield inlet — the field provides a smoothly-varying orientation that additive to the
global `angle` param. Single-pass per-pixel orientation rotation was found to alias
catastrophically at any meaningful density; vecfield-driven orientation avoids this by
pre-computing a smooth field upstream.

Output: luminance only. Color is downstream (colorize, f_channel_grader, etc).

## Signal Flow

```
in0  — texture / control (Vsynth convention)
in1  — f_vecfield (optional — adds to param orientation field)
out0 — texture (char, luminance weave output)
```

## Parameter Contract

| Param      | Type  | Range | Default | Description |
|------------|-------|-------|---------|-------------|
| density    | float | 0–1   | 0.5     | Line spacing and mark frequency (log-mapped: pow(2, density*5-1)) |
| angle      | float | 0–1   | 0.0     | Global line orientation (mapped to 0–π) |
| weight     | float | 0–1   | 0.1     | Line thickness — controls across-line mark extent |
| marklen    | float | 0–1   | 0.3     | Mark length along line — controls along-line mark extent |
| regularity | float | 0–1   | 0.5     | 1=all lines in phase (grid-like rows), 0=fully varied per-line offset |
| phase      | float | any   | 0.0     | Animation — scrolls marks along line direction |
| bypass     | bool  | 0/1   | 0       | Standard bypass — outputs mid-grey (0.5) |

**Note:** `regularity` must be clamped to [0,1] in codebox — values outside this range
produce unpredictable hash behavior.

**Deferred params (not in v1):**
- `swing` — systematic offset on alternating marks; reintroduces slot structure, deferred
- `continuity` — band endings/forks; was explored, produced grid artifacts, deferred
- `beats`/`period` — Euclidean rhythm requires a defined meter (slot structure), deferred

## Codebox Architecture

Confirmed working implementation from Phase 1 scratch patch:

```
// Orientation
cs = cos(angle * pi);
sn = sin(angle * pi);
across = norm.x * cs + norm.y * sn;
along  = norm.x * (-sn) + norm.y * cs;

// Density scale (log-mapped)
density_scale = pow(2.0, density * 5.0 - 1.0);

// Distance to nearest line (continuous, no quantization)
dist_to_line = abs(fract(across * density_scale) - 0.5);

// Per-line phase offset (line_idx used only for hash seed, not grid identity)
line_idx = floor(across * density_scale);
line_hash = fract(sin(line_idx * 127.1) * 43758.5453) * (1.0 - clamp(regularity, 0.0, 1.0));
pos = along * density_scale + phase + line_hash;
dist_to_mark = abs(fract(pos) - 0.5);

// Mark: intersection of near-line AND near-mark-position
mark = smoothstep(weight, 0.0, dist_to_line) * smoothstep(marklen, 0.0, dist_to_mark);

// Output
out1 = mix(vec(mark, mark, mark, 1.0), vec(0.5, 0.5, 0.5, 1.0), bypass);
```

**Note on `line_idx`:** `floor(across * density_scale)` is used solely as a hash seed
for per-line phase variation. It is not a grid identity — no slot structure, no
band-indexed rhythm. This is the key distinction from f_masonry's architecture.

## Vecfield Inlet (Phase 2)

When in1 is connected, the vecfield angle is decoded and added to the `across`/`along`
rotation:

```
// Decode vecfield angle at this pixel
vx = sample(in2, norm).x;
vy = sample(in2, norm).y;
vf_angle = atan2(vy - 0.5, vx - 0.5);

// Add to orientation (scale factor TBD from Phase 2 empirical testing)
theta = angle * pi + vf_angle * src_vecfield * SCALE;
cs = cos(theta); sn = sin(theta);
across = norm.x * cs + norm.y * sn;
along  = norm.x * (-sn) + norm.y * cs;
```

`src_vecfield` is a system-driven param (0/1) set by `vs_inState` on in1. Not
user-facing. Scale factor to be determined empirically in Phase 2.

## Distance Field — Architecture Rationale

Both `dist_to_line` and `dist_to_mark` are continuous distance values, never
thresholded before `smoothstep`. This gives:

1. **Droste compatibility** — confirmed in Phase 1: marks compress cleanly toward
   singularity without aliasing. f_masonry's smoothstep-on-UV approach aliases at
   singularity boundaries; f_weave is the correct reference implementation.

2. **UV transform robustness** — works with f_mobius, f_lens, any UV-displacing
   processor.

## Character Space

| weight  | marklen | regularity | Character |
|---------|---------|------------|-----------|
| low     | high    | 0.5        | Stitching / running stitch |
| low     | low     | 0.0        | Scattered dashes |
| high    | high    | 1.0        | Woven surface / continuous fabric |
| high    | low     | 0.5        | Dotted lines |
| any     | any     | 1.0        | Grid-aligned marks (mechanical) |
| any     | any     | 0.0        | Fully staggered (organic) |

## What Was Dropped and Why

**curl param:** Per-pixel orientation rotation aliases catastrophically at any meaningful
density. The sin hash for band identity loses coherence when theta varies per-pixel,
because band_idx jumps unpredictably. Vecfield inlet provides the same capability
correctly — smooth upstream field, no per-pixel derivative discontinuities.

**beats/period (Euclidean rhythm):** Euclidean rhythm requires a defined meter (n slots).
Slots reintroduce grid structure. The continuous fract-based mark placement gives
equivalent density control without metering.

**swing:** All reasonable implementations required floor(pos) slot quantization.
Deferred.

**continuity:** Band endings require per-band identity to define where along a band a
break occurs. This pulls toward grid architecture. Deferred.

## Works Well With

- `f_droste` — marks become spiral rhythm; confirmed clean through singularity ✅
- `f_vf_fieldmap` — weave → fieldmap → vecfield consumer; line structure drives gradient
- `f_vf_advect` — weave as source texture; flow organizes along line structure
- `f_mobius` — lines bend into circles, mark softness preserved
- `f_lens` — weave as surface texture; gradient emboss gives woven relief

## Future Directions

- **v2 swing** — approach that avoids slot quantization (e.g. smooth sinusoidal
  position modulation along the line rather than floor-based offset)
- **v2 continuity** — probabilistic mark absence without band identity (e.g. 2D
  noise gate on mark brightness)
- **f_weave_proc** — processor variant using line/gap mask to selectively process
  incoming texture
- **Color** — map line direction or mark/gap to hue; v1 luminance only

## Archetype

Generator with optional vecfield inlet. Primary output `@type char`. in1 is float32
(f_vecfield convention: RG=XY, 0.5=zero). Follow f_vf_warp / f_vf_streak pattern for
inlet typing.

## Acceptance Criteria

### Phase 1 — Complete ✅
- [x] Clean mark geometry: line + along distance fields working
- [x] `angle` rotates bands cleanly across full 0–1 range
- [x] Per-line phase variation (`regularity`) breaks row alignment
- [x] `phase` param animates marks along line direction smoothly
- [x] Distance field marks survive f_droste without singularity aliasing

### Phase 2 — Vecfield inlet
- [ ] Vecfield inlet deflects line orientation additively
- [ ] Disconnected inlet = param-only orientation (no residual from vs_black)
- [ ] `vs_inState` correctly gates vecfield contribution
- [ ] Scale factor chosen and documented

### Phase 3 — Build
- [ ] definition.py written with confirmed codebox
- [ ] Built patcher opens in Max, all params respond
- [ ] UI layout correct in presentation mode
- [ ] Committed

### Phase 4 — Registration
- [ ] Appears in f_modules menu under Generators
- [ ] Spawns at correct size
- [ ] Integration tests pass
