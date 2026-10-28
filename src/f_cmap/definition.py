"""
f_cmap -- definition.py   (label CMAP; gate G1 settled 2026-10-27)

Iterated complex-map feedback pull for live input (webgpgpu Example_9, rectangular z^n + w only): each frame the image
is pulled through z' = z^power + w and mixed with the live source.  See .specify/f_cmap/{spec,tasks}.md.

Two jit.gl.pix in one bpatcher, as f_vf_advect (Pattern 1):
  pass_pix  -- holds the previous frame, NaN/Inf-guarded (codebox_cmap_pass.gen)
  state_pix -- primary; in1 = source, in2 = previous frame (codebox_cmap.gen)

The clock (T021): `rate` is turns per frame (signed); it has no pix cord (pix_wire False) and feeds two accumulators:
    theta_clk : [r draw] -> [f] -> [+ rate] -> [expr $f1 - floor($f1)] -> [f] right (store) -> param theta_clk
    phase_clk : the same with rate * sqrt(2)                                                -> param phase_clk
The wrap is exact for a value already in [0, 1), so rate 0 freezes w exactly (the f_quasi clock).

Reset: button / `reset` message / loadbang -> `param reseed 1` for three draw bangs -> `param reseed 0` (f_wc's
counter, a frame count and never a timer); the codebox replaces the history with the source while reseed is 1.
Freeze (header toggle, `freeze_on`) holds the history exactly.  Bypass is `bypass_gate` (never native @bypass).

Control tokens avoid jit.gl.pix attributes (FR-009): the scale dial is `lscale` (Ob3D owns `scale`), the power
dial `pwr`, the bounds menu `edge`.  tests/contracts verifies every token against the pix it drives.
"""

patcher = {
    "name":        "f_cmap",
    "prefix":      "cmap",
    "title":       "CMAP",
    "signal_type": "in/out",

    "presentation_width":  190,
    "presentation_height": 195,

    "archetype":   "processor",
    "bypass_mode": "param",             # jsui -> prepend param bypass_gate -> state pix: a bypassed module is the source

    "pix_chain": [
        {"id": "pass", "name": "#0_cmap_pass", "gen": "codebox_cmap_pass.gen", "n_inlets": 1, "n_outlets": 1,
         "pix_type": "float32", "adapt": True, "primary": False},
        {"id": "state", "name": "#0_cmap_pix", "gen": "codebox_cmap.gen", "n_inlets": 2, "n_outlets": 1,
         "pix_type": "float32", "adapt": True, "primary": True},
    ],
    "pix_wires": [
        ["state", 0, "pass",  0],   # feedback loop
        ["pass",  0, "state", 1],   # previous frame -> in2
    ],

    "params": [
        {"name": "decay",  "type": "float", "min": 0.5, "max": 1.0, "default": 0.97, "label": "Decay",
         "hint": "History gain per frame; 1 = no fade"},
        {"name": "inject", "type": "float", "min": 0.0, "max": 1.0, "default": 0.05, "label": "Inject",
         "hint": "Source weight per frame: 0 = the pure map evolution, 1 = the source; about 0.3 winds the live image through the basin"},
        {"name": "radius", "type": "float", "min": 0.0, "max": 1.75, "default": 0.15, "label": "Radius",
         "hint": "Size of the offset w (the Julia parameter)"},
        {"name": "sweep",  "type": "float", "min": 0.0, "max": 1.75, "default": 0.0, "label": "Sweep",
         "hint": "How far the offset breathes in and out around Radius"},
        {"name": "rate",   "type": "float", "min": -0.01, "max": 0.01, "default": 0.0016, "label": "Rate", "pix_wire": False,
         "hint": "Clock: turns per frame of the offset, either direction. 0 freezes the offset exactly"},
        {"name": "angle",  "type": "float", "min": 0.0, "max": 1.0, "default": 0.0, "label": "Angle",
         "hint": "Direction of the offset, cyclic; the clock adds to this"},
        {"name": "lscale", "type": "float", "min": 0.5, "max": 3.0, "default": 1.75, "label": "Scale",
         "hint": "How much of the complex plane the frame spans: larger = more of the map's folds"},
        {"name": "pwr",    "type": "int", "min": 2, "max": 4, "default": 2, "label": "Power",
         "hint": "Exponent of the map (z squared, cubed or fourth)"},
        {"name": "edge",   "type": "menu", "options": ["Source", "Wrap"], "default": 0, "label": "Bounds",
         "hint": "Where the pull leaves the frame: Source = the live image comes in; Wrap = the previous frame wraps"},
        {"name": "freeze_on", "type": "header_toggle", "min": 0.0, "max": 1.0, "default": 0.0,
         "label": "Freeze", "header_label": "Freeze",
         "hint": "Hold the picture exactly where it is; off resumes from it"},
        {"name": "reset", "type": "raw_ui"},
        {"name": "bypass", "type": "bypass"},

        # Driven by the module itself, never by the route
        {"name": "reseed",      "type": "internal"},
        {"name": "theta_clk",   "type": "internal"},
        {"name": "phase_clk",   "type": "internal"},
        {"name": "bypass_gate", "type": "internal"},
    ],

    "outlets": [{"comment": "image"}],
}


# ---- clock + reset (raw boxes) ---------------------------------------------------------------------------
# Object ids are positional (build/spec.md): the primary is obj-5, the route obj-4, a dial is obj-(20 + 3 n) for its
# place n among the float / int params, the pass stage is the first support id (obj-50 below ten controls).
# tests/modules/cmap/test_cmap_static.py guards these against the built patcher.
_UI = [p["name"] for p in patcher["params"] if p["type"] in ("float", "int")]
_N_CONTROLS = sum(1 for _p in patcher["params"] if _p["type"] in ("float", "int", "menu"))
_N_HEADER = sum(1 for _p in patcher["params"] if _p["type"] == "header_toggle")
_UI_BASE = 20
_PIX = "obj-5"


def _dial(name):
    return f"obj-{_UI_BASE + 3 * _UI.index(name)}"


def _box(i, cls, rect, **kw):
    b = {"id": f"obj-raw-{i}", "maxclass": cls, "patching_rect": rect}
    b.update(kw)
    return {"box": b}


def _obj(i, text, nin, nout, rect, otypes=None):
    return _box(i, "newobj", rect, text=text, numinlets=nin, numoutlets=nout, outlettype=otypes or [""] * nout)


def _msg(i, text, rect):
    return _box(i, "message", rect, text=text, numinlets=2, numoutlets=1, outlettype=[""])


def _line(src, so, dst, di):
    ref = lambda o: o if isinstance(o, str) else f"obj-raw-{o}"      # int = a raw box, str = a full id
    return {"patchline": {"source": [ref(src), so], "destination": [ref(dst), di]}}


patcher["raw_boxes"] = [
    _obj(1, "r draw", 0, 1, [500.0, 320.0, 50.0, 22.0]),
    # theta_clk: f(2) + 0.(3) expr(4) prepend(5)        phase_clk: f(6) + 0.(7) expr(8) prepend(9)      rate * sqrt 2: (10)
    _obj(2, "f", 2, 1, [500.0, 360.0, 30.0, 22.0], ["float"]),
    _obj(3, "+ 0.", 2, 1, [500.0, 400.0, 40.0, 22.0], ["float"]),
    _obj(4, "expr $f1 - floor($f1)", 1, 1, [500.0, 440.0, 120.0, 22.0], ["float"]),
    _obj(5, "prepend param theta_clk", 1, 1, [500.0, 480.0, 130.0, 22.0]),
    _obj(6, "f", 2, 1, [660.0, 360.0, 30.0, 22.0], ["float"]),
    _obj(7, "+ 0.", 2, 1, [660.0, 400.0, 40.0, 22.0], ["float"]),
    _obj(8, "expr $f1 - floor($f1)", 1, 1, [660.0, 440.0, 120.0, 22.0], ["float"]),
    _obj(9, "prepend param phase_clk", 1, 1, [660.0, 480.0, 130.0, 22.0]),
    _obj(10, "* 1.41421356", 2, 1, [740.0, 380.0, 80.0, 22.0], ["float"]),
    # reset: button(11) label(12) loadbang(13) delay(14) trigger(15) msg reseed 1 (16) msg 0 (17) counter i(18) +1 (19) %(20)
    #        sel 2 (21) msg reseed 0 (22)
    _box(11, "button", [90.0, 320.0, 24.0, 24.0], numinlets=1, numoutlets=1, outlettype=["bang"],
         presentation=1, presentation_rect=[8.0, 160.0, 28.0, 28.0], varname="reset_button",
         hint="Re-seed the picture from the live image"),
    _box(12, "comment", [90.0, 346.0, 50.0, 18.0], fontname="Ableton Sans Light", fontsize=9.5,
         numinlets=1, numoutlets=0, presentation=1, presentation_rect=[42.0, 165.0, 44.0, 18.0],
         text="Reset", textjustification=0, varname="lbl_reset"),
    _obj(13, "loadbang", 1, 1, [200.0, 330.0, 60.0, 22.0], ["bang"]),
    _obj(14, "delay 200", 2, 1, [200.0, 355.0, 60.0, 22.0], ["bang"]),
    _obj(15, "t b b", 1, 2, [90.0, 380.0, 40.0, 22.0], ["bang", "bang"]),
    _msg(16, "param reseed 1", [90.0, 420.0, 85.0, 22.0]),
    _msg(17, "0", [200.0, 450.0, 30.0, 22.0]),
    _obj(18, "i", 2, 1, [260.0, 450.0, 30.0, 22.0], ["int"]),
    _obj(19, "+ 1", 2, 1, [300.0, 450.0, 30.0, 22.0], ["int"]),
    _obj(20, "% 1000000", 2, 1, [340.0, 450.0, 60.0, 22.0], ["int"]),
    _obj(21, "sel 3", 2, 2, [260.0, 480.0, 40.0, 22.0], ["bang", ""]),
    _msg(22, "param reseed 0", [260.0, 510.0, 85.0, 22.0]),
]
patcher["raw_lines"] = [
    # the offset clock
    _line(1, 0, 2, 0), _line(2, 0, 3, 0), _line(3, 0, 4, 0), _line(4, 0, 2, 1), _line(4, 0, 5, 0), _line(5, 0, _PIX, 0),
    _line(1, 0, 6, 0), _line(6, 0, 7, 0), _line(7, 0, 8, 0), _line(8, 0, 6, 1), _line(8, 0, 9, 0), _line(9, 0, _PIX, 0),
    _line(_dial("rate"), 0, 3, 1),                         # rate -> theta accumulator
    _line(_dial("rate"), 0, 10, 0), _line(10, 0, 7, 1),    # rate * sqrt 2 -> phase accumulator
    # reset
    _line("obj-4", _N_CONTROLS + _N_HEADER, 15, 0),        # route: `reset` is the last outlet (controls, then the header toggle)
    _line(11, 0, 15, 0),
    _line(13, 0, 14, 0), _line(14, 0, 15, 0),
    _line(15, 1, 16, 0), _line(16, 0, _PIX, 0),            # right: reseed 1 -> primary
    _line(15, 0, 17, 0), _line(17, 0, 18, 1),              # left: 0 -> counter
    _line(1, 0, 18, 0), _line(18, 0, 19, 0), _line(19, 0, 20, 0), _line(20, 0, 18, 1),
    _line(18, 0, 21, 0), _line(21, 0, 22, 0), _line(22, 0, _PIX, 0),
]
