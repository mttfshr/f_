# Circular Screen — Ideas & Research

_Last updated: 2026-06-09_

The circular screen (6' or 8' diameter projection surface) is a first-class design constraint for the f_ package — not just a display target but a formal and mathematical starting point. The governing idea: **circles are the domain, not an approximation of something else.**

---

## The topological problem

Current workflow generates a square texture, passes through a fisheye filter, adds displacement. The limitation is topological: mapping a flat Euclidean plane onto a sphere without distortion is impossible (Gauss's Theorema Egregium). No better filtering fixes this — it's a constraint from geometry itself.

The real question: **what topology should the work actually live in?**

---

## Three directions

### 1. Stereographic projection — `f_stereo` ✅ Built

Work on the sphere natively. Stereographic projection maps the entire sphere to the plane conformally. Rotations of the sphere become Möbius transformations in the plane. The displacement trick that fakes sphere rotation becomes literally correct — actual sphere rotations, no seams, no corner artifacts.

### 2. Spherical harmonics — `f_sharmonics` 📋 Planned

Y_l^m are the universal angular basis for anything radiating from a center point in 3D. Same differential equation as f_chladni, lifted one dimension.

**f_sharmonics is a dual-outlet generator:**
- **Visual outlet** — mode shapes rendered in stereographic projection; natively seamless on the circular screen
- **Vecfield outlet** — ∇Y_l^m as float32 f_vecfield in stereographic coordinates; consumed by f_caustic, f_vf_warp, f_vf_streak

Driven by the same m0–m7 amplitude protocol as f_chladni. The natural pair:

```
f_vf_chladni  — flat plate, Bessel + Fourier, flat space
f_sharmonics  — sphere, spherical Bessel + Y_l^m, stereographic projection
```

Both audio-reactive. f_sharmonics is the topologically honest version for the circular screen.

The ambisonics connection: ambisonics encodes a 3D sound field as spherical harmonic coefficients — those could drive f_sharmonics directly, making the visualization literally show the spatial structure of the sound field.

See `ideas/f_sharmonics.md`.

### 3. Poincaré disk — `f_poincare` 📋 Planned

Maps the entire hyperbolic plane into a unit disk. Tiling is perfect and infinite — no seams because the boundary is at infinity. The circular screen is the natural canvas.

Dense kaleidoscopic patterns with infinite refinement toward the edge. Escher's Circle Limit prints are the visual reference. Möbius transformations that tile hyperbolic space share implementation DNA with f_stereo and f_mobius.

See `ideas/f_poincare.md`.

---

## Audio/EEG connection

Driving Y_l^m amplitudes from audio is physically motivated — higher frequency energy → higher l modes → finer angular pattern. The modes correspond to the angular resolution of the sound field.

Muse Athena EEG (OSC, UDP 5000) available. Driving f_sharmonics from EEG band powers would show the spatial structure of the viewer's neural state on the circular screen — a direct physical correspondence.

---

## Droste singularity connection

The droste singularity boundary is the same conformal compression geometry as Poincaré disk tile edges. Designing f_poincare around this explicitly — rather than discovering it empirically — is an advantage from already understanding droste's behavior. See `ideas/droste_singularity.md`.
