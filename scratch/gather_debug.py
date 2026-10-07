"""
gather_debug.py -- localise the GPU-vs-mirror mismatch of tests/gather_proto.py.

Runs the generated codebox in two debug modes (S = 1, one sample per pixel at the pixel centre) and compares each
intermediate with a direct NumPy computation of the same quantity:
  sel     the first of the M best coarse candidates: its residual and its offset from the pixel
  newton  where Newton from that first candidate ends after T steps, and whether it accepted it (|g| < TOL)
Run:  uv run --no-project --with numpy python3 scratch/gather_debug.py
"""
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "tests"))
sys.path.insert(0, HERE)
import benchclient as bc            # noqa: E402
import caustic_fidelity as cf       # noqa: E402
import gather_proto as gp           # noqa: E402
import multi_guess_gather2 as mg    # noqa: E402

G, M, T, S = 6, 3, 4, 1
FR = 3.5


def numpy_intermediates(d):
    n = 256
    c = (np.arange(n) + 0.5) / n
    lo, hi = mg.CROP
    side = hi - lo
    X, Y = np.meshgrid(c[lo:hi], c[lo:hi])
    px, py = X.ravel()[:, None], Y.ravel()[:, None]
    rho = d * 0.9
    offs = mg.grid_offsets(G * G, rho)
    cx, cy = px + offs[None, :, 0], py + offs[None, :, 1]
    fx, fy = mg.field_only(cx, cy)
    resid = np.hypot(cx + d * fx - px, cy + d * fy - py)
    idx = np.argsort(resid, axis=1)[:, :M]
    rb0 = np.take_along_axis(resid, idx, axis=1)[:, 0]
    sx0 = np.take_along_axis(cx, idx, axis=1)[:, 0] - px[:, 0]
    sy0 = np.take_along_axis(cy, idx, axis=1)[:, 0] - py[:, 0]
    ux = np.take_along_axis(cx, idx, axis=1)[:, :1]
    uy = np.take_along_axis(cy, idx, axis=1)[:, :1]
    for _ in range(T):                                    # Newton exactly as mg.newton does
        fxx, fyy, jxx, jxy, jyx, jyy = mg.ev_texture(ux, uy)
        gx, gy = ux + d * fxx - px, uy + d * fyy - py
        a, b, c_, e = 1 + d * jxx, d * jxy, d * jyx, 1 + d * jyy
        m11, m12, m22 = a * a + c_ * c_ + mg.LAM, a * b + c_ * e, b * b + e * e + mg.LAM
        r1, r2 = a * gx + c_ * gy, b * gx + e * gy
        dm = m11 * m22 - m12 * m12
        sx, sy = (m22 * r1 - m12 * r2) / dm, (-m12 * r1 + m11 * r2) / dm
        k = np.minimum(1.0, mg.STEP_CAP / np.maximum(np.hypot(sx, sy), 1e-12))
        ux, uy = ux - sx * k, uy - sy * k
    fxx, fyy, *_ = mg.ev_texture(ux, uy)
    res = np.hypot(ux + d * fxx - px, uy + d * fyy - py)[:, 0]
    sh = (side, side)
    return {"rb0": rb0.reshape(sh), "sx0": sx0.reshape(sh), "sy0": sy0.reshape(sh),
            "ux0": (ux[:, 0] - px[:, 0]).reshape(sh), "uy0": (uy[:, 0] - py[:, 0]).reshape(sh),
            "res": res.reshape(sh), "ac0": (res < mg.TOL).astype(float).reshape(sh)}


def main():
    bc.reopen(wait=40.0)
    d = FR * cf.first_fold_distance()
    field = np.asarray(cf.field_texture(), np.float32)
    white = np.ones((256, 256, 4), np.float32)
    ref = numpy_intermediates(d)
    lo, hi = mg.CROP
    for mode, names in (("sel", ("rb0", "sx0", "sy0")), ("newton", ("ux0", "uy0", "ac0"))):
        gp.ensure_healthy(bc)
        code = gp.make_code(G, M, T, S, debug=mode)
        img, rep = bc.run_pass(code, [white, field], dim=(256, 256), params={"d": d, "peak": 0.9}, timeout_ms=60000)
        print(f"== debug '{mode}': status {rep.get('status')}, errors {len(rep.get('errors') or [])}")
        if img is None:
            continue
        for ch, name in enumerate(names):
            gpu = img[lo:hi, lo:hi, ch].astype(np.float64)
            r = ref[name]
            corr = cf.pearson(gpu, r) if gpu.std() > 0 and r.std() > 0 else float("nan")
            print(f"   {name}: GPU mean {gpu.mean():+.5f} std {gpu.std():.5f} | NumPy mean {r.mean():+.5f} std {r.std():.5f} "
                  f"| r = {corr:.4f} | max|diff| = {np.abs(gpu - r).max():.5f}")
        if mode == "newton":
            print(f"   NumPy: fraction accepted (res < TOL) = {ref['ac0'].mean():.3f}; "
                  f"GPU accepted = {img[lo:hi, lo:hi, 2].mean():.3f}; NumPy residual after Newton: median {np.median(ref['res']):.2e}")


if __name__ == "__main__":
    main()
