# Spec: f_quasi

_Created: 2026-10-23_
_Status: Built and shipped 2026-10-26 (reference doc: `docs/f-reference/f_quasi.md`; where this spec and the module differ, the doc follows the module)_
_Origin: `ideas/f_quasi.md` (mined from michaelerule/webgpgpu `Example_27`,
`Example_28`, `Example_31`, `Example_33` by the omp run `webgpgpu-ideas-1`,
2026-10-23). Matt chose this as the first of the eight themes to spec, and
settled the four design questions below the same day._

**Working name — not settled.** `f_quasi` is a placeholder (gate G1 in
`tasks.md`).

---

## Clarifications

### Resolved by design discussion (2026-10-23, Claude + Matt)

- **Looks scope:** v1 ships the generator, the source's banded look and three
  outlets. The Relief and Slope-hue looks (ideas 07 and 08 in the omp run) are a
  gated Phase 2, after the generator is proven.
- **Zoom drive:** `zoom` is a cyclic dial on [0, 1) (one octave per cycle); the
  module stays stateless (no feedback). A small clock in the patcher advances it at
  a rate dial. Mechanics of the clock are a Phase 1 detail (T021).
- **Wave and octave counts:** fixed at 5 waves × 7 octaves (the source values).
  `density` and `envelope` are dials. Whether to expose the counts is revisited only
  after the Phase 0 cost measurement.
- **Outlets:** texture (banded luma), vecfield (analytic gradient), scalar
  (potential), after `f_chladni`'s three.

### Settled model (read from the source shaders, 2026-10-23)

Coordinates `q` centred on the frame. With `N = 5` orientations, `M = 7` octaves:

```
s_i   = 2^(zoom + i)                       octave i = 0 .. M-1
w_i   = exp(-0.5 * ((zoom + i - mu) / sigma)^2)      mu = 3, sigma = `envelope`
phi_k = k * pi / N                         k = 0 .. N-1 (same in every octave)
beta_k = frac(exp(pi * k))                 fixed quasi-random phase offsets
psi_ik = (beta_k + p) * s_i + (cos(phi_k) x + sin(phi_k) y) * 2 pi * B * s_i
P      = sum_i w_i sum_k cos(psi_ik) / (N * sum_i w_i)       P in [-1, 1]
```

`B` = `density` (source default 4 bands), `p` = `drift` phase (source drifts it
slowly). The source banded look is `s = (P*0.5 + 1) * N`, then a triangle fold of
`frac(s)` raised to 1.1.

- **Why the zoom loop is seamless:** the envelope is fixed in absolute scale, so
  advancing `zoom` by one doubling shifts the octave set by one. The pattern before
  and after the wrap differs only by the weight of the octave that leaves (scale 128,
  weight exp(-32)) and the one that enters (scale 1, weight exp(-18)). At `sigma` 0.5
  that is about 1e-8. It is **not exact, and it degrades fast as `sigma` widens**: at
  `sigma` 1 the entering octave has weight exp(-4.5) ≈ 0.011, a visible pop. So
  `envelope` needs a cap (T004).
- **Only about three octaves carry weight at the source settings** (weights 0.135,
  1, 0.135 at log2 scale 2, 3, 4). The other four are cost for headroom when `envelope`
  is widened.
- **Gradient (exact):** `grad P = -sum_i w_i sum_k sin(psi_ik) * 2 pi B s_i * dir_k
  / (N * sum_i w_i)`, with `dir_k = (cos phi_k, sin phi_k)`. The webgpgpu
  `Example_31` accumulates `-sin(psi) * dir` without the `2 pi B s` factor, so it is
  a direction-and-relative-strength field, not the true gradient. Magnitude scales with
  octave frequency.
- **Gradient encoding (proposed, gate G2):** divide by the weighted total frequency,
  `v = sum_i w_i s_i sum_k (-sin psi_ik) dir_k / (N * sum_i w_i s_i)`. This is exactly
  bounded by 1 in magnitude, so it encodes into the f_vecfield range (`v*0.5+0.5`)
  without clipping, independent of `density` and `zoom`, and a `gain` dial scales it
  per the library convention.
- **Aspect:** the source scales `x` by aspect and divides `y` by aspect, which is not
  isometric. This module uses isotropic coordinates (`x` scaled by aspect only) so
  rings stay round and wave directions stay true (T008).

### Open, not yet decided

- **G1 naming.** `f_quasi` versus a name that says what a performer sees.
- **G2 vecfield normalisation** (above): confirm the bounded form, or prefer a fixed
  scale.
- **Nyquist handling.** With `density` raised the finest octave can exceed the
  sampling rate and alias; likely a smooth per-octave fade by cycles per pixel, using
  the render size. Whether the cutoff is per octave or global is a Phase 0
  measurement (T005).
- **Clock mechanics (T021).** Frame-count based like the other modules' `rate` dials
  (frame-rate dependent), or time based.
- **Cost.** 35 cosines plus 7 exp/log2 per pixel per frame at the source settings; skip
  octaves below a weight threshold only if it stays branchless-safe. Measured in T006.

---

## User Stories

### User Story 1 — A self-sufficient interference-pattern generator (Priority: P1)

A performer drops `f_quasi` into a patch with no inlet connected and gets a
quasicrystal interference pattern (five-fold, never periodic) at the module's own
resolution, with no input texture.

**Why this priority**: it is the module's reason to exist, a generator the library
lacks. `f_chladni` is a fixed modal figure and `f_ks` is chaotic; neither is a
quasi-periodic tiling or zooms coherently.

**Independent Test**: patch it alone into `vs_preview`; a stable, sharp, five-fold
pattern appears, with no aliasing shimmer at default settings.

**Acceptance Scenarios**:
1. **Given** default settings, **When** the module runs, **Then** the texture shows
   banded five-fold structure with no input connected.
2. **Given** `density` raised to its maximum, **When** viewed at 1920×1080, **Then** no
   aliasing shimmer (high octaves fade instead of folding).

### User Story 2 — Endless zoom (Priority: P1)

A performer advances `zoom` (by hand, by a mod source, or with `zoom_rate`) and the
pattern scales endlessly without changing character, wrapping at one octave with no
visible seam.

**Independent Test**: sweep `zoom` from 0 to 1 and back at the default envelope; the
frame at 0.999 and at 0.000 differ by less than 1.5e-4 in P (the T004 tolerance).

**Acceptance Scenarios**:
1. **Given** the default envelope, **When** `zoom` wraps from 1 to 0, **Then** no
   visible pop.
2. **Given** `zoom_rate` non-zero, **When** left running, **Then** zoom advances
   continuously in either direction.

### User Story 3 — Analytic gradient as a vecfield (Priority: P1)

A performer patches the vecfield outlet into a consumer (`f_caustic`, `f_vf_warp`,
`f_vf_streak`) and gets the pattern's own slope field with no finite-difference
sampling.

**Independent Test**: tier 1 checks the gradient against a finite difference of the
potential; tier 2 diffs the GPU outlet against the mirror.

**Acceptance Scenarios**:
1. **Given** any settings, **When** the vecfield outlet is read, **Then** every pixel
   decodes to a vector of magnitude at most 1 (no clipping).
2. **Given** `gain` 0, **When** read, **Then** the outlet is the neutral field
   (R = G = 0.5).

### User Story 4 — Density, envelope, bands, rotation (Priority: P2)

A performer shapes the texture: `density` (cycles per frame height), `envelope` (how
many octaves are visible), `bands` (contour count in the banded look), `angle` (global
rotation), `drift` (phase drift).

### User Story 5 — Standard f_ module behaviour (Priority: P3)

`bypass`, naming, menu placement and docs follow the library conventions (see
Requirements).

---

## Requirements

### Functional Requirements

- **FR-001**: The module MUST be a pure generator with no required inlets.
- **FR-002**: The potential MUST follow the settled model above (5 waves, 7 octaves,
  log-Gaussian envelope fixed at `mu = 3` in absolute log2 scale, orientations
  `k pi / 5`, quasi-random phase offsets `frac(exp(pi k))`).
- **FR-003**: The module MUST be stateless: no feedback pass, no `pass`/`hold` stage.
  All animation comes from parameters.
- **FR-004**: `zoom` MUST be cyclic on [0, 1); a value outside is wrapped before use.
- **FR-005**: A clock in the patcher MUST advance `zoom` (and `drift`) at their rate
  dials. A rate of zero MUST freeze the pattern exactly.
- **FR-006**: The vecfield outlet MUST emit the exact analytic gradient, normalised as
  in the settled model (bounded by 1), encoded per `docs/f-reference/f_vecfield_type.md`
  (`v*0.5+0.5`, B = 0.5, A = 1), scaled by `gain`.
- **FR-007**: The scalar outlet MUST emit the potential `P` mapped to 0–1 (`P*0.5+0.5`).
- **FR-008**: The texture outlet MUST render the banded look from `P`: triangle fold of
  `frac((P*0.5+1) * bands)`, raised to 1.1 (source value; Phase 2 may expose the
  exponent). `bands` defaults to 5.
- **FR-009**: Octaves near the Nyquist limit MUST NOT alias visibly. T005 (2026-10-26):
  at 1080p inside the parameter ranges no octave carrying weight exceeds 0.50 cycles per
  pixel, so no fade is needed there; whether to ship a per-octave smooth fade without
  renormalisation (start 0.25, end 0.5) as insurance for small render sizes is decided
  at the T030 look, with the T006 cost.
- **FR-010**: `envelope` MUST be capped so the zoom-wrap residual stays under the
  Phase 0 tolerance (the cap is a measured number, not a guess): set by T004 at 0.7, tolerance 1.5e-4 in P.
- **FR-011**: Coordinates MUST be isotropic (aspect applied to `x` only).
- **FR-012**: Standard f_ behaviour: bypass via a codebox `bypass_gate` Param (never
  the native `@bypass`): texture outlet emits black with A = 1 (as `f_chladni` and
  `f_ks`), vecfield outlet emits 0.5 / 0.5, scalar outlet its neutral. Confirm against
  `build/spec.md` before the Phase 1 build.
- **FR-013**: Every sample uses explicit coordinates; no reliance on `sample()`
  wrapping (there are no samples in this module, so the 2026-10-20 clamp findings do
  not apply).

### Non-Functional Requirements

- **NF-001**: Cost measured at 1920×1080 on the M3 Max and recorded as a number; the
  M1 is unmeasured and is flagged, not assumed (`ways-of-working`: GPU budgets should
  hold on the M1).
- **NF-002**: Float32 evaluation of `cos(psi)` with `psi` up to about 1.6e3 rad must
  agree with float64 within the tier-1 tolerance.
- **NF-003**: Output is deterministic: identical parameters give identical frames.

## Parameters (proposed — final set fixed by Phase 0)

| Param | Range | Default | Notes |
|---|---|---|---|
| `zoom` | 0–1 (cyclic) | 0 | base scale = 2^zoom, one octave per cycle |
| `zoom_rate` | signed, octaves/s (unit settled in T021) | small non-zero | patcher clock |
| `drift` | signed rate | small | advances the phase offset; a base-octave phase in turns, offset `2 pi phi` shared by every octave (2026-10-30; it was `2 pi phi 2^i`, which jumped the pattern at every zoom wrap), wrapped at 1 (T002: an unbounded `p` loses precision) |
| `density` | about 1–12 | 4 | cycles per frame HEIGHT at scale 1 (`B`; height, not width, because only `x` is scaled by aspect: T001) |
| `envelope` | 0.25–0.7 | 0.5 | `sigma`; cap 0.7 set by T004 (wrap residual under half an output level at bands 12) |
| `bands` | about 1–12 | 5 | contour count in the banded look |
| `angle` | 0–180 deg | 0 | global rotation of the five orientations |
| `gain` | 0–unbounded | 1 | vecfield strength (library naming) |
| `bypass_gate` | 0/1 | 0 | codebox Param |

Nine params at most; Matt's UI-density concern (`ideas/mod_depth_ui_density.md`)
applies, so the `zoom`/`zoom_rate`/`drift` trio is the first thing to trim.

## Success Criteria

- **SC-001**: Zoom-wrap residual (max absolute difference of `P` between `zoom` just
  below 1 and 0) is below the T004 tolerance at the default envelope and at the capped
  envelope.
- **SC-002**: The analytic gradient matches a central finite difference of `P` to the
  tier-1 tolerance everywhere away from numerical noise.
- **SC-003**: `P` stays in [-1, 1] and the vecfield decodes to magnitude at most 1 for
  every parameter combination in a sweep.
- **SC-004**: No aliasing shimmer at `density` max on a 1920×1080 target (tier 3).
- **SC-005**: Tier-3 look (Matt): reads as distinct from `f_chladni` and `f_ks`, and
  the zoom reads as endless.
- **SC-006**: Cost recorded (NF-001) and acceptable to Matt.

## Edge Cases

- `zoom` exactly 0 or 1, and negative or above 1 (wrap).
- `envelope` at its minimum (one octave dominates; the pattern is a single-scale
  quasicrystal) and at its cap.
- Very high `density`: Nyquist fade must engage.
- Extreme aspect ratios (vertical and ultra-wide): isotropic coordinates must keep
  directions true.
- `gain` 0 (neutral vecfield) and bypass on.
- Frame size change at runtime.
- Zero-weight flat regions: the gradient is exactly zero at saddle points; no
  division is involved in the gradient, so no NaN (the `atan2` NaN risk belongs to the
  Phase 2 Slope-hue look, not this phase).

## Open Experiments (Phase 0)

1. Wrap residual versus `envelope` (sets the cap).
2. Nyquist fade: per-octave cutoff by cycles per pixel at 1080p; check against a
   supersampled reference.
3. Cost at 1920×1080 with all 7 octaves versus skipping negligible ones.
4. Gradient normalisation (G2) rendered into `f_caustic` and `f_vf_warp` for a tier-3
   look.
5. Isotropic versus source aspect handling (a visual check only).

## Proposed Phasing (details belong in plan.md)

- **Phase 0**: NumPy mirror and its checks (T001–T005), cost bench (T006), gates.
- **Phase 1**: codebox, definition, clock, patcher (T020–T022).
- **Phase 2**: tuning and the Relief / Slope-hue looks (`ideas/f_quasi.md` modes 1 and
  2), contour-banding helper if `f_vf_potential` or `f_chladni` should share it.
- **Phase 3**: reference doc, helpfile, menu placement (`Patterns`), README row.

## Out of Scope (This Version)

- Relief shading and slope-hue colouring (Phase 2, gated).
- Exposing wave and octave counts as dials.
- Temporal state of any kind (no feedback, no persistent field).
- An input texture inlet or any use of the pattern as a mask or warp inside the module
  (the vecfield outlet feeds consumers instead).
- A multi-light or colour look beyond grayscale banding.
