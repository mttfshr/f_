# f_tf_backlog — tensor-family candidates that are not built

_Consolidated 2026-10-17 from the triage, the build brief and the expressive-consumers research
(plus one idea from a raw subagent draft). Working doc: pick the next module from here, and
remove an entry when it ships or is killed. Live status and open questions:
`ideas/f_tensorfield.md`. Evidence and prior art: `ideas/f_tf_research.md`._

**Nothing in the confirmed build order remains.** Smooth, glyph, sharpen, aniso_blur and hatch
are built to tier 2 (hub status table). The frontier is the tier-3 live gates on those five,
not a next module. Everything below is deliberately deferred, with its entry condition written
down so the deferral does not rot.

Verdict vocabulary (from the triage): **defer** / **merged** / **view** / **idea**. Nothing was
killed: the platform audit found no shipped duplicate of anything in the catalog.

---

## Operators

### `f_tf_mix` — defer until chain B is being assembled

Tensor-space crossfade of two tensor sources. Morphs through intermediate angles correctly;
blending vecfields gives mush. Also lets a smoothed or sharpened authored field be mixed into a
noisy live one without flicker.

- **Weakest "needs the type" case.** Component-wise crossfade of two float32 textures is
  mathematically stock xfade. A dedicated module is justified by guarantees, not math: float32
  `@type`, family labelling, and neutral handling.
- **Neutral rule for the spec:** an unconnected side must contribute `(0, 0.5, 0, 1)`, never
  all-zeros (zeros decode to a non-SPD phantom, `f_tf_research.md` section 6).
- **Entry condition:** spec it when chain B is actually being assembled, after two real consumers
  exist (now true) and the `f_tf_authored` decision is made. Building it early as "the
  operator-proving module" was considered and declined.

## Render / filter consumers

### `f_tf_glint` — defer, with the view-in-disguise flag as a gate

Oriented specular glints whose *width*, not just direction, comes from the eigenvalue ratio
(brushed-metal shading).

- **Tensor-native only if** lobe width comes from per-pixel coherence. A dial-set width is a
  view wearing a tensor costume, and `f_lens` halation/ghosts already offer that look
  parameter-side.
- **Nothing requires it:** chain C's glint slot is satisfied by `aniso_blur`'s elliptical
  accumulation until a per-pixel-coherence lobe design proves itself.
- **Entry condition:** a live rig actually wants it. Build only with per-pixel coherence lobe
  width; v1 as a single-pass closed-form analytic lobe (cheaper than a directional loop).
- Knobs sketched: `threshold` (luma gate), `gain`, `aniso_response`. Failure modes: needs
  `f_tf_smooth` on live input; a hard threshold shows seams where the lobe snaps round to thin.

### `f_tf_glow` — merged into the parked `f_vf_glow` anisotropy inlet

Tensor-inlet, sign-safe bidirectional variant of `f_vf_glow`. Shipped glow is isotropic
(`co.glow`) or 3D-only (`jit.gl.pass`), so the local `f_vf_glow` / `f_vf_streak` stack is the only
field-following glow, and that stack already runs the bounded bidirectional loop.

- **Decision (Matt, 2026-10-17):** merge with hub Q12 rather than build a module. Q12's design
  (an `anisotropy` mod inlet, `state_param` connection detection, a confidence gate that pulls
  `direction` 1/2 toward the bidirectional floor) delivers most of the gesture at near-zero
  cost. Tasks T039-T043 are in `.specify/f_vf_glow/tasks.md`, all unticked.
- **Reopen condition:** live A/B against the gate-only version shows the full tensor-inlet shape
  (radius proportional to eigenvalue, weight proportional to coherence, both) is materially
  different.
- The strategy note earlier proposed one live test first (tensormap -> axisflow -> glow in2)
  before building Q12; that test is not recorded as done.

## Producers from non-image sources

These make the renderers playable without a camera, arguably more valuable for a live
instrument than another renderer. All are spike-on-demand: no consumer exists yet to validate
their output against, so each waits for the chain that needs it.

### `f_tf_jacobian` — spike-only until chain C is assembled

Symmetric strain tensor (plus a separate scalar curl for the antisymmetric part) from any
`f_vecfield`'s Jacobian. Bridges `f_vf_fluid`, `f_vf_vortex(_multi)` to the tensor consumers:
`aniso_blur` downstream would smear along flow-shear lines rather than image edges, a look
nothing in the library produces. One central-difference pass, `f_vf_fieldmap`'s cost class.
Keep the curl-scalar split in the spike scope so the decision has full information.

### `f_tf_motion` — joins the jacobian spike

The same strain math applied to `f_vf_optical_flow`. Its contract is confirmed (not assumed):
out0 is a standard 0.5-centred vecfield, so no range adapter is needed; out1 carries a raw
confidence determinant and a double-angle ambiguous axis (the aperture-problem signal), so gate
on that instead of inventing confidence. Performance hook: a performer's movement axis becomes
the structure every renderer draws. Inherits optical flow's honest limits (confidence is
per-scene empirical; borders need its masking margin); low-confidence input means
low-confidence structure and must carry that through.

### `f_tf_hessian` — spike-on-demand, anchor chain C

Hessian of a scalar for ridges and valleys rather than edges. Natural first input:
`f_vf_potential`'s accumulated scalar (smooth, real ridges). Second-derivative estimate, the same
complexity as tensormap's Sobel stage. `cf.laplace` is literally the collapsed trace-of-Hessian
view, a useful contrast for its spec's tensor-native paragraph.

### `f_tf_authored` — defer behind the UI-density gate

A hand- or LFO-controlled analytic tensor with no image input (angle, aspect, optional falloff):
the tensor analogue of `f_vf_vortex`. Cheapest instrument-like source, the natural "known-good"
input for `f_tf_mix`, and a trivial NumPy ground truth for testing consumers.

- **Gate:** it may be an instance of the paused `mod_depth_ui_density.md` question (new dials on
  an already-dense panel). When chain B is assembled, ask whether this module unblocks that
  question or waits for it.
- **Zero-code interim, non-blocking:** an LFO-swept analytic tensor patched from whatever cheap
  source can be tried in a scratch patch during any consumer's tier-3 phase.

### `f_tf_metric` — idea (from the subagent draft), not triaged

Producer of the metric tensor (Tissot indicatrix) of a UV warp, then rendered by the **built**
`f_tf_glyph`. For each warper the Jacobian is closed-form, so the producer is per-warp rather
than generic: `f_mobius` (conformal, always circles, already spiked), `f_droste` (real ellipses,
radial and angular scales differ), `f_stereo` (never run; orthographic to stereographic sweeps
ellipse to circle), `f_lens` (predicted always circles). Also feeds adaptive anti-aliasing for
`f_masonry` / `f_weave` (`vector_field_math_concepts.md` #11).

- **Collapse test:** passes as a producer (a scalar "stretch" hides direction-dependent stretch);
  the glyph half is a view when fed other content.
- **Caveat:** glyph must degrade to circles on near-conformal tensors, not zero-size ellipses.
- **Cheapest entry:** the `f_stereo` Tissot spike reuses existing diagnostics and needs no new
  module.

## Views and plumbing (support, not the goal)

- **`f_tf_unpack`** — coherence, trace and an orientation-selective mask
  (`coherence * cos^2(theta - phi)`) as plain scalar textures, the analogue of `f_vf_split`.
  Unlocks uses 4-7 and 11 in `f_tf_research.md`. Build only when a consumer needs it; Q12
  sidesteps it by reading `.w` through a `state_param` inlet. Unverified assumption behind its
  value: existing mod inlets read `.x`.
- **`f_tf_color`** — orientation to hue, coherence to saturation, trace to value. Tiny debug and
  look tool; `f_tf_glyph`'s debug tints overlap it.
- **Orientation-selective effects as an instrument** is a view in disguise (a scalar mask); it
  belongs here, not in the tensor-native list.

## Larger or speculative

- **Tensor voting (Medioni) as a producer mode:** grows structure from sparse points by votes.
  Unclear what the input would be in this library's idiom (sparse marks from `f_vf_seeds`? a
  point generator?). Noted, not assessed.
- **`f_tf_kuwahara` (tensor-in variant):** heavy; only if strokes must follow an edited or
  authored orientation field. `jit.fx.cf.kuwahara` already gives the image-driven look.
- **Photoelastic stress-fringe optics:** new territory for `f_lens` / `f_caustic` / `f_vf_prism`;
  no producer or consumer wiring has ever been sketched.
- **Confidence-scaled marks, full version:** mark *shape* (not just weight) responding to
  anisotropy in `f_vf_seeds`. A further step beyond the mod-tex wiring; see hub Q13-Q15 for the
  stipple, grain and confidence-gate threads.

## v2 ideas for built modules

- **`f_tf_tensormap`:** a gain channel carried on the wire (the strength-pairing problem, hub Q16);
  an RGB-aware tensor that catches chroma edges (kuwahara does this); Gaussian pre-blur vs box
  radius; Scharr instead of Sobel if fine grain demands it; a decoded-convenience outlet if
  per-consumer decode proves noisy in tier 3.
- **`f_tf_axisflow`:** per-pixel reference-direction inlet, `normalize`, trace gating.
- **`f_tf_smooth`:** attack shaping (release-only today by design), a reset bang or
  disagreement detector for hard scene cuts.
- **`f_tf_hatch`:** tone gating (left out of v1), cross-hatch layering, curved-stroke marching
  if the hairpin hazard turns out to matter.
- **`f_tf_glyph`:** variant menu (ellipse / cross / tick) and debug tints, deferred by ADR-8.
- **`f_tf_aniso_blur`:** curved-axis integration; kernel family (b) if the cost experiment says
  family (a) is not enough.

---

## Chains: what each is missing

| Chain | Path | Missing |
|---|---|---|
| A, painterly instrument | `tensormap -> smooth -> sharpen -> aniso_blur`, `glyph` as a sidecar tap | Nothing: all stages exist at tier 2. No whole-chain live check is recorded |
| B, tensor engraving | `tensormap <-mix-> authored`, then `smooth -> hatch` | `f_tf_mix`, `f_tf_authored` (hatch and glyph exist; glyph is the lighter stand-in) |
| C, flow structure | `f_vf_fluid -> jacobian -> smooth -> aniso_blur` / `glint` | `f_tf_jacobian`; `glint` optional. Lowest priority, most novel output |
| D, motion instrument | `f_vf_optical_flow -> motion -> smooth -> hatch` | `f_tf_motion`. Camera-driven by how the scene moves, not what it looks like |
