# Tasks: f_apollonian

**Spec**: `.specify/f_apollonian/spec.md`
**Plan**: `.specify/f_apollonian/plan.md`
**Build order**: Sequential. Complete each phase before the next — no
skipping ahead to Phase 4 (`definition.py`) before Phase 1–3 are confirmed
in Max, per standing practice (scratch-test before production).

**Status (2026-07-08)**: Phase 1–2 below (Ford circles construction) are
complete and confirmed as a **proof-of-concept** — see the finding at the
end of the original Phase 1 section. Per `plan.md`'s ADR-1/ADR-2
supersession notes, scope has been **redirected to the ring +
central-circle construction** (the classical closed gasket). A new
"Phase 1 (redirected)" section below starts that work fresh — the
original Phase 1–2 sections are kept intact below as the historical
record of what was proven and how, not deleted.

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

- [ ] T111 Reuse `apollonian-scratch.maxpat`, same `vs_render`/wiring
      pattern as T101 — no new scratch patch needed
- [ ] T112 Reuse the confirmed `invertX`/`invertY` shared functions
      unchanged (per plan.md's carry-forward note) — no need to
      re-derive the guarded-inversion math
- [ ] T113 Write the N=3 ring + central-circle candidate geometry: one
      central circle plus N ring circles at fixed angular positions
      around it, per the `ebanflo`-derived reference's `gasket()`
      function
- [ ] T114 Decide and implement the `break`/early-exit resolution per
      `plan.md` ADR-2's supersession note — attempt the branchless
      `settled`-flag approach first (run every candidate check
      unconditionally, gate the inversion's effect via a flag rather than
      exiting the loop); only fall back to testing `break` directly if
      the branchless version proves awkward to get correct
- [ ] T115 Write the fixed-count outer loop (start at whatever count the
      Ford-circles proof-of-concept settled on, 16, as a starting guess —
      this construction's convergence behavior is genuinely different
      and may need a different count) with the inner per-candidate
      containment test from T113/T114
- [ ] T116 Write output coloring — start with iteration-depth coloring
      (per the reference's HSV-by-depth approach) rather than the
      Ford-circles line-draw distance field, since this construction's
      natural output is "which iteration did this pixel settle at," not
      a two-line distance field
- [ ] T117 Paste into Max, confirm compiles with no console errors
- [ ] T118 Visually compare against the `ebanflo`-derived reference's
      character — four mutually tangent circles at the base level, nested
      self-similar circles filling gaps, bounded within a visible outer
      structure (not an infinite strip)
- [ ] T119 Scan the frame for NaN/undefined regions — this construction
      has a genuine escape-time termination character (unlike Ford
      circles), so this check is more load-bearing here than it was in
      the original T108 (per spec's revised Acceptance Scenario 2) —
      specifically check what non-settled pixels (max-iteration reached)
      actually show

**Checkpoint**: Recognizable closed gasket renders, matching the
reference's bounded character. `break`/early-exit question has an actual
resolution recorded (not deferred again). No NaN anywhere in frame,
including at non-settled pixels. Do not proceed to a redirected Phase 2
(reusing T201-style animated-inversion work against this new construction)
until all three are true.

---

## Phase 3: Iteration count and fps calibration (maps to plan.md Phase 3, spec User Story 3)

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
