"""
test_immiscible_static.py -- static guards for the f_vf_immiscible codeboxes (tasks T014): what an offline
run CAN verify about src/f_vf_immiscible/*.gen without Max. The GPU agreement with the mirror is
bench_immiscible.py (T016); this file stops the cheap, silent mistakes (bench-verified GenExpr traps, a
forbidden Param name, the two blend copies drifting, constants changed in one place only).

Run:  tests/run.sh -q tests/modules/immiscible/test_immiscible_static.py
"""
import importlib.util
import re
import sys
from pathlib import Path

from harness import check, run
import immiscible_mirror as im

SRC = Path(__file__).resolve().parents[3] / "src" / "f_vf_immiscible"
STAGES = ["inab", "pass", "adv", "spec", "enc"]
DFT = ["dft_fx", "dft_fy", "dft_iy", "dft_ix"]
def say(msg):
    print("  " + msg)


FORBIDDEN = {"texture", "t", "depth", "mix", "bypass", "dim"}      # FR-012


def text(name):
    return (SRC / f"codebox_{name}.gen").read_text()


def code(name):
    return [l for l in text(name).split("\n") if l.strip() and not l.lstrip().startswith("//")]


def load(name):
    spec = importlib.util.spec_from_file_location(name, SRC / f"{name}.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def test_every_stage_has_at_most_three_inputs():
    worst = 0
    for n in STAGES + DFT:
        ins = {int(m) for m in re.findall(r"\bin(\d+)\b", "\n".join(code(n)))}
        worst = max(worst, max(ins, default=0))
        say(f"{n}: inputs {sorted(ins)}")
    check("highest input index used minus 3 (bench covers at most three)", max(0, worst - 3), 0)


def test_no_forbidden_param_names():
    bad = 0
    for n in STAGES + DFT:
        for p in re.findall(r"^Param\s+(\w+)\s*\(", text(n), re.M):
            if p in FORBIDDEN:
                bad += 1
                say(f"{n}: forbidden Param {p}")
    check("forbidden Param names (FR-012)", bad, 0)


def test_generated_files_are_current():
    dft, blend = load("gen_dft"), load("gen_blend")
    fluid = dft._load_fluid()
    stale = 0
    for key in dft.STAGE_NO:
        name, want = dft.render(fluid, key)
        stale += (SRC / name).read_text() != want
    for name, want in blend.render().items():
        stale += (SRC / name).read_text() != want
    check("generated codeboxes that differ from their generator (run gen_dft.py / gen_blend.py)", stale, 0)


def test_blend_block_identical_in_adv_and_enc():
    def block(n):
        m = re.search(r"// ---- blend begin.*?// ---- blend end ----", text(n), re.S)
        return m.group(0) if m else None
    a, e = block("adv"), block("enc")
    check("blend block present in adv and enc", 0 if a and e else 1, 0)
    check("the two blend copies differ", 0 if a == e else 1, 0)


def test_N_literal_only_where_expected():
    bad = 0
    for n in STAGES:
        lits = sum(l.count("256") for l in code(n))
        assigned = sum(l.strip() == "N = 256;" for l in code(n))
        say(f"{n}: 256 literals {lits}, N = 256 assignments {assigned}")
        bad += (assigned != 1) or (lits != 1)
    for n in DFT:                                    # the fluid rule: twice (assignment and loop bound)
        bad += sum(l.count("256") for l in code(n)) != 2
    check("stages whose N = 256 literal count is off", bad, 0)


def test_no_sin_noise_or_unary_minus_traps():
    bad = 0
    for n in STAGES:
        for l in code(n):
            if re.search(r"\bsin\s*\(|\bnoise\s*\(", l):
                bad += 1
                say(f"{n}: {l.strip()}")
    for n in STAGES + DFT:
        for l in code(n):
            if re.search(r"[=(,]\s*-\s*\(", l):               # unary minus before a parenthesis mis-parses
                bad += 1
                say(f"{n}: unary minus before ( : {l.strip()}")
            if re.match(r"\s*(e|phi)\s*=", l):                  # predefined constants
                bad += 1
                say(f"{n}: variable named e or phi: {l.strip()}")
    check("sin()/noise() in non-DFT stages, unary-minus-parenthesis, e/phi names", bad, 0)


def test_non_finite_guard_form_and_no_zero_heal():
    pas = "\n".join(code("pass"))
    ixs = "\n".join(code("dft_ix"))
    check("pass guards the feedback with abs(x) < 1e30", 0 if "abs(fb) < 1e30" in pas else 1, 0)
    check("ix guards with abs(x) < 1e30", 0 if "< 1e30" in ixs else 1, 0)
    check("pass has no exact-zero heal (FR-010: uniform phi = +-1 is legitimate)", 1 if re.search(r"fb\s*==\s*0", pas) else 0, 0)
    check("pass selects with switch(), not mix()", 1 if "mix(" in pas else 0, 0)


def test_constants_match_the_mirror():
    spec, adv, pas = text("spec"), text("adv"), text("pass")
    bad = []
    if not (im.MDT_MAX == 0.1 and im.MDT_EXP == 3 and "0.1 * coarsen * coarsen * coarsen" in spec):
        bad.append("MDT_MAX / MDT_EXP")
    if not (im.A_STAB == 1.5 and "(1.5 + kappa * k2)" in spec and "x * 2.5" in spec):
        bad.append("A_STAB (a and a + 1)")
    if not (im.PHI_CLAMP == 1.25 and "clamp(newp, -1.25, 1.25)" in adv):
        bad.append("PHI_CLAMP")
    if not (im.THRESH_W == 0.15 and "(luma - thresh) / 0.15" in adv):
        bad.append("THRESH_W")
    if not (im.PULL_MAX == 0.05 and "pulle = 0.05 * pull * pull * pull" in spec):
        bad.append("PULL_MAX")
    if not (im.RESEED_AMP == 0.05 and "amp = 0.05;" in pas):
        bad.append("RESEED_AMP")
    if not (im.N_SOLVER == 256):
        bad.append("N_SOLVER")
    for b in bad:
        say(f"constant out of step with the mirror: {b}")
    check("constants out of step between mirror and codebox", len(bad), 0)


def test_stage_params_are_the_planned_ones():
    want = {"inab": {"taps", "src_a", "src_b"}, "pass": {"reseed", "salt", "fill"},
            "adv": {"dt", "inject", "thresh", "taps", "freeze", "src_phi"},
            "spec": {"iface", "coarsen", "freeze", "pull", "fill"},
            "enc": {"bypass_gate"}}
    bad = 0
    for n, w in want.items():
        got = set(re.findall(r"^Param\s+(\w+)\s*\(", text(n), re.M))
        if got != w:
            bad += 1
            say(f"{n}: Params {sorted(got)} != planned {sorted(w)}")
    check("stages whose Params differ from the plan", bad, 0)


if __name__ == "__main__":
    sys.exit(run(globals()))
