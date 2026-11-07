"""
f_poincare -- definition.py

A texture folded into a fundamental domain of the {p,q} tiling of the Poincare disk: mode A (whole curved tile) and
mode B (the sliver kaleidoscope) in ONE codebox (codebox_poincare.gen), a hyperbolic camera (rot, cam_x, cam_y) and a
rim fade. A texture processor: one inlet, one outlet. The output follows the render size (render_dim: Params `width`
and `height`). Record: .specify/f_poincare/{spec,tasks}.md. Verification: tests/modules/poincare (float64 and float32
mirror, bench_poincare.py GPU vs mirror, bench_poincare_module.py the shipped patcher).

Not exposed as controls (codebox defaults, tasks.md T004/T032): iterations 32 and rim_fade 0.99 (the camera moves the
fade start in by up to 0.04 inside the codebox). p_sides is live in both modes (T005); q_vertex below the hyperbolic
minimum for p_sides is raised by the codebox guard, so the dial can sit anywhere in 3..10. `rot` is in radians.
"""

patcher = {
    "name":               "f_poincare",
    "prefix":             "poinc",
    "title":              "Poincare",
    "signal_type":        "tex in/out",

    "presentation_width":  212,
    "presentation_height": 90,

    "archetype": "processor",
    "bypass_mode": "param",             # jsui -> prepend param bypass_gate -> pix; passes the first inlet through

    "outlets": [{"comment": "texture"}],

    "params": [
        {"name": "fold_mode", "type": "text_button", "options": ["Whole", "Sliver"], "default": 0, "label": "Mode",
         "hint": "Whole: each fold ends in the whole curved tile, the texture sits inside it. Sliver: the kaleidoscope, each fold ends in a thin wedge"},
        {"name": "p_sides", "type": "int", "min": 3, "max": 10, "default": 4, "label": "p", "modmode": 0,
         "hint": "Sides of each tile. Whole and Sliver both take it live"},
        {"name": "q_vertex", "type": "int", "min": 3, "max": 10, "default": 5, "label": "q", "modmode": 0,
         "hint": "Tiles meeting at each vertex. Must satisfy 1/p + 1/q < 1/2; a smaller q is raised to the smallest that does"},
        {"name": "tile_scale", "type": "float", "min": 0.05, "max": 1.0, "default": 0.26, "label": "Scale",
         "hint": "How much of the disk the texture covers. 0.26 shows the texture cleanly at p 4, q 5; the tile's vertex radius (0.4 at p 4, q 5) fills the gaps at its corners"},
        {"name": "cam_x", "type": "float", "min": -0.99, "max": 0.99, "default": 0.0, "label": "Cam x",
         "hint": "Travel through the tiling, sideways. A hyperbolic translation: steps look the same size at every depth"},
        {"name": "cam_y", "type": "float", "min": -0.99, "max": 0.99, "default": 0.0, "label": "Cam y",
         "hint": "Travel through the tiling, up and down. Past 0.99 in length the camera is held at 0.99"},
        {"name": "rot", "type": "float", "min": -3.1416, "max": 3.1416, "default": 0.0, "label": "Rot",
         "hint": "Rotation of the view about the disk's centre, in radians, applied before the camera moves"},
        {"name": "bypass", "type": "bypass"},

        # Driven by the bypass jsui (`prepend param bypass_gate`), never by a dial
        {"name": "bypass_gate", "type": "internal"},
        # Render size, driven by render_dim
        {"name": "width", "type": "internal"},
        {"name": "height", "type": "internal"},
    ],

    "render_dim": {
        "width_param":  "width",
        "height_param": "height",
        "param_stages": ["poinc"],
        "size_stages":  ["poinc"],
    },

    "pix_chain": [
        {"id": "poinc", "name": "#0_poinc_pix", "gen": "codebox_poincare.gen", "n_inlets": 1, "n_outlets": 1,
         "pix_attrs": "@adapt 0 @dim 256 256 @type float32", "primary": True},
    ],
    "pix_wires": [],
}

# Presentation layout (2026-11-07, Matt: the Whole / Sliver switch up in the title bar, p over q with the label to the left of
# the numbox, all four dials in one row). The builder's grid is only a default; overrides replace it.
# BEGIN overrides (build/capture.py rewrites only this block)
patcher["overrides"] = {
    "bypass_jsui": {"presentation_rect": [188.0, 5.0, 18.0, 12.0]},
    "title": {"presentation_rect": [10.5, 0.0, 46.0, 21.0]},
    "fold_mode.ctl": {"presentation_rect": [58.0, 2.0, 52.0, 17.0]},
    "p_sides.label": {"presentation_rect": [4.0, 41.0, 16.0, 15.0]},
    "p_sides.ctl": {"presentation_rect": [22.0, 41.0, 34.0, 15.0]},
    "q_vertex.label": {"presentation_rect": [4.0, 63.0, 16.0, 15.0]},
    "q_vertex.ctl": {"presentation_rect": [22.0, 63.0, 34.0, 15.0]},
    "tile_scale.ctl": {"presentation_rect": [64.0, 38.0, 27.0, 43.0]},
    "tile_scale.label": {"presentation_rect": [52.5, 20.0, 50.0, 18.0]},
    "cam_x.ctl": {"presentation_rect": [101.0, 38.0, 27.0, 43.0]},
    "cam_x.label": {"presentation_rect": [89.5, 20.0, 50.0, 18.0]},
    "cam_y.ctl": {"presentation_rect": [138.0, 38.0, 27.0, 43.0]},
    "cam_y.label": {"presentation_rect": [126.5, 20.0, 50.0, 18.0]},
    "rot.ctl": {"presentation_rect": [175.0, 38.0, 27.0, 43.0]},
    "rot.label": {"presentation_rect": [163.5, 20.0, 50.0, 18.0]},
}
# END overrides
