"""
test_build_seeds_keys.py -- the builder keys that let f_vf_seeds be built from its definition
(build_cleanup T019, 2026-10-06).  All default-off and loud; each is exercised on a small synthetic
definition (the helpers of test_build_multistage.py), then on the real module.

  - pix_chain node `gen_code`: the node's codebox as an inline string (instead of a `gen` file)
  - param `pix_shared_attrui`: ONE attrui reaches every stage of a pix_target list
  - param `pix_attr`: the attrui is bound to another attribute than the param's name
  - param `range_menu_outlet`: the live.menu outlet that feeds the range `sel`
  - native `bypass_target`: the toggle's attrui @bypass reaches several stages
  - top-level `outlet_source`: an outlet fed by a named stage's outlet, not the primary's
  - mod_inlets `fanout` / `state_nodes`: a mod inlet's texture and connected-flag reach chosen stages
  - build(): a duplicate box id is loud; support-stage ids move clear of the per-param ids

    tests/run.sh tests/test_build_seeds_keys.py
"""
import copy
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "build"))
import build_patcher as bp          # noqa: E402
from test_build_multistage import (TMP, _eq, by_name, chain_defn, drift, raises,   # noqa: E402
                                   top_and_cords)
from harness import check, run      # noqa: E402


def attrui_ids(top, attr):
    return sorted(i for i, b in top.items() if b.get("maxclass") == "attrui" and b.get("attr") == attr)


# ---- gen_code

def test_gen_code_is_an_inline_codebox_and_is_loud():
    d = chain_defn()
    d["pix_chain"][0].pop("gen")
    d["pix_chain"][0]["gen_code"] = "Param dt(0.1);\nParam tap(8);\nout1 = in1 * 2.0;\n"
    _, _, p = top_and_cords(d)
    code = [b["box"]["code"] for bx in p["boxes"] if "patcher" in bx["box"]
            for b in bx["box"]["patcher"]["boxes"] if "code" in b["box"]]
    _eq("the inline string reaches the node's gen codebox", any("in1 * 2.0" in c for c in code), True)
    both = copy.deepcopy(d)
    both["pix_chain"][0]["gen"] = "b.gen"
    _eq("gen and gen_code together are loud", raises(lambda: bp.build(both), "not both"), True)
    for bad_code in ("", "  \n", None, 3):
        bad = copy.deepcopy(d)
        bad["pix_chain"][0]["gen_code"] = bad_code
        _eq(f"gen_code {bad_code!r} is loud", raises(lambda: bp.build(bad), "gen_code must be a non-empty string"), True)
    # the param-bypass check reads a gen_code node's codebox too
    nopar = chain_defn(bypass_mode="param", bypass_target=["first"])
    nopar["pix_chain"][0].pop("gen")
    nopar["pix_chain"][0]["gen_code"] = "Param dt(0.1);\nout1 = in1;\n"
    _eq("a gen_code target without the Param is loud",
        raises(lambda: bp.build(nopar), "does not declare `Param bypass_gate"), True)
    okpar = copy.deepcopy(nopar)
    okpar["pix_chain"][0]["gen_code"] = "Param dt(0.1);\nParam bypass_gate(0.0);\nout1 = in1;\n"
    _eq("and builds when it declares it", bool(bp.build(okpar)), True)


# ---- pix_shared_attrui

def test_pix_shared_attrui_is_one_attrui_for_every_stage():
    d = chain_defn()
    d["params"][0]["pix_target"] = ["main", "first"]
    top0, _, _ = top_and_cords(d)
    _eq("baseline: a list makes two attruis", len(attrui_ids(top0, "dt")), 2)
    d["params"][0]["pix_shared_attrui"] = True
    top, cords, _ = top_and_cords(d)
    pre, main, first = bp.param_pre_id(0), bp.OBJ_PIX, by_name(top, "#0_t_first")
    _eq("one attrui", attrui_ids(top, "dt"), [pre])
    _eq("it reaches both stages",
        ((pre, 0), (main, 0)) in cords and ((pre, 0), (first, 0)) in cords, True)
    _eq("no obj-700 extra", any(i.startswith("obj-7") and len(i) == 7 for i in top), False)
    _eq("param_connect still names the first stage", top[bp.param_obj_id(0)]["param_connect"], "#0_t_main::dt")
    for label, patch, needle in (
            ("a non-bool", {"pix_shared_attrui": 1}, "must be True or False"),
            ("a single-stage target", {"pix_target": "main"}, "needs a pix_target list"),
            ("a one-element list", {"pix_target": ["main"]}, "two or more"),
            ("ui False", {"ui": False}, "cannot be combined"),
            ("pix_wire False", {"pix_wire": False}, "cannot be combined")):
        bad = copy.deepcopy(d)
        bad["params"][0].update(patch)
        _eq(f"pix_shared_attrui is loud with {label}", raises(lambda: bp.build(bad), needle), True)
    off = copy.deepcopy(d)
    off["params"][0]["pix_shared_attrui"] = False
    _eq("False is the default behaviour (two attruis)", len(attrui_ids(top_and_cords(off)[0], "dt")), 2)


# ---- pix_attr

def test_pix_attr_binds_the_attrui_to_another_attribute():
    d = chain_defn()
    d["params"][0]["pix_attr"] = "other_name"
    top, cords, _ = top_and_cords(d)
    pre = bp.param_pre_id(0)
    _eq("the attrui's attribute is the pix_attr", top[pre]["attr"], "other_name")
    _eq("the widget, its varname and the route token keep the param's name",
        (top[bp.param_obj_id(0)]["varname"], top[bp.OBJ_ROUTE]["text"].split()[1:]), ("dt", ["dt", "tap"]))
    _eq("and the wiring is unchanged",
        ((bp.param_obj_id(0), 0), (pre, 0)) in cords and ((pre, 0), (bp.OBJ_PIX, 0)) in cords, True)
    d["params"][0]["pix_target"] = ["main", "first"]
    top, _, _ = top_and_cords(d)
    _eq("an extra attrui of a list target is bound to it as well", len(attrui_ids(top, "other_name")), 2)
    for label, patch, needle in (("an invalid name", {"pix_attr": "a b"}, "must be an attribute name"),
                                 ("a non-string", {"pix_attr": 3}, "must be an attribute name"),
                                 ("the param's own name", {"pix_attr": "dt"}, "equals the param name"),
                                 ("pix_wire False", {"pix_attr": "x", "pix_wire": False}, "needs an attrui")):
        bad = chain_defn()
        bad["params"][0].update(patch)
        _eq(f"pix_attr is loud with {label}", raises(lambda: bp.build(bad), needle), True)


# ---- range_menu_outlet

def test_range_menu_outlet_picks_the_menu_outlet_that_feeds_sel():
    d = chain_defn()
    d["params"][0]["range_tiers"] = [1.0, 5.0]
    _, cords0, _ = top_and_cords(d)
    menu, sel = bp.range_menu_id(0), bp.range_sel_id(0)
    _eq("default: menu outlet 0 -> sel", ((menu, 0), (sel, 0)) in cords0, True)
    d["params"][0]["range_menu_outlet"] = 2
    _, cords, _ = top_and_cords(d)
    _eq("range_menu_outlet 2: outlet 2 -> sel, and not outlet 0",
        (((menu, 2), (sel, 0)) in cords, ((menu, 0), (sel, 0)) in cords), (True, False))
    for label, val, needle in (("3", 3, "must be 0, 1 or 2"), ("a bool", True, "must be 0, 1 or 2"),
                               ("a string", "2", "must be 0, 1 or 2")):
        bad = copy.deepcopy(d)
        bad["params"][0]["range_menu_outlet"] = val
        _eq(f"range_menu_outlet is loud on {label}", raises(lambda: bp.build(bad), needle), True)
    bad = chain_defn()
    bad["params"][0]["range_menu_outlet"] = 2
    _eq("and without range_tiers", raises(lambda: bp.build(bad), "applies to a param with range_tiers"), True)


# ---- native bypass_target

def test_native_bypass_target_fans_the_attrui_to_every_listed_stage():
    top0, cords0, _ = top_and_cords(chain_defn())
    att0 = attrui_ids(top0, "bypass")[0]
    _eq("default: the primary only",
        (((att0, 0), (bp.OBJ_PIX, 0)) in cords0, ((att0, 0), (by_name(top0, "#0_t_first"), 0)) in cords0),
        (True, False))
    top, cords, _ = top_and_cords(chain_defn(bypass_target=["main", "first"]))
    att = attrui_ids(top, "bypass")
    _eq("still the native attrui @bypass (no prepend)", (len(att), any(b.get("text") == "prepend param bypass_gate" for b in top.values())), (1, False))
    _eq("wired to the primary AND the support stage",
        ((att[0], 0), (bp.OBJ_PIX, 0)) in cords and ((att[0], 0), (by_name(top, "#0_t_first"), 0)) in cords, True)
    only = top_and_cords(chain_defn(bypass_target="first"))
    _eq("a single named stage replaces the primary",
        (((attrui_ids(only[0], "bypass")[0], 0), (by_name(only[0], "#0_t_first"), 0)) in only[1],
         ((attrui_ids(only[0], "bypass")[0], 0), (bp.OBJ_PIX, 0)) in only[1]), (True, False))
    _eq("bypass_param is still loud in native mode",
        raises(lambda: bp.build(chain_defn(bypass_param="x")), 'bypass_mode "param" only'), True)


# ---- outlet_source

def two_outlet(**extra):
    d = chain_defn(outlets=[{"comment": "a"}, {"comment": "b"}])
    d.update(extra)
    return d


def test_outlet_source_feeds_an_outlet_from_a_named_stage():
    top, cords, _ = top_and_cords(two_outlet(outlet_source={1: ["first", 0]}))
    first = by_name(top, "#0_t_first")
    o1 = bp.outlet_obj_id(1)
    _eq("outlet 1 comes from the named stage",
        (((first, 0), (o1, 0)) in cords, ((bp.OBJ_PIX, 1), (o1, 0)) in cords), (True, False))
    _eq("outlet 0 is still the primary's", ((bp.OBJ_PIX, 0), (bp.outlet_obj_id(0), 0)) in cords, True)
    _, cords_d, _ = top_and_cords(two_outlet())
    _eq("default: the primary feeds every outlet", ((bp.OBJ_PIX, 1), (o1, 0)) in cords_d, True)
    for label, patch, needle in (
            ("a missing outlet", {"outlet_source": {5: ["first", 0]}}, "does not exist"),
            ("a non-dict", {"outlet_source": [["first", 0]]}, "must be {outlet_index"),
            ("a bad pair", {"outlet_source": {1: "first"}}, "must be [node, node_outlet]"),
            ("a stage outlet it lacks", {"outlet_source": {1: ["first", 1]}}, "has 1 outlet"),
            ("an unknown node", {"outlet_source": {1: ["nope", 0]}}, "unknown node"),
            ("a clash with outlet_source_override",
             {"outlet_source": {1: ["first", 0]}, "outlet_source_override": {1: "x"}}, "give one")):
        _eq(f"outlet_source is loud with {label}", raises(lambda: bp.build(two_outlet(**patch)), needle), True)


# ---- mod_inlets fanout / state_nodes

def mod_defn(**mi):
    entry = {"label": "v", "state_param": "src_v"}
    entry.update(mi)
    return chain_defn(mod_inlets=[entry])


def test_mod_inlet_fanout_and_state_nodes_choose_the_stages():
    top0, cords0, _ = top_and_cords(mod_defn())
    inst, pre = bp.mod_instate_obj_id(0), bp.mod_state_pre_id(0)
    _eq("default: vs_inState -> the primary's inlet 1, and the prepend -> the primary's inlet 0",
        ((inst, 0), (bp.OBJ_PIX, 1)) in cords0 and ((pre, 0), (bp.OBJ_PIX, 0)) in cords0, True)
    top, cords, _ = top_and_cords(mod_defn(fanout=[["first", 2], ["main", 1]], state_nodes=["first", "main"]))
    first = by_name(top, "#0_t_first")
    _eq("fanout: vs_inState reaches each listed (stage, inlet)",
        ((inst, 0), (first, 2)) in cords and ((inst, 0), (bp.OBJ_PIX, 1)) in cords, True)
    _eq("state_nodes: the prepend reaches each listed stage's inlet 0",
        ((pre, 0), (first, 0)) in cords and ((pre, 0), (bp.OBJ_PIX, 0)) in cords, True)
    top2, cords2, _ = top_and_cords(mod_defn(fanout=[["first", 2]], state_nodes=["first"]))
    _eq("a fanout REPLACES the default feed (the primary gets nothing)",
        (((inst, 0), (bp.OBJ_PIX, 1)) in cords2, ((pre, 0), (bp.OBJ_PIX, 0)) in cords2), (False, False))
    top3, cords3, _ = top_and_cords(mod_defn(state_nodes=[]))
    _eq("state_nodes [] builds the prepend and leaves it unconnected",
        (pre in top3, any(s == (pre, 0) for (s, _d) in cords3)), (True, False))
    _eq("fanout alone keeps the default state target",
        ((pre, 0), (bp.OBJ_PIX, 0)) in top_and_cords(mod_defn(fanout=[["first", 2]]))[1], True)
    plain = chain_defn(mod_inlets=[{"label": "v", "vs_instate": False}])
    _, cp, _ = top_and_cords(plain)
    _eq("without vs_inState the inlet feeds the primary directly, as before",
        ((bp.mod_inlet_obj_id(0), 0), (bp.OBJ_PIX, 1)) in cp, True)
    plain["mod_inlets"][0]["fanout"] = [["first", 2]]
    _, cp2, _ = top_and_cords(plain)
    _eq("and a fanout redirects that direct feed too",
        (((bp.mod_inlet_obj_id(0), 0), (bp.OBJ_PIX, 1)) in cp2,
         ((bp.mod_inlet_obj_id(0), 0), (by_name(top_and_cords(plain)[0], "#0_t_first"), 2)) in cp2), (False, True))
    for label, patch, needle in (
            ("an empty fanout", {"fanout": []}, "non-empty list of [node, inlet]"),
            ("a bad pair", {"fanout": [["first"]]}, "non-empty list of [node, inlet]"),
            ("a negative inlet", {"fanout": [["first", -1]]}, "non-empty list of [node, inlet]"),
            ("an unknown node", {"fanout": [["nope", 0]]}, "unknown node"),
            ("a non-list state_nodes", {"state_nodes": "first"}, "must be a list of node ids"),
            ("a repeated state node", {"state_nodes": ["first", "first"]}, "repeats a node"),
            ("an unknown state node", {"state_nodes": ["nope"]}, "unknown node"),
            ("an unknown key", {"fanout_to": 1}, "unknown key")):
        _eq(f"mod_inlets is loud with {label}", raises(lambda: bp.build(mod_defn(**patch)), needle), True)
    nostate = chain_defn(mod_inlets=[{"label": "v", "state_nodes": ["first"]}])
    _eq("state_nodes without a state_param is loud",
        raises(lambda: bp.build(nostate), "needs a state_param"), True)


# ---- ids

def test_support_stage_ids_move_clear_of_the_param_ids_and_duplicates_are_loud():
    _eq("below ten widgets the base is 50 (every existing module's ids unchanged)",
        [bp.chain_id_base(n) for n in (0, 5, 9)], [50, 50, 50])
    _eq("from ten up it clears the dials, labels and the bypass pair", bp.chain_id_base(13), 61)
    d = chain_defn()
    base = d["params"][:2]
    many = [dict(base[0], name=f"p{k}", label=f"P{k}", hint=f"p{k}") for k in range(14)]
    d["params"] = many + [d["params"][-1]]
    d["pix_chain"][0]["gen"] = "n.gen"
    top, _, _ = top_and_cords(d)
    ids = [i for i, b in top.items() if str(b.get("text", "")).startswith("jit.gl.pix")]
    _eq("14 widgets and a support stage build with unique ids (the support stage is clear of them)",
        (len(top) == len(set(top)), by_name(top, "#0_t_first") == f"obj-{bp.chain_id_base(14)}"), (True, True))
    clash = chain_defn(raw_boxes=[{"box": {"id": bp.OBJ_PIX, "maxclass": "newobj", "text": "x",
                                           "numinlets": 1, "numoutlets": 1, "outlettype": [""],
                                           "patching_rect": [0, 0, 10, 10]}}])
    _eq("a duplicate box id fails the build, naming the id",
        raises(lambda: bp.build(clash), f"duplicate box id {bp.OBJ_PIX}"), True)


# ---- the real module

def test_f_vf_seeds_builds_from_its_definition():
    r = drift.report("f_vf_seeds")
    _eq("f_vf_seeds reproduces exactly from src/f_vf_seeds/definition.py", (r["status"], r["how"]), ("ok", "definition"))


if __name__ == "__main__":
    sys.exit(run(globals()))
