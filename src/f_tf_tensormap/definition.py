# f_tf_tensormap patcher definition
# Input to build/build_patcher.py
# Spec: .specify/f_tf_tensormap/{spec,plan,tasks}.md   Created: 2026-10-16
#
# ARCHITECTURE NOTE -- primary node vs. real output node
#
# Same shape as f_vf_optical_flow (see its definition.py): the source texture
# must reach stage_a (the primary), but the real outlets come from stage_c, the
# last node. So both outlets are redirected to stage_c via outlet_source_override
# (suppresses the automatic primary->outlet wire) + raw_lines (supplies the real
# stage_c->outlet wires).
#
# BYPASS: bypass_mode "param" with bypass_target "c": the toggle drives
# `Param bypass_gate` in stage_c only (never the native @bypass, which would skip
# the shader and flip secondary outlets). Under bypass both outlets are the
# zero-tensor neutral values; stages A and B keep running (nothing reads them).
#
# Hardcoded object ids below are derived by hand from build_patcher.py's id
# formulas, NOT kept in sync automatically. Chain order [a(primary), bh, bv, c]:
#   4 UI params (strength, radius, width, height) -> chain_id_base = 50
#   support nodes: bh = obj-50, bv = obj-51, c = obj-52
#   outlet ids: outlet 0 = obj-2, outlet 1 = obj-201
# If the param count or chain order changes, recompute these.
#
# `dim` reads 1 inside live Vsynth jit.gl.pix objects (tf_probe.maxpat,
# 2026-10-16), so tap spacing comes from the width/height Params instead
# (exposed for now, per Matt). Stages clamp coordinates in-shader because the
# bench GPU wraps out-of-range reads.

CODEBOX_DIR = ""  # gen paths below are relative to this definition.py's own directory

patcher = {
    "name":        "f_tf_tensormap",
    "prefix":      "tensormap",
    "object_name": "tensormap_pix",
    "title":       "Map",
    "signal_type": "T_ out",
    "archetype":   "processor",
    "bypass_mode": "param",
    "bypass_target": "c",

    "presentation_width":  154,
    "presentation_height": 84,

    "pix_chain": [
        {
            "id":        "a",
            "name":      "#0_tm_stage_a",
            "gen":       "codebox_stage_a.gen",
            "n_inlets":  1,
            "n_outlets": 1,
            "pix_type":  "float32",
            "primary":   True,
        },
        {
            "id":        "bh",
            "name":      "#0_tm_stage_b_h",
            "gen":       "codebox_stage_b_h.gen",
            "n_inlets":  1,
            "n_outlets": 1,
            "pix_type":  "float32",
            "primary":   False,
        },
        {
            "id":        "bv",
            "name":      "#0_tm_stage_b_v",
            "gen":       "codebox_stage_b_v.gen",
            "n_inlets":  1,
            "n_outlets": 1,
            "pix_type":  "float32",
            "primary":   False,
        },
        {
            "id":        "c",
            "name":      "#0_tm_stage_c",
            "gen":       "codebox_stage_c.gen",
            "n_inlets":  1,
            "n_outlets": 2,
            "pix_type":  "float32",
            "primary":   False,
        },
    ],

    # [src_id, src_outlet, dst_id, dst_inlet]
    "pix_wires": [
        ["a",  0, "bh", 0],   # gradient products -> horizontal smooth
        ["bh", 0, "bv", 0],   # -> vertical smooth
        ["bv", 0, "c",  0],   # smoothed tensor -> eigen + both encodings
    ],

    "outlets": [
        {"comment": "tensor (raw Jxx, Jxy, Jyy)",
         "color": [0.85, 0.55, 0.2, 1.0],
         "hint": "Raw structure tensor: R = Jxx*strength, G = Jxy*strength*0.5 + 0.5, B = Jyy*strength, A = 1. Sign-safe: no angle doubling. Neutral (zero tensor) = (0, 0.5, 0, 1)."},
        {"comment": "tensor packed (cos2t, sin2t, trace, coherence)",
         "color": [0.85, 0.35, 0.55, 1.0],
         "hint": "Convenience outlet: R = cos(2 theta)*0.5+0.5, G = sin(2 theta)*0.5+0.5, B = clamp(trace*strength), A = coherence (0-1, gain-free). Angle-DOUBLED: do not feed R/G to sign-sensitive consumers (warp, advect, caustic, fluid, potential, seeds); decode theta = 0.5*atan2 first. Neutral = (0.5, 0.5, 0, 0)."},
    ],

    # Suppress the automatic primary(stage_a)->outlet wiring; the real wires
    # are the raw_lines below (see architecture note).
    "outlet_source_override": {0: "c", 1: "c"},

    "raw_lines": [
        {"patchline": {"source": ["obj-52", 0], "destination": ["obj-2",   0]}},  # stage_c out1 (raw tensor) -> outlet 0
        {"patchline": {"source": ["obj-52", 1], "destination": ["obj-201", 0]}},  # stage_c out2 (packed)       -> outlet 1
    ],

    "params": [
        {
            "name": "strength", "type": "float",
            "min": 1.0, "max": 1000.0, "default": 100.0,
            "exponent": 4.0,
            "hint": "Gain on trace and the raw tensor terms before clamping (not on coherence). Trace is gradient squared, so the useful gain scales with feature size squared: roughly 35 for fine detail, 150 medium, 900 coarse/smooth content (at radius 3, 640x480). Log-style dial.",
            "label": "Strength",
            "pix_target": "c",
        },
        {
            "name": "radius", "type": "float",
            "min": 0.0, "max": 16.0, "default": 3.0,
            "hint": "Smoothing radius in pixels (box, 0-16). 0 = no smoothing. Cost depends on the fixed maximum (16), not this value. Pixels only if width/height match the render size.",
            "label": "Radius",
            "pix_target": ["bh", "bv"],
        },
        {
            "name": "width", "type": "float",
            "min": 64.0, "max": 8192.0, "default": 640.0,
            "widget": "numbox",
            "hint": "Render width in pixels. Set to the real frame width: it sets the one-pixel tap step. (Live jit.gl.pix cannot read its own size, so this is exposed for now.)",
            "label": "Width",
            "pix_target": ["a", "bh"],
        },
        {
            "name": "height", "type": "float",
            "min": 64.0, "max": 8192.0, "default": 480.0,
            "widget": "numbox",
            "hint": "Render height in pixels. Set to the real frame height: it sets the vertical tap step.",
            "label": "Height",
            "pix_target": ["a", "bv"],
        },
        {"name": "bypass", "type": "bypass"},
    ],
}

# Layout (2026-10-16, Matt: panel too narrow, width/height cropped): the four controls run to x ~ 150.
patcher["overrides"] = {
    "bypass_jsui": {"presentation_rect": [129.0, 5.0, 18.0, 12.0]},
}
