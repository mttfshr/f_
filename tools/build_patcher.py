#!/usr/bin/env python3
"""
build_patcher.py — generates f_ Vsynth bpatcher .maxpat JSON from a definition file.

Usage:
    python3 tools/build_patcher.py .specify/f_stipple/definition.py

See tools/spec.md for definition file schema.
"""

import json
import sys
import importlib.util
from pathlib import Path

# ---------------------------------------------------------------------------
# Styling constants
# ---------------------------------------------------------------------------
FONT        = "Ableton Sans Light"
FONT_TITLE  = 12.0
FONT_LABEL  = 9.5
DIAL_COLOR  = [0.8, 0.8, 0.8, 1.0]
BG_COLOR    = [0.0, 0.0, 0.0, 1.0]
BORDER_COLOR = [0.0, 0.03529411765, 0.2274509804, 1.0]

# ---------------------------------------------------------------------------
# Object ID scheme (deterministic)
# ---------------------------------------------------------------------------
OBJ_INLET       = "obj-1"
OBJ_OUTLET      = "obj-2"
OBJ_ROUTEPASS   = "obj-3"
OBJ_ROUTE       = "obj-4"
OBJ_PIX         = "obj-5"
OBJ_AUTOPATTR   = "obj-6"
OBJ_PANEL       = "obj-9"
OBJ_TITLE       = "obj-10"
OBJ_LOADBANG    = "obj-11"
OBJ_GETATTR     = "obj-12"
OBJ_THISPATCHER = "obj-13"
OBJ_ZLSLICE     = "obj-14"
OBJ_PRETAM      = "obj-15"
OBJ_MODULESIZE  = "obj-16"
# Dual-mode only:
OBJ_INSTATE     = "obj-17"
OBJ_SRCMODE_PRE = "obj-18"
# Header toggle (proc_mode or similar binary param) — fixed IDs
OBJ_HEADER_TOGGLE       = "obj-19a"
OBJ_HEADER_TOGGLE_LABEL = "obj-19b"
OBJ_HEADER_TOGGLE_PRE   = "obj-19c"
# bypass IDs are dynamic — computed from n_ui_params in build()
UI_PARAM_BASE   = 20

def param_obj_id(n):
    return f"obj-{UI_PARAM_BASE + n * 3 + 0}"

def param_pre_id(n):
    return f"obj-{UI_PARAM_BASE + n * 3 + 1}"

def param_label_id(n):
    return f"obj-{UI_PARAM_BASE + n * 3 + 2}"

def bypass_jsui_id(n_ui_params):
    return f"obj-{UI_PARAM_BASE + n_ui_params * 3 + 0}"

def bypass_pre_id(n_ui_params):
    return f"obj-{UI_PARAM_BASE + n_ui_params * 3 + 1}"


# ---------------------------------------------------------------------------
# Box builders
# ---------------------------------------------------------------------------

def box(id, **kwargs):
    return {"box": {"id": id, **kwargs}}

def inlet_box():
    return box(OBJ_INLET,
        maxclass="inlet", comment="texture in", index=0,
        numinlets=0, numoutlets=1, outlettype=[""],
        patching_rect=[30.0, 30.0, 30.0, 30.0])

def outlet_box():
    return box(OBJ_OUTLET,
        maxclass="outlet", comment="texture out", index=0,
        numinlets=1, numoutlets=0,
        patching_rect=[30.0, 500.0, 30.0, 30.0])

def routepass_box():
    return box(OBJ_ROUTEPASS,
        maxclass="newobj",
        numinlets=3, numoutlets=3, outlettype=["", "", ""],
        patching_rect=[200.0, 90.0, 215.0, 22.0],
        text="routepass jit_gl_texture jit_matrix")

def route_box(ui_params):
    names = " ".join(p["name"] for p in ui_params)
    n = len(ui_params)
    return box(OBJ_ROUTE,
        maxclass="newobj",
        numinlets=1, numoutlets=n, outlettype=[""] * n,
        patching_rect=[200.0, 130.0, max(150.0, len(names) * 7.0), 22.0],
        text=f"route {names}")

def autopattr_box(prefix):
    return box(OBJ_AUTOPATTR,
        maxclass="newobj",
        numinlets=1, numoutlets=4, outlettype=["", "", "", ""],
        patching_rect=[500.0, 500.0, 56.0, 22.0],
        text="autopattr",
        varname=f"{prefix}_autopattr")

def bypass_jsui_box(obj_id, object_name, pw):
    return box(obj_id,
        maxclass="jsui",
        filename="bypass_toggle.js",
        hint="Bypass",
        numinlets=1, numoutlets=1, outlettype=[""],
        presentation=1,
        patching_rect=[pw - 22.0, 5.0, 18.0, 12.0],
        presentation_rect=[pw - 22.0, 5.0, 18.0, 12.0],
        valuepopuplabel=1,
        varname="bypass")

def bypass_attrui_box(obj_id):
    return box(obj_id,
        maxclass="attrui",
        attr="bypass",
        numinlets=1, numoutlets=1, outlettype=[""],
        patching_rect=[400.0, 60.0, 131.0, 22.0],
        style="")

def panel_box(pw, ph):
    return box(OBJ_PANEL,
        maxclass="panel",
        angle=270.0, background=1,
        bgcolor=BG_COLOR,
        border=1, bordercolor=BORDER_COLOR,
        mode=0,
        numinlets=1, numoutlets=0,
        patching_rect=[20.0, 20.0, pw, ph],
        presentation=1,
        presentation_rect=[0.0, 0.0, pw, ph],
        proportion=0.5)

def title_box(title):
    return box(OBJ_TITLE,
        maxclass="comment",
        fontname=FONT, fontsize=FONT_TITLE,
        numinlets=1, numoutlets=0,
        patching_rect=[20.0, 20.0, 80.0, 21.0],
        presentation=1,
        presentation_rect=[-1.5, 0.0, 80.0, 21.0],
        text=title)


def modulesize_boxes():
    return [
        box(OBJ_LOADBANG,
            maxclass="newobj", numinlets=1, numoutlets=1, outlettype=[""],
            patching_rect=[600.0, 50.0, 60.0, 22.0], text="loadbang"),
        box(OBJ_GETATTR,
            maxclass="message", numinlets=2, numoutlets=1, outlettype=[""],
            patching_rect=[600.0, 80.0, 180.0, 22.0], text="getattr presentation_rect"),
        box(OBJ_THISPATCHER,
            maxclass="newobj", numinlets=1, numoutlets=4, outlettype=["","","",""],
            patching_rect=[600.0, 110.0, 80.0, 22.0], text="thispatcher"),
        box(OBJ_ZLSLICE,
            maxclass="newobj", numinlets=2, numoutlets=2, outlettype=["",""],
            patching_rect=[600.0, 140.0, 60.0, 22.0], text="zl slice 2"),
        box(OBJ_PRETAM,
            maxclass="newobj", numinlets=1, numoutlets=1, outlettype=[""],
            patching_rect=[600.0, 170.0, 80.0, 22.0], text="prepend tam"),
        box(OBJ_MODULESIZE,
            maxclass="newobj", numinlets=1, numoutlets=1, outlettype=[""],
            patching_rect=[600.0, 200.0, 100.0, 22.0],
            saved_object_attributes={"filename": "moduleSize.js", "parameter_enable": 0},
            text="js moduleSize.js"),
    ]

def instate_boxes():
    return [
        box(OBJ_INSTATE,
            maxclass="newobj", numinlets=1, numoutlets=2, outlettype=["",""],
            patching_rect=[200.0, 60.0, 80.0, 22.0], text="vs_inState"),
        box(OBJ_SRCMODE_PRE,
            maxclass="newobj", numinlets=1, numoutlets=1, outlettype=[""],
            patching_rect=[350.0, 60.0, 145.0, 22.0], text="prepend param src_mode"),
    ]

def dial_box(n, p, object_name):
    col = n % 5
    row = n // 5
    x = 4.0 + col * 37.0
    y = 38.0 + row * 62.0
    return box(param_obj_id(n),
        maxclass="live.dial",
        activedialcolor=DIAL_COLOR,
        fontname=FONT,
        hint=p.get("hint", ""),
        numinlets=1, numoutlets=2, outlettype=["", "float"],
        param_connect=f"{object_name}::{p['name']}",
        parameter_enable=1,
        patching_rect=[50.0 + n * 50.0, 80.0, 27.0, 43.0],
        presentation=1,
        presentation_rect=[x, y, 27.0, 43.0],
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
                "parameter_unitstyle": 1
            }
        },
        showname=0, triangle=1, valuepopup=1, valuepopuplabel=1,
        varname=p["name"])

def numbox_box(n, p, object_name):
    col = n % 5
    row = n // 5
    x = 4.0 + col * 37.0
    y = 38.0 + row * 62.0
    return box(param_obj_id(n),
        maxclass="live.numbox",
        fontname=FONT,
        hint=p.get("hint", ""),
        numinlets=1, numoutlets=2, outlettype=["", "float"],
        param_connect=f"{object_name}::{p['name']}",
        parameter_enable=1,
        patching_rect=[50.0 + n * 50.0, 80.0, 44.0, 15.0],
        presentation=1,
        presentation_rect=[x, y, 34.0, 15.0],
        saved_attribute_attributes={
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
                "parameter_unitstyle": 0
            }
        },
        varname=p["name"])

def label_box(n, p):
    col = n % 5
    row = n // 5
    x = 4.0 + col * 37.0
    y = 20.0 + row * 62.0
    label = p.get("label", p["name"].replace("_", " ").title())
    return box(param_label_id(n),
        maxclass="comment",
        fontname=FONT, fontsize=FONT_LABEL,
        numinlets=1, numoutlets=0,
        patching_rect=[50.0 + n * 50.0, 130.0, 50.0, 18.0],
        presentation=1,
        presentation_rect=[x - 11.5, y, 50.0, 18.0],
        text=label,
        textjustification=1)

def attrui_box(obj_id, name, x, y):
    return box(obj_id,
        maxclass="attrui",
        attr=name,
        numinlets=1, numoutlets=1, outlettype=[""],
        patching_rect=[x, y, max(100.0, len(name) * 7.0 + 80.0), 22.0],
        style="")

def header_toggle_box(p, object_name, pw):
    # 20×20 live.toggle, right-aligned in header, left of bypass
    x = pw - 50.0
    return box(OBJ_HEADER_TOGGLE,
        maxclass="live.toggle",
        fontname=FONT,
        hint=p.get("hint", ""),
        numinlets=1, numoutlets=1, outlettype=[""],
        param_connect=f"{object_name}::{p['name']}",
        parameter_enable=1,
        patching_rect=[450.0, 60.0, 20.0, 20.0],
        presentation=1,
        presentation_rect=[x, 1.0, 20.0, 20.0],
        saved_attribute_attributes={
            "valueof": {
                "parameter_initial": [float(p["default"])],
                "parameter_initial_enable": 1,
                "parameter_linknames": 1,
                "parameter_longname": p["name"],
                "parameter_mmax": float(p["max"]),
                "parameter_mmin": float(p["min"]),
                "parameter_modmode": 0,
                "parameter_shortname": p["name"],
                "parameter_type": 1,
                "parameter_unitstyle": 0
            }
        },
        varname=p["name"])

def header_toggle_label_box(p, pw):
    # label left of the toggle
    x = pw - 50.0 - 43.0
    label = p.get("header_label", p["name"].replace("_", " ").title())
    return box(OBJ_HEADER_TOGGLE_LABEL,
        maxclass="comment",
        fontname=FONT, fontsize=FONT_LABEL,
        numinlets=1, numoutlets=0,
        patching_rect=[450.0, 60.0, 43.0, 18.0],
        presentation=1,
        presentation_rect=[x, 3.0, 43.0, 18.0],
        text=label,
        textjustification=2)


# ---------------------------------------------------------------------------
# Modulation inlet boxes (vs_inState + vs_black per inlet)
# ---------------------------------------------------------------------------

def mod_inlet_obj_id(i):
    """Outer inlet object for modulation inlet i (0-based). Uses obj-100+ range."""
    return f"obj-{100 + i * 3 + 0}"

def mod_instate_obj_id(i):
    """vs_inState for modulation inlet i."""
    return f"obj-{100 + i * 3 + 1}"

def mod_inlet_boxes(mod_inlets):
    """Generate inlet + vs_inState boxes for each modulation inlet."""
    boxes = []
    for i, mi in enumerate(mod_inlets):
        inlet_id   = mod_inlet_obj_id(i)
        instate_id = mod_instate_obj_id(i)
        label      = mi.get("label", f"mod {i+1}")
        boxes.append(box(inlet_id,
            maxclass="inlet", comment=label, index=i + 1,
            numinlets=0, numoutlets=1, outlettype=[""],
            patching_rect=[30.0 + (i + 1) * 60.0, 30.0, 30.0, 30.0]))
        boxes.append(box(instate_id,
            maxclass="newobj", numinlets=1, numoutlets=2, outlettype=["", ""],
            patching_rect=[30.0 + (i + 1) * 60.0, 80.0, 80.0, 22.0],
            text="vs_inState"))
    return boxes

def mod_inlet_lines(mod_inlets):
    """Wire each modulation inlet → vs_inState → pix inlet N."""
    lines = []
    for i in range(len(mod_inlets)):
        inlet_id   = mod_inlet_obj_id(i)
        instate_id = mod_instate_obj_id(i)
        # inlet → vs_inState
        lines.append(wire(inlet_id, 0, instate_id, 0))
        # vs_inState out0 (texture or vs_black) → pix inlet i+1
        lines.append(wire(instate_id, 0, OBJ_PIX, i + 1))
    return lines


# ---------------------------------------------------------------------------
# Gen subpatcher builder
# ---------------------------------------------------------------------------

def gen_subpatcher(codebox, archetype, mod_inlets=None):
    """
    mod_inlets: list of mod inlet dicts (from definition). When present,
    adds in 2, in 3, ... objects and wires them to codebox inlets 1, 2, ...
    The base in 1 (bang/render trigger) is always inlet 0 of the codebox.
    """
    mod_inlets = mod_inlets or []
    boxes = []
    lines = []

    boxes.append({"box": {
        "id": "gen-obj-1", "maxclass": "newobj",
        "numinlets": 0, "numoutlets": 1, "outlettype": [""],
        "patching_rect": [22.0, 30.0, 28.0, 22.0], "text": "in 1"
    }})

    # Extra gen inlet objects for modulation (in 2, in 3, ...)
    for i, _ in enumerate(mod_inlets):
        gen_in_id = f"gen-obj-{10 + i}"
        boxes.append({"box": {
            "id": gen_in_id, "maxclass": "newobj",
            "numinlets": 0, "numoutlets": 1, "outlettype": [""],
            "patching_rect": [80.0 + i * 58.0, 30.0, 28.0, 22.0],
            "text": f"in {i + 2}"
        }})

    # Total codebox inlets: 1 (base) + len(mod_inlets)
    n_codebox_inlets = 1 + len(mod_inlets)

    if archetype == "source" and not mod_inlets:
        # Original source: in 1 + r dim + codebox(2 inlets)
        boxes.append({"box": {
            "id": "gen-obj-2", "maxclass": "newobj",
            "numinlets": 0, "numoutlets": 1, "outlettype": [""],
            "patching_rect": [120.0, 30.0, 35.0, 22.0], "text": "r dim"
        }})
        boxes.append({"box": {
            "code": codebox,
            "fontface": 0, "fontname": "<Monospaced>", "fontsize": 12.0,
            "id": "gen-obj-3", "maxclass": "codebox",
            "numinlets": 2, "numoutlets": 1, "outlettype": [""],
            "patching_rect": [22.0, 80.0, 550.0, 380.0]
        }})
        boxes.append({"box": {
            "id": "gen-obj-4", "maxclass": "newobj",
            "numinlets": 1, "numoutlets": 0,
            "patching_rect": [22.0, 490.0, 35.0, 22.0], "text": "out 1"
        }})
        lines = [
            {"patchline": {"destination": ["gen-obj-3", 0], "source": ["gen-obj-1", 0]}},
            {"patchline": {"destination": ["gen-obj-3", 1], "source": ["gen-obj-2", 0]}},
            {"patchline": {"destination": ["gen-obj-4", 0], "source": ["gen-obj-3", 0]}},
        ]
    elif archetype == "source" and mod_inlets:
        # Source with modulation inlets: in 1 + in 2..N + codebox(1+N inlets)
        codebox_id = "gen-obj-3"
        out_id     = "gen-obj-4"
        boxes.append({"box": {
            "code": codebox,
            "fontface": 0, "fontname": "<Monospaced>", "fontsize": 12.0,
            "id": codebox_id, "maxclass": "codebox",
            "numinlets": n_codebox_inlets, "numoutlets": 1, "outlettype": [""],
            "patching_rect": [22.0, 80.0, 550.0, 380.0]
        }})
        boxes.append({"box": {
            "id": out_id, "maxclass": "newobj",
            "numinlets": 1, "numoutlets": 0,
            "patching_rect": [22.0, 490.0, 35.0, 22.0], "text": "out 1"
        }})
        # Wire in 1 → codebox inlet 0
        lines.append({"patchline": {"destination": [codebox_id, 0], "source": ["gen-obj-1", 0]}})
        # Wire in 2..N → codebox inlets 1..N-1
        for i in range(len(mod_inlets)):
            gen_in_id = f"gen-obj-{10 + i}"
            lines.append({"patchline": {"destination": [codebox_id, i + 1], "source": [gen_in_id, 0]}})
        # Wire codebox → out
        lines.append({"patchline": {"destination": [out_id, 0], "source": [codebox_id, 0]}})
    else:
        # processor and dual: single inlet to codebox (mod_inlets not supported for these yet)
        boxes.append({"box": {
            "code": codebox,
            "fontface": 0, "fontname": "<Monospaced>", "fontsize": 12.0,
            "id": "gen-obj-2", "maxclass": "codebox",
            "numinlets": 1, "numoutlets": 1, "outlettype": [""],
            "patching_rect": [22.0, 80.0, 550.0, 380.0]
        }})
        boxes.append({"box": {
            "id": "gen-obj-3", "maxclass": "newobj",
            "numinlets": 1, "numoutlets": 0,
            "patching_rect": [22.0, 490.0, 35.0, 22.0], "text": "out 1"
        }})
        lines = [
            {"patchline": {"destination": ["gen-obj-2", 0], "source": ["gen-obj-1", 0]}},
            {"patchline": {"destination": ["gen-obj-3", 0], "source": ["gen-obj-2", 0]}},
        ]

    return {
        "fileversion": 1,
        "appversion": {"major": 9, "minor": 1, "revision": 4,
                       "architecture": "x64", "modernui": 1},
        "classnamespace": "jit.gen",
        "rect": [100.0, 100.0, 700.0, 600.0],
        "boxes": boxes,
        "lines": lines
    }


# ---------------------------------------------------------------------------
# jit.gl.pix box
# ---------------------------------------------------------------------------

def pix_box(p, object_name, codebox, archetype, mod_inlets=None, pix_type=None):
    mod_inlets = mod_inlets or []
    type_attr  = f" @type {pix_type}" if pix_type else ""
    n_outer_inlets = 1 + len(mod_inlets)
    return box(OBJ_PIX,
        maxclass="newobj",
        numinlets=n_outer_inlets, numoutlets=2,
        outlettype=["jit_gl_texture", ""],
        patcher=gen_subpatcher(codebox, archetype, mod_inlets),
        patching_rect=[200.0, 380.0, max(200.0, len(object_name) * 8.0 + 80.0), 22.0],
        text=f"jit.gl.pix vsynth @name {object_name}{type_attr}",
        varname=object_name)

# ---------------------------------------------------------------------------
# Patchline builder
# ---------------------------------------------------------------------------

def wire(src_id, src_outlet, dst_id, dst_inlet):
    return {"patchline": {
        "source": [src_id, src_outlet],
        "destination": [dst_id, dst_inlet]
    }}

# ---------------------------------------------------------------------------
# Main builder
# ---------------------------------------------------------------------------

def build(defn):
    name        = defn["name"]
    prefix      = defn["prefix"]
    object_name = defn["object_name"]
    title       = defn["title"]
    archetype   = defn["archetype"]
    pw          = float(defn["presentation_width"])
    ph          = float(defn["presentation_height"])
    codebox     = defn["codebox"]
    all_params  = defn["params"]
    mod_inlets  = defn.get("mod_inlets", [])
    pix_type    = defn.get("pix_type", None)

    # Separate param types
    ui_params       = [p for p in all_params if p["type"] in ("float", "int")]
    header_toggles  = [p for p in all_params if p["type"] == "header_toggle"]
    internal_params = [p for p in all_params if p["type"] == "internal"]
    # bypass is handled separately

    # Route param names = ui params + header toggles (not internal, not bypass)
    route_params = ui_params + header_toggles

    # bypass IDs — placed after all per-param objects
    bp_jsui_id = bypass_jsui_id(len(ui_params))
    bp_pre_id  = bypass_pre_id(len(ui_params))

    # Build boxes — pix must come before bypass jsui (param_connect dependency)
    boxes = []
    boxes.append(inlet_box())
    boxes.append(outlet_box())
    boxes.append(routepass_box())
    boxes.append(route_box(route_params))
    boxes.append(pix_box(prefix, object_name, codebox, archetype, mod_inlets, pix_type))
    boxes.append(autopattr_box(prefix))
    boxes.append(panel_box(pw, ph))
    boxes.append(title_box(title))
    boxes.extend(modulesize_boxes())

    if archetype == "dual":
        boxes.extend(instate_boxes())

    # Modulation inlet boxes (inlet + vs_inState per mod inlet)
    if mod_inlets:
        boxes.extend(mod_inlet_boxes(mod_inlets))

    # Per-param boxes (grid — float and int only)
    for n, p in enumerate(ui_params):
        if p["type"] == "float":
            boxes.append(dial_box(n, p, object_name))
        elif p["type"] == "int":
            boxes.append(numbox_box(n, p, object_name))
        boxes.append(attrui_box(param_pre_id(n), p["name"],
                                50.0 + n * 50.0, 170.0 + n * 30.0))
        boxes.append(label_box(n, p))

    # Header toggle boxes (e.g. proc_mode) — rendered in header, wired via route
    if header_toggles:
        p = header_toggles[0]   # currently only one supported
        boxes.append(header_toggle_box(p, object_name, pw))
        boxes.append(header_toggle_label_box(p, pw))
        boxes.append(attrui_box(OBJ_HEADER_TOGGLE_PRE, p["name"], 500.0, 230.0))

    # bypass jsui and prepend LAST — must come after pix in boxes list
    boxes.append(bypass_jsui_box(bp_jsui_id, object_name, pw))
    boxes.append(bypass_attrui_box(bp_pre_id))

    # Build patchlines
    lines = []

    # inlet → routepass
    lines.append(wire(OBJ_INLET, 0, OBJ_ROUTEPASS, 0))

    if archetype == "dual":
        # routepass out0 → vs_inState → pix
        lines.append(wire(OBJ_ROUTEPASS, 0, OBJ_INSTATE, 0))
        lines.append(wire(OBJ_INSTATE, 0, OBJ_PIX, 0))
        lines.append(wire(OBJ_INSTATE, 1, OBJ_SRCMODE_PRE, 0))
        lines.append(wire(OBJ_SRCMODE_PRE, 0, OBJ_PIX, 0))
    else:
        # routepass out0 → pix
        lines.append(wire(OBJ_ROUTEPASS, 0, OBJ_PIX, 0))

    # routepass out2 (unmatched) → route
    lines.append(wire(OBJ_ROUTEPASS, 2, OBJ_ROUTE, 0))

    # pix out0 → outlet
    lines.append(wire(OBJ_PIX, 0, OBJ_OUTLET, 0))

    # modulation inlets → vs_inState → pix
    if mod_inlets:
        lines.extend(mod_inlet_lines(mod_inlets))

    # bypass jsui → prepend bypass → pix
    lines.append(wire(bp_jsui_id, 0, bp_pre_id, 0))
    lines.append(wire(bp_pre_id, 0, OBJ_PIX, 0))

    # moduleSize chain
    lines.append(wire(OBJ_LOADBANG, 0, OBJ_GETATTR, 0))
    lines.append(wire(OBJ_GETATTR, 0, OBJ_THISPATCHER, 0))
    lines.append(wire(OBJ_THISPATCHER, 0, OBJ_ZLSLICE, 0))
    lines.append(wire(OBJ_ZLSLICE, 1, OBJ_PRETAM, 0))
    lines.append(wire(OBJ_PRETAM, 0, OBJ_MODULESIZE, 0))

    # route outlets → grid controls → prepends → pix
    for n, p in enumerate(ui_params):
        lines.append(wire(OBJ_ROUTE, n, param_obj_id(n), 0))
        lines.append(wire(param_obj_id(n), 0, param_pre_id(n), 0))
        lines.append(wire(param_pre_id(n), 0, OBJ_PIX, 0))

    # route outlets → header toggles → prepends → pix
    if header_toggles:
        ht_outlet = len(ui_params)   # header toggles come after ui_params in route
        lines.append(wire(OBJ_ROUTE, ht_outlet, OBJ_HEADER_TOGGLE, 0))
        lines.append(wire(OBJ_HEADER_TOGGLE, 0, OBJ_HEADER_TOGGLE_PRE, 0))
        lines.append(wire(OBJ_HEADER_TOGGLE_PRE, 0, OBJ_PIX, 0))

    # parameters block — grid params + header toggles (not bypass jsui)
    params_block = {}
    for n, p in enumerate(ui_params):
        params_block[param_obj_id(n)] = [p["name"], p["name"], 0]
    if header_toggles:
        params_block[OBJ_HEADER_TOGGLE] = [header_toggles[0]["name"], header_toggles[0]["name"], 0]
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

def load_definition(path):
    spec = importlib.util.spec_from_file_location("definition", path)
    mod  = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod.patcher

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 tools/build_patcher.py .specify/f_<name>/definition.py")
        sys.exit(1)

    def_path  = Path(sys.argv[1])
    defn      = load_definition(def_path)
    result    = build(defn)

    repo_root = Path(__file__).parent.parent
    out_path  = repo_root / "patchers" / f"{defn['name']}.maxpat"

    with open(out_path, "w") as f:
        json.dump(result, f, indent="\t")

    print(f"Written: {out_path}")

if __name__ == "__main__":
    main()
