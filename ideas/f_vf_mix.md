# f_vf_mix — Idea

_Last updated: 2026-06-16_
_Status: Concept — not yet built_

## What it does

Blends or combines two f_vecfield textures into one. Infrastructure module — fills the gap that currently prevents combining independently parameterized fields before feeding a consumer.

## Why it's needed

Every f_vf_ consumer (f_vf_warp, f_vf_streak, f_vf_glow, f_caustic, f_lens) takes a single vecfield inlet. Without a mixer, you can only apply one field at a time. With f_vf_mix, you can combine a vortex and a fieldmap, or two vortices at different positions, before any consumer — opening the full combinatorial space.

## Proposed signal flow

```
in0 (texture / control)
in1 (f_vecfield A)
in2 (f_vecfield B)
in3 (mix amount — scalar texture or param)

out0 (f_vecfield — combined)
```

## Combination modes

At minimum:
- **Additive** — field vectors sum; superposition of both fields. Most physically natural; equivalent to what f_vf_vortex_multi does internally for its three sites.
- **Mix** — linear interpolation between A and B controlled by `mix` param or modulation texture. `mix=0` → pure A, `mix=1` → pure B.

Potentially:
- **Multiply** — magnitude of A scaled by magnitude of B; produces masking behavior
- **Max** — dominant field wins per pixel

Additive + mix covers the main expressive territory. Start there.

## Key design question

Whether `mix` should be a scalar param, a texture inlet, or both. Texture-driven mix (e.g., luma of a third texture controls blend spatially) is the most expressive option and consistent with f_ modulation patterns. A scalar param as fallback when inlet is unconnected.

## Notes

- Output must remain float32 RG to stay in the f_vecfield contract
- Additive combination may need normalization or clamping to keep output in [0,1] range — need to decide whether to normalize or clip
- This is infrastructure, not a visual generator — build when a specific signal chain need is felt in performance rather than speculatively
