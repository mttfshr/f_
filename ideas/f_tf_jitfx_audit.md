# jit.fx / built-in Max audit vs. thetensor-family catalog

_Created: 2026-10-17. Status: Phase 0 audit, complete. Companion to `f_tf_build_brief.md` §3/§8
and `f_tf_tensor_strategy.md` §Prior art (which assessed `jit.fx.cf.kuwahara` only). This doc
extends the same evidence bar to the rest of the shipped namespace._

_Evidence bar: shader/gen source read directly (strongest), refpage read (prose), or scout-
verified web refpage (marked). Everything here was checked against the actual files in_
`/Applications/Max.app/Contents/Resources/C74/` _unless explicitly marked as web-only._

---

## 1. Namespace reality (one correction, one confirmation)

- **jit.fx lives in the Jitter Tools package on disk.** All `jit.fx.*` refpages ship under
  `packages/Jitter Tools/docs/jit.fx/`, all effect shaders under `packages/Jitter Tools/code/fx/`
  (`jxs/` = GLSL slabs, `gen/` = `.genjit` sources for the gen-based ones), and the classic
  `jit.*`-flavored slab library under `packages/Jitter Tools/code/jxs/` (`image-fx/{color,
  convolution,generator,specialfx,temporal,texdisplace,transition}`, `math/op.*`, `composite/`,
  `pass-fx/`, `mrt/`, `viz/`). A web scout's claim that "Jitter Tools is not jit.fx's home" is
  wrong for this Max 9 install — that describes the package's Max 8.2-era contents. The
  `jit.fx` objects are `Define`-aliases over `jit.gl.slab`/`jit.gl.pix`/v8
  (docs.cycling74.com/userguide/max_define/), which is why source files are jxs/genjit rather
  than mxo internals.
- **Two module names hypothesized during audit scoping do not exist** and were correctly
  flagged as such by the web scout: `jit.fx.xy.blur2d`, `jit.fx.dots.dither` (404, no web
  trace). Not used further.
- **`jit.gl.tf` is transform feedback, not tensor** [INFERENCE from the glcore examples]:
  the `xform-feedback` example set ships `tf.vecfield.jxs`, `tf.curl.noise.update.jxs`, etc.
  — `tf` = transform feedback, the GPU particle-feedback mechanism. Nothing tensor-related.

## 2. What ships, by relevance to the catalog

### 2.1 Anisotropic / orientation-aware (the short list)

| Module | Evidence | What it actually does | Orientation source |
|---|---|---|---|
| `jit.fx.cf.kuwahara` | source read (`code/fx/jxs/jit.fx.cf.kuwahara{,gaussian_h,gaussian_v,tensor}.jxs`) + strategy doc | Generalized anisotropic Kuwahara, 8-sector polynomial weighting. Already fully assessed 2026-10-16. | **Internal** structure tensor: `kuwahara.tensor.jxs` computes a 3×3 **Sobel on RGB per channel** (dot(Sx,Sx), dot(Sy,Sy), dot(Sx,Sy)) — raw outer product, not luma, not smoothed. The main pass decodes eigenvalues in-shader: `lambda1/2 = 0.5*(l0 ± l1)`, coherence `A = (l1−l2)/(l1+l2)`, angle `phi = −atan(t.y,t.x)`. Tensor is neither in nor out. |
| `jit.fx.cf.directional` | source read | Directional blur: **3-tap** tri-weight line integral (`0.294 center, 0.353±offset`), offset = `1.333·direction·blur_amount·rand`, `direction` is a **uniform vec2 param**, plus a static grain texture (stbn) scaled by the same rand. No loop, no coherence, no eigen anything. | Performer uniform only |
| `jit.fx.cf.tiltshift` | refpage (web scout) + source params | Tilt-shift blur; `angle` rotates the blur **plane** (linear mode), radial/`center` otherwise. Orientation of the blur is parametric. | Performer param only |
| `jit.fx.pixelsorting` | refpage (web scout) | Pixel sorting; `dimmode` horizontal/vertical, `sortdir`. Axis-aligned. | Axis enumeration only |
| `jit.fx.sobel` / `jit.fx.sobel` (classic `code/jxs/image-fx/convolution/cf.sobel.jxs`) | source read | Gradient **magnitude** + threshold. RGB-magnitude form (`sqrt(h²+v²)` per channel); no direction, no output of gx/gy. | none |
| `jit.fx.repos` / `td.repos.jxs` | refpage (web scout) | Displacement-map warp primitive. Direction comes from whatever map is fed — the one shipped "field as content" warp. | from input map |
| `jit.fx.ge.flowfield` | source read (`code/fx/jxs/jit.fx.ge.flowfield.draw.lines.jxs`) | **The one shipped consumer of a direction field for mark drawing**: geometry-shader line strips (127 vertices per stroke, `max_vertices=128`), random-walk seeds, `angle = mix(texture(tex0).b·rotation, prev, smoothness) + randomness·rand`. Field read from **channel B** of a plain texture. | texture channel, geometry shader (not pix-able; gen can't do geometry shaders) |

**No shipped module computes, exposes, or consumes an eigenvalue, coherence, or axis field as
such.** The web scout's category-G sweep (all refpages; search terms anisotropy/coherence/
eigenvalue) found hits only inside kuwahara's own prose. The one C74 codebase that *does*
consume a structure tensor (`jit.fx.cf.kuwahara`) takes it from its own internal pass.

### 2.2 Isotropic blur / edge-preserving / temporal

| Module | Evidence | Notes for the catalog |
|---|---|---|
| `jit.fx.cf.bilateral` | source read | 15×15 bilateral, fixed SIGMA/BSIGMA defines, fully **isotropic** — no orientation input |
| `jit.fx.blur` → `cf.gaussian.h/v` | refpage + source params | Gaussian; the `jit.fx.blur` refpage's See-Also reveals the implementation alias |
| `jit.fx.cf.radial` | source params (`blur_amount`, `center`, `mode`) | Radial blur from a center point; starburst/zoom flavors |
| `jit.fx.tp.filter` | **source read** | Two-pole temporal filter as an MRT gen shader: `out2 = in0·a0 + in1·a1 + in2·a2 − in3·b1 − in4·b2` with feedback via `out3 = in3`. **Channels are storage-agnostic** — it filters whatever sits in RGBA. Linear, no saturation control, 4 texture inlets/4 outlets, unclamped float pipeline. |
| `jit.fx.tp.delay` | refpage description | Frame-accurate texture delay |
| `jit.fx.wake` | refpage description | Feedback + convolution; stock trail effect |
| `jit.fx.conway` | refpage description | Game of Life on textures |
| `jit.fx.ameba`, `bitcrush`, `threshold`, `bsort`, `pixelsorting` | refpage descriptions | Assorted — none orientation-aware |

**No coherence-enhancing / anisotropic diffusion, no DoG, no edge-aware elliptical kernel
anywhere in shipped Jitter** beyond kuwahara's internal sector logic.

### 2.3 Bloom / glow / glint / streak

| Module | Evidence | Notes |
|---|---|---|
| `jit.fx.co.glow` | **source read** | Composite formula only: `result = (b·b)/(1−a)` mixed by `amount` — an inverse-dodge/overflow glow between two textures. **Isotropic, no geometry**, not an accumulation. |
| `jit.gl.pass` bloom/motionblur/smear/dof | refpage (web scout, max8 refpage; Max 9 adds dof-hq, TAA, ReSTIR GI, grain) | Screen-space 3D render passes: bloom and motion-blur exist **but require jit.world's 3D context (velocity/normals RTs)** — unusable in the Vsynth bpatcher chain (consistent with the f_lens Phase 0 note). Isotropic in their 2D application. |
| Vizzie `vz.glow`-family, `vz.embossr` etc. | patcher dir listing + shader file presence (`v001.co2.glow.fp.glsl`) | 8-bit-era additive glow; emboss is isotropic; no orientation content anywhere in Vizzie |
| — | — | **No glint, anamorphic streak, or field-following glow ships.** Our `f_vf_glow`, `f_vf_streak`, `f_vf_chroma`/`f_vf_prism` are the local stack for that territory. |

### 2.4 Hatching / stipple / halftone / engraving

**Nothing ships.** Category-D sweep (web scout, docs + web): no hatching, stipple, halftone,
dither (beyond `bitcrush` quantization and forum recipes), or engraving object in core Jitter
or jit.fx. Adjacent shipped items: `jit.fx.ge.lineinterp` + `jit.fx.ge.pattern` (9.1 additions;
line interpolation between point pairs and pattern tiling — geometric interventions, not
orientation-field renderers), `jit.fx.ge.randlines` (source params: `radius`, `alpha` over drawn
lines), and classic `gn.stripes/bricks/checker` tile generators (fixed axes). Our
`f_weave`/`f_stipple`/`f_vf_seeds` have no shipped analog or competitor. `f_stipple`'s
`anisotropy`/`angle` params remain the most tensor-shaped UI in the whole ecosystem, per the
hub doc's earlier audit.

### 2.5 Producers: fields, flow, derivatives

| Module | Evidence | Notes |
|---|---|---|
| optical flow / motion | **absent**: no `jit.*opticalflow*` file in the bundle, refpage 404, absent from release notes (web scout). Max 9's `jit.gl.pass` velocity RT is 3D-context only. The community answer is `cv.jit` (motion family) [INFERENCE on object names]. Our `f_vf_optical_flow` is local LK. | relevant to `f_tf_motion` |
| gradient direction | **no matrix op outputs direction**: legacy `jit.sobel`/`jit.robcross` emit magnitude only; `jit.convolve` is a fixed user-kernel correlator; `jit.gl.mesh` auto-normal/tangent are the only curvature-adjacent computations and produce no eigen/tensor data (web scout, refpages). To get a bearing one must compose convolves + `jit.expr` atan2 on the CPU matrix side. | confirms `f_tf_tensormap`'s niche |
| Laplacian | classic `code/jxs/image-fx/convolution/cf.laplace.jxs` | Isotropic second derivative = trace-of-Hessian as a scalar **view** — the exact collapse `f_tf_hessian` refuses |
| analytic field generators | classic `gn.gnoise.2d`, `gn.stripes/bricks/spiderweb/spirals` | plain texture generators, no field semantics; `jit.gen`'s `dy`/pixel-level gradient exists but is not a field output |

## 3. Match against the twelve catalog items

For each brief §4 item: what (if anything) shipped already gives the look, whether the
**tensor-in** reason survives, and the finding triage should weigh. "—" = nothing shipped.

| Catalog item | Closest shipped | Does it give the look? | Tensor-in reason valid? |
|---|---|---|---|
| `f_tf_aniso_blur` | `cf.directional` (3-tap, uniform direction), `tiltshift` (parametric plane), `cf.bilateral` (isotropic) | **No.** Nothing ships content-driven elliptical kernels; no coherence-enhancing filter exists. Kuwahara is painterly with an internal tensor — different math, no tensor plumbing. | Yes — the entire point of the type (strategy row 12) |
| `f_tf_smooth` | `jit.fx.tp.filter` (source read): per-channel two-pole with MRT feedback; channels are storage-agnostic | **Approximately yes** — tp.filter's linear recurrence would run on tensor components unchanged. What's missing: tensor-space framing (release-only semantics, family float32 @type guarantee, Vsynth UI/dial, f_-family inlet conventions), and tp.filter's 4-in/4-out shape is a color-pipeline tool with ringing b coefficients, not a performable one-knob smoother. Same gap shape the family already filled instead of reusing stock: `f_vf_temporal_smooth` (parked idea) exists for exactly this reason on the vecfield side. | Mostly no (mathwise) — the case is integration + semantics, which is how the library treats all its `f_` re-shapes; flag honestly in the spec |
| `f_tf_sharpen` | `cf.sharpen` (image sharpening, `amt`) — unrelated semantics | No. Eigen-gap operators are unheard of. | Yes |
| `f_tf_mix` | every composite/xfade (`co.xfade`, `brcosa`, Vizzie mixers) blends **textures** component-wise | **Component-wise crossfade of two float32 textures is exactly tensor-space mixing** — the math is identical to stock xfade. What a dedicated module adds: float32 @type guarantee (stock composite pipeline is 8-bit-ish in places), tensor-family semantics/labels, and the neutral-when-unconnected convention (vs_black decodes to c2=s2=−1, not neutral — a stock xfade would silently mix garbage axes at zero contribution). Flag: this is the one catalog item where "already shipped" is closest to true. | Weakest of the set — defensible, but say so |
| `f_tf_glyph` | — (nothing ships glyphs, tensor output, or eigen anything) | Distinct look, plus the C74 space has no tensor readout at all. `ge.flowfield` draws flow lines via geometry shader — adjacent drawing-of-a-field, different geometry, not glyphs, and geometry shaders can't be built from gen. | Yes |
| `f_tf_hatch` | — (no hatch/stipple/halftone ships; `ge.lineinterp`/`ge.randlines` are line primitives from point data) | Look is open ground. | Yes (hatch commit = per-pixel confidence; see brief) |
| `f_tf_glint` | — (no glint/streak); locally `f_lens` halation/ghosts are radial, `f_vf_chroma/prism` split channels | Open ground, but the brief's view-in-disguise flag stands: a dial-width lobe is exactly what `f_lens` already offers parameter-side. Only per-pixel coherence width earns the inlet. | Conditional — flag preserved |
| `f_tf_glow` | `co.glow` (isotropic composite), `jit.gl.pass` bloom (3D-world only); locally `f_vf_glow` is already the field-following glow | Local module covers the look. | Borderline per brief — radius must come per-pixel coherence or it's Q12's parked scalar gate. Preserved as flag. |
| `f_tf_jacobian` | — (no curl/strain/field-derivative anywhere; `jit.fx.sobel` of a vecfield-as-texture would give signless magnitude ≈ trace-view only) | Open ground. | Yes |
| `f_tf_motion` | — (no optical flow ships; local `f_vf_optical_flow` confirmed: standard 0.5-centered vecfield out0 + confidence/aperture signal out1) | Open ground; the producer (optical flow) is local. | Yes; same math as jacobian on a specific producer |
| `f_tf_hessian` | `cf.laplace` = scalar Laplacian (the trace-of-Hessian **view**); `cf.normals` = sobel→normal map for 3D | No shipped Hessian tensor. The shipped laplace is literally the collapsed version of the idea — nice contrast for the spec's tensor-native statement. | Yes |
| `f_tf_authored` | — (no analytic field generators with field semantics; gn.* are textures) | Open ground. | Yes, but UI-density blocker (brief OQ4) is orthogonal and real |
| `f_tf_decode` (open question) | **kuwahara is the precedent**: its main pass decodes eigenvalues, coherence and angle in-consumer from the raw tensor texture each frame | Nothing ships a standalone decoder; C74's own consumer decodes **per-consumer, in-pixel** | n/a — but the ecosystem's own consumer never needed a central decoder either |

## 4. Findings triage should weigh

1. **The tensor gap is real at the platform level.** No shipped object outputs or accepts a
   structure tensor, eigenvalue, coherence, or orientation field; the only structure tensor in
   the entire ecosystem is kuwahara's internal, untouchable one. Nothing to merge with, nothing
   to duplicate — the family has the namespace to itself.
2. **Two catalog items have near-shipped cousins and must be spec'd honestly against them**:
   `f_tf_smooth` vs `jit.fx.tp.filter` (the same recurrence is a color-pipeline tool; our
   version is a one-knob, tensor-family, float32-guaranteed module — the f_-family precedent
   for this exact situation is that the library re-shapes base capabilities into performable
   semantic modules rather than adopting stock ones), and `f_tf_mix` vs stock composite xfades
   (identical math; the differentiators are float32 guarantees and neutral-vs_black handling).
3. **Two catalog items carry the brief's view-in-disguise flags onward**: `f_tf_glint` and
   `f_tf_glow` are only tensor-native if their secondary shape parameter (lobe width, radius)
   comes from per-pixel coherence rather than a dial. Nothing shipped contradicts this; both
   flags preserved into triage.
4. **`f_tf_decode` has an in-house precedent on the no-dedicated-module side**: C74's own
   kuwahara decodes eigenvalues in-consumer per frame from a raw tensor texture. The decode is
   ~3 lines of closed form. A central module would add a pipeline hop and another adapter —
   exactly what the strategy note warned about making "the adapters the interface."
5. **Nothing about the C74 inventory changes the ranked chains.** Chain A/B/C/D inputs and
   stages are all uncataloged looks and semantics; the platform offers no competing rig.

## 5. Sources

**Local (primary, this audit):**
- `/Applications/Max.app/Contents/Resources/C74/packages/Jitter Tools/code/fx/jxs/` —
  `jit.fx.cf.kuwahara.jxs`, `jit.fx.cf.kuwahara.tensor.jxs`, `jit.fx.cf.directional.jxs`,
  `jit.fx.cf.bilateral.jxs`, `jit.fx.cf.radial.jxs`, `jit.fx.sobel.jxs`,
  `jit.fx.ge.flowfield.draw.lines.jxs`, `jit.fx.ge.randlines.jxs`, `jit.fx.sharpen.jxs`,
  `jit.fx.grain.jxs`
- `.../packages/Jitter Tools/code/fx/jxs/jit.fx.tp.filter.jxs` (temporal two-pole source)
- `.../packages/Jitter Tools/code/fx/gen/` — `fx.ameba/altern/eclipse.genjit`
- `.../packages/Jitter Tools/code/jxs/image-fx/{convolution,generator,specialfx,temporal,
  texdisplace,color}/` — classic slab library incl. `cf.laplace.jxs`, `cf.normals.jxs`,
  `cf.gaussian.2p.jxs`
- `.../packages/Jitter Tools/code/jxs/image-fx/composite/co.glow.jxs`
- `.../packages/Jitter Tools/docs/jit.fx/*.maxref.xml` — full jit.fx refpage set (descriptions
  quoted for tp.delay/filter, wake, eclipse, ameba, altern, bsort, brass, dimmap,
  pixelsorting, crt, vhs, conway)
- `.../packages/Vizzie/patchers/` + `media/v001/v001.co2.glow.jxs` — Vizzie sweep
- `.../packages/Jitter Tools/misc/jitter/passes/{bloom,motionblur,motionblur-hq}.jxp`,
  `patchers/pass-effects/`, `code/jxs/{mrt/hdr.bloom*,image-fx/composite/co.glow.jxs}`,
  `code/jxs/pass-fx/dof.bokeh.jxs` — pass-effect inventory
- `docs/refpages/jit-ref/jit.convolve.maxref.xml` (via scout, local refpage exists)

**Web (scout-verified):**
- [jit.gl.pass refpage](https://docs.cycling74.com/max8/refpages/jit.gl.pass) — pass list,
  NORMALS/VELOCITY inputs, quality attr
- [jit.gl.mesh refpage](https://docs.cycling74.com/max8/refpages/jit.gl.mesh) —
  auto_normals/auto_tangents only; no tensor/eigen
- [jit.convolve refpage](https://docs.cycling74.com/max8/refpages/jit.convolve) — fixed
  user-kernel correlation
- [jit.sobel refpage](https://docs.cycling74.com/max8/refpages/jit.sobel) — magnitude-only
- [Max 7 functional Jitter listing](https://docs.cycling74.com/legacy/max7/vignettes/jitter_functional) —
  legacy matrix-op sweep (jit.robcross etc.)
- [max_define userguide](https://docs.cycling74.com/userguide/max_define/) — jit.fx = Define
  aliases over slab/pix/v8
- [Max 9.0.0 / 9.1.0 / 9.2.0 release notes](https://cycling74.com/releases/max/9.0.0) —
  pass-effect and 9.1 jit.fx additions (cf.kuwahara, cf.tiltshift, ge.lineinterp, ge.pattern)
- [cv.jit package](https://github.com/Cycling74/cv.jit) — community CV/motion stack
  [INFERENCE: object names not re-read this session]