"""
test_build_static_key.py -- the mod_inlets `static` key (2026-11-14, f_halftone T035; plan ADR-10 "Blue texture load").

A pix inlet fed from a file shipped in package/media/ instead of from an outer inlet.  A static mod_inlets entry:

  - gets NO outer inlet and no vs_inState, but keeps its pix inlet (and its gen `in N`)
  - builds loadbang -> t b b; right: `read <file>, bang` -> jit.matrix <planes> <type> <w> <h> -> jit.gl.texture vsynth;
    left: bang the texture (so it sends its name) after the matrix is in; texture -> pix inlet
  - is loud on misuse: a missing file, a path or spaces in the name, a bad dim / type / planes, any other key beside
    label, or the driving texture made static
  - is default-off: a definition without it builds exactly as before (test_drift covers the shipped modules)

Offline only: whether Max finds the file and the texture reaches the pix is for the bench and a live look.

    tests/run.sh tests/build/test_build_static_key.py
"""
import paths as _paths  # noqa: F401
import copy

import build_patcher as bp          # noqa: E402

from harness import check, run      # noqa: E402

ST = {"file": "f_bluenoise64.jxf", "planes": 1, "type": "float32", "dim": [64, 64]}


def _eq(label, got, want):
    check(label, 0 if got == want else 1, 0)


def raises(fn, needle):
    try:
        fn()
    except ValueError as e:
        return needle in str(e)
    return False


def _defn(static=ST, **over):
    d = {"name": "f_t", "prefix": "t", "object_name": "t_pix", "title": "Test", "signal_type": "texture",
         "archetype": "processor", "pix_type": "char", "presentation_width": 160, "presentation_height": 90,
         "outlets": [{"comment": "composite"}],
         "mod_inlets": [{"label": "a mod", "state_param": "src_a"},
                        {"label": "pattern", "static": copy.deepcopy(static)}],
         "params": [
             {"name": "g", "type": "float", "min": 0.0, "max": 1.0, "default": 0.5, "label": "G", "hint": "g"},
             {"name": "src_a", "type": "internal"}, {"name": "bypass", "type": "bypass"},
         ],
         "codebox": "Param g(0.5);\nParam src_a(0);\nParam bypass(0.0);\nout1 = in1 * g + in3;"}
    d.update(over)
    return d


def _built(d):
    p = bp.build(d)["patcher"]
    top = {b["box"]["id"]: b["box"] for b in p["boxes"]}
    cords = {((l["patchline"]["source"][0], l["patchline"]["source"][1]),
              (l["patchline"]["destination"][0], l["patchline"]["destination"][1])) for l in p["lines"]}
    return top, cords


def test_no_outer_inlet_no_instate_but_a_pix_inlet():
    top, _ = _built(_defn())
    inlets = sorted(i for i, b in top.items() if b["maxclass"] == "inlet")
    _eq("the main inlet plus the one ordinary mod inlet", len(inlets), 2)
    _eq("no inlet object or vs_inState for the static entry", [bp.mod_inlet_obj_id(1) in top, bp.mod_instate_obj_id(1) in top],
        [False, False])
    _eq("the pix has an inlet for every entry (main + two)", top[bp.OBJ_PIX]["numinlets"], 3)
    gen = top[bp.OBJ_PIX]["patcher"]["boxes"]
    _eq("the gen has `in 3` for it", any(b["box"].get("text") == "in 3" for b in gen), True)


def test_the_load_chain():
    top, cords = _built(_defn())
    t = lambda part: top[bp.static_obj_id(1, part)]["text"]
    _eq("loadbang", t("load"), "loadbang")
    _eq("t b b", t("trig"), "t b b")
    _eq("the read message", t("msg"), "read f_bluenoise64.jxf, bang")
    _eq("the matrix's planes, type and dim", t("matrix"), "jit.matrix 1 float32 64 64")
    _eq("the texture in the vsynth context, float32, nearest", t("tex"), "jit.gl.texture vsynth @type float32 @adapt 1 @filter nearest")
    i = lambda part: bp.static_obj_id(1, part)
    for (a, ao), (b, bi), what in (((i("load"), 0), (i("trig"), 0), "loadbang -> t b b"),
                                   ((i("trig"), 1), (i("msg"), 0), "right (first) -> read message"),
                                   ((i("msg"), 0), (i("matrix"), 0), "message -> matrix"),
                                   ((i("matrix"), 0), (i("tex"), 0), "matrix -> texture"),
                                   ((i("trig"), 0), (i("tex"), 0), "left (second) -> bang the texture"),
                                   ((i("tex"), 0), (bp.OBJ_PIX, 2), "texture -> pix inlet 2")):
        _eq(what, ((a, ao), (b, bi)) in cords, True)


def test_the_ordinary_entry_is_unchanged():
    _, cords = _built(_defn())
    _eq("inlet -> vs_inState -> pix inlet 1", (((bp.mod_inlet_obj_id(0), 0), (bp.mod_instate_obj_id(0), 0)) in cords,
                                              ((bp.mod_instate_obj_id(0), 0), (bp.OBJ_PIX, 1)) in cords), (True, True))


def test_defaults():
    top, _ = _built(_defn(static={"file": "f_bluenoise64.jxf", "dim": [8, 4]}))
    _eq("planes 4 and char by default", top[bp.static_obj_id(1, "matrix")]["text"], "jit.matrix 4 char 8 4")


def test_loud_on_misuse():
    cases = [
        (dict(static={**ST, "file": "nope.jxf"}), "is not in package/media/"),
        (dict(static={**ST, "file": "media/f_bluenoise64.jxf"}), "bare file name"),
        (dict(static={**ST, "file": "a b.jxf"}), "bare file name"),
        (dict(static={**ST, "dim": [64]}), "two positive ints"),
        (dict(static={**ST, "dim": [64, 0]}), "two positive ints"),
        (dict(static={**ST, "type": "half"}), "type must be"),
        (dict(static={**ST, "planes": 5}), "planes must be"),
        (dict(static={**ST, "extra": 1}), "must be a dict with file and dim"),
        (dict(static={"file": "f_bluenoise64.jxf"}), "must be a dict with file and dim"),
    ]
    for over, needle in cases:
        _eq(f"loud: {over} -> {needle!r}", raises(lambda: bp.build(_defn(**over)), needle), True)
    d = _defn()
    d["mod_inlets"][1]["state_param"] = "src_a"
    _eq("loud: a static entry with state_param", raises(lambda: bp.build(d), "takes only label and static"), True)
    d = _defn(driving_inlet=True)
    d["mod_inlets"] = [{"label": "drv", "static": dict(ST)}]
    _eq("loud: the driving texture made static", raises(lambda: bp.build(d), "driving texture cannot be static"), True)


if __name__ == "__main__":
    import sys
    sys.exit(run(globals()))
