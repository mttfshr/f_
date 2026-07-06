# Implementation Plan: f_vortex_multi

**Date**: 2026-06-07
**Spec**: .specify/f_vortex_multi/spec.md

---

## Summary

f_vortex_multi is a dual-mode generator bpatcher that produces a single f_vecfield-encoded float32 texture by summing three independent vortex fields with shared exponential falloff. It follows the f_vortex codebox math exactly, replicated three times and summed. Site positions are set via cx/cy dials and can be overridden at control rate by `center X Y` messages from `vsc_center_ctrl` on three independent position inlets. Built using the standard build_patcher.py pipeline: scratch codebox verification first, then definition.py, then full patcher JSON.

---

## Technical Context

**Platform**: Max 9, jit.gl.pix GPU codebox
**Archetype**: Dual-mode generator (self-generating, inlet 0 unused — present for Vsynth convention compliance)
**Output type**: float32, f_vecfield encoded (RG = XY, 0.5 = zero)
**Build tool**: tools/build_patcher.py from definition.py
**Codebox**: Single jit.gl.pix gen subpatcher with one codebox

**Constraints**:
- All codebox operators from verified-safe set (jit-gen-codebox skill)
- No loops — per-site math unrolled manually (three copies of f_vortex math)
- No `noise()`, `swiz()`, `cycle()`, `snoise()` — known silent failures
- Component access on stored vec4 fails — decode field inline, never store then access
- `numinlets` on jit.gl.pix is read-only — derived from `in N` object count in gen subpatcher

---

## Architecture Decisions

### ADR-001: Additive field combination

**Context**: Multiple vortex sites must be combined into a single field texture.

**Decision**: Sum all three site fields additively, clamp to 0–1 output range.

**Rationale**: Additive combination produces reinforced convergence where sites overlap — physically motivated (multiple lenses), produces smooth field with no visible seams, enables superposition behavior for lumia-style caustic buildup.

**Alternatives considered**:
- Nearest-site Voronoi: hard basin boundaries visible in f_caustic as dark gaps; wrong character for optical effects
- Distance-weighted blend: effectively same as additive with extra normalization step; adds complexity without benefit

**Consequences**:
- Positive: soft field everywhere, superposition works, f_caustic sees a coherent multi-focal field
- Negative: sites at same position produce 3× field magnitude — handled by clamping, acceptable

---

### ADR-002: vsc_center_ctrl for position animation

**Context**: Site positions need to be animatable independently per site at control rate.

**Decision**: Three independent position inlets (inlets 1, 2, 3) accept `center X Y` messages from `vsc_center_ctrl`. Each inlet routes the center message to update that site's cx/cy params, which are then read by the codebox as Params.

**Rationale**: `vsc_center_ctrl` is the established Vsynth pattern for XY position control with LFO animation. It outputs 0–1 normalized floats via `center X Y` message. No custom animation infrastructure needed. Each site inlet is fully independent.

**Alternatives considered**:
- Texture-based position (sample RG from texture at fixed UV): overkill, requires texture routing, no benefit over message-rate control for position
- No animation support (static dials only): too limiting for performance use

**Consequences**:
- Positive: standard Vsynth workflow, three vsc_center_ctrl instances give full independent orbital control
- Negative: adds three inlets beyond the minimal single texture inlet; panel inlet labels must be clear

---

### ADR-003: Shared falloff, per-site convergence and curl

**Context**: Which params are shared vs. per-site?

**Decision**: Shared: falloff, bypass. Per-site: cx, cy, convergence, curl.

**Rationale**: Falloff controls the spatial extent of all fields together — one control feels right for "how spread out is the whole constellation." Convergence and curl are what give each site its distinct optical character and must be independent.

**Consequences**:
- 13 params total: 3×(cx, cy, conv, curl) + falloff + bypass
- UI panel wider than f_vortex — three columns of per-site dials

---

### ADR-004: Codebox math — three unrolled copies of f_vortex

**Context**: jit.gl.pix gen codeboxes cannot loop dynamically.

**Decision**: Replicate the f_vortex field computation verbatim three times with prefixed variable names (s1_, s2_, s3_), sum the fx/fy results before encoding.

**Rationale**: Straightforward, proven math. f_vortex codebox is verified working. Three copies is verbose but unambiguous and debuggable.

**Consequences**:
- Codebox is long (~80 lines) but structurally simple
- Any fix to the per-site math must be applied in three places

---

### ADR-005: Param naming convention

**Decision**: `s1_cx`, `s1_cy`, `s1_conv`, `s1_curl`, `s2_cx`, ... etc. Falloff stays `falloff`. Bypass stays `bypass`.

**Rationale**: Short prefix `s1_`/`s2_`/`s3_` fits within live.dial label display constraints. `conv` not `convergence` — saves label space. Consistent with f_vortex's `convergence` param conceptually.

---

## Implementation Phases

### Phase 1: Scratch codebox verification

Write and verify the three-site additive codebox in a scratch patch before building anything else.

**Steps**:
- Open scratch patch at `~/Vsynth/patterns/` with vs_render running
- Write codebox with three unrolled site computations, additive sum, encode to RG
- Wire f_caustic downstream to verify multi-focal caustic output
- Test: sites at distinct positions → three hot spots; sites superposed → one bright zone; falloff sweep → tighten/spread
- Test: connect vsc_center_ctrl to a position param (via numbox stand-in) to confirm position drives hot spot location

**Exit criterion**: f_caustic shows correct multi-focal behavior, all three sites independently controllable

---

### Phase 2: definition.py

Write `.specify/f_vortex_multi/definition.py` from confirmed codebox.

**Params**:
```
s1_cx      float  0.0–1.0   default 0.3
s1_cy      float  0.0–1.0   default 0.3
s1_conv    float  0.0–1.0   default 0.5
s1_curl    float  -1.0–1.0  default 0.0
s2_cx      float  0.0–1.0   default 0.5
s2_cy      float  0.0–1.0   default 0.5
s2_conv    float  0.0–1.0   default 0.5
s2_curl    float  -1.0–1.0  default 0.0
s3_cx      float  0.0–1.0   default 0.7
s3_cy      float  0.0–1.0   default 0.7
s3_conv    float  0.0–1.0   default 0.5
s3_curl    float  -1.0–1.0  default 0.0
falloff    float  0.0–10.0  default 2.0
bypass     toggle            default 0
```

**Inlets beyond inlet 0**:
- Inlet 1: site 1 position (`center X Y` from vsc_center_ctrl → route → s1_cx / s1_cy dials)
- Inlet 2: site 2 position
- Inlet 3: site 3 position

**Archetype**: dual-mode generator (inlet 0 present for convention, vs_inState, vs_black fallback)

**Exit criterion**: `python3 -c "import json; json.load(open('patchers/f_vortex_multi.maxpat'))"` passes

---

### Phase 3: Build and wire position inlets

Run build_patcher.py, then manually add the three position inlet routing chains:

For each site N:
```
inlet N → routepass jit_gl_texture jit_matrix (unmatched out) → route center → unpack f f → [s_N_cx dial] + [s_N_cy dial]
```

This is the standard Vsynth center message pattern. The `route center` strips the selector, `unpack f f` splits X and Y to the respective dials.

**Exit criterion**: Sending `center 0.2 0.8` to inlet 1 updates s1_cx/s1_cy and moves the corresponding caustic hot spot

---

### Phase 4: Vsynth integration verification

- Load f_vortex_multi in a full Vsynth chain
- Connect f_caustic downstream — confirm multi-focal caustic output
- Connect three vsc_center_ctrl instances (each with a vs_lfo) — confirm independent orbital motion
- Swap f_vortex_multi for f_vortex — confirm f_caustic continues working (drop-in compliance)
- Connect to vs_displacement — confirm spatially coherent displacement

**Exit criterion**: All spec acceptance scenarios pass

---

### Phase 5: Documentation and commit

- Update README.md: add f_vortex_multi to patch table
- Update docs/f-reference/f_vecfield_type.md: mark f_vortex_multi status as Complete in family members table
- Commit

---

## UI Layout Notes

Panel width needs to accommodate three sites × four dials = 12 dials in three groups. Options:
- Three rows (one per site), four dials per row — wider than f_vortex but same height pattern
- Two rows: position row (cx/cy × 3) and character row (conv/curl × 3) — conceptually cleaner, groups by param type

Decision deferred to Phase 2 — lay out in definition.py after seeing how the dial labels fit.

---

## Complexity Notes

The codebox is straightforward — three copies of verified f_vortex math. The only novel complexity is the position inlet routing (Phase 3), which is control-rate Max patching rather than codebox work. This is low risk — the `center` message pattern is standard Vsynth.
