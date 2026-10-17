# Tensor field strategy: what is the tensor type for?

_Created: 2026-10-16. Status: open question, awaiting Matt's answer (see "The decision")._
_Context: `f_tf_tensormap` and `f_tf_axisflow` are built and live-checked. Before designing
the first consumer (`f_vf_glow` anisotropy inlet, hub Q12), Matt asked the strategic question:
if every downstream module needs an adapter, why have a tensor type at all, and why not output
something vecfield consumers can use directly?_
_Hub: `ideas/f_tensorfield.md`. Type contract: `docs/f-reference/f_tensor_type.md`._

---

## The honest finding

Every concrete use found so far is a **view** of the tensor, not the tensor itself:

| Use | Needs | Delivered by |
|---|---|---|
| Flow along/across edges into advect, warp, caustic, ... | a signed vector | `f_tf_axisflow` (built) |
| Glow radius/direction gating, chroma/prism strength | a scalar (coherence, trace) | nothing yet; needs an unpacker |
| Stipple angle + anisotropy | direction + confidence | views (axis is enough) |
| Anisotropic blur, painterly (Kuwahara-style), glyph/hatching renderer, photoelastic | **the full tensor** (two eigenvalues = an ellipse) | nothing built; all ideas |

If views are all that ever get built, the adapters are the real interface and the tensor is
internal plumbing of the tensormap. The type earns its keep only if something works *on
tensors*.

## What a tensor can do that a vecfield cannot

- **Averages correctly.** Opposite vectors cancel to zero when blurred or blended; opposite
  axes reinforce as tensors. The tensormap already smooths in tensor space for this reason.
  Same for temporal smoothing, mixing two fields, or adding the structure of two sources.
- **Carries confidence** (coherence, trace) with the orientation, no second texture.
- **Two eigenvalues = an ellipse.** Anisotropic blur kernels, painterly filters, glyph and
  hatching renderers need that shape; one direction cannot express it.
- **One source, many views:** flow along edges, across edges, a coherence matte, a trace map.

Precedent: the vecfield family already has the same split. `f_vf_split` and
`f_vf_channelmap` are views/adapters; `f_vf_mix` is a vecfield-space operator (not built, "build
when a real chain needs it"). The tensor family has `f_tf_axisflow` as its first view and no
operators yet.

## Proposed strategy

1. **Views are the default interface.** Two for now: `f_tf_axisflow` (vectors, built) and a
   small scalar unpacker (coherence, trace as plain textures, like `f_vf_split` for vecfields;
   not built). These are what `f_tf_` hands to everyone else.
2. **No per-module tensor inlets** unless the consumer's math needs the whole tensor, or its
   neutral-when-unconnected is not zero (glow's confidence gate wants 1.0).
3. **The type is justified by** tensor-space operators (temporal smoothing, mixing, combining
   fields) and by full-tensor consumers (anisotropic blur, glyphs, hatching).
4. **A test with a deadline.** If the next few things built are all views, collapse the
   design: give the tensormap vecfield and scalar outlets directly and retire the adapters.
   Cost of collapsing now: tensor-space operators could no longer sit between producer and
   view (fine if none ever get built), and it reverses the 2026-10-13 two-outlet decision.

## Rule for deciding how a consumer takes tensor data

- Needs a **vector** -> via axisflow, no new inlet.
- Needs a **scalar** (coherence/trace) -> via the unpacker into an **existing** mod inlet
  (assumption to verify: existing mod inlets read `.x`, so B/A are unreachable without it).
- Needs **several channels together or the full tensor**, or a non-zero neutral -> a new
  per-module inlet, case by case. Prefer zero-new-UI (free mod inlet + `state_param`);
  anything needing a new dial waits for `mod_depth_ui_density.md`.
- Multiply, do not replace, performer dials with data confidence (hub Q15).

## Brainstorm: what to do with the outputs of any tensor generator (2026-10-16)

_Brainstorm, not a plan. Nothing here is decided; consumer fits come from `module-inventory.md`
descriptions and the hub's audit, not from reading every codebox (marked "check" where a fit
depends on an unread detail)._

**Mode legend.** **View**: lossy projection into a type existing modules already take (a vecfield
or a scalar mask). **Full tensor**: the module reads all components (eigenvalues and axes).
**Operator**: tensor in, tensor out (the tensor-space analog of `f_vf_mix`).

**Tensor sources beyond the structure tensor** (same 2x2 shape, so everything below applies):
structure tensor (built); Jacobian of a vecfield (strain/shear/curl, from `f_vf_fluid`, vortex
fields); Hessian of a scalar (curvature, ridges and valleys); metric tensor of a UV warp (stretch
of `f_mobius`, `f_lens`, `f_droste`, `f_stereo`; the Tissot indicatrix). A Jacobian is not
symmetric: split it into a symmetric strain tensor (this family) and a scalar curl.

### Table 1: uses, by what they need from the tensor

| # | Use | Mode | Path | Candidate consumers | Status |
|---|---|---|---|---|---|
| 1 | Flow **along** edges: paint/smear/advect following contours | View (vector) | `f_tf_axisflow` Along | `f_vf_advect`, `f_vf_warp`, `f_caustic`, `f_vf_fluid` (force), `f_vf_potential`, `f_vf_streak`, `f_weave` in2 | Built; advect live-checked |
| 2 | Flow **across** edges: push toward/away from edges, edge-expanding warp | View (vector) | axisflow Across | same set | Built, not tried beyond preview |
| 3 | Orientation-aligned glow/blur that ignores sign | View (axis-blind) | outlet 1 R/G into `f_vf_split` (cos 2t, sin 2t), or axisflow | `f_vf_glow` bidirectional (axis-blind by design), `f_vf_streak` | Straightforward |
| 4 | **Confidence matte**: where is there structure | View (scalar, coherence) | scalar unpacker (to build) | any mod inlet: `f_vf_chroma` (hue/dispersion mod), `f_vf_prism` (reach/spread mod), `f_vf_seeds` (mod tex), `f_lens` (4 mod tex), glow radius mod (check inlet channel) | Needs unpacker |
| 5 | Drive **any** param from tensor data, no per-module inlets | View (scalar) | unpacker into `f_util_matrix_2` as a source | whatever params the matrix can target | Needs unpacker; check matrix source semantics |
| 6 | **Detail/energy map**: grain density and size follow where edges are | View (scalar, trace) | unpacker | `f_grain` (jitter, size var; hub Q14), `f_stipple` density/size, `f_vf_seeds` size_mod | Needs unpacker |
| 7 | **Orientation-selective** effects: only edges near angle phi | View (scalar, cos^2(theta-phi) x coherence) | unpacker variant | any mod inlet as a mask | Speculative, cheap |
| 8 | Marks/lines **aligned to structure**: hatching, stipple orientation, contour-following lines | View (axis + confidence) | axisflow into vecfield inlet | `f_vf_seeds` (oriented marks), `f_weave` in2 (lines follow contours), `f_stipple` angle + anisotropy per pixel (hub Q13, needs new inlets) | seeds/weave: built path; stipple: needs design |
| 9 | **Cross-hatch** from one image: layer 1 along, layer 2 across | View x2 | two axisflow instances (Along, Across) | two `f_weave` or `f_vf_seeds` layers | Cheap trick, untried |
| 10 | **Orientation as color** (hue = angle, sat = coherence, value = trace): diagnostic and art | View (color) | small viewer module | feed `f_hue_processor` to select edges by orientation; or display | Speculative |
| 11 | **Defect/singularity map**: low coherence but real trace marks points where orientation winds | View (scalar) | unpacker variant | `f_vf_seeds` placement, sparkle/particle emitters | Speculative, interesting |
| 12 | **Anisotropic blur / coherence-enhancing smoothing / Kuwahara painterly** | **Full tensor** | new consumer module | the tensor-native module itself (needs both eigenvalues for the kernel ellipse) | Idea; the strongest argument for keeping the type |
| 13 | **Glyph/ellipse field renderer** (ellipses, crosses, hatch ticks per cell; works for any tensor source) | **Full tensor** | new consumer module | itself; doubles as the universal tensor debugger | Idea (hub "Future") |
| 14 | **Temporal smoothing** of the tensor: stable flow from jittery video | **Operator** | new `f_tf_` module (feedback average in tensor space) | between tensormap and any view | Idea; tensors average correctly, vectors do not |
| 15 | **Mix / combine** two tensor fields (crossfade, add the structure of two sources) | **Operator** | new `f_tf_mix` (analog of `f_vf_mix`) | between producers and views | Idea |
| 16 | **Rotate / scale / threshold** a tensor (twist the whole field, sharpen coherence) | **Operator** | could fold into 14/15 | | Idea |
| 17 | **Adaptive anti-aliasing** from a warp's metric tensor | Full tensor or scalar (lambda max) | metric-tensor producer, then view | `f_masonry`, `f_weave` (mortar and line aliasing; `vector_field_math_concepts.md` #11) | Needs a metric-tensor producer |
| 18 | **Tissot indicatrix** diagnostic for warps | Full tensor render | metric-tensor producer + glyph renderer | `f_stereo` (never run), `f_lens` (prediction: always circles) | Needs producer + #13 |
| 19 | **Full-Jacobian weighting** for caustics | Full tensor | Jacobian producer | `f_caustic` (hub: measured, small gain, saddle partitions only) | Low priority, measured |

### Table 2: the modules these uses would justify

| Module | Kind | Unlocks rows | Cost / notes |
|---|---|---|---|
| `f_tf_axisflow` | View (vector) | 1, 2, 8, 9 | Built |
| `f_tf_unpack` (coherence, trace, orientation-select mask as plain textures) | View (scalar) | 4, 5, 6, 7, 11 | One pass, no params to speak of; analog of `f_vf_split` |
| `f_tf_color` (orientation to hue) | View (color) | 10 | Tiny; mostly a debug and look tool |
| `f_tf_glyph` | Full-tensor consumer | 13, 18 | Real design work; universal tensor debugger |
| `f_tf_aniso_blur` | Full-tensor consumer | 12 | Real design work; the standout "needs the type" candidate |
| `f_tf_smooth` (temporal) and `f_tf_mix` | Operators | 14, 15, 16 | Feedback pass / two-input blend; cheap once the encoding contract is fixed |
| metric-tensor and Jacobian producers | New sources | 17, 18, 19 | Separate producer specs; reuse the contract |

**How to read it.** Rows 1-11 are all views: valuable, but they need only axisflow plus one
unpacker, which says "views are the interface". Rows 12-16 are what actually justify a tensor
*type*: `f_tf_aniso_blur`, `f_tf_glyph` and the operators. Of those, temporal smoothing (14) is
the cheapest to prove and the most useful on live video; anisotropic blur (12) is the most
distinctive look. If none of 12-16 appeals, that is the "collapse" signal from the strategy
above.

## Consequence for hub Q12 (`f_vf_glow` anisotropy inlet)

Likely smaller than designed. Axisflow already removes the branch cut that motivated Q12's
safety argument, and its `gate` scales flow to zero at low coherence, which glow's existing
field-suppress turns into "no glow there". What a dedicated inlet still adds is a *different
low-confidence behaviour*: fall back to symmetric (bidirectional) glow instead of none. That is
a taste decision, so the next step is one live test (tensormap -> axisflow -> glow in2) before
building anything. Tasks T039-T043 in `.specify/f_vf_glow/tasks.md` stay parked until then.

## The decision (Matt)

Is there a tensor-space operator or full-tensor consumer actually wanted (temporal smoothing,
anisotropic blur, hatching)?
- **Yes** -> keep the type; build views around it (scalar unpacker next), build the wanted
  operator/consumer as the justification.
- **No** -> fold the views into the tensormap (vecfield + scalar outlets) and drop the
  adapters.

## Related

- `ideas/f_tensorfield.md` (hub, consumer audit, Q12-Q15), `docs/f-reference/f_tensor_type.md`
- `ideas/named_mod_textures.md` (a shared-inlet tag mechanism could replace per-module inlets
  entirely; gated on its own open verification items)
- `ideas/mod_depth_ui_density.md` (why new dials are expensive)
- `.specify/f_tf_axisflow/spec.md` (the first view; deferred v2: per-pixel reference inlet)
