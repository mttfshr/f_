# f_tf_research — evidence base for the tensor family

_Consolidated 2026-10-17 from the strategy note, the expressive-consumers research (plus a
raw subagent draft), and the jit.fx audit. Stable reference: edit when evidence changes, not
when a module ships. Live status and decisions: `ideas/f_tensorfield.md`. Unbuilt
candidates: `ideas/f_tf_backlog.md`. Encoding contract: `docs/f-reference/f_tensor_type.md`._

---

## 1. The tensor-native test

Could this idea be done correctly by collapsing the tensor to a vecfield or a scalar first?
If yes, it is a **view**, not tensor-native: flag it, and do not count it toward justifying
the type. Three kinds of thing pass the test:

- **Full-tensor consumer** — reads both eigenvalues (the ellipse: direction, anisotropy and
  confidence together). Built: glyph, aniso_blur, hatch.
- **Operator** — tensor in, tensor out. Built: smooth, sharpen.
- **Producer** — makes a tensor from a non-image source (Jacobian, Hessian, metric tensor,
  authored). None built.

Views (`f_tf_axisflow`, a scalar unpacker) are support. The 2026-10-16 decision was to focus on
the first two kinds; the type stays because of them.

## 2. What a tensor can do that a vecfield cannot

- **Averages correctly.** Opposite vectors cancel when blurred or blended; opposite axes
  reinforce as tensors. This is why tensormap smooths in tensor space and why `f_tf_smooth`
  exists (mirror proof: a gradient that flips sign every frame leaves the smoothed tensor
  unchanged, while a signed-vector one-pole collapses to 25% within three frames).
- **Carries confidence** (coherence, trace) with the orientation, in one texture.
- **Two eigenvalues are an ellipse.** Anisotropic kernels, glyphs and hatching need that
  shape; one direction cannot express it.
- **One source, many views:** flow along edges, across edges, a coherence matte, a trace map.

Precedent in the vecfield family: `f_vf_split` / `f_vf_channelmap` are views, `f_vf_mix` is an
operator (unbuilt, "build when a chain needs it").

## 3. Uses, by what they need from the tensor

Condensed from the 19-row table in the 2026-10-16 strategy note. **Status as of 2026-10-17.**

| # | Use | Kind | Status |
|---|---|---|---|
| 1-2 | Flow along / across edges into advect, warp, caustic, fluid, potential, streak, weave | View | Built (`f_tf_axisflow`); advect live-checked, "across" only previewed |
| 3 | Sign-blind glow/blur | View | Straightforward via outlet 1 R/G into `f_vf_split`, or axisflow |
| 4-7 | Coherence/trace/orientation-select as plain scalar textures into mod inlets, `f_util_matrix_2`, grain/stipple density | View (scalar) | **Not built**: needs `f_tf_unpack`. Assumption unverified: existing mod inlets read `.x`, so B/A are unreachable without it |
| 8 | Marks aligned to structure | View + full tensor | `f_vf_seeds`/`f_weave` via axisflow (built path); `f_tf_hatch` is the full-tensor version (built); stipple needs new inlets (hub Q13) |
| 9 | Cross-hatch: two axisflow instances (Along, Across) into two mark layers | View x2 | Untried, cheap |
| 10 | Orientation as colour (hue = angle, sat = coherence, value = trace) | View | Speculative; `f_tf_glyph` debug tints are the nearest built thing |
| 11 | Defect/singularity map (low coherence, real trace) | View | Speculative, interesting |
| 12 | Anisotropic blur / coherence-enhancing smoothing | Full tensor | Built (`f_tf_aniso_blur`) |
| 13 | Glyph field, universal tensor debugger | Full tensor | Built (`f_tf_glyph`) |
| 14 | Temporal tensor smoothing | Operator | Built (`f_tf_smooth`) |
| 15 | Mix two tensor fields | Operator | Backlog (`f_tf_mix`) |
| 16 | Rotate / scale / threshold a tensor | Operator | Gap scaling built (`f_tf_sharpen`); rotate and threshold not built |
| 17-19 | Adaptive AA from a warp's metric tensor; Tissot indicatrix for warps; full-Jacobian caustic weight | Producer + render | Backlog: need a metric-tensor or Jacobian producer. Caustic case measured: gain only in saddle partitions (hub) |

Tensor sources beyond the structure tensor share the 2x2 shape, so everything above applies:
Jacobian of a vecfield (split into symmetric strain here and a scalar curl), Hessian of a
scalar, metric tensor of a UV warp.

---

## 4. Platform audit: what Max already ships (Phase 0, 2026-10-17)

Evidence bar: shader/gen source read directly (strongest), refpage prose, or scout-verified
web refpage (marked). Local source is under
`/Applications/Max.app/Contents/Resources/C74/packages/Jitter Tools/` (`code/fx/jxs/` GLSL
slabs, `code/fx/gen/` genjit, `code/jxs/image-fx/` classic slabs, `docs/jit.fx/` refpages).

**Namespace reality.** jit.fx lives in the Jitter Tools package on this Max 9 install (a web
scout's contrary claim describes Max 8.2-era contents). The objects are `Define` aliases over
`jit.gl.slab` / `jit.gl.pix` / v8. Two hypothesised names do not exist (`jit.fx.xy.blur2d`,
`jit.fx.dots.dither`). `jit.gl.tf` is transform feedback (GPU particle feedback), not tensor.

**Headline: no shipped object outputs, accepts or exposes a structure tensor, eigenvalue,
coherence or orientation field.** The only structure tensor in the ecosystem is
`jit.fx.cf.kuwahara`'s internal one.

| Shipped | Evidence | Relevance |
|---|---|---|
| `jit.fx.cf.kuwahara` | source | Anisotropic Kuwahara, 8 sectors, internal RGB Sobel tensor decoded per-frame in-shader (section 5) |
| `jit.fx.cf.directional` | source | 3-tap directional blur, direction is a uniform vec2 plus static grain; no coherence, no eigen |
| `jit.fx.cf.tiltshift`, `pixelsorting`, `sobel`, `repos` | refpage / source | Parametric or axis-aligned; `sobel` is magnitude only; `repos` is the one shipped field-as-content warp |
| `jit.fx.ge.flowfield` | source | Only shipped direction-field mark drawer: geometry-shader line strips reading channel B. Not buildable from gen |
| `jit.fx.tp.filter` | source | Two-pole temporal filter over MRT feedback, storage-agnostic channels: the same recurrence as `f_tf_smooth`, as a colour-pipeline tool (five knobs, no tensor gating, no `@type` guarantee) |
| `jit.fx.cf.bilateral`, `blur`, `radial`, `wake`, `conway` | source / refpage | Isotropic. No coherence-enhancing diffusion, DoG or elliptical kernel anywhere |
| `jit.fx.co.glow`, `jit.gl.pass` bloom | source / refpage | `co.glow` is an isotropic composite formula; `jit.gl.pass` needs jit.world's 3D context, unusable in Vsynth bpatcher chains |
| Hatch / stipple / halftone / engraving | web scout | **Nothing ships.** `ge.lineinterp`, `ge.randlines` are line primitives from point data |
| Optical flow | web scout | Absent in core Jitter; community answer is `cv.jit`. Ours is local Lucas-Kanade |
| Gradient direction | refpages | No matrix op outputs direction (`jit.sobel`, `jit.robcross` are magnitude only), confirming tensormap's niche |
| `cf.laplace` | source | Scalar Laplacian = the collapsed trace-of-Hessian view that `f_tf_hessian` refuses |

**The catalog against it.** Verdicts that came out of the audit, all still standing after the
builds:

- **No duplicates to kill.** Nothing shipped gives an anisotropic, tensor-input or eigen-based
  look.
- **`f_tf_smooth` vs `tp.filter`:** same math, different shape. The honest framing (stock math;
  the contribution is semantics, a one-knob performable gesture, float32 guarantees and the
  tensor inlet contract) is carried in `docs/f-reference/f_tf_smooth.md`. The library's
  precedent is re-shaping base recurrences into semantic modules (`f_vf_temporal_smooth`).
- **`f_tf_mix` vs stock xfades:** component-wise crossfade of two float32 textures is exactly
  tensor-space mixing, the weakest "needs the type" case in the catalog. Its differentiators
  are float32 guarantees, family labelling and **neutral handling**: an unconnected side must
  contribute `(0, 0.5, 0, 1)`, not zeros (zeros decode to a non-SPD phantom, see section 6).
- **`f_tf_glint` and `f_tf_glow`:** tensor-native only if lobe width / radius comes from
  per-pixel coherence rather than a dial; otherwise view-in-disguise.
- **Decode architecture:** kuwahara decodes eigenvalues, coherence and angle per-consumer,
  in-pixel, every frame. That is the precedent for per-consumer decode. The audit called the
  decode "about three lines"; the builds showed it has real traps (section 6), so the
  argument is "document the traps once", not "it is trivial". The conclusion stands.
- **Ranked chains:** nothing in the platform inventory changes them.

---

## 5. Prior art: `jit.fx.cf.kuwahara` (assessed 2026-10-16)

Max ships a generalized anisotropic Kuwahara filter (Kyprianidis et al.; polynomial-weight form
adapted from Garrett Gunnell's MIT-licensed implementation, credited in the shader header).

- **Algorithm:** 8 sectors, per-sector mean and variance, ellipse window from the local tensor,
  sectors weighted by `1/(1 + (hardness * variance)^9)`.
- **Internal tensor:** its own pass computes a 3x3 Sobel structure tensor on **RGB** (per-channel
  dot products, so it sees chroma edges a luma-only tensor misses), then a fixed-sigma-2
  Gaussian pre-blur (`pre_blur` 0-10). Decode in the main pass: `lambda1/2 = 0.5*(l0 +/- l1)`,
  coherence `A = (l1-l2)/(l1+l2)`, `phi = -atan(t.y, t.x)`.
- **Controls:** `sharpness`, `hardness`, `kernel_size` (2-20), `pre_blur` (0-10). One texture
  inlet; the tensor is neither input nor output.
- **Cost:** brute-force nested loop, up to about 2x kernel radius per side, 8 sectors per tap.

**Verdict: the look is covered; do not rebuild it.** The only legitimate reason to write our own
is a **tensor-in** version, with strokes following an authored, mixed or temporally smoothed
field. It cannot be edited, mixed, smoothed or shared today, and running it beside tensormap
computes the structure twice. Side notes: tensormap is luma-only, so an RGB-aware option would
catch chroma edges (see backlog, tensormap v2); its Gaussian pre-blur vs our box radius is a
kernel choice we could revisit. If we ever adapt it, cite Kyprianidis et al. and Gunnell (MIT)
in the docs and helpfile.

## 6. GPU and decode facts the builds established

Recorded here as evidence; the contract lives in `f_tensor_type.md` rules 5-6 and the glyph
plan's ADR-2 amendment.

- **Non-SPD phantom.** All-zeros through the outlet-0 decode gives `Jxy = -1/strength`: trace 0
  but `lambda1 = 1/strength`, `lambda2 = -1/strength`, with a plausible `atan2` axis. It looks
  like structure to any gate on eigenvalue energy. Trace-gated consumers are incidentally
  safe; energy-gated ones need an SPD test as the primary unconnected-input defence.
- **Runtime `atan2(0,0)` is NaN** on the bench GPU, while constants fold to 0. Bias the
  denominator argument (`+1e-7`); a `mix()` after the fact cannot clear a NaN (NaN * 0 = NaN).
- **`sample()` falls back to nearest** when its coordinate is data-dependent and jumps between
  neighbouring pixels. Use the four-tap `nearest()` hand-bilinear idiom.
- **Interpolation residual** is the 8-bit weight ceiling: about 2e-4 per stacked read.
- **Known unknown:** tensormap's stage C survives flat content via `mix(NaN, 0.5, iso)` while
  glyph's identical-shape `mix(NaN, 0.0, flag)` did not clear the NaN. Compiler select/fold
  behaviour, unresolved. Tensormap is verified and live-checked, so it was left alone.

---

## 7. Prior art by family

Surveyed against the tensor-native test. All operate on eigenvalues and axis together, never a
projected vector, except where flagged.

- **Coherence-enhancing / edge-enhancing diffusion (Weickert).** Anisotropic diffusion steered by
  eigen-analysis of the structure tensor: CED reinforces flow-like structure, EED avoids
  diffusing across contours. Direct ancestor of `f_tf_aniso_blur`, which is the closed-form
  one-pass simplification of an iterative PDE. A GPU stencil form reportedly exists (about 9-tap, one pass; from the unverified subagent draft, arXiv 2309.05575).
- **Anisotropic Kuwahara (Kyprianidis, Kang, Doellner 2009; polynomial weights 2010).** Painterly
  abstraction with kernel shape from the smoothed tensor. Shipped in Max (section 5).
- **Line Integral Convolution (Cabral, Leedom 1993).** Blurs noise along a vector field. Needs a
  sign, so a vecfield technique and not tensor-native; the anchor for "flow visualization" vs
  "tensor visualization". VTK has a GPU LIC as precedent. `ideas/f_vf_smear.md` sketches LIC.
- **Tensor glyphs and hyperstreamlines (DT-MRI).** Closest precedent to `f_tf_glyph`: eigenvectors
  for orientation, eigenvalues for scale (Kindlmann superquadric glyphs; hyperstreamlines are
  Delmarcelle and Hesselink 1993). G'MIC's `-structuretensors` + `-eigen` + `-display_tensors`
  renders an ellipse per cell, confirming it is cheap and legible. Scientific visualization only;
  nobody performs them.
- **Flow-guided strokes, hatching, stippling.** Tschumperle's tensor-directed strokes (ICIP 2011)
  are essentially `f_tf_hatch` already published; Kang's structure grid (2011) is a second
  architecture for confidence-scaled marks; Praun et al.'s real-time hatching (2001) is the
  reference for temporal coherence. The lineage of Ostromoukhov (artistic screening, facial
  engraving) and Kang's Coherent Line Drawing is **direction-only**: tensor-native hatching is
  open ground.
- **Tensor voting (Medioni).** Grows structure from sparse or noisy points by letting tensors cast
  votes. A producer mode not otherwise considered, and as a pure smoother it preserves
  anisotropy without being tensor-native. Unassessed for fit (backlog).
- **Hessian / ridge filters (Frangi 1998).** A second tensor source: the Hessian finds ridges and
  valleys, the structure tensor finds edges. Visually distinct on the same input. Eigenvalue-ratio
  measures are only stable above an energy floor, the same reason tensormap's coherence is noisy
  at low trace.
- **Tissot indicatrix / metric tensor of a warp.** An ellipse of local distortion; mechanically
  the first fundamental form of the warp's Jacobian. Already spiked: `f_mobius` always gives
  circles, `f_droste` real ellipses. A metric-tensor producer feeding a glyph renderer has repo
  backing.
- **VJ / creative-coding precedent.** No dedicated structure-tensor modules found in TouchDesigner
  or Shadertoy; structure tensors there are image-processing (an anisotropic Kuwahara on
  Shadertoy, optical-flow shaders), and no VJ platform exposes coherence or anisotropy as a
  performable control [inference]. The gap looks genuinely open, not just unbuilt here.

## 8. Citation corrections

Items that circulated in earlier briefs and could not be verified:

- A Bhatia et al. 2012 paper on "edge glyphs" was not found; the nearest verified match is
  Bhatia's flow-visualization "Edge Maps", which is not a tensor paper.
- "Second-Order Stippling" does not exist under that title. The citable orientation-adjacent
  lineage is Secord's weighted Voronoi stippling (NPAR 2002, scalar density only) and Kim et
  al.'s stippling by example (NPAR 2009).
- Hyperstreamlines are Delmarcelle and Hesselink 1993, not Hagen.

A subagent draft also cited Kang, Lee and Chui 2007 (Coherent Line Drawing), Kindlmann glyph
packing (VIS 2006), Gerrits et al. (TVCG 2017) and Medioni's slides; those links were damaged
in transit and are listed by name only.

---

## Sources

Collected by the original research pass:

- [Anisotropic Diffusion in ITK](https://arxiv.org/pdf/1503.00992)
- [Weickert, Coherence-enhancing diffusion of colour images](https://www.mia.uni-saarland.de/weickert/Abstracts/ced-col.html)
- [Weickert, Coherence-Enhancing Diffusion Filtering](https://datalearner.com/academic/journal-papers/0920-5691/volumes-and-issues/31/paper-detail/12739)
- [Kyprianidis, Kang, Doellner, Image and Video Abstraction by Anisotropic Kuwahara Filtering](https://umsl.edu/~kangh/Papers/kang_cgf09.pdf)
- [Kyprianidis, Semmo, Kang, Doellner, Anisotropic Kuwahara Filtering with Polynomial Weighting Functions](https://diglib.eg.org/items/9865e5fe-3d23-470e-8cf6-e571bebafb9b/full)
- [Cabral, Leedom, Imaging Vector Fields Using Line Integral Convolution](https://courses.cs.duke.edu/spring03/cps296.8/papers/cabralLineIntegralConvolutions.pdf)
- [DT-MRI Visualization with Streamtubes (Delmarcelle/Hesselink, Kindlmann)](https://www2.cs.sfu.ca/~hamarneh/ecopy/spiemi2007c.pdf)
- [Visualization of Tensor Fields Using Superquadric Glyphs](https://pmc.ncbi.nlm.nih.gov/articles/PMC2169197)
- [G'MIC -structuretensors / -eigen / -display_tensors](https://gmic.eu/oldtutorial/_structuretensors.html)
- [Medioni, Tensor Voting](https://homepages.inf.ed.ac.uk/rbf/CVonline/LOCAL_COPIES/MORDOHAI/tensorvoting.html)
- [Tschumperle, Tensor-Directed Simulation of Strokes (ICIP 2011)](https://tschumperle.users.greyc.fr/slides/slides_icip2011.pdf)
- [Kang, Structure grid for directional stippling](https://umsl.edu/~kangh/Papers/kang_gm2011.pdf)
- [Praun, Hoppe, Webb, Finkelstein, Real-time hatching](https://collaborate.princeton.edu/en/publications/real-time-hatching-2/)
- [Frangi et al., Multiscale Vessel Enhancement Filtering](https://www.doi.org/10.1007/BFB0056195)
- [Ridge filters / Hessian eigenvalues reference implementation](https://mitra.stanford.edu/kundaje/marinovg/oak/various/programs/skimage/filters/ridges.py)
- [Tissot Indicatrix for Map Projection Distortion](https://unstats.un.org/unsd/geoinfo/ungegn/docs/_data_ICAcourses/_pdf/selfstudy/s06/S06_02b.pdf)

Added from the subagent draft, **not re-verified**:

- [Weickert, Anisotropic Diffusion in Image Processing (book)](https://www.mia.uni-saarland.de/weickert/Papers/book.pdf)
- [Kyprianidis et al., Anisotropic Kuwahara Filtering on the GPU (PG 2009)](https://kyprianidis.com/p/pg2009/jkyprian-pg2009.pdf)
- [Kang, Coherent Line Drawing / edge tangent field](https://www.cs.princeton.edu/courses/archive/spring16/cos426/papers/Kang09.pdf)
- [Ostromoukhov and Hersch, Artistic Screening (SIGGRAPH 1995)](https://perso.liris.cnrs.fr/victor.ostromoukhov/publications/pdf/SIGGRAPH95_ArtisticScreening.pdf)
- [Secord, Weighted Voronoi Stippling (NPAR 2002)](https://www.cs.ubc.ca/labs/imager/tr/2002/secord2002b/secord.2002b.pdf)
- [Kim et al., Stippling by Example (NPAR 2009)](https://dl.acm.org/doi/abs/10.1145/1572614.1572622)
- [Kindlmann, superquadric tensor glyphs (VisSym 2004)](http://people.cs.uchicago.edu/~glk/pubs/pdf/Kindlmann-Superquad1-Table2-VisSym-2004.pdf)
- [VTK vtkLineIntegralConvolution2D](https://vtk.org/doc/nightly/html/classvtkLineIntegralConvolution2D.html)
- [Tissot indicatrix (map-projections.net)](https://map-projections.net/tissot.php) and [QGIS tiss plugin](https://plugins.qgis.org/plugins/tiss)
- [Shadertoy anisotropic Kuwahara](https://www.shadertoy.com/view/Md23DV) and [CShade cFlow](https://github.com/papadanku/CShade/blob/main/shaders/cFlow.fx)

Jitter and Max references: [jit.gl.pass](https://docs.cycling74.com/max8/refpages/jit.gl.pass),
[jit.gl.mesh](https://docs.cycling74.com/max8/refpages/jit.gl.mesh),
[jit.convolve](https://docs.cycling74.com/max8/refpages/jit.convolve),
[jit.sobel](https://docs.cycling74.com/max8/refpages/jit.sobel),
[max_define userguide](https://docs.cycling74.com/userguide/max_define/),
[Max 9 release notes](https://cycling74.com/releases/max/9.0.0),
[cv.jit](https://github.com/Cycling74/cv.jit).
