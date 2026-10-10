# Tasks: f_grain

Reopened 2026-10-09 by a maintenance pass (`.specify/maintenance/SKILL.md`);
`f_grain` had graduated to `docs/` with no `.specify/` folder of its own, so
this one was created fresh rather than found in `stable/`/`paused/`. Task
IDs are per directory: `f_grain/T001`.

---

- **T001 — perf: baseline cost + bypass-guard check.** No cost measurement
  exists for `f_grain` (no `bench_grain.py` / spike script). Add one (same
  shape as `tests/spike_caustic_res_cost.py`), get a frame-cost baseline at
  HD and 4K, and check whether a shader-side guard on the heavy loop under
  `bypass_gate` recovers any of the cost that native bypass used to save —
  the same open question HANDOFF already raised for `f_caustic` and the
  other five Param-bypass modules, just not yet asked of `f_grain`
  specifically.

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
