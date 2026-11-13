"""Builds package/patchers/f_util_vary_row.maxpat: ONE row of f_util_vary's table (368 x 20), made at runtime by the engine (`script newobject bpatcher @name
f_util_vary_row.maxpat @args <i> <token>`), one per row. Controls: out, param (a menu of the names seen), lo, hi, four dials (amount, chance, wobble, trim), mode, sign, group, delete.
In:  `<i> <field> <value>` from the engine (route #1 keeps the ones for this row; `set` so nothing is sent back).
Out: `cell <i> <field> <value>` when a control is touched, sent on `s #2_cell` (args: row number, instance token) and received by the f_util_vary patcher. Hand-built, like f_util_vary.

    python3 src/f_util_vary/build_vary_row.py
"""
import json
from pathlib import Path

OUT = Path(__file__).resolve().parents[2] / "package" / "patchers" / "f_util_vary_row.maxpat"
boxes, lines = [], []
FONT, FS = "Ableton Sans Light", 9.0


def add(b): boxes.append({"box": b})
def ln(a, ao, b, bi): lines.append({"patchline": {"source": [a, ao], "destination": [b, bi]}})


def obj(i, text, rect, nin, nout, types=None):
    add({"id": i, "maxclass": "newobj", "numinlets": nin, "numoutlets": nout, "outlettype": types or [""] * nout, "patching_rect": rect, "text": text, "fontname": FONT, "fontsize": FS})


def msg(i, text, rect):
    add({"id": i, "maxclass": "message", "numinlets": 2, "numoutlets": 1, "outlettype": [""], "patching_rect": rect, "text": text, "fontname": FONT, "fontsize": FS})


def ui(i, cls, prect, nout, types, **kw):
    b = {"id": i, "maxclass": cls, "numinlets": 1, "numoutlets": nout, "outlettype": types, "patching_rect": [prect[0], 120, prect[2], prect[3]], "presentation": 1,
         "presentation_rect": prect, "fontname": FONT, "fontsize": FS}
    b.update(kw); add(b)


# ---- controls (presentation) ----
ui("c_out", "number", [2, 2, 22, 16], 2, ["", "bang"], minimum=1, maximum=4)
ui("c_param", "umenu", [26, 2, 64, 16], 3, ["int", "", ""], items=[], arrow=0)
ui("c_lo", "flonum", [93, 2, 38, 16], 2, ["", "bang"])
ui("c_hi", "flonum", [133, 2, 38, 16], 2, ["", "bang"])
DIALS = [("amt", 173, 0.0, 100.0), ("chance", 195, 0.0, 100.0), ("wob", 217, 0.0, 100.0), ("trim", 239, -100.0, 200.0)]
for f, x, lo, size in DIALS:
    ui("c_" + f, "dial", [x, 0, 20, 20], 1, ["float"], floatoutput=1, min=lo, size=size)
ui("c_mode", "toggle", [262, 3, 14, 14], 1, ["int"])
ui("c_sign", "umenu", [279, 2, 38, 16], 3, ["int", "", ""], items=["bi", ",", "up", ",", "down"], arrow=0)
ui("c_grp", "number", [319, 2, 22, 16], 2, ["", "bang"], minimum=0, maximum=4)
ui("c_del", "textbutton", [343, 2, 16, 16], 3, ["", "", "int"], text="-", mode=0)

# ---- in: engine -> controls ----
add({"id": "in", "maxclass": "inlet", "numinlets": 0, "numoutlets": 1, "outlettype": [""], "patching_rect": [20, 20, 30, 30], "comment": "<i> <field> <value>"})
obj("outl", "s #2_cell", [20, 440, 90, 22], 1, 0, [])
obj("r1", "route #1", [20, 60, 60, 22], 1, 2)
FIELDS = ["out", "param_idx", "names", "lo", "hi", "amt", "chance", "wob", "trim", "group", "mode", "sign"]
obj("r2", "route " + " ".join(FIELDS), [20, 90, 520, 22], 1, len(FIELDS) + 1)
ln("in", 0, "r1", 0); ln("r1", 0, "r2", 0)
target = {"out": "c_out", "param_idx": "c_param", "lo": "c_lo", "hi": "c_hi", "amt": "c_amt", "chance": "c_chance", "wob": "c_wob", "trim": "c_trim", "group": "c_grp"}
for k, f in enumerate(FIELDS):
    if f in target:
        obj("ps_" + f, "prepend set", [20 + 70 * k, 150, 70, 22], 1, 1); ln("r2", k, "ps_" + f, 0); ln("ps_" + f, 0, target[f], 0)
# the names list -> the param menu (clear, then append each name)
k = FIELDS.index("names")
obj("nt", "t l b", [20, 200, 50, 22], 1, 2); msg("nclr", "clear", [20, 230, 40, 22]); obj("nit", "zl iter 1", [80, 230, 60, 22], 2, 2); obj("nap", "prepend append", [80, 260, 90, 22], 1, 1)
ln("r2", k, "nt", 0); ln("nt", 1, "nclr", 0); ln("nclr", 0, "c_param", 0); ln("nt", 0, "nit", 0); ln("nit", 0, "nap", 0); ln("nap", 0, "c_param", 0)
# mode u / d -> the toggle; sign bi / up / down -> the sign menu
k = FIELDS.index("mode")
obj("sm", "sel u d", [200, 200, 60, 22], 1, 3); msg("sm0", "set 0", [200, 230, 40, 22]); msg("sm1", "set 1", [250, 230, 40, 22])
ln("r2", k, "sm", 0); ln("sm", 0, "sm0", 0); ln("sm", 1, "sm1", 0); ln("sm0", 0, "c_mode", 0); ln("sm1", 0, "c_mode", 0)
k = FIELDS.index("sign")
obj("ss", "sel bi up down", [320, 200, 90, 22], 1, 4)
for j in range(3):
    msg(f"ss{j}", f"set {j}", [320 + 45 * j, 230, 40, 22]); ln("ss", j, f"ss{j}", 0); ln(f"ss{j}", 0, "c_sign", 0)
ln("r2", k, "ss", 0)

# ---- out: controls -> engine ----
def cell(src, so, field, i):
    obj("pc_" + i, f"prepend cell #1 {field}", [20 + 80 * len(boxes) % 400, 330, 120, 22], 1, 1); ln(src, so, "pc_" + i, 0); ln("pc_" + i, 0, "outl", 0)


for f, src, so in [("out", "c_out", 0), ("param", "c_param", 1), ("lo", "c_lo", 0), ("hi", "c_hi", 0), ("amt", "c_amt", 0), ("chance", "c_chance", 0), ("wob", "c_wob", 0),
                   ("trim", "c_trim", 0), ("sign", "c_sign", 1), ("group", "c_grp", 0)]:
    cell(src, so, f, f)
obj("tm", "sel 0 1", [20, 360, 60, 22], 1, 3); msg("tm0", "cell #1 mode u", [20, 390, 100, 22]); msg("tm1", "cell #1 mode d", [130, 390, 100, 22])
ln("c_mode", 0, "tm", 0); ln("tm", 0, "tm0", 0); ln("tm", 1, "tm1", 0); ln("tm0", 0, "outl", 0); ln("tm1", 0, "outl", 0)
msg("dl", "cell #1 del 1", [240, 390, 100, 22]); ln("c_del", 0, "dl", 0); ln("dl", 0, "outl", 0)

patcher = {"fileversion": 1, "appversion": {"major": 9, "minor": 1, "revision": 4, "architecture": "x64", "modernui": 1}, "classnamespace": "box",
           "rect": [100.0, 100.0, 700.0, 460.0], "openinpresentation": 1, "bgcolor": [0.0, 0.0, 0.0, 1.0], "boxes": boxes, "lines": lines, "autosave": 0}
ids = [b["box"]["id"] for b in boxes]
assert len(ids) == len(set(ids)), "duplicate ids"
for l in lines:
    for e in (l["patchline"]["source"][0], l["patchline"]["destination"][0]):
        assert e in ids, e
OUT.write_text(json.dumps({"patcher": patcher}, indent="\t"))
print("wrote", OUT, len(ids), "boxes", len(lines), "cords")
