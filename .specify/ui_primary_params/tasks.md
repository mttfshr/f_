# Tasks: primary / secondary params spike

Spec: `spec.md`. Record of results: this file. Who observed what is stated per task (CLAUDE.md Claims).

## Phase 0: scaffold (2026-11-22, offline, Claude)

- [x] T001 `inventory.py` and `inventory.json`: 53 non-paused modules, 407 params, 0 definition errors (observed by running the script, 2026-11-22). Widgets: 331 dial, 47 number box, 15 menu, 10 text_button, 3 gate_button, 1 header_toggle. 14 modules already mix dials and number boxes; 38 modules have 4 or more dial/number params, 15 have 3 or fewer.
- [x] T002 `spec.md`: hypotheses, definitions, three judges, success and stop rules, pilot set.
- [x] T003 Matt reviewed `spec.md` and said it looks good to try (2026-11-22, after H2 was softened to a default).

## Phase 1: assess (the actual test)

- [x] T010 J1 rubric (Claude, offline, Matt's go 2026-11-22): `roles.json`, 91 float/int params over the 8 pilot modules, role + confidence + reason each; checked against `inventory.json` (none missing or extra). Read: every pilot module's `definition.py` hints; reference docs for `f_vf_advect`, `f_vf_glow`, `f_grain` only (`f_lens`, `f_weave`, `f_halftone`, `f_separate`, `f_vf_erode` were judged from hints). No runs.
- [ ] T011 J2 blind sheets. Generated 2026-11-22 (Claude, `make_sheets.py`), regenerated the same day after H3: `sheets/sheet_<module>.md` for the 8 pilot modules, 63 untyped params (the other 28 are typed by H3 and listed under each sheet), name, label, range and default only, widgets and J1 labels left off. Matt may do the hands-on version instead (rearranged named scratch copy, top row primary); not yet chosen. **Waiting on Matt to fill them in** (P / S / ? and optional notes). Do not show `roles.json` before he returns them.
- [ ] T012 J3 feasibility (Claude, offline, reading only): for each of the 7 mirrors, can a param sweep be driven from the mirror's public function, and what output does it return? Result is a table here, no sweeps run yet.
- [ ] T013 J3 sweeps: a script `sweep.py` in this folder, NumPy only (`uv run --no-project --with numpy python3`). Per CLAUDE.md the count first (modules, params, sweep points, input image) goes to Matt, then his go, then `-q`.
- [ ] T014 Compare J1, J2, J3 against the spec's rules; write the result table and a verdict (proceed, park, or amend the definition) at the bottom of this file. Gate row `P-ui-roles` if parked.

## Phase 2: layout test (only if T014 says proceed)

- [x] T020 (changed 2026-11-22, Matt: build all 8 pilot layouts from J1's recommendations now, before J2 and without waiting for T014; `f_weave` / `f_vf_erode` are set aside by the pool rule). Role split = `roles.json` (J1) plus H3 typing.
- [x] T021 Scratch layouts built 2026-11-22 (Claude, offline, Matt's go): `scratch/experiments/ui_roles/<module>_roles.maxpat` x 8 and `make_roles_layouts.py` (gitignored). Made through the real builder (a copy of each definition with widgets set and rects as `overrides`), not hand JSON; nothing in `src/` or `package/` touched. Offline check only: each reloads as JSON, same box count as the stock build, every control inside its panel, no control overlaps, no number box on the dial row. Not opened in Max.
- [x] T022 Matt looked at all 8 scratch layouts in Max, 2026-11-22: "these 8 all look great", proceed. (Live look by Matt; no per-module notes given.) Whether a `role` key in `definition.py` is worth a schema change is still open. J2 (T011) and J3 (T012-T013) were not done; the layouts were judged on look alone, so H1's thresholds in the spec were never tested.

## Record

### 2026-11-22: J1 result (Claude, offline; inferred from text, not observed in use)

- **Primaries per module** (spec rule: 2 to 5): halftone 3 (pitch, jitter, level), separate 4 (three ink hues, n_inks), erode 3 (flow, lift, settle), weave 5 (density, angle, weight, marklen, offset), lens 3 (aberration, distortion, transmission), advect 2 (decay, dt), glow 2 (radius, direction), grain 4 (density, size, persistence, luma_gate). All 8 are in range; 26 of 91 params are primary. 9 of the 26 are low confidence (jitter, level, n_inks, settle, offset, transmission, dt, direction, luma_gate): expect J2 to differ there.
- **Where the rubric strained (findings for the spec):**
  1. *Mode-conditional primaries.* `f_halftone` `level` matters only on the Threshold screen, `jitter` only on Dot. The true primary there is the `screen` menu, which is out of scope, so the dial role depends on a menu state.
  2. *Bundles of independent effects.* `f_lens` is five separate effects, each with its own amount; kind versus degree barely separates them, so its split is a judgment call and a good J2 test.
  3. *Groups.* `f_separate` repeats one group (H, S, L, gain) three times: hue primary, the rest secondary, which cuts across Matt's 2026-11-18 finding that an HSL triple reads best as three boxes together (an H2 exception, spec).
  4. *Live-performed secondaries* (`f_weave` `phase`, `f_vf_advect` `dt`): criterion 2 and the role disagree.
- **Side findings, not fixed (not mine):** `f_grain` hints for `fade` and `ch_diverge` repeat `persistence`'s text, and its `shape` hint says -1..1 against a 0..1 range; `f_vf_glow` `radius`, `falloff`, `color_mix`, `direction` and `f_vf_advect` `dt`, `gain`, `separate`, `mode` have empty hints.
- **Not a result for H1:** J1 alone cannot support or fail it (spec). Next is T011 (the blind sheets for Matt), then T012.

### 2026-11-22: H3 soft typing and H4 top-row rule added (Matt's calls, Claude wrote them)

- Spec now has H3 (five ordered rules: small discrete -> menu, companion amounts -> number box incl. gain even when primary, circular -> dial, else H2, groups may override) and H4 (number boxes generally not on the first row). Gain as a number box is a proposal only: 26 of 29 gain params are dials today (observed in `inventory.json`), so applying it would flip about 26 across 23 modules; nothing changed in any definition.
- `roles.json`: 28 of the 91 pilot params carry a `typed` key (rule and widget by type); their J1 role is kept as a record. 63 untyped remain for J2. J1's primaries among the untyped: 20.
- Success rule 2 amended (spec): with H3, `f_separate` has 0 untyped primaries (its character is in the typed ink hues and `n_inks`), so "2 to 5" would fail it for a structural reason. Changed after seeing J1, not J2; flagged in the spec.

### 2026-11-22: pool rule

- Matt: set aside modules with substantive layout customization already; when in doubt, set aside. 15 clear, 11 light, 3 audio set aside (lists in spec). Six of the original pilot are in that set; T010 and T011 stand for `f_vf_advect` and `f_vf_glow` only. Sheets for the six moved to `sheets/_set_aside/` so they are not filled in by mistake.

### 2026-11-22: J1 for the new pilot (Claude, offline; inferred from text)

- `roles.json` now covers `f_stipple`, `f_quasi`, `f_vf_seeds`, `f_vf_vortex`, `f_tf_hatch`, `f_vf_ch`, with H3 typing applied. Read: definition hints for all six; reference doc tables for all but `f_quasi` (none found; hints only). No runs.
- **Untyped primaries per module** (typed params excluded): stipple 3 (coarseness, anisotropy, threshold), quasi 2 (density, envelope), seeds 4 (density, size, jitter, stretch), vortex 2 (convergence, curl), hatch 4 (reach, grain, density, line_hard), ch 3 (coarsen, inject, dt); with the carried-over advect 2 (decay, dt) and glow 1 (radius). All 8 are in range of the amended rule 2 (none has zero).
- **Typed:** `*_amt` / `*_mod` depths and `gain` / `mix_pct` (number box); `angle`, `angle_offset` (dial); `taps` (big int, number box); `bomb` (on/off, toggle).
- **Judgment calls to watch (low confidence):** `dt` is primary in both `f_vf_advect` and `f_vf_ch` for consistency (degree more than kind, but a live lever); `f_quasi` `zoom` and `drift` are cyclic wraps by design and might extend H3 rule 3 (circular -> dial): left untyped, secondary, for Matt to decide; `f_stipple` `threshold`; `f_tf_hatch` `line_hard`; `f_vf_seeds` `stretch` and `field_priority`; `f_vf_vortex` `cx` / `cy` (placement, performed live).
- **Sheets:** `sheets/sheet_<module>.md` for the 8 pilot modules (untyped params only: advect 5, glow 3, stipple 9, quasi 7, seeds 10, vortex 5, hatch 7, ch 7 = 53); T011 waits on Matt.

### 2026-11-22: scratch role layouts for the 8 pilot modules (Claude, offline; unlooked-at in Max)

- **Rule applied** (spec H2, H3, H4, from J1 roles, not J2): dial = untyped primary or typed circular (`angle`, `angle_offset`); number box = every other float or int; menus keep their widget; dial row first, number boxes below on the builder's own grid (pitch 37, label above, rows 38 px). Panel width unchanged from stock; height follows the content.
- **Result** (dials | number boxes | panel W x H): advect 2 | 5 + the Mode menu | 190 x 160; glow 1 | 5 | 190 x 122; stipple 4 | 6 | 191 x 160; quasi 3 | 6 | 227 x 122; seeds 4 | 9 + the range menu | 190 x 160; vortex 2 | 7 | 196 x 160; hatch 5 | 3 | 190 x 122; ch 3 | 5 | 190 x 160.
- **Stand-ins and gaps:** H3 rule 1 (small discrete -> menu or stepper) is a plain int/float number box here (`f_vf_glow` `direction`, `f_vf_seeds` `bomb`); `f_vf_ch` `taps` has no panel slot in the stock module either; the `f_vf_ch` reset button has no override key, so it stays put and the grid skips its cells; `f_vf_seeds`'s range menu stays where the stock panel puts it (under the first-row labels, as stock); number formats and decimals not tuned; label widths as stock.
- **What the layouts show (inferred, not seen):** the top row is sparse for modules with few primaries (glow 1 dial, advect 2, vortex 2); stipple and hatch fill a row; no module needed more than one dial row. Whether the sparse rows look wrong is Phase 2's question (T022).
- **Use:** put a `bpatcher` of the `_roles` file (same folder as the scratch parent patch, or on the search path) in a patch with its render chain; stock and `_roles` instances can sit side by side (`#0` names are per instance; two instances sharing a name was not tried).

### 2026-11-22: Matt's verdict

- All 8 role layouts look great (Matt, live). He said to proceed; what "proceed" covers is not yet stated (asked). Not run: J2, J3, T014. The spec's H1 success rules are untested; H2 to H4 were accepted on the look.

### 2026-11-22: the rule written down (Matt: "write the rule down")

- `ideas/ui_design_concepts.md`: new section "Rules Matt has confirmed: widget roles" (role, soft typing, spatial, scope, evidence stated plainly) and a status line; `G-ui-density` row updated in `.specify/gates.md`. Docs only; no module, definition or patcher changed.
- Left open: apply to the 8 for real (definition overrides, rebuild), extend to the other untouched pool modules, finish J2/J3. None started.

### 2026-11-22: applied to 16 shipped modules (Claude, Matt's go: "go on 2 and 3"; not committed; not looked at in Max)

- **Applied (8 pilot):** `f_vf_advect`, `f_vf_glow`, `f_stipple`, `f_quasi`, `f_vf_seeds`, `f_vf_vortex`, `f_tf_hatch`, `f_vf_ch`. **Applied (8 pool):** `f_caustic`, `f_chladni`, `f_ks`, `f_tf_glyph`, `f_vf_flow`, `f_vf_fluid`, `f_vf_prism`, `f_wc`. Method: a one-off script (`scratch/experiments/ui_roles/apply_roles.py`, gitignored) set `"widget": "numbox"` on secondary float params, wrote `presentation_height`, filled the overrides block through `build/capture.py`'s `write_block`, and rebuilt each patcher with `build_patcher.py`. J1 roles for the pool are in `roles.json` (hints only, no docs read).
- **Checked (offline, observed):** `tests/build/test_drift.py` 16/16 after each batch (`tests/logs/20261122-171756-offline.log`, `20261122-171939-offline.log`); rebuilt panels equal the planned size, no control overlaps or sits outside the panel; `generate_menu.py --check` was stale for `f_addmod.js` (the size table), regenerated, now up to date. No bench or live run (layout only). One mistake caught: a regex slip added a duplicate `"widget": "numbox"` key to `mix_pct` in advect, glow and ch; removed by hand, the definitions load.
- **Held back, in doubt (Claude's call, growth over 12 px or nothing to lay out):** `f_ngon` (91 -> 122), `f_tf_aniso_blur` (90 -> 122), `f_vf_optical_flow` (130 -> 160), `f_vf_potential` (100 -> 122), `f_vf_repulse` (80 -> 122), `f_vf_streak` (100 -> 122), `f_sirds` (one param). The dial-then-number-box rule forces two rows, which grows a small panel a lot. Matt decides.
- **Panel size changes:** taller: advect +10, glow +2, stipple +3, vf_ch +10, wc +10, flow +8; shorter: quasi -42, hatch -28, caustic 0, chladni -4, ks -22, glyph -28, fluid -28, prism -38; seeds and vortex unchanged. Helpfiles that now embed a module smaller than its panel: `f_vf_ch.maxhelp` (190 x 150, panel 160), `f_wc.maxhelp` (272 x 150, panel 160), `f_chladni.maxhelp` (154 x 91, already below the old frame, Phase 0 of `.specify/preflight/`). Not fixed.
- **Stand-ins:** `f_chladni` `mode` and `view_mode` (0/1 switches) are number boxes now, as are `f_vf_seeds` `bomb` and `f_vf_glow` `direction`; H3's menu/stepper is not built.
- **Judgment calls to watch:** `dt` is primary in advect, ch and potential but secondary in fluid; `f_tf_glyph` has one primary (`grid`); `f_vf_repulse` `gain` is a number box by H3 although it is the effect's magnitude (held anyway).

### 2026-11-22: range selects tucked in (Matt's note; Claude, offline; not committed, not looked at in Max)

- Cause: the small range menus (`range_tiers`) kept their stock positions after the layout change, so they sat on the wrong labels. Fixed in `f_vf_seeds` (`field_gain`) and `f_caustic` (`gain`, `scale`), the only applied modules with range menus (`f_lens` is set aside, `f_vf_vorticity` is paused).
- Rule used: next to a number box, the 16 x 15 menu sits immediately right of it on the same row, and that param takes two grid slots; on a dial (`f_caustic` `scale`) it stays where the builder puts it, at the right end of the label. Observed afterwards: drift 16/16 (`tests/logs/20261122-175910-offline.log`), no control overlaps. The panel sizes did not change.

### 2026-11-22: the held-back seven (Matt: "all 7"; Claude, offline; not committed, not looked at in Max)

- **Applied (6):** `f_vf_optical_flow` (130 -> 160), `f_vf_streak` (100 -> 122), `f_tf_aniso_blur` (90 -> 122), `f_vf_potential` (100 -> 122), `f_vf_repulse` (80 -> 122), `f_ngon` (91 -> 122). Same method and checks as the earlier batches: drift 16/16 (`tests/logs/20261122-180453-offline.log`), no overlaps, `generate_menu.py` rerun (size table).
- **`f_sirds` reverted, not applied:** rebuilding it failed `test_drift.py` (15/16, `tests/logs/20261122-180446-offline.log`: `f_sirds` drifted from its definition, 11 boxes each way). Its shipped patcher does not reproduce from `definition.py` (known side finding, HANDOFF 2026-11-21: a definition plus an older build script, which governs is not established). Restored `src/f_sirds/definition.py` and `package/patchers/f_sirds.maxpat` from git. It has one param, so there was nothing to lay out anyway.
- **Helpfile embeds smaller than the new panel (not fixed):** `f_vf_optical_flow.maxhelp` 154 x 91, `f_vf_streak.maxhelp` 154 x 91, `f_vf_potential.maxhelp` 208 x 110, `f_vf_repulse.maxhelp` 182 x 91, `f_ngon.maxhelp` 172 x 101; most were already below the old frame (preflight Phase 0).
- Totals now: 22 shipped modules carry the role layout (8 pilot, 8 pool, 6 held-back).
