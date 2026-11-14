"""
f_halftone -- definition.py

Tone to marks: a fixed-angle halftone screen, one plate per color channel (R, G, B), each with its own angle and lattice
phase. Dot, Line, Threshold and Bayer, shape and jitter (T020-T025), the Single plate mode (T016b), and the Plates mode
(T028): inlets 1 to 3 take f_separate's plates, each screened as Single at the R / G / B angle, phase and scale, summed.
Blue and Random screens and Levels (T035, Matt 2026-11-14): Blue reads the void-and-cluster pattern shipped as
package/media/f_bluenoise64.jxf, through a static mod inlet (gen in5; no outer inlet).
Stateless, one stage. A texture processor: four inlets (0 the texture, 1-3 the plates), one outlet; the output follows the render size (render_dim: Params
`width` and `height`). Spec, plan and tasks: .specify/f_halftone/{spec,plan,tasks}.md.
Mirror: tests/modules/halftone/halftone_mirror.py.

The panel (Matt, 2026-11-14: "put x, y, angle and scale for each plate together", in the row style of f_util_vary; sizes
are Claude's): the Screen and Plate menus in the title bar, one row of global dials (Pitch, Soft, Shape, Jitter, Level, then
Seed and the Bayer Read button), and below it a plate table, one row per plate (R, G, B) of number boxes: Angle, Scale, X, Y.
The row labels are comments with varnames `lbl_plate_r/g/b`, so Plates mode (T028) can set them to 1 / 2 / 3.
"""

patcher = {
    "name":                "f_halftone",
    "prefix":              "halftone",
    "object_name":         "#0_halftone_pix",
    "title":               "Halftone",
    "signal_type":         "tex in/out",
    "archetype":           "processor",

    "pix_attrs":           "@adapt 0 @dim 256 256 @type float32",
    "render_dim":          {"width_param": "width", "height_param": "height",
                            "param_stages": ["primary"], "size_stages": ["primary"]},

    # Bypass drives the codebox Param `bypass_gate`: the source passes through.
    "bypass_mode":         "param",

    "presentation_width":  290,
    "presentation_height": 164,

    # T038 (Matt, 2026-11-14; spec US12, FR-028 to FR-030): outlet 0 the combined screen, outlets 1-3 the plates
    "outlets": [
        {"comment": "texture (the plates combined)"},
        {"comment": "plate R (Plates: plate 1), gray mask or color per Out"},
        {"comment": "plate G (Plates: plate 2), gray mask or color per Out"},
        {"comment": "plate B (Plates and Single: plate 3 / the one plate), gray mask or color per Out"},
    ],

    # T028 (Matt, 2026-11-14; spec FR-017 to FR-021): the plate inlets, read only in Plates mode. Each connected flag lets the
    # codebox skip an unconnected plate (an unconnected inlet reads black with alpha 1, which would set the output alpha to 1).
    "mod_inlets": [
        {"label": "plate 1 (Plates mode: screened at the R angle, phase and scale)", "state_param": "plate1_on"},
        {"label": "plate 2 (Plates mode: screened at the G angle, phase and scale)", "state_param": "plate2_on"},
        {"label": "plate 3 (Plates mode: screened at the B angle, phase and scale)", "state_param": "plate3_on"},
        # T035 (Matt, 2026-11-14; plan ADR-10): the Blue screen's thresholds, loaded from the package (gen in5)
        {"label": "blue-noise pattern", "static": {"file": "f_bluenoise64.jxf", "planes": 1, "type": "float32", "dim": [64, 64]}},
    ],

    "params": [
        {"name": "screen", "type": "menu", "options": ["Dot", "Line", "Threshold", "Bayer", "Blue", "Random"], "default": 0, "label": "Screen",
         "hint": "Dot: a lattice of dots, each sized by the tone at its center. Line: parallel lines whose width follows the tone. Threshold: ink where the tone is above Level. Bayer: an ordered dither. Blue: an even, grainy dither with no visible grid. Random: a coarse, clumpy dither"},
        {"name": "plate_mode", "type": "menu", "options": ["Channels", "Single", "Plates"], "default": 0, "label": "Plate",
         "hint": "Channels: red, green and blue are three plates, each at its own angle. Single: the texture is one spot-color plate, screened at the B row, in its own color. Plates: inlets 2-4 take f_separate's plates, screened at rows 1, 2, 3 and added (the main inlet is ignored)"},
        {"name": "pitch", "type": "float", "min": 0.009, "max": 0.2, "default": 0.012, "label": "Pitch",
         "hint": "Lattice period in frame heights, for all three plates (each plate's Scale multiplies it). Below about 10 pixels the inked area stops tracking the tone. Bayer, Blue, Random: the grain cell is Pitch / 8, in whole pixels"},
        {"name": "scale_r", "type": "float", "min": 0.25, "max": 4.0, "default": 1.0, "label": "Scale R", "widget": "numbox",
         "hint": "Multiplies Pitch for the red plate alone, so the plates can run at different rulings (1 = Pitch)"},
        {"name": "scale_g", "type": "float", "min": 0.25, "max": 4.0, "default": 1.0, "label": "Scale G", "widget": "numbox",
         "hint": "Multiplies Pitch for the green plate alone (1 = Pitch)"},
        {"name": "scale_b", "type": "float", "min": 0.25, "max": 4.0, "default": 1.0, "label": "Scale B", "widget": "numbox",
         "hint": "Multiplies Pitch for the blue plate alone (1 = Pitch). Single uses this one"},
        {"name": "softness", "type": "float", "min": 0.0, "max": 1.0, "default": 0.1, "label": "Soft",
         "hint": "Width of the edge between ink and no ink. 0 is as sharp as one pixel allows"},
        {"name": "dot_shape", "type": "float", "min": 0.0, "max": 1.0, "default": 0.0, "label": "Shape",
         "hint": "Dot only: round at 0, square at 1, the same inked area at every setting"},
        {"name": "jitter", "type": "float", "min": 0.0, "max": 1.0, "default": 0.0, "label": "Jitter",
         "hint": "Dot only: moves each dot off the lattice, from a regular screen at 0 toward a random one at 1. Above mid-tone it loses a little ink"},
        {"name": "seed", "type": "int", "min": 1, "max": 256, "default": 1, "label": "Seed", "modmode": 0,
         "hint": "Which random pattern: the jitter, and the Blue and Random grain"},
        {"name": "levels", "type": "int", "min": 2, "max": 16, "default": 2, "label": "Levels", "modmode": 0,
         "hint": "Bayer, Blue and Random: how many output values per channel. 2 is black and white; more steps between them, dithered"},
        {"name": "level", "type": "float", "min": 0.0, "max": 1.0, "default": 0.5, "label": "Level",
         "hint": "Threshold only: the tone above which there is ink. Soft widens the cut"},
        {"name": "bayer_cell", "type": "text_button", "options": ["Pixel", "Cell"], "default": 1, "label": "Read",
         "hint": "Bayer, Blue and Random. Cell: one tone per dither cell, so each cell is wholly lit or dark (an ordered dither). Pixel: the tone per pixel, so the image cuts through each cell. The same at 1-pixel cells"},
        {"name": "angle_r", "type": "float", "min": 0.0, "max": 180.0, "default": 15.0, "label": "Angle R", "widget": "numbox",
         "hint": "Screen angle of the red plate, in degrees"},
        {"name": "angle_g", "type": "float", "min": 0.0, "max": 180.0, "default": 75.0, "label": "Angle G", "widget": "numbox",
         "hint": "Screen angle of the green plate, in degrees"},
        {"name": "angle_b", "type": "float", "min": 0.0, "max": 180.0, "default": 45.0, "label": "Angle B", "widget": "numbox",
         "hint": "Screen angle of the blue plate, in degrees"},
        {"name": "phase_r_x", "type": "float", "min": -1.0, "max": 1.0, "default": 0.0, "label": "R x", "widget": "numbox",
         "hint": "Shifts the red plate's lattice along its own x, in pitches. The marks stay whole and sharp"},
        {"name": "phase_r_y", "type": "float", "min": -1.0, "max": 1.0, "default": 0.0, "label": "R y", "widget": "numbox",
         "hint": "Shifts the red plate's lattice along its own y, in pitches"},
        {"name": "phase_g_x", "type": "float", "min": -1.0, "max": 1.0, "default": 0.0, "label": "G x", "widget": "numbox",
         "hint": "Shifts the green plate's lattice along its own x, in pitches"},
        {"name": "phase_g_y", "type": "float", "min": -1.0, "max": 1.0, "default": 0.0, "label": "G y", "widget": "numbox",
         "hint": "Shifts the green plate's lattice along its own y, in pitches"},
        {"name": "phase_b_x", "type": "float", "min": -1.0, "max": 1.0, "default": 0.0, "label": "B x", "widget": "numbox",
         "hint": "Shifts the blue plate's lattice along its own x, in pitches"},
        {"name": "phase_b_y", "type": "float", "min": -1.0, "max": 1.0, "default": 0.0, "label": "B y", "widget": "numbox",
         "hint": "Shifts the blue plate's lattice along its own y, in pitches"},
        {"name": "plate_out", "type": "text_button", "options": ["Gray", "Color"], "default": 0, "label": "Out",
         "hint": "What outlets 2-4 carry. Gray: each plate's coverage as a gray mask (for an effect such as f_vf_erode). Color: each plate in its color, as it enters outlet 1 (red, green, blue in Channels; the ink color in Single and Plates)"},
        {"name": "bypass", "type": "bypass"},

        # Driven by the bypass jsui (`prepend param bypass_gate`), never by a dial
        {"name": "bypass_gate", "type": "internal"},
        # Connected flags of the plate inlets (T028), from vs_inState
        {"name": "plate1_on", "type": "internal"},
        {"name": "plate2_on", "type": "internal"},
        {"name": "plate3_on", "type": "internal"},
        # Render size, driven by render_dim
        {"name": "width", "type": "internal"},
        {"name": "height", "type": "internal"},
    ],

    "codebox": open("/Users/matt/Github/f_/src/f_halftone/codebox_halftone.gen").read(),
}


# ---- the panel (Matt, 2026-11-14: a plate table in f_util_vary's row style; sizes and positions are Claude's) ------------
_DIAL_TOP = 38.0                    # the global dials; a label sits 18 px above
_GLOBAL_X = {"pitch": 22.0, "softness": 60.0, "dot_shape": 98.0, "jitter": 136.0, "level": 174.0}   # dial centers
_SEED_X, _READ_X = 214.0, 258.0     # Seed numbox and the Bayer Read button centers
_HEAD_Y = 86.0                      # the table's column headers
_ROW_Y = {"r": 102.0, "g": 122.0, "b": 142.0}
_ROW_LABEL_X = 22.0
_COL_X = {"angle": 42.0, "scale": 100.0, "x": 158.0, "y": 216.0}       # left edge of each 50 px column
_COL_W = 50.0


def _dial_at(name, centre, y, lw=38.0):
    return {f"{name}.ctl":   {"presentation_rect": [centre - 13.5, y, 27.0, 43.0]},
            f"{name}.label": {"presentation_rect": [centre - lw / 2, y - 18.0, lw, 18.0]}}


_ov = {
    "title":        {"presentation_rect": [10.5, 0.0, 50.0, 21.0]},
    "screen.ctl":   {"presentation_rect": [64.0, 3.0, 52.0, 15.0]},
    "screen.label": {"hidden": 1},
    "plate_mode.ctl":   {"presentation_rect": [120.0, 3.0, 60.0, 15.0]},     # T016b: beside the Screen menu
    "plate_mode.label": {"hidden": 1},
}
for _n, _x in _GLOBAL_X.items():
    _ov.update(_dial_at(_n, _x, _DIAL_TOP))
# Seed and Levels share a column (T035; placement Claude's, T032 tuning)
_ov["seed.ctl"] = {"presentation_rect": [_SEED_X - 17.0, _DIAL_TOP - 2.0, 34.0, 15.0], "outlettype": ["", "int"],
                   "saved_attribute_attributes": {"valueof": {
                       "parameter_initial": [1.0], "parameter_initial_enable": 1, "parameter_linknames": 1,
                       "parameter_longname": "seed", "parameter_mmax": 256.0, "parameter_mmin": 1.0, "parameter_modmode": 0,
                       "parameter_shortname": "seed", "parameter_type": 1, "parameter_unitstyle": 0}}}
_ov["seed.label"] = {"presentation_rect": [_SEED_X - 19.0, _DIAL_TOP - 18.0, 38.0, 18.0]}
_ov["levels.ctl"] = {"presentation_rect": [_SEED_X - 17.0, _DIAL_TOP + 29.0, 34.0, 15.0], "outlettype": ["", "int"],
                     "saved_attribute_attributes": {"valueof": {
                         "parameter_initial": [2.0], "parameter_initial_enable": 1, "parameter_linknames": 1,
                         "parameter_longname": "levels", "parameter_mmax": 16.0, "parameter_mmin": 2.0, "parameter_modmode": 0,
                         "parameter_shortname": "levels", "parameter_type": 1, "parameter_unitstyle": 0}}}
_ov["levels.label"] = {"presentation_rect": [_SEED_X - 19.0, _DIAL_TOP + 13.0, 38.0, 16.0]}
_ov["bayer_cell.ctl"] = {"presentation_rect": [_READ_X - 20.0, _DIAL_TOP + 13.0, 40.0, 17.0]}   # shows Cell / Pixel itself
_ov["plate_out.ctl"] = {"presentation_rect": [186.0, 3.0, 40.0, 15.0]}   # T038: in the title bar after Plate (Claude's placement)

# the plate table: one row per plate; the per-cell labels are hidden, the headers and row labels are comments
_CELL = {"angle": "angle_{c}", "scale": "scale_{c}", "x": "phase_{c}_x", "y": "phase_{c}_y"}
for _c, _y in _ROW_Y.items():
    for _col, _tmpl in _CELL.items():
        _n = _tmpl.format(c=_c)
        _ov[f"{_n}.ctl"] = {"presentation_rect": [_COL_X[_col] + 2.0, _y, _COL_W - 4.0, 15.0]}
        _ov[f"{_n}.label"] = {"hidden": 1}

_LBL = dict(fontname="Ableton Sans Light", fontsize=9.5, textjustification=1, numinlets=1, numoutlets=0, outlettype=[], presentation=1)
RAW_BOXES = []
for _k, (_col, _txt) in enumerate((("angle", "Angle"), ("scale", "Scale"), ("x", "X"), ("y", "Y"))):
    RAW_BOXES.append({"box": dict(id=f"obj-raw-head{_k}", maxclass="comment", text=_txt, patching_rect=[620.0, 20.0 + 22.0 * _k, 50.0, 18.0],
                                  presentation_rect=[_COL_X[_col], _HEAD_Y, _COL_W, 16.0], **_LBL)})
for _k, (_c, _y) in enumerate(_ROW_Y.items()):
    RAW_BOXES.append({"box": dict(id=f"obj-raw-row{_c}", maxclass="comment", text=_c.upper(), varname=f"lbl_plate_{_c}",
                                  patching_rect=[680.0, 20.0 + 22.0 * _k, 30.0, 18.0],
                                  presentation_rect=[_ROW_LABEL_X - 12.0, _y - 1.0, 24.0, 16.0], **_LBL)})

# T028 (Matt, 2026-11-14; spec FR-018, plan ADR-8): the plate rows read 1 / 2 / 3 in Plates mode, R / G / B otherwise.
# The Plate menu's index -> sel 2 -> `set` messages to the three row labels.
PLATE_MENU = "obj-23"      # the plate_mode live.menu (checked against the built patcher)
RAW_LINES = []


def _line(a, ao, b, bi):
    RAW_LINES.append({"patchline": {"source": [a, ao], "destination": [b, bi]}})


RAW_BOXES.append({"box": dict(id="obj-raw-platesel", maxclass="newobj", text="sel 2", numinlets=2, numoutlets=2,
                              outlettype=["bang", ""], patching_rect=[740.0, 20.0, 40.0, 22.0])})
_line(PLATE_MENU, 0, "obj-raw-platesel", 0)
for _k, _c in enumerate("rgb"):
    for _o, (_tag, _txt) in enumerate((("num", str(_k + 1)), ("let", _c.upper()))):
        _mid = f"obj-raw-set{_tag}{_c}"
        RAW_BOXES.append({"box": dict(id=_mid, maxclass="message", text=f"set {_txt}", numinlets=2, numoutlets=1, outlettype=[""],
                                      patching_rect=[740.0 + 60.0 * _k, 50.0 + 30.0 * _o, 50.0, 22.0])})
        _line("obj-raw-platesel", _o, _mid, 0)
        _line(_mid, 0, f"obj-raw-row{_c}", 0)

patcher["raw_boxes"] = RAW_BOXES
patcher["raw_lines"] = RAW_LINES
patcher["overrides"] = _ov
