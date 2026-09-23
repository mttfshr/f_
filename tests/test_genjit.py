"""
test_genjit.py -- offline structural checks of generated .genjit files,
against a gen patcher Max itself shipped (pinch.genjit).

Run:  tests/run.sh tests/test_genjit.py
"""
import json
import os
import sys

from genjit import count_ports, make_genjit
from harness import check, run

MAX_EXAMPLE = ("/Applications/Max.app/Contents/Resources/Examples/"
               "jitter-examples/gen/pinch.genjit")
BOX_KEYS = {"id", "maxclass", "numinlets", "numoutlets", "patching_rect"}


def _wiring_errors(patcher):
    """Every patchline must join existing boxes at in-range ports."""
    boxes = {b["box"]["id"]: b["box"] for b in patcher["boxes"]}
    errs = 0
    for line in patcher["lines"]:
        (src, so), (dst, di) = line["patchline"]["source"], line["patchline"]["destination"]
        if src not in boxes or dst not in boxes:
            errs += 1
        elif so >= boxes[src]["numoutlets"] or di >= boxes[dst]["numinlets"]:
            errs += 1
    return errs


def test_structure_matches_shipped_example():
    if not os.path.exists(MAX_EXAMPLE):
        print("    SKIP (Max example not found)")
        return
    ref = json.load(open(MAX_EXAMPLE))
    gen = make_genjit("out1 = in1;")
    check("top level is {'patcher'} like the example",
          0 if set(gen) == set(ref) == {"patcher"} else 1, 0)
    missing = {"fileversion", "appversion", "rect", "boxes", "lines"} - set(gen["patcher"])
    check("patcher has the example's core keys", len(missing), 0)
    ref_box_keys = set.intersection(*(set(b["box"]) for b in ref["patcher"]["boxes"]))
    check("example boxes carry the keys we rely on", len(BOX_KEYS - ref_box_keys), 0)
    check("our boxes carry them too",
          sum(len(BOX_KEYS - set(b["box"])) for b in gen["patcher"]["boxes"]), 0)
    check("example wiring self-consistent (validates the checker)",
          _wiring_errors(ref["patcher"]), 0)


def test_ports_and_wiring():
    code = "a = sample(in1, norm);\nb = sample(in3, norm);\nout1 = a;\nout2 = b;"
    p = make_genjit(code)["patcher"]
    texts = sorted(b["box"].get("text", "") for b in p["boxes"] if b["box"]["maxclass"] == "newobj")
    check("in 1..3 and out 1..2 present",
          0 if texts == ["in 1", "in 2", "in 3", "out 1", "out 2"] else 1, 0)
    cb = next(b["box"] for b in p["boxes"] if b["box"]["maxclass"] == "codebox")
    check("codebox inlets/outlets 3/2",
          0 if (cb["numinlets"], cb["numoutlets"]) == (3, 2) else 1, 0)
    check("code embedded verbatim", 0 if cb["code"] == code else 1, 0)
    check("wiring consistent", _wiring_errors(p), 0)
    check("line count = inputs + outputs", abs(len(p["lines"]) - 5), 0)


def test_port_detection():
    check("identity -> (1,1)", 0 if count_ports("out1 = in1;") == (1, 1) else 1, 0)
    check("no refs -> (1,1)", 0 if count_ports("out1 = vec(1,2,3,4);") == (1, 1) else 1, 0)
    check("'min1'/'bin2' ignored",
          0 if count_ports("min1 = 2; bin2 = 3; out1 = in1;") == (1, 1) else 1, 0)
    check("explicit override wins",
          0 if make_genjit("out1 = in1;", n_inputs=3)["patcher"]["boxes"][2]["box"]["text"] == "in 3" else 1, 0)


def test_min_inputs_keeps_constant_inlets():
    """Bench mode: always 3 `in` objects; only referenced ones wired."""
    p = make_genjit("out1 = in1;", min_inputs=3)["patcher"]
    ins = [b["box"]["text"] for b in p["boxes"] if b["box"].get("text", "").startswith("in ")]
    check("in 1..3 present", 0 if ins == ["in 1", "in 2", "in 3"] else 1, 0)
    cb = next(b["box"] for b in p["boxes"] if b["box"]["maxclass"] == "codebox")
    check("codebox inlets = 1 (only in1 used)", abs(cb["numinlets"] - 1), 0)
    wired = [l["patchline"]["source"][0] for l in p["lines"] if l["patchline"]["destination"][0] == "codebox"]
    check("only in-1 wired to codebox", 0 if wired == ["in-1"] else 1, 0)
    check("wiring consistent", _wiring_errors(p), 0)


if __name__ == "__main__":
    sys.exit(run(globals()))
