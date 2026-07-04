# GPU Gems — Research Backlog

Full text freely available online: https://developer.nvidia.com/gpugems/gpugems
Three volumes: GPU Gems, GPU Gems 2, GPU Gems 3.

Came up in f_stereogram research — Chapter 41 ("Real-Time Stereograms",
Policarpo) is the source of the strip-based SIRDS algorithm. Scanning the
full ToC revealed substantial overlap with f_ work past, present, and future.
Flagged here as a standing research resource to revisit.

---

## GPU Gems 1 — chapters of interest

**Ch 2 — Rendering Water Caustics**
Direct overlap with `f_caustic`. Worth reading to see if there are field-
convergence / accumulation ideas we haven't considered. The GPU Gems approach
may differ architecturally from our streamline-accumulation method.
**Read (2026-07-03). No fit — confirmed negative result, not just unread.**
Chapter's technique requires an analytic wave-height function for a
closed-form gradient, refracts one ray via Snell's Law/environment-map
approximation, and does a single dependent texture read at the ray-plane
intercept — a 3D-geometry technique, brightness purely radial/geometric
(distance-from-vertical → environment-map falloff). `f_caustic` has no
analytic function to differentiate (built to work on arbitrary
`f_vecfield` producers, not just a wave function), so it correctly uses
multi-step streamline tracing with finite-difference divergence as a
convergence-detecting weight instead — a genuinely different mechanism,
not an unoptimized version of the chapter's. The two brightness models
(radial/geometric vs. convergence-based) don't overlap, so nothing in the
chapter transfers into `f_caustic`'s current architecture. Minor
speculative note, not a finding: an optional radial-falloff-from-seed-point
term could in principle stack with the existing divergence weight, but the
chapter doesn't demonstrate this and `f_caustic` has no slot for it today
— not worth its own `ideas/` file.

**Ch 5 — Implementing Improved Perlin Noise**
Ken Perlin himself. We work around the jit.gen `noise()` prohibition with
arithmetic hashes — this chapter may contain alternative hash/lattice ideas
worth borrowing or adapting. Also relevant to any future procedural generator.
**Read (2026-07-03). No fit.** Chapter covers true gradient (Perlin) noise —
interpolated between per-lattice-point gradient *vectors* via a smooth
(fifth-order) blending curve, plus a 12-fixed-direction optimization and a
VRAM-conservation tiled-texture trick. Categorically different from our
sin-hash pattern, which is deliberately uncorrelated per-cell value hashing
for grain/seed placement (no interpolation, no smoothness requirement — the
opposite of what this chapter solves for). Where continuous smooth noise is
actually needed as a pattern source, we delegate to `vs_noise_3` (real
Vsynth module) rather than reimplementing Perlin noise in a codebox, so the
chapter's core algorithm has no landing spot in `f_` either way. One partial
match: §5.6's finite-difference bump-mapping is the same central-difference
pattern already in the `jit-gen-codebox` skill and used in `f_caustic` —
confirms existing practice, not a new idea.

**Ch 8 — Simulating Diffraction**
Iridescence / thin-film interference. Natural companion to `f_vf_prism` and
`f_lens` chromatic aberration. Could inspire a dedicated optical-interference
module or extend the prism's color synthesis.
**Read (2026-07-03). Partial fit — narrower than it first looks.** The
diffraction-grating physics (halfway-vector/tangent projection, Ward
highlight) is 3D-surface machinery with no landing spot in a 2D
vecfield-driven processor. But the chapter's rainbow color-map function —
summed triangular bumps turning one scalar into a full spectrum — is a
genuinely separable, portable primitive that `f_vf_prism` currently lacks:
`f_vf_prism` does 3-tap RGB-channel displacement (chromatic
aberration/fringing), not spectral synthesis, so it structurally can't
produce non-RGB spectral bands. See
`ideas/spectral_rainbow_colormap.md` for the full writeup (tabled, no code
yet).

**Ch 20 — Texture Bombing**
Stochastic mark placement via random offsets into a tile. This is essentially
the problem `f_grain` and `f_vf_seeds` solve. May contain ideas about
neighborhood search, overlap handling, or mark distribution we haven't seen.
High priority read — closest chapter to our core discrete-item family work.
**Read (2026-07-03).** Confirmed `f_grain`/`f_vf_seeds` are Voronoi-
partitioned (nearest-seed-wins), not overlap-bombed like the chapter's
technique — real design fork, not a missing tuning knob. See
`ideas/voronoi_vs_texture_bombing.md` for the full discussion (tabled,
no code yet).

**Ch 21 — Real-Time Glow**
Direct overlap with `f_vf_glow`. May have filtering or accumulation ideas
beyond what we implemented. Worth a quick scan for anything we missed.
**Read (2026-07-03). Partial fit, three separable ideas.** The chapter's
headline separable-2D-convolution technique doesn't apply — `f_vf_glow`'s
48-tap accumulation is already inherently 1D (along the local field
direction), never had the `d^2` cost problem the chapter solves. But three
of its secondary ideas transfer cleanly and independently of that
algorithm: a dual-curve (broad base + bright spike) glow profile instead
of the current single exponential falloff, alternate step-weight profiles
for ghosting/multi-image character, and after-image temporal feedback
(currently `f_vf_glow` has zero frame-to-frame memory). See
`ideas/glow_profile_and_afterimage.md` for the full writeup (tabled, no
code yet).

**Ch 22 — Color Controls**
Covers the same ground as `f_channel_grader`, `f_tone_curve`, `f_luma_processor`.
Probably mostly familiar, but worth checking for any standard ops we haven't
exposed.
**Read (2026-07-03). Real, well-bounded finding.** `f_channel_grader`'s
lift/gamma/gain model fully covers the chapter's Levels technique (checked
codebox directly — confirmed, not a gap). But `f_tone_curve`, despite its
name, is a 3-band luma-weighted additive lift, not an actual curve — it
cannot express arbitrary shapes the way the chapter's dependent-texture
LUT ("Curves") can. Real gap, module owner wants to pursue it. Revisit
note added to `.specify/f_tone_curve/definition.py`. See
`ideas/lut_curve_and_color_controls.md` for the full writeup (tabled,
architecture not yet decided). Minor aside logged there too: chapter uses
Rec. 709 luma weights, `f_tone_curve`/`f_caustic` use Rec. 601 — not
chased on its own.

**Ch 23 — Depth of Field: A Survey of Techniques**
Relevant to `f_lens`. Our lens module has tilt-shift but not true DOF blur —
this chapter surveys the GPU approaches to it. Future `f_lens` extension
candidate.
**Read (2026-07-03). Surfaced an architecture question, not a code fix.**
Initial pass wrongly concluded `f_lens` had no blur at all (grepped only
the GenExpr codebox, missed `jit.fx.cf.tiltshift` wired downstream as a
separate native-object stage — corrected on the record in the ideas
file). Real finding: tilt-shift is structurally uncoupled from the rest
of `f_lens` (different mechanism, different object, no shared math),
which turned out to be why Matt wasn't reaching for the module in
practice — independently noticed, not something the chapter surfaced.
Chapter's actual contribution here is narrower: its CoC-from-a-scalar
gather-blur idea suggests a content-driven focus-map mode (vs. the
current fixed screen-position gradient band) as a direction for a
possible split-out module. See `ideas/f_lens_tiltshift_split.md` for the
full writeup — open architecture questions (split or not, blur-engine
choice, naming), not yet decided.

**Ch 38 — Fast Fluid Dynamics Simulation on the GPU**
Jos Stam's GPU fluid solver. Direct ancestor of the vecfield family — the
Navier-Stokes pressure/velocity solve is what `f_vf_advect` approximates
loosely. Reading this properly would clarify what we'd need to implement true
fluid advection vs. what we currently do. High priority if we ever want
`f_vf_lic` or a proper fluid module.
**Read (2026-07-03). Confirmation + honest gap + portable finding.**
Checked `f_vf_advect`'s codebox directly: its core (`src_uv = uv -
field*dt`, backward-trace + bilinear sample + decay feedback) is exactly
the chapter's Advection step, correctly implemented, not an
approximation. Real gap: no diffusion or pressure projection (the step
that actually enforces incompressibility) — but both require 20-80
Jacobi iterations per timestep each, plausibly impractical for real-time
multi-module live use, so logged as a deliberate non-goal rather than an
open item. Genuinely portable finding: vorticity confinement
(S:38.5.1) — a cheap, single-pass, standalone force term (no Poisson
solve) that restores swirl detail lost to numerical dissipation. See
`ideas/vorticity_confinement.md` for the full writeup (tabled, standalone
vs. `f_vf_advect`-extension question open).

**Ch 39 — Volume Rendering Techniques**
Less direct, but the ray-marching / accumulation patterns may map to ideas
for depth-composited or layered visual effects. Lower priority, curiosity read.
**Read (2026-07-03). No fit — architectural mismatch, not a per-module
miss.** Entirely 3D-volumetric: real voxel textures, view-aligned proxy
geometry re-tessellated per frame, alpha-composited over/under operators.
`f_` has no 3D voxel data or proxy geometry anywhere in its architecture
(pure 2D `jit.gl.pix` texture chains) — no specific module to check
against, unlike Ch 2/Ch 5 where at least one codebox got checked before
ruling it out. Confirms the backlog's own "lower priority" flag was
right.

**Ch 41 — Real-Time Stereograms** ← ALREADY CITED in f_stereogram spec
Policarpo's strip-based SIRDS algorithm. The source of the `f_stereogram`
multi-pass architecture. Read this before building the 2-strip scratch patch.

**Ch 42 — Deformers**
UV-space deformation techniques. Overlap with `f_droste`, `f_mobius`, and the
general UV-transform family. May contain ideas for new processor modules or
refinements to existing ones.
**Read (2026-07-03). No fit — architectural mismatch, same shape as Ch 39.**
Chapter is about 3D mesh vertex deformation (lattice/wave deform) with its
real technical content being Jacobian-based correction of deformed vertex
*normals* for lighting. "Deformer" superficially resembles a UV-space
warp, but the actual hard problem (normal-vector correction under an
arbitrary vertex-space function) has no analog in `f_droste`/`f_mobius` —
pure 2D UV-space pixel remaps with no vertices, normals, or lighting model
anywhere in the pipeline. The backlog's original framing here was
speculative rather than evidence-backed; this read resolves that.

---

## GPU Gems 2 — chapters of interest

**Ch 8 — Per-Pixel Displacement Mapping with Distance Functions**
Distance functions are the foundation of our mark rendering in `f_vf_seeds`
and the reference architecture for the discrete-item family. This chapter
covers GPU-native distance field techniques that may inform mark AA quality
work — the thing we noted was "rough" with the current smoothstep-only approach.
High priority.
**Read (2026-07-03). No fit — "distance functions" here means something
different from what f_vf_seeds needs.** Chapter is ray-marching a
precomputed 3D distance-map *volume texture* in tangent space, from a
camera view direction, to fake parallax/relief on 3D-textured geometry —
needs a camera, view vector, tangent space, none of which exist in `f_`.
This is NOT the same "distance function" as 2D signed-distance-field
shape antialiasing (that's GPU Gems 3 Ch 25 / Ch 34, later in this list,
already correctly flagged as the real fit for the mark-AA quality
question). The backlog's "high priority" flag here was based on shared
terminology, not shared technique — resolved by this read; don't
re-investigate this chapter for the AA question again, go straight to
Ch 25/34 instead.

**Ch 12 — Tile-Based Texture Mapping**
Stochastic tiling to avoid repetition artifacts. Directly relevant to
`f_grain` and `f_vf_seeds` — how marks/grains tile at scale without obvious
periodicity. May contain ideas for the seed distribution work captured in
`ideas/seed_distribution_beyond_grid.md`.
**Read (2026-07-03). No fit for current mechanism, real supporting
precedent for an already-open idea.** Wang-tile technique (precomputed
edge-matched tile library + index texture, cheap runtime lookup) solves
periodicity in *tiled bitmap patterns* — a problem no current `f_` module
has, since nothing tiles pre-authored bitmaps (everything procedural is
hash-based). Doesn't apply to `f_grain`/`f_vf_seeds`' actual per-cell hash
mechanism. But it's concrete precedent for the "texture-fed point set"
direction already captured in `ideas/seed_distribution_beyond_grid.md` —
added as a cross-reference there rather than a new file, per the
chapter's own finding that precompute+lookup beat in-shader hashing for
their case.

**Ch 15 — Blueprint Rendering and "Sketchy Drawings"**
NPR hatching and line-based rendering. `f_weave` produces output in exactly
this territory — dense directional mark fields. May contain orientation/density
control ideas we haven't considered, and the hatching rendering literature
generally is relevant context for the f_weave orientation A/B work.
**Read (2026-07-03). Split verdict — no fit / real small idea.** Blueprint
Rendering half needs a 3D scene (normal buffer, depth buffer edge
detection) — no fit, same mismatch as Ch 39/42. Sketchy Drawing half's
"uncertainty" concept (non-uniform spatially-varying perturbation of
line/edge parameters for hand-drawn character) doesn't depend on the 3D
half and is directly portable to `f_weave`'s procedural line geometry —
explicitly a separate, additive axis from the already-open orientation
A/B question, not a resolution to it. See
`ideas/sketchy_uncertainty_perturbation.md` for the full writeup (tabled,
generalized beyond f_weave to the discrete-item family).

**Ch 19 — Generic Refraction Simulation**
UV-space warping via a refraction/normal map. Closely related to `f_vf_warp`
and the UV-transform family (`f_droste`, `f_mobius`, `f_lens`). May contain
cleaner formulations or edge-case handling for UV displacement.
**Read (2026-07-03). Strong confirmation + one small portable addition.**
Checked `f_vf_warp`'s codebox directly: its core (sample vecfield, remap
[-1,1], scale by strength, add to UV, sample source) is exactly Sousa's
refraction technique (Listing 19-1) — same algorithm, independently
arrived at, vecfield standing in for their "refraction normal map."
One gap: the chapter's "Refraction Mask" (S:19.2) spatially gates where
the perturbation applies (e.g. confined to a glass object's silhouette);
`f_vf_warp` currently applies its offset uniformly wherever the vecfield
is nonzero, all-or-nothing via the connected-gate only. A mask inlet
(same idiom as `f_lens`/`f_vf_prism`'s mod-texture inlets) would add this
cheaply. Revisit note added to `.specify/f_vf_warp/definition.py`; not
significant enough to warrant its own `ideas/` file given `f_vf_warp` is
stable/working and this is one small, well-scoped addition, not an open
question.

**Ch 22 — Fast Prefiltered Lines**
Antialiased GPU line rendering. `f_weave` renders lines (`dist_to_line`
smoothstep gates) — this chapter covers the filtering problem for lines
specifically, which is exactly the mark quality question for that module.
**Read (2026-07-03). No fit for the chapter's actual machinery, but a
more precise real finding underneath.** The rasterizer-pipeline
machinery (CPU edge-function setup, conservative line rasterization, 1D
LUT texture) has no landing spot — `f_weave` has no line primitives,
just an analytic per-pixel distance to a periodic pattern. But checking
`f_weave`'s codebox directly reframed the original vague "mark quality
is rough" note into something sharper: the module's `smoothstep` edge
width is fixed in UV space and does not scale with `density_scale`,
which is exactly the scale-invariance failure the chapter's Sampling
Theorem section explains — aliasing should get worse as `density`
increases, independent of falloff shape. Whether GenExpr exposes
screen-space derivatives to fix this properly is unverified. Secondary,
smaller idea: swap the fixed smoothstep for a Gaussian-like profile
(filter-shape-only, doesn't touch the aliasing question). See
`ideas/line_edge_antialiasing.md` for the full writeup (tabled, two open
sub-questions, one flagged UNVERIFIED). `f_masonry`'s mortar lines use
the same `smoothstep` idiom — noted as a likely secondary candidate, not
checked in detail.

**Ch 24 — Using Lookup Tables to Accelerate Color Transformations**
LUT-based color ops. Relevant to `f_tone_curve`, `f_channel_grader`. Also
potentially interesting as an architecture pattern for the hue-selective
work in `f_hue_processor`. Probably mostly familiar territory but worth a scan.
**Read (2026-07-03). Extends the already-open Ch 22 (Vol 1) LUT-curve
thread — not a separate finding.** The chapter's 1D LUT section just
reconfirms the per-channel dependent-texture-read curve idea already
tabled in `ideas/lut_curve_and_color_controls.md`. What's genuinely new
is the 3D LUT (whole-RGB-triple dependent read) — a strictly more
powerful generalization that could in principle express cross-channel
ops (hue/saturation grades) no 1D curve can reach. Real blocker,
unverified: whether GenExpr/`jit.gl.pix` can sample a 3D texture at all
— no existing `f_` module uses one. Appended as an addendum to the
existing file rather than opening a new one; treated as a further-out
"maybe" behind the near-term 1D curve work, not a competing priority.

**Ch 26 — Implementing Improved Perlin Noise** *(also in Vol 1, Ch 5)*
Appears in both volumes — clearly important. Perlin himself in Vol 1, GPU
implementation details here. Our jit.gen `noise()` prohibition forces hash
alternatives; this chapter may suggest approaches closer to the real thing.
**Read (2026-07-03). No fit — same conclusion as Vol 1 Ch 5, this is the
GPU-implementation companion piece, not new territory.** Green's chapter
is a faithful GPU port of Perlin's same smooth/correlated gradient-noise
algorithm (permutation-table + gradient-table texture lookups, 5th-order
Hermite fade curve, trilinear interpolation across 8 cube corners) —
solves for the same "band-limited, smooth, no obvious repeats" noise
category already ruled out as a non-match for `f_`'s deliberately
uncorrelated per-cell hash. Nothing here changes that verdict; where
true smooth noise is needed, `vs_noise_3` remains the answer, not a
hand-rolled permutation-texture shader. No new `ideas/` content —
Vol 1 Ch 5's reasoning covers this chapter too.

**Ch 40 — Computer Vision on the GPU**
GPU-based optical flow and image analysis. Directly relevant to the video
→ optical flow → vecfield pipeline that Matt uses with `f_weave` and the
vf_ family. May inform a future `f_vf_optflow` producer module, or just
improve understanding of the upstream signal we're consuming.
**Read (2026-07-03). No fit — backlog's framing was wrong, and the real
content is architecturally mismatched anyway.** This chapter does not
actually implement optical flow — Horn & Schunk 1981 appears only in the
references list, never built or discussed in the body. The chapter's
real content (radial-distortion correction, Canny edge detection,
CPU-readback summation for image moments/centroids, VideoOrbits'
**Ax**=**b** linear-system solve via GPU-sum-then-CPU-readback, feature-
vector histograms via one-vertex-per-feature rendering) is all built
around a fundamentally different pipeline shape than `f_`: multi-pass
render-to-texture with CPU readback between stages, non-uniform
per-feature vertex layouts — not a single forward `jit.gl.pix` chain
with no CPU round-trip. One incidental overlap, not chased: the radial
barrel-distortion formula (`k1*r² + k2*r⁴`) is the same standard
Brown-Conrady model `f_lens`'s existing `distortion` param almost
certainly already implements (confirmed the param exists via grep, did
not diff the formulas) — not a new idea, just a "yes, that's the
standard one" confirmation. If a real optical-flow producer module
(`f_vf_optflow`) is wanted later, this chapter isn't the source to
revisit — Horn-Schunck's actual paper, or a more current GPU
optical-flow technique, would be.

**Ch 47 — Flow Simulation with Complex Boundaries**
GPU fluid simulation with obstacle boundaries. Complements Gem 1 Ch 38
(Stam's fluid solver). The "complex boundaries" angle is specifically
interesting for `f_vf_repulse` and any future obstacle-aware field generator.
**Read (2026-07-03). No fit — architectural mismatch, heavier version of
the same gap already logged against Vol 1 Ch 38.** This isn't a
Navier-Stokes solver at all — it's the Lattice Boltzmann Method, a full
3D D3Q19 lattice (19 packet-distribution channels per node, packed
across 5 RGBA textures) with GPU-based depth-peel voxelization of
arbitrary moving/deforming boundary geometry and a vertex-array-based
curved-boundary bounce-back rule. Real 3D geometry, real voxels, real
multi-pass depth-peeling render — the same "no 3D data/proxy geometry
anywhere in `f_`'s architecture" mismatch already established for Vol 1
Ch 2/39/42, just for a heavier simulation method than Stam's solver
(which Vol 1 Ch 38 already confirmed `f_vf_advect` correctly implements
a lightweight version of, minus the expensive incompressibility solve).
"Complex boundaries" here specifically means arbitrary 3D obstacle
meshes that must be voxelized every frame — there's no 2D-texture-driven
equivalent to borrow for `f_vf_repulse`, which already gets its
obstacle-like behavior from a completely different, much cheaper
mechanism (luma-thresholded texture-driven ring accumulation, no
lattice, no voxelization). No new `ideas/` content.

---

## GPU Gems 3 — chapters of interest

**Ch 7 — Point-Based Visualization of Metaballs on a GPU**
Point/splat-based rendering on the GPU. `f_vf_seeds` is fundamentally a
point/mark placement engine — this chapter may contain ideas about per-point
rendering, splatting, and density that apply to the seeds family. Also
tangentially relevant to the seed distribution work.
**Read (2026-07-03). No fit — architectural mismatch, deeper than it first
looks.** This is a full 3D SPH surface-particle simulation: CPU-side fluid
atom simulation feeding a GPU visualization loop, spatial-hash neighbor
queries via multi-pass render-to-texture, particle repulsion and "global
dispersion" (moving particles from crowded to sparse regions) all
requiring persistent per-particle GPU state across passes. None of this
exists in `f_`'s architecture. The one conceptually adjacent idea —
"global particle dispersion" — is already the same problem
`ideas/seed_distribution_beyond_grid.md` tables under Poisson-disk-style
approaches, but not portable without persistent-particle-state
architecture `f_vf_seeds` doesn't have. Cross-referenced there.

**Ch 13 — Volumetric Light Scattering as a Post-Process**
Ray-march accumulation along view rays for god-ray / light shaft effects.
The accumulation pattern is closely related to `f_caustic` and `f_vf_streak`
/ `f_vf_glow` — integrating along a path, weighted by some field quantity.
Worth reading for the accumulation math specifically.
**Read (2026-07-03). Real finding — a composition, not a code gap.** The
technique is a pure 2D post-process: radial accumulation from a fixed
screen point with exponential decay, sampling the source image's own
brightness along the path — structurally identical to what
`f_vf_glow`/`f_vf_streak` already do, just radial-from-point instead of
an arbitrary vecfield. `f_vf_vortex` with `curl=0` and outward
`convergence` already produces exactly this field. Composing
`f_vf_vortex` → `f_vf_streak`/`f_vf_glow` should produce a god-ray effect
with zero new code — same category as GPU Gems 2 Ch. 19's `f_vf_warp`
confirmation. See `ideas/godray_radial_accumulation.md` (tabled, untested).

**Ch 16 — Vegetation Procedural Animation and Shading in Crysis**
Field-driven procedural animation of vegetation. Wind as a vecfield driving
per-element orientation and displacement — this is conceptually the same
problem as `f_weave` orientation response to a vecfield. May have worked
solutions to the "feels uncontrolled" problem Matt identified.
**Read (2026-07-03). No fit — different domain than it first looks.**
3D vertex-shader mesh displacement (per-vertex sine-wave bending driven
by wind scalars, artist-painted stiffness/phase maps). No analog to
`f_weave`'s per-pixel analytic line-distance orientation math — no
vertices, no mesh. Doesn't inform the open orientation-blend question
(vector-add vs. true angular blend), which is a 2D field-composition
problem this chapter never touches.

**Ch 18 — Relaxed Cone Stepping for Relief Mapping**
Iterative UV-space displacement via cone stepping. A more sophisticated
version of the UV-warp problem — relevant to `f_vf_warp` and potentially
`f_droste`. The "relaxed" approach handles performance/quality tradeoff in
ways that might apply to our warp accumulation.
**Read (2026-07-03). No fit — same mismatch as GPU Gems 2 Ch. 8, confirmed
again.** Ray-heightfield intersection for parallax/relief mapping needs a
camera view direction and tangent space — neither exists in `f_`'s flat
2D UV-remap pipeline. Same "distance function" terminology trap already
resolved for GPU Gems 2 Ch. 8.

**Ch 25 — Rendering Vector Art on the GPU**
Distance-field–based resolution-independent shape rendering on the GPU.
This is highly relevant to mark quality in `f_vf_seeds` — the smoothstep-
only AA we flagged as "rough" is essentially the naive version of what this
chapter properly solves. High priority read before tackling mark AA work.
**Read (2026-07-03). Real finding — the actual AA recipe, not the
triangulation machinery.** The Bezier-triangulation core needs mesh
triangles — no fit for a per-pixel GenExpr codebox. But Section 25.5
(Antialiasing) gives the exact generalizable formula the already-open
`line_edge_antialiasing.md` blocker was waiting on:
`sd = f(x,y) / length(ddx(f), ddy(f))`, then `alpha = 0.5 - sd` —
screen-space-derivative-based analytic AA for *any* implicit function.
Directly answers the scale-invariance failure already diagnosed in
`f_weave`. **Still UNVERIFIED, same blocker as before, now with a
confirmed target formula:** does GenExpr expose `ddx()`/`ddy()` or
equivalent? See `line_edge_antialiasing.md` addendum (that file was
referenced as already existing in HANDOFF but was missing from disk —
recreated this session, flagged as a discrepancy worth a broader sanity
check).

**Ch 27 — Motion Blur as a Post-Processing Effect**
Directional blur along motion vectors. Closely related to `f_vf_streak` —
both accumulate samples along a direction field. May have filtering or
accumulation ideas we haven't used, particularly around velocity-adaptive
sample counts.
**Read (2026-07-03). No fit for velocity derivation, confirms existing
accumulation pattern.** The chapter derives per-pixel velocity from the
depth buffer plus camera matrices — no analog in `f_`. The blur-along-
velocity accumulation loop itself is exactly what `f_vf_streak` already
does, sourcing direction from an externally-supplied vecfield instead of
reconstructed camera motion. Pure confirmation, no new capability.

**Ch 28 — Practical Post-Process Depth of Field**
GPU DOF as a post-process. Relevant to `f_lens` DOF extension (flagged in
Vol 1 Ch 23 note above). Vol 3 Ch 28 is likely more practical/implementable
than the Vol 1 survey — read this one if actually building DOF for `f_lens`.
**Read (2026-07-03). Real finding — the practical algorithm Vol 1 Ch. 23
pointed toward.** Confirms the "content-driven focus map" idea already
tabled in `f_lens_tiltshift_split.md` and supplies the concrete recipe: a
per-pixel scalar circle-of-confusion map drives a variable-width gather
blur, agnostic to whether that scalar comes from a depth buffer or
anywhere else. Portable piece: the foreground-bleed fix
(`D = 2*max(D0, DB) - D0`, blurring the CoC map itself first) softens
depth-discontinuity artifacts cheaply. See `f_lens_tiltshift_split.md`
addendum.

**Ch 30 — Real-Time Simulation and Rendering of 3D Fluids**
Full 3D fluid sim and rendering on the GPU. Extends the 2D fluid work from
Vol 1 Ch 38 into 3D. Relevant if we ever want a proper fluid-sim–backed
vecfield producer (beyond what `f_vf_advect` approximates).
**Read (2026-07-03). No fit — heavier version of the already-covered 3D
gap.** Full 3D Navier-Stokes solver (3D volume textures, view-aligned
slice rendering) — same "no 3D voxel data anywhere in `f_`" mismatch
already established for Vol 1 Ch 38/Ch 2/39/42 and GPU Gems 2 Ch. 47.

**Ch 34 — Signed Distance Fields Using Single-Pass GPU Scan Conversion**
SDF generation on the GPU in a single pass. SDFs are the right substrate
for high-quality mark rendering in `f_vf_seeds` (and potentially `f_grain`
and `f_weave`). This is the generation side; Ch 25 covers the rendering side.
Together these two chapters frame the proper SDF-based mark pipeline.
**Read (2026-07-03). No fit — backlog's pairing with Ch 25 was
optimistic, corrected here.** This chapter generates a *volumetric 3D*
SDF from a *polygonal 3D mesh* via tetrahedra scan-conversion — a
different problem than what `f_vf_seeds` needs. `f_`'s shapes are 2D and
procedural/analytic, not polygonal meshes, so there's nothing to
scan-convert — the correct approach is writing closed-form distance
functions directly in GenExpr (Quilez's articles). Ch 25 doesn't need
this chapter as a prerequisite for 2D work.

**Ch 37 — Efficient Random Number Generation and Application Using CUDA**
GPU-native RNG. Our arithmetic hash approach in jit.gen is a pragmatic
workaround — this chapter covers proper GPU RNG, which may suggest better
hash quality or distribution for `f_grain`'s stochastic placement and
`f_vf_seeds`' jitter.
**Read (2026-07-03). No fit — different problem shape than what `f_`
needs, same category as the Perlin noise chapters.** Solves generating
long *sequential streams* of random draws per CUDA thread for Monte Carlo
methods. `f_`'s hash approach is the opposite shape: stateless positional
hashing, no sequential state. Also requires integer bitwise ops GenExpr's
float-only arithmetic likely can't express cleanly (not confirmed).

**Ch 40 — Incremental Computation of the Gaussian**
Efficient incremental Gaussian filter computation. Directly relevant to
the Gaussian blur in `f_vf_prism` (11-tap) and `f_vf_glow`. The incremental
approach may be more efficient than our fixed tap count for variable-radius
blurs.
**Read (2026-07-03). Real, small finding.** A forward-differencing
recurrence replaces the per-tap `exp()` call in a fixed-step Gaussian
loop with one multiply per step. Directly applicable to `f_vf_glow`'s
48-tap loop and `f_vf_prism`'s 11-tap blur. **UNVERIFIED:** whether this
tradeoff is even meaningful inside GenExpr/`jit.gl.pix` — not profiled.
See `ideas/incremental_gaussian_taps.md` (tabled, low priority).

---

## Related resources — further reading

**ShaderX → GPU Pro → GPU Zen series** (Wolfgang Engel, ed.)
The direct successor to GPU Gems. Same format: practitioner-written technique
chapters covering advanced GPU rendering. ShaderX ran 7 volumes (2002–2008),
GPU Pro 7 more (2010–2016), GPU Zen is the current series (ongoing — GPU Zen 4
recently published, GPU Zen 5 in progress). More game-industry/API-specific than
GPU Gems but technique chapters transfer. Early ShaderX volumes free online:
https://www.realtimerendering.com/resources/shaderx/

**Real-Time Rendering, 4th ed.** (Akenine-Möller, Haines, Hoffman — 2018)
The field's canonical reference text. ~1200 pages, comprehensive survey with
deep bibliography. Not a recipe collection — most useful as a theoretical
foundation when you need to understand *why* something works. Companion site
with extensive free resources: https://www.realtimerendering.com

**Iñigo Quilez — iquilezles.org** ← highest priority for our work
Hundreds of articles on SDFs, distance functions, procedural noise, domain
distortion, smooth blending operators, voronoi, and more. Fragment-shader-
native, math-first, procedural — exactly how we work in jit.gen. The SDF shape
library is directly applicable to mark quality work in f_vf_seeds. Also
co-founded Shadertoy; his shaders there are a live, searchable technique library.
https://iquilezles.org/articles/

---

## How to use this

- Read chapters before building modules in overlapping territory — avoid
  reinventing wheels or missing known-good algorithms
- Use as an idea source when a module feels "stuck" — there may be a published
  GPU technique that reframes the problem
- Cross-reference with current `ideas/` files when a chapter suggests a new
  module or extension

### Per-chapter working pattern (established 2026-07-03, via Ch 20)

1. **Read the chapter** for its actual mechanism, not just this backlog's
   one-paragraph guess at relevance.
2. **Read the real code** of whichever module(s) the entry flags as
   overlapping — via Desktop Commander, not from memory of what the module
   probably does. If there's no single obvious module (more foundational
   chapters — Perlin noise, fluid dynamics — touch a whole family rather
   than one patch), compare against the family instead of forcing a
   single-module fit.
3. **Discuss whether the chapter's framing actually matches what the code
   does today.** This is the step that matters most — it's where a vague
   "could apply this" hunch either turns into something real and more
   precise than the original guess, or turns out not to fit. Don't skip to
   capturing notes before this comparison happens.
4. **Stay in discussion — no code, no scratch patch** — until the shape of
   an idea is real enough to be worth tabling or acting on.
5. **If something real surfaces, capture it as its own `ideas/` file**
   (tabled or actionable, whichever it is honestly).
6. **Cross-reference both directions** — a pointer from this backlog entry
   to the new file, and the new file references back here — then mark the
   chapter entry **Read (date)** with a one-line summary of the finding.

## Attribution practice

Any technique drawn from this literature — whether used directly, adapted, or
just used as inspiration for the architecture — should be:

1. **Noted in session** when it influences a design decision, so the connection
   isn't lost between reading and building
2. **Cited in the module's helpfile** with enough specificity that someone could
   find the source: author, title, chapter/article, URL if available. The goal
   is to make good-faith claims about what we learned and where, and to give
   anyone reading the helpfile a path to the original material.
3. **Credited honestly** — if we adapted something substantially, say so; if we
   used an algorithm directly, say that too. The distinction matters.

Template for a helpfile citation:
```
Algorithm based on: Policarpo, "Real-Time Stereograms," GPU Gems Ch. 41 (2004)
https://developer.nvidia.com/gpugems/gpugems/part-vi-beyond-triangles/chapter-41-real-time-stereograms
```
