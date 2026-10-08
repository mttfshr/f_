"""
caustic_runner.py -- module-bench runner shared by tests/record_caustic_baseline.py and
tests/bench_caustic_sheets.py (.specify/f_caustic_scatter/tasks.md). The spike's runner pattern
(tests/spike_scatter.py `run`) without its dependency on scratch/.

Needs Max with tests/bench/bench_module.maxpat open and every Vsynth performance patch CLOSED (the bench and a
live patch share the `vsynth` render context). Each job: a module bpatcher in a wrapper, textures fed to its
inlets, params sent as control messages (all of them, every job: the bench keeps a Param's last value between jobs).
Tags in the result: 'base' = defaults, before any param is sent; 'bypassed' = after all params (the module
bench's timeline names it that way). Output arrays are keyed by outlet number starting at 1.
"""
import json
from pathlib import Path

import numpy as np

import benchclient as bc
import jxf
from modulebench import make_wrapper

HERE = Path(__file__).resolve().parent
F32 = np.float32
WARMUP, SETTLE = 30, 24


def ensure_bench():
    if not bc.ping(2.0, ports=bc.MODULE_PORTS):
        print("module bench not open: reopening (Max comes to the front)")
        bc.reopen(wait=40.0, ports=bc.MODULE_PORTS, patch="bench_module.maxpat")


def run(inputs, params, module, n_out=2, n_in=None, timeout_ms=90000, settle=SETTLE, warmup=WARMUP):
    """One module-bench job. `inputs`: float32 RGBA arrays for the module's inlets 0, 1, ... in order (an inlet
    without an array stays UNCONNECTED when n_in is smaller than the module's inlet count). Returns
    (result, {tag: {outlet: array}})."""
    n_in = len(inputs) if n_in is None else n_in
    job, job_dir = bc.new_job("module", warmup=warmup, settle=settle, timeout_ms=timeout_ms)
    job["wrapper"] = f"mjob_{job['id']}.maxpat"
    job["inputs"] = []
    for i, arr in enumerate(inputs):
        fn = f"in{i + 1}.jxf"
        jxf.write_rgba(job_dir / fn, np.asarray(arr, F32))
        job["inputs"].append(fn)
    job["params"] = params
    job["readback"], job["controls"] = {}, []
    wrapper = bc.BENCH_DIR / job["wrapper"]
    wrapper.write_text(json.dumps(make_wrapper(module, n_in, n_out), indent=2))
    result = bc.run_job(job, job_dir, ports=bc.MODULE_PORTS)
    for old in bc.BENCH_DIR.glob("mjob_*.maxpat"):
        if old != wrapper:
            old.unlink()
    out = {}
    for tag, ks in (result.get("outputs") or {}).items():
        out[tag] = {k: jxf.read_rgba(job_dir / f"{tag}_out{k}.jxf") for k in ks}
    return result, out


def report(result, label):
    errs = result.get("errors") or []
    print(f"  [{label}] status={result.get('status')} frames={result.get('frames_rendered')} "
          f"elapsed={result.get('elapsed_ms')} ms errors={len(errs)}")
    for e in errs[:6]:
        print(f"      max error: {e[:200]}")
    return errs
