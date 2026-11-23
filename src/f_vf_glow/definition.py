patcher = {
    "name":               "f_vf_glow",
    "prefix":             "vfglow",
    "object_name":        "vfglow_pix",
    "title":              "Glow",
    "signal_type":        "∇ in",
    "archetype":          "processor",
    "pix_type":           "char",

    # Bypass drives the codebox Param `bypass_gate` (jsui -> `prepend param bypass_gate` -> pix),
    # not the native @bypass, which skips the shader and flips out2.  Both outlets mix to the
    # source, so a bypassed module is a passthrough (Matt, 2026-10-05; plan.md item 10).
    "bypass_mode":        "param",

    "presentation_width":  190,
    "presentation_height": 122,

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
        {"name": "falloff",     "type": "float", "widget": "numbox", "min": 0.0,  "max": 0.05, "default": 0.002, "label": "Falloff"},
        {"name": "gain",        "type": "float", "widget": "numbox", "min": 0.0,  "max": 1.5,  "default": 0.8,   "label": "Gain", "hint": "Glow intensity. Renamed from strength 2026-07-12 to match the library-wide gain/mix naming convention."},
        {"name": "mix_pct",     "type": "float", "min": 0.0,  "max": 100.0,"default": 0.0,   "label": "Mix", "widget": "numbox", "hint": "Dry/wet crossfade toward the fully-composited (source+glow) state. Internal Param named mix_pct to avoid colliding with the codebox's mix() operator — see jit-gen-codebox skill. Default 0 (off by default, matching this module's original load behavior)."},
        {"name": "color_mix",   "type": "float", "widget": "numbox", "min": 0.0,  "max": 1.0,  "default": 0.0,   "label": "Color"},
        {"name": "direction",   "type": "int",   "min": 0,    "max": 2,    "default": 0,     "label": "Dir"},
        {"name": "src_vecfield", "type": "internal"},
        {"name": "bypass",      "type": "bypass"},
    ],

    "codebox": open("/Users/matt/Github/f_/src/f_vf_glow/codebox_v1.gen").read(),
}

# BEGIN overrides (build/capture.py rewrites only this block)
patcher["overrides"] = {
    "color_mix.ctl": {"presentation_rect": [115.0, 100.0, 34.0, 15.0]},
    "color_mix.label": {"presentation_rect": [103.5, 82.0, 50.0, 18.0]},
    "direction.ctl": {"presentation_rect": [152.0, 100.0, 34.0, 15.0]},
    "direction.label": {"presentation_rect": [140.5, 82.0, 50.0, 18.0]},
    "falloff.ctl": {"presentation_rect": [4.0, 100.0, 34.0, 15.0]},
    "falloff.label": {"presentation_rect": [-7.5, 82.0, 50.0, 18.0]},
    "gain.ctl": {"presentation_rect": [41.0, 100.0, 34.0, 15.0]},
    "gain.label": {"presentation_rect": [29.5, 82.0, 50.0, 18.0]},
    "mix_pct.ctl": {"presentation_rect": [78.0, 100.0, 34.0, 15.0]},
    "mix_pct.label": {"presentation_rect": [66.5, 82.0, 50.0, 18.0]},
    "radius.ctl": {"presentation_rect": [4.0, 38.0, 27.0, 43.0]},
    "radius.label": {"presentation_rect": [-7.5, 20.0, 50.0, 18.0]},
}
# END overrides
