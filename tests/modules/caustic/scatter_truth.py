"""
scatter_truth.py -- the test glass and the photon-counting ground truth for the f_caustic sheets mode
(.specify/f_caustic_scatter/). Promoted on 2026-10-07 from scratch/caustic_fidelity.py (the functions the
scatter mirror needs), so tests/ no longer imports from scratch/ for this module. NumPy only.

The glass is a periodic height field h = sum of five cosines (seed 7 unless SEED is set), F = grad h scaled so
max |F| = PEAK in the module's [-1, 1] field units. The truth is photon counting: forward-splat a fine grid of
glass samples through the field and histogram where they land. It does NOT use the Jacobian formula the gather
uses, so it is an independent reference for the sheet regime.
"""
import os

import numpy as np

from gpu_sim import grid

F32 = np.float32
W = 512      # field / render resolution of the mirror (the soft module hardcodes h = 1/512)
NB = 256     # comparison resolution (2x2 block mean of the 512 renders)
M = 3072     # fine glass samples per axis for the ground truth
PEAK = 0.9   # max |F| of the test field, in the module's [-1, 1] field units
TAU = 2.0 * np.pi

# ---------------------------------------------------------------- test glass
_rng = np.random.default_rng(int(os.environ.get("SEED", "7")))
MODES = []
for _ in range(5):
    kx, ky = (int(v) for v in _rng.integers(-3, 4, size=2))
    if kx == 0 and ky == 0:
        kx = 1
    MODES.append((kx, ky, float(_rng.uniform(0.5, 1.0)), float(_rng.uniform(0, TAU))))


def raw_field(x, y):
    """F = grad h for periodic h = sum a cos(2pi(kx x + ky y) + phi), plus the analytic Jacobian entries.
    Unscaled."""
    z = np.zeros_like(x)
    fx, fy, jxx, jxy, jyy = z.copy(), z.copy(), z.copy(), z.copy(), z.copy()
    for kx, ky, a, phi in MODES:
        arg = TAU * (kx * x + ky * y) + phi
        s, c = np.sin(arg), np.cos(arg)
        fx += -a * TAU * kx * s
        fy += -a * TAU * ky * s
        jxx += -a * TAU ** 2 * kx * kx * c
        jxy += -a * TAU ** 2 * kx * ky * c
        jyy += -a * TAU ** 2 * ky * ky * c
    return fx, fy, jxx, jxy, jyy


_cx = (np.arange(W) + 0.5) / W
_X, _Y = np.meshgrid(_cx, _cx)
_RF = raw_field(_X, _Y)
SCALE = PEAK / np.max(np.hypot(_RF[0], _RF[1]))


def field(x, y):
    return tuple(SCALE * v for v in raw_field(x, y))


def first_fold_distance():
    """d* = 1 / (most negative Hessian eigenvalue): where the first fold forms."""
    fx, fy, jxx, jxy, jyy = field(_X, _Y)
    lam = (jxx + jyy) / 2 - np.sqrt(((jxx - jyy) / 2) ** 2 + jxy ** 2)
    return 1.0 / np.max(-lam)


def field_texture():
    """The glass as an f_vecfield texture: RG = F / 2 + 0.5 (decode in a codebox: (v - 0.5) * 2)."""
    nx, ny, _, _ = grid(W, W)
    fx, fy = field(nx.astype(np.float64), ny.astype(np.float64))[:2]
    tex = np.zeros((W, W, 4), F32)
    tex[..., 0] = (fx / 2 + 0.5).astype(F32)
    tex[..., 1] = (fy / 2 + 0.5).astype(F32)
    tex[..., 3] = 1.0
    return tex


# ------------------------------------------------------------- ground truth
def truth(d, m=M):
    """Photon-counting illuminance on an NB x NB screen, mean 1 (periodic). m = glass samples per axis
    (changing it gives an independent noise draw)."""
    edges = np.linspace(0, 1, NB + 1)
    hist = np.zeros((NB, NB))
    u = (np.arange(m) + 0.5) / m
    for r0 in range(0, m, 192):
        y = np.repeat(u[r0:r0 + 192][:, None], m, axis=1)
        x = np.repeat(u[None, :], y.shape[0], axis=0)
        fx, fy = field(x, y)[:2]
        sx = np.mod(x + d * fx, 1.0)
        sy = np.mod(y + d * fy, 1.0)
        hh, _, _ = np.histogram2d(sy.ravel(), sx.ravel(), bins=[edges, edges])
        hist += hh
    return hist * (NB * NB) / (m * m)


# ------------------------------------------------------------------ metrics
def down(a):
    a = np.asarray(a, np.float64)
    return a.reshape(NB, 2, NB, 2).mean(axis=(1, 3))


def interior(d):
    """NB x NB mask of the pixels no point can have left through the edge (clip, not wrap)."""
    m = d * PEAK + 0.02
    c = (np.arange(NB) + 0.5) / NB
    ok = (c > m) & (c < 1 - m)
    return ok[:, None] & ok[None, :]


def pearson(a, b):
    a = a - a.mean()
    b = b - b.mean()
    return float((a * b).sum() / np.sqrt((a * a).sum() * (b * b).sum()))


def top_iou(a, b, q=0.92):
    ta = a >= np.quantile(a, q)
    tb = b >= np.quantile(b, q)
    return float((ta & tb).sum() / max((ta | tb).sum(), 1))
