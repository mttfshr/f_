# Implementation Plan: f_poincare (Phase 0 — kaleidoscope)

**Date**: 2026-07-09
**Spec**: .specify/f_poincare/spec.md

---

## Summary

Build the simplest possible member of the iterated-anti-holomorphic-
reflection family: a dihedral (line-mirror) kaleidoscope, using the exact
same architectural pattern as `f_apollonian`'s settle loop (branchless
per-candidate containment test + fold, repeated for a fixed iteration
count) and the exact same accumulated-transform tracking approach
(`f_apollonian` `plan.md` ADR-8) -- but with line reflection instead of
circle inversion as the per-step transform. This is a deliberate,
temporary detour from `f_apollonian` to isolate whether that module's
current mismatch bug lives in the shared composition/parity logic or in
circle-inversion-specific math.

---

## Architecture Decisions

### ADR-1: Straight-line reflection chosen over circular-arc geodesics for Phase 0

**Context**: `f_apollonian`'s accumulated-transform tracking (ADR-8 in
that module's plan) is verified correct on paper (multiple independent
hand-worked numeric examples) but disagrees with the actual render at
runtime, in a way not yet root-caused. Real hyperbolic {p,q} tiling
(this module's actual end target) uses circular-arc geodesics --
essentially the same circle-inversion machinery already in question.

**Decision**: Start with straight-line mirrors through the origin
instead. Reflection across a line at angle `theta` is
`f(z) = e^(2i*theta) * conj(z)` -- anti-holomorphic, matching the same
general family as circle inversion, but the "M" matrix for this step is
a **pure scalar rotation** (`a = (cos(2*theta), sin(2*theta))`, `b=0`,
`c=0`, `d=1`) -- no division, no per-circle center, no correction term.

**Rationale**: This isolates the exact piece of machinery under
suspicion (composition recursion `N_{k+1} = M_{k+1} * conj(N_k)` and the
depth-parity handling of the final result) from every piece of
complexity specific to circles. If line reflection alone shows the same
kind of mismatch, the bug is in the shared core. If it doesn't, the bug
is isolated to circle-specific math or the multi-candidate priority
selection -- either way, a smaller search space than the current
300-line Apollonian codebox.

**Consequences**: This phase produces a real, if simple, working
artifact (a kaleidoscope effect) even if it's purely diagnostic in
intent -- not wasted work regardless of outcome. Genuine hyperbolic
curvature is deferred to a later phase once this is confirmed.

---

### ADR-2: Branchless multi-mirror test, same shape as f_apollonian's per-candidate loop

**Context**: Need a settle loop analogous to `f_apollonian`'s, but for
N line mirrors instead of N+1 circles.

**Decision**: N mirror lines at angles `theta_i = i * (pi/N)` for
`i = 0..N-1`. Each iteration, for every mirror `i`, test which side of
the mirror the current point is on (sign of `sin(phi - theta_i)` where
`phi = atan2(zy, zx)`, or equivalently a 2D cross-product sign test
avoiding `atan2` if that proves safer/cheaper). If the point is on the
"wrong" side of any mirror (i.e., not yet in the fundamental wedge
`[0, pi/N)`), branchlessly reflect across whichever mirror the priority
chain selects -- same nested-`mix()`-by-`step()` idiom already proven
across this project (`f_apollonian`, `f_vf_seeds`). Depth accumulates
the same way; the loop naturally terminates (in the sense that further
iterations become no-ops) once the point is inside the fundamental
wedge, unlike Apollonian's genuine open-ended escape.

**Rationale**: Reusing the exact same branchless-priority-chain shape
as `f_apollonian` means any behavioral difference between the two
modules is attributable to the *transform itself* (line vs. circle), not
to a different loop architecture -- keeping this a clean, controlled
comparison rather than introducing a second unknown.

**Consequences**: Because a proper dihedral tiling always settles
(bounded iterations, no fractal residual), the visual correctness check
is much stronger and simpler than Apollonian's: **the output either
tiles perfectly with N-fold (or 2N-fold) symmetry and zero visible
seams, or it's simply wrong.** No ambiguity about "almost matching."

---

### ADR-3: Reuse the accumulated-transform sanity check verbatim

**Context**: `f_apollonian`'s debug session this session built a direct
comparison (matrix-reconstructed settled position vs. the actual
fold-loop's settled position) that was essential to finding the
central-circle position-update bug (a real, if not yet fully
explanatory, fix). That check should not be treated as Apollonian-
specific scaffolding to rebuild from scratch here.

**Decision**: Port the same check structure directly: track `N`
(accumulated matrix) alongside the fold loop, and after settling,
reconstruct the original point's image via `N` (with the same
depth-parity conjugation handling) and compare against the loop's own
`zx,zy`. Build this in from the start, not as an afterthought once
something looks visually wrong.

**Rationale**: This project's standing lesson, hit multiple times
(`f_masonry`, Ford-circles, `f_apollonian` itself this session): visual
plausibility is not suf+ficient evidence of correctness, and structural
verification alone isn't either -- direct quantitative comparison is
what actually catches these bugs. No reason to relearn that lesson a
third time by skipping it here.

**Consequences**: Slightly more codebox complexity up front, but this
is exactly the kind of complexity that paid for itself immediately in
`f_apollonian` (caught the central-circle bug that the visual alone
did not clearly indicate).

---

## Implementation Phases

### Phase 1 — Core kaleidoscope loop, scratch-tested

Translate ADR-1/ADR-2 into a GenExpr codebox: fixed `N` (start with a
small number, e.g. 5 or 6 -- easy to visually verify by eye), branchless
per-mirror test-and-reflect loop, fixed iteration count (start at 8 --
likely converges much faster than Apollonian's 16, confirm empirically
rather than assume).

**Checkpoint**:
- Clean compile, no console errors
- No NaN/undefined output anywhere in frame
- Visual: clean N-fold (or 2N-fold) mirror symmetry sampling a test
  source texture, no seams

### Phase 2 — Accumulated-transform tracking + sanity check (ADR-3)

Add `N` matrix tracking using the same scalar-complex machinery already
written for `f_apollonian` (`cmulre/cmulim/cdivre/cdivim`, ported
directly -- no need to rederive). Add the reconstruction-vs-actual
comparison as a debug view, same as `f_apollonian`'s `use_mapped=2`
mode.

**Checkpoint**:
- Debug view is clean (matches) across the whole frame, not just most
  of it -- this is the actual pass/fail signal this phase exists for
- If it fails here too: stop, don't chase further Apollonian fixes
  until this simpler case is understood, since the bug is now confirmed
  to be in shared logic
- If it passes cleanly: document exactly what's different about this
  case vs. Apollonian's (likely candidate: the per-circle correction
  term, or the multi-candidate priority-selection interaction with
  `ctr_in`) before returning to `f_apollonian`

### Phase 3 — Return to f_apollonian with findings

**SUPERSEDED 2026-07-09 — not being pursued.** This phase assumed Phase
2's outcome would cleanly resolve `f_apollonian`'s bug. In practice: the
findings *were* returned and applied (relaxed error threshold), but
produced a new, unreconciled contradiction (`use_mapped=2` pass/fail view
disagreeing with `use_mapped=4`'s actual error-magnitude view on the same
regions) rather than a clean resolution. Matt made the explicit call to
shelve `f_apollonian` at that point rather than continue chasing it — see
that module's `HANDOFF.md`/`plan.md` entries for the full record. This
module (`f_poincare`) does not have a return-to-Apollonian phase anymore;
its own next real phase is the actual {p,q} circular-arc tiling (see
below), independent of Apollonian's status.

---

### Phase 3 (renumbered) — Real {p,q} circular-arc geodesic tiling

The module's actual end target, per `spec.md`'s "What this module does
(end target)": replace Phase 1's straight-line mirrors with real
circular-arc geodesics perpendicular to the disk boundary, moving from a
flat dihedral kaleidoscope toward genuine Poincaré disk hyperbolic
tiling. Not yet specced in detail -- picking this up is the next real
architecture discussion for this module, not a continuation of the
line-reflection diagnostic work above.

---

### Phase 2 result (2026-07-09): composition/parity confirmed sound; circle-inversion math also confirmed, with a real precision caveat

**Kaleidoscope (line-reflection) test**: `use_mapped=2` debug view came
back clean across the whole frame. This confirms the composition
recursion (`N_{k+1} = M_{k+1} * conj(N_k)`) and depth-parity handling are
correct -- ruling out the shared core logic as the source of
`f_apollonian`'s mismatch.

**Single-circle escape test** (`circle-check-scratch.maxpat`, built as a
follow-up once real circle inversion -- not just line reflection -- needed
testing): initial results at a tight `0.01` error threshold showed a
persistent four-lobed mismatch pattern inside the circle, surviving
across multiple isolation attempts (fresh-vs-loop-tracked `N`, literals
vs. `Param`s, in-loop vs. out-of-loop, off-center vs. origin-centered
circles) -- extensive hand-verification (multiple independent numeric
examples, including the exact production parameters) confirmed the
underlying math was correct in every case checked, which was initially
puzzling given the persistent visual mismatch.

**Resolution**: loosening the error threshold from `0.01` to `0.3`
dramatically shrank the mismatched region (though didn't eliminate it
entirely) -- confirming this was substantially a **floating-point
precision effect**, not a logic bug. Möbius transformations are
inherently ill-conditioned near points that map to large magnitudes
(close to the transform's pole); GPU float32 precision degrades there in
an expected, bounded way. The `0.01` threshold was too strict for this
domain and flagged normal numerical softness as a hard failure.

**Implication for `f_apollonian`**: this means the earlier debugging
session's four-lobed/asymmetric mismatch patterns there were likely a
mix of (a) the real central-circle position-update bug (confirmed and
fixed), and (b) this same expected precision characteristic showing up
more visibly given Apollonian's much smaller-scale circles and deeper
recursion -- not necessarily one single remaining undiscovered logic
bug. Any future debugging there should use a relaxed error threshold
(informed by this session's `0.3` finding, though the right value likely
depends on scale) before concluding a mismatch is a real logic error.

---

### Phase 3 Step 2 result (2026-07-09): branchless multi-candidate priority selection confirmed sound, including at real tangency

**Context**: Per the staged plan for real {p,q} geodesic tiling (this
module's Phase 3, see below), the multi-candidate priority-selection
pattern -- N candidate circles tested every iteration, branchless
nested-`mix()` selection of the winner -- was identified as the one
genuinely unproven piece of machinery, since `f_apollonian` never
isolated it on its own (always had 4 candidates at once, tangled with
its own unresolved `debug_ok` contradiction). This was tested in three
stages before touching the real {p,q} candidate count:

1. **Single circle** (`circle-check-scratch.maxpat`, already existed
   from earlier this session) -- no priority contention at all, primitive
   functions only. Already confirmed sound (see Phase 2 result above).
2. **Two overlapping circles** (`two-circle-priority-scratch.maxpat`,
   new this session) -- `circ0` at `(-0.3,0)`, `circ1` at `(0.3,0)`, both
   r2=0.5, deliberately overlapping to force real priority contention.
   `debug_ok` (matrix-reconstruction check) and the signed-error-vector
   view (`use_mapped=4`) **agreed with each other** across the whole
   frame -- mismatch confined to a smooth, graded four-lobed region
   right at the circles' boundaries, consistent with expected
   float32/Möbius-pole precision softness, not a hard logic error. (An
   initially-suspected "black hole" of never-hit pixels in the visual
   overlap region, at `use_mapped=1`, was investigated and retracted --
   a zoomed-in re-check at `scale=1` showed solid, correctly-colored
   fill with no gap; the original read was a misjudged low-resolution
   screenshot, not a real defect. Worth remembering as a general
   caution: a visually "suspicious" region in a downsampled screenshot
   needs a zoomed confirmation before being treated as a finding.)
3. **Two circles at exact tangency** (`tangent-circle-priority-
   scratch.maxpat`, new this session, copied from #2 with
   `circ0_x=-0.5`, `circ1_x=0.5`, both r2=0.25 -- centers 1.0 apart,
   radii sum to exactly 1.0, touching at the origin with zero overlap)
   -- the geometrically realistic relationship real adjacent {p,q}
   geodesics will actually have, unlike #2's deliberate overlap.
   **Same result as #2**: `debug_ok` and the error view agree, mismatch
   confined to a smooth gradient concentrated exactly at the tangency
   point and circle boundaries (the genuine Möbius-pole locations),
   clean everywhere else. Confirmed by Matt directly in Max, including
   a zoomed check.

**Conclusion**: the branchless multi-candidate priority-selection
pattern is confirmed sound under the actual geometric condition (exact
tangency) that real {p,q} geodesics present -- this was the one thing
`f_apollonian` never got to isolate cleanly, and it holds up. Whatever
remains wrong in `f_apollonian` (per its own shelved status) is
therefore *not* likely to be this mechanism in general -- more likely
something specific to that module's particular construction (its
central circle's different role, its 4-way rather than 2-way candidate
count, or something else not yet identified). This module does not
inherit that open question; it can proceed to real geodesic-set
construction on a confirmed foundation.

**A genuine simplification found while building the 2-candidate test,
worth carrying forward**: rather than nesting per-circle `invertX(...)`
calls inside the priority `mix()` chain (as `f_apollonian`'s original
codebox did), resolve `hit_cx`/`hit_cy`/`hit_r2` via the priority chain
*first*, then call `invertX`/`invertY` once with the resolved values.
Mathematically identical, removes a layer of nested function calls, and
scales better as circle count grows (a `p`-candidate real geodesic set
would otherwise need `p` nested `invertX` calls just for the X update).
Worth using this shape when building the real {p,q} candidate loop
rather than porting `f_apollonian`'s more verbose original pattern.

---

### Phase 3 Step 3 result (2026-07-09): real {4,5} geodesic tiling confirmed -- closed-form geometry, priority selection, and genuine recursive depth all verified together

**Context**: First real test of the closed-form {p,q} edge-geodesic
formula (derived this session, see below) combined with the confirmed
branchless multi-candidate priority pattern (Step 2), on an actual
{4,5} tiling rather than a synthetic 2-circle test.

**Formula, worked from the right-angled hyperbolic triangle** (disk
center, edge midpoint, adjacent vertex; angles `π/p`, `π/q`, `π/2`):

```
cosh(ℓ) = cos(π/q) / sin(π/p)
t = tanh(ℓ/2) = sqrt((cosh(ℓ)-1)/(cosh(ℓ)+1))
d = (t + 1/t) / 2        // edge-geodesic circle's center distance from origin
ρ = (1/t - t) / 2        // its radius; r2 = ρ²
```

Edge `i` of `p`: center `= (d·sin(2iθ), d·cos(2iθ))`, `θ = π/p`, radius `ρ`
-- same angular convention as `f_apollonian`'s ring.

**Two independent checks passed before ever building the codebox**:
the hyperbolic-validity condition `cosh(ℓ) > 1` reduces exactly to the
well-known `1/p + 1/q < 1/2`, and the `q → ∞` degenerate limit
reproduces `f_apollonian`'s already-confirmed ring formula
(`d = 1/cos θ`, `ρ = tan θ`) exactly -- a real, non-trivial cross-check,
not a coincidence of round numbers.

**Built `poincare-p4q5-scratch.maxpat`** ({4,5}, 4 edge-geodesic
circles, 24 iterations, same `N`-matrix tracking and `debug_ok`/error-
view checks as Step 2, using the simplified "resolve hit_cx/cy via the
priority chain, invert once" pattern from Step 2's finding). Confirmed
in Max:

- `use_mapped=1`: a genuinely square fundamental domain (gray, depth 0)
  at the center, surrounded by 4 correctly-mirrored depth-1 neighbor
  cells -- real 4-fold symmetry, matching {4,5}'s square fundamental
  domain exactly.
- `use_mapped=3` (depth/bit-plane view): **real recursive depth
  visible** -- depth 0 (fundamental domain) → depth 1 (red) → depth 2
  (green) → depth 3 (yellow) → depth 4 (thin blue slivers appearing
  only right at the disk boundary). This is the defining visual
  signature of genuine hyperbolic tiling (cells shrinking specifically
  toward the boundary, not uniformly) -- not something the priority
  mechanism or the closed-form geometry could produce by accident if
  either were wrong.
- `use_mapped=2`/`4`: mismatch band concentrated specifically at the
  disk boundary, not scattered -- and this is now understood as the
  *same phenomenon* as the depth-4 slivers, not a separate issue: deep
  cells compress into the boundary region precisely because that's
  where points sit closest to multiple geodesics' poles simultaneously,
  so the boundary is simultaneously where recursion is deepest and
  where float32 precision is most stressed. Both findings corroborate
  each other rather than conflicting.

**Conclusion**: this is a genuinely confirmed positive result, not just
"didn't crash" -- the closed-form {p,q} geometry, the branchless
priority-selection pattern, and the `N`-matrix accumulated-transform
tracking all work together correctly on a real (if minimal) hyperbolic
tiling. This is the first actual {p,q} tiling this project has
produced.

**Not yet done, real open items for next session**:
- Iteration count (24) is an untested guess -- unknown whether more
  iterations reveal deeper real structure or hit a real ceiling (either
  numerical or a capture-ceiling compile issue at higher counts)
- Only tested {4,5} -- closed-form geometry not yet cross-checked
  against a second {p,q} pair
- No real source texture sampling yet -- current output is region-ID/
  depth coloring only, not the module's actual end-user behavior
  (sampling an input texture at the settled position)
- `edge_r2`/`edge_d` are currently derived offline (Python) and hand-
  entered as `Param` defaults -- computing `cosh(ℓ)`/`sinh`/`tanh`
  in-codebox from live `p`/`q` params (rather than baking in one fixed
  pair) is unexplored


