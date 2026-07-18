# f_vf_sobel — Plan

## ADRs

### ADR-1: Full 3×3 Sobel kernel, not central difference
Central difference (as in f_vf_fieldmap) uses 2 samples per axis at configurable eps. Sobel uses 8 neighbors with weighted kernel. Sobel is more robust at edge detection on smooth inputs — the weighted neighborhood averages out noise and gives cleaner directionality. Fixed 1-pixel step size is correct for an edge detector; spatial reach is a downstream concern (vs_filter_lp4x).

### ADR-2: strength param signed (-10 to 10), not absolute
Sign controls field polarity — positive = repulsion (vectors point away from bright), negative = attraction. This matches fieldmap's convention and avoids needing a separate invert param. Default positive for repulsion use case.

### ADR-3: No scale param
Fieldmap has `scale` to control sampling distance. For Sobel, the kernel is semantically fixed at 1-pixel neighborhood — changing step size would break the kernel weighting ratios. Spatial reach is handled downstream by vs_filter_lp4x cutoff param.

### ADR-4: Step size derived from dim
One pixel = `1.0 / dim.x` and `1.0 / dim.y`. Aspect-correct per-axis steps rather than a single isotropic step. This ensures the kernel is geometrically correct at non-square resolutions.

### ADR-5: Pure processor archetype
Single texture inlet, single vecfield outlet. No dual-mode generation — Sobel has no meaningful output without an input texture.

## Phases

### Phase 1: Codebox verification
Write and verify the Sobel codebox in a scratch patch before building anything. Confirm:
- Full ring field around masonry blobs
- Flat regions → neutral (0.5, 0.5)
- Sign convention correct

### Phase 2: definition.py + build
Write definition.py, run build_patcher.py, validate JSON.

### Phase 3: Integration + registration
- Wire into full recipe: masonry → f_vf_sobel → vs_filter_lp4x → f_vf_advect
- Confirm fluid motion character
- Register in f_modules.maxpat and f_addmod.js
- Update README.md

## Dependencies

- f_vf_fieldmap definition.py — reference for vecfield encoding pattern
- vs_filter_lp4x — downstream in primary use case recipe (already exists)
- f_vf_advect — downstream consumer (already exists)
