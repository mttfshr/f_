"""
multi_guess_gather.py -- can a PULL (gather) method reach the sheet regime?

Question (Matt, 2026-10-06): a pixel can only follow one trail back, so a plain gather finds one source of
light per pixel and fails once light from several glass points piles onto one pixel. Is there a
pull-based trick that gets further, e.g. starting each pixel's search from several guesses?

Method tested here: MULTI-START NEWTON. For screen pixel x, the glass points u that land there solve
    g(u) = u + d F(u) - x = 0.
From K starting guesses on a grid around x (the sources lie within d*max|F| of x), run T damped Newton
steps  u <- u - (A^T A + lam I)^-1 A^T g,  A = I + d J(u);  accept converged roots, drop duplicates, and sum
1/|det A| over the distinct roots (uniform source). Illuminance, mean 1 over the periodic test domain.

Ground truth: photon counting (caustic_fidelity.truth). The analytic field and Jacobian are used, so this is
an UPPER BOUND on what a shader reading field textures could do. Energy check: if every source were found the
mean illuminance would be exactly 1.0; the shortfall measures missed sources.

Run:  uv run --no-project --with numpy python3 scratch/multi_guess_gather.py
"""
import os
import sys
import time

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "tests"))
sys.path.insert(0, HERE)
import caustic_fidelity as cf   # noqa: E402

NB = cf.NB            # 256 output pixels
T = 8                 # Newton iterations
LAM = 0.05            # damping
TOL = 1e-4            # converged if |g| below this (UV); a pixel is 1/256 = 0.0039
DEDUP = 2e-3          # two roots closer than this (UV) are one
EPS = 0.05            # |det| floor, as in the earlier determinant-gather probe
STEP_CAP = 0.1        # max Newton step length (UV)


def gather(d, K, S, chunk=4096):
    """Illuminance on an NB x NB screen with S x S samples per pixel; K starts per sample."""
    n = NB * S
    c = (np.arange(n) + 0.5) / n
    GX, GY = np.meshgrid(c, c)
    px, py = GX.ravel(), GY.ravel()
    rho = d * cf.PEAK
    side = int(round(np.sqrt(K)))
    if side * side != K:
        raise ValueError("K must be a perfect square")
    if side == 1:
        offs = np.zeros((1, 2))
    else:
        t = np.linspace(-1, 1, side)
        ox, oy = np.meshgrid(t, t)
        offs = np.stack([ox.ravel(), oy.ravel()], axis=1) * rho
    out = np.zeros(px.size)
    nroots = np.zeros(px.size)
    for s0 in range(0, px.size, chunk):
        X = px[s0:s0 + chunk, None]
        Y = py[s0:s0 + chunk, None]
        ux = X + offs[None, :, 0]
        uy = Y + offs[None, :, 1]
        for _ in range(T):
            fx, fy, jxx, jxy, jyy = cf.field(ux, uy)
            gx, gy = ux + d * fx - X, uy + d * fy - Y
            a, b, e = 1 + d * jxx, d * jxy, 1 + d * jyy                     # A = [[a, b], [b, e]] (J symmetric)
            m11, m12, m22 = a * a + b * b + LAM, b * (a + e), b * b + e * e + LAM
            r1, r2 = a * gx + b * gy, b * gx + e * gy                       # A^T g
            det_m = m11 * m22 - m12 * m12
            sx = (m22 * r1 - m12 * r2) / det_m
            sy = (-m12 * r1 + m11 * r2) / det_m
            ln = np.hypot(sx, sy)
            k = np.minimum(1.0, STEP_CAP / np.maximum(ln, 1e-12))
            ux, uy = ux - sx * k, uy - sy * k
        fx, fy, jxx, jxy, jyy = cf.field(ux, uy)
        res = np.hypot(ux + d * fx - X, uy + d * fy - Y)
        det = (1 + d * jxx) * (1 + d * jyy) - (d * jxy) ** 2
        valid = res < TOL
        keep = np.zeros_like(valid)
        for k_ in range(valid.shape[1]):
            dup = np.zeros(valid.shape[0], bool)
            for j in range(k_):
                dup |= keep[:, j] & (np.hypot(ux[:, k_] - ux[:, j], uy[:, k_] - uy[:, j]) < DEDUP)
            keep[:, k_] = valid[:, k_] & ~dup
        out[s0:s0 + chunk] = (keep / np.maximum(np.abs(det), EPS)).sum(axis=1)
        nroots[s0:s0 + chunk] = keep.sum(axis=1)
    img = out.reshape(n, n).reshape(NB, S, NB, S).mean(axis=(1, 3))
    return img, nroots.reshape(n, n).reshape(NB, S, NB, S).mean(axis=(1, 3))


def main():
    dstar = cf.first_fold_distance()
    print(f"test glass seed {os.environ.get('SEED', '7')}: d* = {dstar:.4f}; truth is photon counting, periodic, mean 1")
    print("scatter (GPU, measured earlier) for reference: r 0.999 / 0.999 / 0.994 at 0.6 / 1.0 / 3.5 d*\n")
    print(f"{'d/d*':>5} {'K':>3} {'S':>2} | {'r vs truth':>10} {'IoU':>6} {'mean illum':>10} {'roots/px':>8} | {'time':>6}")
    print("-" * 64)
    for fr in (1.0, 2.0, 3.5):
        d = fr * dstar
        truth = cf.truth(d)
        for K, S in ((1, 2), (4, 2), (9, 2), (16, 2), (36, 2), (16, 1)):
            t0 = time.time()
            img, nr = gather(d, K, S)
            print(f"{fr:5.1f} {K:3d} {S:2d} | {cf.pearson(img, truth):10.4f} {cf.top_iou(img, truth):6.3f} "
                  f"{img.mean():10.4f} {nr.mean():8.2f} | {time.time() - t0:5.0f}s", flush=True)
        print("-" * 64)


if __name__ == "__main__":
    main()
