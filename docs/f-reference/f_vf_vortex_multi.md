# f_vf_vortex_multi

**Type:** Generator (f_vecfield producer)
**Status:** Complete

---

## What it does

Three-site additive vortex field generator — sums three independent f_vf_vortex-style fields (each with its own position, convergence, and curl, sharing one global falloff) into a single f_vecfield texture. Drop-in replacement for f_vf_vortex wherever multi-focal caustic/optical effects are wanted. Primary consumer: f_caustic (multiple independent bright zones).

Sites contribute additively per-pixel, each weighted by its own exponential falloff — sites close together reinforce convergence, sites far apart create independent focal zones, with no visible seams downstream.

---

## Signal Flow

```
in0 (bang + control) → params route to dials → vf_vortex_multi_pix
in1 (cx mod texture, optional)          → vs_inState → vf_vortex_multi_pix
in2 (cy mod texture, optional)          → vs_inState → vf_vortex_multi_pix
in3 (convergence mod texture, optional) → vs_inState → vf_vortex_multi_pix
in4 (curl mod texture, optional)        → vs_inState → vf_vortex_multi_pix

vf_vortex_multi_pix (@type float32) → out0
```

Site position inlets (`vsc_center_ctrl`-driven, injected post-build at indices 5–7) allow each site's cx/cy to be animated independently — three separate `vsc_center_ctrl` instances can drive orbital motion per site. Unconnected site position falls back to that site's static `sN_cx`/`sN_cy` dial values.

---

## Parameters

| Param | Range | Default | Description |
|---|---|---|---|
| `s1_cx` / `s1_cy` | 0–1 | 0.3 / 0.3 | Site 1 position |
| `s1_conv` | 0–1 | 0.5 | Site 1 convergence |
| `s1_curl` | -1–1 | 0.0 | Site 1 curl |
| `s2_cx` / `s2_cy` | 0–1 | 0.5 / 0.5 | Site 2 position |
| `s2_conv` | 0–1 | 0.5 | Site 2 convergence |
| `s2_curl` | -1–1 | 0.0 | Site 2 curl |
| `s3_cx` / `s3_cy` | 0–1 | 0.7 / 0.7 | Site 3 position |
| `s3_conv` | 0–1 | 0.5 | Site 3 convergence |
| `s3_curl` | -1–1 | 0.0 | Site 3 curl |
| `falloff` | 0–10 | 2.0 | Shared exponential falloff rate across all three sites |
| `cx_amt` | 0–1 | 0.0 | Global cx modulation depth (inlet 1) — offsets all three sites together |
| `cy_amt` | 0–1 | 0.0 | Global cy modulation depth (inlet 2) |
| `conv_amt` | 0–1 | 0.0 | Global convergence modulation depth (inlet 3) |
| `curl_amt` | 0–1 | 0.0 | Global curl modulation depth (inlet 4) |
| `bypass` | 0/1 | 0 | Outputs neutral field (all 0.5) |

**Prefix:** `vf_vortex_multi` — **Object name:** `vf_vortex_multi_pix`

---

## Field Encoding

f_vecfield convention: `R = fx * 0.5 + 0.5`, `G = fy * 0.5 + 0.5`, `B = 0.5`, `A = 1.0`. Consumers decode via `(sample - 0.5) * 2.0`. Global modulation inlets decode the same way and offset all three sites' cx/cy/convergence/curl simultaneously — there is no per-site modulation depth in v1 (shared depth, per-site base values only).

---

## Algorithm

Each site independently computes a standard vortex field (radial + tangential components weighted by convergence/curl) about its own center, scaled by `exp(-r * falloff)`. All three sites' `(fx, fy)` contributions sum additively before clamping and encoding:

```
for each site N in {1,2,3}:
    dx, dy = uv - (sN_cx + cx_mod, sN_cy + cy_mod)
    r = length(dx, dy); rx, ry = dx/r, dy/r; tx, ty = -ry, rx
    fN = (sN_conv + conv_mod) * (-rx, -ry) + (sN_curl + curl_mod) * (tx, ty)
    fN *= exp(-r * falloff)

fx, fy = f1 + f2 + f3
R, G = clamp(fx*0.5+0.5, 0, 1), clamp(fy*0.5+0.5, 0, 1)
```

Sites at identical positions sum to roughly 3x single-site magnitude (clamped, not renormalized) — produces a single very bright zone rather than a capped-equal one.

---

## Notes

- Falloff is shared across all three sites (not per-site) — deliberate v1 scope limit, per spec.md's "Out of Scope."
- No per-site modulation inlets in v1 — only the four global (all-sites) modulation inlets exist; per-site modulation is listed as a possible v2 addition following the f_vf_vortex pattern.
- More than three sites, a Voronoi/nearest-site-wins combination mode, and built-in LFO/animation are explicitly out of scope for v1.
- A second file, `patchers/f_vf_vortex_multi_version.maxpat`, exists alongside the primary `f_vf_vortex_multi.maxpat` — not documented here; confirm with Matt whether it's a superseded draft or an intentional alternate build before treating it as current.
- See `docs/f-reference/f_vecfield_type.md` for full type contract.
