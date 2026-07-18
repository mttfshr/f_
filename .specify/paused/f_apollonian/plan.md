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

**RESOLVED 2026-07-08 (tasks.md T111–T119)**: The branchless
`settled`-flag approach recommended above is confirmed working —
`break` was never needed or tested. Every one of the 4 generator
circles (3 ring + 1 enclosing) is checked unconditionally every
iteration; priority order is resolved via nested `mix()` gated by
`step()`-based containment flags, not by exiting the loop.

**Real implementation difficulty this exposed, worth recording
precisely since it wasn't just "write the branchless version and it
works":** getting the branchless update to actually compile took three
attempts, each failing with a Gen compiler error of the same class
("variable X is not defined") but for three different underlying
reasons — repeated reassignment of one variable as both read-source and
write-target in a loop, then the same failure recurring on staged
replacement temporaries, then recurring a third time on a single bare
alias assignment (`ox = zx;`) that never should have been complex
enough to hit a capture-ceiling at all. That third failure is the most
informative: it suggests Gen's optimizer may copy-propagate a plain
variable-to-variable alias and lose track once its source is reassigned
later in the same scope — a different failure shape than the
`f_vf_seeds`/`f_masonry` capture-count-ceiling precedent this ADR
initially expected to be the relevant risk. **Not fully root-caused —
if this resurfaces in a future module, treat "variable not defined" as
a family of at least two distinct failure modes, not one.**

**The actual working idiom**: parallel comma-assignment,
`zx, zy = <exprX>, <exprY>;`, evaluating both right-hand sides against
the same pre-update point before writing either left-hand side — with
zero extra named variables. This is the same idiom the `jit-gen-codebox`
skill already documents for built-in multi-value returns; confirmed
here to also work for two independently-computed expressions rather
than one function's paired outputs. **A logically incorrect
intermediate version compiled with no errors at all** (writing `zx`
then reading the now-updated `zx` inside `zy`'s expression) — worth
restating since it's the same "clean compile ≠ correct" lesson ADR-1's
Ford-circles work already logged once this session, now confirmed
general rather than a one-off.

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

### ADR-6: Generalized ring count via derived-not-stored circle data, count only (2026-07-08)

**Context**: Spec User Story 2.5 (production item #1) requires the ring
to support counts other than the hardcoded N=3 used in T111–T119, while
Matt explicitly scoped this to count-only — equal-radius, evenly-spaced
circles at every count, not variable relative sizes and not arbitrary
independent circles.

**Decision**: Ring circle `i`'s center/radius are computed each frame
from `i`, `ring_count`, and enclosing radius `R` via closed-form tangency
trig (see spec FR-101 and its formulas) — no per-circle stored data (no
texture, no per-slot params). `ring_count` becomes a live param bounded
by a fixed compile-time `MAX_RING` slot count; the containment-check loop
becomes a nested `for i in 0..MAX_RING-1` inside the existing
gasket-iteration loop, with `i >= ring_count` slots branchless-gated
inert using the same idiom ADR-2's `settled`-flag already established.

**Rationale**: Equal-radius rings have a closed-form tangency solution
(derivation in spec.md), so there's no need for a tangency-solver or
stored per-circle data — the formula-per-index approach is strictly
simpler than either alternative discussed (fixed-max unrolled params with
independent x/y/r, or a texture-fed circle table), and matches Matt's
explicit "count only" scope decision. Discussed alternatives (texture-fed
arbitrary circle table, per-slot independent params) are recorded as
rejected-for-this-module, not merely deferred — see spec's Explicitly
Deferred (this evolution).

**Consequences**:
- Positive: no new data-plumbing mechanism (no texture read inside a
  loop, no per-circle param explosion) — smallest reasonable change to
  the existing confirmed T111–T119 codebox
- Negative/risk: nesting a nested `for i in 0..MAX_RING-1` ring-candidate
  loop inside the existing gasket-iteration loop is more deeply nested
  than anything built in this module so far — real capture-ceiling risk
  (per `f_vf_seeds`/`f_masonry` precedent), flagged explicitly in FR-104.
  If a single codebox won't compile at the chosen `MAX_RING`, split into
  a multi-stage `jit.gl.pix` chain (same resolution pattern already used
  for `f_vf_seeds`) rather than reducing `MAX_RING` to dodge the ceiling
- `MAX_RING`'s value is a real open tuning question (start at 8, per
  spec FR-102) — needs its own scratch-confirmed choice, balancing
  capture-ceiling/fps risk against how large a ring a performer would
  actually want live

**Real compile failure hit implementing this (2026-07-08), same family
as ADR-2's, different shape**: a first attempt used a nested `for (k =
0; k < MAX_RING; k += 1)` loop with a loop-carried scalar accumulator
(`res_x = mix(res_x, ..., inside_k);`, reassigning `res_x` across `k`
iterations) — failed to compile with `"res_x" is not defined`. This is
a different shape than any of ADR-2's three documented failures: those
were all about *reading an updated variable within the same statement*
or a bare alias reassignment; this is a **loop-carried single-scalar
accumulator across a nested `for`**, which the T111–T119 codebox never
actually did — its own `zx`/`zy` update is one paired comma-assignment
statement per outer-loop iteration, not a scalar folded across an inner
loop. **Fix**: abandon the inner `for`-over-`k` entirely and fully
unroll the `MAX_RING=8` candidates into one nested-`mix()` expression,
structurally identical to T111–T119's proven 4-candidate (3 ring + 1
enclosing) chain, just extended to 9 candidates (8 ring + 1 enclosing).
Ring circle centers/active-gates are computed once before the gasket
loop (they depend only on `ring_count`, not per-pixel state), same as
T111–T119's constants. **This reintroduces the real capture-ceiling
risk FR-104 already flagged** — a single statement folding 9 candidates
is meaningfully larger than the 4-candidate chain that already worked,
so this is the actual test of whether a single codebox holds or a
multi-stage split (per `f_vf_seeds` precedent) is needed. Not yet
confirmed either way.

**Second silent failure hit (2026-07-08)**: the fully-unrolled retry
compiled clean but rendered solid black. Root cause: the per-candidate
containment flags were named `in0`–`in7`, and `inN` (an `in` followed by
digits) is GenExpr's actual inlet-reference syntax. Renaming to
`ins0`–`ins7` fixed it. Logged as a new pattern in the `jit-gen-codebox`
skill.

---

### ADR-7: Real reference source obtained — the ring+central-circle construction was fundamentally mistranslated, not just missing generalization (2026-07-08)

**Context**: After the `ins`-rename fix, `ring_count` swept cleanly across
2/3/4 with no crashes or NaN, but Matt correctly identified that the
render showed no legible recursive circle-packing — just the base
circles and swirly fractal-boundary detail at tangent points, no visibly
nested smaller circles. Initial hypotheses (coloring legibility, viewing
orientation) were tested and ruled out via direct comparison against the
unmodified original T111–T119 codebox, which produced **pixel-identical**
output — ruling out a regression from this session's generalization work,
but not ruling out a pre-existing bug in T111–T119 itself. Matt then
supplied the actual reference GLSL source (`shadertoy.com/view/MlVfzy`,
the real ebanflo-derived/mla-modified shader — see
`ideas/f_apollonian_reference_glsl.md` for the full preserved source),
enabling a real line-by-line diff instead of further guessing.

**The actual bug, confirmed by the diff**: T111–T119's construction
invented a large "enclosing" circle (`encR2`) that inverts every point
landing outside it back inward, unconditionally, every iteration,
indefinitely. **This circle does not exist anywhere in the real
reference.** The actual reference has:

- N ring circles: centered at distance `r = 1/cos(theta)` from origin,
  radius `s = tan(theta)`, `theta = pi/N`
- ONE small central circle: centered at the ORIGIN (not a giant bound),
  radius `r - s` — for N=3, radius ≈0.268 vs. the ring circles' ≈1.732,
  genuinely different sizes (matches Matt's observation that "the
  largest packed circles are not identical sizes")
- **No enclosing/outer circle at all.** Each iteration checks the
  central circle, then each ring circle; the instant a point isn't
  inside ANY of the N+1 circles, the loop terminates for that point
  (real per-pixel variable-length escape, via `break` in the reference)

T111–T119's fabricated enclosing-circle inversion was applied to the
majority of the frame every single iteration — a real, continuously-
applied transform that has no counterpart in the actual algorithm. This
fully explains the swirl-without-packing visual: most pixels were being
corrupted by a transform that shouldn't exist, not failing to show real
packing that was otherwise present.

**Consequence — T111–T119's "CONFIRMED WORKING AND CORRECT" status is
REVOKED, not just this session's generalization work.** The original
hardcoded N=3 version has the identical bug (confirmed via the
side-by-side test above, before the real reference was obtained) — it
was never actually a correct Apollonian gasket construction, despite
passing every check that was run against it (no NaN, clean console,
"recognizable gasket-like character"). This is the same "compiled clean,
looked plausible, wasn't actually correct" trap this project has hit
before (Ford-circles' missing scale accumulator, `f_masonry`'s slot bug)
— worth restating as a general lesson: **visual plausibility of a
fractal-like image is not evidence of correctness against a specific
target construction** — only a direct comparison against verified
reference source or reference output actually confirms it. This project
went two full sessions (T101–T119) on an unverified construction because
no one had the actual reference source to diff against until this
session.

**Decision — corrected construction, replacing the fabricated enclosing
circle with the real central circle + genuine settle/escape logic**:

- `ringR2 = s*s` (not the previous fixed `1.0`), `centralR2 = (r-s)*(r-s)`
  (replacing `encR2` entirely — this is a different circle in a
  different place serving a different structural role, not a renamed
  version of the old one)
- Ring circle positions: `(r*sin(2*i*theta), r*cos(2*i*theta))`, matching
  the reference's exact angle/axis convention (not this session's earlier
  `cos`/`sin` convention, which was an independent, unrelated deviation
  worth dropping now that we have the real reference to match)
- **The genuine escape/settle behavior needs a different branchless
  idiom than what T111–T119 used.** T111–T119's `settled`-flag (per
  ADR-2) picked among always-active candidates every iteration — it
  never actually froze a point once it escaped, because in the invented
  construction, every point was always inside either a ring/central
  circle or the fabricated enclosing circle, so there was never a true
  "outside everything" state to freeze at. The real reference's `break`
  is a genuine per-pixel variable-length escape: once a point isn't
  inside any of the N+1 real circles, it's done, permanently, for that
  pixel. Branchless equivalent: a **sticky `active` flag**,
  `active = active * any_inside` each iteration (multiplicatively
  latching to 0 forever once a point escapes, never recovering) — this
  refines ADR-2's resolution rather than replacing it: the "no `break`
  needed, branchless flag suffices" conclusion still holds, but the
  flag's job is freezing state at true escape, not selecting among
  perpetually-active candidates.
- Depth accumulation, position update, and `s`-scale accumulation (if
  used for line-drawing) must all be gated by this same `active` flag,
  not just the per-candidate `any_inside` flag — a point that has
  already escaped must not keep accumulating depth or moving in later
  iterations, or the "settled" state has no meaning

**This does not change ADR-6's ring-count generalization approach**
(formula-derived-not-stored circle data, fixed `MAX_RING` slot budget,
branchless `active_k` gating per slot) — that architecture is sound and
orthogonal to this bug. What changes is the actual tangency formulas
(`ringR2`/`centralR2`/positions, corrected per the real reference above)
and the addition of the sticky escape-freeze mechanism, which T111–T119
never needed because its invented construction never had a genuine
"escaped" state.

---

### ADR-8: Accumulated Möbius-transform tracking, replacing fold-path coloring with real mapped-circle containment (2026-07-09)

**Context**: ADR-7's corrected escape/settle construction fixed the
fabricated-enclosing-circle bug, but Matt's visual read of the corrected
render (screenshot, 2026-07-09) found continuous rainbow-swirl bands at
tangent points rather than the flat, solid, round discs the reference
images (and the actual definition of an Apollonian gasket — mutually
tangent circles, each recursively filled) require. Root cause, confirmed
by rereading the saved reference source in full (not just its prior
summary — see the new standing rule added to `vsynth-bpatcher/SKILL.md`
this session): our codebox colors by `depth`/`last_id`, both properties
of the **fold path** a point took (how many inversions, which circle it
last passed through) — neither is a test against a real circle in screen
space, so nothing forces the colored regions to be round. The primary
reference (`shadertoy.com/view/MlVfzy`) doesn't solve this either — it
only computes escape-time `n`. The *second* reference we saved
("Apollonian Britney", `shadertoy.com/view/Xclfzj`'s sibling) does solve
it: it tracks the **accumulated Möbius transform** through the settle
loop, inverts it once at the end, and applies it to a small fixed set of
canonical "limit circles" to find their true image position/radius in
*this pixel's original screen frame* — then does a real containment test
against that mapped circle. That's what produces flat discs.

**Decision**: Add accumulated-transform tracking to the existing
iterated-inversion loop (ADR-7's construction, unchanged), then use the
inverted transform to map 4 canonical "limit circles" (3 ring + 1
central, formula below) into screen space and test real containment
against them for coloring — an addition on top of the existing
mechanism, not a replacement of it.

**Why this is not a pivot to Descartes' Circle Theorem** (a real option
Matt raised and I initially over-corrected toward): Descartes' theorem
explicitly solves for a new tangent circle's radius/position from three
existing ones and would require a genuinely different loop structure
(building an explicit growing list of circles). What we're doing instead
stays entirely within the already-working iterated-inversion/reflection-
group method — we're just completing the half of it our codebox was
missing (screen-space circle reconstruction), matching what the second
reference actually does. Confirmed this by rereading both saved reference
sources in full this session, not by assuming from memory.

**Math, worked from first principles for this project's specific
per-step formula** (not copied from the reference's complex-matrix
notation, since GenExpr has no complex/matrix types and the reference's
own matrix construction wasn't fully legible without re-deriving it):

- Each inversion step is anti-holomorphic:
  `f_k(z) = c_k + r2_k / conj(z - c_k)`, equivalently
  `f_k(z) = M_k(conj(z))` where `M_k` is the *holomorphic* Möbius matrix
  `[[c_k, r2_k - |c_k|²], [1, -conj(c_k)]]`.
- Composing a chain of such steps, tracking only a holomorphic matrix
  `N_k` and the *parity* of how many steps have been applied (`depth`,
  which we already accumulate), gives a clean recursion:
  `N_{k+1} = M_{k+1} · conj(N_k)` (matrix product, entries conjugated
  elementwise), for every step — parity doesn't change the update rule,
  only how the *final* total map is interpreted: total forward map is
  `N_k(z)` if `depth` even, `N_k(conj(z))` if `depth` odd.
- Möbius matrices are projective (defined up to a nonzero scalar
  multiple) — this means the standard adjugate inverse
  `N⁻¹ = (d, -b, -c, a)` is valid **without dividing by the determinant**,
  the same simplification the reference's own `cMobiusInverse` uses.
- To map a **circle** (not just a point) through `N⁻¹`, use the
  reference's `cMobiusOnCircle` approach: map the circle's center with a
  correction term (`z -= r² / conj(d/c + center)`), then apply the plain
  Möbius point-map; get the radius by also mapping `center + (radius, 0)`
  and taking the distance between the two mapped points.
- When `depth` is odd, the *whole* accumulated map includes an extra
  outer conjugation — geometrically this is just a global y-axis mirror,
  so it's applied **after** the circle-mapping step by negating the
  mapped circle's y-coordinate (`mix(Dy, -Dy, is_odd)`), not by
  complicating the matrix math itself.
- **Canonical limit circles** (defined once, independent of any per-pixel
  fold, using the same `theta`/`r`/`s` already computed): ring limit
  circles at `(-cos(2iθ)·R_lim, sin(2iθ)·R_lim)`, radius `R_lim_r`, where
  `R_lim = (r-s)·r` and `R_lim_r = (r-s)·s`; central limit circle at the
  origin with radius exactly `1.0` (this elegant result — the "never
  inverted" region maps back to the full unit disk — comes directly from
  the reference, not independently derived, and is a good sanity check
  if implemented correctly).

**Alternatives rejected**:
- Pivoting to explicit Descartes-theorem circle generation (my initial,
  over-corrected suggestion): rejected because it's not what either
  saved reference actually does, and would require a structurally
  different loop (explicit growing circle list) rather than extending
  the confirmed-working iterated-inversion mechanism already in place.
- Tuning the existing `last_id` coloring further (softer bands, blurred
  transitions, etc.): rejected — no coloring scheme built on `depth`/
  `last_id` can produce round discs, since neither is a screen-space
  circle test. This is a structural gap, not a tuning one, matching the
  standing project lesson (`f_masonry`, Ford-circles) that a
  compiles-and-looks-plausible result isn't evidence of correctness
  against the actual target.

**Consequences / real risks, named upfront rather than discovered**:
- **Real capture-ceiling risk, likely the biggest one yet in this
  project.** This adds 9 new user-defined functions (complex multiply/
  divide, plain Möbius point-map, circle-map x/y/radius) and roughly
  doubles the per-iteration variable count inside the existing loop
  (8 new scalars for the accumulated matrix, updated branchlessly every
  iteration via the same nested-`mix()` priority-chain idiom as the
  existing position/color-id updates). If this doesn't compile as one
  codebox, the fallback is the same multi-stage `jit.gl.pix` split
  already proven for `f_vf_seeds`/`f_masonry` — split the settle loop
  (producing `zx,zy` + the accumulated matrix + `depth`) from the
  post-loop limit-circle mapping/coloring into two stages.
- **This is a from-scratch derivation, not a direct translation** — the
  reference's own matrix construction wasn't fully re-derivable from its
  code alone in the time available this session, so the composition
  rule above was worked out independently from the known mathematical
  fact that circle inversions are anti-holomorphic Möbius maps. This
  needs empirical confirmation in Max before being trusted, same as any
  other new codebox math — check the console first, then check that the
  four base circles render as genuinely round, flat discs (the actual
  target), not just "different from before."
- A useful built-in sanity check: since the forward-fold `zx,zy` are
  already computed independently by the existing loop, `N_k` applied to
  the *original* pixel position should reconstruct `zx,zy` exactly
  (`N_k(z0)` if `depth` even, `N_k(conj(z0))` if odd) — if this project
  ever needs to debug the matrix tracking specifically, comparing against
  the already-trusted `zx,zy` is a stronger check than eyeballing the
  final coloring alone.
- Added a `use_mapped` param (0/1) so the existing `last_id` coloring and
  the new mapped-circle coloring can be A/B compared directly in Max
  without reverting the file — consistent with this project's general
  preference for direct empirical comparison over trusting either
  version blind.

**Update (2026-07-09, via f_poincare diagnostic detour)**: the
composition/parity/circle-inversion math has since been confirmed
correct at the GPU runtime level (not just on paper) via isolated
testing in `f_poincare`'s scratch files — see that module's `plan.md`
Phase 2 result. One real, previously-undiagnosed factor found there:
**the mismatch-detection threshold used in debug views (`0.01`) was too
strict** — Möbius transforms are inherently ill-conditioned near their
pole (points mapping to large magnitudes), and GPU float32 precision
degrades there in an expected, bounded way that a tight threshold
misreads as a hard logic error. Any renewed debugging of this module's
remaining visual mismatches should first relax the threshold (informed
by `f_poincare`'s `0.3` finding, though the right value likely scales
with the circles' own scale) before concluding a mismatch is a real bug
rather than expected numerical softness. The central-circle
position-update bug (above) is confirmed real and fixed regardless.

**Update 2 (2026-07-09, later same session) — MODULE SHELVED, real
contradictory findings recorded, not resolved. Read this in full before
resuming.**

Matt made the explicit call to stop and shelve this module for now,
after this session's re-testing produced two results that don't fit
together and weren't reconciled before stopping:

1. `debug_ok`'s threshold in `apollonian-scratch.maxpat` was relaxed
   from `0.01` to `0.3` (per Update 1 above), file was confirmed reopened
   in Max (not just edited on disk) so the change was live. **At
   `use_mapped=2` (pass/fail debug view) after this change, the four
   large ring/central regions still rendered solid red (fail)** — no
   visible improvement from the threshold relaxation, contradicting
   `f_poincare`'s isolated single-circle test where the same relaxation
   made the mismatch shrink dramatically.
2. Immediately after, `use_mapped=4` (the actual signed-error-vector
   view, `err_col_r/g`) was checked at the same `ring_count=3` — **and
   showed the opposite result**: the four large regions rendered flat
   neutral gray (meaning near-zero `err_x`/`err_y`, i.e. should read as
   pass), with colorful error blooms appearing only right at the tangent
   points between circles, fading smoothly outward — exactly the
   pole-proximity signature ADR-8's math would predict, and a genuinely
   good-looking result on its own.

**These two views should agree and don't.** Zero-error-reading regions
(`use_mapped=4`, gray) should be exactly the `debug_ok=1` (pass, green)
regions in `use_mapped=2` — instead `use_mapped=2` showed those same
regions as fail (red). This was never reconciled this session. Real
candidate explanations, none confirmed:
- `debug_ok`'s own wiring/threshold comparison has a bug independent of
  the `err_mag` calculation that `use_mapped=4` visualizes (i.e. `err_mag`
  itself may be fine, but `step(err_mag, 0.3)` or its downstream color
  mix isn't reading it correctly)
- The two screenshots were not actually taken under identical conditions
  (e.g. a stale compiled state on one of the two checks) despite Matt's
  confirmation of reopening the file earlier in the session — cannot be
  ruled out, wasn't independently verified via a fresh back-to-back pair
  before Matt called it
- Something in the color-mix override chain (`is_debug`/`is_depth_view`/
  `is_err_view`, all layered via sequential `mix()` calls gated by
  `step()` on `use_mapped`) has a boundary bug affecting `use_mapped=2`
  specifically — untested

**A separate, real, unrelated finding from this session, safe to keep
regardless of the above**: `ring_count=2` renders solid black. This is
expected and correct, not a bug — `theta = pi/ring_count` gives
`theta = pi/2` at N=2, making `r = 1/cos(theta)` a division by zero.
The tangency formula this module uses is only valid for `ring_count >= 3`.
Worth a guard/range floor whenever `ring_count` is promoted to a live
param (ADR-6/spec User Story 2.5) — not yet added anywhere.

**This session also produced one real process mistake worth naming
plainly**: mid-session, `use_mapped=3` (the depth/iteration bit-plane
coloring view) was misidentified as the error view and analyzed at
length as if it were — a real misreading of the codebox's own
`is_debug`/`is_depth_view`/`is_err_view` override order (`use_mapped`
thresholds at 1.5/2.5/3.5, so `3` selects depth view, `4` selects error
view, not `3`). The wrong analysis was retracted once caught, but real
time was spent reasoning from it. Lesson: when reasoning about a
multi-mode debug codebox's output, check the actual `step()` threshold
values against the requested `use_mapped` number before interpreting the
image, don't rely on remembering which number maps to which mode.

**Next session, if this module is picked back up, must start here — not
by resuming `ring_count` generalization, and not by assuming either the
`use_mapped=2` or `use_mapped=4` result is the trustworthy one:**
1. Get one clean, verified-fresh back-to-back pair: `use_mapped=2` then
   `use_mapped=4`, same `ring_count`, confirmed no stale compile state
   between them (e.g. force a trivial param nudge and back, or fully
   close/reopen the patch immediately before each screenshot) — this
   session's pair was not confirmed clean this way before stopping
2. If they still disagree once genuinely controlled, treat `debug_ok`'s
   own logic (the `step(err_mag, threshold)` line and its color-mix
   wiring, not the error calculation itself) as a prime suspect and
   trace it directly, rather than re-litigating the threshold value
   again
3. Only once `debug_ok` and the actual error magnitude are confirmed to
   agree does it make sense to form a real opinion on `use_mapped=1`'s
   (the actual mapped-circle coloring) visual correctness — this
   session's `use_mapped=1` screenshot (large blue disc with an
   insect/bird-shaped black cutout) should be treated as uninterpreted
   pending that reconciliation, not as a confirmed remaining defect to
   fix directly

---


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

### Phase 2.5 — Generalized ring count (production item #1, ADR-6) — NEXT UP (2026-07-08)

This is the phase to pick up next, ahead of Phase 3. Implements spec
User Story 2.5 / ADR-6: replace the T111–T119 codebox's hardcoded N=3
ring circles with formula-derived circles indexed by a nested
`for i in 0..MAX_RING-1` loop, gated by a live `ring_count` param.

**Steps**:
- Pick an initial `MAX_RING` (start at 8, per ADR-6)
- Implement the tangency formulas (spec FR-101) as a small helper
  function (`ring_circle(i, ring_count, R)` returning center/radius) —
  check whether GenExpr user-defined functions can return the pair
  cleanly or whether this needs the same parallel comma-assignment
  idiom ADR-2 already confirmed for two independently-computed values
- Nest the ring-candidate loop inside the existing gasket-iteration
  loop; gate `i >= ring_count` slots inert via the same branchless
  `mix()`/flag idiom as the existing 4-circle containment check
- Compile-check first, before any visual verification — this is the
  step most likely to hit a capture-ceiling issue (per ADR-6's risk
  note); if it does, split into a multi-stage `jit.gl.pix` chain rather
  than shrinking `MAX_RING` to route around it

**Checkpoint** (spec User Story 2.5, all Acceptance Scenarios):
- `ring_count = 3` regresses cleanly against the existing confirmed
  T111–T119 output (formula must reduce to the same hardcoded values)
- `ring_count` swept across other in-range values each produces a
  correctly-tangent, N-fold-symmetric closed gasket — no gaps, overlaps,
  or NaN
- Slots beyond `ring_count` (up to `MAX_RING`) are confirmed inert
  regardless of pixel position
- Codebox compiles clean at the chosen `MAX_RING` (or the multi-stage
  fallback compiles clean, if needed)

---

### Phase 3 — Iteration count and fps calibration — LOW PRIORITY, blocked behind spec.md's production items (2026-07-08)

**Deprioritized, per Matt's explicit call (2026-07-08).** Per spec.md's
"What 'production' means" section, three items — generalized/arbitrary
generating circle configurations, a live max-iteration-count param, and
per-region texture sampling — take priority over this phase, in that
order. Two of the three directly change what Phase 3 would even be
measuring: generalized circle configs change per-iteration cost, and
promoting iteration count to a live param turns "pick one fixed shipped
default" into a live-tunable range instead of a single number to choose.
Running this sweep before those land would measure the wrong
construction. Do not pick this phase up next — go to the three items
above (each needs its own spec/plan/tasks pass) before returning here.

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
