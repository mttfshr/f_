"""
harness.py -- minimal test runner. No pytest dependency: each test_*.py file
ends with `sys.exit(run(globals()))` and runs standalone.

Tests call check() with a *measured* error so every run prints real numbers,
not just pass/fail -- the numbers are the useful record.
"""
import contextlib
import io
import os
import sys
import time
import traceback

# Quiet mode (TEST_QUIET=1, set by `tests/run.sh -q` and `tests/bench.sh -q`): a passing test prints nothing; a failing
# test prints its whole output; each file ends with ONE line. Normal mode is unchanged. If TEST_FULL_LOG names a file,
# the full per-test output (passes included) is appended there, so a quiet run never loses information.
QUIET = os.environ.get("TEST_QUIET") == "1"
FULL_LOG = os.environ.get("TEST_FULL_LOG")

# The Max install the offline tests compare against (MAX_APP overrides the default; tests/_log.sh and benchdeps.py read the same variable).
MAX_APP = os.environ.get("MAX_APP", "/Applications/Max.app")
SKIPPED = []        # (test name, reason) of every test that called skip(); printed in the summary, never silent


class Skip(Exception):
    """Raised by skip(): the test did not run, for a stated reason. Counted as skipped, not passed."""


def skip(reason):
    raise Skip(reason)


def max_path(*parts):
    """A path inside the Max install ($MAX_APP, default /Applications/Max.app)."""
    return os.path.join(MAX_APP, *parts)


def slow(fn):
    """Mark a test as slow. Skipped by run() unless BENCH_SLOW=1 (tests/bench.sh
    --slow or --all); the skip is printed, never silent."""
    fn.slow = True
    return fn


# Every check() result is also appended to tests/.state/check_results.jsonl (see tests/lib/checkhist.py) when a runner
# set TEST_RUN_ID, so measured errors and tolerance headroom can be tracked over runs. RECORD=False turns that off
# (test_harness does, so its fake checks never reach the history). _CURRENT says which file and test is running.
RECORD = True
_CURRENT = {"file": None, "test": None}


def _record(label, value, tol):
    if not RECORD:
        return
    try:
        import checkhist
        checkhist.record(_CURRENT["file"], _CURRENT["test"], label, value, tol)
    except Exception:
        pass   # the history is a convenience: it must never fail or slow a check


def _relfile(path):
    if not path:
        return None
    try:
        return os.path.relpath(os.path.realpath(path), os.path.dirname(os.path.dirname(os.path.realpath(__file__))))
    except Exception:
        return os.path.basename(str(path))


def check(label, value, tol):
    value = float(value)
    ok = value <= tol
    _record(label, value, tol)
    print(f"    {'ok ' if ok else 'BAD'}  {label}: {value:.3e}  (tol {tol:.0e})")
    if not ok:
        raise AssertionError(f"{label}: {value:.3e} > {tol:.0e}")


def note(label, value):
    print(f"    ...  {label}: {value}")


def _run_quiet(name, fn):
    """Run one test with its output captured. Print it (whole) only if it fails. Returns 1 on failure, else 0."""
    buf, verdict, t0 = io.StringIO(), "PASS", time.time()
    detail = ""
    with contextlib.redirect_stdout(buf):
        try:
            fn()
        except Skip as e:
            verdict, detail = "SKIP", f"  SKIP  {e}\n"
            SKIPPED.append((name, str(e)))
        except AssertionError as e:
            verdict, detail = "FAIL", f"  FAIL  {e}\n"
        except Exception:
            verdict, detail = "ERROR", "  ERROR\n" + traceback.format_exc()
    if FULL_LOG:
        with open(FULL_LOG, "a") as f:
            f.write(f"{name}\n{buf.getvalue()}  {verdict}  ({time.time() - t0:.2f}s)\n{detail if verdict != 'PASS' else ''}")
    if verdict in ("PASS", "SKIP"):
        return 0
    print(name)
    sys.stdout.write(buf.getvalue())
    sys.stdout.write(detail)
    return 1


def run(namespace):
    SKIPPED.clear()
    tests = [(k, v) for k, v in namespace.items()
             if k.startswith("test_") and callable(v)]
    with_slow = os.environ.get("BENCH_SLOW") == "1"
    skipped = [k for k, v in tests if getattr(v, "slow", False) and not with_slow]
    tests = [(k, v) for k, v in tests if k not in skipped]
    failed = 0
    _CURRENT["file"] = _relfile(namespace.get("__file__"))
    for name, fn in tests:
        _CURRENT["test"] = name
        if QUIET:
            failed += _run_quiet(name, fn)
            continue
        print(name)
        t0 = time.time()
        try:
            fn()
            print(f"  PASS  ({time.time() - t0:.2f}s)")
        except Skip as e:
            SKIPPED.append((name, str(e)))
            print(f"  SKIP  {e}")
        except AssertionError as e:
            failed += 1
            print(f"  FAIL  {e}")
        except Exception:
            failed += 1
            print("  ERROR")
            traceback.print_exc()
    if QUIET:
        label = os.path.basename(sys.argv[0]) or "tests"
        extra = f"  (skipped slow: {len(skipped)})" if skipped else ""
        if SKIPPED:
            extra += "  (skipped: " + "; ".join(f"{n}: {r}" for n, r in SKIPPED) + ")"
        print(f"{'ok  ' if not failed else 'FAIL'} {label}: {len(tests) - failed - len(SKIPPED)}/{len(tests)}{extra}")
        return 1 if failed else 0
    print(f"\n{len(tests) - failed - len(SKIPPED)}/{len(tests)} passed" + (f", {len(SKIPPED)} skipped" if SKIPPED else ""))
    for n, r in SKIPPED:
        print(f"skipped: {n}: {r}")
    if skipped:
        print(f"skipped (slow): {', '.join(skipped)}  -- run with tests/bench.sh --slow")
    return 1 if failed else 0
