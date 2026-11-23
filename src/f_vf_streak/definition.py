patcher = {
    "name":               "f_vf_streak",
    "prefix":             "vfstreak",
    "object_name":        "vfstreak_pix",
    "title":              "Streak",
    "signal_type":        "∇ in",
    "archetype":          "processor",
    "pix_type":           "char",

    # Bypass drives the codebox Param `bypass_gate` (jsui -> `prepend param bypass_gate` -> pix),
    # not the native @bypass, which skips the shader and flips secondary outlets.  Every outlet
    # mixes to its passthrough, so a bypassed module is a passthrough (Matt, 2026-10-05; plan.md item 10).
    "bypass_mode":        "param",

    "presentation_width":  190,
    "presentation_height": 122,

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
        {"name": "gain",        "type": "float", "widget": "numbox", "min": 0.0,  "max": 1.5,  "default": 0.3,  "label": "Gain", "hint": "Streak intensity. Renamed from strength 2026-07-12 to match the library-wide gain/mix naming convention."},
        {"name": "mix_pct",     "type": "float", "min": 0.0,  "max": 100.0,"default": 0.0,  "label": "Mix", "widget": "numbox", "hint": "Dry/wet crossfade toward the fully-composited (source+streak) state. Internal Param named mix_pct to avoid colliding with the codebox's mix() operator. Default 0 (off by default, matching this module's original load behavior)."},
        {"name": "length",      "type": "float", "min": 0.0,  "max": 20.0, "default": 0.15, "label": "Length"},
        {"name": "falloff",     "type": "float", "widget": "numbox", "min": 0.0,  "max": 1.99, "default": 0.0,  "label": "Falloff"},
        {"name": "color_shift", "type": "float", "widget": "numbox", "min": 0.0,  "max": 20.0, "default": 0.0,  "label": "Color"},
        {"name": "src_vecfield", "type": "internal"},
        {"name": "bypass",      "type": "bypass"},
    ],

    "codebox": open("/Users/matt/Github/f_/src/f_vf_streak/codebox_v1.gen").read(),
}

# BEGIN overrides (build/capture.py rewrites only this block)
patcher["overrides"] = {
    "color_shift.ctl": {"presentation_rect": [115.0, 100.0, 34.0, 15.0]},
    "color_shift.label": {"presentation_rect": [103.5, 82.0, 50.0, 18.0]},
    "falloff.ctl": {"presentation_rect": [78.0, 100.0, 34.0, 15.0]},
    "falloff.label": {"presentation_rect": [66.5, 82.0, 50.0, 18.0]},
    "gain.ctl": {"presentation_rect": [4.0, 100.0, 34.0, 15.0]},
    "gain.label": {"presentation_rect": [-7.5, 82.0, 50.0, 18.0]},
    "length.ctl": {"presentation_rect": [4.0, 38.0, 27.0, 43.0]},
    "length.label": {"presentation_rect": [-7.5, 20.0, 50.0, 18.0]},
    "mix_pct.ctl": {"presentation_rect": [41.0, 100.0, 34.0, 15.0]},
    "mix_pct.label": {"presentation_rect": [29.5, 82.0, 50.0, 18.0]},
}
# END overrides
