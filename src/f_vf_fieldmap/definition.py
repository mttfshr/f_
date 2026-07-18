patcher = {
    "name":               "f_vf_fieldmap",
    "prefix":             "fieldmap",
    "object_name":        "fieldmap_pix",
    "title":              "Fieldmap",
    "signal_type":        "vecfield",
    "archetype":          "processor",
    "pix_type":           "float32",

    "presentation_width":  100,
    "presentation_height": 80,

    "outlets": [
        {"comment": "vecfield"},
    ],

    "params": [
        {"name": "gain",     "type": "float", "min": -10.0, "max": 10.0, "default": 4.0,  "label": "Gain",   "hint": "Gradient magnitude scale. Negative inverts field direction."},
        {"name": "scale",    "type": "float", "min": -0.05, "max": 0.05,  "default": 0.004, "label": "Scale",  "hint": "Central difference step size (normalized UV). Negative inverts gradient axis."},
        {"name": "rotate",   "type": "float", "min": -180.0, "max": 180.0, "default": 0.0, "label": "Rotate", "hint": "Rotate field vector in degrees."},
        {"name": "thresh",   "type": "float", "min": 0.0,  "max": 1.0,   "default": 0.0,  "label": "Thresh", "hint": "Suppress field below this luma threshold."},
        {"name": "bypass",   "type": "bypass"},
    ],

    "codebox": """\
Param strength(4.0);
Param scale(0.004);
Param bypass(0.0);

// central difference gradient — inline component access (no stored variables)
// luma = 0.299r + 0.587g + 0.114b (Rec. 601)
L_right = sample(in1, vec(norm.x + scale, norm.y)).x * 0.299 + sample(in1, vec(norm.x + scale, norm.y)).y * 0.587 + sample(in1, vec(norm.x + scale, norm.y)).z * 0.114;
L_left  = sample(in1, vec(norm.x - scale, norm.y)).x * 0.299 + sample(in1, vec(norm.x - scale, norm.y)).y * 0.587 + sample(in1, vec(norm.x - scale, norm.y)).z * 0.114;
L_down  = sample(in1, vec(norm.x, norm.y + scale)).x * 0.299 + sample(in1, vec(norm.x, norm.y + scale)).y * 0.587 + sample(in1, vec(norm.x, norm.y + scale)).z * 0.114;
L_up    = sample(in1, vec(norm.x, norm.y - scale)).x * 0.299 + sample(in1, vec(norm.x, norm.y - scale)).y * 0.587 + sample(in1, vec(norm.x, norm.y - scale)).z * 0.114;

gx = (L_right - L_left) * strength;
gy = (L_down  - L_up)   * strength;

// encode to f_vecfield (0.5 = zero vector)
field   = vec(clamp(gx * 0.5 + 0.5, 0.0, 1.0), clamp(gy * 0.5 + 0.5, 0.0, 1.0), 0.5, 1.0);
neutral = vec(0.5, 0.5, 0.5, 1.0);

out1 = mix(field, neutral, bypass);
""",
}
