# f_grain patcher definition
#
# Rewritten 2026-10-05 (build_cleanup T014) from the shipped, hand-built patcher. The previous
# version (2026-06-05) was an after-the-fact transcription that used param types the builder does
# not have (`numbox`, `umenu`), so those controls were silently never built.
#
# f_grain is a hand-built module with real bespoke logic. The builder's output covers the
# generic part (the dials, the `dual` vs_inState arrangement, the outlets, bypass, the
# moduleSize chain). The rest is carried verbatim in `raw_ui.json` (raw_boxes / raw_lines):
#   - the persistence chain: `persistence` dial -> expr pow(1.0 - $f1, 2.0) -> f -> + 0. -> t f f
#     -> attrui era_clock, clocked by `r draw` (the dial has no attrui or cord to the pix:
#     pix_wire False);
#   - a second route (`route field sv_seed`) fed from routepass out 1, and the `field` / `sv_seed`
#     numboxes and attruis;
#   - the edge_mode umenu and its attrui;
#   - a second `r draw`, wired to the pix.
# The routing is control-first (route_first): the inlet feeds the route, and the route's reject
# outlet feeds routepass. The patch is hand-edited and on plan.md's never-regenerate list: this
# definition exists so drift can be checked and so the module is recorded; do not regenerate.
import json
from pathlib import Path

_HERE = Path(__file__).parent
_RAW = json.loads((_HERE / "raw_ui.json").read_text()) if (_HERE / "raw_ui.json").exists() else {}

patcher = {
    # Identity
    "name":                "f_grain",
    "prefix":              "grain",
    "object_name":         "grain_pix",
    "title":               "Grain",

    # Archetype: vs_inState gates src_mode
    "archetype":           "dual",
    "pix_type":            "char",

    # Bypass drives the codebox Param `bypass_gate` (jsui -> `prepend param bypass_gate` -> pix),
    # not the native @bypass, which skips the shader and flips secondary outlets.  Every outlet
    # mixes to its passthrough, so a bypassed module is a passthrough (Matt, 2026-10-05; plan.md item 10).
    "bypass_mode":        "param",
    "route_bypass":        True,    # the oldest modules route a `bypass 0/1` message to the toggle
    "route_first":         True,    # inlet -> route, route reject -> routepass (see above)
    "inlet_comment":       "",

    # Presentation panel size (from the panel's presentation_rect)
    "presentation_width":  227,
    "presentation_height": 164,

    # Params, in the shipped route order (the order of the route tokens is the param order).
    "params": [
        {"name": "density",     "type": "float", "min": 0.0,  "max": 1.0, "default": 0.5, "label": "Dens",   "hint": "Grain density"},
        {"name": "amount",      "type": "float", "min": 0.0,  "max": 2.0, "default": 1.0, "label": "Amt",    "hint": "Grain amount (blend weight)"},
        {"name": "persistence", "type": "float", "min": 0.0,  "max": 1.0, "default": 1.0, "label": "Freeze", "hint": "Temporal persistence (0=boil 1=frozen)",
         "pix_wire": False},
        {"name": "fade",        "type": "float", "min": 0.0,  "max": 4.0, "default": 0.0, "label": "Fade",   "hint": "Temporal persistence (0=boil 1=frozen)"},
        {"name": "size",        "type": "float", "min": 0.0,  "max": 1.0, "default": 0.0, "label": "Size",   "hint": "Grain size"},
        {"name": "size_var",    "type": "float", "min": 0.0,  "max": 1.0, "default": 0.0, "label": "S.var",  "hint": "Grain size variation"},
        {"name": "shape",       "type": "float", "min": 0.0,  "max": 1.0, "default": 0.5, "label": "Shape",  "hint": "Grain aspect ratio (-1=portrait 0=square 1=landscape)"},
        {"name": "softness",    "type": "float", "min": 0.0,  "max": 1.0, "default": 0.0, "label": "Soft",   "hint": "Grain edge softness"},
        {"name": "jitter",      "type": "float", "min": 0.0,  "max": 2.0, "default": 0.0, "label": "Jitter", "hint": "Grain position jitter (0=grid 1=scattered)"},
        {"name": "ch_diverge",  "type": "float", "min": 0.0,  "max": 1.0, "default": 0.0, "label": "Color",  "hint": "Temporal persistence (0=boil 1=frozen)"},
        {"name": "luma_gate",   "type": "float", "min": -1.0, "max": 1.0, "default": 0.0, "label": "L.gate", "hint": "Luma gate: bipolar (-1=shadows 0=uniform +1=highlights)"},
        {"name": "displace",    "type": "float", "min": 0.0,  "max": 0.5, "default": 0.0, "label": "Displ",  "hint": "Per-grain displacement amount"},
        # route outlets with no generated widget: the umenu and the two numboxes are in raw_ui.json
        {"name": "edge_mode",   "type": "raw_ui", "route_name": "edge_mode_menu"},
        {"name": "field",       "type": "raw_ui"},
        {"name": "sv_seed",     "type": "raw_ui"},
        {"name": "era_clock",   "type": "internal"},  # driven by the persistence chain
        {"name": "src_mode",    "type": "internal"},  # driven by vs_inState
        {"name": "bypass",      "type": "bypass"},
    ],

    # Outlets: out1=composite, out2=grain mask, out3=displaced source only
    "outlets": [
        {"comment": "composite"},
        {"comment": "grain mask", "hint": "Raw"},
        {"comment": "displaced"},
    ],

    # newline="": the shipped codebox has three CRLF line endings, which text mode would convert
    "codebox": (_HERE / "codebox_grain.gen").open(newline="").read(),

    "raw_boxes":      _RAW.get("raw_boxes", []),
    "raw_lines":      _RAW.get("raw_lines", []),
    "raw_parameters": _RAW.get("raw_parameters", {}),
}

# BEGIN overrides (build/capture.py rewrites only this block)
patcher["overrides"] = {
    "amount.ctl": {"presentation_rect": [6.0, 115.0, 27.0, 43.0]},
    "amount.label": {"presentation_rect": [8.0, 99.0, 30.0, 18.0], "textjustification": None},
    "bypass_jsui": {"presentation_rect": [208.00000309944153, 5.600000083446503, 18.0, 12.0], "valuepopuplabel": None},
    "ch_diverge.ctl": {"presentation_rect": [79.0, 115.0, 27.0, 43.0]},
    "ch_diverge.label": {"presentation_rect": [79.00000235438347, 99.00000295042992, 34.0, 18.0], "textjustification": None},
    "density.ctl": {"presentation_rect": [42.00000011920929, 115.0, 27.0, 43.0]},
    "density.label": {"presentation_rect": [42.00000125169754, 99.00000295042992, 35.0, 18.0], "textjustification": None},
    "displace.ctl": {"presentation_rect": [188.0, 115.0, 27.0, 43.0]},
    "displace.label": {"presentation_rect": [187.0, 99.0, 34.0, 18.0], "textjustification": None},
    "fade.ctl": {"presentation_rect": [152.0, 38.0, 27.0, 43.0]},
    "fade.label": {"presentation_rect": [153.0, 22.0, 30.0, 18.0], "textjustification": None},
    "jitter.ctl": {"presentation_rect": [79.0, 38.0, 27.0, 43.0]},
    "jitter.label": {"linecount": 2, "presentation_rect": [77.0, 22.0, 31.0, 18.0], "textjustification": None},
    "luma_gate.ctl": {"presentation_rect": [152.0, 115.0, 27.0, 43.0]},
    "luma_gate.label": {"linecount": 2, "presentation_rect": [151.0, 99.0, 35.333334386348724, 18.0], "textjustification": None},
    "outlet.0": {"tricolor": [0.9529411764705882, 0.6901960784313725, 0.6196078431372549, 1.0]},
    "outlet.1": {"tricolor": [0.6196078431372549, 0.9529411764705882, 0.6588235294117647, 1.0]},
    "outlet.2": {"tricolor": [0.9490196078431372, 0.6196078431372549, 0.9529411764705882, 1.0]},
    "panel": {"bgcolor": [0.058823529411764705, 0.058823529411764705, 0.058823529411764705, 1.0], "bordercolor": [0.0, 0.03529411764705882, 0.22745098039215686, 1.0], "presentation_rect": [2.0, 2.0, 227.0, 164.0]},
    "persistence.ctl": {"presentation_rect": [188.0, 38.0, 27.0, 43.0]},
    "persistence.label": {"linecount": 2, "presentation_rect": [184.0, 22.0, 37.5, 18.0], "textjustification": None},
    "shape.ctl": {"presentation_rect": [115.0, 38.0, 27.0, 43.0]},
    "shape.label": {"presentation_rect": [112.0, 22.0, 35.0, 18.0], "textjustification": None},
    "size.ctl": {"presentation_rect": [6.0, 38.0, 27.0, 43.0]},
    "size.label": {"presentation_rect": [5.0, 22.0, 30.0, 18.0], "textjustification": None},
    "size_var.ctl": {"presentation_rect": [42.00000011920929, 38.0, 27.0, 43.0]},
    "size_var.label": {"presentation_rect": [41.00000011920929, 22.0, 32.0, 18.0], "textjustification": None},
    "softness.ctl": {"presentation_rect": [116.0, 115.0, 27.0, 43.0]},
    "softness.label": {"presentation_rect": [116.0, 99.0, 28.0, 18.0], "textjustification": None},
    "title": {"fontsize": None, "presentation_rect": [4.0, 0.5, 60.0, 21.0]},
}
# END overrides
