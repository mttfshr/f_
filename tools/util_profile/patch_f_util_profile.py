#!/usr/bin/env python3
"""
patch_f_util_profile.py
Injects the dual-chain internal objects and wiring into f_util_profile.maxpat.

New objects added:
  obj-50  jit.gl.pix vsynth (passthrough to trigger asyncread)
  obj-51  jit.gl.asyncread vsynth
  obj-52  jit.dimop @op avg @step 640 1   (row averaging)
  obj-53  jit.dimop @op avg @step 1 640   (col averaging)
  obj-54  gate 1 1                         (gate_row)
  obj-55  gate 1 1                         (gate_col)
  obj-56  == 0                             (bypass inversion)
  obj-57  js profile_rows.js
  obj-58  js profile_cols.js
  obj-59  prepend res_rows
  obj-60  prepend res_cols
  obj-61  jit.gl.texture (row: 128x1, profile_rows_tex)
  obj-62  jit.gl.texture (col: 1x128, profile_cols_tex)
  obj-63  outlet 1 (col profile out)

New wiring:
  routepass out0  → pix
  pix out0        → asyncread
  asyncread out0  → dimop_row, dimop_col (fan out)
  dimop_row       → gate_row
  dimop_col       → gate_col
  bypass_jsui     → == 0 → gate_row in0, gate_col in0
  gate_row        → js_rows → tex_rows → outlet 0
  gate_col        → js_cols → tex_cols → outlet 1
  route out0      → numbox_res_rows → prepend res_rows → js_rows
  route out1      → numbox_res_cols → prepend res_cols → js_cols
"""

import json
from pathlib import Path

PATCHER_PATH = Path("/Users/matt/Github/f_/patchers/f_util_profile.maxpat")

with open(PATCHER_PATH) as f:
    doc = json.load(f)

p = doc["patcher"]

# ------------------------------------------------------------------
# New boxes
# ------------------------------------------------------------------

new_boxes = [
    {"box": {
        "id": "obj-50",
        "maxclass": "newobj",
        "numinlets": 1, "numoutlets": 2,
        "outlettype": ["jit_gl_texture", ""],
        "patching_rect": [200.0, 170.0, 230.0, 22.0],
        "text": "jit.gl.pix vsynth @adapt 0 @type char"
    }},
    {"box": {
        "id": "obj-51",
        "maxclass": "newobj",
        "numinlets": 3, "numoutlets": 1,
        "outlettype": [""],
        "patching_rect": [200.0, 210.0, 180.0, 22.0],
        "text": "jit.gl.asyncread vsynth @enable 1"
    }},
    {"box": {
        "id": "obj-52",
        "maxclass": "newobj",
        "numinlets": 1, "numoutlets": 1,
        "outlettype": [""],
        "patching_rect": [200.0, 250.0, 220.0, 22.0],
        "text": "jit.dimop @op avg @step 640 1"
    }},
    {"box": {
        "id": "obj-53",
        "maxclass": "newobj",
        "numinlets": 1, "numoutlets": 1,
        "outlettype": [""],
        "patching_rect": [450.0, 250.0, 220.0, 22.0],
        "text": "jit.dimop @op avg @step 1 640"
    }},
    {"box": {
        "id": "obj-54",
        "maxclass": "newobj",
        "numinlets": 2, "numoutlets": 1,
        "outlettype": [""],
        "patching_rect": [200.0, 290.0, 60.0, 22.0],
        "text": "gate 1 1"
    }},
    {"box": {
        "id": "obj-55",
        "maxclass": "newobj",
        "numinlets": 2, "numoutlets": 1,
        "outlettype": [""],
        "patching_rect": [450.0, 290.0, 60.0, 22.0],
        "text": "gate 1 1"
    }},
    {"box": {
        "id": "obj-56",
        "maxclass": "newobj",
        "numinlets": 1, "numoutlets": 1,
        "outlettype": [""],
        "patching_rect": [330.0, 170.0, 40.0, 22.0],
        "text": "== 0"
    }},
    {"box": {
        "id": "obj-57",
        "maxclass": "newobj",
        "numinlets": 1, "numoutlets": 1,
        "outlettype": [""],
        "patching_rect": [200.0, 330.0, 130.0, 22.0],
        "text": "js profile_rows.js"
    }},
    {"box": {
        "id": "obj-58",
        "maxclass": "newobj",
        "numinlets": 1, "numoutlets": 1,
        "outlettype": [""],
        "patching_rect": [450.0, 330.0, 130.0, 22.0],
        "text": "js profile_cols.js"
    }},
    {"box": {
        "id": "obj-59",
        "maxclass": "newobj",
        "numinlets": 1, "numoutlets": 1,
        "outlettype": [""],
        "patching_rect": [200.0, 160.0, 120.0, 22.0],
        "text": "prepend res_rows"
    }},
    {"box": {
        "id": "obj-60",
        "maxclass": "newobj",
        "numinlets": 1, "numoutlets": 1,
        "outlettype": [""],
        "patching_rect": [450.0, 160.0, 120.0, 22.0],
        "text": "prepend res_cols"
    }},
    {"box": {
        "id": "obj-61",
        "maxclass": "newobj",
        "numinlets": 1, "numoutlets": 1,
        "outlettype": ["jit_gl_texture"],
        "patching_rect": [200.0, 370.0, 290.0, 22.0],
        "text": "jit.gl.texture @adapt 0 @dim 128 1 @name profile_rows_tex"
    }},
    {"box": {
        "id": "obj-62",
        "maxclass": "newobj",
        "numinlets": 1, "numoutlets": 1,
        "outlettype": ["jit_gl_texture"],
        "patching_rect": [450.0, 370.0, 290.0, 22.0],
        "text": "jit.gl.texture @adapt 0 @dim 1 128 @name profile_cols_tex"
    }},
    {"box": {
        "id": "obj-63",
        "maxclass": "outlet",
        "comment": "col profile out (1x128)",
        "index": 1,
        "numinlets": 1, "numoutlets": 0,
        "patching_rect": [450.0, 420.0, 30.0, 30.0]
    }},
]

p["boxes"].extend(new_boxes)

# ------------------------------------------------------------------
# New patchlines
# ------------------------------------------------------------------

def wire(src, src_out, dst, dst_in):
    return {"patchline": {"source": [src, src_out], "destination": [dst, dst_in]}}

new_lines = [
    # routepass out0 → pix passthrough
    wire("obj-3",  0, "obj-50", 0),
    # pix out0 → asyncread
    wire("obj-50", 0, "obj-51", 0),
    # asyncread → both dimops (fan out)
    wire("obj-51", 0, "obj-52", 0),
    wire("obj-51", 0, "obj-53", 0),
    # dimop_row → gate_row
    wire("obj-52", 0, "obj-54", 1),
    # dimop_col → gate_col
    wire("obj-53", 0, "obj-55", 1),
    # bypass_jsui → == 0 → both gates in0
    wire("obj-29", 0, "obj-56", 0),
    wire("obj-56", 0, "obj-54", 0),
    wire("obj-56", 0, "obj-55", 0),
    # gate_row → js_rows → tex_rows → outlet 0
    wire("obj-54", 0, "obj-57", 0),
    wire("obj-57", 0, "obj-61", 0),
    wire("obj-61", 0, "obj-2",  0),
    # gate_col → js_cols → tex_cols → outlet 1
    wire("obj-55", 0, "obj-58", 0),
    wire("obj-58", 0, "obj-62", 0),
    wire("obj-62", 0, "obj-63", 0),
    # route out0 → numbox_res_rows → prepend res_rows → js_rows
    wire("obj-20", 0, "obj-59", 0),
    wire("obj-59", 0, "obj-57", 0),
    # route out1 → numbox_res_cols → prepend res_cols → js_cols
    wire("obj-23", 0, "obj-60", 0),
    wire("obj-60", 0, "obj-58", 0),
]

p["lines"].extend(new_lines)

# ------------------------------------------------------------------
# Write
# ------------------------------------------------------------------

with open(PATCHER_PATH, "w") as f:
    json.dump(doc, f, indent="\t")

print(f"Done. {len(new_boxes)} objects added, {len(new_lines)} wires added.")
