# f_vf_chroma — tasks (maintenance additions)

_Filed in place: the module is paused mid-retool and a maintenance
finding doesn't by itself mean "resume" (.specify/maintenance/SKILL.md).
Ids start at T001; these sit alongside the paused design work recorded
in continuity.md._

- [ ] T001: The paused design item itself, restated as a task so it's
  on a queue somewhere: closest-emitter / painter-model retool to fix
  the rainbow-averaging collapse (continuity.md's "Proposed direction
  for next session" — first-hit loop or single-sample variant). The
  shipped v10 "produces color, field-driven, gated" but the rainbow
  washes out to gray; vortex-field + v10 is the recorded starting
  point.
- [ ] T002: Build-system blocker for the above either way:
  build_patcher.py hardcodes 2-option text_button wiring
  (parameter_mmax=1.0, reads options[0]/options[1]) so `direction=Bi`
  is unreachable from the UI on the shipped module. Needs n-option
  toggle support (belongs with .specify/build_layout's schema-gap work
  if that's where build_patcher changes are tracked).
- [ ] T003: When the module resumes: the strength→gain/mix_pct
  conversion it missed (2026-07-17 rollout skipped it, never recorded
  as deliberate), the stale spec.md (still describes the scrapped v4
  local-CA architecture), and the stale
  docs/f-reference/f_vf_chroma.md all get refreshed together as part
  of the retool's docs phase — not piecemeal while paused.