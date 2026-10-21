#!/usr/bin/env python3
"""
make_boundmode_probe.py -- writes scratch/boundmode_probe.maxpat, a hand-test patch for one question:

    What does a bare GenExpr sample() do for uv outside [0, 1] in a shipped-style jit.gl.pix chain
    (clamp, or wrap), compared with the codebox bench's path?

(Probe P2/P6 in tests/records/bench_mirror_findings_probes.py found WRAP on the bench; skills/jit-gen-codebox/
SKILL.md says CLAMP for a shipped jit.gl.pix. See HANDOFF 2026-10-20.)

The patch has ONE ramp (R = x) and six probes, each `out1 = sample(in1, vec(U, norm.y, 0.0))`, fed two ways:
  Path A (bench-like):   ramp pix -> jit.matrix (readback) -> jit.gl.texture -> probe pix
  Path B (shipped-like): ramp pix -> probe pix directly (a pix output texture, as Vsynth chains do)
for U = 1.3, -0.2 and exactly 1.0. Every probe is read back through a jit.matrix; a metro sends `getcell 32 0`
and the six message boxes show `cell 32 0 val A R G B` (R is the second number).

What drives it: jit.world's second outlet sends a draw bang every frame (the bench wires it the same way); here it is
connected to the ramp pix, the ramp matrix, the path-A texture (the bench bangs its jit.gl.texture the same way) and all six probe pixes, and a counter shows the frames arriving.

Boxes are deep copies of real ones (the shipped f_stereo pix box and its inline gen patcher, the bench's
jit.world / jit.matrix / jit.gl.texture), so their structure is the proven one. Run:
    python3 scratch/make_boundmode_probe.py        (needs nothing but the stdlib)
"""
import copy
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "scratch" / "boundmode_probe.maxpat"
CTX = "bm_ctx"

bench = json.load(open(ROOT / "tests" / "bench" / "bench.maxpat"))
stereo = json.load(open(ROOT / "package" / "patchers" / "f_stereo.maxpat"))


def by_id(patcher, wanted):
    for b in patcher["boxes"]:
        if b["box"]["id"] == wanted:
            return b["box"]
    raise KeyError(wanted)


def find_pix(patcher):
    for b in patcher["boxes"]:
        bx = b["box"]
        if bx.get("text", "").startswith("jit.gl.pix"):
            return bx
        if "patcher" in bx:
            r = find_pix(bx["patcher"])
            if r:
                return r


W = by_id(bench["patcher"], "world")            # jit.world
TEX = by_id(bench["patcher"], "tex1")           # jit.gl.texture
MAT = by_id(bench["patcher"], "outmat1")        # jit.matrix ... @adapt 1 (readback)
PIX = find_pix(stereo["patcher"])               # shipped-style jit.gl.pix with an inline gen patcher

boxes, lines = [], []
_n = [0]


def nid():
    _n[0] += 1
    return f"obj-{_n[0]}"


def add(box, x, y, w=None, h=None):
    box = copy.deepcopy(box)
    box["id"] = nid()
    r = box.get("patching_rect", [0, 0, 100, 22])
    box["patching_rect"] = [float(x), float(y), float(w or r[2]), float(h or r[3])]
    box.pop("varname", None)
    boxes.append({"box": box})
    return box["id"]


def simple(maxclass, text, x, y, w, h=22, nin=1, nout=1, outtype=None):
    b = {"maxclass": maxclass, "text": text, "numinlets": nin, "numoutlets": nout,
         "outlettype": outtype if outtype is not None else [""] * nout, "patching_rect": [x, y, w, h]}
    if maxclass == "comment":
        b.update(numoutlets=0, outlettype=[], numinlets=1)
    if maxclass == "message":
        b.update(numinlets=2)
    return add(b, x, y, w, h)


def pix(name, code, x, y):
    bx = copy.deepcopy(PIX)
    bx["text"] = f"jit.gl.pix {CTX} @name {name} @type float32 @dim 64 1 @adapt 0"
    for b in bx["patcher"]["boxes"]:
        if b["box"]["maxclass"] == "codebox":
            b["box"]["code"] = code
    return add(bx, x, y, 330, 22)


def connect(src, so, dst, di):
    lines.append({"patchline": {"destination": [dst, di], "source": [src, so]}})


def named(box, text):
    b = copy.deepcopy(box)
    b["text"] = text
    return b


world = add(named(W, f"jit.world {CTX} @enable 1 @size 128 128"), 30, 20)
simple("comment", "boundmode hand test: one ramp (R = x), six probes  out1 = sample(in1, vec(U, norm.y, 0)).  "
                  "Path A = bench-like (ramp -> matrix -> texture).  Path B = shipped-like (pix -> pix).", 30, 50, 900)
simple("comment", "Read the SECOND number (R) of each readout:  U = 1.3  CLAMP 0.992 | WRAP 0.30      "
                  "U = -0.2  CLAMP 0.008 | WRAP 0.80      U = exactly 1.0  CLAMP 0.992 | WRAP 0.008 (first texel)", 30, 72, 900)

frames = simple("newobj", "counter", 160, 20, 60, nin=4, nout=4, outtype=["int", "", "", "int"])
shown_frames = add({"maxclass": "number", "numinlets": 1, "numoutlets": 2, "outlettype": ["", "bang"],
                    "patching_rect": [230.0, 20.0, 50.0, 22.0], "parameter_enable": 0}, 230, 20, 50, 22)
simple("comment", "<- frame count: must be climbing (jit.world draw bang). If it is stuck, nothing is rendering.", 290, 22, 520)
connect(world, 1, frames, 0)
connect(frames, 0, shown_frames, 0)
draw_targets = []

ramp = pix("bm_ramp", "out1 = vec(norm.x, norm.y, 0.0, 1.0);\n", 30, 120)

# Path A: pix -> matrix (readback) -> texture
ramp_mat = add(named(MAT, "jit.matrix bm_ramp_a 4 float32 64 1 @adapt 1"), 30, 160, 260)
tex_a = add(named(TEX, f"jit.gl.texture {CTX} @name bm_tex_a @type float32"), 30, 200, 300)
connect(ramp, 0, ramp_mat, 0)
draw_targets += [ramp, ramp_mat, tex_a]     # the bench also bangs the jit.gl.texture each frame (t b b -> tex1)
connect(ramp_mat, 0, tex_a, 0)

trig = simple("newobj", "metro 250 @active 1", 700, 120, 140, nin=2, nout=1, outtype=["bang"])
getcell = simple("message", "getcell 32 0", 700, 150, 100)
connect(trig, 0, getcell, 0)

cases = [("1.3", "u = 1.3"), ("-0.2", "u = -0.2"), ("1.0", "u = exactly 1.0")]
for col, (path, label_path) in enumerate((("A", "Path A (bench-like)"), ("B", "Path B (shipped-like)"))):
    x0 = 30 + col * 460
    simple("comment", label_path, x0, 250, 300)
    for row, (u, label) in enumerate(cases):
        y = 280 + row * 110
        name = f"bm_p{path}{row + 1}"
        p = pix(name, f"out1 = sample(in1, vec({u}, norm.y, 0.0));\n", x0, y)
        draw_targets.append(p)
        if path == "A":
            connect(tex_a, 0, p, 0)
        else:
            connect(ramp, 0, p, 0)
        m = add(named(MAT, f"jit.matrix bm_out_{path}{row + 1} 4 float32 64 1 @adapt 1"), x0, y + 30, 330)
        connect(p, 0, m, 0)
        connect(getcell, 0, m, 0)
        pre = simple("newobj", "prepend set", x0, y + 58, 110)
        shown = simple("message", f"{label}: (waiting)", x0 + 120, y + 58, 300)
        connect(m, 1, pre, 0)
        connect(pre, 0, shown, 0)

for t in draw_targets:
    connect(world, 1, t, 0)          # the per-frame draw bang drives the whole chain

patch = {"patcher": {"fileversion": 1, "appversion": copy.deepcopy(PIX["patcher"]["appversion"]),
                     "classnamespace": "box", "rect": [60.0, 80.0, 980.0, 640.0],
                     "boxes": boxes, "lines": lines}}

# -- structural checks: unique ids, every line endpoint exists and is within the box's in/outlet counts
ids = {b["box"]["id"]: b["box"] for b in boxes}
assert len(ids) == len(boxes), "duplicate ids"
for l in lines:
    s, d = l["patchline"]["source"], l["patchline"]["destination"]
    assert s[0] in ids and d[0] in ids, l
    assert s[1] < ids[s[0]]["numoutlets"], ("outlet out of range", s, ids[s[0]].get("text"))
    assert d[1] < ids[d[0]]["numinlets"], ("inlet out of range", d, ids[d[0]].get("text"))

OUT.write_text(json.dumps(patch, indent="\t"))
print(f"wrote {OUT.relative_to(ROOT)}: {len(boxes)} boxes, {len(lines)} lines")
