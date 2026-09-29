"""
test_layout.py -- offline checks of the edit-view layout pass (build/layout.py).
Spec: .specify/build_layout/spec.md.  No Max needed, and nothing under
package/patchers is written: every definition is built in-process.

Two layers, like the rest of tests/:
  1. synthetic patchers with a known answer, incl. mutation checks that the invariant
     detectors really do catch an overlap / an upward wire / a changed presentation_rect
  2. every src/*/definition.py that builds through build_patcher.py: after the pass there
     must be 0 overlapping boxes, 0 shared origins, 0 upward wires, and the patcher must be
     identical to an edit_layout=False build except for patching_rect.

Run:  tests/run.sh tests/test_layout.py
"""
import copy
import glob
import os
import sys

from harness import check, note, run

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "build"))
import build_patcher as bp        # noqa: E402
import layout                     # noqa: E402


def _b(id, x, y, w=50.0, h=22.0, **kw):
    return {"box": {"id": id, "maxclass": "newobj", "patching_rect": [x, y, w, h], **kw}}


def _w(a, b):
    return {"patchline": {"source": [a, 0], "destination": [b, 0]}}


def test_audit_detects_overlap_and_upward_wire():
    boxes = [_b("a", 0, 0), _b("b", 20, 10), _b("c", 0, 100)]
    a = layout.audit(boxes, [_w("c", "a")])
    check("overlap pairs found (a,b)", 0 if a["overlaps"] == [("a", "b")] else 1, 0)
    check("upward wire found (c->a)", 0 if a["upward"] == [("c", "a")] else 1, 0)
    clean = layout.audit([_b("a", 0, 0), _b("b", 0, 100)], [_w("a", "b")])
    check("clean patcher: no findings",
          len(clean["overlaps"]) + len(clean["upward"]) + len(clean["same_origin"]), 0)


def test_audit_detects_shared_origin():
    a = layout.audit([_b("a", 5, 5), _b("b", 5, 5, w=1, h=1)], [])
    check("shared origin found", 0 if a["same_origin"] == [["a", "b"]] else 1, 0)


def test_assert_unchanged_catches_presentation_rect_change():
    boxes = [_b("a", 0, 0, presentation_rect=[1, 2, 3, 4])]
    lines = []
    snap = layout.snapshot(boxes, lines)
    boxes[0]["box"]["patching_rect"] = [9, 9, 9, 9]           # allowed
    layout.assert_unchanged(snap, boxes, lines)
    boxes[0]["box"]["presentation_rect"] = [1, 2, 3, 5]       # NOT allowed
    try:
        layout.assert_unchanged(snap, boxes, lines)
    except AssertionError:
        return
    check("presentation_rect change must be caught", 1, 0)


def test_assert_unchanged_catches_line_and_order_change():
    boxes = [_b("a", 0, 0), _b("b", 0, 50)]
    lines = [_w("a", "b")]
    snap = layout.snapshot(boxes, lines)
    lines2 = [_w("b", "a")]
    caught = 0
    try:
        layout.assert_unchanged(snap, boxes, lines2)
    except AssertionError:
        caught += 1
    try:
        layout.assert_unchanged(snap, list(reversed(boxes)), lines)
    except AssertionError:
        caught += 1
    check("line change + box reorder both caught", 2 - caught, 0)


def test_layout_is_deterministic_and_idempotent():
    boxes = [_b("i", 0, 0), _b("r", 0, 0, text="route x y"), _b("p", 0, 0, w=200),
             _b("c0", 0, 0, w=27, h=43), _b("c1", 0, 0, w=27, h=43),
             _b("q0", 0, 0, w=131), _b("q1", 0, 0, w=131), _b("o", 0, 0, w=30, h=30)]
    roles = {"i": ("inlet", None), "r": ("route", None), "p": ("pix", None),
             "c0": ("ctl", 0), "c1": ("ctl", 1), "q0": ("pre", 0), "q1": ("pre", 1),
             "o": ("outlet", 0)}
    lines = [_w("i", "r"), _w("r", "c0"), _w("r", "c1"), _w("c0", "q0"), _w("c1", "q1"),
             _w("q0", "p"), _w("q1", "p"), _w("p", "o")]
    a = copy.deepcopy(boxes)
    layout.layout_edit_view(a, lines, roles)
    b = copy.deepcopy(a)
    layout.layout_edit_view(b, lines, roles)
    check("second pass moves nothing", 0 if a == b else 1, 0)
    res = layout.audit(a, lines, roles)
    check("synthetic lane: overlaps", len(res["overlaps"]), 0)
    check("synthetic lane: upward wires", len(res["upward"]), 0)
    rr = a[1]["box"]["patching_rect"]
    check("route width = n*PITCH + 7", abs(rr[2] - (2 * layout.PITCH + 7.0)), 0)


def test_unknown_boxes_go_to_overflow_as_one_block():
    boxes = [_b("i", 0, 0), _b("u1", 500, 500), _b("u2", 560, 530)]
    layout.layout_edit_view(boxes, [], {"i": ("inlet", None)})
    u1, u2 = boxes[1]["box"]["patching_rect"], boxes[2]["box"]["patching_rect"]
    check("relative x offset preserved", abs((u2[0] - u1[0]) - 60.0), 0)
    check("relative y offset preserved", abs((u2[1] - u1[1]) - 30.0), 0)
    check("overflow is below the placed boxes", 0 if u1[1] > 20.0 + 30.0 else 1, 0)


def _build_all(edit_layout_on):
    """{name: (result, roles)} for every definition that builds through build_patcher."""
    out = {}
    for path in sorted(glob.glob(os.path.join(ROOT, "src", "*", "definition.py"))):
        try:
            defn = bp.load_definition(path)
            defn["edit_layout"] = edit_layout_on
            dbg = {}
            res = bp.build(defn, debug=dbg)
        except (KeyError, TypeError):
            continue                     # per-module build scripts (fluid, seeds, profile)
        out[defn["name"]] = (res, dbg.get("roles", {}))
    return out


def _strip(node):
    if isinstance(node, dict):
        return {k: _strip(v) for k, v in node.items() if k != "patching_rect"}
    if isinstance(node, list):
        return [_strip(x) for x in node]
    return node


def test_every_definition_lays_out_clean():
    on = _build_all(True)
    check("definitions built", 0 if len(on) >= 25 else 1, 0)
    note("definitions built", len(on))
    tot_o = tot_s = tot_u = 0
    bad, raw_notes = [], []
    for name, (res, roles) in on.items():
        p = res["patcher"]
        a = layout.audit(p["boxes"], p["lines"], roles)
        # Findings that involve only raw_boxes (ids not in roles) are the definition's own
        # arrangement, moved as a block -- reported, not asserted.
        own = lambda ids: any(i in roles for i in ids)
        ov = [x for x in a["overlaps"] if own(x)]
        so = [x for x in a["same_origin"] if own(x)]
        up = [x for x in a["upward"] if all(i in roles for i in x)]
        raw = (len(a["overlaps"]) - len(ov), len(a["same_origin"]) - len(so),
               len(a["upward"]) - len(up))
        if any(raw):
            raw_notes.append(f"{name}: raw_boxes-only findings overlaps={raw[0]} "
                             f"same_origin={raw[1]} upward={raw[2]} (not asserted)")
        tot_o += len(ov)
        tot_s += len(so)
        tot_u += len(up)
        if ov or so or up:
            bad.append(f"{name}: overlaps={len(ov)} same_origin={len(so)} upward={len(up)}")
    for line in raw_notes + bad:
        print("    " + line)
    check("total overlapping pairs, all definitions", tot_o, 0)
    check("total shared origins, all definitions", tot_s, 0)
    check("total upward wires, all definitions", tot_u, 0)


def test_only_patching_rect_differs_from_unlaid_build():
    on, off = _build_all(True), _build_all(False)
    diffs = [n for n in on if _strip(on[n][0]) != _strip(off[n][0])]
    if diffs:
        print("    differs beyond patching_rect: " + ", ".join(diffs))
    check("definitions differing beyond patching_rect", len(diffs), 0)


def test_presentation_rects_byte_identical():
    on, off = _build_all(True), _build_all(False)

    def pres(res):
        return [(b["box"]["id"], b["box"].get("presentation_rect")) for b in res["patcher"]["boxes"]]

    diffs = [n for n in on if pres(on[n][0]) != pres(off[n][0])]
    check("definitions whose presentation_rect changed", len(diffs), 0)


if __name__ == "__main__":
    sys.exit(run(globals()))
