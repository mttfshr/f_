"""
glass_vs_fieldmap.py -- does an analytic glass field beat "height texture -> f_vf_fieldmap"?

Scratch check for the f_vf_glass question (2026-10-06). Uses the test glass of caustic_fidelity.py
(seed 7, 5 cosine modes). Scenarios, all producing an f_vecfield texture (512^2):
  A  analytic gradient (what an analytic f_vf_glass would output)
  B  height as a FLOAT32 texture through a fieldmap emulation (central difference at +-s, bilinear)
  C  the same height quantised to 8 bits (a char texture) through the same fieldmap emulation
Each is scored by the caustic it produces (NumPy scatter emulation, 16 points per pixel):
B against A (cost of the fieldmap route), C against B (cost of 8-bit), at 1.0 and 3.5 d*.

Fieldmap emulation follows docs/f-reference/f_vf_fieldmap.md: suv = norm*(1-2s)+s,
g = (L(suv + s) - L(suv - s)) * gain, clamp to [-1, 1]. gain here is the value that recovers the
physical gradient; it is reported so it can be compared with the module's real gain range (-10..10).

Run:  uv run --no-project --with numpy python3 scratch/glass_vs_fieldmap.py
"""
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "tests"))
sys.path.insert(0, HERE)
import caustic_fidelity as cf   # noqa: E402
import spike_scatter as ss      # noqa: E402

g, F32, W = cf.g, np.float32, 512
TAU = 2 * np.pi


def height(x, y):
    h = np.zeros_like(x)
    for kx, ky, a, phi in cf.MODES:
        h += a * np.cos(TAU * (kx * x + ky * y) + phi)
    return h * cf.SCALE            # so that grad(height) == cf.field(x, y)[:2]


def to_tex(fx, fy):
    t = np.zeros((W, W, 4), F32)
    t[..., 0], t[..., 1], t[..., 2], t[..., 3] = fx / 2 + 0.5, fy / 2 + 0.5, 0.5, 1.0
    return t


def fieldmap(Ltex, gain, s, inset=True):
    nx, ny, _, _ = g.grid(W, W)
    if inset:
        sx, sy = nx * F32(1 - 2 * s) + F32(s), ny * F32(1 - 2 * s) + F32(s)
    else:                                   # diagnostic only: the module always insets
        sx, sy = nx, ny

    def L(u, v):
        return g.sample(Ltex, u, v)[..., 0]
    gx = (L(sx + F32(s), sy) - L(sx - F32(s), sy)) * F32(gain)
    gy = (L(sx, sy + F32(s)) - L(sx, sy - F32(s))) * F32(gain)
    return np.clip(gx, -1, 1), np.clip(gy, -1, 1)


def luma_tex(L):
    t = np.zeros((W, W, 4), F32)
    t[..., 0] = t[..., 1] = t[..., 2] = L
    t[..., 3] = 1.0
    return t


def rms_rel(a, b):
    return float(np.sqrt(np.mean((a - b) ** 2)) / np.sqrt(np.mean(b ** 2)))


def caustic(field_tex, d, n=1024):
    w = (ss.R / n) ** 2
    return ss.ref_scatter(ss.white(), field_tex, d, n, w, False, False, fy=1.0)[..., 0].astype(np.float64)


def main():
    c = (np.arange(W) + 0.5) / W
    X, Y = np.meshgrid(c, c)
    h = height(X, Y)
    hmin, hmax = float(h.min()), float(h.max())
    L01 = ((h - hmin) / (hmax - hmin)).astype(F32)           # the height as a 0..1 texture
    L8 = (np.round(L01 * 255) / 255).astype(F32)             # the same, as a char texture
    ax, ay = cf.field(X, Y)[:2]
    A = to_tex(ax, ay)
    dstar = cf.first_fold_distance()
    print(f"height range {hmin:.4f}..{hmax:.4f} (x{cf.SCALE:.4f}); peak |F| {np.hypot(ax, ay).max():.2f}; d* = {dstar:.4f}")
    print("fieldmap gain needed to recover the physical gradient = range / (2 s); the module's gain range is -10..10\n")
    refs = {fr: caustic(A, fr * dstar) for fr in (1.0, 3.5)}
    for s in (0.012, 0.024):
        gain = (hmax - hmin) / (2 * s)
        Bx, By = fieldmap(luma_tex(L01), gain, s)
        Cx, Cy = fieldmap(luma_tex(L8), gain, s)
        B, C = to_tex(Bx, By), to_tex(Cx, Cy)
        print(f"neighbour distance s = {s}: gain {gain:.1f} ({'in' if gain <= 10 else 'OUT OF'} the module's range); "
              f"field error vs analytic: float32 {rms_rel(np.stack([Bx, By]), np.stack([ax, ay])):.4f}, "
              f"8-bit {rms_rel(np.stack([Cx, Cy]), np.stack([ax, ay])):.4f}")
        for fr in (1.0, 3.5):
            d = fr * dstar
            mask = cf.interior(d)
            ia, ib, ic = refs[fr], caustic(B, d), caustic(C, d)
            print(f"   d = {fr} d*:  float32 vs analytic  r {cf.pearson(ib[mask], ia[mask]):.4f} IoU {cf.top_iou(ib[mask], ia[mask]):.3f}"
                  f"   |   8-bit vs analytic  r {cf.pearson(ic[mask], ia[mask]):.4f} IoU {cf.top_iou(ic[mask], ia[mask]):.3f}"
                  f"   |   8-bit vs float32  r {cf.pearson(ic[mask], ib[mask]):.4f}")
        print()


if __name__ == "__main__":
    main()
