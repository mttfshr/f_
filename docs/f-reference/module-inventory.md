# f_ Module Inventory

**Status:** Drafted 2026-09-20 from `docs/f-reference/*.md`.

**Purpose:** Flat, load-the-whole-thing capability map for the f_ library — the layer where "does f_ already do X, or does this need a new module?" questions actually get answered. Answer that from this file alone when possible; open the full per-module doc in `docs/f-reference/<module>.md` only for the 1-3 candidates that survive the shortlist. This file intentionally omits algorithm detail, exact param ranges, and build/loose-thread history — that's what the full docs are for.

**Type contracts (read these when composability is the question):**
- [`f_vecfield_type.md`](f_vecfield_type.md) — the shared vector-field texture format (float32, RG=XY, 0.5=zero). Most "can module A feed module B" questions reduce to "does A produce a coherent f_vecfield and does B consume one," not just "are both texture in/out."
- [`discrete_item_conventions.md`](discrete_item_conventions.md) — shared param vocabulary (`density`, `phase`, `size`+`stretch`, `softness`, `shape`) across the grid/mark-placement modules (f_grain, f_masonry, f_weave, f_vf_seeds), including where the same name means different things per module.
- [`f_tensor_type.md`](f_tensor_type.md) — the shared tensor-field texture format (two float32 outlets: raw Jxx/Jxy/Jyy and the packed cos2θ/sin2θ/trace/coherence form) for the f_tf_ family.

**Reading the I/O column:** `tex` = plain texture, `vecfield` = f_vecfield (float32 RG, coherent field — see contract doc), `scalar` = single-channel grayscale signal. `→` separates input(s) from output(s). **temporal** = has frame-to-frame memory (ping-pong feedback), so behavior depends on accumulated history, not just the current frame's inputs.

**See also:** [`docs/vsynth-reference/module-inventory.md`](../vsynth-reference/module-inventory.md) — the same kind of flat capability map, one layer down, for core Vsynth (`vs_`) modules. Check there too before assuming a new f_ module is needed — the answer is sometimes a core Vsynth module (e.g. `vs_displacement` for a dumb two-channel UV push, no field coherence needed).

---

## Color / Tonal Grading

Stateless, texture→texture, no geometric displacement. Reach for these when the effect is about *what color a pixel is*, not *where it samples from*.

| Module | I/O | What it does |
|---|---|---|
| `f_channel_grader` | tex → tex | Per-channel lift/gamma/gain (film-style grade), R/G/B + master |
| `f_hue_processor` | tex → tex | Isolates a hue band (center + asymmetric width + falloff), adjusts sat/lum/hue within it only. Low-sat regions gated out. ⚠ open UI bug on `hue_lower`/`hue_upper` |
| `f_luma_processor` | tex → tex | Isolates a luma range (shadow/mid/high breakpoints), adjusts sat/lum/hue within it only. Structurally parallel to `f_tone_curve` |
| `f_tone_curve` | tex → tex | Shadow/midtone/highlight brightness adjustment by tonal band. Structurally parallel to `f_luma_processor` |

## Geometry / UV Warp

Stateless, remap sampling coordinates rather than color. No vecfield involved — these bend space by a fixed analytic transform (spiral, Möbius, sphere), not a data-driven field.

| Module | I/O | What it does |
|---|---|---|
| `f_droste` | tex → tex | Log-polar spiral transform — infinite-zoom Droste/Escher recursion. `n_arms`, `twist`, continuous zoom/rotation |
| `f_mobius` | tex → tex | Möbius-family UV transform (rotation/zoom blended with complex inversion `1/z`). Circles stay circles, no pinching even at extremes; loxodromic spiral motion in the 0.2–0.8 `invert` range |
| `f_lens` | tex (+4 mod tex) → tex | Multi-effect filmic lens sim: chromatic aberration, barrel/pincushion distortion, vignette, surface-emboss displacement, ghost images, halation, tilt-shift focus, all in one chain. The "physically-evocative lens" module — closest existing thing to a fresnel-style focus/distortion combo. ⚠ bypass incomplete (halation/tiltshift stay live); tilt-shift slated for extraction to a future `f_focus` |
| `f_stereo` | tex → tex (circular) | Wraps a flat texture onto a rotating sphere, projects to a circular disk (ortho↔stereographic blend). **Display-layer** — last processor before a circular screen, not a general effect |
| `f_sirds` | tex (pattern) + tex (depth, optional) → tex | Single-Image Random Dot Stereogram generator — depth map displaces a repeating pattern into an autostereogram. Narrow, specific technique, not a general depth/parallax tool |
| `f_ngon` | tex → tex | Kaleidoscope fold: reflects each pixel into the wedge between two mirror lines at `π/n_mirrors`, giving `2·n_mirrors`-fold symmetry and a regular polygonal outline, with live `n_mirrors` (2–18), `rotation` and `scale`. The neutral setting is not a passthrough (the fold symmetrizes the frame). ⚠ No spec, tier-1 mirror only (never run on the GPU bench); a sampler, with no filled-polygon mask outlet |

## Vecfield Producers

Output a coherent f_vecfield (or, for f_chladni, an f_vecfield alongside other outlets). This is the "what shape is the underlying field" layer — pick one of these first when an effect needs a *structured* directional field (convergence, rotation, flow) rather than plain noise.

| Module | I/O | What it does |
|---|---|---|
| `f_vf_vortex` | (params) → vecfield | Single fixed-point field, continuously variable sink↔spiral↔center↔spiral-source↔source via `convergence`/`curl`. The basic building block of the family |
| `f_vf_vortex_multi` | (params) → vecfield | Three additive vortex sites sharing one falloff — multi-focal version of `f_vf_vortex` |
| `f_vf_fieldmap` | tex (scalar-dominant) → vecfield | Converts *any* scalar/noise texture into a vecfield via spatial gradient (central difference). The generic "turn a texture into a field" adapter — feed it `jit.gl.bfg` noise, grain, luma, anything |
| `f_tf_tensormap` | tex (scalar-dominant) → raw tensor + packed tensor | Structure tensor of any scalar texture (Sobel, box-smoothed outer products, closed-form eigen): raw Jxx/Jxy/Jyy and packed cos2θ/sin2θ/trace/coherence. Outlet 1 is angle-doubled, NOT a vecfield. Cost scales with fixed R_MAX 16, not `radius`
| `f_tf_axisflow` | packed tensor → vecfield | Bridge from `f_tf_tensormap` outlet 1: projects a reference angle onto the edge line (or its normal), so flow follows image structure with no sign seam. Feeds `f_vf_advect`, warp, caustic... Needs `width`/`height` set
| `f_tf_smooth` | raw tensor → raw tensor, **temporal** | One-pole tensor-space smoother ("inertia"): feedback average per component, so opposite axes reinforce instead of canceling and confidence rides along. `release` is the performable knob; bypass is exact passthrough (not a freeze). Chain A's stabilizer stage
| `f_tf_glyph` | raw tensor + tex → tex | Glyph-field renderer: one closed-form ellipse per grid cell, aspect from the eigenvalue ratio, axis from the tensor, gated on trace. Doubles as the family's universal debug view
| `f_tf_sharpen` | raw tensor → raw tensor | Eigengap operator: scales the eigenvalue gap at fixed trace and untouched axis — commits or relaxes anisotropy with one dial. Not image sharpening
| `f_tf_aniso_blur` | raw tensor + tex → tex | Coherence-enhancing smoother: integrates the source along the tensor's major axis, ellipse width from the eigenvalue ratio, isotropic fallback (Weickert rationale). Straight-axis v1
| `f_tf_hatch` | raw tensor → tex (marks) | Orientation-committed hatching: dashes along the decoded axis via distance-field mechanics, mark commitment from coherence (strokes → dots → nothing). 3 stages, ~6 taps/pixel
| `f_vf_flow` | tex (optional) → vecfield | Dual-mode: unconnected = uniform-direction field at `angle`; connected = direction perturbed spatially by input luminance. Built as `f_weave`'s field input |
| `f_vf_repulse` | tex → vecfield | Ring-samples 16 directions around each pixel, accumulates vectors pointing away from (or, with negative gain, toward) bright regions. Texture-shape-driven repulsion/attraction field |
| `f_vf_optical_flow` | tex (video/live) → vecfield + confidence | Real Lucas-Kanade motion estimation between frames — genuine per-pixel motion field from a moving source, with aperture-problem handling. The "derive a field from what's actually moving in the shot" producer |
| `f_vf_fluid` | vecfield (force) → vecfield, **temporal** | Spectral incompressible-flow solver — stir it with any force (video motion, a vortex, a wind) and the resulting swirl persists and evolves after the force stops, with `viscosity` (smoothing), `project` (swirl vs shock), and `drag`. Outputs a velocity field, not an image: feed it to `f_vf_advect`/`warp`/`glow`/`streak`. The "make a field that keeps moving on its own" module. 256² solver regardless of render size; ~2.5 ms/frame on the bench |
| `f_vf_lbm` | tex (obstacle mask) → vecfield, **temporal** | Lattice Boltzmann (D2Q9) channel flow around a mask-shaped obstacle: a steady wind blows left to right, the wake sheds, and the velocity vecfield comes out for advect / warp / streak / glow. Dials: `omega`, Wind, Tilt (±30°), `gain`, Speed (every 1st–4th frame). Fixed 192×108 solver. Shedding takes thousands of frames to start; the flow is a channel (left in, right out, top/bottom wrap). Bypass = neutral vecfield, solver keeps running. Where `f_vf_fluid` stirs a field with any force, this flows *around a shape* |
| `f_chladni` | (params) → luma + vecfield + scalar | Circular-plate Chladni resonance figure (Bessel modes). out2 is a vecfield (gradient toward nodal lines) — an *audio/note-driven* field producer, distinct in character from the geometric vortex family |
| `f_quasi` | (params; optional tex sets the aspect) → banded luma + vecfield + scalar | Shepard-zoom quasicrystal generator: five plane waves over seven octaves, endless zoom with a patcher clock (Z.rate, D.rate), exact bounded gradient as a vecfield, the potential as a scalar. Stateless. Reference: `f_quasi.md` |
| `f_vf_vorticity` | vecfield → vecfield | Vorticity-confinement processor — takes a field, adds back fine swirl its curl implies. Only legible through a temporal consumer (`f_vf_advect`); no visible effect on stateless consumers |

## Vecfield Consumers / Field-Driven Effects

Take a source texture plus an f_vecfield and produce a visual result shaped by the field's geometry. This is where "warp/distort/focus-like-a-lens" questions usually land — the field supplies the *shape* of the distortion, the consumer supplies the *character* (displace, streak, glow, split colors, accumulate).

| Module | I/O | What it does |
|---|---|---|
| `f_vf_warp` | tex + vecfield → tex | Directly displaces UV by the field vector, scaled by `gain` (`mix_pct` crossfades the composite outlet). The simplest field-driven distortion — single-sample, no accumulation |
| `f_caustic` | tex + vecfield → composite + isolated layer | Forward scatter-sheet accumulation along the field (a lattice of field-displaced points deposits additive splats into a float32 capture); brightness builds up in *convergence* zones (negative divergence). This is the module for a lens/fresnel-style focusing effect — bright bands form where the field converges, exactly the optical-caustic behavior a fresnel lens produces |
| `f_vf_streak` | tex + vecfield (optional) → composite + isolated layer | Accumulates samples along the streamline into a directional smear/streak, with chromatic offset option |
| `f_vf_glow` | tex + vecfield → composite + isolated layer | 48-step bidirectional accumulation along the field → anisotropic glow/bloom that follows field geometry (not radially symmetric like a normal bloom) |
| `f_vf_chroma` | tex + vecfield → composite + isolated layer | Field-steered chromatic aberration — R/B channels offset in opposite directions along the *local* field vector (vs. `f_lens`'s aberration, which is always centrifugal from a fixed center) |
| `f_vf_prism` | tex + vecfield → composite + isolated layer + dispersion-direction vecfield | Field-driven RGB channel separation, luma-gated so prism color only appears where bright content meets the field; feather control blends hard-split ↔ spectral gradient |
| `f_vf_advect` | tex + vecfield → composite + isolated layer + vecfield gradient of the accumulated flow, **temporal** | Frame-to-frame fluid advection — injected content spreads/dissipates/(if `decay`>1) amplifies over many frames, not just displaced once. The module to reach for when an effect needs to *build up* over time rather than react per-frame |
| `f_vf_potential` | vecfield (+ optional color tex) → scalar, **temporal** | Integrates field magnitude over time into a 0–1 scalar whose isolines trace the flow. Built specifically to feed `f_weave`'s scalar inlet (curved isoline texture instead of straight lines) |

## Discrete-Item / Procedural Generators

Self-sufficient generators producing structured marks/grains/bricks/lines rather than processing an input image. Share param vocabulary — see `discrete_item_conventions.md`.

| Module | I/O | What it does |
|---|---|---|
| `f_grain` | tex (optional) → composite + grain mask + displaced source, has feedback | Stochastic grain field — per-grain position/size/shape/color driven by input luma, with a persistence/decay feedback layer |
| `f_masonry` | (params, self-sufficient despite "processor" label) → composite + mask | Parametric brick/masonry structure — courses, bond, mortar, per-course drift. The clean-grid-structure generator that downstream geometric warps (`f_droste`, `f_mobius`, `f_lens`) then distort |
| `f_weave` | (params, self-sufficient) + optional vecfield + optional scalar-potential → tex | Parallel line-and-mark generator, continuous-distance-field based (not grid-quantized — stays clean under Droste/spiral warps, unlike `f_masonry`). Vecfield inlet perturbs line orientation; scalar-potential inlet (from `f_vf_potential`) can fully override line geometry with curved isolines |
| `f_stipple` | tex (optional, dual-mode) → composite + mask + displaced-source | Hash-field stipple/halftone. Source mode: standalone texture from params. Processor mode: incoming luma either sets local dither density or spatially displaces the hash field |
| `f_vf_seeds` | tex (shape) + vecfield (required) + tex (mod, optional) → color + mask + seed-coord | Seed-point placement/orientation engine for discrete marks — no internal mark geometry, samples an external shape texture per seed, oriented by a vecfield. Supports genuine mark overlap ("texture bombing") via field-magnitude-driven growth, not just selection |
| `f_ks` | (params) → luma, **temporal** | Kuramoto-Sivashinsky generator: a self-sustaining chaotic pattern (cells, ridges, spiral-ish defects) that never settles, solved spectrally on a 256² GPU grid. `rate`, `scale`, `sharp`, `reset`. The only generator with both memory and chaos (`f_chladni` is a fixed modal pattern; noise has no memory). Near-flat for about a second after a reset. Bypass = black. Name `f_ks` is a placeholder; output mapping is still a tier-3 decision |
| `f_wc` | tex (pulse, optional) → RGB, **temporal** | Wilson-Cowan form-constant generator: a faithful port of the webgpgpu Example-10 page, a fixed 1024² solver shown through the bare log-polar retinal map, so a silky self-sustaining web (honeycomb, tunnel, spiral, cobweb). Kept alive by a square-wave pulse on the excitatory field (no noise). Dials: `pulse_depth`, `pulse_period`, `sim_rate` (slow motion), `pulse_mix`, `pulse_gain`, `grain_scale`; menus `out_mode` (RGB / E / Contour / Luma, default E), `pulse_space` and `out_view` (Retinal / Unwrapped); header `freeze_on`; `reset`. A texture's luma on the pulse inlet replaces the internal wave (camera / WFG friendly); `out_view` Unwrapped gives the flat cortical grid to feed `f_droste`. Slow to form after a reset by design. Replaces the old FFT-chain `f_wc` (archived as `docs/f-reference/superseded/f_wc_fft.md`). Bypass = black |

## Routing / Utility / Infrastructure

No visual effect of their own — plumbing between other modules.

| Module | I/O | What it does |
|---|---|---|
| `f_texrouter` | up to 4 tex → up to 4 tex | 4×4 texture routing matrix with named presets. ⚠ bypass = freeze (holds last frame), not passthrough — differs from every other f_ module's bypass convention |
| `f_util_matrix_2` | 2 tex (sources) + consumer param list → 2 tex passthrough + mod messages | CV-matrix-style modulation router — one source drives one destination column, textbook Eurorack patch-matrix semantics. ⚠ draft status, open design questions unresolved |
| `f_util_profile` | tex → row profile tex + column profile tex | CPU-side dual-axis luminance profiler — collapses a texture to a 1D row-mean and column-mean signal for driving per-row/per-column modulation (e.g. into `f_masonry`'s course/column inlets) |
| `f_vf_split` | vecfield → scalar + scalar | Splits a vecfield's X and Y channels into two separate grayscale textures, unipolar or bipolar encoding — for feeding a field's individual axes into scalar-only consumers |

## Audio (`f_a_`) and Control Bridges

Hand-built MSP / `gen~` modules with no texture path and no GL context. Audio runs on MSP cables, so these sit beside the video modules but never plug into them. All three are `NOT_IN_MENU` and outside the drift check; the integration decision is tabled (`.specify/plan.md` Still open 1). `I/O` here uses `audio` for signal-rate connections.

| Module | I/O | What it does |
|---|---|---|
| `f_a_decorrelate` | audio → audio | Applies the Yukhnovich et al. (2025) cross-frequency de-correlating modulation to arbitrary input audio via `pfft~` (per-bin AM gain or PM phase), with dry/wet and a `tanh` ceiling. The processor version of `f_a_ripple` |
| `f_a_ripple` | (params) → audio | Generator of the same stimulus: a harmonic carrier with a dynamic spectral ripple on one octave band, a new random f0 every `stim_dur` seconds, forever, self-timed. AM or PM, hearing-correction profiles. ⚠ Unfinished: a standalone prototype (own `dac~` and scopes, no outlet object, plain flonums, no helpfile). **Silent until `output_level` is raised** |
| `f_chladni_audio` | audio → 8 messages | Eight resonant band-pass bands with envelope followers, emitting `m0amp`…`m7amp` every 20 ms (Log or Bessel tuning). ⚠ Unverified, and out of step with `f_chladni`: that module now takes `note` / `amp`, not the eight amplitudes, so this patch cannot drive it. The planned `sigmund~` / `peakamp~` `note` / `amp` patch is unbuilt. The Log/Bessel switch looks inert from its wiring (untested in Max) |

---

## Inlet / Outlet Types, Driving-Texture Requirement, and Bypass Output

Added 2026-10-22 from the per-module docs in this folder. This is a wiring cheat-sheet: what plugs into each module, what comes out, whether the module produces anything meaningful with nothing patched in, and what its outlets show when `bypass` = 1.

**Legend.** Types as in "Reading the I/O column" above, plus `tensor-raw` (f_tensor_type outlet 0: Jxx/Jxy/Jyy), `tensor-packed` (outlet 1: cos2θ/sin2θ/trace/coherence, angle-doubled, NOT a vecfield), `mod` (optional modulation texture; unconnected = no modulation), `ctrl` (control messages that ride on the same physical inlet 0 as the texture, per Vsynth convention; not counted as a separate inlet). **Driving texture** = the input without which the output is not meaningful: **Required** (nothing useful out when unconnected), **Optional** (degrades to a defined fallback, named), **None** (self-sufficient). "Neutral vecfield" = (0.5, 0.5, 0.5, 1); "neutral tensor" = zero-tensor.

**Doc gaps, so you know what is inferred:** `f_grain`, `f_droste`, `f_channel_grader`, `f_hue_processor`, `f_luma_processor` and `f_tone_curve` docs say only "bypass processing"; the bypass column for those is the family convention (source passthrough), not a documented measurement. `f_a_decorrelate`'s doc does not state its bypass behavior either. `f_ks`, `f_vf_lbm`, `f_ngon`, `f_a_ripple` and `f_chladni_audio` got reference docs on 2026-10-22 and are in the tables below; `f_a_ripple` and `f_chladni_audio` are hand-built patches with no bypass control at all.

### Color / Tonal Grading

| Module | Inlets | Outlets | Driving texture | Bypass output |
|---|---|---|---|---|
| `f_channel_grader` | 1: tex + ctrl | 1: tex | Required (processor) | Source passthrough (convention) |
| `f_hue_processor` | 1: tex + ctrl | 1: tex | Required | Source passthrough (convention) |
| `f_luma_processor` | 1: tex + ctrl | 1: tex | Required | Source passthrough (convention) |
| `f_tone_curve` | 1: tex + ctrl | 1: tex | Required | Source passthrough (convention) |

### Geometry / UV Warp

| Module | Inlets | Outlets | Driving texture | Bypass output |
|---|---|---|---|---|
| `f_droste` | 1: tex + ctrl | 1: tex | Required | Source passthrough (convention) |
| `f_mobius` | 1: tex + ctrl | 1: tex | Required | Raw source passthrough |
| `f_lens` | 5: source tex + ctrl; 4 `mod` tex (aberration, distortion, transmission, surface/gradient) | 1: tex | Required (source); mods Optional (unconnected = black = no modulation) | Raw source passthrough. ⚠ Incomplete: halation stays live |
| `f_stereo` | 1: tex | 1: tex (circular disk) | Required | Raw unwarped texture, circular mask removed |
| `f_sirds` | 2: pattern tex (+ctrl); depth tex | 1: tex | Pattern Required; depth Optional (unconnected = zero displacement, flat tiled pattern) | Raw pattern, undisplaced |
| `f_ngon` | 1: tex + ctrl | 1: tex | Required | Raw unwarped source (mixed in by `bypass`; a value between 0 and 1 is a mix) |

### Vecfield / Tensor Producers

| Module | Inlets | Outlets | Driving texture | Bypass output |
|---|---|---|---|---|
| `f_vf_vortex` | 5: ctrl/bang; 4 `mod` tex (cx, cy, convergence, curl) | 1: vecfield | None (params only) | Neutral vecfield |
| `f_vf_vortex_multi` | 5: ctrl/bang; 4 global `mod` tex (+ optional per-site position inlets) | 1: vecfield | None (params only) | Neutral vecfield |
| `f_vf_fieldmap` | 1: tex (scalar-dominant) + ctrl | 1: vecfield | Required (unconnected = neutral vecfield, zero gradient) | Neutral vecfield |
| `f_vf_flow` | 1: tex (scalar, optional) + ctrl | 1: vecfield | Optional (unconnected = uniform field at `angle`; connected = direction perturbed by luma) | Neutral vecfield (not an input passthrough) |
| `f_vf_repulse` | 1: tex + ctrl | 1: vecfield | Required | Neutral vecfield |
| `f_vf_optical_flow` | 1: tex (live/video) + ctrl | 2: vecfield; confidence + axis (packed) | Required, and it must be moving (needs frame-to-frame change) | Neutral vecfield (out0); zero confidence (out1) |
| `f_vf_fluid` | 1: vecfield (force) + ctrl | 1: vecfield. **temporal** | Optional: solver keeps running with no force; existing flow coasts down at the drag rate | Connected: force passed through unmodified. Unconnected: neutral vecfield. Solver keeps running underneath |
| `f_vf_lbm` | 1: obstacle mask tex (white = obstacle) + ctrl | 1: vecfield. **temporal** | Optional: unconnected or black mask = no obstacle, a uniform wind; the solver runs with no input | Exactly neutral vecfield (0.5, 0.5, 0.5, 1); solver keeps running underneath |
| `f_vf_vorticity` | 1: vecfield + ctrl | 1: vecfield | Required (zero force on unconnected/uniform input). Only legible through a temporal consumer | Unmodified input field |
| `f_chladni` | 0 texture inlets (params / note / MIDI) | 3: luma (nodal lines); vecfield (gradient); scalar (magnitude) | None | out1 black; out2 neutral vecfield; out3 black |
| `f_quasi` | 1: tex (optional; its size sets the aspect) + ctrl | 3: tex (banded look); vecfield (gradient, bounded); scalar (potential) | Optional: unconnected = `vs_black`, draws on its own from params | Look black, A = 1; vecfield neutral; potential black, A = 1 |
| `f_tf_tensormap` | 1: tex (scalar-dominant) + ctrl | 2: tensor-raw; tensor-packed | Required (unconnected = neutral tensor on both) | Neutral tensor on both outlets |
| `f_tf_axisflow` | 2: tensor-packed (tensormap out1) + ctrl; optional reference vecfield | 1: vecfield | Tensor Required (unconnected / isotropic = neutral vecfield); vecfield Optional (else constant `angle`) | Neutral vecfield |
| `f_tf_smooth` | 1: tensor-raw + ctrl | 1: tensor-raw. **temporal** | Required (unconnected = field decays to all-zeros) | Exact passthrough of the inlet tensor (not a freeze) |
| `f_tf_sharpen` | 1: tensor-raw + ctrl | 1: tensor-raw | Required (unconnected reads all-zeros) | Exact passthrough of the inlet tensor |

### Tensor / Vecfield Consumers and Renderers

| Module | Inlets | Outlets | Driving texture | Bypass output |
|---|---|---|---|---|
| `f_tf_glyph` | 2: tensor-raw (+ctrl); source tex (tint) | 1: tex (glyph composite) | Tensor Required (below-gate cells are empty); source tex Optional (unconnected = neutral white ink) | Passthrough of the source texture, not a neutral frame |
| `f_tf_aniso_blur` | 2: tensor-raw; source tex (+ctrl) | 1: tex | Both needed: source unconnected = black output; tensor unconnected = isotropic fallback blur | Exact passthrough of inlet 1 (source) |
| `f_tf_hatch` | 1: tensor-raw + ctrl | 2: tex (hatch marks); tex (mark mask) | Required | Black on both outlets |
| `f_vf_warp` | 2: source tex (+ctrl); vecfield | 2: tex (composite, `mix_pct`); tex (warped layer) | Source Required; field Optional (unconnected = unwarped source) | Source on both outlets |
| `f_caustic` | 2: source tex (+ctrl); vecfield (no `vs_inState` fallback) | 2: tex (composite); tex (isolated caustic layer) | Both Required. Field unconnected = composite is a silent source passthrough, caustic layer black | Source on both outlets |
| `f_vf_streak` | 2: source tex (+ctrl); vecfield | 2: tex (composite); tex (isolated streak) | Source Required; field Optional (unconnected = streak layer shows the source, composite only differs via `gain` × `mix_pct`) | Source on both outlets |
| `f_vf_glow` | 3: source tex (+ctrl); vecfield; radius `mod` tex | 2: tex (composite); tex (isolated glow) | Source Required; field Optional (unconnected = no spread, output equals source at default `mix_pct`); mod Optional | Source on both outlets (loop still runs at full cost) |
| `f_vf_chroma` | 4: source tex (+ctrl); vecfield; hue `mod`; dispersion `mod` | 2: tex (composite); tex (isolated chroma layer) | Source Required; vecfield Required (gated by `src_vecfield`); mods Optional | Source on both outlets (loop still runs at full cost) |
| `f_vf_prism` | 4: source tex (+ctrl); vecfield; reach `mod`; spread `mod` | 3: tex (composite); tex (isolated prism layer); vecfield (weighted dispersion direction) | Source Required; vecfield Required (gated by `src_vecfield`); mods Optional | Standard bypass (source passthrough) |
| `f_vf_advect` | 2: source tex (+ctrl); vecfield | 3: tex (composite); tex (advected layer); vecfield (gradient of the accumulated flow). **temporal** | Source Required; field Optional (suppressed when unconnected) | Source passes; feedback loop keeps running, state not reset |
| `f_vf_potential` | 2: vecfield (+ctrl); color tex | 1: scalar. **temporal** | Vecfield Required; color tex Optional | Neutral (0, 0, 0, 1), NOT an input passthrough |

### Discrete-Item / Procedural Generators

| Module | Inlets | Outlets | Driving texture | Bypass output |
|---|---|---|---|---|
| `f_grain` | 1: tex (optional) + ctrl | 3: tex (composite, has feedback layer); tex (grain mask); tex (displaced source) | Optional: input luma only gates grain intensity via `luma_gate` | Not specified in doc (toggle) |
| `f_masonry` | 4: ctrl / render trigger; 3 `mod` tex (slot, brick, pixel) | 2: tex (composite); tex (mask) | None (self-sufficient, though labeled "processor") | Both outlets mix to the source texture from in0, so it only passes something if a texture is connected |
| `f_weave` | 3: ctrl / render trigger; vecfield (orientation); scalar potential | 1: tex | None (self-sufficient); vecfield and potential Optional | Black |
| `f_stipple` | 1: tex (optional, dual-mode) + ctrl | 3: tex (composite); scalar (mask); tex (displaced source) | Optional: unconnected = source mode, standalone stipple from params; connected = processor mode | Source mode: black. Processor mode: source passthrough |
| `f_vf_seeds` | 4: shape tex (+ctrl); vecfield; `mod` tex; color tex | 3: tex (mark color); scalar (mark mask); seed coord (rank 1 UV) | Shape tex Required; vecfield Required; mod and color Optional | Fully transparent (0, 0, 0, 0), not opaque black |
| `f_ks` | 1: ctrl only (messages and the draw bang; no texture) | 1: tex (luma replicated to RGB, A = 1). **temporal** | None (self-seeds from noise on load and on `reset`) | Black, alpha 1; solver keeps running underneath |
| `f_wc` | 2: ctrl (messages and the draw bang); pulse tex (optional; luma replaces the internal square wave) | 1: tex (RGB: E, I, contour; or E / contour / luma per `out_mode`, A = 1). **temporal** | Optional (the pulse): unconnected = the internal square wave; self-seeds from noise on load and on `reset` | Black, alpha 1; solver keeps running underneath |

### Routing / Utility / Audio

| Module | Inlets | Outlets | Driving texture | Bypass output |
|---|---|---|---|---|
| `f_texrouter` | up to 4: tex | up to 4: tex | Required (routes whatever is patched in) | **Freeze:** holds last routed frame. Not a passthrough |
| `f_util_matrix_2` | 3: source tex A; source tex B; control (`params`, `bypass`) | 3: tex A passthrough; tex B passthrough; message outlet (`<param> <source_idx> <amount>`) | Sources Required to modulate anything; textures pass through unchanged | Zeroes all modulation amounts; texture passthrough unchanged |
| `f_util_profile` | 1: tex + ctrl | 2: tex (row profile 128×1); tex (column profile 1×128) | Required | **Freeze:** holds last computed profile on both outlets |
| `f_vf_split` | 1: vecfield | 2: scalar (X); scalar (Y), unipolar or bipolar | Required | Both outlets pass the source vecfield through unsplit |
| `f_a_decorrelate` (audio) | 1: audio signal (`inlet~`) | 1: audio signal (`outlet~`) | Required (audio in) | Not stated in doc |
| `f_a_ripple` (audio) | None at the patch level (standalone prototype); `gen~` has one inlet taking `prepend <param>` messages | None at the patch level; `gen~` out 1 = audio (to its own `dac~`, scopes), out 2 = `render_count`, out 3 = `f0_h` | None (self-timed generator, new stimulus every `stim_dur`) | No bypass control. Silent while `output_level` = 0 (its default) |
| `f_chladni_audio` (audio to control) | 1: audio signal | 1 wired: messages `m0amp` … `m7amp` every 20 ms (a second outlet object exists, unwired) | Required (audio in) | No bypass control |

---

*When a module here looks like a candidate, open its full doc at `docs/f-reference/<module>.md` for exact params, algorithm, and known issues before recommending it.*
*Maintenance: add a row here whenever a new module gets a `docs/f-reference/<name>.md` doc. Keep one-liners to what distinguishes the module, not full behavior — that's what the linked doc is for.*
