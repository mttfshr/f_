"""
genjit.py -- turn codebox text into a .genjit file (a standalone gen patcher
for jit.gl.pix's `gen` attribute; see .specify/test_bench/plan.md ADR-3).

Structure modelled on Max's shipped examples
(Examples/jitter-examples/gen/pinch.genjit) and on build_patcher.py's
gen_subpatcher: `in 1..n` objects wired to codebox inlets 0..n-1, codebox
outlets wired to `out 1..m`. Params are declared inside the codebox with
`Param name(default);` as usual in f_ -- no separate param objects.

Standalone on purpose: build_patcher.gen_subpatcher carries module-specific
archetype / mod-inlet / `r draw` logic the bench doesn't want.
"""
import json
import re

_IN_RE = re.compile(r"\bin(\d+)\b")
_OUT_RE = re.compile(r"\bout(\d+)\b")


def count_ports(code):
    """(n_inputs, n_outputs) from the highest inN / outN referenced.
    Always at least one of each (in 1 carries the driving texture)."""
    ins = [int(x) for x in _IN_RE.findall(code)]
    outs = [int(x) for x in _OUT_RE.findall(code)]
    return max(ins + [1]), max(outs + [1])


def make_genjit(code, n_inputs=None, n_outputs=None, min_inputs=1, min_outputs=1):
    """min_inputs: create at least this many `in` objects even if the code
    doesn't reference them (unused ones are left unwired). jit.gl.pix's inlet
    count follows the gen patcher's `in` objects, so the bench uses
    min_inputs=3 to keep a constant 3 inlets across jobs (plan ADR-6 rev.)."""
    auto_in, auto_out = count_ports(code)
    n_used = n_inputs or auto_in
    n_in = max(n_used, min_inputs)
    n_out_used = n_outputs or auto_out
    n_out = max(n_out_used, min_outputs)    # constant outlet count (same idea as inputs)
    boxes, lines = [], []
    for i in range(n_in):
        boxes.append({"box": {
            "id": f"in-{i + 1}", "maxclass": "newobj", "text": f"in {i + 1}",
            "numinlets": 0, "numoutlets": 1, "outlettype": [""],
            "patching_rect": [22.0 + 60.0 * i, 20.0, 34.0, 22.0]}})
        if i < n_used:
            lines.append({"patchline": {"source": [f"in-{i + 1}", 0],
                                        "destination": ["codebox", i]}})
    boxes.append({"box": {
        "id": "codebox", "maxclass": "codebox", "code": code,
        "fontface": 0, "fontname": "<Monospaced>", "fontsize": 12.0,
        "numinlets": n_used, "numoutlets": n_out_used, "outlettype": [""] * n_out_used,
        "patching_rect": [22.0, 60.0, 560.0, 400.0]}})
    for k in range(n_out):
        boxes.append({"box": {
            "id": f"out-{k + 1}", "maxclass": "newobj", "text": f"out {k + 1}",
            "numinlets": 1, "numoutlets": 0,
            "patching_rect": [22.0 + 60.0 * k, 480.0, 40.0, 22.0]}})
        if k < n_out_used:
            lines.append({"patchline": {"source": ["codebox", k],
                                        "destination": [f"out-{k + 1}", 0]}})
    return {"patcher": {
        "fileversion": 1,
        "appversion": {"major": 9, "minor": 1, "revision": 4,
                       "architecture": "x64", "modernui": 1},
        "classnamespace": "jit.gen",
        "rect": [100.0, 100.0, 620.0, 540.0],
        "boxes": boxes,
        "lines": lines}}


def write_genjit(path, code, **kw):
    with open(path, "w") as f:
        json.dump(make_genjit(code, **kw), f, indent=2)
