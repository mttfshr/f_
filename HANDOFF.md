# f_ — Handoff

_Session: 2026-05-25_

## What was done this session

**Repo structure migrated:**
- `docs/` and `ideas/` directories established; bpatcher specs moved from `.specify/bpatchers/`
- `.specify/` restructured to per-bpatcher dirs — monolithic `spec.md`, `plan.md`, `tasks.md` replaced by `.specify/f_name/` folders
- `README.md` now carries permanent project state (patch table, build queue)
- `HANDOFF.md` scoped to session notes only
- `constitution.md` and `vsynth-bpatcher` skill updated to reflect all of the above

**f_chladni signal chain specced:**
- `.specify/f_chladni/spec.md` — signal chain, acceptance criteria, EEG band→mode mapping, clarifications
- `.specify/f_chladni/plan.md` — 5 ADRs, dependency blocks, phases
- `.specify/f_chladni/tasks.md` — T001–T034

**f_mobius specced:**
- `ideas/f_mobius.md` — concept, params, codebox structure
- `.specify/f_mobius/spec.md` — clean spec; plan + tasks when build begins

**Circular screen design direction captured:**
- `ideas/circular_screen.md` — stereographic projection, spherical harmonics, Poincaré disk; 4 proposed bpatchers; research questions; ambisonics connection

**Housekeeping:**
- `vs_texrouter_SPEC.md` deleted — implementation notes folded into `docs/f_texrouter.md`
- `.specify/f_droste/tasks.md` — single task: add autopattr to match package convention
- `vsynth-bpatcher` skill corrected: autopattr IS used in most patchers; added to checklist

## First thing next session

Open `.specify/f_chladni/tasks.md` → T001 (patcher rename in Max: `f_cymascope.maxpat` → `f_chladni.maxpat`).

## Loose threads

- f_droste: needs autopattr added (`.specify/f_droste/tasks.md`, 3 tasks)
- Scope review still pending: optics family vs circular screen prioritization
- Help patches: none exist for any bpatcher; f_texrouter first (bypass = freeze must be documented)
- Muse calibration: measurement pass needed before EEG companion patch can be built (T020)
