"""test_fc_codebox_static.py -- static guards for the f_formconstants PARITY build
(tasks T043/T044): things an offline run CAN verify about the codeboxes and the
built patcher, since GenExpr itself only compiles in Max (T046).

  1  every codebox's Param `n` default equals the definition's solver @dim (S1) -- the
     texel grid is never the gen `dim` global
  2  the blur literals in codebox_blur_x/y.gen equal fc_parity_mirror.half_kernel()
  3  forbidden constructs (jit-gen-codebox skill / the Revision 2 agent brief) are absent
  4  the positional object ids the definition's raw wiring hard-codes match the built patcher
  5  no solver stage is wired to `r dim`; enc is

Run:  tests/run.sh -q tests/modules/formconstants/test_fc_codebox_static.py
"""
import importlib.util
import json
import os
import re
from pathlib import Path

import numpy as np

from harness import check, note, run  # noqa: E402
import fc_parity_mirror as m  # noqa: E402

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
SRC = os.path.join(REPO, "src", "f_formconstants")
GEN = ["codebox_seed.gen", "codebox_pass.gen", "codebox_blur_x.gen", "codebox_blur_y.gen",
       "codebox_nl.gen", "codebox_enc.gen"]


def _definition():
    spec = importlib.util.spec_from_file_location("fc_definition", os.path.join(SRC, "definition.py"))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def _code(name):
    """The file's code lines with // comments stripped."""
    out = []
    for ln in open(os.path.join(SRC, name)).read().splitlines():
        out.append(ln.split("//")[0])
    return "\n".join(out)


def test_grid_param_matches_solver_dim():
    d = _definition()
    for name in ("codebox_seed.gen", "codebox_blur_x.gen", "codebox_blur_y.gen", "codebox_enc.gen"):
        mt = re.search(r"Param\s+n\s*\(\s*([0-9.]+)\s*\)", _code(name))
        assert mt, f"{name}: no Param n"
        check(f"{name} Param n default vs SOLVER_N", abs(float(mt.group(1)) - d.SOLVER_N), 0.0)
    for node in d.patcher["pix_chain"]:
        if node["id"] in ("hold", "seed", "pass", "blurx", "blury", "nl"):
            assert f"@dim {d.SOLVER_N} {d.SOLVER_N}" in node["pix_attrs"], node["id"]
            assert "@adapt 0" in node["pix_attrs"], node["id"]


def test_blur_literals_match_mirror():
    hk = m.half_kernel()
    wa = [float(hk[i, 0]) for i in range(m.RADIUS + 1)]
    wb = [float(hk[i, 1]) for i in range(m.RADIUS + 1)]
    for name in ("codebox_blur_x.gen", "codebox_blur_y.gen"):
        code = _code(name)
        num = r"([0-9.]+(?:e-?[0-9]+)?)"
        got_a, got_b = [None] * 7, [None] * 7
        mt = re.search(r"ar = t0\.x \* " + num + r"; ag = t0\.y \* " + num + r";", code)
        got_a[0], got_b[0] = float(mt.group(1)), float(mt.group(2))
        for k in range(1, 7):
            mt = re.search(rf"ar = ar \+ \(tp{k}\.x \+ tn{k}\.x\) \* {num}; ag = ag \+ \(tp{k}\.y \+ tn{k}\.y\) \* {num};", code)
            assert mt, f"{name}: tap {k} not found"
            got_a[k], got_b[k] = float(mt.group(1)), float(mt.group(2))
        worst = max(max(abs(a - b) / b for a, b in zip(got_a, wa)),
                    max(abs(a - b) / b for a, b in zip(got_b, wb)))
        check(f"{name} weights vs half_kernel (relative)", worst, 1e-7)
        for k in range(1, 7):                       # the B and A channels reuse the sigma = 1 weights
            assert re.search(rf"ab = ab \+ \(tp{k}\.z \+ tn{k}\.z\) \* {re.escape(str(got_a[k]))}", code) or \
                   f"(tp{k}.z + tn{k}.z) * " in code
        note(f"{name} taps", "7 weights x 2 sigmas verified")


def test_forbidden_constructs_absent():
    bad = []
    for name in GEN:
        code = _code(name)
        for pat, why in ((r"\bdim\b", "gen `dim` global"),
                         (r"nearestpix", "nearestpix with normalized coords"),
                         (r"Param\s+(texture|bypass)\s*\(", "Param named texture/bypass"),
                         (r"Param\s+t\s*\(", "Param named t (never applied by jit.gl.pix; probed 2026-10-24)"),
                         (r"^\s*(e|phi)\s*=", "variable named e/phi"),
                         (r"[=(,]\s*-\s*\(", "unary minus before a parenthesis"),
                         (r"\bsin\s*\(", "sin() in a hash")):
            if why == "sin() in a hash" and "seed" not in name:
                continue        # the hash lives in seed only; nl's T073 Screen map uses sin/cos for geometry
            if re.search(pat, code, re.M):
                bad.append(f"{name}: {why}")
    assert not bad, bad


def _built():
    p = os.path.join(REPO, "package", "patchers", "f_formconstants.maxpat")
    return json.load(open(p))["patcher"]


def _defn():
    """The definition module (its derived _SUP / _N_CONTROLS are what the raw wiring uses)."""
    import importlib.util
    spec = importlib.util.spec_from_file_location(
        "fc_definition", str(Path(__file__).resolve().parents[3] / "src" / "f_formconstants" / "definition.py"))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def _solver_ids():
    d = _defn()
    return [f"obj-{d._SUP + k}" for k in range(6)]


def test_positional_ids_match_built_patcher():
    boxes = {b["box"]["id"]: b["box"] for b in _built()["boxes"]}
    d = _defn()
    names = ["#0_fc_hold", "#0_fc_seed", "#0_fc_pass", "#0_fc_blurx", "#0_fc_blury", "#0_fc_nl"]
    want = dict(zip(names, _solver_ids()))
    want["#0_fc_enc"] = "obj-5"
    note("support-stage base (_SUP) / controls", f"{d._SUP} / {d._N_CONTROLS}")
    for name, oid in want.items():
        box = boxes.get(oid)
        assert box is not None and name in box.get("text", ""), f"{name} is not {oid}: {box and box.get('text')}"
    route = boxes.get("obj-4")
    # T061/T060: the dials' and the menu's tokens come first, so `reset` is the route's last outlet (definition raw_lines)
    assert route and route["text"].split() == ["route", "pulse_depth", "pulse_period", "out_mode", "freeze_on", "sim_rate", "pulse_mix", "pulse_gain", "grain_scale", "pulse_space", "out_view", "reset"], route and route.get("text")
    resets = [ln["patchline"] for ln in _built()["lines"]
              if ln["patchline"]["source"][0] == "obj-4" and ln["patchline"]["destination"][0] == "obj-raw-3"]
    assert [pl["source"][1] for pl in resets] == [d._N_CONTROLS], f"reset must leave the route's last outlet: {resets}"


def test_pulse_inlet_reaches_nl():
    """T061: the pulse mod inlet -> vs_inState -> nl in 3; the connection flag -> param pulse_conn -> nl."""
    pb = _built()
    boxes = {b["box"]["id"]: b["box"] for b in pb["boxes"]}
    into_nl = {(pl["source"][0], pl["destination"][1]) for pl in (ln["patchline"] for ln in pb["lines"])
               if pl["destination"][0] == _solver_ids()[5]}
    srcs = {boxes[s].get("text", ""): i for s, i in into_nl}
    assert srcs.get("vs_inState") == 2, f"pulse texture must reach nl inlet 2 (in3): {srcs}"
    assert srcs.get("prepend param pulse_conn") == 0, f"pulse_conn flag must reach nl: {srcs}"


def test_r_dim_reaches_enc_only():
    """S1: no `dim` message reaches a solver stage (its @dim never follows the window). T073: only the
    output-size PARAMS (prepend param ow / oh) may reach nl, for the Screen pulse."""
    pb = _built()
    boxes = {b["box"]["id"]: b["box"] for b in pb["boxes"]}
    rdim = [i for i, b in boxes.items() if b.get("text") == "r dim"]
    assert len(rdim) == 1, rdim
    sinks = set()
    for ln in pb["lines"]:
        pl = ln["patchline"]
        if pl["source"][0] == rdim[0]:
            sinks.add(pl["destination"][0])
    solver = set(_solver_ids())
    assert not (sinks & solver), f"r dim reaches solver stages: {sinks & solver}"
    assert "obj-5" in sinks, "r dim must reach enc"
    into_solver = {(boxes[pl["source"][0]].get("text", ""), pl["destination"][0])
                   for pl in (ln["patchline"] for ln in pb["lines"])
                   if pl["destination"][0] in solver and pl["source"][0] in boxes}
    dimish = {t for t, _ in into_solver if t in ("r dim", "route dim", "unpack")}
    assert not dimish, f"a dim message reaches a solver stage: {dimish}"
    for t in ("prepend param ow", "prepend param oh"):
        assert (t, _solver_ids()[5]) in into_solver, f"T073: {t} must reach nl"
    note("r dim sinks", sorted(sinks))


if __name__ == "__main__":
    import sys
    sys.exit(run(globals()))
