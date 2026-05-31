# Vsynth Module Inventory

**Status:** Analysis complete — all priority modules read, 2026-05-31.

**Purpose:** Flat reference of every Vsynth module with type, tier, inlet/outlet count, and one-line description. The capability map for f_ design: answers "does Vsynth already do X?"

**Tier definitions:**
- **Tier 1** — single-pass, stateless. No frame memory. Pure shader.
- **Tier 2** — multi-pass within one frame, no frame-to-frame state. (Not yet observed in Vsynth.)
- **Tier 3** — frame-to-frame state. Reads previous frame output as input to current frame. Implemented via multiple `jit.gl.pix vsynth` instances whose draw order creates the temporal relationship — no CPU readback required.

**Note on vector subsystem:** Vsynth includes a parallel vector output subsystem (`patchers/vector/`) for XY oscilloscope-style output. f_ operates entirely in the raster domain. Listed here for completeness; not analyzed.

---

## Sources

| Module | Tier | Notes |
|--------|------|-------|
| `vs_sources/sources_cam` | 1 | Camera input |
| `vs_sources/sources_color` | 1 | Solid color generator |
| `vs_sources/sources_movie` | 1 | Movie file playback |
| `vs_sources/sources_noise` | 1 | Noise generator |
| `vs_sources/sources_oscillator` | 1 | Oscillator source |

---

## WFG Family

| Module | Tier | Notes |
|--------|------|-------|
| `vs_wfg_3` | 1 | **3 inlets:** FM In/Control In, PM In, PWM In. **2 outlets:** Texture Out, Inverted Texture Out. `@type float32`. Gen swappable: `vs_wfg3.genjit` / `vs_wfg3_pow.genjit`. `vs_bline` on freq, fm, pm, speed, bias. `vs_range` on freq (0–1020 / 0–10000), fm, pm. `vs_newTime` for animation. `vs_inState` on FM, PM, PWM inlets. `vs_canvas` for global enable. |
| `vs_wfg_2` | 1 | Earlier WFG variant |
| `vs_wfg_av` | 1 | Audio-video WFG — audio signal drives waveform |
| `vs_wfg_bipolar` | 1 | Bipolar output variant |
| `vs_wfg_polarizer` | 1 | |
| `vs_wfg_rad` | 1 | Radial WFG — output radiates from center |
| `vs_wfg_s` | 1 | |
| `vs_wfg_shapes` | 1 | Shape-masked WFG |
| `vs_wfg_tri_core` | 1 | |

*Gen implementations in `code/`: 6 waveforms (sine, pulse, saw, ramp, trig, empty) × base + wfg3 + wfg3_pow. Radial variants: `vs_radial_<waveform>_<circle|sp1|sp2>` (15 files). Shape variants: `vs_shapes_<waveform>_<shape>` (36 files).*

---

## LFO

| Module | Tier | Notes |
|--------|------|-------|
| `vs_lfo` | 1 | CPU-side LFO; 6 waveforms via gen. |

---

## Processors — Geometry / UV

| Module | Tier | Notes |
|--------|------|-------|
| `vs_displacement` | 1 | **5 inlets:** primary texture + fmx, fmy, angle_m, zoom_m (each via `vs_inState`). Displacement field in polar space (`poltocar`). Texture modulation remapped [0,1]→[-1,1]. Params: zoom, angle, x/y offset, bound mode (Clear/Clamp/Wrap/Mirror), polar/bipolar mode. `vs_bline` on x, y, zoom. |
| `vs_offset` | 1 | XY pixel offset |
| `vs_offset+rot` | 1 | Offset + rotation |
| `vs_cartopol` | 1 | Cartesian → polar UV transform |
| `vs_poltocar` | 1 | Polar → cartesian UV transform |
| `vs_fish_eye` | 1 | Fisheye distortion; aperture param |
| `vs_flip&swap` | 1 | Flip x/y axes, channel swap |
| `vs_pixelator` | 1 | Pixelation / blocky downscale |
| `vs_pixelator_2` | 1 | |
| `vs_pixelator_nonSquare` | 1 | Non-square pixel variant |

---

## Processors — Color

| Module | Tier | Notes |
|--------|------|-------|
| `vs_colorizer` | 1 | Color tint; hue + rgba |
| `vs_colorizer_2` | 1 | Extended: hue, sat, light, pedestal, modulation |
| `vs_cos_palettes` | 1 | Cosine palette colorizer; 4 preset palettes, animatable |
| `vs_hsl_modulator` | 1 | HSL with modulation inputs |
| `vs_hue_rot` | 1 | Hue rotation |
| `vs_huemod_2` | 1 | Hue + saturation modulation |
| `vs_inverter` | 1 | Invert (parametric: -1 to 1) |
| `vs_rgb_mixer` | 1 | Per-channel RGB level mix |
| `vs_rgb_offstr` | 1 | RGB offset and stretch |
| `vs_rgb_swiz` | 1 | RGB channel swizzle/remap |
| `vs_rgb2luma` | 1 | RGB to luminance |
| `vs_rgb2sepia` | 1 | RGB to sepia |
| `vs_rgb2yuv` | 1 | RGB to YUV color space |
| `vs_transfer_curves` | 1 | Transfer curve adjustment |
| `vs_duotoner` | 1 | Two-color toner; threshold + smooth |
| `vs_wavefolder` | 1 | Wavefolding on luma |

---

## Processors — Keying / Compositing

| Module | Tier | Notes |
|--------|------|-------|
| `vs_alpha_blend` | 1 | **3 inlets:** Blacks In, Whites In, Alpha Texture In. Alpha channel of 3rd texture drives blend. |
| `vs_alpha_blend_2` | 1 | Mode toggle + threshold/smooth variant |
| `vs_chroma_key` | 1 | Color-based keying; threshold, smooth, color picker |
| `vs_clr_xtrct` | 1 | Color extract/isolate |
| `vs_comparator` | 1 | Threshold comparison op |
| `vs_crssfade` | 1 | 2-inlet crossfade |
| `vs_fader` | 1 | Level control |
| `vs_luma_key` | 1 | **2 inlets.** Luma-based keying with threshold and smooth |
| `vs_quad_crossfader` | 1 | XY joystick-controlled 4-source crossfade |
| `vs_vca` | 1 | VCA-style amplitude control; bias + AM |

---

## Processors — Mixing

| Module | Tier | Notes |
|--------|------|-------|
| `vs_mixer_3` | 1 | 3-input weighted mix. Per-channel level + master. `@adapt 0 @type char`. |
| `vs_mixer_3_avg` | 1 | 3-channel average mix |
| `vs_mixer_6` | 1 | 6-input weighted mix |
| `vs_mixer_fdbk` | 3 | Feedback mixer — mixes current input with fed-back output |
| `vs_mixer_spat` | 1 | Spatial mixer — position-modulated mix |
| `vs_mixer_spat2` | 1 | Spatial mixer variant |
| `vs_blendmode_mixer` | 1 | 2-input with 13 selectable blend modes. Gen file swapped at runtime via `@gen filename`. |

*13 blend modes via `code/vs_bm_*.genjit`: absdiff, add, alpha, avg, exclude, max, min, mod, mult, negate, screen, sub. Selected by swapping `@gen` filename at runtime.*

---

## Processors — Filtering / Temporal

| Module | Tier | Notes |
|--------|------|-------|
| `vs_filter_hp4x` | 1 | High-pass spatial filter, 4× |
| `vs_filter_lp2x` | 1 | Low-pass spatial filter, 2× |
| `vs_filter_lp4x` | 1 | Low-pass spatial filter, 4× |
| `vs_filter_spat` | 1 | Spatial filter with response modes |
| `vs_filter_temp` | 3 | Temporal filter (attack/release). Multiple `jit.gl.pix vsynth` instances including `@type char` slide pix. Draw-order frame-memory pattern. |
| `vs_frame_delay` | 3 | Frame delay buffer. Uses `jit.gl.textureset.js` — JS-managed explicit texture set. Different from two-pix draw-order; supports longer delays. xfade param. |
| `vs_convolve` | — | |
| `vs_degrader` | 1 | Resolution degradation |
| `vs_dither` | 1 | Dithering |
| `vs_edges` | 1 | Edge detection; freq, threshold, smooth |
| `vs_differentiator` | 3 | Frame differencing; reads previous frame |

---

## Processors — Math / Signal

| Module | Tier | Notes |
|--------|------|-------|
| `vs_op1` | 1 | 1-input math op (add, mult, div, inv, comp1, comp2, pass, subs) |
| `vs_op2` | 1 | **2 inlets.** 2-input math op (same set + max, min) |
| `vs_3bandsplit` | 1 | 3-band frequency split |
| `vs_band_splitter` | 1 | Band splitter |
| `vs_s&h` | 1 | Sample and hold |
| `vs_s&h_spat` | 1 | Spatial sample and hold |

*Math op gen implementations in `code/`: `vs_op<type>` (1-input) and `vs_op2<type>` (2-input): add, comp1, comp2, div, inv, max, min, mult, pass, subs.*

---

## Feedback / State

| Module | Tier | Notes |
|--------|------|-------|
| `vs_feedback` | 3 | Two `jit.gl.pix vsynth` instances; draw order creates frame memory. `@type char` on feedback path. Feedback codebox: `mix(in1, max(in1, in2), amt)`. `vs_bline` on amt. |
| `vs_envelope` | — | |
| `vs_envelope_follower` | — | |
| `vs_chemical_osc` | 3 | Reaction-diffusion. **8 `jit.gl.pix vsynth` instances** — Vsynth's most complex Tier 3 module. Named passes: slide (attack/release), hue+sat, two blur passes, rota (rotation/zoom/offset), additional signal processing. Full multi-pass pipeline in a single named GL context. |

---

## Audio

| Module | Tier | Notes |
|--------|------|-------|
| `vs_audio2video` | 1 | Audio signal → texture |

---

## Analysis / Metering

| Module | Tier | Notes |
|--------|------|-------|
| `vs_scope` | — | Oscilloscope/waveform display |

---

## System / Infrastructure

| Module | Tier | Notes |
|--------|------|-------|
| `vs_render` | — | Render context owner; qmetro, GL context, fps |
| `vs_modules` | — | Module layout and sizing system |
| `vs_sync` | — | Sync utilities |
| `vs_sync_time` | — | Tempo/time sync; exposes `r time` |
| `vs_output` | — | Output / cornerpins routing to display |
| `vs_preview` | — | Preview window |
| `vs_preview_floating` | — | Floating preview |
| `vs_snapshot` | — | State snapshot |
| `vs_snapshot_2` | — | |
| `vs_capture` | — | Video capture |
| `vs_syphon_client` | — | Syphon texture input |
| `vs_syphon_server` | — | Syphon texture output |
| `vs_spout_client` | — | Spout texture input (Windows) |
| `vs_spout_server` | — | Spout texture output (Windows) |

---

## Vector Subsystem (not analyzed)

Separate output domain — XY oscilloscope-style output, not raster texture. f_ operates entirely in the raster domain. ~20 modules in `patchers/vector/`. Analyze only if oscilloscope output becomes part of performance work.

---

*Populated: 2026-05-31 (analysis complete — all priority modules read)*
*Last updated: 2026-05-31*
