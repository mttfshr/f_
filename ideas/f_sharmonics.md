# f_sharmonics

_Status: Planned — not yet specced_
_Last updated: 2026-06-09_

## Concept

Spherical harmonics visualizer — the topologically honest version of f_chladni for the circular screen. Where f_chladni uses Bessel functions radially and Fourier modes angularly (the flat-plate circular harmonic decomposition), f_sharmonics uses spherical Bessel functions radially and Y_l^m angularly — the same differential equation lifted one dimension onto the sphere.

**f_sharmonics is a dual-outlet generator:**
- **Visual outlet** — mode shapes rendered in stereographic projection; natively seamless on the circular screen, no wrapping artifacts
- **Vecfield outlet** — ∇Y_l^m as float32 f_vecfield texture in stereographic coordinates, consumed by f_caustic, f_vf_warp, f_vf_streak

The vecfield outlet is in stereographic coordinates — geometrically correct for the spherical domain. Downstream consumers receive a field shaped by spherical geometry, not a flat approximation.

---

## Relationship to f_vf_chladni

Natural pair — same audio-reactive amplitude protocol (m0–m7), same dual-outlet pattern:

```
audio → [f_vf_chladni | f_sharmonics] → visual + f_vecfield → f_caustic → caustic layer
```

f_vf_chladni: flat plate, analytic/stateless, flat display space.
f_sharmonics: sphere, stereographic projection, natively seamless on circular screen.

Build f_vf_chladni first — it proves the dual-outlet pattern at lower complexity. f_sharmonics follows.

---

## Audio connection

Driving Y_l^m amplitudes from audio is physically motivated: higher frequency energy → higher l modes → finer angular pattern. The modes correspond to the angular resolution of the sound field.

**Ambisonics:** First-order ambisonics encodes a 3D sound field as W/X/Y/Z spherical harmonic coefficients (l=0 and l=1). Higher-order ambisonics extends to l=2,3... Those coefficients could drive f_sharmonics directly — the visualization would literally show the spatial structure of the sound field, not just react to it aesthetically.

**EEG:** Muse Athena (OSC, UDP 5000) available. Driving from EEG band powers would show the spatial structure of the viewer's neural state on the circular screen.

---

## Key design questions (pre-spec)

- **GLSL evaluation:** Evaluating Y_l^m in a codebox — polynomial formulations exist for low l values (l=0 through l=3 covers most visual interest). How many modes are practical to compute per frame? l=0..3 = 16 modes total.
- **Stereographic coordinate system:** UV conventions need verification against f_stereo's implementation before the codebox is written.
- **Vecfield encoding:** ∇Y_l^m computed via finite differences in the codebox; magnitude normalization to use full 0–1 vecfield range meaningfully.
- **Mode amplitude protocol:** Reuse f_chladni's m0amp–m7amp message names? Or extend to l/m index pairs for full spherical harmonic addressing?
- **Visual rendering:** Direct amplitude display vs something more like the caustic accumulation model applied internally?

---

## Relationship to other patches

- `f_stereo` — stereographic projection is internal to f_sharmonics; f_stereo may still be useful downstream for additional spherical transforms
- `f_vf_chladni` — precursor; same dual-outlet pattern, simpler geometry
- `f_caustic` — primary consumer of the vecfield outlet
- `circular_screen.md` — this patch is designed for the circular screen as its primary display context
