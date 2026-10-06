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

// offset to transformation center
zx = norm.x - cx;
zy = norm.y - cy;

// identity path: rotate + zoom
angle = rotate * TWO_PI;
scale = pow(10.0, (zoom - 0.5) * 5.0);
cos_a = cos(angle);
sin_a = sin(angle);
rot_x = (cos_a * zx - sin_a * zy) * scale;
rot_y = (sin_a * zx + cos_a * zy) * scale;

// inversion path: 1/z = conjugate(z) / |z|^2, singularity guarded
mag_sq = max(zx*zx + zy*zy, 0.0001);
inv_x = zx / mag_sq;
inv_y = -zy / mag_sq;

// blend
out_x = mix(rot_x, inv_x, invert);
out_y = mix(rot_y, inv_y, invert);

// offset back + repeat wrap
uv_x = fract(out_x + cx);
uv_y = fract(out_y + cy);

// sample + bypass
effect_out = sample(in1, vec(uv_x, uv_y, 0));
out1 = mix(effect_out, sample(in1, norm), bypass);"""

patcher = {
    "name":        "f_mobius",
    "prefix":      "mob",
    "object_name": "mob_pix",
    "title":       "Möbius",
    "archetype":   "processor",
    "pix_type":    "char",
    "route_bypass": True,   # the oldest modules route a `bypass 0/1` message to the toggle

    "presentation_width":  185,
    "presentation_height": 90,

    "params": [
        {"name": "cx",     "type": "float", "min": 0.0, "max": 1.0,  "default": 0.5, "label": "cx",     "hint": "cx"},
        {"name": "cy",     "type": "float", "min": 0.0, "max": 1.0,  "default": 0.5, "label": "cy",     "hint": "cy"},
        {"name": "rotate", "type": "float", "min": 0.0, "max": 1.0,  "default": 0.0, "label": "rot",    "hint": "rotate"},
        {"name": "zoom",   "type": "float", "min": 0.0, "max": 1.0,  "default": 0.5, "label": "zoom",  "hint": "zoom"},
        {"name": "invert", "type": "float", "min": 0.0, "max": 10.0, "default": 0.0, "label": "inv",    "hint": "invert"},
        {"name": "bypass", "type": "bypass"},
    ],

    "outlets": [{"comment": "texture"}],

    "codebox": CODEBOX,
}

# BEGIN overrides (build/capture.py rewrites only this block)
patcher["overrides"] = {
    "bypass_jsui": {"presentation_rect": [167.0, 5.0, 18.0, 12.0]},
    "cx.ctl": {"presentation_rect": [8.0, 20.0, 27.0, 43.0]},
    "cx.label": {"presentation_rect": [8.0, 64.0, 36.0, 18.0], "textjustification": None},
    "cy.ctl": {"presentation_rect": [43.0, 20.0, 27.0, 43.0]},
    "cy.label": {"presentation_rect": [43.0, 64.0, 36.0, 18.0], "textjustification": None},
    "invert.ctl": {"presentation_rect": [148.0, 20.0, 27.0, 43.0]},
    "invert.label": {"presentation_rect": [148.0, 64.0, 36.0, 18.0], "textjustification": None},
    "rotate.ctl": {"presentation_rect": [78.0, 20.0, 27.0, 43.0]},
    "rotate.label": {"presentation_rect": [78.0, 64.0, 36.0, 18.0], "textjustification": None},
    "title": {"presentation_rect": [8.0, 5.0, 80.0, 21.0]},
    "zoom.ctl": {"presentation_rect": [113.0, 20.0, 27.0, 43.0]},
    "zoom.label": {"presentation_rect": [113.0, 64.0, 36.0, 18.0], "textjustification": None},
}
# END overrides
