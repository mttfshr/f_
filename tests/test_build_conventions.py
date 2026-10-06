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
  - `route_bypass`: `bypass` is the first `route` token, wired to the bypass jsui, and every param
    outlet is one higher; off (the default) changes nothing (T014)

    tests/run.sh tests/test_build_conventions.py
"""
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


if __name__ == "__main__":
    sys.exit(run(globals()))
