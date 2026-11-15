# Project layout and lifecycle

Where things live in the f_ repo and how a module moves from idea to stable. Part of the vsynth-bpatcher skill. CLAUDE.md's repo map and session rules win where this differs.

## Vsynth Reference Documentation

Systematic analysis of Vsynth internals is documented in the f_ repo:

```
/Users/matt/Github/f_/docs/vsynth-reference/
  module-inventory.md   — every Vsynth module: tier, inlets/outlets, notes
  patterns.md           — Kevin's recurring architectural patterns
  vocabulary.md         — named abstractions, sends/receives, conventions
```

Consult these before designing a new f_ patch: capability map (what Vsynth already provides), pattern library (how Kevin solves common problems), vocabulary (what specific terms and objects mean).

---

## Package Structure

```
f_/
  package/     — the installable Max package (this alone is what Max needs)
    patchers/    — all bpatcher .maxpat files (source of truth)
    javascript/  — JS files (on Max search path)
    help/        — .maxhelp files, written in a Claude session (build/generate_helpfiles.py builds the prompt; f-helpfile skill)
    package-info.json
  docs/        — f-reference/ (as-built docs per module), vsynth-reference/, max-reference/
  ideas/       — planned and half-formed bpatchers
    scratchpad.md       — low-friction idea dump, no structure required
    f_<name>.md         — specced but not yet built
  build/       — official build system (version controlled, presentable to other authors)
    build_patcher.py    — generates .maxpat from a definition file (see build/spec.md)
    spec.md             — build script spec
    extract_params.py, generate_helpfiles.py
    generate_menu.py    — generates f_modules.maxpat and f_addmod.js's SIZES from src/f_modules/menu.py
    generate_launch.py  — generates f_Launch.maxpat from the README Patches table
  skills/      — Claude skills for this repo (uploaded to claude.ai; MANIFEST.md + check.sh track the upload)
  tests/       — tests/modules/<m>/ (NumPy mirrors, bench_<m>.py), tests/contracts/, tests/build/
  .specify/    — planning workspace: spec.md/plan.md/tasks.md only (version controlled — no longer gitignored)
    constitution.md
    plan.md, gates.md   — one-page focus; every blocked or parked item with who decides
    f_<name>/           — one dir per active bpatcher, planning docs only
      spec.md           — what it does and how you know it's working
      plan.md           — ADRs, blocks, phases (added when build begins)
      tasks.md          — flat task list, the module's record
    stable/f_<name>/    — modules shipped and verified with nothing outstanding (build/spec.md lifecycle)
    paused/f_<name>/    — shelved on a real open question; excluded from planning (CLAUDE.md)
  src/         — build-input files (version controlled)
    f_<name>/           — one dir per bpatcher with code
      definition.py     — patcher definition: codebox + params + archetype (added at end of Phase 2)
      codebox_*.gen     — confirmed codebox content, referenced by definition.py
      build_*.py        — per-module build script, for modules whose build needs diverge from build_patcher.py's general path
  HANDOFF.md   — START HERE block plus the latest entry (older entries in HANDOFF_ARCHIVE.md)
  README.md    — permanent project state: bpatcher status table, build queue
```

- File naming: `f_<name>.maxpat`
- JS files referenced by filename only — Max finds via search path
- **A file added to the package is not found by a Max launched before it existed** (2026-11-14, `f_halftone`): `jit.matrix: can't find file f_bluenoise64.jxf` for a new file in `package/media/`, and newly written patchers failed to load by name; after a Max relaunch, found (module bench 9/9, `tests/logs/20261114-112730-bench.log`). Relaunch Max before benching or looking at a new media file, JS file or patcher. Users are unaffected (Max scans packages at launch).
- Files shipped for a module to load (a texture, a lookup table) go in `package/media/`, loaded by name through the builder's `mod_inlets` `static` key (`build/build_patcher.py`).
- Every patcher: `"openinpresentation": 1`

### Naming Convention: f_vf_ prefix for vecfield producers

Bpatchers whose **primary output is an f_vecfield texture** (float32, RG=XY, 0.5=zero vector) use the `f_vf_` prefix rather than `f_`. This signals to users that the output is a specialized texture consumed by specific downstream modules (f_caustic, f_lens field inlet) rather than a standard Vsynth char texture.

The current family is the modules with the `V` kind in `src/f_modules/menu.py` (and the README Patches table); don't keep a copy of that list here. Modules without the prefix can still take or emit a vecfield (`f_caustic`, `f_lens`'s field inlet, `f_chladni`'s third outlet): their `signal_type` label says so (`references/parameters-and-ui.md`).

The type contract is in `docs/f_vecfield_type.md`. User-facing disambiguation (UI badge on each producer, helpfile explanation) reinforces the distinction without requiring users to memorize the prefix meaning.

## Bpatcher Lifecycle

Each bpatcher moves through three stages:

**1. `ideas/scratchpad.md`** — half-formed idea, no structure required. Drop it here to avoid losing it.

**2. `ideas/f_name.md`** — graduated from scratchpad when the idea has a concept, rough parameter contract, and known open questions. Not yet built. Create this file before opening Max.

**3. `docs/f-reference/f_name.md`** — as-built reference. Bpatcher is working and confirmed. Documents params, signal chain, usage, and known issues as they actually exist. Nothing lives in `docs/` that isn't working.

### Planning Workflow

- **`ideas/f_name.md`** — spec for a planned bpatcher: concept, parameter contract, open questions. Lives here until the build begins.
- **`.specify/f_name/spec.md`** — what the bpatcher does and how you know it's working. Written before touching Max.
- **`.specify/f_name/plan.md`** — ADRs, dependency blocks, implementation phases. Added when build begins.
- **`.specify/f_name/tasks.md`** — flat ordered task list; the module's record. Added when build begins; it moves with the module to `.specify/stable/` (run module-preflight first).
- **`src/f_name/definition.py`** — patcher definition file: confirmed codebox + full param contract + archetype. Written at end of Phase 2 (codebox confirmed). Input to `build/build_patcher.py`. See `build/spec.md` for schema.
- **`docs/f-reference/f_name.md`** — as-built reference. Updated when the bpatcher changes, not during planning.

**At session end:** follow CLAUDE.md's Session rules and Claims sections (tasks.md, gates.md, plan.md, the HANDOFF START HERE block and a new short entry, a commit). Moving a finished module: `git mv .specify/f_name .specify/stable/f_name` after module-preflight.
