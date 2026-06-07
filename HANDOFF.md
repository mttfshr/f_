# HANDOFF — f_ session 2026-06-07

## What was done this session

### 1. f_vf_vortex_multi v2 — global mod inlets
- Added 4 mod inlets: cx mod, cy mod, convergence mod, curl mod (inlets 1-4)
- Global offset pattern: `(sample(inN) - 0.5) * 2.0 * amt` applied to all three sites
- Per-site dial values preserve individual character; mod inlet drives global variation
- Codebox: in2-in5 decoded to signed offsets, added to per-site cx/cy/conv/curl
- definition.py updated: mod_inlets block, 4 _amt params, presentation_height 100→130
- Site position inlets removed entirely — handled externally via control inlet messages
- ID collision diagnosed: build system uses obj-100..110; post-build injection must use obj-200+
- Committed: "feat: f_vortex_multi v2 — 4 global mod inlets (cx, cy, conv, curl)"
  (Note: committed under old name, renamed in subsequent refactor commit)

### 2. Conceptual clarification — the f_vf_ producer family
Major design session establishing the architecture of the vecfield producer family:

**f_vf_fieldmap concept emerged:** instead of f_vortex_turbulence (hash-grid implicit sites),
the right tool is a scalar-to-vecfield converter — takes any scalar texture (jit.gl.bfg Perlin/Voronoi/fractal,
f_grain, stipple, luma from anything), derives a vector field from the spatial structure, outputs f_vecfield.
f_vortex_turbulence as a planned patch is dissolved.

**f_chladni and f_cymascope reframed as audio-to-vecfield transducers:**
- f_chladni: gradient of modal amplitude field → f_vecfield (vecfield outlet to be added)
- f_cymascope: gradient of FDTD wave amplitude field → f_vecfield (new patch, not yet built)
- Both sit in the same signal chain slot: audio → [transducer] → f_vecfield → f_caustic → visual output
- cymascope ideas file completely rewritten to capture this framing
- f_chladni spec updated with reframe section and deferred vecfield outlet plan

**f_vf_ naming convention established:**
- All vecfield producers use f_vf_ prefix to signal specialized output type
- User-facing disambiguation via UI badge (planned) + helpfile explanation
- Convention documented in constitution.md and vsynth-bpatcher SKILL.md (claude-scaffold)

**mod matrix scratchpad entry added:**
- f_vf_vortex_multi is natural v3 target for mod matrix (2 source textures → per-cell routing/depth)
- Deferred until UX pattern is solid

### 3. f_vf_ refactor — renamed patches
- f_vortex → f_vf_vortex (patcher, docs, internal @name and autopattr varname)
- f_vortex_multi → f_vf_vortex_multi (patcher, docs, internal names)
- .specify/ dirs renamed accordingly
- definition.py name/prefix/object_name fields updated in both
- README.md restructured: f_vf_ family gets its own section with bold header
- docs/f_vecfield_type.md: all patch names updated, f_vortex_turbulence row replaced with f_vf_fieldmap/chladni/cymascope, f_caustic marked Complete
- docs/f_vortex.md renamed to docs/f_vf_vortex.md
- claude-scaffold SKILL.md committed: "feat: add f_vf_ naming convention for vecfield producers"
- f_: "refactor: rename f_vortex and f_vortex_multi to f_vf_ prefix; establish f_vf_ vecfield producer family"

---

## Current state

All patches working. Git clean. f_vv_vortex_multi v2 verified live with f_caustic — excellent results.

**f_vf_ family as of session end:**
| Patch | Status |
|---|---|
| f_vf_vortex | Complete |
| f_vf_vortex_multi | Complete (v2 with 4 mod inlets) |
| f_vf_fieldmap | Planned — spec next |
| f_vf_chladni | Planned — vecfield outlet to be added to existing f_chladni |
| f_vf_cymascope | Planned — FDTD, audio-driven, significant architecture work needed |

---

## Next session priorities

### 1. Spec f_vf_fieldmap (immediate next)
The concept is clear and ready to spec:
- Input: any scalar texture (primary use case: jit.gl.bfg Perlin/Voronoi/fractal noise)
- Output: f_vecfield float32 texture encoding spatial derivative of input
- Archetype: processor (requires input; outputs vecfield, not visual texture)
- Key design questions to resolve in spec:
  - How is the spatial derivative computed? Finite differences (sample neighbors, subtract)
  - How many neighbor samples? 2 (simple forward difference) vs 4 (central difference) vs 5-point stencil
  - How is the output normalized? Raw gradient can have very small magnitude at low-frequency inputs
  - Does it need a strength/scale param to make the gradient range usable?
  - Should it output a visual mode too (for debugging / direct use)?
  - jit.gl.bfg connection: bfg is a separate object, not an inlet — user patches bfg → f_vf_fieldmap

### 2. f_grain diagnosis (oldest debt, still unaddressed)
Flagged broken in a previous session. Cause unknown. Should be investigated before it gets further buried.

### 3. f_vf_vortex_multi performance use
Get it into a real Vsynth set with texture mod patched in. Feel out the vsc_center_ctrl orbital animation pattern.

### 4. f_caustic helpfile
f_droste.maxhelp is the canonical template. f_caustic is a natural next helpfile candidate.

---

## Architecture decisions made this session (ADRs)

**ADR: f_vf_ prefix for vecfield producers**
Rationale: vecfield textures are a specialized type consumed only by specific downstream modules. The prefix makes the output type scannable in any file list without requiring documentation lookup. User-facing disambiguation (UI badge + helpfile) handles the explanation. Alternatives considered: ad hoc naming (rejected — not scannable), f_field_ prefix (rejected — verbose).

**ADR: f_vortex_turbulence dissolved → replaced by f_vf_fieldmap + jit.gl.bfg**
Rationale: Max's native jit.gl.bfg already generates Perlin, Voronoi, fractal and other noise types with full parameter control. Building a hash-grid noise generator in a codebox duplicates native functionality poorly. The right architecture is a small converter patch (f_vf_fieldmap) that derives a vecfield from any scalar input, letting jit.gl.bfg (or anything else) be the source.

**ADR: f_chladni and f_cymascope are audio-to-vecfield transducers**
Rationale: the interesting visual output of both patches comes from caustic accumulation along convergence zones in the amplitude field gradient — not from direct rendering of the amplitude field itself. Reframing as vecfield producers with f_caustic as the consumer produces better visual results and integrates both patches cleanly into the f_vf_ signal chain architecture.

---

## Loose threads

- **f_vf_vortex_multi site position via control inlet:** can simplify by routing `s1 center X Y` etc through inlet 0 with a `route s1 s2 s3` internally. Not urgent — works fine with external routing.
- **f_vf_vortex_multi v3 mod matrix:** 2 incoming texture sources, per-cell routing/depth matrix. Natural target given 4 modulated params. Deferred until UX pattern solid. (ideas/scratchpad.md entry written)
- **UI badge for f_vf_ producers:** small visual indicator in bpatcher presentation to signal vecfield output type. Design not yet decided. Deferred until at least one more f_vf_ patch is built.
- **f_vf_chladni vecfield outlet:** add second outlet (or mode) outputting ∇(modal amplitude) as f_vecfield. Deferred until f_caustic vecfield consumer path is more battle-tested.
- **f_cymascope ping-pong texture architecture:** FDTD requires frame-to-frame state. Investigate vs_chemical_osc before committing to implementation approach. This is the primary architectural risk for f_vf_cymascope.
- **f_chladni signal chain verification:** spectral normalization fix for high-frequency mode starvation. Still unaddressed.
- **f_lens Phase 5:** Vsynth integration testing, deferred multiple times.

---

## Key paths

- Repo: /Users/matt/Github/f_/
- Skills source: /Users/matt/Github/claude-scaffold/skills/
- Vsynth package: /Users/matt/Documents/Max 9/Packages/Vsynth/
- Scratch patches: ~/Vsynth/patterns/
- Obsidian vault: /Users/matt/Library/Mobile Documents/iCloud~md~obsidian/Documents/Obsidian/
