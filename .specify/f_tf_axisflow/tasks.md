# Tasks: f_tf_axisflow

_Created: 2026-10-16_

## Phase 0: mirror
- [x] T001 `tests/modules/tf_axisflow/test_tf_axisflow.py`: projection mirror + brute-force atan2 reference.
- [x] T002 Properties: θ→θ+π invariance, |v| = |cos(θ−φ)|, along + across = r.
- [x] T003 Edge cases: iso → neutral, black input → neutral, gain clamp, `gate` 0/1.
- [x] T004 Aspect: identity on square; pixel direction preserved on 16:9 and 9:16.
- [x] T005 Chain with the tensormap mirror on stripes and ramps; mutation test (sign flip).
- [x] T006 Add to `tests/run.sh` set; green.

## Phase 1: codebox + bench
- [x] T007 `src/f_tf_axisflow/codebox_axisflow.gen` from the plan sketch.
- [x] T008 `tests/modules/tf_axisflow/bench_tf_axisflow.py` + `benchdeps.py` entry (ask Matt before running; bench.maxpat open).
- [x] T009 Bench: parity vs mirror incl. iso, black, aspect, bypass_gate.

## Phase 2: scratch patch (judgment)
- [~] T010 (skipped 2026-10-16: the module itself is the live test) Scratch patch tensormap → axisflow → `f_vf_advect`, noise source.
- [x] T011 (Matt, 2026-11-06: current defaults accepted; `normalize` stays deferred per the reference doc) Matt: sweep `angle`, `gate`, `mode`; confirm no seam; decide defaults and `normalize`.

## Phase 3: module
- [x] T012 `definition.py` (processor, bypass_mode param, 6 controls + bypass, menu for mode).
- [x] T013 Build, register in `menu.py`, README row (≤110 chars), regenerate menu/launcher.
- [x] T014 BYPASS_EXPECT entry (const 0.5,0.5,0.5,1); contract tests; bench_modules clean.
- [x] T015 (covered by T026, passed by Matt 2026-10-17).

## Phase 4: docs
- [x] T016 `docs/f-reference/f_tf_axisflow.md`; helpfile + module-preflight.
- [x] T017 Hub doc: exclusion list points at the bridge; consumer table; HANDOFF entry.
- [x] T018 Naming entry for `f_tf_` in README/constitution (shared with tensormap T042).
- [x] T019 (closed 2026-11-06: committed in `53c10df`) Commit only f_tf_* files (Matt commits; suggest message).

## Phase 5: signed gain + per-pixel reference inlet (2026-10-17)
Why: Axis Flow's flow always has a component along `angle` (mean 0.5 x gain over random edges), and
`f_vf_fluid` accumulates that mean flow (only `drag` damps k=0), so chains drift one way; Matt also wants
negative gain in performance. Decisions (Matt): gain range -4..4; reference inlet unnormalized, `angle`
rotates it, unconnected = old behavior; title-bar label left as `T_ in ∇ out`.
- [x] T020 Signed `gain` (-4..4, default 1): definition range + hint; codebox already unclamped.
- [x] T021 Reference inlet: `mod_inlets` (vs_instate False) -> codebox `in2`; B-gate (|B-0.5|<0.25) absent test;
  pixel-space decode; `angle` rotates. Codebox + mirror `axisflow(ref=...)` in step; patcher rebuilt (pix has 2 inlets).
- [x] T022 Mirror tests: 16 -> 24 (negative gain, constant ref == dial, angle rotates ref, magnitude scales, absent ref
  falls back, per-pixel brute force, seamlessness bound, 16:9 pass-through). `tests/run.sh -q tests/modules/tf_axisflow/test_tf_axisflow.py` 24/24.
- [x] T023 (bench 9/9, 2026-10-17; the sample() tolerance worry did not materialise) Bench: cases written (negative gain, reference inlet, black ref == dial, 16:9 reference); `run_case` now feeds
  in2. NOT RUN: ask Matt (bench.maxpat open). One open point: in2 uses `sample()` (bilinear, so a lower-res fluid
  output reads smoothly); same-size bench inputs should be exact, but if TOL 2e-5 fails check 8-bit sample weights first.
- [x] T024 (2026-11-06, Claude: 69 files passed, log `tests/logs/20261106-081756-offline.log`) Full offline suite once (`tests/run.sh -q`): the rebuild touched only f_tf_axisflow, but the contract /
  drift / conventions tests have not been re-run since.
- [x] T025 Helpfile (2026-10-18): `gain` range corrected, a note on the optional second inlet and negative gain added,
  bpatcher numinlets 2. Text only; Matt's look in Max (the judgment gate) is still to do.
- [x] T026 (passed, Matt 2026-10-17) Matt: load in Max; the panel width (154) is unchanged, check the new inlet position and the cable to it.
- [x] T027 (passed, Matt 2026-10-17) Matt live: tensormap -> axisflow (ref = f_vf_vortex) -> f_vf_fluid; sweep `angle`, negative gain.
- Related, not built: f_caustic `edge` mode (off / wrap / mirror / clamp, vertex-shader) and an optional f_vf_fluid
  `drift` Param scaling the k=0 bin. Both proposed 2026-10-17, neither approved to build yet.

## Phase 6: stable push (2026-11-06)
- [x] T028 Stable preflight (2026-11-06, offline by Claude), record below.
- [ ] T029 Matt's helpfile look: the new demo chain at defaults, the digest, the two notes, the bypass toggle. Then move to `.specify/stable/`.

## Stable preflight (2026-11-06)

Part 1 offline by Claude: drift ok, no baseline entry; menu and launcher `--check` up to date; README row 110 chars or under, no ⚠; menu entry under Adapters, recipe Tensor Advect; bypass is `bypass_gate` (`bypass_mode: "param"`, neutral vecfield in `BYPASS_EXPECT`; `bench_modules.py` passed with 0 unexpected issues in `tests/logs/20261106-081412-bench.log`, before these edits, which touch no module code); helpfile box 154x90 against a footprint of 154x90; `test_generate_menu.py` 17/17 after the helpfile edit (`tests/logs/20261106-084608-offline.log`). Mirror 24 and bench 9 test functions counted in the files. No gate row holds Axis Flow. No code changed, so `bench_tf_axisflow.py` was not re-run: 9/9 rests on the 2026-10-17 record, no log of it is in `tests/logs/`, and it predates the `render_dim` change (`85c32f6`; the codebox itself is unchanged since `0bdf1c6`).

Fixed: `library-characteristics.md` had two chains that cannot work, `f_tf_smooth` and `f_tf_sharpen` into Axis Flow: both output the raw tensor, and Axis Flow reads only packed outlet 1 (from their reference docs and the spec; not run). The Smooth chain now starts at tensormap outlet 1, and the Sharpen idea is replaced by a note saying why not. The spec still had `width` / `height` numboxes, no second inlet, no `angle` rotation, and FR-009 ignored negative gain and long references. `module-inventory.md` and `f_tensor_type.md` said reference angle only; `ideas/f_tensorfield.md` said bench 5/5; `ideas/f_tf_backlog.md` listed the built reference inlet as a v2 idea. The reference doc gained the per-axis clamp, the outlet 1 rule and the bench caveat. `plan.md` got a note that it predates the inlet and `render_dim`.

Helpfile: confirmed no source was wired, so the demo showed only neutral gray. Added `vs_sources_main` -> `f_tf_tensormap` outlet 1 -> Axis Flow -> preview. The inlet note sat on top of the preview: moved beside the module and rewritten, with a second note by the preview. The digest now says what the module is for (spec: consumers can follow image structure). Live by Matt: T029.

Left alone, not Axis Flow's alone: the helpfile lists `bypass [0 / 1]`, but the route is `mode angle gain gate`, so the message does not reach `bypass_gate` (read from the patcher; the contract bench reports the same for 43 modules, Hatch included). `codebox_axisflow.gen` line 2 cites the old mirror path `tests/test_tf_axisflow.py`: fixing it means a rebuild and a stale bench entry (`benchdeps.py` tracks the codebox). `menu.py` says `# no demo` on Tensor Advect, though `f_demo_axisflow` exists (`G-menu` holds `menu.py`). `skills/vsynth-bpatcher/SKILL.md` still has the old category table with Axis Flow under T_ Tensor (the skill needs Matt's re-upload).

## Notes (2026-10-16)
- Mirror 16/16 (`tests/modules/tf_axisflow/test_tf_axisflow.py`); bench 5/5 (`tests/modules/tf_axisflow/bench_tf_axisflow.py`); contract/bench_expect/launch/benchdeps green; bench_modules shows f_tf_axisflow clean (its only failure is the 4 pre-existing f_a_decorrelate errors).
- Spec correction found while writing the mirror: the tensormap theta is the across-edge gradient axis, so "along" is the complement projector (|v_along| = |sin(theta-phi)|). Design sketch had these swapped; spec/plan fixed.
- GenExpr gotcha: `phi` is a predefined constant; assigning it fails the whole compile ("can't assign to predefined constant"). Codebox uses `ref_ang`.
- Panel is 150x100 for six controls; layout unverified until T015 (the tensormap panel needed widening).
