# Tasks: f_util_vary

_Spec_: `.specify/f_util_vary/spec.md`. Record who observed what, and when.

## Phase 1: engine and patcher
- [ ] T001 Engine rework from the scratch prototype: rows keyed by outlet + param; 4 outlets; passthrough to every outlet; per-row wobble; `param` range defaults. Offline Node check updated.
- [ ] T002 Patcher `f_util_vary.maxpat` (hand-built like `f_util_matrix_2`): inlet 0 bases, inlet 1 settings, embedded `text` table with an apply button, fixed strip, 4 knobs (`knob` lines), live bars. js in `package/javascript/`.
- [ ] T003 Live check with the single-effect tables (Matt): passthrough with an empty table, per-outlet variation, per-row wobble, knobs.

## Phase 2: documentation and registration
- [ ] T020 Reference doc `docs/f-reference/f_util_vary.md`; helpfile (`f-helpfile` skill); README row (110 chars, then `build/py.sh build/generate_launch.py`); menu entry in `src/f_modules/menu.py` (`G-menu`).

## Phase 3: preflight
- [ ] T030 Module preflight checklist (`module-preflight` skill).

## Open (decide before T002)
- Per-destination bases; non-float params; the menu category.
