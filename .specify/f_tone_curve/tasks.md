# f_tone_curve — tasks

_Created by the 2026-10-12 maintenance pass: module has no .specify
folder (graduated straight to docs/). The audit found one stale
cross-reference and one idea Matt flagged "wants this pursued for
real". Ids start at T001._

- [ ] T001: Fix the stale pointer in
  ideas/lut_curve_and_color_controls.md: it twice cites a revisit note
  "added at `.specify/f_tone_curve/definition.py`" (lines 47, 124) —
  no such folder/file exists anywhere. Either create the folder and
  move the note there or correct the pointer to wherever the note
  actually lives (likely src/f_tone_curve/definition.py). While in
  that ideas file: the dependent-texture 1×256 LUT experiment it
  specs (Matt: "wants this pursued for real") is the actionable
  follow-up; this task is the doc-pointer fix, the LUT work stays
  tracked in the ideas file until picked up.