"""
test_overrides.py -- the `overrides` block in definition.py (build/build_patcher.py:
element_keys, apply_overrides) and the tool that writes it (build/capture.py).

Offline: a small synthetic definition in a temp dir, so nothing depends on a shipped module.

    tests/run.sh tests/test_overrides.py
"""
import copy
import json
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "build"))
import build_patcher as bp          # noqa: E402
import capture                      # noqa: E402
import drift                        # noqa: E402

from harness import check, run      # noqa: E402


def _eq(label, got, want):
    check(label, 0 if got == want else 1, 0)


def _raises(label, fn, fragment=""):
    try:
        fn()
    except ValueError as e:
        check(label, 0 if fragment in str(e) else 1, 0)
        return
    check(label + " (nothing was raised)", 1, 0)


def _params(order=("a", "b")):
    table = {
        "a": {"name": "a", "type": "float", "min": 0.0, "max": 1.0, "default": 0.5, "label": "A", "hint": "a"},
        "b": {"name": "b", "type": "float", "min": 0.0, "max": 2.0, "default": 1.0, "label": "B", "hint": "b"},
    }
    return [table[n] for n in order] + [{"name": "bypass", "type": "bypass"}]


def _defn(order=("a", "b"), **extra):
    d = {"name": "f_t", "prefix": "t", "object_name": "t_pix", "title": "Test", "signal_type": "texture",
         "archetype": "processor", "pix_type": "char", "presentation_width": 120, "presentation_height": 90,
         "outlets": [{"comment": "texture"}], "params": _params(order),
         "codebox": "Param a(0.5);\nParam b(1.0);\nParam bypass(0.0);\nout1 = in1 * a * b;"}
    d.update(extra)
    return d


DEF_SOURCE = '''# f_t test definition -- a comment the capture tool must never touch
patcher = {
    "name": "f_t", "prefix": "t", "object_name": "t_pix", "title": "Test", "signal_type": "texture",
    "archetype": "processor", "pix_type": "char", "presentation_width": 120, "presentation_height": 90,
    "outlets": [{"comment": "texture"}],
    "params": [
        {"name": "a", "type": "float", "min": 0.0, "max": 1.0, "default": 0.5, "label": "A", "hint": "a"},
        {"name": "b", "type": "float", "min": 0.0, "max": 2.0, "default": 1.0, "label": "B", "hint": "b"},
        {"name": "bypass", "type": "bypass"},
    ],
    "codebox": "Param a(0.5);\\nParam b(1.0);\\nParam bypass(0.0);\\nout1 = in1 * a * b;",
}
'''


def _build(defn):
    dbg = {}
    out = json.loads(json.dumps(bp.build(defn, debug=dbg)))
    return out, dbg["element_keys"]


def _box(out, keys, key):
    bid = keys[key]
    return [b["box"] for b in out["patcher"]["boxes"] if b["box"]["id"] == bid][0]


# ---- element keys

def test_element_keys_are_name_based_unique_and_present():
    out, keys = _build(_defn())
    have = {b["box"]["id"] for b in out["patcher"]["boxes"]}
    present = {k for k, i in keys.items() if i in have}
    for k in ("a.ctl", "a.label", "b.ctl", "b.label", "panel", "title", "signal_type", "outlet.0",
              "pix.0", "bypass_jsui"):
        _eq(f"element key {k!r} exists and its box is generated", k in present, True)
    _eq("keys are unique by construction", len(set(keys.values())), len(keys))
    swapped, skeys = _build(_defn(order=("b", "a")))
    _eq("the key `a.ctl` finds parameter a in both orders",
        (drift._longname(_box(out, keys, "a.ctl")), drift._longname(_box(swapped, skeys, "a.ctl"))),
        ("a", "a"))
    _eq("...although its box id moves when the params are reordered",
        keys["a.ctl"] != skeys["a.ctl"], True)


# ---- applying overrides

def test_apply_overrides_sets_and_removes_and_touches_nothing_else():
    base, keys = _build(_defn())
    ov = {"a.ctl": {"presentation_rect": [1.0, 2.0, 3.0, 4.0], "hint": "changed"},
          "title": {"fontsize": None}}
    new, _ = _build(_defn(overrides=ov))
    _eq("a property is set", _box(new, keys, "a.ctl")["presentation_rect"], [1.0, 2.0, 3.0, 4.0])
    _eq("another property of the same box is set", _box(new, keys, "a.ctl")["hint"], "changed")
    _eq("None removes a property", "fontsize" in _box(new, keys, "title"), False)
    _eq("it was there before", "fontsize" in _box(base, keys, "title"), True)
    changed = [b["box"]["id"] for b, n in zip(base["patcher"]["boxes"], new["patcher"]["boxes"]) if b != n]
    _eq("exactly the two overridden boxes differ", sorted(changed),
        sorted([keys["a.ctl"], keys["title"]]))
    _eq("the cords are untouched", base["patcher"]["lines"], new["patcher"]["lines"])
    shared = {"a.ctl": {"presentation_rect": [1.0, 2.0, 3.0, 4.0]}}
    dbg = {}
    raw = bp.build(_defn(overrides=shared), debug=dbg)           # no JSON round-trip: that would copy
    box = [b["box"] for b in raw["patcher"]["boxes"] if b["box"]["id"] == dbg["element_keys"]["a.ctl"]][0]
    shared["a.ctl"]["presentation_rect"][0] = 99.0
    _eq("the built box does not alias the definition's value", box["presentation_rect"][0], 1.0)


def test_apply_overrides_is_loud():
    def b(ov):
        return lambda: bp.build(_defn(overrides=ov))
    _raises("an unknown element", b({"nope.ctl": {"hint": "x"}}), "unknown element")
    _raises("an element this build did not generate (no panel_toggle here)",
            b({"panel_toggle": {"hint": "x"}}), "not part of this build")
    for prop in ("patching_rect", "id", "maxclass", "patcher"):
        _raises(f"denied property {prop!r}", b({"a.ctl": {prop: 1}}), "cannot be overridden")
    _raises("an empty property dict", b({"a.ctl": {}}), "non-empty")
    _raises("a non-dict value", b({"a.ctl": ["hint"]}), "non-empty")


# ---- capture

def _scene(tmp, edit=None, definition=DEF_SOURCE):
    """A temp definition.py, and a 'shipped' patcher = the base build with `edit(out, keys)` applied."""
    dp = Path(tmp) / "definition.py"
    dp.write_text(definition)
    out, keys = _build(bp.load_definition(dp))
    if edit:
        edit(out, keys)
    sp = Path(tmp) / "shipped.maxpat"
    sp.write_text(json.dumps(out))
    return dp, sp


def _drift_after(dp, sp):
    defn = bp.load_definition(dp)
    counts, _ = drift.compare(bp.build(defn)["patcher"], json.load(open(sp))["patcher"])
    return {k: v for k, v in counts.items() if v}


def _hand_tuned(out, keys):
    _box(out, keys, "a.ctl")["presentation_rect"] = [10.0, 40.0, 25.0, 23.0]
    _box(out, keys, "a.ctl")["appearance"] = 1
    _box(out, keys, "b.label")["textcolor"] = [1.0, 0.0, 0.0, 1.0]
    _box(out, keys, "title").pop("fontsize", None)


def test_capture_writes_presentation_state_and_the_rebuild_then_matches():
    with tempfile.TemporaryDirectory() as tmp:
        dp, sp = _scene(tmp, _hand_tuned)
        _eq("before capture the hand tuning is drift", bool(_drift_after(dp, sp)), True)
        pl = capture.capture(dp, sp, out=lambda *_: None)
        _eq("captured elements", sorted(pl["captured"]), ["a.ctl", "b.label", "title"])
        _eq("a.ctl: rect and appearance", sorted(pl["captured"]["a.ctl"]), ["appearance", "presentation_rect"])
        _eq("a property the shipped patch lacks is captured as None (removal)",
            pl["captured"]["title"], {"fontsize": None})
        _eq("after capture, rebuilding from the definition reproduces the patcher exactly",
            _drift_after(dp, sp), {})


def test_capture_is_idempotent_and_touches_only_its_block():
    with tempfile.TemporaryDirectory() as tmp:
        dp, sp = _scene(tmp, _hand_tuned)
        original = dp.read_text()
        capture.capture(dp, sp, out=lambda *_: None)
        first = dp.read_text()
        _eq("everything before the block is byte-identical", first.startswith(original), True)
        _eq("the block is delimited", capture.BEGIN in first and first.rstrip().endswith(capture.END), True)
        capture.capture(dp, sp, out=lambda *_: None)
        _eq("a second capture changes nothing (byte-identical)", dp.read_text(), first)
        _eq("and says so", capture.write_block(dp, bp.load_definition(dp)["overrides"]), False)


def test_capture_removes_the_block_when_nothing_is_left_to_capture():
    with tempfile.TemporaryDirectory() as tmp:
        dp, sp = _scene(tmp, _hand_tuned)
        original = dp.read_text()
        capture.capture(dp, sp, out=lambda *_: None)
        sp.write_text(json.dumps(_build(bp.load_definition(dp).__class__(
            {k: v for k, v in bp.load_definition(dp).items() if k != "overrides"}))[0]))
        capture.capture(dp, sp, out=lambda *_: None)
        _eq("the patcher now equals the base build: the block is gone, the file is as it was",
            dp.read_text(), original)


def test_capture_refuses_to_freeze_definition_owned_or_builder_ahead_differences():
    def edit(out, keys):
        _box(out, keys, "a.label").pop("varname", None)            # builder ahead of the patch
        _box(out, keys, "a.ctl")["hint"] = "edited in Max"          # a definition value
        _box(out, keys, "title")["text"] = "Renamed in Max"         # a definition value
        _box(out, keys, "title")["fontsize"] = 14.0                 # presentation, on a renamed box
        v = _box(out, keys, "b.ctl")["saved_attribute_attributes"]["valueof"]
        v["parameter_mmax"] = 5.0                                   # a definition value (range)
        _box(out, keys, "b.label")["textcolor"] = [0.1, 0.2, 0.3, 1.0]   # presentation: captured
    with tempfile.TemporaryDirectory() as tmp:
        dp, sp = _scene(tmp, edit)
        pl = capture.capture(dp, sp, out=lambda *_: None)
        refused = {(k, p) for k, p, _, _ in pl["not_captured"]}
        _eq("varname, hint, range and a label renamed in Max are all refused, and reported",
            {("a.label", "varname"), ("a.ctl", "hint"), ("b.ctl", "saved_attribute_attributes"),
             ("title", "text")} <= refused, True)
        _eq("only presentation properties are written (a renamed box still gets its fontsize)",
            pl["captured"], {"b.label": {"textcolor": [0.1, 0.2, 0.3, 1.0]}, "title": {"fontsize": 14.0}})
        _eq("every refusal carries a reason", all(capture._why_not(p) for _, p, _, _ in pl["not_captured"]), True)
        left = _drift_after(dp, sp)
        _eq("what is left is exactly the refused differences (a rename, props), no layout",
            "layout" not in left and left.get("props", 0) >= 3, True)


def test_capture_takes_a_text_buttons_colours_and_rounding_but_not_its_labels():
    src = DEF_SOURCE.replace(
        '        {"name": "bypass", "type": "bypass"},',
        '        {"name": "m", "type": "text_button", "options": ["full", "mask"], "default": 1,'
        ' "label": "M", "hint": "m"},\n        {"name": "bypass", "type": "bypass"},'
    ).replace("Param bypass(0.0);", "Param m(1.0);\\nParam bypass(0.0);")

    def tune(out, keys):
        b = _box(out, keys, "m.ctl")
        b["activebgcolor"] = [0.07, 0.06, 0.06, 1.0]
        b["activebgoncolor"] = [0.07, 0.06, 0.06, 1.0]
        b["activetextcolor"] = [0.76, 0.76, 0.76, 1.0]
        b["activetextoncolor"] = [0.66, 0.66, 0.66, 1.0]
        b["rounded"] = 4.0
    with tempfile.TemporaryDirectory() as tmp:
        dp, sp = _scene(tmp, tune, definition=src)
        _eq("before capture the hand-set colours are drift", bool(_drift_after(dp, sp)), True)
        pl = capture.capture(dp, sp, out=lambda *_: None)
        _eq("the four colours and the rounding are captured, on the toggle only",
            {k: sorted(v) for k, v in pl["captured"].items()},
            {"m.ctl": ["activebgcolor", "activebgoncolor", "activetextcolor", "activetextoncolor", "rounded"]})
        _eq("after capture, rebuilding from the definition reproduces the patcher exactly",
            _drift_after(dp, sp), {})

    def relabel(out, keys):
        _box(out, keys, "m.ctl")["texton"] = "changed in Max"       # the button's label: a definition value
    with tempfile.TemporaryDirectory() as tmp:
        dp, sp = _scene(tmp, relabel, definition=src)
        pl = capture.capture(dp, sp, out=lambda *_: None)
        _eq("a live.text's label text is still refused, not captured",
            ("m.ctl", "texton") in {(k, p) for k, p, _, _ in pl["not_captured"]} and "m.ctl" not in pl["captured"],
            True)


def test_capture_keeps_an_override_whose_element_left_the_shipped_patch():
    def edit(out, keys):
        gone = keys["b.label"]
        out["patcher"]["boxes"] = [b for b in out["patcher"]["boxes"] if b["box"]["id"] != gone]
        out["patcher"]["lines"] = [l for l in out["patcher"]["lines"]
                                   if gone not in (l["patchline"]["source"][0], l["patchline"]["destination"][0])]
    source = DEF_SOURCE + capture.render_block({"b.label": {"textcolor": [1.0, 0.0, 0.0, 1.0]}})
    with tempfile.TemporaryDirectory() as tmp:
        dp, sp = _scene(tmp, edit, definition=source)
        msgs = []
        pl = capture.capture(dp, sp, out=msgs.append)
        _eq("the unmatched element's override is kept as it was", pl["kept"],
            {"b.label": {"textcolor": [1.0, 0.0, 0.0, 1.0]}})
        _eq("and it is still in the file", "b.label" in dp.read_text(), True)
        _eq("and the user is told", any("kept: b.label" in m for m in msgs), True)


def test_capture_warns_about_an_override_that_names_no_element():
    source = DEF_SOURCE + capture.render_block({"nope.ctl": {"hint": "x"}})
    with tempfile.TemporaryDirectory() as tmp:
        dp = Path(tmp) / "definition.py"
        dp.write_text(source)
        out, _ = _build({k: v for k, v in bp.load_definition(dp).items() if k != "overrides"})
        sp = Path(tmp) / "shipped.maxpat"
        sp.write_text(json.dumps(out))
        msgs = []
        pl = capture.capture(dp, sp, dry_run=True, out=msgs.append)
        _eq("an unknown key is reported, not silently dropped",
            pl["unknown"] == ["nope.ctl"] and any("WARNING" in m for m in msgs), True)


def test_render_block_is_deterministic_valid_python():
    ov = {"b.ctl": {"hint": 'say "hi"', "presentation_rect": [1.0, 2.5, 3.0, 4.0]},
          "a.label": {"fontsize": None, "textcolor": [0.1, 0.2, 0.3, 1.0], "hidden": 1}}
    block = capture.render_block(ov)
    ns = {"patcher": {}}
    exec(block, ns)
    _eq("it round-trips through exec", ns["patcher"]["overrides"], ov)
    _eq("it is order-independent", capture.render_block(dict(reversed(list(ov.items())))), block)
    _eq("keys are sorted", block.index('"a.label"') < block.index('"b.ctl"'), True)


if __name__ == "__main__":
    sys.exit(run(globals()))
