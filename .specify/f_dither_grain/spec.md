# Spec: f_dither_grain (name TBD)

_Created: 2026-07-21_
_Status: Draft — architecture pivoted 2026-07-21 (see "Architecture
Pivot" below). Not yet scratch-tested in this new form._
_Origin: `ideas/f_dither_grain.md` — conversational architecture
discussion, no code written yet._

---

## Concept

A **color-selection consumer of `f_vf_seeds`**, not a standalone
placement/grain engine. `f_vf_seeds` already solves discrete mark
placement, jitter/regularity, size, field-driven priority, and
multi-owner overlap compositing — all of it built, shipped, and proven
in production. This module's actual job is much smaller than originally
scoped: given a seed's stable identity (position), decide *which of two
(or more) reference hues* that seed renders as, using the same
threshold-vs-scalar mechanism as classic ordered dithering, applied to
hue selection rather than luminance-to-black/white.

Core per-seed mechanism (unchanged from the original design, still
fully proven — see Phase 0 history below):
- `t` — a scalar in `[0,1]` representing a seed's position between two
  neighboring reference hues (see "Hue-boundary model" below)
- `d` — a per-seed dither threshold, derived by hashing the seed's own
  stable identity (its `gx`/`gy` grid coordinate, supplied by
  `f_vf_seeds`, not computed by this module)
- output = `hue_A` if `t < d`, else `hue_B`

For N > 2 hues: reference hues are treated as an ordered sequence (see
below), and each seed brackets to its two nearest neighbors in that
sequence before running the same single-boundary test locally.

---

## Architecture Pivot (2026-07-21)

**What changed and why.** The original design (Phases 0-3 below,
kept for historical record) built its own 3x3 nearest/second-nearest
Voronoi search, its own jitter mechanism, and its own vecfield-driven
size/shape logic from scratch. This repeatedly hit a specific,
recurring failure: any attempt to make grain *size* legible in the
full-color composite either (a) required a flat background (rejected —
Matt's real use case is full-color textures with no "background"
concept), or (b) required revealing a second-nearest neighbor, which
was only ever visible where that neighbor happened to differ in color
from the first — structurally rare with only two reference hues, so
size ended up invisible almost everywhere except right at the hue
seam, confirmed repeatedly via debug-channel isolation across several
failed attempts that session.

Reading `f_vf_seeds`' own spec/plan history directly (not from memory)
surfaced that it hit the **identical** structural problem — Matt's own
words in that file: *"priority-based selection only warps which single
candidate wins... there is nowhere in that mechanism for a second
candidate's mark to ever appear"* — and already built the real fix:
retaining the top-2 candidates by priority and alpha-compositing
rank-1-over-rank-2 using rank-1's own **luma-keyed alpha** (from an
actual shape texture, not a flat color swap) as the blend factor. This
is a materially better solution than anything attempted in this
module's own Phase 2/3 work, already shipped and battle-tested.

**Decision: `f_dither_grain` becomes a consumer, not a reimplementation.**
Rather than duplicate `f_vf_seeds`' search/jitter/priority/overlap
engineering, this module takes `f_vf_seeds`' per-seed identity as an
input and adds only the one thing seeds doesn't do: hue-threshold color
selection. Everything about shape, size, arrangement, and overlap
legibility is inherited, already proven, for free.

**Open question, not yet resolved — real fork in the road:**
`f_vf_seeds`' shipped production module only exposes **rank 1's** seed
coordinate on its public outlet (`out2`, confirmed by direct read of
`src/f_vf_seeds/definition.py`) — rank 2 exists internally
(`codebox_seeds_search.gen`/`codebox_seeds_merge.gen`) but is not a
public outlet. Since full-tile dithering (no gaps, unlike seeds' own
sparse-mark use case) needs both ranks to guarantee no empty cells when
size varies, there are two real options, not yet decided:

1. **Extend `f_vf_seeds` itself** with a new outlet exposing rank 2's
   seed coordinate (structural change to a shipped, stable module —
   real cost, needs its own decision/task, not something to do
   casually).
2. **Duplicate/fork the search+merge stages** (`codebox_seeds_search.gen`
   + `codebox_seeds_merge.gen`) inside `f_dither_grain`'s own build,
   consuming them as a starting template rather than depending on
   `f_vf_seeds` at runtime. More self-contained; less DRY; doesn't touch
   a shipped module.

Not resolved here — flagged as a decision gate in `tasks.md`, to be
revisited once this module reaches its own build-planning stage. Phase
0 below (hue-threshold mechanism itself) doesn't need this resolved
first, since it can be scratch-tested against rank-1-only data before
the multi-owner question matters.

---

## Historical Record — Original From-Scratch Design (Superseded)

Kept for reference; not the active architecture. The hue-boundary
mechanism itself (Clarifications, Hue-boundary model sections below)
remains valid and carries forward unchanged — only the placement/
grain-morphology machinery is superseded.

### Session 2026-07-21 (original session's clarifications)

- Q: Coupled or decoupled — should the same field drive both the
  hue-boundary `t` and the grain morphology (size/shape)? → A: Decoupled.
  Matt's call — easier on-ramp, lets each mechanism be validated in
  isolation before considering whether coupling is worth the added
  complexity. Revisit only after the decoupled version is proven out.
- Q: How should size/shape/regularity of the dither grain be
  parameterized? → A: Reuse `f_grain`'s existing vocabulary rather than
  inventing new terms — `density`, `size`, `size_var`, `shape`, `jitter`,
  `sv_seed`, `edge_mode`. `jitter` specifically becomes the
  **regularity dial**: `0` = grain centers on a regular grid
  (Bayer-like, screen-locked, repeating), `1` = hash-displaced within
  cell (blue-noise-like, no visible grid). One continuous dial spans
  the whole regular↔stochastic continuum rather than two separate code
  paths.
- Q: Is a vecfield a helpful abstraction for driving grain
  size/shape/distance? → A: Yes, via two separable roles mirroring
  existing consumer patterns already in the library:
  1. **Magnitude → size/density** (same role magnitude plays in
     `f_caustic`'s convergence-weighted accumulation). Distance-from-site
     is a special case of this when the vecfield source is
     `f_vf_vortex`-style — no separate distance input needed.
  2. **Direction → shape/elongation axis** (same role direction plays in
     `f_vf_chroma`/`f_vf_prism`'s streak axis). Grains stretch along
     local flow direction. This is the genuinely novel role — no
     existing module orients grain *shape* from a field, only
     streak/blur kernel direction.
- Q: Fixed authored hue order, or hue-wheel-angle-derived order? → A:
  Resolved via a general heuristic (see "Hue-boundary model" below) —
  since the driving texture actually encodes hue (a live color source,
  not a synthetic scalar), order is derived from hue-wheel angle, not
  authored/typed order.
- Q: How does the saturation-undefined edge case (near-grey pixels)
  get handled? → A: Precedent already exists in `f_hue_processor`'s
  `smoothstep(0.05, 0.15, S)` low-saturation gate. Same mechanism
  applies here: below the gate, skip bracket-finding/dither entirely
  and fall back to a single designated hue or a neutral/grey grain.
  Which fallback reads better is not yet decided — empirical, see
  Phase 0 decision gates in `tasks.md`.

---

## Hue-boundary model

**General heuristic (reusable for future similar decisions):** if the
driving scalar has genuine circular topology (hue angle, oscillator
phase, an `atan2` off a vecfield), derive palette order from that same
topology — wraparound falls out for free and "nearest neighbor"
boundaries are the only choice that doesn't produce a seam artifact. If
the driving scalar is arbitrary (luminance, distance, vecfield
magnitude, noise), use a fixed authored order instead — there's no real
angle to derive from, so imposing one is arbitrary rather than
topology-preserving.

**Applied here:** the driving texture is a live hue source, so:

- Authored reference hues (`hue_a`/`hue_b`, or an N-hue list) are
  **sorted by their own hue angle before use**, rather than used in
  authored/typed order. Matt still authors arbitrary hues — sorting only
  reorders them for boundary-adjacency purposes, it doesn't constrain
  which hues can be chosen.
- Per-cell test: compute the cell's own hue angle from the driving
  texture (standard HSV-style extraction) → find which two sorted
  reference hues bracket that angle → compute fractional position `t`
  between just those two → run the threshold-vs-`d` test, local to that
  bracket. Wraparound at the 0/1 seam uses `wrap()` (GenExpr has no
  `fract()`), not naive subtraction — standard trap per the
  `jit-gen-codebox` skill.
- **Style choice, left open, not architectural:** auto-sort by hue
  angle (smooth, perceptually continuous transitions) vs. an option to
  preserve authored order (lets Matt deliberately place
  clashing/complementary hues adjacent for a harsher graphic effect).
  Default to auto-sort for the first build; exposing a toggle is a cheap
  later addition, not required for Phase 0/1.
- **Low-saturation fallback:** below a `f_hue_processor`-style
  saturation gate, skip the hue-angle-based bracket/dither test
  entirely. Fallback target (designated hue vs. neutral/grey) not yet
  decided — decision gate in `tasks.md`.

---

## Historical: Original Decoupled Architecture (Superseded)

Three inputs, from the original from-scratch design — retained for
reference only, not the active plan (see "Current Architecture" below):

1. **Driving texture** — live hue source; feeds per-cell hue-angle
   extraction and bracket/dither test above.
2. **Vecfield inlet** — magnitude → grain size/density, direction →
   grain shape/elongation axis. Fully decoupled from input 1 for this
   version.
3. **Hue reference source** — static color params (`hue_a`/`hue_b`, or
   an ordered N-hue list), not texture-driven. Texture-driven hue
   references are a possible later extension, explicitly out of scope
   for this version (see below).

Grain field parameters (reusing `f_grain`'s vocabulary):
`density`, `size`, `size_var`, `shape`, `jitter`, `sv_seed`, `edge_mode`.

Grain *existence* is always-on/grid-based (closer to `f_grain`'s
always-on grid than to its `luma_gate`-based placement) — what the
driving texture decides is *which hue* each grain resolves to, not
whether a grain appears at all.

---

## Historical Phase 0 — Core boundary-dither mechanism (regular grid, no vecfield)

**Superseded as a from-scratch build, but the mechanism itself is
fully proven and carries forward unchanged into the new architecture**
(see "New Phase 0" below) — this section is kept because the scratch
testing here is what validated the hue-threshold mechanism in the
first place, before the placement machinery around it was replaced.

De-risk the fundamental mechanism — does thresholding a hue-derived `t`
against a per-cell dither value actually read as a textured, halftone-like
boundary between two flat hues — before adding regularity or vecfield
complexity on top.

**What Phase 0 builds:**
- A regular grid of cells (`jitter=0`, no positional randomization yet).
- Per-cell hue-angle extraction from an authored test texture (a real
  hue-wheel gradient image is acceptable and cheaper to set up than a
  live camera feed, while still exercising the real code path — not a
  synthetic non-hue `t` gradient, since the driving texture is decided
  to actually encode hue).
- Two static reference hues (`hue_a`, `hue_b`), each cell resolves to
  whichever side of the boundary its `t` falls on relative to a fixed
  (non-jittered) per-cell threshold.
- Low-saturation gate stubbed in (even if the test texture is fully
  saturated and never exercises it) so the fallback path exists from
  the start, not bolted on later.

**Acceptance criteria:**
- Grid of grains renders standing alone in a scratch patch, no GL
  errors.
- The boundary between `hue_a` and `hue_b` regions visibly reads as a
  dithered/textured transition band, not a hard edge and not a smooth
  gradient.
- Varying `hue_a`/`hue_b` to different arbitrary hue pairs (not just
  complementary or adjacent ones) confirms the mechanism generalizes,
  not just for one convenient pair.

---

## Historical Phase 1 — Regularity (`jitter`) — Superseded

Superseded: regularity/jitter is now `f_vf_seeds`' own `jitter` param
(already shipped, already covers this exact regular↔stochastic
continuum). No new work needed here — kept for reference only.

---

## Historical Phase 2 — Vecfield: magnitude → size/density — Superseded

Superseded: `f_vf_seeds`' own `field_priority`/`field_gain`/`bomb`
mechanism already covers field-driven size/density/overlap behavior,
built and empirically tuned across multiple real vecfield sources
(Flow, Repulse, Vortex) — a materially more mature solution than the
scratch attempt this session made. No new work needed here.

---

## Historical Phase 3 — Vecfield: direction → shape/elongation — Descoped Prior to Pivot

Already descoped as a separate decision *before* this architecture
pivot (see 2026-07-21 session record — Matt's call: the `aniso_dist`
mechanism was mechanically working but didn't read visually as genuine
elongation, and wasn't essential enough to chase further). `f_vf_seeds`'
own `stretch`/`stretch_mod` params cover elongation along field
direction natively, via its shape-tex orientation projection, if this
capability is wanted later — no need to reconstruct it from scratch.

---

## Current Architecture — Consumer of `f_vf_seeds`

Two real inputs, once the rank-2-exposure question (see "Architecture
Pivot" above) is resolved:

1. **Seed identity/geometry from `f_vf_seeds`** — either its shipped
   `out2` (rank 1 only) or an extended/forked source exposing both
   ranks, depending on how the open question above is resolved. Supplies
   `gx`/`gy` (stable per-seed identity, for hashing `d` and sampling the
   driving hue texture) and `dx`/`dy` (pixel's offset from that seed,
   useful if any local falloff/softness beyond seeds' own shape-tex
   gating is wanted — likely unnecessary, since seeds' shape tex already
   handles edge softness).
2. **Driving texture** — live hue source, sampled at each seed's
   `gx`/`gy` (not per-pixel) to determine that seed's position in the
   hue-bracket sequence. Same mechanism as the original design's Phase
   0, just sampled at a seed's stable identity instead of a
   from-scratch Voronoi cell's center.
3. **Hue reference source** — static color params (`hue_a`/`hue_b`, or
   an ordered N-hue list), unchanged from the original design.

No new grain-morphology params of this module's own — `density`,
`jitter`, `size`, `stretch`, `field_priority`, `field_gain`, `bomb` all
come from `f_vf_seeds` directly. This module's own param surface should
be small: just the hue-boundary controls (`hue_a`/`hue_b` or an N-hue
list, and whatever the low-saturation fallback decision produces).

---

## New Phase 0 — Hue-threshold mechanism against `f_vf_seeds` identity

Confirms the already-proven hue-bracket/threshold mechanism (unchanged
math from the historical Phase 0 above) works correctly when `gx`/`gy`
and the per-seed hash come from `f_vf_seeds`' real search output instead
of this module's own from-scratch Voronoi search.

**What this phase builds:**
- A real `f_vf_seeds` instance in the scratch patch, wired to a shape
  tex (any simple shape — a soft circle is fine) and a real vecfield
  source.
- A small consumer codebox taking `f_vf_seeds`' `out2` (seed coord,
  rank 1) and the driving hue texture as inputs.
- Hash `gx`/`gy` for `d`; sample the driving texture at `gx`/`gy` for
  that seed's hue; run the existing bracket/threshold test; output
  `hue_a` or `hue_b`.
- Composite this module's color output using `f_vf_seeds`' own mark
  mask (`out1`) as the alpha/coverage signal, rather than reimplementing
  any shape/softness logic.

**Acceptance criteria:**
- Renders standing alone in a scratch patch, no GL errors.
- Each visible mark/seed resolves to a single, stable hue (`hue_a` or
  `hue_b`) — no per-pixel flicker within one mark's footprint, since the
  hue decision is per-seed, not per-pixel.
- The overall arrangement visibly inherits `f_vf_seeds`' own
  jitter/density/field-priority behavior correctly — changing those
  params on the seeds instance should visibly affect this module's
  output the same way it already affects seeds' own shape-tex marks.
- Confirms whether rank-1-only (no second-rank fallback) already reads
  acceptably for a first pass, or whether the empty-space-between-marks
  problem reappears immediately — this observation should inform, not
  precede, the rank-2 decision gate in `tasks.md`.

---

## Out of Scope (Current Version)

- Resolving the rank-2-exposure question by assumption — genuinely
  undecided, real decision gate in `tasks.md`, not something to guess at
  in code.
- Coupling `t` (hue-boundary driver) and any vecfield-driven property —
  now moot in the new architecture, since seeds already owns the
  vecfield relationship entirely; this module only ever sees seed
  identity, not the vecfield directly.
- Texture-driven hue references (`hue_a`/`hue_b` or the N-hue list
  coming from a live source rather than static color params) — still
  deferred, unchanged from the original design.
- Direction/elongation shape control — descoped prior to the pivot (see
  Historical Phase 3); `f_vf_seeds`' own `stretch` covers this if wanted
  later.
- Any modification to `f_vf_seeds` itself beyond what the rank-2
  decision gate requires — this module should not casually expand
  seeds' own scope beyond that one specific, named need.
