# Tasks: f_vf_repulse

No `tasks.md` existed before this maintenance pass (2026-10-09,
`.specify/maintenance/SKILL.md`) — only `spec.md`; this module never had a
plan/tasks pipeline completed (`spec.md`'s own status note: "audit and
build sign-off still open"). Folder moved back from `stable/` since it's
gaining real tasks. Full findings in `.specify/maintenance/status.json`.

---

- **T001 — convention, high priority: the reference doc's central claim
  about this module's bypass behavior is wrong, and resolves its own
  open question incorrectly.** `docs/f-reference/f_vf_repulse.md` states
  bypass "passes the *source texture* through, not a neutral vecfield,"
  cites the codebox as `mix(field, sample(in1,uv), bypass)`, and flags
  this as a deliberate divergence from the rest of the vecfield family
  "worth confirming... intentional." The actual shipped codebox in
  `definition.py` is `mix(vec(field_x, field_y, 0.5, 1.0), vec(0.5, 0.5,
  0.5, 1.0), bypass)` — bypass mixes to a **neutral field**, matching
  `f_vf_vortex`/`f_vf_vortex_multi` and the rest of the family. There is
  no divergence; the doc's own uncertainty was based on describing code
  that isn't what's shipping. Rewrite the Parameters row, the Signal
  Flow/Algorithm pseudocode, and the Notes section's open question (which
  this resolves — not "confirm intentional," but "doc was wrong, already
  matches convention").

- **T002 — bench: no contract coverage, and this exact gap is why T001
  went unnoticed.** No `BYPASS_EXPECT` entry in `tests/bench_modules.py`
  — a single automated check of "does out1 equal a neutral field under
  bypass" would have caught the doc/code mismatch in T001 immediately
  instead of it sitting undiscovered. No tier-1 mirror either (predates
  Verification Tiers); the 16-sample ring + 4-mode branch is more
  involved than most generators audited so far and would benefit from
  one, though it's a reasonable candidate for a deliberate, recorded
  skip instead if Matt judges the per-mode branching not worth mirroring.
- **T003 — perf: no cost measurement.** 16 ring samples × luma dot
  product per pixel, single-pass (no multi-stage chain, unlike
  `f_sirds`/`f_vf_seeds`) — moderate sample count but architecturally
  simple. Lower priority than `f_sirds`'s finding, but still an unmeasured
  cost on a module that's one of the more sample-heavy single-pass
  generators in the library.
