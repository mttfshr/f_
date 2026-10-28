"""test_cmap_static.py -- static guards for the f_cmap build (tasks T020/T021): what an offline run CAN verify about the
codeboxes, the definition and the built patcher (GenExpr itself only compiles in Max: bench_cmap.py).

  1  every codebox Param default equals the definition's default (the module-contract default_mismatch check)
  2  every pix-wired control and every internal param is declared in the primary codebox (an undeclared one answers
     "invalid message")
  3  control tokens avoid jit.gl.pix / Ob3D attribute names and codebox operators (FR-009)
  4  forbidden constructs absent (jit-gen-codebox skill): stored-variable component access, Param t / texture /
     bypass, unary minus before a parenthesis, bare `sample(in2` (FR-011: the history is read from nearest() taps)
  5  the positional ids the definition's raw wiring hard-codes match the built patcher

Run:  tests/run.sh -q tests/modules/cmap/test_cmap_static.py   (the built patcher must be current:
      build/py.sh build/build_patcher.py src/f_cmap/definition.py)
"""
import importlib.util
import json
import os
import re

from harness import note, run  # noqa: E402

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
SRC = os.path.join(REPO, "src", "f_cmap")
GEN = ["codebox_cmap.gen", "codebox_cmap_pass.gen"]

# jit.gl.pix is an Ob3D: these attributes exist on it, so a control with the same token binds to the attribute
OB3D = {"scale", "position", "rotate", "quat", "anchor", "color", "blend", "depth", "texture", "name", "drawto",
        "visible", "enable", "lighting_enable", "dim", "type", "adapt", "bypass", "active", "output", "mode"}
OPERATORS = {"mix", "step", "clamp", "smoothstep", "sample", "wrap", "mod", "fold", "min", "max", "abs", "sign",
             "pow", "exp", "log", "floor", "fract", "sqrt", "cos", "sin", "tan", "norm", "snorm", "cell", "dim"}


def _definition():
    spec = importlib.util.spec_from_file_location("cmap_definition", os.path.join(SRC, "definition.py"))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def _code(name):
    return "\n".join(ln.split("//")[0] for ln in open(os.path.join(SRC, name)).read().splitlines())


def _params(code):
    return {m.group(1): float(m.group(2)) for m in re.finditer(r"Param\s+(\w+)\s*\(\s*([-0-9.e]+)\s*\)", code)}


def test_codebox_defaults_match_definition():
    d = _definition()
    got = _params(_code("codebox_cmap.gen"))
    for p in d.patcher["params"]:
        if p["type"] in ("float", "int", "menu") and p.get("pix_wire") is not False:
            assert p["name"] in got, f"{p['name']} is not declared in the primary codebox"
            assert abs(got[p["name"]] - float(p["default"])) < 1e-9, (p["name"], got[p["name"]], p["default"])
    note("declared Params", sorted(got))


def test_every_driven_param_is_declared():
    d = _definition()
    got = _params(_code("codebox_cmap.gen"))
    for p in d.patcher["params"]:
        if p["type"] == "internal":
            assert p["name"] in got, f"internal param {p['name']} is not declared (it would answer 'invalid message')"
    for tok in ("freeze_on", "bypass_gate", "reseed", "theta_clk", "phase_clk"):
        assert tok in got, tok


def test_control_tokens_are_safe():
    d = _definition()
    names = {p["name"] for p in d.patcher["params"] if p["type"] != "bypass"}
    bad = names & (OB3D | OPERATORS)
    assert not bad, f"control tokens collide with jit.gl.pix attributes or operators: {bad}"
    assert "t" not in names and "texture" not in names


def test_forbidden_constructs_absent():
    bad = []
    for name in GEN:
        code = _code(name)
        for pat, why in ((r"Param\s+(texture|bypass|t)\s*\(", "Param named texture / bypass / t"),
                         (r"[=(,]\s*-\s*\(", "unary minus before a parenthesis"),
                         (r"\b(sx|sy|sz|sv|res|hv|held|th|mag)\.[xyzwrgba]\b", "component access on a stored variable"),
                         (r"\bin[0-9]\s*=", "variable named in<digit>"),
                         (r"\b(cell|active|dim|norm)\s*=", "variable shadows a coordinate operator"),
                         (r"sample\(\s*in2", "history read by a bare sample() (FR-011)"),
                         (r"\bnoise\s*\(", "noise() is black on the GPU")):
            if re.search(pat, code):
                bad.append(f"{name}: {why}")
    assert not bad, bad


def _built():
    return json.load(open(os.path.join(REPO, "package", "patchers", "f_cmap.maxpat")))["patcher"]


def test_positional_ids_match_built_patcher():
    pb = _built()
    boxes = {b["box"]["id"]: b["box"] for b in pb["boxes"]}
    d = _definition()
    assert "#0_cmap_pix" in boxes["obj-5"].get("text", ""), boxes["obj-5"].get("text")
    assert "#0_cmap_pass" in boxes["obj-50"].get("text", ""), boxes["obj-50"].get("text")
    route = boxes["obj-4"]["text"].split()
    assert route[0] == "route" and route[-1] == "reset", route
    assert route[1:-1] == ["decay", "inject", "radius", "sweep", "rate", "angle", "lscale", "pwr", "edge", "freeze_on"], route
    assert boxes[d._dial("rate")].get("varname") == "rate", boxes[d._dial("rate")].get("varname")
    lines = [ln["patchline"] for ln in pb["lines"]]
    pairs = {(pl["source"][0], pl["source"][1], pl["destination"][0], pl["destination"][1]) for pl in lines}
    assert ("obj-4", d._N_CONTROLS + d._N_HEADER, "obj-raw-15", 0) in pairs, "reset must leave the route's last outlet"
    for dst in ("obj-raw-3", "obj-raw-10"):
        assert (d._dial("rate"), 0, dst, 0 if dst == "obj-raw-10" else 1) in pairs, f"the rate dial must reach {dst}"
    for raw in ("obj-raw-5", "obj-raw-9", "obj-raw-16", "obj-raw-22"):
        assert (raw, 0, "obj-5", 0) in pairs, f"{raw} must reach the primary pix"
    # the feedback loop
    assert ("obj-5", 0, "obj-50", 0) in pairs and ("obj-50", 0, "obj-5", 1) in pairs, "state -> pass -> state in2"
    note("wired", f"{len(pairs)} lines; controls={d._N_CONTROLS}")


if __name__ == "__main__":
    import sys
    sys.exit(run(globals()))
