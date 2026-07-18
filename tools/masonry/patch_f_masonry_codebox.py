#!/usr/bin/env python3
"""
patch_f_masonry_codebox.py
Replaces the codebox in f_masonry.maxpat with codebox_phase5b.gen.
No structural changes — inlets and params already in place from phase 5.
"""

import json
from pathlib import Path

PATCHER_PATH = Path("/Users/matt/Github/f_/patchers/f_masonry.maxpat")
CODEBOX_PATH = Path("/Users/matt/Github/f_/src/f_masonry/codebox_phase5b.gen")

with open(PATCHER_PATH) as f:
    doc = json.load(f)

with open(CODEBOX_PATH) as f:
    new_codebox = f.read()

p = doc["patcher"]

# Find pix object (obj-7) and update codebox in gen-3
pix_box = next(b for b in p["boxes"] if b["box"]["id"] == "obj-7")
gen = pix_box["box"]["patcher"]

updated = False
for b in gen["boxes"]:
    if b["box"]["id"] == "gen-3":
        b["box"]["code"] = new_codebox
        updated = True
        break

if not updated:
    print("ERROR: gen-3 not found")
    exit(1)

with open(PATCHER_PATH, "w") as f:
    json.dump(doc, f, indent="\t")

print("Done. Codebox updated to phase5b.")
print("V-axis targets: 0=none 1=mortar 2=drift 3=offset 4=speed_var 5=regularity 6=width 7=phase")
