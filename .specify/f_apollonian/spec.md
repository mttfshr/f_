# Feature Specification: f_apollonian

**Created**: 2026-07-07
**Status**: Redirected 2026-07-08 — see Status Addendum below

---

## What "production" means for this spec (2026-07-08)

Everything in this spec — the completed Ford-circles proof-of-concept
*and* the redirected ring + central-circle work in `tasks.md` — remains
**proof-of-concept scope** until three specific items, currently listed
under Explicitly Deferred, are actually built:

1. **Generalized/arbitrary generating circle configurations** — not
   locked to the fixed N=3 ring
2. **Per-region texture sampling** — the per-circle local-frame mechanism,
   not iteration-depth coloring alone
3. **Live max-iteration count as a user param** — not a build-time
   constant

These three, together, are what define the production version of this
module — not a separable "nice to have later" list. A working closed
gasket with a build-time-fixed iteration count and no texture sampling is
still a proof-of-concept, however visually convincing, until these land.
This reframes Phase 4 (`definition.py`/production build) in `plan.md`:
that phase should not be treated as "ship this" until these three are
either built or explicitly re-scoped out with the same deliberateness as
the Ford-circles pivot above.

---

## Status Addendum (2026-07-08): scope redirected after proof-of-concept

The original spec below targeted "the core gasket render mechanism" in
the abstract, and ADR-1 in `plan.md` chose the **Ford circles**
construction (an infinite tangent-circle strip, tiled via modulo-wrap) as
the first, safest thing to build — deliberately deferring the classical
**ring + central-circle** construction (three-plus-one mutually tangent
circles, containment-tested per candidate, packed inside a bounded outer
circle — the actual "closed gasket" most people picture, and the better
structural fit for this project's circular screen target).

That proof-of-concept is now complete and confirmed working (see
`tasks.md` Phase 1–2 — real Ford-circles tangent-circle packing with
correct nested self-similar detail, an animated final inversion swept
clean across a wide range). It proved the GenExpr mechanics work
(fixed-iteration loops, the scale-accumulator pattern, avoiding `break`
entirely) — but it is **not** the closed gasket this spec's Concept
section was actually written to describe. Ford circles is strip-shaped
and infinite in one direction; the classical gasket is bounded and closed.

**This spec's remaining scope is now redirected to the ring + central-
circle construction** — the deferred alternative from ADR-1 — rather than
continuing to build out or productionize the Ford-circles version. The
User Stories below are being revised in place to target that construction
directly. Nothing about the Ford-circles proof-of-concept is discarded —
its confirmed GenExpr patterns (guarded inversion, scale accumulator,
mix()-based animatable blend) carry forward directly into the new
construction's implementation.

---

## Concept

A generator producing a **closed Apollonian gasket** — the classical
three-mutually-tangent-circles-plus-central-circle construction, packed
within a bounded outer circle — as a procedural, animatable pattern.
Colored by iteration depth (no source texture required), in the tradition
of `f_masonry`/`f_chladni`: self-sufficient generator archetype, not a
processor.

Traces to `ideas/f_apollonian.md`, itself derived from three reviewed
Shadertoy reference implementations (2026-07-07) — see that file for full
citation and mechanism notes. The `ebanflo`-derived reference (ring +
central circle, containment-tested per candidate) is now the primary
translation target, superseding the Ford-circles reference used for the
proof-of-concept. Relationship to `f_poincare`, generalized {p,q}
tessellation support, and per-region texture sampling remain deliberately
out of scope here (see Explicitly Deferred below).

---

## Explicitly Deferred (out of scope for this spec)

- **Relationship to `f_poincare`** — whether these end up as one module
  (mode switch) or two siblings sharing a `.genexpr` helper library is
  undecided. Not a blocker for this spec; revisit once this mechanism is
  proven. See `ideas/f_poincare.md`'s cross-reference.
- **Ford-circles strip construction** — proven as a mechanism
  proof-of-concept (see Status Addendum above), but explicitly not the
  target of this spec's remaining work. Could resurface later as a
  separate mode/variant, but isn't planned as one now.
- **Generalized/arbitrary generating circle configurations** — this spec
  targets the classical ring + central-circle construction (fixed N=3
  ring, per the `ebanflo`-derived reference), not a generalized/arbitrary
  configuration. {p,q}-style tessellation groups and non-disk outer
  boundaries (half-plane, etc. — the `ebanflo` reference itself supports
  a half-plane toggle as prior art) are real future directions but not
  this spec.
- **Per-region texture sampling** — coloring is by iteration depth only in
  this spec. The per-circle local-frame mechanism identified in
  `ideas/f_apollonian.md` (normalizing position by the last circle a point
  resolved against) is a later evolution, not built here.
- **Live max-iteration count as a user param** — fixed at build time for
  this spec (matching the `f_sirds`-style "fixed at build time" precedent
  for constants like this). Exposing it live, and deciding what
  non-converged pixels show, is the next evolution (see
  `ideas/f_apollonian.md`'s P2).

---

## User Stories

### User Story 1 — Core closed-gasket mechanism renders correctly (Priority: P1)

A performer opens the module and sees a recognizable closed Apollonian
gasket pattern — circles within circles, self-similar at multiple scales,
packed within a bounded outer circle — matching the character of the
`ebanflo`-derived reference shader (ring + central circle construction).

**Why this priority**: This is the mechanism validation for the
construction this project actually wants (bounded, closed, circular-
screen-native) — not a substitute for the Ford-circles proof-of-concept,
which already confirmed the underlying GenExpr patterns work (see spec's
Status Addendum). What's new and unverified here specifically: per-
candidate containment testing inside the fixed loop (an `if` per circle,
not an unconditional fold), and the genuine escape-time termination
character this construction has that Ford circles didn't (some points
never settle — see Acceptance Scenario 2).

**Independent Test**: Build the ring + central-circle inversion loop
(N=3 ring by default, per the reference) in a scratch patch (per
`vsynth-bpatcher` skill's scratch-patch conventions, `vs_render` present).
Compare visually against the `ebanflo`-derived reference shader's output.
Confirms the loop itself — no production file, no params beyond what's
needed to verify the mechanism.

**Acceptance Scenarios**:
1. **Given** the scratch patch running with default view, **When**
   viewed, **Then** output shows a recognizable closed Apollonian gasket
   pattern (four mutually tangent circles at the base level, nested
   self-similar tangent circles filling every gap, bounded within a
   visible outer circle) — not the infinite strip character of the
   Ford-circles proof-of-concept, and not noise/black/a single uniform
   region
2. **Given** the fixed iteration count is reached without a pixel
   settling into any circle (a genuine possibility here, unlike the
   Ford-circles case — this construction is a real escape-time test, not
   an unconditional fold), **When** viewed, **Then** those pixels do not
   produce NaN/undefined color (some placeholder treatment — flat color
   acceptable for this spec, see Edge Cases)
3. **Given** the loop needs per-candidate containment testing (an `if`
   per circle per iteration, confirmed GPU-safe per `jit-gen-codebox`
   skill) rather than the Ford-circles construction's unconditional fold,
   **When** the codebox compiles, **Then** Max console shows no compile
   errors, and no `break`/early-exit construct is used even though a
   naive translation of the reference shader's inner loop uses one (per
   `plan.md`'s ADR-2, this question was deferred, not resolved, by the
   proof-of-concept — it must be resolved for real here, either by
   confirming `break` is safe or by using the branchless `settled`-flag
   fallback already described in `ideas/f_apollonian.md`)

### User Story 2 — Live-animated final inversion (Priority: P1)

A performer can animate the gasket's apparent region sizes and camera
position in real time via a single additional live-parameterized inversion
step, without the pattern ever breaking (gaps, overlaps, NaNs).

**Why this priority**: This is the specific mechanism identified in
`ideas/f_apollonian.md` as the clean answer to "animate region size/
boundary" — apply one final circle inversion (live center + radius) to the
already-settled fixed-generator result, rather than resizing the generating
circles themselves (which would break tangency). Grouped at P1 alongside
User Story 1 because a static, unanimatable gasket has limited performance
value — this is close to core to the concept, not a nice-to-have layered on
after.

**Independent Test**: Add one live-parameterized inversion (center x/y,
radius) applied to the coordinate after the main gasket loop settles.
Animate center/radius continuously (e.g. via a test LFO) and confirm the
pattern remains a valid, unbroken gasket throughout — no visible seams,
gaps, or overlap artifacts introduced by the animation itself.

**Acceptance Scenarios**:
1. **Given** the final inversion's center and radius held at an identity-
   like default, **When** viewed, **Then** output matches User Story 1's
   unmodified gasket (regression check — the extra step must be provably
   inert at its neutral setting)
2. **Given** the final inversion's center/radius animated continuously,
   **When** viewed, **Then** relative circle sizes visibly change over
   time while the pattern remains structurally valid (no NaNs, no broken
   tangency artifacts)
3. **Given** the final inversion's radius approaches zero or the center
   approaches a point already inverted through during the main loop,
   **When** viewed, **Then** behavior is at minimum non-crashing (exact
   visual character at these extremes is UNVERIFIED — flagged as an edge
   case to observe during scratch testing, not a precondition)

### User Story 3 — Performance at live-performance resolution (Priority: P2)

The gasket renders at a usable frame rate at standard Vsynth live-
performance resolutions, alongside other simultaneously-running `f_`
modules.

**Why this priority**: A correct-but-slow mechanism has limited value in
this project's performance context (per project purpose — live visual
performance). Ranked P2 rather than P1 because correctness must be
established first; a fast, wrong gasket is not useful.

**Independent Test**: Measure fps at the fixed iteration count settled on
in User Story 1, at standard resolution(s) already used for fps checks on
other `f_` modules (per `f_vf_seeds`/`f_vf_vorticity` precedent — 1920×1080
and 3840×2160).

**Acceptance Scenarios**:
1. **Given** the module running standalone at 1920×1080, **When** fps is
   measured, **Then** result is recorded (target: 60fps, per NF-002, but
   the measurement itself — not a specific number — is the acceptance bar
   for this spec; exact iteration-count/performance tradeoff is UNVERIFIED
   going in)
2. **Given** the module running alongside at least one other `f_` module,
   **When** fps is measured, **Then** result is recorded and compared to
   standalone

---

## Requirements

### Functional Requirements

- **FR-001**: Module MUST implement iterated circle inversion against a
  fixed set of generating circles (Ford-circles construction, per
  `ideas/f_apollonian.md`'s reference review) using a `for`/`while` loop
  with a **fixed iteration count** — no reliance on GPU-unverified
  early-exit constructs
- **FR-002**: Module MUST NOT require an input texture — self-sufficient
  generator archetype (matches `f_masonry`/`f_chladni` precedent), coloring
  by iteration depth
- **FR-003**: Module MUST apply exactly one additional, live-parameterized
  circle inversion (center x/y, radius) to the result of the main iteration
  loop, before final coloring
- **FR-004**: The additional inversion (FR-003) MUST be provably inert at
  an identity-like default setting — output must match the unmodified
  gasket from FR-001 at that default (regression requirement, User Story 2
  Acceptance Scenario 1)
- **FR-005**: Module MUST provide a standard `bypass` param per
  `vsynth-bpatcher` skill convention
- **FR-006**: Pixels that do not settle within the fixed iteration count
  MUST NOT produce NaN or undefined color output — some deterministic
  placeholder treatment is required (exact treatment TBD, see Edge Cases;
  "does not crash/does not NaN" is the hard requirement, the specific
  visual choice is not)

### Non-Functional Requirements

- **NF-001**: Module MUST draw to `@drawto vsynth` GL context, per
  `vsynth-bpatcher` skill convention
- **NF-002**: Performance target: 60fps at 1920×1080, alongside at least
  one other simultaneously-running `f_` module (User Story 3) — the
  fixed iteration count chosen in User Story 1 must be checked against
  this target, not assumed compatible with it
- **NF-003**: All params registered in `parameters` block; autopattr
  present for state save, per standard `f_` bpatcher structure
- **NF-004**: Follows `vsynth-bpatcher` skill conventions throughout
  (required objects checklist, UI styling, control message convention)
- **NF-005**: Scratch-test phase (User Stories 1–2) happens in
  `/Users/matt/Vsynth/patterns/`, per `vsynth-bpatcher` skill's scratch-
  patch/production separation — no production `.maxpat` file is written
  until the mechanism is confirmed working in Max, not just JSON-valid

---

## Parameter Contract (this spec's scope only)

| Param | Type | Range | Default | Description |
|---|---|---|---|---|
| `inv_x` | float | TBD — calibrate in scratch testing | identity/inert value | Final inversion center, x |
| `inv_y` | float | TBD — calibrate in scratch testing | identity/inert value | Final inversion center, y |
| `inv_radius` | float | TBD — calibrate in scratch testing | identity/inert value | Final inversion radius |
| `bypass` | float | 0.0 – 1.0 | 0.0 | Standard bypass |

Exact ranges and what constitutes "identity/inert" for `inv_x`/`inv_y`/
`inv_radius` are deferred to scratch testing (User Story 2, Acceptance
Scenario 1 requires this to be nailed down empirically, not assumed).
Max iteration count is a **build-time constant**, not a live param, in this
spec (see Explicitly Deferred) — its value is also TBD, to be settled
during User Story 1/3 scratch testing (correctness vs. fps tradeoff).

---

## Success Criteria

1. A recognizable Apollonian gasket renders in Max, visually matching the
   reference shader's structural character (nested tangent circles,
   self-similarity across scales)
2. The `break`/early-exit GPU-safety question is empirically resolved
   (confirmed safe, or confirmed unsafe with the branchless fallback
   applied) — not left open past this spec's scratch-test phase
3. The final animatable inversion can be swept continuously without ever
   producing a visibly broken (gapped/overlapping/NaN) pattern
4. fps is measured and recorded at 1920×1080 (and ideally 3840×2160) at
   whatever iteration count User Story 1 settles on, alongside at least
   one other `f_` module
5. Non-converged pixels (fractal boundary) have some deterministic,
   non-crashing treatment, even if unrefined

---

## Edge Cases

- **Non-convergent pixels at the fractal boundary**: by construction, some
  pixels will never settle within any finite iteration count (the gasket
  boundary is a genuine fractal residual set — see
  `ideas/f_apollonian.md`). This spec requires only that these pixels
  produce *some* deterministic, non-NaN output (FR-006) — refined
  treatment (iteration-depth coloring, mask output) is explicitly deferred.
- **Final inversion center coinciding with a point on/near a generating
  circle**: UNVERIFIED behavior, flagged in User Story 2 Acceptance
  Scenario 3 — division-by-near-zero risk in the inversion formula
  (`dot(p,p)` in the denominator, per reference shaders) needs a `max(...,
  epsilon)`-style guard, consistent with the `jit-gen-codebox` skill's
  standing `sqrt()`/division-by-zero caution. Confirm empirically during
  scratch testing rather than assuming the guard is sufficient.
- **Fixed iteration count too low**: produces a visually incomplete/coarse
  gasket (large non-converged regions). Too high: fps cost. The specific
  count is a scratch-test tuning question (per `f_vf_seeds`' precedent of
  measuring rather than assuming a count is "obviously fine"), not
  predetermined here.
- **`bypass` engaged**: standard behavior — output should be the
  module's defined bypass state (black or passthrough, per generator
  archetype convention — TBD which, consistent with how `f_masonry`/
  `f_chladni` each handle their own bypass case).

---

## Open Questions (carried from `ideas/f_apollonian.md`)

- Is `break`/early-exit GPU-safe in `jit.gl.pix`'s GenExpr path? Must be
  resolved during this spec's scratch-test phase (User Story 1, Acceptance
  Scenario 3) — not assumed either way going in.
- What's a good default/range for the fixed iteration count, balancing
  visual completeness against fps (NF-002)? Not measured — reference
  shaders range from 8 to 100 depending on desired density, no direct
  read-across to this pipeline's performance target.
- Exact treatment of non-converged pixels — deferred by design (see
  Explicitly Deferred), but the *placeholder* treatment chosen here should
  be noted in `plan.md` so it's not confused with a final decision later.
