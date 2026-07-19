patcher = {
    "name":               "f_vf_chroma",
    "prefix":             "vfchroma",
    "object_name":        "vfchroma_pix",
    "title":              "Chroma",
    "signal_type":        "vecfield",
    "archetype":          "processor",
    "pix_type":           "char",

    "presentation_width":  190,
    "presentation_height": 180,

    # Two outlets: composite (primary) and isolated streak layer
    "outlets": [
        {"comment": "composite"},
        {"comment": "streak", "color": [0.6196078431372549, 0.9529411764705882, 0.6588235294117647, 1.0]},
    ],

    # Inlet 1: vecfield (required)
    # Inlets 2–3: hue mod, dispersion mod
    "mod_inlets": [
        {"label": "vecfield",       "state_param": "src_vecfield"},
        {"label": "hue mod",        "state_param": "src_hue_mod"},
        {"label": "dispersion mod", "state_param": "src_dispersion_mod"},
    ],

    "params": [
        {"name": "radius",          "type": "float", "min": 0.0, "max": 0.3,  "default": 0.05,  "label": "Radius",      "hint": "March distance — how far the streak extends"},
        {"name": "hue",             "type": "float", "min": 0.0, "max": 1.0,  "default": 0.0,   "label": "Hue",         "hint": "Base hue — start of the rainbow sweep"},
        {"name": "dispersion",      "type": "float", "min": 0.0, "max": 1.0,  "default": 0.5,   "label": "Dispersion",  "hint": "Hue sweep width — 0=monochrome, 1=full spectrum across streak"},
        {"name": "saturation",      "type": "float", "min": 0.0, "max": 1.0,  "default": 1.0,   "label": "Saturation",  "hint": "Streak color saturation"},
        {"name": "falloff",         "type": "float", "min": 0.0, "max": 0.01, "default": 0.002, "label": "Falloff",     "hint": "Decay rate along streak — higher = shorter, sharper streak"},
        {"name": "threshold",       "type": "float", "min": 0.0, "max": 1.0,  "default": 0.8,   "label": "Threshold",   "hint": "Luma gate floor — only pixels above this emit streak"},
        {"name": "threshold_width", "type": "float", "min": 0.0, "max": 0.5,  "default": 0.1,   "label": "Gate Width",  "hint": "Softness of the luma gate — 0=hard step, 0.5=gradual"},
        {"name": "strength",        "type": "float", "min": 0.0, "max": 2.0,  "default": 0.8,   "label": "Strength",    "hint": "Streak intensity — additive over source on out1"},
        {"name": "direction",       "type": "text_button", "options": ["Fwd", "Bwd", "Bi"], "default": 0, "label": "Direction", "hint": "Forward: streak away from source; Backward: toward source; Bi: both"},
        {"name": "src_vecfield",    "type": "internal"},
        {"name": "src_hue_mod",     "type": "internal"},
        {"name": "src_dispersion_mod", "type": "internal"},
        {"name": "bypass",          "type": "bypass"},
    ],

    "codebox": open("/Users/matt/Github/f_/src/f_vf_chroma/codebox_v10.gen").read(),
}
