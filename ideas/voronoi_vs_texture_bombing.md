# Voronoi placement vs. texture-bombing overlap — open design question

Sparked by reading GPU Gems Ch. 20 (Glanville, "Texture Bombing"), flagged
as high-priority in `ideas/gpu_gems_research.md`. Captures a discussion
session — no code written, nothing decided yet.

## The chapter, briefly

Grid UV space into cells. Per cell: hash a random offset, place a small
image. Sample the current cell plus the cell below/left (4 total, not the
full 3x3 — placement offset is bounded to [0,1) within a cell so an image
can only bleed into adjacent cells, never diagonal-only neighbors).
Overlap between neighboring cells' images is resolved by a **priority**
value (random, or distance-to-point for the Voronoi variant) — highest
priority wins per pixel. A "multiple samples per cell" inner loop adds
density without changing grid scale.

## What f_grain and f_vf_seeds currently do

Both are **Voronoi-partitioned**, not overlap-bombed. `f_vf_seeds`' 3x3
neighbourhood search computes squared distance to all 9 candidate seeds
and collapses to a single nearest seed (`best_gx`/`best_gy`) via a
`step`/`mix` chain — this *is* a distance-based priority rule, just
implicit in "nearest wins" rather than an explicit priority value. Only
that one nearest seed's mark geometry is ever evaluated against the pixel
(local UV projection, gate against `marklen_eff`/`weight_eff`). If the
pixel falls outside that seed's footprint, output is black — even if a
neighboring seed's mark is large enough that it should geometrically
still be covering this pixel.

**This is the concrete gap, precisely stated:** not raster-order bias
(the nearest-seed selection is deterministic and non-arbitrary), but
**hard clipping at the Voronoi cell boundary** — a mark can never be seen
past its own cell, regardless of size. This is exactly the ceiling the
chapter's multi-candidate-footprint-test approach exists to lift.

`f_grain`'s cellular/voronoi approach is presumed to have the same
structural property (nearest-seed-wins-exclusively) — not yet re-read in
detail this session, but its identity ("2D hash field stipple") suggests
Voronoi-ness is the point, not a limitation.

## Why this isn't a toggle — two different identities, not a spectrum

Voronoi partitioning guarantees exactly one owner per pixel by
construction (cell boundaries are the perpendicular bisectors between
seeds). Overlap-bombing has no such guarantee — marks are placed
independently and drawn where they land, colliding where they collide,
resolved by priority/compositing. You can't gradually interpolate a
codebox from "exactly one owner, always" to "independent placement,
sometimes colliding" — the moment a second candidate's footprint is
tested and can win, the defining Voronoi guarantee is gone, not softened.
A "blend" toggle would really be a fork in which parts of the codebox
even run (single-candidate-test vs. multi-candidate-test-and-composite),
not a continuous parameter.

**Revisit flagged 2026-07-04, not resolved here:** a reread of Ch. 20
against `seed_distribution_beyond_grid.md`'s "Priority as a generalized
quantity" section complicates this. The chapter's own Voronoi and
bombing modes turn out to be the *same* reduction loop over the
neighborhood candidates, differing only in what feeds a single
`priority` value (`-distance²` vs. an arbitrary per-image value) —
both stay single-owner-per-pixel, no compositing required either way.
That's a smaller fork than "which parts of the codebox even run." The
distinction this section draws may still hold for the *further* step of
true multi-owner alpha-blended overlap (which does need a compositing
rule and is a real fork), but priority-based winner selection alone —
where the winner need not be the nearest candidate — looks like it fits
inside the existing single-winner shape rather than requiring a fork
from it. Worth re-examining "the moment a second candidate's footprint
is tested and can win, the defining Voronoi guarantee is gone" against
this before treating it as settled.

## Where each module's identity likely lands

- **f_grain** — voronoi/cellular is the whole identity. Overlap is
  probably foreign to what this module *is*, not a missing feature.
- **f_vf_seeds** — the placement/orientation *engine* for arbitrary shape
  marks, closer in spirit to the chapter's actual stamped-image case.
  This is the plausible candidate for an overlap-bombing sibling or mode
  — Voronoi-clip may be the odd one out here, not the natural default.

## Matt's stated design goal

Prefers modules where idioms carry across, so performers build fluency
once and reuse it — consistent with the existing f_vf_ family (vortex,
warp, streak, glow, repulse share inlet/param conventions despite
different core mechanisms). Wants to lean toward reusing as much of
`f_vf_seeds` as makes sense for any bombing-mode work, but the reasonable
complexity boundary isn't decided yet.

## Where the idiom genuinely carries vs. where it doesn't

Tested by asking: does the param's *meaning* survive the mechanism
change, not just its name/presence.

**Carries across cleanly:**
- `density`, `jitter` — grid spacing and positional randomness are
  mechanism-agnostic.

**Same name, different felt behavior (not disqualifying, but not free):**
- `size`, `stretch` — concept carries, but in Voronoi mode cranking
  `size` eventually hits a clipping ceiling; in bombing mode the same
  motion means escalating visible overlap. Same dial position, different
  outcome — "idiom carries across" is true at the param-list level, less
  true at the muscle-memory level.

**Genuinely new territory, not inherited complexity:**
- `strength`, `mag_weight`, vecfield-driven orientation — designed
  against a single-owner-per-pixel model (unambiguous "which mark am I
  facing" per pixel). Once overlap is possible, a pixel can sit inside
  multiple marks' footprints simultaneously, each with its own
  field-derived orientation — needs a compositing rule (which mark's
  color wins? blend?) on top of the priority question itself.
- `phase` — reads as Voronoi-native (single continuous position along
  one seed's local axis); less obviously meaningful with multiple
  independently-visible marks in the same region.

## A possible dividing line (not decided)

Placement math (density/jitter/hash/grid) and basic mark shape
(size/stretch/shape-tex sampling) are the part that plausibly wants to
carry across as shared "f_vf_seeds family grammar." Overlap/priority
handling and field-orientation-under-overlap are the part that's new
territory requiring its own decisions. This would put the mechanism fork
right after the candidate search — where `best_gx`/`best_gy` currently
commits to a single winner — rather than at the top of the codebox.

Whether that becomes "two modules sharing a documented placement-core
pattern" (precedent: separate-but-related modules like f_vf_streak /
f_vf_glow) or "one module with a mode switch affecting only the back half
of the codebox" is genuinely open.

## Status

Tabled, same as the f_vf_seeds soft-mod question — no scratch patch, no
code. Revisit when a concrete performance need or scratch-patch itch
pulls it back up, or when ready to prototype the multi-candidate-footprint
test as its own small experiment (independent of the overlap-vs-Voronoi
identity question — worth possibly de-risking that mechanism in isolation
first, e.g. as a scratch test on f_vf_seeds' existing 9-candidate data
before deciding module boundaries).

## Open questions to resume with

- Composite or hard-select when overlap is real? (mirrors the chapter's
  priority-value approach vs. e.g. max/screen blending)
- Does f_grain actually share the same nearest-only clipping limitation,
  or does its mechanism differ enough that this doesn't apply? (not
  re-verified this session)
- If pursued: shared placement core as literal shared codebox fragment,
  or just a documented convention followed independently per module?
