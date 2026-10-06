"""
f_vf_advect — definition.py

Temporal fluid advection via f_vecfield.
Accumulates flow across frames using a pass_pix / advect_pix feedback loop (Pattern 1).

Two jit.gl.pix inside one bpatcher:
  pass_pix   — holds the previous advected frame for feedback; also owns `separate` and `mode`
               (the shipped pass codebox is real code, not an identity)
  advect_pix — primary; reads source (in1), vecfield (in2), previous frame (in3)

Outlets:
  0 — composite (wet/dry blended, `gain` then `mix_pct`)
  1 — advected  (raw accumulation pre-mix)
  2 — vecfield  (gradient of the accumulated flow; always live, even under bypass)

Rewritten 2026-10-05 (build_cleanup T014) from the shipped, hand-edited patcher. This file, its
codeboxes and the old `build_advect.py` all predated the July dry/wet/gain work (mix_amt -> gain +
mix_pct, `mode` as a menu, `separate`, the third outlet), which went into the patch by hand. The
codeboxes in this directory are now the shipped ones byte for byte, and `build_patcher.py` builds
this definition directly (build_advect.py is retired). The patch reproduces exactly, so it is off
the never-regenerate list; there is nothing to regenerate (a rebuild would only renumber ids and
reformat what Max last saved).

`mix_pct` answers to `mix` on the control inlet (route_name): that is what ships. Other modules'
`mix_pct` answers to `mix_pct`; see build_cleanup/tasks.md T014.
"""

patcher = {
    # Identity
    "name":               "f_vf_advect",
    "prefix":             "vfadvect",
    "title":              "Advect",
    "signal_type":        "vecfield in",

    # Presentation
    "presentation_width":  190,
    "presentation_height": 150,

    # Archetype — processor: source texture on in0
    "archetype": "processor",

    # Multi-pix chain
    "pix_chain": [
        {
            "id":        "pass",
            "name":      "#0_advect_pass",
            "gen":       "codebox_advect_pass.gen",   # relative to src/f_vf_advect/
            "n_inlets":  1,
            "n_outlets": 1,
            "pix_type":  "float32",
            "adapt":     True,
            "primary":   False,
        },
        {
            "id":        "state",
            "name":      "#0_advect_pix",
            "gen":       "codebox_advect.gen",
            "n_inlets":  3,
            "n_outlets": 3,
            "pix_type":  "float32",
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
        {"comment": "vecfield"},
    ],

    # Params.  `"hint": None` = the shipped control has no hint key at all (build/spec.md).
    "params": [
        {"name": "dt",        "type": "float", "min": 0.0, "max": 0.05, "default": 0.01, "label": "dt", "hint": None},
        {"name": "decay",     "type": "float", "min": 0.8, "max": 1.5,  "default": 0.97, "label": "Decay", "hint": None},
        {"name": "injection", "type": "float", "min": 0.0, "max": 0.2,  "default": 0.02, "label": "Inject", "hint": None},
        {"name": "gain",      "type": "float", "min": 0.0, "max": 4.0,  "default": 1.0,  "label": "Gain", "hint": None},
        {
            "name": "mix_pct", "type": "float", "min": 0.0, "max": 100.0, "default": 100.0,
            "label": "Mix", "widget": "numbox", "route_name": "mix",
            "hint": "Wet/dry crossfade -- 0=source only, 100=fully advected",
        },
        # separate and mode live in the pass pix's codebox, not the primary's
        {"name": "separate",  "type": "float", "min": -2.0, "max": 2.0, "default": 0.0, "label": "Separate",
         "hint": None, "pix_target": "pass"},
        {"name": "mode",      "type": "menu", "options": ["Ride", "Hold", "Snap"], "default": 0,
         "label": "Mode", "hint": None, "pix_target": "pass"},
        {"name": "src_vecfield", "type": "internal"},
        {"name": "bypass",       "type": "bypass"},
    ],
}

# BEGIN overrides (build/capture.py rewrites only this block)
patcher["overrides"] = {
    "signal_type": {"fontsize": 9.5, "textcolor": [0.35, 0.75, 0.95, 1.0]},
}
# END overrides
