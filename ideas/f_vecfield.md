# f_vecfield — Vector Field Family

_Last updated: 2026-06-09_
_Status: Architecture settled. Type contract in `docs/f_vecfield_type.md`. Core producers and consumers built._

## What's built

Producers: `f_vf_vortex`, `f_vf_vortex_multi`, `f_vf_fieldmap`. Consumers: `f_caustic`, `f_vf_warp`, `f_vf_streak`. Type contract: float32, RG=XY, 0.5=zero vector.

The fixed-point framing and encoding decisions are settled — see `docs/f_vecfield_type.md` for the full contract.

---

## Remaining producer concepts

### f_vf_turbulence
Hash-grid vortex sites with jitter, character derived from per-cell hash. The f_grain Voronoi architecture ports more directly here than to f_vf_vortex_multi — implicit infinite grid, no explicit site addressing. Produces organic turbulence-like field character. Lower priority than the explicit-placement producers; no spec yet.

### f_vf_chladni (pending rename)
f_chladni refactored to add a vecfield outlet (gradient of modal amplitude field). See `ideas/f_cymascope.md` and plan workstream for the audio-to-vecfield family.

### f_sharmonics (dual outlet)
Spherical harmonics visualizer — dual outlet: visual mode shapes rendered in stereographic projection, and ∇Y_l^m as f_vecfield. The vecfield outlet is in stereographic coordinates — geometrically correct for the spherical domain. Consumers (f_caustic, f_vf_warp) will receive a field shaped by spherical geometry. See `ideas/f_sharmonics.md` (to be written).

---

## Möbius relationship
Möbius transformations have fixed-point structure — two fixed points in the extended complex plane. The shared math with vortex fixed-point topology is worth investigating before designing any new producer codeboxes.

---

## Reaction-diffusion as producer
The gradient of a Gray-Scott or FitzHugh-Nagumo U field, fed through f_vf_fieldmap, produces vecfields with spiral wave and Turing pattern topology — categorically different from noise-derived fields. Near-term experiment: patch existing RD output through f_vf_fieldmap → f_caustic. No new patches needed.

---

## Remaining consumer territory

### Masking / selection
Derive scalar masks from field geometry — magnitude (fast vs slow regions), divergence (attractors vs repellers), curl (vortex centers vs laminar). These select geometrically significant regions. Would require a `f_vf_scalar` utility extracting one property as a standard char texture for downstream use. Infrastructure-flavoured — evaluate whether there's a direct performance need before building.

### Advection
Temporal transport with feedback — genuinely fluid-like motion, not a single-frame spatial approximation. See `ideas/f_vf_advect.md`. Deferred; multipass architecture needs a design session.

### Modulation
Using field properties (magnitude, curl, divergence) to modulate parameters of other f_ modules directly — either via pre-extracted scalar textures (f_vf_scalar) or native field awareness in modules. Long-term territory.

### Single-pass accumulation family
`f_vf_glow` (directional luminance halo) and `f_vf_smear` (continuous directional blur) round out the single-pass consumer family alongside f_vf_streak. See their respective ideas files.
