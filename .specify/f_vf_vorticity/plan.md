# Implementation Plan: f_vf_vorticity

**Date**: 2026-07-06
**Spec**: .specify/f_vf_vorticity/spec.md

---

## Summary

A standalone vecfield-to-vecfield processor. Single vecfield inlet, single
vecfield outlet — no source/light texture, no composite/isolated-layer split
(unlike `f_vf_glow`/`f_caustic`). Core math: curl (vorticity) via central
differences, gradient of vorticity magnitude via a second central-difference
pass, corrective force perpendicular to that gradient, added back into the
input field. The open architecture question carried from the spec — one
codebox or a multi-stage chain — is resolved here as ADR-1.

---

## Technical Context

- **Runtime**: Max 9, jit.gl.pix GPU path (GenExpr)
- **Type**: float32 RG (f_vecfield convention), NOT `@type char` — this
  module is a vecfield processor, not an image processor
- **GL context**: `@drawto vsynth`
- **Build tool**: `tools/build_patcher.py` from `definition.py` (single-
  codebox path) — falls back to a custom builder script only if ADR-1's
  single-codebox attempt fails (same fallback pattern as `f_vf_seeds`/
  `f_sirds`/`f_masonry`)
- **Inlets**: 1 (vecfield in)
- **Outlets**: 1 (vecfield out)

---

## Architecture Decisions

### ADR-1: Single codebox first, multi-stage only if the capture-ceiling forces it

**Context**: Vorticity confinement needs curl at the current pixel AND at
its four neighbors (to compute the gradient of vorticity magnitude). Curl
itself is a 4-sample central difference on the input field. Naively, this
is ~5 curl evaluations × 4 field samples each = up to 20 field samples,
all inline arithmetic — no loops, no dynamic branching. This is a
different shape from `f_vf_seeds`'/`f_masonry`'s capture-ceiling failures,
which came from candidate-search loops and duplicated render logic, not
from a fixed, linear chain of sample/arithmetic statements.

**Decision**: Attempt a single `jit.gl.pix` codebox first: compute curl
inline at the 4 neighbor offsets and the center, then the vorticity
gradient, then the confinement force, then add to the input field — all
in one codebox, no intermediate texture. Only split into a two-stage chain
(Stage 1: output curl as a scalar texture; Stage 2: sample curl's
neighbors + the original input field, compute confinement force, add,
output) if Phase 1 hits the Lua `DSL.Parser` capture-group ceiling
(`"stack overflow (too many captures)"`, per the `f_vf_seeds` ADR 7/8
precedent) or a silent multi-value-return-style compile failure (per
`f_masonry`'s ADR 7 lesson — inline math, no user-defined multi-return
functions, regardless of which path this takes).

**Rationale**: Simpler is cheaper to build and verify if it fits.
Precedent for hitting the ceiling exists, but so does precedent for a
16-sample-ish computation working fine in one codebox (`f_vf_sobel`'s
9-sample luma neighborhood, used inside `f_vf_repulse`). Don't assume the
ceiling will be hit — test first.

**Alternatives rejected**:
- Multi-stage chain from the start: more build/wiring complexity
  (`build_seeds_multistage.py`-style custom builder) than may be
  necessary. Reserve for if/when Phase 1 proves it's needed.

**Consequences**:
- Positive: if it fits, this is a normal `tools/build_patcher.py`
  single-codebox module — no custom builder script, no multi-object
  wiring, fastest path to done.
- Negative: real risk of discovering mid-Phase-1 that it doesn't fit,
  requiring a pivot to multi-stage after some codebox work is already
  written. Acceptable — same thing happened productively in `f_vf_seeds`.

---

### ADR-2: No explicit vs_black / unconnected-inlet suppression logic

**Context**: `f_vf_glow`'s ADR-2 needed an explicit raw-value threshold
check to suppress glow on an unconnected (`vs_black`) vecfield inlet,
because `vs_black` remaps to a non-zero constant (-1,-1) and glow's
accumulation loop would otherwise react to that non-zero magnitude.

**Decision**: No equivalent suppression logic here. Vorticity confinement
depends on *spatial derivatives* of the field, not the field's raw
magnitude. A spatially uniform field — which is exactly what `vs_black`'s
constant (-1,-1) is — has zero spatial derivative everywhere, so curl = 0
and the confinement force = 0, automatically, as a direct consequence of
the math.

**Rationale**: Don't add defensive code for a case the math already
handles. This is a genuine structural difference from `f_vf_glow`, not an
oversight — worth stating explicitly so a future session doesn't assume
it was forgotten.

**Consequence**: Needs empirical confirmation in Phase 1 (spec's edge
cases already flag this as worth a scratch-test check), but no codebox
branch is expected to be needed for it.

---

### ADR-3: Single inlet, single outlet — no outlet split

**Context**: `f_vf_glow` and `f_caustic` both use a two-outlet
(composited / isolated-layer) pattern because they composite an effect
over a separate source image. `f_vf_vorticity` has no source image — it
transforms the vecfield itself and that transformed field IS the output.

**Decision**: One inlet (vecfield in), one outlet (enhanced vecfield out).
No `outlets` key needed in `definition.py` beyond the default single
outlet.

**Rationale**: Matches the actual data flow — there is nothing to
composite over, and inventing an "isolated force layer" outlet would add
API surface with no established use case. Keep it simple until a real
need for tapping the raw force term surfaces.

---

### ADR-4: Finite-difference offsets via `dim`, matching established idiom

**Context**: Both curl and vorticity-gradient computations need neighbor
texel offsets.

**Decision**: `sx = 1.0/dim.x`, `sy = 1.0/dim.y`, same as `f_vf_sobel`'s
and `f_caustic`'s divergence calc. No new offset convention.

**Rationale**: Established, working idiom — no reason to deviate.

---

### ADR-5: `confinement` range/default deferred to Phase 1

**Context**: Spec explicitly leaves `confinement`'s range and default
TBD, since baseline vorticity is expected to vary significantly by
source field (same finding pattern as `f_vf_seeds`' `field_gain`, which
needed a ~7.5x different useful range depending on source).

**Decision**: Don't guess a number now. Phase 1's scratch test must
include at least vortex, repulse, and flow sources, tested at
`jitter`/base-noise near zero where possible (same "isolate the effect
you're tuning" technique used for `field_gain`) before committing a
range/default to `definition.py`.

**Rationale**: Matches the pattern that already worked once on this
exact category of problem (per-source-varying field-derived params).

---

## Implementation Phases

### Phase 1 — Codebox verified in scratch patch

Write the GenExpr codebox per ADR-1 (single codebox attempt first), paste
into a scratch patch at `~/Vsynth/patterns/`, wire to `f_vf_vortex` to
start (smoothest, simplest source — easiest to visually confirm
`confinement=0` passthrough and to see swirl appear as it's raised), then
`f_vf_repulse` and `f_vf_flow`.

**Codebox inlet map**:
- `in1` — vecfield in (outer pix inlet 0, only content inlet)

**Params declared in codebox**:
- `Param confinement(0.0)` — placeholder default, per ADR-5
- `Param bypass(0.0)`

**Checkpoint** (maps to spec Success Criteria 1-3, Edge Cases):
- `confinement = 0` visually/structurally indistinguishable from
  passthrough, on at least two source fields
- Raising `confinement` produces visible fine-scale swirl distinct from
  source topology
- Full sweep reads as meaningfully different low→high turbulence
  character
- No NaN/blowup near a vortex's fixed-point singularity (spec Edge Case,
  explicitly UNVERIFIED until checked here)
- `vs_black`/unconnected inlet produces zero force with no explicit
  suppression code (confirms ADR-2)
- Decide `confinement`'s actual range/default from what's observed here
  (resolves ADR-5)
- If the codebox hits the capture-ceiling or a silent compile failure:
  stop, split into the two-stage fallback described in ADR-1, don't push
  through by cutting corners on the math

---

### Phase 2 — definition.py + build

Write `.specify/f_vf_vorticity/definition.py` from the confirmed codebox.
Run `tools/build_patcher.py` (single-codebox path, per ADR-1's expected
outcome) or the appropriate custom builder if Phase 1 forced the
multi-stage fallback.

**Key definition.py fields**:
- `archetype: "processor"`
- Single float32 RG inlet, `vs_instate` for graceful unconnected fallback
  (even though ADR-2 says no suppression logic is needed in the codebox,
  the standard `vs_inState` wiring is still the correct inlet-level
  convention)
- Single outlet, default (no `outlets` key needed per ADR-3)
- `@type` — float32, not char (f_vecfield convention, matching
  `f_vf_warp`/`f_vf_advect`/etc., not the image-processor default)

**Checkpoint**: Patch opens in Max. Both params appear in UI. Pix
compiles without errors.

---

### Phase 3 — Integration testing

Drop `f_vf_vorticity` into a Vsynth signal chain, chained with:
- `f_vf_vortex` → `f_vf_vorticity` → `f_vf_advect` (spec User Story 3,
  Acceptance Scenario 1)
- `f_vf_vorticity` → `f_caustic` field inlet directly (spec User Story 3,
  Acceptance Scenario 2)
- `f_vf_vorticity` → `f_vf_warp`

Test `confinement` across its full (now-calibrated) range. Test bypass.
Re-check the `f_vf_advect` `decay > 1.0` interaction flagged as
UNVERIFIED in the spec's edge cases — both mechanisms add energy/swirl
independently; confirm whether they compound controllably or fight.

**Checkpoint**: All spec acceptance scenarios pass. 60fps maintained
alongside at least one other simultaneously-running `f_` module (spec
Success Criteria 5).

---

### Phase 4 — Registration

- Add to `f_modules.maxpat` (Vecfield category)
- Add to `javascript/f_addmod.js` SIZES dict
- Add to `README.md` patch table
- Write `docs/f-reference/f_vf_vorticity.md` as-built reference
- Update `HANDOFF.md`
- Update `ideas/vorticity_confinement.md` status (currently "Tabled" —
  should move to shipped/superseded once this lands)

---

## Complexity Notes

ADR-1 is the real open risk in this plan — whether the vorticity-gradient
computation fits in one codebox or needs to split is genuinely unknown
until Phase 1 is attempted. Precedent exists on both sides (`f_vf_sobel`'s
9-sample neighborhood fit fine; `f_vf_seeds`/`f_masonry` both eventually
needed splits at higher complexity). Don't pre-commit to either path in
`definition.py` before Phase 1 confirms which one is actually needed.

The singularity/NaN check and the per-source `confinement` range
calibration (ADR-5) are the other two real unknowns — both are scratch-
test questions, not design questions, and both are scoped into Phase 1
rather than guessed at here.
