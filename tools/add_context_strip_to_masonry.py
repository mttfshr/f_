#!/usr/bin/env python3
# add_context_strip_to_masonry.py
# Adds context strip jsui to f_masonry front panel:
#   - Extends panel height by STRIP_H
#   - Adds strip jsui (obj-126) to presentation layer
#   - Sends 'strip' message at loadbang
#   - Fans out param name from each prepend to strip via 'prepend focus'
#   - Wires strip outlet back to mod handler inlet 0

import json

SRC  = '/Users/matt/Github/f_/patchers/f_masonry.maxpat'
DEST = '/Users/matt/Github/f_/patchers/f_masonry.maxpat'

with open(SRC) as f:
    p = json.load(f)

patcher = p['patcher']
boxes   = patcher['boxes']
lines   = patcher['lines']

# ------------------------------------------------------------------
# 1. Measure current panel
# ------------------------------------------------------------------

panel_box = None
for b in boxes:
    if b['box'].get('maxclass') == 'panel':
        panel_box = b['box']
        break

if not panel_box:
    raise RuntimeError("panel object not found")

pr = panel_box['presentation_rect']
PANEL_W    = pr[2]
PANEL_H    = pr[3]
STRIP_H    = 22   # one CELL_H (20) + 2px breathing room
GAP        = 4    # gap between bottom dial row and strip
STRIP_Y    = PANEL_H + GAP
NEW_PANEL_H = STRIP_Y + STRIP_H

print(f"Current panel: {PANEL_W} x {PANEL_H}")
print(f"Strip at y={STRIP_Y}, h={STRIP_H}")
print(f"New panel height: {NEW_PANEL_H}")

# ------------------------------------------------------------------
# 2. Extend panel height
# ------------------------------------------------------------------

panel_box['presentation_rect'] = [pr[0], pr[1], PANEL_W, NEW_PANEL_H]
pat = panel_box.get('patching_rect', [])
if pat:
    panel_box['patching_rect'] = [pat[0], pat[1], pat[2], NEW_PANEL_H]

# ------------------------------------------------------------------
# 3. Add strip jsui (obj-126)
# ------------------------------------------------------------------

strip_jsui = {"box": {
    "id": "obj-141",
    "maxclass": "jsui",
    "filename": "f_util_matrix_grid.js",
    "numinlets": 1,
    "numoutlets": 1,
    "outlettype": [""],
    "patching_rect": [5.0, 800.0, PANEL_W - 4.0, float(STRIP_H)],
    "presentation": 1,
    "presentation_rect": [2.0, float(STRIP_Y), PANEL_W - 4.0, float(STRIP_H)],
    "varname": "context_strip"
}}
boxes.append(strip_jsui)

# ------------------------------------------------------------------
# 4. Add 'strip' message object (obj-127) + loadbang wire
# ------------------------------------------------------------------
# Reuse existing loadbang (obj-102) and params message (obj-103).
# We need a 'strip' message object and a 'prepend focus' per param.
# Find loadbang patching_rect to position near it.

loadbang_rect = None
for b in boxes:
    if b['box'].get('id') == 'obj-102':
        loadbang_rect = b['box']['patching_rect']
        break

lby = loadbang_rect[1] if loadbang_rect else 400.0

strip_msg = {"box": {
    "id": "obj-142",
    "maxclass": "message",
    "numinlets": 2,
    "numoutlets": 1,
    "outlettype": [""],
    "patching_rect": [200.0, lby, 50.0, 22.0],
    "text": "strip"
}}
boxes.append(strip_msg)

# loadbang → strip message → strip jsui
lines.append({"patchline": {"source": ["obj-102", 0], "destination": ["obj-142", 0]}})
lines.append({"patchline": {"source": ["obj-142", 0], "destination": ["obj-141", 0]}})

# params message also goes to strip jsui (same params list)
lines.append({"patchline": {"source": ["obj-103", 0], "destination": ["obj-141", 0]}})

# strip jsui outlet → mod handler inlet 0
lines.append({"patchline": {"source": ["obj-141", 0], "destination": ["obj-101", 0]}})

# ------------------------------------------------------------------
# 5. Add focus message objects + wire from each dial
# ------------------------------------------------------------------
# Each modulatable dial already has a prepend <param> (obj-104 to obj-116).
# We add per-param: t b → message "focus <param>" → strip jsui.
# t b fires on any dial touch; message sends the param name with 'focus' prefix.
# obj-143..obj-155 = trigger bang objects (one per param)
# obj-156..obj-168 = focus message objects (one per param)

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

base_y = lby + 60.0
for i, (dial_id, param) in enumerate(DIAL_TO_PARAM.items()):
    trig_id = f"obj-{143 + i}"
    msg_id  = f"obj-{156 + i}"
    x = 250.0 + (i % 4) * 120.0
    y = base_y + (i // 4) * 60.0

    # trigger bang
    boxes.append({"box": {
        "id": trig_id,
        "maxclass": "newobj",
        "numinlets": 1,
        "numoutlets": 1,
        "outlettype": ["bang"],
        "patching_rect": [x, y, 40.0, 22.0],
        "text": "t b"
    }})

    # focus message
    boxes.append({"box": {
        "id": msg_id,
        "maxclass": "message",
        "numinlets": 2,
        "numoutlets": 1,
        "outlettype": [""],
        "patching_rect": [x, y + 30.0, 100.0, 22.0],
        "text": f"focus {param}"
    }})

    # dial → t b → focus msg → strip jsui
    lines.append({"patchline": {"source": [dial_id, 0], "destination": [trig_id, 0]}})
    lines.append({"patchline": {"source": [trig_id, 0], "destination": [msg_id, 0]}})
    lines.append({"patchline": {"source": [msg_id, 0], "destination": ["obj-141", 0]}})

# ------------------------------------------------------------------
# 6. Write
# ------------------------------------------------------------------

with open(DEST, 'w') as f:
    json.dump(p, f, indent=4)

added_objs  = 2 + len(DIAL_TO_PARAM) * 2   # strip jsui + strip msg + (t b + focus msg) × 13
added_lines = 4 + len(DIAL_TO_PARAM) * 3   # strip wires + (dial→tb + tb→msg + msg→strip) × 13
print(f"Done. Added {added_objs} objects, {added_lines} patchlines.")
print(f"Panel now {PANEL_W} x {NEW_PANEL_H}px")
