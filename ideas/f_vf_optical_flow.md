# f_vf_optical_flow — Idea

_Last updated: 2026-06-16_
_Status: Concept — not yet built_

## What it does

Estimates the motion field between two consecutive frames of an input texture and outputs it as an f_vecfield. Turns any animated texture into its own flow field — the field reflects where image content is moving, not an analytically defined geometry.

## Why it's interesting

Every other f_vf_ generator produces fields defined by parameters or input scalar textures. f_vf_optical_flow produces a field that is *derived from motion in the image itself* — the field is emergent from the source content rather than imposed on it. Feeding this back into f_vf_warp or f_vf_glow creates self-referential effects where the image's own movement drives its distortion.

Also useful for connecting live video or external texture sources into the f_vecfield pipeline — camera input, video playback, generative animation all become field sources automatically.

## Approach

Lucas-Kanade or Horn-Schunck optical flow — both implementable in a jit.gl.pix gen shader, though neither is trivial.

**Simpler approximation: frame difference as flow proxy**
Temporal difference between frame T and frame T-1, treated as a flow magnitude. Doesn't give true directional flow but is cheap and visually interesting. Requires ping-pong texture (Pattern 1 from temporal_synthesis_architecture.md).

**True optical flow (Lucas-Kanade)**
Computes spatial and temporal gradients, solves for per-pixel velocity. More correct, more expensive, requires multiple render passes. Likely needs the multi-pix bpatcher pattern.

Start with the frame difference approximation; upgrade to true optical flow if the approximation is insufficient.

## Proposed signal flow

```
in0 (texture / control) — animated source texture
out0 (f_vecfield — estimated motion field)
```

## Params

- `strength` — scales output field magnitude
- `smoothing` — spatial smoothing of estimated field (reduces noise)
- `bypass`

## Key design questions

- **Frame difference approach:** difference gives magnitude but not direction — need spatial gradient of the difference to get direction. This is effectively fieldmap applied to the temporal difference image. Could be implemented as `f_vf_fieldmap` on a `frame_diff` intermediate — no new module required if the approximation is acceptable.
- **True optical flow:** significant complexity, multiple render passes, may need `pix_chain` architecture. Defer until the frame difference approach has been tested and found insufficient.
- **Temporal state:** requires storing previous frame — confirmed pattern from f_vf_advect; known-good in the build system.

## Notes

- The frame difference + fieldmap signal chain is worth testing before building anything: `source → [frame diff pix] → f_vf_fieldmap → f_vf_ consumer`. This may cover most of the expressive territory without a dedicated module.
- True optical flow is a significant build — scope carefully before committing. The visual difference from the approximation may not justify the complexity for a live performance tool.
- Most computationally expensive module in the f_ family if built to full optical flow spec — performance implications at Vsynth resolutions need evaluation.
