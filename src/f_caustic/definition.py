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
        {"name": "mix_pct",     "type": "float", "min": 0.0, "max": 100.0, "default": 0.0,  "label": "Mix", "widget": "numbox", "hint": "Dry/wet crossfade toward the fully-composited (source+caustic) state. Renamed from strength 2026-07-12, range capped to true 0-100% (dropping the old 0-1.5 extrapolation zone). Internal Param named mix_pct to avoid colliding with the codebox's mix() operator."},
        {"name": "gain",        "type": "float", "min": 0.0, "max": 2.0, "default": 0.5,  "label": "Gain", "hint": "Caustic brightness scale. Renamed from intensity 2026-07-12 to match the library-wide gain/mix naming convention."},
        {"name": "scale",       "type": "float", "min": 0.0, "max": 1.0, "default": 0.3,  "label": "Scale"},
        {"name": "softness",    "type": "float", "min": 0.0, "max": 1.0, "default": 0.3,  "label": "Soft"},
        {"name": "color_shift", "type": "float", "min": 0.0, "max": 1.0, "default": 0.0,  "label": "Color"},
        {"name": "bypass",      "type": "bypass"},
    ],

    "codebox": open("/Users/matt/Github/f_/src/f_caustic/codebox_v2.gen").read(),
}
