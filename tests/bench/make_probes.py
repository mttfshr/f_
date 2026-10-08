"""
make_probes.py -- throwaway generator for the Phase 1 feasibility probes of .specify/f_caustic_scatter/ (T007, T008).
Delete the probes and this file once T011 has recorded the answers.

  probe_unconnected_input.maxpat   a 2-inlet bpatcher around a jit.gl.pix that reads in2; the bench wires only
                                   inlet 0, so inlet 1 (pix in2) is UNCONNECTED. outlet 0 = what in2 reads,
                                   outlet 1 = in1 passed through (proves the connected inlet flows).
  probe_shader_path.maxpat         two jit.gl.shader objects: one names f_caustic_sheets_probe.jxs (present only in
                                   package/code/), one names a file that does not exist anywhere (the negative
                                   control: the bench's error list must show exactly that one).

Run:  python3 tests/bench/make_probes.py
"""
import json
from pathlib import Path

from patchbuild import APPVERSION, Patch, patcher_dict

HERE = Path(__file__).resolve().parent


def new_patch():
    p = Patch()
    return p, p.obj, p.wire, p.boxes, p.lines


def port(boxes, oid, maxclass, rect):
    b = {"id": oid, "maxclass": maxclass, "patching_rect": [float(v) for v in rect]}
    if maxclass == "inlet":
        b.update({"numinlets": 0, "numoutlets": 1, "outlettype": [""]})
    else:
        b.update({"numinlets": 1, "numoutlets": 0})
    boxes.append({"box": b})


def pix2(boxes, oid, code, rect):
    """A 2-inlet, 2-outlet jit.gl.pix with a one-codebox gen patcher."""
    def sub(i, **kw):
        kw.update({"id": f"gen-obj-{i}", "patching_rect": [30.0 + 120 * (i % 2), 30.0 + 60 * (i // 2), 110.0, 22.0]})
        return {"box": kw}
    gen = {"fileversion": 1, "appversion": dict(APPVERSION), "classnamespace": "jit.gen",
           "rect": [100.0, 100.0, 520.0, 320.0],
           "boxes": [sub(1, maxclass="newobj", numinlets=0, numoutlets=1, outlettype=[""], text="in 1"),
                     sub(2, maxclass="newobj", numinlets=0, numoutlets=1, outlettype=[""], text="in 2"),
                     sub(3, maxclass="codebox", code=code, numinlets=2, numoutlets=2, outlettype=["", ""],
                         fontname="<Monospaced>", fontsize=12.0),
                     sub(4, maxclass="newobj", numinlets=1, numoutlets=0, text="out 1"),
                     sub(5, maxclass="newobj", numinlets=1, numoutlets=0, text="out 2")],
           "lines": [{"patchline": {"source": ["gen-obj-1", 0], "destination": ["gen-obj-3", 0]}},
                     {"patchline": {"source": ["gen-obj-2", 0], "destination": ["gen-obj-3", 1]}},
                     {"patchline": {"source": ["gen-obj-3", 0], "destination": ["gen-obj-4", 0]}},
                     {"patchline": {"source": ["gen-obj-3", 1], "destination": ["gen-obj-5", 0]}}]}
    boxes.append({"box": {"id": oid, "maxclass": "newobj", "text": "jit.gl.pix vsynth @type float32",
                          "numinlets": 2, "numoutlets": 3, "outlettype": ["jit_gl_texture", "jit_gl_texture", ""],
                          "patching_rect": [float(v) for v in rect], "patcher": gen}})


def write(name, boxes, lines):
    path = HERE / name
    with open(path, "w") as f:
        json.dump(patcher_dict(boxes, lines, rect=(100.0, 100.0, 520.0, 360.0)), f, indent=2)
    print(f"wrote {path.name} ({len(boxes)} boxes, {len(lines)} lines)")


# ---- T008: an unconnected pix input
p, obj, wire, boxes, lines = new_patch()
port(boxes, "in0", "inlet", [20, 20, 30, 22])
port(boxes, "in1", "inlet", [200, 20, 30, 22])
port(boxes, "o0", "outlet", [20, 300, 30, 22])
port(boxes, "o1", "outlet", [200, 300, 30, 22])
CODE = ("out1 = vec(sample(in2, norm).x, sample(in2, norm).y, sample(in2, norm).z, sample(in2, norm).w);\n"
        "out2 = vec(sample(in1, norm).x, sample(in1, norm).y, sample(in1, norm).z, sample(in1, norm).w);\n")
pix2(boxes, "px", CODE, [20, 120, 260, 22])
wire("in0", 0, "px", 0)
wire("in1", 0, "px", 1)
wire("px", 0, "o0", 0)
wire("px", 1, "o1", 0)
write("probe_unconnected_input.maxpat", boxes, lines)

# ---- T007: shader search path (a present-in-package/code file, and a negative control)
p, obj, wire, boxes, lines = new_patch()
port(boxes, "in0", "inlet", [20, 20, 30, 22])
port(boxes, "o0", "outlet", [20, 300, 30, 22])
obj("shA", "jit.gl.shader vsynth @name #0.probe_a @file f_caustic_sheets_probe.jxs", 1, 2, [20, 100, 420, 22], ["", ""])
obj("shB", "jit.gl.shader vsynth @name #0.probe_b @file probe_nonexistent_control.jxs", 1, 2, [20, 140, 420, 22], ["", ""])
wire("in0", 0, "o0", 0)
write("probe_shader_path.maxpat", boxes, lines)
