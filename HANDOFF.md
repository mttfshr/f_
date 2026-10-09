# HANDOFF

_Updated 2026-10-08._

## f_caustic sheets mode: done, including the live check

`f_caustic` now has two modes: **Soft** (the original, bit-identical to before) and **Sheets** (a GPU forward
scatter that forms folded sheets), plus a `detail` menu (1-5) that trades quality for cost. All tasks in
`.specify/f_caustic_scatter/tasks.md` are done, including T037's live check and the four follow-ups it raised
(T044-T047). Findings from that check:

- Sheets mode reads clearly better than Soft ("makes soft mode look like crude embossing")
- `color_shift`/`softness` have no effect in Sheets — expected (soft-only params); decided to leave as-is (T047)
- `gain` and `scale` both got a `range_tiers` menu (`definition.py`): `gain` → `[0.1, 1.0, 2.0]`, `scale` →
  `[1.0, 2.5]` (default tier unchanged in both modes, second tier opt-in; soft mode above `scale`=1.0 is
  untested). Built, offline-tested, and confirmed correct in Max.
- `detail` barely moved frame rate live; output resolution clearly did. Investigated (T046,
  `tests/spike_caustic_res_cost.py`): in isolation `f_caustic` never clears the bench's 60 fps vsync floor at any
  detail/size combo tested, 4K included — so the live slowdown is more likely this module's cost compounding on
  top of Matt's full performance patch, not something specific to `f_caustic` alone. Matt is checking his demo
  patch for the actual expensive chain.
- New skill fact from that spike: `skills/jit-gen-codebox/SKILL.md` gained a module-bench `period_ms` gotcha
  (vsync floor + single-sample noise) — **Matt: re-upload that skill, then `./skills/check.sh stamp`**.

- Spec, plan, tasks and every finding: `.specify/f_caustic_scatter/` (`tasks.md` is the record)
- Reference doc: `docs/f-reference/f_caustic.md`. Helpfile: `package/help/f_caustic.maxhelp`
- Tests: offline green on every caustic-related file; bench green on record as of 2026-10-07

## Left for Matt

- Re-upload `jit-gen-codebox` skill and run `./skills/check.sh stamp` (above)
- Whatever the demo-patch chain-cost check turns up
- Soft mode's look with `scale` pushed past 1.0 — untested

## One thing to know

Routine runs: `tests/run.sh -q` and `tests/bench.sh --changed -q` print one line per file and full detail only for
failures (the full bench output still goes to `tests/jobs/bench_last.log`). `test_T020` is the heaviest bench test
(two 16.8 M-point lattices). If it times out, run it alone: `ONLY=T020 python3 tests/bench_caustic_sheets.py`.
