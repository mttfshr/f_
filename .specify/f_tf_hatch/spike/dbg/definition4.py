# SCRATCH debug patcher 4 (not shipped): the REAL f_tf_hatch E1 and E2 codeboxes followed by a
# display stage (codebox_d3.gen) that shows what E2 receives and produces in the live chain.
# Build:  build/py.sh build/build_patcher.py .specify/f_tf_hatch/spike/dbg/definition4.py
# Writes package/patchers/f_tf_hatch_dbg4.maxpat (UNTRACKED; delete it when done).

CODEBOX_DIR = ""

SRC = "../../../../src/f_tf_hatch/"   # relative to this file: the shipped codeboxes

patcher = {
    "name":        "f_tf_hatch_dbg4",
    "prefix":      "hatchdbg4",
    "object_name": "#0_hatchdbg4_pix",
    "title":       "HatchDbg4",
    "signal_type": "T_ in",
    "archetype":   "processor",
    "bypass_mode": "param",
    "bypass_target": "d3",

    "presentation_width":  190,
    "presentation_height": 150,

    "pix_chain": [
        {"id": "e1", "name": "#0_hatchdbg4_stage_e1", "gen": SRC + "codebox_stage_e1.gen",
         "n_inlets": 1, "n_outlets": 1, "pix_type": "float32", "adapt": True, "primary": True},
        {"id": "e2", "name": "#0_hatchdbg4_stage_e2", "gen": SRC + "codebox_stage_e2.gen",
         "n_inlets": 1, "n_outlets": 1, "pix_type": "float32", "adapt": True, "primary": False},
        {"id": "d3", "name": "#0_hatchdbg4_stage_d3", "gen": "codebox_d3.gen",
         "n_inlets": 2, "n_outlets": 1, "pix_type": "float32", "adapt": True, "primary": False},
    ],
    "pix_wires": [
        ["e1", 0, "e2", 0],
        ["e2", 0, "d3", 0],
        ["e1", 0, "d3", 1],
    ],

    "outlets": [
        {"comment": "debug view",
         "color": [0.55, 0.55, 0.55, 1.0],
         "hint": "Scratch debug view. NOT a tensor, not a vecfield. @type float32."},
    ],
    "outlet_source": {0: ["d3", 0]},

    "params": [
        {"name": "reach", "type": "float", "min": 0.0, "max": 1.0, "default": 0.5,
         "hint": "Same as Hatch Length.", "label": "Length", "pix_target": "e2"},
        {"name": "grain", "type": "float", "min": 0.0, "max": 1.0, "default": 0.5,
         "hint": "Same as Hatch Grain.", "label": "Grain", "pix_target": "e2"},
        {"name": "density", "type": "float", "min": 0.0, "max": 1.0, "default": 0.7,
         "hint": "Same as Hatch Density.", "label": "Density", "pix_target": "e2"},
        {"name": "structure_floor", "type": "float", "min": 0.0, "max": 1.0, "default": 0.1,
         "hint": "Same as Hatch Floor.", "label": "Floor", "pix_target": "e1"},
        {"name": "angle_offset", "type": "float", "min": -1.0, "max": 1.0, "default": 0.0,
         "hint": "Same as Hatch Offset.", "label": "Offset", "pix_target": "e1"},
        {"name": "view", "type": "float", "min": 0.0, "max": 1.0, "default": 0.0,
         "hint": "0-.2 E2 raw; .2-.4 axis; .4-.6 coherence; .6-.8 presence; .8-1 dim bars.",
         "label": "View", "pix_target": "d3"},
        {"name": "gain", "type": "float", "min": 0.0, "max": 1.0, "default": 0.5,
         "hint": "Multiplier for the E2 raw view: 0.01x .. 100x (0.5 = x1).",
         "label": "Gain", "pix_target": "d3"},
                {"name": "width", "type": "float", "min": 64.0, "max": 8192.0, "default": 640.0, "widget": "numbox",
         "hint": "Render width in pixels (E2).", "label": "Width", "pix_target": "e2"},
        {"name": "height", "type": "float", "min": 64.0, "max": 8192.0, "default": 480.0, "widget": "numbox",
         "hint": "Render height in pixels (E2).", "label": "Height", "pix_target": "e2"},
        {"name": "bypass", "type": "bypass"},
    ],
}

patcher["overrides"] = {}
# END overrides
