# Implementation Plan: f_tf_sharpen

_Date: 2026-10-17_
_Spec: .specify/f_tf_sharpen/spec.md_
_Brief: ideas/f_tf_build_brief.md §4; triage: ideas/f_tf_triage.md_

---

## Summary

`f_tf_sharpen` is a **single-pass, stateless, per-pixel** tensor operator: decode raw
tensor → closed-form eigenvalues → scale the eigengap by γ with a floor gate → re-encode
the same raw out0 contract. No loops, no feedback, no neighborhood.

```
in0 -> [decode Jxx/Jxy/Jyy] -> [eigen λ1,λ2,θ] -> [gap scale + floor] -> [re-encode] -> out0
```

All the risk is numeric, not architectural: the decode→operate→re-encode round trip must
not drift (γ=1 must be neutral to float32 tolerance), and the relax branch must never
introduce an eigenvalue swap (axis flip by 90° — see spec OQ2, a real math hazard, not a
taste item).

## Technical Context

**Environment:** Max 9, Vsynth, `jit.gl.pix` gen codeboxes, `@type float32`
**Build method:** NumPy mirror (tier 1) -> codebox on the bench (tier 2) -> scratch
(tier 3) -> definition.py -> build_patcher.py
**Statement budget:** trivial; the whole operator is well under 100 GenExpr statements
(decode + closed-form eigen + branchless scale + encode), an order of magnitude under
the ~450 capture ceiling (`skills/jit-gen-codebox`).
**Decode idiom:** per-consumer (triage resolution). **Canonical text lives in
`.specify/f_tf_glyph/plan.md` ADR-2** — this module copies it verbatim into
`codebox_sharpen.gen` (it is atan2-free: closed-form eigen on the raw components; the
axis rides through unchanged, so sharpen's axis-invariance row is true by construction).
Strength semantics (ADR-4): the idiom's gain-free identities make gap scaling
strength-commuting; the **floor gate is the one strength-dependent piece** (an absolute
trace threshold) — that caveat goes in the helpfile, not into the idiom.

## Files

```
.specify/f_tf_sharpen/
  spec.md  plan.md  tasks.md      — triad
  codebox_sharpen.gen             — Phase 1 (single codebox)
  definition.py                   — Phase 3

tests/
  test_tf_sharpen.py              — tier 1 (Phase 0)
  bench_tf_sharpen.py             — tier 2 (Phase 1)

~/Vsynth/patterns/tf_sharpen_scratch.maxpat  — tier 3 (not committed)

docs/f-reference/f_tf_sharpen.md — Phase 5
```

## Architecture Decisions

### ADR-1: Single codebox, single pass, no intermediate textures
**Context:** the operator is closed-form per pixel; no neighborhood, no feedback.
**Decision:** one codebox; no pix_chain.
**Consequence:** the module is a `pix`-only definition (single node), the simplest in the
family. Statement budget trivial.

### ADR-2: The relax branch is identity-mix, never a negative gap
**Context:** γ < 1 "relaxes" toward isotropy. Literal negative γ swaps eigenvalues
(λ2' > λ1'), which silently rotates the axis by 90° — a correctness hazard the acceptance
rows explicitly forbid (spec OQ2).
**Decision:** compute `g = max(γ, 0)`; `λ1' = trace/2 + g·(λ1 − trace/2)`;
`λ2' = trace/2 − g·(λ2 − trace/2)`; **and** the isotropic remainder is NOT added
separately — with this formula, at g=0 both eigenvalues land on trace/2 exactly, i.e.
the isotropic point, with trace preserved. The dial's <1 range maps through this same
formula (γ directly, no separate mix path).
**Verification:** the mirror's relax case asserts λ'=trace/2 at γ=0 and NO axis swap for
any γ in the dial range (T006).

### ADR-3: Floor is a fixed internal epsilon inherited from the tensormap convention
**Context:** spec OQ3 (param vs fixed eps). UI cost vs expressive value.
**Decision:** fixed internal `eps_trace` = the tensormap convention (1e-6, its T019
decision), NOT a performer dial in v1. The dial can come in v2 if tier 3 shows performers
reaching for it.
**Rationale:** zero new UI; the floor's job is protection from invented structure, not
expression; tensormap already established the epsilon discipline. Recorded honestly as a
deferred dial, not a hidden one.
**Consequence:** spec Parameters table loses the `floor` row in v1; one less knob; the
helpfile says "flat regions pass through unchanged by design."

### ADR-4: Raw in, raw out; strength semantics
**Context:** the raw tensor encoding is strength-scaled (tensormap's own gain). Gap
scaling operates on eigenvalue *ratios and shapes*, which are scale-covariant… careful:
scaling the gap by γ on a strength-scaled tensor is identical to scaling then unscaling
(linear in the components), so the operator commutes with strength — **except** the
floor gate, which is an absolute threshold (spec OQ/discussion).
**Decision:** inlet is the strength-scaled raw form; the module never rescales; the floor
gate therefore depends on the producing tensormap's `strength` (documented caveat in
helpfile + reference doc: "floor eps in pre-gain trace units; see tensormap calibration").
**Consequence:** T008 records exact behavior; the mirror parametrizes on an arbitrary
scale factor to prove the commutation.

### ADR-5: Verification tiers
**Decision (Phase 0 gate, T001):** tier 1 applies (eigh ground truth); tier 2 applies
(GPU round-trip + neutral-at-γ=1); tier 3 applies (dial mapping feel, the OQ1 decision).

## Dependency Blocks

### Block 1: Math settled in NumPy
**Builds:** `tests/modules/tf_sharpen/test_tf_sharpen.py` — decode/eigen/gap/re-encode mirror; trace
invariance; axis invariance; no-swap-on-relax; scale-commutation (ADR-4); mutation
checks (drop the max(γ,0); swap the gap sign).
**Verification:** `np.linalg.eigh` agreement; measured round-trip error recorded.

### Block 2: Codebox on the bench
**Dependencies:** Block 1.
**Builds:** `codebox_sharpen.gen`, `tests/modules/tf_sharpen/bench_tf_sharpen.py`.
**Verification:** γ=1 bit-drift measured (target: < 1e-6 relative, recorded); exaggerate/
relax/floor rows from the spec reproduced on GPU; branch-cut pixels behave (decode via
closed-form eigen of the raw components — no atan2 needed at all, which sidesteps the
branch-cut class entirely: record as a plan finding).

### Block 3: Scratch patch, judgment
**Dependencies:** Block 2.
**Builds:** scratch only.
**Verification:** dial feel across the range on live tensormap output; γ sweep on glyph
output (if built) or hatch marks; Matt's mapping pick (OQ1) and any rename decision
(OQ4/spec).

### Block 4: definition.py and build
**Dependencies:** Block 3.
**Builds:** definition.py (single-node pix), build, menu registration, drift, contracts.
**Verification:** loads in Vsynth; neutrals confirmed.

### Block 5: Docs
**Dependencies:** Block 4.
**Builds:** reference doc (the strength-caveat and no-atan2 notes), inventory row,
HANDOFF.

## Implementation Phases

### Phase 0: Gates + tier-1 math (BLOCKING)
Tier decision (all three apply). Mirror + ground truth + mutations. Exit: mirror clean.

### Phase 1: Codebox on the bench (BLOCKING)
Bench vs mirror at γ ∈ {0, 0.5, 1, 2, 4}; γ=1 round-trip measured; borders trivial
(single-pixel op). **Ask before the bench run.** Exit: parity recorded.

### Phase 2: Scratch patch
Dial mapping feel (OQ1); optional rename decision (spec OQ4); exaggerate-on-flicker demo
confirms the build-after-smooth ordering was right (compare sharpening smoothed vs raw
tensor). Exit: locked dial mapping + name in the spec.

### Phase 3: definition.py and build
Single-node definition; menu; drift; contracts (BYPASS_EXPECT passthrough). Exit: loads,
neutrals confirmed.

### Phase 4: Integration
Chain A assembled: tensormap → smooth → sharpen → (glyph or aniso_blur if built; else the
decode preview). Confirm the gesture: one dial moves the whole rig's commitment. Exit:
recorded in the brief's chain A entry.

### Phase 5: Docs and handoff
Reference doc, inventory, HANDOFF, brief update. Exit: consumer specs can cite sharpen as
the standard operator stage.

## Out of this plan

- Twist/rotation operators (spec Out of Scope).
- Per-pixel γ mod inlet (mod-UI conventions).
- Any packed-outlet handling (raw only).
- Bench runs without asking.