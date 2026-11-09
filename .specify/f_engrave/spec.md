# Spec: f_engrave

_Created: 2026-11-08_
_Status: Draft: not yet built, not yet clarified. **The method is not chosen:** Phase 0 is a spike that decides whether this module can be built (gate G2)._
_Origin: `ideas/f_print_styles.md` (stage 2, the form-following line module for intaglio and engraving looks). Name `f_engrave` is a placeholder (plain `f_`, no family prefix: Matt, 2026-11-07)._

---

## Clarifications

### Resolved with Matt (2026-11-07 / 2026-11-08, in chat)

- **A vocabulary, not a goal** (as for `f_ink`): engraving-style line work is one operator in the print vocabulary, usable for a faithful intaglio look and equally for results that look unmistakably digital.
- **Lines follow the image's form,** which means the tensor family (`f_tf_*`) supplies the direction. Intaglio is a later phase than riso.
- **Separate from `f_tf_hatch`.** This is its own module and does not evolve hatch. Hatch is stable and stays as it is; it may later pick up some of this module's flexibility (Matt, 2026-11-08).
- **The method is a Phase 0 gate** (Matt, 2026-11-08): the three candidates are tried in a scratch spike and chosen by looking and by the criteria below, not by reasoning in advance.
- **Plates are RGB channels, up to three;** alpha is not a plate. Each plate carries one ink's tone.
- **Fixed-angle screens belong to `f_screen`.** Marks that follow the image's form belong here (the tentative decision in the idea file).
- **Dot-stretching is not this module's job;** the continuous, evenly spaced line field is.

### Preliminary decisions taken by Claude (Matt, 2026-11-08: "accept your own recommendations for preliminary gates")

These are Claude's recommendations accepted in place so the spec can proceed; none is a Matt decision, and each is open to his reversal.

- **P1 Two inputs.** in0 is the raw structure tensor (`f_tf_tensormap` outlet 0 encoding, `docs/f-reference/f_tensor_type.md`, as `f_tf_hatch` takes it); a packed feed is a wiring error. in1 is the tone plates (a texture, one ink per channel). With either unconnected the output is black.
- **P2 Raw tensor, not a vecfield.** Lines are unoriented (an axis, not an arrow), so the sign-free raw tensor is the input, not the vecfield from `f_tf_axisflow`.
- **P3 One outlet:** the line plates, same channel layout as in1.
- **P4 Crosshatch by plates.** Each plate has its own angle offset relative to the structure axis, and tone-gated crosshatch is made by feeding a second plate whose tone is only the shadows (shaped upstream with `f_tone_curve`). No tone gating inside the module.
- **P5 Shared pitch** for all plates; angle offset per plate.
- **P6 Direction smoothing is upstream** (`f_tf_smooth`, `f_tf_aniso_blur`); the module uses the tensor as given.
- **P7 Low-coherence fallback:** where the tensor has no usable direction, lines take a fixed `fallback_angle`, blended over a coherence ramp (as `f_tf_hatch`'s Coh Floor idea), so shadows without structure still get tone.
- **P8 Area law:** on a region of constant tone and direction, the fraction inked equals the tone (as for `f_screen`).
- **P9 Width from the tone at the line's centre,** so a line's width is set at the line, not per pixel (as `f_screen` P2).
- **P10 Output bounded 0..1,** and frame-relative units (gate G3).
- **P11 Stateless is preferred;** a stateful method needs a stated reason (G4).
- **P12 Bypass** passes the tone plates (in1) through.

### Open, decided in Phase 0 (gates; to be carried into `tasks.md`)

- **G1 Verification tiers.** The first Phase 0 task. Proposal: tier 1 mirrors the geometry criteria (SC-001 to SC-005) in NumPy; tier 2 benches the real codebox; tier 3 live. A scratch spike comes before any of it (G2).
- **G2 Line-field method.** The module's core and the unsolved problem: evenly spaced, coherent parallel lines whose phase is continuous along a direction field (the phase must be integrated, and it breaks at singularities). Candidates, none tried: (a) LIC over a line-pattern seed; (b) a line pattern warped by a smoothed luma field, so the lines are iso-lines of tone; (c) lines spaced by distance to the previous line; the plan (`plan.md` ADR-3) adds two more for the spike, a global phase solve on a coarse grid and oriented Gabor or phasor-style kernels. **Stop rule:** if no candidate meets SC-001 to SC-004 in the spike, the module is not built and the spec is parked with the result recorded.
- **G3 Units.** Frame widths or frame heights for `pitch`; shared with `f_ink` and `f_screen`.
- **G4 State.** Whether the chosen method needs frame-to-frame state (for example an integrated phase). A stateless method is preferred (P11); a stateful one changes the bench and the bypass behaviour.
- **G5 Singularity policy.** What the lines do at degenerate points of the field (knots, wedges, swirls, which `f_tf_hatch` shows as topology): converge, fade, or leave a gap. Measure the spacing distortion around them.
- **G6 Fallback blend.** The coherence ramp and `fallback_angle` of P7, and the visible seam where direction switches.
- **G7 Tone to width.** The mapping near 0 (hairlines, lines thinner than a texel) and near 1 (merge into a solid), and whether a line ends or only thins in highlights.
- **G8 Per-line versus per-pixel tone.** Preliminary P9. Which taps and how many (about 16 reads per stage; `ideas/f_deflicker.md`).
- **G9 `sample()` behaviour.** Shared with `f_ink` G4 and `f_screen` G8.
- **G10 Codebox budget and cost.** About 250 statements per function and about 450 per program (`skills/jit-gen-codebox/SKILL.md`); a long march is the likely cost. For scale, `f_tf_hatch`'s reference doc gives its streamline stage as about 5 to 12 ms (hardware not stated); this module's cost is unmeasured.
- **G11 Linear-light versus encoded tone.** Deferred (Matt), as for `f_ink`.
- **G12 Code sharing with `f_tf_hatch`.** The tensor decode is reusable; whether code can be shared between modules in this build system is unverified.
- **G13 Name, menu and panel.** Menu category under `G-menu`; the control set under `G-ui-density`; this module is a new tensor consumer (`G-tensor-t3` does not change).

### Open gate added 2026-11-08: coloured plates from `f_separate` (needs Matt's call)

Matt decided that `f_separate` gives each plate its own outlet as a coloured texture (`coverage * ink colour`), because one RGB channel cannot carry a spot colour such as teal. This spec was written assuming plates are the R, G and B channels of one texture. Options: as for `f_screen` (one instance per coloured plate on its brightness, or keep channel mode). `offset_r/g/b` would become one `offset` per instance. Not decided; the P-list items here that mention R, G and B stay as written until it is.

---

## User Stories

### User Story 1: Form-following lines of regular pitch (Priority: P1)

A performer patches a tensor and a tone texture and gets parallel lines that follow the image's contours at a regular spacing, with each line's width set by the tone: thin in highlights, thick in shadows.

**Why this priority**: the module's reason to exist. If this cannot be done, nothing else here matters (G2 stop rule).

**Independent Test**: tier 1 on synthetic tensors with known directions (a uniform axis, a circular field around a point, a smooth bend) and flat or ramped tone.

**Acceptance Scenarios**:
1. **Given** a uniform tensor axis at angle a and flat tone, **Then** the output is parallel lines at angle a with spacing `pitch`.
2. **Given** a circular field around a point, **Then** the lines are concentric rings with spacing `pitch` away from the centre.
3. **Given** a tone ramp 0 to 1, **Then** line width grows monotonically along the ramp, and the inked area fraction equals the tone.
4. **Given** tone 0, **Then** the output is exactly 0; **given** tone 1, **Then** the lines merge into a solid of exactly 1.

### User Story 2: Lines are even and continuous (Priority: P1)

The lines do not break into strokes, wander off the field, or bunch and gap, except where the field itself has a singularity.

**Independent Test**: tier 1 metrics on a smooth synthetic field (below).

**Acceptance Scenarios**:
1. **Given** a smooth field with high coherence, **Then** the spacing between neighbouring lines varies by less than the SC-002 limit.
2. **Given** the same field, **Then** the angle between the drawn lines and the tensor axis is below the SC-003 limit.
3. **Given** a long line crossing the frame, **Then** it is continuous (SC-004).

### User Story 3: Stable under motion (Priority: P1)

When the input moves or changes slightly, the lines move slightly with it; they do not swim, crawl or reshuffle.

**Independent Test**: tier 1/2 on a small perturbation of the tensor (and of the tone): the change in the output is bounded by SC-005.

**Acceptance Scenarios**:
1. **Given** the same input on two frames, **Then** the output is identical.
2. **Given** a small shift of the tensor field, **Then** the lines shift by about the same amount and the pattern does not re-phase elsewhere.

### User Story 4: Pitch in frame units and per-plate angles (Priority: P1)

`pitch` sets the line spacing in frame units, so the look holds at any render size. Each plate has an angle offset from the structure axis, so two plates at 0 and 90 degrees cross.

**Acceptance Scenarios**:
1. **Given** a render size change, **Then** the number of lines across the frame is unchanged.
2. **Given** plate R at offset 0 and plate G at offset 90, **Then** their lines cross at right angles everywhere the field is coherent.
3. **Given** one plate's offset changed, **Then** the other plates are unchanged.

### User Story 5: Weak structure falls back gracefully (Priority: P2)

Where the tensor has no usable direction, the lines take the fixed `fallback_angle` so the tone is still drawn; a `coh_floor` dial sets where this begins.

**Acceptance Scenarios**:
1. **Given** a zero or isotropic tensor, **Then** the lines are straight at `fallback_angle` with the correct width.
2. **Given** a coherence ramp, **Then** the direction blends from the field to the fallback without a hard seam (G6).

### User Story 6: Line character (Priority: P2)

Controls for the character of the line: `softness` of the edge, a `min_width` hairline floor, and an `ends` behaviour (lines thin out or end in highlights).

### User Story 7: Standard f_ module behaviour (Priority: P3)

`bypass`, `#0_` scoped names, helpfile, menu entry, README row.

---

## Requirements

### Functional Requirements

- **FR-001**: The module MUST be a processor with two inputs (P1): the raw tensor on in0 and the tone plates on in1. With either unconnected it outputs black. A packed tensor feed is a wiring error, documented as for `f_tf_hatch`.
- **FR-002**: Each channel of in1 MUST be drawn as its own plate of lines, independently of the other channels (P4, P5).
- **FR-003**: Lines MUST follow the axis decoded from the tensor, offset by the plate's angle (User Story 4), and MUST have spacing `pitch` in frame units (P10).
- **FR-004**: Line width MUST be set by the tone at the line's centre (P9, G8) so that on constant tone and direction the inked fraction equals the tone (P8); tone 0 or below gives exactly 0 and tone 1 or above gives exactly 1.
- **FR-005**: The lines MUST meet the geometric criteria SC-001 to SC-004 on smooth synthetic fields, or the module is not built (G2 stop rule).
- **FR-006**: The output MUST be stable under small input changes (SC-005) and identical on identical input.
- **FR-007**: Where coherence is low, the direction MUST blend to `fallback_angle` (P7, G6); a zero tensor MUST NOT produce an arbitrary angle or NaN (the `f_tf_hatch` guard `eps_trace`, read in its reference doc, is the model).
- **FR-008**: The output MUST be float32 and bounded to 0..1; no NaN or Inf MAY reach the outlet (non-finite input texels are zapped).
- **FR-009**: Every length MUST follow the render size (`render_dim` convention) and be correct for non-square frames.
- **FR-010**: Alpha MUST pass through from the tone texture.
- **FR-011**: Bypass MUST use a codebox `bypass_gate` Param (never native `@bypass`) and pass in1 through (P12).
- **FR-012**: Standard behaviour: `#0_`-scoped names, `routepass` / `route` / `autopattr` with `varname`, `definition.py` as the source of truth. An unconnected input MUST be recognised from the connected flag (via `vs_inState`), not from its value.

### Non-Functional Requirements

- **NF-001** *(target, pending measurement)*: cost at 1080p recorded on the bench, stated as measured or unmeasured, against `f_tf_hatch` as the scale (G10).
- **NF-002**: The codebox MUST fit the statement budget (G10); repeated code goes in functions.
- **NF-003**: Verification follows the constitution's tiers (G1), with the Phase 0 spike first (G2).

## Parameters (provisional; the method may add or remove some)

| Param | Range | Default | Notes |
|---|---|---|---|
| `pitch` | frame units | 0.012 | line spacing (smallest usable value is part of G2) |
| `offset_r`, `offset_g`, `offset_b` | degrees | 0, 90, 45 | angle from the structure axis, per plate |
| `fallback_angle` | degrees | 45 | where there is no direction |
| `coh_floor` | 0-1 | 0.1 | coherence below which the fallback blends in |
| `softness` | 0-1 | 0.1 | edge ramp width |
| `min_width` | 0-1 | 0 | hairline floor (P2 story) |
| `bypass` | toggle | 0 | in1 passthrough |

## Success Criteria

Numeric limits marked `[set in Phase 0]` are fixed from the spike's measurements, not guessed here.

- **SC-001**: Area law and extremes: on constant tone and a uniform axis, the inked fraction equals the tone within `[set in Phase 0]`; tone 0 gives exactly 0 and tone 1 exactly 1.
- **SC-002**: Spacing: on a smooth high-coherence field, the coefficient of variation of the spacing between neighbouring lines is below `[set in Phase 0]`.
- **SC-003**: Alignment: the mean angle between the drawn lines and the tensor axis in high-coherence regions is below `[set in Phase 0]` degrees.
- **SC-004**: Continuity: a line crossing the frame in a smooth field has no break longer than `[set in Phase 0]` pitches.
- **SC-005**: Stability: for a small perturbation of the tensor, the mean absolute change of the output is below `[set in Phase 0]` of what the same perturbation would cause by re-phasing; identical input gives identical output.
- **SC-006**: Plate independence: changing one plate's offset or tone leaves the others unchanged.
- **SC-007**: Render-size scaling: the line count across the frame is unchanged by a render-size change.
- **SC-008**: Tier-3 look (Matt): a photo through `f_tf_tensormap`, smoothing, and `f_engrave` reads as an engraving, with crosshatch from a second plate, and followed by `f_ink` and `f_paper` it reads as an intaglio print; one bent use (lines on a simulation, or lines whose pitch is very coarse) reads as intentionally digital.

## Edge Cases

- A zero, isotropic or noisy tensor; coherence changing rapidly across a small area.
- Singularities (knots, wedges, swirls) and their neighbourhood (G5).
- Field directions that make lines converge to a point, spiral, or leave the frame.
- Tone above 1, below 0 or non-finite; tone changing abruptly across a line.
- Pitch near a texel (aliasing) and at its maximum.
- Lines thinner than a texel (hairlines) and lines wider than the pitch (merging).
- A render size change at runtime; non-square frames.
- Two plates with equal offsets (lines stack) and with offsets that make them tangent.
- The frame border: lines entering and leaving.

## Out of Scope (This Version)

- Fixed-angle screens and dots (`f_screen`).
- Image-to-plate separation (`f_separate`) and the tensor itself (`f_tf_tensormap`, smoothing).
- Ink body (`f_ink`), misregistration, paper and emboss (`f_paper`).
- Tone-gated crosshatch inside the module (P4: made with plates).
- Guilloche and other designed ornament patterns.
- Evolving `f_tf_hatch`.
