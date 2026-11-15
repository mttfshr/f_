"""
f_separate -- definition.py

Splits a color image into up to three spot-color plates. The background is black and the inks are colors of light that
add (Matt, 2026-11-08): pixel = sum of coverage * ink color. Outlet 0 is the composite (the plates summed), outlets 1 to 3
the plates (each ink-colored), the same order as f_halftone (Matt, 2026-11-14). Stateless, per pixel. Spec, plan and
tasks: .specify/stable/f_separate/{spec,plan,tasks}.md. Mirror: tests/modules/separate/separate_mirror.py.

Colors (Matt, 2026-11-14): each ink is three Params, H (degrees), S and L, number boxes in the ink table; the codebox turns
them into RGB with hsl2rgb. This replaced the T009 swatches, their saturation dials and the load-timed bang (in git history).

The panel (Matt, 2026-11-14: "the same tabular layout as we did for halftone"): the Mode menu and the Inks count in the
title bar, and below it an ink table, one row per ink (1, 2, 3) of number boxes: H, S, L, Gain. Sizes are Claude's.
"""

# Default inks in H (degrees), S, L: the same colors as the earlier RGB defaults (1, 0.25, 0), (0, 0.6, 0.6), (0.45, 0, 1)
DEFAULTS = {1: (15.0, 1.0, 0.5), 2: (180.0, 1.0, 0.3), 3: (267.0, 1.0, 0.5)}

patcher = {
    "name":                "f_separate",
    "prefix":              "separate",
    "object_name":         "#0_separate_pix",
    "title":               "Separate",
    "signal_type":         "tex in/out",
    "archetype":           "processor",

    # Output follows the render size (the codebox uses `norm`, not `dim`, so no width/height Params): as f_stipple.
    "pix_attrs":           "@adapt 0 @dim 256 256 @type float32",
    "render_dim":          {"size_stages": ["primary"]},

    # Bypass drives the codebox Param `bypass_gate`; every outlet mixes to the source.
    "bypass_mode":         "param",

    "presentation_width":  240,
    "presentation_height": 106,

    "outlets": [
        {"comment": "composite (the plates summed)"},
        {"comment": "plate 1"},
        {"comment": "plate 2"},
        {"comment": "plate 3"},
    ],

    "params": [
        {"name": "n_inks", "type": "int", "min": 1, "max": 3, "default": 3, "label": "Inks",
         "hint": "How many inks are active. Unused plates are black"},
        {"name": "sep_mode", "type": "menu", "options": ["Unmix", "Nearest", "Project"], "default": 0, "label": "Mode",
         "hint": "Unmix: the best-fit coverage of all the inks together (exact round trip, but plates depend on each other). Nearest: each pixel wholly to its nearest ink, or to none when black is nearest. Project: each ink on its own, so a plate never depends on the other inks (the composite can overshoot)"},
    ] + [
        p for n in (1, 2, 3) for p in (
            {"name": f"ink{n}_h", "type": "float", "min": 0.0, "max": 360.0, "default": DEFAULTS[n][0], "label": f"H {n}",
             "widget": "numbox", "hint": f"Ink {n} hue, in degrees (0 red, 120 green, 240 blue)"},
            {"name": f"ink{n}_s", "type": "float", "min": 0.0, "max": 1.0, "default": DEFAULTS[n][1], "label": f"S {n}",
             "widget": "numbox", "hint": f"Ink {n} saturation (0 is a gray)"},
            {"name": f"ink{n}_l", "type": "float", "min": 0.0, "max": 1.0, "default": DEFAULTS[n][2], "label": f"L {n}",
             "widget": "numbox", "hint": f"Ink {n} lightness (0 black, 0.5 the full color, 1 white)"},
            {"name": f"gain{n}", "type": "float", "min": 0.0, "max": 2.0, "default": 1.0, "label": f"Gain {n}",
             "widget": "numbox", "hint": f"Plate {n} coverage gain. Above 1 saturates faster but never exceeds the ink color"},
        )
    ] + [
        {"name": "bypass", "type": "bypass"},
        {"name": "bypass_gate", "type": "internal"},
    ],

    "codebox": open("/Users/matt/Github/f_/src/f_separate/codebox_separate.gen").read(),
}


# ---- the panel (Matt, 2026-11-14: the ink table in f_halftone's style; sizes and positions are Claude's) ----------------
# Title bar: name, Mode menu (no label), Inks (a true integer numbox, as f_poincare's p and q), signal type.
_HEAD_Y = 28.0                      # the table's column headers
_ROW_Y = {1: 44.0, 2: 64.0, 3: 84.0}
_ROW_LABEL_X = 27.0
_COL_X = {"h": 41.0, "s": 89.0, "l": 137.0, "gain": 185.0}       # left edge of each 48 px column
_COL_W = 48.0

_ov = {
    "title":          {"presentation_rect": [10.5, 0.0, 46.0, 21.0]},
    "sep_mode.ctl":   {"presentation_rect": [60.0, 3.0, 52.0, 15.0]},
    "sep_mode.label": {"hidden": 1},
    "n_inks.label":   {"presentation_rect": [114.0, 1.5, 28.0, 18.0]},
    "n_inks.ctl":     {"presentation_rect": [142.0, 3.0, 26.0, 15.0], "outlettype": ["", "int"],
                       "saved_attribute_attributes": {"valueof": {
                           "parameter_initial": [3.0], "parameter_initial_enable": 1, "parameter_linknames": 1,
                           "parameter_longname": "n_inks", "parameter_mmax": 3.0, "parameter_mmin": 1.0,
                           "parameter_modmode": 3, "parameter_shortname": "n_inks",
                           "parameter_type": 1, "parameter_unitstyle": 0}}},
    "signal_type":    {"presentation_rect": [170.0, 0.9, 49.0, 21.0]},
}
_CELL = {"h": "ink{n}_h", "s": "ink{n}_s", "l": "ink{n}_l", "gain": "gain{n}"}
for _n, _y in _ROW_Y.items():
    for _col, _tmpl in _CELL.items():
        _name = _tmpl.format(n=_n)
        _ov[f"{_name}.ctl"] = {"presentation_rect": [_COL_X[_col] + 2.0, _y, _COL_W - 4.0, 15.0]}
        _ov[f"{_name}.label"] = {"hidden": 1}

_LBL = dict(fontname="Ableton Sans Light", fontsize=9.5, textjustification=1, numinlets=1, numoutlets=0, outlettype=[], presentation=1)
RAW_BOXES = []
for _k, (_col, _txt) in enumerate((("h", "H"), ("s", "S"), ("l", "L"), ("gain", "Gain"))):
    RAW_BOXES.append({"box": dict(id=f"obj-raw-head{_k}", maxclass="comment", text=_txt, patching_rect=[620.0, 20.0 + 22.0 * _k, 50.0, 18.0],
                                  presentation_rect=[_COL_X[_col], _HEAD_Y, _COL_W, 16.0], **_LBL)})
for _k, (_n, _y) in enumerate(_ROW_Y.items()):
    RAW_BOXES.append({"box": dict(id=f"obj-raw-row{_n}", maxclass="comment", text=str(_n), varname=f"lbl_ink{_n}",
                                  patching_rect=[680.0, 20.0 + 22.0 * _k, 30.0, 18.0],
                                  presentation_rect=[_ROW_LABEL_X - 12.0, _y - 1.0, 24.0, 16.0], **_LBL)})

patcher["raw_boxes"] = RAW_BOXES
patcher["overrides"] = _ov
