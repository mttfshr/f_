"""
f_vf_potential — definition.py

Scalar potential field integrator. Takes a vecfield (float32 RG) and accumulates
field magnitude over time via ping-pong feedback. Output is a 0-1 scalar (greyscale)
whose level sets are isolines of integrated flow — directly usable as f_weave
scalar inlet to produce curved isoline texture.

Signal chain: f_vf_repulse → f_vf_potential → f_weave (scalar in)

Two jit.gl.pix inside one bpatcher:
  pass_pix      — identity; holds previous potential frame for feedback
  potential_pix — primary; reads vecfield (in2), prev frame (in3), accumulates
"""

patcher = {
    "name":               "f_vf_potential",
    "prefix":             "vfpotential",
    "title":              "Potential",
    "signal_type":        "vecfield",

    "presentation_width":  190,
    "presentation_height": 100,

    "archetype": "processor",

    "pix_chain": [
        {
            "id":        "pass",
            "name":      "#0_potential_pass",
            "gen":       "pass",
            "n_inlets":  1,
            "n_outlets": 1,
            "pix_type":  "float32",
            "adapt":     True,
            "primary":   False,
        },
        {
            "id":        "state",
            "name":      "#0_potential_pix",
            "gen":       "codebox_potential.gen",
            "n_inlets":  4,
            "n_outlets": 1,
            "pix_type":  "float32",
            "adapt":     True,
            "primary":   True,
        },
    ],

    "pix_wires": [
        ["state", 0, "pass",  0],   # state out0 → pass in0  (feedback loop)
        ["pass",  0, "state", 3],   # pass out0  → state in3 (previous frame)
    ],

    "mod_inlets": [
        {
            "label":       "vecfield",
            "vs_instate":  True,
            "state_param": "src_vecfield",
        },
        {
            "label":       "color",
            "vs_instate":  True,
            "state_param": "src_color",
        },
    ],

    "outlets": [
        {"comment": "scalar potential"},
    ],

    "params": [
        {
            "name": "dt", "type": "float",
            "min": 0.0, "max": 0.05, "default": 0.01,
            "hint": "Accumulation step size per frame -- larger = faster tracking",
            "label": "dt",
        },
        {
            "name": "decay", "type": "float",
            "min": 0.8, "max": 1.0, "default": 0.98,
            "hint": "Frame decay -- lower = faster fade, higher = longer memory",
            "label": "Decay",
        },
        {
            "name": "strength", "type": "float",
            "min": 0.0, "max": 2.0, "default": 1.0,
            "hint": "Output scale",
            "label": "Strength",
        },
        {
            "name": "src_vecfield", "type": "internal",
        },
        {
            "name": "src_color", "type": "internal",
        },
        {
            "name": "bypass", "type": "bypass",
        },
    ],
}
