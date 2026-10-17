# f_tf_axisflow patcher definition
# Input to build/build_patcher.py
# Spec: .specify/f_tf_axisflow/{spec,plan,tasks}.md   Created: 2026-10-16
#
# Single-pix processor: tensormap outlet 1 (packed axis) in, signed vecfield out. The reference
# direction is projected onto the edge line (or its normal), so there is no atan2 and no sign
# choice. BYPASS: bypass_mode "param" -> `Param bypass_gate` (neutral vecfield), not native @bypass.
#
# `dim` reads 1 inside live jit.gl.pix (see f_tf_tensormap), so width/height are Params, used
# for the aspect conversion that keeps the vector's pixel-space direction.
from pathlib import Path

_HERE = Path(__file__).parent

patcher = {
    "name":        "f_tf_axisflow",
    "prefix":      "axisflow",
    "object_name": "axisflow_pix",
    "title":       "Axis Flow",
    "signal_type": "vecfield out",
    "archetype":   "processor",
    "pix_type":    "float32",
    "bypass_mode": "param",

    "presentation_width":  150,
    "presentation_height": 100,

    "codebox": (_HERE / "codebox_axisflow.gen").open(newline="").read(),

    "outlets": [
        {"comment": "vecfield",
         "hint": "Signed vecfield: R,G = v*0.5+0.5, B = 0.5, A = 1. The reference direction projected onto the edge line (Along) or the gradient axis (Across); no seam. Neutral = (0.5, 0.5, 0.5, 1)."},
    ],

    "params": [
        {"name": "mode", "type": "menu", "options": ["Along", "Across"], "default": 0,
         "label": "Mode",
         "hint": "Along: flow follows the edges. Across: flow crosses them (gradient direction)."},
        {"name": "angle", "type": "float", "min": -180.0, "max": 180.0, "default": 0.0,
         "label": "Angle",
         "hint": "Reference direction in degrees. Flow is strongest where an edge runs parallel to it and fades to zero where an edge is perpendicular to it (Along)."},
        {"name": "gain", "type": "float", "min": 0.0, "max": 10.0, "default": 1.0,
         "label": "Gain",
         "hint": "Output amplitude. Vecfield units are the short side of the frame, so consumers usually want small values."},
        {"name": "gate", "type": "float", "min": 0.0, "max": 1.0, "default": 1.0,
         "label": "Gate",
         "hint": "0 = ignore coherence; 1 = scale flow by coherence so it follows only confident structure."},
        {"name": "width", "type": "float", "min": 64.0, "max": 8192.0, "default": 640.0,
         "widget": "numbox", "label": "Width",
         "hint": "Render width in pixels. Set to the real frame width: it keeps the flow direction true on non-square frames. (Live jit.gl.pix cannot read its own size, so this is exposed for now.)"},
        {"name": "height", "type": "float", "min": 64.0, "max": 8192.0, "default": 480.0,
         "widget": "numbox", "label": "Height",
         "hint": "Render height in pixels. Set to the real frame height."},
        {"name": "bypass", "type": "bypass"},
    ],
}
