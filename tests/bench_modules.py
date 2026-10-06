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
  - processors: under bypass (jsui, i.e. a click), out1 == in1 exactly
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

# Secondary outlets that must equal in1 under bypass (out1 is always checked).
# f_vf_warp out2 is the isolated warped layer; bypassed it degenerates to the
# unwarped source, same as out1 (fixed 2026-09-23).  Every module moved to
# `bypass_mode: "param"` (plan.md item 10, Matt's 2026-10-05 passthrough rule) lists its
# secondary outlets here.
BYPASS_PASSTHROUGH_OUTLETS = {
    "f_vf_warp": (2,),
    "f_vf_glow": (2,),
    "f_vf_streak": (2,),
    "f_vf_chroma": (2,),
    "f_vf_prism": (2,),     # out3 passes the vecfield input (neutral if unconnected), not in1: unchecked here
    "f_caustic": (2,),
    "f_vf_split": (2,),
}

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
    if info["archetype"] == "processor" and name not in NEUTRAL_BYPASS_BY_DESIGN:
        byp = (r.get("arrays") or {}).get("bypassed", {}).get(1)
        if byp is not None:
            d = float(np.abs(byp - info["input"]).max())
            if d > 0:
                issues.append(("bypass_out1", "", f"max |out1 - in1| = {d:.4g} under bypass"))
        # secondary outlets that are also meant to pass the input through
        for k in BYPASS_PASSTHROUGH_OUTLETS.get(name, ()):
            bk = (r.get("arrays") or {}).get("bypassed", {}).get(k)
            if bk is None:
                issues.append((f"bypass_out{k}", "", "no bypassed frame captured"))
            else:
                d = float(np.abs(bk - info["input"]).max())
                if d > 0:
                    issues.append((f"bypass_out{k}", "", f"max |out{k} - in1| = {d:.4g} under bypass"))
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
