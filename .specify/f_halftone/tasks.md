# Tasks: f_halftone

**Spec**: spec.md · **Plan**: plan.md · Created 2026-11-08 (Claude, with Matt). No module code yet.

Record format: date, who observed (offline Claude / live Matt), source (log path, commit).

**Gate convention for this list:** a gate marked **PRELIMINARY** was decided by Claude's own recommendation on Matt's instruction (2026-11-08), not by Matt. It stays unticked until Matt confirms it or a measurement settles it. Matt's own decisions from the idea file are ticked.

## Expected source layout

```
src/f_halftone/{definition.py, codebox_halftone.gen}
tests/modules/halftone/{halftone_mirror.py, test_halftone.py, bench_halftone.py, bench_halftone_module.py}
package/patchers/f_halftone.maxpat    docs/f-reference/f_halftone.md    package/help/f_halftone.maxhelp
```

## Phase 0: gates and the mirror (BLOCKING for Phase 1)

- [x] T001 [GATE] DECIDED (Matt, 2026-11-08): no riso-specific halftone work; general halftoning only.
- [x] T002 [GATE] TENTATIVE (Matt, 2026-11-08: "a decision but I'm not sure it's the decision"): fixed-angle screens only; form-following marks go to `f_engrave`.
- [ ] T003 [GATE G1] PRELIMINARY: tiers 1, 2 and 3 all apply.
- [ ] T004 [GATE G2] PRELIMINARY: lengths in frame heights, x scaled by the aspect (shared with `f_vf_erode`).
- [x] T005 [GATE G3] (2026-11-13, offline Claude, `tests/logs/20261113-224223-offline.log`: A(r) vs Monte Carlo within 4e-3, ends exact, slope matches; area law at 24 texels: dot 0.0046, line 0.0002, square 0.0023, morph 0.0036) Verify the area-preserving spot functions in the mirror (plan ADR-2): line exact, square exact, round dot by `A(r)`, shape morph within tolerance. The round-dot derivation is inferred and must pass before the codebox copies it.
- [ ] T006 [GATE G4] P1 ACCEPTED by Matt 2026-11-13 (still MEASURE before tier 3): per-cell tone at the cell centre, one `nearest` tap. MEASURE the staircase on a ramp and a cell-average alternative (up to 16 taps) in the mirror before tier 3.
- [ ] T007 [GATE G5] MEASURE: the smallest pitch (in texels) at which the area law holds within tolerance, and the antialiasing ramp width (plan ADR-3). Assumed about 3 texels until then.
- [ ] T008 [GATE G6] PRELIMINARY: rotate about the frame centre; check in the mirror that 0, 45 and 90 degrees are exact and stable on non-square frames.
- [ ] T009 [GATE G7] MEASURE: jitter displacement limit (plan ADR-5 proposes 0.25 cell) and its statement and read cost.
- [ ] T010 [GATE G8] MEASURE on the bench (T022): `sample()` interpolation, and whether `sample()` works inside a user function and a loop. Until then the design uses `nearest` reads in the main body, passing tone to the functions.
- [ ] T011 [GATE G9] DEFERRED by Matt (linear-light versus encoded). PRELIMINARY: values as given; revisit at tier 3.
- [x] T012 [GATE G10] DECIDED (Matt, 2026-11-13): the name is `f_halftone` (renamed from `f_screen`); menu at Phase 3 (`G-menu`).
- [ ] T013 [GATE G11] PRELIMINARY: the control set in the spec's table; panel layout at T040 (`G-ui-density`).
- [ ] T014 [GATE G12] PRELIMINARY: no driver inlets in v1.
- [ ] T015 [GATE G13] Read `docs/f-reference/discrete_item_conventions.md` and align `softness`, `jitter`, `shape` and `angle` with it; note any differences.
- [ ] T016 (partly done 2026-11-13, see Record) Confirm the twelve preliminary decisions P1-P12 in the spec with Matt (or note which he reverses).
- [x] T017 (2026-11-13, offline Claude: 16/16, `tests/logs/20261113-224223-offline.log`) [US1] [US3] NumPy mirror `tests/modules/halftone/halftone_mirror.py` and `test_halftone.py`: area law (flat patches, several tones, pitches, angles), tone extremes exact, monotone ramp, lattice period and orientation, plate independence, non-finite zap, render-size scaling. Run `tests/run.sh -q tests/modules/halftone`.
- [ ] T018 [US6] Mirror additions for jitter (exact at 0, mean preserved at 1, no overlap beyond the cell) and for Threshold and Bayer.

- [x] T016a (2026-11-13, offline Claude: Single in the mirror, `test_single_plate`, same log) [GATE G-plate] Plate toggle Channels / Single (Matt, 2026-11-08; spec "Plates from `f_separate`"). Phase 0: add Single to the NumPy mirror (tone `max(r,g,b)`, colour `rgb/t`, black stays black, one angle) and test: a teal plate gets one set of marks with equal channels' pattern; Channels mode unchanged. Single reads `angle_b` and `phase_b` (default 45 degrees, the common single-plate angle; inferred, Matt 2026-11-13: "the real-world standard").
- [ ] T016c Phase 0: add the per-plate phase offset (FR-016) to the mirror: a shifted plate's marks stay whole and sharp, 0 phase unchanged, a full-pitch shift returns the original. Phase 1: six `phase_*` Params.
- [ ] T016b Phase 1: `plate` Param in the codebox and `definition.py`; bench Single against the mirror (read `skills/bench-test-authoring` first).

## Phase 1: build

- [ ] T020 [US1] [US3] [US4] `src/f_halftone/codebox_halftone.gen`: rotation, cell, tone read, spot functions for Dot and Line, soft edge, exact extremes, zap, bypass, alpha pass-through (plan ADR-1 to ADR-4, ADR-7). Follow `skills/jit-gen-codebox/SKILL.md`.
- [ ] T021 `src/f_halftone/definition.py`: one stage, `render_dim`, Params (`pitch`, `angle_r/g/b`, `softness`, `screen` menu, `bypass_gate`), route, panel; then `build/py.sh build/build_patcher.py`, drift check, JSON validate, `tests/contracts/test_module_contracts.py` (offline only).
- [ ] T022 `tests/modules/halftone/bench_halftone.py` and `bench_halftone_module.py` (read `skills/bench-test-authoring` first). Written offline; run only with Matt's go, `-q`. First bench items: T010 and T007.
- [ ] T023 [US5] Shape morph and `shape` Param (plan ADR-2), mirror and bench.
- [ ] T024 [US6] Jitter (plan ADR-5): hash, nine-cell function, `jitter` and `seed` Params, mirror and bench.
- [ ] T025 [US7] Threshold and Bayer types (plan ADR-6): `screen` menu entries, `level` Param, mirror and bench.

## Phase 2: tuning (Matt)

- [ ] T030 Live look: a photo through three plates at 15, 75, 45; rosette and moiré; the staircase of dot sizes (T006).
- [ ] T031 Live look: `f_halftone` into `f_vf_erode`; does it read as a print? One bent use (coarse screen, odd angles, a line screen on a simulation).
- [ ] T032 Dial ranges, defaults, default angles, the smallest pitch, softness; back into the codebox and `definition.py`, then re-run tiers 1 and 2.

## Phase 3: docs and registration

- [ ] T040 Reference doc `docs/f-reference/f_halftone.md`, helpfile (the `f-helpfile` skill), menu placement (T012), README row (110 characters; regenerate the launcher), inventory rows.
- [ ] T041 `ideas/f_print_styles.md` stage 2 status; INDEX entry; `.specify/gates.md` rows; module-preflight checklist before `.specify/stable/`.

## Dependencies and order

Phase 0 gates, then the mirror (T017) before any codebox; T020 to T022 in order; T023, T024 and T025 are P2 and each edits `codebox_halftone.gen`, so they run in sequence, not in parallel.

## Record

- 2026-11-08 (offline, Claude): spec drafted, then this plan and task list written from it. Gates marked PRELIMINARY are Claude's recommendations, taken on Matt's instruction; nothing here has been run or measured, and the round-dot area function is an inferred derivation.
- 2026-11-13 (Matt, chat; Claude recorded): P1 and P6 accepted; per-plate x/y phase added (FR-016, T016c); Single reads `angle_b` (45, standard single-plate angle: Matt said to use the real-world standard, the value is Claude's inference); T002 (fixed-angle only) stays open until the first live look; name decided `f_halftone` (renamed from `f_screen` in docs only; nothing was built). `f_dither_grain` stays separate (superseded, paused). P2-P5 and P7-P12 not yet explicitly confirmed. Nothing run.
- 2026-11-13 (offline, Claude; log `tests/logs/20261113-224223-offline.log`, 16/16; mirror only, nothing on the bench): `tests/modules/halftone/halftone_mirror.py` and `test_halftone.py` written (T017; T016c's mirror half: whole-pitch shift returns the original, phase 0.25 at a 16-texel pitch moves the plate 4 texels, marks as sharp; T018's mirror half: jitter, Threshold, Bayer). T016c and T018 stay unticked (T016c has a Phase 1 half; T018's "mean preserved at jitter 1" does NOT hold, below). Measured:
  - **G5 / T007 (mirror only; the bench must repeat it):** worst area-law error by pitch in texels: 1.5: 0.171, 2: 0.125, 3: 0.083, 4: 0.062, 6: 0.039, 8: 0.025, 12: 0.011, 24: 0.005 (dot). The assumed "about 3 texels" smallest pitch is 8% off; under 2% needs about 10 texels. Cause (inferred from the numbers and the formula, not isolated by a test): the ADR-3 edge ramp is cut off at the cell boundary, so gaps thinner than a texel lose ink (square at tone 0.95, 10 texels: -0.024; dot at 0.8: -0.015). A fix would be a change to ADR-3.
  - **G4 / T006:** on a linear ramp the centre tap and the 4 x 4 average give the same band error (0.026 at 7.7 texels, 0.005 at 20 and 41): a linear ramp cannot tell them apart, since the centre value is the cell mean. On a hard edge (0 | 0.8, 20 texels) the ink on the dark half is 0.0155 (centre) against 0.0197 (average). No offline case for the average; the staircase question is for the live look.
  - **Jitter 1 (ADR-5):** mean coverage minus tone: +0.001 at 0.1, 0.000 at 0.3, -0.010 at 0.5, -0.041 at 0.7, -0.069 at 0.9. Spec US6 scenario 2 ("the mean coverage still equals the tone") fails above mid-tone: displaced dots overlap and the cell-clipped area function no longer applies. Needs a decision (accept and reword, or a different area function under jitter).
  - **G6 / T008 (evidence, gate left for Matt):** 90 degrees is the 0 degree output turned a quarter (1e-4); 45 is its own quarter turn; on a 400 x 200 frame the period is pitch x H = 20 texels in both directions.
  - **Softness 0.5:** area-law error 0.041 (tolerance set at 0.05).
  - Mirror note: a NaN tone is dropped by the Dot path's running maximum even without the zap, so the zap mutation is tested on the Line path. The codebox must not rely on that.
- 2026-11-13 (Matt, chat): about 10 texels accepted as the practical pitch floor for now, no ADR-3 change, the bench (T022) repeats the measurement, so T007 stays open; the jitter ink loss above mid-tone is accepted for now and spec US6 scenario 2 is reworded.
