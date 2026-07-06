patcher = {
    "name":               "f_vf_streak",
    "prefix":             "vfstreak",
    "object_name":        "vfstreak_pix",
    "title":              "Streak",
    "signal_type":        "vecfield",
    "archetype":          "processor",
    "pix_type":           "char",

    "presentation_width":  190,
    "presentation_height": 100,

    # Two outlets: composite (primary) and isolated streak layer
    "outlets": [
        {"comment": "composite"},
        {"comment": "streak", "color": [0.6196078431372549, 0.9529411764705882, 0.6588235294117647, 1.0]},
    ],

    # Inlet 1: vecfield texture, via vs_inState + state_param (suppress silent offset)
    "mod_inlets": [
        {"label": "vecfield", "state_param": "src_vecfield"},
    ],

    "params": [
        {"name": "strength",    "type": "float", "min": 0.0,  "max": 1.5,  "default": 0.0,  "label": "Strength"},
        {"name": "length",      "type": "float", "min": 0.0,  "max": 20.0, "default": 0.15, "label": "Length"},
        {"name": "falloff",     "type": "float", "min": 0.0,  "max": 2.5,  "default": 0.0,  "label": "Falloff"},
        {"name": "color_shift", "type": "float", "min": 0.0,  "max": 20.0, "default": 0.0,  "label": "Color"},
        {"name": "src_vecfield", "type": "internal"},
        {"name": "bypass",      "type": "bypass"},
    ],

    "codebox": open("/Users/matt/Github/f_/.specify/f_vf_streak/codebox_v1.gen").read(),
}
