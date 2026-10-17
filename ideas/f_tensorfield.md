# f_tensorfield — Tensor Field Family

_Created: 2026-10-10. Started as a draft spec (`.specify/f_tf_structure/`, the working name then),
moved here 2026-10-10 once it became clear the content was overwhelmingly
open questions and cross-references, not settled architecture — eight open
questions against a handful of "likely safe, not yet confirmed"s is an
ideas file, not a spec (Matt's own call). `f_vecfield.md` is the model for
this doc's role: the family's hub, not a build plan for any one module._

**Status:** Concept only. Nothing built. One producer concept sketched in
enough detail to NumPy-spike; all 12 non-paused built modules in the
library that take a vecfield input have been audited as candidate
consumers (2026-10-11), none of them safely wireable yet; several
cross-cutting questions that aren't this family's to resolve alone.

---

## Origin

Prompted by `vector_field_math_concepts.md` #9 (tensor field as the next
rung up from vector fields: a vector answers "which way," a tensor answers
"which way, and how much does that even mean here" — and some phenomena,
unoriented line fields chief among them, aren't vector-field problems at
all no matter how the vecfield math is tuned). That file's own framing
split #9 into four sub-ideas at very different readiness levels:

| Sub-idea | Readiness (as of 2026-10-10) |
|---|---|
| Structure tensor producer (image gradient → tensor) | Spiked, see below |
| Anisotropic structure-aware blur (consumer) | Depends on producer + consumer-side work below |
| Confidence-scaled marks (`f_vf_seeds` variant) | Depends on producer + consumer-side work below |
| Photoelastic stress-fringe optics | Not pursued — no producer/consumer wiring sketched at all |

---

## Scope note: this may be bigger than "plumb two outlets into free inlets"

Raised by Matt 2026-10-11, after the first few consumer candidates turned up
fits that were about more than wiring (`f_vf_glow`'s `direction` enum as a
continuous anisotropy-driven blend; `f_stipple`'s own `anisotropy`/`angle`
params already meaning almost exactly what the tensor's outlets mean). The
real opportunity may be library-wide: more intuitive, more performative,
per-pixel-responsive control surfaces across *most* modules, not just a
short list of "consumers that happen to accept a vecfield already." That's
a different-shaped project than this doc has been scoped as so far, and it
splits into two phases with very different character:

1. **Survey/audit — what this doc has been doing.** Establish the
   conceptual superstructure: what the producer outputs, what existing
   modules' params could plausibly be driven by it, where the sign/safety
   hazards are. Cheap, breadth-first, done from reference docs and
   `definition.py` files without needing to open most codeboxes.
2. **Per-module finesse — not yet started.** Each real candidate needs its
   own design pass, one module at a time, and for some of them "finesse"
   undersells it — it's a deeper rethink of that module's control surface,
   not just finding or adding an inlet. `f_vf_glow`'s `direction`-as-blend
   is already more than wiring (turns a 3-way enum into a continuous,
   per-pixel, self-safety-gating value). `f_stipple` would need genuinely
   new inlets for a param pair that currently has no field-driven
   modulation at all. Phase 2 work doesn't block on finishing the
   producer spec first, but it does block on having outlet 2/3's
   representation settled enough that per-module passes aren't redone
   when that representation changes.

Phase 1 is still incomplete (the consumer audit above should keep
expanding as more modules get checked), but Phase 2 is a different kind
of work and shouldn't be started piecemeal just because a candidate looks
promising in survey. The three items below are held as open questions
for exactly that reason — real, not just plumbing, and not yet earned
the individual attention they'd need.

**Two existing workstreams are the ones that actually matter here**
(confirmed by Matt 2026-10-11, out of the broader project-state check this
raised): `plan.md` item 6, the drift-cleanup project (`definition.py` as
source of truth — currently 32/39 shipped patchers reproducing, 7 still
not, explicitly the project's own "live task queue" right now), and the
paused UI-density/control-surface workstream (`ideas/mod_depth_ui_density.md`
— higher information density while staying legible, paused on Matt
reviewing Max4Live prior art before picking a direction). Phase 2's
"more intuitive, more performative control surfaces" framing may well
*be* that second workstream's direction, not a separate thing running
alongside it — worth deciding together rather than independently before
any Phase 2 module work starts. Drift-cleanup matters differently: it's
not the same question, but several Phase 2 candidates (`f_vf_seeds`,
`f_vf_warp`) are on the never-regenerate list, so Phase 2 work there
inherits that project's constraints (surgical hand-edits, no clean
regenerate) rather than being independent of it.

---

## Producer concept: `f_tf_tensormap`

> **Promoted to a spec 2026-10-16:** `.specify/f_tf_tensormap/spec.md`
> (Draft; renamed from `f_tf_structure` the same day, outlet order and
> bounded-loop smoothing decided by Matt, plan and tasks written). That file is now the source of truth for the producer's
> outlets, encodings, params and acceptance criteria; this section stays
> as the design history. Where they differ, the spec wins.

A structure-tensor producer: the tensor-field family's analog to
`f_vf_fieldmap` in the vecfield family. Takes any scalar-dominant texture
and derives a 2×2 symmetric structure tensor from its local gradient — the
classic computer-vision technique for local orientation *and* how strongly
that orientation is expressed.

**Two outlets, one computed pass** (not a producer + separate bridge
module — the eigendecomposition of a 2×2 symmetric matrix is cheap and
closed-form, no reason to force an extra patch-cord hop). **DECIDED
2026-10-13 (Matt): the packed-convenience shape (Open Question 2's
"fourth producer-outlet shape"), not the original three-way split.**

1. **Raw tensor** (Jxx, Jxy, Jyy packed). Full information, lossless. No
   consumer today; this is what a future glyph-field renderer or
   photoelastic module would need.
2. **Decoded convenience, packed RGBA**: R=cos 2θ, G=sin 2θ, B=trace
   (λ1+λ2), A=anisotropy (λ1−λ2). Direction is still angle-doubled in
   R/G exactly as before — doubling makes θ and θ+π map to the same
   stored value, so there's no arbitrary sign choice flipping
   discontinuously in storage (this fixes the *storage* ambiguity only —
   see Open Questions for what it does and doesn't fix for consumers).
   Replaces the earlier plan's separate direction and eigenvalue
   outlets: every real candidate consumer so far (`f_vf_glow`: trace +
   anisotropy; `f_stipple`: direction + anisotropy) wants a packed pair
   from this exact set, so one consumer takes one inlet and reads
   whichever channels its own math needs, rather than the producer
   pre-committing to which two-or-three values travel together.

**Explicitly rejected alternative:** smuggling tensor data into unused
vecfield channels on existing producers (e.g. the B channel `f_mobius`
et al. already ignore). Would create two ordinary-looking vecfield
textures meaning different things depending on which producer made them
— the same bug shape `module_taxonomy_standardization.md` already caught
once with `mod_inlets` meaning two things while looking identical.

**Field architecture sketch** (Sobel gradient, box-smoothed, closed-form
2×2 eigendecomposition):

```
gx, gy = sobel_gradient(in0)          // project's own verified kernel,
                                       // .specify/stable/f_vf_sobel/spec.md
Jxx, Jxy, Jyy = box_smooth(gx*gx, gx*gy, gy*gy, radius)

trace = Jxx + Jyy
diff  = Jxx - Jyy
lambda1 = 0.5*(trace + sqrt(diff^2 + 4*Jxy^2))
lambda2 = 0.5*(trace - sqrt(diff^2 + 4*Jxy^2))
theta   = 0.5*atan2(2*Jxy, diff)       // principal axis angle

// outlet 2 (direction, angle-doubled):
R = clamp(cos(2*theta)*0.5+0.5, 0, 1)
G = clamp(sin(2*theta)*0.5+0.5, 0, 1)
```

Inlet: single driving inlet (texture + control), required — same
`driving_inlet` shape as `f_vf_fieldmap`, per
`module_taxonomy_standardization.md`'s distinction. No self-generating
mode.

---

## Spike findings (`tests/spike_structure_tensor_range.py`, 2026-10-10)

NumPy spike against synthetic flat/edge/noise content, using the
project's verified Sobel kernel (`f_vf_sobel`), to characterize outlet 1's
actual numeric range before guessing a `strength` default. Figure:
`scratch/structure_tensor_range.png`.

- **Flat content:** trace exactly 0 at every radius (sanity floor holds).
- **Edge content:** trace scales as contrast² exactly (contrast 1.0 →
  trace 16.0 at radius 0 — matches the Sobel kernel's known gain,
  confirming the implementation). Sharp edges exceed typical-texture
  trace by orders of magnitude (16.0 vs. noise's ~0.1 max) — no single
  fixed gain serves both regimes, same tradeoff `f_vf_fieldmap` already
  accepted with its own `strength` param rather than auto-normalizing.
- **Noise content** (coarse white noise, bilinearly upsampled — stand-in
  for `jit.gl.bfg` Perlin, `f_vf_fieldmap`'s own reference case): trace
  p95 ≈ 0.05–0.07, median ≈ 0.015–0.019, fairly stable across smoothing
  radius. Jxy ranges roughly symmetric (±0.03 to ±0.07), confirming a
  0.5=zero offset is the right encoding for that one signed channel.
  Radius mostly dilutes peak/outlier energy rather than the ambient
  median — radius and gain are fairly decoupled for typical content.
- **Visual sanity check:** the anisotropy map's dark (near-isotropic)
  points line up with where the direction field visually becomes
  undefined — matching the index-type singularities
  `vector_field_math_concepts.md` #1 predicts. Trace cleanly separates
  structured ridges from flat regions. Leaning this confirms trace+
  anisotropy as the right representation for outlet 2's B/A channels,
  not just a guess — not fully closed, worth confirming against an
  actual consumer.
- **Provisional `strength` default:** ~10–15× (brings typical-content
  trace p95 into a ~0.5–1.0 range) — needs live-Max visual confirmation,
  not locked in from a NumPy number alone.

---

## Consumer territory

### Full audit: every built module that takes a vecfield input

Audited against `docs/f-reference/module-inventory.md` (algorithm
character) and each module's `src/<name>/definition.py` `mod_inlets` block
(the ground truth `build_patcher.py` builds from — more reliable than spec
prose for "does a free inlet already exist"). This is every `f_vf_*`
module plus `f_caustic`/`f_weave` that accepts a vecfield anywhere in its
inlet list, **excluding anything in `.specify/paused/`** (per the
2026-10-11 standing convention — see README's session rules) — 12
modules, not the 3 first drafted here (2026-10-10 pass missed
`f_vf_chroma`, `f_vf_prism`, `f_vf_advect`, `f_vf_fluid`, `f_vf_split`;
corrected 2026-10-11). `f_vf_vorticity` would otherwise belong in this
table (it takes a vecfield input) but is paused and unverified
project-wide — excluded, not assessed, not treated as a blocker for
anything here.

| Module | Free mod inlet for outlet 2 (B/A: trace+anisotropy) | Outlet 2 sign-safety (R/G: direction) | Confidence |
|---|---|---|---|
| `f_vf_glow` | **Yes** — `radius mod`, unused | Axis-blind in `direction=bidirectional` (default); sign-sensitive in fwd/back modes | Confirmed, prior session |
| `f_vf_chroma` | **Yes, two** — `hue mod`, `dispersion mod`, both unused | Likely sign-sensitive — R/B offset in opposite directions along the local vector; flipping sign swaps which channel shifts which way | Inferred only |
| `f_vf_prism` | **Yes, two** — `reach mod`, `spread mod`, both unused | Likely sign-sensitive — same luma-gated-RGB-split logic as chroma | Inferred only |
| `f_vf_seeds` | **Yes** — `mod tex`, already feeds `size_mod`/`stretch_mod` | Depends on the *shape tex* supplied AND on `phase` — symmetric marks (ellipse/dash) at `phase=0` are axis-blind, directional marks (arrow/comet) or any nonzero `phase` are sign-sensitive. Orientation is built from a genuine, non-doubled angle either way, so outlet 2's R/G needs a decode+redouble step at the consumer regardless of which case applies | Confirmed 2026-10-16 |
| `f_vf_streak` | No | Sign-sensitive — one-directional algorithm, no bidirectional mode | Confirmed |
| `f_vf_warp` | No | Sign-sensitive — single-sample UV displacement | Inferred |
| `f_caustic` | No (vecfield inlet itself has no connected-state tracking — unconnected is silent, not a default field) | Sign-sensitive — backward streamline accumulation toward convergence zones | Inferred |
| `f_vf_advect` | No | Sign-sensitive — temporal accumulation along a direction, same shape as caustic/warp. **Missing from the exclusion list below until now.** | Inferred |
| `f_vf_potential` | No (2nd inlet is `color`, a texture, not a scalar) | Sign-sensitive — per-frame increment is magnitude-only (`field_mag*dt`), but the backward-advect lookup position (`src_uv = uv - (fx,fy)*dt`) depends on direction; an axis field's branch-cut would corrupt the temporal trail the same way it would for `f_vf_fluid` | Confirmed 2026-10-16 |
| `f_weave` | No — bare `in1` already carries the vecfield (no `vs_instate` tracking, unlike other consumers), `in2` already carries scalar-potential/color | Sign-sensitive — vector-add+renormalize blend (the known `f_weave_orientation_blend.md` bug) reacts sharply to a local axis flip | Inferred |
| `f_vf_fluid` | No — the vecfield *is* the primary inlet (force input), same `in1`-is-the-field pattern as `f_vf_fieldmap` | Sign-sensitive — force adds velocity in the force's direction each frame; an axis field would force the solver toward the branch cut's two opposite directions on alternating frames/pixels. Temporal, so a bad sample doesn't just mis-render once, it corrupts the persistent state | Inferred, new row |
| `f_vf_split` | No — same `in1`-is-the-field pattern; outputs raw X/Y channels | **Not sign-sensitive in a meaningful sense — it's a decode-adjacent utility, not an effect.** Feeding outlet 2 directly into `f_vf_split` (bipolar mode) returns `cos(2θ)` and `sin(2θ)` as two separate scalar textures with no `atan2` involved at all. For any downstream use that only needs the raw doubled components (not a literal recovered angle), this sidesteps Open Question 6 entirely | New row, mechanically obvious once named |

Two follow-on findings from this pass:

- **`f_vf_chroma`/`f_vf_prism` are the best-positioned B/A (trace+anisotropy)
  targets in the whole library** — two free scalar inlets each, zero new
  plumbing, not previously considered.
- **`f_vf_split` suggests the angle-doubled encoding might not need full
  `atan2` decoding everywhere.** Some consumer designs could work directly
  off `(cos 2θ, sin 2θ)` as a bipolar pair rather than recovering θ itself
  — worth keeping in mind before assuming Open Question 6 blocks everything
  equally.

### The sign/branch-cut problem, precisely

Angle-doubling fixes the *storage* ambiguity (smooth R/G channels, no
discontinuity). It does not fix *decoding*: every consumer must recover
`θ = 0.5 * atan2(G_decoded, R_decoded)` and re-encode as `(cos θ, sin θ)`
to get a usable step direction, and halving an `atan2` result confines θ
to `(−π/2, π/2]` — a structure whose true axis sits near vertical gets
its recovered θ flipping between just under +90° and just over −90° as
the real axis crosses that line, two values that look close as angles but
point opposite ways as vectors. Fixed-location and predictable rather
than content-dependent, but not eliminated. Whether it's visible depends
on whether the consumer's own algorithm is symmetric to it (see table).

**Open design question, not resolved:** nothing today lets a consumer
*detect* whether its vecfield inlet received a flow field or an axis
field — both are ordinary f_vecfield-contract textures. Today this is
covered only by convention (document `f_vf_glow`'s `direction=bidirectional`
requirement, don't patch a tensor-sourced field into `f_vf_warp`), which
is discipline, not enforcement — see the named-mod-texture tagging
discussion below for a possible mechanism, not pursued yet.

### Explicit exclusion list

Outlet 2's R/G (direction) channels must not reach sign-sensitive
consumers regardless of the above: `f_vf_warp` (displacement direction),
`f_caustic` (refraction direction), `f_vf_advect` (temporal accumulation
along a direction — added 2026-10-11, missing from the first pass of
this list), `f_vf_fluid` (force direction, also temporal),
`f_vf_potential` (backward-advect lookup direction, also temporal —
confirmed 2026-10-16, moved here from "genuinely open"), `f_vf_seeds`
(orientation frame built from a genuine, non-doubled angle — confirmed
2026-10-16; symmetric-shape/`phase=0` case is axis-blind but still can't
take R/G directly without a decode+redouble step), `f_vf_chroma`/
`f_vf_prism` (channel-split direction, pending confirmation). (`f_vf_vorticity`
is not evaluated at all — it's in `.specify/paused/`, excluded from this
analysis per the standing 2026-10-11 convention, not placed on either
list.)

### Future, not pursued

- **Glyph-field renderer** (ellipse/cross field, structure/stress-tensor
  visualization) — the one consumer that actually needs outlet 1 (raw
  tensor), since ellipse aspect ratio needs both eigenvalues, not
  reducible to direction+one-scalar. No architecture sketched.
- **Photoelastic stress-fringe optics** — genuinely new visual territory
  for the `f_lens`/`f_caustic`/`f_vf_prism` family. No producer/consumer
  wiring sketched at all, per `vector_field_math_concepts.md` #9's own
  assessment.
- **Confidence-scaled marks** (full version — mark *shape*, not just
  weight, responding to anisotropy) — `f_vf_seeds`' mod-tex inlet gets
  outlet 3 wiring above, but shape-responds-to-anisotropy is a further
  step not scoped here.

---

## Beyond the vecfield-consumer audit: a three-part heuristic for built modules (2026-10-11)

The audit above only covers modules that already have a vecfield inlet. A
broader test, run against the full `module-inventory.md` rather than just
that subset: does a built module (1) fight a vector that secretly has no
sign, (2) want a diagnostic ellipse (ties to `vector_field_math_concepts.md`
#10, Tissot's indicatrix), or (3) flatten a genuinely second-order/curvature
quantity to a scalar? Five real hits, one of them already measured with
hard numbers:

- **`f_caustic` — strongest hit, already evidenced.** `optics_map.md`'s own
  caustic-fidelity research already diagnosed this without naming it as a
  tensor problem: the module weights its accumulation by divergence
  (`-div F`), the *trace* of the local Jacobian. Its own root-cause note —
  "a saddle (eigenvalues of opposite sign) can have zero divergence while
  sitting exactly on a fold. The divergence weight sees none of that." — is
  exactly a scalar standing in for a tensor. The det-gather and GPU-scatter
  experiments that *did* reproduce folds worked because they used the full
  Jacobian (`det(I + d·J)`), eigenvalues and all, not its trace. **Now
  measured, 2026-10-12** (`tests/spike_caustic_trace_vs_jacobian.py`,
  same glass/truth as the fidelity research; seeds 7 and 3 agree): the trace
  weight and the local
  full-Jacobian gain never disagree at the top-8% level at d* — the
  saddle-on-a-fold scenario optics_map.md raised does *not* occur on this
  smooth periodic glass (near-fold pixels coincide with strong negative
  divergence, so the trace sees them). The real deficit is structural,
  inside the 53–55% of interior pixels that are saddles at d*: there the
  trace weight correlates with photon-counting truth at r ≈ 0.52–0.69
  vs the full Jacobian's r ≈ 0.60–0.80 (and IoU 0.28–0.38 vs 0.28–0.42).
  In the defocus and focus partitions the two are equivalent (focus:
  0.62/0.66 and 0.52/0.53 — the trace is nearly all the signal there).
  Caveat that bounds the whole comparison: past the first fold (3.5 d*)
  the one-branch local det gain collapses (r ≈ 0.15–0.20, *worse* than
  the trace's 0.46–0.56) — the full Jacobian is only a better weight
  below d*, and multi-branch handling, not the tensor representation, is
  the binding constraint further out. So the audit-table amendment this
  buys is: "sign-sensitive, inferred" gains a measured
  saddle-partition-only fidelity gap, not a blanket one.
- **`f_stipple` — confirms Open Question 13.** No vecfield inlet today, but
  its own `anisotropy`/`angle` params already mean almost exactly what the
  tensor's eigenvalue-anisotropy and principal-angle outlets mean —
  currently global dials, not per-pixel. Strongest *semantic* match in the
  library; still needs new inlets, not free plumbing.
- **`f_stereo` — new, not previously flagged anywhere.** The Tissot-
  indicatrix diagnostic (`vector_field_math_concepts.md` #10) was spiked
  against `f_mobius` and `f_droste` but never pointed at `f_stereo`, despite
  being the same shape of module — a parametrically blended UV transform
  (ortho↔stereographic). Orthographic projection is not conformal;
  stereographic is — so sweeping `f_stereo`'s blend parameter sweeps the
  indicatrix from a genuine ellipse toward a perfect circle, exactly the
  diagnostic already built for the other two warpers, just never run here.
- **`f_lens` — a prediction, not yet checked.** `f_anamorph_unnamed.md`
  already established `f_lens`'s distortion math is locally isotropic at
  every pixel (`warp_cx`/`warp_cy` share one multiplier), which predicts its
  Tissot indicatrix is always a circle — the same negative result
  `f_mobius` got, never actually spiked for `f_lens`. Also why
  `optics_map.md`'s astigmatism/field-curvature row is stuck at "Research":
  astigmatism is direction-dependent defocus, and the module's current math
  is structurally incapable of producing it without becoming genuinely
  tensor-valued.
- **`f_masonry` — marginal, by proxy only.** Doesn't hold a tensor quantity
  itself, but is a named beneficiary of idea #11 (Jacobian-determinant-
  driven adaptive AA) once that's built, since `line_edge_antialiasing.md`
  already flags its mortar lines as sharing `f_weave`'s aliasing bug.

Everything else in `module-inventory.md` — the tonal-grading modules, the
routing/utility layer, and the vecfield producers (vortex/flow/repulse/
optical-flow all carry a legitimate sign, not a line-field ambiguity) —
doesn't fit any of the three criteria. Logged so it isn't re-checked.

## Paused-module check (2026-10-11): no unblocks found

Read every spec/plan in `.specify/paused/` against this same question —
would a tensor-field representation release any of these stalls? No. Each
paused module's actual blocker is orthogonal to representation type:

- **`f_apollonian`/`f_poincare`** — both blocked on the same bug (plan.md
  ADR-8): accumulated Möbius-transform composition/parity-tracking in the
  iterated-inversion math. An algebra correctness bug in the fold logic
  itself, not a missing tensor quantity. One soft, non-blocking connection
  worth remembering for later: `f_poincare`'s real hyperbolic curvature is
  explicitly out of scope for its current phase, and once the parity bug is
  fixed, `vector_field_math_concepts.md` #13 (author a UV warp from a
  metric tensor field directly, rather than a closed-form formula) is a
  plausible path to genuine curvature — but that's a future phase, not
  today's stall.
- **`f_stereogram`** — blocked on a Vsynth architecture limit (intra-frame
  multi-pass render-to-texture), unrelated to field representation. Already
  explicitly decided that its depth input is scalar, not vecfield-typed
  (correctly — depth has no 2D direction to encode).
- **`f_vf_chroma`** (the paused streak-effect draft, distinct from the
  simpler R/B-split version already shipped) — blocked on an averaging-vs.
  first-hit-loop architecture question and a `build_patcher.py` 3-option
  toggle bug. Not a representation problem.
- **`f_vf_vorticity`** — blocked on whether curl + vorticity-gradient fit in
  one codebox pass or need a multi-stage chain. Curl/vorticity carries a
  genuine sign (rotation direction), not a line-field ambiguity — no fit
  for this family's math anyway.
- **`f_focus`** — not actually blocked; Phase 1 ships standalone. The
  deferred part (tilt/axis extraction from `f_lens`) is a scalar focus/CoC
  map, already checked above (`f_lens_tiltshift_split.md`) and ruled out as
  a tensor fit.

## Open questions

> **Terminology note (2026-10-13):** questions 2, 5, 6, 7, and 9 below
> were written against the original three-outlet plan (1=raw tensor,
> 2=direction, 3=eigenvalues). That plan is superseded — see the Producer
> concept section above and the Packing corollary resolution below. Read
> them with this mapping: old outlet 2 (direction) is now the R/G
> channels of the new outlet 2 (packed convenience); old outlet 3
> (eigenvalues/trace+anisotropy) is now that same outlet's B/A channels.
> Nothing below needed re-deciding on the merits — the content and
> representation choices stand, only the outlet count changed — but a
> literal "outlet 3" or "outlet 2 only" reference is stale until these
> items get a terminology pass.
>
> **Terminology pass completed 2026-10-16.** All literal "outlet 3"
> references in this doc are now written as outlet 2's B/A
> (trace+anisotropy) channels; "outlet 2" references are clarified as
> its R/G (direction) channels where the distinction matters.

1. **Outlet 1 (raw tensor) range/normalization.** Spiked (above);
   provisional `strength` ~10–15 needs live-Max confirmation.
2. **Outlet 3 representation — RESOLVED 2026-10-13 (Matt), via the
   packing decision below.** Trace+anisotropy, not raw λ1/λ2 (spike
   evidence above) — and now not a separate outlet at all, but the B/A
   channels of outlet 2's packed convenience RGBA.
3. **Gradient operator.** Sobel (reusing the verified `f_vf_sobel`
   kernel) used in the spike; Scharr comparison deferred, not blocking
   unless Sobel proves insufficiently sharp for fine grain/weave-scale
   structure once a real consumer exists.
4. **Module naming — RESOLVED 2026-10-16 (Matt): `f_tf_tensormap`** (it
   was `f_tf_structure` until then). `tf` is the family prefix, parallel
   to `vf`; module prefix `tensormap`. The constitution's naming table
   still needs an `f_tf_` entry (tasks T042).
5. **First consumer to validate against.** `f_vf_glow` still looks like
   the right target — wiring-only on the B/A (trace+anisotropy)
   channels, wiring+decode-only on the R/G (direction) channels
   (bidirectional mode). `f_vf_chroma`/`f_vf_prism` are now the
   strongest *second* candidates for the B/A channels specifically (two
   free inlets each, no plumbing). `f_vf_streak` needs real
   architecture work first; not a good first target.
6. **GenExpr `atan2` safety in `jit.gl.pix` — VERIFIED SAFE, 2026-10-12**
   (`tests/spike_atan2_safety.py` + `tests/bench/codeboxes/atan2_safety.gen`,
   live on the GPU bench). Compiles, runs clean, no bench errors. On
   *decoded sampled-texture* input (the actual decode use case, stronger
   than the skill file's analytic-coords precedent): max wrap-aware error
   vs `np.arctan2` 5.6e-7 rad across all four quadrants; pixels near the
   branch cut match their own pixel-centre truth (no cross-cut smearing,
   5.5e-7 rad), and 24,934 adjacent-texel pairs correctly jump ~2π at the
   cut — properly wrapped, not interpolated. The decode shapes consumers
   need all pass: half-angle `0.5·atan2` (2.8e-7 rad excl. one degenerate
   texel) and the doubled round trip `atan2(sin t, cos t) == t` (7.8e-7
   rad). **One real caveat, measured:** at the cut boundary itself
   (`Fy == 0, Fx < 0`) the GPU returns +π where IEEE `atan2(-0, -x)` is
   −π — a ±π convention difference at the single most degenerate input.
   Benign for consumers (±π is the same line direction; and blends use
   vectors/doubled components, never the literal value), but a downstream
   NumPy mirror diffing against GPU output must wrap-compare there.
   Blocks nothing: outlet 2's decode is cleared to build.
7. **Mod-texture unipolar/bipolar convention — inherited, not new.**
   `named_mod_textures.md` already flags "the unipolar/bipolar divergence
   between `f_masonry` and Kevin's `vs_displacement`" as unresolved and
   blocking. The B/A (trace+anisotropy) channels' final range can't be
   locked to something that behaves sensibly in `f_vf_glow`'s radius mod
   inlet or `f_vf_seeds`' `size_mod`/`stretch_mod` without reading what
   those inlets actually expect, per consumer.
8. **Could named-mod-texture tags double as a type declaration, not just
   a routing role?** Raised by Matt 2026-10-10. Tagging by *type*
   (`vecfield_flow` vs. `vecfield_axis` vs. `tensor_raw`, plain Vsynth
   content untagged/default) instead of/alongside tagging by *role*
   (`dir_tex`, `aniso_tex`) would let a consumer's `route` demux branch
   its own decode logic on the tag — closing the flow-vs-axis detection
   gap in the open design question above. Coupled to, not incidental to,
   `named_mod_textures.md`'s shared-inlet mechanism: the ambiguity only
   becomes live once more than one semantic flavor can reach the same
   physical inlet (today's one-dedicated-inlet-per-source convention
   avoids it via implicit human-declared typing by cable choice). Also
   raises the bar on that file's own open verification items — if tags
   become load-bearing for *which decode to run* rather than just *which
   param to modulate*, the unresolved pix-hop failure and untested T4/T6
   ordering are gating correctness, not convenience. Not pursued
   further; belongs in `named_mod_textures.md`'s own thread once its
   prerequisite verification work is done.
9. **`f_vf_seeds` sign-sensitivity — RESOLVED 2026-10-16, confirmed via
   codebox read.** `taper` indeed doesn't exist in the shipped param
   list, but that's not what settles this. Both `codebox_seeds.gen` and
   `codebox_seeds_render.gen` build the local `(along, across)` frame
   directly from raw `vx/vy` via `fcs=vx/mag, fsn=vy/mag` — a genuine
   full-angle basis, not an angle-doubled one. Two consequences: (1)
   `phase` (default 0, but a live performable dial) shifts `along`
   asymmetrically (`along_shifted = along - phase*marklen_eff`), so any
   nonzero phase makes the mark sign-sensitive regardless of shape
   symmetry; (2) even at `phase=0`, only shape textures symmetric under
   180° rotation (ellipse/dash) are axis-blind — directional shapes
   (arrow/comet) read the flipped side of the shape tex when the sign
   flips. Matches the audit table's existing characterization exactly,
   now confirmed rather than inferred. **Consequence for wiring:**
   outlet 2's R/G (doubled cos2θ/sin2θ) can't be fed to this inlet
   directly in either case — the codebox expects a genuine signed
   vector, not a doubled one, so a decode-and-redouble step (recover θ,
   re-emit `cos θ, sin θ`) is required at the consumer regardless of
   phase/shape, and even after that decode, nonzero `phase` keeps this
   sign-sensitive by design, not just by convention.
10. **Does any real use case need the raw decoded angle, or would
    `(cos 2θ, sin 2θ)` as a bipolar pair suffice?** Raised by the
    2026-10-11 audit, via `f_vf_split`: if a consumer's modulation target
    is itself just two independent scalar depths (not literally "rotate
    by this angle"), feeding it the raw doubled components sidesteps
    Open Question 6's `atan2` block entirely for that consumer. Not
    assessed per-module yet — would need checking against each
    candidate's actual math, not just its I/O shape.
11. **`f_vf_potential`: does it integrate direction or only magnitude —
    RESOLVED 2026-10-16, confirmed via codebox read: both, in different
    places.** `codebox_potential.gen` shows the per-frame *increment* is
    magnitude-only (`potential = prev*decay + field_mag*dt`,
    `field_mag = sqrt(fx²+fy²)`) — exactly the axis-blind case the
    question hoped for. But the backward-advect step that decides
    *where* `prev` is sampled from is direction-dependent:
    `src_uv = uv - (fx,fy)*dt`. An axis field's branch-cut ambiguity
    would make that lookup position flip between two directions
    frame-to-frame (or pixel-to-pixel near the cut) even though the
    amount added each frame wouldn't change — the same temporal-state
    corruption shape already flagged for `f_vf_fluid`, not a new
    failure mode. **Moved to the exclusion list** (sign-sensitive,
    temporal) rather than staying genuinely open.
12. **`f_vf_glow`'s `direction` as a continuous, per-pixel anisotropy-driven
    blend instead of a flat 3-way enum — RESOLVED 2026-10-16 (design),
    zero-new-UI scope.** Raised by Matt 2026-10-11; designed 2026-10-16
    as the first Phase 2 module, chosen specifically because it needs no
    new panel dial and so isn't blocked behind the paused
    `mod_depth_ui_density.md` question the way `f_stipple` (Q13) is.
    Grounded against the real `codebox_v1.gen`/`definition.py` (not a
    sketch): `fwd_mode`/`bwd_mode` are already computed branchlessly from
    `direction` via `step()`; this design only continuizes the weight
    that reaches the accumulation loop, `direction` itself keeps its
    current meaning and default.

    **Only touches outlet 2's B/A (anisotropy) channel — not R/G.** This
    is a confidence gate on the *existing* vecfield inlet's trustworthiness,
    not a rewiring of the direction source. The R/G decode-and-redouble
    problem (open questions 6/9/10) is a fully separate, still-blocked
    piece of work and isn't touched here.

    **New mod_inlet, no new dial** — `anisotropy`, a fourth texture inlet
    (`in4`), following the exact precedent `radius mod` already sets in
    this same module (a mod_inlet with no separate depth dial of its
    own):
    ```python
    "mod_inlets": [
        {"label": "vecfield", "state_param": "src_vecfield"},
        {"label": "radius mod"},
        {"label": "anisotropy", "state_param": "src_anisotropy"},
    ],
    ```

    **Connection detection must use `state_param`, not a content
    heuristic — this is the one real correctness catch.** An unconnected
    texture inlet samples as black (0), but the neutral/no-op value this
    gate needs when nothing is patched in is `1.0` (full confidence,
    reproducing current behavior exactly). Glow's own vecfield inlet
    gets away with a content heuristic (`field_suppress = step(0.02,
    raw_x+raw_y)`) only because zero is *also* the correct neutral value
    for a flow field — that coincidence doesn't hold here, and reusing it
    would silently force every existing `direction=1`/`2` patch toward
    bidirectional-safe the moment nothing's wired in. `src_anisotropy` as
    a `state_param` (the same mechanism `f_vf_potential` already uses
    correctly: `connected = step(0.5, src_vecfield)`) sidesteps this
    cleanly — declared in `mod_inlets` above but unused in `f_vf_glow`'s
    own vecfield inlet today, so this is the first time the module
    actually exercises it.

    **Codebox change:**
    ```c
    Param src_anisotropy(0.0);
    ...
    // existing, unchanged:
    fwd_mode = 1.0 - step(1.5, direction);
    bwd_mode = 1.0 - step(0.5, direction) + step(1.5, direction);

    // new:
    aniso = mix(1.0, sample(in4, uv).x, src_anisotropy);  // 1.0 = full confidence, unconnected default
    fwd_weight = mix(1.0, fwd_mode, aniso);                // 1.0,1.0 = safe bidirectional floor
    bwd_weight = mix(1.0, bwd_mode, aniso);
    ```
    At `direction=0`, `fwd_mode=bwd_mode=1` already, so `aniso` is a
    no-op — bidirectional stays axis-blind exactly as the audit table
    already says. At `direction=1`/`2`, low anisotropy continuously pulls
    the pixel back toward the bidirectional floor; high anisotropy lets
    the chosen one-directional mode fully apply. Linear mix chosen to
    match the codebox's own existing branchless/mix idiom throughout —
    no gamma/curve param, which would itself be a new dial.

    **Explicitly deferred, not part of this design:** (a) a
    performer-facing gain dial on top of `aniso` (Q15's "nice to have,
    not required") — waits for `mod_depth_ui_density.md`; (b) wiring
    outlet 2's R/G into `in2` at all, which needs the decode+redouble
    step `f_vf_seeds` (Q9) already showed is mandatory, not optional.

    **Blocked on, before this is buildable:** `f_tf_tensormap` (the
    producer) doesn't exist in `.specify/` yet — concept-only. This
    design can sit ready, but specifying the producer is the real next
    step, not this module.
13. **`f_stipple`'s `anisotropy` and `angle` as tensor-driven per-pixel
    params instead of flat dials.** Raised by Matt 2026-10-11. Not a
    vecfield consumer today (no inlet at all), but its own `anisotropy`
    param already blends a directional hash against an isotropic one —
    the same concept the tensor's eigenvalue-derived anisotropy
    represents, just currently global rather than content-driven. Tighter
    semantic match than any module in the vf-consumer audit table, but
    needs two new inlets (or one packed one) and its own design pass, not
    just plumbing.
14. **`f_grain`'s `jitter`/`size_var` as tensor-driven sites instead of (or
    alongside) whatever currently drives their per-grain randomization.**
    Raised by Matt 2026-10-11. `f_grain.md` says grain position/size/
    shape/color are already "driven by the input texture's luminance,"
    which suggests some existing per-grain content-read mechanism — but
    this hasn't been confirmed by reading the actual codebox, so it's
    genuinely unknown whether extending that mechanism to trace/
    anisotropy is a small change or a deeper restructure. Needs
    `codebox_grain.gen` (or whichever file holds the live math) read
    before concluding either way — explicitly not assumed to be an easy
    fit just because the shape of the idea is appealing.

15. **Anisotropy as a multiplicative confidence-gate on mod-amount,
    generalized beyond `f_vf_glow`'s `direction`.** Raised by Matt
    2026-10-11. Two different axes shouldn't be collapsed: a mod-amount
    dial answers performer intent ("how much do I want this param to
    respond right now"), anisotropy answers local data confidence ("how
    much does the field data mean *here*"). Replacing the dial with
    anisotropy loses the performer's ability to mute/ride the effect
    independent of content; the better shape is multiplicative, not a
    substitution: `effective_depth(pixel) = depth_dial * anisotropy(pixel)`,
    or equivalently `sample_eff = sample * anisotropy` before the usual
    accumulation — keeps the dial's meaning unchanged, puts the new
    behavior entirely on the data side, and gets branch-cut suppression
    as a side effect rather than the justification. Open Question 12's
    `direction` blend is one instance of this general pattern, not a
    special case of its own. Where a param has *no* existing depth dial
    at all (`f_vf_glow`'s `radius mod` — confirmed from the codebox:
    `radius_eff = clamp(radius + mod_val * radius, 0, 0.3)`, no separate
    depth scalar), there's nothing to lose by leaning on anisotropy more
    heavily, but even there a performer-facing gain (defaulting to 1.0
    rather than absent) seems better than zero live control. See
    `f_util_mod_texture.md`'s open questions for the declaration-format
    consequence (does the base/depth/texture triple need a fourth,
    optional confidence-gate-source element).

**Packing corollary, surfaced by 12 and 13 together — DECIDED 2026-10-13
(Matt): adopted.** `f_vf_glow` wants trace+anisotropy packed together
(one inlet, two uses); `f_stipple` wants direction+anisotropy packed
together. Between the two, there's a case for a fourth producer-outlet
shape not previously considered — a single RGBA "decoded convenience"
outlet (R=cos2θ, G=sin2θ, B=trace, A=anisotropy) alongside the
raw-tensor outlet, so each consumer takes one inlet and unpacks whichever
channels its own math needs, rather than the producer pre-committing to a
two-vs-three-outlet split before Phase 2 reveals which combinations
consumers actually want. This is now the producer's shape (see Producer
concept, above) and closes Open Question 2 — see its resolution note.

---

## Cross-references

- `vector_field_math_concepts.md` #9 — origin of this whole thread; its
  own "Where this connects" note previously called tensor fields
  "genuinely new territory, not represented anywhere else in `ideas/`" —
  this file is that representation now.
- `f_vecfield.md` — the sibling family's hub doc and type-contract
  precedent (float32, RG=XY, 0.5=zero); this family's outlet 2 reuses
  that contract's storage shape with a different sign convention.
- `module_taxonomy_standardization.md` — `f_tf_tensormap`'s single
  driving inlet follows the `driving_inlet` distinction this file
  established; also the precedent for "two things sharing a label while
  meaning differently" as a real, already-seen bug shape (motivates
  rejecting the channel-smuggling alternative above).
- `named_mod_textures.md` — the plumbing mechanism outlet 2/3 would
  ideally travel through; its own open verification items (pix-hop
  failure, T4 live, T6) gate both the wiring-only consumers and the
  type-tagging idea in open question 8.
- `f_weave_orientation_blend.md` — shared open question 6 (`atan2`
  safety in GenExpr); **verified safe 2026-10-12**, both files updated.
- `tests/spike_structure_tensor_range.py`, `scratch/structure_tensor_range.png`
  — the NumPy spike backing the findings above.
- `f_vf_sobel` (`.specify/stable/f_vf_sobel/spec.md`) — the verified
  gradient kernel the spike reused.

---

## Next step

Not a build plan yet. Two different kinds of next step are live at once,
per the Scope note above, and shouldn't be conflated:

- **Phase 1 (survey) — CLOSED 2026-10-16.** The `atan2` verification
  (open question 6) was done 2026-10-12, verified GPU-safe. The two
  remaining codebox reads are done: open question 9 (`f_vf_seeds`) and
  open question 11 (`f_vf_potential`) are both resolved and both landed
  sign-sensitive — `f_vf_potential` moved onto the explicit exclusion
  list, `f_vf_seeds` confirmed as needing a decode+redouble step
  regardless of shape/phase. The terminology pass flagged at the top of
  Open Questions is also done — no stale "outlet 3" references remain.
  Open question 13's consumer-design pass is Phase 2 work, not Phase 1,
  and stays open below.
- **Phase 2 (per-module finesse) — started 2026-10-16, deliberately
  narrow.** Checked Q12/Q13 against the paused `mod_depth_ui_density.md`
  question first: `f_stipple` (Q13) genuinely inherits that blocker (no
  mod-inlet machinery exists for `anisotropy`/`angle` today, so wiring
  them means new base+depth dials on an already-dense panel); `f_vf_glow`
  (Q12) doesn't, because `radius mod` already establishes a mod_inlet
  with no separate depth dial in this exact module, and Q12's confidence
  gate can reuse that shape. So Q12 is designed (see above, "zero-new-UI
  scope") and Q13/Q14 stay open, still waiting on the UI-density question
  to resolve (or on their own codebox reads, for Q14).
- **What actually blocks building Q12's design: `f_tf_tensormap` doesn't
  exist yet.** It's concept-only — nothing in `.specify/`. Writing its
  spec (producer outlets, params, `strength` default from the spike
  findings above) is the real next step, not further Phase 2 module
  design; Q12's design can sit ready until then.
