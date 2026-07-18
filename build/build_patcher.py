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

# Signal type label colors (used in header next to title)
SIGNAL_TYPE_COLORS = {
    "vecfield": [ 0.302, 0.325, 0.463, 1.000 ],   
}
OBJ_SIGNAL_TYPE = "obj-8"  # reserved ID for signal type label

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
# Panel toggle (front/back panel switch) — fixed IDs, added 2026-07-15
OBJ_PANEL_TOGGLE    = "obj-19d"
OBJ_PANEL_TOGGLE_JS = "obj-19e"
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

# Range tier objects occupy obj-300+ to avoid all collisions
# Each param with range_tiers gets: 1 menu + 1 sel + N message boxes
# Allocation: obj-{300 + n*10 + 0} = menu, obj-{300 + n*10 + 1} = sel,
#             obj-{300 + n*10 + 2..} = messages (one per tier)
def range_menu_id(n):    return f"obj-{300 + n * 10 + 0}"
def range_sel_id(n):     return f"obj-{300 + n * 10 + 1}"
def range_msg_id(n, t):  return f"obj-{300 + n * 10 + 2 + t}"


# ---------------------------------------------------------------------------
# Box builders
# ---------------------------------------------------------------------------

def box(id, **kwargs):
    return {"box": {"id": id, **kwargs}}

def inlet_box():
    return box(OBJ_INLET,
        maxclass="inlet", comment="texture / control", index=0,
        numinlets=0, numoutlets=1, outlettype=[""],
        patching_rect=[30.0, 30.0, 30.0, 30.0])

def outlet_box():
    """Single default outlet — used when definition has no 'outlets' key."""
    return box(OBJ_OUTLET,
        maxclass="outlet", comment="texture", index=0,
        numinlets=1, numoutlets=0,
        patching_rect=[30.0, 500.0, 30.0, 30.0])

def outlet_obj_id(i):
    """Outlet object ID for outlet index i. i=0 → obj-2 (primary), i>0 → obj-200+i."""
    return OBJ_OUTLET if i == 0 else f"obj-{200 + i}"

def outlet_boxes(outlets):
    """Generate outlet boxes for a list of outlet dicts: [{comment, color?}, ...]"""
    boxes = []
    for i, o in enumerate(outlets):
        obj_id = outlet_obj_id(i)
        kwargs = dict(
            maxclass="outlet", comment=o.get("comment", "texture out"), index=i,
            numinlets=1, numoutlets=0,
            patching_rect=[30.0 + i * 70.0, 500.0, 30.0, 30.0])
        if o.get("color"):
            kwargs["tricolor"] = o["color"]
        boxes.append(box(obj_id, **kwargs))
    return boxes

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

def signal_type_box(signal_type, title):
    """Small colored label rendered in the header, right of the title text."""
    color = SIGNAL_TYPE_COLORS.get(signal_type, [0.6, 0.6, 0.6, 1.0])
    # Estimate title width to position label after it (approx 7px per char)
    title_w = max(40.0, len(title) * 7.2)
    return box(OBJ_SIGNAL_TYPE,
        maxclass="comment",
        fontname=FONT, fontsize=FONT_TITLE,
        textcolor=color,
        numinlets=1, numoutlets=0,
        patching_rect=[20.0, 20.0, 60.0, 21.0],
        presentation=1,
        presentation_rect=[title_w - 2.0, 2.5, 60.0, 18.0],
        text=signal_type)

def panel_toggle_boxes(panel_toggle, pw):
    """
    Generate the front/back panel-switch toggle button + its wired js
    object. Added 2026-07-15, generalized from f_lens's hand-built
    panel_toggle/lens_toggle.js mechanism. The actual per-module toggle
    JS *file* is written separately (see write_panel_toggle_js) — this
    function only returns the two patcher boxes.

    panel_toggle: {
        "front": [param_name, ...], "back": [param_name, ...],
        "front_label": str (shown when back panel active, default "front"),
        "back_label": str (shown when front panel active, default "back"),
        "js_filename": str (default "<prefix>_toggle.js", set by caller),
    }
    """
    front_label = panel_toggle.get("front_label", "front")
    back_label  = panel_toggle.get("back_label", "back")
    js_filename = panel_toggle["js_filename"]
    toggle = box(OBJ_PANEL_TOGGLE,
        maxclass="live.text",
        fontname=FONT,
        numinlets=1, numoutlets=2, outlettype=["", ""],
        parameter_enable=1,
        patching_rect=[700.0, 30.0, 36.0, 14.0],
        presentation=1,
        presentation_rect=[pw - 58.0, 3.125, 36.0, 15.75],
        rounded=4.0,
        saved_attribute_attributes={
            "valueof": {
                "parameter_enum":            [front_label, back_label],
                "parameter_initial":         [0.0],
                "parameter_initial_enable":  1,
                "parameter_linknames":       1,
                "parameter_longname":        "panel_toggle",
                "parameter_mmax":            1,
                "parameter_modmode":         0,
                "parameter_shortname":       "panel_toggle",
                "parameter_speedlim":        0.0,
                "parameter_type":            2,
            }
        },
        text=front_label,
        texton=back_label,
        varname="panel_toggle")
    js = box(OBJ_PANEL_TOGGLE_JS,
        maxclass="newobj", numinlets=1, numoutlets=1, outlettype=[""],
        patching_rect=[700.0, 62.0, 130.0, 22.0],
        saved_object_attributes={"filename": js_filename, "parameter_enable": 0},
        text=f"js {js_filename}")
    return [toggle, js]

def panel_toggle_js_content(front_params, back_params):
    """
    Generate the per-module toggle JS file content — same sendbox
    mechanism as the original hand-built lens_toggle.js, parameterized
    by the front/back varname lists instead of hardcoded. front_params/
    back_params are param-name lists; each name's dial/numbox/menu AND
    its label (varname f"lbl_{name}", per label_box's 2026-07-15 varname
    fix) both get toggled together.
    """
    def obj_list(names):
        items = []
        for n in names:
            items.append(n)
            items.append(f"lbl_{n}")
        return items

    front_objs = obj_list(front_params)
    back_objs  = obj_list(back_params)
    front_js = ", ".join(f'"{o}"' for o in front_objs)
    back_js  = ", ".join(f'"{o}"' for o in back_objs)
    return f"""// Auto-generated by build_patcher.py from a "panel_toggle" definition —
// do not hand-edit; regenerate from definition.py instead.
// Receives 0 (front panel) or 1 (back panel).
// Scripts presentation visibility via thispatcher script sendbox.

var FRONT_OBJS = [{front_js}];

var BACK_OBJS = [{back_js}];

function loadbang()   {{ setpanel(0); }}
function msg_int(v)   {{ setpanel(v); }}
function msg_float(v) {{ setpanel(Math.round(v)); }}

function setpanel(show_back) {{
    var i;
    for (i = 0; i < FRONT_OBJS.length; i++) {{
        outlet(0, "script", "sendbox", FRONT_OBJS[i], "hidden", show_back ? 1 : 0);
    }}
    for (i = 0; i < BACK_OBJS.length; i++) {{
        outlet(0, "script", "sendbox", BACK_OBJS[i], "hidden", show_back ? 0 : 1);
    }}
}}
"""

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

def range_tier_boxes(n, p):
    """
    Generate menu + sel + message boxes for a param with range_tiers.
    n         — param index (for ID and presentation position)
    p         — param dict with 'range_tiers' key. Each tier entry is either:
                  - a plain number `upper` (unipolar, min assumed 0.) — original form
                  - a (lower, upper) 2-tuple/list (bipolar, explicit min) — added 2026-07-15
                for the aberration/distortion/transmission/ghost_spacing bipolar tier work.
    Returns list of box dicts.
    """
    tiers    = p["range_tiers"]
    n_tiers  = len(tiers)
    col      = n % 5
    dial_x   = 4.0 + col * 37.0

    def tier_bounds(t):
        """Normalize a tier entry to (lower, upper)."""
        if isinstance(t, (tuple, list)):
            return t[0], t[1]
        return 0.0, t

    def tier_label(t):
        """Menu display string for a tier entry."""
        if isinstance(t, (tuple, list)):
            lo, hi = t
            return f"{lo}..{hi}"
        return str(t)

    # Menu — presentation: triangle-only (16x15) positioned right of dial label
    menu_items = [tier_label(t) for t in tiers]
    menu = box(range_menu_id(n),
        maxclass="live.menu",
        fontname=FONT,
        fontsize=9.0,
        numinlets=1, numoutlets=3,
        outlettype=["", "", "float"],
        parameter_enable=1,
        patching_rect=[500.0 + n * 120.0, 200.0, 100.0, 15.0],
        presentation=1,
        presentation_rect=[dial_x + 22.5, 21.5, 16.0, 15.0],
        saved_attribute_attributes={
            "valueof": {
                "parameter_enum":     menu_items,
                "parameter_longname": f"range_{p['name']}",
                "parameter_shortname": f"range_{p['name']}",
                "parameter_type":     2,
            }
        })

    # sel object — one outlet per tier
    sel_args = " ".join(str(i) for i in range(n_tiers))
    sel = box(range_sel_id(n),
        maxclass="newobj",
        numinlets=1, numoutlets=n_tiers,
        outlettype=[""] * n_tiers,
        patching_rect=[500.0 + n * 120.0, 240.0, 60.0, 22.0],
        text=f"sel {sel_args}")

    # One _parameter_range message per tier
    msgs = []
    for t, tier in enumerate(tiers):
        lower, upper = tier_bounds(tier)
        # Preserve exact legacy text for unipolar tiers ("0." not "0.0.");
        # bipolar tiers interpolate the lower bound directly.
        lower_str = "0." if lower == 0 else str(lower)
        msgs.append(box(range_msg_id(n, t),
            maxclass="message",
            numinlets=2, numoutlets=1, outlettype=[""],
            patching_rect=[500.0 + n * 120.0 + t * 150.0, 280.0 + t * 30.0,
                           134.0, 22.0],
            text=f"_parameter_range {lower_str} {upper}"))

    return [menu, sel] + msgs


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

def text_button_box(n, p, object_name):
    col = n % 5
    row = n // 5
    x = 4.0 + col * 37.0
    y = 38.0 + row * 62.0
    options = p.get("options", ["Off", "On"])
    text_off = options[0]
    text_on  = options[1] if len(options) > 1 else options[0]
    w = max(35.0, max(len(text_off), len(text_on)) * 6.5 + 8.0)
    return box(param_obj_id(n),
        maxclass="live.text",
        fontname=FONT,
        fontsize=FONT_LABEL,
        hint=p.get("hint", ""),
        numinlets=1, numoutlets=2, outlettype=["", ""],
        param_connect=f"{object_name}::{p['name']}",
        parameter_enable=1,
        patching_rect=[50.0 + n * 50.0, 80.0, w, 17.0],
        presentation=1,
        presentation_rect=[x - 4.0, y + 14.0, w, 17.0],
        text=text_off,
        texton=text_on,
        saved_attribute_attributes={
            "activebgcolor":   {"expression": ""},
            "activebgoncolor": {"expression": ""},
            "activetextcolor": {"expression": ""},
            "activetextoncolor": {"expression": ""},
            "bgoncolor":       {"expression": ""},
            "valueof": {
                "parameter_enum":           options,
                "parameter_initial":        [float(p["default"])],
                "parameter_initial_enable": 1,
                "parameter_linknames":      1,
                "parameter_longname":       p["name"],
                "parameter_mmax":           1.0,
                "parameter_mmin":           0.0,
                "parameter_modmode":        0,
                "parameter_shortname":      p["name"],
                "parameter_type":           1,
                "parameter_unitstyle":      0
            }
        },
        varname=p["name"])

def menu_box(n, p, object_name):
    col = n % 5
    row = n // 5
    x = 4.0 + col * 37.0
    y = 38.0 + row * 62.0
    options = p.get("options", [])
    return box(param_obj_id(n),
        maxclass="live.menu",
        fontname=FONT,
        hint=p.get("hint", ""),
        numinlets=1, numoutlets=3, outlettype=["", "", "float"],
        param_connect=f"{object_name}::{p['name']}",
        parameter_enable=1,
        patching_rect=[50.0 + n * 50.0, 80.0, 60.0, 15.0],
        presentation=1,
        presentation_rect=[x - 4.0, y + 14.0, 45.0, 15.0],
        saved_attribute_attributes={
            "valueof": {
                "parameter_enum":           options,
                "parameter_initial":        [float(p["default"])],
                "parameter_initial_enable": 1,
                "parameter_linknames":      1,
                "parameter_longname":       p["name"],
                "parameter_mmax":           float(len(options) - 1),
                "parameter_mmin":           0.0,
                "parameter_modmode":        0,
                "parameter_shortname":      p["name"],
                "parameter_type":           2,
                "parameter_unitstyle":      0
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
        textjustification=1,
        varname=f"lbl_{p['name']}")

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

def mod_inlet_boxes(mod_inlets, driving_inlet=False):
    """Generate inlet + optional vs_inState boxes for each modulation inlet.
    If vs_instate is False, no vs_inState box is generated (inlet routes directly to pix).

    driving_inlet: when True, mod_inlets[0] is the module's primary driving
    texture and shares outer inlet 0 with inlet_box() (the "texture /
    control" inlet) instead of getting its own dedicated inlet object —
    mirrors the gen_subpatcher driving_inlet fix, which likewise omits a
    redundant channel rather than reindexing/sharing. Its vs_inState/
    state_param boxes (if declared) are still generated here; the wiring
    that sources them from OBJ_ROUTEPASS instead of a dedicated inlet
    lives in mod_inlet_lines(). Remaining mod_inlets shift down by one
    outer-inlet index (i instead of i+1).
    """
    boxes = []
    for i, mi in enumerate(mod_inlets):
        instate_id  = mod_instate_obj_id(i)
        label       = mi.get("label", f"mod {i+1}")
        use_instate = mi.get("vs_instate", True)
        skip_inlet  = driving_inlet and i == 0
        if not skip_inlet:
            inlet_id = mod_inlet_obj_id(i)
            index    = i if driving_inlet else i + 1
            boxes.append(box(inlet_id,
                maxclass="inlet", comment=label, index=index,
                numinlets=0, numoutlets=1, outlettype=[""],
                patching_rect=[30.0 + index * 60.0, 30.0, 30.0, 30.0]))
        if use_instate:
            boxes.append(box(instate_id,
                maxclass="newobj", numinlets=1, numoutlets=2, outlettype=["", ""],
                patching_rect=[30.0 + (i + 1) * 60.0, 80.0, 80.0, 22.0],
                text="vs_inState"))
    return boxes

def mod_state_pre_id(i):
    """prepend param <state_param> for modulation inlet i (when state_param present)."""
    return f"obj-{100 + i * 3 + 2}"

def mod_inlet_lines(mod_inlets, driving_inlet=False):
    """Wire each modulation inlet → (vs_inState →) pix inlet N.
    vs_instate defaults True. When False, inlet wires directly to pix (no vs_inState).
    If a mod_inlet has a 'state_param' key, also wire vs_inState out1
    → prepend param <state_param> → pix in0 (message inlet).
    state_param requires vs_instate=True (validated in build()).

    driving_inlet: when True, mod_inlets[0] is the module's primary driving
    texture (not optional modulation) and shares pix inlet 0 with control
    messages, per Vsynth convention ("in[0] is the driving texture if
    needed, as well as all control messages"). mod_inlets[i] then wires to
    pix inlet i (not i+1). Use for generators whose core content comes
    from an external texture (e.g. f_vf_seeds), not for optional secondary
    modulation on an otherwise self-sufficient generator (e.g. f_vf_vortex,
    where pix inlet 0 is control-only and mod_inlets start at inlet 1).
    """
    lines = []
    offset = 0 if driving_inlet else 1
    for i, mi in enumerate(mod_inlets):
        instate_id  = mod_instate_obj_id(i)
        use_instate = mi.get("vs_instate", True)
        # mod_inlets[0] under driving_inlet has no dedicated inlet object
        # (see mod_inlet_boxes) — it shares outer inlet 0, so its wiring
        # sources from OBJ_ROUTEPASS's texture outlet instead. build()
        # must not also emit its own unconditional OBJ_ROUTEPASS→pix
        # inlet-0 wire in this case (would double-feed pix inlet 0).
        is_driving_primary = driving_inlet and i == 0
        source_id = OBJ_ROUTEPASS if is_driving_primary else mod_inlet_obj_id(i)
        if use_instate:
            # source → vs_inState → pix inlet i+offset
            lines.append(wire(source_id, 0, instate_id, 0))
            lines.append(wire(instate_id, 0, OBJ_PIX, i + offset))
            # optional state_param feedback
            if mi.get("state_param"):
                pre_id = mod_state_pre_id(i)
                lines.append(wire(instate_id, 1, pre_id, 0))
                lines.append(wire(pre_id, 0, OBJ_PIX, 0))
        else:
            # source → pix inlet i+offset directly (no vs_inState)
            lines.append(wire(source_id, 0, OBJ_PIX, i + offset))
    return lines

def mod_state_pre_boxes(mod_inlets):
    """Generate prepend param <state_param> boxes for mod inlets that declare one."""
    boxes = []
    for i, mi in enumerate(mod_inlets):
        if mi.get("state_param"):
            pre_id = mod_state_pre_id(i)
            boxes.append(box(pre_id,
                maxclass="newobj", numinlets=1, numoutlets=1, outlettype=[""],
                patching_rect=[30.0 + (i + 1) * 60.0, 130.0, 160.0, 22.0],
                text=f"prepend param {mi['state_param']}"))
    return boxes


# ---------------------------------------------------------------------------
# Gen subpatcher builder
# ---------------------------------------------------------------------------

def gen_subpatcher(codebox, archetype, mod_inlets=None, n_outlets=1, driving_inlet=False):
    """
    mod_inlets: list of mod inlet dicts (from definition). When present,
    adds in 2, in 3, ... objects and wires them to codebox inlets 1, 2, ...
    The base in 1 (bang/render trigger) is always inlet 0 of the codebox.
    n_outlets: number of gen out objects (and codebox outlets) to generate.

    driving_inlet: when True, there is no separate bang-only "in 1" — the
    module's core content comes from an external texture, so mod_inlets[0]
    IS "in 1" (codebox inlet 0), mod_inlets[1] is "in 2" (inlet 1), etc.
    Per Vsynth convention: inlet 0 carries the driving texture plus all
    control messages, never a phantom control-only channel. Do not set
    this for generators with true optional modulation on an otherwise
    self-sufficient base (e.g. f_vf_vortex) — there, the bang-only in 1
    is correct.
    """
    mod_inlets = mod_inlets or []
    boxes = []
    lines = []

    if not driving_inlet:
        boxes.append({"box": {
            "id": "gen-obj-1", "maxclass": "newobj",
            "numinlets": 0, "numoutlets": 1, "outlettype": [""],
            "patching_rect": [22.0, 30.0, 28.0, 22.0], "text": "in 1"
        }})

    # Extra gen inlet objects for modulation (in 2, in 3, ...) — or, when
    # driving_inlet, these ARE the primary content inlets (in 1, in 2, ...)
    for i, _ in enumerate(mod_inlets):
        gen_in_id = f"gen-obj-{10 + i}"
        in_num = i + 1 if driving_inlet else i + 2
        boxes.append({"box": {
            "id": gen_in_id, "maxclass": "newobj",
            "numinlets": 0, "numoutlets": 1, "outlettype": [""],
            "patching_rect": [80.0 + i * 58.0, 30.0, 28.0, 22.0],
            "text": f"in {in_num}"
        }})

    # Total codebox inlets: driving_inlet has no separate bang tap, so it's
    # just len(mod_inlets); otherwise 1 (base bang) + len(mod_inlets).
    n_codebox_inlets = len(mod_inlets) if driving_inlet else 1 + len(mod_inlets)

    if archetype == "source" and not mod_inlets:
        # Original source: in 1 + r draw + codebox
        # r draw fires every render frame in the Vsynth GL context — required for
        # self-generating patches that need no upstream texture to render.
        boxes.append({"box": {
            "id": "gen-obj-2", "maxclass": "newobj",
            "numinlets": 0, "numoutlets": 1, "outlettype": [""],
            "patching_rect": [120.0, 30.0, 40.0, 22.0], "text": "r draw"
        }})
        codebox_outlettype = [""] * n_outlets
        boxes.append({"box": {
            "code": codebox,
            "fontface": 0, "fontname": "<Monospaced>", "fontsize": 12.0,
            "id": "gen-obj-3", "maxclass": "codebox",
            "numinlets": 2, "numoutlets": n_outlets, "outlettype": codebox_outlettype,
            "patching_rect": [22.0, 80.0, 550.0, 380.0]
        }})
        for k in range(n_outlets):
            out_id = f"gen-obj-{4 + k}"
            boxes.append({"box": {
                "id": out_id, "maxclass": "newobj",
                "numinlets": 1, "numoutlets": 0,
                "patching_rect": [22.0 + k * 60.0, 490.0, 35.0, 22.0],
                "text": f"out {k + 1}"
            }})
        lines = [
            {"patchline": {"destination": ["gen-obj-3", 0], "source": ["gen-obj-1", 0]}},
            {"patchline": {"destination": ["gen-obj-3", 1], "source": ["gen-obj-2", 0]}},
        ]
        for k in range(n_outlets):
            lines.append({"patchline": {"destination": [f"gen-obj-{4 + k}", 0], "source": ["gen-obj-3", k]}})
    elif archetype == "source" and mod_inlets:
        # Source with modulation inlets: add r draw for render trigger
        boxes.append({"box": {
            "id": "gen-obj-2", "maxclass": "newobj",
            "numinlets": 0, "numoutlets": 1, "outlettype": [""],
            "patching_rect": [120.0, 30.0, 40.0, 22.0], "text": "r draw"
        }})
        codebox_id = "gen-obj-3"
        codebox_outlettype = [""] * n_outlets
        boxes.append({"box": {
            "code": codebox,
            "fontface": 0, "fontname": "<Monospaced>", "fontsize": 12.0,
            "id": codebox_id, "maxclass": "codebox",
            "numinlets": n_codebox_inlets, "numoutlets": n_outlets, "outlettype": codebox_outlettype,
            "patching_rect": [22.0, 80.0, 550.0, 380.0]
        }})
        for k in range(n_outlets):
            out_id = f"gen-obj-{4 + k}"
            boxes.append({"box": {
                "id": out_id, "maxclass": "newobj",
                "numinlets": 1, "numoutlets": 0,
                "patching_rect": [22.0 + k * 60.0, 490.0, 35.0, 22.0],
                "text": f"out {k + 1}"
            }})
        if not driving_inlet:
            lines.append({"patchline": {"destination": [codebox_id, 0], "source": ["gen-obj-1", 0]}})
        # r draw (gen-obj-2) exists free-standing — its presence triggers gen each frame
        # it is NOT wired to the codebox
        cb_offset = 0 if driving_inlet else 1
        for i in range(len(mod_inlets)):
            gen_in_id = f"gen-obj-{10 + i}"
            lines.append({"patchline": {"destination": [codebox_id, i + cb_offset], "source": [gen_in_id, 0]}})
        for k in range(n_outlets):
            lines.append({"patchline": {"destination": [f"gen-obj-{4 + k}", 0], "source": [codebox_id, k]}})
    else:
        # processor and dual
        n_codebox_inlets = 1 + len(mod_inlets)
        codebox_id = "gen-obj-2"
        codebox_outlettype = [""] * n_outlets
        boxes.append({"box": {
            "code": codebox,
            "fontface": 0, "fontname": "<Monospaced>", "fontsize": 12.0,
            "id": codebox_id, "maxclass": "codebox",
            "numinlets": n_codebox_inlets, "numoutlets": n_outlets, "outlettype": codebox_outlettype,
            "patching_rect": [22.0, 80.0, 550.0, 380.0]
        }})
        for k in range(n_outlets):
            out_id = f"gen-obj-{3 + k}"
            boxes.append({"box": {
                "id": out_id, "maxclass": "newobj",
                "numinlets": 1, "numoutlets": 0,
                "patching_rect": [22.0 + k * 60.0, 490.0, 35.0, 22.0],
                "text": f"out {k + 1}"
            }})
        lines.append({"patchline": {"destination": [codebox_id, 0], "source": ["gen-obj-1", 0]}})
        for i in range(len(mod_inlets)):
            gen_in_id = f"gen-obj-{10 + i}"
            lines.append({"patchline": {"destination": [codebox_id, i + 1], "source": [gen_in_id, 0]}})
        for k in range(n_outlets):
            lines.append({"patchline": {"destination": [f"gen-obj-{3 + k}", 0], "source": [codebox_id, k]}})

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

def pix_box(p, object_name, codebox, archetype, mod_inlets=None, pix_type=None, outlets=None, adapt=False, driving_inlet=False):
    mod_inlets = mod_inlets or []
    outlets    = outlets or [{"comment": "texture out"}]
    type_attr  = f" @type {pix_type}" if pix_type else ""
    adapt_attr = " @adapt 1" if adapt else ""
    n_outer_inlets = len(mod_inlets) if driving_inlet else 1 + len(mod_inlets)
    n_outlets      = len(outlets)
    outlettype     = ["jit_gl_texture"] * n_outlets + [""]
    return box(OBJ_PIX,
        maxclass="newobj",
        numinlets=n_outer_inlets, numoutlets=n_outlets + 1,
        outlettype=outlettype,
        patcher=gen_subpatcher(codebox, archetype, mod_inlets, n_outlets, driving_inlet=driving_inlet),
        patching_rect=[200.0, 380.0, max(200.0, len(object_name) * 8.0 + 80.0), 22.0],
        text=f"jit.gl.pix vsynth @name {object_name}{type_attr}{adapt_attr}",
        varname=object_name)

# ---------------------------------------------------------------------------
# Multi-pix chain support
# ---------------------------------------------------------------------------

def gen_identity():
    """Trivial identity gen: in 1 → out 1. Used for pass_pix nodes."""
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


def chain_pix_obj_id(node):
    """Return obj-id for a pix_chain node. Primary → OBJ_PIX; support → obj-50+."""
    if node["primary"]:
        return OBJ_PIX
    return f"obj-{50 + node['_support_index']}"


def build_pix_chain(defn, def_dir):
    """
    Build boxes and cross-pix wires for a pix_chain definition.

    Returns (chain_boxes, chain_lines, primary_obj_id, primary_node, id_to_obj)
      chain_boxes    — jit.gl.pix box dicts for all nodes
      chain_lines    — patchlines for pix_wires cross-wiring only
      primary_obj_id — obj-id of the primary pix
      primary_node   — the primary node dict
      id_to_obj      — {chain node "id": obj-id}, for params targeting a
                        support node via "pix_target" (added 2026-07-15,
                        for f_lens halation — see param loop in build())
    """
    chain      = [dict(n) for n in defn["pix_chain"]]  # shallow copy to annotate
    wires_spec = defn.get("pix_wires", [])

    # Annotate support index (position among non-primary nodes, in chain order)
    support_idx = 0
    for node in chain:
        if node["primary"]:
            node["_support_index"] = None
        else:
            node["_support_index"] = support_idx
            support_idx += 1

    id_to_obj      = {node["id"]: chain_pix_obj_id(node) for node in chain}
    primary_node   = next(n for n in chain if n["primary"])
    primary_obj_id = id_to_obj[primary_node["id"]]

    chain_boxes = []
    for node in chain:
        obj_id     = id_to_obj[node["id"]]
        name       = node["name"]
        pix_type   = node.get("pix_type")
        adapt      = node.get("adapt", False)
        n_in       = node["n_inlets"]
        n_out      = node["n_outlets"]
        type_attr  = f" @type {pix_type}" if pix_type else ""
        adapt_attr = " @adapt 1" if adapt else ""
        outlettype = ["jit_gl_texture"] * n_out + [""]

        gen_spec = node.get("gen", "")
        if gen_spec == "pass":
            gen = gen_identity()
        else:
            cb_path = def_dir / gen_spec
            codebox = cb_path.read_text()
            # Processor-style gen; extra inlets beyond in1 are mod_inlet placeholders
            gen = gen_subpatcher(codebox, "processor",
                                 mod_inlets=[{}] * (n_in - 1),
                                 n_outlets=n_out)

        y_rect = (380.0 + node["_support_index"] * 60.0
                  if not node["primary"] else 380.0)
        chain_boxes.append(box(obj_id,
            maxclass="newobj",
            numinlets=n_in, numoutlets=n_out + 1,
            outlettype=outlettype,
            patcher=gen,
            patching_rect=[200.0, y_rect, max(200.0, len(name) * 8.0 + 80.0), 22.0],
            text=f"jit.gl.pix vsynth @name {name}{type_attr}{adapt_attr}",
            varname=name))

    # Cross-pix wires from pix_wires spec
    chain_lines = []
    for w in wires_spec:
        src_id, src_out, dst_id, dst_in = w
        chain_lines.append({"patchline": {
            "source":      [id_to_obj[src_id], src_out],
            "destination": [id_to_obj[dst_id], dst_in],
        }})

    return chain_boxes, chain_lines, primary_obj_id, primary_node, id_to_obj


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
    title       = defn["title"]
    pw          = float(defn["presentation_width"])
    ph          = float(defn["presentation_height"])
    all_params  = defn["params"]
    mod_inlets  = defn.get("mod_inlets", [])
    outlets     = defn.get("outlets", [{"comment": "texture out"}])

    # Validate: vs_instate:False and state_param are mutually exclusive
    for mi in mod_inlets:
        if not mi.get("vs_instate", True) and mi.get("state_param"):
            raise ValueError(f"mod_inlet '{mi.get('label')}': vs_instate:False and state_param are mutually exclusive")

    # Separate param types
    ui_params       = [p for p in all_params if p["type"] in ("float", "int", "menu", "text_button")]
    header_toggles  = [p for p in all_params if p["type"] == "header_toggle"]
    internal_params = [p for p in all_params if p["type"] == "internal"]
    # raw_ui: reserves a route outlet (dispatched by name) but generates NO
    # dial/label/attrui/pix-wire — the param's UI and downstream wiring are
    # supplied verbatim via definition.py's raw_boxes/raw_lines instead.
    # Added 2026-07-15 for f_lens's tilt-shift params, which have real UI
    # and route dispatch but target a secondary non-primary object
    # (jit.fx.cf.tiltshift) via bespoke per-param transform logic (e.g.
    # lens_tiltcenter.js combining tilt_axis+tilt_pos) that doesn't fit a
    # generic "downstream target" schema. See ideas/build_patcher_schema_gaps.md.
    raw_ui_params   = [p for p in all_params if p["type"] == "raw_ui"]
    # bypass is handled separately

    # Route param names = ui params + header toggles + raw_ui params (in that
    # order) — raw_ui params still need a route outlet, just no generated UI.
    route_params = ui_params + header_toggles + raw_ui_params

    # bypass IDs — placed after all per-param objects
    bp_jsui_id = bypass_jsui_id(len(ui_params))
    bp_pre_id  = bypass_pre_id(len(ui_params))

    # ---------------------------------------------------------------------------
    # Pix box(es) — single-pix or pix_chain path
    # ---------------------------------------------------------------------------
    pix_chain = defn.get("pix_chain")

    if pix_chain:
        # Multi-pix path
        def_dir = Path(defn.get("_def_path", ".")).parent
        chain_boxes, chain_lines, primary_obj_id, primary_node, chain_id_to_obj = build_pix_chain(defn, def_dir)
        object_name = primary_node["name"]   # @name of primary pix — used for param_connect
        archetype   = defn.get("archetype", "processor")
        pix_boxes_to_add = chain_boxes
        extra_pix_lines  = chain_lines
    else:
        # Single-pix path (existing behaviour)
        object_name = defn["object_name"]
        archetype   = defn["archetype"]
        codebox     = defn["codebox"]
        pix_type    = defn.get("pix_type", None)
        driving_inlet = defn.get("driving_inlet", False)
        primary_obj_id   = OBJ_PIX
        pix_boxes_to_add = [pix_box(prefix, object_name, codebox, archetype,
                                    mod_inlets, pix_type, outlets,
                                    adapt=defn.get("pix_adapt", False),
                                    driving_inlet=driving_inlet)]
        extra_pix_lines  = []
        chain_id_to_obj  = {}

    # Build boxes — pix must come before bypass jsui (param_connect dependency)
    boxes = []
    boxes.append(inlet_box())
    boxes.extend(outlet_boxes(outlets))
    boxes.append(routepass_box())
    boxes.append(route_box(route_params))
    boxes.extend(pix_boxes_to_add)
    boxes.append(autopattr_box(prefix))
    boxes.append(panel_box(pw, ph))
    boxes.append(title_box(title))
    signal_type = defn.get("signal_type")
    if signal_type:
        boxes.append(signal_type_box(signal_type, title))
    boxes.extend(modulesize_boxes())

    panel_toggle = defn.get("panel_toggle")
    if panel_toggle:
        pt = dict(panel_toggle)
        pt.setdefault("js_filename", f"{prefix}_toggle.js")
        boxes.extend(panel_toggle_boxes(pt, pw))
        # Write the generated per-module toggle JS as a side effect —
        # path is relative to this script's own location (build/../package/
        # javascript/), not cwd, so it's correct regardless of how
        # build_patcher.py is invoked.
        js_content = panel_toggle_js_content(pt.get("front", []), pt.get("back", []))
        js_path = Path(__file__).parent.parent / "package" / "javascript" / pt["js_filename"]
        js_path.write_text(js_content)

    if archetype == "dual":
        boxes.extend(instate_boxes())

    # r draw for source archetype — wired to pix inlet 0 as render trigger
    OBJ_RDRAW = "obj-20a"
    if archetype == "source":
        boxes.append(box(OBJ_RDRAW,
            maxclass="newobj", numinlets=0, numoutlets=1, outlettype=[""],
            patching_rect=[400.0, 30.0, 50.0, 22.0], text="r draw"))

    # Modulation inlet boxes (inlet + optional vs_inState per mod inlet, plus state prepends)
    if mod_inlets:
        boxes.extend(mod_inlet_boxes(mod_inlets, driving_inlet=defn.get("driving_inlet", False)))
        boxes.extend(mod_state_pre_boxes(mod_inlets))

    # Per-param boxes (grid — float and int only)
    for n, p in enumerate(ui_params):
        if p["type"] == "float" and p.get("widget") == "numbox":
            # opt-in override for the library's mix/dry-wet crossfade
            # convention (vsynth-bpatcher/SKILL.md) -- live.numbox instead
            # of the float-param default live.dial
            boxes.append(numbox_box(n, p, object_name))
        elif p["type"] == "float":
            boxes.append(dial_box(n, p, object_name))
        elif p["type"] == "int":
            boxes.append(numbox_box(n, p, object_name))
        elif p["type"] == "menu":
            boxes.append(menu_box(n, p, object_name))
        elif p["type"] == "text_button":
            boxes.append(text_button_box(n, p, object_name))
        boxes.append(attrui_box(param_pre_id(n), p["name"],
                                50.0 + n * 50.0, 170.0 + n * 30.0))
        if p["type"] != "text_button":
            boxes.append(label_box(n, p))
        if p.get("range_tiers"):
            boxes.extend(range_tier_boxes(n, p))

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
        # routepass out0 → vs_inState → primary pix
        lines.append(wire(OBJ_ROUTEPASS, 0, OBJ_INSTATE, 0))
        lines.append(wire(OBJ_INSTATE, 0, primary_obj_id, 0))
        lines.append(wire(OBJ_INSTATE, 1, OBJ_SRCMODE_PRE, 0))
        lines.append(wire(OBJ_SRCMODE_PRE, 0, primary_obj_id, 0))
    elif archetype == "source":
        # routepass out0 → primary pix (texture trigger) — suppressed when
        # driving_inlet + mod_inlets are present, since mod_inlet_lines()
        # already sources mod_inlets[0] from OBJ_ROUTEPASS directly (this
        # avoids double-feeding pix inlet 0 from two separate wires)
        if not (defn.get("driving_inlet", False) and mod_inlets):
            lines.append(wire(OBJ_ROUTEPASS, 0, primary_obj_id, 0))
        # r draw → pix inlet 0 (render trigger for self-generating patches)
        lines.append(wire("obj-20a", 0, primary_obj_id, 0))
    else:
        # routepass out0 → primary pix
        lines.append(wire(OBJ_ROUTEPASS, 0, primary_obj_id, 0))

    # routepass out2 (unmatched) → route
    lines.append(wire(OBJ_ROUTEPASS, 2, OBJ_ROUTE, 0))

    # primary pix outN → outletN (one wire per outlet), unless overridden.
    # outlet_source_override: {outlet_index: raw_object_id} — when a raw_boxes
    # object sits between the primary pix and this outlet (e.g. f_lens's
    # tiltshift, downstream of lens_pix), skip the direct wire here; the
    # pix→raw-object and raw-object→outlet wires are supplied via raw_lines
    # instead. Added 2026-07-15, see raw_ui_params note above.
    outlet_overrides = defn.get("outlet_source_override", {})
    for i in range(len(outlets)):
        if i not in outlet_overrides:
            lines.append(wire(primary_obj_id, i, outlet_obj_id(i), 0))

    # modulation inlets → (vs_inState →) primary pix
    if mod_inlets:
        lines.extend(mod_inlet_lines(mod_inlets, driving_inlet=defn.get("driving_inlet", False)))

    # bypass jsui → prepend bypass → primary pix
    lines.append(wire(bp_jsui_id, 0, bp_pre_id, 0))
    lines.append(wire(bp_pre_id, 0, primary_obj_id, 0))

    # panel_toggle → js → thispatcher (reuses the same thispatcher object
    # modulesize already wires up for its own getattr flow — a thispatcher
    # object just executes whatever properly-formed message it receives,
    # regardless of source, so sharing it is safe)
    if panel_toggle:
        lines.append(wire(OBJ_PANEL_TOGGLE, 0, OBJ_PANEL_TOGGLE_JS, 0))
        lines.append(wire(OBJ_PANEL_TOGGLE_JS, 0, OBJ_THISPATCHER, 0))

    # cross-pix wires (pix_chain only)
    lines.extend(extra_pix_lines)

    # moduleSize chain
    lines.append(wire(OBJ_LOADBANG, 0, OBJ_GETATTR, 0))
    lines.append(wire(OBJ_GETATTR, 0, OBJ_THISPATCHER, 0))
    lines.append(wire(OBJ_THISPATCHER, 0, OBJ_ZLSLICE, 0))
    lines.append(wire(OBJ_ZLSLICE, 1, OBJ_PRETAM, 0))
    lines.append(wire(OBJ_PRETAM, 0, OBJ_MODULESIZE, 0))

    # route outlets → grid controls → prepends → primary pix (or a support
    # pix node, if the param declares "pix_target": "<chain node id>" —
    # added 2026-07-15 for f_lens halation, a pix_chain support node with
    # its own independently-dialed params, unlike the standard pix_chain
    # case where only the primary node is ever a param target)
    for n, p in enumerate(ui_params):
        # pix_target resolution: a pix_chain node id (looked up via
        # chain_id_to_obj) OR, if not found there, treated as a literal
        # object id directly — added 2026-07-15 to also support params
        # targeting a manually-declared raw_boxes object (e.g. f_lens's
        # halation pix), without requiring the primary pix itself to be
        # restructured into a pix_chain.
        pt = p.get("pix_target")
        target = chain_id_to_obj.get(pt, pt) if pt else primary_obj_id
        lines.append(wire(OBJ_ROUTE, n, param_obj_id(n), 0))
        lines.append(wire(param_obj_id(n), 0, param_pre_id(n), 0))
        lines.append(wire(param_pre_id(n), 0, target, 0))
        if p.get("range_tiers"):
            # menu → sel
            lines.append(wire(range_menu_id(n), 0, range_sel_id(n), 0))
            # sel outN → messageN → dial
            for t in range(len(p["range_tiers"])):
                lines.append(wire(range_sel_id(n), t, range_msg_id(n, t), 0))
                lines.append(wire(range_msg_id(n, t), 0, param_obj_id(n), 0))

    # route outlets → header toggles → prepends → primary pix
    if header_toggles:
        ht_outlet = len(ui_params)   # header toggles come after ui_params in route
        lines.append(wire(OBJ_ROUTE, ht_outlet, OBJ_HEADER_TOGGLE, 0))
        lines.append(wire(OBJ_HEADER_TOGGLE, 0, OBJ_HEADER_TOGGLE_PRE, 0))
        lines.append(wire(OBJ_HEADER_TOGGLE_PRE, 0, primary_obj_id, 0))

    # parameters block — grid params + header toggles (not bypass jsui)
    params_block = {}
    for n, p in enumerate(ui_params):
        params_block[param_obj_id(n)] = [p["name"], p["name"], 0]
    if header_toggles:
        params_block[OBJ_HEADER_TOGGLE] = [header_toggles[0]["name"], header_toggles[0]["name"], 0]
    if panel_toggle:
        params_block[OBJ_PANEL_TOGGLE] = ["panel_toggle", "panel_toggle", 0]
    params_block["parameterbanks"] = {"0": {
        "index": 0, "name": "",
        "parameters": ["-","-","-","-","-","-","-","-"],
        "buttons":    ["-","-","-","-","-","-","-","-"]
    }}
    params_block["inherited_shortname"] = 1

    # raw_boxes / raw_lines: verbatim box/patchline dicts (already in the
    # exact {"box": {...}} / {"patchline": {...}} wrapper shape used
    # throughout this file), appended unmodified. Added 2026-07-15 for
    # content the schema doesn't (yet) model generically — see raw_ui_params
    # note above. Author is responsible for using object IDs that don't
    # collide with any schema-generated ID (UI_PARAM_BASE-derived, fixed
    # constants, range-tier obj-300+ range, etc.) — extract-and-remap from
    # a working reference file rather than hand-picking IDs from scratch.
    boxes.extend(defn.get("raw_boxes", []))
    lines.extend(defn.get("raw_lines", []))
    # raw_parameters: {obj_id: [longname, shortname, 0]} for raw_boxes objects
    # that need autopattr state persistence (must use the same remapped IDs
    # as the corresponding raw_boxes entries).
    params_block.update(defn.get("raw_parameters", {}))

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
    defn = mod.patcher
    defn["_def_path"] = str(Path(path).resolve())
    return defn

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 build/build_patcher.py .specify/f_<name>/definition.py")
        sys.exit(1)

    def_path  = Path(sys.argv[1])
    defn      = load_definition(def_path)
    result    = build(defn)

    repo_root = Path(__file__).parent.parent
    out_path  = repo_root / "package" / "patchers" / f"{defn['name']}.maxpat"

    with open(out_path, "w") as f:
        json.dump(result, f, indent="\t")

    print(f"Written: {out_path}")

if __name__ == "__main__":
    main()
