# Tasks: f_grain

Reopened 2026-10-09 by a maintenance pass (`.specify/maintenance/SKILL.md`);
`f_grain` had graduated to `docs/` with no `.specify/` folder of its own, so
this one was created fresh rather than found in `stable/`/`paused/`. Task
IDs are per directory: `f_grain/T001`.

---

- [x] **T001 — perf: baseline cost + bypass-guard check. DONE 2026-10-09.**
  Added `tests/spike_grain_cost.py` (diagnostic, not a regression test —
  same shape as `tests/spike_caustic_res_cost.py`): measures the real
  `codebox_grain.gen` via `benchclient.measure` at HD/4K, and separately
  measures an in-memory guarded variant (early-out on `bypass_gate > 0.5`
  around the per-grain Voronoi search) to see what a shader-side guard
  would recover — the guarded variant is measurement-only, never written
  back to `src/f_grain/codebox_grain.gen`.

  **Result: same outcome as `f_caustic`'s T046 spike.** Even chained 128x
  at 4K, `measure()` never clears the bench's CPU-overhead/vsync floor
  (`gpu_bound` false at every chain tried: 8, 32, 128) — the reported
  numbers are upper bounds that keep shrinking as `floor / chain`, not real
  per-pass costs, so the module's true GPU cost is unmeasurably far below
  the floor at both HD and 4K. Baseline (`bypass_gate=0` vs `=1`) and the
  guarded variant read identical within noise at every chain/size tried
  (see log below) — there is no measurable amount of frame time for a
  shader-side `bypass_gate` guard to recover at these resolutions. Not
  "no effect," per the jit-gen-codebox skill's caution — just below what
  this bench can resolve; chain would need to go well past 128 (slow to
  compile) to say more, and isn't worth it given `f_caustic`'s identical
  finding already settled the cross-module question. No further action.

  Chain=128 log (HD / 4K, ms/pass upper bound, all flagged not-gpu_bound):
  baseline bypass=0/1: 0.048 / 0.048 (HD), 0.187 / 0.187 (4K); guarded
  bypass=0/1: 0.050 / 0.047 (HD), 0.188 / 0.188 (4K).

- [x] **T002 — convention: `softness` range is untuned. DONE 2026-10-09.**
  `live.dial` range was `0.0-5.0`; the codebox only uses `softness`
  meaningfully in `[0,1]` (`feather = mix(0.02, 0.5, softness)`), so
  roughly 80% of the dial's travel was a no-op. Fixed: tightened the
  shipped `.maxpat`'s dial (`obj-31`, `parameter_mmax` 5.0 -> 1.0, surgical
  `edit_block` since this module is on the never-regenerate list) and
  `src/f_grain/definition.py`'s recorded range to match; updated the Loose
  Thread note in `docs/f-reference/f_grain.md`. `tests/run.sh -q`:
  `test_drift.py` and `test_module_contracts.py` both still green (no
  existing patch/preset relied on the dead `[1,5]` range).

- [x] **T003 — convention: `amount` needed the gain/mix split. DONE 2026-10-09.**
  The 2026-07-17 canonical-naming rollout (`gain`=unbounded intensity,
  `mix`=0-100% blend) touched six modules but not `f_grain`, which still
  had a single `amount` (0-2) param doing blend-weight duty. Decision
  (Matt, 2026-10-09): the split does apply — `f_grain` composites a
  displaced-source + grain field, and `mix_pct` crossfades toward that
  full composite exactly like the six rolled-out modules, so `amount`
  was folded into the same convention rather than left as a special case.

  Along the way, discovered the header comment's "never regenerate this
  module" claim was stale: `build/drift.py -v f_grain` already showed it
  reproducing the shipped patch byte for byte, so f_grain's bespoke parts
  (persistence era-clock chain, second `route field sv_seed`, edge_mode
  umenu) are fully captured by `raw_ui.json` + the raw-box/raw-line
  mechanism, same as other once-hand-built modules absorbed into the
  generator. Took it off the never-regenerate list; `definition.py` is
  the generator again.

  Changes:
  - `amount` renamed to `gain` (same range 0-2, default 1.0) — no UI/range
    change, naming only.
  - New `mix_pct` param (float, 0-100%, default 100 — preserves the
    module's prior look unchanged on upgrade): crossfades toward
    `vec(mix(src.r, driven.r, mix_pct/100), ..., src.a)` where `driven`
    is the old unconditional composite. Internal codebox `Param` named
    `mix_pct`, not `mix`, to avoid the `mix()`-operator name collision
    (jit-gen-codebox skill).
  - `mix_pct` placed last in `definition.py`'s `params` list.

  **Regression found and fixed**: adding `mix_pct` broke the offline
  wiring check (`unrouted: ["sv_seed"]`, and a garbled `route_map`) even
  though `mix_pct` was placed last in the params list. Root cause, in
  `build/build_patcher.py`: the generated `route` object's token order is
  `route_params = ui_params + header_toggles + raw_ui_params` — grouped by
  **type**, not by position in `definition.py`'s list. `mix_pct` is
  `type: "float"`, so it always lands in the `ui_params` group, which the
  builder always places before `raw_ui_params` (`edge_mode`, `field`,
  `sv_seed`) regardless of list order. That shifted all three raw_ui
  params' outlet index on the shared `route` object by +1 (13->14,
  14->15, 15->16) — and `raw_lines` are spliced in completely verbatim
  (`lines.extend(defn.get("raw_lines", []))`, no renumbering, by design:
  "Author is responsible for..."), so the three hand-captured wires in
  `raw_ui.json` sourced from the main route object were still hardcoded
  to the old indices. Fixed by editing those three `raw_lines` entries in
  `src/f_grain/raw_ui.json` directly (surgical JSON edit, not a
  `build_patcher.py` code change — this is inherent to how raw_ui modules
  work, not a generator bug). **Any future param added to f_grain** (or
  any other raw_ui module) will need the same raw_lines re-index if it
  shifts the `ui_params` count — this is a standing hazard of the
  raw_ui/raw_lines mechanism worth remembering, not something this fix
  makes systematically safe.

  Verified clean after the fix: `build/drift.py -v f_grain` reproduces
  exactly; `tests/test_module_contracts.py` (8/8), `tests/test_drift.py`
  (16/16), `tests/test_layout.py` (12/12) all pass with no unrouted/
  bad_attr/undriven/unused findings.

  **Still open**: Matt to eyeball the module live in Max (Tier 3) to
  confirm `mix_pct` crossfades as expected and nothing else regressed
  visually — offline tests cover wiring/drift, not appearance.
