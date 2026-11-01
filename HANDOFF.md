# HANDOFF

## START HERE (2026-10-31)

**Read order for a new session:** CLAUDE.md, this block, `.specify/plan.md` (one-page focus), `.specify/gates.md`. README.md is NOT required. Older entries are in `HANDOFF_ARCHIVE.md`: grep it, do not read it whole.

**State:** closed: T062/T063 (`render_dim` migration; `f_masonry` and `f_cmap` stay exempt) and the `f_vf_advect` Trail rework (live look passed). Live contract bench: first run 21:52 failed (harness bypass-shape gap for four `render_dim` modules), fixed in `tests/contracts/bench_modules.py`, re-run 22:12 GREEN (2/2). Also closed that evening: Hatch (T051 README marker dropped, T061 8 ms gate kept, T052 helpfile written and checked, T065 tier-3 questions decided; only the spike-script tail of T064 remains) and `f_ks` tier-3 tuning (map, defaults, ranges unchanged). Nothing is scheduled; Matt picks the next item.

**Candidates (Matt decides):**
- Render-trigger check: `f_stipple`, `f_weave`, `f_vf_flow` may draw nothing unconnected (the `f_quasi` bug).
- Hatch tail (T064): the spike scripts `camera_like.py` and `lic_stills*.py` still pass `strength=` and fail.
- Tier-3 tuning owed: `f_wave_field` T030 (its full bench re-run is owed once after tuning, with only `bench.maxpat` open). `f_ks` still needs its name (T010) and docs (T040).
- `vs_black` wording in `skills/vsynth-bpatcher/SKILL.md` and `docs/vsynth-reference/patterns.md` (the skill needs Matt's re-upload and `skills/check.sh stamp`).
- `f_vf_seeds` cost at 1080p is unmeasured; optional cap on the `f_vf_advect` Trail dial.

**Process:** discuss design before code; one phase per turn; ask before any bench run; Desktop Commander for files (`mcp__remote-devices__Desktop_Commander__*`, load schemas with ToolSearch); `edit_block` for targeted edits, and never rewrite a CRLF file in text mode; commit per module.

**End of session:** update this block and the `.specify/gates.md` rows you touched. Keep the new entry under about 15 lines; narrative goes in the commit message.

## 2026-10-31 (23:58): Hatch closed out; `f_ks` tier-3 tuning done with no code change

- **Hatch:** README marker dropped (launcher regenerated, `test_launch` 8/8); 8 ms gate kept; v2 helpfile written and Matt checked it in Max; OQ1/3/4/6/7 decided as leaned (spec "Tier-3 decisions"); the reference doc's References gained the coherence-persistence line.
- **T064 correction:** the demo's `strength[1]` bindings belong to its `f_tf_tensormap` (obj-7), not Hatch; the Hatch bpatcher there has exactly the eight v2 bindings. Nothing removed. Not tested: that the demo loads in Max.
- **`f_ks`:** Matt's live look: `rate`, `scale`, `sharp` all smooth and expressive; the pattern reads about 3 s after reset at the default rate (about 2 s at the top). Clamp map, defaults and ranges stay (T005 closed unrun, T012 decided, T030 `[x]`). Matt passed on the "organic and distinct" verdict (T030 now `[x]`) and on naming it; T010 name and T040 docs stay open.
- **Commits:** b977cbf, 3deb87d, 9648d97, 6969d59, 65f58de. Tree clean after the HANDOFF commit.
- **Next:** `f_wave_field` T030 tuning (one module, dials plus the `medium` presets), then its bench re-run once; then the render-trigger check.
