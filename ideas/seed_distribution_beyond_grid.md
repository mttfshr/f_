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
  Supporting precedent (via GPU Gems 2 Ch. 12, "Tile-Based Texture
  Mapping," read 2026-07-03): that chapter's Wang-tile technique
  precomputes tile-selection data offline into a small index texture,
  looked up cheaply at runtime — and explicitly found the equivalent
  in-shader hashing approach too slow for real-time use in their tests.
  Different problem (avoiding periodicity in a tiled bitmap, which no
  current f_ module has, since nothing tiles pre-authored bitmaps), but
  real evidence that "precompute placement data, cheap lookup at
  runtime" beats "compute placement per-pixel via hash" at least in one
  concrete case — worth keeping in mind if the texture-fed point set
  direction is ever prototyped.
- **Hybrid**: keep the grid for the *search structure* (fast nearest-seed
  lookup) but randomize cell density/presence more aggressively — some
  cells empty, some cells with multiple seeds — to break the visual
  regularity of "exactly one seed per cell, jittered."
- **Multiple samples per cell** (GPU Gems Ch. 20, "Texture Bombing,"
  reread 2026-07-04): the chapter's own stated remedy for "still reads as
  regular even with a random offset" is not more jitter — it's more
  points per cell. Loop `k=0..N` inside the same 3x3/9-candidate search,
  reseeding the random offset each iteration, cell scale increased by
  `sqrt(N)` to hold average density constant. This is a specific, cheap
  mechanism distinct from the "hybrid" bullet above (which was vaguer
  aggressive randomization) and cheaper than Poisson disk — no new
  spatial index needed, just a larger loop bound over the existing
  search structure. See the "Priority as a generalized quantity" section
  below for how this connects to the field-convergence-overlap question.

  **LANDED, 2026-07-05.** Built as `f_vf_seeds`' Evolution 2 (K=2, not a
  live loop bound — GenExpr codeboxes can't loop, so this became two
  9-candidate search halves + a top-2 merge, not a literal `k=0..N`
  loop as originally imagined here). Full architecture, empirical
  findings, and open questions: `docs/f-reference/f_vf_seeds.md`,
  `.specify/f_vf_seeds/spec.md` (Evolution 2), `.specify/f_vf_seeds/plan.md`
  (ADR 7/8 + addenda). One correction to this bullet's own prediction:
  the `sqrt(N)` density compensation described above was actually built,
  then **removed** — it made the resulting `bomb` control read as a
  zoom/density knob rather than a clustering knob (cell pitch and jitter
  rescaled together, mechanically identical to `density` itself).
  Point density now genuinely rises with bombing — the density/
  irregularity coupling this whole file is about is reintroduced by
  bombing itself, not resolved by it. Confirmed real overlap does occur
  (clustered marks genuinely intersecting), but only once combined with
  `mag_weight` (field magnitude → mark size) — priority-based selection
  alone, without mark growth, never produces overlap regardless of how
  it's tuned. That distinction — selection vs. growth — wasn't obvious
  going in and is worth remembering for any future placement mechanism
  in this family.

## Sharpened description of the itch (2026-07-03 discussion)

Came back to this via a discussion of `f_grain`/`f_vf_seeds` overlap
(see `ideas/voronoi_vs_texture_bombing.md`) — Matt initially named that as
a separate question, but on reflection considers grid-rigidity and
cell-boundary clipping to be facets of the same felt problem, not two
things to solve independently.

Talked through it in plain, non-mechanism language rather than starting
from architecture. What actually surfaced, in Matt's own terms:

- **Even with jitter and `size_var` maxed out, it still reads as
  regular.** And a real coupling was named directly: turning up
  `size_var` (irregularity) isn't independent of density, because the
  grid is fixed-size underneath — cranking irregularity necessarily
  changes how dense it looks, whether or not that's wanted. Irregularity
  and density are tangled together instead of being separate dials.
- **This is not a ceiling problem — it's structural.** No amount of
  dialing existing params (jitter, size_var, density) fixes it, because
  the grid itself produces the regularity. It's not that jitter=1.0
  isn't irregular *enough* — it's that no jitter value on top of a grid
  produces what's wanted, because the structure is wrong, not
  under-tuned. This is a stronger claim than the file's original framing
  above ("has grid-scale structure baked in... implicit max
  irregularity") — Matt is saying it's not about raising that ceiling.
- **Size/clipping matters differently per module.** In `f_grain`,
  flattening/cutoff at high size reads as fine — Matt uses `f_grain` at
  smaller sizes for textural/surface effect, and the flattening reads as
  part of the irregularity, not a bug. In `f_vf_seeds` it's more of a
  problem, because each mark is meant to carry individual meaning — a
  flattened/cut mark reads as broken rather than textural. **Different
  modules, different tolerance for the same underlying limitation** —
  not a shared bug to fix identically.
- **The sharpest and most concrete point:** when a vecfield is driving
  flow/orientation (as in `f_vf_seeds`), places where the field naturally
  converges or compresses *should* produce marks that overlap or crowd
  together — that's what the field is telling the placement to do.
  Currently the grid prevents that regardless of what the field wants.
  Matt was explicit this is not about clumping or chaotic piling — it's
  about overlap happening **the way the field's own information would
  predict**, i.e. field-driven convergence should be visually honored,
  not discarded by the placement substrate. Right now that information
  (see `discrete_item_family.md`'s note that vecfield magnitude is
  already an under-used "free second parameter") gets computed but can't
  express spatially because of how seeds are placed.

**Reframing, not yet a design decision:** this isn't "add overlap as a
mode" or "swap in a fancier distribution algorithm" as two small
independent moves. Both symptoms (regularity that won't relax, and
field-convergence that can't show up as overlap) point at the same root
constraint on the placement layer itself. What replaces or relaxes that
constraint is still completely open — the candidate directions listed
above (Poisson disk, density-field scatter, texture-fed point set,
grid-as-search-structure-only hybrid) are still the live options, none
chosen, none newly favored by this conversation. This entry exists to
record the *felt problem* precisely, before any mechanism gets picked.

## Priority as a generalized quantity (GPU Gems Ch. 20 reread, 2026-07-04)

Went back to Ch. 20 specifically to check whether its language on priority
and multiple-images-per-cell was already covered here, since our framing
uses different terms. It wasn't fully — this section captures what's
missing, and it reframes the "sharpest point" above rather than adding a
new candidate direction alongside it.

**The core finding: the chapter's Voronoi mode and its texture-bombing
mode are the same code shape**, differing only in what feeds a single
`priority` value in an otherwise identical reduction over the neighborhood
candidates:

```
if (candidate_priority > priority) { color = candidate; priority = candidate_priority; }
```

- Voronoi mode: `priority = -distance²` — nearest candidate always wins,
  hard partition, no overlap. This is what `f_vf_seeds`' `best_gx`/
  `best_gy` reduction already does, just via `step`/`mix` instead of an
  explicit priority variable.
- Texture-bombing mode: `priority = random.w` (an arbitrary per-image
  value) — real overlap becomes possible, since the winner isn't
  necessarily the nearest candidate, just whichever has the higher
  priority. Still single-owner-per-pixel — no alpha compositing needed.

**This directly answers the "sharpest point" above.** The itch was:
field convergence should be able to produce mark overlap, "the way the
field's own information would predict" — not clumping, not randomness.
The chapter's mechanism gives a concrete way to do exactly that without
a new search structure: swap `priority` from `-distance²` to something
derived from the vecfield at each candidate (field magnitude/convergence,
or a blend of distance and field-derived weight). A candidate seed sitting
in a zone of strong field convergence could then win pixels its distance
alone wouldn't earn it — overlap driven by the field's own data, still
resolved as a single winner per pixel, no compositing-rule problem to
solve. The 9-candidate search already computes what's needed for this;
the change is in the reduction, not the search.

**This is a smaller fork than `voronoi_vs_texture_bombing.md` currently
describes.** That file frames Voronoi-vs-bombing as two identities that
can't be gradually interpolated — "a 'blend' toggle would really be a
fork in which parts of the codebox even run." The priority-generalization
view says otherwise: it's the same reduction loop, one line swapped.
Worth revisiting that file's "why this isn't a toggle" argument in light
of this — flagged there directly, not resolved here.

**Secondary confirmation, smaller: density-as-priority-threshold.** The
chapter's controlled-variable-density mode (20.3.2) doesn't gate presence
with a separate branch — it sets each candidate's *initial* priority
threshold from a density texture (e.g., start at 0.5, so only candidates
whose `random.w` clears that bar appear at all). This is the same
priority-as-generalized-quantity move applied to presence/absence rather
than winner-selection, which means density-field-driven scatter (already
a candidate direction above) and field-driven overlap could plausibly
share one mechanism rather than being two separate features to design
independently.

## Relationship to current work

Not blocking f_vf_seeds in its current form — the shape-tex architecture and
size+stretch simplification stand on their own regardless of seed
distribution method. This is a separate, deeper architectural question about
the placement layer specifically, worth its own spec→plan→tasks cycle when
picked up.
