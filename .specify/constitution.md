# f_ — Project Constitution

_Last updated: 2026-05-25_

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
- No `autopattr` (explicit routing only)
- Single Vsynth inlet; parameters via message
- GLSL in codebox, not inline

---

## Development Approach

### New Bpatcher Ideas

Half-formed ideas, inspiration, and things to try go in `.specify/ideas.md` — no structure required. When an idea has a name, concept, and rough parameter contract, it graduates to a spec file in `.specify/bpatchers/`.

### The Unit of Work Is a Bpatcher

Each bpatcher has its own spec file in `.specify/bpatchers/`. A bpatcher spec covers:
- Purpose and concept
- Parameters (with types and ranges)
- Signal chain (intended data flow)
- Loose threads and known issues
- Status (working / in-progress / stub)

### Sessions May Touch Multiple Bpatchers

A session might add a parameter to `f_hue_processor`, fix a bug in `f_droste`, and build the signal chain for `f_cymascope`. Cross-session state lives in:

- **Per-bpatcher specs** — what that bpatcher is and what's unresolved
- **`tasks.md`** — flat, ordered list of in-progress and next work across all bpatchers

### Handoff Protocol

At the end of a session:
1. Update any modified bpatcher specs
2. Update `tasks.md` — mark done, add new items, reorder
3. Update `HANDOFF.md` at the repo root — one paragraph summary of where things stand

---

## Package Structure

```
f_/
  patchers/       — bpatcher .maxpat files (source of truth)
  code/           — JS files used by patchers
  help/           — .maxhelp files (currently empty)
  .specify/
    constitution.md       — this file
    ideas.md              — scratchpad for half-formed bpatcher ideas (no structure required)
    bpatchers/            — one spec per bpatcher (graduated from ideas.md)
    tasks.md              — cross-session task tracker
  package-info.json
  HANDOFF.md              — session handoff summary
  README.md               — public-facing package docs
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
| `f_cymascope` | Circular plate modal synthesis visualizer (Bessel modes) | Working — signal chain pending |

---

## Constraints

1. **Don't break Vsynth compatibility** — all bpatchers must follow Vsynth signal flow conventions
2. **Codebox before patcher** — write and verify GLSL in codebox text before building JSON structure
3. **One bpatcher, one concern** — resist adding unrelated functionality to an existing bpatcher
4. **Specs before building** — for any new bpatcher, write the spec (concept + params + signal chain) before opening Max
5. **Tasks.md is the session anchor** — always update it at session end; it is the handoff
