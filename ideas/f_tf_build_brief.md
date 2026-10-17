# f_tf build brief — combined reference for tensor-family module development

_Created: 2026-10-17. Status: handoff brief, not itself a spec. Purpose: a single
entry point for subagent work fleshing out full-tensor consumer modules into
`.specify/<module>/{spec,plan,tasks}.md`, so that work doesn't require re-reading
~950 lines spread across three source docs first._

_Source docs this compiles (read these directly for anything not covered below —
nothing here supersedes them): `ideas/f_tensorfield.md` (hub, full consumer audit),
`ideas/f_tf_tensor_strategy.md` (the decision + Tables 1/2 + jit.fx.cf.kuwahara
research), `ideas/f_tf_expressive_consumers.md` (prior art + 11 new candidates +
ranking). Reference contracts: `docs/f-reference/f_tensor_type.md`,
`docs/f-reference/f_tf_tensormap.md`, `docs/f-reference/f_tf_axisflow.md`._

---

## 1. What's already built, and the contract

Two modules exist and are live-checked:

**`f_tf_tensormap`** — the structure-tensor producer. Takes any scalar-dominant
texture, derives a 2×2 symmetric structure tensor from its local gradient. Two
outlets, one computed pass:
- **Outlet 0, raw tensor** (float32, unclamped): R = Jxx·strength, G =
  Jxy·strength·0.5+0.5 (signed, 0.5=zero), B = Jyy·strength, A = 1. Lossless. No
  consumer built yet — this is the input every full-tensor module below reads.
- **Outlet 1, packed** (float32): R = cos2θ·0.5+0.5, G = sin2θ·0.5+0.5, B =
  clamp(trace·strength), A = coherence (λ1−λ2)/(λ1+λ2), 0–1. θ is the dominant
  **gradient** direction (across the edge); along the edge is θ+90°.

**`f_tf_axisflow`** — the sanctioned *view*: projects a reference angle onto the
edge line and outputs an ordinary signed vecfield, no `atan2`, no branch cut. This
is how tensor data reaches any vecfield-only consumer (`f_vf_advect`, `f_vf_warp`,
`f_caustic`, etc.) safely.

**The sign/branch-cut problem, in one paragraph:** angle-doubling (storing cos2θ,
sin2θ instead of cosθ, sinθ) fixes *storage* continuity — θ and θ+180° store
identically, no discontinuity in the texture itself. It does **not** fix decoding:
recovering θ = 0.5·atan2(...) confines it to (−π/2, π/2], so an axis sitting near
vertical flips between just-under and just-over that boundary — same storage,
opposite vector. **Never feed outlet 1's R/G directly into a sign-sensitive
consumer** (`f_vf_warp`, `f_caustic`, `f_vf_advect`, `f_vf_fluid`,
`f_vf_potential`, `f_vf_seeds`, `f_vf_chroma`/`f_vf_prism`) — route through
`f_tf_axisflow` first. Axis-blind uses of B/A (trace, coherence) are always fine.
Full module-by-module audit: `f_tensorfield.md` §"Consumer territory".

## 2. The decision, and the test

**2026-10-16, resolved:** focus on full-tensor consumers — reads both eigenvalues
(the ellipse: direction + anisotropy + confidence together), or operates
tensor-in/tensor-out. Views (axisflow, a later scalar unpacker) are support, not
the goal; they already cover rows 1–11 of Table 1 below with no new module needed.

**The tensor-native test:** could this idea be done correctly by collapsing the
tensor to a vecfield or scalar first? If yes, it's a view, not tensor-native — flag
it, don't count it toward justifying the type. Apply this test to every candidate
below, and to anything a subagent proposes beyond this list.

## 3. Prior art already assessed: `jit.fx.cf.kuwahara` — don't rebuild this part

Max ships a real anisotropic Kuwahara filter (Jitter Tools, `jit.gl.slab` chain,
GLSL, adapted from Kyprianidis et al. / Garrett Gunnell's MIT-licensed
implementation). Assessed in full 2026-10-16 (`f_tf_tensor_strategy.md`):

- **Algorithm:** 8 sectors, per-sector mean/variance, ellipse window from an
  *internal* structure tensor computed on RGB (not luma-only like ours), fixed
  Gaussian pre-blur, polynomial sector weighting.
- **Controls:** `sharpness`, `hardness`, `kernel_size` (2–20), `pre_blur` (0–10).
  One texture inlet. The tensor is neither input nor output — can't be touched.
- **Cost:** brute-force nested loop, ~2×kernel_size per side, 8 sectors/tap. Heavy
  at high `kernel_size`.
- **Verdict:** the *look* is fully covered — do not reimplement anisotropic
  Kuwahara painterly filtering. The only legitimate reason to build our own variant
  is a **tensor-in** version: strokes that follow an authored, mixed, or temporally
  smoothed orientation field instead of only the image's own edges. That's new
  territory, not a duplicate — but it's the single confirmed finding from a jit.fx
  audit so far, not the whole audit. **This is the template and the starting
  point for the jit.fx research task below — it is not yet done for the rest of
  the jit.fx.* namespace or other relevant jit.gl.* built-ins.**

## 4. Candidate module catalog

Twelve items below: eleven named candidate modules plus one open architecture
question (`f_tf_decode`) that affects all of them. All use the `f_tf_` prefix.
Full detail (performer knobs, exact chains, cost, failure modes) for each is in
`ideas/f_tf_expressive_consumers.md`; condensed here to what a triage pass needs.

### Operators (tensor in, tensor out)

**`f_tf_aniso_blur`** — structure-aligned smoothing: integrate the source along
the edge line, kernel ellipse from the eigenvalues, falls back to isotropic where
the field has no preferred direction. The strongest original argument for the
type existing at all (strategy doc, row 12). Bounded loop (~16–48 taps,
glow-like). Medium risk: curved contours need step-by-step continuity-based sign
choice to avoid a seam. Not yet detailed with knobs/failure-modes in the
expressive-consumers doc — do that as part of its spec, not before.

**`f_tf_smooth`** — temporal tensor smoother ("inertia"): feedback blend of the
raw tensor with its own previous frame, in tensor space (so opposite axes
reinforce rather than cancel, unlike a vecfield one-pole). One knob: `release`.
**Current single best next module** — see §5. Negligible cost, one feedback
texture.

**`f_tf_sharpen`** — exaggerates or relaxes anisotropy: scales the eigenvalue gap
while holding trace fixed. One knob: `exaggerate` (bipolar). Closed-form,
trivial cost. The single most leveraged performer gesture in the whole family —
every downstream renderer's character shifts with it.

**`f_tf_mix`** — tensor-space crossfade of two tensor sources (strategy doc row
15). Morphs through in-between angles correctly; blending vecfields gives mush.
Pairs naturally with `f_tf_authored` for image-vs-authored crossfades.

### Render / filter consumers

**`f_tf_glyph`** — ellipse/cross/tick glyph field, one per grid cell, aspect from
eigenvalue ratio, rotation from axis. Purest full-tensor consumer in the set
(losing λ2 collapses it to a line or dot). Closed-form, no loop, cheapest
full-tensor consumer possible. Doubles as the debug tool every other module
here will want. Current second-best next module.

**`f_tf_hatch`** — oriented hatching/engraving, density/spacing varying with
coherence, stroke curvature following the field. Real open cost question:
literal stroke-marching (bounded-loop-per-pixel, possibly multi-pass) vs. a
cheaper tileable procedural pattern (closer to `f_weave`'s distance-field-line
approach). Needs this decided before speccing (Open Question 1 below).

**`f_tf_glint`** — oriented specular glints whose *width*, not just direction,
comes from the eigenvalue ratio. **Flagged risk:** if the shipped version reads
only axis + a performer dial for lobe width, it's a view wearing a tensor
costume — the lobe width must come from per-pixel coherence to earn tensor-native
status.

**`f_tf_glow`** — tensor-inlet, sign-safe bidirectional variant of `f_vf_glow`:
accumulates along the ellipse major axis in two opposed segments, radius from
eigenvalue ratio, weight from coherence. **Flagged borderline/view-adjacent** —
reuses `f_vf_glow`'s existing free `in2` radius-mod inlet, same bounded 8–16-tap
loop it already runs.

### Tensor producers from non-image sources

**`f_tf_jacobian`** — symmetric strain tensor (+ separate scalar curl) from any
`f_vecfield`'s Jacobian. Bridges the vecfield family (`f_vf_fluid`, vortex
fields) to the tensor-consumer family. One central-difference pass.

**`f_tf_motion`** — the same strain-tensor math applied specifically to
`f_vf_optical_flow`'s output (confirmed: standard 0.5-centered vecfield on out0,
with its own confidence/aperture-ambiguity signal on out1 already available to
gate on). Performance hook: a performer's movement becomes the structure every
renderer above consumes.

**`f_tf_hessian`** — Hessian-of-a-scalar tensor: ridges/valleys rather than
edges. Visually distinct from the gradient structure tensor on the same source.
`f_vf_potential`'s accumulated scalar field is the natural first input.

**`f_tf_authored`** — hand/LFO-controlled analytic tensor field, no image input,
the tensor-field equivalent of `f_vf_vortex`. Cheapest way to get a genuinely
instrument-like tensor source, and the natural NumPy-mirror ground truth for
testing every consumer above before wiring a real image source. **Flagged** —
may be an instance of the paused `mod_depth_ui_density.md` question (new dials
on an already-dense panel) rather than a clean tensor-family addition.

### Open architecture question affecting all of the above

**`f_tf_decode`** (not yet a committed module name) — every full-tensor consumer
above needs λ1/λ2 and the axis, not just outlet 0's raw Jxx/Jxy/Jyy. Decode
centrally once (a new outlet on `f_tf_tensormap`, or a standalone module) so
every consumer downstream is a pure ellipse-consumer, or decode independently
per-consumer (simpler per-module, repeats the sqrt+atan2 work everywhere). This
decides the inlet shape for most of the catalog above — settle it before
speccing more than one or two of them (Open Question 7 below).

## 5. Ranked chains (current state, already revised once — see history note)

**Chain A — "Painterly instrument."** `tensormap → f_tf_smooth → f_tf_sharpen →
f_tf_aniso_blur`, with `f_tf_glyph` as a sidecar debug tap. Producer, stabilizer,
operator, renderer — the cleanest four-stage rig.

**Chain B — "Tensor engraving instrument."** `tensormap ↔(mix)↔ f_tf_authored`
through `f_tf_mix`, then `→ f_tf_smooth → f_tf_hatch` (or `f_tf_glyph` while
hatch's cost question is open). The authored side is what makes this a
performance rig, not a camera filter — morph live between "draw what the camera
sees" and "draw what I'm steering."

**Chain C — "Flow-structure instrument."** `f_vf_fluid → f_tf_jacobian →
f_tf_smooth → f_tf_aniso_blur`/`f_tf_glint`. No camera at all — pure generative
structure. Lowest priority (depends on an unspecced producer) but the most
novel-looking output of the three.

**Chain D — "Motion instrument"** (implicit in the catalog, not yet named as a
fourth chain in the source doc): `f_vf_optical_flow → f_tf_motion → f_tf_smooth
→ f_tf_hatch`. Camera-but-not-content-driven: structure from how the scene
moves, not what it looks like.

**Single best next module: `f_tf_smooth`.** Prerequisite every full-tensor
renderer silently needs for live video, nearly free to build, and its own
`release` control is itself a performable gesture. *(History note: an earlier
draft of the source doc picked `f_tf_glyph` first, on the narrower strength of
"validates the raw-tensor decode path." Revised 2026-10-17 after folding in a
second independent research pass that argued, convincingly, for build-order
over validation-order.)*

**Second pick: `f_tf_glyph`.** Still the right second build, now that it has
something stable to decode from.

**Flagged as views in disguise, don't count toward justifying the type:** the
orientation-selective mask idea (a scalar, belongs with a future `f_tf_unpack`
view-family); any `f_tf_glint` whose lobe shape is set by a dial, not per-pixel
coherence; any `f_tf_glow` whose radius is set by a dial, not per-pixel
coherence.

## 6. Open questions (consolidated, carried from the source doc)

1. **`f_tf_hatch`'s real cost shape** — stroke-marching vs. tileable-pattern
   approximation. Gut-check before any spec.
2. **Does `f_tf_smooth` get its own Phase-0 pass, or ride with `f_tf_glyph`?**
   Build it first, alone — nothing else validates against live flicker until it
   exists.
3. **`f_tf_jacobian`/`f_tf_hessian` as producers** — spike now, or defer until a
   consumer exists to justify them? Nothing downstream yet; Chain C depends on
   both.
4. **Does `f_tf_authored` belong in this phase**, or does it inherit the paused
   UI-density blocker?
5. **Should `f_tf_glyph` get a Phase-0 decision-gate task now**, right after
   `f_tf_smooth`?
6. **Tensor voting (Medioni) as a producer mode** — grows structure from sparse
   points via votes rather than a dense gradient. Unclear what the input would
   even be in this library's idiom. Noted, not assessed.
7. **Centralized eigenvalue decode vs. per-consumer in-pixel decode** — see §4's
   `f_tf_decode` entry. Affects inlet shape for most of the catalog; settle
   before speccing more than one or two consumers.

## 7. Related tensor ideas found elsewhere in the repo

These are docs about *other* modules where a tensor-shaped fix or idea got
flagged in passing — real material, but scoped to that module's own problem,
not folded in above. Read the source file directly if one becomes relevant to a
module being specced.

- **`ideas/f_anamorph_unnamed.md`** (§"Cross-reference: same line/axis problem as
  tensor fields") — flags that this module hits the identical sign/branch-cut
  problem `f_tensorfield.md`'s `f_tf_tensormap` producer solves, before blending.
- **`ideas/f_util_mod_texture.md`** — references hub Open Question 15: a
  structure tensor's anisotropy output as a per-pixel "how much does this even
  mean" signal for a generic mod-texture mechanism.
- **`ideas/f_vf_emulsion.md`** — "a second candidate fix, from the tensor-field
  exploration": a structure tensor computed from the source, diffusing hard
  along the filament and almost none across it, as an alternative to isotropic
  diffusion.
- **`ideas/f_weave_orientation_blend.md`** (§"Tensor-field framing") — the
  correct fix for `f_weave`'s known vector-add-renormalize blend bug is the same
  angle-doubled (2θ) encoding `f_tf_tensormap` already uses, for exactly the
  same reason; shares the identical Open Question 6 blocker.
- **`ideas/optics_map.md`** — photoelastic stress-fringe interference flagged as
  "genuinely new territory... no producer/consumer sketched" (still true);
  astigmatism noted as itself a tensor-valued aberration (direction-dependent
  defocus), cross-referenced to the raw-tensor outlet, not scoped anywhere yet.
- **`ideas/vector_field_math_concepts.md`** §9 — the actual origin of the
  glyph-field idea: tensor field as "the next rung up" from vector fields,
  visualized as a field of oriented ellipses or crosses (stress/strain glyph
  plots, structure-tensor visualization).
- **`ideas/wind_as_interface.md`** — a real but unprototyped performance idea:
  a camera pointed at fabric under tension computes a structure-tensor field
  from the feed, reduced to drive generative content aimed at a physical dome.
  Explicitly flagged in its own doc as "real but un-prototyped — no producer
  sketched."

## 8. What's NOT yet done — the jit.fx / built-in audit

Only `jit.fx.cf.kuwahara` has been checked against this catalog (§3). The rest
of the `jit.fx.*` namespace, and any other jit.gl.pix/jit.gl.slab built-ins that
might already give an anisotropic, orientation-aware, or tensor-adjacent look,
have **not** been surveyed. This is explicitly the first task for whoever picks
this brief up next — see the companion prompt for how to scope it.

## 9. Sources (prior art citations, from `f_tf_expressive_consumers.md`)

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

## 10. The template to mirror

`.specify/f_tf_tensormap/{spec,plan,tasks}.md` is a real, built, shipped example
of what a spec/plan/tasks folder looks like for this family: spec states what it
does and why, in architecture terms (not code); plan gives the stage-by-stage
signal flow and technical context; tasks gives the phased build order with
explicit Phase-0 blocking gates and a declared output layout. Mirror its
structure and level of detail, not its specific content.
