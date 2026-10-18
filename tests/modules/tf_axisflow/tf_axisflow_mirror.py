"""
tf_axisflow_mirror.py -- NumPy mirror of the tf_axisflow shader: the functions (and the constants and
fixtures they need) that tests/modules/tf_axisflow/bench_tf_axisflow.py imports. Extracted
from test_tf_axisflow.py in Phase C, 2026-10-18; the tests stay there.
"""
import numpy as np
import gpu_sim as g  # noqa: E402

F32 = np.float32
LEN_MAX = F32(1.05)      # content guard: valid packed input has |(c2,s2)| <= 1
EPS_LEN = F32(1e-6)


# --- mirror shader -----------------------------------------------------

def axisflow(t, angle=0.0, mode=0, gain=1.0, gate=1.0, width=64.0, height=64.0,
             bypass=0.0, swap=False, ref=None):
    """The codebox, in NumPy. t: packed tensormap outlet 1 (H,W,4). Returns vecfield RGBA.
    ref: optional per-pixel reference vecfield (H,W,4, in2); None = the `angle` dial's constant r."""
    c2 = (t[..., 0] - F32(0.5)) * F32(2)
    s2 = (t[..., 1] - F32(0.5)) * F32(2)
    ln = np.sqrt(c2 * c2 + s2 * s2)
    ok = (ln >= EPS_LEN).astype(F32) * (ln < LEN_MAX).astype(F32)   # iso and vs_black -> 0
    phi = F32(angle) * F32(np.pi) / F32(180)
    ca, sa = F32(np.cos(phi)), F32(np.sin(phi))
    sh = F32(min(width, height))
    if ref is None:
        rx, ry = ca, sa
    else:                       # per-pixel reference: B gate (vs_black -> 0), pixel space, rotated
        use = (np.abs(ref[..., 2] - F32(0.5)) < F32(0.25)).astype(F32)
        px = (ref[..., 0] - F32(0.5)) * F32(2) * F32(width) / sh
        py = (ref[..., 1] - F32(0.5)) * F32(2) * F32(height) / sh
        rx = ca + (ca * px - sa * py - ca) * use
        ry = sa + (sa * px + ca * py - sa) * use
    ax = F32(0.5) * ((F32(1) + c2) * rx + s2 * ry)        # across: (g.r) g
    ay = F32(0.5) * (s2 * rx + (F32(1) - c2) * ry)
    m = F32(1 - mode) if swap else F32(mode)
    vx = (rx - ax) * (F32(1) - m) + ax * m                # mode 0 = along = r - across
    vy = (ry - ay) * (F32(1) - m) + ay * m
    mag = ok * F32(gain) * ((F32(1) - F32(gate)) + F32(gate) * t[..., 3])
    o = g.texture(*c2.shape)
    o[..., 0] = np.clip(vx * mag * sh / F32(width) * F32(0.5) + F32(0.5), 0, 1)
    o[..., 1] = np.clip(vy * mag * sh / F32(height) * F32(0.5) + F32(0.5), 0, 1)
    o[..., 2] = F32(0.5)
    o[..., 3] = F32(1.0)
    neutral = np.array([0.5, 0.5, 0.5, 1.0], F32)
    o = o * (F32(1) - F32(bypass)) + neutral * F32(bypass)
    return g.store_float32(o)


# --- per-pixel reference inlet (2026-10-17) ----------------------------

def refvec(vx, vy, shape=(4, 4)):
    """Constant reference f_vecfield; (vx, vy) is the DECODED vector, normalized screen units."""
    r = g.texture(*shape)
    r[..., 0] = F32(vx * 0.5 + 0.5)
    r[..., 1] = F32(vy * 0.5 + 0.5)
    r[..., 2] = F32(0.5)
    r[..., 3] = F32(1.0)
    return g.store_float32(r)


def _swirl(n):
    """Rigid swirl reference (decoded components within +-0.8) on an n x n frame."""
    y, x = np.mgrid[0:n, 0:n]
    cx, cy = (x + 0.5) / n - 0.5, (y + 0.5) / n - 0.5
    vx, vy = -cy * 1.6, cx * 1.6
    r = g.texture(n, n)
    r[..., 0] = (vx * 0.5 + 0.5).astype(F32)
    r[..., 1] = (vy * 0.5 + 0.5).astype(F32)
    r[..., 2] = F32(0.5)
    r[..., 3] = F32(1.0)
    return g.store_float32(r), vx, vy
