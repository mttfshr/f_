# f_ — Project Plan

_Last updated: 2026-07-12_

This document is orientation, not execution. It names active workstreams, states current thinking on sequencing and priority, and surfaces open questions that need a decision before work can proceed. Per-module task detail lives in `.specify/f_name/tasks.md`. Session-specific state and full narrative history live in `HANDOFF.md`.

---

## Work queue — current thinking

1. ~~Crossfader/dry-wet UI widget convention~~ — **RESOLVED 2026-07-12** (took `f_vf_prism` five attempts to get right — see item 2 and `ideas/dry_wet_gain_and_novel_field_outlet.md` finding 1 for the full history). `mix` control is `live.numbox`, unipolar 0–100% (originally "wet," renamed per Matt's call). **Correct shape**: `driven = clamp(src+layer*gain, 0, 1); comp = mix(src, driven, mix_pct/100.0)` — `driven` is the module's own complete, already-composited 100%-effect state, NOT a bare effect layer and NOT masked by coverage/opacity; both of those were tried and produced double-image artifacts, since a bare/sparse effect layer has empty regions that break a uniform crossfade. Internal `Param` must be named `mix_pct`, not `mix` (collides with the codebox's own `mix()` operator — real bug, `jit-gen-codebox` skill). Written into `vsynth-bpatcher/SKILL.md` and `ideas/dry_wet_gain_and_novel_field_outlet.md` finding 1/2.
2. ~~Dry/wet/gain + novel-field-outlet rollout~~ — **implementation DONE 2026-07-12**, Max verification partial. All six modules (`f_chladni`, `f_vf_advect`, `f_vf_prism`, `f_caustic`, `f_vf_glow`, `f_vf_streak`) now share one canonical naming: **`gain`** (unbounded effect intensity) and **`mix`** (0–100%, `live.numbox`, blend ratio) — never a synonym, locked into `vsynth-bpatcher/SKILL.md`'s "Canonical naming: `gain` vs `mix`" section after real drift surfaced (three different names — `gain`/`strength`/`intensity` — had crept in across already-shipped modules for the same role). `f_vf_prism` (`strength`→`gain`) and `f_caustic` (`intensity`→`gain`, `strength`→`mix`) retrofitted; `f_vf_glow`/`f_vf_streak` built fresh. `f_vf_glow` and `f_vf_prism` confirmed working in Max by Matt. **`f_caustic` and `f_vf_streak` still need Max verification** — do that next, then this item is fully closed (Phase 5 docs/registration sweep is otherwise a no-op — no new modules, no outlet-count changes). `f_vf_prism`'s own `out3_scale` internal constant (guess 8.0, novel-field-outlet work) still needs empirical tuning whenever next observed in Max. `f_vf_prism`'s own `gain` composite is still additive/screen, occlusion-model question still open, not resolved. `f_vf_warp` also touched (real behavior change: out2 currently ignores bypass — flag for Matt's explicit confirmation before building). `f_vf_chroma` not yet assessed for this convention. Full session detail: HANDOFF.md 2026-07-12d entry.
3. ~~f_vf_advect `separate` doc debt~~ — the mix/gain/mode work this session (item 2 above) documented `separate`'s ADR history properly, but **`separate` itself remains flagged CANDIDATE/UNVERIFIED in its own codebox header comment (2026-07-07)** — that underlying verification question is still open, just no longer an undocumented loose end. Whoever picks this up next should treat "is separate actually confirmed working" as a live question, not settled.
4. ~~`mode` param upgrade to `live.menu`~~ — **DONE 2026-07-12**, see ADR 8 in `.specify/f_vf_advect/plan.md`.
5. **f_poincare — Phase 3** — SHELVED along with the rest of f_poincare, see Paused/blocked below. Kept here only as a placeholder for what Phase 3 would involve if resumed: real circular-arc {p,q} tiling with actual source-texture sampling (current output is region-ID/depth coloring only). Also open: iteration count beyond the untested 24-guess, cross-check closed-form geometry against a second {p,q} pair, compute `edge_r2`/`edge_d` in-codebox from live params instead of hardcoded Python-derived constants.

---

## Paused / blocked — do not resume by default

- **`f_apollonian`** — SHELVED. Real unresolved contradiction: `use_mapped=2` (pass/fail) shows large fail regions that `use_mapped=4` (signed error vector) shows as near-zero error on the same regions — these two views should agree and don't. `debug_ok`'s own step/mix logic is the prime suspect, not yet traced. Full detail: `.specify/f_apollonian/plan.md` ADR-8 Update 2. Concrete next step if picked up: one clean fresh `use_mapped=2`→`4` pair (forcing full reopen to rule out stale compile state), then trace `debug_ok` directly. `ring_count=2` divide-by-zero needs a guard whenever `ring_count` goes live. Do not trust prior "confirmed working" language anywhere in this module's history without independent re-verification — this module has been wrongly marked confirmed twice already.
- **`f_vf_vorticity`** — built, status genuinely UNVERIFIED. Do not register in `f_modules.maxpat` or build on top of it assuming it works — an earlier session's confidence in this module did not survive re-scrutiny. Renamed conceptually to "curl amp" with a `gain` param; file rename deferred. Needs independent re-verification from scratch before any further work.
- **`f_poincare`** — SHELVED (Matt's call, 2026-07-12). Phase 0-2 confirmed working, closed-form {p,q} formula derived for {4,5} — see Hyperbolic/non-Euclidean geometry workstream below for what's already done. Phase 3 (real texture sampling) not resumed unless Matt explicitly asks.
- **`f_vf_advect` / vorticity-confinement fold-in** — attempted, reverted to last-committed state (`e27db16`) except for one real, unrelated, preserved fix (`strength`/`mix_amt` param-name mismatch). Confinement itself never got working despite exhaustive, evidence-based elimination of every hypothesis tried. If resumed: try a dedicated multi-stage `pix_chain` splitting curl-computation from confinement-force computation into separate stages, rather than one combined codebox (never tried). Full history: `ideas/vorticity_confinement.md` addendum.

---

## Workstreams

### Helpfile pass
Tooling operational — `tools/generate_helpfiles.py`. 18+ helpfiles generated; `f_vf_seeds` deferred by Matt's explicit choice (3 real texture inlets don't fit the skill's single-source template cleanly — Matt will build this one directly in Max). `f_sirds`, `f_vf_advect` helpfiles still outstanding. `f_droste.maxhelp` remains the canonical hand-built template.

### Vecfield consumer ecosystem
Producers: `f_vf_vortex`, `f_vf_vortex_multi`, `f_vf_fieldmap`. Consumers: `f_caustic`, `f_vf_warp`, `f_vf_streak`, `f_vf_advect`, `f_vf_glow` — all built and shipped. `f_vf_vorticity` ("curl amp") is a standalone processor attempt, unverified — see Paused/blocked above.

Masking (`f_vf_scalar` — magnitude/divergence/curl/angle as scalar outputs) remains further out; evaluate performance need before speccing. Note: the dry/wet/gain rollout's "novel field outlet" heuristic (finding 4, `ideas/dry_wet_gain_and_novel_field_outlet.md`) has started answering pieces of this question per-module rather than as a single `f_vf_scalar` module — worth reconciling once the six-module rollout lands.

### f_chladni / f_cymascope — audio-to-vecfield family
`f_chladni` shipped (single-resonance transducer, note+amp interface, dual luma/vecfield outlet) and is now also in the dry/wet/gain rollout queue (finding 6 only — cleanest case, pure wiring). `f_cymascope` still gated behind that convention settling and behind `f_vf_advect`'s multi-pix bpatcher pattern, both now established precedent.

### Hyperbolic / non-Euclidean geometry
`f_mobius` shipped. `f_poincare` has real progress: Phase 0/1 (dihedral kaleidoscope) and Phase 2 (accumulated Möbius-transform tracking) both confirmed working, closed-form {p,q} edge-geodesic formula derived and confirmed in Max for {4,5} — first genuine hyperbolic tiling this project has produced. Phase 3 (real texture sampling) is next, see Work queue above. `f_apollonian` is a structurally related but currently shelved sibling thread (see Paused/blocked) — Phase 2's verified complex/Möbius arithmetic (now in the `jit-gen-codebox` skill as known-good) should get applied back to it before `f_apollonian` resumes, per Matt's stated intent, but that hasn't happened yet. `f_ngon` (regular N-gon generator/mask) forked off `f_poincare` Phase 1 as an idea, not specced — see Parked. `f_sharmonics` still unstarted, no updated timeline.

### Build system generalisation
**Complete.** `build_patcher.py` supports `outlets`, `vs_instate` per-inlet bypass, `pix_chain`/`pix_wires` multi-pix bpatchers, `range_tiers`, and (since the `f_vf_seeds` inlet bug fix) `driving_inlet` for primary-required-content modules vs. optional-secondary-modulation modules. Per-module scripts retired except where hand-built UI makes full regeneration unsafe (see below).

**Never regenerate via `tools/build_patcher.py` — hand-edit `.maxpat` directly:** `f_masonry`, `f_sirds`, `f_vf_advect`, `f_vf_seeds` (multistage). Confirmed the hard way (a full regen of `f_masonry` once silently destroyed ~1900 lines of hand-built mod-matrix UI). Surgical Python-script text edits or Desktop Commander `edit_block` only, verified against `git diff --stat`.

### Temporal synthesis
`f_vf_advect` (Pattern 1, one historical frame) and `f_vf_glow` (single-pass field-aligned blur) both done. `f_cymascope` (Pattern 1 extended, two historical frames) still queued behind the audio-to-vecfield family settling above. `f_vf_smear` — try single-pass LIC first. `f_ganzflicker`/`f_dreamachine`/`f_util_envelope` — not texture-feedback problems, live in audio/signal domain instead.

### f_modules menu
**Complete, 2026-07-10.** Rebuilt from 5 categories to 8 (Scope, Discrete, Spatial, Optical, ∇ Generators, ∇ Processors, Color/Tone, Utilities), organized by visual character rather than generator/processor archetype. All 32 shipped modules accounted for; `f_apollonian`/`f_poincare`/`f_vf_vorticity` correctly excluded pending confirmation. ∇ marking convention applied to vecfield-typed modules/categories. `f_lens` and `f_weave` still lack explicit vecfield port labels (real gap, not urgent — noted in HANDOFF). **2026-07-12: the labeling procedure for non-`f_vf_`-prefixed mixed-outlet modules is now written down** in `vsynth-bpatcher/SKILL.md`'s "Vecfield labeling for non-`f_vf_`-prefixed modules" section (header `signal_type` free-text + hand-set standard color, plus `tools/append_nabla_menu.py`'s `VECFIELD_MODULES` set) — applied to `f_chladni` as the first concrete case. `f_lens`/`f_weave` can follow the same recipe whenever picked up.

### UI density / control surface design
Still pre-spec, still blocks `f_util_matrix` jsui refinement and any composite-dial widgets. No new movement since 2026-06-17 framing — question stands as written: survey what's expressive within Max's bpatcher/jsui constraints before either downstream implementation begins.

### Infrastructure: f_util_matrix
Working implementation exists; refinement blocked on the UI density discovery phase above. Don't touch until that closes.

### Module taxonomy
Open question, not scheduled: several modules (`f_masonry`, `f_weave`) are labeled `archetype:"processor"` but behave as self-sufficient generators (black bypass, no real content dependency) — the mirror image of the bug that `f_vf_seeds`' generator-labeled-as-driving-inlet mismatch caused. Matt's call: fix concrete cases as they surface, formalize a rubric later, revisit when the `f_modules` category system next gets touched. `ideas/module_taxonomy_standardization.md` has the fuller writeup.

---

## Parked

- **`f_ngon`** — regular N-gon generator/mask, byproduct of `f_poincare` Phase 1's kaleidoscope fold. `ideas/f_ngon.md`. Not scheduled.
- **`f_conformal_fill`** — offline-solved arbitrary-boundary conformal tiling, different architecture from `f_poincare` (precompute + thin GPU sampler). Idea file created, not specced.
- **Helpfile refinement** — ongoing tinkering; some modules will want purpose demonstrations; not a task queue item.
- **`f_util_profile` dual-axis output** — works as-is; extension is a nice-to-have.
- **`f_raster`** — mostly superseded by `vs_pixelator`; only supersampling/pre-filter and anisotropic x/y scaling remain as genuine gaps, no urgency.
- **Entrainment / perceptual work** (`f_ganzflicker`, `f_dreamachine`) — design research phase only; Muse Athena EEG integration available but ungrounded.
- **`f_vf_streak` color_shift v2** — full 2D field vector shift, parked pending clear expressive need.
- **`f_vf_scalar` / masking** — evaluate performance need before speccing; see also the vecfield-ecosystem note above re: overlap with the dry/wet rollout's novel-outlet findings.
- **`f_tone_curve` real LUT-based curve** — Matt confirmed wants this; gap identified via GPU Gems research (1D LUT, `ideas/lut_curve_and_color_controls.md`; 3D-LUT generalization noted but blocked on unconfirmed GenExpr 3D-texture-sampling support).
- **`f_lens` tilt-shift split** — architecture/naming question (`f_tiltshift` vs `f_focus`), whether to add a content-driven focus-map blur mode. `ideas/f_lens_tiltshift_split.md`.
- **Godray composition via `f_vf_vortex` → `f_vf_streak`/`f_vf_glow`** — should work with zero new code per GPU Gems Ch. 13 comparison, untested. `ideas/godray_radial_accumulation.md`.
- **Line/mark edge antialiasing** (`f_weave`, `f_masonry`) — real diagnosed aliasing issue, blocked on whether GenExpr exposes `ddx`/`ddy`-equivalent screen-space derivatives (checked against Max's documented Gen operator set — doesn't appear; not yet confirmed via live scratch test). `ideas/line_edge_antialiasing.md`.
- **Sketchy/uncertainty perturbation** for `f_weave`-family line geometry. `ideas/sketchy_uncertainty_perturbation.md`.
- **Spectral rainbow colormap** for `f_vf_prism` (currently 3-tap RGB offset only, not true spectral synthesis). `ideas/spectral_rainbow_colormap.md`.
- **Glow profile shaping + temporal afterimage** for `f_vf_glow`. `ideas/glow_profile_and_afterimage.md`.
- **Incremental Gaussian taps** — low-priority perf optimization for `f_vf_glow`/`f_vf_prism` blur loops, unprofiled. `ideas/incremental_gaussian_taps.md`.
- **Voronoi vs. texture-bombing identity question** (`f_grain`/`f_vf_seeds` "naturalness" gap) — sharpened to: grid-rigidity and cell-boundary clipping are the same structural problem, not a tuning ceiling; field convergence should be able to produce mark overlap the way the field's own information predicts. No mechanism chosen (Poisson disk / density-field scatter / texture-fed point set / grid-as-search-structure-only all open). `ideas/seed_distribution_beyond_grid.md`.
- **Jacobi diffusion/projection scratch test** — test the "20-80 iterations, too expensive" non-goal empirically in this pipeline (no FFT, no CPU roundtrip) before pursuing either FFT path further. `ideas/ceyron_simulation_scripts_notes.md`.
- **Known small bugs, untouched:** `f_masonry` square-output-at-non-square-render; `f_hue_processor` band drag; `f_weave` — Matt flagged "can't put my finger on it yet," not yet confirmed related to the grain/seeds thread above.
