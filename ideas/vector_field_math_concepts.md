# Vector Field Math — Concepts Worth Exploring

_Created: 2026-10-10._ Prompted by a re-read of the [Wikipedia vector field
article](https://en.wikipedia.org/wiki/Vector_field), with a follow-up pass
(§10-13) from the [tensor field article](https://en.wikipedia.org/wiki/Tensor_field).
Not a module spec — a list of formal concepts from the articles, each paired
with where it might actually cash out in `f_`. Cross-reference
`ideas/f_vecfield.md` (the family's roadmap hub) and `ideas/INDEX.md`'s
Vector field family section before building on any of these; several overlap
with threads already open there.

---

## 1. Singularity index as an explicit design control

The article's **index** section: a source/sink has index +1, a saddle has
index −1 (more generally (−1)^k for a saddle with k contracting dimensions).
`f_vf_vortex_multi` already places sites with independent convergence/curl,
which implicitly picks an index per site, but nothing exposes "index" as a
parameter a user reasons about directly. A mode (or new producer) that lets
you pick singularity *type* — source, sink, saddle, vortex — per site, with
the field math derived from the choice rather than tuned by hand, would make
deliberate topology ("I want three sources and a saddle, here") buildable
instead of discovered by fiddling with convergence/curl sliders.

**Sharper version, tied to `circular_screen.md`/`f_sharmonics`:** the
**Poincaré–Hopf theorem** says the sum of indices must equal the domain's
Euler characteristic — for a sphere, that's 2, no matter what. (This is the
**hairy ball theorem** as a special case: you cannot comb a sphere's hair
flat without a part or a whorl somewhere.) If a vecfield is ever defined
over the *whole* stereographic/spherical domain the circular-screen work
targets, this isn't a stylistic choice — it's a constraint. A field with
total index != 2 on that domain is either not smooth everywhere or not
actually covering the whole sphere. Worth checking against `f_sharmonics`'s
planned grad-Y_l^m vecfield outlet once that's built: do its singularities
already sum to 2, or does the stereographic projection hide a seam where
the field isn't actually well-defined?

## 2. Central fields as an explicit, simpler generator mode

A **central field** (invariant under rotation about a point — vectors point
straight at or away from the center, no twist) is, per the article, *always*
a gradient field. `f_vf_vortex`'s pure-convergence setting (curl = 0) already
produces one, but it's reached as a special case of a more general module
rather than offered as its own thing. Naming it explicitly — a
"radial/central field" generator with no curl parameter at all, just
convergence sign and falloff — would (a) be the cleanest possible feed for
anything wanting a guaranteed-conservative field (no rotational artifacts),
and (b) make the vortex module's real degrees of freedom clearer by removing
the one that collapses to this simpler case. Worth comparing against what
`f_caustic` actually looks like fed a pure central field vs. one with curl —
central fields might be the "clean lens" case, curl the "swirl" case.

## 3. Gradient/curl decomposition (Helmholtz-style) of an arbitrary field

The article separates **divergence** (source/sink strength) and **curl**
(rotation) as the two things you can extract from a vector field. `f_vf_potential`
already integrates field magnitude over time into a scalar; `f_vf_vorticity`
(parked, unverified) targets curl specifically. Formal next step: given *any*
vecfield (not just a vortex you built from scratch), decompose it into a
gradient part (irrotational, built from some scalar potential) and a
divergence-free remainder (curl-only, built from a stream function) — the
textbook Helmholtz decomposition. That would let any upstream field (fluid
sim output, optical flow, whatever) get split into "the part that's
expanding/contracting" and "the part that's rotating" as two separate
vecfields, each feeding different downstream character. Non-trivial to
implement on GPU at real-time rates (needs a Poisson solve, same cost class
already ruled out for `f_vf_advect`'s pressure-projection step) — flag this
as research-grade, not a near-term build.

## 4. Streamlines vs. pathlines vs. streaklines, as a user-facing toggle

The article names three distinct curves you can draw from a *time-varying*
field: a **streamline** is frozen-instant (what the field looks like right
now), a **pathline** is what a single particle actually did over time, and a
**streakline** is what passes through one fixed point over time. `f_vf_advect`
and `f_vf_streak`/`f_vf_glow` currently blur these together — they accumulate
across frames, which is pathline/streakline-flavored, with no way to see the
"instantaneous streamline" version of the same field. A mode (or a dedicated
single-pass LIC utility, see `ideas/f_vf_smear.md`) that draws true frozen-
instant streamlines would be a genuinely different visual register from the
existing accumulation-based modules — useful as a diagnostic ("what does the
field look like this frame, with no history") as much as an aesthetic choice.
`f_vf_smear`'s LIC candidate is the natural home for this; worth framing it
explicitly as "streamline viewer" rather than just "smoother streak."

## 5. Lie bracket — composing two fields in both orders

The article's **Lie bracket** measures how two vector fields' flows fail to
commute: apply field A then field B vs. B then A, and the difference is
itself a vector field. This is cheaply testable *today* with existing shipped
modules and no new code: feed `f_vf_warp`'s source through field A then
field B, versus B then A, and diff the two results. If the two orders
produce visibly different output (they will, unless A and B are special),
that difference *is* a rendering of the Lie bracket, and might be a
legitimately novel visual texture in its own right — "what commutator
distortion looks like" — distinct from either field alone. Pure experiment,
zero build cost, worth a scratch-patch afternoon before it's anything more.

## 6. Does a warped vecfield transform correctly, or just resample?

The article's covariance/contravariance section: a vector's *components*
must transform by a specific law when you change coordinates — a vector
field is not just "a texture that happens to hold direction data," its
values have to rotate/scale correctly when the underlying space is
reparametrized. `f_droste`, `f_mobius`, and (planned) `f_poincare` all warp
UV space nonlinearly. If any vecfield were ever piped *through* one of these
UV transformers (not just a color texture), does the current pipeline
correctly rotate the field vectors to match the new local coordinate frame,
or does it naively resample the RG channels as if they were plain color data
— which would silently produce a geometrically wrong field (arrows pointing
the "old" direction in the "new" space)? Worth a direct check: this is
either a real latent bug waiting for the day someone chains
`f_vf_vortex -> f_mobius -> f_caustic`, or confirmation that it's already
handled and documented. Cheap to verify, high value if it catches a bug
before it's built on.

## 7. Conservative fields and path-independence as a correctness check

A **conservative field** has the property that the line integral around any
closed loop is zero — path doesn't matter, only endpoints. This is a free
correctness test for anything claiming to be a gradient field (central
fields, `f_vf_fieldmap`'s output): numerically integrate the candidate field
around a closed loop in the NumPy test layer (`tests/gpu_sim.py`) and confirm
it nets to ~zero. Cheap, falls directly into the existing math-tier test
infrastructure, and would catch a mislabeled or buggy "gradient field" before
it reaches the GPU bench tier.

## 8. Complete vs. incomplete fields — deliberate finite-time blow-up

A vector field is **incomplete** if some of its flow lines escape to infinity
(or hit a boundary) in finite time, rather than existing for all time — the
article's example is literally `dx/dt = x^2`. `f_vf_advect`'s note that
"decay > 1.0 is excitable" is this phenomenon showing up already, informally.
Worth naming it as a deliberate design axis rather than an edge case to avoid:
a field tuned to be formally incomplete — trajectories genuinely diverging
in finite simulated time, not just "getting large" — might be a clean way to
produce a controlled, mathematically principled "blow-up" or "collapse"
visual event, as opposed to the usual ad hoc clamping/decay tricks. Research-
flavored; would want a NumPy check of the finite-time-blowup condition before
trying it on the GPU.

## 9. Tensor field as the next rung up — a glyph-field module, someday

Vector field generalizes scalar field (rank 0) one step up; the article notes
the further generalization to general tensor fields (via p-vectors and
differential forms). `f_` already has scalar-field territory (luma/hue
processing, `f_util_profile`) and the vector-field family covered here. A
rank-2 tensor field — visualized the classic way, as a field of oriented
ellipses or crosses (think stress/strain glyph plots, or structure-tensor
visualizations of local image orientation+anisotropy) — is a real further
step, not just a bigger vecfield. No clear producer or consumer in mind yet;
flagging it as the next item in the hierarchy rather than anything close to
spec'd. Possible organic entry point: a structure tensor derived from an
image's local gradient (cheap, well-known CV technique) feeding an
ellipse-glyph renderer — would slot in next to `f_vf_fieldmap` as "the same
idea, one tensor rank up."

**Why it's not just a fancier vecfield — concrete phenomena a tensor field
makes possible that a vector field structurally can't:**

- **Unoriented "line fields."** A vector has a sign — it points *this* way,
  not the opposite way. Grain, hair, woven fiber, and crystal structure have
  an *axis*, not a direction: a fiber running at 30° and one running at 210°
  are the same line. Average those as vectors and they cancel to zero;
  average them as a tensor and they correctly reinforce. `f_weave`'s
  orientation-blend bug (`f_weave_orientation_blend.md`, the vector-add vs.
  `atan2` question) is this exact problem in miniature — a tensor
  representation doesn't work around it, it's the structurally correct
  encoding for this whole class of "grain direction" phenomena.
- **Anisotropic, structure-aware blur.** `f_vf_streak`/`f_vf_glow` blur
  along whatever vecfield they're handed. A tensor derived from the image
  itself would let blur direction *and strength* respond to local structure —
  smear hard along an edge, barely at all across it (or the reverse) — the
  classic coherence-enhancing/edge-aware smoothing used in painterly
  rendering. Different register from feeding those modules a hand-authored
  field: the texture tells the blur what to do, not the other way around.
- **Photoelastic stress-fringe optics.** A genuinely new phenomenon for the
  `f_lens`/`f_caustic`/`f_vf_prism` family specifically: real stressed
  transparent material under polarized light shows rainbow interference
  fringes because mechanical stress is a tensor that locally warps the
  material's optical properties directionally. A synthetic stress tensor
  (built the same way as the structure tensor, or hand-authored) could drive
  a fringe-pattern shader shaped by tensor anisotropy rather than by
  distance from a light source — a different visual species from anything
  currently in the optics chain.
- **Confidence-scaled marks for the discrete-item family.** `f_vf_seeds`/
  `f_grain` orient marks from a vecfield but have no sense of how *sure*
  that orientation is. A tensor input would let mark shape (not just angle)
  respond to anisotropy — elongated needle-marks where structure is strong
  and clear, round/neutral marks where it's weak or ambiguous. Closer to how
  real hatching or fur commits to a direction only where direction actually
  exists in the source.

The common thread: a vector field answers "which way"; a tensor field
answers "which way, and how much does that even mean here" — and the
line-field case means some phenomena (grain, weave, fiber) aren't vector-field
problems at all, no matter how the vecfield math is tuned.

## 10. Tissot's indicatrix — a distortion diagnostic for the existing UV warpers

The [tensor field article](https://en.wikipedia.org/wiki/Tensor_field)'s own
illustration of the metric tensor is **Tissot's indicatrix**: draw a small
circle at a point, apply a map, and the ellipse it becomes *is* the local
distortion — how much the map stretches, and in which direction. This is a
ready-made diagnostic for `f_droste`/`f_mobius`/(planned)`f_poincare`:
overlay a grid of small circles before the warp and look at what ellipses
come out the other side. That's a direct visual readout of where and how
badly each transform distorts space — exactly the kind of thing
`droste_singularity.md` already reasons about informally near the center
seam, but as a built diagnostic rather than an inference. It also gives a
concrete way to actually *answer* §6 above (whether a vecfield piped through
these warpers transforms correctly): a correctly-transformed vecfield should
rotate/stretch in step with the indicatrix ellipses; a naively-resampled one
won't.

## 11. Jacobian determinant as adaptive anti-aliasing

The article's tensor-density section, stripped of the formalism, says: the
Jacobian determinant of a coordinate change tells you how much a patch of
area stretches or compresses locally. That number is exactly what you'd want
to drive adaptive supersampling or blur radius in a UV warper — stretch more
-> sample/blur more to avoid aliasing, compress -> less needed. This connects
directly to two things already open in `ideas/`: `line_edge_antialiasing.md`
(currently blocked on whether GenExpr exposes screen-space derivatives) and
`f_raster.md`'s supersampling idea. The Jacobian-determinant route may be a
way *around* that GenExpr-derivatives block entirely — the Jacobian can be
computed analytically straight from the warp's own closed-form math (already
in hand for `f_mobius`/`f_droste`), with no hardware derivative instruction
needed at all.

## 12. Covariant derivative — a correctness warning for curved domains

The article's point about covariant derivatives: differencing a tensor (or
vector) field component-by-component gives the wrong answer once the
coordinate system itself is curved or distorted, because the basis is
changing too — you need a derivative that accounts for that. This sharpens
§6's warning beyond "does a warped vecfield transform correctly": it applies
the moment *anything* computes a gradient **on** a stereographic or
Poincaré-disk domain rather than in flat UV space — i.e., squarely
`f_sharmonics`/circular-screen territory. Worth flagging there directly:
don't assume a plain central-difference gradient computed on that domain is
geometrically correct without checking it against the domain's actual
curvature.

## 13. Authoring distortion from a metric, instead of from a formula

The one genuinely new *producer* idea here, not a diagnostic for something
already built. `f_droste`/`f_mobius`/`f_poincare` all start from a
closed-form coordinate transform, and the distortion (§10) is a side effect
of that formula. The reverse is also possible: author or derive a metric
tensor field directly — a "how stretchy is space here" map — and solve for a
UV warp that's locally consistent with it, without ever writing down a
global closed-form transform. That's a different design axis from anything
else in the conformal-geometry cluster: those modules are "pick a formula,
see what distortion results"; this would be "pick the distortion, solve for
a map that produces it." Research-grade — closer to `f_conformal_fill.md`'s
offline-solve flavor (a discrete differential-geometry problem) than a
real-time shader — but it's a real gap, not a restatement of anything
already in `ideas/`.

---

## Where this connects to open threads

- #1 and #2 bear directly on `f_vf_vortex`/`f_vf_vortex_multi` and on the
  circular-screen/`f_sharmonics` work (`circular_screen.md`, `f_vecfield.md`).
- #3 overlaps `f_vf_potential` and the parked `f_vf_vorticity` — don't start
  either without re-reading those files first.
- #4 is a reframing of `ideas/f_vf_smear.md`'s LIC candidate, not a separate
  build.
- #5 and #6 are cheap to investigate with zero new code — good candidates
  for a short scratch session before anything bigger. **Spiked 2026-10-10**
  (NumPy, not Max — see `HANDOFF.md`): #5 confirmed visibly non-commuting
  (`tests/spike_lie_bracket.py`, `scratch/lie_bracket_spike.png`); #6
  confirmed true from source (`f_mobius` naively resamples a piped-through
  vecfield) and characterized via #10, see below.
- #7 is a test-infrastructure addition, not a module.
- #8 is speculative and research-grade; pairs with `vorticity_confinement.md`
  and `ceyron_simulation_scripts_notes.md`'s open questions about what's
  actually affordable at real-time rates.
- #9 is genuinely new territory, not represented anywhere else in `ideas/`.
- #10 is a diagnostic for `f_droste`/`f_mobius`/`f_poincare` and the most
  direct way to settle #6 empirically — build this before worrying about
  the others. **Spiked 2026-10-10 for `f_mobius`** (`tests/spike_mobius_vecfield_transform.py`):
  both its paths are conformal, so its true indicatrix is always a circle,
  never an ellipse — the honest diagnostic turned out to be a local-scale
  heatmap, not drawn ellipses (`scratch/mobius_vecfield_rotate_zoom.png`,
  `scratch/mobius_vecfield_invert.png`). `f_droste`/`f_poincare` not yet
  checked — their maps may not be purely conformal, worth re-deriving rather
  than assuming this result carries over.
- #11 connects to `line_edge_antialiasing.md` and `f_raster.md`; possibly a
  way around the GenExpr-screen-space-derivatives block noted there.
- #12 is a correctness warning for `f_sharmonics`/circular-screen gradient
  work, not a module on its own — note it in `circular_screen.md` or
  `f_sharmonics.md` once either is actively being built.
- #13 is genuinely new territory alongside #9, closer in spirit to
  `f_conformal_fill.md` than to the formula-driven warpers it's compared
  against.
