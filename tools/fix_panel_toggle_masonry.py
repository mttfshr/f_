#!/usr/bin/env python3
# fix_panel_toggle_masonry.py
# - Replaces obj-125 (live.text) with correct structure matching f_lens pattern
# - Fixes wiring: panel_toggle -> masonry_toggle.js -> thispatcher
# - parameter_enable + initial value ensures controls show on load

import json

SRC  = '/Users/matt/Github/f_/patchers/f_masonry.maxpat'
DEST = '/Users/matt/Github/f_/patchers/f_masonry.maxpat'

with open(SRC) as f:
    p = json.load(f)

patcher = p['patcher']
boxes   = patcher['boxes']
lines   = patcher['lines']

# ------------------------------------------------------------------
# 1. Remove old obj-125 and its patchlines
# ------------------------------------------------------------------
REMOVE_IDS = {'obj-125'}
patcher['boxes'] = [b for b in boxes if b['box']['id'] not in REMOVE_IDS]
patcher['lines'] = [
    l for l in lines
    if l['patchline']['source'][0] not in REMOVE_IDS
    and l['patchline']['destination'][0] not in REMOVE_IDS
]
boxes = patcher['boxes']
lines = patcher['lines']

# ------------------------------------------------------------------
# 2. Replace with correct live.text matching f_lens pattern
# ------------------------------------------------------------------
new_toggle = {"box": {
    "activebgcolor": [0.067, 0.063, 0.063, 1.0],
    "activebgoncolor": [0.067, 0.063, 0.063, 1.0],
    "activetextcolor": [0.757, 0.757, 0.757, 1.0],
    "activetextoncolor": [0.659, 0.659, 0.659, 1.0],
    "bordercolor": [0.8, 0.8, 0.8, 1.0],
    "fontname": "Ableton Sans Light",
    "id": "obj-125",
    "maxclass": "live.text",
    "numinlets": 1,
    "numoutlets": 2,
    "outlettype": ["", ""],
    "parameter_enable": 1,
    "patching_rect": [5.0, 5.0, 60.0, 15.0],
    "presentation": 1,
    "presentation_rect": [160.0, 4.0, 60.0, 14.0],
    "rounded": 4.0,
    "saved_attribute_attributes": {
        "valueof": {
            "parameter_enum": ["Controls", "Matrix"],
            "parameter_initial": [0.0],
            "parameter_initial_enable": 1,
            "parameter_linknames": 1,
            "parameter_longname": "panel_toggle",
            "parameter_mmax": 1,
            "parameter_modmode": 0,
            "parameter_shortname": "panel_toggle",
            "parameter_speedlim": 0.0,
            "parameter_type": 2
        }
    },
    "text": "Controls",
    "texton": "Matrix",
    "varname": "panel_toggle"
}}

boxes.append(new_toggle)

# ------------------------------------------------------------------
# 3. Fix wiring: panel_toggle -> masonry_toggle.js -> thispatcher
#    (obj-126 is masonry_toggle.js, obj-127 is thispatcher)
#    Remove any stale lines from obj-125, re-add correct ones
# ------------------------------------------------------------------
patcher['lines'] = [
    l for l in lines
    if not (l['patchline']['source'][0] == 'obj-125'
            or l['patchline']['destination'][0] == 'obj-125')
]
lines = patcher['lines']

new_lines = [
    {"patchline": {"source": ["obj-125", 0], "destination": ["obj-126", 0]}},
    {"patchline": {"source": ["obj-126", 0], "destination": ["obj-127", 0]}},
]
for l in new_lines:
    lines.append(l)

# ------------------------------------------------------------------
# 4. Write
# ------------------------------------------------------------------
with open(DEST, 'w') as f:
    json.dump(p, f, indent=4)

print("Done. Fixed panel_toggle (obj-125) with parameter_enable + initial value.")
print("Wiring: obj-125 -> obj-126 (masonry_toggle.js) -> obj-127 (thispatcher)")
