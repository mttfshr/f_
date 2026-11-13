"""Builds package/patchers/f_util_vary.maxpat (T002). A hand-built utility, so it is out_of_scope for the definition.py ratchet
(tests/build/drift_baseline.json); this script is the source, and a hand edit in Max is to be written back here.

Layout (presentation 340 x 200): roll + seed, a strip of four dials (amount, chance, wobble, slew), four knob dials (assigned by `knob` lines in the
table), a multislider of live row positions with a label comment, and the table as ONE message box (comma-separated lines; click to apply,
double-click in an unlocked patch to edit). js = f_util_vary.js. Inlet 0 bases, inlet 1 settings; four destination outlets.

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
     "mode": 0, "numinlets": 1, "numoutlets": 0, "patching_rect": [400, 20, 340, 200], "presentation": 1, "presentation_rect": [0, 0, 340, 200], "proportion": 0.5})
# the library's title bar: two type dots (takes / outputs: neither, so dim gray) and the module name at x 10.5 (tests/build/test_generate_menu.py)
for dot_id, y, hint in (("obj-19f", 5.0, "Takes: no vecfield or tensor"), ("obj-19g", 12.0, "Outputs: no vecfield or tensor")):
    add({"id": dot_id, "maxclass": "panel", "background": 0, "bgcolor": [0.28, 0.28, 0.28, 1.0], "border": 0, "mode": 0, "hint": hint, "numinlets": 1, "numoutlets": 0,
         "patching_rect": [400, 250 + y, 5.0, 5.0], "presentation": 1, "presentation_rect": [4.0, y, 5.0, 5.0], "rounded": 6})
add({"id": "title", "maxclass": "comment", "numinlets": 1, "numoutlets": 0, "patching_rect": [400, 20, 100, 21], "text": "f_util_vary", "fontname": FONT, "fontsize": 12.0,
     "presentation": 1, "presentation_rect": [10.5, 0.0, 92.0, 21.0]})
com("hint", "bases in the left inlet, settings in the right; 4 outlets", [400, 40, 300, 20], [104, 3, 232, 16], 8.0)
msg("roll", "roll", [20, 120, 40, 22], [8, 24, 40, 18])
obj("seedn", "number", [70, 120, 50, 22], 1, 2, ["", "bang"], presentation=1, presentation_rect=[54, 24, 44, 18], fontname=FONT, fontsize=9.0)
com("seedl", "seed", [130, 120, 40, 20], [100, 25, 34, 16], 8.0)
for k, (name, lo, hi, init, unit) in enumerate([("amount", 0.0, 2.0, 1.0, 1), ("chance", 0.0, 1.0, 1.0, 1), ("wobble", 0.0, 1.0, 1.0, 1), ("slew", 0.0, 2000.0, 0.0, 2)]):
    x = 8 + 50 * k
    dial("d_" + name, name, [20 + 70 * k, 160, 50, 60], [x, 46, 46, 58], lo, hi, init, unit)
    obj("p_" + name, "prepend " + name, [20 + 70 * k, 230, 70, 22], 1, 1)
    ln("d_" + name, 0, "p_" + name, 0); ln("p_" + name, 0, "js", 1)
for k in range(4):
    x = 8 + 50 * k
    dial(f"d_k{k+1}", f"k{k+1}", [20 + 70 * k, 270, 50, 60], [x, 108, 46, 58], 0.0, 1.0, 0.5)
    obj(f"p_k{k+1}", f"prepend k {k+1}", [20 + 70 * k, 340, 80, 22], 1, 1)
    ln(f"d_k{k+1}", 0, f"p_k{k+1}", 0); ln(f"p_k{k+1}", 0, "js", 1)
add({"id": "mon", "maxclass": "multislider", "numinlets": 1, "numoutlets": 2, "outlettype": ["", ""], "patching_rect": [400, 80, 124, 100], "size": 16, "setminmax": [0.0, 1.0],
     "ignoreclick": 1, "contdata": 1, "peakcolor": [0.8, 0.8, 0.8, 1.0], "slidercolor": [0.35, 0.8, 0.8, 1.0], "bgcolor": [0.05, 0.05, 0.05, 1.0],
     "presentation": 1, "presentation_rect": [208, 24, 124, 100]})
com("labels", "(no rows)", [400, 190, 124, 40], [208, 126, 124, 40], 8.0)
TABLE = "clear, refresh"
msg("table", TABLE, [20, 400, 330, 22], [8, 172, 324, 22])
com("tablel", "table (one message box: click to apply; edit it in an unlocked patch). Lines: param, group, row, knob; see the helpfile.", [20, 424, 600, 20])

# ---- plumbing (not on the surface) ----
add({"id": "in0", "maxclass": "inlet", "numinlets": 0, "numoutlets": 1, "outlettype": [""], "patching_rect": [20, 20, 30, 30], "comment": "bases: <param> <value>"})
add({"id": "in1", "maxclass": "inlet", "numinlets": 0, "numoutlets": 1, "outlettype": [""], "patching_rect": [220, 20, 30, 30], "comment": "settings and table lines"})
obj("js", "js f_util_vary.js", [20, 70, 230, 22], 2, 6)
ln("in0", 0, "js", 0); ln("in1", 0, "js", 1)
for k in range(4):
    add({"id": f"out{k+1}", "maxclass": "outlet", "numinlets": 1, "numoutlets": 0, "patching_rect": [20 + 60 * k, 500, 30, 30], "comment": f"destination {k+1}"})
    ln("js", k, f"out{k+1}", 0)
ln("js", 4, "mon", 0); ln("js", 5, "labels", 0)
ln("roll", 0, "js", 1)
obj("pseed", "prepend seed", [70, 150, 80, 22], 1, 1); ln("seedn", 0, "pseed", 0); ln("pseed", 0, "js", 1)
obj("draw", "r draw", [270, 120, 60, 22], 0, 1); msg("tick", "tick", [270, 150, 40, 22]); ln("draw", 0, "tick", 0); ln("tick", 0, "js", 1)
obj("ld", "loadbang", [20, 370, 60, 22], 1, 1, ["bang"]); ln("ld", 0, "table", 0)
ln("table", 0, "js", 1)

patcher = {"fileversion": 1, "appversion": {"major": 9, "minor": 1, "revision": 4, "architecture": "x64", "modernui": 1}, "classnamespace": "box",
           "rect": [100.0, 100.0, 760.0, 600.0], "openinpresentation": 1, "boxes": boxes, "lines": lines, "autosave": 0}
ids = [b["box"]["id"] for b in boxes]
assert len(ids) == len(set(ids)), "duplicate ids"
for l in lines:
    for e in (l["patchline"]["source"][0], l["patchline"]["destination"][0]):
        assert e in ids, e
OUT.write_text(json.dumps({"patcher": patcher}, indent="\t"))
print("wrote", OUT, len(ids), "boxes", len(lines), "cords")
