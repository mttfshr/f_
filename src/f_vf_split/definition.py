patcher = {
    "name":               "f_vf_split",
    "prefix":             "split",
    "object_name":        "split_pix",
    "title":              "VF Split",
    "signal_type":        "vecfield in",
    "archetype":          "processor",
    "pix_type":           "float32",

    # Bypass drives the codebox Param `bypass_gate` (jsui -> `prepend param bypass_gate` -> pix),
    # not the native @bypass, which skips the shader and flips secondary outlets.  Every outlet
    # mixes to its passthrough, so a bypassed module is a passthrough (Matt, 2026-10-05; plan.md item 10).
    "bypass_mode":        "param",

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
Param bypass_gate(0.0);

r = sample(in1, norm).x;
g = sample(in1, norm).y;

r_out = mix(r, r * 2.0 - 1.0, bipolar);
g_out = mix(g, g * 2.0 - 1.0, bipolar);

x_ch = vec(r_out, r_out, r_out, 1.0);
y_ch = vec(g_out, g_out, g_out, 1.0);

out1 = mix(x_ch, sample(in1, norm), bypass_gate);
out2 = mix(y_ch, sample(in1, norm), bypass_gate);
""",
}
