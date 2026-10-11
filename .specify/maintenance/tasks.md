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
A-G). This section is just the immediately-next slice of it, so a session
in a hurry doesn't have to read the whole plan to know what's next.
Standing priority, overrides the generically-computed tier order in
`SKILL.md` while it's recorded here. 9 modules audited so far (2026-10-09):
`f_grain`, `f_vf_advect`, `f_masonry`, `f_sirds`, `f_vf_vorticity`,
`f_vf_warp`, `f_vf_seeds`, `f_vf_fieldmap`, `f_vf_repulse`.

- [ ] Next (`plan.md` Tier A): `f_vf_glow`, `f_vf_prism`, `f_vf_streak`,
  `f_vf_chroma` — check why `f_vf_chroma` is in `paused/` first (flagged
  in `plan.md`, not yet understood).
- [ ] Then Tier B: `f_chladni`, `f_stipple`, `f_vf_split` — same
  Param-bypass oversight risk `f_masonry` turned up.
- [ ] `f_caustic` stays out of the queue entirely while sheets mode is
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
