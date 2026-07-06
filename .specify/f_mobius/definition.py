# f_mobius patcher definition
# Input to tools/build_patcher.py
# Last updated: 2026-06-15

CODEBOX = """\
Param cx(0.5);
Param cy(0.5);
Param rotate(0.0);
Param zoom(0.5);
Param invert(0.0);
Param bypass(0.0);

TWO_PI = 6.28318530717959;

zx = norm.x - cx;
zy = norm.y - cy;

angle = rotate * TWO_PI;
scale = pow(10.0, (zoom - 0.5) * 5.0);
cos_a = cos(angle);
sin_a = sin(angle);
rot_x = (cos_a * zx - sin_a * zy) * scale;
rot_y = (sin_a * zx + cos_a * zy) * scale;

mag_sq = max(zx*zx + zy*zy, 0.0001);
inv_x = zx / mag_sq;
inv_y = -zy / mag_sq;

out_x = mix(rot_x, inv_x, invert);
out_y = mix(rot_y, inv_y, invert);

uv_x = fract(out_x + cx);
uv_y = fract(out_y + cy);

effect_out = sample(in1, vec(uv_x, uv_y, 0));
out1 = mix(effect_out, sample(in1, norm), bypass);
"""

patcher = {
    "name":        "f_mobius",
    "prefix":      "mobius",
    "object_name": "mobius_pix",
    "title":       "Mobius",
    "archetype":   "processor",

    "presentation_width":  154,
    "presentation_height": 91,

    "params": [
        {"name": "cx",     "type": "float", "min": 0.0, "max": 1.0,  "default": 0.5, "label": "Cx",     "hint": "Transform center X"},
        {"name": "cy",     "type": "float", "min": 0.0, "max": 1.0,  "default": 0.5, "label": "Cy",     "hint": "Transform center Y"},
        {"name": "rotate", "type": "float", "min": 0.0, "max": 1.0,  "default": 0.0, "label": "Rotate", "hint": "Rotation -- full sweep = one revolution"},
        {"name": "zoom",   "type": "float", "min": 0.0, "max": 1.0,  "default": 0.5, "label": "Zoom",   "hint": "Zoom -- 0.5=identity, logarithmic scale (10^((zoom-0.5)*5))"},
        {"name": "invert", "type": "float", "min": 0.0, "max": 10.0, "default": 0.0, "label": "Invert", "hint": "Blend from rotation/zoom toward complex inversion (1/z)"},
        {"name": "bypass", "type": "bypass"},
    ],

    "outlets": [{"comment": "composite"}],

    "codebox": CODEBOX,
}
