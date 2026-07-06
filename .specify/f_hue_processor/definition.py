# f_hue_processor patcher definition
# Input to tools/build_patcher.py
# Last updated: 2026-06-15

CODEBOX = """\
Param hue_center(120.0);
Param hue_lower(36.0);
Param hue_upper(36.0);
Param edge_falloff(10.0);
Param sat_amt(0.0);
Param lum_shift(0.0);
Param hue_shift(0.0);
Param bypass(0.0);

uv = norm;
src = sample(in1, uv);
rg = src.r; gg = src.g; bg = src.b;

cmax = max(rg, max(gg, bg));
cmin = min(rg, min(gg, bg));
delta = cmax - cmin;
safe_delta = max(delta, 0.001);
safe_cmax  = max(cmax, 0.001);

hue_r = mod((gg - bg) / safe_delta, 6.0) / 6.0;
hue_g = ((bg - rg) / safe_delta + 2.0) / 6.0;
hue_b = ((rg - gg) / safe_delta + 4.0) / 6.0;

r_is_max = step(gg, rg) * step(bg, rg);
g_is_max = step(bg, gg) * (1.0 - r_is_max);

hue = mix(mix(hue_b, hue_g, g_is_max), hue_r, r_is_max);
hue = fract(hue + 1.0);

S = delta / safe_cmax;
V = cmax;

hue_c   = hue_center / 360.0;
lower_n = hue_lower  / 360.0;
upper_n = hue_upper  / 360.0;
fall_n  = max(edge_falloff / 360.0, 0.00001);

signed_dist = mod(hue - hue_c + 0.5, 1.0) - 0.5;

upper_mask = 1.0 - smoothstep(upper_n, upper_n + fall_n, max( signed_dist, 0.0));
lower_mask = 1.0 - smoothstep(lower_n, lower_n + fall_n, max(-signed_dist, 0.0));

sat_gate = smoothstep(0.05, 0.15, S);
hue_mask = upper_mask * lower_mask * sat_gate;

blended_H = fract(hue + (hue_shift / 360.0) * hue_mask);
blended_S = clamp(S + sat_amt * hue_mask, 0.0, 1.0);
blended_V = clamp(V + lum_shift * hue_mask, 0.0, 1.0);

h6    = blended_H * 6.0;
r_hsv = clamp(abs(h6 - 3.0) - 1.0, 0.0, 1.0);
g_hsv = clamp(2.0 - abs(h6 - 2.0), 0.0, 1.0);
b_hsv = clamp(2.0 - abs(h6 - 4.0), 0.0, 1.0);

ro = blended_V * mix(1.0, r_hsv, blended_S);
go = blended_V * mix(1.0, g_hsv, blended_S);
bo = blended_V * mix(1.0, b_hsv, blended_S);

effective = 1.0 - bypass;
out1 = vec(mix(rg, ro, effective),
           mix(gg, go, effective),
           mix(bg, bo, effective),
           src.a);
"""

patcher = {
    "name":        "f_hue_processor",
    "prefix":      "hue_processor",
    "object_name": "hue_pix",
    "title":       "Hue Processor",
    "archetype":   "processor",

    "presentation_width":  227,
    "presentation_height": 164,

    "params": [
        {"name": "hue_center",   "type": "float", "min": 0.0,    "max": 360.0, "default": 120.0, "label": "Center",  "hint": "Hue band center in degrees"},
        {"name": "hue_lower",    "type": "float", "min": 0.0,    "max": 180.0, "default": 36.0,  "label": "Lower",   "hint": "Flat-top extent below center in degrees"},
        {"name": "hue_upper",    "type": "float", "min": 0.0,    "max": 180.0, "default": 36.0,  "label": "Upper",   "hint": "Flat-top extent above center in degrees"},
        {"name": "edge_falloff", "type": "float", "min": 0.0,    "max": 90.0,  "default": 10.0,  "label": "Falloff", "hint": "Smoothstep falloff width in degrees -- 0=hard edge"},
        {"name": "sat_amt",      "type": "float", "min": -1.0,   "max": 1.0,   "default": 0.0,   "label": "Sat",     "hint": "-1=full desaturate  0=unchanged  1=full boost"},
        {"name": "lum_shift",    "type": "float", "min": -1.0,   "max": 1.0,   "default": 0.0,   "label": "Lum",     "hint": "Additive luminance shift within band"},
        {"name": "hue_shift",    "type": "float", "min": -180.0, "max": 180.0, "default": 0.0,   "label": "Hue",     "hint": "Hue rotation within band in degrees"},
        {"name": "bypass",       "type": "bypass"},
    ],

    "outlets": [{"comment": "composite"}],

    "codebox": CODEBOX,
}
