# Idea: breaking the grid — seed distribution beyond grid+jitter

Status: captured, not started. Flagged 2026-06-29 during f_vf_seeds shape-tex
architecture session.

## The current model

f_vf_seeds (and presumably f_grain, f_masonry) place items using a regular
grid with per-cell jitter, found via a 3x3 neighborhood hash search. This is
fast, GPU-friendly, stateless, and gives a controllable density/regularity
range — but it is fundamentally still a grid. Even at jitter=1.0, the
distribution has grid-scale structure baked in (cell boundaries constrain how
far a jittered seed can wander, so there's an implicit max irregularity).

## The itch

Matt: "I would love to break the grid entirely." Not a complaint about the
current implementation — jitter does a good job of disguising the grid in
practice — but a genuine interest in what a non-grid-based seed distribution
would feel like, and whether it opens up compositional possibilities the
grid forecloses (true clustering, density-field-driven scatter, organic
irregularity that doesn't read as "jittered grid" even at close inspection).

## Why this is its own exploration, not a parameter tweak

The neighborhood search (3x3 grid cells) is load-bearing for performance —
it's what makes "find nearest seed" tractable per-pixel on GPU without a
full scan. A genuinely non-grid distribution (Poisson disk sampling, for
instance) doesn't have an equivalent fast nearest-neighbor structure without
its own spatial index, which is a different algorithmic problem, not a
parameter on the existing approach.

## Candidate directions (unexplored, not vetted)

- **Poisson disk sampling**: minimum-distance-guaranteed random distribution.
  Classic "blue noise" look. GPU-friendly variants exist but typically need
  either a precomputed point set (texture-fed) or a more expensive per-pixel
  search than the current 3x3.
- **Density-field-driven scatter**: seed density varies spatially based on
  an input texture (a literal "where should seeds cluster" map). Could
  reuse the mod-tex inlet concept, but the underlying placement algorithm
  would still need to change.
- **Texture-fed point set**: precompute or externally generate a point
  list (CPU-side, jit.gen, or a points texture), feed it in as data rather
  than computing positions analytically per-pixel. Decouples placement
  algorithm entirely from the GPU shader, at the cost of requiring an
  upstream point-generation step.
- **Hybrid**: keep the grid for the *search structure* (fast nearest-seed
  lookup) but randomize cell density/presence more aggressively — some
  cells empty, some cells with multiple seeds — to break the visual
  regularity of "exactly one seed per cell, jittered."

## Relationship to current work

Not blocking f_vf_seeds in its current form — the shape-tex architecture and
size+stretch simplification stand on their own regardless of seed
distribution method. This is a separate, deeper architectural question about
the placement layer specifically, worth its own spec→plan→tasks cycle when
picked up.
