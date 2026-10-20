"""
stereo_mirror.py -- NumPy mirror of the f_stereo shader: src/f_stereo/codebox_v1.gen, float32, in the codebox's own order
of operations:

  1. UV -> centred plane (zx, zy) in [-1, 1]
  2. sphere point via the orthographic / stereographic inverse formulas, mixed by proj
  3. rotation angles from lon / lat / spin
  4. R = Rz(spin) x Ry(lon) x Rx(lat) as the codebox's three expanded scalar rows
  5. equirectangular sample: ux = atan2(ry, rx) / TWO_PI + 0.5, uy = asin(rz)/PI + 0.5
  6. circular mask: dist = |norm - 0.5|, outside = step(0.5, dist), mix toward (0,0,0,1)
  7. bypass: mix(masked, sample(in1, norm), bypass)

Sampling is gpu_sim's bilinear, texel-centre, clamp-to-edge `sample` (the codebox uses
plain `sample`). The doc notes back-hemisphere uv values "tile naturally", but the codebox
performs no fract() on the sampling coordinate and the GPU's default boundmode is clamp
(bench-verified), so the mirror clamps -- the convention gpu_sim.sample implements.

Constants follow the codebox's own literals (TWO_PI = 2 * 3.14159265359, not np.pi).

`bug` values are the mutations the tests must catch:
  - "sign_flip_sz"   : the stereographic sz sign flipped, (1 - r2)/denom -> (r2 - 1)/denom
                       (a plausible transcription slip; the sphere point leaves the unit
                       sphere and the near hemisphere points away)
  - "ortho_no_max"   : orthographic sz_o = sqrt(1 - r2) unguarded -- NaN in the outer ring
                       where r2 > 1 (the max() clamp dropped)
  - "swap_asin_atan" : the equirectangular coordinate mapping swapped -- ux from asin,
                       uy from atan2 (a plausible mix-up of which axis is longitude)
  - "drop_mask"      : the circular mask removed (circ has no effect)
"""
import numpy as np

import gpu_sim as g  # noqa: E402

F32 = np.float32

TWO_PI = F32(3.14159265359 * 2.0)
PI = F32(3.14159265359)


def _mix(a, b, t):
    """GenExpr / GLSL mix: a * (1 - t) + b * t, float32."""
    t = F32(t) if np.isscalar(t) else t
    one = F32(1.0)
    return (a * (one - t) + b * t).astype(F32)


def sphere_field(h, w, lon=0.5, lat=0.5, spin=0.0, proj=0.0, bug=None, nx=None, ny=None):
    """Codebox sections 1-5 up to the rotated sphere point (rx, ry, rz), float32.
    Returned separately so tests can check the rotation without the sampling.
    nx, ny: optional precomputed texel-centre coordinates (test hook for point-wise
    evaluation; when given, h and w are ignored and no grid is built)."""
    if nx is None:
        nx, ny, _, _ = g.grid(h, w)

    # 1. UV to centred complex plane
    zx = ((nx - F32(0.5)) * F32(2.0)).astype(F32)
    zy = ((ny - F32(0.5)) * F32(2.0)).astype(F32)

    # 2. sphere point from screen uv
    r2 = (zx * zx + zy * zy).astype(F32)
    denom = (F32(1.0) + r2).astype(F32)

    sx_s = (F32(2.0) * zx / denom).astype(F32)
    sy_s = (F32(2.0) * zy / denom).astype(F32)
    if bug == "sign_flip_sz":
        sz_s = ((r2 - F32(1.0)) / denom).astype(F32)
    else:
        sz_s = ((F32(1.0) - r2) / denom).astype(F32)

    if bug == "ortho_no_max":
        sz_o = np.sqrt(F32(1.0) - r2).astype(F32)
    else:
        sz_o = np.sqrt(np.maximum(F32(1.0) - r2, F32(0.0))).astype(F32)
    sx_o = zx
    sy_o = zy

    p = F32(proj)
    sx = _mix(sx_o, sx_s, p)
    sy = _mix(sy_o, sy_s, p)
    sz = _mix(sz_o, sz_s, p)

    # 3. rotation angles
    lon_a = ((F32(lon) - F32(0.5)) * TWO_PI).astype(F32)
    lat_a = ((F32(lat) - F32(0.5)) * PI).astype(F32)
    spin_a = (F32(spin) * TWO_PI).astype(F32)

    ca = np.cos(lat_a).astype(F32); sa = np.sin(lat_a).astype(F32)
    cb = np.cos(lon_a).astype(F32); sb = np.sin(lon_a).astype(F32)
    cs = np.cos(spin_a).astype(F32); ss = np.sin(spin_a).astype(F32)

    # 4. R = Rz(spin) x Ry(lon) x Rx(lat), the codebox's expanded scalar rows
    rx = (cs * cb * sx + (cs * sb * sa - ss * ca) * sy + (cs * sb * ca + ss * sa) * sz).astype(F32)
    ry = (ss * cb * sx + (ss * sb * sa + cs * ca) * sy + (ss * sb * ca - cs * sa) * sz).astype(F32)
    rz = (-sb * sx + cb * sa * sy + cb * ca * sz).astype(F32)
    return rx, ry, rz


def stereo(src, lon=0.5, lat=0.5, spin=0.0, proj=0.0, circ=1.0, bypass=0.0, bug=None):
    """One pass. src: (H, W, 4) float32. Returns (H, W, 4) float32, the codebox's out1."""
    h, w = src.shape[:2]
    nx, ny, _, _ = g.grid(h, w)

    rx, ry, rz = sphere_field(h, w, lon=lon, lat=lat, spin=spin, proj=proj, bug=bug)

    # 5. equirectangular sampling
    if bug == "swap_asin_atan":
        ux = (np.arcsin(rz) / PI + F32(0.5)).astype(F32)
        uy = (np.arctan2(ry, rx) / TWO_PI + F32(0.5)).astype(F32)
    else:
        ux = (np.arctan2(ry, rx) / TWO_PI + F32(0.5)).astype(F32)
        with np.errstate(invalid="ignore"):  # |rz| > 1 (extended proj, below) is a real
            uy = (np.arcsin(rz) / PI + F32(0.5)).astype(F32)  # domain exit -> NaN, like the GPU
    effect_out = g.sample(src, ux, uy)

    # 6. circular mask
    dx = nx - F32(0.5)
    dy = ny - F32(0.5)
    dist = np.sqrt(dx * dx + dy * dy).astype(F32)
    outside = (dist >= F32(0.5)).astype(F32)  # step(0.5, dist) = 1 where dist >= 0.5
    black = np.tile(np.array([0.0, 0.0, 0.0, 1.0], F32), (h, w, 1))
    masked = _mix(effect_out, black, (outside * F32(circ))[..., None])
    if bug == "drop_mask":
        masked = effect_out

    # 7. bypass
    raw = g.sample(src, nx, ny)
    out1 = _mix(masked, raw, F32(bypass))
    return out1