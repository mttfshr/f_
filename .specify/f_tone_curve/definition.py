# f_tone_curve patcher definition
# Input to tools/build_patcher.py
# Last updated: 2026-06-15

# REVISIT (2026-07-03, via GPU Gems Ch. 22 "Color Controls" read):
# Despite the name, this module is not a curve — it's a 3-band
# (shadows/midtones/highlights) smoothstep-weighted additive lift keyed
# on luma. It can shift bands relative to each other but cannot express
# an arbitrary shape (S-curves, per-channel divergent remaps,
# posterization, etc.). GPU Gems Ch. 22's "Curves" section does this via
# a dependent-texture LUT: a 1xN texture sampled per-channel using the
# source channel value as the U coordinate, giving fully arbitrary
# per-channel remapping. Cheap to add given `sample()` is already the
# core primitive throughout f_. Open question: extend this module to add
# true LUT-based curve control (alongside or replacing the current
# 3-band model), or keep this module as-is and add a separate/honestly
# named module for arbitrary curves. See
# `ideas/lut_curve_and_color_controls.md` for the full research note.
# Not yet designed — discuss architecture before touching CODEBOX below.

CODEBOX = """\
Param shadows(0.0);
Param midtones(0.0);
Param highlights(0.0);
Param low_mid(0.33);
Param mid_high(0.66);
Param bypass(0.0);
Param edge_falloff(0.1);

uv = norm;
src = sample(in1, uv);
r = src.r; g = src.g; b = src.b;

lm = min(low_mid, mid_high);
mh = max(low_mid, mid_high);

lum = 0.299 * r + 0.587 * g + 0.114 * b;

sw = 1.0 - smoothstep(lm - edge_falloff, lm + edge_falloff, lum);
hw = smoothstep(mh - edge_falloff, mh + edge_falloff, lum);
mw = max(1.0 - sw - hw, 0.0);

lift_amt = shadows * sw + midtones * mw + highlights * hw;

ro = clamp(r + lift_amt, 0.0, 1.0);
go = clamp(g + lift_amt, 0.0, 1.0);
bo = clamp(b + lift_amt, 0.0, 1.0);

effective = 1.0 - bypass;
out1 = vec(mix(r, ro, effective),
           mix(g, go, effective),
           mix(b, bo, effective),
           src.a);
"""

patcher = {
    "name":        "f_tone_curve",
    "prefix":      "tone_curve",
    "object_name": "tone_pix",
    "title":       "Tone Curve",
    "archetype":   "processor",

    "presentation_width":  227,
    "presentation_height": 164,

    "params": [
        {"name": "shadows",      "type": "float", "min": -1.0, "max": 1.0, "default": 0.0,  "label": "Shadows",    "hint": "Additive lift in shadow band"},
        {"name": "midtones",     "type": "float", "min": -1.0, "max": 1.0, "default": 0.0,  "label": "Midtones",   "hint": "Additive lift in midtone band"},
        {"name": "highlights",   "type": "float", "min": -1.0, "max": 1.0, "default": 0.0,  "label": "Highlights", "hint": "Additive lift in highlight band"},
        {"name": "low_mid",      "type": "float", "min": 0.0,  "max": 1.0, "default": 0.33, "label": "Lo/Mid",     "hint": "Luma crossover between shadows and midtones"},
        {"name": "mid_high",     "type": "float", "min": 0.0,  "max": 1.0, "default": 0.66, "label": "Mid/Hi",     "hint": "Luma crossover between midtones and highlights"},
        {"name": "edge_falloff", "type": "float", "min": 0.0,  "max": 0.5, "default": 0.1,  "label": "Falloff",    "hint": "Smoothstep falloff width at band crossovers"},
        {"name": "bypass",       "type": "bypass"},
    ],

    "outlets": [{"comment": "composite"}],

    "codebox": CODEBOX,
}
