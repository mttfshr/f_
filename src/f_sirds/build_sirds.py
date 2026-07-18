#!/usr/bin/env python3
"""
build_sirds.py — generates f_sirds.maxpat

13-stage SIRDS chain: stage0 (reference/seed, unmasked periodic tile) +
stage1..stage12 (depth-driven, byte-identical codebox apart from baked
stage_index). num_strips=12 is a fixed build-time constant, not a live
param -- see .specify/f_sirds/definition.py for full rationale.

depth_factor and bypass are broadcast to every depth-driven stage (not
just the primary/final one) -- this is why this module has its own
builder instead of going through tools/build_patcher.py, which only
wires live params to a single "primary" pix_chain node.

Run: python3 .specify/f_sirds/build_sirds.py
"""

import json
from pathlib import Path

REPO = Path(__file__).parent.parent.parent   # .specify/f_sirds/ → f_/
HERE = Path(__file__).parent

# ---------------------------------------------------------------------------
# Module identity / constants
# ---------------------------------------------------------------------------
NAME         = "f_sirds"
PREFIX       = "sirds"
TITLE        = "SIRDS"
PW, PH       = 190.0, 130.0

NUM_STRIPS   = 12
STRIP_WIDTH  = 1.0 / (NUM_STRIPS + 1)

FONT         = "Ableton Sans Light"
FONT_TITLE   = 12.0
FONT_LABEL   = 9.5
DIAL_COLOR   = [0.8, 0.8, 0.8, 1.0]
BG_COLOR     = [0.0, 0.0, 0.0, 1.0]
BORDER_COLOR = [0.0, 0.03529411765, 0.2274509804, 1.0]

CODEBOX_STAGE0_TMPL = open(HERE / "codebox_stage0.gen").read()
CODEBOX_STAGE_N_TMPL = open(HERE / "codebox_stage_n.gen").read()

PARAMS = [
    {"name": "depth_factor", "type": "float", "min": -0.3, "max": 0.3,
     "default": 0.0, "label": "depth"},
]

# ---------------------------------------------------------------------------
# Object IDs
# ---------------------------------------------------------------------------
OBJ_INLET       = "obj-1"    # pattern texture in
OBJ_OUTLET      = "obj-2"    # sirds out
OBJ_ROUTEPASS   = "obj-3"
OBJ_ROUTE       = "obj-4"

# Stage chain: obj-5 (stage0) .. obj-17 (stage12, primary)
STAGE_IDS = [f"obj-{5+i}" for i in range(NUM_STRIPS + 1)]
PRIMARY   = STAGE_IDS[-1]

OBJ_AUTOPATTR     = "obj-200"
OBJ_PANEL         = "obj-201"
OBJ_TITLE_BOX     = "obj-202"
OBJ_LOADBANG      = "obj-203"
OBJ_GETATTR       = "obj-204"
OBJ_THISPATCHER   = "obj-205"
OBJ_ZLSLICE       = "obj-206"
OBJ_PRETAM        = "obj-207"
OBJ_MODULESIZE    = "obj-208"

OBJ_DEPTH_INLET   = "obj-210"  # bpatcher inlet index 1
OBJ_DEPTH_INSTATE = "obj-211"

OBJ_DF_DIAL       = "obj-220"  # depth_factor
OBJ_DF_ATTRUI     = "obj-221"
OBJ_DF_LABEL      = "obj-222"

OBJ_BYPASS_JSUI   = "obj-230"
OBJ_BYPASS_ATTRUI = "obj-231"

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
def gen_stage0():
    """stage0: single inlet (pattern) -> codebox -> out 1. No depth, no mask."""
    code = CODEBOX_STAGE0_TMPL.format(strip_width=STRIP_WIDTH)
    return {
        "fileversion": 1,
        "appversion": {"major": 9, "minor": 1, "revision": 4,
                       "architecture": "x64", "modernui": 1},
        "classnamespace": "jit.gen",
        "rect": [100.0, 100.0, 500.0, 400.0],
        "boxes": [
            {"box": {"id": "gen-obj-1", "maxclass": "newobj",
                     "numinlets": 0, "numoutlets": 1, "outlettype": [""],
                     "patching_rect": [22.0, 30.0, 28.0, 22.0], "text": "in 1"}},
            {"box": {
                "id": "gen-obj-2", "maxclass": "codebox", "code": code,
                "fontface": 0, "fontname": "<Monospaced>", "fontsize": 12.0,
                "numinlets": 1, "numoutlets": 1,
                "patching_rect": [22.0, 80.0, 450.0, 200.0]}},
            {"box": {"id": "gen-obj-3", "maxclass": "newobj",
                     "numinlets": 1, "numoutlets": 0,
                     "patching_rect": [22.0, 300.0, 35.0, 22.0], "text": "out 1"}},
        ],
        "lines": [
            {"patchline": {"source": ["gen-obj-1", 0], "destination": ["gen-obj-2", 0]}},
            {"patchline": {"source": ["gen-obj-2", 0], "destination": ["gen-obj-3", 0]}},
        ]
    }

def gen_stage_n(stage_index):
    """Depth-driven stage: in1=chain texture, in2=depth -> codebox -> out 1."""
    code = CODEBOX_STAGE_N_TMPL.format(stage_index=float(stage_index),
                                        strip_width=STRIP_WIDTH)
    return {
        "fileversion": 1,
        "appversion": {"major": 9, "minor": 1, "revision": 4,
                       "architecture": "x64", "modernui": 1},
        "classnamespace": "jit.gen",
        "rect": [100.0, 100.0, 600.0, 500.0],
        "boxes": [
            {"box": {"id": "gen-obj-1", "maxclass": "newobj",
                     "numinlets": 0, "numoutlets": 1, "outlettype": [""],
                     "patching_rect": [22.0, 30.0, 28.0, 22.0], "text": "in 1"}},
            {"box": {"id": "gen-obj-2", "maxclass": "newobj",
                     "numinlets": 0, "numoutlets": 1, "outlettype": [""],
                     "patching_rect": [80.0, 30.0, 28.0, 22.0], "text": "in 2"}},
            {"box": {
                "id": "gen-obj-3", "maxclass": "codebox", "code": code,
                "fontface": 0, "fontname": "<Monospaced>", "fontsize": 12.0,
                "numinlets": 2, "numoutlets": 1,
                "patching_rect": [22.0, 80.0, 550.0, 320.0]}},
            {"box": {"id": "gen-obj-4", "maxclass": "newobj",
                     "numinlets": 1, "numoutlets": 0,
                     "patching_rect": [22.0, 420.0, 35.0, 22.0], "text": "out 1"}},
        ],
        "lines": [
            {"patchline": {"source": ["gen-obj-1", 0], "destination": ["gen-obj-3", 0]}},
            {"patchline": {"source": ["gen-obj-2", 0], "destination": ["gen-obj-3", 1]}},
            {"patchline": {"source": ["gen-obj-3", 0], "destination": ["gen-obj-4", 0]}},
        ]
    }

# ---------------------------------------------------------------------------
# UI box builders
# ---------------------------------------------------------------------------
def dial_box(p):
    x, y = 4.0, 38.0
    return box(OBJ_DF_DIAL,
        maxclass="live.dial",
        activedialcolor=DIAL_COLOR, fontname=FONT,
        numinlets=1, numoutlets=2, outlettype=["", "float"],
        parameter_enable=1,
        patching_rect=[50.0, 80.0, 27.0, 43.0],
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

def label_box(p):
    x, y = -7.5, 20.0
    return box(OBJ_DF_LABEL,
        maxclass="comment", fontname=FONT, fontsize=FONT_LABEL,
        numinlets=1, numoutlets=0,
        patching_rect=[50.0, 130.0, 50.0, 18.0],
        presentation=1,
        presentation_rect=[x, y, 50.0, 18.0],
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
            patching_rect=[700.0, 50.0,  60.0, 22.0], text="loadbang"),
        box(OBJ_GETATTR,     maxclass="message", numinlets=2, numoutlets=1, outlettype=[""],
            patching_rect=[700.0, 80.0,  180.0, 22.0], text="getattr presentation_rect"),
        box(OBJ_THISPATCHER, maxclass="newobj", numinlets=1, numoutlets=4, outlettype=["","","",""],
            patching_rect=[700.0, 110.0, 80.0, 22.0], text="thispatcher"),
        box(OBJ_ZLSLICE,     maxclass="newobj", numinlets=2, numoutlets=2, outlettype=["",""],
            patching_rect=[700.0, 140.0, 60.0, 22.0], text="zl slice 2"),
        box(OBJ_PRETAM,      maxclass="newobj", numinlets=1, numoutlets=1, outlettype=[""],
            patching_rect=[700.0, 170.0, 80.0, 22.0], text="prepend tam"),
        box(OBJ_MODULESIZE,  maxclass="newobj", numinlets=1, numoutlets=1, outlettype=[""],
            patching_rect=[700.0, 200.0, 100.0, 22.0],
            saved_object_attributes={"filename": "moduleSize.js", "parameter_enable": 0},
            text="js moduleSize.js"),
    ]

# ---------------------------------------------------------------------------
# Main builder
# ---------------------------------------------------------------------------
def build():
    boxes = [
        box(OBJ_INLET,  maxclass="inlet",  comment="pattern texture / control", index=0,
            numinlets=0, numoutlets=1, outlettype=[""],
            patching_rect=[30.0, 30.0, 30.0, 30.0]),
        box(OBJ_OUTLET, maxclass="outlet", comment="sirds", index=0,
            numinlets=1, numoutlets=0,
            patching_rect=[30.0, 600.0, 30.0, 30.0]),
        box(OBJ_ROUTEPASS, maxclass="newobj",
            numinlets=3, numoutlets=3, outlettype=["","",""],
            patching_rect=[200.0, 90.0, 215.0, 22.0],
            text="routepass jit_gl_texture jit_matrix"),
        box(OBJ_ROUTE, maxclass="newobj",
            numinlets=1, numoutlets=len(PARAMS), outlettype=[""] * len(PARAMS),
            patching_rect=[200.0, 130.0, 200.0, 22.0],
            text="route " + " ".join(p["name"] for p in PARAMS)),

        # depth inlet (bpatcher inlet index 1) + vs_inState
        box(OBJ_DEPTH_INLET, maxclass="inlet", comment="depth", index=1,
            numinlets=0, numoutlets=1, outlettype=[""],
            patching_rect=[90.0, 30.0, 30.0, 30.0]),
        box(OBJ_DEPTH_INSTATE, maxclass="newobj", text="vs_inState",
            numinlets=1, numoutlets=2, outlettype=["",""],
            patching_rect=[90.0, 80.0, 80.0, 22.0]),
    ]

    # Stage chain
    for i, sid in enumerate(STAGE_IDS):
        name = f"#0_sirds_stage{i}"
        if i == 0:
            boxes.append(box(sid, maxclass="newobj",
                numinlets=1, numoutlets=2, outlettype=["jit_gl_texture", ""],
                patcher=gen_stage0(),
                patching_rect=[400.0, 100.0 + i*30.0, 320.0, 22.0],
                text=f"jit.gl.pix vsynth @name {name} @adapt 1",
                varname=name))
        else:
            boxes.append(box(sid, maxclass="newobj",
                numinlets=2, numoutlets=2, outlettype=["jit_gl_texture", ""],
                patcher=gen_stage_n(i),
                patching_rect=[400.0, 100.0 + i*30.0, 320.0, 22.0],
                text=f"jit.gl.pix vsynth @name {name} @adapt 1",
                varname=name))

    # Infra: autopattr, panel, title, moduleSize
    boxes += [
        box(OBJ_AUTOPATTR, maxclass="newobj",
            numinlets=1, numoutlets=4, outlettype=["","","",""],
            patching_rect=[600.0, 600.0, 56.0, 22.0],
            text="autopattr", varname=f"{PREFIX}_autopattr"),
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
    ]
    boxes += modulesize_boxes()

    # depth_factor UI
    boxes.append(dial_box(PARAMS[0]))
    boxes.append(attrui_box(OBJ_DF_ATTRUI, "depth_factor", 50.0, 170.0))
    boxes.append(label_box(PARAMS[0]))

    # bypass UI
    boxes.append(box(OBJ_BYPASS_JSUI,
        maxclass="jsui", filename="bypass_toggle.js", hint="Bypass",
        numinlets=1, numoutlets=1, outlettype=[""],
        presentation=1,
        patching_rect=[PW - 22.0, 5.0, 18.0, 12.0],
        presentation_rect=[PW - 22.0, 5.0, 18.0, 12.0],
        valuepopuplabel=1, varname="bypass"))
    boxes.append(box(OBJ_BYPASS_ATTRUI,
        maxclass="attrui", attr="bypass",
        numinlets=1, numoutlets=1, outlettype=[""],
        patching_rect=[600.0, 60.0, 131.0, 22.0], style=""))

    # ------------------------------------------------------------------
    # Patchlines
    # ------------------------------------------------------------------
    lines = [
        wire(OBJ_INLET,     0, OBJ_ROUTEPASS, 0),
        wire(OBJ_ROUTEPASS, 0, STAGE_IDS[0],  0),   # pattern -> stage0
        wire(OBJ_ROUTEPASS, 2, OBJ_ROUTE,     0),   # unmatched -> route

        # depth inlet -> vs_inState (broadcast to all depth-driven stages below)
        wire(OBJ_DEPTH_INLET, 0, OBJ_DEPTH_INSTATE, 0),

        # route -> depth_factor dial -> attrui (broadcast below)
        wire(OBJ_ROUTE,    0, OBJ_DF_DIAL,   0),
        wire(OBJ_DF_DIAL,  0, OBJ_DF_ATTRUI, 0),

        # bypass jsui -> attrui (broadcast below)
        wire(OBJ_BYPASS_JSUI, 0, OBJ_BYPASS_ATTRUI, 0),

        # chain: stage[i] -> stage[i+1]
    ] + [
        wire(STAGE_IDS[i], 0, STAGE_IDS[i+1], 0) for i in range(NUM_STRIPS)
    ] + [
        # primary (final stage) -> module outlet
        wire(PRIMARY, 0, OBJ_OUTLET, 0),
    ]

    # Broadcast depth_factor, bypass, and depth texture to every
    # depth-driven stage (stage1..stage12) -- the reason this module
    # needed its own builder instead of tools/build_patcher.py.
    for sid in STAGE_IDS[1:]:
        lines.append(wire(OBJ_DF_ATTRUI,     0, sid, 0))  # depth_factor -> in0
        lines.append(wire(OBJ_BYPASS_ATTRUI, 0, sid, 0))  # bypass -> in0
        lines.append(wire(OBJ_DEPTH_INSTATE, 0, sid, 1))  # depth tex -> in1

    # moduleSize chain
    lines += [
        wire(OBJ_LOADBANG,    0, OBJ_GETATTR,     0),
        wire(OBJ_GETATTR,     0, OBJ_THISPATCHER, 0),
        wire(OBJ_THISPATCHER, 0, OBJ_ZLSLICE,     0),
        wire(OBJ_ZLSLICE,     1, OBJ_PRETAM,      0),
        wire(OBJ_PRETAM,      0, OBJ_MODULESIZE,  0),
    ]

    # parameters block
    params_block = {OBJ_DF_DIAL: ["depth_factor", "depth_factor", 0]}
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
        "rect": [100.0, 100.0, 900.0, 700.0],
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
    print(f"num_strips={NUM_STRIPS}, strip_width={STRIP_WIDTH:.6f}")
    print(f"Stages: {STAGE_IDS[0]} (seed) .. {PRIMARY} (primary/output)")
