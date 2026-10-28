# Spec: f_cmap

_Created: 2026-10-26_
_Status: Specced; Phase 0 (T001-T006) done 2026-10-27, gates G1-G7 open_
_Origin: `ideas/f_cmap_feedback.md` (mined from michaelerule/webgpgpu `Example_9`,
omp run `webgpgpu-ideas-1`, 2026-10-23; source re-read and the design settled with Matt
2026-10-26)._

**Working name, not settled.** `f_cmap` is a placeholder (gate G1 in `tasks.md`).

---

## Clarifications

### Resolved by design discussion (2026-10-26, Claude + Matt)

- **Use case:** performing with live input. The module takes a source texture and
  feeds it into the loop every frame.
- **No checker.** The source's 128 px checker for out-of-domain pixels is dropped
  outright: no toggle, no mask outlet. In the source the checker was the only thing
  injecting new information (its seed program is never called), so this module needs
  its own injection (below).
- **Rectangular (Square) map only.** Log mode is out of scope. If log space keeps
  recurring across modules, build a separate log-space transformer, not a mode here.
- **Tensor field:** not part of v1. A later optional vecfield inlet that offsets the pull
  per pixel (fed from `f_tf_tensormap` -> `f_tf_axisflow`) is Phase 2, gated.
- **Architecture:** Pattern 1 feedback, as `f_vf_advect` (a `pass` pix holding the
  previous frame, a primary pix reading source and previous frame), float32, render
  resolution (`adapt`).

### Settled model (read from the source shader, 2026-10-26)

Coordinates are isometric, centred, in frame-height units: `q = ((x-0.5)*aspect, y-0.5)`,
`z = 2 L q` with `L = 1.75` (the source `SCALE`; frame height spans [-L, L]). Per
frame, per pixel:

```
z' = z^n + w                    complex; n = 2 in the source
q' = z' / (2 L)
p' = (q'.x / aspect + 0.5, q'.y + 0.5)        sample position in the previous frame
hist = prev(p')   if p' inside the frame, else the bounds rule
out  = mix(decay * hist, src, inject)
```

`w` animates: angle `theta` advances `rate` per second, a second phase advances at
`sqrt(2) * rate`, and `|w| = radius + sweep * cos(phase)` (the source: radius 0.15,
sweep 1.5, angle step 0.01 and phase step 0.01 sqrt(2) per frame, so `|w|` sweeps
-1.35 to 1.65 and passes through zero).

- **Why isometric:** the map is conformal only if position becomes a complex number
  without independent x/y scaling (the source's square canvas hid this). Aspect is applied
  to `x` once, in and out, so rings stay round at any frame shape.
- **`z^n` by repeated complex multiplication**, integer `n` only: no `atan2`, no branch cut.
- **Smear (the real risk):** `|f'| = n |z|^(n-1)`. For n = 2 the pull magnifies near
  the centre (each frame's interpolation blurs, and the blur compounds) and minifies toward
  the edge (aliasing). Measured in Phase 0 (T004) before choosing a sampler.
- **Julia connection:** with no injection, iterating the pull is Julia-set dynamics and
  `w` is the Julia parameter. A tier-3 look, not a tier-1 claim.

### Open, not yet decided (gates in `tasks.md`)

- **G1 naming.** `f_cmap` versus something a performer reads (the idea file notes none).
- **G2 bounds region.** The source tests a disk of radius L (its canvas was square). For
  16:9 live video a frame-rectangle test (pulled point outside the texture) is the natural
  criterion; the disk leaves corners that never update. Proposed: the rectangle.
- **G3 `n` range.** Integer 2-4, default 2; or fixed at 2 for v1.
- **G4 sampler.** The previous frame is read with taps built by hand from `nearest()`,
  never a bare `sample()` (T006: the hardware `sample()` is exactly nearest in the minifying
  part of this pull). Choose a 4-tap bilinear (cost under the bench floor) or a 16-tap
  Catmull-Rom (about 0.66 ms at 1080p, 2.4 ms at 4K, derived); recommend the 4-tap for v1
  (tasks.md Record, 2026-10-27).
- **G5 dry/wet.** `inject` is already the source blend, so propose no `gain` / `mix_pct` in
  v1 (cf. the 2026-10-19 decision for processors with no dry/wet control); confirm.
- **G6 control trim.** The `angle` / `rate` / `radius` / `sweep` quartet and the `decay` /
  `inject` pair are many dials (`ideas/mod_depth_ui_density.md`); trim after T005.

---

## User Stories

### User Story 1 - Live-input feedback that winds into filaments (Priority: P1)

A performer patches a camera into `f_cmap` and gets the live image folded back through
`z^2 + w` every frame: motion winds up into filaments and spirals a one-shot warp cannot
make, while `inject` keeps the live source present.

**Independent Test**: camera in, defaults; a stable, evolving, non-degenerate image that
tracks the input (not black, not saturated, not frozen).

**Acceptance Scenarios**:
1. **Given** defaults and a moving source, **When** running, **Then** history accumulates
   and the source stays recognisable (inject > 0).
2. **Given** `inject` 0, **When** a source change occurs, **Then** the result evolves
   under the map only, decaying at `decay` per frame.

### User Story 2 - Animated Julia offset (Priority: P1)

`w` moves on a patcher clock: `rate` sets the angular speed (signed, 0 freezes it
exactly), `radius` and `sweep` set its amplitude path.

**Independent Test**: `rate` 0 gives an identical frame sequence for a static source and a
static loop; non-zero `rate` visibly moves the fringes.

### User Story 3 - Out-of-domain handling (Priority: P2)

A `bounds` menu decides what a pulled position outside the frame shows: Source (the live
input at that pixel), Black, or Wrap (the previous frame wrapped with explicit coordinates).

### User Story 4 - Standard f_ module behaviour (Priority: P3)

`bypass`, naming, menu placement and docs follow the library conventions.

---

## Requirements

### Functional Requirements

- **FR-001**: One required texture inlet (source). The module is a temporal processor, not
  a generator.
- **FR-002**: The pull MUST follow the settled model: isometric centred coordinates, `L` =
  1.75, `z' = z^n + w`, integer `n` (default 2), `z^n` by repeated complex multiplication.
- **FR-003**: History MUST be float32 and live in the `pass` stage; `out = mix(decay * hist,
  src, inject)`. `decay` is capped at 1.0 (bounded: no excitable regime in v1).
- **FR-004**: `inject` MUST be able to reach 0 (pure map evolution) and 1 (pure source).
- **FR-005**: `bounds` MUST offer Source, Black and Wrap. Source returns the source at the
  current pixel; Black returns 0 (A = 1); Wrap samples the previous frame at `fract(p')`
  with explicit texel-centre coordinates (no reliance on bare `sample()` wrapping: the
  2026-10-20 sampling findings, `skills/jit-gen-codebox/SKILL.md`).
- **FR-006**: A patcher clock MUST advance `theta` at `rate` (signed); `rate` 0 MUST freeze
  `w` exactly. The second phase advances at `sqrt(2)` times the angle rate. Mechanics follow
  `f_quasi`'s clock (frame-count versus time based: settled in T021).
- **FR-007**: `reset` MUST re-seed the history from the current source; `freeze` MUST hold
  the history (`f_wc` header-toggle precedent).
- **FR-008**: Standard behaviour: bypass via a codebox `bypass_gate` Param (never native
  `@bypass`); a bypassed module is a passthrough of the source (as `f_vf_advect`).
- **FR-009**: Control names MUST NOT collide with `jit.gl.pix` attributes or GLSL builtins
  (the dial-name and `texture` / `t` traps: `f_wc` HANDOFF); T020 checks every name.
- **FR-010**: Identity-map invariance: with `n = 1`, `w = 0`, `decay = 1`, `inject = 0`, the
  image MUST be unchanged frame to frame (texel-centre sampling exact; no drift).
- **FR-011**: The history read MUST be made from manual `nearest()` taps at texel-centre
  coordinates (with `dim` as the size, so the first inlet must be render-sized), not from a
  bare `sample()`: the coordinate of this pull jumps by more than a texel between
  neighbouring pixels wherever |f'| > 1, where the hardware filter falls back to nearest
  (jit-gen-codebox skill, 2026-10-06; confirmed here by T006 Part 1). Taps use a clamp of
  0.0005 / 0.9995 on the sample position (the wrap-seam rule, probe P9).

### Non-Functional Requirements

- **NF-001**: Cost at 1920x1080 on the M3 Max recorded as a number; the M1 flagged, not
  assumed. The bench has a resolution floor (about 0.2 ms); a result under it is reported
  as a bound.
- **NF-002**: Deterministic: identical source sequence and parameters give identical frames.
- **NF-003**: No NaN/Inf can enter the history (guard as `f_wc`'s pass stage).

## Parameters (proposed, final set fixed by Phase 0)

| Param | Range | Default | Notes |
|---|---|---|---|
| `decay` | 0.5-1.0 | 0.97 | history gain per frame (advect default) |
| `inject` | 0-1 | 0.05 | source weight per frame |
| `radius` | 0-1.75 | 0.15 | `\|w\|` base (source value) |
| `sweep` | 0-1.75 | 0 | radius modulation depth (source 1.5) |
| `rate` | signed turns/s (unit in T021) | small | patcher clock, 0 freezes |
| `angle` | 0-1 (cyclic) | 0 | manual `theta` offset |
| `power` | int 2-4 | 2 | exponent `n` (G3; name checked against FR-009) |
| `bounds` | Source / Black / Wrap | Source | menu |
| `freeze`, `reset`, `bypass_gate` | toggles | 0 | |

## Success Criteria

- **SC-001**: Identity-map invariance (FR-010) holds to float32 rounding.
- **SC-002**: The pull's Jacobian is a scaled rotation (singular-value ratio 1 within the
  tier-1 tolerance) at every pixel, at aspect 1, 16:9 and 9:16 (isometry, FR-002).
- **SC-003**: With nearest sampling, no decay and no injection, after n frames the image at
  z equals the original at `f^n(z)` (composition test).
- **SC-004**: The bounds region is exactly the set of pixels whose pulled position leaves
  the frame (G2 settles rectangle versus disk).
- **SC-005**: Tier-3 (Matt, live camera): reads as distinct from `f_droste` / `f_mobius`
  in `vs_feedback`; the smear is controllable with `inject` / `decay`.
- **SC-006**: Cost recorded (NF-001) and acceptable to Matt.

## Edge Cases

- `rate` 0 (frozen `w`), and `radius` 0 with `sweep` 0 (`w` = 0: fixed points at the
  origin and the unit circle for n = 2).
- `inject` 0 with a static source: history only, must not go NaN or saturate.
- Huge `|z|`: `z^4` reaches `L^4` (about 9.4); the pulled position then lies far outside
  the frame and the bounds rule decides.
- Aspect extremes (vertical, ultra-wide) and a runtime frame-size change (history is
  re-seeded or resampled: settled in T020).
- The source `dim` follows the first input's size in the bench (HANDOFF, 2026-10-26): feed
  the bench source at the render size.
- Pulled position exactly on a frame edge (the 2026-10-20 x = 1.0 / y = 0.0 knife edges).

## Open Experiments (Phase 0)

1. Smear: how many frames until a single-texel impulse is blurred below a threshold,
   bilinear versus Catmull-Rom, and where the field aliases (decides G4).
2. Usable `decay` / `inject` / `radius` region on synthetic live-like input (noise,
   gradient, moving edge), by mirror stills.
3. Bounds rectangle versus disk coverage at 16:9 (decides G2).
4. Cost at 1920x1080 (single pass plus `pass` copy).

## Proposed Phasing (details in `tasks.md`)

- **Phase 0**: NumPy mirror and its checks (T001-T004), look stills (T005), cost (T006),
  gates.
- **Phase 1**: codeboxes, definition, clock, patcher, bench, contracts (T020-T023).
- **Phase 2**: tuning, optional vecfield offset inlet (tensor-field route), `scale` dial.
- **Phase 3**: reference doc, helpfile, menu placement, README row.

## Out of Scope (This Version)

- Log mode, and any log-space transform (a separate transformer module if ever needed).
- The checker, or any out-of-domain mask outlet.
- A vecfield or tensor offset inlet (Phase 2, gated).
- Excitable (`decay` > 1) regimes; non-integer `n`.
- A second outlet of any kind.
