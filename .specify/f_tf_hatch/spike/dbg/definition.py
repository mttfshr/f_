# SCRATCH debug patcher (not shipped): shows what f_tf_hatch's E1 receives from the live tensor.
# Build:  build/py.sh build/build_patcher.py .specify/f_tf_hatch/spike/dbg/definition.py
# Writes package/patchers/f_tf_hatch_dbg.maxpat (UNTRACKED; delete it when done).
# Drop it where Hatch sits (after Smooth); the outlet goes to the render chain as usual.

CODEBOX_DIR = ""

patcher = {
    "name":        "f_tf_hatch_dbg",
    "prefix":      "hatchdbg",
    "object_name": "#0_hatchdbg_pix",
    "title":       "HatchDbg",
    "signal_type": "T_ in",
    "archetype":   "processor",
    "bypass_mode": "param",
    "bypass_target": "e1",

    "presentation_width":  190,
    "presentation_height": 90,

    "pix_chain": [
        {
            "id":        "e1",
            "name":      "#0_hatchdbg_stage_e1",
            "gen":       "codebox_dbg.gen",
            "n_inlets":  1,
            "n_outlets": 1,
            "pix_type":  "float32",
            "primary":   True,
        },
    ],
    "pix_wires": [],

    "outlets": [
        {"comment": "debug view",
         "color": [0.55, 0.55, 0.55, 1.0],
         "hint": "Scratch debug view of the tensor Hatch receives. NOT a tensor, not a vecfield. @type float32."},
    ],

    "params": [
        {"name": "view", "type": "float", "min": 0.0, "max": 1.0, "default": 0.0,
         "hint": "0-.25 raw R,G,B; .25-.5 coherence; .5-.75 axis colours; .75-1 presence.",
         "label": "View", "pix_target": "e1"},
        {"name": "gain", "type": "float", "min": 0.0, "max": 1.0, "default": 0.5,
         "hint": "Multiplier for the raw view: 0.01x .. 100x (0.5 = x1).",
         "label": "Gain", "pix_target": "e1"},
        {"name": "structure_floor", "type": "float", "min": 0.0, "max": 1.0, "default": 0.1,
         "hint": "Same floor as Hatch (presence view).",
         "label": "Floor", "pix_target": "e1"},
        {"name": "bypass", "type": "bypass"},
    ],
}

patcher["overrides"] = {}
# END overrides
