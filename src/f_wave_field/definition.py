"""
f_wave_field -- definition.py

Spectral wave / resonator field ("Wave Field", gate G1): ripples, rings and plate waves on a 256x256 periodic
sheet that decay, reflect off nothing (an edge sponge) or wrap around, driven by an optional force texture (inlet
0, where), an optional LFO texture (inlet 1, when) and a strike. Outlets: luma (the height u) and a gradient
vecfield. With nothing connected it rings once from the load strike and decays: the point sine exciter was removed
2026-11-04 (D7), so spec User Story 1 ("keeps going") no longer holds. See .specify/f_wave_field/{spec,tasks}.md.

Stage chain (the f_ks / f_vf_fluid pattern), solver stages at a fixed 256x256 float32:
    hold -> pass (in 1)                          hold -> real (in 3)
    pass -> fx -> fy -> spec -> iy -> ix -> real      (real -> hold feedback)
                                            real -> enc (render resolution; two outlets)
  pass  hold last state, or clear (Param reset_gate); strips G and A so the DFT sees only u and v
  fx/fy/iy/ix  separable DFT, two complex fields per pass (u in R,G; v in B,A)
  spec  exact per-bin step of u_tt + 2 beta u_t + omega^2 u = 0 (Params speed, damping, dispersion, ring)
  real  force inlet, LFO inlet, strike, edge sponge, containment; carries G through unused; A stays 1
  enc   render-res periodic upsample, tanh luma map (outlet 1), tanh gradient vecfield (outlet 2), bypass gate

The `r draw` bang goes to pass and enc (draw_triggers); the feedback arrives on cold inlets, so the loop
advances exactly once per rendered frame. The force texture (inlet 0) and the LFO texture (inlet 1) reach `real`
through their own vs_inState; the connected flags `src_force` and `src_lfo` gate them (an unconnected inlet is
vs_black = 0, which would decode to a full -1 force).

Inlets (T033 / T036, Matt 2026-11-04): inlet 0 says WHERE, inlet 1 says WHEN. With a texture on inlet 0 Force pushes
with it (0 to 1.5) and Strike drops `strength` on its OUTLINES; with nothing there Strike is a point at the frame centre. An LFO
texture on inlet 1 gives the time function T per pixel (`lmode`: uni raw 0..1, bi 2 x - 1): it scales the texture push
and the strike, and does nothing alone (no push without inlet 0). The point sine exciter (Freq, Amp) was removed.

Time unit (gate G3, Matt 2026-10-25): one draw = 1/60 model second (Param dt, a codebox constant, not a dial).
Output mapping (gate G2): tanh with the `gain` dial in front. Dial set (gate G4): the proposed set.
`damping` starts at its floor (0.001, T003) so float32 round-off cannot grow energy.
Strike and reset: a button, a message or the load. Strike is a held PRESS (D11 / D12, T042): the button's ubutton sends
`param strike_gate 1` on mouse-down and `0` on mouse-up; the `strike` message is a tap, `strike 1` / `strike 0` press and
release; every release waits two draws (the `r draw` counter pattern), so a press is seen by at least two rendered
frames. While the gate is held the real stage pins u toward strength * amp * T along the outlines (replace, not add).
`reset` clears the field for a few draws and the pin waits for it (reset, then strike: the load behaviour, FR-009;
the load press is held until the reset has finished plus two draws).
Bypass follows f_ks: luma black alpha 1, vecfield neutral 0.5 / 0.5, the solver keeps running underneath.

Verification: tests/modules/wave_field (mirror, test_wave_field.py), bench_wave_field.py (GPU vs mirror) and
bench_wave_field_module.py (the shipped patcher).
"""

patcher = {
    "name":               "f_wave_field",
    "prefix":             "wf",
    "title":              "Wave Field",
    "signal_type":        "∇ out",

    "presentation_width":  190,
    "presentation_height": 232,

    "archetype": "processor",

    "outlets": [
        {"comment": "field (luma)"},
        {"comment": "gradient (vecfield)"},
    ],

    "params": [
        {"name": "speed", "type": "float", "min": 0.0, "max": 0.5, "default": 0.25,
         "label": "Speed", "pix_target": "spec",
         "hint": "Wave speed: how fast ripples cross the frame (frame widths per second at the middle scale). 0 with Ring makes a field of independent resonators"},
        {"name": "damping", "type": "float", "min": 0.001, "max": 5.0, "default": 0.2,
         "label": "Damp", "pix_target": "spec",
         "hint": "How fast waves die out. The bottom of the range is a tiny floor, so the field always settles eventually; high values go thick and syrupy"},
        {"name": "dispersion", "type": "float", "min": 0.5, "max": 2.0, "default": 1.0,
         "label": "Disp", "pix_target": "spec",
         "hint": "How wavelength sets speed: 1 = ordinary waves (a clean ring), 2 = a plate (short ripples run ahead of long ones), 0.5 = long swells outrun short ripples"},
        {"name": "ring", "type": "float", "min": 0.0, "max": 50.0, "default": 0.0,
         "label": "Ring", "pix_target": "spec",
         "hint": "A tone every point rings at on its own, whatever the wavelength. With Speed 0 the sheet becomes independent resonators"},
        {"name": "edge", "type": "float", "min": 0.0, "max": 1.0, "default": 0.5,
         "label": "Edge", "pix_attr": "edge_amt", "pix_target": "real",
         "hint": "Absorbing borders: 0 = waves wrap around to the opposite side, higher = they die at the edge without reflecting"},
        {"name": "force", "type": "float", "min": 0.0, "max": 1.5, "default": 1.0,
         "label": "Force", "pix_target": "real",
         "hint": "How hard the texture on inlet 0 pushes the field: mid-grey does nothing, brighter pushes up, darker pushes down. Past 1 it boosts a dim texture. An LFO on inlet 1 makes the push pulse"},
        {"name": "strength", "type": "float", "min": 0.0, "max": 1.0, "default": 1.0,
         "label": "Strength", "pix_target": "real",
         "hint": "How hard Strike hits: on the outlines of the texture on inlet 0, or at the frame centre with nothing connected. 0 = no strike. An LFO on inlet 1 shapes the pulse"},
        {"name": "gain", "type": "float", "min": 0.0, "max": 10.0, "default": 1.0,
         "label": "Gain", "pix_target": "enc",
         "hint": "Output strength before the soft tanh limiter: raise it to see quiet waves, lower it for big ones"},
        {"name": "lmode", "type": "text_button", "options": ["LFO uni", "LFO bi"], "default": 0, "label": "LFO mode",
         "pix_target": "real",
         "hint": "How the LFO on inlet 1 is read. LFO uni = raw 0..1 (can only add). LFO bi = rescaled to -1..1 (mid-grey = nothing, dark pulls the other way). Modelled on f_weave's Mod mode"},
        {"name": "strike", "type": "raw_ui"},
        {"name": "reset", "type": "raw_ui"},
        {"name": "bypass", "type": "bypass"},

        # Driven by the module's own logic (`prepend param ...`), never by a dial
        {"name": "reset_gate", "type": "internal"},
        {"name": "strike_gate", "type": "internal"},
        # Set by vs_inState via `prepend param src_force` (1 = force inlet connected)
        {"name": "src_force", "type": "internal"},
        # Set by the LFO inlet's vs_inState via `prepend param src_lfo` (1 = LFO inlet connected)
        {"name": "src_lfo", "type": "internal"},
        # Driven by the bypass jsui (`prepend param bypass_gate`), never by the route
        {"name": "bypass_gate", "type": "internal"},
    ],

    "inlet_comment": "force texture (where) / control",
    "inlet_fanout": {"texture": [["real", 1]], "state": ["real"], "state_param": "src_force"},
    # inlet 1: the LFO texture (the time function T), its own vs_inState and connected flag, into `real` inlet 3 (in4)
    "mod_inlets": [
        {"label": "LFO texture (when)", "vs_instate": True, "state_param": "src_lfo",
         "fanout": [["real", 3]], "state_nodes": ["real"]},
    ],
    "draw_triggers": ["pass", "enc"],
    "bypass_mode": "param",             # jsui -> prepend param bypass_gate -> enc (the primary)

    "pix_chain": [
        {"id": "hold", "name": "#0_wf_hold", "gen": "pass",               "n_inlets": 1, "n_outlets": 1,
         "pix_attrs": "@adapt 0 @dim 256 256 @type float32", "primary": False},
        {"id": "pass", "name": "#0_wf_pass", "gen": "codebox_pass.gen",   "n_inlets": 2, "n_outlets": 1,
         "pix_attrs": "@adapt 0 @dim 256 256 @type float32", "primary": False},
        {"id": "fx",   "name": "#0_wf_fx",   "gen": "codebox_dft_fx.gen", "n_inlets": 1, "n_outlets": 1,
         "pix_attrs": "@adapt 0 @dim 256 256 @type float32", "primary": False},
        {"id": "fy",   "name": "#0_wf_fy",   "gen": "codebox_dft_fy.gen", "n_inlets": 1, "n_outlets": 1,
         "pix_attrs": "@adapt 0 @dim 256 256 @type float32", "primary": False},
        {"id": "spec", "name": "#0_wf_spec", "gen": "codebox_spec.gen",   "n_inlets": 1, "n_outlets": 1,
         "pix_attrs": "@adapt 0 @dim 256 256 @type float32", "primary": False},
        {"id": "iy",   "name": "#0_wf_iy",   "gen": "codebox_dft_iy.gen", "n_inlets": 1, "n_outlets": 1,
         "pix_attrs": "@adapt 0 @dim 256 256 @type float32", "primary": False},
        {"id": "ix",   "name": "#0_wf_ix",   "gen": "codebox_dft_ix.gen", "n_inlets": 1, "n_outlets": 1,
         "pix_attrs": "@adapt 0 @dim 256 256 @type float32", "primary": False},
        {"id": "real", "name": "#0_wf_real", "gen": "codebox_real.gen",   "n_inlets": 4, "n_outlets": 1,
         "pix_attrs": "@adapt 0 @dim 256 256 @type float32", "primary": False},
        {"id": "enc",  "name": "#0_wf_enc",  "gen": "codebox_enc.gen",    "n_inlets": 2, "n_outlets": 2,
         "pix_attrs": "@adapt 1 @type float32", "primary": True},
    ],
    "pix_wires": [
        ["hold", 0, "pass", 1],     # previous state (cold)
        ["hold", 0, "real", 2],     # previous state (cold; real reads and re-writes its G only so that in3 is a real inlet)
        ["pass", 0, "fx", 0], ["fx", 0, "fy", 0], ["fy", 0, "spec", 0],
        ["spec", 0, "iy", 0], ["iy", 0, "ix", 0], ["ix", 0, "real", 0],
        ["real", 0, "hold", 0],     # feedback edge
        ["real", 0, "enc", 1],      # state -> encode (cold)
    ],
}

# Codebox Params that are not a UI control, and where each lives (reset_gate is read by two stages).
_STAGES_OF = {"reset_gate": ["pass", "real"], "strike_gate": "real"}
for _p in patcher["params"]:
    if _p["name"] in _STAGES_OF:
        _p["pix_target"] = _STAGES_OF[_p["name"]]


# ---- reset and strike logic (raw boxes) --------------------------------------------------------------------
#   loadbang -> delay 200 -> [t b b] reset trigger, and -> a PRESS (load strike); `1` opens a [spigot] so the
#     reset's [sel 2] (reset_gate back to 0) releases that press once: [spigot] -> [t b b] (right: `0` closes it; left: RELEASE)
#   reset button / `reset` message -> [t b b]:  right: 0 -> [i] right inlet (restart the draw count)
#                                              left : `param reset_gate 1` -> pass and real
#   strike ubutton: outlet 1 (mouse-down) -> PRESS, outlet 0 (mouse-up) -> RELEASE (a plain button has no release)
#   `strike` message -> [sel bang 1 0]: bare `strike` = tap (PRESS then RELEASE), `strike 1` = PRESS, `strike 0` = RELEASE
#   PRESS   = [t b b]: right `100` -> [i] right inlet (cancels a pending release), left `param strike_gate 1` -> real
#   RELEASE = `0` -> [i] right inlet; [r draw] -> [i] -> [+ 1] -> [i] ; [i] -> [sel 2] -> `param strike_gate 0` -> real
#     (the third draw bang after the release, so the gate is seen by at least two frames, never a timer)
#   [r draw] -> [i] -> [+ 1] -> [i] ; [i] -> [sel 2] -> `param reset_gate 0` -> pass and real   (reset_gate stays 1
#     for two draw bangs: if rendering is not running yet it waits)
# strike_gate is idempotent in the codebox (a pin), so there is no counter and no state memory. Object ids of the
# chain stages and the route are the builder's (pass obj-?? etc., see _IDS below, checked by the
# bench_wave_field_module wiring test).
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


# Filled in from the built patcher (build order of pix_chain: hold, pass, fx, fy, spec, iy, ix, real, enc).
_IDS = {"route": "obj-4", "pass": "obj-51", "real": "obj-57"}

patcher["raw_boxes"] = [
    _box(1, "button", [90.0, 320.0, 24.0, 24.0], numinlets=1, numoutlets=1, outlettype=["bang"],
         presentation=1, presentation_rect=[115.0, 186.0, 28.0, 28.0], varname="reset_button",
         hint="Clear the field"),
    _box(2, "comment", [90.0, 346.0, 50.0, 18.0], fontname="Ableton Sans Light", fontsize=9.5,
         numinlets=1, numoutlets=0, presentation=1, presentation_rect=[104.0, 164.0, 50.0, 18.0],
         text="Reset", textjustification=1, varname="lbl_reset"),
    # the Strike face: a panel behind a transparent ubutton (a plain button reports no release)
    _box(18, "panel", [30.0, 320.0, 24.0, 24.0], numinlets=1, numoutlets=0, background=1, ignoreclick=1,
         border=2, bordercolor=[0.55, 0.55, 0.55, 1.0], bgcolor=[0.2, 0.2, 0.2, 1.0], rounded=14,
         presentation=1, presentation_rect=[78.0, 186.0, 28.0, 28.0], varname="strike_face"),
    _box(3, "ubutton", [30.0, 320.0, 24.0, 24.0], numinlets=1, numoutlets=4,
         outlettype=["bang", "bang", "", "int"], hltcolor=[1.0, 1.0, 1.0, 0.45],
         presentation=1, presentation_rect=[78.0, 186.0, 28.0, 28.0], varname="strike_button",
         hint="Hold to strike: pins the outlines of the inlet texture (or the frame centre with nothing connected) while held; release lets the waves ring out"),
    _box(4, "comment", [30.0, 346.0, 50.0, 18.0], fontname="Ableton Sans Light", fontsize=9.5,
         numinlets=1, numoutlets=0, presentation=1, presentation_rect=[67.0, 164.0, 50.0, 18.0],
         text="Strike", textjustification=1, varname="lbl_strike"),
    _obj(5, "t b b", 1, 2, [90.0, 380.0, 40.0, 22.0], ["bang", "bang"]),
    _obj(6, "loadbang", 1, 1, [200.0, 330.0, 60.0, 22.0], ["bang"]),
    _obj(7, "delay 200", 2, 1, [200.0, 355.0, 60.0, 22.0], ["bang"]),
    _msg(8, "0", [150.0, 420.0, 30.0, 22.0]),
    _msg(9, "param reset_gate 1", [90.0, 420.0, 100.0, 22.0]),
    _obj(12, "r draw", 0, 1, [260.0, 420.0, 50.0, 22.0]),
    _obj(13, "i", 2, 1, [260.0, 450.0, 30.0, 22.0], ["int"]),
    _obj(14, "+ 1", 2, 1, [300.0, 480.0, 30.0, 22.0], ["int"]),
    _obj(15, "sel 2", 2, 2, [260.0, 480.0, 40.0, 22.0], ["bang", ""]),
    _msg(16, "param reset_gate 0", [260.0, 510.0, 100.0, 22.0]),
    # the strike gate
    _obj(10, "sel bang 1 0", 1, 4, [30.0, 550.0, 90.0, 22.0], ["bang", "bang", "bang", ""]),
    _obj(24, "t b b", 1, 2, [30.0, 585.0, 40.0, 22.0], ["bang", "bang"]),
    _obj(19, "t b b", 1, 2, [90.0, 620.0, 40.0, 22.0], ["bang", "bang"]),
    _msg(22, "0", [30.0, 655.0, 30.0, 22.0]),
    _msg(21, "param strike_gate 1", [90.0, 655.0, 120.0, 22.0]),
    _msg(20, "100", [230.0, 655.0, 36.0, 22.0]),
    _obj(25, "i", 2, 1, [300.0, 550.0, 30.0, 22.0], ["int"]),
    _obj(26, "+ 1", 2, 1, [340.0, 580.0, 30.0, 22.0], ["int"]),
    _obj(27, "sel 2", 2, 2, [300.0, 610.0, 40.0, 22.0], ["bang", ""]),
    _msg(23, "param strike_gate 0", [300.0, 640.0, 120.0, 22.0]),
    # the load press: held until the reset has finished (then released through the draw counter)
    _msg(31, "1", [380.0, 380.0, 30.0, 22.0]),
    _obj(28, "spigot", 2, 1, [380.0, 420.0, 50.0, 22.0], [""]),
    _obj(29, "t b b", 1, 2, [380.0, 450.0, 40.0, 22.0], ["bang", "bang"]),
    _msg(30, "0", [420.0, 480.0, 30.0, 22.0]),
]
patcher["raw_lines"] = [
    _line(_IDS["route"], 9, 10, 0),    # route: `strike` / `strike 1` / `strike 0` -> [sel bang 1 0]   (route outlet 9: speed ... gain, lmode = 0..8, strike, reset)
    _line(_IDS["route"], 10, 5, 0),   # route: `reset` -> trigger
    _line(1, 0, 5, 0),                 # reset button -> trigger
    _line(3, 1, 19, 0), _line(3, 0, 22, 0),                        # ubutton: mouse-down -> PRESS, mouse-up -> RELEASE
    _line(10, 0, 24, 0), _line(10, 1, 19, 0), _line(10, 2, 22, 0),    # bare `strike` -> tap, `strike 1` -> PRESS, `strike 0` -> RELEASE
    _line(24, 1, 19, 0), _line(24, 0, 22, 0),                      # tap: PRESS (right, first), then RELEASE
    _line(19, 1, 20, 0), _line(20, 0, 25, 1),                      # PRESS: `100` -> [i] right inlet (cancel a pending release)
    _line(19, 0, 21, 0), _line(21, 0, _IDS["real"], 0),            # PRESS: `param strike_gate 1` -> real
    _line(22, 0, 25, 1),                                           # RELEASE: `0` -> [i] right inlet (start the draw count)
    _line(12, 0, 25, 0), _line(25, 0, 26, 0), _line(26, 0, 25, 1), # draw -> [i] -> +1 -> [i]
    _line(25, 0, 27, 0), _line(27, 0, 23, 0), _line(23, 0, _IDS["real"], 0),    # sel 2 -> `param strike_gate 0` -> real
    _line(6, 0, 20, 0),                                            # loadbang: no pending release at start
    _line(6, 0, 7, 0), _line(7, 0, 5, 0),                          # loadbang -> delay -> reset trigger
    _line(7, 0, 19, 0), _line(7, 0, 31, 0), _line(31, 0, 28, 1),   # delay -> load PRESS, and open the spigot
    _line(15, 0, 28, 0), _line(28, 0, 29, 0),                      # reset done ([sel 2]) -> spigot -> [t b b]
    _line(29, 1, 30, 0), _line(30, 0, 28, 1), _line(29, 0, 22, 0), # right: close the spigot; left: RELEASE (the load press)
    _line(5, 1, 8, 0), _line(8, 0, 13, 1),                         # trigger right -> 0 -> [i] right inlet
    _line(5, 0, 9, 0), _line(9, 0, _IDS["pass"], 0), _line(9, 0, _IDS["real"], 0),   # trigger left -> reset 1 -> pass, real
    _line(12, 0, 13, 0), _line(13, 0, 14, 0), _line(14, 0, 13, 1),    # draw -> [i] -> +1 -> [i]
    _line(13, 0, 15, 0), _line(15, 0, 16, 0), _line(16, 0, _IDS["pass"], 0), _line(16, 0, _IDS["real"], 0),   # sel 2 -> reset 0
]
