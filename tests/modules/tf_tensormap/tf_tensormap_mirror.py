"""
tf_tensormap_mirror.py -- NumPy mirror of the tf_tensormap shader: the functions (and the constants and
fixtures they need) that tests/modules/tf_tensormap/bench_tf_tensormap.py imports. Extracted
from test_tf_tensormap.py in Phase C, 2026-10-18; the tests stay there.
"""
import numpy as np
import gpu_sim as g  # noqa: E402

F32 = np.float32
R_MAX = 8            # provisional (T016/T017 pick the real one)
EPS_TRACE = F32(1e-6)  # provisional (T019)
STRENGTH = F32(12.0)   # provisional default


def _luma601(tex):
    return (F32(0.299) * tex[..., 0] + F32(0.587) * tex[..., 1]
            + F32(0.114) * tex[..., 2]).astype(F32)


def stage_a(src):
    """src: RGBA texture. Returns RGBA (gx^2, gx*gy, gy^2, 1)."""
    h, w = src.shape[:2]
    nx, ny, _, _ = g.grid(h, w)
    dx, dy = F32(1.0 / w), F32(1.0 / h)

    def L(ox, oy):
        return _luma601(g.nearest(src, nx + F32(ox) * dx, ny + F32(oy) * dy))

    tl, tc, tr = L(-1, -1), L(0, -1), L(1, -1)
    ml, mr = L(-1, 0), L(1, 0)
    bl, bc, br = L(-1, 1), L(0, 1), L(1, 1)
    gx = (-tl + tr) + F32(-2) * ml + F32(2) * mr + (-bl + br)
    gy = (-tl - F32(2) * tc - tr) + (bl + F32(2) * bc + br)
    out = g.texture(h, w)
    out[..., 0] = gx * gx
    out[..., 1] = gx * gy
    out[..., 2] = gy * gy
    out[..., 3] = F32(1.0)
    return g.store_float32(out)


def stage_b(tex, radius, axis, r_max=R_MAX):
    """One separable smoothing pass. axis 0 = horizontal, 1 = vertical."""
    h, w = tex.shape[:2]
    nx, ny, _, _ = g.grid(h, w)
    acc = np.zeros((h, w, 4), F32)
    count = np.zeros((h, w), F32)
    for i in range(-r_max, r_max + 1):
        wt = F32(1.0) if abs(i) <= radius else F32(0.0)
        if axis == 0:
            s = g.nearest(tex, nx + F32(i) / F32(w), ny)
        else:
            s = g.nearest(tex, nx, ny + F32(i) / F32(h))
        acc += wt * s
        count += wt
    count = np.maximum(count, F32(1.0))
    return g.store_float32(acc / count[..., None])


def eigen_closed(Jxx, Jxy, Jyy):
    trace = Jxx + Jyy
    diff = Jxx - Jyy
    root = np.sqrt(diff * diff + F32(4) * Jxy * Jxy)
    return trace, diff, root


def stage_c(tex, strength=STRENGTH, eps=EPS_TRACE, flip_jxy=False):
    """Returns (outlet0, outlet1) RGBA textures."""
    Jxx, Jxy, Jyy = tex[..., 0], tex[..., 1], tex[..., 2]
    if flip_jxy:
        Jxy = -Jxy
    trace, diff, root = eigen_closed(Jxx, Jxy, Jyy)
    theta = F32(0.5) * np.arctan2(F32(2) * Jxy, diff)
    iso = trace < eps

    o0 = g.texture(*Jxx.shape)
    o0[..., 0] = Jxx * strength
    o0[..., 1] = Jxy * strength * F32(0.5) + F32(0.5)
    o0[..., 2] = Jyy * strength
    o0[..., 3] = F32(1.0)

    o1 = g.texture(*Jxx.shape)
    safe_trace = np.maximum(trace, eps)
    o1[..., 0] = np.cos(F32(2) * theta) * F32(0.5) + F32(0.5)
    o1[..., 1] = np.sin(F32(2) * theta) * F32(0.5) + F32(0.5)
    o1[..., 2] = np.clip(trace * strength, 0, 1)
    o1[..., 3] = np.clip(root / safe_trace, 0, 1)
    o1[root < eps, 0:2] = F32(0.5)   # direction undefined (equal eigenvalues)
    o1[iso] = np.array([0.5, 0.5, 0.0, 0.0], F32)
    return g.store_float32(o0), g.store_float32(o1)
