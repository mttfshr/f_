# f_vf_prism — continuity doc
# Session: 2026-06-20

## What this module is supposed to do

Prismatic spectral dispersion driven by a vecfield. Bright areas (above a luma
threshold) cast separated R/G/B color bands displaced along the field direction,
like light passing through a prism or crystal — wavelength-dependent spatial
separation. Each channel lands at a slightly different position, giving clean
spectral bands rather than a blended rainbow.

Reference images: crystal light leaks, prism dispersion on surfaces, long-exposure
bokeh streaks with RGB fringing.

## Origin

Forked from f_vf_chroma (2026-06-20) after the vortex field experiment revealed
a perspectival depth/light character that suggested a different optical model
entirely. f_vf_chroma continues as a separate streak/rainbow processor.

## Key optical insight

The effect is NOT about painting a gradient along a streak. It's about each
wavelength (channel) landing at a spatially distinct position. Each output pixel
asks: "is there a bright emitter at MY displaced position?" independently per
channel. The gate is at the sample position, not the current pixel.

This is an inverse lookup — three independent UV displacements, one per channel,
each rotated slightly off-axis from the field direction. The angular spread between
channels determines the width of the chromatic separation.

## Architecture (v1)

Three UV lookups:
- R: field direction rotated +width radians, displaced by length
- G: field direction, no rotation, displaced by length  
- B: field direction rotated -width radians, displaced by length

Gate: luma smoothstep at each displaced UV (not at current pixel)
Output: per-channel gate value — no hue synthesis, color comes purely from
channel separation

Params: length, width, threshold, threshold_width, strength, bypass
Mod inlets: vecfield (in2), length mod (in3), width mod (in4)

## Version history

### v14 — WORKING (current)
- 11-tap Gaussian blur of gate values perpendicular to field
- step_size normalized to inter-channel separation — feather never extends beyond spread
- Helper functions: displaced_luma(), channel_gate()
- Key insight: blur gate values AFTER threshold, not luma before — keeps blob edges sharp
- Key insight: step_size must scale to actual channel separation, not reach alone
- Params all working: reach, spread, threshold, threshold_width, feather, strength, bypass

### v1–v13 — exploration
- v1-v4: established three-UV angular dispersion architecture (working separation)
- v5-v9: failed attempts at spectral blending via Gaussian weights on gate outputs
- v10-v12: directional blur on luma (wrong — caused omnidirectional shape blur)
- v13: 11-tap version of v12, hit line length silent failure
- v14: blur gate values not luma, functions, correct step_size scaling — works

### v1 — three-UV angular dispersion (archived)
- Clean three-sample architecture, no accumulation loop
- Gate at sample position per channel
- Angular spread between channels via cos/sin rotation of field vector
- No hue synthesis — spectral color emerges from channel separation alone
- Status: written, needs scratch patch test

## Signal flow notes

Two distinct performance modes depending on field source:

- **f_vf_vortex** — convergent streamlines give directional streak spectra, arms
  radiating from a center point. Rainbow runs along the streak direction.

- **f_vf_repulse** — divergent outward field wraps the spectrum around blob contours,
  giving annular/ring spectra. Rainbow follows the shape boundary of each bright region.
  Extraordinary result — each blob gets a full spectral halo.

Both modes are valid and musically distinct. Field source is the primary performance
variable for changing the character of the effect.

- Source: any bright-on-dark texture works; jit.gl.bfg with colorize is good

## Params to tune first

- length: how far each channel is displaced (reach of the effect)
- width: angular spread between R and B (chromatic separation width)
- threshold: gate floor — keep high so only bright sources emit

## Open questions

- Is pure channel-separation (no hue synthesis) sufficient, or do we need to
  weight/tint each channel to get the full prismatic color range?
- Does the rotation direction (R toward positive angle, B toward negative) need
  to be flipped or made param-controllable?
- Should there be a saturation/intensity control on the prism output?
