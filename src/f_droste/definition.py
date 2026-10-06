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
// twist=1: Escher coupling — both families spiral, one revolution = one zoom level
s_sp = s - t * twist;
t_sp = t + s * twist;

droste_out = sample(in1, vec(fract(t_sp * n_arms), fract(s_sp), 0));
out1 = mix(droste_out, sample(in1, norm), bypass);"""

patcher = {
    # Identity
    "name":        "f_droste",
    "prefix":      "droste",
    "object_name": "droste_pix",
    "title":       "Droste",

    # Archetype
    "archetype":   "processor",
    "pix_type":    "char",
    "route_bypass": True,   # the oldest modules route a `bypass 0/1` message to the toggle

    # Presentation panel size
    "presentation_width":  150,
    "presentation_height": 88,

    "params": [
        {"name": "zoom",     "type": "float", "min": 1.1,  "max": 100.0, "default": 2.0, "label": "Zoom",     "hint": "Scale ratio — layer density"},
        {"name": "n_arms",   "type": "float", "min": 1.0,  "max": 16.0,  "default": 1.0, "label": "Arms",     "hint": "Arm count — all integers tile cleanly",
     "modmode": 0},   # modulation off: a fractional arm count does not tile
        {"name": "twist",    "type": "float", "min": -8.0, "max": 8.0,   "default": 0.0, "label": "Twist",    "hint": "0=rings  1=Escher spiral"},
        {"name": "rotation", "type": "float", "min": 0.0,  "max": 1.0,   "default": 0.0, "label": "Rot",      "hint": "Angular offset"},
        {"name": "time_s",   "type": "internal"},  # scalar signal inlet, driven by LFO data outlet
        {"name": "bypass",   "type": "bypass"},
    ],

    "outlets": [
        {"comment": "texture"},
    ],

    "codebox": CODEBOX,

    # The `time_s` scalar inlet (an LFO data outlet drives it): inlet -> attrui time_s -> pix.
    # The only module with a scalar inlet wired straight to an attrui, so it is two raw boxes and
    # two raw cords rather than a schema feature (build_cleanup T014, Matt 2026-10-05).  The attrui
    # sits left of the inlet in the raw block so the inlets stay in port order after layout.
    "raw_boxes": [
        {"box": {"attr": "time_s", "id": "obj-902", "maxclass": "attrui", "numinlets": 1, "numoutlets": 1,
                 "outlettype": [""], "parameter_enable": 0, "patching_rect": [0.0, 60.0, 129.0, 22.0]}},
        {"box": {"comment": "time_s", "id": "obj-901", "index": 0, "maxclass": "inlet", "numinlets": 0,
                 "numoutlets": 1, "outlettype": [""], "patching_rect": [160.0, 0.0, 30.0, 30.0]}},
    ],
    "raw_lines": [
        {"patchline": {"destination": ["obj-902", 0], "source": ["obj-901", 0]}},
        {"patchline": {"destination": ["obj-5", 0], "source": ["obj-902", 0]}},
    ],
}

# BEGIN overrides (build/capture.py rewrites only this block)
patcher["overrides"] = {
    "bypass_jsui": {"presentation_rect": [129.0, 4.0, 18.0, 12.0]},
    "n_arms.ctl": {"presentation_rect": [41.0, 36.0, 27.0, 43.0]},
    "n_arms.label": {"presentation_rect": [39.0, 21.0, 35.0, 18.0], "textjustification": None},
    "panel": {"presentation_rect": [0.0, 0.0, 150.0, 88.5]},
    "rotation.ctl": {"presentation_rect": [115.0, 36.0, 27.0, 43.0]},
    "rotation.label": {"presentation_rect": [116.0, 21.0, 30.0, 18.0], "textjustification": None},
    "twist.ctl": {"presentation_rect": [78.0, 36.0, 27.0, 43.0]},
    "twist.label": {"presentation_rect": [76.0, 21.0, 35.0, 18.0], "textjustification": None},
    "zoom.ctl": {"presentation_rect": [4.0, 36.0, 27.0, 43.0]},
    "zoom.label": {"presentation_rect": [3.0, 21.0, 35.0, 18.0], "textjustification": None},
}
# END overrides
