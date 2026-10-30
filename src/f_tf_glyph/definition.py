# f_tf_glyph patcher definition
# Input to build/build_patcher.py
# Spec: .specify/f_tf_glyph/{spec,plan,tasks}.md   Created: 2026-10-17
#
# Single-pix processor (plan ADR-1): one stage does cell lookup -> ADR-2
# decode -> ADR-6 gate -> closed-form ellipse draw -> tint. `driving_inlet`
# puts the raw tensor on module inlet 0 (control rides with it, tensormap-
# style); the tint texture is mod_inlet 1 on module inlet 1 (plan ADR-7).
#
# BYPASS: bypass_mode "param" -> `Param bypass_gate` = passthrough of the
# source texture at the current pixel (glyph = passthrough per the family
# contract), NOT the native @bypass.
#
# Header signal_type "tensor in" reuses the amber `tensor` color added by
# tensormap T030 (the color is keyed on the first word only).
#
# Param names on the wire match the codebox Params exactly; `scale` is
# renamed `glyph_scale` inside the codebox because `scale` collides with the
# GenExpr `scale()` operator (same silent-collision class as `mix`/
# `active`, skills/jit-gen-codebox).

from pathlib import Path

_HERE = Path(__file__).parent

CODEBOX_DIR = ""  # gen path below is relative to this definition.py's own directory

patcher = {
    "name":        "f_tf_glyph",
    "prefix":      "glyph",
    "object_name": "#0_glyph_pix",
    "title":       "Glyph",
    "signal_type": "T_ in",
    "archetype":   "processor",
    "driving_inlet": True,
    "bypass_mode": "param",

    "presentation_width":  190,
    "presentation_height": 150,

    "codebox": (_HERE / "codebox_glyph.gen").open(newline="").read(),

    # Render size (2026-10-30, Matt: Width / Height dials removed, output follows the render size): the pix is
    # `@adapt 0`, sized by Vsynth's render size through render_dim, which also drives the internal width / height
    # Params (the clamped-tap texel step; `dim` reads 1 in a live jit.gl.pix). No @type: the glyph keeps its output type.
    "pix_attrs": "@adapt 0 @dim 256 256",
    "render_dim": {
        "width_param":  "width",
        "height_param": "height",
        "param_stages": ["primary"],
        "size_stages":  ["primary"],
    },

    "outlets": [
        {"comment": "glyph composite",
         "hint": "One closed-form ellipse glyph per grid cell over the raw tensor: "
                 "orientation from the decoded axis (along the edge), aspect from the "
                 "eigenvalue ratio, drawn only where trace >= gate. Tinted by the "
                 "source luma at the cell center. Gain-free: sweeping tensormap's "
                 "strength changes nothing here. Bypass = source passthrough."},
    ],

    "mod_inlets": [
        {"label": "tensor (tensormap outlet 0)", "vs_instate": True},
        {"label": "source (tint)", "vs_instate": True},
    ],

    # Inlet contract (plan ADR-3): inlet 0 expects f_tf_tensormap OUTLET 0
    # exactly -- f_tensor_type.md. Feeding outlet 1 (angle-doubled packed)
    # or a vecfield decodes a visibly wrong field; documented, not sniffed.

    "params": [
        {
            "name": "grid", "type": "float",
            "min": 2.0, "max": 256.0, "default": 24.0,
            "label": "Grid",
            "hint": "Cells across (the glyph lattice is grid x grid). The real control: "
                    "24 = coarse debug read, 64+ = dense texture. PROVISIONAL default "
                    "-- live judgment pending (tasks TG020).",
        },
        {
            "name": "glyph_scale", "type": "float",
            "min": 0.0, "max": 2.0, "default": 0.8,
            "widget": "numbox",
            "label": "Scale",
            "hint": "Glyph radius relative to the cell: 1.0 = glyphs touch. "
                    "PROVISIONAL (TG020).",
        },
        {
            "name": "thickness", "type": "float",
            "min": 0.0, "max": 1.0, "default": 0.15,
            "label": "Thickness",
            "hint": "Stroke weight of the ellipse ring, as a fraction of the radius. "
                    "PROVISIONAL (TG020).",
        },
        {
            "name": "softness", "type": "float",
            "min": 0.0, "max": 1.0, "default": 0.1,
            "label": "Softness",
            "hint": "Edge falloff, independent of thickness (f_weave convention). "
                    "PROVISIONAL (TG020).",
        },
        {
            "name": "gate", "type": "float",
            "min": 0.0, "max": 1.0, "default": 0.05,
            "label": "Gate",
            "hint": "Draw threshold on the delivered trace: cells below it stay empty "
                    "(inherits tensormap's eps_trace convention; zero and unconnected "
                    "tensors render empty). PROVISIONAL (TG020).",
        },
        {
            "name": "max_aspect", "type": "float",
            "min": 1.0, "max": 32.0, "default": 8.0,
            "label": "Max Aspect",
            "hint": "Clamp on the ellipse aspect so near-degenerate tensors do not "
                    "draw infinitely thin spikes. PROVISIONAL (TG020).",
        },
        {"name": "width",  "type": "internal"},   # render size, driven by Vsynth (render_dim)
        {"name": "height", "type": "internal"},
        {"name": "bypass", "type": "bypass"},
    ],
}

# Layout: six controls in two rows under the title, on the library's 5-column,
# 190 px grid (the frame was 154 x 84 and cropped the right dials and the second row).
# (2026-10-30: the Width / Height numboxes are gone; the builder lays out the six that remain.)
patcher["overrides"] = {}