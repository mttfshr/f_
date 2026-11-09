"""
f_ink -- definition.py

The body of ink on paper, as operators on any texture: spread (dot gain), edge pooling, mottle and dropout, per channel,
in frame-height units, stateless. Spec, plan and tasks: .specify/f_ink/{spec,plan,tasks}.md. Mirror:
tests/modules/ink/ink_mirror.py. P1 only so far: flecks, banding, channel gains and the two driver inlets are T025-T027.

Eight stages, in the fixed order of FR-008, each one codebox:
    zap -> blur_h -> blur_v -> thresh -> pool_h -> pool_v -> pool -> fx_b

The source texture reaches `zap` (the primary); the one outlet comes from `fx_b`. The zapped source also goes to fx_b's
second inlet (bypass and alpha), and S goes to pool's second inlet. A pix renders on its left inlet, so each two-input
stage takes on the left the path that arrives last. The texture names do not change frame to frame, so a right inlet
reads the current contents whichever cord fires first (inferred from how the chain modules work; T024 checks it).

Dial ranges and defaults are provisional (T032); the panel layout is the builder's until T040 (`G-ui-density`).
"""

SRC = "/Users/matt/Github/f_/src/f_ink/"
SPREAD_CAP_H = "7.0 / 1080.0"       # spread = 1 in frame heights: 7 texels at 1080 (Matt, 2026-11-08)

_BLUR = open(SRC + "codebox_blur.gen").read()
for _marker in ("Param radius(0.0);", "Param axis(0.0);"):
    assert _BLUR.count(_marker) == 1, _marker


def _blur(axis, role):
    """The blur template for one stage. Every Param left in a shipped stage has a driver (the contract test fails others)."""
    if role == "spread":
        param, radius = "Param spread(0.0);", f"spread * {SPREAD_CAP_H}"
    else:
        param, radius = "Param pool_width(0.005);", "pool_width"
    return (_BLUR.replace("Param radius(0.0);", param)
                 .replace("Param axis(0.0);", f"axis = {axis:.1f};\nradius = {radius};"))


def _stage(id_, n_inlets, gen=None, code=None, primary=False):
    node = {"id": id_, "name": f"#0_ink_stage_{id_}", "n_inlets": n_inlets, "n_outlets": 1,
            "pix_attrs": "@adapt 0 @dim 256 256 @type float32", "primary": primary}
    if gen:
        node["gen"] = gen
    else:
        node["gen_code"] = code
    return node


patcher = {
    "name":        "f_ink",
    "prefix":      "ink",
    "object_name": "#0_ink_pix",
    "title":       "Ink",
    "signal_type": "tex in/out",
    "archetype":   "processor",

    "bypass_mode":   "param",
    "bypass_target": "fx_b",

    "presentation_width":  190,
    "presentation_height": 185,

    "render_dim": {
        "width_param":  "width",
        "height_param": "height",
        "param_stages": ["blur_h", "blur_v", "pool_h", "pool_v", "fx_b"],
        "size_stages":  ["zap", "blur_h", "blur_v", "thresh", "pool_h", "pool_v", "pool", "fx_b"],
    },

    "pix_chain": [
        _stage("zap", 1, gen="codebox_zap.gen", primary=True),
        _stage("blur_h", 1, code=_blur(0, "spread")),
        _stage("blur_v", 1, code=_blur(1, "spread")),
        _stage("thresh", 1, gen="codebox_thresh.gen"),
        _stage("pool_h", 1, code=_blur(0, "pool")),
        _stage("pool_v", 1, code=_blur(1, "pool")),
        _stage("pool", 2, gen="codebox_pool.gen"),
        _stage("fx_b", 2, gen="codebox_fx_b.gen"),
    ],

    # [src_id, src_outlet, dst_id, dst_inlet]
    "pix_wires": [
        ["zap", 0, "blur_h", 0],
        ["blur_h", 0, "blur_v", 0],
        ["blur_v", 0, "thresh", 0],
        ["thresh", 0, "pool_h", 0],
        ["pool_h", 0, "pool_v", 0],
        ["pool_v", 0, "pool", 0],     # Bp, the path that arrives last, on the left
        ["thresh", 0, "pool", 1],     # S
        ["pool", 0, "fx_b", 0],
        ["zap", 0, "fx_b", 1],        # the source, for bypass and alpha
    ],

    "outlets": [{"comment": "texture out"}],
    "outlet_source": {0: ["fx_b", 0]},

    "params": [
        {"name": "spread", "type": "float", "min": 0.0, "max": 1.0, "default": 0.0, "label": "Spread",
         "pix_target": ["blur_h", "blur_v", "thresh"],
         "hint": "Ink gain: blurs each channel, then Snap hardens it back into a mark. 1 reaches 7 texels at 1080; the reach is capped there, so above 1080 it shrinks with the frame. PROVISIONAL"},
        {"name": "bias", "type": "float", "min": -1.0, "max": 1.0, "default": 0.0, "label": "Bias",
         "pix_target": "thresh",
         "hint": "After the blur: positive fattens marks, negative thins them. Needs Spread and Snap above 0. PROVISIONAL"},
        {"name": "snap", "type": "float", "min": 0.0, "max": 1.0, "default": 1.0, "label": "Snap",
         "pix_target": "thresh",
         "hint": "How much the blur hardens back into a mark. 0 is a plain blur that keeps continuous tone; 1 posterizes continuous tone as Spread rises. PROVISIONAL"},
        {"name": "soften", "type": "float", "min": 0.0, "max": 1.0, "default": 0.2, "label": "Soften",
         "pix_target": "thresh",
         "hint": "Edge softness of the hardened mark. PROVISIONAL"},
        {"name": "edge_pool", "type": "float", "min": 0.0, "max": 1.0, "default": 0.0, "label": "Edge Pool",
         "pix_target": "pool",
         "hint": "Ink collects at the edges of marks: a denser rim, up to twice the mark's value at 1. Flat areas stay as they are. Output is not clamped"},
        {"name": "pool_width", "type": "float", "min": 0.0, "max": 0.013, "default": 0.005, "label": "Pool W",
         "pix_target": ["pool_h", "pool_v"],
         "hint": "Width of the Edge Pool rim, in frame heights. It shares the 7-texel reach of the blur. PROVISIONAL"},
        {"name": "mottle", "type": "float", "min": 0.0, "max": 1.0, "default": 0.0, "label": "Mottle",
         "pix_target": "fx_b",
         "hint": "Uneven density in blotches. It scales the ink that is there, so black stays black"},
        {"name": "mottle_scale", "type": "float", "min": 0.01, "max": 0.5, "default": 0.15, "label": "Mottle Sz",
         "pix_target": "fx_b",
         "hint": "Blotch size, in frame heights. PROVISIONAL"},
        {"name": "dropout", "type": "float", "min": 0.0, "max": 1.0, "default": 0.0, "label": "Dropout",
         "pix_target": "fx_b",
         "hint": "Ink fails to take on the paper's tooth: pinholes and skips, lighter values first, solids last"},
        {"name": "tooth_scale", "type": "float", "min": 0.001, "max": 0.02, "default": 0.004, "label": "Tooth Sz",
         "pix_target": "fx_b",
         "hint": "Grain of the paper, in frame heights. PROVISIONAL"},
        {"name": "seed", "type": "int", "min": 0, "max": 999, "default": 1, "label": "Seed",
         "pix_target": "fx_b",
         "hint": "Picks the mottle and tooth patterns. They are fixed to the frame and do not move"},
        {"name": "width", "type": "internal"},
        {"name": "height", "type": "internal"},
        {"name": "bypass", "type": "bypass"},
    ],
}
