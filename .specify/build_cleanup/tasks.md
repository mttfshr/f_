# Tasks: Build, Tools and Test Cleanup

**Spec**: `.specify/build_cleanup/spec.md`
**Build order**: Phases are roughly sequential, but Phase 3 modules can be taken one at a time in any order once Phase 2 exists.
**Commits**: Matt commits manually, after each verified phase (per `build_layout/tasks.md`). Phase 0 was committed during the 2026-10-04 session as five commits, each after Matt approved that step.

Task IDs are per directory: write `build_cleanup/T012`.

**Status 2026-10-04:** Phase 0 done. The live bench ran later the same day (T024, T028). Phase 1 is next.

---

## Where things stand (measured 2026-10-04, `build/py.sh build/drift.py`)

**11 of 40** shipped patchers reproduce exactly from their definition: `f_caustic`, `f_ngon`, `f_stipple`, `f_vf_chroma`, `f_vf_fluid`, `f_vf_glow`, `f_vf_potential`, `f_vf_prism`, `f_vf_seeds`, `f_vf_split`, `f_vf_streak`. The other 29 are in `tests/drift_baseline.json`: **21 drifted, 7 with no definition, 1 build error.**

Difference counts over the 21 drifted: props 403, boxes only in the patch 270, boxes only in the definition build 137, layout 133, cords only in the patch 11, pix ports 10, cords only in the definition 5, codebox text 5. Layout plus props is 55% of the counts, but **only two modules are cosmetic-only** (`f_chladni`, `f_vf_flow`); the other 19 also have structural drift, which comes in four kinds:

- **Stale definition values**: label text edited in Max ("Rotation" vs "Rot", "Mobius" vs "Möbius"), a pix `@name`, an outlet comment. A plain `definition.py` edit. These show as one box "only in the definition" plus one "only in the patch" (T006 pairs them).
- **Generator ahead of the patch**: e.g. the patch's `route` still lists `bypass`. The patch is the stale side; regenerate.
- **Schema cannot express it yet**: `f_channel_grader` and siblings use a 3x3 grid with shared row labels (9 dials, 3 labels); `f_droste` has an extra `time_s` inlet and attrui; dial vs numbox choices; Param-bypass (`ideas/build_patcher_schema_gaps.md` gap 6, plan Work Queue item 10); gaps 3-5; `r draw` triggers.
- **Bespoke hand-built UI**: `f_masonry` (62 boxes only in the patch, mod-matrix UI), `f_texrouter` (98).

**Grouping of the 21** (structural diff counts are def-only / patch-only boxes):

| Group | Modules |
|---|---|
| Cosmetic only | `f_chladni`, `f_vf_flow` |
| Small (<= 6 boxes) | `f_vf_vortex` (2/1), `f_vf_vortex_multi` (2/3), `f_vf_vorticity` (3/3), `f_vf_warp` (2/2, code), `f_vf_fieldmap` (1/1, code), `f_vf_repulse` (1/1, code), `f_sirds` (1 cord), `f_weave` (0/6, code) |
| Medium | `f_mobius`, `f_droste`, `f_channel_grader`, `f_hue_processor`, `f_luma_processor`, `f_tone_curve`, `f_vf_advect`, `f_lens`, `f_grain` |
| Heavy | `f_masonry`, `f_texrouter` |

**No definition (7):** `f_stereo` (shipped, none at all), `f_vf_optical_flow` (its codebox files live in `.specify/f_vf_optical_flow/`, not `src/`), `f_vf_vortex_multi_version` (archived second copy; a README warning row), `f_a_ripple` and `f_chladni_audio` (`gen~` audio, the schema has no audio archetype), `f_modules` (the menu, Phase 5), `f_util_matrix_2` (draft utility). **Build error (1):** `f_util_profile` (`KeyError: 'object_name'`, a non-pix module the schema cannot express).

---

## Phase 0: Housekeeping (DONE 2026-10-04)

- [x] T001 Remove 16 one-shot scripts (`tools/masonry/*`, `tools/util_profile/*`, five others in `tools/`, `build/migrate_to_attrui.py`, which would have reverted deliberate `prepend param` wiring such as `f_vf_warp`'s `bypass_gate`). `1ab9ee5`.
- [x] T002 `tests/jobs/` held 73 GB and was never pruned. Deleted the contents; `benchclient.new_job()` now keeps the newest 50 job dirs. `f933082`.
- [x] T003 `tests/bench.sh`: default is a regression set (`control selftest fft temporal fluid modules fluid_module`), `--all` adds `perf` and `fluid_probes`, `--list` prints the selection. `8fc3ec6`.
- [x] T004 Merged `build/audit_interface.py` into `tests/module_contract.py`: per-pix undriven and unused Params, codebox-less pix, port gaps, on every stage of every module. 9 documented `KNOWN_ISSUES` (3 `f_vf_seeds` and 1 `f_vf_optical_flow` by design; 5 dead `f_masonry` mod cells). `dc10d50`.
- [x] T005 `build()` made pure (`side_files`); `build/drift.py`; `tests/test_drift.py` and `tests/drift_baseline.json`; the source-of-truth rule written into README, `build/spec.md`, `plan.md` and the skill. `52205e6`.

---

## Phase 1: Make drift diagnosable

- [ ] T006 In `build/drift.py`, pair unmatched boxes that are the same element under a different identity (same `maxclass`, nearest presentation position, or same sequence) and report each pair once as `old -> new`, instead of one def-only plus one patch-only box. Rewrite the baseline afterwards (counts change, intentionally).
- [ ] T007 Decide each of the 7 definition-less patchers: write a definition (`f_stereo`), move files from `.specify/` into `src/` (`f_vf_optical_flow`), delete or archive (`f_vf_vortex_multi_version`: Matt's call, it is a README warning row), or declare out of scope for the schema (audio, menu, draft utility) with a reason recorded in the baseline. Also give `f_util_profile` a definition or an explicit exemption.
- [ ] T008 Settle the Max-normalisation list in `build/drift.py` for the cases left as drift because the evidence was ambiguous: `autopattr` `varname` (built `channel_grader_autopattr`, shipped `u905020188`), dial `param_connect` (`grade_pix::x` vs `jit.gl.pix_AA::x`), outlet and inlet `index`. Each is either real drift or Max normalisation; decide with a Max round-trip, then encode it.

## Phase 2: A place in `definition.py` for hand-tuned state (pilot)

- [ ] T009 Design a generic `overrides` block, keyed by element identity (`"<param>.dial"`, `"<param>.label"`, `"panel"`, `"title"`, ...), holding any property, with layout as its main use (also colours, hints, text formatting). **Approved by Matt 2026-10-04: generic, not layout-only.** Record the decision as an ADR in `build/spec.md`.
- [ ] T010 Implement it in `build_patcher.py`: apply overrides after the generated box is made; unknown keys fail loudly.
- [ ] T011 `build_patcher.py --capture src/<m>/definition.py`: read the shipped patcher, and for boxes matched by identity append the differing properties as `patcher["overrides"] = {...}` to `definition.py`. Idempotent, and it must not rewrite the rest of the file. This is the write-back tool for layout.
- [ ] T012 Pilot on `f_chladni` and `f_vf_flow` (cosmetic only): capture, rebuild, `drift` reports zero, lower the baseline.

## Phase 3: Close drift module by module

Recipe for each module: `build/py.sh build/drift.py -v <m>`, then (stale value: edit the definition) or (schema gap: extend the schema, see Phase 4) or (cosmetic: `--capture`) or (patch is the stale side: regenerate), then drift reports zero, then `tests/run.sh`, then `tests/bench.sh` for modules the bench covers (needs Max), then Matt looks at the result in Max for anything visual, then `python3 tests/test_drift.py --write-baseline`. When regenerating a hand-edited module, check `git diff -w --stat -- package/patchers/<m>.maxpat` first, and `git checkout --` the file if the diff is not small.

- [ ] T013 Small group: `f_vf_vortex`, `f_vf_vortex_multi`, `f_vf_vorticity`, `f_vf_warp`, `f_vf_fieldmap`, `f_vf_repulse`, `f_sirds`, `f_weave`. `f_vf_fieldmap` and `f_vf_repulse` were hand-edited and are an open question for `plan.md`'s never-regenerate list. `f_vf_warp`'s `bypass_gate` needs Param-bypass (T017).
- [ ] T014 Medium group: `f_mobius`, `f_droste` (extra `time_s` inlet, and the missing `autopattr` parked in `plan.md`), `f_channel_grader`, `f_hue_processor`, `f_luma_processor`, `f_tone_curve` (these four need a shared-label grid layout, T018), `f_vf_advect`, `f_lens` (`raw_boxes`/`raw_ui` already exist, the definition still builds the removed tiltshift), `f_grain` (the definition is an after-the-fact transcription; already missing a real control once).
- [ ] T015 Heavy group: `f_masonry` and `f_texrouter`. For `f_masonry` the options are to capture the hand-built mod-matrix UI as `raw_boxes`/`raw_lines` first (definition becomes truth now, structured later) or wait for the mod-texture convention. The five dead `_mod_amt_a` cells are in `KNOWN_ISSUES` and resolve with that decision. `f_texrouter`'s old build script was deleted in T001 (find it in git history).

## Phase 4: Schema features the drift exposes

These come from the Phase 3 work; take them in the order the modules need them. Background: `ideas/build_patcher_schema_gaps.md`.

- [ ] T016 Gaps 3-5 and `r draw` triggers: `inlet_targets` (an inlet fanning out to several stages), per-node `pix_attrs`/`dim`/`adapt`, `pix_target` as a list, bang-triggered stages.
- [ ] T017 Gap 6, Param-based bypass (`bypass_mode: "param"` with a target stage and Param name). Same mechanism as `f_vf_warp`'s `bypass_gate`, `f_vf_fluid`, and plan Work Queue item 10 (11 modules with flipped secondary outlets under native bypass). Probably the most valuable one.
- [ ] T018 A grid layout with shared labels (rows x columns), for the colour modules.
- [ ] T019 Absorb the four script-built modules into `build_patcher.py` once T016/T017 exist (`build_sirds.py`, `build_advect.py`, `build_fluid.py`, `build_seeds_multistage.py`); until then `drift.py` covers them through their `build()`.

## Phase 5: Generate the `f_modules` menu

- [ ] T020 Decide the menu's source: its own definition (categories, order, labels, sizes for `f_addmod.js`, the nabla marks), versus extending the README Patches table that `generate_launch.py` already parses. Ideally the menu and `f_Launch` derive from the same data. Settle `plan.md`'s open `f_vf_vortex_multi` / category questions as part of it.
- [ ] T021 Write the generator (follow `generate_launch.py`: validate loudly, `--check`, offline test), then delete `tools/rebuild_modules_menu.py`, `tools/append_nabla_menu.py`, `build/tools/f_modules/build_modules.py`, and `tools/`. This closes `packaging/T022` (the old 5-category script that would overwrite the shipped 8-category menu).

## Phase 6: Remaining loose ends

- [ ] T022 `packaging/T018`: the README says helpfile generation is "via Claude API", but `plan.md` says `build/generate_helpfiles.py` no longer calls it. Open the script and fix whichever is wrong.
- [ ] T023 `build/helpfile_queue.json` is a tracked generated file that `extract_params.py --all` rewrites every run. Untrack and gitignore it, or stop `--all` from writing it by default.
- [x] T024 Run the live bench once. Done 2026-10-04 on Max 9.2.0; it found three problems, all fixed (T028). Full default run: 7/7 files green. The job-dir prune held the directory at exactly 50 during the run.
- [ ] T025 Delete `scratch/regen_drift_semantic.py`, `regen_drift_props.py`, `regen_drift_depth.py`, `regen_dryrun.py` (superseded by `build/drift.py`), and decide the rest of `scratch/` (39 committed files).
- [ ] T026 Optional, low priority, needs Max: `tests/bench/bench.js` and `bench_module.js` share 11 same-named functions, and `make_bench.py` / `make_module_bench.py` share `obj` and `wire`. Deduplicate with a shared include.
- [ ] T027 Matt: re-upload `skills/vsynth-bpatcher/SKILL.md` to claude.ai and run `./skills/check.sh stamp` (changed three times on 2026-10-04; Matt was uploading it at the end of that session, confirm `check.sh` is clean).
- [x] T028 First live bench run since the cleanup, on Max 9.2.0 (`18eb7cd`, `ee43b7d`). Three findings. (a) `f_stereo`'s codebox assigned `PI = 3.14159265359;`; Max 9.2.0 refuses to compile an assignment to a predefined constant, so the pix produced nothing and all five params reported "invalid message": 20 contract issues, all in `f_stereo`. Renamed the variable to `pi_val` (three sites). `f_stereo` has no definition, so this hand edit must be carried into its definition (T007). (b) `bench_modules.py` and `bench_fluid_module.py` started with `require_bench`, demanding the module bench be open although every module reopens it fresh, so the default `bench.sh` died after ~4 minutes; they now reopen it, and `bench.sh` only requires the codebox bench when a selected file needs it. (My earlier README and `bench.sh` text saying they open it themselves was wrong when I wrote it and is true now.) (c) `bench_fluid_module` T038a: with viscosity 0 the force is integrated every frame (max|u| 0.47 at 16 warmup frames, 0.90 at 32, saturated at 48), so the old `warmup=48` clamped; now 24 (noise rejection 1.77 against the 1.5 limit, smooth-force difference 0.4% against 10%). `bench.sh` now writes the Max version and date as the first line of `bench_last.log`.
- [ ] T029 Add a gotcha to `skills/jit-gen-codebox/SKILL.md` and check `gen-tilde-codebox`: a codebox that assigns to a predefined constant (`PI`) fails to compile on Max 9.2.0, the whole pix produces nothing, and every param message reports "invalid message". Use the lowercase constants (`pi`, `twopi`) or another variable name. Bundle it with the next skill upload.
- [ ] T030 Max 9.2.0 versus 9.1.4. The patches were saved in 9.1.4 (`appversion`), the bench now runs on 9.2.0. Open: (i) why the fluid field's frame count differs. Warmup 2 and 4 frames give identical output, so frames are quantised somehow, and 48 now saturates where it passed on 09-29 (the Max version of that run was not recorded). (ii) Whether other modules rely on behaviour 9.2.0 changed; today's full bench is green, so none that the bench covers. (iii) `package-info.json`'s `max_version_min` 9.0.0 is unverified (see packaging), and the `PI` failure is evidence that compile strictness differs across builds.
- [x] T031 Bench speed (asked 2026-10-04). Done: `@slow` tier (`d7fe787`), the default run goes from ~440 s to 188 s. Three further ideas were measured and rejected, with numbers in `tests/README.md`: free-running frames (4% faster, broke `bench_selftest` and `bench_temporal` because secondary-output readback needs wall-clock time), content-hashed gen names (no gain in the real alternating pattern), and running the two benches concurrently (the codebox group failed 15 assertions because Max error capture is global).
- [x] T032b `bench.sh --changed` built (`tests/benchdeps.py`): skips a bench file whose inputs and Max/Vsynth versions match its last green run; `bench_modules` runs only changed patchers. Tested offline, 19 tests, 23 mutants caught (shell glue tested with a fake `uv`). **Not yet run against live Max**: seed with one plain `tests/bench.sh`, then try `--changed`.
- [ ] T032 Optional, only if 188 s is still too slow: (a) run a chain of passes inside one job in `bench.js`, so T020's 100 solver frames take a few seconds instead of ~60 (a new bench mode); (b) `bench.sh --changed`, running `bench_modules` only for modules whose patcher or codebox changed (75 s of forced reopens otherwise); (c) per-bench error capture, which would also make parallel runs possible. (c) touches the parked `jpatcher: doesn't understand getattr` console error: it reaches the bench while `bench_module.maxpat` loads Vsynth, which is a lead for that thread.
- [ ] T033 Parked, not needed unless the bench starts being run often (`bench.sh --changed` should make most sessions run nothing, or one module for ~10 s). Running the bench in the background while working: (a) DONE 2026-10-04: `tests/bg.sh start|status|log|stop|list`, with a lock (one bench run at a time), a status file and a macOS notification (`tests/test_bg.py`); (b) `benchclient.reopen()` uses `open -a Max`, which brings Max to the front on every reopen (33 times in `bench_modules`): try `open -g`, with a test that the bench still renders while Max is not frontmost; (c) a dedicated Max instance for the bench (`open -n -g`) on its own ports (hard-coded in the generated patches, so parameterise `make_bench.py` / `make_module_bench.py`), which isolates it from the user's session (the global error trap, window churn) and would let the two benches run in parallel; whether a second Max instance runs alongside the first here is unverified, and finding out launches one; (d) only after (c), an auto-trigger (watch plus `--changed`).

---

## Notes

- **The ratchet's blind spot**: `tests/drift_baseline.json` stores counts, so one difference fixed and another introduced in the same module is invisible. Acceptable for a stopgap; a hash of the difference set would close it if it ever bites.
- **`tests/` layout** (flat, 27 Python files) was looked at and left alone on purpose: moving files means editing paths in the README, skills and `.specify` docs, for little gain. The Phase 0 survey found `tests/` sound; the problems were in `tools/` and the unpruned job dir.
- **Pitfalls hit this session**: `harness.check` passes at `value <= tol`, so a `tol=1` detection test also passes at 0 (use exact counts); a `re.S` non-greedy regex edit silently re-targeted the wrong calls (use a real edit tool); Desktop Commander's `write_file` needs an explicit `mode` to overwrite and an existing parent directory.
