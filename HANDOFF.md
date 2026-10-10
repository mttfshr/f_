# HANDOFF

_Updated 2026-10-10._

## f_grain: T001-T003 done, including the live check

All three tasks in `.specify/f_grain/tasks.md` are done and confirmed:

- **T001 (perf)**: no measurable shader-side cost to recover from a `bypass_gate` guard — same
  outcome as `f_caustic`'s T046 spike, both below the bench's measurable floor. No action.
- **T002 (convention)**: `softness` dial range tightened `0.0-5.0` -> `0.0-1.0` (the codebox never
  used the rest of the range). Shipped patch and `definition.py` both updated, surgically.
- **T003 (convention + regression)**: `amount` renamed to `gain`, new `mix_pct` param added
  (0-100%, default 100 — look unchanged on upgrade), matching the library-wide gain/mix convention.
  Took f_grain off the never-regenerate list (`drift.py` already showed it reproducing exactly, so
  `definition.py` is the generator again).

  Hit and fixed a real regression along the way: adding `mix_pct` broke `field`/`sv_seed`'s wiring
  no matter where in the params list it went. Root cause in `build_patcher.py`: the route object's
  token order is `ui_params + header_toggles + raw_ui_params`, grouped by **type**, not list
  position — so any new UI-generating param always lands before the `raw_ui`-type ones, shifting
  their outlet index on the shared `route` object. `raw_lines` are spliced in verbatim with no
  renumbering, so the three hand-captured wires in `raw_ui.json` sourced from the main route object
  were still pointing at stale indices (13->14, 14->15, 15->16). Fixed with a surgical edit to
  those three `raw_lines` entries — not a `build_patcher.py` change; this is inherent to the
  raw_ui mechanism, not a generator bug. Documented as a standing hazard in
  `docs/f-reference/f_grain.md` for the next param this module gets.

  **Live check (2026-10-10): done.** Matt opened it in Max, repositioned `mix_pct`'s widget and
  nudged `ch_diverge`'s dial/panel size. Captured that presentation state back into
  `definition.py` via `build/capture.py` so a rebuild reproduces it — `drift.py -v f_grain` is
  clean again.

  Verified: `drift.py -v f_grain` reproduces exactly; `test_module_contracts.py` (8/8),
  `test_drift.py` (16/16), `test_layout.py` (12/12) all pass.

- Full findings: `.specify/f_grain/tasks.md`
- Reference doc: `docs/f-reference/f_grain.md`
- Commits: `e2ea2db` (T002), `8c0f9ae` (T001), `4dad7e9` (T003), plus tonight's capture (uncommitted)

## Left for Matt

- Nothing outstanding on f_grain. Per repo convention, since all three tasks are done and
  confirmed, `.specify/f_grain/` could move to `.specify/stable/f_grain/` (tasks.md deleted,
  the usual signal for "no open work") — didn't do this unprompted since it's a structural call,
  not something you asked for this turn. Say the word if you want it done.
- Everything else from the previous handoff (f_caustic demo-patch chain-cost check, the
  `jit-gen-codebox` skill re-upload, soft-mode `scale`>1.0) is presumably still wherever it was —
  not touched this session.
