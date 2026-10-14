#!/usr/bin/env python3
"""
Re-applies the helpfile cropping fix that an accidental `import
make_missing_helpfiles` just reverted for 14 of the 17 touched helpfiles
(that import runs module-level generation code with no __main__ guard).
Pure stdlib json, no import of make_missing_helpfiles -- avoids repeating
the mistake.

Same formula as the original fix: d-4 (module bpatcher) sized to the
module's real presentation-view bbox + 10px margin, d-5 (vs_preview)
repositioned 20px below d-4's new bottom edge, d-9 (recipe comment, if
present) repositioned 16px below d-5's bottom edge.
"""
import json
from pathlib import Path

REPO = Path("/Users/matt/Github/f_")

REVERTED = [
    "f_vf_advect", "f_vf_chroma", "f_vf_flow", "f_vf_glow", "f_vf_potential",
    "f_vf_prism", "f_vf_repulse", "f_vf_seeds", "f_vf_split",
    "f_vf_vortex_multi", "f_vf_vorticity", "f_weave", "f_ngon", "f_sirds",
]


def presentation_bbox(maxpat_path):
    d = json.load(open(maxpat_path))
    xs0, ys0, xs1, ys1 = [], [], [], []
    for b in d["patcher"]["boxes"]:
        bb = b["box"]
        if bb.get("presentation"):
            r = bb.get("presentation_rect")
            if not r:
                continue
            x, y, w, h = r
            xs0.append(x); ys0.append(y); xs1.append(x + w); ys1.append(y + h)
    if not xs0:
        return None
    return (max(xs1) - min(xs0), max(ys1) - min(ys0))


def main():
    for m in REVERTED:
        maxpat = REPO / "package" / "patchers" / f"{m}.maxpat"
        helpf = REPO / "package" / "help" / f"{m}.maxhelp"
        bbox = presentation_bbox(maxpat)
        if bbox is None:
            print(f"{m}: no presentation boxes found, SKIPPED")
            continue
        real_w, real_h = bbox

        d = json.load(open(helpf))
        byid = {b["box"]["id"]: b["box"] for b in d["patcher"]["boxes"]}
        d4, d5, d9 = byid.get("d-4"), byid.get("d-5"), byid.get("d-9")
        if d4 is None or d5 is None:
            print(f"{m}: missing d-4/d-5, SKIPPED")
            continue

        x4, y4, _, _ = d4["patching_rect"]
        new_w, new_h = real_w + 10, real_h + 10
        d4["patching_rect"] = [x4, y4, new_w, new_h]

        x5, _, w5, h5 = d5["patching_rect"]
        new_y5 = y4 + new_h + 20
        d5["patching_rect"] = [x5, new_y5, w5, h5]
        max_bottom = new_y5 + h5

        if d9:
            x9, _, w9, h9 = d9["patching_rect"]
            new_y9 = new_y5 + h5 + 16
            d9["patching_rect"] = [x9, new_y9, w9, h9]
            max_bottom = new_y9 + h9

        with open(helpf, "w") as f:
            json.dump(d, f, indent="\t")
        print(f"{m}: d-4={new_w:.1f}x{new_h:.1f} d-5_y={new_y5:.1f} max_bottom={max_bottom:.1f}")


if __name__ == "__main__":
    main()
