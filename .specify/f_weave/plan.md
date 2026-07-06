# Implementation Plan: f_weave

**Date:** 2026-06-24
**Spec:** `.specify/f_weave/spec.md`

---

## Summary

f_weave is a band-structure texture generator: luminance output, parametric Euclidean
rhythm along orientation-field-defined bands, optional f_vecfield inlet for additive
field-driven curvature. All logic lives in a single jit.gl.pix codebox; the patcher is
a thin wrapper following standard f_ conventions. The primary implementation risk is the
codebox — specifically the euclidean hit distance function, the curl field, and the
wrap() behavior with integer period values. Phase 1 resolves all three empirically
before any patcher structure is built.

---

## Technical Context

**Environment:** Max 9, Vsynth package, jit.gl.pix gen subpatcher
**Build system:** `tools/build_patcher.py` + `.specify/f_weave/definition.py`
**Primary output:** `@type char` texture
**Vecfield inlet:** float32 (f_vecfield convention: RG=XY, 0.5=zero)
**Scratch location:** `~/Vsynth/patterns/`
**Source of truth:** `patchers/f_weave.maxpat`

**Constitution constraints met:**
- Codebox-before-patcher: Phase 1 is scratch patch only; no JSON written until codebox confirmed
- Specs before building: spec written and reviewed before this plan
- One concern: generator only; processor variant deferred to f_weave_proc
- Vsynth compatible: `@type char` output, routepass pattern, vs_inState for optional inlet

---

## Architecture Decisions

### ADR 1: Single jit.gl.pix, no multipass

**Context:** f_weave computes everything analytically per pixel — orientation field,
band index, Euclidean hit distance, continuity gate. No temporal state, no feedback,
no cross-pixel communication required.

**Decision:** Single stateless jit.gl.pix codebox. No ping-pong texture.

**Rationale:** Everything is deterministic from pixel position + params. The sin hash
provides per-band identity without any cross-pixel aggregation.

**Alternatives:**
- Multipass for accumulation: not needed — there is nothing to accumulate
- CPU-side precomputation of Euclidean patterns: unnecessary complexity

**Consequences:** Simple architecture, easy to debug, no latency issues.

---

### ADR 2: Euclidean hit as unrolled comparison

**Context:** E(k,n) beat positions are `floor(i * period / beats)` for i in 0..beats-1.
Period ≤ 16, beats ≤ 16. GPU shaders can't dynamically index arrays.

**Decision:** Unroll the comparison loop — hardcode checks for all positions up to
period=16. Use user-defined function `euclidean_hit(along_phase, beats, period, swing,
band_seed)` returning a distance float (0.0 = on a hit, 1.0 = maximally between hits).

**Rationale:** Bounded iteration count (≤ 16) makes unrolling tractable. User-defined
functions are confirmed GPU-safe (jit-gen-codebox skill, 2026-06-18). Distance float
return is the distance field requirement.

**Alternatives:**
- Trig-based E(k,n) approximation: less accurate, harder to reason about
- CPU-side precomputation passed as texture: unnecessary complexity for this scale

**Consequences:** Codebox is verbose but correct. beats/period must be enforced ≤ 16
in the patcher before reaching codebox.

---

### ADR 3: Curl field via low-frequency spatial sine

**Context:** The orientation field needs a smooth spatially-varying rotation across the
image to produce fingerprint/contour character at nonzero curl.

**Decision:** Start with `curl_angle = curl * halfpi * sin(px * curl_freq + py *
curl_freq * 0.7)` — a single 2D sinusoid. Phase 1 validates whether this produces
convincing whorls before committing.

**Rationale:** Simplest possible smooth spatial variation. If it produces plausible
fingerprint character empirically, no more complexity needed. If not, upgrade to a
2D sin hash or multi-octave approach.

**Alternatives:**
- 2D sin hash for curl: more varied, more complex — evaluate only if sine insufficient
- Perlin-style: noise() is broken on GPU; would require manual octave sin hash

**Consequences:** Phase 1 must verify this empirically before definition.py is written.

---

### ADR 4: Vecfield inlet drives orientation additively, gated by vs_inState

**Context:** in1 is an optional f_vecfield. When disconnected, vs_black produces
(0,0,0,0) or neutral output. The vecfield angle contribution must be zero when
unconnected.

**Decision:** Use `vs_inState` on in1. Its mode outlet drives a `src_vecfield` param
in the pix codebox (0 = no inlet, 1 = inlet connected). When src_vecfield=0, vecfield
angle contribution is multiplied to zero.

**Rationale:** Standard f_ pattern for optional inlets (established in f_vf_repulse,
f_grain dual-mode). Keeps codebox clean — one multiply gates the entire vecfield
contribution.

**Alternatives:**
- Always sample in1, rely on vs_black outputting 0.5 neutral: vs_black remaps to (-1,-1)
  not neutral — unreliable without the gate
- Separate pix for vecfield decode: unnecessary complexity

**Consequences:** `src_vecfield` is system-driven (not user-facing) — uses `prepend
param` not `attrui`. Does not appear in route, UI objects, or parameters block.

---

### ADR 5: Distance field falloff is mandatory

**Context:** The ideas doc established this as a hard requirement for UV-transform
compatibility (droste, mobius, lens). The alternative (smoothstep on UV coordinate)
aliases at singularity boundaries.

**Decision:** `euclidean_hit()` returns a continuous distance float. `smoothstep` is
applied to that float with `softness` as the edge parameter. The distance value is
never thresholded to 0/1 before smoothstep.

**Rationale:** Droste→weave aliasing is the primary failure mode this prevents. The
ideas doc documents this as the core architectural lesson from f_masonry's smoothstep
approach.

**Consequences:** One acceptance criterion is specifically droste compatibility — test
this before declaring Phase 3 complete.

---

## Dependency Blocks

### Block 1: Codebox verified in scratch patch
**Dependencies:** None
**Builds:** Working weave codebox (orientation field, band rotation, euclidean rhythm,
continuity, phase, distance field output)
**Verification:** Denim character at defaults; fingerprint at high curl; phase animates;
distance field marks visible through droste without singularity aliasing

### Block 2: Vecfield inlet verified in scratch patch
**Dependencies:** Block 1 (working base codebox)
**Builds:** vs_inState gate + vecfield angle contribution
**Verification:** Connecting f_vf_vortex deflects band orientation; disconnecting
returns to param-driven orientation

### Block 3: definition.py + built patcher
**Dependencies:** Blocks 1 + 2 (codebox fully confirmed)
**Builds:** `definition.py`, `patchers/f_weave.maxpat` via build_patcher.py
**Verification:** JSON valid; opens in Max; all params respond; UI correct

### Block 4: Integration + registration
**Dependencies:** Block 3 (working built patcher)
**Builds:** Module registered in f_modules menu; droste compatibility confirmed
**Verification:** Spawns from menu at correct size; droste chain clean

---

## Implementation Phases

### Phase 1 — Codebox in scratch patch

Goal: working codebox with all structural features confirmed empirically.

- [ ] Scaffold scratch patch at `~/Vsynth/patterns/f_weave_scratch.maxpat`
      (vs_render, jit.gl.pix, jit.pwindow, param number boxes)
- [ ] Write `euclidean_hit()` user-defined function; verify E(4,8) and E(7,13)
      produce correct beat positions
- [ ] Verify `wrap(x, 0, period)` with integer period values behaves correctly
- [ ] Implement orientation field: angle param + curl sine field
- [ ] Implement band rotation into local frame (along/across)
- [ ] Implement band_idx hash for per-band phase offset
- [ ] Implement `phase` param scrolling along-band
- [ ] Implement continuity gate (slow spatial hash)
- [ ] Implement distance field mark with softness and weight
- [ ] Verify denim character at defaults (low curl, high continuity, E(4,8))
- [ ] Verify fingerprint character (high curl, low continuity)
- [ ] Verify phase animates smoothly
- [ ] Test marks through f_droste — confirm no singularity aliasing

**Checkpoint:** All acceptance criteria from spec except vecfield inlet and build.

---

### Phase 2 — Vecfield inlet in scratch patch

Goal: additive vecfield orientation contribution confirmed working.

- [ ] Add in2 reference to codebox; add `in 2` gen object; wire
- [ ] Add vs_inState on in1 of scratch pix; wire src_vecfield prepend
- [ ] Implement vecfield angle decode: `atan2(vy - 0.5, vx - 0.5)`
- [ ] Implement additive contribution: `theta += vecfield_angle * src_vecfield`
- [ ] Determine scale factor — test with f_vf_vortex connected; tune for
      expressive but not overwhelming deflection
- [ ] Verify: connected → bands deflect; disconnected → param-only orientation

**Checkpoint:** Vecfield inlet acceptance criteria met.

---

### Phase 3 — definition.py + build

Goal: confirmed codebox promoted to built patcher.

- [ ] Read `tools/spec.md` for definition.py schema
- [ ] Write `.specify/f_weave/definition.py` with confirmed codebox + full
      param contract
- [ ] Run `tools/py.sh tools/build_patcher.py .specify/f_weave/definition.py
      patchers/f_weave.maxpat`
- [ ] Validate JSON: `python3 -c "import json; json.load(open('patchers/f_weave.maxpat'))"`
- [ ] Open in Max; verify all params respond; verify UI layout
- [ ] Wire beats/period enforcement (beats ≤ period) in patcher

**Checkpoint:** Patcher opens, all params work, UI correct.

---

### Phase 4 — Integration + registration

Goal: registered in f_modules, integration-tested, committed.

- [ ] Add to `.specify/f_modules/build_modules.py` under Generators category
- [ ] Add to `javascript/f_addmod.js` SIZES dict (measure presentation_rect)
- [ ] Regenerate f_modules.maxpat; validate JSON; open in Max
- [ ] Confirm f_weave spawns from menu at correct size
- [ ] Integration test: f_weave → f_droste (distance field criterion)
- [ ] Integration test: f_vf_vortex → f_weave (vecfield deflection)
- [ ] Integration test: f_weave → f_vf_fieldmap → f_caustic
- [ ] Update README.md (add f_weave to status table)
- [ ] Update ideas/f_weave.md status or archive
- [ ] Commit: logical units per phase; message per milestone

---

## Complexity Notes

The codebox is the hard part. The euclidean hit unroll for period up to 16 will be
verbose — consider writing it as a user-defined function with nested if/else rather
than a flat unroll, which would be unreadable. The curl sine field is a hypothesis
that must be verified empirically; if it produces grid-like artifacts rather than
smooth whorls, a 2D sin hash for curl is the upgrade path.

The vecfield angle scale factor (Phase 2) requires empirical tuning — no principled
value exists before testing. Document the chosen value and rationale in definition.py
comments.
