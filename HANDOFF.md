# HANDOFF

_Latest session: 2026-10-05_ — `build_cleanup` **Phases 1 and 2 done, Phase 3 in progress** (T013 small group partly closed; **T014 started: `f_mobius` and `f_stereo`, see the next section**), nothing pushed. The session before it (2026-10-04, second: the cleanup project itself, 13 commits) is condensed below, and the one before that (2026-10-02 to 2026-10-04: Package Manager research, `f_Launch`, licensing; `de89863`) follows it. The open packaging items (packaging/T008 to packaging/T011 and the rest) are in `.specify/packaging/tasks.md`.

_Task IDs are per directory: each `.specify/<dir>/tasks.md` starts at T001. Write the directory with the ID, e.g. `packaging/T021` means `.specify/packaging/tasks.md`._

## Later the same day (2026-10-05): T014 started, `f_mobius` and `f_stereo`

Detail and evidence: `.specify/build_cleanup/tasks.md`, T014. Offline suite green (14 files), `./bench.sh --changed` green (33 modules,
0 unexpected issues, 2/2; it also seeded a fresh green record). **Matt's look at `f_mobius` and `f_stereo` in Max: passed (2026-10-05).**

- **New schema key `route_bypass`** (`build/spec.md`; default off, generated modules unchanged): `bypass` becomes the first `route`
  token, wired to the bypass jsui, every param outlet one higher. It exists because the nine oldest modules route a `bypass 0/1`
  message (skills/vsynth-bpatcher decision 2026-09-23, "do not retrofit"); the bench's `bypass 1` line confirms it works in exactly those 9.
  The layout pass learned it (`build/layout.py`: lane column 0 is the bypass outlet's, params start at column 1; addendum in
  `.specify/build_layout/spec.md`). `pix_type` already existed (my first read of `@type char` as a schema gap was wrong).
- **`f_mobius` closed and regenerated** (20 of 39 reproduce exactly). **Matt chose to drop its second `control` inlet** (there since the
  first commit; it fed the same `route` the first inlet's `routepass` already feeds, so it added no capability) and with it the
  `routepass` out 1 (`jit_matrix`) -> pix cord, which only `f_mobius` and `f_stereo` had. Verified by `drift.compare` against the
  committed file: only the inlet, that cord and five `lbl_*` varnames differ.
- **`f_stereo`: same removal, but a surgical edit, not a regenerate** (parse-dump, 43 deleted lines, nothing else): its hand-built `circ`
  full/mask toggle differs from what the builder writes in ways nobody has checked in Max. Its definition gained `route_bypass`, lost
  `signal_type`, and has an overrides block. **`capture.py` now also takes a live.text's four `active*color` props and `rounded`** (Matt
  asked what they were, then said proceed). Left in the baseline (renamed 1, props 4): `circ`'s `param_connect`, its saved `valueof`
  (shipped parameter_type 2 / enum val1,val2 vs builder type 1 / full,mask: needs Max before anyone regenerates), the bypass jsui's inert saved `valueof`.
- **Bench pitfall hit again:** the first `--changed` run failed on `f_stereo` with `name stereo_pix already in use` because patches holding an
  `f_stereo` instance were open in Max (its help, four demos). Close every other patch and reopen `tests/bench/bench.maxpat` first.
- **Next:** the rest of T014 (`f_droste`, `f_vf_advect`, the colour modules need T018's shared-label grid, `f_lens`, `f_grain`). Most of
  the colour modules and `f_droste`, `f_grain` also route `bypass`, so `route_bypass` is now available to them.

## This session (2026-10-05): build_cleanup Phases 1 and 2, start of Phase 3

Read `.specify/build_cleanup/tasks.md` first (status line, T006 to T013a carry the detail and the evidence).
Full offline suite green (`tests/run.sh`, 13 files). **The bench was not run**, and it should be: see "Start here".

### Start here

- **Everything is committed, nothing is pushed** (`git log` from `cc5d543` to the commit after `9548306`):
  skills (T029), Phase 1, Phase 2, the never-regenerate list, the label varnames (T013a), the T013 definition
  write-backs, `f_vf_vorticity` parked. All eight skills are uploaded and stamped (`./skills/check.sh` clean).
- **The bench is green** (Matt, `./bench.sh --changed`, 2026-10-05, Max 9.2.0): `bench_modules` 2/2 in 73.7 s with 0
  unexpected live contract issues, `bench_fluid_module` 4/4. The first run that day had failed only on
  `f_vf_optical_flow` (`bypass_out1` 8.387): not a code regression, T007 moved its definition into `src/`, so
  `modulebench.archetype()` classified it as a `processor` for the first time and applied the strict "out1 == in1
  under bypass" check. Its bypass is documented to output a neutral field, so it is in `NEUTRAL_BYPASS_BY_DESIGN`
  (`tests/bench_modules.py`), now verified. `benchdeps.py` folds each definition's archetype into its module's
  tracked hash, so a definition change that flips an archetype now reruns that module. This also confirms the 14
  label-varname patchers, `f_stereo` and the builder changes are fine in live Max.
- **Questions waiting for Matt** (none open):
  1. ~~`f_sirds` bypass cord~~ **resolved:** not stray (Matt, 2026-10-05; I had wrongly inferred it from stage 0's
     codebox having no `bypass` Param). `build_sirds.py` now wires bypass into stage 0 too; the module is exact.
  2. ~~`r draw`~~ **done** (T013b): new schema key `render_trigger` (`"inlet"` omits `r draw`); `f_vf_vortex` exact.
  3. ~~`f_vf_vortex_multi`~~ **done** (T013b): finished (Matt); `raw_boxes` for its `nodes` object and
     `vsc_center_ctrl` bpatcher (the file ships with Vsynth), plus an overrides block; exact.
  4. ~~Builder numbox unitstyle / port indexes~~ **decided yes and done** (T008a): the builder writes what Max
     writes, with a `check_port_order()` guard. The shipped patchers still carry the old values until each is
     regenerated or saved in Max; `f_sirds` and `f_vf_advect` (own scripts) still write their own `index`.
- **Next: T014 medium group.** T015 (`f_masonry`, `f_texrouter`) is dropped: masonry will be refactored, texrouter is not in use (Matt, 2026-10-05). Suggested start: `f_mobius` and `f_vf_advect` (least structural
  drift; `f_vf_advect` is script-built and on the never-regenerate list). `f_channel_grader`, `f_hue_processor`,
  `f_luma_processor`, `f_tone_curve` need the shared-label grid layout (T018); `f_droste` has an extra `time_s`
  inlet. The recipe is at the top of Phase 3 in tasks.md.
- **Rule of thumb that came out of this session:** when the patch is the newer side, edit the *definition* to
  match it (hints, ranges, codebox, `signal_type`, extra params); when the builder is the newer side and the
  difference is additive and lossless, edit the *patch* surgically (the label varnames). Never regenerate a
  patch on the never-regenerate list (`.specify/plan.md`: `f_vf_warp`, `f_lens`, `f_vf_fieldmap`,
  `f_vf_repulse`, `f_masonry`, `f_sirds`, `f_vf_advect`, `f_vf_seeds`, `f_grain`). Verify a surgical patch edit
  by parsing the result: it must equal the old content plus exactly the intended change.
- **How he wants to work** (unchanged): discuss architecture before code; slow things in the background; do
  not rerun the bench to re-verify your own changes; he is fine with Claude committing on f_ projects.

### What changed

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

### State of drift

(As of the earlier part of this day; later today it is 20 of 39 after `f_mobius`, see the previous section.) 39 shipped patchers: **19 reproduce exactly**, 15 drift, 5 `out_of_scope`. Remaining counts: props 274, boxes
only in the patch 240, layout 136, boxes only in the definition 113, cords 103, renamed 22, code 9, pix ports 2.

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
