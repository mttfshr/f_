# f_vf_stamp (was `f_splat`) — a gated stamp: ink texture plus impulse vecfield

**Status:** 🟢 **built 2026-11-05** (`docs/f-reference/f_vf_stamp.md`; record in `.specify/f_vf_stamp/`). This note keeps the design history; where it differs, the reference doc wins. Raised 2026-10-27 with Matt
as the missing "drop of ink" piece for the ink-in-water look and for dropping
oil into `f_vf_ch.md`. Name decided 2026-11-05 (below).

> **Decisions 2026-11-05 (Matt):** (1) **Stamp only**: the shape comes in as a texture; the
> module does not generate blots. Named **`f_vf_stamp`** (the `f_vf_` prefix: it takes and
> produces vecfields). (2) **Coverage from luma**, not alpha. (3) **With nothing on in1 the
> impulse is RADIAL, derived from the stamp's own gradient** (outward = minus the gradient of the
> mask). Consequence below. (4) **A radial / swirl switch: yes.** Still open: the dials. The sections from "Concept" to "Tier-1 checks" below
> describe the original generated-blot design (2026-10-27) and are SUPERSEDED by the
> stamp variant, except the curl constraint, which now applies to in1.

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

What it would give `f_vf_stamp` (inference, not tried):

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
  (replaces) because that module holds the field; `f_vf_stamp`'s outputs are stateless,
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

## Stamp variant: the shape comes in as a texture (2026-11-05, Matt)

Matt's idea: `f_vf_stamp` does not draw the blot. It is a **stamping tool**. Two inlets:

```
in0  texture   the stamp: its shape is the blot, its RGB is the ink      (where / what)
in1  vecfield  direction and force of motion, at the same pixels          (how it moves)
     control   splat / gate messages, the held press above

out0 ink      the stamp, masked by the gate and envelope (texture)
out1 impulse  in1 x the stamp's mask x amount x envelope  (vecfield contract: 0.5, 0.5, 0.5, 1 when idle)
```

Mirrors `f_wave_field`: there inlet 0 said where (and Strike hit its outlines) and
inlet 1 said when (an LFO); here inlet 0 says where and what, and inlet 1 says how.
The rest (inference, not tried):

- **It answers two open questions.** Position is live, because the texture can move
  (hold the press while the source moves and it paints a trail; a latch would need a
  feedback buffer and a snapshot at the press, so it is not the default). The internal
  random clock is not needed: random drops come from an upstream source (`f_grain`,
  `f_vf_seeds`), and `f_ngon` already generates clean shapes.
- **The module becomes stateless and tiny:** per pixel, no solver, no feedback, no DFT.
  Tier 1 is closed forms: output = input x envelope, neutral when idle, impulse linear
  in `amount`, impulse zero where the mask is zero.
- **The unique parts are the pair and the gate:** one mask and one gate shape the ink
  and the impulse together, so they register exactly, with the held press and its
  envelope on top. Each single operation exists as a plain mixer; this is the same
  stamp for any texture and vecfield pair (into `f_vf_advect`, `f_vf_ch` as oil,
  `f_vf_warp`, ...), not only ink, which fits Matt's taste for general tools.
- **Natural source pair: a camera and its own motion.** `f_vf_optical_flow` of a
  camera is literally direction and force of motion, so camera luma on in0 and the
  optical flow on in1 stamps ink where things move and stirs along that motion.
- **The curl constraint moves to the vecfield.** The section above (the impulse needs
  curl or `f_vf_fluid`'s `project` deletes it) now applies to what is patched into
  in1: `f_vf_vortex`, a swirl, or optical flow carry curl; a radial field does not.
  With in1 empty, **decided 2026-11-05 (Matt): a radial impulse from the stamp's own
  gradient**, outward = minus the gradient of the mask (the mask is high inside the
  blot). It needs a soft mask (a blurred or smoothed threshold), the same band-width
  lesson as `f_wave_field`'s outline mask; unverified. **Consequence (from the curl
  section above, not yet seen in practice):** a radial field is curl-free, so
  `f_vf_fluid` at its default `project` of 1 deletes it and the empty-in1 stamp stirs
  nothing there; it shows at `project` below 1, or in a consumer that reads the field
  directly (`f_vf_warp`, `f_vf_advect` advecting with it). The swirl alternative (the
  gradient rotated 90 degrees: divergence-free, curl at the edges) survives
  `project`: **a Radial / Swirl switch is in (Matt, 2026-11-05)**, inert when in1 is connected.
- **Mask and edge.** Coverage from luma or alpha (Vsynth textures are usually A = 1)
  with `threshold` and `softness` dials. An irregular edge can come from a noise-offset
  threshold, which works for any stamp shape, instead of angular harmonics on a radius.

The generated-blot design above (a disc with harmonics and satellites, a dipole
profile) stays recorded as the alternative; this variant makes it a source upstream.

## Open questions

- **Stateless pulse (recommended) versus held slots.** (Stateless: decided by the stamp variant, 2026-11-05.) Pulse: tiny module,
  composes with the two state holders, needs a patcher-level envelope.
  Slots: self-contained, but means N × params and array state in one
  `jit.gl.pix`, and duplicates persistence that `f_vf_advect` and `f_vf_fluid`
  already provide.
- **Trigger convention.** A Max message per splat, an internal random clock,
  or both. Needs a decision before any spec. The held press above is a third form: a gate with a `line` envelope.
  (Decided 2026-11-05: the held press; position is live from the texture; no internal random clock.)
- **Decided 2026-11-05 (Matt):** stamp only, luma coverage, name `f_vf_stamp`, radial in1-empty
  fallback. The dial set (`threshold`, `softness`, `amount`, edge irregularity) is still open.
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
