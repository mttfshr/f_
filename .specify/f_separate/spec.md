# Spec: f_separate

_Created: 2026-11-08_
_Status: Draft: not yet built, not yet clarified_
_Origin: `ideas/f_print_styles.md` (stage 1 of the print-styles family, "separation"), modelled on the prepress app Matt uses to separate full-colour images into riso spot-colour inks. Name `f_separate` is a placeholder (plain `f_`, no family prefix: Matt, 2026-11-07)._

---

## Clarifications

### Resolved with Matt (2026-11-07 / 2026-11-08, in chat)

- **Not a swizzle.** Vsynth's RGB swizzle with a recolour gives at most three plates tied to R, G and B. `f_separate` splits a full-colour image into arbitrary spot-colour inks from a palette, or into CMYK-like inks, which is what makes it worth a module (Matt: "could be more interesting").
- **Plates are RGB channels, up to three.** Alpha is not a plate. Vsynth's invert module reverses a channel if needed. Spot-colour separation is the interesting part (Matt).
- **The reference is the prepress app** Matt uses for riso. It is specific to riso machines' halftone and overprint options and gives a **live composite preview showing the overall colour shift from the palette clamping** the chosen inks create. Its riso-specific halftone options are not to be emulated (Matt).
- **Separation and overprint are one coupled decision:** `f_separate` unmixes with the overprint model that `f_paper` will mix with (Claude's consequence of Matt's description, inferred).
- **A vocabulary, not a goal:** the separation is one operator in the print vocabulary and can be bent into a digital colour-reduction tool as well.
- **Undecided by Matt ("I don't know yet"):** the separation method for riso, and the CMYK scope. The method here is the preliminary decision below.

### Preliminary decisions taken by Claude (Matt, 2026-11-08: "accept your own recommendations for preliminary gates")

These are Claude's recommendations accepted in place so the spec can proceed; none is a Matt decision, and each is open to his reversal.

- **P1 Palette unmix.** Up to three inks (`inks` 1 to 3), each with a colour. The module finds, for each pixel, the coverage of each ink that best reproduces the pixel's colour, under the overprint model P2, clamped to 0..1.
- **P2 Overprint model: density (Beer-Lambert-like).** An ink with full-coverage colour `k` (relative to the paper) has optical density `d = -log(k)` per channel; coverages add: the colour of a pixel is `paper * exp(-sum_i c_i * d_i)`. Taking logs makes the model linear in the coverages, so the unmix is a small least-squares solve. Overprint is order-independent (a multiply). Riso inks are in reality translucent and order-dependent; order is out of scope. This model is Claude's choice, not checked against the prepress app or any print behaviour, and is gate G2.
- **P3 Paper colour is a parameter** (`paper`, default white), because the model is relative to the paper.
- **P4 Fewer inks than three:** the unmix is the least-squares projection onto the chosen inks (the colour the inks can best reproduce); what the inks cannot reproduce is the "clamping" the preview shows.
- **P5 Two outlets.** out0 is the plates: ink 1 coverage in R, ink 2 in G, ink 3 in B (unused channels 0). out1 is the **preview composite**: the plates recomposed on the paper by the same model, so the colour shift from the palette is visible live. The preview duplicates `f_paper`'s maths in a minimal form (G5).
- **P6 Hard split mode (P2 story):** `mode` Nearest assigns each pixel wholly to the nearest ink (or none), for flat spot-colour jobs. The default is Unmix.
- **P7 No black generation; palettes only.** A real CMYK needs a fourth plate and a nonlinear black extraction; CMYK is a four-ink palette and is out of scope as a three-channel result. Black is simply one of the inks.
- **P8 Per-pixel and stateless:** no neighbourhood, no feedback, no texture other than in0. Output is a pure function of in0 and the params.
- **P9 Plates bounded to 0..1;** the preview bounded to 0..1.
- **P10 Bypass** passes the source through on both outlets.
- **P11 Polarity as elsewhere in the family:** high channel value = more ink coverage in the plates. The source image is ordinary colour.

### Open, decided in Phase 0 (gates; to be carried into `tasks.md`)

- **G1 Verification tiers.** The first Phase 0 task. Proposal: tier 1 mirrors the unmix and the round trip (closed forms, no Max); tier 2 benches the real codebox; tier 3 is Matt's live look against his prepress app.
- **G2 Overprint model.** The density model P2 versus a coverage-weighted multiply (`paper * product_i (1 - c_i * (1 - k_i))`, order-independent but not linear in the coverages, so the unmix is not a linear solve). Decide by round trip and by whether the preview behaves as Matt's app does. Shared with `f_paper`, whose spec is not yet written.
- **G3 Solve and constraints.** Unconstrained least squares then clamp (cheap, not optimal) versus a constrained solve for three inks; ridge handling when the ink colours are nearly collinear.
- **G4 Degenerate inks.** An ink equal to the paper (zero density), an ink with a zero channel (the logarithm is undefined), and a pixel brighter than the paper: epsilon, clamp, and what the preview shows.
- **G5 Preview and `f_paper`.** Whether the preview stays inside `f_separate` (P5) or is only produced by a chain into `f_paper`; whether code can be shared between modules is unverified.
- **G6 Colour parameters in `definition.py`.** How a colour control (three ink swatches, the paper swatch) is expressed in `build/spec.md` and `build_patcher.py`; not read for this spec. If there is no colour-picker type, the colours may have to be three numbers each.
- **G7 Linear-light versus encoded values.** The density model is defined on reflectance (linear light). Deferred (Matt, for `f_ink`); here it changes the unmix directly, so decide before tier 3.
- **G8 Name, menu and panel.** The menu category under `G-menu`; the control set (three swatches plus paper, count, mode) under `G-ui-density`.
- **G9 Order dependence.** Riso overprint is order-dependent; whether to add an ink order later (out of scope now).

---

## User Stories

### User Story 1: Separate into spot-colour plates (Priority: P1)

A performer patches a full-colour image, picks up to three ink colours, and gets one plate per ink: where each ink needs to print for the inks together to reproduce the image.

**Why this priority**: the module's purpose.

**Independent Test**: tier 1 on flat patches of each ink colour, of their overprints, and of grey ramps.

**Acceptance Scenarios**:
1. **Given** a patch exactly the colour of ink 2 at full coverage, **Then** plate 2 is 1 and the other plates are 0.
2. **Given** a patch of the overprint of inks 1 and 2 at full coverage, **Then** plates 1 and 2 are 1 and plate 3 is 0.
3. **Given** a patch the colour of the paper, **Then** every plate is 0.
4. **Given** any pixel, **Then** every plate is within 0..1.

### User Story 2: Live gamut preview (Priority: P1)

out1 shows the plates recomposed on the paper. Colours the inks cannot reproduce visibly shift toward what they can, so choosing inks becomes a visible decision.

**Independent Test**: tier 1 round trip on an image inside the palette's gamut and one outside.

**Acceptance Scenarios**:
1. **Given** an image made only of colours the palette can reproduce, **Then** out1 equals the source within tolerance (the round trip).
2. **Given** an image with colours outside the gamut, **Then** out1 differs from the source, and the difference is the colour shift from the clamping.
3. **Given** a change to one ink colour, **Then** out1 updates immediately and the plates change accordingly.

### User Story 3: One and two inks (Priority: P1)

With one ink the plate is a tone of that ink (a luma-like projection); with two it is the best two-ink reproduction. The count `inks` selects 1, 2 or 3.

**Acceptance Scenarios**:
1. **Given** `inks` 1 and a black ink on white paper, **Then** plate 1 grows monotonically as the source darkens.
2. **Given** `inks` 2, **Then** plate 3 is exactly 0 and the preview shows the two-ink gamut.

### User Story 4: Paper colour (Priority: P1)

`paper` sets the colour the plates are relative to, so cream or tinted stock changes the separation and the preview.

**Acceptance Scenarios**:
1. **Given** a cream paper colour, **Then** a source patch of that colour gives all-zero plates.
2. **Given** a change in `paper`, **Then** the plates and the preview both change.

### User Story 5: Hard split (Priority: P2)

`mode` Nearest assigns each pixel wholly to its nearest ink (or to none when closest to the paper), giving flat spot-colour plates for a screen-print look.

**Acceptance Scenarios**:
1. **Given** Nearest, **Then** each pixel has at most one plate at 1 and the rest at 0.
2. **Given** a pixel exactly an ink colour, **Then** that plate is 1.

### User Story 6: Per-ink tone shaping (Priority: P2)

A per-plate gain (or curve) on the coverages before the preview, so one ink can be weakened or strengthened without changing the palette. (The full per-plate tone curve belongs upstream in `f_tone_curve`.)

### User Story 7: Standard f_ module behaviour (Priority: P3)

`bypass`, `#0_` scoped names, helpfile, menu entry, README row.

---

## Requirements

### Functional Requirements

- **FR-001**: The module MUST be a processor: in0 is a colour texture. With nothing connected it outputs black on both outlets.
- **FR-002**: The module MUST be per-pixel and stateless (P8): the outputs are pure functions of in0 and the params.
- **FR-003**: out0 MUST carry the plates: ink 1 coverage in R, ink 2 in G, ink 3 in B, channels for unused inks exactly 0 (`inks`), each bounded to 0..1.
- **FR-004**: In Unmix mode, the coverages MUST be the least-squares solution under the overprint model (P2, G2) for the pixel's colour relative to `paper`, clamped to 0..1 (P1, P4, G3).
- **FR-005**: out1 MUST be the plates recomposed on `paper` by the same model (P5), so that for any pixel whose colour the palette can reproduce, out1 equals the source within tolerance (the round trip).
- **FR-006**: A pixel the colour of the paper MUST give all-zero plates, and a pixel exactly an ink's full-coverage colour MUST give that plate 1 and the others 0 (within tolerance).
- **FR-007**: Degenerate inks and pixels (G4) MUST NOT produce NaN or Inf: an ink equal to the paper, a zero channel in an ink, a collinear palette, and a pixel brighter than the paper are all handled and tested.
- **FR-008**: In Nearest mode, each pixel MUST have at most one plate at 1 and the rest at exactly 0.
- **FR-009**: Alpha MUST pass through from the source on both outlets.
- **FR-010**: The outlets MUST be float32 and bounded to 0..1; no NaN or Inf MAY reach either (non-finite input texels are zapped).
- **FR-011**: The ink and paper colours MUST be controllable live (G6), and a change MUST take effect on the next frame.
- **FR-012**: Bypass MUST use a codebox `bypass_gate` Param (never native `@bypass`) and pass the source through on both outlets (P10).
- **FR-013**: Standard behaviour: `#0_`-scoped names, `routepass` / `route` / `autopattr` with `varname`, `definition.py` as the source of truth.

### Non-Functional Requirements

- **NF-001** *(target, pending measurement)*: one pass at 1080p with cost recorded on the bench, stated as measured or unmeasured (library rule).
- **NF-002**: The per-pixel solve MUST fit the codebox statement budget (about 250 per function body, about 450 per program; `skills/jit-gen-codebox/SKILL.md`); the palette's pseudo-inverse is computed once per palette change, not per pixel, if the build system allows it (inferred; G3).
- **NF-003**: Verification follows the constitution's tiers (G1).

## Parameters (provisional; tuned live at tier 3)

| Param | Range | Default | Notes |
|---|---|---|---|
| `inks` | 1-3 | 2 | how many inks are active |
| `ink1`, `ink2`, `ink3` | colours | three distinct spot colours | full-coverage colours of the inks (G6) |
| `paper` | colour | white | the colour the plates are relative to |
| `mode` | Unmix / Nearest | Unmix | Nearest is P2 |
| `gain1`, `gain2`, `gain3` | 0-2 | 1 | per-ink coverage gain (P2 story) |
| `bypass` | toggle | 0 | passthrough on both outlets |

## Success Criteria

- **SC-001**: Reproduction: flat patches of each ink, each overprint pair, the paper colour and a grey ramp separate to the expected plates within tolerance (User Story 1).
- **SC-002**: Round trip: for sources inside the palette's gamut, `out1` equals the source within `[set in Phase 0]`; for sources outside, `out1` is the nearest reproducible colour under the model.
- **SC-003**: Bounds: plates and preview are within 0..1 for any input, including values above 1, below 0 and non-finite.
- **SC-004**: Degenerate palettes: an ink equal to the paper, a zero-channel ink, and a collinear palette produce no NaN or Inf and a defined result.
- **SC-005**: Monotone: with one ink, the plate rises monotonically as the source darkens toward the ink.
- **SC-006**: Nearest mode: at most one plate is nonzero per pixel; exact ink colours map to their plate.
- **SC-007**: Live update: changing an ink or the paper changes the plates and the preview on the next frame.
- **SC-008**: Tier-3 look (Matt): a full-colour photo with two or three chosen riso-style inks shows a preview that matches what his prepress app's preview does in character (the colour shift from the palette), and one deliberately bent use (three unrelated colours, or a very narrow palette) reads as intentionally digital.

## Edge Cases

- `inks` 1 with an ink very close to the paper colour (tiny dynamic range).
- Two inks of nearly the same colour (collinear), or an ink the colour of black (full density in every channel).
- A source brighter than the paper, darker than any overprint, or outside 0..1.
- An all-black and an all-white source; a source colour exactly between inks.
- A paper colour with a zero channel.
- Changing `inks` at runtime (the unused channels go to exactly 0).
- Colours outside the gamut near the boundary (the preview's clamp seam).

## Out of Scope (This Version)

- Halftoning or any spatial treatment (`f_screen`, `f_engrave`, `f_ink`).
- Black generation and a fourth plate (P7).
- Order-dependent (translucent) overprint (G9).
- Picking the palette from the image automatically.
- Paper texture, ink colour physics beyond the model, misregistration and emboss (`f_paper`, `f_misregister`).
- A full per-plate tone curve (`f_tone_curve`).
