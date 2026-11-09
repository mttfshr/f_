# Tasks: f_separate

**Spec**: spec.md · **Plan**: plan.md · Created 2026-11-08 (Claude, with Matt). No module code yet.

Record format: date, who observed (offline Claude / live Matt), source (log path, commit).

**Gate convention for this list:** a gate marked **PRELIMINARY** was decided by Claude's own recommendation on Matt's instruction (2026-11-08), not by Matt. It stays unticked until Matt confirms it or a measurement settles it. Matt's own decisions from the idea file are ticked.

## Expected source layout

```
src/f_separate/{definition.py, codebox_separate.gen}
tests/modules/separate/{separate_mirror.py, test_separate.py, bench_separate.py, bench_separate_module.py}
package/patchers/f_separate.maxpat    docs/f-reference/f_separate.md    package/help/f_separate.maxhelp
```

## Phase 0: gates and the mirror (BLOCKING for Phase 1)

- [x] T001 [GATE] DECIDED (Matt, 2026-11-08): plates are RGB, up to three; alpha is not a plate.
- [x] T002 [GATE] DECIDED (Matt, 2026-11-08): not a swizzle; a palette-aware separation with a live composite preview of the palette's colour shift.
- [x] T003 [GATE] DECIDED (Matt, 2026-11-08): no riso-specific halftone emulation (affects `f_screen`, noted here for the contract).
- [ ] T004 [GATE G1] PRELIMINARY: tiers 1, 2 and 3 all apply.
- [ ] T005 [GATE G2] PRELIMINARY: the density model (plan ADR-1). Keep the coverage-weighted multiply as the comparison model in the mirror.
- [ ] T006 [GATE G3] PRELIMINARY: unconstrained least squares then clamp, ridge for collinear palettes (plan ADR-2); a constrained solve is the alternative if the boundary looks wrong.
- [ ] T007 [GATE G4] PRELIMINARY: `ε` and the clamps of plan ADR-3; test each degenerate case.
- [ ] T008 [GATE G2/G5] Ask Matt to compare the preview of the mirror's output against his prepress app on one image and one palette; record which overprint model matches better. Until then the density model stands.
- [ ] T009 [GATE G6] Prove the colour-control route: a `swatch` per colour unpacked to Params, in a scratch `definition.py` (offline: JSON and route; Matt confirms in Max). Fallback: twelve float dials. Read `build/spec.md` for how raw boxes feed Params.
- [ ] T010 [GATE G7] DEFERRED by Matt (linear-light versus encoded). PRELIMINARY: apply the model to values as given; revisit at T032 and add a switch if the look needs it.
- [ ] T011 [GATE G8] PRELIMINARY: keep the name `f_separate`; menu category at Phase 3 (`G-menu`); the panel grouped as Inks / Paper / Mode (`G-ui-density`).
- [ ] T012 [GATE G9] PRELIMINARY: ink order out of scope (order-independent overprint).
- [ ] T013 Confirm the eleven preliminary decisions P1-P11 in the spec with Matt (or note which he reverses), and note the contract with `f_paper` in `ideas/f_print_styles.md`.
- [ ] T014 [US1] [US2] [US3] [US4] NumPy mirror `tests/modules/separate/separate_mirror.py` and `test_separate.py`: flat ink patches, overprint pairs, the paper, a grey ramp, the round trip (in and out of gamut, random palettes), bounds, degenerate palettes, one-ink monotonicity, non-finite zap. Run `tests/run.sh -q tests/modules/separate`.
- [ ] T015 [US5] Mirror additions for Nearest mode (at most one plate at 1; exact ink colours map to their plate).

## Phase 1: build

- [ ] T020 [US1] [US2] [US3] [US4] `src/f_separate/codebox_separate.gen`: density, 3×N solve with ridge, plates and preview, degenerate handling, zap, bypass on both outlets, alpha pass-through (plan ADR-1 to ADR-4, ADR-7). Follow `skills/jit-gen-codebox/SKILL.md`.
- [ ] T021 `src/f_separate/definition.py`: one stage with two outlets, `render_dim`, the colour controls (T009), `inks`, `mode`, `bypass_gate`; then `build/py.sh build/build_patcher.py`, drift check, JSON validate, `tests/contracts/test_module_contracts.py` (offline only).
- [ ] T022 `tests/modules/separate/bench_separate.py` and `bench_separate_module.py` (read `skills/bench-test-authoring` first). Written offline; run only with Matt's go, `-q`. First bench item: per-pixel cost at 1080p.
- [ ] T023 [US5] Nearest mode in the codebox (plan ADR-5): `mode` Param, mirror and bench.
- [ ] T024 [US6] Per-ink gains (`gain1` to `gain3`) in the codebox and the mirror.

## Phase 2: tuning (Matt)

- [ ] T030 Live look: a photo with two and then three inks; does the preview match the character of his prepress app's? (T008)
- [ ] T031 Live look: Nearest mode; a bent use (three unrelated colours, a very narrow palette).
- [ ] T032 Ridge, clamps, defaults and linear-light (T010); back into the codebox and `definition.py`, then re-run tiers 1 and 2.

## Phase 3: docs and registration

- [ ] T040 Reference doc `docs/f-reference/f_separate.md`, helpfile (the `f-helpfile` skill), menu placement (T011), README Patches row (110 characters; regenerate the launcher), inventory rows.
- [ ] T041 `ideas/f_print_styles.md` stage 1 status; INDEX entry; `.specify/gates.md` rows; module-preflight checklist before `.specify/stable/`.

## Dependencies and order

Phase 0 gates, then the mirror (T014) before any codebox; T009 (the colour route) gates T021; T020 to T022 in order; T023 and T024 both edit `codebox_separate.gen`, so they run in sequence.

## Record

- 2026-11-08 (offline, Claude): spec drafted, then this plan and task list written from it. Gates marked PRELIMINARY are Claude's recommendations, taken on Matt's instruction; nothing here has been run or measured. A search of `src/f_vf_glow/definition.py` and `build/spec.md` for a colour-picker type found none (output: `color_mix` is a float dial); T009 depends on that.
