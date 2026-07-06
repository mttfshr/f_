# Tasks: f_util_matrix

_Created: 2026-06-02_
_Spec_: `.specify/f_util_matrix/spec.md`
_Plan_: `.specify/f_util_matrix/plan.md`

---

## Phase 1 — Discovery

- [x] D001 Investigate Max `pattr` remote autopattr enumeration — RESOLVED
  - Top-level `pattrstorage @greedy 1` + `dump` enumerates consumer params
  - Output format: `bpatcherScriptingName::paramName value`, ends with `dump done`
  - Consumer needs only `autopattr` + named `pattr` objects (no pattrstorage)
  - Matrix filters dump output by consumer scripting name prefix
  - No loadbang param report needed from consumer
  - ADR-8 added to plan. Scratch: `d001_pattr_discovery.maxpat`

- [x] D002 Design consumer contract abstraction — RESOLVED
  - Form: JS file (`f_util_mod_handler.js`) in `code/`
  - Inlet 0: mod assignments from matrix `<param> <source_idx> <amount>`
  - Inlet 1: base values from dials via prepend: `<param> <value>`
  - Stores amount dict keyed by param name; source_idx ignored (amount is scalar)
  - Outlet 0: `param foo_mod_amt <amount>` and `param foo <base>` to pix
  - Codebox convention: `Param foo` + `Param foo_mod_amt` + `float foo_eff = foo + foo_mod_amt`
  - `clear` message zeros all mod params; `dump` posts state to console

- [x] D003 Read core Vsynth modules — texture inlet convention — RESOLVED
  - Consistent across all WFG variants and shape genjit files
  - `in 2` → `* fm`, `in 3` → `* pm`: texture value multiplied by param scalar
  - Convention: `effective = param * texture_inlet_value`
  - f_util_router implication: amount scaling belongs in the consumer (post-receive),
    not in the router. Router passes texture through; consumer multiplies by amount.

- [x] D004 Validate message format — RESOLVED
  - `route` routes on first element of a message; `mortar 0 0.6` → `route mortar` matches,
    passes `0 0.6` as a two-element list. Works correctly in Max.
  - `mod <param> <source_idx> <amount>` alternative unnecessary — matrix outlet is a
    dedicated connection, not shared with other control messages. Plain format confirmed.
  - ADR-4 unchanged: `<param> <source_idx> <amount>` is the locked message format.

**Checkpoint**: All four discovery items resolved. Plan ADRs updated. Ready for Phase 2.

---

## Phase 2 — jsui design

- [x] T001 Sketch matrix grid layout — param rows × source columns (transposed from initial design; scales to 10+ params vertically)
- [x] T002 Implement jsui: draw grid, param labels left, source labels top, amount bars per cell — `code/f_util_matrix_grid.js`
- [x] T003 Implement cell interaction: drag to set amount (onclick/ondrag), double-click to clear
- [x] T004 No-aggregate enforcement: dragging a cell non-zero auto-clears any other source routed to same param; messages emitted for both
- [x] T005 Implement bypass state display (dark overlay, drag disabled)
- [x] T006 Verify jsui in scratch patch: `d002_matrix_grid_test.maxpat` — params message rebuilds rows, outlet emits correct format

**Checkpoint**: jsui functional in scratch patch. ✓

---

## Phase 3 — Consumer contract abstraction

- [x] T007 Verify f_util_mod_handler.js in scratch patch (d003_mod_handler_test.maxpat)
  - mortar 0 0.6 → param mortar_mod_amt 0.6 ✓
  - flonum → prepend mortar → param mortar 0.xx ✓
  - clear zeros all mod params ✓
- [x] T008 Verify: receives <param> <source_idx> <amount>, stores correctly ✓
- [x] T009 Verify: exposed amounts readable by codebox (print confirmed message format) ✓
- [x] T010 Full flow: matrix grid + mod handler together (d003_dummy_consumer_test.maxpat) ✓

**Checkpoint**: Consumer abstraction working in isolation. ✓

---

## Phase 4 — f_util_matrix_2 build

- [x] T011 Write f_util_matrix_2.maxpat directly (build script not applicable — no codebox/pix)
- [x] T012 Wire: 2 texture inlets → 2 texture outlets (passthrough)
- [x] T013 Wire: control inlet → route bypass params → jsui
- [x] T014 Wire: jsui → outlet 2 (mod assignments); bypass handled inside jsui ondrag
- [x] T015 Wire: bypass → prepend bypass → jsui (grey overlay + drag suppression)
- [x] T016 Inlet order: 0=control, 1=source A, 2=source B; outlet 2=mod assignments
- [x] T017 Open in Max, confirm no load errors
- [x] T018 Send params mortar drift on inlet 0 → grid rebuilds correctly
- [x] T019 Drag cell → correct mortar 0 0.xx message on outlet 2
- [x] T020 bypass 1 → no output on drag; bypass 0 → messages flow again
- Note: gate object removed — jsui already suppresses output internally when bypassed
- Note: prepend params/bypass needed to restore selector words stripped by route
- Scratch: d004_matrix_2_test.maxpat

**Checkpoint**: f_util_matrix_2.maxpat functional standalone. ✓

---

## Phase 5 — f_masonry integration

- [ ] T021 Revise f_masonry codebox: replace chooser/_eff approach with
  contract-based approach (amounts received as messages, stored, applied)
- [ ] T022 Add consumer abstraction to f_masonry
- [ ] T023 Add loadbang param report to f_masonry
- [ ] T024 Wire: f_util_profile → f_util_matrix_2 inlets
- [ ] T025 Wire: f_util_matrix_2 texture outlets → f_masonry mod inlets
- [ ] T026 Wire: f_util_matrix_2 message outlet → f_masonry control inlet
- [ ] T027 Verify: matrix UI shows masonry params as columns
- [ ] T028 Verify: setting cell amount produces correct per-course modulation
- [ ] T029 Verify: routing source A to different params works independently
- [ ] T030 Verify: bypass zeros modulation, base params unchanged

**Checkpoint**: Full signal chain working. f_masonry modulated via matrix. ✓

---

## Phase 6 — f_util_router

Blocked on D003. Spec to be written after discovery complete.

- [ ] T031 Write f_util_router spec (after D003)
- [ ] T032 Build f_util_router (scope TBD from discovery)

---

## Deferred

- 4-source variant (f_util_matrix_4) — when concrete use case arises
- Per-cell slew/smoothing on amount changes
- Preset recall for matrix state
- Multiple consumer broadcast
- f_util_router full build
