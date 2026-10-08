"""
run_feasibility_probes.py -- throwaway (tasks T007, T008 of .specify/f_caustic_scatter/). Needs the module bench
(Max) and NO Vsynth patch open. Delete with the probes once T011 has recorded the answers.

  T007  is package/code/ on Max's search path for jit.gl.shader @file?
        (a) JS File() lookup of a probe shader that exists ONLY in package/code/, of Vsynth's vtfk.jxs (control:
            must be found) and of a bogus name (control: must be missing);
        (b) a real bench job: two jit.gl.shader objects, one naming the probe, one naming a missing file; the
            bench's error list must show exactly the missing one.
  T008  what does a jit.gl.pix read from an UNCONNECTED inlet (in2)?

Run:  uv run --no-project --with numpy python3 scratch/run_feasibility_probes.py
"""
import shutil
import subprocess
import sys
from pathlib import Path

import numpy as np

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tests"))
import caustic_runner as cr   # noqa: E402
import modulebench as mb      # noqa: E402
import scatter_mirror as sm   # noqa: E402

JS = """
function probe(n) {
  var f = new File(n);
  var ok = f.isopen;
  if (ok) f.close();
  return ok ? "found" : "missing";
}
var r = {probe_in_package_code: probe("f_caustic_sheets_probe.jxs"),
         control_vtfk: probe("vtfk.jxs"),
         control_bogus: probe("probe_nonexistent_control.jxs")};
r;
"""


def t007():
    print("\n== T007: is package/code/ on the shader search path? ==")
    code = REPO / "package" / "code"
    code.mkdir(exist_ok=True)
    shutil.copy2(REPO / "tests" / "bench" / "spike_scatter.jxs", code / "f_caustic_sheets_probe.jxs")
    print(f"  placed {code / 'f_caustic_sheets_probe.jxs'}")
    print("  (a) JS File() lookup inside Max:", mb.bench_eval(JS))
    res, _ = cr.run([sm.white(64)], [], "probe_shader_path.maxpat", n_out=1, n_in=1)
    errs = cr.report(res, "shader probe job")
    mentions = [e for e in errs if "probe_nonexistent_control" in e]
    found_err = [e for e in errs if "f_caustic_sheets_probe" in e]
    print(f"  (b) errors naming the MISSING control file: {len(mentions)} (expected 1+); "
          f"errors naming the probe shader in package/code: {len(found_err)} (0 means it was found)")


def t008():
    print("\n== T008: what does an unconnected jit.gl.pix inlet read? ==")
    src = sm.gradient_src(64)
    res, out = cr.run([src], [], "probe_unconnected_input.maxpat", n_out=2, n_in=1)
    cr.report(res, "unconnected-input job")
    for tag in sorted(out):
        a, b = out[tag].get(1), out[tag].get(2)
        if a is None or b is None:
            print(f"  [{tag}] missing outlets: {sorted(out[tag])}")
            continue
        uniq = np.unique(a.reshape(-1, 4), axis=0)
        print(f"  [{tag}] in2 (UNCONNECTED) read: {len(uniq)} distinct RGBA value(s); first {uniq[:3].tolist()}; "
              f"min {a.min():.4f} max {a.max():.4f}")
        print(f"  [{tag}] in1 (connected) passthrough == source: max|diff| {np.abs(b - src).max():.2e}")


def main():
    subprocess.run([sys.executable, str(REPO / "tests" / "bench" / "make_probes.py")], check=True, cwd=REPO / "tests" / "bench")
    cr.ensure_bench()
    t007()
    t008()
    return 0


if __name__ == "__main__":
    sys.exit(main())
