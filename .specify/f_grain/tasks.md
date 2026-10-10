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

- **T003 — convention decision gate: does `amount` need the gain/mix split?**
  The 2026-07-17 canonical-naming rollout (`gain`=unbounded intensity,
  `mix`=0-100% blend) touched six modules (`f_chladni`, `f_vf_advect`,
  `f_vf_prism`, `f_caustic`, `f_vf_glow`, `f_vf_streak`) but not `f_grain`,
  which still has a single `amount` (0-2) param doing blend-weight duty.
  Open question, not yet a clear bug: `f_grain` is a generator compositing
  its own field, not a layer-over-source effect in the same shape as the
  six rolled-out modules, so the split may genuinely not apply. Needs
  Matt's call before any change; if the answer is "doesn't apply," record
  that reasoning here so it doesn't get re-asked next audit.
