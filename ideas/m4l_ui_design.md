# M4L layout: what we would do differently, and what to borrow

_Started 2026-11-17. Companion to `ideas/vsynth_as_m4l_research.md` and `ideas/ui_design_concepts.md`. Written from general knowledge of Live and Max for Live conventions; **nothing here was checked against Live or the current Ableton device set this session.** The two open questions at the end are answered as Claude's recommendations, for Matt to confirm._

## Why layout is a separate question from architecture

The architecture question (how textures cross devices) is in `vsynth_as_m4l_research.md`. Layout is independent: it applies to any `f_` module whether or not it ever becomes an `.amxd`, because most of the changes make a panel easier to use in a Live-like workflow.

## What would change

| # | Change | From | To | Touches |
|---|---|---|---|---|
| 1 | Strip proportions | Tall bpatcher panels | Short, wide device strip (about 170 px tall in Live's device view; check the current height) | Every module; worst for dense ones (`f_separate`, `f_halftone`, `f_lens`) |
| 2 | Fewer visible controls | All params shown | Hero graph or preview plus a small set of macro dials; the rest behind an unfold or advanced section | `G-ui-density` |
| 3 | Live parameter model | Dial names chosen for the panel | Short stable names (Live's automation lists truncate), deliberate choice of which params are automatable, a Macro-friendly set of 4 to 8 per device | `live.*` params, `build/spec.md` naming |
| 4 | On/off | Bypass toggle plus `bypass_gate` Param | One title-bar device on/off driving the same gate | The bypass convention (`G-bypass-native`) |
| 5 | Presets and variation | `pattrstorage` presets, `f_util_vary` | Lean on Live's preset browser, Macro Variations and Randomize where they fit | `ideas/f_util_scoped_presets.md` question 5 |
| 6 | Control modulation | Vsynth LFOs and mod textures | Live's M4L LFO, Envelope Follower and Shaper for control values; keep mod textures for per-pixel modulation only | `f_util_mod_texture.md` |
| 7 | Chain I/O | Implicit patch cords, `vs_inState` timing | Explicit source and destination slot chooser plus a visible "input connected" indicator | Architecture A or C only |

Items 1 to 5 are layout-only and could be tried on one module without any architecture decision.

## Inspirations (to look at, not copy)

- **Ableton's own devices.** Wavetable (compact display plus tabs), Hybrid Reverb (one central graph, a few dials around it), Echo and Drum Buss (title-bar toggles, small clear regions). Lesson: one hero element, few controls.
- **Max for Live stock devices** (LFO, Envelope Follower, Shaper): the reference for dial and label sizes and mapping behavior.
- **Live's Macro Map list:** the growable row list already noted in `f_util_mod_texture.md`.
- **Resolume and VDMX:** effects as stacked collapsible cards, which maps onto Live's device chain.
- **Hardware-style units:** a big preview with a handful of dials beneath it.

## Answers to the open questions (Claude's recommendation, Matt decides)

1. **What drives the redesign first?** The "few macro dials" model (item 2), not the strip proportions. Proportions are mechanical once the visible set is chosen; choosing the set is the design work, and it is the same decision `G-ui-density` is waiting on.
2. **Which device to use as the reference?** Hybrid Reverb, for the pattern of one central graph with a few dials, since most `f_` modules have a natural hero (the plate preview in `f_separate`, the dot pattern in `f_halftone`). Wavetable is the second pick for dense modules. Both are from memory: Matt should open them in Live and say whether they hold up.

## Suggested first experiment (needs Matt's go)

Redesign one dense module, `f_separate`, as a wide strip with a hero preview and 6 macro dials, in a scratch patcher only (no definition change, no build). Judge by looking at it next to a stock Live device.

## Asks for Matt

- Confirm or change the two recommendations above.
- Go or no-go on the `f_separate` scratch experiment.
- Is the density work (`G-ui-density`) the right home for this, or should it get its own gate row? I have not touched `gates.md`.

## Strip experiment (2026-11-18)

Built as `scratch/experiments/m4l_strip_f_separate/f_separate_strip.maxpat` (local, gitignored). Generated once from the real module by `make_strip.py`, then edited by hand: **do not rerun the script, it would overwrite Matt's tweaks.** Max has saved it (9.2.0).

Rounds, with Matt's feedback:
1. Dials for hue, saturation and lightness behind an unfold. Matt: **number boxes for hue, and saturation and lightness in the main panel**.
2. Gain as a dial, then a `live.slider` with its value shown. Finding: `live.slider` cannot place its value readout (the installed `live.slider.maxref.xml` lists only `showname`, `shownumber` and `textcolor`; read 2026-11-18, not tried in Live). Matt: **gain as a number box**.
3. Matt trimmed the panel to about 361 x 125 px and moved Gain to its own row, label on the left, box running to the column edge. Claude then snapped the three Gain boxes to 64 px wide, 40 px in from each column, and the labels to y 102.5.

4. Narrower: Matt asked for a narrower strip. Claude shrank the swatches (90 x 24 px) and columns (pitch 98, number boxes 28 px wide), giving 310 x 105 px. Kept.
5. Narrower still: each ink as a 2 x 2 grid (H S / L Gain), 212 x 122 px. **Rejected** by Matt ("it was better before"): it traded 98 px of width for height and read denser.
6. One ink per tab (`live.tab`, hidden boxes via `script sendbox ... hidden`), 212 x 124 px, `f_separate_strip_tabs.maxpat`. Built; the tab first drew nothing (inferred: `parameter_enable 0` left it without labels; fixed in the file, parameter_visibility 2 unverified). **Rejected** by Matt 2026-11-18: "the tabless version seems better". Reason, inferred: one ink at a time hides the color relationships a three-ink table exists to show. A summary row of color bars was not built.

Where it stands: a 310 px wide strip with the title bar (Separate, Mode, Inks, on/off), then per ink a hero swatch, an H / S / L number-box row and a Gain row. Offline edits only; Matt has looked at it in Max (rounds 1 to 3), the final snap is unlooked-at. Lessons so far: the "few macro dials" rule gives way for a color triple, which reads best as three plain number boxes together; number boxes beat sliders and dials where the value must be readable and placeable.

## Strip experiment 2: `f_vf_erode` (2026-11-18)

Scratch files (local, gitignored): `scratch/experiments/m4l_strip_f_vf_erode/`, generated from the real module (presentation rects only; the three `make_strip*.py` scripts are one-shot, do not rerun after hand edits). Rounds:
1. Nine dials in one row, four groups (Run: flow, push, speed; Pigment: lift, settle; Water: flood, dry; Feed: feed, fade), Wet button at the left, 390 x 95 px. Matt: not better, "just a single row version that's too wide"; **the group labels help a lot**.
2. All number boxes, group columns with labels to the left, 346 x 88 px. Matt: fewer columns, more rows.
3. **Chosen (Matt, 2026-11-18, "this is great"):** all number boxes in two columns of stacked groups, 204 x 146 px: left Run over Pigment, right Water over Feed, labels left of the boxes, Wet at the far left, title bar Erode / Darker-Lighter / on-off. File `f_vf_erode_strip_2col.maxpat`. Looked at in Max by Matt; unverified by Claude: the `dry` readout width (36 px for 0.0016) and whether Wet should move into the gap under Water.

What transfers (inferred from two modules): group headers carry the meaning that dials-in-a-row lose; number boxes beat dials when a module has many parameters and no hero element; trade width for height, since a Live strip has about 170 px of height to spend; keep every parameter visible (tabs and unfolds were both rejected on `f_separate`). Not yet applied to the real modules: `definition.py` and the builder are untouched, and Live was not involved.
