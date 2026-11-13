"""Builds package/patchers/f_util_vary.maxpat (T002). A hand-built utility, so it is out_of_scope for the definition.py ratchet
(tests/build/drift_baseline.json); this script is the source, and a hand edit in Max is to be written back here.

Layout (presentation 372 x 488): roll + seed, a strip of four dials (amount, chance, wobble, slew), four group-correlation dials (g1-g4), a multislider of live
row positions with a label comment, and the table as rows of controls: the + button makes a row (the engine scripts a f_util_vary_row.maxpat bpatcher, built by
build_vary_row.py), each row has out / param / lo / hi / amount / chance / wobble / trim / mode / sign / group / delete. The engine owns the table and a pattr keeps it;
it saves only when f_util_vary is placed as an EMBEDDED bpatcher (Matt's scratch test, 2026-11-13). js = f_util_vary.js. Inlet 0 bases, inlet 1 settings; four destination outlets.

    python3 src/f_util_vary/build_vary_patcher.py
"""
import json
from pathlib import Path

OUT = Path(__file__).resolve().parents[2] / "package" / "patchers" / "f_util_vary.maxpat"
boxes, lines = [], []
FONT = "Ableton Sans Light"
LIGHT = [0.8, 0.8, 0.8, 1.0]


def add(b): boxes.append({"box": b})


def pres(rect): return {"presentation": 1, "presentation_rect": rect}


def obj(i, text, rect, nin, nout, types=None, **kw):
    b = {"id": i, "maxclass": "newobj", "numinlets": nin, "numoutlets": nout, "outlettype": types or [""] * nout, "patching_rect": rect, "text": text}
    b.update(kw); add(b)


def msg(i, text, rect, prect=None):
    b = {"id": i, "maxclass": "message", "numinlets": 2, "numoutlets": 1, "outlettype": [""], "patching_rect": rect, "text": text, "fontname": FONT, "fontsize": 9.0}
    if prect: b.update(pres(prect))
    add(b)


def com(i, text, rect, prect=None, size=9.0):
    b = {"id": i, "maxclass": "comment", "numinlets": 1, "numoutlets": 0, "patching_rect": rect, "text": text, "fontname": FONT, "fontsize": size, "textcolor": LIGHT}
    if prect: b.update(pres(prect))
    add(b)


def dial(i, name, rect, prect, lo, hi, init, unit=1):
    add({"id": i, "maxclass": "live.dial", "fontname": FONT, "numinlets": 1, "numoutlets": 2, "outlettype": ["", "float"], "parameter_enable": 1,
         "patching_rect": rect, "presentation": 1, "presentation_rect": prect,
         "saved_attribute_attributes": {"valueof": {"parameter_initial": [init], "parameter_initial_enable": 1, "parameter_linknames": 1, "parameter_longname": name,
                                                    "parameter_mmax": hi, "parameter_mmin": lo, "parameter_modmode": 3, "parameter_shortname": name,
                                                    "parameter_type": 0, "parameter_unitstyle": unit}},
         "showname": 1, "varname": name})


def ln(a, ao, b, bi): lines.append({"patchline": {"source": [a, ao], "destination": [b, bi]}})


# ---- presentation surface ----
add({"id": "bg", "maxclass": "panel", "angle": 270.0, "background": 1, "bgcolor": [0.0, 0.0, 0.0, 1.0], "border": 1, "bordercolor": [0.0, 0.03529411765, 0.2274509804, 1.0],
     "mode": 0, "numinlets": 1, "numoutlets": 0, "patching_rect": [400, 20, 372, 488], "presentation": 1, "presentation_rect": [0, 0, 372, 488], "proportion": 0.5})
# the library's title bar: two type dots (takes / outputs: neither, so dim gray) and the module name at x 10.5 (tests/build/test_generate_menu.py)
for dot_id, y, hint in (("obj-19f", 5.0, "Takes: no vecfield or tensor"), ("obj-19g", 12.0, "Outputs: no vecfield or tensor")):
    add({"id": dot_id, "maxclass": "panel", "background": 0, "bgcolor": [0.28, 0.28, 0.28, 1.0], "border": 0, "mode": 0, "hint": hint, "numinlets": 1, "numoutlets": 0,
         "patching_rect": [400, 250 + y, 5.0, 5.0], "presentation": 1, "presentation_rect": [4.0, y, 5.0, 5.0], "rounded": 6})
add({"id": "title", "maxclass": "comment", "numinlets": 1, "numoutlets": 0, "patching_rect": [400, 20, 100, 21], "text": "f_util_vary", "fontname": FONT, "fontsize": 12.0,
     "presentation": 1, "presentation_rect": [10.5, 0.0, 92.0, 21.0]})
com("hint", "bases in the left inlet, settings in the right; 4 outlets", [400, 40, 300, 20], [104, 3, 264, 16], 8.0)
msg("roll", "roll", [20, 120, 40, 22], [8, 24, 40, 18])
obj("seedn", "number", [70, 120, 50, 22], 1, 2, ["", "bang"], presentation=1, presentation_rect=[54, 24, 44, 18], fontname=FONT, fontsize=9.0)
com("seedl", "seed", [130, 120, 40, 20], [100, 25, 34, 16], 8.0)
for k, (name, lo, hi, init, unit) in enumerate([("amount", 0.0, 2.0, 1.0, 1), ("chance", 0.0, 1.0, 1.0, 1), ("wobble", 0.0, 1.0, 1.0, 1), ("slew", 0.0, 2000.0, 0.0, 2)]):
    x = 8 + 50 * k
    dial("d_" + name, name, [20 + 70 * k, 160, 50, 60], [x, 46, 46, 58], lo, hi, init, unit)
    obj("p_" + name, "prepend " + name, [20 + 70 * k, 230, 70, 22], 1, 1)
    ln("d_" + name, 0, "p_" + name, 0); ln("p_" + name, 0, "js", 1)
obj("rg", "route g1 g2 g3 g4", [20, 380, 120, 22], 1, 5); ln("js", 9, "rg", 0)
for k in range(4):
    x = 8 + 50 * k
    dial(f"d_g{k+1}", f"g{k+1}", [20 + 70 * k, 270, 50, 60], [x, 108, 46, 58], 0.0, 1.0, 0.5)
    obj(f"p_g{k+1}", f"prepend group g{k+1}", [20 + 70 * k, 340, 100, 22], 1, 1); ln(f"d_g{k+1}", 0, f"p_g{k+1}", 0); ln(f"p_g{k+1}", 0, "js", 1)
    obj(f"s_g{k+1}", "prepend set", [150 + 70 * k, 410, 70, 22], 1, 1); ln("rg", k, f"s_g{k+1}", 0); ln(f"s_g{k+1}", 0, f"d_g{k+1}", 0)
add({"id": "mon", "maxclass": "multislider", "numinlets": 1, "numoutlets": 2, "outlettype": ["", ""], "patching_rect": [400, 80, 124, 100], "size": 16, "setminmax": [0.0, 1.0],
     "ignoreclick": 1, "contdata": 1, "peakcolor": [0.8, 0.8, 0.8, 1.0], "slidercolor": [0.35, 0.8, 0.8, 1.0], "bgcolor": [0.05, 0.05, 0.05, 1.0],
     "presentation": 1, "presentation_rect": [208, 24, 160, 100]})
com("labels", "(no rows)", [400, 190, 124, 40], [208, 126, 160, 40], 8.0)
# ---- the table: a header, the + button, and (below, made at runtime by the engine) one vary_row bpatcher per row ----
HEAD = [("out", 2), ("param", 26), ("lo", 93), ("hi", 133), ("amt", 173), ("chn", 195), ("wob", 217), ("trim", 239), ("mode", 262), ("sign", 279), ("grp", 319)]
for name, x in HEAD:
    com("h_" + name, name, [400 + x, 400, 40, 16], [x, 170, 40, 14], 7.0)
add({"id": "plus", "maxclass": "textbutton", "text": "+", "mode": 0, "numinlets": 1, "numoutlets": 3, "outlettype": ["", "", "int"], "patching_rect": [400, 420, 20, 20],
     "presentation": 1, "presentation_rect": [343, 168, 16, 16], "fontname": FONT, "fontsize": 11.0})
msg("addm", "add", [430, 420, 40, 22]); ln("plus", 0, "addm", 0); ln("addm", 0, "js", 1)
obj("ld2", "loadbang", [20, 580, 60, 22], 1, 1, ["bang"]); obj("dly", "delay 300", [90, 580, 60, 22], 1, 1)
msg("rf", "refresh", [160, 580, 60, 22]); ln("ld2", 0, "dly", 0); ln("dly", 0, "rf", 0); ln("rf", 0, "js", 1)
obj("tp", "thispatcher", [260, 580, 80, 22], 1, 2, ["", ""])
# the row UIs answer on `send #0_cell` (#0 is unique to this placed instance); the token tells the engine that name
obj("rcell", "r #0_cell", [350, 580, 90, 22], 0, 1); ln("rcell", 0, "js", 1)
msg("tokm", "token #0", [450, 580, 70, 22]); ln("ld2", 0, "tokm", 0); ln("tokm", 0, "js", 1)
# the table is kept by the engine; a pattr stores it (one `restore ...` list) and echoes it back at load
obj("pt", "pattr vary_table @autorestore 1", [20, 540, 200, 22], 1, 3, ["", "", ""]); ln("js", 6, "pt", 0); ln("pt", 0, "js", 1)

# ---- plumbing (not on the surface) ----
add({"id": "in0", "maxclass": "inlet", "numinlets": 0, "numoutlets": 1, "outlettype": [""], "patching_rect": [20, 20, 30, 30], "comment": "bases: <param> <value>"})
add({"id": "in1", "maxclass": "inlet", "numinlets": 0, "numoutlets": 1, "outlettype": [""], "patching_rect": [220, 20, 30, 30], "comment": "settings and table lines"})
obj("js", "js f_util_vary.js", [20, 70, 230, 22], 2, 10, varname="eng"); ln("js", 7, "tp", 0)
ln("in0", 0, "js", 0); ln("in1", 0, "js", 1)
for k in range(4):
    add({"id": f"out{k+1}", "maxclass": "outlet", "numinlets": 1, "numoutlets": 0, "patching_rect": [20 + 60 * k, 500, 30, 30], "comment": f"destination {k+1}"})
    ln("js", k, f"out{k+1}", 0)
ln("js", 4, "mon", 0); ln("js", 5, "labels", 0)
ln("roll", 0, "js", 1)
obj("pseed", "prepend seed", [70, 150, 80, 22], 1, 1); ln("seedn", 0, "pseed", 0); ln("pseed", 0, "js", 1)
obj("draw", "r draw", [270, 120, 60, 22], 0, 1); msg("tick", "tick", [270, 150, 40, 22]); ln("draw", 0, "tick", 0); ln("tick", 0, "js", 1)

patcher = {"fileversion": 1, "appversion": {"major": 9, "minor": 1, "revision": 4, "architecture": "x64", "modernui": 1}, "classnamespace": "box",
           "rect": [100.0, 100.0, 900.0, 760.0], "openinpresentation": 1, "boxes": boxes, "lines": lines, "autosave": 0}
ids = [b["box"]["id"] for b in boxes]
assert len(ids) == len(set(ids)), "duplicate ids"
for l in lines:
    for e in (l["patchline"]["source"][0], l["patchline"]["destination"][0]):
        assert e in ids, e
OUT.write_text(json.dumps({"patcher": patcher}, indent="\t"))
print("wrote", OUT, len(ids), "boxes", len(lines), "cords")
