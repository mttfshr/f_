# Idea: a build process for `f_a_` (audio) modules

_Created: 2026-09-16_
_Status: Scoped, not started. Follow-up project, not blocking `f_a_ripple`
or `f_a_purr`._

## Origin

Both `f_a_purr` and `f_a_ripple` have reached the same open question in
their `plan.md`s: Phase 4 (production build) has "no `definition.py`
equivalent... for `f_a_` modules yet." Surfaced explicitly while deciding
what "finishable" means for `f_a_ripple` — worth scoping the question
once, here, rather than re-deriving it per-module.

## The actual question

Can the existing `build/build_patcher.py` (which generates `f_` visual
modules from a `definition.py`) be extended to cover `f_a_` audio
modules, or does audio need a separate build path?

## What's in `build_patcher.py`, and which half applies

Read the whole script 2026-09-16. It splits cleanly into two halves.

**Tied to `jit.gl.pix`/Vsynth specifically — does not carry over:**
- `routepass jit_gl_texture jit_matrix` and `jit_gl_texture`-typed
  outlets — there's no texture in an `f_a_` module.
- `vs_inState` on modulation inlets — texture-state tracking, meaningless
  for a control-rate float feeding a `gen~` `Param`.
- `gen_subpatcher()`/`pix_box()` — the core-object builder. Emits a
  `classnamespace: "jit.gen"` subpatcher wrapped in
  `jit.gl.pix vsynth @name ...`, with `r draw` render triggers and the
  pix codebox dialect. Every `f_a_` scratch patch built so far
  (`f_a_ripple_scratch_t*.maxpat`) uses `classnamespace: "dsp.gen"` plain
  `gen~`, no `r draw`, and the `Param`/`History`/`Data` keyword syntax —
  a genuinely different sub-language (see `gen-tilde-codebox/SKILL.md`,
  in the `claude-scaffold` repo), not a parameter tweak on the existing
  function.
- `moduleSize.js` — reports the GL panel's `presentation_rect` for
  Vsynth's texture-sizing system. No equivalent concept for a pure audio
  generator.

**Generic Max UI plumbing — agnostic to what's underneath:**
- `dial_box`/`numbox_box`/`menu_box`/`label_box`/`attrui_box` + the
  `route`-dispatch wiring: `live.dial → attrui → param_connect`, works
  identically whether `param_connect` targets a `jit.gl.pix` or a `gen~`.
- `panel_box`/`title_box`, `panel_toggle` front/back switching,
  `range_tier_boxes` — UI chrome, agnostic to the core object.
- The bypass mechanism's *shape* (jsui toggle → prepend → target)
  carries over, though its *semantics* would change (texture passthrough
  vs. audio dry/wet or mute).

## Candidate approach

Not "extend `build_patcher.py`" and not "write an unrelated second build
script from scratch." Write a new core-object builder — the `gen~`/
`dsp.gen` equivalent of `pix_box()`+`gen_subpatcher()` — targeting the
actual dialect already hand-written in the `f_a_ripple`/`f_a_purr`
scratch patches, and reuse the UI-parameter-grid half (as-is, or via a
light refactor that parameterizes the "core object" builder rather than
hardcoding `jit.gl.pix`).

## Not yet decided

- Whether to refactor `build_patcher.py` in place (parameterize the core-
  object builder) or write a new sibling script that imports the reusable
  UI-generation functions.
- What audio-specific schema concepts are needed beyond what visual
  modules have — e.g. `dac~`/signal-outlet wiring, bypass semantics for
  audio (mute vs. dry passthrough), whether `mod_inlets`' texture-state
  framing (`vs_inState`) has any real audio-domain analogue or just
  doesn't apply.
- Priority — not scheduled. Comes up for real once either `f_a_purr` or
  `f_a_ripple` reaches Phase 4 and someone actually wants to package a
  scratch patch into a shipped module.
