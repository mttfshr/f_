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

---

### ADR 5: dry/wet crossfader (finding 1, 2026-07-11)

**Context**: Library-wide convention change (`ideas/dry_wet_gain_and_novel_field_outlet.md`,
finding 1). `f_vf_warp` is the replacement-type shape — `out1`/`out2`
are full remapped images, not an additive layer — which finding 1
identifies as the textbook clean case for a direct crossfade, no
gain/wet split needed the way the additive-layer group required. Unlike
`f_vf_advect`/`f_caustic`, though, this module currently has no blend
control at all: `out1` is unconditionally fully-warped (or
fully-source-on-bypass), with `strength` controlling depth, not blend.

Also corrects two things caught while writing this reframe (see
spec.md's parallel correction): this doc previously described a
single-outlet module, when `definition.py` has had a second outlet
(`warped`) for some time; and `out2` currently doesn't respect bypass at
all (`out2 = warped_sample`, unconditional) — the only module in this
whole rollout with that asymmetry.

**Decision**:
- Add `wet` param, float 0–1, crossfader widget (check
  `vsynth-bpatcher/SKILL.md` convention)
- `out1 = mix(mix(source, warped, wet), source, bypass)`
- Leave `strength` (0–1.5, warp depth) as-is — correct gain-equivalent
  for this shape
- `out2 = mix(warped, source, bypass)` — makes out2 respect bypass,
  matching every other module's isolated/raw-outlet convention in this
  library rather than leaving this module as the sole exception
- Outlet comment: `composite` → `mix`

**Rationale**: Simpler than the additive-layer group's two-stage
gain-then-wet form — no layer to compute before blending, `wet` blends
directly between source and warped. Matches finding 1's prediction for
this shape exactly.

**Alternatives considered**:
- Leave out2's bypass behavior unconditional (as shipped) — considered,
  rejected in favor of consistency with the rest of the library; flagged
  as a real behavior change from current shipped code, not a silent
  correction, since a performer relying on the current always-warped
  out2 would see a change

**Consequences**:
- Positive: this module needs less new complexity than the additive-
  layer group despite needing genuinely new architecture (unlike
  `f_caustic`/`f_vf_advect`, which already had the shape) — only one
  new param, no two-stage composite math
- Negative: out2's bypass-behavior change is a real functional change,
  not just a rename — needs explicit regression testing, not just a
  naming verification

---

### Phase 6: dry/wet crossfader

**Work:**
- Confirm crossfader widget convention against `vsynth-bpatcher/SKILL.md`
  before building
- Add `wet` param; rewrite `out1`/`out2` per ADR 5
- Rename `composite` outlet comment → `mix`
- Rebuild via `build_patcher.py`; JSON-validate

**Verification:**
- `wet=0` → out1 is clean source regardless of `strength`
- `wet=1` → out1 matches current pre-change behavior at any given
  `strength` (regression check)
- out2 now goes to source on bypass (behavior change — confirm this is
  the intended new behavior, not a regression, when reviewing in Max)
- No vecfield connected: sensible behavior at any `wet`/`strength`
  (offset suppressed via `src_vecfield`)

**Checkpoint:** All reframe acceptance criteria from spec.md verified in
Max, including the out2 bypass behavior change specifically. Update
`docs/f-reference/f_vf_warp.md` and HANDOFF.md.
