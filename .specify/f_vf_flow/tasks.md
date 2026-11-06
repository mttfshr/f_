# f_vf_flow — tasks

_Created by the 2026-10-12 maintenance pass: the module shipped and
graduated to docs/, but its bypass behavior is completely unasserted
(archetype "dual" means the implicit out1==in1 processor check never
applies, and no BYPASS_EXPECT entry exists — unlike sibling generator
f_chladni, which has explicit const entries for exactly this shape).
Ids start at T001._

- [x] T001 (2026-11-06: the module was on native `@bypass`, so the neutral below never ran; moved to `bypass_gate`, entry added, live bench 2/2, log `tests/logs/20261106-081412-bench.log`; live by Matt 2026-11-06: bypass gives a neutral field): Add a `1: ("const", (0.5, 0.5, 0.5, 1.0), 0.0)`-style
  BYPASS_EXPECT entry for f_vf_flow in tests/contracts/bench_modules.py,
  mirroring the f_chladni generator-neutral pattern. The module's
  bypass mixes to the neutral vecfield (correct per family convention)
  — it just has never been asserted anywhere. First live run
  validates.

- [x] T002 (decided 2026-10-19, Matt): tier 1 skipped. Angle-to-unit-vector trig, a few lines, no iteration. (Constitution rule for pre-convention modules, "Verification Tiers".)

- [x] T003 (decided 2026-11-01, Matt): f_vf_flow needs a texture; no unconnected rendering (no gated `r draw`, no size handling). Re-typed `processor` (was `dual`): `vs_inState`, `src_mode` and the unconnected codebox path removed. Render-trigger check closed for this module. Doc and descriptions updated (README, Launch, help, make_missing_helpfiles.py digest; 2026-11-01).
