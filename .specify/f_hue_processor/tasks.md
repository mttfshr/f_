# f_hue_processor — tasks

_Reopened by the 2026-10-12 maintenance pass: the module shipped and
graduated to docs/ long ago, but its one recorded bug never landed as a
task (it lived only in plan.md's "known small bugs" line and the
reference doc's Loose Threads — the exact folklore state
.specify/maintenance/plan.md Tier E said to fix). No prior task file
exists; ids start at T001._

- [ ] T001: Fix the hue band-drag UI bug. Symptom: dragging the band in
  the rslider works (fires hue_center/lower/upper via
  package/javascript/hue_rslider.js → hue_range.js), but the
  parameter-enabled `hue_lower`/`hue_upper` live.numboxes'
  parameter_messaging path doesn't reach the pix — `ondrag` calls
  `output()` while `msg_float` on inlets 0/1 deliberately suppresses it
  (loop-back guard), and the numboxes' param_connect goes to the pix
  directly, so the two paths disagree. Audit trail:
  .specify/plan.md:97, docs/f-reference/f_hue_processor.md:34. The
  codebox math itself is correct (band selection via
  `mod(hue - hue_c + 0.5, 1.0) - 0.5`, two smoothstep shoulders,
  saturation gate; reused by f_dither_grain ADR-4). Decide and
  implement the single authoritative path, then re-verify both input
  routes drive the band.
- [ ] T002: Correct docs/f-reference/f_hue_processor.md's parameter
  description: it claims hue_center/hue_lower/hue_upper are "plain
  live.dial floats routed like any other param", but the shipped
  definition.py carries them as `type: "internal"` with no route token,
  driven via the jsui pair. Also resolves the stale HANDOFF citation in
  Loose Threads once T001 lands. Cross-ref: .specify/helpfiles/tasks.md
  T004/T019 still open for this module's helpfile.

- [x] T003 **Tier-1 NumPy mirror (omp run mirror-build-2, landed 2026-10-20).** `tests/modules/hue_processor/{hue_processor_mirror,test_hue_processor}.py`, 14/14 offline. Checks: Python colorsys as the reference, the band sides from the doc (hue_lower below the centre, hue_upper above), the edge smoothstep. Doc corrected to follow the codebox (Matt, 2026-10-20): the default hue_upper is 156.0, not 36.0. See `HANDOFF.md` 2026-10-20.
