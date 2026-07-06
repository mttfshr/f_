# Feature Specification: f_vortex_multi

**Created**: 2026-06-07
**Status**: Draft

---

## Overview

A three-site vortex vector field generator. Produces a single f_vecfield-encoded float32 texture by summing three independent vortex fields, each with distance-weighted falloff. Designed as a drop-in replacement for f_vortex wherever multi-focal caustic and optical effects are desired. Primary consumer: f_caustic.

The three sites contribute additively — each pixel receives the sum of all three vortex fields, weighted by each site's exponential falloff. Sites close together reinforce convergence; sites far apart create independent focal zones. Soft field boundaries mean no visible seams in downstream consumers.

Site positions are set via cx/cy dials (static base position) and can be animated by connecting a `vsc_center_ctrl` to each site's position inlet. Each site has its own independent position inlet, so three separate `vsc_center_ctrl` instances can drive the three sites independently — including LFO-driven orbital motion.

---

## User Stories

### User Story 1 — Multi-focal caustic field (Priority: P1)

A performer can connect f_vortex_multi to f_caustic to produce a caustic pattern with up to three independent focal zones, each with its own position and character.

**Why this priority**: This is the primary use case. Everything else is secondary to this working correctly and beautifully.

**Independent Test**: Connect f_vortex_multi output to f_caustic vec field inlet. Confirm caustic hot spots appear at each site position. Move a site position dial and confirm the corresponding hot spot moves. Confirm all three sites active simultaneously produce three overlapping caustic clusters.

**Acceptance Scenarios**:

1. **Given** three sites at distinct positions, **When** f_caustic consumes the field, **Then** three caustic hot spots are visible at approximately those positions
2. **Given** two sites moved close together, **When** f_caustic consumes the field, **Then** a single reinforced caustic zone is visible (additive intensity)
3. **Given** all three sites at the same position, **When** f_caustic consumes the field, **Then** a single bright caustic zone results — equivalent to a high-intensity single vortex
4. **Given** one site's convergence set to zero, **When** f_caustic consumes the field, **Then** that site's caustic hot spot disappears but the other two remain

---

### User Story 2 — Per-site independent character (Priority: P1)

A performer can set independent convergence and curl values per site, giving each focal zone its own rotational and convergence character.

**Why this priority**: Without per-site convergence/curl, all three sites are identical and the module adds no expressive value over running three f_vortex instances.

**Independent Test**: Set site 1 convergence high, site 2 convergence low, site 3 curl nonzero. Confirm visually distinct caustic character at each site's location.

**Acceptance Scenarios**:

1. **Given** site 1 has high convergence and sites 2/3 have zero convergence, **When** the field is consumed by f_caustic, **Then** only site 1 produces a bright caustic zone
2. **Given** site 1 has positive curl and site 2 has negative curl, **When** the field is consumed, **Then** streamlines spiral in opposite directions around each site

---

### User Story 3 — Independent site position animation (Priority: P1)

A performer can connect a vsc_center_ctrl (driven by LFOs or other Vsynth sources) to each site's position inlet to animate site positions independently in real time.

**Why this priority**: Static positions are useful but the primary expressive value of multi-site fields is in motion — orbiting focal zones, breathing constellations, choreographed light placement. This is what separates f_vortex_multi from just placing three f_vortex instances manually.

**Independent Test**: Connect three vsc_center_ctrl instances (each driven by a vs_lfo at different rates) to the three site position inlets. Confirm each caustic hot spot moves independently according to its LFO.

**Acceptance Scenarios**:

1. **Given** a vsc_center_ctrl connected to site 1 position inlet, **When** the controller outputs a new center position, **Then** site 1's caustic hot spot moves to that position
2. **Given** three vsc_center_ctrl at different LFO rates on each site inlet, **When** LFOs run, **Then** three caustic hot spots orbit independently with no cross-interference
3. **Given** no vsc_center_ctrl connected to a site inlet, **When** the field is computed, **Then** that site uses its cx/cy dial values as static position (vs_black fallback = center 0.5, 0.5)

---

### User Story 4 — Shared falloff control (Priority: P2)

A performer can control the falloff rate globally, setting how tightly each site's field is concentrated vs. how broadly it spreads across the frame.

**Why this priority**: Falloff determines whether sites feel like tight points of light or broad atmospheric zones. One shared control is sufficient — per-site falloff would add complexity without clear benefit.

**Independent Test**: With three sites spread across the frame, sweep falloff from low to high. Confirm caustic clusters tighten and separate at high falloff, and spread and merge at low falloff.

**Acceptance Scenarios**:

1. **Given** low falloff, **When** sites are near each other, **Then** fields overlap substantially and caustic energy blends between sites
2. **Given** high falloff, **When** sites are well-separated, **Then** caustic hot spots are tight and distinct with dark field between them

---

### User Story 5 — f_vecfield type contract compliance (Priority: P1)

f_vortex_multi produces a float32 texture conforming to the f_vecfield type contract, making it interchangeable with f_vortex as a field source for any f_vecfield consumer.

**Why this priority**: Type contract compliance is what makes the module composable. Without it, the module is a dead end.

**Independent Test**: Swap f_vortex_multi for f_vortex in an existing f_caustic signal chain without changing any other connections. Confirm f_caustic continues to function correctly.

**Acceptance Scenarios**:

1. **Given** f_vortex_multi connected to f_caustic, **When** the patch loads, **Then** f_caustic produces output without errors or black frames
2. **Given** f_vortex_multi connected to vs_displacement, **When** a source texture is displaced, **Then** displacement behavior is visible and spatially coherent

---

### User Story 6 — Bypass (Priority: P2)

A performer can bypass f_vortex_multi, outputting a neutral field (all 0.5) without disconnecting it from the signal chain.

**Why this priority**: Consistent with all other f_ modules. Allows live toggling without patch rewiring.

**Independent Test**: With bypass on, confirm f_caustic downstream shows no caustic effect (neutral field = zero vectors = no streamline deviation).

**Acceptance Scenarios**:

1. **Given** bypass enabled, **When** the field is consumed by f_caustic, **Then** no caustic pattern is visible — output is a flat neutral field
2. **Given** bypass toggled off, **When** the field is consumed, **Then** caustic pattern returns immediately

---

## Requirements

### Functional Requirements

- **FR-001**: Output MUST be a float32 texture encoding RG = XY vector components in 0–1 range with 0.5 = zero vector
- **FR-002**: B channel MUST be 0.5, A channel MUST be 1.0 (f_vecfield contract)
- **FR-003**: Each of three sites MUST have independent cx, cy, convergence, and curl parameters
- **FR-004**: All three sites MUST share a single falloff parameter
- **FR-005**: Site contributions MUST be summed additively with per-site exponential falloff
- **FR-006**: Summed field MUST be clamped to 0–1 before output
- **FR-007**: Each site MUST have an independent position inlet accepting center messages from vsc_center_ctrl
- **FR-008**: When a site position inlet is unconnected, that site MUST use its cx/cy dial values as static position
- **FR-009**: Bypass MUST output a neutral field (all channels 0.5) when enabled
- **FR-010**: Module MUST conform to Vsynth bpatcher conventions (presentation panel, live.dial params, attrui wiring, bypass_toggle)
- **FR-011**: Module MUST be usable as a drop-in replacement for f_vortex on any f_vecfield consumer inlet

### Non-Functional Requirements

- **NF-001**: Codebox MUST compile and run on GPU via jit.gl.pix without silent failures
- **NF-002**: All codebox operators MUST be from the verified-safe set in the jit-gen-codebox skill
- **NF-003**: UI panel MUST fit within standard Vsynth bpatcher presentation dimensions
- **NF-004**: Parameter names MUST follow f_vortex naming convention with site prefix (e.g. s1_cx, s1_cy, s1_conv, s1_curl)
- **NF-005**: Position inlet message handling MUST use routepass/route pattern consistent with Vsynth control conventions

---

## Success Criteria

1. f_vortex_multi connected to f_caustic produces visually distinct multi-focal caustic patterns with three independently positionable hot spots
2. Three vsc_center_ctrl instances at different LFO rates produce three independently orbiting caustic hot spots
3. Sites in superposition produce additive caustic intensity (brighter than any single site)
4. The module is indistinguishable from f_vortex at the signal level — any f_vecfield consumer accepts it without modification
5. Bypass produces a completely neutral field with no residual caustic effect

---

## Edge Cases

- **All sites at same position**: additive field is 3x single-site magnitude — clamping handles 0–1 constraint; caustic shows a single very bright zone
- **Site outside 0–1 UV range**: field still computed correctly; site has no effect on the visible frame
- **All convergence and curl at zero**: all sites produce zero vectors; output is flat neutral field identical to bypass
- **Very low falloff (near zero)**: field spreads uniformly; all three sites contribute nearly equally everywhere; caustic becomes a broad uniform glow
- **Very high falloff**: each site's field is extremely local; caustic hot spots are tight pinpoints with dark field between them
- **vsc_center_ctrl disconnected mid-performance**: site falls back to static cx/cy dial position

---

## Out of Scope (v1)

- Per-site falloff (shared falloff is sufficient for v1)
- Modulation inlets for convergence/curl (can be added in v2 following f_vortex pattern)
- More than three sites
- Voronoi / nearest-site-wins combination mode
- Animation or LFO built into the module itself
