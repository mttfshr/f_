"""
test_launch.py -- offline checks of build/generate_launch.py and the committed
package/extras/f_Launch.maxpat (the package homepatcher). No Max needed.

Two layers, like the rest of tests/:
  1. the committed file against the README and the package: up to date, valid structure,
     every module listed exactly once, a name is clickable iff its helpfile exists, and each
     button is wired button -> "loadunique <name>.maxhelp" -> pcontrol
  2. mutation checks that the generator's validation really does reject a too-long
     description, a duplicate row, a README row with no patcher, an unparseable row, ...

Run:  tests/run.sh tests/test_launch.py
If test 1 fails with "stale": edit the README, then regenerate
  build/py.sh build/generate_launch.py
"""
import copy
import json
import os
import sys

from harness import check, run

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "build"))
import generate_launch as gl      # noqa: E402


def _groups():
    return gl.parse_readme(gl.README.read_text(encoding="utf-8"))


def _committed():
    return json.loads(gl.OUT.read_text(encoding="utf-8"))["patcher"]


def _raises(fn, *args):
    try:
        fn(*args)
    except gl.LaunchError:
        return 1
    return 0


def _scope_problems(scope):
    ids = [b["box"]["id"] for b in scope["boxes"]]
    idset = set(ids)
    dup = [x for x in idset if ids.count(x) > 1]
    dangling = [e for ln in scope.get("lines", [])
                for e in (ln["patchline"]["source"][0], ln["patchline"]["destination"][0]) if e not in idset]
    return len(dup) + len(dangling)


def _tabs(d):
    return [b["box"] for b in d["boxes"]]


def _name_boxes(tab):
    """The per-row name boxes: a textbutton (clickable) or a grey comment (no helpfile)."""
    return [b["box"] for b in tab["patcher"]["boxes"]
            if b["box"].get("presentation_rect", [None])[0] == gl.NAME_X]


def test_committed_file_is_current():
    text, _ = gl.generate()
    on_disk = gl.OUT.read_text(encoding="utf-8") if gl.OUT.exists() else ""
    check("f_Launch.maxpat differs from a fresh generate (stale if 1)", 0 if on_disk == text else 1, 0)


def test_structure():
    d = _committed()
    groups = _groups()
    check("root patcher hidden from tabs (showrootpatcherontab)", d.get("showrootpatcherontab"), 0)
    check("tab count equals README group count", len(_tabs(d)), len(groups))
    check("every tab patcher has showontab 1", sum(t["patcher"].get("showontab") != 1 for t in _tabs(d)), 0)
    check("root scope: duplicate ids + dangling lines", _scope_problems(d), 0)
    check("tab scopes: duplicate ids + dangling lines", sum(_scope_problems(t["patcher"]) for t in _tabs(d)), 0)
    want_labels = [gl.tab_box_text(gl.tab_label(h)) for h, _ in groups]
    check("tab labels not matching README group order (1 = mismatch)",
          0 if [t["text"] for t in _tabs(d)] == want_labels else 1, 0)


def test_every_module_listed_exactly_once():
    d = _committed()
    listed = [b["text"] for t in _tabs(d) for b in _name_boxes(t)]
    want = {n for _, rows in _groups() for n, _ in rows}
    check("modules listed but not in the README, or in the README but not listed", len(set(listed) ^ want), 0)
    check("module names listed more than once", len(listed) - len(set(listed)), 0)
    on_disk = {p.stem for p in gl.PATCHERS_DIR.glob("*.maxpat")}
    check("modules listed but not in package/patchers, or the reverse", len(set(listed) ^ on_disk), 0)


def test_clickable_iff_helpfile_and_wired():
    d = _committed()
    wrong_kind = unwired = 0
    for t in _tabs(d):
        boxes = {b["box"]["id"]: b["box"] for b in t["patcher"]["boxes"]}
        out = {}
        for ln in t["patcher"]["lines"]:
            pl = ln["patchline"]
            out.setdefault(pl["source"][0], []).append(pl["destination"][0])
        for nb in _name_boxes(t):
            name = nb["text"]
            has_help = (gl.HELP_DIR / f"{name}.maxhelp").exists()
            if (nb["maxclass"] == "textbutton") != has_help:
                wrong_kind += 1
                continue
            if nb["maxclass"] == "textbutton":
                msgs = [boxes[x] for x in out.get(nb["id"], [])]
                ok = (len(msgs) == 1 and msgs[0]["text"] == f"loadunique {name}.maxhelp"
                      and any(boxes[y]["text"] == "pcontrol" for y in out.get(msgs[0]["id"], [])))
                unwired += 0 if ok else 1
    check("names whose clickable/greyed state disagrees with helpfile existence", wrong_kind, 0)
    check("buttons not wired button -> loadunique <name>.maxhelp -> pcontrol", unwired, 0)


def test_validation_rejects_bad_readmes():
    good = _groups()
    check("real README passes validate()", 0 if not _raises(gl.validate, good) else 1, 0)

    long_desc = copy.deepcopy(good)
    long_desc[0][1][0] = (long_desc[0][1][0][0], "x" * (gl.MAX_DESC + 1))
    check("description over the limit is rejected", _raises(gl.validate, long_desc), 1)

    dup = copy.deepcopy(good)
    dup[0][1].append(dup[0][1][0])
    check("duplicate row is rejected", _raises(gl.validate, dup), 1)

    ghost = copy.deepcopy(good)
    ghost[0][1].append(("f_no_such_patcher", "A row with no patcher behind it"))
    check("README row with no patcher is rejected", _raises(gl.validate, ghost), 1)

    dropped = copy.deepcopy(good)
    dropped[0][1].pop(0)
    check("patcher with no README row is rejected", _raises(gl.validate, dropped), 1)

    empty = copy.deepcopy(good) + [("Empty group", [])]
    check("empty group is rejected", _raises(gl.validate, empty), 1)

    same_label = copy.deepcopy(good) + [("Generators (again)", [good[0][1][0]])]
    check("two headings with one tab label are rejected", _raises(gl.validate, same_label), 1)


def test_parse_rejects_malformed_table():
    bad_row = "## Patches\n\n### G\n\n| Patch | Description |\n|---|---|\n| f_x | missing backticks |\n"
    check("row without backticked name is rejected", _raises(gl.parse_readme, bad_row), 1)
    orphan = "## Patches\n\n| `f_x` | row before any heading |\n"
    check("row before any ### heading is rejected", _raises(gl.parse_readme, orphan), 1)
    check("README without a Patches section is rejected", _raises(gl.parse_readme, "# nothing here\n"), 1)


def _menu_categories():
    """Shipped f_modules.maxpat -> {category label: [module names]} in menu order.
    That patcher is what users see; since build_cleanup T021 it is generated by
    build/generate_menu.py from src/f_modules/menu.py."""
    fm = json.loads((gl.PATCHERS_DIR / "f_modules.maxpat").read_text(encoding="utf-8"))["patcher"]
    cats, cur = {}, None
    for b in fm["boxes"]:
        bx = b["box"]
        if bx.get("maxclass") == "comment" and bx.get("text") != "f_":
            cur = bx["text"]
        elif bx.get("maxclass") == "live.menu":
            v = bx.get("saved_attribute_attributes", {}).get("valueof", {})
            if v.get("parameter_longname", "").endswith("_file"):
                cats[cur] = ["f_" + x for x in v["parameter_enum"]]
    return cats


def test_categories_match_f_modules_menu():
    cats = _menu_categories()
    groups = _groups()
    headings = [h for h, _ in groups]
    readme = {n: h for h, rows in groups for n, _ in rows}
    check("f_modules menu categories parsed (0 = found)", 0 if cats else 1, 0)
    check("menu modules filed under a different README heading than their menu category",
          sum(1 for c, L in cats.items() for n in L if readme.get(n) != c), 0)
    check("README headings not in menu order (1 = mismatch)",
          0 if headings[:len(cats)] == list(cats) else 1, 0)
    allowed = set(cats) | {h for h in headings if h.startswith("Audio")}
    check("README headings that are neither a menu category nor Audio",
          len([h for h in headings if h not in allowed]), 0)


def test_tab_labels():
    check("backticks and parenthetical not stripped (1 = wrong)",
          0 if gl.tab_label("Audio (`gen~`)") == "Audio" else 1, 0)
    check("plain heading changed (1 = wrong)", 0 if gl.tab_label("Scope") == "Scope" else 1, 0)
    check("glyph heading altered (1 = wrong)",
          0 if gl.tab_label("∇ Generators") == "∇ Generators" else 1, 0)
    check("label with spaces not given the quoted box text (1 = wrong)",
          0 if gl.tab_box_text(gl.tab_label("Color / Tone")) == 'p "Color / Tone"' else 1, 0)
    check("glyph label not quoted (1 = wrong)",
          0 if gl.tab_box_text(gl.tab_label("∇ Processors")) == 'p "∇ Processors"' else 1, 0)
    check("label without spaces wrongly quoted (1 = wrong)",
          0 if gl.tab_box_text("Audio") == "p Audio" else 1, 0)


if __name__ == "__main__":
    sys.exit(run(globals()))
