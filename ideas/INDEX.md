# Ideas Index

_Created: 2026-09-17._ A refresher map of `ideas/` (59 files) so you don't have
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

- **[f_a_spectral_ripple.md](f_a_spectral_ripple.md)** 🟡 — Cross-frequency
  de-correlating tinnitus stimulus generator (Yukhnovich et al. 2025). T1–T7
  scratch-verified; shipped as first production build
  `package/patchers/f_a_ripple.maxpat` (see repo HANDOFF.md). Open: UI polish
  to `f_` visual convention, Phase 5 docs/helpfile, T7b (PM in `pfft~`) and T8
  (cross-frequency correlation check) — neither gates v1.
- **[f_a_build_process.md](f_a_build_process.md)** ⚪ — Scoped follow-up: can
  `build_patcher.py` extend to `f_a_` (audio) modules, or does audio need its
  own builder? Analysis done (UI-grid half reusable, `gen_subpatcher`/`pix_box`
  half is not); not started. Blocks nothing yet, but next thing both
  `f_a_ripple` and `f_a_purr` will want once DSP is stable.

## Audio modules (`f_a_` prefix)

- **[f_a_purr.md](f_a_purr.md)** 🟡 — Fully parametric cat-purr synthesis
  (glottal click → pulse train → breath cycle → resonance → behavioral
  scheduler, 6 layers). Layers 0–2/4 + resonator verified in scratch. Q2, Q4,
  Q6, Q7 still open. First `f_a_` module; established the prefix.
- **[f_a_breath_phase.md](f_a_breath_phase.md)** ⚪ — Input utility: read
  wearer's breathing (contact mic/piezo, plain `adc~`, no MIDI bridge needed)
  and drive a downstream generator's phase directly. Pure ideation, no signal
  chain built.
- **[f_a_spectral_ripple.md](f_a_spectral_ripple.md)** — see Active above.
- **[f_a_build_process.md](f_a_build_process.md)** — see Active above.

## Vector field family (`f_vf_*`, `f_vecfield`)

- **[f_vecfield.md](f_vecfield.md)** 🟢 — The family's type contract (float32,
  RG=XY, 0.5=zero) and roadmap hub. Producers built: `f_vf_vortex(_multi)`,
  `f_vf_fieldmap`. Consumers built: `f_caustic`, `f_vf_warp`, `f_vf_streak`.
  Points out remaining territory: `f_vf_turbulence`, `f_vf_chladni`,
  masking/scalar-extraction, advection, modulation.
- **[f_vf_seeds.md](f_vf_seeds.md)** ⚪ — Discrete-item generator: marks at
  hash-stable seed points, oriented by an incoming vecfield (wind-barb/ink
  look). Reference implementation for the discrete-item family's inlet
  architecture and "identity coordinate" output.
- **[f_vf_mix.md](f_vf_mix.md)** ⚪ — Infrastructure: blend two vecfields
  (additive / crossfade) before a consumer. Not built; build when a real
  chain needs it.
- **[f_vf_channelmap.md](f_vf_channelmap.md)** ⚪ — Reinterpret any two
  texture channels directly as vecfield XY (no gradient math) — inverse of
  `f_vf_split`. Supersedes and absorbs the deleted `f_vf_normal.md`.
- **[f_vf_optical_flow.md](f_vf_optical_flow.md)** ⚪ — Derive a vecfield from
  motion between frames. Cheap frame-diff approximation **tested and ruled
  out** (2026-07-17, structural reason: gradient-of-a-trail points the wrong
  way, not a tuning problem). Real Lucas-Kanade optical flow is the only path
  left, not started — biggest remaining build in the family if pursued.
- **[f_vf_smear.md](f_vf_smear.md)** ⚪ — True continuous streamline blur
  (fixes the visible discrete-sample banding in `f_vf_streak` at long
  lengths). LIC single-pass or multipass-iterative; LIC flagged as the
  cheaper first prototype.
- **[f_vf_temporal_smooth.md](f_vf_temporal_smooth.md)** ⚪ — Parked:
  frame-to-frame inertia/lag applied to any vecfield (one-pole lowpass, but
  per-vector). Deliberately spun out of `f_vf_advect` rather than becoming its
  3rd outlet.
- **[f_vf_wilson_cowan.md](f_vf_wilson_cowan.md)** ⚪ — Vecfield producer from
  the Wilson-Cowan neural-mass model (E/I reaction-diffusion) — targets the
  classic funnel/spiral/lattice/cobweb hallucination-form taxonomy
  (Ermentrout-Cowan). Needs `jit.gl.node @capture 1` self-recursion, not a
  stateless pix chain.
- **[f_weave_orientation_blend.md](f_weave_orientation_blend.md)** ⚪ — Open
  bug/question: `f_weave`'s vecfield-driven orientation uses vector-add +
  renormalize (non-proportional response); candidate fix is true angular
  blend via `atan2`. Needs a live A/B scratch test, not decided.
- **[dry_wet_gain_and_novel_field_outlet.md](dry_wet_gain_and_novel_field_outlet.md)**
  🧰 — Design discussion (no module chosen yet): reframe additive-layer
  modules (`f_vf_glow/chroma/prism/streak`, `f_caustic`) with separate `gain`
  (can exceed 1.0) + `mix` (0–100% crossfade) controls, vs. the true
  replacement-shape modules (`f_mobius/droste/lens/warp`) which already map
  cleanly to `mix(src, processed, wet)`. "Add a vecfield 3rd outlet" idea
  scoped but unresolved.

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
- **[f_poincare.md](f_poincare.md)** ⚪ — Poincaré disk hyperbolic tiling as a
  UV processor. Shares Möbius-transform DNA with `f_mobius`/`f_stereo`. Open:
  {p,q} tessellation choice, fundamental-domain mapping, singularity handling
  (see droste_singularity). Vecfield-masking noted as a natural way to make
  the visible region dynamic rather than disk-shaped.
- **[f_apollonian.md](f_apollonian.md)** ⚪ — Apollonian gasket via iterated
  circle inversion; shares a Möbius-iteration core with `f_poincare` (maybe
  one module, maybe two — undecided). Three Shadertoy references reviewed in
  detail; fixed-iteration loops confirmed GPU-safe, `break`/early-exit
  **unverified**. Ford-circles construction (fixed generating circles + one
  live-animated final inversion) is the recommended first scratch target.
- **[f_apollonian_reference_glsl.md](f_apollonian_reference_glsl.md)** 🔵 —
  Raw reference GLSL (ebanflo-derived Shadertoy) backing the analysis above.
  Not prose — keep as a code reference, not a read-through.
- **[f_ngon.md](f_ngon.md)** ⚪ — Live N-gon generator, discovered as a
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
- **[f_weave.md](f_weave.md)** ⚪ — Linear/banded woven texture, orientation
  field generalizes denim→canvas→fingerprint→rope by curl/continuity.
  **Hard requirement:** must be a distance field, not a smoothstep boundary
  — the reference implementation proving that fix (masonry has the same bug
  but is already built and harder to refactor).
- **[f_weave_orientation_blend.md](f_weave_orientation_blend.md)** — see
  Vector field family above (cross-listed, it's a `f_weave` bug).
- **[f_dither_grain.md](f_dither_grain.md)** ⚪ — Ordered dithering reframed
  as an `f_grain`-family processor: per-cell hue selection via a `t` vs.
  jittered threshold `d` test, reusing grain's density/size/shape vocabulary.
  Vecfield driver deliberately decoupled from the hue-boundary test for v1.
- **[f_grain_size_mod.md](f_grain_size_mod.md)** ⚪ — Small, scoped, designed
  (not built): a plain mod-texture inlet blending into `f_grain`'s
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

- **[f_lens.md](f_lens.md)** 🟢 — Built and working; future-directions note.
  Open: inter-reflection/ghost images (own bpatcher candidate,
  `f_interreflect`), anamorphic character (now split out, see below),
  halation.
- **[f_lens_tiltshift_split.md](f_lens_tiltshift_split.md)** 🔵 — Diagnoses
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
  finding that reopens the cost assumption via FFT.
- **[voronoi_vs_texture_bombing.md](voronoi_vs_texture_bombing.md)** — see
  Discrete-item family above (cross-listed).
- **[spectral_rainbow_colormap.md](spectral_rainbow_colormap.md)** — see
  Optics/color above (cross-listed).

## Simulation & physics research

- **[ceyron_simulation_scripts_notes.md](ceyron_simulation_scripts_notes.md)**
  🔵 — First-pass read of Felix Köhler's CFD/spectral-method reference scripts.
  **Real finding:** FFT-based Stable Fluids makes diffusion and pressure
  projection each a single elementwise Fourier-space op — reopens the
  "too expensive for real-time" conclusion in `vorticity_confinement.md`,
  *if* GPU FFT is available. Checked: `jit.fft` exists but isn't GL-space —
  open question, not resolved.
- **[slab_chain_architecture.md](slab_chain_architecture.md)** 🧰 — Stub for a
  second architectural track: true multi-pass GLSL slab chains
  (`jit.gl.slab`/`pass`/`node` ping-pong), needed for FFT Stable Fluids,
  Lattice Boltzmann, possibly Kuramoto-Sivashinsky. Explicit gate before
  promoting to spec: current gain/mix rollout closed out, a concrete first
  target chosen, a scratch-patch spike confirming ping-pong behavior in Max 9.
- **[f_vf_wilson_cowan.md](f_vf_wilson_cowan.md)** — see Vector field family
  above (cross-listed).
- **[f_cymascope.md](f_cymascope.md)** — see Conformal geometry above
  (cross-listed).

## Build process, architecture & conventions

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
- **[genjit_abstraction_library.md](genjit_abstraction_library.md)** 🧰 —
  Idea: shared `.genjit` function library for math duplicated across codeboxes
  (Bessel modes, polar setup, sin-hash). Explicitly deferred until 2–3 modules'
  copies have actually diverged — packaging/distribution cost not worth it yet.
- **[web_shim_candidates.md](web_shim_candidates.md)** 🔵 — Getting `f_`
  running in-browser for mattfisher.io demos. **Key finding:** Max already
  exports `jit.gl.pix`/`jit.gen` codeboxes to ISF, JXS, or **WebGL**
  (standalone `.html` + TWGL) directly — no hand-translation needed. WebGL
  export is untested; known Max-forum history of `exportcode` producing
  broken output (`full_source_code` is the undocumented workaround). Next
  concrete step: try `exportcode webgl` on one simple shipped module
  (`f_droste` or `f_mobius`).
- **[dry_wet_gain_and_novel_field_outlet.md](dry_wet_gain_and_novel_field_outlet.md)**
  — see Vector field family above (cross-listed).
- **[CV_TRIGGER_INVENTORY.md](CV_TRIGGER_INVENTORY.md)** 🔵 — Catalogue of
  on-system CV→trigger modules (`upshot_attackdetection`, `bonk~`,
  FluCoMa's `onsetslice~`/`onsetfeature~`/`ampslice~`/`ampgate~`) with output
  types tabulated, for designing a routing-matrix message protocol around
  what these modules actually emit.

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

- **`f_util_mod_texture.md` vs `named_mod_textures.md`** — the newer,
  unverified hypothesis would obsolete most of the older, shipped-code-backed
  convention. Don't design new mod-inlet UI against either until
  `named_mod_textures.md`'s tests run.
- **`droste_singularity.md`** underlies both `f_poincare.md` (same boundary
  math) and `f_raster.md` (supersampling shrinks but never eliminates it).
- **`f_apollonian.md` / `f_poincare.md` / `f_ngon.md` / `f_conformal_fill.md`**
  all share a "point repeatedly transformed by a generating set until it
  settles" core loop — real shared DNA, unresolved whether any of them merge.
- **GPU Gems sweep** — treat `gpu_gems_research.md` as the table of contents;
  the standalone files exist only where a chapter produced a real, portable
  finding (confirmed no-fits stay logged in the backlog file itself, not
  spun out).
