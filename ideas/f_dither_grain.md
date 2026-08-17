# f_dither_grain (name TBD) — idea

_Captured 2026-07-21, architecture discussion only, not specced._

## Concept

Parametric dithering reframed as a `f_grain`-family processor: instead of
smooth blending between two (or more) arbitrary hues, a jittered grain
field decides, per-cell, which hue wins — using the same
threshold-vs-scalar mechanism as classic ordered dithering, but applied
to hue selection rather than luminance-to-black/white.

Core mechanism, generalized from ordered dithering:
- `t` = a scalar in `[0,1]` at each cell, representing position between
  hue A and hue B (or, extended, position along a sequence of N hues)
- `d` = a per-cell dither threshold (see "Regularity" below)
- output = `hue_A` if `t < d`, else `hue_B`

For N > 2 hues: treat hues as an ordered sequence, `t ∈ [0, N-1]`,
`floor(t)` selects the adjacent pair, `wrap(t)` (GenExpr has no `fract()`)
feeds the same single-boundary test locally within that segment. This
gives posterized hue bands with dithered seams, rather than independent
per-pixel N-way blending (that's a different, more expensive
Voronoi-adjacent approach — not this idea).

## Why grain, not a Bayer/blue-noise texture

Framing as a grain field (vs. a fixed dither matrix) means size, shape,
and regularity of the dither pattern become first-class continuous
params, reusing `f_grain`'s already-solved vocabulary rather than
inventing new ones:

| Param | Role here |
|---|---|
| `density` | grains per field |
| `size` / `size_var` | grain radius + variance |
| `shape` | circular → elongated (becomes an *axis* once vecfield-driven, see below) |
| `jitter` | **regularity dial**: `0` = grain centers on a regular grid (Bayer-like, screen-locked, repeating), `1` = hash-displaced within cell (blue-noise-like, no visible grid). One dial spans the whole regular↔stochastic continuum instead of two code paths. |
| `sv_seed` | random seed |
| `edge_mode` | edge handling, same as `f_grain` |

Key difference from `f_grain`: `f_grain`'s `luma_gate` decides *whether*
a grain appears (binary-ish gating from source luminance). Here, grain
existence is closer to `f_grain`'s always-on grid — what the driving
texture decides is *which hue* each grain resolves to, via the `t` vs
`d` test above.

## Vecfield as a driver — decoupled from hue-boundary `t`

Decision (2026-07-21, Matt's call): **decoupled**, not coupled. Vecfield
and driving-texture are separate inputs, at least for the first pass.
Coupling one field to do double duty (both `t` and morphology) is more
interesting visually but harder to debug — revisit only after the
decoupled version is proven out.

Two separable roles for the vecfield, each mirroring an existing
consumer pattern already in the repo:

1. **Magnitude → size/density** — same role magnitude plays in
   `f_caustic` (convergence-weighted accumulation). Strong magnitude at
   a cell → bigger/denser grains; weak → smaller/sparser. Distance-from-
   site (e.g. from a `f_vf_vortex` source) is a special case of this —
   don't need a separate "distance" input, magnitude on a vortex-sourced
   field already falls off with distance.
2. **Direction → shape/elongation axis** — same role direction plays in
   `f_vf_chroma`/`f_vf_prism` (streak axis). Grains stretch along local
   flow direction instead of a fixed/global orientation. This is the
   genuinely novel piece — no existing module orients grain *shape* from
   a field (only streak/blur kernel direction).

## Architecture (decoupled, first pass)

Three inputs:
1. **Driving texture** — feeds per-cell `t` sample (hue-boundary
   position)
2. **Vecfield inlet** — magnitude → size/density, direction → shape axis
3. **Hue source(s)** — default to **static color params** (`hue_a`/
   `hue_b`, or an ordered N-hue list for the sequence case), not
   texture-driven, to keep the first pass to one axis of complexity.
   Texture-driven hues are a possible later extension, not scoped now.

This makes it structurally closer to `f_caustic`'s two-driving-input
shape than to `f_grain`'s single-input shape.

## Proposed Phase 0 scratch sequence

Mirrors the isolation approach used for `f_vf_optical_flow`'s buildup —
each phase confirms one variable before the next is added:

- **Phase 0a** — regular grid of grains (`jitter=0`), no vecfield. Static
  `t` gradient (or the driving texture) against two flat hues. Confirms
  the core threshold-per-cell mechanism actually reads as a dithered
  boundary, not just noise.
- **Phase 0b** — add `jitter` (regularity dial) alone, still no
  vecfield. Confirms the regular→stochastic continuum behaves as
  expected in isolation.
- **Phase 0c** — add vecfield, magnitude→size only. Confirms that role
  in isolation.
- **Phase 0d** — vecfield direction→shape/elongation. Confirms the novel
  role, most likely to need iteration.

Only after all four read well independently is coupling `t` and vecfield
into one shared source worth revisiting.

## Hue-boundary heuristic (resolved 2026-07-21)

**Decision: driving texture actually encodes hue** (a live color source,
not a synthetic scalar) — Matt's call. This resolves the
fixed-list-vs-hue-wheel question via a general heuristic, worth keeping
for future similar decisions:

> If the driving scalar has genuine circular topology (hue angle,
> oscillator phase, an `atan2` off a vecfield), derive palette order
> from that same topology — wraparound falls out for free and "nearest
> neighbor" boundaries are the only choice that doesn't produce a seam
> artifact. If the driving scalar is arbitrary (luminance, distance,
> vecfield magnitude, noise), use a fixed authored order — there's no
> real angle to derive from, so imposing one is arbitrary rather than
> topology-preserving.

Since the driving texture is a live hue source, this resolves to
**hue-wheel angle**, which changes several things below the surface:

- **`t` is no longer a synthetic gradient** (as Phase 0a originally
  assumed) — it's derived from the driving texture's actual hue angle
  (standard HSV-style extraction). Phase 0a can still use an authored
  test texture (e.g. an actual hue-wheel gradient image) rather than a
  live camera feed, to keep the scratch setup cheap while exercising the
  real code path.
- **Authored hues (`hue_a`/`hue_b`/N-hue list) get sorted by their own
  hue angle before use**, rather than used in authored/typed order.
  Sorting is what makes wraparound free — with reference hues pre-sorted
  by angle, "nearest neighbors" and "the wrap seam" fall out
  automatically instead of needing special-casing. (Matt still authors
  arbitrary hues — sorting only reorders them, it doesn't constrain
  which hues can be chosen.)
- **Per-cell test gains a bracket-finding step upstream of the dither
  test**: compute the cell's hue angle → find which two sorted
  reference hues bracket it → compute fractional position between just
  those two → run the same threshold-vs-`d` test as before, local to
  that bracket. Wraparound at the 0/1 seam uses `wrap()`, not naive
  subtraction (per the standing GenExpr trap).
- **Style choice, not architecture, left open:** auto-sort by hue angle
  (smooth, perceptually continuous transitions) vs. an option to
  preserve authored order (lets Matt deliberately place
  clashing/complementary hues adjacent for a harsher effect). Cheap to
  expose as a toggle later — doesn't block Phase 0.

## Low-saturation edge case (open, with a known-good precedent)

Hue angle is undefined/numerically unstable for near-grey (low
saturation) pixels — the driving texture will inevitably have some.
`f_hue_processor` already solved exactly this problem for hue-selective
processing: a `smoothstep(0.05, 0.15, S)` low-saturation gate suppresses
the hue-dependent effect entirely below that threshold, independent of
whatever the (unstable) hue reading says.

Same fix should apply here directly: below the saturation gate, skip
bracket-finding/dither entirely and fall back to a single designated
hue (or a neutral/grey grain) rather than letting unstable hue readings
drive boundary placement. Not yet decided which fallback (designated
hue vs. grey) reads better — worth testing both once Phase 0a is
running.

## Other open questions, not yet decided

- Whether hue source *also* needs to support non-texture-driven mode
  later (i.e. keeping the originally-considered fixed-list path as an
  alternate mode, not just superseded) — not needed for Phase 0, but
  worth a note if the module ever tries to serve both cases.
- Whether this ends up needing `pix_chain` (multi-stage, like
  `f_vf_optical_flow`) or fits a single codebox like `f_grain` — depends
  on whether the vecfield-driven shape/orientation math is cheap enough
  inline.
- Module naming — `f_dither_grain` is a placeholder.

## Status

Idea only. Not specced, not scratch-tested, not scheduled.
