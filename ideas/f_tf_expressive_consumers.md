# f_tf_expressive_consumers — research: full-tensor consumers for the f_ library

_Created: 2026-10-17. Status: research/ideation only. Nothing built, nothing specced._
_Context: `ideas/f_tf_tensor_strategy.md` resolved 2026-10-16 to focus on full-tensor
consumers (Table 1 rows 12-16) rather than views. This file is the research pass
requested to find more concrete candidates in that space, plus prior art._
_Hub: `ideas/f_tensorfield.md`. Type contract: `docs/f-reference/f_tensor_type.md`._
_Strategy: `ideas/f_tf_tensor_strategy.md`._

---

## Prior art, with sources

Surveyed against the tensor-native test (full eigen-structure, not reducible to a
vector or scalar). Four real families turned up, all operating on eigenvalues and
axis together, never on a projected vector:

**Coherence-enhancing / edge-enhancing anisotropic diffusion.** Weickert's orientation
analysis builds nonlinear anisotropic diffusion scale-spaces adapted to image structure
via the structure tensor; Coherence Enhancing Diffusion (CED) reinforces flow-like
structure, Edge Enhancing Diffusion (EED) avoids diffusing across contours while
diffusing freely elsewhere — both steered by eigen-analysis of the structure tensor.
Direct ancestor of `f_tf_aniso_blur`, except CED is an iterative PDE (expensive); a
closed-form elliptical-kernel single pass is the real-time simplification.

**Anisotropic Kuwahara / painterly abstraction.** Kyprianidis, Kang and Döllner's
"Image and Video Abstraction by Anisotropic Kuwahara Filtering" (CGF 2009) generalizes
the Kuwahara filter, adapting shape/scale/orientation of the kernel to the smoothed
structure tensor, producing a painting-like flattening along feature directions while
preserving shape boundaries, real-time on GPU. Follow-up "Anisotropic Kuwahara
Filtering with Polynomial Weighting Functions" (Kyprianidis, Semmo, Kang, Döllner,
2010) replaces convolution-based weighting with direct computation, avoiding a
texture-map sample. `jit.fx.cf.kuwahara` already ships this look (see
`ideas/f_tf_tensor_strategy.md`); only a tensor-in variant is new territory.

**Line Integral Convolution.** Cabral and Leedom's LIC (SIGGRAPH 1993) locally blurs
white noise along a vector field, one-to-one between grid cells and output pixels.
Vecfield technique, not tensor-native by this library's own test (needs a sign) — the
right anchor for distinguishing "flow visualization" (vecfield) from "tensor
visualization" (glyphs, anisotropic blur).

**Tensor glyphs and hyperstreamlines (DT-MRI).** Closest existing precedent to
`f_tf_glyph`. Glyph-based visualization uses eigenvectors for orientation, eigenvalues
for scale (superquadric glyphs, Kindlmann et al.); Delmarcelle and Hesselink's
hyperstreamlines (Visualization '93) extend streamline tracing into a continuous
tensor-field representation. Closer non-medical precedent: G'MIC's `-structuretensors`
+ `-eigen` + `-display_tensors` renders an ellipse per tensor cell with axes
proportional to the two eigenvalues and faux-colors edge orientation — `f_tf_glyph`
already built, in a different tool. Confirms it's cheap and legible.

**Tensor voting.** Medioni's tensor voting encodes input as second-order symmetric
tensors that cast votes to neighbors, accumulating into new tensors whose eigensystem
reveals inferred structure (curves, junctions, regions) even from noisy/sparse points.
Not a filter on an existing field — a way to *grow* structure from sparse input.
Suggests a producer mode not otherwise considered (see Open Questions).

**Flow-guided stroke rendering / hatching / stippling.** Most direct carry-over to the
render-consumer category. Tschumperlé's tensor-directed stroke simulation (ICIP 2011)
places anisotropic strokes across contours (hatching) and along contours, streamlines
letting strokes curve, one tensor model supporting multiple rendering styles —
essentially `f_tf_hatch` already published. Kang's "structure grid" (2011) represents
directional stippling as an adaptive texture built from orientation information,
unifying directional stippling and feature-guided hatching — a second concrete
architecture for the `f_vf_seeds`/`f_stipple` confidence-scaled-marks idea in the hub
doc. Praun, Hoppe, Webb, Finkelstein's real-time hatching (2001) aligns a lapped
texture parametrization to a curvature-based direction field — the classic reference
for keeping hatching temporally coherent, relevant to `f_tf_hatch` on live video.

**Hessian / ridge filters.** Frangi's multiscale vesselness filter (1998) derives a
"vesselness" measure from all eigenvalues of the image Hessian at each scale. A second
tensor source distinct from the gradient-outer-product structure tensor: the Hessian
finds ridges/valleys (ellipse elongated along a crest), the structure tensor finds
edges (ellipse elongated along an edge). Visually divergent on the same source, not
redundant.

**Tissot indicatrix / metric tensor of a warp.** The Tissot indicatrix shows how an
infinitesimally small circle on a source surface appears after a map projection — an
ellipse of distortion revealing local scale and angular distortion. Mechanically the
first fundamental form of the UV warp's Jacobian — the "metric tensor" already flagged
in the hub doc for `f_mobius`/`f_droste`/`f_stereo`/`f_lens`. The ellipse-field
description is identical to what `f_tf_glyph` would render.

**VJ / creative-coding precedent.** No dedicated structure-tensor modules found in the
TouchDesigner or Shadertoy ecosystems — TouchDesigner's shader-porting tools move
single-pass Shadertoy fragment shaders across, not tensor-specific ones; orientation-
field work found was mostly scientific/materials (fiber orientation in porous media),
not live-visuals practice. Matches the `jit.fx.cf.kuwahara` finding in the strategy
doc: anisotropic-Kuwahara-as-filter reached mainstream tools, but full-tensor-in/out
modules, glyph fields, and tensor-driven stroke placement as *performable* live
instruments appear genuinely underexplored in VJ practice, not just unbuilt here.

---

## New concrete tensor-native consumers

### Operators (tensor in, tensor out)

**`f_tf_smooth`** — temporal tensor smoother ("inertia"). Already identified in
`f_tf_tensor_strategy.md` row 14; detailed here since it's load-bearing for everything
else on live video.
- *Tensor-native test:* averaging opposite axes cancels to zero in vector space; via
  the doubled-angle encoding (or directly on Jxx/Jxy/Jyy) they reinforce in tensor
  space. A feedback blend of the raw tensor outlet with its own previous frame is the
  only way to damp frame-to-frame jitter without branch-cut flicker.
- *Performer touches:* one knob, `release` (0-1, feedback coefficient), same shape as
  `f_vf_advect`'s `decay`. Optionally a `reset` bang.
- *Chains:* directly after `f_tf_tensormap` outlet 0, before any full-tensor consumer.
  Less "a module," more "the stabilizer every other full-tensor consumer here silently
  assumes exists" — per the strategy doc's Q4, likely worth building before
  `f_tf_aniso_blur`.
- *Cost:* one feedback texture, one `mix()` per channel — cheaper than `f_vf_advect`
  (no displacement lookup). Negligible.
- *Failure modes:* over-smoothing kills responsiveness to real scene cuts; needs either
  `reset` or a disagreement detector (new vs. smoothed tensor differ past a threshold ->
  snap instead of blend) — a performable `release` dial mostly sidesteps this if ridden
  down into a hard cut.

**`f_tf_sharpen`** — exaggerates or relaxes anisotropy in tensor space: scales the
eigenvalue gap while holding trace (energy) fixed.
- *Tensor-native test:* needs both eigenvalues explicitly — a vecfield has no second
  axis to redistribute energy from.
- *Performer touches:* one knob, `exaggerate` (bipolar: toward a line field at +1,
  toward isotropic at -1, no-op at 0).
- *Chains:* `tensormap -> f_tf_smooth -> f_tf_sharpen -> f_tf_aniso_blur` or
  `-> f_tf_glyph`. The "turn the painting knob" gesture — pushing `exaggerate` live
  moves a scene from photographic to woodcut without touching source content.
- *Cost:* closed-form, one pass, same order as tensormap's own stage C
  eigendecomposition. Trivial.
- *Failure modes:* pushed toward isotropic, axis-dependent downstream consumers
  (`f_tf_glyph`, `f_tf_hatch`) get an undefined direction everywhere and should fall
  back to their own neutral (circle / no-mark) — inherit tensormap's existing neutral
  convention by decoding/re-encoding the same way, not a new convention.

**`f_tf_mix`** — already identified (strategy doc row 15). Worth naming: with
`f_tf_sharpen`/`f_tf_smooth` in the family, mixing a smoothed/sharpened authored field
into a raw/noisy live one gives a believable hybrid rather than a flicker.

### Render / filter consumers

**`f_tf_glyph`** — ellipse (or cross, or tick-mark) field renderer, one glyph per cell
on a coarse grid over the source. Strongest candidate; see Ranking below.
- *Tensor-native test:* glyph aspect ratio from the eigenvalue ratio, rotation from the
  axis — a vecfield reduction gives a line segment with no sense of "how anisotropic";
  a scalar reduction gives a dot with no orientation. Purest full-tensor consumer in
  this set.
- *Performer touches:* `grid_size` (cell spacing — the real control), `scale` (glyph
  size relative to cell), `thickness`. Optional `mode`: ellipse / cross / tick (cheap
  shape-function swap).
- *What the audience sees:* a field of oriented marks reading immediately as "this is
  showing the grain of the image" — legible even to a non-technical audience.
- *Chains:* takes outlet 0 (raw tensor) directly per the strategy doc's architecture
  note; source texture in a second inlet only if glyphs should be tinted/masked by
  image content. Pairs downstream of `f_tf_sharpen` (exaggerate, then look). The
  natural first build: validates the raw-tensor decode end to end, nothing else in this
  family has touched outlet 0 yet.
- *Cost:* one closed-form pass per cell, no loops — cheapest full-tensor consumer
  possible. Grid-based, so real per-pixel cost is near zero; can evaluate at reduced
  resolution and upscale, the idiom `f_vf_seeds` already uses for discrete marks.
- *Failure modes:* flat regions give the neutral (a tiny dot, not an elongated line) —
  guaranteed by tensormap at the source; aliasing/moire if `grid_size` is too fine
  relative to `thickness`; no angle-doubling pitfall — the module decodes cos2θ/sin2θ
  directly and halves once, same decode tensormap's own doc already specs.

**`f_tf_hatch`** — oriented hatching/engraving strokes along (or across) the tensor
axis, tone-gated by a brightness/tone-curve input, following the Tschumperlé precedent
above.
- *Tensor-native test:* direction alone would be a view (axisflow could supply that).
  What makes this full-tensor: stroke density/spacing should vary with coherence
  (confident structure -> clean parallel lines; low coherence -> cross-hatch or stipple
  fallback, per Tschumperlé's "contours vs. hatching from the same tensor model"), and
  stroke curvature should follow the field step by step, the way `f_tf_aniso_blur`'s
  spec note already describes for curved contours.
- *Performer touches:* `density` (line spacing), `angle_offset` (rotates the hatch
  pattern relative to the field, same shape as axisflow's reference angle),
  `coherence_gate` (how much low-confidence regions fall back to stipple vs. blank).
- *What the audience sees:* an engraving/woodcut look tracking the live image's
  structure, distinct from a static screen-space hatch overlay.
- *Chains:* downstream of `f_tf_smooth` (mandatory — hatching is far more
  flicker-sensitive than blur, a line present one frame and gone the next reads as
  noise) and `f_tf_sharpen`. Natural pairing with `f_tf_glyph` for debugging during the
  build.
- *Cost:* real open question. A genuine stroke-placement hatcher (march along the
  field, accumulate coverage) is bounded-loop-per-pixel at best, more likely
  multi-pass or point-sprite, outside the single-codebox shape everything else in this
  family uses. Cheaper fallback: a tileable procedural line pattern whose local UV
  rotation and frequency are driven by axis + density (closer to `f_weave`'s existing
  distance-field-line approach than literal stroke placement) — loses some "real
  strokes" character but stays in budget. Needs deciding before speccing (Open
  Questions #1).
- *Failure modes:* flicker under temporal instability (mitigated, not eliminated, by
  `f_tf_smooth`); moire between hatch frequency and `grid_size`-scale screen features;
  at low coherence, naive hatching produces visible noise rather than a graceful
  cross-hatch fallback unless `coherence_gate` is tuned.

**`f_tf_glint`** — oriented specular glints/streaks whose *width*, not just direction,
comes from the eigenvalue ratio (anisotropic-highlight look, the shading analog of
brushed metal).
- *Tensor-native test:* direction-only glints are a view (axisflow could drive an
  existing one-directional streak module). What makes this tensor-native is the glint
  lobe shape — tight/linear on coherent structure, soft/round on isotropic structure —
  needing both eigenvalues. **Flagged as the idea on this list most worth a second look
  before committing architecture:** if the shipped version only ever reads the axis and
  a single performer-set "sharpness" slider, it has silently become a view wearing a
  tensor costume. The tensor-native version must derive lobe width from per-pixel
  coherence, not a performer dial, to earn its keep.
- *Performer touches:* `threshold` (luma gate for where glints appear), `gain` (glint
  intensity), `aniso_response` (how strongly coherence maps to lobe width — legitimate
  as a performer-facing response curve, not a substitute for per-pixel data).
- *Chains:* downstream of `f_tf_smooth`; natural companion to `f_vf_prism`/`f_vf_chroma`
  (both already have free mod inlets per the hub audit) if glint color should pick up
  chromatic dispersion.
- *Cost:* comparable to `f_vf_glow`'s accumulation loop if implemented as directional
  sampling, or a single-pass closed-form lobe if implemented as an analytic anisotropic
  highlight (cheaper, recommended for v1).
- *Failure modes:* flicker (needs `f_tf_smooth`, as with all full-tensor renders on
  live input); at `aniso_response` pushed high, isotropic regions produce visible seams
  where the lobe snaps from round to a thin line — needs the same smooth falloff
  tensormap's own coherence channel already provides, not a hard threshold.

### Tensor producers from non-image sources

These make the renderers above playable independent of camera/video content — arguably
more valuable for a live-performance instrument than another render consumer, letting a
performer author structure directly rather than only ever reacting to whatever's in
frame.

**`f_tf_jacobian`** — symmetric strain tensor (+ a separate scalar curl) from any
`f_vecfield`, splitting the Jacobian into symmetric and antisymmetric parts, per the
strategy doc's own brainstorm note.
- *Why it matters:* bridges the vecfield family (`f_vf_fluid`, `f_vf_vortex`,
  `f_vf_vortex_multi`) to the tensor-consumer family. Feed a fluid-sim velocity field
  through this and get a shear/strain structure, genuinely different in character from
  the gradient-of-luma structure tensormap produces — `f_tf_aniso_blur` downstream
  smears along flow shear lines rather than image edges, a look not currently anywhere
  in the library.
- *Cost:* central-difference Jacobian of an already-rendered vecfield texture, same
  cost class as `f_vf_fieldmap`'s own central-difference gradient. One pass.
- *Chains:* `f_vf_fluid -> f_tf_jacobian -> f_tf_smooth -> f_tf_aniso_blur` or
  `-> f_tf_glint` (Chain C below).

**`f_tf_hessian`** — Hessian-of-a-scalar tensor, for ridge/valley structure rather than
edge structure (per the Frangi precedent above).
- *Why it matters:* visually distinct from the gradient-structure-tensor's output on
  the same source — crests and valleys of a luma field, not its transitions. Feeding
  `f_vf_potential`'s accumulated scalar field through this is a natural first use,
  since that module already produces a smooth scalar surface with real ridges.
- *Cost:* second-derivative estimate, comparable complexity to the Sobel-based
  structure tensor stage already in `tensormap`.

**`f_tf_authored`** — a hand-controllable tensor field with no image input at all: two
or four performer parameters (angle, aspect ratio, optionally spatial falloff or an LFO
sweep on either) generating a tensor analytically, the tensor-field equivalent of
`f_vf_vortex`.
- *Why it matters:* cheapest way to get a genuinely instrument-like tensor source —
  sweep `angle` with an LFO and every full-tensor consumer downstream (glyph, blur,
  hatch, glint) responds as a coherent, controllable gesture, independent of the
  camera. Also the natural "known-good" source for `f_tf_mix` crossfades (image-derived
  tensor mixed with an authored one), and a trivial NumPy-mirror ground truth for
  testing every consumer in this list before wiring a real image source.
- *Cost:* near zero — closed-form per pixel, no sampling beyond UV.

### Performance gestures (cutting across the above)

- **Crossfading grains / release.** `f_tf_mix` for two tensor sources, `f_tf_smooth`'s
  `release` for temporal grain.
- **Exaggerate/relax anisotropy, one knob.** `f_tf_sharpen`'s `exaggerate` — the single
  most leveraged performer gesture in this set, since every downstream renderer's
  character shifts with it.
- **Orientation-selective effects as instrument.** Worth naming but **not** a new
  full-tensor consumer: a mask of `coherence x cos^2(theta - phi)` (strategy doc Table 1
  row 7) is a scalar output, reducible, a view by this library's own test. Belongs with
  the `f_tf_unpack`-family of views, not this list — flagged per the "view in disguise"
  check, since at first glance it reads like a performance instrument but is actually
  plumbing.

---

## Ranked chains

**Chain A — "Painterly instrument."**
`f_tf_tensormap -> f_tf_smooth -> f_tf_sharpen -> f_tf_aniso_blur`, with `f_tf_glyph`
as a sidecar/debug tap off the same tensormap output, not in the signal path. Producer,
stabilizer, operator, renderer — the cleanest four-stage rig, and the one the strategy
doc's Q12-16 resolution already points toward.

**Chain B — "Tensor engraving instrument."**
`f_tf_tensormap <-(mix)-> f_tf_authored`, both through `f_tf_mix`, then
`-> f_tf_smooth -> f_tf_hatch` (or `f_tf_glyph` for a lighter-weight version while
`f_tf_hatch`'s cost question is unresolved). The authored-field side is what makes this
a performance rig rather than a camera filter — the performer can morph between "draw
what the camera sees" and "draw what I'm steering," live.

**Chain C — "Flow-structure instrument."**
`f_vf_fluid` (or `f_vf_vortex_multi`) `-> f_tf_jacobian -> f_tf_smooth ->
f_tf_aniso_blur` / `f_tf_glint`. Doesn't touch a camera at all — pure generative
structure from the existing vecfield producers, rendered through the new tensor-
consumer vocabulary. Lowest priority to build (depends on an unspecced producer,
`f_tf_jacobian`) but the most novel-looking output of the three, since nothing
currently in the library renders flow *shear* as a texture.

**Single next module, best expressive value for effort: `f_tf_glyph`.** Cheapest build
(closed-form, no loop); the only module here that validates the raw-tensor decode path
end to end (nothing else has touched outlet 0 yet); known-legible, known-cheap
elsewhere per the G'MIC precedent — low technical risk. Permanently earns its keep as
the debug tool every other module in this file will want while being tuned, which the
strategy doc already anticipated.

**Second pick: `f_tf_smooth`.** Not for its own look, but because it's the
prerequisite every renderer here silently needs for live video, and it's nearly free to
build.

**Flagged as a view in disguise:** the orientation-selective mask (performance-gestures
section above), and any version of `f_tf_glint` whose lobe shape is set by a performer
dial rather than per-pixel coherence (noted in its own section above as the idea here
most worth a second look before committing architecture).

---

## Open questions

1. **`f_tf_hatch`'s real cost shape** — literal curved-stroke placement vs. a cheaper
   tileable-pattern approximation (closer to `f_weave`'s existing distance-field-line
   mechanism). Worth a quick GPU-budget gut check before any spec; it's the one idea
   here that might not fit the single-codebox, bounded-loop shape everything else in
   the family uses.
2. **Does `f_tf_smooth` get built before or alongside the first renderer?** Cheap and
   load-bearing, but building it in isolation means no real consumer to validate it
   against live flicker; building it alongside `f_tf_glyph` means two Phase-0 decision
   gates in one module pass.
3. **`f_tf_jacobian`/`f_tf_hessian` as producers** — worth a NumPy spike now, or
   deferred until a full-tensor consumer exists to justify them? Cheap to spike but
   currently nothing downstream to feed; Chain C depends on both existing.
4. **Does `f_tf_authored` belong in this phase at all**, or is it really an instance of
   the paused `mod_depth_ui_density.md` question (new dials on an already-dense panel)
   wearing a tensor-family label? Cheap to build but, like `f_stipple` (hub Q13), might
   inherit that blocker rather than sidestep it the way `f_vf_glow`'s Q12 did.
5. **Should `f_tf_glyph` get a Phase 0 decision-gate task now**, independent of
   everything else in this file, so it's live-testable in a scratch patch before any of
   the others get designed in detail?
6. **Tensor voting (Medioni) as a producer mode** — surfaced by the prior-art survey,
   not otherwise considered: grows structure from sparse/noisy points by letting
   tensors accumulate via votes, rather than deriving a tensor from a dense gradient
   field the way `tensormap` does. Unclear what the input would even be in this
   library's idiom (sparse marks from `f_vf_seeds`? a point cloud generator?) — noted
   here so it isn't lost, not assessed for fit.

---

## Related

- `ideas/f_tensorfield.md` — hub, full consumer audit, open questions 1-16.
- `ideas/f_tf_tensor_strategy.md` — the decision to focus on full-tensor consumers;
  Table 1/2 this file builds on; the "decoded convenience" packing decision.
- `docs/f-reference/f_tensor_type.md` — encoding contract, consumer rules.
- `docs/f-reference/f_tf_tensormap.md`, `f_tf_axisflow.md` — the two built family
  members this file's every chain starts from or routes sign-sensitive output through.

---

## Sources

- [Anisotropic Diffusion in ITK](https://arxiv.org/pdf/1503.00992)
- [Weickert, Coherence-enhancing diffusion of colour images](https://www.mia.uni-saarland.de/weickert/Abstracts/ced-col.html)
- [Weickert, Coherence-Enhancing Diffusion Filtering](https://datalearner.com/academic/journal-papers/0920-5691/volumes-and-issues/31/paper-detail/12739)
- [Kyprianidis, Kang, Döllner — Image and Video Abstraction by Anisotropic Kuwahara Filtering](https://umsl.edu/~kangh/Papers/kang_cgf09.pdf)
- [Kyprianidis, Semmo, Kang, Döllner — Anisotropic Kuwahara Filtering with Polynomial Weighting Functions](https://diglib.eg.org/items/9865e5fe-3d23-470e-8cf6-e571bebafb9b/full)
- [Cabral, Leedom — Imaging Vector Fields Using Line Integral Convolution](https://courses.cs.duke.edu/spring03/cps296.8/papers/cabralLineIntegralConvolutions.pdf)
- [DT-MRI Visualization with Streamtubes (Delmarcelle/Hesselink hyperstreamlines, Kindlmann superquadric glyphs)](https://www2.cs.sfu.ca/~hamarneh/ecopy/spiemi2007c.pdf)
- [Visualization of Tensor Fields Using Superquadric Glyphs](https://pmc.ncbi.nlm.nih.gov/articles/PMC2169197)
- [G'MIC -structuretensors / -eigen / -display_tensors](https://gmic.eu/oldtutorial/_structuretensors.html)
- [Medioni — Tensor Voting](https://homepages.inf.ed.ac.uk/rbf/CVonline/LOCAL_COPIES/MORDOHAI/tensorvoting.html)
- [Tschumperlé — Tensor-Directed Simulation of Strokes for Image Stylization with Hatching and Contours](https://tschumperle.users.greyc.fr/slides/slides_icip2011.pdf)
- [Kang — Structure grid for directional stippling](https://umsl.edu/~kangh/Papers/kang_gm2011.pdf)
- [Praun, Hoppe, Webb, Finkelstein — Real-time hatching](https://collaborate.princeton.edu/en/publications/real-time-hatching-2/)
- [Frangi, Niessen, Vincken, Viergever — Multiscale Vessel Enhancement Filtering](https://www.doi.org/10.1007/BFB0056195)
- [Ridge filters / Hessian eigenvalues reference implementation](https://mitra.stanford.edu/kundaje/marinovg/oak/various/programs/skimage/filters/ridges.py)
- [Tissot Indicatrix for Map Projection Distortion](https://unstats.un.org/unsd/geoinfo/ungegn/docs/_data_ICAcourses/_pdf/selfstudy/s06/S06_02b.pdf)
