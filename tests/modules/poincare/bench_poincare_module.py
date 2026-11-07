"""
bench_poincare_module.py -- f_poincare T042: the shipped patcher in the live module bench. The codebox bench cannot see this
layer: the control names, render_dim (width / height from the render size) and the flag-free single inlet.

Each job is a `segments` timeline (bench_module.js): control messages one per frame, a wait in frames, a snapshot. The first
input is the ramp of bench_poincare.py (R = u, G = v, B = u v) at the render size, so the sampled colour is the settled position
and one comparison checks position and colour together.

Asserted (thresholds written before the first run, the codebox bench's, not to be loosened to make a failure pass):
  - defaults: the output is the render size and matches the mirror (mode A {4,5}, tile_scale 0.26)
  - Sliver ({5,4}, tile_scale 0.4) and the camera (cam_x 0.5, cam_y 0.3, rot 0.4) match the mirror
  - zero camera equals the static tiling: sending explicit zeros gives EXACTLY the default frame
  - outside the unit disk is exactly black, in both modes

Fractions as bench_poincare.py: >= 99.9% of pixels within the per-channel tolerance at r < 0.3 and 0.9, >= 99% at r < 0.97.
Bypass is the contract bench's (tests/contracts/bench_modules.py, f_poincare in INPUT_SIZE).

The render size is the bench's vs_render, 640 x 640 (bench_modules.RENDER_DIM_SIZE); each snapshot's shape is checked. Frame counts
around a snapshot are loose, so the wait is long.

Needs Max with tests/bench/bench_module.maxpat open (Vsynth performance patches closed).
Run:  tests/bench.sh tests/modules/poincare/bench_poincare_module.py       (ask Matt first: CLAUDE.md)
"""
GROUP = "regression"
ORDER = 163            # integers only

import paths as _paths
import json
import sys

import numpy as np

import benchclient as bc
import jxf
import modulebench as mb
from harness import check, note, run

import poincare_mirror as m

N = 640
SETTLE = 60            # frames after a control message
FRACTIONS = ((0.30, 0.999), (0.90, 0.999), (0.97, 0.99))


def ramp(n):
    nx, ny = m.norm_grid(n, n, np.float32)
    return np.stack([nx, ny, nx * ny, np.ones_like(nx)], -1).astype(np.float32)


RAMP = ramp(N)


def job(segments, warmup=30):
    bc.reopen(ports=bc.MODULE_PORTS, patch="bench_module.maxpat")
    j, job_dir = bc.new_job("module", warmup=warmup, settle=6, timeout_ms=60000)
    j["wrapper"] = f"mjob_{j['id']}.maxpat"
    j["inputs"] = ["in1.jxf"]
    jxf.write_rgba(job_dir / "in1.jxf", RAMP)
    j["segments"] = segments
    wrapper = bc.BENCH_DIR / j["wrapper"]
    wrapper.write_text(json.dumps(mb.make_wrapper("f_poincare.maxpat", 1, 1), indent=2))
    r = bc.run_job(j, job_dir, ports=bc.MODULE_PORTS)
    for old in bc.BENCH_DIR.glob("mjob_*.maxpat"):
        if old != wrapper:
            old.unlink()
    assert r["status"] != "stalled", r["errors"][-3:]
    frames = {tag: jxf.read_rgba(job_dir / f"{tag}_out1.jxf") for tag, ks in (r.get("outputs") or {}).items() if 1 in ks}
    return frames


def snap(frames, tag):
    assert tag in frames, f"no {tag} snapshot: {sorted(frames)}"
    check(f"{tag}: output at the render size", float(frames[tag].shape[:2] != (N, N)), 0.0)
    return frames[tag]


def matches(out, label, mode=0, p=4, q=5, tile_scale=0.26, **cam):
    nx, ny = m.norm_grid(N, N)
    want, _, rr = m.render(nx, ny, mode, p, q, tile_scale, 32, 0.99, 1.0, **cam)
    tol = np.array([1.0 / N, 1.0 / N, 1.0 / N])
    err = (np.abs(out[..., :3].astype(np.float64) - want) / tol).max(-1)
    for rmax, need in FRACTIONS:
        frac = float((err[rr < rmax] <= 1.0).mean())
        note(f"[{label}] r<{rmax}: fraction within tolerance", frac)
        assert frac >= need, f"[{label}] r<{rmax}: {frac:.5f}, need {need}"
    check(f"[{label}] r >= 1 exactly black", float(np.abs(out[rr >= 1.0][:, :3]).max()), 0.0)
    return rr


def test_defaults_and_modes():
    f = job([{"wait": SETTLE, "snap": "default"},
             {"params": [["fold_mode", 1], ["p_sides", 5], ["q_vertex", 4], ["tile_scale", 0.4]], "wait": SETTLE, "snap": "sliver"}])
    matches(snap(f, "default"), "default: whole {4,5}")
    matches(snap(f, "sliver"), "sliver {5,4}", mode=1, p=5, q=4, tile_scale=0.4)


def test_camera_matches_mirror_and_zero_is_static():
    f = job([{"wait": SETTLE, "snap": "static"},
             {"params": [["cam_x", 0.0], ["cam_y", 0.0], ["rot", 0.0]], "wait": SETTLE, "snap": "zeros"},
             {"params": [["cam_x", 0.5], ["cam_y", 0.3], ["rot", 0.4]], "wait": SETTLE, "snap": "moved"}])
    check("explicit zero camera equals the default frame", float(np.abs(snap(f, "zeros") - snap(f, "static")).max()), 0.0)
    matches(snap(f, "moved"), "camera (0.5, 0.3) rot 0.4", cam_x=0.5, cam_y=0.3, rot=0.4)


if __name__ == "__main__":
    sys.exit(run(globals()))
