# f_splat (working name) — a triggered drop: ink blot plus impulse

**Status:** ⚪ idea only, not specced, not scheduled. Raised 2026-10-27 with Matt
as the missing "drop of ink" piece for the ink-in-water look and for dropping
oil into `f_vf_ch.md`. Name is a placeholder.

## The gap

`f_vf_fluid` plus `f_vf_advect` already move and smear ink once it exists, and
`f_vf_vortex` gives a force at a point. What nothing does (searched the
reference docs and ideas, not exhaustively) is **produce one event**: a drop
that arrives at an instant, at a place, with a size, as both

1. an **ink blot texture** (the thing to be carried), and
2. an **impulse vecfield** at the same place and size (the thing that stirs).

Closest existing pieces:

- `f_grain` makes grains that come and go on an era clock ("boil" to "frozen"),
  so it can feed drops upstream, but it is a scheduled texture with no momentum.
- `f_vf_vortex` / `f_vf_vortex_multi` give a swirl or radial force at fixed
  positions, but constant, with no trigger or envelope.
- `f_vf_seeds` places discrete marks; not an event source.

## Concept

A trigger (a message, or an internal random clock) emits a **splat** for a few
frames: an irregular-edged blot and a matching impulse field. Everything after
that is left to modules that already hold state:

- `f_vf_advect` keeps and spreads the ink (its `injection` re-injects the source
  every frame, so ink per splat is injection times the envelope's integral).
- `f_vf_fluid` keeps the momentum (it adds `force · F` per frame, so momentum
  per splat is force times the envelope's integral).

This is the "stateless pulse" design. It is my recommendation; Matt was unsure
(2026-10-27). The alternative, a module that holds N splat slots itself, is
recorded under Open questions.

## Proposed shape

```
in0  control (messages): splat x y radius amount seed ... / random-mode settings

out0 ink blot   (texture; RGB = ink colour, A = coverage)
out1 impulse    (vecfield, f_vecfield contract: B = 0.5, A = 1)
```

Persistence belongs downstream. The envelope (how many frames, how it falls
off) is a patcher-level `line` driving an `amp` param, the way `f_vf_fluid`
uses draw counters.

Provisional dials: position (or a random region), radius, ink amount, ink hue,
impulse strength, impulse mode, edge irregularity, satellite droplets, seed,
envelope length.

## The impulse must have curl, or `project` deletes it

This is the main design constraint, from `docs/f-reference/f_vf_fluid.md`:
`project = 1` removes the curl-free part of the velocity. A pure radial
outflow from a point **is** curl-free, so at the default `project` of 1 it would
be projected away and the splat would stir nothing. Hence impulse modes:

- **Swirl** (a vortex; like `f_vf_vortex` with convergence 0).
- **Dipole / jet** (a vortex pair, the 2D analogue of a drop kicking a jet).
  Likely the best-looking default. [inference]
- **Radial** (outflow). Only visible at `project` below 1 (compressible,
  shock-front look) or in a consumer that reads the field directly.

## Ink blot

- Irregular edge from a few angular harmonics on the radius (`edge irregularity`
  sets their amount), plus optional satellite droplets from a hash.
- Fine fingering is not drawn: it is what the flow does to the blot afterwards.
- Draw with periodic wrap in the distance calculation, because `f_vf_fluid`'s
  domain is a torus; a splat near an edge should not seam against it.
- A second use: the same blot, taken as a φ injection, is a drop of oil for
  `f_vf_ch.md`.

## Tier-1 checks (candidates)

- Blot area matches the analytic area for a circle at zero irregularity.
- Swirl mode is divergence-free; radial mode is curl-free (finite differences).
- Dipole mode is divergence-free, with net momentum along the jet axis;
  check against the closed form once the profile is chosen.
- Neutral output (exactly 0.5, 0.5, 0.5, 1) when idle.

## Held press: the gate button from `f_wave_field` (2026-11-05, raised by Matt)

`f_wave_field` T042 built its Strike as a **held press**, not a trigger: a `ubutton`
reports mouse-down and mouse-up, a `strike_gate` param is 1 while held, and a tap is
a gate the patcher holds for a few draws (a release is applied on the third draw bang
after it, so any press is seen by at least two rendered frames; counters, never
timers). Reference: `docs/f-reference/f_wave_field.md`, decisions D11-D14 in
`.specify/f_wave_field/tasks.md`.

What it would give `f_splat` (inference, not tried):

- **The envelope question gets a performer-sized answer: tap = drop, hold = pour.**
  A patcher-level `line` ramps `amp` up on press and down on release; the sustain is
  how long the button is held. The module stays a stateless pulse (no memory of its
  own); persistence is still `f_vf_advect` (ink per splat = injection times the
  envelope's integral) and `f_vf_fluid` (momentum = force times the integral). So a
  hold is a faucet or a sustained jet, a tap is a kick.
- **The one-frame-pulse worry is half-solved.** A tap is never one frame: the draw
  counter spreads it over two to three, which matters at `f_vf_fluid`'s default
  `force` of 0.02 per frame.
- **Replace-versus-add is not this module's question.** `f_wave_field` pins
  (replaces) because that module holds the field; `f_splat`'s outputs are stateless,
  so whether a splat adds to what is there is decided by the consumers.

What it does not settle:

- **Where.** `f_wave_field` got its position from a texture's outlines or the frame
  centre. A splat needs x and y: latched at the press, or following while held
  (drag a brush through the ink, a stationary hold pours in one place)?
- **Random mode.** Whether the gate also arms the internal random clock while held.

Parts to reuse: a `ubutton` over a `panel` face (a plain `button` reports no
release, `live.text` in button mode sends only a bang on click, `textbutton` sends
two identical bangs); `[sel bang 1 0]` to decode a bare `strike` (tap), `strike 1`
and `strike 0`; a PRESS `[t b b]` that cancels a pending release, a RELEASE that
restarts the draw counter. Name the Param `<something>_gate`: `gate` alone is a Gen
operator name (the same clash as `edge`). The raw boxes live in
`src/f_wave_field/definition.py`; a general `gate button` UI type in the
`definition.py` schema, instead of copying them, fits Matt's taste for general tools
and is an open choice.

## Open questions

- **Stateless pulse (recommended) versus held slots.** Pulse: tiny module,
  composes with the two state holders, needs a patcher-level envelope.
  Slots: self-contained, but means N × params and array state in one
  `jit.gl.pix`, and duplicates persistence that `f_vf_advect` and `f_vf_fluid`
  already provide.
- **Trigger convention.** A Max message per splat, an internal random clock,
  or both. Needs a decision before any spec. The held press above is a third form: a gate with a `line` envelope.
- **Position: latched at the press or live while held**, and whether the
  gate arms the random clock (see the held-press section).
- **Gate button as a shared building block** in the `definition.py` schema, or
  copied raw boxes.
- **Ink colour and mixing.** `f_vf_advect` advects channels as plain values,
  which is additive-looking; subtractive watercolour mixing and paper effects
  may need their own treatment. Not looked at.
- **Frame-rate dependence of the envelope.** Envelope in frames or seconds?
- **Does a one-frame pulse register in Fluid?** `f_vf_fluid`'s default `force`
  is 0.02 velocity per frame at full scale, so a single frame is a small kick;
  that is why the pulse is spread over an envelope.

## Related

`f_wave_field` (the held Strike), `f_vf_ch.md`, `f_vf_emulsion.md`, `f_vf_fluid`, `f_vf_advect`,
`f_vf_vortex`, `f_vf_vortex_multi`, `f_grain`, `f_vf_seeds`, `f_vf_mix.md`
(to add a splat to a performer's stirring force).

## Provenance

Conversation with Matt, 2026-10-27, after reading the reference docs for
`f_vf_fluid`, `f_vf_advect`, `f_vf_lbm`, `f_grain` and `f_vecfield_type`.
