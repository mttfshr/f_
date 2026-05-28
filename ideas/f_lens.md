# f_lens — Idea File

_Started: 2026-05-27_
_Status: Brainstorm — not yet specced_

---

## Origin

Not primarily about optical physics accuracy. The goal is **evocativeness** — the visual quality of looking through imperfect glass, the filmic register of 20th century cinema and home Super-8, the specific experience of light passing through a physical medium that has character and imperfection.

Sources of inspiration:
- B&W photography, darkroom, photograms
- Lens artifacts in 20th century film — flare, aberration, bloom as part of the composition rather than errors to correct
- Inter-reflections in eyeglasses: ghost images in peripheral vision, displaced and attenuated, slightly color-shifted
- Looking into darkness through a pane of glass — double and triple repeats of bright sources
- The mediated quality of seeing through something

The physics is a reference point, not the destination.

---

## Core Abstraction

A lens sits between the image and the eye. It doesn't need to know what it's imaging — it operates on UV space and pixel values. No 3D scene, no light source simulation, no camera model required.

Any f_ output is a valid source for in2 or in3 — f_grain for organic surface noise, f_chladni for modal imperfections, f_stereo for something stranger. Routable via vs_texrouter for live material swapping.

---

## Inlets

**in1** — the image being seen through the lens

**in2** — surface texture: describes the lens as a physical material. Drives dust and coating variation, transmission falloff character, reflection and inter-reflection intensity map. Wants to be fine-grained and relatively static — f_grain is a natural source.

**in3** — field texture: describes how the lens deforms space. Drives local distortion variation and focus field deviation (where the focal plane is non-flat). Wants to be smoother and possibly animated — f_chladni, slow noise, or LFO-driven sources.

The two-texture split reflects a real distinction: in2 is about the lens as a material object, in3 is about the lens as a spatial transformer. These would plausibly be driven by completely different sources and changed independently.

Note: UI parameter selection is deliberately deferred until f_lens is being used in actual chains. The right controls will emerge from patching context, as with f_grain.

---

## What a Lens Does (Experientially)

- **Gathers** — pulls light from a region into a point, or spreads a point across a region
- **Shifts** — displaces different parts of the image differently (more at edges, per-channel variation)
- **Selects** — some things are sharp, some soft; that boundary is the lens's decision
- **Leaks** — light from bright sources bleeds, reflects between surfaces, scatters

All of these are UV-space and pixel-value operations. None require a 3D scene.

---

## Parameter Families

### Radially Symmetric (optical axis effects)
These treat the center as special and fall off radially outward:

- `focus` — gather vs spread; center sharp vs edge sharp
- `aberration` — per-channel UV offset scaling from center (lateral chromatic aberration)
- `distortion` — barrel vs pincushion (the shape of the UV warp itself)
- `transmission` — brightness/color falloff toward edges (vignette with character, possibly color-shifted)

### Axially Asymmetric (tilt and anamorphic)
These break rotational symmetry and impose a directionality:

- `tilt` — rotates the focal plane so sharpness becomes a diagonal band rather than a uniform field
- `tilt_axis` — the angle of the sharp band across the frame
- `tilt_width` — width of the in-focus band
- Anamorphic stretch — directional distortion on one axis; characteristic of widescreen cinema lenses. Oval bokeh, horizontal flare character.

Axially asymmetric effects make the viewer aware of the frame and the axis — very cinematic quality.

### in2-Driven (lens material / surface)
Modulated by in2, making character non-uniform across the lens:

- Local distortion variation — organic, hand-ground lens feel vs uniform barrel/pincushion
- Reflection intensity map — where inter-reflections appear and how bright
- Dust and coating variation — non-uniform transmission falloff
- Focus variation — focal plane deviations

### in3-Driven (lens field / space)
Modulated by in3, making spatial deformation non-uniform:

- Local distortion variation separate from material character
- Focus field deviation — where the focal plane bends

---

## Inter-Reflection / Ghost Images

A distinct sub-effect. Light bouncing between parallel glass surfaces arrives at the eye displaced and attenuated — a cascade of ghost copies:

- Bright source → ghost at ~70% brightness, offset → ghost at ~50%, further offset → ghost at ~30%
- Each step: same direction offset, same attenuation factor, slight color shift
- Reads as mysterious — the "you are looking through something" signal

In shader terms: additive superposition of the source sampled at progressively offset and attenuated UV coordinates.

Parameters: `ghost_count`, `ghost_offset` (direction + magnitude), `ghost_attenuation` (per step), `ghost_color_shift` (per step)

This might be its own bpatcher (`f_interreflect`?) or a parameter cluster within f_lens.

Connection: the ghost artifact in f_stereo when sweeping lat/lon may be related to this phenomenon.

---

## Filmic Register Notes

The effects that feel most alive in this territory:

- **Lumia** — Thomas Wilfred's light-as-performance-medium; slow color and form with no representational content. One of the earliest precedents for this whole project.
- **Bokeh** — shape of out-of-focus regions; aperture shape appears in every bright defocused region. Tractable as a convolution approximation.
- **Halation** — soft additive glow around bright regions, slightly warm/amber color-shifted. Very distinct from digital bloom.
- **Chemical staining** — cameraless film, lumen prints. Painterly, not photographic.
- **Glass ripple distortion** — organic displacement; sits between coordinate-space transform and optical effect.
- **Caustics through imperfect or thick glass / water** — evocative quality of focused light through an imperfect medium.
- **Anamorphic lens flare** — horizontal streaks, characteristic of widescreen cinema.

---

## Open Questions

- Does inter-reflection want to be part of f_lens or its own bpatcher (`f_interreflect`)?
- Anamorphic: too specific a reference, or worth including?
- What's the right default state — barely-there (subtle) or obvious character?
- Relationship to f_flare, f_caustic, f_diffraction from scratchpad — do those fold into f_lens or stay separate?

---

## Status

Brainstorm only. No codebox, no build script, no spec yet. Graduate to `.specify/f_lens/` when the parameter contract feels settled.
