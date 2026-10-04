"""
harness.py -- minimal test runner. No pytest dependency: each test_*.py file
ends with `sys.exit(run(globals()))` and runs standalone.

Tests call check() with a *measured* error so every run prints real numbers,
not just pass/fail -- the numbers are the useful record.
"""
import os
import time
import traceback


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


def run(namespace):
    tests = [(k, v) for k, v in namespace.items()
             if k.startswith("test_") and callable(v)]
    with_slow = os.environ.get("BENCH_SLOW") == "1"
    skipped = [k for k, v in tests if getattr(v, "slow", False) and not with_slow]
    tests = [(k, v) for k, v in tests if k not in skipped]
    failed = 0
    for name, fn in tests:
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
    print(f"\n{len(tests) - failed}/{len(tests)} passed")
    if skipped:
        print(f"skipped (slow): {', '.join(skipped)}  -- run with tests/bench.sh --slow")
    return 1 if failed else 0
