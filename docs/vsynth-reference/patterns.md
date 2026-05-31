# Vsynth Pattern Library

**Status:** Populated from first analysis pass, 2026-05-31.

**Purpose:** Recurring architectural patterns Kevin uses in Vsynth internals. Answers "how does Kevin solve X?" and "should f_ do the same?"

---

## Pattern: Dual-Mode via vs_inState

**Where used:** Any module that behaves differently depending on whether an upstream texture is connected.

**Mechanism:** `vs_inState` wraps the inlet, detects connection state via draw-callback timing (not luma/alpha — avoids false negatives with black textures). Outlet 0 = upstream texture or `vs_black` fallback. Outlet 1 = 0/1 state-change int.

**Wiring pattern:**
```
inlet → routepass jit_gl_texture jit_matrix
  routepass out0 (texture) → vs_inState in0
    vs_inState out0 → pix in0             [texture or vs_black]
    vs_inState out1 → prepend param src_mode → pix in0   [0/1, state change only]
  routepass out2 (unmatched) → route     [control]
```

**f_ adoption:** Used in `f_stipple` (first f_ dual-mode patch). Confirmed working. The `src_mode` param is hidden — not in route, UI, or parameters block.

---

## Pattern: Parameter Range Switching via vs_range

**Where used:** WFG family and other modules with dual or triple parameter ranges (e.g. `freq [0-1000] [0-10000]`).

**Mechanism:** `vs_range` abstraction takes integer 0/1/2, outputs `_parameter_range min max` message to the live.dial. Range values are set as patcherargs to `vs_range`. A range-select control (typically a toggle or int box) drives the inlet.

**Why it matters for f_:** This is how Kevin exposes wide vs. narrow control ranges without needing two separate params. f_ currently hardcodes param ranges in the definition file — if a param needs runtime range switching, `vs_range` is the pattern. Relevant for: f_weave (freq might want narrow/wide), any frequency param with a useful sub-range.

---

## Pattern: Global Enable via vs_canvas / vs_canvasLFO

**Where used:** All Vsynth modules.

**Mechanism:** `vs_canvas` wraps the module's enable/disable gate. Listens to `r canvas` global receive so all modules can be globally toggled from a central point. `vs_canvasLFO` variant for LFO parameters separately.

**f_ position:** f_ uses `bypass` (per-module) rather than `enable` (global). These are different things — bypass passes input through, enable stops the module entirely. f_ doesn't use `vs_canvas` and probably shouldn't — the bypass pattern is better for performance use. But knowing `r canvas` exists explains why Kevin's modules respond to a global enable that f_ modules wouldn't respond to.

---

## Pattern: WFG Signal Architecture

**Source: `code/vs_wfg_sine.genjit`, `code/vs_wfg3.genjit`**

The WFG gen is a node-based patcher (not a codebox). Key architectural points:

**Params declared:**
- `param freq 6.` — spatial frequency (default 6)
- `param fm 0.` — FM amount (modulates freq via incoming signal)
- `param pm 0.` — PM amount (modulates phase via incoming signal)
- `param pw 0.5` — pulse width
- `param pwm 0.` — pulse width modulation
- `param ph 0.` — phase offset
- `param time 0.` — time signal (driven externally by `vs_newTime`)
- `param sync_lock 1` — sync mode (4-position selector)

**Signal flow:**
1. `norm` (UV) → aspect correction via `gen @file vs_fixAspect` (inline subpatcher)
2. Aspect-corrected UV → x component extracted via `swiz x`
3. x × freq → base spatial frequency
4. FM signal (in 2) × fm → frequency modulation → (+ 1) → frequency multiplier
5. freq × FM multiplier → modulated frequency
6. PM signal (in 3) × pm → phase modulation
7. time (param) added → animation
8. phase (param ph) added → phase offset
9. All summed → `fract` (wraps to [0,1])
10. → sine subpatcher (x × TWOPI → sin → × 0.5 → + 0.5) → [0,1] output
11. out 1 = waveform value (RGBA, broadcast across all channels via `vec 1`)
12. out 2 = `!- 1` (inverted) — Kevin always outputs both normal and inverted

**Key insight:** The WFG outputs **two** channels — normal and inverted. This is a consistent pattern across the WFG family. f_ patches receiving WFG output can use either polarity.

**Aspect correction:** Kevin uses a dedicated inline subpatcher (`gen fix_aspect_ratio`) rather than the manual `dim.x / dim.y` approach used in f_. The subpatcher takes norm + dim as vec2 inputs, extracts x/y components, computes x / (x/y ratio), and reconstructs a vec2. Result: aspect-correct spatial coordinates, not just aspect-correct x scalar.

**Sync lock selector:** `selector 4` with `param sync_lock 1` — four sync modes selectable at runtime. The `sync_lock` param selects which of 4 signals drives the time input. Mode 1 is the default (x component of aspect-corrected UV, scaled by freq).

**wfg3 additions over wfg_sine:**
- `+ rotation` after aspect correction — adds a rotation parameter directly in the UV transform rather than as a phase offset
- `clamp 0. 1.` on shape — shape param is bounded
- `clamp 1. 2.` on another internal signal — suggesting the wfg3 has additional waveform-shaping logic not present in basic wfg_sine

---

## Pattern: Tier 3 Feedback via Two jit.gl.pix Instances

**Source: `patchers/vs_feedback.maxpat`**

Vsynth's `vs_feedback` does **not** use a ping-pong texture with `jit.gl.asyncread` and a CPU round-trip. Instead it uses **two `jit.gl.pix vsynth` instances** within the same GL context.

**Architecture:**
- `obj-19`: `jit.gl.pix vsynth @type char` — 2-inlet gen patcher. Takes `in 1` (incoming texture) and `in 2` (feedback signal). Gen codebox: `mix(in1, max(in1, in2), amt)`. This is the feedback mixing node — blends fresh input with feedback signal by amt.
- `obj-13`: `jit.gl.pix vsynth` — 1-inlet passthrough gen. Simply passes its input to out 1. This is the readback node — it samples the result of the mixing node one frame later.

**Signal flow:**
```
inlet → routepass → pix_19 in0 (fresh texture)
pix_13 out0 → pix_19 in1 (previous frame — feedback loop)
pix_19 out0 → pix_13 in0 (current output → becomes next frame's feedback)
pix_19 out0 → bpatcher outlet (texture out)
```

**The key insight:** Within a single Vsynth GL render pass, `jit.gl.pix` objects can read each other's outputs because they draw sequentially into the same named context. The "previous frame" isn't explicitly stored — it's simply that `pix_13` drew first (last render cycle) and `pix_19` samples it in the current cycle. The ordering of draw calls within `vsynth` context determines which is "old" and which is "new."

**Feedback codebox (pix_19):**
```glsl
// in1 = fresh texture, in2 = feedback (previous frame output)
// max(in1, in2) = take the brighter of the two at each pixel
// mix(..., amt) = blend between unaffected input and feedback-brightened result
out = mix(sample(in1, norm), max(sample(in1, norm), sample(in2, norm)), amt)
```

**`vs_bline` usage:** The `amt` control signal passes through `vs_bline` before `prepend amt`. Confirms vs_bline is a smoothing abstraction — prevents stepping on feedback amount changes.

**`@type char`:** The feedback pix uses `@type char` (8-bit integer output) rather than float. This means the feedback path is quantized to 8-bit precision — intentional choice that introduces quantization artifacts and floor noise that are part of the feedback aesthetic.

**Implications for f_:**
- True frame-to-frame state in f_ patches is achievable using the same two-pix pattern within the vsynth context
- No CPU readback required — purely GPU
- Draw order within the vsynth context determines temporal relationship
- `@type char` quantization is a creative choice, not a technical requirement
- This is the architecture to use for `f_cymascope` (FDTD wave propagation) if it proceeds

---

## Pattern: Parameter Smoothing via vs_bline

**Where used:** `vs_feedback` amt parameter, likely other modules.

**Mechanism:** Sits in the control path between a live.dial outlet and `prepend param`. Smooths discrete value changes into a continuous ramp. Prevents audible/visible stepping on parameter automation.

**f_ position:** f_ does not currently use `vs_bline`. Direct wiring from live.dial → prepend param produces stepped changes. For most parameters this is fine. For parameters where smooth transitions matter (feedback amount, blend ratios), adopting `vs_bline` would improve behavior.

---

## Pattern: Aspect Correction in Gen

**Where used:** All WFG gen implementations (via `gen @file vs_fixAspect` inline subpatcher).

**Mechanism:** Dedicated inline gen subpatcher that takes `norm` (vec2) and `dim` (vec2), extracts x/y via `swiz`, computes `x / (x/y)` (i.e. aspect ratio correction), and reconstructs a vec2. Result: coordinates that are square in pixel space even at non-square render dimensions.

**f_ current approach:** Manual `aspect = dim.x / dim.y; px = norm.x * aspect;` in codebox. Equivalent result, different implementation style. Kevin's subpatcher approach is reusable and cleaner for node-based gen. For codebox-based f_, the manual approach is fine.

---

## Pattern: Dual Output (Normal + Inverted)

**Where used:** WFG gen implementations.

**Mechanism:** Every WFG gen outputs two signals: `out 1` = waveform [0,1], `out 2` = inverted (`!- 1` = `1 - x`). The outer patcher (vs_wfg_3.maxpat) routes these to separate outlets for use in modulation chains.

**Implication for f_:** When receiving a WFG texture, both the texture and its inverse are available. Not currently exploited in f_ design — a texture inlet could expose a polarity toggle to select which the codebox uses.

---

*Populated: 2026-05-31 (first analysis pass)*
*Last updated: 2026-05-31*
