# Spec: f_vf_fluid

_Created: 2026-09-23_
_Status: Draft — not yet built_
_Origin: `ideas/ceyron_simulation_scripts_notes.md` (FFT thread, 2026-07-03
→ 2026-09-22). Separable-DFT passes verified on the GPU through the test
bench; spectral diffusion/projection verified in NumPy
(`tests/test_fft_separable.py`). Architecture discussed and decided
2026-09-23._

---

## Clarifications

### Session 2026-09-23

- Q: New module, or an evolution of `f_vf_advect`? → A: **New module.**
  `f_vf_advect` is passive transport (a vecfield arrives fresh every frame;
  only dye accumulates) and has a distinct excitable `decay > 1.0` mode.
  A solver gives the vecfield inlet a different meaning (force, not
  velocity), so it is a different module, not a mode.
- Q: Does the module carry dye? → A: **No.** It is a *velocity solver*: a
  vecfield goes in as a force, an evolving velocity vecfield comes out.
  Dye/texture transport is done by the existing consumers
  (`f_vf_advect`, `f_vf_warp`, `f_vf_streak`, `f_vf_glow`, …) fed from its
  outlet. This makes it the first **self-evolving vecfield producer** and
  gives the whole `f_vf_` family viscous, incompressible flow without
  changing any consumer.
- Q: Which method? → A: **Spectral (FFT) incompressible flow.**
  Semi-Lagrangian self-advection in real space, then forward FFT →
  one elementwise pass (exact viscous diffusion, exact pressure
  projection, linear drag) → inverse FFT. No Jacobi iteration. Measured:
  the separable-DFT round trip is real-time at 128–256² (a pass is 2.96 ms
  at 512², well under 0.5 ms at 256²).
- Q: Is there a cheaper, non-incompressible mode? → A: Yes, for free: a
  `project` amount from 0 to 1 blends unprojected and projected velocity.
  At 0 the flow is viscous-Burgers-like (smoothed shock fronts where flow
  converges — the "rung 2" look from the 2026-09-22 notes); at 1 it is
  divergence-free swirl. One module covers both; no separate rung-2 module.
- Q: Internal resolution? → A: **256² for the first build**, fixed
  (independent of the Vsynth render resolution; the render size is
  user-configurable, the solver's working size is not). 128² is the
  fallback if 256² costs too much in a real patch. Runtime-selectable
  resolution is deferred (see Open experiments).
- Q: Boundaries? → A: **Periodic (torus)** for the first build — flow that
  leaves one edge re-enters the opposite one. Free-slip walls (mirrored 2N
  domain) are possible later at roughly 4× the pixel cost; not in v1.
- Q: Output encoding? → A: Conforms to the `f_vecfield` contract (0–1,
  0.5 = zero). Solver velocity is unbounded, so an output `gain` scales it
  before encoding, with clamping to [0, 1]. No auto-normalization.
- Q: Vorticity confinement, obstacle masks, walls? → A: Deferred. The
  neighbor-sampling failure that sank the confinement fold-in into
  `f_vf_advect` is unresolved; this module's self-advection needs only plain
  `sample()`, which works.

---

## User Stories

### User Story 1 — Evolving vecfield producer (Priority: P1)

A performer patches any existing `f_vf_` producer (e.g. `f_vf_vortex`) into
`f_vf_fluid`, and the outlet becomes a *living* flow field: the force stirs
it, the flow carries itself along, and it keeps moving and slowly decays
after the force stops. Patched into `f_vf_advect`, `f_vf_warp`, `f_vf_glow`
etc. it produces persistent swirling motion the stateless producers cannot.

**Why this priority**: it is the module's entire reason to exist — the first
producer with memory.

**Independent Test**: `f_vf_vortex → f_vf_fluid → f_vf_advect` on a source
texture. Motion continues after the vortex is disabled (via its own
bypass/zero output) and fades over time.

**Acceptance Scenarios**:
1. **Given** no force connected and zero state, **When** the module runs,
   **Then** the outlet is exactly the neutral field (R = G = 0.5, B = 0.5,
   A = 1.0) on every frame.
2. **Given** a force is applied for a few frames then removed, **When** more
   frames run, **Then** the flow persists and decays monotonically in energy
   according to `viscosity` and `drag`.
3. **Given** the outlet feeds `f_vf_warp` / `f_vf_advect`, **When** the flow
   evolves, **Then** consumers decode it with no changes on their side.

---

### User Story 2 — Viscosity from thin to honey (Priority: P1)

One `viscosity` control spans nearly inviscid, turbulent-looking flow to
thick honey-like flow where small-scale structure dies within a frame or two —
stably, at any setting.

**Why this priority**: this is the capability the current `f_vf_advect` can't
offer at all (no velocity state to act on), and the reason for the spectral
method (explicit diffusion goes unstable at high viscosity; this cannot).

**Independent Test**: numerically (bench + NumPy mirror): a single Fourier
mode decays by exactly `exp(-ν·dt·|k|²)` per frame; a high-frequency field at
high viscosity is flat after one step, without oscillation or blow-up.

**Acceptance Scenarios**:
1. **Given** a single-mode velocity field and zero force, **When** one frame
   runs at viscosity ν, **Then** its amplitude scales by `exp(-ν·dt·|k|²)`
   within tolerance.
2. **Given** viscosity at its maximum, **When** the module runs for 10,000
   frames under sustained force, **Then** the output contains no NaN/Inf and
   no growth beyond the clamped output range.
3. **Given** viscosity at 0 and `drag` at 0, **When** no force is applied,
   **Then** total energy does not increase between frames beyond numerical
   tolerance.

---

### User Story 3 — Incompressibility control (Priority: P1)

A `project` control moves the flow between compressible, shock-forming
character (0) and divergence-free swirling character (1).

**Why this priority**: the two looks are genuinely different and both are
wanted; projection is the other capability the current advect can't provide.

**Independent Test**: at `project = 1`, the spectral divergence of the output
velocity is at numerical zero for arbitrary input; at `project = 0` a
converging force produces nonzero divergence.

**Acceptance Scenarios**:
1. **Given** an arbitrary random force field, **When** `project = 1`,
   **Then** the divergence of the resulting velocity is below tolerance
   relative to its magnitude.
2. **Given** a pure-gradient force, **When** `project = 1`, **Then** the
   resulting velocity is (near) zero; a pure-curl force is left unchanged.
3. **Given** `project` between 0 and 1, **When** the module runs, **Then**
   the result is the linear blend of the unprojected and projected results.

---

### User Story 4 — Stirring from motion (Priority: P2)

Patching `f_vf_optical_flow` (or `f_vf_repulse`, `f_vf_flow`, `f_vf_fieldmap`)
into the force inlet makes the fluid respond to video motion, an obstacle
pattern, a steady wind or a luma landscape.

**Why this priority**: the expressive payoff, but it depends on US1–US3 and
is a tier-3 (judgement) test.

**Independent Test**: a scratch Vsynth patch with each producer in turn;
each visibly drives the flow, none produces artifacts at the frame edge or
when disconnected.

**Acceptance Scenarios**:
1. **Given** `f_vf_optical_flow` on a moving video, **When** it drives the
   force, **Then** the fluid visibly swirls along the motion.
2. **Given** a uniform steady force (`f_vf_flow`), **When** `drag` is above
   zero, **Then** the flow settles to a bounded speed rather than accelerating
   without limit.
3. **Given** the force inlet is connected and then disconnected mid-run,
   **When** the next frames run, **Then** no offset artifact appears (the
   disconnected inlet contributes zero force, not a corner-directed one) and
   the flow decays freely.

---

### User Story 5 — Standard f_ module behavior (Priority: P2)

The module behaves like every other `f_` bpatcher: bypass toggle, autopattr
state, `moduleSize` UI, canonical parameter names, and multiple independent
instances in one patch.

**Why this priority**: required for it to be usable, not the point of it.

**Independent Test**: the module contract bench (`tests/bench_modules.py`)
and offline contract test pass with no XFAIL entries added; two instances
placed in one Vsynth patch run independently.

**Acceptance Scenarios**:
1. **Given** bypass is on, **When** frames run, **Then** the outlet passes
   the incoming force field through unmodified (bench: out1 equals in1) and
   the solver state is not reset.
2. **Given** two `f_vf_fluid` instances in one patch, **When** both run,
   **Then** neither errors ("name already in use") and their states are
   independent.
3. **Given** the patcher is saved and reopened, **When** it loads, **Then**
   parameters restore and the solver starts from zero state without NaNs.

---

## Requirements

### Functional Requirements

- **FR-001**: The outlet MUST be an `f_vecfield`-conformant `float32`
  texture: RG = XY encoded as `v * 0.5 + 0.5`, B = 0.5, A = 1.0.
- **FR-002**: The primary inlet MUST accept an `f_vecfield` and interpret it
  as a **force** (decoded `(p - 0.5) * 2`, scaled by a `force` amount),
  added to the velocity state each frame. An unconnected inlet MUST
  contribute exactly zero force (same suppression pattern as
  `src_vecfield` in `f_vf_warp`/`f_vf_advect`).
- **FR-003**: The module MUST hold a persistent velocity state across frames
  in a one-frame feedback loop (established `f_vf_advect` Pattern 1) at an
  internal, fixed resolution of 256×256, `float32`.
- **FR-004**: Each frame MUST self-advect the velocity (semi-Lagrangian,
  backward trace) with a `dt`-style step control, before the spectral pass.
- **FR-005**: Viscosity MUST be applied as the exact spectral decay
  `exp(-ν·dt·|k|²)`, stable for any ν ≥ 0.
- **FR-006**: A `project` control in [0, 1] MUST blend the unprojected and
  Helmholtz-projected velocity; at 1 the projection MUST remove the
  divergent component exactly in Fourier space.
- **FR-007**: A `drag` control MUST apply unconditionally stable linear
  damping (`exp(-μ·dt)`-form) so sustained or uniform force cannot cause
  unbounded growth.
- **FR-008**: The domain MUST be periodic; this MUST be documented in the
  module's reference doc and helpfile.
- **FR-009**: With zero state and zero force the outlet MUST be exactly the
  neutral field.
- **FR-010**: An output `gain` MUST scale velocity before encoding and the
  encoded result MUST be clamped to [0, 1]; no NaN/Inf may ever reach the
  outlet.
- **FR-011**: Bypass MUST pass the incoming force field through unmodified
  on the outlet without resetting the solver state (state keeps evolving,
  as in `f_vf_advect`), and MUST be verified by the module bench's
  `bypass_out1` check.
- **FR-012**: All object names MUST be `#0_`-scoped so multiple instances
  coexist in one Max session.
- **FR-013**: The module MUST follow the standard bpatcher conventions
  (`routepass`, `route`, `autopattr` with `varname`, bypass toggle,
  `moduleSize` chain) and canonical parameter naming (`gain` = unbounded
  intensity, `mix` = 0–100% blend if any).
- **FR-014**: The internal resolution MUST be independent of the Vsynth
  render resolution; consumers sampling the outlet at any render size MUST
  get a smooth field (bilinear).

### Non-Functional Requirements

- **NF-001** *(target, pending measurement)*: the module adds ≤ 3 ms/frame
  at 256² in the bench, and does not drop a typical Vsynth patch below
  real-time on Matt's machine.
- **NF-002**: Precision — `float32` end to end; the transform round trip
  matches `np.fft` within the already-achieved ~1e-5 absolute.
- **NF-003**: Stability — no NaN/Inf after 10,000 frames at the extremes of
  every parameter range under sustained force (bench temporal run).
- **NF-004**: Verification follows the constitution's tiers: NumPy mirror of
  the whole step (math), bench with frame-exact multi-frame feedback runs
  (execution), then a scratch patch for tuning (judgement).

---

## Success Criteria

1. **Viscosity is exact:** single-mode decay per frame matches
   `exp(-ν·dt·|k|²)` within 1% (bench, N = 256).
2. **Projection is exact:** divergence after `project = 1` is at numerical
   zero (relative to |u|) for random and pure-gradient inputs; a pure-curl
   field is unchanged.
3. **Taylor–Green vortex:** a 2D Taylor–Green initial state decays at the
   analytic rate `exp(-2·ν·k²·t)` within 5% over 100 frames (semi-Lagrangian
   advection is dissipative, so this bounds that error).
4. **Frame-exact feedback:** the bench's multi-frame run of the real
   codeboxes matches the NumPy mirror within 1e-4 over 100 frames.
5. **Stable:** no NaN/Inf after 10,000 frames at parameter extremes.
6. **Zero in, zero out:** neutral field exactly, on every frame.
7. **Expressive (tier 3, Matt's judgement):** `f_vf_vortex → f_vf_fluid →
   f_vf_advect` produces persistent swirling flow visibly distinct from
   `f_vf_advect` alone, and `f_vf_optical_flow → f_vf_fluid` stirs the flow
   from video motion.
8. **Cost:** measured and recorded against NF-001; if 256² is too heavy in a
   real patch, the 128² fallback is evaluated before shipping.

---

## Edge Cases

- **Uniform force / mean flow:** the k = 0 mode is untouched by viscosity and
  projection, so a constant force accelerates the whole field without
  bound unless `drag > 0` or the output clamps. Defaults must keep this
  bounded.
- **Nyquist bins:** the wavenumber sign at k = N/2 is ambiguous; its handling
  in the spectral pass must be defined and tested (symmetric or zeroed).
- **Edge wrap vs. consumers:** the velocity is periodic but `f_vf_advect`
  and friends clamp at their own edges; content leaving one side of a
  consumer's image does not re-enter, though the field itself wraps.
- **Force larger than the encoding range:** encoded [0, 1] force fields
  cap at ±1 (decoded); larger effective force comes from the `force` amount,
  not the texture.
- **Force resolution mismatch:** the force is resampled from render
  resolution down to 256²; a noisy source (e.g. optical flow) may alias.
  Sampling filter is a Phase 0 decision.
- **First frame / reopen / bypass toggling:** state starts at zero; toggling
  bypass never resets it; a save/reopen must not produce NaNs.
- **Render resolution changes:** internal state is fixed-size, so a render
  resize must not reset or corrupt it.
- **Two instances / fixed names:** any fixed `@name` would break the second
  instance (`ob3d does not allow multiple bindings`) — `#0_` scoping
  throughout.
- **Disconnect mid-run:** an unconnected force inlet is zero force, not the
  `vs_black` corner-offset artifact.
- **Extreme parameters:** viscosity max, drag max, `project` at 0 and 1,
  `dt` at both ends — all must stay finite.

---

## Open Experiments (Phase 0 — resolve before committing to the plan)

These are known unknowns with a cheap, defined test each; none blocks the
spec.

1. **Reduced `@dim` inside Vsynth.** Bench shows `dim` works on a pix, but
   it is untested in a real bpatcher inside Vsynth's render context: does a
   256² solver pix run there, and does a render-resolution pix downstream
   sample its output correctly? *Highest risk — test first.* (Per plan
   ADR-2 only the solver stages are 256²; the final encode stage runs at
   render resolution, so consumers never see a small texture. Follow-up
   1b: what size is that final stage when the force inlet is unconnected?)
2. **Spectral pass on the GPU.** Write the diffusion + projection + drag
   codebox and verify it on the bench against the existing NumPy
   `pass_spectral` (including Nyquist handling).
3. **Full-step mirror + Taylor–Green.** Extend the NumPy mirror to the whole
   step (self-advect + force → FFT → spectral → IFFT) and use Taylor–Green as
   the end-to-end reference; then run the real codeboxes multi-frame on the
   bench (`run_temporal`).
4. **Force resampling filter** (nearest / bilinear / box) for render-res →
   256² downsampling, judged on a noisy source.
5. **Runtime resolution (optional).** Whether the DFT loop bound can be a
   `Param` on `jit.gl.pix` (compiles and runs), which would allow selectable
   resolution without a `gen` swap. If not, resolution stays a build-time
   constant.
6. **Parameter ranges and defaults** — tier 3 tuning in a scratch patch,
   after 2–3 pass.

---

## Proposed Phasing (details belong in plan.md)

- **Phase 0** — the experiments above: spectral pass on the bench, full-step
  NumPy mirror + Taylor–Green, reduced-`@dim` test in Vsynth.
- **Phase 1** — solver stages on the bench as real codebox files, including
  frame-exact multi-frame feedback.
- **Phase 2** — build the bpatcher (multi-stage `pix_chain`; hand-edit
  territory like `f_vf_advect`/`f_vf_optical_flow` — decide regenerability
  in the plan) and pass the module contract bench.
- **Phase 3** — scratch-patch tuning with real producers (tier 3).
- **Phase 4** — reference doc, helpfile, `f_modules` menu placement (∇
  Generators/Processors per the vecfield labeling convention), README row.

---

## Out of Scope (This Version)

- Dye/texture transport inside the module (use `f_vf_advect` and friends).
- Vorticity confinement.
- Obstacle / no-slip masks and free-slip walls (mirrored-domain solve).
- Runtime-selectable resolution (pending Open Experiment 5).
- 3D flow.
- Additional outlets (vorticity, pressure, divergence) — possible later
  debug/derived outputs.
- Auto-gain / energy normalization of the output.
- Audio coupling.
