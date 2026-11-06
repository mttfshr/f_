# f_vf_potential

**Type:** Processor (f_vecfield consumer), temporal / has memory
**Status:** Working; maintenance-audited 2026-10-12, stable preflight 2026-11-06

---

## What it does

Scalar potential-field integrator. Takes a vecfield and accumulates its magnitude over time via ping-pong feedback (same two-`jit.gl.pix`-in-one-bpatcher pattern as `f_vf_advect`: an identity `pass` stage holds the previous frame, a `state` stage accumulates). Output is a scalar (grayscale; the internal 0–1 potential times strength, so it can exceed 1) that is bright where the field has been strong, and whose level sets (isolines) follow that history — designed to feed directly into `f_weave`'s scalar inlet to produce curved, field-informed isoline texture in place of `f_weave`'s straight-line default.

Typical chain: `f_vf_repulse → f_vf_potential → f_weave` (across or along inlet).

**Wiring: the vecfield goes to inlet 1, and inlet 0 needs a texture too.** Inlet 0 only triggers the frame: the codebox never reads it (`in1`). A vecfield on inlet 0 alone is ignored, and a vecfield on inlet 1 alone never runs (the pix fires from its left inlet; read from the patcher, not run). The simple wiring is one vecfield into both inlets 0 and 1. The output size follows inlet 0 (`@adapt`; inferred).

---

## Signal Flow

```
inlet 0 (any texture + control) → routepass → potential_pix in1   [trigger only, never sampled]
  unmatched control → route dt decay strength → dials → potential_pix
inlet 1 (vecfield, required) → vs_inState → potential_pix in2   [src_vecfield gate]
inlet 2 (color texture, optional) → vs_inState → potential_pix in3   [src_color gate]
bypass jsui → prepend param bypass_gate → potential_pix

pass_pix out0 → potential_pix in4   [previous frame, feedback]
potential_pix out0 → pass_pix in0   [feedback]
potential_pix out0 → out0 (scalar potential)
```

---

## Parameters

| Param | Range | Default | Description |
|---|---|---|---|
| `dt` | 0–0.05 | 0.01 | Accumulation step size per frame — larger = faster tracking |
| `decay` | 0.8–1.0 | 0.98 | Frame decay — lower = faster fade, higher = longer memory |
| `strength` | 0–2.0 | 1.0 | Output scale, and part of the feedback: the loop reads the scaled output, so the per-frame carry is `strength × decay`. Below 1 the trail fades much faster; from about 1/`decay` (1.02 at the default) it runs up to the clamp. |
| `src_vecfield`, `src_color` | internal | — | vs_inState connection gates; not user-facing |
| `bypass` | 0/1 | 0 | Panel toggle only: drives the codebox Param `bypass_gate`, output (0, 0, 0, 1). The route has no `bypass` selector, so a `bypass` message does nothing. |

**Prefix:** `vfpotential` — **Object names:** `#0_potential_pix` (accumulator), `#0_potential_pass` (identity feedback-hold stage)

---

## Notes

- Temporal module — has memory across frames, same architectural family as `f_vf_advect` (ping-pong `pass`/`state` pix pair, `@adapt` on both stages).
- **2026-10-12 maintenance audit:** `codebox_potential.gen` integrates field **magnitude** only (`field_mag = sqrt(fx² + fy²)` accumulated with `dt`/`decay`) — it does not integrate the vector path or direction. Correction, 2026-11-06: the increment is magnitude-only, but the backward-advect lookup of the previous frame depends on direction, so the module is **sign-sensitive**, not axis-blind, and `ideas/f_tensorfield.md` keeps it on the exclusion list (open question 11, confirmed 2026-10-16). The optional color inlet tints the final output per channel by mixing against a white base. Because the loop reads the output's red channel, the red tint also scales the carry, so a color with low red shortens the memory (mirror: `tests/modules/vf_potential`, feedback closed form).
- A uniform field accumulates a uniform value, so it gives no isolines away from the edges: the structure comes from variation in field strength (from the codebox and the mirror's uniform-field series).
- **Bypass behavior (audit finding):** bypassed, the module outputs the neutral (0,0,0,1), not an input passthrough, despite declaring archetype "processor" — the implicit `out1 == in1` contract check doesn't cover this module. Asserted by a BYPASS_EXPECT entry since 2026-11-06, when bypass moved from native `@bypass` to `bypass_gate`. The feedback loop reads this output, so bypass also clears the accumulated trail, which is fine (live by Matt, 2026-11-06).

## Source File

`package/patchers/f_vf_potential.maxpat`
