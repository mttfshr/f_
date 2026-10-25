"""definition.py -- f_formconstants: the PARITY build of WC_Example_10_fullscreen.html
(spec Revision 2, tasks Phase R).

A faithful port of the webgpgpu page: a FIXED 1024 x 1024 float32 Wilson-Cowan solver
(S1), 8-bit quantization at the page's three points (S2), the separable multi-sigma
Gaussian coupling sigma (1, 2) with a shared radius 6 (S3), the Example-10 constants
and the `s` square-wave drive (S4, S5), a one-time uint8 seed (S6), and the bare
conformal log-polar display map on the output size (S7), RGB out (S8). Nothing else:
no noise, no habituation. Phase D adds deviations one at a time; so far T061 (2026-10-24): the
`depth` / `period` dials and the pulse inlet (luma replaces the internal square wave, read on the
solver grid; unconnected = the internal wave through a vs_inState flag, Param pulse_conn).

The steady-web build this replaces (Psychedelic constants + noise + habituation, a
render-resolution solver, 12 dials) is the reference at git commit 63b6129.

Layout:

    hold -> pass (in 1) ; seed -> pass (in 2)
    pass -> blur_x -> blur_y -> nl (in 1) ; pass -> nl (in 2) ; pulse -> nl (in 3)
    nl -> hold (feedback) ; nl -> enc (in 2)

    pass   hold last state (R = E, G = I, B = contour, A = 1 flag), or reseed it from the seed
           (Param reseed); a texel whose alpha is 0 is lost and reseeds too (S6)
    seed   hash noise, uniform uint8 in all four channels (Param salt, advanced per RESET only)
    blur_x / blur_y
           GPUGaussianMultiBlur(1, 2, 1, 1): 13 taps, per-channel weights, wrap, quantized (S2, S3)
    nl     the page's `wc` shader: E, I relax toward F(couplings - H [+ s on E]); out = (q(E), q(I),
           q8(3 |E - I|), 1); s = s_depth * mix(square(frameno / s_period), luma(pulse), pulse_conn)
           (S2, S4, S5; T061)
    enc    the retinal map on the OUTPUT size (Params ow, oh from `r dim`): square crop on the long
           axis, sample the state at (atan2, ln r)/2 pi, bilinear + wrap, RGB out (S7, S8)

The solver stages are fixed `@dim 1024 1024` and NO `r dim` message reaches them (S1: the page's
solver never follows the window). Only enc follows the render size. Every codebox takes the grid
size from a Param n (default 1024), never the gen `dim` global (test_fc_codebox_static.py asserts
the default equals the @dim below).

Verification: tests/modules/formconstants/fc_parity_mirror.py + test_fc_parity.py (tier 1);
bench legs against the mirror (T046) and the look gate against the HTML page (T048).
"""

SOLVER_N = 1024

patcher = {
    "name":               "f_formconstants",
    "prefix":             "fc",
    "title":              "Form Constants",
    "signal_type":        "rgb out",

    "presentation_width":  377,             # nine controls + reset in a tenth slot (T069 sets the final layout)
    "presentation_height": 88,

    "archetype": "source",
    "pix_type":  "float32",

    "outlets": [
        {"comment": "pattern (RGB: E, I, contour)"},
    ],

    "params": [
        # Phase D T061 (Matt, 2026-10-24): the pulse. s = depth * (pulse inlet luma if connected, else the
        # internal square wave of `period` frames). No dead-zone guard: kill and revive is a gesture.
        # Dial names are NOT `depth` / `period`: a control's param_connect names `<pix>::<dial name>`, and
        # jit.gl.pix has an int 0/1 attribute called `depth` -- a dial named `depth` bound to it and became
        # Type Int, Range 0 1 in Max (Matt, 2026-10-24). Prefixed names cannot collide with a pix attribute.
        {"name": "pulse_depth", "type": "float", "min": 0.0, "max": 1.5, "default": 0.6,
         "label": "Depth", "pix_attr": "s_depth", "pix_target": "nl",
         "hint": "Pulse depth (excitability). 0.6 = the source; 0 fades the field out slowly; ~1.5 kills it fast"},
        {"name": "pulse_period", "type": "float", "min": 30.0, "max": 600.0, "default": 147.0588,
         "label": "Period", "pix_attr": "s_period", "pix_target": "nl",
         "hint": "Internal pulse period in frames (used when the pulse inlet is unplugged). 147 = the source; under ~100 the field dies"},
        # Phase D T060 (Matt, 2026-10-24): output mode. Default E (provisional: "probably not RGB";
        # Matt picks after a live A/B). Name `out_mode`, not `output`/`mode` (pix attribute trap, T061).
        {"name": "out_mode", "type": "menu", "options": ["RGB", "E", "Contour", "Luma"], "default": 1,
         "label": "Output", "pix_target": "enc",
         "hint": "RGB = the source look (E, I, contour). E = the activity (spots). Contour = the boundary web. Luma = all three as gray"},
        # Phase D T062 (Matt, 2026-10-25): quantization levels at the page's three points (blur_x, blur_y,
        # nl). Only the living span: every level below 255 freezes the field (spike_fc_quant_levels.py).
        {"name": "q_levels", "type": "menu", "options": ["255", "1023", "Float"], "default": 0,
         "label": "Quant", "pix_target": ["nl", "blurx", "blury"],
         "hint": "Quantization: 255 = the source (crisp spots, lattice); 1023 in between; Float = softer, larger domains, slower to form"},
        # Phase D T070 (Matt, 2026-10-25): Freeze -- nl writes its incoming state back unchanged, so the
        # field holds; Off resumes from that state. A menu (the builder has no toggle type).
        {"name": "freeze_on", "type": "menu", "options": ["Off", "On"], "default": 0,
         "label": "Freeze", "pix_target": "nl",
         "hint": "Freeze: hold the field exactly where it is (the display keeps rendering); Off resumes from that state"},
        # Phase D T065 (Matt, 2026-10-25): Rate = slow motion by step skipping (the solver advances on a
        # fraction of the frames; the pulse clock counts solver steps), so the look is unchanged.
        {"name": "sim_rate", "type": "float", "min": 0.05, "max": 1.0, "default": 1.0,
         "label": "Rate", "pix_target": "nl",
         "hint": "Slow motion: 1 = the source speed; 0.5 = half speed, pulse and pattern together (same look)"},
        # Phase D T071 (Matt, 2026-10-25): how the pulse texture enters (only when it is plugged in).
        {"name": "pulse_mix", "type": "float", "min": 0.0, "max": 1.0, "default": 1.0,
         "label": "P.Mix", "pix_target": "nl",
         "hint": "Pulse texture vs the internal wave: 1 = the texture is the pulse; 0 = ignored; between = blend"},
        {"name": "pulse_gain", "type": "float", "min": 0.0, "max": 2.0, "default": 1.0,
         "label": "P.Gain", "pix_target": "nl",
         "hint": "Pulse texture brightness before it becomes the pulse: raise a dim image, tame a bright one"},
        # Phase D T072 (Matt, 2026-10-25): Grain = the blur's tap spacing (same 13 taps). Below 1 finer and
        # wormier, above 1 bigger softer spots; above ~1.5 the spaced taps alias into a moire (kept: Matt).
        {"name": "grain_scale", "type": "float", "min": 0.5, "max": 2.0, "default": 1.0,
         "label": "Grain", "pix_target": ["blurx", "blury"],
         "hint": "Pattern scale: 1 = the source lattice; lower = finer, wormier; higher = bigger spots, moire near 2"},
        {"name": "reset", "type": "raw_ui"},
        {"name": "bypass", "type": "bypass"},

        # Driven by the module's own reset/draw logic (`prepend param ...`), never by the route
        {"name": "reseed", "type": "internal"},
        {"name": "salt", "type": "internal"},
        {"name": "frameno", "type": "internal"},
        # Driven by the bypass jsui (`prepend param bypass_gate`)
        {"name": "bypass_gate", "type": "internal"},
        # Driven by the raw `r dim` unpack (`prepend param ow/oh`) -> enc only: the OUTPUT size
        {"name": "ow", "type": "internal"},
        {"name": "oh", "type": "internal"},
        # Driven by the pulse vs_inState connection flag (`prepend param pulse_conn` -> nl)
        {"name": "pulse_conn", "type": "internal"},
    ],

    "inlet_comment": "control",
    "mod_inlets": [
        {
            "label":       "pulse in (luma = the pulse; unconnected = internal square wave)",
            "vs_instate":  True,
            "state_param": "pulse_conn",
            "fanout":      [["nl", 2]],        # the pulse texture reads at nl in 3
            "state_nodes": ["nl"],             # connection flag -> param pulse_conn -> nl
        },
    ],
    "draw_triggers": ["seed", "pass", "enc"],
    "bypass_mode": "param",             # jsui -> prepend param bypass_gate -> enc (the primary)

    "pix_chain": [
        {"id": "hold",  "name": "#0_fc_hold",  "gen": "pass",               "n_inlets": 1, "n_outlets": 1,
         "pix_attrs": f"@adapt 0 @dim {SOLVER_N} {SOLVER_N} @type float32", "primary": False},
        {"id": "seed",  "name": "#0_fc_seed",  "gen": "codebox_seed.gen",   "n_inlets": 1, "n_outlets": 1,
         "pix_attrs": f"@adapt 0 @dim {SOLVER_N} {SOLVER_N} @type float32", "primary": False},
        {"id": "pass",  "name": "#0_fc_pass",  "gen": "codebox_pass.gen",   "n_inlets": 3, "n_outlets": 1,
         "pix_attrs": f"@adapt 0 @dim {SOLVER_N} {SOLVER_N} @type float32", "primary": False},
        {"id": "blurx", "name": "#0_fc_blurx", "gen": "codebox_blur_x.gen", "n_inlets": 1, "n_outlets": 1,
         "pix_attrs": f"@adapt 0 @dim {SOLVER_N} {SOLVER_N} @type float32", "primary": False},
        {"id": "blury", "name": "#0_fc_blury", "gen": "codebox_blur_y.gen", "n_inlets": 1, "n_outlets": 1,
         "pix_attrs": f"@adapt 0 @dim {SOLVER_N} {SOLVER_N} @type float32", "primary": False},
        {"id": "nl",    "name": "#0_fc_nl",    "gen": "codebox_nl.gen",     "n_inlets": 3, "n_outlets": 1,
         "pix_attrs": f"@adapt 0 @dim {SOLVER_N} {SOLVER_N} @type float32", "primary": False},
        {"id": "enc",   "name": "#0_fc_enc",   "gen": "codebox_enc.gen",    "n_inlets": 2, "n_outlets": 1,
         "pix_attrs": "@adapt 0 @dim 256 256 @type float32", "primary": True},    # follows `r dim`
    ],
    "pix_wires": [
        ["hold", 0, "pass", 1],     # previous state (cold)
        ["seed", 0, "pass", 2],     # seed (cold)
        ["pass", 0, "blurx", 0], ["blurx", 0, "blury", 0], ["blury", 0, "nl", 0],
        ["pass", 0, "nl", 1],       # raw state (cold; same frame as the convolved input)
        ["nl", 0, "hold", 0],       # feedback edge
        ["nl", 0, "enc", 1],        # state -> render (cold)
    ],
}

# Codebox Params that are not a UI control: which stage holds them (driven by raw boxes through
# `prepend param <name>`; see the reset logic below).
_STAGES_OF = {"reseed": "pass", "salt": "seed", "frameno": "nl", "ow": "enc", "oh": "enc"}
for _p in patcher["params"]:
    if _p["name"] in _STAGES_OF:
        _p["pix_target"] = _STAGES_OF[_p["name"]]


# ---- reset + frame counter + salt (raw boxes) ---------------------------------------------------------
#   button / `reset` message / loadbang -> [delay 200] -> [t b b b]
#       right  : `param reseed 1` -> pass      reseed the state from the seed
#       middle : 0 -> frame counter right inlet (the `s` phase and the reseed drop restart at t = 0)
#       left   : bang -> salt counter           a new seed per reset
#   [r draw] -> [i] -> [+ 1] -> [% 1000000] -> [i] right   the frame counter (T061: the period is a dial,
#                                                         so no short wrap is seamless; 1e6 frames ~ 4.6 h)
#   [i] -> [prepend param frameno] -> nl               the frame index drives the `s` square wave
#   [i] -> [sel 2] -> `param reseed 0` -> pass   reseed stays 1 for three draw bangs (never a timer)
#   salt: [i] -> [+ 1] -> [i] right ; [i] -> [prepend param salt] -> seed   (per reset, NOT per frame)
#   [r dim] -> enc, and -> [route dim] -> [unpack] -> [prepend param ow / oh] -> enc: the OUTPUT size only.
#   NOTHING from `r dim` reaches a solver stage (S1) and a resize does not reseed.
# Object ids (positional -- they shift when a UI box is added, build/spec.md): with no dial widgets the
# support stages start at obj-50: hold = obj-50, seed = obj-51, pass = obj-52, blurx = obj-53,
# blury = obj-54, nl = obj-55; enc (primary) = obj-5 (two dials: still under the ten-widget threshold, so
# the obj-50 base holds); the route is obj-4 with tokens pulse_depth, pulse_period, out_mode, q_levels,
# freeze_on, sim_rate, pulse_mix, pulse_gain, grain_scale, reset (`reset` = outlet 9). Nine widgets: one more
# crosses the ten-widget threshold and moves the support-stage ids (build/spec.md). tests/modules/formconstants/test_fc_codebox_static.py guards these.
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
         presentation=1, presentation_rect=[341.0, 44.0, 28.0, 28.0], varname="reset_button",
         hint="Reseed the fields from fresh noise"),
    _box(2, "comment", [90.0, 346.0, 50.0, 18.0], fontname="Ableton Sans Light", fontsize=9.5,
         numinlets=1, numoutlets=0, presentation=1, presentation_rect=[333.0, 20.0, 44.0, 18.0],
         text="Reset", textjustification=1, varname="lbl_reset"),
    _obj(3, "t b b b", 1, 3, [90.0, 380.0, 50.0, 22.0], ["bang", "bang", "bang"]),
    _obj(4, "loadbang", 1, 1, [200.0, 330.0, 60.0, 22.0], ["bang"]),
    _obj(5, "delay 200", 2, 1, [200.0, 355.0, 60.0, 22.0], ["bang"]),
    _msg(6, "param reseed 1", [90.0, 420.0, 80.0, 22.0]),
    _msg(7, "0", [200.0, 450.0, 30.0, 22.0]),
    _obj(8, "r draw", 0, 1, [260.0, 420.0, 50.0, 22.0]),
    _obj(9, "i", 2, 1, [260.0, 450.0, 30.0, 22.0], ["int"]),
    _obj(10, "+ 1", 2, 1, [300.0, 450.0, 30.0, 22.0], ["int"]),
    _obj(11, "% 1000000", 2, 1, [340.0, 450.0, 50.0, 22.0], ["int"]),
    _obj(12, "sel 2", 2, 2, [260.0, 480.0, 40.0, 22.0], ["bang", ""]),
    _msg(13, "param reseed 0", [260.0, 510.0, 85.0, 22.0]),
    _obj(14, "prepend param frameno", 1, 1, [350.0, 480.0, 100.0, 22.0]),
    _obj(15, "i", 2, 1, [30.0, 450.0, 30.0, 22.0], ["int"]),
    _obj(16, "+ 1", 2, 1, [70.0, 450.0, 30.0, 22.0], ["int"]),
    _obj(17, "prepend param salt", 1, 1, [30.0, 480.0, 110.0, 22.0]),
    _obj(18, "r dim", 0, 1, [480.0, 320.0, 40.0, 22.0]),
    _obj(19, "route dim", 1, 2, [530.0, 320.0, 60.0, 22.0], ["", ""]),
    _obj(20, "unpack", 1, 2, [530.0, 350.0, 50.0, 22.0], ["int", "int"]),
    _obj(21, "prepend param ow", 1, 1, [480.0, 380.0, 105.0, 22.0]),
    _obj(22, "prepend param oh", 1, 1, [590.0, 380.0, 105.0, 22.0]),
]
patcher["raw_lines"] = [
    _line("obj-4", 9, 3, 0),          # route: `reset` -> trigger (route outlet 9, after the nine controls)
    _line(1, 0, 3, 0),                # button -> trigger
    _line(4, 0, 5, 0), _line(5, 0, 3, 0),     # loadbang -> delay -> trigger
    _line(3, 2, 6, 0), _line(6, 0, "obj-52", 0),    # trigger right -> reseed 1 -> pass
    _line(3, 1, 7, 0), _line(7, 0, 9, 1),     # trigger middle -> 0 -> frame counter right inlet
    _line(3, 0, 15, 0),               # trigger left -> salt counter
    _line(8, 0, 9, 0), _line(9, 0, 10, 0), _line(10, 0, 11, 0), _line(11, 0, 9, 1),   # draw -> [i] -> +1 -> %2500 -> [i]
    _line(9, 0, 14, 0), _line(14, 0, "obj-55", 0),  # frame index -> param frameno -> nl
    _line(9, 0, 12, 0), _line(12, 0, 13, 0), _line(13, 0, "obj-52", 0),   # sel 2 -> reseed 0 -> pass
    _line(15, 0, 16, 0), _line(16, 0, 15, 1),       # salt counter
    _line(15, 0, 17, 0), _line(17, 0, "obj-51", 0),   # [i] -> param salt -> seed (per reset)
    _line(18, 0, "obj-5", 0),         # r dim -> enc: the output follows the render size
    _line(18, 0, 19, 0), _line(19, 0, 20, 0),
    _line(20, 0, 21, 0), _line(20, 1, 22, 0),
    _line(21, 0, "obj-5", 0), _line(22, 0, "obj-5", 0),     # -> enc: ow, oh
]
