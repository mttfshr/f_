"""
test_benchclient.py -- offline checks of the OSC encoding used to talk to the
bench, against hand-written OSC 1.0 byte strings (independent ground truth),
plus an in-process UDP loopback of the reply-matching logic.

Run:  tests/run.sh tests/toolchain/test_benchclient.py
"""
import socket
import sys
import tempfile
import threading
from pathlib import Path

import benchclient
from benchclient import Channel, osc_decode, osc_encode
from harness import check, run, skip


def test_encode_matches_spec_bytes():
    # OSC 1.0: address and type-tag strings null-terminated, padded to 4
    check("/ping", 0 if osc_encode("/ping") == b"/ping\x00\x00\x00,\x00\x00\x00" else 1, 0)
    check("4-char address gets 4 nulls",
          0 if osc_encode("/abc") == b"/abc\x00\x00\x00\x00,\x00\x00\x00" else 1, 0)
    expect = b"/run\x00\x00\x00\x00,s\x00\x00/a b\x00\x00\x00\x00"
    check("/run '/a b'", 0 if osc_encode("/run", "/a b") == expect else 1, 0)
    check("int arg", 0 if osc_encode("/x", 7) == b"/x\x00\x00,i\x00\x00\x00\x00\x00\x07" else 1, 0)


def test_roundtrip():
    cases = [("/ping", []), ("/pong", []),
             ("/run", ["/Users/matt/Github/f_/tests/jobs/20260922_120000_abcdef"]),
             ("/done", ["/path with spaces/x"]), ("/mix", ["s", 3, 0.5])]
    bad = 0
    for address, args in cases:
        a, got = osc_decode(osc_encode(address, *args))
        bad += (a != address) or (got != args)
    check("round trips", bad, 0)
    check("address-only packet (no type tags) decodes",
          0 if osc_decode(b"/pong\x00\x00\x00") == ("/pong", []) else 1, 0)


def test_loopback_reply_matching():
    """A fake bench on the bench port: replies to /run with an unrelated
    /done first, then the matching one. wait_for must skip the unrelated."""
    fake = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        fake.bind((benchclient.HOST, benchclient.TO_BENCH_PORT))
    except OSError:
        fake.close()
        skip("bench port in use -- the real bench is probably open")
    fake.settimeout(2.0)

    def serve():
        data, _ = fake.recvfrom(65536)
        _, args = osc_decode(data)
        reply_to = (benchclient.HOST, benchclient.FROM_BENCH_PORT)
        fake.sendto(osc_encode("/done", "/some/other/job"), reply_to)
        fake.sendto(osc_encode("/done", args[0]), reply_to)

    t = threading.Thread(target=serve)
    try:
        with Channel() as ch:
            t.start()
            ch.send("/run", "/tmp/job_x")
            match = benchclient._is_reply({"/done", "/busy"}, "/tmp/job_x")
            address, args = ch.wait_for(match, 2.0)
        check("matched reply is ours", 0 if args == ["/tmp/job_x"] else 1, 0)
    finally:
        t.join(timeout=2.0)
        fake.close()


def test_prune_jobs_keeps_newest_and_leaves_other_files():
    """Only job-id-named dirs are pruned, oldest first; logs and unrelated
    dirs survive. new_job() prunes but never removes the dir it just made."""
    with tempfile.TemporaryDirectory() as tmp:
        jobs = Path(tmp)
        ids = [f"2026092{d}_120000_{d:06x}" for d in range(1, 8)]     # 7 jobs, oldest first
        for i in ids:
            (jobs / i).mkdir()
            (jobs / i / "big.jxf").write_bytes(b"x")
        (jobs / "bench_last.log").write_text("log")
        (jobs / "notes").mkdir()
        removed = benchclient.prune_jobs(jobs, 3)
        left = sorted(p.name for p in jobs.iterdir())
        check("removed the 4 oldest", removed, 4)
        check("newest 3 kept + log + unrelated dir",
              0 if left == sorted(ids[-3:] + ["bench_last.log", "notes"]) else 1, 0)
        check("keep >= count removes nothing", benchclient.prune_jobs(jobs, 99), 0)

        old = (benchclient.JOBS_DIR, benchclient.JOBS_KEEP)
        benchclient.JOBS_DIR, benchclient.JOBS_KEEP = jobs, 2
        try:
            _, job_dir = benchclient.new_job("test")
            check("new job dir survives its own prune", 0 if job_dir.is_dir() else 1, 0)
            n_jobs = sum(1 for p in jobs.iterdir() if p.is_dir() and p.name != "notes")
            check("jobs dir held to JOBS_KEEP", n_jobs, 2)
        finally:
            benchclient.JOBS_DIR, benchclient.JOBS_KEEP = old


def test_prune_after_run_is_tighter_than_the_in_run_cap():
    """The in-run cap must stay high (tests prepare many jobs before running the first), the end-of-run
    prune is what keeps tests/jobs/ small: it keeps JOBS_KEEP_AFTER_RUN dirs, touches only job-named dirs,
    and does nothing on a directory that is already small."""
    check("the end-of-run keep is below the in-run cap",
          0 if 1 <= benchclient.JOBS_KEEP_AFTER_RUN < benchclient.JOBS_KEEP else 1, 0)
    keep = benchclient.JOBS_KEEP_AFTER_RUN
    with tempfile.TemporaryDirectory() as tmp:
        jobs = Path(tmp)
        ids = [f"20260901_1200{n:02d}_{n:06x}" for n in range(keep + 5)]    # keep + 5 jobs, oldest first
        for i in ids:
            (jobs / i).mkdir()
        (jobs / "bench_green.json").write_text("{}")
        (jobs / "bg").mkdir()
        old = benchclient.JOBS_DIR
        benchclient.JOBS_DIR = jobs
        try:
            check("removes everything but the newest keep", benchclient.prune_jobs_after_run(), 5)
            left = sorted(p.name for p in jobs.iterdir())
            check("newest dirs + the record + the unrelated dir survive",
                  0 if left == sorted(ids[-keep:] + ["bench_green.json", "bg"]) else 1, 0)
            check("a second call removes nothing", benchclient.prune_jobs_after_run(), 0)
        finally:
            benchclient.JOBS_DIR = old


_DECLARATIONS = """
// Param ghost(9);
Param a(0.5);
Param b(1, min=0, max=2);  /* Param ghost2(3); */
Param c(1e-3);
Param d;
Param e(PI);
Param bypass_gate(0.0);
out1 = vec(a, b, c, 1);
"""


def _param_default_problems(defaults_fn, merge_fn):
    """Everything wrong with a pair of implementations, as a list of strings ([] = correct)."""
    bad = []
    want = {"a": 0.5, "b": 1.0, "c": 1e-3, "bypass_gate": 0.0}
    got = defaults_fn(_DECLARATIONS)
    if got != want:
        bad.append(f"declarations parsed as {got}, want {want}")
    merged = merge_fn(_DECLARATIONS, {"a": 0.9, "extra": 2.0})
    if merged.get("a") != 0.9:
        bad.append("a supplied value did not win over the default")
    if merged.get("b") != 1.0:
        bad.append("an unsupplied param did not get its default")
    if merged.get("extra") != 2.0:
        bad.append("a param the caller supplied was dropped")
    if "ghost" in merged or "ghost2" in merged or "d" in merged or "e" in merged:
        bad.append("a commented-out or default-less Param was sent")
    if merge_fn(_DECLARATIONS, None).get("a") != 0.5:
        bad.append("params=None did not give the defaults")
    return bad


def test_param_defaults_come_from_the_codebox_and_the_caller_wins():
    """A4: bench jobs send the codebox's own Param defaults for anything the test did not supply."""
    problems = _param_default_problems(benchclient.param_defaults, benchclient.with_param_defaults)
    for p in problems:
        print("    problem:", p)
    check("problems with the real implementation", len(problems), 0)


def test_the_param_default_checks_catch_broken_implementations():
    """Mutation check on the check itself: each broken variant must be reported."""
    pd, wpd = benchclient.param_defaults, benchclient.with_param_defaults
    mutants = {
        "defaults override the caller": (pd, lambda code, p: {**(p or {}), **pd(code)}),
        "no defaults are added": (pd, lambda code, p: dict(p or {})),
        "caller params are dropped": (pd, lambda code, p: pd(code)),
        "comments are not stripped": (lambda code: benchclient._PARAM_RE and {
            n: float(a.split(",")[0]) for n, a in benchclient._PARAM_RE.findall(code)
            if a.split(",")[0].strip().replace(".", "").replace("e-", "").isdigit()}, wpd),
        "only the first Param is read": (lambda code: dict(list(pd(code).items())[:1]), lambda code, p: wpd(code, p)),
    }
    missed = [name for name, (d, m) in mutants.items() if not _param_default_problems(d, m)]
    for name in missed:
        print("    not caught:", name)
    check("mutants the checks let through", len(missed), 0)


if __name__ == "__main__":
    sys.exit(run(globals()))
