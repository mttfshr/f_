"""
multi_guess_gather2.py -- (1) does the multi-start gather survive reading a real field TEXTURE, and
(2) can smarter starting guesses cut its cost?   Follow-up to multi_guess_gather.py.

(1) "texture" evaluator: the field comes from a 512x512 float32 texture (bilinear), slopes by central difference
    (+-1/512), like a shader would. The earlier script used the analytic field and Jacobian.
(2) "coarse search" starts: instead of K starts on a fixed grid, look at G x G coarse points around the pixel,
    keep those whose image u + dF(u) lands near the pixel (|residual| < tau), at most M of them, and run Newton
    from only those. Cost per sample = G^2 field reads + (starts used) * T * 5 reads.

Everything is compared on the same central crop of the 256x256 output, against the photon-counting truth
(caustic_fidelity.truth), at 1.0, 2.0, 3.5 d*, with 2x2 samples per pixel. Texture sampling is periodic here
(the test glass and the truth are periodic); a real texture would clamp at the edges.

Run:  uv run --no-project --with numpy python3 scratch/multi_guess_gather2.py
"""
import os
import sys
import time

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "tests"))
sys.path.insert(0, HERE)
import caustic_fidelity as cf   # noqa: E402

g = cf.g
NB, S = cf.NB, 2
LAM, TOL, DEDUP, EPS, STEP_CAP = 0.05, 1e-4, 2e-3, 0.05, 0.1
CROP = (80, 176)                    # output rows/cols evaluated (96 x 96 pixels)
TEX = np.asarray(cf.field_texture(), np.float32)
H = 1.0 / 512.0


# ---------------------------------------------------------------- evaluators
def ev_analytic(u, v):
    fx, fy, jxx, jxy, jyy = cf.field(u, v)
    return fx, fy, jxx, jxy, jxy, jyy                      # J = [[jxx, jxy], [jyx, jyy]]


def _samp(u, v):
    return (g.sample(TEX, np.mod(u, 1.0).astype(np.float32), np.mod(v, 1.0).astype(np.float32))[..., :2]
            .astype(np.float64) - 0.5) * 2.0


def ev_texture(u, v):
    c = _samp(u, v)
    xp, xm, yp, ym = _samp(u + H, v), _samp(u - H, v), _samp(u, v + H), _samp(u, v - H)
    jxx = (xp[..., 0] - xm[..., 0]) / (2 * H)              # dFx/dx
    jyx = (xp[..., 1] - xm[..., 1]) / (2 * H)              # dFy/dx
    jxy = (yp[..., 0] - ym[..., 0]) / (2 * H)              # dFx/dy
    jyy = (yp[..., 1] - ym[..., 1]) / (2 * H)              # dFy/dy
    return c[..., 0], c[..., 1], jxx, jxy, jyx, jyy


def field_only(u, v):
    c = _samp(u, v)
    return c[..., 0], c[..., 1]


# ---------------------------------------------------------------- the solver
def newton(X, Y, ux, uy, mask, d, ev, T):
    for _ in range(T):
        fx, fy, jxx, jxy, jyx, jyy = ev(ux, uy)
        gx, gy = ux + d * fx - X, uy + d * fy - Y
        a, b, c_, e = 1 + d * jxx, d * jxy, d * jyx, 1 + d * jyy
        m11, m12, m22 = a * a + c_ * c_ + LAM, a * b + c_ * e, b * b + e * e + LAM
        r1, r2 = a * gx + c_ * gy, b * gx + e * gy
        dm = m11 * m22 - m12 * m12
        sx, sy = (m22 * r1 - m12 * r2) / dm, (-m12 * r1 + m11 * r2) / dm
        k = np.minimum(1.0, STEP_CAP / np.maximum(np.hypot(sx, sy), 1e-12))
        ux, uy = ux - sx * k, uy - sy * k
    fx, fy, jxx, jxy, jyx, jyy = ev(ux, uy)
    res = np.hypot(ux + d * fx - X, uy + d * fy - Y)
    det = (1 + d * jxx) * (1 + d * jyy) - (d * jxy) * (d * jyx)
    valid = mask & (res < TOL)
    keep = np.zeros_like(valid)
    for k_ in range(valid.shape[1]):
        dup = np.zeros(valid.shape[0], bool)
        for j in range(k_):
            dup |= keep[:, j] & (np.hypot(ux[:, k_] - ux[:, j], uy[:, k_] - uy[:, j]) < DEDUP)
        keep[:, k_] = valid[:, k_] & ~dup
    return (keep / np.maximum(np.abs(det), EPS)).sum(axis=1), keep.sum(axis=1)


def grid_offsets(K, rho):
    side = int(round(np.sqrt(K)))
    if side == 1:
        return np.zeros((1, 2))
    t = np.linspace(-1, 1, side)
    ox, oy = np.meshgrid(t, t)
    return np.stack([ox.ravel(), oy.ravel()], axis=1) * rho


def run(d, ev, starts, T, lam_max=None, chunk=3000):
    """starts = ('grid', K) or ('coarse', G, tau_factor, M). Returns image, roots/px, starts used, reads/px."""
    n = NB * S
    c = (np.arange(n) + 0.5) / n
    GX, GY = np.meshgrid(c[S * CROP[0]:S * CROP[1]], c[S * CROP[0]:S * CROP[1]])
    px, py = GX.ravel(), GY.ravel()
    rho = d * cf.PEAK
    out, nroots, nstarts = np.zeros(px.size), np.zeros(px.size), np.zeros(px.size)
    for s0 in range(0, px.size, chunk):
        X, Y = px[s0:s0 + chunk, None], py[s0:s0 + chunk, None]
        if starts[0] == "grid":
            offs = grid_offsets(starts[1], rho)
            ux, uy = X + offs[None, :, 0], Y + offs[None, :, 1]
            mask = np.ones(ux.shape, bool)
            coarse_reads = 0
        else:
            _, G, tauf, M = starts
            offs = grid_offsets(G * G, rho)
            cx, cy = X + offs[None, :, 0], Y + offs[None, :, 1]
            fx, fy = field_only(cx, cy)
            resid = np.hypot(cx + d * fx - X, cy + d * fy - Y)
            hc = 2 * rho / (G - 1)
            tau = tauf * hc * (1 + d * lam_max)
            idx = np.argsort(resid, axis=1)[:, :M]
            rr = np.take_along_axis(resid, idx, axis=1)
            ux, uy = np.take_along_axis(cx, idx, axis=1), np.take_along_axis(cy, idx, axis=1)
            mask = rr < tau
            coarse_reads = G * G
        i_, nr = newton(X, Y, ux, uy, mask, d, ev, T)
        out[s0:s0 + chunk], nroots[s0:s0 + chunk], nstarts[s0:s0 + chunk] = i_, nr, mask.sum(axis=1)
    m = CROP[1] - CROP[0]
    img = out.reshape(m * S, m * S).reshape(m, S, m, S).mean(axis=(1, 3))
    reads = (coarse_reads + nstarts.mean() * T * 5) * S * S
    return img, nroots.mean(), nstarts.mean(), reads


def main():
    dstar = cf.first_fold_distance()
    lam_max = 0.0
    c = (np.arange(128) + 0.5) / 128
    X_, Y_ = np.meshgrid(c, c)
    _, _, jxx, jxy, jyy = cf.field(X_, Y_)
    lam_max = float(np.max(np.abs((jxx + jyy) / 2) + np.sqrt(((jxx - jyy) / 2) ** 2 + jxy ** 2)))
    print(f"d* = {dstar:.4f}; max |eigenvalue| of the field's slope = {lam_max:.1f}; crop {CROP} of {NB}, S = {S}")
    print("reads/px = texture reads per OUTPUT pixel (5 per Newton step: field + 4 for slopes; 1 per coarse point)\n")
    print(f"{'d/d*':>5} {'evaluator':<9} {'starts':<26} {'T':>2} | {'r':>6} {'IoU':>5} {'mean':>6} {'roots':>5} {'used':>5} {'reads/px':>9}")
    print("-" * 96)
    for fr in (1.0, 2.0, 3.5):
        d = fr * dstar
        truth = cf.truth(d)[CROP[0]:CROP[1], CROP[0]:CROP[1]]
        cases = [("analytic", ev_analytic, ("grid", 36), 8),
                 ("texture", ev_texture, ("grid", 16), 8),
                 ("texture", ev_texture, ("grid", 36), 8),
                 ("texture", ev_texture, ("coarse", 6, 1.0, 8), 6),
                 ("texture", ev_texture, ("coarse", 6, 1.5, 8), 6),
                 ("texture", ev_texture, ("coarse", 6, 1.5, 8), 4),
                 ("texture", ev_texture, ("coarse", 9, 1.5, 8), 4)]
        for name, ev, st, T in cases:
            t0 = time.time()
            img, roots, used, reads = run(d, ev, st, T, lam_max)
            label = "grid K=%d" % st[1] if st[0] == "grid" else "coarse G=%d tau=%.1f M=%d" % st[1:]
            print(f"{fr:5.1f} {name:<9} {label:<26} {T:>2} | {cf.pearson(img, truth):6.3f} {cf.top_iou(img, truth):5.3f} "
                  f"{img.mean():6.3f} {roots:5.2f} {used:5.1f} {reads:9.0f}   ({time.time() - t0:.0f}s)", flush=True)
        print("-" * 96)


if __name__ == "__main__":
    main()
