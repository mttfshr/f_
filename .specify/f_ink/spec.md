# Spec: f_ink

_Created: 2026-11-08_
_Status: narrowed 2026-11-09 (see "Narrowed"); built and benched, looks in progress_
_Origin: `ideas/f_print_styles.md` (stage 3 of the print-styles family, "ink body"). Name `f_ink` is a placeholder (plain `f_`, no family prefix: Matt, 2026-11-07)._

---

## Narrowed (Matt, 2026-11-09, after two live looks)

**This section supersedes the rest of this spec wherever they differ.** Matt: mottle, dropout and their field inlets belong to blends elsewhere; "maybe we should be trying to hone how edge pool works".

f_ink is ink that moves along a vecfield. It takes a texture (in0) and a vecfield (in1, `f_vecfield_type.md`), per channel, stateless, unclamped float32.
- **N-001 Extent:** one step of mass transport along the field. Ink piles up where the flow runs into a slope and starves where it leaves one; a converging field gathers ink. The total of ink over the frame is conserved to within 2% on a test bump.
- **N-002 Bulge:** only the outlines move along the field, weighted by the local slope, so flat areas hold still.
- **N-003 Travel:** how far, for both; replaces Spread (folded in, Matt).
- **N-004:** with no field connected, or with Extent and Bulge at 0, the output is exactly the input. Detected from the connected flag.
- **N-005:** both effects read the slope of the tone, so they work on smooth images with no hard marks.
- **Kept from below:** FR-010 (unclamped, no NaN), FR-011, FR-012, FR-013, FR-015, A1-A4, A6.
- **Removed:** spread, snap, bias, soften (FR-004), edge_pool / pool_width (FR-007), mottle (FR-005), dropout (FR-006), FR-017, the amount driver of FR-014. Flecks, banding and channel gains (US5, US6, FR-016) are not built and are not in this version.

## Clarifications

### Resolved with Matt (2026-11-07 / 2026-11-08, in chat)

- **A vocabulary, not a goal.** The physical behaviours of ink on paper (spread, mottle, dropout, edge pooling, flecks, banding) are a vocabulary to be simulated and then bent: the same operators must be usable for results that look unmistakably digital, driven by the rest of Vsynth. Authentic print emulation is one use, not the measure of success.
- **Any texture in, texture out.** No ink colour, no paper, no plate assumption (those belong to the later `f_paper` and to `f_separate`). Plates are RGB channels, up to three; alpha is not a plate and is not essential (Matt). Vsynth's invert module reverses a channel if needed.
- **Physical names, ranges may exceed physics.** Dials are named for the behaviour; ranges may go past what ink does (for example per-channel rates so R, G and B spread differently).
- **Effects wanted:** all of spread (dot gain), mottle, dropout, edge pooling, flecks and banding, with mottle, dropout and edge pooling the priority.
- **Static first.** Bleed or wicking over time (a feedback build) is interesting but second, and out of scope here.
- **Drivers from anywhere.** The pattern or direction that drives an effect may come from the rest of Vsynth (a texture, a vecfield, a simulation, audio through an upstream texture), not only from the module's own internal patterns.
- **Fixed order of effects** (clarify Q1, Matt, 2026-11-08: "Yes, fixed order"): spread, edge pooling, mottle, dropout, flecks, banding (FR-008). The order is not user-changeable.
- **Linear-light versus display-encoded values:** undecided, to be settled when the spread and threshold are first looked at (Matt: "figure that out when we get there"). Gate G9.

### Clarify session 2026-11-08

- Q1: Fixed or changeable effect order? → A: Fixed (FR-008).
- Q5: How do per-channel rates work? → A: Three channel gains `gain_r`, `gain_g`, `gain_b` (0-2, default 1), each scaling every effect amount for that channel (FR-016). Not spread-only, and not a full dial set per channel.
- Q4: How does f_ink take outside drivers? → A: Two dedicated optional inlets (FR-014): in1 a texture whose luma scales the effect amounts by position, in2 a vecfield that sets the spread direction. Tagged textures are not used (`P-mod-textures`: tags suit many named targets, a dedicated inlet one role-defining signal).
- Q3: Mottle, tooth, flecks and bands fixed to the frame or to the image? → A: Fixed to the frame only, no switch (FR-009). An animated input moves under a static paper; an image-locked effect, if wanted, comes from a driver input.
- Q2: Clamp the output to 0..1? → A: No, unclamped float32 (FR-010). Edge pooling and bent uses may exceed 1; a downstream module clamps if wanted. A clamp switch can be added later.
- First live look (Matt, 2026-11-09): edge pool too subtle, so candidate C (the rim stays full, the body thins, about a 12-texel rim). Mottle and dropout read an incoming texture for their field, one inlet each (FR-017). Mock-ups: `scratch/experiments/f_ink_look/` (local).
- Tone through spread (Matt, 2026-11-08, after the mirror showed the re-threshold posterizing continuous tone): a separate dial, `snap` (FR-004).

### Assumed by Claude, accepted for now by Matt, 2026-11-08 (T015; nothing tried in Max)

- A1 **Polarity:** channel value is ink coverage, high = more ink. A black-on-white image is inverted upstream.
- A2 **Per channel:** each channel is processed independently, with no mixing between channels.
- A3 **Stateless:** output is a pure function of the inputs, the params and the render size; no feedback texture.
- A4 **Frame-relative units** for every length (spread radius, mottle scale, tooth size), so the look survives a render-size change.
- A6 **Identity at zero:** with every amount at 0 the output equals the input exactly.

### Open, decided in Phase 0 (gates; to be carried into `tasks.md`)

- **G1 Verification tiers.** Which tiers apply (constitution: the first Phase 0 task). Proposal: tier 1 (NumPy mirror) for the effects, which have closed forms on test shapes; tier 2 (bench) for the real codebox; tier 3 live.
- **G2 Units.** Confirm A4 and the exact unit (frame widths, as `f_vf_stamp`'s `rim`, or frame heights).
- **G3 (resolved, clarify Q3).** Patterns are frame-fixed, no switch; see Clarifications and FR-009.
- **G4 `sample()` behaviour.** `ideas/f_deflicker.md` (2026-10-25) records that a bilinear tap on a texel corner returned ONE texel, while `.specify/f_vf_stamp/spec.md` FR-009 says "sample bilinearly". Settle it on the bench before the spread is designed. Not reconciled in the docs.
- **G5 Spread kernel and radius cap.** A blur must fit the shader limits (about 16 reads per stage; about 250 statements per function, about 450 per program; `skills/jit-gen-codebox/SKILL.md`), so a wide spread needs cascaded stages or a downsample. Decide kernel, stage count and the maximum radius, and what the dial does beyond it.
- **G6 (resolved, clarify Q2).** Output is unclamped float32; see Clarifications and FR-010.
- **G7 Frame-border handling.** Clamp-to-edge, wrap or mirror at the frame border, by explicit index math, never an out-of-range `sample()` (the `G-edge-wrap` lesson cited in the `f_vf_stamp` spec, FR-010).
- **G8 (resolved, clarify Q4).** Two dedicated optional inlets; see Clarifications and FR-014. Still open for Phase 0: which effect amounts the in1 texture scales (proposal: all of them), and how the in2 vecfield elongates the spread kernel within the G5 limits.
- **G9 Linear-light versus encoded** (Matt, deferred).
- **G10 Noise source and statement budget.** `noise()` outputs black in the `jit.gl.pix` GPU path (`skills/jit-gen-codebox/SKILL.md`); use the sin hash. Decide how many octaves mottle gets inside the statement budget, and whether tooth and flecks share the hash.
- **G11 Name and menu.** `f_ink` is a placeholder; menu category under `G-menu`.
- **G12 Control set.** About a dozen dials plus the three channel gains is a dense panel (`G-ui-density`): grouping, and which dials are P2. The per-channel form is resolved (clarify Q5).

- **Plates from `f_separate` (Matt, 2026-11-08):** this module works on any texture, including each of the three coloured plate textures; this spec holds as written.

---

## User Stories

### User Story 1: Spread, ink gain and loss (Priority: P1)

A performer patches any texture into f_ink and raises Spread: marks fatten, small gaps close and small marks merge, as ink spreads on paper. A bias dial moves the result toward gain (fatter) or loss (thinner).

**Why this priority**: the core ink behaviour, and the base the other effects build on.

**Independent Test**: tier 1 on a flat disc, a one-texel line and a two-line gap; Spread 0 is identity.

**Acceptance Scenarios**:
1. **Given** Spread 0, **Then** the output equals the input exactly.
2. **Given** a disc of coverage 1 on 0 and Spread raised with neutral bias, **Then** the disc's edge is softened and its mean coverage is unchanged within tolerance (inferred: a pure blur preserves area; bias then moves the edge).
3. **Given** two lines separated by a gap smaller than the spread, **Then** the gap fills (the lines merge).
4. **Given** bias toward loss, **Then** the same disc shrinks.

### User Story 2: Mottle (Priority: P1)

A performer raises Mottle and the density of flat areas varies unevenly, in blotches, like a poorly inked drum. `mottle_scale` sets the blotch size.

**Independent Test**: tier 1 on a flat 0.8 patch: the standard deviation of the output grows with Mottle, and the spatial correlation length tracks `mottle_scale`.

**Acceptance Scenarios**:
1. **Given** Mottle 0, **Then** identity.
2. **Given** a flat 0.8 patch and Mottle > 0, **Then** the output varies slowly across the patch with mean near 0.8 (inferred: the mean is preserved or deliberately shifted: gate to settle in Phase 0).
3. **Given** the same seed and two frames of the same input, **Then** the output is identical (the pattern is stable, A3, A5).
4. **Given** a region of coverage 0, **Then** it stays 0 (mottle modulates ink, it does not add it).

### User Story 3: Dropout (Priority: P1)

A performer raises Dropout and the ink fails to take in places, like paper tooth: tiny gaps, pinholes and skips. `tooth_scale` sets the grain of the paper.

**Independent Test**: tier 1 on flat patches at 0.3, 0.6 and 1.0: the fraction of texels that drop out is monotone in Dropout.

**Acceptance Scenarios**:
1. **Given** Dropout 0, **Then** identity.
2. **Given** flat patches of different coverage and the same Dropout, **Then** lighter patches lose more texels than solid ones (inferred: light ink skips first on tooth; a solid takes everywhere).
3. **Given** `tooth_scale` raised, **Then** the dropped specks grow, in frame units.

### User Story 4: Edge pooling (Priority: P1)

A performer raises Edge Pool and ink collects at the edges of marks: a darker rim, the squash of letterpress and offset. `pool_width` sets the rim's width.

**Independent Test**: tier 1 on a disc: the rim's coverage exceeds the interior's, the interior and exterior are unchanged away from the edge, and the rim width tracks `pool_width`.

**Acceptance Scenarios**:
1. **Given** Edge Pool 0, **Then** identity.
2. **Given** a solid disc, **Then** coverage is highest in a band at the edge, and equals the input at distance greater than a few `pool_width` from it.
3. **Given** a flat field with no edges, **Then** the output equals the input.

### User Story 5: Flecks and banding (Priority: P2)

Flecks are sparse specks of ink or toner around and between marks; banding is a regular density variation across the frame (a roller). Each has an amount and a size or period.

**Acceptance Scenarios**:
1. **Given** Fleck or Band 0, **Then** identity.
2. **Given** a flat patch, **Then** flecks appear as isolated texels or small blobs at a rate that grows with the amount, and banding as parallel bands whose period equals the dial.

### User Story 6: Per-channel rates and drivers (Priority: P2)

A performer gives the three channels different gains (`gain_r`, `gain_g`, `gain_b`, so R, G and B spread and mottle at different rates), and drives an amount or a direction from another module: a texture modulates where an effect acts, a vecfield sets a spread direction, a simulation supplies the mottle field.

**Why this priority**: this is the bent-metaphor use: it turns a print emulation into an operator that gives digital results.

**Acceptance Scenarios**:
1. **Given** different channel gains, **Then** each output channel equals the single-channel result with every effect amount scaled by that channel's gain (gain 0 leaves the channel unchanged).
2. **Given** a driver texture, **Then** the effect's local amount follows the driver's luma (a driver of 0 leaves that region unchanged).
3. **Given** a vecfield on its inlet, **Then** spread is elongated along the field direction.

### User Story 7: Standard f_ module behaviour (Priority: P3)

`bypass`, `#0_` scoped names, helpfile, menu entry, README row, per the library conventions.

---

## Requirements

### Functional Requirements

- **FR-001**: The module MUST be a processor: in0 is a texture (in1 and in2 are the optional drivers of FR-014). With nothing connected it outputs black. All behaviour below is per channel (A2) and in frame-relative units (A4).
- **FR-002**: The module MUST be stateless (A3): the output is a pure function of in0, any driver inputs, the params, the seed and the render size. No feedback texture.
- **FR-003**: With every effect amount at 0, the output MUST equal the input exactly (A6).
- **FR-004**: Spread MUST blur each channel by a radius set in frame units, then re-threshold with a bias and a softness, so marks fatten, thin, round and merge. A separate `snap` dial MUST set how much of the re-threshold applies: at 0 the result is the plain blur, which keeps continuous tone (Matt, 2026-11-08). Its kernel, stage count and radius cap are fixed by G5.
- **FR-005** (revised 2026-11-09, Matt, after the first look): Mottle MUST only thin ink, most where ink is dense, and MUST NOT add ink where the input is 0. Its field comes from the mottle field inlet (FR-017) when connected, otherwise from built-in fine noise whose size is `mottle_scale`.
- **FR-006** (revised 2026-11-09): Dropout MUST remove ink where the coverage is below a tooth value that varies by position, with soft edges, so light tones drop out first. Solids go last, and at high amounts they MAY take pinholes. The tooth comes from the tooth field inlet (FR-017) when connected, otherwise from built-in fine noise at the grain `tooth_scale`.
- **FR-007** (reversed 2026-11-09, Matt chose candidate C): Edge pooling MUST keep the edges of marks at full value and thin the body of the mark, in a band of width `pool_width` set inward from the edge. A flat area of ink therefore thins when Edge Pool is up (this replaces "leave flat areas unchanged": a rim above 1 clips on a screen and cannot show on a full-value mark). No ink is added where the input is 0, and Edge Pool 0 is exact identity.
- **FR-008**: The effects MUST apply in this fixed order: spread, edge pooling, mottle, dropout, flecks, banding. The order is not configurable (Matt, 2026-11-08).
- **FR-009**: Patterns (mottle, tooth, flecks, bands) MUST be deterministic from the seed and fixed to the frame (Matt, 2026-11-08; no image-lock switch), so successive frames of the same input are identical.
- **FR-010**: The output MUST be float32, with no NaN or Inf reaching any outlet (non-finite input texels are zapped to 0). The output MUST NOT be clamped to 0..1 (Matt, 2026-11-08); identity at zero stays exact.
- **FR-011**: Every length MUST follow the render size (`render_dim` convention) and the module MUST be correct for non-square frames.
- **FR-012**: Frame-border handling per G7, by explicit index math.
- **FR-013**: Bypass MUST use a codebox `bypass_gate` Param (never native `@bypass`) and pass the source through.
- **FR-014**: The module MUST have two optional driver inlets (Matt, 2026-11-08): in1, a texture whose luma scales the effect amounts by position (luma 0 leaves that region unchanged); in2, a vecfield (`f_vecfield_type.md`) that sets the spread direction. With neither connected the module behaves as without drivers. An unconnected driver MUST be recognised from the connected flag (via `vs_inState`), not from its value (the `vs_black` lesson cited in the `f_vf_stamp` spec).
- **FR-016**: Three channel gains MUST each scale every effect amount (and the in1 driver's effect on it) for their channel; with all gains at 1 the module behaves as without them, and a gain of 0 leaves that channel unchanged (Matt, 2026-11-08).
- **FR-017** (Matt, 2026-11-09): Two more optional inlets, one for each: a mottle field and a tooth field, any texture, luma used in place of the built-in noise. Unconnected, the built-in noise is used. Recognised from the connected flag, not the value (as FR-014).
- **FR-015**: Standard behaviour: `#0_`-scoped names, `routepass` / `route` / `autopattr` with `varname`, `definition.py` as the source of truth.

### Non-Functional Requirements

- **NF-001** *(target, pending measurement)*: cost recorded at 1080p on the bench, stated as measured or unmeasured (library rule); the M1 is flagged.
- **NF-002**: Every stage MUST fit the codebox statement and read budgets (G5, G10), so the module passes the parser.
- **NF-003**: Verification follows the constitution's tiers (G1).

## Parameters (provisional; tuned live at tier 3)

| Param | Range | Default | Notes |
|---|---|---|---|
| `spread` | 0-1 | 0 | blur radius in frame units; 1 is 7 texels at 1080 (G5, Matt, 2026-11-08) |
| `bias` | -1 to 1 | 0 | after the blur: toward gain (fatter) or loss (thinner) |
| `snap` | 0-1 | 1 | how much the blur hardens back into a mark; 0 is a plain blur that keeps tone (name and default provisional) |
| `soften` | 0-1 | 0.2 | edge softness of the re-threshold |
| `edge_pool` | 0-1 | 0 | how far the body of a mark thins |
| `pool_width` | 0-0.02 | 0.014 | rim width in frame heights; 21 texels of reach (two blur pairs) |
| `mottle` | 0-1 | 0 | amount |
| `mottle_scale` | 0.01-0.3 | 0.045 | built-in patch size, speckle a tenth of it; no effect with a field patched |
| `dropout` | 0-1 | 0 | amount |
| `tooth_scale` | 0.001-0.02 | 0.003 | built-in grain size; no effect with a field patched |
| `fleck` | 0-1 | 0 | amount (P2) |
| `band` | 0-1 | 0 | amount (P2), with period |
| `seed` | int | 1 | pattern seed |
| `gain_r`, `gain_g`, `gain_b` | 0-2 | 1 | P2: scale every effect amount for that channel (Matt, 2026-11-08) |
| `bypass` | toggle | 0 | passthrough |

## Success Criteria

- **SC-001**: Identity: every amount at 0 gives the input exactly, on a test image.
- **SC-002**: Spread closed forms on a disc, a line and a gap match the mirror (area, merge, thin).
- **SC-003**: Mottle: the output standard deviation is monotone in the amount and its correlation length tracks the scale; output is 0 where the input is 0.
- **SC-004**: Dropout: the dropped fraction is monotone in the amount, and lighter patches lose more than solids.
- **SC-005**: Edge pooling: rim above interior on a disc, the flat area unchanged.
- **SC-006**: Stability: two frames of the same input and seed are bit-identical; a change of render size scales the features with the frame.
- **SC-007**: Channel independence: with channel gains, each channel equals the single-channel result with its amounts scaled by its own gain.
- **SC-008**: Tier-3 look (Matt): on the output of `f_stipple`, `f_tf_hatch` and a simulation (`f_wave_field` or `f_ks`), f_ink reads as ink on paper; and one deliberately bent use (for example per-channel spread, or a field-driven spread) reads as intentionally digital.

## Edge Cases

- Input values outside 0..1 (float textures from other modules) and negative values.
- Spread at the radius cap, and at texel scale.
- Features smaller than the spread (merge or vanish); marks at the frame border.
- `mottle_scale` below a texel or above the frame; `tooth_scale` below a texel.
- An all-black and an all-white input.
- Render size changes at runtime; non-square frames.
- A driver connected but flat (all 0 or all 1).
- Alpha: passes through from the source (A not processed), unless G12 decides otherwise.

## Out of Scope (This Version)

- Bleed, wicking and any effect with memory over time (a feedback build, a later separate module).
- Ink colour, paper, overprint and plate logic (`f_paper`, `f_separate`).
- Halftone screens and line work (`f_screen`, `f_engrave`); misregistration (`f_misregister`).
- Real fluid or capillary physics.
- Audio analysis: audio drives f_ink only through an upstream texture.
