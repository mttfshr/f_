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

## Open questions (carry from the spec)

- Optical Flow `temporal`?
- Launcher tab order = menu order (current assumption).
- Modifier-click opens the helpfile?
