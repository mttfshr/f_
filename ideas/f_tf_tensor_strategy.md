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
