"""
f_quasi -- definition.py   (working name `f_quasi`; gate G1 settled 2026-10-26: keep it)

Shepard-zoom quasicrystal generator: five cosine plane waves over seven octaves, the octave weights a Gaussian in
log2 scale, so advancing `zoom` one octave never changes the pattern's character (an endless zoom). A stateless
generator: one pix, three outlets, no feedback.  See .specify/stable/f_quasi/{spec,tasks}.md.

  outlet 1  banded look of the potential (triangle-folded contours, `bands` of them)
  outlet 2  the exact analytic gradient as an f_vecfield, divided by the weighted total frequency so |v| <= 1
            (gate G2: the bounded form ships, with `gain`; a fixed scale is judged in Phase 2)
  outlet 3  the potential P mapped to 0..1

Archetype `dual` (vs_inState on the first inlet, vs_black when nothing is connected; vs_black alone does not trigger the
pix, so a raw `r draw` -> pix cord renders the module every frame with nothing connected, as f_grain does);
the codebox reads the aspect from the internal `width` / `height` Params (render_dim; `dim` reads 1 live).  `src_mode` (vs_inState's flag) is declared and
not read.  Bypass is `bypass_gate` (never the native @bypass): look and scalar black with alpha 1, vecfield neutral.

The clock (T021, G3: frame-based like the other `rate` dials).  `zoom` and `drift` are plain dials (so a mod source or
LFO can drive them); `zoom_rate` (octaves per frame) and `drift_rate` (turns per frame) have no pix cord (pix_wire False)
and feed two accumulators carried in raw boxes:
    [r draw] -> [f] -> [+ rate] -> [expr $f1 - floor($f1)] -> [f] right inlet (store)
                                                           -> [prepend param zoom_clk] -> pix
The wrap is exact for a value already in [0, 1), so rate 0 freezes the phase exactly; the codebox ADDS the phase to the
dial and wraps the sum.  Drift is a phase in turns (the codebox applies it as 2 pi drift 2^i, exactly periodic).
There is no control-rate [wrap] object in Max, hence the expr.

Verification: tests/modules/quasi (mirror, 12 tests), tests/modules/quasi/bench_quasi.py (the codebox on the GPU).
"""
from pathlib import Path

_HERE = Path(__file__).parent

patcher = {
    "name":        "f_quasi",
    "prefix":      "quasi",
    "object_name": "#0_quasi_pix",       # #0_ prefix: per-instance Ob3D name (two live instances must not collide)
    "title":       "Quasi",
    "archetype":   "dual",
    "signal_type": "∇ out",

    # 2026-10-30: `dim` reads 1 inside a live jit.gl.pix, so the aspect cannot come from it.  width / height are
    # internal Params driven from the render size by the builder's `render_dim` key, and the output follows the
    # render size (`@adapt 0`; the first inlet's texture is never read).  pix_attrs replaces pix_type (the builder
    # rejects both); the outlets stay float32.
    "pix_attrs":   "@adapt 0 @dim 256 256 @type float32",
    "render_dim": {
        "width_param":  "width",
        "height_param": "height",
        "param_stages": ["primary"],
        "size_stages":  ["primary"],
    },
    "bypass_mode": "param",             # jsui -> prepend param bypass_gate -> pix (every outlet its neutral)

    "presentation_width":  227,
    "presentation_height": 164,

    "params": [
        {"name": "zoom",       "type": "float", "min": 0.0,   "max": 1.0,   "default": 0.0,   "label": "Zoom",
         "hint": "Pattern scale, cyclic: one full turn is one octave and wraps with no seam. The clock adds to this"},
        {"name": "zoom_rate",  "type": "float", "min": -0.02, "max": 0.02,  "default": 0.002, "label": "Z.rate", "pix_wire": False,
         "hint": "Zoom clock: octaves per frame, either direction. 0 freezes the zoom exactly"},
        {"name": "drift",      "type": "float", "min": 0.0,   "max": 1.0,   "default": 0.0,   "label": "Drift",
         "hint": "Phase of the waves, cyclic: one full turn is the identical frame. The clock adds to this"},
        {"name": "drift_rate", "type": "float", "min": -0.02, "max": 0.02,  "default": 0.001, "label": "D.rate", "pix_wire": False,
         "hint": "Drift clock: turns per frame, either direction. 0 freezes the phase exactly"},
        {"name": "density",    "type": "float", "min": 1.0,   "max": 12.0,  "default": 4.0,   "label": "Dens",
         "hint": "Bands per frame height at the base scale: finer or coarser texture"},
        {"name": "envelope",   "type": "float", "min": 0.25,  "max": 0.7,   "default": 0.5,   "label": "Env",
         "hint": "How many octaves show: low = one scale dominates, high = a wider mix. The top of the range keeps the zoom loop seamless"},
        {"name": "bands",      "type": "float", "min": 1.0,   "max": 12.0,  "default": 5.0,   "label": "Bands",
         "hint": "Contour count in the look outlet"},
        {"name": "angle",      "type": "float", "min": 0.0,   "max": 180.0, "default": 0.0,   "label": "Angle",
         "hint": "Rotates the five wave directions together (degrees)"},
        {"name": "gain",       "type": "float", "min": 0.0,   "max": 8.0,   "default": 1.0,   "label": "Gain",
         "hint": "Strength of the vecfield outlet (unbounded in use: the bounded field only fills part of the range at 1)"},
        {"name": "bypass", "type": "bypass"},

        # Driven by the module itself, never by the route: the clock's phases, vs_inState's flag, the bypass jsui
        {"name": "zoom_clk",    "type": "internal"},
        {"name": "drift_clk",   "type": "internal"},
        {"name": "src_mode",    "type": "internal"},
        {"name": "bypass_gate", "type": "internal"},
        {"name": "width",       "type": "internal"},     # render size, driven by render_dim
        {"name": "height",      "type": "internal"},
    ],

    "outlets": [
        {"comment": "pattern (banded look)"},
        {"comment": "gradient (vecfield)", "signal_type": "float32"},
        {"comment": "potential"},
    ],

    # The benched codebox file, byte for byte (newline="" keeps its endings)
    "codebox": (_HERE / "codebox_quasi.gen").open(newline="").read(),
}


# ---- the clock (raw boxes) -------------------------------------------------------------------------------
# A dial's id is derived from its place among the float / int params (builder: obj-(20 + 3 n)); the single pix is obj-5.
# tests/contracts/test_module_contracts.py and the build check below fail if either assumption stops holding.
_UI = [p["name"] for p in patcher["params"] if p["type"] in ("float", "int")]
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


def _line(src, so, dst, di):
    ref = lambda o: o if isinstance(o, str) else f"obj-raw-{o}"      # int = a raw box, str = a full id
    return {"patchline": {"source": [ref(src), so], "destination": [ref(dst), di]}}


# one shared `r draw` (obj-raw-1); per clock: [f] [+ 0.] [expr] [prepend param X]
_CLOCKS = [("zoom_rate", "zoom_clk", 2), ("drift_rate", "drift_clk", 6)]
patcher["raw_boxes"] = [_obj(1, "r draw", 0, 1, [500.0, 320.0, 50.0, 22.0])]
patcher["raw_lines"] = []
for _k, (_rate, _param, _b) in enumerate(_CLOCKS):
    _x = 500.0 + 130.0 * _k
    patcher["raw_boxes"] += [
        _obj(_b,     "f",                          2, 1, [_x, 360.0, 30.0, 22.0], ["float"]),
        _obj(_b + 1, "+ 0.",                       2, 1, [_x, 400.0, 40.0, 22.0], ["float"]),
        _obj(_b + 2, "expr $f1 - floor($f1)",      1, 1, [_x, 440.0, 120.0, 22.0], ["float"]),
        _obj(_b + 3, f"prepend param {_param}",    1, 1, [_x, 480.0, 120.0, 22.0]),
    ]
    patcher["raw_lines"] += [
        _line(1, 0, _b, 0),                   # frame tick -> [f]
        _line(_b, 0, _b + 1, 0),              # stored phase -> [+ rate]
        _line(_b + 1, 0, _b + 2, 0),          # -> wrap into [0, 1)
        _line(_b + 2, 0, _b, 1),              # store the new phase
        _line(_b + 2, 0, _b + 3, 0),          # and send it
        _line(_b + 3, 0, _PIX, 0),            # prepend param <clk> -> the pix
        _line(_dial(_rate), 0, _b + 1, 1),    # the rate dial -> [+ rate] right inlet
    ]

# Render trigger (2026-10-30).  vs_inState's vs_black fallback does NOT make the pix draw by itself: unconnected, the
# module drew nothing (Matt, live).  `r draw` goes straight to the pix, as f_grain / f_masonry do, so the generator
# renders every frame with nothing on the inlet.  Connected, a texture also triggers the pix: two cheap passes.
patcher["raw_lines"].append(_line(1, 0, _PIX, 0))     # r draw -> the pix
