# Spec: f_poincare

**Date**: 2026-07-09
**Status**: Phase 0 — kaleidoscope proof-of-concept, deliberately narrow scope

---

## What this module does (end target)

Poincaré disk model of hyperbolic {p,q} tiling, rendered as a UV-space
processor — an input texture is repeatedly reflected/inverted through a
generating set of geodesics until the sample point settles into a single
canonical fundamental domain, then the input texture is sampled there.
See `ideas/f_poincare.md` for the full concept, presentation-region ideas,
and relationship to `f_mobius`/`f_droste`/`f_apollonian`.

## What THIS spec covers (deliberately much narrower)

This spec covers only a **dihedral kaleidoscope**: reflection across a
small fixed set of straight lines through the origin, at even angular
spacing. This is not yet a hyperbolic tiling (no curvature, no circular
arcs, no genuine Poincaré disk geometry) — it is the simplest possible
member of the same mathematical family (iterated anti-holomorphic
reflection until settled), chosen specifically as a diagnostic testbed
for the Möbius-composition/parity-tracking machinery currently blocked
on `f_apollonian` (see that module's `plan.md` ADR-8 for the shared
math and the specific mismatch it's trying to root-cause).

**Why start here instead of real {p,q} tiling**: line reflection
(`z -> e^(2i*theta) * conj(z)`) is the simplest possible anti-holomorphic
map -- no division, no correction term, no per-circle center. If the
same composition/parity-tracking approach that's currently failing on
`f_apollonian` also fails here, that confirms the bug is in the shared
core logic, not anything Apollonian- or circle-specific. If it works
cleanly here, the bug is isolated to circle-inversion specifics or the
multi-candidate priority-selection logic -- a much smaller place to look
next.

## User-facing behavior (this phase only)

- A pixel's position is reflected across whichever of N mirror lines
  (through the origin, evenly spaced) it currently lies "outside" of, on
  repeat, until it settles inside the single wedge bounded by two
  adjacent mirrors (the fundamental domain)
- Settled position sampled against a test source texture -- output should
  look like a classic N-fold (or 2N-fold, if mirrors act both ways)
  kaleidoscope: a single wedge of the source image reflected/repeated
  around the full circle with no visible seams or discontinuities
- `mirror_count` param controls N (start fixed, live param is a later
  step, not this phase)

## Acceptance criteria (this phase)

- Visually: a clean, seamless N-fold mirror-symmetric kaleidoscope -- any
  visible seam, discontinuity, or asymmetry is a failure, and unlike
  `f_apollonian` this has **no fractal residual** to explain away -- it
  either tiles perfectly or it's wrong, full stop
- The same accumulated-transform sanity check developed for
  `f_apollonian` (compare matrix-reconstructed settled position against
  the actual fold-loop position) must pass cleanly here before trusting
  the visual result alone -- same "structural verification is necessary
  but not sufficient" lesson this project has hit repeatedly
- No NaN, no console errors, clean compile

## Explicitly out of scope (this phase)

- Real hyperbolic curvature / circular-arc geodesics (this is flat
  Euclidean reflection only)
- {p,q} notation, fundamental-domain polygon shape choices
- Live `mirror_count` param, animation, presentation-region masking
- Any promotion to production `.maxpat` -- this is scratch-only,
  diagnostic-first work

## Relationship back to f_apollonian

If this phase confirms the composition/parity logic is sound, the next
step is reintroducing circle-inversion geodesics (perpendicular-to-
boundary arcs) one at a time against this same known-good scaffold,
which is also the natural path toward real {p,q} tiling -- not a detour,
the same work either way. `f_apollonian`'s `plan.md` ADR-8 remains the
source of truth for the shared math derivation; this spec doesn't
re-derive it, only re-tests it in a simpler setting.
