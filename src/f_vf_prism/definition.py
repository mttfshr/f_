from pathlib import Path

_HERE = Path(__file__).resolve().parent

patcher = {
    "name":               "f_vf_prism",
    "prefix":             "vfprism",
    "object_name":        "vfprism_pix",
    "title":              "Prism",
    "signal_type":        "∇ in/out",
    "archetype":          "processor",
    "pix_type":           "char",

    # Bypass drives the codebox Param `bypass_gate` (jsui -> `prepend param bypass_gate` -> pix),
    # not the native @bypass, which skips the shader and flips secondary outlets.  Every outlet
    # mixes to its passthrough, so a bypassed module is a passthrough (Matt, 2026-10-05; plan.md item 10).
    "bypass_mode":        "param",

    "presentation_width":  190,
    "presentation_height": 122,

    # Three outlets: composite (primary), isolated prism layer, gate-
    # weighted dispersion direction (vecfield, ADR1).  The pix is @type char, so
    # this outlet is 8-bit in practice; `signal_type` below does not change that.
    "outlets": [
        {"comment": "composite"},
        {"comment": "prism", "color": [0.6196078431372549, 0.9529411764705882, 0.6588235294117647, 1.0]},
        {"type": "vec", "comment": "vecfield", "signal_type": "float32"},
    ],

    # Inlet 0: source texture
    # Inlet 1: vecfield
    # Inlet 2: length mod
    # Inlet 3: width mod
    "mod_inlets": [
        {"type": "vec", "label": "vecfield",    "state_param": "src_vecfield"},
        {"label": "reach mod",   "state_param": "src_length_mod"},
        {"label": "spread mod",  "state_param": "src_width_mod"},
    ],

    "params": [
        {"name": "reach",           "type": "float", "min": 0.0, "max": 0.3,  "default": 0.05,  "label": "Reach",    "hint": "Displacement distance along field — how far the prism effect reaches"},
        {"name": "spread",          "type": "float", "min": 0.0, "max": 0.5,  "default": 0.1,   "label": "Spread",   "hint": "Angular spread between R/G/B channels — chromatic separation distance"},
        {"name": "threshold",       "type": "float", "min": 0.0, "max": 1.0,  "default": 0.7,   "label": "Threshold", "hint": "Luma gate — only bright pixels at sample position cast prism color"},
        {"name": "threshold_width", "type": "float", "widget": "numbox", "min": 0.0, "max": 0.5,  "default": 0.1,   "label": "Gate Width","hint": "Softness of the luma gate — blob boundary edge"},
        {"name": "feather",         "type": "float", "widget": "numbox", "min": 0.0, "max": 0.5,  "default": 0.1,   "label": "Feather",   "hint": "Inter-channel blend — 0=hard RGB separation, high=smooth spectral gradient"},
        {"name": "gain",            "type": "float", "widget": "numbox", "min": 0.0, "max": 2.0,  "default": 1.0,   "label": "Gain",  "hint": "Prism intensity — additive over source, before mix"},
        {"name": "mix_pct",         "type": "float", "min": 0.0, "max": 100.0, "default": 100.0, "label": "Mix", "widget": "numbox", "hint": "% strength toward the fully-composited (source+effect) state — a continuous blend, not spatial masking. mix=30 means every pixel is 30% of the way from source toward its own 100%-effect value. (internal Param named mix_pct to avoid colliding with the codebox's mix() operator — see jit-gen-codebox skill)"},
        {"name": "src_vecfield",    "type": "internal"},
        {"name": "src_length_mod",  "type": "internal"},
        {"name": "src_width_mod",   "type": "internal"},
        {"name": "bypass",          "type": "bypass"},
    ],

    "codebox": (_HERE / "codebox_v17.gen").open().read(),
}

# BEGIN overrides (build/capture.py rewrites only this block)
patcher["overrides"] = {
    "feather.ctl": {"presentation_rect": [41.0, 100.0, 34.0, 15.0]},
    "feather.label": {"presentation_rect": [29.5, 82.0, 50.0, 18.0]},
    "gain.ctl": {"presentation_rect": [78.0, 100.0, 34.0, 15.0]},
    "gain.label": {"presentation_rect": [66.5, 82.0, 50.0, 18.0]},
    "mix_pct.ctl": {"presentation_rect": [115.0, 100.0, 34.0, 15.0]},
    "mix_pct.label": {"presentation_rect": [103.5, 82.0, 50.0, 18.0]},
    "reach.ctl": {"presentation_rect": [4.0, 38.0, 27.0, 43.0]},
    "reach.label": {"presentation_rect": [-7.5, 20.0, 50.0, 18.0]},
    "spread.ctl": {"presentation_rect": [41.0, 38.0, 27.0, 43.0]},
    "spread.label": {"presentation_rect": [29.5, 20.0, 50.0, 18.0]},
    "threshold.ctl": {"presentation_rect": [78.0, 38.0, 27.0, 43.0]},
    "threshold.label": {"presentation_rect": [66.5, 20.0, 50.0, 18.0]},
    "threshold_width.ctl": {"presentation_rect": [4.0, 100.0, 34.0, 15.0]},
    "threshold_width.label": {"presentation_rect": [-7.5, 82.0, 50.0, 18.0]},
}
# END overrides
