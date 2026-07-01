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

**Ch 5 — Implementing Improved Perlin Noise**
Ken Perlin himself. We work around the jit.gen `noise()` prohibition with
arithmetic hashes — this chapter may contain alternative hash/lattice ideas
worth borrowing or adapting. Also relevant to any future procedural generator.

**Ch 8 — Simulating Diffraction**
Iridescence / thin-film interference. Natural companion to `f_vf_prism` and
`f_lens` chromatic aberration. Could inspire a dedicated optical-interference
module or extend the prism's color synthesis.

**Ch 20 — Texture Bombing**
Stochastic mark placement via random offsets into a tile. This is essentially
the problem `f_grain` and `f_vf_seeds` solve. May contain ideas about
neighborhood search, overlap handling, or mark distribution we haven't seen.
High priority read — closest chapter to our core discrete-item family work.

**Ch 21 — Real-Time Glow**
Direct overlap with `f_vf_glow`. May have filtering or accumulation ideas
beyond what we implemented. Worth a quick scan for anything we missed.

**Ch 22 — Color Controls**
Covers the same ground as `f_channel_grader`, `f_tone_curve`, `f_luma_processor`.
Probably mostly familiar, but worth checking for any standard ops we haven't
exposed.

**Ch 23 — Depth of Field: A Survey of Techniques**
Relevant to `f_lens`. Our lens module has tilt-shift but not true DOF blur —
this chapter surveys the GPU approaches to it. Future `f_lens` extension
candidate.

**Ch 38 — Fast Fluid Dynamics Simulation on the GPU**
Jos Stam's GPU fluid solver. Direct ancestor of the vecfield family — the
Navier-Stokes pressure/velocity solve is what `f_vf_advect` approximates
loosely. Reading this properly would clarify what we'd need to implement true
fluid advection vs. what we currently do. High priority if we ever want
`f_vf_lic` or a proper fluid module.

**Ch 39 — Volume Rendering Techniques**
Less direct, but the ray-marching / accumulation patterns may map to ideas
for depth-composited or layered visual effects. Lower priority, curiosity read.

**Ch 41 — Real-Time Stereograms** ← ALREADY CITED in f_stereogram spec
Policarpo's strip-based SIRDS algorithm. The source of the `f_stereogram`
multi-pass architecture. Read this before building the 2-strip scratch patch.

**Ch 42 — Deformers**
UV-space deformation techniques. Overlap with `f_droste`, `f_mobius`, and the
general UV-transform family. May contain ideas for new processor modules or
refinements to existing ones.

---

## GPU Gems 2 — chapters of interest

**Ch 8 — Per-Pixel Displacement Mapping with Distance Functions**
Distance functions are the foundation of our mark rendering in `f_vf_seeds`
and the reference architecture for the discrete-item family. This chapter
covers GPU-native distance field techniques that may inform mark AA quality
work — the thing we noted was "rough" with the current smoothstep-only approach.
High priority.

**Ch 12 — Tile-Based Texture Mapping**
Stochastic tiling to avoid repetition artifacts. Directly relevant to
`f_grain` and `f_vf_seeds` — how marks/grains tile at scale without obvious
periodicity. May contain ideas for the seed distribution work captured in
`ideas/seed_distribution_beyond_grid.md`.

**Ch 15 — Blueprint Rendering and "Sketchy Drawings"**
NPR hatching and line-based rendering. `f_weave` produces output in exactly
this territory — dense directional mark fields. May contain orientation/density
control ideas we haven't considered, and the hatching rendering literature
generally is relevant context for the f_weave orientation A/B work.

**Ch 19 — Generic Refraction Simulation**
UV-space warping via a refraction/normal map. Closely related to `f_vf_warp`
and the UV-transform family (`f_droste`, `f_mobius`, `f_lens`). May contain
cleaner formulations or edge-case handling for UV displacement.

**Ch 22 — Fast Prefiltered Lines**
Antialiased GPU line rendering. `f_weave` renders lines (`dist_to_line`
smoothstep gates) — this chapter covers the filtering problem for lines
specifically, which is exactly the mark quality question for that module.

**Ch 24 — Using Lookup Tables to Accelerate Color Transformations**
LUT-based color ops. Relevant to `f_tone_curve`, `f_channel_grader`. Also
potentially interesting as an architecture pattern for the hue-selective
work in `f_hue_processor`. Probably mostly familiar territory but worth a scan.

**Ch 26 — Implementing Improved Perlin Noise** *(also in Vol 1, Ch 5)*
Appears in both volumes — clearly important. Perlin himself in Vol 1, GPU
implementation details here. Our jit.gen `noise()` prohibition forces hash
alternatives; this chapter may suggest approaches closer to the real thing.

**Ch 40 — Computer Vision on the GPU**
GPU-based optical flow and image analysis. Directly relevant to the video
→ optical flow → vecfield pipeline that Matt uses with `f_weave` and the
vf_ family. May inform a future `f_vf_optflow` producer module, or just
improve understanding of the upstream signal we're consuming.

**Ch 47 — Flow Simulation with Complex Boundaries**
GPU fluid simulation with obstacle boundaries. Complements Gem 1 Ch 38
(Stam's fluid solver). The "complex boundaries" angle is specifically
interesting for `f_vf_repulse` and any future obstacle-aware field generator.

---

## GPU Gems 3 — chapters of interest

**Ch 7 — Point-Based Visualization of Metaballs on a GPU**
Point/splat-based rendering on the GPU. `f_vf_seeds` is fundamentally a
point/mark placement engine — this chapter may contain ideas about per-point
rendering, splatting, and density that apply to the seeds family. Also
tangentially relevant to the seed distribution work.

**Ch 13 — Volumetric Light Scattering as a Post-Process**
Ray-march accumulation along view rays for god-ray / light shaft effects.
The accumulation pattern is closely related to `f_caustic` and `f_vf_streak`
/ `f_vf_glow` — integrating along a path, weighted by some field quantity.
Worth reading for the accumulation math specifically.

**Ch 16 — Vegetation Procedural Animation and Shading in Crysis**
Field-driven procedural animation of vegetation. Wind as a vecfield driving
per-element orientation and displacement — this is conceptually the same
problem as `f_weave` orientation response to a vecfield. May have worked
solutions to the "feels uncontrolled" problem Matt identified.

**Ch 18 — Relaxed Cone Stepping for Relief Mapping**
Iterative UV-space displacement via cone stepping. A more sophisticated
version of the UV-warp problem — relevant to `f_vf_warp` and potentially
`f_droste`. The "relaxed" approach handles performance/quality tradeoff in
ways that might apply to our warp accumulation.

**Ch 25 — Rendering Vector Art on the GPU**
Distance-field–based resolution-independent shape rendering on the GPU.
This is highly relevant to mark quality in `f_vf_seeds` — the smoothstep-
only AA we flagged as "rough" is essentially the naive version of what this
chapter properly solves. High priority read before tackling mark AA work.

**Ch 27 — Motion Blur as a Post-Processing Effect**
Directional blur along motion vectors. Closely related to `f_vf_streak` —
both accumulate samples along a direction field. May have filtering or
accumulation ideas we haven't used, particularly around velocity-adaptive
sample counts.

**Ch 28 — Practical Post-Process Depth of Field**
GPU DOF as a post-process. Relevant to `f_lens` DOF extension (flagged in
Vol 1 Ch 23 note above). Vol 3 Ch 28 is likely more practical/implementable
than the Vol 1 survey — read this one if actually building DOF for `f_lens`.

**Ch 30 — Real-Time Simulation and Rendering of 3D Fluids**
Full 3D fluid sim and rendering on the GPU. Extends the 2D fluid work from
Vol 1 Ch 38 into 3D. Relevant if we ever want a proper fluid-sim–backed
vecfield producer (beyond what `f_vf_advect` approximates).

**Ch 34 — Signed Distance Fields Using Single-Pass GPU Scan Conversion**
SDF generation on the GPU in a single pass. SDFs are the right substrate
for high-quality mark rendering in `f_vf_seeds` (and potentially `f_grain`
and `f_weave`). This is the generation side; Ch 25 covers the rendering side.
Together these two chapters frame the proper SDF-based mark pipeline.

**Ch 37 — Efficient Random Number Generation and Application Using CUDA**
GPU-native RNG. Our arithmetic hash approach in jit.gen is a pragmatic
workaround — this chapter covers proper GPU RNG, which may suggest better
hash quality or distribution for `f_grain`'s stochastic placement and
`f_vf_seeds`' jitter.

**Ch 40 — Incremental Computation of the Gaussian**
Efficient incremental Gaussian filter computation. Directly relevant to
the Gaussian blur in `f_vf_prism` (11-tap) and `f_vf_glow`. The incremental
approach may be more efficient than our fixed tap count for variable-radius
blurs.

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
