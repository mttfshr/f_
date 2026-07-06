#!/usr/bin/env python3
"""
build_seeds_multistage.py — generates f_vf_seeds.maxpat

6-stage chain: Stage 1a/1b (search halves, one shared codebox with baked
hash-salt constants distinguishing the two) + Stage 1c (merge) + Stage 2/3
(render, one shared codebox) + Stage 4 (composite). Needed its own builder
because tools/build_patcher.py's pix_chain mechanism only wires live params
to a single "primary" node via param_connect (Live's per-object parameter
binding) — most of this module's params need to fan out to TWO differently-
named pix objects at once (e.g. density -> both search halves), which
param_connect can't do. Same category of limitation that gave f_sirds its
own builder (see build_sirds.py's own docstring).

Outer contract is backward-compatible with the pre-Evolution-2 single-
codebox module: same 3 inlets (shape tex+control combined / vecfield /
mod tex), same 3 outlets (mark color / mark mask / seed coord — "seed
coord" now specifically means rank 1's position, sourced directly from
Stage 1c, bypassing Stage 4 entirely).

Full architecture, rationale, and empirical findings:
  .specify/f_vf_seeds/spec.md   (Evolution 1.5 + Evolution 2 sections)
  .specify/f_vf_seeds/plan.md   (ADR 6-8 + addenda)
This file documents the CONCRETE wiring; those files document WHY.

Run: python3 .specify/f_vf_seeds/build_seeds_multistage.py
"""

import json
from pathlib import Path

REPO = Path(__file__).parent.parent.parent   # .specify/f_vf_seeds/ → f_/
HERE = Path(__file__).parent

NAME   = "f_vf_seeds"
PREFIX = "vfseeds"
TITLE  = "Seeds"
PW, PH = 190.0, 160.0

FONT         = "Ableton Sans Light"
FONT_TITLE   = 12.0
FONT_LABEL   = 9.5
DIAL_COLOR   = [0.8, 0.8, 0.8, 1.0]
BG_COLOR     = [0.0, 0.0, 0.0, 1.0]
BORDER_COLOR = [0.0, 0.03529411765, 0.2274509804, 1.0]
SIGNAL_TYPE_COLOR = [0.302, 0.325, 0.463, 1.0]   # vecfield

APPVER = {"major": 9, "minor": 1, "revision": 4,
          "architecture": "x64", "modernui": 1}

CODEBOX_SEARCH_TMPL = open(HERE / "codebox_seeds_search.gen").read()
CODEBOX_MERGE        = open(HERE / "codebox_seeds_merge.gen").read()
CODEBOX_RENDER       = open(HERE / "codebox_seeds_render.gen").read()
CODEBOX_COMPOSITE    = open(HERE / "codebox_seeds_composite.gen").read()

SALTS_A = (127.1, 311.7, 269.5, 183.3)   # Stage 1a — original 9
SALTS_B = (419.2, 371.9, 133.7, 197.3)   # Stage 1b — bombing 9

# ---------------------------------------------------------------------------
# Params — name, range, default, label/hint, and which internal stage(s)
# each fans out to. "targets" values map through STAGE_OBJ below. Optional
# "attr_name" overrides which attribute the param's attrui is bound to
# (defaults to the param's own name) — used by "bomb", whose attrui is
# bound directly to "active_blend" rather than "bomb" (see build()).
# ---------------------------------------------------------------------------
PARAMS = [
    {"name": "density", "min": 0.0, "max": 1.0, "default": 0.5,
     "label": "Density",
     "hint": "Seed spacing — log-mapped, higher = more seeds",
     "targets": ["1a", "1b"]},
    {"name": "jitter", "min": 0.0, "max": 1.0, "default": 0.5,
     "label": "Jitter",
     "hint": "Seed position randomness (0=regular grid, 1=fully stochastic)",
     "targets": ["1a", "1b"]},
    {"name": "size", "min": 0.0, "max": 0.5, "default": 0.2,
     "label": "Size",
     "hint": "Mark size — overall scale",
     "targets": ["2", "3"]},
    {"name": "stretch", "min": 0.0, "max": 1.0, "default": 0.0,
     "label": "Stretch",
     "hint": "Aspect ratio — 0=circular/square, increasing elongates along field direction",
     "targets": ["2", "3"]},
    {"name": "strength", "min": 0.0, "max": 1.0, "default": 1.0,
     "label": "Strength",
     "hint": "Vecfield influence on mark orientation (0=rightward, 1=full field)",
     "targets": ["2", "3"]},
    {"name": "mag_weight", "min": 0.0, "max": 1.0, "default": 0.0,
     "label": "Mag\u2192Wt",
     "hint": "Field magnitude \u2192 mark weight modulation depth",
     "targets": ["2", "3"]},
    {"name": "field_priority", "min": 0.0, "max": 1.0, "default": 0.0,
     "label": "Field Pri",
     "hint": "Seed selection: 0=nearest-distance (Voronoi, original behavior), 1=field-magnitude-only (degenerate at exactly 1.0 — see docs)",
     "targets": ["1a", "1b"]},
    {"name": "field_gain", "min": -1.5, "max": 1.5, "default": 0.0,
     "label": "Field Gain",
     "hint": "Field-priority scale — useful window varies by vecfield source (Flow ~0.2, Repulse ~0.8, Vortex ~1.5).",
     "range_tiers": [0.2, 0.8, 1.5],
     "targets": ["1a", "1b"]},
    {"name": "bomb", "min": 0.0, "max": 1.0, "default": 0.0,
     "label": "Bomb",
     "hint": "Second-sample-per-cell toggle — behaves as on/off, not a graded fader (see spec.md Evolution 2). Its attrui is bound directly to active_blend on Stage 1b — the dial itself keeps showing \"Bomb\".",
     "attr_name": "active_blend",
     "targets": ["1b"]},
    {"name": "phase", "min": -1.0, "max": 1.0, "default": 0.0,
     "label": "Phase",
     "hint": "Scroll marks along field direction (connect LFO for motion)",
     "targets": ["2", "3"]},
    {"name": "size_mod", "min": -1.0, "max": 1.0, "default": 0.0,
     "label": "Size Mod",
     "hint": "Mod tex \u2192 size modulation depth (bipolar)",
     "targets": ["2", "3"]},
    {"name": "stretch_mod", "min": -1.0, "max": 1.0, "default": 0.0,
     "label": "Str Mod",
     "hint": "Mod tex \u2192 stretch modulation depth (bipolar)",
     "targets": ["2", "3"]},
]

BYPASS_TARGETS = ["1c", "4"]

# ---------------------------------------------------------------------------
# Object ID scheme (deterministic)
# ---------------------------------------------------------------------------
OBJ_INLET_SHAPE     = "obj-1"    # index0, shape tex + control (driving)
OBJ_INLET_VECFIELD  = "obj-2"    # index1
OBJ_INLET_MODTEX    = "obj-3"    # index2
OBJ_OUTLET_COLOR    = "obj-4"    # index0, mark color
OBJ_OUTLET_MASK      = "obj-5"    # index1, mark mask
OBJ_OUTLET_COORD    = "obj-6"    # index2, seed coord (rank1 only)

OBJ_ROUTEPASS = "obj-10"
OBJ_ROUTE     = "obj-11"

OBJ_SHAPE_INSTATE    = "obj-12"
OBJ_SHAPE_PRE        = "obj-13"   # prepend param src_shape
OBJ_VECFIELD_INSTATE = "obj-14"
OBJ_VECFIELD_PRE     = "obj-15"   # prepend param src_vecfield (unused in math, kept for convention)
OBJ_MODTEX_INSTATE   = "obj-16"
OBJ_MODTEX_PRE       = "obj-17"   # prepend param src_mod

OBJ_STAGE_1A = "obj-20"
OBJ_STAGE_1B = "obj-21"
OBJ_STAGE_1C = "obj-22"
OBJ_STAGE_2  = "obj-23"
OBJ_STAGE_3  = "obj-24"
OBJ_STAGE_4  = "obj-25"

STAGE_OBJ = {"1a": OBJ_STAGE_1A, "1b": OBJ_STAGE_1B, "1c": OBJ_STAGE_1C,
             "2": OBJ_STAGE_2, "3": OBJ_STAGE_3, "4": OBJ_STAGE_4}


OBJ_AUTOPATTR   = "obj-100"
OBJ_PANEL       = "obj-101"
OBJ_TITLE       = "obj-102"
OBJ_SIGNAL_TYPE = "obj-103"
OBJ_LOADBANG    = "obj-104"
OBJ_GETATTR     = "obj-105"
OBJ_THISPATCHER = "obj-106"
OBJ_ZLSLICE     = "obj-107"
OBJ_PRETAM      = "obj-108"
OBJ_MODULESIZE  = "obj-109"

OBJ_BYPASS_JSUI   = "obj-110"
OBJ_BYPASS_ATTRUI = "obj-111"

def dial_id(n):   return f"obj-{200 + n*3 + 0}"
def attrui_id(n): return f"obj-{200 + n*3 + 1}"
def label_id(n):  return f"obj-{200 + n*3 + 2}"

def range_menu_id(n):   return f"obj-{400 + n*10 + 0}"
def range_sel_id(n):    return f"obj-{400 + n*10 + 1}"
def range_msg_id(n, t): return f"obj-{400 + n*10 + 2 + t}"

# ---------------------------------------------------------------------------
# Generic helpers
# ---------------------------------------------------------------------------
def box(id, **kw):
    return {"box": {"id": id, **kw}}

def wire(src, out, dst, inn):
    return {"patchline": {"source": [src, out], "destination": [dst, inn]}}

# ---------------------------------------------------------------------------
# Gen subpatcher builders — one per stage shape (search halves share this
# same shape, just formatted with different salts)
# ---------------------------------------------------------------------------
def gen_search(salts):
    code = CODEBOX_SEARCH_TMPL.format(salt1=salts[0], salt2=salts[1],
                                       salt3=salts[2], salt4=salts[3])
    return {
        "fileversion": 1, "appversion": APPVER, "classnamespace": "jit.gen",
        "rect": [59.0, 114.0, 600.0, 450.0],
        "boxes": [
            {"box": {"id": "gen-obj-1", "maxclass": "newobj",
                     "numinlets": 0, "numoutlets": 1, "outlettype": [""],
                     "patching_rect": [50.0, 14.0, 28.0, 22.0], "text": "in 1"}},
            {"box": {"id": "gen-obj-2", "maxclass": "codebox", "code": code,
                     "fontface": 0, "fontname": "<Monospaced>", "fontsize": 12.0,
                     "numinlets": 1, "numoutlets": 3, "outlettype": ["", "", ""],
                     "patching_rect": [29.0, 56.0, 487.0, 293.0]}},
            {"box": {"id": "gen-obj-3", "maxclass": "newobj",
                     "numinlets": 1, "numoutlets": 0,
                     "patching_rect": [176.0, 418.0, 35.0, 22.0], "text": "out 1"}},
            {"box": {"id": "gen-obj-4", "maxclass": "newobj",
                     "numinlets": 1, "numoutlets": 0,
                     "patching_rect": [360.0, 396.0, 35.0, 22.0], "text": "out 2"}},
            {"box": {"id": "gen-obj-5", "maxclass": "newobj",
                     "numinlets": 1, "numoutlets": 0,
                     "patching_rect": [481.0, 414.0, 35.0, 22.0], "text": "out 3"}},
        ],
        "lines": [
            wire("gen-obj-1", 0, "gen-obj-2", 0),
            wire("gen-obj-2", 0, "gen-obj-3", 0),
            wire("gen-obj-2", 1, "gen-obj-4", 0),
            wire("gen-obj-2", 2, "gen-obj-5", 0),
        ]
    }

def gen_merge():
    return {
        "fileversion": 1, "appversion": APPVER, "classnamespace": "jit.gen",
        "rect": [59.0, 114.0, 600.0, 450.0],
        "boxes": [
            {"box": {"id": "gen-obj-1", "maxclass": "newobj",
                     "numinlets": 0, "numoutlets": 1, "outlettype": [""],
                     "patching_rect": [50.0, 14.0, 28.0, 22.0], "text": "in 1"}},
            {"box": {"id": "gen-obj-2", "maxclass": "newobj",
                     "numinlets": 0, "numoutlets": 1, "outlettype": [""],
                     "patching_rect": [305.0, 14.0, 28.0, 22.0], "text": "in 2"}},
            {"box": {"id": "gen-obj-6", "maxclass": "newobj",
                     "numinlets": 0, "numoutlets": 1, "outlettype": [""],
                     "patching_rect": [335.0, 44.0, 28.0, 22.0], "text": "in 3"}},
            {"box": {"id": "gen-obj-7", "maxclass": "newobj",
                     "numinlets": 0, "numoutlets": 1, "outlettype": [""],
                     "patching_rect": [371.0, 91.0, 28.0, 22.0], "text": "in 4"}},
            {"box": {"id": "gen-obj-8", "maxclass": "newobj",
                     "numinlets": 0, "numoutlets": 1, "outlettype": [""],
                     "patching_rect": [423.0, 97.0, 28.0, 22.0], "text": "in 5"}},
            {"box": {"id": "gen-obj-9", "maxclass": "newobj",
                     "numinlets": 0, "numoutlets": 1, "outlettype": [""],
                     "patching_rect": [480.0, 97.0, 28.0, 22.0], "text": "in 6"}},
            {"box": {"id": "gen-obj-3", "maxclass": "codebox", "code": CODEBOX_MERGE,
                     "fontface": 0, "fontname": "<Monospaced>", "fontsize": 12.0,
                     "numinlets": 6, "numoutlets": 3, "outlettype": ["", "", ""],
                     "patching_rect": [176.0, 149.0, 340.0, 220.0]}},
            {"box": {"id": "gen-obj-4", "maxclass": "newobj",
                     "numinlets": 1, "numoutlets": 0,
                     "patching_rect": [176.0, 418.0, 35.0, 22.0], "text": "out 1"}},
            {"box": {"id": "gen-obj-5", "maxclass": "newobj",
                     "numinlets": 1, "numoutlets": 0,
                     "patching_rect": [360.0, 396.0, 35.0, 22.0], "text": "out 2"}},
            {"box": {"id": "gen-obj-10", "maxclass": "newobj",
                     "numinlets": 1, "numoutlets": 0,
                     "patching_rect": [481.0, 414.0, 35.0, 22.0], "text": "out 3"}},
        ],
        "lines": [
            wire("gen-obj-1", 0, "gen-obj-3", 0),
            wire("gen-obj-2", 0, "gen-obj-3", 1),
            wire("gen-obj-6", 0, "gen-obj-3", 2),
            wire("gen-obj-7", 0, "gen-obj-3", 3),
            wire("gen-obj-8", 0, "gen-obj-3", 4),
            wire("gen-obj-9", 0, "gen-obj-3", 5),
            wire("gen-obj-3", 0, "gen-obj-4", 0),
            wire("gen-obj-3", 1, "gen-obj-5", 0),
            wire("gen-obj-3", 2, "gen-obj-10", 0),
        ]
    }

def gen_render():
    return {
        "fileversion": 1, "appversion": APPVER, "classnamespace": "jit.gen",
        "rect": [59.0, 114.0, 600.0, 450.0],
        "boxes": [
            {"box": {"id": "gen-obj-1", "maxclass": "newobj",
                     "numinlets": 0, "numoutlets": 1, "outlettype": [""],
                     "patching_rect": [50.0, 14.0, 28.0, 22.0], "text": "in 1"}},
            {"box": {"id": "gen-obj-2", "maxclass": "newobj",
                     "numinlets": 0, "numoutlets": 1, "outlettype": [""],
                     "patching_rect": [173.0, 8.0, 28.0, 22.0], "text": "in 2"}},
            {"box": {"id": "gen-obj-5", "maxclass": "newobj",
                     "numinlets": 0, "numoutlets": 1, "outlettype": [""],
                     "patching_rect": [285.0, 23.0, 28.0, 22.0], "text": "in 3"}},
            {"box": {"id": "gen-obj-6", "maxclass": "newobj",
                     "numinlets": 0, "numoutlets": 1, "outlettype": [""],
                     "patching_rect": [443.0, 14.0, 28.0, 22.0], "text": "in 4"}},
            {"box": {"id": "gen-obj-3", "maxclass": "codebox", "code": CODEBOX_RENDER,
                     "fontface": 0, "fontname": "<Monospaced>", "fontsize": 12.0,
                     "numinlets": 4, "numoutlets": 1, "outlettype": [""],
                     "patching_rect": [29.0, 56.0, 539.0, 685.0]}},
            {"box": {"id": "gen-obj-4", "maxclass": "newobj",
                     "numinlets": 1, "numoutlets": 0,
                     "patching_rect": [176.0, 418.0, 35.0, 22.0], "text": "out 1"}},
        ],
        "lines": [
            wire("gen-obj-1", 0, "gen-obj-3", 0),
            wire("gen-obj-2", 0, "gen-obj-3", 1),
            wire("gen-obj-5", 0, "gen-obj-3", 2),
            wire("gen-obj-6", 0, "gen-obj-3", 3),
            wire("gen-obj-3", 0, "gen-obj-4", 0),
        ]
    }

def gen_composite():
    return {
        "fileversion": 1, "appversion": APPVER, "classnamespace": "jit.gen",
        "rect": [59.0, 114.0, 597.0, 662.0],
        "boxes": [
            {"box": {"id": "gen-obj-1", "maxclass": "newobj",
                     "numinlets": 0, "numoutlets": 1, "outlettype": [""],
                     "patching_rect": [50.0, 14.0, 28.0, 22.0], "text": "in 1"}},
            {"box": {"id": "gen-obj-2", "maxclass": "newobj",
                     "numinlets": 0, "numoutlets": 1, "outlettype": [""],
                     "patching_rect": [305.0, 14.0, 28.0, 22.0], "text": "in 2"}},
            {"box": {"id": "gen-obj-3", "maxclass": "codebox", "code": CODEBOX_COMPOSITE,
                     "fontface": 0, "fontname": "<Monospaced>", "fontsize": 12.0,
                     "numinlets": 2, "numoutlets": 2, "outlettype": ["", ""],
                     "patching_rect": [28.0, 78.0, 536.0, 524.0]}},
            {"box": {"id": "gen-obj-4", "maxclass": "newobj",
                     "numinlets": 1, "numoutlets": 0,
                     "patching_rect": [11.0, 630.0, 35.0, 22.0], "text": "out 1"}},
            {"box": {"id": "gen-obj-5", "maxclass": "newobj",
                     "numinlets": 1, "numoutlets": 0,
                     "patching_rect": [200.0, 630.0, 35.0, 22.0], "text": "out 2"}},
        ],
        "lines": [
            wire("gen-obj-1", 0, "gen-obj-3", 0),
            wire("gen-obj-2", 0, "gen-obj-3", 1),
            wire("gen-obj-3", 0, "gen-obj-4", 0),
            wire("gen-obj-3", 1, "gen-obj-5", 0),
        ]
    }

# ---------------------------------------------------------------------------
# UI box builders (styling matches tools/build_patcher.py conventions)
# ---------------------------------------------------------------------------
def dial_box(n, p):
    col, row = n % 5, n // 5
    x, y = 4.0 + col * 37.0, 38.0 + row * 62.0
    return box(dial_id(n),
        maxclass="live.dial", activedialcolor=DIAL_COLOR, fontname=FONT,
        hint=p.get("hint", ""),
        numinlets=1, numoutlets=2, outlettype=["", "float"],
        parameter_enable=1,
        patching_rect=[50.0 + n * 50.0, 80.0, 27.0, 43.0],
        presentation=1, presentation_rect=[x, y, 27.0, 43.0],
        saved_attribute_attributes={
            "activedialcolor": {"expression": ""},
            "valueof": {
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
    col, row = n % 5, n // 5
    x, y = 4.0 + col * 37.0, 20.0 + row * 62.0
    return box(label_id(n),
        maxclass="comment", fontname=FONT, fontsize=FONT_LABEL,
        numinlets=1, numoutlets=0,
        patching_rect=[50.0 + n * 50.0, 130.0, 50.0, 18.0],
        presentation=1, presentation_rect=[x - 11.5, y, 50.0, 18.0],
        text=p.get("label", p["name"]), textjustification=1)

def attrui_box(obj_id, name, x, y):
    return box(obj_id,
        maxclass="attrui", attr=name,
        numinlets=1, numoutlets=1, outlettype=[""],
        patching_rect=[x, y, max(100.0, len(name) * 7.0 + 80.0), 22.0],
        style="")

def range_tier_boxes(n, p):
    """Numeric-range picker for field_gain — mirrors build_patcher.py's
    range_tier_boxes exactly (menu + sel + one _parameter_range message
    per tier, all targeting the param's own live.dial)."""
    tiers = p["range_tiers"]
    n_tiers = len(tiers)
    col = n % 5
    dial_x = 4.0 + col * 37.0
    menu = box(range_menu_id(n),
        maxclass="live.menu", fontname=FONT, fontsize=9.0,
        numinlets=1, numoutlets=3, outlettype=["", "", "float"],
        parameter_enable=1,
        patching_rect=[500.0 + n * 120.0, 200.0, 100.0, 15.0],
        presentation=1, presentation_rect=[dial_x + 22.5, 21.5, 16.0, 15.0],
        saved_attribute_attributes={"valueof": {
            "parameter_enum": [str(t) for t in tiers],
            "parameter_longname": f"range_{p['name']}",
            "parameter_shortname": f"range_{p['name']}",
            "parameter_type": 2}})
    sel = box(range_sel_id(n),
        maxclass="newobj", numinlets=1, numoutlets=n_tiers,
        outlettype=[""] * n_tiers,
        patching_rect=[500.0 + n * 120.0, 240.0, 60.0, 22.0],
        text="sel " + " ".join(str(i) for i in range(n_tiers)))
    msgs = []
    for t, upper in enumerate(tiers):
        msgs.append(box(range_msg_id(n, t),
            maxclass="message", numinlets=2, numoutlets=1, outlettype=[""],
            patching_rect=[500.0 + n * 120.0 + t * 150.0, 280.0 + t * 30.0, 134.0, 22.0],
            text=f"_parameter_range 0. {upper}"))
    return [menu, sel] + msgs

def panel_box():
    return box(OBJ_PANEL,
        maxclass="panel", angle=270.0, background=1, bgcolor=BG_COLOR,
        border=1, bordercolor=BORDER_COLOR, mode=0,
        numinlets=1, numoutlets=0,
        patching_rect=[20.0, 20.0, PW, PH],
        presentation=1, presentation_rect=[0.0, 0.0, PW, PH],
        proportion=0.5)

def title_box():
    return box(OBJ_TITLE,
        maxclass="comment", fontname=FONT, fontsize=FONT_TITLE,
        numinlets=1, numoutlets=0,
        patching_rect=[20.0, 20.0, 80.0, 21.0],
        presentation=1, presentation_rect=[-1.5, 0.0, 80.0, 21.0],
        text=TITLE)

def signal_type_box():
    title_w = max(40.0, len(TITLE) * 7.2)
    return box(OBJ_SIGNAL_TYPE,
        maxclass="comment", fontname=FONT, fontsize=FONT_TITLE,
        textcolor=SIGNAL_TYPE_COLOR,
        numinlets=1, numoutlets=0,
        patching_rect=[20.0, 20.0, 60.0, 21.0],
        presentation=1, presentation_rect=[title_w - 2.0, 2.5, 60.0, 18.0],
        text="vecfield")

def modulesize_boxes():
    return [
        box(OBJ_LOADBANG, maxclass="newobj", numinlets=1, numoutlets=1, outlettype=[""],
            patching_rect=[700.0, 50.0, 60.0, 22.0], text="loadbang"),
        box(OBJ_GETATTR, maxclass="message", numinlets=2, numoutlets=1, outlettype=[""],
            patching_rect=[700.0, 80.0, 180.0, 22.0], text="getattr presentation_rect"),
        box(OBJ_THISPATCHER, maxclass="newobj", numinlets=1, numoutlets=4,
            outlettype=["", "", "", ""],
            patching_rect=[700.0, 110.0, 80.0, 22.0], text="thispatcher"),
        box(OBJ_ZLSLICE, maxclass="newobj", numinlets=2, numoutlets=2, outlettype=["", ""],
            patching_rect=[700.0, 140.0, 60.0, 22.0], text="zl slice 2"),
        box(OBJ_PRETAM, maxclass="newobj", numinlets=1, numoutlets=1, outlettype=[""],
            patching_rect=[700.0, 170.0, 80.0, 22.0], text="prepend tam"),
        box(OBJ_MODULESIZE, maxclass="newobj", numinlets=1, numoutlets=1, outlettype=[""],
            patching_rect=[700.0, 200.0, 100.0, 22.0],
            saved_object_attributes={"filename": "moduleSize.js", "parameter_enable": 0},
            text="js moduleSize.js"),
    ]

# ---------------------------------------------------------------------------
# Main builder
# ---------------------------------------------------------------------------
def build():
    boxes = []
    lines = []

    # ---- Outer inlets / outlets -------------------------------------------
    boxes += [
        box(OBJ_INLET_SHAPE, maxclass="inlet", comment="shape tex / control",
            index=0, numinlets=0, numoutlets=1, outlettype=[""],
            patching_rect=[30.0, 30.0, 30.0, 30.0]),
        box(OBJ_INLET_VECFIELD, maxclass="inlet", comment="vecfield",
            index=1, numinlets=0, numoutlets=1, outlettype=[""],
            patching_rect=[90.0, 30.0, 30.0, 30.0]),
        box(OBJ_INLET_MODTEX, maxclass="inlet", comment="mod tex",
            index=2, numinlets=0, numoutlets=1, outlettype=[""],
            patching_rect=[150.0, 30.0, 30.0, 30.0]),
        box(OBJ_OUTLET_COLOR, maxclass="outlet", comment="mark color",
            index=0, numinlets=1, numoutlets=0,
            patching_rect=[30.0, 780.0, 30.0, 30.0]),
        box(OBJ_OUTLET_MASK, maxclass="outlet", comment="mark mask",
            index=1, numinlets=1, numoutlets=0,
            patching_rect=[90.0, 780.0, 30.0, 30.0]),
        box(OBJ_OUTLET_COORD, maxclass="outlet", comment="seed coord",
            index=2, numinlets=1, numoutlets=0,
            patching_rect=[150.0, 780.0, 30.0, 30.0]),
    ]

    # ---- Control-message dispatch: routepass splits texture from control,
    # route dispatches named param messages to their dials -----------------
    boxes.append(box(OBJ_ROUTEPASS, maxclass="newobj",
        numinlets=3, numoutlets=3, outlettype=["", "", ""],
        patching_rect=[200.0, 90.0, 215.0, 22.0],
        text="routepass jit_gl_texture jit_matrix"))
    route_names = " ".join(p["name"] for p in PARAMS)
    boxes.append(box(OBJ_ROUTE, maxclass="newobj",
        numinlets=1, numoutlets=len(PARAMS), outlettype=[""] * len(PARAMS),
        patching_rect=[200.0, 130.0, max(150.0, len(route_names) * 7.0), 22.0],
        text=f"route {route_names}"))
    lines += [
        wire(OBJ_INLET_SHAPE, 0, OBJ_ROUTEPASS, 0),
        wire(OBJ_ROUTEPASS, 2, OBJ_ROUTE, 0),
    ]

    # ---- vs_inState for each of the 3 content inlets (src_shape/
    # src_vecfield/src_mod connected-state tracking, Vsynth convention).
    # src_shape and src_mod are actually consumed in codebox_seeds_render's
    # math; src_vecfield is tracked but unused in the math, matching its
    # already-vestigial status in the pre-Evolution-2 shipped module. -----
    boxes += [
        box(OBJ_SHAPE_INSTATE, maxclass="newobj", numinlets=1, numoutlets=2,
            outlettype=["", ""], patching_rect=[200.0, 60.0, 80.0, 22.0],
            text="vs_inState"),
        box(OBJ_SHAPE_PRE, maxclass="newobj", numinlets=1, numoutlets=1,
            outlettype=[""], patching_rect=[350.0, 60.0, 160.0, 22.0],
            text="prepend param src_shape"),
        box(OBJ_VECFIELD_INSTATE, maxclass="newobj", numinlets=1, numoutlets=2,
            outlettype=["", ""], patching_rect=[200.0, 30.0, 80.0, 22.0],
            text="vs_inState"),
        box(OBJ_VECFIELD_PRE, maxclass="newobj", numinlets=1, numoutlets=1,
            outlettype=[""], patching_rect=[350.0, 30.0, 170.0, 22.0],
            text="prepend param src_vecfield"),
        box(OBJ_MODTEX_INSTATE, maxclass="newobj", numinlets=1, numoutlets=2,
            outlettype=["", ""], patching_rect=[200.0, 0.0, 80.0, 22.0],
            text="vs_inState"),
        box(OBJ_MODTEX_PRE, maxclass="newobj", numinlets=1, numoutlets=1,
            outlettype=[""], patching_rect=[350.0, 0.0, 150.0, 22.0],
            text="prepend param src_mod"),
    ]
    lines += [
        # shape tex: driving inlet, shares OBJ_ROUTEPASS's texture outlet
        wire(OBJ_ROUTEPASS, 0, OBJ_SHAPE_INSTATE, 0),
        wire(OBJ_SHAPE_INSTATE, 1, OBJ_SHAPE_PRE, 0),
        # vecfield: its own dedicated inlet
        wire(OBJ_INLET_VECFIELD, 0, OBJ_VECFIELD_INSTATE, 0),
        wire(OBJ_VECFIELD_INSTATE, 1, OBJ_VECFIELD_PRE, 0),
        # mod tex: its own dedicated inlet
        wire(OBJ_INLET_MODTEX, 0, OBJ_MODTEX_INSTATE, 0),
        wire(OBJ_MODTEX_INSTATE, 1, OBJ_MODTEX_PRE, 0),
    ]

    # ---- Six internal pix stages -------------------------------------------
    boxes += [
        box(OBJ_STAGE_1A, maxclass="newobj",
            numinlets=1, numoutlets=4,
            outlettype=["jit_gl_texture", "jit_gl_texture", "jit_gl_texture", ""],
            patcher=gen_search(SALTS_A),
            patching_rect=[200.0, 300.0, 140.0, 22.0],
            text=f"jit.gl.pix vsynth @name {PREFIX}_search_a @type float32",
            varname=f"{PREFIX}_search_a"),
        box(OBJ_STAGE_1B, maxclass="newobj",
            numinlets=1, numoutlets=4,
            outlettype=["jit_gl_texture", "jit_gl_texture", "jit_gl_texture", ""],
            patcher=gen_search(SALTS_B),
            patching_rect=[400.0, 300.0, 140.0, 22.0],
            text=f"jit.gl.pix vsynth @name {PREFIX}_search_b @type float32",
            varname=f"{PREFIX}_search_b"),
        box(OBJ_STAGE_1C, maxclass="newobj",
            numinlets=6, numoutlets=4,
            outlettype=["jit_gl_texture", "jit_gl_texture", "jit_gl_texture", ""],
            patcher=gen_merge(),
            patching_rect=[300.0, 360.0, 140.0, 22.0],
            text=f"jit.gl.pix vsynth @name {PREFIX}_merge @type float32",
            varname=f"{PREFIX}_merge"),
        box(OBJ_STAGE_2, maxclass="newobj",
            numinlets=4, numoutlets=2,
            outlettype=["jit_gl_texture", ""],
            patcher=gen_render(),
            patching_rect=[200.0, 420.0, 140.0, 22.0],
            text=f"jit.gl.pix vsynth @name {PREFIX}_render_1",
            varname=f"{PREFIX}_render_1"),
        box(OBJ_STAGE_3, maxclass="newobj",
            numinlets=4, numoutlets=2,
            outlettype=["jit_gl_texture", ""],
            patcher=gen_render(),
            patching_rect=[400.0, 420.0, 140.0, 22.0],
            text=f"jit.gl.pix vsynth @name {PREFIX}_render_2",
            varname=f"{PREFIX}_render_2"),
        box(OBJ_STAGE_4, maxclass="newobj",
            numinlets=2, numoutlets=3,
            outlettype=["jit_gl_texture", "jit_gl_texture", ""],
            patcher=gen_composite(),
            patching_rect=[300.0, 480.0, 140.0, 22.0],
            text=f"jit.gl.pix vsynth @name {PREFIX}_composite",
            varname=f"{PREFIX}_composite"),
    ]

    # Texture passthrough (vs_inState outlet 0) -> stages that consume it
    lines += [
        # vecfield -> Stage 1a, 1b, 2, 3 (each stage's vecfield inlet)
        wire(OBJ_VECFIELD_INSTATE, 0, OBJ_STAGE_1A, 0),
        wire(OBJ_VECFIELD_INSTATE, 0, OBJ_STAGE_1B, 0),
        wire(OBJ_VECFIELD_INSTATE, 0, OBJ_STAGE_2, 2),
        wire(OBJ_VECFIELD_INSTATE, 0, OBJ_STAGE_3, 2),
        # shape tex -> Stage 2, 3
        wire(OBJ_SHAPE_INSTATE, 0, OBJ_STAGE_2, 1),
        wire(OBJ_SHAPE_INSTATE, 0, OBJ_STAGE_3, 1),
        # mod tex -> Stage 2, 3
        wire(OBJ_MODTEX_INSTATE, 0, OBJ_STAGE_2, 3),
        wire(OBJ_MODTEX_INSTATE, 0, OBJ_STAGE_3, 3),
        # src_shape / src_mod state -> Stage 2, 3 (control message on inlet 0)
        wire(OBJ_SHAPE_PRE, 0, OBJ_STAGE_2, 0),
        wire(OBJ_SHAPE_PRE, 0, OBJ_STAGE_3, 0),
        wire(OBJ_MODTEX_PRE, 0, OBJ_STAGE_2, 0),
        wire(OBJ_MODTEX_PRE, 0, OBJ_STAGE_3, 0),
        # src_vecfield tracked but unused in either codebox's math — no
        # further destination, matches its already-vestigial status in the
        # pre-Evolution-2 shipped module.

        # Stage 1a/1b -> Stage 1c (search halves -> merge)
        wire(OBJ_STAGE_1A, 0, OBJ_STAGE_1C, 0),
        wire(OBJ_STAGE_1A, 1, OBJ_STAGE_1C, 1),
        wire(OBJ_STAGE_1A, 2, OBJ_STAGE_1C, 2),
        wire(OBJ_STAGE_1B, 0, OBJ_STAGE_1C, 3),
        wire(OBJ_STAGE_1B, 1, OBJ_STAGE_1C, 4),
        wire(OBJ_STAGE_1B, 2, OBJ_STAGE_1C, 5),

        # Stage 1c -> Stage 2/3 (rank1_coord/rank2_coord -> render inlet 0)
        wire(OBJ_STAGE_1C, 0, OBJ_STAGE_2, 0),
        wire(OBJ_STAGE_1C, 1, OBJ_STAGE_3, 0),
        # Stage 1c's out3 (properly-formatted seed coord) -> outer outlet,
        # bypassing Stage 4 entirely
        wire(OBJ_STAGE_1C, 2, OBJ_OUTLET_COORD, 0),

        # Stage 2/3 -> Stage 4 (composite)
        wire(OBJ_STAGE_2, 0, OBJ_STAGE_4, 0),
        wire(OBJ_STAGE_3, 0, OBJ_STAGE_4, 1),

        # Stage 4 -> outer outlets (mark color, mark mask)
        wire(OBJ_STAGE_4, 0, OBJ_OUTLET_COLOR, 0),
        wire(OBJ_STAGE_4, 1, OBJ_OUTLET_MASK, 0),
    ]

    # ---- Per-param UI: dial + attrui + label, wired ROUTE -> dial -> attrui
    # -> fan out to every target stage at inlet 0 (control message). Each
    # param's attrui is bound to `attr_name` (defaults to the param's own
    # name) — this is how `bomb` reaches Stage 1b's `active_blend` without
    # any rename plumbing: the dial keeps showing "Bomb" (its own
    # parameter_longname), but feeds an attrui bound directly to
    # `active_blend`, since an attrui's OUTPUT name comes from its own
    # `attr`, not from whatever fed its inlet. An earlier version tried a
    # `route bomb` -> `prepend active_blend` rename chain instead — Matt
    # found this silently dropped the value in Max (confirmed via a
    # `print` object placed in the chain — see plan.md's addendum) and
    # replaced it with this direct-attrui approach, confirmed working.
    for n, p in enumerate(PARAMS):
        boxes.append(dial_box(n, p))
        attr_name = p.get("attr_name", p["name"])
        boxes.append(attrui_box(attrui_id(n), attr_name, 50.0 + n * 50.0, 170.0 + n * 30.0))
        boxes.append(label_box(n, p))
        if p.get("range_tiers"):
            boxes.extend(range_tier_boxes(n, p))
            # range menu targets this param's own dial (Live-parameter
            # convention: _parameter_range message sent directly to the
            # live.dial adjusts its bounds) — same pattern build_patcher.py
            # already uses for this exact param.
            for t in range(len(p["range_tiers"])):
                lines.append(wire(range_sel_id(n), t, range_msg_id(n, t), 0))
                lines.append(wire(range_msg_id(n, t), 0, dial_id(n), 0))
            lines.append(wire(range_menu_id(n), 2, range_sel_id(n), 0))

        lines.append(wire(OBJ_ROUTE, n, dial_id(n), 0))
        lines.append(wire(dial_id(n), 0, attrui_id(n), 0))

        for target in p["targets"]:
            lines.append(wire(attrui_id(n), 0, STAGE_OBJ[target], 0))

    # ---- Bypass: jsui + attrui, fanned to Stage 1c and Stage 4 ------------
    boxes += [
        box(OBJ_BYPASS_JSUI, maxclass="jsui", filename="bypass_toggle.js",
            hint="Bypass", numinlets=1, numoutlets=1, outlettype=[""],
            presentation=1,
            patching_rect=[PW - 22.0, 5.0, 18.0, 12.0],
            presentation_rect=[PW - 22.0, 5.0, 18.0, 12.0],
            valuepopuplabel=1, varname="bypass"),
        box(OBJ_BYPASS_ATTRUI, maxclass="attrui", attr="bypass",
            numinlets=1, numoutlets=1, outlettype=[""],
            patching_rect=[600.0, 60.0, 131.0, 22.0], style=""),
    ]
    lines.append(wire(OBJ_BYPASS_JSUI, 0, OBJ_BYPASS_ATTRUI, 0))
    for target in BYPASS_TARGETS:
        lines.append(wire(OBJ_BYPASS_ATTRUI, 0, STAGE_OBJ[target], 0))

    # ---- Panel / title / infra ---------------------------------------------
    boxes += [
        box(OBJ_AUTOPATTR, maxclass="newobj", numinlets=1, numoutlets=4,
            outlettype=["", "", "", ""],
            patching_rect=[600.0, 780.0, 56.0, 22.0],
            text="autopattr", varname=f"{PREFIX}_autopattr"),
        panel_box(), title_box(), signal_type_box(),
    ]
    boxes.extend(modulesize_boxes())
    lines += [
        wire(OBJ_LOADBANG, 0, OBJ_GETATTR, 0),
        wire(OBJ_GETATTR, 0, OBJ_THISPATCHER, 0),
        wire(OBJ_THISPATCHER, 0, OBJ_ZLSLICE, 0),
        wire(OBJ_ZLSLICE, 1, OBJ_PRETAM, 0),
        wire(OBJ_PRETAM, 0, OBJ_MODULESIZE, 0),
    ]

    # ---- parameters block (Live parameter-bank system) --------------------
    params_block = {dial_id(n): [p["name"], p["name"], 0] for n, p in enumerate(PARAMS)}
    params_block["parameterbanks"] = {"0": {
        "index": 0, "name": "",
        "parameters": ["-", "-", "-", "-", "-", "-", "-", "-"],
        "buttons":    ["-", "-", "-", "-", "-", "-", "-", "-"]}}
    params_block["inherited_shortname"] = 1

    patcher = {
        "fileversion": 1, "appversion": APPVER, "classnamespace": "box",
        "rect": [100.0, 100.0, 900.0, 900.0],
        "openinpresentation": 1,
        "boxes": boxes, "lines": lines,
        "parameters": params_block,
        "autosave": 0,
    }
    return {"patcher": patcher}

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    result = build()
    out_path = REPO / "patchers" / f"{NAME}.maxpat"
    with open(out_path, "w") as f:
        json.dump(result, f, indent="\t")
    print(f"Written: {out_path}")
    print(f"Params: {len(PARAMS)}, stages: 1a/1b/1c/2/3/4 (6 total)")
