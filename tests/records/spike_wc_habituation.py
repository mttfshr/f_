"""
spike_wc_habituation.py -- f_wc Phase 4, task T052 (2026-10-23).

Does slow subtractive adaptation (Ve, Vi relaxing toward the firing rates;
Rule Example 11: ae = 50, ai = 100) survive the saturation boundary the
labyrinth lives on? The two measurements the gate G5 needs:

  (i)  usable band width in Ne around the shipped corner (Ne = 1.0 is BAKED,
       no dial -- if adaptation shrinks or shifts the band the shipped
       default dies in place);
  (ii) E-mean drift over long runs (the soak found the plain run's E-mean
       washing toward one extreme over 30 s; adaptation is the mechanistic
       fix candidate, vs the shipped display patch sharp = 0.5).

Grid: be = bi in {0, 0.2, 0.5, 1.0} x Ne in {0.6, 0.8, 1.0, 1.2}, N = 128,
fast_fft, dt = 1 (rate 1.0), texture 1.4, 1200 frames from the same seed,
one seed per cell (the labyrinth is a transient on a saturation boundary --
single-seed cells are indicative, not definitive).

Per cell: early = mean/std of E over frames 200-300, late = frames 1100-1200,
drift = late_mean - early_mean, sat = fraction far-end texels > 0.99 or
< 0.01, alive = late std > 0.02.

Usage: tests/run.sh tests/records/spike_wc_habituation.py
CSV to stdout: be,bi,ne,mean_early,std_early,mean_late,std_late,drift,sat_late,alive
"""
import os
import sys
import time

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "lib"))
sys.path.insert(0, os.path.join(HERE, "..", "modules", "wc"))
from gpu_sim import F32  # noqa: E402
import wc_mirror as km  # noqa: E402

N = 128
FRAMES = 1200
WINDOWS = ((200, 300, "early"), (1100, 1200, "late"))


def run_cell(be, bi, ne, seed=11):
    P = km.Params(rate=1.0, texture=1.4, ne=ne, fast_fft=True,
                  be=be, bi=bi)
    rng = np.random.default_rng(seed)
    state = km.seed_state(N, N, seed)
    seg = {"early": [], "late": []}
    for f in range(1, FRAMES + 1):
        state = km.wc_frame(state, rng, P)
        for lo, hi, name in WINDOWS:
            if lo <= f < hi:
                if f % 10 == 0:
                    seg[name].append((float(state[..., 0].mean()),
                                      float(state[..., 0].std())))
    e_mean, e_std = np.mean(seg["early"], axis=0)
    l_mean, l_std = np.mean(seg["late"], axis=0)
    e = state[..., 0]
    sat = float(np.mean((e > 0.99) | (e < 0.01)))
    alive = l_std > 0.02
    return e_mean, e_std, l_mean, l_std, sat, alive


def main():
    print("# be,bi,ne,mean_early,std_early,mean_late,std_late,drift,sat_late,alive")
    t0 = time.time()
    for be in (0.0, 0.2, 0.5, 1.0):
        for ne in (0.6, 0.8, 1.0, 1.2):
            out = run_cell(F32(be), F32(be), F32(ne))
            print(f"{be},{be},{ne},{out[0]:.4f},{out[1]:.4f},{out[2]:.4f},"
                  f"{out[3]:.4f},{out[2] - out[0]:+.4f},{out[4]:.3f},{int(out[5])}",
                  flush=True)
    print(f"# {time.time() - t0:.0f}s total", flush=True)


if __name__ == "__main__":
    main()
