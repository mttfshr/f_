# Vsynth Module Inventory

**Status:** Skeleton — not yet populated. Reading pass planned; see HANDOFF.md.

**Purpose:** Flat reference of every Vsynth module with type, tier, inlet/outlet count, and one-line description. The capability map for f_ design: answers "does Vsynth already do X?"

**Tier definitions:**
- **Tier 1** — single-pass, stateless. No frame memory, no ping-pong. Pure shader.
- **Tier 2** — multi-pass, no frame memory. Multiple gl contexts or passes per frame, but no state between frames.
- **Tier 3** — ping-pong / frame-to-frame state. Reads previous frame output as input to current frame. Required for feedback, filtering, reaction-diffusion, etc.

**Note on vector subsystem:** Vsynth includes a parallel vector output subsystem (`patchers/vector/`) for XY oscilloscope-style output. f_ operates entirely in the raster domain. Vector modules are listed here for completeness but not analyzed in depth — relevant only if oscilloscope output becomes part of performance work.

---

## Reading priority for first analysis pass

Determined from directory inventory 2026-05-31. Read in this order:

1. `patchers/vs_public_variables.txt` — send/receive namespace; likely yields vocabulary doc skeleton directly
2. `patchers/abstractions/` (all ~15 files) — core internal abstractions; yields vocabulary + pattern library
3. `code/vs_wfg_sine.genjit` + `code/vs_wfg3.genjit` — canonical WFG gen implementations; codebox patterns
4. `patchers/vs_feedback.maxpat` + `patchers/vs_displacement.maxpat` — Tier 3 architecture
5. `patchers/vs_render.maxpat` — understand what the render system actually does

Blend modes (`code/vs_bm_*.genjit`) and math operators (`code/vs_op*.genjit`) are lower priority — their existence and function are already known from the capability map perspective.

---

## Sources

| Module | Tier | Notes |
|--------|------|-------|
| `vs_sources/sources_cam` | — | Camera input |
| `vs_sources/sources_color` | — | Solid color generator |
| `vs_sources/sources_movie` | — | Movie file playback |
| `vs_sources/sources_noise` | — | Noise generator |
| `vs_sources/sources_oscillator` | — | Oscillator source |

## WFG Family

| Module | Tier | Notes |
|--------|------|-------|
| `vs_wfg_2` | — | |
| `vs_wfg_3` | — | |
| `vs_wfg_av` | — | Audio-video WFG |
| `vs_wfg_bipolar` | — | |
| `vs_wfg_polarizer` | — | |
| `vs_wfg_rad` | — | Radial WFG |
| `vs_wfg_s` | — | |
| `vs_wfg_shapes` | — | Shape-based WFG |
| `vs_wfg_tri_core` | — | |

*Gen implementations in `code/`: `vs_wfg_sine`, `vs_wfg_pulse`, `vs_wfg_saw`, `vs_wfg_ramp`, `vs_wfg_trig`, `vs_wfg_empty`, `vs_wfg3`, `vs_wfg3_pow`. Radial variants: `vs_radial_<waveform>_<circle|sp1|sp2>` (15 files). Shape variants: `vs_shapes_<waveform>_<shape>` (36 files).*

## LFO

| Module | Tier | Notes |
|--------|------|-------|
| `vs_lfo` | — | |

*Gen implementations in `code/`: `vs_lfo_sin`, `vs_lfo_pulse`, `vs_lfo_ramp`, `vs_lfo_saw`, `vs_lfo_trig`, `vs_lfo_empty`.*

## Processors — Geometry / UV

| Module | Tier | Notes |
|--------|------|-------|
| `vs_displacement` | — | Core displacement; likely Tier 3 |
| `vs_offset` | — | |
| `vs_offset+rot` | — | Offset + rotation |
| `vs_cartopol` | — | Cartesian → polar |
| `vs_poltocar` | — | Polar → cartesian |
| `vs_fish_eye` | — | |
| `vs_flip&swap` | — | |
| `vs_pixelator` | — | |
| `vs_pixelator_2` | — | |
| `vs_pixelator_nonSquare` | — | |

## Processors — Color

| Module | Tier | Notes |
|--------|------|-------|
| `vs_colorizer` | — | |
| `vs_colorizer_2` | — | |
| `vs_cos_palettes` | — | Cosine palette colorizer |
| `vs_hsl_modulator` | — | |
| `vs_hue_rot` | — | |
| `vs_huemod_2` | — | |
| `vs_inverter` | — | |
| `vs_rgb_mixer` | — | |
| `vs_rgb_offstr` | — | RGB offset/stretch |
| `vs_rgb_swiz` | — | RGB swizzle/remap |
| `vs_rgb2luma` | — | |
| `vs_rgb2sepia` | — | |
| `vs_rgb2yuv` | — | |
| `vs_transfer_curves` | — | |
| `vs_duotoner` | — | |
| `vs_wavefolder` | — | |

## Processors — Keying / Compositing

| Module | Tier | Notes |
|--------|------|-------|
| `vs_alpha_blend` | — | |
| `vs_alpha_blend_2` | — | |
| `vs_chroma_key` | — | |
| `vs_clr_xtrct` | — | Color extract/isolate |
| `vs_comparator` | — | |
| `vs_crssfade` | — | Crossfade |
| `vs_fader` | — | |
| `vs_luma_key` | — | |
| `vs_quad_crossfader` | — | |
| `vs_vca` | — | VCA-style level control |

## Processors — Mixing

| Module | Tier | Notes |
|--------|------|-------|
| `vs_mixer_3` | — | 3-channel mixer |
| `vs_mixer_3_avg` | — | |
| `vs_mixer_6` | — | 6-channel mixer |
| `vs_mixer_fdbk` | — | Feedback mixer |
| `vs_mixer_spat` | — | Spatial mixer |
| `vs_mixer_spat2` | — | |
| `vs_blendmode_mixer` | — | |

*Blend mode gen implementations in `code/vs_bm_*.genjit`: absdiff, add, alpha, avg, exclude, max, min, mod, mult, negate, screen, sub (13 modes).*

## Processors — Filtering / Temporal

| Module | Tier | Notes |
|--------|------|-------|
| `vs_filter_hp4x` | — | High-pass, 4× |
| `vs_filter_lp2x` | — | Low-pass, 2× |
| `vs_filter_lp4x` | — | Low-pass, 4× |
| `vs_filter_spat` | — | Spatial filter |
| `vs_filter_temp` | — | Temporal filter; likely Tier 3 |
| `vs_frame_delay` | — | Frame delay; likely Tier 3 |
| `vs_convolve` | — | |
| `vs_degrader` | — | |
| `vs_dither` | — | |
| `vs_edges` | — | Edge detection |
| `vs_differentiator` | — | Frame differencing; likely Tier 3 |

## Processors — Math / Signal

| Module | Tier | Notes |
|--------|------|-------|
| `vs_op1` | — | 1-input math op (selectable) |
| `vs_op2` | — | 2-input math op (selectable) |
| `vs_3bandsplit` | — | |
| `vs_band_splitter` | — | |
| `vs_s&h` | — | Sample and hold |
| `vs_s&h_spat` | — | Spatial S&H |

*Math op gen implementations in `code/`: `vs_op<waveform>` (1-input) and `vs_op2<waveform>` (2-input): add, comp1, comp2, div, inv, max, min, mult, pass, subs.*

## Feedback / State

| Module | Tier | Notes |
|--------|------|-------|
| `vs_feedback` | 3 | Two jit.gl.pix instances in vsynth context; draw order creates frame memory. No CPU readback. `@type char` on feedback path (8-bit quantization intentional). |
| `vs_envelope` | — | |
| `vs_envelope_follower` | — | |
| `vs_chemical_osc` | — | Reaction-diffusion; likely Tier 3, same two-pix pattern |

## Audio

| Module | Tier | Notes |
|--------|------|-------|
| `vs_audio2video` | — | Audio → texture |

## Analysis / Metering

| Module | Tier | Notes |
|--------|------|-------|
| `vs_scope` | — | |

## System / Infrastructure

| Module | Tier | Notes |
|--------|------|-------|
| `vs_render` | — | Render context owner — priority read |
| `vs_modules` | — | Module layout system |
| `vs_sync` | — | Sync utilities |
| `vs_sync_time` | — | Tempo/time sync |
| `vs_output` | — | Output / cornerpins routing |
| `vs_preview` | — | Preview window |
| `vs_preview_floating` | — | |
| `vs_snapshot` | — | |
| `vs_snapshot_2` | — | |
| `vs_capture` | — | |
| `vs_syphon_client` | — | |
| `vs_syphon_server` | — | |
| `vs_spout_client` | — | |
| `vs_spout_server` | — | |

## Vector Subsystem (not analyzed)

Separate output domain — XY oscilloscope-style output, not raster texture. f_ operates entirely in the raster domain. ~20 modules in `patchers/vector/`. To be analyzed only if oscilloscope output becomes relevant to performance work.

---

*Populated: 2026-05-31 (skeleton from directory inventory; first analysis pass complete — vs_public_variables, abstractions, vs_wfg_sine, vs_wfg3, vs_feedback partial, vs_render partial)*
*Last updated: 2026-05-31*
