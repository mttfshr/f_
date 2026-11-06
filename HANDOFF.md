# HANDOFF

## START HERE (2026-11-05)

**Read order for a new session:** CLAUDE.md, this block, `.specify/plan.md` (one-page focus), `.specify/gates.md`. README.md is NOT required. Older entries are in `HANDOFF_ARCHIVE.md`: grep it, do not read it whole.

**State:** `f_wave_field` is finished except T041 (the `f_cymascope` audio front end, not started): redesign built, docs and helpfile written, in the menu under ∇ Fields, README ⚠ removed, live looks passed, benches green on the four-input harness (record: `.specify/f_wave_field/tasks.md`). `f_vf_stamp` (was `f_splat`) is BUILT OFFLINE, nothing run: `.specify/f_vf_stamp/{spec,plan,tasks}.md`; Phase 0 and T020-T024 are done, the codebox, module and contract benches are green (10/10, 7/7, 2/2), Matt's live looks (T030-T032) are next; G8 waits for Phase 3. Earlier closed work (`f_vf_ch` rename, `f_weave` promotion, `f_stipple` / `f_vf_flow` render triggers, the `render_dim` migration, Hatch, `f_ks` tuning, the Claims rule) is in `HANDOFF_ARCHIVE.md` and the module `tasks.md` files. Nothing else is scheduled; Matt picks the next item.

**Candidates (Matt decides):**
- **`f_vf_stamp` benches** (start here if Matt says go): all benches are green; next Phase 2's live looks, Matt's.
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

## 2026-11-05 (late night): `f_vf_stamp` Phase 1 built, nothing run live

- **Done (offline, Claude; record in `.specify/f_vf_stamp/tasks.md`):** T020 the `gate_button` schema type, `f_wave_field` Strike built from it; T021 the codebox; T022 the definition and envelope; T023 the patcher; T024 two bench files, written, not run.
- **Decided (Matt, chat):** plan ADR-9 (render on `r draw`, textures on cold inputs); `src_stamp`, so an empty in0 stamps nothing under `invert`; `stamp_gate` feeds the envelope only (FR-007). `obj-gate-*` ids taken by default.
- **For Matt's veto:** `env` snaps to 0 below 0.001; loadbang bangs the `attack` and `release` dials; `invert` reads Norm / Inv; panel copies `f_wave_field`.
- **Commits:** 4866d14, 034662c, 7429edb, 14a4ff4, then this one.
- **Verified offline:** `f_wave_field` rebuild equal to the committed patcher in every box property and cord once 13 ids are mapped; `drift -v` ok for both modules; `test_build_gate_button.py` 10/10; `test_vf_stamp.py` 21/21; `test_module_contracts.py` 9/9 (log `tests/logs/20261105-215041-offline.log`; `stamp` is a new known issue, the path is one hop past `max_depth` 6); `test_bench_expect.py` 10/10.
- **Bench (Matt's go):** `bench_vf_stamp.py` 10/10, first compile (log `tests/logs/20261105-215536-bench.log`); `bench_vf_stamp_module.py` 7/7 (log `tests/logs/20261105-215636-bench.log`). `src_stamp` from `vs_inState` is not proven by it: check live at T031 (`tasks.md`). `bench_modules.py` 2/2 (log `tests/logs/20261105-215801-bench.log`).
- **Not run:** the rest of the offline suite, `test_gates.py`. `f_wave_field` not reopened in Max since T020.
- **Owed to Matt:** the live looks (T030-T032). Add the module by name: no menu or README row until T040.
- **Note:** `make_missing_helpfiles.py` skips `gate_button`, so `stamp` needs adding by hand at T040. An empty untracked `f_bench_dry.py` sits in the repo root (not Claude's).
- **Gates touched, no row edited:** `G-menu` (T008 still held), `G-ui-density` (nine controls plus the press).
