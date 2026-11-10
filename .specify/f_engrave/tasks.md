# Tasks: f_engrave

**Spec**: spec.md · **Plan**: plan.md · Created 2026-11-08 (Claude, with Matt). No module code yet.

Record format: date, who observed (offline Claude / live Matt), source (log path, commit).

**Gate convention for this list:** a gate marked **PRELIMINARY** was decided by Claude's own recommendation on Matt's instruction (2026-11-08), not by Matt. It stays unticked until Matt confirms it or a measurement settles it. **Phase 1 onward is conditional:** it is written generically here and is rewritten at the decision gate (T030) once the method is chosen. If the gate says stop, Phases 1 to 3 are not done.

## Expected source layout

```
tests/modules/engrave/spike/{fields.py, metrics.py, cand_a_lic.py, cand_b_iso.py, cand_c_dist.py, cand_d_phase.py, cand_e_gabor.py, spike_report.md}
(after the decision) src/f_engrave/{definition.py, codebox_*.gen}
tests/modules/engrave/{engrave_mirror.py, test_engrave.py, bench_engrave.py, bench_engrave_module.py}
package/patchers/f_engrave.maxpat    docs/f-reference/f_engrave.md    package/help/f_engrave.maxhelp
```

## Phase 0: the spike (BLOCKING for everything else)

- [x] T001 [GATE] DECIDED (Matt, 2026-11-08): the line-field method is a Phase 0 gate; the three candidates are tried and chosen by looking and by measured criteria.
- [x] T002 [GATE] DECIDED (Matt, 2026-11-08): `f_engrave` is separate from `f_tf_hatch`; hatch stays as it is.
- [ ] T003 [GATE G1] PRELIMINARY: the spike is part of tier 1; tiers 2 and 3 apply to the winner.
- [ ] T004 [GATE G3] PRELIMINARY: lengths in frame heights, shared with `f_vf_erode` and `f_screen`.
- [ ] T005 [GATE G4] PRELIMINARY: prefer a stateless method; a stateful winner needs a stated reason and the bypass behaviour of plan ADR-6.
- [ ] T006 [GATE G7/G8] PRELIMINARY: tone-to-width by `|s| < tone/2`, per-line tone read, hairlines by a texel-wide antialiasing ramp (plan ADR-4).
- [ ] T007 Read `docs/f-reference/f_tf_hatch.md` and `docs/f-reference/f_tensor_type.md` again for the exact raw-tensor encoding and decode idiom; write the decode into `tests/modules/engrave/spike/fields.py` so the fields are real encoded tensors, not angles.
- [ ] T008 [US1] Write `tests/modules/engrave/spike/fields.py`: F1 uniform (0, 45, 90 degrees and one other), F2 concentric rings, F3 gentle bend, F4 radial rays, F5 a wedge and a saddle; each with a flat-tone image, a ramp, and a small-perturbation copy (plan ADR-2).
- [ ] T009 [US1] [US2] [US3] Write `tests/modules/engrave/spike/metrics.py`: area law, tone extremes, spacing coefficient of variation along a transect, angle error between the drawn lines and the axis in high-coherence regions, continuity (longest unbroken line as pitches), stability under perturbation (spec SC-001 to SC-005). Test the metrics on a hand-drawn ideal image (parallel lines at `pitch`) so they give 0 error there.
- [ ] T010 [P] [US1] Candidate A, `cand_a_lic.py`: LIC over a stripe seed. Run on F1 to F5; record the metrics. Prediction to check (inferred): it fails F2 and F3.
- [ ] T011 [P] [US1] Candidate B, `cand_b_iso.py`: iso-lines of smoothed tone, with and without gradient normalisation. Prediction (inferred): spacing fails.
- [ ] T012 [P] [US1] Candidate C, `cand_c_dist.py`: distance-from-previous-line placement, with a jump-flooding-style multi-pass approximation noted. Prediction (inferred): exact near the seed, drifts elsewhere.
- [ ] T013 [P] [US1] Candidate D, `cand_d_phase.py`: a global phase solve on a coarse grid in the style of "Stripe Patterns on Surfaces" (recalled from memory, not read; fetch the paper first if Matt allows, or note that the implementation is from memory). Record iterations to converge, working grid size and how the solved field is interpolated.
- [ ] T014 [P] [US1] Candidate E, `cand_e_gabor.py`: oriented Gabor or phasor-style kernels (recalled from memory, not read); record taps per pixel and the line-break statistics.
- [ ] T015 Write `tests/modules/engrave/spike/spike_report.md`: the numbers for every candidate on every field, the shader-limit feasibility of each (statements, reads per stage, state, cost against `f_tf_hatch`), and the images saved as PNGs next to it. No thresholds are chosen before the numbers are in.
- [ ] T016 [US2] [US3] Check the geometric caveat of the plan (spacing between streamlines depends on the field's divergence) against the F4 numbers; record whether the spec's SC-002 should apply only to F1 to F3.

## Decision gate

- [ ] T030 [GATE G2] **Matt's decision, with the spike report in hand:** pick a candidate, or stop. If a candidate is picked: set the SC thresholds in the spec (SC-001 to SC-005) from the report, tick the stop rule as passed, and rewrite Phases 1 to 3 below for that method. If stop: park the spec with the report (`.specify/paused/` or `gates.md` with a tripwire) and do not build.
- [ ] T031 [GATE G5] Record the singularity policy chosen from the F5 numbers (converge, fade, or leave a gap).
- [ ] T032 [GATE G6] Choose the fallback blend and `coh_floor` default from the seam visible in the numbers.
- [ ] T033 [GATE G9/G10] Record `sample()` behaviour and the cost estimate for the winner; decide whether it fits (spec NF-001, NF-002).

- [ ] T033a [GATE G-plate] Plate toggle Channels / Single (Matt, 2026-11-08; spec "Plates from `f_separate`"). Phase 0: add Single to the NumPy mirror (tone `max(r,g,b)`, colour `rgb/t`, black stays black, one angle) and test: a teal plate gets one set of marks with equal channels' pattern; Channels mode unchanged. Settle which angle param Single reads and the default (PRELIMINARY: `offset_r`).
- [ ] T033b Phase 1: `plate` Param in the codebox and `definition.py`; bench Single against the mirror (read `skills/bench-test-authoring` first).

## Phase 1: build (CONDITIONAL; rewrite at T030)

- [ ] T040 [US1] [US2] [US3] Mirror of the winner at shader scale: `tests/modules/engrave/engrave_mirror.py` and `test_engrave.py` for SC-001 to SC-007 (plate independence, render-size scaling, determinism, non-finite zap included). Run `tests/run.sh -q tests/modules/engrave`.
- [ ] T041 [US1] [US4] `src/f_engrave/codebox_*.gen` for each stage of the winner, plus the draw stage (plan ADR-4, ADR-5, ADR-7). Follow `skills/jit-gen-codebox/SKILL.md`.
- [ ] T042 `src/f_engrave/definition.py` (stages, `render_dim`, Params, `bypass_gate`), then `build/py.sh build/build_patcher.py`, drift check, JSON validate, `tests/contracts/test_module_contracts.py` (offline only).
- [ ] T043 `tests/modules/engrave/bench_engrave.py` and `bench_engrave_module.py`, stage by stage (read `skills/bench-test-authoring` first). Written offline; run only with Matt's go, `-q`.
- [ ] T044 [US5] Fallback direction and `coh_floor`; [US6] `softness`, `min_width`, `ends`.

## Phase 2: tuning (Matt, CONDITIONAL)

- [ ] T050 Live look: a photo through `f_tf_tensormap`, smoothing and `f_engrave`; crosshatch from a second plate; does it read as an engraving?
- [ ] T051 Live look: followed by `f_vf_erode` and `f_paper` (once those exist); one bent use.
- [ ] T052 Pitch range, defaults, offsets, fallback, softness; back into the codebox and `definition.py`, then re-run tiers 1 and 2.

## Phase 3: docs and registration (CONDITIONAL)

- [ ] T060 Reference doc `docs/f-reference/f_engrave.md`, helpfile (the `f-helpfile` skill), menu placement (`G-menu`), README Patches row (110 characters; regenerate the launcher), inventory rows.
- [ ] T061 `ideas/f_print_styles.md` stage 2 status; INDEX entry; `.specify/gates.md` rows (including `G-tensor-t3` note: a new tensor consumer); module-preflight checklist before `.specify/stable/`.

## Dependencies and order

T007 to T009 (fields and metrics) block all candidate tasks; T010 to T014 are parallel (separate files); T015 follows all of them; the decision gate T030 blocks Phases 1 to 3. T031 to T033 are decided from the report.

## Record

- 2026-11-08 (offline, Claude): spec drafted, then this plan and task list written from it. The plan's predictions about the five candidates are inferred; D and E are recalled from the literature and not read. Gates marked PRELIMINARY are Claude's recommendations, taken on Matt's instruction; nothing here has been run.
