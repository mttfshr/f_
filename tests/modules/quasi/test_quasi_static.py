"""test_quasi_static.py -- static guard for the f_quasi render trigger (2026-10-30): what an offline run CAN verify about
the built patcher. Unconnected, vs_inState's vs_black fallback does not make the jit.gl.pix draw (Matt, live), so the
module needs an `r draw` wired straight to the pix, as f_grain and f_masonry have.

  1  an `r draw` box feeds the pix inlet 0 directly (the generator renders with nothing on its inlet)
  2  the clocks still run from `r draw` (zoom_clk and drift_clk reach the pix through their prepends)

Run:  tests/run.sh -q tests/modules/quasi/test_quasi_static.py   (the built patcher must be current:
      build/py.sh build/build_patcher.py src/f_quasi/definition.py)
"""
import json
import os

from harness import check, run  # noqa: E402

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))


def _patcher():
    d = json.load(open(os.path.join(REPO, "package", "patchers", "f_quasi.maxpat")))["patcher"]
    boxes = {b["box"]["id"]: b["box"] for b in d["boxes"]}
    lines = [(l["patchline"]["source"], l["patchline"]["destination"]) for l in d["lines"]]
    return boxes, lines


def test_r_draw_feeds_the_pix_directly():
    boxes, lines = _patcher()
    pix = [i for i, b in boxes.items() if b.get("text", "").startswith("jit.gl.pix")]
    rdraw = [i for i, b in boxes.items() if b.get("text", "") == "r draw"]
    assert len(pix) == 1 and rdraw, (pix, rdraw)
    direct = [1 for s, d in lines if s[0] in rdraw and d[0] == pix[0] and d[1] == 0]
    check("an `r draw` cord reaches the pix inlet 0 directly", 0 if direct else 1, 0)


def test_clocks_still_reach_the_pix():
    boxes, lines = _patcher()
    pix = [i for i, b in boxes.items() if b.get("text", "").startswith("jit.gl.pix")][0]
    fed = {boxes[s[0]].get("text", "") for s, d in lines if d[0] == pix}
    for want in ("prepend param zoom_clk", "prepend param drift_clk"):
        check(f"{want} -> pix", 0 if want in fed else 1, 0)


if __name__ == "__main__":
    import sys
    sys.exit(run(globals()))
