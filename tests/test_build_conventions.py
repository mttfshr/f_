"""
test_build_conventions.py -- the builder writes what Max writes (build_cleanup/T008 round-trip,
Matt 2026-10-05), so a patcher opened and saved in Max changes nothing:

  - a float-type numbox is written with parameter_unitstyle 1 (Float); Max rewrites 0 to 1
  - every inlet/outlet is written with index 0; Max rewrites every index to 0 and orders the
    ports by patching_rect x, so the x order must BE the port order (check_port_order)

  - `render_trigger` (source archetype): "rdraw" (default) adds an `r draw` render trigger,
    "inlet" omits it, as the finished f_vf_vortex / f_vf_vortex_multi ship (T013)

  - per-param `modmode` (default 3, relative modulation; `0` for f_droste's n_arms): dials and numboxes,
    loud outside 0-4 (T014)
  - per-param `route_name` (the message a control answers to, when not its name: f_vf_advect's `mix`),
    `"hint": None` (no hint key, for hand-made controls), and `param_connect` naming the pix a control
    actually drives (`pix_target`): T014
  - `route_first` (inlet -> route, route reject -> routepass), per-param `pix_wire: False` (a control with
    no attrui and no pix cord), `inlet_comment`, and an outlet `hint`: f_grain's shape (T014)
  - `legacy` (pix_varname, autopattr_varname, bypass_jsui_saved, control_valueof), `route_reject_to_pix`,
    per-param `color_expression`: the oldest modules' re-created-object state, T014 (f_channel_grader)
  - `"color_expression": None` (no activedialcolor entry) and `legacy.control_box` (top-level box
    properties of a control): f_hue_processor / f_luma_processor / f_tone_curve, T014
  - range-tier `_parameter_range` messages written the way Max writes floats ("1." not "1.0"), and
    `legacy.element_box` / `legacy.element_valueof` (any element by its override key): f_lens, T014
  - `route_bypass`: `bypass` is the first `route` token, wired to the bypass jsui, and every param
    outlet is one higher; off (the default) changes nothing (T014)

    tests/run.sh tests/test_build_conventions.py
"""
import copy
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "build"))
import build_patcher as bp          # noqa: E402
import drift                        # noqa: E402

from harness import check, run      # noqa: E402


def _eq(label, got, want):
    check(label, 0 if got == want else 1, 0)


def _defn():
    return {"name": "f_t", "prefix": "t", "object_name": "t_pix", "title": "Test", "signal_type": "texture",
            "archetype": "processor", "pix_type": "char", "presentation_width": 160, "presentation_height": 90,
            "outlets": [{"comment": "composite"}, {"comment": "aux"}, {"comment": "third"}],
            "mod_inlets": [{"label": "a mod", "state_param": "src_a"}, {"label": "b mod", "state_param": "src_b"}],
            "params": [
                {"name": "g", "type": "float", "min": 0.0, "max": 1.0, "default": 0.5, "label": "G", "hint": "g"},
                {"name": "mix_pct", "type": "float", "min": 0.0, "max": 100.0, "default": 0.0, "label": "Mix",
                 "widget": "numbox", "hint": "m"},
                {"name": "n", "type": "int", "min": 0, "max": 8, "default": 1, "label": "N", "hint": "n"},
                {"name": "src_a", "type": "internal"}, {"name": "src_b", "type": "internal"},
                {"name": "bypass", "type": "bypass"},
            ],
            "codebox": "Param g(0.5);\nParam mix_pct(0.0);\nParam n(1);\nParam src_a(0);\nParam src_b(0);\n"
                       "Param bypass(0.0);\nout1 = in1 * g;"}


def _boxes():
    return [b["box"] for b in bp.build(_defn())["patcher"]["boxes"]]


def test_numbox_is_written_as_max_writes_it():
    nums = [b for b in _boxes() if b.get("maxclass") == "live.numbox"]
    _eq("the definition makes two numboxes (a float one and an int one)", len(nums), 2)
    for b in nums:
        v = b["saved_attribute_attributes"]["valueof"]
        if v["parameter_longname"] == "mix_pct":
            _eq("a float-type numbox is parameter_type 0 / unitstyle 1 (Float)",
                (v["parameter_type"], v["parameter_unitstyle"]), (0, 1))
    dials = [b for b in _boxes() if b.get("maxclass") == "live.dial"]
    _eq("a dial is unitstyle 1 too (unchanged)",
        {b["saved_attribute_attributes"]["valueof"]["parameter_unitstyle"] for b in dials}, {1})


def test_every_port_is_index_zero_and_in_x_order():
    boxes = _boxes()
    for mc, n in (("inlet", 3), ("outlet", 3)):
        ports = [b for b in boxes if b.get("maxclass") == mc]
        _eq(f"{n} {mc}s", len(ports), n)
        _eq(f"every {mc} is written with index 0 (Max rewrites it to 0)",
            {b["index"] for b in ports}, {0})
        xs = [b["patching_rect"][0] for b in ports]
        _eq(f"the {mc}s are in strictly increasing x order, so Max keeps the port order",
            xs == sorted(xs) and len(set(xs)) == len(xs), True)
        _eq(f"...and the {mc}s are labelled in the intended order",
            [b["comment"] for b in ports],
            ["texture / control", "a mod", "b mod"] if mc == "inlet" else ["composite", "aux", "third"])


def _port(bid, mc, x):
    return {"box": {"id": bid, "maxclass": mc, "patching_rect": [x, 10.0, 30.0, 30.0]}}


def test_check_port_order():
    bp.check_port_order([_port("a", "inlet", 10.0), _port("b", "inlet", 50.0), _port("c", "outlet", 5.0)])
    check("increasing x passes", 0, 0)
    for label, boxes in (("inlets out of x order", [_port("a", "inlet", 50.0), _port("b", "inlet", 10.0)]),
                         ("outlets out of x order", [_port("a", "outlet", 90.0), _port("b", "outlet", 20.0)]),
                         ("two inlets at the same x", [_port("a", "inlet", 30.0), _port("b", "inlet", 30.0)])):
        try:
            bp.check_port_order(boxes)
        except ValueError as e:
            check(label + " is refused", 0 if "x" in str(e) else 1, 0)
        else:
            check(label + " (nothing was raised)", 1, 0)
    bp.check_port_order([_port("a", "inlet", 50.0), {"box": {"id": "t", "maxclass": "comment",
                                                               "patching_rect": [1.0, 1.0, 1.0, 1.0]}}])
    check("a non-port box at a smaller x is ignored", 0, 0)


def test_build_runs_the_port_order_check():
    calls = []
    real = bp.check_port_order
    bp.check_port_order = lambda boxes: (calls.append(len(boxes)), real(boxes))[1]
    try:
        bp.build(_defn())
    finally:
        bp.check_port_order = real
    _eq("build() calls check_port_order exactly once, on the finished box list", len(calls), 1)
    _eq("...with the whole patcher's boxes", calls[0] > 20, True)


# ---- render_trigger

def _source(**extra):
    d = {"name": "f_s", "prefix": "s", "object_name": "s_pix", "title": "Src", "signal_type": "vecfield out",
         "archetype": "source", "pix_type": "float32", "presentation_width": 160, "presentation_height": 90,
         "outlets": [{"comment": "vecfield"}],
         "mod_inlets": [{"label": "a mod", "state_param": "src_a"}],
         "params": [{"name": "g", "type": "float", "min": 0.0, "max": 1.0, "default": 0.5, "label": "G", "hint": "g"},
                    {"name": "src_a", "type": "internal"}, {"name": "bypass", "type": "bypass"}],
         "codebox": "Param g(0.5);\nParam src_a(0);\nParam bypass(0.0);\nout1 = vec(g, g, 0.5, 1.0);"}
    d.update(extra)
    return d


def _rdraw_facts(defn):
    p = bp.build(defn)["patcher"]
    top = [b["box"] for b in p["boxes"]]
    pix = [b for b in top if str(b.get("text", "")).startswith("jit.gl.pix")][0]
    rdraw = [b for b in top if b.get("text") == "r draw"]
    to_pix = [(ln["patchline"]["source"][0], ln["patchline"]["source"][1]) for ln in p["lines"]
              if ln["patchline"]["destination"] == [pix["id"], 0]]
    inner = [x["box"] for x in pix["patcher"]["boxes"]]
    inner_lines = sorted((tuple(ln["patchline"]["source"]), tuple(ln["patchline"]["destination"]))
                         for ln in pix["patcher"]["lines"])
    return {"top_rdraw": len(rdraw), "from_rdraw": sum(1 for src, _ in to_pix if rdraw and src == rdraw[0]["id"]),
            "from_routepass": sum(1 for src, _ in to_pix if src == bp.OBJ_ROUTEPASS),
            "inner_rdraw": sum(1 for b in inner if b.get("text") == "r draw"), "inner_lines": inner_lines}


def test_render_trigger_default_adds_r_draw():
    f = _rdraw_facts(_source())
    _eq("default: a top-level `r draw` box", f["top_rdraw"], 1)
    _eq("default: wired to the pix", f["from_rdraw"], 1)
    _eq("default: routepass drives the pix too", f["from_routepass"], 1)
    _eq("default: an `r draw` inside the gen patcher", f["inner_rdraw"], 1)
    _eq("an explicit \"rdraw\" is the default", _rdraw_facts(_source(render_trigger="rdraw")), f)


def test_render_trigger_inlet_omits_r_draw_everywhere_and_nothing_else():
    dflt, inl = _rdraw_facts(_source()), _rdraw_facts(_source(render_trigger="inlet"))
    _eq("inlet: no top-level `r draw` box", inl["top_rdraw"], 0)
    _eq("inlet: no cord from it", inl["from_rdraw"], 0)
    _eq("inlet: routepass still drives the pix", inl["from_routepass"], 1)
    _eq("inlet: no `r draw` inside the gen patcher", inl["inner_rdraw"], 0)
    _eq("inlet: the gen patcher's cords are unchanged (the inner r draw was free-standing)",
        inl["inner_lines"], dflt["inner_lines"])
    base = bp.build(_source())["patcher"]["boxes"]
    new = bp.build(_source(render_trigger="inlet"))["patcher"]["boxes"]
    top_diff = [b["box"].get("text") for b in base if b["box"]["id"] not in {x["box"]["id"] for x in new}]
    _eq("exactly one top-level box differs: the `r draw`", top_diff, ["r draw"])


def test_render_trigger_is_loud():
    def raises(label, defn, fragment):
        try:
            bp.build(defn)
        except ValueError as e:
            check(label, 0 if fragment in str(e) else 1, 0)
        else:
            check(label + " (nothing was raised)", 1, 0)
    raises("an unknown value", _source(render_trigger="timer"), "must be")
    proc = _defn()
    proc["render_trigger"] = "inlet"
    raises("\"inlet\" on a processor", proc, "source archetype only")
    raises("\"inlet\" on a source without mod_inlets", _source(render_trigger="inlet", mod_inlets=[]), "needs mod_inlets")


def test_the_vortex_modules_ship_without_r_draw_and_keep_their_hand_built_controls():
    for name in ("f_vf_vortex", "f_vf_vortex_multi"):
        built, _ = drift.build_module(name)
        texts = [b["box"].get("text") for b in built["patcher"]["boxes"]]
        _eq(f"{name}: no `r draw`", "r draw" in texts, False)
    built, _ = drift.build_module("f_vf_vortex_multi")
    classes = [b["box"]["maxclass"] for b in built["patcher"]["boxes"]]
    _eq("f_vf_vortex_multi keeps its nodes object and vsc_center_ctrl bpatcher (raw_boxes)",
        ("nodes" in classes, "bpatcher" in classes), (True, True))
    _eq("...and the nodes object's saved state is in the parameters block",
        "obj-901" in built["patcher"]["parameters"], True)


def test_every_shipped_definition_builds_with_ports_in_order():
    n = 0
    for name in drift.shipped_names():
        if drift.definition_path(name).exists() and not drift.builder_script(name):
            built, _ = drift.build_module(name)      # build() runs check_port_order itself
            n += 1
            for mc in ("inlet", "outlet"):
                idx = {b["box"]["index"] for b in built["patcher"]["boxes"] if b["box"].get("maxclass") == mc}
                _eq(f"{name}: {mc} index", idx <= {0}, True)
    print(f"    ({n} definitions built)")
    _eq("a useful number of definitions were checked", n >= 25, True)


# ---- route_bypass

def _route_facts(defn):
    p = bp.build(defn)["patcher"]
    top = {b["box"]["id"]: b["box"] for b in p["boxes"]}
    route = top[bp.OBJ_ROUTE]
    from_route = sorted((ln["patchline"]["source"][1], ln["patchline"]["destination"][0])
                        for ln in p["lines"] if ln["patchline"]["source"][0] == bp.OBJ_ROUTE)
    jsui = [i for i, b in top.items() if b.get("maxclass") == "jsui"][0]
    return {"text": route["text"], "numoutlets": route["numoutlets"], "from_route": from_route,
            "jsui": jsui, "top": top, "lines": p["lines"]}


def test_route_bypass_default_is_off_and_unchanged():
    d = _route_facts(_defn())
    _eq("default: no bypass token", d["text"], "route g mix_pct n")
    _eq("default: nothing from the route reaches the bypass jsui",
        any(dst == d["jsui"] for _, dst in d["from_route"]), False)
    _eq("an explicit False is the default", _route_facts(dict(_defn(), route_bypass=False))["from_route"],
        d["from_route"])


def test_route_bypass_adds_the_token_the_cord_and_shifts_every_outlet():
    on = _route_facts(dict(_defn(), route_bypass=True))
    off = _route_facts(_defn())
    _eq("bypass is the first token", on["text"], "route bypass g mix_pct n")
    _eq("one more route outlet", on["numoutlets"], off["numoutlets"] + 1)
    _eq("outlet 0 goes to the bypass jsui", [dst for i, dst in on["from_route"] if i == 0], [on["jsui"]])
    # the invariant that matters: whatever a route token names is what its outlet feeds
    tokens = on["text"].split()[1:]
    ctl_name = {bp.param_obj_id(n): b["varname"] for n, b in enumerate(
        [on["top"][bp.param_obj_id(k)] for k in range(3)])}
    for i, dst in on["from_route"]:
        if dst in ctl_name:
            _eq(f"outlet {i} (token {tokens[i]!r}) feeds the control of that name", ctl_name[dst], tokens[i])
    _eq("every param is still fed exactly once", sorted(d for _, d in on["from_route"] if d in ctl_name),
        sorted(ctl_name))
    shifted = [(i - 1, dst) for i, dst in on["from_route"] if i > 0]
    _eq("the param cords are the default's, one outlet up", shifted, off["from_route"])


def test_route_bypass_shifts_the_header_toggle_outlet_too():
    def toggle_source(**extra):
        d = _defn()
        d["params"].insert(3, {"name": "tog", "type": "header_toggle", "label": "T", "hint": "t", "default": 0,
                                "min": 0, "max": 1})
        d["codebox"] = "Param tog(0.0);\n" + d["codebox"]
        d.update(extra)
        f = _route_facts(d)
        tokens = f["text"].split()[1:]
        return tokens, [i for i, dst in f["from_route"] if dst == bp.OBJ_HEADER_TOGGLE]
    for rb in (False, True):
        tokens, outs = toggle_source(route_bypass=rb)
        _eq(f"route_bypass={rb}: the header toggle's outlet is the one named `tog`",
            [tokens[i] for i in outs], ["tog"])


def test_route_bypass_changes_nothing_else():
    on = bp.build(dict(_defn(), route_bypass=True))["patcher"]
    off = bp.build(_defn())["patcher"]
    # patching_rect is the layout pass's (it moves the controls over by one lane column; see
    # tests/test_layout.py), so compare everything else
    no_rect = lambda b: {k: v for k, v in b.items() if k != "patching_rect"}
    on_boxes = {b["box"]["id"]: no_rect(b["box"]) for b in on["boxes"]}
    off_boxes = {b["box"]["id"]: no_rect(b["box"]) for b in off["boxes"]}
    _eq("the same boxes", sorted(on_boxes), sorted(off_boxes))
    diff = sorted(i for i in on_boxes if on_boxes[i] != off_boxes[i])
    _eq("only the route box differs (apart from patching_rect)", diff, [bp.OBJ_ROUTE])
    keyed = lambda lines: sorted((tuple(ln["patchline"]["source"]), tuple(ln["patchline"]["destination"]))
                                 for ln in lines if ln["patchline"]["source"][0] != bp.OBJ_ROUTE)
    _eq("every cord that does not leave the route is identical", keyed(on["lines"]), keyed(off["lines"]))


def test_route_bypass_is_loud():
    try:
        bp.build(dict(_defn(), route_bypass="yes"))
    except ValueError as e:
        check("a non-boolean value", 0 if "route_bypass" in str(e) else 1, 0)
    else:
        check("a non-boolean value (nothing was raised)", 1, 0)


def test_f_mobius_routes_bypass_as_shipped():
    built, _ = drift.build_module("f_mobius")
    texts = [b["box"].get("text") for b in built["patcher"]["boxes"]]
    _eq("f_mobius builds its `route bypass ...`", "route bypass cx cy rotate zoom invert" in texts, True)


# ---- modmode

def _modmodes(defn):
    out = {}
    for b in _boxes_of(defn):
        v = b.get("saved_attribute_attributes", {}).get("valueof")
        if b.get("maxclass") in ("live.dial", "live.numbox") and v:
            out[v["parameter_longname"]] = v["parameter_modmode"]
    return out


def _boxes_of(defn):
    return [b["box"] for b in bp.build(defn)["patcher"]["boxes"]]


def test_modmode_defaults_to_relative_and_a_param_can_turn_it_off():
    _eq("default: every dial and numbox is 3", _modmodes(_defn()), {"g": 3, "mix_pct": 3, "n": 3})
    d = _defn()
    d["params"][0]["modmode"] = 0          # a dial
    d["params"][2]["modmode"] = 0          # an int numbox
    _eq("only the params that say so change (dial and numbox)", _modmodes(d), {"g": 0, "mix_pct": 3, "n": 0})
    d2 = _defn()
    d2["params"][1]["modmode"] = 4         # a float numbox
    _eq("any of Max's 0-4 is passed through", _modmodes(d2), {"g": 3, "mix_pct": 4, "n": 3})


def test_modmode_is_loud_outside_0_to_4():
    for bad in (5, -1, 3.0, "0", True, None):
        d = _defn()
        d["params"][0]["modmode"] = bad
        try:
            bp.build(d)
        except ValueError as e:
            check(f"modmode {bad!r} is refused, naming the param", 0 if "'g'" in str(e) and "modmode" in str(e) else 1, 0)
        else:
            check(f"modmode {bad!r} (nothing was raised)", 1, 0)


def test_f_droste_has_its_time_s_inlet_and_a_dial_with_modulation_off():
    built, _ = drift.build_module("f_droste")
    top = [b["box"] for b in built["patcher"]["boxes"]]
    inlets = sorted((b["patching_rect"][0], b.get("comment")) for b in top if b["maxclass"] == "inlet")
    _eq("two inlets, in port order: the texture / control inlet, then time_s",
        [c for _, c in inlets], ["texture / control", "time_s"])
    attr = [b for b in top if b["maxclass"] == "attrui" and b.get("attr") == "time_s"]
    _eq("one attrui for time_s", len(attr), 1)
    inlet = [b for b in top if b.get("comment") == "time_s"][0]
    cords = {(ln["patchline"]["source"][0], ln["patchline"]["destination"][0]) for ln in built["patcher"]["lines"]}
    _eq("inlet -> attrui -> the pix", ((inlet["id"], attr[0]["id"]) in cords, (attr[0]["id"], bp.OBJ_PIX) in cords),
        (True, True))
    modes = {b["saved_attribute_attributes"]["valueof"]["parameter_longname"]:
             b["saved_attribute_attributes"]["valueof"]["parameter_modmode"]
             for b in top if b["maxclass"] == "live.dial"}
    _eq("only n_arms has modulation off", modes, {"zoom": 3, "n_arms": 0, "twist": 3, "rotation": 3})


# ---- route_name, hint None, param_connect follows pix_target

def _route(defn):
    p = bp.build(defn)["patcher"]
    top = {b["box"]["id"]: b["box"] for b in p["boxes"]}
    r = top[bp.OBJ_ROUTE]
    out = {}
    for ln in p["lines"]:
        pl = ln["patchline"]
        if pl["source"][0] == bp.OBJ_ROUTE:
            out[pl["source"][1]] = top[pl["destination"][0]].get("varname")
    return r["text"].split()[1:], out


def test_route_name_changes_the_token_not_the_control_it_reaches():
    d = _defn()
    d["params"][1]["route_name"] = "mix"          # mix_pct answers to `mix`
    tokens, out = _route(d)
    _eq("the token is the route_name", tokens, ["g", "mix", "n"])
    _eq("and its outlet still reaches the mix_pct control", [out[i] for i in range(3)], ["g", "mix_pct", "n"])
    _eq("without it the token is the name (unchanged)", _route(_defn())[0], ["g", "mix_pct", "n"])
    d2 = _defn()
    d2["route_bypass"] = True
    d2["params"][1]["route_name"] = "mix"
    t2, o2 = _route(d2)
    _eq("with route_bypass the shift still holds", (t2, [o2[i] for i in range(1, 4)]),
        (["bypass", "g", "mix", "n"], ["g", "mix_pct", "n"]))


def test_route_name_is_loud():
    def raises(label, mutate, fragment):
        d = _defn()
        mutate(d)
        try:
            bp.build(d)
        except ValueError as e:
            check(label, 0 if fragment in str(e) else 1, 0)
        else:
            check(label + " (nothing was raised)", 1, 0)
    raises("two words", lambda d: d["params"][0].update(route_name="a b"), "single word")
    raises("empty", lambda d: d["params"][0].update(route_name=""), "single word")
    raises("surrounding space (one word after split, but not a clean token)",
           lambda d: d["params"][0].update(route_name=" x"), "single word")
    raises("not a string", lambda d: d["params"][0].update(route_name=3), "single word")
    raises("bypass is reserved", lambda d: d["params"][0].update(route_name="bypass"), "reserved")
    raises("a token that duplicates another param's name", lambda d: d["params"][0].update(route_name="n"), "unique")
    raises("two params sharing a route_name",
           lambda d: (d["params"][0].update(route_name="x"), d["params"][2].update(route_name="x")), "unique")


def test_hint_none_writes_no_hint_key_and_unset_still_writes_an_empty_one():
    def hints(**per_param):
        d = _defn()
        for i, h in per_param.items():
            d["params"][int(i[1:])]["hint"] = h
        d["params"].insert(3, {"name": "m", "type": "menu", "options": ["a", "b"], "default": 0, "label": "M"})
        d["codebox"] = "Param m(0.0);\n" + d["codebox"]
        got = {}
        for b in _boxes_of(d):
            v = b.get("saved_attribute_attributes", {}).get("valueof", {})
            if v.get("parameter_longname") in ("g", "mix_pct", "n", "m"):
                got[v["parameter_longname"]] = b.get("hint", "<no key>")
        return got
    base = hints()
    _eq("a param with a hint keeps it; one with none still gets \"\" (the builder's long-standing output)",
        (base["g"], base["mix_pct"], base["n"], base["m"]), ("g", "m", "n", ""))
    none = hints(p0=None, p1=None, p2=None)
    _eq("\"hint\": None omits the key (dial, numbox, int numbox); an unset menu hint is unchanged",
        (none["g"], none["mix_pct"], none["n"], none["m"]), ("<no key>", "<no key>", "<no key>", ""))
    d = _defn()
    d["params"].insert(0, {"name": "m", "type": "menu", "options": ["a", "b"], "default": 0, "label": "M", "hint": None})
    d["codebox"] = "Param m(0.0);\n" + d["codebox"]
    menu = [b for b in _boxes_of(d) if b.get("varname") == "m"][0]
    _eq("a menu honours hint None too", "hint" in menu, False)


def test_param_connect_names_the_pix_a_control_drives():
    built, _ = drift.build_module("f_vf_advect")
    top = [b["box"] for b in built["patcher"]["boxes"]]
    pc = {b["varname"]: b["param_connect"] for b in top
          if b.get("param_connect") and b.get("varname") and b["maxclass"] != "jsui"}
    _eq("separate and mode drive the pass pix, and param_connect says so",
        (pc["separate"], pc["mode"]), ("#0_advect_pass::separate", "#0_advect_pass::mode"))
    _eq("the rest name the primary pix",
        {k: v for k, v in pc.items() if k not in ("separate", "mode")},
        {k: f"#0_advect_pix::{k}" for k in ("dt", "decay", "injection", "gain", "mix_pct")})
    d = _defn()
    d["params"][0]["pix_target"] = "obj-raw-9"       # a raw object id: its @name is unknown here
    pcs = {b["varname"]: b["param_connect"] for b in _boxes_of(d) if b.get("param_connect") and b.get("varname")}
    _eq("a raw-object pix_target keeps naming the primary pix, as before", pcs["g"], "t_pix::g")
    # a control built AFTER a pix_target one must not inherit its target (the pix name is per control)
    d3 = _defn()
    d3["params"][0]["pix_target"] = "obj-raw-9"
    d3["params"].insert(1, {"name": "tog", "type": "header_toggle", "label": "T", "hint": "t", "default": 0,
                            "min": 0, "max": 1})
    d3["codebox"] = "Param tog(0.0);\n" + d3["codebox"]
    after = {b["varname"]: b["param_connect"] for b in _boxes_of(d3) if b.get("param_connect") and b.get("varname")}
    _eq("the header toggle and the controls after a pix_target one still name the primary pix",
        (after["tog"], after["mix_pct"], after["n"]), ("t_pix::tog", "t_pix::mix_pct", "t_pix::n"))
    # ...and the same on a real pix_chain: a header toggle added after advect's `separate` / `mode`
    # (which target the pass pix) must still name the PRIMARY pix, not the pass pix
    import copy
    adv = copy.deepcopy(bp.load_definition(ROOT / "src" / "f_vf_advect" / "definition.py"))
    adv["params"].insert(-1, {"name": "tog", "type": "header_toggle", "label": "T", "hint": "t", "default": 0,
                              "min": 0, "max": 1})
    tog = [b["box"] for b in bp.build(adv)["patcher"]["boxes"] if b["box"].get("varname") == "tog"][0]
    _eq("on a pix_chain too: a control after the pass-pix ones names the primary pix",
        tog["param_connect"], "#0_advect_pix::tog")


def test_f_vf_advect_builds_from_its_definition_as_it_ships():
    built, _ = drift.build_module("f_vf_advect")
    p = built["patcher"]
    top = {b["box"]["id"]: b["box"] for b in p["boxes"]}
    tokens = top[bp.OBJ_ROUTE]["text"].split()[1:]
    _eq("route tokens, `mix` for the mix_pct numbox",
        tokens, ["dt", "decay", "injection", "gain", "mix", "separate", "mode"])
    outs = sorted((b["comment"] for b in top.values() if b["maxclass"] == "outlet"))
    _eq("three outlets", outs, ["advected", "composite", "vecfield"])
    pix = [b for b in top.values() if str(b.get("text", "")).startswith("jit.gl.pix")]
    _eq("both pix are float32 @adapt 1", sorted(b["text"] for b in pix),
        ["jit.gl.pix vsynth @name #0_advect_pass @type float32 @adapt 1",
         "jit.gl.pix vsynth @name #0_advect_pix @type float32 @adapt 1"])
    _eq("the menu offers Ride / Hold / Snap",
        [b["saved_attribute_attributes"]["valueof"]["parameter_enum"] for b in top.values()
         if b.get("varname") == "mode"], [["Ride", "Hold", "Snap"]])


# ---- route_first, pix_wire, inlet_comment, outlet hint (f_grain)

def _cords(defn):
    p = bp.build(defn)["patcher"]
    top = {b["box"]["id"]: b["box"] for b in p["boxes"]}
    return top, {(tuple(ln["patchline"]["source"]), tuple(ln["patchline"]["destination"])) for ln in p["lines"]}


def test_route_first_reverses_the_topology_and_adds_the_reject_outlet():
    top0, c0 = _cords(_defn())
    _eq("default: inlet -> routepass, routepass unmatched -> route",
        ((("obj-1", 0), (bp.OBJ_ROUTEPASS, 0)) in c0, ((bp.OBJ_ROUTEPASS, 2), (bp.OBJ_ROUTE, 0)) in c0), (True, True))
    top1, c1 = _cords(dict(_defn(), route_first=True))
    n = len(top1[bp.OBJ_ROUTE]["text"].split()) - 1
    _eq("route_first: inlet -> route", ((bp.OBJ_INLET, 0), (bp.OBJ_ROUTE, 0)) in c1, True)
    _eq("route_first: no inlet -> routepass", ((bp.OBJ_INLET, 0), (bp.OBJ_ROUTEPASS, 0)) in c1, False)
    _eq("route_first: the reject outlet (one past the last token) -> routepass",
        ((bp.OBJ_ROUTE, n), (bp.OBJ_ROUTEPASS, 0)) in c1, True)
    _eq("route_first: no routepass unmatched -> route", ((bp.OBJ_ROUTEPASS, 2), (bp.OBJ_ROUTE, 0)) in c1, False)
    _eq("the route box has the extra (reject) outlet", top1[bp.OBJ_ROUTE]["numoutlets"], n + 1)
    _eq("default route box has none", top0[bp.OBJ_ROUTE]["numoutlets"], n)
    top2, c2 = _cords(dict(_defn(), route_first=True, route_bypass=True))
    n2 = len(top2[bp.OBJ_ROUTE]["text"].split()) - 1
    _eq("with route_bypass the reject outlet moves up with the tokens",
        (n2, ((bp.OBJ_ROUTE, n2), (bp.OBJ_ROUTEPASS, 0)) in c2, top2[bp.OBJ_ROUTE]["numoutlets"]), (n + 1, True, n2 + 1))
    try:
        bp.build(dict(_defn(), route_first="yes"))
    except ValueError as e:
        check("a non-boolean route_first", 0 if "route_first" in str(e) else 1, 0)
    else:
        check("a non-boolean route_first (nothing was raised)", 1, 0)
    gone = {c for c in c0 if c not in c1}
    _eq("exactly the two default cords are replaced",
        sorted(gone), sorted({((bp.OBJ_INLET, 0), (bp.OBJ_ROUTEPASS, 0)), ((bp.OBJ_ROUTEPASS, 2), (bp.OBJ_ROUTE, 0))}))


def test_pix_wire_false_leaves_a_control_with_a_route_outlet_and_nothing_else():
    d = _defn()
    d["params"][0]["pix_wire"] = False                     # the `g` dial
    top, cords = _cords(d)
    dial = bp.param_obj_id(0)
    _eq("the dial and its label still exist", (dial in top, bp.param_label_id(0) in top), (True, True))
    _eq("but no attrui for it", bp.param_pre_id(0) in top, False)
    _eq("its route outlet still reaches the dial", ((bp.OBJ_ROUTE, 0), (dial, 0)) in cords, True)
    _eq("and the dial has no cord going anywhere", [c for c in cords if c[0][0] == dial], [])
    _eq("the other params keep their attrui and cords",
        all(bp.param_pre_id(k) in top and ((bp.param_obj_id(k), 0), (bp.param_pre_id(k), 0)) in cords for k in (1, 2)), True)
    base_top, _ = _cords(_defn())
    _eq("the only box that disappears is that attrui", sorted(set(base_top) - set(top)), [bp.param_pre_id(0)])
    bad = _defn()
    bad["params"][0]["pix_wire"] = "no"
    try:
        bp.build(bad)
    except ValueError as e:
        check("a non-boolean pix_wire", 0 if "pix_wire" in str(e) else 1, 0)
    else:
        check("a non-boolean pix_wire (nothing was raised)", 1, 0)


def test_inlet_comment_and_outlet_hint():
    def inlet(defn):
        return [b for b in _boxes_of(defn) if b["maxclass"] == "inlet"][0]["comment"]
    _eq("default inlet comment", inlet(_defn()), "texture / control")
    _eq("custom inlet comment", inlet(dict(_defn(), inlet_comment="control")), "control")
    _eq("an empty inlet comment is honoured", inlet(dict(_defn(), inlet_comment="")), "")
    try:
        bp.build(dict(_defn(), inlet_comment=3))
    except ValueError as e:
        check("a non-string inlet_comment", 0 if "inlet_comment" in str(e) else 1, 0)
    else:
        check("a non-string inlet_comment (nothing was raised)", 1, 0)
    d = _defn()
    d["outlets"][1]["hint"] = "Raw"
    outs = {b["comment"]: b for b in _boxes_of(d) if b["maxclass"] == "outlet"}
    _eq("an outlet hint is written, and only where given",
        (outs["aux"].get("hint"), "hint" in outs["composite"], "hint" in outs["third"]), ("Raw", False, False))


def test_f_grain_builds_from_its_definition_as_it_ships():
    built, _ = drift.build_module("f_grain")
    p = built["patcher"]
    top = {b["box"]["id"]: b["box"] for b in p["boxes"]}
    route = top[bp.OBJ_ROUTE]
    _eq("the route, with `edge_mode_menu` for the umenu and the numbox routes last",
        route["text"], "route bypass density amount persistence fade size size_var shape softness jitter "
                       "ch_diverge luma_gate displace edge_mode_menu field sv_seed")
    cords = {(tuple(ln["patchline"]["source"]), tuple(ln["patchline"]["destination"])) for ln in p["lines"]}
    _eq("control-first: inlet -> route, reject outlet -> routepass",
        (((bp.OBJ_INLET, 0), (bp.OBJ_ROUTE, 0)) in cords, ((bp.OBJ_ROUTE, 16), (bp.OBJ_ROUTEPASS, 0)) in cords),
        (True, True))
    inlet = [b for b in top.values() if b["maxclass"] == "inlet"][0]
    _eq("the inlet has no comment", inlet["comment"], "")
    pers = [i for i, b in top.items() if b.get("varname") == "persistence"][0]
    _eq("persistence is a dial with no attrui: its only cord goes into the era-clock chain",
        sorted(top[d[0]].get("text", top[d[0]]["maxclass"]) for (s, d) in cords if s[0] == pers),
        ["expr pow(1.0 - $f1\\, 2.0)"])
    raw = sorted(i for i in top if i.startswith("obj-9") and len(i) == 7 and i[5:].isdigit() and int(i[4:]) >= 901)
    _eq("14 raw boxes, obj-901..obj-914", raw, [f"obj-{n}" for n in range(901, 915)])
    _eq("the raw numboxes and the umenu are in the parameters block",
        sorted(k for k in p["parameters"] if k in raw), ["obj-901", "obj-906", "obj-912"])
    outs = {b["comment"]: b for b in top.values() if b["maxclass"] == "outlet"}
    _eq("the grain mask outlet has its hint", outs["grain mask"].get("hint"), "Raw")
    _eq("two `r draw`: one into the persistence chain, one into the pix",
        sorted(b["text"] for b in top.values() if b.get("text") == "r draw"), ["r draw", "r draw"])


# ---- legacy, route_reject_to_pix, color_expression (f_channel_grader)

def _controls(defn):
    return {b["varname"]: b for b in _boxes_of(defn) if b.get("maxclass") in ("live.dial", "live.numbox")}


def test_legacy_is_default_off_and_each_entry_does_only_its_job():
    base = bp.build(_defn())["patcher"]
    top = {b["box"]["id"]: b["box"] for b in base["boxes"]}
    _eq("default: pix varname is the object name, autopattr is <prefix>_autopattr, jsui has no saved block",
        (top[bp.OBJ_PIX]["varname"], top[bp.OBJ_AUTOPATTR]["varname"],
         "saved_attribute_attributes" in [b for b in top.values() if b["maxclass"] == "jsui"][0]),
        ("t_pix", "t_autopattr", False))
    d = _defn()
    d["legacy"] = {"pix_varname": "jit.gl.pix_AA", "autopattr_varname": "u123",
                   "bypass_jsui_saved": {"valueof": {"parameter_invisible": 1}}}
    new = bp.build(d)["patcher"]
    nt = {b["box"]["id"]: b["box"] for b in new["boxes"]}
    pix = nt[bp.OBJ_PIX]
    _eq("pix varname changes, its @name does not", (pix["varname"], "@name t_pix" in pix["text"]),
        ("jit.gl.pix_AA", True))
    _eq("every control's param_connect follows the pix varname",
        sorted({b["param_connect"].split("::")[0] for b in nt.values() if b.get("param_connect")}), ["jit.gl.pix_AA"])
    _eq("autopattr varname", nt[bp.OBJ_AUTOPATTR]["varname"], "u123")
    jsui = [b for b in nt.values() if b["maxclass"] == "jsui"][0]
    _eq("the jsui's saved block, verbatim", jsui["saved_attribute_attributes"], {"valueof": {"parameter_invisible": 1}})
    d["legacy"]["bypass_jsui_saved"]["valueof"]["parameter_invisible"] = 9
    _eq("and a copy: editing the definition afterwards does not reach the built box",
        jsui["saved_attribute_attributes"]["valueof"]["parameter_invisible"], 1)
    only = [i for i in nt if nt[i] != top.get(i)]
    _eq("nothing else changed (the same boxes, only pix / autopattr / jsui / param_connect ones differ)",
        sorted(set(only) - {bp.OBJ_PIX, bp.OBJ_AUTOPATTR} - {i for i, b in nt.items()
                                                              if b.get("param_connect") or b["maxclass"] == "jsui"}), [])


def test_legacy_control_valueof_patches_only_the_named_control_and_none_removes():
    d = _defn()
    d["legacy"] = {"control_valueof": {"g": {"parameter_shortname": "live.dial"},
                                       "n": {"parameter_initial": None, "parameter_initial_enable": None}}}
    got, base = _controls(d), _controls(_defn())
    v = lambda c, k: c["saved_attribute_attributes"]["valueof"].get(k, "<absent>")
    _eq("g: the shortname is replaced", (v(got["g"], "parameter_shortname"), v(base["g"], "parameter_shortname")),
        ("live.dial", "g"))
    _eq("n: the two initial keys are removed", (v(got["n"], "parameter_initial"), v(got["n"], "parameter_initial_enable")),
        ("<absent>", "<absent>"))
    _eq("mix_pct is untouched", got["mix_pct"]["saved_attribute_attributes"], base["mix_pct"]["saved_attribute_attributes"])
    _eq("and g's other valueof keys are untouched",
        {k: x for k, x in got["g"]["saved_attribute_attributes"]["valueof"].items() if k != "parameter_shortname"},
        {k: x for k, x in base["g"]["saved_attribute_attributes"]["valueof"].items() if k != "parameter_shortname"})


def test_legacy_is_loud():
    def raises(label, legacy, fragment, extra=None):
        d = dict(_defn(), legacy=legacy)
        if extra:
            d.update(extra)
        try:
            bp.build(d)
        except ValueError as e:
            check(label, 0 if fragment in str(e) else 1, 0)
        else:
            check(label + " (nothing was raised)", 1, 0)
    raises("not a dict", ["pix_varname"], "must be a dict")
    raises("an unknown key", {"pix_varnam": "x"}, "unknown key")
    raises("an empty pix_varname", {"pix_varname": ""}, "pix_varname")
    raises("a non-string autopattr_varname", {"autopattr_varname": 3}, "autopattr_varname")
    raises("a non-dict jsui block", {"bypass_jsui_saved": "x"}, "bypass_jsui_saved")
    raises("control_valueof of the wrong shape", {"control_valueof": {"g": "x"}}, "control_valueof")
    raises("control_valueof naming a param that does not exist", {"control_valueof": {"zzz": {"a": 1}}}, "do not exist")
    adv = copy.deepcopy(bp.load_definition(ROOT / "src" / "f_vf_advect" / "definition.py"))
    adv["legacy"] = {"pix_varname": "x"}
    try:
        bp.build(adv)
    except ValueError as e:
        check("pix_varname on a pix_chain", 0 if "pix_chain" in str(e) else 1, 0)
    else:
        check("pix_varname on a pix_chain (nothing was raised)", 1, 0)


def test_route_reject_to_pix_adds_the_outlet_and_the_cord():
    top0, c0 = _cords(_defn())
    top1, c1 = _cords(dict(_defn(), route_reject_to_pix=True))
    n = len(top1[bp.OBJ_ROUTE]["text"].split()) - 1
    _eq("the reject outlet (one past the last token) -> the pix", ((bp.OBJ_ROUTE, n), (bp.OBJ_PIX, 0)) in c1, True)
    _eq("the route box has the extra outlet; default has not", (top1[bp.OBJ_ROUTE]["numoutlets"], top0[bp.OBJ_ROUTE]["numoutlets"]), (n + 1, n))
    _eq("it is the only cord added", sorted(c1 - c0), [((bp.OBJ_ROUTE, n), (bp.OBJ_PIX, 0))])
    _eq("and the normal topology is kept (inlet -> routepass, routepass unmatched -> route)",
        (((bp.OBJ_INLET, 0), (bp.OBJ_ROUTEPASS, 0)) in c1, ((bp.OBJ_ROUTEPASS, 2), (bp.OBJ_ROUTE, 0)) in c1), (True, True))
    top2, c2 = _cords(dict(_defn(), route_reject_to_pix=True, route_bypass=True))
    n2 = len(top2[bp.OBJ_ROUTE]["text"].split()) - 1
    _eq("with route_bypass the reject index moves up with the tokens", ((bp.OBJ_ROUTE, n2), (bp.OBJ_PIX, 0)) in c2, True)
    for label, d, frag in (("with route_first", dict(_defn(), route_reject_to_pix=True, route_first=True), "both use"),
                           ("non-boolean", dict(_defn(), route_reject_to_pix="yes"), "route_reject_to_pix")):
        try:
            bp.build(d)
        except ValueError as e:
            check(f"route_reject_to_pix {label}", 0 if frag in str(e) else 1, 0)
        else:
            check(f"route_reject_to_pix {label} (nothing was raised)", 1, 0)


def test_color_expression_sets_the_dial_theme_string_only():
    d = _defn()
    d["params"][0]["color_expression"] = "themecolor.live_record"
    got, base = _controls(d), _controls(_defn())
    ex = lambda c: c["saved_attribute_attributes"].get("activedialcolor", {}).get("expression", "<none>")
    _eq("the dial gets it; an unset dial keeps \"\"; a numbox has no activedialcolor",
        (ex(got["g"]), ex(base["g"]), ex(got["mix_pct"]), ex(got["n"])),
        ("themecolor.live_record", "", "<none>", "<none>"))
    bad = _defn()
    bad["params"][0]["color_expression"] = 3
    try:
        bp.build(bad)
    except ValueError as e:
        check("a non-string color_expression", 0 if "color_expression" in str(e) else 1, 0)
    else:
        check("a non-string color_expression (nothing was raised)", 1, 0)


def test_f_channel_grader_builds_from_its_definition_as_it_ships():
    built, _ = drift.build_module("f_channel_grader")
    p = built["patcher"]
    top = {b["box"]["id"]: b["box"] for b in p["boxes"]}
    pix = top[bp.OBJ_PIX]
    _eq("the pix text is the old @drawto form, and its varname is the re-created one",
        (pix["text"], pix["varname"]), ("jit.gl.pix @name cg_pix @drawto vsynth @type char", "jit.gl.pix_AA"))
    dials = {b["varname"]: b for b in top.values() if b["maxclass"] == "live.dial"}
    _eq("12 dials, all bound to that varname", (len(dials), {b["param_connect"].split("::")[0] for b in dials.values()}),
        (12, {"jit.gl.pix_AA"}))
    labels = sorted(b["text"] for b in top.values() if b["maxclass"] == "comment" and b["text"] in ("Lift", "Gam", "Gain"))
    _eq("three shared row labels (raw) and no per-dial labels", (labels, [b for b in top if b.startswith("obj-") and top[b]["maxclass"] == "comment" and top[b].get("varname", "").startswith("lbl_")]),
        (["Gain", "Gam", "Lift"], []))
    route = top[bp.OBJ_ROUTE]
    _eq("route: bypass first, one reject outlet that feeds the pix",
        (route["text"].split()[1], route["numoutlets"],
         any(ln["patchline"]["source"] == [bp.OBJ_ROUTE, 13] and ln["patchline"]["destination"] == [bp.OBJ_PIX, 0]
             for ln in p["lines"])), ("bypass", 14, True))
    _eq("autopattr keeps its auto name", top[bp.OBJ_AUTOPATTR]["varname"], "u905020188")
    ex = lambda v: dials[v]["saved_attribute_attributes"]["activedialcolor"]["expression"]
    _eq("the rows keep their theme colours (R, G, B; Master has none)",
        (ex("r_gain"), ex("g_lift"), ex("b_gamma"), ex("m_gain")),
        ("themecolor.live_record", "themecolor.live_macro_assignment", "themecolor.live_prelisten", ""))
    _eq("m_lift has no initial value, g_lift keeps Max's default shortname",
        ("parameter_initial" in dials["m_lift"]["saved_attribute_attributes"]["valueof"],
         dials["g_lift"]["saved_attribute_attributes"]["valueof"]["parameter_shortname"]), (False, "live.dial"))


# ---- color_expression None, legacy.control_box (the three band-editor colour modules)

def test_color_expression_none_omits_the_activedialcolor_entry():
    d = _defn()
    d["params"][0]["color_expression"] = None
    got, base = _controls(d), _controls(_defn())
    has = lambda c: "activedialcolor" in c["saved_attribute_attributes"]
    _eq("None: no activedialcolor entry; unset: the empty one is still written; a numbox is unaffected",
        (has(got["g"]), has(base["g"]), has(got["mix_pct"])), (False, True, False))
    _eq("the rest of that dial's saved block is untouched",
        {k: v for k, v in got["g"]["saved_attribute_attributes"].items()},
        {k: v for k, v in base["g"]["saved_attribute_attributes"].items() if k != "activedialcolor"})
    d2 = _defn()
    d2["params"][0]["color_expression"] = "themecolor.live_record"
    _eq("a string still sets it", _controls(d2)["g"]["saved_attribute_attributes"]["activedialcolor"]["expression"],
        "themecolor.live_record")


def test_legacy_control_box_sets_and_removes_top_level_properties_of_the_named_control():
    d = _defn()
    d["legacy"] = {"control_box": {"g": {"param_connect": None, "hint": "custom"}, "n": {"annotation": "x"}}}
    got, base = _controls(d), _controls(_defn())
    _eq("g: param_connect removed, hint replaced", ("param_connect" in got["g"], got["g"]["hint"]), (False, "custom"))
    _eq("n: a new property is added", got["n"].get("annotation"), "x")
    _eq("mix_pct is untouched", got["mix_pct"], base["mix_pct"])
    _eq("and g keeps every other property",
        {k: v for k, v in got["g"].items() if k not in ("param_connect", "hint")},
        {k: v for k, v in base["g"].items() if k not in ("param_connect", "hint")})

    def raises(label, cb, fragment):
        try:
            bp.build(dict(_defn(), legacy={"control_box": cb}))
        except ValueError as e:
            check(label, 0 if fragment in str(e) else 1, 0)
        else:
            check(label + " (nothing was raised)", 1, 0)
    raises("wrong shape", {"g": "x"}, "control_box")
    raises("a param that does not exist", {"zzz": {"hint": "x"}}, "do not exist")
    for forbidden in ("id", "maxclass", "patching_rect", "patcher"):
        raises(f"forbidden property {forbidden!r}", {"g": {forbidden: 1}}, "cannot set")


def test_the_band_editor_colour_modules_build_as_they_ship():
    for name, tokens, dials, raw_n in (
        ("f_hue_processor", "bypass sat_amt lum_shift hue_shift edge_falloff", {"sat_amt", "lum_shift", "hue_shift"}, 14),
        ("f_luma_processor", "bypass sat_amt lum_shift hue_shift edge_falloff low_mid mid_high",
         {"sat_amt", "lum_shift", "hue_shift"}, 12),
        ("f_tone_curve", "bypass shadows midtones highlights edge_falloff low_mid mid_high",
         {"shadows", "midtones", "highlights", "edge_falloff"}, 11),
    ):
        built, _ = drift.build_module(name)
        p = built["patcher"]
        top = {b["box"]["id"]: b["box"] for b in p["boxes"]}
        route = top[bp.OBJ_ROUTE]
        _eq(f"{name}: route tokens", " ".join(route["text"].split()[1:]), tokens)
        n = len(route["text"].split()) - 1
        _eq(f"{name}: the reject outlet feeds the pix, and the route has that outlet",
            (route["numoutlets"], any(ln["patchline"]["source"] == [bp.OBJ_ROUTE, n]
                                      and ln["patchline"]["destination"] == [bp.OBJ_PIX, 0] for ln in p["lines"])),
            (n + 1, True))
        pix = top[bp.OBJ_PIX]
        _eq(f"{name}: the old @drawto pix form and the re-created varname",
            (pix["text"].startswith("jit.gl.pix @name ") and "@drawto vsynth" in pix["text"], pix["varname"]),
            (True, "jit.gl.pix_AA"))
        generic = {b["varname"] for i, b in top.items()
                   if b["maxclass"] == "live.dial" and i[4:].isdigit() and int(i[4:]) < 901}
        _eq(f"{name}: the generated dials (ids below the raw range) are the ones the builder can make exactly",
            generic, dials)
        raw = [i for i in top if i.startswith("obj-9") and i[4:].isdigit() and int(i[4:]) >= 901]
        _eq(f"{name}: raw boxes obj-901..", sorted(raw), [f"obj-{n}" for n in range(901, 901 + raw_n)])
        _eq(f"{name}: no generated dial has an activedialcolor entry (these dials never had one)",
            [v for v in (b for b in top.values() if b["maxclass"] == "live.dial")
             if "activedialcolor" in v.get("saved_attribute_attributes", {})], [])
        _eq(f"{name}: no bypass-message cord is missing (route outlet 0 reaches the jsui)",
            any(ln["patchline"]["source"] == [bp.OBJ_ROUTE, 0]
                and top[ln["patchline"]["destination"][0]]["maxclass"] == "jsui" for ln in p["lines"]), True)


# ---- range-tier message text, legacy.element_*  (f_lens)

def test_max_float_text_is_max_style():
    f = bp._max_float_text
    _eq("whole numbers get a trailing dot, not .0",
        [f(0), f(0.0), f(1.0), f(-1.0), f(10.0), f(-5.0), f(100.0)], ["0.", "0.", "1.", "-1.", "10.", "-5.", "100."])
    _eq("everything else is its shortest repr", [f(0.2), f(1.5), f(-0.5), f(0.25), f(0.1)],
        ["0.2", "1.5", "-0.5", "0.25", "0.1"])


def test_range_tier_messages_are_written_max_style_for_unipolar_and_bipolar_tiers():
    def texts(tiers):
        d = _defn()
        d["params"][0]["range_tiers"] = tiers
        return sorted(b["text"] for b in _boxes_of(d) if b.get("maxclass") == "message" and b["text"].startswith("_parameter_range"))
    _eq("bipolar tuples", texts([(-1.0, 1.0), (-2.0, 2.0), (-10.0, 10.0)]),
        ["_parameter_range -1. 1.", "_parameter_range -10. 10.", "_parameter_range -2. 2."])
    _eq("unipolar floats, whole and fractional", texts([0.2, 1.0, 10.0]),
        ["_parameter_range 0. 0.2", "_parameter_range 0. 1.", "_parameter_range 0. 10."])
    _eq("a fractional bipolar tier", texts([(-0.5, 0.5), (-1.0, 1.0)]), ["_parameter_range -0.5 0.5", "_parameter_range -1. 1."])


def _elements(defn):
    dbg = {}
    p = bp.build(defn, debug=dbg)["patcher"]
    top = {b["box"]["id"]: b["box"] for b in p["boxes"]}
    return top, dbg["element_keys"]


def test_legacy_element_box_and_valueof_patch_any_element_by_its_override_key():
    def tiered(**legacy):
        d = _defn()
        d["params"][0]["range_tiers"] = [(-1.0, 1.0), (-2.0, 2.0)]
        d["legacy"] = legacy
        return d
    top0, keys0 = _elements(tiered())
    menu0 = top0[keys0["g.range_menu"]]
    top, keys = _elements(tiered(element_box={"g.range_menu": {"varname": "live.menu[1]"}},
                                 element_valueof={"g.range_menu": {"parameter_mmax": 1, "parameter_modmode": 0}}))
    menu = top[keys["g.range_menu"]]
    _eq("varname set (unset by default), mmax and modmode added to the saved valueof",
        (menu0.get("varname"), menu.get("varname"),
         menu["saved_attribute_attributes"]["valueof"].get("parameter_mmax"),
         menu["saved_attribute_attributes"]["valueof"].get("parameter_modmode")),
        (None, "live.menu[1]", 1, 0))
    _eq("everything else on that menu is unchanged",
        {k: v for k, v in menu.items() if k not in ("varname", "saved_attribute_attributes")},
        {k: v for k, v in menu0.items() if k not in ("varname", "saved_attribute_attributes")})
    _eq("and no other element changed",
        sorted(i for i in top if top[i] != top0.get(i) and i != keys["g.range_menu"]), [])
    top2, keys2 = _elements(tiered(element_valueof={"g.range_menu": {"parameter_enum": None}}))
    _eq("None removes a valueof key",
        "parameter_enum" in top2[keys2["g.range_menu"]]["saved_attribute_attributes"]["valueof"], False)

    def raises(label, legacy, fragment):
        try:
            bp.build(dict(tiered(), legacy=legacy))
        except ValueError as e:
            check(label, 0 if fragment in str(e) else 1, 0)
        else:
            check(label + " (nothing was raised)", 1, 0)
    raises("element_box: unknown element", {"element_box": {"nope.ctl": {"varname": "x"}}}, "unknown element")
    raises("element_valueof: unknown element", {"element_valueof": {"nope.ctl": {"a": 1}}}, "unknown element")
    raises("element_box: wrong shape", {"element_box": {"g.ctl": "x"}}, "element_box")
    raises("element_valueof: empty dict", {"element_valueof": {"g.ctl": {}}}, "element_valueof")
    raises("element_valueof: an element with no saved valueof", {"element_valueof": {"g.label": {"a": 1}}}, "no saved valueof")
    raises("element_box: a denied property", {"element_box": {"g.ctl": {"id": "obj-1"}}}, "cannot be overridden")


def test_f_lens_builds_from_its_definition_as_it_ships():
    built, _ = drift.build_module("f_lens")
    p = built["patcher"]
    top = {b["box"]["id"]: b["box"] for b in p["boxes"]}
    route = top[bp.OBJ_ROUTE]
    _eq("no tilt-shift tokens in the route (it moved to f_focus)",
        [t for t in route["text"].split() if t in ("tilt", "tilt_axis", "tilt_pos", "slope", "mode")], [])
    _eq("two pix: the primary lens pix and the raw halation pix",
        sorted(b["text"] for b in top.values() if str(b.get("text", "")).startswith("jit.gl.pix")),
        ["jit.gl.pix vsynth @name lens_halation @type char", "jit.gl.pix vsynth @name lens_pix @type char"])
    cords = {(tuple(ln["patchline"]["source"]), tuple(ln["patchline"]["destination"])) for ln in p["lines"]}
    _eq("the chain is lens pix -> halation -> outlet (no direct pix -> outlet cord)",
        (((bp.OBJ_PIX, 0), ("obj-raw-17", 0)) in cords, (("obj-raw-17", 0), (bp.OBJ_OUTLET, 0)) in cords,
         ((bp.OBJ_PIX, 0), (bp.OBJ_OUTLET, 0)) in cords), (True, True, False))
    byp = [i for i, b in top.items() if b["maxclass"] == "attrui" and b.get("attr") == "bypass"][0]
    _eq("the bypass attrui feeds both pix (the 2026-09-23 fix)",
        (((byp, 0), (bp.OBJ_PIX, 0)) in cords, ((byp, 0), ("obj-raw-17", 0)) in cords), (True, True))
    _eq("the range messages are Max-style",
        sorted(b["text"] for b in top.values() if b["maxclass"] == "message" and b["text"].startswith("_parameter_range")),
        ["_parameter_range -1. 1."] * 4 + ["_parameter_range -10. 10."] + ["_parameter_range -2. 2."] * 2 + ["_parameter_range -5. 5."] * 2)
    toggle = [b for b in top.values() if b["maxclass"] == "live.text"
              and b["saved_attribute_attributes"]["valueof"]["parameter_longname"] == "panel_toggle"][0]
    _eq("the panel toggle keeps Max's default enum labels (its visible labels are text / texton)",
        (toggle["saved_attribute_attributes"]["valueof"]["parameter_enum"], toggle["text"], toggle["texton"]),
        (["val1", "val2"], "lens", "field"))
    menus = {b["saved_attribute_attributes"]["valueof"]["parameter_longname"]: (b.get("varname"), b["saved_attribute_attributes"]["valueof"]["parameter_mmax"])
             for b in top.values() if b["maxclass"] == "live.menu" and "range_" in b["saved_attribute_attributes"]["valueof"]["parameter_longname"]}
    _eq("the range menus carry Max's auto names and item-count mmax",
        menus, {"range_aberration": ("live.menu", 2), "range_distortion": ("live.menu[1]", 1),
                "range_transmission": ("live.menu[2]", 1), "range_ghost_spacing": ("live.menu[3]", 1)})


if __name__ == "__main__":
    sys.exit(run(globals()))
