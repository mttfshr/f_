# Implementation Plan: f_apollonian

**Date**: 2026-07-07
**Spec**: .specify/f_apollonian/spec.md

---

## Summary

A self-sufficient `jit.gl.pix` generator, no input texture. Per-pixel: run a
fixed-count `for` loop that repeatedly folds the coordinate through a
circle inversion (plus reflection and a modulo wrap) to build the Ford
circles construction — closest of the three reviewed reference shaders to
GenExpr's safest control-flow subset, since it needs no conditional
early-exit at all (see ADR-2). After the fixed loop settles, apply one
additional live-parameterized circle inversion (center + radius, blended in
via a `mix()`-style amount rather than a special-case "neutral" position —
see ADR-3) before final distance-based coloring. This resolves the spec's
open architecture question (which reference construction to build first)
as ADR-1.

---

## Technical Context

- **Runtime**: Max 9, `jit.gl.pix` GPU path (GenExpr)
- **Type**: standard `@type char` — this is a color generator, not a
  vecfield producer/processor, no `f_vf_` prefix
- **GL context**: `@drawto vsynth`
- **Build tool**: `tools/build_patcher.py` from `definition.py` — expected
  to fit the single-codebox path (no multi-stage split anticipated, unlike
  `f_vf_seeds`/`f_masonry`; confirm in Phase 1, don't assume)
- **Inlets**: 0 required (self-sufficient generator, per FR-002) —
  matches `f_masonry`/`f_chladni` archetype, not a dual-mode generator
  (no `src_mode`, no upstream texture fallback needed)
- **Outlets**: 1 (color out)
- **Scratch location**: `/Users/matt/Vsynth/patterns/`, `vs_render`
  bpatcher present, per `vsynth-bpatcher` skill's scratch-patch
  requirement for any `vsynth`-context GL object

---

## Architecture Decisions

### ADR-1: Ford-circles construction chosen as the first target, not the ring+central-circle construction

**Context**: `ideas/f_apollonian.md` reviewed three reference shaders.
Two (`Colourful Apollonian III` lineage, ebanflo-derived) build the gasket
via an N=3 ring of tangent circles plus a central circle, testing
containment against each of N+1 circles per iteration and inverting into
whichever one contains the current point. The third (Ford circles) builds
a *different* but related fractal via an unconditional per-iteration fold:
invert in the unit circle, swap x/y, modulo-wrap x — no containment test,
no branch, at all.

**Decision**: Build the Ford-circles construction first.

**Rationale**: It requires zero conditional logic inside the loop — just
straight-line arithmetic repeated a fixed number of times. This is a
strictly safer GenExpr target than the ring+central-circle construction,
which needs an `if` per candidate circle per iteration (confirmed
GPU-safe per `jit-gen-codebox` skill, but still more moving parts to get
wrong than an unconditional fold). It also has the simplest possible
"is this even close to correct" visual check — the reference shader's own
comments describe the exact folded pre-image ("draws two circles and two
lines... warped using circle inversions and copied using modulo").

**Alternatives rejected**:
- Ring+central-circle (N=3) construction: more visually canonical (four
  mutually tangent circles, closer to the classical Apollonian gasket
  image), but requires per-candidate containment testing inside the loop.
  Deferred, not discarded — worth building once the simpler construction
  is proven, since it's the construction most directly relevant to a
  future {p,q}/`f_poincare` unification (explicitly out of scope for this
  spec, but worth remembering why this alternative isn't gone for good).

**Consequences**:
- Positive: lowest-risk path to a working scratch test; sidesteps the
  `break`/early-exit question entirely rather than needing to resolve it
  (see ADR-2)
- Negative: the resulting fractal is the Ford circles pattern specifically
  (tangent circles along a line, generated via the modular group), not the
  four-mutually-tangent-circle gasket most people picture when they hear
  "Apollonian gasket." Visually related, not identical. Acceptable for a
  mechanism-proving first spec.

**SUPERSEDED 2026-07-08**: The proof-of-concept described above is
complete and confirmed working (see `tasks.md` Phase 1–2). Per the
"Alternatives rejected" note above, this was always meant to be deferred,
not discarded — that deferral is now being exercised. **The ring +
central-circle construction is now the actual target** for this spec's
remaining work (see spec.md's Status Addendum, 2026-07-08). Reasoning for
the pivot: (1) the proof-of-concept succeeded at what it was for —
confirming GenExpr can do iterated Möbius/circle-inversion fractals at
all, including the scale-accumulator pattern and a clean animated final
inversion; (2) the Ford-circles result, while a real and correct fractal,
is structurally the wrong shape for this project's circular-screen target
(infinite strip vs. bounded closed gasket); (3) with that foundational
fluency now demonstrated, the complexity/risk case for continuing to
defer the closed-gasket construction is much weaker than it was when this
ADR was first written. This is a genuine architecture pivot, not a
reversal made lightly — see ADR-2 below for what this means for the
`break`/early-exit question specifically, which this pivot reopens rather
than resolves.

---

### ADR-2: No `break`/early-exit anywhere — sidestepped by construction, not tested

**Context**: The spec flagged `break`/early-exit GPU-safety as an open
question requiring empirical resolution (User Story 1, Acceptance
Scenario 3), based on the ring+central-circle reference's use of
conditional early-exit inside its per-candidate inner loop.

**Decision**: The Ford-circles construction (ADR-1) has no conditional
logic in its loop at all — every iteration unconditionally applies the
same inversion/flip/wrap fold, confirmed-safe `for` with a fixed count and
nothing else. This means the `break`/early-exit question doesn't need to
be empirically tested to build ADR-1's target — it's moot for this
specific construction, not resolved in general.

**Rationale**: Don't spend a scratch-test cycle proving something the
architecture choice already avoids needing. This is a narrower claim than
"break is GPU-safe" — it's "we don't need to know that yet, given ADR-1."

**SUPERSEDED 2026-07-08 by ADR-1's pivot**: Now that the ring +
central-circle construction is the actual target, this question is live
again and must actually be resolved — it can no longer be sidestepped by
construction, since that construction's per-candidate containment test
is exactly the case this ADR was written about. Per spec User Story 1's
revised Acceptance Scenario 3: either confirm `break` is genuinely
GPU-safe in `jit.gl.pix`, or use the branchless `settled`-flag fallback
described in `ideas/f_apollonian.md` (run every candidate check
unconditionally every iteration, gate the inversion's effect with a
flag/`mix()` rather than exiting the loop). Recommend attempting the
branchless fallback first, consistent with this project's general
preference for known-safe GPU idioms over newly-tested ones when a
safe alternative exists — but this is worth a real scratch-test decision,
not just defaulting silently.

**Consequence**: The open question carried in the spec is **not actually
closed** by this plan — it's deferred again, now explicitly tied to
whichever future work needs the ring+central-circle construction (the
`{p,q}`/`f_poincare`-relevant alternative from ADR-1). Update
`ideas/f_apollonian.md` and the spec's Open Questions when that thread
picks back up, rather than treating this ADR as having answered it.

---

### ADR-3: Final inversion as a blend amount, not a "neutral" center/radius

**Context**: Spec FR-004 requires the live-parameterized final inversion
to be provably inert at some default setting. Circle inversion has no
true identity transform at finite radius — there's no `(center, radius)`
combination that leaves every point unchanged (only the degenerate
infinite-radius limit approximates identity, and only far from the
center).

**Decision**: Implement the final inversion as `z_final = mix(z_settled,
invert(z_settled, inv_center, inv_radius), inv_amount)`, with `inv_amount`
as a new live param (0–1, default 0). At `inv_amount = 0`, output is
provably, exactly the unmodified settled coordinate — satisfies FR-004
directly, no approximate-identity tuning required.

**Rationale**: Matches the project's standard `bypass`-style `mix()`
idiom (per `jit-gen-codebox` skill's "Bypass pattern") rather than
inventing a new, harder-to-verify notion of "neutral" position/radius.
Simpler to reason about and to test.

**Consequence**: Parameter Contract gains `inv_amount` (not in the original
spec table, which only listed `inv_x`/`inv_y`/`inv_radius`) — `plan.md` is
the right place for this addition since it's a HOW decision, not a WHAT
one. Note this when writing `definition.py` in Phase 4.

---

### ADR-4: Non-convergent-pixel handling is likely moot for this construction — confirm, don't assume

**Context**: Spec FR-006 requires non-NaN, deterministic output for pixels
that don't "settle" within the fixed iteration count, framed around the
ring+central-circle construction's escape-time character (some points
never stop being contained by a circle).

**Decision**: No special-case handling planned for Phase 1. The Ford-
circles fold is not an escape-time/containment test — it's an
unconditional distance-estimator that runs the same fixed fold every
pixel and produces a finite distance value at the end regardless (per the
reference's own final step: `min(d1,d2)/s`, always well-defined arithmetic
on finite inputs, `s` product-of-scale-factors, guarded below by ADR-5's
epsilon).

**Rationale**: FR-006 may simply be satisfied automatically by this
construction's structure, the same way `f_vf_vorticity`'s ADR-2 found
`vs_black` suppression to be structurally unnecessary rather than a
missing feature. Don't build a placeholder branch for a problem that may
not exist here.

**Consequence**: Phase 1 must still empirically check this (spec's Edge
Cases still stand as written) — this ADR predicts the outcome, it doesn't
skip the check. If Phase 1 finds real NaN/undefined cases (e.g. from
`dot(z,z) = 0` at the origin), ADR-5's epsilon guard is the fix, not a new
settled/unsettled branch.

---

### ADR-5: Division-by-zero guard on every inversion call

**Context**: Both the main loop's per-iteration inversion and the final
inversion (ADR-3) divide by `dot(p, p)` (squared distance from a circle's
center) — undefined at `p = (0,0)`, i.e. exactly at a circle's center.

**Decision**: Guard every such division with `max(dot(p,p), epsilon)`,
`epsilon` a small fixed constant (e.g. `0.0001`), consistent with the
`jit-gen-codebox` skill's standing caution on `sqrt()`/division guards.

**Rationale**: Cheap, mechanical, matches an already-established project
convention. No reason to discover this the hard way mid-scratch-test.

**Consequence**: None negative — this is a pure safety addition, doesn't
change correct-case behavior since `epsilon` is far below any distance
that matters visually.

---

## Implementation Phases

### Status addendum (2026-07-08) — Phases 1–2 confirmed, ADR-1's math corrected

Phases 1 and 2 below are now confirmed working in
`~/Vsynth/patterns/apollonian-scratch.maxpat`. Two real translation bugs
were found and fixed along the way — see `tasks.md`'s Phase 1 finding for
full detail. In short: the original codebox was missing the reference
shader's scale accumulator (`s`) entirely, and used the wrong inversion
radius (`1.0` instead of the correct `2.0`, per the reference's
`f = 0.5*dot(z,z)`). The pre-fix version compiled cleanly and looked
plausible but did not actually match the Ford-circles construction — only
after both fixes did the output show genuine tangent-circle packing with
nested self-similar detail in the gaps.

**Confirmed working parameters** (current scratch-patch defaults, not yet
promoted to `definition.py`):
- Starting coordinate: `snorm.x * 6.0`, `snorm.y * 6.0` (not raw `norm` —
  needs a signed, centered, scaled-up domain to show a repeating chain
  rather than one magnified cell)
- Iterations: 16 (not yet the Phase 3-calibrated final choice — this was
  the value used throughout Phase 1/2 verification, not a considered
  tradeoff against fps)
- Inversion radius: 2.0 (corrected from the initial 1.0 — matches
  reference exactly)
- Line threshold: `smoothstep(0.0, 0.02, d)`, where `d` is normalized by
  the accumulated scale `s` — this normalization is the fix; the
  threshold constant itself was re-tuned after the fix and is not
  comparable to earlier un-normalized values
- Final inversion taper radius: `0.1` (`smoothstep(0.0, 0.1,
  dist_to_inv)`) — added during Phase 2, keeps `inv_amount` from
  introducing distortion right at its own singularity; confirmed
  effective across a `0 → 0.7` sweep

fps spot-checked at 60+ standalone at these settings — comfortable, but
this was a single spot-check, not Phase 3's full sweep (see Phase 3 below,
still open).

### Phase 1 — Core Ford-circles loop verified in scratch patch

Translate the Ford-circles fold (ADR-1) into GenExpr: fixed-count `for`
loop (start with 8, per the reference), each iteration: invert in unit
circle (guarded per ADR-5), swap x/y, modulo-wrap x. Final step: the
two-line/two-circle distance field (`min(d1,d2)/s`), rendered as a
smoothstep-thresholded line drawing matching the reference's visual
character (or iteration-depth coloring if that reads better in practice —
untested which is more legible on this pipeline, decide by looking).

**Codebox structure**:
- No texture inlets (`in1` not referenced — pure generator)
- `Param bypass(0.0)`
- Fixed loop count as a hardcoded constant first (not yet a param, per
  spec's Explicitly Deferred), to isolate "does the fold work at all"
  from "what's the right iteration count" — the latter is Phase 3's job

**Checkpoint** (spec User Story 1, Acceptance Scenarios 1–2):
- Visually matches the Ford-circles reference's structural character —
  nested tangent circles, self-similar
- No NaN/undefined output anywhere in frame (confirms or refutes ADR-4's
  prediction)
- If unexpected visual breakage appears, check epsilon guard (ADR-5)
  before suspecting the fold math itself

---

### Phase 2 — Final animatable inversion added

Add `inv_x`, `inv_y`, `inv_radius`, `inv_amount` per ADR-3. Wire
`inv_amount` to a test LFO or manual dial for continuous sweeping.

**Checkpoint** (spec User Story 2, all Acceptance Scenarios):
- `inv_amount = 0` output is pixel-identical to Phase 1's output
  (regression check, satisfies FR-004 directly per ADR-3's mix-based
  approach — should be a strong pass, not approximate)
- Continuous sweep of `inv_x`/`inv_y`/`inv_radius`/`inv_amount` never
  produces a visibly broken pattern
- Specifically test `inv_radius` near zero and `inv_center` landing near
  a point the main loop already inverted through — confirm non-crashing
  (ADR-5's guard should cover this; confirm it actually does)

---

### Phase 3 — Iteration count and fps calibration

With both Phase 1 and 2 confirmed correct, sweep the fixed iteration
count (try 4, 8, 16, 32) and measure fps at each, at 1920×1080 and
3840×2160, alongside at least one other `f_` module running
simultaneously (per `f_vf_seeds`/`f_vf_vorticity` fps-measurement
precedent).

**Checkpoint** (spec User Story 3, Success Criteria 4):
- fps recorded at each tested iteration count, both resolutions
- A specific iteration count is chosen as the shipped default, balancing
  visual completeness against the 60fps target (NF-002) — record the
  reasoning, not just the number, since this is exactly the kind of
  tradeoff `HANDOFF.md`/`plan.md` should preserve for future sessions
  (same practice as `f_vf_seeds`' `field_gain` range documentation)

---

### Phase 4 — definition.py + build

Write `.specify/f_apollonian/definition.py` from the confirmed codebox.

**Key definition.py fields**:
- `archetype: "generator"`
- No inlets (self-sufficient, per FR-002/ADR technical context)
- `@type char` (standard color output, not f_vecfield)
- Params: iteration count (if promoted to live per Phase 3 findings —
  otherwise stays a hardcoded constant), `inv_x`, `inv_y`, `inv_radius`,
  `inv_amount`, `bypass`

**Checkpoint**: Patch opens in Max via `tools/build_patcher.py`'s
single-codebox path. All params appear in UI and respond correctly. Pix
compiles without console errors.

**IMPORTANT (2026-07-08)**: Per spec.md's "What 'production' means"
section, completing this checkpoint does **not** mean the module is
production-ready — it means a proof-of-concept has been promoted to a
`.maxpat` file. Generalized/arbitrary generating configurations,
per-region texture sampling, and a live iteration-count param are what
define "production" for this module. Don't let a working `definition.py`
build read as "done."

---

### Phase 5 — Documentation and status update (registration deferred)

Given this spec's deliberately narrow scope (core mechanism only — no
`f_poincare` merge decision, no texture sampling), full `f_modules.maxpat`
registration is **not** part of this plan. Instead:

- Write `docs/f-reference/f_apollonian.md` as a working scratch/mechanism
  reference (not a full as-built doc, since the module isn't registered
  yet) — GPU Gems / Shadertoy attribution per the project's attribution
  practice (used directly vs. adapted vs. inspired — this is "adapted
  from," the fold math is translated, not copied verbatim)
- Update `ideas/f_apollonian.md`'s status and Open Questions to reflect
  what Phases 1–3 actually found (especially: does ADR-4's prediction
  hold, what iteration count was chosen, and the ADR-2 `break` question's
  deferred status)
- Update `HANDOFF.md` with next-session pointers: the `f_poincare`
  relationship decision, the ring+central-circle construction as a
  follow-up build, and per-region texture sampling as the next real
  evolution

---

## Complexity Notes

ADR-1's choice to build the "wrong" (Ford, not classical 4-circle) gasket
first is the main judgment call in this plan — worth restating plainly:
this trades visual canonicity for implementation safety on the first
pass. If Phase 1–3 go smoothly, the ring+central-circle construction
(closer to what most people picture as "Apollonian gasket," and more
directly relevant to a future `f_poincare` unification) is a natural
next-spec candidate, not a discarded idea.

ADR-4's prediction (non-convergent-pixel handling is moot for this
construction) is the other real unknown — stated as a prediction, not a
certainty, and Phase 1 must confirm it rather than assume it going into
Phase 4's `definition.py`.
