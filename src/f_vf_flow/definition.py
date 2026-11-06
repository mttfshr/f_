"""
f_vf_flow — definition.py

Vecfield processor (Matt, 2026-11-01: flow needs a texture; it is not a dual). Takes a scalar texture on inlet 0 and
turns its red channel into a flow direction: angle * 2pi + (red - 0.5) * spread * 2pi. With nothing connected it
renders nothing (no uniform-field mode, no render trigger).

Output: float32 RG vecfield (0.5 = zero vector).
Bypass: neutral vecfield (0.5, 0.5) — not passthrough.

Signal chain: [texture] → f_vf_flow → any vecfield inlet
"""

patcher = {
    "name":               "f_vf_flow",
    "prefix":             "vfflow",
    "object_name":        "vfflow_pix",
    "title":              "Flow",
    "archetype":          "processor",
    "pix_type":           "float32",
    "signal_type":        "∇ out",

    # Bypass drives the codebox Param `bypass_gate`, not the native @bypass, which skips the shader
    # and would send the raw input texture downstream as a vecfield (G-bypass-native, Matt 2026-11-06).
    "bypass_mode":        "param",

    "presentation_width":  150,
    "presentation_height": 80,

    "outlets": [
        {"comment": "vecfield out"},
    ],

    "params": [
        {
            "name": "angle", "type": "float",
            "min": 0.0, "max": 1.0, "default": 0.0,
            "hint": "Base flow direction (0-1 = full circle)",
            "label": "Angle",
        },
        {
            "name": "spread", "type": "float",
            "min": 0.0, "max": 1.0, "default": 0.5,
            "hint": "How much the texture perturbs direction (0=uniform, 1=full rotation)",
            "label": "Spread",
        },
        {
            "name": "bypass", "type": "bypass",
        },
    ],

    "codebox": open("/Users/matt/Github/f_/src/f_vf_flow/codebox_flow.gen").read(),

    # The shipped spread dial's saved valueof still says mmin -1.0 (left over from when spread was
    # bipolar; its range is 0..1). Kept as shipped; unverified whether Max rewrites it on load.
    "legacy": {
        "control_valueof": {"spread": {"parameter_mmin": -1.0}},
    },
}
