# Vsynth Vocabulary

**Status:** Skeleton — not yet populated. Reading pass planned; see HANDOFF.md.

**Purpose:** Named abstractions, send/receive conventions, what specific objects and terms mean in Vsynth context. Reduces reconstruction cost each session. Answers "what does X actually do?"

---

## Named Abstractions

### vs_inState
*Source: `patchers/abstractions/vs_inState.maxpat`*

Monitors whether a texture is connected to an inlet. Uses draw-callback timing rather than luma/alpha to detect connection state — avoids false negatives with black textures.

- **Outlet 0:** real upstream texture when connected; `vs_black` fallback when not
- **Outlet 1:** 0/1 int — fires on state change only (not every frame). 0 = unconnected, 1 = connected

Used to implement dual-mode bpatchers (source when unconnected, processor when texture present).

### vs_black
*Source: unknown — likely a send or abstraction producing a black texture*

Black texture fallback used by `vs_inState` when no upstream texture is connected. Allows source-mode bpatchers to render without a real upstream signal.

### vs_render
*Source: `patchers/vs_render.maxpat`*

Owns the Vsynth GL render context and render tempo. Sets `qmetro` rate, creates the `vsynth` drawto context. f_ bpatchers draw to this context via `jit.gl.pix vsynth` — they never touch `vs_render` directly.

### vs_modules
*Source: `patchers/vs_modules.maxpat`*

Module layout system. Manages bpatcher sizing and positioning in the Vsynth canvas. f_ bpatchers report their presentation size via the `moduleSize.js` chain so `vs_modules` can arrange them.

### vs_sync_time
*Source: `patchers/vs_sync_time.maxpat`*

Tempo/time sync utility. Exposes a `r time` global receiver carrying the current render time. Used by f_ patches that need time-based animation (e.g. `f_grain` speed control).

---

## Send/Receive Namespace

*To be populated from `patchers/vs_public_variables.txt`.*

| Send/Receive | Type | Description |
|---|---|---|
| `r dim` | vec2 | Current render dimensions |
| `r time` | float | Global render time / tempo signal |

*Additional sends/receives to be documented after reading `vs_public_variables.txt`.*

---

## Parameter Conventions

*To be populated from WFG and other module reads.*

| Term | Meaning |
|---|---|
| `freq` | Spatial frequency — number of cycles across the frame |
| `phase` | Phase offset — where in the waveform cycle the field starts |
| `angle` | Orientation in degrees (-360 to 360) |
| `FM` / `PM` | Frequency/phase modulation amount — how much an incoming signal modulates the waveform |
| `bypass` | 0/1 toggle — passes input texture through unmodified when 1 |

---

## Naming Conventions

*To be populated from analysis pass.*

- `vs_` prefix — core Vsynth module
- `vs_wfg_` prefix — waveform generator family
- `vs_lfo_` prefix — LFO variant of waveform generators
- `vs_bm_` prefix — blend mode gen implementation
- `vs_op` prefix — math operator (1-input)
- `vs_op2` prefix — math operator (2-input)
- `f_` prefix — Matt's extension library (this repo)
- `f_util_` prefix — f_ infrastructure/analysis tools (no texture output)
- `vector_` prefix — vector subsystem modules (separate output domain)

---

*Populated: 2026-05-31 (skeleton + known items from session notes — no Vsynth files read yet)*
*Last updated: 2026-05-31*
