"""
test_bg.py -- tests/bg.sh, the background runner. It must return at once, report
state without blocking, refuse a second bench run, survive a dead run, and never
leave its run dirs where the job-pruning code could delete them.

Uses fake commands for tests/run.sh and tests/bench.sh (no Max, a few seconds).
Run:  tests/run.sh tests/test_bg.py
"""
import os
import re
import subprocess
import sys
import tempfile
import time
from pathlib import Path

import benchclient
from harness import check, run

REPO = Path(__file__).resolve().parent.parent
BG = REPO / "tests" / "bg.sh"


def _t(label, cond):
    check(label, 0 if cond else 1, 0)


class Sandbox:
    """A temp BG_DIR plus fake offline/bench commands that print their args, sleep
    $FAKE_SLEEP seconds, and exit $FAKE_RC."""

    def __init__(self, tmp):
        self.tmp = Path(tmp)
        fake = self.tmp / "fake.sh"
        fake.write_text('#!/bin/bash\n'
                        'echo "=== tests/fake_$1.py"\n'
                        'echo "args: ${*:2}"\n'
                        'sleep "${FAKE_SLEEP:-0}"\n'
                        'if [ "${FAKE_RC:-0}" != 0 ]; then echo "  FAIL boom"; fi\n'
                        'echo "3/3 passed"\n'
                        'exit "${FAKE_RC:-0}"\n')
        self.env = dict(os.environ, BG_DIR=str(self.tmp / "bg"), BG_NO_NOTIFY="1",
                        BG_OFFLINE_CMD=f"bash {fake} offline", BG_BENCH_CMD=f"bash {fake} bench")

    def bg(self, *args, sleep=0, rc=0):
        env = dict(self.env, FAKE_SLEEP=str(sleep), FAKE_RC=str(rc))
        return subprocess.run(["bash", str(BG), *args], cwd=REPO, env=env,
                              capture_output=True, text=True, timeout=60)

    def start(self, *args, **kw):
        r = self.bg("start", *args, **kw)
        m = re.search(r"started (\S+)", r.stdout)
        return r, (m.group(1) if m else None)

    def wait(self, ident, timeout=20):
        end = time.time() + timeout
        while time.time() < end:
            if self.bg("status", ident).returncode != 2:
                return
            time.sleep(0.2)
        raise AssertionError(f"{ident} did not finish in {timeout}s")

    def pid(self, ident):
        return int((self.tmp / "bg" / ident / "pid").read_text())


def _descendants(pid):
    out = []
    for c in subprocess.run(["pgrep", "-P", str(pid)], capture_output=True, text=True).stdout.split():
        out += [int(c)] + _descendants(int(c))
    return out


def _alive(pid):
    try:
        os.kill(pid, 0)
        return True
    except OSError:
        return False


def test_start_returns_at_once_and_status_does_not_block():
    with tempfile.TemporaryDirectory() as tmp:
        sb = Sandbox(tmp)
        t0 = time.time()
        r, ident = sb.start("offline", sleep=3)
        took = time.time() - t0
        _t("start prints the run id", r.returncode == 0 and ident is not None)
        _t("and returns long before the 3 s run ends", took < 1.5)
        t0 = time.time()
        s = sb.bg("status")
        _t("status of a running run exits 2 and says running", s.returncode == 2 and "running" in s.stdout)
        _t("status itself does not wait", time.time() - t0 < 1.5)
        sb.wait(ident)
        s = sb.bg("status")
        _t("when done: exit 0, 'passed', and the per-file summary", s.returncode == 0
           and "passed" in s.stdout and "tests/fake_offline.py: 3/3 passed" in s.stdout)


def test_a_failing_run_is_reported_as_failed_with_its_failures():
    with tempfile.TemporaryDirectory() as tmp:
        sb = Sandbox(tmp)
        r, ident = sb.start("offline", rc=1)
        sb.wait(ident)
        s = sb.bg("status")
        _t("exit 1 and 'failed'", s.returncode == 1 and "failed" in s.stdout)
        _t("the FAIL line is in the summary", "FAIL boom" in s.stdout)
        lg = sb.bg("log")
        _t("log shows the run's output and its path", "args:" in lg.stdout and "/log" in lg.stdout)


def test_bench_defaults_to_changed_and_args_replace_it():
    with tempfile.TemporaryDirectory() as tmp:
        sb = Sandbox(tmp)
        _, a = sb.start("bench")
        sb.wait(a)
        _t("bench with no args runs --changed", "args: --changed" in sb.bg("log", a).stdout)
        _, b = sb.start("bench", "--all")
        sb.wait(b)
        lg = sb.bg("log", b).stdout
        _t("explicit args replace it", "args: --all" in lg and "--changed" not in lg)
        _, c = sb.start("offline", "tests/test_x.py")
        sb.wait(c)
        _t("offline passes its args through", "args: tests/test_x.py" in sb.bg("log", c).stdout)


def test_only_one_bench_run_at_a_time_but_offline_may_overlap():
    with tempfile.TemporaryDirectory() as tmp:
        sb = Sandbox(tmp)
        _, first = sb.start("bench", sleep=3)
        r, second = sb.start("bench")
        _t("a second bench run is refused", r.returncode == 1 and second is None
           and "already in progress" in r.stdout and first in r.stdout)
        r, off = sb.start("offline")
        _t("an offline run is allowed alongside", r.returncode == 0 and off is not None)
        r, allr = sb.start("all")
        _t("'all' counts as a bench run and is refused too", r.returncode == 1)
        sb.wait(first); sb.wait(off)
        r, third = sb.start("bench")
        _t("once the first finished, a bench run starts again", r.returncode == 0 and third is not None)
        sb.wait(third)


def test_a_stale_lock_from_a_dead_run_does_not_block():
    with tempfile.TemporaryDirectory() as tmp:
        sb = Sandbox(tmp)
        (sb.tmp / "bg").mkdir()
        (sb.tmp / "bg" / "bench.lock").write_text("999999 bg-old-bench.XXXX\n")
        r, ident = sb.start("bench")
        _t("a lock whose process is gone is cleared", r.returncode == 0 and ident is not None)
        sb.wait(ident)


def test_stop_kills_the_run_and_frees_the_lock():
    with tempfile.TemporaryDirectory() as tmp:
        sb = Sandbox(tmp)
        _, ident = sb.start("bench", sleep=30)
        time.sleep(0.5)
        pid = sb.pid(ident)
        kids = _descendants(pid)
        _t("it is running, with child processes (the real test run)", _alive(pid) and len(kids) >= 2)
        r = sb.bg("stop")
        _t("stop says so", r.returncode == 0 and "stopped" in r.stdout)
        time.sleep(0.3)
        _t("the process is gone", not _alive(pid))
        _t("and so is everything it started", not any(_alive(k) for k in kids))
        s = sb.bg("status")
        _t("status: stopped, exit 1", s.returncode == 1 and "stopped" in s.stdout)
        _t("the lock is released", not (sb.tmp / "bg" / "bench.lock").exists())
        r, nxt = sb.start("bench")
        _t("a new bench run can start", r.returncode == 0)
        sb.wait(nxt)
        r = sb.bg("stop", ident)
        _t("stopping a run that is not running is an error", r.returncode == 1)


def test_a_run_whose_process_vanished_is_reported_as_died():
    with tempfile.TemporaryDirectory() as tmp:
        sb = Sandbox(tmp)
        d = sb.tmp / "bg" / "bg-20260101-000000-offline.AAAA"
        d.mkdir(parents=True)
        for name, val in (("status", "running"), ("pid", "999999"), ("started", "1"), ("cmd", "offline")):
            (d / name).write_text(val + "\n")
        (d / "log").write_text("=== tests/x.py\n")
        s = sb.bg("status", d.name)
        _t("status 'died', exit 1, with a pointer to the log", s.returncode == 1 and "died" in s.stdout
           and "log" in s.stdout)
        _t("list shows it as died too", "died" in sb.bg("list").stdout)


def test_all_runs_both_even_when_the_first_fails():
    with tempfile.TemporaryDirectory() as tmp:
        sb = Sandbox(tmp)
        env = dict(sb.env, FAKE_SLEEP="0")
        sb.env = dict(env)
        r = subprocess.run(["bash", str(BG), "start", "all"], cwd=REPO,
                           env=dict(sb.env, FAKE_RC="1"), capture_output=True, text=True)
        ident = re.search(r"started (\S+)", r.stdout).group(1)
        sb.wait(ident)
        lg = (sb.tmp / "bg" / ident / "log").read_text()
        _t("the offline part and the bench part both ran", "fake_offline" in lg and "fake_bench" in lg)
        _t("and the bench defaulted to --changed", "args: --changed" in lg)
        _t("overall failed", sb.bg("status", ident).returncode == 1)


def test_status_and_list_find_runs_by_kind_and_in_order():
    with tempfile.TemporaryDirectory() as tmp:
        sb = Sandbox(tmp)
        _, a = sb.start("offline"); sb.wait(a)
        time.sleep(1.1)
        _, b = sb.start("bench"); sb.wait(b)
        _t("`status bench` finds the latest bench run", b in sb.bg("status", "bench").stdout)
        _t("`status offline` finds the latest offline run", a in sb.bg("status", "offline").stdout)
        _t("plain `status` is the most recently started", b in sb.bg("status").stdout)
        lst = sb.bg("list").stdout.split("\n")
        _t("list names both runs", any(a in l for l in lst) and any(b in l for l in lst))
        _t("`status` with nothing recorded exits 3", Sandbox(tempfile.mkdtemp()).bg("status").returncode == 3)


def test_run_dirs_are_safe_from_the_job_pruner_and_from_git():
    with tempfile.TemporaryDirectory() as tmp:
        sb = Sandbox(tmp)
        _, ident = sb.start("offline"); sb.wait(ident)
        _t("a run id does not look like a bench job id (prune_jobs would delete those)",
           benchclient._JOB_ID_RE.match(ident) is None)
    r = subprocess.run(["git", "check-ignore", "-q", "tests/jobs/bg/bg-x-offline.AAAA/log"], cwd=REPO)
    _t("the default run directory is gitignored", r.returncode == 0)


if __name__ == "__main__":
    sys.exit(run(globals()))
