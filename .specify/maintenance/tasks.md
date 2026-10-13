# Tasks: maintenance (the workstream itself)

This tracks the upkeep protocol's own backlog — which module to run next,
and cross-cutting observations that surfaced across more than one module's
audit. It is NOT where individual findings get filed; those always live in
the audited module's own `.specify/<name>/tasks.md` (see `SKILL.md`
"Output and stopping point"). This file is closer to `build_cleanup`'s
`tasks.md` — one workstream's own record — than to a module's.

---

## Queue

Full prioritization across all 25 remaining modules: `plan.md` (Tiers
A-G). **All tiers executed 2026-10-12** — the whole remaining set is
now audited (34 modules in status.json: the 2026-10-09 nine plus all
25 from this pass). The plan's snapshot ordering is spent; if a new
pass is wanted, re-derive per SKILL.md's live selection algorithm (or
re-snapshot plan.md if the shipped-module list has changed).

Standing priority from the 2026-10-12 pass, for whoever picks up the
filed tasks:
- Highest-value single session: the **glow + prism + streak + chladni
  profiling session** (all four flagged the same shape: unmeasured
  cost, no bypass guard on unrolled/looping codeboxes — one bench
  afternoon covers T036-class items across four modules).
- `f_caustic` stays out of the queue entirely while sheets mode is
  active (`HANDOFF.md`) — re-add once that settles.

## Cross-cutting observations (not yet actioned anywhere)

Patterns that showed up across more than one module's audit — each is a
real decision, just not one tied to a single module's tasks.md:

- **Never-regenerate list has stale entries.** `f_grain` and `f_vf_warp`
  both turned up in the state "definition.py reproduces the patch
  exactly, but still listed as never-regenerate on policy" — the same
  state `f_vf_advect` was in before it formally came off the list
  (2026-10-05). Worth a single pass over the whole list rather than
  re-discovering this module by module.
- **`gain`/`mix` split left two modules behind.** `f_grain`'s `amount`
  and `f_vf_warp`'s `strength` are both pre-rollout blend params doing
  the same job the six rolled-out modules split in 2026-07-17. Worth
  deciding once, generally, rather than per module (see each module's own
  tasks.md for the specific decision-gate task).
- **`f_texrouter` — confirmed not in use (Matt, 2026-10-09).** Not
  audited on that basis. Real open question this raises: it's still in
  `README.md`'s Patches table and `f_modules` menu with the largest drift
  entry in `drift_baseline.json` (96 patch-only boxes) — worth an actual
  decision (deprecate/remove vs. quietly let it keep drifting) rather
  than leaving it in limbo.
- **bench_modules.py's "not yet seen green live" header comment is
  dead** (found across Tiers A–B; the 2026-10-09 f_grain audit saw it
  first): the 2026-10-06 live run was 33/33, 0 unexpected issues
  (plan.md), so the derived BYPASS_EXPECT entries HAVE been seen green.
  One-line comment fix in tests/bench_modules.py — folded into
  f_vf_prism T001 rather than filed per-module.
- **Dead preset keys in package/examples/** (Tier A finding): demo
  files preset pre-rename param names (`f_vf_warp::strength`,
  `f_vf_seeds::strength`) that silently no-op on shipped modules.
  Filed as f_vf_streak T055 as a sweep; if the sweep finds more, the
  fix is mechanical (grep + rename to `gain`).
- **"No tier-1 mirror, no recorded skip decision" is the single most
  common audit result** (12+ modules): modules built before
  Verification Tiers have neither coverage nor a written deliberate
  skip. Not worth filing per-module everywhere — the interesting
  subset is where a mirror is cheap and meaningful (vortex family:
  promotable NumPy mirror already exists in spike_lie_bracket.py;
  chladni: closed-form modal field; optical_flow stages c/e). Those
  got tasks. The rest are candidates for a single written triviality/
  skip-decision pass, same shape as the never-regenerate list cleanup
  above.
