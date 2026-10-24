"""
spike_wc_character.py -- f_wc, second-tier performable-axis ranking (2026-10-23).

Which baked constants move CHARACTER enough to deserve a dial? Two mirror
sweeps at the shipped corner (N = 128, fast_fft, rate 1.0, 1200 frames,
one seed per cell; transient caveat applies):

  GRID A -- sigma ratio (sigma_E = sigma_I / ratio; shipped 1.45, the Rule
    2/2.9 aspect) x grain (sigma_I; the landmarks 1.1/1.4/1.9). Geometry
    axis: kernel ratio is the literature's rolls/labyrinth/spots axis.
    Reported: late std, wc_classify label, wavelength.

  GRID B -- sigmoid threshold bias (he = 3.1 + b, hi = 3.5 + b, shifted
    together as one "excitability" axis) x Ne. Operating-point axis: moves
    along the saturation boundary (night-1 record: thresholds load-bearing).
    Reported: late std, mean, saturated fraction.

Usage: uv run --no-project --with numpy python3 tests/records/spike_wc_character.py
CSV to stdout.
"""
import os
import sys
import time

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "lib"))
sys.path.insert(0, os.path.join(HERE, "..", "modules", "wc"))
sys.path.insert(0, HERE)
import wc_mirror as km  # noqa: E402
import wc_classify as C  # noqa: E402

N = 128
FRAMES = 1200


def run_cell(P, seed=11):
    rng = np.random.default_rng(seed)
    state = km.seed_state(N, N, seed)
    late_mean, late_std = [], []
    for f in range(1, FRAMES + 1):
        state = km.wc_frame(state, rng, P)
        if f >= FRAMES - 100 and f % 10 == 0:
            late_mean.append(float(state[..., 0].mean()))
            late_std.append(float(state[..., 0].std()))
    e = state[..., 0]
    sat = float(np.mean((e > 0.99) | (e < 0.01)))
    label, k_star, det = C.classify(e)
    return (np.mean(late_mean), np.mean(late_std), sat, label,
            det.get("lambda_px", float("inf")), det.get("f2", 0), det.get("f6", 0))


def main():
    t0 = time.time()
    print("# GRID A: sigma_ratio,grain,mean,std,sat,label,lambda_px,f2,f6")
    for ratio in (1.1, 1.3, 1.45, 1.7, 2.0, 2.5):
        for grain in (1.1, 1.4, 1.9):
            P = km.Params(rate=1.0, texture=grain, ne=1.0, sig_ratio=ratio,
                          fast_fft=True)
            m, s, sat, label, lam, f2, f6 = run_cell(P)
            print(f"A,{ratio},{grain},{m:.4f},{s:.4f},{sat:.3f},{label},"
                  f"{lam:.1f},{f2:.3f},{f6:.3f}", flush=True)
    print("# GRID B: thresh_bias,ne,mean,std,sat,label,lambda_px,f2,f6")
    for b in (-1.0, -0.5, 0.0, 0.5, 1.0):
        for ne in (0.8, 1.0, 1.2):
            P = km.Params(rate=1.0, texture=1.4, ne=ne,
                          he=3.1 + b, hi=3.5 + b, fast_fft=True)
            m, s, sat, label, lam, f2, f6 = run_cell(P)
            print(f"B,{b},{ne},{m:.4f},{s:.4f},{sat:.3f},{label},"
                  f"{lam:.1f},{f2:.3f},{f6:.3f}", flush=True)
    print(f"# {time.time() - t0:.0f}s total", flush=True)


if __name__ == "__main__":
    main()
