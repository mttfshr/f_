# Spec: f_vf_lbm

_Created: 2026-10-13_
_Status: Draft — not yet built_
_Origin: `ideas/ceyron_simulation_scripts_notes.md` section 2 (2D Lattice
Boltzmann, D2Q9, obstacle bounce-back). Architecture question resolved
by `tests/records/spike_lbm_d2q9_architecture.py` (NumPy, 2026-10-12): fits the
chained-`jit.gl.pix` pattern `f_vf_fluid` already proved out — no
slab/GLSL track needed. Matt: "spec it" (2026-10-13)._

**Working name — not settled.** `f_vf_lbm` names the technique (parallels
`f_vf_fluid`'s generic naming); `f_vf_karman` or `f_vf_obstacle` would
name the visual result instead (parallels `f_chladni`'s naming style).
Flagging rather than deciding, same as `f_tf_tensormap` in
`ideas/f_tensorfield.md`.

---

## Clarifications

### Carried from the spike (`tests/records/spike_lbm_d2q9_architecture.py`)

- **Architecture: fits the chained-pix pattern, no slab/GLSL track.**
  State packs into **3 RGBA `float32` planes** (9 D2Q9 distributions:
  planes 1–2 hold `f0..f7`, plane 3 holds `f8` + unused channels). Two
  solver codeboxes, not a fixed pipeline of many: (1) a **fused**
  macro+equilibrium+collide+bounce-back codebox (local per-cell math,
  reads the 3 state planes + 1 obstacle-mask plane = 4 texel fetches,
  writes 3 planes); (2) a **streaming** codebox (gather — each of the 9
  directions samples the state textures at a fixed per-direction
  neighbor offset, up to 27 fetches across 3 shared textures, writes 3
  planes). Roughly "2 solver codeboxes + 1 encode" against `f_vf_fluid`'s
  7 stages, at **3× the state bandwidth**.
- **Two correctness traps, both silent (no error, just wrong output) —
  MUST be explicit regression tests, not just "written carefully":**
  1. **Streaming direction.** The gather must read from *upstream*:
     `new[x] = old[x - e_i]`, i.e. the array is rolled by **+e_i**,
     which means the shader's SAMPLE COORDINATE is displaced by **−e_i**
     texels (`sample(tex, x − e_i)`; the mirror's `stream` does exactly
     this). Reading at `x + e_i` instead inverts the flow direction —
     invisible under uniform flow, only exposed once an obstacle is
     present.
  2. **Bounce-back must read pre-collision values.** Obstacle bounce-back
     swaps `f_prev[OPP[i]]` (the state *before* this frame's collision
     step), not the post-collision result. Using post-collision values
     feeds equilibrium-of-garbage into obstacle cells and blows up within
     ~40 steps at `omega ≈ 1.97`.
- **Boundary handling differs from `f_vf_fluid`.** `f_vf_fluid` is
  periodic (torus); this module needs **open channel inflow/outflow**
  (Zou/He-style velocity inflow at one edge, zero-gradient copy outflow
  at the opposite edge) — **periodic wrap + an obstacle is measurably
  less stable** than the reference's channel BCs (periodic+obstacle
  holds only to `omega ≈ 1.8`, i.e. lower Reynolds number, vs. the
  reference's `omega ≈ 1.97` at Re 80 with channel BCs). The spike notes
  this is expressible in a codebox via branching on texel coordinate
  (not CPU-style indexed writes), just not yet written.
- **Shedding quality is an honest open risk, not a solved look.** A
  12,000-step run at the spike's reference geometry (300×50) produced a
  weakly oscillating wake (probe std 0.0085 vs. inflow `U0` 0.04) — a
  real but faint disturbance, not a textbook von Kármán vortex street.
  The reference script itself skips its first 5,000 of 15,000 steps
  before visualizing. **This is a tier-3 (judged) risk carried forward
  explicitly, not glossed over**: a performable version may need a
  longer warm-up, finer resolution, or both before the wake reads as a
  genuine vortex street rather than a faint wobble.
- **Not a replacement for `f_vf_repulse`.** `f_vf_repulse` is a cheap
  repulsion-pattern fake (16-sample ring accumulation, luma threshold),
  not a flow solve. This module is a materially heavier, different
  thing — genuine obstacle-aware incompressible-ish flow. Both are
  worth having; this doesn't retire the other.
- **Obstacle as a mask inlet.** The obstacle shape is a texture (the
  mod-texture-inlet idiom already used elsewhere in the library), not a
  hardcoded shape — patchable/animatable like any other mask-driven
  module.
- **Producer, not consumer.** Like `f_vf_fluid`, this is a **vecfield
  producer**: macro velocity `(ux, uy)` extracted from the distributions
  each frame, encoded per the `f_vecfield` contract, feeding any
  existing `f_vf_` consumer.

### Open, not yet decided

- **Naming** (see header).
- **Safe `omega` ceiling for the channel-BC case.** The spike measured
  the periodic+obstacle ceiling (`omega ≲ 1.8`) but only *reasoned about*
  the channel case (expected to tolerate the reference's `omega ≈ 1.97`
  since that's what the reference itself uses) — not yet measured for
  this module's own codebox. Phase 0 task.
- **Bypass behavior.** `f_vf_fluid` passes its force inlet through
  unmodified on bypass; this module has no equivalent "input texture" to
  pass through (its only texture inlet is the obstacle mask, which isn't
  the thing flowing). What bypass means here needs its own decision in
  Phase 1, not an inherited default.
- **Derived outlets.** The spike's packed state technically makes
  pressure/density (`rho`) and vorticity available as by-products of the
  macro stage — `f_vf_fluid` deferred exactly this kind of thing
  ("Additional outlets... possible later debug/derived outputs"). Same
  deferral here; not in v1.

---

## User Stories

### User Story 1 — Obstacle-aware vortex shedding (Priority: P1)

A performer patches a shape into the obstacle mask inlet and a steady
inflow drives flow through the domain; the output vecfield shows a real,
evolving wake behind the obstacle — not the cheap repulsion-ring pattern
`f_vf_repulse` produces, but flow that actually separates and sheds
behind a real shape.

**Why this priority**: this is the module's entire reason to exist — a
genuine flow solve with obstacle awareness, a category `f_` doesn't have
at all today.

**Independent Test**: `vs_sources_main` (or a drawn shape) → obstacle
mask inlet, with a steady inflow; `f_vf_lbm → f_vf_advect` on a dye
source shows visible, evolving wake structure behind the obstacle that a
no-obstacle run doesn't show.

**Acceptance Scenarios**:
1. **Given** no obstacle (empty mask) and steady inflow, **When** the
   module runs, **Then** the output is smooth channel flow with near-zero
   curl everywhere (mirrors the spike's own inflow-curl check).
2. **Given** an obstacle mask and steady inflow, **When** the module runs
   for several thousand frames, **Then** the output shows nonzero,
   bounded curl in the wake region behind the obstacle, measurably
   greater than the inflow-region curl (mirrors the spike's T1 wake
   detection exactly).
3. **Given** the obstacle mask changes shape live, **When** frames
   continue, **Then** no NaN/Inf artifact appears at the transition.

---

### User Story 2 — Numerically stable at performable settings (Priority: P1)

The module stays stable (no NaN, no blow-up) across the inflow-velocity
and relaxation-rate range a performer would actually reach for, honoring
the stability ceiling the architecture spike found.

**Why this priority**: LBM is the most numerically fragile thing being
proposed for this library (3× the state of `f_vf_fluid`, two silent
correctness traps already found) — without a hard stability guarantee
this module is unusable live.

**Independent Test**: bench + NumPy mirror, extended from the spike: a
long run (10,000+ frames) at the channel BC's measured safe `omega`
range stays finite with mass conserved (`sum(f) ≈ 1` everywhere).

**Acceptance Scenarios**:
1. **Given** `omega` at its documented safe maximum, **When** the module
   runs for 10,000+ frames with an obstacle present, **Then** no NaN/Inf
   reaches the outlet and total mass per cell stays within tolerance of
   1.0 throughout.
2. **Given** `omega` requested above the safe ceiling, **When** the
   module runs, **Then** it either clamps internally to the safe range
   (preferred, matching `f_ks`'s `rate`-clamp precedent) or is
   UI-range-limited so the unsafe value is unreachable — decided in
   Phase 1.
3. **Given** the streaming-direction and bounce-back-timing regression
   tests (the spike's two traps), **When** run against the real
   codeboxes, **Then** both pass — these are permanent regression tests,
   not one-time checks.

---

### User Story 3 — Inflow control (Priority: P2)

An inflow-velocity control (the "wind strength" through the channel)
drives how strongly the flow moves and how pronounced the obstacle's
wake becomes — a performable Reynolds-number-like knob.

**Why this priority**: the only other live-feel control besides the
obstacle shape itself; without it the flow runs at one fixed strength.

**Independent Test**: sweep inflow velocity live; wake visibly
strengthens/weakens; no setting destabilizes the solver (bounded by the
same `omega`-derived viscosity relationship the spike used to set up its
reference geometry).

**Acceptance Scenarios**:
1. **Given** inflow at its minimum, **When** frames run, **Then** the
   flow is slow/laminar with little or no wake disturbance.
2. **Given** inflow at its maximum, **When** frames run, **Then** the
   wake is visibly stronger but the solver remains stable (no NaN/Inf).

---

### User Story 4 — Standard f_ module behavior (Priority: P3)

Bypass (behavior TBD, see Clarifications), autopattr, `moduleSize`,
canonical parameter names, multiple independent instances.

**Why this priority**: required for it to be usable, not the point of
the module.

**Independent Test**: module contract bench (`tests/contracts/bench_modules.py`);
two instances in one patch run independently with independent obstacle
masks.

**Acceptance Scenarios**:
1. **Given** two instances in one patch with different obstacle masks,
   **When** both run, **Then** neither errors and their states (and
   wakes) are independent.
2. **Given** the patcher is saved and reopened, **When** it loads,
   **Then** the solver re-initializes to a valid equilibrium (not zero —
   see Edge Cases) with no NaN on the first frame.

---

## Requirements

### Functional Requirements

- **FR-001**: State MUST be the 9 D2Q9 distribution values packed into 3
  RGBA `float32` planes, held in a persistent one-frame feedback loop
  (3-plane ping-pong, the same `jit.gl.pix` `pass`-feedback idiom
  `f_vf_fluid` uses, at 3× its state bandwidth).
- **FR-002**: A fused local codebox MUST compute macro quantities
  (`rho`, `ux`, `uy`), BGK equilibrium, collision, and obstacle
  bounce-back in one pass, reading the 3 state planes plus 1
  obstacle-mask plane.
- **FR-003**: Bounce-back MUST use the previous frame's pre-collision
  values (`f_prev[OPP[i]]`), never the just-collided result. MUST have a
  dedicated regression test (this is the spike's trap #2).
- **FR-004**: Streaming MUST be a separate gather codebox; each of the 9
  directions MUST sample upstream (`new[x] = old[x - e_i]`, i.e. the
  sample coordinate is displaced by `-e_i` texels; the array roll is
  `+e_i`). MUST have a dedicated regression test for stream-direction
  sign (the spike's trap #1).
- **FR-005**: The domain boundary MUST implement open channel
  inflow/outflow (Zou/He-style velocity inflow at one edge, zero-gradient
  copy outflow at the opposite edge) — **NOT** periodic wrap. Edge
  handling MUST be expressed as texel-coordinate branching inside the
  relevant codebox(es), not CPU-style indexed writes. The y edges are
  **periodic** (decided 2026-10-21; the mirror and the reference
  experiment both wrap y). The inflow prescribes `ux = U0` on the
  interior rows FIRST and only then computes the Zou/He density from it.
- **FR-006**: The obstacle MUST be specified via a mask texture inlet
  (mod-texture-inlet idiom), not a hardcoded shape.
- **FR-007**: The BGK relaxation rate (`omega`, or a user-facing
  viscosity-style control derived from it) MUST be clamped internally to
  the empirically safe range for the channel-BC case (measurement is a
  Phase 0 task; the periodic+obstacle ceiling was `omega ≲ 1.8` and is
  the floor of what to expect, not necessarily the channel case's own
  ceiling). Mirror measurement (2026-10-21, 300×50, circle r=6, U0 0.08,
  2500 frames): 1.975 and 1.98 hold, 1.99 goes NaN by frame ~900;
  clamp near 1.97 until the bench says otherwise.
- **FR-008**: The outlet MUST be an `f_vecfield`-conformant encoding of
  the macro velocity (RG = XY, 0.5 = zero), gain-scaled and clamped, with
  no NaN/Inf ever reaching it (mirrors `f_vf_fluid` FR-010). The
  mirror's `np.clip` passes NaN through, so this guarantee needs an
  explicit guard in the encode codebox and its own test; it is not
  modeled yet (found 2026-10-21).
- **FR-009**: With a valid equilibrium initial state (uniform `rho = 1`,
  `u = inflow`) and no obstacle, the outlet MUST show near-zero curl
  everywhere (the "clean channel flow" baseline US1's first scenario
  tests).
- **FR-010**: All object names MUST be `#0_`-scoped so multiple instances
  coexist in one Max session, each with its own obstacle mask and state.
- **FR-011**: The module MUST follow standard bpatcher conventions
  (`routepass`, `route`, `autopattr` with `varname`, bypass toggle,
  `moduleSize` chain) and canonical parameter naming.
- **FR-012**: Internal working resolution MUST be independent of the
  Vsynth render resolution (same freedom `f_vf_fluid` established);
  exact working size (the spike used 300×50) is a Phase 0/Phase 1
  decision balancing shedding quality against cost.

### Non-Functional Requirements

- **NF-001** *(target, pending measurement)*: cost per frame stays within
  real-time budget in a typical Vsynth patch — expected materially
  higher than `f_vf_fluid` given 3× state bandwidth and the extra
  streaming-gather codebox; exact ceiling TBD.
- **NF-002**: Precision — `float32` end to end; mass conservation
  (`sum(f)` per cell) within the spike's own demonstrated tolerance
  (`max|rho - 1| < 1.0` over thousands of steps at the reference
  geometry).
- **NF-003**: Stability — no NaN/Inf after 10,000+ frames at the
  documented safe `omega`/inflow range, with an obstacle present.
- **NF-004**: Verification follows the constitution's tiers: the NumPy
  mirror already exists (the spike itself, including both correctness
  traps as findings); bench with frame-exact multi-frame feedback runs
  next; then scratch-patch tuning (tier 3) for obstacle shapes, inflow
  range, and — critically — whether the shedding actually reads as a
  vortex street at a performable resolution and warm-up time.

---

## Success Criteria

1. **Mass conserved:** `sum(f)` per cell stays within tolerance of 1.0
   over long runs (bench, mirrors the spike's own invariant check).
2. **Streaming direction correct:** dedicated regression test for the
   `+e_i` upstream-gather sign (spike trap #1) passes and stays a
   permanent test, not a one-time check.
3. **Bounce-back timing correct:** dedicated regression test confirming
   pre-collision values are used (spike trap #2) passes and stays
   permanent.
4. **Wake detected:** nonzero, bounded wake curl behind an obstacle,
   measurably greater than near-zero inflow-region curl (mirrors the
   spike's T1 exactly).
5. **Frame-exact feedback:** the bench's multi-frame run of the real
   codeboxes matches the NumPy mirror within the constitution's standard
   tolerance.
6. **Stable:** no NaN/Inf after 10,000+ frames at the documented safe
   parameter range, obstacle present.
7. **Expressive, with the risk named up front (tier 3, Matt's
   judgment):** the wake needs to read as genuine shedding, not a faint
   wobble — the spike's own 300×50/12,000-step run only achieved a weak
   disturbance (probe std 0.0085 vs. inflow 0.04). Success here may
   require a longer warm-up, a different resolution, or accepting a
   subtler "disturbed flow" character rather than a textbook vortex
   street — this is explicitly not pre-judged as solved.

---

## Edge Cases

- **No obstacle (empty mask):** must behave as plain channel flow, no
  bounce-back triggered anywhere, near-zero curl (US1 scenario 1).
- **Obstacle covering the whole domain:** inflow effectively blocked;
  must stay stable/bounded rather than producing runaway pressure-like
  buildup.
- **`omega` near the instability ceiling:** must be internally clamped
  (FR-007) rather than trusting the dial, same posture as `f_ks`'s
  `rate` clamp.
- **Obstacle mask resolution mismatch:** the mask is resampled to the
  solver's internal resolution; filter choice (nearest/bilinear/box) is
  a Phase 0 open question, same class as `f_vf_fluid`'s force-resampling
  item.
- **First frame / reopen:** state MUST seed to a valid equilibrium
  (uniform `rho = 1`, `u = inflow`), never zero distributions — zero
  would violate the `rho > 0` assumption the macro-velocity divide
  depends on (`ux = sum(f_i * e_ix) / rho`).
- **Two instances / fixed names:** `#0_` scoping throughout; independent
  obstacle masks and independent states.
- **Render resolution changes:** internal state is fixed-size; a render
  resize must not reset or corrupt it.
- **Mid-run obstacle-mask changes:** must not introduce a one-frame
  NaN/Inf spike at the transition (cells newly covered or uncovered need
  a defined bounce-back/collision behavior on the transition frame).

---

## Open Experiments (Phase 0 — none yet run on the GPU)

1. **Solver codeboxes on the GPU.** Port the fused
   macro+equilibrium+collide+bounce-back codebox and the streaming-gather
   codebox, and verify both against the spike's NumPy mirror —
   including both correctness-trap regression tests.
2. **Channel inflow/outflow codebox.** Write the Zou/He-style inflow and
   zero-gradient outflow as texel-coordinate branching inside the
   relevant codebox(es); verify against the spike's channel-geometry
   reference run.
3. **Safe `omega` ceiling for the channel-BC case specifically.** The
   spike only measured the periodic+obstacle ceiling (`≲1.8`); the
   channel case is expected (not measured) to tolerate the reference's
   `omega ≈ 1.97` — confirm on the real codeboxes.
4. **Shedding quality at a performable resolution/soak length.** The
   spike's own honesty note: 12,000 steps at 300×50 produced only a weak
   wake. Does a usable resolution and warm-up time (short enough for a
   live patch) produce a satisfying wake, or does this need a
   fundamentally different geometry/approach to look good live? This is
   the real judged risk, not a stability question.
5. **Obstacle-mask resampling filter** — same class of question as
   `f_vf_fluid`'s force-resampling open experiment.
6. **Bypass behavior decision** (see Clarifications) — what "bypass"
   means for a module with no pass-through input texture.
7. **Parameter ranges and defaults** (`omega`/viscosity control, inflow
   velocity) — tier-3 tuning in a scratch patch, after items 1–4 pass.

---

## Proposed Phasing (details belong in plan.md)

- **Phase 0** — the experiments above: both solver codeboxes on the
  bench against the NumPy mirror (with both correctness-trap regression
  tests), channel-BC codebox, safe-`omega` measurement for the channel
  case.
- **Phase 1** — solver stages as real codebox files on the bench
  (frame-exact multi-frame feedback), decide bypass behavior, build the
  bpatcher (multi-stage `pix_chain`, 3-plane ping-pong — hand-edit
  territory like `f_vf_advect`/`f_vf_fluid`), pass the module contract
  bench.
- **Phase 2** — scratch-patch tuning: obstacle shapes, inflow/`omega`
  range, and the shedding-quality judgment call (tier 3) — this is
  where User Story 1's real success/failure gets decided.
- **Phase 3** — reference doc, helpfile, `f_modules` menu placement
  (vecfield Generators/Producers per the existing labeling convention),
  README row, final naming decision.

---

## Out of Scope (This Version)

- Periodic-domain variant (channel BCs only in v1).
- 3D (D3Q19 or similar) — this spec is 2D D2Q9 only, deliberately the
  lighter case GPU Gems 2 Ch. 47's 3D D3Q19 was ruled out for.
- Multiple or moving obstacles beyond a single mask-driven shape.
- Derived outlets (vorticity, pressure/density as separate outputs) —
  possible later, same deferral `f_vf_fluid` made for its own case.
- Reduced-lattice optimization (e.g. D2Q5) for cost reduction.
- Audio coupling.
- Runtime-selectable resolution.
