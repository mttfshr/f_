"""
f_separate -- definition.py

Splits a color image into up to three spot-color plates. The background is black and the inks are colors of light that
add (Matt, 2026-11-08): pixel = sum of coverage * ink color. Outlets 0 to 2 are the plates (each ink-colored), outlet 3
the preview (the plates summed). Stateless, per pixel. Spec, plan and tasks: .specify/stable/f_separate/{spec,plan,tasks}.md.
Mirror: tests/modules/separate/separate_mirror.py.

Colors (T009, proven live by Matt 2026-11-08): three `swatch` boxes, each route outlet -> swatch -> unpack ->
three `prepend param inkN_c` -> the pix. A swatch is a hue by lightness plane at one saturation, so each ink also has a
saturation dial (`sat1`-`sat3`) feeding the swatch's `saturation` message, then a bang so the swatch sends its color again.
The nine ink Params are `internal`: the swatches drive them, never a dial.
"""

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

    "presentation_width":  191,
    "presentation_height": 200,

    "outlets": [
        {"comment": "plate 1"},
        {"comment": "plate 2"},
        {"comment": "plate 3"},
        {"comment": "preview (plates summed)"},
    ],

    "params": [
        {"name": "n_inks", "type": "int", "min": 1, "max": 3, "default": 2, "label": "Inks",
         "hint": "How many inks are active. Unused plates are black"},
        {"name": "sep_mode", "type": "menu", "options": ["Unmix", "Nearest", "Project"], "default": 0, "label": "Mode",
         "hint": "Unmix: the best-fit coverage of all the inks together (exact round trip, but plates depend on each other). Nearest: each pixel wholly to its nearest ink, or to none when black is nearest. Project: each ink on its own, so a plate never depends on the other inks (the preview can overshoot)"},
        {"name": "gain1", "type": "float", "min": 0.0, "max": 2.0, "default": 1.0, "label": "Gain 1",
         "hint": "Plate 1 coverage gain. Above 1 saturates faster but never exceeds the ink color"},
        {"name": "gain2", "type": "float", "min": 0.0, "max": 2.0, "default": 1.0, "label": "Gain 2",
         "hint": "Plate 2 coverage gain"},
        {"name": "gain3", "type": "float", "min": 0.0, "max": 2.0, "default": 1.0, "label": "Gain 3",
         "hint": "Plate 3 coverage gain"},
        {"name": "sat1", "type": "float", "min": 0.0, "max": 1.0, "default": 1.0, "label": "Sat 1", "pix_wire": False,
         "hint": "Saturation of swatch 1's color plane (lower for pastels and grays)"},
        {"name": "sat2", "type": "float", "min": 0.0, "max": 1.0, "default": 1.0, "label": "Sat 2", "pix_wire": False,
         "hint": "Saturation of swatch 2's color plane"},
        {"name": "sat3", "type": "float", "min": 0.0, "max": 1.0, "default": 1.0, "label": "Sat 3", "pix_wire": False,
         "hint": "Saturation of swatch 3's color plane"},
        {"name": "ink1", "type": "raw_ui"}, {"name": "ink2", "type": "raw_ui"}, {"name": "ink3", "type": "raw_ui"},
        {"name": "bypass", "type": "bypass"},
    ] + [
        {"name": f"ink{n}_{c}", "type": "internal"} for n in (1, 2, 3) for c in "rgb"
    ] + [
        {"name": "bypass_gate", "type": "internal"},
    ],

    "codebox": open("/Users/matt/Github/f_/src/f_separate/codebox_separate.gen").read(),
}


# ---- the swatches (raw boxes; T009) ---------------------------------------------------------------------------------
#   color:  route outlet inkN -> swatch -> unpack -> three `prepend param inkN_c` -> the pix (a swatch change and a
#            module message `inkN r g b` both go through the swatch, so the display and the Params never disagree)
#   default: loadbang -> deferlow -> `set r g b 1.` paints the swatch without sending. The color is sent once, later:
#            first `r draw` -> [onebang 1] -> [delay 100] -> bang each swatch. A bang at load (0f0826d) left all four outlets
#            black on Matt's look, 2026-11-08; INFERRED cause: too early for the pix or the swatch, so timed off a draw
#   sat:     satN dial (0..1) -> [t b f] -> f: `prepend saturation` -> swatch, then b: bang -> the swatch sends its color
#            again. The attribute is 0..1 (swatch.maxhelp saves 1.0); a `* 255` here had no visible effect on the module bench,
#            2026-11-08. UNVERIFIED in Max: whether `saturation` alone re-sends (the bang is the safe order)
# Ids: the route is obj-4 (outlet 7 + N is inkN), the primary pix obj-5, the dials are the builder's (sat1-3).
DEFAULTS = {1: (1.0, 0.25, 0.0), 2: (0.0, 0.6, 0.6), 3: (0.45, 0.0, 1.0)}
SAT_DIAL = {1: "obj-35", 2: "obj-38", 3: "obj-41"}
COL_CENTRE = {1: 66.0, 2: 113.0, 3: 160.0}    # panel columns, one per ink: Gain, Sat and the swatch share a center (Matt, 2026-11-08)
RAW_BOXES, RAW_LINES = [], []


def _box(id_, maxclass, text=None, outs=1, ins=1, rect=(0, 0, 40, 20), pres=None, otypes=None, **kw):
    b = {"id": id_, "maxclass": maxclass, "numinlets": ins, "numoutlets": outs,
         "outlettype": otypes or ["" for _ in range(outs)], "patching_rect": [float(v) for v in rect]}
    if text is not None:
        b["text"] = text
    if pres:
        b["presentation"] = 1
        b["presentation_rect"] = [float(v) for v in pres]
    b.update(kw)
    RAW_BOXES.append({"box": b})


def _line(a, ao, b, bi):
    RAW_LINES.append({"patchline": {"source": [a, ao], "destination": [b, bi]}})


_box("obj-raw-load", "newobj", "loadbang", rect=(560, 20, 60, 22))
_box("obj-raw-def", "newobj", "deferlow", rect=(560, 50, 60, 22))
_line("obj-raw-load", 0, "obj-raw-def", 0)
_box("obj-raw-draw", "newobj", "r draw", ins=0, rect=(640, 20, 50, 22))
_box("obj-raw-once", "newobj", "onebang 1", ins=2, outs=2, rect=(640, 50, 70, 22), otypes=["bang", "bang"])
_box("obj-raw-wait", "newobj", "delay 100", ins=2, rect=(640, 80, 70, 22), otypes=["bang"])
_line("obj-raw-draw", 0, "obj-raw-once", 0)
_line("obj-raw-once", 0, "obj-raw-wait", 0)
for n, (r, g, bl) in DEFAULTS.items():
    y = 300 + 130 * (n - 1)
    sw, un, st = f"obj-raw-sw{n}", f"obj-raw-un{n}", f"obj-raw-set{n}"
    cx = COL_CENTRE[n]
    _box(sw, "swatch", ins=1, outs=2, rect=(300, y, 60, 30), pres=(cx - 22, 160, 44, 36), otypes=["", "float"],
         varname=f"ink{n}_swatch")
    _box(f"obj-raw-lbl{n}", "comment", f"Ink {n}", outs=0, rect=(380, y - 20, 50, 18), pres=(cx - 25, 144, 50, 18),
         fontname="Ableton Sans Light", fontsize=9.5, textjustification=1, varname=f"lbl_ink{n}")
    _box(st, "message", f"set {r} {g} {bl} 1.", rect=(380, y, 120, 22))
    _box(un, "newobj", "unpack 0. 0. 0. 0.", outs=4, rect=(300, y + 40, 100, 22), otypes=["float"] * 4)
    _line("obj-4", 7 + n, sw, 0)
    _line("obj-raw-def", 0, st, 0)     # paint the default at load
    _line(st, 0, sw, 0)
    _line("obj-raw-wait", 0, sw, 0)    # after the first draw: the swatch SENDS its color, so the Params follow
    _line(sw, 0, un, 0)
    for j, c in enumerate("rgb"):
        pp = f"obj-raw-pp{n}{c}"
        _box(pp, "newobj", f"prepend param ink{n}_{c}", rect=(300 + 130 * j, y + 70, 120, 22))
        _line(un, j, pp, 0)
        _line(pp, 0, "obj-5", 0)
    tr, ps = f"obj-raw-tr{n}", f"obj-raw-ps{n}"
    _box(tr, "newobj", "t b f", outs=2, rect=(520, y + 30, 50, 22), otypes=["bang", "float"])
    _box(ps, "newobj", "prepend saturation", rect=(520, y + 60, 120, 22))
    _line(SAT_DIAL[n], 0, tr, 0)
    _line(tr, 1, ps, 0)
    _line(ps, 0, sw, 0)
    _line(tr, 0, sw, 0)

patcher["raw_boxes"] = RAW_BOXES
patcher["raw_lines"] = RAW_LINES


# ---- the panel (Matt, 2026-11-08) ------------------------------------------------------------------------------------
# Title bar: name, Mode menu (no label), signal type. Left column: Inks, a true integer numbox (as f_poincare's p and q).
# Three columns, one per ink: Gain, Sat and the swatch on one center.
_ROW_GAIN, _ROW_SAT = 38.0, 100.0   # dial tops; a label sits 18 px above


def _dial_at(name, centre, y):
    return {f"{name}.ctl":   {"presentation_rect": [centre - 13.5, y, 27.0, 43.0]},
            f"{name}.label": {"presentation_rect": [centre - 25.0, y - 18.0, 50.0, 18.0]}}


_ov = {
    "title":         {"presentation_rect": [10.5, 0.0, 46.0, 21.0]},
    "sep_mode.ctl":  {"presentation_rect": [60.0, 3.0, 52.0, 15.0]},
    "sep_mode.label": {"hidden": 1},
    "signal_type":   {"presentation_rect": [116.0, 0.9, 49.0, 21.0]},
    "n_inks.ctl":    {"presentation_rect": [4.0, _ROW_GAIN, 34.0, 15.0], "outlettype": ["", "int"],
                      "saved_attribute_attributes": {"valueof": {
                          "parameter_initial": [2.0], "parameter_initial_enable": 1, "parameter_linknames": 1,
                          "parameter_longname": "n_inks", "parameter_mmax": 3.0, "parameter_mmin": 1.0,
                          "parameter_modmode": 3, "parameter_shortname": "n_inks",
                          "parameter_type": 1, "parameter_unitstyle": 0}}},
    "n_inks.label":  {"presentation_rect": [-4.0, _ROW_GAIN - 18.0, 50.0, 18.0]},
}
for _n, _c in COL_CENTRE.items():
    _ov.update(_dial_at(f"gain{_n}", _c, _ROW_GAIN))
    _ov.update(_dial_at(f"sat{_n}", _c, _ROW_SAT))
patcher["overrides"] = _ov
