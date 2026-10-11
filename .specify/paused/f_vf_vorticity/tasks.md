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
