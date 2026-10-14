"""Build the exportcode trial patcher + genjit for f_vf_split.

Scratch experiment (web_shim_candidates idea trial, 2026-10-12). Nothing here
touches the canonical module -- src/f_vf_split/definition.py is only read.

Creates in this directory:
  split_export.genjit   -- f_vf_split's codebox wrapped as a standalone gen patcher
  split_export.maxpat   -- self-driving patcher: loads the genjit into jit.gl.pix,
                           sends `exportcode webgl` and `exportcode isf`, then
                           closes itself (never quits Max).
"""
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent

sys.path.insert(0, "/Users/matt/Github/f_/tests")
from genjit import make_genjit  # noqa: E402

sys.path.insert(0, "/Users/matt/Github/f_/src/f_vf_split")
import definition  # noqa: E402

code = definition.patcher["codebox"]
n_in, n_out = 3, 4  # match the bench's constant-port convention; codebox uses in1, out1, out2

genjit = make_genjit(code, n_inputs=n_in, n_outputs=n_out,
                     min_inputs=n_in, min_outputs=n_out)
(HERE / "split_export.genjit").write_text(json.dumps(genjit, indent=1))

boxes, lines = [], []
steps = [
    ("loadbang", {"maxclass": "newobj", "text": "loadbang",
                  "numinlets": 1, "numoutlets": 1, "outlettype": ["bang"],
                  "patching_rect": [40.0, 20.0, 50.0, 22.0]}),
    ("delay1", {"maxclass": "newobj", "text": "delay 500",
                "numinlets": 2, "numoutlets": 1, "outlettype": ["bang"],
                "patching_rect": [40.0, 60.0, 60.0, 22.0]}),
    ("pix", {"maxclass": "jit.gl.pix",
             "text": f"jit.gl.pix foo @gen split_export @exportfolder {HERE / '_exports'}",
             "numinlets": 1, "numoutlets": 2, "outlettype": ["jit_matrix", ""],
             "patching_rect": [40.0, 100.0, 400.0, 22.0]}),
    ("send_webgl", {"maxclass": "message", "text": "exportcode webgl",
                    "numinlets": 1, "numoutlets": 1, "outlettype": [""],
                    "patching_rect": [40.0, 140.0, 120.0, 22.0]}),
    ("delay2", {"maxclass": "newobj", "text": "delay 2000",
                "numinlets": 2, "numoutlets": 1, "outlettype": ["bang"],
                "patching_rect": [40.0, 180.0, 60.0, 22.0]}),
    ("send_isf", {"maxclass": "message", "text": "exportcode isf",
                  "numinlets": 1, "numoutlets": 1, "outlettype": [""],
                  "patching_rect": [40.0, 220.0, 120.0, 22.0]}),
    ("delay3", {"maxclass": "newobj", "text": "delay 2000",
                "numinlets": 2, "numoutlets": 1, "outlettype": ["bang"],
                "patching_rect": [40.0, 260.0, 60.0, 22.0]}),
    ("close_msg", {"maxclass": "message", "text": "close",
                   "numinlets": 1, "numoutlets": 1, "outlettype": [""],
                   "patching_rect": [40.0, 300.0, 60.0, 22.0]}),
    ("closer", {"maxclass": "newobj", "text": "thispatcher",
                "numinlets": 1, "numoutlets": 2, "outlettype": ["bang", ""],
                "patching_rect": [40.0, 330.0, 70.0, 22.0]}),
    ("out_print", {"maxclass": "newobj", "text": "print split_export",
                   "numinlets": 1, "numoutlets": 0,
                   "patching_rect": [300.0, 250.0, 60.0, 22.0]}),
]
for sid, spec in steps:
    spec["id"] = sid
    boxes.append({"box": spec})

def wire(src, sport, dst, dport):
    lines.append({"patchline": {"source": [src, sport], "destination": [dst, dport]}})

wire("loadbang", 0, "delay1", 0)
wire("delay1", 0, "pix", 0)          # bang into pix: trigger render/compile of gen
wire("delay1", 0, "send_webgl", 0)
wire("send_webgl", 0, "pix", 0)
wire("delay1", 0, "delay2", 0)
wire("delay2", 0, "send_isf", 0)
wire("send_isf", 0, "pix", 0)
wire("delay2", 0, "delay3", 0)
wire("delay3", 0, "close_msg", 0)
wire("close_msg", 0, "closer", 0)
wire("pix", 1, "out_print", 0)        # right outlet = error messages -> print

patcher = {
    "fileversion": 1,
    "appversion": {"major": 9, "minor": 2, "revision": 0, "architecture": "x64", "modernui": 1},
    "patcher": {"boxes": boxes, "lines": lines, "params": []},
}
(HERE / "split_export.maxpat").write_text(json.dumps(patcher, indent=1))
print("wrote split_export.genjit + split_export.maxpat")