# f_vf_seeds — Bpatcher Spec

_Last updated: 2026-07-05_
_Status: Working_

## Concept

Placement and orientation engine for discrete marks. Stable seed points
distributed across the frame (jittered grid, hash-stable), each rendered
by sampling an external shape texture in seed-local UV space, oriented by
a vecfield sampled at that seed's position. No internal mark geometry —
shape character comes entirely from the shape tex inlet.

Two evolutions beyond the original single-owner-per-pixel design, both
2026-07-04/05:

- **Priority-generalized selection** — seed selection blends pure
  nearest-distance (Voronoi) with vecfield magnitude, so field convergence
  can influence which seed wins a pixel, not just geometric proximity.
- **Multi-owner overlap (texture bombing)** — the real payoff. Retaining
  and compositing the top-2 candidates by priority, plus a second
  jittered sample per cell, so marks can genuinely overlap where the
  field indicates convergence — not just warp cell boundaries.

Traces to GPU Gems Ch. 20 ("Texture Bombing") throughout — see References.

## Parameters

| Name | Type | Range | Description |
|------|------|-------|--------------|
| `density` | float | 0–1 | Seed spacing — log-mapped, higher = more seeds |
| `jitter` | float | 0–1 | Seed position randomness (0=regular grid, 1=fully stochastic) |
| `size` | float | 0–0.5 | Mark size — overall scale |
| `stretch` | float | 0–1 | 0=circular/square, increasing elongates along field direction |
| `strength` | float | 0–1 | Vecfield influence on orientation (0=rightward, 1=full field) |
| `mag_weight` | float | 0–1 | Field magnitude → mark size modulation — the actual mechanism that grows marks into each other's territory (selection alone never produces overlap) |
| `field_priority` | float | 0–1 | 0=nearest-distance (original Voronoi behavior), 1=field-magnitude-only (degenerate boundary, not "high overlap") |
| `field_gain` | float | -1.5–1.5 | Field-priority scale. Useful window varies ~7.5x by vecfield source (Flow ~0.2, Repulse ~0.8, Vortex ~1.5) — exposed via `range_tiers` menu |
| `bomb` | float | 0–1 | Second-sample-per-cell toggle. **Behaves as on/off, not a graded fader** — see Key Findings |
| `phase` | float | -1–1 | Scroll marks along field direction (connect LFO for motion) |
| `size_mod` | float | -1–1 | Mod tex → size modulation depth (bipolar) |
| `stretch_mod` | float | -1–1 | Mod tex → stretch modulation depth (bipolar) |
| `bypass` | toggle | — | Fully transparent output (not opaque black — see Key Findings) |

## Inlets

| Inlet | Type | Description |
|---|---|---|
| 0 | texture (required, driving) | Shape tex — mark footprint, oriented rightward, centered, any color. Combined with all control messages on this same physical inlet per Vsynth convention. |
| 1 | texture (required) | Vecfield — float32 RG, drives mark orientation and (via `mag_weight`/priority) mark growth and selection |
| 2 | texture (optional) | Mod tex — sampled at seed UV, per-seed weight/marklen modulation |

## Outlets

| Outlet | Description |
|---|---|
| 0 | Mark color — composited rank-1-over-rank-2, gated by mark footprint |
| 1 | Mark mask — luma of composited mark, greyscale |
| 2 | Seed coord — **rank 1's UV position only.** Rank 2 isn't exposed here; this preserves the pre-Evolution-2 contract exactly (there was only ever one rank before) |

## Architecture

Six-stage `jit.gl.pix` chain — not one codebox, and not four. A
single-codebox implementation of the render/composite logic hit a hard
platform ceiling (Max's GL2→GL3 shader transformer's Lua `DSL.Parser`
capture-group limit, confirmed via console error). Splitting render into
its own stages resolved that; extending the search to 18 candidates for
bombing hit the **same** ceiling again, at Stage 1 alone with zero render
logic involved — resolved by splitting Stage 1 itself into two halves
plus a small merge stage.

```
Stage 1a — 9-candidate search + top-2 select, original hash salts
Stage 1b — same codebox as 1a (salt-parameterized reuse, not a
           duplicate file), bombing hash salts, active_blend fades
           its candidates in/out via the outer `bomb` param
Stage 1c — merge: small top-2 insertion across the two halves' already-
           reduced results (4 candidates in, not 9 or 18). Also outputs
           a properly zero-padded seed-coord (gx,gy,0,1) wired directly
           to the module's outlet 2, bypassing Stage 4 entirely
Stage 2/3 — render: full per-candidate downstream (orientation
            projection, mod-tex sample, gate, shape sample, luma alpha),
            one shared codebox instanced once per rank
Stage 4   — composite: rank-1-over-rank-2 alpha composite using rank 1's
            own luma-keyed alpha as the blend factor. bypass lives here
            (and independently on Stage 1c, for the seed-coord outlet)
```

**Luma-keyed alpha (prerequisite for correct compositing):** mark color's
alpha is `mark_luma` (shape luma × gate), not a hardcoded `1.0`. Without
this, overlapping marks read as hard black rectangles instead of
respecting the shape tex's own masked silhouette — the rectangular gate
has no relationship to the shape texture's actual content. Same
luma-gating idiom `f_grain` already uses, applied here to the alpha
channel specifically. Bypass output is fully transparent `(0,0,0,0)`,
not opaque black.

**Selection reduction — insertion into (best, second), not just a single
winner:** each new candidate is compared to current best; whichever loses
that comparison (new candidate or demoted old best) then competes
against current second. Mechanical extension of the same `step`/`mix`
"lower wins" idiom already used for single-winner selection.

**Bombing density compensation — tried, removed.** An earlier version
compensated cell scale by `sqrt(2)` as `bomb` rose, to hold point count
constant. This made `bomb` read as a zoom/density control instead of a
clustering control (cell pitch and jitter rescaled together, identical to
the `density` param itself). Removed — `bomb` now genuinely raises point
density, reintroducing the density/irregularity coupling question already
open in `ideas/seed_distribution_beyond_grid.md`, in exchange for `bomb`
actually meaning "more items."

**Priority sentinel:** each search half's second-sample candidates use
`priX = mix(sentinel, priXr, active_blend)` to force them to lose when
`active_blend=0`. `sentinel` defaults to `5.0` — see Key Findings for why
this can't be tuned into a graded fader.

## Build

**Not built via `tools/build_patcher.py`.** Same category of limitation
as `f_sirds`: `param_connect` (Live's per-object parameter binding) only
binds a dial to one named pix object, but most params here need to reach
*two* differently-named stages at once (e.g. `density` → both search
halves). Built instead via a dedicated script:

```
.specify/f_vf_seeds/definition.py               — documented source of truth
.specify/f_vf_seeds/codebox_seeds_search.gen     — Stage 1a/1b template (salts via .format())
.specify/f_vf_seeds/codebox_seeds_merge.gen      — Stage 1c
.specify/f_vf_seeds/codebox_seeds_render.gen     — Stage 2/3 template
.specify/f_vf_seeds/codebox_seeds_composite.gen  — Stage 4
.specify/f_vf_seeds/build_seeds_multistage.py    — generates patchers/f_vf_seeds.maxpat
```

Run: `python3 .specify/f_vf_seeds/build_seeds_multistage.py`
Validate: `python3 -c "import json; json.load(open('patchers/f_vf_seeds.maxpat'))"`

## Key Findings

**Selection alone never produces overlap — this took real testing to
confirm, not just reasoning.** Priority-based selection only warps *which
single candidate wins* each pixel; exactly one candidate is ever drawn
regardless of how priority is computed. `mag_weight` (mark size grows
with field magnitude) combined with genuine multi-owner compositing is
what actually produces overlap — cranking `field_priority`/`field_gain`
alone, with `mag_weight=0`, shows zero overlap no matter how far it's
pushed.

**`bomb`/`active_blend` behaves as an on/off toggle, not a graded fader —
confirmed empirically, not a bug.** Real priority magnitude scales with
`density`/`jitter`/`field_gain`/`field_priority` together; no single
fixed `sentinel` constant stays correctly scaled relative to that moving
target. Tried `sentinel=1000` and `sentinel=5` — both produced a
near-hard-switch right at `active_blend≈1.0` rather than a smooth
transition across the whole range. Fixing this properly would mean
computing `sentinel` dynamically from the current priority range — real
added complexity for a control most performers would use fully-on or
fully-off anyway. Left as a toggle.

**A structurally-valid, JSON-verified patch can still be functionally
broken at runtime — twice, this session, in two different ways.** (1) The
compile-ceiling discovery (ADR 8) — a shader that never finished
compiling left `jit.gl.pix` in a broken state that looked like a render
bug. (2) A `route`/`prepend` message-rename chain that validated
perfectly as a box graph but silently dropped its value in Max — found
only by placing a `print` object in the chain and watching the console.
Neither was visible from JSON inspection alone.

**Direct-`attrui`-binding beats message renaming.** An `attrui`'s
*output* name comes from its own `attr` property, not from whatever fed
its inlet — so `bomb`'s dial can display/save/automate as "Bomb" while
feeding an `attrui` bound directly to `active_blend`, with no rename
message chain at all. Simpler and more reliable than the `route`/
`prepend` approach it replaced.

## Open Questions

- **fps at higher bombing depth or 4K** — confirmed 60+fps at the current
  K=2/N=2 configuration; not tested beyond that.
- **Mark shape/edge AA quality** — smoothstep-only antialiasing is rough;
  blocked on whether GenExpr exposes `ddx`/`ddy` screen-space derivatives
  (unconfirmed — see `ideas/line_edge_antialiasing.md`).
- **Density/irregularity coupling** reintroduced by removing bombing's
  density compensation — same open question as
  `ideas/seed_distribution_beyond_grid.md`, not resolved by this work,
  just no longer masked by compensation math.
- **Compositing depth beyond N=2** not attempted — would need its own
  fps measurement, not assumed to scale linearly from N=2's cost.
- **Mod-tex-driven per-seed softness/low-pass control** — queued
  near-term enhancement, not scoped.

## Source File

`patchers/f_vf_seeds.maxpat`

## References

GPU Gems Ch. 20, "Texture Bombing" (Vol. 1) — the multi-sample-per-cell
mechanism and its cell-scale/density-compensation formula, adapted (and
ultimately partially reverted — see Architecture) for this module's
selection-based rather than pure-scatter placement model.

`docs/f-reference/f_vecfield_type.md` — float32/signed-value texture
convention followed for the inter-stage coordinate textures carrying
signed `dx`/`dy` offsets.
