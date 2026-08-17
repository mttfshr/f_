# f_ngon patcher definition
# Input to tools/build_patcher.py
# Last updated: 2026-07-23
# Mechanism confirmed in ~/Vsynth/patterns/ngon-scratch.maxpat (forked from
# f_poincare Phase 1 kaleidoscope diagnostic work). See ideas/f_ngon.md.

CODEBOX = """\
Param n_mirrors(6.0);
Param rotation(0.0);
Param scale(1.0);
Param bypass(0.0);

theta = pi / n_mirrors;

zx0 = snorm.x * (1.0/scale);
zy0 = snorm.y * (1.0/scale);
cr = cos(0.0-rotation);
sr = sin(0.0-rotation);
zx = zx0*cr - zy0*sr;
zy = zx0*sr + zy0*cr;

for (i = 0; i < 32; i += 1) {
    test0 = step(zy, 0.0);
    crossTheta = zx*sin(theta) - zy*cos(theta);
    test1 = step(crossTheta, 0.0);

    ct = cos(2.0*theta);
    st = sin(2.0*theta);

    newzx0 = zx;
    newzy0 = 0.0 - zy;
    newzx1 = ct*zx + st*zy;
    newzy1 = st*zx - ct*zy;

    zx, zy = mix(mix(zx, newzx1, test1), newzx0, test0),
              mix(mix(zy, newzy1, test1), newzy0, test0);
}

uv_x = clamp(zx*0.5+0.5, 0.0, 1.0);
uv_y = clamp(zy*0.5+0.5, 0.0, 1.0);

effect_out = sample(in1, vec(uv_x, uv_y));
out1 = mix(effect_out, sample(in1, norm), bypass);
"""

patcher = {
    "name":        "f_ngon",
    "prefix":      "ngon",
    "object_name": "ngon_pix",
    "title":       "Ngon",
    "archetype":   "processor",

    "presentation_width":  154,
    "presentation_height": 91,

    "params": [
        {"name": "n_mirrors", "type": "float", "min": 2.0, "max": 18.0, "default": 6.0, "label": "N Mirrors", "hint": "Mirror count -- output is a 2*n_mirrors-gon; 32-iteration fold confirmed stable through n_mirrors=18"},
        {"name": "rotation",  "type": "float", "min": 0.0, "max": 6.2831853, "default": 0.0, "label": "Rotation", "hint": "Mirror axis rotation, radians -- mirror-0 defaults to x-axis"},
        {"name": "scale",     "type": "float", "min": 0.0, "max": 2.0, "default": 1.0, "label": "Scale",    "hint": "Zoom -- confirmed stable near zero; 1.0=identity"},
        {"name": "bypass",    "type": "bypass"},
    ],

    "outlets": [{"comment": "composite"}],

    "codebox": CODEBOX,
}
