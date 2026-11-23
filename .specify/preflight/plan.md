# Preflight — Plan

_Drafted 2026-11-21 (Claude, offline). Orientation only; detail is in `spec.md` and `tasks.md`._

## Order of work and why

1. **Measure before building (Phase 0).** Three read-only questions decide the shape of the code: how many modules fail a generalised helpfile-fit check, what native bypass looks like in a definition, and whether the launch validator can be scoped to one module. No code is committed in this phase.
2. **Share the helpfile-fit logic (Phase 1a).** Move `content_extent` out of `test_generate_menu.py` so there is one implementation. The existing `tf_` test must behave exactly as before.
3. **The script and its exemptions (Phase 1b).** `build/preflight.py`, the exemption file, and `tests/build/test_preflight.py`. The exemption rules copy `test_drift.py`'s so they behave the same way.
4. **Part 2 split (Phase 2).** Rubric file, review procedure, owed-line output.
5. **Wire it in (Phase 3).** `build/spec.md` lifecycle, `CLAUDE.md` Claims line, skill body edit, then Matt's upload and stamp.
6. **Trial (Phase 4).** One clean stable module and one with a known exemption, to see whether the report tells the truth.

## Decisions this plan rests on

- ADR-1: Preflight orchestrates existing checks and adds only three. It does not replace `test_drift.py`, the contract suite or the launch and menu tests.
- ADR-2: No LLM call from any script. The reviewer is a Claude session step described in the skill.
- ADR-3: Exemptions are data with a reason and a gate, enforced by a shrink-only test, the same pattern as `drift_baseline.json`.
- ADR-4: One module per run, with no batch flag.

## Risks

- **Generalising helpfile fit may turn up many failures** among the 52 helpfiles. Mitigation: T001 counts first. If the number is large, enforce for new and promoted modules and baseline the rest on a shrink-only list (`G-helpfiles` already tracks 13 non-clean helpfiles, so the two may overlap).
- **The skill is mirrored on claude.ai and goes stale on upload.** Mitigation: T033 is Matt's step and the commit message names it.
- **Reviewer cost.** One subagent run per module closed. The skill says so and the run count is stated before it starts, in line with the evals README.
