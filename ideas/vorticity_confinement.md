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

## Status update (2026-07-06) — SHIPPED as f_vf_vorticity, standalone

Built as `f_vf_vorticity`, a standalone processor. Full spec/plan/as-built
reference: `.specify/f_vf_vorticity/spec.md`, `.specify/f_vf_vorticity/plan.md`,
`docs/f-reference/f_vf_vorticity.md`. This entry summarizes the resolution
of the three open questions above — read the as-built doc for full detail.

**Standalone, confirmed correct in hindsight.** Single codebox (curl via
central differences, calls into vorticity's own gradient via a second
central-difference pass, corrective force perpendicular to that
gradient) compiled clean with no capture-ceiling split needed — the
architecture question from planning resolved in the simpler direction.

**`confinement` is a prominent turbulence-amount dial, per Matt's call**
— not a subtle correction. Its effective range varies substantially by
source (same category of finding as `f_vf_seeds`' `field_gain`), exposed
via `range_tiers` (0.1/1.0/10.0) rather than one fixed number.

**The real finding, beyond what this file anticipated:** the technique's
visible effect requires a consumer with *temporal feedback* to compound
against — `f_vf_advect` is currently the only one in `f_`. Every other
consumer (`f_caustic`, `f_vf_warp`, `f_lens`, `f_vf_glow`) samples the
field fresh each frame with no persistent state, so chaining through them
produces a different-looking static field, not visible turbulence.
Confirmed directly: `f_vf_vortex` → `f_vf_vorticity` → `f_vf_advect`
reads as distinctly turbulent; the same source through any memoryless
consumer doesn't read as meaningfully different from the unmodified
field. This reinforces rather than undermines the standalone decision —
it's guidance about *where in a chain the module earns its keep*, not a
reason to fold it into `f_vf_advect` as a param.

Open thread carried into the as-built doc's Open Questions: whether
`confinement` and `f_vf_advect`'s `decay > 1.0` "excitable" mode compound
controllably or fight each other hasn't been systematically mapped, only
informally confirmed to "work well."

## Addendum (2026-07-06) — fold-into-f_vf_advect attempted, reverted; standalone module's status also corrected

**Correction, end of session:** everything below this point originally
asserted the standalone `f_vf_vorticity` module was shipped/confirmed
working. Matt corrected this at end of session — it is not confirmed.
That confidence was based on apparent chain-testing results earlier in
the session, and this exact session also produced a long thread (the
`f_vf_advect` fold-in below) where things seemed confirmed at multiple
points and later turned out not to be, after a lot of debugging. Given
that, don't trust the "SHIPPED"/"confirmed" language a few paragraphs
down without independently re-verifying from scratch next session.

After the standalone module was built, Matt asked to try folding
confinement directly into `f_vf_advect` instead — curl computed on `in3` (the previous
accumulated frame) rather than a live source, so confinement could
reinforce rotation emerging from the feedback loop itself rather than
depending on the upstream field having curl. Real engineering happened:
`f_vf_advect`'s two `pix_chain` nodes were changed from `char` to
`float32` (needed for curl precision near the f_vecfield rest state), a
third outlet was added exposing the actual enhanced displacement field
(`fx_total`/`fy_total`, properly re-encoded, gated by the same
`connected` flag as everywhere else) rather than a relabeled copy of the
existing "advected" outlet, and a real pre-existing bug was found and
fixed along the way: `f_vf_advect`'s "Strength" param was declared as
`strength` in `definition.py` while the codebox's actual `Param` was
always `mix_amt` — silently binding the dial to a nonexistent pix
attribute every rebuild, unrelated to confinement but caught in the
course of debugging it.

**Confinement itself was never gotten working.** Extensive debugging
ruled out, one at a time, with direct evidence rather than assumption
each time: wrong `param_connect` metadata (real bug, fixed, but not the
cause — value delivery goes through `attrui`'s own `attr`, not
`param_connect`), `mix_amt=0` breaking the feedback loop entirely (real
issue, fixed, not the cause), `@type`/`@adapt` interaction (checked
against the actual Max reference docs — `@adapt` only affects
dimensions, not type; ruled out), a `dim`/`sx` scale problem (directly
visualized, confirmed sane), a Lua `DSL.Parser` capture-group compile
ceiling from fully inlining the curl functions (console confirmed clean,
ruled out), the elaborate 5-curl-evaluation gradient-of-vorticity chain
being the specific point of failure (replaced with a much simpler
single-curl-sample, perpendicular-to-flow variant — still no effect),
and finally whether tiny single-texel sampling offsets behave differently
than the larger offsets the confirmed-working advection step itself uses
on the same feedback texture (tested at 8x the offset — still no effect).

**Genuinely unresolved.** Something about reading spatial neighbor
offsets from `in3` specifically for the *curl computation* never
produced a nonzero result, despite: the same field values being
successfully read via other offset patterns elsewhere in the identical
codebox (the advection step's own `sample(in3, src_uv)` — proven working,
since the visible spiral in the "advected" output requires it), correct
wiring end-to-end (confirmed by reading the actual scratch patch JSON,
not assumption), a clean console, and multiple independently-verified
correct rewrites of the curl math itself. Whatever the actual root cause
is, it was not found this session.

**Reverted (2026-07-06).** `f_vf_advect` restored via `git checkout` to
its last-committed, pre-confinement state (`e27db16`) -- 2 outlets,
`char` type, no curl/confinement code -- with only the unrelated
`mix_amt` naming fix re-applied on top, since that bug was real,
independent of confinement, and worth keeping. The standalone
`f_vf_vorticity` module (this file's original recommendation) is NOT
confirmed as a working replacement -- Matt corrected the record on this
at end of session, see the note at the top of this addendum and of
`docs/f-reference/f_vf_vorticity.md`. Re-verify from scratch before
treating it as the answer to this thread.

**If this is revisited:** don't re-attempt curl-on-in3-inside-advect
blind. The one genuinely untested idea from this session: compute curl
on a *separate, dedicated single-purpose pix stage* reading `in3`, output
it as its own texture, then have a second stage do the confinement-force
arithmetic by sampling that curl texture's neighbors (i.e., the actual
multi-stage split pattern already established for `f_vf_seeds`/
`f_sirds`, not attempted here because the problem never presented as a
compile-ceiling issue). Whether that changes anything is unknown --
flagged as the next thing to try, not a confirmed fix.
