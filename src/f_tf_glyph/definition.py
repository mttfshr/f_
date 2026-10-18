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
# Header signal_type "tensor in" reuses the amber `tensor` colour added by
# tensormap T030 (the colour is keyed on the first word only).
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
    "signal_type": "tensor in",
    "archetype":   "processor",
    "driving_inlet": True,
    "bypass_mode": "param",

    "presentation_width":  154,
    "presentation_height": 84,

    "codebox": (_HERE / "codebox_glyph.gen").open(newline="").read(),

    "outlets": [
        {"comment": "glyph composite",
         "hint": "One closed-form ellipse glyph per grid cell over the raw tensor: "
                 "orientation from the decoded axis (along the edge), aspect from the "
                 "eigenvalue ratio, drawn only where trace >= gate. Tinted by the "
                 "source luma at the cell centre. Gain-free: sweeping tensormap's "
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
                    "-- live judgement pending (tasks TG020).",
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
        {
            "name": "width", "type": "float",
            "min": 64.0, "max": 8192.0, "default": 640.0,
            "widget": "numbox",
            "hint": "Render width in pixels. Set to the real frame width: it sets the "
                    "clamped-tap texel step. (Live jit.gl.pix cannot read its own size, "
                    "so this is exposed for now.)",
            "label": "Width",
        },
        {
            "name": "height", "type": "float",
            "min": 64.0, "max": 8192.0, "default": 480.0,
            "widget": "numbox",
            "hint": "Render height in pixels. Set to the real frame height.",
            "label": "Height",
        },
        {"name": "bypass", "type": "bypass"},
    ],
}

# Layout: six controls in two rows under the title (mirrors tensormap's panel
# proportions: four dials, one numbox pair row).
patcher["overrides"] = {
    "bypass_jsui": {"presentation_rect": [129.0, 5.0, 18.0, 12.0]},
    "signal_type": {"fontsize": 9.5, "presentation_rect": [62.0, 3.0, 60.0, 18.0]},
}