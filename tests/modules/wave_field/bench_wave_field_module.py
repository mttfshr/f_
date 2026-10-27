"""
bench_wave_field_module.py -- f_wave_field as a shipped patcher in the live module bench (tasks.md T021/T022):
the real chain, the real reset logic and the real load-time reset + strike, with nothing connected.

Asserted:
  - after load both outlets are finite, luma is inside [0, 1] (tanh encode) and opaque
  - the load strike fired and the field runs (the default exciter also keeps ringing): luma shows real
    contrast and the vecfield outlet leaves its neutral 0.5 grey
  - the pattern evolves: the same module read at two different times differs

Needs Max with tests/bench/bench_module.maxpat open (Vsynth performance patches closed).
Run:  tests/bench.sh tests/modules/wave_field/bench_wave_field_module.py
"""
GROUP = "regression"
ORDER = 63             # integers only; 58 was shared with bench_vf_lbm_module, renumbered 2026-10-26

import paths as _paths
import sys

import numpy as np

import modulebench as mb
from harness import check, note, run

N = 64


def frames(warmup):
    r, plan, info = mb.run_module("f_wave_field", n=N, warmup=warmup, settle=6)
    assert r["status"] != "stalled", r["errors"][-3:]
    arrs = (r.get("arrays") or {}).get("base", {})
    assert 1 in arrs and 2 in arrs, f"missing outlet (status {r['status']}, errors {r['errors'][-3:]})"
    return arrs[1].astype(np.float64), arrs[2].astype(np.float64)


def test_live_field_after_load():
    for w in (30, 120, 300):
        a, v = frames(w)
        lum = a[..., 0]
        check(f"frame {w}: luma finite", float(not np.isfinite(a).all()), 0.0)
        check(f"frame {w}: vecfield finite", float(not np.isfinite(v).all()), 0.0)
        check(f"frame {w}: luma inside [0, 1]", float(lum.min() < -1e-6 or lum.max() > 1 + 1e-6), 0.0)
        check(f"frame {w}: opaque", float(abs(a[..., 3] - 1).max()), 1e-6)
        note(f"frame {w}: luma mean / std; vec deviation from 0.5", 
             f"{lum.mean():.4f} / {lum.std():.4f}; {np.abs(v[..., :2] - 0.5).max():.4f}")
    check("load strike / exciter fired: real contrast (std > 0.01)", float(lum.std() < 0.01), 0.0)
    check("vecfield leaves neutral (deviation > 1e-3)", float(np.abs(v[..., :2] - 0.5).max() < 1e-3), 0.0)


def test_pattern_evolves():
    a = frames(30)[0][..., 0]
    b = frames(120)[0][..., 0]
    d = float(np.abs(a - b).mean())
    note("mean |difference| between frame 30 and frame 120", d)
    check("the field evolves (mean difference > 0.005)", float(d < 0.005), 0.0)


if __name__ == "__main__":
    sys.exit(run(globals()))
