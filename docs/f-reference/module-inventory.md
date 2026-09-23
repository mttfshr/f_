# f_ Module Inventory

**Status:** Drafted 2026-09-20 from `docs/f-reference/*.md`.

**Purpose:** Flat, load-the-whole-thing capability map for the f_ library — the layer where "does f_ already do X, or does this need a new module?" questions actually get answered. Answer that from this file alone when possible; open the full per-module doc in `docs/f-reference/<module>.md` only for the 1-3 candidates that survive the shortlist. This file intentionally omits algorithm detail, exact param ranges, and build/loose-thread history — that's what the full docs are for.

**Type contracts (read these when composability is the question):**
- [`f_vecfield_type.md`](f_vecfield_type.md) — the shared vector-field texture format (float32, RG=XY, 0.5=zero). Most "can module A feed module B" questions reduce to "does A produce a coherent f_vecfield and does B consume one," not just "are both texture in/out."
- [`discrete_item_conventions.md`](discrete_item_conventions.md) — shared param vocabulary (`density`, `phase`, `size`+`stretch`, `softness`, `shape`) across the grid/mark-placement modules (f_grain, f_masonry, f_weave, f_vf_seeds), including where the same name means different things per module.

**Reading the I/O column:** `tex` = plain texture, `vecfield` = f_vecfield (float32 RG, coherent field — see contract doc), `scalar` = single-channel greyscale signal. `→` separates input(s) from output(s). **temporal** = has frame-to-frame memory (ping-pong feedback), so behavior depends on accumulated history, not just the current frame's inputs.

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

## Vecfield Producers

Output a coherent f_vecfield (or, for f_chladni, an f_vecfield alongside other outlets). This is the "what shape is the underlying field" layer — pick one of these first when an effect needs a *structured* directional field (convergence, rotation, flow) rather than plain noise.

| Module | I/O | What it does |
|---|---|---|
| `f_vf_vortex` | (params) → vecfield | Single fixed-point field, continuously variable sink↔spiral↔center↔spiral-source↔source via `convergence`/`curl`. The basic building block of the family |
| `f_vf_vortex_multi` | (params) → vecfield | Three additive vortex sites sharing one falloff — multi-focal version of `f_vf_vortex` |
| `f_vf_fieldmap` | tex (scalar-dominant) → vecfield | Converts *any* scalar/noise texture into a vecfield via spatial gradient (central difference). The generic "turn a texture into a field" adapter — feed it `jit.gl.bfg` noise, grain, luma, anything |
| `f_vf_flow` | tex (optional) → vecfield | Dual-mode: unconnected = uniform-direction field at `angle`; connected = direction perturbed spatially by input luminance. Built as `f_weave`'s field input |
| `f_vf_repulse` | tex → vecfield | Ring-samples 16 directions around each pixel, accumulates vectors pointing away from (or, with negative gain, toward) bright regions. Texture-shape-driven repulsion/attraction field |
| `f_vf_optical_flow` | tex (video/live) → vecfield + confidence | Real Lucas-Kanade motion estimation between frames — genuine per-pixel motion field from a moving source, with aperture-problem handling. The "derive a field from what's actually moving in the shot" producer |
| `f_chladni` | (params) → luma + vecfield + scalar | Circular-plate Chladni resonance figure (Bessel modes). out2 is a vecfield (gradient toward nodal lines) — an *audio/note-driven* field producer, distinct in character from the geometric vortex family |
| `f_vf_vorticity` | vecfield → vecfield | ⚠ **UNVERIFIED, do not treat as working.** Vorticity-confinement processor — takes a field, adds back fine swirl its curl implies. Only legible through a temporal consumer (`f_vf_advect`); no visible effect on stateless consumers |

## Vecfield Consumers / Field-Driven Effects

Take a source texture plus an f_vecfield and produce a visual result shaped by the field's geometry. This is where "warp/distort/focus-like-a-lens" questions usually land — the field supplies the *shape* of the distortion, the consumer supplies the *character* (displace, streak, glow, split colors, accumulate).

| Module | I/O | What it does |
|---|---|---|
| `f_vf_warp` | tex + vecfield → tex | Directly displaces UV by the field vector, scaled by `strength`. The simplest field-driven distortion — single-sample, no accumulation |
| `f_caustic` | tex + vecfield → composite + isolated layer | Backward streamline accumulation along the field; brightness builds up in *convergence* zones (negative divergence). This is the module for a lens/fresnel-style focusing effect — bright bands form where the field converges, exactly the optical-caustic behavior a fresnel lens produces |
| `f_vf_streak` | tex + vecfield (optional) → composite + isolated layer | Accumulates samples along the streamline into a directional smear/streak, with chromatic offset option |
| `f_vf_glow` | tex + vecfield → composite + isolated layer | 48-step bidirectional accumulation along the field → anisotropic glow/bloom that follows field geometry (not radially symmetric like a normal bloom) |
| `f_vf_chroma` | tex + vecfield → composite + isolated layer | Field-steered chromatic aberration — R/B channels offset in opposite directions along the *local* field vector (vs. `f_lens`'s aberration, which is always centrifugal from a fixed center) |
| `f_vf_prism` | tex + vecfield → composite + isolated layer | Field-driven RGB channel separation, luma-gated so prism color only appears where bright content meets the field; feather control blends hard-split ↔ spectral gradient |
| `f_vf_advect` | tex + vecfield → composite + isolated layer, **temporal** | Frame-to-frame fluid advection — injected content spreads/dissipates/(if `decay`>1) amplifies over many frames, not just displaced once. The module to reach for when an effect needs to *build up* over time rather than react per-frame |
| `f_vf_potential` | vecfield (+ optional color tex) → scalar, **temporal** | Integrates field magnitude over time into a 0–1 scalar whose isolines trace the flow. Built specifically to feed `f_weave`'s scalar inlet (curved isoline texture instead of straight lines) |

## Discrete-Item / Procedural Generators

Self-sufficient generators producing structured marks/grains/bricks/lines rather than processing an input image. Share param vocabulary — see `discrete_item_conventions.md`.

| Module | I/O | What it does |
|---|---|---|
| `f_grain` | tex (optional) → tex, has feedback | Stochastic grain field — per-grain position/size/shape/color driven by input luma, with a persistence/decay feedback layer |
| `f_masonry` | (params, self-sufficient despite "processor" label) → composite + mask | Parametric brick/masonry structure — courses, bond, mortar, per-course drift. The clean-grid-structure generator that downstream geometric warps (`f_droste`, `f_mobius`, `f_lens`) then distort |
| `f_weave` | (params, self-sufficient) + optional vecfield + optional scalar-potential → tex | Parallel line-and-mark generator, continuous-distance-field based (not grid-quantized — stays clean under Droste/spiral warps, unlike `f_masonry`). Vecfield inlet perturbs line orientation; scalar-potential inlet (from `f_vf_potential`) can fully override line geometry with curved isolines |
| `f_stipple` | tex (optional, dual-mode) → composite + mask + displaced-source | Hash-field stipple/halftone. Source mode: standalone texture from params. Processor mode: incoming luma either sets local dither density or spatially displaces the hash field |
| `f_vf_seeds` | tex (shape) + vecfield (required) + tex (mod, optional) → color + mask + seed-coord | Seed-point placement/orientation engine for discrete marks — no internal mark geometry, samples an external shape texture per seed, oriented by a vecfield. Supports genuine mark overlap ("texture bombing") via field-magnitude-driven growth, not just selection |

## Routing / Utility / Infrastructure

No visual effect of their own — plumbing between other modules.

| Module | I/O | What it does |
|---|---|---|
| `f_texrouter` | up to 4 tex → up to 4 tex | 4×4 texture routing matrix with named presets. ⚠ bypass = freeze (holds last frame), not passthrough — differs from every other f_ module's bypass convention |
| `f_util_matrix_2` | 2 tex (sources) + consumer param list → 2 tex passthrough + mod messages | CV-matrix-style modulation router — one source drives one destination column, textbook Eurorack patch-matrix semantics. ⚠ draft status, open design questions unresolved |
| `f_util_profile` | tex → row profile tex + column profile tex | CPU-side dual-axis luminance profiler — collapses a texture to a 1D row-mean and column-mean signal for driving per-row/per-column modulation (e.g. into `f_masonry`'s course/column inlets) |
| `f_vf_split` | vecfield → scalar + scalar | Splits a vecfield's X and Y channels into two separate greyscale textures, unipolar or bipolar encoding — for feeding a field's individual axes into scalar-only consumers |

---

*When a module here looks like a candidate, open its full doc at `docs/f-reference/<module>.md` for exact params, algorithm, and known issues before recommending it.*
*Maintenance: add a row here whenever a new module gets a `docs/f-reference/<name>.md` doc. Keep one-liners to what distinguishes the module, not full behavior — that's what the linked doc is for.*
