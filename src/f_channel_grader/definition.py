# f_channel_grader patcher definition
# Input to tools/build_patcher.py
# Last updated: 2026-06-15

CODEBOX = """\
Param r_lift(0.0);  Param r_gamma(0.0);  Param r_gain(0.0);
Param g_lift(0.0);  Param g_gamma(0.0);  Param g_gain(0.0);
Param b_lift(0.0);  Param b_gamma(0.0);  Param b_gain(0.0);
Param m_lift(0.0);  Param m_gamma(0.0);  Param m_gain(0.0);
Param bypass(0.0);

uv = norm;
src = sample(in1, uv);
r = src.r; g = src.g; b = src.b;

rg = pow(2.0, r_gain) * pow(clamp(r + r_lift, 0.0, 1.0), 1.0 / max(pow(2.0, r_gamma), 0.001));
gg = pow(2.0, g_gain) * pow(clamp(g + g_lift, 0.0, 1.0), 1.0 / max(pow(2.0, g_gamma), 0.001));
bg = pow(2.0, b_gain) * pow(clamp(b + b_lift, 0.0, 1.0), 1.0 / max(pow(2.0, b_gamma), 0.001));

mg = pow(2.0, m_gain);
me = 1.0 / max(pow(2.0, m_gamma), 0.001);
ro = mg * pow(clamp(rg + m_lift, 0.0, 1.0), me);
go = mg * pow(clamp(gg + m_lift, 0.0, 1.0), me);
bo = mg * pow(clamp(bg + m_lift, 0.0, 1.0), me);

effective = 1.0 - bypass;
out1 = vec(mix(r, ro, effective),
           mix(g, go, effective),
           mix(b, bo, effective),
           src.a);
"""

patcher = {
    "name":        "f_channel_grader",
    "prefix":      "channel_grader",
    "object_name": "grade_pix",
    "title":       "Channel Grader",
    "archetype":   "processor",

    "presentation_width":  227,
    "presentation_height": 164,

    "params": [
        # Red channel
        {"name": "r_lift",  "type": "float", "min": -1.0, "max": 1.0, "default": 0.0, "label": "R Lift",  "hint": "Red lift"},
        {"name": "r_gamma", "type": "float", "min": -1.0, "max": 1.0, "default": 0.0, "label": "R Gamma", "hint": "Red gamma"},
        {"name": "r_gain",  "type": "float", "min": -1.0, "max": 1.0, "default": 0.0, "label": "R Gain",  "hint": "Red gain"},
        # Green channel
        {"name": "g_lift",  "type": "float", "min": -1.0, "max": 1.0, "default": 0.0, "label": "G Lift",  "hint": "Green lift"},
        {"name": "g_gamma", "type": "float", "min": -1.0, "max": 1.0, "default": 0.0, "label": "G Gamma", "hint": "Green gamma"},
        {"name": "g_gain",  "type": "float", "min": -1.0, "max": 1.0, "default": 0.0, "label": "G Gain",  "hint": "Green gain"},
        # Blue channel
        {"name": "b_lift",  "type": "float", "min": -1.0, "max": 1.0, "default": 0.0, "label": "B Lift",  "hint": "Blue lift"},
        {"name": "b_gamma", "type": "float", "min": -1.0, "max": 1.0, "default": 0.0, "label": "B Gamma", "hint": "Blue gamma"},
        {"name": "b_gain",  "type": "float", "min": -1.0, "max": 1.0, "default": 0.0, "label": "B Gain",  "hint": "Blue gain"},
        # Master
        {"name": "m_lift",  "type": "float", "min": -1.0, "max": 1.0, "default": 0.0, "label": "M Lift",  "hint": "Master lift -- applied after per-channel"},
        {"name": "m_gamma", "type": "float", "min": -1.0, "max": 1.0, "default": 0.0, "label": "M Gamma", "hint": "Master gamma -- applied after per-channel"},
        {"name": "m_gain",  "type": "float", "min": -1.0, "max": 1.0, "default": 0.0, "label": "M Gain",  "hint": "Master gain -- applied after per-channel"},
        {"name": "bypass",  "type": "bypass"},
    ],

    "outlets": [{"comment": "composite"}],

    "codebox": CODEBOX,
}
