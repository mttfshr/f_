# HANDOFF

## START HERE (2026-11-06)

**Read order for a new session:** CLAUDE.md, this block, `.specify/plan.md` (one-page focus), `.specify/gates.md`. README.md is NOT required. Older entries are in `HANDOFF_ARCHIVE.md`: grep it, do not read it whole.

**State:** `f_wave_field` is finished except T041 (the `f_cymascope` audio front end, not started): redesign built, docs and helpfile written, in the menu under ∇ Fields, README ⚠ removed, live looks passed, benches green on the four-input harness (record: `.specify/f_wave_field/tasks.md`). `f_vf_stamp` (was `f_splat`) is BUILT OFFLINE, nothing run: `.specify/f_vf_stamp/{spec,plan,tasks}.md`; Phase 0 and T020-T024 are done, benches green (10/10, 7/7, 2/2), live looks passed, documented and registered (Phase 3 done 2026-11-06; the helpfile is not yet opened in Max); menu category provisional under Adapters (`G-menu`). Earlier closed work (`f_vf_ch` rename, `f_weave` promotion, `f_stipple` / `f_vf_flow` render triggers, the `render_dim` migration, Hatch, `f_ks` tuning, the Claims rule) is in `HANDOFF_ARCHIVE.md` and the module `tasks.md` files. `f_vf_fluid` and `f_vf_split` moved to `.specify/stable/` 2026-11-06. `f_tf_tensormap` moved to `.specify/stable/` 2026-11-06. `f_tf_hatch` moved to `.specify/stable/` 2026-11-06. `f_tf_axisflow` moved to `.specify/stable/` 2026-11-06. `f_vf_fieldmap` and `f_vf_potential` moved to `.specify/stable/` 2026-11-06. `f_vf_flow` and `f_tone_curve` moved to `.specify/stable/` 2026-11-06, so all seven batch 3 modules are moved. Stable push: batch 4 triage is done, record in `.specify/maintenance/batch4_triage_2026-11-06.md`; Group A (`f_vf_warp`, `f_stipple`, `f_vf_glow`, `f_vf_prism`) is next. Plan and bar: the 2026-11-06 entries in `HANDOFF_ARCHIVE.md`, and `.specify/plan.md` Next 0.

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

## 2026-11-06: batch 4 triage and the omp doc harness

- **Done (offline, Claude and omp; nothing run in Max):** triage of 11 modules. Record: `.specify/maintenance/batch4_triage_2026-11-06.md`. Candidates: warp, stipple, glow, prism. Needs work: advect, streak. Held: vortex, optical_flow, seeds. Out: repulse, sirds.
- **omp harness:** first triage found 0 of 2 planted doc errors; claim ledger 6 of 9, gate failed; three-stage blind audit 11 of 12, 12 of 15 flags correct, gate passed narrowly. An omp `agree` is not a clean bill. Lessons: skill `omp-fanout`, `references/lessons.md`. Runs: `f_omp_runs/`, whose reports contain planted errors.
- **Real doc errors found:** prism "Two outlets" and `strength`; glow line 25 `strength`; vortex `vs_black` (inferred, not run).
- **Gates:** `G-edge-wrap` note added (`HANDOFF_ARCHIVE.md:941` says the clamp triage was done; Matt closes it). `G-bypass-native` note on optical_flow.
- **Stray file:** an omp worker wrote `write` at the repo root; untracked, not staged, deletion waiting on Matt.
- **Next:** Group A preflight. Matt's open calls are in the triage record.
