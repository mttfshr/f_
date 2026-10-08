# HANDOFF

_Updated 2026-10-07._

## f_caustic sheets mode: done and committed

`f_caustic` now has two modes: **Soft** (the original, bit-identical to before) and **Sheets** (a GPU forward scatter that forms folded sheets), plus a `detail` menu (1-5) that trades quality for cost. Tasks T001-T042 are done except T037 (the live check below); T043 was dropped (1 frame of lag is accepted).

- Spec, plan, tasks and every finding: `.specify/f_caustic_scatter/` (`tasks.md` is the record)
- Reference doc: `docs/f-reference/f_caustic.md`. Helpfile: `package/help/f_caustic.maxhelp`
- Measurements: `ideas/optics_map.md`
- Tests: offline 237/237; every bench file is green on record (`bench_caustic_sheets` 18/18)

## Left for Matt

- Live check on real video: `scale` and `gain` ranges, the Detail hitch, two instances in one patch, the look
- Open `f_caustic.maxhelp` in Max and check the layout (never opened there)
- Re-upload the `jit-gen-codebox` skill, then `./skills/check.sh stamp`

## One thing to know

`test_T020` is the heaviest bench test (two 16.8 M-point lattices). If it times out, run it alone: `ONLY=T020 python3 tests/bench_caustic_sheets.py`.
