#!/usr/bin/env python3
"""
patch_f_util_profile_op.py
Adds row_op and col_op params to f_util_profile.maxpat.

Each param is a live.menu (avg/max/min). Selection is converted to a symbol
via sel 0 1 2 → message boxes → prepend op → dimop inlet 0.

New objects:
  obj-70  live.menu (row_op)
  obj-71  comment label "row op"
  obj-72  sel 0 1 2  (row)
  obj-73  message "avg" (row)
  obj-74  message "max" (row)
  obj-75  message "min" (row)
  obj-76  prepend op  (row)
  obj-80  live.menu (col_op)
  obj-81  comment label "col op"
  obj-82  sel 0 1 2  (col)
  obj-83  message "avg" (col)
  obj-84  message "max" (col)
  obj-85  message "min" (col)
  obj-86  prepend op  (col)

Route obj-4 updated: add row_op, col_op
"""

import json
from pathlib import Path

PATCHER_PATH = Path("/Users/matt/Github/f_/patchers/f_util_profile.maxpat")

with open(PATCHER_PATH) as f:
    doc = json.load(f)

p = doc["patcher"]

FONT = "Ableton Sans Light"
FONT_LABEL = 9.5

# ------------------------------------------------------------------
# 1. Update route to include row_op and col_op
# ------------------------------------------------------------------

route_box = next(b for b in p["boxes"] if b["box"]["id"] == "obj-4")
route_box["box"]["text"] = "route res_rows res_cols freq row_op col_op"
route_box["box"]["numinlets"] = 1
route_box["box"]["numoutlets"] = 5
route_box["box"]["outlettype"] = ["", "", "", "", ""]

# ------------------------------------------------------------------
# 2. Add live.menu boxes for row_op and col_op
#    Placed in presentation below existing params
# ------------------------------------------------------------------

menu_items = ["avg", "max", "min"]

# row_op menu
p["boxes"].append({"box": {
    "id": "obj-70",
    "maxclass": "live.menu",
    "fontname": FONT,
    "hint": "Row profile operation",
    "items": menu_items,
    "numinlets": 1, "numoutlets": 2, "outlettype": ["", "float"],
    "parameter_enable": 1,
    "patching_rect": [50.0, 560.0, 55.0, 18.0],
    "presentation": 1,
    "presentation_rect": [4.0, 56.0, 55.0, 18.0],
    "saved_attribute_attributes": {"valueof": {
        "parameter_initial": [0.0],
        "parameter_initial_enable": 1,
        "parameter_linknames": 1,
        "parameter_longname": "row_op",
        "parameter_mmax": 2.0,
        "parameter_mmin": 0.0,
        "parameter_modmode": 0,
        "parameter_shortname": "row_op",
        "parameter_type": 1,
        "parameter_unitstyle": 0
    }},
    "varname": "row_op"
}})
p["boxes"].append({"box": {
    "id": "obj-71",
    "maxclass": "comment",
    "fontname": FONT, "fontsize": FONT_LABEL,
    "numinlets": 1, "numoutlets": 0,
    "patching_rect": [50.0, 580.0, 55.0, 18.0],
    "presentation": 1,
    "presentation_rect": [-7.5, 42.0, 55.0, 18.0],
    "text": "row op", "textjustification": 1
}})

# row sel + messages
p["boxes"].append({"box": {
    "id": "obj-72",
    "maxclass": "newobj",
    "numinlets": 1, "numoutlets": 4, "outlettype": ["bang", "bang", "bang", ""],
    "patching_rect": [50.0, 600.0, 60.0, 22.0],
    "text": "sel 0 1 2"
}})
p["boxes"].append({"box": {
    "id": "obj-73",
    "maxclass": "message",
    "numinlets": 2, "numoutlets": 1, "outlettype": [""],
    "patching_rect": [50.0, 630.0, 35.0, 22.0],
    "text": "avg"
}})
p["boxes"].append({"box": {
    "id": "obj-74",
    "maxclass": "message",
    "numinlets": 2, "numoutlets": 1, "outlettype": [""],
    "patching_rect": [95.0, 630.0, 35.0, 22.0],
    "text": "max"
}})
p["boxes"].append({"box": {
    "id": "obj-75",
    "maxclass": "message",
    "numinlets": 2, "numoutlets": 1, "outlettype": [""],
    "patching_rect": [140.0, 630.0, 35.0, 22.0],
    "text": "min"
}})
p["boxes"].append({"box": {
    "id": "obj-76",
    "maxclass": "newobj",
    "numinlets": 1, "numoutlets": 1, "outlettype": [""],
    "patching_rect": [50.0, 660.0, 70.0, 22.0],
    "text": "prepend op"
}})

# col_op menu
p["boxes"].append({"box": {
    "id": "obj-80",
    "maxclass": "live.menu",
    "fontname": FONT,
    "hint": "Column profile operation",
    "items": menu_items,
    "numinlets": 1, "numoutlets": 2, "outlettype": ["", "float"],
    "parameter_enable": 1,
    "patching_rect": [115.0, 560.0, 55.0, 18.0],
    "presentation": 1,
    "presentation_rect": [66.0, 56.0, 55.0, 18.0],
    "saved_attribute_attributes": {"valueof": {
        "parameter_initial": [0.0],
        "parameter_initial_enable": 1,
        "parameter_linknames": 1,
        "parameter_longname": "col_op",
        "parameter_mmax": 2.0,
        "parameter_mmin": 0.0,
        "parameter_modmode": 0,
        "parameter_shortname": "col_op",
        "parameter_type": 1,
        "parameter_unitstyle": 0
    }},
    "varname": "col_op"
}})
p["boxes"].append({"box": {
    "id": "obj-81",
    "maxclass": "comment",
    "fontname": FONT, "fontsize": FONT_LABEL,
    "numinlets": 1, "numoutlets": 0,
    "patching_rect": [115.0, 580.0, 55.0, 18.0],
    "presentation": 1,
    "presentation_rect": [54.5, 42.0, 55.0, 18.0],
    "text": "col op", "textjustification": 1
}})

# col sel + messages
p["boxes"].append({"box": {
    "id": "obj-82",
    "maxclass": "newobj",
    "numinlets": 1, "numoutlets": 4, "outlettype": ["bang", "bang", "bang", ""],
    "patching_rect": [115.0, 600.0, 60.0, 22.0],
    "text": "sel 0 1 2"
}})
p["boxes"].append({"box": {
    "id": "obj-83",
    "maxclass": "message",
    "numinlets": 2, "numoutlets": 1, "outlettype": [""],
    "patching_rect": [115.0, 630.0, 35.0, 22.0],
    "text": "avg"
}})
p["boxes"].append({"box": {
    "id": "obj-84",
    "maxclass": "message",
    "numinlets": 2, "numoutlets": 1, "outlettype": [""],
    "patching_rect": [160.0, 630.0, 35.0, 22.0],
    "text": "max"
}})
p["boxes"].append({"box": {
    "id": "obj-85",
    "maxclass": "message",
    "numinlets": 2, "numoutlets": 1, "outlettype": [""],
    "patching_rect": [205.0, 630.0, 35.0, 22.0],
    "text": "min"
}})
p["boxes"].append({"box": {
    "id": "obj-86",
    "maxclass": "newobj",
    "numinlets": 1, "numoutlets": 1, "outlettype": [""],
    "patching_rect": [115.0, 660.0, 70.0, 22.0],
    "text": "prepend op"
}})

# ------------------------------------------------------------------
# 3. New patchlines
# ------------------------------------------------------------------

def wire(src, src_out, dst, dst_in):
    return {"patchline": {"source": [src, src_out], "destination": [dst, dst_in]}}

new_lines = [
    # route outlets 3,4 → menus
    wire("obj-4",  3, "obj-70", 0),
    wire("obj-4",  4, "obj-80", 0),

    # row_op: menu → sel → messages → prepend op → dimop row (obj-52)
    wire("obj-70", 0, "obj-72", 0),
    wire("obj-72", 0, "obj-73", 0),
    wire("obj-72", 1, "obj-74", 0),
    wire("obj-72", 2, "obj-75", 0),
    wire("obj-73", 0, "obj-76", 0),
    wire("obj-74", 0, "obj-76", 0),
    wire("obj-75", 0, "obj-76", 0),
    wire("obj-76", 0, "obj-52", 0),

    # col_op: menu → sel → messages → prepend op → dimop col (obj-53)
    wire("obj-80", 0, "obj-82", 0),
    wire("obj-82", 0, "obj-83", 0),
    wire("obj-82", 1, "obj-84", 0),
    wire("obj-82", 2, "obj-85", 0),
    wire("obj-83", 0, "obj-86", 0),
    wire("obj-84", 0, "obj-86", 0),
    wire("obj-85", 0, "obj-86", 0),
    wire("obj-86", 0, "obj-53", 0),
]

p["lines"].extend(new_lines)

# ------------------------------------------------------------------
# 4. Update parameters block
# ------------------------------------------------------------------

p["parameters"]["obj-70"] = ["row_op", "row_op", 0]
p["parameters"]["obj-80"] = ["col_op", "col_op", 0]

# Also expand the panel height to accommodate new UI rows
for b in p["boxes"]:
    if b["box"].get("id") == "obj-9":
        b["box"]["presentation_rect"][3] = 120.0
        b["box"]["patching_rect"][3] = 120.0
        break

# ------------------------------------------------------------------
# Write
# ------------------------------------------------------------------

with open(PATCHER_PATH, "w") as f:
    json.dump(doc, f, indent="\t")

print("Done.")
print(f"  Added row_op and col_op live.menu params")
print(f"  Each routes 0/1/2 → avg/max/min → prepend op → respective dimop")
print(f"  Panel height expanded to 120px")
