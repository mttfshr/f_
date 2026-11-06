# f_vf_split — tasks

_Created by the 2026-10-12 maintenance pass: module has no .specify
folder (graduated straight to docs/). One triviality-skip note closes
the bench axis per the constitution's "skip, but say so" rule; one
one-line doc fix. Ids start at T001._

- [x] T001 (decided 2026-10-19, Matt: tiers 1-2 skipped as trivial; the stale
  doc line was already fixed): Record the written triviality-skip decision for tier-1/tier-2
  coverage (the codebox is two samples + two mixes — the cheapest
  non-identity shader in the library; BYPASS_EXPECT {2: IN1} is the only
  check it needs), and fix the one stale line in
  docs/f-reference/f_vf_split.md: it still says the module is "not yet
  listed in README.md's patch table" — it is (README.md:110).

## Moved to stable/ (2026-11-06)

Preflight. Part 1 offline by Claude: drift ok, `tests/run.sh -q` on six named files passed (log `tests/logs/20261106-080311-offline.log`), menu and launcher `--check` up to date. `bench_modules.py` 2/2 from 2026-11-05 (log `tests/logs/20261105-215801-bench.log`). Live by Matt, 2026-11-06: helpfile look passes, wording stays as it is. The helpfile lists a `bypass` message that does not work (the same bench log: works in 7 modules of 50); Matt accepted this 2026-11-06, no gate row.
