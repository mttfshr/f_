# f_vf_advect

**Type:** Processor (f_vecfield consumer) — **temporal / has memory**
**Status:** Complete

---

## What it does

Temporal fluid advection. Each frame, samples the source texture backward along the vecfield and feeds it through a one-frame feedback loop — content injected into the field spreads, advects, and dissipates across many frames rather than being displaced once. Unlike f_vf_streak/f_vf_warp (stateless single-pass), f_vf_advect's visual character depends on accumulated history, not just the current frame — genuinely excitable/amplifying at `decay > 1.0`.

Architecture: two chained `jit.gl.pix` inside one bpatcher (Pattern 1, shared with any other temporal f_ module) — `pass_pix` is an identity pix holding the previous frame's advected output as a stable texture reference (GL's one-frame pipeline latency makes this stable); `advect_pix` reads the source, the vecfield, and the previous frame, and computes the new state.

Compatible with any f_vf_ producer on the vecfield inlet.

---

## Signal Flow

```
in0 (texture + control) → routepass → advect_pix in0        [source, gen in1]
  unmatched → route dt decay injection strength → dials → prepend param <name> → advect_pix in0

in1 (vecfield) → vs_inState
  vs_inState out0 (texture or vs_black) → advect_pix in1     [gen in2]
  vs_inState out1 (0/1) → prepend param src_vecfield → advect_pix in0

pass_pix out0 → advect_pix in2                                [previous frame, gen in3]
advect_pix out0 → pass_pix in0                                [feedback]
advect_pix out0 → out0 (composite)
advect_pix out1 → out1 (advected, pre-mix)
```

`src_vecfield` suppresses the displacement artifact that `vs_black`'s all-zero fallback would otherwise introduce (a zero-texture sample remaps to `(-1,-1)`, a nonzero displacement toward the corner, not a neutral one) — same pattern as f_vf_warp/f_vf_streak's `src_vecfield`/`src_vecfield` suppression params.

---

## Parameters

| Param | Range | Default | Description |
|---|---|---|---|
| `dt` | 0–0.05 | 0.01 | Displacement step size per frame — larger = faster flow. UI range tiers: 0.05 / 0.5 / 1.0. |
| `decay` | 0.8–1.5 | 0.97 | Frame retention. <1.0 fades, >1.0 amplifies (excitable regime). |
| `injection` | 0–0.05 | 0.02 | Source bleed-in amount per frame. UI range tiers: 0.05 / 0.5 / 1.0. |
| `strength` | 0–1.5 | 0.0 | Wet/dry mix — 0 = source only, 1 = fully advected. Extends above 1.0 for amplified output. |
| `src_vecfield` | internal | — | Driven by vs_inState; suppresses vs_black displacement artifact. Not user-facing. |
| `bypass` | 0/1 | 0 | Passes source unmodified; feedback loop keeps running underneath (state isn't reset). |

**Prefix:** `vfadvect` — **Object names:** `vfadvect_pix` (advect stage), `vfadvect_pass` (identity feedback-hold stage)

---

## Algorithm

```
field_xy = (sample(vecfield, uv) - 0.5) * 2.0 * step(0.5, src_vecfield)   // suppressed when unconnected
src_uv   = uv - field_xy * dt
advected = sample(previous_frame, src_uv) * decay
out      = advected + sample(source, uv) * injection
composite = mix(source, out, strength)                                    // wet/dry
composite = mix(composite, source, bypass)
```

Backward displacement (pulling from source rather than pushing to destination) avoids holes and is the standard fluid-sim/video-warp convention. Steady-state amplitude at equilibrium is approximately `injection / (1 - decay)`.

---

## Notes

- `injection`/`decay` reach an equilibrium amplitude at typical settings — no runaway blowout at defaults, confirmed empirically.
- `strength` is the final wet/dry lever, independent of `injection`: `injection` controls what enters the flow; `strength` controls how much of the *output* is flow vs. raw source.
- Bypass does not reset the feedback loop — `pass_pix` keeps updating underneath, so disabling bypass resumes from the accumulated state rather than a fresh black frame.
- No wrap/mirror at the UV edge (clamp-to-edge); no divergence correction (incompressible-flow mass conservation is not enforced — density variation is treated as expressive, not a bug); no explicit reset trigger (`decay=0` gives an effective instant reset).
- `dt` upper bound (0.05 in `definition.py`, described as provisional 0.1 in spec.md) may still be revisited — a dial-range change only, not an architecture change.
- See `docs/f-reference/f_vecfield_type.md` for the f_vecfield type contract.
