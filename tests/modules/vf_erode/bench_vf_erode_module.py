"""
bench_vf_erode_module.py -- f_vf_erode (narrowed 2026-11-09, T052): the shipped patcher in the live module bench: the three stages and their
cords, the vecfield inlet and its connected flag, the render size arriving by `r dim`, and a dial with two stage targets.

Asserted (thresholds written before the first run; not to be loosened to make a failure pass):
  - load, nothing touched, field connected or not: the output is the source
  - field unconnected, amounts up: still the source (the flag, not the inlet's contents)
  - field connected: Extent, Bulge, both, and Travel each match the mirror texel by texel

Tolerance: TOL 5e-4, three stages of float32 against the mirror, as written.

Not here: bypass is the contract bench's (tests/contracts/bench_modules.py, BYPASS_EXPECT).

Needs Max with tests/bench/bench_module.maxpat open (Vsynth performance patches closed).
Run:  tests/bench.sh -q tests/modules/vf_erode/bench_vf_erode_module.py       (ask Matt first: CLAUDE.md)
"""
GROUP = "regression"
ORDER = 173            # integers only

import paths as _paths
import json
import sys

import numpy as np

import benchclient as bc
import jxf
import modulebench as mb
from harness import check, note, run
from vf_erode_mirror import F32, ink
from test_vf_erode import smooth, swirl_field

N = 640
SETTLE = 30            # frames after a control message
TOL = 5e-4
SRC = smooth(N, N)
SRC[..., 3] = np.random.default_rng(5).uniform(0.2, 1, (N, N)).astype(F32)
FIELD = swirl_field(N, N)


def job(segments, warmup=30, connect=True):
    """One segments job. Returns {tag: array} for the one outlet."""
    bc.reopen(ports=bc.MODULE_PORTS, patch="bench_module.maxpat")
    j, job_dir = bc.new_job("module", warmup=warmup, settle=6, timeout_ms=60000)
    j["wrapper"] = f"mjob_{j['id']}.maxpat"
    textures = (SRC, FIELD) if connect else (SRC,)
    j["inputs"] = [f"in{i + 1}.jxf" for i in range(len(textures))]
    for i, tex in enumerate(textures):
        jxf.write_rgba(job_dir / f"in{i + 1}.jxf", tex)
    j["segments"] = segments
    wrapper = bc.BENCH_DIR / j["wrapper"]
    wrapper.write_text(json.dumps(mb.make_wrapper("f_vf_erode.maxpat", len(textures), 1), indent=2))
    r = bc.run_job(j, job_dir, ports=bc.MODULE_PORTS)
    for old in bc.BENCH_DIR.glob("mjob_*.maxpat"):
        if old != wrapper:
            old.unlink()
    assert r["status"] != "stalled", r["errors"][-3:]
    return {tag: jxf.read_rgba(job_dir / f"{tag}_out1.jxf") for tag in (r.get("outputs") or {})}


def mx(a, b):
    return float(np.max(np.abs(np.asarray(a, np.float64) - np.asarray(b, np.float64))))


def frame(frames, tag):
    assert tag in frames, f"no {tag} snapshot: {sorted(frames)}"
    got = frames[tag]
    check(f"{tag}: at the render size", float(got.shape[:2] != (N, N)), 0.0)
    return got


def matches(got, label, **kw):
    want = ink(SRC, FIELD, **{"travel": 0.5, **kw})
    worst = mx(got[..., :3], want[..., :3])
    note(f"{label}: max rgb error", worst)
    check(f"{label}: vs mirror", worst, TOL)
    check(f"{label}: alpha is the source's", mx(got[..., 3], SRC[..., 3]), 1e-6)


def step(tag, *params):
    return {"params": [list(p) for p in params], "wait": SETTLE, "snap": tag}


def test_unconnected_field_is_identity():
    f = job([{"wait": SETTLE, "snap": "load"}, step("up", ("extent", 2.0), ("bulge", 2.0), ("travel", 1.0))], connect=False)
    check("load: the output is the source", mx(frame(f, "load"), SRC), 1e-6)
    check("no field, amounts up: still the source", mx(frame(f, "up"), SRC), 1e-6)


def test_dials():
    f = job([{"wait": SETTLE, "snap": "idle"},
             step("extent", ("extent", 1.0)),
             step("both", ("extent", 1.0), ("bulge", 1.0)),
             step("travel", ("travel", 1.0)),
             step("bulge_only", ("extent", 0.0), ("bulge", 1.5), ("travel", 0.5))])
    check("field connected, amounts 0: the source", mx(frame(f, "idle"), SRC), 1e-6)
    matches(frame(f, "extent"), "extent 1", extent=1.0)
    matches(frame(f, "both"), "extent 1, bulge 1", extent=1.0, bulge=1.0)
    matches(frame(f, "travel"), "travel 1, reaching both stages", extent=1.0, bulge=1.0, travel=1.0)
    matches(frame(f, "bulge_only"), "bulge 1.5", bulge=1.5)


if __name__ == "__main__":
    sys.exit(run(globals()))
