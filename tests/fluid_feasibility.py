"""
fluid_feasibility.py -- f_vf_fluid Block C (tasks.md T002-T004): does the
solver/encode split of plan ADR-2 work inside Vsynth's real render context?

Builds a scratch two-stage bpatcher and runs it through the MODULE bench
(tests/bench/bench_module.maxpat, which loads bpatchers inside vs_render):

    inlet -> routepass -> vs_inState -+-> A  jit.gl.pix @adapt 0 @dim 256 256   (solver stage)
                                      |     out1 -> module outlet 2 (raw, to read its size)
                                      +-> B  jit.gl.pix @adapt 1 (render res)   (encode stage)
                                            in1 = the (force) texture, in2 = A, samples A bilinearly
                                            out1 -> module outlet 1

  E1   does a 256^2 pix run inside Vsynth, what size is each stage, and does B
       upsample A correctly?
  E1b  what size is B when the inlet is UNCONNECTED (vs_inState -> vs_black)?
  E1c  variant "draw": B is triggered by `r draw` (a bang, like the generators)
       with the force on in2 and A on in3 -- does B then take the render size
       whether or not the inlet is connected?

The scratch module is written into package/patchers/ so the bench can find it
by name, and always removed afterwards. Never commit it.

Needs Max with tests/bench/bench_module.maxpat open (other patches closed).
Run:  uv run --no-project --with numpy python3 tests/fluid_feasibility.py
"""
import json
import sys
import time

import numpy as np

import benchclient as bc
import jxf
import modulebench as mb
from gpu_sim import F32, TWOPI, grid, sample

NAME = "f_zz_fluid_dimtest"
PATH = mb.PATCHERS / f"{NAME}.maxpat"

CODEBOX_A = """\
x = sample(in1, norm).x * 0;
out1 = vec(0.5 + 0.5 * sin(twopi * 3 * norm.x) + x, 0.5 + 0.5 * cos(twopi * 2 * norm.y), norm.x, 1);
"""

CODEBOX_B = """\
x = sample(in1, norm).x * 0;
out1 = vec(sample(in2, norm).x + x, sample(in2, norm).y, sample(in1, norm).x, 1);
"""


CODEBOX_B_DRAW = """\
out1 = vec(sample(in3, norm).x, sample(in3, norm).y, sample(in2, norm).x, 1);
"""


def gen_patcher(codebox, n_in):
    boxes = [{"box": {"id": f"gen-in{i + 1}", "maxclass": "newobj", "numinlets": 0, "numoutlets": 1,
                      "outlettype": [""], "patching_rect": [22.0 + 58 * i, 30.0, 28.0, 22.0],
                      "text": f"in {i + 1}"}} for i in range(n_in)]
    boxes.append({"box": {"id": "gen-code", "maxclass": "codebox", "code": codebox,
                          "fontface": 0, "fontname": "<Monospaced>", "fontsize": 12.0,
                          "numinlets": n_in, "numoutlets": 1, "outlettype": [""],
                          "patching_rect": [22.0, 80.0, 550.0, 200.0]}})
    boxes.append({"box": {"id": "gen-out1", "maxclass": "newobj", "numinlets": 1, "numoutlets": 0,
                          "patching_rect": [22.0, 300.0, 35.0, 22.0], "text": "out 1"}})
    lines = [{"patchline": {"source": [f"gen-in{i + 1}", 0], "destination": ["gen-code", i]}}
             for i in range(n_in)]
    lines.append({"patchline": {"source": ["gen-code", 0], "destination": ["gen-out1", 0]}})
    return {"fileversion": 1,
            "appversion": {"major": 9, "minor": 1, "revision": 4, "architecture": "x64", "modernui": 1},
            "classnamespace": "jit.gen", "rect": [100.0, 100.0, 700.0, 400.0],
            "boxes": boxes, "lines": lines}


def scratch_module(variant="force0"):
    def b(id, **kw):
        return {"box": {"id": id, **kw}}

    def w(s, so, d, di):
        return {"patchline": {"source": [s, so], "destination": [d, di]}}

    boxes = [
        b("obj-1", maxclass="inlet", comment="texture / control", index=0, numinlets=0, numoutlets=1,
          outlettype=[""], patching_rect=[30.0, 30.0, 30.0, 30.0]),
        b("obj-2", maxclass="outlet", comment="B (encode stage)", index=0, numinlets=1, numoutlets=0,
          patching_rect=[30.0, 500.0, 30.0, 30.0]),
        b("obj-201", maxclass="outlet", comment="A raw (solver stage)", index=1, numinlets=1, numoutlets=0,
          patching_rect=[100.0, 500.0, 30.0, 30.0]),
        b("obj-3", maxclass="newobj", numinlets=3, numoutlets=3, outlettype=["", "", ""],
          patching_rect=[200.0, 90.0, 215.0, 22.0], text="routepass jit_gl_texture jit_matrix"),
        b("obj-101", maxclass="newobj", numinlets=1, numoutlets=2, outlettype=["", ""],
          patching_rect=[200.0, 130.0, 80.0, 22.0], text="vs_inState"),
        b("obj-5", maxclass="newobj", numinlets=1, numoutlets=2, outlettype=["jit_gl_texture", ""],
          patcher=gen_patcher(CODEBOX_A, 1), patching_rect=[200.0, 250.0, 330.0, 22.0],
          text="jit.gl.pix vsynth @name #0_dimtest_a @adapt 0 @dim 256 256 @type float32",
          varname="#0_dimtest_a"),
    ]
    draw = variant == "draw"
    boxes.append(b("obj-6", maxclass="newobj", numinlets=3 if draw else 2, numoutlets=2,
                   outlettype=["jit_gl_texture", ""],
                   patcher=gen_patcher(CODEBOX_B_DRAW if draw else CODEBOX_B, 3 if draw else 2),
                   patching_rect=[200.0, 350.0, 280.0, 22.0],
                   text="jit.gl.pix vsynth @name #0_dimtest_b @adapt 1 @type float32",
                   varname="#0_dimtest_b"))
    lines = [w("obj-1", 0, "obj-3", 0), w("obj-3", 0, "obj-101", 0),
             w("obj-101", 0, "obj-5", 0), w("obj-6", 0, "obj-2", 0), w("obj-5", 0, "obj-201", 0)]
    if draw:
        boxes.append(b("obj-102", maxclass="newobj", numinlets=1, numoutlets=1, outlettype=[""],
                       patching_rect=[350.0, 130.0, 40.0, 22.0], text="r draw"))
        lines += [w("obj-102", 0, "obj-6", 0), w("obj-101", 0, "obj-6", 1), w("obj-5", 0, "obj-6", 2)]
    else:
        lines += [w("obj-101", 0, "obj-6", 0), w("obj-5", 0, "obj-6", 1)]
    return {"patcher": {"fileversion": 1,
                        "appversion": {"major": 9, "minor": 1, "revision": 4, "architecture": "x64",
                                       "modernui": 1},
                        "classnamespace": "box", "rect": [100.0, 100.0, 700.0, 600.0],
                        "boxes": boxes, "lines": lines}}


def run(inputs, variant="force0", warmup=12, settle=6, _retry=True):
    # a brand-new file in package/patchers is not on Max's search path yet:
    # write it first, then (re)open the bench; retry once on a load error
    with open(mb.PATCHERS / f"{NAME}.maxpat", "w") as f:
        json.dump(scratch_module(variant), f, indent=2)
    bc.reopen(ports=bc.MODULE_PORTS, patch="bench_module.maxpat")
    job, job_dir = bc.new_job("module", warmup=warmup, settle=settle, timeout_ms=20000)
    job["wrapper"] = f"mjob_{job['id']}.maxpat"
    job["inputs"] = []
    for i, arr in enumerate(inputs):
        fn = f"in{i + 1}.jxf"
        jxf.write_rgba(job_dir / fn, arr)
        job["inputs"].append(fn)
    job["params"], job["readback"], job["controls"] = [], {}, []
    wrapper = bc.BENCH_DIR / job["wrapper"]
    with open(wrapper, "w") as f:
        json.dump(mb.make_wrapper(f"{NAME}.maxpat", 1, 2), f, indent=2)
    result = bc.run_job(job, job_dir, ports=bc.MODULE_PORTS)
    if _retry and any("error loading patcher" in e for e in result["errors"]):
        time.sleep(2.0)
        return run(inputs, variant, warmup, settle, _retry=False)
    arrays = {k: jxf.read_rgba(job_dir / f"base_out{k}.jxf")
              for k in (result.get("outputs") or {}).get("base", [])}
    try:
        dims = mb.bench_eval(
            "pixList().map(function (p) { return [String(p.getattr('name')), p.getattr('dim'), "
            "p.getattr('adapt')]; })")
    except Exception as e:                      # introspection is a bonus
        dims = f"bench_eval failed: {e}"
    return result, arrays, dims


def describe(label, result, arrays, dims):
    print(f"\n=== {label}")
    print("status:", result["status"], "| errors:", result["errors"][:5])
    print("pix seen by the bench:", result.get("pix"))
    print("pix dim/adapt attrs:", dims)
    for k, name in ((1, "B (encode, @adapt 1)"), (2, "A (solver, @dim 256 256)")):
        a = arrays.get(k)
        print(f"outlet {k} {name}: " + ("no frame captured" if a is None else f"shape {a.shape[:2]}"))


def analyse_connected(inp, arrays):
    A, B = arrays.get(2), arrays.get(1)
    if A is not None:
        nx, ny, _, _ = grid(*A.shape[:2])
        wantR = 0.5 + 0.5 * np.sin(TWOPI * 3 * nx)
        wantG = 0.5 + 0.5 * np.cos(TWOPI * 2 * ny)
        print(f"A pattern vs analytic: R {np.abs(A[..., 0] - wantR).max():.2e}, "
              f"G {np.abs(A[..., 1] - wantG).max():.2e}")
    if A is not None and B is not None:
        nx, ny, _, _ = grid(*B.shape[:2])
        up = sample(A, nx, ny, wrap=True)
        upc = sample(A, nx, ny, wrap=False)
        h, w = B.shape[:2]
        e = lambda ref: float(np.abs(B[..., :2] - ref[..., :2]).max())
        msg = f"B (R,G) vs A reads: bilinear-wrap {e(up):.2e} | bilinear-clamp {e(upc):.2e}"
        if A.shape[0] > h and A.shape[0] % h == 0 and A.shape[1] % w == 0:
            fy, fx = A.shape[0] // h, A.shape[1] // w
            box = A[:h * fy, :w * fx].reshape(h, fy, w, fx, 4).mean(axis=(1, 3))
            near = A[fy // 2::fy, fx // 2::fx][:h, :w]
            msg += f" | {fy}x{fx} box mean {e(box):.2e} | nearest {e(near):.2e}"
        print(msg)
        ee = np.abs(B[..., :2] - up[..., :2]).max(axis=-1)
        iy, ix = np.unravel_index(np.argmax(ee), ee.shape)
        print(f"   worst mismatch at pixel (row {iy}, col {ix}) of {B.shape[:2]}: {ee[iy, ix]:.2e}; "
              f"interior (2px in) worst {ee[2:-2, 2:-2].max():.2e}")
        if B.shape[:2] == inp.shape[:2]:
            print(f"B blue vs the input texture's red: {np.abs(B[..., 2] - inp[..., 0]).max():.2e}")


def main():
    bc.require_bench(ports=bc.MODULE_PORTS, patch="bench_module.maxpat")
    try:
        inp = mb.test_input(64)
        res, arrays, dims = run([inp])
        describe("E1: inlet CONNECTED (64x64 input texture)", res, arrays, dims)
        analyse_connected(inp, arrays)
        res2, arrays2, dims2 = run([])
        describe("E1b: inlet UNCONNECTED (vs_black via vs_inState)", res2, arrays2, dims2)
        res3, arrays3, dims3 = run([inp], variant="draw")
        describe("E1c: `r draw` trigger, inlet CONNECTED (64x64 input texture)", res3, arrays3, dims3)
        analyse_connected(inp, arrays3)
        res4, arrays4, dims4 = run([], variant="draw")
        describe("E1c: `r draw` trigger, inlet UNCONNECTED", res4, arrays4, dims4)
    finally:
        PATH.unlink(missing_ok=True)
        for old in bc.BENCH_DIR.glob("mjob_*.maxpat"):
            old.unlink()
    print("\nscratch module removed.")


if __name__ == "__main__":
    sys.exit(main())
