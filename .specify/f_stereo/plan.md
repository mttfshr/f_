# Plan: f_stereo

_Last updated: 2026-05-26_

## Architectural Decisions

### ADR-1: Rotation order R = Rz(lon) × Rx(lat) × Rz(spin)
Apply Euler angles in this order: azimuth first (lon), then tilt (lat), then roll (spin).
- Rz(lon) positions the north pole azimuthally on the sphere before tilt is applied
- Rx(lat) tilts the north pole toward/away from the viewer
- Rz(spin) rolls around the viewing axis — independent of lon/lat orientation
- This matches the performer model: lon = "where you're pointing", lat = "how much you tilt", spin = "roll"

Rejected: lon applied last — would cause spin and lon to interact unintuitively when lat ≠ 0.

### ADR-2: lat angle mapping — (lat − 0.5) × 2π
Maps lat=0.5 → 0 (north pole facing viewer), full range covers the entire sphere.
- lat=0.25 → −π/2 (south pole sideways, equator through center)
- lat=0 or lat=1 → ±π (south pole facing viewer, image inverted)
- The spec text says "0 or 1 = tilted 90°" — this is a documentation inconsistency;
  the formula produces 180° at those extremes. Verify empirically in Phase 0.

### ADR-3: Rotation matrix inlined as scalar arithmetic
R = Rz(a) × Rx(b) × Rz(c) expanded to nine multiply-adds per output component.
No matrix objects. Applied directly to (sx, sy, sz) from inverse projection.

Expanded expressions (a=lon_a, b=lat_a, c=spin_a):

```
rx = (cos a · cos c − sin a · cos b · sin c) · sx
   + (−cos a · sin c − sin a · cos b · cos c) · sy
   + ( sin a · sin b) · sz

ry = ( sin a · cos c + cos a · cos b · sin c) · sx
   + (−sin a · sin c + cos a · cos b · cos c) · sy
   + (−cos a · sin b) · sz

rz = (sin b · sin c) · sx
   + (sin b · cos c) · sy
   + (cos b) · sz
```

Rationale: single codebox, no intermediate outputs, no gen~ matrix ops needed.

### ADR-4: South pole singularity guard — max(1 + rz, 0.0001)
When rz → −1 the forward projection denominator → 0. Clamp to 0.0001.
- Near-south-pole pixels get large UV values, land outside the unit disk, masked to black
- No branching, no NaN, no visible artifact inside the mask region

### ADR-5: Hard circular mask via step()
`dist = length(vec(norm.x − 0.5, norm.y − 0.5))`
`masked = mix(effect_out, vec(0, 0, 0, 1), step(0.5, dist))`
- Hard edge, no anti-aliasing — consistent with the circular screen usage
- Bypass removes the mask (passes raw texture through norm sampling)

### ADR-6: No UV wrap (no fract())
UV values outside [0,1] from the projection are expected — they correspond to back-hemisphere
content where the source texture tiles naturally. No fract() needed; texture sampler handles it.
Contrast with f_droste/f_mobius which wrap explicitly.

### ADR-7: Python build script for bpatcher
4 params (lon, lat, spin, bypass) plus full signal chain: param objects, pix wrapper,
receive objects, xy encoder routing on in1. Python script is cleaner than hand-written JSON.
Consistent with f_texrouter and f_mobius precedent.

---

## Implementation Phases

### Phase 0 — Codebox (verify math before building wrapper)
Write the full codebox with rotation matrix inlined. Paste into a scratch patch
(vs_noise_3 or similar as texture source). Verify all four acceptance criteria:
1. lon=0.5, lat=0.5, spin=0 → stable centered, radially symmetric texture appears symmetric
2. Sweep lon → content rotates continuously around viewing axis, no discontinuity
3. Sweep lat → content tilts (north pole moves off-center)
4. LFO on lon → smooth continuous rotation, no discontinuity at 0/1 boundary
Also: verify lat=0.25 behavior (equator through center) vs spec text discrepancy.

### Phase 1 — Bpatcher Wrapper
Python build script → patchers/f_stereo.maxpat.
Required: jit.gl.pix, stereo_pix codebox, param objects, receive objects,
autopattr, moduleSize.js chain, bypass routing, in1/out1 labeling.
xy encoder: lon → x-axis, lat → y-axis (named float messages on in1).

### Phase 2 — Performance Validation
LFO on lon for continuous rotation. lat range exploration.
Compose with upstream processors (f_grain, f_chladni, f_mobius).
Aspect ratio check in actual Vsynth context.

### Phase 3 — Documentation
docs/f_stereo.md written. README updated. HANDOFF updated.
