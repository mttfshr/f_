# Spec: f_wave_field

_Created: 2026-10-23_
_Status: Draft — not yet built_
_Origin: `ideas/f_wave_field.md` (mined from michaelerule/webgpgpu
`Example_24`, `Vision_006`, `Vision_010`, `Vision_014` by the omp run
`webgpgpu-ideas-1`, 2026-10-23), the solver core that `ideas/f_cymascope.md`
asks for. The spectral direction and the four design questions below were
settled with Matt the same day._

**Working name — not settled.** `f_wave_field` is a placeholder (gate G1 in
`tasks.md`). Avoid `ripple`: `f_a_ripple` already exists (audio).

---

## Clarifications

### Resolved by design discussion (2026-10-23, Claude + Matt)

- **Solver: spectral, the `f_ks` DFT chain.** The wave equation is linear, so
  each Fourier bin takes an exact step: no stability limit, no real-space
  Laplacian, no CFL worry (the omp run's main risk). The real-space leapfrog from
  webgpgpu stays as the fallback only if Phase 0 shows the spectral cost is
  unacceptable.
- **General dispersion, not just the plain wave equation.** One dispersion relation
  covers every webgpgpu mode and more:
  `omega(k)^2 = ring^2 + speed^2 * k^(2*dispersion)` (normalised below).
  `dispersion` = 1 is the ordinary wave; `speed` = 0 with `ring` > 0 is the per-pixel
  resonator (`Vision_006`); both non-zero is a ringing wave (Klein-Gordon,
  `Vision_014`); `dispersion` 2 is plate waves (the physics of `f_chladni`);
  1.5 and 0.5 are capillary-like and deep-water-like. This is an addition over the
  omp drafts.
- **Edges: periodic, plus an absorbing-edge dial.** Native to the spectral solver;
  `edge` > 0 applies a real-space sponge near the borders. Reflecting edges (a mirrored
  grid, about 4 times the transform cost) are out of scope for v1.
- **Drive: optional force inlet, a point exciter and a strike.** A texture inlet adds
  forcing (unconnected: none, free ringing); a built-in point source (x, y, frequency,
  amplitude) gives cymascope-style driving; `strike` drops an impulse at the exciter.
- **Outlets: field luma and a gradient vecfield** (the `f_cymascope` use: a vecfield
  producer for `f_caustic`, `f_vf_warp`).
- **Audio is not in this module.** `f_cymascope` later becomes this module plus a
  front end (pitch tracker and envelope to `frequency` and `amplitude`).

### Model (settled; to be confirmed by the Phase 0 mirror)

State: position `u` and velocity `v = du/dt`, both real scalar fields on a periodic
N × N grid. Per Fourier bin `k` (angular wavenumber, `|k|` the magnitude):

```
omega^2 = ring^2 + (speed * kref * (|k|/kref)^dispersion)^2
          # speed is the phase velocity at the reference wavenumber kref (T004),
          # so changing `dispersion` does not change the apparent speed of
          # mid-scale waves
beta    = damping + nu * |k|^2     # nu: small fixed viscosity, tames the top bins
u'      = e^(-beta dt) [ u cos(wd dt) + (v + beta u) sin(wd dt)/wd ]
v'      = e^(-beta dt) [ v cos(wd dt) - (omega^2 u + beta v) sin(wd dt)/wd ]
wd^2    = omega^2 - beta^2
```

This is the exact solution of `u_tt + 2 beta u_t + omega^2 u = 0` over one step.
Three regimes need branch-free handling: underdamped (`wd^2` > 0), critically damped
(`sin(wd dt)/wd` → `dt`), overdamped (`wd^2` < 0: cosh and sinh; no `sqrt` of a
negative). The webgpgpu `Example_24` smooths the field before taking the Laplacian
(two Gaussian blurs); the viscous `nu |k|^2` term plays that role exactly and cheaply.

Per frame: forward DFT of `u` and `v` → spectral step (with the DC bin zeroed) →
inverse DFT → real-space stage: add forcing to `v` (`v += F dt`), apply the edge sponge
to `u` and `v`, compute the central-difference gradient of `u` (periodic), containment
(NaN/Inf zap, bounded clamp).

State packing follows the `f_ks` chain (and the retired `f_wc_fft`, HANDOFF 2026-10-23): the four channels of the `f_ks` DFT
chain are two independent complex fields; put `u` in the first (R = u, G = 0) and `v` in
the second (B = v, A = 0). The spectral stage mixes `u` and `v` at the same bin, so it
needs all four channels at once, which the `spec` stage already sees.

### Open, not yet decided

- **G1 naming.**
- **G2 output mapping.** Luma from `u` and the vecfield from `grad u` have unbounded
  linear range. Hard clamp, `tanh`-style compression or auto-range, and the vecfield
  normalisation, are open (tier 3, same shape as `f_ks`'s T005). A `gain` dial is
  expected.
- **G3 time units.** The model step is one frame (frame-rate dependent, like `f_ks`
  `rate`), or seconds from a measured frame time (`ideas/variable_framerate.md`).
  `frequency` and `speed` units follow.
- **G4 dial count.** About 11 dials plus buttons is more than the library's UI density
  tolerates (`ideas/mod_depth_ui_density.md`); grouping and a possible `medium` preset
  menu (Membrane, Water, Plate, Resonator) are Phase 2.
- **Hidden constants:** `kref`, `nu`, the sponge width and profile (T004).
- **Shared DFT chain.** The shared generator is `src/f_vf_fluid/gen_dft.py`; each user has a thin adapter
  (`src/f_ks/gen_dft.py`). The third user, the old `f_wc_fft`, was retired 2026-10-25 and its adapter deleted
  (its T020 decision is in `.specify/superseded/f_wc_fft/tasks.md`). This module adds its own adapter.

---

## User Stories

### User Story 1 — Visible rings with nothing connected (Priority: P1)

A performer drops `f_wave_field` in alone and sees waves: a default exciter drives
concentric rings that expand, wrap or are soaked up at the edges, and interfere.

**Why this priority**: it is a generator `f_` lacks. `f_chladni` is a standing figure,
`f_ks` is chaotic, `f_vf_fluid` makes flow; none propagates interfering waves.

**Independent Test**: patch it alone into `vs_preview`; within a second rings are
visible, and they keep going (the default exciter amplitude is non-zero).

**Acceptance Scenarios**:
1. **Given** a freshly loaded module, **When** frames run with no inlet connected,
   **Then** expanding rings appear and persist while the exciter runs.
2. **Given** `amplitude` 0 and a `strike`, **When** the field rings freely, **Then** it
   decays at the `damping` rate and never grows.

### User Story 2 — Wave, resonator and plate in one module (Priority: P1)

A performer turns `dispersion`, `speed` and `ring` and gets different media: ordinary
ripples, per-pixel ringing that follows input, plate-like patterns.

**Independent Test**: tier 1 checks each regime against its closed form (single-mode
frequency and decay).

**Acceptance Scenarios**:
1. **Given** `speed` 0 and `ring` > 0, **When** a force texture is applied, **Then** each
   pixel rings independently at `ring` (no spatial propagation).
2. **Given** `dispersion` 1, **When** a pulse is struck, **Then** the ring radius grows
   at the phase velocity `speed` and the shape does not disperse.

### User Story 3 — Drive it with a texture (Priority: P1)

A performer patches a texture (video luma, another generator) into the force inlet and
the field is forced by it: every bright area radiates.

**Acceptance Scenarios**:
1. **Given** the inlet unconnected, **Then** it reads as neutral (0.5) and applies no
   force.
2. **Given** a static non-neutral texture and non-zero `force`, **When** run, **Then**
   the field responds linearly (twice the force, twice the field).

### User Story 4 — Gradient vecfield for consumers (Priority: P1)

A performer patches the vecfield outlet into `f_caustic` or `f_vf_warp` and the
wave crests drive them.

**Acceptance Scenarios**:
1. **Given** a pulse, **When** the vecfield is read, **Then** it points along the
   gradient of the luma outlet.
2. **Given** a flat field, **Then** the vecfield is neutral (0.5 / 0.5).

### User Story 5 — Edges and strike (Priority: P2)

A performer sets `edge` for absorbing borders (0 = wraps) and presses `strike` to drop
an impulse at the exciter position. `reset` clears the field.

### User Story 6 — Standard f_ module behaviour (Priority: P3)

`bypass`, `#0_`-scoped names, helpfile, menu, README per the library conventions.

---

## Requirements

### Functional Requirements

- **FR-001**: The module MUST be usable with no inlet connected. The one texture inlet
  (force) is optional.
- **FR-002**: The module MUST hold `u` and `v` across frames in a one-frame feedback loop
  (the `f_ks` chain pattern) at a fixed internal resolution independent of the render
  size (N = 256 pending Phase 0 cost; 128² fallback), periodic domain.
- **FR-003**: The linear step MUST be the exact per-bin solution above in all three
  damping regimes, with no `sqrt` of a negative and no division by zero at `wd` = 0.
- **FR-004**: The dispersion relation MUST be `omega^2 = ring^2 + (speed * kref *
  (|k|/kref)^dispersion)^2`, with `speed` calibrated as the phase velocity at `kref`.
- **FR-005**: The DC bin MUST be zeroed every step (a point exciter has a non-zero mean
  force and would otherwise accelerate a mean offset without bound, the same class of
  failure as `f_ks`'s drift).
- **FR-006**: A small `damping` floor MUST keep float32 round-off from growing energy
  over long runs; its value is set in Phase 0 (T003).
- **FR-007**: The force inlet MUST add `F = force * 2 * (tex - 0.5)` to `v` each frame,
  neutral at 0.5 when unconnected.
- **FR-008**: The point exciter MUST add a Gaussian-profile force at (`x`, `y`) with a
  sinusoidal time dependence at `frequency` and strength `amplitude`; a phase accumulator
  runs in the real-space stage.
- **FR-009**: `strike` MUST add a single impulse at the exciter position (to `u`);
  `reset` MUST zero `u` and `v`. Both fire once on load (reset, then strike).
- **FR-010**: `edge` MUST apply a smooth absorbing sponge to `u` and `v` near the borders
  (0 = pure periodic wrap), by an exponential damping profile so it cannot add energy.
- **FR-011**: The luma outlet MUST be a bounded mapping of `u`; the vecfield outlet MUST be
  the central-difference gradient of `u` encoded per `f_vecfield_type.md` (`v*0.5+0.5`,
  B = 0.5, A = 1), bounded; no NaN/Inf ever reaches either outlet (containment).
- **FR-012**: Outlets MUST be bilinear and follow the render size (the solver size is
  independent), like `f_ks`'s `enc`.
- **FR-013**: Standard behaviour: `#0_` scoped names, `routepass` / `route` / `autopattr`
  with `varname`, bypass via a codebox `bypass_gate` Param (never native `@bypass`):
  luma black A = 1 (as `f_ks`), vecfield 0.5 / 0.5; the solver keeps running underneath.

### Non-Functional Requirements

- **NF-001** *(target, pending measurement)*: cost per frame at 256² within real-time budget
  on the M3 Max; the M1 is unmeasured and flagged (library rule).
- **NF-002**: Float32 end to end; transform round trip matches `np.fft` within the `f_ks`
  achieved tolerance.
- **NF-003**: No NaN/Inf after 10,000 frames at any parameter setting, with and without
  resets interspersed.
- **NF-004**: Verification follows the constitution's tiers (below).

## Parameters (proposed — final set fixed by Phase 0, trimmed by G4)

| Param | Range | Default | Notes |
|---|---|---|---|
| `speed` | 0–max | mid | phase velocity at `kref` (frame widths per unit time) |
| `damping` | floor–max | small | `beta` base rate |
| `dispersion` | 0.5–2 | 1 | 1 = ordinary wave, 2 = plate |
| `ring` | 0–max | 0 | `omega` at k = 0; with `speed` 0 gives the resonator |
| `edge` | 0–1 | 0.5 | absorbing-border strength; 0 wraps |
| `x`, `y` | 0–1 | 0.5, 0.5 | exciter position |
| `frequency` | range | mid | exciter frequency |
| `amplitude` | 0–1 | non-zero | exciter strength; 0 = free ringing |
| `force` | 0–1 | 1 | gain on the force inlet |
| `gain` | unbounded | 1 | output mapping strength (G2) |
| `strike`, `reset` | buttons | | also messages; fire on load |
| `bypass` | toggle | 0 | |

## Success Criteria

- **SC-001**: Single-mode closed forms: the mirror matches the analytic oscillation in the
  underdamped, critical and overdamped regimes within the T001 tolerance.
- **SC-002**: At zero damping (floor excepted) total spectral energy is conserved over
  1,000 frames within the T003 tolerance (target 1e-4 relative).
- **SC-003**: A struck pulse at `dispersion` 1 has a ring radius growing at the phase
  velocity; at `dispersion` 2 a single mode's frequency scales as k².
- **SC-004**: Superposition: field(a·F1 + b·F2) = a·field(F1) + b·field(F2).
- **SC-005**: With `edge` 0 a pulse that leaves one border reappears at the opposite one with
  the same shape; with `edge` > 0 the energy after crossing is reduced and never
  increases.
- **SC-006**: 10,000-frame soak (NF-003) at the parameter extremes, resets interspersed.
- **SC-007**: Cost recorded at 256² and 128² (NF-001) and acceptable to Matt.
- **SC-008**: Tier-3 look (Matt): reads as distinct from `f_chladni`, `f_ks`, `f_vf_fluid`;
  rings feel right; the vecfield drives `f_caustic` well.

## Edge Cases

- `speed` 0 and `ring` 0: no dynamics (the field only decays); must stay stable.
- `damping` large (overdamped low modes); `damping` at the floor.
- `dispersion` at both ends of its range (0.5 and 2), and `|k|` = 0 (DC) and the Nyquist
  row and column (handle as `f_vf_fluid` does; take the real part after the inverse).
- A force texture that is not neutral at rest, or a mean-non-zero force (DC zeroing).
- `frequency` above the solver's useful range, and `amplitude` at resonance with zero
  damping (growth bounded by containment, the floor and the viscous term).
- Render size changes at runtime; very small and very large aspect ratios.
- `strike` while the field is mid-ring; `reset` and `strike` the same frame.
- `edge` at 1 (strong sponge) must not reflect noticeably (smooth profile).

## Open Experiments (Phase 0)

1. Mirror of the exact step in all three regimes, with forcing and sponge.
2. Float32 versus float64 energy drift; set the damping floor.
3. Normalisation constants: `kref`, `nu`, sponge width and profile.
4. Output mapping and vecfield normalisation, compared on the same states (tier 3).
5. Cost at 256² versus 128² in a real patch, third DFT user.
6. Operator-splitting accuracy of real-space forcing and sponge against the exact driven
   response, to set the useful per-frame step.

## Proposed Phasing (details belong in plan.md)

- **Phase 0**: NumPy mirror and closed-form checks, constants, cost, gates.
- **Phase 1**: codeboxes (`spec`, `nl`, `pass`, `enc`), `definition.py`, patcher.
- **Phase 2**: tuning, dial grouping (G4), possible `medium` preset menu.
- **Phase 3**: reference doc, helpfile, menu placement, README row; `f_cymascope` as a
  follow-on front end.

## Out of Scope (This Version)

- Reflecting edges (mirrored grid) and non-rectangular dishes.
- Spatially varying medium (varying speed or obstacles): breaks the spectral step; would
  need the real-space leapfrog.
- Audio front end (pitch tracker, envelope): `f_cymascope`.
- Nonlinear or breaking waves; the webgpgpu amplitude homeostat (`Vision_014`).
- A velocity or energy outlet (Matt chose luma plus vecfield).
