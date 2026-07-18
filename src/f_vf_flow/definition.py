"""
f_vf_flow — definition.py

Dual-mode vecfield generator. Takes an optional scalar texture on inlet 0.
Unconnected: uniform direction field — all vectors point same way (angle param).
Connected: direction varies spatially following texture luminance * spread.

Output: float32 RG vecfield (0.5 = zero vector).
Bypass: neutral vecfield (0.5, 0.5) — not passthrough.

Signal chain: [optional scalar] → f_vf_flow → f_weave (vecfield inlet)
"""

patcher = {
    "name":               "f_vf_flow",
    "prefix":             "vfflow",
    "object_name":        "vfflow_pix",
    "title":              "Flow",
    "archetype":          "dual",
    "pix_type":           "float32",
    "signal_type":        "vecfield",

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
            "name": "src_mode", "type": "internal",
        },
        {
            "name": "bypass", "type": "bypass",
        },
    ],

    "codebox": open("/Users/matt/Github/f_/.specify/f_vf_flow/codebox_flow.gen").read(),
}
