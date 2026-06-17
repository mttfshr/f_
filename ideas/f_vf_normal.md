# f_vf_normal — Idea

_Last updated: 2026-06-16_
_Status: Concept — not yet built_

## What it does

Repackages an input texture's RG channels as an f_vecfield, treating them as XY normal map components. Bridges normal map assets (from 3D renderers, Jitter procedural tools, or image sources) into the f_vecfield pipeline.

## Why it's needed

Normal maps are already encoded as RG textures with 0.5 = zero — the same convention as f_vecfield. Many tools produce normal maps: `jit.gl.bfg` with normal output, 3D render passes, image-processed surfaces. Currently there's no clean way to route these into f_vf_ consumers without going through fieldmap (which reinterprets the texture as a scalar and re-differentiates, losing information).

f_vf_normal is essentially a format adapter — minimal processing, mostly a semantic declaration that "this RG texture should be treated as a vecfield."

## Proposed signal flow

```
in0 (texture / control) — normal map or any RG texture
out0 (f_vecfield)
```

## Params

Probably minimal:
- `strength` — scales the XY components (0.5 + (raw - 0.5) * strength); at 1.0 pass-through, lower values reduce field magnitude
- `bypass`

Possibly:
- `invert_x`, `invert_y` — flip field axes; useful when source normals use a different handedness convention

## Key design question

Whether this needs to be a full bpatcher or could just be a convention note — if the source is already in the right format, you can wire it directly to any f_vf_ consumer inlet. The module only adds value if you need strength scaling or axis correction. Build only if a concrete use case appears.

## Notes

- Essentially the inverse of f_vf_fieldmap: fieldmap converts scalar → vecfield via differentiation; f_vf_normal passes RG through as vecfield with optional scaling
- `jit.gl.bfg` normal output is already in the right format and may wire directly to f_vf_ consumers without needing this module — test first before building
