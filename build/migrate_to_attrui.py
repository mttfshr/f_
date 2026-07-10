#!/usr/bin/env python3
"""
migrate_to_attrui.py — migrate existing f_ patchers from `prepend param <name>`
to `attrui` objects in-place.

The `attrui` object accepts the same inlet/outlet topology as `prepend param`,
so patchlines are unchanged. Only the box definition is replaced.

Skips `prepend param src_mode` — that object is system-driven (vs_inState
dual-mode) and intentionally uses prepend, not attrui.

Usage:
    python3 build/migrate_to_attrui.py [patcher ...] [--dry-run]

    With no patcher arguments, migrates all .maxpat files in patchers/.
    --dry-run prints what would change without writing.

Examples:
    python3 build/migrate_to_attrui.py                          # all patchers
    python3 build/migrate_to_attrui.py patchers/f_grain.maxpat  # one patcher
    python3 build/migrate_to_attrui.py --dry-run                # preview
"""

import json
import sys
from pathlib import Path

SKIP_NAMES = {"src_mode"}   # prepend param names that must stay as prepend

REPO_ROOT = Path(__file__).parent.parent
PATCHERS_DIR = REPO_ROOT / "patchers"

EXCLUDE_FILES = {"f_menu.maxpat", "f_modules.maxpat", "f_chladni_audio.maxpat"}


def is_prepend_param(box: dict) -> bool:
    return (
        box.get("maxclass") == "newobj"
        and box.get("text", "").startswith("prepend param ")
    )


def param_name_from(box: dict) -> str:
    return box["text"].removeprefix("prepend param ").strip()


def to_attrui(box: dict) -> dict:
    """Return a new box dict replacing prepend param with attrui."""
    name = param_name_from(box)
    rect = box.get("patching_rect", [0.0, 0.0, 100.0, 22.0])
    return {
        "id": box["id"],
        "maxclass": "attrui",
        "attr": name,
        "numinlets": 1,
        "numoutlets": 1,
        "outlettype": [""],
        "patching_rect": rect,
        "style": "",
    }


def migrate_patcher(path: Path, dry_run: bool) -> int:
    """Migrate one .maxpat file. Returns number of boxes changed."""
    with open(path) as f:
        data = json.load(f)

    boxes = data["patcher"]["boxes"]
    changed = 0

    for i, entry in enumerate(boxes):
        box = entry["box"]
        if not is_prepend_param(box):
            continue
        name = param_name_from(box)
        if name in SKIP_NAMES:
            print(f"  SKIP  {box['id']} prepend param {name} (intentional)")
            continue
        if dry_run:
            print(f"  WOULD replace {box['id']} prepend param {name} → attrui")
        else:
            print(f"  replacing {box['id']} prepend param {name} → attrui")
            boxes[i] = {"box": to_attrui(box)}
        changed += 1

    if not dry_run and changed > 0:
        with open(path, "w") as f:
            json.dump(data, f, indent="\t")

    return changed


def main():
    args = sys.argv[1:]
    dry_run = "--dry-run" in args
    args = [a for a in args if a != "--dry-run"]

    if args:
        paths = [Path(a) for a in args]
    else:
        paths = sorted(
            p for p in PATCHERS_DIR.glob("*.maxpat")
            if p.name not in EXCLUDE_FILES
        )

    total = 0
    for path in paths:
        print(f"\n{'[DRY RUN] ' if dry_run else ''}{path.name}")
        n = migrate_patcher(path, dry_run)
        print(f"  → {n} box(es) {'would be ' if dry_run else ''}changed")
        total += n

    print(f"\n{'Would change' if dry_run else 'Changed'} {total} box(es) across {len(paths)} patcher(s).")
    if dry_run:
        print("Run without --dry-run to apply.")


if __name__ == "__main__":
    main()
