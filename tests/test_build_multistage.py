"""
test_build_multistage.py -- the schema keys that let build_patcher.py express a multi-stage module
(build_cleanup T016/T017, 2026-10-05).  All default-off; each is exercised on a small synthetic
definition, then on the real module that needs it.

  - per pix_chain node `pix_attrs`: the attributes as one verbatim string, replacing @type/@adapt
  - per param `pix_target` as a list: the widget drives the first stage, an extra attrui drives each further one
  - per param `ui: False`: a route token and an attrui, no widget / label / panel slot
  - top-level `inlet_fanout`: the texture inlet reaches several stages through vs_inState
  - top-level `draw_triggers`: `r draw` -> inlet 0 of each listed stage
  - top-level `bypass_mode: "param"` (+ `bypass_param`, `bypass_target`): the toggle drives a codebox
    Param through `prepend param <name>`, never the native @bypass

    tests/run.sh tests/test_build_multistage.py
"""
import copy
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "build"))
import build_patcher as bp          # noqa: E402
import drift                        # noqa: E402

from harness import check, run      # noqa: E402

TMP = Path(tempfile.mkdtemp(prefix="f_multistage_"))
(TMP / "a.gen").write_text("Param dt(0.1);\nParam bypass_gate(0.0);\nout1 = in1 * dt;\n")
(TMP / "b.gen").write_text("Param dt(0.1);\nParam tap(8);\nParam bypass_gate(0.0);\nout1 = in1;\n")
(TMP / "n.gen").write_text("Param dt(0.1);\nout1 = in1;\n")


def _eq(label, got, want):
    check(label, 0 if got == want else 1, 0)


def raises(fn, needle):
    try:
        fn()
    except ValueError as e:
        return needle in str(e)
    return False


def chain_defn(**extra):
    """Two-stage chain: `first` (support) -> `main` (primary, the outlet)."""
    d = {"name": "f_t", "prefix": "t", "title": "Test", "signal_type": "texture",
         "archetype": "processor", "presentation_width": 160, "presentation_height": 90,
         "_def_path": str(TMP / "definition.py"),
         "outlets": [{"comment": "out"}],
         "pix_chain": [
             {"id": "first", "name": "#0_t_first", "gen": "b.gen", "n_inlets": 3, "n_outlets": 1,
              "pix_type": "float32", "adapt": False, "primary": False},
             {"id": "main", "name": "#0_t_main", "gen": "a.gen", "n_inlets": 2, "n_outlets": 1,
              "pix_type": "float32", "adapt": True, "primary": True}],
         "pix_wires": [["first", 0, "main", 1]],
         "params": [
             {"name": "dt", "type": "float", "min": 0.0, "max": 1.0, "default": 0.1, "label": "dt", "hint": "dt"},
             {"name": "tap", "type": "int", "min": 1, "max": 16, "default": 8, "label": "Tap", "hint": "tap",
              "pix_target": "first"},
             {"name": "bypass", "type": "bypass"}]}
    d.update(extra)
    return d


def single_defn(**extra):
    d = {"name": "f_s", "prefix": "s", "object_name": "s_pix", "title": "S", "archetype": "processor",
         "pix_type": "char", "presentation_width": 160, "presentation_height": 90,
         "outlets": [{"comment": "out"}], "bypass_mode": "param",
         "params": [{"name": "g", "type": "float", "min": 0.0, "max": 1.0, "default": 0.5, "label": "G", "hint": "g"},
                    {"name": "bypass", "type": "bypass"}],
         "codebox": "Param g(0.5);\nParam bypass_gate(0.0);\nout1 = mix(in1 * g, in1, bypass_gate);"}
    d.update(extra)
    return d


def top_and_cords(defn):
    p = bp.build(defn)["patcher"]
    top = {b["box"]["id"]: b["box"] for b in p["boxes"]}
    cords = {(tuple(ln["patchline"]["source"]), tuple(ln["patchline"]["destination"])) for ln in p["lines"]}
    return top, cords, p


def by_text(top, text):
    return [i for i, b in top.items() if b.get("text") == text]


def by_name(top, name):
    return [i for i, b in top.items()
            if str(b.get("text", "")).startswith("jit.gl.pix") and f"@name {name}" in b["text"]][0]


# ---- pix_attrs

def test_pix_attrs_replaces_type_and_adapt_and_is_loud():
    d = chain_defn()
    d["pix_chain"][0].pop("pix_type")
    d["pix_chain"][0].pop("adapt")
    d["pix_chain"][0]["pix_attrs"] = "@adapt 0 @dim 256 256 @type float32"
    top, _, _ = top_and_cords(d)
    texts = sorted(b["text"] for b in top.values() if str(b.get("text", "")).startswith("jit.gl.pix"))
    _eq("the node text carries the attributes verbatim, after @name",
        texts, ["jit.gl.pix vsynth @name #0_t_first @adapt 0 @dim 256 256 @type float32",
                "jit.gl.pix vsynth @name #0_t_main @type float32 @adapt 1"])
    for label, node_patch, needle in (("with pix_type", {"pix_type": "char"}, "give one or the other"),
                                      ("with adapt", {"adapt": True}, "give one or the other"),
                                      ("empty", {"pix_attrs": " "}, "non-empty"),
                                      ("setting @name", {"pix_attrs": "@name x"}, "must not set @name")):
        bad = copy.deepcopy(d)
        bad["pix_chain"][0].update(node_patch)
        _eq(f"pix_attrs is loud {label}", raises(lambda: bp.build(bad), needle), True)


# ---- pix_target as a list, ui: False

def test_pix_target_list_adds_an_attrui_per_further_stage():
    d = chain_defn()
    d["params"][0]["pix_target"] = ["main", "first"]
    top, cords, p = top_and_cords(d)
    main, first = bp.OBJ_PIX, by_name(top, "#0_t_first")
    ctl, pre = bp.param_obj_id(0), bp.param_pre_id(0)
    extras = [i for i, b in top.items() if b.get("maxclass") == "attrui" and b.get("attr") == "dt" and i != pre]
    _eq("one extra attrui for the second stage", len(extras), 1)
    _eq("the widget feeds the first stage through its own attrui",
        ((ctl, 0), (pre, 0)) in cords and ((pre, 0), (main, 0)) in cords, True)
    _eq("and the second stage through the extra attrui, fed by the widget",
        ((ctl, 0), (extras[0], 0)) in cords and ((extras[0], 0), (first, 0)) in cords, True)
    _eq("param_connect names the FIRST stage", top[ctl]["param_connect"], "#0_t_main::dt")
    flipped = chain_defn()
    flipped["params"][0]["pix_target"] = ["first", "main"]
    topf, cordsf, _ = top_and_cords(flipped)
    _eq("and a reversed list names the other one first",
        (topf[ctl]["param_connect"], ((pre, 0), (by_name(topf, "#0_t_first"), 0)) in cordsf),
        ("#0_t_first::dt", True))
    s = chain_defn()
    s["params"][0]["pix_target"] = "main"
    top1, _, _ = top_and_cords(s)
    _eq("the single-id form makes no extra attrui",
        [i for i, b in top1.items() if b.get("maxclass") == "attrui" and b.get("attr") == "dt"],
        [bp.param_pre_id(0)])
    for label, tgt, needle in (("an unknown node", ["main", "nope"], "unknown node"),
                               ("a repeat", ["main", "main"], "repeats a node"),
                               ("an empty list", [], "non-empty list")):
        bad = chain_defn()
        bad["params"][0]["pix_target"] = tgt
        _eq(f"a pix_target list is loud on {label}", raises(lambda: bp.build(bad), needle), True)


def test_ui_false_is_a_route_token_and_an_attrui_only():
    d = chain_defn()
    top, cords, p = top_and_cords(d)
    _eq("baseline: tap has a widget and a label",
        (bp.param_obj_id(1) in top, bp.param_label_id(1) in top), (True, True))
    d["params"][1]["ui"] = False
    top, cords, p = top_and_cords(d)
    ctl, lab, pre = bp.param_obj_id(1), bp.param_label_id(1), bp.param_pre_id(1)
    _eq("no widget and no label", (ctl in top, lab in top), (False, False))
    _eq("the attrui exists and carries the param's varname",
        (top[pre]["attr"], top[pre].get("varname")), ("tap", "tap"))
    _eq("the route token is still there", top[bp.OBJ_ROUTE]["text"].split()[1:], ["dt", "tap"])
    _eq("the route outlet feeds the attrui, which feeds its stage",
        ((bp.OBJ_ROUTE, 1), (pre, 0)) in cords and ((pre, 0), (by_name(top, "#0_t_first"), 0)) in cords, True)
    _eq("it is not in the parameters block",
        sorted(k for k in p["parameters"] if k.startswith("obj-")), [bp.param_obj_id(0)])
    d["params"][1]["pix_target"] = ["first", "main"]
    top, cords, _ = top_and_cords(d)
    extra = [i for i, b in top.items() if b.get("attr") == "tap" and i != pre][0]
    _eq("a ui-False param with a list target feeds its extra attrui from the route outlet",
        ((bp.OBJ_ROUTE, 1), (extra, 0)) in cords, True)
    bad = chain_defn()
    bad["params"][1]["ui"] = "no"
    _eq("ui is loud when not a bool", raises(lambda: bp.build(bad), "ui must be True or False"), True)
    bad = chain_defn()
    bad["params"][0].update({"ui": False, "type": "menu", "options": ["a", "b"]})
    _eq("ui False is loud on a menu", raises(lambda: bp.build(bad), "float and int params only"), True)


# ---- inlet_fanout, draw_triggers

def test_inlet_fanout_routes_the_texture_and_the_state_to_every_listed_stage():
    d = chain_defn(inlet_fanout={"texture": [["first", 1], ["main", 1]], "state": ["first", "main"],
                                 "state_param": "src_vec"})
    top, cords, _ = top_and_cords(d)
    first, main = by_name(top, "#0_t_first"), bp.OBJ_PIX
    _eq("the state prepend names the Param", top[bp.OBJ_SRCMODE_PRE]["text"], "prepend param src_vec")
    _eq("routepass -> vs_inState, and no cord straight into the pix",
        (((bp.OBJ_ROUTEPASS, 0), (bp.OBJ_INSTATE, 0)) in cords, ((bp.OBJ_ROUTEPASS, 0), (main, 0)) in cords),
        (True, False))
    _eq("vs_inState out 0 -> each stage's cold inlet",
        ((bp.OBJ_INSTATE, 0), (first, 1)) in cords and ((bp.OBJ_INSTATE, 0), (main, 1)) in cords, True)
    _eq("vs_inState out 1 -> prepend -> inlet 0 of each stage",
        ((bp.OBJ_INSTATE, 1), (bp.OBJ_SRCMODE_PRE, 0)) in cords and ((bp.OBJ_SRCMODE_PRE, 0), (first, 0)) in cords
        and ((bp.OBJ_SRCMODE_PRE, 0), (main, 0)) in cords, True)
    top2, cords2, _ = top_and_cords(chain_defn(inlet_fanout={"texture": [["main", 1]]}))
    _eq("without `state` there is no prepend box and no state cord",
        (bp.OBJ_SRCMODE_PRE in top2, any(c[0] == (bp.OBJ_INSTATE, 1) for c in cords2)), (False, False))
    plain, plain_cords, _ = top_and_cords(chain_defn())
    _eq("without the key a processor has no vs_inState and routepass feeds the primary",
        (bp.OBJ_INSTATE in plain, ((bp.OBJ_ROUTEPASS, 0), (bp.OBJ_PIX, 0)) in plain_cords), (False, True))
    for label, fan, needle in (("an unknown key", {"texture": [["main", 1]], "x": 1}, "inlet_fanout must be"),
                               ("no texture", {"state": ["main"]}, "non-empty list of [node, inlet]"),
                               ("an unknown node", {"texture": [["zz", 1]]}, "unknown node"),
                               ("a bad pair", {"texture": [["main"]]}, "[node, inlet] pairs"),
                               ("a bad Param name",
                                {"texture": [["main", 1]], "state": ["main"], "state_param": "a b"}, "Param name")):
        _eq(f"inlet_fanout is loud on {label}",
            raises(lambda: bp.build(chain_defn(inlet_fanout=fan)), needle), True)


def test_draw_triggers_wire_r_draw_to_inlet_0_of_each_stage():
    plain, _, _ = top_and_cords(chain_defn())
    _eq("no r draw box by default", by_text(plain, "r draw"), [])
    top, cords, _ = top_and_cords(chain_defn(draw_triggers=["first", "main"]))
    _eq("exactly one r draw box", by_text(top, "r draw"), ["obj-20a"])
    _eq("it feeds inlet 0 of both stages",
        (("obj-20a", 0), (by_name(top, "#0_t_first"), 0)) in cords and (("obj-20a", 0), (bp.OBJ_PIX, 0)) in cords,
        True)
    _eq("a single node id is accepted",
        (("obj-20a", 0), (bp.OBJ_PIX, 0)) in top_and_cords(chain_defn(draw_triggers="main"))[1], True)
    # the source archetype already feeds its primary from `r draw`: a trigger on it must not double the cord
    src = chain_defn(archetype="source", draw_triggers=["main"])
    p = bp.build(src)["patcher"]
    rd_to_main = [ln for ln in p["lines"] if ln["patchline"]["source"] == ["obj-20a", 0]
                  and ln["patchline"]["destination"] == [bp.OBJ_PIX, 0]]
    _eq("source archetype + a trigger on the primary: one cord, not two", len(rd_to_main), 1)
    for label, spec, needle in (("an unknown node", ["nope"], "unknown node"), ("an empty list", [], "non-empty list")):
        _eq(f"draw_triggers is loud on {label}",
            raises(lambda: bp.build(chain_defn(draw_triggers=spec)), needle), True)


# ---- bypass_mode "param"

def test_bypass_mode_param_drives_a_codebox_param_not_the_native_attribute():
    native, ncords, _ = top_and_cords(chain_defn())
    natt = [i for i, b in native.items() if b.get("maxclass") == "attrui" and b.get("attr") == "bypass"]
    _eq("default: the native bypass attrui, wired to the primary",
        (len(natt), ((natt[0], 0), (bp.OBJ_PIX, 0)) in ncords), (1, True))
    top, cords, _ = top_and_cords(chain_defn(bypass_mode="param"))
    pre, jsui = bp.bypass_pre_id(2), bp.bypass_jsui_id(2)       # two routed params
    _eq("`prepend param bypass_gate` replaces the attrui",
        (top[pre]["maxclass"], top[pre]["text"]), ("newobj", "prepend param bypass_gate"))
    _eq("no native bypass attrui anywhere", any(b.get("attr") == "bypass" for b in top.values()), False)
    _eq("jsui -> prepend -> the primary pix",
        ((jsui, 0), (pre, 0)) in cords and ((pre, 0), (bp.OBJ_PIX, 0)) in cords, True)
    _eq("and not the support stage", ((pre, 0), (by_name(top, "#0_t_first"), 0)) in cords, False)
    two, c2, _ = top_and_cords(chain_defn(bypass_mode="param", bypass_target=["main", "first"]))
    _eq("bypass_target as a list feeds every listed stage",
        ((pre, 0), (bp.OBJ_PIX, 0)) in c2 and ((pre, 0), (by_name(two, "#0_t_first"), 0)) in c2, True)
    st, sc, _ = top_and_cords(single_defn())
    _eq("a single-pix module works the same way",
        (any(b.get("text") == "prepend param bypass_gate" for b in st.values()),
         any(b.get("attr") == "bypass" for b in st.values())), (True, False))
    renamed = single_defn(bypass_param="passthru")
    renamed["codebox"] = renamed["codebox"].replace("bypass_gate", "passthru")
    _eq("bypass_param renames the Param",
        any(b.get("text") == "prepend param passthru" for b in top_and_cords(renamed)[0].values()), True)


def test_bypass_mode_is_loud():
    def _b(**kw):
        return lambda: bp.build(chain_defn(**kw))
    _eq("an unknown mode", raises(_b(bypass_mode="soft"), 'must be "native" or "param"'), True)
    _eq("bypass_param named bypass",
        raises(_b(bypass_mode="param", bypass_param="bypass"), "other than 'bypass'"), True)
    _eq("bypass_param not a name", raises(_b(bypass_mode="param", bypass_param="a b"), "Param name"), True)
    _eq("bypass_param without param mode", raises(_b(bypass_param="bypass_gate"), 'bypass_mode "param" only'), True)
    _eq("bypass_target without param mode", raises(_b(bypass_target="main"), 'bypass_mode "param" only'), True)
    _eq("an unknown bypass_target", raises(_b(bypass_mode="param", bypass_target="zz"), "unknown node"), True)
    bad = chain_defn(bypass_mode="param")
    bad["pix_chain"][1]["gen"] = "n.gen"          # the primary's codebox has no Param bypass_gate
    _eq("a target whose codebox lacks the Param (the toggle would do nothing)",
        raises(lambda: bp.build(bad), "does not declare `Param bypass_gate"), True)
    _eq("a single-pix module without the Param is loud too",
        raises(lambda: bp.build(single_defn(codebox="out1 = in1;")), "does not declare"), True)


# ---- the real modules

def test_the_new_keys_change_nothing_when_absent():
    for name in ("f_vf_advect", "f_vf_glow", "f_stipple", "f_lens", "f_grain"):
        _eq(f"{name} still reproduces", drift.report(name)["status"], "ok")


def test_f_vf_warp_uses_param_bypass_and_reproduces_exactly():
    _eq("f_vf_warp reproduces", drift.report("f_vf_warp")["status"], "ok")
    built, _ = drift.build_module("f_vf_warp")
    boxes = [b["box"] for b in built["patcher"]["boxes"]]
    _eq("it has the prepend and no native bypass attrui",
        (any(b.get("text") == "prepend param bypass_gate" for b in boxes),
         any(b.get("attr") == "bypass" for b in boxes)), (True, False))


def test_f_vf_fluid_builds_from_its_definition_with_the_old_scripts_invariants():
    """build_fluid.py is gone (T019); its verify() checks live on here."""
    _eq("no per-module build script is left to be preferred over the definition",
        drift.builder_script("f_vf_fluid"), None)
    _eq("f_vf_fluid reproduces from its definition", drift.report("f_vf_fluid")["status"], "ok")
    built, how = drift.build_module("f_vf_fluid")
    _eq("built through the generic path", how, "definition")
    p = built["patcher"]
    boxes = {b["box"]["id"]: b["box"] for b in p["boxes"]}
    cords = {(tuple(ln["patchline"]["source"]), tuple(ln["patchline"]["destination"])) for ln in p["lines"]}
    pix = {b["varname"]: b for b in boxes.values() if str(b.get("text", "")).startswith("jit.gl.pix")}
    _eq("eight pix, all #0-scoped and unique",
        (len(pix), sorted(pix) == sorted(set(pix)), all(n.startswith("#0_") for n in pix)), (8, True, True))
    solver = [n for n in pix if n != "#0_fluid_enc"]
    _eq("seven solver stages are @adapt 0 @dim 256 256 float32",
        all("@adapt 0 @dim 256 256 @type float32" in pix[n]["text"] for n in solver), True)
    _eq("enc follows the render size", pix["#0_fluid_enc"]["text"].endswith("@adapt 1 @type float32"), True)
    _eq("no native bypass attribute anywhere", any(b.get("attr") == "bypass" for b in boxes.values()), False)
    _eq("the bypass toggle drives enc's Param",
        any(b.get("text") == "prepend param bypass_gate" for b in boxes.values()), True)
    _eq("route tokens in definition order, taps last",
        boxes[bp.OBJ_ROUTE]["text"].split()[1:], ["force", "dt", "viscosity", "project", "drag", "gain", "taps"])
    taps_n = 6
    _eq("taps has no widget and no label, only its attrui",
        (bp.param_obj_id(taps_n) in boxes, bp.param_label_id(taps_n) in boxes, bp.param_pre_id(taps_n) in boxes),
        (False, False, True))
    dt_attruis = [i for i, b in boxes.items() if b.get("maxclass") == "attrui" and b.get("attr") == "dt"]
    _eq("dt reaches two stages through two attruis", len(dt_attruis), 2)
    enc, adv = bp.OBJ_PIX, pix["#0_fluid_adv"]["id"]
    _eq("the force inlet reaches adv and enc cold inlets, and r draw triggers both",
        ((bp.OBJ_INSTATE, 0), (adv, 1)) in cords and ((bp.OBJ_INSTATE, 0), (enc, 1)) in cords
        and (("obj-20a", 0), (adv, 0)) in cords and (("obj-20a", 0), (enc, 0)) in cords, True)
    _eq("the feedback edge ix -> pass exists",
        ((pix["#0_fluid_ix"]["id"], 0), (pix["#0_fluid_pass"]["id"], 0)) in cords, True)


# ---- the edit-view layout of the new boxes

def test_fanout_and_extra_attruis_lay_out_without_overlap_or_upward_cords():
    import layout
    d = chain_defn(inlet_fanout={"texture": [["first", 1], ["main", 1]], "state": ["first", "main"],
                                 "state_param": "src_vec"},
                   draw_triggers=["first", "main"])
    d["params"][0]["pix_target"] = ["main", "first"]
    dbg = {}
    p = bp.build(d, debug=dbg)["patcher"]
    roles = dbg["roles"]
    a = layout.audit(p["boxes"], p["lines"], roles)
    _eq("no overlaps, shared origins or upward cords", (a["overlaps"], a["same_origin"], a["upward"]), ([], [], []))
    boxes = {b["box"]["id"]: b["box"] for b in p["boxes"]}
    _eq("r draw sits beside vs_inState, not on it",
        boxes["obj-20a"]["patching_rect"][:2] != boxes[bp.OBJ_INSTATE]["patching_rect"][:2], True)
    extra = [i for i, r in roles.items() if r[0] == "pre_extra"]
    pre = boxes[bp.param_pre_id(0)]["patching_rect"]
    ex = boxes[extra[0]]["patching_rect"]
    _eq("the extra attrui is in its param's column, below the first attrui",
        (len(extra), abs((ex[0] + ex[2] / 2) - (pre[0] + pre[2] / 2)) < 1.0, ex[1] > pre[1]), (1, True, True))
    keys = bp.element_keys(roles, [q for q in d["params"] if q["type"] in ("float", "int")], [])
    _eq("the extra attrui has a stable override key", "dt.pre_extra.0" in keys, True)


if __name__ == "__main__":
    sys.exit(run(globals()))
