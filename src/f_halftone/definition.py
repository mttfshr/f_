"""
f_halftone -- definition.py

Tone to marks: a fixed-angle halftone screen, one plate per color channel (R, G, B), each with its own angle and lattice
phase. Dot, Line, Threshold and Bayer, shape and jitter (T020-T025), and the Single plate mode (T016b).
Stateless, one stage. A texture processor: one inlet, one outlet; the output follows the render size (render_dim: Params
`width` and `height`). Spec, plan and tasks: .specify/f_halftone/{spec,plan,tasks}.md.
Mirror: tests/modules/halftone/halftone_mirror.py.

The panel below is a first placement by Claude (2026-11-13), not Matt's layout (tasks T013, gate G-ui-density): the type menu
in the title bar, Pitch over Soft on the left, then one pair of columns per plate with the angle above its x / y phase.
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
    "presentation_height": 212,

    "outlets": [{"comment": "texture"}],

    "params": [
        {"name": "screen", "type": "menu", "options": ["Dot", "Line", "Threshold", "Bayer"], "default": 0, "label": "Screen",
         "hint": "Dot: a lattice of dots, each sized by the tone at its center. Line: parallel lines whose width follows the tone. Threshold: ink where the tone is above Level. Bayer: an ordered dither, one pixel per mark"},
        {"name": "plate_mode", "type": "menu", "options": ["Channels", "Single"], "default": 0, "label": "Plate",
         "hint": "Channels: red, green and blue are three plates, each at its own angle. Single: the texture is one spot-color plate, screened once at the B angle and phase, in its own color (for f_separate's plates)"},
        {"name": "pitch", "type": "float", "min": 0.003, "max": 0.2, "default": 0.012, "label": "Pitch",
         "hint": "Lattice period in frame heights. Below about 10 pixels the inked area stops tracking the tone"},
        {"name": "softness", "type": "float", "min": 0.0, "max": 1.0, "default": 0.1, "label": "Soft",
         "hint": "Width of the edge between ink and no ink. 0 is as sharp as one pixel allows"},
        {"name": "dot_shape", "type": "float", "min": 0.0, "max": 1.0, "default": 0.0, "label": "Shape",
         "hint": "Dot only: round at 0, square at 1, the same inked area at every setting"},
        {"name": "jitter", "type": "float", "min": 0.0, "max": 1.0, "default": 0.0, "label": "Jitter",
         "hint": "Dot only: moves each dot off the lattice, from a regular screen at 0 toward a random one at 1. Above mid-tone it loses a little ink"},
        {"name": "seed", "type": "int", "min": 1, "max": 999, "default": 1, "label": "Seed", "modmode": 0,
         "hint": "Which random jitter pattern"},
        {"name": "level", "type": "float", "min": 0.0, "max": 1.0, "default": 0.5, "label": "Level",
         "hint": "Threshold only: the tone above which there is ink. Soft widens the cut"},
        {"name": "bayer_scale", "type": "float", "min": 1.0, "max": 16.0, "default": 1.0, "label": "Bayer",
         "hint": "Bayer only: pixels per dither cell, in whole pixels. 1 is the finest; larger gives a blocky, low-resolution dither"},
        {"name": "angle_r", "type": "float", "min": 0.0, "max": 180.0, "default": 15.0, "label": "Angle R",
         "hint": "Screen angle of the red plate, in degrees"},
        {"name": "angle_g", "type": "float", "min": 0.0, "max": 180.0, "default": 75.0, "label": "Angle G",
         "hint": "Screen angle of the green plate, in degrees"},
        {"name": "angle_b", "type": "float", "min": 0.0, "max": 180.0, "default": 45.0, "label": "Angle B",
         "hint": "Screen angle of the blue plate, in degrees"},
        {"name": "phase_r_x", "type": "float", "min": -1.0, "max": 1.0, "default": 0.0, "label": "R x",
         "hint": "Shifts the red plate's lattice along its own x, in pitches. The marks stay whole and sharp"},
        {"name": "phase_r_y", "type": "float", "min": -1.0, "max": 1.0, "default": 0.0, "label": "R y",
         "hint": "Shifts the red plate's lattice along its own y, in pitches"},
        {"name": "phase_g_x", "type": "float", "min": -1.0, "max": 1.0, "default": 0.0, "label": "G x",
         "hint": "Shifts the green plate's lattice along its own x, in pitches"},
        {"name": "phase_g_y", "type": "float", "min": -1.0, "max": 1.0, "default": 0.0, "label": "G y",
         "hint": "Shifts the green plate's lattice along its own y, in pitches"},
        {"name": "phase_b_x", "type": "float", "min": -1.0, "max": 1.0, "default": 0.0, "label": "B x",
         "hint": "Shifts the blue plate's lattice along its own x, in pitches"},
        {"name": "phase_b_y", "type": "float", "min": -1.0, "max": 1.0, "default": 0.0, "label": "B y",
         "hint": "Shifts the blue plate's lattice along its own y, in pitches"},
        {"name": "bypass", "type": "bypass"},

        # Driven by the bypass jsui (`prepend param bypass_gate`), never by a dial
        {"name": "bypass_gate", "type": "internal"},
        # Render size, driven by render_dim
        {"name": "width", "type": "internal"},
        {"name": "height", "type": "internal"},
    ],

    "codebox": open("/Users/matt/Github/f_/src/f_halftone/codebox_halftone.gen").read(),
}


# ---- the panel (Claude's first placement, 2026-11-13; T013) ----------------------------------------------------------
_ROW_TOP, _ROW_LOW = 38.0, 100.0    # dial tops; a label sits 18 px above
_COL_LEFT = 24.0                    # Pitch over Soft over Shape
_PLATE_X = {"r": 70.0, "g": 151.0, "b": 232.0}   # center of each plate's x-phase column; y-phase is 37 px right


def _dial_at(name, centre, y):
    return {f"{name}.ctl":   {"presentation_rect": [centre - 13.5, y, 27.0, 43.0]},
            f"{name}.label": {"presentation_rect": [centre - 25.0, y - 18.0, 50.0, 18.0]}}


_ov = {
    "title":        {"presentation_rect": [10.5, 0.0, 50.0, 21.0]},
    "screen.ctl":   {"presentation_rect": [64.0, 3.0, 52.0, 15.0]},
    "screen.label": {"hidden": 1},
    "plate_mode.ctl":   {"presentation_rect": [120.0, 3.0, 60.0, 15.0]},     # T016b: beside the Screen menu
    "plate_mode.label": {"hidden": 1},
}
_ov.update(_dial_at("pitch", _COL_LEFT, _ROW_TOP))
_ov.update(_dial_at("softness", _COL_LEFT, _ROW_LOW))
_ov.update(_dial_at("dot_shape", _COL_LEFT, _ROW_LOW + 62.0))     # T023: a third row on the left, under Soft
for _c, _x in _PLATE_X.items():
    _ov.update(_dial_at(f"angle_{_c}", _x + 18.5, _ROW_TOP))
    _ov.update(_dial_at(f"phase_{_c}_x", _x, _ROW_LOW))
    _ov.update(_dial_at(f"phase_{_c}_y", _x + 37.0, _ROW_LOW))
# T024, T025 (2026-11-14): Jitter, Seed and Level on the third row, under the red and green plates
_ov.update(_dial_at("jitter", _PLATE_X["r"], _ROW_LOW + 62.0))
_ov.update(_dial_at("level", _PLATE_X["g"], _ROW_LOW + 62.0))
_ov.update(_dial_at("bayer_scale", _PLATE_X["g"] + 37.0, _ROW_LOW + 62.0))     # Matt, 2026-11-14: a Bayer scale dial
_ov["seed.ctl"] = {"presentation_rect": [_PLATE_X["r"] + 37.0 - 17.0, _ROW_LOW + 62.0 + 14.0, 34.0, 15.0], "outlettype": ["", "int"],
                   "saved_attribute_attributes": {"valueof": {
                       "parameter_initial": [1.0], "parameter_initial_enable": 1, "parameter_linknames": 1,
                       "parameter_longname": "seed", "parameter_mmax": 999.0, "parameter_mmin": 1.0, "parameter_modmode": 0,
                       "parameter_shortname": "seed", "parameter_type": 1, "parameter_unitstyle": 0}}}
_ov["seed.label"] = {"presentation_rect": [_PLATE_X["r"] + 37.0 - 25.0, _ROW_LOW + 62.0 - 4.0, 50.0, 18.0]}
patcher["overrides"] = _ov
