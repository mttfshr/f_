# f_tf_aniso_blur patcher definition
# Input to build/build_patcher.py
# Spec: .specify/f_tf_aniso_blur/{spec,plan,tasks}.md   Created: 2026-10-17
#
# Single-pix processor (plan ADR-1: one codebox, two texture inlets, no
# pix_chain): decode -> ADR-3 gates -> family (a) kernel -> accumulate ->
# normalize -> out. `driving_inlet` puts the raw tensor on module inlet 0
# (control rides with it, tensormap-style); the source texture is mod_inlet
# 1 on module inlet 1 (the second texture the kernel smooths; control
# messages route to params per the spec's Inlets table).
#
# BYPASS: bypass_mode "param" -> `Param bypass_gate` = EXACT passthrough of
# inlet 1 (this module has no encoding of its own to neutralize: family
# bypass contract "bypassed module is a PASSTHROUGH", not a neutral frame).
#
# Header signal_type "tensor in" reuses the amber `tensor` color added by
# tensormap T030 (SIGNAL_TYPE_COLORS is keyed on the first word only). The
# OUTLET is an ordinary color texture (spec OQ1): no signal-type novelty,
# default outlet wiring is right.
#
# Param names on the wire match the codebox Params exactly (the route token
# IS the param name, glyph's `glyph_scale` precedent); `floor` is renamed
# `floor_pct` inside BOTH the codebox and the param name because it collides
# with the GenExpr `floor()` OPERATOR (skills/jit-gen-codebox, same
# silent-collision class as `mix`/`active`); the UI label stays "Floor".
#
# width/height Params exist because `dim` reads 1 inside live Vsynth
# jit.gl.pix (tensormap T012 finding): they set the one-pixel tap step.
#
# All kernel/gate defaults are PROVISIONAL (spec Parameters table; tier-2
# bench + tier-3 live judgment pending Matt): strength_scale 0.5,
# length 4, width_gate 0.5, floor 0.25. See the codebox header for the
# ADR-2 PROVISIONAL-OPEN gate note.

from pathlib import Path

_HERE = Path(__file__).parent

CODEBOX_DIR = ""  # gen path below is relative to this definition.py's own directory

patcher = {
    "name":        "f_tf_aniso_blur",
    "prefix":      "aniso_blur",
    "object_name": "#0_aniso_blur_pix",
    "title":       "Aniso Blur",
    "signal_type": "T_ in",
    "archetype":   "processor",
    "driving_inlet": True,
    "bypass_mode": "param",

    "presentation_width":  190,
    "presentation_height": 122,

    "codebox": (_HERE / "codebox_aniso.gen").open(newline="").read(),

    "outlets": [
        {"comment": "smoothed source",
         "hint": "The source texture smoothed along the tensor field's "
                 "structure axis (kernel shape and orientation from the "
                 "decoded eigenvalues; isotropic blur wherever the field "
                 "has no direction or the tensor is non-SPD/unconnected -- "
                 "the SPD guard). Unbounded float32 passthrough of a "
                 "weighted mean: values stay within the source's convex "
                 "hull. Bypass = exact passthrough of the source."},
    ],

    "mod_inlets": [
        {"label": "tensor (tensormap outlet 0)", "vs_instate": True},
        {"label": "source (the content to smooth)", "vs_instate": True},
    ],

    # Inlet contract (glyph plan ADR-3 pattern): inlet 0 expects
    # f_tf_tensormap OUTLET 0 exactly -- f_tensor_type.md. Feeding outlet 1
    # (angle-doubled packed) or a vecfield decodes a wrong kernel field;
    # documented, not sniffed. Unconnected tensor (vs_black) -> the SPD
    # guard -> plain isotropic blur of the source (the honest degenerate).
    # Unconnected source -> black output.

    "params": [
        {
            "name": "strength_scale", "type": "float",
            "min": 0.0, "max": 2.0, "default": 0.5,
            "label": "Strength",
            "hint": "Energy-to-length gate: W = min(1, lambda1 * this). "
                    "Must be calibrated TOGETHER with tensormap's `strength` "
                    "(the G-channel trap: the raw tensor's G carries "
                    "Jxy*strength*0.5+0.5 -- the decode `strength` param "
                    "below must match the value tensormap was dialed to). "
                    "PROVISIONAL default 0.5 -- the T010 coupling "
                    "measurement shows W saturates (full length) at "
                    "lambda1 >= 2, typical at strength 100 on noise.",
        },
        {
            "name": "length", "type": "float",
            "min": 0.0, "max": 8.0, "default": 4.0,
            "label": "Length",
            "hint": "Kernel semi-length in pixels along the structure axis. "
                    "0 = no blur at all (identity). Range top 8 = "
                    "TAPS_MAX 49 (1 + 2*8 stations * 3 transverse taps); "
                    "PROVISIONAL -- tier-3 pending. COST SCALES WITH "
                    "TAPS_MAX (the compile-time loop), NOT this dial: "
                    "turning it down saves no frame time.",
        },
        {
            "name": "width_gate", "type": "float",
            "min": 0.0, "max": 1.0, "default": 0.5,
            "label": "Width Gate",
            "hint": "Anisotropy gate: how much coherence the kernel "
                    "transverse width responds to (w = max(floor, 1 - "
                    "coherence * this)). 0 = always circular (anisotropy "
                    "off); 1 = full coherence response. PROVISIONAL (tier-3).",
        },
        {
            "name": "floor_pct", "type": "float",
            "min": 0.0, "max": 1.0, "default": 0.25,
            "label": "Floor",
            "hint": "Width floor: the kernel keeps at least this fraction "
                    "of isotropic smoothing everywhere, even at coherence "
                    "0 (prevents a visible no-blur seam in flat regions). "
                    "1 = fully isotropic everywhere. 0 = no smoothing "
                    "where there is no structure (the painterly look). "
                    "Named floor_pct on the wire (the GenExpr floor() "
                    "operator collision). PROVISIONAL 0.25 (tier-3).",
        },
        {
            "name": "strength", "type": "float",
            "min": 1.0, "max": 1000.0, "default": 100.0,
            "exponent": 4.0,
            "label": "T-Map Strength",
            "hint": "The value tensormap's own `strength` dial is set to: "
                    "the raw tensor's G channel is 0.5-offset encoded with "
                    "that gain, so the decode needs it. Mismatches scale "
                    "the decoded tensor by strength_tm/strength_here and "
                    "thus the kernel length (measured in tasks.md T010). "
                    "PROVISIONAL: OQ3 option (a), documented pairing.",
        },
        {
            "name": "width", "type": "float",
            "min": 64.0, "max": 8192.0, "default": 640.0,
            "widget": "numbox",
            "label": "Width",
            "hint": "Render width in pixels. Set to the real frame width: "
                    "it sets the one-pixel tap step. (Live jit.gl.pix "
                    "cannot read its own size; tensormap T012.)",
        },
        {
            "name": "height", "type": "float",
            "min": 64.0, "max": 8192.0, "default": 480.0,
            "widget": "numbox",
            "label": "Height",
            "hint": "Render height in pixels. Set to the real frame height: "
                    "it sets the vertical tap step.",
        },
        {"name": "bypass", "type": "bypass"},
    ],
}

# Layout: the library's 5-column, 190 px grid (five dials, then a numbox row); the frame was
# 154 x 84 and cropped the right dials and the numbox row.
patcher["overrides"] = {}