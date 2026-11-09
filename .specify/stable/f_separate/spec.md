# Spec: f_separate

_Created: 2026-11-08_
_Status: Draft: P-list reviewed with Matt 2026-11-08 (additive, black background, coloured plates); FRs, stories and success criteria reconciled 2026-11-08; not built_
_Origin: `ideas/f_print_styles.md` (stage 1 of the print-styles family, "separation"), modelled on the prepress app Matt uses to separate full-colour images into riso spot-colour inks. Name `f_separate` is a placeholder (plain `f_`, no family prefix: Matt, 2026-11-07)._

---

## Clarifications

### Resolved with Matt (2026-11-07 / 2026-11-08, in chat)

- **Not a swizzle.** Vsynth's RGB swizzle with a recolour gives at most three plates tied to R, G and B. `f_separate` splits a full-colour image into arbitrary spot-colour inks from a palette, or into CMYK-like inks, which is what makes it worth a module (Matt: "could be more interesting").
- **Plates:** up to three, one per ink. Alpha is not a plate. Vsynth's invert module reverses a channel if needed. Spot-colour separation is the interesting part (Matt).
- **SUPERSEDED 2026-11-08 (print is a vocabulary for screens; no prepress comparison decides anything): the reference was the prepress app** Matt uses for riso. It is specific to riso machines' halftone and overprint options and gives a **live composite preview showing the overall colour shift from the palette clamping** the chosen inks create. Its riso-specific halftone options are not to be emulated (Matt).
- **Separation and overprint are one coupled decision (now additive light, P2):** `f_separate` unmixes with the overprint model that `f_paper` will mix with (Claude's consequence of Matt's description, inferred).
- **A vocabulary, not a goal:** the separation is one operator in the print vocabulary and can be bent into a digital colour-reduction tool as well.
- **Undecided by Matt ("I don't know yet"):** the separation method for riso, and the CMYK scope. The method here is the preliminary decision below.

### Decided with Matt, P-list review (2026-11-08, chat, one at a time)

- **Paper is the background, and it is black.** Matt: "we're not printing on paper. paper is a metaphor"; other modules behave the same. There is no `paper` parameter. Ink colours are colours of light. This replaced the density (Beer-Lambert) model and the paper-relative maths; the prepress app is no longer a reference for any decision (print is a vocabulary: see `ideas/f_print_styles.md`).
- **P1 Palette unmix** (Matt: yes). Up to three inks (`inks` 1 to 3), each a colour. Per pixel, the coverage of each ink that best reproduces the pixel's colour, clamped to 0..1.
- **P2 Overprint is additive light** (Matt: "add"). Pixel colour is `sum_i c_i * k_i` on black. Linear in the coverages, so the unmix is an exact small least-squares solve; no logs, no epsilon, order-independent. The preview clips where inks sum past 1. The screen-blend alternative (`1 - prod(1 - c_i k_i)`, never clips, not exactly invertible) was offered and not chosen.
- **P3 No paper parameter** (Matt: the background is always black).
- **P4 Fewer inks:** least-squares projection onto the chosen inks; what they cannot reproduce is lost and the preview shows it (Matt: yes).
- **P5 Four outlets** (Matt): one coloured plate per ink, each `c_i * k_i` (a teal ink gives a teal plate; plates cannot be packed into R, G and B), black for unused inks, plus a fourth **preview** outlet, the sum of the plates. Reason (Matt): a single RGB channel cannot represent a spot colour like teal.
- **P6 Nearest mode** (Matt: yes): `mode` Nearest assigns each pixel wholly to the nearest ink or to black (black is a candidate), by RGB distance; the winner's coverage is 1, the others 0. Unmix is the default.
- **P7 No black generation, no CMYK** (Matt: yes): up to three coloured-light inks; black is the background, there is no black plate or fourth plate.
- **P8 Per-pixel and stateless** (Matt: yes): no neighbourhood, no feedback, one texture input.
- **P9 Bounds** (Matt: yes): coverages and the preview clamped to 0..1.
- **P10 Bypass** (Matt: yes): the source goes to all four outlets.
- **P11 Polarity** (Matt: yes): more light in the source means more coverage; the source is an ordinary colour image.

- **P12 Project mode** (Matt, 2026-11-08, after seeing that moving one ink's swatch changed the other plates: the joint solve makes plates depend on each other whenever the ink colours overlap; "the independent alternative might be easier to reason about"): a third `sep_mode`, Project: each ink alone, `c_i = clamp(gain_i * (k_i . x) / (k_i . k_i), 0, 1)`. A plate depends only on the source and its own ink; the cost is no exact round trip for overlapping inks (the preview can overshoot and clip) and bleed (the teal patch gives a violet plate 0.50 through shared blue, measured on the mirror). Unmix stays the default; Matt picks by look.

### Consequences noted, not yet applied elsewhere

- The FRs, user stories and success criteria were reconciled with this list on 2026-11-08 (tasks T013a). A gain above 1 cannot push a plate past its ink colour (follows from P9; preliminary).
- `f_screen`, `f_ink` and `f_engrave` were specced with plates as single channels; with coloured plates they act on the plate's brightness and keep its colour. To be noted in those specs.
- `f_paper` inherits additive light (the contract is simpler: sum of plates), no Beer-Lambert.

### Open, decided in Phase 0 (gates; carried into `tasks.md`)

- **G1 Verification tiers.** Proposal: tier 1 mirrors the unmix and the round trip (closed forms, no Max); tier 2 benches the real codebox; tier 3 is Matt's live look.
- **G2 Overprint model.** CLOSED by P2 (additive).
- **G3 Solve and constraints.** Unconstrained least squares then clamp versus a non-negative solve for three inks; ridge when the ink colours are nearly collinear.
- **G4 Degenerate inks.** A black ink (zero column), duplicate or collinear inks, and non-finite input. (Paper-related cases are gone.)
- **G5 Preview.** CLOSED by P5: the preview is the fourth outlet.
- **G6 Colour parameters in `definition.py`.** CLOSED (T009, 2026-11-08): three `swatch` boxes unpacked to nine Params, plus a saturation dial per ink (Matt: pastels, greys and dim inks matter); nine float dials are the fallback.
- **G7 Linear-light versus encoded values.** Deferred (Matt). Additive light is physically linear light; whether to treat the input as encoded is a look decision.
- **G8 Name, menu and panel.** Menu category under `G-menu`; control set (three swatches, count, mode, gains) under `G-ui-density`.
- **G9 Order dependence.** Moot: additive overprint is commutative.

---

## User Stories

### User Story 1: Separate into spot-colour plates (Priority: P1)

A performer patches a full-colour image, picks up to three ink colours, and gets one plate per ink on its own outlet: how much of each ink's light is needed for the inks together to reproduce the image. Each plate is the ink's colour times its coverage (a teal ink gives a teal plate).

**Why this priority**: the module's purpose.

**Independent Test**: tier 1 on flat patches of each ink colour, of their overlaps, and of grey ramps.

**Acceptance Scenarios**:
1. **Given** a patch exactly the colour of ink 2, **Then** plate 2 is exactly ink 2's colour and the other plates are black.
2. **Given** a patch that is the sum of inks 1 and 2 (within 0..1), **Then** plates 1 and 2 are their ink colours and plate 3 is black.
3. **Given** a black patch, **Then** every plate is black.
4. **Given** any pixel, **Then** every plate is within 0..1.

### User Story 2: Live gamut preview (Priority: P1)

Outlet 3 shows the plates added together on black. Colours the inks cannot reproduce visibly shift toward what they can, so choosing inks becomes a visible decision.

**Independent Test**: tier 1 round trip on an image inside the palette's gamut and one outside.

**Acceptance Scenarios**:
1. **Given** an image made only of colours the palette can reproduce, **Then** the preview equals the source within tolerance (the round trip).
2. **Given** an image with colours outside the gamut, **Then** the preview differs from the source, and the difference is the colour the inks cannot make (plus clipping where inks sum past 1).
3. **Given** a change to one ink colour, **Then** the preview updates immediately and the plates change accordingly.
4. **Given** any inputs, **Then** the preview equals the sum of the three plate outlets, clamped to 0..1.

### User Story 3: One and two inks (Priority: P1)

With one ink the plate is the projection of the pixel onto that ink's colour; with two it is the best two-ink reproduction. The count `inks` selects 1, 2 or 3.

**Acceptance Scenarios**:
1. **Given** `inks` 1 and a grey ink, **Then** plate 1 grows monotonically as the source brightens.
2. **Given** `inks` 2, **Then** plate 3 is exactly black and the preview shows the two-ink gamut (a colour the two inks cannot make is lost).

### User Story 4: Hard split (Priority: P2)

`mode` Nearest assigns each pixel wholly to its nearest ink, or to none when black is closest, giving flat spot-colour plates.

**Acceptance Scenarios**:
1. **Given** Nearest, **Then** each pixel has at most one plate non-black, and that plate is exactly its ink colour.
2. **Given** a pixel exactly an ink colour, **Then** that plate is that colour and the others are black.

### User Story 4b: Project mode (Priority: P2)

`sep_mode` Project makes each plate depend only on the source and its own ink (P12).

**Acceptance Scenarios**:
1. **Given** Project, **When** any other ink's colour changes, **Then** an ink's plate is unchanged exactly.
2. **Given** orthogonal inks (red, green, blue) or one ink, **Then** Project equals Unmix.
3. **Given** a patch exactly an ink's colour, **Then** that ink's plate is that colour in full (other plates may be non-zero where inks share colour).

### User Story 5: Per-ink gain (Priority: P2)

A per-ink gain (0-2) on the coverage, so one ink can be weakened or strengthened without changing the palette. The gain is applied before the 0..1 clamp of P9, so a gain above 1 saturates a plate faster but never makes it brighter than its ink colour (preliminary: follows from P9). The full per-plate tone curve belongs upstream in `f_tone_curve`.

### User Story 6: Standard f_ module behaviour (Priority: P3)

`bypass`, `#0_` scoped names, helpfile, menu entry, README row.

---

## Requirements

### Functional Requirements

- **FR-001**: The module MUST be a processor: in0 is a colour texture. With nothing connected it outputs black on all four outlets.
- **FR-002**: The module MUST be per-pixel and stateless (P8): the outputs are pure functions of in0 and the params.
- **FR-003**: Outlets 0 to 2 MUST carry the plates: plate `i` is `c_i * k_i` (ink colour times coverage, each coverage in 0..1), exactly black for any ink beyond `inks`.
- **FR-004**: In Unmix mode, the coverages MUST be the least-squares solution of `K c = x` (P1, P2, G3) for the pixel colour `x`, clamped to 0..1, with the gain applied before the clamp.
- **FR-005**: Outlet 3 MUST be the sum of the three plate outlets clamped to 0..1 (P5), so that for any pixel whose colour the palette can reproduce, it equals the source within tolerance (the round trip).
- **FR-006**: A black pixel MUST give all-black plates, and a pixel exactly an ink's colour MUST give that plate exactly its ink colour and the others black (within tolerance).
- **FR-007**: Degenerate inks and pixels (G4) MUST NOT produce NaN or Inf: a black ink, duplicate or collinear inks, and non-finite input are all handled and tested.
- **FR-014**: In Project mode (P12), each coverage MUST be `clamp(gain_i * (k_i . x) / (k_i . k_i), 0, 1)` and MUST NOT depend on any other ink.
- **FR-008**: In Nearest mode, each pixel MUST have at most one non-black plate, equal to its ink colour (P6).
- **FR-009**: Alpha MUST pass through from the source on all four outlets.
- **FR-010**: The outlets MUST be float32 and bounded to 0..1; no NaN or Inf MAY reach any (non-finite input texels are zapped).
- **FR-011**: The ink colours MUST be controllable live (G6), and a change MUST take effect on the next frame.
- **FR-012**: Bypass MUST use a codebox `bypass_gate` Param (never native `@bypass`) and pass the source through on all four outlets (P10).
- **FR-013**: Standard behaviour: `#0_`-scoped names, `routepass` / `route` / `autopattr` with `varname`, `definition.py` as the source of truth.

### Non-Functional Requirements

- **NF-001** *(stated UNMEASURED, Matt, 2026-11-08)*: one pass at 1080p with cost recorded on the bench, stated as measured or unmeasured (library rule).
- **NF-002**: The per-pixel solve MUST fit the codebox statement budget (about 250 per function body, about 450 per program; `skills/jit-gen-codebox/SKILL.md`); the palette's pseudo-inverse is computed once per palette change, not per pixel, if the build system allows it (inferred; G3). Four outlets from one stage are unverified in this build system.
- **NF-003**: Verification follows the constitution's tiers (G1).

## Parameters (provisional; tuned live at tier 3)

| Param | Range | Default | Notes |
|---|---|---|---|
| `inks` | 1-3 | 2 | how many inks are active |
| `ink1`, `ink2`, `ink3` | colours (swatch) | three distinct spot colours | full-coverage colours of the inks, colours of light (G6) |
| `sat1`, `sat2`, `sat3` | 0-1 | 1 | saturation of each swatch's colour plane; panel-only, not codebox Params (T009) |
| `sep_mode` | Unmix / Nearest / Project | Unmix | Nearest is P6, Project is P12 (a menu; `mode` would bind to a pix attribute) |
| `gain1`, `gain2`, `gain3` | 0-2 | 1 | per-ink coverage gain (User Story 5) |
| `bypass` | toggle | 0 | passthrough on all four outlets |

## Success Criteria

- **SC-001**: Reproduction: flat patches of each ink, each overlap pair (the sum), black and a grey ramp separate to the expected plates within tolerance (User Story 1).
- **SC-002**: Round trip: for sources inside the palette's gamut, the preview equals the source within `[set in Phase 0]`; for sources outside, it is the nearest reproducible colour under the model.
- **SC-003**: Bounds: plates and preview are within 0..1 for any input, including values above 1, below 0 and non-finite.
- **SC-004**: Degenerate palettes: a black ink, duplicate inks and a collinear palette produce no NaN or Inf and a defined result.
- **SC-005**: Monotone: with one ink, the plate rises monotonically as the source brightens toward the ink.
- **SC-006**: Nearest mode: at most one plate is non-black per pixel; exact ink colours map to their plate.
- **SC-007**: Live update: changing an ink changes the plates and the preview on the next frame.
- **SC-008**: Tier-3 look (Matt): a full-colour photo with two or three chosen inks shows plates and a preview that look and behave well on screen (the colour shift from the palette is legible), and one deliberately bent use (three unrelated colours, or a very narrow palette) reads as intentionally digital. No comparison with a print or prepress reference.

## Edge Cases

- `inks` 1 with a very dim ink (tiny dynamic range).
- Two inks of nearly the same colour (collinear), or a black ink (a zero column).
- A source darker than black, outside 0..1, or brighter than the inks can sum to.
- An all-black and an all-white source; a source colour exactly between inks.
- Changing `inks` at runtime (the unused plates go to exactly black).
- Colours outside the gamut near the boundary (the preview's clamp seam).
- Inks that sum past 1 in a channel (the preview clips).

## Out of Scope (This Version)

- Halftoning or any spatial treatment (`f_screen`, `f_engrave`, `f_ink`).
- A black plate, CMYK and a fourth plate (P7).
- Picking the palette from the image automatically.
- A paper parameter or texture: the background is black (P3). Misregistration and emboss (`f_misregister`).
- A full per-plate tone curve (`f_tone_curve`).
