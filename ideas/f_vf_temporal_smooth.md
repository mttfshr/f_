# f_vf_temporal_smooth — vecfield inertia/lag module

**Status:** Parked idea, not started. Surfaced 2026-07-11 while scoping
`f_vf_advect`'s 3rd outlet (see
`ideas/dry_wet_gain_and_novel_field_outlet.md`, finding 7).

## The idea

Apply the same pass/state accumulation architecture `f_vf_advect` uses
for color to a vecfield instead — a module that takes any f_vecfield in
and outputs a temporally-smoothed version with adjustable inertia/lag
(same shape as a one-pole lowpass, but per-vector rather than per-pixel
color).

## Why this is its own module, not part of f_vf_advect

Considered as `f_vf_advect`'s 3rd outlet and rejected there: giving a
vecfield inertia isn't specific to advection — any `f_vf_` producer's
output could equally want this. Folding it into advect would also add a
second feedback loop to a module that already had one feedback
experiment (vorticity confinement) fail and get reverted — not a good
place to stack more of the same kind of complexity for a generic payoff.

## Not yet explored

- Whether this is better as a standalone `pass_pix`/state-pix pair
  (mirrors advect's architecture) or achievable single-pass
  - Smoothing coefficient — single `decay`-style param, or separate
    attack/release
  - Where it'd sit in the module taxonomy — processor? Or does "vecfield
    in, vecfield out, temporal" want its own family designation
