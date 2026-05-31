#!/usr/bin/env python3
"""
add_routepass.py — add routepass to processor patchers that have a bare
inlet → route wiring, inserting proper texture/control separation.

Before: inlet → route
After:  inlet → routepass → pix in0   (texture path)
                routepass → route      (control path, unmatched outlet 2)

The existing inlet → route patchline is replaced. A new routepass box and
two new patchlines are inserted. The pix object already has inlet 0 wired
for control messages; we add the texture wire on the same inlet (jit.gl.pix
accepts multiple connections to inlet 0).

Usage:
    python3 tools/add_routepass.py [patcher ...] [--dry-run]

    With no arguments, targets the four known affected patchers.
    --dry-run prints what would change without writing.
"""

import json
import sys
from pathlib import Path

REPO_ROOT    = Path(__file__).parent.parent
PATCHERS_DIR = REPO_ROOT / "patchers"

TARGETS = [
    "f_channel_grader.maxpat",
    "f_hue_processor.maxpat",
    "f_luma_processor.maxpat",
    "f_tone_curve.maxpat",
]


def find_box(boxes, pred):
    for b in boxes:
        if pred(b["box"]):
            return b["box"]
    return None


def free_id(boxes, prefix="obj-rp"):
    used = {b["box"]["id"] for b in boxes}
    i = 100
    while f"{prefix}{i}" in used:
        i += 1
    return f"{prefix}{i}"


def wire(src_id, src_outlet, dst_id, dst_inlet):
    return {"patchline": {"source": [src_id, src_outlet],
                          "destination": [dst_id, dst_inlet]}}


def migrate_patcher(path: Path, dry_run: bool) -> bool:
    with open(path) as f:
        data = json.load(f)

    boxes = data["patcher"]["boxes"]
    lines = data["patcher"]["lines"]

    # Sanity: already has routepass?
    if any("routepass" in b["box"].get("text", "") for b in boxes):
        print(f"  SKIP — routepass already present")
        return False

    inlet_box = find_box(boxes, lambda b: b.get("maxclass") == "inlet")
    route_box = find_box(boxes, lambda b: b.get("maxclass") == "newobj"
                         and b.get("text", "").startswith("route "))
    pix_box   = find_box(boxes, lambda b: "jit.gl.pix" in b.get("text", ""))

    if not (inlet_box and route_box and pix_box):
        print(f"  ERROR — could not find inlet/route/pix objects")
        return False

    inlet_id = inlet_box["id"]
    route_id = route_box["id"]
    pix_id   = pix_box["id"]

    # Find and remove the inlet → route patchline
    inlet_route_idx = next(
        (i for i, l in enumerate(lines)
         if l["patchline"]["source"][0] == inlet_id
         and l["patchline"]["destination"][0] == route_id),
        None
    )
    if inlet_route_idx is None:
        print(f"  ERROR — no inlet→route patchline found")
        return False

    # Position routepass between inlet and route
    ix, iy = inlet_box["patching_rect"][:2]
    rx, ry = route_box["patching_rect"][:2]
    rp_x = ix
    rp_y = (iy + ry) / 2.0

    rp_id = free_id(boxes)

    routepass_box = {
        "box": {
            "id": rp_id,
            "maxclass": "newobj",
            "text": "routepass jit_gl_texture jit_matrix",
            "numinlets": 1,
            "numoutlets": 3,
            "outlettype": ["jit_gl_texture", "jit_matrix", ""],
            "patching_rect": [rp_x, rp_y, 220.0, 22.0],
        }
    }

    new_lines = [
        wire(inlet_id, 0, rp_id,    0),   # inlet → routepass
        wire(rp_id,    0, pix_id,   0),   # routepass tex out → pix in0
        wire(rp_id,    2, route_id, 0),   # routepass unmatched → route
    ]

    if dry_run:
        print(f"  WOULD insert routepass {rp_id} at [{rp_x:.0f}, {rp_y:.0f}]")
        print(f"  WOULD remove patchline: {inlet_id}[0] → {route_id}[0]")
        print(f"  WOULD add patchlines:")
        for l in new_lines:
            pl = l["patchline"]
            print(f"    {pl['source'][0]}[{pl['source'][1]}] → {pl['destination'][0]}[{pl['destination'][1]}]")
    else:
        # Remove old inlet→route line
        lines.pop(inlet_route_idx)
        # Add routepass box
        boxes.append(routepass_box)
        # Add new patchlines
        lines.extend(new_lines)

        with open(path, "w") as f:
            json.dump(data, f, indent="\t")

        print(f"  inserted routepass {rp_id}")
        print(f"  removed inlet→route direct wire, added 3 new patchlines")

    return True


def main():
    args = sys.argv[1:]
    dry_run = "--dry-run" in args
    args = [a for a in args if a != "--dry-run"]

    if args:
        paths = [Path(a) for a in args]
    else:
        paths = [PATCHERS_DIR / t for t in TARGETS]

    changed = 0
    for path in paths:
        print(f"\n{'[DRY RUN] ' if dry_run else ''}{path.name}")
        if migrate_patcher(path, dry_run):
            changed += 1

    print(f"\n{'Would update' if dry_run else 'Updated'} {changed} patcher(s).")
    if dry_run:
        print("Run without --dry-run to apply.")


if __name__ == "__main__":
    main()
