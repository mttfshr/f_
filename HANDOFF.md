# HANDOFF

## START HERE (2026-10-31)

**Read order for a new session:** CLAUDE.md, this block, `.specify/plan.md` (one-page focus), `.specify/gates.md`. README.md is NOT required. Older entries are in `HANDOFF_ARCHIVE.md`: grep it, do not read it whole.

**State:** closed: T062/T063 (`render_dim` migration; `f_masonry` and `f_cmap` stay exempt) and the `f_vf_advect` Trail rework (live look passed). Live contract bench: first run 21:52 failed (harness bypass-shape gap for four `render_dim` modules), fixed in `tests/contracts/bench_modules.py`, re-run 22:12 GREEN (2/2). Nothing is scheduled; Matt picks the next item.

**Candidates (Matt decides):**
- Render-trigger check: `f_stipple`, `f_weave`, `f_vf_flow` may draw nothing unconnected (the `f_quasi` bug).
- Close Hatch: v1 helpfile T052, README marker T051, 8 ms gate T061 (`.specify/f_tf_hatch/tasks.md`).
- Tier-3 tuning owed: `f_ks` T030 and `f_wave_field` T030 (both built; docs and registration pending).
- `vs_black` wording in `skills/vsynth-bpatcher/SKILL.md` and `docs/vsynth-reference/patterns.md` (the skill needs Matt's re-upload and `skills/check.sh stamp`).
- `f_vf_seeds` cost at 1080p is unmeasured; optional cap on the `f_vf_advect` Trail dial.

**Process:** discuss design before code; one phase per turn; ask before any bench run; Desktop Commander for files (`mcp__remote-devices__Desktop_Commander__*`, load schemas with ToolSearch); `edit_block` for targeted edits, and never rewrite a CRLF file in text mode; commit per module.

**End of session:** update this block and the `.specify/gates.md` rows you touched. Keep the new entry under about 15 lines; narrative goes in the commit message.

## 2026-10-31 (22:15): live contract bench after the `render_dim` migrations: first run FAIL 1/2 (6 bypass-shape issues in four modules), harness fixed, re-run GREEN 2/2. CLOSED

- **Run:** `tests/bench.sh -q tests/contracts/bench_modules.py`, 109 s, log `tests/logs/20261031-215154-bench.log`. `test_live_module_contracts` fails, the other test passes. 49 modules checked; the `f_a_decorrelate` XFAILs are the known audio case.
- **Failures:** `f_grain` out1-3, `f_tf_aniso_blur` out1, `f_tf_glyph` out1, `f_vf_vorticity` out1: "bypassed frame is (640, 640, 4), expected (64, 64, 4)". Nothing else is unexpected.
- **Cause (read-only, not confirmed live):** these four have passthrough bypass expectations (`("in", k)` / `in_a1` in `BYPASS_EXPECT`) and their output now follows the render size (`@adapt 0`, size from Vsynth's `dim W H` broadcast; "the input is assumed render-sized"). The bench feeds a 64x64 input and sends no `dim`, so they render at the 640 default and `bypass_issues` trips on the shape check. `const` expectations (axisflow, tensormap, quasi) skip that check, so they pass. Reads as a harness expectation gap, not a module bug.
- **Fix (Matt chose the INPUT_SIZE route over sending `dim`):** the bench's real `vs_render` already broadcasts `dim` (640 x 640), so `bench_modules.py` `INPUT_SIZE` now feeds `f_grain`, `f_tf_aniso_blur`, `f_tf_glyph`, `f_vf_vorticity` a 640 input (`RENDER_DIM_SIZE`); inlets 2+ follow. Test-harness change only; no module touched.
- **Re-run 22:12:** `tests/bench.sh -q tests/contracts/bench_modules.py` 2/2, all selected files passed (log `tests/logs/latest-bench`). The `f_a_decorrelate` XFAILs are the known audio case.
- **Note:** the 640 is inferred from the failing shape, not read from `vs_render`; the old "512" comment for `f_vf_fluid` is now worded as fluid-specific.
