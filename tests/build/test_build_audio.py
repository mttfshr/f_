"""
test_build_audio.py -- the audio archetypes of the builder (build/spec.md "Audio archetypes"; f_a_ripple, 2026-11-16).

Every src/*/definition.py with an `audio_*` archetype is built through build_audio() and checked offline:

  - it builds, and the result is valid JSON that round-trips
  - every param reaches the core: control -> `prepend <name>` -> the gen~ box, inlet 0 (and the Bypass
    toggle -> `prepend bypass_gate`), and the gen~ codebox declares `Param <name>(...)` for each; no Param in
    the codebox is left without a control (an orphan)
  - each control's initial value equals the codebox Param's default
  - box ids are unique; every line names real boxes; no texture-archetype objects (route, routepass,
    jit.gl.pix, vs_inState) are present; `outlet~` is present, `inlet~` only when audio_in
  - the checker itself catches mutants: a dropped cord, a renamed prepend, a renamed codebox Param, a duplicate id

Offline only: sound, bypass clicks and the panel's look are for Max (Matt).

    tests/run.sh -q tests/build/test_build_audio.py
"""
import paths as _paths  # noqa: F401
import copy
import json
import re
from pathlib import Path

import build_patcher as bp          # noqa: E402

from harness import check, run      # noqa: E402

REPO = Path(__file__).resolve().parents[2]
TEXTURE_ONLY = ("route", "routepass", "jit.gl.pix", "vs_inState")


def _eq(label, got, want):
    check(label, 0 if got == want else 1, 0)


def audio_definitions():
    out = {}
    for path in sorted((REPO / "src").glob("*/definition.py")):
        d = bp.load_definition(path)
        if str(d.get("archetype", "")).startswith("audio_"):
            out[d["name"]] = d
    return out


def codebox_of(patcher):
    core = next(b["box"] for b in patcher["boxes"] if b["box"].get("text") == "gen~")
    return next(x["box"]["code"] for x in core["patcher"]["boxes"] if "code" in x["box"])


def problems(patcher, defn):
    """Everything wrong with a built audio patcher; [] when it is sound."""
    p = patcher["patcher"] if "patcher" in patcher else patcher
    bad = []
    boxes = {b["box"]["id"]: b["box"] for b in p["boxes"]}
    if len(boxes) != len(p["boxes"]):
        bad.append("duplicate box ids")
    for l in p["lines"]:
        for end in (l["patchline"]["source"][0], l["patchline"]["destination"][0]):
            if end not in boxes:
                bad.append(f"line names missing box {end}")
    core_ids = [i for i, b in boxes.items() if b.get("text") == "gen~"]
    if len(core_ids) != 1:
        return bad + ["expected exactly one gen~"]
    core = core_ids[0]
    code = codebox_of(p)
    declared = dict(re.findall(r"\bParam\s+(\w+)\s*\(\s*([-\d.eE+]+)\s*\)", code))
    texts = " ".join(str(b.get("text", "")) + " " + b.get("maxclass", "") for b in boxes.values())
    for t in TEXTURE_ONLY:
        if re.search(rf"(^|\s){re.escape(t)}(\s|$)", texts):
            bad.append(f"texture-only object {t} present")
    outs = sorted((b for b in boxes.values() if b.get("text") == "outlet~"), key=lambda b: b["id"])
    want = defn.get("audio_outputs", ["audio out"])
    if len(outs) != len(want):
        bad.append(f"{len(outs)} outlet~ for {len(want)} audio_outputs")
    else:
        xs = [b["patching_rect"][0] for b in outs]
        if xs != sorted(xs) or len(set(xs)) != len(xs):
            bad.append("outlet~ x order is not strictly increasing")
        for i, b in enumerate(outs):
            if b.get("comment") != want[i]:
                bad.append(f"outlet~ {i} comment {b.get('comment')!r} != {want[i]!r}")
            if not any(l["patchline"]["source"] == [core, i] and l["patchline"]["destination"] == [b["id"], 0] for l in p["lines"]):
                bad.append(f"gen~ outlet {i} is not wired to {b['id']}")
    if boxes[core].get("numoutlets") != len(want):
        bad.append("gen~ numoutlets does not match audio_outputs")
    n_assigned = {int(m) for m in re.findall(r"\bout(\d+)\s*=", code)}
    if n_assigned != set(range(1, len(want) + 1)):
        bad.append(f"codebox assigns out{sorted(n_assigned)}, expected 1..{len(want)}")
    has_in = any(b.get("text") == "inlet~" for b in boxes.values())
    if has_in != bool(defn.get("audio_in", False)):
        bad.append("inlet~ does not match audio_in")
    by_var = {b.get("varname"): (i, b) for i, b in boxes.items() if b.get("varname")}
    wired = set()
    names = [q["name"] for q in defn["params"]] + ["bypass"]
    for n in names:
        gate = "bypass_gate" if n == "bypass" else n
        if gate not in declared:
            bad.append(f"codebox has no Param {gate}")
        ctl = by_var.get(n)
        if ctl is None:
            bad.append(f"no control named {n}")
            continue
        cid, cbox = ctl
        pre = [i for i, b in boxes.items() if b.get("text") == f"prepend {gate}"]
        ok = (len(pre) == 1
              and any(l["patchline"]["source"] == [cid, 0] and l["patchline"]["destination"] == [pre[0], 0] for l in p["lines"])
              and any(l["patchline"]["source"] == [pre[0], 0] and l["patchline"]["destination"] == [core, 0] for l in p["lines"]))
        if not ok:
            bad.append(f"{n}: not wired control -> prepend {gate} -> gen~ inlet 0")
        wired.add(gate)
        init = cbox["saved_attribute_attributes"]["valueof"]["parameter_initial"][0]
        if gate in declared and float(declared[gate]) != float(init):
            bad.append(f"{n}: control initial {init} != codebox default {declared[gate]}")
        if cbox.get("param_connect"):
            bad.append(f"{n}: has a param_connect (that names a jit.gl.pix)")
    for orphan in sorted(set(declared) - wired):
        bad.append(f"codebox Param {orphan} has no control")
    return bad


def test_every_audio_definition_builds_and_wires():
    defs = audio_definitions()
    check("at least one audio definition exists (f_a_ripple)", 0 if "f_a_ripple" in defs else 1, 0)
    for name, d in defs.items():
        built = bp.build(d)
        again = json.loads(json.dumps(built))
        _eq(f"{name}: JSON round-trips", again, built)
        _eq(f"{name}: sound", problems(built, d), [])
        _eq(f"{name}: openinpresentation", built["patcher"]["openinpresentation"], 1)


def test_purr_ports_and_mutants():
    """f_a_purr: an inlet~ (breath phase) and two outlet~ (purr, breath phase); the port checks catch mutants."""
    d = audio_definitions().get("f_a_purr")
    check("f_a_purr has an audio definition", 0 if d else 1, 0)
    good = json.loads(json.dumps(bp.build(d)))
    _eq("f_a_purr: two outlet~, one inlet~", sorted(b["box"]["text"] for b in good["patcher"]["boxes"]
                                                    if b["box"].get("text", "").endswith("~") and b["box"]["text"] != "gen~"),
        ["inlet~", "outlet~", "outlet~"])

    def mutant(fn):
        m = copy.deepcopy(good)
        fn(m["patcher"])
        return problems(m, d)

    def swap_x(p):
        o = [b["box"] for b in p["boxes"] if b["box"].get("text") == "outlet~"]
        o[0]["patching_rect"][0], o[1]["patching_rect"][0] = o[1]["patching_rect"][0], o[0]["patching_rect"][0]
    check("mutant: reversed outlet~ order is caught", 0 if mutant(swap_x) else 1, 0)
    check("mutant: a missing second outlet~ is caught",
          0 if mutant(lambda p: p["boxes"].remove(next(b for b in p["boxes"] if b["box"]["id"] == "obj-201"))) else 1, 0)
    check("mutant: the breath phase outlet unwired is caught",
          0 if mutant(lambda p: p["lines"].remove(next(l for l in p["lines"] if l["patchline"]["destination"] == ["obj-201", 0]))) else 1, 0)
    dd = copy.deepcopy(d)
    dd["audio_outputs"] = ["purr"]
    try:
        bp.build(dd)
        raised = False
    except ValueError as e:
        raised = "audio_outputs has 1 entries" in str(e)
    check("loud: out2 assigned but one audio output declared", 0 if raised else 1, 0)


def test_shipped_patcher_matches_the_build():
    """The shipped patcher of each audio module is its build (Max owns it afterwards; this catches a stale build)."""
    for name, d in audio_definitions().items():
        shipped = json.load(open(REPO / "package" / "patchers" / f"{name}.maxpat"))
        _eq(f"{name}: shipped file is the build", shipped, json.loads(json.dumps(bp.build(d))))


def test_checker_catches_mutants():
    d = audio_definitions()["f_a_ripple"]
    good = json.loads(json.dumps(bp.build(d)))

    def mutant(fn):
        m = copy.deepcopy(good)
        fn(m["patcher"])
        return problems(m, d)

    check("mutant: a dropped cord is caught",
          0 if mutant(lambda p: p["lines"].pop(next(i for i, l in enumerate(p["lines"])
                                                    if l["patchline"]["source"] == ["obj-21", 0]
                                                    and l["patchline"]["destination"] == ["obj-3", 0]))) else 1, 0)

    def rename_prepend(p):
        next(b["box"] for b in p["boxes"] if b["box"].get("text") == "prepend depth")["text"] = "prepend dept"
    check("mutant: a renamed prepend is caught", 0 if mutant(rename_prepend) else 1, 0)

    def rename_param(p):
        core = next(b["box"] for b in p["boxes"] if b["box"].get("text") == "gen~")
        cb = next(x["box"] for x in core["patcher"]["boxes"] if "code" in x["box"])
        cb["code"] = cb["code"].replace("Param tmr(", "Param tmrx(")
    check("mutant: a renamed codebox Param is caught", 0 if mutant(rename_param) else 1, 0)
    check("mutant: a duplicate id is caught", 0 if mutant(lambda p: p["boxes"].append(copy.deepcopy(p["boxes"][0]))) else 1, 0)
    check("mutant: a texture object is caught",
          0 if mutant(lambda p: p["boxes"].append({"box": {"id": "obj-999", "maxclass": "newobj", "text": "routepass"}})) else 1, 0)
    check("mutant: a changed default is caught",
          0 if mutant(lambda p: next(b["box"] for b in p["boxes"] if b["box"].get("varname") == "depth")
                      ["saved_attribute_attributes"]["valueof"]["parameter_initial"].__setitem__(0, 0.25)) else 1, 0)


def test_build_is_loud_on_misuse():
    d = audio_definitions()["f_a_ripple"]

    def raises(over, needle):
        dd = copy.deepcopy(d)
        dd.update(over)
        try:
            bp.build(dd)
        except ValueError as e:
            return needle in str(e)
        return False

    _eq("loud: a codebox without bypass_gate", raises({"codebox": d["codebox"].replace("Param bypass_gate(0.0);", "")}, "bypass_gate"), True)
    _eq("loud: a param the codebox lacks", raises({"params": d["params"] + [{"name": "nope", "type": "float", "min": 0, "max": 1, "default": 0}]}, "no `Param nope"), True)
    _eq("loud: audio_pfft is not built yet", raises({"archetype": "audio_pfft"}, "not built yet"), True)
    _eq("loud: overrides are unsupported", raises({"overrides": {"panel": {"x": 1}}}, "not supported"), True)
    _eq("loud: bypass_gate listed as a param", raises({"params": d["params"] + [{"name": "bypass_gate", "type": "float", "min": 0, "max": 1, "default": 0}]}, "shell's bypass"), True)


def test_texture_path_is_untouched():
    """A texture definition does not enter build_audio()."""
    d = bp.load_definition(REPO / "src" / "f_stipple" / "definition.py")
    _eq("texture build has a jit.gl.pix", any("jit.gl.pix" in str(b["box"].get("text", "")) for b in bp.build(d)["patcher"]["boxes"]), True)


if __name__ == "__main__":
    import sys
    sys.exit(run(globals()))
