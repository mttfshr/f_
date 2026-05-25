# f_ Package Handoff
_Last updated: 2026-05-25 — repo structure design + skill update_

## What was done this session

### .specify/ scaffold built
Constitution, tasks, ideas, and per-bpatcher stubs (params extracted from source). See previous commit for details.

### f_cymascope → f_chladni clarification
Existing bpatcher is Chladni plate physics (Bessel modal superposition), not cymascope (FDTD wave propagation through fluid). Renamed spec. New f_cymascope.md written as a distinct concept spec. **Patcher file rename still pending in Max.**

### Repo structure designed and committed
Three-tier layout agreed and documented in constitution + vsynth-bpatcher skill:

- **`docs/`** — as-built reference, working bpatchers only
- **`ideas/`** — planned and half-formed bpatchers (scratchpad.md + per-bpatcher files)
- **`.specify/`** — planning workspace only (constitution, spec, plan, tasks)

Current `.specify/bpatchers/` files are temporary — migration to docs/ and ideas/ is the first task next session.

### Ideas captured
Four idea clusters in ideas.md: optics family (f_lens, f_caustic, f_flare, f_diffraction — unified by "incoming texture as light source"), Apollonian fractal, non-Euclidean / hyperbolic geometry, light caustics. Emerging taxonomy noted: processors / optical elements / wave physics / geometry.

### vsynth-bpatcher skill updated
Package structure and bpatcher lifecycle added. claude-scaffold committed `1064daf`.

## First thing next session

**Repo migration — do before anything else:**
1. Create `docs/` and `ideas/` directories
2. Move working bpatcher specs from `.specify/bpatchers/` → `docs/`
3. Move f_cymascope.md → `ideas/f_cymascope.md`
4. Rename ideas.md → `ideas/scratchpad.md`
5. Delete `.specify/bpatchers/`
6. Write `spec.md` for f_chladni signal chain
7. Derive `plan.md` and rewrite `tasks.md` from spec

## After migration

- f_chladni patcher file rename in Max (f_cymascope.maxpat → f_chladni.maxpat)
- Scope review — package taxonomy, optics family prioritization
- f_chladni audio signal chain build

## Loose threads

- f_chladni: ph0 dead param, near-center singularity, plate shape morphing (pending scope review)
- f_cymascope: ping-pong texture / FDTD feasibility — needs dedicated discussion
- Help patches: none exist yet
- f_texrouter: bypass = freeze semantics need documenting
- README: update patch table for f_chladni rename
