"""
test_bench_expect.py -- offline guard for the live bypass expectations in
tests/bench_modules.py (BYPASS_EXPECT).  No Max needed.

The live bench can only check what the table says, so the table has to be complete and well
formed or a module's bypass goes unchecked without anyone noticing (that was the state of
f_stipple, f_chladni and f_grain until 2026-10-06).  Two things are enforced here:

  1. every entry is valid: a shipped module, an outlet that exists, a known kind of
     expectation, an inlet that exists, a sane tolerance;
  2. every module whose definition declares `bypass_mode: "param"` has an expectation for
     EVERY outlet (a processor's out1 counts as covered by the implicit `in1` default).
     A module moved to Param bypass without extending the table fails here, and so does a
     table that loses an outlet.

Run:  tests/run.sh tests/test_bench_expect.py
"""
import re
import sys
from pathlib import Path

import bench_modules as bm
import modulebench as mb
from harness import check, run
from module_contract import Module, shipped_modules

ROOT = Path(__file__).resolve().parent.parent

# Modules with `bypass_mode: "param"` whose bypass the module bench does not check outlet by outlet,
# with the reason.  A reason is required; an empty dict is the goal.
COVERAGE_EXEMPT = {}


def io(name):
    return mb.module_io(Module(ROOT / "package" / "patchers" / f"{name}.maxpat"))


def problems_in_table(table):
    """Every way an entry of a BYPASS_EXPECT-shaped table can be wrong."""
    shipped = {p.stem for p in shipped_modules()}
    out = []
    for name, outs in table.items():
        if name not in shipped:
            out.append(f"{name}: not a shipped module")
            continue
        n_in, n_out = io(name)
        for k, spec in outs.items():
            where = f"{name} out{k}"
            if not isinstance(k, int) or not 1 <= k <= n_out:
                out.append(f"{where}: the module has {n_out} outlets")
                continue
            kind = spec[0] if isinstance(spec, tuple) and spec else None
            if kind == "in" and len(spec) == 2:
                inlet, tol = spec[1], 0.0
            elif kind == "vec" and len(spec) == 3:
                inlet, tol = spec[1], spec[2]
            elif kind == "const" and len(spec) == 3:
                inlet, tol = None, spec[2]
                if len(spec[1]) != 4:
                    out.append(f"{where}: a const needs 4 channels, got {len(spec[1])}")
            else:
                out.append(f"{where}: unknown or malformed expectation {spec!r}")
                continue
            if inlet is not None and not 1 <= inlet <= n_in:
                out.append(f"{where}: expectation names inlet {inlet}, the module has {n_in}")
            if not tol >= 0:
                out.append(f"{where}: negative tolerance {tol}")
    return out


def param_bypass_modules():
    mods = []
    for d in sorted((ROOT / "src").glob("*/definition.py")):
        if re.search(r'"bypass_mode"\s*:\s*"param"', d.read_text()):
            mods.append(d.parent.name)
    return mods


def uncovered(table, modules):
    """(module, outlet) pairs of `modules` with no expectation, explicit or implicit."""
    out = []
    for name in modules:
        if name in COVERAGE_EXEMPT:
            continue
        _, n_out = io(name)
        covered = set(table.get(name, {}))
        if mb.archetype(name) == "processor" and name not in bm.NEUTRAL_BYPASS_BY_DESIGN:
            covered.add(1)
        out += [(name, k) for k in range(1, n_out + 1) if k not in covered]
    return out


def test_every_table_entry_is_valid():
    bad = problems_in_table(bm.BYPASS_EXPECT)
    for b in bad:
        print("     ", b)
    check("invalid BYPASS_EXPECT entries", len(bad), 0)


def test_every_param_bypass_module_has_every_outlet_covered():
    mods = param_bypass_modules()
    check("modules found with bypass_mode param (sanity: more than 10)", 0 if len(mods) > 10 else 1, 0)
    missing = uncovered(bm.BYPASS_EXPECT, mods)
    for m, k in missing:
        print(f"      {m}: out{k} has no bypass expectation in tests/bench_modules.py BYPASS_EXPECT")
    check("outlets without a bypass expectation", len(missing), 0)


def test_exemptions_carry_a_reason_and_name_a_param_bypass_module():
    mods = set(param_bypass_modules())
    bad = [m for m, why in COVERAGE_EXEMPT.items() if not str(why).strip() or m not in mods]
    check("exemptions without a reason, or for a module not on Param bypass", len(bad), 0)


# ---- the checks must detect what they claim to (mutation checks, offline)

def test_detects_an_outlet_that_does_not_exist():
    t = {"f_grain": {1: bm.IN1, 2: bm.IN1, 3: bm.IN1, 4: bm.IN1}}
    check("an outlet past n_out is reported", 0 if len(problems_in_table(t)) == 1 else 1, 0)


def test_detects_an_unknown_kind_a_bad_inlet_and_a_stranger():
    t = {"f_grain": {1: ("nope", 1)}}
    check("an unknown kind is reported", 0 if len(problems_in_table(t)) == 1 else 1, 0)
    t = {"f_grain": {1: ("in", 3)}}
    check("an inlet the module lacks is reported", 0 if len(problems_in_table(t)) == 1 else 1, 0)
    t = {"f_not_a_module": {1: bm.IN1}}
    check("a module that is not shipped is reported", 0 if len(problems_in_table(t)) == 1 else 1, 0)
    t = {"f_chladni": {1: ("const", (0.0, 0.0, 0.0), 0.0)}}
    check("a const with three channels is reported", 0 if len(problems_in_table(t)) == 1 else 1, 0)


def test_detects_a_dropped_outlet_and_a_dropped_module():
    full = {k: dict(v) for k, v in bm.BYPASS_EXPECT.items()}
    mods = param_bypass_modules()
    check("the shipped table is complete (precondition)", len(uncovered(full, mods)), 0)
    t = {k: dict(v) for k, v in full.items()}
    del t["f_grain"][3]
    check("a dropped secondary outlet is reported", 0 if ("f_grain", 3) in uncovered(t, mods) else 1, 0)
    t = {k: dict(v) for k, v in full.items()}
    del t["f_chladni"]
    check("a dropped generator is reported (no implicit out1)", 0 if ("f_chladni", 1) in uncovered(t, mods) else 1, 0)
    t = {k: dict(v) for k, v in full.items()}
    del t["f_vf_glow"]
    check("a dropped processor still has its implicit out1 but loses out2",
          0 if uncovered(t, mods) == [("f_vf_glow", 2)] else 1, 0)


# ---- the live comparator (bench_modules.bypass_issues), exercised with synthetic frames

N = 8


def _info(archetype, n_in):
    return {"archetype": archetype, "n_in": n_in, "input": mb.test_input(N)}


def _kinds(issues):
    return sorted(i[0] for i in issues)


def test_comparator_accepts_what_the_table_says_and_flags_what_it_does_not():
    import numpy as np
    info = _info("dual", 1)
    x = info["input"]
    ok = {1: x.copy(), 2: x.copy(), 3: x.copy()}
    check("a dual module that passes the source through on all three outlets is clean",
          len(bm.bypass_issues("f_stipple", info, N, ok)), 0)
    bad = {1: x.copy(), 2: x * np.float32(0.5), 3: x.copy()}
    check("a wrong outlet 2 is the only finding",
          0 if _kinds(bm.bypass_issues("f_stipple", info, N, bad)) == ["bypass_out2"] else 1, 0)
    one_off = {1: x.copy(), 2: x.copy(), 3: x.copy()}
    one_off[3][0, 0, 0] += np.float32(1e-6)
    check("an `in` expectation is exact: a 1e-6 error on outlet 3 is reported",
          0 if _kinds(bm.bypass_issues("f_stipple", info, N, one_off)) == ["bypass_out3"] else 1, 0)
    missing = {1: x.copy(), 3: x.copy()}
    check("a listed outlet with no captured frame is reported",
          0 if _kinds(bm.bypass_issues("f_stipple", info, N, missing)) == ["bypass_out2"] else 1, 0)
    check("a frame of another size is reported, not compared",
          0 if _kinds(bm.bypass_issues("f_stipple", info, N, {1: x[:4], 2: x, 3: x})) == ["bypass_out1"] else 1, 0)


def test_comparator_processor_default_is_out1_and_a_missing_out1_is_silent():
    import numpy as np
    info = _info("processor", 4)
    x = info["input"]
    check("f_masonry: out1 and out2 equal in1 -> clean",
          len(bm.bypass_issues("f_masonry", info, N, {1: x.copy(), 2: x.copy()})), 0)
    check("f_masonry: a wrong out1 is found through the implicit default",
          0 if _kinds(bm.bypass_issues("f_masonry", info, N, {1: x * np.float32(0.5), 2: x.copy()})) == ["bypass_out1"] else 1, 0)
    check("f_masonry: a missing out1 stays silent (as before 2026-10-06)",
          len(bm.bypass_issues("f_masonry", info, N, {2: x.copy()})), 0)
    check("f_masonry: a missing out2 is reported",
          0 if _kinds(bm.bypass_issues("f_masonry", info, N, {1: x.copy()})) == ["bypass_out2"] else 1, 0)
    check("a generator with no table entry is never checked",
          len(bm.bypass_issues("f_vf_vortex", _info("generator", 1), N, {1: x * np.float32(0.3)})), 0)


def test_comparator_vecfield_passthrough_and_constants():
    import numpy as np
    neutral = mb.neutral(N)                                   # what inlet 2 is fed
    vec = neutral.copy()
    vec[..., 2] = np.float32(0.5)
    vec[..., 3] = np.float32(1.0)
    x = mb.test_input(N)
    prism = {1: x.copy(), 2: x.copy(), 3: vec.copy()}
    check("f_vf_prism out3 = (in2.r, in2.g, 0.5, 1) -> clean",
          len(bm.bypass_issues("f_vf_prism", _info("processor", 4), N, prism)), 0)
    char_b = vec.copy()
    char_b[..., 2] = np.float32(127) / np.float32(255)        # a char outlet's nearest to 0.5
    prism[3] = char_b
    check("f_vf_prism out3: a char outlet's 127/255 for B is inside the tolerance",
          len(bm.bypass_issues("f_vf_prism", _info("processor", 4), N, prism)), 0)
    prism[3] = np.full_like(vec, np.float32(0.9))
    check("f_vf_prism out3: a genuinely wrong field is reported",
          0 if _kinds(bm.bypass_issues("f_vf_prism", _info("processor", 4), N, prism)) == ["bypass_out3"] else 1, 0)
    unconnected = vec.copy()
    unconnected[..., 0] = unconnected[..., 1] = np.float32(0.5)
    adv = {1: x.copy(), 2: x.copy(), 3: vec.copy()}
    check("f_vf_advect out3 (float32, tol 1e-5): (in2.r, in2.g, 0.5, 1) -> clean",
          len(bm.bypass_issues("f_vf_advect", _info("processor", 2), N, adv)), 0)
    adv[3] = unconnected
    check("f_vf_advect out3 (float32, tol 1e-5): the neutral-0.5 'unconnected' look is told apart from the passthrough",
          0 if _kinds(bm.bypass_issues("f_vf_advect", _info("processor", 2), N, adv)) == ["bypass_out3"] else 1, 0)
    wrong_b = vec.copy()
    wrong_b[..., 2] = neutral[..., 2]                          # B left at 128/255 instead of 0.5
    adv[3] = wrong_b
    check("f_vf_advect out3: B must be 0.5, not the input's blue",
          0 if _kinds(bm.bypass_issues("f_vf_advect", _info("processor", 2), N, adv)) == ["bypass_out3"] else 1, 0)
    gen = {1: np.zeros((N, N, 4), np.float32), 2: np.zeros((N, N, 4), np.float32), 3: np.zeros((N, N, 4), np.float32)}
    gen[1][..., 3] = 1.0
    gen[2][..., 0] = gen[2][..., 1] = 0.5
    gen[2][..., 3] = 1.0
    gen[3][..., 3] = 1.0
    check("f_chladni: black / zero-vector / black with alpha 1 -> clean",
          len(bm.bypass_issues("f_chladni", _info("generator", 1), N, gen)), 0)
    gen[2][..., 3] = 0.0
    check("f_chladni: a wrong alpha on out2 is reported",
          0 if _kinds(bm.bypass_issues("f_chladni", _info("generator", 1), N, gen)) == ["bypass_out2"] else 1, 0)
    big = {k: np.zeros((16, 16, 4), np.float32) for k in (1, 2, 3)}
    for k in big:
        big[k][..., 3] = 1.0
    big[2][..., 0] = big[2][..., 1] = 0.5
    check("f_chladni: constants are compared at the outlet's own size (the context, not the input's)",
          len(bm.bypass_issues("f_chladni", _info("generator", 1), N, big)), 0)


def test_expected_picks_the_inlet_it_names():
    a, b = mb.test_input(N, seed=1), mb.test_input(N, seed=2)
    got, tol = bm.bypass_expected(("in", 2), {1: a, 2: b})
    check("('in', 2) is inlet 2's texture, not inlet 1's", 0 if got is b and tol == 0.0 else 1, 0)
    got, tol = bm.bypass_expected(("in", 1), {1: a, 2: b})
    check("('in', 1) is inlet 1's texture", 0 if got is a else 1, 0)
    got, _ = bm.bypass_expected(("vec", 2, 0.1), {1: a, 2: b})
    import numpy as np
    want = b.copy()
    want[..., 2] = 0.5
    want[..., 3] = 1.0
    check("('vec', 2) is inlet 2's (R, G) with B = 0.5, A = 1", float(np.abs(got - want).max()), 0.0)
    check("('vec', 2) leaves inlet 2's own frame untouched", 0 if not np.array_equal(b, got) else 1, 0)


if __name__ == "__main__":
    sys.exit(run(globals()))
