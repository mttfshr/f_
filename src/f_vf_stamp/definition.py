"""
f_vf_stamp -- definition.py

A gated stamping tool: a texture says where and what colour, a held press says when. Inlet 0 is the stamp (its luma is
the mask, its RGB the ink), inlet 1 an optional vecfield. Outlets: the ink and the impulse vecfield. Stateless: what
persists is downstream (`f_vf_advect` keeps the ink, `f_vf_fluid` the momentum). With nothing on inlet 1 the impulse
comes from the stamp's own edge, radial or swirl. See .specify/f_vf_stamp/{spec,plan,tasks}.md.

One stage, rendered by `r draw` with the textures on cold inputs (plan ADR-9, the f_wave_field `enc` pattern), so it
draws with nothing connected. Connected flags `src_stamp` and `src_vec` come from each inlet's vs_inState. The output
follows the render size; the Params `width` and `height` are render_dim's.

Stamp is the `gate_button` type (build/spec.md). `stamp_gate` feeds the envelope below and never reaches the codebox,
which reads only `env` (FR-007, FR-008).

Verification: tests/modules/vf_stamp (mirror, test_vf_stamp.py), bench_vf_stamp.py (GPU vs mirror) and
bench_vf_stamp_module.py (the shipped patcher).
"""

patcher = {
    "name":               "f_vf_stamp",
    "prefix":             "vfstamp",
    "title":              "Stamp",
    "signal_type":        "∇ in/out",

    "presentation_width":  190,
    "presentation_height": 232,

    "archetype": "processor",

    "outlets": [
        {"comment": "ink"},
        {"comment": "impulse (vecfield)"},
    ],

    "params": [
        {"name": "threshold", "type": "float", "min": 0.0, "max": 1.0, "default": 0.05,
         "label": "Thresh",
         "hint": "Luma above which the stamp covers. Low by default so saturated reds and blues stamp too"},
        {"name": "softness", "type": "float", "min": 0.0, "max": 1.0, "default": 0.1,
         "label": "Soft",
         "hint": "Width of the mask's edge, in luma. It softens a soft stamp; a hard-edged stamp stays hard, whatever this says"},
        {"name": "amount", "type": "float", "min": 0.0, "max": 4.0, "default": 1.0,
         "label": "Amount",
         "hint": "Ink strength. Above 1 lifts a short tap"},
        {"name": "force", "type": "float", "min": 0.0, "max": 2.0, "default": 1.0,
         "label": "Force",
         "hint": "Impulse strength, for the field on inlet 1 and for the stamp's own push alike"},
        {"name": "rim", "type": "float", "min": 0.005, "max": 0.05, "default": 0.015,
         "label": "Rim",
         "hint": "Width of the push around the stamp's edge, in frame widths. Does nothing with a field on inlet 1"},
        {"name": "attack", "type": "float", "min": 0.0, "max": 60.0, "default": 0.0,
         "label": "Attack", "pix_wire": False,
         "hint": "How fast the stamp comes on after a press, in frames. 0 = at once"},
        {"name": "release", "type": "float", "min": 0.0, "max": 120.0, "default": 8.0,
         "label": "Release", "pix_wire": False,
         "hint": "How fast the stamp fades after a release, in frames. 0 = at once"},
        {"name": "invert", "type": "text_button", "options": ["Norm", "Inv"], "default": 0, "label": "Invert",
         "hint": "Inv stamps where the texture is dark instead of where it is bright"},
        {"name": "impulse", "type": "text_button", "options": ["Radial", "Swirl"], "default": 0, "label": "Impulse",
         "hint": "The push with nothing on inlet 1. Radial pushes out from the stamp's edge, Swirl turns around it. f_vf_fluid's Project removes Radial and keeps Swirl"},
        {"name": "stamp", "type": "gate_button", "label": "Stamp", "gate_param": "stamp_gate",
         "rect": [78.0, 186.0, 28.0, 28.0], "label_rect": [67.0, 164.0, 50.0, 18.0],
         "hint": "Hold to stamp: the ink and the impulse flow while held. A tap is a kick, a hold is a pour"},
        {"name": "bypass", "type": "bypass"},

        # Feeds the envelope (the raw box below), not a codebox Param
        {"name": "stamp_gate", "type": "internal", "pix_target": "obj-raw-1"},
        # Driven by the envelope (`prepend param env`), never by a dial
        {"name": "env", "type": "internal"},
        # Set by each vs_inState via `prepend param` (1 = inlet connected)
        {"name": "src_stamp", "type": "internal"},
        {"name": "src_vec", "type": "internal"},
        # Driven by the bypass jsui (`prepend param bypass_gate`), never by the route
        {"name": "bypass_gate", "type": "internal"},
        # Render size, driven by render_dim
        {"name": "width", "type": "internal"},
        {"name": "height", "type": "internal"},
    ],

    "inlet_comment": "stamp texture / control",
    "inlet_fanout": {"texture": [["stamp", 1]], "state": ["stamp"], "state_param": "src_stamp"},
    "mod_inlets": [
        {"label": "vecfield", "vs_instate": True, "state_param": "src_vec",
         "fanout": [["stamp", 2]], "state_nodes": ["stamp"]},
    ],
    "draw_triggers": ["stamp"],
    "bypass_mode": "param",             # jsui -> prepend param bypass_gate -> stamp

    "render_dim": {
        "width_param":  "width",
        "height_param": "height",
        "param_stages": ["stamp"],
        "size_stages":  ["stamp"],
    },

    "pix_chain": [
        {"id": "stamp", "name": "#0_vfstamp_pix", "gen": "codebox_stamp.gen", "n_inlets": 3, "n_outlets": 2,
         "pix_attrs": "@adapt 0 @dim 256 256 @type float32", "primary": True},
    ],
    "pix_wires": [],
}


# ---- the envelope (raw boxes; plan ADR-3) -----------------------------------------------------------------------
#   gate:  `param stamp_gate 0/1` -> [route param] -> [route stamp_gate] -> the step's second inlet
#   rates: attack / release dial -> k = 1 at 0 frames, else 1 - exp(-1 / frames) -> the step's third / fourth inlet;
#          the gate's loadbang bangs both dials, so the rates are set however the dials load
#   step:  [r draw] -> [f] -> env + (gate - env) * k, k = attack's while rising, release's while falling
#          -> snap -> [f] right inlet (the state) and `param env` -> the stage
#   snap:  below 0.001 env is 0: a one-pole never gets there, and SC-002 wants the idle outputs exact
# Frames, never a timer: one step per draw. Which of the gate and the step moves first inside a draw shifts the fall
# by one frame at most, and the gate is still open for its two draws. Ids of the dials are the builder's: ui_params
# order, param_obj_id(5) and (6).
def _box(i, cls, rect, **kw):
    b = {"id": f"obj-raw-{i}", "maxclass": cls, "patching_rect": rect}
    b.update(kw)
    return {"box": b}


def _obj(i, text, nin, nout, rect, otypes=None):
    return _box(i, "newobj", rect, text=text, numinlets=nin, numoutlets=nout,
                outlettype=otypes or [""] * nout)


def _line(src, so, dst, di):
    ref = lambda o: o if isinstance(o, str) else f"obj-raw-{o}"      # int = a raw box, str = a full id
    return {"patchline": {"source": [ref(src), so], "destination": [ref(dst), di]}}


_IDS = {"attack": "obj-35", "release": "obj-38", "stage": "obj-5",
        "draw": "obj-gate-stamp-draw", "load": "obj-gate-stamp-load"}

_K = r"expr ($f1 <= 0.) + ($f1 > 0.) * (1. - exp(-1. / max($f1\, 0.001)))"

patcher["raw_boxes"] = [
    _obj(1, "route param", 2, 2, [460.0, 320.0, 70.0, 22.0]),
    _obj(2, "route stamp_gate", 2, 2, [460.0, 350.0, 100.0, 22.0]),
    _obj(3, _K, 1, 1, [580.0, 320.0, 280.0, 22.0]),
    _obj(4, _K, 1, 1, [580.0, 350.0, 280.0, 22.0]),
    _obj(5, "f", 2, 1, [460.0, 400.0, 30.0, 22.0], ["float"]),
    _obj(6, "expr $f1 + ($f2 - $f1) * (($f2 > $f1) * $f3 + ($f2 <= $f1) * $f4)", 4, 1, [460.0, 430.0, 360.0, 22.0]),
    _obj(7, "expr ($f1 >= 0.001) * $f1", 1, 1, [460.0, 460.0, 150.0, 22.0]),
    _obj(8, "prepend param env", 1, 1, [460.0, 490.0, 110.0, 22.0]),
]
patcher["raw_lines"] = [
    _line(1, 0, 2, 0), _line(2, 0, 6, 1),                          # gate -> the step's second inlet
    _line(_IDS["attack"], 0, 3, 0), _line(3, 0, 6, 2),             # attack dial -> k -> third inlet
    _line(_IDS["release"], 0, 4, 0), _line(4, 0, 6, 3),            # release dial -> k -> fourth inlet
    _line(_IDS["load"], 0, _IDS["attack"], 0), _line(_IDS["load"], 0, _IDS["release"], 0),    # load: the rates are set
    _line(_IDS["draw"], 0, 5, 0), _line(5, 0, 6, 0),               # draw -> env -> step
    _line(6, 0, 7, 0), _line(7, 0, 5, 1), _line(7, 0, 8, 0),       # step -> snap -> the state, and
    _line(8, 0, _IDS["stage"], 0),                                 # `param env` -> the stage
]
