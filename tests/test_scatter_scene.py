"""
test_scatter_scene.py -- the f_caustic sheets-mode raw layer (src/f_caustic/scatter_scene.py, raw_ui.json) is current
and agrees with a real build of the definition (tasks T014, T024, T025). No Max.

The raw cords name builder-made boxes by id (the soft stage obj-5, the support stages obj-50..52, the scale dial and
the two menus). Those ids are the builder's, not ours, so this test builds the definition and checks each one.

Run:  tests/run.sh tests/test_scatter_scene.py
"""
import json
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "build"))
sys.path.insert(0, str(REPO / "src" / "f_caustic"))
import build_patcher as bp          # noqa: E402
import scatter_scene as sc          # noqa: E402

from harness import check, run      # noqa: E402


def built():
    out = bp.build(bp.load_definition(str(REPO / "src" / "f_caustic" / "definition.py")))["patcher"]
    return {b["box"]["id"]: b["box"] for b in out["boxes"]}, out["lines"]


def test_raw_ui_json_is_current():
    """raw_ui.json is derived: regenerate with `python3 src/f_caustic/scatter_scene.py` after changing the generator."""
    on_disk = json.loads((REPO / "src" / "f_caustic" / "raw_ui.json").read_text())
    check("raw_ui.json differs from the generator's output (1 = stale)", float(on_disk != json.loads(json.dumps(sc.raw_ui()))), 0.0)


def test_the_builder_ids_the_raw_cords_name_are_the_ones_in_the_build():
    boxes, _ = built()
    def pix(i):
        return (boxes[i].get("text") or "").split("@name ")[-1].split()[0] if i in boxes else None
    want = {sc.SOFT: "caustic_pix", sc.SHEETS: "#0_caustic_sheets", sc.SEL_COMP: "#0_caustic_selc", sc.SEL_LAYER: "#0_caustic_sell"}
    wrong = {i: (pix(i), n) for i, n in want.items() if pix(i) != n}
    check("pix stage ids that are not what scatter_scene.py assumes", len(wrong), 0.0)
    for bid, kind, var in ((sc.DIAL_SCALE, "live.dial", "scale"), (sc.MENU_MODE, "live.menu", "mode"), (sc.MENU_DETAIL, "live.menu", "detail")):
        b = boxes.get(bid, {})
        check(f"{bid} is the {kind} '{var}'", float(not (b.get("maxclass") == kind and b.get("varname") == var)), 0.0)


def test_every_raw_cord_has_real_endpoints():
    boxes, lines = built()
    bad = []
    for l in lines:
        (s, so), (t, ti) = l["patchline"]["source"], l["patchline"]["destination"]
        if s not in boxes or t not in boxes or so >= boxes[s].get("numoutlets", 0) or ti >= boxes[t].get("numinlets", 1):
            bad.append((s, so, t, ti))
    check("cords with a missing box or an out-of-range port in the built module", len(bad), 0.0)


def test_every_gl_object_name_is_scoped_per_instance():
    """Two f_caustic instances must not share a node, shader or pix name (`#0` is unique per instance). The one
    exception is the soft stage's `caustic_pix`, a fixed name the module has always had: it is kept so the soft path is
    bit-identical (task T027), and it is the one thing a live two-instance check (T037) has to look at."""
    boxes, _ = built()
    unscoped = []
    for b in boxes.values():
        text = b.get("text") or ""
        if text.startswith("jit.gl.") and "@name " in text and "@name #0" not in text:
            unscoped.append(text.split("@name ")[1].split()[0])
        if text.startswith("jit.gl.mesh") and " #0." not in text:
            unscoped.append("mesh target: " + text.split()[1])
    check("GL objects whose name is not #0-scoped (expected: only caustic_pix)", len([u for u in unscoped if u != "caustic_pix"]), 0.0)
    assert unscoped.count("caustic_pix") == 1, unscoped


if __name__ == "__main__":
    sys.exit(run(globals()))
