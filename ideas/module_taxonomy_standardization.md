# Module taxonomy standardization — generator/processor/source distinction

**Status:** Noted, not started. Captured 2026-07-04 during `f_vf_seeds`'
`build_patcher.py` inlet bugfix — deliberately deferred rather than solved
in the moment, per Matt's call: "we're stuck in semantics... let's fix
this module and make a note to standardize generally later."

## The concrete trigger

`build_patcher.py`'s `mod_inlets` mechanism turned out to mean two
genuinely different things depending on the module:

- **Optional secondary modulation** on an otherwise self-sufficient
  generator — `f_vf_vortex`'s cx/cy/convergence/curl mod inlets. No
  driving texture exists; params alone produce output. A dedicated
  control-only `in 1` (bang/render trigger) with modulation starting at
  `in 2` is correct here.
- **Primary required content** — `f_vf_seeds`'s shape tex/vecfield/mod
  tex. The module produces nothing without these; per Vsynth convention,
  inlet 0 needs to carry the driving texture *and* all control messages
  combined, no separate control-only channel.

`build_patcher.py` had no way to distinguish these — it assumed every
`archetype="source"` + `mod_inlets` module was the first kind. Fixed with
an opt-in `driving_inlet` flag (see `.specify/f_vf_seeds/plan.md` ADR 5),
scoped to just this one bug rather than a general schema rework.

## The broader question, not resolved here

"Generator," "processor," and "source" as categories have been fluid
across this library — distinctions generated as needed, not from a
settled taxonomy decided up front. This is fine and probably inevitable
for a library that grows by building real modules rather than designing
a schema first — but the `driving_inlet` case shows a real cost: two
modules can share an `archetype` value and a `mod_inlets` mechanism while
meaning structurally different things by them, and nothing catches that
until it breaks.

Worth a dedicated pass at some point to ask, across the whole library:

- What are the actual distinct *shapes* modules take, independent of
  what they're currently labeled? (self-sufficient-generator-with-
  optional-modulation vs. generator-driven-by-required-external-texture
  vs. true processor-with-passthrough vs. dual-mode — at minimum four
  shapes visible just from this one bug, possibly more once looked at
  directly.)
- Does `archetype` need to grow a value, or does `driving_inlet` (or
  something like it) become a standard second axis alongside it?
- Any other existing modules quietly relying on `mod_inlets` for primary
  content rather than true modulation, undiscovered because they haven't
  hit this specific bug yet? Worth an audit pass, not an assumption
  either way.

## Not scheduled

This is a "worth doing sometime" note, not a queued task. No mechanism
chosen, no priority assigned relative to other open threads.
