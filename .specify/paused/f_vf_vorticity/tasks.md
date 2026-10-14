# Tasks: f_vf_vorticity

No `tasks.md` existed for this module before this maintenance pass
(2026-10-09, `.specify/maintenance/SKILL.md`) — only `spec.md`/`plan.md`.
Staying in `paused/`: a maintenance finding isn't itself a decision to
resume. These tasks are what "resuming" would need to address first,
not a resumption.

---

- **T001 — bench, this is the real ask here.** `plan.md`'s root Paused/
  blocked section already says this module is "genuinely UNVERIFIED...
  an earlier session's confidence in this module did not survive
  re-scrutiny," and the Test Infrastructure workstream separately names
  `f_vf_vorticity` as a candidate once the math-first bench existed. That
  bench now exists and this module has never been run through it — no
  tier 1 (NumPy mirror of the curl/vorticity-gradient math — the exact
  kind of thing tier 1 is for, and the exact kind of claim that didn't
  survive re-scrutiny last time), no tier 2, nothing in `tests/` at all
  beyond an incidental name match in a menu-generator test fixture. This
  task doesn't add new information — it formalizes an intention that was
  already stated twice but never turned into a task.

- **T002 — convention: bypass predates both current conventions.** The
  codebox declares a bare `Param bypass(0.0)` and mixes
  `out1 = mix(result, sample(in1, norm), bypass)` directly — not the
  native `@bypass` toggle (which would skip the shader and never reach
  this logic) and not the `bypass_gate` Param convention the 2026-10-06
  rollout established (wrong Param name, no `bypass_mode` key in
  `definition.py` at all). Built 2026-07-06, before either convention was
  settled; whichever path this module takes when resumed, reconcile the
  bypass mechanism with whatever's current then, since neither existing
  pattern matches exactly.

- **T003 — DONE 2026-10-13. `confinement` range_tiers corrected from a
  live Max check, not assumed.** Matt opened the regenerated patcher in
  Max (the 2026-10-12 build_cleanup pass) and reports it's "working
  great" — the first real, live engagement with this module since it was
  marked UNVERIFIED. One concrete finding came out of it: the provisional
  `range_tiers: [0.1, 1.0, 10.0]` (flagged in the definition.py comment
  as "pending Phase 3 chain testing") had a third tier (10.0) that
  exceeded the param's own declared `max: 1.0` — never reachable
  cleanly. Changed to `[0.1, 1.0]` — fine (0-0.1) and coarse (0-1), the
  two ranges Matt actually wants. `definition.py` edited,
  `build/build_patcher.py src/f_vf_vorticity/definition.py` regenerated
  the shipped patcher, `build/drift.py -v f_vf_vorticity` confirms clean
  (1 of 1 reproduces exactly). **Confirmed in Max 2026-10-13 (Matt): the
  two-tier range select works as expected** (an earlier "looks disabled"
  report turned out to be a stale already-open window, not a real bug).
  This finding is closed.

  **Bigger open question this raises, for Matt, not decided here:** T001
  above (and `plan.md`'s root Paused/blocked entry) say this module is
  "genuinely UNVERIFIED... needs independent re-verification from
  scratch." Does today's live Max check count as that re-verification, or
  does the bar still require the NumPy-mirror math-tier bench T001 asks
  for before this comes off `paused/`? T002's bypass-convention mismatch
  is also still unresolved either way.
