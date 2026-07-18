#!/usr/bin/env python3
"""
Build script for f_modules.maxpat
Run this to regenerate the patcher when adding new modules.

After regenerating, verify in Max that typography looks correct —
all style attributes are baked in from the last manually-edited version.

When adding a module:
  1. Add to CATEGORIES below
  2. Add to SIZES in javascript/f_addmod.js
  3. Run: python3 .specify/f_modules/build_modules.py
  4. Validate: python3 -c "import json; json.load(open('patchers/f_modules.maxpat'))"
"""

import json, os

# ─── Module taxonomy ───────────────────────────────────────────────────────────
CATEGORIES = [
    ("Generators",  [("Masonry",        "masonry"),
                     ("Chladni",        "chladni"),
                     ("Stipple",        "stipple"),
                     ("Grain",          "grain"),
                     ("Weave",          "weave")]),
    ("Processors",  [("Droste",         "droste"),
                     ("Mobius",         "mobius"),
                     ("Stereo",         "stereo"),
                     ("Lens",           "lens"),
                     ("Caustic",        "caustic"),
                     ("SIRDS",          "sirds")]),
    ("Color / Tone",[("Channel Grader", "channel_grader"),
                     ("Hue Processor",  "hue_processor"),
                     ("Luma Processor", "luma_processor"),
                     ("Tone Curve",     "tone_curve")]),
    ("Utilities",   [("Tex Router",     "texrouter"),
                     ("Profile",        "util_profile")]),
    ("Vecfield",    [("Vortex",         "vf_vortex"),
                     ("Vortex Multi",   "vf_vortex_multi"),
                     ("Fieldmap",       "vf_fieldmap"),
                     ("Warp",           "vf_warp"),
                     ("Streak",         "vf_streak"),
                     ("Advect",         "vf_advect"),
                     ("Glow",           "vf_glow"),
                     ("Repulse",        "vf_repulse"),
                     ("Split",          "vf_split"),
                     ("Chroma",         "vf_chroma"),
                     ("Prism",          "vf_prism"),
                     ("Potential",      "vf_potential"),
                     ("Flow",           "vf_flow"),
                     ("Seeds",          "vf_seeds")]),
]

# ─── Colours (from manually-edited file) ──────────────────────────────────────
BLUE  = [0.0, 0.03529411765, 0.2274509804, 1.0]
WHITE = [1.0, 1.0, 1.0, 1.0]
BLACK = [0.0, 0.0, 0.0, 1.0]
GREY  = [0.45098039215686275, 0.47058823529411764, 0.5764705882352941, 1.0]
FONT  = "Ableton Sans Light"

# ─── Layout (derived from manually-edited presentation_rects) ─────────────────
PANEL_W   = 96.0
PANEL_H   = 249.0
LEFT      = 3.0
MENU_W    = 89.66666933894157
MENU_H    = 17.0
LABEL_H   = 21.0

# Exact y positions from the saved file — edit these if you resize
LABEL_YS  = [25.0, 68.0, 111.0, 154.0, 197.0]
MENU_YS   = [46.0, 89.0, 132.0, 175.0, 218.0]

# ─── Build ────────────────────────────────────────────────────────────────────
boxes  = []
lines  = []
params = {}
_id    = [1]

def nid():
    s = f"obj-{_id[0]}"
    _id[0] += 1
    return s

# Panel
panel_id = nid()
boxes.append({"box": {
    "background": 1,
    "bgcolor": BLACK,
    "border": 2,
    "bordercolor": BLUE,
    "id": panel_id,
    "maxclass": "panel",
    "mode": 0,
    "numinlets": 1,
    "numoutlets": 0,
    "patching_rect": [0.0, 0.0, 160.0, 209.0],
    "presentation": 1,
    "presentation_rect": [0.0, 0.0, PANEL_W, PANEL_H],
    "rounded": 6
}})

# f_ header
header_id = nid()
boxes.append({"box": {
    "fontface": 2,
    "fontname": FONT,
    "fontsize": 12.5,
    "id": header_id,
    "maxclass": "comment",
    "numinlets": 1,
    "numoutlets": 0,
    "patching_rect": [3.0, 4.0, 156.0, 21.0],
    "presentation": 1,
    "presentation_rect": [LEFT, 4.0, MENU_W, 21.0],
    "text": "f_",
    "textcolor": WHITE
}})

# Patching-only infrastructure
js_id   = nid()
gate_id = nid()
pipe_id = nid()
load_id = nid()

boxes.append({"box": {
    "id": js_id, "maxclass": "newobj",
    "numinlets": 1, "numoutlets": 1, "outlettype": [""],
    "patching_rect": [200.0, 300.0, 100.0, 22.0],
    "saved_object_attributes": {"filename": "f_addmod.js", "parameter_enable": 0},
    "text": "js f_addmod.js"
}})
boxes.append({"box": {
    "id": gate_id, "maxclass": "newobj",
    "numinlets": 2, "numoutlets": 1, "outlettype": [""],
    "patching_rect": [200.0, 270.0, 55.0, 22.0],
    "text": "gate 1 0"
}})
boxes.append({"box": {
    "id": pipe_id, "maxclass": "newobj",
    "numinlets": 2, "numoutlets": 1, "outlettype": [""],
    "patching_rect": [130.0, 230.0, 60.0, 22.0],
    "text": "pipe 250"
}})
boxes.append({"box": {
    "id": load_id, "maxclass": "newobj",
    "numinlets": 1, "numoutlets": 1, "outlettype": [""],
    "patching_rect": [130.0, 200.0, 72.0, 22.0],
    "text": "loadmess 1"
}})

lines.append({"patchline": {"source": [load_id, 0], "destination": [pipe_id, 0]}})
lines.append({"patchline": {"source": [pipe_id, 0], "destination": [gate_id, 0]}})
lines.append({"patchline": {"source": [gate_id, 0], "destination": [js_id,   0]}})

# Categories
vn = [0]

for i, (label, mods) in enumerate(CATEGORIES):
    label_y      = LABEL_YS[i]
    menu_y       = MENU_YS[i]
    patch_y_base = 600.0 + i * 100.0

    # Category label
    lbl_id = nid()
    boxes.append({"box": {
        "fontface": 0,
        "fontname": FONT,
        "fontsize": 12.0,
        "id": lbl_id,
        "maxclass": "comment",
        "numinlets": 1,
        "numoutlets": 0,
        "patching_rect": [LEFT, label_y, 176.0, LABEL_H],
        "presentation": 1,
        "presentation_rect": [2.0, label_y, MENU_W, LABEL_H],
        "text": label,
        "textcolor": GREY
    }})

    # Display-name menu (visible)
    disp_names = [m[0] for m in mods]
    disp_id    = nid()
    dvname     = "live.menu" if vn[0] == 0 else f"live.menu[{vn[0]}]"
    dlongname  = f"f_module_{i}_disp"
    vn[0]     += 1

    boxes.append({"box": {
        "appearance": 1,
        "fontname": FONT,
        "fontsize": 11.0,
        "id": disp_id,
        "lcdcolor": [0.8, 0.8, 0.8, 1.0],
        "maxclass": "live.menu",
        "numinlets": 1,
        "numoutlets": 3,
        "outlettype": ["", "", "float"],
        "parameter_enable": 1,
        "parameter_mappable": 0,
        "patching_rect": [LEFT, patch_y_base, 154.0, MENU_H],
        "presentation": 1,
        "presentation_rect": [LEFT, menu_y, MENU_W, MENU_H],
        "saved_attribute_attributes": {
            "lcdcolor": {"expression": "themecolor.live_arranger_grid_tiles"},
            "valueof": {
                "parameter_enum": disp_names,
                "parameter_initial": [0.0],
                "parameter_invisible": 2,
                "parameter_longname": dlongname,
                "parameter_mmax": len(disp_names) - 1,
                "parameter_modmode": 0,
                "parameter_shortname": "live.menu",
                "parameter_type": 2
            }
        },
        "varname": dvname
    }})

    # Filename menu (hidden)
    file_names = [m[1] for m in mods]
    file_id    = nid()
    fvname     = f"live.menu[{vn[0]}]"
    flongname  = f"f_module_{i}_file"
    vn[0]     += 1

    boxes.append({"box": {
        "id": file_id,
        "maxclass": "live.menu",
        "numinlets": 1,
        "numoutlets": 3,
        "outlettype": ["", "", "float"],
        "parameter_enable": 1,
        "parameter_mappable": 0,
        "patching_rect": [LEFT, patch_y_base + 600.0, 154.0, 15.0],
        "saved_attribute_attributes": {
            "valueof": {
                "parameter_enum": file_names,
                "parameter_initial": [0.0],
                "parameter_invisible": 2,
                "parameter_longname": flongname,
                "parameter_mmax": len(file_names) - 1,
                "parameter_modmode": 0,
                "parameter_shortname": "live.menu",
                "parameter_type": 2
            }
        },
        "varname": fvname
    }})

    # prepend addmod
    prep_id = nid()
    boxes.append({"box": {
        "id": prep_id, "maxclass": "newobj",
        "numinlets": 1, "numoutlets": 1, "outlettype": [""],
        "patching_rect": [LEFT, patch_y_base + 1200.0, 100.0, 22.0],
        "text": "prepend addmod"
    }})

    lines.append({"patchline": {"source": [disp_id, 0], "destination": [file_id, 0]}})
    lines.append({"patchline": {"source": [file_id, 1], "destination": [prep_id, 0]}})
    lines.append({"patchline": {"source": [prep_id, 0], "destination": [gate_id, 1]}})

    params[disp_id] = [dlongname, "live.menu", 0]
    params[file_id] = [flongname, "live.menu", 0]

params["parameterbanks"] = {
    "0": {"index": 0, "name": "", "parameters": ["-"]*8, "buttons": ["-"]*8}
}
params["inherited_shortname"] = 1

patcher = {
    "patcher": {
        "fileversion": 1,
        "appversion": {"major": 9, "minor": 1, "revision": 4, "architecture": "x64", "modernui": 1},
        "classnamespace": "box",
        "rect": [467.0, 158.0, 892.0, 835.0],
        "openinpresentation": 1,
        "boxes": boxes,
        "lines": lines,
        "parameters": params,
        "autosave": 0
    }
}

repo_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
out_path  = os.path.join(repo_root, "patchers", "f_modules.maxpat")

with open(out_path, "w") as f:
    json.dump(patcher, f, indent=4)

with open(out_path) as f:
    json.load(f)

print(f"OK — {out_path}")
print(f"Boxes: {len(boxes)}, Lines: {len(lines)}")
