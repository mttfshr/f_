"""
test_capture_raw.py -- build/capture_raw.py (the raw_boxes / raw_lines / raw_parameters tool), and
the two builder keys that came with it: `"label": None` (no label box) and `pix_context`.

Offline: a small synthetic definition in a temp dir, plus f_grain, whose committed raw_ui.json must
be exactly what the tool derives from the shipped patcher.

    tests/run.sh tests/test_capture_raw.py
"""
import copy
import json
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "build"))
import build_patcher as bp          # noqa: E402
import capture_raw                  # noqa: E402
import drift                        # noqa: E402

from harness import check, run      # noqa: E402


def _eq(label, got, want):
    check(label, 0 if got == want else 1, 0)


DEF_SOURCE = '''import json
from pathlib import Path
_HERE = Path(__file__).parent
_RAW = json.loads((_HERE / "raw_ui.json").read_text()) if (_HERE / "raw_ui.json").exists() else {}
patcher = {
    "name": "f_t", "prefix": "t", "object_name": "t_pix", "title": "Test", "signal_type": "texture",
    "archetype": "processor", "pix_type": "char", "presentation_width": 120, "presentation_height": 90,
    "outlets": [{"comment": "texture"}],
    "params": [
        {"name": "a", "type": "float", "min": 0.0, "max": 1.0, "default": 0.5, "label": "A", "hint": "a"},
        {"name": "b", "type": "float", "min": 0.0, "max": 2.0, "default": 1.0, "label": "B", "hint": "b"},
        {"name": "bypass", "type": "bypass"},
    ],
    "codebox": "Param a(0.5);\\nParam b(1.0);\\nParam bypass(0.0);\\nout1 = in1 * a * b;",
    "raw_boxes": _RAW.get("raw_boxes", []), "raw_lines": _RAW.get("raw_lines", []),
    "raw_parameters": _RAW.get("raw_parameters", {}),
}
'''

# the hand-made extras of the synthetic "shipped" patcher: ids are the shipped ones, not the raw ones
EXTRA_BOXES = [
    {"box": {"id": "obj-77", "maxclass": "newobj", "text": "expr pow(1.0 - $f1\\, 2.0)", "numinlets": 1,
             "numoutlets": 1, "outlettype": [""], "patching_rect": [10.0, 10.0, 90.0, 22.0]}},
    {"box": {"id": "obj-78", "maxclass": "newobj", "text": "r draw", "numinlets": 0, "numoutlets": 1,
             "outlettype": [""], "patching_rect": [10.0, 40.0, 40.0, 22.0]}},
    {"box": {"id": "obj-79", "maxclass": "newobj", "text": "r draw", "numinlets": 0, "numoutlets": 1,
             "outlettype": [""], "patching_rect": [60.0, 40.0, 40.0, 22.0]}},
    {"box": {"id": "obj-80", "maxclass": "live.numbox", "varname": "extra", "numinlets": 1, "numoutlets": 2,
             "outlettype": ["", "float"], "patching_rect": [10.0, 70.0, 44.0, 15.0],
             "presentation": 1, "presentation_rect": [4.0, 70.0, 34.0, 15.0]}},
]


def _scene(tmp):
    dp = Path(tmp) / "definition.py"
    dp.write_text(DEF_SOURCE)
    built = json.loads(json.dumps(bp.build(bp.load_definition(dp))))
    dial_a = [b["box"]["id"] for b in built["patcher"]["boxes"] if b["box"].get("varname") == "a"
              and b["box"]["maxclass"] == "live.dial"][0]
    shipped = copy.deepcopy(built)
    sp_ = shipped["patcher"]
    sp_["boxes"] += copy.deepcopy(EXTRA_BOXES)
    sp_["lines"] += [
        {"patchline": {"source": [dial_a, 0], "destination": ["obj-77", 0]}},      # generic -> raw
        {"patchline": {"source": ["obj-78", 0], "destination": [bp.OBJ_PIX, 0]}},   # raw -> generic
        {"patchline": {"source": ["obj-79", 0], "destination": ["obj-77", 0]}},     # raw -> raw
        {"patchline": {"source": ["obj-80", 0], "destination": [bp.OBJ_PIX, 0]}},
    ]
    sp_["parameters"]["obj-80"] = ["extra", "extra", 0]
    sp = Path(tmp) / "shipped.maxpat"
    sp.write_text(json.dumps(shipped))
    return dp, sp, dial_a


def test_only_the_boxes_the_builder_does_not_make_become_raw_boxes():
    with tempfile.TemporaryDirectory() as tmp:
        dp, sp, _ = _scene(tmp)
        c = capture_raw.plan(dp, sp)
        ids = [b["box"]["id"] for b in c["raw_boxes"]]
        _eq("the four hand-made boxes, ids obj-901.. in shipped order", ids, ["obj-901", "obj-902", "obj-903", "obj-904"])
        _eq("what they are (the two identical `r draw` are both raw)",
            [b["box"].get("text") or b["box"].get("varname") for b in c["raw_boxes"]],
            ["expr pow(1.0 - $f1\\, 2.0)", "r draw", "r draw", "extra"])
        for new, old in zip(c["raw_boxes"], EXTRA_BOXES):
            n, o = dict(new["box"]), dict(old["box"])
            n.pop("id"), o.pop("id")
            _eq(f"{new['box']['id']} is copied verbatim apart from its id", n, o)


def test_cords_with_a_raw_end_are_translated_and_the_rest_are_not_captured():
    with tempfile.TemporaryDirectory() as tmp:
        dp, sp, dial_a = _scene(tmp)
        c = capture_raw.plan(dp, sp)
        got = sorted((tuple(ln["patchline"]["source"]), tuple(ln["patchline"]["destination"])) for ln in c["raw_lines"])
        want = sorted([((dial_a, 0), ("obj-901", 0)), (("obj-902", 0), (bp.OBJ_PIX, 0)),
                       (("obj-903", 0), ("obj-901", 0)), (("obj-904", 0), (bp.OBJ_PIX, 0))])
        _eq("the generic end is the BUILT id, the raw end the new id; nothing else", got, want)
        _eq("shipped `parameters` entries of raw boxes move to the new id", c["raw_parameters"],
            {"obj-904": ["extra", "extra", 0]})


def test_the_captured_definition_reproduces_the_shipped_patcher_and_a_rerun_changes_nothing():
    with tempfile.TemporaryDirectory() as tmp:
        dp, sp, _ = _scene(tmp)
        before, _c = drift.compare(bp.build(bp.load_definition(dp))["patcher"], json.load(open(sp))["patcher"]), None
        _eq("before capture the hand-made boxes are drift", bool(before[0]["boxes_patch_only"]), True)
        _eq("main writes the file", capture_raw.main([str(dp), f"--shipped={sp}"]), 0)
        out = dp.parent / "raw_ui.json"
        first = out.read_text()
        counts, _ex = drift.compare(bp.build(bp.load_definition(dp))["patcher"], json.load(open(sp))["patcher"])
        _eq("after capture, rebuilding from the definition reproduces the patcher exactly",
            {k: v for k, v in counts.items() if v}, {})
        capture_raw.main([str(dp), f"--shipped={sp}"])
        _eq("a second run is byte-identical (the build ignores the existing raw_* keys)", out.read_text(), first)
        out.unlink()
        capture_raw.main([str(dp), f"--shipped={sp}", "--dry-run"])
        _eq("--dry-run writes nothing (the file stays absent)", out.exists(), False)


def test_generic_boxes_with_the_same_identity_on_both_sides_are_paired_not_made_raw():
    # two controls with the same label text: two `comment:X` boxes that exist in the build and in
    # the shipped patcher, with a non-unique identity.  They must pair in order, not become raw.
    with tempfile.TemporaryDirectory() as tmp:
        src = DEF_SOURCE.replace('"label": "A"', '"label": "X"').replace('"label": "B"', '"label": "X"')
        dp = Path(tmp) / "definition.py"
        dp.write_text(src)
        built = json.loads(json.dumps(bp.build(bp.load_definition(dp))))
        shipped = copy.deepcopy(built)
        shipped["patcher"]["boxes"] += copy.deepcopy(EXTRA_BOXES[:1])          # one hand-made box
        sp = Path(tmp) / "shipped.maxpat"
        sp.write_text(json.dumps(shipped))
        xs = [b for b in built["patcher"]["boxes"] if b["box"].get("text") == "X"]
        _eq("the scene really has two identical generic labels", len(xs), 2)
        c = capture_raw.plan(dp, sp)
        _eq("only the hand-made box is raw (the two labels are not)",
            [b["box"].get("text") for b in c["raw_boxes"]], ["expr pow(1.0 - $f1\\, 2.0)"])
        dp.parent.joinpath("raw_ui.json").write_text(capture_raw.render(c))
        counts, _ex = drift.compare(bp.build(bp.load_definition(dp))["patcher"], json.load(open(sp))["patcher"])
        _eq("and the rebuilt definition then reproduces the patcher", {k: v for k, v in counts.items() if v}, {})


def test_raw_ids_must_not_collide_with_generated_ids():
    with tempfile.TemporaryDirectory() as tmp:
        dp, sp, _ = _scene(tmp)
        old = capture_raw.RAW_ID_BASE
        try:
            capture_raw.RAW_ID_BASE = 1          # obj-1.. are the builder's own ids
            try:
                capture_raw.plan(dp, sp)
            except ValueError as e:
                check("a colliding raw id range is refused", 0 if "collide" in str(e) else 1, 0)
            else:
                check("a colliding raw id range (nothing was raised)", 1, 0)
        finally:
            capture_raw.RAW_ID_BASE = old


def test_f_grain_raw_ui_json_is_what_the_tool_derives_from_the_shipped_patcher():
    c = capture_raw.plan(ROOT / "src" / "f_grain" / "definition.py")
    _eq("the committed raw_ui.json is in sync with the shipped patch",
        capture_raw.render(c), (ROOT / "src" / "f_grain" / "raw_ui.json").read_text())


# ---- the builder keys that came with it

def _defn(**extra):
    d = {"name": "f_t", "prefix": "t", "object_name": "t_pix", "title": "Test", "archetype": "processor",
         "pix_type": "char", "presentation_width": 120, "presentation_height": 90,
         "params": [{"name": "a", "type": "float", "min": 0.0, "max": 1.0, "default": 0.5, "label": "A", "hint": "a"},
                    {"name": "b", "type": "float", "min": 0.0, "max": 1.0, "default": 0.5, "label": "B", "hint": "b"},
                    {"name": "bypass", "type": "bypass"}],
         "codebox": "Param a(0.5);\nParam b(0.5);\nParam bypass(0.0);\nout1 = in1 * a * b;"}
    d.update(extra)
    return d


def test_label_none_skips_the_label_box_and_nothing_else():
    def labels(d):
        return sorted(b["box"]["text"] for b in bp.build(d)["patcher"]["boxes"]
                      if b["box"]["maxclass"] == "comment" and b["box"].get("varname", "").startswith("lbl_"))
    _eq("default: both labels", labels(_defn()), ["A", "B"])
    d = _defn()
    d["params"][0]["label"] = None
    _eq("label None: that label only is gone", labels(d), ["B"])
    base = {b["box"]["id"] for b in bp.build(_defn())["patcher"]["boxes"]}
    new = {b["box"]["id"] for b in bp.build(d)["patcher"]["boxes"]}
    _eq("the only box that disappears is the label", sorted(base - new), [bp.param_label_id(0)])
    d2 = _defn()
    del d2["params"][0]["label"]
    _eq("a param with no label key still gets its default label (its name, title-cased)",
        labels(d2), ["A", "B"])


def test_pix_context_picks_the_object_text_form():
    def text(d):
        return [b["box"]["text"] for b in bp.build(d)["patcher"]["boxes"]
                if str(b["box"].get("text", "")).startswith("jit.gl.pix")][0]
    _eq("default", text(_defn()), "jit.gl.pix vsynth @name t_pix @type char")
    _eq("arg is the default", text(_defn(pix_context="arg")), "jit.gl.pix vsynth @name t_pix @type char")
    _eq("drawto", text(_defn(pix_context="drawto")), "jit.gl.pix @name t_pix @drawto vsynth @type char")
    _eq("drawto with adapt", text(_defn(pix_context="drawto", pix_adapt=True)),
        "jit.gl.pix @name t_pix @drawto vsynth @type char @adapt 1")
    try:
        bp.build(_defn(pix_context="context"))
    except ValueError as e:
        check("an unknown pix_context", 0 if "pix_context" in str(e) else 1, 0)
    else:
        check("an unknown pix_context (nothing was raised)", 1, 0)
    adv = copy.deepcopy(bp.load_definition(ROOT / "src" / "f_vf_advect" / "definition.py"))
    adv["pix_context"] = "drawto"
    texts = sorted(b["box"]["text"] for b in bp.build(adv)["patcher"]["boxes"]
                   if str(b["box"].get("text", "")).startswith("jit.gl.pix"))
    _eq("a pix_chain follows it too",
        texts, ["jit.gl.pix @name #0_advect_pass @drawto vsynth @type float32 @adapt 1",
                "jit.gl.pix @name #0_advect_pix @drawto vsynth @type float32 @adapt 1"])


if __name__ == "__main__":
    sys.exit(run(globals()))
