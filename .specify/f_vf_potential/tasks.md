# f_vf_potential — tasks

_Created by the 2026-10-12 maintenance pass: the module shipped and
graduated to docs/, but the audit found two gaps — an unasserted bypass
behavior and a tensor-consumer fact that closes a filed open question.
Ids start at T001._

- [ ] T001: Add a BYPASS_EXPECT entry (or NEUTRAL_BYPASS_BY_DESIGN
  listing) for f_vf_potential in tests/contracts/bench_modules.py. The module
  declares archetype "processor" but its bypass outputs the neutral
  (0,0,0,1), not input passthrough — the implicit out1==in1 check
  shouldn't silently pass or silently skip; one line makes the
  behavior asserted. First live run validates it (the same pattern
  f_chladni's generator-neutral entries use).
- [ ] T002: Fold the OQ11 answer into ideas/f_tensorfield.md's
  consumer audit table: f_vf_potential integrates field *magnitude*
  (codebox_potential.gen:20 — `field_mag = sqrt(fx*fx + fy*fy)`, line
  27 accumulates it), so it is axis-blind: a 180°-flipped field
  produces identical output. The table's current "assumed excluded"
  framing is wrong; it belongs on the affected list. (Code read
  settles the open question; only the doc row needs updating.)

- [x] T003 **Tier-1 NumPy mirror (omp run mirror-build-3, landed 2026-10-20).** `tests/modules/vf_potential/{vf_potential_mirror,test_vf_potential}.py`, 16/16 offline. Checks: the geometric series and fixed point for a uniform field, zero-field decay, bypass, clamp, advection, the strength/tint feedback closed form, and the direction of `decay` from the doc's own words (added 2026-10-20 after the planted-doc control for this module was missed by the author and the verifier). See `HANDOFF.md` 2026-10-20.
