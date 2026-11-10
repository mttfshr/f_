"""
f_vf_erode -- definition.py

Ink that moves along a vecfield (narrowed 2026-11-09, Matt, after two live looks: mottle, dropout and the threshold spread are
gone). Patch a vecfield (repulse, optical flow) into the second inlet: Bulge moves the outlines along it, Extent carries ink along
it so it piles up and starves at the slopes of the image, and Travel sets how far for both. Per channel, in frame-height units,
stateless. Spec, plan and tasks: .specify/f_vf_erode/{spec,plan,tasks}.md. Mirror: tests/modules/vf_erode/vf_erode_mirror.py.

Three stages: zap -> bulge -> extent. The source reaches `zap` (the primary); the one outlet comes from `extent`. A pix renders on
its left inlet, so each stage's left inlet is the image, which arrives last; the vecfield and the source are on the right.

Dial ranges and defaults are provisional; the panel layout is the builder's until the docs phase (`G-ui-density`).
"""


def _stage(id_, n_inlets, gen, primary=False):
    return {"id": id_, "name": f"#0_vferode_stage_{id_}", "gen": gen, "n_inlets": n_inlets, "n_outlets": 1,
            "pix_attrs": "@adapt 0 @dim 256 256 @type float32", "primary": primary}


patcher = {
    "name":        "f_vf_erode",
    "prefix":      "vferode",
    "object_name": "#0_vferode_pix",
    "title":       "Erode",
    "signal_type": "tex in/out",
    "archetype":   "processor",

    "bypass_mode":   "param",
    "bypass_target": "extent",

    "presentation_width":  190,
    "presentation_height": 95,

    "render_dim": {
        "width_param":  "width",
        "height_param": "height",
        "param_stages": ["bulge", "extent"],
        "size_stages":  ["zap", "bulge", "extent"],
    },

    "pix_chain": [
        _stage("zap", 1, "codebox_zap.gen", primary=True),
        _stage("bulge", 2, "codebox_bulge.gen"),
        _stage("extent", 3, "codebox_extent.gen"),
    ],

    # [src_id, src_outlet, dst_id, dst_inlet]
    "pix_wires": [
        ["zap", 0, "bulge", 0],
        ["bulge", 0, "extent", 0],
        ["zap", 0, "extent", 2],      # the source, for bypass and alpha
    ],

    "mod_inlets": [
        {"label": "vecfield: the flow that moves the ink (repulse, optical flow). Unconnected, the module passes its input through",
         "state_param": "src_field", "fanout": [["bulge", 1], ["extent", 1]], "state_nodes": ["bulge", "extent"]},
    ],

    "outlets": [{"comment": "texture out"}],
    "outlet_source": {0: ["extent", 0]},

    "params": [
        {"name": "extent", "type": "float", "min": 0.0, "max": 2.0, "default": 0.0, "label": "Extent",
         "pix_target": "extent",
         "hint": "How much ink the field carries: it piles up, denser in its own color, where the flow runs into a slope, and thins where it leaves one. Output is not clamped. PROVISIONAL"},
        {"name": "bulge", "type": "float", "min": 0.0, "max": 2.0, "default": 0.0, "label": "Bulge",
         "pix_target": "bulge",
         "hint": "Moves only the outlines along the field, so edges swell and pinch while flat areas hold still. PROVISIONAL"},
        {"name": "travel", "type": "float", "min": 0.0, "max": 1.0, "default": 0.5, "label": "Travel",
         "pix_target": ["bulge", "extent"],
         "hint": "How far the ink travels, for both Extent and Bulge: 1 is 5% of the frame height at the field's full strength. PROVISIONAL"},
        {"name": "src_field", "type": "internal"},
        {"name": "width", "type": "internal"},
        {"name": "height", "type": "internal"},
        {"name": "bypass", "type": "bypass"},
    ],
}
