# Circular Screen — Ideas & Research

The circular screen (6' or 8' diameter projection surface) is a first-class design constraint for the f_ package — not just a display target but a formal and mathematical starting point. The governing idea: **circles are the domain, not an approximation of something else.**

---

## The Current Approach and Its Limitation

Current workflow:
1. Generate a square texture
2. Pass through a fisheye filter → round image
3. Add x/y displacement with mirror edges → illusion of a moving 3D spherical surface
4. Project onto circular screen

The limitation is **topological, not technical.** Mapping a flat Euclidean plane onto a sphere without distortion is impossible — Gauss's Theorema Egregium proves it. Where the corners of a tiled flat texture meet, the illusion breaks, because the surfaces are fundamentally incompatible shapes. No better filtering or tiling fixes this; it's a constraint from geometry itself.

The real question this raises: **what topology should the work actually live in?**

---

## Three Directions

### 1. Stereographic Projection — Work on the Sphere Natively

Instead of generating a flat texture and warping it to look spherical, generate content in a coordinate system that *is already* the sphere. Stereographic projection maps the entire sphere to the plane conformally — preserving angles and local shapes. Rotations of the sphere become Möbius transformations in the plane.

**For the circular screen:**
- South pole maps to center of the disk
- Equator maps to a ring at mid-radius
- North pole maps to the edge

The displacement trick that fakes sphere rotation becomes *literally correct* — actual sphere rotations, expressed in 2D. No seams. No corner artifacts. The sphere is the coordinate system, not a destination being approximated.

**A wave emanating from the center of the circular screen, under stereographic projection, is a wave emanating from the south pole of a sphere.** The geometry is honest. The circular screen stops being an approximation of a sphere and becomes a mathematically correct window onto one.

**As a bpatcher:** `f_stereo` — stereographic projection processor. Wraps any flat texture in spherically-correct coordinates. Could be a display-layer bpatcher that sits at the end of any chain intended for the circular screen.

---

### 2. Spherical Harmonics — The Native Language of Sphere Radiation

**Spherical harmonics Y_l^m are the universal angular basis for anything radiating from a center point in 3D.** They appear wherever a spherical problem is separated into radial and angular parts — the angular part always resolves to spherical harmonics, regardless of what the wave is. Sound, light, heat, quantum wavefunctions, gravity — same angular basis functions.

**What they describe:**
- Acoustic radiation — how sound from a point source distributes in 3D. This is literally what ambisonics is built on: spherical harmonics encode the 3D sound field.
- Ripples on a spherical surface — waves propagating outward from a point on a sphere (f_cymascope on a sphere)
- Electromagnetic radiation patterns — dipole (l=1), quadrupole (l=2) etc. are just Y_l^m modes. Antenna patterns, lens flare physics.
- Atomic orbitals — the s, p, d, f shapes are l=0,1,2,3 spherical harmonics. The connection to f_chladni is not metaphorical — it's the same differential equation.

**Connection to existing f_chladni work:**
f_chladni already uses Bessel functions radially and Fourier modes angularly (cos(mθ)). That combination — Bessel radially, Fourier angularly — *is* the 2D circular harmonic decomposition. It is the flat-plate version of spherical harmonics. The spherical version is the same idea lifted one dimension: spherical Bessel functions radially, Y_l^m angularly. The upgrade path is direct.

**For the circular screen:**
Rendered in stereographic projection, spherical harmonic mode shapes would be seamless circular patterns — like f_chladni, but topologically honest. No seams, no wrapping artifacts. The same modal amplitude inputs (m0–m7) could drive a spherical harmonic visualizer the same way they drive f_chladni.

**The natural arc this suggests:**

```
f_chladni (current)
  → circular plate, 2D Bessel + Fourier, flat space
  → flat display, wrapping artifacts

f_sharmonics (proposed)
  → sphere, spherical Bessel + Y_l^m, curved space
  → stereographic projection display, natively seamless
  → same audio-reactive amplitude inputs

f_cymascope-on-sphere (longer term)
  → FDTD wave propagation on a spherical surface
  → wave equation in spherical coordinates
  → natural mode shapes are spherical harmonics
```

**As a bpatcher:** `f_sharmonics` — spherical harmonics visualizer rendered in stereographic projection. Driven by the same m0–m7 amplitude protocol as f_chladni. Natively seamless on a circular screen.

---

### 3. Hyperbolic Geometry — Poincaré Disk

Already in the backlog (see `scratchpad.md`), worth naming in this context. The Poincaré disk maps the *entire* hyperbolic plane into a unit disk. Tiling in hyperbolic space is perfect and infinite — no seams because the boundary of the disk is at infinity.

**The circular screen is the natural canvas for Poincaré disk work.** The disk shape isn't incidental — it's the domain of the geometry. Dense kaleidoscopic patterns with infinite refinement toward the edge. Escher's Circle Limit prints are the visual reference.

The Möbius transformations that tile hyperbolic space are the same underlying math as stereographic projection rotations — building the stereographic projection bpatcher first may share implementation DNA with the Poincaré disk work.

---

## Audio/EEG Connection

Because spherical harmonics describe acoustic radiation, there is a direct physical connection between:
- The audio signal driving the bpatcher (sound = pressure wave from a source)
- The spherical harmonic mode being displayed (angular distribution of that radiation)

Driving Y_l^m amplitudes from audio analysis is not just aesthetically motivated — it's physically motivated. Higher frequency energy → higher l modes → finer angular pattern. The modes that light up correspond to the angular resolution of the sound field.

The ambisonics connection is worth exploring: ambisonics encodes a 3D sound field as spherical harmonic coefficients (W, X, Y, Z for first order, extending to l=2,3,... for higher). Those coefficients could drive a spherical harmonics visualizer directly — the visualization would literally show the spatial structure of the sound field.

---

## Research Questions

- **Stereographic projection in jit.gl.pix:** How to transform UV coordinates through stereographic projection in the codebox? The math is straightforward (closed-form, no iteration), but the coordinate conventions need verification.
- **Spherical harmonic GLSL:** Evaluating Y_l^m in a codebox — there are known polynomial formulations for low l values (l=0 through l=3 covers most visual interest). How many modes are practical to compute per frame?
- **Möbius transformation as a general processor:** A bpatcher that applies an arbitrary Möbius transformation to UV coordinates — this would generalize both stereographic rotation and hyperbolic tiling. Worth researching as a foundation layer.
- **Ambisonics OSC:** Does Muse or any other hardware output ambisonics-compatible spherical harmonic coefficients? If so, the audio-reactive pathway to f_sharmonics is direct.

---

## Proposed New Bpatchers (from this direction)

| Name | Concept | Status |
|------|---------|--------|
| `f_stereo` | Stereographic projection — display layer for circular screen; wraps any texture into spherically-correct coordinates | Idea |
| `f_sharmonics` | Spherical harmonics visualizer in stereographic projection; driven by m0–m7 amplitudes; natively seamless on circular screen | Idea |
| `f_mobius` | General Möbius transformation processor applied to UV coordinates; foundation for stereographic + hyperbolic work | Specced — see `ideas/f_mobius.md` |
| `f_poincare` | Poincaré disk — hyperbolic tiling in the unit disk; naturally fits the circular screen | In backlog (scratchpad.md) |

---

## Relation to Existing Backlog

- `f_cymascope` — FDTD wave propagation; on a sphere this produces spherical harmonic mode shapes naturally
- Optics family — aberration, caustics, flare, diffraction — all angular distributions; spherical harmonic framing may apply
- Apollonian fractal — circle packing; Möbius transformation connection; possibly shares implementation with `f_mobius`
- Non-Euclidean geometry (scratchpad) — overlaps substantially with this direction; consider merging or cross-referencing
