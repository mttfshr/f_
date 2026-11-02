"""
test_build_tag_key.py -- the mod_inlets `tag` key (2026-11-01, f_weave; ideas/named_mod_textures.md).

A modulation texture that arrives on the module's MAIN inlet, tagged with a name
(`<tag> jit_gl_texture <name>`, made upstream with `prepend <tag>`).  A tagged mod_inlets entry:

  - gets NO outer inlet (the module keeps only its real inlets), but still gets its pix inlet, its
    vs_inState and its connected-flag prepend
  - is fed by ONE `route <tags>` (TAG_DEMUX), itself fed by the scalar route's reject outlet
  - sits in the edit view under the route row, so those cords run downward (layout.py)
  - is loud on misuse: a bad or duplicate tag, a tag that is also a route token or `bypass`, a tag on the
    driving texture, or a tag together with route_first / route_reject_to_pix (both use the reject outlet)
  - is default-off: a definition without it builds exactly as before

    tests/run.sh tests/build/test_build_tag_key.py
"""
import paths as _paths
import copy
import sys

ROOT = _paths.REPO
import build_patcher as bp          # noqa: E402

from harness import check, run      # noqa: E402


def _eq(label, got, want):
    check(label, 0 if got == want else 1, 0)


def raises(fn, needle):
    try:
        fn()
    except ValueError as e:
        return needle in str(e)
    return False


def _defn(**over):
    d = {"name": "f_t", "prefix": "t", "object_name": "t_pix", "title": "Test", "signal_type": "texture",
         "archetype": "processor", "pix_type": "char", "presentation_width": 160, "presentation_height": 90,
         "outlets": [{"comment": "composite"}],
         "mod_inlets": [{"label": "a mod", "state_param": "src_a"},
                        {"label": "b tex", "state_param": "src_b", "tag": "b_tex"},
                        {"label": "c tex", "state_param": "src_c", "tag": "c_tex"}],
         "params": [
             {"name": "g", "type": "float", "min": 0.0, "max": 1.0, "default": 0.5, "label": "G", "hint": "g"},
             {"name": "src_a", "type": "internal"}, {"name": "src_b", "type": "internal"},
             {"name": "src_c", "type": "internal"}, {"name": "bypass", "type": "bypass"},
         ],
         "codebox": "Param g(0.5);\nParam src_a(0);\nParam src_b(0);\nParam src_c(0);\nParam bypass(0.0);\nout1 = in1 * g;"}
    d.update(over)
    return d


def _built(d):
    p = bp.build(d)["patcher"]
    top = {b["box"]["id"]: b["box"] for b in p["boxes"]}
    cords = {((l["patchline"]["source"][0], l["patchline"]["source"][1]),
              (l["patchline"]["destination"][0], l["patchline"]["destination"][1])) for l in p["lines"]}
    return top, cords


def _untagged():
    d = _defn()
    for m in d["mod_inlets"]:
        m.pop("tag", None)
    return d


def test_a_tagged_entry_has_no_outer_inlet_but_keeps_its_pix_inlet():
    top, _ = _built(_defn())
    base, _ = _built(_untagged())
    inlets = lambda t: sorted(i for i, b in t.items() if b["maxclass"] == "inlet")
    _eq("untagged: the main inlet plus one per mod inlet", len(inlets(base)), 4)
    _eq("tagged: the main inlet plus the one untagged mod inlet", len(inlets(top)), 2)
    _eq("the tagged entries' inlet objects are not built",
        [bp.mod_inlet_obj_id(1) in top, bp.mod_inlet_obj_id(2) in top], [False, False])
    _eq("the pix still has an inlet for every entry (main + three)", top[bp.OBJ_PIX]["numinlets"], 4)


def test_the_demux_is_fed_by_the_scalar_routes_reject_outlet():
    top, cords = _built(_defn())
    base, _ = _built(_untagged())
    n_names = len(top[bp.OBJ_ROUTE]["text"].split()) - 1
    _eq("the scalar route gained its reject outlet", top[bp.OBJ_ROUTE]["numoutlets"], n_names + 1)
    _eq("an untagged build has none", base[bp.OBJ_ROUTE]["numoutlets"], n_names)
    _eq("the demux is `route <tags>` with one outlet per tag and a reject",
        (top[bp.TAG_DEMUX]["text"], top[bp.TAG_DEMUX]["numoutlets"]), ("route b_tex c_tex", 3))
    _eq("route reject -> demux", ((bp.OBJ_ROUTE, n_names), (bp.TAG_DEMUX, 0)) in cords, True)
    _eq("an untagged build has no demux", bp.TAG_DEMUX in base, False)


def test_each_tag_has_its_own_vs_instate_flag_and_pix_inlet():
    top, cords = _built(_defn())
    for k, i in enumerate((1, 2)):
        inst, pre = bp.mod_instate_obj_id(i), bp.mod_state_pre_id(i)
        _eq(f"demux outlet {k} -> its vs_inState", ((bp.TAG_DEMUX, k), (inst, 0)) in cords, True)
        _eq(f"vs_inState {i} -> pix inlet {i + 1}", ((inst, 0), (bp.OBJ_PIX, i + 1)) in cords, True)
        _eq(f"connected flag {i} -> prepend -> pix", ((inst, 1), (pre, 0)) in cords and ((pre, 0), (bp.OBJ_PIX, 0)) in cords, True)
    _eq("the untagged entry is wired as ever (inlet -> vs_inState -> pix inlet 1)",
        (((bp.mod_inlet_obj_id(0), 0), (bp.mod_instate_obj_id(0), 0)) in cords,
         ((bp.mod_instate_obj_id(0), 0), (bp.OBJ_PIX, 1)) in cords), (True, True))


def test_the_tag_strip_runs_downward_in_the_edit_view():
    top, cords = _built(_defn())
    y = lambda i: top[i]["patching_rect"][1]
    chain = [(bp.OBJ_ROUTE, bp.TAG_DEMUX)]
    for i in (1, 2):
        chain += [(bp.TAG_DEMUX, bp.mod_instate_obj_id(i)), (bp.mod_instate_obj_id(i), bp.mod_state_pre_id(i)),
                  (bp.mod_instate_obj_id(i), bp.OBJ_PIX), (bp.mod_state_pre_id(i), bp.OBJ_PIX)]
    for a, b in chain:
        _eq(f"{a} -> {b} does not run upward", y(b) >= y(a), True)
    x = lambda i: top[i]["patching_rect"][0]
    _eq("the strip is clear of the route's right edge",
        x(bp.TAG_DEMUX) > x(bp.OBJ_ROUTE) + top[bp.OBJ_ROUTE]["patching_rect"][2], True)
    _eq("the two tagged vs_inStates do not overlap",
        abs(x(bp.mod_instate_obj_id(2)) - x(bp.mod_instate_obj_id(1))) >= 80.0, True)


def test_tag_elements_take_overrides():
    d = _defn(overrides={"tag_demux": {"fontsize": 11.0}, "tag_instate.1": {"fontsize": 10.0},
                         "tag_statepre.2": {"fontsize": 10.0}})
    top, _ = _built(d)
    _eq("overrides reach the demux and the tagged boxes",
        (top[bp.TAG_DEMUX].get("fontsize"), top[bp.mod_instate_obj_id(1)].get("fontsize"),
         top[bp.mod_state_pre_id(2)].get("fontsize")), (11.0, 10.0, 10.0))
    _eq("an untagged entry keeps the old element key",
        bool(_built(_defn(overrides={"mod_instate.0": {"fontsize": 9.0}}))[0][bp.mod_instate_obj_id(0)].get("fontsize")), True)


def test_default_off_changes_nothing():
    a = bp.build(_untagged())
    b = bp.build(_defn(mod_inlets=[{"label": "a mod", "state_param": "src_a"},
                                    {"label": "b tex", "state_param": "src_b"},
                                    {"label": "c tex", "state_param": "src_c"}]))
    _eq("a definition with no tag builds identically however it is spelled", a == b, True)


def test_misuse_is_loud():
    def tagged(**over):
        return _defn(**over)

    for bad in ("", "two words", " pad", 3, None):
        d = _defn()
        d["mod_inlets"][1]["tag"] = bad
        _eq(f"tag {bad!r} is loud", raises(lambda: bp.build(d), "must be a single word"), True)
    d = _defn()
    d["mod_inlets"][2]["tag"] = "b_tex"
    _eq("a duplicate tag is loud", raises(lambda: bp.build(d), "must be unique"), True)
    d = _defn()
    d["mod_inlets"][1]["tag"] = "g"
    _eq("a tag that is a param name is loud", raises(lambda: bp.build(d), "also a route token"), True)
    d = _defn()
    d["mod_inlets"][1]["tag"] = "bypass"
    _eq("a tag called bypass is loud", raises(lambda: bp.build(d), "also a route token"), True)
    _eq("route_first is loud with a tag", raises(lambda: bp.build(tagged(route_first=True)), "cannot be combined"), True)
    _eq("route_reject_to_pix is loud with a tag",
        raises(lambda: bp.build(tagged(route_reject_to_pix=True)), "cannot be combined"), True)
    d = _defn(archetype="source", driving_inlet=True)
    d["mod_inlets"][0]["tag"] = "a_tex"
    _eq("a tag on the driving texture is loud", raises(lambda: bp.build(d), "driving texture"), True)


if __name__ == "__main__":
    sys.exit(run(globals()))
