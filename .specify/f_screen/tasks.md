# Tasks: f_screen

**Spec**: spec.md · **Plan**: plan.md · Created 2026-11-08 (Claude, with Matt). No module code yet.

Record format: date, who observed (offline Claude / live Matt), source (log path, commit).

**Gate convention for this list:** a gate marked **PRELIMINARY** was decided by Claude's own recommendation on Matt's instruction (2026-11-08), not by Matt. It stays unticked until Matt confirms it or a measurement settles it. Matt's own decisions from the idea file are ticked.

## Expected source layout

```
src/f_screen/{definition.py, codebox_screen.gen}
tests/modules/screen/{screen_mirror.py, test_screen.py, bench_screen.py, bench_screen_module.py}
package/patchers/f_screen.maxpat    docs/f-reference/f_screen.md    package/help/f_screen.maxhelp
```

## Phase 0: gates and the mirror (BLOCKING for Phase 1)

- [x] T001 [GATE] DECIDED (Matt, 2026-11-08): no riso-specific halftone work; general halftoning only.
- [x] T002 [GATE] TENTATIVE (Matt, 2026-11-08: "a decision but I'm not sure it's the decision"): fixed-angle screens only; form-following marks go to `f_engrave`.
- [ ] T003 [GATE G1] PRELIMINARY: tiers 1, 2 and 3 all apply.
- [ ] T004 [GATE G2] PRELIMINARY: lengths in frame heights, x scaled by the aspect (shared with `f_ink`).
- [ ] T005 [GATE G3] Verify the area-preserving spot functions in the mirror (plan ADR-2): line exact, square exact, round dot by `A(r)`, shape morph within tolerance. The round-dot derivation is inferred and must pass before the codebox copies it.
- [ ] T006 [GATE G4] PRELIMINARY: per-cell tone at the cell centre, one `nearest` tap. MEASURE the staircase on a ramp and a cell-average alternative (up to 16 taps) in the mirror before tier 3.
- [ ] T007 [GATE G5] MEASURE: the smallest pitch (in texels) at which the area law holds within tolerance, and the antialiasing ramp width (plan ADR-3). Assumed about 3 texels until then.
- [ ] T008 [GATE G6] PRELIMINARY: rotate about the frame centre; check in the mirror that 0, 45 and 90 degrees are exact and stable on non-square frames.
- [ ] T009 [GATE G7] MEASURE: jitter displacement limit (plan ADR-5 proposes 0.25 cell) and its statement and read cost.
- [ ] T010 [GATE G8] MEASURE on the bench (T022): `sample()` interpolation, and whether `sample()` works inside a user function and a loop. Until then the design uses `nearest` reads in the main body, passing tone to the functions.
- [ ] T011 [GATE G9] DEFERRED by Matt (linear-light versus encoded). PRELIMINARY: values as given; revisit at tier 3.
- [ ] T012 [GATE G10] PRELIMINARY: keep `f_screen`; `f_halftone` is the alternative; menu at Phase 3 (`G-menu`).
- [ ] T013 [GATE G11] PRELIMINARY: the control set in the spec's table; panel layout at T040 (`G-ui-density`).
- [ ] T014 [GATE G12] PRELIMINARY: no driver inlets in v1.
- [ ] T015 [GATE G13] Read `docs/f-reference/discrete_item_conventions.md` and align `softness`, `jitter`, `shape` and `angle` with it; note any differences.
- [ ] T016 Confirm the twelve preliminary decisions P1-P12 in the spec with Matt (or note which he reverses).
- [ ] T017 [US1] [US3] NumPy mirror `tests/modules/screen/screen_mirror.py` and `test_screen.py`: area law (flat patches, several tones, pitches, angles), tone extremes exact, monotone ramp, lattice period and orientation, plate independence, non-finite zap, render-size scaling. Run `tests/run.sh -q tests/modules/screen`.
- [ ] T018 [US6] Mirror additions for jitter (exact at 0, mean preserved at 1, no overlap beyond the cell) and for Threshold and Bayer.

- [ ] T016a [GATE G-plate] Plate toggle Channels / Single (Matt, 2026-11-08; spec "Plates from `f_separate`"). Phase 0: add Single to the NumPy mirror (tone `max(r,g,b)`, colour `rgb/t`, black stays black, one angle) and test: a teal plate gets one set of marks with equal channels' pattern; Channels mode unchanged. Settle which angle param Single reads and the default (PRELIMINARY: `angle_r`).
- [ ] T016b Phase 1: `plate` Param in the codebox and `definition.py`; bench Single against the mirror (read `skills/bench-test-authoring` first).

## Phase 1: build

- [ ] T020 [US1] [US3] [US4] `src/f_screen/codebox_screen.gen`: rotation, cell, tone read, spot functions for Dot and Line, soft edge, exact extremes, zap, bypass, alpha pass-through (plan ADR-1 to ADR-4, ADR-7). Follow `skills/jit-gen-codebox/SKILL.md`.
- [ ] T021 `src/f_screen/definition.py`: one stage, `render_dim`, Params (`pitch`, `angle_r/g/b`, `softness`, `screen` menu, `bypass_gate`), route, panel; then `build/py.sh build/build_patcher.py`, drift check, JSON validate, `tests/contracts/test_module_contracts.py` (offline only).
- [ ] T022 `tests/modules/screen/bench_screen.py` and `bench_screen_module.py` (read `skills/bench-test-authoring` first). Written offline; run only with Matt's go, `-q`. First bench items: T010 and T007.
- [ ] T023 [US5] Shape morph and `shape` Param (plan ADR-2), mirror and bench.
- [ ] T024 [US6] Jitter (plan ADR-5): hash, nine-cell function, `jitter` and `seed` Params, mirror and bench.
- [ ] T025 [US7] Threshold and Bayer types (plan ADR-6): `screen` menu entries, `level` Param, mirror and bench.

## Phase 2: tuning (Matt)

- [ ] T030 Live look: a photo through three plates at 15, 75, 45; rosette and moiré; the staircase of dot sizes (T006).
- [ ] T031 Live look: `f_screen` into `f_ink`; does it read as a print? One bent use (coarse screen, odd angles, a line screen on a simulation).
- [ ] T032 Dial ranges, defaults, default angles, the smallest pitch, softness; back into the codebox and `definition.py`, then re-run tiers 1 and 2.

## Phase 3: docs and registration

- [ ] T040 Reference doc `docs/f-reference/f_screen.md`, helpfile (the `f-helpfile` skill), menu placement (T012), README row (110 characters; regenerate the launcher), inventory rows.
- [ ] T041 `ideas/f_print_styles.md` stage 2 status; INDEX entry; `.specify/gates.md` rows; module-preflight checklist before `.specify/stable/`.

## Dependencies and order

Phase 0 gates, then the mirror (T017) before any codebox; T020 to T022 in order; T023, T024 and T025 are P2 and each edits `codebox_screen.gen`, so they run in sequence, not in parallel.

## Record

- 2026-11-08 (offline, Claude): spec drafted, then this plan and task list written from it. Gates marked PRELIMINARY are Claude's recommendations, taken on Matt's instruction; nothing here has been run or measured, and the round-dot area function is an inferred derivation.
