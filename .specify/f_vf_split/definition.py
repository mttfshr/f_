patcher = {
    "name":               "f_vf_split",
    "prefix":             "split",
    "object_name":        "split_pix",
    "title":              "VF Split",
    "signal_type":        "vecfield",
    "archetype":          "processor",
    "pix_type":           "float32",

    "presentation_width":  80,
    "presentation_height": 80,

    "outlets": [
        {"comment": "X channel (R)"},
        {"comment": "Y channel (G)"},
    ],

    "params": [
        {"name": "bipolar", "type": "text_button", "options": ["Unipolar", "Bipolar"], "default": 0,
         "hint": "Unipolar: passthrough 0-1; Bipolar: remap to -1 to 1"},
        {"name": "bypass", "type": "bypass"},
    ],

    "codebox": """\
Param bipolar(0.0);
Param bypass(0.0);

r = sample(in1, norm).x;
g = sample(in1, norm).y;

r_out = mix(r, r * 2.0 - 1.0, bipolar);
g_out = mix(g, g * 2.0 - 1.0, bipolar);

x_ch = vec(r_out, r_out, r_out, 1.0);
y_ch = vec(g_out, g_out, g_out, 1.0);

out1 = mix(x_ch, sample(in1, norm), bypass);
out2 = mix(y_ch, sample(in1, norm), bypass);
""",
}
