# Vsynth Vocabulary

**Status:** Populated from first analysis pass, 2026-05-31.

**Purpose:** Named abstractions, send/receive conventions, what specific objects and terms mean in Vsynth context. Reduces reconstruction cost each session. Answers "what does X actually do?"

---

## Named Abstractions

### vs_inState
*Source: `patchers/abstractions/vs_inState.maxpat`*

Detects whether a real texture is connected to an inlet. Uses a `timer` against `r draw` (the global draw bang) to measure time since last texture arrived. If elapsed time < 180ms, a texture is connected; if ≥ 180ms, disconnected. Uses `r vs_noConnectionTimer` as threshold reference.

Mechanism: `route clear` separates `clear` messages from real textures. Real textures restart the timer; `clear` messages indicate no connection. A `change` object ensures state-change output fires only on transitions, not every frame.

- **Inlet 0:** texture or control signal from upstream
- **Outlet 0:** real upstream texture when connected; `jit_gl_texture vs_black` fallback when not (switched via `switch 2`)
- **Outlet 1:** 0/1 int — fires **on state change only**, not every frame. 0 = disconnected (source mode), 1 = connected (processor mode)

The fallback is `vs_black`. An optional `vs_gray` fallback also exists in the patcher but is not in the default signal path.

### vs_thru
*Source: `patchers/abstractions/vs_thru.maxpat`*

Trivial passthrough — inlet directly wired to outlet with no logic. Used as a named wire for clarity in larger patches. Seen in `vs_render` routing texture flow.

### vs_canvas
*Source: `patchers/abstractions/vs_canvas.maxpat`*

Enable-gate abstraction. Routes `enable` messages to control a `gate 1 1` (default open). Passes all non-enable messages straight through. Listens to `r canvas` global receive — the canvas state can be set globally to block/pass all canvas-routed signals. Used to enable/disable modules from a central control point.

### vs_canvasLFO
*Source: `patchers/abstractions/vs_canvasLFO.maxpat`*

Identical to `vs_canvas` but listens to `r canvas_lfo`. Allows LFO modulation to be globally toggled independently of main canvas enable.

### vs_range
*Source: `patchers/abstractions/vs_range.maxpat`*

Parameter range selector with 3 preset ranges. Takes integer 0/1/2, outputs `_parameter_range #min #max` with corresponding args (set via patcherargs). This is the mechanism behind dual/triple-range params in WFG modules (e.g. `freq [0-1000] [0-10000]`). The `vs_range` abstraction switches which range is active at runtime.

### vs_b2b (black-to-bang)
*Source: `patchers/abstractions/vs_b2b.maxpat`*

Texture-to-bang converter. Runs `jit.3m` on incoming matrix, extracts mean luma (÷255), thresholds at 0.5, fires a one-shot bang on first frame where mean luma exceeds 0.5. Uses `onebang` to prevent repeated firing. Purpose: detect when a texture "goes bright" and fire a single event. Used for beat/event detection from visual sources.

### vs_newTime
*Source: `patchers/abstractions/vs_newTime.maxpat`*

Time/sync abstraction with 3 inlets: shape (inlet 1), freq (inlet 2), speed (inlet 3). Reads `r vs_ntime` (normalized time) and `r trig_res` (trigger reset). Produces `time $1` message on outlet 1. Translates the global time signal into per-module time with independent speed control. Core of how WFG animation is driven. Handles sync locking and modulo wrapping.

### vs_bline
*Source: `patchers/abstractions/vs_bline.maxpat`*

Parameter interpolation abstraction wrapping Max's built-in `bline` object (breakpoint line interpolator). Smooths discrete value changes into a continuous ramp, frame-synced to `r draw`.

**Mechanism:** Incoming float → `pak f 6` (packages with 6-frame interpolation time) → `bline 0.`. A `gate` object opens only when the value is changing (detected via `change`) — the `r draw` bang only drives `bline` while interpolating, stops at destination. Kevin's comment: *"Avoid [render] to keep triggering [bline] after reaching destination."*

- **Inlet 0:** float value to smooth toward
- **Outlet 0:** smoothed float output
- **Outlet 1:** `done` bang when destination is reached

Optional: accepts a name via patcherargs — outputs `prepend <name>` message for named param bundling.

Used in `vs_feedback` (amt), `vs_displacement` (x, y, zoom), and likely many other modules. f_ does not currently use `vs_bline` — direct live.dial → prepend is sufficient for most params. For automation-sensitive params (feedback amount, blend ratios), `vs_bline` improves behavior.

---

## Global Sends / Receives

From `patchers/vs_public_variables.txt` and patcher reads.

| Send/Receive | Type | Description |
|---|---|---|
| `r draw` | bang | Global draw bang — fires every render frame. Used by `vs_inState` for timing. |
| `r vs_ntime` | float | Normalized global time signal. Used by `vs_newTime` for animation. |
| `r vs_noConnectionTimer` | float | Threshold value (~180ms) used by `vs_inState` for disconnect detection. |
| `r trig_res` | float/bang | Trigger reset. Used by `vs_newTime` for sync reset. |
| `r canvas` | int | Global canvas enable. Received by all `vs_canvas` abstractions. |
| `r canvas_lfo` | int | Global LFO enable. Received by all `vs_canvasLFO` abstractions. |
| `r time` | float | Time signal used directly by WFG gen params. |
| `r dim` | vec2 | Current render dimensions. Used in source patchers for aspect correction. |

---

## External Control Message Conventions

From `patchers/vs_public_variables.txt`. Document self-describes as outdated — check individual help files for current params.

**Common to most modules:**
- `enable [boolean]` — on/off

**WFG family params (wfg_3 / bipolar_wfg):**
- `freq [0-1000] [0-10000]` — dual range (narrow/wide)
- `fm [-1-1] [-5-5]` — frequency modulation amount, dual range
- `pm [-1-1] [-5-5]` — phase modulation amount, dual range
- `bias [0-100]` — DC bias
- `bm [-0.5-0.5]` — bias modulation
- `pw [0-100]` — pulse width
- `pwm [-0.5-0.5]` — pulse width modulation
- `phase [0-1]` — initial phase offset
- `speed [-10-10]` — animation speed
- `angle [0-360]` — spatial orientation
- `shape [0-1]` — waveform shape blend
- `sync_lock [0-3]` — sync mode

**Displacement:**
- `x/y` — triple range: `[-0.1-0.1]`, `[-0.5-0.5]`, `[-3-3]`
- `angle [0-360]`
- `zoom [0-5]`
- `bound mode [0-3]`

---

## Naming Conventions

| Prefix | Domain |
|---|---|
| `vs_` | Core Vsynth module |
| `vs_wfg_` | Waveform generator family |
| `vs_lfo_` | LFO variant |
| `vs_bm_` | Blend mode gen implementation |
| `vs_op` | Math operator, 1-input |
| `vs_op2` | Math operator, 2-input |
| `f_` | Matt's extension library |
| `f_util_` | f_ infrastructure/analysis tools |
| `vector_` | Vector subsystem (separate output domain) |

**Kevin's parameter naming conventions:**
- Single-word lowercase: `freq`, `phase`, `speed`, `angle`, `bias`, `shape`
- Two-letter modulation suffix: `fm`, `pm`, `bm`, `pwm`, `hm`, `sm`, `lm`, `am`
- `enable` = module on/off. Kevin does NOT use `bypass` — f_ does.

---

## Key Architectural Terms

| Term | Meaning |
|---|---|
| `vsynth` | Named GL drawto context — all modules draw here |
| `vs_render` | Patch that owns render context, qmetro, fps |
| `vs_modules` | Module layout/sizing system |
| `vs_black` | Named black texture — system-wide zero-signal reference |
| `vs_gray` | Named gray texture — alternative fallback |
| `r draw` | Per-frame heartbeat of the entire render system |
| `_parameter_range` | Max message to set live.dial range at runtime |
| `vs_bline` | Frame-synced parameter smoothing abstraction |
| `vs_canvas` | Enable-gate with global toggle |
| `@gen filename` | `jit.gl.pix` attribute to specify gen implementation by file — Kevin's pattern for runtime-selectable operations (e.g. blendmode_mixer swaps gen file to change blend mode) |
| `@adapt 0` | On `jit.gl.pix` — disables auto-dimension adaptation to input. Used in mixers to keep fixed output size. |
| `@type char` | On `jit.gl.pix` — 8-bit integer output. Used on feedback paths intentionally for quantization character. |
| `poltocar` | Gen object: polar to cartesian conversion. Used inside displacement gen to define displacement field in polar space. |
| `scale 0. 1. -1. 1.` | Gen object: remaps [0,1] texture values to [-1,1] bipolar displacement. Standard pattern for texture-driven bipolar modulation. |

---

*Populated: 2026-05-31 (second analysis pass — vs_bline confirmed, vs_displacement, compositing modules)*
*Last updated: 2026-05-31*
