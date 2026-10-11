---
name: f-module-maintenance
description: One-module-at-a-time upkeep pass for shipped f_ modules — checks performance, bench coverage, and convention conformance against current tooling/skill state. Use when Matt asks for a maintenance/tech-debt/audit pass on an older module, or when Claude judges a session has slack and a pass hasn't run recently. Not a scheduled or automatic task — always proposed, never self-started without saying so.
---

# f_ Module Maintenance Protocol

## Why this exists

Skills and bench tooling keep accumulating findings (naming rules, bypass
conventions, new bench tiers, new gotchas) after modules have already
shipped. Nothing currently re-checks an old module against what's been
learned since it was built. This is a lightweight, repeatable pass that
does that — one module, three checks, record the findings, stop.

This is workflow scaffolding specific to this repo's process, not Max/
Vsynth domain knowledge, so it lives here rather than in `skills/` (which
is the symlinked, cross-project domain-knowledge library per
`README.md`'s Repo Structure section). It is not tracked by
`skills/check.sh` / `MANIFEST.md` and is not meant to be copied into
`claude-scaffold`.

## When to run

Conversational, not a slash command. Matt asks for it directly, or Claude
suggests it in one line when it seems like a good use of the session (new
session with no specific target yet, Matt mentions tech debt / old
modules / "has this been checked since X changed"). Never run without
saying so first — this is exploratory/diagnostic work, not something to
silently fold into an unrelated task.

## Status record

`.specify/maintenance/status.json` — flat map keyed by module name (as it
appears in `README.md`'s Patches table). A module absent from the file has
never been audited. Entry shape:

```json
{
  "f_vf_vorticity": {
    "last_audited": "2026-10-09",
    "perf":       {"status": "flagged", "note": "bypass no longer skips shader; unprofiled"},
    "bench":      {"status": "fail",    "note": "no tier1 or tier2 coverage; still genuinely unverified"},
    "convention": {"status": "pass",    "note": null},
    "tasks_filed": ["T001"]
  }
}
```

`status` per axis: `pass` / `flagged` (known issue, not yet actionable) /
`fail` (coverage genuinely missing). `tasks_filed` cross-references task
ids in the module's own tasks file — see "Output and stopping point"
below for exactly where that lives (it's never a shared file; tasks
always live with their module). This file is a record of *whether a
pass happened and what it found*, not a duplicate of
`tests/drift_baseline.json`, the README's ⚠ markers, or `ideas/` — read
those live each run rather than mirroring them here, so this file can't
go stale against them.

## Selecting the next module

Computed fresh each run from live sources, never hardcoded, highest risk
first:

1. On the never-regenerate / hand-built list (`plan.md` "Build system
   generalisation" section, currently: `f_masonry`, `f_sirds`,
   `f_vf_seeds`, `f_grain`, `f_vf_warp`, `f_vf_fieldmap`, `f_vf_repulse`)
   — drift here is invisible to `drift.py` by construction.
2. Listed in `tests/drift_baseline.json` — definition doesn't reproduce
   the shipped patch. Read the file live; don't copy its contents here.
3. Marked ⚠ in `README.md`'s Patches table (unfinished / unverified /
   undocumented).
4. Everything else — never-audited (absent from `status.json`) before
   anything with a `last_audited` date; oldest `last_audited` first
   within that.

Separately, check `.specify/maintenance/tasks.md` for a standing queue —
a deliberate, human-set priority (e.g. "these six have an open perf
question, do them before the generic ordering above") overrides the
computed tier whenever one is recorded there.

Within any tier, never-audited outranks already-audited. State which
module was picked and why in one line, then proceed — don't wait for
confirmation unless Matt redirects to a different module.

## The three checks

Each produces one of `pass` / `flagged` / `fail` plus a one-line note.
This is a check for what's already known or cheaply knowable, not a new
round of profiling or GPU bench runs — those are hard constraints
(`ways-of-working.md`: no bench runs without asking, run sparingly) and
stay that way here. Where a check's answer requires one, the pass ends
by asking whether to spend it, rather than spending it automatically.

### 1. Performance (primary axis)

- Does the module have an existing cost measurement (`bench_modules.py`,
  `bench_fluid.py`, or a module-specific bench file)? If none exists,
  that's a `fail`, not a `flagged` — note it as missing, don't run one.
- If `bypass_mode: "param"` (i.e. it's one of the 11 modules from the
  2026-09-23/10-06 bypass rollout: `f_caustic`, `f_chladni`, `f_grain`,
  `f_masonry`, `f_stipple`, `f_vf_advect`, `f_vf_chroma`, `f_vf_glow`,
  `f_vf_prism`, `f_vf_split`, `f_vf_streak`) — does the heavy shader loop
  still run full-cost while bypassed? This is the known open item from
  `plan.md`'s "Open: GPU cost" note; carry it forward as `flagged` unless
  someone has since added a guard.
- Does `ideas/` contain an open, unprofiled perf idea naming this module
  (e.g. `incremental_gaussian_taps.md` for glow/prism)? If so, `flagged`.

### 2. Bench coverage

- Tier 1 (NumPy mirror, `tests/test_*.py`) exists and last ran green?
  Running the single relevant tier-1 test now is fine (offline, fast,
  no GPU) — this isn't the kind of run the hard constraint is about.
- Tier 2 (GPU bench) exists for this module? Don't run it — that needs
  asking first. Note whether it exists and when it last reportedly ran.
- Contract test / `BYPASS_EXPECT` entry present in `tests/bench_modules.py`?
- `drift.py` clean for this module, or present in
  `tests/drift_baseline.json` with a documented reason (check the reason
  is still accurate, not just that an entry exists).

### 3. Convention

- Naming: `gain`/`mix`/`mix_pct` used correctly where the module has
  those controls (per `plan.md` item 2's canonical naming rollout).
- Bypass: every outlet passes through per the 2026-10-06 rule (signal
  kind's own input, or its neutral value) — or has a recorded, deliberate
  exception (e.g. `f_vf_advect`'s warm feedback).
- Panel density: any param that looks like it fails the "not every
  parameter earns a panel slot" bar (`skills/vsynth-bpatcher`)?
- Does `src/<name>/definition.py` actually reproduce the shipped patch,
  or is it correctly accounted for (never-regenerate list, or
  `drift_baseline.json` with a current reason)?

## Output and stopping point

- Always record all three axes in `status.json` for the audited module,
  pass or not, each with a one-line note. Update `last_audited`.
- File a task only when a finding is actionable and non-trivial — a real
  perf question worth a future profiling session, a genuine coverage gap,
  a real convention violation. Not for "checked, looks fine." Tasks
  always live with their module, never in a shared maintenance file —
  check all three places a module's folder can be, in this order:
  `.specify/<name>/`, `.specify/stable/<name>/`, `.specify/paused/<name>/`.
    - Found in `.specify/<name>/` (active): append to its `tasks.md`,
      per-directory task ids (`<name>/T0xx`), matching every other
      module's convention.
    - Found in `.specify/stable/<name>/`: a module gaining new
      maintenance tasks is no longer "shipped-and-verified-with-nothing-
      outstanding" (the bar `constitution.md` sets for `stable/`), so
      move the whole folder back to `.specify/<name>/` (`move_file`),
      then append the task there. Say in the close-out that the module
      came off `stable/` and why.
    - Found in `.specify/paused/<name>/`: append there, in place — a
      maintenance finding doesn't by itself mean "resume," so don't move
      it; note the new task alongside whatever it's paused on.
    - Found nowhere: create `.specify/<name>/tasks.md` fresh, with a short
      header noting it was reopened by a maintenance pass (most shipped
      modules have no `.specify/` folder at all, having graduated to
      `docs/` — this is expected, not an error).
  Record the task id(s) in `tasks_filed` as `.specify/<path>/T0xx`.
- Stop after one module. No cascading to a second module, no fixing what
  was found inline — fixes are future tasks, matching the "one phase per
  turn" rule. Close with three lines: what was audited, what each axis
  found, what got filed.
- This pass never edits `plan.md`'s Work Queue directly — if a finding is
  big enough to warrant a work-queue item, say so and let Matt decide.
