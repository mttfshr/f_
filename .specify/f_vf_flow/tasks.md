# f_vf_flow — tasks

_Created by the 2026-10-12 maintenance pass: the module shipped and
graduated to docs/, but its bypass behavior is completely unasserted
(archetype "dual" means the implicit out1==in1 processor check never
applies, and no BYPASS_EXPECT entry exists — unlike sibling generator
f_chladni, which has explicit const entries for exactly this shape).
Ids start at T001._

- [ ] T001: Add a `1: ("const", (0.5, 0.5, 0.5, 1.0), 0.0)`-style
  BYPASS_EXPECT entry for f_vf_flow in tests/bench_modules.py,
  mirroring the f_chladni generator-neutral pattern. The module's
  bypass mixes to the neutral vecfield (correct per family convention)
  — it just has never been asserted anywhere. First live run
  validates.