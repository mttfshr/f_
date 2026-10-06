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
         "NOT_IN_MENU": copy.deepcopy(m.NOT_IN_MENU), "NABLA": m.NABLA}
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
        _eq(f"{label}: displays carry the nabla mark exactly when vecfield",
            disp["saved_attribute_attributes"]["valueof"]["parameter_enum"],
            [d + (menu.NABLA if vf else "") for d, _, vf in items])
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


def test_the_old_menu_scripts_are_gone():
    _eq("tools/ is removed", (ROOT / "tools").exists(), False)
    _eq("the 5-category build_modules.py is removed", (ROOT / "build" / "tools").exists(), False)


# ---- the checks are loud

def test_validate_accepts_the_shipped_data():
    _eq("no problems", problem_text(fresh_menu()), "")


def test_validate_catches_each_kind_of_mistake():
    m = fresh_menu()
    cats = lambda: copy.deepcopy(m.CATEGORIES)

    c = cats(); c[0][1].append(("Weave2", "weave", True))
    _eq("a module in two categories", "module listed twice: weave" in problem_text(fresh_menu(CATEGORIES=c)), True)

    c = cats(); c[0][1][0] = ("Ghost", "ghost", True)
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

    c = cats(); c[4][1][0] = ("Vortex", "vf_vortex", False)
    _eq("a nabla category with an unflagged module", "not flagged vecfield" in problem_text(fresh_menu(CATEGORIES=c)), True)

    c = cats(); c[1][1].append(("Stipple", "texrouter", False))
    _eq("two entries shown with the same name", "two entries are shown as 'Stipple'" in problem_text(fresh_menu(CATEGORIES=c)), True)

    c = cats(); c[0] = (c[0][0], [])
    _eq("an empty category", "empty category" in problem_text(fresh_menu(CATEGORIES=c)), True)

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

    for label, bad, needle in (("a non-bool vecfield flag", [("L", [("A", "chladni", "yes")])], "a menu entry must be"),
                               ("a 2-tuple entry", [("L", [("A", "chladni")])], "a menu entry must be"),
                               ("an empty display name", [("L", [("", "chladni", True)])], "a menu entry must be"),
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
