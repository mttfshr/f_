# Spec: f_stereo

_Last updated: 2026-05-26_

## What it does

A display-layer bpatcher that maps any flat texture onto a sphere via
stereographic projection, then rotates the sphere using three performer
controls. Replaces the current fisheye + XY displacement workflow with a
mathematically correct equivalent: the same gestural vocabulary (pan,
tilt, spin), but operating honestly in spherical coordinates rather than
approximating them on a flat tiled surface.

**Chain position:** Display layer — last in chain, before the circular
screen. Takes any flat texture in. Outputs a stereographically-projected
circular image with a hard black mask at the unit disk boundary.

**The projection:** Stereographic projection maps the entire sphere
conformally onto the plane — preserving angles and local shapes. The
north pole maps to the center of the circular screen. The equator maps
to a ring at mid-radius. The south pole maps to infinity (outside the
visible disk). Every pixel on the circular screen corresponds to exactly
one point on the sphere — no seams, no corner artifacts.

**Sphere rotation:** Rotating the sphere is equivalent to a Möbius
transformation in the projected plane. f_stereo applies the rotation in
3D (plane → sphere → rotate → plane) so the math is exact. lon/lat
position the north pole; spin rolls around the viewing axis.

**Replaces:** fisheye filter + XY displacement + angle displacement in
the current Vsynth workflow. The same three controls (x position, y
position, angle) map to lon, lat, spin.

**Acceptance criteria:**
- `lon=0.5, lat=0.5, spin=0` → stable centered projection, radially
  symmetric texture appears symmetric (north pole at screen center)
- Sweeping `lon` → content rotates continuously around the viewing axis
- Sweeping `lat` → content tilts (north pole moves off-center)
- LFO on `lon` produces smooth continuous rotation with no discontinuity
- Hard black circular mask at unit disk boundary
- Bypass shows raw unwarped texture (mask also bypassed)
- Loads in Vsynth, composes with f_chladni, f_grain, f_mobius upstream

---

## Parameters

| Param | Range | Default | Description |
|-------|-------|---------|-------------|
| `lon` | 0–1 | 0.5 | Longitude — azimuthal position of north pole (0.5 = centered). LFO target for continuous rotation. |
| `lat` | 0–1 | 0.5 | Latitude — tilt of north pole from viewing axis (0.5 = facing viewer, 0 or 1 = tilted 90°). |
| `spin` | 0–1 | 0.0 | Spin — roll around the viewing axis. Independent of lon/lat. |
| `bypass` | 0/1 | 0 | Standard bypass — passes raw texture, removes mask. |

**lon:** Primary animation target. Maps 0–1 to 0–2π azimuthal rotation.
Full sweep = one complete revolution. Driving with a slow LFO (0.01–0.1
Hz) produces the continuous sphere rotation effect.

**lat:** Tilts the sphere so the north pole moves off the viewing axis.
At 0.5 the north pole is centered. Moving away from 0.5 in either
direction tilts the sphere — content from the "side" of the sphere
comes into view. Maps to ±90° from center (±π/2 tilt range). Beyond
that range content from the back hemisphere fills in — handled
naturally by the projection.

**spin:** Rolls the image around the center of the circular screen.
Equivalent to the current angle displacement control. At lat=0.5 (no
tilt), spin and lon are equivalent; the distinction matters when lat≠0.5.

**xy encoder convention:** lon → x-axis, lat → y-axis. Same as the
current XY displacement encoder. Named float messages on in1: `lon 0.4`,
`lat 0.6`. Standard Vsynth control inlet.

---

## Codebox Structure

```
// 1. UV → complex plane (centered, unit circle = equator)
zx = (norm.x - 0.5) * 2.0;
zy = (norm.y - 0.5) * 2.0;

// 2. Inverse stereographic projection: plane → sphere
// Projects from south pole onto equatorial plane
r2 = zx*zx + zy*zy;
denom = 1.0 + r2;
sx = 2.0 * zx / denom;
sy = 2.0 * zy / denom;
sz = (1.0 - r2) / denom;
// Result: (sx, sy, sz) is a point on the unit sphere
// North pole (0,0,1) → center; equator → unit circle

// 3. Sphere rotation: R = Rz(lon) * Rx(lat_tilt) * Rz(spin)
spin_a  = spin * TWO_PI;
lat_a   = (lat - 0.5) * TWO_PI;   // -π to π (full sphere coverage)
lon_a   = lon * TWO_PI;
// Apply rotation matrix inline (9 terms)
// rx, ry, rz = R * (sx, sy, sz)

// 4. Forward stereographic projection: sphere → plane
// Guard against south pole singularity (rz → -1)
denom2 = max(1.0 + rz, 0.0001);
ux = (rx / denom2) * 0.5 + 0.5;
uy = (ry / denom2) * 0.5 + 0.5;

// 5. Sample
effect_out = sample(in1, vec(ux, uy, 0));

// 6. Circular mask — hard black outside unit disk
dist = length(vec(norm.x - 0.5, norm.y - 0.5));
masked = mix(effect_out, vec(0, 0, 0, 1), step(0.5, dist));

// 7. Bypass
out1 = mix(masked, sample(in1, norm), bypass);
```

**Rotation matrix composition:** R = Rz(lon) * Rx(lat) * Rz(spin).
Applied inline — no matrix objects, just scalar arithmetic on sx/sy/sz.
Nine multiply-add operations. Fully works out to explicit rx, ry, rz
expressions; compute at plan/codebox stage.

**South pole singularity:** When rz → -1, denom2 → 0. The `max(...,
0.0001)` guard keeps it finite — the south pole region gets a large UV
value that lands outside the unit disk and is masked to black anyway.

**No edge wrap needed:** UV values outside [0,1] after projection
correspond to content from the back hemisphere. This is expected —
the texture tiles and the projection handles it naturally. No fract()
needed.

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

**Enables:**
- Honest sphere rotation — the displacement trick becomes exact
- Seam-free content on the circular screen — no corner artifacts
- f_sharmonics — once f_stereo exists, a spherical harmonics
  visualizer can render directly in stereographic coordinates

**Does not depend on:**
- f_mobius — f_stereo implements its own Möbius math internally
  (the sphere rotation step is itself a Möbius transform)

---

## Open Questions

- **lat range:** Full ±180° (2π) — complete sphere coverage. lat=0.5
  is north pole facing viewer; lat=0 or lat=1 is south pole facing
  viewer (fully inverted). Resolved: use `(lat - 0.5) * TWO_PI`.
- **Texture sampling at back hemisphere:** UV values from the back
  hemisphere may sample unexpected regions of a non-tiling texture.
  Test with f_chladni and f_grain to see if this is an issue in
  practice.
- **Aspect ratio:** Assumes square output. If the Vsynth context is not
  square, the circular mask and projection will be elliptical. Verify
  with actual Vsynth context dimensions.
- **Prefix:** `stereo` → `stereo_pix`. Confirm no collision with
  existing Vsynth objects.
