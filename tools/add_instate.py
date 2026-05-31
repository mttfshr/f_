#!/usr/bin/env python3
"""
add_instate.py — insert vs_inState into dual-mode generator patchers that
currently wire routepass out0 directly to pix in0.

Before:  routepass[0] → pix[0]
After:   routepass[0] → vs_inState[0]
         vs_inState[0] → pix[0]        (texture or vs_black fallback)
         vs_inState[1] → prepend_src_mode[0] → pix[0]

Also adds Param src_mode(0.0) to the codebox if not already present.
src_mode is system-driven (not user-facing) — prepend stays as prepend,
not attrui, per convention.

Usage:
    python3 tools/add_instate.py [patcher ...] [--dry-run]

    With no arguments, targets f_grain and f_masonry.
    --dry-run prints what would change without writing.
"""

import json
import sys
from pathlib import Path

REPO_ROOT    = Path(__file__).parent.parent
PATCHERS_DIR = REPO_ROOT / "patchers"

TARGETS = [
    "f_grain.maxpat",
    "f_masonry.maxpat",
]

# IDs to use for new objects, keyed by patcher name
NEW_IDS = {
    "f_grain.maxpat":   {"instate": "obj-41",  "srcmode_pre": "obj-44"},
    "f_masonry.maxpat": {"instate": "obj-16",  "srcmode_pre": "obj-17"},
}


def find_box(boxes, pred):
    for b in boxes:
        if pred(b["box"]):
            return b["box"]
    return None


def wire(src_id, src_outlet, dst_id, dst_inlet):
    return {"patchline": {"source": [src_id, src_outlet],
                          "destination": [dst_id, dst_inlet]}}


def migrate_patcher(path: Path, ids: dict, dry_run: bool) -> bool:
    with open(path) as f:
        data = json.load(f)

    boxes  = data["patcher"]["boxes"]
    lines  = data["patcher"]["lines"]

    # Sanity: already has vs_inState?
    if any("vs_inState" in b["box"].get("text", "") for b in boxes):
        print(f"  SKIP — vs_inState already present")
        return False

    rp_box  = find_box(boxes, lambda b: "routepass" in b.get("text", ""))
    pix_box = find_box(boxes, lambda b: "jit.gl.pix" in b.get("text", ""))

    if not (rp_box and pix_box):
        print(f"  ERROR — could not find routepass or pix")
        return False

    rp_id  = rp_box["id"]
    pix_id = pix_box["id"]

    # Find routepass[0] → pix[0] line to replace
    rp_pix_idx = next(
        (i for i, l in enumerate(lines)
         if l["patchline"]["source"][0] == rp_id
         and l["patchline"]["source"][1] == 0
         and l["patchline"]["destination"][0] == pix_id),
        None
    )
    if rp_pix_idx is None:
        print(f"  ERROR — no routepass[0]→pix[0] line found")
        return False

    # Position vs_inState midway between routepass and pix
    rp_x, rp_y = rp_box["patching_rect"][:2]
    px_x, px_y = pix_box["patching_rect"][:2]
    is_x = rp_x
    is_y = (rp_y + px_y) / 2.0
    sp_x = is_x + 230.0  # prepend src_mode to the right
    sp_y = is_y

    is_id = ids["instate"]
    sp_id = ids["srcmode_pre"]

    instate_box = {
        "box": {
            "id": is_id,
            "maxclass": "newobj",
            "text": "vs_inState",
            "numinlets": 1,
            "numoutlets": 2,
            "outlettype": ["", ""],
            "patching_rect": [is_x, is_y, 80.0, 22.0],
        }
    }

    srcmode_pre_box = {
        "box": {
            "id": sp_id,
            "maxclass": "newobj",
            "text": "prepend param src_mode",
            "numinlets": 1,
            "numoutlets": 1,
            "outlettype": [""],
            "patching_rect": [sp_x, sp_y, 145.0, 22.0],
        }
    }

    new_lines = [
        wire(rp_id, 0, is_id, 0),   # routepass[0] → vs_inState[0]
        wire(is_id, 0, pix_id, 0),  # vs_inState[0] → pix[0]
        wire(is_id, 1, sp_id, 0),   # vs_inState[1] → prepend src_mode
        wire(sp_id, 0, pix_id, 0),  # prepend src_mode → pix[0]
    ]

    # Codebox: add Param src_mode(0.0) if missing
    gen = pix_box.get("patcher", {})
    gen_boxes = gen.get("boxes", [])
    codebox_entry = next(
        (gb for gb in gen_boxes if gb["box"].get("maxclass") == "codebox"),
        None
    )
    codebox_changed = False
    if codebox_entry and "src_mode" not in codebox_entry["box"].get("code", ""):
        old_code = codebox_entry["box"]["code"]
        new_code = "Param src_mode(0.0);\n" + old_code
        codebox_changed = True

    if dry_run:
        print(f"  WOULD insert vs_inState {is_id} at [{is_x:.0f}, {is_y:.0f}]")
        print(f"  WOULD insert prepend param src_mode {sp_id} at [{sp_x:.0f}, {sp_y:.0f}]")
        print(f"  WOULD remove routepass[0]→pix[0] direct wire")
        print(f"  WOULD add 4 new patchlines")
        if codebox_changed:
            print(f"  WOULD prepend 'Param src_mode(0.0);' to codebox")
        else:
            print(f"  codebox already has src_mode — no change")
    else:
        # Remove old direct wire
        lines.pop(rp_pix_idx)
        # Add new boxes
        boxes.append(instate_box)
        boxes.append(srcmode_pre_box)
        # Add new lines
        lines.extend(new_lines)
        # Update codebox if needed
        if codebox_changed:
            codebox_entry["box"]["code"] = new_code

        with open(path, "w") as f:
            json.dump(data, f, indent="\t")

        print(f"  inserted vs_inState {is_id}, prepend src_mode {sp_id}")
        print(f"  rewired routepass → vs_inState → pix")
        if codebox_changed:
            print(f"  prepended Param src_mode(0.0) to codebox")

    return True


def main():
    args = sys.argv[1:]
    dry_run = "--dry-run" in args
    args = [a for a in args if a != "--dry-run"]

    if args:
        paths_ids = [(Path(a), NEW_IDS.get(Path(a).name, {})) for a in args]
    else:
        paths_ids = [(PATCHERS_DIR / t, NEW_IDS[t]) for t in TARGETS]

    changed = 0
    for path, ids in paths_ids:
        print(f"\n{'[DRY RUN] ' if dry_run else ''}{path.name}")
        if not ids:
            print(f"  ERROR — no ID mapping for {path.name}; add to NEW_IDS dict")
            continue
        if migrate_patcher(path, ids, dry_run):
            changed += 1

    print(f"\n{'Would update' if dry_run else 'Updated'} {changed} patcher(s).")
    if dry_run:
        print("Run without --dry-run to apply.")


if __name__ == "__main__":
    main()
