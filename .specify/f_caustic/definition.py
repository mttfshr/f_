patcher = {
    "name":               "f_caustic",
    "prefix":             "caustic",
    "object_name":        "caustic_pix",
    "title":              "Caustic",
    "signal_type":        "vecfield",
    "archetype":          "processor",
    "pix_type":           "float32",

    "presentation_width":  227,
    "presentation_height": 100,

    # Two outlets: composited (primary) and isolated caustic layer
    "outlets": [
        {"comment": "composite"},
        {"comment": "caustic", "color": [0.6196078431372549, 0.9529411764705882, 0.6588235294117647, 1.0]},
    ],

    # Inlet 1: vecfield, direct (no vs_inState — zero field = no caustic, correct silent behavior)
    "mod_inlets": [
        {"label": "vecfield", "vs_instate": False},
    ],

    "params": [
        {"name": "strength",    "type": "float", "min": 0.0, "max": 1.5, "default": 0.0,  "label": "Strength"},
        {"name": "intensity",   "type": "float", "min": 0.0, "max": 2.0, "default": 0.5,  "label": "Intens"},
        {"name": "scale",       "type": "float", "min": 0.0, "max": 1.0, "default": 0.3,  "label": "Scale"},
        {"name": "softness",    "type": "float", "min": 0.0, "max": 1.0, "default": 0.3,  "label": "Soft"},
        {"name": "color_shift", "type": "float", "min": 0.0, "max": 1.0, "default": 0.0,  "label": "Color"},
        {"name": "bypass",      "type": "bypass"},
    ],

    "codebox": open("/Users/matt/Github/f_/.specify/f_caustic/codebox_v2.gen").read(),
}
