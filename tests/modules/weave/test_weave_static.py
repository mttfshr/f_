"""test_weave_static.py -- static guard for the f_weave source-mode render trigger (2026-11-01): what an offline run
CAN verify about the built patcher. With nothing on the inlet, vs_inState does not make the jit.gl.pix draw (the f_quasi
bug, Matt live), so source mode has its own per-frame trigger: `r draw` -> [gate 1 1] -> pix inlet 0. The gate starts
open and vs_inState's connected flag closes it through [== 0], so a connected weave renders once per frame.

  1  `r draw` reaches the pix only through the gate (data inlet 1 -> outlet 0 -> pix inlet 0), never directly
  2  the gate starts open ("gate 1 1") and its control inlet 0 is fed by [== 0], fed by vs_inState outlet 1
  3  the old paths are intact: vs_inState outlet 0 -> pix inlet 0, and its flag still reaches `prepend param src_mode`
  4  the output follows the render size (render_dim, size_stages only): pix `@adapt 0 @dim ...`, `r dim` -> pix,
     loadbang -> `s trig_res`. Unconnected, the pix otherwise adapts to vs_black (1x1; inferred) and draws one pixel.

NOT covered offline: that a bang to an unconnected pix really draws, and the unconnected output size (Matt, live).

Run:  tests/run.sh -q tests/modules/weave/test_weave_static.py   (the built patcher must be current:
      build/py.sh build/build_patcher.py src/f_weave/definition.py)
"""
import json
import os

from harness import check, run  # noqa: E402

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))


def _patcher():
    d = json.load(open(os.path.join(REPO, "package", "patchers", "f_weave.maxpat")))["patcher"]
    boxes = {b["box"]["id"]: b["box"] for b in d["boxes"]}
    lines = [(tuple(l["patchline"]["source"]), tuple(l["patchline"]["destination"])) for l in d["lines"]]
    return boxes, lines


def _ids(boxes, text):
    return [i for i, b in boxes.items() if b.get("text", "") == text]


def _field_instate(boxes, lines):
    """The vs_inState of inlet 0 (the vecfield): the one whose outlet 1 feeds `prepend param src_mode`. weave has a
    second vs_inState on its scalar mod inlet, so the text alone is ambiguous."""
    pre = _ids(boxes, "prepend param src_mode")
    assert len(pre) == 1, pre
    inst = [s[0] for s, d in lines if d[0] == pre[0] and s[1] == 1 and boxes[s[0]].get("text") == "vs_inState"]
    assert len(inst) == 1, inst
    return inst[0]


def _pix(boxes):
    pix = [i for i, b in boxes.items() if b.get("text", "").startswith("jit.gl.pix")]
    assert len(pix) == 1, pix
    return pix[0]


def test_r_draw_reaches_the_pix_only_through_the_gate():
    boxes, lines = _patcher()
    pix, rdraw, gate = _pix(boxes), _ids(boxes, "r draw"), _ids(boxes, "gate 1 1")
    assert len(rdraw) == 1 and len(gate) == 1, (rdraw, gate)
    check("r draw -> gate data inlet 1", 0 if ((rdraw[0], 0), (gate[0], 1)) in lines else 1, 0)
    check("gate outlet 0 -> pix inlet 0", 0 if ((gate[0], 0), (pix, 0)) in lines else 1, 0)
    direct = [1 for s, d in lines if s[0] == rdraw[0] and d[0] == pix]
    check("no direct r draw -> pix cord (it would render twice when connected)", len(direct), 0)


def test_gate_starts_open_and_is_closed_by_the_connected_flag():
    boxes, lines = _patcher()
    gate, eq, inst = _ids(boxes, "gate 1 1"), _ids(boxes, "== 0"), [_field_instate(boxes, lines)]
    assert len(gate) == 1 and len(eq) == 1, (gate, eq)
    check("vs_inState outlet 1 -> [== 0] inlet 0", 0 if ((inst[0], 1), (eq[0], 0)) in lines else 1, 0)
    check("[== 0] -> gate control inlet 0", 0 if ((eq[0], 0), (gate[0], 0)) in lines else 1, 0)


def test_existing_trigger_and_src_mode_paths_intact():
    boxes, lines = _patcher()
    pix, inst = _pix(boxes), _field_instate(boxes, lines)
    pre = _ids(boxes, "prepend param src_mode")
    assert len(pre) == 1, pre
    check("vs_inState outlet 0 -> pix inlet 0", 0 if ((inst, 0), (pix, 0)) in lines else 1, 0)
    check("vs_inState outlet 1 -> prepend param src_mode", 0 if ((inst, 1), (pre[0], 0)) in lines else 1, 0)
    check("prepend param src_mode -> pix inlet 0", 0 if ((pre[0], 0), (pix, 0)) in lines else 1, 0)


def test_output_follows_the_render_size():
    boxes, lines = _patcher()
    pix = _pix(boxes)
    text = boxes[pix]["text"]
    check("pix is @adapt 0 (the size is set, not adapted to vs_black's 1x1)", 0 if "@adapt 0" in text else 1, 0)
    check("pix has an explicit @dim", 0 if "@dim " in text else 1, 0)
    rdim = _ids(boxes, "r dim")
    assert len(rdim) == 1, rdim
    check("r dim -> pix inlet 0", 0 if ((rdim[0], 0), (pix, 0)) in lines else 1, 0)
    trig = _ids(boxes, "s trig_res")
    check("loadbang -> s trig_res (Vsynth re-sends the size)", 0 if trig and any(d[0] == trig[0] for _, d in lines) else 1, 0)


if __name__ == "__main__":
    import sys
    sys.exit(run(globals()))
