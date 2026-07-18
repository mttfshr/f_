# f_vf_seeds — Spec: Priority-Generalized Selection

**Status:** Evolving existing module (v1 shipped, registered, in production) —
this spec covers the next phase of f_vf_seeds' lifecycle: generalizing seed
selection from pure nearest-distance to a generalized priority function,
enabling field-driven mark overlap.

**Created:** 2026-07-04
**Related:** `ideas/seed_distribution_beyond_grid.md`,
`ideas/voronoi_vs_texture_bombing.md`

---

## Concept

f_vf_seeds currently selects, for each pixel, the nearest seed among a 3x3
jittered-grid neighborhood (9 candidates), using squared distance as the sole
selection criterion — a hard Voronoi partition, one owner per pixel, no
overlap possible by construction.

This evolution generalizes that selection: swap the value driving the
winner-take-all reduction from raw squared distance to a **priority** value
that can incorporate other information — starting with vecfield magnitude at
each candidate, so that a candidate seed sitting in a zone of strong field
convergence can win pixels its distance alone wouldn't earn it. Overlap
becomes something the field's own data predicts, not clumping or randomness
introduced separately.

This is deliberately an **evolution of the existing module**, not a new
sibling module. A separate "seed distribution" module would duplicate this
same reduction loop with no distinct identity of its own — once f_vf_seeds
can do priority-based selection, there's nothing left for a second module to
be. (Reasoned through directly with Matt, 2026-07-04 — the value proposition
of a separate module drops to zero once this lands here.)

Source: this direction traces to GPU Gems Ch. 20 ("Texture Bombing") reread
2026-07-04 — its Voronoi mode and its texture-bombing mode turn out to be the
same reduction loop, differing only in what feeds a single `priority` value
(`-distance²` vs. an arbitrary per-image value). Both stay
single-owner-per-pixel; no compositing/blending required either way.

## Explicitly Deferred (this evolution, tabled for later)

- **Multi-sample-per-cell** — a separate mechanism (looping N samples within
  each of the 9 cells rather than 1) for combating grid-scale regularity.
  Conflates two open questions if bundled with priority-generalization; kept
  as its own future item in `ideas/seed_distribution_beyond_grid.md`.
- **4-cell (2x2) neighborhood search** — considered and explicitly declined
  for now. Correctness at this codebox's full jitter range (up to ±0.5 cell
  offset at `jitter=1.0`) requires the current 3x3/9-candidate search; a 2x2
  reduction (Gustavson 2011) introduces real artifacts at exactly the jitter
  settings this module already treats as expressive, not edge-case. Decision:
  keep 9 for correctness, accept the cost, revisit only if
  priority-generalization's per-candidate texture-sampling cost (below) turns
  out to make 9 candidates prohibitively expensive in practice.
- **True multi-owner alpha-blended overlap** — a further step beyond
  priority-based single-owner selection, requiring an actual compositing
  rule. Not needed for the field-driven-overlap goal; single-owner-per-pixel
  via priority already satisfies it.
- **Density-as-priority-threshold** — GPU Gems Ch. 20's variable-density mode
  (20.3.2) uses the same priority-as-generalized-quantity idea for
  presence/absence rather than winner-selection. Noted as a plausible shared
  mechanism with the existing "density-field-driven scatter" candidate
  direction, not scheduled in this pass.

## Signal Flow (unchanged)

```
in0 — shape tex   (codebox in1 — mark footprint)
in1 — vecfield    (codebox in2 — drives orientation AND, new, priority)
in2 — mod tex     (codebox in3 — per-seed weight/marklen modulation)

out0 — mark color
out1 — mark mask
out2 — seed coord
```

No change to inlet count, typing, or downstream (orientation, gating,
shape-tex sampling) — confirmed by direct read of `codebox_seeds.gen`: the
selection reduction is self-contained, and everything after
`best_gx`/`best_gy`/`best_dx`/`best_dy` operates on whichever candidate wins,
regardless of why it won.

## Parameter Contract — additions

| Param            | Type  | Range | Default | Description |
|------------------|-------|-------|---------|--------------|
| `field_priority` | float | 0–1   | 0.0     | Blends seed selection from pure nearest-distance (0) toward field-magnitude-driven priority (1). Follows the same base→field blend idiom as `strength` (orientation). At 0, behavior is identical to current shipped module. |
| `field_gain`     | float | see below | 0.0 | Live performable dial — its raw value is the effective scale applied to field magnitude in the priority calculation directly. No separate scale param, no codebox-side range logic. Ships with `"range_tiers": [0.2, 0.8, 1.5]` (per `definition.py` convention, precedent: `f_vf_advect`'s `dt`/`injection`) — a pure UI-layer numeric menu that rescales this same dial's live max between the three empirically-tested per-field windows below. Whatever tier is active, the value reaching the codebox is always just `field_gain`. |

**Resolved (was open in original draft of this spec):** distance and field
magnitude are not on a common scale, and — critically — **the useful
scale doesn't generalize across vecfields either.** Empirical testing
(2026-07-04) found meaningfully different useful ranges per field: Flow
~±0.2, Repulse ~±0.1–0.8, Vortex ~±1.5 — roughly a 7.5x spread between
Flow and Vortex. A single baked-in constant (the original ADR 4 plan)
cannot serve all of these; either it does nothing on narrow-window fields
or immediately collapses into the degenerate wedge regime (see Character
Space) on them. **ADR 4 is reversed as a result** — see plan.md.
`field_gain` ships live, with `range_tiers` (the same mechanism already
used by `f_vf_advect`) handling the per-field range difference entirely
in the UI layer — no second param, no codebox branching, just a menu that
rescales one dial's max.

**Existing params — all unchanged in meaning:** `density`, `jitter`, `size`,
`stretch`, `phase`, `mag_weight`, `size_mod`, `stretch_mod`, `strength`.
`jitter`'s current range/behavior is explicitly preserved per the 4-cell
decision above — no interface change to it in this pass.

## Codebox Architecture — the selection swap

Current (`codebox_seeds.gen`, confirmed by direct read 2026-07-04):

```
// vecfield sampled ONCE, after selection, at the single winner
vx = (sample(in2, vec(best_gx, best_gy)).x - 0.5) * 2.0;
vy = (sample(in2, vec(best_gx, best_gy)).y - 0.5) * 2.0;
```

Selection reduction (unrolled A–I, 9 candidates):
```
best_d=dA; best_gx=sxA; ...
t=step(dB,best_d); best_d=mix(best_d,dB,t); best_gx=mix(best_gx,sxB,t); ...
// ... repeated through I
```

Evolved shape (scratch-only until Phase 1/2 confirm it):

- Sample the vecfield at **each** of the 9 candidate positions (`sxA/syA` …
  `sxI/syI`), before selection — a real cost increase (9 texture samples vs.
  today's 1), to be measured, not assumed free.
- Compute a `priority` value per candidate: `priority = mix(d, -field_mag *
  field_gain, field_priority)` — `field_gain`'s live value is used directly,
  no separate scale param or codebox branching — in the existing "lower
  wins" convention so it drops into the current `step`/`mix` chain
  unchanged.
- Everything downstream — vecfield sampling for orientation, mod-tex
  sampling, along/across projection, shape-tex gating — is unmodified; it
  already operates on `best_gx`/`best_gy`/`best_dx`/`best_dy` regardless of
  how those were chosen.

## Character Space (confirmed empirically, scratch testing 2026-07-04)

| field_priority | Confirmed character |
|----------------|---------------------|
| 0.0 | Identical to shipped v1 — hard Voronoi partition, no overlap. Confirmed via direct comparison at both `jitter=0.5` and `jitter=1.0`. |
| 0.0 < x < 1.0 | Real, graded partition warp — cell boundaries visibly reshaped by field magnitude, distance still contributes. This is the useful, tunable range. Confirmed at `field_priority=0.10` (Repulse) and `0.5` (gradient field). A moving priority-flip seam is visible at low `field_gain` values within this range — confirmed to shift when `field_gain` changes, i.e. a real effect of the mechanism, not an artifact. |
| 1.0 | **Degenerate boundary, not a continuation of "high overlap."** `mix(d, -field_mag*field_gain, 1.0)` discards the distance term entirely — provable directly from the formula. Only the *sign* of `field_gain` can affect the outcome at this exact value, never its magnitude. Visually: large blocky wedge-collapse regions (confirmed across three different fields — a smooth gradient, Repulse, Vortex), where the local 9-candidate neighborhood's ranking is the same across broad contiguous areas. Not useful as a performance setting on its own; the graded behavior lives strictly inside `(0, 1)`. |

**Tuning technique (discovered during Phase 2 empirical testing):** test
at `jitter=0`. With no jitter, the distance term is perfectly uniform
across the whole frame, so any visible distortion is attributable
directly to the field-priority term, with no jitter noise competing for
attention — a much cleaner diagnostic than testing at `jitter=1.0`, where
jitter randomness and field-driven flips are both contributing to what's
visible and hard to separate. Recommended as the standard way to tune
`field_gain` per field: dial it in at `jitter=0`, then bring jitter back
up and reconfirm.

## Acceptance Criteria

### Phase 1 — Scratch patch: mechanism proof
- [x] Per-candidate vecfield sampling implemented in scratch codebox (copy,
      not production file)
- [x] `field_priority` blend implemented per the selection swap above
- [x] Visually confirms field-driven overlap reads as "field information
      showing through," not noise/glitching — confirmed across four
      fields (gradient test field, Repulse, Vortex, Flow)
- [x] `jitter` at existing mid/high settings unaffected (regression check,
      since 9-cell search is unchanged) — confirmed at `field_priority=0`,
      both `jitter=0.5` and `1.0`

**Phase 1 complete.**

### Phase 2 — Empirical tuning
- [x] Normalization constant for distance-vs-field-magnitude scale mismatch
      found and documented — **resolved, but not as a single constant.**
      Useful range varies ~7.5x across fields tested (Flow ~±0.2, Repulse
      ~±0.1–0.8, Vortex ~±1.5) — a single baked-in value can't serve all
      of them. **ADR 4 reversed as a result** (see plan.md): `field_gain`
      ships as a live param, with `range_tiers: [0.2, 0.8, 1.5]` (the
      three tested windows, verbatim) handling the per-field difference
      as a pure UI menu convenience — same mechanism already used by
      `f_vf_advect`'s `dt`/`injection`, no codebox branching involved.
- [x] fps measured at target resolution: 9-sample-per-pixel vs. current
      1-sample baseline; delta documented — **1920×1080: 60+fps.
      3840×2160: 58–60fps.** Cost is negligible; ADR 2 (keep 9 candidates)
      confirmed by evidence.
- [x] Decision recorded: is the cost acceptable for live performance use —
      **yes**, at both tested resolutions up to 4K.

**Phase 2 complete.**

### Phase 3 — Promotion to production
- [x] `codebox_seeds.gen` updated with confirmed mechanism
- [x] `definition.py` updated with `field_priority` and `field_gain`
      (`"range_tiers": [0.2, 0.8, 1.5]`) params
- [x] `tools/build_patcher.py` regenerates `patchers/f_vf_seeds.maxpat`; JSON
      validated
- [ ] Opens in Max; all params (existing + new) respond correctly; UI layout
      correct — **needs confirmation in Max, not yet checked**
- [ ] Regression check: `field_priority=0` output matches pre-change
      behavior exactly — **needs confirmation in Max, not yet checked**

### Phase 4 — Integration + docs
- [ ] Existing integration points re-verified — no regression
- [ ] `docs/f_vf_seeds.md` updated with `field_priority`, attribution to GPU
      Gems Ch. 20 per attribution practice
- [ ] Helpfile updated if one exists / created per `f-helpfile` skill
      conventions
- [ ] `ideas/seed_distribution_beyond_grid.md` and
      `ideas/voronoi_vs_texture_bombing.md` status updated to reflect landed
      work
- [ ] Committed with descriptive milestone message

---

## Evolution 1.5 — Luma-Keyed Alpha on Mark Output (SHIPPED)

**Status:** Landed in production `codebox_seeds.gen` and rebuilt
`patchers/f_vf_seeds.maxpat`, 2026-07-04 (same session as Evolution 2 below).
Not part of the original priority-generalization scope — surfaced as a
prerequisite bug once field-driven overlap was actually being tested.

**Problem:** `out1`'s alpha was hardcoded to `1.0` regardless of the shape
texture's own content. The mark footprint gate (`step(abs(along_shifted),
marklen_eff) * step(abs(across), weight_eff)`) is a rectangular bounding-box
test with no relationship to what's actually inside the shape texture at
that pixel. Any pixel inside the gate — including the shape tex's own black
background — reported full opacity. Wherever priority-driven selection
caused a candidate to win a pixel its own shape didn't actually cover
(exactly the zones Evolution 1 was meant to enable), the result was a hard
black rectangle, not a masked mark.

**Fix:** `mark_luma` (shape luma × gate) already existed in the codebox —
it was being computed and discarded as a separate grayscale mask output
(`out2`) instead of feeding the channel that would make it act as
transparency. Swapped `out1`'s alpha from `1.0` to `mark_luma`, and bypass
from opaque black `(0,0,0,1)` to fully transparent `(0,0,0,0)` (consistent
with alpha now meaning something). `out2`/`out3` unchanged.

**Decision: raw luma, no threshold.** Considered a hard `step()` cutoff for
crisper edges, but raw luma gives graded/soft edges for free on any shape
tex with its own AA, and needs no new param. Matt's call: start here, add a
threshold only if scratch testing shows a real need (untested so far, no
need surfaced).

**Decision: compositing stays downstream.** This module doesn't do
alpha-aware blending itself — Matt confirmed existing Vsynth compositing
modules already handle that; `f_vf_seeds`' job is just to output correct,
meaningful alpha.

Same idiom `f_grain` already uses per the README ("luma gating") — applied
here to the alpha channel specifically rather than a separate mask layer.

---

## Evolution 2 — Multi-Owner Overlap (Texture Bombing + Compositing)

**Status:** Architecture decided 2026-07-04, not yet built. A hard platform
ceiling was hit mid-session (see plan.md ADR 8) that forces a materially
different implementation shape than originally assumed — this section
documents the revised plan, not the original single-codebox approach.

### Why Evolution 1 alone wasn't enough

This file's original "Explicitly Deferred" section stated: *"True
multi-owner alpha-blended overlap — a further step beyond priority-based
single-owner selection... Not needed for the field-driven-overlap goal;
single-owner-per-pixel via priority already satisfies it."* **This
assumption is wrong, confirmed empirically 2026-07-04.** Matt tested
Evolution 1 with `field_priority`/`field_gain` cranked and saw no overlap —
correctly diagnosed as structural: priority-based selection only warps
*which single candidate wins* each pixel. Exactly one candidate is ever
drawn regardless of how priority is computed; there is nowhere in that
mechanism for a second candidate's mark to ever appear. The "Explicitly
Deferred" framing is superseded by this section, not by a parameter — this
is now the active thread.

### Concept

Two combined mechanisms, both traced to GPU Gems Ch. 20 ("Texture
Bombing"), decided together per Matt's explicit direction (2026-07-04) to
build the full mechanism rather than compositing-only as an intermediate
step:

1. **K samples per cell ("bombing")** — each of the 9 existing grid cells
   gets `K=2` jittered candidates instead of 1 (18 total), decorrelated via
   a distinct hash salt per sample index. Cell scale is compensated by
   `sqrt(K)` to hold average density constant as bombing increases — GPU
   Gems' own remedy for grid-scale regularity, generalized here to a
   continuous live dial (see `bomb` param below) rather than a hard integer
   switch, consistent with how `field_priority`/`density_scale` already
   work in this module.
2. **Top-N compositing (`N=2`)** — the selection reduction retains the top
   2 candidates by priority (not just 1), via an insertion-into-ranked-list
   extension of the existing `step`/`mix` reduction idiom (compare each new
   candidate to current best; whichever loses that comparison — new
   candidate or old best — then competes against current second). Each
   retained candidate gets the *entire* downstream per-winner block
   (orientation projection, mod-tex sample, gate, shape sample) run
   independently, then composited rank-1-over-rank-2 using rank-1's own
   alpha (Evolution 1.5) as the blend factor.

`K` and `N` are both fixed at build time, not live params — same precedent
as `f_sirds`' `num_strips` being baked to 12. `bomb` (0–1, live) fades the
second sample-per-cell's contribution in; at `bomb=0` it's forced to a
sentinel priority value that can never win, collapsing to pre-bombing
behavior exactly (same "0 = identical to shipped" idiom as `field_priority`).

### New parameter — `bomb`

| Param  | Type  | Range | Default | Description |
|--------|-------|-------|---------|--------------|
| `bomb` | float | 0–1   | 0.0     | **Behaves as an effective on/off toggle, not a continuous blend** (confirmed empirically, session 2026-07-04 — see plan.md's addendum to ADR 7/8). At 0, behavior is identical to Evolution 1 (single sample per cell, K=1). At 1, both samples per cell compete on equal footing in the priority reduction. Density-scale compensation (`sqrt(2)`) was tried and removed — see below. |

**Note on graded blending:** an earlier version of this mechanism attempted a
smooth `mix(sentinel, real_priority, active_blend)` fade. This doesn't work
as a continuous control: real priority magnitudes scale with `density`/
`jitter`/`field_gain`/`field_priority`, so no single fixed `sentinel`
constant stays correctly scaled across settings — it either fails to
guarantee "always loses" at low `active_blend`, or produces a near-hard
switch near `active_blend=1` regardless of the exact constant chosen
(confirmed with `sentinel=1000` and `sentinel=5`, both produced the same
switch-like transition). Matt's call: treat it as a toggle rather than
add the complexity of dynamically rescaling `sentinel` to the current
priority range. The `mix()`-based implementation is left as-is since it
already behaves correctly at both endpoints — this is a documentation
correction, not a code change.

**Note on density compensation:** the original design compensated cell
scale by `sqrt(2)` as `bomb` rose, to hold total point count constant.
Removed after empirical testing showed it made `bomb` read as a zoom/
density control rather than a clustering control — cell pitch and jitter
magnitude rescaled together as bomb swept, mechanically identical to the
`density` param itself. Accepted trade-off: point count now genuinely
rises with `bomb` (reintroduces the density/irregularity coupling
question already open in `ideas/seed_distribution_beyond_grid.md`), in
exchange for `bomb` actually meaning "more items" instead of "same items,
zoomed."

### Signal Flow — revised, multi-stage (see plan.md ADR 8 for why)

A single-codebox implementation of Evolution 2 hit a hard compile-time
ceiling (Lua pattern-matching capture-group limit in Max's GL2→GL3 shader
transformer) — confirmed via console error, not assumed. The mechanism
above is unchanged; only its implementation shape changes, from one
`jit.gl.pix` to four chained stages:

```
Stage 1 — Search + Select (vfseeds_search_pix)
  in: vecfield
  out: rank1_coord (best_gx, best_gy, best_dx, best_dy)
       rank2_coord (second_gx, second_gy, second_dx, second_dy)
  — 9-candidate (Evolution 1) or 18-candidate (Evolution 2 bombing) priority
    search + top-2 insertion. No shape/mod-tex sampling here.

Stage 2 — Render (vfseeds_render_pix), instance A
  in: shape tex, vecfield, mod tex, rank1_coord
  out: mark_r1 (mark_r, mark_g, mark_b, mark_a)
  — full per-candidate downstream block: orientation, mod-tex sample, gate,
    shape sample, luma alpha (Evolution 1.5). Re-samples vecfield at its own
    rank's gx/gy rather than carrying vx/vy through Stage 1, to keep Stage 1
    at 2 outlets instead of 3.

Stage 3 — Render (vfseeds_render_pix), instance B
  Same codebox as Stage 2, wired to rank2_coord instead of rank1_coord.
  Deliberately the same .gen file reused twice, not a second codebox, to
  stay DRY.

Stage 4 — Composite (vfseeds_composite_pix)
  in: mark_r1, mark_r2, bypass
  out: mark color (final)
  — rank-1-over-rank-2 alpha composite. bypass is applied only here —
    intermediate stages don't need their own bypass gating since their
    output is discarded either way once composited.
```

### Acceptance Criteria

#### Phase 1 — Stage 1 (Search + Select) proven in scratch
- [ ] 9-candidate search + top-2 insertion isolated into its own codebox,
      outputting rank1_coord/rank2_coord as two vec4 textures
- [ ] Verify visually (e.g. temporarily wire coords to color output) that
      rank1 matches Evolution 1's existing single-winner behavior exactly
      at `field_priority=0`
- [ ] Verify rank2 is a sensible "next-best" candidate, not degenerate

#### Phase 2 — Stage 2/3 (Render) proven in scratch
- [ ] Render codebox takes a coord texture + shape/vecfield/mod tex,
      reproduces Evolution 1.5's existing per-winner output exactly when
      fed rank1_coord
- [ ] Same codebox, second instance, fed rank2_coord, produces a sensible
      independent render

#### Phase 3 — Stage 4 (Composite) proven in scratch
- [ ] Rank-1-over-rank-2 composite matches the intended alpha-over formula
- [ ] Regression check: `field_priority=0`, no bombing — visually identical
      to Evolution 1.5's shipped output
- [ ] Overlap check: `field_priority`/`field_gain` cranked — rank2 visibly
      shows through where rank1's own shape doesn't cover, no hard
      rectangles
- [ ] fps measured at target resolution — 4-stage chain, unknown cost,
      not assumed cheap like Evolution 1's scalar-only 9x vecfield sampling

#### Phase 4 — Bombing (`bomb`, K=2) added
- [ ] Second sample per cell added to Stage 1 with distinct hash salt
- [ ] `sqrt(K)` density compensation implemented, live-faded by `bomb`
- [ ] `bomb=0` regression check: identical to Phase 3's non-bombing output
- [ ] fps re-measured at 18-candidate search vs. 9-candidate baseline

#### Phase 5 — Promotion to production
- [ ] Custom builder script (`build_seeds_multistage.py` or similar, per
      `f_sirds` precedent — `tools/build_patcher.py` only supports
      single-codebox modules)
- [ ] `definition.py` updated to document (not necessarily drive) the
      multi-stage architecture
- [ ] JSON validated, opens in Max, all stages wire correctly
- [ ] Regression + overlap checks reconfirmed on the production build
- [ ] Docs (`docs/f_vf_seeds.md`, helpfile) updated; GPU Gems Ch. 20
      attribution extended to cover the bombing mechanism specifically
- [ ] `ideas/seed_distribution_beyond_grid.md` status updated — "Multiple
      samples per cell" item moves from captured-idea to landed
