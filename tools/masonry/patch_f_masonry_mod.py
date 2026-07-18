#!/usr/bin/env python3
"""
patch_f_masonry_mod.py
Adds u-mod and v-mod texture inlets to f_masonry.maxpat (Phase 5).

Changes:
  - Replaces codebox in gen-3 with phase 5 code (adds in2/in3 sampling + mod logic)
  - Adds gen-5 (in 2), gen-6 (in 3) to gen patcher with wires to codebox
  - Updates pix numinlets: 1 → 3
  - Adds outer inlet 1 (u-mod), inlet 2 (v-mod)
  - Updates route object to include u_mod_target, u_mod_depth, v_mod_target, v_mod_depth
  - Adds UI: u_mod_target (numbox int 0-3), u_mod_depth (dial -1 to 1),
             v_mod_target (numbox int 0-3), v_mod_depth (dial -1 to 1)
  - Adds prepend objects for new params → pix in0
  - Wires new inlets → pix in1/in2
  - Updates parameters block
"""

import json
from pathlib import Path

PATCHER_PATH = Path("/Users/matt/Github/f_/patchers/f_masonry.maxpat")
CODEBOX_PATH = Path("/Users/matt/Github/f_/src/f_masonry/codebox_phase5.gen")

with open(PATCHER_PATH) as f:
    doc = json.load(f)

with open(CODEBOX_PATH) as f:
    new_codebox = f.read()

# Convert newlines to \n for JSON embedding
new_codebox_escaped = new_codebox.replace("\n", "\n")

p = doc["patcher"]

# ------------------------------------------------------------------
# 1. Update codebox in gen-3 and add in2/in3 to gen patcher
# ------------------------------------------------------------------

pix_box = next(b for b in p["boxes"] if b["box"]["id"] == "obj-7")
gen = pix_box["box"]["patcher"]

# Update codebox code and numinlets (was 1, needs 3 for in1/in2/in3)
for b in gen["boxes"]:
    if b["box"]["id"] == "gen-3":
        b["box"]["code"] = new_codebox
        b["box"]["numinlets"] = 3
        break

# Add in 2 and in 3 boxes to gen patcher
gen["boxes"].append({"box": {
    "id": "gen-5",
    "maxclass": "newobj",
    "numinlets": 0, "numoutlets": 1, "outlettype": [""],
    "patching_rect": [210.0, 14.0, 35.0, 22.0],
    "text": "in 2"
}})
gen["boxes"].append({"box": {
    "id": "gen-6",
    "maxclass": "newobj",
    "numinlets": 0, "numoutlets": 1, "outlettype": [""],
    "patching_rect": [290.0, 14.0, 35.0, 22.0],
    "text": "in 3"
}})

# Wire in2 → codebox in1, in3 → codebox in2
gen["lines"].append({"patchline": {
    "source": ["gen-5", 0], "destination": ["gen-3", 1]
}})
gen["lines"].append({"patchline": {
    "source": ["gen-6", 0], "destination": ["gen-3", 2]
}})

# Update pix numinlets: 1 → 3
pix_box["box"]["numinlets"] = 3

# ------------------------------------------------------------------
# 2. Add outer inlets for u-mod (index 1) and v-mod (index 2)
# ------------------------------------------------------------------

p["boxes"].append({"box": {
    "id": "obj-m1",
    "maxclass": "inlet",
    "comment": "u-mod texture in",
    "index": 1,
    "numinlets": 0, "numoutlets": 1, "outlettype": [""],
    "patching_rect": [150.0, 30.0, 30.0, 30.0]
}})
p["boxes"].append({"box": {
    "id": "obj-m2",
    "maxclass": "inlet",
    "comment": "v-mod texture in",
    "index": 2,
    "numinlets": 0, "numoutlets": 1, "outlettype": [""],
    "patching_rect": [250.0, 30.0, 30.0, 30.0]
}})

# ------------------------------------------------------------------
# 3. Update route object to include new params
# ------------------------------------------------------------------

route_box = next(b for b in p["boxes"] if b["box"]["id"] == "obj-5b")
old_text = route_box["box"]["text"]
new_params = "u_mod_target u_mod_depth v_mod_target v_mod_depth"
route_box["box"]["text"] = old_text + " " + new_params
old_n = route_box["box"]["numinlets"]
route_box["box"]["numinlets"] = old_n + 4
route_box["box"]["numoutlets"] = old_n + 4
route_box["box"]["outlettype"] = [""] * (old_n + 4)

# ------------------------------------------------------------------
# 4. Add UI objects: numboxes for targets, dials for depths
#    Placed below existing UI row to avoid overlap
# ------------------------------------------------------------------

FONT = "Ableton Sans Light"
FONT_LABEL = 9.5
DIAL_COLOR = [0.8, 0.8, 0.8, 1.0]

# u_mod_target — live.numbox int 0-3
p["boxes"].append({"box": {
    "id": "obj-m10",
    "maxclass": "live.numbox",
    "fontname": FONT,
    "hint": "u-mod target: 0=none 1=mortar 2=drift 3=offset",
    "numinlets": 1, "numoutlets": 2, "outlettype": ["", "float"],
    "parameter_enable": 1,
    "patching_rect": [100.0, 390.0, 44.0, 15.0],
    "presentation": 1,
    "presentation_rect": [8.0, 152.0, 34.0, 15.0],
    "saved_attribute_attributes": {"valueof": {
        "parameter_initial": [0.0],
        "parameter_initial_enable": 1,
        "parameter_linknames": 1,
        "parameter_longname": "u_mod_target",
        "parameter_mmax": 3.0,
        "parameter_mmin": 0.0,
        "parameter_modmode": 0,
        "parameter_shortname": "u_mod_target",
        "parameter_type": 1,
        "parameter_unitstyle": 0
    }},
    "varname": "u_mod_target"
}})
p["boxes"].append({"box": {
    "id": "lbl-obj-m10",
    "maxclass": "comment",
    "fontname": FONT, "fontsize": FONT_LABEL,
    "numinlets": 1, "numoutlets": 0,
    "patching_rect": [100.0, 410.0, 44.0, 18.0],
    "presentation": 1,
    "presentation_rect": [-7.5, 136.0, 50.0, 18.0],
    "text": "u-tgt", "textjustification": 1
}})

# u_mod_depth — live.dial -1 to 1
p["boxes"].append({"box": {
    "id": "obj-m11",
    "maxclass": "live.dial",
    "activedialcolor": DIAL_COLOR,
    "fontname": FONT,
    "hint": "u-mod depth (bipolar)",
    "numinlets": 1, "numoutlets": 2, "outlettype": ["", "float"],
    "parameter_enable": 1,
    "patching_rect": [160.0, 380.0, 27.0, 43.0],
    "presentation": 1,
    "presentation_rect": [50.0, 136.0, 27.0, 43.0],
    "saved_attribute_attributes": {
        "activedialcolor": {"expression": ""},
        "valueof": {
            "parameter_initial": [0.0],
            "parameter_initial_enable": 1,
            "parameter_linknames": 1,
            "parameter_longname": "u_mod_depth",
            "parameter_mmax": 1.0,
            "parameter_mmin": -1.0,
            "parameter_modmode": 3,
            "parameter_shortname": "u_mod_depth",
            "parameter_type": 0,
            "parameter_unitstyle": 1
        }
    },
    "showname": 0, "triangle": 1, "valuepopup": 1, "valuepopuplabel": 1,
    "varname": "u_mod_depth"
}})
p["boxes"].append({"box": {
    "id": "lbl-obj-m11",
    "maxclass": "comment",
    "fontname": FONT, "fontsize": FONT_LABEL,
    "numinlets": 1, "numoutlets": 0,
    "patching_rect": [160.0, 430.0, 44.0, 18.0],
    "presentation": 1,
    "presentation_rect": [38.5, 120.0, 50.0, 18.0],
    "text": "u-dep", "textjustification": 1
}})

# v_mod_target — live.numbox int 0-3
p["boxes"].append({"box": {
    "id": "obj-m20",
    "maxclass": "live.numbox",
    "fontname": FONT,
    "hint": "v-mod target: 0=none 1=mortar 2=drift 3=offset",
    "numinlets": 1, "numoutlets": 2, "outlettype": ["", "float"],
    "parameter_enable": 1,
    "patching_rect": [220.0, 390.0, 44.0, 15.0],
    "presentation": 1,
    "presentation_rect": [92.0, 152.0, 34.0, 15.0],
    "saved_attribute_attributes": {"valueof": {
        "parameter_initial": [0.0],
        "parameter_initial_enable": 1,
        "parameter_linknames": 1,
        "parameter_longname": "v_mod_target",
        "parameter_mmax": 3.0,
        "parameter_mmin": 0.0,
        "parameter_modmode": 0,
        "parameter_shortname": "v_mod_target",
        "parameter_type": 1,
        "parameter_unitstyle": 0
    }},
    "varname": "v_mod_target"
}})
p["boxes"].append({"box": {
    "id": "lbl-obj-m20",
    "maxclass": "comment",
    "fontname": FONT, "fontsize": FONT_LABEL,
    "numinlets": 1, "numoutlets": 0,
    "patching_rect": [220.0, 410.0, 44.0, 18.0],
    "presentation": 1,
    "presentation_rect": [76.5, 136.0, 50.0, 18.0],
    "text": "v-tgt", "textjustification": 1
}})

# v_mod_depth — live.dial -1 to 1
p["boxes"].append({"box": {
    "id": "obj-m21",
    "maxclass": "live.dial",
    "activedialcolor": DIAL_COLOR,
    "fontname": FONT,
    "hint": "v-mod depth (bipolar)",
    "numinlets": 1, "numoutlets": 2, "outlettype": ["", "float"],
    "parameter_enable": 1,
    "patching_rect": [280.0, 380.0, 27.0, 43.0],
    "presentation": 1,
    "presentation_rect": [134.0, 136.0, 27.0, 43.0],
    "saved_attribute_attributes": {
        "activedialcolor": {"expression": ""},
        "valueof": {
            "parameter_initial": [0.0],
            "parameter_initial_enable": 1,
            "parameter_linknames": 1,
            "parameter_longname": "v_mod_depth",
            "parameter_mmax": 1.0,
            "parameter_mmin": -1.0,
            "parameter_modmode": 3,
            "parameter_shortname": "v_mod_depth",
            "parameter_type": 0,
            "parameter_unitstyle": 1
        }
    },
    "showname": 0, "triangle": 1, "valuepopup": 1, "valuepopuplabel": 1,
    "varname": "v_mod_depth"
}})
p["boxes"].append({"box": {
    "id": "lbl-obj-m21",
    "maxclass": "comment",
    "fontname": FONT, "fontsize": FONT_LABEL,
    "numinlets": 1, "numoutlets": 0,
    "patching_rect": [280.0, 430.0, 44.0, 18.0],
    "presentation": 1,
    "presentation_rect": [122.5, 120.0, 50.0, 18.0],
    "text": "v-dep", "textjustification": 1
}})

# ------------------------------------------------------------------
# 5. Add prepend objects for new params → pix in0
# ------------------------------------------------------------------

p["boxes"].append({"box": {
    "id": "obj-m30",
    "maxclass": "newobj",
    "numinlets": 1, "numoutlets": 1, "outlettype": [""],
    "patching_rect": [100.0, 420.0, 160.0, 22.0],
    "text": "prepend param u_mod_target"
}})
p["boxes"].append({"box": {
    "id": "obj-m31",
    "maxclass": "newobj",
    "numinlets": 1, "numoutlets": 1, "outlettype": [""],
    "patching_rect": [160.0, 420.0, 160.0, 22.0],
    "text": "prepend param u_mod_depth"
}})
p["boxes"].append({"box": {
    "id": "obj-m32",
    "maxclass": "newobj",
    "numinlets": 1, "numoutlets": 1, "outlettype": [""],
    "patching_rect": [220.0, 420.0, 160.0, 22.0],
    "text": "prepend param v_mod_target"
}})
p["boxes"].append({"box": {
    "id": "obj-m33",
    "maxclass": "newobj",
    "numinlets": 1, "numoutlets": 1, "outlettype": [""],
    "patching_rect": [280.0, 420.0, 160.0, 22.0],
    "text": "prepend param v_mod_depth"
}})

# ------------------------------------------------------------------
# 6. New patchlines
# ------------------------------------------------------------------

def wire(src, src_out, dst, dst_in):
    return {"patchline": {"source": [src, src_out], "destination": [dst, dst_in]}}

# mod inlets → pix in1 and in2
p["lines"].append(wire("obj-m1", 0, "obj-7", 1))
p["lines"].append(wire("obj-m2", 0, "obj-7", 2))

# UI → prepend → pix in0
p["lines"].append(wire("obj-m10", 0, "obj-m30", 0))
p["lines"].append(wire("obj-m30", 0, "obj-7",   0))
p["lines"].append(wire("obj-m11", 0, "obj-m31", 0))
p["lines"].append(wire("obj-m31", 0, "obj-7",   0))
p["lines"].append(wire("obj-m20", 0, "obj-m32", 0))
p["lines"].append(wire("obj-m32", 0, "obj-7",   0))
p["lines"].append(wire("obj-m21", 0, "obj-m33", 0))
p["lines"].append(wire("obj-m33", 0, "obj-7",   0))

# route new outlets → UI (outlets 19-22, 0-indexed)
# Current route has 19 params (outlets 0-18); new params are outlets 19-22
p["lines"].append(wire("obj-5b", 19, "obj-m10", 0))
p["lines"].append(wire("obj-5b", 20, "obj-m11", 0))
p["lines"].append(wire("obj-5b", 21, "obj-m20", 0))
p["lines"].append(wire("obj-5b", 22, "obj-m21", 0))

# ------------------------------------------------------------------
# 7. Update parameters block
# ------------------------------------------------------------------

p["parameters"]["obj-m10"] = ["u_mod_target", "u_mod_target", 0]
p["parameters"]["obj-m11"] = ["u_mod_depth",  "u_mod_depth",  0]
p["parameters"]["obj-m20"] = ["v_mod_target", "v_mod_target", 0]
p["parameters"]["obj-m21"] = ["v_mod_depth",  "v_mod_depth",  0]

# ------------------------------------------------------------------
# Write
# ------------------------------------------------------------------

with open(PATCHER_PATH, "w") as f:
    json.dump(doc, f, indent="\t")

print("Done.")
print(f"  Gen patcher: added in2, in3, updated codebox numinlets to 3")
print(f"  Outer patcher: added 2 inlets, 4 UI objects, 4 prepends, updated route")
print(f"  New wires: {2 + 8 + 4} total")
