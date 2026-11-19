"""
f_vf_erode -- definition.py

Ink that pools like a wash on paper (spec rewritten 2026-11-10, Matt; the 2026-11-09 extent/bulge design is in git).
A picture goes in; on a wetting it becomes pigment on the paper and the frame is flooded. Water then runs over a terrain
(inlet 1) pushed by a vecfield (inlet 2), lifts pigment off the paper where it runs fast and puts it down where it slows, so
ink pools in the low places and leaves the high ones. Inlet 3 is the background the pigment sits on. Polarity: Darker filters
a background that is white when unconnected, Lighter adds over a black one.
Spec, plan, tasks: .specify/stable/f_vf_erode/{spec,plan,tasks}.md. Mirror: tests/modules/vf_erode/vf_erode_mirror.py.

State: ONE float32 atlas at the render size, W x 2H, two RGBA planes stacked vertically (plan ADR-1):
  plane A  R water depth, GBA pigment in suspension      plane B  RGB pigment on the paper, A the load flag
Stage chain (one solver step per `r draw`; plan ADR-2, amended 2026-11-10):
    hold -> load -> transport -> react -> hold         (react -> hold feedback, cold)
    prep -> transport, react                           (static face velocities from the terrain and the field, cold)
    react -> enc                                       (enc: composite per Polarity, thickness, bypass gate)
  hold       the loop break (identity)
  load       the wetting (press edge of wet_gate): picture -> paper pigment, water added, suspension emptied; and Feed, the continuous source (US5)
  transport  water and suspended pigment through the cell faces, conservative gather form; drying
  react      lift off the paper and settle onto it from the speed of the water
  prep       terrain luma and vecfield -> the static part of each face's velocity, and of the lift/settle drive
  enc        render-size composite and thickness; before the first wetting it shows the picture as if loaded (T076)
Every stage has at most four inlets (the codebox bench's limit). All atlas stages are `@adapt 0` and take `dim W 2H` from the
builder's render_dim `atlas_stages` key; they read W and H from the Params width / height (a live pix reads `dim` as 1).

Dial ranges and defaults are provisional (T032 tuning with Matt); the panel layout is the builder's until `G-ui-density`.
"""

ATLAS = "@adapt 0 @dim 256 512 @type float32"

patcher = {
    "name":        "f_vf_erode",
    "prefix":      "vferode",
    "object_name": "#0_vferode_pix",
    "title":       "Erode",
    "archetype":   "processor",

    "presentation_width":  204,      # was 190 x 150: two dial rows, the Wet button in the first slot (Matt, 2026-11-10)
    "presentation_height": 146,      # Live-style panel, 2026-11-18 (Matt chose it: ideas/m4l_ui_design.md, tasks.md Phase 4)

    "outlets": [
        {"comment": "ink (composite over the background)"},
        {"comment": "thickness (pigment on the paper)"},
    ],

    "params": [
        {"name": "polar_sw", "type": "text_button", "options": ["Darker", "Lighter"], "default": 0, "label": "Polarity",
         "pix_target": ["load", "enc"],
         "hint": "Darker: the pigment filters the background, white when inlet 3 is unconnected. Lighter: it adds to a black background. A change takes effect at the next wetting"},
        {"name": "flow", "type": "float", "widget": "numbox", "min": 0.0, "max": 2.0, "default": 0.4, "label": "Flow",
         "pix_target": ["prep", "transport", "react"],
         "hint": "How strongly the water runs downhill on the terrain (inlet 1). PROVISIONAL"},
        {"name": "push", "type": "float", "widget": "numbox", "min": 0.0, "max": 4.0, "default": 1.0, "label": "Push",
         "pix_target": "prep",
         "hint": "How strongly the vecfield (inlet 2) moves the water. 0 is the same as no vecfield. PROVISIONAL"},
        {"name": "lift", "type": "float", "widget": "numbox", "min": 0.0, "max": 1.0, "default": 0.7, "label": "Lift",
         "pix_target": "react",
         "hint": "How readily running water takes pigment off the paper. A curve: the bottom half is gentle, the top lifts almost everything at once. PROVISIONAL"},
        {"name": "settle", "type": "float", "widget": "numbox", "min": 0.0, "max": 1.0, "default": 0.19, "label": "Settle",
         "pix_target": "react",
         "hint": "How readily slow water puts pigment back down; higher drops it sooner, so less is carried far. A cubic curve. Water that has gone puts all of it down regardless. PROVISIONAL"},
        {"name": "dry", "type": "float", "widget": "numbox", "min": 0.0, "max": 0.02, "default": 0.0016, "label": "Dry",
         "pix_target": "transport",
         "hint": "How fast the water goes, per step. A dried wash is still. PROVISIONAL"},
        {"name": "speed", "type": "float", "widget": "numbox", "min": 0.0, "max": 4.0, "default": 1.0, "label": "Speed",
         "pix_target": ["prep", "transport", "react"],
         "hint": "Step size of each solver step; limited inside the solver so the water stays stable. PROVISIONAL"},
        {"name": "flood", "type": "float", "widget": "numbox", "min": 0.0, "max": 4.0, "default": 1.0, "label": "Flood",
         "pix_target": "load",
         "hint": "How much water a wetting adds. It is added to any water still on the paper. PROVISIONAL"},
        {"name": "feed", "type": "float", "widget": "numbox", "min": 0.0, "max": 1.0, "default": 0.0, "label": "Feed",
         "pix_target": "load",
         "hint": "A continuous source for an animated or live picture: each step a fraction of what the picture holds beyond the paper is deposited, and the water relaxes toward Flood. 0 is wet once. A still picture on a flat frame converges to itself. PROVISIONAL"},
        {"name": "fade", "type": "float", "widget": "numbox", "min": 0.0, "max": 1.0, "default": 0.02, "label": "Fade",
         "pix_target": "load",
         "hint": "With Feed above 0: how fast ink above what the picture holds returns to the picture, so a picture that gets lighter is followed and the frame does not go black. Small = pooled ink lasts about 1 / Fade frames. 0 = it never fades. PROVISIONAL"},
        {"name": "wet", "type": "gate_button", "label": "Wet", "gate_param": "wet_gate",
         "rect": [10.0, 38.0, 32.0, 32.0], "label_rect": [1.0, 20.0, 50.0, 18.0],      # far left, label above (was [3.5, 46, 28, 28] in the dial grid, 2026-11-10)
         "hint": "Wet once: the picture on inlet 0 becomes the pigment on the paper and the frame is flooded. Holding does not wet again"},
        {"name": "bypass", "type": "bypass"},

        # Feeds the load stage; the press edge wets (the load flag keeps the gate as last seen)
        {"name": "wet_gate", "type": "internal", "pix_target": "load"},
        # Set by each vs_inState via `prepend param` (1 = that inlet is connected)
        {"name": "src_terrain", "type": "internal"},
        {"name": "src_field", "type": "internal"},
        {"name": "src_bg", "type": "internal"},
        # Driven by the bypass jsui (`prepend param bypass_gate`), never by the route
        {"name": "bypass_gate", "type": "internal"},
        # Render size, driven by render_dim
        {"name": "width", "type": "internal"},
        {"name": "height", "type": "internal"},
    ],

    "inlet_comment": "picture / control",
    "inlet_fanout": {"texture": [["load", 1], ["enc", 2]], "state": []},
    "mod_inlets": [
        {"label": "terrain (luma = height; water runs downhill)", "vs_instate": True, "state_param": "src_terrain",
         "fanout": [["prep", 1]], "state_nodes": ["prep"]},
        {"label": "vecfield (pushes the water)", "vs_instate": True, "state_param": "src_field",
         "fanout": [["prep", 2]], "state_nodes": ["prep"]},
        {"label": "background (the paper the pigment sits on)", "vs_instate": True, "state_param": "src_bg",
         "fanout": [["enc", 3]], "state_nodes": ["enc"]},
    ],
    "draw_triggers": ["hold", "prep", "enc"],
    "bypass_mode": "param",             # jsui -> prepend param bypass_gate -> enc (the primary)

    "render_dim": {
        "width_param":  "width",
        "height_param": "height",
        "param_stages": ["prep", "load", "transport", "react"],
        "size_stages":  ["enc"],
        "atlas_stages": ["hold", "prep", "load", "transport", "react"],
    },

    "pix_chain": [
        {"id": "hold",      "name": "#0_vferode_hold",      "gen": "codebox_hold.gen",      "n_inlets": 2, "n_outlets": 1,
         "pix_attrs": ATLAS, "primary": False},
        {"id": "prep",      "name": "#0_vferode_prep",      "gen": "codebox_prep.gen",      "n_inlets": 3, "n_outlets": 1,
         "pix_attrs": ATLAS, "primary": False},
        {"id": "load",      "name": "#0_vferode_load",      "gen": "codebox_load.gen",      "n_inlets": 2, "n_outlets": 1,
         "pix_attrs": ATLAS, "primary": False},
        {"id": "transport", "name": "#0_vferode_transport", "gen": "codebox_transport.gen", "n_inlets": 2, "n_outlets": 1,
         "pix_attrs": ATLAS, "primary": False},
        {"id": "react",     "name": "#0_vferode_react",     "gen": "codebox_react.gen",     "n_inlets": 2, "n_outlets": 1,
         "pix_attrs": ATLAS, "primary": False},
        {"id": "enc",       "name": "#0_vferode_enc",       "gen": "codebox_enc.gen",       "n_inlets": 4, "n_outlets": 2,
         "pix_attrs": "@adapt 0 @dim 256 256 @type float32", "primary": True},
    ],

    # [src_id, src_outlet, dst_id, dst_inlet]
    "pix_wires": [
        ["hold", 0, "load", 0],           # the state: load's one hot inlet
        ["load", 0, "transport", 0],
        ["transport", 0, "react", 0],
        ["react", 0, "hold", 1],          # feedback edge: cold inlet (the draw bang is the hot one)
        ["prep", 0, "transport", 1],      # static velocities (cold)
        ["prep", 0, "react", 1],
        ["react", 0, "enc", 1],           # state -> encode (cold)
    ],
}


# The Darker / Lighter toggle lives in the title bar (Matt, 2026-11-10), like f_weave's mode controls: [Erode] [Darker] ... [bypass].
# 2026-11-18 (Matt): Live-style panel, 204 x 146: all number boxes in two columns of stacked groups, a header over each group
# (Run / Pigment over Water / Feed), the label left of its box, Wet far left. The type label was dropped (commit 66374e0).
# The rects come from scratch/experiments/m4l_strip_f_vf_erode/f_vf_erode_strip_2col.maxpat (local mock).
# Before: title [10.5, 0, 40, 21], polar_sw.ctl [50, 3, 52, 15], nine dials in two rows on the builder's grid.
_GROUPS = [("Run",     58.0,  17.0, ["flow", "push", "speed"]),
           ("Pigment", 58.0,  89.0, ["lift", "settle"]),
           ("Water",   134.0, 17.0, ["flood", "dry"]),
           ("Feed",    134.0, 89.0, ["feed", "fade"])]
_ov = {
    "title":        {"presentation_rect": [10.5, 0.0, 44.0, 21.0]},   # x 10.5 is what test_generate_menu finds the module name by (the mock had 14)
    "polar_sw.ctl": {"presentation_rect": [62.0, 3.0, 56.0, 15.0]},
}
_LBL = dict(fontname="Ableton Sans Light", fontsize=9.5, textjustification=0, numinlets=1, numoutlets=0, outlettype=[], presentation=1)
RAW_BOXES = []
for _k, (_g, _x, _y0, _names) in enumerate(_GROUPS):
    RAW_BOXES.append({"box": dict(id=f"obj-raw-grp{_k}", maxclass="comment", text=_g,
                                  patching_rect=[620.0, 20.0 + 22.0 * _k, 60.0, 18.0],
                                  presentation_rect=[_x - 1.0, _y0, 68.0, 16.0], **_LBL)})
    for _j, _n in enumerate(_names):
        _y = _y0 + 19.0 + 17.0 * _j
        _ov[f"{_n}.ctl"] = {"presentation_rect": [_x + 30.0, _y, 36.0, 15.0]}
        _ov[f"{_n}.label"] = {"presentation_rect": [_x - 2.0, _y - 1.5, 34.0, 18.0], "textjustification": 0}
# The Wet button's own face (the panel behind its ubutton) did not draw in Max (Matt, 2026-11-18, screenshot): the area was
# black on black. A foreground outline over the same rect, transparent fill, clicks pass through (ignoreclick), so the button
# can be seen. Likely cause (inferred: test_generate_menu's docstring says a background-layer panel is drawn under the frame and
# vanishes; the builder's gate_button face is background=1): not confirmed in Max. f_vf_stamp and f_wave_field share the face.
RAW_BOXES.append({"box": dict(id="obj-raw-wetoutline", maxclass="panel", varname="wet_outline", patching_rect=[700.0, 20.0, 32.0, 32.0],
                              numinlets=1, numoutlets=0, background=0, ignoreclick=1, border=2, rounded=14,
                              bordercolor=[0.75, 0.75, 0.75, 1.0], bgcolor=[0.0, 0.0, 0.0, 0.0],
                              presentation=1, presentation_rect=[10.0, 38.0, 32.0, 32.0])})
patcher["raw_boxes"] = RAW_BOXES
patcher["overrides"] = _ov
