#!/usr/bin/env python3
# add_texture_inlets_to_masonry.py
# Adds in2/in3 texture inlets and matrix modulation to f_masonry codebox:
#   - Adds 26 mod_amt params (13 params x 2 sources)
#   - Adds in2/in3 sampling at top of codebox
#   - Replaces each modulatable param usage with _eff version
#   - Sets pix numinlets to 3
#   - Adds inlet obj-m1 (source A) and obj-m2 (source B) to patcher
#   - Wires inlets to pix

import json

SRC  = '/Users/matt/Github/f_/patchers/f_masonry.maxpat'
DEST = '/Users/matt/Github/f_/patchers/f_masonry.maxpat'

with open(SRC) as f:
    p = json.load(f)

patcher = p['patcher']
boxes   = patcher['boxes']
lines   = patcher['lines']

MODULATABLE = [
    'mortar', 'drift', 'offset', 'speed_var', 'regularity',
    'width', 'phase', 'softness', 'roundness', 'quantize',
    'course_color', 'brick_color', 'skip'
]

# ------------------------------------------------------------------
# 1. Update codebox inside jit.gl.pix
# ------------------------------------------------------------------

pix_box = None
for b in boxes:
    if 'jit.gl.pix' in b['box'].get('text', ''):
        pix_box = b['box']
        break

if not pix_box:
    raise RuntimeError('jit.gl.pix not found')

sub_boxes = pix_box['patcher']['boxes']
codebox = None
for sb in sub_boxes:
    if sb['box'].get('maxclass') == 'codebox':
        codebox = sb['box']
        break

if not codebox:
    raise RuntimeError('codebox not found')

old_code = codebox['code']

# Build new param declarations for mod amounts
mod_param_lines = '\n'.join(
    f'Param {p}_mod_amt_a(0.0);\nParam {p}_mod_amt_b(0.0);'
    for p in MODULATABLE
)

# Sampling lines
sampling_lines = (
    'a_sample = sample(in2, vec(0.5, norm.y)).r;\n'
    'b_sample = sample(in3, vec(norm.x, 0.5)).r;'
)

# Effective value lines — inserted after sampling
eff_lines = '\n'.join(
    f'{p}_eff = clamp({p} + a_sample * {p}_mod_amt_a + b_sample * {p}_mod_amt_b, 0.0, 1.0);'
    for p in MODULATABLE
)

# Prepend new params + sampling + eff values to existing code
# Insert after the existing Param block (find last Param line)
lines_list = old_code.split('\n')
last_param_idx = -1
for i, line in enumerate(lines_list):
    if line.strip().startswith('Param '):
        last_param_idx = i

if last_param_idx < 0:
    raise RuntimeError('No Param lines found in codebox')

new_lines = (
    lines_list[:last_param_idx + 1]
    + ['']
    + mod_param_lines.split('\n')
    + ['']
    + sampling_lines.split('\n')
    + ['']
    + eff_lines.split('\n')
    + ['']
    + lines_list[last_param_idx + 1:]
)

new_code = '\n'.join(new_lines)

# Replace each modulatable param usage with _eff version.
# Must be careful to replace whole-word usage only, not param declarations.
# Pattern: replace bare param name (not preceded by Param keyword or _mod_amt)
import re
for param in MODULATABLE:
    # Replace usage but not in Param declarations or _mod_amt lines or _eff assignments
    # Use negative lookbehind for 'Param ' and negative lookahead for '_'
    new_code = re.sub(
        r'(?<!Param )(?<!\w)' + re.escape(param) + r'(?!_)(?!\w)',
        param + '_eff',
        new_code
    )

# Fix: the _eff assignment lines themselves use param_eff on left and param on right
# which got double-replaced. Fix by restoring the right-hand param in _eff lines.
for param in MODULATABLE:
    # The eff line looks like: mortar_eff_eff = clamp(mortar_eff + ...
    # Fix double-replacement
    new_code = new_code.replace(
        f'{param}_eff_eff',
        f'{param}_eff'
    )
    # Also fix the rhs of the eff assignment which got _eff appended
    new_code = new_code.replace(
        f'clamp({param}_eff +',
        f'clamp({param} +'
    )
    new_code = new_code.replace(
        f'{param}_eff_mod_amt_a',
        f'{param}_mod_amt_a'
    )
    new_code = new_code.replace(
        f'{param}_eff_mod_amt_b',
        f'{param}_mod_amt_b'
    )

codebox['code'] = new_code

# ------------------------------------------------------------------
# 2. Set pix numinlets to 3
# ------------------------------------------------------------------

pix_box['numinlets'] = 3

# Also update numinlets inside the gen patcher if needed
for sb in sub_boxes:
    sbox = sb['box']
    if sbox.get('maxclass') == 'inlet':
        pass  # gen inlets handled by Max automatically

# ------------------------------------------------------------------
# 3. Add inlet objects for source A (in2) and source B (in3)
# ------------------------------------------------------------------

# Find existing inlet patching_rect for positioning reference
inlet_rect = None
for b in boxes:
    if b['box'].get('maxclass') == 'inlet':
        inlet_rect = b['box']['patching_rect']
        break

ref_x = inlet_rect[0] if inlet_rect else 50.0
ref_y = inlet_rect[1] if inlet_rect else 30.0

boxes.append({'box': {
    'comment': 'source A texture',
    'id': 'obj-m1',
    'index': 1,
    'maxclass': 'inlet',
    'numinlets': 0,
    'numoutlets': 1,
    'outlettype': [''],
    'patching_rect': [ref_x + 50.0, ref_y, 30.0, 30.0]
}})

boxes.append({'box': {
    'comment': 'source B texture',
    'id': 'obj-m2',
    'index': 2,
    'maxclass': 'inlet',
    'numinlets': 0,
    'numoutlets': 1,
    'outlettype': [''],
    'patching_rect': [ref_x + 100.0, ref_y, 30.0, 30.0]
}})

# ------------------------------------------------------------------
# 4. Wire inlets to pix
# ------------------------------------------------------------------

pix_id = pix_box['id']
lines.append({'patchline': {'source': ['obj-m1', 0], 'destination': [pix_id, 1]}})
lines.append({'patchline': {'source': ['obj-m2', 0], 'destination': [pix_id, 2]}})

# ------------------------------------------------------------------
# 5. Write
# ------------------------------------------------------------------

with open(DEST, 'w') as f:
    json.dump(p, f, indent=4)

print('Done.')
print(f'Added {len(MODULATABLE) * 2} mod_amt params to codebox')
print('Added in2/in3 sampling and _eff values')
print('Set pix numinlets to 3')
print('Added inlet objects obj-m1, obj-m2')
