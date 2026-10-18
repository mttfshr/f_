# Tasks: f_tf_axisflow

_Created: 2026-10-16_

## Phase 0: mirror
- [x] T001 `tests/test_tf_axisflow.py`: projection mirror + brute-force atan2 reference.
- [x] T002 Properties: θ→θ+π invariance, |v| = |cos(θ−φ)|, along + across = r.
- [x] T003 Edge cases: iso → neutral, black input → neutral, gain clamp, `gate` 0/1.
- [x] T004 Aspect: identity on square; pixel direction preserved on 16:9 and 9:16.
- [x] T005 Chain with the tensormap mirror on stripes and ramps; mutation test (sign flip).
- [x] T006 Add to `tests/run.sh` set; green.

## Phase 1: codebox + bench
- [x] T007 `src/f_tf_axisflow/codebox_axisflow.gen` from the plan sketch.
- [x] T008 `tests/bench_tf_axisflow.py` + `benchdeps.py` entry (ask Matt before running; bench.maxpat open).
- [x] T009 Bench: parity vs mirror incl. iso, black, aspect, bypass_gate.

## Phase 2: scratch patch (judgement)
- [~] T010 (skipped 2026-10-16: the module itself is the live test) Scratch patch tensormap → axisflow → `f_vf_advect`, noise source.
- [ ] T011 Matt: sweep `angle`, `gate`, `mode`; confirm no seam; decide defaults and `normalize`.

## Phase 3: module
- [x] T012 `definition.py` (processor, bypass_mode param, 6 controls + bypass, menu for mode).
- [x] T013 Build, register in `menu.py`, README row (≤110 chars), regenerate menu/launcher.
- [x] T014 BYPASS_EXPECT entry (const 0.5,0.5,0.5,1); contract tests; bench_modules clean.
- [ ] T015 Matt: load in Max (T036 equivalent), panel width fits the controls.

## Phase 4: docs
- [x] T016 `docs/f-reference/f_tf_axisflow.md`; helpfile + module-preflight.
- [x] T017 Hub doc: exclusion list points at the bridge; consumer table; HANDOFF entry.
- [x] T018 Naming entry for `f_tf_` in README/constitution (shared with tensormap T042).
- [ ] T019 Commit only f_tf_* files (Matt commits; suggest message).

## Phase 5: signed gain + per-pixel reference inlet (2026-10-17)
Why: Axis Flow's flow always has a component along `angle` (mean 0.5 x gain over random edges), and
`f_vf_fluid` accumulates that mean flow (only `drag` damps k=0), so chains drift one way; Matt also wants
negative gain in performance. Decisions (Matt): gain range -4..4; reference inlet unnormalized, `angle`
rotates it, unconnected = old behaviour; title-bar label left as `T_ in ∇ out`.
- [x] T020 Signed `gain` (-4..4, default 1): definition range + hint; codebox already unclamped.
- [x] T021 Reference inlet: `mod_inlets` (vs_instate False) -> codebox `in2`; B-gate (|B-0.5|<0.25) absent test;
  pixel-space decode; `angle` rotates. Codebox + mirror `axisflow(ref=...)` in step; patcher rebuilt (pix has 2 inlets).
- [x] T022 Mirror tests: 16 -> 24 (negative gain, constant ref == dial, angle rotates ref, magnitude scales, absent ref
  falls back, per-pixel brute force, seamlessness bound, 16:9 pass-through). `tests/run.sh -q tests/test_tf_axisflow.py` 24/24.
- [x] T023 (bench 9/9, 2026-10-17; the sample() tolerance worry did not materialise) Bench: cases written (negative gain, reference inlet, black ref == dial, 16:9 reference); `run_case` now feeds
  in2. NOT RUN: ask Matt (bench.maxpat open). One open point: in2 uses `sample()` (bilinear, so a lower-res fluid
  output reads smoothly); same-size bench inputs should be exact, but if TOL 2e-5 fails check 8-bit sample weights first.
- [ ] T024 Full offline suite once (`tests/run.sh -q`): the rebuild touched only f_tf_axisflow, but the contract /
  drift / conventions tests have not been re-run since.
- [ ] T025 Helpfile: only the `gain` range was corrected (0-10 -> -4..4); text for the second inlet and the
  reference behaviour is not written (generated in-session; judgement gate is Matt's).
- [ ] T026 Matt: load in Max; the panel width (154) is unchanged, check the new inlet position and the cable to it.
- [ ] T027 Matt live: tensormap -> axisflow (ref = f_vf_vortex) -> f_vf_fluid; sweep `angle`, negative gain.
- Related, not built: f_caustic `edge` mode (off / wrap / mirror / clamp, vertex-shader) and an optional f_vf_fluid
  `drift` Param scaling the k=0 bin. Both proposed 2026-10-17, neither approved to build yet.

## Notes (2026-10-16)
- Mirror 16/16 (`tests/test_tf_axisflow.py`); bench 5/5 (`tests/bench_tf_axisflow.py`); contract/bench_expect/launch/benchdeps green; bench_modules shows f_tf_axisflow clean (its only failure is the 4 pre-existing f_a_decorrelate errors).
- Spec correction found while writing the mirror: the tensormap theta is the across-edge gradient axis, so "along" is the complement projector (|v_along| = |sin(theta-phi)|). Design sketch had these swapped; spec/plan fixed.
- GenExpr gotcha: `phi` is a predefined constant; assigning it fails the whole compile ("can't assign to predefined constant"). Codebox uses `ref_ang`.
- Panel is 150x100 for six controls; layout unverified until T015 (the tensormap panel needed widening).
