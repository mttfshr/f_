# f_a_ripple — tasks

_Created by the 2026-10-12 maintenance pass: the folder had only
spec.md + plan.md — the plan's Phase 4 "not yet done" and Phase 5
"not started" had no task-level tracking record. Ids start at T001._

- [ ] T001: Fix the modulated-band loop bounds (plan ADR-2's "honest
  fix"): compute n_lo..n_hi from band edges + f0 instead of running all
  200 harmonics with gated accumulation. Measured non-blocking (DSP
  CPU% ~33% flat, 2026-09-15) — code hygiene, not a perf emergency.
- [ ] T002: Phase 4/5 leftovers per plan.md: live.dial UI grid per f_
  conventions (shipped maxpat currently uses plain flonums), and the
  Phase 5 docs/helpfile (no .maxhelp exists). Also close the one
  unchecked spec acceptance box: perceptual comparison against
  checkhearing.org at matched settings.