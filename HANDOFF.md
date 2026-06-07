# HANDOFF — f_ session 2026-06-07

## Status

f_vortex_multi v2 complete and working. 4 global mod inlets added (cx, cy, conv, curl). Verified live with f_caustic — spectacular results with texture modulation driving the field.

---

## What was done this session

### f_vortex_multi v2 — global mod inlets
- Added 4 mod inlets: cx mod, cy mod, convergence mod, curl mod (inlets 1-4)
- Mod signals apply globally to all three sites: per-site dial values set character, mod inlet drives global variation
- Codebox: decodes in2-in5 to signed offsets, adds to per-site cx/cy/conv/curl before field computation
- definition.py updated: mod_inlets, 4 _amt params, presentation_height 100→130
- Post-build site position inlets removed — position animation handled externally via control inlet messages (s1 center X Y etc routed by user as needed)
- ID collision issue diagnosed and resolved: build system uses obj-100..110 for mod inlet infrastructure; post-build injection must use obj-200+
- Committed: "feat: f_vortex_multi v2 — 4 global mod inlets (cx, cy, conv, curl)"

### Docs updated
- docs/f_vecfield_type.md: f_vortex_multi marked Complete, description updated
- README.md: f_vortex_multi row updated to reflect mod inlets

### Scratchpad entry added
- ideas/scratchpad.md: mod matrix revisited — f_vortex_multi as natural v3 target; 2 source textures → per-cell routing/depth matrix; deferred until UX pattern is solid

---

## f_vortex_multi v2 architecture

- Archetype: source (dual-mode generator)
- Inlets: 0=texture/control, 1=cx mod, 2=cy mod, 3=convergence mod, 4=curl mod
- Outlet: f_vecfield float32 texture
- Params: s1_cx, s1_cy, s1_conv, s1_curl, s2_cx, s2_cy, s2_conv, s2_curl, s3_cx, s3_cy, s3_conv, s3_curl, falloff, cx_amt, cy_amt, conv_amt, curl_amt, bypass
- Site position animation: send `s1 center X Y` etc to inlet 0; route externally as needed
- Mod pattern: global offset = (sample(inN) - 0.5) * 2.0 * amt; added to all three sites

---

## Next session priorities

1. **f_grain diagnosis** — flagged broken from previous session, still unaddressed (oldest debt)
2. **f_vortex_multi performance use** — get it into a real Vsynth set with texture mod patched in
3. **f_vortex_turbulence spec** — hash-grid implicit sites for lumia-style caustic accumulation
4. **f_caustic helpfile** — f_droste.maxhelp is the template

---

## Loose threads

- f_vortex_multi v3: mod matrix — 2 incoming texture sources, per-cell routing/depth matrix; natural target given 4 modulated params; deferred until UX pattern solid (see scratchpad)
- f_vortex_multi: site position inlet simplification — collapse 3 site pos inlets to control inlet via prefixed messages (s1 center X Y); known to work, just Max patching, not urgent
- f_vortex_turbulence: primary consumer would be f_caustic for lumia-style effects; design should prioritize smooth continuous field
- f_caustic color_shift: R/B separation perpendicular to field direction — parallel as creative option worth trying
