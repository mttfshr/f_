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
Param gain(4.0);
Param scale(0.004);
Param rotate(0.0);
Param thresh(0.0);
Param bypass(0.0);

// inset UV by scale to keep neighbor samples within bounds
suv_x = norm.x * (1.0 - 2.0 * scale) + scale;
suv_y = norm.y * (1.0 - 2.0 * scale) + scale;

L_center = sample(in1, vec(suv_x, suv_y)).x * 0.299 + sample(in1, vec(suv_x, suv_y)).y * 0.587 + sample(in1, vec(suv_x, suv_y)).z * 0.114;
L_right  = sample(in1, vec(suv_x + scale, suv_y)).x * 0.299 + sample(in1, vec(suv_x + scale, suv_y)).y * 0.587 + sample(in1, vec(suv_x + scale, suv_y)).z * 0.114;
L_left   = sample(in1, vec(suv_x - scale, suv_y)).x * 0.299 + sample(in1, vec(suv_x - scale, suv_y)).y * 0.587 + sample(in1, vec(suv_x - scale, suv_y)).z * 0.114;
L_down   = sample(in1, vec(suv_x, suv_y + scale)).x * 0.299 + sample(in1, vec(suv_x, suv_y + scale)).y * 0.587 + sample(in1, vec(suv_x, suv_y + scale)).z * 0.114;
L_up     = sample(in1, vec(suv_x, suv_y - scale)).x * 0.299 + sample(in1, vec(suv_x, suv_y - scale)).y * 0.587 + sample(in1, vec(suv_x, suv_y - scale)).z * 0.114;

gx = (L_right - L_left) * gain;
gy = (L_down  - L_up)   * gain;

angle = rotate * pi / 180.0;
cos_r = cos(angle);
sin_r = sin(angle);
gx2 = gx * cos_r - gy * sin_r;
gy2 = gx * sin_r + gy * cos_r;

field   = vec(clamp(gx2 * 0.5 + 0.5, 0.0, 1.0), clamp(gy2 * 0.5 + 0.5, 0.0, 1.0), 0.5, 1.0);
neutral = vec(0.5, 0.5, 0.5, 1.0);

threshed = mix(field, neutral, step(L_center, thresh));
out1 = mix(threshed, neutral, bypass);
""",
}
