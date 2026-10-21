"""
bench_vf_lbm_module.py -- f_vf_lbm as a shipped patcher in the live module bench (tasks.md T021): the real chain
(hold loop break, mrg, collide, stream, mac, enc), the real mask inlet and the real load-time seed, not
codebox-by-codebox.

Asserted:
  - after load the output is a finite f_vecfield: R, G inside [0, 1], B = 0.5, A = 1
  - empty (black) mask: uniform channel flow at the inflow, so R is 0.5 + gain * inflow = 0.74 everywhere
    (the seeded state IS the uniform-flow fixed point, so this holds from the first frames)
  - a white disc as the mask: velocity inside the disc is near zero (R near 0.5), the free stream near the
    inflow edge is still 0.74, and the field has real cross-stream motion (G moves away from 0.5)
  - the solver runs: the disc case evolves between two times

The wake SHEDDING itself needs thousands of frames (spec success criterion 7, tier 3, Matt's judgment) and is not
asserted here. Tolerances are guesses written before the first live run; tighten them after it.

Needs Max with tests/bench/bench_module.maxpat open (Vsynth performance patches closed).
Run:  tests/bench.sh tests/modules/vf_lbm/bench_vf_lbm_module.py
"""
GROUP = "regression"   # tests/bench.sh runs "regression"; see tests/lib/benchdeps.py list --group
ORDER = 58

import paths as _paths
import sys

import numpy as np

import modulebench as mb
from harness import check, note, run

N = 128
FREE_STREAM = 0.5 + 3.0 * 0.08        # default gain 3, default inflow 0.08


def mask_image(disc):
    img = np.zeros((N, N, 4), np.float32)
    img[..., 3] = 1.0
    if disc:
        yy, xx = np.mgrid[0:N, 0:N]
        inside = (xx + 0.5 - 0.25 * N) ** 2 + (yy + 0.5 - 0.5 * N) ** 2 < (0.12 * N) ** 2
        img[..., :3] = inside[..., None].astype(np.float32)
    return img


def frame(warmup, disc):
    r, plan, info = mb.run_module("f_vf_lbm", n=N, warmup=warmup, settle=6, first_input=mask_image(disc))
    assert r["status"] != "stalled", r["errors"][-3:]
    arrs = (r.get("arrays") or {}).get("base", {})
    assert 1 in arrs, f"no frame on outlet 1 (status {r['status']}, errors {r['errors'][-3:]})"
    return arrs[1].astype(np.float64)


def test_empty_mask_is_uniform_channel_flow():
    for w in (30, 240):
        a = frame(w, False)
        check(f"frame {w}: finite", float(not np.isfinite(a).all()), 0.0)
        check(f"frame {w}: R, G inside [0, 1]", float(a[..., :2].min() < -1e-6 or a[..., :2].max() > 1 + 1e-6), 0.0)
        check(f"frame {w}: B = 0.5 and A = 1", max(float(np.abs(a[..., 2] - 0.5).max()), float(np.abs(a[..., 3] - 1).max())), 1e-6)
        note(f"frame {w}: R mean / min / max", f"{a[..., 0].mean():.4f} / {a[..., 0].min():.4f} / {a[..., 0].max():.4f}")
        check(f"frame {w}: R is the free stream {FREE_STREAM:.2f} everywhere (within 0.02)",
              float(np.abs(a[..., 0] - FREE_STREAM).max()), 0.02)
        check(f"frame {w}: G is neutral (within 0.02; the seed ripple is about 0.005)",
              float(np.abs(a[..., 1] - 0.5).max()), 0.02)


def test_disc_obstacle_stops_the_flow_and_deflects_it():
    a = frame(240, True)
    check("disc, frame 240: finite", float(not np.isfinite(a).all()), 0.0)
    check("disc, frame 240: inside [0, 1]", float(a[..., :2].min() < -1e-6 or a[..., :2].max() > 1 + 1e-6), 0.0)
    cy, cx = int(0.5 * a.shape[0]), int(0.25 * a.shape[1])
    inside = a[cy - 2:cy + 3, cx - 2:cx + 3, 0]
    note("R inside the disc (mean)", float(inside.mean()))
    check("velocity inside the obstacle is near zero (R within 0.08 of 0.5)", float(np.abs(inside - 0.5).max()), 0.08)
    left = a[:, : max(a.shape[1] // 12, 2), 0]
    note("R near the inflow edge (mean)", float(left.mean()))
    check("the free stream at the inflow edge is intact (R within 0.04 of 0.74)", float(abs(left.mean() - FREE_STREAM)), 0.04)
    dev = float(np.abs(a[..., 1] - 0.5).mean())
    note("mean |G - 0.5| with the disc", dev)
    check("the obstacle deflects the flow: cross-stream motion well above the seed ripple (mean |G - 0.5| > 0.01)",
          float(dev < 0.01), 0.0)


def test_solver_evolves():
    a = frame(60, True)[..., :2]
    b = frame(300, True)[..., :2]
    d = float(np.abs(a - b).mean())
    note("mean |difference| between frame 60 and frame 300 with the disc", d)
    check("the flow evolves (mean difference > 0.002)", float(d < 0.002), 0.0)


if __name__ == "__main__":
    sys.exit(run(globals()))
