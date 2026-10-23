# Spec: `f_modules` Menu Redesign (index sheet + palette window)

**Status**: Specified 2026-10-22. **Revised the same evening: the compact sheet is scrapped; the menu stays as dropdowns** (see Revision). Nothing built.

## Revision (2026-10-22, evening)

Matt saw the sheet mock render (45 names, dots, key). At a legible size it was 2.4x the footprint of today's menu and the dots read as visual noise, so "see it all at once" did not hold. **Decision: keep the dropdown menus (`live.menu`, one per category), with the new grouping.**

- **Still in:** the regrouping below (menu, README and launcher agree), section titles that keep `∇` and `T_`, short labels where a name is too long, and the facts about each module living in the title bars (type dots) after it is placed.
- **Out:** the two-column sheet, the type dots and green temporal dot in the menu, the key, the layout engine and the `jsui`. Everything below that describes the sheet (Row model and marks, Compact sheet, the layout parts of Data model, the layout checks) is **superseded** and kept only as a record.
- **Decided (Matt, 2026-10-22, later):** **no subgroups** (the dropdowns are plain lists, so the Groups table below is the whole design). **Unverified modules stay in the menu as ordinary entries** (no dimming, no mark): Matt wants to see where they fit; the README ⚠ still marks them in the launcher.
- **Order inside a dropdown:** alphabetical, except T_ Fields, which keeps its pipeline order: map, smooth, sharpen (the existing convention). Default, not yet confirmed.
- **Recipes are back (Matt, 2026-10-22), as a tenth dropdown, "Recipes", at the bottom of the menu.** Choosing one places a row of modules, left to right in signal order, unwired (v1). `RECIPES = [(display, [modules])]` in `menu.py` is checked by `generate_menu.py` (at least two modules, all menu modules, unique keys) and written to a generated `RECIPES` block in `f_addmod.js`; the new `addrecipe` function places the row. Recipes are not a README group, so the README/launcher parity ignores them. The panel grew from 380 to 420 px: the 380 was an arbitrary constant, not a limit. Most recipes come from the module sets in `package/examples/f_demo_*.maxpat`.
- **Section-title colors (Matt, 2026-10-22):** `∇ Fields` and `∇ Effects` are drawn in the title-bar vecfield cyan, `T_ Fields` and `T_ Effects` in the tensor amber (a first request had them swapped, and was put back). Other titles stay grey. The colors come from `build_patcher.SIGNAL_TYPE_COLORS` and a test pins them.
- **On hold:** the floating palette window (a larger always-open view in its own window: all groups, a filter, a hover description, recipes). It was designed around the dots and the sheet; it is only built if Matt asks for it.
- **Footprint:** the new grouping has 8 dropdowns (Audio stays out of the menu), one fewer than today. At the current 39 px slot that is shorter than the 380 px panel, so the panel and the example patches that embed it do not have to change.

**Tasks**: `.specify/f_modules_menu/tasks.md`
**Inputs**: `docs/f-reference/module-inventory.md` (the inlet / outlet / driving-texture table of 2026-10-22), `src/f_modules/menu.py`, `build/generate_menu.py`, `build/generate_launch.py`, `build/build_patcher.py` (type dots).

## Problem

The menu is a 96 x 380 px bpatcher with nine `live.menu` dropdowns, one per category. Every module is behind a flyout, and the grouping has drifted from how modules are actually found:

- `∇ Processors` holds 13 of the 45 menu modules in two opposite roles: seven *make* a field (Fieldmap, Flow, Repulse, Optical Flow, Fluid, LBM, Vorticity) and six *use* one (Caustic, Warp, Streak, Glow, Advect, Chroma). `Scope` has 1 module, `Optical` 2, `∇ Generators` 2.
- The `∇` mark is scattered: Prism (Optical), Seeds and Weave (Discrete), Chladni (Scope), Split and Potential (Utilities).
- Names such as `Scope`, `Optical`, `Spatial`, `Discrete` do not say what is inside. Order inside a category is "newest last".
- Modules are found by name, by effect and by "what plugs into what I just placed", depending on the moment. Dropdowns serve none of these well.

## Decisions (Matt, 2026-10-22; items 1 and 4 to 7 were superseded by the Revision above: the sheet, the menu dots and the palette are out or on hold)

1. **No flyouts, no tabs, nothing hidden.** Every module is visible at once.
2. **Regroup by pipeline role** (below). (Subgroup runs were dropped later the same evening.)
3. **Section titles keep the marks** `∇` and `T_`: they teach what the marks mean everywhere else.
4. **Per-entry marks become the title-bar type dots**: a round in-dot and out-dot, cyan = vecfield, amber = tensor, dim gray = neither (colors from `SIGNAL_TYPE_COLORS` / `DOT_NONE` in `build_patcher.py`). Round only; shapes were rejected 2026-10-17.
5. **Three more facts, kept quiet**: *runs with nothing patched in* = no in-dot; *temporal* = one small **soft green** dot at the row's right edge; *unverified* (README ⚠) = the name drawn dimmer. No glyphs.
6. **Two surfaces from one data set**: a compact in-patch sheet (tall, two columns, about 230 x 378) and a floating **palette window** with the full view.
7. **Palette extras**: dim-on-filter text field, hover footer, recipes, audio group.
8. **Not doing**: cross-listing a module in two groups (breaks the rule that the menu, README and launcher agree).

## Groups (menu order = README order = launcher tab order)

45 menu modules, no module listed twice.

| Group | Modules (alphabetical; T_ Fields in pipeline order) |
|---|---|
| Patterns | Chladni, Grain, Kuramoto-Sivashinsky, Masonry, Seeds, Stipple, Weave |
| Space & Optics | Droste, Lens, Mobius, Ngon, SIRDS, Stereo |
| Color / Tone | Channel Grader, Hue Processor, Luma Processor, Tone Curve |
| ∇ Fields | Flow, Fluid, Lattice Boltzmann, Optical Flow, Repulse, Vortex, Vortex Multi, Vorticity |
| ∇ Effects | Advect, Caustic, Chroma, Glow, Prism, Streak, Warp |
| T_ Fields | Tensormap, Smooth, Sharpen (pipeline order) |
| T_ Effects | Aniso Blur, Glyph, Hatch |
| Adapters | Axis Flow, Fieldmap, Potential, Split |
| Routing / Mod | Matrix 2, Profile, Tex Router |
| Audio (not in the menu) | Chladni Audio, Decorrelate, Ripple |

The README table and launcher use the same groups. The Audio group stays `NOT_IN_MENU` (no bpatchers yet). (The earlier subgroup runs, such as warps / projection / optics, were dropped 2026-10-22.) Menu order is README order is launcher tab order.

Why some placements: Chladni and Seeds are Patterns because their main output is an image (Chladni a luma figure; Seeds a mark layer); their dots keep them findable from the vecfield side. Adapters holds modules whose job is to change a signal's type: Fieldmap (texture to vecfield), Split (vecfield to two scalars), Potential (vecfield to scalar) and Axis Flow, the one bridge from the tensor family to the vecfield family. **Tensor split (Matt, 2026-10-22):** the old `T_ Tensor` group became `T_ Fields` (makes or conditions a tensor: Tensormap, Smooth, Sharpen) and `T_ Effects` (uses a tensor to make an image: Aniso Blur, Glyph, Hatch), mirroring `∇ Fields` and `∇ Effects`. Adapters comes after all four, then Routing / Mod. Tensormap stays with the tensor producers, like Flow and Repulse in `∇ Fields`, rather than with the Adapters.

## Row model and marks

One row per module:

```
[in-dot][out-dot]  Name                      [temporal dot]
```

| Element | Rule |
|---|---|
| In-dot, out-dot | From the module's `signal_type` title-bar label, parsed by `build_patcher.parse_signal_type`: `∇` cyan, `T_` amber, gray when that side has neither. A module with no `signal_type` is gray / gray |
| No in-dot | Module flagged `source` (produces output with nothing patched in, even if it accepts an optional input). Differs from the title bar, where such a module's top dot is gray |
| Temporal dot | Module flagged `temporal` (memory or warm-up): soft green, about `[0.45, 0.80, 0.50]`, final value tuned at tier 3 |
| Dim name | README row starts with ⚠ (unverified), read from the README, never duplicated into `menu.py` |

Initial flags (from the inventory; the editorial calls live in `menu.py`):

- `source`: Masonry, Stipple, Grain, Weave, Kuramoto-Sivashinsky, Chladni, Vortex, Vortex Multi, Flow, Lattice Boltzmann.
- `temporal`: Grain, Kuramoto-Sivashinsky, Lattice Boltzmann, Fluid, Advect, Potential, Smooth.
- Open: whether Optical Flow (holds the previous frame) is temporal.

## Compact sheet (in the patch)

- One `jsui`, about 230 x 378 px, replaces the nine `live.menu`s. Click sends the existing `addmod <module>` message to `f_addmod.js`, which inserts at the menu's location as today.
- Two columns, about 115 px each. Groups flow in menu order; the column break falls on the group boundary that best balances height (Fields ends the left column: 29 rows, about 376 px with the subgroup gaps; the right column is 24 rows, about 315 px, leaving room for the key).
- Row pitch about 12 px, 11 pt font (raised twice on 2026-10-22 after Matt saw the mock render: 9 pt / 10 px, then 10 pt / 11 px, now 11 pt / 12 px). The two dots are 7 px with a 2 px gap, side by side (the title bar's stacked pair is 12 px tall, the whole row at this pitch). The name starts near x = 19 and has about 85 px, so some display names need a **short label** (Kuramoto-Siv., Lattice Boltz.).
- Group headings keep their marks (`∇ Fields`, `T_ Tensor`), drawn in the cyan / amber of the type dots. Unmarked headings are a quieter gray, and every heading has a 1 px hairline under it (added 2026-10-22 after the first render, where headings barely stood out from the names).
- A four-row **key** sits in the free space under the right column: cyan *vecfield*, amber *tensor*, gray *other*, green *temporal*; "no left dot: source"; "dim name: unverified". It costs no extra footprint, apart from a few px of height (378 px total). Its lines are measured with the names (T004).
- No filter and no footer. Hover shows a tooltip with the README one-liner if a dynamic hint works (T003); otherwise none.
- The panel height changes from 380: `PANEL_H` and the example patches that embed the menu must be updated together.

## Palette window (floating)

- A separate patcher in `package/extras/`, opened from the Extras menu or a key, `float` on, placed anywhere, zero patch space when closed.
- Same data, four columns, about 530 x 400 px: subgroup label rows, a hover footer (two wrapped lines for the 110-character one-liners), a filter field at the top, an Audio group and a Recipes column.
- **Filter dims, never hides**: entries keep their positions. It matches name, group, subgroup and the words *vecfield*, *tensor*, *temporal*, *no input*, *unverified*.
- **Recipes** are named chains (for example Vortex → Warp; Tensormap → Axis Flow → Advect; Mask → Lattice Boltzmann → Advect). A click inserts the chain's modules in a row; whether it also patches them is decided in T050. Recipe data is its own block in `menu.py`, outside the README parity check.
- A click on a module inserts it into the patcher you were last working in. This is **decision gate G1** (T001); fallbacks are listed in the task.

## Data model (`src/f_modules/menu.py`)

- Each category holds subgroups. Each entry keeps `(display, module, kinds)` and gains `short` (optional), `source` (bool) and `temporal` (bool). `kinds` stays, so the rule that a category titled with `∇` or `T_` holds only modules of that kind stays. The `∇ Fields`, `∇ Effects` and `T_ Tensor` members above all carry the mark; `Adapters`, with no mark in its title, has no constraint.
- `RECIPES = [(short_label, [modules], one_line)]`; every module must exist.
- Type dots and ⚠ are derived, not stored: dots from each module's `signal_type`, ⚠ from the README row.
- Layout (x, y, w, h of every row, heading, gap and dot) is **computed at generation time** (`build/menu_layout.py`), not in the jsui. The jsui only draws and hit-tests precomputed rectangles, so the layout is testable in Python. Both layouts (compact, full) are emitted into a generated block in `package/javascript/f_menu.js` between BEGIN / END markers, the same pattern as the `SIZES` block in `f_addmod.js`; one script, with `jsarguments` selecting compact or full.

## README and launcher

The README `## Patches` table is restructured to the group headings above (`### Patterns`, `### Space & Optics`, `### Color / Tone`, `### ∇ Fields`, `### ∇ Effects`, `### T_ Fields`, `### T_ Effects`, `### Adapters`, `### Routing / Mod`, `### Audio (gen~)`), and `f_Launch` regenerates with those tabs. Rows stay alphabetical in the README. Description text is unchanged (110-character limit).

## Checks (extend `generate_menu.py --check`)

- Every existing check stays: schema, patcher exists, every shipped patcher in the menu or `NOT_IN_MENU`, categories match the README in label, order and members, the mark rule, size overrides.
- New: every `short` fits the name width (estimated, conservative); no overlapping rectangles; the computed sheet height fits the new panel height; flags only on known modules; recipes only reference menu modules; every dot color is one of the three type colors or the temporal green.
- `tests/build/test_menu_layout.py`: tier-1 mirror of the layout and the click-to-module mapping, with mutations (column break, subgroup gap, heading offset, hit-test off-by-one).

## Risks and open questions

- **G1**: insertion from a separate window may not be possible (T001). Fallbacks, in order: track the last active non-palette patcher; or the palette browses and opens helpfiles but does not insert.
- **Title labels drive the dots, so they must be right.** Audited 2026-10-22 (T010): every `signal_type` agrees with the module's outlets. Advect and Prism say `∇ in/out` correctly: each has a third, vecfield outlet (Advect: gradient of the accumulated flow; Prism: weighted dispersion direction). The modules with no label (the color processors, Mobius, Droste, Ngon, Stereo, SIRDS, Lens, Masonry, Stipple, Grain, Tex Router, Tone Curve) have no vecfield or tensor on either side, so gray / gray is correct.
- **Legibility** at 11 pt / 12 px pitch is unproven on the laptop in the dark (T002).
- **Tooltips**: a jsui cannot draw outside its box, so a hover description needs a dynamic `hint` set through `thispatcher` (T003).
- **Embedders**: every example patch embedding the menu at about 96 x 380 must be resized (T033).
- Open: Optical Flow `temporal`, launcher tab order, and whether modifier-click opens the helpfile.

## Verification tiers

Tier 1: layout mirror and mutations (above). Tier 2: `generate_menu.py --check`, `generate_launch.py --check`, `test_launch`. Tier 3 (Matt's eyes in Max): legibility, dot colors, hover, insertion, palette placement.
