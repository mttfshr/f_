# Spec: f_vf_advect

_Created: 2026-06-09_
_Status: Revised — vecfield suppression pattern corrected, open questions resolved_

---

## What it does

A temporal fluid advection processor for Vsynth. Each frame, samples the source texture from a position displaced *backwards* along the vector field — transporting accumulated color values forward through the field over time. With feedback this creates genuine flow: content injected into the field spreads, advects, and dissipates across many frames.

**Consumer in the f_vecfield family.** Expects a valid f_vecfield texture (float32, RG=XY, 0.5=zero vector) on the vecfield inlet. Compatible with any f_vf_ producer.

**Temporal processor — has memory.** Unlike f_vf_streak and f_vf_warp (stateless single-pass), f_vf_advect accumulates state across frames. Its visual character depends on history, not just the current input frame. This makes it expressive as a slow accumulator and fundamentally different in character from single-pass displacement.

**Architecture: two chained jit.gl.pix inside one bpatcher** (Pattern 1 from temporal synthesis discovery). `pass_pix` is an identity pix that holds the previous frame's advected output as a stable texture reference; `advect_pix` reads both the current source and the previous frame, computes the new advected state, and outputs it. The GL pipeline's one-frame latency makes the loop stable.

---

## Algorithm

At each pixel, each frame:

```
// 1. Look up field vector at current UV, remap from [0,1] to [-1,1]
field_xy = (sample(vecfield, uv).rg - 0.5) * 2.0

// 2. Compute backwards-displaced UV (where did this pixel come from?)
src_uv = uv - field_xy * dt

// 3. Sample previous frame's advected output at the displaced UV
advected = sample(previous_frame, src_uv) * decay

// 4. Mix with source injection
out = advected + sample(source, uv) * injection

// 5. Bypass blend
out = mix(out, sample(source, uv), bypass)
```

**Why backwards displacement:** Forward advection (push color to destination) produces holes; backward advection (pull color from source) is continuous and artifact-free. Standard in fluid simulation and video warping.

**`dt` (advection step):** Scales the field vector before displacing. At `dt=0`, `src_uv = uv` — no advection, content decays in place. At `dt=1.0`, a unit-magnitude field vector displaces by one full UV unit per frame. Useful range is small (0–0.1) to prevent aliasing from large jumps.

**`decay` (frame retention):** Multiplied into the advected sample each frame. `1.0` = no decay, content persists indefinitely. `0.0` = previous frame fully discarded. Primary expressive lever for trail length vs responsiveness.

**`injection` (source bleed-in):** How much of the current source texture enters the flow each frame. `0.0` = no new input (flow carries only what was already there). `1.0` = fully additive injection (source constantly feeding in). At typical values, injection and decay reach equilibrium: `injection / (1 - decay)` is the steady-state amplitude.

**`mix` (wet/dry):** Final blend between the advected output and the raw source. Independently useful from injection: injection controls what enters the *flow*; mix controls how much of the *output* is the flow vs. the source. Allows strong accumulation in the flow while keeping the visual output close to the source, or vice versa.

---

## Inlets

| Inlet | Type | Label | Required | Description |
|---|---|---|---|---|
| 0 | texture + control | texture in | Yes | Source texture to advect; control messages on in0 |
| 1 | f_vecfield texture | vecfield | No | Flow field (float32, RG=XY, 0.5=zero vector) |

**Vecfield unconnected:** `vs_inState` delivers `vs_black` (all zeros) to the gen. After remap, `(0.0 - 0.5) * 2.0 = -1.0` — a non-zero displacement toward the top-left corner, not zero. This is incorrect silent behavior. Suppressed via a hidden `src_vecfield` system param (same pattern as f_vf_warp): `vs_inState` outlet 1 (0/1 connection state) wires to `prepend param src_vecfield → advect_pix in0`, and the codebox zeroes the displacement when `src_vecfield < 0.5`. When unconnected, content decays in place with no advection direction.

**Source unconnected:** `injection = 0` equivalent — no new content enters; accumulated state decays toward black over time.

---

## Parameters

| Param | UI | Range | Default | Notes |
|---|---|---|---|---|
| `dt` | live.dial | 0.0–0.05 | 0.01 | Advection step — how far content moves per frame. Small values give fluid feel; larger values give streak/displacement character. |
| `decay` | live.dial | 0.8–1.5 | 0.97 | Frame retention. Values >1.0 amplify rather than decay — excitable fluid territory. |
| `injection` | live.dial | 0.0–0.2 | 0.02 | Source bleed-in per frame. Fluid zone is 0.01–0.05; higher values give displacement character. |
| `mix` | live.dial | 0.0–1.5 | 1.0 | Wet/dry, extendable above 1.0 for amplified output. |
| `bypass` | bypass_toggle.js | 0/1 | 0 | Passes source texture unmodified; feedback loop stays warm. |

**Prefix:** `vfadvect`
**Object name:** `vfadvect_pix` (advect_pix), `vfadvect_pass` (pass_pix)
**Output type:** `@type char`

Hidden system params (not in UI, route, or parameters block):

| Param | Source | Notes |
|---|---|---|
| `src_vecfield` | vs_inState out1 on in1 | 0 = no field connected, 1 = connected. Suppresses displacement artifact from vs_black. |

---

## Internal Architecture

Two jit.gl.pix inside the bpatcher:

```
pass_pix  — @name vfadvect_pass @type char @adapt 1
              numinlets=1, gen: in1 → out1 (identity)

advect_pix — @name vfadvect_pix @type char @adapt 1
              numinlets=3 (source in0, vecfield in1, previous_frame in2)
              gen: in1=source, in2=vecfield, in3=previous_frame → codebox → out1
```

**Feedback wiring (inside bpatcher):**
```
advect_pix out0 → pass_pix in0       [current advected → held for next frame]
pass_pix out0   → advect_pix in2     [previous frame → feeds back into advect]
advect_pix out0 → bpatcher outlet 0  [output]
```

**Source and vecfield routing:**
```
bpatcher in0 → routepass → advect_pix in0     [source texture]
bpatcher in1 (vecfield) → vs_inState → advect_pix in1
```

---

## Signal Flow

```
in0 (texture + control) → routepass jit_gl_texture jit_matrix
  jit_gl_texture → advect_pix in0          [source texture, gen in1]
  unmatched → route dt decay injection mix → dials → attrui → advect_pix in0

in1 (vecfield) → vs_inState
  vs_inState out0 (texture or vs_black) → advect_pix in1   [gen in2]
  vs_inState out1 (0/1) → prepend param src_vecfield → advect_pix in0

pass_pix out0 → advect_pix in2             [previous frame, gen in3]
advect_pix out0 → pass_pix in0            [feedback]
advect_pix out0 → bpatcher outlet 0

bypass_toggle.js → attrui bypass → advect_pix in0
```

---

## Acceptance Criteria

- **Basic advection:** Connect a source texture to in0 and `f_vf_vortex` to in1. With default params, content should visibly flow along field streamlines over multiple frames — spiral accumulation around the vortex center.
- **dt control:** Increasing `dt` increases the apparent flow speed (larger displacements per frame). At `dt=0`, no advection — content decays in place.
- **decay control:** At `decay=1.0`, content persists indefinitely (no decay). At `decay=0.0`, each frame shows only freshly injected content — no persistence. Intermediate values produce trails of varying length.
- **injection control:** At `injection=0`, no new source content enters the flow. The accumulated state decays to black over time. At `injection=1.0`, source is strongly and continuously added to the flow.
- **mix control:** At `mix=0`, output is the raw source texture regardless of advection state. At `mix=1.0`, output is the full advected result. Intermediate values blend both.
- **Vecfield unconnected:** With in1 unconnected, output should show the source decaying in place — no directional drift or diagonal smear artifact from vs_black.
- **Source unconnected:** Accumulated state should decay to black; no crash.
- **Bypass:** With bypass enabled, output exactly matches the source texture. The feedback loop continues running (pass_pix still updates), so disabling bypass restores the accumulated state rather than resetting.
- **No vecfield producer needed:** Works expressively with any f_vf_ producer or with no field connected.
- **State stability:** No runaway accumulation (output doesn't blow out to white or black over time at default params). Equilibrium between injection and decay is reached and held.
- **Loads in Vsynth.** Survives save/load cycle without crashing. Two pix objects inside one bpatcher do not conflict.

---

## Out of Scope

- **Wrap/mirror at edge** — clamp-to-edge sufficient; streaks at boundary are a feature
- **Multiple advection steps per frame** — single-step per frame; higher visual quality via lower `dt` and multiple connected modules if needed
- **Divergence correction** — incompressible flow (mass conservation) not required; density variations are expressive
- **Color-dependent advection** — field applies uniformly across all channels
- **Reset trigger** — no explicit state clear; `decay=0` provides instant reset behavior
- **build_patcher.py multi-pix support** — build system extension is a plan-phase task; bpatcher may be hand-assembled or use a per-module build script until the extension is ready

---

## Open Questions

1. **`@adapt 1` on both pix:** Almost certainly required (confirmed from vs_frame_delay pattern). Verify in scratch — failure mode is black output at mismatched resolutions. Treat as a scratch-phase confirmation, not a design question.

2. **dt upper bound:** `0.1` is provisional. Revisit after scratch testing; changing the dial range is a trivial update.

---

## Reframe (2026-07-11): 3rd outlet — gradient of accumulated flow

### Correction to prior assumption

`ideas/dry_wet_gain_and_novel_field_outlet.md` originally called this
module the cleanest finding-4 pass in the library, reasoning from
HANDOFF's note about the reverted vorticity-confinement fold-in rather
than the current codebox. On direct read, the module's actual field
consumption (`fx,fy` — gated passthrough of the vecfield inlet, no
further computation) fails the novel-field test the same way
`f_vf_warp` does. The confinement work that would have made it novel is
exactly what got reverted. This spec addition is not "finish the
originally-planned 3rd outlet" — it's a new decision, made in light of
that correction (see finding 7 in the ideas doc for full reasoning).

### What's novel here instead

`result` (the accumulated color state, already outlet 2 — `advected`) is
genuinely temporal and novel, but it's a texture, not a vecfield. Two
vecfield-shaped candidates were considered:

- Temporally-smoothed input field (inertia/lag) — rejected, generic to
  any vecfield producer, not specific to advection; would also add a
  second feedback loop to a module where one feedback experiment
  (vorticity confinement) already failed and was reverted. Parked as its
  own idea: `ideas/f_vf_temporal_smooth.md`.
- **Gradient of the accumulated texture** — finite-difference `result`
  (same idiom as `f_vf_fieldmap`), turning the *shape* the flow has drawn
  into a direction field. Chosen: self-referential in a way nothing else
  in the library produces (patched back into another `f_vf_advect` or
  `f_vf_warp`, the flow can reshape its own future direction based on
  what it already drew), cheap (four extra samples on `result`, which
  the module already holds as `in3`'s next-frame source), no new pix
  stage or feedback wiring.

### New outlet

- Out 3: float32 f_vecfield — central-difference gradient of `result`
  (luma or per-channel, TBD in scratch — `result` is a char/RGB
  accumulation, not a scalar field like `f_chladni`'s `total`, so the
  gradient needs a luma-reduction step first, same as `f_vf_fieldmap`'s
  approach to an RGB source). Encoded RG float32, `0.5 = zero vector`,
  standard f_vecfield convention.
- No new param anticipated — reuses the same `scale`/step-size constant
  `f_vf_fieldmap` uses for its central difference, unless scratch testing
  shows advect's accumulated texture needs a different epsilon.
- Bypass behavior: neutral vecfield (`0.5, 0.5`), matching `f_vf_flow`'s
  bypass convention for vecfield outlets (not `f_vf_glow`'s black-on-
  bypass, since this outlet isn't an additive layer).

### Acceptance criteria (addition)

- Out 3 responds to accumulated structure, not instantaneous input —
  verify by holding a static source + field and confirming out3 changes
  shape as `result` builds up over several frames, not just per-frame
  with the input
- Out 3 is zero-ish (neutral `0.5,0.5`) when `result` is uniform/flat —
  confirms it's tracking gradient, not absolute state
- Routing out3 → another `f_vf_advect` or `f_vf_warp` produces visibly
  different behavior from routing the original input field to the same
  destination — confirms the outlet carries genuinely different
  information, not a rescaled copy
- No change to out1 (composite/mix) or out2 (advected) behavior — pure
  addition
- Bypass sets out3 to neutral, consistent with other vecfield-outlet
  bypass conventions in the library
