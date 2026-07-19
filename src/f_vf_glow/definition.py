patcher = {
    "name":               "f_vf_glow",
    "prefix":             "vfglow",
    "object_name":        "vfglow_pix",
    "title":              "Glow",
    "signal_type":        "vecfield",
    "archetype":          "processor",
    "pix_type":           "char",

    "presentation_width":  190,
    "presentation_height": 120,

    # Two outlets: composited (primary) and isolated glow layer
    "outlets": [
        {"comment": "composite"},
        {"comment": "glow", "color": [0.6196078431372549, 0.9529411764705882, 0.6588235294117647, 1.0]},
    ],

    # Inlet 1: vecfield; Inlet 2: radius mod
    "mod_inlets": [
        {"label": "vecfield", "state_param": "src_vecfield"},
        {"label": "radius mod"},
    ],

    "params": [
        {"name": "radius",      "type": "float", "min": 0.0,  "max": 0.2,  "default": 0.01,  "label": "Radius"},
        {"name": "falloff",     "type": "float", "min": 0.0,  "max": 0.05, "default": 0.002, "label": "Falloff"},
        {"name": "gain",        "type": "float", "min": 0.0,  "max": 1.5,  "default": 0.8,   "label": "Gain", "hint": "Glow intensity. Renamed from strength 2026-07-12 to match the library-wide gain/mix naming convention."},
        {"name": "mix_pct",     "type": "float", "min": 0.0,  "max": 100.0,"default": 0.0,   "label": "Mix", "widget": "numbox", "hint": "Dry/wet crossfade toward the fully-composited (source+glow) state. Internal Param named mix_pct to avoid colliding with the codebox's mix() operator — see jit-gen-codebox skill. Default 0 (off by default, matching this module's original load behavior)."},
        {"name": "color_mix",   "type": "float", "min": 0.0,  "max": 1.0,  "default": 0.0,   "label": "Color"},
        {"name": "direction",   "type": "int",   "min": 0,    "max": 2,    "default": 0,     "label": "Dir"},
        {"name": "src_vecfield", "type": "internal"},
        {"name": "bypass",      "type": "bypass"},
    ],

    "codebox": open("/Users/matt/Github/f_/src/f_vf_glow/codebox_v1.gen").read(),
}
