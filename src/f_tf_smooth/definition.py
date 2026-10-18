# f_tf_smooth patcher definition
# Input to build/build_patcher.py
# Spec: .specify/f_tf_smooth/{spec,plan,tasks}.md   Created: 2026-10-17
#
# ARCHITECTURE (plan ADR-2): two-domain pix_chain, the f_vf_advect precedent.
#
#   state  (primary, 2 inlets / 1 outlet): in1 = this frame's raw tensor +
#          all params; in2 = the blended tensor fed back one frame later.
#          Computes T' = T_new + release*(T_prev - T_new), per channel,
#          unclamped (ADR-3): the feedback path is raw float32 arithmetic,
#          no decode, no atan2, no encode.
#   render (support, 1 inlet / 1 outlet): identity passthrough. Its OUTLET is
#          the module's raw-tensor outlet AND the texture that loops back
#          into state's in2.
#
# Wiring: routepass -> state in0 (automatic, primary); pix_wires supplies the
# loop ["render",0,"state",1]. state out0 -> render in0; render out0 ->
# module outlet 0 (outlet_source_override {0: "render"} + raw_lines, the
# f_vf_optical_flow "real output node is not the primary" pattern).
#
# BYPASS: bypass_mode "param", bypass_target the state pix (primary): the
# toggle drives `Param bypass_gate` in codebox_state.gen only, where bypass
# is an EXACT PASSTHROUGH of the inlet tensor with the feedback ignored
# (plan ADR-4) -- not a freeze of the last smoothed frame. The render node
# has no params and needs no gate.
#
# Object ids derived by hand from build_patcher.py's formulas (build/spec.md):
# 2 UI params (release, bypass) -> chain_id_base = 50; support node render =
# obj-50; outlet 0 = obj-2. If the param count or chain order changes,
# recompute. Codeboxes are relative to this definition.py's directory
# (src/f_tf_smooth/, the built-module layout; plan ADR-6).

patcher = {
    "name":        "f_tf_smooth",
    "prefix":      "smooth",
    "object_name": "#0_smooth_pix",
    "title":       "Tensor Smooth",
    "signal_type": "tensor out",
    "archetype":   "processor",
    "bypass_mode": "param",

    "presentation_width":  154,
    "presentation_height": 84,

    "pix_chain": [
        {
            "id":        "state",
            "name":      "#0_smooth_state",
            "gen":       "codebox_state.gen",
            "n_inlets":  2,
            "n_outlets": 1,
            "pix_type":  "float32",
            "adapt":     True,
            "primary":   True,
        },
        {
            "id":        "render",
            "name":      "#0_smooth_render",
            "gen":       "codebox_render.gen",
            "n_inlets":  1,
            "n_outlets": 1,
            "pix_type":  "float32",
            "adapt":     True,
            "primary":   False,
        },
    ],

    # [src_id, src_outlet, dst_id, dst_inlet]
    "pix_wires": [
        ["state",  0, "render", 0],   # blended tensor -> passthrough render node
        ["render", 0, "state",  1],   # render out = previous blended tensor -> state in2 (feedback loop)
    ],

    "outlets": [
        {"comment": "tensor (raw Jxx, Jxy, Jyy)", "color": [0.85, 0.55, 0.2, 1.0],
         "hint": "Raw structure tensor, smoothed in time: same encoding as the input "
                 "(f_tensor_type.md outlet 0; R = Jxx*strength, G = Jxy*strength*0.5 + 0.5, "
                 "B = Jyy*strength, A = 1). Neutral (zero tensor) = (0, 0.5, 0, 1). "
                 "No decode, no angle doubling -- output type equals input type."},
    ],

    # The real outlet comes from the render passthrough node, not the
    # primary(state) pix -- suppresses the automatic state->outlet wire.
    "outlet_source_override": {0: "render"},

    "raw_lines": [
        {"patchline": {"source": ["obj-50", 0], "destination": ["obj-2", 0]}},  # render out (raw tensor) -> outlet 0
    ],

    "params": [
        {
            "name": "release", "type": "float",
            "min": 0.0, "max": 1.0, "default": 0.5,
            "hint": "Feedback coefficient: T' = T_new + release*(T_prev - T_new). "
                    "0 = passthrough (no residue from frame 1); higher = longer memory "
                    "(0.3 light, 0.5 default, 0.9 heavy inertia). PROVISIONAL default "
                    "and ceiling -- OQ1 gate open, tier-3 judgement on live noise "
                    "pending (same discipline as tensormap's strength calibration).",
            "label": "Release",
        },
        {"name": "bypass", "type": "bypass"},
    ],
}

# Layout mirrors f_tf_tensormap (same 154x84 panel; release dial + bypass jsui).
patcher["overrides"] = {
    "bypass_jsui": {"presentation_rect": [129.0, 5.0, 18.0, 12.0]},
    "signal_type": {"fontsize": 9.5, "presentation_rect": [62.0, 3.0, 60.0, 18.0]},
}