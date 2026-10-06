# f_tone_curve patcher definition
#
# Rewritten 2026-10-05 (build_cleanup T014) from the shipped, hand-built patcher.
#
# The generic part (the dials the builder can make exactly, the routing, bypass, the moduleSize chain)
# comes from the builder. The rest is a hand-built band editor and is carried verbatim in
# `raw_ui.json` (derived by build/capture_raw.py): the three band labels (Shdws / Mids / Highs), the two crossover numboxes `low_mid` / `mid_high` (route tokens), one more numbox, and a hand-built curve jsui.
# The dial / label positions are an `overrides` block (build/capture.py).
#
# `legacy` preserves what Max wrote when it re-created these objects, so the shipped patch stays
# byte-faithful and need not be regenerated: see build/spec.md, "legacy".
import json
from pathlib import Path

_HERE = Path(__file__).parent
_RAW = json.loads((_HERE / "raw_ui.json").read_text()) if (_HERE / "raw_ui.json").exists() else {}


patcher = {
    "name":        "f_tone_curve",
    "prefix":      "tone",
    "object_name": "tone_curve",
    "title":       "Tone Curve",
    "archetype":   "processor",
    "pix_type":    "char",
    "pix_context": "drawto",        # jit.gl.pix @name tone_curve @drawto vsynth @type char
    "route_bypass": True,           # the oldest modules route a `bypass 0/1` message to the toggle
    "route_reject_to_pix": True,    # ...and send what no route token claims to the pix

    "presentation_width":  150,
    "presentation_height": 120,

    # Params in the shipped route order (bypass, shadows, midtones, highlights, edge_falloff, low_mid,
    # mid_high); the raw_ui params come last, as they do in the route.
    "params": [
        {"name": "shadows",      "type": "float", "min": -1.0, "max": 1.0, "default": 0.0, "label": None,      "hint": "Shadows", "color_expression": None},
        {"name": "midtones",     "type": "float", "min": -1.0, "max": 1.0, "default": 0.0, "label": None,      "hint": "Midtones", "color_expression": None},
        {"name": "highlights",   "type": "float", "min": -1.0, "max": 1.0, "default": 0.0, "label": None,      "hint": "Highlights", "color_expression": None},
        {"name": "edge_falloff", "type": "float", "min": 0.0,  "max": 1.0, "default": 0.0, "label": "Falloff", "hint": "Edge falloff", "color_expression": None},
        {"name": "low_mid",  "type": "raw_ui"},
        {"name": "mid_high", "type": "raw_ui"},
        {"name": "bypass", "type": "bypass"},
    ],

    "outlets": [{"comment": 'texture'}],
    "inlet_comment": 'texture / control',

    # newline="": a shipped codebox can carry CRLF line endings, which text mode would convert
    "codebox": (_HERE / "codebox_tone_curve.gen").open(newline="").read(),

    "legacy": {
        # three dials saved without parameter_linknames (the builder writes 1)
        "control_valueof": {"shadows": {"parameter_linknames": None}, "midtones": {"parameter_linknames": None},
                            "highlights": {"parameter_linknames": None}},
        # the compact falloff dial had its param_connect removed by hand
        "control_box": {"edge_falloff": {"param_connect": None}},
        "pix_varname":       "jit.gl.pix_AA",
        "autopattr_varname": "u288002127",
        "bypass_jsui_saved": {"valueof": {"parameter_invisible": 1, "parameter_longname": "bypass", "parameter_modmode": 4,
                                          "parameter_shortname": "bypass", "parameter_type": 1, "parameter_unitstyle": 0}},
    },

    "raw_boxes":      _RAW.get("raw_boxes", []),
    "raw_lines":      _RAW.get("raw_lines", []),
    "raw_parameters": _RAW.get("raw_parameters", {}),
}

# BEGIN overrides (build/capture.py rewrites only this block)
patcher["overrides"] = {
    "bypass_jsui": {"presentation_rect": [126.25, 6.5, 18.0, 12.0]},
    "edge_falloff.ctl": {"activedialcolor": None, "appearance": 1, "presentation_rect": [6.5, 79.375, 25.0, 23.0], "shownumber": 0, "triangle": None},
    "edge_falloff.label": {"fontsize": 9.0, "presentation_rect": [2.5, 59.375, 35.0, 17.0], "textjustification": None},
    "highlights.ctl": {"activedialcolor": None, "presentation_rect": [116.0000034570694, 73.33333551883698, 27.0, 43.0]},
    "midtones.ctl": {"activedialcolor": None, "presentation_rect": [79.00000235438347, 73.33333551883698, 27.0, 43.0]},
    "panel": {"background": None, "bgcolor": [0.058823529411764705, 0.058823529411764705, 0.058823529411764705, 1.0]},
    "shadows.ctl": {"activedialcolor": None, "presentation_rect": [42.66666793823242, 73.33333551883698, 27.0, 43.0]},
    "title": {"presentation_rect": [2.0000000596046448, 2.6666667461395264, 94.0, 21.0]},
}
# END overrides
