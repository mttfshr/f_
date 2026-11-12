# f_util_scoped_presets

_Captured 2026-11-10 in chat with Matt. Concept only: nothing built, nothing verified in Max. Spike patch is local (`scratch/experiments/scoped_presets/`, gitignored)._
_Status: Idea. Experiment 1 (below) is the next step; its result decides everything else._

## Where it came from

While scoping `f_misregister` (`ideas/f_print_styles.md`, Stage 4) the point was made that Vsynth already has offset, rotation, displacement, sample-and-hold, noise and delay, so a misregistration module would mostly duplicate a chain. What a chain cannot give is **one coherent control surface**: a press pass is a single random event across all plates, and wiring about a dozen LFO and sample-and-hold signals by hand has no single "how worn is the press" knob. That led to Ableton Live's racks and macros, and then (Matt's reframing) away from fixed recipes toward a general utility.

## The idea (Matt, 2026-11-10)

A **custom scoped `pattrstorage` plus a linked parameter list**: pick any chain of modules, encapsulate its state, and present a short, simplified set of dials or sliders over it. Not a set recipe: the user assembles the chain and the control surface.

- **Scope versus exposure.** The store covers everything in the chain (so a preset never loses hidden state); the exposed list is the few controls shown. Two layers.
- **Links.** One exposed control can drive several underlying parameters, each with its own min, max and curve (the Live macro model).
- **Presets.** Save and recall the whole scoped state. `pattrstorage` can also interpolate between two stored presets (`recall 1 2 0.5`), which Live's racks do not do: a "clean press to worn press" slider is a morph between two presets.
- **Sidecar first (Claude's lean, Matt's framing fits it).** The utility sits beside a chain already patched and attaches to its modules by name, so it needs no dynamic placement and works on any hand-patched chain. A container form (the chain lives inside it, like a Live rack) is later and needs machinery that is unproven (`f_addmod.js` places modules by script; connected texture wires inside a container are not verified).

## What the repo already offers (read, not tested)

- Every shipped module's dials are parameter-enabled `live.dial`s inside bpatchers; a saved patcher records them in its `parameters` block under their long names, with `[n]` suffixes where names repeat (seen in `scratch/fresnel_comparison.maxpat`: `strength` and `strength[1]`). A `pattrstorage @parameter_enable 1` should see them. **Unverified.** Repeated names across modules are the fragile part.
- Every module takes named messages on its first inlet (the helpfiles list them), so a macro can also drive a dial by `prepend <param>` without touching `pattrstorage`. Whether a dial moves on screen when driven this way is **unverified**.
- `build/extract_params.py` already extracts name, range, default and hint per module; it could supply the catalog for a link editor (unverified that it is reusable as is).
- The Recipes dropdown in `f_modules` (`f_addmod.js`) places a row of modules; it has no container, shared controls or state.
- Related compaction ideas: `f_util_compound_dial.md` (two parameters in one widget), `f_util_mod_texture.md` and the tagged-texture convention (`P-mod-textures`).

## Experiment 1 (revised 2026-11-10, Matt): the spike IS the `f_misregister` work

Matt's direction: do not test the store on a throwaway chain. Compose a real chain that approaches print misregistration from existing modules, and see whether it gets there or leaves a gap for a module to fill. That chain carries the scoped store as well, so both questions get answered on one real case.

`scratch/experiments/misregister_chain/` (local, gitignored): `build_chain.py` builds `misregister_chain.maxpat`, with `misreg_press.js` beside it. Source into `f_separate`, then three `vs_offset+rot` for the plates and three for faint ghost copies, into a `vs_mixer_6`, with a preview of the misregistered result beside `f_separate`'s own registered preview. The "press" is a small `js`: one random event per sheet, split into a part shared by all plates (`corr`) and an independent part per plate, a leaky random walk for wobble per frame, and a ghost level and offset. Four `live.dial`s (wear, corr, wobble, ghost) plus gofs are the simplified control list, and a `pattrstorage @parameter_enable 1` sits over the whole patch with store, recall and dump. Not in this round, on purpose, because they are the likely gap: a smooth non-rigid paper warp, sharp halftone shifts, registration marks.

**Result (Matt, live, 2026-11-10): the chain works as designed, and the scoped store saves and recalls (so Experiment 1 questions 2 and 4 are answered yes on a real chain; naming of repeated dials was not reported).** The gap he named: **per-plate individual character**, not more transform: differences in ink and color distribution, density, overbleed. Not wanted: vintage-filter looks; wanted: a few performable parameters per plate. Registration marks are out (Matt: "except maybe for registration marks").

Claude's mapping of those phenomena onto what exists (inferred, none of it tried): density = `f_channel_grader` or `f_tone_curve` per plate; uneven distribution and pooling = `f_vf_erode` per plate in Lighter polarity with its own noise texture as the terrain (physical, and Feed makes it live; the 2026-11-09 noise-overlay mottle and dropout failed two live looks as "generic noise", which is the caution); overbleed and dot gain = **CORRECTED (Matt, 2026-11-10)**: Vsynth does have them: `vs_filter_lp2x` / `vs_filter_lp4x` (low-pass, one `cutoff`), `vs_filter_hp4x`, `vs_filter_spat`, `vs_convolve`, plus `vs_comparator` and `vs_duotoner` (threshold and smooth). Spread is a low-pass followed by a re-threshold with a duotoner (which also restores the ink color); Claude's first search used the word "blur" and missed them. So the overbleed gap is smaller than first stated: what remains is whether the result feels like ink and how to reach it. Round 2 of the experiment (`build_chain2.py`, `misregister_chain2.maxpat`) adds a per-plate strip: lp (spread), duotoner (hardness), erode on its own noise terrain (distribution), grader (density), then the offsets, to measure what is left.

The older single-purpose spike (`scratch/experiments/scoped_presets/`) stays as a smaller test of the store alone.

Questions, in order of how much they decide:

(Original, smaller spike) `scratch/experiments/scoped_presets/spike_scoped_presets.maxpat` (built by `build_spike.py` there): a pattern source into `f_channel_grader` (`chain_a`) into `f_luma_processor` (`chain_b`) into a preview, with a `pattrstorage spike_ps @parameter_enable 1`, store, recall and morph controls, and one macro slider driving one dial in each module by message. Questions it answers, in order of how much they decide:

1. Does the `pattrstorage` see the dials of both modules, and under what names?
2. Do store, recall and a morph move the dials and the picture?
3. Does a macro driven by message move the visible dials, and does the store then see the new values?
4. Do presets survive a save and reopen?

If 1 and 2 hold, a sidecar is mostly a UI and a link table. If they fail, the container route or a message-based store is the fallback.

**Update 2026-11-11:** the variation layer (per-plate randomness, chance, wobble) is recorded separately in `ideas/f_util_randomizer.md`; it sits on top of this utility as the second layer (base here, variation there), possibly as one target table.

## Why it matters for the print family

- `G-ui-density`: a handful of exposed dials over a four-module chain is a direct answer to dense panels.
- Print styles as presets (riso, offset, xerox, newspaper) become stored states of one chain instead of new modules (`ideas/f_print_styles.md`, "Other styles as recipes").
- `f_misregister` is **paused, not parked** (Matt, 2026-11-10): this utility is the way to find out whether it needs or can do anything a chain plus a control surface cannot. Candidates that survive: a registration source (seeded per-plate offset, rotation and a smooth warp field with a sheet-change trigger), and registration marks and color bars as a small generator.

## Open questions

1. Container or sidecar for good, or both?
2. Naming: how does a link refer to a parameter that repeats across modules (`strength[1]`)? Scripting names of the bpatchers (`chain_a::flow`) are the obvious candidate.
3. Curves per link (linear, exponential, inverted) and where they are edited.
4. How the link table is authored: text or dictionary first, a Live-style map mode later.
5. Interaction with Max for Live, where parameter automation and macros already exist (not looked at).
6. Whether non-parameter state (a Wet button, a gate) should be in scope.

## Gates this touches

`G-ui-density` (directly), `G-menu` (a new utility needs a place), `P-mod-textures` (only if links drive tagged textures). None cleared or reopened.
