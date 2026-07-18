# f_vf_channelmap (working name) — direct channel-to-vecfield reinterpretation

**Status:** idea only, not specced, not scheduled. Surfaced 2026-07-17
mid-session while scratch-testing the frame-diff → `f_vf_fieldmap`
approach for `f_vf_optical_flow`. Not naming-locked.

## Core idea

A vecfield-originator utility that reinterprets two existing channels
of *any* incoming texture directly as vector x/y components, rather
than deriving a vecfield through gradient computation the way
`f_vf_fieldmap` does. Zero-computation reinterpretation: pick a
channel for X, pick a channel for Y, remap `[0,1] → [-1,1]`, done.

This is the direct structural inverse of `f_vf_split`, which already
exists and does the opposite: vecfield → 2 monochromatic scalar
textures. `f_vf_channelmap` closes the loop as the counterpart:
scalar/RGBA texture → vecfield.

## Motivation

Surfaced as a tangent from the optical-flow thread: an RGB texture
already has R/G/B/A planes sitting right there, and a frame-diff image
in particular might carry usable directional information in its raw
channels even without a proper gradient derivation. But the utility is
general-purpose beyond that one use case — anything that hands you an
arbitrary texture with two channels worth reinterpreting as direction
becomes a candidate: normal maps (R/G as flow direction), hand-authored
or found textures used as a drawn-in flow field, any existing `f_`
scalar output repurposed as a vecfield source without needing a new
gradient-based module for each one.

**Supersedes `ideas/f_vf_normal.md` (2026-06-16, folded in here and
deleted).** That file captured the same core mechanism — RG channels
of an input texture reinterpreted as XY vecfield components — motivated
specifically by normal-map assets: normal maps are already encoded as
RG textures with 0.5 = zero, the same convention as `f_vecfield`, and
tools like `jit.gl.bfg` (normal output), 3D render passes, and
image-processed surfaces all produce this format with no clean route
into `f_vf_` consumers except going through `f_vf_fieldmap` (which
re-differentiates a scalar and loses the original directional
information rather than passing it through). `f_vf_channelmap`
generalizes that idea: fixed R/G-only becomes just one configuration of
a selectable R/G/B/A/Luma pair. That file's proposed `strength`
(scale) and `invert_x`/`invert_y` params are worth reconsidering against
this file's "no gain knob, per-axis invert only" default (see Proposed
default scope) — `f_vf_normal` wanted a strength scale specifically so
1.0 = pass-through and lower values reduce field magnitude; whether
that's better living here or purely downstream in a consumer's `gain`
is an open question, not yet re-resolved. Also worth reusing:
`f_vf_normal`'s framing of itself as "essentially the inverse of
`f_vf_fieldmap`" and its instinct that `jit.gl.bfg` normal output might
already wire directly into `f_vf_` consumers without needing any
adapter at all — worth testing before assuming this module is needed
for the normal-map case specifically, independent of whatever the
frame-diff scratch test shows for the channel-select case generally.

## Proposed default scope (agreed this session, not yet built)

- **Input:** any texture, in0.
- **Channel select:** two menus, X source and Y source, each
  `R / G / B / A / Luma` (Luma = Rec.709 reduction computed in-codebox,
  for cases where a scalar-derived axis is wanted rather than a raw
  channel).
- **Same-channel allowed on both axes** — no guard against picking the
  same source for X and Y. Legitimate degenerate case (e.g.
  radial-ish patterns derived from a single scalar), not worth
  blocking.
- **Per-axis invert** — two toggles. Cheap to add, useful for flipped
  source footage or authored textures that need a sign flip on one or
  both axes.
- **No gain/scale knob** — deliberately kept a pure remap
  (`[0,1] → [-1,1]`, optionally inverted per axis). A magnitude/strength
  control is the downstream consumer's `gain` param's job, not this
  utility's — keeps the module doing exactly one thing.
- **Output:** vecfield-typed texture, out0. As an `f_vf_`-prefixed
  vecfield originator, outlet label is plain `"vecfield"` per existing
  convention (see `f_vf_fieldmap`, `f_vf_seeds`).

## Build complexity (informal assessment, not a real estimate)

Looks cheap enough that it may not need `pix_chain` at all — a single
`jit.gl.pix` codebox doing a channel select (branchless, same
`step()`-based select pattern already used elsewhere in the library,
e.g. `f_vf_advect`'s mode select) + linear remap. Should slot into
`build_patcher.py`'s existing single-pix path without needing any new
schema capability — unlike `f_focus`, which hit a real gap because its
primary object wasn't a `jit.gl.pix` at all. This module doesn't have
that problem.

## Open questions

- Whether this ever gets built depends partly on how the frame-diff
  scratch test goes — if raw R/G channels of a frame-diff image turn
  out to carry genuinely useful directional information (undetermined,
  not yet tested in Max), that's a concrete second use case beyond
  "generically useful utility," which would strengthen the case for
  building it now rather than leaving it as a someday-idea.
- Naming: `f_vf_channelmap` chosen for this file as the clear
  structural counterpart to `f_vf_split`, not yet confirmed as the
  final name.
- Not yet checked against `f_vf_fieldmap`'s own menu/param conventions
  in detail (e.g. exact `live.menu` wiring pattern for the two channel
  selectors) — should reuse whatever pattern already exists there
  rather than re-deriving it.

## Explicitly not decided / not in scope yet

- No spec, no plan, no build. Captured per standing rule (valuable
  architectural discussion goes into docs by default, not left to
  session-log compression).
- Relationship to the `f_vf_optical_flow` idea file is "inspired by,
  potentially useful alongside" — not a dependency in either
  direction. Frame-diff → `f_vf_fieldmap` remains the primary
  scratch-test path for optical flow; `f_vf_channelmap` is a separate,
  more general utility that happened to surface from the same
  conversation.
