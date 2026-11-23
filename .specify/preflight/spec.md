# Preflight — Spec

_Drafted 2026-11-21 (Claude, offline) from a read-only pass over the repo. Nothing here has been built or run. Decisions by Matt are in "Decided with Matt"; everything else is a PRELIMINARY gate (Claude's recommendation, listed in `tasks.md`)._

## Goal

`skills/module-preflight/SKILL.md` is the "is this one module actually finished" gate. Its Part 1 is prose naming eight checks across six or more separate commands, and its Part 2 mixes checks a fresh reader can do with checks only Matt can do (a live look in Max). Nothing wires it to the moment a module is closed. This feature makes Part 1 one command, splits Part 2 by who can do it, and ties both to the existing "reconcile before closing" rule.

Non-goals: library-wide release readiness (`.specify/packaging/`), batch sweeps (the skill's one-module-at-a-time rule stands), any script that calls an LLM (`CLAUDE.md` Helpfiles rule, and cost).

## Decided with Matt (2026-11-21, chat)

- A fresh-context reviewer takes the text-checkable half of Part 2.
- Spec first, in `.specify/`, before any code.

## What exists today (observed offline by Claude, 2026-11-21)

| Part 1 check | Today | Source |
|---|---|---|
| Drift | Per module: `drift.report(name)`, and `test_drift.py` `problems()` / `load_baseline()` apply the ratchet and the `out_of_scope` exemptions with reasons | `build/drift.py`, `tests/build/test_drift.py:55-100` |
| Contracts (undriven or unused params, default mismatch, port gaps) | Per module via `_check_module(path)`, with `NOT_APPLICABLE` and `KNOWN_ISSUES`. Not named in preflight Part 1 | `tests/contracts/test_module_contracts.py:116-150` |
| Menu and launcher registration | Library-wide. Listed exactly once; clickable iff helpfile and wired; README row parses; README group agrees with menu category | `tests/build/test_launch.py:82,94`, `test_generate_menu.py` |
| README row ≤ 110 chars | Enforced by `generate_launch.py` (`MAX_DESC = 110`), exercised by `test_launch.py:123` | `build/generate_launch.py:39` |
| Bypass convention | **No check on shipped modules.** Builder tests use synthetic definitions. Prose only in `G-bypass-native` | `tests/build/test_build_conventions.py` |
| `docs/f-reference/f_name.md` exists | **No check** | grep of `tests/` |
| Helpfile exists and is not cropped | **Checked for `tf_*` modules only**: `content_extent` plus an embed-size comparison. The skill's "no script does this yet" is therefore partly stale | `tests/build/test_generate_menu.py:270-292` |

The repo has 63 patchers and 52 helpfiles (`ls package/`, 2026-11-21), so "has a helpfile" is not universal.

## Design

### A. `build/preflight.py` (static by default)

`build/py.sh build/preflight.py f_name [--tests] [--json]`

- **One module per run.** More than one name is refused, which keeps the skill's one-module-at-a-time rule.
- **Orchestrator, not a rewrite.** It imports `drift.report` and `test_drift.problems`, `_check_module`, and the registration validators. It adds three new checks: bypass, doc exists, helpfile fit.
- **Helpfile fit is generalised, not reinvented.** `content_extent` and the embed comparison move from `test_generate_menu.py` into `build/helpfile_fit.py`. The existing `tf_` test imports it, and preflight applies it to every module that has a helpfile. The result for the whole library is measured before anything is enforced (task T001).
- **Report.** One line per check: `ok | RED | exempt | owed`, then the file or command it came from. Exit status 1 if any RED. This is the "cite the source" rule from `CLAUDE.md` applied to the report itself.
- **Cost rules.** Static checks only by default. `--tests` adds the module's own tests (`tests/modules/<name>/`) and the launch and menu tests. Bench steps print as `owed`, never run (`CLAUDE.md`: no bench runs without asking).
- **Bypass check.** A shipped module must use `bypass_gate`, not native `@bypass`, unless exempt.

### B. Exemptions as data

`tests/build/preflight_exemptions.json`, modelled on `drift_baseline.json`: per module and check, a non-empty `reason` and a `gate` ID. `tests/build/test_preflight.py` fails when an exemption has no reason, cites a gate ID that is not a row in `.specify/gates.md`, or is no longer needed (the module now passes). A list that only shrinks. First use: the native-bypass modules in `G-bypass-native` that Matt kept native (`f_tone_curve`, `f_vf_vortex`), plus the rest of that row until Matt decides.

### C. Part 2 split

- **2a, text checks, fresh-context reviewer.** A subagent that has not seen the session gets: the helpfile's comment boxes, `docs/f-reference/f_name.md`, `spec.md`, the module's README row and the status line in `tasks.md`. It checks the rubric in `skills/module-preflight/review-rubric.md` (R1 digest says what the module is for, not just what it is; R2 signal-flow comments describe its role in a chain; R3 status caveats agree across README, tasks and helpfile; R4 references are real, not a stub; R5 the doc matches the shipped state). **Report-only: it edits nothing and its verdict is advisory.** Matt decides. The result is recorded in `tasks.md` as "reviewed offline by Claude (fresh context), <date>", never as a live observation (`CLAUDE.md` Claims: records say who observed what).
- **2b, live looks, Matt.** Open the module and helpfile in Max, defaults give something sensible, nothing clipped. Preflight prints these as `owed` lines to paste into `plan.md` "Owed to Matt". It does not edit `plan.md`. "No console errors" is worded as "no new console lines beyond `P-console`", because three unexplained lines already appear on opening a helpfile (`gates.md` row `P-console`).

### D. Wiring

- The promotion block in `build/spec.md` (the "Full lifecycle" box, about line 803) gains a step before the move to `stable/`: Part 1 green, 2a reviewed, 2b logged as owed.
- `CLAUDE.md` Claims "Reconcile before closing" gains one line: closing a module cites its preflight report (command and date) as the source.
- `skills/module-preflight/SKILL.md` body is edited (Part 1 becomes "run this, expect green" plus a table of what each line means and how to fix it; Part 2 split as above; the two stale claims corrected). **The description is left unchanged**, so the trigger evals are not re-run. After the edit, Matt re-uploads and runs `skills/check.sh stamp` (it is on the ask list).

## Constraints

- No preflight run touches Max. Nothing in this feature runs a bench.
- No batch mode, now or later.
- A red is fixed or exempted with a reason and a gate. It is never skipped silently.

## Resolved in Phase 0 (2026-11-21, observed offline by Claude; detail in `tasks.md`)

- Bypass: `bypass_mode` defaults to native; 15 native modules, identical to the `G-bypass-native` row, so the bypass check starts with 15 exemptions citing it (T002).
- Launch and menu validators are library-wide; per-module use needs a small wrapper that filters their problem strings (T003; the filtering is inferred, not tried).
- Helpfile fit over all 63 patchers: 33 pass, 12 have no helpfile, 18 fail. The 10 "embed smaller than frame" failures are the high-signal ones. The 9 "content past frame" failures are unexplained and not yet enforceable (T001).

## Still not verified

- Which box extends past the frame in the nine content-past-frame modules, and whether it is intended.
- Whether `f_sirds`'s bypass is governed by its definition or by `build_sirds.py`.
