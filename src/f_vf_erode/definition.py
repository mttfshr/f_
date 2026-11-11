"""
f_vf_erode -- definition.py

Ink that pools like a wash on paper (spec rewritten 2026-11-10, Matt; the 2026-11-09 extent/bulge design is in git).
A picture goes in; on a wetting it becomes pigment on the paper and the frame is flooded. Water then runs over a terrain
(inlet 1) pushed by a vecfield (inlet 2), lifts pigment off the paper where it runs fast and puts it down where it slows, so
ink pools in the low places and leaves the high ones. Inlet 3 is the background the pigment sits on. Polarity: Darker filters
a background that is white when unconnected, Lighter adds over a black one.
Spec, plan, tasks: .specify/f_vf_erode/{spec,plan,tasks}.md. Mirror: tests/modules/vf_erode/vf_erode_mirror.py.

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
    "signal_type": "tex in/out",
    "archetype":   "processor",

    "presentation_width":  190,
    "presentation_height": 150,      # two dial rows end at y 143; the Wet button took the empty first slot (Matt, 2026-11-10)

    "outlets": [
        {"comment": "ink (composite over the background)"},
        {"comment": "thickness (pigment on the paper)"},
    ],

    "params": [
        {"name": "polar_sw", "type": "text_button", "options": ["Darker", "Lighter"], "default": 0, "label": "Polarity",
         "pix_target": ["load", "enc"],
         "hint": "Darker: the pigment filters the background, white when inlet 3 is unconnected. Lighter: it adds to a black background. A change takes effect at the next wetting"},
        {"name": "flow", "type": "float", "min": 0.0, "max": 2.0, "default": 0.4, "label": "Flow",
         "pix_target": ["prep", "transport", "react"],
         "hint": "How strongly the water runs downhill on the terrain (inlet 1). PROVISIONAL"},
        {"name": "push", "type": "float", "min": 0.0, "max": 4.0, "default": 1.0, "label": "Push",
         "pix_target": "prep",
         "hint": "How strongly the vecfield (inlet 2) moves the water. 0 is the same as no vecfield. PROVISIONAL"},
        {"name": "lift", "type": "float", "min": 0.0, "max": 2.0, "default": 0.9, "label": "Lift",
         "pix_target": "react",
         "hint": "How readily running water takes pigment off the paper. PROVISIONAL"},
        {"name": "settle", "type": "float", "min": 0.0, "max": 0.05, "default": 0.004, "label": "Settle",
         "pix_target": "react",
         "hint": "How readily slow water puts pigment back down. Water that has gone puts all of it down. PROVISIONAL"},
        {"name": "dry", "type": "float", "min": 0.0, "max": 0.02, "default": 0.0016, "label": "Dry",
         "pix_target": "transport",
         "hint": "How fast the water goes, per step. A dried wash is still. PROVISIONAL"},
        {"name": "speed", "type": "float", "min": 0.0, "max": 4.0, "default": 1.0, "label": "Speed",
         "pix_target": ["prep", "transport", "react"],
         "hint": "Step size of each solver step; limited inside the solver so the water stays stable. PROVISIONAL"},
        {"name": "flood", "type": "float", "min": 0.0, "max": 4.0, "default": 1.0, "label": "Flood",
         "pix_target": "load",
         "hint": "How much water a wetting adds. It is added to any water still on the paper. PROVISIONAL"},
        {"name": "feed", "type": "float", "min": 0.0, "max": 1.0, "default": 0.0, "label": "Feed",
         "pix_target": "load",
         "hint": "A continuous source for an animated or live picture: each step a fraction of what the picture holds beyond the paper is deposited, and the water relaxes toward Flood. 0 is wet once. A still picture on a flat frame converges to itself. PROVISIONAL"},
        {"name": "fade", "type": "float", "min": 0.0, "max": 1.0, "default": 0.02, "label": "Fade",
         "pix_target": "load",
         "hint": "With Feed above 0: how fast ink above what the picture holds returns to the picture, so a picture that gets lighter is followed and the frame does not go black. Small = pooled ink lasts about 1 / Fade frames. 0 = it never fades. PROVISIONAL"},
        {"name": "wet", "type": "gate_button", "label": "Wet", "gate_param": "wet_gate",
         "rect": [3.5, 46.0, 28.0, 28.0], "label_rect": [-7.5, 20.0, 50.0, 18.0],     # column 0 of the first dial row, under its label (Matt, 2026-11-10)
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


# The Darker / Lighter toggle lives in the title bar (Matt, 2026-11-10), like f_weave's mode controls: [Erode] [Darker] ... [type label] [bypass].
# The title shrinks to its text; the toggle is 52 px wide so it clears the right-justified "tex in/out" label (its text starts near x 109).
patcher["overrides"] = {
    "title":        {"presentation_rect": [10.5, 0.0, 40.0, 21.0]},
    "polar_sw.ctl": {"presentation_rect": [50.0, 3.0, 52.0, 15.0]},
}
