# f_stereo

Stereographic projection display layer. Maps any flat texture onto a rotating sphere and projects the result as a circular image.

## What it does

Takes a flat texture and wraps it onto a sphere. The sphere can be rotated in three axes by the performer. The output is a circular stereographic projection of the sphere — every pixel in the disk corresponds to exactly one point on the sphere surface — with a hard black mask at the unit disk boundary.

**Chain position:** Display layer — intended as the last processor before a circular screen. Takes any flat texture in. Outputs a circular image.

---

## Parameters

| Param | Range | Default | Description |
|-------|-------|---------|-------------|
| `lon` | 0–1 | 0.5 | Globe rotation around vertical axis. Full sweep = one revolution. Primary LFO target. |
| `lat` | 0–1 | 0.5 | Pole tilt — tilts the north pole toward/away from viewer. 0.5 = equatorial view. |
| `spin` | 0–1 | 0.0 | Roll around the viewing axis. Independent of lon/lat. |
| `proj` | −2–2 | 0.5 | Projection blend: 0 = orthographic, 1 = stereographic. Values outside 0–1 produce extended distortions. |
| `circ` | circle/full | circle | Output shape: circle applies a circular mask at the unit disk boundary; full passes the complete projected rectangle including back-hemisphere corners. |
| `bypass` | 0/1 | 0 | Passes raw unwarped texture through. Distinct from circ=full: bypass removes the projection entirely. |

**lon** is the primary animation target. Driving with a slow LFO (0.01–0.1 Hz) produces continuous globe rotation. At default lat=0.5, lon and spin are fully independent.

**lat** at 0.5 = equatorial view (default). Sweeping toward 0 or 1 tilts the pole into/out of frame. Range is ±90° — does not traverse the full sphere, keeps content always visible.

**spin** rolls the sampling grid around the viewing axis. Screen-space rotation, fully independent of globe orientation.

**proj** blends between orthographic (0) and stereographic (1) projection:
- Orthographic = natural globe feel, edges gently foreshortened
- Stereographic = conformal, edges expanded
- Values outside 0–1 produce extended distortions that are expressive but uncontrolled — treat as beta territory for now

**xy encoder convention:** lon → x-axis, lat → y-axis. Named float messages on in1: `lon 0.4`, `lat 0.6`.

---

## Signal Chain

```
in1 (jit_gl_texture) → jit.gl.pix [stereo_pix] → out1 (jit_gl_texture)
```

The codebox implements the full pipeline:
1. UV → centered complex plane
2. Inverse stereographic projection → unit sphere (sx, sy, sz)
3. Rotation R = Rz(spin) × Ry(lon) × Rx(lat) applied as inlined scalar arithmetic
4. Equirectangular sampling: `ux = atan2(ry, rx) / TWO_PI + 0.5`, `uy = asin(rz) / PI + 0.5`
5. Hard circular mask via `step(0.5, dist)` — outside disk → black
6. Bypass: raw `sample(in1, norm)`, mask removed

---

## Rotation Model

R = Rz(spin) × Ry(lon) × Rx(lat)

- `Ry(lon)` — globe spins on its vertical axis; content moves left/right
- `Rx(lat)` — pole tilts toward/away from viewer
- `Rz(spin)` — screen-space roll, always independent

Angle mappings:
- lon: `(lon − 0.5) × 2π` → −π to π, centered at 0.5
- lat: `(lat − 0.5) × π` → −π/2 to π/2, centered at 0.5
- spin: `spin × 2π` → 0 to 2π

At default values (lon=0.5, lat=0.5, spin=0) all angles are zero → identity transform → equatorial view, radially symmetric texture appears symmetric.

No singularity guard needed: the forward stereographic projection step is removed. Equirectangular sampling via atan2/asin is well-behaved everywhere on the sphere.

---

## Texture Sampling

Equirectangular coordinates (atan2 / asin) sample the source texture. The texture tiles seamlessly across the sphere in both axes. This produces a natural globe feel with no compression artifacts at the poles.

UV values outside [0,1] correspond to back-hemisphere content where the source texture tiles naturally — no fract() needed.

---

## Feeding Radially Symmetric Sources

f_stereo samples its input in equirectangular coordinates — the x-axis is longitude (0–1 = full revolution), the y-axis is latitude (y=1 = north pole, y=0.5 = equator). This means the center of a flat source image maps to the *equator*, not the pole. Radially symmetric content (Chladni figures, Bessel modes, mandalas) with its axis of symmetry at the image center will arrive on the sphere with that axis lying in the equatorial belt — the widest, most distorted part of the projection. It looks wrong.

The fix is to remap the source so its center lands at the north pole of the equirectangular grid. This is a two-step chain using existing Vsynth modules:

**source → vs_flipy → vs_poltocar → f_stereo**

- `vs_poltocar` unwraps a circular source into a rectangle: x-axis = angle sweep (matches longitude), y-axis = radius from center. It puts r=0 (source center) at y=0 (top of rectangle).
- f_stereo's north pole samples at y=1, so without the flip, the source center ends up at the south pole.
- `vs_flipy` before poltocar inverts the source vertically, moving its center to y=1, which poltocar then maps correctly to the north pole.

The result: the source's axis of symmetry aligns with the viewing axis. Rings become latitude bands. Radial lines become meridians. Verified working with f_chladni upstream — Bessel modes project cleanly onto the sphere.

**Note on latitude nonlinearity:** f_stereo uses `asin` for latitude sampling, so the radial distribution is not perfectly linear — content is slightly compressed toward the center and expanded toward the edges of the disk. In practice this is imperceptible with organic sources.

**Sources that benefit from this chain:** f_chladni, f_sharmonics (planned), any radially symmetric generator.

---

## Composition

f_stereo is agnostic to what feeds it. Tested upstream:
- f_grain
- f_chladni
- f_mobius
- vs_noise_3

**Fisheye post-processing:** Passing f_stereo's output through a fisheye module significantly improves the spherical illusion. The stereographic projection alone shows both poles simultaneously, which reads as flat. A fisheye narrows the field of view so only one hemisphere is visible at a time — more consistent with how a large sphere looks at close range. Recommended as a standard part of the display chain: `f_stereo → vs_fisheye → output`.

---

## Known Behaviors and Issues

**Ghost image artifact:** When sweeping lat or lon, a faint blob-shaped ghost image is visible behind the sphere. Appears as though the globe is slightly transparent, with a morphing shape beneath. Likely alpha bleeding at the mask edge or a contribution from the singularity region. Not yet diagnosed — log for investigation.

**proj outside 0–1:** Extended distortion effects are discovered, not designed. Treat as expressive territory but expect uncontrolled behavior. May be scaled back in a future revision.

**Aspect ratio:** Assumes square output context. In a non-square Vsynth context, the circular mask and projection would become elliptical. Verified working correctly in standard square Vsynth context.
