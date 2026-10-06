"""
bench_modules.py -- E3 live module contract suite
(.specify/test_bench/tasks_extensions.md T105-T107). Needs Max with
tests/bench/bench_module.maxpat open (Vsynth performance patches closed).
Each module gets a freshly reopened bench (see modulebench.run_module).

Per module, asserted:
  - loads and every outlet produces a frame
  - no unexpected Max errors (environment noise and known issues excluded)
  - every route parameter with a known range, sent as a control message,
    reads back unchanged on its target pix attribute
  - bypass (jsui, i.e. a click): a processor's out1 == in1 exactly, and every outlet listed
    in BYPASS_EXPECT shows what that table says (tests/test_bench_expect.py keeps it complete)
Reported, not asserted:
  - whether the documented `bypass 1` control message works
  - pix objects the bypass leaves active

Run:  tests/bench.sh tests/bench_modules.py   (~3 s per module)
"""
import re
import os
import sys

import numpy as np

import benchclient as bc
import modulebench as mb
from harness import check, run
from module_contract import shipped_modules
from test_module_contracts import NOT_APPLICABLE

# BENCH_MODULES=f_a,f_b limits the run to those modules (tests/bench.sh --changed
# sets it when only some patchers changed). Empty means all.
ONLY = {m for m in os.environ.get("BENCH_MODULES", "").split(",") if m}

# Errors posted by the module's own size handling in this nesting
# ("getattr presentation_rect" to thispatcher); whether Vsynth shows it too is
# unverified.
ENV_NOISE = ("jpatcher: doesn't understand getattr",)

KNOWN = {
}

# What each outlet must show under bypass: {module: {outlet: expectation}}.  A processor's
# out1 is checked as `in1` without being listed (the implicit default, see module_issues);
# every other outlet of a module moved to `bypass_mode: "param"` (plan.md item 10, Matt's
# 2026-10-05 passthrough rule) is listed here, and tests/test_bench_expect.py fails when one
# is missing.  The bench feeds in1 random char-representable RGBA and every other inlet
# neutral grey (128/255 in all four channels, modulebench.neutral).  Expectations:
#   ("in", k)            equals the texture fed to inlet k, exactly
#   ("vec", k, tol)      the vecfield passthrough of inlet k: (R, G, 0.5, 1.0); a char outlet
#                        cannot hold 0.5 exactly, hence the tolerance there
#   ("const", rgba, tol) a constant (a module with no texture input, bypassed to neutral values)
# Expectations other than ("in", 1) for f_stipple, f_grain, f_chladni and the out3 of
# f_vf_prism / f_vf_advect were derived from the codeboxes (2026-10-06) and are not yet seen
# green live: the first live run validates them.
IN1 = ("in", 1)
BYPASS_EXPECT = {
    "f_vf_warp": {2: IN1},      # out2 is the isolated warped layer; bypassed it is the unwarped source (fixed 2026-09-23)
    "f_vf_glow": {2: IN1},
    "f_vf_streak": {2: IN1},
    "f_vf_chroma": {2: IN1},
    "f_vf_prism": {2: IN1, 3: ("vec", 2, 0.0042)},     # out3: the vecfield input (neutral 0.5 if unconnected)
    "f_caustic": {2: IN1},
    "f_vf_split": {2: IN1},
    "f_vf_advect": {2: IN1, 3: ("vec", 2, 1e-5)},      # out3: the vecfield input (neutral 0.5 if unconnected)
    "f_masonry": {2: IN1},                              # out2 is the brick mask
    "f_stipple": {1: IN1, 2: IN1, 3: IN1},              # dual: the source when connected, black when not
    "f_grain": {1: IN1, 2: IN1, 3: IN1},                # dual: the source when connected, black when not
    "f_chladni": {                                      # generator, no texture input: neutral values
        1: ("const", (0.0, 0.0, 0.0, 1.0), 0.0),        # luma: black
        2: ("const", (0.5, 0.5, 0.0, 1.0), 0.0),        # vecfield: zero vector
        3: ("const", (0.0, 0.0, 0.0, 1.0), 0.0),        # magnitude: black
    },
}


def bypass_expected(spec, inputs):
    """(expected array or colour, tolerance) for one BYPASS_EXPECT entry; inputs maps inlet -> array."""
    kind = spec[0]
    if kind == "in":
        return inputs[spec[1]], 0.0
    if kind == "vec":
        a = inputs[spec[1]].copy()
        a[..., 2] = np.float32(0.5)
        a[..., 3] = np.float32(1.0)
        return a, spec[2]
    if kind == "const":
        return np.array(spec[1], np.float32), spec[2]
    raise ValueError(f"unknown bypass expectation {spec!r}")


def bypass_issues(name, info, n, bypassed):
    """The bypass findings for one module, as module_issues() tuples.  `bypassed` maps
    outlet number -> captured frame; info carries archetype, n_in and the first input.
    Pure (no Max), so tests/test_bench_expect.py can exercise it with synthetic frames."""
    issues = []
    expect = dict(BYPASS_EXPECT.get(name, {}))
    implicit = set()
    if info["archetype"] == "processor" and name not in NEUTRAL_BYPASS_BY_DESIGN and 1 not in expect:
        expect[1] = IN1                     # a processor's out1 is its input under bypass, always
        implicit.add(1)                     # (and is skipped silently when no frame was captured)
    ins = {1: info["input"]}
    for k in range(2, info["n_in"] + 1):
        ins[k] = mb.neutral(n)              # what run_module feeds every inlet after the first
    for k, spec in sorted(expect.items()):
        got = bypassed.get(k)
        if got is None:
            if k not in implicit:
                issues.append((f"bypass_out{k}", "", "no bypassed frame captured"))
            continue
        want, tol = bypass_expected(spec, ins)
        if spec[0] != "const" and want.shape != got.shape:
            issues.append((f"bypass_out{k}", "", f"bypassed frame is {got.shape}, expected {want.shape}"))
            continue
        d = float(np.abs(got - want).max())
        if d > tol:
            mean = lambda a: np.round(np.asarray(a, np.float64).reshape(-1, 4).mean(axis=0), 4).tolist()
            issues.append((f"bypass_out{k}", "",
                           f"max |out{k} - expected {spec[0]}{spec[1]}| = {d:.4g} under bypass (tol {tol:g}); "
                           f"mean out {mean(got)}, mean expected {mean(np.broadcast_to(want, got.shape))}"))
    return issues

# Multi-stage modules whose specs deliberately gate bypass at the final stage
# only (feedback loops stay warm / intermediate stages need no gating):
# f_vf_advect (plan.md: feedback keeps running through bypass),
# f_vf_seeds (ADR 8: bypass applied only at the composite stage),
# f_vf_optical_flow (per-stage bypass Params, see codebox_stage_e.gen header).
# Any change is a GPU-cost decision, not a bug.
PARTIAL_BYPASS_BY_DESIGN = {"f_vf_advect", "f_vf_seeds", "f_vf_optical_flow",
                            "f_vf_fluid"}     # fluid: Param gate on enc, not native @bypass (plan ADR-8)

# Processors whose bypass is DOCUMENTED to output a neutral field, not to pass the input through,
# so the strict `out1 == in1 under bypass` check does not apply. f_vf_optical_flow: "bypass
# should mean output neutral field" (src/f_vf_optical_flow/definition.py header;
# codebox_stage_e.gen header). The check only started to run for it when its definition moved
# into src/ (build_cleanup T007), because modulebench.archetype() reads the definition there;
# before that its archetype was unknown and it was silently skipped.
NEUTRAL_BYPASS_BY_DESIGN = {"f_vf_optical_flow"}

# Modules whose output follows the render CONTEXT size (512x512 in the module bench), not the
# input texture's: feed them an input of that size so the passthrough check is like for like.
INPUT_SIZE = {"f_vf_fluid": 512}

# Modules whose primary inlet takes a VECFIELD (B = 0.5, A = 1): a random-RGBA input is not one,
# and f_vf_fluid (correctly) refuses a texture whose B is not ~0.5 as a force. Char-representable
# k/255 values, B = 128/255, so a passthrough stays exact.
VECFIELD_INPUT = {"f_vf_fluid"}


def vecfield_input(n):
    x = mb.test_input(n)
    x[..., 2] = np.float32(128) / np.float32(255)
    return x

_seen = set()
# Informational only: whether the optional `bypass <0|1>` control *message*
# reaches the pix. The toggle path (jsui -> attrui -> pix) is the supported
# bypass and is what bypass_out1 above tests; only the oldest modules also
# route the message.
_bypass_msg = {"works": [], "no": []}


def module_issues(name):
    n = INPUT_SIZE.get(name, 64)
    r, plan, info = mb.run_module(name, n=n, first_input=vecfield_input(n) if name in VECFIELD_INPUT else None)
    issues = []
    if r["status"] == "stalled":
        issues.append(("stalled", "", str(r["errors"][-1:])))
        return issues, r, info
    base = (r.get("outputs") or {}).get("base", [])
    for k in range(1, min(info["n_out"], 4) + 1):
        if k not in base:
            issues.append(("outlet", str(k), "no frame"))
    for e in r["errors"]:
        if not e.startswith(ENV_NOISE):
            issues.append(("error", re.sub(r"index \d+", "index N", e), ""))
    for p in plan:
        for a in p["attrs"]:
            vals = (r.get("params_readback") or {}).get(a) or {}
            if not vals:
                issues.append(("param", p["name"], f"no attribute '{a}' on target pix"))
            elif p["value_comparable"]:
                for pix, v in vals.items():
                    if v is None or abs(float(v) - p["value"]) > 1e-4 * max(1.0, abs(p["value"])):
                        issues.append(("param", p["name"], f"{pix}.{a} = {v}, sent {p['value']:.6g}"))
    issues += bypass_issues(name, info, n, (r.get("arrays") or {}).get("bypassed", {}))
    bm = r.get("bypass_msg_readback") or {}
    (_bypass_msg["works"] if bm and all(v == 1 for v in bm.values()) else _bypass_msg["no"]).append(name)
    return issues, r, info


def test_live_module_contracts():
    unexpected, n = [], 0
    for path in shipped_modules():
        name = path.stem
        if name in NOT_APPLICABLE or name.endswith("_version"):
            continue
        if ONLY and name not in ONLY:
            continue
        n += 1
        issues, r, info = module_issues(name)
        by = r.get("bypass_jsui_readback") or {}
        idle = [k for k, v in by.items() if v != 1]
        line = f"    {name:22s} outs={(r.get('outputs') or {}).get('base')} pix={len(r.get('pix') or [])}"
        if idle:
            line += f" bypass-leaves-active={len(idle)}"
            if name in PARTIAL_BYPASS_BY_DESIGN:
                line += " (by design)"
        print(line)
        for kind, detail, why in issues:
            key = (name, kind, detail)
            if key in KNOWN:
                _seen.add(key)
                print(f"      XFAIL {kind} {detail} {why} -- {KNOWN[key]}")
            else:
                unexpected.append(f"{name}: {kind} {detail} {why}")
                print(f"      BAD   {kind} {detail} {why}")
    print(f"    ({n} modules{', limited by BENCH_MODULES' if ONLY else ''})")
    print(f"    documented `bypass 1` control message works in {len(_bypass_msg['works'])}, "
          f"not in {len(_bypass_msg['no'])}: {_bypass_msg['no']}")
    check("unexpected live contract issues", len(unexpected), 0)


def test_known_live_issues_still_present():
    # With BENCH_MODULES set, known issues of modules that were not run cannot show
    # up, and must not be reported as fixed.
    gone = sorted(k for k in set(KNOWN) - _seen if not ONLY or k[0] in ONLY)
    for key in gone:
        print(f"    XPASS {key} -- remove from KNOWN")
    check("known issues that now pass (remove them)", len(gone), 0)


if __name__ == "__main__":
    # Each module reopens the bench itself (modulebench.run_module, fresh=True),
    # so don't require it to be open: open it, which also fails fast if Max isn't up.
    bc.reopen(ports=bc.MODULE_PORTS, patch="bench_module.maxpat")
    sys.exit(run(globals()))
