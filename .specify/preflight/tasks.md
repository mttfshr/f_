# Preflight — Tasks

_Drafted 2026-11-21 (Claude, offline). Nothing is built or run. Ticks mean done and verified; "observed" lines say by whom._

## Preliminary gates (Claude's recommendation, not Matt's decision)

- [x] PG1 — Name and place: `build/preflight.py`, with `build/helpfile_fit.py` beside it. Confirmed by Matt, 2026-11-21 (chat).
- [x] PG2 — Exemptions file `tests/build/preflight_exemptions.json` with a shrink-only test, citing gate IDs. Confirmed by Matt, 2026-11-21 (chat).
- [x] PG3 — The reviewer is advisory only; its verdict never ticks a task by itself. Confirmed by Matt, 2026-11-21 (chat).
- [x] PG4 — `--tests` is opt-in; the default run is static and fits the "no test runs without asking" rule. Confirmed by Matt, 2026-11-21 (chat).
- [x] PG5 — If generalised helpfile fit fails for many modules (T001), enforce for new and promoted modules and baseline the rest. Policy confirmed by Matt, 2026-11-21 (chat, "confirm all"); the actual count (T001) is still to be reviewed with him before enforcing.

## Phase 0: measure (read-only, no code committed)

- [x] T001 — Run the `content_extent` plus embed comparison over every shipped module that has a helpfile, from a scratch script. Record the failing modules and how far each is cropped. Decides PG5.
  - Observed offline by Claude, 2026-11-21 (scratch script, not in the repo; Linux VM, Python 3.10). 63 shipped patchers: **33 pass**, **12 have no helpfile**, **18 fail** (f_vf_optical_flow fails both ways).
  - **Embed smaller than the frame (10)**, all at the 154x91 size from the 2026-10-13 incident: f_channel_grader (frame 150x165), f_chladni (227x164), f_hue_processor (150x120), f_luma_processor (150x120), f_masonry (342x241), f_mobius (185x90), f_stereo (160x90), f_util_profile (200x120), f_vf_optical_flow (190x130), f_vf_streak (190x100). Not looked at in Max.
  - **Content past the frame by more than 1.5 px (9)**: f_grain (content 234x158, frame 232x176), f_halftone (286x286 vs 290x164), f_separate (296x162 vs 300x118), f_vf_fieldmap (154x81 vs 150x88), f_vf_optical_flow (190x143 vs 190x130), f_vf_seeds (190x205 vs 190x160), f_vf_split (102x69 vs 80x80), f_vf_vortex_multi (279x267 vs 190x283), f_vf_warp (102x61 vs 78x90). The frame heuristic picked the largest presentation panel and that was one unambiguous panel in the six checked, so these are not shown to be false positives. They are also not shown to be real crops: which box lies past the frame, and whether that is intended, is not established (`f_halftone` passed Matt's live look 2026-11-14). Inferred only.
  - **No helpfile (12)**: f_a_decorrelate, f_a_decorrelate_inner, f_a_purr, f_a_ripple, f_chladni_audio, f_cmap, f_ks, f_modules, f_texrouter, f_util_matrix_2, f_util_vary_row, f_vf_lbm. A "helpfile exists" check needs an exemption class for inners, non-modules and paused modules.
  - **PG5 consequence (policy as confirmed):** the embed-smaller half (10) is the high-signal part and should be enforced for new and promoted modules. The content-past-frame half (9) needs the question above answered before it is enforced. The 18 failing modules would go on a shrink-only baseline.
- [x] T002 — Read how `build_patcher.py` treats `bypass_mode`. List every shipped module as native or `bypass_gate`, and reconcile with `G-bypass-native` (15 native, some migrated 2026-11-06).
  - Observed offline by Claude, 2026-11-21. `build_patcher.py:2053`: `bypass_mode` defaults to `"native"`; only `"native"` and `"param"` are accepted; `param` writes the gate param (`bypass_gate` by default). The audio shell (`build_patcher.py:2685`) requires `Param bypass_gate`.
  - 56 definitions: **param 37**, **native 15**, **audio shell 3** (f_a_decorrelate, f_a_purr, f_a_ripple), **no bypass control 1** (f_texrouter). Seven definitions could not be loaded in the VM (they `open()` their codebox at an absolute `/Users/matt/Github/f_/...` path); those seven were read from the text instead and all say `bypass_mode: "param"`: f_halftone, f_separate, f_vf_chroma, f_vf_flow, f_vf_glow, f_vf_prism, f_vf_streak.
  - **The 15 native modules match the `G-bypass-native` row exactly** (same 15 names, compared by eye): f_channel_grader, f_droste, f_hue_processor, f_lens, f_luma_processor, f_mobius, f_ngon, f_sirds, f_stereo, f_tone_curve, f_vf_repulse, f_vf_vortex, f_vf_vortex_multi, f_vf_vorticity, f_weave. So the bypass check starts with 15 exemptions, all citing `G-bypass-native`, and no surprises.
  - Side finding, not in scope: 7 definitions hardcode an absolute path under `/Users/matt/` for their codebox, so drift and build cannot run for them anywhere but Matt's machine. Also `f_sirds` has both a definition (native) and `build_sirds.py`; `drift.py` uses the script first, so which one governs its bypass was not established.
- [x] T003 — Check whether `generate_launch.validate` and the menu validator can be applied to one module. If not, note the wrapper needed.
  - Observed offline by Claude, 2026-11-21 (read, not run). `generate_launch.validate(groups)` and `generate_menu.validate(menu, groups)` are library-wide: they collect every problem and raise one error listing them. Neither takes a module name. `parse_readme(text)` returns `(heading, [(name, description)])` groups, so a per-module wrapper is small: find the module's row, check `len(desc) <= MAX_DESC`, check its group heading against the menu category, check `HELP_DIR/<name>.maxhelp`, and also call the two validators and keep only the problem strings that name the module. The last step is inferred (the problem strings do contain the module name); it has not been tried.

## Phase 1: the script

- [ ] T010 — Move `content_extent` and the embed-size comparison into `build/helpfile_fit.py`. `test_generate_menu.py` imports it. The `tf_` test passes unchanged.
- [ ] T011 — `build/preflight.py` skeleton: single module only, report format (`ok | RED | exempt | owed` plus source), `--json`, exit codes.
- [ ] T012 — Wire the checks: drift (via `test_drift.problems` and the baseline), contracts, registration, README row, doc exists, helpfile fit, bypass.
- [ ] T013 — `tests/build/preflight_exemptions.json` and `tests/build/test_preflight.py`: reason required, gate ID must exist in `gates.md`, exemption no longer needed is a failure, check names validated. Unit tests with synthetic modules, in the style of `test_drift.py`.
- [ ] T014 — `--tests`: the module's `tests/modules/<name>/` files plus the launch and menu tests. Bench steps print as `owed`.

## Phase 2: Part 2

- [ ] T020 — `skills/module-preflight/review-rubric.md` with R1 to R5 (see `spec.md` C).
- [ ] T021 — Review procedure in the skill: what the subagent is given, report-only, how the result is recorded in `tasks.md`. State the run count before the first run.
- [ ] T022 — Preflight prints the live-look items (open in Max, no new lines beyond `P-console`) as `owed` lines for `plan.md`. It does not edit `plan.md`.

## Phase 3: wire in

- [ ] T030 — Edit the `module-preflight` SKILL.md body: Part 1 becomes the command and a what-each-line-means table, Part 2 split, the two stale claims fixed ("no script does this yet", "spec.md names most of Part 1"). Description unchanged.
- [ ] T031 — Add the preflight step to the "Full lifecycle" block in `build/spec.md`.
- [ ] T032 — Add one line to `CLAUDE.md` Claims: closing a module cites its preflight report.
- [ ] T033 — Matt: re-upload the skill to claude.ai, then `skills/check.sh stamp`.

## Phase 4: trial

- [ ] T040 — Run preflight on one clean stable module and one with a known exemption (Matt picks; `f_tone_curve` has a native bypass kept by his call 2026-11-06).
- [ ] T041 — Compare the report with what is known to be true about those two modules. Amend the checks or the exemptions, then tick.
