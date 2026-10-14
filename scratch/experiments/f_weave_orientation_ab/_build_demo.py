#!/usr/bin/env python3
"""
One-off driver: builds the demo wiring patch for the f_weave orientation
A/B scratch test (ideas/f_weave_orientation_blend.md). Not part of the
repo's build pipeline -- scratch/experiments/ only.

Chain: vs_sources_main -> f_vf_optical_flow -> {f_weave_oab (scratch,
dialable), f_weave (shipped, unmodified reference)} -> two vs_preview.

f_weave_oab's field_amount=1.0, fix_blend=0.0 should render pixel-identical
to the f_weave reference -- that's the sanity check before exploring.
"""
import json
from pathlib import Path

# box()/bpatcher() inlined from build/make_missing_helpfiles.py rather than
# imported -- that module runs its own generation pass at import time with
# no __main__ guard, which reverts the helpfile cropping fix on import.
# (Learned the hard way while building this file -- see _refix_helpfiles.py.)

def box(id_, maxclass, rect, text=None, fontsize=12.0, fontname="Ableton Sans Light",
        linecount=None, bubble=False, extra=None):
    b = {"id": id_, "maxclass": maxclass, "numinlets": 1, "numoutlets": 0,
         "patching_rect": rect}
    if maxclass == "comment":
        b.update({"fontface": 0, "fontname": fontname,
                  "bgcolor": [0.2, 0.2, 0.2, 0.0],
                  "saved_attribute_attributes": {"textcolor": {"expression": "themecolor.live_control_fg"}}})
        if bubble:
            b["bgcolor"] = [0.0, 0.0, 0.0, 0.0]
            b["bubble"] = 1
            del b["saved_attribute_attributes"]
    if text is not None:
        b["text"] = text
    if fontsize:
        b["fontsize"] = fontsize
    if linecount:
        b["linecount"] = linecount
    if extra:
        b.update(extra)
    return {"box": b}


def bpatcher(id_, name, rect, n_in, n_out, outlettype, varname=None):
    b = {"id": id_, "maxclass": "bpatcher", "name": name,
         "numinlets": n_in, "numoutlets": n_out, "outlettype": outlettype,
         "patching_rect": rect,
         "bgmode": 1, "border": 1, "clickthrough": 0,
         "enablehscroll": 0, "enablevscroll": 0, "lockeddragscroll": 0,
         "lockedsize": 0, "offset": [0.0, 0.0], "viewvisibility": 1}
    if varname:
        b["varname"] = varname
    return {"box": b}


def main():
    boxes = [
        box("h-1", "comment", [20.0, 15.0, 600.0, 30.0],
            "f_weave orientation A/B -- scratch (ideas/f_weave_orientation_blend.md)",
            fontsize=16.0, fontname="Ableton Sans Medium"),
        box("h-2", "comment", [20.0, 45.0, 600.0, 40.0],
            "field_amount=1.0, fix_blend=0.0 on the left should match the right exactly. "
            "Then explore: fix_blend toward 1 = true angular blend (Fix B); "
            "field_amount alone with fix_blend=0 = exposed-depth vector-add (Fix A).",
            fontsize=12.0, linecount=2),

        box("src-label", "comment", [20.0, 100.0, 300.0, 20.0], "Source", fontsize=12.0),
        bpatcher("src", "vs_sources_main.maxpat", [20.0, 125.0, 296.0, 125.5], 1, 1,
                 ["jit_gl_texture"], varname="src"),

        box("flow-label", "comment", [20.0, 265.0, 300.0, 20.0], "Optical flow (real footage/camera in Source)", fontsize=12.0),
        bpatcher("flow", "f_vf_optical_flow.maxpat", [20.0, 290.0, 154.0, 91.0], 1, 2,
                 ["jit_gl_texture", "jit_gl_texture"], varname="flow"),

        box("oab-label", "comment", [20.0, 400.0, 260.0, 20.0],
            "SCRATCH -- f_weave_oab (field_amount / fix_blend dials)", fontsize=12.0),
        bpatcher("oab", "f_weave_oab.maxpat", [20.0, 425.0, 220.0, 219.0], 2, 1,
                 ["jit_gl_texture"], varname="oab"),
        bpatcher("prev-oab", "vs_preview.maxpat", [20.0, 660.0, 236.0, 249.0], 1, 1,
                 ["jit_gl_texture"], varname="prev_oab"),

        box("ref-label", "comment", [360.0, 400.0, 260.0, 20.0],
            "REFERENCE -- shipped f_weave (unmodified)", fontsize=12.0),
        bpatcher("ref", "f_weave.maxpat", [360.0, 425.0, 220.0, 159.0], 2, 1,
                 ["jit_gl_texture"], varname="ref"),
        bpatcher("prev-ref", "vs_preview.maxpat", [360.0, 600.0, 236.0, 249.0], 1, 1,
                 ["jit_gl_texture"], varname="prev_ref"),
    ]

    lines = [
        {"patchline": {"source": ["src", 0], "destination": ["flow", 0]}},
        {"patchline": {"source": ["flow", 0], "destination": ["oab", 1]}},
        {"patchline": {"source": ["flow", 0], "destination": ["ref", 1]}},
        {"patchline": {"source": ["oab", 0], "destination": ["prev-oab", 0]}},
        {"patchline": {"source": ["ref", 0], "destination": ["prev-ref", 0]}},
    ]

    result = {"patcher": {
        "fileversion": 1,
        "appversion": {"major": 9, "minor": 1, "revision": 4, "architecture": "x64", "modernui": 1},
        "classnamespace": "box",
        "rect": [80.0, 80.0, 640.0, 950.0],
        "gridonopen": 2, "toolbarvisible": 1, "helpsidebarclosed": 1,
        "boxes": boxes, "lines": lines,
        "parameters": {"inherited_shortname": 1},
        "autosave": 0,
    }}

    out_path = Path(__file__).parent / "scratch_weave_orientation_ab.maxpat"
    with open(out_path, "w") as f:
        json.dump(result, f, indent="\t")
    print(f"Written: {out_path}")


if __name__ == "__main__":
    main()
