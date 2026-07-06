# Implementation Plan: f_vf_warp

**Date:** 2026-06-07
**Spec:** `.specify/f_vf_warp/spec.md`

---

## Summary

`f_vf_warp` is a pure Processor bpatcher that warps a source texture's UV coordinates using an f_vecfield texture. It is the simplest possible vecfield consumer: single-pass, single-sample, two texture inlets, one scalar param. The implementation follows the standard Processor archetype with one extension — a second texture inlet (vecfield) using `vs_inState` with a hidden `src_vecfield` system param to suppress the neutral-offset artifact from `vs_black` fallback.

The codebox is the only novel work. The patcher structure is straightforward and closely follows f_caustic as a reference (also a two-texture-inlet processor). GLSL is written and verified in a scratch patch before the definition file is authored.

---

## Technical Context

**Environment:** Max 9 / Vsynth package
**Primary artifact:** `patchers/f_vf_warp.maxpat`
**Build tool:** `tools/build_patcher.py` from `definition.py`
**Output type:** `@type char` (standard Vsynth processor convention)
**Gen type:** `jit.gl.pix vsynth @name vfwarp_pix`

**Constraints from constitution:**
- Codebox before patcher — GLSL verified in scratch before definition.py is written
- One bpatcher, one concern — no scope creep beyond UV warp
- Vsynth compatibility — routepass pattern, vs_inState, moduleSize chain, attrui wiring

---

## Architecture Decisions

### ADR 1: Pure Processor, not Dual-Mode Generator

**Context:** Spec originally called this a Processor with `vs_inState` on in0, which is the dual-mode generator pattern.

**Decision:** Pure Processor. `routepass → pix in0` directly, no `vs_inState` on in0.

**Rationale:** f_vf_warp has no self-generated content. It is meaningless without a source texture — there is nothing to warp. The dual-mode generator archetype is for patches that produce something useful standalone. f_vf_warp cannot.

**Alternatives considered:**
- Dual-mode with vs_black fallback on in0: would output a warp of a black texture (black), indistinguishable from no-source result but structurally misleading.

**Consequences:**
- Simpler patcher structure — one fewer vs_inState, no src_mode param
- f_vf_warp will appear black if placed with no upstream connection (expected, matches all Vsynth processors)

---

### ADR 2: vs_inState + src_vecfield to suppress vs_black offset artifact

**Context:** When the vecfield inlet (in1) is unconnected, `vs_inState` delivers `vs_black` (all zeros) to the gen. The remap `(0 - 0.5) * 2.0 * strength` produces a constant diagonal offset of `-strength`, not zero. This is incorrect "no field → no warp" behavior.

**Decision:** Use `vs_inState` outlet 1 (connection state 0/1) wired to a hidden `src_vecfield` Param in the codebox. Suppress the offset with `mix(vec(0,0), raw_offset, step(0.5, src_vecfield))`.

**Rationale:** The `mix`/`step` approach uses verified jit.gen operators (no `select()`, no ternary). When unconnected, offset is exactly zero. When connected, offset is fully computed. No mid-gray texture source needed.

**Alternatives considered:**
- `vs_grey` fallback: no such abstraction exists in the Vsynth package.
- Offset by +0.5 baked into codebox default: fragile — depends on vs_black always delivering exactly 0.0.
- Leave artifact unfixed: unacceptable — "no field → pass through" is an acceptance criterion.

**Consequences:**
- One hidden system param (`src_vecfield`) in the patcher — follows the same pattern as `src_mode` in dual-mode generators
- `src_vecfield` must be absent from route, UI, and parameters block
- `vs_inState` outlet 1 wired via `prepend param src_vecfield → pix in0`

---

### ADR 3: Single-sample warp, clamp to edge

**Context:** The NOTES.md describes both single-sample UV warp and multi-step streamline tracing ("flow warp"). Multi-step would require accumulation over N iterations per pixel.

**Decision:** Single-sample only. Clamp to edge on out-of-bounds UV.

**Rationale:** Single-sample is the correct v1 scope. It is O(1) per pixel, unconditionally real-time, and already expressive with strong vector fields. Flow warp is a separate patch concept (f_vf_flow or similar) — it should not share an archetype with f_vf_warp.

**Consequences:**
- No loop constructs in codebox (which are not supported in jit.gen codebox anyway)
- Edge clamp is visible at high strength values — documented as expected behavior

---

### ADR 4: strength range 0–1

**Decision:** `strength` dial range 0.0–1.0, default 0.1.

**Rationale:** At strength=1, UV offset spans ±1 (full texture width/height). This is already an extreme warp in practice. Default 0.1 produces subtle, usable warping with typical vortex fields.

**Open:** May need to extend to 0–2 after testing with weak fields. Revisit post-verification; changing a param range is a trivial spec/definition update.

---

## Implementation Phases

### Phase 1: Codebox verification (scratch patch)

Write and verify the warp codebox in a scratch patch before touching the build system.

**Work:**
- Open `~/Vsynth/patterns/` scratch patch with vs_render and a test texture
- Add jit.gl.pix with two texture inlets (source, vecfield)
- Wire f_vf_vortex to the vecfield inlet; a video/noise source to the source inlet
- Paste codebox; add sliders for strength and src_vecfield
- Verify: warp visible, strength scales correctly, src_vecfield=0 gives zero offset, clamp behavior at edges, bypass line works

**Checkpoint:** Warp is visible and correct in scratch patch. No black output, no compile errors, no silent failures. Codebox is frozen — no further changes after this point.

---

### Phase 2: definition.py

Author the definition file encoding the confirmed codebox and full patcher structure.

**Work:**
- Write `.specify/f_vf_warp/definition.py` with:
  - `archetype: "processor"`
  - Two texture inlets: in0 (source, via routepass), in1 (vecfield, via vs_inState)
  - `src_vecfield` as hidden system param (present in codebox Param declaration, absent from params list)
  - One user param: `strength` (live.dial, 0–1, default 0.1)
  - `bypass_toggle.js` jsui
  - `@type char` on pix
  - Prefix: `vfwarp`
- Validate definition.py structure matches `tools/spec.md` schema before running build

**Checkpoint:** `python3 -c "import json; json.load(open('patchers/f_vf_warp.maxpat'))"` passes. No JSON errors.

---

### Phase 3: Patcher build and inspection

Run build_patcher.py and verify the generated patcher structure is correct.

**Work:**
- `python3 tools/build_patcher.py .specify/f_vf_warp/definition.py`
- Inspect generated JSON: confirm numinlets count on pix, gen in1/in2 present, vs_inState wired correctly to both pix in1 (texture) and in0 (src_vecfield prepend), parameters block complete
- Check that `src_vecfield` is absent from route args, absent from UI objects, absent from parameters block

**Checkpoint:** Patcher JSON is valid and structurally correct per manual inspection.

---

### Phase 4: Vsynth integration testing

Open the built patcher in a live Vsynth patch and verify all acceptance criteria.

**Work:**
- Load f_vf_warp as a bpatcher in a Vsynth patch
- Connect f_vf_vortex → in1, video/noise → in0
- Confirm: warp visible, strength scales it, no-field = passthrough, bypass works
- Save and reload the patch — confirm no crash, no parameter reset
- Test with f_vf_vortex_multi and f_vf_fieldmap if available

**Checkpoint:** All acceptance criteria from spec pass. Patcher survives save/load.

---

### Phase 5: Docs and registration

Update permanent project records.

**Work:**
- Write `docs/f-reference/f_vf_warp.md` (as-built reference: params, signal chain, usage notes, known edge behaviors)
- Update `README.md`: add f_vf_warp to bpatcher table, move from build queue to working
- Update `f_modules` menu: add "Warp" entry to Vecfield category in `.specify/f_modules/build_modules.py`, add size entry to `javascript/f_addmod.js`, regenerate f_modules.maxpat
- Update `HANDOFF.md` for session end

**Checkpoint:** README updated. f_modules menu includes f_vf_warp. Commit message drafted.

---

## Dependency Blocks

| Block | Depends on | Produces |
|---|---|---|
| Phase 1: Codebox | Nothing | Verified GLSL |
| Phase 2: definition.py | Phase 1 (frozen codebox) | Build input |
| Phase 3: Build | Phase 2 | f_vf_warp.maxpat |
| Phase 4: Integration | Phase 3 + Vsynth env | Verified working patch |
| Phase 5: Docs | Phase 4 (confirmed working) | Updated project records |

The critical gate is Phase 1 → 2: do not write the definition file until the codebox is confirmed working in scratch. Changing the codebox after building requires a rebuild.

---

## Complexity Notes

This is a low-complexity build. The patcher structure is well-understood (matches f_caustic's two-inlet processor pattern). The only novel element is the `src_vecfield` suppression pattern, which is a one-line codebox addition and a single wire in the patcher.

The main risk is the `mix`/`step` suppression failing in jit.gen — but both operators are empirically verified. If for any reason it fails, fallback is to branch in the codebox using `src_vecfield > 0.5` as a float comparison (also verified safe).
