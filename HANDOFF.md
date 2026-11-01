# HANDOFF

## START HERE (2026-11-01)

**Read order for a new session:** CLAUDE.md, this block, `.specify/plan.md` (one-page focus), `.specify/gates.md`. README.md is NOT required. Older entries are in `HANDOFF_ARCHIVE.md`: grep it, do not read it whole.

**State:** closed 2026-11-01: `f_weave` (unconnected lines, across/along/vecfield inlets, density/weight/marklen/softness; Matt live; live contract bench green 2/2), `f_stipple` unconnected rendering (T044 gated `r draw` trigger, T045 render-size output; Matt live "works as expected"; live contract bench green 2/2 at 08:52 after adding it to `INPUT_SIZE`). Closed earlier: T062/T063 (`render_dim` migration; `f_masonry` and `f_cmap` stay exempt), the `f_vf_advect` Trail rework, Hatch (only the spike-script tail of T064 remains), `f_ks` tier-3 tuning (map, defaults, ranges unchanged), the Claims rule in CLAUDE.md with `tests/build/test_gates.py`. Nothing is scheduled; Matt picks the next item.

**Candidates (Matt decides):**
- Render-trigger check, remaining: `f_vf_flow` (same `dual` wiring and the same unconnected-use doc claim; apply the `f_stipple` pattern, design check first; notes in the latest entry).
- `f_weave` scope questions (open, for Matt's thinking time; gate `G-weave-scope`, `ideas/f_weave_scope_questions.md`): keep the vecfield inlet or use `f_vf_warp`.
- Hatch tail (T064): the spike scripts `camera_like.py` and `lic_stills*.py` still pass `strength=` and fail.
- Tier-3 tuning owed: `f_wave_field` T030 (its full bench re-run is owed once after tuning, with only `bench.maxpat` open). `f_ks` still needs its name (T010) and docs (T040).
- `vs_black` wording in `skills/vsynth-bpatcher/SKILL.md` and `docs/vsynth-reference/patterns.md` (the skill needs Matt's re-upload and `skills/check.sh stamp`). New fact for that wording: `vs_black` is a 1x1 texture (`vs_render.maxpat`).
- `f_vf_seeds` cost at 1080p is unmeasured; optional cap on the `f_vf_advect` Trail dial.

**Process:** discuss design before code; one phase per turn; ask before any bench run; Desktop Commander for files (`mcp__remote-devices__Desktop_Commander__*`, load schemas with ToolSearch; the plain Bash tool runs in a cloud sandbox, not on the Mac); `edit_block` for targeted edits, and never rewrite a CRLF file in text mode; commit per module. Do not mention or follow up on demo `.maxpat` files Matt edits (Matt, 2026-11-01). Long bench runs outlast the relay's 60 s wait: start with a short timeout, then ask Matt to say when it is done.

**End of session:** update this block and the `.specify/gates.md` rows you touched. Keep the new entry under about 15 lines; narrative goes in the commit message.

## 2026-11-01 (09:55): `f_weave` rebuilt: unconnected lines, three inlets, packing, crisp softness

- **Commits (f_):** a5c9022 (dual: straight lines at `angle` unconnected, render size), 6106fb7 (`density` to 64 cells above 0.5, `weight`/`marklen` 0-1), 4451e2f (`softness` 0 crisp, 1 = old softness 1), then the inlet commit. Matt live: density/weight/marklen "much better"; all three inlets work. Softness crisp look confirmed live (Matt, 09:58).
- **Final shape:** `processor` + `driving_inlet`, `mod_inlets` across (inlet 0, `in1`, flag `src_potential`, also tints), along (inlet 1, `in2`, `src_along`, new), vecfield (inlet 2, `in3`, `src_field`). The `dual` pieces (`obj-17`, `obj-18`, `src_mode`) are gone; the gated `r draw` is keyed on inlet 0's `vs_inState` (`obj-101`). Nothing connected: straight lines at `angle`. The vecfield steers only axes a scalar has not replaced (with 0 and 1 both connected it does nothing: by design, Matt saw it).
- **Wiring changed:** patches that fed weave a vecfield on inlet 0 and a scalar on inlet 1 need rewiring. Docs/help/README updated (`f_vf_flow`, `f_vf_potential` help point at the new inlets).
- **Checks:** `tests/modules/weave/test_weave_static.py` 7/7 (trigger, flags, codebox reads, density curve, softness), full offline suite green 66 files, `drift -v f_weave` ok (Claude, offline).
- **Live contract bench:** 09:53 FAIL 1/2 (weave's bypass frame 640x640 against the 64x64 input, the same harness gap as stipple); `f_weave` added to `INPUT_SIZE` in `tests/contracts/bench_modules.py`; rerun GREEN 2/2 (log `tests/logs/20261101-095527-bench.log`, Max 9.2.0).
- **Correction:** an earlier entry said `f_quasi` has two `vs_inState`; it has one (parsed). Removed from the archived text.
- **For `f_vf_flow` (next):** copy the bottom of `src/f_stipple/definition.py` (gated `r draw`; `obj-17` `vs_inState`, `obj-5` pix, check both in the built patcher) plus `pix_attrs`/`render_dim`; adapt `tests/modules/stipple/test_stipple_static.py`. Its codebox has no `dim.` reads; it is not in `bench_modules.py`. Design check first.
- **Next:** `f_vf_flow`; then `f_wave_field` T030 tuning.

