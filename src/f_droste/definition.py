# f_droste patcher definition
# Input to tools/build_patcher.py
# Last updated: 2026-06-15

CODEBOX = """\
Param zoom(2.0);
Param n_arms(1.0);
Param time_s(0.0);
Param twist(0.0);
Param rotation(0.0);
Param bypass(0.0);

TWO_PI = 6.28318530717959;

dx = norm.x - 0.5;
dy = norm.y - 0.5;

r = sqrt(dx*dx + dy*dy);
theta = atan2(dy, dx);

log_zoom = log(max(zoom, 1.001));
s = log(max(r, 0.00001)) / log_zoom;
t = (theta / TWO_PI) + rotation;

s = s + time_s;

// symmetric shear in log-polar space
// twist=0: rings + radial spokes
// twist=1: Escher coupling -- both families spiral, one revolution = one zoom level
s_sp = s - t * twist;
t_sp = t + s * twist;

droste_out = sample(in1, vec(fract(t_sp * n_arms), fract(s_sp), 0));
out1 = mix(droste_out, sample(in1, norm), bypass);
"""

patcher = {
    # Identity
    "name":        "f_droste",
    "prefix":      "droste",
    "object_name": "droste_pix",
    "title":       "Droste",

    # Archetype
    "archetype":   "processor",

    # Presentation panel size
    "presentation_width":  154,
    "presentation_height": 91,

    "params": [
        {"name": "zoom",     "type": "float", "min": 1.1,  "max": 100.0, "default": 2.0, "label": "Zoom",     "hint": "Scale ratio -- layer density"},
        {"name": "n_arms",   "type": "float", "min": 1.0,  "max": 16.0,  "default": 1.0, "label": "Arms",     "hint": "Arm count -- all integers tile cleanly"},
        {"name": "twist",    "type": "float", "min": -8.0, "max": 8.0,   "default": 0.0, "label": "Twist",    "hint": "0=rings  1=Escher spiral"},
        {"name": "rotation", "type": "float", "min": 0.0,  "max": 1.0,   "default": 0.0, "label": "Rotation", "hint": "Angular offset"},
        {"name": "time_s",   "type": "internal"},  # scalar signal inlet, driven by LFO data outlet
        {"name": "bypass",   "type": "bypass"},
    ],

    "outlets": [
        {"comment": "composite"},
    ],

    "codebox": CODEBOX,
}
