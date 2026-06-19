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

## f_masonry: open questions

### mod matrix UI — tex A asymmetry
Tex A (in2) is the only inlet that can modulate structural params (offset, drift, speed_var, phase, regularity, skip, quantize). Tex B and C are appearance-only. This asymmetry is architecturally correct but not visible in the UI.

Options (not decided):
- Visual distinction in the grid (dimmed rows for B/C on structural params)
- Restructure grid into two sections: structural (A only) / appearance (A+B+C)
- Accept as-is and document

**Deferred — not a blocker.**

### Continuous drift hash seam
The `quantize` param continuous drift has a faint diagonal seam at non-zero values. Current codebox uses `1.3` as compromise frequency. Consider revisiting with a 2D hash approach (hashing both `along` and `across` together) to break diagonal coherence.

### Distance field refactor
Masonry's smoothstep boundary approach is the root cause of masonry→droste aliasing. A distance field refactor would fix this. f_weave is being written distance-field-native as the proof of concept — a working weave→droste chain is the validation before attempting the masonry refactor. See `ideas/f_weave.md`.

---

## Mod matrix interaction model

Context: f_masonry shipped with mod matrix (back panel) + context strip (front panel). Strip shows A/B mod amounts for the last-touched dial. Core problem: `live.dial` doesn't expose mousedown — only value change. Strip shows last *changed* param, not last *touched*. Friction in performance.

**Key insight:** The focus/strip problem is downstream of showing a *subset* of state. A table or compound-cell grid showing all state simultaneously resolves it. See `ideas/f_util_compound_dial.md` and UI density discovery workstream.

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

## f_magic_eye: autostereogram generator/processor

Two inlets: depth/mask texture (shape) + pattern texture (e.g. from f_stipple or f_grain). Outputs a SIRDS-style autostereogram. Core algorithm: horizontal pixel shift driven by depth map, pattern tiled as repeating strip.

**Open question:** the standard SIRDS algorithm has a left-to-right feedback dependency (each pixel's output depends on the pixel N columns left of it). This conflicts with jit.gl.pix's parallel execution model — needs investigation before committing to a scratch patch. May require a multi-pass approach or a CPU fallback.

---

## f_dither: parametric dither processor

Handles transition gradients in posterized/quantized textures. Sits naturally after f_tone_curve or any quantizing processor. Two dither source modes: internal hash-based (with shape/scale control param) or external pattern inlet (e.g. f_stipple). Clean fit with the existing library — stipple-driven dither especially interesting.

---

## Extracted to dedicated files

- `f_util_compound_dial` → `ideas/f_util_compound_dial.md`
- `f_util_audio_spectra` → `ideas/f_util_audio_spectra.md`
- `f_vecfield` + feedback chain vocabulary → `ideas/f_vecfield.md`
- Vsynth capability gaps → `ideas/vsynth_gaps.md`
- Weave collision events → `ideas/f_weave.md`
- `f_util_profile` → `ideas/f_util_analysis.md`
- `f_cymascope` → `ideas/f_cymascope.md`
- Droste singularity → `ideas/droste_singularity.md`
