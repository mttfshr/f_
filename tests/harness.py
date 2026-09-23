"""
harness.py -- minimal test runner. No pytest dependency: each test_*.py file
ends with `sys.exit(run(globals()))` and runs standalone.

Tests call check() with a *measured* error so every run prints real numbers,
not just pass/fail -- the numbers are the useful record.
"""
import time
import traceback


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
    return 1 if failed else 0
