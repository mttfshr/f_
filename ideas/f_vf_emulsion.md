# f_vf_emulsion (working name) — two materials in one flow

**Status:** idea only, not specced, not scheduled. Surfaced 2026-09-29 in
conversation, immediately after `f_vf_fluid` reached its Phase 4 checkpoint.
Not naming-locked. Would be a **fork of `f_vf_fluid`**, not a v2 of it — see
"Why a separate module".

## The question that started it

Matt, on `f_vf_fluid` in use: all the onscreen fluid behaves the same way —
it is all the *same* fluid. What if you wanted to mix fluids of differing
viscosities or characters?

Sharpened over the conversation to: **what happens when oil and smoke collide
and begin to mix.** Explicitly a vecfield problem, not an image-domain
compositing job.

## Why one fluid is structural in `f_vf_fluid`, not a choice

The solver's parameters live in two places, and that determines how hard each
is to vary spatially.

- **Real-space, per-pixel** (`adv` / `ix` / `enc`): `force`, `dt`, `gain`.
  Already per-texel multiplies. Spatially varying them is a sample and a
  multiply — effectively free.
- **Spectral, per-bin** (`spec`): `viscosity`, `project`. `exp(-ν·k²·dt)` is
  diagonal in Fourier space *only because ν is constant*. A ν(x) makes the
  operator a convolution — it cannot be expressed in the k-domain at all.
  This is the real obstruction, not a GenExpr limitation or a cost problem.
- **`drag` is the exception**: `exp(-drag·dt)` has no `k` in it, so it is the
  same multiply in both domains. **Spatially varying drag is nearly free** —
  one sample and multiply in `ix`, inside the feedback loop.

Corollary worth keeping regardless of whether this module gets built: if any
future per-region control of Fluid is wanted, drag is the cheap one, force and
dt are cheap, viscosity and project are not.

## Options considered and where they landed

**Tier 0 — two `f_vf_advect` consumers off one Fluid, composited.** Different
`decay`/`separate`, mixed with `vs_blendmode_mixer` (13 blend modes) or
`vs_alpha_blend`. Zero new code, patchable today. **Matt's intended first
experiment, then ruled insufficient**: it gives two substances *in* a flow but
they never affect the flow or each other. It is a picture of two fluids, not
two fluids.

**Tier 1 — two Fluid instances, blended by a mask.** ~5 ms against a 3 ms
budget, and the two fields do not interact — no momentum crosses the interface.
Also: a mask-weighted blend of two divergence-free fields is *not*
divergence-free (`∇·(w·u₁+(1−w)·u₂) = ∇w·(u₁−u₂)`), so sources and sinks appear
along the mask gradient. Rejected for this purpose. It is what would need
`f_vf_mix` (see below).

**Tier 2 — spatially varying `drag` from a map inlet.** Cheapest real win,
~0.1 ms. Still a *static* map: "this corner of the screen is honey" is
architecture, not behaviour. Kept as a fallback, not the answer.

**Tier 3 — spatially varying viscosity, approximated.** Solve spectrally at
ν_min, blur after `ix`, mix by the map. One separable blur pair, ~0.3–0.6 ms.
The exact version (second inverse-DFT branch at ν_hi, blend in real space)
costs ~+1.2 ms. Neither is divergence-free at the interface, but **the next
frame's projection removes accumulated divergence**, so the error is bounded at
one frame either way — which is what makes the cheap approximation defensible.

**Tier 4 — spatially varying `project`.** Compressible shock fronts beside
incompressible swirl is arguably the biggest *character* contrast available,
bigger than viscosity. Needs the curl-free part in real space: one extra
inverse DFT pair, ~+1.2 ms. Parked, not part of the proposal below.

**True multiphase flow** (variable density in the momentum equation, surface
tension) is out of scope: variable density makes the pressure projection a
variable-coefficient Poisson problem and breaks the spectral solve outright.
The proposal below gets the look without it.

## The proposal: an advected material field φ

What makes two substances read as *mixing* is not that they have different
properties in different places. It is that **the boundary between them is
carried by the flow it is helping to create.** That is a feedback loop, and it
is the loop `f_vf_fluid` does not have. A static map cannot produce it.

So: a scalar **φ(x) ∈ [0,1]** — 0 is smoke, 1 is oil — as a second state field
inside the solver, advected by `u` every frame the way `u` advects itself. The
solver's local behaviour is a function of φ; φ is a function of where the flow
has carried it. One velocity field, one fluid, two materials in it.

### Terms, by cost

- **Advecting φ** — a second 256² float32 state texture with its own pass node,
  mirroring the existing `pass` feedback shape. Reads post-solve velocity from
  `ix` and its own previous frame, backtraces with the periodic 4-tap sampler
  already written. One pass, ~0.15 ms. **It cannot ride in a spare channel of
  the velocity state** — the DFT stages need all four for Re/Im of both
  components.
- **Buoyancy — highest value per cost in the whole design, and nearly free.**
  Boussinesq approximation: density difference enters *only* as a body force
  proportional to φ along a chosen direction. One extra term in `adv`, beside
  where the input force is already added. This is what gives plumes, and
  Rayleigh–Taylor fingering when the heavy material sits above the light one.
  Avoids variable density entirely, so the projection stays constant-coefficient.
- **Viscosity contrast** — Tier 3's real-space approximation, mixed by φ rather
  than by a static map. ~0.3–0.6 ms.
- **Drag contrast** — free, per-pixel after `ix`.
- **Mixing itself is free, and the risk is having too much of it.**
  Semi-Lagrangian advection of φ numerically diffuses, hardest exactly where
  the flow is stirring hardest. That *is* mixing. The parameter that may be
  needed is therefore a **sharpening / anti-diffusion** term to keep the
  interface alive longer, not a mixing rate.
- **Surface tension** (what makes oil bead rather than smear) needs curvature
  of φ — a cheap real-space stencil, notoriously fiddly to tune. **Leave out of
  a first build**; check whether viscosity contrast plus buoyancy already reads
  as "oil".

Rough total ~3.2 ms against Fluid's current 2.5. Slightly over the old 3 ms
budget, with real headroom unmeasured (Fluid held 59–60 fps at 4K with one
consumer chain, which is the vsync ceiling, so the margin was never measured —
see `docs/f-reference/f_vf_fluid.md`).

## Where the expressive potential actually is

Discussed at length; the conclusion is that it is **not** in the injection
pattern, and that framing the design question as "which inlet" undersells it.

**1. Timescale separation — φ's persistence is the load-bearing parameter.**
What makes oil-and-smoke legible is that you see *history*: a filament is a
record of everything the flow did to a boundary since that boundary existed. So
φ must persist far longer than the stirring gesture but not forever. Two
failure modes bracket it:

- φ relaxes fast → a slightly weird dye layer, none of the structure.
- φ strictly conserved (the physical default — advection conserves) → a minute
  of performing leaves uniform grey emulsion with no way back.

Every interesting state is between those and is **transient**, which is a
problem if it is not controllable. The relaxation rate is the dial you would
ride during a set. **Open sub-question, genuinely undecided:** what
"equilibrium" means — a fixed value, the frame average, or the current
injection. Those are three quite different behaviours.

**2. Contrast depth — one macro dial.** A single scalar scaling the whole
difference between the materials at once (viscosity ratio, buoyancy, drag),
0 = one homogeneous fluid, 1 = maximally distinct substances. Tune the
individual ratios once by eye, expose the scalar. Performable in a way that
five separate physical parameters are not.

These two are where the module lives or dies. Everything else is secondary.

## φ's source: a dedicated inlet, not derived from the force

**Argued, not just defaulted to.** If substance appears exactly where motion
is, the boundary is always co-located with the stirring, and you never get the
case that makes mixing readable — a settled region that something *else*
arrives and disturbs. Contrast in the image needs independent causes; tying φ
to the force makes them one cause, and the result will tend to read as a single
slightly-lumpy fluid however good the solver is.

So: a **dedicated unipolar scalar inlet**, an injection-rate dial, source left
entirely to the patch. The interesting rig is then obvious — an `f_vf_`
producer stirring, and something unrelated (a shape generator, a slow
`f_weave`, a second video) deciding what is being stirred. Pairing chosen per
piece.

## The technical risk, and the cheap test that retires it

**Whether semi-Lagrangian numerical diffusion smears the interface faster than
the flow can fold it into filaments.** If it does, the whole thing reads as a
blur rather than as mixing, and the fix is an anti-diffusion term that is
fiddly and can go unstable.

**Test it in the NumPy mirror before any module exists.** `tests/fluid_mirror.py`
already has the velocity solver; adding a φ advection step to it is small. Stir
a sharp boundary for a few hundred frames and see whether it survives or turns
to mush. That answer gates the build.

## Why a separate module, not `f_vf_fluid` v2

`f_vf_fluid` is verified, documented, stable, and reproduced byte-for-byte by
`build_fluid.py`. This roughly doubles its state and adds five or six params
(φ injection and rate, persistence, contrast depth, buoyancy strength and
direction, possibly sharpening) to a panel already holding 6 dials. Forking
keeps the tuned thing tuned; `build_fluid.py` is a good starting point rather
than a thing to complicate.

## Open questions

- **φ breaks Fluid's founding constraint.** "No dye inside — feed the
  consumers" is the design principle `f_vf_fluid` was specced on. φ is a
  substance map, and once it exists you will want to look at it, which means a
  second outlet. Defensible as *material property* rather than transported
  imagery — φ is not an image being moved, it is a coefficient field — but it
  is a real departure and should be settled before a build, not after.
- **Equilibrium semantics for φ relaxation** (above): fixed / frame average /
  current injection.
- **Inlet count and the mod-texture convention.** A φ inlet lands on the
  unresolved thread in `.specify/plan.md` — unipolar vs bipolar, `mod_inlets`
  as the declaration site, and the untested named-mod-texture hypothesis (T1 in
  `ideas/named_mod_textures.md`). Fluid currently has *one* inlet carrying both
  force and control messages, so adding any map inlet is already a structural
  change.
- **A φ map arriving at render res is minified into 256²**, same as the force —
  the "a fixed-`@dim` stage is a resampler" finding in `skills/jit-gen-codebox`.
  Smooth maps are fine; a noisy one needs the `taps` treatment.

## Spun off: `f_vf_mix` (separate, smaller, independent of this)

Surfaced en route and worth recording on its own. **There is currently no way
to combine two vecfields at all** — `f_vf_split` takes one apart, nothing puts
them together. A real gap in the family, independent of the fluid question.

Not needed for Tier 0 (those outputs are images; `vs_blendmode_mixer` and
friends already handle them). Needed for Tier 1, and useful generally.

Two reasons it cannot just be an image mixer, even though the encoding is
affine (`0.5 + 0.5·u`, so a linear crossfade of two *encoded* fields is exactly
the linear blend of the decoded fields — no conversion needed):

1. **Precision.** `vs_mixer_3` is `@adapt 0 @type char`. 8 bits per axis is
   fine for an image and visibly steppy as a displacement source. `f_vf_mix`
   would hold float32 and re-assert the B = 0.5 / A = 1 contract.
2. **The useful modes are not image modes.** Max-magnitude (locally stronger
   field wins), vector add with clamp, and **angle-blend** (interpolate
   direction and magnitude separately). That last one matters: a plain linear
   mix of two fields pointing opposite ways cancels to zero, giving dead
   patches exactly at an interface. Angle-blend is what would make a
   mask-driven blend look like an interface rather than a hole.

## See also

- `docs/f-reference/f_vf_fluid.md` — the solver this forks from; stage table,
  parameter semantics, cost figures, the `vs_black` content-gate caveat.
- `.specify/f_vf_fluid/{spec,plan,tasks}.md` — design record and findings.
- `docs/f-reference/f_vecfield_type.md` — the type contract φ's outlet would
  have to honour if exposed.
- `ideas/named_mod_textures.md`, `.specify/plan.md` "UI density" and
  "f_util_matrix" entries — the inlet/mod-texture convention this depends on.
