# HANDOFF

## START HERE (2026-11-06)

**Read order for a new session:** CLAUDE.md, this block, `.specify/plan.md` (one-page focus), `.specify/gates.md`. README.md is NOT required. Older entries are in `HANDOFF_ARCHIVE.md`: grep it, do not read it whole.

**State:** `f_wave_field` is finished except T041 (the `f_cymascope` audio front end, not started): redesign built, docs and helpfile written, in the menu under ∇ Fields, README ⚠ removed, live looks passed, benches green on the four-input harness (record: `.specify/f_wave_field/tasks.md`). `f_vf_stamp` (was `f_splat`) is BUILT OFFLINE, nothing run: `.specify/f_vf_stamp/{spec,plan,tasks}.md`; Phase 0 and T020-T024 are done, benches green (10/10, 7/7, 2/2), live looks passed, documented and registered (Phase 3 done 2026-11-06; the helpfile is not yet opened in Max); menu category provisional under Adapters (`G-menu`). Earlier closed work (`f_vf_ch` rename, `f_weave` promotion, `f_stipple` / `f_vf_flow` render triggers, the `render_dim` migration, Hatch, `f_ks` tuning, the Claims rule) is in `HANDOFF_ARCHIVE.md` and the module `tasks.md` files. `f_vf_fluid` and `f_vf_split` moved to `.specify/stable/` 2026-11-06. Nothing else is scheduled; Matt picks the next item.

**Candidates (Matt decides):**
- `f_wave_field` T041: the `f_cymascope` front end now produces an LFO texture for inlet 1 (and strike triggers); not started.
- `f_masonry` adopts tagged textures (Matt, 2026-11-01 21:17: "we will do masonry, but not this second"): design discussion first. Its modulation is by space (slot, brick, pixel) with a depth per appearance param in each (6 x 3 = 18 depths, read from `src/f_masonry/definition.py`), so one tag per named `<param>_tex` needs a decision about the spaces. It is the module on the never-regenerate list (`G-masonry`).
- The UI design conversation toward a design skill: `ideas/ui_design_concepts.md` (gate `G-ui-density`); the compact `f_weave` panel is the first test case.
- `f_weave` name and identity: keeping `weave` for now (Matt, 2026-11-01 21:26), to revisit once he knows the module better (question 6; the names discussed are listed in `ideas/f_weave_scope_questions.md`); the other scope questions are tabled.
- Hatch tail (T064): the spike scripts `camera_like.py` and `lic_stills*.py` still pass `strength=` and fail.
- `f_ks` still needs its name (T010) and docs (T040) (its tuning is done).
- `vs_black` wording in `skills/vsynth-bpatcher/SKILL.md` and `docs/vsynth-reference/patterns.md` (the skill needs Matt's re-upload and `skills/check.sh stamp`). New fact for that wording: `vs_black` is a 1x1 texture (`vs_render.maxpat`).
- `f_vf_seeds` cost at 1080p is unmeasured; optional cap on the `f_vf_advect` Trail dial.

**Process:** discuss design before code; one phase per turn; ask before any bench run (the codebox bench now passes up to FOUR inputs); Desktop Commander for files (load schemas with ToolSearch; tool names vary by client; in the desktop app, 2026-11-05, the plain Bash tool ran on the Mac); `edit_block` for targeted edits, and never rewrite a CRLF file in text mode; commit per module. Do not mention or follow up on demo `.maxpat` files Matt edits (Matt, 2026-11-01). Long bench runs outlast the relay's 60 s wait: start with a short timeout, then ask Matt to say when it is done. Ad-hoc numpy scripts: `uv run --no-project --with numpy python3 script.py` (system `python3` and `build/py.sh` have no numpy); `sed -i` needs an extension on this Mac, so edit with Python or `edit_block`.

**End of session:** update this block and the `.specify/gates.md` rows you touched. Keep the new entry under about 15 lines; narrative goes in the commit message.

## 2026-11-06: `f_vf_fluid` and `f_vf_split` moved to `.specify/stable/`

- **Done (Claude, on Matt's go):** read the `.specify` dirs for stable candidates, ran module-preflight on these two, moved them, updated the live path references. Dated records in `.specify/test_bench/` and `.specify/build_cleanup/` keep the old path.
- **Verified:** record in each module's `tasks.md`, "Moved to stable/". `bench_fluid.py` 11/11, 2 slow skipped (log `tests/logs/20261106-080539-bench.log`); drift ok for both after the move; offline log `tests/logs/20261106-080311-offline.log` is from before the move.
- **Live (Matt):** both helpfile looks pass; Split wording stays; the `bypass` control message that works in 7 of 50 modules is accepted, no gate row.
- **Next:** batch 2 remainder: full offline suite (`f_tf_axisflow` T024). Batch 3: preflight and move `f_tf_tensormap`, `f_tf_hatch`, `f_tf_axisflow`, `f_vf_fieldmap`, `f_vf_potential`, `f_vf_flow`, `f_tone_curve` (helpfile work first), one at a time. Batch 4: triage the older group. Stable bar (Matt, 2026-11-06): wrong docs, unasserted bypass, real bugs and holding gates block; optional cost and parked mirrors carry over.
- **Record mismatches, not fixed:** `f_wave_field` T034 unticked though live looks passed; `status.json` lists `f_vf_warp` under `stable/`, the dir is at the root; `f_vf_repulse` and `f_sirds` tasks have no checkboxes.
- **Batch 1 toward stable (Matt's go, offline):** ticked `f_tf_tensormap` T001 and T045, `f_vf_fieldmap` T023, `f_vf_potential` T002, `f_tone_curve` T001. `f_vf_flow`, `f_vf_fieldmap`, `f_vf_potential` moved from native `@bypass` to `bypass_gate` (Matt's call), entries added, live `bench_modules.py` 2/2 (log `tests/logs/20261106-081412-bench.log`); 17 modules remain under new gate `G-bypass-native`. `f_tf_hatch` T064 closed (scripts in `spike/retired/`); `f_tf_axisflow` T011 closed (Matt: defaults accepted).
- **Gates touched:** `G-bypass-native` added. `tests/build/test_gates.py` 5/5 after the move (Matt's go; log `tests/logs/20261106-080820-offline.log`).
