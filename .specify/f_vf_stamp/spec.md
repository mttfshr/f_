# Spec: f_vf_stamp

_Created: 2026-11-05_
_Status: Draft — not yet built_
_Origin: `ideas/f_vf_stamp.md` (was `f_splat`, raised 2026-10-27 as the missing "drop of ink"), reshaped with Matt on 2026-11-05 into a stamping tool, plus the held-press gate button from `f_wave_field` T042 (`docs/f-reference/f_wave_field.md`, D11-D14)._

---

## Clarifications

### Resolved with Matt (2026-11-05)

- **Stamp only.** The shape comes in as a texture; the module does not generate blots. Shapes come from upstream (`f_ngon`, `f_grain`, `f_vf_seeds`, a camera).
- **Name `f_vf_stamp`** (the `f_vf_` prefix: it takes and produces vecfields).
- **Coverage from luma**, not alpha (Vsynth textures are usually A = 1).
- **Two inlets plus control.** in0: the stamp texture (its shape is the blot, its RGB the ink). in1: a vecfield giving direction and force of motion at the same pixels. Control messages and the gate arrive on in0.
- **Two outlets.** out0: the ink (the stamp, masked and enveloped). out1: the impulse vecfield (in1 x the stamp's mask x amount x envelope).
- **With nothing on in1 the impulse is RADIAL**, derived from the stamp's own gradient (outward = minus the gradient of the mask), **with a switch to SWIRL** (the gradient rotated 90 degrees). A radial field is curl-free, so `f_vf_fluid` at its default `project` of 1 deletes it; a swirl survives `project`. The switch is why both exist.
- **A held press, not a trigger** (the `f_wave_field` Strike pattern): a `ubutton` sends a gate 1 on mouse-down and 0 on mouse-up; the `stamp` message is a tap; a release is applied on the third draw bang after it so any press is seen by at least two rendered frames. Counters, never timers.
- **Stateless module.** No feedback, no memory of its own. Persistence is downstream: `f_vf_advect` keeps the ink (ink per stamp = its `injection` times the envelope's integral), `f_vf_fluid` keeps the momentum (momentum per stamp = `force` times the integral). A hold is a faucet or a sustained jet, a tap is a kick.
- **Position is live from the texture.** A moving source with the press held paints a trail. A latch (a snapshot at the press) would need a feedback buffer and is out of scope.
- **No internal random clock.** Random drops come from an upstream source.

### Open, decided in Phase 0 (gates in `tasks.md`)

- **G1 Envelope mechanism and units.** DECIDED 2026-11-05 (Matt): frames. A per-draw one-pole in the patcher (`env += (gate - env) * k`, `k` from `attack` and `release` in frames, `0` = instant), so no timer and no `line`. Alternative (not taken): `line` in ms (frame-rate dependent).
- **G2 Ink encoding.** Which channels does `f_vf_advect`'s injection source read (RGB, alpha, premultiplied)? Out0 must match.
- **G3 Radial and swirl field definition.** Edge band only (the gradient of a soft mask is non-zero only in the `softness` band) versus a smoothed interior (extra taps or a blur); how magnitude is normalised so it does not depend on `softness`.
- **G4 Gate button as a shared building block.** Extract the `ubutton`, `[sel bang 1 0]` and draw-counter boxes from `f_wave_field`'s `definition.py` into a schema UI type, or copy the raw boxes. DECIDED 2026-11-05 (Matt): extract.
- **G5 Bypass.** DECIDED 2026-11-05 (Matt: "pass the input through"; reading confirmed by Matt the same day): out0 passes in0, out1 passes in1 when connected (else neutral 0.5 / 0.5); the gate and envelope are ignored, so a bypassed stamp hands the whole texture downstream as ink. FR-011's non-finite zap stays active in bypass (Claude's proposal; Matt did not object).
- **G6 Dial set and ranges** (below), subject to `G-ui-density`.
- **G7 Luma weights** the library uses for coverage (confirm against `f_luma_processor` / `f_vf_glow`).
- **G8 Menu category** (held by `G-menu`).

---

## User Stories

### User Story 1 — Stamp ink where a shape is (Priority: P1)

A performer patches a shape texture into in0 and holds Stamp: the ink appears where the shape's luma is above `threshold`, softly edged by `softness`; release and it stops (after the envelope).

**Independent Test**: tier 1 coverage closed forms (mask is 0 below `threshold - softness/2`, 1 above `threshold + softness/2`, smoothstep between; `invert` flips it).

**Acceptance Scenarios**:
1. **Given** a white disc on black and Stamp held, **When** run, **Then** out0 is the disc's RGB where covered and zero elsewhere.
2. **Given** Stamp not held and the envelope at 0, **Then** out0 is zero and out1 is exactly neutral (0.5, 0.5).

### User Story 2 — Stir with a patched vecfield (Priority: P1)

A performer patches a vecfield (`f_vf_vortex`, `f_vf_optical_flow`) into in1. The impulse is that field, gated by the stamp's mask, scaled by `force` and the envelope. Patching it into `f_vf_fluid`'s force inlet stirs along the field only where the stamp is.

**Acceptance Scenarios**:
1. **Given** in1 connected, **Then** out1 = encode((in1 - 0.5) * 2 * mask * env * force), B = 0.5, A = 1.
2. **Given** a field that is non-neutral outside the mask, **Then** out1 is neutral there.

### User Story 3 — Radial or swirl from the stamp itself (Priority: P1)

With nothing on in1, the stamp stirs by itself: a radial push outward from the blot (default) or a swirl around it (`impulse` switch).

**Acceptance Scenarios**:
1. **Given** a disc and `impulse` Radial, **Then** out1 points outward (dot with the radial direction > 0 across the edge band).
2. **Given** `impulse` Swirl, **Then** out1 is the radial field rotated 90 degrees; its divergence is zero within the finite-difference tolerance.
3. **Given** in1 connected, **Then** the `impulse` switch has no effect.

### User Story 4 — Tap and hold (Priority: P1)

A tap is a kick, a hold is a pour. `attack` and `release` (in frames, 0 = instant) shape how fast the envelope rises and falls.

**Acceptance Scenarios**:
1. **Given** a tap, **Then** the gate is seen by at least two rendered frames and out0 / out1 are non-neutral for at least that long.
2. **Given** a press while a release is pending, **Then** the release is cancelled and the gate stays on.

### User Story 5 — Shape the mask (Priority: P2)

`threshold`, `softness`, `invert`, and an irregular edge (`edge` amount with `seed`): a noise-offset threshold that works for any stamp shape.

### User Story 6 — Standard f_ module behaviour (Priority: P3)

`bypass`, `#0_` scoped names, helpfile, menu, README per the library conventions.

---

## Requirements

### Functional Requirements

- **FR-001**: The module MUST be usable with nothing on in1. With nothing on in0 it stamps nothing (out0 black A = 1, out1 neutral): in0 gives the shape, so it is a processor, not a generator.
- **FR-002**: The module MUST be stateless: output is a pure function of in0, in1, the params, the envelope value and the render size. No feedback texture.
- **FR-003**: Coverage MUST be `cov = smoothstep(threshold - softness/2, threshold + softness/2, luma + edge * noise)`, flipped by `invert`, with the library's luma weights (G7) and a deterministic arithmetic hash noise (no `sin()`, as `f_ks`'s seed) seeded by `seed`.
- **FR-004**: out0 MUST be the stamp's ink scaled by `cov`, `amount` and the envelope, in the encoding G2 settles; exactly zero when `cov * env` = 0.
- **FR-005**: With in1 connected, out1 MUST be `encode((in1.rg - 0.5) * 2 * cov * env * force)` per `f_vecfield_type.md` (`v * 0.5 + 0.5`, B = 0.5, A = 1), bounded, and exactly (0.5, 0.5) when `cov * env` = 0. An unconnected in1 MUST be recognised from the connected flag (via `vs_inState`), not from the value: `vs_black` would decode as a full -1 vector (the `f_vf_glow` ADR-2 lesson, `vs_black` suppression before the remap).
- **FR-006**: With in1 unconnected, out1 MUST be the radial impulse (`impulse` Radial) or the swirl (`impulse` Swirl) derived from the gradient of `cov` by central differences, definition per G3, scaled by `force` and the envelope. With in1 connected the switch MUST have no effect.
- **FR-007**: The Stamp control MUST be a held press: `ubutton` mouse-down sends `param stamp_gate 1`, mouse-up starts a release applied on the third draw bang after it; the `stamp` message is a tap, `stamp 1` / `stamp 0` press and release; a new press cancels a pending release. The Param is named `stamp_gate` (`gate` alone is a Gen operator name, as `edge` is). There is no stamp on load.
- **FR-008**: The envelope MUST be computed in the patcher per draw (G1), with `attack` and `release` in frames, `0` meaning instant; the codebox receives `env` as a Param.
- **FR-009**: Both outlets MUST follow the render size (`render_dim` convention) and sample in0 and in1 bilinearly.
- **FR-010**: The gradient MUST use periodic neighbours by explicit texel index math, never an out-of-range `sample()` (the `G-edge-wrap` lesson: out-of-range reads wrap, and an explicit clamp protects only two of four edges), because `f_vf_fluid`'s domain is a torus.
- **FR-011**: No NaN or Inf MAY reach either outlet (non-finite in0 or in1 texels are zapped to 0 / neutral).
- **FR-012**: Bypass MUST use a codebox `bypass_gate` Param (never native `@bypass`); behaviour per G5.
- **FR-013**: Standard behaviour: `#0_`-scoped names, `routepass` / `route` / `autopattr` with `varname`, `definition.py` as the source of truth.

### Non-Functional Requirements

- **NF-001** *(target, pending measurement)*: one `jit.gl.pix` pass; cost recorded at 1080p on the bench; the M1 is unmeasured and flagged (library rule).
- **NF-002**: Float32 end to end for the vecfield; the ink outlet follows G2.
- **NF-003**: Verification follows the constitution's tiers (below).

## Parameters (proposed; final set fixed by G6, trimmed by `G-ui-density`)

| Param | Range | Default | Notes |
|---|---|---|---|
| `threshold` | 0–1 | 0.5 | luma above which the stamp covers |
| `softness` | 0–1 | 0.1 | width of the smoothstep band; 0 = hard edge |
| `invert` | toggle | 0 | stamp where luma is below |
| `edge` | 0–1 | 0 | irregular edge: noise offset on the threshold (internal Param `edge_amt`) |
| `seed` | int | 0 | noise seed |
| `amount` | 0–1 | 1 | ink strength |
| `force` | 0–2 | 1 | impulse strength (the field is in vecfield units) |
| `impulse` | Radial / Swirl | Radial | the in1-empty fallback; inert when in1 is connected |
| `attack` | frames, 0–60 | 0 | envelope rise; 0 = instant |
| `release` | frames, 0–120 | 8 | envelope fall; 0 = instant |
| `stamp` | ubutton / message | | the held press |
| `bypass` | toggle | 0 | |

## Success Criteria

- **SC-001**: Coverage closed forms (the three regions of the smoothstep, `invert`, `softness` 0) match the mirror.
- **SC-002**: Idle exactness: `cov * env` = 0 gives out0 exactly 0 and out1 exactly (0.5, 0.5, 0.5, 1).
- **SC-003**: Linearity: out1 is linear in `force` and in the envelope while unsaturated; out1 = 0 where `cov` = 0.
- **SC-004**: Radial: on a disc, out1 points outward across the edge band; swirl: divergence-free within the finite-difference tolerance, and equal to the radial field rotated 90 degrees; periodic wrap: a disc across the border gives the same field as the same disc moved to the centre, shifted.
- **SC-005**: Gate: a tap is seen for at least two frames; a press cancels a pending release (offline check of the patcher logic plus the live module contract bench).
- **SC-006**: Tier-3 look (Matt): a held stamp into `f_vf_advect` plus `f_vf_fluid` reads as ink dropped and stirred; Radial versus Swirl at `project` 1 behaves as predicted (swirl stirs, radial does not).

## Edge Cases

- `softness` 0 (a hard mask): the gradient is one texel wide; the radial field aliases (G3).
- A stamp smaller than a few texels; `threshold` at 0 or 1; `invert` on a full-white texture.
- in1 non-neutral outside the mask (masked off); in1 with non-finite texels.
- Render size changes at runtime; non-square render targets (the gradient steps are per-texel in each axis).
- A press held while the source texture moves (a trail; no latch).
- `attack` 0 and `release` 0: a one-frame hard edge on a tap, still two frames of gate by FR-007.

## Out of Scope (This Version)

- Generating blots, discs, satellites or dipole profiles (upstream sources do that).
- Held slots (the module holds N stamps itself) and a latch of the stamp at the press.
- An internal random clock.
- Subtractive (watercolour) ink mixing; that is a consumer's treatment (`ideas/f_vf_stamp.md`, open).
- Making the radial impulse survive `f_vf_fluid`'s `project`: that is what the swirl switch is for.
