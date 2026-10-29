# HANDOFF

## 2026-10-29 (00:25): `f_tf_hatch` v2 (LIC renderer) BUILT, tiers 1-2 green, but LIVE OUTPUT IS WRONG (axis-aligned rectangles, not strokes along contours). START HERE for hatch; full write-up in `.specify/f_tf_hatch/findings_2026-10-29.md`

- **State:** codeboxes E1/E2/E3, `definition.py`, patcher rebuilt (commit `c141cbb`); tier 1 11/11; tier 2 exact vs the mirror on coherence-1 fields; cost 3.24 ms at 1080p (a later run read 5.21 under live GPU load, inconclusive). The mirror at Matt's exact settings draws oriented strokes, so the live defect is GPU / pipeline / real-tensor, not the design.
- **Next (one bench run, Max/Vsynth live session CLOSED):** `tests/bench.sh -q tests/modules/tf_hatch/bench_tf_hatch.py`: runs two new never-run tests (GPU `hash13` vs NumPy + directional bias; E2 vs mirror at coherence 0.5/0.2) and re-measures cost. Then a 1080p geometry test; capture a real camera tensor. Strength dial is dead in v2 (remove?). Open design question A/B/C/D (persistence curve / Persist dial / strict LIC + coherence-as-length) is in the findings doc.

## 2026-10-27 (evening): `f_vf_immiscible` SPECCED (spec, plan, tasks written; nothing built, nothing run). START HERE for the fluid thread; the `f_cmap` entry below is still current for that module (paused)

- **What exists (all docs, none committed by Claude):** `.specify/f_vf_immiscible/{spec,plan,tasks}.md` (34 tasks, Phase 0 first); `ideas/f_vf_immiscible.md` (the idea record; began as `f_vf_phase`), `ideas/f_splat.md` (new idea), `ideas/f_ca.md` (River rule from omp draft 50 folded in, plus a parked fluid-coupling section), `ideas/f_vf_emulsion.md` (banner: now the analysis record), `ideas/f_vf_mix.md` (note: first concrete consumer), `ideas/INDEX.md`, `.specify/plan.md` item 14.
- **Decisions (Matt, 2026-10-27):** a separate module, not a fork of `f_vf_fluid`; it **requires two upstream velocity vecfields**, one per phase, each from its own `f_vf_fluid`, so different viscosities are two Fluids with different dials; name `f_vf_immiscible`; a Cahn–Hilliard phase field φ blends them. Drops come from upstream (`f_grain`, and `f_splat` once it exists). Ink in water is already served by `f_vf_fluid` + `f_vf_advect`. Parked: River rule coupling, drops-on-glass rivulets, pooling water (a height-field rule, unplanned). Tensors are used only inside (the interface projector), not as inputs.
- **Correction to remember:** an earlier claim that a normal/tangential blend removes the interface divergence was wrong; the divergence integrated across the interface equals the normal-velocity jump for any output-side rule, and only stage 2 (nudging the Fluids) removes it. Spec, plan and idea file are corrected; G2 and T007 measure how large the jump is in practice.
- **Open for Matt:** G5 (bypass: neutral outlets, as the plan has it, or a passthrough of input A, which needs a fourth pix input beyond the bench's three), wanted before T020. `f_splat`: stateless pulse (recommended) versus held slots, and the trigger convention.
- **Unverified (all marked [inference]):** the Cahn–Hilliard stabilised step and its constants, the ten-stage chain against the builder (three inlets), cost (about 8 ms with two Fluids, unmeasured), and the cross-module feedback cycle for stage 2.
- **Next:** Phase 0, offline NumPy, no Max. T002 the mirror (`tests/modules/immiscible/immiscible_mirror.py`, imports `fluid_mirror`); T008 the builder check can start at any time; T005 pre-registers the thresholds before T006 (stirring) and T007 (blend divergence) run; stop at the Phase 0 checkpoint, since G7 decides whether the idea stands. No tests or benches were run this session.

## 2026-10-27: `f_cmap` (label CMAP) PAUSED by Matt after his first looks in Max (Phases 0-1 built and green; plan.md Paused section has the summary; do not resume unless he asks). The `f_quasi` entry below is still the START HERE for everything else

- **Phase 1 (evening):** `src/f_cmap/` (two codeboxes + `definition.py`), `package/patchers/f_cmap.maxpat`, `tests/modules/cmap/{test_cmap_static,bench_cmap}.py`. Bench 9/9 against the mirror (mean error 2e-8 to 1e-7; freeze, reseed, bypass and inject 1 exact; NaN guarded), contract bench and offline suite green. Gates decided by Matt: G1 label CMAP (module stays `f_cmap`), G2 rectangle, G3 power 2-4, G4 4-tap bilinear, G5 no mix, G6 Black bounds cut, G7 Scale dial in v1 (token `lscale`: `scale` is an Ob3D attribute). Record in `.specify/f_cmap/tasks.md`. Owed: the look in Max (open the patcher with a camera; `inject` ~0.3 winds the live image; Rate, Radius, Sweep, Power, Scale), real cost of the built module (T006 measured scratch shaders), helpfile / reference doc / menu placement (Phase 3), presentation layout check (Reset sits bottom left).

- **T006 (Max bench, `tests/records/spike_cmap_cost.py`):** a bare `sample()` is exactly nearest wherever the pull minifies (|q| > 0.2; 0.0000 error vs the mirror's nearest) and bilinear only near the centre, so the codebox must read the history from hand-built `nearest()` taps (new spec FR-011; the 4-bilinear-fetch bicubic trick is unusable too). 4-tap bilinear matches the mirror to 0.0002 and costs under the bench floor (<0.76 ms at 1080p); 16-tap Catmull-Rom is about 0.66 ms at 1080p, 2.4 ms at 4K (derived from a x4 amplified run; M1 unmeasured). The T004 "bilinear" numbers describe the 4-tap read, not `sample()`.

- **Built (committed):** `tests/modules/cmap/{cmap_mirror,test_cmap}.py` (9/9, 0.4 s, five mutations caught), `tests/records/spike_cmap_smear.py`, `tests/records/spike_cmap_look.py` (sheets to `tests/logs/cmap_look/`, gitignored). Full numbers in `.specify/f_cmap/tasks.md` Record (2026-10-27).
- **Findings that matter:** (1) the default look is a Julia window: the basin interior goes flat and the live image shows outside it; `inject` ~0.3 is what makes the live image wind through the interior. (2) Bilinear loses ~9% of an 8 px wave per frame, Catmull-Rom ~1%; outside |q| > 0.2 everything aliases after ~3 frames (bilinear mush, Catmull-Rom keeps contrast). Not visibly different on the smooth synthetic source. (3) float32 identity drift 2e-2 at 3000 frames on noise: `freeze` must hold `prev` without resampling. (4) `bounds` Black leaves 82% of the frame black (candidate cut); Wrap is dim but processes the whole frame. (5) The source's disk bounds would cover 44% of a 16:9 frame: use the rectangle.
- **Next:** gates for Matt (G1 name, G2 rectangle, G3 power, G4 sampler (recommend the hand 4-tap bilinear for v1; 16-tap Catmull-Rom is the affordable alternative), G5, G6 cut Black?, new G7: expose the `L` scale in v1?), then Phase 1 (T020-T023). The sheets are a synthetic source, not a camera: the real look is T030.
- **Earlier the same entry (2026-10-26, speccing):**

- **What exists:** `.specify/f_cmap/{spec,tasks}.md`, `ideas/f_cmap_feedback.md` revised (🟡), `plan.md` item 13. No code, no tests run.
- **Decisions (Matt, 2026-10-26):** for performing with live input; rectangular `z^n + w` pull only (Log dropped; a separate log-space transformer if log space keeps recurring); NO checker. Drop-in replacements: per-frame source `inject` plus a `bounds` menu (Source / Black / Wrap). Tensor field is not the core; an optional vecfield offset inlet is Phase 2.
- **Facts read from the webgpgpu source (`/Users/matt/Github/webgpgpu/examples/Example_9*.html`):** the examples never inject an image (the `seed` program is never called), so the checker was their only information source; Log's angular term jumps by an integer (3), so REPEAT wrap hides the atan seam; `|w|` sweeps -1.35..1.65 at 0.01 rad per frame (frame-rate coupled). Architecture follows `f_vf_advect` (Pattern 1: `pass` pix plus primary pix, float32, `adapt`).
- **Next:** Phase 0 T001-T003 (mirror, identity / isometry / composition tests), T004 (smear measurement, decides the sampler gate G4), T005 look stills. Gates for Matt: G1 naming, G2 bounds rectangle vs disk (proposed rectangle), G3 `power` range, G4 sampler, G5 no `mix_pct`, G6 control trim. T001-T005 are offline and good `omp` fan-out material; T006 cost needs Max.
- **Unverified:** Log mode matching `f_droste` with other constants (droste codebox not read; moot now that Log is dropped).

## START HERE (2026-10-26): `f_quasi` SHIPPED (Phase 1 built, benched, live contracts green; reference doc, helpfile, menu entry, README row done)

- **What exists:** `tests/modules/quasi/quasi_mirror.py` + `test_quasi.py` (12/12, 0.7 s; independent scalar float64 reference, finite difference, rotation covariance, four mutations caught) and four records, `tests/records/spike_quasi_{float32,gradient,wrap,nyquist}.py` (run with `uv run --no-project --with numpy python3`). Full findings in `.specify/stable/f_quasi/tasks.md` Record (2026-10-26); spec table amended (density is per frame HEIGHT, `envelope` max 0.7, drift a wrapped phase).
- **Decisions made (revisit freely):** no argument reduction (float32 error 2.6e-5 in P); `envelope` cap 0.7 (wrap residual under half an output level at bands 12, tolerance 1.5e-4 in P); **drift must be a wrapped phase** (unbounded p reaches half a level at p = 1e4); beta_k are float64 literals; renormalised Nyquist fades and a global fade rejected, a per-octave no-renorm smooth fade (0.25 to 0.5) is the candidate but irrelevant at 1080p inside the ranges, so the decision waits for the T030 small-render look and the T006 cost.
- **Not measured:** the M1 (NF-001); the module's cost is a bound under 0.21 ms at 1080p on the M3 Max. The full offline suite DID run (2026-10-26, 102 s, 57 files; green apart from the since-fixed ORDER collision and one skipped live-bench test).
- **T006 DONE (two bench runs, Max 9.2.0):** all 9 scratch variants compile; GPU potential matches the float64 mirror to 3.7e-5 over 12 cases (so no argument reduction on the GPU either); cost is under 0.21 ms per pass at 1080p (under 0.82 at 4K), below the bench's resolution, so octave skipping is not worth doing. Details in `.specify/stable/f_quasi/tasks.md` T006. The `dim` question it left open is answered by T006a (below): `dim` follows the first input's size.
- **FIXED 2026-10-26 (was: BUG IN SHARED BENCH CLIENT):** the bench has 8 chain slots (`N_SLOTS = 8`, `tests/bench/bench.js` clamps `job.chain`) and reports `chain: 8`, but `tests/lib/benchclient.py measure()` used to divide by the REQUESTED chain (`ms_per_pass = frame_ms / chain`, `ms_per_pass_upper_bound = frame_ms_k0 / chain`). Anything that requested a chain above 8 was mislabelled by chain/8: unresolved bounds, and any ms/pass from `tf_hatch` (fixed `chain=32`: a GPU-bound result is 4x too LOW) and from the 16 / 32 / 64 rungs of `bench_fluid`, `bench_wc`, `bench_wave_field`, `spike_ks_dft_cost`, `gather_proto`. Results that were GPU bound at chain 8 are right. FIX APPLIED: `measure()` divides by `result["chain"]` and keeps `chain_requested`, with unit tests in `test_benchclient.py` (mutation-checked against the old code: the new test fails on it by exactly the 4x). Callers that escalate the chain now just repeat the same 8-pass measurement (harmless, redundant). Costs recorded EARLIER from rungs above 8 are still suspect until re-measured: `tf_hatch` (fixed chain 32), and the unresolved bounds in `bench_fluid`, `bench_wc`, `bench_wave_field`, `spike_ks_dft_cost`, `gather_proto`. The `bench-test-authoring` skill (item 9) was edited again: needs YOUR re-upload then `skills/check.sh stamp`.
- **PROCESS CORRECTION (2026-10-26, after reading the skills):** the constitution and `vsynth-bpatcher` say write the codebox as `src/f_name/codebox_*.gen` and tier-2 bench THAT file before any scratch patch. T020 is now T006a in Phase 0. DONE and benched 6/6 on the first run: `src/f_quasi/codebox_quasi.gen` (placeholder dir name until G1) and `tests/modules/quasi/bench_quasi.py` (ORDER 61, registered): all three outlets within 2.2e-4 / 2.5e-5 / 2.0e-5 of the mirror, bypass / gain 0 / zoom and drift wrap exact. **`dim` in the bench follows the FIRST INPUT's size, not the render's** (render-sized input: 16:9; 4x4 stand-in: square): give the first input the render's size in any bench of a codebox that uses `dim`. The mirror's `drift` is the wrapped-turns form (12/12 offline).
- **Next:** nothing is open on `f_quasi`. Shipped 2026-10-26 (Matt: "the built module -- ship it"; the helpfile looks fine): the reference doc `docs/f-reference/f_quasi.md`, the helpfile, the Patterns menu entry (marked ∇), the README row, the inventory rows; `.specify/f_quasi` moved to `.specify/stable/f_quasi` (spec.md and tasks.md kept, as `stable/f_wc` did). Not built, by choice (listed under Known issues in the doc): the tuning pass (T030), the Relief and Slope-hue looks (T031), a Nyquist fade, a fixed-scale vecfield. Evidence: `test_quasi` 12/12, `bench_quasi` 7/7, live module contracts 2/2 (all 47 modules), contracts 9/9, drift 16/16, launch 8/8, menu 17/17.
- **Fixed 2026-10-26:** the bench ORDER collision (`bench_vf_lbm` and `bench_wave_field` both 57, the two module benches both 58) is resolved: the `f_wave_field` benches are now 62 and 63, `test_benchdeps` 23/23, and the full offline suite is green apart from one skipped live-bench test (102 s, 57 files). (The `f_wave_field` README Patches row was missing: added 2026-10-26 with a ⚠, launcher regenerated, `test_launch` 8/8; its menu placement and helpfile are still Phase 3 T040.)
- **Stale-doc warning:** this file's entries below say `f_wave_field` Phase 0 is not started and `plan.md` item 11 agrees, but git history shows `f_wave_field` Phase 0 complete (T006 cost on the bench) and Phase 1 built (`a68c9db`, T020-T022). Not updated here: not my work this session. Matt's moves of `f_dither_grain` (to `paused/`), `f_vf_lbm` and `f_wc` (to `stable/`) were committed 2026-10-26 as pure renames (`2292711`); the 37 live pointers to their old `.specify/<module>/` paths (25 files: docs, `src/f_vf_lbm/definition.py`, ideas, test docstrings, `f_vf_seeds` docs) were updated the same day. Note `.specify/f_wc` in the archived FFT-module docs and `tests/records/spike_wc_solver.py` meant the OLD FFT-chain module and now points at `.specify/superseded/f_wc_fft`. Older HANDOFF history entries below still use the old paths, on purpose.

## 2026-10-25, 17:30: `f_formconstants` is now `f_wc` (Wilson-Cowan); the old FFT-chain `f_wc` is retired

**STATUS AT CLOSE (2026-10-25, 18:35): `f_wc` is DONE. Nothing is owed on it.** Phase D closed, soak passed, README ⚠ off, helpfile checked in Max, skills re-uploaded and stamped, full offline suite 92 s green, Max module contract bench green (`bench_modules.py` 2/2, f_wc covered). The repo is clean at `4b16b5b`.

**Next (Matt's pick; no `f_wc` work is queued):** (a) `f_quasi` or `f_wave_field` Phase 0 (both specced, offline-only tasks, good `omp` fan-out material; `plan.md` items 10 and 11); (b) `ideas/f_deflicker.md`, the downstream de-flicker utility that came out of the T075 finding; (c) fix the `bench_wc_look.py` module-bench capture bug (no outlet captured though the module renders; first suspect float32 output vs the capture matrix; diff against the old `bench_wc_look` job one change at a time).

**Loose threads:** the `f-helpfile` skill checklist was not run line by line on `f_wc.maxhelp` (Matt's look in Max passed); `skills/jit-gen-codebox` and `maxpat-json-authoring` entries still name `f_formconstants` as history; `tests/records/spike_wc_character.py` and `spike_wc_habituation.py` are record-only (they import the deleted old mirror).

**Naming map (old entries below use the old names):** `f_formconstants` → **`f_wc`** (menu "Wilson-Cowan", Patterns, after Weave); the old FFT-chain module `f_wc` → **`f_wc_fft`**, archived and removed. Pix prefix `fc_` → `wc_` (`#0_wc_*`). Files: `src/f_wc/`, `tests/modules/wc/` (`wc_parity_mirror.py`, `wc_steadyweb_mirror.py` (the old steady-web reference mirror, renamed to avoid a clash), `test_wc_parity.py`, `test_wc_codebox_static.py`, `test_wc_steadyweb.py`, `bench_wc.py`, `bench_wc_look.py`), `.specify/f_wc/`, `docs/f-reference/f_wc.md`, `package/help/f_wc.maxhelp`, `ideas/f_wc.md`. **Kept on purpose:** `tests/records/spike_fc_*.py` keep their names (the tasks cite them) with imports updated; `spike_wc_character.py` and `spike_wc_habituation.py` are record-only now (they import the deleted old mirror; restore `tests/modules/wc` from `af74411` to rerun).

**Commits today (all on main):** `af74411` (T066/T068 dropped, spec "Shipped controls" table, reference doc + helpfile + inventory rows drafted, skill traps, solver-size spike), `121e321` (old f_wc docs archived to `.specify/superseded/f_wc_fft/` and `docs/f-reference/superseded/f_wc_fft.md`, banners), `10ffbc3` (old f_wc code/patcher/helpfile/tests removed; T064 dropped), `77d02c1` (the rename), plus the cleanup commit that carries this entry. Matt updated `package/examples/f_demo_wc.maxpat` for the rename and it was committed as a save checkpoint (17:45); `f_demo_wc.json` and `f_demo_ks.maxpat` mentions of the old module were not checked.

**Decisions (Matt, 2026-10-25):** the live defaults are good; T066 (drive inlet) and T068 (steady-web mode) dropped; **T064 dropped, the solver stays FIXED at 1024** (the N 512 / 1024 / 2048 look: `tests/records/spike_fc_solver_size.py`, `tests/logs/fc_solver_size.png`: same dynamics and emergence frames at every N, only the scale changes); f_wc takes the id, the old module "goes away" (archived under `superseded/`).

**Verified right after the rename (offline only; the later full suite and Max contract bench are in the status line above):** test_launch 8/8, test_generate_menu 17/17, test_module_contracts 9/9, test_drift 16/16 (f_wc reproduces exactly), test_wc_codebox_static 7/7, test_wc_parity 19/19, test_wc_steadyweb 10/10. NOT run: any Max bench, the full offline suite, the module contract bench (T030).

**Still owed:**
1. ~~Matt approves the control set~~ **DONE 17:41: Phase D CLOSED.** Phase 2 soak (T024) done by Matt live, **README ⚠ removed** (2026-10-25 17:45).
2. ~~Matt's look in Max at `package/help/f_wc.maxhelp`~~ **DONE 17:43 ("looks great").** It has no `parameters` block; the `f-helpfile` skill checklist was not run line by line.
3. ~~Re-upload the two skills~~ **DONE: Matt uploaded `jit-gen-codebox` and `maxpat-json-authoring` and `skills/check.sh stamp` was run (17:45).** (Four traps added: `Param t` never applied, dial-name vs pix attribute, `sample()` = one texel at corners, ~256-tap parser limit; the entries still say `f_formconstants` as history.)
4. T030: ~~full offline suite~~ **PASSED 17:48 (92 s)** after registering `bench_wc` / `bench_wc_look` in `tests/lib/benchdeps.py` (look = GROUP record; `bench_wc.py` ORDER 59), and re-adding the `f_wc` bypass entry in `tests/contracts/bench_modules.py`. **The Max module contract bench PASSED too (18:30, `bench_modules.py` 2/2, f_wc covered): T030 CLOSED.** `bench_wc_look.py` still has the module-bench capture bug (no outlet captured though the module renders).

**Gotcha learned:** `git mv dir existing-empty-dir` nests instead of renaming (stale `__pycache__` stubs left an empty `tests/modules/wc/` and `src/f_wc/`). Delete the stubs first.

## 2026-10-25, 11:56: f_formconstants — Phase D mostly done (superseded by the entry above; the module is now `f_wc`)

**Read first:** `.specify/f_formconstants/tasks.md` Phase D (T060–T075, each with its record). All work is committed (last `4b50f8e`); `bench_formconstants.py` 14/14, `test_fc_parity` 19/19, static 7/7, contracts 9/9, drift 16/16, all `tests/build` green. Only uncommitted file: Matt's own `package/examples/f_demo_wc.maxpat` — leave it.

**The module now (all kept by Matt live unless noted):**
- Row 1: **Depth** (`pulse_depth` 0–1.5, 0.6) · **Period** (`pulse_period` 30–600 f, 147) · **Rate** (`sim_rate` 0.05–1, slow motion by step skipping) · **P.Mix** · **P.Gain** · Reset.
- Row 2: **Grain** (`grain_scale` 0.5–2, blur tap spacing; moiré near 2 kept on purpose) · **Output** (`out_mode` RGB/E/Contour/Luma, default E) · **Input** (`pulse_space` Retinal/Unwrapped, default Retinal = the input lands where seen) · **Space** (`out_view` Retinal/Unwrapped, default Retinal; Unwrapped = the flat cortical grid, to feed f_droste).
- Header: **Freeze** (header live.toggle → nl). Pulse texture inlet (luma replaces the internal square wave; WFG-friendly). Panel 272×150, two rows (T069 layout pass 1).
- Settings groups A–E (Depth/Period/Grain) verified at N 1024 → go in the helpfile (T026), NOT a preset menu.

**Decided against / moved out (do not rebuild):** Quant menu (removed: no visible difference); Inhibit dial (narrow, wash-out kills); Flash "swing" dial and an inhibition-rate damping dial (the flash is the E–I loop's own bulk oscillation, inseparable from the pattern: `spike_fc_flash.py`, `spike_fc_damping.py`); De-flicker → a downstream utility, `ideas/f_deflicker.md`; Strike/impulse and Contrast/Sharp → downstream modules (Matt's call). T063 map (zoom/rotate/arms/spiral) ON HOLD: overlaps f_droste; the Unwrapped view covers the droste route.

**Builder changes this session:** a `header_toggle` may target one `pix_target` stage; the title-bar type label now ends left of a header toggle (both in `build/spec.md`). `f_formconstants/definition.py` DERIVES its support-stage ids (`_SUP`) and reset's route outlet from the control count — the ten-widget id shift no longer breaks its raw wiring.

**Measured GPU facts (do not rediscover):**
- **Dial-name trap:** `param_connect` names `<pix>::<dial name>`; a dial named like a jit.gl.pix attribute (`depth`) binds to it and becomes Int 0–1. Use prefixed names.
- **`sample()` does not interpolate here**: a tap on a texel corner returns ONE texel (T075 evidence). Use `nearest` at texel centres for exact maths.
- **~256-tap codeboxes break jit.gl.pix's shader translator** ("lua: stack overflow (too many captures)"), and a failed compile makes every later leg in that bench run fail.
- Quantization below 255 levels freezes the field; ≥ 255 all live.

**Next (Matt's calls, in this order):**
1. Remaining Phase D items: **T064** solver size (load-time 512/1024/2048 — design discussion first), **T066** drive inlet (likely superseded by the Retinal pulse input — decide or drop), **T068** steady-web mode (A/B or drop), **T069** finish (defaults; rewrite spec.md's Parameters table to the shipped controls). Then Matt approves the control set = Phase D closed.
2. Phase 2 soak (T024), Phase 3 docs: T025 reference doc, T026 helpfile (must include the A–E settings-groups table); README row (⚠ until docs).

**Still owed (not blocking):** skill updates — `Param t` trap, dial-name trap, `sample` = nearest, shader-length limit → `skills/jit-gen-codebox/SKILL.md` / maxpat-json-authoring (re-upload + `skills/check.sh stamp`); scan other modules for the dial-name trap / consider a builder guard; `bench_fc_look.py` module-bench capture bug (no outlet captured though the module renders).

## 2026-10-24, 18:00: f_formconstants — PHASE R CLOSED; next is Phase D, starting with the T061 design discussion (superseded by the entry above)

- **T049 done:** N 1024: 1.07 ms @ 1080p / 1.54 ms @ 4K; N 2048: 2.04 / 2.47 ms (upper bounds; f_wc 2.45 ms). Cost is not a constraint. `bench_formconstants.py` 9/9 incl. --slow.
- **Phase D direction (Matt, recorded in tasks.md above T060):** "outstanding simulation, not a performable module". Slow reset is a feature (no fix). Breathe wave + pulse are the primary performance surface: subtle dials, an external WFG (Vsynth convention, internal square wave as fallback) and a texture input. Kill-and-revive is a feature (no dead-zone guard). **MVP = regular-texture input only**; vecfield/tensor post-MVP.
- **T061 DONE and KEPT (2026-10-24 23:47):** pulse inlet (luma replaces the internal square wave, cortical space), `pulse_depth` 0-1.5 / `pulse_period` 30-600 dials, counter wrap 1e6; bench 8/8; Matt live: great. (Dial-name trap found on the way, see "Still owed".)
- **T060 DONE and KEPT (2026-10-25 00:01):** Output menu `out_mode` (RGB / E / Contour / Luma), default **E** (Matt's pick); enc only; bench 9/9.
- **Next:** T062 (quantization levels dial: A/B the look first), then T063 map, T064 solver size (design discussion first), T065-T069.

## 2026-10-24, 17:30: f_formconstants — PARITY LOOK PASSED (T048); Phase R at T049

- **T048 PASSED (Matt):** the module looks "almost exactly perfect", like the HTML page; ran 3 minutes live and stays alive. No specific difference named. **T047 closed on that live observation.**
- **T047 pre-check finding (keep):** the reference's own dynamics have a ~600-frame near-uniform transient and sub-0.05 E-std dips after emergence; the mean-E pulse is 150 frames. The adopted bench criteria (a–d) are in tasks.md and `bench_fc_look.py`. The mirror at N 256 stands in for N 1024 (mean/std within 0.014).
- **Follow-up (next bench session, not blocking):** `bench_fc_look.py` captured NO outlet output in the module bench although the module renders live → bench-side capture bug. First suspect: float32 output vs the capture matrix; diff against `bench_wc_look.py`'s job one change at a time.
- **Next:** T049 (cost: ms/frame at N 1024 / 2048, 1080p / 4K vs f_wc 2.45 ms). Then Phase D (T060–T069), one deviation at a time, starting with output mode / breathe dials. README row updated (⚠ stays: no dials, no docs). Commits through `6eac1fb` + this one.
- Still owed: the `Param t` trap line in `skills/jit-gen-codebox/SKILL.md` (re-upload + `skills/check.sh stamp`).
- Still owed (2026-10-24, T061): the **dial-name trap** -- a control's `param_connect` names `<pix>::<dial name>`, so a dial named like a jit.gl.pix attribute (`depth` was one: int 0/1) binds to that attribute and takes its type/range. f_formconstants renamed to `pulse_depth`/`pulse_period`. Scan the other definitions; consider a builder guard; add to the maxpat-json-authoring skill.

## 2026-10-24, 17:05: f_formconstants parity rebuild — Phase R at T047 (superseded by the entry above)

**Goal:** make `f_formconstants` look like `WC_Example_10_fullscreen.html`. Phase R = faithful port, Phase D = deviations one at a time. **Read first:** `.specify/f_formconstants/tasks.md` from the "REVISION 2" heading (agent brief, Phase R T040–T049, Phase D T060–T069, and the T041/T042/T046 records) and `spec.md` "Revision 2" (source facts S1–S8).

**State (all committed, last `7345ff7`):** T040–T046 DONE. Offline: drift 0, contracts 9/9, launch 8/8, menu 17/17, `test_fc_parity` 8/8, `test_fc_codebox_static` 5/5, `test_formconstants` 10/10 (steady-web mirror, retained as reference). Max (9.2.0): all six parity codeboxes compile; `bench_formconstants` 8/8 incl. `--slow` (stage legs ≤ 1 level vs `fc_parity_mirror`; 150-frame E std/mean GPU = mirror to 4 digits). The module itself (the built patcher, in a live Vsynth patch) has NOT been looked at since the rebuild; the old "flash then black" symptom was module-level.

**Next:** T047 — adapt `tests/modules/formconstants/bench_fc_look.py` (currently skips; it targets the steady-web build) to the parity module: RGB output, no dials, expect structured (E std > 0.05 through the run, mean E pulsing at ≈ 147 frames). If uniform/dead, apply the brief's live-debug rule (probe each stage output in a scratch patch; no new bench legs first). Then T048 (Matt: side-by-side vs the HTML page = the gate), T049 (cost at N 1024/2048, 1080p/4K). No Phase D work before T048 passes.

**Facts learned this session (do not rediscover):**
- The reference solver is a FIXED 1024² (`getRasterGL` reads `clientWidth` before `make_fullscreen`; Matt confirmed `maincanvas.width` = 1024). The display map MAGNIFIES the field; the old render-res solver minified it.
- Sustain: with the source's real kernel σ = (1, 2) the **`s` square wave** keeps the field alive in float32 and quantized alike; without `s` both die (`tests/records/spike_fc_parity_sustain.py`). The T002 "quantization sustains" claim was wrong (wrong σ; its port was never committed). Quantization stays for parity; whether it earns a dial is T062.
- **A Param named `t` is never applied in a jit.gl.pix codebox** (found at T046; the frame counter is `frameno`). Same family as `texture` / `bypass`. NOT yet in `skills/jit-gen-codebox/SKILL.md` (needs a re-upload + `skills/check.sh stamp`).
- `s` differs from the page's `sign(sin)` only at t = 0 and t = 1250 k (single frames; documented).
- Chain tolerance (Matt): R, G ≤ 1 level, B ≤ 3 (B = 3|E−I| triples inherited flips), A exact, ≤ 0.1% values differing; `test_each_frame_is_stage_exact_given_identical_input` proves per-frame exactness.
- Open for T047/T048: whether a fresh float32 `jit.gl.pix` output reads A = 0 (the pass stage's lost flag; loadbang reseed covers frame 1 either way). Panel is a 100×70 placeholder (reset + bypass); T069 sets the layout.
- Working-style notes: bench runs via `tests/bench.sh -q <file>` (add `--slow` for @slow); offline via `tests/run.sh -q <file>`; python with numpy via `uv run --no-project --with numpy python3`; `write_file` on an existing file needs `mode: "rewrite"`; the steady-web reference build is git `63b6129`. `package/examples/f_demo_wc.maxpat` is Matt's modified working patch: leave it alone.

## 2026-10-24 (late night, 2): f_formconstants parity build — T040–T045 DONE offline; next is the Max bench (T046)

- **T041/T042:** `fc_parity_mirror.py` + `test_fc_parity.py` (8/8, 14 s). **The T002 claim "quantization sustains; float32 dies" is FALSIFIED:** with the source's real kernel σ (1, 2) the float32 + `s` run sustains exactly like the quantized one; only removing the `s` square wave kills the field (`tests/records/spike_fc_parity_sustain.py`; T002 had used σ_I 1 / σ_E 0.69 and its port was never committed). So `s` is the liveness mechanism; quantization is kept in Phase R for parity only (look control, T062).
- **T043–T045:** six parity codeboxes (blur literals generated from the mirror), `definition.py` rewritten (fixed `@dim 1024` solver stages, no dials, `r dim` → enc only, frame counter → `t`, salt per reset), patcher rebuilt drift 0, contracts 9/9, launch 8/8, menu 17/17, `test_fc_codebox_static.py` 5/5; the two old Max benches skip. README row corrected (⚠). **Codeboxes are UNVERIFIED until T046 compiles them in Max.**
- **T046 RUN (Max 9.2.0): all six codeboxes compile; stage legs match the mirror (blur/nl ≤ 1 level, enc 8e-5); a REAL BUG found and fixed: a Param named `t` is never applied in a jit.gl.pix codebox (renamed `frameno`; the `s` wave had been stuck on).** Chain tolerance decided (R,G ≤ 1 level, B ≤ 3, per frame; an attribution leg proves every frame stage-exact). **bench_formconstants 8/8 incl. @slow: 150-frame E std/mean GPU = mirror to 4 digits.** **Next:** T047 (module look bench, adapt `bench_fc_look.py` to RGB: structured, E std > 0.05, mean E pulsing at ~147 frames) then T048 side-by-side with the HTML page (Matt); T049 cost.
- Panel is 100×70 (reset + bypass only); T069 sets the final layout.

## 2026-10-24 (late night): f_formconstants REVISION 2 — parity rebuild; read this first

- The reference page was misread: its solver is a FIXED 1024² (not render-res), it sustains on 8-bit quantization + the `s` square wave, and its bare conformal log map MAGNIFIES the field (ours minified it ~2.5×). Spec now has a "Revision 2" section (source facts S1–S8, superseded list, parity architecture); tasks.md has an agent brief, Phase R (T040–T049, parity build: fixed @dim 1024, no dials, RGB out, quantize at the three source points) and Phase D (T060–T069, one deviation at a time).
- The night entry below (live "flash then black") is NOT being pursued: T044 removes the `r dim`/sizing layer it most likely lives in. The steady-web build is the reference at `63b6129`.
- **Next:** T040 (source verification; Matt checks `maincanvas.width` in the browser), then T041–T045 offline. Any agent: read the brief in tasks.md before starting.

## 2026-10-24 (night, for fresh eyes): f_formconstants LIVE symptom unresolved — read this before touching the module

**Module status:** builds drift-0, offline suite green, codebox stage bench 8/8
PASS (blur 1.8e-7 vs exact kernel, nl 1.2e-7, enc corr 1.0000), 30-frame
host-sequenced chain frame-exact class 7.3e-5, module contract bench PASS.
**Everything at the stage and host-sequenced-chain level is verified correct.**

**Remaining symptom (LIVE, Matt's patch, after ALL fixes):** "flashes, brief
moments of noise, then all black; the rate of flashing seems directly driven
by Rate." Reloaded after the sw/sh fix (`fa7da52`), still broken. NOT YET
OBSERVED against the stage bench's evidence.

**Evidence assembled (in order):**
1. First Max try: solid black. Code audit found `nearestpix(...)` with
   normalized coords everywhere (gen pixel-vs-normalized trap) → `nearest`.
2. Then: flickering solid. Bench legs revealed: blur tap mask truncated at
   floor(3σ) vs the mirror's ceil(3σ) kernel radius (real bug, 8e-4 → 1.8e-7);
   enc-vs-mirror decorrelation was MIRROR-side (`xs/W` pixel edges vs gen
   texel-centred `norm` — fc_mirror.encode fixed, enc now corr 1.0000);
   30-frame chain divergence was BENCH-sim-side (my boxmuller() guarded only
   `na`; the codebox guards BOTH uniforms z*0.999+0.0001 — ~3e-3 cos shift ×
   30 relaxation steps; fixed → 7.3e-5). GPU proven arithmetically exact via
   a self-readout leg.
3. The solid-flicker root cause candidate shipped in `fa7da52`: seed/enc
   codeboxes used the gen `dim` global for texture SIZE in stages whose in1
   is a bang-only inlet (the jit-gen-codebox skill documents: "a codebox
   cannot read an input texture's size; manual taps need the size as a
   literal or a Param"). Fixed with `sw`/`sh` Params fed from raw
   `r dim → route dim → unpack → prepend param sw/sh`. **This did NOT cure the
   live symptom** (Matt's last report is POST-fix). Either the flicker has a
   different production cause, or dim still isn't what we think in the stages.
4. `bench_fc_look.py` (module-lifecycle snapshots at Rate 1 / Rate 0.2 over
   8s): **the field is spatially UNIFORM at all times in the module bench**
   (std ≤ 0.04 even immediately after reseed; first snapshot mean 0.937 —
   a structured hash-seed would read ~0.5±0.29). Oscillation/death timescale
   tracks Rate (r02 collapses to sat=1.000 all-black at 4s; r10 swings
   0.94→0.08→0.02→0.07). Uniform + Rate-scaled = scalar dynamics — a
   degenerate-size state (1×1-ish) in the module bench, where NOTHING emits
   the Vsynth `dim` broadcast my stages rely on for sizing (f_wc's stages all
   carry explicit `@dim 256 256`).
5. **Latest commit `67d9a07` adds explicit `@dim 256 256` to all seven stages**
   (production still resizes via the `r dim` message; the bench now reflects
   real sizes). **The look bench has NOT been rerun since this commit** —
   that's the immediate next action: if the rerun shows structured dynamics,
   the bench-uniform artifact is explained and attention goes to what's
   different in Matt's live world (his f_wc fullscreen renders prove `r dim`
   broadcasts fire there — BUT check whether it fires at LOAD reliably; the
   T013 line `r dim → delay 200 → reseed` only exists in this module).

**What is NOT yet verified anywhere:** a *structured* state at a real size
actually DYING over minutes — mirror sustains 6000+ frames at the same corner
(Ne 0.75, habit 0.9, σ 0.86px @ 1080 class). If a properly-sized module
(bench with @dim defaults) also dies, the mirror↔production disagreement is
the physics itself (then compare: salt advance? drive drv_conn? `route dim`
ordering? rate Param dt reaching nl?).

**Files to read first:** `.specify/f_formconstants/tasks.md` (full debug arc
recorded in T015, Phase 0 regime map in T003), `src/f_formconstants/`
(6 codeboxes + definition), `tests/modules/formconstants/bench_fc_look.py`
(rerun instructions in its docstring), `tests/logs/fc_look/*.ppm` (contact
sheets from the uniform run).

**Open questions for fresh eyes:**
1. Was the live symptom the seed-side degenerate noise (should be fixed by
   sw/sh + @dim defaults — needs a RELOAD in Matt's patch) or a genuine
   death-after-reseed at production size?
2. In the module bench, do the stage pix actually render at 256² now
   (readback @dim or probe state size via sw/sh vs actual)?
3. If live still dies: does `r dim` broadcast in the wrapper/Vsynth context
   reach this module's raw receiver during startup ordering (the loadbang →
   delay → reseed path races the first dim message)?

## 2026-10-24 (evening): f_formconstants BENCH GREEN — stage legs 8/8, chain 7.3e-5, debug arc closed

- Matt's first Max try: solid black → then "flickering solid black/white/gray". Five-bug arc, all resolved with the stage bench as the instrument (systematic-debugging order): (1) `nearestpix` with normalized coords; (2) blur mask floor-vs-ceil(3σ) real kernel bug; (3) **the module flicker root cause**: seed/enc codeboxes used the gen `dim` global for texture size when their in1 is bang-only (gen `dim` is not an input texture's size — the jit-gen-codebox skill documents this rule; fixed with `sw`/`sh` Params fed from `r dim → route dim → unpack`); (4) the enc bench decorrelation was **mirror-side** (fc_mirror.encode used pixel-edge `xs/W` where gen `norm` is texel-centred — fixed, enc now corr 1.0000); (5) the chain divergence was **bench-sim-side** (boxmuller guarded only na; the codebox guards both uniforms). GPU was arithmetically exact in every case — proven via a self-readout leg (gpu nx vs float64-of-its-own-readback: 1e-6).
- **Bench 8/8 PASS**: blur 1.8e-7 vs exact kernel; nl 1.2e-7 single-step; enc 2.2e-4 corr 1.0; 30-frame chain 7.3e-5. Contract bench PASS (loads, frames, params, no unexpected errors). Drift 0, offline suite green. Commits ...d84 → fa5c56f.
- **Left in Phase 1**: T017 (drive-imprint leg), T018 (cost measurement at 1080p/4K/320² — the module's whole pitch is per-pixel work, this number gates viability at 4K).
- **Phase 2 is now unblocked (tier-3, live with Matt):** AB vs the HTML page, GRAIN/ASPECT ranges + landmarks (the T003 map predicts the steady band), rate ceiling, map corner (T004 stills said closer 5/3/1.0), G2 soak.
- Also outstanding from today: the module hasn't been LOOKED at since the dim fix — Matt to reload and gate the web visually.

## 2026-10-24 (late afternoon): f_formconstants Phase 0 CLOSED — Example-10 constants measured dead; ships Psychedelic+habituation "steady dark web"

- Phase 0 experiments overturned the spec's constants: **WC_Example_10_fullscreen is Rule's *flicker* preset** (Ne=0 + slow square-wave `s`) — at float32 it dies in every configuration; only a faithful 8-bit-quantized+s port breathes. The float32-native sustaining corner (N=512/1024, 4000–6000-frame soaks): **Psychedelic couplings (16.1/14.5/13.7/13, He 3.1, Hi 3.5, Te 4, Ti 12.5) + Ne 0.75 + habituation** — and habituation is LOAD-BEARING (saturation by ~3k frames without it, matched to f_wc's T052 mechanism). f_wc Psychedelic-at-fine-grain also saturates without habit — the webgpgpu pages are all transient aesthetics.
- Regime map (σ_I px × habit): **steady band σ_I 0.75–1.1 px × habit 0.9–1.2**, dark-field silk, λ 16–43 px dynamics-set (not kernel-set); habit 0.2–0.45 pulses rhythmically. Resize finding: frame-fraction λ was the wrong target — features are pixel-scale by design; NF-005 amended to regime-independence via a σ_px band clamp [0.75, 1.4].
- **Gates answered (Matt):** G0 = steady dark web corner (stills `scratch/fc_enc/steady_s*`, pulsing white family reachable at habit ~0.2); G1 = habituation ships, default 0.9.
- Tier-1 mirror + tests 10/10 green at the shipped corner (`tests/modules/formconstants/`). Spec amended (FR-002, FR-003, NF-005, params); plan.md item 12 current.
- **Next: Phase 1 — T011 FIRST** (build-system check: the first adaptive-res feedback pix_chain; f_ks/f_wc solver stages are all fixed 256²), then T012–T014 codeboxes+definition (offline), bench/cost with Matt (T015–T019).

## 2026-10-24 (afternoon): f_formconstants SPECCED — render-res WC sibling born from the f_wc pixelation post-mortem

- The pixelation discussion traced the whole arc (CR fix → failed SSAA) and then read the ACTUAL `WC_Example_10_fullscreen.html` source + `gpgpu.js`/`gpugaussian.js`: their smoothness is STRUCTURAL (solver grid = display grid, separable-Gaussian blur σ_E1/σ_I2 px, 8-bit quantized state, bare-log map, continuous non-thresholded display). Re-reading failed SSAA commit 0589d14 found it structurally unable to help: quarter-SCREEN-pixel offsets against a ~7-screen-px/texel artifact, averaged pre-threshold. SSAA work item reframed in f_wc tasks remains parked; the fine/silky look needs a different architecture, not enc polish.
- **Matt's calls:** their look is the target (fine/silky; color not essential); NEW SIBLING (f_wc ships unchanged); Example-10 constants (10.5/8.5/12/3, He 2, Hi 3.5, Te 10, Ti 20) as defaults; name **`f_formconstants`**.
- Written + committed: `ideas/f_formconstants.md`, `.specify/f_formconstants/{spec,tasks}.md` (30 tasks; Phase 0 offline: mirror + the load-bearing T002 sustain-at-float32-without-noise measurement, λ(σ) calibration, look stills, resize invariance; gates G0 defaults / G1 habituation), plan.md item 12, INDEX entry. Deliberate departures from the source: float32 state, pattern scale in frame-height units (their resize-couples-physics fixed), r_soft retained, `Ne` measured not assumed.
- **Next:** Phase 0 T001-T005 (offline, good omp fan-out material minus the gates), then Phase 1's T011 build-system check (first adaptive-res feedback pix_chain — f_ks/f_wc stages are all fixed 256²).

## 2026-10-24 (session break): housekeeping — scratch/ + archive/ gitignored, plan.md item 8 current

- `/scratch/` and `/archive/` are now gitignored and untracked (files stay on disk; references in records remain valid as on-disk paths). `f_demo_ks`/`f_demo_wc` example maxpats are Matt's untracked work patches, left alone.
- plan.md item 8 (f_wc) now carries the 2026-10-23/24 expansion summary (Phase 4, G5-G8 dials, display fixes, reverted SSAA, bench debt). (A script bug truncated plan.md mid-edit; restored from git and re-applied — the accidental delete commit e05c1b9 contains no other changes.)

## 2026-10-24 (noon, session break): enc reverted to proven cubic; session checkpoint

- Matt called a break. Everything committed: enc reverted to the verified CR build (2d9174c), records updated, proof renders in scratch/wc_enc/ now tracked. **Left on the table deliberately:** f_demo_ks/f_demo_wc maxpats are Matt's working patches (untracked, per the long-standing note); SSAA is parked as bench-session work.
- **When you come back, the bench session owes:** (1) the habit > 0 chain-vs-mirror leg (mirror m_step takes be=bi=habit); (2) live look at the six new dials; (3) SSAA-in-Max (compile + readback, small steps, verify each); (4) the full offline suite (tests/bg.sh start offline) — several rebuilds happened without it; (5) enc-vs-mirror bench now runs the CR sampler — old 4-tap tolerances retired. Cost question if edge blocking still bothers: solver 512², measure before deciding.

## 2026-10-24 (noon, LATER): enc REVERTED to the proven single-eval Catmull-Rom build

- The SSAA variants never worked live: function form → field rendered 4-fold mirrored; inline ×4 with sqrt+two-arg-atan → still 4-fold; cartopol restored → 2-fold. Cause never isolated; offline cannot compile-check GenExpr, so every iteration burned a Max reload on a guess. REVERTED `codebox_enc.gen` to commit fbee342's verified working cubic (the "this is better" build), header fixed (it still said the un-softened map in one line).
- **Rule now recorded twice and hard:** GenExpr changes beyond trivial expression edits are bench-session work — compile + readback in Max or don't ship. SSAA is parked as bench work (tasks.md).
- Reload now renders the working CR output (soft contours, foveal softening available via r_soft on the bench).

## 2026-10-24 (noon, hotfix b852d9d): SSAA function form boxed BLACK## 2026-10-24 (noon, hotfix b852d9d): SSAA function form boxed BLACK — inlined ×4 instead

- The `mapE(nx,ny)` GenExpr function failed on load (module black). The inlined 4-copy version is now shipped (every construct precedented: dim.x/dim.y per f_grain/f_masonry, nearest/wrap/vec per the working cubic build). **Lesson for codeboxes: no multi-assign or function-refactoring in jit.gl.pix codeboxes without a Max session to compile-check — the offline path can't catch it.**
- Reload check owed to Matt: module should render with 2x2 AA. Patcher rebuilt; drift + contracts + test_wc green.

## 2026-10-24 (noon): f_wc enc now 2x2 SSAA## 2026-10-24 (noon): f_wc enc now 2x2 SSAA over the Catmull-Rom taps

- Matt: "better, but still blocky around the edges." Diagnosis: with the values smooth, the remaining stair is CONTOUR-position quantization — near-binary fields on a 256² grid have edges pinned to texels. enc now averages mapE at 4 quarter-pixel offsets per output pixel (SSAA; GenExpr function form, mirror refactored identically — offline green). If still steppy live at high Sharp: the ceiling is the 256² solver itself → 512² is a cost question (2.45 ms @256² measured; unmeasured at 512²) for the bench session.
- Bench debt: chain-vs-mirror habit leg, live looks, enc leg now diffs cubic+SSAA.

## 2026-10-24 (late morning): f_wc enc sampler upgraded## 2026-10-24 (late morning): f_wc enc sampler upgraded — Catmull-Rom 4x4 (pixelation fix)

- Matt's 1920x1080 grab showed ~30px blocks with sharp 0 — the enc bilinear's C0 facets (not upscale, not Sharp). Now: bicubic `codebox_enc.gen` (inline CR weights — caught a weight-bug via test_wc's radial-constancy test mid-ship; weights now verified sum-1), mirror `_tap16` matching, proof render `scratch/wc_enc/cubic_c1.png` smooth. Bench note: enc leg now diffs a CUBIC sampler. r_soft stays bench-vary (message `#0_wc_enc` `param r_soft 0.35` for the calm disc; 0.0 = the parity-vortex look).
- f_wc now at 15 controls; all named offline checks green.

## 2026-10-24 (mid-morning, later): f_wc G8 SHIPPED## 2026-10-24 (mid-morning, later): f_wc G8 SHIPPED — `contrast` dial + `aie`/`aii` coupling dials

- Both Matt-approved. **contrast** (0.5–8.0, def 1.0, bit-neutral): mid-gray stretch in enc before Sharp — rescues faint regimes (spots, low energy) and counters soak wash. **aie** / **aii** (Inhibit / I-Inhibit): the couplings, exposed after a proper sweep (spike_wc_couplings.log). Verdict: SPOTS = aii 3.0–6.0 at aie 11–14.5 (dark field, robust, both seeds); aie < 8 = whiteout; aii > 9 = labyrinth family. The html Example-10 corner (aii 3 + aie 8.5) does NOT transfer at our stronger Aee — spots here live at aii 3–4 with aie kept high.
- 14 dials now; positional pix refs shifted obj-56/57 → obj-65/66 (fixed, contracts 9/9). Helpfile list 17 rows, docs updated.
- **Try:** Inhibit 12–14.5, I-Inhibit 3–4, Grain 1.0–1.2, Contrast 3–6 → the Example-10-style dark dot field. If washed again, push Contrast up rather than Excite (excite moves the physics, contrast only the display).
- Bench debt unchanged and growing (chain-vs-mirror habit leg; live look at the new dials; full offline suite).

## 2026-10-24 (mid-morning): f_wc HTML-parity map config shipped for AB comparison## 2026-10-24 (mid-morning): f_wc HTML-parity map config shipped for AB comparison

- "Theirs looks noticeably better" — map math: WC_Example_10's display pass is the bare complex log (`atan`/`log(length)`: ~1 wrap/rev, ~1 wrap radial) vs our retuned 5/3/1.0 (~2.8 wraps, 3 spokes) → their shapes read ~3x bigger. Shipped parity defaults: **zoom 1, twist 1, fovea 0.003, r_soft 0.0** (ranges widened: zoom 1–16, twist 1–8, fovea 0.001–5). Mirror render reproduces the demo character (`scratch/wc_enc/html_s000_sharp.png`). For the live AB: Energy 0.75 (their Ne) on top.
- **After AB, Matt decides the ship corner:** parity bare-log / closer 5/3/1.0 / plus r_soft 0.35 for the center disc. r_max (4 vs their 1.41) is still baked — the real field-of-view lever if needed.
- Prior notes this morning: center softening fix (a232930, r_soft now defaults 0 for the parity pass — flip back if the calm disc wins), closer retune (e6f431f).

## 2026-10-24 (morning, later): f_wc center pixelation FIXED## 2026-10-24 (morning, later): f_wc center pixelation FIXED — foveal softening in enc (r_soft = 0.35)

- Matt's screenshot showed the retinotopic center breaking into an aliased vortex. Cause: the log map's du/dr = k_ecc/(r0+r) diverges at r → 0, compressing cortical periods past render Nyquist — the 4-tap bilinear can't reconstruct them. Fix shipped: `u = k_ecc·ln(1 + sqrt(r² + s²)/r0)` in `codebox_enc.gen` (`r_soft` = 0.35, a bench-vary Param registered known-undriven in the contract test; mirror encode + T051 inverse updated). Center becomes a calm disc for r ≪ s; periphery untouched.
- **Owed to Max:** reload and eyeball the center at fine grain (1.1–1.4) and deep fovea; if angular speckle remains, next step is 2×2 supersampled enc taps. r_soft is sweepable on the bench (`param r_soft` on `#0_wc_enc`); expose as a dial only if it wants performable depth.
- NOTE: the shipped module defaults are now zoom 5 / twist 3 / fovea 1.0 but the MIRROR constants (K_ECC 8, K_ANG 5, R0 0.5) still record the T033 corner — the bench enc leg must pass the module values as kwargs (encode() already takes them).

## 2026-10-24 (morning): f_wc map defaults retuned CLOSER — zoom 5 / twist 3 / fovea 1.0

- Matt's live report: at the T033 corner (8 / 5 / 0.5) the scene reads far away — expected from the map math (~2.8 cortical wraps radially; k_ang 5 ≈ 3.4°/spoke). Shipped the closer default set **zoom 5, twist 3, fovea 1.0** (~1.3 wraps radially, ~1.7x wider spokes); ranges unchanged (zoom 2–16, twist int 2–8, fovea 0.1–5.0). Codebox literals, spec FR-007, reference rows and hints aligned; drift + contracts green.
- Try live: twist 2 for ~2.5x-wider spokes than the old corner, zoom toward 3 for still-bigger fields. `r_max 4` is the true field-of-view and stays baked — exposing it is the next lever if this still isn't close enough.
- Bench session debt unchanged (habit > 0 chain-vs-mirror leg; live look at the new dials). Full offline suite not run since rebuild.

## 2026-10-23 (night 14): f_wc map dials SHIPPED — zoom / twist / fovea (T033 no-exposure reversed); 11 dials now

- Matt asked for zoom: **`zoom`** (k_ecc 2–16, def 8), **`twist`** (k_ang INT 2–8, def 5 — integer-only; fractional = seam at θ = ±π, T006), **`fovea`** (r0 0.1–2.0, def 0.5), all in `codebox_enc.gen`; `r_max 4` stays baked. Mirror `encode()` gained kwargs. Panel → 247×212 (menu `"wc": [247, 212]`, launcher regenerated).
- Positional-id trap again: adding the 3 dials shifted the raw pix references seed/pass obj-51/52 → obj-56/57; caught by test_module_contracts (reset/salt undriven), fixed, 9/9 green. This is the third time — worth a named anchor in the raw wiring if a 4th dial row ever appears.
- **Offline green:** drift 16/16, contracts 9/9, launch 8/8, menu 17/17, test_wc 10/10. **Owed to Max (one bench session):** live look at all six new dials (energy/habit/aspect/excite/zoom-map trio) + the G5 habit > 0 chain-vs-mirror leg. Full offline suite not run since rebuild — `tests/bg.sh start offline` before the next unrelated edit.

## 2026-10-23 (night 13): f_wc G6 + G7 SHIPPED — `aspect` and `excite` dials; module now has 8 dials + reset + bypass

- Matt approved both tier-2 dials. **`aspect`** (σ-ratio `sig_ratio`, 1.2–2.2, def 1.45) in the `spec` codebox — hexagons at 1.3 × fine grain, hot rolls 1.7–2.0, saturates ≥ 2.5. **`excite`** (−0.3..+0.8, def 0) in `nl` — a shared `+ excite` offset inside both sigmoid inputs (sign-flip vs the sweep's bias: sweep b = −excite; clean rolls at +0.5, toward blackout below −0.3). Mirror `Params.excite` maps `he/hi = P.he/P.hi − P.excite` for bench parity.
- Dial row order: rate / grain / aspect / drive / energy on row 1, habituation / sharp / excite on row 2 (panel stays 247×150); the raw `reset` route wire moved outlet 6 → 8. Spec FR-002 (ratio un-baked) + FR-003 (excite amendment) + Parameters updated; reference doc, definition docstring, helpfile (11-line control list, references block shifted) updated.
- **Offline green:** drift 16/16, contracts 9/9, launch 8/8, menu 17/17, test_wc 10/10. **Owed to Max (one bench session):** live look at aspect/excite/energy/habituation; the G5 habit > 0 chain-vs-mirror leg. Full offline suite not run since rebuild.

## 2026-10-23 (night 12): f_wc `energy` dial shipped; tier-2 sweep ranked Aspect + Excite (gates G6/G7 staged)

- **`energy` (Ne) exposed**: 0–2, default 1.0, between Drive and Habituation (dial token `energy`, `pix_attr ne`; panel grew to 247×150 with a second dial row; raw reset route wire moved outlet 5 → 6; `ne` removed from the contract known-undriven list). Docs + helpfile updated. Offline green (drift, contracts, launch, menu, test_wc).
- **Tier-2 sweep measured** (`tests/records/spike_wc_character.py`, mirror parametrized for sig_ratio + he/hi): **σ-ratio is a strong safe character axis** (1.3 = hexagons at fine grain — the morphology G1 ruled out as a selector; 1.7–2.0 = hot healthy labyrinth; 2.5 = saturating) → candidate "Aspect" dial 1.2–2.2. **Threshold bias is a narrow excitability axis** (−0.5 = strong clean rolls; ±death outside ~−0.8..+0.1) → candidate "Excite" dial −0.8..+0.3. Both default-neutral to ship. **Staged as gates G6/G7 in tasks.md — Matt's call.**
- **Owed to Max (one bench session):** live look at the new dials; habit > 0 chain-vs-mirror leg (from G5). Full offline suite not run since rebuild — `tests/bg.sh start offline`.

## 2026-10-23 (night 10): f_wc G5 SHIPPED — `habituation` depth dial built and registered

- Matt approved G5 (depth dial). Built: `habituation` 0–1, default 0, between Drive and Sharp (dial token `habituation`, `pix_attr habit`; panel 210 → 247, menu/launcher regenerated, `"wc": [247, 110]`). `codebox_nl.gen` carries Ve/Vi in state G/A (relaxes toward the rates at baked 50/100-frame constants, subtracts `-habit*Ve/-habit*Vi`, pins G/A to 0 at habit 0 → pre-G5 dynamics bit-preserved); `codebox_pass.gen` carries G/A with the NaN guard and restarts them at 0 on reseed/self-heal. Spec FR-003 + Parameters, `docs/f-reference/f_wc.md`, and the helpfile (control list + bpatcher embed) updated.
- **Offline green:** build/drift 16/16, module contracts 9/9 (one fix: the raw `reset` route wire moved outlet 4 → 5 when the dial was inserted — the f_vf_lbm stale-id trap pattern), launch 8/8, menu 17/17, test_wc 10/10. Full offline suite NOT run since the rebuild — run `tests/bg.sh start offline` before the next unrelated edit.
- **Owed to Max (one bench session):** live `habit` sweep look (expect steadier mean / tighter contrast per T052; low-drive band narrows) + a habit > 0 chain-vs-mirror leg in `bench_wc.py` (`m_step` takes `be=bi=habit`; zero-depth legs unchanged). Next after that: f_quasi or f_wave_field Phase 0 per `.specify/plan.md`.

## 2026-10-23 (night 9): f_wc Phase 4 T050-T052 DONE — only gate G5 (Matt) remains

- **T050/T051 (tier-1 hygiene, in `test_wc.py`, 10/10 green):** the shipped hash noise stream is clean — 4-channel histograms chi2 8-14 on 15 dof, ≤ 6e-3 spatial lag-1 corr, ≤ 2.7e-3 frame-to-frame corr, Box-Muller kurtosis 3.03. Retinotopy map→inverse identity: mean err 6.5e-3 / p95 2.0e-2 in the supported eccentricity band (100% of the sheet covered via u-wrap copies).
- **T052 (habituation spike, `tests/records/spike_wc_habituation.py`, 21 s):** mirror now carries Ve/Vi in state G/A when depth ≠ 0 (zero depth stays bit-tied to the shipped chain; pass-stage carry-through is priced as the only structural cost if exposed). (be/bi × Ne) sweep at 128²/1200 frames: **adaptation is survivable** — Ne 1.0 stays inside the band at every depth 0-1.0 (the doom case the ideas doc warned about did not show); adaptation DAMPENS the E-mean drift where it exists (Ne 1.2: +0.064 → +0.001) — the mechanistic fix for the soak drift that G4's sharp=0.5 patches — and moderate depth (0.5-1.0) IMPROVES contrast at the shifted band (0.30 vs 0.25). Cost: the low-Ne cells (0.6) die under adaptation. Caveats: one seed/cell, 128², coupled be=bi, ae/ai only 50/100.
- **G5 staged for Matt in tasks.md:** expose a habituation DEPTH dial (0-1, default 0 = shipped dynamics; rate dials not recommended — ae/ai untested off 50/100) or drop. If go: pass carry-through + reseed init of G/A, nl params be/bi, one bench leg, live look. Next candidate if dropped or done: f_quasi or f_wave_field Phase 0 per `.specify/plan.md`.

## 2026-10-23 (night 8): f_wc Phase 4 drafted from the webgpgpu ideas doc — T050-T052 + gate G5 queued

- Discussed `ideas/f_wc_from_webgpgpu.md` against the shipped module with Matt. Outcome (committed): Phase 4 in `.specify/f_wc/tasks.md` — T050/T051 offline tier-1 hygiene (noise-stream histogram + temporal decorrelation of the salt-incremented hash; retinotopy map↔inverse round trip), T052 habituation mirror extension + (be/bi × Ne) mini region map at the shipped corner, gate G5 (Matt): expose depth/rate dials or drop. Parked with reasons: the Rule-page stats fixture (mirror already derives from the page-validated model) and a shared `f_rng`/retinotopy module (no second consumer; solver noise must live inside the 256² loop).
- **Structural fact verified against the shipped codeboxes:** state texture G/A are free (`codebox_pass` forces them 0 as DFT imaginary parts; `nl.in2` taps raw pre-DFT state), so Ve/Vi adaptation fits with a pass carry-through and ~4 ALU ops in nl — no extra texture. The real risk is behavioral: Ne is baked at 1.0, and subtractive adaptation on the saturation boundary may shift the usable band; T052 measures band width and E-mean drift (adaptation may fix what G4's sharp=0.5 patches).
- All Phase 4 tasks are offline; no bench session needed until G5 decides. Ideas doc flipped to 🟡 partially promoted.

## 2026-10-23 (night 7): f_wc Phase 3 COMPLETE — module shipped (G2: names stayed `f_wc` / "Wilson-Cowan")

- **G2 decided by Matt:** keep `f_wc` / "Wilson-Cowan" (no rename). T040 doc `docs/f-reference/f_wc.md` (settled model, gates, notes, verification). T041 helpfile `package/help/f_wc.maxhelp` (generator layout, drive bubble, refs in sync). T042 menu: "Wilson-Cowan" in Patterns after Weave (menu + addmod regenerated); T043 README row finalized (no ⚠), `ideas/INDEX.md` 🟢, `.specify/plan.md` item 8 BUILT and SHIPPED.
- Build tests green (`test_generate_menu`/`test_launch`/contracts/bench_expect); drift 0. Full module contract bench running in background against the final patcher set as the last sanity before calling it shipped.
- **f_wc is DONE**: all 4 phases closed (spec settled 2026-10-22 → Phase 0 model via Rule reference + G1/G3 → Phase 1 GPU chain mirror-diffed + contract bench → Phase 2 tuning with Matt → Phase 3 docs/registration). Next candidate: per `.specify/plan.md`, **f_quasi Phase 0** or **f_wave_field Phase 0**.

## 2026-10-23 (night 6): f_wc Phase 2 COMPLETE — Matt settled G4 + all of T030-T033

- **G4 / output map:** plain E + the `sharp` S-curve blend, SHIPPED DEFAULT sharp = 0.5 (soak showed the soft map drifts toward white over 30 s). No special encoding; T008's comparison item is overtaken by the gate decision.
- **Ranges (approved):** `rate` 0–1 (def 1.0), `drive_gain` 0–2 (def 0), `grain` 1.0–4.0 (def 1.4) continuous.
- **T031 landmarks:** σ_I = **1.1 / 1.4 / 1.9** (broken stripes / labyrinth / coarse), in the grain dial hint + T040 documentation. **T033:** provisional retinotopy constants ACCEPTED (r0 .5, k 8/5, r_max 4; no foveal special-casing; no user exposure). **T032:** "see" ≈ 1.5 documented in the drive hint.
- Codebox `Param sharp(0.5)` + definition updated, hints carry the landmarks; rebuild reproduces exactly, offline contracts green (bf8ebbe + this).
- **Next: Phase 3 — G2 naming FIRST** (blocks README row text, menu, reference doc, helpfile), then T040 ref doc, T041 helpfile, T042 menu, T043 README/INDEX/plan.md.

## 2026-10-23 (night 5, Max bench): f_wc Phase 2 measurement session done — T030-T033 decisions staged for Matt

- **New instrument:** `tests/modules/wc/bench_wc_look.py` (parametric `segments` timeline added as a branch in `tests/bench/bench_module.js` — legacy module jobs unchanged) + contact sheets in `tests/logs/wc_look/*.png`. One 55 s job on the shipped module at 512².
- **Soak:** contrast grows 0.059→0.122 over 30 s, zero saturation (NF-003 holds). KEY FINDING for G4: the E-mean drifts over time — 4 s dark+knots, 30 s bright+dark-knots; plain E display washes toward an extreme. Candidates: mean/contrast-normalized display or higher default `sharp`.
- **Grain sweep 1.1→3.5:** displayed contrast 0.12→0.03; fine grains = fine central speckle; coarse grains (2.6+) wash out under the provisional retinotopy. Physics-vs-display is a T033 live question.
- **Drive imprint (drive_gain 0→1.5→0):** corr vs map-warped scene −0.00 → **0.83 in 0.25 s** → 0.64/0.71 sustained → 0.01 at +1 s after off. Imprint legible, release clean.
- **Decisions for Matt (Phase 2, live):** T030 output map (G4) + rate/grain defaults per the soak finding; T031 landmark snaps (depends on G4); T032 "see"-gain default + range labels; T033 retinotopy constants (periphery currently sub-resolves fine grains). Then G2 naming + Phase 3.
- Bench status: everything green (offline suite, bench_wc 10/10, contract 2/2, drift 0).

## 2026-10-23 (night 4, Max bench session): f_wc Phase 1 COMPLETE — all legs green on Max, including the live module contract bench

- **`tests/modules/wc/bench_wc.py` written (the bench_ks template), 10/10 PASS incl slow:** stage compile, seed statistics (R/G reseed channels independent), 4-field DFT chain vs np.fft (1e-5 of peak), pass reseed/hold/self-heal exact, spec gains vs mirror (1e-4), nl vs mirror (1.2e-7) + containment, enc vs mirror (256² 5.2e-6; rectangular renders 1e-4 tol = float32 map-coordinate ulps), 30-frame chain vs mirror **4.1e-6** (flat, no fast divergence), @slow 100-frame contract: contrast 0.226 GPU vs 0.226 mirror (mechanism intact on the real chain), @slow cost: **2.45 ms/frame total** (f_ks class — ONE shared DFT chain carries both fields), → **256² solver, 128² fallback dropped (T024)**.
- **Module contract bench green (2/2):** param routing readbacks exact (dt / sig_i / drive_gain / sharp), bypass → black A=1, 10 pix. Two offline-bench catches fixed on the way: (1) the mirror's retinotopic 4-tap was half a texel off the codebox's texel-center index (3.2e-2 err); (2) the codebox bench wires at most 3 inputs, so the nl drive test runs at the black-inlet point (drv=0, drv_conn=1) and the connected-scene case is covered by the contract bench instead.
- **REAL BUG FOUND ON THE LIVE BENCH — the word `texture` is unusable as a control token on a pix-targeted param.** The builder wires `param_connect` as `<pix name>::<param name>`; for `texture` that binds the dial to jit.gl.pix's NATIVE @texture attribute (a texture-name list), which rejects the numeric value and snaps the dial back to min. Renamed the FR-010 dial's token to **`grain`** (label stays "Texture"), spec FR-010 + param table + G1 record amended. Rate/drive/sharp worked because their tokens don't collide with native pix attributes.
- **Two settled constants registered as known-undriven Params** in test_module_contracts.py (`#0_wc_nl.ne`, `#0_wc_pass.amp` — bench-vary only, the f_ks `amp` precedent).
- Phase 1 checkpoint in tasks.md records everything; **Phase 2 (tier 3, Matt) is next:** T030 output mapping/G4 + rate/grain ranges live, T031 grain-sweep feel, T032 drive-transition feel, T033 retinotopic look. Then Phase 3: G2 naming FIRST (blocks menu/README), T040-T042, README row text.

## 2026-10-23 (night 3): f_wc T025 offline half DONE — patcher builds, drift 0, offline suite green

- **`src/f_wc/definition.py` written (modeled on f_ks) and `package/patchers/f_wc.maxpat` BUILT: drift 0** (`1 of 1 reproduce exactly`), `test_module_contracts`, `test_launch`, `test_generate_menu`, `test_wc` all green. Params: `rate` (dt→nl, default 1.0 = the validated regime), `texture` (1.0–4.0, default 1.4, → spec's `sig_i`), `drive_gain` (0–2, default 0 → nl), `sharp`, `reset`, bypass. Ne BAKED at 1.0 — no dial (not in the spec's param table).
- **Build-time finding that corrects a G3 assumption:** an unconnected `jit.gl.pix` inlet reads BLACK (0,0,0,1), not mid-0.5, so "unconnected = 0.5 neutral for free" was wrong. The drive inlet runs through a vs_inState (`mod_inlets` entry with `fanout` [["nl", 3]] + `state_nodes` ["nl"] + `state_param` "drv_conn") and the nl codebox substitutes 0.5 when unconnected. Spec FR-006 and the G3 task record corrected.
- **Salt increments EVERY DRAW** ([r draw] → [i]/[+1] counter → `prepend param salt` → seed); the same counter drives the reseed-drop sel-2. Object ids came out identical to f_ks's (seed obj-51, pass obj-52, enc obj-5); the built patcher has 0 dangling patchlines.
- **Registration (earlier than planned):** f_wc is in NOT_IN_MENU with the reason "the menu entry is T042 (Phase 3)", plus a README row at ⚠ ("Wilson-Cowan hallucination generator: a noise-sustained living labyrinth; drive inlet in") and a regenerated launcher (50 modules, 9 ⚠) — required by `test_launch`/`test_generate_menu`, which validate every shipped patcher. T043 remains: INDEX flip, plan.md item 8, naming G2, and a real README description if wanted. Panel 210×110 is provisional (T030/capture).
- **Owed to Max (all in one bench session):** T021/T022 bench legs (stage + enc vs mirror), T023 (frame-exact chain vs `run_temporal` with the hash-stream helpers), T024 (cost; ONE chain ≈ f_ks class), T025's live contract bench (bypass → black A=1).

## 2026-10-23 (night 2): f_wc Phase 1 — all six codeboxes written (T021/T022 written, bench leg owed to Max)

- **`src/f_wc/` has the full stage set:** generated `codebox_dft_{fx,fy,iy,ix}.gen` (T020) plus hand-written `codebox_seed.gen`, `codebox_pass.gen`, `codebox_spec.gen`, `codebox_nl.gen`, `codebox_enc.gen`, all written against `tests/modules/wc/wc_mirror.py` (7/7 green) and the jit-gen-codebox skill. Design facts: the noise stage's `salt` increments EVERY DRAW (one counter from `r draw`, both reseed channels and Box-Muller uniforms — the per-frame mechanism; simpler than f_ks's per-reset counter); the spec codebox param is `sig_i` (`texture` would collide with the GLSL builtin — the definition maps dial → param); nl is 4-inlet (convolved, raw state, noise, drive) with Box-Muller×√dt into both sigmoid inputs and the E-only drive term; enc bakes the provisional map constants (T033 decides exposure). Mirror grew `hash_noise_tex`/`seed_from_hash`/`nx_from_hash_tex` (exact float32 Hash port) so T023 can feed the mirror the GPU's own noise stream.
- **Still owed, all need Max (Matt's bench):** T021/T022 bench legs (stage-by-stage + enc vs mirror), T023 (frame-exact chain run; noise stream → statistical comparison after frame 1, FMA-caveat noted), T024 (cost; ONE chain ≈ f_ks class), T025 (definition.py, build, drift, offline contracts — build/drift halves are offline-doable next session).
- Not committed: nothing — everything committed as the T021/T022-written checkpoint.
- **Next session(s):** T025's offline half (definition.py modeled on f_ks, build, drift 0, offline contracts, README/menu left for Phase 3), then hand to Matt for the bench legs (T021/T022/T023/T024 + module contract bench).

## 2026-10-23 (night): f_wc Phase 1 groundwork — T020 DFT factoring + tier-1 mirror done; spec rewritten to the settled model

- **T020 done, decision recorded in tasks.md:** `src/f_vf_fluid/gen_dft.py` IS the shared DFT generator; f_wc got a third adapter `src/f_wc/gen_dft.py` (same shape as f_ks's, code-line assertion, packing comment changed to `R,G = Re,Im of E-hat; B,A = Re,Im of I-hat`). No template move, no copy. Four codeboxes generated; ONE chain carries BOTH fields.
- **Tier-1 mirror done:** `tests/modules/wc/wc_mirror.py` + `test_wc.py`, from the SETTLED model (per-frame noise in BOTH sigmoid inputs, E-only drive term, Gaussian per-bin gains, relaxation form; the old `spike_wc_solver.py` constants are a superseded record, NOT the mirror's source — don't copy them). 7/7 green, 2.2 s (fast_fft=True on the long runs after a 300 s pass-chain timeout — the pass chain is only tied to np.fft at N=32, the f_ks precedent). Bug found by the tests: the retinotopic encode had cortical u/v swapped (u = ROWS, v = COLUMNS, per `wc_retinotopy.render`) — caught by the radial-constancy test at 0.67 residual.
- **Spec rewritten to the settled model:** FR-002 (kernel-convolution gains only, one chain, no decay term / no DC zeroing), FR-003 (the exact settled equations with constants), FR-005 (no NaN ceiling exists; rate ceiling is aesthetic → T030), FR-006 (G3 raw additive E-only drive, 0.5-neutral unconnected). Phase-1 layout block and T021/T023/T024/T025 in tasks.md updated to the one-chain architecture; `form` is dead, T025 param list is `texture`/`drive_gain`/`rate`/`sharp`.
- **Next:** T021 + T022 (GenExpr codeboxes — seed/pass/spec/nl/enc against the mirror's stages), then T023-T025 (Max bench). The module's first texture inlet (drive) needs the `build/spec.md` `driving_inlet` handling checked at definition time (T025).
- Committed as the T020/mirror checkpoint.

## 2026-10-23 (evening): `f_quasi` and `f_wave_field` specced; both at Phase 0, not started

- `.specify/f_quasi/{spec,tasks}.md` written from `ideas/f_quasi.md` (omp run `webgpgpu-ideas-1`, eight idea files committed `bfd8007`). Settled with Matt: looks (Relief, Slope hue) in a gated Phase 2; cyclic `zoom` dial plus a patcher clock; fixed 5 waves × 7 octaves; outlets texture, gradient vecfield, potential scalar. Phase 0 (NumPy mirror T001-T005, cost bench T006, vecfield-normalisation look T007, gates G1-G3) is not started.
- Source facts that changed the idea: the zoom wrap is approximate (1e-8 at sigma 0.5, visible at sigma 1, so `envelope` needs a cap), the source gradient lacks the 2πBs factor, the source aspect handling is not isometric.
- `f_wave_field` spec and tasks written (`.specify/f_wave_field/`). Settled with Matt: spectral solver on the `f_ks` / `f_wc` DFT chain, general dispersion `omega^2 = ring^2 + speed^2 k^(2 dispersion)` (wave, resonator, plate, water-like; my addition over the omp drafts), periodic edges plus an absorbing-edge dial, optional force inlet plus point exciter plus strike, outlets luma and gradient vecfield. Third user of the DFT chain: factoring is `f_wc` T020 (gate G5 there). `f_cymascope` becomes this module plus an audio front end (T041).
- **Next:** `f_wc` Phase 1 build is still the HANDOFF entry below; the two new specs are queued behind it. Their Phase 0 offline tasks (`f_quasi` T001-T005, `f_wave_field` T001-T005 and T007) would suit an omp run.

---

## 2026-10-23 (late): f_wc Phase 0 CLOSED (G1 + G3 approved); Phase 1 architecture worked out from the f_ks chain — next session builds

**Phase 0 closed (commit `880820c`).** Both remaining gates went to Matt and came back: G1 = labyrinth-generator scope (no four-form selector), G3 = drive-coupling recommendation approved. Still open, later phases: G4 (output encoding, slips to Phase 2 via T008), G2 (naming `f_wc` vs `f_formconstants`, Phase 3 blocker).

**Phase 1 architecture (worked out by reading all of src/f_ks; build against this directly).** Key structural insight: the f_ks DFT codeboxes (`codebox_dft_{fx,fy,iy,ix}.gen`) already process FOUR channels as TWO independent complex fields (R,G = complex 1; B,A = complex 2). So ONE f_ks-shaped DFT chain carries BOTH WC fields at once — pack complex-1 = E (R=E, G=0), complex-2 = I (B=I, A=0). No duplicated DFT chain, no Hermitian split needed. Stage plan, 256² float32:

    hold → pass(3in) → fx → fy → spec → iy → ix → nl(4in) → hold (feedback)
    noise → pass.in2 (reseed source) ; noise → nl.in3 (per-frame drive)
    state pass→nl.in2 (raw E,I) ; nl → enc (render-res)

- **hold/pass/enc/iy/ix** adapt f_ks 1:1 (pass reseeds R=E,G=I each from an independent hash channel of `noise`; enc's 4-tap resample becomes the retinotopic map).
- **spec:** replace the KS rate `exp((k²−k⁴)dt)` with TWO real per-bin gains: `KE=exp(−σ_E²k²/2)` on the E channels (R,G out = in·KE), `KI=exp(−σ_I²k²/2)` on the I channels (B,A). σ in PIXELS (working-set σ_E=σ_I/1.45, texture dial = σ_I). NO DC zeroing (that's KS-specific). Param `texture` → σ_I, plus `rate`→dt is NOT here (dt only in nl).
- **nl (the heart), 4 inlets:** in1=convolved fields (R=conv(E,KE), B=conv(I,KI)), in2=raw state (R=E,G=I), in3=per-frame noise, in4=drive texture (sampled at solver res). Computes `Ae=F(16.1·cE − 14.5·cI − He + Ne·nx + drive_gain·(drv−0.5))` (+ same for I with Aei/Aii/Hi), relaxes `E += (Ae−E)·(dt/Te)`, Te=4 Ti=12.5. NaN/Inf zap per f_ks. Params dt(rate), Ne, drive_gain.
- **noise stage:** f_ks seed codebox + a G channel hash; salt increments EVERY frame (not just on reset — per-frame noise is the load-bearing mechanism) via the `r draw` counter in the raw wiring (f_ks resets salt per reset; WC increments per draw).
- **enc:** the 256² state → render-res retinotopic (log-polar) resample from `wc_retinotopy.py` (u=k_e·log1p(r/r0), v=k_t·θ, periodic taps), display E (placeholder until G4), sharp dial, bypass→black A=1. Map constants (r0, k_e, k_t) provisional per T006.
- **Drive inlet** = the module's first texture inlet; check `build/spec.md` `driving_inlet` handling; unconnected default must read 0.5 (so drive=0 → free US-1, per G3).
- **Params:** rate (dt mult→nl), texture (σ_I→spec, working band corner σ_I∈[1.2,1.7]×Ne; default σ_I=1.4), drive_gain (G3: weak=hallucinate, strong=see; Ne fixed at 1.0 in the G3-verified corner, or its own dial — decide at build), sharp (enc), reset, bypass_gate.
- **T020 (DFT factor):** f_wc reuses `src/f_ks/gen_dft.py` a third time → factor to a shared location (FR-002). The four DFT codeboxes are byte-adapted from the same template; only the packing comment changes.
- **Verification tier 1:** new mirror `tests/modules/wc/wc_mirror.py` from the SETTLED model (per-frame noise, relaxation form, Gaussian conv) — the existing spikes are records, not the tier-1 mirror. Tier 2 frame-exact feedback bench per f_ks `bench_ks.py`.

**The settled model (verbatim, from T005/T007):** `E += (S(16.1·(K_E⊗E) − 14.5·(K_I⊗I) − 3.1 + Ne·N + dg·(drive−0.5)) − E)·dt/4`; `I += (S(13.7·(K_E⊗E) − 13·(K_I⊗I) − 3.5 + Ne·N) − I)·dt/12.5`; S logistic, K Gaussian (σ_E<σ_I), N fresh Gaussian noise per frame, dt=1 baseline.

---

## 2026-10-23 (f_wc UN-BLOCKED): the mechanism is noise-sustained patterning — per-frame drive, not nucleation. Module is GO

**START HERE if resuming f_wc.** The "both model classes fail" conclusion earlier today (commits `c31012d`/`4a1f377`) was MY error, reversed the same day. Matt pointed to Michael Rule's working webgpgpu Wilson-Cowan pages. I ran the actual page headless (512², Psychedelic preset, 1600 frames) and read back the cortical texture: **std 95/255, clean labyrinthine stripe structure** — the real Ermentrout-Cowan hallucination texture — and reproduced it in NumPy.

**The one load-bearing ingredient every prior spike lacked: persistent per-frame stochastic drive (`Ne=0.75` injected every frame).** Ablation: with per-frame noise → pattern (std ~0.36); without → uniform/dead. 8-bit quantization, 256-vs-512 resolution, Box-Muller-vs-Gaussian, exact couplings — all secondary. My T004/T005/Pinto-Ermentrout failures all seeded once and let the field decay; none had continuous drive, so all collapsed. The Wikipedia "bistable finite-nucleation" framing was a red herring for this model.

**Working system (Rule's Psychedelic), a small delta from the original `spike_wc_solver.py`:** `Ue += (F(Aee·(Ke⊗E) − Aie·(Ki⊗I) − He − be·Ve + Ne·noise) − Ue)·dt/Te` (same for I), slow adaptation `Ve += (E−Ve)·dt/ae`, Gaussian kernels σe=2px σi=2.9px (E narrower than I = lateral inhibition). Constants: Aee=16.1 Aie=14.5 Aei=13.7 Aii=13, He=3.1 Hi=3.5, Te=4 Ti=12.5, dt=1, Ne=0.75, be=bi=0. The original model class (kernel-coupled sigmoid E/I) was right; it just needs the drive term. The `drive` inlet and autonomous-generator story map onto this directly.

**Region map WITH per-frame noise done (`spike_wc_noise_regions.py`, 96 cells) — refines the picture:** the labyrinth is a **noise-driven TRANSIENT, not a steady state.** (1) Sharp drive threshold at Ne≈0.75 (below: pattern decays to float-noise; above: real contrast). (2) The Psychedelic constants sit on a saturation boundary — the elaborate labyrinth is long-lived but high-Ne cells eventually saturate all-ones, low-Ne cells die; my earlier "uniform" port was correct asymptotic behavior, Rule's live pattern is the transient. Usable band is the narrow Ne≈0.7–0.85. (3) Kernel width selects geometry: sig_i=1.5 → coherent broken stripes ("stripe glass", the closest to rolls, f2=0.48); sig_i=2.9–6.0 → disordered labyrinth/chaos. No clean hexagon region at reachable amplitude.

**Reopens gate G1 for Matt (tier-3 / spec scope):** the aesthetic target is a noise-driven *living labyrinth / stripe-glass* sustained at tuned drive (~0.75) with kernel width as the texture dial — NOT a discrete rolls/hexagon/spiral/funnel selector as the spec's FR-010 assumes. Decision owed: ship "autonomous hallucination-labyrinth generator + drive inlet + texture dial" (which the model delivers) vs. hold out for the discrete form constants (may not exist as separable stable regions in this model). Retinotopic map works on the labyrinth (model-agnostic, std preserved). Full detail in `.specify/f_wc/tasks.md` T005.

**Next:** Matt rules on G1 scope, then T006 render on the real solver output for the tier-3 look, T007 drive coupling (now meaningful: drive inlet modulates Ne or the sigmoid bias), T008. The reframed task detail is in `.specify/f_wc/tasks.md` T005.

---

## 2026-10-23 (f_wc T005 fork): Pinto-Ermentrout spike — SUPERSEDED (see entry above; the failure was missing per-frame noise, not the model class)

<details><summary>Superseded: earlier-negative-result record (kept for history)</summary>

The u/v Heaviside activator-recovery spike (`tests/records/spike_wc_pinto.py`, commit `c31012d`) found no reachable excitable window — but this was before the noise-sustained mechanism was understood. Kept as a record of the dead end; the conclusion "module's existence is the open question" is retracted.

</summary>

---

## 2026-10-23 (f_wc Phase 0): spec + tasks written; Phase 0 region map DONE — NEGATIVE result; module's forms unconfirmed

**START HERE if you are resuming f_wc.** `f_wc` is the Wilson-Cowan hallucination-form generator (`ideas/f_vf_wilson_cowan.md`). Spec and tasks written this session: `.specify/f_wc/{spec,tasks}.md`, idea file header marked specced, `ideas/INDEX.md` flipped to 🟡, `.specify/plan.md` item 8 added (old 8 → 9). Working name `f_wc` (flagged, gate G2). Commits: `a19811a` (spec/tasks/solver), `940ca0b` (region map), `2352435` (negative-result record).

**Phase 0 state (`.specify/f_wc/tasks.md` is the full record):**
- **T001–T003 done:** `tests/records/spike_wc_solver.py`, 5/5 green. Solver is **kernel-coupled** (Ermentrout-Cowan form: each coupling convolves its field with a Gaussian `exp(-σ²k²/2)`, inhibition wider than excitation), NOT the spec's naive "diffuse-then-couple" — the naive form produces long-wavelength mush. **Spec FR-002/FR-003 still describe the wrong (diffusion) form and need rewriting to the kernel form** (the stage architecture is unchanged: exact linear + explicit nonlinear). No NaN ceiling exists (exact decay + bounded sigmoid); `rate` ceiling is pattern-preservation. Sigmoid thresholds and seed amplitude are load-bearing.
- **T004 done (fanned out, 4 parallel slices):** `tests/records/spike_wc_regions.py` + `wc_classify.py`, 80 cells. **No clean rolls/hexagons anywhere** — strong coupling → saturated spots/blobs, weak coupling → uniform collapse.
- **T005 open, the crux (go/no-go for the module):** the Turing band my dispersion scan "found" was about a *different fixed point* than the solver converges to. At the candidate point the physical rest state is saturated-low with all-negative eigenvalues (continuous −0.80/−1.04, discrete 0.967 < 1) — genuinely stable. **Root cause: rest-state multi-stability, NOT discretization** (dt 0.005–0.05 all collapse identically). **Next session's exact task (in tasks.md T005):** find ALL fixed points as a function of (P, wscale, thresholds); compute the finite-k dispersion about the *physical low stable branch* specifically; confirm a band exists there before any more simulation. Do NOT trust the earlier dispersion scan.
- **T006 scaffolding done:** `tests/records/wc_retinotopy.py` — the inverse log-polar map works on synthetic patterns (cortical diagonal-rolls → spiral, v-axis rolls → spokes/cobweb, hexagons → honeycomb lattice). Sub-finding: `k_t` (angular gain) must divide the cortical v-wavelength or a seam shows at the origin. Still owed: render the solver's *actual* output once T005 lands real forms.
- **T007 (drive coupling), T008 (encoding measurement), gates G1–G4: not started**, moot until T005 confirms forms exist.

**Traps to avoid when resuming (learned the hard way this session):** (1) `wc_classify`'s std threshold and normalized ASCII art both mislead at near-zero amplitude — classify on spectral peak prominence; a "pattern" at std < 1e-3 is float noise amplified by normalization, not structure. (2) `k²` in the spectral operators must use ANGULAR wavenumbers (2π·fftfreq), not cycles — getting it wrong under-diffuses by (2π)²; fixed in the solver. (3) Sweep driver `spike_wc_regions.py` bootstraps `tests/lib` onto sys.path itself so it can run outside `tests/run.sh`. (4) The dispersion analysis and the solver must compute the SAME fixed point — this was the session's main error.

**2026-10-23 late addition — the Wilson–Cowan Wikipedia article (Matt's pointer) redirects T005 before the next session simulates anything.** Full detail in `.specify/f_wc/tasks.md` T005's second note. Three takeaways: (1) bistability/hysteresis is the documented mechanism — forms need FINITE-amplitude nucleation, not spontaneous growth from small noise (my seeding approach was wrong); (2) the spatially-extended variant with documented spiral waves is the **Pinto-Ermentrout activator-recovery** form (`du/dt=u−v+∫ω·H(u−θ)`, `dv/dt=ε(βu−v)`, Heaviside firing, slow recovery `v`) — structurally NOT my E/I-sigmoid system; the E/I-sigmoid model may be the wrong model class for spatial forms; (3) the literature's connection kernel is exponential `A·exp(−λr)`, (A,λ)=(2.1,1), still diagonal in Fourier space so the spectral machinery carries over. **This is a design fork for Matt: keep E/I-sigmoid and hunt the right fixed point, or switch local dynamics to activator-recovery (Pinto-Ermentrout). Changes the model class, not just parameters. Decide before more simulation.**

## START HERE (2026-10-20, 20:35): state for a new conversation

- **NEWER (2026-10-22, 22:57): the START HERE state below is out of date. Read the entries dated 2026-10-22 first (22:57, then 09:50).** Much is uncommitted now (menu regroup, Recipes, five new reference docs, the inventory table, the `f_vf_lbm` Tilt dial); the full offline suite has NOT been run since the menu change.

- **State:** everything is committed; the offline suite was green (72 s) after the last code change; the probe bench file passes 9/9 on the GPU. Tier-1 mirrors now cover 19 pre-convention modules (advect, streak, mobius, droste, vortex, vortex_multi, glow, hue, repulse, stereo, channel_grader, luma, sirds, optical_flow Stage C, potential, seeds merge and composite, lens, chladni, ngon), landed from three omp waves; every landing is recorded in `plan.md` and the modules' `tasks.md`.
- **GPU facts established today (probes P1-P9, `tests/records/bench_mirror_findings_probes.py`; the entries below have the numbers):** a bare `sample()` WRAPS out-of-range coordinates in a pix-to-pix chain (x: exact 0.0 and 1.0 read the first texel; y: both read the LAST row, `1 - fract(1 - v)`); an explicit `clamp(coord, 0, 1)` protects only two of four edges (x = 1.0 reads the first column, y = 0.0 the last row); `atan2(0,0)` from arithmetic zeros is +pi on the bench (the repo's NaN claim was for texture-sampled zeros); the chladni note-127 'dead zone' was a NumPy artifact; luma's gray texel rendering green was a hue tie-break bug, fixed 2026-10-20 (it also turned yellows green); stereo's pole texel is a one-ulp knife edge. `tests/lib/gpu_sim.py` models the wrap by default (`OOB_DEFAULT`); `tests/README.md` and `skills/jit-gen-codebox/SKILL.md` state it.
- **Next (rewritten 2026-10-20, 20:35):** everything the earlier list named is DONE and committed: clamp triage and fixes (warp, advect, prism, chroma, potential, ngon, stipple; aniso_blur was a false positive) with all tier-3 looks passed, the `jit-gen-codebox` skill re-uploaded and stamped, the demo re-saves, the live `bench_modules` warp entry, the luma hue tie-break fix, and the frame-panel background fix for luma, hue and tone_curve. Remaining, nothing blocking: (1) more omp mirror waves, when wanted: tooling is ready in `f_omp_runs/mirror-build-4/` (no units yet; see its README and the lessons file in `f_omp_runs/skill-draft/omp-fanout/references/lessons.md`); queue: weave (incomplete in wave 1), prism, seeds search and render, optical_flow stages A, B, D, E. (2) The `f_tf_` modules take the 0.001 / 0.999 constants when their width/height dials go (cosmetic: they already clamp to texel centres in-shader). (3) Optional: a clamp note in the potential, ngon and stipple reference docs (warp and advect have one); fix path A of `scratch/boundmode_probe.maxpat`; the parked `ideas/vecfield_aware_uv_warps.md`.
- **Open decisions for Matt:** whether any clamp artifact is visible enough to fix; the stale `src/f_lens/definition.py` and Stage C comment items were already fixed and regenerated; `package/javascript/lens_toggle.js` was regenerated and kept.
- **Housekeeping notes:** device tools were renamed twice during the session (`mcp__remote-devices__` and `mcp__claude-device__lcl-`); long commands over about 60 s time out on the device, so use `tests/bg.sh start offline` and `tests/bg.sh status`. A stray older stash exists (`stash@{0}`, not from today).

## 2026-10-22 (22:57): `f_modules` menu regrouped into 9 dropdowns plus a Recipes dropdown; five new reference docs; module-inventory I/O table; NOT committed

- **Inventory table (docs/f-reference/module-inventory.md):** new section "Inlet / Outlet Types, Driving-Texture Requirement, and Bypass Output" (six tables plus audio): inlets, outlets, whether a driving texture is Required / Optional / None, and what bypass outputs. A label audit later found three errors in it, now fixed: `f_vf_advect` and `f_vf_prism` each have a THIRD, vecfield outlet (Advect: gradient of the accumulated flow; Prism: weighted dispersion direction), and `f_grain` has 3 outlets (composite, grain mask, displaced), not 1. Inferred (not documented) bypass behavior is marked for `f_grain`, `f_droste`, the four color processors and `f_a_decorrelate`.
- **Five new reference docs (docs/f-reference/):** `f_ks`, `f_vf_lbm`, `f_ngon`, `f_a_ripple`, `f_chladni_audio`, all with rows in the inventory (new "Audio (`f_a_`) and Control Bridges" section). Findings: `f_ngon` is a kaleidoscope fold with no mask outlet, no spec, no GPU bench; `f_a_ripple` is a hand-built standalone prototype (own `dac~`, no outlet object), silent until `output_level` is raised, and has no `carrier_phase` param (the spec lists one).
- **`f_chladni_audio` is NOT what the docs said:** the shipped patch is the superseded 8-band filterbank (band-pass `biquad~` x 8, `abs~`/`slide~` followers, `m0amp`-`m7amp` messages every 20 ms). It has no `sigmund~`/`peakamp~`, and `f_chladni` no longer accepts `m0amp`-`m7amp` (it takes `note`/`amp`). T123 (the `note`/`amp` patch) is still OPEN. Likely bug, read from the wiring only, NOT tested in Max: `[select 0 1]` is fed from the umenu's text outlet, so the Log/Bessel switch probably does nothing (filters stay on the typed Log coefficients; on load the menu shows Bessel). README row (+ launcher), `f_chladni.md`, `.specify/f_chladni/tasks.md` (T141 ticked, T123/T140 noted) and `plan.md` were corrected.
- **Menu redesign, spec and tasks at `.specify/f_modules_menu/` (read the Revision section first).** A two-column index sheet (dots, key, green temporal mark) and a floating palette window were designed and mocked (`scratch/menu_phase0/`, regenerate with `make_probes.py`); Matt found the dots noisy and the sheet too big and SCRAPPED it: **dropdowns stay**. Decisions: no subgroups; unverified modules are ordinary entries; palette on hold. Phase 0 probes (T001-T005) were written; only the sheet probe was opened (it rendered correctly); the palette and insertion probes (T001, T005) were never run and matter only if the palette returns.
- **What shipped (not yet seen in Max):** `src/f_modules/menu.py` now has 9 categories in this order: Patterns (7), Space & Optics (6), Color / Tone (4), `∇ Fields` (8), `∇ Effects` (7), `T_ Fields` (Tensormap, Smooth, Sharpen: 3), `T_ Effects` (Aniso Blur, Glyph, Hatch: 3), Adapters (Axis Flow, Fieldmap, Potential, Split: 4), Routing / Mod (3); alphabetical except `T_ Fields` (pipeline order). Matt split the old `T_ Tensor` for symmetry and moved Axis Flow to Adapters. Section labels: `∇` titles cyan, `T_` titles amber (a swapped request was withdrawn); other titles grey. README Patches table restructured to the same groups (46 rows moved, descriptions untouched; `f_modules` sits in Routing / Mod); `f_Launch` has 10 tabs, 49 modules (the 9 categories plus Audio).
- **Recipes (T050 v1):** a tenth dropdown, `Recipes`; each entry places a row of modules left to right in signal order, UNWIRED. `RECIPES` in `menu.py` (12; 11 from the module sets in `package/examples/f_demo_*.maxpat`, ordered by me from the inventory; "Tensor Advect" has no demo), checked by `generate_menu.py`, written to a generated `RECIPES` block in `package/javascript/f_addmod.js`; new `addrecipe` function (shares a `place` helper with `addmod`; 12 px between modules). `PANEL_H` went 380 to 420 (it was always an arbitrary constant). Recipes are not a README group, so `test_launch` skips them.
- **Checks run:** `generate_menu.py --check` and `generate_launch.py --check` clean; `test_generate_menu` 17/17 (negative tests now find categories by content, not position, and the Recipes checks are new), `test_launch` 8/8, `test_module_contracts` 9/9. `tests/check.sh quick` was started but timed out on the device (60 s limit) and was not re-run: **run the full offline suite (`tests/bg.sh start offline`) before committing.**
- **Owed (Matt, in Max):** open `f_modules` and look: do all 10 labels fit (`Space & Optics` is the longest), do the label colors read, does the dropdown column look right at 96 x 420; pick a recipe in a patch and see how the row lands (`addrecipe` is only parse-checked); T037. The 20 patches that embed the menu (embed heights 249 to 395 px) were NOT resized to 420, so they clip the bottom dropdowns (Recipes, and for the shortest embeds, more); a small script can resize them.
- **Open decisions:** which recipes to keep, reorder or add; auto-wiring recipes (needs a connection list per recipe); the floating palette window (on hold); alphabetical order inside dropdowns (my default, not confirmed); whether `f_chladni_audio` gets rebuilt as the `note`/`amp` companion or kept and renamed as an 8-band analyzer.
- **Stale items noticed, not fixed:** README `f_ngon` row ("regular N-gon generator / mask") and `f_a_ripple` row ("docs pending"); `skills/vsynth-bpatcher/SKILL.md` lines about 1063 still list the old categories (`skills/check.sh` compares it with the uploaded copy, so it was left alone); `ideas/f_ngon.md` lists rotation and scale as open (both are dials); `f_vf_chroma`'s second outlet is commented `streak` in its definition (cosmetic).
- **Uncommitted, new today:** `.specify/f_modules_menu/` (spec.md, tasks.md), `docs/f-reference/{f_ks,f_vf_lbm,f_ngon,f_a_ripple,f_chladni_audio}.md`, `scratch/menu_phase0/`. Modified today: `README.md`, `.specify/plan.md`, `.specify/f_chladni/tasks.md`, `docs/f-reference/{f_chladni,module-inventory}.md`, `src/f_modules/menu.py`, `build/generate_menu.py`, `package/patchers/f_modules.maxpat`, `package/javascript/f_addmod.js`, `package/extras/f_Launch.maxpat`, `tests/build/{test_generate_menu,test_launch}.py`. Still uncommitted from earlier entries: the `f_vf_lbm` Tilt files and the vorticity/menu items listed in the 09:50 entry. Suggested commit split: (1) docs and inventory, (2) chladni_audio corrections, (3) menu regroup + README + launcher + tests, (4) Recipes, (5) LBM Tilt.
- **Housekeeping:** this session used Desktop Commander for all file work and never called the Max MCP bridge (Matt asked for direct file edits); long commands over about 60 s time out, so use `tests/bg.sh`.

## 2026-10-22 (09:50): `f_vf_lbm` Tilt dial (wind direction) built in the mirror, codebox, definition and menu size; NOT run in Max, NOT committed

- **What it is:** Matt chose the tilt option (a mirror-flip toggle was not wanted). New `tilt` param, -30 to 30 degrees, default 0, label `Tilt`, between Wind and Gain. The collide codebox prescribes the inflow as `u = Wind * (cos t, sin t)` instead of `(Wind, 0)` (`th` is clamped to +-30 degrees in the codebox too); speed magnitude is still Wind. Seeding of an empty state is unchanged (straight wind plus the ripple).
- **Mirror and tests:** `tilt=0.0` keyword on `fuse_local` and `lbm_step` in `tests/modules/vf_lbm/vf_lbm_mirror.py` (clamped like the codebox). Two new tests in `test_vf_lbm.py`: `test_inflow_tilt_sets_direction` (rightward populations at the inflow = the tilted equilibrium at the Zou/He density for 20, -15, 30 degrees; tilt 0 identical to the straight wind; clamps at 30) and `test_tilt_turns_the_flow_near_the_inflow` (200 frames, first columns take U0 sin(t) across-stream within 20%). `test_vf_lbm.py` 17/17, `test_module_contracts.py` 9/9, `test_launch.py` 8/8, `drift.py -v f_vf_lbm` ok, menu `--check` ok.
- **Measured (mirror, 192x108, Wind 0.08, omega 1.97, empty mask, `scratch/lbm_tilt_probe.py`):** the interior settles to the target (tilt 20: ux 0.0751 / uy 0.0271 vs 0.0752 / 0.0274; tilt +-30: uy +-0.0397 vs +-0.0400). The first three columns sit about 7% short across-stream. **The across-stream part travels downstream at about the flow speed (~0.075 cells/frame): the front reaches column ~60 by frame 1000 and the whole channel by ~2500 frames (about 40 s at Speed Full and 60 fps). A tilt change shows first at the left and sweeps right.** Peak speed is about 0.088-0.089 at Wind 0.08 (the straight wind stays at 0.080), and density ranges 0.97 to 1.01 (straight: 0.999 to 1.001): the tilted inflow is rougher. Not measured: tilt with an obstacle, or at Wind 0.1 / omega 1.98 (the Mach ceiling).
- **Layout:** five controls overran the 190 px panel (the Speed menu ended at x = 193), so `presentation_width` is now 197 (menu size row `vf_lbm: [197, 110]` regenerated; launcher regenerated).
- **Stale-id trap, fixed:** the frame gate's raw wiring names the Speed menu `obj-29`; adding Tilt moved it to `obj-32`, so the wiring pointed at the wrong object. `test_module_contracts.py` caught it ('unrouted speed'); the definition now says `obj-32` and carries a note. Any further param added before Speed shifts it again.
- **Owed (Matt, in Max):** reopen a fresh patcher, check the five controls and the title bar, and try Tilt live (expect the turn to sweep left to right over tens of seconds). The three benches from before are still unrun, and `bench_vf_lbm_module.py` has no Tilt case (default tilt 0 leaves its free-stream check unchanged). The module's reference doc and helpfile (T040) do not exist yet, so Tilt is documented only in its hint, the definition and this file.
- **Uncommitted (adds to the 23:20 list):** `src/f_vf_lbm/codebox_collide.gen`, `tests/modules/vf_lbm/{test_vf_lbm,vf_lbm_mirror}.py`, `scratch/lbm_tilt_probe.py` (new). `package/examples/f_demo_ks.{maxpat,json}` are untracked and not from this work.

## 2026-10-21 (23:20): `f_vf_lbm` verified, `f_vf_vorticity` shippable and in the menu; NOT committed

- **Decided (Matt, 23:14):** LBM is verified (README ⚠ removed) and vorticity's pause was an old note: it is shippable. Judged by use; no new bench was run for either, and LBM's three Max benches (`bench_vf_lbm_module.py`, the `bench_modules.py` row, the slow chain) are still unrun.
- **Vorticity:** `src/f_modules/menu.py` lost its `NOT_IN_MENU` entry and gained `("Vorticity", "vf_vorticity", V)` after Advect in ∇ Processors. README row rewritten (no more "Do not treat as working"), launcher regenerated (49 modules, 8 marked ⚠), `test_launch.py` 8/8, menu `--check` ok, `drift.py -v f_vf_vorticity` ok. Unverified wording removed from the reference doc status line, `module-inventory.md`, the helpfile (two text strings; still valid JSON) and `ideas/INDEX.md`; `plan.md` dropped its Paused entry and gained a one-line Resolved item. The README description is 109 characters.
- **Left stale on purpose:** the 2026-07-06 correction paragraph in the vorticity reference doc (kept as history); `plan.md` Still open 7 still says the Phase 0 GPU bench for `f_ks` / `f_vf_lbm` has not started (it has, for LBM); the vorticity helpfile was not opened in Max.
- **Uncommitted:** README.md, `.specify/plan.md`, `docs/f-reference/{f_vf_vorticity,module-inventory}.md`, `ideas/INDEX.md`, `package/help/f_vf_vorticity.maxhelp`, `package/extras/f_Launch.maxpat`, `src/f_modules/menu.py`, `package/patchers/{f_modules,f_vf_lbm}.maxpat`, `package/javascript/f_addmod.js`, `src/f_vf_lbm/definition.py`, this file, `.specify/f_vf_lbm/tasks.md`.
/examples/f_demo_ks.maxpat` is untracked and not from this work.

## f_vf_immiscible (2026-10-27)
Phase 0 started: T001, T002, T003, T008 done (tier-1 mirror and 14 tests green, builder dry build OK). Next: T004 constants sweep, T005 thresholds, then T006/T007. Open: G5 bypass (Matt), adv input-order amendment (see tasks.md Record).

f_vf_immiscible (2026-10-27, later): Phase 0 complete (T001–T008, T006b). G2 plain, G5 neutral, G7 Cahn–Hilliard decided. Constants fixed in the mirror. Next: Phase 1, T010 (codebox stages on the bench); T017 carries the 3000-frame drift check. Plan ADR-1 `adv` input order amended (state hot).

f_vf_immiscible (2026-10-27, night): T016 bench 13/13, T017 cost recorded (3.7 ms at 1080p taps 2, 5.9 ms at 4K, DFT chain 2.06 ms), drift check done (bounded, no mean-restore). Open for Matt: G6 (256² vs 128²). Next: Phase 2, T018 (definition.py + builder).

f_vf_immiscible (2026-10-27, late): Phase 1 done and committed; Phase 2 T020 done (`0610c5d`): `src/f_vf_immiscible/definition.py` builds `package/patchers/f_vf_immiscible.maxpat`, drift 0, ten stages in the amended ADR-1 order, reset logic and A/B vs_inState gating in the definition, README row ⚠, NOT_IN_MENU ("menu entry is T032"), launch regenerated, test_launch and test_generate_menu pass. NOT yet loaded in Max; draw order (inab before pass) untested. Dial ranges are provisional (dt 0-0.05, iface 1.5-12, coarsen 0-1, inject 0-1, fill ±0.6, taps hidden default 2). G6 stays 256² until the live look. Open for Matt: G1 (T033), G3 (T024), G4 (T023), G6, G8. Next: T021 (check reset/load/freeze live in the patcher), T022 (module bench + `bench_modules.py`; Max bench, ask first), then Matt's looks T023-T026. `.specify/plan.md` and `ideas/` files are uncommitted from before.

f_vf_immiscible (2026-10-28): Matt's live test: camera on in0 floods phi to white. Fixed in code (not yet in Max): `thresh` dial (smoothstep, only bright parts deposit), `inject` cubic, `pull` dial (k=0 bin relaxes the mean toward `fill`). Tier 1 17/17, static 9/9, drift 0; rebuilt patcher (reload it in Max; reset button moved). GPU bench not re-run: do `tests/bench.sh bench_immiscible.py` (Max + bench.maxpat open, ask first) before T022. Live recipe in tasks.md Record. Defaults are guesses (inject 0.3, thresh 0.5, pull 0.3).

f_vf_immiscible (2026-10-28, evening): T021 and T022 done. `freeze` removed everywhere. Stage bench 14/14, module bench `bench_immiscible_module.py` 4/4 (reset on load, once-per-frame 0.965, A/B blend and Mix exact, two instances), live contract run 0 unexpected issues. Controls: dt, iface, coarsen, inject (cubic), thresh, pull, fill (±0.6), mix_pct (0-100, velocity bias), reset. Next: Matt's looks T023-T026 (two f_vf_fluid at different viscosity, dt above 0, ride Mix), then T027 (bake defaults: found-working values thresh 0.85, pull 0.64, fill 0.22, inject 0.5, coarsen 0.02, iface 1.5; re-run `--slow` cost test; decide taps default). Then Phase 3 (helpfile, reference doc, menu T032). Uncommitted before this work: `.specify/plan.md`, `ideas/`.

f_vf_immiscible (2026-10-28, night): Matt's first live look (T023) passes: two `f_vf_fluid` at different viscosity, "in good shape", defaults good. Decision: NOTHING is baked; shipped defaults stay (found-working set thresh 0.85 / pull 0.64 / fill 0.22 / inject 0.5 / coarsen 0.02 / iface 1.5 stays a recorded recipe only). T023, T027 and G3 ticked in tasks.md. Still open: T024/T025 (not separately reported), G4, G6 (256² kept), G1 (T033), G8; `--slow` cost test not re-run. Next: Phase 3 (T030 reference doc, T031 helpfile, T032 menu entry + README row, T033 name/ideas/plan), whenever Matt says go.

f_vf_advect (2026-10-28): added `trail` (half-life in frames, 0-1000, cubic taper; 0 = off = classic loop) and cubic taper on `injection`. With Trail on, `injection` is rescaled so a still source settles at injection / 0.03 whatever the trail length, and `decay` scales the half-life on a log curve: hl = trail * exp((decay - 1) * 20), clamped 1..1000 (decay 1.0 neutral; the default 0.97 gives x0.55). Commits 976adee, a8bb81c. Tier 1 14/14; GPU `bench_vf_advect.py` 2/2 (exp() and all Decay x Trail cases match the mirror). Matt tried it live: "outstanding". Open: helpfile does not mention Trail; Matt may refine the Trail x Decay interaction near decay = 1.0 (his words); other options not chosen (lighten/max injection, bleed dial).

f_vf_immiscible (2026-10-28, closed out): DONE. Phase 3 committed (`4378d8e`: reference doc, helpfile, menu entry in Fields, README/inventory rows). Matt then closed T024, T025, G4 and G6 and moved the spec directory to `.specify/stable/f_vf_immiscible/` (live references to the old `.specify/f_vf_immiscible/` path were repointed; older entries above keep the old path as history). Unchecked by me: the helpfile layout in Max (wider canvas than usual, two Fluids at viscosity 0.05 / 0.6 set by a loadbang delay). Not built: Phase 4 (momentum across the interface, G8). `--slow` cost test not re-run since pull/thresh/mix_pct. Uncommitted and not mine: `package/examples/f_demo_immiscible.*`, `ideas/f_splat.md`, `f_ca.md`, `f_vf_emulsion.md`, `f_vf_mix.md`.
