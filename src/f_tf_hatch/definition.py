# f_tf_hatch patcher definition (v2: streamline renderer)
# Input to build/build_patcher.py
# Spec: .specify/f_tf_hatch/{spec,plan}.md   Created: 2026-10-17   v2: 2026-10-29
#
# ARCHITECTURE NOTE -- primary node vs. real output node
#
# Same shape as f_tf_tensormap (see its definition.py): the tensor texture
# must reach stage_e1 (the primary), but the real outlets come from stage_e3,
# the last node. Both outlets are redirected to e3 via `outlet_source`.
# bypass_mode "param" with bypass_target "e3": the toggle drives
# `Param bypass_gate` in stage e3 only (never the native @bypass, which would
# skip the shader and flip secondary outlets); stages e1/e2 keep running under
# bypass by design (nothing reads their outputs then).
#
# v2 chain: e1 decode + presence -> e2 streamline march (N = 16 per direction,
# one pass, ~1.8 ms at 1080p) -> e3 style + encode. Params reach the stages by
# `pix_target`. Names that differ from the spec's table because GenExpr
# reserves the word: `reach` (spec: length), `line_hard` (spec: line); the
# dials keep the spec's labels.
#
# The module samples only at `norm` for the tensor and with `nearest` at
# computed positions for the march (aux texture is render-sized), so
# width/height params are not needed.

CODEBOX_DIR = ""  # gen paths below are relative to this definition.py's own directory

patcher = {
    "name":        "f_tf_hatch",
    "prefix":      "hatch",
    "object_name": "#0_hatch_pix",
    "title":       "Hatch",
    # Header signal_type: the tensor-family amber "tensor" color. The OUTLETS
    # themselves are ordinary luma/texture renders: not tensor-typed; the
    # per-outlet comments carry the encoding hint so they are never wired as
    # tensor/vecfield.
    "signal_type": "T_ in",
    "archetype":   "processor",
    "bypass_mode": "param",
    "bypass_target": "e3",

    # The render size from Vsynth (build/spec.md "render_dim"): `r dim` -> E2's width/height Params, and
    # `r dim` -> every stage (@adapt 0), so the whole chain renders at the render size, not the tensor's.
    "render_dim": {
        "width_param":  "width",
        "height_param": "height",
        "param_stages": ["e2"],
        "size_stages":  ["e1", "e2", "e3"],
    },

    "presentation_width":  190,
    "presentation_height": 150,

    "pix_chain": [
        {
            "id":        "e1",
            "name":      "#0_hatch_stage_e1",
            "gen":       "codebox_stage_e1.gen",
            "n_inlets":  1,
            "n_outlets": 1,
            "pix_attrs": "@adapt 0 @dim 256 256 @type float32",   # output follows the render size (render_dim)
            "primary":   True,
        },
        {
            "id":        "e2",
            "name":      "#0_hatch_stage_e2",
            "gen":       "codebox_stage_e2.gen",
            "n_inlets":  1,
            "n_outlets": 1,
            "pix_attrs": "@adapt 0 @dim 256 256 @type float32",   # output follows the render size (render_dim)
            "primary":   False,
        },
        {
            "id":        "e3",
            "name":      "#0_hatch_stage_e3",
            "gen":       "codebox_stage_e3.gen",
            "n_inlets":  1,
            "n_outlets": 2,
            "pix_attrs": "@adapt 0 @dim 256 256 @type float32",   # output follows the render size (render_dim)
            "primary":   False,
        },
    ],

    # [src_id, src_outlet, dst_id, dst_inlet]
    "pix_wires": [
        ["e1", 0, "e2", 0],   # (ca, sa, coh, pres) -> streamline march
        ["e2", 0, "e3", 0],   # (raw, pres, 0, 1)   -> style + encode
    ],

    "outlets": [
        {"comment": "streaks",
         "color": [0.55, 0.55, 0.55, 1.0],
         "hint": "Hatch strokes, luma on black (color is downstream's job): strokes follow the tensor's structure axis and lengthen where coherence is high; grain where it is low; nothing below the structure floor. @type float32."},
        {"comment": "streak field",
         "color": [0.55, 0.55, 0.55, 1.0],
         "hint": "The same field without the Line style (soft strokes), for downstream styling or gating. NOT a tensor and not a vecfield."},
    ],

    # Both outlets come from stage e3 (the encode stage), not the primary.
    "outlet_source": {0: ["e3", 0], 1: ["e3", 1]},

    "params": [
        {
            "name": "reach", "type": "float",
            "min": 0.0, "max": 1.0, "default": 0.5,
            "hint": "Stroke length: half-length of the march, 0 to a quarter of the frame height on each side. Strokes only get this long where coherence is high; 0 draws nothing. With very fine Grain at full Length the march can skip noise cells and strokes get gaps. PROVISIONAL.",
            "label": "Length",
            "pix_target": "e2",
        },
        {
            "name": "grain", "type": "float",
            "min": 0.0, "max": 1.0, "default": 0.5,
            "hint": "Feature scale of the noise the strokes are drawn from, log-mapped: low = fine, thin strokes; high = coarse, thick strokes (and fewer of them). PROVISIONAL.",
            "label": "Grain",
            "pix_target": "e2",
        },
        {
            "name": "density", "type": "float",
            "min": 0.0, "max": 1.0, "default": 0.7,
            "hint": "How many strokes: how much of the frame the noise blobs the strokes are drawn from cover (0.25% at 0 to 8% at 1). PROVISIONAL.",
            "label": "Density",
            "pix_target": "e2",
        },
        {
            "name": "contrast", "type": "float",
            "min": 0.0, "max": 1.0, "default": 0.5,
            "hint": "Stroke brightness gain (0.6x at 0 to 2x at 1). PROVISIONAL.",
            "label": "Contrast",
            "pix_target": "e3",
        },
        {
            "name": "line_hard", "type": "float",
            "min": 0.0, "max": 1.0, "default": 0.0,
            "hint": "Stroke style: 0 = soft, 1 = hard engraved lines (thresholded with a soft edge). Outlet 1 stays soft.",
            "label": "Line",
            "pix_target": "e3",
        },
        {
            "name": "structure_floor", "type": "float",
            "min": 0.0, "max": 1.0, "default": 0.1,
            "hint": "Structure floor: where there is too little structure to mark, draw nothing. Reads the tensormap's trace scale (trace x its Strength; strong structure is ~1), squared for finer control at the low end. 0 = marks wherever any structure exists. Not strength-invariant: calibrate with the tensormap's Strength. PROVISIONAL default.",
            "label": "Floor",
            "pix_target": "e1",
        },
        {
            "name": "angle_offset", "type": "float",
            "min": -1.0, "max": 1.0, "default": 0.0,
            "hint": "Rotates the streaks relative to the structure axis: +-1 = +-90 deg (the axis is an unoriented line, so +-90 spans the distinct layouts). Zero keeps strokes along structure.",
            "label": "Offset",
            "pix_target": "e1",
        },
        # Render size, driven by Vsynth through render_dim (never set by hand): `dim` reads 1 in a live
        # jit.gl.pix, so E2 takes its frame size from these two Params.
        {"name": "width", "type": "internal"},
        {"name": "height", "type": "internal"},
        {"name": "bypass", "type": "bypass"},
    ],
}

# Layout: the library's 5-column, 190 px grid (controls run to x ~ 180, two dial rows).
patcher["overrides"] = {}
# END overrides
