"""
test_module_contracts.py -- offline contract check of every shipped f_
bpatcher (.specify/test_bench/tasks_extensions.md T101). No Max needed.

For each module: every `route` name reaches an attrui; every attrui
attribute exists on the pix it drives (a codebox Param or a built-in
jit.gl.pix attribute); no route name that is itself a Param is wired to a
*different* attribute (cross-wiring). Per jit.gl.pix (all stages of a
multi-stage module, not just the first): every codebox Param has a driver and
is actually read, a pix without a codebox is a pure in->out identity pass, and
every gen `in N` / `out N` has a cord on the pix. (These last checks were
ported from the retired build/audit_interface.py.)

Known, recorded issues are reported as XFAIL with a pointer instead of
failing the suite; if one starts passing it reports XPASS -- remove it from
KNOWN_ISSUES then. Anything not listed fails.

Run:  tests/run.sh tests/test_module_contracts.py
"""
import sys
from collections import defaultdict

from harness import check, run
from module_contract import Module, shipped_modules, pix_params

# Modules whose control structure isn't route -> attrui -> pix Param.
NOT_APPLICABLE = {
    "f_a_ripple": "gen~ audio, no jit.gl.pix",
    "f_chladni_audio": "audio companion patch, no jit.gl.pix",
    "f_modules": "module menu, no jit.gl.pix",
    "f_texrouter": "texture routing utility; routes drive routing logic, not pix Params",
    "f_util_matrix_2": "modulation-routing utility (draft); routes go to js",
    "f_util_profile": "CPU-side profiler; routes drive jit/js objects, not pix Params",
}

# (module, kind, detail) -> pointer to where it's recorded.
# undriven / unused details are "<pix name>.<param>".
_SEEDS_NOTE = ("documented in the shipped codebox header: active_blend/sentinel are live "
               "Params in both search stages, only stage 1b's active_blend is wired (to `bomb`); "
               ".specify/stable/f_vf_seeds/plan.md addendum on active_blend")
_MASONRY_NOTE = ("dead mod-matrix cell: declared, never read by the codebox (the phantom cells "
                 "noted in .specify/plan.md 'Infrastructure: f_util_matrix' and "
                 "ideas/f_util_mod_texture.md); resolves with the mod-texture convention decision")
KNOWN_ISSUES = {
    ("f_vf_seeds", "undriven", "vfseeds_search_a.active_blend"): _SEEDS_NOTE,
    ("f_vf_seeds", "undriven", "vfseeds_search_a.sentinel"): _SEEDS_NOTE,
    ("f_vf_seeds", "undriven", "vfseeds_search_b.sentinel"): _SEEDS_NOTE,
    ("f_vf_optical_flow", "unused", "#0_of_stage_a.bypass"):
        "documented in src/f_vf_optical_flow/codebox_stage_a.gen's header: Param bypass is "
        "declared but unused; this stage stays live under bypass by design "
        "(plan.md, 'Bypassed multi-stage modules keep running')",
}
for _p in ("drift", "phase", "regularity", "skip", "speed_var"):
    KNOWN_ISSUES[("f_masonry", "unused", f"masonry_pix.{_p}_mod_amt_a")] = _MASONRY_NOTE

_seen_known = set()


def _issues(report, pix_param_union):
    issues = []
    for name in report["unrouted"]:
        issues.append(("unrouted", name))
    for b in report["bad_attr"]:
        issues.append(("bad_attr", b["attr"]))
    for name, attrs in report["route_map"].items():
        if name in pix_param_union and name not in attrs:
            issues.append(("cross_wired", name))
    for kind in ("undriven", "unused"):
        for d in report[kind]:
            issues.append((kind, f"{d['pix']}.{d['param']}"))
    for nm in report["no_codebox"]:
        issues.append(("no_codebox", nm))
    for gap in report["port_gaps"]:
        issues.append(("port_gap", gap))
    return sorted(set(issues))


def _check_module(path):
    m = Module(path)
    r = m.analyze()
    union = set().union(*[pix_params(b) for b in m.pix().values()]) if m.pix() else set()
    unexpected = []
    for kind, detail in _issues(r, union):
        key = (r["module"], kind, detail)
        if key in KNOWN_ISSUES:
            _seen_known.add(key)
            print(f"    XFAIL {r['module']} {kind} '{detail}': {KNOWN_ISSUES[key]}")
        else:
            unexpected.append(f"{kind} '{detail}'")
    return r, unexpected


def test_all_modules_contract():
    bad = []
    checked = 0
    for path in shipped_modules():
        name = path.stem
        if name in NOT_APPLICABLE:
            print(f"    n/a   {name}: {NOT_APPLICABLE[name]}")
            continue
        if name.endswith("_version"):
            print(f"    skip  {name}: archived version file")
            continue
        r, unexpected = _check_module(path)
        checked += 1
        if unexpected:
            bad.append(f"{name}: {', '.join(unexpected)}")
            print(f"    BAD   {name}: {', '.join(unexpected)}")
    print(f"    ({checked} modules checked)")
    check("modules with unexpected contract issues", len(bad), 0)


def test_known_issues_still_present():
    """XPASS detector: a KNOWN_ISSUES entry that no longer occurs means it was
    fixed -- remove it so the suite guards against regressions."""
    if not _seen_known:
        for path in shipped_modules():
            if path.stem not in NOT_APPLICABLE and not path.stem.endswith("_version"):
                _check_module(path)
    gone = sorted(set(KNOWN_ISSUES) - _seen_known)
    for key in gone:
        print(f"    XPASS {key}: no longer occurs -- remove from KNOWN_ISSUES")
    check("known issues that now pass (remove them)", len(gone), 0)


def test_checker_catches_the_original_mix_amt_bug():
    """Self-check against the historical bug that motivated this test: a
    control bound to an attribute the codebox doesn't declare."""
    from module_contract import Module as M
    m = M.__new__(M)
    m.name = "synthetic"
    route = {"id": "r", "maxclass": "newobj", "text": "route strength", "numinlets": 1, "numoutlets": 2}
    dial = {"id": "d", "maxclass": "live.dial", "numinlets": 1, "numoutlets": 2}
    attr = {"id": "a", "maxclass": "attrui", "attr": "strength", "numinlets": 1, "numoutlets": 1}
    pix = {"id": "p", "maxclass": "newobj", "text": "jit.gl.pix vsynth @name x_pix", "numinlets": 1,
           "numoutlets": 2, "patcher": {"boxes": [{"box": {"maxclass": "codebox",
                                                           "code": "Param mix_amt(1);\nout1 = in1 * mix_amt;"}}]}}
    m.patcher = {"boxes": [{"box": b} for b in (route, dial, attr, pix)],
                 "lines": [{"patchline": {"source": s, "destination": d}}
                           for s, d in ((["r", 0], ["d", 0]), (["d", 0], ["a", 0]), (["a", 0], ["p", 0]))]}
    from collections import defaultdict
    m.boxes = {b["box"]["id"]: b["box"] for b in m.patcher["boxes"]}
    m.out = defaultdict(list)
    for line in m.patcher["lines"]:
        (s, so), (d, di) = line["patchline"]["source"], line["patchline"]["destination"]
        m.out[(s, so)].append((d, di))
    r = m.analyze()
    check("strength->mix_amt flagged as bad_attr",
          0 if any(b["attr"] == "strength" for b in r["bad_attr"]) else 1, 0)


# ---- synthetic fixtures: each new check must fire on a minimal bad patcher and
# ---- stay quiet on the matching good one (so it can't pass vacuously on the
# ---- shipped modules).

def _box(bid, maxclass="newobj", text="", outlets=1, **kw):
    return {"id": bid, "maxclass": maxclass, "text": text, "numinlets": 1,
            "numoutlets": outlets, **kw}


def _pix(code, gen_extra=(), gen_lines=()):
    """A jit.gl.pix box with an embedded gen patcher. code=None: no codebox."""
    gen = [] if code is None else [{"box": {"id": "cb", "maxclass": "codebox", "code": code}}]
    gen += [{"box": b} for b in gen_extra]
    return {"id": "p", "maxclass": "newobj", "text": "jit.gl.pix vsynth @name x_pix",
            "numinlets": 2, "numoutlets": 2,
            "patcher": {"boxes": gen,
                        "lines": [{"patchline": {"source": [s, so], "destination": [d, di]}}
                                  for s, so, d, di in gen_lines]}}


def _synth(boxes, lines):
    """A Module built from raw box dicts and (src, outlet, dst, inlet) cords."""
    m = Module.__new__(Module)
    m.name = "synthetic"
    m.patcher = {"boxes": [{"box": b} for b in boxes],
                 "lines": [{"patchline": {"source": [s, so], "destination": [d, di]}}
                           for s, so, d, di in lines]}
    m.boxes = {b["id"]: b for b in boxes}
    m.out = defaultdict(list)
    for s, so, d, di in lines:
        m.out[(s, so)].append((d, di))
    return m


def _ids(report, key):
    return sorted(d["param"] if isinstance(d, dict) else d for d in report[key])


GAIN = "Param gain(1);\nout1 = in1 * gain;"


def test_undriven_param_detected_and_each_driver_kind_clears_it():
    pix = _pix(GAIN)
    bare = _synth([pix], []).analyze()
    check("bare Param is undriven", 0 if _ids(bare, "undriven") == ["gain"] else 1, 0)

    prep = _synth([pix, _box("pp", text="prepend param gain")], [("pp", 0, "p", 0)]).analyze()
    check("`prepend param gain` -> pix drives it", len(prep["undriven"]), 0)

    msg = _synth([pix, _box("mm", "message", "param gain 0.5")], [("mm", 0, "p", 0)]).analyze()
    check("`param gain 0.5` message -> pix drives it", len(msg["undriven"]), 0)

    attr = _box("at", "attrui", attr="gain")
    fed = _synth([pix, attr, _box("dl", "live.dial", outlets=2)],
                 [("dl", 0, "at", 0), ("at", 0, "p", 0)]).analyze()
    check("attrui fed by a dial drives it", len(fed["undriven"]), 0)

    inl = _synth([pix, attr, _box("in0", "inlet")],
                 [("in0", 0, "at", 0), ("at", 0, "p", 0)]).analyze()
    check("attrui fed by an inlet drives it", len(inl["undriven"]), 0)

    dangling = _synth([pix, attr], [("at", 0, "p", 0)]).analyze()
    check("an attrui nothing feeds does NOT count as a driver",
          0 if _ids(dangling, "undriven") == ["gain"] else 1, 0)

    shown = _synth([pix, dict(attr, presentation=1)], [("at", 0, "p", 0)]).analyze()
    check("an attrui on the presentation panel is its own control",
          len(shown["undriven"]), 0)

    other = _synth([pix, _box("pp", text="prepend param other")], [("pp", 0, "p", 0)]).analyze()
    check("a driver for a different name does not clear it",
          0 if _ids(other, "undriven") == ["gain"] else 1, 0)

    away = _synth([pix, _box("pp", text="prepend param gain")], []).analyze()
    check("an unconnected `prepend param gain` does not clear it",
          0 if _ids(away, "undriven") == ["gain"] else 1, 0)

    bypass = _synth([_pix("Param bypass(0);\nout1 = in1 * (1 - bypass);")], []).analyze()
    check("Param bypass needs no driver", len(bypass["undriven"]), 0)


def test_mod_handler_drives_only_mod_amt_params_and_only_while_wired():
    pix = _pix("Param foo(1);\nParam foo_mod_amt_a(0);\nout1 = in1 * foo + foo_mod_amt_a;")
    js = _box("js", text="js f_util_mod_handler.js")
    wired = _synth([pix, js], [("js", 0, "p", 0)]).analyze()
    check("handler wired: only the *_mod_amt_* Param is covered",
          0 if _ids(wired, "undriven") == ["foo"] else 1, 0)
    cut = _synth([pix, js], []).analyze()
    check("handler not wired: both flagged",
          0 if _ids(cut, "undriven") == ["foo", "foo_mod_amt_a"] else 1, 0)


def test_unused_param_detected_and_comments_dont_count_as_use():
    used = _synth([_pix(GAIN)], []).analyze()
    check("a read Param is not unused", len(used["unused"]), 0)
    dead = _synth([_pix("Param gain(1);\nout1 = in1;")], []).analyze()
    check("a never-read Param is unused", 0 if _ids(dead, "unused") == ["gain"] else 1, 0)
    cmt = _synth([_pix("Param gain(1);\n// gain is not used here\n/* gain */\nout1 = in1;")], []).analyze()
    check("mentions in comments are not use", 0 if _ids(cmt, "unused") == ["gain"] else 1, 0)
    sub = _synth([_pix("Param gain(1);\nParam gainer(1);\nout1 = in1 * gainer;")], []).analyze()
    check("a longer name does not count as use of a shorter one",
          0 if _ids(sub, "unused") == ["gain"] else 1, 0)


def test_no_codebox_allows_only_a_pure_identity_pass():
    ports = [_box("i1", text="in 1"), _box("o1", text="out 1")]
    ident = _synth([_pix(None, ports, [("i1", 0, "o1", 0)])], []).analyze()
    check("in 1 -> out 1 identity pass is fine", len(ident["no_codebox"]), 0)
    unwired = _synth([_pix(None, ports, [])], []).analyze()
    check("in/out with no cord between them is flagged",
          0 if unwired["no_codebox"] == ["x_pix"] else 1, 0)
    empty = _synth([_pix(None)], []).analyze()
    check("an empty gen is flagged", 0 if empty["no_codebox"] == ["x_pix"] else 1, 0)
    other = _synth([_pix(None, ports + [_box("m", text="* 2")],
                         [("i1", 0, "m", 0), ("m", 0, "o1", 0)])], []).analyze()
    check("a gen that does any processing without a codebox is flagged",
          0 if other["no_codebox"] == ["x_pix"] else 1, 0)


def test_port_gaps_for_unconnected_gen_ports():
    ports = [_box("i1", text="in 1"), _box("i2", text="in 2"), _box("o1", text="out 1")]
    pix = _pix("out1 = in1 + in2;", ports)
    src, sink = _box("src"), _box("sink")
    gap = _synth([pix, src], [("src", 0, "p", 0)]).analyze()
    check("in 2 and out 1 uncabled are both reported",
          0 if gap["port_gaps"] == ["x_pix:in2", "x_pix:out1"] else 1, 0)
    full = _synth([pix, src, sink], [("src", 0, "p", 0), ("src", 0, "p", 1), ("p", 0, "sink", 0)]).analyze()
    check("fully cabled pix has no gaps", len(full["port_gaps"]), 0)


if __name__ == "__main__":
    sys.exit(run(globals()))
