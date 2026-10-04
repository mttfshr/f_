"""Scratch: generate scratch/launch_tab_test.maxpat (T021 mechanism test, not the real generator).
Tests: native subpatcher tabs (showontab), awkward tab labels, textbutton -> loadunique -> pcontrol
from inside a subpatcher, presentation-only rows, a greyed (no-helpfile) row."""
import json, os

APP = {"major": 9, "minor": 1, "revision": 4, "architecture": "x64", "modernui": 1}
GREY = [0.55, 0.55, 0.55, 1.0]
HELP = "/Users/matt/Github/f_/package/help"

def tab_patcher(rows):
    boxes, lines = [], []
    boxes.append({"box": {"id": "obj-1", "maxclass": "newobj", "numinlets": 1, "numoutlets": 1,
                          "outlettype": [""], "patching_rect": [420.0, 20.0, 60.0, 22.0], "text": "pcontrol"}})
    n = 2
    for i, (name, desc) in enumerate(rows):
        y = 12 + 30 * i
        has_help = os.path.exists(f"{HELP}/{name}.maxhelp")
        if has_help:
            btn, msg = f"obj-{n}", f"obj-{n+1}"
            boxes.append({"box": {"id": btn, "maxclass": "textbutton", "numinlets": 1, "numoutlets": 3,
                                  "outlettype": ["", "", "int"], "parameter_enable": 0, "fontsize": 12.0,
                                  "patching_rect": [20.0, 20.0 + 60 * i, 150.0, 22.0], "text": name,
                                  "presentation": 1, "presentation_rect": [10.0, float(y), 160.0, 22.0]}})
            boxes.append({"box": {"id": msg, "maxclass": "message", "numinlets": 2, "numoutlets": 1,
                                  "outlettype": [""], "patching_rect": [20.0, 48.0 + 60 * i, 230.0, 22.0],
                                  "text": f"loadunique {name}.maxhelp"}})
            lines.append({"patchline": {"source": [btn, 0], "destination": [msg, 0]}})
            lines.append({"patchline": {"source": [msg, 0], "destination": ["obj-1", 0]}})
            n += 2
        else:
            boxes.append({"box": {"id": f"obj-{n}", "maxclass": "comment", "numinlets": 1, "numoutlets": 0,
                                  "patching_rect": [20.0, 20.0 + 60 * i, 150.0, 20.0], "text": name,
                                  "textcolor": GREY, "presentation": 1,
                                  "presentation_rect": [10.0, float(y + 2), 160.0, 20.0]}})
            n += 1
        boxes.append({"box": {"id": f"obj-{n}", "maxclass": "comment", "numinlets": 1, "numoutlets": 0,
                              "patching_rect": [260.0, 20.0 + 60 * i, 150.0, 20.0], "text": desc,
                              "textcolor": [0.1, 0.1, 0.1, 1.0] if has_help else GREY,
                              "presentation": 1, "presentation_rect": [180.0, float(y + 2), 520.0, 20.0]}})
        n += 1
    return {"fileversion": 1, "appversion": APP, "classnamespace": "box", "rect": [0.0, 26.0, 720.0, 140.0],
            "openinpresentation": 1, "gridsize": [15.0, 15.0], "showontab": 1, "boxes": boxes, "lines": lines}

TABS = [
    ("p Generators", "tab_gen", [("f_masonry", "Parametric masonry texture -- courses, bond, mortar, drift, color"),
                                 ("f_ngon", "WARN Unfinished. Regular N-gon generator / mask (greyed: no helpfile)")]),
    ('p "Generator / processor"', "tab_genproc", [("f_grain", "Stochastic grain field with per-grain displacement and luma gating")]),
    ("p Audio-domain", "tab_audio", [("f_a_ripple", "WARN Unfinished. De-correlating ripple stimulus (greyed: no helpfile)")]),
]
root_boxes = []
for i, (text, var, rows) in enumerate(TABS):
    root_boxes.append({"box": {"id": f"obj-{i+1}", "maxclass": "newobj", "numinlets": 0, "numoutlets": 0,
                               "patching_rect": [30.0 + 170 * i, 40.0, 150.0, 22.0], "text": text,
                               "varname": var, "patcher": tab_patcher(rows)}})
root = {"patcher": {"fileversion": 1, "appversion": APP, "classnamespace": "box", "rect": [100.0, 100.0, 720.0, 200.0],
                    "gridsize": [15.0, 15.0], "showrootpatcherontab": 0, "showontab": 0,
                    "boxes": root_boxes, "lines": []}}
out = "/Users/matt/Github/f_/scratch/launch_tab_test.maxpat"
json.dump(root, open(out, "w"), indent="\t", ensure_ascii=False)

# validation (maxpat-json-authoring checklist), every scope separately
def check(scope, label):
    ids = [b["box"]["id"] for b in scope["boxes"]]
    dup = {x for x in ids if ids.count(x) > 1}
    dangling = [e for l in scope.get("lines", []) for e in (l["patchline"]["source"][0], l["patchline"]["destination"][0]) if e not in set(ids)]
    print(f"{label}: {len(ids)} boxes, dup ids: {dup or 'none'}, dangling: {dangling or 'none'}")
d = json.load(open(out))["patcher"]
check(d, "root")
for b in d["boxes"]:
    if "patcher" in b["box"]:
        check(b["box"]["patcher"], f"  tab {b['box']['text']}")
print("wrote", out)
