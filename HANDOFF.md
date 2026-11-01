# HANDOFF

## START HERE (2026-10-31)

**Read order for a new session:** CLAUDE.md, this block, `.specify/plan.md` (one-page focus), `.specify/gates.md`. README.md is NOT required. Older entries are in `HANDOFF_ARCHIVE.md`: grep it, do not read it whole.

**State:** closed: T062/T063 (`render_dim` migration; `f_masonry` and `f_cmap` stay exempt) and the `f_vf_advect` Trail rework (live look passed). Nothing is scheduled; Matt picks the next item.

**Candidates (Matt decides):**
- Run the live module contract bench (Max). Not run since the `render_dim` migrations (tensormap, glyph, aniso_blur, axisflow, vorticity, quasi, grain, seeds).
- Render-trigger check: `f_stipple`, `f_weave`, `f_vf_flow` may draw nothing unconnected (the `f_quasi` bug).
- Close Hatch: v1 helpfile T052, README marker T051, 8 ms gate T061 (`.specify/f_tf_hatch/tasks.md`).
- Tier-3 tuning owed: `f_ks` T030 and `f_wave_field` T030 (both built; docs and registration pending).
- `vs_black` wording in `skills/vsynth-bpatcher/SKILL.md` and `docs/vsynth-reference/patterns.md` (the skill needs Matt's re-upload and `skills/check.sh stamp`).
- `f_vf_seeds` cost at 1080p is unmeasured; optional cap on the `f_vf_advect` Trail dial.

**Process:** discuss design before code; one phase per turn; ask before any bench run; Desktop Commander for files (`mcp__remote-devices__Desktop_Commander__*`, load schemas with ToolSearch); `edit_block` for targeted edits, and never rewrite a CRLF file in text mode; commit per module.

**End of session:** update this block and the `.specify/gates.md` rows you touched. Keep the new entry under about 15 lines; narrative goes in the commit message.

## 2026-10-31 (11:35): `f_vf_advect` Trail REWORKED to a persistence multiplier (Matt: option A); the jump at trail = 1.0 is gone. Offline green, GPU bench 2/2 (2026-10-31 17:05), live look PASSED (Matt, 17:04: the Trail sweep is smooth; the immiscible demo presets were updated by Matt and are fine). CLOSED

- **The bug:** trail >= 1 switched to an absolute half-life (`hl = trail * exp((decay - 1) * 20)`, clamped to >= 1 frame), but trail 0 was the classic loop, which at Decay 0.97 is a 22.8-frame half-life. So sweeping Trail through 1.0 dropped persistence from 22.8 frames to 1 (decay_eff 0.97 -> 0.5, injection x16.7), held flat to ~1.82, then climbed back (the classic look sat at trail ~41). The settled level was already continuous; persistence was not.
- **The fix (option A):** `m = 1 + trail`, `decay_eff = decay^(1/m)`: half-life = the classic half-life x m, so trail 0 is the classic loop bit for bit (a `step(1e-6, trail)` select keeps it exact), 1 = twice as long, 3 = four times, 9 = ten times, continuous and monotone everywhere. Injection is rescaled by `(1 - decay_eff) / (1 - decay)` (limit `1/m` within 0.001 of decay 1.0, divisor kept off zero so the masked branch cannot NaN), so a still source settles at the CLASSIC `injection / (1 - decay)` whatever the trail. Decay > 1 works: the growth rate is divided by m.
- **Given up (Matt chose A knowing the first two):** the absolute-frames meaning of Trail and the log-scale Decay x Trail scaling from 10-28; the settled level `injection / 0.03` independent of Decay (it is `injection / (1 - decay)` again). NOT flagged before choosing, found after: **at Decay exactly 1.0 Trail does nothing** (`1^(1/m) = 1`, nothing fades, nothing to lengthen).
- **Changed:** `codebox_advect.gen`, the mirror (`vf_advect_mirror.py`, new mutation `legacy_trail` = the old form), `test_vf_advect.py` (15/15: trail 0 bit-identical; half-life = classic x (1 + trail), exact case decay 0.5^(1/10) trail 2 -> half in 30 frames; excitable growth slowed by m; settled level classic for trails 0-12 at decay 0.97 / 0.9; a 0..3 trail sweep with no step above 0.0018 (the old form's was 0.22) and no jump across decay = 1.0; the mutations incl. the old jumping trail are caught), `bench_vf_advect.py` (cases and the half-life leg rewritten for the multiplier, incl. decay 1.0 / 0.9995 / 1.0005 and 1e-7), `definition.py` (Decay / Inject / Trail hints), `docs/f-reference/f_vf_advect.md`. Patcher rebuilt, `drift -v f_vf_advect` ok. Offline: drift, module contracts, `test_render_dim`, `test_launch`, `test_generate_menu` all pass.
- **Unchanged on purpose:** the Trail dial is still 0-1000 with the cubic taper. That is now x1 to x1001 (up to ~23000 frames at the default Decay), so the top half of the dial is far past useful; a cap near 50-100 is a one-line change if wanted.
- **Owed:** (1) Matt's live look: sweep Trail through 0 / 1 / 2 on a real chain: no jump; (2) DONE: GPU bench `tests/bench.sh -q tests/modules/vf_advect/bench_vf_advect.py` passed 2/2 (every Trail x Decay x Inject case, incl. decay 1.0 / 0.9995 / 1.0005 and trail 1e-7, matches the mirror within 2e-5; the 30-frame half-life leg passes); (3) **`package/examples/f_demo_immiscible.json` has two advect presets in the OLD meaning and will now trail far too long:** `f_vf_advect` Decay 1.0 / Trail 60 / Inject 0.000904 (nothing fades at Decay 1.0 now), and Decay 0.97244 / Trail 98.84 / Inject 0.001716. Equivalent values for the old looks (computed, NOT applied): first Decay 0.9885, Trail 0, Inject 0.000346; second Decay 0.97244, Trail 1.32, Inject 0.001577. The `f_demo_axisflow` and `f_demo_quasi` presets have Trail 0 and are unaffected.
