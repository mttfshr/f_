#!/usr/bin/env python3
"""Generate the Phase 0 scratch patchers for .specify/f_modules_menu (T001-T005).

    python3 scratch/menu_phase0/make_probes.py

Writes next to this script (so Max finds the .js files on the patcher's own path):
    menu_sheet_probe.maxpat    jsui mock of the compact sheet: T002 legibility, T003 hover hint, T004 text measure
    menu_palette_probe.maxpat  floating window with insert buttons: T001 (insertion), T005 (float window)
    menu_target_probe.maxpat   an empty patch to receive the inserted button
"""
import json
from pathlib import Path

HERE = Path(__file__).parent
APP = {"major": 9, "minor": 1, "revision": 4, "architecture": "x64", "modernui": 1}


def box(id_, maxclass, rect, **kw):
    b = {"id": id_, "maxclass": maxclass, "patching_rect": list(rect)}
    b.update(kw)
    return {"box": b}


def newobj(id_, text, rect, nin, nout, outtypes, **kw):
    return box(id_, "newobj", rect, text=text, numinlets=nin, numoutlets=nout, outlettype=outtypes, **kw)


def comment(id_, text, rect, **kw):
    return box(id_, "comment", rect, text=text, numinlets=1, numoutlets=0, **kw)


def message(id_, text, rect, **kw):
    return box(id_, "message", rect, text=text, numinlets=2, numoutlets=1, outlettype=[""], **kw)


def line(src, sout, dst, din):
    return {"patchline": {"source": [src, sout], "destination": [dst, din]}}


def patcher(rect, boxes, lines, presentation=0):
    return {"patcher": {"fileversion": 1, "appversion": APP, "classnamespace": "box", "rect": list(rect),
                        "openinpresentation": presentation, "boxes": boxes, "lines": lines}}


def validate(d, name):
    p = d["patcher"]
    ids = [b["box"]["id"] for b in p["boxes"]]
    assert len(ids) == len(set(ids)), name + ": duplicate ids"
    for l in p["lines"]:
        pl = l["patchline"]
        for end in (pl["source"][0], pl["destination"][0]):
            assert end in ids, name + ": dangling " + end


# 1. sheet probe: presentation shows only the jsui at the compact-sheet size
sheet = patcher([60, 80, 230, 378], [
    box("obj-1", "jsui", [20, 140, 230, 378], filename="menu_sheet_test.js", varname="sheet",
        numinlets=1, numoutlets=1, outlettype=[""], presentation=1, presentation_rect=[0, 0, 230, 378]),
    newobj("obj-2", "thispatcher", [260, 140, 70, 22], 1, 2, ["", ""]),
    newobj("obj-3", "loadbang", [20, 100, 60, 22], 1, 1, ["bang"]),
    message("obj-4", "measure", [100, 100, 60, 22]),
    comment("obj-5", "Phase 0 probe (T002, T003, T004). Presentation mode shows the sheet at 230 x 378. "
            "T002: judge legibility at 11 pt / 12 px pitch on your laptop, in the dark. "
            "T003: hover a row for a second: does a tooltip appear? (obj-1 outlet 0 -> thispatcher sets the hint.) "
            "T004: open the Max console; widths are printed on load, 'TOO WIDE' means a short label is needed.",
            [20, 20, 420, 60]),
], [
    line("obj-1", 0, "obj-2", 0),
    line("obj-3", 0, "obj-1", 0),
    line("obj-4", 0, "obj-1", 0),
], presentation=1)

# 2. palette probe: floating window with two insert buttons
palette = patcher([700, 80, 230, 110], [
    newobj("obj-1", "loadbang", [20, 20, 60, 22], 1, 1, ["bang"]),
    message("obj-2", "window flags float, window exec", [20, 50, 200, 22]),
    newobj("obj-3", "thispatcher", [20, 80, 70, 22], 1, 2, ["", ""]),
    message("obj-4", "insert", [20, 120, 60, 22], presentation=1, presentation_rect=[10, 10, 90, 22]),
    message("obj-5", "insert_any", [110, 120, 70, 22], presentation=1, presentation_rect=[110, 10, 100, 22]),
    newobj("obj-6", "js probe_insert.js", [20, 160, 130, 22], 1, 1, [""]),
    comment("obj-7", "Phase 0 probe (T001, T005). Click in menu_target_probe first, then click [insert] here. "
            "Console says which patcher was in front and whether a button was added to it. "
            "T005: this window should float above others on load.",
            [20, 200, 330, 50], presentation=1, presentation_rect=[10, 40, 210, 62]),
], [
    line("obj-1", 0, "obj-2", 0),
    line("obj-2", 0, "obj-3", 0),
    line("obj-4", 0, "obj-6", 0),
    line("obj-5", 0, "obj-6", 0),
], presentation=1)

# 3. target patch
target = patcher([400, 80, 260, 180], [
    comment("obj-1", "Target patch for T001. Click in this window (edit mode), then click [insert] in the "
            "floating palette. A button should appear here, near the top left.", [20, 20, 220, 60]),
], [])

for name, d in (("menu_sheet_probe", sheet), ("menu_palette_probe", palette), ("menu_target_probe", target)):
    validate(d, name)
    path = HERE / (name + ".maxpat")
    path.write_text(json.dumps(d, indent=4, ensure_ascii=False) + "\n")
    json.load(open(path))
    print("wrote", path.name)
