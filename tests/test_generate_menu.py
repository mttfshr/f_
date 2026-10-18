"""
test_generate_menu.py -- build/generate_menu.py (build_cleanup T020/T021, 2026-10-05): the module menu
(package/patchers/f_modules.maxpat) and the SIZES table of package/javascript/f_addmod.js are generated
from src/f_modules/menu.py, checked against the README Patches table, and never hand-edited.

    tests/run.sh tests/test_generate_menu.py
"""
import copy
import json
import re
import sys
from pathlib import Path
from types import SimpleNamespace

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "build"))
import generate_menu as g           # noqa: E402
import generate_launch as launch    # noqa: E402

from harness import check, run      # noqa: E402


def _eq(label, got, want):
    check(label, 0 if got == want else 1, 0)


_REAL_LOAD_MENU = g.load_menu          # tests below replace g.load_menu; fresh_menu must not follow


def fresh_menu(**patch):
    m = _REAL_LOAD_MENU()
    d = {"CATEGORIES": copy.deepcopy(m.CATEGORIES), "SIZE_OVERRIDES": copy.deepcopy(m.SIZE_OVERRIDES),
         "NOT_IN_MENU": copy.deepcopy(m.NOT_IN_MENU), "MARKS": copy.deepcopy(m.MARKS)}
    d.update(patch)
    return SimpleNamespace(**d)


GROUPS = launch.parse_readme((ROOT / "README.md").read_text())


def problem_text(menu):
    try:
        g.validate(menu, GROUPS)
    except g.MenuError as e:
        return str(e)
    return ""


def shipped_patcher():
    return json.loads(g.OUT_PATCHER.read_text())["patcher"]


# ---- the shipped files are the generated ones

def test_the_shipped_menu_and_sizes_are_what_the_generator_writes():
    patcher_text, js_text = g.generate()
    _eq("f_modules.maxpat is byte-identical to the generated one", g.OUT_PATCHER.read_text(), patcher_text)
    _eq("f_addmod.js is identical to the regenerated one", g.OUT_JS.read_text(), js_text)
    _eq("--check exits 0", g.main(["--check"]), 0)
    _eq("an unknown argument is refused", g.main(["--nope"]), 2)


def test_every_menu_module_has_a_size_and_none_is_left_over():
    menu = g.load_menu()
    modules = [m for _, items in menu.CATEGORIES for _, m, _ in items]
    block = g.OUT_JS.read_text().split(g.SIZES_BEGIN)[1].split(g.SIZES_END)[0]
    sizes = {k: [int(a), int(b)] for k, a, b in re.findall(r'"(\w+)":\s*\[\s*(\d+),\s*(\d+)\s*\]', block)}
    _eq("exactly the menu's modules, in menu order", list(sizes), modules)
    for m in modules:
        want = menu.SIZE_OVERRIDES[m][0] if m in menu.SIZE_OVERRIDES else g.panel_size(m)
        _eq(f"{m}: the panel size, or its override", sizes[m], want)
    _eq("the three modules whose content extends past the panel are overridden",
        sorted(menu.SIZE_OVERRIDES), ["chladni", "vf_seeds", "vf_vortex_multi"])


def test_the_menu_patcher_is_wired_the_way_f_addmod_expects():
    p = shipped_patcher()
    boxes = {b["box"]["id"]: b["box"] for b in p["boxes"]}
    menu = g.load_menu()
    live = [b for b in boxes.values() if b["maxclass"] == "live.menu"]
    _eq("two live.menu per category (display and file)", len(live), 2 * len(menu.CATEGORIES))
    for slot, (label, items) in enumerate(menu.CATEGORIES):
        disp = [b for b in live if b["saved_attribute_attributes"]["valueof"]["parameter_longname"] == f"f_module_{slot}_disp"][0]
        file = [b for b in live if b["saved_attribute_attributes"]["valueof"]["parameter_longname"] == f"f_module_{slot}_file"][0]
        _eq(f"{label}: displays carry the mark of every kind the module takes or produces",
            disp["saved_attribute_attributes"]["valueof"]["parameter_enum"],
            [d + "".join(mark for kind, mark in menu.MARKS.items() if kind in kinds) for d, _, kinds in items])
        _eq(f"{label}: the file menu lists the module names",
            file["saved_attribute_attributes"]["valueof"]["parameter_enum"], [m for _, m, _ in items])
        _eq(f"{label}: both menus have mmax = items - 1",
            (disp["saved_attribute_attributes"]["valueof"]["parameter_mmax"],
             file["saved_attribute_attributes"]["valueof"]["parameter_mmax"]), (len(items) - 1,) * 2)
    cords = {(tuple(l["patchline"]["source"]), tuple(l["patchline"]["destination"])) for l in p["lines"]}
    _eq("every cord joins existing boxes", all(s[0] in boxes and d[0] in boxes for s, d in cords), True)
    prepends = [i for i, b in boxes.items() if b.get("text") == "prepend addmod"]
    _eq("each file menu's second outlet -> prepend addmod -> gate inlet 1",
        all(any(s[0] == i and d == ("obj-4", 1) for s, d in cords) for i in prepends) and len(prepends) == len(menu.CATEGORIES), True)
    _eq("every live.menu is a saved parameter", all(i in p["parameters"] for i, b in boxes.items() if b["maxclass"] == "live.menu"), True)


_ONE = "(?:\u2207|T_) (?:in|out|in/out)"
TITLE_LABEL = re.compile(f"^{_ONE}(?: {_ONE})?$")


def title_labels(module):
    """The type labels in a patcher's title bar: presentation comments in the top rows that mention a type."""
    p = json.loads((g.PATCHERS_DIR / f"f_{module}.maxpat").read_text())["patcher"]
    out = []
    for b in p["boxes"]:
        b = b["box"]
        r = b.get("presentation_rect") or [0, 99, 0, 0]
        if b.get("maxclass") == "comment" and b.get("presentation") and r[1] < 26 \
                and re.search("vecfield|tensor|\u2207|T_", str(b.get("text", ""))):
            out.append(b["text"])
    return out


def test_title_bar_labels_use_marks_for_in_and_out_and_agree_with_the_menu_kinds():
    menu = g.load_menu()
    for _, items in menu.CATEGORIES:
        for _, m, kinds in items:
            found = title_labels(m)
            if not kinds:
                _eq(f"{m}: no type marks in the menu, none in the title bar", found, [])
                continue
            _eq(f"{m}: exactly one type label in the title bar", len(found), 1)
            text = found[0]
            _eq(f"{m}: {text!r} reads as marks with in / out / in/out, never the words vecfield or tensor",
                bool(TITLE_LABEL.match(text)), True)
            marks = ({"vec"} if "\u2207" in text else set()) | ({"tensor"} if "T_" in text else set())
            _eq(f"{m}: the title-bar marks equal the menu kinds", marks, set(kinds))


def test_title_bar_labels_say_the_right_direction_for_the_tensor_family():
    want = {"tf_tensormap": "T_ out", "tf_smooth": "T_ in/out", "tf_sharpen": "T_ in/out",
            "tf_aniso_blur": "T_ in", "tf_hatch": "T_ in", "tf_glyph": "T_ in",
            "tf_axisflow": "T_ in \u2207 out", "vf_fluid": "\u2207 in/out", "vf_warp": "\u2207 in",
            "vf_vortex": "\u2207 out", "weave": "\u2207 in",
            "vf_advect": "\u2207 in/out", "vf_prism": "\u2207 in/out"}   # their 3rd outlets carry a vecfield (code audit 2026-10-17)
    for m, text in want.items():
        _eq(f"{m}: title-bar label", title_labels(m), [text])


def test_a_module_with_an_outlet_named_vecfield_or_tensor_says_so_on_its_output_side():
    """The audit that caught advect and prism (a third outlet that is a vecfield, labelled only "in") was done by
    reading the code.  This keeps the cheap part of it: an outlet the module itself names vecfield / tensor means
    the title-bar label must have that mark on its output side (out or in/out)."""
    menu = g.load_menu()
    for _, items in menu.CATEGORIES:
        for _, m, _ in items:
            p = json.loads((g.PATCHERS_DIR / f"f_{m}.maxpat").read_text())["patcher"]
            names = " ".join(str(b["box"].get("comment", "")) for b in p["boxes"] if b["box"].get("maxclass") == "outlet").lower()
            labels = title_labels(m)
            outs = {mark for mark, d in re.findall("(\u2207|T_) (in/out|in|out)", labels[0] if labels else "") if d in ("out", "in/out")}
            if "vecfield" in names:
                _eq(f"{m}: an outlet is named vecfield, so the label outputs \u2207", "\u2207" in outs, True)
            if "tensor" in names:
                _eq(f"{m}: an outlet is named tensor, so the label outputs T_", "T_" in outs, True)


def title_label_boxes(module):
    p = json.loads((g.PATCHERS_DIR / f"f_{module}.maxpat").read_text())["patcher"]
    boxes = [b["box"] for b in p["boxes"]]
    labels = [b for b in boxes if b.get("maxclass") == "comment" and b.get("presentation")
              and (b.get("presentation_rect") or [0, 99])[1] < 26 and TITLE_LABEL.match(str(b.get("text", "")))]
    button = [b for b in boxes if b.get("maxclass") == "jsui" and b.get("varname") == "bypass" and b.get("presentation")]
    return labels, button


def test_title_bar_labels_share_one_look_and_one_place():
    VEC, TENSOR = [0.35, 0.75, 0.95, 1.0], [0.85, 0.55, 0.2, 1.0]
    menu = g.load_menu()
    for _, items in menu.CATEGORIES:
        for _, m, kinds in items:
            if not kinds:
                continue
            labels, button = title_label_boxes(m)
            _eq(f"{m}: one label and one bypass button", (len(labels), len(button)), (1, 1))
            L, rect = labels[0], labels[0]["presentation_rect"]
            _eq(f"{m}: 11 pt", L["fontsize"], 11.0)
            _eq(f"{m}: right-justified", L.get("textjustification"), 2)
            _eq(f"{m}: on the title's baseline (y 0.9 under the 12 pt title at y 0), 70 x 21", (rect[1], rect[2], rect[3]), (0.9, 70.0, 21.0))
            _eq(f"{m}: right edge 4 px left of the bypass button", round(rect[0] + rect[2], 1), round(button[0]["presentation_rect"][0] - 4.0, 1))
            want = VEC if L["text"].startswith("\u2207") else TENSOR
            _eq(f"{m}: colour follows the first mark", [round(c, 3) for c in L["textcolor"]], want)


def frame_border(module):
    p = json.loads((g.PATCHERS_DIR / f"f_{module}.maxpat").read_text())["patcher"]
    panels = [b["box"] for b in p["boxes"] if b["box"].get("maxclass") == "panel" and b["box"].get("presentation")]
    big = max(panels, key=lambda b: b["presentation_rect"][2] * b["presentation_rect"][3])
    return [round(c, 3) for c in big["bordercolor"]]


def title_bar_dots(module):
    """(top dot, bottom dot, the module-name comments sitting right of them, every box id) of a patcher."""
    p = json.loads((g.PATCHERS_DIR / f"f_{module}.maxpat").read_text())["patcher"]
    boxes = {b["box"]["id"]: b["box"] for b in p["boxes"]}
    names = [b for b in boxes.values() if b.get("maxclass") == "comment" and b.get("presentation")
             and b["presentation_rect"][0] == 10.5 and b["presentation_rect"][1] < 8]
    return boxes.get("obj-19f"), boxes.get("obj-19g"), names, boxes


def test_the_type_dots_show_what_each_module_takes_and_outputs():
    """Two stacked round dots left of the module name on EVERY module: top = the type it takes, bottom = the type
    it outputs (cyan vecfield, amber tensor, dim grey neither), read from the title-bar label.  They are foreground
    panels (a background-layer panel is drawn under the frame and vanishes).  The frame border stays dark blue."""
    DARK, VEC, TENSOR, GREY = [0.0, 0.035, 0.227, 1.0], [0.35, 0.75, 0.95, 1.0], [0.85, 0.55, 0.2, 1.0], [0.28, 0.28, 0.28, 1.0]
    colour = {"\u2207": VEC, "T_": TENSOR, None: GREY}
    menu = g.load_menu()
    for _, items in menu.CATEGORIES:
        for _, m, kinds in items:
            labels = title_labels(m)
            ins = outs = None
            for mark, direction in re.findall("(\u2207|T_) (in/out|in|out)", labels[0] if labels else ""):
                ins = mark if direction in ("in", "in/out") else ins
                outs = mark if direction in ("out", "in/out") else outs
            d_in, d_out, names, boxes = title_bar_dots(m)
            _eq(f"{m}: both dots exist and one module name sits to their right", (d_in is not None, d_out is not None, len(names)), (True, True, 1))
            _eq(f"{m}: top dot = what it takes ({ins or 'neither'})", [round(c, 3) for c in d_in["bgcolor"]], colour[ins])
            _eq(f"{m}: bottom dot = what it outputs ({outs or 'neither'})", [round(c, 3) for c in d_out["bgcolor"]], colour[outs])
            r_in, r_out = d_in["presentation_rect"], d_out["presentation_rect"]
            _eq(f"{m}: 5 px dots in one column at x 4, stacked 7 px apart", (r_in[2:], r_out[2:], r_in[0], r_out[0], round(r_out[1] - r_in[1], 3)),
                ([5.0, 5.0], [5.0, 5.0], 4.0, 4.0, 7.0))
            _eq(f"{m}: both dots are round", (d_in.get("rounded"), d_out.get("rounded")), (6, 6))
            _eq(f"{m}: dots are in the foreground layer", (d_in.get("background"), d_out.get("background")), (0, 0))
            _eq(f"{m}: frame border is the standard dark blue", frame_border(m), DARK)


def content_extent(path):
    """((frame w, frame h), (right edge, bottom edge) of everything else shown in presentation)."""
    boxes = [b["box"] for b in json.loads(path.read_text())["patcher"]["boxes"]]
    frame = max((b for b in boxes if b.get("maxclass") == "panel" and b.get("presentation")),
                key=lambda b: b["presentation_rect"][2] * b["presentation_rect"][3])
    right = bottom = 0.0
    for b in boxes:
        if b is frame or not b.get("presentation") or not b.get("presentation_rect"):
            continue
        r = b["presentation_rect"]
        right, bottom = max(right, r[0] + r[2]), max(bottom, r[1] + r[3])
    return tuple(frame["presentation_rect"][2:]), (right, bottom)


def test_the_tensor_modules_are_not_cropped_by_their_frame_or_their_helpfile_embed():
    """f_tf_glyph / hatch / aniso_blur shipped on a 154 x 84 frame and lost their right-hand dials and second row.
    Content may poke 1.5 px past the frame (the 50 px label boxes centre their text); the helpfile's bpatcher
    must be at least as large as the frame."""
    menu = g.load_menu()
    for _, items in menu.CATEGORIES:
        for _, m, _ in items:
            if not m.startswith("tf_"):
                continue
            (fw, fh), (right, bottom) = content_extent(g.PATCHERS_DIR / f"f_{m}.maxpat")
            _eq(f"{m}: content (to {right:.1f} x {bottom:.1f}) fits the {fw:.0f} x {fh:.0f} frame",
                (right <= fw + 1.5, bottom <= fh + 1.5), (True, True))
            help_boxes = [b["box"] for b in json.loads((ROOT / "package" / "help" / f"f_{m}.maxhelp").read_text())["patcher"]["boxes"]]
            embed = [b for b in help_boxes if b.get("maxclass") == "bpatcher" and b.get("name") == f"f_{m}.maxpat"]
            _eq(f"{m}: one embed in its helpfile", len(embed), 1)
            ew, eh = embed[0]["patching_rect"][2:]
            _eq(f"{m}: helpfile embed ({ew:.0f} x {eh:.0f}) is at least the frame size", (ew >= fw, eh >= fh), (True, True))


def test_the_old_menu_scripts_are_gone():
    _eq("tools/ is removed", (ROOT / "tools").exists(), False)
    _eq("the 5-category build_modules.py is removed", (ROOT / "build" / "tools").exists(), False)


# ---- the checks are loud

def test_validate_accepts_the_shipped_data():
    _eq("no problems", problem_text(fresh_menu()), "")


def test_validate_catches_each_kind_of_mistake():
    m = fresh_menu()
    cats = lambda: copy.deepcopy(m.CATEGORIES)

    c = cats(); c[0][1].append(("Weave2", "weave", ("vec",)))
    _eq("a module in two categories", "module listed twice: weave" in problem_text(fresh_menu(CATEGORIES=c)), True)

    c = cats(); c[0][1][0] = ("Ghost", "ghost", ("vec",))
    t = problem_text(fresh_menu(CATEGORIES=c))
    _eq("a menu entry with no patcher", "no package/patchers/f_ghost.maxpat" in t, True)

    c = cats(); c[1] = (c[1][0], [e for e in c[1][1] if e[1] != "masonry"])
    t = problem_text(fresh_menu(CATEGORIES=c))
    _eq("a shipped patcher left out of the menu and out of NOT_IN_MENU",
        "f_masonry.maxpat is neither in the menu nor in NOT_IN_MENU" in t, True)

    c = cats(); c[1] = ("Discrete things", c[1][1])
    _eq("a category the README does not have", "is not a README group" in problem_text(fresh_menu(CATEGORIES=c)), True)

    c = cats(); c[0], c[1] = c[1], c[0]
    _eq("categories in a different order from the README", "differs from the README's" in problem_text(fresh_menu(CATEGORIES=c)), True)

    c = cats(); moved = c[1][1].pop(0); c[2][1].append(moved)
    t = problem_text(fresh_menu(CATEGORIES=c))
    _eq("a module in another category than the README puts it",
        "f_masonry is in menu category 'Spatial' but in another README group" in t
        and "f_masonry is in README group 'Discrete' but not in that menu category" in t, True)

    c = cats(); i = [lab for lab, _ in c].index("\u2207 Generators"); c[i][1][0] = ("Vortex", "vf_vortex", ())
    _eq("a nabla category with an unflagged module", "not flagged vec" in problem_text(fresh_menu(CATEGORIES=c)), True)

    c = cats(); i = [lab for lab, _ in c].index("T_ Tensor"); c[i][1][0] = ("Tensormap", "tf_tensormap", ())
    _eq("a T_ category with an unflagged module",
        "in the tensor category 'T_ Tensor' but not flagged tensor" in problem_text(fresh_menu(CATEGORIES=c)), True)

    c = cats(); i = [lab for lab, _ in c].index("T_ Tensor"); c[i][1][0] = ("Tensormap", "tf_tensormap", ("vec",))
    _eq("a vecfield-only module does not satisfy a T_ category",
        "not flagged tensor" in problem_text(fresh_menu(CATEGORIES=c)), True)

    c = cats(); i = [lab for lab, _ in c].index("T_ Tensor")
    _eq("a module that takes a tensor and makes a vecfield carries both marks and may sit in T_ (f_tf_axisflow)",
        [e[2] for e in c[i][1] if e[1] == "tf_axisflow"], [("vec", "tensor")])

    c = cats(); c[1][1].append(("Stipple", "texrouter", ()))
    _eq("two entries shown with the same name", "two entries are shown as 'Stipple'" in problem_text(fresh_menu(CATEGORIES=c)), True)

    c = cats(); c[0] = (c[0][0], [])
    _eq("an empty category", "empty category" in problem_text(fresh_menu(CATEGORIES=c)), True)

    old_slot = g.SLOT
    try:
        g.SLOT = 43.0                      # the pitch before the T_ category: nine categories no longer fit
        t = problem_text(fresh_menu())
    finally:
        g.SLOT = old_slot
    _eq("a menu taller than its panel is refused (the examples embed it at that size)",
        "the menu panel is 380 px" in t, True)

    skip = dict(m.NOT_IN_MENU); skip["f_vf_vorticity"] = "  "
    _eq("NOT_IN_MENU without a reason", "needs a reason" in problem_text(fresh_menu(NOT_IN_MENU=skip)), True)

    skip = dict(m.NOT_IN_MENU); skip["f_masonry"] = "no"
    _eq("a module both in the menu and in NOT_IN_MENU", "both in the menu and in NOT_IN_MENU" in problem_text(fresh_menu(NOT_IN_MENU=skip)), True)

    skip = dict(m.NOT_IN_MENU); skip["f_nothing"] = "x"
    _eq("NOT_IN_MENU naming a patcher that does not exist", "not a shipped patcher" in problem_text(fresh_menu(NOT_IN_MENU=skip)), True)

    skip = dict(m.NOT_IN_MENU); del skip["f_chladni_audio"]
    t = problem_text(fresh_menu(NOT_IN_MENU=skip))
    _eq("a README group the menu does not show whose module is not exempted",
        "f_chladni_audio" in t and "which the menu does not show" in t, True)

    ov = dict(m.SIZE_OVERRIDES); ov["masonry"] = ([342, 241], "same as the panel")
    _eq("a stale size override (equals the panel)", "stale override" in problem_text(fresh_menu(SIZE_OVERRIDES=ov)), True)

    ov = dict(m.SIZE_OVERRIDES); ov["lens"] = ([1, 2], " ")
    _eq("a size override without a reason", "must be ([w, h], reason)" in problem_text(fresh_menu(SIZE_OVERRIDES=ov)), True)

    ov = dict(m.SIZE_OVERRIDES); ov["wave_table"] = ([1, 2], "x")
    _eq("a size override for a module that is not in the menu", "not in the menu" in problem_text(fresh_menu(SIZE_OVERRIDES=ov)), True)

    c = cats(); c[1] = (c[0][0], c[1][1])
    _eq("two categories with the same label", "duplicate category: 'Scope'" in problem_text(fresh_menu(CATEGORIES=c)), True)

    for label, bad, needle in (("a string where the kinds tuple goes", [("L", [("A", "chladni", "yes")])], "a menu entry must be"),
                               ("the old bool vecfield flag", [("L", [("A", "chladni", True)])], "a menu entry must be"),
                               ("a mark kind that does not exist", [("L", [("A", "chladni", ("spin",))])], "a menu entry must be"),
                               ("a mark kind listed twice", [("L", [("A", "chladni", ("vec", "vec"))])], "a menu entry must be"),
                               ("a 2-tuple entry", [("L", [("A", "chladni")])], "a menu entry must be"),
                               ("an empty display name", [("L", [("", "chladni", ("vec",))])], "a menu entry must be"),
                               ("a category that is not a pair", ["L"], "a category must be"),
                               ("a category list that is empty", [], "non-empty list")):
        msg = ""
        try:
            g.validate(fresh_menu(CATEGORIES=bad), GROUPS)
        except g.MenuError as e:
            msg = str(e)
        _eq(f"malformed data is refused, for the right reason: {label}", needle in msg, True)


def test_a_failed_check_writes_nothing():
    before = (g.OUT_PATCHER.read_bytes(), g.OUT_JS.read_bytes())
    orig = g.load_menu
    try:
        g.load_menu = lambda: fresh_menu(NOT_IN_MENU={})
        code = g.main([])
    finally:
        g.load_menu = orig
    _eq("main fails", code, 1)
    _eq("and neither file changed", (g.OUT_PATCHER.read_bytes(), g.OUT_JS.read_bytes()), before)


def test_check_reports_a_stale_file_and_write_fixes_it():
    import tempfile
    tmp = Path(tempfile.mkdtemp(prefix="f_menu_"))
    real = (g.OUT_PATCHER, g.OUT_JS)
    try:
        for which in ("patcher", "js"):
            p, j = tmp / f"{which}.maxpat", tmp / f"{which}.js"
            p.write_text(real[0].read_text())
            j.write_text(real[1].read_text())
            if which == "patcher":
                p.write_text(p.read_text() + " ")                       # any byte change
            else:                                                       # text outside the block is kept; edit INSIDE it
                text = j.read_text()
                assert "[299, 234]" in text
                j.write_text(text.replace("[299, 234]", "[300, 234]"))
            g.OUT_PATCHER, g.OUT_JS = p, j
            _eq(f"--check fails when the {which} file is stale", g.main(["--check"]), 1)
            _eq(f"a write repairs it", (g.main([]), g.main(["--check"])), (0, 0))
        g.OUT_PATCHER, g.OUT_JS = tmp / "missing.maxpat", real[1]
        _eq("--check fails when the patcher file is missing", g.main(["--check"]), 1)
    finally:
        g.OUT_PATCHER, g.OUT_JS = real


def test_the_js_needs_its_markers():
    raised = False
    try:
        g.new_js("var SIZES = {};", g.load_menu())
    except g.MenuError as e:
        raised = "markers" in str(e)
    _eq("a js file without the markers is refused", raised, True)


if __name__ == "__main__":
    sys.exit(run(globals()))
