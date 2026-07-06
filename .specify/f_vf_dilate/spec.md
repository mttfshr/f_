# f_vf_dilate — Spec

## Concept

vecfield in → vecfield out. Spreads non-neutral vectors outward into neutral (0.5, 0.5) regions via iterative pix-to-pix feedback. Each pass propagates edge vectors one pixel further from their source. After N passes, the field extends N pixels outward from any non-neutral region.

General utility — works on any f_vecfield input: sobel edges, vortex fields, chladni gradient outlet, fieldmap output, etc. Primary motivation is extending repulsion fields for f_vf_advect consumption, but applicable anywhere field influence radius needs to be increased.

## Signal Flow

```
vecfield in → [dilation pass] ↔ [feedback] → vecfield out
```

Per-pass logic: for each pixel, if current vector is neutral, check 4 neighbors (N/S/E/W). Adopt the neighbor with the highest magnitude (furthest from 0.5). If no non-neutral neighbors, stay neutral.

After `reach` passes, non-neutral vectors have spread outward by `reach` pixels.

## Architecture

pix-to-pix feedback via jit.gl.textureset (same pattern as f_vf_advect). Number of feedback iterations controlled by `reach` param — drives an external counter that gates how many passes fire per frame.

Open question: is `reach` a continuous float (smoothly interpolated pass count) or integer (exact pass count)? Integer is simpler and correct for dilation semantics. Suggest integer, range 0–32.

## Parameter Contract

| Param  | Type    | Range | Default | Description |
|--------|---------|-------|---------|-------------|
| reach  | integer | 0–32  | 4       | Number of dilation passes. Each pass spreads field 1 pixel outward. |
| bypass | bool    | 0/1   | 0       | Pass input vecfield through unchanged. |

## Archetype

Pure processor — float32 in, float32 out. Single inlet (vecfield), single outlet (vecfield).

## Acceptance Criteria

- [ ] Scratch patch: ring field from f_vf_sobel visibly spreads outward with increasing reach
- [ ] reach=0 → output identical to input (no spread)
- [ ] Neutral regions (0.5, 0.5) remain neutral where no neighbor has signal
- [ ] Direction of spread vectors correct: outward from source edge, not inward
- [ ] No encoding artifacts at field boundaries
- [ ] Works on non-sobel inputs: vortex field, fieldmap output
- [ ] f_vf_advect downstream produces fluid motion extending beyond edge boundary
- [ ] Audit passes clean
