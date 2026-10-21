# f_vf_prism — tasks

_Created by the 2026-10-12 maintenance pass: the folder had
spec.md/plan.md/continuity.md but no tasks.md. The original build's
task tracking lived in plan.md phases. Ids start at T001._

- [ ] T001: Profile the 11-tap blur's cost including the bypassed
  full-cost question: the 33 gate calls (11 taps × 3 channels, each a
  displaced sample) are fully unrolled with no early-exit guard under
  param bypass; no measurement exists. Fold into the glow/streak
  profiling session (all three are the same class). Note: the out3
  BYPASS_EXPECT entry {3: ("vec", 2, 0.0042)} is one of the entries
  bench_modules.py's header still marks "not yet seen green live" —
  that header comment is stale vs the 2026-10-06 33/33 live run (plan.md);
  fix the comment in the same pass. Also while auditing cost:
  ideas/incremental_gaussian_taps.md names prism's "per-tap exp()" —
  stale, shipped v17 uses precomputed constant weights w0–w5; correct
  the idea file when touching it.

- [x] T001a (2026-10-13): Profiled on the live bench
  (`tests/records/spike_four_module_cost.py`, 512², chain=128, median of 3):
  ~0.0169 ms/pass active, ~0.0151 ms/pass bypassed — **not GPU-bound
  even at chain=128** (upper-bound figures only, below the bench's
  ~2–3.5 ms CPU-overhead floor at this resolution/chain). The 33 gate
  samples are confirmed negligible at practical resolution regardless
  of bypass state; no shader-side guard is warranted. The bench header
  staleness note above is unrelated and still open.

- **2026-10-20, clamp edge fix:** v17's three `displaced_r/g/b` helpers clamped the displaced coordinate to exact [0, 1], so on the GPU (probe P9: x = 1.0 reads the first column, y = 0.0 the last row) gate taps near the right and low-y edges read the opposite edge's luma. Bounds are now 0.001 / 0.999 (six lines plus a comment). Patcher regenerated, one-line diff, `drift.py -v f_vf_prism` ok. No tier-1 mirror exists. Tier 3 pending (Matt): a bright left or top edge should no longer produce prism fringes along the right or bottom edge.
