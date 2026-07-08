"""
f_vf_advect — definition.py

Temporal fluid advection via f_vecfield.
Accumulates flow across frames using a pass_pix / advect_pix feedback loop (Pattern 1).

Two jit.gl.pix inside one bpatcher:
  pass_pix   — identity; holds previous advected frame for feedback
  advect_pix — primary; reads source (in1), vecfield (in2), previous frame (in3)

Outlets:
  0 — composite (wet/dry blended)
  1 — advected  (raw accumulation pre-mix)

Pre-existing bug found and fixed (2026-07-06): this param was declared as
"strength" here while the codebox's actual Param was always named
mix_amt -- attrui's attr is generated from this dict's "name" key, so the
dial was bound to a nonexistent pix attribute ("strength") and never
actually reached the codebox, regardless of the codebox itself being
correct. Matt caught this while debugging an unrelated vorticity-
confinement integration attempt (folded into this module, then reverted
back to the standalone f_vf_vorticity processor after extensive
debugging did not resolve it -- see ideas/vorticity_confinement.md for
the full history). This dict entry is renamed to mix_amt to match the
codebox; display label stays "Strength" -- only the underlying param
name changed. This fix is independent of the confinement work and is
kept even though that work was reverted.
"""

patcher = {
    # Identity
    "name":               "f_vf_advect",
    "prefix":             "vfadvect",
    "title":              "Advect",
    "signal_type":        "vecfield",

    # Presentation
    "presentation_width":  190,
    "presentation_height": 130,

    # Archetype — processor: source texture on in0
    "archetype": "processor",

    # Multi-pix chain
    "pix_chain": [
        {
            "id":        "pass",
            "name":      "#0_advect_pass",
            "gen":       "pass",           # identity gen sentinel
            "n_inlets":  1,
            "n_outlets": 1,
            "pix_type":  "char",
            "adapt":     True,
            "primary":   False,
        },
        {
            "id":        "state",
            "name":      "#0_advect_pix",
            "gen":       "codebox_advect.gen",  # relative to .specify/f_vf_advect/
            "n_inlets":  3,
            "n_outlets": 2,
            "pix_type":  "char",
            "adapt":     True,
            "primary":   True,
        },
    ],

    # Cross-pix feedback wiring
    # [src_id, src_outlet, dst_id, dst_inlet]
    "pix_wires": [
        ["state", 0, "pass",  0],   # state out0 → pass in0  (feedback loop)
        ["pass",  0, "state", 2],   # pass out0  → state in2 (previous frame)
    ],

    # Vecfield inlet — vs_inState gates src_vecfield (suppresses vs_black displacement)
    "mod_inlets": [
        {
            "label":       "vecfield",
            "vs_instate":  True,
            "state_param": "src_vecfield",
        },
    ],

    # Outlets
    "outlets": [
        {"comment": "composite"},
        {"comment": "advected"},
    ],

    # Params
    "params": [
        {
            "name": "dt", "type": "float",
            "min": 0.0, "max": 0.05, "default": 0.01,
            "hint": "Displacement step size per frame -- larger = faster flow",
            "label": "dt",
            "range_tiers": [0.05, 0.5, 1.0],
        },
        {
            "name": "decay", "type": "float",
            "min": 0.8, "max": 1.5, "default": 0.97,
            "hint": "Frame decay -- <1.0 fades, >1.0 amplifies (excitable regime)",
            "label": "Decay",
        },
        {
            "name": "injection", "type": "float",
            "min": 0.0, "max": 0.05, "default": 0.02,
            "hint": "Source injection amount per frame",
            "label": "Inject",
            "range_tiers": [0.05, 0.5, 1.0],
        },
        {
            "name": "mix_amt", "type": "float",
            "min": 0.0, "max": 1.5, "default": 0.0,
            "hint": "Effect strength -- 0=source only, 1=fully advected",
            "label": "Strength",
        },
        {
            "name": "src_vecfield", "type": "internal",
        },
        {
            "name": "bypass", "type": "bypass",
        },
    ],
}
