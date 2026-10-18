"""
test_harness.py -- the runner's @slow marker. A slow test is skipped by default,
the skip is printed by name (never silent), BENCH_SLOW=1 runs it, and a failing
slow test fails the run when it is enabled.

Run:  tests/run.sh tests/toolchain/test_harness.py
"""
import io
import os
import sys
from contextlib import redirect_stdout

from harness import check, run, skip, slow


def _t(label, cond):
    check(label, 0 if cond else 1, 0)


def _run(namespace, slow_on):
    old = os.environ.get("BENCH_SLOW")
    if slow_on:
        os.environ["BENCH_SLOW"] = "1"
    else:
        os.environ.pop("BENCH_SLOW", None)
    buf = io.StringIO()
    import harness as _h
    saved_quiet, _h.QUIET = _h.QUIET, False   # the assertions below expect non-quiet output, even under run.sh -q
    saved_record, _h.RECORD = _h.RECORD, False   # the fake tests' checks must not reach the check history
    saved_current = dict(_h._CURRENT)
    saved_skipped = list(_h.SKIPPED)
    try:
        with redirect_stdout(buf):
            code = run(namespace)
    finally:
        _h.QUIET = saved_quiet
        _h.RECORD = saved_record
        _h._CURRENT.update(saved_current)
        _h.SKIPPED[:] = saved_skipped
        if old is None:
            os.environ.pop("BENCH_SLOW", None)
        else:
            os.environ["BENCH_SLOW"] = old
    return code, buf.getvalue()


def _namespace(calls):
    def test_fast():
        calls.append("fast")

    @slow
    def test_slow_ok():
        calls.append("slow_ok")

    @slow
    def test_slow_fails():
        calls.append("slow_fails")
        raise AssertionError("boom")

    return {"test_fast": test_fast, "test_slow_ok": test_slow_ok, "test_slow_fails": test_slow_fails}


def test_slow_tests_are_skipped_by_default_and_the_skip_is_visible():
    calls = []
    code, out = _run(_namespace(calls), slow_on=False)
    _t("only the fast test ran", calls == ["fast"])
    _t("a skipped slow test does not fail the run", code == 0)
    _t("summary counts only what ran", "1/1 passed" in out)
    _t("skipped tests are named in the output",
       "skipped (slow): test_slow_ok, test_slow_fails" in out)
    _t("the output says how to run them", "tests/bench.sh --slow" in out)


def test_slow_tests_run_when_enabled_and_their_failures_count():
    calls = []
    code, out = _run(_namespace(calls), slow_on=True)
    _t("every test ran", sorted(calls) == ["fast", "slow_fails", "slow_ok"])
    _t("a failing slow test fails the run", code == 1)
    _t("summary counts the slow tests", "2/3 passed" in out)
    _t("nothing is reported skipped", "skipped" not in out)


def test_no_slow_tests_means_no_skip_line():
    code, out = _run({"test_a": lambda: None}, slow_on=False)
    _t("plain namespace passes", code == 0 and "1/1 passed" in out)
    _t("and prints no skip line", "skipped" not in out)


def test_the_environment_is_restored():
    before = os.environ.get("BENCH_SLOW")
    _run(_namespace([]), slow_on=True)
    _t("BENCH_SLOW is as it was", os.environ.get("BENCH_SLOW") == before)


def test_skip_is_counted_as_skipped_and_the_reason_is_printed():
    def test_runs():
        pass

    def test_skips():
        skip("Max not found")

    code, out = _run({"test_runs": test_runs, "test_skips": test_skips}, False)
    _t("a skip is not a failure", code == 0)
    _t("it is not counted as a pass", "1/2 passed, 1 skipped" in out)
    _t("the reason is printed", "skipped: test_skips: Max not found" in out)


if __name__ == "__main__":
    sys.exit(run(globals()))
