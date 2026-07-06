# Feature Specification: f_vf_glow

**Created**: 2026-06-16
**Status**: Draft

---

## Concept

A vecfield consumer + processor that produces a directional glow shaped by the topology of an incoming vecfield. At each pixel, samples the source texture at N steps along (and/or against) the local field direction, accumulates color with exponential falloff, and composites the result over the source. Unlike radially symmetric bloom, the glow is anisotropic — it follows field streamlines, producing halos that align with vortex arms, gradient flows, or any other field structure.

The primary output is a composited texture (source + glow). A second outlet provides the isolated glow layer for downstream blending flexibility.

---

## User Stories

### User Story 1 — Field-aligned glow on a source texture (Priority: P1)

A performer connects a source texture and a vecfield; the module outputs a glow that traces the field topology rather than spreading uniformly.

**Why this priority**: Core value proposition. Without this the module is just a blur.

**Independent Test**: Connect a solid-color source with a vortex vecfield. Glow should arc along vortex streamlines, not radiate evenly from bright areas.

**Acceptance Scenarios**:
1. **Given** source + vecfield connected, **When** `radius` is increased, **Then** glow extends further along field streamlines
2. **Given** a vortex field, **When** viewed at default params, **Then** glow traces curved arcs, not circular halos
3. **Given** no vecfield connected (`vs_black` fallback), **When** module is active, **Then** glow is suppressed (zero field → no displacement → neutral accumulation)
4. **Given** `bypass` engaged, **When** viewed, **Then** output is identical to input source

### User Story 2 — Direction control (Priority: P1)

A performer can choose whether glow trails behind, leads ahead, or surrounds the source along field streamlines.

**Why this priority**: Forward vs. bidirectional vs. backward produces meaningfully different aesthetics — trailing glow vs. halo vs. leading bloom. This is a primary expressive axis.

**Acceptance Scenarios**:
1. **Given** `direction = bidirectional`, **When** viewed, **Then** glow extends symmetrically along both field directions from each pixel
2. **Given** `direction = forward`, **When** viewed, **Then** glow extends only in the positive field direction (trailing effect relative to field flow)
3. **Given** `direction = backward`, **When** viewed, **Then** glow extends only against the field direction (leading bloom)

### User Story 3 — Falloff and color control (Priority: P1)

A performer can tune how quickly the glow fades with distance and how chromatic it is.

**Acceptance Scenarios**:
1. **Given** `falloff = 0` (minimum), **When** viewed, **Then** glow weight is nearly uniform across all steps (wide, diffuse)
2. **Given** `falloff = 1` (maximum), **When** viewed, **Then** glow weight drops sharply after first few steps (tight, concentrated near source)
3. **Given** `color_mix = 0`, **When** viewed, **Then** glow carries full source color (chromatic glow)
4. **Given** `color_mix = 1`, **When** viewed, **Then** glow is luma-only (neutral/white glow regardless of source hue)

### User Story 4 — Spatially-varying radius via modulation inlet (Priority: P2)

A performer can connect a texture to the radius mod inlet to produce spatially varying glow extent — tighter glow in some regions, wider in others.

**Acceptance Scenarios**:
1. **Given** a gradient texture connected to radius mod inlet, **When** viewed, **Then** glow extent varies smoothly across the frame
2. **Given** no radius mod inlet connected (`vs_black` fallback at 0.0), **When** viewed, **Then** behavior is identical to modulation-free mode (base `radius` param governs)

### User Story 5 — Isolated glow layer outlet (Priority: P2)

A performer can tap the raw glow layer (before composite) for independent downstream processing or blending.

**Acceptance Scenarios**:
1. **Given** out1 connected to a downstream processor, **When** viewed, **Then** signal carries only the accumulated glow with no source texture
2. **Given** `bypass` engaged, **When** out1 examined, **Then** isolated outlet outputs black (glow is suppressed)

---

## Requirements

### Functional Requirements

- **FR-001**: Module MUST consume a float32 RG vecfield texture (f_vecfield convention: 0.5 = zero vector) on in1
- **FR-002**: Module MUST accumulate source color at 24 fixed steps along the field direction
- **FR-003**: Step count MUST be fixed at compile time (24); `radius` param controls spatial extent
- **FR-004**: Module MUST support three direction modes: bidirectional (0), forward (1), backward (2)
- **FR-005**: Accumulation weight per step MUST follow exponential falloff: `exp(-i * i * falloff)`
- **FR-006**: `color_mix` param MUST blend accumulated color between full-color (0) and luma-only (1)
- **FR-007**: `strength` param MUST control wet/dry mix of glow over source
- **FR-008**: Module MUST provide a radius modulation inlet (in2); unconnected state (vs_black = 0.0) MUST degrade to base `radius` param gracefully
- **FR-009**: When vecfield inlet is unconnected (vs_black fallback), glow MUST be suppressed — vs_black remaps to (-1,-1), which is non-zero; suppression requires mix/step on field magnitude
- **FR-010**: Module MUST provide two outlets: composited (out0) and isolated glow layer (out1)
- **FR-011**: `bypass` param MUST restore unmodified source on out0 and black on out1

### Non-Functional Requirements

- **NF-001**: Module MUST draw to `@drawto vsynth` GL context
- **NF-002**: Source texture type: `@type char` (Vsynth processor convention)
- **NF-003**: Vecfield inlet: float32 RG, consistent with f_vecfield_type.md contract
- **NF-004**: Performance: 24 steps × 2 directions (max 48 samples) per pixel — acceptable on target GPU for standard Vsynth resolutions
- **NF-005**: All params registered in `parameters` block; autopattr present for state save
- **NF-006**: Follows vsynth-bpatcher skill conventions throughout

---

## Parameter Contract

| Param | Type | Range | Default | Description |
|---|---|---|---|---|
| `radius` | float | 0.0 – 0.2 | 0.05 | UV step size per step; controls glow spatial extent |
| `falloff` | float | 0.0 – 5.0 | 1.5 | Exponential decay per step; higher = tighter glow |
| `strength` | float | 0.0 – 1.0 | 0.8 | Glow wet/dry mix over source |
| `color_mix` | float | 0.0 – 1.0 | 0.0 | 0 = full color glow; 1 = luma-only glow |
| `direction` | int | 0 – 2 | 0 | 0 = bidirectional, 1 = forward, 2 = backward |
| `bypass` | float | 0.0 – 1.0 | 0.0 | Standard bypass |

---

## Success Criteria

1. Glow visibly traces vortex field streamlines rather than spreading radially — distinguishable from isotropic bloom at a glance
2. All three direction modes produce perceptually distinct results on a vortex field
3. Unconnected vecfield inlet produces no glow (not arbitrary noise)
4. Unconnected radius mod inlet is indistinguishable from no modulation inlet
5. Isolated outlet carries only the glow layer — confirmed by connecting it solo to a viewer
6. Performance is acceptable at 1280×720 on target hardware (no dropped frames in Vsynth render loop)

---

## Edge Cases

- **vs_black on vecfield inlet**: `vs_black` remaps to (-1,-1), not (0,0) — field magnitude is non-zero, so naive implementation produces glow in a fixed direction on unconnected patches. Must suppress via `step(magnitude_threshold, magnitude)` or `mix` on scalar magnitude.
- **vs_black on radius mod inlet**: 0.0 texture value → radius mod contribution is 0.0 → `radius_effective = radius_base + 0.0 * scale` — graceful degradation if mod is additive. Or: `radius_effective = radius_base * (1.0 + mod)` — needs careful default so unconnected = no change.
- **Zero-magnitude field region**: At field singularities (vortex center), field magnitude → 0. Steps go nowhere; accumulation converges on source pixel. Result should be a tight spot with no spread — correct behavior, no special case needed.
- **Radius = 0**: Steps have zero UV delta; all samples land on source pixel; accumulation = source color × sum of weights. `strength` mix then adds that back over source — effectively a brightness boost. Acceptable degenerate case.
- **Very high falloff (>>5)**: Weight at step 2 ≈ exp(-4 * 5) ≈ 0 — effectively only step 0 contributes. Glow disappears. Acceptable.
