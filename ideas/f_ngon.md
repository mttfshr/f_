# f_ngon

_Status: Planned -- not yet specced_
_Discovered: 2026-07-09, as a byproduct of f_poincare Phase 0 (kaleidoscope
diagnostic scratch work, see .specify/f_poincare/)_

## Concept

A live, parametrically modulatable N-gon generator/shape mask. Currently
Vsynth has no simple way to get a clean regular polygon (pentagon,
hexagon, etc.) with a live-modulatable vertex count -- the existing
shape generator is limited. This fills that gap directly.

## Where it came from

Built while diagnosing f_poincare's accumulated-Mobius-transform tracking
(shared math with f_apollonian, see that module's plan.md ADR-8). The
core mechanism -- branchless alternating reflection across two mirror
lines at angle 0 and `pi/n_mirrors`, repeated until a point settles into
the fundamental wedge -- naturally produces a regular `2*n_mirrors`-gon
when applied to a texture sample (confirmed visually at n_mirrors=6, 11,
18 in `~/Vsynth/patterns/ngon-scratch.maxpat`, forked from
`poincare-scratch.maxpat` at the point Phase 1 was confirmed working).

**Real bug found and fixed getting here, worth remembering if this
resurfaces elsewhere:** the second mirror's containment test had an
inverted sign (`step(0.0, crossTheta)` instead of `step(crossTheta,
0.0)`) -- verified via concrete numeric example before fixing, not
guessed. Separately, convergence needs roughly `n_mirrors` iterations in
the worst case (a point starting far from a narrow wedge needs more
alternating folds) -- a fixed iteration count tuned for one `n_mirrors`
value will silently under-converge (visibly deformed, asymmetric output)
at higher values. Confirmed 10 iterations broke down around
`n_mirrors=18`; 32 iterations held up cleanly at least that far.

## Open questions (pre-spec)

- Live `n_mirrors` param range and iteration-count tradeoff -- does
  iteration count need to scale with `n_mirrors` live, or is a single
  generously-large fixed count (e.g. 32) cheap enough to always use?
- Output as a filled polygon mask (shape only) vs. kaleidoscope-sampling
  an arbitrary input texture (current scratch behavior) -- both are
  useful, possibly two outlets or a mode switch
- Rotation/phase param (currently fixed at mirror-0 = x-axis) for live
  spin
- Radius/scale param -- currently uses `snorm` directly, unclear if a
  zoom param is needed for practical use in a Vsynth chain
- Relationship to the existing shape generator -- is this a replacement,
  a companion, or does it fold into that module's param set?

## Build sequence

Not yet scheduled -- flagged here so it isn't lost while `f_poincare`
Phase 2 (matrix tracking) continues on the original scratch file. Revisit
after `f_poincare`'s diagnostic work concludes, since the exact
convergence/iteration-count question above may get more evidence from
that work anyway (same core loop, larger n_mirrors territory).
