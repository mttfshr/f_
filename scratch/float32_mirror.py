"""
float32_mirror.py -- is the GPU/NumPy gap of the multi-start gather float32 arithmetic?

The earlier mirror (multi_guess_gather2.py) did its arithmetic in float64 and only read the texture in float32. The
project's rule is a pass-for-pass FLOAT32 mirror, so this redoes the exact program tests/gather_proto.make_code_fn
generates with every intermediate rounded to float32 (dtype switch: float64 = the old behaviour, as a sanity check).
Same config as the GPU test: G=6, M=4, T=6, S=2, field texture 256^2 = output 256^2, central 96x96 crop.

Compared against the photon-counting truth, and pixel-by-pixel against the actual GPU image from the bench.
Run:  uv run --no-project --with numpy python3 scratch/float32_mirror.py
"""
import sys
from pathlib import Path

import numpy as np

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "tests"))
sys.path.insert(0, str(HERE))
import caustic_fidelity as cf       # noqa: E402
import gather_proto as gp           # noqa: E402
import multi_guess_gather2 as mg    # noqa: E402

g = cf.g
LAM, DEDUP, EPS, STEP_CAP = 0.05, 2e-3, 0.05, 0.1
G, M, T, S = 6, 4, 6, 2
FSIZE = 256
CROP = mg.CROP


def run(d, tol, dt, field):
    f = dt
    lo, hi = CROP
    n = 256
    centres = ((np.arange(n, dtype=np.float64) + 0.5) / n).astype(f)
    cy_, cx_ = np.meshgrid(centres[lo:hi], centres[lo:hi], indexing="ij")     # rows = y, cols = x
    X0, Y0 = cx_.ravel(), cy_.ravel()
    hh = f(1.0 / FSIZE)
    kk_slope = f(FSIZE / 2.0)
    d, peak, tol = f(d), f(0.9), f(tol)
    rho = d * peak

    def fl(a):
        return a - np.floor(a)

    def F(u, v):                                                               # (fx, fy) at wrapped (u, v)
        s = g.sample(field, fl(u).astype(np.float32), fl(v).astype(np.float32))
        return (s[..., 0].astype(f) - f(0.5)) * f(2.0), (s[..., 1].astype(f) - f(0.5)) * f(2.0)

    total = np.zeros(X0.size, f)
    for sub in range(S * S):
        sox = f((sub % S + 0.5) / S - 0.5)
        soy = f((sub // S + 0.5) / S - 0.5)
        x0 = X0 + sox / f(n)
        y0 = Y0 + soy / f(n)
        # coarse points and residuals
        cxs, cys, rs = [], [], []
        for j in range(G * G):
            jx, jy = j % G, j // G
            cx = x0 + f(-1.0 + 2.0 * jx / (G - 1)) * rho
            cy = y0 + f(-1.0 + 2.0 * jy / (G - 1)) * rho
            fx, fy = F(cx, cy)
            qx, qy = cx + d * fx - x0, cy + d * fy - y0
            cxs.append(cx)
            cys.append(cy)
            rs.append(np.sqrt(qx * qx + qy * qy))
        cxs, cys, rs = np.stack(cxs, 1), np.stack(cys, 1), np.stack(rs, 1)
        idx = np.argsort(rs, axis=1, kind="stable")[:, :M]
        ux = [np.take_along_axis(cxs, idx[:, m:m + 1], 1)[:, 0] for m in range(M)]
        uy = [np.take_along_axis(cys, idx[:, m:m + 1], 1)[:, 0] for m in range(M)]
        ic = np.zeros(X0.size, f)
        acs = []
        for m in range(M):
            u, v = ux[m], uy[m]

            def eval_at(u, v):
                fx, fy = F(u, v)
                wu, wv = fl(u), fl(v)
                xpx, xpy = F(wu + hh, wv)
                xmx, xmy = F(wu - hh, wv)
                ypx, ypy = F(wu, wv + hh)
                ymx, ymy = F(wu, wv - hh)
                na = f(1.0) + d * (xpx - xmx) * kk_slope
                nb = d * (ypx - ymx) * kk_slope
                nc = d * (xpy - xmy) * kk_slope
                nd = f(1.0) + d * (ypy - ymy) * kk_slope
                gx, gy = u + d * fx - x0, v + d * fy - y0
                return gx, gy, na, nb, nc, nd

            for _ in range(T):
                gx, gy, na, nb, nc, nd = eval_at(u, v)
                m11 = na * na + nc * nc + f(LAM)
                m12 = na * nb + nc * nd
                m22 = nb * nb + nd * nd + f(LAM)
                r1, r2 = na * gx + nc * gy, nb * gx + nd * gy
                dm = m11 * m22 - m12 * m12
                stx, sty = (m22 * r1 - m12 * r2) / dm, (m11 * r2 - m12 * r1) / dm
                kk = np.minimum(f(1.0), f(STEP_CAP) / np.maximum(np.sqrt(stx * stx + sty * sty), f(1e-12)))
                u, v = u - stx * kk, v - sty * kk
            ux[m], uy[m] = u, v
            gx, gy, na, nb, nc, nd = eval_at(u, v)
            ac = (np.sqrt(gx * gx + gy * gy) < tol).astype(f)
            for k in range(m):
                dk = np.sqrt((u - ux[k]) * (u - ux[k]) + (v - uy[k]) * (v - uy[k]))
                ac = ac * (f(1.0) - acs[k] * (f(1.0) - (dk >= f(DEDUP)).astype(f)))
            acs.append(ac)
            ic = ic + ac / np.maximum(np.abs(na * nd - nb * nc), f(EPS))
        total = total + ic
    side = hi - lo
    return (total / f(S * S)).reshape(side, side).astype(np.float64)


def main():
    field = gp.analytic_field(cf, FSIZE)
    lo, hi = CROP
    gpu = {}
    try:                                                                        # the real GPU image, if the bench answers
        import benchclient as bc
        bc.reopen(wait=40.0)
        white = np.ones((256, 256, 4), np.float32)
        code = gp.make_code_fn(G, M, T, S)
        for fr in (1.0, 2.0, 3.5):
            d = fr * cf.first_fold_distance()
            gp.ensure_healthy(bc)
            img, rep = bc.run_pass(code, [white, field], dim=(256, 256), params={"d": d, "peak": 0.9, "tol": 1e-3}, timeout_ms=90000)
            gpu[fr] = img[lo:hi, lo:hi, 0].astype(np.float64)
    except Exception as e:                                                      # NumPy-only run still useful
        print("(no GPU image:", type(e).__name__, e, ")")
    print(f"G={G} M={M} T={T} S={S}, tol 1e-3, field {FSIZE}^2, crop {lo}:{hi}; photon-counting truth; GPU = codebox on the bench")
    print(f"{'d/d*':>5} {'arithmetic':<16} | {'r vs truth':>10} {'IoU':>6} {'mean':>6} | {'r vs GPU image':>14}")
    for fr in (1.0, 2.0, 3.5):
        d = fr * cf.first_fold_distance()
        truth = cf.truth(d)[lo:hi, lo:hi]
        rows = [("float64 mirror", run(d, 1e-3, np.float64, field)), ("float32 mirror", run(d, 1e-3, np.float32, field))]
        if fr in gpu:
            rows.append(("GPU (bench)", gpu[fr]))
        for name, img in rows:
            vs_gpu = f"{cf.pearson(img, gpu[fr]):14.4f}" if fr in gpu else f"{'':>14}"
            print(f"{fr:5.1f} {name:<16} | {cf.pearson(img, truth):10.3f} {cf.top_iou(img, truth):6.3f} {img.mean():6.3f} | {vs_gpu}", flush=True)
        print()


if __name__ == "__main__":
    main()
