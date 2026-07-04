# Vorticity confinement and the shape of f_vf_advect's approximation — from GPU Gems Ch. 38 (Fast Fluid Dynamics)

Sparked by reading GPU Gems Ch. 38 (Harris, based on Stam's stable-fluids
method) against `f_vf_advect`. One confirmation, one honest gap, one
concretely portable addition — richer than a backlog one-liner.

## The chapter's full algorithm

`u = Projection(Force(Diffuse(Advect(u))))` — four composed steps per
timestep:

1. **Advection** — backward-trace each cell along the velocity field,
   bilinear-sample the previous state there (Stam's stability trick:
   implicit/backward tracing rather than forward-pushing values, which
   GPU fragments can't do anyway since they can't relocate themselves).
2. **Diffusion** — viscosity, solved as a Poisson equation via ~20-50
   Jacobi iterations (each iteration = a full-frame 4-neighbor sample
   pass).
3. **Force application** — external impulses added directly to velocity.
4. **Projection** — divergence computed, a *second* Poisson equation
   solved for pressure (~40-80 more Jacobi iterations), pressure
   gradient subtracted from velocity to enforce zero divergence
   (incompressibility). This is what makes it a self-consistent fluid
   rather than flow being pushed around arbitrarily (Helmholtz-Hodge
   decomposition).

## Confirmation: f_vf_advect's core IS the chapter's Advection step

Checked directly against the codebox:
```
src_uv = uv - field*dt
advected = sample(prev_frame, src_uv) * decay
result = advected + sample(source, uv) * injection
```
This is exactly Advection — backward-traced UV, bilinear sample (via
`sample()`'s built-in bilinear), fed through a decay-weighted feedback
loop. Not an approximation of the technique; the actual technique,
correctly implemented. Worth having on record as a genuine confirmation,
not just "no fit" or "gap."

## The honest gap, and why it's likely not worth closing

No diffusion, no projection. `decay` is a crude global exponential fade
substituting for real viscosity — one multiply, no Jacobi solve. No
pressure projection at all means the vecfield being advected is never
enforced divergence-free — it's genuinely just whatever the upstream
generator (vortex/repulse/etc.) produced, pushed around by itself, not a
self-consistent incompressible fluid.

Each Jacobi solve is 20-80 *additional* full-frame multi-pass iterations
*per timestep*. Given multiple `f_` modules run simultaneously in a live
rig at 2560-3840px output, true diffusion+projection is plausibly
impractical for real-time live use — not a missed opportunity, a cost
that likely doesn't clear the bar for this context. Logged so this
doesn't get re-investigated expecting a different conclusion, similar in
spirit to the Ch 2 / Ch 5 no-fit entries but for a *specific missing
piece* within an otherwise-confirmed module, not the whole chapter.

## The portable finding: vorticity confinement (S:38.5.1)

Standalone, single-pass, additive force term — no Poisson solve required:
compute vorticity (curl of velocity via finite differences — same
central-difference pattern already used in `f_caustic`'s divergence
calc), build a normalized gradient-of-vorticity-magnitude vector, add a
small corrective force perpendicular to it. Restores fine-scale swirling
motion that numerical dissipation washes out on a coarse grid.

This is the standout idea from the chapter for f_'s purposes: cheap,
self-contained, fits the performance constraints that rule out real
diffusion/projection. It's also conceptually adjacent to what
`f_vf_advect`'s `decay`-driven "excitable/amplifying" mode (decay > 1.0)
seems to be reaching for empirically already — a cheap way to add
controllable swirl/turbulence character.

## Where it could go (not decided)

- **Inside `f_vf_advect`** — an additional force term added to the
  existing advection step, new param for confinement strength.
- **A standalone vecfield processor** — takes any vecfield in, adds
  vorticity confinement, outputs an enhanced vecfield; would work
  upstream of `f_vf_advect` or any other vecfield consumer, not
  advection-specific. More in keeping with the vf_ family's
  producer/consumer composability (per README's vf_ family framing) than
  bolting it onto one specific module.

The second option seems structurally more natural given how the rest of
the vf_ family is organized (small, composable, single-purpose
processors), but this is genuinely undecided.

## Status

Tabled. No scratch patch yet. Confirmation (advection) needs no action.
Gap (diffusion/projection) is logged as a deliberate non-goal, not an
open item. Vorticity confinement is the one live thread here worth
picking up.

## Open questions to resume with

- Standalone processor or `f_vf_advect` extension — leaning standalone
  per the composability argument above, but undecided.
- What does "confinement strength" feel like live — subtle detail
  restoration, or does it read as a distinct character control worth its
  own prominent dial?
- Does this want to be tested against multiple vecfield sources
  (vortex, repulse, fieldmap-from-texture) before deciding param ranges,
  given different sources will have very different baseline vorticity?
