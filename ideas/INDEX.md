# Ideas Index

_Created: 2026-09-17; last brought current 2026-10-18 (75 notes plus one parked
script)._ A refresher map of `ideas/` so you don't have
to reread everything to remember where a thread stands. Grouped by theme, not
date. Each entry: one-line gist + status. When a file's own status line is
more precise than what's here, trust the file — this index is a pointer, not
a replacement.

**Status shorthand:** 🟢 built/shipped · 🟡 specced or scratch-verified,
mid-build · ⚪ concept only, not started · 🔵 research/analysis note, not a
module proposal · 🧰 process/infrastructure/convention

Maintenance note: this index isn't auto-generated. When you add, retire, or
substantially move a file in `ideas/`, update its entry here too.

---

## Active right now

- **[f_tensorfield.md](f_tensorfield.md)** 🟡 — The tensor family hub (details under
  Vector field family below). Seven `f_tf_` modules built and bench-verified; the open
  items are tier-3 live-feel gates and Q16/Q17.
- **[f_a_spectral_ripple.md](f_a_spectral_ripple.md)** 🟡 — Cross-frequency
  de-correlating tinnitus stimulus generator (Yukhnovich et al. 2025). T1–T7
  verified; shipped as `package/patchers/f_a_ripple.maxpat` and, as the `pfft~`
  processor `f_a_decorrelate` (2026-10-12, at the `f_a_ripple` packaging bar; PM
  un-scoped for v1, ADR-4). Both are still ⚠ in the README. Open: UI to `f_`
  convention, docs/helpfile, `f_a_ripple` T002 (checkhearing comparison), T8.
- **[f_a_build_process.md](f_a_build_process.md)** ⚪ — Can `build_patcher.py` extend
  to `f_a_` (audio) modules, or does audio need its own builder? Analysis done
  (UI-grid half reusable, `gen_subpatcher`/`pix_box` half is not). **The wider
  audio-integration question was TABLED 2026-10-18** (HANDOFF): options are a
  hand-built sibling family made official, an audio archetype in the builder, or
  control-rate bridge modules only (lean: first + third, defer the second). Three
  questions to Matt unanswered. Small items that don't wait on it: how the module
  bench treats `f_a_*` (since decided: XFAIL), and the README "unfinished" marker
  vs `f_a_decorrelate`'s spec saying "complete".

## Audio modules (`f_a_` prefix)

- **[f_a_purr.md](f_a_purr.md)** 🟡 — Fully parametric cat-purr synthesis
  (glottal click → pulse train → breath cycle → resonance → behavioral
  scheduler, 6 layers). Layers 0–2/4 + resonator verified in scratch. Q2, Q4,
  Q6, Q7 still open; the build-pipeline gate (T026) is held with the tabled
  audio-integration question. First `f_a_` module; established the prefix.
- **[f_a_breath_phase.md](f_a_breath_phase.md)** ⚪ — Input utility: read
  wearer's breathing (contact mic/piezo, plain `adc~`, no MIDI bridge needed)
  and drive a downstream generator's phase directly. Pure ideation, no signal
  chain built.
- **[f_a_spectral_ripple.md](f_a_spectral_ripple.md)** — see Active above.
- **[f_a_build_process.md](f_a_build_process.md)** — see Active above.

## Vector field family (`f_vf_*`, `f_vecfield`)

- **[vector_field_math_concepts.md](vector_field_math_concepts.md)** 🔵 —
  Concepts pulled from re-reads of the Wikipedia vector-field and tensor-field
  articles, each paired with where it might cash out in `f_`: singularity
  index as an explicit control (ties to Poincaré–Hopf/hairy-ball on the
  circular-screen domain), central fields as their own simple generator mode,
  Helmholtz gradient/curl decomposition, streamline vs. pathline vs.
  streakline as a user-facing toggle (reframes `f_vf_smear`'s LIC candidate),
  the Lie bracket as a zero-build composition experiment, whether UV warpers
  (`f_droste`/`f_mobius`/`f_poincare`) transform a piped-through vecfield
  correctly or just resample it (possible latent bug, cheap to check),
  conservative-field path-independence as a free NumPy correctness test,
  deliberate finite-time blow-up as a design axis, tensor fields
  (glyph/ellipse visualization, unoriented line fields, anisotropic
  structure-aware blur, photoelastic stress-fringe optics) as the next rung
  up from vector fields, Tissot's indicatrix as a distortion diagnostic for
  the UV warpers, the Jacobian determinant as adaptive anti-aliasing
  (possible way around `line_edge_antialiasing.md`'s GenExpr-derivatives
  block), the covariant derivative as a correctness warning for
  `f_sharmonics`/circular-screen gradient work, and authoring UV distortion
  from a metric tensor instead of a closed-form transform. Research notes,
  not specs — cross-reference before building any of them.
- **[f_vecfield.md](f_vecfield.md)** 🟢 — The family's type contract (float32,
  RG=XY, 0.5=zero) and roadmap hub. The roadmap
  sections predate most of the build-out: since then `f_vf_flow`, `f_vf_fluid`,
  `f_vf_repulse`, `f_vf_optical_flow` (sources) and `f_vf_glow`, `f_vf_advect`,
  `f_vf_prism`, `f_vf_potential`, `f_vf_split` (consumers) joined the originals
  (`f_vf_vortex(_multi)`, `f_vf_fieldmap`, `f_caustic`, `f_vf_warp`, `f_vf_streak`).
  The README Patches table is the current module list; `f_vf_chroma` and
  `f_vf_vorticity` are paused.
- **[f_tensorfield.md](f_tensorfield.md)** 🟡 — Tensor field family hub (sibling to
  `f_vecfield.md`): status of the seven built `f_tf_` modules, decisions, live open
  questions (Q12-Q17) and the vecfield-consumer audit. The active working doc.
- **[f_tf_backlog.md](f_tf_backlog.md)** 🟡 — The tensor family's unbuilt candidates (mix,
  glint, jacobian, motion, hessian, authored, metric, ...) with entry conditions, v2 ideas
  for built modules, and what chains A-D still miss.
- **[f_tf_research.md](f_tf_research.md)** ⚪ — Stable evidence for the tensor family: the
  tensor-native test, prior art, the jit.fx platform audit, kuwahara, and GPU/decode facts
  from the builds.
- **[f_vf_seeds.md](f_vf_seeds.md)** 🟢 — Built. Discrete-item generator: marks at
  hash-stable seed points, oriented by an incoming vecfield (wind-barb/ink
  look). Reference implementation for the discrete-item family's inlet
  architecture and "identity coordinate" output. Evolution 3 (color-driving
  texture, which absorbed `f_dither_grain`) shipped; the idea note is the
  original capture.
- **[f_vf_mix.md](f_vf_mix.md)** ⚪ — Infrastructure: blend two vecfields
  (additive / crossfade) before a consumer. Not built; build when a real
  chain needs it.
- **[f_vf_channelmap.md](f_vf_channelmap.md)** ⚪ — Reinterpret any two
  texture channels directly as vecfield XY (no gradient math) — inverse of
  `f_vf_split`. Supersedes and absorbs the deleted `f_vf_normal.md`.
- **[f_vf_optical_flow.md](f_vf_optical_flow.md)** 🟢 — Derive a vecfield from
  motion between frames. Built as Lucas-Kanade (confidence-gated, aperture-problem
  fill, two outlets). The note is the pre-build idea plus the record of the cheap
  frame-diff approximation being **tested and ruled out** (2026-07-17, structural
  reason: gradient-of-a-trail points the wrong way, not a tuning problem).
- **[f_vf_smear.md](f_vf_smear.md)** ⚪ — True continuous streamline blur
  (fixes the visible discrete-sample banding in `f_vf_streak` at long
  lengths). LIC single-pass or multipass-iterative; LIC flagged as the
  cheaper first prototype.
- **[f_vf_temporal_smooth.md](f_vf_temporal_smooth.md)** ⚪ — Parked:
  frame-to-frame inertia/lag applied to any vecfield (one-pole lowpass, but
  per-vector). Deliberately spun out of `f_vf_advect` rather than becoming its
  3rd outlet. (Its tensor-side sibling `f_tf_smooth` is built.)
- **[f_vf_emulsion.md](f_vf_emulsion.md)** ⚪ — Surfaced 2026-09-29: two materials
  (oil and smoke) in one flow, sharpened to "what happens when they collide and
  begin to mix" as a vecfield problem rather than image compositing. Would be a
  **fork of `f_vf_fluid`**, not a v2: the solver's parameters live in real space
  (`force`, `dt`, `gain`, cheap to vary per pixel) and in the spectral stage
  (structural). Idea only, not specced, not named.
- **[f_vf_wilson_cowan.md](f_vf_wilson_cowan.md)** ⚪ — Vecfield producer from
  the Wilson-Cowan neural-mass model (E/I reaction-diffusion) — targets the
  classic funnel/spiral/lattice/cobweb hallucination-form taxonomy
  (Ermentrout-Cowan). Needs `jit.gl.node @capture 1` self-recursion, not a
  stateless pix chain.
- **[f_weave_orientation_blend.md](f_weave_orientation_blend.md)** 🟢 — **RESOLVED
  2026-10-13: ship both.** `f_weave`'s vecfield-driven orientation used vector-add +
  renormalize (non-proportional response); the true angular blend via `atan2` (GPU
  safety verified 2026-10-12) is now one end of a performable `fix_blend` crossfade,
  with `field_amount` setting depth. Both dials are live in `src/f_weave/definition.py`.
- **[dry_wet_gain_and_novel_field_outlet.md](dry_wet_gain_and_novel_field_outlet.md)**
  🧰 — Design discussion (no module chosen yet): reframe additive-layer
  modules (`f_vf_glow/chroma/prism/streak`, `f_caustic`) with separate `gain`
  (can exceed 1.0) + `mix` (0–100% crossfade) controls, vs. the true
  replacement-shape modules (`f_mobius/droste/lens/warp`) which already map
  cleanly to `mix(src, processed, wet)`. "Add a vecfield 3rd outlet" idea
  scoped but unresolved. The gain/mix rollout is per-module and still open in
  places: `f_grain` closed the question 2026-10-09 (T003); `f_vf_warp` T052 asks the
  same thing and was open at the 10-11 gates digest, so that precedent may answer it.

## Conformal / non-Euclidean geometry

- **[circular_screen.md](circular_screen.md)** 🔵 — Framing doc: the circular
  projection screen as a formal constraint, not just a display target. Three
  directions: stereographic (`f_stereo`, built), spherical harmonics
  (`f_sharmonics`, planned), Poincaré disk (`f_poincare`, planned).
- **[droste_singularity.md](droste_singularity.md)** 🔵 — Explains the shadow
  shape at droste's center: the innermost log-polar tile-boundary seam, which
  is simultaneously a Nyquist/sampling-rate isocontour. Directly informs
  `f_poincare`'s and `f_raster`'s design (supersampling shrinks the zone but
  can't eliminate it).
- **[f_poincare.md](f_poincare.md)** ⏸ PAUSED (`.specify/paused/`; blocked on a
  Möbius-composition parity-tracking bug, ADR-8) — Poincaré disk hyperbolic tiling as a
  UV processor. Shares Möbius-transform DNA with `f_mobius`/`f_stereo`. Open:
  {p,q} tessellation choice, fundamental-domain mapping, singularity handling
  (see droste_singularity). Vecfield-masking noted as a natural way to make
  the visible region dynamic rather than disk-shaped.
- **[f_apollonian.md](f_apollonian.md)** ⏸ PAUSED (`.specify/paused/`, same
  algebra bug as `f_poincare`) — Apollonian gasket via iterated
  circle inversion; shares a Möbius-iteration core with `f_poincare` (maybe
  one module, maybe two — undecided). Three Shadertoy references reviewed in
  detail; fixed-iteration loops confirmed GPU-safe, `break`/early-exit
  **unverified**. Ford-circles construction (fixed generating circles + one
  live-animated final inversion) is the recommended first scratch target.
- **[f_apollonian_reference_glsl.md](f_apollonian_reference_glsl.md)** 🔵 —
  Raw reference GLSL (ebanflo-derived Shadertoy) backing the analysis above.
  Not prose — keep as a code reference, not a read-through.
- **[f_ngon.md](f_ngon.md)** 🟡 — Built but ⚠ unfinished/unconfirmed in the README
  (`.specify/f_ngon/`). Live N-gon generator, discovered as a
  byproduct of `f_poincare`'s kaleidoscope diagnostics (alternating-mirror
  reflection settles into a regular 2·n-gon). A real sign-inversion bug was
  found and fixed along the way (documented, in case it recurs elsewhere).
  Iteration count must scale with `n_mirrors` (32 held to n=18; 10 broke).
- **[f_conformal_fill.md](f_conformal_fill.md)** ⚪ — Genuinely different
  architecture: numerically solve a discrete-harmonic system to conformally
  map a tessellation onto an *arbitrary bitmap shape* (not just disk/
  half-plane). Offline precompute (~5 min/shape) + thin GPU sampler at
  runtime — not a `f_poincare` mode, its own build track.
- **[f_sharmonics.md](f_sharmonics.md)** ⚪ — Spherical-harmonics visualizer,
  the topologically-honest sibling of `f_chladni`/`f_vf_chladni` for the
  circular screen. Dual outlet (visual + ∇Y_l^m vecfield in stereographic
  coords). Build `f_vf_chladni` first to prove the dual-outlet pattern.
- **[f_cymascope.md](f_cymascope.md)** ⚪ — Audio-to-vecfield transducer via
  FDTD wave propagation (ping-pong texture, `f_chladni`'s fluid-medium
  sibling). Reframed from "direct visualizer" to "vecfield producer feeding
  `f_caustic`." Flagged high-priority in `vsynth_gaps.md`.

## Discrete-item / textural placement family

- **[discrete_item_family.md](discrete_item_family.md)** 🧰 — The framework
  doc: `f_grain`, `f_masonry`, `f_weave`, `f_vf_seeds` share one identity
  (fields of discrete marks) differing only in arrangement topology. Defines
  the four control layers (global arrangement / local arrangement / item
  character / item orientation) every family member should expose.
- **[f_weave.md](f_weave.md)** 🟢 — Built (the note's own "Status: Idea" header is
  stale). Linear/banded woven texture, orientation
  field generalizes denim→canvas→fingerprint→rope by curl/continuity.
  **Hard requirement:** must be a distance field, not a smoothstep boundary
  — the reference implementation proving that fix (masonry has the same bug
  but is already built and harder to refactor).
- **[f_weave_orientation_blend.md](f_weave_orientation_blend.md)** — see
  Vector field family above (cross-listed; resolved 2026-10-13).
- **[f_dither_grain.md](f_dither_grain.md)** ⏸ SUPERSEDED 2026-07-21 — folded into
  `f_vf_seeds` as Evolution 3 (shipped); `.specify/f_dither_grain/` is history only.
  (The 10-11 gates digest still listed its T001/T002 as blocking; its tasks file says
  superseded.) Ordered dithering reframed
  as an `f_grain`-family processor: per-cell hue selection via a `t` vs.
  jittered threshold `d` test, reusing grain's density/size/shape vocabulary.
  Vecfield driver deliberately decoupled from the hue-boundary test for v1.
- **[f_grain_size_mod.md](f_grain_size_mod.md)** ⚪ — Small, scoped, designed
  (still not built: no `size_mod` in `src/f_grain/definition.py`, checked 2026-10-18;
  `f_grain` itself moved to `.specify/stable/` 2026-10-13): a plain mod-texture inlet blending into `f_grain`'s
  `cell_size` calc. Shape-tex and vecfield-steering alternatives were
  considered and explicitly ruled out first.
- **[seed_distribution_beyond_grid.md](seed_distribution_beyond_grid.md)**
  ⚪ — "Break the grid entirely": current grid+jitter placement (f_grain/
  f_vf_seeds) always has implicit grid-scale structure. Candidates: Poisson
  disk, density-field-driven scatter, precomputed point-set textures. None
  vetted — the fast 3×3 neighbor search is load-bearing and doesn't
  generalize for free.
- **[voronoi_vs_texture_bombing.md](voronoi_vs_texture_bombing.md)** 🔵 —
  Open design question from GPU Gems Ch. 20: `f_grain`/`f_vf_seeds` are
  strict Voronoi (hard clip at cell boundary, mark can never show past its
  own cell) vs. texture-bombing's multi-candidate overlap+priority. Not a
  toggle — different identities, not a spectrum. Discussion only, unresolved.

## Optics, lens, color

- **[f_lens.md](f_lens.md)** 🟢 — Built and working; moved to `.specify/stable/`
  2026-10-13 with v2 (ghost images + halation) closed. Tilt-shift left for `f_focus`
  (paused, never built). The note's future-directions list predates that; anamorphic
  character is split out (see below).
- **[f_caustic.md](f_caustic.md)** 🟢 — Future-directions note for `f_caustic`
  (last updated 2026-06-09, before most of its history): `in3` surface texture, inline
  radial fallback, flare/diffraction as separate bpatchers, color shift. Since then
  `color_shift` and three other params were removed (2026-10-10) and an `edge` menu
  (Off/Wrap/Mirror/Clamp) added (2026-10-17); the module is in `.specify/stable/` and
  `docs/f-reference/f_caustic.md` now exists (the note still says "to be written").
- **[f_lens_tiltshift_split.md](f_lens_tiltshift_split.md)** 🔵 — **Resolved
  retroactively 2026-10-13:** the split happened (tilt-shift moved to `f_focus` on
  2026-09-23; tracking docs had gone stale). Diagnoses
  *why* `f_lens` doesn't get reached for in practice: it bundles a coupled
  radial codebox (aberration/distortion/transmission) with an uncoupled
  `jit.fx.cf.tiltshift` object that shares no mental model. GPU Gems Ch. 23
  suggests a content-driven focus map as tilt-shift's natural growth
  direction, additive to (not replacing) the current gradient-band blur.
- **[f_anamorph_unnamed.md](f_anamorph_unnamed.md)** ⚪ — Static + field-driven
  anamorphic squeeze module, graduated out of `f_lens` v2 scope (judged
  "already very full"). Name TBD. Field-driven half needs hemisphere-aligning
  the vecfield to the static axis before blending (axis is a line, not a
  direction) — mechanism worked out, not yet built.
- **[f_lumia.md](f_lumia.md)** ⚪ — Lumia-style animated caustics: light through
  irregular glass modeled as a height field -> `f_vf_fieldmap` -> `f_caustic`
  (+ optional `f_vf_warp` of the source, same field), animation via evolving
  height, rotation, throw distance. Warp vs. caustic distinction written up;
  `f_vf_fluid` flagged as a trap (`project` removes the convergence caustic
  needs). Untested. Decided 2026-10-06: two modules, `f_vf_glass` (producer)
  and `f_caustic_scatter` (consumer, sheet regime); draft specs in `.specify/`.
  Since then: `f_vf_glass` went on hold the same day, and the scatter work was folded
  into `f_caustic` as an addendum (`edge` mode, 2026-10-17) instead of shipping as its
  own module. `.specify/f_caustic_scatter/` still reads as standalone.
- **[f_vf_glass.md](f_vf_glass.md)** ⏸ ON HOLD (2026-10-06) — Animated analytic glass height field ->
  f_vecfield producer (mode-sum families: modes, fluted, hobnail, hex; evolve /
  drift / rotate; outlets vecfield, height, focus). Chosen 2026-10-06 as a
  separate producer so one glass feeds warp, prism, caustic and the scatter
  module together. Draft spec: `.specify/f_vf_glass/spec.md`. Untested; open
  questions include the time source and regime normalization.
- **[optics_map.md](optics_map.md)** 🔵 — Map of the light-transport concept
  across modules (medium -> dispersion -> scatter -> camera -> persistence),
  the "share one field" compounding principle, a by-phenomenon chart of
  have / compose / build / research / skip, constraints, a proposed
  research order, and the result of research item 1 (NumPy check of
  `f_caustic` vs photon-counting truth: it is the first-order term only, does
  not focus with distance, no fold lines; physical caustics at larger
  distance become overlapping translucent sheets, which needs scatter), and
  the scatter feasibility spike run in Max (GPU point scatter inside Vsynth's
  render context matches the truth, r 0.994 at 3.5 d*; one frame of lag vs
  pix chains; cost and untested items listed). Map plus findings, not a spec;
  built from the inventory, not per-module docs.
- **[f_raster.md](f_raster.md)** ⚪ — Resolution-as-parameter: downsample/
  upsample with independent interpolation mode, for deliberate pixelation and
  as a pre-filter/anti-aliasing utility feeding UV-transformers (droste,
  mobius) that alias badly on hard-edge sources.
- **[lut_curve_and_color_controls.md](lut_curve_and_color_controls.md)** 🔵 —
  Verified against actual codeboxes: `f_channel_grader` already covers GPU
  Gems Ch. 22's Levels model properly. `f_tone_curve` is misleadingly named —
  it's a 3-band smoothstep lift, not an arbitrary curve. Real gap: no
  dependent-texture LUT (1×256 sampled per-channel) exists anywhere in `f_`.
  Matt wants this pursued for real; revisit note added at
  `.specify/f_tone_curve/definition.py`.
- **[spectral_rainbow_colormap.md](spectral_rainbow_colormap.md)** 🔵 — A
  portable primitive from GPU Gems Ch. 8: closed-form scalar→rainbow-RGB via
  a 7-term triangular-bump sum, no LUT. Real gap in `f_vf_prism`, which only
  does 3-tap RGB channel-offset (chromatic aberration), never true spectral
  synthesis. Undecided: new `f_vf_prism` mode vs. standalone `.genexpr`
  helper.

## GPU Gems research sweep

`gpu_gems_research.md` is the index/backlog for this whole cluster — start
there, then the chapter-specific files for depth.

- **[gpu_gems_research.md](gpu_gems_research.md)** 🔵 — Standing backlog
  across all three GPU Gems volumes, checked chapter-by-chapter against real
  `f_` codeboxes (not assumed from titles). Confirmed no-fits are logged
  explicitly so they aren't re-investigated.
- **[godray_radial_accumulation.md](godray_radial_accumulation.md)** 🔵 —
  Not a new module: `f_vf_vortex` (curl=0, divergence outward) → `f_vf_streak`
  /`f_vf_glow` should already produce a god-ray look from the existing chain.
  Untested composition, not a code gap.
- **[glow_profile_and_afterimage.md](glow_profile_and_afterimage.md)** 🔵 —
  Three portable ideas for `f_vf_glow`: dual-Gaussian glow profile (likely
  highest value), periodic/sawtooth step-weight for ghosting character,
  cross-frame afterimage feedback. The chapter's headline separable-blur
  algorithm does **not** apply (glow is already 1D directional, nothing to
  separate).
- **[incremental_gaussian_taps.md](incremental_gaussian_taps.md)** 🔵 — Small
  optimization: replace per-tap `exp()` in `f_vf_glow`'s 48-tap loop and
  `f_vf_prism`'s 11-tap blur with a forward-differencing recurrence. Not
  urgent; whether it even matters on this GPU pipeline is **unverified**.
- **[line_edge_antialiasing.md](line_edge_antialiasing.md)** 🔵 — Root-caused
  a real `f_weave` bug: smoothstep edge width is fixed in UV space and
  doesn't scale with `density_scale` (aliasing worsens as density increases).
  GPU Gems 3 Ch. 25 supplies the general fix: `sd = f(x,y)/length(ddx,ddy)`
  works for any implicit function, not just Bezier curves. `f_masonry`'s
  mortar lines likely share the bug, not yet checked.
- **[sketchy_uncertainty_perturbation.md](sketchy_uncertainty_perturbation.md)**
  🔵 — General NPR trick, independent of the chapter's 3D edge-extraction
  machinery: perturb line width/position/opacity *non-uniformly* (not one
  global jitter) for hand-drawn character. Relevant to `f_weave`, `f_vf_seeds`,
  `f_grain`. A separate axis from the orientation-blend question above, not a
  fix for it.
- **[vorticity_confinement.md](vorticity_confinement.md)** 🔵 — Confirms
  `f_vf_advect`'s core *is* the chapter's real Advection step (not an
  approximation of it). Diffusion/pressure-projection are honestly missing
  (~20–80 Jacobi iterations each, judged impractical at live multi-module
  resolutions — logged so it isn't re-litigated). Portable addition: vorticity
  confinement (S:38.5.1) — see `ceyron_simulation_scripts_notes.md` for the
  finding that reopens the cost assumption via FFT. Built as `f_vf_vorticity`
  (now paused; the README says do not treat it as working), while `f_vf_fluid` took
  the FFT route and shipped.
- **[voronoi_vs_texture_bombing.md](voronoi_vs_texture_bombing.md)** — see
  Discrete-item family above (cross-listed).
- **[spectral_rainbow_colormap.md](spectral_rainbow_colormap.md)** — see
  Optics/color above (cross-listed).

## Simulation & physics research

- **[ceyron_simulation_scripts_notes.md](ceyron_simulation_scripts_notes.md)**
  🔵 — First-pass read of Felix Köhler's CFD/spectral-method reference scripts.
  **FFT-based Stable Fluids thread resolved and shipped (2026-10-11 update):**
  no GL-space FFT in Jitter, but a separable-DFT alternative was verified in
  NumPy then on the GPU test bench (round trip ~5e-6 abs error, ~3ms/pass at
  512², real-time at the 128–256² target) and specced/built as `f_vf_fluid`
  — no longer open. **Both remaining threads evaluated 2026-10-12 (spike
  scripts in tests/): 2D Lattice Boltzmann (D2Q9) fits the chained-pix
  pattern — no slab track; two correctness traps and two real constraints
  (periodic+obstacle unstable at omega ~ 1.97; slow shedding at perf
  resolutions) recorded; remaining question is value vs `f_vf_repulse`, not
  architecture. Kuramoto-Sivashinsky: real-space FD dead (~2000 substeps/
  frame), but the spectral `f_vf_fluid`-shape is stable one-step-per-frame
  (dt ~ 0.076) with a mandatory k=0 mean-zeroing — cleared to spec whenever
  wanted.** **Both then fully specced 2026-10-13** (`.specify/f_ks/spec.md`,
  `.specify/f_vf_lbm/spec.md`); Phase 0 GPU bench not started for either.
- **[slab_chain_architecture.md](slab_chain_architecture.md)** 🧰 —
  **RETIRED 2026-10-12.** Was the stub for a second architectural track
  (true multi-pass GLSL slab chains). FFT fluids shipped without it
  (`f_vf_fluid`, chained pix objects), and the 2026-10-12 spikes proved
  its two remaining candidates (LBM, Kuramoto-Sivashinsky) also fit the
  ordinary pix pattern — no justification left. Kept as the decision
  record; do not build on it.
- **[f_vf_wilson_cowan.md](f_vf_wilson_cowan.md)** — see Vector field family
  above (cross-listed).
- **[f_cymascope.md](f_cymascope.md)** — see Conformal geometry above
  (cross-listed).

## Build process, architecture & conventions

- **[genexpr_interpreter.md](genexpr_interpreter.md)** 🔵 — Analysis (2026-10-18),
  no decision: would a GenExpr interpreter / NumPy transpiler replace the hand-written
  mirrors, and what would it cost? Not worth building yet (the benefit that is specific
  to it, ending mirror translation errors, is unevidenced; the costly findings were GPU
  quirks it could not have found). Suggests a tally of failure kinds plus a one-session
  spike on `f_tf_axisflow`.

- **[build_patcher_schema_gaps.md](build_patcher_schema_gaps.md)** 🧰 —
  Mostly resolved same-day (2026-07-15). Two schema gaps found regenerating
  `f_lens` from `definition.py`: downstream-target params (UI/route dispatch
  targeting a non-primary object) and `panel_toggle` front/back panel
  switching. One piece still open — check the file for which.
- **[module_taxonomy_standardization.md](module_taxonomy_standardization.md)**
  🧰 — Not scheduled. `build_patcher.py`'s `mod_inlets` conflated two shapes
  (optional secondary modulation vs. primary required content) — patched
  narrowly via a `driving_inlet` flag. Broader question open: does the whole
  library need an audited taxonomy of module "shapes," not just labels.
- **[f_util_mod_texture.md](f_util_mod_texture.md)** 🧰 — Convention: modules
  expose a small fixed number of shared mod-texture inlets, with per-param
  weighted accumulation and *assignment* done inside the module (verified
  against `f_masonry`), not via an external routing util. **Superseded as
  the leading plan, 2026-09-17** — `named_mod_textures.md`'s T1-T3 passed
  live, which per this file's own trigger condition obsoletes the matrix
  mechanism and its grid UI (though not the scalar/depth/texture triple or
  the still-open unipolar/bipolar question, both orthogonal to routing).
- **[named_mod_textures.md](named_mod_textures.md)** 🧰 — **CORE MECHANISM
  VERIFIED, 2026-09-17.** Tag texture streams with `prepend <name>` and
  demux with `route` inside the module, the same way Vsynth already does
  for scalar control messages — lets one shared inlet carry arbitrarily
  many named mod textures. T1 (round-trip), T2 (two tagged streams sharing
  one inlet), T3 (no staleness) all passed live in Max. Still open: T4's
  live half (does an untagged target correctly fall back to neutral?), T5
  (inlet ceiling), T6 (`routepass` interaction), and an unexplained failure
  mode (a bare pass-through `jit.gl.pix` didn't render; going straight
  through did). Mostly obsoletes `f_util_mod_texture.md` as the leading
  plan. UI follow-on: `ideas/mod_depth_ui_density.md`.
- **[f_helpfile_content_audit_2026-10-13.md](f_helpfile_content_audit_2026-10-13.md)** 🔵 —
  Audit-only pass of 17 helpfiles' *content* (the same day's sizing fix was layout
  only) against `skills/module-preflight`'s judgment gate: 4 clean, 13 need work.
  Worst three: `f_sirds` (bad citation, doesn't match its own doc), `f_vf_vorticity`
  (recipe omits the one fact that makes it usable), `f_vf_glow` (its doc's recipes
  never reached the helpfile). No rewrites done; deliberately not started.
- **[type_dots.js](type_dots.js)** 🧰 — Parked script, not a note: one `jsui` drawing
  the two module type dots as triangle / disc / square. Dropped 2026-10-17 for the
  plain circles that shipped ("reads as noisy"); copy to `package/javascript/` and set
  `TYPE_DOTS = "jsui"` in `build_patcher.py` to use it.
- **[genjit_abstraction_library.md](genjit_abstraction_library.md)** 🧰 —
  Idea: shared `.genjit` function library for math duplicated across codeboxes
  (Bessel modes, polar setup, sin-hash). Explicitly deferred until 2–3 modules'
  copies have actually diverged — packaging/distribution cost not worth it yet.
- **[web_shim_candidates.md](web_shim_candidates.md)** 🔵 — Getting `f_`
  running in-browser for mattfisher.io demos. **Key finding:** Max already
  exports `jit.gl.pix`/`jit.gen` codeboxes to ISF, JXS, or **WebGL**
  (standalone `.html` + TWGL) directly — no hand-translation needed. WebGL
  export was tried once (2026-10-12, below); known Max-forum history of `exportcode` producing
  broken output (`full_source_code` is the undocumented workaround). **Trial run
  2026-10-12 on `f_vf_split`** (`scratch/experiments/web_shim_trial/REPORT.md`,
  uncommitted): both the WebGL and ISF exports compile and run. Gaps: multi-outlet
  modules collapse to the last outlet, inputs are hardwired to the webcam, params are
  one-shot uniforms, 8-bit instead of float32, free-running clock. No go/no-go made;
  whether feedback modules (`f_vf_advect`, `f_vf_fluid`, `f_caustic`) export at all is
  untested.
- **[dry_wet_gain_and_novel_field_outlet.md](dry_wet_gain_and_novel_field_outlet.md)**
  — see Vector field family above (cross-listed).
- **[CV_TRIGGER_INVENTORY.md](CV_TRIGGER_INVENTORY.md)** 🔵 — Catalog of
  on-system CV→trigger modules (`upshot_attackdetection`, `bonk~`,
  FluCoMa's `onsetslice~`/`onsetfeature~`/`ampslice~`/`ampgate~`) with output
  types tabulated, for designing a routing-matrix message protocol around
  what these modules actually emit.
- **[walkthrough_and_capture.md](walkthrough_and_capture.md)** ⚪ — Public
  walkthrough of `f_` on mattfisher.io (authored "stops" rather than the
  current slideshow workbook) plus a proposed capture pipeline for recording
  module clips, extending the OSC-driven test benches. Decided: recording is
  in scope, and clip inputs are a per-clip mix of test inputs and own footage.
  Everything else is proposed. Open: video capture path (benches only grab
  single float32 frames today).

## Analysis utilities (`f_util_`)

- **[f_util_analysis.md](f_util_analysis.md)** ⚪ — Family of GPU→CPU texture
  self-awareness utilities (proprioception: a patch reacting to its own
  rendered content, not external control). `f_util_profile` (spatial-band
  luminance) is furthest along and the shared-architecture template; others
  named but undeveloped. Known gaps: temporal structure, cross-signal
  relationships, conditioning (→ `f_util_envelope`'s job).
- **[f_util_audio_spectra.md](f_util_audio_spectra.md)** ⚪ — Audio spectral
  *character* extractor (energy/tilt/flatness/flux/bang), fixed 4-band split
  at musically meaningful crossovers, for post-mix/complex-soundscape input.
  Parallel to `f_util_profile` but audio→control instead of GPU→CPU.
- **[f_util_compound_dial.md](f_util_compound_dial.md)** 🧰 — Custom `jsui`
  widget: two concentric rings controlling two independent params in one
  UI footprint. Blocked on a broader "UI density" design question, not
  implementation difficulty.
- **[mod_depth_ui_density.md](mod_depth_ui_density.md)** 🧰 — 2026-09-20
  brainstorm, paused mid-thread: how to show a per-param mod-depth control
  only when connected, dense enough for 12+ params with no scrolling, legible
  and clickable *performing in the dark*. Five UI concepts sketched (two-zone
  fused control, single-strip dual-marker, reveal-on-engage, panel-wide
  mode-flip, XY-pad); real Max facts pinned down along the way (`live.numbox`
  has a native bipolar `appearance` mode; its height is locked in every mode
  except LCD, undocumented, found by hands-on testing). An instance of the
  same open "UI density / control surface design" question this file is
  blocked on — see `.specify/plan.md`. Next step: reviewing Max4Live devices
  for prior art before picking a direction.

## Standalone research

- **[wind_as_interface.md](wind_as_interface.md)** 🔵 — Brainstorm for a
  sewn, inflatable, translucent rear-projection dome deliberately designed
  to deform gently in wind: the reframe from correcting geometry to
  picking content that degrades gracefully under uncontrolled movement
  (`f_vf_vortex`/`f_vf_fluid`/`f_caustic`/`f_grain` fit by nature), the
  escalation to actually sensing live deformation (fabric wrinkles as a
  structure-tensor phenomenon, same math as `vector_field_math_concepts.md`
  §9's line fields), why that needs distributed processing (camera CV and
  GPU-heavy Vsynth contend for the same resources on one machine), and a
  comparison of sensing routes — camera+CV streaming a small field texture
  over NDI vs. distributed IMU nodes (candidate part: Adafruit
  LSM6DS3TR-C, 6-DoF, STEMMA QT) sending OSC over WiFi vs. a plain
  anemometer. Mulling-over notes, nothing decided or built.
- **[entrainment.md](entrainment.md)** 🔵 — Research brief on light/frequency
  altered-state induction (ganzfeld/ganzflicker, SSVEP/photic driving,
  Dreamachine lineage) with an EEG (Muse Athena) angle for measuring real
  vs. claimed effects. Design-brief territory, not a module spec.
- **[f_loop_to_cycle.md](f_loop_to_cycle.md)** ⚪ — Treat a looped video's
  frame-index/N as a WFG-style phase signal, so phase-mod/frequency-scaling
  operations apply to loop playback the same way they apply to a waveform
  cycle. Named target: feed a loop's phase into `f_masonry`'s brick
  modulation. Untested — GPU texture-array phase reads vs. CPU seek-based
  playback is the open technical fork.
- **[f_texture_sampler.md](f_texture_sampler.md)** ⚪ — Working name. An MPC-style
  sampler for video, textures and fields (captured 2026-10-18 from "is there a video
  equivalent of a sampler?"). Splits into A, live capture / freeze / loop on a texture
  ring buffer (Vsynth's `vs_frame_delay` / `jit.gl.textureset` is the precedent), and
  B, a pad-triggered clip bank (mostly control logic over movie playback). Includes a
  memory-budget table, the library-specific angle of recording and replaying float32
  vecfields, and the pad / choke / envelope control layer. Option A doubles as the
  feasibility test for `f_loop_to_cycle` (indexable GPU-resident frames). Nothing
  tried in Max; lean is a small probe on A first.
- **[variable_framerate.md](variable_framerate.md)** ⚪ — Captured 2026-10-18 from "can
  breath or an oscillator drive the frame rate?". Separates render rate (`jit.world`
  `fps` / `interval`, capped at the display refresh with vsync, slower is allowed;
  stutter look) from content time (per-module `dt` / rate / phase step; smooth at a
  steady frame rate). Notes that `f_` state advances per `r draw`, not per second, so a
  slower render clock slows every module and stretches frame-counted smoothers
  (`vs_bline`). Three breath mappings: to render interval, to read-head position
  (a held breath freezes the picture), to a shared `time_scale`. Nothing tried in Max.
- **[vsynth_gaps.md](vsynth_gaps.md)** 🔵 — Strategic gap analysis across Vsynth:
  texture-analysis→control (partially filled), temporal synthesis (high
  priority — `f_cymascope` is the natural next move), non-rectilinear
  geometry (substantially filled), coordinate-space transforms
  (substantially filled). Explicitly calls out what's *not* worth pursuing
  (compositing/color/WFG variants — already comprehensive).

## Scratchpad & catch-all

- **[scratchpad.md](scratchpad.md)** 🔵 — Loose threads not yet graduated to
  their own file: `f_chladni_audio` spectral normalization, `f_mobius`
  performance-gap complaint, a `f_moire` concept (discovered as an
  unwanted moiré artifact in `f_masonry`), texture-as-structural-modulation
  targets, a generative-face concept (downstream of multi-fixed-point
  vecfields), and a Max native-styles color-theming idea.

---

## Notable cross-file relationships worth remembering

- **`f_util_mod_texture.md` vs `named_mod_textures.md`** — the newer
  mechanism's T1–T3 passed live (2026-09-17), so it has displaced most of the older,
  shipped-code-backed convention. T4–T6 (and the unexplained "pix hop" failure) are
  still owed before any `build_patcher.py` change; don't design new mod-inlet UI
  against either until then.
- **`droste_singularity.md`** underlies both `f_poincare.md` (same boundary
  math) and `f_raster.md` (supersampling shrinks but never eliminates it).
- **`f_apollonian.md` / `f_poincare.md` / `f_ngon.md` / `f_conformal_fill.md`**
  all share a "point repeatedly transformed by a generating set until it
  settles" core loop — real shared DNA, unresolved whether any of them merge.
- **GPU Gems sweep** — treat `gpu_gems_research.md` as the table of contents;
  the standalone files exist only where a chapter produced a real, portable
  finding (confirmed no-fits stay logged in the backlog file itself, not
  spun out).
- **`f_texture_sampler.md` / `f_loop_to_cycle.md` / `temporal_synthesis_architecture.md`**
  (`docs/max-reference/`) — one open question seen from three sides: can a pix read
  arbitrary frames from a GPU-resident texture store (Pattern 2, `jit.gl.textureset`)?
  The sampler's option A would answer it for the other two; none has been tried yet.
- **`variable_framerate.md` / `f_a_breath_phase.md` / `f_texture_sampler.md`** — breath
  phase as a read position into a stored loop is the cleanest mapping in the
  variable-frame-rate note, and it answers the breath note's open "does a hold freeze
  phase?" question (the picture holds). Depends on the same frame-store question as the
  sampler and `f_loop_to_cycle.md`.
