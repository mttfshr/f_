# f_luma_processor patcher definition
#
# Rewritten 2026-10-05 (build_cleanup T014) from the shipped, hand-built patcher.
#
# The generic part (the dials the builder can make exactly, the routing, bypass, the moduleSize chain)
# comes from the builder. The rest is a hand-built band editor and is carried verbatim in
# `raw_ui.json` (derived by build/capture_raw.py): the `falloff` dial (its widget varname differs from its Param, `edge_falloff`), the `Rot` label, the two band numboxes `low_mid` / `mid_high` (route tokens), one more numbox, and a hand-built band-editor jsui.
# The dial / label positions are an `overrides` block (build/capture.py).
#
# `legacy` preserves what Max wrote when it re-created these objects, so the shipped patch stays
# byte-faithful and need not be regenerated: see build/spec.md, "legacy".
import json
from pathlib import Path

_HERE = Path(__file__).parent
_RAW = json.loads((_HERE / "raw_ui.json").read_text()) if (_HERE / "raw_ui.json").exists() else {}


patcher = {
    "name":        "f_luma_processor",
    "prefix":      "luma",
    "object_name": "luma_pix",
    "title":       "Luma Processor",
    "archetype":   "processor",
    "pix_type":    "char",
    "pix_context": "drawto",        # jit.gl.pix @name luma_pix @drawto vsynth @type char
    "route_bypass": True,           # the oldest modules route a `bypass 0/1` message to the toggle
    "route_reject_to_pix": True,    # ...and send what no route token claims to the pix

    "presentation_width":  150,
    "presentation_height": 120,

    # Params in the shipped route order (bypass, sat_amt, lum_shift, hue_shift, edge_falloff, low_mid,
    # mid_high); the raw_ui params come last, as they do in the route.
    "params": [
        {"name": "sat_amt",   "type": "float", "min": -1.0,   "max": 1.0,   "default": 0.0, "label": "Sat", "hint": "Saturation", "color_expression": None},
        {"name": "lum_shift", "type": "float", "min": -1.0,   "max": 1.0,   "default": 0.0, "label": "Lum", "hint": "Luminosity", "color_expression": None},
        {"name": "hue_shift", "type": "float", "min": -180.0, "max": 180.0, "default": 0.0, "label": None,  "hint": "Hue rotation", "color_expression": None},
        {"name": "edge_falloff", "type": "raw_ui"},
        {"name": "low_mid",      "type": "raw_ui"},
        {"name": "mid_high",     "type": "raw_ui"},
        {"name": "bypass", "type": "bypass"},
    ],

    "outlets": [{"comment": 'texture'}],
    "inlet_comment": 'texture / control',

    # newline="": a shipped codebox can carry CRLF line endings, which text mode would convert
    "codebox": (_HERE / "codebox_luma_processor.gen").open(newline="").read(),

    "legacy": {
        "pix_varname":       "jit.gl.pix_AA",
        "autopattr_varname": "u099020110",
        "bypass_jsui_saved": {"valueof": {"parameter_invisible": 1, "parameter_longname": "bypass", "parameter_modmode": 4,
                                          "parameter_shortname": "bypass", "parameter_type": 1, "parameter_unitstyle": 0}},
    },

    "raw_boxes":      _RAW.get("raw_boxes", []),
    "raw_lines":      _RAW.get("raw_lines", []),
    "raw_parameters": _RAW.get("raw_parameters", {}),
}

# BEGIN overrides (build/capture.py rewrites only this block)
patcher["overrides"] = {
    "bypass_jsui": {"presentation_rect": [129.0, 4.0, 18.0, 12.0]},
    "hue_shift.ctl": {"activedialcolor": None, "needlemode": 2, "presentation_rect": [116.33333680033684, 70.00000208616257, 27.0, 43.0]},
    "lum_shift.ctl": {"activedialcolor": None, "presentation_rect": [80.66666907072067, 70.00000208616257, 27.0, 43.0]},
    "lum_shift.label": {"fontsize": 9.0, "presentation_rect": [82.33333578705788, 56.666668355464935, 27.0, 17.0], "textjustification": None},
    "panel": {"background": None, "bgcolor": [0.058823529411764705, 0.058823529411764705, 0.058823529411764705, 1.0]},
    "sat_amt.ctl": {"activedialcolor": None, "presentation_rect": [43.00000128149986, 69.66666874289513, 27.0, 43.0]},
    "sat_amt.label": {"fontsize": 9.0, "presentation_rect": [44.66666799783707, 56.666668355464935, 27.0, 17.0], "textjustification": None},
    "title": {"fontsize": None, "numinlets": 0, "presentation_rect": [-0.25, 1.0000000298023224, 97.0, 21.0], "suppressinlet": 1},
}
# END overrides
