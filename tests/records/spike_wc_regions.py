"""
spike_wc_regions.py -- f_wc Phase 0, task T004: parameter region map.

Sweeps the working coupling-aggregate space and classifies the asymptotic
pattern morphology with wc_classify. The map decides gate G1 (discrete form
selector vs. continuous knobs) and fixes the four `form` parameter sets (T005).

Sweep axes (the spec's curated aggregates):
  P        excitatory drive (the pattern-forming threshold control)
  sscale   overall kernel-width multiplier (pattern wavelength)
  seed_hi  seed noise amplitude upper bound (0..seed_hi)

Fixed: W_EE=16, W_EI=12, W_IE=15, W_II=3, A_E=1.3, TH_E=4.0, A_I=2.0,
TH_I=3.7, tau_E=1, tau_I=2, kernel width ratio 1:2:2:1, N=256, L=80, dt=0.05.

Usage:
  tests/run.sh tests/records/spike_wc_regions.py            # full sweep
  python3 spike_wc_regions.py --p-slice 0:3                  # subset (fan-out)
Writes rows to stdout as CSV: P,sscale,seed_hi,label,k_star,std,frac_high
"""
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "lib"))
sys.path.insert(0, HERE)
import spike_wc_solver as S  # noqa: E402
import wc_classify as C  # noqa: E402

N = 256
L = 80.0
DT = 0.05
FRAMES = 1200

# sweep grids
P_VALUES = [0.6, 0.8, 1.0, 1.2, 1.4, 1.6, 1.8, 2.0]
SSCALE_VALUES = [0.3, 0.4, 0.5, 0.6, 0.7]
SEED_VALUES = [0.3, 0.6]


def run_cell(P, sscale, seed_hi, n=N, dom=L, dt=DT, frames=FRAMES, seed=1):
    rng = np.random.default_rng(seed)
    E = rng.uniform(0, seed_hi, (n, n))
    I = rng.uniform(0, seed_hi, (n, n))
    K = S.make_kernels(n=n, dom=dom,
                       s_ee=0.5 * sscale, s_ei=1.0 * sscale,
                       s_ie=1.0 * sscale, s_ii=0.5 * sscale)
    for _ in range(frames):
        E, I = S.wc_step(E, I, dt, P, K)
    return E


def sweep_row(P, sscale, seed_hi):
    E = run_cell(P, sscale, seed_hi)
    label, k_star, d = C.classify(E)
    return dict(P=P, sscale=sscale, seed_hi=seed_hi, label=label,
                k_star=k_star, std=d["std"], frac_high=d.get("frac_high", 0.0),
                f2=d.get("f2", 0.0), f6=d.get("f6", 0.0),
                n_lambda=(L * (k_star / N) if k_star else 0.0))


def row_csv(r):
    return (f"{r['P']},{r['sscale']},{r['seed_hi']},{r['label']},{r['k_star']},"
            f"{r['std']:.5f},{r['frac_high']:.4f},{r['f2']:.3f},{r['f6']:.3f},"
            f"{r['n_lambda']:.2f}")


def main():
    p_slice = None
    for a in sys.argv[1:]:
        if a.startswith("--p-slice="):
            lo, hi = a.split("=")[1].split(":")
            p_slice = (int(lo), int(hi))
    pvals = P_VALUES if p_slice is None else P_VALUES[p_slice[0]:p_slice[1]]
    print("P,sscale,seed_hi,label,k_star,std,frac_high,f2,f6,n_lambda")
    for P in pvals:
        for sscale in SSCALE_VALUES:
            for seed_hi in SEED_VALUES:
                print(row_csv(sweep_row(P, sscale, seed_hi)), flush=True)


if __name__ == "__main__":
    main()
