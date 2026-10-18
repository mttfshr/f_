# f_tf_sharpen patcher definition
# Input to build/build_patcher.py
# Spec: .specify/f_tf_sharpen/{spec,plan,tasks}.md   Created: 2026-10-17
#
# Single-pix processor, the simplest shape in the f_tf family (plan ADR-1):
# one codebox, one pass, one inlet (driving tensor + control), one outlet.
# Gap scale on the raw tensor's eigengap; the axis rides through in component
# space (no atan2 in the codebox -- glyph plan ADR-2 idiom, cited there).
#
# BYPASS: bypass_mode "param" -> `Param bypass_gate` in the codebox (exact
# passthrough), never the native @bypass (f_tf_axisflow / tensormap precedent).
#
# Params: sharpen (the gap multiplier gamma). DIAL MAPPING PROVISIONAL
# (spec OQ1 gate open, tasks T016 pending Matt): one-sided 0-4, default 1.0
# (1 = neutral, <1 relaxes toward isotropy, >1 exaggerates). Linear; the
# "log-scaled around 1" curve variant stays an OQ1 alternative, decided in
# tier 3. If the mapping changes, update the codebox comment (GATE
# PROVISIONAL-OPEN marker) and this min/max/default together.
# Floor is NOT a param (plan ADR-3: fixed internal eps_trace = 1e-6, tensormap
# T019 convention).
from pathlib import Path

_HERE = Path(__file__).parent

patcher = {
    "name":        "f_tf_sharpen",
    "prefix":      "sharpen",
    "object_name": "#0_sharpen_pix",
    "title":       "Sharpen",
    "signal_type": "T_ in/out",
    "archetype":   "processor",
    "pix_type":    "float32",
    "bypass_mode": "param",

    "presentation_width":  154,
    "presentation_height": 84,

    "codebox": (_HERE / "codebox_sharpen.gen").open(newline="").read(),

    "outlets": [
        {"comment": "tensor (raw Jxx, Jxy, Jyy)",
         "color": [0.85, 0.55, 0.2, 1.0],
         "hint": "Raw structure tensor, gap-scaled: R = Jxx'*strength, G = Jxy'*strength*0.5 + 0.5, B = Jyy'*strength, A = 1. Gap = 1 is exact passthrough; relax (<1) eases toward isotropy, exaggerate (>1) commits edges. Axis never changes; trace preserved inside the linear range. Neutral (zero tensor) = (0, 0.5, 0, 1)."},
    ],

    "params": [
        {
            "name": "sharpen", "type": "float",
            "min": 0.0, "max": 4.0, "default": 1.0,
            "hint": "Eigengap multiplier: 1 = neutral, below 1 relaxes the field toward isotropy, above 1 exaggerates anisotropy (commit edges). Linear, one-sided 0-4 (provisional; gate open).",
            "label": "Sharpen",
        },
        {"name": "bypass", "type": "bypass"},
    ],
}

# Layout: single dial in row 1; matches the one/two-param module shape.
patcher["overrides"] = {
    "bypass_jsui": {"presentation_rect": [129.0, 5.0, 18.0, 12.0]},
    "sharpen.ctl":  {"presentation_rect": [4.0, 38.0, 27.0, 43.0]},
    "sharpen.label": {"presentation_rect": [-8.0, 20.0, 50.0, 18.0]},
}