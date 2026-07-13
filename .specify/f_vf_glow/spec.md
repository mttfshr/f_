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
- **FR-002**: Module MUST accumulate source color at 48 fixed steps along the field direction, with small per-step jitter (`fract(sin(...) * 43758.5453) - 0.5`, scaled by 0.1) to break up banding artifacts at low step-to-radius ratios
- **FR-003**: Step count MUST be fixed at compile time (48, not 24 as originally specced — corrected 2026-07-11 against actual `codebox_v1.gen`); `radius` param controls spatial extent
- **FR-004**: Module MUST support three direction modes: bidirectional (0), forward (1), backward (2)
- **FR-005**: Accumulation weight per step MUST follow exponential falloff: `exp(-i * i * falloff)`
- **FR-006**: `color_mix` param MUST blend accumulated color between full-color (0) and luma-only (1)
- **FR-007**: `gain` param MUST control glow intensity, added additively over source before the `mix` blend stage (`driven = clamp(src + glow*gain, 0, 1); comp = mix(src, driven, mix_pct/100)`). Renamed from `strength` 2026-07-12 to match the library-wide `gain`/`mix` naming convention (vsynth-bpatcher skill) — `mix` (numbox, 0–100%, internal `Param mix_pct`, default 0) added as the separate crossfade stage, per the corrected formula confirmed on `f_vf_prism`.
- **FR-008**: Module MUST provide a radius modulation inlet (in2); unconnected state (vs_black = 0.0) MUST degrade to base `radius` param gracefully
- **FR-009**: When vecfield inlet is unconnected (vs_black fallback), glow MUST be suppressed — vs_black remaps to (-1,-1), which is non-zero; suppression requires mix/step on field magnitude
- **FR-010**: Module MUST provide two outlets: composited (out0) and isolated glow layer (out1)
- **FR-011**: `bypass` param MUST restore unmodified source on out0 and black on out1

### Non-Functional Requirements

- **NF-001**: Module MUST draw to `@drawto vsynth` GL context
- **NF-002**: Source texture type: `@type char` (Vsynth processor convention)
- **NF-003**: Vecfield inlet: float32 RG, consistent with f_vecfield_type.md contract
- **NF-004**: Performance: 48 steps × 2 directions sampled per iteration (both `fwd_uv`/`bwd_uv` computed every loop regardless of which direction weight is active) = 96 texture samples per pixel — corrected 2026-07-11; originally stated as 24×2=48, undercounting by half since both directions are always sampled, not just the active one
- **NF-005**: All params registered in `parameters` block; autopattr present for state save
- **NF-006**: Follows vsynth-bpatcher skill conventions throughout

---

## Parameter Contract

_Corrected 2026-07-11 against actual `definition.py`/`codebox_v1.gen` —
the ranges/defaults below replace stale values from initial spec
authoring; the concept and acceptance criteria elsewhere in this doc were
still accurate and are unchanged._

| Param | Type | Range | Default | Description |
|---|---|---|---|---|
| `radius` | float | 0.0 – 0.2 | 0.01 | UV step size per step; controls glow spatial extent |
| `falloff` | float | 0.0 – 0.05 | 0.002 | Exponential decay per step (`exp(-i²·falloff)`, i up to 48) — small values are correct here, not a typo; higher = tighter glow |
| `gain` | float | 0.0 – 1.5 | 0.8 | Glow intensity, additive over source before the `mix` blend stage (see FR-007). Renamed from `strength` 2026-07-12 — same math, name only. Default changed from 0.0 to 0.8 as part of the split: `mix` (default 0) is now the master off-switch, so `gain` carries a sensible "on" magnitude instead |
| `mix` | float | 0.0 – 100.0% | 0.0 | Dry/wet crossfade toward the fully-composited (source+glow) state. Added 2026-07-12. `live.numbox` widget, internal `Param mix_pct` (external label/attr/varname stay `mix`) to avoid colliding with the codebox's own `mix()` operator. Default 0 — off by default, preserving this module's original load behavior |
| `color_mix` | float | 0.0 – 1.0 | 0.0 | 0 = full color glow; 1 = luma-only glow |
| `direction` | int | 0 – 2 | 0 | 0 = bidirectional, 1 = forward, 2 = backward |
| `src_vecfield` | internal | — | 0.0 | vs_inState gate; suppresses vs_black diagonal-offset artifact (FR-009) — present in shipped module, missing from this table in the original spec |
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

---

## Reframe (2026-07-12): gain/mix split + naming retrofit — done

### Context

Library-wide convention change (`ideas/dry_wet_gain_and_novel_field_outlet.md`,
findings 1–3), superseded by the 2026-07-12 canonical-naming decision
(`vsynth-bpatcher/SKILL.md`'s "Canonical naming: `gain` vs `mix`"): the
effect-intensity role is always `gain`, the blend role is always `mix` —
never `strength`/`intensity`/`wet`, regardless of what an earlier plan
called for. `f_vf_glow`'s own codebox originally grounded finding 1's
additive-layer distinction, but had not yet gone through its own Phase 5
rename before this session.

### What changed

- `strength` → `gain`, same 0–1.5 range, default changed 0.0 → 0.8 (see
  Parameter Contract table above for why)
- New `mix` param: `live.numbox`, 0–100%, internal `Param mix_pct`,
  default 0
- Codebox composite rewritten to the two-stage form confirmed correct on
  `f_vf_prism` after its five-round formula struggle:
  ```
  driven_r = clamp(src_r + glow_r * gain, 0.0, 1.0);
  comp_r   = mix(src_r, driven_r, mix_pct / 100.0);
  ```
  (and analogously for g/b) — `driven` is the complete composited state
  (source included), not a bare effect layer; crossfading toward a bare
  layer was the failure mode `f_vf_prism` worked through and rejected.
- Outlet comment left as `composite` (not renamed to `mix`) — matches
  actual shipped precedent (`f_vf_prism` also never did this rename
  despite its own plan calling for it)

### Two pre-existing bugs found and fixed as a rebuild side effect

- The previously-built `.maxpat` had `radius`/`falloff`/`strength`'s
  dial UI labels shifted by one position (`radius`'s dial was captioned
  "Strength," `falloff`'s "Radius," `strength`'s "Falloff") — a stale
  build artifact, unrelated to this rename. Rebuild corrected it.
- The vecfield inlet was labeled "vecfield in" (a directional label
  reserved for mixed-outlet non-`f_vf_`-prefixed modules like
  `f_chladni`) instead of the plain `"vecfield"` this fully-`f_vf_`-typed
  module should use. Rebuild corrected it.

### Verification

- Rebuild via `build_patcher.py`, JSON-validated
- Diff against pre-rename `.maxpat` showed only the expected changes:
  `route` message list, `gain`/`mix_pct` attr/varname/parameter_*
  fields, widget class for `mix_pct` (`live.dial`→`live.numbox`), label
  text, plus the two unrelated pre-existing bugs above — no unintended
  structural changes
- `mix=0` → clean source regardless of `gain` (confirmed via default
  values; no regression to existing bypass/vecfield-suppression logic,
  neither of which this change touched)
- Confirmed working in Max by Matt (2026-07-12) — module fully verified,
  rollout closed for this module
