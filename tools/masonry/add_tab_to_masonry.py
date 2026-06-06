#!/usr/bin/env python3
# add_tab_to_masonry.py
# Adds live.tab Controls/Matrix switcher to f_masonry presentation layer.
# - Reverts panel to 290x285
# - Adds live.tab at top (y=0, h=18)
# - Shifts existing presentation objects down by TAB_H
# - Repositions jsui grid to same area as controls (below tab), same size
# - Wires tab → sel 0 1 → thispatcher script show/hide controls vs grid

import json

SRC  = '/Users/matt/Github/f_/patchers/f_masonry.maxpat'
DEST = '/Users/matt/Github/f_/patchers/f_masonry.maxpat'

with open(SRC) as f:
    p = json.load(f)

patcher = p['patcher']
boxes   = patcher['boxes']
lines   = patcher['lines']

TAB_H      = 18.0
PANEL_W    = 290.0
PANEL_H    = 285.0
CONTENT_H  = PANEL_H - TAB_H   # 267px for controls and grid

# IDs of objects that are part of the matrix layer (hide when tab=0)
MATRIX_IDS = {'obj-100'}

# IDs of objects that are part of the controls layer (hide when tab=1)
# Everything with presentation=1 except panel, title comment, bypass toggle,
# tab itself, and matrix grid
ALWAYS_VISIBLE = {'obj-1', 'obj-2', 'obj-8'}  # panel, title, bypass

# ------------------------------------------------------------------
# 1. Revert panel to 290x285
# ------------------------------------------------------------------
for box in boxes:
    b = box['box']
    if b.get('maxclass') == 'panel' and b['id'] == 'obj-1':
        b['presentation_rect'] = [0.0, 0.0, PANEL_W, PANEL_H]
        b['patching_rect'] = [20.0, 20.0, PANEL_W, PANEL_H]

# ------------------------------------------------------------------
# 2. Collect controls layer IDs (all presentation objects except
#    panel, title, bypass, and matrix grid)
# ------------------------------------------------------------------
controls_ids = []
for box in boxes:
    b = box['box']
    if b.get('presentation') == 1 and b['id'] not in ALWAYS_VISIBLE and b['id'] not in MATRIX_IDS:
        controls_ids.append(b['id'])

# ------------------------------------------------------------------
# 3. Shift existing presentation objects down by TAB_H
#    (all except panel obj-1 which stays at 0,0)
# ------------------------------------------------------------------
for box in boxes:
    b = box['box']
    if b.get('presentation') == 1 and b['id'] != 'obj-1':
        pr = b.get('presentation_rect')
        if pr:
            b['presentation_rect'] = [pr[0], pr[1] + TAB_H, pr[2], pr[3]]

# ------------------------------------------------------------------
# 4. Reposition jsui grid: same footprint as controls area
#    x=5, y=TAB_H, w=210, h=CONTENT_H
# ------------------------------------------------------------------
for box in boxes:
    b = box['box']
    if b['id'] == 'obj-100':
        b['presentation_rect'] = [5.0, TAB_H, 210.0, CONTENT_H]
        b['patching_rect']     = [5.0, 50.0, 210.0, CONTENT_H]

# ------------------------------------------------------------------
# 5. Add new objects: live.tab, sel 0 1, two message boxes for
#    thispatcher scripting, thispatcher
# ------------------------------------------------------------------

# Build show/hide message strings for controls layer
controls_show = ' '.join([f'script sendbox {oid} visible 1' for oid in controls_ids])
controls_hide = ' '.join([f'script sendbox {oid} visible 0' for oid in controls_ids])

new_boxes = [
    # obj-120: live.tab — Controls / Matrix
    {"box": {
        "id": "obj-120",
        "maxclass": "live.tab",
        "numinlets": 1,
        "numoutlets": 2,
        "outlettype": ["int", "int"],
        "patching_rect": [5.0, 5.0, PANEL_W - 10.0, TAB_H],
        "presentation": 1,
        "presentation_rect": [0.0, 0.0, PANEL_W, TAB_H],
        "parameter_enable": 0,
        "tabs": ["Controls", "Matrix"],
        "varname": "tab_selector"
    }},
    # obj-121: sel 0 1
    {"box": {
        "id": "obj-121",
        "maxclass": "newobj",
        "numinlets": 1,
        "numoutlets": 2,
        "outlettype": ["bang", "bang"],
        "patching_rect": [5.0, 30.0, 60.0, 22.0],
        "text": "sel 0 1"
    }},
    # obj-122: thispatcher
    {"box": {
        "id": "obj-122",
        "maxclass": "newobj",
        "numinlets": 1,
        "numoutlets": 2,
        "outlettype": ["", ""],
        "patching_rect": [5.0, 85.0, 80.0, 22.0],
        "text": "thispatcher"
    }},
    # obj-123: show controls, hide grid (tab=0)
    {"box": {
        "id": "obj-123",
        "maxclass": "message",
        "numinlets": 2,
        "numoutlets": 1,
        "outlettype": [""],
        "patching_rect": [5.0, 55.0, 400.0, 22.0],
        "text": f"script sendbox obj-100 visible 0 , {controls_show}"
    }},
    # obj-124: hide controls, show grid (tab=1)
    {"box": {
        "id": "obj-124",
        "maxclass": "message",
        "numinlets": 2,
        "numoutlets": 1,
        "outlettype": [""],
        "patching_rect": [420.0, 55.0, 400.0, 22.0],
        "text": f"script sendbox obj-100 visible 1 , {controls_hide}"
    }},
]

for b in new_boxes:
    boxes.append(b)

# ------------------------------------------------------------------
# 6. New patchlines
# ------------------------------------------------------------------
new_lines = [
    # tab → sel
    {"patchline": {"source": ["obj-120", 0], "destination": ["obj-121", 0]}},
    # sel outlet 0 (Controls) → show-controls message
    {"patchline": {"source": ["obj-121", 0], "destination": ["obj-123", 0]}},
    # sel outlet 1 (Matrix) → hide-controls message
    {"patchline": {"source": ["obj-121", 1], "destination": ["obj-124", 0]}},
    # both messages → thispatcher
    {"patchline": {"source": ["obj-123", 0], "destination": ["obj-122", 0]}},
    {"patchline": {"source": ["obj-124", 0], "destination": ["obj-122", 0]}},
]

for l in new_lines:
    lines.append(l)

# ------------------------------------------------------------------
# 7. Write output
# ------------------------------------------------------------------
with open(DEST, 'w') as f:
    json.dump(p, f, indent=4)

print(f"Done.")
print(f"Panel reverted to {PANEL_W}x{PANEL_H}")
print(f"Tab height: {TAB_H}px, content area: {CONTENT_H}px")
print(f"Controls layer IDs ({len(controls_ids)}): {controls_ids}")
print(f"Matrix grid (obj-100) repositioned to y={TAB_H}, h={CONTENT_H}")
