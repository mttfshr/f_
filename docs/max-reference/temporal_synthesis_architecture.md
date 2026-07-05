# Temporal Synthesis — Architecture Discovery

_Last updated: 2026-06-09_
_Status: Discovery complete. Findings from reading vs_chemical_osc, vs_feedback, vs_filter_temp, vs_frame_delay._

---

## The core finding

Temporal state in Vsynth/jit.gl.pix is managed through **direct pix-to-pix feedback wiring**. One pix object reads a previous frame's output by receiving the output of another pix object as its input — and that second object's output is also fed back as the first's input.

**Sharpened 2026-07-01** (see `jit_gl_pass_architecture.md` and HANDOFF.md
for the full research thread): the one-frame latency here is a property of
**closing a feedback loop specifically, not a general property of the GL
texture pipeline.** Both `jit.gl.slab` and `jit.gl.pix` copy their incoming
texture rather than binding to it by reference — this is what prevents a
feedback loop from becoming an infinite instantaneous regress, and it's
*that* copy-on-cycle behavior that produces the one-frame settle, not
texture handoff in general. A straight-line forward chain (A→B→C, nothing
feeding back to an earlier point) has no such structural requirement and
is not expected to carry the same delay — confirmed both by `jit.gl.pix`'s
documented default `thru` behavior (synchronous output when input is
received) and by the fact that every existing f_ *processor* module
already chains `jit.gl.pix` objects sampling an upstream inlet in
production, with no observed frame-lag artifact. If forward chaining
carried an inherent delay, it would show up as a full frame of lag on
every processor module in the library, not just in an edge-case test.

**Practical takeaway:** when building something that *needs* the delay
(temporal state, exactly what this doc is about), close the loop as
described below. When building something that must *not* have a delay
(e.g. a forward multi-pass chain within a single frame, as in
f_stereogram's strip algorithm), a straight non-cyclic chain should be
safe — the delay is a loop property, not a chaining property.

The GL texture pipeline being naturally stable across this loop is what
makes Pattern 1 below work with nothing more than a wire — no special
"ping-pong" object, no explicit texture buffer management for the simple
case.

---

## Pattern 1 — Chained pix feedback loop (the fundamental pattern)

Used in: **vs_chemical_osc (p TEMPORAL)**, **vs_feedback**, **vs_filter_temp**

```
pass_pix (1 in, 1 out) — identity or trivial transform
    ↓ out0
slide_pix (2 in, 1 out) — computes new state from current input + previous state
    ↓ out0
    ↑ in1 (feedback: previous slide_pix output)
    ↑ in0 (current input from upstream)
```

**How it works:**

- `pass_pix` is a simple pass-through: `out1 = in1`. Its role is to hold the current frame's output as a stable texture reference for the next frame.
- `slide_pix` does the actual computation. It receives:
  - `in1` — the current frame's input (upstream texture or control signal)
  - `in2` — the previous frame's `slide_pix` output (fed back from `pass_pix`)
- The GL pipeline's one-frame latency means `in2` is always one frame behind — exactly what temporal synthesis needs.

**The slide codebox (from vs_chemical_osc / vs_filter_temp):**
```
// Temporal low-pass (exponential moving average):
param attack 0.1
+ in2        // current + previous
- in2        // difference = (current - previous)
* attack     // scale difference by attack coefficient
             // result: previous + attack * (current - previous)
out 1
```

This is a first-order IIR filter per pixel. `attack` = 1.0 → instant response (no memory). `attack` = 0.0 → frozen (no update).

**vs_filter_temp** is the clearest implementation: two chained pix pairs (one char, one float32), producing both lowpass and highpass outputs from the same temporal filter. The slide codebox there also produces a highpass output: `lp + hp = input`, so `hp = input - lp`.

**vs_feedback** uses the same pattern but the slide codebox does: `mix(input, max(input, previous), amt)` — feedback with accumulation rather than filtering.

---

## Pattern 2 — jit.gl.textureset (multi-frame delay)

Used in: **vs_frame_delay**

`jit.gl.textureset.js` manages a ring buffer of named textures. It provides N frames of history — not just one. The pix objects read from specific named slots in the set.

This is the architecture for:
- Variable-length frame delay (playback at arbitrary points in history)
- Anything needing more than one historical frame (e.g. FDTD's u[t-1] and u[t])

**vs_frame_delay wiring sketch:**
```
input → pass_pix → textureset.js (manages ring buffer)
                         ↓ named texture slot(s)
               crossfade_pix (mixes current and delayed)
                         ↓ output
```

The textureset JS object handles the ring buffer mechanics; pix objects read from it by texture name.

---

## Pattern 3 — Single pix self-loop (implied, not confirmed in Vsynth)

Theoretically: a single `jit.gl.pix` with its own output wired back to one of its inlets. Not observed in Vsynth source — Kevin always uses the pass_pix intermediary. The intermediary likely exists to ensure stable texture reference across the frame boundary. **Do not attempt single-pix self-loop without testing.**

---

## What this means for each idea

### f_vf_advect (Pattern 1 — one historical frame)

Simple case. Two chained pix:
- `pass_pix` — identity, holds current advected output
- `advect_pix` — `sample(previous_frame, uv - field * dt) * decay + source * injection`

The vecfield comes in as a third inlet (standard mod_inlet, no vs_inState needed — zero field = no advection, correct behavior). The source image is in0 (standard processor inlet). Previous frame is in2 (feedback from pass_pix).

**Fits cleanly into the f_ bpatcher model** with two jit.gl.pix objects inside one bpatcher. No new infrastructure needed.

### f_cymascope (Pattern 1 or 2 — two historical frames)

FDTD needs u[t-1] and u[t] to compute u[t+1]. Two options:

**Option A — Two chained pass_pix (Pattern 1 extended):**
```
pass_pix_A (holds u[t-1]) ← fed by pass_pix_B
pass_pix_B (holds u[t])   ← fed by fdtd_pix
fdtd_pix — reads in1=u[t] (from pass_pix_B), in2=u[t-1] (from pass_pix_A)
```
Three chained pix objects. Manageable.

**Option B — textureset with depth=2 (Pattern 2):**
Let textureset handle the ring buffer. Cleaner conceptually but adds JS dependency.

Option A is probably simpler to implement and debug. Revisit if three-pix wiring becomes unwieldy.

### f_vf_smear (Pattern 1, iterative passes)

Single-pass LIC is worth prototyping first — may not need temporal state at all (uses procedural noise convolved along streamlines, all computed per-frame). Try single-pass before committing to multipass. If multipass is needed, it's the same Pattern 1 structure but the feedback accumulates streamline integration steps rather than frame-to-frame time.

### f_weave — collision/phase disruption framing

The traveling-wave collision model would need phase state per pixel — accumulated phase from crossing events. **This is Pattern 1** if implemented: a phase accumulation pix reading its own previous state. However, worth questioning whether this complexity is necessary for v1 weave — the band-structure model is fully single-pass and expressive without it.

### f_ganzflicker / f_dreamachine — phase-coherent oscillation

A phase-coherent Hz oscillator needs frame-to-frame phase accumulation: `phase[t] = phase[t-1] + (hz / framerate)`. This is the simplest possible Pattern 1 use — a single float (not a texture) being accumulated. In Max this is more naturally a `phasor~` → `jit.op @op *` → color scaling rather than a pix feedback loop. The temporal state lives in the audio/signal domain, not the texture domain. **Not a ping-pong texture problem.**

### f_util_envelope — temporal smoothing

`vs_envelope` uses `jit.gl.asyncread` to pull a scalar from a texture into Max's control domain, then uses Max objects (`bline`) for smoothing. The temporal state lives in Max's scheduler, not in a texture. Pattern 1 could work (per-pixel temporal filter applied to the texture before readback), but for a scalar envelope `bline` or `slide` in Max is simpler. **Not necessarily a texture feedback problem.**

---

## Bpatcher integration constraints

- **Multiple jit.gl.pix inside one bpatcher is fine** — Kevin does this in every temporal patch. They share the `vsynth` context by virtue of being in the same render context.
- **The `@name` attribute must be unique per pix** — use `{prefix}_pass` and `{prefix}_state` or similar. Collisions between bpatcher instances would be a problem. This is the same constraint as the existing single-pix modules.
- **The pass_pix doesn't need UI wiring** — it's purely internal plumbing. No `route` outlet, no `param_connect`. Just a wire.
- **build_patcher.py will need extension** for multi-pix bpatchers. The current schema assumes one jit.gl.pix per bpatcher. For temporal synthesis modules, the definition will need to express multiple pix objects with their wiring. This is a build system question to resolve when speccing the first temporal module — probably f_vf_advect.

---

## Recommended build sequence

1. ~~**f_vf_advect** — probe module; Pattern 1, one historical frame, no
   physics model.~~ **Built and shipped** — established the multi-pix
   bpatcher convention this doc predicted would be needed.
2. **f_cymascope** — Pattern 1 extended (three pix), FDTD physics. Not
   started as of this update.
3. **f_vf_smear** — try single-pass LIC first; fall back to Pattern 1 if
   insufficient. Not started as of this update.
4. **f_weave collision model** — only if the band-structure v1 is
   insufficient; significant additional complexity. Not started as of
   this update; current v1 (band-structure) has been sufficient so far.
