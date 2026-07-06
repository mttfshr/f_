#!/usr/bin/env python3
"""
build_advect.py — generates f_vf_advect.maxpat

Two-pix temporal advection processor:
  - advect_pix (obj-5): 3-inlet pix; source (in0), vecfield (in1), previous frame (in2)
  - pass_pix   (obj-50): 1-inlet identity pix; holds previous frame for feedback

Feedback loop: advect_pix out0 → pass_pix in0
               pass_pix out0   → advect_pix in2

Run: python3 .specify/f_vf_advect/build_advect.py
"""

import json, sys
from pathlib import Path

# ---------------------------------------------------------------------------
# Repo root
# ---------------------------------------------------------------------------
REPO = Path(__file__).parent.parent.parent   # .specify/f_vf_advect/ → f_/

# ---------------------------------------------------------------------------
# Styling (match build_patcher.py)
# ---------------------------------------------------------------------------
FONT         = "Ableton Sans Light"
FONT_TITLE   = 12.0
FONT_LABEL   = 9.5
DIAL_COLOR   = [0.8, 0.8, 0.8, 1.0]
BG_COLOR     = [0.0, 0.0, 0.0, 1.0]
BORDER_COLOR = [0.0, 0.03529411765, 0.2274509804, 1.0]

# ---------------------------------------------------------------------------
# Module identity
# ---------------------------------------------------------------------------
NAME        = "f_vf_advect"
PREFIX      = "vfadvect"
OBJ_NAME    = "#0_advect_pix"   # advect pix @name (scoped)
PASS_NAME   = "#0_advect_pass"  # pass pix @name (scoped)
TITLE       = "Advect"
PW, PH      = 190.0, 130.0     # presentation width, height

CODEBOX = open(Path(__file__).parent / "codebox_advect.gen").read()

# ---------------------------------------------------------------------------
# UI params (displayed in grid)
# ---------------------------------------------------------------------------
PARAMS = [
    {"name": "dt",        "type": "float", "min": 0.0,  "max": 0.05, "default": 0.01, "label": "dt"},
    {"name": "decay",     "type": "float", "min": 0.8,  "max": 1.5,  "default": 0.97, "label": "Decay"},
    {"name": "injection", "type": "float", "min": 0.0,  "max": 0.2,  "default": 0.02, "label": "Inject"},
    {"name": "mix_amt",   "type": "float", "min": 0.0,  "max": 1.5,  "default": 1.0,  "label": "Mix"},
]

# ---------------------------------------------------------------------------
# Object IDs
# ---------------------------------------------------------------------------
OBJ_INLET       = "obj-1"
OBJ_OUTLET      = "obj-2"
OBJ_ROUTEPASS   = "obj-3"
OBJ_ROUTE       = "obj-4"
OBJ_ADVECT_PIX  = "obj-5"      # advect_pix — main pix
OBJ_AUTOPATTR   = "obj-6"
OBJ_PANEL       = "obj-9"
OBJ_TITLE_BOX   = "obj-10"
OBJ_LOADBANG    = "obj-11"
OBJ_GETATTR     = "obj-12"
OBJ_THISPATCHER = "obj-13"
OBJ_ZLSLICE     = "obj-14"
OBJ_PRETAM      = "obj-15"
OBJ_MODULESIZE  = "obj-16"

OBJ_PASS_PIX    = "obj-50"     # pass_pix — identity feedback holder
OBJ_VF_INLET    = "obj-51"     # vecfield bpatcher inlet
OBJ_VF_INSTATE  = "obj-52"     # vs_inState on vecfield inlet
OBJ_VF_STATEPRE = "obj-53"     # prepend param src_vecfield

UI_BASE = 20

def param_obj_id(n):   return f"obj-{UI_BASE + n*3 + 0}"
def param_pre_id(n):   return f"obj-{UI_BASE + n*3 + 1}"
def param_label_id(n): return f"obj-{UI_BASE + n*3 + 2}"

N = len(PARAMS)
OBJ_BYPASS_JSUI = f"obj-{UI_BASE + N*3 + 0}"
OBJ_BYPASS_PRE  = f"obj-{UI_BASE + N*3 + 1}"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
def box(id, **kw):
    return {"box": {"id": id, **kw}}

def wire(src, src_out, dst, dst_in):
    return {"patchline": {"source": [src, src_out], "destination": [dst, dst_in]}}

# ---------------------------------------------------------------------------
# Gen subpatcher builders
# ---------------------------------------------------------------------------

def gen_pass():
    """Trivial identity gen: in 1 → out 1. No codebox needed."""
    return {
        "fileversion": 1,
        "appversion": {"major": 9, "minor": 1, "revision": 4,
                       "architecture": "x64", "modernui": 1},
        "classnamespace": "jit.gen",
        "rect": [100.0, 100.0, 400.0, 300.0],
        "boxes": [
            {"box": {"id": "gen-obj-1", "maxclass": "newobj",
                     "numinlets": 0, "numoutlets": 1, "outlettype": [""],
                     "patching_rect": [22.0, 30.0, 28.0, 22.0], "text": "in 1"}},
            {"box": {"id": "gen-obj-2", "maxclass": "newobj",
                     "numinlets": 1, "numoutlets": 0,
                     "patching_rect": [22.0, 100.0, 35.0, 22.0], "text": "out 1"}},
        ],
        "lines": [
            {"patchline": {"source": ["gen-obj-1", 0], "destination": ["gen-obj-2", 0]}}
        ]
    }

def gen_advect():
    """3-inlet advect gen: in1=source, in2=vecfield, in3=previous → codebox → out1."""
    return {
        "fileversion": 1,
        "appversion": {"major": 9, "minor": 1, "revision": 4,
                       "architecture": "x64", "modernui": 1},
        "classnamespace": "jit.gen",
        "rect": [100.0, 100.0, 700.0, 600.0],
        "boxes": [
            {"box": {"id": "gen-obj-1", "maxclass": "newobj",
                     "numinlets": 0, "numoutlets": 1, "outlettype": [""],
                     "patching_rect": [22.0,  30.0, 28.0, 22.0], "text": "in 1"}},
            {"box": {"id": "gen-obj-2", "maxclass": "newobj",
                     "numinlets": 0, "numoutlets": 1, "outlettype": [""],
                     "patching_rect": [80.0,  30.0, 28.0, 22.0], "text": "in 2"}},
            {"box": {"id": "gen-obj-3", "maxclass": "newobj",
                     "numinlets": 0, "numoutlets": 1, "outlettype": [""],
                     "patching_rect": [138.0, 30.0, 28.0, 22.0], "text": "in 3"}},
            {"box": {
                "id": "gen-obj-4", "maxclass": "codebox",
                "code": CODEBOX,
                "fontface": 0, "fontname": "<Monospaced>", "fontsize": 12.0,
                "numinlets": 3, "numoutlets": 2, "outlettype": ["", ""],
                "patching_rect": [22.0, 80.0, 550.0, 380.0]
            }},
            {"box": {"id": "gen-obj-5", "maxclass": "newobj",
                     "numinlets": 1, "numoutlets": 0,
                     "patching_rect": [22.0, 490.0, 35.0, 22.0], "text": "out 1"}},
            {"box": {"id": "gen-obj-6", "maxclass": "newobj",
                     "numinlets": 1, "numoutlets": 0,
                     "patching_rect": [80.0, 490.0, 35.0, 22.0], "text": "out 2"}},
        ],
        "lines": [
            {"patchline": {"source": ["gen-obj-1", 0], "destination": ["gen-obj-4", 0]}},
            {"patchline": {"source": ["gen-obj-2", 0], "destination": ["gen-obj-4", 1]}},
            {"patchline": {"source": ["gen-obj-3", 0], "destination": ["gen-obj-4", 2]}},
            {"patchline": {"source": ["gen-obj-4", 0], "destination": ["gen-obj-5", 0]}},
            {"patchline": {"source": ["gen-obj-4", 1], "destination": ["gen-obj-6", 0]}},
        ]
    }

# ---------------------------------------------------------------------------
# Box builders (UI)
# ---------------------------------------------------------------------------

def dial_box(n, p):
    col = n % 5; row = n // 5
    x = 4.0 + col * 37.0; y = 38.0 + row * 62.0
    return box(param_obj_id(n),
        maxclass="live.dial",
        activedialcolor=DIAL_COLOR, fontname=FONT,
        numinlets=1, numoutlets=2, outlettype=["", "float"],
        param_connect=f"{OBJ_NAME}::{p['name']}",
        parameter_enable=1,
        patching_rect=[50.0 + n*50.0, 80.0, 27.0, 43.0],
        presentation=1,
        presentation_rect=[x, y, 27.0, 43.0],
        saved_attribute_attributes={"activedialcolor": {"expression": ""}, "valueof": {
            "parameter_initial": [float(p["default"])],
            "parameter_initial_enable": 1,
            "parameter_linknames": 1,
            "parameter_longname": p["name"],
            "parameter_mmax": float(p["max"]),
            "parameter_mmin": float(p["min"]),
            "parameter_modmode": 3,
            "parameter_shortname": p["name"],
            "parameter_type": 0,
            "parameter_unitstyle": 1,
        }},
        showname=0, triangle=1, valuepopup=1, valuepopuplabel=1,
        varname=p["name"])

def label_box(n, p):
    col = n % 5; row = n // 5
    x = 4.0 + col * 37.0; y = 20.0 + row * 62.0
    return box(param_label_id(n),
        maxclass="comment", fontname=FONT, fontsize=FONT_LABEL,
        numinlets=1, numoutlets=0,
        patching_rect=[50.0 + n*50.0, 130.0, 50.0, 18.0],
        presentation=1,
        presentation_rect=[x - 11.5, y, 50.0, 18.0],
        text=p.get("label", p["name"]),
        textjustification=1)

def attrui_box(obj_id, name, x, y):
    return box(obj_id,
        maxclass="attrui", attr=name,
        numinlets=1, numoutlets=1, outlettype=[""],
        patching_rect=[x, y, max(100.0, len(name)*7.0 + 80.0), 22.0],
        style="")

def modulesize_boxes():
    return [
        box(OBJ_LOADBANG,    maxclass="newobj", numinlets=1, numoutlets=1, outlettype=[""],
            patching_rect=[600.0, 50.0,  60.0, 22.0], text="loadbang"),
        box(OBJ_GETATTR,     maxclass="message", numinlets=2, numoutlets=1, outlettype=[""],
            patching_rect=[600.0, 80.0,  180.0, 22.0], text="getattr presentation_rect"),
        box(OBJ_THISPATCHER, maxclass="newobj", numinlets=1, numoutlets=4, outlettype=["","","",""],
            patching_rect=[600.0, 110.0, 80.0, 22.0], text="thispatcher"),
        box(OBJ_ZLSLICE,     maxclass="newobj", numinlets=2, numoutlets=2, outlettype=["",""],
            patching_rect=[600.0, 140.0, 60.0, 22.0], text="zl slice 2"),
        box(OBJ_PRETAM,      maxclass="newobj", numinlets=1, numoutlets=1, outlettype=[""],
            patching_rect=[600.0, 170.0, 80.0, 22.0], text="prepend tam"),
        box(OBJ_MODULESIZE,  maxclass="newobj", numinlets=1, numoutlets=1, outlettype=[""],
            patching_rect=[600.0, 200.0, 100.0, 22.0],
            saved_object_attributes={"filename": "moduleSize.js", "parameter_enable": 0},
            text="js moduleSize.js"),
    ]

# ---------------------------------------------------------------------------
# Main builder
# ---------------------------------------------------------------------------

def build():
    route_names = " ".join(p["name"] for p in PARAMS)

    boxes = [
        # Standard signal flow infrastructure
        box(OBJ_INLET,   maxclass="inlet",  comment="texture / control", index=0,
            numinlets=0, numoutlets=1, outlettype=[""],
            patching_rect=[30.0, 30.0, 30.0, 30.0]),
        box(OBJ_OUTLET,  maxclass="outlet", comment="composite", index=0,
            numinlets=1, numoutlets=0,
            patching_rect=[30.0, 500.0, 30.0, 30.0]),
        box("obj-2b",    maxclass="outlet", comment="advected", index=1,
            numinlets=1, numoutlets=0,
            patching_rect=[100.0, 500.0, 30.0, 30.0]),
        box(OBJ_ROUTEPASS, maxclass="newobj",
            numinlets=3, numoutlets=3, outlettype=["","",""],
            patching_rect=[200.0, 90.0, 215.0, 22.0],
            text="routepass jit_gl_texture jit_matrix"),
        box(OBJ_ROUTE, maxclass="newobj",
            numinlets=1, numoutlets=len(PARAMS), outlettype=[""] * len(PARAMS),
            patching_rect=[200.0, 130.0, max(150.0, len(route_names)*7.0), 22.0],
            text=f"route {route_names}"),

        # advect_pix — main 3-inlet pix
        box(OBJ_ADVECT_PIX, maxclass="newobj",
            numinlets=3, numoutlets=2, outlettype=["jit_gl_texture", ""],
            patcher=gen_advect(),
            patching_rect=[200.0, 380.0, 320.0, 22.0],
            text=f"jit.gl.pix vsynth @name {OBJ_NAME} @type char @adapt 1",
            varname=OBJ_NAME),

        # pass_pix — identity pix, holds previous frame
        box(OBJ_PASS_PIX, maxclass="newobj",
            numinlets=1, numoutlets=2, outlettype=["jit_gl_texture", ""],
            patcher=gen_pass(),
            patching_rect=[200.0, 440.0, 300.0, 22.0],
            text=f"jit.gl.pix vsynth @name {PASS_NAME} @type char @adapt 1",
            varname=PASS_NAME),

        # autopattr
        box(OBJ_AUTOPATTR, maxclass="newobj",
            numinlets=1, numoutlets=4, outlettype=["","","",""],
            patching_rect=[500.0, 500.0, 56.0, 22.0],
            text="autopattr", varname=f"{PREFIX}_autopattr"),

        # Panel + title + signal type label
        box(OBJ_PANEL, maxclass="panel",
            angle=270.0, background=1, bgcolor=BG_COLOR,
            border=1, bordercolor=BORDER_COLOR, mode=0,
            numinlets=1, numoutlets=0,
            patching_rect=[20.0, 20.0, PW, PH],
            presentation=1, presentation_rect=[0.0, 0.0, PW, PH],
            proportion=0.5),
        box(OBJ_TITLE_BOX, maxclass="comment",
            fontname=FONT, fontsize=FONT_TITLE,
            numinlets=1, numoutlets=0,
            patching_rect=[20.0, 20.0, 80.0, 21.0],
            presentation=1, presentation_rect=[-1.5, 0.0, 80.0, 21.0],
            text=TITLE),
        box("obj-8", maxclass="comment",
            fontname=FONT, fontsize=FONT_LABEL,
            textcolor=[0.35, 0.75, 0.95, 1.0],
            numinlets=1, numoutlets=0,
            patching_rect=[20.0, 20.0, 60.0, 21.0],
            presentation=1, presentation_rect=[len(TITLE) * 7.2 - 2.0, 2.5, 60.0, 18.0],
            text="vecfield"),

        # vecfield inlet + vs_inState + state prepend
        box(OBJ_VF_INLET,    maxclass="inlet",  comment="vecfield", index=1,
            numinlets=0, numoutlets=1, outlettype=[""],
            patching_rect=[90.0, 30.0, 30.0, 30.0]),
        box(OBJ_VF_INSTATE,  maxclass="newobj", text="vs_inState",
            numinlets=1, numoutlets=2, outlettype=["",""],
            patching_rect=[90.0, 80.0, 80.0, 22.0]),
        box(OBJ_VF_STATEPRE, maxclass="newobj", text="prepend param src_vecfield",
            numinlets=1, numoutlets=1, outlettype=[""],
            patching_rect=[90.0, 130.0, 180.0, 22.0]),
    ]

    # moduleSize chain
    boxes.extend(modulesize_boxes())

    # Per-param UI: dial + attrui + label
    for n, p in enumerate(PARAMS):
        boxes.append(dial_box(n, p))
        boxes.append(attrui_box(param_pre_id(n), p["name"], 50.0 + n*50.0, 170.0 + n*30.0))
        boxes.append(label_box(n, p))

    # Bypass jsui + attrui
    boxes.append(box(OBJ_BYPASS_JSUI,
        maxclass="jsui", filename="bypass_toggle.js", hint="Bypass",
        numinlets=1, numoutlets=1, outlettype=[""],
        presentation=1,
        patching_rect=[PW - 22.0, 5.0, 18.0, 12.0],
        presentation_rect=[PW - 22.0, 5.0, 18.0, 12.0],
        valuepopuplabel=1, varname="bypass"))
    boxes.append(box(OBJ_BYPASS_PRE,
        maxclass="attrui", attr="bypass",
        numinlets=1, numoutlets=1, outlettype=[""],
        patching_rect=[400.0, 60.0, 131.0, 22.0], style=""))

    # ---------------------------------------------------------------------------
    # Patchlines
    # ---------------------------------------------------------------------------
    lines = [
        # Inlet → routepass
        wire(OBJ_INLET,      0, OBJ_ROUTEPASS,   0),
        # routepass texture out → advect_pix in0 (source)
        wire(OBJ_ROUTEPASS,  0, OBJ_ADVECT_PIX,  0),
        # routepass unmatched → route
        wire(OBJ_ROUTEPASS,  2, OBJ_ROUTE,        0),

        # vecfield inlet → vs_inState → advect_pix in1
        wire(OBJ_VF_INLET,   0, OBJ_VF_INSTATE,  0),
        wire(OBJ_VF_INSTATE, 0, OBJ_ADVECT_PIX,  1),
        # vs_inState out1 (0/1 state) → prepend src_vecfield → advect_pix in0
        wire(OBJ_VF_INSTATE, 1, OBJ_VF_STATEPRE, 0),
        wire(OBJ_VF_STATEPRE,0, OBJ_ADVECT_PIX,  0),

        # Feedback: pass_pix out0 → advect_pix in2 (previous frame)
        wire(OBJ_PASS_PIX,   0, OBJ_ADVECT_PIX,  2),
        # Feedback: advect_pix out0 → pass_pix in0
        wire(OBJ_ADVECT_PIX, 0, OBJ_PASS_PIX,    0),

        # advect_pix out0 → bpatcher outlet (composite), out1 → second outlet (advected)
        wire(OBJ_ADVECT_PIX, 0, OBJ_OUTLET,  0),
        wire(OBJ_ADVECT_PIX, 1, "obj-2b",    0),

        # bypass
        wire(OBJ_BYPASS_JSUI,0, OBJ_BYPASS_PRE,  0),
        wire(OBJ_BYPASS_PRE, 0, OBJ_ADVECT_PIX,  0),

        # moduleSize chain
        wire(OBJ_LOADBANG,   0, OBJ_GETATTR,      0),
        wire(OBJ_GETATTR,    0, OBJ_THISPATCHER,  0),
        wire(OBJ_THISPATCHER,0, OBJ_ZLSLICE,      0),
        wire(OBJ_ZLSLICE,    1, OBJ_PRETAM,       0),
        wire(OBJ_PRETAM,     0, OBJ_MODULESIZE,   0),
    ]

    # route → dial → attrui → advect_pix
    for n, p in enumerate(PARAMS):
        lines.append(wire(OBJ_ROUTE,       n, param_obj_id(n), 0))
        lines.append(wire(param_obj_id(n), 0, param_pre_id(n), 0))
        lines.append(wire(param_pre_id(n), 0, OBJ_ADVECT_PIX,  0))

    # parameters block
    params_block = {}
    for n, p in enumerate(PARAMS):
        params_block[param_obj_id(n)] = [p["name"], p["name"], 0]
    params_block["parameterbanks"] = {"0": {
        "index": 0, "name": "",
        "parameters": ["-","-","-","-","-","-","-","-"],
        "buttons":    ["-","-","-","-","-","-","-","-"]
    }}
    params_block["inherited_shortname"] = 1

    patcher = {
        "fileversion": 1,
        "appversion": {"major": 9, "minor": 1, "revision": 4,
                       "architecture": "x64", "modernui": 1},
        "classnamespace": "box",
        "rect": [100.0, 100.0, 800.0, 600.0],
        "openinpresentation": 1,
        "boxes": boxes,
        "lines": lines,
        "parameters": params_block,
        "autosave": 0
    }

    return {"patcher": patcher}

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    result   = build()
    out_path = REPO / "patchers" / f"{NAME}.maxpat"
    with open(out_path, "w") as f:
        json.dump(result, f, indent="\t")
    print(f"Written: {out_path}")
