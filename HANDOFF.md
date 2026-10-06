# HANDOFF

_Latest session: 2026-10-05 (one long session)_ — `build_cleanup` **Phases 1 and 2 done, and Phase 3's T014 (the medium group) complete.** 28 of 39 shipped patchers now reproduce exactly from their `definition.py`; the drift baseline is 11 (six drifting, five out of scope). Everything is committed (last code commit `becd99f`), nothing is pushed.

_Task IDs are per directory: each `.specify/<dir>/tasks.md` starts at T001. Write the directory with the ID, e.g. `packaging/T021` means `.specify/packaging/tasks.md`._

## Start here (for the next conversation)

**State.** Offline suite green (`tests/run.sh`, 15 files, exit 0). `build/py.sh build/drift.py` says 28 of 39 exact. The last bench run was green (Matt, `./bench.sh --changed`, `bench_modules` 2/2). Since then only definitions, tests, docs and layout/builder code changed; **no shipped patch has changed since that bench run, so nothing needs Max right now.** The per-module evidence is the T014 paragraph in `.specify/build_cleanup/tasks.md`.

**Waiting on Matt**
1. **Look at `f_vf_advect` and `f_vf_optical_flow` in Max** (the bench passed, but nobody has looked). `f_vf_optical_flow`'s 8 support-stage dials had their `param_connect` corrected to bind to their own stage (it was bound to `stage_a`, a pix without those Params); `f_vf_advect`'s patch gained 7 `lbl_*` label varnames.
2. **Re-upload two skills, then `./skills/check.sh stamp`:** `skills/vsynth-bpatcher` (new section "Reproducing a Shipped Module from Its Definition", the builder keys, the `legacy` rationale) and `skills/maxpat-json-authoring` (surgical-edit recipe). `./skills/check.sh` reports both STALE. Do not stamp before uploading.

**Open questions for Matt** (none blocks work)
- `f_vf_advect`'s `mix_pct` numbox answers to `mix` on the control inlet, but most modules' `mix_pct` answers to `mix_pct`. The `route_name` key records the difference; check how the dry/wet modules differ before unifying.
- `f_grain` ships three wrong or odd tooltips (`fade` and `ch_diverge` both say "Temporal persistence…"; `shape` describes an aspect ratio its 0..1 range does not have). Left as shipped; fixing means editing the patch and the definition together.
- `f_droste`'s bypass jsui lost its inert saved block when it was regenerated (assumed inert because it has no `parameter_enable`; never tested in Max). Easy to revert if wrong.
- `f_grain` and `f_lens` could now come off plan.md's never-regenerate list (their definitions reproduce the patches), as `f_vf_advect` did; regenerating gains nothing.

**Next, in suggested order**
1. **Quick wins in the baseline** (each a few differences): `f_stereo` (the circ toggle's `param_connect` and saved block and the bypass jsui's inert block are now expressible with `legacy.control_box` / `control_valueof` / `bypass_jsui_saved`), `f_vf_flow` (1 property), `f_vf_vorticity` (3 properties; the module was never completed, README marks it ⚠), `f_vf_warp` (1 box each way; its Param-based bypass needs T017). `f_masonry` (T015, will be refactored) and `f_texrouter` (shipped, not in use) stay as recorded exceptions.
2. **Phase 4:** T016 (inlet fan-out, per-node pix attributes, `r draw` triggers) and T017 (Param-based bypass; `f_vf_warp` is the user), then T019 (absorb the remaining script-built modules; `build_advect.py` is done and deleted).
3. **Phase 5:** T020 and T021 (the generated `f_modules` menu), then the packaging questions (T022, T023), T025 (delete the `scratch/` regen scripts), T026 (optional, needs Max).

**What changed this session, in one list** (each is documented in `build/spec.md`, `.specify/build_layout/spec.md`, and the skill):
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
- **Bench name collision:** close every patch holding an instance of the module (its help, demos) and reopen `tests/bench/bench.maxpat` before `./bench.sh --changed`, or it fails with `name X already in use`.
- **Desktop Commander refuses any shell command that contains the bare token `dd`** (the disk-dump command), even as a Python variable name or inside quoted text: "Command not allowed", and nothing runs. Pick another variable name, and write text that mentions it with the file-writing tool, not a heredoc. (Writing this very note through a heredoc triggered it.)
- **That tool only writes inside allowed directories** (`/Users/matt/Github`, not `/tmp`): stage files under the repo's `scratch/`.
- **Heredoc edit scripts:** anchors must match exactly. An `AssertionError` leaves files unwritten, but a *following* `git commit` line still runs unless you chain it with `&&`. Once a commit claimed records that had not been written (amended). Verify a written test file parses (`python3 -c "import ast; ast.parse(...)"`): escaped quotes in a heredoc caused a `SyntaxError`.
- **Codeboxes can have CRLF endings** (`f_grain`, `f_tone_curve`): read a `.gen` file with `newline=""`.
- **Check for a half-finished earlier session before editing:** when a connection drops, work can be left uncommitted in the tree. Look at `git status` and file timestamps first and do not overwrite it (this session found and finished one: `d8e32ac`).
- A route box is never narrower than its text (6.5 px per character): with long token names it is wider than its lane.

**How he wants to work:** discuss architecture before code; slow things in the background; he is fine with Claude committing on f_ projects; start each conversation by reading `README.md`, `HANDOFF.md` and `.specify/plan.md`.

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
