"""definition.py -- f_formconstants: the render-resolution Wilson-Cowan labyrinth.

Sibling of f_wc (.specify/f_formconstants/spec.md): the SAME Wilson-Cowan model class
(per-frame-noise-driven E/I fields with habituation, Example-10 retinotopic display
stage), but built on the webgpgpu WC_Example_10_fullscreen pipeline: the solver grid IS
the render grid (`r dim` resizes every stage; no fixed-size solver texture), the
coupling convolution is a real-space separable Gaussian blur (no DFT chain anywhere in
this module -- a separate module decision from f_wc's spectral chain, and the reason
this module needs no reconstruction filter downstream), and the state is float32 end
to end (the source demo's 8-bit EncodeFloat quantization is deliberately NOT carried:
it is that page's sustain mechanism, dead weight for us -- Phase 0 T002).

The constants are the measured sustaining corner (Phase 0 T002/T003, G0): Psychedelic
couplings (16.1/14.5/13.7/13, HE 3.1, HI 3.5, TE 4, TI 12.5), energy 0.75,
HABITUATION 0.9 and load-bearing (without it the field saturates by ~3k frames -- G1),
sigma_I clamped to the steady band 0.75..1.4 screen px (the `grain` dial maps to
sigma_frac and the codebox clamps per frame; pattern features are pixel-scale by
design, spec NF-005). The Example-10 constants (the webgpgpu *flicker* preset) measured
dead at float32.

Layout (the f_wc feedback chain pattern, T011):

    hold -> pass (in 1) ; seed -> pass (in 2) ; seed -> nl (in 3)
                                                                      (nl -> hold feedback)
    pass -> blur_x -> blur_y -> nl (in 1) ; pass -> nl (in 2) ; nl -> enc (in 2)
    pass  hold last state (R = E, G = I; B = Ve, A = Vi habituation memory, reseeds to 0), or reseed
          the fields from the noise (Param reseed)
    seed  hash noise: seed channels (R = E, G = I; used only by the reseed path in pass) + raw uniforms
          (B, A; the per-frame noise source, Box-Mullered in nl -- load-bearing, T002)
    blur_x / blur_y
          separable Gaussian coupling (FR-002): R (E) blurred at sigma_E, G (I) at sigma_I,
          radius ceil(3*sigma), wrap; sigma_px = clamp(grain*min(dim), 0.75, 1.4), sigma_E =
          sigma_I / sig_ratio; the exact discrete kernel the mirror asserts
    nl    the settled model: E += (F(16.1*cE - aie*cI - 3.1 + excite - habit*Ve
                                     + ne*N + drive_gain*(scene - 0.5)) - E) * dt/4
          I += (F(13.7*cE - aii*cI - 3.5 + excite - habit*Vi + ne*N) - I) * dt/12.5
          Ve += (E - Ve) * dt/50 ; Vi += (I - Vi) * dt/100
          with the drive inlet reading E-only (G3), the noise N fresh per frame (salt increments
          every draw), and habit = 0 pinning the carry channels at exactly 0
    enc   inverse retinotopic resample (u, v) = (k_ecc*log(1 + sqrt(r^2 + r_soft^2)/r0),
          k_ang*theta): manual bilinear WITH WRAP (state res == render res; the f_wc CR
          sampler exists only to hide 256^2-quantized contours, which this module does not
          have). Contrast + sharp display map, bypass_gate black

The drive inlet is optional (unconnected = free hallucination, FR-006), routed through a
vs_inState so the patcher can set drv_conn = 0 (zero net drive for free). One luma outlet.

Verification: tests/modules/formconstants (mirror, 10 tests) and -- once the Max bench legs
are done -- tests/modules/formconstants/bench_formconstants.py (GPU vs mirror).
"""

patcher = {
    "name":               "f_formconstants",
    "prefix":             "fc",
    "title":              "Form Constants",
    "signal_type":        "luma out",

    "presentation_width":  247,             # 12 dials on three rows (builder pitch is 5/row) + reset
    "presentation_height": 212,             # row 3 holds Fovea (was 150 at 6 dials)

    "archetype": "source",
    "pix_type":  "float32",

    "outlets": [
        {"comment": "pattern (luma)"},
    ],

    "params": [
        {"name": "rate", "type": "float", "min": 0.0, "max": 1.0, "default": 1.0,
         "label": "Rate", "pix_attr": "dt", "pix_target": "nl",
         "hint": "Time step per frame (1 = the validated tempo). No stability ceiling; the top is aesthetic"},
        {"name": "grain", "type": "float", "min": 0.0003, "max": 0.003, "default": 0.0008,
         "label": "Grain", "pix_target": ["blurx", "blury"],
         "hint": "Texture scale: sigma as a fraction of frame height, clamped to the sustaining band 0.75-1.4 screen px (T003). Low = fine silk; high ends pulse and die"},
        {"name": "aspect", "type": "float", "min": 1.2, "max": 2.2, "default": 1.45,
         "label": "Aspect", "pix_attr": "sig_ratio", "pix_target": ["blurx", "blury"],
         "hint": "Inhibition-to-excitation kernel ratio (f_wc G6 semantics): steers ordering. 1.45 default"},
        {"name": "drive_gain", "type": "float", "min": 0.0, "max": 2.0, "default": 0.0,
         "label": "Drive", "pix_target": "nl",
         "hint": "Scene strength: 0 = pure hallucination; ~1.5 = the drive inlet imprints (normal vision)"},
        {"name": "energy", "type": "float", "min": 0.0, "max": 2.0, "default": 0.75,
         "label": "Energy", "pix_attr": "ne", "pix_target": "nl",
         "hint": "Per-frame noise energy (Ne, load-bearing: T002). 0.75 default; the sustain axis with Habituation"},
        {"name": "habituation", "type": "float", "min": 0.0, "max": 2.0, "default": 0.9,
         "label": "Habituation", "pix_attr": "habit", "pix_target": "nl",
         "hint": "Fatigue: slow negative feedback (load-bearing at fine grain: without it the field saturates by ~3k frames). 0.9 default = steady web; ~0.2 = pulsing family"},
        {"name": "sharp", "type": "float", "min": 0.0, "max": 1.0, "default": 0.5,
         "label": "Sharp", "pix_target": "enc",
         "hint": "Edge sharpness: 0 = soft gradients, 1 = hard-edged cells. The web stays silky at any setting -- the state is render-resolution"},
        {"name": "excite", "type": "float", "min": -0.3, "max": 0.8, "default": 0.0,
         "label": "Excite", "pix_target": "nl",
         "hint": "Excitability: firing thresholds, E and I together (f_wc G7). + = hotter; - = toward blackout; breathes the web (the source page's square wave, as a gesture)"},
        {"name": "zoom", "type": "float", "min": 1.0, "max": 16.0, "default": 5.0,
         "label": "Zoom", "pix_attr": "k_ecc", "pix_target": "enc",
         "hint": "Eccentricity gain of the retinotopic map (log-radius zoom). 5 = the close corner from the stills; 1 = the webgpgpu bare-log corner"},
        {"name": "twist", "type": "int", "min": 1, "max": 8, "default": 3,
         "label": "Twist", "pix_attr": "k_ang", "pix_target": "enc",
         "hint": "Angular gain of the map (spoke fold); integer only -- fractional seams the field. 3 = default"},
        {"name": "fovea", "type": "float", "min": 0.001, "max": 5.0, "default": 1.0,
         "label": "Fovea", "pix_attr": "r0", "pix_target": "enc",
         "hint": "Foveal radius of the map: smaller = more center magnification. 1.0 = the close corner (the bare-log 0.003 vortex is an alias at this scale)"},
        {"name": "contrast", "type": "float", "min": 0.5, "max": 8.0, "default": 1.0,
         "label": "Contrast", "pix_target": "enc",
         "hint": "Display stretch about mid-gray, before the Sharp curve (f_wc G8a). 1 = neutral"},
        {"name": "reset", "type": "raw_ui"},
        {"name": "bypass", "type": "bypass"},

        # Driven by the module's own reset/draw logic (`prepend param ...`), never by the route
        {"name": "reseed", "type": "internal"},
        {"name": "salt", "type": "internal"},
        # Driven by the bypass jsui (`prepend param bypass_gate`)
        {"name": "bypass_gate", "type": "internal"},
        # Driven by the drive vs_inState connection flag (`prepend param drv_conn` -> nl)
        {"name": "drv_conn", "type": "internal"},
        # Driven by the raw `r dim` unpack (`prepend param sw/sh`) -> seed + enc:
        # the STATE size, explicit per the jit-gen-codebox rule (`dim` is not an
        # input texture's size; 2026-10-24 solid-flicker debug)
        {"name": "sw", "type": "internal"},
        {"name": "sh", "type": "internal"},
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
        {"id": "hold",  "name": "#0_fc_hold",  "gen": "pass",               "n_inlets": 1, "n_outlets": 1,
         "pix_attrs": "@adapt 0 @dim 256 256 @type float32", "primary": False},
        {"id": "seed",  "name": "#0_fc_seed",  "gen": "codebox_seed.gen",   "n_inlets": 1, "n_outlets": 1,
         "pix_attrs": "@adapt 0 @dim 256 256 @type float32", "primary": False},
        {"id": "pass",  "name": "#0_fc_pass",  "gen": "codebox_pass.gen",   "n_inlets": 3, "n_outlets": 1,
         "pix_attrs": "@adapt 0 @dim 256 256 @type float32", "primary": False},
        {"id": "blurx", "name": "#0_fc_blurx", "gen": "codebox_blur_x.gen", "n_inlets": 1, "n_outlets": 1,
         "pix_attrs": "@adapt 0 @dim 256 256 @type float32", "primary": False},
        {"id": "blury", "name": "#0_fc_blury", "gen": "codebox_blur_y.gen", "n_inlets": 1, "n_outlets": 1,
         "pix_attrs": "@adapt 0 @dim 256 256 @type float32", "primary": False},
        {"id": "nl",    "name": "#0_fc_nl",    "gen": "codebox_nl.gen",     "n_inlets": 4, "n_outlets": 1,
         "pix_attrs": "@adapt 0 @dim 256 256 @type float32", "primary": False},
        {"id": "enc",   "name": "#0_fc_enc",   "gen": "codebox_enc.gen",    "n_inlets": 2, "n_outlets": 1,
         "pix_attrs": "@adapt 0 @dim 256 256 @type float32", "primary": True},
    ],
    "pix_wires": [
        ["hold", 0, "pass", 1],     # previous state (cold)
        ["seed", 0, "pass", 2],     # reseed channels (cold)
        ["pass", 0, "blurx", 0], ["blurx", 0, "blury", 0], ["blury", 0, "nl", 0],
        ["pass", 0, "nl", 1],       # raw state (cold; same frame as the convolved input)
        ["seed", 0, "nl", 2],       # per-frame noise uniforms (cold)
        ["nl", 0, "hold", 0],       # feedback edge
        ["nl", 0, "enc", 1],        # state -> encode (cold)
    ],
}

# Codebox Params that are not a UI control: which stage holds them (the internal ones are driven by raw
# boxes through `prepend param <name>`; see the reset logic below and the drive mod_inlet above).
_STAGES_OF = {"reseed": "pass", "salt": "seed", "drv_conn": "nl",
              "sw": ["seed", "enc"], "sh": ["seed", "enc"]}
for _p in patcher["params"]:
    if _p["name"] in _STAGES_OF:
        _p["pix_target"] = _STAGES_OF[_p["name"]]


# ---- reset + salt logic + RESIZE RESEED (raw boxes) -------------------------------------------------------
#   button / `reset` message / loadbang / `r dim` (a RESIZE) --> [delay 200] --> [t b b]
#       right : `param reseed 1` -> pass       reseed the state (from the current salt's channels)
#       left  : 0 -> [i] right inlet           restart the draw count for the reseed drop
#   [r draw] -> [i] -> [+ 1] -> [i]           the frame counter
#   [i] -> [prepend param salt] -> seed       salt advances EVERY DRAW: the per-frame noise is the
#                                              mechanism (T002), as in f_wc
#   [i] -> [sel 2] -> `param reseed 0` -> pass
# reseed stays 1 for three draw bangs (never a timer): if rendering is not running yet the reseed waits,
# and at least two rendered frames see it.  The RESIZE RESEED (T013, the deliberate seam over the size
# realloc glitch): a `dim W H` broadcast is fanned to EVERY stage (the vs_mixer_3 convention; the stages
# are @adapt 0 and follow it -- solver res = render res), AND it bangs the same reseed trigger, so the
# picture re-forms from fresh noise ~200 ms after a resize instead of interpolating garbage.
# Object ids (positional -- they shift when a UI box is added; see f_wc T030's stale-id trap):
# support stages start at obj-{max(50, 20 + n_ui_params*3 + 2)} = obj-58 at 12 dials
# (build/spec.md): hold = obj-58, seed = obj-59, pass = obj-60, blurx = obj-61, blury = obj-62,
# nl = obj-63; enc (primary) = obj-5. Route tokens are the 12 dials in order, then reset.
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
    # render size: fan `dim W H` to EVERY stage (solver res = render res, T011) + the resize reseed
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
    # dim W H -> the state size as Params for the stages whose inlets do not
    # carry the state texture (seed, enc): jit-gen-codebox rule — `dim` is not
    # an input texture's size (2026-10-24 solid-flicker debug)
    _obj(16, "route dim", 1, 2, [380.0, 320.0, 60.0, 22.0], ["", ""]),
    _obj(17, "unpack", 1, 2, [380.0, 350.0, 50.0, 22.0], ["int", "int"]),
    _obj(18, "prepend param sw", 1, 1, [330.0, 380.0, 105.0, 22.0]),
    _obj(19, "prepend param sh", 1, 1, [440.0, 380.0, 105.0, 22.0]),
]
patcher["raw_lines"] = [
    _line(15, 0, "obj-5", 0),        # r dim -> enc: the output follows the render size
    _line(15, 0, "obj-58", 0),       # r dim -> the solver stages: solver res = render res (T011)
    _line(15, 0, "obj-59", 0),
    _line(15, 0, "obj-60", 0),
    _line(15, 0, "obj-61", 0),
    _line(15, 0, "obj-62", 0),
    _line(15, 0, "obj-63", 0),
    _line(15, 0, 5, 0),              # r dim -> delay -> reseed: the deliberate resize seam (T013)
    _line("obj-4", 12, 3, 0),        # route: `reset` -> trigger   (route outlet 12 after the 12 dials)
    _line(1, 0, 3, 0),               # button -> trigger
    _line(4, 0, 5, 0), _line(5, 0, 3, 0),     # loadbang -> delay -> trigger
    _line(3, 0, 7, 0), _line(7, 0, "obj-60", 0),    # trigger right -> reseed 1 -> pass
    _line(3, 1, 6, 0), _line(6, 0, 11, 1),    # trigger left -> 0 -> [i] right inlet (restart count)
    _line(10, 0, 11, 0), _line(11, 0, 12, 0), _line(12, 0, 11, 1),    # draw -> [i] -> +1 -> [i]
    _line(15, 0, 16, 0),             # r dim -> route dim
    _line(16, 0, 17, 0),             # -> unpack W H
    _line(17, 0, 18, 0), _line(17, 1, 19, 0),   # W -> param sw, H -> param sh
    _line(18, 0, "obj-59", 0), _line(19, 0, "obj-59", 0),   # -> seed
    _line(18, 0, "obj-5", 0), _line(19, 0, "obj-5", 0),     # -> enc
    _line(11, 0, 9, 0), _line(9, 0, "obj-59", 0),   # [i] -> salt -> seed (EVERY DRAW: the mechanism)
    _line(11, 0, 13, 0), _line(13, 0, 14, 0), _line(14, 0, "obj-60", 0),   # sel 2 -> reseed 0 -> pass
]
