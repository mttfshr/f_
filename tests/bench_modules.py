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
import sys

import numpy as np

import benchclient as bc
import modulebench as mb
from harness import check, run
from module_contract import shipped_modules
from test_module_contracts import NOT_APPLICABLE

# Errors posted by the module's own size handling in this nesting
# ("getattr presentation_rect" to thispatcher); whether Vsynth shows it too is
# unverified.
ENV_NOISE = ("jpatcher: doesn't understand getattr",)

KNOWN = {
    ("f_vf_fieldmap", "param", "gain"): "gain dial -> attr strength (static: test_module_contracts)",
    ("f_vf_fieldmap", "error", "jit.gl.pix: invalid message strength"): "same bug",
    ("f_vf_fieldmap", "error", "jit.gl.pix: boundmode is not a valid attribute argument"):
        "pix box declares @boundmode, not a jit.gl.pix attribute (found 2026-09-22; unfixed)",
    ("f_vf_repulse", "param", "gain"): "gain dial -> attr strength (static)",
    ("f_vf_repulse", "error", "jit.gl.pix: invalid message strength"): "same bug",
    ("f_masonry", "error", "jit.gl.pix: invalid message quantize"): "same",
    ("f_masonry", "error", "autopattr: varname is not a valid attribute argument"):
        "`autopattr @varname X` isn't valid syntax in Max 9 (found 2026-09-22; unfixed)",
    ("f_mobius", "error", "autopattr: varname is not a valid attribute argument"): "same",
    ("f_stereo", "error", "autopattr: varname is not a valid attribute argument"): "same",
    ("f_hue_processor", "error", "js: bad outlet index N [hue_range.js]"):
        "hue_range.js calls outlet() beyond its outlet count (found 2026-09-22; unfixed)",
    ("f_lens", "bypass_out1", ""): "bypass reaches lens_pix only, not lens_halation (.specify/plan.md Parked)",
    ("f_sirds", "bypass_out1", ""): "bypassed out1 != in1; stage0 not bypassed (found 2026-09-22; uninvestigated)",
}

_seen = set()
_bypass_msg = {"works": [], "no": []}


def module_issues(name):
    r, plan, info = mb.run_module(name)
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
    if info["archetype"] == "processor":
        byp = (r.get("arrays") or {}).get("bypassed", {}).get(1)
        if byp is not None:
            d = float(np.abs(byp - info["input"]).max())
            if d > 0:
                issues.append(("bypass_out1", "", f"max |out1 - in1| = {d:.4g} under bypass"))
    bm = r.get("bypass_msg_readback") or {}
    (_bypass_msg["works"] if bm and all(v == 1 for v in bm.values()) else _bypass_msg["no"]).append(name)
    return issues, r, info


def test_live_module_contracts():
    unexpected, n = [], 0
    for path in shipped_modules():
        name = path.stem
        if name in NOT_APPLICABLE or name.endswith("_version"):
            continue
        n += 1
        issues, r, info = module_issues(name)
        by = r.get("bypass_jsui_readback") or {}
        idle = [k for k, v in by.items() if v != 1]
        line = f"    {name:22s} outs={(r.get('outputs') or {}).get('base')} pix={len(r.get('pix') or [])}"
        if idle:
            line += f" bypass-leaves-active={len(idle)}"
        print(line)
        for kind, detail, why in issues:
            key = (name, kind, detail)
            if key in KNOWN:
                _seen.add(key)
                print(f"      XFAIL {kind} {detail} {why} -- {KNOWN[key]}")
            else:
                unexpected.append(f"{name}: {kind} {detail} {why}")
                print(f"      BAD   {kind} {detail} {why}")
    print(f"    ({n} modules)")
    print(f"    documented `bypass 1` control message works in {len(_bypass_msg['works'])}, "
          f"not in {len(_bypass_msg['no'])}: {_bypass_msg['no']}")
    check("unexpected live contract issues", len(unexpected), 0)


def test_known_live_issues_still_present():
    gone = sorted(set(KNOWN) - _seen)
    for key in gone:
        print(f"    XPASS {key} -- remove from KNOWN")
    check("known issues that now pass (remove them)", len(gone), 0)


if __name__ == "__main__":
    bc.require_bench(ports=bc.MODULE_PORTS, patch="bench_module.maxpat")
    sys.exit(run(globals()))
