# Spec: f_ks

_Created: 2026-10-13_
_Status: Draft — not yet built_
_Origin: `ideas/ceyron_simulation_scripts_notes.md` section 3 (Kuramoto-
Sivashinsky). Stability question resolved by `tests/spike_ks_stability.py`
(NumPy, 2026-10-12): real-space finite-difference is dead on arrival
(~2000 substeps/frame); the spectral-linear/explicit-nonlinear shape
`f_vf_fluid` already uses is real-time-stable, one step per frame. Matt:
"spec it" (2026-10-13)._

**Working name — not settled.** `f_ks` (parallels `f_chladni`'s
physics-name convention) is a placeholder; see Clarifications.

---

## Clarifications

### Carried from the spike (`tests/spike_ks_stability.py`)

- **Method: spectral, not real-space FD.** Linear part (`lap + lap^2`)
  integrated exactly per Fourier bin (`rate = K2 - K2^2`, the same
  per-bin-`exp()`-decay shape as `f_vf_fluid`'s `spec` stage); the
  `0.5*|grad u|^2` nonlinearity stays explicit in real space, computed
  after the spectral step on `u_lin`. One FFT + one IFFT per frame, no
  adaptive substepping.
- **Mandatory DC (k=0) zeroing.** The nonlinearity integrates
  domain-negative, so the field mean drifts secularly downward without
  intervention (measured: -0.2 to -15 over 200 steps). The k=0 Fourier
  bin MUST be zeroed every step — this is not a tunable option, it's a
  correctness requirement the spike demonstrated is needed (same class
  of fix as `f_vf_fluid`'s Nyquist handling).
- **Self-sustaining, no forcing.** Unlike Kolmogorov-forced turbulence,
  KS needs zero external input to stay chaotic once seeded from noise —
  this is the property the ideas file says no existing `f_` generator
  has (`f_chladni` is deterministic/non-chaotic; noise generators have
  no memory). Closer in spirit to `f_vf_advect`'s temporal accumulation
  than to any reactive module.
- **u = 0 is a fixed point.** Both the linear and nonlinear terms vanish
  at `u = 0`, so a zero-initialized state sits frozen forever — the
  module MUST seed its state from random noise on load/reset, never
  from zero, or it will silently do nothing. (The inverse of
  `f_vf_fluid`'s "zero in → zero out" neutral-field guarantee: here a
  zero *state* is the degenerate case to avoid, not the desired rest
  state.)
- **Resolution carried from the notebook/spike:** N=256, periodic domain,
  `L=50` (`DX = L/N`). Not yet re-measured for real-time cost on the GPU
  at this or a smaller size (see Open Experiments — same open question
  `f_vf_fluid` had about its own 256²/128² choice).
- **Safe `dt`:** the spike found a stable simple-scheme `dt` ceiling by
  bisection and ran 600-step soaks at half that ceiling, both without
  mean-zeroing (demonstrating the drift) and with it (demonstrating
  bounded, still-evolving behavior). The spike reports the *method*, not
  a fixed numeric `dt`, since the ceiling is a property of the resolution
  and will need re-confirming once the real codebox runs on the GPU
  (Phase 0).

### Open, not yet decided

- **Naming.** `f_ks` is a placeholder (see header). Flagging rather than
  deciding, same as `f_tf_tensormap` was flagged in `ideas/f_tensorfield.md`.
- **Output encoding.** `u`'s dynamic range is bounded but not naturally
  [0,1] (spike's soaks show `max|u|` in the low-to-mid single digits at
  the measured safe `dt`, but this hasn't been tuned for how it should
  map to a displayable field). Hard clamp, soft `tanh`-style compression,
  or auto-ranging are all open — this is tier-3 (Matt's judgement),
  deferred to Phase 2.
- **Forcing inlet.** The ideas file frames KS as needing *no* forcing to
  stay interesting, but doesn't rule out an optional perturbation inlet
  (e.g. nudging the field, or seeding from an image) as a later addition.
  Out of scope v1 (see below) — a pure autonomous generator first.
- **Companion vecfield outlet.** Not proposed by the research notes for
  this module specifically, unlike `f_tensorfield.md`'s multi-outlet
  producer discussion — no second outlet planned. Flag only if a real
  consumer need surfaces later.

---

## User Stories

### User Story 1 — Autonomous organic pattern generator (Priority: P1)

A performer drops `f_ks` into a patch with no inlets connected, and it
produces a continuously evolving, organic, worm-like/fingerprint-like
texture that never needs re-triggering or external driving — visually
and structurally distinct from `f_chladni` (fixed modal pattern) or any
noise-based generator (no memory, no structure).

**Why this priority**: this is the module's whole reason to exist — a
genuinely new category of generator for the library, not a variant of
one that exists.

**Independent Test**: patch `f_ks` alone into `vs_preview`. Over several
minutes, the pattern keeps changing — no freeze, no decay to a static
image, no blow-up to a garbled/clipped mess.

**Acceptance Scenarios**:
1. **Given** a freshly loaded module (randomly seeded state), **When**
   frames run with no inlets connected, **Then** the output keeps
   evolving indefinitely (no two frames identical, no convergence to a
   static image) for at least 10,000 frames.
2. **Given** the module has run for a long time, **When** more frames
   run, **Then** no NaN/Inf ever reaches the outlet and the displayed
   range stays within the module's defined output bounds.
3. **Given** two `f_ks` instances in one patch with independent seeds,
   **When** both run, **Then** they evolve differently from each other
   (confirming state isn't accidentally shared).

---

### User Story 2 — Reseed / reset (Priority: P1)

A performer sends a reset message (or bangs a UI control) to re-randomize
the state and get a fresh, differently-seeded pattern, without reloading
the module or the patch.

**Why this priority**: the module is autonomous once seeded — without a
reset, a performer who wants a different pattern has no way to get one
short of deleting and re-adding the object. This is as load-bearing as
the generator behavior itself.

**Independent Test**: send `reset`/`bang` to the module twice in a row
mid-performance; the resulting evolution differs each time.

**Acceptance Scenarios**:
1. **Given** the module is running, **When** a reset message arrives,
   **Then** the state re-seeds from fresh random noise (not zero — see
   Clarifications) and resumes autonomous evolution.
2. **Given** a reset at an arbitrary point in the module's evolution,
   **When** frames continue, **Then** no NaN/Inf artifact appears at the
   seam.

---

### User Story 3 — Rate control (Priority: P2)

A `rate` dial scales how fast the chaotic evolution proceeds per frame
(a `dt` multiplier), so a performer can slow the pattern toward a
near-still, slowly-morphing texture or speed it toward frantic churn —
without ever destabilizing the solver.

**Why this priority**: the only performable "feel" control this module
has at all; without it the pattern evolves at one fixed, uncontrollable
speed.

**Independent Test**: sweep `rate` from its minimum to maximum live; no
setting produces NaN/Inf or a frozen frame.

**Acceptance Scenarios**:
1. **Given** `rate` at its maximum, **When** frames run for 10,000
   frames, **Then** the output stays finite and within bounds (the
   module MUST internally clamp the effective `dt` to the resolution's
   measured stability ceiling, never trusting `rate` alone to stay
   safe).
2. **Given** `rate` at its minimum (near zero), **When** frames run,
   **Then** the pattern still visibly evolves, just slowly (not frozen).

---

### User Story 4 — Standard f_ module behavior (Priority: P3)

Bypass, autopattr, `moduleSize`, canonical parameter names, multiple
independent instances — the same baseline every other module in the
library provides.

**Why this priority**: required for it to be usable, not the point of
the module.

**Independent Test**: module contract bench (`tests/bench_modules.py`);
two instances in one patch run independently.

**Acceptance Scenarios**:
1. **Given** bypass is on, **When** frames run, **Then** the outlet
   shows the bypass-neutral output (TBD exact value, see Open
   Experiments) without resetting the solver state (state keeps
   evolving underneath, matching `f_vf_fluid`'s precedent).
2. **Given** two instances in one patch, **When** both run, **Then**
   neither errors and their states evolve independently.

---

## Requirements

### Functional Requirements

- **FR-001**: The module MUST be a pure generator — no required inlets.
  An optional forcing/perturbation inlet is explicitly out of scope v1.
- **FR-002**: The module MUST hold a persistent scalar state `u` across
  frames in a one-frame feedback loop (established `f_vf_advect` Pattern
  1), at a fixed internal resolution (N=256 carried from the spike,
  pending Phase 0 cost re-verification; 128² is the fallback, same
  framing as `f_vf_fluid`'s own resolution choice).
- **FR-003**: State MUST be seeded from random noise on load and on
  reset — **never from zero** (u=0 is a stable fixed point; a
  zero-seeded module would sit frozen forever, silently).
- **FR-004**: Each frame MUST integrate the linear part (`lap + lap^2`)
  exactly per Fourier bin (`rate = K2 - K2^2`, one FFT + one IFFT), then
  apply the `0.5*|grad u|^2` nonlinearity explicitly in real space on the
  linear-step result (central-difference gradient) — matching
  `ks_step_spectral_fixed` in the spike exactly.
- **FR-005**: The k=0 (DC) Fourier bin MUST be zeroed every step. This is
  not exposed as a toggle — skipping it produces measured secular mean
  drift (-0.2 to -15 over 200 steps in the spike), not a usable mode.
- **FR-006**: A `rate` control MUST scale the effective per-frame `dt`;
  the module MUST internally clamp the effective `dt` to the resolution's
  measured stable ceiling regardless of the `rate` value requested, so
  no dial setting can destabilize the solver.
- **FR-007**: A reset/reseed trigger (message or UI bang) MUST
  re-randomize the state from fresh noise without reloading the module.
- **FR-008**: The output MUST be mapped to a bounded, displayable
  grayscale range with no NaN/Inf ever reaching the outlet. The exact
  mapping (hard clamp / soft compression / auto-range) is a Phase 2,
  tier-3 decision (see Open Experiments) — but *some* bounded mapping is
  mandatory regardless of which is chosen.
- **FR-009**: All object names MUST be `#0_`-scoped so multiple instances
  coexist in one Max session.
- **FR-010**: The module MUST follow standard bpatcher conventions
  (`routepass`, `route`, `autopattr` with `varname`, bypass toggle,
  `moduleSize` chain) and canonical parameter naming.
- **FR-011**: Internal resolution MUST be independent of the Vsynth
  render resolution; consumers sampling the outlet at any render size
  MUST get a smooth (bilinear) field.

### Non-Functional Requirements

- **NF-001** *(target, pending measurement)*: cost per frame at the
  working resolution stays within real-time budget in a typical Vsynth
  patch on Matt's machine — exact ceiling TBD, same framing as
  `f_vf_fluid`'s NF-001.
- **NF-002**: Precision — `float32` end to end; transform round trip
  matches `np.fft` within the spike's own already-achieved tolerance.
- **NF-003**: Stability — no NaN/Inf after 10,000 frames at any `rate`
  setting, with and without resets interspersed.
- **NF-004**: Verification follows the constitution's tiers: the NumPy
  mirror already exists (the spike itself); bench with frame-exact
  multi-frame feedback runs next; then scratch-patch tuning (tier 3) for
  rate range, reset behavior, and output-mapping feel.

---

## Success Criteria

1. **Linear part is exact:** single-mode evolution matches the analytic
   per-bin rate `K2 - K2^2` within tolerance (bench, mirrors the spike's
   T2 single-mode check).
2. **Self-sustaining:** from a warmed-up random state with zero external
   input, the field keeps evolving (no freeze, no blow-up) over at least
   600 frames with mean-zeroing active — mirrors the spike's T3 exactly.
3. **DC containment holds:** with mean-zeroing active, field mean stays
   bounded over long runs; the spike's own no-fix drift demonstration is
   kept as a regression test (drift reproduces without the fix, stays
   bounded with it).
4. **Frame-exact feedback:** the bench's multi-frame run of the real
   codeboxes matches the NumPy mirror within the constitution's standard
   tolerance over 100+ frames.
5. **Stable:** no NaN/Inf after 10,000 frames at `rate` extremes,
   including across reset events.
6. **Never frozen:** no seed (including immediately after a reset) sits
   at a fixed point — state changes meaningfully between any two
   snapshots 100+ frames apart.
7. **Expressive (tier 3, Matt's judgement):** the pattern is genuinely
   organic/worm-like, visibly distinct from every existing `f_`
   generator, and the `rate` control changes felt speed without
   changing character unpleasantly (e.g. without introducing visible
   stepping or instability artifacts near either extreme).

---

## Edge Cases

- **Zero-seeded state:** must never happen outside of a deliberate test —
  FR-003 exists specifically to prevent this failure mode.
- **Reset storms:** rapid repeated reset messages must not leave the
  solver in a bad state (e.g. reset mid-FFT-stage in a multi-pass chain)
  — needs defining once the real pix-chain stage boundaries are fixed in
  Phase 1.
- **`rate` at extremes:** both the internal `dt` clamp (FR-006) and the
  mean-zeroing (FR-005) must hold at `rate`'s minimum and maximum, not
  just in the middle of its range.
- **Render resolution changes:** internal state is fixed-size, so a
  render resize must not reset or corrupt it (same requirement as
  `f_vf_fluid`'s equivalent edge case).
- **Two instances / fixed names:** `#0_` scoping throughout, same
  precedent as every other multi-instance-capable module.
- **First frame / reopen:** state must seed from noise cleanly (not
  zero) on patch load, with no NaN on the very first frame.

---

## Open Experiments (Phase 0 — none yet run on the GPU)

1. **Spectral step on the GPU.** Write the linear-integration + k=0-zero
   + real-space-nonlinearity codebox and verify it on the bench against
   the spike's NumPy `ks_step_spectral_fixed`, including the DC-zeroing
   behavior.
2. **Resolution cost in real Vsynth context.** Same open question
   `f_vf_fluid` had about its own 256²/128² choice — does a 256² solver
   pix run at acceptable cost inside a real patch; 128² is the fallback.
3. **Full multi-frame mirror + bench match.** Extend the spike's NumPy
   step into a multi-frame run and compare frame-exact against the real
   codeboxes on the bench (`run_temporal`, same pattern `f_vf_fluid`
   used).
4. **Output encoding / mapping.** Hard clamp vs. soft compression vs.
   auto-range — tier-3, judged against how the module actually looks at
   typical `rate` settings once built.
5. **Bypass behavior.** What the bypass-neutral output actually is for a
   pure generator with no meaningful "pass the input through" state
   (unlike `f_vf_fluid`, which has a force inlet to pass through) — needs
   deciding in Phase 1, not inherited wholesale from the fluid precedent.
6. **Parameter ranges and defaults for `rate`** — tier-3 tuning in a
   scratch patch, after items 1–3 pass.

---

## Proposed Phasing (details belong in plan.md)

- **Phase 0** — the experiments above: spectral step on the bench,
  full-step NumPy-to-GPU match, resolution cost check in real Vsynth
  context.
- **Phase 1** — solver stages as real codebox files on the bench
  (frame-exact multi-frame feedback), decide bypass behavior, build the
  bpatcher (multi-stage `pix_chain`, hand-edit territory like
  `f_vf_advect`), pass the module contract bench.
- **Phase 2** — scratch-patch tuning: output-encoding decision, `rate`
  range/defaults, reset-message UI (tier 3).
- **Phase 3** — reference doc, helpfile, `f_modules` menu placement,
  README row, final naming decision.

---

## Out of Scope (This Version)

- Forcing/perturbation inlet (pure autonomous generator in v1).
- Companion vecfield or gradient outlet.
- 3D.
- Audio coupling.
- Runtime-selectable resolution (same deferral as `f_vf_fluid`'s
  equivalent item).
- Non-periodic boundary variants.
