"""
SUPERSEDED 2026-10-07: Matt hand-edited ~/Vsynth/patterns/scatter_look/scatter_look.maxpat in Max (his own
layout; `gswitch` UI selectors in place of the gate selectors below; the f_caustic source cord and the dim
cords to the tone stage are gone). DO NOT RUN THIS: it overwrites his patch. Change his file with a surgical
edit instead (and only while it is closed in Max). Kept as the record of how the first version was built.

build_scatter_look.py -- generate a scratch patch to LOOK at the GPU-scatter caustic (the f_caustic
"sheets" mode, ideas/optics_map.md) on real Vsynth sources. Nothing here is shipped.

  python3 scratch/build_scatter_look.py

writes ~/Vsynth/patterns/scatter_look/{scatter_look.maxpat, spike_scatter.maxpat, spike_scatter.jxs}
(the two spike files are copied from tests/bench/, so the bpatcher and its shader are found next to the
patch). Regenerating overwrites the patch: hand edits in Max are lost.

Chain:  light source (Vsynth video | waveform gen)  --------------------------> scatter inlet 0
        glass: vs_noise_3 | vs_chemical_osc -> vs_filter_lp2x -> f_vf_fieldmap -> scatter inlet 1
        scatter (float32 capture, square) -> tone map + bilinear upscale to the render size
        selectable outlet: scatter | f_caustic (soft, same field and source) | the raw field

Only ONE spike_scatter bpatcher can exist per Max session (fixed @names): close the test bench first.
"""
import json
import shutil
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
BENCH = HERE.parent / "tests" / "bench"
sys.path.insert(0, str(BENCH))
from patchbuild import APPVERSION, Patch, patcher_dict   # noqa: E402

OUT_DIR = Path.home() / "Vsynth" / "patterns" / "scatter_look"
OUT = OUT_DIR / "scatter_look.maxpat"

p = Patch()
obj, wire, comment, boxes = p.obj, p.wire, p.comment, p.boxes


def bp(oid, name, rect, nin, nout, varname=None):
    boxes.append({"box": {
        "id": oid, "maxclass": "bpatcher", "name": name, "numinlets": nin, "numoutlets": nout,
        "patching_rect": [float(v) for v in rect], "bgmode": 1, "border": 1, "clickthrough": 0,
        "enablehscroll": 0, "enablevscroll": 0, "lockeddragscroll": 0, "lockedsize": 0,
        "offset": [0.0, 0.0], "viewvisibility": 1,
        **({"outlettype": ["jit_gl_texture"] * nout} if nout else {}),
        "varname": varname or oid}})


def message(oid, text, rect):
    boxes.append({"box": {"id": oid, "maxclass": "message", "text": text, "numinlets": 2, "numoutlets": 1,
                          "outlettype": [""], "patching_rect": [float(v) for v in rect]}})


def flonum(oid, rect):
    boxes.append({"box": {"id": oid, "maxclass": "flonum", "numinlets": 1, "numoutlets": 2,
                          "outlettype": ["", "bang"], "parameter_enable": 0, "minimum": 0.0,
                          "patching_rect": [float(v) for v in rect]}})


def umenu(oid, items, rect):
    flat = []
    for i, it in enumerate(items):
        flat += ([","] if i else []) + [it]
    boxes.append({"box": {"id": oid, "maxclass": "umenu", "items": flat, "numinlets": 1, "numoutlets": 3,
                          "outlettype": ["int", "", ""], "parameter_enable": 0, "pattrmode": 1,
                          "patching_rect": [float(v) for v in rect], "varname": oid}})


def selector(prefix, items, x, y, sources):
    """A texture input selector built the way f_texrouter routes textures: one `gate 1` per input, each
    opened by `== n` on the umenu index (no `switch`). The first input starts open, matching the umenu's
    first item. sources = box ids whose outlet 0 feeds gate n's data inlet. Returns the gate ids: connect
    each of them to every destination (cords fan in, so no merge object is needed)."""
    umenu(f"{prefix}sel", items, [x, y, 150, 22])
    gates = []
    for n, src in enumerate(sources):
        obj(f"{prefix}eq{n}", f"== {n}", 2, 1, [x + 90 * n, y + 28, 40, 22], ["int"])
        obj(f"{prefix}g{n}", f"gate 1 {1 if n == 0 else 0}", 2, 1, [x + 90 * n, y + 56, 70, 22])
        wire(f"{prefix}sel", 0, f"{prefix}eq{n}", 0)
        wire(f"{prefix}eq{n}", 0, f"{prefix}g{n}", 0)
        wire(src, 0, f"{prefix}g{n}", 1)
        gates.append(f"{prefix}g{n}")
    return gates


def connect(gates, dst, di):
    for g in gates:
        wire(g, 0, dst, di)


def pix_box(oid, code, rect, attrs):
    """An inline jit.gl.pix with a one-codebox gen patcher (the structure build_patcher.py writes)."""
    def sub_box(i, **kw):
        kw.update({"id": f"gen-obj-{i}", "patching_rect": [30.0, 30.0 + 60 * i, 200.0, 22.0]})
        return {"box": kw}
    sub = {"fileversion": 1, "appversion": dict(APPVERSION), "classnamespace": "jit.gen",
           "rect": [100.0, 100.0, 500.0, 300.0],
           "boxes": [sub_box(1, maxclass="newobj", numinlets=0, numoutlets=1, outlettype=[""], text="in 1"),
                     sub_box(2, maxclass="codebox", code=code, numinlets=1, numoutlets=1, outlettype=[""],
                             fontname="<Monospaced>", fontsize=12.0),
                     sub_box(3, maxclass="newobj", numinlets=1, numoutlets=0, text="out 1")],
           "lines": [{"patchline": {"source": ["gen-obj-1", 0], "destination": ["gen-obj-2", 0]}},
                     {"patchline": {"source": ["gen-obj-2", 0], "destination": ["gen-obj-3", 0]}}]}
    boxes.append({"box": {"id": oid, "maxclass": "newobj", "text": f"jit.gl.pix vsynth {attrs}",
                          "numinlets": 1, "numoutlets": 2, "outlettype": ["jit_gl_texture", ""],
                          "patching_rect": [float(v) for v in rect], "patcher": sub}})


# ---------------------------------------------------------------- title and render context
comment("title", "scatter_look -- generated by scratch/build_scatter_look.py (regenerating overwrites). "
                 "Looks at the GPU-scatter caustic on real sources; see ideas/optics_map.md.", [25, 8, 900, 18])
bp("render", "vs_render.maxpat", [25, 60, 97, 147], 1, 1)
comment("t-dim", "render size", [135, 40, 100, 18])
for i, (w, h) in enumerate(((1280, 720), (1920, 1080), (3840, 2160))):
    message(f"m-{h}", f"dim {w} {h}", [135, 60 + 30 * i, 100, 22])
    wire(f"m-{h}", 0, "render", 0)

# ---------------------------------------------------------------- light source
bp("wfg", "vs_wfg_3.maxpat", [250, 60, 178, 132], 1, 1)
bp("src", "vs_sources_main.maxpat", [450, 30, 542, 442], 1, 1, "vs_sources")
comment("t-src", "light source: the movie tab gives real video; the waveform gen gives clean test patterns",
        [250, 40, 200, 18])
sgates = selector("s", ["Video sources", "Waveform gen"], 450, 490, ["src", "wfg"])

# ---------------------------------------------------------------- glass: height -> smooth -> field
comment("t-glass", "GLASS: a smooth height field -> f_vf_fieldmap (its gradient is the glass)", [25, 480, 420, 18])
bp("noise", "vs_noise_3.maxpat", [25, 505, 126, 61], 1, 1)
bp("chem", "vs_chemical_osc.maxpat", [170, 505, 266, 75], 1, 1)
ggates = selector("g", ["Noise", "Chemical osc"], 25, 595, ["noise", "chem"])
bp("lp", "vs_filter_lp2x.maxpat", [25, 685, 62, 75], 1, 1)
bp("fmap", "f_vf_fieldmap.maxpat", [110, 685, 150, 88], 1, 1)
connect(ggates, "lp", 0)
wire("lp", 0, "fmap", 0)

# ---------------------------------------------------------------- the scatter and its reference
bp("scatter", "spike_scatter.maxpat", [300, 700, 160, 40], 2, 1)
bp("caustic", "f_caustic.maxpat", [300, 780, 227, 100], 2, 1)
connect(sgates, "scatter", 0)
wire("fmap", 0, "scatter", 1)
connect(sgates, "caustic", 0)
wire("fmap", 0, "caustic", 1)

# tone map + bilinear upscale to the render size (the capture is a square float32 texture, HDR)
TONE = ("tm(v, ex) {\n"          # function definitions must PRECEDE all statements; a Param is a statement
        "\tt = v / (1.0 + v);\n"
        "\treturn pow(t, ex);\n"
        "}\n"
        "Param lev(1.0);\n"
        "Param expo(0.7);\n"
        "r = tm(sample(in1, norm).x * lev, expo);\n"       # components read INLINE on sample(): a stored
        "g = tm(sample(in1, norm).y * lev, expo);\n"       # variable's .x silently outputs black
        "b = tm(sample(in1, norm).z * lev, expo);\n"       # (skills/jit-gen-codebox, Silent Failures)
        "out1 = vec(r, g, b, 1.0);\n")
pix_box("tone", TONE, [560, 700, 400, 22], "@type float32 @adapt 0 @dim 1920 1080")
wire("scatter", 0, "tone", 0)
for h in (720, 1080, 2160):
    wire(f"m-{h}", 0, "tone", 0)

# ---------------------------------------------------------------- output selector and output
ogates = selector("o", ["Scatter (new)", "f_caustic (soft, reference)", "Field (raw)"], 700, 780,
                  ["tone", "caustic", "fmap"])
bp("out", "vs_output.maxpat", [700, 880, 157, 22], 1, 0, "vs_output")
connect(ogates, "out", 0)

# ---------------------------------------------------------------- scatter controls
comment("t-pre", "SCATTER SETTINGS -- click one (capture size, points per capture pixel); d and fy below",
        [620, 480, 520, 18])
presets = [("512^2, 2 pts/px  <- MVP default", 512, 724),
           ("768^2, 2 pts/px", 768, 1086),
           ("1024^2, 4 pts/px (reference-like)", 1024, 2048),
           ("512^2, 1 pt/px (shows the moire)", 512, 512),
           ("256^2, 2 pts/px (coarse)", 256, 362),
           ("1024^2, 1 pt/px", 1024, 1024)]
for i, (label, r, n) in enumerate(presets):
    w = (r / n) ** 2
    message(f"pre{i}", f"r {r}, psize 2, snap 1, h 1, jit 0, taps 1, latn {n}, weight {w:.4f}, n {n}",
            [620, 505 + 26 * i, 400, 22])
    comment(f"pre{i}c", label, [1030, 507 + 26 * i, 260, 18])
    wire(f"pre{i}", 0, "scatter", 0)

comment("t-d", "d = propagation distance (UV per unit field). Sweep 0.02 to 0.5: sheets fold over at larger d",
        [620, 670, 560, 18])
flonum("dflo", [620, 692, 70, 22])
message("dmsg", "d $1", [700, 692, 50, 22])
wire("dflo", 0, "dmsg", 0)
wire("dmsg", 0, "scatter", 0)
message("fy-", "fy -1", [770, 692, 50, 22])
message("fy+", "fy 1", [830, 692, 50, 22])
comment("t-fy", "fy: flip the field's Y if the scatter looks like a mirror image of f_caustic at small d",
        [890, 694, 420, 18])
wire("fy-", 0, "scatter", 0)
wire("fy+", 0, "scatter", 0)

comment("t-tone", "display: lev = brightness before the tone curve, expo = output exponent (lower = brighter darks)",
        [620, 730, 560, 18])
flonum("levflo", [620, 752, 70, 22])
message("levmsg", "param lev $1", [700, 752, 90, 22])
flonum("expflo", [810, 752, 70, 22])
message("expmsg", "param expo $1", [890, 752, 100, 22])
wire("levflo", 0, "levmsg", 0)
wire("levmsg", 0, "tone", 0)
wire("expflo", 0, "expmsg", 0)
wire("expmsg", 0, "tone", 0)

# defaults on load: values into the numboxes (which then send), then the first preset and fy after a delay
obj("lb", "loadbang", 0, 1, [1010, 640, 60, 22], ["bang"])
message("init-d", "0.15", [1080, 640, 40, 22])
message("init-lev", "1.", [1130, 640, 30, 22])
message("init-exp", "0.7", [1170, 640, 30, 22])
obj("lbdel", "delay 1500", 2, 1, [1010, 670, 70, 22], ["bang"])
wire("lb", 0, "init-d", 0)
wire("lb", 0, "init-lev", 0)
wire("lb", 0, "init-exp", 0)
wire("lb", 0, "lbdel", 0)
wire("init-d", 0, "dflo", 0)
wire("init-lev", 0, "levflo", 0)
wire("init-exp", 0, "expflo", 0)
wire("lbdel", 0, "pre0", 0)
wire("lbdel", 0, "fy-", 0)

comment("t-how", "HOW TO LOOK: (1) pick a glass and a light source; (2) output = Scatter; (3) sweep d; (4) click the "
                 "512^2 / 2 pts-per-px preset against the 1024^2 / 4 one; (5) flip the output to f_caustic to compare. "
                 "Close the test bench first: the spike bpatcher has fixed @names.", [25, 910, 1100, 18])

# ---------------------------------------------------------------- write
OUT_DIR.mkdir(parents=True, exist_ok=True)
for f in ("spike_scatter.maxpat", "spike_scatter.jxs"):
    shutil.copy2(BENCH / f, OUT_DIR / f)
with open(OUT, "w") as fh:
    json.dump(patcher_dict(boxes, p.lines, rect=(60.0, 80.0, 1320.0, 950.0)), fh, indent=2)
print(f"wrote {OUT} ({len(boxes)} boxes, {len(p.lines)} lines) and copied the spike bpatcher + shader beside it")
