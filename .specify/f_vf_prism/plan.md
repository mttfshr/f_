# Implementation Plan: f_vf_prism

**Date**: 2026-07-11
**Spec**: `.specify/f_vf_prism/spec.md`

---

## Summary

Two independent additions to a working, shipped module: (1) a 3rd
outlet exposing a gate-weighted per-channel dispersion direction — a
genuinely novel vecfield derived from this module's own luma-gated
accumulation, not from the input field alone (finding 4/8 correction);
and (2) the library-wide findings 1–3 rollout — splitting the current
single `strength` param into separate `gain` (effect intensity,
unbounded) and `wet` (crossfader blend) controls, and renaming the
`composite` outlet comment to `mix`. Both are additive to the existing
codebox; no change to the core dispersion/gating math.

---

## Architecture Decisions

### ADR 1: 3rd outlet — gate-weighted combination, not raw geometry average

**Context**: Finding 4 originally credited this module as a clean pass
based on each channel's rotated perpendicular direction being distinct.
Reading the actual rotation math shows any *unweighted* combination of
the three (average, difference) cancels to a scalar multiple of the
input field — not novel, same failure shape as `f_vf_warp`. See spec.md's
2026-07-11 reframe and ideas doc finding 8 for full derivation.

**Decision**: `out3 = gr*R + gg*G + gb*B` — combine the three per-channel
directions weighted by their own post-blur gate values (`gr,gg,gb`,
already computed for out1/out2), rather than an unweighted average.

**Rationale**: The gate weights are independently, nonlinearly
data-dependent (luma-thresholded at each channel's own displaced sample
position) — genuinely new information the input field doesn't carry.
Gate-weighting is the only combination that preserves that novelty;
degenerates gracefully to the (already-known-trivial) unweighted case
when gates happen to agree.

**Alternatives considered**:
- Unweighted average or R−B difference — rejected, provably collapses to
  scalar multiple of input field (sine cancellation under symmetric
  rotation)
- Expose one channel's direction only (e.g. R) — rejected, arbitrary
  choice with no principled reason to prefer one channel, and still
  degenerates to the same trivial case for that channel alone whenever
  its own gate is uniform
- Three separate outlets (one per channel) — rejected, breaks the
  three-outlet convention this whole rollout is standardizing around;
  also each channel's direction alone is *only* a rotation of the input
  field (novelty lives in the gate weighting applied jointly, not in any
  single channel's geometry)

**Consequences**:
- Positive: reuses gate values already computed for out1/out2, no new
  sampling passes
- Negative: needs its own small block of codebox math to combine three
  weighted vectors and re-encode as f_vecfield; not zero-cost the way
  `f_chladni`'s addition was
- Magnitude behavior (not unit-normalized) should be sanity-checked
  during scratch verification per finding 6's redundancy concern, though
  there's no pre-existing vecfield-shaped outlet on this module to be
  redundant *with* the way `f_vf_vortex`'s case was

---

### ADR 2: gain/wet split + outlet rename (findings 1–3)

**Context**: Library-wide convention change (`ideas/dry_wet_gain_and_novel_field_outlet.md`,
findings 1–3) — separate effect intensity from blend amount, use a
crossfader-style control for blend, rename the `composite` outlet to
`mix`. `f_vf_prism` is in the additive-layer group this applies to.

**Decision**:
- Rename existing `strength` param → `gain` (keep its current 0–2.0
  range and default of 1.0 — see note below on why this isn't
  reconciled to match other modules' 1.5 ceiling)
- Add new `wet` param, float 0–1, crossfader-styled UI widget (per
  finding 2 — check `vsynth-bpatcher/SKILL.md` for the established
  widget convention before building)
- Codebox: `mixed = mix(src, src + layer*gain, wet)`, replacing the
  current direct `strength`-scaled additive composite
- Outlet comment: `composite` → `mix`

**Rationale**: Same reasoning as the library-wide finding 1 — `gain`
preserves the ability to overdrive the effect itself, `wet` gives a
separate, bounded, performable blend control, matching the audio-
sidechain shape (send level vs. return blend are different controls).

**Note on the 2.0 vs 1.5 ceiling discrepancy** (flagged in spec.md):
choosing to *keep* `gain`'s range at 0–2.0 rather than reconcile it down
to 1.5 to match `f_vf_glow`/`f_vf_streak`/`f_caustic`. No record exists
of why 2.0 was originally chosen for this module specifically, but
absent a reason to believe it was a mistake (as opposed to a deliberate
choice for this effect's character), forcing conformity risks losing a
deliberately-tuned range on a guess. Worth a two-second check against
Matt in scratch — does 2.0 still feel right, or was it arbitrary — before
finalizing, but not blocking the plan on it.

**Alternatives considered**:
- Leave `strength` name, add `wet` alongside it — rejected, `mix_amt`/
  `strength`/`gain` naming needs to converge on one term across the
  rollout or every module ends up calling the same concept something
  different (see the `f_vf_advect` naming note from finding 1 originally)
- Cap `gain` at 1.5 to match the other additive-layer modules — rejected
  per the note above; no evidence 1.5 is the "correct" number rather than
  just what those three modules happened to land on

**Consequences**:
- Positive: consistent naming with rollout across the additive-layer
  group; crossfader UI matches the convention once established elsewhere
- Negative: renaming `strength`→`gain` changes the param name any saved
  patches reference — existing patches using `f_vf_prism` will need
  their `gain`/`strength` attrui rewired on rebuild (same cost as any
  other param rename in this library, not unique to this module)

---

## Implementation Phases

### Phase 1: Scratch — 3rd outlet
- Extend prism's scratch patch (or the existing v15 scratch context) to
  compute `out3 = gr*R + gg*G + gb*B`, encode as f_vecfield
- Verify against spec.md's addition acceptance criteria: diverges from
  scaled input field wherever gates disagree, near-neutral where gates
  agree, neutral on bypass
- **Checkpoint**: out3 behavior confirmed distinct from input field in
  Max before touching `definition.py`

### Phase 2: Scratch — gain/wet split
- Confirm `gain` range (2.0 vs. 1.5 question) empirically against actual
  visual character at both ceilings
- Build crossfader-styled `wet` control per `vsynth-bpatcher/SKILL.md`
  convention (check this first — don't invent a one-off widget)
- Verify `mixed = mix(src, src+layer*gain, wet)` produces the intended
  audio-sidechain-shaped behavior: `wet=0` → clean source regardless of
  `gain`; `wet=1` → full gain-scaled effect blended in
- **Checkpoint**: both new controls behave as specced, independently of
  each other

### Phase 3: definition.py + codebox rewrite
- Add `gain`, `wet` params; remove/rename `strength`
- Add `out3` computation and outlet declaration; rename `composite` →
  `mix` outlet comment
- Rebuild via `build_patcher.py`; JSON-validate

### Phase 4: Vsynth integration verification
- Load rebuilt bpatcher in Max
- Verify all acceptance criteria from spec.md (original + 3rd-outlet
  addition) against the live module
- Confirm no regression to existing dispersion/gating behavior on
  out1/out2

### Phase 5: Docs + registration
- Update `docs/f_vf_prism.md` (if it exists) with new params/outlet
- Update HANDOFF.md
- Confirm `f_modules` menu entry doesn't need changes (outlet count
  change only, not signal_type)

---

## Dependency Blocks

| Block | Depends on | Produces | Gate |
|---|---|---|---|
| Phase 1: 3rd outlet scratch | Nothing | Verified out3 behavior | Acceptance criteria met before Phase 3 |
| Phase 2: gain/wet scratch | Nothing (parallel to Phase 1) | Verified gain/wet controls | Acceptance criteria met before Phase 3 |
| Phase 3: definition.py rewrite | Phases 1+2 | Rebuilt `f_vf_prism.maxpat` | JSON valid before Phase 4 |
| Phase 4: Integration | Phase 3 | Verified working patcher | All acceptance criteria before Phase 5 |
| Phase 5: Docs | Phase 4 | Updated project records | — |

Phases 1 and 2 are independent of each other and can be scratch-verified
in either order or in parallel; both must land before the single
`definition.py` rewrite in Phase 3 to avoid two separate rebuild passes.

---

## Complexity Notes

Two unrelated additions bundled into one plan because they touch the
same file in the same rebuild pass — worth keeping them as separately
identifiable ADRs (done above) so either could be reverted or re-scoped
independently if scratch testing reveals a problem with just one.
