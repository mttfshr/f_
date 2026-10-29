# Spec: f_vf_immiscible

_Created: 2026-10-27_
_Status: Draft — not yet built_
_Origin: `ideas/f_vf_immiscible.md`, which grew out of `ideas/f_vf_emulsion.md`
(2026-09-29). Direction, name and the required second vecfield settled with Matt
2026-10-27. Companion idea: `ideas/f_splat.md` (the drop of ink or oil)._

**Working name, chosen by Matt 2026-10-27.** Confirm at Phase 3 (gate G1).

Everything below marked [inference] is general knowledge of the method or my own
derivation, not checked against the repo or tried. Phase 0 exists to test it.

---

## Clarifications

### Resolved by design discussion (2026-10-27, Claude + Matt)

- **Phenomenon:** an oil-and-water light show: two fluids that do not mix, with
  different characters, viscosity first. Ink dispersing in water is served by
  existing modules (`f_vf_fluid` + `f_vf_advect`) plus `f_splat`; drops on glass
  and pooling water are out of scope here.
- **A separate module, not a fork of `f_vf_fluid`.** `f_vf_fluid` uses all four
  channels of its DFT chain, so the phase field needs its own chain either way.
  Separate costs the same and works with any vecfield producer.
- **Two required upstream velocity vecfields, one per phase,** each normally from
  its own `f_vf_fluid` with its own `viscosity`, `project`, `drag` and `dt`.
  Different viscosity is therefore two Fluids with different dials, not a feature
  of this module. There is **no single-fluid mode.**
- **The phase field φ has a dedicated source inlet,** not derived from any force
  (the argument in `f_vf_emulsion.md`: contrast in the image needs independent
  causes).
- **Drops come from upstream** (`f_grain`, `f_splat`); this module does not
  generate them.
- **Inputs are Fluid's encoded outlets** (render size, gain applied, clamped to ±1
  field units), not its raw solver state. That caps the velocity φ can feel.
- **Tensor inputs are not used.** The module takes vecfields.
- **v1 is one-way:** the blended flow and φ come out, and nothing is fed back into
  the two Fluids. Momentum across the interface is a gated Phase 2.

### Settled model (derived 2026-10-27 from the `f_vf_fluid` and `f_vf_emulsion` docs)

- **What a blend can and cannot do.** If both inputs are divergence-free, the
  plain blend `u = (1−w)·u_A + w·u_B` has divergence `∇w · (u_B − u_A)`, so only
  the component of the difference normal to the interface contributes. Where the
  two normal components agree, the plain blend is already divergence-free (to
  first order). Where they disagree, the jump `n·(u_B − u_A)` is a real
  mass-flux mismatch: **the integral of the divergence across the interface
  equals that jump for any blend rule.** An output-side rule can only spread it
  over a wider band; only changing the flows themselves (Phase 2) removes it. If
  both Fluids get the same stirring force the difference is mostly in magnitude,
  so the jump may be small in practice. Phase 0 measures that.
- **Candidate phase model: Cahn–Hilliard** [inference]. A double-well energy keeps
  φ near its two values, fixes the interface width, makes droplets bead and
  coalesce, and conserves the total amount of each phase. The alternative
  (plain advected φ plus a sharpening term) is the emulsion doc's fallback;
  Phase 0 decides (G7).
- **φ is conserved by the phase step and separates:** the failure mode is not a
  grey emulsion but everything slowly resolving into two large regions. Stirring
  keeps it alive; a coarsening-rate dial sets how fast it resolves.
- **Periodic domain,** as `f_vf_fluid`: a fixed 256² grid, with only the final
  encode following the render size.

### Open, not yet decided (gates)

- **G1 naming.** `f_vf_immiscible` chosen; confirm at Phase 3.
- **G2 blend rule.** Plain `w` blend, or an interface-aware rule (normal component
  replaced by a band-weighted average, which spreads the jump), or a
  viscosity-weighted variant. Decided by the Phase 0 divergence measurement.
- **G3 initial state.** On reset, φ = `fill` plus small deterministic noise. With
  `fill` inside the spinodal range (about ±0.58 for the standard double well
  [inference]) the module shows a texture at once and coarsens; outside it, φ
  needs injection or larger noise. Proposed default `fill` = 0.
- **G4 φ outlet encoding.** Proposed: `w = (φ + 1) / 2` as a grey scalar texture
  (RGB equal, A = 1); neutral (bypass) = mid grey.
- **G5 bypass.** The plan implements neutral outlets (out0 mid grey, out1 the
  neutral vecfield 0.5, 0.5, 0.5, 1), solver running; this is the library rule
  ("each outlet mixes to its own-kind neutral", `.specify/plan.md`, 2026-10-06).
  Passing input A through unmodified, as `f_vf_fluid` does with its force, would
  need A at render size on the encode stage: a fourth input, beyond the bench's
  three. Matt's call.
- **G6 solver size.** 256² proposed; 128² if two Fluids plus this module cost too
  much in a real patch.
- **G7 phase model.** Cahn–Hilliard versus the plain-advection-plus-sharpening
  fallback. Decided by Phase 0 experiment 1.
- **G8 stage 2 delivery.** How a Fluid is nudged toward the blend: through its
  existing force inlet (with `f_vf_mix` additive) or a new native inlet on
  `f_vf_fluid`. Decided after the cross-module cycle test (experiment 6).

---

## User Stories

### User Story 1 — Two flows, one interface (Priority: P1)

A performer patches two `f_vf_fluid` modules, set to clearly different viscosity,
and feeds both the same stirring force. This module's blended outlet drives
`f_vf_advect` (or `f_vf_warp`). On screen there are two regions with visibly
different flow characters, separated by a boundary.

**Why this priority**: it is the module's reason to exist, and it shows whether
the look is worth the cost before anything else is built.

**Independent Test**: two `f_vf_fluid` modules at viscosity 0.05 and 0.6 with the
same force, φ initialised half and half; the blended vecfield equals Fluid A deep
in region A and Fluid B deep in region B.

**Acceptance Scenarios**:
1. **Given** φ = −1 everywhere, **When** running, **Then** out1 equals input A
   (to encoding tolerance).
2. **Given** φ = +1 everywhere, **When** running, **Then** out1 equals input B.
3. **Given** a mixed φ, **When** running, **Then** out1 is a convex combination
   of A and B at every pixel.

### User Story 2 — An interface that stays crisp (Priority: P1)

Under stirring the two phases do not smear into each other: droplets bead up,
coalesce, and the interface keeps a controlled width. `iface` sets the width and
`coarsen` sets how fast the regions merge.

**Why this priority**: "immiscible" is the whole point of the name; without a
crisp interface this is an ordinary mask blend.

**Independent Test** (tier 1, no Max): stir a φ blob and a thin filament with the
`fluid_mirror` velocity for 600 frames and measure peak interface gradient and
droplet count against the plain-advection fallback.

**Acceptance Scenarios**:
1. **Given** no flow and no injection, **When** frames run, **Then** φ approaches
   two values and the mean of φ is unchanged (to float32 summation tolerance).
2. **Given** a flat interface, **When** frames run, **Then** it relaxes to the
   profile its width parameter predicts.
3. **Given** stirring, **When** frames run, **Then** the interface does not
   dissolve into a uniform mid value within the Phase 0 test horizon.

### User Story 3 — Dropping a phase in (Priority: P2)

A texture on the first inlet deposits the second phase where it is bright, at a
rate `inject`; a splat generator or `f_grain` upstream makes oil drops in water.
`reset` and `fill` start from a chosen mixture.

**Independent Test**: a bright disc on in0 with `inject` > 0 raises φ toward +1
inside the disc and nowhere else; with in0 unconnected nothing is deposited.

**Acceptance Scenarios**:
1. **Given** a black in0, **When** running, **Then** no phase is deposited.
2. **Given** `reset` with `fill` 0, **When** running, **Then** φ shows a fine
   random texture that coarsens, and `fill` −1 gives uniform phase A.

### User Story 4 — Blend behaviour at the interface (Priority: P2)

The blended vecfield does not create visible sources or sinks along the interface
beyond what the two flows' own mismatch forces. Which blend rule achieves that is
decided by measurement (G2).

**Independent Test** (tier 1): for a straight interface between two uniform flows,
the divergence integrated across the interface equals the normal jump, for every
rule; the interface-aware rule's peak divergence is no larger than the plain
rule's.

**Acceptance Scenarios**:
1. **Given** uniform flows with agreeing normal components, **When** blended,
   **Then** divergence is zero to rounding.
2. **Given** swapped inputs and `w → 1 − w`, **When** blended, **Then** the output
   is identical.

### User Story 5 — Momentum across the interface (Priority: P3, gated)

Each Fluid feels the other phase: nudged toward the blend in a band across the
interface, with buoyancy and surface tension as optional forces. Needs the
cross-module feedback cycle and a delivery choice (G8); not built until both are
settled.

### User Story 6 — Standard f_ module behaviour (Priority: P3)

Bypass, naming, three inlets, `vs_inState` gating, `#0_` scoping, two instances in
one patch, menu placement and docs follow library conventions.

---

## Requirements

### Functional Requirements

- **FR-001**: Three inlets. In0: control messages plus an optional φ source
  texture (luma, unipolar). In1: velocity vecfield A (phase A). In2: velocity
  vecfield B (phase B). In1 and in2 are required; an unconnected inlet, or a
  texture that is not a vecfield (B ≠ 0.5, such as `vs_black`), MUST read as zero
  velocity, never as `vs_black`'s decoded −1, including during the ~180 ms the
  connected flag lags at load and disconnect (`f_vecfield_type.md` producer note 4).
- **FR-002**: Two outlets in v1. Out0: φ as a scalar texture (G4). Out1: the
  blended velocity as an `f_vecfield` (`float32`, RG = 0.5 + 0.5·v, B = 0.5,
  A = 1). Stage 2 may add outlets (FR-016).
- **FR-003**: φ MUST be a persistent `float32` state at a fixed 256 × 256 on a
  periodic domain, independent of render size. Outlets follow the render size.
- **FR-004**: Blend identities: at φ = −1 out1 equals input A; at φ = +1 it equals
  input B; elsewhere it is a convex combination with a weight that is monotone in
  φ; swapping A and B with φ → −φ gives the same output.
- **FR-005**: The blend rule MUST be one of the options decided at G2; the plain
  `w` blend MUST remain available as the baseline.
- **FR-006**: Each frame φ MUST be advected by the blended velocity (backward
  trace, periodic, displacement = velocity × `dt`, the same meaning as
  `f_vf_advect`'s and `f_vf_fluid`'s `dt`), then phase-separated (model per G7).
- **FR-007**: With no flow and no injection, φ MUST evolve toward two phases with
  an interface of controlled width (`iface`) while the mean of φ is conserved
  (exact for Cahn–Hilliard; if the fallback wins G7, the conservation bound is
  stated from Phase 0).
- **FR-008**: The in0 texture's luma MUST deposit phase B (φ toward +1) at rate
  `inject`; zero luma deposits nothing; an unconnected or non-texture in0 deposits
  nothing.
- **FR-009**: `reset` MUST re-seed φ as `fill` plus small deterministic noise and
  MUST fire once on load. `freeze` MUST stop φ's evolution while the blend keeps
  running on the held φ.
- **FR-010**: No NaN or Inf may enter φ or reach an outlet; φ MUST be bounded
  (clamp plus the non-finite guard). A uniform φ of exactly ±1 is a legitimate
  stable state and MUST NOT be treated as a fault and reseeded.
- **FR-011**: Bypass MUST be a Param gate on the encode stage (never native
  `@bypass`), the solver keeps running, and the outlets follow G5.
- **FR-012**: Control names MUST NOT collide with `jit.gl.pix` attributes or GLSL
  builtins (`texture`, `t`, `depth`, `mix`, `bypass`, `dim` and the other traps in
  `skills/jit-gen-codebox`); checked at definition time.
- **FR-013**: All object names `#0_`-scoped; two instances coexist and are
  independent.
- **FR-014**: Deterministic: identical inputs, parameters and seed give identical
  frames.
- **FR-015**: Out1 carries no gain control; the velocity scale is set by the
  upstream Fluids and applied by consumers (type contract consumer rule 4).
- **FR-016** (Phase 2, gated by G8): outlets that return a nudge and force
  vecfield for each Fluid, in the `f_vecfield` contract, plus buoyancy and
  surface-tension controls.

### Non-Functional Requirements

- **NF-001**: Cost recorded as numbers: this module alone, and the full chain (two
  Fluids plus this module) at 1920 × 1080 and 3840 × 2160 on the M3 Max; the M1
  flagged, not assumed. The bench has a resolution floor (about 0.2 ms); a result
  under it is reported as a bound. Rough budget, unmeasured: about 3 ms for this
  module and about 8 ms for the chain.
- **NF-002**: `float32` end to end; the DFT round trip matches `np.fft` within
  about 1e-5 absolute (as `f_vf_fluid`).
- **NF-003**: Stable: no NaN/Inf after 10,000 frames at the extremes of every
  parameter under strong stirring (bench temporal run).
- **NF-004**: Verification follows the constitution's tiers; the NumPy mirror
  imports `tests/modules/fluid/fluid_mirror.py` for stirring and the periodic
  interpolation.
- **NF-005**: The look does not depend on render size: the interface width is set
  in solver texels on the fixed grid.

---

## Parameters (proposed; the final set is fixed by Phase 0)

| Param | Range | Default | Notes |
|---|---|---|---|
| `dt` | 0–0.05 | 0.01 | advection step; same meaning as Fluid and Advect |
| `iface` | 2–12 texels | 4 | interface width; needs a few texels on the 256² grid |
| `coarsen` | 0–1 dial | 0.3 | per-frame coarsening rate via a law like Fluid's `viscosity` (cubic); decided in Phase 0 |
| `inject` | 0–1 | 0.2 | in0 deposit rate |
| `fill` | −0.6–0.6 | 0 | mean φ at reset (G3) |
| `blend` | menu | Plain | blend rule (G2) |
| `taps` | 1–16 | 2 | input minification filter; control message only; Fluid outlets are smooth so the default is low |
| `reset`, `freeze`, `bypass` | toggles | 0 | |
| Stage 2 (gated): `nudge`, `buoyancy` + direction, `tension` | | | |

---

## Success Criteria

1. **Mean conserved:** with no flow and no injection, the mean of φ changes by no
   more than float32 summation error per frame (target under 1e-6 absolute).
2. **Energy:** with no flow and no injection the free energy does not increase
   from frame to frame beyond tolerance.
3. **Spinodal rate:** a single small-amplitude Fourier mode grows or decays at the
   analytic rate within 2%.
4. **Interface profile:** a flat interface relaxes to the `tanh` profile with the
   width `iface` predicts, within 10%.
5. **Blend identities:** FR-004 holds exactly; the plain blend's divergence equals
   `∇w · d` to 1e-5; the divergence integrated across a straight interface equals
   the normal jump for every rule.
6. **Phase 0 gate (G7):** under 600 frames of `fluid_mirror` stirring, a blob and
   a thin filament keep a defined interface and droplets coalesce; thresholds
   (a proposal is "peak interface gradient at least half its starting value") are
   fixed in the first Phase 0 task, and the numbers and stills recorded.
7. **Cost:** NF-001 recorded and acceptable to Matt.
8. **Tier-3 (Matt, live):** two Fluids at clearly different viscosity with the
   same stirring force, blended and driving `f_vf_advect`, read as two substances
   that do not mix, each with its own character, on either side of a crisp
   interface.
9. **Contracts:** the module contract bench and offline contract test pass with no
   new XFAIL entries; two instances run independently.

---

## Edge Cases

- **A and B identical:** the blend equals either; φ is then invisible in out1 and
  still visible in out0.
- **Strongly disagreeing normal components:** the interface carries a real
  divergence (Settled model); the output shows sources or sinks there until
  stage 2.
- **Inputs of different render size or from different producers** (for example
  `f_vf_lbm` at 192 × 108): each is minified separately into 256²; detail finer
  than the grid is lost; a non-periodic producer shows a seam at the wrap.
- **Uniform φ = ±1** (`fill` ±1, or one phase swallowing the other): a stable
  state, not a fault; out1 then equals one input.
- **`fill` outside the spinodal range:** φ stays near its initial phase until
  injection or noise nucleates the other.
- **Large `inject`:** φ saturates toward +1 where the source is bright; bounded by
  the clamp.
- **`coarsen` 0:** φ is only advected, with no phase separation; the interface
  smears under flow (the fallback's failure mode).
- **Thin features:** a filament narrower than `iface` cannot be represented; it
  either thickens or breaks up. Phase 0 reports which.
- **Frame-size change:** φ is fixed-size and must not be reset or corrupted.
- **First frame, reopen, bypass toggling:** state starts from a valid seed; toggling
  bypass never resets φ; reopen never produces NaN.
- **Latency:** each Fluid has one frame of latency; A and B are equally late, so
  the blend is consistent, but out1 is one frame behind a direct Fluid outlet.
- **Fluid's output clamp:** inputs are clamped to ±1 field units, so the velocity φ
  feels saturates where a Fluid's `gain` is high.

---

## Open Experiments (Phase 0, resolved before the build)

1. **φ under stirring (decides G7).** Advect a Cahn–Hilliard φ with the
   `fluid_mirror` velocity: does the interface stay sharp, do droplets coalesce,
   how fast does it coarsen at 256²? Compare against plain advected φ plus a
   sharpening term. Run a blob and a thin filament.
2. **Blend divergence (decides G2).** Two mirror Fluids with different
   `viscosity` and `project`, the same force, blended by φ: the divergence of the
   plain blend relative to |u|, and how much the interface-aware rule lowers its
   peak.
3. **Coarsening at real time.** Frames for the region scale to double at default
   `coarsen`, and whether it needs more than one phase step per frame.
4. **Cost.** The φ chain on the bench at 256²; input minification at `taps` 1, 2, 8.
5. **Builder and pix limits.** Whether the builder can express three input inlets
   with `vs_inState` gating on two of them, and whether every stage stays within
   three pix inputs (the bench covers at most three).
6. **Cross-module feedback cycle (stage 2 only).** A scratch Max test: two
   trivial modules feeding each other through a one-frame `hold` delay.

## Proposed Phasing (details in `plan.md` and `tasks.md`)

- **Phase 0:** verification-tier gate, NumPy mirror, experiments 1–3 and 5
  (offline), gates G2 and G7.
- **Phase 1:** codeboxes on the bench, cost (experiment 4), stage by stage and
  host-sequenced.
- **Phase 2:** build the module from `definition.py`; contracts; live look with two
  Fluids; stage 1 closes here.
- **Phase 3:** reference doc, helpfile, menu placement, README row; confirm the
  name (G1).
- **Phase 4 (gated):** stage 2: the cycle test, `f_vf_mix` additive if the existing
  force inlet is chosen, nudge and force outlets.

## Out of Scope (This Version)

- A single-fluid mode; tensor inputs.
- Feeding anything back into the Fluids (stage 2, gated).
- Buoyancy and surface tension in v1 (stage 2).
- Viscosity or drag maps inside `f_vf_fluid` (the fallback if two Fluids cost too
  much; a separate change to Fluid).
- More than two phases; a free surface; variable density; compressibility.
- Non-periodic edges; absorbing or reflecting boundaries.
- Colouring φ (a downstream consumer's job).
- Generating drops (upstream: `f_grain`, `f_splat`).
