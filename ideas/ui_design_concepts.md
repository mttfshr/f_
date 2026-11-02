# UI and design concepts for f_ panels (toward a design skill)

## Status: OPEN for discussion, started 2026-11-01. Nothing here is decided.

**Aim (Matt, 2026-11-01):** talk through UI and design concepts until we can write a skill that describes the best
set of design concepts for us, so a panel (a new module, or a rework like `f_weave`) comes out clear without
re-deriving the rules each time. This file is the thinking space; the skill is the outcome. Claude's critiques below are
proposals from screenshots, not tested, and Matt chose not to apply any of them yet.

Touches gate **`G-ui-density`** (`.specify/gates.md`: "Direction for UI density / control-surface design", decider Matt).
That gate is the same question this file works on; if a direction lands here, the gate row is where it gets recorded.

## What already exists (read, not run)

- **`skills/vsynth-bpatcher/SKILL.md`**, "UI Styling": Ableton Sans Light everywhere; title 12 pt, param labels 9.5 pt;
  black panel with the blue border `[0, 0.035, 0.227, 1.0]`; dials `activedialcolor` 0.8 grey, `triangle: 1`,
  `valuepopup: 1`; numboxes 34 x 15 in presentation. "Not every parameter earns a panel slot": a slot is for a
  performable lever, correctness settings go in the shader at a measured default (`"ui": False`).
- **Builder defaults (`build/build_patcher.py`):** a 5-column grid, 37 px pitch, rows 62 px apart; dial 27 x 43; a label
  is a 50 px comment box 18 px above its control, centred; numbox 34 x 15; `text_button` (two states, one label at a
  time) and `live.menu` exist; menus and buttons take their width from the text. Any of it can be moved with
  `overrides` (`presentation_rect`, colours, fonts, `hidden`). Captions and headings are not generated; they need raw
  comment boxes. A front/back split exists (`panel_toggle`), but it writes a JS file into `package/javascript/` even for a
  scratch build (known gap, `build/spec.md`).
- **Precedents in the library:** `f_grain` (a small numbox directly under the dial it affects, Mix in the header,
  short labels such as "Soft", "L.gate", "S.var"); `f_lens` (the four `*_mod` depth dials live on the back panel);
  `f_weave` scratch copy (below).
- **Earlier thinking:** `ideas/mod_depth_ui_density.md` (2026-09-20, paused): the problem as "higher density of
  information while maintaining legibility and clickability", sharpened to **performing in the dark**; five concepts
  sketched (two-zone fused control, single-strip dual marker, reveal-on-engage, panel-wide mode flip, XY pad); two Max
  facts found by hand: `live.numbox` has a native bipolar `appearance` mode and its height is locked in every mode but
  LCD. `ideas/f_util_compound_dial.md` is blocked on this same question. Matt meant to review Max4Live devices for prior
  art; there is no record that he did.

## What the `f_weave` panel session showed (2026-11-01, scratch copy only)

The panel went from a 5-column grid of 15 controls (3 rows, 220 x 219) to a 6 x 2 grid (232 x 194) in about eight
passes. Along the way, from Matt's screenshots and our own misses:

- Moving controls is cheap once a layout is a small block of `overrides`; most of the time went on discovering rules by
  hitting them (`text_button` has no label box, a label box is wider than its text, a menu needs about 44 px, a numbox
  may touch its dial by 1 px, the first column's label clips at the panel edge).
- Two labels collided on screen ("Noise freq" into "Tex mode"), and a value readout under a dial plus a numbox under
  that read as two numbers for one control until the numbox was tinted.
- The depth numboxes (tinted blue) and the toggle that governs them (grey) look unrelated; the stale blue `∇ in`
  header glyph is the loudest colour on the panel.

**Result:** the compact panel (two dial rows, depth numbox under each modulated dial, Variant menu and Tex uni/bi toggle in the title bar, label hidden, gray type dots) was promoted to the shipped `f_weave` on 2026-11-01; its layout is `patcher["overrides"]` in `src/f_weave/definition.py`. It is the first real test case for whatever skill comes out of this file.

## Design assessment of the 2026-11-01 panel (Claude, from a screenshot; Matt: apply none yet)

Offered as candidate principles to argue with, not findings:

1. One colour, one meaning, carried through every control it governs.
2. Fix header noise: a stale or decorative glyph should not be the loudest thing on the panel.
3. A caption should say what a colour means, not use placeholder-style text, and be quieter than a control label.
4. Groups should be visible: related controls adjacent, a gap or hairline between groups, no unfinished-looking gaps.
5. One rule for label vocabulary (full words, or short forms, not a mix).
6. Reference text (captions) weighs less than control names.

## Concepts to talk through

Each is a question, with what we know. Add, strike or reword freely.

1. **Perform versus set-and-forget.** The skill's rule says a slot is for a performable lever. Where do set-and-forget
   things live (depth numboxes, mode toggles, correctness values): same panel, smaller, back panel, hidden until
   connected? Is "dim = set once" a visual rule?
2. **Grouping and proximity.** Rows as groups, captions, hairlines, or just spacing? Is grouping by function (marks,
   irregularity, modulation) or by how often it is touched?
3. **Colour semantics.** The panel is black with 0.8 grey dials and a blue border. What do we allow colour to mean:
   modulation, mode, state (engaged), danger? How many colours before it is noise? Does the blue family belong to the
   border, to texture modulation, or to the signal-type glyph?
4. **Visual hierarchy, in the dark.** What should the eye hit first, second? Label weight versus value weight versus
   caption weight. Minimum font size and contrast we accept for stage conditions.
5. **Label vocabulary.** Full words ("Softness"), clipped ("Soft"), or per-module? A slot is 37 px and a label box 50 px:
   a max characters rule would remove collisions. Same name for the same idea across modules (`density`, `weight`)?
6. **Hit targets.** Dial 27 x 43, numbox 34 x 15, button height 17. What is the smallest we accept for a control reached
   mid-performance? Is a numbox a set-up control only?
7. **The mod-depth pattern.** A numbox under the dial (f_grain, weave), a back panel (f_lens), reveal on engage, a ring
   on the dial. When does each earn its place? Should depth show only when something is connected?
8. **Mode controls.** The builder gives a one-label toggle or a menu. A mode (unipolar/bipolar, edge, variant) wants both
   states visible at once; a segmented control is not available. Menu, toggle, or two buttons?
9. **Header contents.** Title, signal-type glyph (`∇` marks vecfield modules), bypass, a global mode. What belongs, and
   what must be true for the glyph to stay (it is stale on the shipped `f_weave`)?
10. **Panel size and rhythm.** Columns of 37 px and widths that are multiples of it, common panel sizes so stacked
    bpatchers line up in a patch. Does a patch full of f_ modules need a shared footprint?
11. **Empty slots and symmetry.** Is an empty cell a smell, or fine breathing room?
12. **Where explanation lives.** In the panel (caption), the hint (mouseover), or the helpfile? What is allowed on the
    panel itself?
13. **Cross-module consistency.** Same order of dials, same position for the same idea, same colour for the same state.
    How strict, and is it worth regenerating old panels?
14. **Front/back panels.** When is a second face worth the toggle, given the scratch-build JS side effect?
15. **Dials versus numboxes versus menus for the same thing.** What decides: precision, speed, range, discrete values?

## Constraints any concept has to live inside

- Generated modules lose hand-tweaks on regeneration; hand layout belongs in `overrides` (`build/capture.py` can write
  Max edits back). Four modules have their own `build_*.py` and no overrides.
- `text_button` has no label box and one text at a time; menus and numboxes size from content or are locked (numbox
  height); there is no segmented control or icon support in the builder.
- Captions and section headings need raw comment boxes; they are not part of the schema.
- Theme-bound colours (`expression: ""`) are what Max writes by default; a custom colour must be set explicitly (the
  library's saved numboxes carry `activebgcolor`).
- The panel is judged live in Max, often in the dark; nothing in this file has been checked against real stage
  conditions.

## How we could get to a skill (a suggestion, not a plan)

1. Talk through the concepts above; keep the ones Matt actually holds as rules and drop the rest.
2. **Audit what exists:** a small read-only script over `package/patchers/*.maxpat` to list panel size, control counts,
   label lengths, colours in use, and which modules use a back panel. Plus 5 or 6 screenshots of the panels Matt likes
   and dislikes. The audit shows what "how we do it today" is before we decide what it should be.
3. Look at prior art (the Max4Live review Matt planned; Ableton's own device conventions, since the library uses `live.*`
   objects).
4. Draft the skill as principles + a checklist + before/after examples taken from `f_weave`, then try it on one real
   rework (weave first) and revise.
5. Decide where it lives: a new skill (for example `f-ui-design`) or a section of `vsynth-bpatcher`, which is already
   about 1,080 lines. A new skill must be uploaded and stamped (`skills/check.sh stamp`).

## Questions for Matt

- Is there one panel in the library (or in Max4Live / Ableton) you consider the best, to use as the reference?
- Skill type: a short list of rules, or a review checklist Claude runs on a layout (including a "designer critique"
  pass like the one above)?
- How much does performing in the dark constrain us, concretely (minimum label size, minimum target size)?
- Should the skill apply to old modules too, or only to new panels and reworks?
- Does this file replace `ideas/mod_depth_ui_density.md` as the home for the UI thread, or sit beside it?

## Where this is tracked

`G-ui-density` (`.specify/gates.md`), `ideas/mod_depth_ui_density.md`, `ideas/f_util_compound_dial.md`,
`.specify/f_weave/tasks.md` T064 (the weave panel is the first test case), `skills/vsynth-bpatcher/SKILL.md` "UI
Styling". The scratch panel is `scratch/experiments/f_weave_character/` (local only).
