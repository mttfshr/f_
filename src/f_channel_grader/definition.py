# f_channel_grader patcher definition
#
# Rewritten 2026-10-05 (build_cleanup T014) from the shipped, hand-built patcher.
#
# The panel is a 3 x 4 grid of dials: rows Lift / Gam / Gain, columns R / G / B / M(aster). It has three
# SHARED row labels and no per-dial labels, so every dial has `"label": None` and the three labels
# are carried as raw_boxes in raw_ui.json (derived by build/capture_raw.py). The dial positions are an
# `overrides` block (build/capture.py).
#
# `legacy` preserves what Max wrote when it re-created these objects (the pix varname that every dial's
# param_connect follows, the autopattr's auto name, the bypass jsui's saved block) so the shipped
# patch stays byte-faithful and need not be regenerated. See build/spec.md, "legacy".
import json
from pathlib import Path

_HERE = Path(__file__).parent
_RAW = json.loads((_HERE / "raw_ui.json").read_text()) if (_HERE / "raw_ui.json").exists() else {}


def _dial(name, hint, color=None):
    d = {"name": name, "type": "float", "min": -1.0, "max": 1.0, "default": 0.0, "label": None, "hint": hint}
    if color:
        d["color_expression"] = color      # the row's theme colour; the RGB itself is in `overrides`
    return d


_R, _G, _B = "themecolor.live_record", "themecolor.live_macro_assignment", "themecolor.live_prelisten"


patcher = {
    # Identity
    "name":        "f_channel_grader",
    "prefix":      "cg",
    "object_name": "cg_pix",
    "title":       "Channel Grader",
    "archetype":   "processor",
    "pix_type":    "char",
    "pix_context": "drawto",       # jit.gl.pix @name cg_pix @drawto vsynth @type char
    "route_bypass": True,          # the oldest modules route a `bypass 0/1` message to the toggle
    "route_reject_to_pix": True,   # ...and send what no route token claims to the pix

    "presentation_width":  150,
    "presentation_height": 165,

    # Params, in the shipped route order: R, G, B, then Master; each Lift, Gamma, Gain
    "params": [
        _dial("r_lift",  "Red lift", _R),    _dial("r_gamma", "Red gamma", _R),    _dial("r_gain",  "R gain", _R),
        _dial("g_lift",  "Green lift", _G),  _dial("g_gamma", "Green gamma", _G),  _dial("g_gain",  "Green gain", _G),
        _dial("b_lift",  "Blue lift", _B),   _dial("b_gamma", "Blue gamma", _B),   _dial("b_gain",  "Blue gain", _B),
        _dial("m_lift",  "Master lift"), _dial("m_gamma", "Master gamma"), _dial("m_gain",  "Master gain"),
        {"name": "bypass", "type": "bypass"},
    ],

    "outlets": [{"comment": "texture"}],

    "codebox": (_HERE / "codebox_channel_grader.gen").open(newline="").read(),

    "legacy": {
        "pix_varname":       "jit.gl.pix_AA",
        "autopattr_varname": "u905020188",
        # two hand-edit leftovers: g_lift kept Max's default shortname, m_lift has no initial value set
        "control_valueof": {"g_lift": {"parameter_shortname": "live.dial"},
                            "m_lift": {"parameter_initial": None, "parameter_initial_enable": None}},
        "bypass_jsui_saved": {"valueof": {"parameter_invisible": 1, "parameter_longname": "bypass",
                                          "parameter_mmax": 1.0, "parameter_modmode": 4,
                                          "parameter_shortname": "bypass", "parameter_type": 1,
                                          "parameter_unitstyle": 0}},
    },

    "raw_boxes":      _RAW.get("raw_boxes", []),
    "raw_lines":      _RAW.get("raw_lines", []),
    "raw_parameters": _RAW.get("raw_parameters", {}),
}

# BEGIN overrides (build/capture.py rewrites only this block)
patcher["overrides"] = {
    "b_gain.ctl": {"activedialcolor": [0.101960784313725, 0.490196078431373, 0.945098039215686, 1.0], "presentation_rect": [87.0, 115.5, 27.0, 43.0]},
    "b_gamma.ctl": {"activedialcolor": [0.101960784313725, 0.490196078431373, 0.945098039215686, 1.0], "presentation_rect": [87.0, 71.5, 27.0, 43.0]},
    "b_lift.ctl": {"activedialcolor": [0.101960784313725, 0.490196078431373, 0.945098039215686, 1.0], "presentation_rect": [87.0, 25.5, 27.0, 43.0], "valuepopup": None},
    "bypass_jsui": {"presentation_rect": [129.0, 7.0, 18.0, 12.0]},
    "g_gain.ctl": {"activedialcolor": [0.0, 0.854901960784314, 0.282352941176471, 1.0], "presentation_rect": [58.0, 115.5, 27.0, 43.0]},
    "g_gamma.ctl": {"activedialcolor": [0.0, 0.854901960784314, 0.282352941176471, 1.0], "presentation_rect": [58.0, 71.5, 27.0, 43.0]},
    "g_lift.ctl": {"activedialcolor": [0.0, 0.854901960784314, 0.282352941176471, 1.0], "presentation_rect": [58.0, 25.5, 27.0, 43.0]},
    "m_gain.ctl": {"activedialcolor": [0.8862745098039215, 0.8941176470588236, 0.9058823529411765, 1.0], "presentation_rect": [116.0, 115.5, 27.0, 43.0]},
    "m_gamma.ctl": {"activedialcolor": [0.9490196078431372, 0.9568627450980393, 0.9647058823529412, 1.0], "presentation_rect": [116.0, 71.5, 27.0, 43.0]},
    "m_lift.ctl": {"activedialcolor": [0.8862745098039215, 0.8941176470588236, 0.9058823529411765, 1.0], "presentation_rect": [116.0, 25.5, 27.0, 43.0]},
    "panel": {"bgcolor": [0.058823529411764705, 0.058823529411764705, 0.058823529411764705, 1.0], "bordercolor": [0.0, 0.03529411764705882, 0.22745098039215686, 1.0], "presentation_rect": [2.0, 2.0, 150.0, 165.0]},
    "r_gain.ctl": {"activedialcolor": [1.0, 0.349019607843137, 0.372549019607843, 1.0], "presentation_rect": [28.5, 115.5, 27.0, 43.0]},
    "r_gamma.ctl": {"activedialcolor": [1.0, 0.349019607843137, 0.372549019607843, 1.0], "presentation_rect": [28.5, 71.5, 27.0, 43.0]},
    "r_lift.ctl": {"activedialcolor": [1.0, 0.349019607843137, 0.372549019607843, 1.0], "presentation_rect": [28.5, 25.5, 27.0, 43.0]},
    "title": {"fontsize": None, "presentation_rect": [1.5, 3.5, 91.0, 21.0]},
}
# END overrides
