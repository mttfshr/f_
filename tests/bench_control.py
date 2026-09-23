"""
bench_control.py -- Phase 1 checks of the terminal <-> bench control loop
(.specify/test_bench/tasks.md T013). Needs Max with tests/bench/bench.maxpat
open; run via tests/bench.sh (which first fails fast if the bench is
unreachable -- that covers the "bench closed" case).

Run:  tests/bench.sh tests/bench_control.py
"""
import sys

import benchclient
from benchclient import Channel, new_job, run_job
from harness import check, note, run


def test_ping():
    check("ping answered", 0 if benchclient.ping() else 1, 0)


def test_stub_roundtrip():
    job, d = new_job("stub")
    result = run_job(job, d)
    check("status ok", 0 if result.get("status") == "ok" else 1, 0)
    check("result id matches job", 0 if result.get("id") == job["id"] else 1, 0)
    check("no errors", len(result.get("errors", [])), 0)


def test_frames_arrive_during_job():
    """A 1.5 s job should see ~45 draw bangs at jit.world's default 30 fps:
    proves the world is rendering and its bangs reach bench.js."""
    job, d = new_job("stub_delay", delay_ms=1500)
    result = run_job(job, d)
    frames = result.get("frames_rendered", 0)
    note("frames seen in 1.5 s", frames)
    check("frames arrived (>= 10)", 0 if frames >= 10 else 1, 0)


def test_busy_rejected_not_interleaved():
    job_a, dir_a = new_job("stub_delay", delay_ms=1500)
    job_b, dir_b = new_job("stub")
    benchclient._write_job(job_a, dir_a)
    benchclient._write_job(job_b, dir_b)
    with Channel() as ch:
        ch.send("/run", str(dir_a))
        ch.send("/run", str(dir_b))
        addr_b, _ = ch.wait_for(benchclient._is_reply({"/done", "/busy"}, dir_b), 3.0)
        addr_a, _ = ch.wait_for(benchclient._is_reply({"/done", "/busy"}, dir_a), 4.0)
    check("second job refused with /busy", 0 if addr_b == "/busy" else 1, 0)
    check("first job still completes", 0 if addr_a == "/done" else 1, 0)
    check("refused job wrote no result", 0 if not (dir_b / "result.json").exists() else 1, 0)


def test_unreadable_job_reports_error():
    job, d = new_job("stub")
    with Channel() as ch:                       # no job.json written on purpose
        ch.send("/run", str(d))
        ch.wait_for(benchclient._is_reply({"/done"}, d), 3.0)
    import json
    result = json.load(open(d / "result.json"))
    check("status error", 0 if result.get("status") == "error" else 1, 0)
    check("error mentions job.json",
          0 if any("job.json" in e for e in result.get("errors", [])) else 1, 0)


if __name__ == "__main__":
    sys.exit(run(globals()))
