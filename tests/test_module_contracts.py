"""
test_module_contracts.py -- offline contract check of every shipped f_
bpatcher (.specify/test_bench/tasks_extensions.md T101). No Max needed.

For each module: every `route` name reaches an attrui; every attrui
attribute exists on the pix it drives (a codebox Param or a built-in
jit.gl.pix attribute); no route name that is itself a Param is wired to a
*different* attribute (cross-wiring).

Known, recorded issues are reported as XFAIL with a pointer instead of
failing the suite; if one starts passing it reports XPASS -- remove it from
KNOWN_ISSUES then. Anything not listed fails.

Run:  tests/run.sh tests/test_module_contracts.py
"""
import sys

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

# (module, kind, detail) -> pointer to where it's recorded
KNOWN_ISSUES = {
    ("f_masonry", "bad_attr", "quantize"):
        "dead control: Param quantize removed 2026-07-05 (.specify/f_masonry/tasks.md E001), UI left behind",
    ("f_masonry", "unrouted", "course_seed"):
        "route outlet unconnected; route brick_seed drives the course_seed numbox (found 2026-09-22; unfixed)",
    ("f_masonry", "cross_wired", "brick_seed"): "same wiring bug as above",
}

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


if __name__ == "__main__":
    sys.exit(run(globals()))
