# Tasks: f_sirds

Reopened 2026-10-09 by a maintenance pass (`.specify/maintenance/SKILL.md`);
no `.specify/f_sirds/` folder existed anywhere (root/`stable/`/`paused/`) —
this module graduated straight to `docs/` and was never revisited. Task IDs
are per directory: `f_sirds/T001`.

---

- **T001 — perf, high priority: no cost measurement, and a real unresolved
  risk at its actual scale.** `f_sirds` is a forward chain of **13**
  `jit.gl.pix` stages — by far the longest pass-chain in the library (most
  modules are 1, `f_vf_advect`/`f_vf_fluid` are 2-7). Its own reference doc
  says cook-order delay-freedom was "confirmed... at 4 stages; not
  independently re-verified at 13" — i.e. the actual shipped configuration
  has never been checked for the thing that would silently break it
  (a desync/lag artifact). No fps/cost number exists anywhere either. This
  is the single most under-verified performance-relevant module found in
  the maintenance pass so far; re-verify at the real 13-stage count and get
  a baseline cost at HD/4K.

- **T002 — bench: zero coverage of any kind.** `f_sirds` doesn't appear
  anywhere in `tests/` — not in `drift_baseline.json` (not even as an
  explicit `out_of_scope` entry, unlike `f_a_ripple`/`f_util_profile`/etc.,
  which are custom-builder modules that _are_ recorded with a reason), not
  in `bench_modules.py`'s `BYPASS_EXPECT` table, no tier-1 mirror. Its
  bypass mechanism also predates the `bypass_gate` Param convention
  entirely — each stage's own gate is multiplied by `(1.0 - bypass)`
  directly, the older `route_bypass` message pattern — so it wasn't
  swept up in the 2026-10-06 rollout and isn't a param-bypass module at
  all. Two separate things to do: add `f_sirds` to `drift_baseline.json`
  as an explicit `out_of_scope` entry with a reason (custom multi-stage
  builder, same as its siblings), and decide whether a contract/bypass
  bench entry is feasible given the 13-stage broadcast-gate design.

- **T003 — convention/docs: `docs/f-reference/f_sirds.md`'s Build section
  points at a path that doesn't exist.** It documents the source of truth
  as `.specify/f_sirds/definition.py`, `codebox_stage0.gen`,
  `codebox_stage_n.gen`, `build_sirds.py` — but those files are actually at
  `src/f_sirds/` (confirmed: that's where they live today). Following the
  doc's own "Run:" instruction (`python3 .specify/f_sirds/build_sirds.py`)
  would fail outright. Likely predates the `src/` vs `.specify/` layout
  split; fix the paths.
