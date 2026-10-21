"""
f_ks -- definition.py

2D Kuramoto-Sivashinsky generator on the GPU: a self-sustaining chaotic pattern (cells, ridges,
spiral-ish defects) that never settles. A generator: no texture inlet, one luma outlet.
See .specify/f_ks/{spec,plan,tasks}.md.

Stage chain (the f_vf_fluid ADR-1 pattern), solver stages at a fixed 256x256 float32:
    hold -> pass (in 1) ; seed -> pass (in 2)
    pass -> fx -> fy -> spec -> iy -> ix -> nl      (nl -> hold feedback)
                                              nl -> enc (render resolution)
  seed  hash noise (Param salt)    pass  hold last state, or reseed from the noise (Param reseed)
  fx/fy/iy/ix  separable DFT       spec  exact linear step per Fourier bin (Param dt, L)
  nl    nonlinear step + containment (Param dt, L)    enc  render-res periodic upsample + luma map
                                                       + bypass gate (Param bypass_gate)

The `r draw` bang goes to seed, pass and enc (draw_triggers); the feedback and the noise arrive on cold
inlets, so the loop advances exactly once per rendered frame.

Controls: `rate` is the time step per frame, its range ends at the measured stability ceiling (0.0625 at
N = 256; 0.075 diverged), so no setting can blow the solver up.  `reset` (a button, a `reset` message or a
message on the control inlet) reseeds the field from fresh noise; it also fires once on load.
Bypass follows f_chladni: black, alpha 1, and the solver keeps running underneath.

Verification: tests/modules/ks (mirror, 17 tests) and tests/modules/ks/bench_ks.py (GPU vs mirror).
"""

patcher = {
    "name":               "f_ks",
    "prefix":             "ks",
    "title":              "Kuramoto-Sivashinsky",
    "signal_type":        "luma out",

    "presentation_width":  190,
    "presentation_height": 110,

    "archetype": "source",
    "pix_type":  "float32",

    "outlets": [
        {"comment": "pattern (luma)"},
    ],

    "params": [
        {"name": "rate", "type": "float", "min": 0.0, "max": 0.0625, "default": 0.05,
         "label": "Rate", "pix_attr": "dt", "pix_target": ["spec", "nl"],
         "hint": "Time step per frame: how fast the pattern evolves. The top of the range is the stability limit"},
        {"name": "reset", "type": "raw_ui"},
        {"name": "bypass", "type": "bypass"},

        # Driven by the module's own reset logic (`prepend param ...`), never by the route
        {"name": "reseed", "type": "internal"},
        {"name": "salt", "type": "internal"},
        # Driven by the bypass jsui (`prepend param bypass_gate`)
        {"name": "bypass_gate", "type": "internal"},
    ],

    "inlet_comment": "control",
    "draw_triggers": ["seed", "pass", "enc"],
    "bypass_mode": "param",             # jsui -> prepend param bypass_gate -> enc (the primary)

    "pix_chain": [
        {"id": "hold", "name": "#0_ks_hold", "gen": "pass",              "n_inlets": 1, "n_outlets": 1,
         "pix_attrs": "@adapt 0 @dim 256 256 @type float32", "primary": False},
        {"id": "seed", "name": "#0_ks_seed", "gen": "codebox_seed.gen",  "n_inlets": 1, "n_outlets": 1,
         "pix_attrs": "@adapt 0 @dim 256 256 @type float32", "primary": False},
        {"id": "pass", "name": "#0_ks_pass", "gen": "codebox_pass.gen",  "n_inlets": 3, "n_outlets": 1,
         "pix_attrs": "@adapt 0 @dim 256 256 @type float32", "primary": False},
        {"id": "fx",   "name": "#0_ks_fx",   "gen": "codebox_dft_fx.gen", "n_inlets": 1, "n_outlets": 1,
         "pix_attrs": "@adapt 0 @dim 256 256 @type float32", "primary": False},
        {"id": "fy",   "name": "#0_ks_fy",   "gen": "codebox_dft_fy.gen", "n_inlets": 1, "n_outlets": 1,
         "pix_attrs": "@adapt 0 @dim 256 256 @type float32", "primary": False},
        {"id": "spec", "name": "#0_ks_spec", "gen": "codebox_spec.gen",  "n_inlets": 1, "n_outlets": 1,
         "pix_attrs": "@adapt 0 @dim 256 256 @type float32", "primary": False},
        {"id": "iy",   "name": "#0_ks_iy",   "gen": "codebox_dft_iy.gen", "n_inlets": 1, "n_outlets": 1,
         "pix_attrs": "@adapt 0 @dim 256 256 @type float32", "primary": False},
        {"id": "ix",   "name": "#0_ks_ix",   "gen": "codebox_dft_ix.gen", "n_inlets": 1, "n_outlets": 1,
         "pix_attrs": "@adapt 0 @dim 256 256 @type float32", "primary": False},
        {"id": "nl",   "name": "#0_ks_nl",   "gen": "codebox_nl.gen",    "n_inlets": 1, "n_outlets": 1,
         "pix_attrs": "@adapt 0 @dim 256 256 @type float32", "primary": False},
        {"id": "enc",  "name": "#0_ks_enc",  "gen": "codebox_enc.gen",   "n_inlets": 2, "n_outlets": 1,
         "pix_attrs": "@adapt 1 @type float32", "primary": True},
    ],
    "pix_wires": [
        ["hold", 0, "pass", 1],     # previous state (cold)
        ["seed", 0, "pass", 2],     # noise (cold)
        ["pass", 0, "fx", 0], ["fx", 0, "fy", 0], ["fy", 0, "spec", 0],
        ["spec", 0, "iy", 0], ["iy", 0, "ix", 0], ["ix", 0, "nl", 0],
        ["nl", 0, "hold", 0],       # feedback edge
        ["nl", 0, "enc", 1],        # state -> encode (cold)
    ],
}

# Codebox Params that are not a UI control: which stage holds them (the internal ones are driven by raw
# boxes through `prepend param <name>`; see the reset logic).
_STAGES_OF = {"reseed": "pass", "salt": "seed"}
for _p in patcher["params"]:
    if _p["name"] in _STAGES_OF:
        _p["pix_target"] = _STAGES_OF[_p["name"]]


# ---- reset logic (raw boxes) ----------------------------------------------------------------------------
#   button / `reset` message / load --> [t b b b]
#       right : 0 -> [i] right inlet           restart the frame count
#       middle: `param reseed 1` -> pass       reseed the state
#       left  : [counter] -> prepend param salt -> seed     a new noise pattern each reset
#   [r draw] -> [i] -> [+ 1] -> [i] ; [i] -> [sel 2] -> `param reseed 0` -> pass
# reseed stays 1 for three draw bangs (never a timer): if rendering is not running yet the reseed waits,
# and at least two rendered frames see it.  Object ids: pass obj-52, seed obj-51 (chain order, build/spec.md).
def _box(i, cls, rect, **kw):
    b = {"id": f"obj-raw-{i}", "maxclass": cls, "patching_rect": rect}
    b.update(kw)
    return {"box": b}


def _obj(i, text, nin, nout, rect, otypes=None):
    return _box(i, "newobj", rect, text=text, numinlets=nin, numoutlets=nout,
                outlettype=otypes or [""] * nout)


def _msg(i, text, rect):
    return _box(i, "message", rect, text=text, numinlets=2, numoutlets=1, outlettype=[""])


def _line(src, so, dst, di):
    ref = lambda o: o if isinstance(o, str) else f"obj-raw-{o}"      # int = a raw box, str = a full id
    return {"patchline": {"source": [ref(src), so], "destination": [ref(dst), di]}}


patcher["raw_boxes"] = [
    _box(1, "button", [90.0, 320.0, 24.0, 24.0], numinlets=1, numoutlets=1, outlettype=["bang"],
         presentation=1, presentation_rect=[62.0, 46.0, 28.0, 28.0], varname="reset_button",
         hint="Reseed the field from fresh noise"),
    _box(2, "comment", [90.0, 346.0, 50.0, 18.0], fontname="Ableton Sans Light", fontsize=9.5,
         numinlets=1, numoutlets=0, presentation=1, presentation_rect=[51.0, 24.0, 50.0, 18.0],
         text="Reset", textjustification=1, varname="lbl_reset"),
    _obj(3, "t b b b", 1, 3, [90.0, 380.0, 52.0, 22.0], ["bang", "bang", "bang"]),
    _obj(4, "loadbang", 1, 1, [200.0, 330.0, 60.0, 22.0], ["bang"]),
    _obj(5, "delay 200", 2, 1, [200.0, 355.0, 60.0, 22.0], ["bang"]),
    _msg(6, "0", [150.0, 420.0, 30.0, 22.0]),
    _msg(7, "param reseed 1", [90.0, 420.0, 80.0, 22.0]),
    _obj(8, "counter", 5, 4, [30.0, 420.0, 50.0, 22.0], ["int", "", "", "int"]),
    _obj(9, "prepend param salt", 1, 1, [30.0, 450.0, 110.0, 22.0]),
    _obj(10, "r draw", 0, 1, [260.0, 420.0, 50.0, 22.0]),
    _obj(11, "i", 2, 1, [260.0, 450.0, 30.0, 22.0], ["int"]),
    _obj(12, "+ 1", 2, 1, [300.0, 480.0, 30.0, 22.0], ["int"]),
    _obj(13, "sel 2", 2, 2, [260.0, 480.0, 40.0, 22.0], ["bang", ""]),
    _msg(14, "param reseed 0", [260.0, 510.0, 85.0, 22.0]),
]
patcher["raw_lines"] = [
    _line("obj-4", 1, 3, 0),         # route: `reset` -> trigger   (route outlet 1; outlet 0 is rate)
    _line(1, 0, 3, 0),               # button -> trigger
    _line(4, 0, 5, 0), _line(5, 0, 3, 0),     # loadbang -> delay -> trigger
    _line(3, 2, 6, 0), _line(6, 0, 11, 1),    # trigger right -> 0 -> [i] right inlet
    _line(3, 1, 7, 0), _line(7, 0, "obj-52", 0),    # trigger middle -> reseed 1 -> pass
    _line(3, 0, 8, 0), _line(8, 0, 9, 0), _line(9, 0, "obj-51", 0),   # trigger left -> counter -> salt
    _line(10, 0, 11, 0), _line(11, 0, 12, 0), _line(12, 0, 11, 1),    # draw -> [i] -> +1 -> [i]
    _line(11, 0, 13, 0), _line(13, 0, 14, 0), _line(14, 0, "obj-52", 0),   # sel 2 -> reseed 0 -> pass
]
