# f_tf_smooth

**Type:** Processor (f_tensor in → f_tensor out)
**Status:** Draft — codebox tier-2 bench and tier-3 live judgement pending

---

## What it does

A **temporal tensor smoother** ("inertia") for the f_tensor family. It feeds
the raw structure tensor back onto itself across frames:

```
T'(k) = T(k) + release * (T'(k−1) − T(k))        per channel, in tensor space
```

Each pixel's tensor becomes the released average of the tensor it has been
seeing, so per-frame gradient jitter settles into a stable field while real
motion still tracks through. It sits between `f_tf_tensormap` and every
consumer: chain A is `tensormap → smooth → sharpen → aniso_blur`, and no
chain works on live video without this stabilizer stage.

**Why tensor space and not "temporal filter on a texture":** opposite axes
that trade places frame-to-frame (flicker between two edge camps) average
into a stable tensor rather than cancelling into mush, and the field carries
its confidence with it. Proven in the tier-1 mirror: a gradient that flips
sign every frame (the same edge seen from opposite ends) leaves the smoothed
tensor exactly unchanged, while a signed-vector (vecfield) one-pole on the
same alternation collapses to 25% of its magnitude within three frames
(`tests/modules/tf_smooth/test_tf_smooth.py`). Same argument the hub doc makes for tensor-space
spatial smoothing, applied over time.

**What it is not:** a new algorithm. `jit.fx.tp.filter` is shipped platform
coverage of the same two-pole recurrence math (`ideas/f_tf_research.md`
§4 source-read, `out2 = in0·a0 + in1·a1 + in2·a2 − in3·b1 − in4·b2`). This
module's contribution is semantics/integration: the one-knob performable
release gesture, the family's float32 guarantees, the exact f_tensor inlet
contract, and correct neutral behavior (`jit.fx.tp.filter` garbage-in-
garbage-outs on tensor data: no vs_black gate, audio-adjacent five-knob
interface, no @type guarantee).

Processor archetype, single outlet — the output type equals the input type,
which is what makes it chain-safe anywhere.

---

## Signal Flow

```
in0 (raw tensor + control) -> routepass -> state pix (primary)
     state pix in1 = this frame's tensor
     state pix in2 = previous blended tensor  <-+
     state pix out1 (blended) ------------------+   (feedback, next frame)
     state pix out1 -> render pix (passthrough) -> outlet 0
```

Two `jit.gl.pix` nodes in one bpatcher (the `f_vf_advect` two-domain
precedent): the **state pix** computes the recurrence and both writes it back
(feedback) and forwards it; the **render pix** is a passthrough that surfaces
the state texture to the module outlet. One feedback tap per channel; no
spatial sampling, no decode, no atan2 anywhere — the codeboxes are 4-channel
arithmetic only. Stateless-in, stateful-out: internal textures are unbounded
float32 and are never exposed as outlets.

---

## Parameters

| Param | Range | Default | Description |
|---|---|---|---|
| `release` | 0–1 | 0.5 (provisional) | Feedback coefficient. 0 = passthrough (neutral, no residue from frame 1). Higher = longer memory: 0.3 light, 0.5 default, 0.9 heavy inertia. Ride it from 0 (reactive) to 0.9+ (frozen-ish). |
| `bypass` | 0/1 | 0 | **Exact passthrough of the inlet tensor** — feedback ignored, NOT a freeze of the last smoothed frame. On an unconnected inlet the field decays naturally to the zero-tensor neutral instead of holding stale data. |

**Prefix:** `smooth` - **Object name:** `smooth_pix` (state) / render - **Type:** `@type float32`

`release` semantics: the tensor arriving each frame is trusted at face value
and only history is softened (release-only; there is no attack curve — attack
shaping would dull real structure and is the v2 door per spec Out of Scope).
Default 0.5 and the top of the range are **PROVISIONAL**: the OQ1 gate is
open pending tier-3 judgement on live noise (same discipline as tensormap's
strength calibration; the shipped default is the spec's provisional value).

**Decay behaviour** (the number to reason with, verified in the mirror): a
one-frame step from tensor A to constant B gives `out(k) = B + (A−B)·release^k`
per channel — release 0.5 halves the residual every frame; release 0.9 takes
~22 frames to reach 10% residual; release 0.99 is near-frozen (~1% per frame
decay, floats fine but visually static).

---

## Output

A raw f_tensor (`docs/f-reference/f_tensor_type.md`, outlet-0 encoding):
R = Jxx·strength, G = Jxy·strength·0.5 + 0.5, B = Jyy·strength, A = 1.
Neutral (zero tensor) = (0, 0.5, 0, 1). The module is bit-faithful to the
encoding contract: G's signed 0.5 offset passes through untouched, A stays 1,
and no angle doubling is introduced or removed. Consumers needing the packed
(cos2θ, sin2θ, trace, coherence) form take tensormap outlet 1 directly — this
module must not re-encode it.

- **No clamp anywhere in the feedback path.** Raw tensor values are unbounded
  floats (strong edges give Jxx·strength far above 1) and the recurrence must
  not clip them — clipping inside a feedback loop creates stuck-at-boundary
  artifacts. The only encode/clamps in the chain belong to tensormap upstream
  and the consumer downstream.
- **NaN persistence caveat (ADR-3's cost):** a degenerate input (NaN) persists
  forever in the feedback. That is a debug situation, not a performance
  behaviour; the bypass recovers it (bypass = passthrough, so a clean source
  flushes the state).

---

## Typical use

```
jit.gl.bfg -> f_tf_tensormap (outlet 0) -> f_tf_smooth -> f_tf_sharpen / f_tf_aniso_blur / ...
```

Sweep `release` during performance: 0 makes the field jitter with the source
(reactive), rising values settle a stable field the consumers can trust.
Note: cost does NOT scale with `release` (one fixed feedback tap, no loops);
and `release` is not a "smoothing radius" — it trades responsiveness for
stability, per channel, everywhere in the frame.

---

## Notes

- Tier-1 mirror: `tests/modules/tf_smooth/test_tf_smooth.py` (12 tests) — decay theorem against
  the closed form at release {0, 0.3, 0.5, 0.9, 0.99} over 50 frames
  (worst abs err 3.8e-6), line-field invariance (alternating θ/θ+180° gives a
  bitwise-constant output), opposite-axis reinforcement (sign-flipping
  gradients keep the tensor exactly while a vecfield control collapses;
  crossed-camp 90° flicker settles to the analytic period-2 blend with full
  preserved trace; hot/cold regional alternation never drops below the min of
  the inputs' coherences), unconnected-input decay to the zero-tensor neutral,
  bypass-exact-passthrough, channel independence, and three mutation checks
  (sign-flip, swapped weights, clamped feedback — the clamp bug is invisible
  on 0-1 content and caught only on unbounded values, which is why ADR-3 is a
  test).
- Tier-2 bench: `tests/modules/tf_smooth/bench_tf_smooth.py` — WRITTEN, NOT RUN (needs the bench
  open; run pending Matt). Frame-boundary round-trip of unbounded values
  (Jxx = 4.0 in → A·release out the next frame, no re-clamp), 5-frame
  recurrence vs mirror, release-0 GPU-exact passthrough, bypass, cost.
- Spec, plan, tasks: `.specify/f_tf_smooth/`. Codeboxes:
  `src/f_tf_smooth/codebox_state.gen`, `codebox_render.gen`.

---

## References

- One-pole release-only temporal smoothing: standard recursion. `jit.fx.tp.filter`
  is the shipped platform coverage of the recurrence math (audit §2.2 source-read);
  this module re-shapes it for the tensor family — no code taken from it, and
  no algorithm claimed as new. `f_vf_temporal_smooth` (parked idea) is the
  vecfield-family precedent for exactly this reshape.
- Input/output encoding: `docs/f-reference/f_tensor_type.md`.
- Feedback wiring precedent: `f_vf_advect` (two-domain state/pass pix chain),
  `vs_feedback.maxpat` (draw-order frame memory).