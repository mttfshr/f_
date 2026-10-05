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
  - "out_of_scope" (needs a non-empty "reason") is an exemption for a module the schema
    cannot express (audio, the menu, a draft utility).  It fails if the module gains a
    src/<name>/definition.py, so an exemption cannot become permanent by accident.
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
    for n, b in (load_baseline() if BASELINE.exists() else {}).items():
        if b["status"] == "out_of_scope" and cur.get(n, {}).get("status") == "no_definition":
            cur[n] = b                      # keep the exemption and its reason
    BASELINE.write_text(json.dumps({
        "_about": "definition.py ratchet (tests/test_drift.py). Modules whose patcher does not "
                  "yet reproduce from its definition, with the drift counts they are allowed. "
                  "Only ever shrinks; delete this file when empty. Regenerate with "
                  "`python3 tests/test_drift.py --write-baseline`.",
        "modules": cur}, indent=1, sort_keys=True) + "\n")
    print(f"wrote {BASELINE} ({len(cur)} modules)")


def problems(cur, base):
    """List of human-readable problems for one module (empty = fine)."""
    if base is not None and base["status"] == "out_of_scope":
        if not str(base.get("reason", "")).strip():
            return ["exempt as out_of_scope but no reason is recorded"]
        if cur["status"] != "no_definition":
            return [f"is exempt as out_of_scope but is now {cur['status']} (it has a definition): "
                    f"remove the exemption"]
        return []
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


def test_out_of_scope_exemption_rules():
    exempt = {"status": "out_of_scope", "reason": "gen~ audio; the schema has no audio archetype"}
    nodef = {"status": "no_definition"}
    _eq("exempt and still without a definition: fine", problems(nodef, dict(exempt)), [])
    _eq("exempt but the module gained a definition: flagged",
        len(problems({"status": "drift", "counts": {"layout": 1}}, dict(exempt))), 1)
    _eq("exempt but the module now reproduces exactly: flagged",
        len(problems({"status": "ok"}, dict(exempt))), 1)
    _eq("exempt with no reason: flagged",
        len(problems(nodef, {"status": "out_of_scope"})), 1)
    _eq("exempt with a blank reason: flagged",
        len(problems(nodef, {"status": "out_of_scope", "reason": "  "})), 1)
    _eq("an unexempted module without a definition is still flagged",
        len(problems(nodef, None)), 1)


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
    _eq("a changed route argument list IS drift (one renamed box, not two)",
        _counts(_patcher([route()]), _patcher([route(text="route a c")])),
        {"boxes_renamed": 1})
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
    _eq("pix with a different @name is one renamed box; its ports and code still compare",
        _counts(base, other), {"boxes_renamed": 1})
    changed = _patcher([_pix("out1=in1*2;", ni=3, text="jit.gl.pix vsynth @name q")])
    _eq("a renamed pix with different ports and code registers both",
        _counts(base, changed), {"boxes_renamed": 1, "pix_io": 1, "code": 1})


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


# ---- T006: the same element under a different identity is one `old -> new` line

def _label(bid, text, rect=(4.0, 5.0, 30.0, 14.0), **kw):
    b = {"id": bid, "maxclass": "comment", "text": text, "presentation": 1,
         "presentation_rect": list(rect), "patching_rect": [0.0, 0.0, 1.0, 1.0]}
    b.update(kw)
    return b


def test_compare_renamed_label_is_paired_and_reported_once():
    old, new = _label("a", "Rotation"), _label("b", "Rot")
    counts, ex = drift.compare(_patcher([old]), _patcher([new]))
    _eq("an edited label is one renamed box, not a def-only plus a patch-only",
        {k: v for k, v in counts.items() if v}, {"boxes_renamed": 1})
    _eq("the example reads definition -> patch", ex["boxes_renamed"], ["comment:Rotation -> comment:Rot"])
    _eq("the same label, other id: nothing",
        _counts(_patcher([old]), _patcher([_label("z", "Rotation")])), {})


def test_compare_pairing_is_conservative():
    old = _label("a", "Rotation")
    far = _label("b", "Rot", rect=(4.0, 40.0, 30.0, 14.0))
    _eq("a label that moved far is not paired",
        _counts(_patcher([old]), _patcher([far])), {"boxes_def_only": 1, "boxes_patch_only": 1})
    dial_rect = _label("b", "Rot", rect=(4.0, 22.0, 27.0, 43.0))
    _eq("a different maxclass at the same rect is not paired",
        _counts(_patcher([_box("a")]), _patcher([dial_rect])),
        {"boxes_def_only": 1, "boxes_patch_only": 1})
    two_old = _patcher([_label("a", "A", rect=(4.0, 5.0, 30.0, 14.0)),
                        _label("b", "B", rect=(6.0, 5.0, 30.0, 14.0))])
    one_new = _patcher([_label("c", "C", rect=(5.0, 5.0, 30.0, 14.0))])
    _eq("two candidates for one box: nothing is paired",
        _counts(two_old, one_new), {"boxes_def_only": 2, "boxes_patch_only": 1})
    off_panel = _label("b", "Rot", presentation=0)
    _eq("boxes not on the presentation panel are not paired by position",
        _counts(_patcher([old]), _patcher([off_panel])), {"boxes_def_only": 1, "boxes_patch_only": 1})


def test_compare_a_renamed_box_is_still_compared_for_everything_but_its_identity():
    old = _label("a", "Rotation")
    _eq("a rename plus a colour change is a rename plus a prop",
        _counts(_patcher([old]), _patcher([_label("b", "Rot", textcolor=[1.0, 0.0, 0.0, 1.0])])),
        {"boxes_renamed": 1, "props": 1})
    _eq("a rename plus a small move (inside the pairing tolerance) is a rename plus layout",
        _counts(_patcher([old]), _patcher([_label("b", "Rot", rect=(7.0, 5.0, 30.0, 14.0))])),
        {"boxes_renamed": 1, "layout": 1})


def test_compare_cords_follow_a_renamed_box():
    dial = _box("a")
    built = _patcher([dial, _label("l", "Rotation")], [(("a", 0), ("l", 0))])
    same = _patcher([_box("x"), _label("m", "Rot")], [(("x", 0), ("m", 0))])
    _eq("a cord to a renamed box is the same cord", _counts(built, same), {"boxes_renamed": 1})
    cordless = _patcher([_box("x"), _label("m", "Rot")])
    _eq("a cord missing on the patch side still registers",
        _counts(built, cordless), {"boxes_renamed": 1, "lines_def_only": 1})


# ---- T008: what Max normalises (round-trip evidence, build/drift.py) versus what is real drift

def _valueof(b, **kw):
    v = b["saved_attribute_attributes"]["valueof"]
    for k, val in kw.items():
        if val is None:
            v.pop(k, None)
        else:
            v[k] = val
    return b


def _numbox(bid="n", name="mix", **kw):
    b = _box(bid, maxclass="live.numbox", name=name)
    b["saved_attribute_attributes"]["valueof"].update({"parameter_type": 0, "parameter_unitstyle": 0})
    return _valueof(b, **kw)


def _port(bid, maxclass, label, index):
    return {"id": bid, "maxclass": maxclass, "comment": label, "index": index, "numinlets": 0,
            "numoutlets": 1, "outlettype": [""], "patching_rect": [30.0, 10.0, 30.0, 30.0]}


def test_max_rewrites_are_not_drift():
    _eq("inlet and outlet `index` (Max resets every one to 0) is not drift",
        _counts(_patcher([_port("a", "inlet", "vecfield", 1), _port("b", "outlet", "streak", 2)]),
                _patcher([_port("x", "inlet", "vecfield", 0), _port("y", "outlet", "streak", 0)])), {})
    dial = lambda **kw: _patcher([_valueof(_box("a"), **kw)])
    _eq("a dial's parameter_mmin 0.0 dropped by Max is not drift",
        _counts(dial(parameter_mmin=0.0), dial(parameter_mmin=None)), {})
    _eq("a dial's mmin 0.5 against no mmin IS drift",
        _counts(dial(parameter_mmin=0.5), dial(parameter_mmin=None)), {"props": 1})
    _eq("a dial's mmax 127.0 (its default) dropped by Max is not drift",
        _counts(dial(parameter_mmax=127.0), dial(parameter_mmax=None)), {})
    _eq("a dial's mmax 100.0 against no mmax IS drift (only the default is dropped)",
        _counts(dial(parameter_mmax=100.0), dial(parameter_mmax=None)), {"props": 1})
    num = lambda **kw: _patcher([_numbox(**kw)])
    _eq("a numbox's mmin 0.0 dropped by Max is not drift",
        _counts(num(parameter_mmin=0.0), num(parameter_mmin=None)), {})
    _eq("a numbox's mmax 127.0 is NOT a dropped default (only a dial's is): IS drift",
        _counts(num(parameter_mmax=127.0), num(parameter_mmax=None)), {"props": 1})
    _eq("a float numbox written Int (unitstyle 0) that Max saves as Float (1) is not drift",
        _counts(num(parameter_unitstyle=0), num(parameter_unitstyle=1)), {})
    _eq("...in either direction",
        _counts(num(parameter_unitstyle=1), num(parameter_unitstyle=0)), {})
    _eq("a numbox with another unitstyle IS drift",
        _counts(num(parameter_unitstyle=2), num(parameter_unitstyle=0)), {"props": 1})
    _eq("an integer-type numbox's unitstyle is not rewritten: IS drift",
        _counts(num(parameter_type=1, parameter_unitstyle=0), num(parameter_type=1, parameter_unitstyle=1)),
        {"props": 1})
    ap = {"id": "t", "maxclass": "newobj", "text": "autopattr", "numinlets": 1, "numoutlets": 4}
    _eq("autopattr restore_extra (Max save state) is not drift",
        _counts(_patcher([ap]), _patcher([dict(ap, restore_extra={"bypass": {"id": "obj-47"}})])), {})
    txt = {"id": "d", "maxclass": "live.text", "text": "Fwd", "presentation": 1,
           "presentation_rect": [1.0, 2.0, 35.0, 17.0], "fontsize": 9.5,
           "saved_attribute_attributes": {"valueof": {"parameter_longname": "direction"}}}
    nofont = {k: v for k, v in txt.items() if k != "fontsize"}
    _eq("a live.text fontsize 9.5 dropped by Max is not drift",
        _counts(_patcher([txt]), _patcher([nofont])), {})
    _eq("a live.text fontsize 12 against none IS drift",
        _counts(_patcher([dict(txt, fontsize=12.0)]), _patcher([nofont])), {"props": 1})


def test_comment_size_is_fitted_by_max_but_position_is_structure():
    base = _patcher([_label("a", "Lon", rect=(4.0, 5.0, 50.0, 18.0))])
    _eq("a comment re-fitted to its text (width and height) is not drift",
        _counts(base, _patcher([_label("b", "Lon", rect=(4.0, 5.0, 51.0, 21.0))])), {})
    _eq("a comment that moved IS layout drift",
        _counts(base, _patcher([_label("b", "Lon", rect=(9.0, 5.0, 50.0, 18.0))])), {"layout": 1})
    dial = _box("a")
    wider = _box("a", presentation_rect=[4.0, 22.0, 31.0, 43.0])
    _eq("a dial's size is still layout (only comments are fitted)",
        _counts(_patcher([dial]), _patcher([wider])), {"layout": 1})


def test_what_max_preserves_stays_drift():
    """Round-trip: Max kept all three of these exactly as built, so a difference is a real
    edit (or a stale definition), never normalisation.  Pinned so nobody 'fixes' it away."""
    ap = {"id": "t", "maxclass": "newobj", "text": "autopattr", "numinlets": 1, "numoutlets": 4,
          "varname": "channel_grader_autopattr"}
    _eq("autopattr varname (built x_autopattr, shipped u905020188) IS drift",
        _counts(_patcher([ap]), _patcher([dict(ap, varname="u905020188")])), {"props": 1})
    _eq("a dial's param_connect IS drift",
        _counts(_patcher([_box("a", param_connect="grade_pix::x")]),
                _patcher([_box("a", param_connect="jit.gl.pix_AA::x")])), {"props": 1})
    _eq("a comment's varname (built lbl_zoom, shipped none) IS drift",
        _counts(_patcher([_label("a", "Zoom", varname="lbl_zoom")]), _patcher([_label("b", "Zoom")])),
        {"props": 1})


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
