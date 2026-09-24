"""
f_vf_fluid — definition.py

METADATA ONLY. This file feeds the docs/helpfile/param-extraction tooling
(build/extract_params.py, docs pipeline) and the bench's archetype lookup, and
build_fluid.py reads the UI parameter specs from here. It is NOT the input of
build/build_patcher.py: the patcher is built by src/f_vf_fluid/build_fluid.py
(plan ADR-9 — an eight-stage chain that the generic pix_chain schema cannot
express: inlet fan-out through vs_inState, `r draw` triggers, per-stage @dim,
params reaching several stages, a Param-based bypass gate).

Spectral (FFT) incompressible-flow VELOCITY SOLVER, a vecfield producer:
a force vecfield goes in, an evolving velocity vecfield comes out. Dye/texture
transport is left to f_vf_advect and friends fed from the outlet.
See .specify/f_vf_fluid/{spec,plan,tasks}.md.

Stage chain (plan ADR-1), solver stages at a fixed 256x256 float32:
    pass -> adv -> fx -> fy -> spec -> iy -> ix -> enc      (ix -> pass feedback)
  adv  self-advect + force        spec  projection + viscosity + drag
  fx/fy/iy/ix  separable DFT      enc   render-res upsample + encode + bypass gate

Ranges and defaults below are PROVISIONAL (tier-3 tuning is tasks.md T036-T037).
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
        {"name": "viscosity", "type": "float", "min": 0.0, "max": 0.002, "default": 0.0001,
         "label": "Visc",
         "hint": "Kinematic viscosity: exact and stable at any value; high = honey, small scales die"},
        {"name": "project", "type": "float", "min": 0.0, "max": 1.0, "default": 1.0,
         "label": "Project",
         "hint": "0 = compressible (shock fronts), 1 = divergence-free swirl"},
        {"name": "drag", "type": "float", "min": 0.0, "max": 5.0, "default": 0.5,
         "label": "Drag",
         "hint": "Linear damping; keeps sustained or uniform force bounded"},
        {"name": "gain", "type": "float", "min": 0.0, "max": 10.0, "default": 1.0,
         "label": "Gain",
         "hint": "Output scale applied to the velocity before encoding (clamped to the vecfield range)"},

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
}
