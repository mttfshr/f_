"""
f_separate -- definition.py

Splits a color image into up to three spot-color plates. The background is black and the inks are colors of light that
add (Matt, 2026-11-08): pixel = sum of coverage * ink color. Outlet 0 is the composite (the plates summed), outlets 1 to 3
the plates (each ink-colored), the same order as f_halftone (Matt, 2026-11-14). Stateless, per pixel. Spec, plan and
tasks: .specify/stable/f_separate/{spec,plan,tasks}.md. Mirror: tests/modules/separate/separate_mirror.py.

Colors (Matt, 2026-11-14): each ink is three Params, H (degrees), S and L, number boxes in the ink table; the codebox turns
them into RGB with hsl2rgb. This replaced the T009 swatches, their saturation dials and the load-timed bang (in git history).
Each row ends in a swatch (Matt, 2026-11-14: "make it clickable too"): the number boxes paint it with `sethsl`, which sends
nothing, and a click converts the swatch's RGBA back to H, S, L in `expr` boxes and sets the number boxes. The number boxes
stay the only state: the swatches have no varname, so Vsynth's pattrstorage neither saves nor recalls them.

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

    "presentation_width":  300,
    "presentation_height": 118,

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
_HEAD_Y = 26.0                      # the table's column headers
_ROW_Y = {1: 44.0, 2: 68.0, 3: 92.0}      # 24 apart, room for a 20 px swatch
_ROW_LABEL_X = 27.0
_COL_X = {"h": 41.0, "s": 89.0, "l": 137.0, "gain": 185.0}       # left edge of each 48 px column
_COL_W = 48.0
_SW_X, _SW_W, _SW_H = 238.0, 56.0, 19.0                          # the swatch column (hue across, lightness up)

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
for _k, (_col, _txt) in enumerate((("h", "H"), ("s", "S"), ("l", "L"), ("gain", "Gain"), ("sw", "Color"))):
    RAW_BOXES.append({"box": dict(id=f"obj-raw-head{_k}", maxclass="comment", text=_txt, patching_rect=[620.0, 20.0 + 22.0 * _k, 50.0, 18.0],
                                  presentation_rect=([_SW_X, _HEAD_Y, _SW_W, 16.0] if _col == "sw" else [_COL_X[_col], _HEAD_Y, _COL_W, 16.0]), **_LBL)})
for _k, (_n, _y) in enumerate(_ROW_Y.items()):
    RAW_BOXES.append({"box": dict(id=f"obj-raw-row{_n}", maxclass="comment", text=str(_n), varname=f"lbl_ink{_n}",
                                  patching_rect=[680.0, 20.0 + 22.0 * _k, 30.0, 18.0],
                                  presentation_rect=[_ROW_LABEL_X - 12.0, _y - 1.0, 24.0, 16.0], **_LBL)})


# ---- the swatches (Matt, 2026-11-14) ----------------------------------------------------------------------------------
#   display: H numbox -> [/ 360.] -> pak 0; S -> pak 1; L -> pak 2; pak -> `prepend sethsl` -> swatch. `sethsl` sets the color
#            and redraws WITHOUT output (swatch.maxref), so the loop ends there
#   click:   swatch RGBA -> [zl.slice 3] -> [t l l l] -> one `expr` per component (a list into expr's left inlet fills its
#            inlets, expr.maxref) -> the numbox, which sends its Param to the pix and repaints the swatch by `sethsl`.
#            H goes through [split 0. 360.]: for a gray (max = min) the hue expr gives -1 and the old hue is kept
#   The expressions are the standard RGB to HSL (colorsys); max and min are written out in each (expr has no variables)
# Numbox ids are the builder's, checked against the built patcher (by varname) after each build.
NUMBOX = {1: ("obj-26", "obj-29", "obj-32"), 2: ("obj-38", "obj-41", "obj-44"), 3: ("obj-50", "obj-53", "obj-56")}
_M = "max(max($f1\\, $f2)\\, $f3)"
_m = "min(min($f1\\, $f2)\\, $f3)"
_D = f"({_M} - {_m})"
_DZ = f"({_D} + ({_D} == 0.))"
_XR = f"(($f2 - $f3) / {_DZ})"
_ISR = f"({_M} == $f1)"
_ISG = f"(1. - {_ISR}) * ({_M} == $f2)"
_ISB = f"(1. - {_ISR}) * (1. - ({_M} == $f2))"
EXPR_H = (f"expr ({_D} > 0.) * 60. * ({_ISR} * ({_XR} + 6. * ({_XR} < 0.)) + {_ISG} * (($f3 - $f1) / {_DZ} + 2.) "
          f"+ {_ISB} * (($f1 - $f2) / {_DZ} + 4.)) - ({_D} == 0.)")
EXPR_S = f"expr {_D} / (1. - abs({_M} + {_m} - 1.) + ({_D} == 0.))"
EXPR_L = f"expr ({_M} + {_m}) / 2."
RAW_LINES = []


def _raw(id_, maxclass, text, rect, ins=1, outs=1, otypes=None, pres=None):
    b = dict(id=id_, maxclass=maxclass, numinlets=ins, numoutlets=outs, outlettype=otypes or [""] * outs,
             patching_rect=[float(v) for v in rect])
    if text is not None:
        b["text"] = text
    if pres:
        b["presentation"] = 1
        b["presentation_rect"] = [float(v) for v in pres]
    RAW_BOXES.append({"box": b})


def _line(a, ao, b, bi):
    RAW_LINES.append({"patchline": {"source": [a, ao], "destination": [b, bi]}})


for _n, _y in _ROW_Y.items():
    px, py = 800.0, 20.0 + 200.0 * (_n - 1)
    nh, ns, nl = NUMBOX[_n]
    sw, dv, pk, ps = f"obj-raw-sw{_n}", f"obj-raw-div{_n}", f"obj-raw-pak{_n}", f"obj-raw-sethsl{_n}"
    zl, tr, eh, es, el, sp = (f"obj-raw-{k}{_n}" for k in ("zl", "tr", "eh", "es", "el", "split"))
    _raw(sw, "swatch", None, (px, py + 90, 60, 30), ins=1, outs=2, otypes=["", "float"],
         pres=(_SW_X, _y - 2.0, _SW_W, _SW_H))
    _raw(dv, "newobj", "/ 360.", (px, py, 50, 22), ins=2, otypes=["float"])
    _raw(pk, "newobj", "pak 0. 0. 0.", (px, py + 30, 80, 22), ins=3)
    _raw(ps, "newobj", "prepend sethsl", (px, py + 60, 90, 22))
    _line(nh, 0, dv, 0)
    _line(dv, 0, pk, 0)
    _line(ns, 0, pk, 1)
    _line(nl, 0, pk, 2)
    _line(pk, 0, ps, 0)
    _line(ps, 0, sw, 0)
    _raw(zl, "newobj", "zl.slice 3", (px, py + 130, 70, 22), ins=2, outs=2, otypes=["", ""])
    _raw(tr, "newobj", "t l l l", (px, py + 160, 60, 22), outs=3, otypes=["", "", ""])
    _raw(eh, "newobj", EXPR_H, (px + 200, py + 100, 300, 22), ins=3)
    _raw(sp, "newobj", "split 0. 360.", (px + 200, py + 130, 90, 22), ins=3, outs=2, otypes=["float", "float"])
    _raw(es, "newobj", EXPR_S, (px + 200, py + 160, 300, 22), ins=3)
    _raw(el, "newobj", EXPR_L, (px + 200, py + 190, 300, 22), ins=3)
    _line(sw, 0, zl, 0)
    _line(zl, 0, tr, 0)
    _line(tr, 2, eh, 0)
    _line(eh, 0, sp, 0)
    _line(sp, 0, nh, 0)
    _line(tr, 1, es, 0)
    _line(es, 0, ns, 0)
    _line(tr, 0, el, 0)
    _line(el, 0, nl, 0)

patcher["raw_boxes"] = RAW_BOXES
patcher["raw_lines"] = RAW_LINES
patcher["overrides"] = _ov
