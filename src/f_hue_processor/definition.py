# f_hue_processor patcher definition
#
# Rewritten 2026-10-05 (build_cleanup T014) from the shipped, hand-built patcher.
#
# The generic part (the dials the builder can make exactly, the routing, bypass, the moduleSize chain)
# comes from the builder. The rest is a hand-built band editor and is carried verbatim in
# `raw_ui.json` (derived by build/capture_raw.py): the `falloff` dial (its widget varname differs from its Param, `edge_falloff`), the `Rot` label, the two band numboxes `hue_lower` / `hue_upper`, one more numbox, and the `hue_rslider.js` band editor with its `hue_range.js` helper.
# The dial / label positions are an `overrides` block (build/capture.py).
#
# `legacy` preserves what Max wrote when it re-created these objects, so the shipped patch stays
# byte-faithful and need not be regenerated: see build/spec.md, "legacy".
import json
from pathlib import Path

_HERE = Path(__file__).parent
_RAW = json.loads((_HERE / "raw_ui.json").read_text()) if (_HERE / "raw_ui.json").exists() else {}


patcher = {
    "name":        "f_hue_processor",
    "prefix":      "hp",
    "object_name": "hp_pix",
    "title":       "Hue Processor",
    "archetype":   "processor",
    "pix_type":    "char",
    "pix_context": "drawto",        # jit.gl.pix @name hp_pix @drawto vsynth @type char
    "route_bypass": True,           # the oldest modules route a `bypass 0/1` message to the toggle
    "route_reject_to_pix": True,    # ...and send what no route token claims to the pix

    "presentation_width":  150,
    "presentation_height": 120,

    # Params in the shipped route order (bypass, sat_amt, lum_shift, hue_shift, edge_falloff). The raw_ui
    # params come last, as they do in the route; the band parameters have no route token (internal).
    "params": [
        {"name": "sat_amt",   "type": "float", "min": -1.0,   "max": 1.0,   "default": 0.0, "label": "Sat", "hint": "Saturation", "color_expression": None},
        {"name": "lum_shift", "type": "float", "min": -1.0,   "max": 1.0,   "default": 0.0, "label": "Lum", "hint": "Luminosity", "color_expression": None},
        {"name": "hue_shift", "type": "float", "min": -180.0, "max": 180.0, "default": 0.0, "label": None,  "hint": "Hue rotation", "color_expression": None},
        {"name": "edge_falloff", "type": "raw_ui"},
        {"name": "hue_center", "type": "internal"},
        {"name": "hue_lower",  "type": "internal"},
        {"name": "hue_upper",  "type": "internal"},
        {"name": "bypass", "type": "bypass"},
    ],

    "outlets": [{"comment": ''}],
    "inlet_comment": '',

    # newline="": a shipped codebox can carry CRLF line endings, which text mode would convert
    "codebox": (_HERE / "codebox_hue_processor.gen").open(newline="").read(),

    "legacy": {
        "pix_varname":       "jit.gl.pix_AA",
        "autopattr_varname": "u099020110",
    },

    "raw_boxes":      _RAW.get("raw_boxes", []),
    "raw_lines":      _RAW.get("raw_lines", []),
    "raw_parameters": _RAW.get("raw_parameters", {}),
}

# BEGIN overrides (build/capture.py rewrites only this block)
patcher["overrides"] = {
    "hue_shift.ctl": {"activedialcolor": None, "needlemode": 2, "presentation_rect": [116.25, 70.0, 27.0, 43.0]},
    "lum_shift.ctl": {"activedialcolor": None, "presentation_rect": [79.75, 70.0, 27.0, 43.0]},
    "lum_shift.label": {"fontsize": 9.0, "presentation_rect": [81.25, 56.5, 27.0, 17.0], "textjustification": None},
    "panel": {"background": None, "bgcolor": [0.058823529411764705, 0.058823529411764705, 0.058823529411764705, 1.0]},
    "sat_amt.ctl": {"activedialcolor": None, "presentation_rect": [42.0, 69.75, 27.0, 43.0]},
    "sat_amt.label": {"fontsize": 9.0, "presentation_rect": [44.5, 56.5, 25.5, 17.0], "textjustification": None},
    "title": {"fontsize": None, "numinlets": 0, "presentation_rect": [-0.3333333432674408, 1.0000000298023224, 88.0, 21.0], "suppressinlet": 1},
}
# END overrides
