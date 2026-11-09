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
- [x] T005 [GATE G2] DECIDED (Matt, 2026-11-08): overprint is additive light on a black background ("add"); density and multiply models dropped, no paper parameter.
- [ ] T006 [GATE G3] PRELIMINARY: unconstrained least squares then clamp, ridge for collinear palettes (plan ADR-2); a non-negative solve is the alternative if the boundary looks wrong.
- [ ] T007 [GATE G4] PRELIMINARY: degenerate cases are a black ink, duplicate or collinear inks, and non-finite input (plan ADR-3); test each.
- [x] T008 [GATE G2/G5] CLOSED (Matt, 2026-11-08): no prepress-app comparison (print is a vocabulary, output is for screens). G2 by T005; G5 by T013: the preview is the fourth outlet.
- [x] T009 [GATE G6] DONE (route proven offline by Claude 2026-11-08, then live by Matt the same day with the probe in `scratch/f_separate_swatch/`). Route: nine `internal` Params `ink1_r` ... `ink3_b`; `raw_ui` params `ink1` to `ink3` give route outlets; per ink, `raw_boxes` chain route outlet -> `swatch` -> `unpack` -> three `prepend param inkN_c` -> pix, plus a loadbang `set` message painting the default. Live (Matt, 2026-11-08): the three swatches show the defaults; a swatch change reaches the output; the Max console showed the swatch list and the three `param` messages matching exactly (swatch1 `0.192857 0. 0.642857 1.` -> `ink1_r 0.192857`, `ink1_g 0.`, `ink1_b 0.642857`); the swatch state is restored by the host's autopattr preset, not by simply reopening the patch (a plain reopen did not pick it up at once; reloading and recalling the preset did), which is how the other widgets behave (inferred; not checked against a dial). DECIDED (Matt, 2026-11-08): a swatch is a hue by lightness plane at one fixed saturation (the `saturation` attribute, default 255; from the maxref), so pastels, greys and dim inks need saturation control: add a small saturation dial per ink (three more controls, `pix_wire` False, feeding the swatch's `saturation` message). Not yet tried in Max: the dial's route into the swatch, and whether a `saturation` message needs a following `bang` to re-output the colour (T021 proof item). The probe file was removed from `package/patchers/`; the scratch copy stays (gitignored).
- [ ] T010 [GATE G7] DEFERRED by Matt (linear-light versus encoded). PRELIMINARY: apply the maths to values as given; revisit at T032.
- [ ] T011 [GATE G8] PRELIMINARY: keep the name `f_separate`; menu category at Phase 3 (`G-menu`); the panel grouped as Inks / Mode (`G-ui-density`).
- [x] T012 [GATE G9] CLOSED: additive overprint is commutative, order is moot.
- [x] T013 P-list review done with Matt, 2026-11-08 (chat, one at a time): P1 to P11, recorded in the spec "Decided with Matt". Outcomes: black background and additive overprint (P2, P3), four outlets with coloured plates (P5), Nearest includes black (P6), no black plate (P7), bypass to all four outlets (P10). Contract note for `f_paper` still to go into `ideas/f_print_styles.md`.
- [x] T013a Spec FRs, stories and success criteria reconciled with the P-list (2026-11-08, Claude, offline); the coloured-plate consequence is an open gate note in the `f_screen`, `f_ink` and `f_engrave` specs (needs Matt). Gain above 1 cannot exceed the ink colour (follows from P9; preliminary).
- [x] T014 [US1] [US2] [US3] NumPy mirror `tests/modules/separate/separate_mirror.py` and `test_separate.py` (additive model only; no second model): flat ink patches, overprint pairs (sums), black, a grey ramp, the round trip (in and out of gamut, random palettes), bounds, degenerate palettes, one-ink monotonicity, non-finite zap. Run `tests/run.sh -q tests/modules/separate`.
- [x] T015 [US4] Mirror additions for Nearest mode (at most one plate at 1; exact ink colours map to their plate).

## Phase 1: build

- [x] T020 [US1] [US2] [US3] [US4] `src/f_separate/codebox_separate.gen`: density, 3×N solve with ridge, plates and preview, degenerate handling, zap, bypass on both outlets, alpha pass-through (plan ADR-1 to ADR-4, ADR-7). Follow `skills/jit-gen-codebox/SKILL.md`.
- [x] T021 `src/f_separate/definition.py`: one stage with four outlets (three plates, preview), the three swatches plus a saturation dial each (T009), `render_dim`, the colour controls (T009), `inks`, `mode`, `bypass_gate`; then `build/py.sh build/build_patcher.py`, drift check, JSON validate, `tests/contracts/test_module_contracts.py` (offline only).
- [ ] T022 `tests/modules/separate/bench_separate.py` and `bench_separate_module.py` (read `skills/bench-test-authoring` first). Written offline; run only with Matt's go, `-q`. First bench item: per-pixel cost at 1080p.
- [ ] T023 [US5] Nearest mode in the codebox (plan ADR-5): `mode` Param, mirror and bench.
- [ ] T024 [US6] Per-ink gains (`gain1` to `gain3`) in the codebox and the mirror.

## Phase 2: tuning (Matt)

- [ ] T030 Live look: a photo with two and then three inks; do the plates and the preview look and behave well on screen? (No prepress comparison; Matt, 2026-11-08.)
- [ ] T031 Live look: Nearest mode; a bent use (three unrelated colours, a very narrow palette).
- [ ] T032 Ridge, clamps, defaults and linear-light (T010); back into the codebox and `definition.py`, then re-run tiers 1 and 2.

## Phase 3: docs and registration

- [ ] T040 Reference doc `docs/f-reference/f_separate.md`, helpfile (the `f-helpfile` skill), menu placement (T011), README Patches row (110 characters; regenerate the launcher), inventory rows.
- [ ] T041 `ideas/f_print_styles.md` stage 1 status; INDEX entry; `.specify/gates.md` rows; module-preflight checklist before `.specify/stable/`.

## Dependencies and order

Phase 0 gates, then the mirror (T014) before any codebox; T009 (the colour route) gates T021; T020 to T022 in order; T023 and T024 both edit `codebox_separate.gen`, so they run in sequence.

## Record

- 2026-11-08 (offline, Claude): `tests/modules/separate/separate_mirror.py` and `test_separate.py` written (T014, T015); `tests/run.sh -q` 12/12, log `tests/logs/20261108-213624-offline.log`. Measured: in-gamut round trip worst 4.8e-4; float32 vs a float64 ridge solve worst 1.1e-5; the ridge's bias against the unregularised least squares up to 4.6e-3 (random palettes, condition number up to 12). The ridge is relative (`1e-4 * trace(K^T K) / N + 1e-8`), an inferred choice (T006 stays PRELIMINARY). Seven mutations are caught. Not run in Max; the codebox does not exist yet.

- 2026-11-08 (offline, Claude): spec drafted, then this plan and task list written from it. Gates marked PRELIMINARY are Claude's recommendations, taken on Matt's instruction; nothing here has been run or measured. A search of `src/f_vf_glow/definition.py` and `build/spec.md` for a colour-picker type found none (output: `color_mix` is a float dial); T009 depends on that.
- 2026-11-08 (offline, Claude): `src/f_separate/codebox_separate.gen` written (T020): about 90 statements, four outlets, nine ink Params, `n_inks`, `sep_mode` (not `mode`: a pix attribute), `gain1-3`, `bypass_gate`; inactive inks decouple by a 1 on the matrix diagonal. NOT compiled, NOT run in Max; syntax is unchecked until the T022 bench. A float32 NumPy transcription of the codebox's own formulation (zero columns, cofactors, `idet`) agrees with the mirror to 5.7e-4 worst over 300 random palettes, inputs, modes and gains (scratch script, not kept). While writing it I found the mirror clamped coverage twice; FR-004 says gain then ONE clamp, so the mirror was changed to match (`test_separate.py` still 12/12, log `tests/logs/20261108-220027-offline.log`). An unconnected inlet reads black with alpha 1, so with nothing connected the codebox gives black plates with alpha 1, not the mirror's alpha 0 (the mirror's `None` case is a convention only).
- 2026-11-08 (offline, Claude): `src/f_separate/definition.py` written and built to `package/patchers/f_separate.maxpat` (T021): one primary pix, four outlets, `render_dim` size_stages, `bypass_mode` param, three swatches (route outlet -> swatch -> unpack -> `prepend param inkN_c` -> pix) with a saturation dial each (dial -> `expr * 255` -> `t b f` -> `prepend saturation` and a bang -> swatch), nine `internal` ink Params. Checked offline: JSON loads, 76 unique ids, every cord's boxes and outlet/inlet indices exist, the route's outlets 8 to 10 reach the three swatches, all four pix outlets are wired; `tests/run.sh -q` on `test_drift.py` 16/16, `test_module_contracts.py` 9/9 (52 modules), `test_bench_expect.py` 10/10 (logs `tests/logs/20261108-220807-offline.log`, `-220812-offline.log`, and one more after the lib edit). Registered in `tests/contracts/bench_modules.py` (`BYPASS_EXPECT` outlets 2-4 = in 1, `INPUT_SIZE` 640). The contract check did not follow `swatch` or `unpack`, so both were added to `tests/lib/module_contract.py` (`PASS_THROUGH`, `TRAVERSE_TOKENS`): a shared-test change, to review. NOT verified in Max (Matt): the built patcher loading; the panel layout (swatches in a band below the dials, a placeholder, `G-ui-density`); whether `saturation` plus the bang makes the swatch re-send its colour; the four outlets driving four plate textures; `@type float32` with `@adapt 0`. The live contract bench (T022) has not been run.
