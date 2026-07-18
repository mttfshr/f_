# f_luma_processor patcher definition
# Input to tools/build_patcher.py
# Last updated: 2026-06-15

CODEBOX = """\
Param low_mid(0.33);
Param mid_high(0.66);
Param edge_falloff(0.1);
Param sat_amt(0.0);
Param lum_shift(0.0);
Param hue_shift(0.0);
Param bypass(0.0);

uv = norm;
src = sample(in1, uv);
r = src.r; g = src.g; b = src.b;

cmax = max(max(r, g), b);
cmin = min(min(r, g), b);
delta = cmax - cmin;

hue = 0.0;
s1 = step(0.00001, delta);
hr = (g - b) / max(delta, 0.00001);
hg = 2.0 + (b - r) / max(delta, 0.00001);
hb = 4.0 + (r - g) / max(delta, 0.00001);
hue = step(cmax, r + 0.00001) * hr
    + step(cmax, g + 0.00001) * hg
    + (1.0 - step(cmax, r + 0.00001)) * (1.0 - step(cmax, g + 0.00001)) * hb;
hue = (hue / 6.0 + 1.0) - floor(hue / 6.0 + 1.0);

sat = s1 * delta / max(cmax, 0.00001);
val = cmax;

lum = 0.299 * r + 0.587 * g + 0.114 * b;

lm = min(low_mid, mid_high);
mh = max(low_mid, mid_high);
ef = edge_falloff;
mask = smoothstep(lm - ef, lm + ef, lum) * (1.0 - smoothstep(mh - ef, mh + ef, lum));

sat_out = clamp(sat + sat_amt * mask, 0.0, 1.0);
val_out = clamp(val + lum_shift * mask, 0.0, 1.0);
hue_out = hue + (hue_shift / 360.0) * mask;
hue_out = hue_out - floor(hue_out);

h6 = hue_out * 6.0;
kr = abs(h6 - 3.0) - 1.0;
kg = 2.0 - abs(h6 - 2.0);
kb = 2.0 - abs(h6 - 4.0);
ro = val_out * mix(1.0, clamp(kr, 0.0, 1.0), sat_out);
go = val_out * mix(1.0, clamp(kg, 0.0, 1.0), sat_out);
bo = val_out * mix(1.0, clamp(kb, 0.0, 1.0), sat_out);

effective = 1.0 - bypass;
out1 = vec(mix(r, ro, effective),
           mix(g, go, effective),
           mix(b, bo, effective),
           src.a);
"""

patcher = {
    "name":        "f_luma_processor",
    "prefix":      "luma_processor",
    "object_name": "luma_pix",
    "title":       "Luma Processor",
    "archetype":   "processor",

    "presentation_width":  227,
    "presentation_height": 164,

    "params": [
        {"name": "low_mid",      "type": "float", "min": 0.0,    "max": 1.0,   "default": 0.33,  "label": "Lo/Mid",  "hint": "Lower boundary of midtone band (luma 0-1)"},
        {"name": "mid_high",     "type": "float", "min": 0.0,    "max": 1.0,   "default": 0.66,  "label": "Mid/Hi",  "hint": "Upper boundary of midtone band (luma 0-1)"},
        {"name": "edge_falloff", "type": "float", "min": 0.0,    "max": 0.5,   "default": 0.1,   "label": "Falloff", "hint": "Smoothstep falloff width at band edges"},
        {"name": "sat_amt",      "type": "float", "min": -1.0,   "max": 1.0,   "default": 0.0,   "label": "Sat",     "hint": "-1=full desaturate  0=unchanged  1=full boost"},
        {"name": "lum_shift",    "type": "float", "min": -1.0,   "max": 1.0,   "default": 0.0,   "label": "Lum",     "hint": "Additive luminance shift within band"},
        {"name": "hue_shift",    "type": "float", "min": -180.0, "max": 180.0, "default": 0.0,   "label": "Hue",     "hint": "Hue rotation within band in degrees"},
        {"name": "bypass",       "type": "bypass"},
    ],

    "outlets": [{"comment": "composite"}],

    "codebox": CODEBOX,
}
