# f_lens patcher definition
# Input to tools/build_patcher.py
# Last updated: 2026-06-15
#
# Note: tilt, tilt_axis, tilt_pos, slope, mode are in the route and UI
# but not yet implemented in the codebox -- marked internal until wired.

CODEBOX = """\
Param aberration(0.0);
Param distortion(0.5);
Param transmission(0.0);
Param aberration_mod(0.0);
Param distortion_mod(0.0);
Param transmission_mod(0.0);
Param surface_mod(0.0);
Param bypass(0.0);

uv = norm;
cx = uv.x - 0.5;
cy = uv.y - 0.5;
dist = length(vec(cx, cy));

aberr_tex = sample(in2, uv).x;
dist_tex  = sample(in3, uv).x;
trans_tex = sample(in4, uv).x;
eps    = 0.002;
surf_c = sample(in5, uv).x;
surf_r = sample(in5, vec(uv.x + eps, uv.y)).x;
surf_u = sample(in5, vec(uv.x, uv.y + eps)).x;

k = (distortion - 0.5) * 2.0;
k = k * (1.0 + dist_tex * distortion_mod);
r2 = cx*cx + cy*cy;
warp_cx = cx * (1.0 + k*r2);
warp_cy = cy * (1.0 + k*r2);
warp_uv = vec(0.5 + warp_cx, 0.5 + warp_cy);

surf_dx = (surf_r - surf_c) * surface_mod;
surf_dy = (surf_u - surf_c) * surface_mod;
warp_uv = vec(warp_uv.x + surf_dx, warp_uv.y + surf_dy);
warp_cx = warp_uv.x - 0.5;
warp_cy = warp_uv.y - 0.5;

ab = aberration * dist * (1.0 + aberr_tex * aberration_mod);
r_uv = vec(0.5 + warp_cx * (1.0 + ab), 0.5 + warp_cy * (1.0 + ab));
b_uv = vec(0.5 + warp_cx * (1.0 - ab), 0.5 + warp_cy * (1.0 - ab));
r_val = sample(in1, r_uv).x;
g_val = sample(in1, warp_uv).y;
b_val = sample(in1, b_uv).z;
effect_out = vec(r_val, g_val, b_val, 1.0);

dist_v = dist * (1.0 + trans_tex * transmission_mod);
vignette = 1.0 - smoothstep(0.3, 0.7, dist_v);
warm_shift = vec(1.05, 1.0, 0.92, 1.0);
effect_out = mix(effect_out * warm_shift * vignette, effect_out, 1.0 - transmission);

out1 = mix(effect_out, sample(in1, uv), bypass);
"""

patcher = {
    "name":        "f_lens",
    "prefix":      "lens",
    "object_name": "lens_pix",
    "title":       "Lens",
    "archetype":   "processor",

    "presentation_width":  227,
    "presentation_height": 164,

    "params": [
        {"name": "aberration",      "type": "float", "min": 0.0, "max": 1.0,  "default": 0.0, "label": "Aberr",      "hint": "Chromatic aberration -- RGB channel separation scaled by radius"},
        {"name": "distortion",      "type": "float", "min": 0.0, "max": 1.0,  "default": 0.5, "label": "Distort",    "hint": "Barrel/pincushion distortion -- 0.5=none, <0.5=barrel, >0.5=pincushion"},
        {"name": "transmission",    "type": "float", "min": 0.0, "max": 1.0,  "default": 0.0, "label": "Trans",      "hint": "Vignette / transmission falloff -- warm-shifted toward edges"},
        {"name": "aberration_mod",  "type": "float", "min": 0.0, "max": 1.0,  "default": 0.0, "label": "Aberr Mod",  "hint": "Aberration modulation depth (inlet 2 texture)"},
        {"name": "distortion_mod",  "type": "float", "min": 0.0, "max": 1.0,  "default": 0.0, "label": "Dist Mod",   "hint": "Distortion modulation depth (inlet 3 texture)"},
        {"name": "transmission_mod","type": "float", "min": 0.0, "max": 1.0,  "default": 0.0, "label": "Trans Mod",  "hint": "Transmission modulation depth (inlet 4 texture)"},
        {"name": "surface_mod",     "type": "float", "min": 0.0, "max": 5.0,  "default": 0.0, "label": "Surf Mod",   "hint": "Surface emboss displacement depth (inlet 5 gradient texture)"},
        # Not yet wired in codebox -- UI-only for now
        {"name": "tilt",            "type": "internal"},
        {"name": "tilt_axis",       "type": "internal"},
        {"name": "tilt_pos",        "type": "internal"},
        {"name": "slope",           "type": "internal"},
        {"name": "mode",            "type": "internal"},
        {"name": "bypass",          "type": "bypass"},
    ],

    "outlets": [{"comment": "composite"}],

    "codebox": CODEBOX,
}
