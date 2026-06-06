import json

def build():
    objs, lines = [], []
    ctr = [1]

    def new_id():
        id = f"obj-{ctr[0]}"
        ctr[0] += 1
        return id

    def add(maxclass, numinlets, numoutlets, outlettype, rect, **kw):
        id = new_id()
        b = {"id": id, "maxclass": maxclass,
             "numinlets": numinlets, "numoutlets": numoutlets,
             "outlettype": outlettype, "patching_rect": rect}
        b.update(kw)
        objs.append({"box": b})
        return id

    def obj(text, numinlets, numoutlets, outlettype, rect, **kw):
        return add("newobj", numinlets, numoutlets, outlettype, rect, text=text, **kw)

    def wire(s, so, d, di):
        lines.append({"patchline": {"source": [s, so], "destination": [d, di]}})

    # ── Inlets ───────────────────────────────────────────────────────────
    in_ids = []
    for i in range(4):
        in_ids.append(add("inlet", 0, 1, [""], [30 + i*160, 30, 30, 30],
                          comment=f"in{i} — texture + control"))

    # ── Outlets ──────────────────────────────────────────────────────────
    out_ids = []
    for i in range(4):
        out_ids.append(add("outlet", 1, 0, [], [30 + i*55, 510, 30, 30],
                           comment=f"out{i}"))

    # ── routepass: out0=jit_gl_texture, out1=control ─────────────────────
    rp_ids = []
    for i in range(4):
        rp_ids.append(obj("routepass jit_gl_texture", 1, 2, ["", ""],
                          [30 + i*160, 80, 165, 22]))

    # ── Gates gate_RC: in0=selector(0/1), in1=message ────────────────────
    gate_ids = []
    for r in range(4):
        row = []
        for c in range(4):
            row.append(obj("gate 1", 2, 1, [""],
                           [30 + c*55, 150 + r*45, 40, 22]))
        gate_ids.append(row)

    # ── Toggles tog_RC ────────────────────────────────────────────────────
    tog_ids = []
    for r in range(4):
        row = []
        for c in range(4):
            vn   = f"tog_{r}{c}"
            diag = (r == c)
            init = [1] if diag else [0]
            row.append(add("live.toggle", 1, 1, [""],
                           [700 + c*50, 150 + r*45, 20, 20],
                           parameter_enable=1,
                           presentation=1,
                           presentation_rect=[48 + c*35, 28 + r*25, 20, 20],
                           varname=vn,
                           saved_attribute_attributes={
                               "valueof": {
                                   "parameter_longname": vn,
                                   "parameter_shortname": vn,
                                   "parameter_type": 2,
                                   "parameter_mmax": 1,
                                   "parameter_initial_enable": 1,
                                   "parameter_initial": init
                               }
                           }))
        tog_ids.append(row)

    # ── Bypass ────────────────────────────────────────────────────────────
    bypass_id = add("live.toggle", 1, 1, [""], [960, 80, 20, 20],
                    parameter_enable=1,
                    presentation=1,
                    presentation_rect=[226, 5, 20, 20],
                    varname="router_bypass",
                    saved_attribute_attributes={
                        "valueof": {
                            "parameter_longname": "bypass",
                            "parameter_shortname": "bypass",
                            "parameter_type": 2,
                            "parameter_mmax": 1,
                            "parameter_initial_enable": 1,
                            "parameter_initial": [0]
                        }
                    })
    bypass_inv_id = obj("!- 1",   2, 1, [""], [960, 120, 42, 22])
    ctrl_gate_id  = obj("gate 1", 2, 1, [""], [960, 160, 40, 22])

    # ── Control dispatch ──────────────────────────────────────────────────
    ctrl_sym_id  = obj("routepass preset clear reset cell",
                        1, 5, ["","","","",""], [960, 210, 210, 22])
    ctrl_type_id = obj("route bang",
                        1, 2, ["",""],          [960, 255, 80, 22])

    # ── preset object — native store/recall UI, pattrstorage integration ─
    # Inlet: int N = recall N; "next" = advance; "store N" = store as N
    # Presentation: sits below the toggle grid as the preset UI
    preset_id = obj("preset @num 8", 1, 2, ["",""],
                    [1110, 300, 126, 42],
                    presentation=1,
                    presentation_rect=[44, 112, 198, 32])

    # ── pattrstorage: named to match preset object ────────────────────────
    pattrstorage_id = obj("pattrstorage router_presets @savemode 1",
                           1, 1, [""], [1110, 360, 230, 22],
                           varname="router_pattrstorage")

    # ── autopattr ─────────────────────────────────────────────────────────
    autopattr_id = obj("autopattr @save 1",
                        1, 4, ["","","",""], [1110, 405, 120, 22],
                        varname="router_autopattr")

    # ── bang → next, int → direct recall ─────────────────────────────────
    prepend_next_id  = obj("prepend next",  1, 1, [""], [960, 300, 82, 22])

    # ── store command: "preset N" from protocol → "store N" to preset obj ─
    prepend_store_id = obj("prepend store", 1, 1, [""], [810, 255, 92, 22])

    # ── Clear / Reset message boxes ───────────────────────────────────────
    msg_clear_id = add("message", 2, 1, [""], [810, 305, 248, 22],
                       text="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0")
    msg_reset_id = add("message", 2, 1, [""], [810, 340, 248, 22],
                       text="1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1")

    # ── State unpack (16 outlets → all toggles) ───────────────────────────
    state_unpack_id = obj("unpack i i i i i i i i i i i i i i i i",
                           1, 16, [""]*16, [700, 395, 318, 22])

    # ── Loadbang → identity on open ───────────────────────────────────────
    loadbang_id = obj("loadbang", 0, 1, ["bang"], [660, 30, 65, 22])

    # ── Cell edit objects ─────────────────────────────────────────────────
    cell_unpack_id   = obj("unpack i i i", 1, 3, ["","",""], [1360, 255, 80, 22])
    cell_idx_id      = obj("expr ($i1 * 4) + $i2",
                            2, 1, [""], [1460, 295, 138, 22])
    cell_dispatch_id = obj("route 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15",
                            1, 17, [""]*17, [1360, 340, 318, 22])

    tap_ids, cell_int_ids = [], []
    for i in range(16):
        r, c = i // 4, i % 4
        tap_ids.append(obj("t b", 1, 1, ["bang"],
                           [1360 + c*52, 380 + r*30, 30, 22]))
        cell_int_ids.append(obj("int", 2, 1, [""],
                                [1360 + c*52, 475 + r*30, 30, 22]))

    # ── Presentation labels + panel ───────────────────────────────────────
    lx, ly = 1750, 30

    def lbl(text, pr, fs=10.0, bold=False, color=None):
        nonlocal ly
        kw = {"text": text, "fontsize": fs, "fontname": "Arial",
              "presentation": 1, "presentation_rect": pr}
        if bold:   kw["fontface"] = 1
        if color:  kw["textcolor"] = color
        add("comment", 1, 0, [], [lx, ly, 100, 18], **kw)
        ly += 20

    add("panel", 1, 0, [], [lx, ly, 20, 20],
        presentation=1,
        presentation_rect=[0, 0, 252, 152],
        bgcolor=[0.14, 0.14, 0.14, 1.0],
        bordercolor=[0.28, 0.28, 0.28, 1.0],
        mode=0)
    ly += 20

    grey  = [0.65, 0.65, 0.65, 1.0]
    white = [0.9,  0.9,  0.9,  1.0]

    lbl("vs_texrouter", [5, 5, 88, 16], bold=True, color=white)
    lbl("bypass",       [191, 7, 34, 13], fs=9.0, color=grey)
    for c in range(4):
        lbl(f"out{c}", [46 + c*35, 13, 32, 13], fs=9.0, color=grey)
    for r in range(4):
        lbl(f"in{r}",  [5, 31 + r*25, 32, 13], fs=9.0, color=grey)

    # ── Wire everything ───────────────────────────────────────────────────

    wire(loadbang_id, 0, msg_reset_id, 0)   # identity on open

    for i in range(4):
        wire(in_ids[i], 0, rp_ids[i], 0)

    for r in range(4):
        for c in range(4):
            wire(rp_ids[r], 0, gate_ids[r][c], 1)   # texture → gate message
        wire(rp_ids[r], 1, ctrl_gate_id, 1)          # control → ctrl_gate

    for r in range(4):
        for c in range(4):
            wire(tog_ids[r][c], 0, gate_ids[r][c], 0)  # toggle → gate selector
            wire(gate_ids[r][c], 0, out_ids[c], 0)      # gate → outlet

    wire(bypass_id,     0, bypass_inv_id, 0)
    wire(bypass_inv_id, 0, ctrl_gate_id,  0)
    wire(ctrl_gate_id,  0, ctrl_sym_id,   0)

    # ctrl_sym_route outlets
    wire(ctrl_sym_id, 0, prepend_store_id, 0)  # "preset N" → int N → "store N"
    wire(ctrl_sym_id, 1, msg_clear_id,     0)  # clear
    wire(ctrl_sym_id, 2, msg_reset_id,     0)  # reset
    wire(ctrl_sym_id, 3, cell_unpack_id,   0)  # cell R C V
    wire(ctrl_sym_id, 4, ctrl_type_id,     0)  # bang / int

    # store path → preset object
    wire(prepend_store_id, 0, preset_id, 0)

    # bang/int dispatch
    wire(ctrl_type_id,    0, prepend_next_id, 0)  # bang → "next"
    wire(prepend_next_id, 0, preset_id,       0)  # "next" → preset
    wire(ctrl_type_id,    1, preset_id,       0)  # int → direct recall

    # preset → pattrstorage (preset outputs recall/store messages natively)
    wire(preset_id, 0, pattrstorage_id, 0)

    # clear / reset → state_unpack → toggles
    wire(msg_clear_id,  0, state_unpack_id, 0)
    wire(msg_reset_id,  0, state_unpack_id, 0)
    for r in range(4):
        for c in range(4):
            wire(state_unpack_id, r*4+c, tog_ids[r][c], 0)

    # Cell edit
    wire(cell_unpack_id, 1, cell_idx_id, 1)   # C → cold
    wire(cell_unpack_id, 0, cell_idx_id, 0)   # R → hot (triggers)
    wire(cell_idx_id, 0, cell_dispatch_id, 0)
    for i in range(16):
        r, c = i // 4, i % 4
        wire(cell_unpack_id,   2, cell_int_ids[i], 1)  # V → cold store
        wire(cell_dispatch_id, i, tap_ids[i],      0)
        wire(tap_ids[i],       0, cell_int_ids[i], 0)  # bang → output V
        wire(cell_int_ids[i],  0, tog_ids[r][c],   0)

    return {
        "patcher": {
            "fileversion": 1,
            "appversion": {"major": 8, "minor": 6, "revision": 5,
                           "architecture": "x64", "modernui": 1},
            "classnamespace": "box",
            "rect": [34, 79, 1800, 960],
            "bglocked": 0,
            "openinpresentation": 1,
            "default_fontsize": 12.0,
            "default_fontface": 0,
            "default_fontname": "Arial",
            "gridonopen": 1,
            "gridsize": [15.0, 15.0],
            "gridsnaponopen": 1,
            "objectsnaponopen": 1,
            "statusbarvisible": 2,
            "toolbarvisible": 1,
            "lefttoolbarpinned": 0,
            "toptoolbarpinned": 0,
            "righttoolbarpinned": 0,
            "bottomtoolbarpinned": 0,
            "toolbars_unpinned_last_save": 0,
            "tallnewobj": 0,
            "boxanimatetime": 200,
            "enablehscroll": 1,
            "enablevscroll": 1,
            "devicewidth": 0.0,
            "description": "4x4 texture routing matrix for Vsynth",
            "digest": "",
            "tags": "",
            "style": "",
            "subpatcher_template": "",
            "assistshowspatchername": 0,
            "boxes": objs,
            "lines": lines
        }
    }

patch = build()
out = "/Users/matt/Vsynth/bpatchers/vs_texrouter.maxpat"
with open(out, "w") as f:
    json.dump(patch, f, indent="\t")

print(f"Written: {out}")
print(f"Objects: {len(patch['patcher']['boxes'])}")
print(f"Lines:   {len(patch['patcher']['lines'])}")

boxes   = patch["patcher"]["boxes"]
ids     = [b["box"]["id"] for b in boxes]
assert len(ids) == len(set(ids)), "Duplicate IDs!"
all_ids = set(ids)
bad = [(l["patchline"]["source"][0], l["patchline"]["destination"][0])
       for l in patch["patcher"]["lines"]
       if l["patchline"]["source"][0] not in all_ids
       or l["patchline"]["destination"][0] not in all_ids]
if bad:
    print(f"BAD CONNECTIONS: {bad}")
else:
    print("All connection IDs valid ✓")

# Report by class
from collections import Counter
classes = Counter(b["box"]["maxclass"] for b in boxes)
print("Object classes:")
for k, v in sorted(classes.items()):
    print(f"  {k}: {v}")
