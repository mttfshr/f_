# Implementation Plan: f_dither_grain (name TBD)

> **SUPERSEDED 2026-07-21** — folded into `f_vf_seeds` as "Evolution 3:
> Color-Driving Texture". See `.specify/stable/f_vf_seeds/plan.md`'s ADR 9
> and `.specify/stable/f_vf_seeds/spec.md`'s Evolution 3 section for the
> active plan. Kept below as historical record of the from-scratch
> attempt that preceded the pivot — not actionable, do not resume work
> here.

---

_Date: 2026-07-21_
_Spec: .specify/f_dither_grain/spec.md_

---

## Summary

`f_dither_grain` is a new processor generalizing ordered dithering into
a `f_grain`-family grain field: per-cell thresholding of a hue-derived
scalar against a jittered dither value, selecting between two (or an
ordered sequence of N) arbitrary reference hues rather than blending
smoothly. Built decoupled — hue-boundary driver and vecfield-driven
grain morphology are separate inputs, validated independently across
four scratch-test phases before any coupling is considered. No code
written yet; this plan covers architecture decisions made in discussion,
not yet a build.

---

## Architecture Decisions

### ADR-1: Decoupled hue-boundary driver and vecfield, not a shared source

**Context:** A single field could plausibly drive both the hue-boundary
scalar `t` and the grain's size/shape/orientation — more visually
coherent in principle, but couples two independently-risky mechanisms
together from the start.

**Decision:** Decoupled. Driving texture (hue-boundary `t`) and vecfield
(grain morphology) are separate inputs for this version. Matt's call —
easier on-ramp, each mechanism gets validated in isolation before
deciding whether coupling is worth the added complexity.

**Consequences:** Three-input architecture (driving texture, vecfield,
static hue references) rather than a simpler single-input shape like
`f_grain`. Four independent scratch-test phases instead of one combined
phase. Coupling remains a possible future spec revision, explicitly out
of scope here (see spec.md Out of Scope).

### ADR-2: Reuse `f_grain`'s parameter vocabulary for size/shape/regularity

**Context:** Needed a way to parameterize dither-grain size, shape, and
regularity (regular grid vs. stochastic scatter). Could invent new
terms, or reuse an existing solved vocabulary.

**Decision:** Reuse `f_grain`'s params directly — `density`, `size`,
`size_var`, `shape`, `jitter`, `sv_seed`, `edge_mode`. `jitter`
specifically becomes the regularity dial: `0` = regular grid
(Bayer-like), `1` = hash-displaced (blue-noise-like), continuous
between.

**Consequences:** No new parameter design needed for grain morphology
itself — only the hue-selection logic (bracket/threshold/dither test)
is genuinely new. Diverges from `f_grain` in one respect: grain
*existence* here is always-on/grid-based, not gated by a `luma_gate`-style
threshold — the driving texture decides which hue a grain resolves to,
not whether it appears.

### ADR-3: Hue-wheel-angle ordering, not a fixed authored list

**Context:** With more than two reference hues, the sequence needs an
order to bracket against. Options: authored/typed order (arbitrary), or
derived from each hue's angle on the hue wheel.

**Decision:** Hue-wheel angle, via a general heuristic — decided since
the driving texture is confirmed to actually encode hue (a live color
source, not a synthetic scalar): a circularly-topological driving scalar
should use a palette order derived from that same topology, so
wraparound and nearest-neighbor bracketing fall out for free rather than
needing special-casing.

**Consequences:** Authored hues get sorted by angle before use (Matt
still picks arbitrary hues; sorting only reorders them for bracketing
purposes). Per-cell test gains a bracket-finding step (find the two
sorted reference hues nearest the cell's own hue angle) upstream of the
existing threshold/dither test. Wraparound at the 0/1 seam uses `wrap()`
(GenExpr has no `fract()`), not naive subtraction. An auto-sort-vs.
authored-order toggle is left as a style option, not required for the
first build (see spec.md).

### ADR-4: Low-saturation fallback via `f_hue_processor`'s known-good gate

**Context:** Hue angle is undefined/numerically unstable for near-grey
pixels, which the driving texture will inevitably contain in normal
use.

**Decision:** Reuse `f_hue_processor`'s existing `smoothstep(0.05, 0.15,
S)` low-saturation gate mechanism — below the gate, skip bracket-finding
and the dither test entirely.

**Consequences:** No new saturation-handling design needed — mechanism
already proven working elsewhere in the library. What's still open:
*which* fallback target to use below the gate (a single designated hue,
or a neutral/grey grain) — genuinely empirical, not resolvable by
discussion, so it's a Phase 0 decision gate (`tasks.md` T001) rather
than settled here.

---

## Dependency Blocks

### Block 0: Core boundary-dither mechanism (Phase 0 of spec.md)
**Dependencies:** None — reuses `f_hue_processor`'s saturation-gate
precedent and standard HSV-style hue extraction; no novel technique yet.
**Builds:** Regular grid of cells (no jitter), hue-angle extraction from
an authored test texture, two-hue bracket + threshold/dither test,
low-saturation gate stub.
**Verification:** Per spec.md Phase 0 acceptance criteria — renders
standalone; boundary between two hues visibly reads as dithered/textured,
not a hard edge or smooth gradient; confirmed across more than one
arbitrary hue pair, not just one convenient case.

### Block 1: Regularity — `jitter` (Phase 1 of spec.md)
**Dependencies:** Block 0
**Builds:** Hash-based per-cell positional jitter (reusing `f_stipple`/
`f_grain`'s known-good hash approach — `noise()`/`snoise()` confirmed
dead on this GPU path, not an option).
**Verification:** Per spec.md Phase 1 acceptance criteria — `jitter=0`
exactly reproduces Block 0's regular grid; `jitter=1` produces a
no-visible-grid scatter; intermediate values form a legible continuum.

### Block 2: Vecfield — magnitude → size/density (Phase 2 of spec.md)
**Dependencies:** Block 1
**Builds:** Vecfield inlet, magnitude role only — grain size/density
response to field magnitude.
**Verification:** Per spec.md Phase 2 acceptance criteria — legible,
controllable response across the magnitude range; confirmed with a real
`f_vf_` producer (e.g. `f_vf_vortex`), including that distance-from-site
falloff reads naturally through magnitude alone with no separate
distance input needed.

### Block 3: Vecfield — direction → shape/elongation (Phase 3 of spec.md)
**Dependencies:** Block 2
**Builds:** Direction role — grain shape/elongation axis follows local
vecfield direction. The one genuinely novel mechanism in this module;
no existing consumer orients grain *shape* from a field (only
streak/blur kernel direction).
**Verification:** Per spec.md Phase 3 acceptance criteria — elongation
visibly follows local direction, distinct from a fixed/global
orientation; confirmed with a real `f_vf_` producer with clearly
varying direction across the frame, not a uniform test field.

### Block 4: `definition.py` and build
**Dependencies:** Blocks 0–3 all individually confirmed correct as
standalone scratch-tested mechanisms.
**Builds:** Full `src/f_dither_grain/definition.py` (canonical location
for build-input files; `.specify/` holds planning docs only). Architecture
(single codebox vs. `pix_chain`) not yet decided — depends on whether
Block 3's vecfield-driven shape/orientation math is cheap enough to
compute inline alongside the hue-bracket/dither test, or needs
separating the way `f_vf_optical_flow`'s windowed-sum stage did. This is
a genuine open decision gate (`tasks.md` T022), not assumed here either
way.
**Verification:** JSON validation, then Max load.

### Block 5: Real-consumer wiring and expressive verification
**Dependencies:** Block 4
**Builds:** Nothing new — wiring hue A/B (or an N-hue list) and a real
driving texture/vecfield source into the built module.
**Verification:** Visual judgment of whether the dithered hue-boundary
effect reads as expressively useful, not just numerically/mechanically
correct — same standard applied to `f_vf_optical_flow`'s Phase 3/4, where
"correct" and "reads as intended" turned out to be different questions
worth checking separately.

### Block 6: f_modules registration and docs
**Dependencies:** Block 5 confirmed working
**Builds:** Category entry, `SIZES` dict entry, `.maxhelp` file, README
update. Blocked on the module-name decision gate (`tasks.md` T023) —
`f_dither_grain` is a placeholder throughout this plan and the spec.
**Verification:** Appears correctly in `f_modules` menu; loads cleanly.

---

## Complexity Notes

Complexity here is spread differently than in a typical single-mechanism
module: four separate things need independent validation (hue-boundary
threshold test, regularity, vecfield magnitude, vecfield direction)
before any of them can be assembled, rather than one clear highest-risk
stage. Of the four, **Block 3 (direction → shape/elongation) is the
most likely to need real iteration** — it's the one mechanism with no
existing precedent to lean on (`f_vf_chroma`/`f_vf_prism` establish
direction-driving-an-*axis* as a pattern, but always for a streak/blur
kernel, never for a grain's own shape parameter), so treat it as the
module's equivalent of `f_vf_optical_flow`'s windowed-sum stage — the
place genuinely new ground is being broken, not just an application of
known-good technique.

The single-codebox-vs-`pix_chain` question (Block 4) is deliberately
left undecided rather than guessed at this stage, since — per
`f_vf_optical_flow`'s own experience — that kind of architectural
question is answered more reliably by what the GPU actually does once
real code is running than by estimating complexity in advance.
