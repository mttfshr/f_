# f\_tf\_expressive\_consumers research

Oct 17, 2026 · @Matt

Research and ideation only — nothing built, nothing specced, nothing committed to code. Follows `ideas/f_tf_tensor_strategy.md`'s 2026-10-16 decision to focus on full-tensor consumers (reads both eigenvalues, or operates tensor-in/tensor-out) rather than views (axisflow-style projections to a vecfield or scalar).

## Prior art, with sources

Four real families use structure tensors expressively, all operating on eigenvalues and axis together, never on a projected vector.

**Coherence-enhancing / edge-enhancing anisotropic diffusion.** Weickert's orientation analysis builds nonlinear anisotropic diffusion scale-spaces adapted to image structure via the structure tensor; Coherence Enhancing Diffusion (CED) reinforces flow-like structure, Edge Enhancing Diffusion (EED) avoids diffusing across contours while diffusing freely elsewhere — both steered by eigen-analysis of the structure tensor. Direct ancestor of `f_tf_aniso_blur`, except CED is an iterative PDE (expensive); a closed-form elliptical-kernel single pass is the real-time simplification.

**Anisotropic Kuwahara / painterly abstraction.** Kyprianidis, Kang and Döllner's "Image and Video Abstraction by Anisotropic Kuwahara Filtering" (CGF 2009) generalizes the Kuwahara filter, adapting shape/scale/orientation of the kernel to the smoothed structure tensor, producing a painting-like flattening along feature directions while preserving shape boundaries, real-time on GPU. The follow-up "Anisotropic Kuwahara Filtering with Polynomial Weighting Functions" (2010) replaces convolution-based weighting with direct computation, avoiding a texture-map sample. `jit.fx.cf.kuwahara` already ships this look; only a tensor-in variant is new territory.

**Line Integral Convolution.** Cabral and Leedom's LIC (SIGGRAPH 1993) locally blurs white noise along a vector field, one-to-one between grid cells and output pixels. A vecfield technique, not tensor-native by this library's own test (needs a sign) — the right anchor for distinguishing "flow visualization" (vecfield) from "tensor visualization" (glyphs, anisotropic blur).

**Tensor glyphs and hyperstreamlines (DT-MRI).** Closest existing precedent to `f_tf_glyph`. Glyph-based visualization uses eigenvectors for orientation, eigenvalues for scale (superquadric glyphs, Kindlmann et al.); Delmarcelle and Hesselink's hyperstreamlines (Visualization '93) extend streamline tracing into a continuous tensor-field representation. A closer non-medical precedent: G'MIC's `-structuretensors` + `-eigen` + `-display_tensors` renders an ellipse per tensor cell with axes proportional to the two eigenvalues and faux-colors edge orientation — `f_tf_glyph` already built, in a different tool. Confirms it's cheap and legible.

**Tensor voting.** Medioni's tensor voting encodes input as second-order symmetric tensors that cast votes to neighbors, accumulating into new tensors whose eigensystem reveals inferred structure (curves, junctions, regions) even from noisy/sparse points. Not a filter on an existing field — a way to grow structure from sparse input. Suggests a producer mode not otherwise considered (see Open Questions).

**Flow-guided stroke rendering / hatching / stippling.** Most direct carry-over to the render-consumer category. Tschumperlé's tensor-directed stroke simulation (ICIP 2011) places anisotropic strokes across contours (hatching) and along contours, streamlines letting strokes curve, one tensor model supporting multiple rendering styles — essentially `f_tf_hatch` already published. Kang's "structure grid" (2011) represents directional stippling as an adaptive texture built from orientation information, unifying directional stippling and feature-guided hatching — a second concrete architecture for the `f_vf_seeds`/`f_stipple` confidence-scaled-marks idea in the hub doc. Praun, Hoppe, Webb, Finkelstein's real-time hatching (2001) aligns a lapped texture parametrization to a curvature-based direction field — the classic reference for keeping hatching temporally coherent, relevant to `f_tf_hatch` on live video.

**Hessian / ridge filters.** Frangi's multiscale vesselness filter (1998) derives a "vesselness" measure from all eigenvalues of the image Hessian at each scale. A second tensor source distinct from the gradient-outer-product structure tensor: the Hessian finds ridges/valleys (ellipse elongated along a crest), the structure tensor finds edges (ellipse elongated along an edge). Visually divergent on the same source, not redundant.

**Tissot indicatrix / metric tensor of a warp.** The Tissot indicatrix shows how an infinitesimally small circle on a source surface appears after a map projection — an ellipse of distortion revealing local scale and angular distortion. Mechanically the first fundamental form of the UV warp's Jacobian — the "metric tensor" already flagged in the hub doc for `f_mobius`/`f_droste`/`f_stereo`/`f_lens`. The ellipse-field description is identical to what `f_tf_glyph` would render.

**VJ / creative-coding precedent.** No dedicated structure-tensor modules found in the TouchDesigner or Shadertoy ecosystems — TouchDesigner's shader-porting tools move single-pass Shadertoy fragment shaders across, not tensor-specific ones; orientation-field work found was mostly scientific/materials (fiber orientation in porous media), not live-visuals practice. Matches the `jit.fx.cf.kuwahara` finding: anisotropic-Kuwahara-as-filter reached mainstream tools, but full-tensor-in/out modules, glyph fields, and tensor-driven stroke placement as *performable* live instruments appear genuinely underexplored in VJ practice, not just unbuilt here.

## New tensor-space operators (tensor in, tensor out)

**`f_tf_smooth`** — temporal tensor smoother ("inertia"), identified in `f_tf_tensor_strategy.md` row 14; load-bearing for everything else on live video.

- *Tensor-native test:* averaging opposite axes cancels to zero in vector space; via the doubled-angle encoding (or directly on Jxx/Jxy/Jyy) they reinforce in tensor space. A feedback blend of the raw tensor with its own previous frame is the only way to damp frame-to-frame jitter without branch-cut flicker.
- *Performer touches:* one knob, `release` (0-1, feedback coefficient), same shape as `f_vf_advect`'s `decay`. Optionally a `reset` bang.
- *Chains:* directly after `f_tf_tensormap` outlet 0, before any full-tensor consumer — less "a module," more "the stabilizer every other full-tensor consumer here silently assumes exists."
- *Cost:* one feedback texture, one `mix()` per channel — cheaper than `f_vf_advect` (no displacement lookup). Negligible.
- *Failure modes:* over-smoothing kills responsiveness to real scene cuts; needs either `reset` or a disagreement detector (new vs. smoothed tensor differ past a threshold -> snap instead of blend).

**`f_tf_sharpen`** — exaggerates or relaxes anisotropy in tensor space: scales the eigenvalue gap while holding trace (energy) fixed.

- *Tensor-native test:* needs both eigenvalues explicitly — a vecfield has no second axis to redistribute energy from.
- *Performer touches:* one knob, `exaggerate` (bipolar: toward a line field at +1, toward isotropic at -1, no-op at 0).
- *Chains:* `tensormap -> f_tf_smooth -> f_tf_sharpen -> f_tf_aniso_blur` or `-> f_tf_glyph`. The "turn the painting knob" gesture.
- *Cost:* closed-form, one pass, same order as tensormap's own stage C eigendecomposition. Trivial.
- *Failure modes:* pushed toward isotropic, axis-dependent downstream consumers get an undefined direction everywhere and should fall back to their own neutral (circle / no-mark) — inherit tensormap's existing neutral convention rather than invent a new one.

**`f_tf_mix`** — already identified (strategy doc row 15). Worth naming: with `f_tf_sharpen`/`f_tf_smooth` in the family, mixing a smoothed/sharpened authored field into a raw/noisy live one gives a believable hybrid rather than a flicker.

## New render / filter consumers

**`f_tf_glyph`** — ellipse (or cross, or tick-mark) field renderer, one glyph per cell on a coarse grid over the source. Strongest candidate overall; see Ranked chains.

- *Tensor-native test:* glyph aspect ratio from the eigenvalue ratio, rotation from the axis — a vecfield reduction gives a line segment with no sense of "how anisotropic"; a scalar reduction gives a dot with no orientation. Purest full-tensor consumer in this set.
- *Performer touches:* `grid_size` (cell spacing — the real control), `scale` (glyph size relative to cell), `thickness`. Optional `mode`: ellipse / cross / tick.
- *What the audience sees:* a field of oriented marks reading immediately as "this is showing the grain of the image" — legible even to a non-technical audience.
- *Chains:* takes outlet 0 (raw tensor) directly; source texture in a second inlet only if glyphs should be tinted/masked by image content. Pairs downstream of `f_tf_sharpen`. The natural first build — validates the raw-tensor decode end to end, nothing else in this family has touched outlet 0 yet.
- *Cost:* one closed-form pass per cell, no loops — cheapest full-tensor consumer possible. Grid-based, so real per-pixel cost is near zero; can evaluate at reduced resolution and upscale, the idiom `f_vf_seeds` already uses for discrete marks.
- *Failure modes:* flat regions give the neutral (a tiny dot, not an elongated line); aliasing/moire if `grid_size` is too fine relative to `thickness`; no angle-doubling pitfall — decodes cos2θ/sin2θ directly and halves once, same decode tensormap's own doc specs.

**`f_tf_hatch`** — oriented hatching/engraving strokes along (or across) the tensor axis, tone-gated by a brightness input, following the Tschumperlé precedent.

- *Tensor-native test:* direction alone would be a view (axisflow could supply that). What makes this full-tensor: stroke density/spacing should vary with coherence (confident structure -> clean parallel lines; low coherence -> cross-hatch or stipple fallback), and stroke curvature should follow the field step by step.
- *Performer touches:* `density` (line spacing), `angle_offset` (rotates the hatch pattern relative to the field), `coherence_gate` (how much low-confidence regions fall back to stipple vs. blank).
- *What the audience sees:* an engraving/woodcut look tracking the live image's structure, distinct from a static screen-space hatch overlay.
- *Chains:* downstream of `f_tf_smooth` (mandatory — hatching is far more flicker-sensitive than blur) and `f_tf_sharpen`. Natural pairing with `f_tf_glyph` for debugging during the build.
- *Cost:* real open question (see Open questions #1). A genuine stroke-placement hatcher is bounded-loop-per-pixel at best, more likely multi-pass or point-sprite, outside the single-codebox shape everything else here uses. Cheaper fallback: a tileable procedural line pattern whose local UV rotation and frequency are driven by axis + density, closer to `f_weave`'s existing distance-field-line approach.
- *Failure modes:* flicker under temporal instability; moire between hatch frequency and `grid_size`-scale screen features; at low coherence, naive hatching produces visible noise rather than a graceful cross-hatch fallback unless `coherence_gate` is tuned.

**`f_tf_glint`** — oriented specular glints/streaks whose *width*, not just direction, comes from the eigenvalue ratio (the shading analog of brushed metal).

- *Tensor-native test:* direction-only glints are a view. What makes this tensor-native is the glint lobe shape — tight/linear on coherent structure, soft/round on isotropic structure — needing both eigenvalues. **Flagged as the idea most worth a second look before committing architecture:** if the shipped version only ever reads the axis and a single performer-set "sharpness" slider, it has silently become a view wearing a tensor costume. The tensor-native version must derive lobe width from per-pixel coherence, not a performer dial, to earn its keep.
- *Performer touches:* `threshold` (luma gate for where glints appear), `gain` (glint intensity), `aniso_response` (how strongly coherence maps to lobe width — legitimate as a performer-facing response curve, not a substitute for per-pixel data).
- *Chains:* downstream of `f_tf_smooth`; natural companion to `f_vf_prism`/`f_vf_chroma` (both already have free mod inlets) if glint color should pick up chromatic dispersion.
- *Cost:* comparable to `f_vf_glow`'s accumulation loop if implemented as directional sampling, or a single-pass closed-form lobe if implemented as an analytic anisotropic highlight (cheaper, recommended for v1).
- *Failure modes:* flicker (needs `f_tf_smooth`); at `aniso_response` pushed high, isotropic regions produce visible seams where the lobe snaps from round to a thin line.

## New tensor producers from non-image sources

These make the renderers above playable independent of camera/video content — arguably more valuable for a live-performance instrument than another render consumer, letting a performer author structure directly rather than only ever reacting to whatever's in frame.

**`f_tf_jacobian`** — symmetric strain tensor (+ a separate scalar curl) from any `f_vecfield`, splitting the Jacobian into symmetric and antisymmetric parts, per the strategy doc's own brainstorm note.

- *Why it matters:* bridges the vecfield family (`f_vf_fluid`, `f_vf_vortex`, `f_vf_vortex_multi`) to the tensor-consumer family. Feed a fluid-sim velocity field through this and get a shear/strain structure, genuinely different in character from the gradient-of-luma structure tensormap produces — `f_tf_aniso_blur` downstream smears along flow shear lines rather than image edges, a look not currently anywhere in the library.
- *Cost:* central-difference Jacobian of an already-rendered vecfield texture, same cost class as `f_vf_fieldmap`'s own central-difference gradient. One pass.
- *Chains:* `f_vf_fluid -> f_tf_jacobian -> f_tf_smooth -> f_tf_aniso_blur` or `-> f_tf_glint` (Chain C, below).

**`f_tf_hessian`** — Hessian-of-a-scalar tensor, for ridge/valley structure rather than edge structure (per the Frangi precedent above).

- *Why it matters:* visually distinct from the gradient-structure-tensor's output on the same source — crests and valleys of a luma field, not its transitions. Feeding `f_vf_potential`'s accumulated scalar field through this is a natural first use, since that module already produces a smooth scalar surface with real ridges.
- *Cost:* second-derivative estimate, comparable complexity to the Sobel-based structure tensor stage already in `tensormap`.

**`f_tf_authored`** — a hand-controllable tensor field with no image input at all: two or four performer parameters (angle, aspect ratio, optionally spatial falloff or an LFO sweep on either) generating a tensor analytically, the tensor-field equivalent of `f_vf_vortex`.

- *Why it matters:* cheapest way to get a genuinely instrument-like tensor source — sweep `angle` with an LFO and every full-tensor consumer downstream responds as a coherent, controllable gesture, independent of the camera. Also the natural "known-good" source for `f_tf_mix` crossfades (image-derived tensor mixed with an authored one), and a trivial NumPy-mirror ground truth for testing every consumer here before wiring a real image source.
- *Cost:* near zero — closed-form per pixel, no sampling beyond UV.

## Performance gestures, and what's a view in disguise

Cutting across everything above:

- **Crossfading grains / release.** `f_tf_mix` for two tensor sources, `f_tf_smooth`'s `release` for temporal grain.
- **Exaggerate/relax anisotropy, one knob.** `f_tf_sharpen`'s `exaggerate` — the single most leveraged performer gesture in this set, since every downstream renderer's character shifts with it.
- **Orientation-selective effects as instrument.** Worth naming but **not** a new full-tensor consumer: a mask of `coherence x cos^2(theta - phi)` (strategy doc Table 1 row 7) is a scalar output, reducible, a view by this library's own test. Belongs with the `f_tf_unpack`-family of views, not this list — flagged per the "view in disguise" check, since at first glance it reads like a performance instrument but is actually plumbing.

**Second flag:** any version of `f_tf_glint` (above) whose lobe shape is set by a performer dial rather than per-pixel coherence is also a view in disguise — noted in its own section as the idea here most worth a second look before committing architecture.

## Ranked chains

&#91;embedded content: three chains — painterly, engraving, flow-structure; f\_tf\_glyph is the cheapest first build\]

**Single next module, best expressive value for effort: `f_tf_glyph`.** Cheapest build (closed-form, no loop); the only module here that validates the raw-tensor decode path end to end (nothing else has touched outlet 0 yet); known-legible, known-cheap elsewhere per the G'MIC precedent — low technical risk. Permanently earns its keep as the debug tool every other module in this file will want while being tuned, which the strategy doc already anticipated.

**Second pick: `f_tf_smooth`.** Not for its own look, but because it's the prerequisite every renderer here silently needs for live video, and it's nearly free to build.

Chain C is the lowest priority to build — it depends on an unspecced producer (`f_tf_jacobian`) — but the most novel-looking output of the three, since nothing currently in the library renders flow shear as a texture.

## Open questions

1. **`f_tf_hatch` cost shape.** Is it a bounded-step marching-lines approach (cheap, closer to Praun/Hoppe/Webb/Finkelstein) or a per-pixel procedural stripe lookup (cheaper still, more aliasing-prone)? This decides whether it's a near-term build or a spike.
2. **When does `f_tf_smooth` get built relative to the live chains above?** It's cheap and load-bearing for all three, but has no standalone visual identity of its own — does it get its own Phase-0/spec cycle, or does it ride along inside the first consumer that needs it?
3. **Do `f_tf_jacobian` and `f_tf_hessian` get spiked now, or deferred until a concrete consumer needs one?** Both are producers with no consumer-side precedent in this doc yet; building either first risks a module with nothing to plug into.
4. **Is `f_tf_authored` blocked on the paused UI-density question** (per the hub doc), since it's the one module here whose whole point is manual/LFO authoring surface?
5. **Should `f_tf_glyph` get a Phase-0 decision-gate task now**, given it's named best-next-module here, or does it wait for the next planning pass?
6. **Is tensor voting (Medioni) worth a producer-mode flag on `f_tf_tensormap` itself** — accumulating/denoising orientation evidence spatially before it ever reaches a consumer — rather than a separate module?

## Sources

- [Anisotropic Diffusion in ITK](https://arxiv.org/pdf/1503.00992)
- [Weickert, Coherence-enhancing diffusion of colour images](https://www.mia.uni-saarland.de/weickert/Abstracts/ced-col.html)
- [Weickert, Coherence-Enhancing Diffusion Filtering](https://datalearner.com/academic/journal-papers/0920-5691/volumes-and-issues/31/paper-detail/12739)
- [Kyprianidis, Kang, Döllner — Image and Video Abstraction by Anisotropic Kuwahara Filtering](https://umsl.edu/~kangh/Papers/kang_cgf09.pdf)
- [Kyprianidis, Semmo, Kang, Döllner — Anisotropic Kuwahara Filtering with Polynomial Weighting Functions](https://diglib.eg.org/items/9865e5fe-3d23-470e-8cf6-e571bebafb9b/full)
- [Cabral, Leedom — Imaging Vector Fields Using Line Integral Convolution](https://courses.cs.duke.edu/spring03/cps296.8/papers/cabralLineIntegralConvolutions.pdf)
- [DT-MRI Visualization with Streamtubes (Delmarcelle/Hesselink hyperstreamlines, Kindlmann superquadric glyphs)](https://www2.cs.sfu.ca/~hamarneh/ecopy/spiemi2007c.pdf)
- [Visualization of Tensor Fields Using Superquadric Glyphs](https://pmc.ncbi.nlm.nih.gov/articles/PMC2169197)
- [G'MIC -structuretensors / -eigen / -display\_tensors](https://gmic.eu/oldtutorial/_structuretensors.html)
- [Medioni — Tensor Voting](https://homepages.inf.ed.ac.uk/rbf/CVonline/LOCAL_COPIES/MORDOHAI/tensorvoting.html)
- [Tschumperlé — Tensor-Directed Simulation of Strokes for Image Stylization with Hatching and Contours](https://tschumperle.users.greyc.fr/slides/slides_icip2011.pdf)
- [Kang — Structure grid for directional stippling](https://umsl.edu/~kangh/Papers/kang_gm2011.pdf)
- [Praun, Hoppe, Webb, Finkelstein — Real-time hatching](https://collaborate.princeton.edu/en/publications/real-time-hatching-2/)
- [Frangi, Niessen, Vincken, Viergever — Multiscale Vessel Enhancement Filtering](https://www.doi.org/10.1007/BFB0056195)
- [Ridge filters / Hessian eigenvalues reference implementation](https://mitra.stanford.edu/kundaje/marinovg/oak/various/programs/skimage/filters/ridges.py)
- [Tissot Indicatrix for Map Projection Distortion](https://unstats.un.org/unsd/geoinfo/ungegn/docs/_data_ICAcourses/_pdf/selfstudy/s06/S06_02b.pdf)
