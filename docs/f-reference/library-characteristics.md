# f_ Library: Characteristics and Example Data Flow

What the f_ library does, per family, with the pipeline characteristic that defines it and a data flow that demonstrates the characteristic at its best. Module behavior per `docs/f-reference/module-inventory.md`; type contracts per `f_vecfield_type.md`, `f_tensor_type.md`, `discrete_item_conventions.md`. Modules marked ⚠ in the README are noted. `f_cmap` (paused), `f_wave_field` (unfinished), `f_a_ripple` (unfinished), `f_chladni_audio` (stale vs. `f_chladni` note/amp protocol), `f_util_matrix_2` (draft) are outside scope: they're excluded from planning per repo rules and not part of a finished pipeline.

## Pattern generators — self-sustaining dynamics

Characteristic: the module is a **solver, not a filter**. It runs a differential system (Bessel modes, Kuramoto-Sivashinsky chaos, Wilson-Cowan neural fields, spectral wave field) on a fixed internal grid, driven by audio/note or pulse, and keeps going without input. It outputs the pattern itself, and — crucially — a coherent derived field as a byproduct.

Data flow (Chladni → field effect chain):

- `f_chladni_audio` receives a live audio signal and emits `m0amp`…`m7amp` band amplitudes (audio-to-control bridge).
- `f_chladni` is driven in note/amp form by those amplitudes, driving modal synthesis; emits luma (nodal lines), a vecfield (gradient toward nodal lines), and a scalar.
- `f_vf_glow` consumes the luma + vecfield to accumulate anisotropic, field-aligned bloom on the pattern.

This shows the characteristic sharply: the generator is self-sufficient (no texture input at all), yet hands downstream consumers a full `f_vecfield`, not just pixels.

Data flow (self-sustaining solver chain):

- `f_ks` outputs a continuously chaotic luma field; feed it as scalar to `f_vf_fieldmap`.
- `f_vf_fieldmap` converts the chaotic texture into a vecfield via central-difference gradient.
- `f_caustic` consumes source + vecfield to accumulate bright sheets in convergence zones (negative divergence).

The solver's internal chaos becomes a coherent direction field via the adapter; `f_caustic`'s temporal accumulation turns it into brightness structure. Note: `f_vf_fieldmap`'s gradient is "the primary source: jit.gl.bfg" per its reference doc, so this chain is inferred but type-correct.

## ∇ Fields (vecfield producers) — coherent geometry

Characteristic: outputs are not "textures that look like arrows" but **jointly computed two-channel RG float32** per `f_vecfield_type.md`, so divergence, curl, streamlines are meaningful; zero = (0.5, 0.5). Different producers exist for different *sources* of geometry: parametric (vortex, vortex_multi), texture-derived (fieldmap, flow, repulse), image-structure-derived (tensormap→axisflow), motion-derived (optical_flow), and simulated (fluid, vorticity, lbm, ch).

Data flow (source-of-geometry spread, four producers one consumer):

- Branch A: `vs_wfg_3` (or any scalar texture) → `f_vf_fieldmap` (geometry from texture gradient).
- Branch B: video input → `f_vf_optical_flow` (geometry from actual motion, confidence output).
- Branch C: `f_vf_vortex` (geometry from a single parametric singularity, mod-textures on cx/cy/convergence/curl).
- Branch D: scalar texture → `f_tf_tensormap` (structure tensor) → `f_tf_axisflow` (seam-free vecfield along image edges).

All four vecfields feed `f_vf_warp`, which displaces source UVs along local field vectors. This is the library's composability thesis: shape the field at the producer layer, keep the consumer fixed.

Data flow (feedback field that keeps moving):

- `f_vf_fluid` stirred by `f_vf_vortex`; its evolving velocity out → `f_vf_vorticity` (adds back fine curl) → `f_vf_advect` (accumulates content over frames) → gradient-of-flow vecfield from `f_vf_advect` out 2 → `f_vf_potential` (integrates field magnitude over time into isolines) → scalar to `f_weave` across inlet, turning flow isolines into woven curved lines.

This is the temporal chain that no single Vsynth core module can do: `f_vf_fluid` makes a field that moves on its own, `f_vf_advect` builds content over time, `f_vf_potential` converts that into a static-looking scalar that `f_weave` converts into line geometry.

## ∇ Effects (vecfield consumers) — shared field geometry, different character

Characteristic: all consume `source + f_vecfield` and differ in the accumulation operator (warp: single-sample displacement; streak: integrate along streamlines; glow: 48-step bidirectional accumulation; chroma: counter-offset R/B; prism: per-channel gated RGB separation; advect: frame-to-frame fluid advection; caustic: forward-scatter sheet accumulation). The field is the *shape*, the consumer is the *character*.

Data flow (one field, five characters):

- `f_vf_vortex_multi` (three additive vortex sites) → vecfield.
- Split the output 5 ways to: `f_vf_warp`, `f_vf_streak`, `f_vf_glow`, `f_vf_chroma`, `f_caustic` — each with a common source texture.
- All five outputs are different reads (displace, smear, bloom, color-split, focus-brightening) of identical field geometry.

This shows the abstraction cleanly: the vecfield format is a shared language; the consumer family is a toolbox over that language; `mix_pct` on the composites lets all branches be crossfaded back over the source.

## T_ Fields (tensor pipeline) — structure over direction

Characteristic: the whole `f_tf_` family treats image **structure as a first-class signal**. `f_tf_tensormap` produces a raw structure tensor (Sobel outer products, box-smoothed, closed-form eigensystem) and a packed orientation form; consumers read *axis and anisotropy* rather than sign-sensitive direction. Outlet 1 is angle-doubled (cos2θ/sin2θ) so the stored field has no branch-cut seam; it is NOT a vecfield, and sign-sensitive consumers must be reached through `f_tf_axisflow` per `f_tensor_type.md`.

Data flow (structure-tensor chain):

- Scalar texture (e.g. `vs_wfg_3` or bfg noise) → `f_tf_tensormap` (raw tensor + packed).
- raw tensor → `f_tf_smooth` (temporal one-pole smoothing for stability, opposite axes reinforce).
- smoothed raw tensor → `f_tf_sharpen` (eigengap exaggeration; axis untouched, trace fixed).
- result → `f_tf_glyph`: one oriented ellipse per grid cell, sized by eigenvalue ratio, gated on trace; doubles as the family's debug view.
- Alternatively `f_tf_aniso_blur` to blur only along the tensor's major axis (Weickert-style coherence-enhancing), or `f_tf_hatch` for streamline hatch marks along the axis.
- To reach standard vecfield consumers, `f_tf_axisflow` bridges packed → vecfield (along or across edges), which can then feed the ∇ Effects chain above.

## Discrete-Item / Generators — structured marks from a shared vocabulary

Characteristic: generators that build **arrangements** (grids of bricks, weaves, stipples, seeds) rather than smooth fields. They share a param vocabulary (`density`, `phase`, `size`+`stretch`, `softness`, `shape`) per `discrete_item_conventions.md`, though the same name can mean different quantities in different modules (documented drift, currently known-but-unreconciled).

Data flow (potential → isolines → weave):

- `f_vf_vortex` (or `f_vf_fluid`) vecfield out → `f_vf_potential` inlets 0 and 1 (temporal integration of field magnitude into a 0–1 scalar whose isolines trace the flow; the field is read from inlet 1, and inlet 0 only triggers the frame).
- `f_vf_potential` scalar out → `f_weave`'s across inlet: weave lines become curved isolines of the flow, not straight grids.
- `f_weave` tex out → `f_masonry`-style geometry: for a different feel, `f_masonry`'s output is the module that stays clean under geometric warps like `f_droste` because it's distance-field based, whereas `f_masonry` is grid-quantized.

Data flow (seed bombing):

- `f_vf_seeds` consumes a shape texture (in0) + a vecfield (required) + optional mod/color.
- Mark placement and orientation come from the vecfield; the shape texture gives each seed its mark; field-magnitude-driven growth enables true overlap ("texture bombing").
- Output tex = mark color, scalar = mark mask; composite with `vs_alpha_blend_2` or add with `vs_mixer_3`.

## Geometry / UV Warp — analytic warps

Characteristic: stateless single-pass transforms that **bend sampling coordinates** by a fixed analytic map (log-polar Droste recursion, Möbius inversion, stereographic disk, kaleidoscope fold, SIRDS depth-displacement), not by any input data field.

Data flow (generator → geometric warp → color):

- `f_masonry` bricks out → `f_droste` (log-polar spiral, infinite-zoom recursion of the brick wall) → `f_lens` (aberration/distortion/halation, spatially modulated) → `f_tone_curve` (shadow/mid/high) → final.

This shows the "bend space, don't generate color" family doing what it's for: taking structured content from a discrete-item generator and making it infinitely recursive, then optically treating it.

## Color / Tonal Grading — terminal, per-pixel, no geometry

Characteristic: stateless, no geometric displacement; effect is about *what color a pixel is*, structured by a tonal segmentation (per-channel lift/gamma/gain; hue-band select; luma-range select; shadow/mid/high). Terminal in the pipeline and easily interleaved with `vs_colorizer`/`vs_rgb_mixer`-class core modules.

Data flow (luma-gated color on field output):

- `f_vf_prism` composite out → `f_luma_processor` (adjust sat/lum/hue only within shadow/mid/high) → `f_channel_grader` (per-channel grade) → `vs_cos_palettes` (cosine palette colorize) → output.

## Routing / Utility / Adapters — plumbing the type system

Characteristic: adapters and routing matrices that let otherwise incompatible modules talk; each enforces a convention that keeps types correct downstream.

Data flow (profile-driven masonry modulation):

- any source texture → `f_util_profile` (CPU-side row-column luminance profiler, 128×1 + 1×128 outputs).
- `f_masonry` course/column modulation inlets driven by those profiles.
- Same source → `f_texrouter` (4×4 patch-matrix routing with named presets) to distribute frames across the chain.
- `f_vf_split` → scalar-only consumers (e.g. feed Y channel of an optical-flow vecfield into `f_masonry`'s drift modulation).

Data flow (CV-matrix-style modulation):

- Two source textures → `f_util_matrix_2` (Eurorack-style CV matrix; one source drives one destination column, scalar per-param routing messages out).
- Messages drive a patch of scalar-modulated modules (e.g. `f_hue_processor` hue band drift, `f_channel_grader` R/G/B gain sweep).

## Audio — parallel subsystem, no texture path

Characteristic: gen~/pfft~ modules with **no GL context**, driven by MSP cables, out of the texture type system. `f_a_decorrelate` (audio in/out, shipped) is the processor form of `f_a_ripple` (generator, unfinished), and `f_chladni_audio` is the audio-to-control bridge into `f_chladni` (but protocol-stale: sends m0amp…m7amp while `f_chladni` now takes `note`/`amp`).

## Cross-cutting conventions worth knowing

- **Bypass is not uniform.** Most modules pass source; `f_texrouter`, `f_util_profile` hold last frame (freeze); `f_vf_ch`, `f_ks`, `f_wc`, `f_vf_lbm` keep the solver running underneath and emit a neutral texture; `f_tf_smooth`/`f_tf_sharpen` passthrough exactly. Documented in the inventory's bypass table.
- **Type boundaries are real boundaries.** `f_vecfield` ≠ tensor ≠ scalar; `f_tf_tensormap` outlet 1 is not a vecfield and sign-sensitive consumers must go via `f_tf_axisflow`. Unconnected inlets decode as neutral/black/grey per the inventory's driving-texture table, with documented traps (e.g. all-zeros decoding to a "phantom" non-SPD tensor in `f_tensor_type.md` rule 5).
- **Temporal modules are consumers of their own history.** `f_vf_fluid`, `f_vf_ch`, `f_vf_lbm`, `f_vf_advect`, `f_vf_potential`, `f_tf_smooth`, `f_grain`'s feedback layer, `f_ks`, `f_wc` all have frame-to-frame state; wiring them into the non-temporal part of a chain changes the chain's time behavior.
- **Named pipelines:** `f_tf_hatch` is a three-stage streamline (LIC) renderer, 16 steps per direction, with a two-stage pre-filter for its stroke texture; `f_tf_glyph` doubles as the tensor family's debug view; `f_tf_aniso_blur` is the coherence-enhancing smoother.

## Summary map (per patcher file in `package/patchers/`)

| Category | Modules | Character |
|---|---|---|
| Patterns | f_chladni, f_ks, f_wc, f_quasi, f_cmap⚠ | Solver-driven, self-sustaining, field byproduct |
| Generators/Discrete | f_grain, f_masonry, f_weave, f_stipple, f_vf_seeds | Arranged marks, shared param vocabulary |
| Geometry/UV | f_droste, f_mobius, f_lens, f_stereo, f_sirds, f_ngon⚠, f_cmap⚠ | Stateless analytic coordinate warps |
| Color/Tone | f_channel_grader, f_hue_processor, f_luma_processor, f_tone_curve, f_cmap⚠ | Terminal, tonal segmentation, pixel-value only |
| ∇ Fields | f_vf_vortex, f_vf_vortex_multi, f_vf_fieldmap, f_vf_flow, f_vf_repulse, f_vf_optical_flow, f_vf_fluid, f_vf_ch, f_vf_lbm, f_vf_vorticity, f_wave_field, f_chladni (partly) | Coherent jointly-computed RG vecfield producers |
| ∇ Effects | f_vf_warp, f_vf_streak, f_vf_glow, f_vf_chroma, f_vf_prism, f_vf_advect, f_caustic | Shared-field consumers, differing accumulation operator |
| T_ Fields | f_tf_tensormap, f_tf_smooth, f_tf_sharpen | Structure (axis+anisotropy) signal, angle-doubled, NOT vecfield |
| T_ Effects | f_tf_aniso_blur, f_tf_glyph, f_tf_hatch | Axis-aligned renderers, axis-blind or bridged |
| Adapters | f_tf_axisflow, f_vf_fieldmap, f_vf_potential, f_vf_split | Type-conversion and bridging |
| Routing/Utility | f_texrouter, f_util_matrix_2⚠, f_util_profile, f_modules, f_util_matrix_2 draft | Plumbing, matrices, profiling, no visual effect of their own |
| Audio | f_a_decorrelate, f_a_ripple⚠, f_chladni_audio⚠ | Signal domain, no textures, MSP cables |
| Launcher/Menu | f_modules, f_Launch (extras) | Generated menus and launcher, not effects |

f_ngon has no reference doc (tier-1 mirror only, "not yet confirmed or documented" per README); f_quasi and f_chladni doc files exist. Verify any given module by its own doc (`docs/f-reference/<name>.md`) before wiring beyond these flows.

---

# Example flows, module by module

Two additional example data flows per patcher, beyond the family-level chains above. Wiring is per the inventory's inlet/outlet/bypass tables; `⚠` modules get aspirational flows consistent with their built surface, not evidence of a verified look.

## Patterns

**f_chladni**
1. Nodal-line gradient as structure: `f_chladni` out1 luma → `vs_edges` → `f_vf_fieldmap` → `f_vf_streak` (source texture = live camera) — streaks align to the plate's nodal lines, re-shaping real footage by the resonance figure.
2. Per-note color grade: MIDI note → `f_chladni`; out1 luma → `f_luma_processor` (shadow/mid breakpoints) → `f_channel_grader` — each triggered mode re-grades a different tonal band of the accompanying video.

**f_chladni_audio** ⚠ (protocol-stale: emits `m0amp`…`m7amp`, `f_chladni` now takes `note`/`amp`)
1. Music-aware plate: multitrack audio → `f_chladni_audio` → once the note/amp bridge is built → `f_chladni` → `f_vf_glow`; band energy picks the resonance figure.
2. Message-rate CV: `m0amp`…`m7amp` (20 ms messages) → Max sliders → scaled `f_hue_processor` center messages over time — eight audio bands each steer a hue band on a texture feed, until the band→param mapping is formalized.

**f_ks**
1. Chaos as field source: `f_ks` luma → `f_vf_fieldmap` → `f_vf_advect` — the chaotic pattern advects injected content into self-reorganizing streaks.
2. Texture as modulation map: `f_ks` luma → `f_stipple` processor mode (luma sets dither density) → `vs_dither` — chaotic density-modulated stipple, no geometric displacement involved.

**f_wc**
1. Cortical grid optics: `f_wc` with `out_view` = Unwrapped → `f_droste` → `f_lens` — the flat cortical grid of the web becomes an infinite-zoom spiral, then filmic lens treatment.
2. Camera-pulsed web: live camera luma (via `f_tone_curve`, shadows up and highlights down to squash contrast) → `f_wc` pulse inlet — the web's pulse trains ride the video's rhythm, `out_mode` = Contour gives a clean overlay layer.

**f_quasi**
1. Self-referential aberration: `f_quasi` out2 (exact bounded gradient) → `f_vf_chroma` with out1 (banded luma) as the source — the quasicrystal's own gradient steers its RGB separation.
2. Woven quasicrystal: `f_quasi` out3 (potential scalar) → `f_weave` across inlet → `f_mobius` — Shepard-zoom isolines woven into lines, then Möbius-folded.

**f_wave_field**
1. Strike → rings → glow: a held Strike on `f_wave_field` (the outlines of a texture on inlet 0, or the frame centre) → out1 luma → `f_vf_glow` (source + its dispersion field) — dispersion rings bloom outward along the gradient.
2. Field-driven trails: `f_wave_field` out2 gradient vecfield → `f_vf_advect` with camera source — footage smears along the wavefront gradient, decay shaping the trail length.

**f_cmap** ⚠ paused (built and benched, look not confirmed)
1. Feedback pull on live input: camera → `f_cmap` (z^n + w feedback) → `f_grain` — the complex-map pull warps footage, grain re-attaches stochastic detail.
2. Recursion pair: `f_cmap` output → `f_droste` — the complex-map pull nested inside log-polar recursion, both infinite-recursion mechanisms combined.

## Discrete-item generators

**f_grain**
1. Gated grain grade: `f_grain` out0 composite → `f_hue_processor` (center on the grain palette) → `f_tone_curve` — grain placement stays stochastic, color gets selective.
2. Mask-crossfade layers: `f_grain` out1 grain mask → `vs_alpha_blend_2` (blacks = displaced source out2, whites = clean input) — grain appears exactly where displaced, clean where not; the mask as the only truth.

**f_masonry**
1. Brick-depth stereogram: `f_masonry` out1 mask (as depth, smoothed by `f_tf_aniso_blur`'s isotropic fallback? no — use `vs_filter_lp4x`) → `f_sirds` depth inlet; pattern = `f_stipple` source mode — a stereogram whose depth plan is the brick coursing.
2. Drift from profiles: `f_util_profile` column profile (1×128) → `f_masonry` column modulation → output → `f_droste` — courses drift by luminance column, making the wall melt into a spiral.

**f_weave**
1. Curved-isoline weave: `f_vf_potential` scalar (fed from `f_vf_fluid`) → `f_weave` across inlet — the cloth's lines become flow isolines; `mix_pct`-free, geometry itself is overridden.
2. Profile-graded weave: `f_util_profile` row profile → scaled → `f_weave` weight_tex-tagged texture on inlet 0 — line weight varies per horizontal band from luminance.

**f_stipple**
1. Stipple as SIRDS pattern: `f_stipple` source mode composite → `f_sirds` pattern inlet, depth = `vs_fish_eye`-warped camera luma — a halftone stereogram.
2. Processor-mode dither feedback: camera → `f_stipple` processor mode (the red channel dithers against the hash field; black and white unless Colorize is raised) → `vs_mixer_fdbk` — the stipple feeds the mix, decaying into a dithered residue. Displacement is not in this path; it exists only on the third outlet (displaced source).

**f_vf_seeds**
1. Flow-oriented marks: `f_vf_fluid` vecfield → `f_vf_seeds` field inlet; shape tex = `f_tf_hatch` marks; camera as mod — seeds orient to fluid flow and the hatch marks become the mark texture.
2. Overlap bombing via mask: `f_vf_seeds` out1 mark mask → `vs_alpha_blend_2` over the source photo → `f_channel_grader` on the photo layer — seeds' growth (field-magnitude-driven overlap) reveals a re-graded photo through the mask.

## Geometry / UV warp

**f_droste**
1. Quasicrystal recursion: `f_quasi` banded out1 → `f_droste` (`n_arms` = 5 to match the five plane waves) — endless-zoom bands on endless-zoom geometry.
2. Glyph field spiral: `f_tf_glyph` output → `f_droste` → `f_stereo` — oriented ellipses fold up a spiral and wrap onto the display sphere.

**f_mobius**
1. Clean inversion on structure: `f_tf_glyph` → `f_mobius` (invert ≈ 0.5, loxodromic range) — circles stay circles because glyph ellipses are the geometry the transform preserves.
2. Möbius-driven chromatic: `f_mobius` → `f_vf_prism` with `f_vf_fieldmap` of the Möbius output — the inversion's own gradient drives the split.

**f_lens**
1. Full chain end-to-end: `f_masonry` → `f_droste` → `f_lens` (aberration mod = `f_util_profile` row profile; transmission mod = `f_vf_potential`) → `f_channel_grader`.
2. Ghost-image texture trick: `f_lens` with `f_grain` composite as the ghost source patch… not supported (single source) — alternative: camera → `f_lens` → `f_vf_streak` isolated-layer output re-composited by `vs_alpha_blend_2` — streaks only where the lens darkened.

**f_stereo**
1. Recursive disk: `f_droste` → `f_stereo` — the spiral zoom wraps onto the rotating sphere, its rotation dial synchronized visually to Droste's twist.
2. Tensor disk display: `f_tf_axisflow`-driven `f_vf_advect` output → `f_stereo` — advected flow (which carries curved direction) shown on the stereographic surface.

**f_sirds**
1. Flow-depth stereogram: `f_vf_potential` scalar (isolines of a stirred fluid) → `f_sirds` depth; pattern = `f_stipple` — depth = the flow's accumulated potential, so the hidden image is the flow topology.
2. Brick relief: `f_masonry` mask (low-passed via `vs_filter_lp4x`) → `f_sirds` depth; pattern = `f_stipple` source mode — the autostereogram's depth plan is the brick coursing.

**f_ngon** ⚠ (tier-1 mirror only, undocumented)
1. Kaleidoscope of the web: `f_wc` RGB → `f_ngon` (n = 8) → `f_vf_glow` inlet 0, `f_vf_vortex` on inlet 1 — the form-constant web symmetrized and bloomed.
2. Folded tensor hatching: `f_tf_hatch` marks → `f_ngon` → `f_stereo` — hatching mirrors into n-fold symmetry, rendered as a disk.

## Color / tone

**f_channel_grader**
1. Stereogram grade: `f_sirds` output → `f_channel_grader` (per-channel lift/gain to kill the color fringing strips) → `vs_dither`.
2. Solver-tinted: `f_ks` luma → replicated RGB → `f_channel_grader` (R lift / B gain) → `f_quasi`'s aspect-setting inlet — chaos gets a duotone push and feeds the next generator's aspect.

**f_hue_processor**
1. Caustic color select: `f_caustic` composite → `f_hue_processor` — keep only the warm caustic bands' saturation, desaturate the rest of the frame.
2. Grain palette lock: `f_grain` composite → `f_hue_processor` (center = the grain color) → `f_tone_curve` — Hue Processor's grade respects only the grain's palette, leaving other pixels flat; Tone Curve then shapes the whole frame by band.

**f_luma_processor**
1. Shadow-only weave boost: camera → `f_luma_processor` (shadow band lift) → `f_weave` weight_tex on inlet 0 — dark areas weave thick, bright ones thin.
2. Tonal-gate prism: `f_vf_prism` composite → `f_luma_processor` → `f_channel_grader` — the prism's spectral split gets re-graded per tonal band, spectral gradient clean only in highlights.

**f_tone_curve**
1. Pulse conditioning: camera → `f_tone_curve` (crushed shadows) → `f_wc` pulse inlet (1) — dark frames stop pulsing the Wilson-Cowan web entirely; the web rests between bright beats.
2. Luma-band field: camera → `f_tone_curve` (crushed shadows, Falloff raised) → `f_vf_fieldmap` → `f_vf_advect` inlet 1, with a source on inlet 0 — only the mids' and highlights' gradient advects; shadows stall the flow. At Falloff 0 the jump at `low_mid` is a hard edge, likely the strongest gradient in the frame.

## ∇ Fields (producers)

**f_vf_vortex**
1. Singularity caustics: `f_vf_vortex` (convergence high, curl mid) → `f_caustic` with camera source — bright sheet forms at the fixed point.
2. Noise-drifting vortex: `vs_sources_noise` low-band → `f_vf_vortex` cx/cy mod inlets → `f_vf_advect` — the sink wanders, advected content follows.

**f_vf_vortex_multi**
1. Three-site chroma: `f_vf_vortex_multi` → `f_vf_chroma` — R/B split around three sinks at once.
2. Multi-focal potential cloth: `f_vf_vortex_multi` → `f_vf_potential` → `f_weave` across — isolines weave around all three foci.

**f_vf_fieldmap**
1. Noise-field warp: `jit.gl.bfg` noise → `f_vf_fieldmap` → `f_vf_warp` (source = `f_masonry`) — noise gradients bend the brick wall.
2. Field-seeded fluid: `f_vf_fieldmap` (source = camera luma, `rotate` near 90) → `f_vf_fluid` force inlet → `f_vf_advect` — video luminance stirs an incompressible soup that then moves on its own. At `rotate` 0 the force is a pure gradient, and Fluid's default `project` removes nearly all of it.

**f_vf_flow**
1. Waveform-directed flow: `vs_wfg_3` inverted output → `f_vf_flow` → `f_vf_streak` inlet 1, with a source on inlet 0 — the WFG's phase stripes set a scanning flow angle; streaks sweep in a time pattern.
2. Texture-steered prism: scalar texture → `f_vf_flow` → `f_vf_prism` inlet 1, with a source on inlet 0 — the texture sets the split direction. Flow is full strength everywhere, so it does not limit where the split appears; Prism's own `threshold` does, on bright source.

**f_vf_repulse**
1. Attraction variant: camera → `f_vf_repulse` with negative `gain` → `f_caustic` — brightness attracts, caustic sheets converge on the subject.
2. Warp-away portrait: `f_vf_repulse` → `f_vf_warp` (source = same camera) — the surroundings close in on its bright regions, which shrink (warp reads along the vector, so content moves against it); composite `mix_pct` crossfades the two truths.

**f_vf_optical_flow**
1. Motion streaks: camera → `f_vf_optical_flow` → `f_vf_streak` (source = camera) — motion blur in the true motion direction, aperture-problem handled.
2. Motion memory: vecfield out0 → `f_vf_fluid` force → `f_vf_advect` — after the motion stops, the fluid keeps the momentum; confidence out1 → `vs_comparator` gates where the fluid is force-fed.

**f_vf_fluid**
1. Vortex-stirred warp: `f_vf_vortex` → `f_vf_fluid` force → `f_vf_warp` (source = `f_weave`) — the weave is bent by persistent incompressible swirl.
2. Two-fluid phase: two `f_vf_fluid` at different `viscosity`, one stirred by `f_vf_vortex`, one by optical flow → `f_vf_ch` → blended velocity out0 → `f_vf_glow` — droplet boundaries glow along the blended field.

**f_vf_ch**
1. Phase as stipple density: `f_vf_ch` phase tex (out0, grey) → `f_stipple` processor mode — droplets decide where the stipple field densifies.
2. Blended-field prism: `f_vf_ch` blended vecfield (out1) → `f_vf_prism` (source = the phase tex) — the Cahn–Hilliard pattern prisms along its own immiscible flow.

**f_vf_lbm**
1. Wake streaks: `f_masonry` mask → `f_vf_lbm` obstacle → `f_vf_streak` (source = `f_masonry` composite) — the wind's wake drags the bricks' texture into a vortex street.
2. Shedding potential: wait for shedding → `f_vf_potential` → `f_weave` — the Kármán street's isolines end up woven as cloth.

**f_vf_vorticity**
1. Re-swirled decay: `f_vf_fluid` (viscosity low) → `f_vf_vorticity` → `f_vf_advect` — fine curl that solver smoothing removed is returned to the advection.
2. Confinement check chain: `f_vf_vortex` → `f_vf_vorticity` → `f_caustic` — confinement sharpens the singularity's caustic sheet vs. un-confinement (the same setup minus the stage).

## ∇ Effects (consumers)

**f_vf_warp**
1. Warp-with-feedback: `f_vf_warp` warped layer out2 → `vs_mixer_fdbk` — the mixer's additive feedback sits after the warp, so the warped image builds up brighter; the displacement itself does not compound.
2. Noise-warped masonry: `f_vf_fieldmap` of bfg noise → `f_vf_warp` (source = `f_masonry`) → `f_droste` — first a local bend, then a global one.

**f_vf_streak**
1. Keyed streak layers: `f_vf_streak` isolated layer out1 → `vs_luma_key` → `vs_alpha_blend_2` over clean camera — streak only where the image is bright.
2. Chromatic streak grade: `f_vf_streak` (chromatic option on) → `f_hue_processor` — restrict the streak's spectral smear to one hue band.

**f_vf_glow**
1. Profile-driven radius: `f_util_profile` row profile → `f_vf_glow` radius mod inlet — glow radius varies left to right, one band per row of luminance (the 128 × 1 profile is read along x).
2. Solver-energy bloom: `f_vf_fluid`-advected camera → `f_vf_glow` inlet 0, the same fluid field on inlet 1 — energy in the flow field (its geometry) decides where light bleeds.

**f_vf_chroma**
1. Palette-modulated aberration: `vs_cos_palettes` out → `f_vf_chroma` hue mod inlet — the rainbow direction is steered by a second, unrelated source.
2. Graded split: `f_vf_chroma` composite → `f_luma_processor` → `f_tone_curve` — the split gets a tonal band treatment, matching color processor conventions.

**f_vf_prism**
1. Dispersion-field reuse: `f_vf_prism` out2 (weighted dispersion direction vecfield) → `f_vf_split` → two scalars → `f_weave` across and along — the prism's own dispersion drives the weave's geometry.
2. Brightness-gated only: `f_tf_tensormap` outlet 1 → `f_tf_axisflow` → `f_vf_prism` inlet 1, with a source on inlet 0 — prism split follows image edges, not a synthetic field.

**f_vf_advect**
1. Excitable trails: camera → `f_vf_advect` (decay > 1) → `f_vf_glow` inlet 0, the advecting field on inlet 1 — accumulated flow amplifies frame to frame, self-igniting along the vortex street.
2. Flow gradient as new field: `f_vf_advect` out2 gradient vecfield → `f_vf_potential` → `f_weave` — the advection's own history becomes woven isolines.

**f_caustic**
1. Lens-stacked caustics: `f_caustic` composite → `f_lens` (halation, transmission mod = `f_vf_potential`) — the caustic sheet gets a filmic lens pass on top.
2. Bricks under water: `f_masonry` → `f_caustic` (field = `f_vf_fluid` stirred by noise) → `f_droste` — masonry refracted through turbulent caustics, then spiraled.

**f_vf_potential** (in every chain here, the vecfield goes to inlet 1 and inlet 0 needs a texture; one vecfield into both works)
1. Depth for stereogram: `f_vf_potential` scalar → `f_sirds` depth — flow topology as stereogram relief.
2. Isoline stipple: `f_vf_potential` scalar → `f_stipple` processor mode — stipple density tracks the potential isolines rather than the source image.

## T_ fields and effects

**f_tf_tensormap**
1. Edge-tracked advect: scalar source → `f_tf_tensormap` → `f_tf_axisflow` → `f_vf_advect` — content flows along image structure without sign seams.
2. Orientation-driven stipple: packed out1 → `f_stipple` processor mode — Stipple reads red only, which in the packed texture is cos 2θ (0.5 on flat areas), so the dither follows edge orientation. Trace (B) and coherence (A) are not reachable without an unpack module (`f_tf_unpack`, not built).

**f_tf_smooth**
1. Stabilize then commit: camera → `f_tf_tensormap` → `f_tf_smooth` → `f_tf_sharpen` → `f_tf_glyph` — wobbling camera structure becomes crisp, stabilized, then exaggerated ellipses.
2. Release-performable inertia: `f_tf_smooth` in the above with `release` swept live → `f_tf_aniso_blur` on the same source — anisotropy confidence fades as the operator releases, blur relaxes toward isotropic.

**f_tf_sharpen**
1. Commit-to-hatch: `f_tf_smooth` → `f_tf_sharpen` → `f_tf_hatch` — the sharpened eigengap pushes coherence toward 1, so strokes follow the axis further and less of the frame reads as grain.
2. Not into `f_tf_axisflow`: `f_tf_sharpen` and `f_tf_smooth` output the raw tensor, and axisflow reads only the packed form (tensormap outlet 1).

**f_tf_aniso_blur**
1. Structure-smoothing grade: camera → `f_tf_aniso_blur` (source = camera, tensor = same camera through `f_tf_tensormap` → `f_tf_smooth`) → `f_hue_processor` — blur only along structures, then selectively re-saturate.
2. Isotropic fallback demo: blank scalar tex → `f_tf_tensormap` → raw → `f_tf_aniso_blur` (source = `f_masonry`) — no direction anywhere: isotropic fallback, the whole wall softens evenly.

**f_tf_glyph**
1. Real-structure debug over video: camera → `f_tf_tensormap` → `f_tf_glyph` with source tex = camera — the ellipses tell you which way the footage's edges run; doubles as the family's debug view.
2. Glyph-cloth: `f_tf_glyph` composite → `f_weave` weight_tex on inlet 0 — ellipses modulate line weight; the glyph view becomes a control source.

**f_tf_hatch**
1. Keyed hatch composite: `f_tf_hatch` streaks (outlet 0) → `vs_alpha_blend_2` over the source photo — hatching exactly where the tensor found structure, photo underneath.
2. Hatch marks as seeds: `f_tf_hatch` streak field (outlet 1) → `f_vf_seeds` shape tex; vecfield = `f_tf_axisflow` of the same tensor — the seed engine places the hatch strokes where the structure lives.

**f_tf_axisflow**
1. Across-mode flow: `f_tf_axisflow` (mode = across) → `f_vf_warp` (source = `f_weave`) — content pushed perpendicular to the edges: the weave gets combed away from its lines.
2. Along-mode caustics: `f_tf_axisflow` (mode = along) → `f_caustic` — brightness collects where edge-flow converges, a lens effect that is structurally derived from the image.

## Adapters

**f_vf_split**
1. Axis-separated control: `f_vf_fluid` → `f_vf_split` → X scalar to `f_weave` along inlet, Y scalar to offset — horizontal flow rate and vertical drift modulated independently.
2. Scalar-only consumers: `f_vf_optical_flow` out0 → `f_vf_split` → Y scalar → `f_stipple` processor mode — motion's vertical component becomes dither density.

**f_tf_axisflow** — see T_ fields/effects above; both its modes are exercised there.

## Routing / mod

**f_texrouter**
1. Four-bank switching: four generated sources (`f_ks`, `f_quasi`, `f_weave`, `f_wc`) → `f_texrouter` preset system → `f_stereo` display — one dial swaps the whole stage without rewiring.
2. Hold-frame transition: route then `bypass` = 1 (freeze) between preset swaps → `vs_alpha_blend_2` — the freeze is itself an effect (a held frame crossfaded over the next).

**f_util_profile**
1. Profile-driven masonry: camera → `f_util_profile` → row/column profiles → `f_masonry` course and column inlets — the wall's bond follows the video's axis statistics.
2. Profile-keyed glow: same camera → profiles → `f_vf_glow` radius mod — brightness bands (per row, per column) decide where bloom spreads.

**f_util_matrix_2** ⚠ draft
1. Eurorack-style modulation: `f_util_profile` row tex and camera → `f_util_matrix_2` sources → message outlet → `f_hue_processor` center, `f_channel_grader` gain — one texture routes to two destinations per column, routed by amount.
2. Cross-routed warps: `f_vf_fluid` output as source A, `f_tf_axisflow` output as source B → matrix → `mix_pct` of `f_vf_warp` and `f_vf_chroma`, swapped preset-to-preset.

**f_modules**
1. Live chain building: `f_modules` adds modules in the order: `f_vf_fluid` → `f_vf_advect` → `f_vf_potential` → `f_weave` — the chain in the temporal field characteristic section. `menu.py` has no recipe for it, so wire `f_vf_potential`'s inlets by hand.
2. Category-typed wiring: the ∇ and T_ category markers in the menu are the type system check: `f_tf_tensormap` is added under T_ Fields, and the next picker (`f_tf_axisflow`) lands straight under it — category order = pipeline order.

## Audio

**f_a_decorrelate**
1. Stereo widening with a ceiling: synth stereo pair → `f_a_decorrelate` (pfft~ per-band processing, `tanh` ceiling) → out — de-correlated stereo without clipping.
2. Processing the stimulus: `f_a_ripple`'s output (once the module has external outlets) → `f_a_decorrelate` — the stimulus processed by its own processor sibling, with dry/wet crossfading.

**f_a_ripple** ⚠ unfinished
1. Self-timed stimulus into processing: raise `output_level` → gen~ audio out → (after getting external outlets) `f_a_decorrelate` — the generator's own output gets a second modulation layer.
2. f0 as control: gen~ out3 `f0_h` → scaled to `f_chladni` note messages — a new f0 every `stim_dur` re-tunes the plate; requires the band→note bridge noted above to be built.

**f_chladni_audio** ⚠ unverified, protocol-stale — see its two flows in the Patterns section; both end at known-stale interfaces (`m0amp`…`m7amp` vs. `f_chladni`'s `note`/`amp`), so they need the band→note bridge before anything downstream is reachable.