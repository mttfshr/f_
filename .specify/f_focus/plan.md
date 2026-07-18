# Implementation Plan: f_focus

_Date: 2026-07-15_
_Spec: .specify/f_focus/spec.md_

---

## Summary

`f_focus` is a new module extracting the tilt-shift mechanism currently
living inside `f_lens` v1. Phase 1 is a near-mechanical port — no new
verification needed on the core mechanism, `jit.fx.cf.tiltshift` is
already confirmed working in the Vsynth context. Phase 2 (content-driven
focus-map gather-blur) is a real, larger, separately-scoped build,
tracked but not detailed here yet.

---

## Architecture Decisions

### ADR-1: Split rationale

**Context:** `f_lens`'s tilt-shift (`jit.fx.cf.tiltshift`, gradient-band
blur) shares no math or mental model with the rest of `lens_pix`
(aberration/distortion/transmission — all radial, all sharing
`dist`/`warp_uv`). Matt's own "not reaching for `f_lens`" was the
practical symptom, traced in `ideas/f_lens_tiltshift_split.md`.

**Decision:** Full extraction, not a lightweight duplicate kept in both
places. `f_lens` v2 removes tilt-shift entirely.

**Consequences:** Any existing patches wiring into `f_lens`'s tilt
params break and need to be repointed at `f_focus`. Real migration cost
— worth flagging to Matt at build time, not just at spec time.

### ADR-2: Phasing — engine choice deferred, not decided now

**Context:** `ideas/f_lens_tiltshift_split.md` open question 2 (keep
tiltshift only / add focus-map mode / replace outright) was explicitly
undecided.

**Decision:** Phase 1 ships `jit.fx.cf.tiltshift`-only, matching the
"keep tiltshift as default/proven, add focus-map blur later" path the
idea file already flagged as lower-risk. Phase 2 (focus-map mode) is
scoped in the spec but not planned in build-phase detail — real
architecture work (CoC source choice, variable-radius blur cost,
foreground-bleed multi-pass) deferred until Phase 1 ships and Phase 2 is
picked up deliberately.

---

## Dependency Blocks

### Block 0: Param/object port
**Dependencies:** None — `jit.fx.cf.tiltshift` already proven in Vsynth
context, no feasibility risk here (unlike `f_lens`'s original Phase 0).
**Builds:** Single-inlet bpatcher wrapping `jit.fx.cf.tiltshift`, ported
params (`blur`/`axis`/`pos`/`mode`/`slope`/`bypass`), standard Vsynth
wrapper (routepass, route, autopattr, bypass toggle, moduleSize.js).
**Verification:** Same acceptance criteria as `f_lens` v1's tilt-shift
— band visibility, axis rotation, pos movement, mode switch, bypass,
passthrough at defaults.

### Block 1: f_modules registration
**Dependencies:** Block 0
**Builds:** Add to `.specify/f_modules/build_modules.py` category
(likely Optical, alongside `f_lens`) + size entry in
`javascript/f_addmod.js` SIZES dict.
**Verification:** Appears correctly in `f_modules` menu in Max.

### Block 2 (future, Phase 2): Focus-map gather-blur
Not detailed yet — see spec.md Phase 2 open items. Real planning pass
needed before this becomes a task list.

---

## Implementation Phases

### Phase 1a: Build patcher wrapper

Straightforward `build_patcher.py` definition — single `jit.fx`-backed
processor, no codebox needed. Should be one of the simpler modules to
build in the library, given zero GenExpr risk.

### Phase 1b: Vsynth integration

Load in Vsynth context. Test in place of where `f_lens`'s tilt-shift
previously sat in any existing performance chains, to confirm the
extraction doesn't lose anything in practice.

### Phase 1c: Documentation

- `docs/f-reference/f_focus.md` — as-built reference
- Update `README.md` patches table
- `.maxhelp` file per `f-helpfile` skill conventions
- Note in `f_lens`'s own docs that tilt-shift moved to `f_focus`

---

## Complexity Notes

Phase 1 is low-risk — porting an already-proven object with already-
proven params, no new GenExpr, no new inlet types. The real complexity
is entirely in Phase 2, deliberately deferred.
