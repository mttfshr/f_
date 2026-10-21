"""
spike_ks_ceiling_vs_L.py -- diagnostic, not a regression gate.

How does the largest stable per-frame dt of f_ks change with the domain size L (the future `scale` dial)?
Mirror at N = 256 (np.fft path, the same maths as the GPU chain), seeded from noise, 500 frames per run.
A run SURVIVES when every state is finite and max|u| stays under 50 (the containment clamp is +-100 and
the normal range is 15 to 20: anything past 50 is a blow-up on its way to the clamp).

Run: uv run --no-project --with numpy python3 tests/records/spike_ks_ceiling_vs_L.py
"""
import paths as _paths  # noqa: F401
import sys
import time

import numpy as np

import ks_mirror as km

N = 256
FRAMES = 500
LS = (12.5, 25.0, 50.0, 75.0, 100.0, 150.0, 200.0)
DTS = (0.03, 0.04, 0.05, 0.0625, 0.075, 0.09, 0.11)


def survives(L, dt):
    p = km.Params(rate=1.0, dt0=dt, ceiling=10.0, L=L, fast_fft=True)
    st = km.seed_state(N, N, 5)
    worst = 0.0
    for f in range(FRAMES):
        st, _ = km.ks_frame(st, p)
        u = st[..., 0]
        if not np.isfinite(u).all():
            return False, float("inf"), f
        worst = max(worst, float(np.abs(u).max()))
        if worst > 50.0:
            return False, worst, f
    return True, worst, FRAMES


if __name__ == "__main__":
    t0 = time.time()
    print(f"{'L':>6} " + " ".join(f"{d:>9g}" for d in DTS) + "   ceiling (largest surviving dt)")
    for L in LS:
        row, best = [], None
        for dt in DTS:
            ok, worst, f = survives(L, dt)
            row.append(f"{'ok' if ok else 'X@' + str(f):>5}{worst:>4.0f}" if np.isfinite(worst) else f"{'X@' + str(f):>9}")
            if ok:
                best = dt
        print(f"{L:>6g} " + " ".join(f"{r:>9}" for r in row) + f"   {best}", flush=True)
    print(f"done in {time.time() - t0:.0f}s")
