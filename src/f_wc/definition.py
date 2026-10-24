"""
f_wc -- definition.py

Wilson-Cowan hallucination-form generator on the GPU: a self-sustaining, noise-driven living
labyrinth (the Ermentrout-Cowan / Michael Rule noise-sustained regime, `.specify/f_wc/`).
A generator with a DRIVE inlet: weak drive = hallucinate (free labyrinth), strong drive = the
scene imprints (normal vision). One luma outlet.
See .specify/f_wc/{spec,tasks}.md. Phase 0 settled the model (gate G1: no four-form selector,
the `texture` dial = the inhibition kernel width steers the grain; G3: raw additive E-only drive).

Stage chain (the f_ks pattern; ONE DFT chain carries BOTH fields, the f_vf_fluid
two-complex-field packing: R,G = Re,Im of E-hat; B,A = Re,Im of I-hat. FR-002):
    hold -> pass (in 1) ; seed -> pass (in 2) ; seed -> nl (in 3)
    pass -> fx -> fy -> spec -> iy -> ix -> nl  ;  pass -> nl (in 2)  ;  drive -> nl (in 4)
                                                                    (nl -> hold feedback)
                                                              nl -> enc (render resolution)
  seed  hash noise (Param salt): R/G = reseed-E/I channels, B/A = per-frame Box-Muller uniforms
  pass  hold last state (R = E, B = I; G = Ve, A = Vi habituation memory, reseeds to 0), or reseed the fields from the noise (Param reseed)
  fx/fy/iy/ix  separable DFT (generated: src/f_wc/gen_dft.py, the shared f_vf_fluid template)
  spec  per-bin kernel gains exp(-sigma^2 k^2 / 2), E pair vs I pair (Param sig_i; FR-010)
  nl    sigmoid coupling + per-frame noise + E-only drive, dt/TE|TI relaxation + containment;
        Ve/Vi relax toward the rates (50/100 frames, Rule Ex. 11) and subtract at depth habit
        (0 = shipped dynamics, G/A pinned to 0) (Param dt, ne, drive_gain, drv_conn, habit; FR-003/G5)
  enc   render-res retinotopic resample + display map + bypass gate (Param sharp, bypass_gate)

The `r draw` bang goes to seed, pass and enc (draw_triggers); it ALSO increments the noise
stage's `salt` every frame (the raw wiring: [r draw] -> counter -> `prepend param salt`),
because WC's per-frame noise is the load-bearing mechanism (T005) -- unlike f_ks, where salt
only advances on reset. The feedback, the state tap and the noise/drive textures arrive on
cold inlets, so the loop advances exactly once per rendered frame.

Controls: `rate` scales the per-frame dt (1.0 = the validated labyrinth regime; no NaN ceiling
exists -- relaxation toward a bounded sigmoid -- so the ceiling is aesthetic, T030).  `texture`
is the grain (sigma_I in pixels, sigma_E slaved at sigma_I/sig_ratio): low = coherent broken
stripes ("stripe glass"), high = disordered labyrinth (the Phase-0 region map).  `aspect`
(G6) is that sig_ratio: the inhibition-to-excitation kernel ratio — 1.3 + fine grain =
hexagons, 1.7-2.0 = hot rolls/labyrinth, past ~2.5 it saturates.  `drive_gain`
is scene strength (a gain-role dial; 0 = free US-1 labyrinth, the unconnected drive inlet is
neutral mid-gray via the vs_inState flag; FR-006/G3).  `energy` is the per-frame noise
amplitude Ne (0-2, default 1.0): the drive-band axis — below ~0.7 the labyrinth freezes out,
above ~1.2 it shimmers hot, and it compensates deep habituation (T052).  `habituation`
(G5/T052) is slow
subtractive fatigue: the Ve/Vi adaptation memory rides the state texture's spare G/A
channels, 0 = free run, higher steadies the field mean against long soak drift (and nudges
the usable drive band upward).  `excite` (G7) adds a shared positive offset inside both
sigmoid inputs (the firing thresholds HE/HI lowered together): + = hotter, clean rolls
near 0.5; - = toward blackout.  `sharp` blends the output map from soft to hard-edged (enc
stage, the f_ks shape).  `zoom` (k_ecc, eccentricity gain), `twist` (k_ang, angular gain --
integer only, fractional values seam the map at theta = pi per T006) and `fovea` (r0, center
magnification) expose the retinotopic map (gate reopened 2026-10-23: T033's no-exposure
reversed by Matt).
  The output size follows the render size
(`r dim` into enc, @adapt 0).  `reset` (a button, a `reset` message or a message on the
control inlet) reseeds both fields from fresh noise; it also fires once on load.  Bypass
follows f_chladni: black, alpha 1, and the solver keeps running underneath.

Verification: tests/modules/wc (mirror, 7 tests) and -- once the Max bench legs are done --
tests/modules/wc/bench_wc.py (GPU vs mirror). Naming is gate G2 (Phase 3): `f_wc` is the
working name.
"""

patcher = {
    "name":               "f_wc",
    "prefix":             "wc",
    "title":              "Wilson-Cowan",
    "signal_type":        "luma out",

    "presentation_width":  247,             # 11 dials on three rows (builder pitch is 5/row) + reset
    "presentation_height": 212,             # row 3 holds Fovea (was 150 at 6 dials)

    "archetype": "source",
    "pix_type":  "float32",

    "outlets": [
        {"comment": "pattern (luma)"},
    ],

    "params": [
        {"name": "rate", "type": "float", "min": 0.0, "max": 1.0, "default": 1.0,
         "label": "Rate", "pix_attr": "dt", "pix_target": "nl",
         "hint": "Time step per frame (1 = the validated labyrinth tempo). No stability ceiling; the top is aesthetic"},
        {"name": "grain", "type": "float", "min": 1.0, "max": 4.0, "default": 1.4,
         "label": "Grain", "pix_attr": "sig_i", "pix_target": "spec",
         "hint": "Grain: inhibition kernel width in pixels. Landmarks: 1.1 broken stripes, 1.4 labyrinth (default), 1.9 coarse"},
        {"name": "aspect", "type": "float", "min": 1.2, "max": 2.2, "default": 1.45,
         "label": "Aspect", "pix_attr": "sig_ratio", "pix_target": "spec",
         "hint": "Inhibition-to-excitation kernel ratio (G6): 1.3 + fine grain = hexagons; 1.45 labyrinth (default); 1.7-2.0 hot rolls; above 2.5 saturates"},
        {"name": "drive_gain", "type": "float", "min": 0.0, "max": 2.0, "default": 0.0,
         "label": "Drive", "pix_target": "nl",
         "hint": "Scene strength: 0 = pure hallucination; ~1.5 = the drive inlet imprints (normal vision)"},
        {"name": "energy", "type": "float", "min": 0.0, "max": 2.0, "default": 1.0,
         "label": "Energy", "pix_attr": "ne", "pix_target": "nl",
         "hint": "Per-frame noise energy (Ne): below ~0.7 the labyrinth freezes out; above ~1.2 it shimmers hot. Compensates deep Habituation"},
        {"name": "habituation", "type": "float", "min": 0.0, "max": 1.5, "default": 0.0,
         "label": "Habituation", "pix_attr": "habit", "pix_target": "nl",
         "hint": "Fatigue: slow negative feedback on the activity (T052/G5). 0 = free run; higher steadies the mean over time"},
        {"name": "sharp", "type": "float", "min": 0.0, "max": 1.0, "default": 0.5,
         "label": "Sharp", "pix_target": "enc",
         "hint": "Edge sharpness: 0 = soft gradients, 1 = hard-edged cells (0.5 keeps the free labyrinth readable over time)"},
        {"name": "excite", "type": "float", "min": -0.3, "max": 0.8, "default": 0.0,
         "label": "Excite", "pix_target": "nl",
         "hint": "Excitability: firing thresholds, E and I together (G7). + = hotter (clean rolls near 0.5); - = toward blackout"},
        {"name": "zoom", "type": "float", "min": 1.0, "max": 16.0, "default": 1.0,
         "label": "Zoom", "pix_attr": "k_ecc", "pix_target": "enc",
         "hint": "Eccentricity gain of the retinotopic map (log-radius zoom). Lower = closer, bigger shapes. 1 = the webgpgpu bare-log corner"},
        {"name": "twist", "type": "int", "min": 1, "max": 8, "default": 1,
         "label": "Twist", "pix_attr": "k_ang", "pix_target": "enc",
         "hint": "Angular gain of the map (spoke fold); integer only -- fractional seams the field. 3 = default (T033 corner 5 = finer spokes)"},
        {"name": "fovea", "type": "float", "min": 0.001, "max": 5.0, "default": 0.003,
         "label": "Fovea", "pix_attr": "r0", "pix_target": "enc",
         "hint": "Foveal radius of the map: smaller = more center magnification. 0.003 = the bare-log webgpgpu corner (untreated center vortex)"},
        {"name": "reset", "type": "raw_ui"},
        {"name": "bypass", "type": "bypass"},

        # Driven by the module's own reset/draw logic (`prepend param ...`), never by the route
        {"name": "reseed", "type": "internal"},
        {"name": "salt", "type": "internal"},
        # Driven by the bypass jsui (`prepend param bypass_gate`)
        {"name": "bypass_gate", "type": "internal"},
        # Driven by the drive vs_inState connection flag (`prepend param drv_conn` -> nl)
        {"name": "drv_conn", "type": "internal"},
    ],

    "inlet_comment": "control",
    "mod_inlets": [
        {
            "label":       "drive in (scene; unconnected = free hallucination)",
            "vs_instate":  True,
            "state_param": "drv_conn",
            "fanout":      [["nl", 3]],        # the drive texture reads at nl in 4
            "state_nodes": ["nl"],             # connection flag -> param drv_conn -> nl
        },
    ],
    "draw_triggers": ["seed", "pass", "enc"],
    "bypass_mode": "param",             # jsui -> prepend param bypass_gate -> enc (the primary)

    "pix_chain": [
        {"id": "hold", "name": "#0_wc_hold", "gen": "pass",              "n_inlets": 1, "n_outlets": 1,
         "pix_attrs": "@adapt 0 @dim 256 256 @type float32", "primary": False},
        {"id": "seed", "name": "#0_wc_seed", "gen": "codebox_seed.gen",  "n_inlets": 1, "n_outlets": 1,
         "pix_attrs": "@adapt 0 @dim 256 256 @type float32", "primary": False},
        {"id": "pass", "name": "#0_wc_pass", "gen": "codebox_pass.gen",  "n_inlets": 3, "n_outlets": 1,
         "pix_attrs": "@adapt 0 @dim 256 256 @type float32", "primary": False},
        {"id": "fx",   "name": "#0_wc_fx",   "gen": "codebox_dft_fx.gen", "n_inlets": 1, "n_outlets": 1,
         "pix_attrs": "@adapt 0 @dim 256 256 @type float32", "primary": False},
        {"id": "fy",   "name": "#0_wc_fy",   "gen": "codebox_dft_fy.gen", "n_inlets": 1, "n_outlets": 1,
         "pix_attrs": "@adapt 0 @dim 256 256 @type float32", "primary": False},
        {"id": "spec", "name": "#0_wc_spec", "gen": "codebox_spec.gen",  "n_inlets": 1, "n_outlets": 1,
         "pix_attrs": "@adapt 0 @dim 256 256 @type float32", "primary": False},
        {"id": "iy",   "name": "#0_wc_iy",   "gen": "codebox_dft_iy.gen", "n_inlets": 1, "n_outlets": 1,
         "pix_attrs": "@adapt 0 @dim 256 256 @type float32", "primary": False},
        {"id": "ix",   "name": "#0_wc_ix",   "gen": "codebox_dft_ix.gen", "n_inlets": 1, "n_outlets": 1,
         "pix_attrs": "@adapt 0 @dim 256 256 @type float32", "primary": False},
        {"id": "nl",   "name": "#0_wc_nl",   "gen": "codebox_nl.gen",    "n_inlets": 4, "n_outlets": 1,
         "pix_attrs": "@adapt 0 @dim 256 256 @type float32", "primary": False},
        {"id": "enc",  "name": "#0_wc_enc",  "gen": "codebox_enc.gen",   "n_inlets": 2, "n_outlets": 1,
         "pix_attrs": "@adapt 0 @type float32", "primary": True},
    ],
    "pix_wires": [
        ["hold", 0, "pass", 1],     # previous state (cold)
        ["seed", 0, "pass", 2],     # reseed channels (cold)
        ["pass", 0, "fx", 0], ["fx", 0, "fy", 0], ["fy", 0, "spec", 0],
        ["spec", 0, "iy", 0], ["iy", 0, "ix", 0], ["ix", 0, "nl", 0],
        ["pass", 0, "nl", 1],       # raw state (cold; same frame as in 1)
        ["seed", 0, "nl", 2],       # per-frame noise uniforms (cold)
        ["nl", 0, "hold", 0],       # feedback edge
        ["nl", 0, "enc", 1],        # state -> encode (cold)
    ],
}

# Codebox Params that are not a UI control: which stage holds them (the internal ones are driven by raw
# boxes through `prepend param <name>`; see the reset logic below and the drive mod_inlet above).
_STAGES_OF = {"reseed": "pass", "salt": "seed", "drv_conn": "nl"}
for _p in patcher["params"]:
    if _p["name"] in _STAGES_OF:
        _p["pix_target"] = _STAGES_OF[_p["name"]]


# ---- reset + salt logic (raw boxes) ---------------------------------------------------------------------
#   button / `reset` message / load --> [t b b]
#       right : `param reseed 1` -> pass       reseed the state (from the current salt's channels)
#       left  : 0 -> [i] right inlet           restart the draw count for the reseed drop
#   [r draw] -> [i] -> [+ 1] -> [i]           the frame counter
#   [i] -> [prepend param salt] -> seed       salt advances EVERY DRAW: WC's per-frame noise is the
#                                              mechanism (T005), unlike f_ks's per-reset counter
#   [i] -> [sel 2] -> `param reseed 0` -> pass
# reseed stays 1 for three draw bangs (never a timer): if rendering is not running yet the reseed waits,
# and at least two rendered frames see it.  Object ids: pass obj-57, seed obj-56 (chain order, build/spec.md;
# positional ids -- they shift when a UI box is added; see T030's stale-id trap).
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
    # render size: the vs_mixer_3 convention (@adapt 0, `r dim` -> the pix); the message is "dim W H"
    _obj(15, "r dim", 0, 1, [330.0, 320.0, 40.0, 22.0]),
    _box(1, "button", [90.0, 320.0, 24.0, 24.0], numinlets=1, numoutlets=1, outlettype=["bang"],
         presentation=1, presentation_rect=[227.0, 46.0, 28.0, 28.0], varname="reset_button",
         hint="Reseed the fields from fresh noise"),
    _box(2, "comment", [90.0, 346.0, 50.0, 18.0], fontname="Ableton Sans Light", fontsize=9.5,
         numinlets=1, numoutlets=0, presentation=1, presentation_rect=[216.0, 24.0, 50.0, 18.0],
         text="Reset", textjustification=1, varname="lbl_reset"),
    _obj(3, "t b b", 1, 2, [90.0, 380.0, 40.0, 22.0], ["bang", "bang"]),
    _obj(4, "loadbang", 1, 1, [200.0, 330.0, 60.0, 22.0], ["bang"]),
    _obj(5, "delay 200", 2, 1, [200.0, 355.0, 60.0, 22.0], ["bang"]),
    _msg(7, "param reseed 1", [90.0, 420.0, 80.0, 22.0]),
    _obj(10, "r draw", 0, 1, [260.0, 420.0, 50.0, 22.0]),
    _obj(11, "i", 2, 1, [260.0, 450.0, 30.0, 22.0], ["int"]),
    _msg(6, "0", [200.0, 450.0, 30.0, 22.0]),
    _obj(12, "+ 1", 2, 1, [300.0, 480.0, 30.0, 22.0], ["int"]),
    _obj(13, "sel 2", 2, 2, [260.0, 480.0, 40.0, 22.0], ["bang", ""]),
    _msg(14, "param reseed 0", [260.0, 510.0, 85.0, 22.0]),
    _obj(9, "prepend param salt", 1, 1, [30.0, 480.0, 110.0, 22.0]),
]
patcher["raw_lines"] = [
    _line(15, 0, "obj-5", 0),        # r dim -> enc: the output follows the render size
    _line("obj-4", 11, 3, 0),        # route: `reset` -> trigger   (route outlet 11 after the 11 dials)
    _line(1, 0, 3, 0),               # button -> trigger
    _line(4, 0, 5, 0), _line(5, 0, 3, 0),     # loadbang -> delay -> trigger
    _line(3, 0, 7, 0), _line(7, 0, "obj-57", 0),    # trigger right -> reseed 1 -> pass
    _line(3, 1, 6, 0), _line(6, 0, 11, 1),    # trigger left -> 0 -> [i] right inlet (restart count)
    _line(10, 0, 11, 0), _line(11, 0, 12, 0), _line(12, 0, 11, 1),    # draw -> [i] -> +1 -> [i]
    _line(11, 0, 9, 0), _line(9, 0, "obj-56", 0),   # [i] -> salt -> seed (EVERY DRAW: the mechanism)
    _line(11, 0, 13, 0), _line(13, 0, 14, 0), _line(14, 0, "obj-57", 0),   # sel 2 -> reseed 0 -> pass
]
