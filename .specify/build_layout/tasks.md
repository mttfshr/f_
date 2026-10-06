# Tasks: Edit-View Layout Pass

**Spec**: `.specify/build_layout/spec.md`
**Build order**: Sequential. Complete each phase before the next.
**Commits**: Matt commits manually, after each verified phase. Suggested split: (1) `build/layout.py` + `tests/test_layout.py`, (2) `build/build_patcher.py` wiring + docs, (3) the six regenerated patchers (`git diff --stat` reviewed; only `patching_rect` + inert label `varname`s changed).

**Status 2026-09-24:** Phases 0–2 done, Phase 3 done for the ten modules that can be regenerated safely (six + four group-A) (T014 = Matt's eyes in Max, pending), Phase 4 done except T017/T018 decisions.

---

## Drift survey (2026-09-24) — why Phase 3 reached only six modules

`scratch/regen_dryrun.py` / `regen_drift_depth.py` (by box id) and `regen_drift_semantic.py` / `regen_drift_props.py` (boxes matched by identity — class + text + parameter name — so renumbered ids don't masquerade as changes) rebuild every `src/*/definition.py` in-process and compare to the shipped patcher, ignoring `patching_rect`. Of **33** definitions: **1 regenerates identically** (`f_ngon`), **5 differ only by inert label `varname`s**, **24 have real drift**, and **3 don't build through `build_patcher.py`**. Phase 3 regenerated the first six, then four group-A modules (T019); **23 remain** (A: 1, B: 9, C: 10, D: 3):

**A. Label direction/colour only** — `f_vf_chroma`, `f_vf_potential`, `f_vf_split` (patch says `vecfield in`), `f_chladni` (label colour) → **DONE 2026-09-24** (see T019). Still open: `f_vf_vortex` (patch says `vecfield out`, but its shipped patch has no `r draw` box where the builder adds one — decide which is right first).

**B. Definition is behind the patch (9)** — `f_vf_flow` (**found 2026-09-24 when regeneration was attempted and reverted:** `spread` dial is bipolar −1…1 in the patch vs 0…1 in the definition, `angle` dial min differs, label height 21 vs 18, saved `restore` state; `signal_type` in the definition now says `vecfield out` to match the patch), `f_weave` (patch has `softness` + `shape` dials, route 9 vs 6 outlets, codebox differs), `f_vf_advect` (definition still `dt/decay/injection/mix_amt`; patch `gain/mix/separate`), `f_vf_warp` (`bypass_gate`, `strength` default), `f_lens` (tiltshift removed), `f_vf_fieldmap` (codebox, hints, **panel resized 100×80 → 150×88**), `f_vf_repulse` (codebox), `f_vf_vorticity` (extra outlet; unverified module), `f_vf_vortex_multi` (hand-added `nodes` + `bpatcher` UI, no `r draw`). Each needs its definition synced; several are on the never-regenerate list on purpose. **Lesson:** dial-range differences live in `saved_attribute_attributes` and look like save noise in a property tally — only a full leaf-level diff against `HEAD` after regenerating (`scratch/verify_regen_full.py` (deleted 2026-10-06; in git history, `git log --diff-filter=D -- scratch/verify_regen_full.py`)) is trustworthy; do that before keeping any regen.

**C. Predate the builder / hand-built (10)** — `f_channel_grader`, `f_droste`, `f_grain`, `f_hue_processor`, `f_luma_processor`, `f_mobius`, `f_tone_curve` (the oldest: bypass via `route bypass …` message, `jsui bypass`, outlet named `texture`, pix declared `@name x @drawto vsynth`, some params `live.numbox` where the definition has `live.dial`, shortened labels, `f_droste` has an extra `time_s` inlet; **7–27 presentation boxes sit at different `presentation_rect`s, so a regen would reflow the UI**), plus `f_masonry` (108 vs 71 boxes, hand-built mod matrix), `f_sirds` (pix node texts differ on all 13 stages, 62 vs 28 lines), `f_texrouter` (definition is a 19-box stub of a 109-box hand-built routing matrix). Definitions are after-the-fact transcriptions; a regen would rewrite them.

**D. Don't build through `build_patcher.py` (3)** — `f_util_profile`, `f_vf_fluid`, `f_vf_seeds` (own scripts).

**Noise, not drift:** many property differences on matched boxes (`attrui.style`/`parameter_enable`, `autopattr` inlet/outlet counts, saved `restore`/`save` state, `live.dial` saved attributes) are Max re-save normalization. They regenerate away harmlessly — except `autopattr`'s saved `restore` values (stored parameter values would reset to `parameter_initial`).

## Phase 0: Decision gates

- [x] T001 Defaults confirmed by Matt 2026-09-24 ("your defaults are all sensible"): gen subpatchers untouched; `raw_boxes` moved as one block to an overflow area. **Deviation:** zone-label comments were *not* added in v1 — they'd add new boxes with new ids to every regenerated patcher, and the header-row param labels already orient the lane. Revisit only if the first look in Max wants them.
- [x] T002 Constants (in `build/layout.py`): attrui compact 68 px, column pitch 72 px (Matt: compact is fine), main inlet y=20, routepass y=70, instate/state-prepend y=120, param label header y=180, route y=204 (width n*72+7), control y=250, attrui y=310, pix y=380 (+50 per layer), outlets 50 below deepest pix, modulation band x=260 pitch 170, service area right of everything. Values are first guesses; expect to tune after T014.
- [x] T003 **DECIDED (Matt): separate `{id: (role, idx)}` dict** (`assign_roles()` in `build_patcher.py`), so `box()` output stays byte-identical. Roles never enter the `.maxpat`.
- [x] T004 In-scope set enumerated — see "Drift survey" above. Result: six regenerable today; the rest need definition sync or a different route (T018).

## Phase 1: Offline — no Max

- [x] T005 `layout.audit()` (overlaps, shared origins, upward wires) lives in `build/layout.py`; invariants asserted in `tests/test_layout.py`. `scratch/edit_layout_audit.py` (deleted 2026-10-06; in git history, `git log --diff-filter=D -- scratch/edit_layout_audit.py`) remains as the standalone reporter for shipped files.
- [x] T006 `tests/test_layout.py` — 9/9. Synthetic cases with mutation checks (overlap, shared origin, upward wire, `presentation_rect` change, line/order change all detected) plus whole-corpus tests. Also mutation-checked against the real corpus: `PITCH=20` → 864 overlaps caught; `Y_PRE` above the control → upward wires caught.
- [x] T007 `build/layout.py` written (constants block, zone placement, param-lane columns, route width = n×pitch, panel moved to the service area, overflow block).
- [x] T008 Baseline (overlapping pairs, shipped patchers before): `f_droste` 13, `f_vf_fluid` 33, `f_stipple` 38, `f_vf_glow` 39, `f_vf_prism` 62, `f_masonry` 150. After: 0 for every definition that builds through `build_patcher.py` (30 checked; `f_lens`'s raw-box-only findings are reported, not asserted).

## Phase 2: Wire into the build

- [x] T009 Roles assigned by `assign_roles()` (inlet/outlets, routepass, route, pix nodes, per-param ctl/pre/label + range-tier group, header toggle as the column after the params, mod inlets, service objects).
- [x] T010 `layout_edit_view` called at the end of `build()`, gated by `defn.get("edit_layout", True)`; `assert_unchanged()` inside `build()` raises if anything but `patching_rect` moved. `build(defn, debug=...)` hands the roles to tests.
- [x] T011 Corpus covers: single pix, `pix_chain`, source/dual/processor archetypes, `mod_inlets` ± `driving_inlet`, `range_tiers`, `header_toggle`, `panel_toggle`, multi-outlet, `raw_boxes` (`f_lens`). All 30 buildable definitions clean. Not covered by a real-file eyeball yet: see T014.

## Phase 3: Regenerate and verify in-scope modules

- [x] T012 Regenerated `f_caustic`, `f_stipple`, `f_vf_glow`, `f_vf_prism`, `f_vf_streak`, `f_ngon` with `build/py.sh build/build_patcher.py src/<m>/definition.py`. `scratch/verify_regen.py` (deleted 2026-10-06; in git history, `git log --diff-filter=D -- scratch/verify_regen.py`) checks each against `HEAD`: valid JSON; identical except `patching_rect` and label `varname`s; 0 overlaps, 0 shared origins. `package/javascript/` untouched. `tools/rebuild_modules_menu.py` / `append_nabla_menu.py` not needed (menu content unchanged).
- [x] T013 Overlap count 0 and JSON valid for all six.
- [ ] T014 **Matt, by eye in Max** (close and reopen each patch — Max doesn't reload changed files). Suggested set: `f_stipple` (10 params, widest lane), `f_vf_prism` (7 params, longest names, two extra outlets), `f_vf_glow`, `f_ngon`. Verdict: readable edit view, wires tidy, presentation view unchanged. Constants in `build/layout.py` are guesses; adjust after looking.

## Phase 4: Docs

- [x] T015 `build/spec.md`: "Edit-View Layout" section now describes the implemented pass and constants.
- [x] T016 `skills/vsynth-bpatcher/SKILL.md`: new "Edit-View Layout (generated modules)" section incl. "manual edit-view tweaks are lost on regeneration" and the drift caveat.
- [ ] T017 Decide whether `build_fluid.py` (and other per-module builders that import shared chrome) should call `layout.layout_edit_view` too. `f_vf_fluid` is script-generated and not yet hand-edited; needs its own `assign_roles`-style dict.
- [ ] T018 **Decision for Matt (2026-09-24: do A, leave B and C alone — A done, see T019):** how do the 23 remaining modules get a clean edit view? By group: **A (1: `f_vf_vortex`)** — blocked on the `r draw` question. **B (9)** — sync each definition from its patch (codebox, params, panel size), then regenerate; or rects-only transfer by box id where ids still match; several are never-regenerate on purpose. **C (10)** — regeneration is unsuitable (UI reflows, structure differs) and box ids don't correspond, so a by-id rects transfer doesn't work either; the only route is a retrofit that infers roles from the shipped patch's wiring — a different, larger tool than this pass. **D (3)** — own scripts (T017). Or (c) leave them. **Matt's current call: leave B and C.** Options (b) and the C-route widen the earlier "generated modules only" scope, so they need an explicit yes.
- [x] T019 **Group A regenerated (2026-09-24, Matt: "do A now and leave B and C alone").** Builder: `signal_type_box` now keys the colour on the first word, so `"vecfield in"` / `"vecfield out"` keep the vecfield colour (previously an exact-string match, which is why `f_chladni`'s `"vecfield out"` fell back to grey). Definitions: `signal_type` → `"vecfield in"` for `f_vf_chroma`, `f_vf_potential`, `f_vf_split`; `"vecfield out"` for `f_vf_flow` (kept although flow's regen was reverted — it matches the patch). Regenerated + verified with a full leaf-level diff against `HEAD` (`scratch/verify_regen_full.py` (deleted 2026-10-06; in git history, `git log --diff-filter=D -- scratch/verify_regen_full.py`)): `f_vf_chroma` (8 label varnames only), `f_vf_potential` (3), `f_vf_split` (0 differences besides `patching_rect`), `f_chladni` (10). Valid JSON, 0 overlaps, `package/javascript/` untouched. **`f_vf_flow` was regenerated, failed the diff (73 leaf differences incl. the bipolar `spread` range) and was restored from `HEAD`.** `f_vf_vortex` deliberately not regenerated (`r draw`).
