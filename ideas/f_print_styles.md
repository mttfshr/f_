# Print styles: a vocabulary of print behaviours as composable `f_` modules

_Captured 2026-11-07 in chat with Matt; reorganised by topic 2026-11-08. Concept and decisions only: not specced, nothing built or measured. Process descriptions are general knowledge, not checked against anything in the repo. Repo facts cite the inventory (`docs/f-reference/module-inventory.md`, lines cited, **not opened**) or the `f_tf_hatch` reference doc (**read 2026-11-08, nothing run**). "Inferred" means worked out, not observed._

## Goal

The physical behaviours of print (ink spread, mottle, dropout, edge pooling, halftone screens, line work, misregistration, overprint, paper) are a **vocabulary, not the goal** (Matt, 2026-11-08). The family is a set of composable operators named for those behaviours. They can reproduce specific print looks (offset, riso, xerox, intaglio, screen print, letterpress, linocut, newspaper, gravure) as recipes, and the same operators, driven by the rest of Vsynth, can be bent into results that look unmistakably digital. Authentic emulation is one use of the vocabulary, not the measure of success.

## Decisions so far

Settled (Matt unless noted):

1. **Architecture:** a family of small modules, one per stage, composed in Max; not one module with a style menu. Styles are recipes: example patches and presets. (2026-11-07)
2. **Plain `f_` names.** Prefixes mark module type (`f_vf_`, `f_tf_`, `f_a_`), not effect category, and these are plain texture modules. Module names below are placeholders. (2026-11-07)
3. **First target: riso.** Intaglio is a later phase. (2026-11-07)
4. **Plates are processed separately:** every stage passes plates through, and a final stage composites them. (2026-11-07)
5. **Form-following line work uses the tensor family** (`f_tf_*`). (2026-11-07)
6. **Line work and `f_tf_hatch` are separate concerns.** The line module is its own thing and does not evolve hatch. Hatch may later pick up some of its flexibility. (2026-11-08)
7. **No riso-specific halftoning.** The screen stage does halftoning generally. (2026-11-08)
8. **Immediate interest is stage 3 (ink body),** the static look first, bleed over time second. (2026-11-08)
9. **Spec first, but not yet:** Matt wants time to think. No scratch spike until he says. (2026-11-08)

Tentative (Matt: "a decision but I'm not sure it's the decision", 2026-11-08): `f_screen` does fixed-angle round and line screens only, one angle per plate. Marks that follow the image's form (stretched dots, hatching, engraving) belong to the tensor family and the line module. Reason: a dot stretched along a direction until its neighbours merge is a hatch stroke.

## The five stages

| Stage | Job | Module (placeholder) |
|---|---|---|
| 1 Separation | full-colour image to plates | `f_separate` |
| 2 Tone-to-mark | plate tone to dots, grain, threshold or lines | `f_screen`; `f_engrave` (form-following, later) |
| 3 Ink body | dot gain, mottle, dropout, edge pooling, flecks, banding | `f_ink` |
| 4 Process artifacts | per-plate misregistration, wobble, ghosting | `f_misregister` |
| 5 Substrate | plates x ink colours onto paper: overprint, tint, tooth, show-through, emboss | `f_paper` |

**Plate convention (proposed, not confirmed; Matt 2026-11-08: alpha as a plate is not essential, spot-colour separation is the interesting part, and Vsynth has an invert module if a reversed channel is needed):** one texture, RGB = up to three plates, each channel the ink coverage 0..1 of that plate. Riso with one to three spot inks fits; a four-plate CMYK would need a second texture and is not a goal. Stages 2-4 act on every channel, with per-plate params where they matter (screen angle, offset). Only `f_paper` knows ink colours. Any stage can be skipped, any ordinary `f_` module can sit between stages, and a single channel can be pulled out to recolour or process, which is what "process separately" needs.

### Stage 1: `f_separate`

**Status 2026-11-08:** built, benched, documented (`docs/f-reference/f_separate.md`); tuning looks pending. Light on black with additive inks: where this section still says multiply or paper, the update below replaces it.

Not a swizzle. Vsynth's RGB swizzle plus a recolour gives at most three plates tied to R, G and B. `f_separate` would split a full-colour image into CMYK or arbitrary spot-colour inks from a palette, like the prepress app Matt uses for riso separations. The value is the palette-aware split: an unmix against the ink colours, and a rule for what to give up when there are fewer inks than colours.

That app (Matt, 2026-11-08) is specific to riso machines' halftone and overprint options and gives a live composite preview showing the colour shift caused by the palette clamping your ink choices create. Consequences (inferred from his description, not the app):

- **Update 2026-11-08 (Matt, `f_separate` review; supersedes the multiply and paper wording in this section):** "paper is a metaphor": the background is black and inks are colours of light that ADD. `f_separate` outputs one coloured texture per ink (coverage times ink colour) plus a summed preview, so a later `f_paper` inherits addition, not a subtractive overprint. `f_screen` and `f_engrave` work on the RGB channels of each texture, with a Channels / Single toggle (Single = one screen for a spot colour).
- Separation and overprint are one coupled decision: `f_separate` and `f_paper` must share one overprint model, `f_separate` inverting what `f_paper` applies.
- The preview is a chain: `f_separate` into `f_paper` with no screen between shows the gamut-clamped image; inserting `f_screen` gives the real look.
- A test: separate and recompose a flat patch of each ink; it should come back unchanged.
- Riso inks are translucent and overprint order-dependently, so the overprint model (multiply or something else) is an explicit spec decision.

**Black / K (inferred, Matt has not answered):** the output is light on a screen, so K's print reasons (ink cost, drying) do not apply. What carries over is a deeper black than CMY multiplied gives, and a key plate that stays crisp while the colour plates drift. Both work if black is simply one ink in the palette. Black generation (pulling K out of CMY, nonlinear) matters only to emulate CMYK offset specifically. Claude's lean: palettes only, with CMYK as a four-ink palette (open question 3).

### Stage 2: screens, thresholds, and the line module

Dithering, halftoning and hatching are largely **one operation**: compare tone to a threshold field. A clustered-dot screen is a threshold field of dots at an angle, a line screen is stripes, ordered dither is a Bayer or blue-noise field, and engraving is stripes that follow the image's form. What differs is the field generator (the hard part), the scale (dither works at pixel scale with a hard compare; halftone marks are larger and want a soft compare for dot gain and antialiased edges) and the output levels. Error diffusion (Floyd-Steinberg) is the exception: it is sequential and does not fit a per-pixel GPU pass; a blue-noise threshold approximates the look. All of this is inferred.

**`f_screen` and `ideas/f_dither_grain.md`:** both are cell fields with size, shape and a regularity dial (`jitter`) and a compare per cell. They differ in colour model: `f_dither_grain` resolves each grain to exactly one hue, so a dithered image never overprints, while print separates into inks and layers them. Print also needs several plates at different angles, and a soft compare. Current lean: keep them separate and share only the cell vocabulary (`density`, `size`, `shape`, `jitter`). Whether to fold them together stays open (question 6).

**The line module (`f_engrave`, intaglio and form-following lines), later phase:**

- Lines follow the image's contours (along isophotes, perpendicular to the luma gradient) with width set by tone; crosshatch in shadows by layering a second direction at a tone threshold. Direction comes from the tensor chain.
- It is **separate from `f_tf_hatch`.** Per its reference doc (read 2026-11-08), hatch is a diagnostic streamline renderer: inputs are the tensor and an optional stroke texture; Grain, Density and Contrast are global dials; coherence sets stroke length and faithfulness; there is no coherence-to-stroke-shape mapping and no tone input. The gaps to engraving (all inferred): tone input; tone-to-width; a regular pitch (hatch uses sparse noise, so strokes have random gaps); line continuity beyond the 16-step march; tone-gated crosshatch (hatch has only a global `angle_offset`); plate output; stability under motion (noise-seeded lines would swim).
- **Main risk (inferred, untested):** engraving needs evenly spaced, coherent parallel lines, and keeping line phase continuous along a direction field is a known hard problem (the phase must be integrated, and it breaks at singularities). Options for a scratch spike: LIC over a line-pattern seed; a line pattern warped by a smoothed luma field (iso-lines of tone); lines spaced by distance to the previous line. Pick by looking.
- Plate wipe tone, ink relief and a plate-mark emboss belong to `f_paper`, shared with letterpress.

### Stage 3: `f_ink` (Matt's immediate interest)

"Ink on paper" is a metaphorical framing: describe the characteristics of physical ink, simulate them, then bend the metaphor to things that look unmistakably digital. So `f_ink` (inferred design consequences):

- It takes **any texture and returns a texture**, with no ink colour, paper or plate assumption (those live in `f_paper`). It works per channel on whatever it gets, which takes the plate-convention question off its critical path and means it can be tried today on the output of `f_stipple`, `f_tf_hatch`, `f_wave_field` or anything else.
- Dial names stay physical (Spread, Mottle, Dropout, Edge Pool), but ranges may exceed what ink does: anisotropic spread, negative gain, per-channel rates so R, G and B bleed at different speeds.
- Its operations look like variations of blur then threshold against a field: dot gain (blur, then re-threshold), mottle (a low-frequency threshold field), dropout (a paper-tooth field), edge pooling (spread minus eroded, a darker rim), flecks (sparse noise), banding (a one-dimensional periodic term). That is the same threshold-field idea as stage 2.
- The field and direction drivers can come from anywhere: tagged textures, vecfield or tensor direction (spread along a field, edge pooling along a gradient from `f_vf_fieldmap`, mottle streaked along the structure axis), simulation output (`f_ks`, `f_wave_field`, `f_vf_fluid`), audio.
- Static spread, mottle, dropout and edge pooling come first. Applying the spread every frame in a feedback loop turns it into bleed over time, a stateful build with its own bench difficulty, second (`f_grain` has a feedback layer, per the inventory).
- Print-looking results are defaults and presets.

### Stages 4 and 5

`f_misregister` gives each plate its own offset, rotation and scale (riso passes are separate drums, so each plate drifts independently), plus wobble and ghosting. `f_paper` composites plates by their ink colours with the shared overprint model, and adds tint, tooth, show-through and emboss. Banding can live in `f_ink`.

## Existing pieces (per the inventory unless noted)

- `f_stipple` (line 93): hash-field stipple/halftone, an FM (stochastic) screen; covers part of stage 2.
- `f_tf_hatch` (line 58; reference doc read): streamline renderer along the tensor axis. Its direction decode is reusable for the line module.
- `f_tf_*`: the structure tensor and its consumers, the direction source for form-following lines.
- `f_grain` (lines 90, 193): grain field with a feedback layer; candidate for xerox generation loss and for bleed.
- `f_tone_curve`: shape tone before screening.
- `f_raster` (`ideas/f_raster.md`): resolution as a parameter; its aesthetic reference already lists riso, screen print and xerox.
- `ideas/f_dither_grain.md`: threshold-versus-scalar dithering as a grain-family processor.

## Riso first spike (a proposal, not started)

Riso signature (general knowledge): one to three spot-colour passes, each its own drum with its own misregistration; a grainy "grain touch" screen or a coarse halftone; heavily mottled ink with dropout; translucent inks that overprint into mixed colours; uncoated warm paper; slight banding.

- **Chain:** `f_separate` (N spot inks) then `f_screen` (grain or coarse AM, per-plate angle) then `f_ink` (mottle, dropout, gain) then `f_misregister` then `f_paper` (overprint, tint, tooth).
- **Done when:** a photo through a two-ink chain reads as riso on Matt's live look. Nothing else counts as done.
- **Module count is open:** the spike could be built as these modules, or as a scratch patch first to find which stages really are separate (scratch before spec). Because `f_ink` stands alone, it is also a natural first piece.

## Other styles as recipes (later; cost is mostly presets)

Offset (four plates, rosette halftone at 15/75/0/45 degrees, small misregistration, moiré for free); xerox (threshold, toner flecks, edge boost, streaks, feedback loop); newspaper (one coarse 45-degree plate, high gain, show-through); screen print (flat spots, mesh, fray); letterpress (squash rim, deboss); linocut and woodcut (hard threshold, carved gouge marks, grain direction; probably another `f_screen` mode); gravure (cell grid, visible walls).

## Possible later: more mark character in `f_tf_hatch` (parked, not scoped)

Matt thinks hatch could use more control over the character of the individual mark; unsure what. His framing: if the aim were a drawn look, pen nibs and calligraphic character. Candidates read from the hatch reference doc (inferred; codebox not read; nothing tried): width separate from Grain (Grain now sets thickness and noise scale together); taper by weighting the 16 march steps with a profile; per-stroke length variation (a hash per step); direction wobble along coherent strokes; per-stroke pressure; a threshold-level dial for hard-line width. The module already knows each stroke's axis, so a broad-nib effect (thickness set by the angle between stroke and a nib angle) uses data it has; a pointed pen is pressure plus taper. New dials should default to the current output bit for bit, as Coh Floor does, so the stable tests stay valid.

## Open questions

1. **Plate convention:** RGBA-as-plates, or separate textures? Check how `f_vf_ch` / `f_vf_channelmap` treat channels first. (Matt: "I don't know yet".)
2. **Module names:** all placeholders. `screen` collides in meaning with `ideas/circular_screen.md`, so `f_halftone` may fit better.
3. **`f_separate`:** the separation method (luma into one plate, nearest ink colour, or channel invert to CMY; Matt: "I don't know yet"); CMYK scope (real CMYK with black generation, or palettes only); the overprint model; how much palette UI (compact panel, see `G-ui-density`). Matt's prepress app is the reference for what it offers.
4. **Per-plate parameters:** one param set per plate on a single module (many dials), or one module instance per plate. Tagged-texture inputs (`P-mod-textures`) could drive mottle or misregistration.
5. **Mottle:** one `f_ink` feature, or a shared `f_util_mod_texture`-style generator other stages can use?
6. **`f_screen` and `f_dither_grain`:** fold together, share a cell core, or stay separate? Matt: "maybe, let's discuss". Whether this build system can share code between modules is unverified.
7. **Oriented marks (tentative above):** is it right that `f_screen` stays fixed-angle and all form-following marks go to the tensor family?
8. **Stage 3 scope:** static only first, with bleed over time a later stateful module, or both from the start?

## Gates this touches (scanned `.specify/gates.md`; none cleared or reopened)

- `G-tensor-t3`: the line module would be a new tensor consumer; it does not change the open tier-3 items.
- `G-ui-density`: per-plate params make a dense panel, a test case for the UI-density conversation.
- `G-menu`: new modules need a category and menu entries; wait on or ride the redesign.
- `P-mod-textures`: touched only if per-plate params or `f_ink` drivers use tagged textures (questions 4 and 5).
