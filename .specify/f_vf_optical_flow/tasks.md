# Tasks: f_vf_optical_flow

**Spec**: `.specify/f_vf_optical_flow/spec.md`
**Plan**: `.specify/f_vf_optical_flow/plan.md`
**Build order**: Sequential. Complete each phase before the next.
**Commits**: After each phase checkpoint.

---

## Expected Output Layout

```
patchers/
  f_vf_optical_flow.maxpat        — built by build script from definition.py

.specify/f_vf_optical_flow/
  spec.md                         — done
  plan.md                         — done
  tasks.md                        — this file
  definition.py                   — authored in Phase 3
  codebox_stage_a.gen             — authored in Phase 0
  codebox_stage_b.gen             — authored in Phase 1
  codebox_stage_c.gen             — authored in Phase 2

docs/f-reference/
  f_vf_optical_flow.md            — as-built reference (Phase 5)

~/Vsynth/patterns/
  optical_flow_scratch.maxpat     — scratch patch for Phases 0-2 (not committed)
```

---

## Phase 0: Stage A scratch test — gradients + temporal diff (BLOCKING)

**Purpose:** De-risk the mechanical part before building the genuinely
new windowed-sum machinery. Reuses only already-confirmed techniques.

⚠️ Do not begin Phase 1 (Stage B) until this checkpoint is confirmed.

- [ ] T001 Open scratch patch at `~/Vsynth/patterns/optical_flow_scratch.maxpat`
- [ ] T002 Build 2-pix feedback pair: `pass_pix` (identity) + `stage_a_pix` (primary), same shape as `f_vf_advect`'s `state`/`pass` pattern
- [ ] T003 **DECISION GATE:** decide `Ix`/`Iy` gradient source — current-frame-only central difference, or averaged current+previous (Horn-Schunck-style noise reduction). Per spec.md Phase 0, decide this empirically once Stage A is running and visible, not by assumption beforehand. Document the choice and why here before moving to T004.
- [ ] T004 Write `codebox_stage_a.gen`: compute `Ix`, `Iy` (central difference, per decision in T003) and `It` (`current - previous`)
- [ ] T005 Confirm Stage A renders standing alone, no GL errors
- [ ] T006 Wire each of `Ix`/`Iy`/`It` individually to a preview; confirm each visibly responds to motion in a live or played-back source (not all-zero, not garbage)
- [ ] T007 Confirm the previous-frame feedback loop behaves correctly via draw order (same mechanism as `f_vf_advect`, already confirmed working there — verify it holds here too, don't assume it transfers automatically)

**Checkpoint:** Stage A confirmed working standalone — gradients and temporal diff all visibly correct. → Proceed to Phase 1.

---

## Phase 1: Windowed sum — Stage B (BLOCKING)

**Purpose:** Build the one genuinely new technique in this module. Highest risk phase for the GL2→GL3 capture-group ceiling.

⚠️ Do not begin Phase 2 (Stage C) until this checkpoint is confirmed.

- [ ] T008 Write `codebox_stage_b.gen`: 5×5 windowed accumulation of `Ix²`, `Iy²`, `IxIy`, `IxIt`, `IyIt` from Stage A's output
- [ ] T009 **DECISION GATE:** decide channel packing for the five accumulator outputs — how many output textures, which sums go in which channels. Not yet decided as of spec.md; resolve here before finalizing the codebox's `out1`/`out2`/etc. structure.
- [ ] T010 Compile and render at 5×5. **If the GL2→GL3 capture-group ceiling bites** (params gray out, pix goes invalid): split into smaller sub-stages per `jit-gen-codebox` skill's documented approach — do not attempt to hand-optimize the math first. Note here which happened.
- [ ] T011 Build a simple test pattern (e.g. a hard vertical edge moving horizontally) with a predictable, manually-computable expected signature
- [ ] T012 Spot-check the five sums against the manual expectation from T011 — confirm they're in the right ballpark and have the right dominant-term signature, not just "some nonzero values"

**Checkpoint:** Stage B confirmed working, ceiling risk resolved one way or the other, sums spot-checked against a known test case. → Proceed to Phase 2.

---

## Phase 2: Solve + confidence — Stage C (BLOCKING)

**Purpose:** Closed-form solve for velocity, plus the confidence signal that makes the aperture problem visible rather than silently contaminating downstream consumers.

⚠️ Do not begin Phase 3 (definition.py) until this checkpoint is confirmed.

- [ ] T013 Write `codebox_stage_c.gen`: closed-form 2×2 linear solve (Cramer's rule) for `(u,v)` from Stage B's five sums
- [ ] T014 Add matrix-determinant computation as a second output (confidence signal)
- [ ] T015 Confirm `(u,v)` output loads into `f_vf_fieldmap`'s expected vecfield format with no adapter needed (standard `f_vf_` x/y-as-RG convention)
- [ ] T016 Build/reuse a flat, textureless test region and a textured/edge-rich test region; confirm confidence output is visibly near-zero in the flat region and visibly higher in the textured region
- [ ] T017 **DECISION GATE:** check the raw determinant value range empirically before deciding on any normalization/clamping — per spec.md Phase 2, don't remap in a way that loses the zero-crossing meaning without first knowing what range you're actually working with

**Checkpoint:** Both outlets (vecfield + confidence) confirmed correct against real test patterns, not just "compiles." → Proceed to Phase 3.

---

## Phase 3: definition.py and Build

**Purpose:** Assemble the three confirmed stage codeboxes plus the previous-frame pass pix into a real `pix_chain` bpatcher.

- [ ] T018 Write `.specify/f_vf_optical_flow/definition.py` using `pix_chain`/`pix_wires` — 4 nodes: `pass_pix`, `stage_a_pix`, `stage_b_pix`, `stage_c_pix` (primary)
- [ ] T019 **DECISION GATE:** check whether `build_patcher.py`'s `outlets` mechanism already supports a non-`jit_gl_texture` outlettype for the scalar confidence outlet (per plan.md Block 3), or whether this itself needs a small schema check/extension before assuming it just works
- [ ] T020 Define standard Vsynth wrapper: routepass, autopattr, bypass toggle, moduleSize.js
- [ ] T021 Run build script per current `build_patcher.py` invocation convention (check usage directly, don't assume the same invocation as older custom build scripts)
- [ ] T022 Validate JSON: `python3 -c "import json; json.load(open('patchers/f_vf_optical_flow.maxpat'))"` — must pass with no errors

**Checkpoint:** Valid `f_vf_optical_flow.maxpat` generated. → Proceed to Phase 4.

---

## Phase 4: Real-Consumer Wiring and Expressive Verification

**Purpose:** Answer the question the whole module exists to answer — does this produce expressively useful flow, not just numerically plausible output. This is the phase most likely to reveal the module isn't done yet, even if everything above passed.

- [ ] T023 Open in Vsynth; wire `(u,v)` output into `f_vf_warp` (recommended per spec.md for legibility)
- [ ] T024 With a live or played-back moving source, judge by eye: does the resulting warp read as coherent motion-following, the way the ruled-out frame-diff approach explicitly did not?
- [ ] T025 Test with fast motion specifically — confirm/deny the expected single-scale LK failure mode (breaks down on large frame-to-frame displacement). Document the finding concretely either way — don't silently declare the module done if this limitation shows up as expected; that's the known trigger for the pyramid upgrade (out of scope for this build, per spec.md).
- [ ] T026 Test confidence outlet in a real (non-synthetic-test-pattern) scene — confirm it's still doing something sensible, not just correct on the synthetic test cases from Phase 2

**Checkpoint:** Real expressive verification complete, with an honest answer either way — including if the answer is "single-scale isn't enough, pyramid is the real next step."

---

## Phase 5: Docs and Registration

**Purpose:** Update permanent project records. Nothing here until Phase 4 checkpoint is confirmed.

- [ ] T027 Write `docs/f-reference/f_vf_optical_flow.md` — as-built reference: params, both outlets explained (vecfield + confidence), signal chain summary, single-scale limitation noted honestly
- [ ] T028 Update `README.md` bpatcher table
- [ ] T029 Add to appropriate category in `.specify/f_modules/build_modules.py` (likely alongside other `f_vf_` vecfield producers — check existing category conventions, e.g. "∇ Generators")
- [ ] T030 Add size entry to `SIZES` dict in `javascript/f_addmod.js`
- [ ] T031 Regenerate `patchers/f_modules.maxpat`; validate JSON
- [ ] T032 Write `.maxhelp` file per `f-helpfile` skill conventions
- [ ] T033 Update `HANDOFF.md`

**Checkpoint:** Ready to commit.

---

## Dependencies

**Phase dependencies (strict):**
- Phase 0 → Phase 1: Stage A confirmed before building Stage B's windowed sum on top of it
- Phase 1 → Phase 2: Stage B's sums confirmed correct before solving from them
- Phase 2 → Phase 3: both stage-C outlets confirmed against real test patterns before assembling the full `pix_chain`
- Phase 3 → Phase 4: valid patcher before real-consumer testing
- Phase 4 → Phase 5: expressive verification (including honest documentation of single-scale limits) before docs/registration

**No cross-phase parallelism** — each gate exists specifically because this module has more genuinely untested territory (the windowed-sum stage) than most modules in this library.

---

## Notes

- Three explicit decision gates are embedded in this task list (T003, T009, T017, T019) rather than left as spec.md prose, per the project's convention of putting outstanding architecture/design decisions into `tasks.md` as real to-do items when they exist for a module.
- The most likely point of real difficulty is T010 (5×5 ceiling risk) — treat a ceiling hit as an expected possible outcome with a known response (split further), not a surprise requiring re-architecture.
- T025 is the task most likely to produce an honest "not fully done" result even after everything else passes — that's expected given ADR-3's deliberate single-scale-only scope, not a sign something went wrong.
