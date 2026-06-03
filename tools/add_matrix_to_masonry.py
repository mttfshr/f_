#!/usr/bin/env python3
# add_matrix_to_masonry.py
# Adds onboard matrix grid modulation to f_masonry.maxpat:
#   - Removes old u/v mod chooser objects and patchlines
#   - Adds jsui matrix grid, js mod handler, loadbang/params seed
#   - Adds prepend chains from each modulatable dial to mod handler inlet 1
#   - Extends presentation panel height to accommodate grid
#   - Updates pix numinlets (in2/in3 already exist, no change needed)

import json, copy

SRC  = '/Users/matt/Github/f_/patchers/f_masonry.maxpat'
DEST = '/Users/matt/Github/f_/patchers/f_masonry.maxpat'

with open(SRC) as f:
    p = json.load(f)

patcher = p['patcher']
boxes   = patcher['boxes']
lines   = patcher['lines']

# ------------------------------------------------------------------
# 1. Remove old mod objects and their patchlines
# ------------------------------------------------------------------

OLD_IDS = {'obj-m10','obj-m11','obj-m20','obj-m21',
           'obj-m30','obj-m31','obj-m32','obj-m33'}

patcher['boxes'] = [b for b in boxes if b['box']['id'] not in OLD_IDS]
patcher['lines'] = [
    l for l in lines
    if l['patchline']['source'][0] not in OLD_IDS
    and l['patchline']['destination'][0] not in OLD_IDS
]

boxes = patcher['boxes']
lines = patcher['lines']

# ------------------------------------------------------------------
# 2. Extend presentation panel height
# ------------------------------------------------------------------
# Grid dimensions: LABEL_COL_W=90, CELL_W=60, NUM_SOURCES=2
# HEADER_H=20, CELL_H=28, NUM_PARAMS=13
# Grid width:  90 + 2*60 = 210
# Grid height: 20 + 13*28 = 384
# New panel height: existing 285 + 20 gap + 384 grid = 689

GRID_W = 210
GRID_H = 384
GRID_GAP = 20
OLD_PANEL_H = 285.0
NEW_PANEL_H = OLD_PANEL_H + GRID_GAP + GRID_H  # 689
GRID_Y = OLD_PANEL_H + GRID_GAP  # 305

for box in boxes:
    b = box['box']
    if b.get('maxclass') == 'panel':
        pr = b.get('presentation_rect', [])
        if pr:
            b['presentation_rect'] = [pr[0], pr[1], pr[2], NEW_PANEL_H]
        r = b.get('patching_rect', [])
        if r:
            b['patching_rect'] = [r[0], r[1], r[2], NEW_PANEL_H]

# ------------------------------------------------------------------
# 3. New objects
# ------------------------------------------------------------------

MODULATABLE = [
    'mortar', 'drift', 'offset', 'speed_var', 'regularity',
    'width', 'phase', 'softness', 'roundness', 'quantize',
    'course_color', 'brick_color', 'skip'
]

# Dial id → param name (from discovery)
DIAL_TO_PARAM = {
    'obj-30': 'mortar',
    'obj-27': 'drift',
    'obj-22': 'offset',
    'obj-29': 'speed_var',
    'obj-26': 'regularity',
    'obj-32': 'width',
    'obj-28': 'phase',
    'obj-31': 'softness',
    'obj-33': 'roundness',
    'obj-25': 'quantize',
    'obj-35': 'course_color',
    'obj-36': 'brick_color',
    'obj-24': 'skip',
}

PARAMS_MSG = 'params ' + ' '.join(MODULATABLE)

new_boxes = []

# obj-100: jsui matrix grid
new_boxes.append({"box": {
    "id": "obj-100",
    "maxclass": "jsui",
    "filename": "f_util_matrix_grid.js",
    "numinlets": 1,
    "numoutlets": 1,
    "outlettype": [""],
    "patching_rect": [5.0, GRID_Y + 30.0, float(GRID_W), float(GRID_H)],
    "presentation": 1,
    "presentation_rect": [5.0, GRID_Y, float(GRID_W), float(GRID_H)],
    "varname": "matrix_grid"
}})

# obj-101: js mod handler
new_boxes.append({"box": {
    "id": "obj-101",
    "maxclass": "newobj",
    "numinlets": 2,
    "numoutlets": 1,
    "outlettype": [""],
    "patching_rect": [5.0, GRID_Y + 30.0 + GRID_H + 15.0, 160.0, 22.0],
    "text": "js f_util_mod_handler.js"
}})

# obj-102: loadbang
new_boxes.append({"box": {
    "id": "obj-102",
    "maxclass": "newobj",
    "numinlets": 1,
    "numoutlets": 1,
    "outlettype": ["bang"],
    "patching_rect": [5.0, GRID_Y - 25.0, 60.0, 22.0],
    "text": "loadbang"
}})

# obj-103: params seed message
new_boxes.append({"box": {
    "id": "obj-103",
    "maxclass": "message",
    "numinlets": 2,
    "numoutlets": 1,
    "outlettype": [""],
    "patching_rect": [70.0, GRID_Y - 25.0, 400.0, 22.0],
    "text": PARAMS_MSG
}})

# obj-104 through obj-116: prepend <param> for each modulatable dial → mod handler in1
for i, (dial_id, param) in enumerate(DIAL_TO_PARAM.items()):
    obj_id = f"obj-{104 + i}"
    new_boxes.append({"box": {
        "id": obj_id,
        "maxclass": "newobj",
        "numinlets": 2,
        "numoutlets": 1,
        "outlettype": [""],
        "patching_rect": [250.0 + (i % 4) * 120.0, GRID_Y + 30.0 + GRID_H + 45.0 + (i // 4) * 30.0, 100.0, 22.0],
        "text": f"prepend {param}"
    }})

for b in new_boxes:
    boxes.append(b)

# ------------------------------------------------------------------
# 4. New patchlines
# ------------------------------------------------------------------

new_lines = []

# loadbang → params message
new_lines.append({"patchline": {"source": ["obj-102", 0], "destination": ["obj-103", 0]}})

# params message → jsui
new_lines.append({"patchline": {"source": ["obj-103", 0], "destination": ["obj-100", 0]}})

# jsui → mod handler in0
new_lines.append({"patchline": {"source": ["obj-100", 0], "destination": ["obj-101", 0]}})

# mod handler out → pix in0
new_lines.append({"patchline": {"source": ["obj-101", 0], "destination": ["obj-7", 0]}})

# each dial → prepend → mod handler in1
dial_param_list = list(DIAL_TO_PARAM.items())
for i, (dial_id, param) in enumerate(dial_param_list):
    prepend_id = f"obj-{104 + i}"
    new_lines.append({"patchline": {"source": [dial_id, 0], "destination": [prepend_id, 0]}})
    new_lines.append({"patchline": {"source": [prepend_id, 0], "destination": ["obj-101", 1]}})

for l in new_lines:
    lines.append(l)

# ------------------------------------------------------------------
# 5. Write output
# ------------------------------------------------------------------

with open(DEST, 'w') as f:
    json.dump(p, f, indent=4)

print(f"Done. Added {len(new_boxes)} objects, {len(new_lines)} patchlines.")
print(f"Removed old mod chooser objects: {OLD_IDS}")
print(f"New panel height: {NEW_PANEL_H}px")
print(f"Grid at y={GRID_Y}, {GRID_W}x{GRID_H}px")
