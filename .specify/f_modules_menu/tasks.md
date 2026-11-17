# Tasks: `f_modules` Menu Redesign

**Spec**: `.specify/f_modules_menu/spec.md`
**Build order**: Phase 0 first (scratch tests in Max, decision gates), then Phases 1 to 4 in order. Phase 5 (recipes) is later.
**Commits**: Matt commits manually, after each verified phase.

**REVISED 2026-10-22 evening: the compact sheet is scrapped; the menu stays as dropdowns.** Phase 2 (layout engine) and Phase 3 (compact sheet) are superseded; Phase 4 (palette) is on hold; Matt asked what it was and has not asked for it. Phase 1 (data, README, launcher) is unchanged and is the next real step. The Phase 0 probes in `scratch/menu_phase0/` are kept as a record (the sheet mock is no longer needed; T001 and T005 matter only if the palette stays).

**Recipes added 2026-10-22 as a tenth dropdown (T050 v1); panel now 420 px.** **Phase 1 and the dropdown build (T011 to T014, T035, T036) done 2026-10-22, then `T_ Tensor` split into `T_ Fields` / `T_ Effects` with Axis Flow moved to Adapters, and section titles colored (`∇` cyan, `T_` amber); T037 (Matt's eyes in Max) is the open step.**

**Status 2026-10-22 (before the revision):** specified. Phase 0 probes written and syntax-checked. Matt opened `menu_sheet_probe` the same evening and shared a screenshot (renders correctly: dots, gaps, green marks, colored headings) and asked for everything to go up one point; the console output (T003 tooltip, T004 widths) and the palette probe (T001, T005) have not been reported yet: `scratch/menu_phase0/` (`make_probes.py` regenerates the three `.maxpat` files). Open `menu_sheet_probe` for T002 / T003 / T004, and `menu_target_probe` plus `menu_palette_probe` for T001 / T005. The mock first measured 190 x 317 px at 9 pt; after Matt saw it render (legible, T002 effectively passed) everything went up one point twice: now 11 pt, 12 px pitch, 7 px dots, 230 x 378 px, with the key and quieter headings (both added the same evening). Nothing else built.

---

## Phase 0 — Scratch tests in Max (no repo changes; gates the design)

- [ ] T001: (G1) Insertion from a floating window. In a scratch patcher with `float` on, a `js` calls `max.frontpatcher` and inserts a bpatcher into the patcher you were last working in. Record what it returns when the palette itself is active. Fallbacks: (a) track the last active non-palette patcher with a poll; (b) the palette browses and opens helpfiles but does not insert. Decide which ships.
- [ ] T002: Legibility. A scratch jsui at 11 pt, 12 px row pitch, 7 px dots on the laptop, in a dark room, with the real cyan / amber / gray / green. Adjust pitch or font if it fails.
- [ ] T003: Hover description. Can the jsui set its own `hint` through `thispatcher` (`script sendbox ... hint`) on hover so the tooltip shows the README one-liner? Record yes or no.
- [ ] T004: Text measure. Measure real name widths at 11 pt (`mgraphics` text measure) for all 45 display names; set the short-label list and the width estimate the checks use.
- [ ] T005: `float` window and opening it from the Extras menu (or a key) alongside `f_Launch`.

## Phase 1 — Data, README, launcher

- [x] T010: Audit every module's `signal_type` against its real outlets and inlets. **Done 2026-10-22, read-only:** all 45 menu modules agree. Advect and Prism's `∇ in/out` is correct (each has a third vecfield outlet). The audit instead found three errors in `docs/f-reference/module-inventory.md` (Prism and Advect outlet counts, and `f_grain`, which has 3 outlets, not 1), now corrected. Cosmetic: `f_vf_chroma`'s second outlet is commented `streak` in its definition (a copy-paste label; not a type issue).
- [x] T011: Schema in `src/f_modules/menu.py`: keep `(display, module, kinds)`; add `short` only if a name proves too wide. No subgroups, no `source` / `temporal` flags, no `RECIPES` (all belonged to the scrapped sheet and palette). Existing output stays identical until T012. **Done 2026-10-22:** kept `(display, module, kinds)` unchanged; no new schema was needed.
- [x] T012: Regroup the 45 modules into the nine groups of the spec (Audio stays `NOT_IN_MENU`). **Done 2026-10-22:** `src/f_modules/menu.py` regrouped, then the Tensor group split the same evening: 9 categories, 45 modules, alphabetical (T_ Fields in pipeline order).
- [x] T013: Restructure the README `## Patches` table to the new group headings; keep rows alphabetical; keep descriptions. **Done 2026-10-22:** README Patches table restructured to the 9 groups (46 rows moved, descriptions untouched; `f_modules` now sits in Routing / Mod).
- [x] T014: Regenerate `f_Launch` (`build/generate_launch.py`); `test_launch` passes; `generate_menu.py --check` passes. **Done 2026-10-22:** `generate_launch.py` (9 tabs, 49 modules) and `generate_menu.py` regenerated; both `--check` pass; `test_launch` 8/8, `test_module_contracts` 9/9, `test_generate_menu` 15/15 (its negative tests were tied to the old categories by position and now find categories by content).

## Phase 2 — Layout engine and tier-1 mirror (SUPERSEDED, sheet scrapped)

- [ ] T020: `build/menu_layout.py`: pure function from the menu data to rectangles for the compact (two-column) and full (four-column) layouts, including headings, subgroup gaps, dots and the column-break rule.
- [ ] T021: `tests/build/test_menu_layout.py`: row counts per group, no overlaps, heights, column balance, `short` fit, click-to-module mapping; mutations (column break, gap, heading offset, hit-test off-by-one).

## Phase 3 — Compact sheet (SUPERSEDED; replaced by the dropdown task below)

- [ ] T030: `package/javascript/f_menu.js`: draws the precomputed rectangles, type dots, temporal dot, dim names, colored `∇` / `T_` headings; hit-tests; click sends `addmod <module>`. Tooltip per T003.
- [ ] T031: `generate_menu.py` emits the jsui and the generated layout block into `f_menu.js`; `f_modules.maxpat` loses the nine `live.menu`s.
- [ ] T032: New panel size; replace the `PANEL_H` check with the computed sheet height; update `SIZES` generation as needed.
- [ ] T033: Find every patcher embedding the menu (`grep f_modules` in `package/**/*.maxpat`) and resize.
- [ ] T034: Matt's eyes in Max: legibility, dot colors, click insertion, a module added to a real patch.

## Phase 3b — Dropdown menu with the new grouping (replaces Phases 2 and 3)

- [x] T035: `generate_menu.py` emits the 8 new `live.menu` categories from the regrouped `menu.py` (alphabetical; Tensor in pipeline order; no subgroups); `f_modules.maxpat` regenerated; `SIZES` unchanged. Unverified modules are ordinary entries. **Done 2026-10-22:** `f_modules.maxpat` rebuilt with 9 `live.menu`s (7, 6, 4, 8, 7, 3, 3, 4 and 3 entries); `SIZES` block regenerated.
- [x] T036: Keep the panel at 380 px if the 8 categories fit (they should: 8 x 39 + 25 < 380) so the example patches need no change; otherwise follow T033. **Done 2026-10-22:** panel stays 96 x 380; the last category ends at 375 px (of 380), so the example patches need no change.
- [ ] T037: Matt's eyes in Max: the dropdowns, the new category names, the headings with `∇` and `T_`.

## Phase 4 — Palette window (ON HOLD, decide first)

- [ ] T040: Generate `package/extras/f_modules_palette.maxpat` (four columns, subgroup labels, Audio group, hover footer with two wrapped lines).
- [ ] T041: Filter field that dims non-matching entries (name, group, subgroup, *vecfield*, *tensor*, *temporal*, *no input*, *unverified*).
- [ ] T042: Insertion per the T001 outcome; Audio entries dimmed and not insertable.
- [ ] T043: Extras entry and key; `float`.
- [ ] T044: Matt's eyes in Max.

## Phase 5 — Recipes (later)

- [x] T050: (v1 done 2026-10-22) Recipes as a tenth dropdown that places a row of modules, unwired; `RECIPES` in `menu.py`, `addrecipe` in `f_addmod.js`, checks and tests in `generate_menu.py` / `test_generate_menu.py` (17/17), `test_launch` skips the Recipes dropdown. 12 recipes (11 from the demo patches, 1 not). **Not yet:** auto-patching the chain; trying `addrecipe` in Max (it is parse-checked only); resizing the 20 patches that embed the menu to the new 420 px panel.

## Phase 6 — Docs

- [ ] T060: Update `.specify/plan.md` (menu entry), README repo-structure and menu description, and the `menu.py` docstring; mark this spec Implemented.
- [ ] T061: Refresh `docs/f-reference/module-inventory.md` section order to the new groups.

## Phase 7 — Audio category (audio archetype Phase D, added 2026-11-16, Claude; Matt's go "as proposed"; BUILT offline 2026-11-16, Max look owed, T076)

Source: `build/spec.md` "Audio archetypes" Phase D; the decision of record is `G-audio` (Matt, 2026-11-16: `f_a_*` modules are bpatchers in the `f_modules` menu under an Audio category, and in the `f_addmod` size table). This reverses the 2026-10-22 line of this folder's spec ("Audio stays out of the menu", "no bpatchers yet"), which stays as history. `G-menu` (the redesign) is Matt's and in progress, so everything here is provisional and marked so. Facts read this session from `src/f_modules/menu.py`, `build/generate_menu.py`, `package/javascript/f_addmod.js`, `README.md` and the example patches (not run).

Constraints found by reading: `generate_menu.py` requires the menu categories to match the README groups by label and order, and a README group the menu does not show to hold only `NOT_IN_MENU` modules; the README heading `### Audio (gen~)` already maps to the label `Audio`. The menu panel is 420 px high and fits 10 slots (9 categories plus Recipes: 25 + 39 x 9 + 38 = 414 px); an eleventh needs 453 px, so the check fails until `PANEL_H` grows or the slots shrink. The example patches embed the menu at heights from 249 to 430 px (most at 420; several at 380 and so already clip their last slot).

- [x] T070: `src/f_modules/menu.py`: an `Audio` category last (so menu order is README order): Decorrelate (`a_decorrelate`), Purr (`a_purr`), Ripple (`a_ripple`), kinds `N` (no vecfield or tensor mark); the three `NOT_IN_MENU` entries removed (`f_chladni_audio` stays, unverified, no bpatcher). Placed provisionally (a comment says so, as for Stamp and Halftone).
- [x] T071: Panel height (Q1): `PANEL_H` 420 -> 460 in `build/generate_menu.py` so the eleventh slot fits (`needed` = 453). The generated `f_modules.maxpat` is regenerated; the example patches keep their embed sizes (not touched, per the standing rule on demo patches), so where an embed is 420 px high the lowest dropdown (Recipes, now at y 415) is cut off until that embed is resized.
- [x] T072: Regenerate `package/patchers/f_modules.maxpat` and the `f_addmod.js` SIZES block (`build/py.sh build/generate_menu.py`, then `--check`): the three audio modules get their panel sizes (330 x 152, 330 x 276, 330 x 152), read from the built patchers, no override needed. `place()` needs no change (a bpatcher is a bpatcher; audio ports are `inlet~` / `outlet~` inside, nothing is wired by the menu).
- [x] T073: README Audio table (`### Audio (gen~)` -> `### Audio`, since one module is `pfft~`): honest one-liners of at most 110 characters for the three rebuilt modules (the `f_a_ripple` row still says "Unfinished ... UI and docs pending", the `f_a_decorrelate` row says "shipped and documented 2026-10-12"; both are out of date). The warning marks stay on all four until Matt has heard them (T013 / T047 / T024 of the three modules). `build/py.sh build/generate_launch.py` regenerates `f_Launch` (the Audio tab already exists; the modules stay grayed: no helpfile, and the helpfile shape for audio is a separate item).
- [x] T074: A test in `tests/build/test_build_audio.py`: every `audio_*` definition's module is in the menu (a category, not `NOT_IN_MENU`) and its SIZES entry equals its presentation panel; mutant: a module moved to `NOT_IN_MENU`. Then `test_generate_menu.py`, `test_launch.py`, `test_build_audio.py`, `test_drift.py`, `test_gates.py`, all `-q`, with Matt's go.
- [x] T075: Records: this folder's spec (dated amendment lines where it says Audio stays out), `docs/f-reference/module-inventory.md` (no `f_a_purr` row; the `f_a_ripple` and `f_a_decorrelate` rows still describe the hand-built prototypes), the three modules' tasks (`f_a_purr` T028 ticked), `build/spec.md` status, `G-menu` row (Audio category added provisionally), `G-audio` (Q2), `.specify/plan.md` "Owed to Matt" (the audio Max checks), `HANDOFF.md`; one commit.
- [ ] T076 (owed to Matt, Max, not claimed by Claude): open `f_modules` in Max, the Audio dropdown (three names), insert each module into a patch (size, no clipping, bpatcher opens, `pfft~` inner file found for Decorrelate), the Recipes dropdown still reachable at the new panel height; the launcher's Audio tab.

### Decided 2026-11-16 (Matt: "Go, as proposed")

1. **Panel height.** Proposal: grow the panel to 460 px (T071), accepting that example patches embedding it at 420 px or less lose the bottom of the menu (Recipes) until you resize them; I do not touch the demos. Alternatives: (a) keep 420 and shrink the slot pitch to about 35 px, which overlaps the 38 px label-plus-menu slot by 3 px (look unverified); (b) leave audio out of the menu until your `G-menu` redesign lands and register only the `f_addmod` sizes (that reverses the 2026-11-16 decision for now).
2. **The `G-audio` row.** After Phase D every part of its original question is answered and built. Proposal: remove the row (the record is in the three modules' tasks, `build/spec.md` and `HANDOFF.md`), put the audio Max checks in `.specify/plan.md` "Owed to Matt", and move `f_chladni_audio` (T123, unverified, no bpatcher) to a one-line Parked row. Or keep the row until the Max checks pass.
3. **README heading.** Proposal: rename `Audio (gen~)` to `Audio`. Say if you would rather keep it.

### Phase 7 record (2026-11-16, Claude, offline)

- Built: `Audio` category in `src/f_modules/menu.py` (Decorrelate, Purr, Ripple; three `NOT_IN_MENU` entries removed); `PANEL_H` 460; `f_modules.maxpat` and `f_addmod.js` regenerated (sizes 330 x 152, 330 x 276, 330 x 152); README Audio heading is `Audio` and the three rows are honest (⚠ kept); `f_Launch` regenerated; `module-inventory.md` updated (`f_a_purr` row added).
- Found and fixed on the way: `test_generate_menu.py` showed the audio shells had no title-bar type dots (every other module has two gray-or-colored dots left of its name); `build_audio()` now writes the two dots (gray: no vecfield or tensor), and the three audio patchers were rebuilt (`drift.py` ok for all). `test_generate_menu.py` also had one case that used the Audio group as its example of a group the menu does not show; it now hides the Audio category for that case.
- Run offline (all `-q`; `tests/logs/20261116-234724-offline.log`): `test_build_audio.py` 8/8 (new: audio modules are in the Audio category and their f_addmod size is their panel), `test_generate_menu.py` 17/17, `test_launch.py` 8/8, `test_drift.py` 16/16, `test_gates.py` 5/5, `test_build_conventions.py` 40/40, `test_layout.py` 11/12 (the known `f_vf_erode` pair).
- Not verified: everything in Max (T076); how the menu column looks at 460 px; that the example patches embedding it at 420 px or less now cut off its bottom (Recipes), inferred from the arithmetic, not looked at (the demos are not touched).

## Open questions (carry from the spec)

- Optical Flow `temporal`?
- Launcher tab order = menu order (current assumption).
- Modifier-click opens the helpfile?
