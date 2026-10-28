"""
f_vf_immiscible -- definition.py

Immiscible two-phase blend of two upstream velocity vecfields.  A Cahn-Hilliard phase field phi (a fixed
256x256 float32 periodic state, advected by the blended velocity and phase-separated every frame) decides
where velocity A (phi = -1) and velocity B (phi = +1) show: out0 = phi as grey, out1 = the blended velocity
as an f_vecfield.  See .specify/f_vf_immiscible/{spec,plan,tasks}.md.

Stage chain (plan ADR-1, amended 2026-10-27), solver stages at a fixed 256x256 float32:
    inab -> adv (in1, cold) ; inab -> enc (in1)
    hold -> pass (in1) ; pass -> adv (in0, HOT)
    adv -> fx -> fy -> spec -> iy -> ix        (ix -> hold feedback ; ix -> enc in2)
  inab  A and B vecfields -> one packed 256x256 velocity texture (content gate, taps x taps average)
  hold  last state    pass  hold it, or reseed from the hash (Params reseed, salt, fill)
  adv   blend + advect phi + inject (Params dt, inject, thresh, taps, freeze, src_phi)
  fx/fy/iy/ix  separable DFT (phi and phi^3 as two complex fields)
  spec  stabilised Cahn-Hilliard step per bin (Params iface, coarsen, freeze, pull, fill)
  enc   render-size outlets: out0 phi grey, out1 blended velocity; bypass gate (Param bypass_gate)

`r draw` goes to inab, pass and enc.  inab and pass are both chain heads on the same bang: the cold inab
output must land before pass fires adv (T022 verifies the draw order on the shipped patcher).
Input 0 carries control messages plus the optional phi source texture (luma deposits phase B); inputs 1
and 2 are the velocity vecfields, each gated by vs_inState (src_a, src_b) so an unconnected or non-vecfield
input reads as zero velocity.  Bypass is a Param gate on enc (never native @bypass); outlets go neutral.
"""

SOLVER = "@adapt 0 @dim 256 256 @type float32"

patcher = {
    "name":               "f_vf_immiscible",
    "prefix":             "vfimm",
    "title":              "Immiscible",
    "signal_type":        "∇ in/out",

    "presentation_width":  190,
    "presentation_height": 150,

    "archetype": "processor",

    "outlets": [
        {"comment": "phi (grey scalar)"},
        {"comment": "blended velocity vecfield"},
    ],

    "params": [
        {"name": "dt", "type": "float", "min": 0.0, "max": 0.05, "default": 0.01,
         "label": "dt",
         "hint": "Advection step: how far the blend pattern is carried by the flow each frame"},
        {"name": "iface", "type": "float", "min": 1.5, "max": 12.0, "default": 4.0,
         "label": "Iface",
         "hint": "Interface width in solver texels: small = crisp edge between the two flows, large = soft blend zone"},
        {"name": "coarsen", "type": "float", "min": 0.0, "max": 1.0, "default": 0.3,
         "label": "Coarsen",
         "hint": "How fast the two phases pull together into bigger blobs; 0 = the pattern is only carried, never re-forms"},
        {"name": "inject", "type": "float", "min": 0.0, "max": 1.0, "default": 0.3,
         "label": "Inject",
         "hint": "How strongly the bright parts of the texture on input 0 deposit phase B (velocity B). The dial is cubic: gentle at the bottom, full strength at 1"},
        {"name": "thresh", "type": "float", "min": 0.0, "max": 0.9, "default": 0.5,
         "label": "Thresh",
         "hint": "Brightness the input-0 texture needs before it deposits anything: dim and mid-grey parts add nothing, only brighter parts do"},
        {"name": "pull", "type": "float", "min": 0.0, "max": 1.0, "default": 0.3,
         "label": "Pull",
         "hint": "Slowly pulls the overall mix back toward Fill, so a held source settles into a balance instead of flooding the screen with B. 0 = off"},
        {"name": "fill", "type": "float", "min": -0.6, "max": 0.6, "default": 0.0,
         "label": "Fill",
         "hint": "Mean mix at reset, and the balance point Pull relaxes toward: negative = mostly A, positive = mostly B"},
        {"name": "freeze", "type": "menu", "options": ["Off", "Freeze"], "default": 0,
         "label": "Freeze",
         "hint": "Hold the pattern still while the blend keeps running on it"},
        {"name": "taps", "type": "int", "min": 1, "max": 16, "default": 2,
         "label": "Taps", "ui": False,
         "hint": "Input filter: taps x taps samples per solver texel for the velocity and source inputs"},
        {"name": "reset", "type": "raw_ui"},
        {"name": "bypass", "type": "bypass"},

        # Set by vs_inState via `prepend param ...` (1 = that inlet is connected)
        {"name": "src_a", "type": "internal"},
        {"name": "src_b", "type": "internal"},
        {"name": "src_phi", "type": "internal"},
        # Driven by the module's own reset logic (`prepend param ...`), never by the route
        {"name": "reseed", "type": "internal"},
        {"name": "salt", "type": "internal"},
        # Driven by the bypass jsui (`prepend param bypass_gate`)
        {"name": "bypass_gate", "type": "internal"},
    ],

    "inlet_comment": "control / phi source texture",
    "inlet_fanout": {"texture": [["adv", 2]], "state": ["adv"], "state_param": "src_phi"},
    "mod_inlets": [
        {"label": "velocity A (phase A)", "vs_instate": True, "state_param": "src_a",
         "fanout": [["inab", 1]], "state_nodes": ["inab"]},
        {"label": "velocity B (phase B)", "vs_instate": True, "state_param": "src_b",
         "fanout": [["inab", 2]], "state_nodes": ["inab"]},
    ],
    "draw_triggers": ["inab", "pass", "enc"],
    "bypass_mode": "param",             # jsui -> prepend param bypass_gate -> enc (the primary)

    "pix_chain": [
        {"id": "inab", "name": "#0_imm_inab", "gen": "codebox_inab.gen",    "n_inlets": 3, "n_outlets": 1,
         "pix_attrs": SOLVER, "primary": False},
        {"id": "hold", "name": "#0_imm_hold", "gen": "pass",                "n_inlets": 1, "n_outlets": 1,
         "pix_attrs": SOLVER, "primary": False},
        {"id": "pass", "name": "#0_imm_pass", "gen": "codebox_pass.gen",    "n_inlets": 2, "n_outlets": 1,
         "pix_attrs": SOLVER, "primary": False},
        {"id": "adv",  "name": "#0_imm_adv",  "gen": "codebox_adv.gen",     "n_inlets": 3, "n_outlets": 1,
         "pix_attrs": SOLVER, "primary": False},
        {"id": "fx",   "name": "#0_imm_fx",   "gen": "codebox_dft_fx.gen",  "n_inlets": 1, "n_outlets": 1,
         "pix_attrs": SOLVER, "primary": False},
        {"id": "fy",   "name": "#0_imm_fy",   "gen": "codebox_dft_fy.gen",  "n_inlets": 1, "n_outlets": 1,
         "pix_attrs": SOLVER, "primary": False},
        {"id": "spec", "name": "#0_imm_spec", "gen": "codebox_spec.gen",    "n_inlets": 1, "n_outlets": 1,
         "pix_attrs": SOLVER, "primary": False},
        {"id": "iy",   "name": "#0_imm_iy",   "gen": "codebox_dft_iy.gen",  "n_inlets": 1, "n_outlets": 1,
         "pix_attrs": SOLVER, "primary": False},
        {"id": "ix",   "name": "#0_imm_ix",   "gen": "codebox_dft_ix.gen",  "n_inlets": 1, "n_outlets": 1,
         "pix_attrs": SOLVER, "primary": False},
        {"id": "enc",  "name": "#0_imm_enc",  "gen": "codebox_enc.gen",     "n_inlets": 3, "n_outlets": 2,
         "pix_attrs": "@adapt 1 @type float32", "primary": True},
    ],
    "pix_wires": [
        ["hold", 0, "pass", 1],     # previous state (cold)
        ["pass", 0, "adv", 0],      # state (HOT: fires adv)
        ["inab", 0, "adv", 1],      # packed velocity (cold)
        ["adv", 0, "fx", 0], ["fx", 0, "fy", 0], ["fy", 0, "spec", 0],
        ["spec", 0, "iy", 0], ["iy", 0, "ix", 0],
        ["ix", 0, "hold", 0],       # feedback edge
        ["inab", 0, "enc", 1],      # velocity -> encode (cold)
        ["ix", 0, "enc", 2],        # phi state -> encode (cold)
    ],
}

# UI parameter / internal flag -> the stage(s) whose codebox Param it sets (the first is the control's
# param_connect target).
_STAGES_OF = {"dt": "adv", "iface": "spec", "coarsen": "spec", "inject": "adv", "thresh": "adv", "pull": "spec",
              "fill": ["pass", "spec"], "freeze": ["adv", "spec"], "taps": ["inab", "adv"],
              "reseed": "pass", "salt": "pass"}
for _p in patcher["params"]:
    if _p["name"] in _STAGES_OF:
        _p["pix_target"] = _STAGES_OF[_p["name"]]


# ---- reset logic (raw boxes) ----------------------------------------------------------------------------
#   button / `reset` message / load (after 200 ms) --> [t b b b]
#       right : 0 -> [i] right inlet           restart the frame count
#       middle: `param reseed 1` -> pass       reseed the state
#       left  : [counter] -> prepend param salt -> pass     a new hash pattern each reset
#   [r draw] -> [i] -> [+ 1] -> [i] ; [i] -> [sel 2] -> `param reseed 0` -> pass
# reseed stays 1 for three draw bangs (never a timer), as f_ks.
# Object ids (positional -- build/spec.md): support stages start at _SUP in chain order (inab, hold, pass,
# adv, fx, fy, spec, iy, ix), enc (primary) = obj-5, the route is obj-4 and `reset` is its LAST outlet.
# _SUP follows build_patcher.chain_id_base: 50 below ten widgets (this module has six).
_N_CONTROLS = sum(1 for _p in patcher["params"] if _p["type"] in ("float", "int", "menu"))
_N_HEADER = sum(1 for _p in patcher["params"] if _p["type"] == "header_toggle")
_SUP = 50 if _N_CONTROLS < 10 else 20 + 3 * _N_CONTROLS + 2
_PASS = f"obj-{_SUP + 2}"        # chain order: inab, hold, pass


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
         presentation=1, presentation_rect=[151.0, 104.0, 28.0, 28.0], varname="reset_button",
         hint="Reseed the pattern: mean mix = Fill, plus a little noise"),
    _box(2, "comment", [90.0, 346.0, 50.0, 18.0], fontname="Ableton Sans Light", fontsize=9.5,
         numinlets=1, numoutlets=0, presentation=1, presentation_rect=[140.0, 82.0, 50.0, 18.0],
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
    _line("obj-4", _N_CONTROLS + _N_HEADER, 3, 0),   # route: `reset` -> trigger (its last outlet)
    _line(1, 0, 3, 0),               # button -> trigger
    _line(4, 0, 5, 0), _line(5, 0, 3, 0),     # loadbang -> delay -> trigger
    _line(3, 2, 6, 0), _line(6, 0, 11, 1),    # trigger right -> 0 -> [i] right inlet
    _line(3, 1, 7, 0), _line(7, 0, _PASS, 0),       # trigger middle -> reseed 1 -> pass
    _line(3, 0, 8, 0), _line(8, 0, 9, 0), _line(9, 0, _PASS, 0),      # trigger left -> counter -> salt
    _line(10, 0, 11, 0), _line(11, 0, 12, 0), _line(12, 0, 11, 1),    # draw -> [i] -> +1 -> [i]
    _line(11, 0, 13, 0), _line(13, 0, 14, 0), _line(14, 0, _PASS, 0),   # sel 2 -> reseed 0 -> pass
]
