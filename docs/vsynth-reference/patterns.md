# Vsynth Pattern Library

**Status:** Populated from analysis pass, 2026-05-31.

**Purpose:** Recurring architectural patterns Kevin uses in Vsynth internals. Answers "how does Kevin solve X?" and "should f_ do the same?"

---

## Pattern: Dual-Mode via vs_inState

**Where used:** Any module that behaves differently depending on whether an upstream texture is connected. `vs_displacement` uses **five** `vs_inState` instances — one per modulation inlet — confirming this is a standard pattern for optional inlets, not just for source/processor switching.

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

**Extended use case (from vs_displacement):** Kevin uses `vs_inState` on every optional modulation inlet, not just the primary texture. Each optional modulation input (fmx, fmy, rotm, zoom_m, etc.) has its own `vs_inState`. When unconnected, the fallback `vs_black` keeps the param at zero modulation. This is the clean pattern for any f_ patch that wants optional texture modulation on parameters — no manual connection detection needed.

---

## Pattern: Parameter Range Switching via vs_range

**Where used:** WFG family and other modules with dual or triple parameter ranges (e.g. `freq [0-1000] [0-10000]`).

**Mechanism:** `vs_range` abstraction takes integer 0/1/2, outputs `_parameter_range min max` message to the live.dial. Range values set as patcherargs. A range-select control drives the inlet.

**Why it matters for f_:** f_ hardcodes param ranges in the definition file. If a param needs runtime range switching, `vs_range` is the pattern. Relevant for: any frequency param with both a useful sub-range and wide range.

---

## Pattern: Global Enable via vs_canvas / vs_canvasLFO

**Where used:** All Vsynth modules.

**Mechanism:** `vs_canvas` wraps the module's enable/disable gate. Listens to `r canvas` global receive so all modules can be globally toggled. `vs_canvasLFO` variant for LFO parameters separately.

**f_ position:** f_ uses `bypass` (per-module) rather than `enable` (global). These are different things — bypass passes input through, enable stops the module entirely. f_ doesn't use `vs_canvas` and shouldn't — the bypass pattern is better for performance use. But `r canvas` explains why Kevin's modules respond to a global enable that f_ modules wouldn't.

---

## Pattern: WFG Signal Architecture

**Source: `code/vs_wfg_sine.genjit`, `code/vs_wfg3.genjit`**

Node-based gen patcher (not codebox). Key architecture:

**Params declared:**
- `param freq 6.` — spatial frequency
- `param fm 0.` — FM amount (modulates freq via incoming texture)
- `param pm 0.` — PM amount (modulates phase via incoming texture)
- `param pw 0.5` — pulse width
- `param pwm 0.` — pulse width modulation
- `param ph 0.` — phase offset
- `param time 0.` — time signal (driven externally by `vs_newTime` abstraction)
- `param sync_lock 1` — sync mode (4-position selector)

**Signal flow summary:**
1. `norm` + `dim` → `gen fix_aspect_ratio` inline subpatcher → aspect-correct UV
2. UV.x × freq → base spatial frequency
3. Incoming signal (in 2) × fm → (+1) → frequency multiplier
4. Incoming signal (in 3) × pm → phase modulation
5. All terms summed → `fract` (wraps to [0,1])
6. → sine subgen: x × TWOPI → sin → ×0.5 → +0.5 → [0,1] output
7. `out 1` = waveform value (broadcast across RGBA via `vec 1`)
8. `out 2` = `1 - out1` (inverted) — always present

**Dual output:** Every WFG gen outputs both normal and inverted waveform. The outer patcher routes these to separate outlets. f_ patches receiving WFG texture can use either polarity — currently unexploited.

**Aspect correction:** Dedicated inline gen subpatcher `fix_aspect_ratio`, takes norm (vec2) + dim (vec2), computes aspect-corrected UV as vec2. Kevin's reusable approach vs. f_'s manual `dim.x/dim.y` in codebox — functionally equivalent.

**wfg3 vs wfg_sine:** wfg3 adds `+ rotation` directly in the UV transform, `clamp 0. 1.` on shape, and additional waveform-shaping logic. wfg3 is the full-featured variant; wfg_sine is the base implementation.

---

## Pattern: Displacement Architecture

**Source: `patchers/vs_displacement.maxpat`**

The Displacement module is a **processor with multiple optional modulation inlets**, not a simple 2-inlet patcher. Key points:

**Inlets (bpatcher level):**
- in 0: primary texture + control (routepass)
- in 1–4: optional modulation textures (fmx, fmy, rotm/angle_m, zoom_m) — each wrapped in `vs_inState`

**Parameters in gen subpatcher:**
- `param zoom 1.` — scale (default 1 = no scaling)
- `param zoom_m 0.` — zoom modulation amount (from texture)
- `param angle 0` — rotation angle
- `param angle_m 0.` — angle modulation amount (from texture)
- `param fmx 0.` — x-axis frequency modulation
- `param fmy 0.` — y-axis frequency modulation
- `param off 0 0` — x/y offset (vec2)
- `param mode` — polar/bipolar mode selector
- `param a_lock 0` — angle lock
- `param clear 2` — boundary mode
- `param boundmode 1` — boundary handling

**Displacement math (gen subpatcher):**
1. `norm` → `swiz x` / `swiz y` → separate UV components
2. UV × zoom → scale
3. Optional texture (in 4 via vs_inState) × zoom_m → additive zoom modulation
4. UV fed through `poltocar` (polar-to-cartesian) — displacement field is defined in polar space
5. Rotation via angle param — applied as vec2 rotation
6. x and y displacement values from texture (in 2, in 3 via vs_inState) → scaled by fmx/fmy
7. `scale 0. 1. -1. 1.` on modulation texture values — remaps [0,1] texture values to [-1,1] bipolar displacement
8. All displacement terms summed → added to UV → `sample(in1, displaced_uv)`
9. Boundary mode applied: Clear/Clamp/Wrap/Mirror (4 modes)

**Key architectural insight for f_:** The displacement field is in **polar space** internally (`poltocar`). Texture modulation of displacement parameters maps [0,1] texture values to [-1,1] via `scale 0. 1. -1. 1.`. This is the standard remapping pattern — any f_ patch receiving a texture for bipolar modulation should do the same remapping. `vs_bline` is used on x and y params (smooth displacement changes), `vs_bline` also appears on the zoom modulation path.

**`param mode` (polar/bipolar):** Controls whether displacement interprets the modulation texture as unipolar (0 to max) or bipolar (-max to +max). Two `selector` objects in gen switch between the interpretations.

---

## Pattern: Tier 3 Feedback via Two jit.gl.pix Instances

**Source: `patchers/vs_feedback.maxpat`**

Vsynth's `vs_feedback` uses **two `jit.gl.pix vsynth` instances** within the same GL context — no CPU readback, no ping-pong texture swap.

**Architecture:**
- `pix_mixing` (`@type char`): 2-inlet gen. Mixes fresh input with previous frame output. Codebox: `mix(in1, max(in1, in2), amt)`
- `pix_passthrough`: 1-inlet passthrough gen. Reads the mixing pix output — which was the *prior render cycle's* result.

**Signal flow:**
```
inlet texture → pix_mixing in0 (fresh)
pix_passthrough out → pix_mixing in1 (previous frame)
pix_mixing out → pix_passthrough in (current output → next frame's feedback)
pix_mixing out → bpatcher outlet
```

**The mechanism:** Within one Vsynth GL render pass, `jit.gl.pix` objects draw sequentially into the named context. `pix_passthrough` drew first (last cycle); `pix_mixing` samples it this cycle. No explicit frame store — draw order is the temporal mechanism.

**`@type char`:** 8-bit integer output on the feedback path. Quantization is intentional — part of the feedback aesthetic.

**`vs_bline` on amt:** Parameter smoothing on the feedback amount control — prevents stepping on automation.

**Implication for f_cymascope:** This exact pattern enables FDTD wave propagation within Vsynth. Two-pix draw order = frame memory. Feasibility confirmed.

---

## Pattern: Parameter Smoothing via vs_bline

**Source: `patchers/abstractions/vs_bline.maxpat`**

`vs_bline` wraps Max's built-in `bline` object (breakpoint line interpolator) with draw-sync and optional numbering.

**Mechanism:**
- Inlet receives float value
- Value → `pak f 6` (packages with interpolation time of 6) → `bline 0.`
- `bline` is driven by `r draw` (per-frame bang via gate) — ensures interpolation steps are frame-synced, not time-based
- The `gate` opens on value change (detected via `change`) — **only drives bline while interpolating**, stops when destination is reached
- Outlet 0: smoothed float value
- Outlet 1: `done` bang when bline reaches destination

Kevin's comment in the patcher: *"Avoid [render] to keep triggering [bline] after reaching destination"* — explains why he gates the draw signal rather than always driving it.

**Optional numbering:** `patcherargs` allows passing a name; if provided, outputs `prepend <name>` message on a second outlet — useful for bundling multiple smoothed params into named messages.

**`@gen` file swapping:** The blendmode mixer uses `jit.gl.pix vsynth @gen vs_bm_add.genjit @type char` — the gen is specified by filename at the object level, not hardcoded. This is how Kevin implements selectable operations without subpatcher switching — he swaps the gen file at runtime. f_ doesn't currently use this pattern but it's relevant for op-selector modules.

**f_ adoption:** f_ doesn't use `vs_bline`. For most f_ params, direct live.dial → prepend is fine. For feedback-amount or blend-ratio params where smooth automation matters, `vs_bline` is the right addition.

---

## Pattern: Compositing — Multi-Inlet Texture Mixing

**From: `vs_mixer_3.maxpat`, `vs_blendmode_mixer.maxpat`, `vs_alpha_blend.maxpat`**

**vs_mixer_3:** 3-input weighted mix. Params: `in1`, `in2`, `in3` (level per channel, 0–1), `master` (overall). Gen: `jit.gl.pix vsynth @adapt 0 @type char` with 4 inlets (3 textures + control). `@adapt 0` — does not auto-adapt to input dimensions (fixed output size). 

**vs_blendmode_mixer:** 2-input with selectable blend mode. Params: `in1`, `in2`, `master`, `blend_mode`. Uses `jit.gl.pix vsynth @gen vs_bm_add.genjit @type char` — gen file swapped at runtime to change blend mode. Routes to one of 13 blend mode gens (absdiff, add, alpha, avg, exclude, max, min, mod, mult, negate, screen, sub).

**vs_alpha_blend:** 3 inlets — "Replace Blacks In", "Replace Whites In", "Alpha Texture In". The alpha texture drives the mix between the two content textures. Uses the alpha channel of the third texture as the blend key.

**Key observations for capability map:**
- Vsynth has comprehensive compositing already: weighted mix (3ch, 6ch), all standard blend modes, alpha keying, luma keying, chroma keying, crossfade, quad crossfade
- f_ should not replicate any of these
- f_ textures output to Vsynth, then compositing happens in Vsynth's own modules
- The only gap would be compositing operations that require patch-specific knowledge (e.g. f_grain's luma gate, which is internal to the grain placement logic)

---

## Pattern: Aspect Correction in Gen

**Where used:** All WFG gen implementations via `gen @file vs_fixAspect` inline subpatcher.

**Mechanism:** Inline gen subpatcher takes `norm` (vec2) and `dim` (vec2), extracts components via `swiz`, computes aspect ratio correction, reconstructs vec2. Result: square pixel-space coordinates at any render dimension.

**f_ current approach:** Manual `aspect = dim.x / dim.y; px = norm.x * aspect;` in codebox. Functionally equivalent. Kevin's subpatcher is reusable across node-based gens; f_'s codebox approach is fine for codebox-based patches.

## Pattern: Two Tier 3 Mechanisms — Draw Order vs. Texture Set

**Source: `vs_feedback.maxpat`, `vs_filter_temp.maxpat`, `vs_frame_delay.maxpat`, `vs_chemical_osc.maxpat`**

Vsynth uses two distinct Tier 3 mechanisms depending on how many frames of delay are needed:

**Mechanism 1: Draw-order frame memory (most common)**
Multiple `jit.gl.pix vsynth` instances in the same named context. Sequential draw order means pix_A's output from the prior cycle is readable by pix_B in the current cycle. Minimum delay: exactly 1 frame. Used by: `vs_feedback`, `vs_filter_temp`, likely `vs_differentiator`. `vs_chemical_osc` extends this to 8 pix instances for a full multi-pass pipeline within one GL context — slide, color, blur ×2, rotation, and additional processing, all chained by draw order.

**Mechanism 2: jit.gl.textureset.js (explicit buffer)**
A JavaScript object that manages a named set of GL textures explicitly. Enables arbitrary delay depth (not just 1 frame). Used by `vs_frame_delay` which needs user-configurable delay times. Higher overhead than draw-order method but more flexible.

**Implication for f_cymascope (FDTD):** Draw-order mechanism is the right choice — FDTD needs exactly 1-frame delay (previous wave state → current computation). The chemical oscillator's 8-pix pipeline confirms that complex multi-pass algorithms are viable within a single named context.

---

## Pattern: WFG as Modulation Source (Full Architecture)

**Source: `vs_wfg_3.maxpat` outer patcher**

The WFG patcher's inlet/outlet contract, confirmed:

**Inlets (3):**
1. FM In / Control In — texture for frequency modulation + all control messages
2. PM In — texture for phase modulation
3. PWM In — texture for pulse width modulation

**Outlets (2):**
1. Texture Out — waveform [0,1] as RGBA float32
2. Inverted Texture Out — `1 - waveform` [0,1] as RGBA float32

**`@type float32`:** WFG output is full 32-bit float, not 8-bit char. This preserves precision for use as a modulation source — essential when the WFG output drives displacement amounts or phase offsets in downstream patches.

**Smoothing:** Every controllable WFG parameter goes through `vs_bline` before reaching the gen param — freq, fm, pm, speed, bias all smoothed. This is why WFG parameter changes feel gradual in performance.

**All three modulation inlets use `vs_inState`:** When FM, PM, or PWM inlets are unconnected, `vs_black` fallback keeps modulation at zero. WFG works as a pure spatial/temporal oscillator with no modulation when used standalone.

**Gen swapping:** `gen vs_wfg3.genjit` vs `gen vs_wfg3_pow.genjit` — two implementations of the same parameter surface, selectable at the patcher level. Likely `_pow` variant applies power-law shaping to the waveform. Same inlet/outlet contract, different math.

**f_ implications:**
- When receiving WFG output, both normal and inverted are available — no need to invert in codebox
- The WFG already does all modulation input handling (FM, PM, PWM) with full `vs_inState` per inlet — f_ patches that receive WFG output don't need to handle modulation, just sample the result
- `@type float32` means WFG values arriving at f_ texture inlets are precise floats, not quantized — sample them directly for modulation without rescaling for quantization

---

*Populated: 2026-05-31 (analysis complete)*
*Last updated: 2026-06-30*

---

## Pattern: jit.gl.node @capture for Render-to-Texture within Vsynth

**Source: Kevin's tutorial "Capture with jit.gl.node to mix Vsynth with 3D content"**

`jit.gl.node vsynth @capture 1` renders its sub-context to an internal
texture, outputting a `jit_gl_texture` message from its left outlet each frame.
This is a first-class Vsynth pattern — Kevin uses it in a documented tutorial.

```
jit.gl.node vsynth @capture 1 @erase_color 0 0 0 0 @fsaa 1 @adapt 0
```

- `vsynth` = parent context
- `@capture 1` = render to texture
- `@erase_color 0 0 0 0` = transparent background (required for correct compositing)
- `@fsaa 1` = anti-aliasing on capture
- `@adapt 0` / `@adapt 1` = fixed vs. input-matched output dimensions

The captured texture outlet feeds directly into `vs_op2` or any other Vsynth
module inlet. `jit.gl.pix` and 3D objects inside the node use the node's name
as their `drawto` attribute.

**Intra-frame ordering:** Multiple nodes at different `@layer` values draw in
layer order *within a single frame* with no inter-frame delay. Confirmed by
C74 staff (Rob Ramirez) and empirically verified. This enables multi-pass
intra-frame algorithms (e.g. autostereogram strip generation) that are
impossible with draw-order chaining between `jit.gl.pix vsynth` instances
(which always have a 1-frame delay). See
`docs/intraframe_multipass_architecture.md` for full pattern.

---

## Pattern: Sibling Render Context Synchronized to Vsynth

**Source: Kevin's tutorial "Shows how to make your render context child of Vsynth"**

For a *separate* output window synchronized to Vsynth's frame rate — e.g.
second projector output, separate display — rather than embedding within the
`vsynth` context:

```
r draw                     ← Vsynth publishes a draw bang every frame via s draw
  ↓
t b b erase
  ├── s your_context_draw  ← drive your context's draw
  └── [erase] → jit.gl.render your_context_name @erase_color 0. 0. 0. 1.

jit.window your_context_name @shared 1 @pos X Y
                            ← @shared 1 = shares OpenGL context with Vsynth
                              (texture names valid across both contexts)

[vsynth texture] → jit.gl.cornerpin your_context_name @preserve_aspect 1 ...
                            ← display Vsynth content in your window
```

**`r draw`:** Vsynth's render loop publishes a global bang via a named send
every frame. Any patch can receive it to drive a synchronized sibling context.
This is the global timing signal for anything outside the `vsynth` context.

**`@shared 1`:** Without this, texture names from the `vsynth` context are
not valid references in the sibling window's context.

**Distinct from `jit.gl.node @capture`:** That pattern embeds *within* the
`vsynth` context. This pattern creates a *sibling* context driven by Vsynth's
clock. Use this for separate output windows; use `jit.gl.node @capture` for
multi-pass rendering that feeds back into the Vsynth signal chain.
