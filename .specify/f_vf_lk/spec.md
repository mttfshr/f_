# Spec: f_vf_optical_flow

_Created: 2026-07-17_
_Status: Draft — not yet built_
_Origin: `ideas/f_vf_optical_flow.md` — cheap frame-diff + `f_vf_fieldmap`
approximation scratch-tested and ruled out for a specific structural
reason (see idea file's Scratch test result section); real Lucas-Kanade
architecture discussed and decided same session._

---

## Clarifications

### Session 2026-07-17

- Q: Does the cheap frame-diff + `f_vf_fieldmap` chain produce usable
  flow direction? → A: No — ruled out. `f_vf_fieldmap`'s gradient points
  perpendicular-to-contour (dim→bright), correct for a height-field-like
  scalar; an accumulated motion trail's meaningful direction is
  tangent-to-trail (its long axis), a structurally different shape. Not
  a tuning problem — confirmed live in Max, described as "not interesting
  yet."
- Q: What's the real approach then? → A: Lucas-Kanade — genuinely solves
  for per-pixel velocity via a 2×2 linear system built from spatial and
  temporal gradients over a local window, rather than deriving direction
  from a diff blob's shape.
- Q: Window size? → A: 5×5 (25 taps). Chosen as a real working size
  rather than starting minimal; back off to 3×3 only if the GL2→GL3
  capture-group ceiling actually bites (per `jit-gen-codebox` skill's
  documented approach — split the stage further, don't debug the math).
- Q: Handle the aperture problem (flat/textureless regions where the
  2×2 solve is singular or near-singular)? → A: Yes — output a
  confidence signal (the solve's matrix determinant, near-zero exactly
  where the solve is unreliable) as a separate scalar outlet, not
  bundled into the vecfield texture. No existing `f_vf_` consumer reads
  a 3rd channel of a vecfield texture, and adding one would mean every
  consumer needs new handling for one producer's benefit. A separate
  outlet mirrors `f_vf_split`'s existing precedent (extracting scalar
  info out of/alongside a vecfield as its own outlet) and requires zero
  changes to any existing consumer.
- Q: Coarse-to-fine pyramid for large motions? → A: No — single-scale
  only for a first build. Pyramid is a much larger undertaking,
  deliberately deferred rather than silently assumed away. If
  single-scale proves too limited for fast motion once tested, pyramid
  is the documented next step, not a surprise gap.
- Q: Does the `pix_chain` build-system schema support this shape? → A:
  Yes, confirmed by reading `build_pix_chain()` directly (not assumed)
  — `pix_wires` is an unrestricted list of `[src_id, src_out, dst_id,
  dst_in]` tuples, no limit to a single feedback loop or fixed chain
  shape. Unlike `f_focus` (which needed a new `primary_object` schema
  mode because its render object wasn't a `jit.gl.pix` at all), this
  module is built entirely from `jit.gl.pix` codeboxes and fits the
  existing schema with no new capability needed.
- Q: How many pix nodes total? → A: 4, not 5. Since `It = current -
  previous` is computed *inside* Stage A anyway, only one previous-frame
  feedback loop is needed (shared by Stage A), not one per stage —
  Stages B and C are purely forward, no feedback of their own. Total:
  `pass_pix` (previous-frame identity) + Stage A + Stage B + Stage C.

---

## Phase 0 — Stage A scratch test (gradients + temporal diff)

De-risk the most mechanical part before building the genuinely new
windowed-sum machinery. Confirms central-difference reuse and the
previous-frame feedback loop work as expected in this specific
configuration before Phase 1 adds real complexity on top.

**What Stage A computes**, per pixel:
- `Ix`, `Iy` — spatial gradients via central-difference sampling of the
  current frame (known-good idiom, same as `f_vf_fieldmap`).
- `It` — temporal gradient, `current − previous`. Same computation as
  the ruled-out approach's frame-diff codebox, reused here as an
  ingredient rather than the whole story.

**Nodes:** `pass_pix` (identity, holds previous frame) + `stage_a_pix`
(primary for this phase's scratch test), wired in the confirmed
`f_vf_advect` `state`/`pass` feedback shape.

**Open question to resolve during this phase, not before:** whether
`Ix`/`Iy` should be computed from the current frame alone, or from an
average of current+previous (Horn-Schunck-style averaging reduces
noise but is a refinement on core LK, not required for a first
version). Decide empirically once Stage A is actually running and
visible, not by assumption beforehand.

**Acceptance criteria:**
- `Stage A` renders standing alone in a scratch patch, no GL errors.
- `Ix`/`Iy`/`It` each visibly respond to motion in a live or played-back
  source (e.g. wire each individually to a preview to confirm they
  aren't all-zero or garbage).
- Previous-frame feedback loop confirmed working via the same
  draw-order mechanism `f_vf_advect` already relies on.

---

## Phase 1 — Windowed sum (Stage B)

The one genuinely new technique in this module — no existing precedent
in the library for summing multiple per-pixel products across a local
neighborhood. Highest risk phase for the GL2→GL3 capture-group ceiling.

**What Stage B computes**, per pixel, over the 5×5 window centered on
that pixel, using Stage A's `Ix`/`Iy`/`It` output:
- `ΣIx²`
- `ΣIy²`
- `ΣIxIy`
- `ΣIxIt`
- `ΣIyIt`

Five accumulator values per pixel, output as an intermediate texture
(likely needs more than 4 channels worth of information across possibly
more than one output texture — concrete channel packing not yet
decided, see Open questions).

**Acceptance criteria:**
- Stage B compiles and renders without hitting the capture-group
  ceiling at 5×5. If it does hit the ceiling: split into smaller
  sub-stages per the `jit-gen-codebox` skill's documented approach,
  don't attempt to hand-optimize the math first.
- Spot-check the five sums against a manually-computed expectation on a
  simple test pattern (e.g. a hard vertical edge moving horizontally
  should produce a predictable, checkable `Ix`-dominated signature).

---

## Phase 2 — Solve + confidence output (Stage C)

**What Stage C computes**, per pixel, from Stage B's five sums:
- Closed-form 2×2 linear solve (Cramer's rule) for `(u, v)` — the
  per-pixel velocity, output as the module's vecfield.
- Matrix determinant of the 2×2 system, output as a separate scalar
  confidence outlet — near-zero exactly where the solve is unreliable
  (flat/textureless regions, the aperture problem).

**Acceptance criteria:**
- `(u, v)` output loads into `f_vf_fieldmap`'s expected vecfield format
  with no adapter needed (standard `f_vf_` x/y-as-RG convention).
- Confidence outlet is visibly near-zero in flat/textureless test
  regions and visibly higher wherever real edges/texture exist to solve
  against.
- Determinant-based confidence doesn't need to be normalized/clamped in
  a way that loses its zero-crossing meaning — verify the raw value
  range empirically before deciding on any remapping.

---

## Phase 3 — Real-consumer wiring, tuning, and expressive verification

Only meaningful after Phases 0–2 individually verify correct. This
phase asks the actual question the whole module exists to answer: is
the resulting flow field expressively useful, not just numerically
plausible.

**Acceptance criteria:**
- Wire `(u, v)` into at least one real `f_vf_` consumer (`f_vf_warp` is
  the most legible choice for visually judging whether direction
  tracks real motion, per the same instinct used in the ruled-out
  scratch test).
- Confirm — by looking at it, not by trusting the math — whether the
  result reads as coherent motion-following, the way the ruled-out
  approach explicitly did not.
- If single-scale motion range proves too limited (fast motion breaks
  down, as expected for single-scale LK), document that finding
  concretely rather than silently declaring the module done — pyramid
  upgrade is the known next step if so, not a surprise.

---

## Out of Scope (This Version)

- Coarse-to-fine image pyramid (deferred, not assumed away — see
  Clarifications).
- Horn-Schulck or any non-Lucas-Kanade flow algorithm.
- Any bundling of confidence into the vecfield texture's own channels —
  confidence is a separate outlet by design (see Clarifications).
- Any masking/suppression logic downstream of the confidence outlet —
  this module produces the signal; consuming it to actually suppress
  unreliable flow in a downstream module is a separate concern, not
  part of this spec.
