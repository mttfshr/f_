#!/opt/homebrew/bin/python3.13
"""
generate_launch.py -- generate package/extras/f_Launch.maxpat from the README Patches table.

f_Launch is the package homepatcher (package-info.json "homepatcher"): the Package Manager
"Launch" button and the Extras menu open it. One tab per README group, one row per module.
A module with package/help/<name>.maxhelp gets a clickable name that opens that helpfile
(textbutton -> "loadunique <name>.maxhelp" -> pcontrol); a module without one gets plain grey
text, because a click on a missing helpfile fails silently in Max.

Source of truth: the README "## Patches" table. Never hand-edit f_Launch.maxpat -- edit the
README and regenerate.

Usage:
    build/py.sh build/generate_launch.py            # write package/extras/f_Launch.maxpat
    build/py.sh build/generate_launch.py --check    # exit 1 if the file is stale or a check fails

Checks (any failure aborts, nothing is written):
    - every Patches row parses; no duplicate module names; no empty group
    - README rows and package/patchers/*.maxpat match in both directions
    - every description is at most MAX_DESC characters
"""

import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).parent.parent
README = REPO_ROOT / "README.md"
PATCHERS_DIR = REPO_ROOT / "package" / "patchers"
HELP_DIR = REPO_ROOT / "package" / "help"
OUT = REPO_ROOT / "package" / "extras" / "f_Launch.maxpat"

MAX_DESC = 110
APP = {"major": 9, "minor": 1, "revision": 4, "architecture": "x64", "modernui": 1}
GREY = [0.55, 0.55, 0.55, 1.0]

# Layout (pixels). One-liners are at most 110 characters: about 720 px at 12 pt.
ROW_H, TOP = 28, 12
NAME_X, NAME_W = 10, 210
DESC_X, DESC_W = 230, 720
WIN_W, WIN_H_MAX = 960, 700


class LaunchError(Exception):
    pass


def parse_readme(text):
    """Return [(heading, [(name, description), ...]), ...] from the Patches table."""
    if "## Patches" not in text:
        raise LaunchError('README has no "## Patches" section')
    section = text.split("## Patches", 1)[1].split("\n## ", 1)[0]
    groups = []
    for line in section.splitlines():
        m = re.match(r"^###\s+(.+?)\s*$", line)
        if m:
            groups.append((m.group(1), []))
            continue
        if not line.startswith("|"):
            continue
        if re.match(r"^\|\s*Patch\s*\|\s*Description\s*\|\s*$", line) or re.match(r"^\|[\s\-|:]+\|\s*$", line):
            continue
        m = re.match(r"^\|\s*`([^`]+)`\s*\|\s*(.+?)\s*\|\s*$", line)
        if not m:
            raise LaunchError(f"Patches table: cannot parse row: {line!r}")
        if not groups:
            raise LaunchError(f"Patches table: row before any ### heading: {line!r}")
        groups[-1][1].append((m.group(1), m.group(2)))
    return groups


def validate(groups):
    problems = []
    names = [n for _, rows in groups for n, _ in rows]
    for n in sorted({x for x in names if names.count(x) > 1}):
        problems.append(f"duplicate row: {n}")
    for heading, rows in groups:
        if not rows:
            problems.append(f"empty group: {heading!r}")
    on_disk = {p.stem for p in PATCHERS_DIR.glob("*.maxpat")}
    for n in sorted(set(names) - on_disk):
        problems.append(f"in README table but no package/patchers/{n}.maxpat")
    for n in sorted(on_disk - set(names)):
        problems.append(f"patcher {n}.maxpat has no README table row")
    for _, rows in groups:
        for n, d in rows:
            if len(d) > MAX_DESC:
                problems.append(f"{n}: description is {len(d)} chars (limit {MAX_DESC})")
    labels = [tab_label(h) for h, _ in groups]
    for lab in sorted({x for x in labels if labels.count(x) > 1}):
        problems.append(f"two groups give the same tab label: {lab!r}")
    if problems:
        raise LaunchError("\n  ".join(["checks failed:"] + problems))


def tab_label(heading):
    """README heading -> tab label: drop backticks and parentheticals."""
    label = re.sub(r"\([^)]*\)", "", heading.replace("`", ""))
    return re.sub(r"\s+", " ", label).strip()


def tab_box_text(label):
    return f'p "{label}"' if " " in label else f"p {label}"


def display(desc):
    return desc.replace("`", "")


def build_tab(rows):
    boxes = [{"box": {"id": "obj-1", "maxclass": "newobj", "numinlets": 1, "numoutlets": 1,
                      "outlettype": [""], "patching_rect": [420.0, 20.0, 60.0, 22.0], "text": "pcontrol"}}]
    lines = []
    n = 2
    for i, (name, desc) in enumerate(rows):
        y = float(TOP + ROW_H * i)
        clickable = (HELP_DIR / f"{name}.maxhelp").exists()
        py = 20.0 + 60 * i  # patching-view position (hidden: tabs open in presentation mode)
        if clickable:
            btn, msg = f"obj-{n}", f"obj-{n + 1}"
            boxes.append({"box": {"id": btn, "maxclass": "textbutton", "numinlets": 1, "numoutlets": 3,
                                  "outlettype": ["", "", "int"], "parameter_enable": 0, "fontsize": 12.0,
                                  "patching_rect": [20.0, py, 150.0, 22.0], "text": name,
                                  "presentation": 1, "presentation_rect": [float(NAME_X), y, float(NAME_W), 22.0]}})
            boxes.append({"box": {"id": msg, "maxclass": "message", "numinlets": 2, "numoutlets": 1,
                                  "outlettype": [""], "patching_rect": [20.0, py + 28, 230.0, 22.0],
                                  "text": f"loadunique {name}.maxhelp"}})
            lines.append({"patchline": {"source": [btn, 0], "destination": [msg, 0]}})
            lines.append({"patchline": {"source": [msg, 0], "destination": ["obj-1", 0]}})
            n += 2
        else:
            boxes.append({"box": {"id": f"obj-{n}", "maxclass": "comment", "numinlets": 1, "numoutlets": 0,
                                  "patching_rect": [20.0, py, 150.0, 20.0], "text": name, "textcolor": GREY,
                                  "presentation": 1,
                                  "presentation_rect": [float(NAME_X), y + 2, float(NAME_W), 20.0]}})
            n += 1
        desc_box = {"id": f"obj-{n}", "maxclass": "comment", "numinlets": 1, "numoutlets": 0,
                    "patching_rect": [260.0, py, 150.0, 20.0], "text": display(desc),
                    "presentation": 1, "presentation_rect": [float(DESC_X), y + 2, float(DESC_W), 20.0]}
        if not clickable:
            desc_box["textcolor"] = GREY
        boxes.append({"box": desc_box})
        n += 1
    return boxes, lines


def build_patcher(groups):
    height = min(max(len(rows) for _, rows in groups) * ROW_H + 2 * TOP + 4, WIN_H_MAX)
    root_boxes = []
    for i, (heading, rows) in enumerate(groups):
        label = tab_label(heading)
        boxes, lines = build_tab(rows)
        var = "tab_" + re.sub(r"[^a-z0-9]+", "_", label.lower()).strip("_")
        inner = {"fileversion": 1, "appversion": APP, "classnamespace": "box",
                 "rect": [0.0, 26.0, float(WIN_W), float(height)], "openinpresentation": 1,
                 "gridsize": [15.0, 15.0], "enablevscroll": 1, "enablehscroll": 0, "showontab": 1,
                 "boxes": boxes, "lines": lines}
        root_boxes.append({"box": {"id": f"obj-{i + 1}", "maxclass": "newobj", "numinlets": 0, "numoutlets": 0,
                                   "patching_rect": [30.0 + 190 * i, 40.0, 170.0, 22.0],
                                   "text": tab_box_text(label), "varname": var, "patcher": inner}})
    return {"patcher": {"fileversion": 1, "appversion": APP, "classnamespace": "box",
                        "rect": [100.0, 100.0, float(WIN_W), float(height + 26)], "gridsize": [15.0, 15.0],
                        "showrootpatcherontab": 0, "showontab": 0, "boxes": root_boxes, "lines": []}}


def generate():
    """Return (file text, summary string). Raises LaunchError if any check fails."""
    groups = parse_readme(README.read_text(encoding="utf-8"))
    validate(groups)
    text = json.dumps(build_patcher(groups), indent="\t", ensure_ascii=False) + "\n"
    rows = [(n, d) for _, g in groups for n, d in g]
    clickable = sum((HELP_DIR / f"{n}.maxhelp").exists() for n, _ in rows)
    summary = (f"{len(groups)} tabs, {len(rows)} modules: {clickable} clickable, "
               f"{len(rows) - clickable} greyed (no helpfile), {sum('⚠' in d for _, d in rows)} marked ⚠")
    return text, summary


def main(argv):
    try:
        text, summary = generate()
    except LaunchError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 1
    if "--check" in argv:
        if not OUT.exists():
            print(f"STALE: {OUT.relative_to(REPO_ROOT)} does not exist; run build/py.sh build/generate_launch.py")
            return 1
        if OUT.read_text(encoding="utf-8") != text:
            print(f"STALE: {OUT.relative_to(REPO_ROOT)} differs from the README; run build/py.sh build/generate_launch.py")
            return 1
        print(f"up to date: {summary}")
        return 0
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(text, encoding="utf-8")
    print(f"wrote {OUT.relative_to(REPO_ROOT)}: {summary}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
