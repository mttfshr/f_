# Spec: f_screen

_Created: 2026-11-08_
_Status: Draft: not yet built, not yet clarified_
_Origin: `ideas/f_print_styles.md` (stage 2 of the print-styles family, "tone to mark"). Name `f_screen` is a placeholder: `screen` collides in meaning with `ideas/circular_screen.md`, so `f_halftone` is the alternative (gate G10)._

---

## Clarifications

### Resolved with Matt (2026-11-07 / 2026-11-08, in chat)

- **A vocabulary, not a goal** (as for `f_ink`): the screen is one composable operator that can reproduce a print look as a recipe and can also be bent into results that look unmistakably digital.
- **Plain `f_` name** (no family prefix). Plates are RGB channels, up to three; alpha is not a plate. A reversed channel comes from Vsynth's invert module.
- **Halftoning in general.** No riso-specific halftone work (Matt, 2026-11-08).
- **Fixed-angle screens only** (tentative: "a decision but I'm not sure it's the decision"). Marks that follow the image's form (stretched dots, hatching, engraving) belong to the tensor family and the later `f_engrave`, not here.
- **Dithering is one operation.** A halftone is a comparison of tone against a threshold field; ordered dither is the same comparison with a different field. `f_screen` is the threshold-field stage, with a soft compare.
- **`f_screen` and `ideas/f_dither_grain.md` stay separate for now** (Matt: "maybe", the question is open). They share only the cell vocabulary.
- **Print-faithful output.** Dot gain, mottle, dropout and the rest of the ink's behaviour belong to `f_ink`, which follows `f_screen` in a chain.

### Preliminary decisions taken by Claude (Matt, 2026-11-08: "proceed and accept your own recommendations for preliminary gates")

These are not Matt's calls. They are Claude's recommendations, accepted in place so the spec can proceed, and each is open to Matt's reversal.

- **P1 Per-cell tone sampling for dots.** A dot's size comes from one tone value per cell, sampled at the cell centre, so dots are regular and uniform within a cell (gate G4). Per-pixel comparison, where tone varies inside a cell and distorts the dot, is not the default.
- **P2 Line screen samples along the line.** Line width comes from the tone at the nearest point on the line's centre.
- **P3 Area coverage equals tone.** On a flat patch, the fraction of the area inked equals the tone (exactly at 0 and at 1).
- **P4 Rotation about the frame centre.** The lattice is fixed to the frame, never to the image, so an animated input moves under a static screen.
- **P5 One shared pitch** for all three plates; the angle is per plate.
- **P6 Default angles 15, 75 and 45 degrees** for R, G and B (inferred from the offset convention, which separates screens by 30 degrees or more to limit moiré; not tested).
- **P7 Output is bounded to 0..1** by construction (coverage), with input above 1 saturating to full and below 0 giving none. This differs from `f_ink` (unclamped) because a mark is either there or not.
- **P8 No driver inlets in v1** (G12).
- **P9 Stochastic (FM) stipple is out of scope.** `f_stipple` is a hash-field stipple (its doc, read 2026-11-08), and it reads only the red channel.
- **P10 Units are frame-relative,** as for `f_ink` (A4 there; gate G2).
- **P11 Polarity as in `f_ink`:** high channel value = more ink.
- **P12 Bypass** passes the source through.

### Open, decided in Phase 0 (gates; to be carried into `tasks.md`)

- **G1 Verification tiers.** The first Phase 0 task (constitution). Proposal: tier 1 (NumPy mirror: closed forms on flat patches and ramps), tier 2 (bench of the real codebox), tier 3 live.
- **G2 Units.** Frame widths or frame heights for `pitch`; shared with `f_ink` G2.
- **G3 Spot functions.** The threshold field for each type (round dot, line) must be area-preserving (P3): the fraction of a cell below threshold t equals t. A round dot's radius is not linear in tone, and a dot at tone above one half has to merge into its neighbours. Settle the functions and test the area law on the mirror.
- **G4 Per-cell versus per-pixel tone sampling.** Preliminary P1. Open details: a single centre tap versus a small average over the cell (taps are limited to about 16 reads per stage), and what the cell-boundary staircase looks like on a smooth ramp.
- **G5 Smallest usable pitch and antialiasing.** The pitch (in texels) below which the screen aliases or the dot area stops tracking tone, and the edge ramp width in texels.
- **G6 Lattice origin and rotation.** Preliminary P4 (frame centre); check that 0, 45 and 90 degrees are exact and that rotation about the centre keeps the grid stable on non-square frames.
- **G7 Jitter.** How much displacement keeps neighbouring marks from overlapping, and whether the displacement adds statements within the budget (about 250 per function body, about 450 per program; `skills/jit-gen-codebox/SKILL.md`).
- **G8 `sample()` behaviour.** `ideas/f_deflicker.md` (2026-10-25) says a bilinear tap on a texel corner returned one texel; settle on the bench, shared with `f_ink` G4. The screen's own pattern needs no sampling (it is analytic), only the tone read.
- **G9 Linear-light versus encoded tone.** Deferred (Matt, for `f_ink`; the same call applies here). It changes how a mid-tone maps to dot area.
- **G10 Name and menu.** `f_screen` or `f_halftone`; menu category under `G-menu`.
- **G11 Control set.** Pitch, three angles, type, shape, softness, jitter, level, seed: about ten dials plus the type menu (`G-ui-density`).
- **G12 Drivers.** Preliminary P8: none. A later optional modulation inlet (pitch or size by a texture) is possible and would be a new version.
- **G13 Naming alignment.** `softness`, `jitter`, `shape`, `angle` follow `docs/f-reference/discrete_item_conventions.md` (not opened this session); check that the names mean the same here.

- **Plates from `f_separate`, and the plate toggle (Matt, 2026-11-08):** `f_separate` outputs three textures, each carrying one spot colour as its RGB channels; this module operates on the RGB channels of each of those textures. Because a real spot-colour screen is ONE screen, a `plate` toggle chooses how a texture is read: **Channels** (the spec as written: R, G and B are separate plates, each with its own angle) or **Single** (the whole texture is one plate with one angle: the tone is the brightest channel, `t = max(r, g, b)`; the colour is normalised to full brightness, `rgb / t`; the output is that colour times the mark, so a teal plate gets one set of teal dots and its two non-zero channels are not split). Matt chose the brightest-channel tone with normalised colour over keeping the plate's original brightness (which would cap the dot area): a dimmer plate colour is restored with a gain downstream. Black (`t` near 0) gives black. Alpha passes through. Default: Channels (a full-colour texture), Single for spot-colour plates. Details (which angle param Single reads, default) are gate G-plate in `tasks.md`.

---

## User Stories

### User Story 1: Dot screen (Priority: P1)

A performer patches a tone texture (one to three plates in R, G and B) into f_screen and gets a halftone: a regular lattice of dots at an angle, each dot sized by the tone in its cell, so dark areas have large dots and light areas small ones.

**Why this priority**: the core of stage 2, and the base for the riso and offset recipes.

**Independent Test**: tier 1 on flat patches and a ramp: the mean coverage of the output equals the tone, and dot area grows monotonically along the ramp.

**Acceptance Scenarios**:
1. **Given** a flat patch of tone 0.5 and `screen` Dot, **Then** about half of the area is inked and the marks lie on a lattice of the given pitch at the given angle.
2. **Given** tone 0, **Then** the output is exactly 0; **given** tone 1 or more, **Then** the output is exactly 1 everywhere.
3. **Given** a ramp from 0 to 1, **Then** the dots grow along the ramp, merge near 0.5 and leave only small gaps near 1.
4. **Given** the same input and params on two frames, **Then** the output is identical (the screen is fixed to the frame).

### User Story 2: Per-plate angles (Priority: P1)

Each of the three channels has its own angle. Overprinting plates at different angles gives the rosette and moiré patterns of multi-plate print, and equal angles give dots that stack.

**Independent Test**: tier 1 on a flat patch with the same tone in all three channels: each channel's lattice has the orientation of its own angle.

**Acceptance Scenarios**:
1. **Given** angles 15, 75 and 45 and equal flat tones, **Then** the three output lattices have those orientations.
2. **Given** one channel's angle changed, **Then** the other two channels' outputs are unchanged.

### User Story 3: Line screen (Priority: P1)

The same tone controls the width of parallel lines at an angle: a line screen, as in engraving-like prints and newspaper line cuts.

**Independent Test**: tier 1 on a flat patch: the line width equals the tone times the pitch and the lines lie at the given angle.

**Acceptance Scenarios**:
1. **Given** flat tone 0.3, **Then** the lines cover about 30 percent of the area.
2. **Given** tone 1, **Then** the lines merge into a solid.
3. **Given** a ramp, **Then** the lines thicken along the ramp.

### User Story 4: Pitch in frame units (Priority: P1)

`pitch` sets the lattice period in frame units, so the same look appears at any render size.

**Acceptance Scenarios**:
1. **Given** a render size change, **Then** the number of dots across the frame is unchanged.
2. **Given** a non-square frame, **Then** the dots are square-spaced (not stretched).

### User Story 5: Softness and shape (Priority: P2)

`softness` widens the edge ramp (a softer, rounder dot, and antialiasing); `shape` morphs the dot between round, square and diamond.

**Acceptance Scenarios**:
1. **Given** `softness` raised, **Then** the edge between ink and no ink widens and the area law (P3) still holds within tolerance.
2. **Given** `shape` at its extremes, **Then** the dot is round or square at the same area.

### User Story 6: Jitter (Priority: P2)

`jitter` moves from a regular lattice (0) to hash-displaced marks (1), from a screen toward a random look, with the same tone-to-area law.

**Acceptance Scenarios**:
1. **Given** jitter 0, **Then** the lattice is exactly regular.
2. **Given** jitter 1, **Then** no two marks overlap more than the cell allows, and the mean coverage still equals the tone.

### User Story 7: Threshold and Bayer types (Priority: P2)

A `Threshold` type (a hard or soft cut at a level, the linocut and xerox base) and a `Bayer` type (ordered dither at pixel scale).

**Acceptance Scenarios**:
1. **Given** `Threshold` and a `level`, **Then** output is 1 where the tone is above it (softly edged by `softness`) and 0 elsewhere.
2. **Given** `Bayer` and a flat tone, **Then** the fraction of lit texels equals the tone to within the matrix's resolution.

### User Story 8: Standard f_ module behaviour (Priority: P3)

`bypass`, `#0_` scoped names, helpfile, menu entry, README row.

---

## Requirements

### Functional Requirements

- **FR-001**: The module MUST be a processor: in0 is a texture, and each channel is processed independently as one plate's tone. With nothing connected it outputs black.
- **FR-002**: The module MUST be stateless: the output is a pure function of in0, the params, the seed and the render size. No feedback texture.
- **FR-003**: For the Dot and Line types, the fraction of area inked on a flat patch of tone `t` in 0..1 MUST equal `t` (P3, G3), within a tolerance fixed by the mirror.
- **FR-004**: Tone 0 or below MUST give output exactly 0, and tone 1 or above MUST give exactly 1, for every type.
- **FR-005**: The lattice MUST have period `pitch` in frame units and the orientation of the channel's own angle, rotating about the frame centre (P4), and MUST be fixed to the frame.
- **FR-006**: The Dot type MUST take its tone from one sample per cell (P1, G4), so every dot in a cell is the same size and a smooth ramp gives a stepped sequence of dot sizes.
- **FR-007**: The Line type MUST take its tone from the nearest point on the line's centre (P2), so a line's width is constant across the line's local cell.
- **FR-008**: `softness` MUST set the width of the edge ramp between ink and no ink; at the smallest value the edge is as sharp as the antialiasing (G5) allows.
- **FR-009**: `jitter` 0 MUST give an exactly regular lattice; larger values displace each cell's mark deterministically from `seed`.
- **FR-010**: The Threshold type MUST compare the tone at each pixel with `level` (softly, by `softness`); the Bayer type MUST compare it with an ordered matrix at pixel scale.
- **FR-011**: The output MUST be float32 and bounded to 0..1 (P7); no NaN or Inf MAY reach an outlet (non-finite input texels are zapped to 0).
- **FR-012**: Every length MUST follow the render size (`render_dim` convention) and be correct for non-square frames.
- **FR-013**: Alpha MUST pass through from the source.
- **FR-014**: Bypass MUST use a codebox `bypass_gate` Param (never native `@bypass`) and pass the source through (P12).
- **FR-015**: Standard behaviour: `#0_`-scoped names, `routepass` / `route` / `autopattr` with `varname`, `definition.py` as the source of truth.

### Non-Functional Requirements

- **NF-001** *(target, pending measurement)*: cost recorded at 1080p on the bench, stated as measured or unmeasured (library rule).
- **NF-002**: The codebox MUST fit the statement budget (G7); repeated code goes in functions.
- **NF-003**: Verification follows the constitution's tiers (G1).

## Parameters (provisional; tuned live at tier 3)

| Param | Range | Default | Notes |
|---|---|---|---|
| `screen` | Dot / Line / Threshold / Bayer | Dot | Threshold and Bayer are P2 |
| `pitch` | frame units | 0.012 | lattice period; the smallest usable value is G5 |
| `angle_r`, `angle_g`, `angle_b` | degrees | 15, 75, 45 | per plate (P6) |
| `softness` | 0-1 | 0.1 | edge ramp width |
| `shape` | 0-1 | 0 | round to square (P2) |
| `jitter` | 0-1 | 0 | regular to hash-displaced (P2) |
| `level` | 0-1 | 0.5 | Threshold type only |
| `seed` | int | 1 | for jitter |
| `plate` | Channels / Single | Channels | how the texture is read; Single is one plate (tone = brightest channel, colour normalised); reads `angle_r` as its one angle (name decided in Phase 0) |
| `bypass` | toggle | 0 | passthrough |

## Success Criteria

- **SC-001**: Area law: on flat patches at several tones, the mean output equals the tone within the mirror's tolerance, for Dot and Line, at several pitches and angles.
- **SC-002**: Extremes: tone 0 gives exactly 0 and tone 1 exactly 1, for every type.
- **SC-003**: Monotone: along a 0-to-1 ramp the local inked area never decreases.
- **SC-004**: Lattice: the output's autocorrelation shows the period `pitch` along the channel's angle; plates with different angles show their own orientations.
- **SC-005**: Plate independence: changing one channel's angle or tone leaves the other channels' outputs unchanged.
- **SC-006**: Stability: two frames of the same input are bit-identical; a render-size change scales the lattice with the frame.
- **SC-007**: Jitter: at 0 the lattice is exact; at 1 the mean coverage still equals the tone.
- **SC-008**: Tier-3 look (Matt): a photo through three plates at 15, 75 and 45 degrees reads as a halftone print with the expected rosette and no unintended moiré; followed by `f_ink` it reads as ink on paper; one deliberately bent use (a very coarse screen, odd angles, or a line screen on a simulation) reads as intentionally digital.

## Edge Cases

- Tone above 1, below 0, or non-finite.
- `pitch` near a texel (aliasing, moiré) and at its maximum (a few cells across the frame).
- Marks smaller than a texel (tone near 0): do they vanish, flicker or stay as partial coverage? (G5)
- Angles 0, 45 and 90 (lines or dots exactly on the pixel grid).
- `jitter` 1 with neighbouring marks that would overlap.
- Non-square frames and a render size that changes at runtime.
- A smooth ramp across cell boundaries (the staircase of per-cell dot sizes).
- Equal angles on two plates (dots stack) versus 90-degree differences.
- Alpha is not a plate and passes through.

## Out of Scope (This Version)

- Marks that follow the image's form: stretched dots, hatching, engraving (`f_engrave`, the tensor family).
- Stochastic (FM) stipple (`f_stipple`) and error diffusion (sequential; a blue-noise threshold is the stand-in).
- Image-to-plate separation (`f_separate`).
- Ink behaviour: dot gain, mottle, dropout, edge pooling (`f_ink`); misregistration (`f_misregister`); colour and overprint (`f_paper`).
- A fourth (CMYK black) plate.
- Riso-specific halftone options.
- Driver inlets (G12); drivers can be added in a later version.
