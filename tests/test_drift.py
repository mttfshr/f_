"""
test_drift.py -- the definition.py ratchet.  definition.py is the source of truth
for every module; a hand edit in Max has to be written back into it.  This test
rebuilds every shipped patcher from its definition (build/drift.py, read-only)
and holds the result against tests/drift_baseline.json, a list that may only
shrink -- a stopgap that is deleted once it is empty.

A module NOT in the baseline must reproduce exactly.  A module in it:
  - drift grew in any category          -> FAIL: write the edit back into definition.py
  - drift shrank                        -> FAIL: lower the baseline (see below)
  - now reproduces exactly              -> FAIL: remove it from the baseline
  - status changed (e.g. gained a definition) -> FAIL: update the baseline
Shrinking fails on purpose, so every cleanup lands as a visible baseline diff.
Blind spot: counts can't see one difference fixed and another introduced.

    tests/run.sh tests/test_drift.py
    python3 tests/test_drift.py --write-baseline     # rewrite the baseline from the repo
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "build"))
import build_patcher as bp          # noqa: E402
import drift                        # noqa: E402

from harness import check, run      # noqa: E402

BASELINE = Path(__file__).resolve().parent / "drift_baseline.json"


def _eq(label, got, want):
    """Exact-count assertion. harness.check passes when value <= tol, so
    `check(label, n, 1)` also passes at n == 0 -- useless for 'this must be
    detected'. Every detection test below uses _eq."""
    check(label, 0 if got == want else 1, 0)


def _summary(r):
    s = {"status": r["status"]}
    nz = {k: v for k, v in r["counts"].items() if v}
    if nz:
        s["counts"] = nz
    return s


def current():
    return {n: _summary(drift.report(n)) for n in drift.shipped_names()}


def load_baseline():
    return json.loads(BASELINE.read_text())["modules"]


def write_baseline():
    cur = {n: s for n, s in current().items() if s["status"] != "ok"}
    BASELINE.write_text(json.dumps({
        "_about": "definition.py ratchet (tests/test_drift.py). Modules whose patcher does not "
                  "yet reproduce from its definition, with the drift counts they are allowed. "
                  "Only ever shrinks; delete this file when empty. Regenerate with "
                  "`python3 tests/test_drift.py --write-baseline`.",
        "modules": cur}, indent=1, sort_keys=True) + "\n")
    print(f"wrote {BASELINE} ({len(cur)} modules)")


def problems(cur, base):
    """List of human-readable problems for one module (empty = fine)."""
    if base is None:
        if cur["status"] == "ok":
            return []
        what = {"drift": "drifted from its definition (a hand edit not written back to "
                         "definition.py, or a definition change not rebuilt)",
                "no_definition": "has no src/<name>/definition.py",
                "build_error": "its definition fails to build"}[cur["status"]]
        return [f"{what}: {cur.get('counts', '')}"]
    if cur["status"] == "ok":
        return ["now reproduces exactly -- remove it from the baseline"]
    if cur["status"] != base["status"]:
        return [f"status {base['status']} -> {cur['status']} -- update the baseline"]
    cc, bc = cur.get("counts", {}), base.get("counts", {})
    grew = {k: (bc.get(k, 0), v) for k, v in cc.items() if v > bc.get(k, 0)}
    if grew:
        return [f"drift grew {grew} (baseline, now) -- write the edit back into definition.py"]
    if cc != bc:
        return [f"drift shrank {bc} -> {cc} -- lower the baseline (--write-baseline)"]
    return []


def test_every_shipped_patcher_matches_its_definition_or_its_baseline():
    base, cur = load_baseline(), current()
    bad = 0
    for name in sorted(set(cur) | set(base)):
        if name not in cur:
            print(f"    BAD   {name}: in the baseline but no longer a shipped patcher")
            bad += 1
            continue
        probs = problems(cur[name], base.get(name))
        if probs:
            bad += 1
            print(f"    BAD   {name}: {'; '.join(probs)}")
        elif name in base:
            print(f"    known {name}: {base[name]['status']} {base[name].get('counts', '')}")
    n_ok = sum(1 for n in cur if n not in base)
    print(f"    ({n_ok} reproduce exactly, {len(base)} in the baseline)")
    _eq("modules out of line with the baseline", bad, 0)


def test_problems_rules():
    """The ratchet's own decision table."""
    ok, drifted = {"status": "ok"}, {"status": "drift", "counts": {"layout": 2, "props": 1}}
    _eq("clean module, no baseline: fine", problems(ok, None), [])
    _eq("drifted module, no baseline: flagged", len(problems(drifted, None)), 1)
    _eq("no_definition, no baseline: flagged", len(problems({"status": "no_definition"}, None)), 1)
    _eq("same drift as baseline: fine", problems(drifted, dict(drifted)), [])
    grown = {"status": "drift", "counts": {"layout": 3, "props": 1}}
    _eq("drift grew: flagged", len(problems(grown, dict(drifted))), 1)
    newcat = {"status": "drift", "counts": {"layout": 2, "props": 1, "code": 1}}
    _eq("a new drift category: flagged", len(problems(newcat, dict(drifted))), 1)
    shrank = {"status": "drift", "counts": {"layout": 1, "props": 1}}
    _eq("drift shrank without lowering the baseline: flagged", len(problems(shrank, dict(drifted))), 1)
    _eq("baselined module now exact: flagged (remove it)", len(problems(ok, dict(drifted))), 1)
    _eq("status changed: flagged", len(problems({"status": "drift", "counts": {"layout": 1}},
                                                {"status": "no_definition"})), 1)


# ---- compare() itself: synthetic fixtures (bad cases must register, noise must not)

def _box(bid, maxclass="live.dial", name="gain", **kw):
    b = {"id": bid, "maxclass": maxclass, "presentation": 1,
         "presentation_rect": [4.0, 22.0, 27.0, 43.0], "patching_rect": [10.0, 10.0, 30.0, 20.0],
         "saved_attribute_attributes": {"valueof": {"parameter_longname": name,
                                                    "parameter_mmax": 1.0}}}
    b.update(kw)
    return b


def _patcher(boxes, lines=()):
    return {"boxes": [{"box": b} for b in boxes],
            "lines": [{"patchline": {"source": list(s), "destination": list(d)}} for s, d in lines]}


def _counts(rebuilt, shipped):
    c, _ = drift.compare(rebuilt, shipped)
    return {k: v for k, v in c.items() if v}


def test_compare_identity_ignores_ids_and_edit_view_layout():
    a = _patcher([_box("obj-1"), _box("obj-2", name="mix")])
    b = _patcher([_box("obj-9", name="mix", patching_rect=[300.0, 5.0, 9.0, 9.0]),
                  _box("obj-7", patching_rect=[1.0, 1.0, 1.0, 1.0])])
    _eq("same boxes, other ids and patching_rect: no drift", _counts(a, b), {})


def test_compare_box_counts_props_and_layout_register():
    base = _patcher([_box("a")])
    two = _patcher([_box("a"), _box("b", name="mix")])
    _eq("box only in the shipped patch", _counts(base, two), {"boxes_patch_only": 1})
    _eq("box only in the definition build", _counts(two, base), {"boxes_def_only": 1})
    ranged = _box("a")
    ranged["saved_attribute_attributes"]["valueof"]["parameter_mmax"] = 5.0
    _eq("a dial's range changed in Max is drift", _counts(base, _patcher([ranged])), {"props": 1})
    _eq("a hint changed in Max is drift",
        _counts(_patcher([_box("a", hint="R gain")]), _patcher([_box("a", hint="Red gain")])),
        {"props": 1})
    moved = _box("a", presentation_rect=[40.0, 22.0, 27.0, 43.0])
    _eq("a moved dial is layout drift and nothing else", _counts(base, _patcher([moved])), {"layout": 1})
    tiny = _box("a", presentation_rect=[4.0004, 22.0, 27.0, 43.0])
    _eq("a sub-tolerance rect wobble is not drift", _counts(base, _patcher([tiny])), {})
    hidden = _box("a", presentation=0, presentation_rect=[99.0, 99.0, 1.0, 1.0])
    off = _box("a", presentation=0, presentation_rect=[1.0, 1.0, 1.0, 1.0])
    _eq("a rect that is not on the presentation panel is not layout drift",
        _counts(_patcher([hidden]), _patcher([off])).get("layout", 0), 0)


def test_compare_max_normalisation_is_not_drift_but_real_edits_are():
    def route(**kw):
        return {"id": "r", "maxclass": "newobj", "text": "route a b", "numinlets": 1,
                "numoutlets": 3, "outlettype": ["", "", ""], **kw}
    shipped_route = route(numinlets=3, numoutlets=3, outlettype=["x", "y", "z"],
                          restore={"a": [0.0]}, save=["#N", "thispatcher"])
    _eq("Max-derived ports and saved state are not drift",
        _counts(_patcher([route()]), _patcher([shipped_route])), {})
    _eq("a changed route argument list IS drift",
        _counts(_patcher([route()]), _patcher([route(text="route a c")])),
        {"boxes_def_only": 1, "boxes_patch_only": 1})
    att = {"id": "t", "maxclass": "attrui", "attr": "gain"}
    _eq("attrui style ''/missing and parameter_enable 0/missing are the same",
        _counts(_patcher([dict(att, style="", parameter_enable=0)]), _patcher([att])), {})
    _eq("attrui with a real style is drift",
        _counts(_patcher([att]), _patcher([dict(att, style="x")])), {"props": 1})


def _pix(code, ni=2, no=1, text="jit.gl.pix vsynth @name p"):
    return {"id": "p", "maxclass": "newobj", "text": text, "numinlets": ni, "numoutlets": no,
            "patcher": {"boxes": [{"box": {"maxclass": "codebox", "code": code}}]}}


def test_compare_pix_io_and_code():
    base = _patcher([_pix("out1=in1;")])
    _eq("pix port count change", _counts(base, _patcher([_pix("out1=in1;", ni=3)])), {"pix_io": 1})
    _eq("pix codebox edited", _counts(base, _patcher([_pix("out1=in1*2;")])), {"code": 1})
    other = _patcher([_pix("out1=in1;", text="jit.gl.pix vsynth @name q")])
    got = _counts(base, other)
    _eq("pix with different @name text registers as pix_io",
        got.get("pix_io", 0) >= 1 and got.get("boxes_def_only", 0) == 1, True)


def test_compare_cords_between_matched_boxes():
    a, b = _box("a"), _box("b", name="mix")
    plain = _patcher([a, b])
    wired = _patcher([a, b], [(("a", 0), ("b", 0))])
    _eq("cord only in the shipped patch", _counts(plain, wired), {"lines_patch_only": 1})
    _eq("cord only in the definition build", _counts(wired, plain), {"lines_def_only": 1})
    _eq("same cord, other ids", _counts(wired, _patcher([_box("x"), _box("y", name="mix")],
                                                         [(("x", 0), ("y", 0))])), {})
    d1, d2 = _box("c"), _box("d")       # identical identity: cords touching them are not compared
    _eq("cords on non-unique boxes are not compared",
        _counts(_patcher([d1, d2], [(("c", 0), ("d", 0))]), _patcher([d1, d2])), {})


def test_build_is_pure_and_returns_side_files():
    """build() once rewrote package/javascript/lens_toggle.js from inside; it must not."""
    js = ROOT / "package" / "javascript" / "lens_toggle.js"
    before = (js.stat().st_mtime_ns, js.read_text())
    defn = bp.load_definition(ROOT / "src" / "f_lens" / "definition.py")
    bp.build(defn)
    _eq("build() leaves the shipped toggle JS untouched",
        (js.stat().st_mtime_ns, js.read_text()), before)
    files = {}
    bp.build(defn, side_files=files)
    _eq("build(side_files=...) hands the JS back instead",
        list(files) == [js] and isinstance(files[js], str) and bool(files[js]), True)


if __name__ == "__main__":
    if "--write-baseline" in sys.argv:
        write_baseline()
    else:
        sys.exit(run(globals()))
