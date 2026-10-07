"""
parser_limit_probe.py -- what exactly does Max's codebox parser ("lua: [string DSL.Parser]: stack overflow (too many
captures)") count?  Spike 2026-10-06, after `require` turned out NOT to escape it (a 7.7 KB required file of 600
trivial statements fails alone, while a more complex 11 KB program compiles, so it is not bytes).

Each probe is a trivial program whose result is known; "ok" = compiled and correct. A failed compile wedges the
bench, so gather_proto.ensure_healthy reopens it between probes.
  F  one function body with N statements
  T  N statements at the top level of the main program
  L  N statements inside one for-loop body
  K  K separate functions of N statements each (is the limit per block or for the whole program?)
  P  N statements packed 5 per line (is it lines or statements?)
Run:  uv run --no-project --with numpy python3 scratch/parser_limit_probe.py
"""
import sys
from pathlib import Path

import numpy as np

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "tests"))
sys.path.insert(0, str(HERE))
import benchclient as bc            # noqa: E402
import gather_proto as gp           # noqa: E402

white = np.ones((16, 16, 4), np.float32)
X = 0.001


def works(code, expect):
    gp.ensure_healthy(bc)
    out, rep = bc.run_pass(code, [white], dim=(16, 16), timeout_ms=60000)
    if out is None or (rep.get("errors") or []):
        return False
    return abs(float(out[4, 4, 0]) - expect) < 2e-3


def stmts(n, per_line=1):
    lines = []
    for i in range(0, n, per_line):
        lines.append("  " + " ".join("a = a + x;" for _ in range(min(per_line, n - i))))
    return "\n".join(lines) + "\n"


def prog_F(n):
    return f"f1(x) {{\n  a = 0.0;\n{stmts(n)}  return a;\n}}\nout1 = vec(f1({X} + 0.0 * norm.x), 0.0, 0.0, 1.0);\n"


def prog_T(n):
    return f"a = 0.0;\nx = {X} + 0.0 * norm.x;\n{stmts(n)}out1 = vec(a, 0.0, 0.0, 1.0);\n"


def prog_L(n):
    return f"a = 0.0;\nx = {X} + 0.0 * norm.x;\nfor (i = 0; i < 1; i += 1) {{\n{stmts(n)}}}\nout1 = vec(a, 0.0, 0.0, 1.0);\n"


def prog_K(k, n):
    funcs = "".join(f"f{j}(x) {{\n  a = 0.0;\n{stmts(n)}  return a;\n}}\n" for j in range(k))
    calls = " + ".join(f"f{j}({X} + 0.0 * norm.x)" for j in range(k))
    return funcs + f"out1 = vec({calls}, 0.0, 0.0, 1.0);\n"


def prog_P(n):
    return f"f1(x) {{\n  a = 0.0;\n{stmts(n, 5)}  return a;\n}}\nout1 = vec(f1({X} + 0.0 * norm.x), 0.0, 0.0, 1.0);\n"


def threshold(name, make, expect_of, lo=20, hi=800):
    """Largest n that works, by doubling then bisection (assumes monotone)."""
    n = lo
    if not works(make(n), expect_of(n)):
        return None, lo
    last_ok = n
    while n < hi:
        n = min(hi, n * 2)
        if works(make(n), expect_of(n)):
            last_ok = n
        else:
            lo_, hi_ = last_ok, n
            while hi_ - lo_ > max(4, lo_ // 25):
                mid = (lo_ + hi_) // 2
                if works(make(mid), expect_of(mid)):
                    lo_ = mid
                else:
                    hi_ = mid
            return lo_, hi_
    return last_ok, None


def main():
    bc.reopen(wait=40.0)
    print("largest N that compiles (first failure just above):")
    for name, make in (("F  statements in one function body   ", prog_F),
                       ("T  statements at the top level        ", prog_T),
                       ("L  statements in one for-loop body     ", prog_L),
                       ("P  statements packed 5 per line (F)   ", prog_P)):
        ok, bad = threshold(name, make, lambda n: n * X)
        print(f"  {name}: works up to {ok}, fails by {bad}", flush=True)
    # per block or whole program?  K functions of N statements, N below the single-function limit
    ok_f, _ = threshold("F", prog_F, lambda n: n * X)
    n = max(10, int(ok_f * 0.6)) if ok_f else 50
    print(f"\nK functions of {n} statements each (each alone is under the single-function limit):")
    for k in (1, 2, 3, 4, 6):
        ok = works(prog_K(k, n), k * n * X)
        print(f"  K = {k}: total {k * n} statements -> {'compiled' if ok else 'FAILED'}", flush=True)
        if not ok:
            break
    gp.ensure_healthy(bc)


if __name__ == "__main__":
    main()
