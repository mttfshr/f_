# Tasks: f_tf_sharpen

**Spec**: `.specify/f_tf_sharpen/spec.md`
**Plan**: `.specify/f_tf_sharpen/plan.md`
**Brief**: `ideas/f_tf_build_brief.md` §4; **triage**: `ideas/f_tf_triage.md`
**Build order**: After `f_tf_smooth` ships (confirmed order: smooth → glyph → sharpen).
**Commits**: After each phase checkpoint.
**Test discipline**: one affected test, `-q`, background via `tests/bg.sh`; never rerun
the bench to re-verify; **ask before any bench run**.

---

## Expected Output Layout

```
.specify/f_tf_sharpen/
  spec.md  plan.md  tasks.md      — triad
  codebox_sharpen.gen             — Phase 1
  definition.py                   — Phase 3

tests/
  test_tf_sharpen.py              — Phase 0, tier-1 mirror
  bench_tf_sharpen.py             — Phase 1, tier-2

~/Vsynth/patterns/tf_sharpen_scratch.maxpat — Phase 2 (not committed)

docs/f-reference/f_tf_sharpen.md — Phase 5
```

---

## Phase 0: Gates + NumPy mirror (BLOCKING)

⚠️ Do not begin Phase 1 until this checkpoint is confirmed.

- [x] T001 **DECISION GATE: verification tiers.** Plan ADR-5: tier 1 (eigh ground truth),
  tier 2 (GPU round-trip), tier 3 (dial mapping feel). Confirm or amend.
  *Confirmed 2026-10-17, no amendment: all three apply. The owner constraint (no live
  bench / no scratch session this pass) leaves tier 1 green and tier 2/3 pending — see
  Phase 1/2 tasks.*
- [x] T002 *[done 2026-10-17]* Write `tests/modules/tf_sharpen/test_tf_sharpen.py`: decode mirror (f_tensor out0 contract decode,
  parametrized on strength), closed-form eigen, gap op per plan ADR-2 (`g = max(γ,0)`),
  re-encode. One function, ground truth via `np.linalg.eigh` on random symmetric
  matrices (include near-isotropic and diagonal-only cases, per tensormap T006 pattern).
  Mirror operates directly on the strength-scaled encoded components (plan ADR-4); eigh
  ground truth agrees to 1.8e-7 over random SPD/near-isotropic/diagonal/near-line cases.
- [x] T003 *[done 2026-10-17: worst 1.2e-7 unclamped across γ ∈ {0,0.25,0.5,1,2,4}]* Trace invariance test: trace(γ) == trace for γ ∈ {0, 0.25, 0.5, 1, 2, 4} to
  float32 tolerance. **Finding:** this test caught a sign slip in the spec's own prose —
  `λ2' = trace/2 − gap·(λ2 − trace/2)` yields λ1'==λ2' at every γ≠1 and breaks trace
  invariance; the trace-preserving form (which plan ADR-2's component-space mix reduces
  to) is `λ2' = trace/2 + gap·(λ2 − trace/2)`, same PLUS sign for both eigenvalues.
  Spec corrected via REGISTRATION_NOTES row (owner constraint: shared-file edits go there);
  mirror docstring states the corrected algebra with the citation.
- [x] T004 *[done 2026-10-17: (cos2θ,sin2θ) unchanged, 1.2e-6, γ ∈ {0.25..4}, measured pre-encode-clamp]* Axis invariance test: recovered axis (mod π) unchanged for all γ including the
  isotropic endpoint (γ=0 outputs the neutral axis per the eps_trace convention). γ=0
  gives the exact isotropic tensor (G out == 0.5 bitwise, both eigenvalues trace/2, 0.0e0).
  NOTE: post-encode-clamp saturation (λ' > 1 or λ2' < 0 at extreme γ) distorts the
  axis identity — the invariant is a property of the linear (pre-clamp) math, which is
  what the codebox computes before its final-stage encode; tests measure there.
- [x] T005 *[done 2026-10-17: 3.6e-7 / 0.0 / 1.5e-7]* Coherence mapping test: γ=2 on a coherence-0.5 tensor gives 1.0; γ=0 gives 0;
  γ=0.5 gives 0.25 (linear in the gap — measured, not assumed). Linear confirmed.
- [x] T006 *[done 2026-10-17: no labeled swap, 0.0e0, for every γ in 0..4]* **No-swap-on-relax test (ADR-2, the correctness hazard):** for every γ in the
  candidate dial range, λ1' ≥ λ2' holds (no eigenvalue swap → no 90° axis flip), and
  γ=0 gives exactly the isotropic tensor (both λ = trace/2). Implementation note: the
  check uses labeled Rayleigh quotients along the input's major/perpendicular axes —
  a plain eigh sort cannot detect a swap (it sorts), so the obvious implementation of
  this test is vacuous; the mutation check (T009a) relies on the same labeled form.
- [x] T007 *[done 2026-10-17: relative disagreement 2.9e-7 at k ∈ {1,10,1000}; floor-gate break measured at the exact analytic delta 2.0e-6]* Scale-commutation test (ADR-4): the operator commutes with a uniform scale
  factor on the input (eigen ratios are scale-free except the floor gate); verify on
  tensors scaled by 1, 10, 1000. Floor behavior recorded in spec Notes (T008).
- [x] T008 *[decision recorded 2026-10-17, see T003/T007 rows]* **DECISION GATE: floor semantics with strength.** Given ADR-4 (floor eps is an
  absolute pre-gain trace threshold), record in the spec Notes the exact floor behavior
  as a function of the producing tensormap's `strength`. Fixed internal eps per ADR-3 —
  not a dial. Recorded: eps_trace = 1e-6 lives in **encoded units** (post-strength),
  so the effective pre-gain floor is eps/strength — with tensormap's default 100,
  structure below pre-gain trace 1e-8 passes through untouched; floor bites 100× deeper
  at strength 1. The non-commutation is measured, not assumed: sharpen(k·T) == k·sharpen(T)
  to 2.9e-7 where both sides are above floor; a sub-floor tensor scaled by 1000 escapes
  the floor by exactly the analytic delta k·|γ−1|·trace/2 = 2.0e-6 (asserted in-mirror).
  Caveat belongs in the reference doc (owner constraint: reference doc is ours).
- [x] T009 *[done 2026-10-17: (a) drop_max caught 0.3 (b−a label swap); (b) gap-swap caught 0.34 axis rotation; both mutants fail the suite]* Mutation checks: (a) drop `max(γ,0)` → T006 fails; (b) gap sign error → T003
  or T004 fails. One is enough per tests/README if both are cheap. Both included;
  T006's labeled-Rayleigh check (see its row) is what makes (a) detectable at all.
- [x] T010 *[done 2026-10-17: `tests/run.sh tests/modules/tf_sharpen/test_tf_sharpen.py -q` → ok 15/15; errors ~1e-7 class except T006's bitwise 0; both mutations caught]* Run `tests/run.sh tests/modules/tf_sharpen/test_tf_sharpen.py -q` in background; record errors.

**Checkpoint:** mirror clean, no-swap hazard guarded, scale behavior recorded.
→ Phase 1.

---

## Phase 1: Codebox on the bench (BLOCKING)

⚠️ **Ask before the bench run.**

- [x] T011 *[written 2026-10-17; never executed (owner constraint)]* Write `codebox_sharpen.gen`: single pass; decode → eigen → gap+floorgate →
  re-encode; `Param sharpen` (γ); `Param bypass`. **No atan2 anywhere** — the eigen
  decode of the raw components needs only sqrt/atan2-free closed forms plus the axis
  re-encoding via the unchanged components. Plan Block 2 finding to verify, not assume.
  Written, ~30 GenExpr statements (budget trivial, order of magnitude under the ~450
  capture ceiling). Decode idiom copied verbatim from `.specify/f_tf_glyph/plan.md`
  ADR-2 with citation (strength division dropped per plan ADR-4 with in-code reason:
  the operator is positively homogeneous in the components — mirror T007). No atan2 by
  construction; the idiom's closed-form component math is the whole decode. Provisional
  gates visible in comments (OQ1 dial mapping, OQ4 name, strength/floor caveat).
- [x] T012 *[BENCHED 2026-10-17 (M3 Max), ask-approved: 6/6 pass, re-confirmed in the final
  5-file sweep. Two bench-file bugs found and fixed while running (the module was unaffected):
  (a) the fixtures encoded at strength 100, blowing out the outlet-0 contract's own clamp
  (R = clamp(Jxx*strength, 0, 1)) — the gamma-1 comparison measured the contract's clamp, not
  the operator; fixtures now encode at strength 1.0 (gain-commutation stays T007's row);
  (b) the iso/vs_black passthrough copied the raw block's alpha 0 while the codebox encodes
  its outlet with the contractual A=1 — the mirror now writes alpha 1 at the passthrough and
  the tests compare rgb + alpha-vs-contract separately. Round-trip at gamma=1: rgb exact
  (1e-6 tol), alpha = 1 everywhere; no-axis-flip held at every gamma on the GPU; floor rows
  untouched at gamma in {0, 4}; cost recorded at chain 8: 1080p/4k upper bounds logged in
  tests/modules/tf_sharpen/bench_tf_sharpen.py test_cost (no loop, one tap — the PROVISIONAL-OPEN cost gate's
  number is in).]* Bench vs mirror with `all_outputs=True` at gamma in {0, 0.5, 1, 2, 4} on
  synthetic tensor textures (flat, single edge, noise). Record gamma=1 round-trip error
  explicitly. `tests/modules/tf_sharpen/bench_tf_sharpen.py` written (parity, floor, invariants rows).
- [x] T013 [BENCHED 2026-10-17, same run: floor rows pass — trace below eps → output == input
  exactly, at every gamma; the vs blocks untouched at gamma 4.]
- [x] T014 *[exact entry supplied in .specify/f_tf_sharpen/REGISTRATION_NOTES.md (owner-only file, not edited here); glob existence verified against the enforced test]* Register `tests/modules/tf_sharpen/bench_tf_sharpen.py` in `tests/lib/benchdeps.DATA`; not DEFAULT
  until Matt says regression gate.

**Checkpoint:** GPU parity recorded including the round-trip number. → Phase 2.

---

## Phase 2: Scratch patch, judgment tier

*OUT OF SCOPE this pass (owner constraint 2026-10-17): no live Max session. All three
gates stay open; shipped provisional values recorded in their task rows.*

- [ ] T015 *[PENDING MATT — scratch never built]* Build `~/Vsynth/patterns/tf_sharpen_scratch.maxpat`: tensormap → [smooth, if
  built] → sharpen → decode/glyph-style preview.
- [ ] T016 *[PENDING MATT — DECISION GATE OPEN; shipped provisionally one-sided linear 0–4, default 1.0 (spec OQ1); definition.py + codebox comments carry the provisional flag]* **DECISION GATE: dial mapping (spec OQ1).** Feel one-sided 0–4 vs bipolar
  −2→+2 mapped through ADR-2's form. Matt's pick recorded; spec Parameters updated.
- [ ] T017 *[PENDING MATT — DECISION GATE OPEN; name stays `f_tf_sharpen`, PROVISIONAL flag in REGISTRATION_NOTES: a future rename is one find-replace before live shipping]* **DECISION GATE: name (spec OQ4).** `f_tf_sharpen` vs `f_tf_eigengap`/
  `f_tf_aniso`. If renamed: spec, plan, tasks, codebox names, directory all change here —
  cheap now, expensive after definition.py exists.
- [ ] T018 *[PENDING MATT — live comparison]* Confirm the build-order rationale live: sharpen on raw tensor vs sharpen on
  smoothed tensor (flicker amplification visible; the triage's sequencing claim).
  Photograph/record the observation in this file's notes.

**Checkpoint:** dial mapping + name locked; sequencing rationale demonstrated. → Phase 3.

---

## Phase 3: definition.py and build

- [x] T019 *[written 2026-10-17]* Write `definition.py`: single-node pix (plan ADR-1), params `sharpen` (locked
  mapping from T016), `bypass`. If a rename happened at T017, use it everywhere here.
  Name stays `f_tf_sharpen` (T017 gate open, PROVISIONAL flag in REGISTRATION_NOTES);
  dial mapping ships the provisional one-sided 0–4 default 1.0 (T016 gate open);
  `floor` is not a param (plan ADR-3). `pix_target` omitted → defaults to the primary
  pix; single outlet, `signal_type "tensor out"` with the tensormap T030 amber.
- [x] T020 *[built 2026-10-17: `python3 build/build_patcher.py .specify/f_tf_sharpen/definition.py` from repo root → package/patchers/f_tf_sharpen.maxpat written; `json.load` → VALID. One build fix: `pix_target` must be a node id (the builder rejects a bare index); omitted it instead — single-pix default wiring]* Build via build_patcher.py (confirm invocation from tensormap T032 first);
  validate JSON. Note: the definition lives in `.specify/` (this module's layout per
  plan "Files"), not `src/` — build_patcher resolves relative codebox paths against the
  definition's own directory either way; the tasks prose's 'src/' is tensormap's layout.
- [ ] T021 *[PENDING PARENT — menu registration is a shared-file edit; exact content in REGISTRATION_NOTES]* Menu registration (`build/generate_menu.py`; note placement, taste call).
- [ ] T022 *[PENDING PARENT — needs the module in the drift harness; definition + built patcher are ready. Offline sanity done: the build reproduced from the definition it was just built from; `tests/build/test_drift.py` run is the parent's]* Drift check: reproduces from definition.py; baseline untouched.
- [ ] T023 *[PENDING PARENT — BYPASS_EXPECT entry content supplied in REGISTRATION_NOTES; running the contract tests registers the module first]* Contract tests offline; BYPASS_EXPECT passthrough entry; bench registration
  per T014. **Ask before any bench run.**
- [ ] T024 *[PENDING MATT — live session]* Close/reopen in Max; load in Vsynth; panel/params/neutrals confirmed (Matt).

**Checkpoint:** loads, drift-clean, contracts green. → Phase 4.

---

## Phase 4: Integration (chain A assembled)

*OUT OF SCOPE this pass (owner constraint): no live session.*

- [ ] T025 *[PENDING MATT — live integration]* Wire tensormap → smooth → sharpen → preview (glyph/aniso_blur if their
  patchers exist; else the decode preview). Confirm the gesture end-to-end live.
- [ ] T026 *[PENDING — shared file (ideas/f_tf_build_brief.md is the parent's)]* Update `ideas/f_tf_build_brief.md` chain A entry to the built modules.

## Phase 5: Docs and handoff

- [x] T027 *[written 2026-10-17: docs/f-reference/f_tf_sharpen.md, "Status: Draft — codebox tier-2 bench and tier-3 live judgment pending", tensormap doc structure mirrored; carries the gap math, no-axis-flip guarantee, strength/floor table, linearity/clamp section, no-atan2 note, name-provisional note]* `docs/f-reference/f_tf_sharpen.md` (or renamed): params, the gap math, the
  no-axis-flip guarantee, the strength-floor caveat, "no atan2 needed" implementation note.
- [ ] T028 *[PENDING PARENT — rows' content supplied in REGISTRATION_NOTES (menu.py, README, module-inventory, HANDOFF are shared)]* module-inventory row, README row, HANDOFF.
- [ ] T029 *[PENDING — no commits by constraint]* Commit. Suggested split: triad; tests + codebox; patcher + registration; docs.

---

## Dependencies & Execution Order

- Phase 0 → 1 → 2 → 3 → 4 → 5, sequential.
- After T017 (possible rename), all subsequent artifacts use the final name.
- **Module-level prerequisite:** `f_tf_smooth` built (Phase 4 integration and the T018
  comparison need it; the module itself is independent).

## Notes

- The correct relax form (ADR-2) is the one piece of real math: a naive negative gap
  silently rotates axes by 90°. T006 guards it forever.
- No atan2 in the codebox: the decode happens on the raw components via closed-form
  eigenvalues only. The axis rides through in component space. Verify at T011 rather than
  discovering an accidental atan2 at review.
- Hard constraint: no script in this task list calls the Anthropic API.
- Total tasks: 29.