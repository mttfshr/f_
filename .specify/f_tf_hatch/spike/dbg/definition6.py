# SCRATCH debug patcher 6 (not shipped): the REAL f_tf_hatch E1 and E2 codeboxes followed by a
# display stage (codebox_d3.gen) that shows what E2 receives and produces in the live chain.
# Build:  build/py.sh build/build_patcher.py .specify/f_tf_hatch/spike/dbg/definition6.py
# Writes package/patchers/f_tf_hatch_dbg6.maxpat (UNTRACKED; delete it when done).

CODEBOX_DIR = ""

SRC = "../../../../src/f_tf_hatch/"   # relative to this file: the shipped codeboxes

patcher = {
    "name":        "f_tf_hatch_dbg6",
    "prefix":      "hatchdbg6",
    "object_name": "#0_hatchdbg6_pix",
    "title":       "HatchDbg6",
    "signal_type": "T_ in",
    "archetype":   "processor",
    "bypass_mode": "param",
    "bypass_target": "d3",

    "presentation_width":  190,
    "presentation_height": 150,

    "pix_chain": [
        {"id": "e1", "name": "#0_hatchdbg6_stage_e1", "gen": SRC + "codebox_stage_e1.gen",
         "n_inlets": 1, "n_outlets": 1, "pix_type": "float32", "primary": True},
        {"id": "e2", "name": "#0_hatchdbg6_stage_e2", "gen": "codebox_e2_dim.gen",
         "n_inlets": 1, "n_outlets": 1, "pix_type": "float32", "primary": False},
        {"id": "d3", "name": "#0_hatchdbg6_stage_d3", "gen": "codebox_d3.gen",
         "n_inlets": 2, "n_outlets": 1, "pix_type": "float32", "primary": False},
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
                {"name": "bypass", "type": "bypass"},
    ],
}


# The Vsynth convention (vs_edges, vs_pixelator): a global [r dim] into each jit.gl.pix's left inlet.
# vs_render sends `dim W H`; the message sets the pix's dim attribute. Pix ids: primary obj-5,
# support obj-50, obj-51 in chain order.
patcher["raw_boxes"] = [
    {"box": {"id": "obj-dimr", "maxclass": "newobj", "numinlets": 0, "numoutlets": 1,
             "outlettype": [""], "patching_rect": [10.0, 10.0, 40.0, 22.0], "text": "r dim"}},
    # ...and ask Vsynth to re-send the size at load (vs_pixelator / vs_filter_spat: loadbang -> s trig_res;
    # vs_render answers `r trig_res` with `pak dim i i` -> `s dim`). Without this a module added after
    # the render started never receives a value.
    {"box": {"id": "obj-dimlb", "maxclass": "newobj", "numinlets": 1, "numoutlets": 1,
             "outlettype": ["bang"], "patching_rect": [60.0, 10.0, 60.0, 22.0], "text": "loadbang"}},
    {"box": {"id": "obj-dimst", "maxclass": "newobj", "numinlets": 1, "numoutlets": 0,
             "patching_rect": [60.0, 40.0, 70.0, 22.0], "text": "s trig_res"}},
]
patcher["raw_lines"] = [
    {"patchline": {"source": ["obj-dimr", 0], "destination": [t, 0]}} for t in ("obj-5", "obj-50", "obj-51")
]

patcher["raw_lines"].append({"patchline": {"source": ["obj-dimlb", 0], "destination": ["obj-dimst", 0]}})

patcher["overrides"] = {}
# END overrides
