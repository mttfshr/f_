# f_util_vary

_Captured 2026-11-11 in chat with Matt, from the `f_misregister` experiment. Concept only: nothing built, nothing verified in Max for this idea. The name `f_util_vary` was chosen by Matt 2026-11-12 (this note was `f_util_randomizer.md`; `f_util_variance`, `f_util_press` and others were considered)._
_Status: Idea. Companion to `ideas/f_util_scoped_presets.md` (the base layer) and `ideas/f_print_styles.md` (Stage 4, `f_misregister`, now folded in here)._

## Where it came from

The `f_misregister` experiment (`scratch/experiments/misregister_chain/`, local) showed that rigid offset, rotation, wobble and ghosting come from existing Vsynth modules plus a small `js` "press" (Matt, live, 2026-11-10: works as designed, save and recall work). The gap he named was per-plate **character**: ink and color distribution, density, overbleed, as a few performable parameters and not vintage-filter looks. Most of that also exists as chains (`vs_filter_lp2x` or `lp4x` plus `vs_duotoner` for spread and re-threshold, `f_vf_erode` on a noise terrain for distribution, `f_channel_grader` for density). What a chain cannot give is **per-plate variation of those parameters with a statistical flavor**. Matt's idea (2026-11-10): `f_misregister` is an *orchestrator* that lets a scoped-presets surface differ per plate, or add wobble or a percent chance to parameter values. Then (2026-11-11): think of it as a **general randomizer, as a percentage**. This note records that.

## The idea

A utility that, for each parameter in a chosen list, moves the value around its base by an amount thought of as a percentage. Plates are just *groups*; misregistration is one preset of it, not a module.

Per target (any dial in any module, addressed by the module's scripting name and parameter name):

- **Amount (%):** how far it may move, as a percentage of the parameter's range. Works for any parameter without knowing its units.
- **Chance (%):** how often it moves at all per trigger (the "statistical chance").
- **Distribution:** uniform, bell-shaped (most draws near the base), or occasional large jumps.
- **Group and correlation:** targets in a group share part of the draw. For misregistration: one group per plate, offsets highly correlated across plates, densities independent.
- **Wobble:** a slow, leaky per-frame drift on top, with its own size.
- **Trim:** a fixed bias per target (plate 1 always spreads more). This is a plate's personality and is saved in presets.
- **Subrange limit:** a safe min and max per target, so a randomized solver parameter cannot leave a stable range.

Global controls (the ones to perform with): overall **amount**, overall **chance**, a **roll** trigger (what the press script calls `sheet`), **wobble**, and a **seed** so a draw can be recalled ("roll 17"). Effective value, as in the press script generalized: `base + trim + amount * (corr * shared + (1 - corr) * independent) * chance-gate + wobble`, clamped to the subrange.

## How it fits the scoped-presets work

Three layers, in order: **base** (scoped presets: macros and a linked parameter list hold each parameter's intended value) → **variation** (this utility) → **modules**. The base layer owns presets; the variation layer owns the draw.

- **The tension, and the way out.** If a preset stored the *effective* values, recall would freeze one random draw and lose the variation; and a direct turn of a randomized dial gets overwritten on the next roll. So the utility must own the parameters it varies: the store holds the base values and the utility's own controls (amounts, chances, groups, trims, seed), not the effective values. Whether `pattrstorage` can exclude those dials, or whether the controls must be the only things stored, is **untested**.
- **Bake.** A "bake" action turns the current draw into a new preset: randomize freely, keep what you like. This resolves the freeze problem from the other side.
- **One table or two utilities.** Open (Matt asked). Claude's lean: one target table with the two layers in the code (base link plus variation columns), because a second table repeats every row.

## Addressing the targets (planned, untested)

Every shipped module has a scripting name (`erode1`, `density2`) and takes `<param> <value>` messages on its first inlet; Max's `thispatcher` can send them with `script send <name> <message>`. A target table (plate or group, module name, parameter, range, correlation group, chance, trim) plus one `thispatcher` then needs no wire per parameter. Round 1's `misreg_press.js` used a fixed set of outlets instead; the table-driven version would replace them. Unverified: whether a dial moves on screen when driven this way, how repeated parameter names behave, and how many messages per frame are acceptable (send only values that changed, and only on triggers for the non-wobble targets).

## Wiring: the randomizer is the single writer (Matt and Claude, 2026-11-12)

Convention (Matt): inlet 0 of a module is the standard control-message inlet. The textures and vecfields on a module's other inlets never touch the randomizer; it is a control-side sidecar.

- **All scalar params go through the randomizer.** Its outlet is the only wire into the module's inlet 0. Any `name value` arriving at the randomizer is a base: a dial, a preset recall, or an external driver such as an LFO.
- **Output** is `clamp(base + offset)` for every incoming base message. The offset is sample-and-hold per param and changes only on a re-roll (chance, wobble tick, button). A driver that already modulates a param keeps modulating it, with the offset riding on top.
- **Unmanaged names pass through unchanged**, so the randomizer can sit on inlet 0 and do nothing until a table is given.
- **Why not drivers straight to the module:** two writers to one param means the last message wins (the LFO erases the offset, or the wobble tick erases the LFO), and the randomizer would have no base to be relative to.
- **`script send` addressing** writes straight into the dials and would fight any driver on inlet 0. Treat it as the convenience route for the scoped-presets store, not for a chain with live drivers. Still untested.
- **Inferred, not checked:** that every target module accepts plain `name value` messages on inlet 0 (round 1 did this to `vs_offset+rot`), and that signal-rate drivers need a `snapshot~` first.

## Per-param control and UI (Matt and Claude, 2026-11-12)

Every `name value` on inlet 0 is keyed by name, so each param has independent state. Per-param controls: amount (percent of range), chance, group (shared draw, correlation), wobble, trim (safe subrange), lock (pass through). Global amount and chance scale all rows like a macro.

- **Inlets (Matt's decision):** inlet 0 = the base stream (the library convention); inlet 1 = the randomizer's own settings (per-row amount, chance, group, seed, re-roll). A second inlet, not a name prefix, so the settings can be driven by an LFO or preset without colliding with a target's param names.
- **First engine pass (Matt's decision):** the table is text or a dictionary, no UI. The engine decides what the UI must expose.
- **UI sketch for later:** a table of rows (name, base, offset, effective bar; amount and chance editable), a master strip (global amount, chance, re-roll, seed, bake to preset), and a detail editor for the selected row (group, wobble, trim, lock). Rows fill from the scoped-presets param list or by learning names seen on inlet 0.

## Borrowed from Live and Max for Live (Matt and Claude, 2026-11-12; from memory, not verified)

Inspiration: Live's rack Randomize with per-macro exclusion and min/max ranges, Macro Variations (snapshots), the native Random MIDI effect (Chance, Scale, Sign), the Max for Live LFO (random and smooth shapes, Jitter, Depth and Offset), clip note probability, Max's `drunk`.

- **In the first engine pass (Matt):** sign (unipolar or bipolar per row), slew (the offset glides to its new value over a time instead of jumping), and drunk mode (bounded random walk with a step size; bounds reflect or clamp).
- **Later:** beat-synced rate and trigger re-roll, one-step undo of a roll, exclude from global re-roll (lock covers part of it).
- **Per-row mode** is then: uniform re-roll, drunk walk, or smooth wobble. Single writer, per-name state and inlet 1 for settings are unchanged.

## What it takes from the repo

- A per-module parameter catalog: `build/extract_params.py` already pulls name, range, default and hint for `f_` modules (read once, not tested as a catalog source). Vsynth modules are not in it; their ranges would come from the dial attributes.
- Parameter types: floats are the easy case. Menus, toggles and integers need their own rule (pick another item with a chance, not move by a percentage). Some parameters must never be randomized (bypass, the Wet button, anything that resets state); default those to excluded.

## Misregistration as a preset

Offset and rotation targets per plate, one correlation group per drum (a press error is partly shared), a roll trigger, small wobble, plus ghost level and offset. The rest of the print vocabulary (uneven inking, heavy or starved plate, bleed) is the same tool pointed at other targets: spread (`cutoff` and the duotoner threshold and smooth), distribution (`f_vf_erode` flow, flood, Feed), density (`f_channel_grader`). Registration marks are out of scope (Matt, 2026-11-10).

## Possible link (an idea, not looked at)

`f_util_profile` extracts audio and video features. Its outputs could drive the roll trigger or the overall amount, so the randomizer reacts to the performance. How its outlets work was not read.

## Open questions

1. Name: closed (`f_util_vary`, Matt, 2026-11-12). Still open: whether it is one table or two utilities.
2. Container or sidecar (same question as `f_util_scoped_presets`; sidecar first).
3. How to exclude the varied dials from the store, or whether the controls alone are stored.
4. Handling of non-float parameters, and per-target safe subranges.
5. Seeds: one global seed, or one per group; what "roll N" recalls exactly.
6. Message rate and the edit UI for the target table (text or dictionary first, a Live-style map mode later).

## Next step

Generalize `scratch/experiments/misregister_chain/misreg_press.js` into a table-driven engine and test it on the round 2 chain (`misregister_chain2.maxpat`) with three targets per plate: offset x and y, spread cutoff, density gain. That checks the `script send` addressing, whether the dials move on screen, and whether the base and effective split holds. Matt's go is needed first; Matt's round 2 look (five notes at the bottom of that patch) is still owed.

## First engine pass: decided (Matt, 2026-11-12)

- **Output:** the wired single writer (not `script send`). The engine is the only wire into each target module's inlet 0.
- **Keys:** `module.param` (for example `lp1.cutoff`), on every base message in and every row of the table.
- **Seed:** one global seed; each group derives its own stream from it.
- **Table:** plain text, one row per line (target, lo, hi, amount, chance, group, trim, mode, sign); loaded at start.
- **Not decided, Claude's lean:** the js emits one outlet of `module param value`, and a `route lp1 erode1 ...` in the patch fans it to each module's inlet 0 (a js has a fixed outlet count, so one outlet per module would not follow the table).

## Gates this touches

`G-ui-density` (a control surface over many dials), `G-menu` (a new utility needs a place), `P-mod-textures` only if targets include tagged textures. None cleared or reopened.
