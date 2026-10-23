# Spec: f_wc

_Created: 2026-10-22_
_Status: Draft — not yet built_
_Origin: `ideas/f_vf_wilson_cowan.md` (Wilson-Cowan neural mass model,
Butler et al. 2012 PNAS variant with long-range inhibitory diffusion;
Ermentrout-Cowan 1979 hallucination-form taxonomy). Spec'd in one pass
without a prior spike; the spike is Phase 0 below (the f_ks spec had
`tests/records/spike_ks_stability.py` behind it — this module's
equivalent spike does not exist yet, so everything the f_ks spec
"carried from the spike" is here an explicit Phase 0 deliverable)._

**Working name — not settled.** `f_wc` (physics-name convention,
parallels `f_ks` and `f_chladni`) is a placeholder; see Clarifications.
The idea file's `f_vf_wilson_cowan` is rejected: the output is a
grayscale visual-field pattern (luma), not an RG vecfield, and the
module is an autonomous generator — the `f_vf_` prefix would misstate
both the type contract and the archetype (same reasoning as `f_ks`,
which is also not `f_vf_` despite having a plausible `grad(u)` outlet).

---

## Concept

A 2D Wilson-Cowan neural mass field: two coupled scalar populations,
excitatory `E(x)` and inhibitory `I(x)`, evolving per

```
tau_E * dE/dt = -E + (1 - r_E * E) * S(w_EE * E - w_EI * I + P + D_E * lap(E))
tau_I * dI/dt = -I + (1 - r_I * I) * S(w_IE * E - w_II * I + Q + D_I * lap(I))
```

with `S` a sigmoid nonlinearity, `w_**` coupling weights, `P`/`Q`
external drives, `D_E`/`D_I` diffusion coefficients (`D_I > D_E`: the
Butler variant's long-range inhibition), simulated on a periodic
domain and mapped at render time through the inverse retinotopic
(log-polar) transform so that pattern forming in simulated cortex
coordinates appears in visual-field coordinates as the classic
Ermentrout-Cowan hallucination forms: funnel, spiral, lattice
(honeycomb), cobweb.

The aesthetic target is specific: not generic reaction-diffusion
texture, but that taxonomy of geometric forms, with a control surface
that lets a performer navigate to a form category the way a WFG dial
navigates to a waveform.

## Why this module, in this library

- `f_ks` ships a self-sustaining chaotic generator (cells, ridges) but
  its pattern vocabulary is one texture family, tuned by `scale` and
  `sharp`. `f_wc` targets a *catalogued* taxonomy of structurally
  distinct geometric forms — a generator whose parameter space has
  known, named landmarks.
- The Butler paper's framing — normal vision = excitation driven by
  external stimulus, hallucination = spontaneous pattern overwhelming
  the drive — gives the module a natural *driven* mode (a texture
  inlet modulates the cortical drive) that no existing `f_` generator
  has, and that makes "hallucinate" a performable continuous gesture
  rather than a mode switch.
- The solver architecture is proven in-repo: the f_ks spectral pattern
  (exact linear step per Fourier bin + explicit real-space
  nonlinearity + one-frame feedback) transfers directly; diffusion is
  the easy case of spectral integration (unconditionally stable).

---

## Clarifications

### Resolved by design discussion (2026-10-22, Claude + Matt)

- **Archetype: generator (source), not vecfield producer.** Every
  existing `f_vf_*` is either stateless or stateful-but-input-driven;
  a self-running autonomous field would be a new kind of thing in that
  family, and the aesthetic target is a pattern you watch, not a field
  you consume. `archetype: "source"`, one luma outlet, `f_ks`/`f_chladni`
  role. A `grad(E - I)` vecfield outlet is one extra stage later if a
  real consumer need surfaces.
- **Diffusion is spectral, not real-space DoG.** The idea file's open
  perf question (difference-of-Gaussians convolution cost) assumed a
  real-space kernel. The Butler variant's long-range inhibition is
  *diffusion* — exactly what the spectral stage computes for free as a
  per-bin multiplier `exp(-D k^2 dt)`, unconditionally stable at any
  `dt`. The lateral-inhibition *kernel* framing only matters for
  non-diffusive connectivity, which v1 does not use.
- **Two fields, two parallel solver chains (boring option first).**
  E and I do not share one DFT trivially. v1: two parallel chains of
  the f_ks stages (hold/pass/seed → DFT×2 → spec → IDFT×2 → nl), ~12
  stages at 256². The optimization if benching demands it: pack E+iI
  into one complex DFT and split via Hermitian symmetry. Start boring;
  `src/f_ks/gen_dft.py` is already factored to be reused and would be
  lifted a second time.
- **The retinotopic map is part of the module, in the enc stage.**
  What forms in cortical coordinates is rolls or hexagons; the four
  classic forms are what those become under the inverse retinotopic
  map (roughly log-polar → Cartesian). Without the map the module
  shows stripe/blob texture, not the taxonomy. The map is a render-time
  resample in the `enc` stage (the f_ks `enc` role: fixed-size solver
  state → render-resolution display), not a solver concern. Repo
  precedent for polar/log-polar resampling: `f_droste`, `f_mobius`.
- **Knob count is curated, not exhaustive.** Raw WC has ~8 parameters
  (4 couplings, thresholds/gains, `D` ratio, drives). The dial set is
  chosen from literature-backed aggregates (see Parameters), with the
  rest fixed to values from the Butler/Ermentrout-Cowan lineage. The
  Phase 0 spike's parameter-region map (Open Experiments 2) is what
  decides the final aggregates and their ranges.

### Open, not yet decided

- **Naming.** `f_wc` is a placeholder (see header). Alternatives that
  surfaced: `f_formconstants` (Ermentrout-Cowan's own term), something
  in the `f_cymascope`/`f_chladni` phenomenological vein. Flag, same
  as f_ks did.
- **Form selector: dial vs. continuum.** Whether the four forms occupy
  clean discrete parameter regions (a 4-position selector with glyph
  previews, the WFG-dial idea) or a fuzzy continuum (continuous knobs
  only) is *the* question the Phase 0 spike answers — it cannot be
  decided from the literature alone because the answer depends on
  basin widths at the chosen resolution, dt, and fixed-parameter set.
  Both UI shapes are spec'd below (US-4); the spike's region map
  picks one. If regions are clean: discrete selector + continuous
  knobs. If fuzzy: continuous knobs only, with the four forms as
  presets/snaps if they're stable attractors.
- **Drive inlet semantics.** The Butler narrative wants an external
  drive `P(x)` that a connected texture modulates. Exact shape
  (additive drive on E only? on both? luminance-gated?) and its
  default-when-unconnected (uniform `P0`) are Phase 0/1 decisions.
  v1 commits to *having* the inlet (US-2) but not to its exact
  coupling equation.
- **Output encoding.** `E` (or `E - I`, or `E` alone) has bounded but
  not naturally [0,1] range — same open question f_ks had. Hard clamp
  vs. soft compression is a tier-3 Phase 2 decision once the real
  dynamic range is measured.
- **Map constants.** The retinotopic map has its own parameters
  (eccentricity range, log base / scale, foveal singularity handling,
  polar origin offset). Defaults from the Bressloff/Ermentrout-Cowan
  literature; whether any become user-facing dials (e.g. a "visual
  angle" scale) is tier-3.
- **Solver resolution.** Carried as 256² (f_ks parity), pending Phase 0
  cost re-verification with two fields — the effective stage count is
  ~2× f_ks's. 128² is the fallback, same framing as f_vf_fluid's own
  choice.

---

## User Stories

### User Story 1 — Autonomous hallucination-form generator (Priority: P1)

A performer drops `f_wc` into a patch with no inlets connected, and it
produces a continuously evolving geometric pattern — funnel, spiral,
lattice, or cobweb depending on settings — rendered in visual-field
coordinates, never settling to a static image and never needing
external drive.

**Why this priority**: the module's whole reason to exist — the
specific Ermentrout-Cowan form taxonomy, as a live generator.

**Independent Test**: patch `f_wc` alone into `vs_preview`. With the
form selector (or parameter region) set to each of the four categories
in turn, the output is recognizably that category's geometry (tier-3
judgment: does a spiral read as a spiral), keeps evolving, and never
blows up or freezes.

**Acceptance Scenarios**:
1. **Given** a freshly loaded module (randomly seeded cortical state),
   **When** frames run with no inlets connected, **Then** the output
   keeps evolving indefinitely (no freeze, no decay, no blow-up) for at
   least 10,000 frames.
2. **Given** parameters in the spike-mapped region for each of the four
   form categories, **When** the module runs from random initial
   conditions, **Then** the visual-field output develops that
   category's geometry within a bounded warm-up time (spike-measured;
   lattice/spiral forms take O(100) frames to nucleate — the number
   comes from the spike).
3. **Given** the module running in any form region, **When** more
   frames run, **Then** no NaN/Inf ever reaches the outlet and the
   displayed range stays within the module's defined output bounds.

---

### User Story 2 — Driven mode: external stimulus vs. spontaneous pattern (Priority: P1)

A performer connects a texture (the "scene") to the drive inlet. At
low excitability, the module's cortical pattern follows the scene
(normal vision: the drive dominates). As excitability is raised past
threshold, spontaneous self-organized pattern overwhelms the drive
(hallucination). The transition is continuous and performable.

**Why this priority**: this is the Butler paper's actual mechanism and
the module's performative core — "how hallucinated is this" as a
single continuous gesture over a live input, which no existing `f_`
generator offers. Equal priority with US-1: without the drive inlet
the module is a screensaver; with it, it's an instrument.

**Independent Test**: connect a high-contrast moving texture to the
drive inlet. Sweep the excitability control across threshold: below
it, the output tracks the input's structure (edges/regions visible in
the cortical response); above it, geometric form constants emerge and
dominate regardless of input content.

**Acceptance Scenarios**:
1. **Given** a static structured texture on the drive inlet and
   excitability well below threshold, **When** frames run, **Then**
   the output's structure follows the input (measurable: output/input
   correlation above a spike-determined bound).
2. **Given** the same input and excitability well above threshold,
   **When** frames run, **Then** the output shows spontaneous
   geometric structure with input correlation below the bound.
3. **Given** the drive inlet disconnected, **When** frames run,
   **Then** the module behaves exactly as in US-1 (uniform default
   drive).

---

### User Story 3 — Form navigation (Priority: P1)

A performer can reliably reach each of the four form categories
(funnel, spiral, lattice, cobweb) from the control surface — via a
discrete selector if the spike shows clean parameter regions, or via
continuous knobs with documented landmarks if it doesn't — without
needing to understand the underlying equations.

**Why this priority**: the taxonomy is the promise; a control surface
that can't navigate it fails the module's point even if the solver is
perfect.

**Independent Test**: set each form in turn from the UI, from a cold
(random) state, and confirm the named geometry appears (tier-3).

**Acceptance Scenarios**:
1. **Given** the spike's region map, **When** the selector/knobs are
   set to each mapped category, **Then** the corresponding geometry
   develops from random initial conditions within the spike-measured
   warm-up time, in at least 4 of 5 independent random seeds per
   category (some categories may have seed-dependent mode selection —
   the spike measures this).
2. **Given** a running pattern in one category, **When** the selection
   changes to another category, **Then** the pattern reorganizes into
   the new category without a reset and without diverging.
3. **Given** the module has been live-patched mid-performance,
   **When** the selector moves through its full range over a few
   seconds, **Then** no transient produces NaN/Inf or a hard visual
   blow-out (rate-of-change limiting on the critical coupling is
   acceptable if the spike shows it's needed).

---

### User Story 4 — Rate, scale, and reset (Priority: P2)

A `rate` dial scales evolution speed per frame (dt multiplier, clamped
to the measured stability ceiling); a `scale` control sets the
characteristic cortical wavelength (pattern grain relative to the
mapped visual field); a reset re-seeds the cortical state from fresh
noise.

**Why this priority**: the performable feel controls, same role as
f_ks's `rate`/`scale`/`reset`.

**Independent Test**: sweep `rate` and `scale` across their ranges
live; send reset repeatedly; no setting produces NaN/Inf, freezing, or
a shared state between instances.

**Acceptance Scenarios**:
1. **Given** `rate` at maximum, **When** frames run for 10,000 frames,
   **Then** the output stays finite and bounded (effective dt clamped
   to the Phase-0-measured ceiling regardless of requested rate).
2. **Given** a reset mid-run, **When** frames continue, **Then** the
   state re-seeds from fresh noise (E = I = rest state is NOT a fixed
   point only in a sub-region — see Edge Cases — so reset-to-noise is
   the unconditional path) and resumes evolving with no NaN seam.
3. **Given** two instances in one patch, **When** both run, **Then**
   their states evolve independently (`#0_`-scoped names throughout).

---

### User Story 5 — Standard f_ module behavior (Priority: P3)

Bypass, autopattr, `moduleSize`, canonical parameter names, multiple
independent instances — the library baseline.

**Why this priority**: required for usability, not the point.

**Independent Test**: module contract bench
(`tests/contracts/bench_modules.py`); two instances in one patch.

**Acceptance Scenarios**:
1. **Given** bypass is on, **When** frames run, **Then** the outlet
   shows the bypass-neutral output (f_ks precedent: black, alpha 1)
   while the solver keeps running underneath.
2. **Given** a saved and reloaded patch, **When** frames run, **Then**
   the state re-seeds cleanly from noise on load (never from zero —
   see Edge Cases).

---

## Requirements

### Functional Requirements

- **FR-001**: The module MUST hold persistent two-field state `(E, I)`
  across frames in a one-frame feedback loop (the f_ks/f_vf_fluid
  pattern: `hold -> pass -> solver stages -> nl -> hold`), at a fixed
  internal resolution (256² carried, pending Phase 0 cost check; 128²
  fallback).
- **FR-002**: The linear part (decay + diffusion for both fields) MUST
  be integrated exactly per Fourier bin — per-bin multiplier
  `exp((-1 - D k^2) dt / tau)` — reusing the f_ks separable DFT chain
  (`src/f_ks/gen_dft.py`, itself lifted from `f_vf_fluid`; a third
  reuse should factor it, decided at build time).
- **FR-003**: The nonlinear part (sigmoid coupling, refractory terms,
  drive) MUST be applied explicitly in real space after the spectral
  step, on both fields (the `nl` stage role in f_ks).
- **FR-004**: State MUST be seeded from random noise on load and on
  reset — never from zero, never from the spatially uniform rest
  state, because uniform rest is a fixed point whose stability is
  parameter-dependent (see Edge Cases); noise seeding is the
  unconditional correct path.
- **FR-005**: A `rate` control MUST scale the effective per-frame dt;
  the module MUST clamp effective dt to the Phase-0-measured stability
  ceiling regardless of the requested value.
- **FR-006**: A drive inlet MUST modulate the cortical drive term
  (shape per Clarifications); unconnected, the drive MUST default to
  its uniform spontaneous-pattern value.
- **FR-007**: The render stage MUST apply the inverse retinotopic
  (log-polar → Cartesian) map when sampling the cortical state to the
  visual-field output, with map constants per Clarifications; the map
  is a resample, not a solver modification.
- **FR-008**: The output MUST be mapped to a bounded, displayable
  grayscale range with no NaN/Inf ever reaching the outlet; the exact
  mapping is a Phase 2 tier-3 decision.
- **FR-009**: A reset/reseed trigger (message or UI bang) MUST
  re-randomize both fields from fresh noise without reloading the
  module.
- **FR-010**: A form-navigation control MUST exist whose shape
  (discrete selector vs. continuous knobs) is decided by the Phase 0
  region map (see Clarifications). If discrete: the four categories
  with distinct parameter sets per category. If continuous: the
  documented landmark parameter sets MUST be reachable as snap points
  or presets.
- **FR-011**: All object names MUST be `#0_`-scoped.
- **FR-012**: Standard bpatcher conventions (`routepass`, `route`,
  `autopattr` with `varname`, bypass toggle, `moduleSize` chain) and
  canonical parameter naming.
- **FR-013**: Internal solver resolution MUST be independent of the
  Vsynth render resolution; the `enc` stage samples at render size
  with smooth interpolation (f_ks precedent: `@adapt 0`).

### Non-Functional Requirements

- **NF-001** *(target, pending measurement)*: per-frame cost of the
  two-field solver plus the mapped render stage stays within real-time
  budget in a typical Vsynth patch on Matt's machine — measured in
  Phase 0 against f_ks's cost as the reference point (expected ~2×,
  plus one render-res resample).
- **NF-002**: `float32` end to end; the DFT round trip matches
  `np.fft` within f_ks's already-achieved tolerance (same chain).
- **NF-003**: No NaN/Inf after 10,000 frames at any `rate` setting,
  with and without resets, in every mapped form region.
- **NF-004**: Verification tiers: Phase 0 NumPy spike first (tier 1,
  mirror + region map + stability ceilings), then bench with
  frame-exact multi-frame feedback (tier 2), then scratch-patch
  judgment for form quality, mapping feel, and the drive transition
  (tier 3).

---

## Parameters (proposed — final set fixed by Phase 0)

| Dial | Underlying | Notes |
|---|---|---|
| `form` | discrete selector over 4 spike-mapped parameter sets | ONLY if the spike shows clean regions; otherwise replaced by continuous couplings (see Clarifications) |
| `hallucinate` | excitability aggregate — scales the coupling gains through the pattern-forming threshold | the performative core (US-2): below threshold the drive dominates, above it spontaneous pattern does |
| `rate` | per-frame dt multiplier | clamped per FR-005 |
| `scale` | characteristic cortical wavelength (sets `D` ratio / domain size) | pattern grain in the mapped visual field |
| `drive_gain` | gain on the drive inlet's contribution | how strongly the scene pushes the cortex; at 0 the module is US-1 pure |
| `sharp` | output-map edge sharpening | f_ks precedent |
| `reset` | reseed button/message | FR-009 |

Internal-only (spike-determined, fixed): the four coupling weights'
base values, `tau` ratio, refractory strengths, `D_E`, sigmoid
thresholds — all subject to the Phase 0 region map.

---

## Success Criteria

1. **Diffusion is exact:** single-Fourier-mode decay of E and I matches
   the analytic per-bin rates within tolerance (bench; mirrors the
   spike's single-mode check).
2. **Spontaneous pattern formation:** from random initial conditions
   with uniform drive, in each mapped form region, the cortical field
   develops the predicted symmetry-broken structure (rolls/hexagons in
   cortical coordinates) within the spike-measured warm-up — verified
   numerically in the spike (structure-factor peak at the predicted
   wavelength), visually in tier 3 (the mapped form constant).
3. **The taxonomy renders:** each of the four categories produces its
   named visual-field geometry through the retinotopic map — funnel,
   spiral, lattice, cobweb (tier-3 judgment, Matt).
4. **Drive transition works:** output/input correlation is high below
   threshold and low above it (bench-measurable proxy), and the
   transition reads as continuous in tier 3.
5. **Frame-exact feedback:** multi-frame bench runs of the real
   codeboxes match the NumPy mirror within the standard tolerance over
   100+ frames.
6. **Stable:** no NaN/Inf after 10,000 frames at `rate` extremes, in
   every form region, including across resets.
7. **Never frozen:** state changes meaningfully between any two
   snapshots 100+ frames apart in every form region (traveling-wave
   regions are in motion by construction; standing-pattern regions may
   be near-static in cortical coordinates but must not be a degenerate
   fixed point — the spike defines "meaningfully").
8. **Expressive (tier 3, Matt's judgment):** the four forms are
   visibly distinct from each other and from every existing `f_`
   generator; `hallucinate` reads as one legible gesture; the WFG-dial
   navigation (if shipped) lands on its named form reliably.

---

## Edge Cases

- **Uniform rest state is conditionally stable.** E = I = rest is a
  fixed point; below the pattern-forming threshold it's *attracting*.
  FR-004 (noise seeding, never zero/uniform) is the unconditional
  guard — but note the asymmetry with f_ks: there, u = 0 frozen was
  the failure mode; here, a *too-clean* state in a below-threshold
  region decays to rest and the module goes quiet (blank output). This
  is correct dynamics (that's what "no hallucination" means), not a
  bug — but it means US-2's below-threshold behavior is "shows the
  drive", and US-1's regions must all be *above* threshold by
  construction (the spike verifies each mapped region patterns
  spontaneously).
- **Reset storms:** rapid resets must not leave the multi-stage chain
  mid-frame — same handling as f_ks's equivalent edge case, defined
  once stage boundaries are fixed in Phase 1.
- **Foveal singularity:** the log-polar map is singular at the origin.
  The enc stage MUST clamp/suppress the central region (a foveal
  radius inside which the map is not sampled); what that region
  displays (neutral gray, last-ring extrapolation, masked) is tier-3.
- **Mode competition near region boundaries:** if regions are clean,
  a selector jump is discontinuous by design (US-3 scenario 2 still
  requires no divergence); if fuzzy, mid-knob positions may show mixed
  or metastable patterns — acceptable, and the spike should
  characterize rather than eliminate it.
- **Two fields' NaN containment:** sigmoid saturation bounds the
  nonlinearity (unlike KS's quadratic gradient term), so WC is
  structurally safer — but the refractory/coupling arithmetic can
  still produce non-finite intermediates at extreme settings; the `nl`
  stage MUST zap non-finite values per the f_ks containment precedent.
- **Drive inlet hot-plug:** connecting/disconnecting the drive mid-run
  must not NaN (unconnected-read guard, same convention as other
  inlet-optional modules).
- **Render resolution changes:** solver state is fixed-size; a render
  resize must not reset or corrupt it (the map resamples, state is
  untouched).

---

## Open Experiments (Phase 0 — none yet run)

1. **NumPy mirror of the full solver** (`tests/records/spike_wc_*.py`):
   spectral diffusion + explicit sigmoid coupling, two fields, periodic
   256². Verify: single-mode decay rates, spontaneous pattern formation
   from noise, boundedness over long soaks.
2. **Parameter region map** (the load-bearing experiment): sweep the
   curated coupling aggregates and classify asymptotic patterns
   (structure factor / symmetry analysis) into rolls vs. hexagons in
   cortical coordinates; measure region widths, warm-up times,
   seed-dependence (mode selection variance), and the dt stability
   ceiling. **This experiment answers the dial-vs-continuum
   Clarification and fixes the `form` parameter sets.**
3. **Retinotopic map application:** apply the inverse log-polar map to
   spike-produced rolls/hexagons; verify funnel/spiral/lattice/cobweb
   emerge and judge the look (the one tier-3 step inside Phase 0 —
   static renders, no Max). Fix map constants and the foveal-radius
   handling.
4. **Drive coupling shape:** in the mirror, verify the
   below/above-threshold correlation behavior (Success Criterion 4)
   for the chosen drive coupling; pick the coupling equation.
5. **GPU cost check:** the two-field stage count (~2× f_ks) benched in
   real Vsynth context; decide 256² vs. 128².
6. **Output encoding:** measure the real dynamic range of the display
  quantity (`E`, or `E - I`) across all regions; propose the mapping
   for tier-3 confirmation.

---

## Proposed Phasing (details belong in plan.md)

- **Phase 0** — Open Experiments 1–4 (the NumPy spike: mirror, region
  map, retinotopic render, drive coupling). Deliverables: spike file(s)
  in `tests/records/`, the region map, resolved Clarifications (form
  selector shape, drive semantics, map constants), dt ceiling.
- **Phase 1** — solver codeboxes on the bench (frame-exact multi-frame
  match against the mirror), cost check (Experiment 5), build the
  bpatcher (multi-stage `pix_chain`, f_ks structure), module contract
  bench.
- **Phase 2** — scratch-patch tuning (tier 3): output encoding, form
  navigation feel, drive transition feel, map look (foveal handling,
  map constants), rate/scale ranges.
- **Phase 3** — reference doc, helpfile, `f_modules` menu placement,
  README row, final naming decision.

---

## Out of Scope (This Version)

- Vecfield outlet (`grad(E - I)` or otherwise) — generator only.
- Non-diffusive connectivity kernels (real-space DoG, axonal
  delays) — the diffusion approximation is the Butler variant's own
  simplification and is what makes the spectral solver work.
- Runtime-selectable solver resolution.
- Non-periodic boundary variants.
- Orientation-preference coupling (the full Ermentrout-Cowan V1 model
  includes orientation columns; the scalar two-field version already
  produces the form taxonomy — orientation structure is a possible
  later extension, not v1).
- Color mapping beyond grayscale (chain a colormap module downstream).
- Audio reactivity (no `f_chladni`-style audio inlet; the drive inlet
  is the modulation surface).
