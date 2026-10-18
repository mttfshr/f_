# Spec: f_tf_aniso_blur

_Created: 2026-10-17_
_Status: Draft_

_Sixth module of the `f_tf_` tensor-field family, build order position 4
(`ideas/f_tf_triage.md`: smooth → glyph → sharpen → **aniso_blur** → hatch).
Promoted from `ideas/f_tf_build_brief.md` §4 (strategy row 12, "build as
proposed, the standout look") and `ideas/f_tf_expressive_consumers.md`
(prior-art section 1; flagged there as "not yet detailed with knobs/failure
modes in the expressive-consumers doc — do that as part of its spec, not
before"). This spec is that detailing. Open ground at the platform level
per `ideas/f_tf_jitfx_audit.md` §3: nothing shipped computes or consumes
eigenvalues, coherence, or a content-driven elliptical kernel
(`cf.directional` is a 3-tap line integral at a performer-set uniform
direction; `cf.tiltshift` is a parametric plane; `cf.bilateral` is
isotropic) — the tensor-native test passes unconditionally._

---

## What it does

**Structure-aligned smoothing, the coherence-enhancing smoother.** Blurs the
source texture along the local structure axis, with the kernel's shape — its
elongation *and* orientation — taken per-pixel from the structure tensor, and
falls back to plain isotropic blur where the field has no direction. The
one-sentence version: it smooths *along* the grain and not *across* it.

It is the real-time closed-form simplification of Weickert's coherence-
enhancing diffusion (CED): CED steers a nonlinear anisotropic diffusion PDE
by the structure tensor's eigensystem, reinforcing flow-like structure
(`ideas/f_tf_expressive_consumers.md` §Prior art, first bullet; Weickert's
CED/EED papers, cited there). CED is iterative and expensive; this module
does the same steering in a single pass with an elliptical kernel: sample
the source along the decoded edge direction, weight the samples by an ellipse
whose axes come from the eigenvalues (long axis along the edge, short axis
across it, ratio from the eigenvalue ratio). Where the tensor says
"isotropic" (low coherence / near-zero trace), the ellipse degenerates to a
circle and the filter is exactly an isotropic blur — no seam, no invented
direction. The same fallback logic Weickert encodes as the diffusion tensor's
eigenvalue ordering.

**Processor archetype, `driving_inlet`.** Two texture inlets: the tensor
drives the kernel, the second inlet drives the content. (In the canonical
chain the two carry different textures: tensormap derives its tensor from a
structure source, while the blur smooths a second image — e.g. a noisy video
through the kernel field of a clean structure source. Feeding the same
texture to both inlets, the default hand connection, is the standard
edge-preserving-denoise behavior.) The tensor inlet requires an
`f_tf_tensormap` outlet 0 (raw tensor, per `docs/f-reference/f_tensor_type.md`);
module decodes eigenvalues and axis per-pixel, in-shader, per the triage's
per-consumer decode decision — there is no `f_tf_decode` module and never
will be a shared one (`ideas/f_tf_triage.md`, review outcome 3; first idiom
recorded by `f_tf_glyph`).

**Single outlet 0.** The smoothed source texture, `@type float32`, unclamped
(range matches the source's; the module is a smoother, not a coder — hard
rule: stage outputs stay unbounded float32, only a final coder would clamp).
This is a content filter, not a tensor producer or bridge; nothing about the
outlet needs a new signal-type tag (see Open Questions 1).

### Why this earns the tensor inlet (the tensor-native test)

A direction-only version is a view: `f_tf_axisflow` already turns the packed
tensor into a vecfield, and `jit.fx.cf.directional` / `f_vf_streak` blur
along a direction. What makes this module tensor-native and worth a new
build per `ideas/f_tf_jitfx_audit.md` §3 ("Yes — the entire point of the
type, strategy row 12"):

- **Kernel *shape*, not just orientation, is per-pixel data.** The ellipse's
  axis ratio comes from the eigenvalue ratio (λ1, λ2), i.e. the coherence
  channel. A direction-driven module has a dial-round kernel no matter what
  the content is doing.
- **The isotropic fallback is content-driven.** Where trace and coherence say
  the field has no direction, the kernel goes circular *by measurement*, not
  by a performer threshold. The same pixels would be a hard seam for any
  fixed-elongation directional blur (exactly `f_tf_glint`'s flagged
  `aniso_response`-pushed-high failure, which this module's fallback
  discipline inherits and solves by construction).
- Both eigenvalues are consumed together, every pixel — not a projected
  vector, not a scalar matte.

---

## Field Architecture

Single content pass that reads two textures and one decode. GenExpr pseudocode
(architecture only; the real kernel is a plan.md decision between two
families, see Open Questions 6):

```
// decode raw tensor (outlet 0 encoding, f_tensor_type.md; cite, never re-derive)
s     = tensormap_strength (unknown to this module: see "The G-channel trap")
Jxx   = sample(t0, uv).r / s        // >= 0
Jxy   = (sample(t0, uv).g - 0.5) * 2 / s
Jyy   = sample(t0, uv).b / s        // >= 0

// closed-form 2x2 symmetric eigendecomposition (same forms as
// f_tf_tensormap stage C and jit.fx.cf.kuwahara's in-shader decode)
trace  = Jxx + Jyy
diff   = Jxx - Jyy
root   = sqrt(diff*diff + 4*Jxy*Jxy)
lambda1 = 0.5 * (trace + root)      // major-eigenvalue energy
lambda2 = 0.5 * (trace - root)      // minor-eigenvalue energy
coherence = root / max(trace, eps)  // in [0,1]

// across-edge axis theta, from the angle-doubled terms
// (equivalent to 0.5*atan2(2*Jxy, diff); no atan2 needed)
axis_x = diff
axis_y = 2*Jxy
// along-edge (major-axis) unit vector v = (axis_y, -axis_x) / root, guarded

// kernel shape
W = min(1, lambda1 * strength_scale)      // length gate, provisional; see knobs
w = W * max(floor, coherence)             // width gate: anisotropy gate * floor
// semi-length L and semi-width D drive the sample offsets:
L = length * W
D = L * clamp(1 - coherence, D_MIN, 1)    // transverse: full circle at coherence 0

// weighted accumulation over taps; exact kernel shape per plan.md ADR-*)
acc = 0
for tap in taps:                          // bounded, compile-time TAPS_MAX
    r = tap position (u along v, t across v)        // per kernel family
    weight = tapweight(r, t) * gate(W, w)           // radius-weight gating
    acc  += weight * sample(t1, clamped_texel_centre(uv + r*v + t*v_perp))
out = acc / totalweight
```

**Why half-angle math without `atan2`:** the raw tensor stores J entries, not
the packed doubled angle. `atan2` on *decoded sampled-texture input* is
verified safe on the GPU (`f_tensor_type.md` consumer rule 4,
`tests/records/spike_atan2_safety.py`), but the module does not need it at all: the
across-edge axis is `(diff, 2·Jxy)` normalized by `root`, and the along-edge
axis is its perpendicular — the same closed-form the tensormap's own stage C
uses to build `(cos 2θ, sin 2θ)`. The line field is unoriented (θ and θ+π are
the same structure), so the along-edge axis sign is irrelevant to a
*bilateral* (up-and-down-both) kernel: every sample offset appears with both
signs.

**The G-channel trap.** The raw tensor's G is `Jxy·strength·0.5 + 0.5`
(signed, 0.5 = zero) and the decode must divide by the `strength` tensormap
was dialed to. That value is not carried in the texture (its A is a constant
1.0; A carries coherence only on outlet 1). `f_tensor_type.md` gives the
lossless decode as `Jxy = (G − 0.5)·2/strength` and states the decode needs
`strength` — but the wire has no strength channel. Options recorded in
Open Questions 3; the spec's position: the module needs a matching `strength`
param unless tensormap v2 adds gain to an outlet, and the fallback behavior
when the two disagree must be graceful (the eigenvalue *ratios* — coherence,
axis shape — are strength-invariant; only the absolute tap-radius scale
changes).

**Unconnected-tensor guard.** An unconnected wire carries `vs_black` — an
all-zero texture `(0,0,0,0)`, which under the G-channel 0.5 offset decodes to
Jxx·s = 0, **Jxy·s = −1**, Jyy·s = 0: not the zero tensor and not positive
semi-definite (the eigen math there gives root = 2, λ2 = −1 — a physically
impossible tensor). The SPD/`root` guard catches this and routes the pixel to
the isotropic fallback. Note the distinction from the family's *neutral*: the
raw-tensor neutral (0, 0.5, 0, 1) is what tensormap outputs on bypass and
decodes cleanly to the zero tensor; but what arrives on an unconnected wire
is zeros, decoding garbage — the same trap `f_tensor_type.md` consumer rule 5
documents for outlet 1's packed encoding (there it reads as c2 = s2 = −1;
here it reads as a non-SPD tensor). One family-level distinction (worked out
jointly with `f_tf_glyph`'s triad, 2026-10-17): the all-zeros decode has
trace 0 but λ1 = 1, axis atan2(−2, 0) — it *looks like structure* to any gate
on eigenvalue energy while failing the SPD test. A trace-gated consumer
(glyph's no-mark gate) is incidentally safe; an **energy-gated** consumer —
this module's W = min(1, λ1·strength_scale) is exactly that — needs the SPD
check as its primary unconnected-input defense. A mis-wired packed (outlet 1)
texture would read |Jxy·s| = 1 against R = B = 0 and fail the same test.
Specified behavior, not implementation detail: a non-SPD or black tensor
pixel behaves exactly as an isotropic
pixel. See Open Questions 4.

**Clamping discipline (hard rules, already decided family-wide).** Weights
and gate scalars are floats and are unclamped *between stages* of the math —
the single pass is one codebox, and the only clamps inside it are:
1. the tensor decode's SPD/RNG guard (above) — not a range clamp;
2. **sample coordinates clamped to texel centres in-shader**, because the
   bench GPU wraps out-of-range reads (`f_tf_tensormap.md` Notes; tensormap
   ADR-5 outcome);
3. sample *weights* bounded by construction (positive, sum-normalized).
No clamp on the output values themselves.

---

## Inlets

| Inlet | Type | Label | Description |
|---|---|---|---|
| 0 | texture (required) | tensor | `f_tf_tensormap` outlet 0 (raw tensor, `@type float32`). Decoded per-pixel. |
| 1 | texture (required) + control | source | The texture to smooth. Control messages route to params. |

vs_* fallbacks: inlet 0 unconnected → vs_black decodes to a non-SPD tensor
(see the guard section above) → the isotropic-fallback path everywhere — the
module becomes a plain `length`-radius isotropic blur of inlet 1, which is
the honest degenerate behavior, not a crash.
Inlet 1 unconnected → output is black. (Both behaviors stated as acceptance
criteria below.)

No mod inlets in v1 (same call as `f_vf_fieldmap`/`f_tf_tensormap`; and per
`ideas/f_tf_build_brief.md`: kernel-gain modulation is what the *knobs* are
for — see Open Questions 8).

---

## Outlets

| Outlet | Content | Channels |
|---|---|---|
| 0 | Smoothed source, float32 | RGBA, passthrough of inlet 1's channel count |

Single outlet. `@type float32`. Output is unbounded: wherever the kernel is
weight-normalized (all the kernel families considered), the output lies
within the input's convex hull — in practice 0..1 for ordinary sources, but
the module asserts no clamp (float32 passthrough of a weighted mean; the
convex-hull property is the *number*, not a clamped ceiling). This matches
the family hard rule: stage outputs stay unbounded; clamping/encoding is the
next consumer's business, not a smoother's.

This outlet is an ordinary color texture — not an `f_vecfield`, not a tensor
outlet. No signal-type novelty is needed for it.

---

## Parameters

Provisional set for spec purposes; the ranges and defaults are tier-3
verifications, not guesses to be locked here. **Phase 0 / tier 3 confirm or
replace these** (see Open Questions 5).

| Param | UI | Range (provisional) | Default (provisional) | Notes |
|---|---|---|---|---|
| `strength_scale` | live.dial | 0-2 | 0.5 | Gain mapping absolute tensor energy (λ1) to the length gate W = min(1, λ1·strength_scale). **Calibration depends on tensormap `strength`** (the G-channel trap): both are set in the same tier-3 session on real content, and the default is only meaningful with tensormap's default 100. Provisional 0.5 assumes λ1 ~ 2 typical at tensormap strength 100 on noise (tensormap calibration table: trace ~ 1 at p95, so λ1 ~ trace/2 ≈ 0.5-2). [INFERENCE on the λ1 typical value; to be measured in tier 1 mirror on the same synthetic inputs the tensormap mirror used.] |
| `length` | live.dial | 0-16 | 4 | Kernel semi-length in pixels along the edge (the along-edge sampling extent). Tap spacing = 1 pixel; cost scales with `TAPS_MAX`, not with `length` (same fact as tensormap's radius, `f_tf_tensormap.md` Notes). Range top = TAPS_MAX/2 for a symmetric bilateral kernel. |
| `width_gate` | live.dial | 0-1 | 0.5 | "Anisotropy gate": how much the *coherence* (not the eigenvalue ratio directly) must be present before the kernel elongates — the second half of w = W·max(floor, coherence·width_gate). At 0, the kernel is always circular (off-switch for anisotropy); at 1, full coherence response. |
| `floor` | live.dial | 0-1 | 0.25 | Width floor: w = W·max(floor, coherence·width_gate) — the kernel is never *more* isotropic than this fraction of its length across, even at coherence 0 where trace says there is no structure. Prevents the "no blur at all in flat regions" seam. At 1, the blur is fully isotropic everywhere. |
| `bypass` | jsui (bypass_toggle.js) | 0/1 | 0 | Passthrough of inlet 1 (per-family bypass contract: outlet == inlet-1's texture, not a neutral — the module has no encoding of its own to neutralize). |

**Deliberately not knobs in v1:** kernel step spacing (fixed 1 pixel),
transverse tap arrangement (kernel-family decision, plan.md ADR), and
*curved* integration (no continuation along the field — V1 constraint).

**V1 constraint — the kernel is a straight-axis local ellipse.** Samples are
taken along the local axis *through the center pixel*, with no step-by-step
curvature following. On curved contours (the majority of real content), the
kernel is tangent to the field at the center pixel only, so smoothing
slightly *cuts* curved corners rather than flowing around them — the honest
single-pass limit, exactly what Weickert's iterative version does better and
why his is 30 iterations. The brief already names the risk
(`ideas/f_tf_build_brief.md` §4: "Medium risk: curved contours need
step-by-step continuity-based sign choice to avoid a seam"). Specifying the
straight-axis constraint avoids that entire problem class in v1; curved
integration is a documented open question (6), not deferred silently.

---

## Signal Flow

```
in0 (tensor, f_tf_tensormap out0) ──┐
                                    ├─> tensormap_pix_consumer codebox (decode + kernel + accumulate)
in1 (source texture + control) ─────┘
```

```
in0 jit_gl_texture branch -> vs_inState -> aniso_pix in0
unmatched -> route <params> -> live.dials -> prepend param <name> -> aniso_pix in0
in1 jit_gl_texture branch -> vs_inState -> aniso_pix in1

aniso_pix out0 -> outlet 0 (smoothed source, @type float32)
```

Same routing skeleton as `f_vf_fieldmap`/`f_tf_tensormap`. Unlike the tensormap
(this is a **one-stage module** — one codebox, no pix_chain), unless the
kernel-family decision in plan.md forces a two-stage split (see Open
Questions 6); the decode+kernel is a single pass over two textures, and the
statement budget well under ~450 lines (`skills/jit-gen-codebox`) is a plan
constraint, not a spec one.

---

## Acceptance Criteria

Numbers first, per the constitution's Verification Tiers. Tier 1 (NumPy
mirror) applies: the line-integral kernel and its isotropic fallback have
independent ground truth (analytic constant/ramp inputs, convex-hull and
energy-preservation arguments, and an exact-match check against a brute-force
reference weighted-sum implementation in NumPy). Tier 2 (bench) applies: the
real codebox(es) must compile, cost at HD/4K is an open question, and
texture-coordinate clamping must be verified against the wrap behavior. Tier
3 (scratch patch) applies: the `strength_scale`/`length`/`width_gate`/`floor`
defaults are live-content judgements. The tier gate is recorded as Phase 0's
first task in tasks.md.

- **Flat source, flat tensor (both black):** with the zero-texture tensor
  (`vs_black`, decodes non-SPD → guard → isotropic fallback) the output is
  the isotropic reference blur of the source — no invented structure, no NaN,
  no sign-dependent artifact from the phantom Jxy = −1. With the raw-tensor
  *neutral* (0, 0.5, 0, 1) — tensormap's bypass output — the decode is the
  exact zero tensor: trace 0, isotropic fallback, same reference result.
- **Isotropic-fallback exactness:** where the tensor has trace 0 (or the
  coherence gate closes), the output at every pixel equals a plain isotropic
  box/Gaussian blur of `length` radius — *numerically identical* to the
  isotropic reference implementation in the tier-1 mirror, channel by channel
  (the fallback is not an approximation of isotropic blur; it is isotropic
  blur). — VERIFIED at 4.2e-7 in every guard case and at both knob closures
  (width_gate 0, floor 1); ONE REFUSAL recorded: the packed-NEUTRAL mis-wire
  (0.5, 0.5, 0, 0) is NOT a fallback case through the raw decode (it is a
  weak isotropic tensor: near-no-op under the gate model) — see the Non-SPD
  guard criterion's build-time amendment.
- **Coherent-edge behavior:** on an analytic ramp edge with a synthetic
  tensor whose axis is the edge direction and coherence 1: output is *unchanged*
  across the edge (no blur applied across it, weight concentrated along it)
  and heavily smoothed along it. Quantified in tier 1: the across-edge
  gradient at the edge center is preserved to within one tap's weight of the
  original (the kernel has near-zero transverse extent at coherence 1 and
  `floor` -> 0).
- **Axis rotation:** rotating the synthetic tensor axis by an angle φ rotates
  the blur direction by φ; output matches the brute-force NumPy
  weighted-sum reference at φ = 0°, 45°, 90°, 135°. No `atan2` anywhere in
  the module, so no branch-cut failure mode exists; the doubled-angle
  symmetry holds by construction and is checked at φ and φ+π.
- **Convex hull:** output pixel values always lie within min/max of the
  sampled neighborhood's values (weights are positive and sum-normalized) —
  no overshoot, no invented values. This is the float32-unclamped claim made
  checkable.
- **Degenerate eigenvalues (λ1 = λ2, i.e. a perfect circle field):** kernel
  is exactly circular; output matches the isotropic reference. No
  axis-dependent behavior at the eigenvalue-degeneracy point.
- **Non-SPD tensor guard:** a tensor texture pixel that is not positive
  semi-definite (all-zeros unconnected input, or a mis-wired packed texture)
  produces the isotropic fallback at that pixel. v1 reads the tensor only at
  the center pixel — neighbors' tensors do not enter the kernel *shape*;
  only the source texture is sampled along the axis. (If a later kernel
  family reads tensors at tap positions this changes; out of v1 scope.) The
  guard is therefore a purely local check, and the phantom-λ1=1 all-zeros
  case is constructed explicitly in tier 1. — BUILD-TIME AMENDMENT
  (tier-1 work, 2026-10-17): (a) the guard has TWO clauses in the shipped
  form — λ2 < −1e-4 (SPD) OR trace < eps_trace: vs_black is caught by both
  (λ2 = −1/s AND trace 0), so it does not discriminate the two; the SPD
  clause's own case is a LARGE-trace non-SPD feed (Jxx=1, Jxy=1, Jyy=0.1:
  trace 1.1, λ2 −0.49), which only the SPD clause catches, and that is the
  case the mutation check exercises; (b) the "mis-wired packed texture"
  clause is refined by measurement: the packed NEUTRAL (0.5, 0.5, 0, 0)
  through the raw decode is a WEAK isotropic tensor (Jxx = 0.5/s), so it
  does NOT hit the fallback — it takes the energy-gated near-no-op path
  (an honest reading of the gate model); only a strong packed feed would
  read as a plausible-but-wrong kernel field (documented, self-diagnosing).
  Also: the across-edge axis in the shipped codebox is the HALF-angle axis
  (cos θ = √((1+diff/root)/2), sin θ = sign(2·Jxy)·√((1−diff/root)/2)),
  not the doubled-angle vector used as a direction — the spec's
  Field-Architecture pencil sketch above conflated the two; the idiom's
  doubled-angle form is what the code halves, atan2-free.
- **Coherence/width_gate extremes:** `width_gate` = 0 gives the isotropic
  reference at every tensor; `floor` = 1 gives the isotropic reference at
  every tensor; both are exact identity-with-the-isotropic-reference claims,
  tested in tier 1 against the brute-force reference.
- **`length` = 0:** output equals source (identity) — the kernel has no
  extent, weights collapse to the center tap.
- **Unconnected inlet 0 (tensor):** vs_black decodes non-SPD → isotropic
  fallback everywhere (the guard path), output = isotropic blur of source, no
  crash. The SPD guard must demonstrably fire here (tier 1 constructs this
  input explicitly).
- **Unconnected inlet 1 (source):** black output, no crash.
- **Bypass:** outlet equals inlet 1 exactly, bitwise-passthrough semantics.
- **Loads in Vsynth** and outlet 0 renders in `vs_render` (the shipped-
  bpatcher contract tests).
- **Judgement tier (scratch patch):** the anisotropic look separates from the
  isotropic look on real content — ridges/edges stay crisp while flat areas
  smooth; `floor` prevents a visible boundary between the two regimes;
  provisional defaults read sensibly on bfg Perlin/Voronoi/fbm and on a real
  video source. This is the confirmation the provisional parameter table is
  waiting on.

## Out of Scope (v1)

- **Curved-axis integration** — the step-sign continuity choice that follows
  the field around a bend is the brief's "medium risk" and is a documented
  open question (6), not v1. The straight-axis kernel is the entire v1.
- **Kernel-family choice.** Fixed-tap line integration vs ellipse-grid kernel
  is plan.md's ADR-2 decision gate, present as a decision with cost reasoning
  on both sides; this spec does not pick.
- **The tensor producer, its packing, or tensormap changes.** The module
  consumes outlet 0 as-is. Any tensormap v2 (gain-on-outlet, an SPD/λ1λ2
  third outlet) is tensormap's roadmap, not this spec's.
- **The `f_tf_decode` module** — retired name; per-consumer decode per
  `ideas/f_tf_triage.md` review outcome 3. Decode idiom lives in this
  module's codebox, cross-checked against the first recorded idiom in
  `f_tf_glyph`'s plan.
- **Sharpening/edge-enhancing (EED-style) modes.** This module only smooths.
  An "enhance across" mode is a sign flip of some weights away, but is
  `f_tf_sharpen`'s territory (eigen-gap operator) and out of this spec.
- **Mod inlets** on any param (same call as `f_vf_fieldmap`/tensormap;
  blocked behind `mod_depth_ui_density.md`).
- **Temporal anything.** Stateless per-frame; `f_tf_smooth` upstream owns the
  flicker problem (chains: `f_tf_expressive_consumers.md`, Chain A).
- **Self-generating mode.** Processor, `driving_inlet`; requires both inlets.

---

## Open Questions

1. **Signal-type tag. Outlet 0 is an ordinary color texture** — no tag
   needed, unlike tensormap's outlets (spec OQ5 there). Nothing to decide
   beyond confirming build_patcher.py's default coloring applies. [INFERENCE:
   default; checked at Phase 3.]
2. **Module name / prefix / object name.** Following the family convention:
   `f_tf_aniso_blur`, prefix `aniso_blur`, object `aniso_blur_pix`. The
   triage confirmed the name (`ideas/f_tf_triage.md`, build order item 4);
   constitution naming-table entry for `f_tf_` already exists (T042,
   tensormap tasks.md). No open question; recorded here as done.
3. **The strength-coupling problem (the G-channel trap, made explicit).**
   The raw tensor's magnitude depends on tensormap's `strength` dial; the
   kernel gate W = min(1, λ1·strength_scale) therefore couples to a dial on
   *another module*. Options: (a) this module's `strength_scale` is
   documented as "matching tensormap's strength" and calibrated together in
   tier 3 — zero code, a docs burden; (b) tensormap v2 encodes λ1 into a
   free channel — blocked on a tensormap revision; (c) this module
   self-normalizes (e.g. W from λ1/(λ1+λ2) or a local p-normalization) —
   changes the semantics from "energy-gated" to "ratio-gated" and loses the
   "no blur where there is no structure" property that trace provides.
   Leaning (a) for v1 [INFERENCE; needs Matt's call at the Phase 0 gate],
   with the tier-1 mirror parameterized on both strengths so the coupling is
   at least measured, not guessed.
4. **Non-SPD / black tensor guard.** The tensormap itself always produces SPD
   output, and its bypass neutral decodes cleanly to the zero tensor — so the
   SPD guard (root² ≥ diff² + 4·Jxy², or equivalently λ2 ≥ 0 after the
   closed-form solve) fires in v1 only on non-tensormap feeds: chiefly the
   unconnected inlet, where vs_black's all-zeros decode via the G-channel
   offset to Jxy·s = −1 (non-SPD; f_tensor_type.md documents the analogous
   trap for outlet 1's packed encoding, consumer rule 5). Two candidate
   behaviors: reject-to-isotropic (the pixel acts as if the field had no
   direction — proposed for v1, [INFERENCE]) or clamping the tensor into the
   SPD envelope (root² ≥ diff² + 4·Jxy²), which invents a valid tensor from a
   garbage one and keeps an axis where none exists. The reject is cheaper and
   honest; revisit only if a real feed turns out to need the clamp.
5. **Provisional parameter ranges and defaults.** All four knobs'
   (strength_scale, length, width_gate, floor) ranges/defaults are tier-3
   confirmations; the table's provisional values come from: tensormap's
   calibration table for the energy scale, the ~450-line statement budget
   binding TAPS_MAX ≤ ~24 (length ≤ 12 bilateral), and the `f_vf_glow`/cf.directional
   precedents for length defaults. To be replaced with measured values in
   the phase-2 scratch patch.
6. **Curved-axis integration (the brief's "medium risk").** Following the
   field around a bend requires, at each step along the axis, choosing the
   next step's sign/branch so the path is continuous — no straight-line
   shortcut. This is a design problem (step-sign continuity choice; possibly
   a 2-pass approach where a first pass traces field lines into a UV texture)
   that changes the module's shape from one codebox to a chain. Documented
   open question, not v1. Whatever the V2 outcome, the straight-axis v1
   kernel families below are exactly the building blocks of the curved one.
7. **Transverse-width from eigenvalue ratio vs from coherence.** The spec
   uses coherence (root/trace, the A channel of tensormap's outlet 1, in
   [0,1]) as the elongation driver since the raw tensor gives λ1, λ2 anyway
   and root/trace is the same information normalized. Open question is
   whether raw λ2/λ1 (bounded [0,1] but differently scaled) reads better as
   the width gate on real content. Tier-3 question; cost-free to switch.
8. **Kernel-gain modulation via mod inlets.** Explicitly out of v1 (see
   Out of Scope), but the long-term shape — `length`/`coherence-gate`
   accessible as per-pixel mod inputs the way `f_vf_glow` uses its free
   inlets — is the shape chain C (`f_vf_fluid → f_tf_jacobian → f_tf_smooth
   → f_tf_aniso_blur`) would eventually want. Noted, not specced.
9. **Kernel-shape decision (plan.md's job).** The fixed-tap line integration
   vs ellipse-grid families differ in cost, artifact character, and the
   shape of the isotropic fallback; this spec stays silent on which is
   chosen (Out of Scope item 2) but constrains both: tap weights positive,
   sum-normalized, bounded-loop compile-time TAPS_MAX, transverse extent
   from the coherence-derived width gate, coordinates clamped to texel
   centres in-shader.

---

## Clarifications

### Carried from the triage/brief (decided before this spec)

- Q: Build at all? → A: Yes, confirmed twice — `ideas/f_tf_build_brief.md`
  ("the strongest original argument for the type existing at all", strategy
  row 12) and `ideas/f_tf_triage.md` (build order item 4; "the standout
  look"); `ideas/f_tf_jitfx_audit.md` §3 confirms nothing ships the look.
- Q: Is curved-integration needed for the look? → A: No for v1. The brief's
  seam risk is real but belongs to curved integration only; straight-axis
  kernels avoid the step-sign problem entirely.
- Q: Where does the decode live? → A: In this module's codebox, per the
  triage's per-consumer decision (review outcome 3). `f_tf_decode` is a
  retired name.
- Q: Tensor inlet encoding? → A: `f_tf_tensormap` outlet 0 (raw tensor), per
  `docs/f-reference/f_tensor_type.md`. Not outlet 1 (packed is for axis-blind
  scalars; this module needs the eigenstructure, and the raw form avoids one
  atan2).
- Q: What about the "no blur where there is no structure" regime — is absence
  of blur a look? → A: Yes, and it is controlled by `floor`: floor = 0 gives
  full no-blur in flat regions (the "painterly, keep the noise there" look);
  floor > 0 keeps some isotropic smoothing everywhere. Both are legitimate;
  tier 3 decides the default. [INFERENCE on which default Matt will want;
  provisional 0.25 leans toward keeping flat regions from going fully dead.]
- Q: Is the fallback isotropic blur or *no* blur? → A: **Isotropic blur** (the
  kernel degenerates to a circle of the same length budget), not "skip the
  filter". This is the Weickert behavior (diffusion becomes isotropic where
  the structure lacks direction) and the exact seam-avoidance the brief asked
  for. `length` = 0 is the "no blur at all" path, a knob, not a fallback mode.

### Session 2026-10-17 (this spec)

- Q: Two inlets or one? → A: Two (tensor + source). The one-inlet version
  (same texture drives both) is trivially reachable by hand-patching, but the
  expressive chain (Chain A) wants the kernel field decoupled from the
  smoothed content. The tensormap needs no change for this.
- Q: Does the module need the tensor's *packed* outlet 1 instead? → A: No.
  The packed outlet stores the angle-doubled axis, which needs an atan2
  half-angle to recover the axis and stores no eigenvalue *ratio* information
  beyond the coherence A channel; the raw outlet carries Jxx/Jxy/Jyy
  losslessly and the eigen math is three lines of closed form. Consumer rule
  4 of `f_tensor_type.md` permits either.
- Q: Straight axis or curved? → A: Straight axis in v1 (the V1 constraint
  section). Curved is open question 6, a design-level decision with its own
  spike, not a knob.
- Q: What bounds the loop? → A: A compile-time `TAPS_MAX` (provisional ~16),
  per-tap weights gated by the live knobs (the tensormap ADR-3 idiom: cost
  scales with the compile-time maximum, not the dial).
- Q: `strength_scale` naming (was provisionally `anisotropy_gate` in
  discussion)? → A: The knob set fixed for spec purposes is
  `strength_scale`, `length`, `width_gate`, `floor` — four knobs, one per
  behavior: energy→length mapping, extent, coherence-response shape, and
  the isotropic floor. Naming follows the "one knob, one behavior" rule and
  avoids the overloaded "anisotropy" word for a knob that is actually a
  coherence-response curve.