# HANDOFF

## START HERE (2026-11-01)

**Read order for a new session:** CLAUDE.md, this block, `.specify/plan.md` (one-page focus), `.specify/gates.md`. README.md is NOT required. Older entries are in `HANDOFF_ARCHIVE.md`: grep it, do not read it whole.

**State:** closed 2026-11-01: `f_stipple` unconnected rendering (T044 gated `r draw` trigger, T045 render-size output; Matt live "works as expected"; live contract bench green 2/2 at 08:52 after adding it to `INPUT_SIZE`). Closed earlier: T062/T063 (`render_dim` migration; `f_masonry` and `f_cmap` stay exempt), the `f_vf_advect` Trail rework, Hatch (only the spike-script tail of T064 remains), `f_ks` tier-3 tuning (map, defaults, ranges unchanged), the Claims rule in CLAUDE.md with `tests/build/test_gates.py`. Nothing is scheduled; Matt picks the next item.

**Candidates (Matt decides):**
- Render-trigger check, remaining: `f_vf_flow` (same `dual` wiring and the same unconnected-use doc claim; apply the `f_stipple` pattern, design check first) and `f_weave` (decided 2026-11-01, plan in the latest entry: make it a `dual` through the definition so it draws straight lines at `angle` unconnected).
- Hatch tail (T064): the spike scripts `camera_like.py` and `lic_stills*.py` still pass `strength=` and fail.
- Tier-3 tuning owed: `f_wave_field` T030 (its full bench re-run is owed once after tuning, with only `bench.maxpat` open). `f_ks` still needs its name (T010) and docs (T040).
- `vs_black` wording in `skills/vsynth-bpatcher/SKILL.md` and `docs/vsynth-reference/patterns.md` (the skill needs Matt's re-upload and `skills/check.sh stamp`). New fact for that wording: `vs_black` is a 1x1 texture (`vs_render.maxpat`).
- `f_vf_seeds` cost at 1080p is unmeasured; optional cap on the `f_vf_advect` Trail dial.

**Process:** discuss design before code; one phase per turn; ask before any bench run; Desktop Commander for files (`mcp__remote-devices__Desktop_Commander__*`, load schemas with ToolSearch; the plain Bash tool runs in a cloud sandbox, not on the Mac); `edit_block` for targeted edits, and never rewrite a CRLF file in text mode; commit per module. Do not mention or follow up on demo `.maxpat` files Matt edits (Matt, 2026-11-01). Long bench runs outlast the relay's 60 s wait: start with a short timeout, then ask Matt to say when it is done.

**End of session:** update this block and the `.specify/gates.md` rows you touched. Keep the new entry under about 15 lines; narrative goes in the commit message.

## 2026-11-01 (09:05): `f_stipple` unconnected rendering fixed (trigger + size); contract bench green

- **Trigger (T044):** unconnected `f_stipple` drew nothing (Matt, live; the `f_quasi` bug). `src/f_stipple/definition.py` `raw_boxes`/`raw_lines`: `r draw` -> `gate 1 1` -> pix inlet 0, the gate closed by `vs_inState`'s connected flag through `== 0`, so a connected stipple renders once per frame. Matt chose gated and per-module raw_lines. The gate starts open because that flag is a `change`, which probably swallows a first 0 (inferred from reading `vs_inState.maxpat`, not probed).
- **Size (T045):** with the trigger in, unconnected source mode was a solid frame flipping white/black near `threshold` 0.2 (Matt, live). Inferred, not probed: the pix adapted to `vs_black`, a 1x1 texture. Fix: `pix_attrs "@adapt 0 @dim 256 256"` plus `render_dim {"size_stages": ["primary"]}` (no width/height Params; the codebox reads `norm`). Matt live: works as expected.
- **Checks:** `tests/modules/stipple/test_stipple_static.py` 4/4, `test_render_dim` 12/12, `test_bench_expect` 10/10, `drift -v f_stipple` ok (Claude, offline). Live contract bench: 08:48 FAIL 1/2 (stipple's bypass frames 640x640 against the 64x64 input, a harness gap), `f_stipple` added to `INPUT_SIZE` in `tests/contracts/bench_modules.py`, 08:52 GREEN 2/2 (log `tests/logs/20261101-085202-bench.log`, Max 9.2.0).
- **For `f_vf_flow`:** same `dual` wiring, no `r draw`, default `@adapt`; its codebox has no `dim.` reads and it is not named in `bench_modules.py` (its bypass expectation there is not checked). Copy the bottom of `src/f_stipple/definition.py` (raw boxes/lines; `obj-17` is `vs_inState`, `obj-5` the pix, check both in the built patcher) and the `pix_attrs`/`render_dim` keys, and adapt `tests/modules/stipple/test_stipple_static.py`.
- **`f_weave` (decided by Matt 2026-11-01, not started):** unconnected it draws straight lines at `angle` (no field); it becomes a `dual` through `definition.py` (inlet 0 = the optional vecfield); the connected output may follow the render size. Found by reading, not run: inlet 0 is the vecfield (`sample(in1, norm)`), `in2` the scalar, only the scalar inlet has a `vs_inState`, and ADR 4's `src_vecfield` gate is absent from `definition.py` (grep), so an unconnected black inlet would read as a constant (-0.5, -0.5) field. Plan: archetype `dual` (state param `src_mode`); scale the codebox field term `vx`, `vy` by `src_mode` (connected multiplies by 1, so connected output should be unchanged: check offline); `pix_attrs "@adapt 0 @dim ..."` plus `render_dim` size stage; a gated `r draw` as in stipple if `dual` adds no trigger. Unverified: that the builder supports `dual` with weave's scalar mod inlet (`f_quasi` has two `vs_inState`); `f_weave` is not in the drift baseline. Fix the doc's "routepass out0 (texture or vs_black)" line. No tier-1 mirror exists for weave (`P-mirrors`).
- **Gates:** the `P-taxonomy` row is updated: `f_weave` is being made a `dual`.
- **Docs and record:** `docs/f-reference/f_stipple.md` (signal chain, source-mode note), `.specify/f_stipple/tasks.md` T044/T045, `.specify/plan.md` Next 1.
- **Commits (f_):** d1144ac, 131a1c9, then this handoff commit.
- **Next:** `f_vf_flow` with the stipple pattern; then `f_weave` per the decisions above; then `f_wave_field` T030 tuning.
