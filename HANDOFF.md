# f_ Package Handoff
_Last updated: 2026-05-25 — .specify/ scaffold + conceptual clarifications_

## What was done this session

### .specify/ scaffold built from scratch

Created the full project planning structure in `f_/.specify/`:

- **constitution.md** — project identity, bpatcher conventions, development approach, two-tier ideas→spec graduation system
- **tasks.md** — cross-session task tracker; migrated all loose threads and next steps from HANDOFF
- **ideas.md** — scratchpad for half-formed bpatcher ideas before they have a name and parameter contract
- **bpatchers/** — stub specs for all 8 bpatchers, with params extracted from source; f_chladni has full spec including signal chain and EEG band mapping

### f_cymascope → f_chladni clarification

Realized the existing bpatcher is Chladni plate physics (modal superposition, Bessel functions, nodal lines on a solid plate) — not cymascope physics (wave propagation through a fluid medium). Renamed spec accordingly. A new `f_cymascope.md` spec describes the FDTD wave propagation approach as a distinct future bpatcher, with a feasibility note about ping-pong texture technique in Vsynth.

**Patcher file rename still pending** — `f_cymascope.maxpat` → `f_chladni.maxpat` needs to happen in Max.

### Ideas captured

Four idea clusters added to ideas.md:
- **Optics family** (f_lens, f_caustic, f_flare, f_diffraction) — unified by "incoming texture as light source" framing; separate bpatchers, shared parameter vocabulary
- **Apollonian fractal** — circular gasket, animatable, GLSL approach TBD
- **Non-Euclidean geometry** — hyperbolic tiling (Poincaré disk / Möbius transforms), connects to f_droste mathematically
- **Light caustics** — wave physics / optics crossover; generator vs processor question open

Emerging taxonomy noted: processors / optical elements / wave physics / geometry — useful framing for the scope review.

## Current state

All patchers working. .specify/ scaffold committed. No Max files modified this session.

## Loose threads

- **f_chladni: patcher file rename** — do in Max, update param_connect strings inside the patcher
- **f_chladni: audio signal chain** — bandpass bank → peakamp~ → smooth → m0–m7
- **f_chladni: Muse OSC routing** — udpreceive → band routing → scale → smooth → m0–m7
- **f_cymascope feasibility** — ping-pong texture / FDTD in jit.gl.pix; needs dedicated discussion before building
- **Scope review** — step back on overall package direction before planning new bpatchers; feeds into plate morphing decision and optics family prioritization
- **Help patches** — none exist yet

## Next steps

1. Rename f_cymascope.maxpat → f_chladni.maxpat in Max
2. Scope review conversation (taxonomy: processors / optics / wave physics / geometry)
3. Build f_chladni audio signal chain
4. Begin speccing optics family (review prior aberration session work first)

## Package structure

```
f_/
  patchers/       — 8 bpatchers (f_cymascope.maxpat pending rename to f_chladni)
  code/           — JS files
  help/           — (empty)
  .specify/
    constitution.md
    ideas.md
    tasks.md
    bpatchers/    — 9 specs (8 working + f_cymascope concept)
  package-info.json
  HANDOFF.md
  README.md       — needs f_chladni added to patch table
```

## Resources
- Vsynth: /Users/matt/Documents/Max 9/Packages/Vsynth
- vsynth-bpatcher skill: /mnt/skills/user/vsynth-bpatcher/SKILL.md
- Chladni Obsidian note: f_cymascope_bpatcher.md (needs renaming)
