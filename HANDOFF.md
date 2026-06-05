# HANDOFF — f_ session 2026-06-04 (session 2)

## Status
Texture resolution and aliasing investigation across droste, stereo, masonry. Several fixes committed. f_grain reported broken — needs troubleshooting next session.

---

## What was done this session

### f_droste, f_stereo: @type char
Both patchers were outputting at lower effective resolution than input because `jit.gl.pix` without `@type char` defaults to float32 and adapts to Vsynth context dim in an inconsistent way. Added `@type char` to both, matching Vsynth processor convention (vs_hue_rot, vs_wavefolder, etc.).

**Note:** f_mobius, f_grain, f_lens, f_stipple, f_masonry, f_chladni are also missing `@type char` — deferred.

### Droste center pixelation investigation
Investigated pixelation of raster sources (masonry, stipple) near droste center vs WFG which is clean. Conclusion: single-pass droste on raster sources fundamentally cannot recurse — the center maps to magnified source texels. True Droste recursion requires multi-pass rendering (each pass feeding the next) or the source to be analytically infinite (like WFG float32). Frame delay doesn't help for static sources. **Not resolved — accepted as architectural limitation of single-pass droste on raster sources.**

### f_masonry: @type float32 + analytical AA
- Changed pix to `@type float32` (preserves precision)
- Added analytical AA block computing per-pixel smoothstep width from screen-space gradient of brick geometry
- `dim` in jit.gl.pix codebox returns input matrix dimensions (huge/undefined when no texture input) — workaround is hardcoded `px_norm = 1.0 / 640.0`
- AA improves edge quality at native resolution but does not fix droste center pixelation (different problem)
- `aspect = dim.x / dim.y` in masonry codebox is also using broken `dim` — currently returns 1.0 by coincidence (square context) but should be fixed properly

---

## Known issues / loose threads

### f_grain: broken
Suddenly not working. Cause unknown. **First priority next session.**

### f_masonry: C inlet wiring still unverified
From previous session: C inlet (in4) may not be correctly wired in bpatcher. Hover over each texture inlet in Max to confirm index ordering.

### f_masonry: aspect using broken dim
`aspect = dim.x / dim.y` uses `dim` which returns input matrix dimensions (undefined for generator). Works by coincidence in square context. Should be replaced with hardcoded `1.0` or exposed as a param.

### f_masonry: overall unresolved
Masonry is not a well-resolved tool yet. Aliasing, droste interaction, C inlet, and general robustness all need work.

---

## Key learnings this session
- `dim` in jit.gl.pix codebox = input matrix dimensions, not output/context dimensions
- `norm` is correctly 0–1 over output in jit.gl.pix generator context
- `texdim` does not exist in jit.gl.pix gen context
- `@type char` is the correct Vsynth processor convention for most effect patchers
- True Droste recursion on raster sources requires multi-pass rendering

---

## Files changed this session
- `patchers/f_droste.maxpat` — added `@type char`
- `patchers/f_stereo.maxpat` — added `@type char`
- `patchers/f_masonry.maxpat` — `@type float32`, analytical AA block
- `code/f_util_matrix_grid.js` — NUM_SOURCES 2→3, labels A/B/C
- `code/f_util_mod_handler.js` — C suffix routing added
