"""
bench_ks_module.py -- f_ks as a shipped patcher in the live module bench (tasks.md T021): the real
chain, the real reset logic and the real load-time reseed, not codebox-by-codebox.

Asserted:
  - after load the output is finite and inside [0, 1]
  - the load reseed fired and the solver runs: the pattern grows to real contrast (u = 0 would stay a flat
    0.5 grey forever).  It does NOT start with contrast: white-noise seed energy sits almost entirely in
    wavenumbers the linear step kills at once, and the unstable band (|k| < 1, ~0.2% of the energy) then
    grows at most e^(0.25 dt) per frame, so the first ~second after a reset is near-flat (measured luma
    std 0.011 at frame 30).  A tier-3 question for Matt (seed shape / warm-up), tasks.md T012.
  - the pattern evolves: the same module read at two different times differs

Needs Max with tests/bench/bench_module.maxpat open (Vsynth performance patches closed).
Run:  tests/bench.sh tests/modules/ks/bench_ks_module.py
"""
GROUP = "regression"   # tests/bench.sh runs "regression"; see tests/lib/benchdeps.py list --group
ORDER = 56

import paths as _paths
import sys

import numpy as np

import modulebench as mb
from harness import check, note, run

N = 64


def frame(warmup):
    r, plan, info = mb.run_module("f_ks", n=N, warmup=warmup, settle=6)
    assert r["status"] != "stalled", r["errors"][-3:]
    arrs = (r.get("arrays") or {}).get("base", {})
    assert 1 in arrs, f"no frame on outlet 1 (status {r['status']}, errors {r['errors'][-3:]})"
    return arrs[1].astype(np.float64)


def test_live_pattern_after_load():
    for w in (30, 240, 600):
        a = frame(w)
        lum = a[..., 0]
        check(f"frame {w}: finite", float(not np.isfinite(a).all()), 0.0)
        check(f"frame {w}: inside [0, 1]", float(lum.min() < -1e-6 or lum.max() > 1 + 1e-6), 0.0)
        check(f"frame {w}: opaque", float(abs(a[..., 3] - 1).max()), 1e-6)
        note(f"frame {w}: luma mean / std", f"{lum.mean():.4f} / {lum.std():.4f}")
    check("the load reseed fired and the solver runs: real contrast by frame 600 (std > 0.05)",
          float(lum.std() < 0.05), 0.0)


def test_pattern_evolves():
    a = frame(30)[..., 0]
    b = frame(240)[..., 0]
    d = float(np.abs(a - b).mean())
    note("mean |difference| between frame 30 and frame 240", d)
    check("the pattern evolves (mean difference > 0.02)", float(d < 0.02), 0.0)


if __name__ == "__main__":
    sys.exit(run(globals()))
