# HANDOFF

_Updated 2026-10-09._

## f_grain: T001-T003 done, one thing left for Matt

All three open tasks in `.specify/f_grain/tasks.md` are done:

- **T001 (perf)**: no measurable shader-side cost to recover from a `bypass_gate` guard — same
  outcome as `f_caustic`'s T046 spike, both below the bench's measurable floor. No action.
- **T002 (convention)**: `softness` dial range tightened `0.0-5.0` -> `0.0-1.0` (the codebox never
  used the rest of the range). Shipped patch and `definition.py` both updated, surgically.
- **T003 (convention + regression)**: `amount` renamed to `gain`, new `mix_pct` param added
  (0-100%, default 100 — look unchanged on upgrade), matching the library-wide gain/mix convention.
  Along the way: the module's "never regenerate" header comment was stale — `drift.py` already
  showed it reproducing exactly — so it's off the never-regenerate list; `definition.py` is the
  generator again.

  Hit and fixed a real regression: adding `mix_pct` broke `field`/`sv_seed`'s wiring
  (`unrouted: ["sv_seed"]`) no matter where in the params list it went. Root cause in
  `build_patcher.py`: the route object's token order is `ui_params + header_toggles +
  raw_ui_params`, grouped by **type**, not list position — so any new UI-generating param always
  lands before the `raw_ui`-type ones, shifting their outlet index on the shared `route` object.
  `raw_lines` are spliced in completely verbatim (no renumbering, by design), so the three
  hand-captured wires in `raw_ui.json` sourced from the main route object were still pointing at
  the old indices. Fixed by editing those three `raw_lines` entries directly in
  `src/f_grain/raw_ui.json` (13->14, 14->15, 15->16) — not a `build_patcher.py` change; this is
  inherent to the raw_ui mechanism, not a generator bug. **Documented as a standing hazard** in
  `docs/f-reference/f_grain.md`'s Loose Threads: the next param added to f_grain (or any other
  raw_ui module) needs the same manual re-index, and `test_module_contracts.py`'s `unrouted`/
  `route_map` output is what catches it.

  Verified clean: `drift.py -v f_grain` reproduces exactly; `test_module_contracts.py` (8/8),
  `test_drift.py` (16/16), `test_layout.py` (12/12) all pass.

- Full findings: `.specify/f_grain/tasks.md`
- Reference doc: `docs/f-reference/f_grain.md`

## Left for Matt

- **Eyeball `f_grain` live in Max** (Tier 3) — confirm `mix_pct` crossfades as expected and nothing
  regressed visually. Offline tests cover wiring/drift, not appearance.
- Everything else from the previous handoff (f_caustic demo-patch chain-cost check, the
  `jit-gen-codebox` skill re-upload, soft-mode `scale`>1.0) is presumably still wherever it was —
  not touched this session.
