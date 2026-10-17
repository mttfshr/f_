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
- [ ] T016 `docs/f-reference/f_tf_axisflow.md`; helpfile + module-preflight.
- [ ] T017 Hub doc: exclusion list points at the bridge; consumer table; HANDOFF entry.
- [ ] T018 Naming entry for `f_tf_` in README/constitution (shared with tensormap T042).
- [ ] T019 Commit only f_tf_* files (Matt commits; suggest message).

## Notes (2026-10-16)
- Mirror 16/16 (`tests/test_tf_axisflow.py`); bench 5/5 (`tests/bench_tf_axisflow.py`); contract/bench_expect/launch/benchdeps green; bench_modules shows f_tf_axisflow clean (its only failure is the 4 pre-existing f_a_decorrelate errors).
- Spec correction found while writing the mirror: the tensormap theta is the across-edge gradient axis, so "along" is the complement projector (|v_along| = |sin(theta-phi)|). Design sketch had these swapped; spec/plan fixed.
- GenExpr gotcha: `phi` is a predefined constant; assigning it fails the whole compile ("can't assign to predefined constant"). Codebox uses `ref_ang`.
- Panel is 150x100 for six controls; layout unverified until T015 (the tensormap panel needed widening).
