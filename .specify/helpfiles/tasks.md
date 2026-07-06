# Tasks — f_ Helpfiles

Flat ordered task list. One helpfile per session or batch simple ones together.

---

## Cross-cutting setup

- [x] T001 — Establish helpfile conventions (layout, fonts, rects) via f_droste.maxhelp
- [x] T002 — Write f-helpfile skill to claude-scaffold
- [x] T003 — Add `## References` section to docs/f_droste.md
- [ ] T004 — Add `## References` section to all remaining docs/ files (f_stereo, f_mobius, f_chladni, f_stipple, f_grain, f_lens, f_masonry, f_channel_grader, f_hue_processor, f_luma_processor, f_tone_curve, f_texrouter)

---

## Per-patcher helpfiles

- [x] T010 — f_droste.maxhelp — processor template ✅ 2026-06-06
- [ ] T011 — f_stereo.maxhelp — simple processor, no time inlet
- [ ] T012 — f_mobius.maxhelp — simple processor
- [ ] T013 — f_chladni.maxhelp — generator; note audio companion patch
- [ ] T014 — f_stipple.maxhelp — dual-mode generator
- [ ] T015 — f_grain.maxhelp — dual-mode generator
- [ ] T016 — f_lens.maxhelp — complex processor, many params; do after lens is stable
- [ ] T017 — f_masonry.maxhelp — do after masonry C inlet and quantize issues resolved
- [ ] T018 — f_channel_grader.maxhelp
- [ ] T019 — f_hue_processor.maxhelp
- [ ] T020 — f_luma_processor.maxhelp
- [ ] T021 — f_tone_curve.maxhelp
- [ ] T022 — f_texrouter.maxhelp — utility; assess signal flow separately

---

## Per-helpfile checklist (copy per patcher)

Each T01x task is done when:
- [ ] Ranges verified from codebox and attrui
- [ ] docs/f_name.md has ## References section
- [ ] .maxhelp generated from template, opened in Max
- [ ] Demo produces visible output
- [ ] Layout clean (no clipping, correct column widths)
- [ ] Committed
