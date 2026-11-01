# HANDOFF

## START HERE (2026-11-01)

**Read order for a new session:** CLAUDE.md, this block, `.specify/plan.md` (one-page focus), `.specify/gates.md`. README.md is NOT required. Older entries are in `HANDOFF_ARCHIVE.md`: grep it, do not read it whole.

**State:** closed: T062/T063 (`render_dim` migration; `f_masonry` and `f_cmap` stay exempt) and the `f_vf_advect` Trail rework (live look passed). Live contract bench: first run 21:52 failed (harness bypass-shape gap for four `render_dim` modules), fixed in `tests/contracts/bench_modules.py`, re-run 22:12 GREEN (2/2). Also closed that evening: Hatch (T051 README marker dropped, T061 8 ms gate kept, T052 helpfile written and checked, T065 tier-3 questions decided; only the spike-script tail of T064 remains) and `f_ks` tier-3 tuning (map, defaults, ranges unchanged). 2026-11-01: Claims rule added to CLAUDE.md and `tests/build/test_gates.py` written; Hatch's Q17 (NaN in E1) probed clean, and Matt decided no permanent bench rows or live check for it. Nothing is scheduled; Matt picks the next item.

**Candidates (Matt decides):**
- Render-trigger check: `f_stipple`, `f_weave`, `f_vf_flow` may draw nothing unconnected (the `f_quasi` bug).
- Hatch tail (T064): the spike scripts `camera_like.py` and `lic_stills*.py` still pass `strength=` and fail.
- Tier-3 tuning owed: `f_wave_field` T030 (its full bench re-run is owed once after tuning, with only `bench.maxpat` open). `f_ks` still needs its name (T010) and docs (T040).
- `vs_black` wording in `skills/vsynth-bpatcher/SKILL.md` and `docs/vsynth-reference/patterns.md` (the skill needs Matt's re-upload and `skills/check.sh stamp`).
- `f_vf_seeds` cost at 1080p is unmeasured; optional cap on the `f_vf_advect` Trail dial.

**Process:** discuss design before code; one phase per turn; ask before any bench run; Desktop Commander for files (`mcp__remote-devices__Desktop_Commander__*`, load schemas with ToolSearch); `edit_block` for targeted edits, and never rewrite a CRLF file in text mode; commit per module.

**End of session:** update this block and the `.specify/gates.md` rows you touched. Keep the new entry under about 15 lines; narrative goes in the commit message.

## 2026-11-01 (08:30): Claims rule and gates check added; Hatch Q17 probed clean

- **Claims rule (CLAUDE.md "Claims"):** status claims cite their source; reconcile `gates.md`, `plan.md` and the module's `tasks.md` before saying closed; inferred is not verified; records say who observed what. `tests/build/test_gates.py` (5/5) flags a Waiting gate whose cited tasks are all ticked or that cites a missing task or path; it cannot see rows that cite no task ids. `finishing-a-session` skill step 6 added (claude-scaffold `2623572`; Matt re-uploaded it).
- **Hatch Q17:** `.specify/f_tf_hatch/spike/bench_e1_nan_probe.py` 5/5, zero NaN/inf in E1 on zero, isotropic and mixed tensors (log `tests/logs/20261101-082451-bench.log`, Max 9.2.0; T066). Matt decided no permanent bench rows and no live check. Not explained: why glyph's `atan2(0,0)` NaN does not reproduce in E1. The `G-hatch` row is removed and Hatch is out of `G-tensor-t3` (four README warnings left).
- **Evening of 2026-10-31 (archive entry 23:58):** Hatch closed out (T051, T052, T061, T065; only the spike-script tail of T064 remains); `f_ks` tier-3 done with no code change (T005, T012, T030 closed; T010 name and T040 docs open); contract bench green after a harness input-size fix.
- **Commits (f_):** b977cbf, 3deb87d, 9648d97, 6969d59, 65f58de, 7fd9b59, 3ce861b, ad7408f, then this handoff commit.
- **Next:** `f_wave_field` T030 tuning (dials plus the `medium` presets), then its one full bench re-run (only `bench.maxpat` open); then the render-trigger check.
