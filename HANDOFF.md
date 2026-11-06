# HANDOFF

## START HERE (2026-11-05)

**Read order for a new session:** CLAUDE.md, this block, `.specify/plan.md` (one-page focus), `.specify/gates.md`. README.md is NOT required. Older entries are in `HANDOFF_ARCHIVE.md`: grep it, do not read it whole.

**State:** `f_wave_field` is finished except T041 (the `f_cymascope` audio front end, not started): redesign built, docs and helpfile written, in the menu under ∇ Fields, README ⚠ removed, live looks passed, benches green on the four-input harness (record: `.specify/f_wave_field/tasks.md`). `f_vf_stamp` (was `f_splat`) is SPECCED, nothing built: `.specify/f_vf_stamp/{spec,plan,tasks}.md`; Phase 0 gates G1 (envelope in frames), G4 (extract the gate button into a schema type) and G5 (bypass passes the input through) are decided, the rest are open. Earlier closed work (`f_vf_ch` rename, `f_weave` promotion, `f_stipple` / `f_vf_flow` render triggers, the `render_dim` migration, Hatch, `f_ks` tuning, the Claims rule) is in `HANDOFF_ARCHIVE.md` and the module `tasks.md` files. Nothing else is scheduled; Matt picks the next item.

**Candidates (Matt decides):**
- **`f_vf_stamp` Phase 0** (start here if Matt says go): T002 read `f_vf_advect`'s injection source to fix the ink encoding; T003 radial / swirl field definition (the mirror decides); T006 dial set (Matt); T007 luma weights; T009 / T010 the NumPy mirror in `tests/modules/vf_stamp/`; then Phase 1 starts with T020 (extract the gate button; `drift -v f_wave_field` must still reproduce). Confirm Claude's reading of G5 first (T005).
- `f_wave_field` T041: the `f_cymascope` front end now produces an LFO texture for inlet 1 (and strike triggers); not started.
- `f_masonry` adopts tagged textures (Matt, 2026-11-01 21:17: "we will do masonry, but not this second"): design discussion first. Its modulation is by space (slot, brick, pixel) with a depth per appearance param in each (6 x 3 = 18 depths, read from `src/f_masonry/definition.py`), so one tag per named `<param>_tex` needs a decision about the spaces. It is the module on the never-regenerate list (`G-masonry`).
- The UI design conversation toward a design skill: `ideas/ui_design_concepts.md` (gate `G-ui-density`); the compact `f_weave` panel is the first test case.
- `f_weave` name and identity: keeping `weave` for now (Matt, 2026-11-01 21:26), to revisit once he knows the module better (question 6; the names discussed are listed in `ideas/f_weave_scope_questions.md`); the other scope questions are tabled.
- Hatch tail (T064): the spike scripts `camera_like.py` and `lic_stills*.py` still pass `strength=` and fail.
- `f_ks` still needs its name (T010) and docs (T040) (its tuning is done).
- `vs_black` wording in `skills/vsynth-bpatcher/SKILL.md` and `docs/vsynth-reference/patterns.md` (the skill needs Matt's re-upload and `skills/check.sh stamp`). New fact for that wording: `vs_black` is a 1x1 texture (`vs_render.maxpat`).
- `f_vf_seeds` cost at 1080p is unmeasured; optional cap on the `f_vf_advect` Trail dial.

**Process:** discuss design before code; one phase per turn; ask before any bench run (the codebox bench now passes up to FOUR inputs); Desktop Commander for files (`mcp__remote-devices__Desktop_Commander__*`, load schemas with ToolSearch; the plain Bash tool runs in a cloud sandbox, not on the Mac); `edit_block` for targeted edits, and never rewrite a CRLF file in text mode; commit per module. Do not mention or follow up on demo `.maxpat` files Matt edits (Matt, 2026-11-01). Long bench runs outlast the relay's 60 s wait: start with a short timeout, then ask Matt to say when it is done. Ad-hoc numpy scripts: `uv run --no-project --with numpy python3 script.py` (system `python3` and `build/py.sh` have no numpy); `sed -i` needs an extension on this Mac, so edit with Python or `edit_block`.

**End of session:** update this block and the `.specify/gates.md` rows you touched. Keep the new entry under about 15 lines; narrative goes in the commit message.

## 2026-11-05: `f_wave_field` closed out; `f_vf_stamp` specced

- **Decided (Matt, chat):** `f_wave_field` goes under ∇ Fields (not Patterns); README ⚠ removed after he approved the helpfile. `f_splat` becomes `f_vf_stamp`: stamp only, luma coverage, radial impulse from the stamp's gradient when in1 is empty with a Radial / Swirl switch, the held press from `f_wave_field`. Then G1 frames, G4 extract, G5 "pass the input through" (Claude's reading, unconfirmed: out0 = in0, out1 = in1 when connected else neutral; a bypassed stamp hands the whole texture downstream).
- **Commits (see `git log`):** 42b48fa four-input bench harness; b3b04da, c6e52ce menu; 64a5137, a9713bd T040 docs and helpfile; 7c15b8a ⚠ removed; b77160f `f_vf_stamp` spec / plan / tasks; the handoff commit at the end of the log.
- **Verified:** `bench_wave_field.py` 11/11, `bench_wave_field_module.py` 2/2, `bench_selftest` 9/9, `bench_control` 6/6, `bench_temporal` 4/4 (Matt's go; log `tests/logs/20261104-231254-bench.log`); live looks passed (Matt, 2026-11-04 22:59); offline `test_launch.py` 8/8, `test_generate_menu.py` 17/17.
- **Not run:** the `@slow` bench tests (100-frame chain, cost per stage), the rest of the bench regression set, the module contract bench for `f_wave_field`, `tests/build/test_gates.py` (not since the `f_vf_stamp` docs). The `f_wave_field` cost (2.52 ms at 256²) predates the redesign.
- **Owed to Matt:** G6 (dial set), confirm the G5 reading, T008 later (menu category, held by `G-menu`).
- **Gates touched, no row edited:** `G-ui-density` (about ten controls on the stamp), `G-menu`, `G-edge-wrap` (the stamp's gradient needs wrapped texel indices), `P-taxonomy` (a processor with optional inlets). Phase 0 gates live in `.specify/f_vf_stamp/tasks.md`.
- **Untracked, origin unknown:** `f_bench_dry.py` at the repo root (not created this session; possibly a dry-run script from an earlier one). Do not follow up on demo `.maxpat` files.
