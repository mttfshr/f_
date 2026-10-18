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
- [x] T023 — Helpfiles for the remaining shipped GPU modules (2026-10-12): 14 written (f_vf_advect, f_vf_chroma, f_vf_flow, f_vf_glow, f_vf_potential, f_vf_prism, f_vf_repulse, f_vf_seeds, f_vf_split, f_vf_vortex_multi, f_vf_vorticity, f_weave, f_ngon, f_sirds) via build/make_missing_helpfiles.py from the f_vf_vortex template structure; param lists AST-extracted from definition.py (internal/raw_ui params omitted, bypass last). f_Launch.maxpat regenerated: 34 of 39 modules now clickable (was 20). Deliberately still gray: f_a_ripple + f_chladni_audio (audio, no help archetype), f_modules (the menu itself), f_texrouter (confirmed not in use; T022 assessment), f_util_matrix_2 (unfinished draft). f_vf_vorticity's and f_ngon's helpfiles carry their README ⚠ caveats inline; f_vf_chroma's carries the paused-retool note. Same Max-verification session owed as the T011–T021 batch above (demos/layout live).

---

Each T01x task is done when:
- [x] Ranges verified from codebox and attrui ✅ 2026-10-12 — all 11 helpfiles' External Control blocks re-checked against src/*/definition.py (+ raw_ui.json where params are raw_ui); three stale blocks corrected (grain, lens, tone_curve)
- [x] docs/f_name.md has ## References section ✅ 2026-10-12 (T004)
- [x] .maxhelp generated from template, opened in Max ✅ generated via the committed pipeline (9126050, 2026-07-19); **re-open-in-Max spot check still owed** — the 2026-10-12 corrections to grain/lens/tone_curve changed only comment text, not wiring or rects, but the demo-visible-output and layout-clean items below should get one Max session across all 11 before this checklist is fully retired
- [ ] Demo produces visible output — needs the Max session above (not scriptable via the codebox bench)
- [x] Layout clean (no clipping, correct column widths) — rects unchanged by the 2026-10-12 text-only edits (JSON diff confirms only comment text changed)
- [x] Committed (this batch: 2026-10-12)
