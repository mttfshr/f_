# Spec: f_stereo

_Last updated: 2026-05-26_

## What it does

A display-layer bpatcher that maps any flat texture onto a sphere and
rotates the sphere using three performer controls — lon, lat, spin.
The texture tiles seamlessly across the sphere surface. The output is
a circular stereographic projection of the sphere with a hard black mask
at the unit disk boundary.

**Chain position:** Display layer — last in chain, before the circular
screen. Takes any flat texture in. Outputs a circular image.

**The display projection:** Stereographic projection maps the sphere
conformally onto the circular screen. Every pixel in the disk corresponds
to exactly one point on the sphere. The center of the disk is the north
pole of the rotated sphere.

**Texture sampling:** The sphere surface is sampled using equirectangular
UV coordinates — `atan2` for longitude, `asin` for latitude. The source
texture tiles seamlessly in both directions across the sphere. This gives
a natural "globe" feel: the texture wraps the sphere uniformly with no
compression artifacts at the poles.

**Sphere rotation:** R = Rz(spin) × Ry(lon) × Rx(lat), applied in 3D
as scalar arithmetic on the inverse-projected sphere point (sx, sy, sz).
- `Ry(lon)` — globe spins on its vertical axis, content moves left/right
- `Rx(lat)` — pole tilts toward/away from viewer
- `Rz(spin)` — screen-space roll, always independent

**Replaces:** fisheye filter + XY displacement + angle displacement in
the current Vsynth workflow.

**Acceptance criteria:**
- `lon=0.5, lat=0.5, spin=0` → equatorial view, texture visible across
  full disk, radially symmetric source appears symmetric
- Sweeping `lon` → content rotates like a globe on a stand (left/right)
- Sweeping `lat` → pole tilts toward/away from viewer
- `spin` → rolls content around disk center, independent of lon/lat
- LFO on `lon` produces smooth continuous rotation with no discontinuity
- Hard black circular mask at unit disk boundary
- Bypass shows raw unwarped texture (mask also bypassed)
- Loads in Vsynth, composes with f_chladni, f_grain, f_mobius upstream

---

## Parameters

| Param | Range | Default | Description |
|-------|-------|---------|-------------|
| `lon` | 0–1 | 0.5 | Longitude — globe rotation around vertical axis. Full sweep = one revolution. LFO target for continuous rotation. |
| `lat` | 0–1 | 0.5 | Latitude — tilt of pole toward/away from viewer. 0.5 = equatorial view. 0 = south pole facing. 1 = north pole facing. |
| `spin` | 0–1 | 0.0 | Spin — roll around the viewing axis. Independent of lon/lat. |
| `bypass` | 0/1 | 0 | Standard bypass — passes raw texture, removes mask. |

**lon:** Primary animation target. Maps 0–1 to −π→π (full revolution,
centered at 0.5). Driving with a slow LFO (0.01–0.1 Hz) produces
continuous globe rotation. At default lat=0.5, lon and spin affect
different axes and are fully independent.

**lat:** Maps 0–1 to −π/2→π/2. At 0.5 = equatorial view (default).
At 0 = south pole faces viewer. At 1 = north pole faces viewer.
Range is ±90° — does not traverse the full sphere, keeps content
always visible.

**spin:** Maps 0–1 to 0–2π. Rolls sampling around the viewing axis.
Screen-space roll — independent of lon/lat orientation.

**xy encoder convention:** lon → x-axis, lat → y-axis. Named float
messages on in1: `lon 0.4`, `lat 0.6`.

---

## Codebox Structure

```
// 1. UV → centered complex plane
zx = (norm.x - 0.5) * 2.0;
zy = (norm.y - 0.5) * 2.0;

// 2. Inverse stereographic projection: plane → unit sphere
r2 = zx*zx + zy*zy;
denom = 1.0 + r2;
sx = 2.0 * zx / denom;
sy = 2.0 * zy / denom;
sz = (1.0 - r2) / denom;

// 3. Rotation angles
TWO_PI = 3.14159265359 * 2.0;
PI = 3.14159265359;
lon_a  = (lon - 0.5) * TWO_PI;   // -π to π, centered at 0.5
lat_a  = (lat - 0.5) * PI;       // -π/2 to π/2, centered at 0.5
spin_a = spin * TWO_PI;           // 0 to 2π

// Precompute trig (s=spin, b=lon, a=lat)
ca = cos(lat_a);  sa = sin(lat_a);
cb = cos(lon_a);  sb = sin(lon_a);
cs = cos(spin_a); ss = sin(spin_a);

// 4. Apply R = Rz(spin) × Ry(lon) × Rx(lat)
rx = cs*cb*sx + (cs*sb*sa - ss*ca)*sy + (cs*sb*ca + ss*sa)*sz;
ry = ss*cb*sx + (ss*sb*sa + cs*ca)*sy + (ss*sb*ca - cs*sa)*sz;
rz =   -sb*sx +              cb*sa*sy +              cb*ca*sz;

// 5. Equirectangular sampling
ux = atan2(ry, rx) / TWO_PI + 0.5;
uy = asin(rz) / PI + 0.5;
effect_out = sample(in1, vec(ux, uy, 0));

// 6. Circular mask
dist = length(vec(norm.x - 0.5, norm.y - 0.5));
masked = mix(effect_out, vec(0, 0, 0, 1), step(0.5, dist));

// 7. Bypass
out1 = mix(masked, sample(in1, norm), bypass);
```

**Rotation matrix R = Rz(spin) × Ry(lon) × Rx(lat) expanded:**
```
rx = cs*cb*sx  +  (cs*sb*sa - ss*ca)*sy  +  (cs*sb*ca + ss*sa)*sz
ry = ss*cb*sx  +  (ss*sb*sa + cs*ca)*sy  +  (ss*sb*ca - cs*sa)*sz
rz =   -sb*sx  +               cb*sa*sy  +               cb*ca*sz
```
Verified: lon=0.5, lat=0.5, spin=0 → all angles 0 → identity (rx=sx, ry=sy, rz=sz).

**No south pole singularity guard needed:** forward stereographic
projection is gone. Equirectangular sampling is well-behaved everywhere
on the sphere.

---

## Relation to Other Bpatchers

**Replaces in current workflow:**
- Fisheye filter
- XY displacement
- Angle displacement

**Works with:**
- Any upstream source or processor — f_chladni, f_grain, f_mobius,
  video, noise. f_stereo is agnostic to what feeds it.
- f_sharmonics (planned) — spherical harmonics rendered in
  stereographic projection; f_stereo provides the display layer

**Note on f_poincare:** At lat=0 or lat=1 (pole facing viewer) with the
original all-stereographic architecture, f_stereo produced Poincaré-disk
geometry as an emergent property. With equirectangular sampling this no
longer occurs. f_poincare remains a separate planned module.

**Does not depend on:**
- f_mobius — f_stereo implements its own rotation math internally

---

## Open Questions

- **Aspect ratio:** Assumes square output. If the Vsynth context is not
  square, the circular mask and projection will be elliptical. Verify
  with actual Vsynth context dimensions.
- **Prefix:** `stereo` → `stereo_pix`. Confirm no collision with
  existing Vsynth objects.
- **lon sweep direction:** Verify that increasing lon moves content in
  the expected direction (left or right). May need sign flip on lon_a.
