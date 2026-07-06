# Implementation Plan: f_vf_streak

**Date:** 2026-06-08
**Spec:** `.specify/f_vf_streak/spec.md`

---

## Summary

`f_vf_streak` is a pure Processor bpatcher that accumulates source texture samples along vecfield streamlines, producing a directional smear of the source image aligned with the field geometry. It is architecturally similar to f_caustic (8-step unrolled accumulation loop, two outlets, two texture inlets) but accumulates source color along the path rather than convergence-weighted light. The codebox is the primary novel work. The patcher structure closely follows f_caustic with one inlet configuration difference: the vecfield inlet uses `vs_inState` + `src_vecfield` suppression (as in f_vf_warp), since vs_black would produce a diagonal smear artifact rather than passthrough.

---

## Technical Context

**Environment:** Max 9 / Vsynth package
**Primary artifact:** `patchers/f_vf_streak.maxpat`
**Build tool:** `tools/build_patcher.py` from `definition.py`
**Output type:** `@type char` (standard Vsynth processor convention)
**Gen type:** `jit.gl.pix vsynth @name vfstreak_pix`

**Constraints from constitution:**
- Codebox before patcher — GLSL verified in scratch before definition.py is authored
- One bpatcher, one concern — directional streak only, no scope creep
- Vsynth compatibility — routepass pattern, vs_inState, moduleSize chain, attrui wiring
- Inline component access only — never store a vec then access .x/.y

---

## Architecture Decisions

### ADR 1: Pure Processor archetype

**Context:** f_vf_streak requires a source texture to streak — it has no self-generated content.

**Decision:** Pure Processor. `routepass → pix in0` directly, no `vs_inState` on in0.

**Rationale:** Matches f_vf_warp's reasoning exactly. Without a source texture there is nothing to smear. Output is black if in0 is unconnected — correct and expected.

**Alternatives considered:**
- Dual-mode generator: would output a streak of black (black), structurally misleading.

**Consequences:**
- Simpler patcher — no src_mode param, no vs_inState on in0
- Appears black with no upstream connection (expected for all Vsynth processors)

---

### ADR 2: vs_inState + src_vecfield suppression on vecfield inlet

**Context:** When in1 is unconnected, `vs_inState` delivers `vs_black` (all zeros). After `(field - 0.5) * 2.0` remap, zero maps to -1.0 — all 8 steps walk toward the top-left corner, producing a diagonal smear artifact rather than source passthrough.

**Decision:** Use `vs_inState` outlet 1 wired to a hidden `src_vecfield` Param. Multiply decoded field vectors by `step(0.5, src_vecfield)` before stepping, zeroing them when unconnected. Same pattern as f_vf_warp.

**Rationale:** When suppressed, all step positions collapse to current UV — accumulation degenerates to 8 identical source samples, normalizing to the source pixel. Clean passthrough with no artifact.

**Alternatives considered:**
- Leave unsuppressed: unacceptable — diagonal smear when no field connected fails the passthrough acceptance criterion.
- vs_grey fallback: no such abstraction in Vsynth package.

**Consequences:**
- One hidden system param (`src_vecfield`) — absent from route, UI, and parameters block
- `vs_inState` outlet 1 wired via `prepend param src_vecfield → pix in0`
- out1 (streak layer) will be black when unconnected (all steps at same UV → uniform color accumulation → normalized to source pixel color, not black). Verify this is acceptable in scratch patch.

---

### ADR 3: Two-outlet gen subpatcher, matching caustic pattern

**Context:** Spec requires two outlets: out0 (composite) and out1 (isolated streak layer). This requires a gen subpatcher with two `out` objects and a codebox with two outlets.

**Decision:** Gen subpatcher structure: `in 1` (source), `in 2` (vecfield), codebox with `numinlets=2, numoutlets=2`, `out 1` (composite), `out 2` (streak layer). Bpatcher outlets wired: pix out0 → outlet 0, pix out1 → outlet 1.

**Rationale:** Directly mirrors f_caustic's gen structure. `build_patcher.py` already supports dual-outlet gen subpatchers via the caustic build script pattern. The standard `definition.py` + `build_patcher.py` path will need a `dual_outlet` key or the caustic custom build script pattern — confirm which during Phase 2.

**Alternatives considered:**
- Single outlet with mode select: loses the sidechain compositing flexibility that is core to the design.

**Consequences:**
- May require a custom build script (like f_caustic's `build_caustic.py`) if `build_patcher.py` does not support dual gen outlets natively. Check before Phase 2.
- Presentation rect width likely needs to be wider than standard 78px to accommodate two outlet triangles and four param dials — check moduleSize.js constraints.

---

### ADR 4: Additive composite for out0

**Context:** out0 combines source and streak layer. Two operators considered: additive blend and replace blend.

**Decision:** Additive — `out0 = clamp(source + streak * strength, 0, 1)`.

**Rationale:** Treats streak as a light layer over source, matching caustic's compositing model. Clipping at high strength is acceptable and visually desirable. Consistent with the sidechain mental model where out1 is the raw layer and out0 is a convenience composite.

**Alternatives considered:**
- Replace blend `mix(source, streak, strength)`: replaces source at high strength, losing underlying content. Not appropriate for a light-accumulation effect.

**Consequences:**
- out0 can clip at high strength + bright source — document as expected
- out1 is always the isolated layer; users who need full compositing control use out1

---

### ADR 5: Falloff as linear weight interpolation

**Context:** `falloff` controls the weight distribution across 8 accumulation steps.

**Decision:** Per-step weight = `mix(1.0, 1.0 - (n / 7.0), falloff)` where n = step index 0–7. At falloff=0: all weights 1.0 (uniform). At falloff=1: weights 1.0, 0.857, 0.714 ... 0.0 (linear ramp to zero). At falloff>1: tail weights go negative — expressive artifact territory. Normalize by sum of weights before applying intensity. Range: 0.0–2.5.

**Rationale:** Simple, parameter-free, avoids `pow()` which is unavailable in jit.gen codebox GPU path. Covers the full range from symmetric directional blur to sharp-leading trailing smear.

**Alternatives considered:**
- Exponential falloff via repeated multiplication: requires `pow()` — not available.
- Gaussian: requires `exp()` — not verified in jit.gen GPU path, avoid.

**Consequences:**
- Weight sum varies with falloff — normalization required to prevent brightness shift between falloff values
- At falloff=1, step 7 weight is exactly 0 (contributes nothing) — effectively 7 active steps. Acceptable.

---

### ADR 6: color_shift implemented as per-channel UV offset along field direction

**Context:** color_shift should produce chromatic separation aligned to the streak direction, matching caustic's approach.

**Decision:** At each step, sample R channel at `pos + field * cs`, G at `pos`, B at `pos - field * cs`, where `cs = color_shift * step_size`. Applied inline at every step sample.

**Rationale:** Directly mirrors caustic's `color_shift` implementation. Field-aligned separation means chromatic aberration follows the streak geometry — visually coherent and expressive.

**Consequences:**
- Three texture samples per step instead of one (R, G, B separately) — 24 total samples at 8 steps. Within jit.gen budget.
- At color_shift=0, cs=0 → all three channels sample the same UV → no separation. Clean zero.

---

## Implementation Phases

### Phase 1: Codebox verification (scratch patch)

Write and verify the streak codebox in a scratch patch before touching the build system.

**Work:**
- Open scratch patch in `~/Vsynth/patterns/` with vs_render, a source texture, and f_vf_vortex
- Add `jit.gl.pix` with two texture inlets (source, vecfield) and two outlets
- Build gen subpatcher: in 1, in 2, codebox (numinlets=2, numoutlets=2), out 1, out 2
- Wire sliders for strength, length, falloff, color_shift, src_vecfield
- Write and paste the full 8-step unrolled codebox
- Verify:
  - Streak visible and directionally aligned with vortex field
  - `length` scales streak reach smoothly
  - `falloff=0` gives symmetric blur; `falloff=1` gives trailing smear
  - `color_shift > 0` produces chromatic separation along streak axis
  - `src_vecfield=0` gives clean source passthrough (no diagonal artifact)
  - `strength` scales streak layer contribution in out0
  - out1 contains isolated streak layer (dark background, colored streaks)
  - Bypass: out0 = source, out1 = black
  - No codebox compile errors, no silent GLSL failures

**Checkpoint:** Both outlets behave correctly, all four params have visible effect, passthrough is clean. Codebox frozen — no further changes after this point.

---

### Phase 2: definition.py and build system check

Confirm build_patcher.py supports dual gen outlets, then author definition.py.

**Work:**
- Inspect `tools/build_patcher.py` to determine if dual-outlet gen subpatcher is supported natively
  - If yes: use `definition.py` with a `dual_outlet: true` key (or equivalent)
  - If no: write a custom `build_streak.py` modelled on `build_caustic.py`
- Author definition file:
  - `archetype: "processor"`
  - `pix_type: "char"`
  - Prefix: `vfstreak`, object name: `vfstreak_pix`
  - `mod_inlets: [{"label": "vecfield", "state_param": "src_vecfield"}]`
  - Params: `strength` (0–1, default 0.3), `length` (0–20, default 0.15), `falloff` (0–2.5, default 0.0), `color_shift` (0–20, default 0.0), `src_vecfield` (internal), `bypass`
  - Presentation rect: wider than 78px — four dials + two outlet triangles; target ~120px wide, verify against moduleSize.js
- Validate definition.py before running build

**Checkpoint:** `python3 -c "import json; json.load(open('patchers/f_vf_streak.maxpat'))"` passes. Structural inspection confirms: two pix outlets, two gen out objects, vs_inState wired correctly, src_vecfield absent from route/UI/parameters block.

---

### Phase 3: Patcher build and inspection

Run build script and verify generated patcher structure.

**Work:**
- Run build script against definition.py (or build_streak.py)
- Inspect generated JSON:
  - pix has numinlets=3 (control, source, vecfield), numoutlets=2
  - Gen subpatcher has in 1, in 2, codebox (numinlets=2, numoutlets=2), out 1, out 2
  - vs_inState wired: out0 → pix in1 (vecfield texture), out1 → prepend param src_vecfield → pix in0
  - Two bpatcher outlets present, correctly labeled
  - Four live.dials in presentation layer
  - src_vecfield absent from route args, UI objects, parameters block
- JSON validation passes

**Checkpoint:** Patcher JSON valid. Structure correct per manual inspection.

---

### Phase 4: Vsynth integration testing

Open built patcher in live Vsynth patch and verify all acceptance criteria.

**Work:**
- Load f_vf_streak as bpatcher in Vsynth
- Connect source texture → in0, f_vf_vortex → in1
- Verify all acceptance criteria from spec:
  - Streak visible and field-aligned
  - All four params have correct effect
  - Passthrough when in1 unconnected
  - Black when in0 unconnected
  - Bypass correct on both outlets
  - out1 usable as additive composite source
- Test with f_vf_vortex_multi and f_vf_fieldmap
- Save/reload — no crash, no parameter reset

**Checkpoint:** All acceptance criteria pass. Survives save/load cycle.

---

### Phase 5: Docs and registration

Update permanent project records.

**Work:**
- Write `docs/f-reference/f_vf_streak.md` (params, signal flow, usage notes, known behaviors)
- Update `README.md`: add f_vf_streak to bpatcher table under f_vf_ family
- Update f_modules menu: add "Streak" entry to Vecfield category in `.specify/f_modules/build_modules.py`, add size entry to `javascript/f_addmod.js`, regenerate f_modules.maxpat
- Update `HANDOFF.md`

**Checkpoint:** README updated. f_modules includes f_vf_streak. Commit drafted.

---

## Dependency Blocks

| Block | Depends on | Produces |
|---|---|---|
| Phase 1: Codebox | Nothing | Verified GLSL (frozen) |
| Phase 2: definition.py | Phase 1 (frozen codebox), build system check | Build input |
| Phase 3: Build | Phase 2 | f_vf_streak.maxpat |
| Phase 4: Integration | Phase 3 + Vsynth env | Verified working patch |
| Phase 5: Docs | Phase 4 (confirmed working) | Updated project records |

Critical gate: Phase 1 → 2. Do not author definition.py until codebox is verified working in scratch. If build system does not support dual outlets natively, the custom build script must be written before Phase 3.

---

## Complexity Notes

Medium complexity — higher than f_vf_warp due to the accumulation loop (8-step unroll is verbose), the dual-outlet gen structure, and the color_shift per-channel sampling (24 texture samples total). All of this is well-understood from caustic; f_vf_streak is essentially caustic with a different accumulation kernel.

**Primary risks:**
- Normalization arithmetic: sum of falloff-weighted weights must be computed correctly to avoid brightness shift. Verify in scratch patch across falloff range.
- Dual gen outlet support in build_patcher.py: check before committing to definition.py path. If unsupported, custom build script adds a phase of work but is low-risk given caustic as template.
- out1 isolation when in1 unconnected: when src_vecfield suppresses offsets, all steps accumulate the same UV → out1 will be a solid color (the source pixel), not black. May need explicit out1 = black when src_vecfield=0. Verify in scratch patch.
