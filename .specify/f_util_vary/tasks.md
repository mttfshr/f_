# Tasks: f_util_vary

_Spec_: `.specify/f_util_vary/spec.md`. Record who observed what, and when.

## Phase 1: engine and patcher
- [x] T001 Engine rework from the scratch prototype: rows keyed by outlet + param; 4 outlets; passthrough to every outlet; per-row wobble; `param` range defaults. Done 2026-11-12 by Claude (offline only): `package/javascript/f_util_vary.js`; check `tests/modules/f_util_vary/vary_engine_check.js` via `test_vary_engine.py`, passes (`tests/logs/20261112-220305-offline.log`). Not run in Max (T003). The table file loader is dropped (embedded `text` instead, T002); everything sits in one closure so a base named like a function cannot call it.
- [x] T002 Patcher `package/patchers/f_util_vary.maxpat`, built by `src/f_util_vary/build_vary_patcher.py` (hand-built utility; `out_of_scope` in `tests/build/drift_baseline.json`). Built 2026-11-12 by Claude, NOT opened in Max (T003). Deviation from the plan, Claude's call: the table is ONE message box (comma-separated lines; click to apply, edit in an unlocked patch), not `text @embed` (its embed format cannot be hand-authored or checked offline); switch later if wanted. Has: inlet 0 bases, inlet 1 settings, 4 outlets, roll, seed, amount / chance / wobble / slew dials, 4 knob dials (`knob` lines, engine added: `knob <n> row <outlet> <param> <field>` or `knob <n> group <name>`, value `k <n> <0..1>`), a 16-bar multislider of row positions (js outlet 4) and a label comment (outlet 5), a `list`-led line accepted. Engine check 14 sections pass (`tests/logs/20261112-220659-offline.log`); `test_drift`, `test_launch`, `test_generate_menu` pass; `test_layout` fails on `f_vf_erode` (1 overlap), also on a clean tree, not from this change.
- [ ] T003 Live check with the single-effect tables (Matt): passthrough with an empty table, per-outlet variation, per-row wobble, knobs.

## Phase 2: documentation and registration
- [ ] T020 Reference doc `docs/f-reference/f_util_vary.md`; helpfile (`f-helpfile` skill); README row (110 chars, then `build/py.sh build/generate_launch.py`); menu entry in `src/f_modules/menu.py` (`G-menu`). Partly done 2026-11-12 (Claude): README row (draft status) and menu entry `Vary` under Routing / Mod (provisional, `G-menu`), launcher and menu regenerated; reference doc and helpfile still to do.

## Phase 3: preflight
- [ ] T030 Module preflight checklist (`module-preflight` skill).

## Open (decide before T002)
- Per-destination bases; non-float params; the menu category.
