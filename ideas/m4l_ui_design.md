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
