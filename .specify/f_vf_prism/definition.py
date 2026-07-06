patcher = {
    "name":               "f_vf_prism",
    "prefix":             "vfprism",
    "object_name":        "vfprism_pix",
    "title":              "Prism",
    "signal_type":        "vecfield",
    "archetype":          "processor",
    "pix_type":           "char",

    "presentation_width":  190,
    "presentation_height": 160,

    # Two outlets: composite (primary) and isolated prism layer
    "outlets": [
        {"comment": "composite"},
        {"comment": "prism", "color": [0.6196078431372549, 0.9529411764705882, 0.6588235294117647, 1.0]},
    ],

    # Inlet 1: source texture
    # Inlet 2: vecfield
    # Inlet 3: length mod
    # Inlet 4: width mod
    "mod_inlets": [
        {"label": "vecfield",    "state_param": "src_vecfield"},
        {"label": "reach mod",   "state_param": "src_length_mod"},
        {"label": "spread mod",  "state_param": "src_width_mod"},
    ],

    "params": [
        {"name": "reach",           "type": "float", "min": 0.0, "max": 0.3,  "default": 0.05,  "label": "Reach",    "hint": "Displacement distance along field — how far the prism effect reaches"},
        {"name": "spread",          "type": "float", "min": 0.0, "max": 0.5,  "default": 0.1,   "label": "Spread",   "hint": "Angular spread between R/G/B channels — chromatic separation distance"},
        {"name": "threshold",       "type": "float", "min": 0.0, "max": 1.0,  "default": 0.7,   "label": "Threshold", "hint": "Luma gate — only bright pixels at sample position cast prism color"},
        {"name": "threshold_width", "type": "float", "min": 0.0, "max": 0.5,  "default": 0.1,   "label": "Gate Width","hint": "Softness of the luma gate — blob boundary edge"},
        {"name": "feather",         "type": "float", "min": 0.0, "max": 0.5,  "default": 0.1,   "label": "Feather",   "hint": "Inter-channel blend — 0=hard RGB separation, high=smooth spectral gradient"},
        {"name": "strength",        "type": "float", "min": 0.0, "max": 2.0,  "default": 1.0,   "label": "Strength",  "hint": "Prism intensity — additive over source on out1"},
        {"name": "src_vecfield",    "type": "internal"},
        {"name": "src_length_mod",  "type": "internal"},
        {"name": "src_width_mod",   "type": "internal"},
        {"name": "bypass",          "type": "bypass"},
    ],

    "codebox": open("/Users/matt/Github/f_/.specify/f_vf_prism/codebox_v15.gen").read(),
}
