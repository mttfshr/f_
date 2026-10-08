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


def slow(fn):
    """Mark a test as slow. Skipped by run() unless BENCH_SLOW=1 (tests/bench.sh
    --slow or --all); the skip is printed, never silent."""
    fn.slow = True
    return fn


def check(label, value, tol):
    value = float(value)
    ok = value <= tol
    print(f"    {'ok ' if ok else 'BAD'}  {label}: {value:.3e}  (tol {tol:.0e})")
    if not ok:
        raise AssertionError(f"{label}: {value:.3e} > {tol:.0e}")


def note(label, value):
    print(f"    ...  {label}: {float(value):.3e}")


def _run_quiet(name, fn):
    """Run one test with its output captured. Print it (whole) only if it fails. Returns 1 on failure, else 0."""
    buf, verdict, t0 = io.StringIO(), "PASS", time.time()
    detail = ""
    with contextlib.redirect_stdout(buf):
        try:
            fn()
        except AssertionError as e:
            verdict, detail = "FAIL", f"  FAIL  {e}\n"
        except Exception:
            verdict, detail = "ERROR", "  ERROR\n" + traceback.format_exc()
    if FULL_LOG:
        with open(FULL_LOG, "a") as f:
            f.write(f"{name}\n{buf.getvalue()}  {verdict}  ({time.time() - t0:.2f}s)\n{detail if verdict != 'PASS' else ''}")
    if verdict == "PASS":
        return 0
    print(name)
    sys.stdout.write(buf.getvalue())
    sys.stdout.write(detail)
    return 1


def run(namespace):
    tests = [(k, v) for k, v in namespace.items()
             if k.startswith("test_") and callable(v)]
    with_slow = os.environ.get("BENCH_SLOW") == "1"
    skipped = [k for k, v in tests if getattr(v, "slow", False) and not with_slow]
    tests = [(k, v) for k, v in tests if k not in skipped]
    failed = 0
    for name, fn in tests:
        if QUIET:
            failed += _run_quiet(name, fn)
            continue
        print(name)
        t0 = time.time()
        try:
            fn()
            print(f"  PASS  ({time.time() - t0:.2f}s)")
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
        print(f"{'ok  ' if not failed else 'FAIL'} {label}: {len(tests) - failed}/{len(tests)}{extra}")
        return 1 if failed else 0
    print(f"\n{len(tests) - failed}/{len(tests)} passed")
    if skipped:
        print(f"skipped (slow): {', '.join(skipped)}  -- run with tests/bench.sh --slow")
    return 1 if failed else 0
