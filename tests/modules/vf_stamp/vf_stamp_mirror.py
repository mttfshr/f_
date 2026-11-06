"""vf_stamp_mirror.py -- tier-1 NumPy mirror of the not-yet-built f_vf_stamp module (spec:
.specify/f_vf_stamp/spec.md, tasks T009-T010). Float32, one stage, in the order a codebox would
compute it; every texture read goes through gpu_sim.sample.

Inputs as in the planned gen: in0 = stamp texture, in1 = vecfield (R,G encode (v - 0.5) * 2).
src_vec is the vs_inState connected flag; in1 = None stands for vs_black (0, 0, 0, 0).

    out0 = vec(in0.rgb * cov * amount * env, 1)                       (G2)
    out1 = encode(v), encode = v * 0.5 + 0.5, B = 0.5, A = 1          (f_vecfield_type)
    v    = (in1.rg - 0.5) * 2 * cov * env * force                     in1 connected
    v    = field(cov) * env * force                                   in1 empty (radial / swirl)

Luma is Rec.709 (G7). Bypass (G5): out0 = in0, out1 = in1 when connected else neutral, with the
FR-011 zap still active.

The field (`field` argument) is what T003 has to choose, so both candidates are here:
  "unit"  plan ADR-4 as written: g = central difference / 2, direction -g / max(|g|, eps),
          magnitude 4 cov (1 - cov) from the centre texel.
  "diff"  the plain wide central difference, no divide: v = -(cov(x+s) - cov(x-s), cov(y+s) -
          cov(y-s)), s = `reach` texels. Each component is already in [-1, 1].
Swirl is the radial field rotated by (x, y) -> (-y, x) in either case.

Neighbours use explicit integer texel indices with a modulo wrap (FR-010): the codebox reads them
at texel centres. Noise (ADR-5) is value noise over the f_ks hash, centred on 0 so edge = 0 is
exact and a non-zero edge does not bias the threshold.

PROVISIONAL CONSTANT: NOISE_CELL (texels per noise cell), not a spec value yet.

`bug` values are mutations the tests must catch: "inward" (radial sign flipped), "clamp_edge"
(neighbours clamped, not wrapped), "value_flag" (in1 used regardless of src_vec), "ink_no_env"
(the ink ignores the envelope), "swap_luma" (Rec.601 weights).
"""
import numpy as np

import gpu_sim as g  # noqa: E402

F32 = np.float32
LUMA = (F32(0.2126), F32(0.7152), F32(0.0722))
LUMA_601 = (F32(0.299), F32(0.587), F32(0.114))
SOFT_EPS = F32(1e-5)     # smoothstep width floor: softness 0 must not divide by zero
UNIT_EPS = F32(1e-6)     # ADR-4's eps
NOISE_CELL = 8


def zap(x, fill):
    """Non-finite to fill, by the library's abs(x) < 1e30 guard (NaN == NaN is TRUE on this GPU)."""
    return np.where(np.abs(x) < F32(1e30), x, F32(fill)).astype(F32)


def _mix(a, b, t):
    return (a * (F32(1) - F32(t)) + b * F32(t)).astype(F32)


def _mixa(a, b, t):
    return (a * (F32(1) - t) + b * t).astype(F32)


def hash2(px, py):
    """src/f_ks/codebox_seed.gen's arithmetic hash (no sin()): in [0, 1)."""
    px = np.asarray(px, F32)
    py = np.asarray(py, F32)
    ha = (px * F32(0.1031)) % F32(1)
    hb = (py * F32(0.1031)) % F32(1)
    hc = ha
    hd = ha * (hb + F32(33.33)) + hb * (hc + F32(33.33)) + hc * (ha + F32(33.33))
    ha = ha + hd
    hb = hb + hd
    hc = hc + hd
    return (((ha + hb) * hc) % F32(1)).astype(F32)


def value_noise(ix, iy, w, h, seed, cell=NOISE_CELL):
    """Value noise in texel space, in [-0.5, 0.5), periodic on the render size."""
    ncx = max(1, int(np.ceil(w / cell)))
    ncy = max(1, int(np.ceil(h / cell)))
    fx = np.asarray(ix, F32) / F32(cell)
    fy = np.asarray(iy, F32) / F32(cell)
    cx = np.floor(fx)
    cy = np.floor(fy)
    tx = fx - cx
    ty = fy - cy
    tx = tx * tx * (F32(3) - F32(2) * tx)
    ty = ty * ty * (F32(3) - F32(2) * ty)

    def lat(a, b):
        return hash2((a % ncx) + F32(seed * 61), (b % ncy) + F32(seed * 17))

    top = _mixa(lat(cx, cy), lat(cx + 1, cy), tx)
    bot = _mixa(lat(cx, cy + 1), lat(cx + 1, cy + 1), tx)
    return (_mixa(top, bot, ty) - F32(0.5)).astype(F32)


def smoothstep(e0, e1, x):
    t = np.clip((x - F32(e0)) / max(F32(e1) - F32(e0), SOFT_EPS), 0, 1).astype(F32)
    return (t * t * (F32(3) - F32(2) * t)).astype(F32)


def coverage(in0, ix, iy, w, h, threshold, softness, invert, edge_amt, seed, weights=LUMA):
    """cov at integer texel indices of a w x h render target (FR-003)."""
    rgb = zap(g.sample(in0, (ix + F32(0.5)) / F32(w), (iy + F32(0.5)) / F32(h)), 0)
    lum = rgb[..., 0] * weights[0] + rgb[..., 1] * weights[1] + rgb[..., 2] * weights[2]
    lum = lum + F32(edge_amt) * value_noise(ix, iy, w, h, seed)
    c = smoothstep(F32(threshold) - F32(softness) / 2, F32(threshold) + F32(softness) / 2, lum)
    return _mix(c, F32(1) - c, invert)


def impulse_field(cov_at, c0, ix, iy, w, h, field, reach, impulse, bug=None):
    """The in1-empty field in vecfield units, before env and force. Returns (vx, vy)."""
    s = F32(reach)
    if bug == "clamp_edge":
        def wx(a):
            return np.clip(a, 0, w - 1).astype(F32)

        def wy(a):
            return np.clip(a, 0, h - 1).astype(F32)
    else:
        def wx(a):
            return (a % F32(w)).astype(F32)

        def wy(a):
            return (a % F32(h)).astype(F32)
    dx = cov_at(wx(ix + s), iy) - cov_at(wx(ix - s), iy)
    dy = cov_at(ix, wy(iy + s)) - cov_at(ix, wy(iy - s))
    if field == "diff":
        rx, ry = -dx, -dy
    elif field == "unit":
        gx = dx * F32(0.5)
        gy = dy * F32(0.5)
        inv = F32(1) / np.maximum(np.sqrt(gx * gx + gy * gy), UNIT_EPS)
        m = F32(4) * c0 * (F32(1) - c0)
        rx, ry = -gx * inv * m, -gy * inv * m
    else:
        raise ValueError(field)
    if bug == "inward":
        rx, ry = -rx, -ry
    if impulse >= 0.5:
        return (-ry).astype(F32), rx.astype(F32)
    return rx.astype(F32), ry.astype(F32)


def stamp_stage(in0, in1=None, threshold=0.5, softness=0.1, invert=0.0, edge_amt=0.0, seed=0,
                amount=1.0, force=1.0, impulse=0.0, env=1.0, src_vec=0.0, bypass_gate=0.0,
                field="diff", reach=1, size=None, bug=None):
    """One frame of the stage. Returns (out0, out1), each float32 (H, W, 4)."""
    h, w = size if size else in0.shape[:2]
    nx, ny, ix, iy = g.grid(h, w)
    weights = LUMA_601 if bug == "swap_luma" else LUMA

    def cov_at(a, b):
        return coverage(in0, a, b, w, h, threshold, softness, invert, edge_amt, seed, weights)

    c0 = cov_at(ix, iy)
    src = g.sample(in0, nx, ny)
    src = np.dstack([zap(src[..., 0:3], 0), zap(src[..., 3:4], 1)]).astype(F32)

    env_ink = F32(1) if bug == "ink_no_env" else F32(env)
    ink = src[..., 0:3] * (c0 * F32(amount) * env_ink)[..., None]
    out0 = np.dstack([ink, np.ones((h, w, 1), F32)]).astype(F32)

    vin = np.zeros((h, w, 4), F32) if in1 is None else g.sample(in1, nx, ny)
    vin = zap(vin, 0.5)
    conn = F32(1) if bug == "value_flag" else F32(1 if src_vec >= 0.5 else 0)

    gain_in = c0 * F32(env) * F32(force)
    in_x = (vin[..., 0] - F32(0.5)) * F32(2) * gain_in
    in_y = (vin[..., 1] - F32(0.5)) * F32(2) * gain_in
    fx, fy = impulse_field(cov_at, c0, ix, iy, w, h, field, reach, impulse, bug)
    fx = fx * F32(env) * F32(force)
    fy = fy * F32(env) * F32(force)
    vx = _mix(fx, in_x, conn)
    vy = _mix(fy, in_y, conn)

    half = np.full((h, w), F32(0.5))
    one = np.ones((h, w), F32)
    out1 = np.dstack([np.clip(vx * F32(0.5) + F32(0.5), 0, 1), np.clip(vy * F32(0.5) + F32(0.5), 0, 1),
                      half, one]).astype(F32)

    pass1 = np.dstack([_mix(half, vin[..., 0], conn), _mix(half, vin[..., 1], conn), half, one]).astype(F32)
    return _mix(out0, src, bypass_gate), _mix(out1, pass1, bypass_gate)


def decode(out1):
    """out1 back to vecfield units."""
    return (out1[..., 0] - F32(0.5)) * F32(2), (out1[..., 1] - F32(0.5)) * F32(2)


def disc(n, cx=0.5, cy=0.5, r=0.2, ramp=0.0, rgb=(1.0, 1.0, 1.0), periodic=True):
    """Test stamp: a disc on black. ramp = luma ramp width as a fraction of the frame (0 = hard)."""
    nx, ny, _, _ = g.grid(n, n)
    dx = nx - F32(cx)
    dy = ny - F32(cy)
    if periodic:
        dx = dx - np.round(dx)
        dy = dy - np.round(dy)
    d = np.sqrt(dx * dx + dy * dy)
    if ramp > 0:
        m = np.clip((F32(r) + F32(ramp) / 2 - d) / F32(ramp), 0, 1)
    else:
        m = (d < F32(r)).astype(F32)
    t = g.texture(n, n)
    for i in range(3):
        t[..., i] = m * F32(rgb[i])
    t[..., 3] = 1
    return t


def project(vx, vy):
    """f_vf_fluid's Helmholtz projection (docs/f-reference/f_vf_fluid.md), float64 FFT, Nyquist
    zeroed in k. Used to predict what project = 1 leaves of a field; it is not the fluid solver."""
    h, w = vx.shape
    kx = np.fft.fftfreq(w) * w
    ky = np.fft.fftfreq(h) * h
    kx[w // 2] = 0
    ky[h // 2] = 0
    KX, KY = np.meshgrid(kx, ky)
    k2 = KX * KX + KY * KY
    k2[k2 == 0] = 1    # DC and the Nyquist-zeroed bins: their numerator is zero too
    ux = np.fft.fft2(vx.astype(np.float64))
    uy = np.fft.fft2(vy.astype(np.float64))
    d = (KX * ux + KY * uy) / k2
    return np.fft.ifft2(ux - KX * d).real, np.fft.ifft2(uy - KY * d).real
