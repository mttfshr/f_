# HANDOFF

## START HERE (2026-11-06)

**Read order for a new session:** CLAUDE.md, this block, `.specify/plan.md` (one-page focus), `.specify/gates.md`. README.md is NOT required. Older entries are in `HANDOFF_ARCHIVE.md`: grep it, do not read it whole.

**State:** `f_wave_field` is finished except T041 (the `f_cymascope` audio front end, not started): redesign built, docs and helpfile written, in the menu under ∇ Fields, README ⚠ removed, live looks passed, benches green on the four-input harness (record: `.specify/f_wave_field/tasks.md`). `f_vf_stamp` (was `f_splat`) is BUILT OFFLINE, nothing run: `.specify/f_vf_stamp/{spec,plan,tasks}.md`; Phase 0 and T020-T024 are done, benches green (10/10, 7/7, 2/2), live looks passed, documented and registered (Phase 3 done 2026-11-06; the helpfile is not yet opened in Max); menu category provisional under Adapters (`G-menu`). Earlier closed work (`f_vf_ch` rename, `f_weave` promotion, `f_stipple` / `f_vf_flow` render triggers, the `render_dim` migration, Hatch, `f_ks` tuning, the Claims rule) is in `HANDOFF_ARCHIVE.md` and the module `tasks.md` files. `f_vf_fluid` and `f_vf_split` moved to `.specify/stable/` 2026-11-06. `f_tf_tensormap` moved to `.specify/stable/` 2026-11-06. `f_tf_hatch` moved to `.specify/stable/` 2026-11-06. `f_tf_axisflow` moved to `.specify/stable/` 2026-11-06. Stable push in progress: batch 3 continues at `f_vf_fieldmap`. Plan and bar: the 2026-11-06 entries in `HANDOFF_ARCHIVE.md`, and `.specify/plan.md` Next 0.

**Candidates (Matt decides):**
- `f_wave_field` T041: the `f_cymascope` front end now produces an LFO texture for inlet 1 (and strike triggers); not started.
- `f_masonry` adopts tagged textures (Matt, 2026-11-01 21:17: "we will do masonry, but not this second"): design discussion first. Its modulation is by space (slot, brick, pixel) with a depth per appearance param in each (6 x 3 = 18 depths, read from `src/f_masonry/definition.py`), so one tag per named `<param>_tex` needs a decision about the spaces. It is the module on the never-regenerate list (`G-masonry`).
- The UI design conversation toward a design skill: `ideas/ui_design_concepts.md` (gate `G-ui-density`); the compact `f_weave` panel is the first test case.
- `f_weave` name and identity: keeping `weave` for now (Matt, 2026-11-01 21:26), to revisit once he knows the module better (question 6; the names discussed are listed in `ideas/f_weave_scope_questions.md`); the other scope questions are tabled.
- `f_ks` still needs its name (T010) and docs (T040) (its tuning is done).
- `vs_black` wording in `skills/vsynth-bpatcher/SKILL.md` and `docs/vsynth-reference/patterns.md` (the skill needs Matt's re-upload and `skills/check.sh stamp`). New fact for that wording: `vs_black` is a 1x1 texture (`vs_render.maxpat`).
- `f_vf_seeds` cost at 1080p is unmeasured; optional cap on the `f_vf_advect` Trail dial.

**Process:** discuss design before code; one phase per turn; ask before any bench run (the codebox bench now passes up to FOUR inputs); Desktop Commander for files (load schemas with ToolSearch; tool names vary by client; in the desktop app, 2026-11-05, the plain Bash tool ran on the Mac); `edit_block` for targeted edits, and never rewrite a CRLF file in text mode; commit per module. Do not mention or follow up on demo `.maxpat` files Matt edits (Matt, 2026-11-01). Long bench runs outlast the relay's 60 s wait: start with a short timeout, then ask Matt to say when it is done. Ad-hoc numpy scripts: `uv run --no-project --with numpy python3 script.py` (system `python3` and `build/py.sh` have no numpy); `sed -i` needs an extension on this Mac, so edit with Python or `edit_block`.

**End of session:** update this block and the `.specify/gates.md` rows you touched. Keep the new entry under about 15 lines; narrative goes in the commit message.

## 2026-11-06: batch 3, `f_tf_axisflow` moved to `.specify/stable/`

- **Done (offline, Claude):** preflight, helpfile given `vs_sources_main` -> `f_tf_tensormap` outlet 1 -> Axis Flow, overlapping note moved, digest rewritten, stale spec and docs fixed. Moved after Matt's helpfile look passed (T029). Record: `.specify/stable/f_tf_axisflow/tasks.md`, "Stable preflight" and "Moved to stable/".
- **Found:** `library-characteristics.md` chained `f_tf_smooth` and `f_tf_sharpen` into Axis Flow; both output the raw tensor, so those chains cannot work (from the docs; not run). Fixed.
- **Verified:** drift ok, menu and launcher `--check`, `test_generate_menu.py` 17/17 (log `tests/logs/20261106-084608-offline.log`). `bench_tf_axisflow.py` not re-run; no code changed; no log of the 9/9 exists, and it predates `render_dim`.
- **Gates:** no row touched. `tests/build/test_gates.py` not run yet (needs Matt's go).
- **Owed to Matt:** decide what to do about `bypass [0 / 1]` in helpfiles: the message does not work in 43 modules (log `tests/logs/20261106-081412-bench.log`).
- **Pattern:** the "Stable preflight" and "Moved to stable/" sections of `.specify/stable/f_tf_hatch/tasks.md`. A `git mv` into `stable/` adds a folder level, so check `parents[N]` and `../` paths in spike scripts and update the `Spec:` path in `definition.py`.
- **Next:** `f_vf_fieldmap`, then `f_vf_potential`, `f_vf_flow`, `f_tone_curve`. The `f_vf_potential` and `f_vf_flow` helpfiles also have no upstream module wired (confirmed for `f_vf_flow` this session; `f_vf_potential` not opened).
