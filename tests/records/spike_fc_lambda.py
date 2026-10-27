"""spike_fc_lambda.py -- f_wc Phase 0, T003 + T005.

T003: lambda(sigma) calibration at the shipped constants -- structure-factor
peak wavelength vs. the grain dial (sigma_I as a fraction of min dim). Fixes
the grain dial mapping (FR-002) and the landmark ladder.

T005: resize invariance -- the same grain at several N, wavelength measured
in FRAME-FRACTION units; bounds NF-005's claim and shows the floor.

**2026-10-24 VERDICT (recorded in .specify/stable/f_wc/tasks.md T003/T005):
shipped defaults are Psychedelic couplings + Ne = 0.75 + habituation; the fine
regime lives INSIDE the sigma clamp band [0.75, 1.4] px and its lambda is
dynamics-set, not kernel-set, so a clean lambda(sigma) table does not exist
where it matters. The cell() runs below remain the per-corner verification
tool; ENERGY/HABIT now reflect the shipped corner.**

Run from the repo root: uv run --no-project --with numpy python3 tests/records/spike_fc_lambda.py
"""
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, "tests", "lib"))
sys.path.insert(0, os.path.join(REPO, "tests", "modules", "wc"))

import numpy as np  # noqa: E402
from wc_steadyweb_mirror import (Params, lambda_px, run, seed_state,  # noqa: E402
                       sigmas_px, structure_factor_metrics)

ENERGY = 0.75       # shipped (T002 measured)
HABIT = 0.9         # shipped (T002/T003 measured: load-bearing)
N = 512
FRAMES = 700


def cell(n, grain, seed=1, frames=FRAMES):
    P = Params(grain=grain, energy=ENERGY, habituation=HABIT)
    st, _ = run(seed_state(n, n, seed), P, frames,
                seed=(7 if ENERGY > 0 else None), fast_blur=True)
    e = np.asarray(st[..., 0], dtype=np.float64)
    lam = lambda_px(e)
    m = structure_factor_metrics(e)
    si_px, _ = sigmas_px(n, n, P)
    si_eff = grain * n
    floor = "FLOOR" if abs(si_px - si_eff) > 1e-6 else ""
    return lam, m, float(si_px), floor, float(e.mean()), float(e.std())


def main():
    print("== T003: lambda(grain) at N=512 ==", flush=True)
    print(f"{'grain':>9s} {'sigI_px':>8s} {'lam_px':>7s} {'lam/N':>6s} "
          f"{'prom':>6s} {'aniso':>6s} {'mean':>6s} {'std':>6s}")
    grains = [5e-4, 1e-3, 2e-3, 4e-3, 8e-3, 1.5e-2, 3e-2]
    rows = []
    for g in grains:
        lam, m, si, fl, em, es = cell(N, g)
        rows.append((g, si, lam))
        print(f"{g:9.4f} {si:8.2f} {lam:7.1f} {lam / N:6.3f} "
              f"{m['prominence']:6.1f} {m['anisotropy']:6.2f} {em:6.3f} {es:6.3f} {fl}",
              flush=True)
    # fit lambda_px = c * sigma_I_px on the non-floor rows
    xs = np.array([r[1] for r in rows])
    ys = np.array([r[2] for r in rows])
    c = float((xs * ys).sum() / (xs * xs).sum())
    resid = np.abs(ys - c * xs) / np.maximum(ys, 1e-9)
    print(f"\nfit: lambda_px = {c:.2f} * sigma_I_px  (max rel resid "
          f"{float(resid.max()):.2f})")

    print("\n== T005: same grain, three sizes ==", flush=True)
    for n in (128, 256, 512):
        lam, m, si, fl, em, es = cell(n, 0.004)
        print(f"N={n:4d} grain=0.004 | sigI {si:5.2f}px | lam {lam:6.1f}px "
              f"= {lam / n:5.3f} frame-heights | prom {m['prominence']:5.1f} "
              f"mean {em:.3f} std {es:.3f} {fl}", flush=True)
    # floor-bound fine grain at small N
    lam, m, si, fl, em, es = cell(128, 0.001)
    print(f"N= 128 grain=0.001 | sigI {si:5.2f}px | lam {lam:6.1f}px "
          f"= {lam / 128:5.3f} frame-heights | prom {m['prominence']:5.1f} "
          f"mean {em:.3f} std {es:.3f} {fl}", flush=True)


if __name__ == "__main__":
    main()
