# HANDOFF

## START HERE (2026-10-31)

**Read order for a new session:** CLAUDE.md, this block, `.specify/plan.md` (one-page focus), `.specify/gates.md`. README.md is NOT required. Older entries are in `HANDOFF_ARCHIVE.md`: grep it, do not read it whole.

**State:** closed: T062/T063 (`render_dim` migration; `f_masonry` and `f_cmap` stay exempt) and the `f_vf_advect` Trail rework (live look passed). Live contract bench RAN 21:52 and FAILED (bypass frame shape for four `render_dim` modules; diagnosed, not fixed: see the latest entry). Nothing is scheduled; Matt picks the next item.

**Candidates (Matt decides):**
- Contract bench harness fix, then re-run `tests/bench.sh -q tests/contracts/bench_modules.py`: first run after the `render_dim` migrations failed on bypass frame shape (`f_grain`, `f_tf_aniso_blur`, `f_tf_glyph`, `f_vf_vorticity`). Matt picks option A/B/C below.
- Render-trigger check: `f_stipple`, `f_weave`, `f_vf_flow` may draw nothing unconnected (the `f_quasi` bug).
- Close Hatch: v1 helpfile T052, README marker T051, 8 ms gate T061 (`.specify/f_tf_hatch/tasks.md`).
- Tier-3 tuning owed: `f_ks` T030 and `f_wave_field` T030 (both built; docs and registration pending).
- `vs_black` wording in `skills/vsynth-bpatcher/SKILL.md` and `docs/vsynth-reference/patterns.md` (the skill needs Matt's re-upload and `skills/check.sh stamp`).
- `f_vf_seeds` cost at 1080p is unmeasured; optional cap on the `f_vf_advect` Trail dial.

**Process:** discuss design before code; one phase per turn; ask before any bench run; Desktop Commander for files (`mcp__remote-devices__Desktop_Commander__*`, load schemas with ToolSearch); `edit_block` for targeted edits, and never rewrite a CRLF file in text mode; commit per module.

**End of session:** update this block and the `.specify/gates.md` rows you touched. Keep the new entry under about 15 lines; narrative goes in the commit message.

## 2026-10-31 (21:55): live contract bench run: FAIL 1/2, 6 bypass-shape issues, all in four `render_dim` modules. Diagnosed only, NOT FIXED

- **Run:** `tests/bench.sh -q tests/contracts/bench_modules.py`, 109 s, log `tests/logs/20261031-215154-bench.log`. `test_live_module_contracts` fails, the other test passes. 49 modules checked; the `f_a_decorrelate` XFAILs are the known audio case.
- **Failures:** `f_grain` out1-3, `f_tf_aniso_blur` out1, `f_tf_glyph` out1, `f_vf_vorticity` out1: "bypassed frame is (640, 640, 4), expected (64, 64, 4)". Nothing else is unexpected.
- **Cause (read-only, not confirmed live):** these four have passthrough bypass expectations (`("in", k)` / `in_a1` in `BYPASS_EXPECT`) and their output now follows the render size (`@adapt 0`, size from Vsynth's `dim W H` broadcast; "the input is assumed render-sized"). The bench feeds a 64x64 input and sends no `dim`, so they render at the 640 default and `bypass_issues` trips on the shape check. `const` expectations (axisflow, tensormap, quasi) skip that check, so they pass. Reads as a harness expectation gap, not a module bug.
- **Options (Matt decides):** (A) the harness sends `dim 64 64` before the bypass pass (risk: `s dim` is global in Max; check how other tests drive it); (B) feed these modules a 640x640 input (slower); (C) a short exception list asserting a (640, 640) frame plus a downsampled value check against the input.
- **Owed:** Matt picks A/B/C; then fix `tests/contracts/bench_modules.py` (and `test_bench_expect.py` if the expectation logic changes) and re-run that one file. Nothing committed; repo was clean at session start.
