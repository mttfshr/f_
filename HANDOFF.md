# HANDOFF

_Newest session: 2026-10-07 (the first section below): scatter chosen for the `f_caustic` sheets mode, density / cost / detail spikes done, no module built. The 2026-10-06 line that follows covers the older sessions._

_Latest session: 2026-10-06 (three sessions; the newest is a different workstream, the optics / Lumia research, committed on 2026-10-07 and continued in the 2026-10-07 section below; the two older sections are `build_cleanup` and supersede each other as before)_ — `build_cleanup` **Phases 1, 2, 5 and 6 are done, Phase 4 is done except `f_sirds` (T019: fluid, advect and seeds absorbed; `f_sirds` deliberately left alone), and plan item 10 is 11 of 11.** 31 of 39 shipped patchers reproduce exactly from their `definition.py`; the drift baseline is 8 (`f_masonry`, `f_texrouter`, `f_vf_vorticity`, five out of scope). Everything in the `build_cleanup` work is committed (last commit `bc190bb` when it was written), nothing is pushed; the optics research of the third session was committed on 2026-10-07 (`26df9b6`).

_Task IDs are per directory: each `.specify/<dir>/tasks.md` starts at T001. Write the directory with the ID, e.g. `packaging/T021` means `.specify/packaging/tasks.md`._

## 2026-10-07: scatter chosen for the `f_caustic` sheets mode; density, cost and detail spikes (RESEARCH; no module built; committed)

**Decisions (Matt)**
- **The sheets mode uses the GPU scatter** ("the numbers strongly suggest the gl method for sheets"); the multi-start gather stays in `tests/` as the fallback.
- **The 1-frame lag is accepted** ("we do 1 frame lag in many places").
- **MVP: a fixed internal capture size** (Matt's default look, chosen after trying the presets: a 1024^2 capture, 4 points per capture pixel, bilinear upscale to the output; the cheaper 512^2 / 2-point preset is the fallback), not a scale relative to the output: 4K then costs the same as 1080p and only looks softer. There is no `detail` parameter in the MVP.

**Results** (all numbers and caveats in `ideas/optics_map.md`, "Findings: scatter density, cost and detail"; records `tests/spike_scatter.py` stages `s4` to `s9`, logs and figures in `scratch/scatter_spike_s*`)
- A K-meshes load multiplier to see past the 60 fps cap was NOT linear (negative and 100 ms-noisy periods): discarded and removed.
- Cost is driven by points per pixel (blend contention), not point count: at a fixed 16.8 M points, 1 point per pixel is about 17 to 22 ms, 16 per pixel 29 to 69 ms; vertex work is about 1 ms per million points or less. **Timings vary up to 2x between runs** (same config 69, 29, 45 ms), a few percent within a run.
- Corner-snap + `point_size 2` is bit-identical to `point_size 3`; a speed-up was not established.
- Coarse capture + bilinear upscale: `s = 2` (half size) at 2 points per capture pixel is r 0.998 at 1 d* and 0.958 at 3.5 d* against a 16 points-per-pixel reference; the loss is resolution, not noise. About 1 M points at 1080p, roughly 1 to 2.5 ms plus the upscale pass on this M3 Max.
- At 1 point per capture pixel there is a visible lattice moire (Pearson barely sees it); 2 is clean. Lattice jitter trades it for grain and is a net loss. A 4-tap source prefilter does nothing (r changes under 0.001, 0.003 at most). Source aliasing (zone plate, checkers) is small at `s = 2`.

**Files.** New or changed: `tests/spike_scatter.py` (stages `s4` to `s9`), `tests/bench/make_spike_scatter.py` and `spike_scatter.jxs` (uniforms `h`, `snap`, `jit`, `latn`, `taps`; the K meshes were added and removed), `scratch/s4_diag.py`, the `scratch/scatter_spike_s*` logs and figures, `ideas/optics_map.md`, `.specify/f_caustic_scatter/spec.md` (a Session 2026-10-07 note and an update line), `.specify/plan.md` (item 15), `tests/README.md`. Commit `26df9b6` ("2026-10-07") swept in everything of the session plus Matt's own `package/examples/f_demo_glow.*` Max 9.2.0 re-save and the `skills/MANIFEST.md` stamp; the write-up is the commit after it.

**Look patch (built later the same session; Matt confirmed it renders).** `~/Vsynth/patterns/scatter_look/scatter_look.maxpat` (outside the repo; the spike bpatcher and shader are copied beside it): a light-source selector (video | waveform gen), a glass selector (`vs_noise_3` | `vs_chemical_osc` -> `vs_filter_lp2x` -> `f_vf_fieldmap`), the spike scatter with six preset message boxes and a `d` numbox, a tone-map + bilinear-upscale `jit.gl.pix`, and `f_caustic` on the same field as a reference output. **Matt hand-edited it in Max** (his layout; `gswitch` UI selectors in place of my gates; he dropped the `f_caustic` source cord and the `dim` cords to the tone stage), so `scratch/build_scatter_look.py` is only the record of the first version and must NOT be run: it overwrites his patch. Change his file by a surgical edit, and only while it is closed in Max (backups beside it: `.bak`, `.bak2`). `tests/bench/spike_scatter_tone.maxpat` plus stage `s10` is the bench test of the tone stage (Pearson 1.0000 against NumPy at 512^2 and at 1920 x 1080).

**`detail` control (built the same day, after Matt said his performance machine is this M3 Max or an M1).** The spike bpatcher takes `detail 1` to `detail 5`: capture size / points per capture pixel = 256/2, 512/2, 768/2, 1024/2, 1024/4 (0.13, 0.52, 1.2, 2.1, 4.2 M points); ONE message sets `r`, `latn`, `weight` and `n` (n last, so the lattice rebuilds once) with the footprint fixed (corner-snap, size 2, regular lattice, one source read). Bench stage `s11` shows each step identical to the equivalent explicit messages (max|diff| 0). The look patch has a menu for it (a surgical edit; at load it sends step 5, Matt's default). Rebuilding the lattice hitches at the high steps: it is a setup control, not a performance one. **Not measured: any M1 number**; my guess is 3 to 5x slower than the M3 Max for this blend-bound work (step 5 roughly 15 to 45 ms), so run `s6` and the look patch on the M1 and set its default step there. The ladder moves into the `f_caustic` module with the spec addendum. Matt skipped the M1 measurement and confirmed he did not need the `fy 1` flip live (so `fy -1` holds in a real chain). **Correction:** the look patch's on-canvas note says the spike bpatcher has fixed `@name`s; that is wrong (the node and shader names use `#0`, unique per instance): the collision with the bench was the shared `vsynth` render context.

**Implementation progress (Phases 0-1, 2026-10-07; **Phase 1 is DONE: T001-T011.** `package/code/` is on the shader search path (verified after relaunching Max); ADR-1 settled: declarative).**
- **T001 baseline:** `tests/baselines/f_caustic_soft.npz`, the unmodified module's two outlets for 5 parameter sets (sha256 + 128² copies), recorded by `tests/record_caustic_baseline.py`; a repeat run is **bit-identical**, so the hash is a valid identity check. **Gotcha found the hard way:** in the module bench `base` is captured BEFORE the job's `params` and `bypassed` AFTER the bypass test (a passthrough for a module that honours bypass), so neither is "after the params, bypass off". `tests/caustic_runner.py run(..., settings=...)` sends the settings from a wrapper loadbang (200 ms delay, after the first renders) and you read `base`, the `bench_fluid_module.py` precedent. My first recording read `bypassed` and stored a passthrough for every set; I caught it because all sets were identical, and the recorder now refuses a baseline where they are.
- **T002 before-state:** offline suite 233/233 across 21 files (exit 0); module bench 33 modules, 0 unexpected issues.
- **T003-T006:** `tests/scatter_truth.py`, `tests/scatter_mirror.py`, `tests/test_scatter_mirror.py` (7 tier-1 checks, 1.7 s; r vs truth 0.9987 / 0.9939).
- **T008 answered:** an unconnected `jit.gl.pix` inlet reads a constant **(0, 0, 0, 1)**: black with alpha 1 (not stale, not undefined), and the connected inlet passes through exactly. The sheets composite's unconnected-field guard therefore keys on R = G = 0 at several fixed points and must NOT use alpha.
- **T009 / T010 answered** (in-process builder probe, `scratch/probe_builder_targets.py`): the declarative builder can express the whole structure; see plan ADR-1 / ADR-4. No dedicated build script is needed.
- **T007 answered (after a Max relaunch): `package/code/` IS searched.** Background: Max's file database does not see files created after launch: `max.refresh()` (via `bench_eval`) makes a new file in a folder already on the path findable after a few seconds, but a NEW folder (`package/code/`) is not added to the search path until Max is relaunched. Vsynth's own `code/` folder (present at launch) IS found, so `code` is a searched package folder. The bench also does not capture `jit.gl.shader` load errors (the negative control, a nonexistent shader file, raised nothing), so a shader's loading must be verified by non-black output, not by an empty error list. The probes and the temporary probe shader were deleted at T011.

**Implementation progress, Phases 2-5 (T012-T036 done; tasks.md is the anchor).** `f_caustic` now HAS the sheets mode (`package/patchers/f_caustic.maxpat`, built from `src/f_caustic/definition.py` + the generated `raw_ui.json`; shader `package/code/f_caustic_sheets.jxs`). Verified: soft mode **bit-identical** to the baseline (5 of 5 parameter sets); sheets through the module equals the standalone exactly; bypass is an exact passthrough on both outlets in both modes; an unconnected vecfield is silent in sheets mode; sheets/soft brightness ratio 1.55 at the defaults (`k_sheets` left at 2.0 on purpose); both modes fit the frame budget; the offline suite is 236/236 and the live module bench is green for all 33 modules. **Matt confirmed live that the Mode menu and the Detail select work.**
- **Gotchas found (all fixed unless noted):** the soft stage must stay ENABLED in sheets mode (the select stages render on its output; a disabled stage emits nothing, so the module output nothing); an `attrui` aimed at a non-pix box drops the value, so non-pix controls use `pix_wire: False` and tap the widget's outlet (`scatter_scene.py`); the select stage is TWO stages because the codebox bench takes 3 inputs; the codebox bench counts `outN` tokens even in comments; `base` / `bypassed` are not "after params" (use `caustic_runner.run(settings=...)`); a heavy bench run can stall Max (T020's 16.8 M-point references; probable memory pressure) and give nonsense timings, so `ONLY=T031,T032 python3 tests/bench_caustic_sheets.py` runs a subset and T021 now rejects an invalid measurement; `tests/module_contract.py` now treats GL scene objects as valid route sinks and passes through `route` / `select` for route tokens only (not for attrui targets).
- **Still open:** **T043** (assert the 1-frame lag through the module: needs a counter pix wrapper); a possible EXTRA frame of latency in sheets mode, because the select stages are triggered by the soft stage's output and the sheets composite may land a frame later depending on message order (T043 should show it); **T037** (Matt's live check of the rest: `scale` / `gain` ranges, the Detail hitch, TWO instances, the look on real video); Phase 6: the reference doc and helpfile (T038, T039; the reference doc's signal flow is stale and still says three inlets), the constitution amendment (T040), README / skill (T041: add the `outN`-in-comments finding to `jit-gen-codebox`), final checks (T042).

**Do first next session**
1. ~~Rewrite the spec~~ **done 2026-10-07:** `.specify/f_caustic_scatter/spec.md` is now a draft addendum to `f_caustic` (the soft path untouched, a `mode` switch, the `detail` 1 to 5 ladder, the shared `scale` / `gain` / `mix_pct` / `bypass`, selection in a pix, an unconnected-vecfield guard, acceptance criteria from the measured numbers). Its 7 decisions were **all resolved 2026-10-07 as recommended** (Matt: "go with your recommendations"; listed at the end of the spec, including the constitution wording to apply at ship time). **Phase 1 plan and tasks written 2026-10-07:** `.specify/f_caustic_scatter/plan.md` (8 ADRs, 5 dependency blocks: A baselines and feasibility, B scene / shader / composite standalone, C the `detail` ladder and mode network, D build into `f_caustic`, E live and release) and `.specify/f_caustic_scatter/tasks.md` (42 tasks, T001-T042, validated). **Matt still has to confirm the block sequence** (the plan-workflow checkpoint); then start at T001 (record the soft-path baseline BEFORE any module change). The architecture choice that matters: a declarative `definition.py` (pix_chain x3 + a generated raw scene), with a dedicated build script only as the fallback if the builder checks T009 / T010 find a limit.
2. Phase 0 spike 3 is now mostly design on paper (the spec settles render-size and non-square handling: a fixed square capture, a composite that follows the source's size); what is left is Phase 1 verification: the `.jxs` found from a new `package/code/` folder (Vsynth keeps `vtfk.jxs` in its `code/`), how an unconnected pix input reads in Vsynth, and the builder accepting the node / mesh / slab scene as `raw_boxes`.
3. **Matt's eyes:** the look patch exists and renders (see "Look patch" above); judge the `s = 2` default on real video, from the first fold out to 3.5 d*. **Verdict so far (Matt, looking at the preset buttons in the look patch): the presets do not look the same, none looks "worse", and all of the effects could be useful.** So the differences the tests treated as flaws (the `p = 1` moire cross-hatch, softness at larger `s`, grain) may be wanted characters. The fixed-internal-size decision stands for the MVP, but a creative `detail` / character control (a few presets, not a free resolution) is worth considering after it; **default chosen (Matt): 1024^2 capture, 4 points per capture pixel** (n = 2048, 4.2 M points, about 200 MB of lattice). By S6's 1.3 to 2.2 ms per million points that is roughly 5 to 9 ms on this M3 Max (only ever measured as "within the 16.7 ms cap", S3a), heavier than the ~1 M-point design the tests recommended: check it in a full chain, and on the performance machine. His reply on `fy` and real video is still open.
4. Re-measure cost with a better method before fixing any budget (interleave A/B, several runs, note the thermal state; a calibrated ballast pass whose knee shifts is the untried idea). The machine is an M3 Max; a performance machine may be weaker.

**Open decisions:** the capture size value and its aspect, tone map and HDR policy, `edge: wrap`, the mode's name and UI, where the `.jxs` lives, whether the lattice is built only when the sheets mode is on.

**State of Max and the bench.** Nothing is running; the module bench is open in Max (the spike runs reopen it). Lattices up to 800 MB were released at the end of each stage; restart Max if it feels sluggish. Do not leave a Vsynth performance patch open while the bench runs.

**Process lessons** (so they are not relearned)
- Validate a new timing method on a known-cheap and a known-linear case before trusting it: the K-meshes multiplier gave plausible-looking numbers that were noise plus per-mesh overhead.
- Timings repeat within a run and not between runs (up to 2x): compare configs inside one run, interleave A/B, and keep the raw numbers.
- Pearson r is nearly blind to lattice moire, and the spectral "structure score" conflates moire with the upscale residual: look at the picture (the figure files) before concluding anything about visual quality.
- A vertex-stage `texture2D` has no derivatives or mip selection: the source read is one bilinear tap per point.
- **Read the codebox skill before writing any codebox, not after.** The look patch's tone stage output black because it broke two rules the `jit-gen-codebox` skill already documents: functions must precede every statement including `Param` (a hard compile error, "function definitions not allowed here") and `.x` on a stored `sample()` result silently outputs black.
- A black result in a live patch cannot be diagnosed by reading: reproduce the stage in the bench with known inputs first. Stage `s10` found the compile error in one run, after two rounds of guessing in the live patch.
- Matt rejected `switch` and used `gswitch` UI objects for texture selection. Whether `switch` or `gate` would have worked was never tested (the black output turned out to be the compile error); note that a bare `switch N` starts Off unless given its initial-state argument (`switch 2 2`, as Vsynth writes it).

## 2026-10-06, third session: optics research for a Lumia-type effect (RESEARCH ONLY; committed 2026-10-07; no module built)

_Superseded in part by the 2026-10-07 section above: scatter was chosen over the gather and the lag is accepted, so its "Do first" items 1 and 2 are done or replaced._

**Goal and outcome.** Matt asked for a Lumia-type module (a texture in, light through animated glass out). The session produced research, two draft specs and one open decision, no module. Everything is in `ideas/optics_map.md` (read its "Findings" sections first; they hold every number and caveat) and `ideas/f_lumia.md`.

**Decisions (Matt)**
- **`f_vf_glass` is ON HOLD** (idea + spec kept, marked): Vsynth already ships smooth morphing sources (`vs_noise_2/3/s`, `vs_chemical_osc`, `vs_filter_lp*`), and a smooth height through `f_vf_fieldmap` already makes a valid glass (checked in NumPy: even 8-bit height gives the same caustics; fieldmap's UV inset only stretches the field).
- **The sheet regime goes into `f_caustic` as a second mode**, not a separate module: soft = today's path, untouched; sheets = new path beside it; a small selector picks the outlet source; the inactive branch should be disabled. "Lumia" is the look, not a module name.
- **The METHOD for the sheets mode is OPEN: scatter or multi-start gather.** Numbers against the photon-counting truth at 3.5x the first-fold distance d*:

| | existing `f_caustic` | multi-start gather (pix codebox, hand-made bilinear; G6 M4 T6 S2, tol 3e-4) | GPU scatter (GL scene) |
|---|---|---|---|
| agreement r | 0.51 | 0.930 (1.000 at 1 d*, 0.960 at 2 d*) | 0.994 (0.999 at 0.6 and 1 d*) |
| bright-line overlap | 0.20 | 0.840 | 0.926 |
| cost | cheap | 4.4 ms/pass at 256², 11 ms at 512² (4 starts); 7.8 / 19.8 ms with 8 starts; grows with pixels | held the 60 fps cap up to 6.55 M points into 1024²; headroom unmeasured |
| integration | none | ordinary shader; fits builder and tests; no lag, no memory grid; parser budget ~450 statements (8 starts fit, maybe 16-24 with more function-izing) | `jit.gl.node` + `gridshape` matrix + `jit.gl.mesh` points + `.jxs`; 1 frame behind pix chains; 48 B/vertex lattice; `fy = -1` flip; bypass needs a pix stage after it |

**Findings that outlive the decision** (all bench-verified unless marked; now in `skills/jit-gen-codebox/SKILL.md`)
- **`sample()` is nearest, not bilinear, when its coordinate is data-dependent and jumps between neighbouring pixels** (filtering picks magnify/minify from the screen-space derivative). Fix: four exact `nearest()` taps (~3.7x the reads). This was the entire "GPU worse than NumPy" mystery. **Not audited:** whether any shipped module reads `sample()` at jumpy computed coordinates.
- **Codebox parser statement budget:** ~250 per function body / top level, ~450 whole program (not bytes or lines), for-loop bodies tolerate more; `require` adds none; functions help (a call is one statement). A failure **wedges the bench** (stale image, no error) until `reopen()`.
- Functions can sample `in2`, loop and multi-return; `require("name")` loads `name.genexpr`; `step()` with two literal constants folds reversed.
- Scatter, measured: float32 additive accumulation exact (no clamp); texture upload and capture readback each flip vertically (net upright, field Y inverted: `fy = -1`); `gridshape` has no `@draw_mode` and `@poly_mode 2 2` draws each vertex ~6x (use matrix output into a points mesh); GL points are round (size-1 loses ~21% energy; tent splat with `point_size 3`); ~4 points per pixel is the quality plateau; frame lag vs pix chains is exactly 1.
- Not causes of the gap, so do not chase them again: float32 arithmetic, 8-bit interpolation weights, candidate selection, the Newton step.
- `docs/f-reference/f_caustic.md` was wrong about `scale` 0 (it is the undisplaced divergence-weighted layer, not empty): fixed.

**Files (committed 2026-10-07, `26df9b6`)**
- Modified: `docs/f-reference/f_caustic.md` (the `scale` row), `ideas/INDEX.md`, `skills/jit-gen-codebox/SKILL.md`, `tests/README.md`, this file.
- New, tracked-worthy: `ideas/optics_map.md`, `ideas/f_lumia.md`, `ideas/f_vf_glass.md`, `.specify/f_vf_glass/spec.md` (ON HOLD), `.specify/f_caustic_scatter/spec.md` (still a separate-module draft with a "superseded in part" note), `tests/spike_scatter.py`, `tests/gather_proto.py`, `tests/bench/{make_spike_scatter.py, spike_scatter.jxs, spike_scatter.maxpat, spike_scatter_chain.maxpat}` (records, not regression gates; `tests/README.md` lists them).
- **Untracked `scratch/` that the tests/ records import:** `caustic_fidelity.py`, `multi_guess_gather2.py` (and `float32_mirror.py`, `gather_debug.py` for the gap hunt). Commit those with the records or the records will not run. Also in `scratch/`: the other research scripts (`multi_guess_gather.py`, `glass_vs_fieldmap*.py`, `require_probe.py`, `parser_limit_probe.py`), PNGs and `*.log` outputs; curate or delete as you like (nothing else depends on them).

**State of Max and the bench.** Nothing is running. The CODEBOX bench is open in Max (reopened many times); the module bench was closed to avoid contention (`gather_proto.ensure_codebox_bench` closes it). Max reached ~3 GB resident during the big-lattice sweep: restart it if it feels sluggish. Do not leave a Vsynth performance patch open while either bench runs.

**Do first next session (suggested order)**
1. **Decide gather vs scatter.** Cheapest evidence first: (a) the **cell-Jacobian experiment**: take the slopes from the same four taps as the field value (one `fxy` call per Newton step instead of five); estimated ~5x fewer Newton-stage reads but it changes the slope definition, so check accuracy against 0.930 / 0.840 first (NumPy, then bench); if cost falls to ~1 ms at 256² the gather becomes attractive. (b) A **scratch patch to look at real sheets** on Vsynth sources (`vs_noise_*` or `vs_chemical_osc` -> `vs_filter_lp*` -> `f_vf_fieldmap` -> `f_caustic`, plus the scatter spike's chain): all numbers so far are against physics, nobody has judged the look; needs Matt's eyes. (c) If scatter: its Phase 0 spikes (lag via `@layer`, 12 B/vertex lattice, real chain + render-size adapt, source aliasing / gobo = highest risk, headroom beyond the 60 fps cap).
2. **Rewrite `.specify/f_caustic_scatter/spec.md` as an addendum to `f_caustic`** (mode switch; shared `scale` = distance, `gain`, `mix`, `bypass`; soft-only `softness` / `color_shift`; new `detail`; `gain` default per mode). Do this after step 1.
3. ~~Commit the research~~ done 2026-10-07 (`26df9b6`; the scratch imports are tracked).

**Open decisions and loose threads**
- HDR/tone-map policy (illuminance peaks ~18x mean), `edge: wrap`, where the `.jxs` lives (Max search path), the codebox-first deviation wording in the constitution (if scatter), the mode's name/UI, whether the lattice is built only when sheets mode is on.
- `docs/f-reference/f_caustic.md`: the `bypass` row is stale (says out2 goes black; since 2026-10-06 bypass passes the source on every outlet). Not edited.
- `.specify/plan.md` and README were NOT updated: no module is in the build queue, no patcher status changed, and `.specify/`'s README description already covers new directories.
- **Skills:** `jit-gen-codebox` changed this session and is the only stale skill (`./skills/check.sh` says so; the others are ok). Re-upload it, then `./skills/check.sh stamp`. (Done by Matt on 2026-10-07: `check.sh` reports all uploads current.) I did not touch `skills/MANIFEST.md`. (The older note below about re-uploading `vsynth-bpatcher` for the T019 keys no longer shows as stale; I did not check whether the skill text covers those keys.)

**Process lessons from this session** (so they are not relearned)
- A mismatch between a NumPy mirror and the GPU is not automatically the GPU's fault, and the first hypothesis was wrong three times (float32, interpolation weights, then my own probe forgetting to pass `d`). Bisect by program stage with a tiny known-good probe at each step, and test one hypothesis at a time.
- Numbers from a program that never compiled look like valid measurements (flat 330-650 fps). Always confirm the output is correct, and probe the bench after any compile failure, before trusting a timing.
- The project's float32-mirror rule is right, but here a float32 mirror was identical to float64; the discrepancy was in an execution-model fact the mirror did not model (`gpu_sim.sample` is always bilinear).

## 2026-10-06, second session: masonry bypass, bench table, seeds (T019) and T026 done (offline suite green, bench green)

**Commits:** `75dc017` (masonry + bench table), `53563e3` (seeds), `11f9d38` (T026 Python half). Offline suite green after each; `drift.py` 31 of 39 (baseline 8, unchanged); `generate_menu.py --check` / `generate_launch.py --check` up to date. No shipped patcher was regenerated; the only shipped patcher edited is `f_masonry.maxpat` (9-line surgical diff).

**Live check done by Matt, same day: `tests/bench.sh tests/bench_modules.py` ran all 33 modules, 0 unexpected issues.** So the new `BYPASS_EXPECT` expectations hold live (stipple/grain/chladni/masonry out2/prism out3/advect out3). Side note: `BENCH_MODULES=...` did not narrow the run (all 33 ran); not investigated.

**What changed**
- **`f_masonry`: `bypass_mode: "param"`**, both outlets mix to `sample(in1, norm)` (nothing connected reads black, as under native bypass). Plan item 10 is 11 of 11.
- **`tests/bench_modules.py`: `BYPASS_EXPECT`** replaces `BYPASS_PASSTHROUGH_OUTLETS`; `bypass_issues()` is pure. **`tests/test_bench_expect.py`** fails if a `bypass_mode: "param"` module has an outlet with no expectation (a new Param-bypass module MUST extend the table) and exercises the comparator offline.
- **`f_vf_seeds` builds from `src/f_vf_seeds/definition.py`**; `build_seeds_multistage.py` is deleted. Seven new builder keys (all default-off and loud; `build/spec.md` "T019 keys"; `tests/test_build_seeds_keys.py`): pix_chain `gen_code`; param `pix_shared_attrui`, `pix_attr`, `range_menu_outlet`; native `bypass_target` (it used to be loud in native mode); `outlet_source`; mod_inlets `fanout` / `state_nodes`. The two quirks of the script-built patch (no `param_connect` on the dials, no `lbl_` label varnames) are carried by `legacy.control_box` / `legacy.element_box`. The definition uses `archetype: "source"` with `render_trigger: "inlet"` (also reproduces exactly) so the bench still treats seeds as a generator.
- **Builder bug fixed:** support pix ids `obj-50+` collided with the dial/attrui/label ids from ten widgets up (seeds has 13), silently garbling cords. `chain_id_base` moves the base only on collision (no other module's ids changed) and `build()` now fails on any duplicate box id. Lesson: when a rebuild's cords look absurd, check ids before suspecting the schema.
- **T026:** the two bench-patch generators share `tests/bench/patchbuild.py`, byte-identical output (`tests/test_bench_patchbuild.py`). **The JS half is closed as won't-do**: the 11 "shared" functions are not identical (see `build_cleanup/tasks.md` T026).
- Every new test and key was mutation-checked (17 + 29 + 10 + 10 mutants, all caught at the end; several first runs found real test gaps, e.g. `1 == 1.0` in Python hides a missing float conversion: compare serialized JSON).

**Waiting on Matt**
**Status (Matt, end of the 2026-10-06 sessions): the four items below, plus the untracked helpers in `scratch/`, are all "done for now" (closed, not reopened by the next session unless Matt does).** No outcome was recorded for any of them: the Vsynth look is NOT recorded as passed or failed, the GPU-cost question has no decision (the caveat below stays as written), `fluid-scratch.json` / `.maxpat` was not declared disposable (kept), and the six untracked `scratch/` files (`rollout_param_bypass.py`, `seeds_measure.py`, four `mutate_*.py`) were left as they are, untracked. Deleting the untracked ones is permanent.

1. **Vsynth eyeball of the 11 param-bypass modules** (every outlet = source, vecfield outlets = the input field; masonry is new). The offline suite and the bench prove wiring and values, not how it looks.
2. **The GPU-cost decision** (below): unchanged, still open.
3. **Re-upload `skills/vsynth-bpatcher`** then `./skills/check.sh stamp`: the skill does not yet mention the seven T019 keys, `chain_id_base` or `BYPASS_EXPECT`, so it is more stale than before (I did not edit it; do that first).

**Next, suggested**
1. The above. Then Phase 3 leftovers: `f_masonry` refactor (T015: it still drifts, 24 boxes only in the definition / 61 only in the patch; the definition's CODEBOX is now the shipped text, so `capture_raw.py` is the way), `f_texrouter`, `f_vf_vorticity`.
2. `f_sirds` stays off-limits (Matt).
3. `scratch/` was cleaned 2026-10-06 (T025 done: 26 tracked files and six untracked one-shots deleted after verification; see `build_cleanup/tasks.md`). Still untracked and awaiting Matt's call: `rollout_param_bypass.py` (merges a codebox and a bypass box into a Max-saved patch; all 11 modules are done, so only useful if another hand-built module moves to Param bypass), `seeds_measure.py` (measures a candidate definition against the shipped patch with uncapped drift examples; useful for the `f_masonry` refactor), and the four reusable mutation harnesses `mutate_bench_expect.py`, `mutate_builder_t019.py`, `mutate_seeds_def.py`, `mutate_patchbuild.py` (each runs the baseline first, restores the file, clears `__pycache__`; untracked, so deleting them is permanent). Tracked and held back: `fluid-scratch.json` / `.maxpat` (a saved Vsynth scratch patch; delete once Matt confirms it is disposable). `skills/MANIFEST.md` is Matt's: leave it.

## 2026-10-06 first session: plan item 10 rollout done for 10 of 11 modules (superseded above for masonry, seeds and T026)

**Done, four commits** (`ca02912`, `5f41a78`, `0274043`, `8627fce`; offline suite green after each, `drift.py` still 31 of 39): `f_vf_glow` (pilot), `f_vf_streak`, `f_vf_chroma`, `f_vf_prism`, `f_caustic`, `f_vf_split`, `f_stipple`, `f_chladni`, `f_grain`, `f_vf_advect` now use `bypass_mode: "param"` with a codebox `Param bypass_gate` and a passthrough on every outlet. The rule, details per module and what is left are in plan.md item 10 (read that paragraph). Short version: an outlet mixes to the input of its own signal kind, else its neutral value; isolated-layer outlets show the SOURCE; prism/advect out3 show the vecfield INPUT (neutral if unconnected). **Not touched: `f_masonry`** (hand-built, drifting, due a refactor).

**Waiting on Matt (the live bench has run, green; the Vsynth look has not happened)**
1. Eyeball each of the 10 in Vsynth with bypass on (every outlet = source, vecfield outlets = input field). The offline suite proves wiring and that the Param is driven, not what it looks like.
2. ~~Live bench~~ **Done by Matt, same day: green.** `./bench.sh --changed` ran `bench_modules` (2/2, 0 unexpected contract issues across 33 modules, 77 s) and `bench_fluid_module` (4/4); the other five files were skipped as unchanged, and `bench_green.json` is now seeded. So out2 == in1 under bypass is confirmed live for glow, streak, chroma, prism, caustic, split and advect (`BYPASS_PASSTHROUGH_OUTLETS`). **Coverage gap:** that check only runs for `archetype == "processor"`, so `f_stipple`, `f_chladni`, `f_grain` have no live bypass assertion, and prism/advect out3 are unchecked. Closing it needs a per-module expected-value table in `bench_modules.py`, validated live.

**How the rollout was done (reuse for `f_masonry`)**: edit the definition (`bypass_mode`) and the codebox, run `build/py.sh build/build_patcher.py src/<m>/definition.py`, then `python3 scratch/rollout_param_bypass.py <m> [--dry-run] [--accept-layout]` (UNTRACKED helper: commit it or delete it as you prefer). It takes ONLY the codebox text and the bypass box from the rebuild and aborts (restore with `git checkout -- package/patchers/<m>.maxpat`) on any other difference, so Max-normalisation noise (inlet/outlet `index`, `parameter_unitstyle`) and layout never reach the shipped patch. Two modes: a builder-formatted file is parsed and dumped; a **Max-saved** file (`f_chladni`, `f_grain`, `f_vf_advect`, with Max-renumbered ids) is patched in the TEXT (so the other ~2000 lines stay byte-identical), pairing codeboxes by similarity and the bypass box by what it is, and the result is re-parsed and must equal the intended structure. After any merge run `build/py.sh build/drift.py`: it pairs by content and must still say ok (the end-to-end check for the Max-saved ones). `--accept-layout` was needed once, for `f_stipple` (a uniform +3.5 px x-shift of its service-area objects in the edit view, because the `prepend param` box differs from the attrui it replaces).

**Seeds (T019), analysis only, no code**: closer than `f_sirds` was. Gaps in `build_patcher.py`: (1) ONE attrui fanning to several stages (the `pix_target` list makes one attrui PER extra stage; seeds' shipped patch has one attrui with two cords, so a "shared attrui" mode is needed); (2) `inlet_fanout` covers only the primary inlet, seeds has four inlets each with its own `vs_inState` and fanout (vecfield's state goes nowhere: vestigial); (3) native bypass to a target list (`1c`, `4`: `bypass_target` is loud in native mode); (4) `bomb` binds its attrui to `active_blend` (check whether an `attr_name`-style key exists); (5) the two search stages differ only by baked salts: `definition.py` is Python and can render both codebox strings itself, so probably no key (verify the builder accepts per-node codebox strings). Absorbing it regenerates the shipped patch from the builder, so expect edit-view layout to change (use `overrides`/the layout pass) and verify with `drift.py`; do NOT change seeds' bypass behaviour in that step (a generator with no source input, a separate decision). The shipped `f_vf_seeds` is on the never-regenerate list: the aim is a definition that reproduces it, as for `f_grain`.

**T026 (bench dedupe), analysis only**: `make_bench.py` and `make_module_bench.py` live in `tests/bench/`; extract `obj`/`wire` into a shared module and prove it by regenerating both bench patches byte-identically (offline). The JS half (11 shared functions in `bench.js` / `bench_module.js`) first needs a diff to confirm they are identical and a check of which engine the bench patches use (`js` vs `v8`, which decides the include mechanism); it needs one live full `bench.sh`.

**Pitfall found**: `drift.py` says "ok" for Max-saved files by pairing boxes by content, but their ids differ from a rebuild, so an id-based comparison of a rebuild against the shipped file is meaningless for `f_chladni`, `f_grain`, `f_vf_advect` (and any other Max-re-saved module).

**GPU-cost caveat of the rollout (open, NOT yet decided or tested).** Native bypass skipped the shader entirely, so a bypassed module cost almost nothing. Under `bypass_mode: "param"` the shader always runs and only the outputs are gated (`f_vf_warp` already worked this way). It matters most for the heavy modules: `f_vf_glow` (48-tap loop), `f_vf_prism`, `f_vf_streak`, `f_vf_chroma`, `f_caustic`, `f_grain`. The bench prints `bypass-leaves-active=1` for each converted module; that is informational and now expected. A guard that skips the heavy loop when `bypass_gate` is 1 is conceivable, but how GenExpr handles a branch around a loop (and whether it saves anything on the GPU, where both sides of a branch may still run) is UNKNOWN: test it live on `f_vf_glow` with the bench's fps measurement before building anything on it. Whether the loss matters in performance is Matt's call.

**Unconfirmed**: the live bench lists `f_grain` among the modules where the documented `bypass 1` control MESSAGE does not work. The rollout did not touch that wiring (9-line merge: codebox plus bypass block), so it very probably predates it, but no earlier bench log was compared.

**Next session, suggested order**
1. Matt's Vsynth eyeball of the 10 modules (see above), and the decision on the GPU-cost caveat.
2. `f_masonry` bypass (surgical edit, or with its refactor); then close the bench coverage gap (a per-module expected-value table in `tests/bench_modules.py` for dual/generator archetypes and the out3 vecfield outlets, validated live).
3. Seeds (T019): start by writing a `src/f_vf_seeds/definition.py` candidate using only existing builder keys and measuring the real remaining gap with `build/drift.py -v f_vf_seeds`, then add the missing keys one at a time (each default-off, loud, mutation-checked in `tests/test_build_multistage.py`).
4. T026 (offline Python half first, JS half with one live full `bench.sh`).
5. `scratch/rollout_param_bypass.py` is untracked: commit or delete. `skills/MANIFEST.md` is modified (Matt's skill-upload work), not mine: leave it.

## Start here (state at the end of 2026-10-05; the 2026-10-06 section above supersedes it where they differ)

**State.** Offline suite green (`tests/run.sh`, 17 files, exit 0); `build/py.sh build/drift.py` says 31 of 39 exact; `generate_menu.py --check` and `generate_launch.py --check` both say up to date. **No shipped patcher changed this session** (fluid and `f_vf_warp` reproduce what ships, so neither was regenerated), so nothing needs the bench. The one runtime change is `package/javascript/f_addmod.js` (next list).

**Waiting on Matt**
1. **In Max, add `Ngon` and `Matrix 2` from the `f_modules` menu once.** `f_addmod.js`'s SIZES table is now generated from the panels, so those two get 154 x 91 and 230 x 120 instead of the 200 x 150 fallback they had (everything else is unchanged; the generated patcher is byte-identical to the old one).
2. **Re-upload `skills/vsynth-bpatcher`, then `./skills/check.sh stamp`** (`check.sh` reports it STALE; it is the only one). It now describes the menu generator, the multi-stage builder keys, `bypass_mode: "param"` and the passthrough convention, and no longer points at the deleted `build_fluid.py`.
3. **Decide the rest of `scratch/`** (proposal in `build_cleanup/tasks.md` T025: 35 files, nothing deleted yet) and the `LICENSE.md` row that still lists `tools/` among the MIT paths (with the licence wording review, `packaging/T012`).
4. The earlier open questions still stand: `f_vf_advect`'s `mix_pct` numbox answering to `mix`, `f_grain`'s three odd tooltips, `f_droste`'s bypass jsui block, `f_grain` / `f_lens` coming off plan.md's never-regenerate list. **New:** `f_vf_flow`'s header says its bypass is a neutral vecfield, not a passthrough (it is a generator with only an optional scalar input, so that may be right).

**Decision (Matt, 2026-10-05): a bypassed module is a passthrough on every outlet.** `f_vf_warp` already does it (`out1 = mix(warped, in1, bypass_gate)` on both outlets).

**Next, in suggested order**
1. **Rest of `build_cleanup/T019` (left open on purpose).** **Matt, end of session: ignore `f_sirds`; do not work on it.** `build_sirds.py` stays as it is, and `drift.py` keeps covering it through its `build()`. For the record, absorbing it would need five more builder keys: a per-node templated codebox (`stage_index` and `strip_width` are baked in), a second module inlet fanned out to 12 stages, a plain feed from routepass into stage 0 (no `vs_inState`), native bypass broadcast to a target list (`bypass_target` is loud in native mode today), and one attrui whose cords reach many stages (`pix_target` as a list makes one attrui PER extra stage, which would not reproduce the shipped patch). `f_vf_seeds` (`build_seeds_multistage.py`, 755 lines) was never assessed and was not started; ask Matt before spending time on it (the `raw_ui.json` route, as `f_grain`, is the fallback if it is too bespoke).
2. **Plan.md item 10 rollout** (the 11 modules whose secondary outlets flip under native `@bypass`): move each to `bypass_mode: "param"` with the passthrough rule. This edits shipped patches and codeboxes by hand (they are on or near the never-regenerate list), so Matt eyeballs each in Vsynth and `tests/bench.sh --changed` runs.
3. **Phase 3 leftovers:** `f_masonry` (T015, will be refactored), `f_texrouter` (shipped, not in use), `f_vf_vorticity` (parked, never completed).
4. **T026** (optional, needs Max): deduplicate the bench JS and the two `make_*bench.py` helpers.

**What changed in the second session, in one list** (documented in `build/spec.md`, "Multi-stage keys", and in `tests/test_build_multistage.py` / `tests/test_generate_menu.py`):
- **New builder keys (T016/T017), all default-off and loud:** per-node `pix_attrs` (verbatim attribute string replacing `@type`/`@adapt`); per-param `pix_target` as a list (first stage = the widget's `param_connect`, one extra attrui per further stage) and `ui: False` (route token plus attrui, no widget/label/panel slot); top-level `inlet_fanout` (`{texture: [[node, inlet]...], state: [node...], state_param}`), `draw_triggers` (`r draw` to inlet 0 of each stage) and `bypass_mode: "param"` with `bypass_param` / `bypass_target` (jsui -> `prepend param <name>` -> the stage(s); the builder checks the target codebox declares the Param). The layout pass places `r draw` beside `vs_inState` and gives extra attruis their own role (`pre_extra`, override key `<param>.pre_extra.<k>`).
- **`f_vf_fluid` is built by `build_patcher.py` from its `definition.py`** (`build_fluid.py` deleted; its `verify()` checks are in `test_build_multistage.py`). **`f_vf_warp`, `f_stereo` and `f_vf_flow` now reproduce exactly.**
- **The `f_modules` menu is generated:** `src/f_modules/menu.py` (categories as `(display, module, vecfield)`, `SIZE_OVERRIDES` with reasons, `NOT_IN_MENU` with reasons) -> `build/generate_menu.py` -> `f_modules.maxpat` (byte-identical to what shipped) and the SIZES block of `f_addmod.js`. It checks the menu against the README Patches table (labels, order, members), that every shipped patcher is in the menu or exempted, and that no size override is stale. `tools/` and the old 5-category `build/tools/f_modules/build_modules.py` are deleted (`packaging/T022` closed).
- **Loose ends:** the README no longer says helpfile generation uses the API (it never did); `build/helpfile_queue.json` is untracked and gitignored; four superseded regen scripts are gone from `scratch/`.

**What changed in the first session of the day, in one list** (each is documented in `build/spec.md`, `.specify/build_layout/spec.md`, and the skill):

- **Definitions now reproduce the patch** for `f_mobius`, `f_droste`, `f_vf_advect`, `f_grain`, `f_lens` and the four oldest colour modules; `f_stereo` is partly done. Most patches were **not** regenerated: hand-built ones stay as shipped and their definition describes them.
- **New tools:** `build/capture_raw.py` (derives a module's `raw_ui.json` from the shipped patch); `build/capture.py` also takes a live.text's colours, `suppressinlet` and a comment's `numinlets`.
- **New builder keys** (all explicit, default-off): top level `route_bypass`, `route_first`, `route_reject_to_pix`, `inlet_comment`, `pix_context`, `legacy` (`pix_varname`, `autopattr_varname`, `bypass_jsui_saved`, `control_valueof`, `control_box`, `element_valueof`, `element_box`); per param `modmode`, `route_name`, `"hint": None`, `pix_wire: False`, `color_expression`, `"label": None`; per outlet `hint`.
- **Builder fixes:** `param_connect` follows `pix_target` (this exposed `f_vf_optical_flow`'s mis-bound dials); `_parameter_range` message bounds are Max-style (`1.` not `1.0`); the layout pass places `routepass` below the lane for `route_first`, puts the bypass jsui in lane column 0 for `route_bypass`, and keeps the service area clear of a wide route box.
- **`legacy` exists because** every oldest module carries artefacts of objects Max re-created (pix varname `jit.gl.pix_AA`, auto-named `autopattr`s, an inert saved block on the bypass jsui). Regenerating would rename the `autopattr`, which could affect preset recall, and nothing can verify that offline. T018's "shared-label grid" was one module's layout (`f_channel_grader`), not a schema.

**Rules of thumb**
- When the patch is the newer side, edit the *definition* to match it. When the builder is the newer side and the difference is additive and lossless, edit the *patch* surgically: parse, change, dump, and verify the result equals the old content plus exactly the change (`skills/maxpat-json-authoring`). A module that reproduces exactly needs no regeneration; never regenerate a hand-built one (list in `.specify/plan.md`).
- A hand-built module is the generic part from the builder plus the bespoke part in `raw_ui.json` (`capture_raw.py`), presentation state in `overrides` (`capture.py`), Max leftovers in `legacy`.
- Mutation-check every new test: break the code in each way you can think of and confirm a test fails. For a mutant in a *definition*, include `tests/test_drift.py` in the run, because the drift ratchet is the guard there.
- Do not rerun the bench to re-verify your own changes; do not add a module to the drift baseline (it only shrinks).

**Pitfalls hit this session**
- **A mutation run is only evidence if the unmutated tests pass first.** One harness reported "28 caught" while the baseline was already red (a bug in the new test), so every mutant "failed". Make the harness run the baseline first and abort if it is red.
- **Stale `.pyc`:** a mutant restore within the same second and with the same file size leaves a valid-looking cache, so a later run (or a different interpreter, `uv run` is 3.12, `build/py.sh` is 3.14) builds the mutant. Clear `__pycache__` between mutants, or run with `PYTHONDONTWRITEBYTECODE=1`.
- **`create_file` can write to a different filesystem than Desktop Commander sees** (it reported "already exists" for a file that was not on Matt's disk). Write repo files with Desktop Commander's `write_file` (it needs an existing parent directory) or a Python script.
- **Something else may be editing the repo.** `f_vf_warp/definition.py` and the drift baseline had already been changed when this session reached them (compatible with the plan, so they were kept). Run `git status` before editing and look at unexpected diffs before overwriting.
- **`git add <dir>` fails on a directory that is already gone** and an `&&` chain then silently skips the commit: after `git rm -r`, do not name the directory again.
- **A generator that preserves text outside its block (`f_addmod.js`) will not call a trailing edit "stale"**; a staleness test has to edit inside the generated block.
- **Bench name collision:** close every patch holding an instance of the module (its help, demos) and reopen `tests/bench/bench.maxpat` before `./bench.sh --changed`, or it fails with `name X already in use`.
- **Desktop Commander refuses any shell command that contains the bare token `dd`** (the disk-dump command), even as a Python variable name or inside quoted text: "Command not allowed", and nothing runs. Pick another variable name, and write text that mentions it with the file-writing tool, not a heredoc. (Writing this very note through a heredoc triggered it.)
- **That tool only writes inside allowed directories** (`/Users/matt/Github`, not `/tmp`): stage files under the repo's `scratch/`.
- **Heredoc edit scripts:** anchors must match exactly. An `AssertionError` leaves files unwritten, but a *following* `git commit` line still runs unless you chain it with `&&`. Once a commit claimed records that had not been written (amended). Verify a written test file parses (`python3 -c "import ast; ast.parse(...)"`): escaped quotes in a heredoc caused a `SyntaxError`.
- **Codeboxes can have CRLF endings** (`f_grain`, `f_tone_curve`): read a `.gen` file with `newline=""`.
- **Check for a half-finished earlier session before editing:** when a connection drops, work can be left uncommitted in the tree. Look at `git status` and file timestamps first and do not overwrite it (this session found and finished one: `d8e32ac`).
- A route box is never narrower than its text (6.5 px per character): with long token names it is wider than its lane.

**How he wants to work:** discuss architecture before code; slow things in the background; he is fine with Claude committing on f_ projects (a commit that sweeps in files Claude did not work on is just a save checkpoint: a plain message, nothing elaborate); start each conversation by reading `README.md`, `HANDOFF.md` and `.specify/plan.md`.

## Earlier today (2026-10-05): Phases 1 and 2 detail

Read `.specify/build_cleanup/tasks.md` first (status line, T006 to T013a carry the detail and the evidence).

- **T006** `build/drift.py` pairs renamed boxes (`boxes_renamed`, reported once as `definition -> patch`).
- **T008, by a live Max round-trip done with Matt** (Max 9.2.0; procedure in tasks.md, repeatable for T030).
  The 11 "exact" modules were NOT round-trip evidence: Max never re-saved them. Max normalises inlet/outlet
  `index`, a dial's `mmin` 0.0 / `mmax` 127.0, a numbox's `mmin` 0.0, a float numbox's unitstyle 0 to 1,
  comment width/height, `restore_extra`, live.text fontsize 9.5. Max preserves the autopattr varname, a
  dial's `param_connect` and a comment's `varname`, so those stay drift (pinned by tests).
- **T007** `f_stereo` has a definition (hand-built, pre-schema, 19 props / 11 layout / cord differences left);
  `f_vf_optical_flow` moved into `src/` and reproduces exactly; `f_vf_vortex_multi_version` is in `archive/`
  (README row removed, `f_Launch` regenerated to 39 modules); five modules are `out_of_scope` in the baseline
  with recorded reasons; `f_util_profile`'s stale definition was deleted.
- **Phase 2** `overrides`: ADR in `build/spec.md`; `element_keys` / `apply_overrides` in `build_patcher.py`;
  `build/capture.py` (`--dry-run`, `--keys`); capture takes presentation state only and refuses, with the
  reason, label text, hints, ranges, `varname`, `param_connect`. Piloted on `f_vf_fieldmap` and `f_vf_warp`.
- **T029** the `PI = ...` compile failure on Max 9.2.0 is in both codebox skills.
- **T013a** the `lbl_<param>` label varnames (the builder writes them so the panel-toggle JS can address
  labels) were added to the 70 label comments in 14 patchers that lacked them, by a verified surgical edit.
- **T013** definitions written back from the patches: `f_vf_repulse`, `f_vf_fieldmap`, `f_weave` now reproduce
  exactly (`f_vf_repulse`'s shipped codebox is a real behaviour change: zoom remap, out-of-bounds gate, neutral
  output under bypass). `f_vf_fieldmap` and `f_vf_repulse` joined the never-regenerate list. `f_vf_vorticity`
  is parked: the module was never completed (README marks it ⚠). `f_vf_warp` only has `bypass_gate` left (T017).

## Previous session (2026-10-04, second): build, tools and test cleanup

A project, not a task: `.specify/build_cleanup/spec.md` and `tasks.md` (write IDs as `build_cleanup/T006`).
Read `tasks.md` first; its top section has the measured drift state and the grouping of every module.

### Start here (as it was then)

- **Ask Matt what he wants to work on.** The session ended with him saying he had lost track of what he
  wanted to do ("we've spent all afternoon on this"). The `build_cleanup` list below is the default only
  if he has no other aim.
- **How he wants to work:** slow things go in the background (`tests/bg.sh`), not foreground polling;
  do not rerun the bench to re-verify your own changes (that is what `--changed` is for); discuss
  architecture before code; committing on f_ projects is fine (he said so on 2026-10-04).

### Decisions (Matt)

- **`definition.py` is the source of truth.** A hand edit in Max must be written back into it, extending
  the schema when it cannot yet express the edit.
- **Layout belongs in `definition.py` too**, not formula-only: "the shape of definition.py is in progress
  and we want it to hold whatever it needs to hold."
- **The drift list is a stopgap**: a ratchet that only shrinks and is deleted when empty.
- **The generic `overrides` block is approved** (not layout-only), to be piloted on `f_chladni` and
  `f_vf_flow` (build_cleanup/T009 to T012).

### Done (13 commits, in order)

- `1ab9ee5` removed 16 one-shot scripts (`tools/masonry/*`, `tools/util_profile/*`, five more in `tools/`,
  `build/migrate_to_attrui.py`, which would have reverted `f_vf_warp`'s deliberate `prepend param
  bypass_gate`). `tools/` now holds only the two menu scripts and its README.
- `f933082` `tests/jobs/` had grown to 73 GB (14,171 job dirs, never pruned); deleted, and
  `benchclient.new_job()` now keeps the newest 50.
- `8fc3ec6` `tests/bench.sh` runs a regression set by default; `--all` adds `bench_perf` and
  `bench_fluid_probes`; `--list` prints the selection without Max.
- `dc10d50` `build/audit_interface.py` merged into `tests/module_contract.py`, which now checks every stage
  of every module (the audit only looked at the first pix). 9 documented `KNOWN_ISSUES`.
- `52205e6` `build()` made pure (the toggle JS comes back via `side_files`); `build/drift.py`; the
  `tests/test_drift.py` ratchet and `tests/drift_baseline.json`.
- `18eb7cd` **`f_stereo` was broken on Max 9.2.0**: its codebox assigned `PI = ...`, which 9.2.0 refuses to
  compile, so its pix produced nothing (20 module-bench issues, all in this module). Renamed to `pi_val`.
  It has no definition, so carry the fix into one (build_cleanup/T007).
- `ee43b7d` bench fixes: the module-bench files now reopen their own bench (they demanded it be open),
  `bench.sh` requires the codebox bench only when needed, `bench_fluid_module` T038a warmup 48 to 24 (the
  integrating field saturated), and `bench_last.log` starts with the Max version and date.
- `649e640` the `build_cleanup` spec and task list, plan.md item 14, this file.
- `d7fe787` **bench speed: the default `bench.sh` run goes from ~440 s to 188 s** by moving `bench_fluid`
  T022 (soak, 190 s) and T021 (cost, 45 s) to an `@slow` tier (`--slow`, or `--all`).
- `5756370` recorded what was tried and rejected, with numbers, in `tests/README.md`: free-running frames
  (4% faster, broke secondary-output capture), content-hashed gen names (no gain), running the two benches in
  parallel (fails: Max error capture is global).
- `2b13bc4` **`tests/bench.sh --changed`** (`tests/benchdeps.py`): skips bench files whose Python imports, data
  files and Max/Vsynth versions match their last green run; `bench_modules` runs only the modules whose patcher
  changed (`BENCH_MODULES`). Record in `tests/jobs/bench_green.json` (local, gitignored).
- `23b47b8` parked the background-bench ideas as build_cleanup/T033.
- `978caf4` **`tests/bg.sh`** background runner: `start [offline|bench|all]` returns at once (0.2 s), then
  `status` (exit 0 passed, 1 failed, 2 running), `log`, `stop`, `list`; one bench run at a time; macOS
  notification on finish.

### State

- **`tests/run.sh`: 12 files, all green** (last run through `tests/bg.sh`, 54 s).
- **Live bench:** the last full default run was green on Max 9.2.0, 7/7 files, 188 s. Since then
  `bench_modules.py` gained the `BENCH_MODULES` filter and `bench.sh` gained `--changed` and recording: those are
  **tested offline only (19 + 10 tests, mutation-checked), never run against live Max.**
  `tests/jobs/bench_green.json` does not exist yet: the first plain `tests/bench.sh` seeds it, then `--changed` works.
- **`tests/bg.sh` does not isolate the bench from Matt's Max session**: reopening the bench still brings Max to
  the front, and the bench's global error trap can pick up errors caused in Max meanwhile (build_cleanup/T033 b to d).
- **Installed Max is 9.2.0; the patches were saved in 9.1.4** (build_cleanup/T028 to T030).
- **Drift: 11 of 40 shipped patchers reproduce from their definitions**; 21 drift, 7 have no definition, 1 fails
  to build. Only `f_chladni` and `f_vf_flow` are cosmetic-only, so most drift needs schema work, not just layout
  capture (numbers and the four kinds of drift: `build_cleanup/tasks.md`).
- **Skills:** `./skills/check.sh` showed `vsynth-bpatcher` STALE when this session ended (Matt was uploading it): run it, then `./skills/check.sh stamp` once the upload is current.
- Lead for the parked `getattr` console error: it reaches the bench while `bench_module.maxpat` loads Vsynth
  (build_cleanup/T032).

### Next session

1. **Ask Matt** what he wants to work on (see Start here).
2. If it is the cleanup: **build_cleanup Phase 1** (`T006` to `T008`): pair renamed boxes in `build/drift.py` so
   an edited label reports once as `old -> new`; decide the 7 definition-less patchers; settle the four ambiguous
   Max-normalisation cases (`autopattr` varname, `param_connect`, inlet/outlet `index`).
3. **Phase 2** (`T009` to `T012`): the `overrides` block (approved) and `--capture`, piloted on `f_chladni` and
   `f_vf_flow`. Design the element-key scheme first and record it as an ADR in `build/spec.md`.
4. Then Phase 3 module by module, Phase 4 schema gaps (Param-bypass first), Phase 5 the generated `f_modules`
   menu, Phase 6 loose ends. Optional and only if wanted: build_cleanup/T032a (chain passes in one bench job) and
   T033 b to d (focus, a dedicated Max instance).
5. **Matt:** build_cleanup/T027 (skill upload and `check.sh stamp`), then T029 (a `PI` gotcha in `jit-gen-codebox`,
   one more upload).

---

## Previous session (2026-10-02 to 2026-10-04): `f_Launch` and licensing

### Done

- **packaging/T014, submission research.** The Cycling '74 form asks for author, email, a link to a
  downloadable package, a summary and a ready date, and says follow-up is likely. Package
  Authoring Part 2: a ReadMe **and a License** must be in the package; `icon.png` is 500x500;
  `homepatcher` is what the Package Manager's Launch button opens. Not documented anywhere
  read: how the registry ingests an archive (confirm at submission; packages@cycling74.com).
  Part 3 (refpages) was not read. Nothing requires the repo root to be the package, so the
  `package/` subfolder + release zip approach stands.
- **packaging/T021, `f_Launch` (Matt confirmed in Max: "looks great", not itemized).**
  `build/generate_launch.py` parses the README Patches table and writes
  `package/extras/f_Launch.maxpat`: 9 tabs (native subpatcher tabs, `showontab`), 40 modules,
  20 clickable (textbutton to `loadunique <name>.maxhelp` to `pcontrol`) and 20 greyed (no
  helpfile; a click on a missing helpfile fails silently in Max, tested). `--check` mode;
  fails on unparseable rows, duplicates, README/patchers mismatch, descriptions over 110
  chars. `package-info.json` now has `"homepatcher": "f_Launch.maxpat"` (a bare filename, as
  in every installed package checked). `tests/test_launch.py` has 8 tests, including a drift
  check against the shipped `f_modules.maxpat`.
- **README Patches table** regrouped under the `f_modules` menu categories (Scope, Discrete,
  Spatial, Optical, ∇ Generators, ∇ Processors, Color / Tone, Utilities, Audio) and 18
  descriptions shortened to at most 110 chars. **It is now the source of truth for
  `f_Launch`: after editing it, run `build/py.sh build/generate_launch.py`**; the test fails
  if the committed file is stale.
- **Licensing, decided, wording awaiting Matt's review (packaging/T012).** Rule in the root
  `LICENSE.md`: everything is MIT except `package/`, `src/` and `.specify/`, which get
  CC BY-NC 4.0 plus an additional permission for paid professional work (performances, client
  work, selling rendered output, paid teaching; no selling or bundling the software). The
  extra paragraph exists because CC's NonCommercial judges purpose of use, so a paid gig could
  otherwise count as commercial. `package/license.md` is self-contained for the zip. The three
  `docs/vsynth-reference/` files got a header note naming Vsynth's license. Details in
  `docs/max-reference/packaging.md`.

### State

Full test suite green (8 files, no failures, about 36 s). `build/release.sh --working-tree`
builds and the zip contains `extras/f_Launch.maxpat` and `license.md`. `./skills/check.sh`:
all uploads current.

### Committed

`de89863` ("license", 2026-10-04) holds everything above in 18 files, including the three `scratch/`
tests and `package/patchers/f_masonry.maxpat` (see Loose threads). The three-way commit split
suggested at the time was not used.

### The build/tools review requested at the end of that session (now a project)

Done or moved into `.specify/build_cleanup/`: the `build/` vs `tools/` boundary (Phase 0: one-shot
scripts removed, the two menu scripts left until they are replaced), packaging/T022 (the stale
5-category menu script: `build_cleanup/T020`-`T021`), packaging/T018 (README says helpfile generation
is "via Claude API", `plan.md` says it no longer is: `build_cleanup/T022`, still unopened), and the
definition/patch drift tech-debt pass (the project itself). `generate_launch.py` was used as the
template for the drift check and is the template for the menu generator.

### Outstanding, Matt's

packaging/T008 open the renamed demos in Max and read the console. packaging/T011 message to Kevin: install
method, Max and Vsynth versions, first console error, and whether paid performance with
Vsynth counts as commercial use under its license (not yet drafted). packaging/T012 review the license
wording. packaging/T013 `icon.png` (500x500). Skim `ideas/`, `docs/`, `.specify/` and `src/` for
third-party text before publishing (not audited). Resolve the five ⚠ rows before submission
(`f_ngon`, `f_vf_vortex_multi_version`, `f_vf_vorticity`, `f_a_ripple`, `f_chladni_audio`);
`f_Launch` lists them. packaging/T015 (tag `v0.1.0`) waits on packaging/T008, packaging/T012 and packaging/T013.

### Loose threads

- **`package/patchers/f_masonry.maxpat` was re-saved by Max, not edited by Claude** (appversion
  9.1.4 to 9.2.0, new `restore_extra` data), probably while testing `f_Launch` clicks. It went
  into `de89863` with everything else. If that was unintended, restore it with
  `git checkout de89863~1 -- package/patchers/f_masonry.maxpat` and commit.
- `scratch/helpfile_open_test.maxpat`, `launch_tab_test.maxpat` and `build_launch_tab_test.py`
  (committed in `de89863`) are the throwaway tests for the packaging/T021 mechanisms; keep or delete.
- Matt's Max check of `f_Launch` was not itemized, so these are unconfirmed in detail: the
  `∇` and `Color / Tone` tab labels, 9 tabs fitting the strip, and `;` `,` `"` and ⚠ rendering
  in descriptions (fallback: change `display()` in the generator).
- Dates: the license decisions were made 2026-10-04 (file timestamps); the f_Launch work was
  2026-10-02 onward. Some task text says 2026-10-02 for work done in between.
- License caveats: Matt's view that `f_` is not an adaptation of Vsynth is his reading and
  Kevin has not been asked; not legal advice; CC advises against its licenses for software
  (Vsynth uses one anyway).

---

## Earlier sessions (condensed 2026-10-04)

Condensed from about 740 lines. The full text is in git: `git show de89863:HANDOFF.md`
(older versions: `git log -p HANDOFF.md`). Anything still open is under "Still live".

- **2026-10-01, packaging.** `package/` stays a subfolder and ships as a release zip; `demos/`
  became `package/examples/` (`f_demo_` prefix); the `moduleSize.js` copy was removed (Matt
  reports it safe); `build/release.sh`, `package/readme.md` and the README install section
  were written. Detail: `docs/max-reference/packaging.md`, `.specify/packaging/tasks.md`.
- **2026-09-29c, `f_vf_fluid` Phases 3 and 4.** Tuned by eye: 256² stays; defaults `dt` 0.01,
  `force` 0.02, `drag` 0.5, `gain` 1.0, `viscosity` 0.085; `project` left on the panel. Docs,
  helpfile, menu slot 5 (∇ Processors) and `f_addmod.js` size fixes done; regression green.
  Detail: `.specify/f_vf_fluid/tasks.md`.
- **2026-09-29b, skills consolidated.** `f_/skills/` is the single source (eight skills,
  `claude-scaffold/skills/` symlinks to it); `skills/check.sh` and `MANIFEST.md` track what
  was last uploaded to claude.ai.
- **2026-09-29a and 09-28, `f_vf_fluid` tuning work.** `viscosity` became a 0 to 1 dial; a force
  tap grid fixed aliasing at HD/4K; `taps` came off the panel (still a codebox Param, default
  8); tuning patch at `~/Vsynth/patterns/fluid_tuning.maxpat`.
- **2026-09-24 and earlier.** Layout pass; drift survey of all 33 definitions; bypass
  investigation (three bugs fixed: `f_lens`, `f_sirds`, `f_vf_warp`); `f_vf_fluid` specced and
  built through Phase 2; `f_masonry` `quantize` removed and a route off-by-one fixed.

### Still live

**Module work**
- **Work Queue item 10** (`.specify/plan.md`): 11 modules show flipped secondary outlets
  (outlets 2+) under native `@bypass`: `f_caustic`, `f_chladni`, `f_grain`, `f_masonry`,
  `f_stipple`, `f_vf_advect`, `f_vf_chroma`, `f_vf_glow`, `f_vf_prism`, `f_vf_split`,
  `f_vf_streak`. Matt eyeballs each in Vsynth and decides the bypassed state; fix with the
  `f_vf_warp` recipe (drive a non-`bypass` Param, hand-edit). Not a defect: `f_vf_advect`,
  `f_vf_optical_flow` and `f_vf_seeds` keep GPU stages running under bypass by design.
- **`f_chladni` does not appear from the `f_modules` menu** (an empty rectangle). Parked by
  Matt: do not raise unprompted. If picked up: the size of the empty rectangle (200×150 means
  a wrong symbol reached `addmod`; 299×234 means the file failed to load), then the Max
  console. Whether it ever worked from the menu is unknown.
- **Definition/patch drift** (superseded: now the `build_cleanup` project, with current numbers in
  `.specify/build_cleanup/tasks.md`; `tests/drift_baseline.json` is the machine-readable list):
  23 of 33 `src/*/definition.py` differ from their shipped patchers
  (9 definitions behind the patch, 10 predate the builder, 3 own build scripts, 1 blocked on
  `f_vf_vortex`). **Do not regenerate** `f_vf_warp`, `f_lens`, `f_vf_fieldmap`,
  `f_vf_repulse` or `f_masonry` (hand-edited); open decision whether to add fieldmap and
  repulse to `plan.md`'s never-regenerate list. Before trusting a regen:
  `build/py.sh build/build_patcher.py src/<m>/definition.py && git diff -w --stat --
  package/patchers/<m>.maxpat`, and `git checkout --` the file if the diff isn't tiny.
  `build/drift.py` replaced the scratch drift scripts (`scratch/regen_drift_*.py` can go, see
  build_cleanup/T025); the task list is `.specify/build_cleanup/tasks.md`.
- `f_vf_fluid` is script-built (`src/f_vf_fluid/build_fluid.py`), safe to regenerate; once
  hand-edited it joins the never-regenerate list.
- Build-schema gaps 3 to 6 are in `ideas/build_patcher_schema_gaps.md`, none attempted; gap 6
  (Param-based bypass) is the same mechanism as item 10.
- `f_a_ripple`: DSP done and confirmed by ear; UI is still plain flonums and toggles (reuse
  analysis in `ideas/f_a_build_process.md`), then Phase 5 docs and helpfile.
- Small: `f_vf_seeds` bottom dials sit below its 160 px panel; the `chladni` size in
  `f_addmod.js` is larger than its panel; `f_vecfield_type.md`'s producers table is
  incomplete; `project` not yet tried on a compressive force; `f_droste` lacks `autopattr`
  (plain box with `varname` `droste_autopattr`); modules whose pix use a fixed `@name` cannot
  exist twice in one Max session; the bench could re-verify `f_vf_vorticity` and trace
  `f_apollonian`'s `debug_ok`.

**Build and test tooling** (relevant to the next session)
- `build/extract_params.py --all` rewrites the tracked `build/helpfile_queue.json` (about
  2,100 lines); restore it, don't commit it.
- Bench: it keeps a Param's last value between jobs, so pin every Param a measurement depends
  on. "Name already in use" errors (`ob3d does not allow multiple bindings`) mean another open
  patch holds fixed `@name`s: close every other patch and reopen `bench_module.maxpat`.
  Relaunch with `open -a Max tests/bench/bench.maxpat`; run long bench files in the background
  and poll the log. `scratch/run_subset.py <names>` and `scratch/run_module.py <name>` run
  chosen tests or one module.
- Unexplained: loading about 30 modules into one bench session scrambled other modules' dial
  `_parameter_range`; one intermittent ERROR in
  `bench_control.py::test_frames_arrive_during_job`; `bench_src` kept but not proven necessary.
- With Desktop Commander, scripts must live under an allowed path (`scratch/` works, `/tmp`
  does not).
- GenExpr and Vsynth facts found along the way live in `skills/` (for example: a unary minus
  before a parenthesis mis-parses; the NaN guard is `switch(abs(x) < 1e30, x, 0)`).

**Skills**
- `f_/skills/` holds domain knowledge (Max, Vsynth, audio DSP); generic workflow scaffolding
  stays in `claude-scaffold`. Upload rule: everything in `f_/skills/`. After uploading to
  claude.ai run `./skills/check.sh stamp`; plain `./skills/check.sh` reports drift (all
  current as of 2026-10-04).

**Packaging cautions**
- `~/Documents/Max 9/Packages/f_` is a symlink to this repo's `package/`; never unzip a
  release there. The `getattr` console error is parked (packaging/T019). `8af4c71` ("cleanup") bundled a
  whole session and swept in `ideas/f_vf_emulsion.md`; history was not rewritten.
