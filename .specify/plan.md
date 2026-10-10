# f_ — Project Plan

_Last updated: 2026-10-10_

This document is orientation, not execution. It names active workstreams, states current thinking on sequencing and priority, and surfaces open questions that need a decision before work can proceed. Per-module task detail lives in `.specify/f_name/tasks.md`. Session-specific state and full narrative history live in `HANDOFF.md` and git log — resolved items below are kept to one line with a pointer, not the full story.

---

## Work queue — current thinking

**Resolved / done (compressed — see the pointer for detail):**

- Crossfade/dry-wet UI convention (`gain` unbounded, `mix_pct` 0–100% `live.numbox`, `driven` = full composite not a bare layer) — locked 2026-07-12, see `skills/vsynth-bpatcher/SKILL.md` "Canonical naming: gain vs mix".
- Six-module gain/mix rollout (`f_chladni`, `f_vf_advect`, `f_vf_prism`, `f_caustic`, `f_vf_glow`, `f_vf_streak`) — done 2026-07-17, all confirmed in Max except `f_vf_streak` (never confirmed, not blocking).
- `f_vf_advect`'s `separate` doc debt, `mode`→`live.menu` upgrade — both done 2026-07-12; module moved to `.specify/stable/`.
- `f_vf_warp` bypass (native `@bypass` flipped `out2`) — fixed 2026-09-23 via a codebox `bypass_gate` Param, same mechanism used library-wide below.
- **Bypass-passthrough rollout, 11 modules** — every outlet now mixes to its own-kind neutral (source for textures, 0.5/0.5 for vecfields) under bypass, via `bypass_mode: "param"` + a codebox `Param bypass_gate` (never the native `@bypass`, which skips the shader and silently flips secondary outlets — see Parked). **11 of 11 done** 2026-10-06, bench-verified live (33/33 modules, 0 unexpected issues). Mechanism: `skills/vsynth-bpatcher/SKILL.md` "Native bypass caveat". Open: whether a shader-side guard would recover GPU cost on the now-always-running heavy modules — untested, see `f_grain`/`f_caustic` spikes below (answer so far: no measurable effect, below the bench's floor).
- **`f_vf_fluid`** (spectral velocity solver, vecfield producer) — specced, built, tuned, and shipped 2026-09-23 through 2026-09-29 (all phases done: NumPy mirror, GPU stage proofs, module build, viscosity/force-filtering tuning, reference doc + helpfile + menu entry). Not on the never-regenerate list. One parked oddity: doesn't appear when added from the `f_modules` menu (undiagnosed, see HANDOFF history).
- **`f_caustic` sheets mode (GPU scatter)** — built and shipped 2026-10-07/08. Second mode alongside the original ("soft"): a GL point-scatter path forming folded sheets, selector picks the branch. Live-tested by Matt 2026-10-08: reads clearly better than soft; `gain`/`scale` both got `range_tiers` menus; `color_shift`/`softness` correctly inert in sheets mode (soft-only params, left as-is); `detail` vs. output-resolution cost investigated (module alone never clears the bench's 60fps floor — any live slowdown is the full performance patch compounding, not this module). Full record: `.specify/f_caustic_scatter/tasks.md`. Still open: Matt's demo-patch chain-cost check (what in the live patch is actually expensive) — untouched since 2026-10-08.
- **`f_grain`** — `amount`→`gain` rename + new `mix_pct` crossfade (library convention), softness range fix, perf spike (no measurable bypass-guard win, same as `f_caustic`'s finding). Done 2026-10-09/10, live-checked in Max. Taken **off** the never-regenerate list (see Build system section). Found and fixed a real `build_patcher.py` interaction along the way — raw_ui modules' hand-captured `raw_lines` hardcode route-object outlet *indices*, which silently shift whenever a new UI param is added (grouped by type, not list position) — documented as a standing hazard in `docs/f-reference/f_grain.md`. Full record: `.specify/f_grain/tasks.md`.

**Still open:**

1. **`f_lens` v2 — ghost/halation.** Specced 2026-07-15, Phase 1 (ghost) was in progress as of that date; anamorphic scope moved out to `ideas/f_anamorph_unnamed.md`. Status not re-checked since — confirm where Phase 1 actually landed before resuming. `.specify/f_lens/spec.md` v2, `plan.md` ADR-6.
2. **`f_vf_optical_flow`.** Phases 0–4 done 2026-07-18 (real Lucas-Kanade, replacing a ruled-out frame-diff approach). Phase 5 open: axis-aligned content makes the 2×2 solve singular (real aperture-problem limitation, not a tuning issue) — fix is confidence-gated spatial fill, mechanism (isotropic blur vs. directional propagation) undecided. `.specify/f_vf_optical_flow/tasks.md` T034–T038. Not yet stable/registered.
3. **Edit-view layout pass for `build_patcher.py`.** Implemented 2026-09-24 (`build/layout.py`, zone-based, 0 overlaps across 30 buildable definitions). 10 of 33 modules regenerated with it so far; the rest have drifted from their definitions and weren't touched (Matt's call). Open: Matt's look at the 10 in Max (constants are first guesses), whether to sync the drifted definitions or leave them, `build_fluid.py` adoption.
4. **Packaging / Package Manager readiness.** Started 2026-10-01. Done: `package-info.json` fixed, `examples/` renamed+repaired, `release.sh`, README install section. Open: license (asking Kevin re: Vsynth adaptation/CC BY-NC), `icon.png`, first tag/release, how the C74 registry ingests submissions (unread), `max_version_min` unverified. `.specify/packaging/tasks.md`.
5. **Build/tools/test cleanup — `definition.py` as source of truth.** Ongoing multi-phase project since 2026-10-04. Core rule: a hand edit in Max must be written back into `definition.py`; `tests/test_drift.py` ratchets a shrinking "can't regenerate yet" baseline (`tests/drift_baseline.json`). Current count: **32 of 39 shipped patchers reproduce exactly from their definitions; baseline 7** (`f_grain` came off 2026-10-09, same way `f_vf_advect` did earlier). Remaining baseline + hand-built modules are listed in the Build system section below — that list *is* the live task queue for this project now; check any module with `build/py.sh build/drift.py -v <name>`. `.specify/build_cleanup/tasks.md`.

---

## Paused / blocked — do not resume by default

- **`f_focus`** — SHELVED 2026-07-17. Phase 0 (feasibility) confirmed working, but shelved on a "does this warrant existing" question: as scoped it's a pure UI/state wrapper around one stock native object with zero added processing. Resume only if Phase 2's content-driven focus-map blur gets picked up, or a concrete gap in using the native object bare surfaces. `.specify/f_focus/{spec,plan,tasks}.md`.
- **`f_apollonian`** — SHELVED. Real unresolved contradiction: `use_mapped=2` vs `=4` disagree on the same regions; `debug_ok`'s step/mix logic is the prime suspect, not yet traced. Do not trust prior "confirmed working" language in this module's history without independent re-verification (wrongly marked confirmed twice already). `.specify/f_apollonian/plan.md` ADR-8.
- **`f_vf_vorticity`** ("curl amp") — built, status genuinely UNVERIFIED. Do not register in the module menu or build on top of it. Needs independent re-verification from scratch.
- **`f_poincare`** — SHELVED (Matt's call, 2026-07-12). Phases 0–2 confirmed working, closed-form {p,q} formula derived for {4,5}. Phase 3 (real texture sampling) not resumed unless Matt explicitly asks.
- **`f_vf_advect` / vorticity-confinement fold-in** — attempted, reverted; confinement never worked despite exhaustive elimination. If resumed, try a dedicated multi-stage `pix_chain` splitting curl computation from confinement-force computation (never tried). `ideas/vorticity_confinement.md`.

---

## Workstreams

Durable, lower-tempo threads not tied to one task. Most of the detailed "why" lives in the referenced skill/idea files — this is pointers, not the history.

- **Test infrastructure.** Built 2026-09-22: a NumPy math layer (`tests/gpu_sim.py`, `tests/run.sh`) plus a Max test bench (generated patch driven over OSC, float32 transfer, fps measurement; `tests/bench.sh`). Any codebox can be verified numerically without a hand-built scratch patch.
- **Demo patches.** Multi-module concept-teaching patches, distinct from per-module helpfiles and throwaway scratch work. Six concepts scoped (`.specify/demos/spec.md`), not started.
- **Helpfile pipeline.** Formalized 2026-07-19 (`build/spec.md` "Helpfile Generation Pipeline"). As of the last full pass: 19 current, 15 ready, 0 stale, 3 blocked (no docs). `f_sirds` deferred by choice. Generation is always in-session by hand, never via API call.
- **Vecfield consumer ecosystem.** Producers (`f_vf_vortex`, `f_vf_vortex_multi`, `f_vf_fieldmap`) and consumers (`f_caustic`, `f_vf_warp`, `f_vf_streak`, `f_vf_advect`, `f_vf_glow`) all shipped. `f_vf_scalar` (magnitude/divergence/curl/angle masking) further out — evaluate performance need before speccing.
- **`f_chladni`/`f_cymascope` audio-to-vecfield family.** `f_chladni` shipped and on the gain/mix convention. `f_cymascope` gated behind `f_vf_advect`'s multi-pix pattern (now established precedent) — no blocker left, just not started.
- **Hyperbolic/non-Euclidean geometry.** `f_mobius` shipped. `f_poincare` — see Paused/blocked. `f_apollonian` — see Paused/blocked; Poincaré's verified complex/Möbius arithmetic (now in `jit-gen-codebox` skill) should get applied back to it before it resumes. `f_ngon` forked off as an idea, not specced. `f_sharmonics` unstarted.
- **Build system generalization.** Complete: `build_patcher.py` supports `outlets`, per-inlet bypass, `pix_chain` multi-pix, `range_tiers`, `driving_inlet`. Per-module build scripts retired except where hand-built UI makes full regeneration unsafe — see the never-regenerate list just below.

  **Never regenerate via `build/build_patcher.py` — hand-edit the `.maxpat` directly:** `f_vf_warp`, `f_lens` (reproduces since 2026-10-05, could come off), `f_vf_fieldmap`, `f_vf_repulse`, `f_masonry`, `f_sirds`, `f_vf_seeds` (multistage). `f_grain` and `f_vf_advect` both came **off** this list once their `definition.py` was confirmed to reproduce the shipped patch exactly (2026-10-09 and 2026-10-05 respectively) — same path available to any module above once its drift is traced to zero. A full regen of a never-regenerate module can silently destroy hand-built UI (happened once to `f_masonry`, ~1900 lines) — surgical text edits only, verified against `git diff --stat`.
- **Temporal synthesis.** `f_vf_advect`, `f_vf_glow` done. `f_cymascope` queued behind the audio family above. `f_vf_smear` (try single-pass LIC), `f_ganzflicker`/`f_dreamachine`/`f_util_envelope` (audio/signal domain, not texture-feedback) unstarted.
- **`f_modules` menu.** Complete 2026-07-10, 8 categories, all 32 (now more) shipped modules placed; generated by `build/generate_menu.py` from `src/f_modules/menu.py`, no longer hand-maintained.
- **UI density / control surface design.** Pre-spec, blocks `f_util_matrix` refinement and composite-dial widgets. Framing (Matt): higher information density while staying legible/clickable in the dark. Five concepts sketched 2026-09-20, paused — Matt reviewing Max4Live prior art before picking a direction. `ideas/mod_depth_ui_density.md`.
- **`f_util_matrix` / mod-texture assignment convention.** Long design conclusion (2026-07-29): 2 mod-texture inlets as the working default, per-param weighted accumulation in the codebox (generalizing `f_masonry`, not an external util — that was investigated and rejected). Key open fork: `ideas/named_mod_textures.md`'s unverified alternative (tag-and-demux on a single shared inlet, extending Vsynth convention instead of breaking it) — T1 of its six scratch tests is load-bearing and untested; run that before committing to either approach. Also still open: masonry's mod inlets are unipolar, Kevin's native convention is bipolar — unresolved, current leaning is bipolar. Not specced, not scheduled.
- **Module taxonomy.** Open question, not scheduled: some modules (`f_masonry`, `f_weave`) are labeled `archetype:"processor"` but behave as self-sufficient generators. Fix concrete cases as they surface; formalize later. `ideas/module_taxonomy_standardization.md`.

---

## Parked

Lower-priority ideas and known small issues, not scheduled. One-liners; see each idea file for detail.

- `f_ngon` — regular N-gon generator/mask, byproduct of `f_poincare` Phase 1. `ideas/f_ngon.md`.
- `build_patcher.py` schema gaps — downstream-target params, `panel_toggle` mechanism (`f_lens`-class patterns). `ideas/build_patcher_schema_gaps.md`.
- Anamorphic vecfield displace/distort module — graduated out of `f_lens` v2 scope. `ideas/f_anamorph_unnamed.md`. Worth checking whether it's really distinct from `f_vf_warp`.
- `f_conformal_fill` — offline-solved arbitrary-boundary conformal tiling. Idea only.
- `f_util_profile` dual-axis output, `f_raster` supersampling/anisotropic scaling — nice-to-haves, no urgency.
- Entrainment/perceptual work (`f_ganzflicker`, `f_dreamachine`) — design research only.
- `f_vf_streak` color_shift v2 (full 2D field vector shift) — parked pending clear need.
- `f_tone_curve` real LUT-based curve — confirmed wanted, blocked on nothing in particular. `ideas/lut_curve_and_color_controls.md`.
- Godray composition (`f_vf_vortex`→`f_vf_streak`/`f_vf_glow`) — should work with zero new code, untested. `ideas/godray_radial_accumulation.md`.
- Line/mark edge antialiasing (`f_weave`, `f_masonry`) — blocked on whether GenExpr exposes screen-space derivatives (doesn't appear to, unconfirmed live). `ideas/line_edge_antialiasing.md`.
- Sketchy/uncertainty perturbation, spectral rainbow colormap (`f_vf_prism`), glow profile shaping + afterimage (`f_vf_glow`), incremental Gaussian taps (perf, unprofiled) — all idea-file-only, no urgency.
- Voronoi vs. texture-bombing "naturalness" gap (`f_grain`/`f_vf_seeds`) — grid-rigidity/cell-clipping is the real structural problem; no mechanism chosen. `ideas/seed_distribution_beyond_grid.md`.
- Known small bugs, untouched: `f_masonry` square-output-at-non-square-render; `f_hue_processor` band drag; `f_weave` unspecified visual issue.
- **Native-bypass secondary outlets** — the root cause behind the 11-module bypass rollout above: native `@bypass` skips the shader and flips secondary outlets. Documented here as the mechanism reference, not an open item.
- Bypassed multi-stage modules that keep running by design (`f_vf_advect`, `f_vf_seeds`, `f_vf_optical_flow`) — deliberate, revisit only if bypassed GPU cost becomes a real problem.
- `f_loop_to_cycle` — treat a looped clip as a WFG-like phase signal. Central open question: GPU-resident indexable frames vs. CPU seek-only playback — architecturally different answers. `ideas/f_loop_to_cycle.md`.
- `f_vf_channelmap` — direct channel-to-vecfield reinterpretation, structural inverse of `f_vf_split`. Cheap, fits the existing single-pix schema. `ideas/f_vf_channelmap.md`.
- `f_a_ripple` / `f_a_decorrelate` — audio-domain pair (tinnitus stimulus generator + pfft~ processor), specced 2026-08-04. T2 scratch-tested clean; T3 (wavetable-split optimization) inconclusive — needs a rerun at a realistic f0 (96–256 Hz), not the 5 Hz test that invalidated the last attempt. `.specify/f_a_ripple/`, `.specify/f_a_decorrelate/`, `ideas/f_a_spectral_ripple.md`.
