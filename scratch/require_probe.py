"""
require_probe.py -- does GenExpr `require("file")` work in the bench's jit.gl.pix codebox, and does a required
file escape the codebox parser's size limit (~11 KB ok, ~14 KB fails, spike 2026-10-06)?

Probes (each a bench pass compared with a known value; the bench is reopened if a failed compile wedges it):
  R1  require a tiny helper file and call it
  R2  a required function that samples in2
  R3  a required function far too big to compile inline (control: the same body inline must FAIL)
  R4  the real Newton-start function from gather_proto.make_code_fn moved into a required file: output must equal
      the inline version, then how many starts fit in the main program
Helper files are written to tests/bench/ (the bench patch's folder) and removed at the end.

Run:  uv run --no-project --with numpy python3 scratch/require_probe.py
"""
import os
import sys
from pathlib import Path

import numpy as np

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "tests"))
sys.path.insert(0, str(HERE))
import benchclient as bc            # noqa: E402
import caustic_fidelity as cf       # noqa: E402
import gather_proto as gp           # noqa: E402

BENCH = bc.BENCH_DIR
made = []


def helper(name, text):
    p = BENCH / f"{name}.genexpr"
    p.write_text(text)
    made.append(p)


def run(code, field, white, params=None, dim=64):
    gp.ensure_healthy(bc)
    out, rep = bc.run_pass(code, [white, field], dim=(dim, dim), params=params or {}, timeout_ms=60000)
    return out, rep


def report(label, out, rep, expect):
    errs = rep.get("errors") or []
    if out is None:
        print(f"BAD {label:58s} no output: {rep.get('status')} | {(errs[0] if errs else '')[:110]}", flush=True)
        return False
    got = out[10, 20, :3].astype(float).tolist()
    ok = np.allclose(got, expect, atol=3e-3)
    print(f"{'ok ' if ok else 'BAD'} {label:58s} got {np.round(got, 4).tolist()} expect {np.round(expect, 4).tolist()}"
          f"  errors {len(errs)}" + (f" | {errs[0][:90]}" if errs and not ok else ""), flush=True)
    return ok


def main():
    field = gp.analytic_field(cf, 256)
    white = np.ones((64, 64, 4), np.float32)
    bc.reopen(wait=40.0)
    g = cf.g

    # R1: a tiny required helper
    helper("gp_help1", "addhalf(x) { return x + 0.5; }\n")
    out, rep = run('require("gp_help1");\nout1 = vec(addhalf(0.1 + 0.0 * norm.x), 0.0, 0.0, 1.0);', field, white)
    r1 = report("R1 require a tiny helper file", out, rep, [0.6, 0, 0])

    # R2: a required function that samples in2
    helper("gp_help2", "fieldx(u, v) { return (sample(in2, vec(u, v)).x - 0.5) * 2.0; }\n")
    fx = (g.sample(field, np.array([[0.3]], np.float32), np.array([[0.6]], np.float32))[0, 0, 0] - 0.5) * 2.0
    out, rep = run('require("gp_help2");\nout1 = vec(fieldx(0.3 + 0.0 * norm.x, 0.6) * 0.5 + 0.5, 0.0, 0.0, 1.0);', field, white)
    r2 = report("R2 required function samples in2", out, rep, [fx * 0.5 + 0.5, 0, 0])

    # R3: a body too big to compile inline; required it should (if parsed separately) compile
    n = 1500
    body = "bigacc(x) {\n  a = 0.0;\n" + "".join("  a = a + x;\n" for _ in range(n)) + "  return a;\n}\n"
    helper("gp_big", body)
    print(f"   (R3 body: {len(body) / 1024:.1f} KB, {n} statements)", flush=True)
    r3 = None
    if r1:
        out, rep = run('require("gp_big");\nout1 = vec(bigacc(0.0001 + 0.0 * norm.x), 0.0, 0.0, 1.0);', field, white)
        r3 = report("R3 required BIG function (should work if parsed apart)", out, rep, [n * 0.0001, 0, 0])

    # R4: the real Newton function in a required file; same output as inline?
    d = 3.5 * cf.first_fold_distance()
    params = {"d": d, "peak": 0.9, "tol": 1e-3}
    lo, hi = 80, 176
    white256 = np.ones((256, 256, 4), np.float32)
    if r1 and r2:
        for M in (6, 8, 10, 12, 16):
            full = gp.make_code_fn(6, M, 6, 2)
            cut = full.index("Param d(0.1);")
            func_text, main_text = full[:cut], 'require("gp_nstart");\n' + full[cut:]
            helper("gp_nstart", func_text)
            out, rep = run(main_text, field, white256, params, dim=256)
            if out is None or (rep.get("errors") or []):
                print(f"BAD R4 split program M={M:2d} (main {len(main_text) / 1024:4.1f} KB + required {len(func_text) / 1024:3.1f} KB): "
                      f"no usable output | {((rep.get('errors') or [''])[0])[:100]}", flush=True)
                continue
            line = f"ok  R4 split program M={M:2d} (main {len(main_text) / 1024:4.1f} KB + required {len(func_text) / 1024:3.1f} KB): compiled"
            if M == 6 or M == 8:
                gp.ensure_healthy(bc)
                ref, _ = bc.run_pass(full, [white256, field], dim=(256, 256), params=params, timeout_ms=60000)
                a, b = out[lo:hi, lo:hi, 0].astype(float), ref[lo:hi, lo:hi, 0].astype(float)
                line += f"; vs the same program with the function inline: r = {cf.pearson(a, b):.5f}, max|diff| = {np.abs(a - b).max():.4f}"
            print(line, flush=True)

    # control last (a failure wedges the bench): the same big body inline must fail if the limit is size-based
    inline = body + 'out1 = vec(bigacc(0.0001 + 0.0 * norm.x), 0.0, 0.0, 1.0);\n'
    out, rep = run(inline, field, white)
    ok = report("CONTROL the same big body INLINE (expected to fail)", out, rep, [n * 0.0001, 0, 0])
    print(f"   control {'passed (so the limit is NOT purely size-based)' if ok else 'failed as expected'}", flush=True)

    for p in made:
        p.unlink(missing_ok=True)
    gp.ensure_healthy(bc)


if __name__ == "__main__":
    main()
