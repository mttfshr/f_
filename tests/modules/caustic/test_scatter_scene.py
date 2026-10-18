"""
test_scatter_scene.py -- the f_caustic raw layer (src/f_caustic/scatter_scene.py, raw_ui.json) is current and
agrees with a real build of the definition (tasks T014, T024, T025; updated 2026-10-10 for the soft-mode-removal
rebuild -- the module is now one pix stage, no select stages, no mode/detail menus).

The raw cords name builder-made boxes by id (the composite pix obj-5, the scale dial). Those ids are the
builder's, not ours, so this test builds the definition and checks each one.

Run:  tests/run.sh tests/modules/caustic/test_scatter_scene.py
"""
import paths as _paths
import json
import sys
from pathlib import Path

REPO = _paths.REPO
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
    check(f"{sc.SHEETS} is not the composite pix '#0_caustic_sheets' scatter_scene.py assumes",
          float(pix(sc.SHEETS) != "#0_caustic_sheets"), 0.0)
    b = boxes.get(sc.DIAL_SCALE, {})
    check(f"{sc.DIAL_SCALE} is not the live.dial 'scale' scatter_scene.py taps",
          float(not (b.get("maxclass") == "live.dial" and b.get("varname") == "scale")), 0.0)


def test_the_edge_menu_the_raw_cords_tap_is_the_one_in_the_build():
    """`edge` is a shader uniform driven through the scene's control entry, so the builder's Edge live.menu is
    tapped at its outlet (like the Scale dial). Its id is the builder's, so check it, and that it feeds nothing
    else (pix_wire False: no attrui, no cord to a pix)."""
    boxes, lines = built()
    b = boxes.get(sc.MENU_EDGE, {})
    check(f"{sc.MENU_EDGE} is not the live.menu 'edge' scatter_scene.py taps",
          float(not (b.get("maxclass") == "live.menu" and b.get("varname") == "edge")), 0.0)
    items = b.get("saved_attribute_attributes", {}).get("valueof", {}).get("parameter_enum", [])
    check("the Edge menu items are not off / wrap / mirror / clamp, in that order (the shader reads the index)",
          float(items != ["Off", "Wrap", "Mirror", "Clamp"]), 0.0)
    wired = [l["patchline"]["destination"][0] for l in lines if l["patchline"]["source"][0] == sc.MENU_EDGE]
    check("the Edge menu feeds something other than the one `prepend edge` tap", float(wired != ["obj-949"]), 0.0)


def test_every_raw_cord_has_real_endpoints():
    boxes, lines = built()
    bad = []
    for l in lines:
        (s, so), (t, ti) = l["patchline"]["source"], l["patchline"]["destination"]
        if s not in boxes or t not in boxes or so >= boxes[s].get("numoutlets", 0) or ti >= boxes[t].get("numinlets", 1):
            bad.append((s, so, t, ti))
    check("cords with a missing box or an out-of-range port in the built module", len(bad), 0.0)


def test_every_gl_object_name_is_scoped_per_instance():
    """Two f_caustic instances must not share a node, shader or pix name. Soft mode's `caustic_pix` -- the one
    fixed, unscoped name the module ever had, kept only so that path stayed bit-identical -- is gone with soft
    mode itself, so every GL object is #0-scoped now, no exception."""
    boxes, _ = built()
    unscoped = []
    for b in boxes.values():
        text = b.get("text") or ""
        if text.startswith("jit.gl.") and "@name " in text and "@name #0" not in text:
            unscoped.append(text.split("@name ")[1].split()[0])
        if text.startswith("jit.gl.mesh") and " #0." not in text:
            unscoped.append("mesh target: " + text.split()[1])
    check("GL objects whose name is not #0-scoped", len(unscoped), 0.0)


if __name__ == "__main__":
    sys.exit(run(globals()))
