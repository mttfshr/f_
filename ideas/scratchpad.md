# f_ — Scratchpad

Active loose threads, open questions, and half-formed notes. When an idea has enough shape to stand alone, graduate it to a dedicated `ideas/` file.

---

## f_chladni_audio: spectral normalization

**Problem:** Amplitude-based bandpass processing means m0/m1 always saturate before m6/m7 get any signal. High bands are starved for any normal audio material.

**Solution:** Normalize per-frame so modes reflect spectral *shape* not *level*. Divide each band's envelope by total power (or max band) before outputting m0amp–m7amp. Quiet and loud signals produce the same modal distribution — only timbre matters.

**Alternatives:**
- Peak-normalize: scale all bands relative to loudest band each frame
- Spectral flux: drive from rate-of-change per band (transients become the signal)

**Where to implement:** In f_chladni_audio, after the slide~ envelopes and before the *~ gain stage. Relevant to the f_vf_chladni refactor pass.

---

## f_mobius: performance gap

Feels like it does a specific and somewhat limited thing in practice. Not clear how to incorporate it into a chain or what to pair it with. May be missing one or two params that would open up the useful range. Revisit after some performance use — look at what the transform space actually exposes and whether there are handles (animation-friendly params, modulation targets) that aren't currently surfaced.

---

## Low-frequency drift moiré → f_moire concept

Discovered during f_masonry development: when the continuous drift hash uses a low frequency multiplier and angle is non-orthogonal, the hash field produces large-scale moiré/interference patterns. Wrong for masonry, but interesting as its own thing — a dedicated `f_moire` patch where interference is the point. Parameters: two frequency fields, their angle relationship, phase offset, animation speed. Not yet ready to graduate.

---

## Texture-as-structural-modulation: per-patch opportunities

The highest-leverage texture inlet targets are structural parameters (phase, geometry, selection), not appearance.

- **Phase fields** — any patch with periodic structure: f_droste's spiral phase, f_grain's cell hash offset, f_weave's band timing
- **Symmetry/transformation parameters** — f_droste's `twist` or f_mobius's coefficients driven by texture field
- **Threshold/gating parameters** — f_grain luma gating, f_luma_processor selection windows
- **f_chladni** — texture-driving mode frequencies or damping would produce hybrid standing-wave/field behavior

---

## Generative face / figure — concept

Tribal, fauvist, outsider art — masks, faces, figures that are simultaneously organic and mathematically structured.

**Key insight:** may not require a dedicated patch at all. If f_vecfield supports multiple fixed points, features emerge from attractor geometry — an eye is a spiral sink at a position, a mouth is a saddle along a horizontal axis. The face is the topology of the displacement field, not something drawn. This makes the face idea downstream of multi-fixed-point vecfield work (f_vf_vortex_multi). See `ideas/f_vecfield.md`.

---

## Color theming via Max styles system

Max's built-in styles system could let f_ ship a named style (`f_default`) and let users recolor bpatchers or reset to default. Objects would reference the style by name rather than having colors baked into JSON.

**What needs auditing:** whether current f_ objects already have style slots set or have baked colors. Which color slots are semantically meaningful. Whether `jsui` objects can read the active style programmatically.

**Status:** idea only. Worth establishing before module count grows further, but currently all colors are baked.

---

## f_dither: parametric dither processor

Handles transition gradients in posterized/quantized textures. Sits naturally after f_tone_curve or any quantizing processor. Two dither source modes: internal hash-based (with shape/scale control param) or external pattern inlet (e.g. f_stipple). Clean fit with the existing library — stipple-driven dither especially interesting.


---

## f_vf_potential: scalar potential field integrator

**Context:** Emerged from f_weave Phase 2 work. The vecfield inlet in f_weave steers
local line orientation per-pixel, which works well for gentle deflection but can't
produce coherent curved lines across the frame (fingerprint/isoline character). True
isoline structure requires lines to be isolines of a scalar potential field — the
integral of the vecfield.

**What it is:** A vecfield processor that integrates an input vecfield into a scalar
potential texture (float32 single-channel). The potential value at each pixel represents
the accumulated "depth" along field lines from some reference. Isolines of this field
are the coherent curved paths that vecfield-driven f_weave would follow.

**Architecture:** Ping-pong feedback (same pattern as f_vf_advect). Each frame
accumulates `scalar += dot(field_xy, march_direction)` along a consistent marching
direction. Converges quickly for well-behaved fields (vortex: a few passes). For
vortex specifically, `atan2(y - cy, x - cx)` is the analytic potential — could be
a fast-path mode with no iteration needed.

**Integration with f_weave:** f_weave v2 would have an optional `across` inlet
(float32 scalar). When connected, this replaces the internal
`fract(across * density_scale)` with the potential field directly — lines become
isolines of the potential. Chain: `f_vf_vortex → f_vf_potential → f_weave`.

**Relation to cymascope:** Same ping-pong architecture as the FDTD wave simulation
proposed for f_cymascope. Both confirm that f_vf_advect's feedback pattern is the
general solve for multipass GPU computation in Vsynth.

**Status:** Idea. Graduate to dedicated file when ready to spec.

---


## f_vf_lic: Line Integral Convolution streamline renderer

**Context:** Emerged from f_vf_potential experiment 2026-06-25. The desired visual is
a weather-map wind direction layer — streamlines that follow the field direction
continuously across the frame, like wind barbs or ocean current visualization.

**What it is:** LIC (Line Integral Convolution) is a technique that produces streamline
textures by convolving a noise texture along field-direction paths. Each pixel's value
is the weighted average of a noise field sampled along the streamline passing through
that pixel. The result is a texture where structure is aligned along field lines
everywhere — classic wind map / fluid flow visualization character.

**Architecture:** Ping-pong multipass. Each pass traces one step along the field
direction, accumulating a blurred noise texture along the path. Requires:
- A white noise source texture (can be generated analytically from a hash)
- N passes of short-step accumulation along field direction
- Normalization pass

Alternatively: advect a noise texture along the field with fast decay — gives
approximate streamline character without true LIC, cheaper, might be sufficient
for performance use.

**Distinction from f_vf_potential:**
- f_vf_potential produces isolines (lines perpendicular to field — like pressure
  contours on a weather map)
- f_vf_lic produces streamlines (lines parallel to field — like wind direction arrows)

**Relation to existing modules:** f_vf_advect with a noise source and fast decay
is a crude approximation. A proper LIC module would be a cleaner, more controllable
version of that character.

**Status:** Idea only. Capture before building f_vf_potential.

