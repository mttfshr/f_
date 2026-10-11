# f_tensorfield — Tensor Field Family

_Created: 2026-10-10. Started as a draft spec (`.specify/f_tf_structure/`),
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

## Producer concept: `f_tf_structure`

A structure-tensor producer: the tensor-field family's analog to
`f_vf_fieldmap` in the vecfield family. Takes any scalar-dominant texture
and derives a 2×2 symmetric structure tensor from its local gradient — the
classic computer-vision technique for local orientation *and* how strongly
that orientation is expressed.

**Three outlets, one computed pass** (not a producer + separate bridge
module — the eigendecomposition of a 2×2 symmetric matrix is cheap and
closed-form, no reason to force an extra patch-cord hop):

1. **Raw tensor** (Jxx, Jxy, Jyy packed). Full information, lossless. No
   consumer today; this is what a future glyph-field renderer or
   photoelastic module would need.
2. **Principal-axis direction**, f_vecfield-contract texture (RG=XY,
   0.5=zero), but encoded via **angle-doubling** (2θ) rather than a naive
   eigenvector-as-vector conversion — doubling makes θ and θ+π map to the
   same stored value, so there's no arbitrary sign choice flipping
   discontinuously in storage. (This fixes the *storage* ambiguity only —
   see Open Questions for what it does and doesn't fix for consumers.)
3. **Eigenvalues**, ordinary scalar texture — leaning trace+anisotropy
   (λ1+λ2, λ1−λ2) over raw λ1/λ2, see spike findings below.

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
  anisotropy as the right outlet-3 representation, not just a guess —
  not fully closed, worth confirming against an actual consumer.
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

| Module | Free mod inlet for outlet 3 | Outlet 2 sign-safety | Confidence |
|---|---|---|---|
| `f_vf_glow` | **Yes** — `radius mod`, unused | Axis-blind in `direction=bidirectional` (default); sign-sensitive in fwd/back modes | Confirmed, prior session |
| `f_vf_chroma` | **Yes, two** — `hue mod`, `dispersion mod`, both unused | Likely sign-sensitive — R/B offset in opposite directions along the local vector; flipping sign swaps which channel shifts which way | Inferred only |
| `f_vf_prism` | **Yes, two** — `reach mod`, `spread mod`, both unused | Likely sign-sensitive — same luma-gated-RGB-split logic as chroma | Inferred only |
| `f_vf_seeds` | **Yes** — `mod tex`, already feeds `size_mod`/`stretch_mod` | Depends on the *shape tex* supplied, not the module alone — symmetric marks (ellipse/dash) are axis-blind, directional marks (arrow/comet) are sign-sensitive | Not yet confirmed — needs `codebox_seeds_render.gen` read |
| `f_vf_streak` | No | Sign-sensitive — one-directional algorithm, no bidirectional mode | Confirmed |
| `f_vf_warp` | No | Sign-sensitive — single-sample UV displacement | Inferred |
| `f_caustic` | No (vecfield inlet itself has no connected-state tracking — unconnected is silent, not a default field) | Sign-sensitive — backward streamline accumulation toward convergence zones | Inferred |
| `f_vf_advect` | No | Sign-sensitive — temporal accumulation along a direction, same shape as caustic/warp. **Missing from the exclusion list below until now.** | Inferred |
| `f_vf_potential` | No (2nd inlet is `color`, a texture, not a scalar) | **Genuinely open** — if it integrates field *magnitude* rather than walking the vector path, it could turn out axis-blind. Don't assume excluded. | Unknown — needs a codebox read |
| `f_weave` | No — bare `in1` already carries the vecfield (no `vs_instate` tracking, unlike other consumers), `in2` already carries scalar-potential/color | Sign-sensitive — vector-add+renormalize blend (the known `f_weave_orientation_blend.md` bug) reacts sharply to a local axis flip | Inferred |
| `f_vf_fluid` | No — the vecfield *is* the primary inlet (force input), same `in1`-is-the-field pattern as `f_vf_fieldmap` | Sign-sensitive — force adds velocity in the force's direction each frame; an axis field would force the solver toward the branch cut's two opposite directions on alternating frames/pixels. Temporal, so a bad sample doesn't just mis-render once, it corrupts the persistent state | Inferred, new row |
| `f_vf_split` | No — same `in1`-is-the-field pattern; outputs raw X/Y channels | **Not sign-sensitive in a meaningful sense — it's a decode-adjacent utility, not an effect.** Feeding outlet 2 directly into `f_vf_split` (bipolar mode) returns `cos(2θ)` and `sin(2θ)` as two separate scalar textures with no `atan2` involved at all. For any downstream use that only needs the raw doubled components (not a literal recovered angle), this sidesteps Open Question 6 entirely | New row, mechanically obvious once named |

Two follow-on findings from this pass:

- **`f_vf_chroma`/`f_vf_prism` are the best-positioned outlet-3 targets in
  the whole library** — two free scalar inlets each, zero new plumbing,
  not previously considered.
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

Outlet 2 must not reach sign-sensitive consumers regardless of the above:
`f_vf_warp` (displacement direction), `f_caustic` (refraction direction),
`f_vf_advect` (temporal accumulation along a direction — added 2026-10-11,
missing from the first pass of this list), `f_vf_fluid` (force direction,
also temporal), `f_vf_chroma`/`f_vf_prism` (channel-split direction, pending
confirmation). `f_vf_potential` is deliberately *not* on this list — see
the audit table above, its safety is genuinely unresolved rather than
assumed-excluded. (`f_vf_vorticity` is not evaluated at all — it's in
`.specify/paused/`, excluded from this analysis per the standing
2026-10-11 convention, not placed on either list.)

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
  Jacobian (`det(I + d·J)`), eigenvalues and all, not its trace. Worth
  amending this file's own audit table above: not just "sign-sensitive,
  inferred" for `f_caustic`, but a measured trace-vs-full-tensor fidelity
  gap with numbers already in hand.
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

1. **Outlet 1 (raw tensor) range/normalization.** Spiked (above);
   provisional `strength` ~10–15 needs live-Max confirmation.
2. **Outlet 3 representation.** Leaning trace+anisotropy over raw λ1/λ2
   (spike evidence above), not fully closed.
3. **Gradient operator.** Sobel (reusing the verified `f_vf_sobel`
   kernel) used in the spike; Scharr comparison deferred, not blocking
   unless Sobel proves insufficiently sharp for fine grain/weave-scale
   structure once a real consumer exists.
4. **Module naming.** `f_tf_structure` is a working name only — `tf`
   prefix for the family (parallel to `vf`) proposed here, not settled
   project-wide.
5. **First consumer to validate against.** `f_vf_glow` still looks like
   the right target — wiring-only on outlet 3, wiring+decode-only on
   outlet 2 (bidirectional mode). `f_vf_chroma`/`f_vf_prism` are now the
   strongest *second* candidates for outlet 3 specifically (two free
   inlets each, no plumbing). `f_vf_streak` needs real architecture work
   first; not a good first target.
6. **GenExpr `atan2` safety in `jit.gl.pix` — unverified, blocks the
   decode entirely.** Nothing in this library has confirmed `atan2`
   behaves safely in a jit.gl.pix codebox. `f_weave_orientation_blend.md`'s
   candidate fix B flagged the identical requirement and never closed
   it. Needs its own small verification pass (per
   `max-advanced-object-methodology`) before any consumer codebox can
   use the decode. Blocks every consumer in the audit table above that
   needs a literal recovered angle — which, per Open Question 10, may
   not be all of them.
7. **Mod-texture unipolar/bipolar convention — inherited, not new.**
   `named_mod_textures.md` already flags "the unipolar/bipolar divergence
   between `f_masonry` and Kevin's `vs_displacement`" as unresolved and
   blocking. Outlet 3's final range can't be locked to something that
   behaves sensibly in `f_vf_glow`'s radius mod inlet or `f_vf_seeds`'
   `size_mod`/`stretch_mod` without reading what those inlets actually
   expect, per consumer.
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
9. **`f_vf_seeds` sign-sensitivity — needs a direct codebox read.**
   The ideas-doc sketch's `taper` param (which would make orientation
   sign-sensitive) doesn't appear in the shipped param list at all —
   good sign, but "likely safe" isn't "confirmed safe." Needs reading
   `codebox_seeds.gen`/`codebox_seeds_render.gen` directly before outlet
   2 is wired there.
10. **Does any real use case need the raw decoded angle, or would
    `(cos 2θ, sin 2θ)` as a bipolar pair suffice?** Raised by the
    2026-10-11 audit, via `f_vf_split`: if a consumer's modulation target
    is itself just two independent scalar depths (not literally "rotate
    by this angle"), feeding it the raw doubled components sidesteps
    Open Question 6's `atan2` block entirely for that consumer. Not
    assessed per-module yet — would need checking against each
    candidate's actual math, not just its I/O shape.
11. **`f_vf_potential`: does it integrate direction or only magnitude?**
    Raised by the 2026-10-11 audit. If its time-integration only
    accumulates field *magnitude* (speed) rather than walking the vector
    path, it could be axis-blind rather than excluded — current framing
    assumed the latter without checking. Needs a codebox read
    (`.specify/f_vf_potential/` or its `.gen` file) before it's placed on
    either list with any confidence.
12. **`f_vf_glow`'s `direction` as a continuous, per-pixel anisotropy-driven
    blend instead of a flat 3-way enum.** Raised by Matt 2026-10-11. The
    codebox already computes `fwd_weight`/`bwd_weight` branchlessly from
    `direction` via `step()` — nothing architectural stops those from
    being continuous, spatially-varying values instead of one of three
    fixed presets. Low anisotropy (direction untrustworthy, e.g. near a
    singularity) could push the blend toward bidirectional/safe
    automatically; high anisotropy could let it lean directional. A
    concrete, real design — not wiring — held open pending Phase 2.
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

**Packing corollary, surfaced by 12 and 13 together:** `f_vf_glow` wants
trace+anisotropy packed together (one inlet, two uses); `f_stipple` wants
direction+anisotropy packed together. Between the two, there's a case for
a fourth producer-outlet shape not previously considered — a single RGBA
"decoded convenience" outlet (R=cos2θ, G=sin2θ, B=trace, A=anisotropy)
alongside the raw-tensor outlet, so each consumer takes one inlet and
unpacks whichever channels its own math needs, rather than the producer
pre-committing to a two-vs-three-outlet split before Phase 2 reveals which
combinations consumers actually want. Worth weighing against Open
Question 2 before that one closes.

---

## Cross-references

- `vector_field_math_concepts.md` #9 — origin of this whole thread; its
  own "Where this connects" note previously called tensor fields
  "genuinely new territory, not represented anywhere else in `ideas/`" —
  this file is that representation now.
- `f_vecfield.md` — the sibling family's hub doc and type-contract
  precedent (float32, RG=XY, 0.5=zero); this family's outlet 2 reuses
  that contract's storage shape with a different sign convention.
- `module_taxonomy_standardization.md` — `f_tf_structure`'s single
  driving inlet follows the `driving_inlet` distinction this file
  established; also the precedent for "two things sharing a label while
  meaning differently" as a real, already-seen bug shape (motivates
  rejecting the channel-smuggling alternative above).
- `named_mod_textures.md` — the plumbing mechanism outlet 2/3 would
  ideally travel through; its own open verification items (pix-hop
  failure, T4 live, T6) gate both the wiring-only consumers and the
  type-tagging idea in open question 8.
- `f_weave_orientation_blend.md` — shares open question 6 (`atan2`
  safety in GenExpr), unresolved there first.
- `tests/spike_structure_tensor_range.py`, `scratch/structure_tensor_range.png`
  — the NumPy spike backing the findings above.
- `f_vf_sobel` (`.specify/stable/f_vf_sobel/spec.md`) — the verified
  gradient kernel the spike reused.

---

## Next step

Not a build plan yet. Two different kinds of next step are live at once,
per the Scope note above, and shouldn't be conflated:

- **Phase 1 (survey) still open:** the `atan2` verification (open question
  6) is the highest-leverage item — it blocks every consumer that needs a
  literal recovered angle, is cheap to check, and several other open
  questions (9, 11) are downstream of it or of similar codebox reads.
- **Phase 2 (per-module finesse) hasn't started on purpose.** Open
  questions 12–14 are real designs, not wiring, and the packing corollary
  they surfaced (RGBA convenience outlet) feeds back into Phase 1's own
  Open Question 2 — so the honest order is: keep closing Phase 1 items,
  let the outlet-count/packing question settle, *then* start Phase 2
  one module at a time, starting wherever the fit is tightest
  (`f_vf_glow`'s direction-blend and `f_stipple`'s anisotropy/angle both
  look like strong first candidates once there's something stable to
  build against).
