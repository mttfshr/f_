# f_ — Project Constitution

_Last updated: 2026-06-09_

## Identity

**f_** is an open-ended collection of visual processing bpatchers for [Vsynth](https://www.kevinkripper.com/vsynth) in Max. It is developed alongside live performance work and grows incrementally as new processing needs emerge.

The package is a collaboration artifact — its structure and conventions are designed to support working with Claude across sessions on an evolving, open-ended set of files.

---

## What f_ IS

- A **Max package** following Cycling '74 package conventions
- A collection of **Vsynth-compatible bpatchers**, each self-contained and independently usable
- Developed **alongside performance work** — real needs drive new bpatchers
- **Open-ended** in scope — no fixed feature set, new bpatchers are added as needed
- **Codebox-first** — GLSL logic lives in jit.gl.pix codeboxes; patchers are thin wrappers
- **Signal-chain oriented** — each bpatcher has defined inputs, outputs, and parameter contracts
- Designed to be **understood and modified** by anyone who knows Max and Vsynth

## What f_ IS NOT

- Not a monolithic application with a fixed roadmap
- Not standalone — requires Max 9 and Vsynth
- Not a framework or abstraction layer over Vsynth
- Not optimized for generality — bpatchers solve specific problems
- Not finished software — it evolves with the work that uses it

---

## Bpatcher Conventions

Every bpatcher in `patchers/` follows the vsynth-bpatcher skill conventions:

- Vsynth owns render tempo and cornerpins
- `routepass` pattern for parameter routing
- `moduleSize` chain for UI sizing
- Single Vsynth inlet; parameters via message
- GLSL in codebox, not inline

### Naming Convention: f_vf_ prefix for vecfield producers

Bpatchers that produce **f_vecfield textures** (float32, RG=XY, 0.5=zero) use the `f_vf_` prefix:

```
f_vf_vortex         — single analytic fixed-point vortex field
f_vf_vortex_multi   — three-site additive vortex field
f_vf_fieldmap       — scalar texture → vecfield via spatial derivative
f_vf_warp           — UV warp consumer
f_vf_streak         — directional blur consumer
f_vf_chladni        — modal superposition, audio-driven (vecfield outlet pending; currently f_chladni)
f_vf_cymascope      — FDTD wave propagation, audio-driven (not yet built)
```

The `f_vf_` prefix signals to users that the primary output is a vecfield texture consumed by specific downstream modules (f_caustic, f_lens field inlet). Bpatchers without this prefix produce standard Vsynth char textures. User-facing disambiguation (UI badge, helpfile explanation) reinforces the distinction.

The type contract is documented in `docs/f-reference/f_vecfield_type.md`.

---

## Development Approach

### The Bpatcher Lifecycle

Each bpatcher moves through three stages, each with a distinct home:

**1. `ideas/scratchpad.md`** — half-formed, no structure required. A name, a feeling, a reference. Low friction.

**2. `ideas/f_name.md`** — graduated from scratchpad when the idea has a concept, rough parameter contract, and known open questions. Not yet built. `f_cymascope` lives here.

**3. `docs/f_name.md`** — as-built reference. The bpatcher is working. Documents params, signal chain, usage, and known issues as they actually exist. Stable unless the bpatcher changes.

A bpatcher moves from `ideas/` to `docs/` when it is built and confirmed working. Nothing lives in `docs/` that isn't working.

### Planning Workspace

`.specify/` is a planning workspace, not a reference directory. It contains:

- **`constitution.md`** — project identity and conventions (this file)
- **`f_name/spec.md`** — what the bpatcher does, for whom, and how you know it's working
- **`f_name/plan.md`** — ADRs, dependency blocks, implementation phases; derived from spec
- **`f_name/tasks.md`** — flat ordered task list; the session anchor for that build

Each bpatcher gets its own subdirectory when actively being built. `spec.md` is written first. `plan.md` and `tasks.md` are added when the build begins. The folder is removed (or archived) when the bpatcher graduates to `docs/`.

### Sessions May Touch Multiple Bpatchers

Cross-session state lives in:
- **`docs/f_name.md`** — what a working bpatcher is and how it behaves
- **`ideas/f_name.md`** — what a planned bpatcher should be
- **`.specify/f_name/tasks.md`** — what's in progress for the active build

### Handoff Protocol

At the end of every session, update **both**:

**`README.md`** (permanent project state):
- Bpatcher status table — add new bpatchers, update status changes
- Build queue — reflect any priority changes
- `.specify/` structure — update if directories were added or removed

**`HANDOFF.md`** (session notes — ephemeral):
- What was done this session
- What to do first next session
- Any loose threads or open decisions

HANDOFF.md is written fresh each session. README.md is maintained continuously. Do not put permanent project state in HANDOFF — it will be overwritten.

At the start of each session, read `.specify/plan.md` for workstream orientation, then HANDOFF.md for the specific state of the last session.

---

## Package Structure

```
f_/
  patchers/       — bpatcher .maxpat files (source of truth)
  code/           — JS files used by patchers
  help/           — .maxhelp files (derived from docs/ eventually)
  docs/           — as-built reference docs (working bpatchers only)
  ideas/          — planned and half-formed bpatchers
    scratchpad.md — low-friction idea dump
    f_name.md     — specced, not yet built
  .specify/       — planning workspace
    constitution.md     — this file
    f_name/             — one dir per bpatcher under active development
      spec.md           — what it does and how you know it's working
      plan.md           — ADRs, blocks, phases (added when build begins)
      tasks.md          — flat task list, session anchor (added when build begins)
  package-info.json
  HANDOFF.md      — session notes (ephemeral; written fresh each session)
  README.md       — permanent project state: status table, build queue
```

---

## Current Bpatchers

| File | Description | Status |
|------|-------------|--------|
| `f_droste` | Log-polar spiral transform (Droste/Escher recursive zoom) | Working |
| `f_grain` | Stochastic grain field with per-grain displacement and luma gating | Working |
| `f_channel_grader` | Per-channel color grading | Working |
| `f_hue_processor` | Hue-selective processing | Working |
| `f_luma_processor` | Luminance-selective processing | Working |
| `f_tone_curve` | Tone curve adjustment | Working |
| `f_texrouter` | 4×4 texture routing matrix with preset system | Working |
| `f_chladni` | Chladni plate modal synthesis visualizer (Bessel modes), audio-reactive | Working — audio companion init issue open; vecfield outlet planned → rename f_vf_chladni |
| `f_caustic` | Optical caustic — streamline accumulation weighted by field convergence | Working |
| `f_lens` | Filmic lens — aberration, distortion, transmission, tilt-shift, spatial modulation | Working |
| `f_stereo` | Stereographic projection display layer | Working |
| `f_masonry` | Parametric masonry texture | Working |
| `f_stipple` | 2D hash field stipple texture | Working |
| `f_mobius` | Möbius transformation UV-space processor | Working |
| `f_vf_vortex` | Single fixed-point vortex field — f_vecfield producer | Working (renamed from f_vortex) |
| `f_vf_vortex_multi` | Three-site additive vortex field — f_vecfield producer | Working (renamed from f_vortex_multi) |
| `f_vf_fieldmap` | Scalar texture → vecfield via central difference gradient | Working |
| `f_vf_warp` | UV warp via f_vecfield | Working |
| `f_vf_streak` | Directional blur via f_vecfield — dual outlet | Working |

---

## Constraints

1. **Don't break Vsynth compatibility** — all bpatchers must follow Vsynth signal flow conventions
2. **Codebox before patcher** — write and verify GLSL in codebox text before building JSON structure
3. **One bpatcher, one concern** — resist adding unrelated functionality to an existing bpatcher
4. **Specs before building** — for any new bpatcher, write the spec (concept + params + signal chain) before opening Max
5. **Tasks.md is the session anchor** — always update `.specify/f_name/tasks.md` at session end; also update README.md (project state) and HANDOFF.md (session notes)
