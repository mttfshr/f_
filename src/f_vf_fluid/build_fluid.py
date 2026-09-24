#!/usr/bin/env python3
"""
build_fluid.py -- generates package/patchers/f_vf_fluid.maxpat (plan ADR-9).

A dedicated build script in the build_advect.py / build_seeds_multistage.py
tradition: the eight-stage chain cannot be expressed by build_patcher.py's
pix_chain schema (inlet fan-out through vs_inState, `r draw` triggers, per-stage
@dim, params reaching several stages, a Param-based bypass). Shared chrome
(panel, title, dials, moduleSize chain, autopattr, ...) comes from
build/build_patcher.py so the module looks and behaves like every other f_ one;
UI parameter specs come from definition.py.

Stage chain (plan ADR-1/ADR-2; codeboxes in this directory):

    r draw -> adv (in0)         force -> vs_inState -> adv (in1), enc (in1)
    pass -> adv (in2) -> fx -> fy -> spec -> iy -> ix -> pass       (feedback)
                                                    ix -> enc (in2) -> outlet
    r draw -> enc (in0)   [makes enc take the render-context size, never 1x1]

Solver stages are @adapt 0 @dim 256 256 float32; only enc follows the render
size. Bypass is a Param gate on enc (jsui -> prepend param bypass_gate), NOT
the native pix @bypass (plan ADR-8).

Run:  python3 src/f_vf_fluid/build_fluid.py
"""
import importlib.util
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parent.parent
sys.path.insert(0, str(REPO / "build"))

import build_patcher as bp                      # shared chrome helpers
from build_patcher import box, wire

NAME = "f_vf_fluid"
N = 256

OBJ_RDRAW = "obj-20a"
OBJ_SRCPRE = bp.OBJ_SRCMODE_PRE                 # prepend param src_vecfield
OBJ_INSTATE = bp.OBJ_INSTATE                    # vs_inState on the force inlet

# key -> (object id, scoped @name, codebox file or None for identity, n_inlets, pix attrs)
SOLVER_ATTRS = f"@adapt 0 @dim {N} {N} @type float32"
STAGES = {
    "pass": ("obj-50", "#0_fluid_pass", None,                    1, SOLVER_ATTRS),
    "adv":  ("obj-51", "#0_fluid_adv",  "codebox_adv.gen",       3, SOLVER_ATTRS),
    "fx":   ("obj-52", "#0_fluid_fx",   "codebox_dft_fx.gen",    1, SOLVER_ATTRS),
    "fy":   ("obj-53", "#0_fluid_fy",   "codebox_dft_fy.gen",    1, SOLVER_ATTRS),
    "spec": ("obj-54", "#0_fluid_spec", "codebox_spec.gen",      1, SOLVER_ATTRS),
    "iy":   ("obj-55", "#0_fluid_iy",   "codebox_dft_iy.gen",    1, SOLVER_ATTRS),
    "ix":   ("obj-56", "#0_fluid_ix",   "codebox_dft_ix.gen",    1, SOLVER_ATTRS),
    "enc":  (bp.OBJ_PIX, "#0_fluid_enc", "codebox_enc.gen",      3, "@adapt 1 @type float32"),
}
SID = {k: v[0] for k, v in STAGES.items()}
SNAME = {k: v[1] for k, v in STAGES.items()}

# UI parameter -> stage(s) whose codebox Param it sets (first entry = param_connect target)
TARGETS = {
    "force": ["adv"], "dt": ["adv", "spec"], "viscosity": ["spec"],
    "project": ["spec"], "drag": ["spec"], "gain": ["enc"],
}


def load_definition():
    spec = importlib.util.spec_from_file_location("definition", HERE / "definition.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod.patcher


def gen_stage(codebox, n_in):
    """jit.gen patcher: in 1..n -> codebox -> out 1."""
    boxes = [{"box": {"id": f"gen-obj-{i + 1}", "maxclass": "newobj", "numinlets": 0, "numoutlets": 1,
                      "outlettype": [""], "patching_rect": [22.0 + 58.0 * i, 30.0, 28.0, 22.0],
                      "text": f"in {i + 1}"}} for i in range(n_in)]
    cb, out = f"gen-obj-{n_in + 1}", f"gen-obj-{n_in + 2}"
    boxes.append({"box": {"id": cb, "maxclass": "codebox", "code": codebox, "fontface": 0,
                          "fontname": "<Monospaced>", "fontsize": 12.0, "numinlets": n_in,
                          "numoutlets": 1, "outlettype": [""],
                          "patching_rect": [22.0, 80.0, 550.0, 380.0]}})
    boxes.append({"box": {"id": out, "maxclass": "newobj", "numinlets": 1, "numoutlets": 0,
                          "patching_rect": [22.0, 490.0, 35.0, 22.0], "text": "out 1"}})
    lines = [{"patchline": {"source": [f"gen-obj-{i + 1}", 0], "destination": [cb, i]}} for i in range(n_in)]
    lines.append({"patchline": {"source": [cb, 0], "destination": [out, 0]}})
    return {"fileversion": 1,
            "appversion": {"major": 9, "minor": 1, "revision": 4, "architecture": "x64", "modernui": 1},
            "classnamespace": "jit.gen", "rect": [100.0, 100.0, 700.0, 600.0],
            "boxes": boxes, "lines": lines}


def pix_boxes():
    out = []
    for i, (key, (oid, name, cbfile, n_in, attrs)) in enumerate(STAGES.items()):
        gen = bp.gen_identity() if cbfile is None else gen_stage((HERE / cbfile).read_text(), n_in)
        x, y = (520.0, 300.0) if key == "enc" else (200.0, 250.0 + 32.0 * i)
        out.append(box(oid, maxclass="newobj", numinlets=n_in, numoutlets=2,
                       outlettype=["jit_gl_texture", ""], patcher=gen,
                       patching_rect=[x, y, 330.0, 22.0],
                       text=f"jit.gl.pix vsynth @name {name} {attrs}", varname=name))
    return out


def build():
    d = load_definition()
    prefix, title = d["prefix"], d["title"]
    pw, ph = float(d["presentation_width"]), float(d["presentation_height"])
    ui = [p for p in d["params"] if p["type"] == "float"]
    assert [p["name"] for p in ui] == list(TARGETS), "definition.py params must match TARGETS (order too)"
    n_ui = len(ui)
    bp_jsui, bp_pre = bp.bypass_jsui_id(n_ui), bp.bypass_pre_id(n_ui)
    enc = SID["enc"]

    boxes = [
        box(bp.OBJ_INLET, maxclass="inlet", comment="force vecfield / control", index=0,
            numinlets=0, numoutlets=1, outlettype=[""], patching_rect=[30.0, 30.0, 30.0, 30.0]),
        *bp.outlet_boxes(d["outlets"]),
        bp.routepass_box(),
        bp.route_box(ui),
        *pix_boxes(),
        box(OBJ_INSTATE, maxclass="newobj", numinlets=1, numoutlets=2, outlettype=["", ""],
            patching_rect=[200.0, 60.0, 80.0, 22.0], text="vs_inState"),
        box(OBJ_SRCPRE, maxclass="newobj", numinlets=1, numoutlets=1, outlettype=[""],
            patching_rect=[350.0, 60.0, 175.0, 22.0], text="prepend param src_vecfield"),
        box(OBJ_RDRAW, maxclass="newobj", numinlets=0, numoutlets=1, outlettype=[""],
            patching_rect=[560.0, 30.0, 50.0, 22.0], text="r draw"),
        bp.autopattr_box(prefix),
        bp.panel_box(pw, ph),
        bp.title_box(title),
        bp.signal_type_box(d["signal_type"], title),
        *bp.modulesize_boxes(),
    ]

    extra_attruis = []                               # (attrui id, param name, stage key)
    for n, p in enumerate(ui):
        stages = TARGETS[p["name"]]
        boxes.append(bp.dial_box(n, p, SNAME[stages[0]]))
        boxes.append(bp.attrui_box(bp.param_pre_id(n), p["name"], 50.0 + n * 50.0, 170.0 + n * 30.0))
        boxes.append(bp.label_box(n, p))
        for k, extra in enumerate(stages[1:]):
            aid = f"obj-{60 + len(extra_attruis)}"
            boxes.append(bp.attrui_box(aid, p["name"], 400.0, 170.0 + 30.0 * len(extra_attruis)))
            extra_attruis.append((aid, n, extra))

    # bypass LAST (after the pix boxes): jsui -> prepend param bypass_gate -> enc.
    # Deliberately NOT bp.bypass_attrui_box: no native `bypass` attribute anywhere.
    boxes.append(bp.bypass_jsui_box(bp_jsui, SNAME["enc"], pw))
    boxes.append(box(bp_pre, maxclass="newobj", numinlets=1, numoutlets=1, outlettype=[""],
                     patching_rect=[400.0, 60.0, 160.0, 22.0], text="prepend param bypass_gate"))

    lines = [
        wire(bp.OBJ_INLET, 0, bp.OBJ_ROUTEPASS, 0),
        wire(bp.OBJ_ROUTEPASS, 0, OBJ_INSTATE, 0),               # force texture -> vs_inState
        wire(bp.OBJ_ROUTEPASS, 2, bp.OBJ_ROUTE, 0),              # control messages -> route
        wire(OBJ_INSTATE, 0, SID["adv"], 1),                     # force (cold inlet)
        wire(OBJ_INSTATE, 0, enc, 1),                            # force passthrough (cold)
        wire(OBJ_INSTATE, 1, OBJ_SRCPRE, 0),
        wire(OBJ_SRCPRE, 0, SID["adv"], 0),
        wire(OBJ_SRCPRE, 0, enc, 0),
        wire(OBJ_RDRAW, 0, SID["adv"], 0),                       # per-frame triggers (plan ADR-2)
        wire(OBJ_RDRAW, 0, enc, 0),
        wire(SID["pass"], 0, SID["adv"], 2),                     # previous state
        wire(SID["adv"], 0, SID["fx"], 0),
        wire(SID["fx"], 0, SID["fy"], 0),
        wire(SID["fy"], 0, SID["spec"], 0),
        wire(SID["spec"], 0, SID["iy"], 0),
        wire(SID["iy"], 0, SID["ix"], 0),
        wire(SID["ix"], 0, SID["pass"], 0),                      # feedback edge
        wire(SID["ix"], 0, enc, 2),                              # velocity -> encode (cold)
        wire(enc, 0, bp.outlet_obj_id(0), 0),
        wire(bp_jsui, 0, bp_pre, 0),
        wire(bp_pre, 0, enc, 0),
        wire(bp.OBJ_LOADBANG, 0, bp.OBJ_GETATTR, 0),
        wire(bp.OBJ_GETATTR, 0, bp.OBJ_THISPATCHER, 0),
        wire(bp.OBJ_THISPATCHER, 0, bp.OBJ_ZLSLICE, 0),
        wire(bp.OBJ_ZLSLICE, 1, bp.OBJ_PRETAM, 0),
        wire(bp.OBJ_PRETAM, 0, bp.OBJ_MODULESIZE, 0),
    ]
    for n, p in enumerate(ui):
        lines.append(wire(bp.OBJ_ROUTE, n, bp.param_obj_id(n), 0))
        lines.append(wire(bp.param_obj_id(n), 0, bp.param_pre_id(n), 0))
        lines.append(wire(bp.param_pre_id(n), 0, SID[TARGETS[p["name"]][0]], 0))
    for aid, n, stage in extra_attruis:
        lines.append(wire(bp.param_obj_id(n), 0, aid, 0))
        lines.append(wire(aid, 0, SID[stage], 0))

    params_block = {bp.param_obj_id(n): [p["name"], p["name"], 0] for n, p in enumerate(ui)}
    params_block["parameterbanks"] = {"0": {"index": 0, "name": "",
                                            "parameters": ["-"] * 8, "buttons": ["-"] * 8}}
    params_block["inherited_shortname"] = 1

    return {"patcher": {"fileversion": 1,
                        "appversion": {"major": 9, "minor": 1, "revision": 4,
                                       "architecture": "x64", "modernui": 1},
                        "classnamespace": "box", "rect": [100.0, 100.0, 800.0, 600.0],
                        "openinpresentation": 1, "boxes": boxes, "lines": lines,
                        "parameters": params_block, "autosave": 0}}


def verify(result):
    """Static self-check (tasks.md T029): unique ids, no dangling wires, every route
    token wired to the same-named control, #0-scoped unique pix names, and no native
    bypass attribute anywhere."""
    p = result["patcher"]
    ids = [b["box"]["id"] for b in p["boxes"]]
    assert len(ids) == len(set(ids)), "duplicate box ids"
    boxes = {b["box"]["id"]: b["box"] for b in p["boxes"]}
    for l in p["lines"]:
        pl = l["patchline"]
        assert pl["source"][0] in boxes and pl["destination"][0] in boxes, f"dangling wire {pl}"
    route = boxes[bp.OBJ_ROUTE]
    toks = route["text"].split()[1:]
    wired = {}
    for l in p["lines"]:
        pl = l["patchline"]
        if pl["source"][0] == bp.OBJ_ROUTE:
            wired[pl["source"][1]] = boxes[pl["destination"][0]].get("varname")
    assert [wired.get(i) for i in range(len(toks))] == toks, f"route wiring {wired} vs {toks}"
    names = [b["varname"] for b in boxes.values() if b.get("maxclass") == "newobj"
             and str(b.get("text", "")).startswith("jit.gl.pix")]
    assert len(names) == 8 and len(set(names)) == 8 and all(n.startswith("#0_") for n in names), names
    assert not any(b.get("attr") == "bypass" for b in boxes.values()), "native bypass attrui present"
    assert not any("@name" in str(b.get("text", "")) and "#0" not in str(b.get("text", ""))
                   for b in boxes.values() if str(b.get("text", "")).startswith("jit.gl.pix")), "unscoped @name"
    return toks, len(boxes), len(p["lines"])


if __name__ == "__main__":
    result = build()
    toks, nb, nl = verify(result)
    out_path = REPO / "package" / "patchers" / f"{NAME}.maxpat"
    with open(out_path, "w") as f:
        json.dump(result, f, indent="\t")
    print(f"Written: {out_path}  ({nb} boxes, {nl} lines; route tokens: {' '.join(toks)})")
