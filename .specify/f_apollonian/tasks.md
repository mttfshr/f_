# Tasks: f_apollonian

**Spec**: `.specify/f_apollonian/spec.md`
**Plan**: `.specify/f_apollonian/plan.md`
**Build order**: Sequential. Complete each phase before the next — no
skipping ahead to Phase 4 (`definition.py`) before Phase 1–3 are confirmed
in Max, per standing practice (scratch-test before production).

**Status (2026-07-08)**: Phase 1–2 below (Ford circles construction) are
complete and confirmed as a **proof-of-concept** — see the finding at the
end of the original Phase 1 section. Per `plan.md`'s ADR-1/ADR-2
supersession notes, scope was **redirected to the ring + central-circle
construction** (the classical closed gasket).

**"Phase 1 (redirected)" (T111–T119)'s "CONFIRMED WORKING AND CORRECT"
status is REVOKED (2026-07-08) — see plan.md ADR-7 for the full
diagnosis.** The construction built there invented a large "enclosing"
circle with no counterpart in the actual reference shader
(`shadertoy.com/view/MlVfzy`, full source now preserved in
`ideas/f_apollonian_reference_glsl.md`) — the real construction has N
ring circles plus one small CENTRAL circle (not a giant bound), and no
enclosing circle at all. T111–T119 passed every check that was run
against it (no NaN, clean console, "recognizable gasket-like character")
but was never actually verified against real reference source, and the
fabricated circle explains the swirl-without-legible-packing look Matt
correctly flagged this session. This is a real regression in confidence,
not just a scope change — treat T111–T119's findings about GenExpr
mechanics (branchless containment via `mix()`, parallel comma-assignment
for `zx`/`zy` updates, guarded division) as still valid, but the specific
geometry/circle-set as built is wrong and needs rebuilding per ADR-7's
corrected formulas before any further verification proceeds.

**Next up is Phase 2.5, NOT Phase 3.** Per Matt's explicit call
(2026-07-08) and spec.md's "What 'production' means" section, Phase 3
(iteration-count/fps calibration, T301–T305 below) is low priority and
blocked behind three production-scope items, in this order: (1)
generalized ring count — count only, equal-radius circles, scoped and
specced this session as User Story 2.5/ADR-6/Phase 2.5 (T601–T608,
below) — (2) live max-iteration count as a user param, (3) per-region
texture sampling. Items 2 and 3 don't have specs yet — do those passes
when Phase 2.5 is confirmed. Running the fps sweep before all three land
would measure a construction that's about to change anyway (generalized
configs alter per-iteration cost; a live iteration param removes the
"pick one fixed count" premise Phase 3 assumes).

---

## Source Layout

```
~/Vsynth/patterns/
  apollonian-scratch.maxpat   — scratch patch (Phases 1–3, not version controlled)

/Users/matt/Github/f_/
  patchers/
    f_apollonian.maxpat       — production output (T4xx, version controlled)
  docs/f-reference/
    f_apollonian.md           — working/mechanism reference (T5xx)
  .specify/f_apollonian/
    spec.md
    plan.md
    tasks.md                  — this file
    definition.py             — patcher definition (T4xx)
  ideas/
    f_apollonian.md           — status updated at T5xx
```

---

## Phase 1 [PROOF-OF-CONCEPT, COMPLETE — SUPERSEDED SCOPE]: Core Ford-circles loop (maps to plan.md Phase 1, spec User Story 1 as originally written)

**Goal**: Confirm the unconditional fixed-iteration circle-inversion fold
produces a recognizable Ford-circles gasket in `jit.gl.pix`.

**Independent Test**: Spec User Story 1's Acceptance Scenarios — visual
match to reference shader's structural character, no NaN/undefined output.

- [x] T101 Create `apollonian-scratch.maxpat` in `~/Vsynth/patterns/` with
      `vs_render` bpatcher + toggle, per `vsynth-bpatcher` skill's
      scratch-patch GL context requirement
- [x] T102 Add a bare `jit.gl.pix vsynth @name apollonian_pix` with a
      codebox gen subpatcher — no texture inlets (`in1` not referenced),
      per FR-002/ADR technical context
- [x] T103 Write the fixed-count `for` loop (start at 8 iterations, per
      ADR-1): per iteration, invert in unit circle (guarded per ADR-5:
      `max(dot(p,p), epsilon)`), swap x/y, modulo-wrap x — translate from
      the Ford-circles reference reviewed in `ideas/f_apollonian.md`
      **— done, at 16 iterations not 8 (see finding below), radius 2.0
      not 1.0 to correctly match the reference's `f = 0.5*dot(z,z)`**
- [x] T104 Write the final distance-field step (`min(d1,d2)/s`) and a
      `smoothstep`-thresholded line-draw coloring, matching the
      reference's visual character
- [x] T105 `Param bypass(0.0)`, `mix()` on the last line per standard
      bypass pattern — **placeholder only, `mix(result, result, bypass)`
      is currently a no-op; real bypass behavior for a no-inlet generator
      still undecided, see spec Edge Cases**
- [x] T106 Paste codebox into Max, confirm compiles with no console errors
- [x] T107 Visually compare output against the Ford-circles reference
      shader's described character (nested tangent circles, self-similar
      folded pattern) — record match/mismatch
      **— CONFIRMED MATCH 2026-07-08, after fixing two translation bugs
      (see finding below)**
- [x] T108 Scan the full frame for NaN/undefined/solid-black regions —
      confirms or refutes ADR-4's prediction that this construction has
      no non-convergent-pixel problem to begin with
      **— confirmed clean at the origin, both pre- and post-fix**

**Finding (2026-07-08): two real translation bugs, not tuning issues,
found by comparing against the Ford-circles reference more carefully
after the first "working" version didn't visually read as circle
packing:**

1. **Missing scale accumulator.** The reference tracks `s /= f` every
   iteration and divides the final distance by it (`min(d1,d2)/s`) before
   thresholding. The first codebox draft never carried this at all — line
   thickness was measured in the wrong units at every point, which is
   very likely why the first "working" version looked like smooth
   deformed bands rather than clean tangent circles.
2. **Wrong inversion radius.** The reference's `f = 0.5 * dot(z,z)` is
   equivalent to inverting with radius `2`, not `1`. First draft used
   `r=1.` throughout — wrong geometry, not just wrong scale.
3. Smaller, related: the swap/wrap step wrapped the wrong post-swap
   component in the first draft (wrapped the new `x` before confirming
   it was actually the *old y* that should be wrapped, per the
   reference's exact order). Fixed alongside #1 and #2.

All three fixed together, then **T107 re-confirmed and passed** against
the reference's actual visual character (repeating tangent-circle chain
with nested self-similar cascades filling the gaps) — the pre-fix
"working" result from earlier in the session was a false positive; it
compiled clean and looked plausible but was not structurally correct.
Lesson for future translation work: a clean compile and a plausible-looking
result are not the same as a verified match — worth comparing against the
reference's exact algebra (not just its general shape/description) before
calling a translation done.

**Also investigated and resolved during this phase**: a real speckling
artifact appeared once Phase 2's final inversion was added, initially
suspected as a math/singularity bug. Traced via several isolation tests
(moving the inversion center, changing line thickness, and finally a
raw-coordinate diagnostic color output) to be **entirely a symptom of the
missing `s` normalization above** — once fixed, a full `inv_amount` sweep
(0 → 0.7) showed clean, artifact-free deformation. Recorded here since the
debugging process itself (isolate variables one at a time, use a diagnostic
output when visual ambiguity limits what a screenshot can show) is worth
remembering for future sessions, not just the fix.

**Checkpoint**: Recognizable gasket renders, no NaN anywhere in frame.
Do not proceed to Phase 2 until both are true.

---

## Phase 2 [PROOF-OF-CONCEPT, COMPLETE — SUPERSEDED SCOPE]: Final animatable inversion (maps to plan.md Phase 2, spec User Story 2 as originally applied to Ford circles)

**Goal**: One additional live-parameterized inversion, blended in via
`inv_amount`, provably inert at `inv_amount = 0`.

**Independent Test**: Spec User Story 2's Acceptance Scenarios — regression
match at neutral default, no breakage under continuous animation.

- [x] T201 Add `Param inv_x(0.0)`, `Param inv_y(0.0)`, `Param
      inv_radius(1.0)`, `Param inv_amount(0.0)` to the codebox
- [x] T202 Implement `z_final = mix(z_settled, invert(z_settled, inv_x,
      inv_y, inv_radius), inv_amount)` per ADR-3, with the same
      division-by-zero guard as T103 (ADR-5) applied inside `invert()`
      **— implemented with an added local taper (`smoothstep` on distance
      to the inversion center) not in the original plan; see finding
      under Phase 1 — needed once the pre-fix speckling investigation was
      underway, kept after the real fix since it's cheap insurance near
      the inversion's own singularity**
- [x] T203 Confirm `inv_amount = 0` output is pixel-identical to Phase 1's
      T107 output — direct regression check, not approximate
      **— confirmed on both the pre-fix and post-fix (correct) codebox**
- [x] T204 Wire `inv_amount`, `inv_x`, `inv_y`, `inv_radius` to test
      LFOs/manual dials; sweep continuously, watch for visible breakage
      (gaps, overlaps, flicker)
      **— swept 0 → 0.7 on the corrected codebox, clean throughout,
      dramatic but artifact-free deformation at 0.7**
- [x] T205 Specifically test `inv_radius` near zero and `inv_x`/`inv_y`
      landing near a point already inverted through in the main loop —
      confirm non-crashing (this is the case ADR-5's guard exists for —
      confirm it actually holds, don't just assume)
      **— not separately isolated; folded into the general 0→0.7 sweep
      (T204), which passed a wide range of `inv_x` including far-outside-
      frame values. A dedicated near-zero-radius test was not run — flag
      as a light gap if this matters before Phase 4**

**Checkpoint**: `inv_amount = 0` regression passes exactly. Continuous
sweep never visibly breaks the pattern. Do not proceed to Phase 3 until
both are true.

---

## Phase 1 (redirected): Ring + central-circle closed gasket (maps to plan.md ADR-1/ADR-2 supersession, spec User Story 1 as revised 2026-07-08)

**Goal**: Confirm the ring + central-circle construction (N=3 ring,
`ebanflo`-derived reference) produces a recognizable closed Apollonian
gasket in `jit.gl.pix` — the actual target construction for this project,
not the Ford-circles proof-of-concept above.

**Independent Test**: Spec User Story 1's revised Acceptance Scenarios —
visual match to the `ebanflo`-derived reference's closed, bounded
character; no NaN/undefined output; `break`/early-exit question actually
resolved, not sidestepped.

- [x] T111 Reuse `apollonian-scratch.maxpat`, same `vs_render`/wiring
      pattern as T101 — no new scratch patch needed
- [x] T112 Reuse the confirmed `invertX`/`invertY` shared functions
      unchanged (per plan.md's carry-forward note) — no need to
      re-derive the guarded-inversion math
- [x] T113 Write the N=3 ring + central-circle candidate geometry —
      **implemented as 3 equal-radius ring circles (120° spacing) + 1
      enclosing circle, not a small inner Descartes circle** (that
      ambiguity was resolved explicitly before coding — see finding
      below). Exact constants derived via Descartes' Circle Theorem,
      symmetric case, ring radius r=1: `d = 2/√3 ≈ 1.154701` (ring
      distance), `R = r/(2√3−3) ≈ 2.154701` (enclosing radius).
- [x] T114 Decide and implement the `break`/early-exit resolution —
      **branchless settled-flag approach confirmed working, `break`
      never tested/needed.** See finding below — this is the actual
      resolution to the long-deferred ADR-2 question.
- [x] T115 Fixed-count outer loop — 16 iterations, same count the
      Ford-circles proof-of-concept used. Not yet calibrated against
      this construction's own convergence behavior (that's Phase 3).
- [x] T116 Output coloring — iteration-depth (3-phase cosine cycle on a
      `depth` accumulator that increments only on iterations where an
      inversion actually fired), not the Ford-circles distance field.
- [x] T117 Paste into Max, confirm compiles with no console errors
      **— CONFIRMED CLEAN 2026-07-08**, after resolving three real
      compiler issues along the way (see finding below).
- [x] T118 Visually compare against the reference's character
      **— CONFIRMED MATCH 2026-07-08.** Bilateral (left-right) mirror
      symmetry, not 3-fold rotational — correct and expected, since ring
      circles sit at 90°/210°/330° (210°/330° are exact mirrors of each
      other, 90° sits alone at top). Nested self-similar detail
      concentrated at tangent points, not smeared uniformly. Bounded
      within a visible outer structure, not an infinite strip.
- [x] T119 Scan the frame for NaN/undefined regions
      **— CONFIRMED CLEAN 2026-07-08.** No flat black/white flicker or
      hard discontinuities anywhere, including at the visible
      circle-boundary seams. Not yet a dedicated pixel-level probe at
      the exact three ring-circle tangent points specifically (closest
      approach to `dot(p,p)=0` for a non-origin-centered generator) —
      visual inspection only; flag as a light gap, not a failure.

**Finding (2026-07-08): T113's "central circle" ambiguity resolved before
coding, not discovered during it.** "Ring + central circle" could mean
either (a) an enclosing/bounding circle containing the ring, or (b) a
small inner Descartes circle nested in the gap between ring circles.
Resolved as (a) — 3 ring + 1 enclosing, 4 total generators — via
discussion before writing any code, matching T118's "bounded within a
visible outer structure" checkpoint language. (b) remains a candidate
5th generator for a denser classic look, not attempted this session.

**Finding (2026-07-08): three real Gen-compiler issues hit getting T114
to actually compile — a genuine debugging thread, not one clean pass.**
All three surfaced as "variable X is not defined" — a misleading error
class, since each one was actually a different real issue, not the same
bug under a new name:

1. **Repeated reassignment of the same variable as both read-source and
   write-target within one loop body** (`nx = mix(nx, ...)` chained four
   times) — first attempt, renamed to staged uniquely-named temporaries
   (`stage1x`...`stage4x`) as the fix.
2. **The staged-temporaries fix still failed**, now on `stage4x` —
   collapsing to a single nested `mix(mix(mix(mix(...))))` expression
   per variable (no intermediate names at all) was the next attempt.
3. **A bare alias assignment** (`ox = zx;`, meant to snapshot the
   pre-update `zx` for use in the `zy` update) **itself threw "not
   defined."** This is the most informative data point of the three —
   it suggests Gen's optimizer may copy-propagate a plain
   variable-to-variable assignment and lose track once its source is
   reassigned later in the same scope, a different failure shape than a
   pure capture-count ceiling (the `f_vf_seeds`/`f_masonry` precedent).
   **Not fully root-caused — worth deeper investigation if this pattern
   recurs**, but the workaround is confirmed: avoid bare aliasing.

**The actual fix, and the real T114 resolution:** parallel
comma-assignment — `zx, zy = <exprX>, <exprY>;` — evaluates both
right-hand sides against the same pre-iteration point before writing
either left-hand side, with **no extra named variable at all**. This
is the GenExpr idiom the `jit-gen-codebox` skill already documents for
built-in multi-value returns (`sum, diff = a+b, a-b;`); confirmed here to
also work for two independently-computed expressions, not just a single
function's paired outputs.

**A fourth, purely logical (not compiler) bug also caught before
shipping**: an intermediate version that assigned `zx = mix(...)` then
`zy = mix(...)` as two separate statements compiled clean but was
*wrong* — the `zy` line's `invertY(zx, zy, ...)` call read the
already-updated `zx`, not the true previous point. Compiling without
error is not the same as being correct — same lesson the Ford-circles
session already logged once this session, now confirmed to generalize
beyond that one construction.

**Checkpoint**: Recognizable closed gasket renders, matching the
reference's bounded character — **PASSED.** `break`/early-exit question
has an actual resolution recorded — **PASSED, branchless confirmed, see
above.** No NaN anywhere in frame, including at non-settled pixels —
**PASSED** (visual scan; dedicated tangent-point probe not done, see
T119 note). All three true — **Phase 1 (redirected) is COMPLETE.**

---

## Phase 2.5: Generalized ring count (maps to plan.md Phase 2.5/ADR-6, spec User Story 2.5) — NEXT UP (2026-07-08)

**Goal**: Replace the hardcoded N=3 ring with a formula-derived,
`ring_count`-parameterized ring (equal-radius, evenly-spaced only — see
spec's Explicitly Deferred for this evolution), bounded by a fixed
`MAX_RING` slot budget.

**Independent Test**: Spec User Story 2.5's Acceptance Scenarios —
`ring_count=3` regresses against T111–T119, other in-range counts each
produce a valid tangent gasket, out-of-range slots are provably inert.

- [ ] T601 Choose initial `MAX_RING` (start at 8, per ADR-6)
- [ ] T602 Implement the tangency formulas (spec FR-101) — `d`, `r` from
      `ring_count`/`R`; per-index center via `cos`/`sin` of
      `2*pi*i/ring_count`
- [ ] T603 Confirm whether a user-defined function can cleanly return
      both center and radius, or whether this needs the parallel
      comma-assignment idiom (ADR-2) instead — record which, and why, in
      plan.md if it differs from the ADR-6 assumption
- [ ] T604 Nest a `for i in 0..MAX_RING-1` ring-candidate loop inside the
      existing gasket-iteration loop; branchless-gate `i >= ring_count`
      slots inert (never win the priority mix chain), per FR-103
- [ ] T605 Compile-check in Max — confirm no console errors before any
      visual verification (capture-ceiling risk flagged in ADR-6/FR-104
      — if it fails, split into a multi-stage `jit.gl.pix` chain rather
      than shrinking `MAX_RING`)
      **— first attempt (nested `for`-over-`k` with a loop-carried
      `res_x`/`res_y` accumulator) failed: `"res_x" is not defined`. A
      different failure shape than any of ADR-2's three — loop-carried
      scalar accumulation across a nested `for`, not a same-statement
      read-after-write. Fix: abandon the inner loop, fully unroll all 8
      ring candidates into one nested-`mix()` expression (same shape as
      T111–T119's proven 4-candidate chain, just bigger).**
      **— second attempt (fully unrolled) compiled clean but produced
      solid black output — a genuine silent failure, not a compile
      error. Root cause (suspected, not yet isolated with a minimal
      repro): the containment flags were named `in0`–`in7`, and `inN`
      (an `in` followed by digits) is GenExpr's actual inlet-reference
      syntax — the parser likely treats any `in`+digit token as an
      inlet reference regardless of whether that inlet exists in this
      codebox (which has none), reading as zero/undefined rather than
      erroring. Logged in `jit-gen-codebox` skill as a new documented
      silent-failure pattern. Fix: rename `in0`–`in7` → `ins0`–`ins7`
      throughout. Retry pending.**
- [ ] T606 Regression check: `ring_count=3` visually matches the existing
      confirmed T111–T119 output
      **— T606 investigation (2026-07-08): Matt flagged the ring_count=3
      render as apparently missing recursive circle-packing — only the
      3 base circles visible, no legible nested smaller circles. Isolated
      via direct side-by-side: pasting the untouched original T111–T119
      codebox (verbatim, no generalization changes) produces the
      IDENTICAL output. This rules out a regression from the Phase 2.5
      generalization work — the issue, if it is one, predates this
      session's changes and is common to both. Root cause identified:
      not a math/packing bug at all — `cos(depth * 0.5 + phase)`
      iteration-depth coloring (T116) has no mechanism to draw circle
      *boundaries*, and its ~12.57-depth-unit color cycle means nested
      circles at different depths can land on visually similar colors.
      The recursive packing is confirmed happening geometrically (the
      inversion math is unchanged and was already confirmed correct);
      it's specifically illegible under this coloring scheme. This was
      always true of the original N=3 hardcoded version too — it was
      never actually visually verified for legible packing, only for
      "recognizable gasket-like character" (T107's original acceptance
      bar was looser than what Matt is now checking for). Open decision:
      improve coloring now (e.g. draw circle-boundary lines via a
      distance field, or discretize depth into visually distinct bands)
      vs. defer legible-packing verification to per-region texture
      sampling (production item #3), which will make circle identity
      visually obvious by construction. Not yet decided — see plan.md.**
- [ ] T607 Sweep `ring_count` across other in-range values (e.g. 4, 5,
      6, up to `MAX_RING`) — confirm each is a correctly-tangent,
      N-fold-symmetric closed gasket, no gaps/overlaps/NaN
- [ ] T608 Confirm slots beyond `ring_count` are inert across a range of
      pixel positions, not just spot-checked at one point
- [ ] T609 (added 2026-07-08, supersedes T601-608's construction) Rebuild
      per ADR-7's corrected formulas: `ringR2=s*s`, `centralR2=(r-s)^2`
      replacing the fabricated `encR2` entirely, ring positions
      `(r*sin(2*i*theta), r*cos(2*i*theta))`, and a sticky `active` flag
      (`active = active * any_inside`) gating position/depth updates so
      escaped points genuinely freeze rather than continuing to be
      inverted through a nonexistent enclosing circle
- [ ] T610 Re-run T606-T608's checks against the corrected construction —
      the old T606 "regress against T111-T119" check is now void (that
      output was wrong); the new correctness bar is "recognizably matches
      the real reference's known character" instead
- [ ] T611 Re-verify no NaN/crash at points near the central circle's
      boundary and at ring-circle tangent points specifically (these are
      exactly where the escape-time character gets most extreme, per the
      real reference's own fractal-boundary behavior)
      **— T609 retry (2026-07-08) hit a compile failure: `"new_zx" is
      not defined`. Likely the capture-ceiling risk FR-104/ADR-6 already
      flagged, now actually landing — the corrected construction needs
      up to 9 candidates (8 ring + 1 central) folded into one
      nested-`mix()` expression, more than double the 4-candidate chain
      (3 ring + 1 fabricated-enclosing) that was the largest thing
      confirmed to compile in this module before. Same failure family as
      the earlier `"res_x" is not defined` error — a giant expression
      silently failing to register, surfacing downstream as "not
      defined" rather than a clear capture-ceiling message. Testing
      cheaply: retry at `MAX_RING=4` (5 total candidates: 4 ring + 1
      central) before committing to a multi-stage `jit.gl.pix` split —
      if 5 candidates compiles and 9 doesn't, that's real evidence of
      where the ceiling sits for this module, informative for the
      split-vs-shrink decision either way.**
      **— Investigation continued via systematic bisection (2026-07-08):
      the capture-ceiling hypothesis was WRONG. Root cause found via
      isolating a minimal repro (static geometry test → single-step
      test → 2-iteration test), not by continuing to guess at the full
      construction: TWO real GenExpr bugs, neither related to
      complexity/ceiling. (1) A variable whose first assignment happens
      inside a `for` block cannot be read after the loop ends — this
      broke `any_inside` (needed for the final color) and would have
      broken `active`/`depth` too; fix is pre-declaring with an initial
      value before the loop. (2) `active` as a variable name silently
      collides (same failure shape as the `inN` collision — clean
      compile, solid black, no error) — suspected to be a reserved
      Jitter/Max attribute name (`@active`); renaming to `alive` fixed
      it immediately with zero other changes. Both logged in the
      `jit-gen-codebox` skill. Confirmed via the fixed 3-circle,
      2-iteration case showing correct recursive packing (visible
      nested smaller circles) for the first time this session — the
      original swirl-without-packing symptom is resolved. Next: scale
      to full 16 iterations, real color output, then reintroduce the
      `MAX_RING`/`ring_count` generalization on top of this now-working
      base.**

**Session paused here (2026-07-08 end of session).** Full next-session
pointer in `HANDOFF.md` at project root — read that first. Short
version: real recursive circle-packing is finally confirmed rendering
correctly (fixed N=3, 16 iterations, real color) after fixing three
distinct GenExpr bugs this session (see the T609 log entries above and
the `jit-gen-codebox` skill for full detail: `inN`-shaped variable names,
variables first assigned inside a `for` loop being unreadable after it,
and `active` as a silently-colliding variable name). Matt's read on the
current render was "almost" matches expected — not a full confirmation,
and the specific gap wasn't identified before the session closed. Next
session should start by pinning down what "almost" means before doing
anything else, not by assuming this is done and moving on to
`ring_count` generalization (T601 onward, still not reintroduced since
the ADR-7 rebuild — currently only fixed N=3 is confirmed).

---

## Phase 3: Iteration count and fps calibration (maps to plan.md Phase 3, spec User Story 3) — LOW PRIORITY, blocked (2026-07-08)

**Do not start this phase next.** Blocked behind spec.md's three
production-scope items, in order: (1) generalized/arbitrary generating
circle configurations, (2) live max-iteration count as a user param, (3)
per-region texture sampling. See the tasks.md status block at top of
this file and plan.md's Phase 3 note for full reasoning.

**Goal**: Choose a shipped default iteration count balancing visual
completeness against the 60fps target.

**Independent Test**: Spec User Story 3's Acceptance Scenarios — fps
measured and recorded at 1920×1080 (and ideally 3840×2160), alongside at
least one other `f_` module.

**Spot-check (2026-07-08, not the full Phase 3 sweep)**: fps read 60+ at
16 iterations, standalone, at the scratch patch's current window
resolution — comfortable headroom, not a marginal result. This confirms
16 iterations is affordable at all, but is **not** a substitute for T301–
T305's full sweep (multiple iteration counts, both target resolutions,
alongside another `f_` module) — those remain open for a future session.

**Second spot-check (2026-07-08, ring+enclosing construction, still not
the full sweep)**: fps read 62+ at 16 iterations, standalone, against
the confirmed T111–T119 ring+enclosing codebox — consistent with the
Ford-circles proof-of-concept's own spot-check margin at the same count.
Deliberately not expanded into the full T301–T305 sweep this session
(explicit call, not an oversight) — the margin here is comfortable
enough that grinding through 4/8/16/32 × both resolutions × alongside
another module didn't feel like the highest-value use of this session,
but that's a scope decision to revisit, not a substitute for actually
doing it. Full sweep remains open for a future session.

- [ ] T301 Sweep the fixed iteration count (try 4, 8, 16, 32) — for each,
      note visual completeness (how much of the frame reads as
      resolved gasket vs. coarse/incomplete)
- [ ] T302 Measure fps at each tested count, standalone, at 1920×1080
- [ ] T303 Measure fps at each tested count, standalone, at 3840×2160
- [ ] T304 Measure fps at the most promising count(s) alongside at least
      one other simultaneously-running `f_` module
- [ ] T305 Choose and record the shipped default iteration count, with
      the reasoning (visual completeness vs. fps tradeoff) — this
      reasoning goes in `HANDOFF.md`/plan.md addendum, not just a bare
      number, per project practice of preserving reasoning for future
      sessions

**Checkpoint**: A specific iteration count is chosen and justified in
writing. 60fps target (NF-002) met at 1920×1080 at the chosen count,
alongside at least one other module.

---

## Phase 4: definition.py + build (maps to plan.md Phase 4)

**Goal**: Confirmed scratch codebox promoted to a production `.maxpat`
via the standard build tool.

- [ ] T401 Write `.specify/f_apollonian/definition.py`: `archetype:
      "generator"`, no inlets, `@type char`, params = iteration count (if
      Phase 3 promoted it to live — otherwise omit, stays a hardcoded
      codebox constant), `inv_x`, `inv_y`, `inv_radius`, `inv_amount`,
      `bypass`
- [ ] T402 Run `tools/build_patcher.py` against `definition.py`
- [ ] T403 JSON-validate: `python3 -c "import json;
      json.load(open('patchers/f_apollonian.maxpat')); print('valid')"`
- [ ] T404 Open in Max — confirm all params appear in UI, respond
      correctly, pix compiles with no console errors
- [ ] T405 Re-run Phase 1–3's checkpoints against the built production
      patcher (not just the scratch patch) — confirm nothing was lost or
      changed in translation to `definition.py`/build

**Checkpoint**: Production `patchers/f_apollonian.maxpat` exists, opens
cleanly in Max, matches confirmed scratch behavior exactly.

---

## Phase 5: Documentation and status update (maps to plan.md Phase 5)

**Goal**: Capture what was learned, without registering the module in the
module menu (deliberately deferred — see plan.md Phase 5 rationale).

- [ ] T501 Write `docs/f-reference/f_apollonian.md` as a working/mechanism
      reference — not a full as-built doc — with GPU Gems/Shadertoy
      attribution per project attribution practice ("adapted from," not
      "used directly" — the fold math is translated, not copied verbatim)
- [ ] T502 Update `ideas/f_apollonian.md`: status, and specifically
      whether ADR-4's non-convergent-pixel prediction held, the chosen
      iteration count, and the ADR-2 `break`/early-exit question's
      still-deferred status
- [ ] T503 Update `HANDOFF.md` with next-session pointers: the
      `f_poincare` relationship decision, the ring+central-circle
      construction as a follow-up build (per plan.md ADR-1's
      "alternatives rejected, not discarded"), and per-region texture
      sampling as the next real evolution
- [ ] T504 Git commit (Matt pushes manually, per standing practice)

**Checkpoint**: Docs and idea file accurately reflect what was actually
built and confirmed — not what was originally planned, where the two
differ.

---

## Dependencies & Execution Order

### Phase Dependencies
Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5. Strictly sequential —
each phase's checkpoint gates the next. No `definition.py` (Phase 4) work
starts before Phase 1–3 are confirmed in Max, per the project's standing
"scratch-test before production" practice.

### Within Each Phase
- Phase 1: T101 → T102 → T103 → T104 → T105 → T106 → T107/T108 (the last
  two can run in either order once T106 passes)
- Phase 2: T201/T202 must complete before T203; T204 before T205
- Phase 3: T301 before T302/T303 (need candidate counts before measuring);
  T304 after at least one count is confirmed promising from T302/T303;
  T305 last
- Phase 4: strictly sequential, T401 → T402 → T403 → T404 → T405
- Phase 5: T501/T502/T503 can happen in any order; T504 last

### Parallel Opportunities
None marked — this is a single-threaded scratch-test-then-build sequence
by nature (one codebox, one person, one Max instance), unlike a
multi-file software project. Every task in this plan touches the same
codebox or the same handful of docs, so parallelization would just create
merge conflicts with yourself.

---

## Implementation Strategy

**Scratch-first, always.** Phases 1–3 happen entirely in
`~/Vsynth/patterns/apollonian-scratch.maxpat`, never in `patchers/`. Only
Phase 4 touches version-controlled production files, and only after every
Phase 1–3 checkpoint has passed in Max — not just JSON-validated.

**Stop and reassess if ADR-1 or ADR-4 turn out wrong.** If Phase 1 (T107/
T108) shows the Ford-circles construction doesn't read as a recognizable
gasket, or does produce NaNs despite ADR-4's prediction, stop before Phase
2 — that's a plan.md-level finding, not a tasks-level bug, and may need an
ADR addendum before continuing.

---

## Notes

- No `[P]` parallel markers used — see Parallel Opportunities above for
  why
- No `[US#]` labels — this tasks list maps 1:1 to plan.md's five phases,
  which already correspond to spec.md's user stories in sequence (Phase 1
  → US1, Phase 2 → US2, Phase 3 → US3); restating the mapping per-task
  would be redundant given the phase headers already state it
- Commit at T504 only — this is a single build with no natural
  incremental-delivery seams before then (unlike, say, `f_vf_seeds`'
  Evolution 1/1.5/2 structure, which had real standalone shippable
  points)
