#!/usr/bin/env python3
# add_panel_toggle_to_masonry.py
# - Adds varnames to label comment objects
# - Removes orphaned old-mod label objects
# - Writes masonry_toggle.js
# - Adds live.text panel toggle + toggle JS + wiring to f_masonry

import json, os

SRC  = '/Users/matt/Github/f_/patchers/f_masonry.maxpat'
DEST = '/Users/matt/Github/f_/patchers/f_masonry.maxpat'
JS_DEST = '/Users/matt/Github/f_/code/masonry_toggle.js'

with open(SRC) as f:
    p = json.load(f)

patcher = p['patcher']
boxes   = patcher['boxes']
lines   = patcher['lines']

# ------------------------------------------------------------------
# 1. Remove orphaned old-mod label objects and their lines
# ------------------------------------------------------------------
ORPHAN_IDS = {'lbl-obj-m10', 'lbl-obj-m11', 'lbl-obj-m20', 'lbl-obj-m21'}
patcher['boxes'] = [b for b in boxes if b['box']['id'] not in ORPHAN_IDS]
patcher['lines'] = [
    l for l in lines
    if l['patchline']['source'][0] not in ORPHAN_IDS
    and l['patchline']['destination'][0] not in ORPHAN_IDS
]
boxes = patcher['boxes']
lines = patcher['lines']

# ------------------------------------------------------------------
# 2. Add varnames to label comment objects
# ------------------------------------------------------------------
LABEL_VARNAMES = {
    'lbl-obj-20': 'lbl_courses',
    'lbl-obj-21': 'lbl_bond',
    'lbl-obj-22': 'lbl_offset',
    'lbl-obj-23': 'lbl_angle',
    'lbl-obj-24': 'lbl_skip',
    'lbl-obj-25': 'lbl_quantize',
    'lbl-obj-26': 'lbl_regularity',
    'lbl-obj-27': 'lbl_drift',
    'lbl-obj-28': 'lbl_phase',
    'lbl-obj-29': 'lbl_speed_var',
    'lbl-obj-30': 'lbl_mortar',
    'lbl-obj-31': 'lbl_softness',
    'lbl-obj-32': 'lbl_width',
    'lbl-obj-33': 'lbl_roundness',
    'lbl-obj-35': 'lbl_course_color',
    'lbl-obj-36': 'lbl_brick_color',
}
for box in boxes:
    b = box['box']
    if b['id'] in LABEL_VARNAMES:
        b['varname'] = LABEL_VARNAMES[b['id']]

# ------------------------------------------------------------------
# 3. Controls layer varnames — dials + labels + numboxes
# ------------------------------------------------------------------
CONTROLS_VARNAMES = [
    # dials
    'courses', 'bond', 'offset', 'angle', 'skip', 'quantize',
    'regularity', 'drift', 'phase', 'speed_var', 'mortar',
    'softness', 'width', 'roundness', 'course_color', 'brick_color',
    # numboxes
    'course_seed', 'brick_seed',
    # labels
    'lbl_courses', 'lbl_bond', 'lbl_offset', 'lbl_angle', 'lbl_skip',
    'lbl_quantize', 'lbl_regularity', 'lbl_drift', 'lbl_phase',
    'lbl_speed_var', 'lbl_mortar', 'lbl_softness', 'lbl_width',
    'lbl_roundness', 'lbl_course_color', 'lbl_brick_color',
]

MATRIX_VARNAMES = ['matrix_grid']

# ------------------------------------------------------------------
# 4. Write masonry_toggle.js
# ------------------------------------------------------------------
js_content = '''// masonry_toggle.js
// Receives 0 (controls panel) or 1 (matrix panel).
// Scripts presentation visibility via thispatcher script sendbox.

var CONTROLS_OBJS = [
    {controls}
];

var MATRIX_OBJS = [
    {matrix}
];

function msg_int(v)   {{ setpanel(v); }}
function msg_float(v) {{ setpanel(Math.round(v)); }}

function setpanel(show_matrix) {{
    var i;
    for (i = 0; i < CONTROLS_OBJS.length; i++) {{
        outlet(0, "script", "sendbox", CONTROLS_OBJS[i], "hidden", show_matrix ? 1 : 0);
    }}
    for (i = 0; i < MATRIX_OBJS.length; i++) {{
        outlet(0, "script", "sendbox", MATRIX_OBJS[i], "hidden", show_matrix ? 0 : 1);
    }}
}}
'''.format(
    controls=',\n    '.join([f'"{v}"' for v in CONTROLS_VARNAMES]),
    matrix=',\n    '.join([f'"{v}"' for v in MATRIX_VARNAMES])
)

with open(JS_DEST, 'w') as f:
    f.write(js_content)
print(f"Wrote {JS_DEST}")

# ------------------------------------------------------------------
# 5. Add new Max objects
# ------------------------------------------------------------------

# Find thispatcher already in patch for moduleSize chain
# We need a separate thispatcher for the toggle — add obj-125
# live.text panel toggle — same style as f_lens (obj-4 there)
# Position: top of presentation, next to title

new_boxes = [
    # obj-125: live.text panel toggle (Controls / Matrix)
    {"box": {
        "id": "obj-125",
        "maxclass": "live.text",
        "numinlets": 1,
        "numoutlets": 2,
        "outlettype": ["int", "int"],
        "patching_rect": [5.0, 5.0, 60.0, 15.0],
        "presentation": 1,
        "presentation_rect": [100.0, 5.0, 80.0, 13.0],
        "parameter_enable": 0,
        "varname": "panel_toggle",
        "text_off": "Controls",
        "text_on": "Matrix",
        "Mode_Entry": 2
    }},
    # obj-126: js masonry_toggle.js
    {"box": {
        "id": "obj-126",
        "maxclass": "newobj",
        "numinlets": 1,
        "numoutlets": 1,
        "outlettype": [""],
        "patching_rect": [5.0, 30.0, 160.0, 22.0],
        "text": "js masonry_toggle.js"
    }},
    # obj-127: thispatcher for toggle scripting
    {"box": {
        "id": "obj-127",
        "maxclass": "newobj",
        "numinlets": 1,
        "numoutlets": 2,
        "outlettype": ["", ""],
        "patching_rect": [5.0, 55.0, 80.0, 22.0],
        "text": "thispatcher"
    }},
]

for b in new_boxes:
    boxes.append(b)

# ------------------------------------------------------------------
# 6. New patchlines
# ------------------------------------------------------------------
new_lines = [
    # live.text → toggle js
    {"patchline": {"source": ["obj-125", 0], "destination": ["obj-126", 0]}},
    # toggle js → thispatcher
    {"patchline": {"source": ["obj-126", 0], "destination": ["obj-127", 0]}},
]

for l in new_lines:
    lines.append(l)

# ------------------------------------------------------------------
# 7. Write patch
# ------------------------------------------------------------------
with open(DEST, 'w') as f:
    json.dump(p, f, indent=4)

print(f"Done. Added {len(new_boxes)} objects, {len(new_lines)} patchlines.")
print(f"Removed orphan labels: {ORPHAN_IDS}")
print(f"Added varnames to {len(LABEL_VARNAMES)} label objects.")
