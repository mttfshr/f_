"""
f_vf_fluid — definition.py

The full definition of the module: build/build_patcher.py builds the shipped patcher from it
(build_cleanup T019, 2026-10-05; until then src/f_vf_fluid/build_fluid.py did, plan ADR-9, because
the generic schema could not express an eight-stage chain).  The keys that made it expressible
(build_cleanup T016/T017; build/spec.md "Multi-stage keys"): per-node `pix_attrs`, `pix_target` lists,
`ui: False` for `taps`, `inlet_fanout` (the force inlet reaches `adv` and `enc` through vs_inState),
`draw_triggers` (`r draw` -> `adv` and `enc`) and `bypass_mode: "param"` (the bypass toggle drives the
codebox Param `bypass_gate` on `enc`, never the native @bypass, plan ADR-8).
This file also feeds the docs/helpfile/param-extraction tooling (build/extract_params.py) and the
bench's archetype lookup.
Spectral (FFT) incompressible-flow VELOCITY SOLVER, a vecfield producer:
a force vecfield goes in, an evolving velocity vecfield comes out. Dye/texture
transport is left to f_vf_advect and friends fed from the outlet.
See .specify/f_vf_fluid/{spec,plan,tasks}.md.

Stage chain (plan ADR-1), solver stages at a fixed 256x256 float32:
    pass -> adv -> fx -> fy -> spec -> iy -> ix -> enc      (ix -> pass feedback)
  adv  self-advect + force        spec  projection + viscosity + drag
  fx/fy/iy/ix  separable DFT      enc   render-res upsample + encode + bypass gate

Defaults were judged by eye in Vsynth and left as built (tasks.md T036, 2026-09-29);
the ranges were not judged separately.
`viscosity` is a 0..1 dial (shader maps it to a per-frame nu*dt, T036). `taps` is the
force tap-grid size (T038a): `"ui": False`, so it keeps its route token and reaches
`adv` by control message, but takes no panel slot — it is a correctness setting fixed
at 8 by GPU measurement, not a performable lever (decided 2026-09-29).
"""

patcher = {
    "name":               "f_vf_fluid",
    "prefix":             "vffluid",
    "title":              "Fluid",
    "signal_type":        "vecfield",

    "presentation_width":  190,
    "presentation_height": 150,

    # processor: the force vecfield arrives on the primary inlet and, when
    # bypassed, passes straight through (see bypass_gate below)
    "archetype": "processor",

    "outlets": [
        {"comment": "velocity vecfield"},
    ],

    "params": [
        {"name": "force", "type": "float", "min": 0.0, "max": 0.2, "default": 0.02,
         "label": "Force",
         "hint": "Velocity gained per frame from the force input at full scale"},
        {"name": "dt", "type": "float", "min": 0.0, "max": 0.05, "default": 0.01,
         "label": "dt",
         "hint": "Self-advection step and the time step of viscosity/drag"},
        {"name": "viscosity", "type": "float", "min": 0.0, "max": 1.0, "default": 0.085,
         "label": "Visc",
         "hint": "Smoothing per frame (independent of dt): 0 = off, high = honey, only the biggest swirls survive"},
        {"name": "project", "type": "float", "min": 0.0, "max": 1.0, "default": 1.0,
         "label": "Project",
         "hint": "0 = compressible (shock fronts), 1 = divergence-free swirl"},
        {"name": "drag", "type": "float", "min": 0.0, "max": 5.0, "default": 0.5,
         "label": "Drag",
         "hint": "Linear damping; keeps sustained or uniform force bounded"},
        {"name": "gain", "type": "float", "min": 0.0, "max": 10.0, "default": 1.0,
         "label": "Gain",
         "hint": "Output scale applied to the velocity before encoding (clamped to the vecfield range)"},
        {"name": "taps", "type": "int", "min": 1, "max": 16, "default": 8,
         "label": "Taps", "ui": False,
         "hint": "Force filter: taps x taps samples per solver texel. Higher = calmer noisy force at HD/4K but costs GPU (8 = ~0.4-0.7 ms, 16 = ~1.5 ms); 1 = off"},

        # Bypass toggle. Unlike every other f_ module this does NOT set the
        # native pix @bypass attribute: the jsui drives the codebox Param
        # `bypass_gate` on the encode stage (jsui -> prepend param bypass_gate).
        # Native bypass skips the shader and flips secondary outlets; here the
        # solver must keep running and an unconnected inlet must pass a neutral
        # field (plan ADR-8).
        {"name": "bypass", "type": "bypass"},

        # Set by vs_inState via `prepend param src_vecfield` (1 = force inlet connected)
        {"name": "src_vecfield", "type": "internal"},
        # Driven by the bypass jsui (`prepend param bypass_gate`), never by the route
        {"name": "bypass_gate", "type": "internal"},
    ],

    # ---- the chain (build/spec.md "Multi-stage keys") ----------------------------------------------
    #   r draw -> adv (in0), enc (in0)        force -> vs_inState -> adv (in1), enc (in1)
    #   pass -> adv (in2) -> fx -> fy -> spec -> iy -> ix -> pass   (feedback)
    #                                               ix -> enc (in2) -> outlet
    # Solver stages are @adapt 0 @dim 256 256 float32; only `enc` follows the render size (the
    # primary, and the one outlet).  The `r draw` bang on `enc` makes it take the render-context
    # size even with the force inlet unconnected (plan ADR-2).
    "inlet_comment": "force vecfield / control",
    "inlet_fanout": {"texture": [["adv", 1], ["enc", 1]],
                     "state": ["adv", "enc"], "state_param": "src_vecfield"},
    "draw_triggers": ["adv", "enc"],
    "bypass_mode": "param",             # jsui -> prepend param bypass_gate -> enc (the primary)

    "pix_chain": [
        {"id": "pass", "name": "#0_fluid_pass", "gen": "pass",                 "n_inlets": 1, "n_outlets": 1,
         "pix_attrs": "@adapt 0 @dim 256 256 @type float32", "primary": False},
        {"id": "adv",  "name": "#0_fluid_adv",  "gen": "codebox_adv.gen",     "n_inlets": 3, "n_outlets": 1,
         "pix_attrs": "@adapt 0 @dim 256 256 @type float32", "primary": False},
        {"id": "fx",   "name": "#0_fluid_fx",   "gen": "codebox_dft_fx.gen",  "n_inlets": 1, "n_outlets": 1,
         "pix_attrs": "@adapt 0 @dim 256 256 @type float32", "primary": False},
        {"id": "fy",   "name": "#0_fluid_fy",   "gen": "codebox_dft_fy.gen",  "n_inlets": 1, "n_outlets": 1,
         "pix_attrs": "@adapt 0 @dim 256 256 @type float32", "primary": False},
        {"id": "spec", "name": "#0_fluid_spec", "gen": "codebox_spec.gen",    "n_inlets": 1, "n_outlets": 1,
         "pix_attrs": "@adapt 0 @dim 256 256 @type float32", "primary": False},
        {"id": "iy",   "name": "#0_fluid_iy",   "gen": "codebox_dft_iy.gen",  "n_inlets": 1, "n_outlets": 1,
         "pix_attrs": "@adapt 0 @dim 256 256 @type float32", "primary": False},
        {"id": "ix",   "name": "#0_fluid_ix",   "gen": "codebox_dft_ix.gen",  "n_inlets": 1, "n_outlets": 1,
         "pix_attrs": "@adapt 0 @dim 256 256 @type float32", "primary": False},
        {"id": "enc",  "name": "#0_fluid_enc",  "gen": "codebox_enc.gen",     "n_inlets": 3, "n_outlets": 1,
         "pix_attrs": "@adapt 1 @type float32", "primary": True},
    ],
    "pix_wires": [
        ["pass", 0, "adv", 2],      # previous state
        ["adv", 0, "fx", 0], ["fx", 0, "fy", 0], ["fy", 0, "spec", 0],
        ["spec", 0, "iy", 0], ["iy", 0, "ix", 0],
        ["ix", 0, "pass", 0],       # feedback edge
        ["ix", 0, "enc", 2],        # velocity -> encode (cold)
    ],
}

# UI parameter -> the stage(s) whose codebox Param it sets (the first is the control's param_connect target).
_STAGES_OF = {"force": "adv", "dt": ["adv", "spec"], "viscosity": "spec", "project": "spec",
              "drag": "spec", "gain": "enc", "taps": "adv"}
for _p in patcher["params"]:
    if _p["name"] in _STAGES_OF:
        _p["pix_target"] = _STAGES_OF[_p["name"]]
