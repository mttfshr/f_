# Tasks — f_ Helpfiles

Flat ordered task list. One helpfile per session or batch simple ones together.

---

## Cross-cutting setup

- [x] T001 — Establish helpfile conventions (layout, fonts, rects) via f_droste.maxhelp
- [x] T002 — Write f-helpfile skill to claude-scaffold
- [x] T003 — Add `## References` section to docs/f_droste.md
- [x] T004 — Add `## References` section to all remaining docs/ files (f_stereo, f_mobius, f_chladni, f_stipple, f_grain, f_lens, f_masonry, f_channel_grader, f_hue_processor, f_luma_processor, f_tone_curve, f_texrouter) ✅ 2026-10-12 — all 12 written; sources labeled, original derivations flagged as such; texrouter's section records the module's not-in-use status

---

## Per-patcher helpfiles

- [x] T010 — f_droste.maxhelp — processor template ✅ 2026-06-06
- [x] T011 — f_stereo.maxhelp — simple processor, no time inlet ✅ verified 2026-10-12 (params/ranges re-checked against definition.py)
- [x] T012 — f_mobius.maxhelp — simple processor ✅ verified 2026-10-12
- [x] T013 — f_chladni.maxhelp — generator; audio companion noted in References ✅ verified 2026-10-12
- [x] T014 — f_stipple.maxhelp — dual-mode generator ✅ verified 2026-10-12 (post-2026-10-05 definition rewrite: params/ranges agree)
- [x] T015 — f_grain.maxhelp — dual-mode generator ✅ corrected 2026-10-12: the External Control block predated the gain/mix rollout (dead `amount`, missing gain/mix, wrong softness range) — fixed against definition.py
- [x] T016 — f_lens.maxhelp — complex processor ✅ corrected 2026-10-12: five dead tilt-shift params removed from the control list (stage moved to f_focus 2026-09-23)
- [x] T017 — f_masonry.maxhelp — verified 2026-10-12 (the "do after masonry stabilizes" gate was met: C-inlet and quantize issues are documented loose threads, module ships)
- [x] T018 — f_channel_grader.maxhelp ✅ verified 2026-10-12
- [x] T019 — f_hue_processor.maxhelp ✅ verified 2026-10-12 (control list matches the shipped definition incl. jsui-driven band params)
- [x] T020 — f_luma_processor.maxhelp ✅ verified 2026-10-12
- [x] T021 — f_tone_curve.maxhelp ✅ corrected 2026-10-12: control block had drifted from the shipped params (shadows/midtones/highlights bipolar, edge_falloff 0–1, crossovers 0–1) — fixed against definition.py + raw_ui.json
- [x] T022 — f_texrouter.maxhelp — assessed 2026-10-12, deliberately NOT made: module confirmed not in use (Matt, 2026-10-09); no codebox, no standard params (16 matrix cells driven by message), no pipeline archetype. Assessment recorded in docs/f-reference/f_texrouter.md's References section. Revisit only if the deprecate-vs-keep decision lands on "keep."

---

Each T01x task is done when:
- [x] Ranges verified from codebox and attrui ✅ 2026-10-12 — all 11 helpfiles' External Control blocks re-checked against src/*/definition.py (+ raw_ui.json where params are raw_ui); three stale blocks corrected (grain, lens, tone_curve)
- [x] docs/f_name.md has ## References section ✅ 2026-10-12 (T004)
- [x] .maxhelp generated from template, opened in Max ✅ generated via the committed pipeline (9126050, 2026-07-19); **re-open-in-Max spot check still owed** — the 2026-10-12 corrections to grain/lens/tone_curve changed only comment text, not wiring or rects, but the demo-visible-output and layout-clean items below should get one Max session across all 11 before this checklist is fully retired
- [ ] Demo produces visible output — needs the Max session above (not scriptable via the codebox bench)
- [x] Layout clean (no clipping, correct column widths) — rects unchanged by the 2026-10-12 text-only edits (JSON diff confirms only comment text changed)
- [x] Committed (this batch: 2026-10-12)
