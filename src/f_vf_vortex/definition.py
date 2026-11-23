patcher = {
    "name":               "f_vf_vortex",
    "prefix":             "vf_vortex",
    "object_name":        "vf_vortex_pix",
    "title":              "Vortex",
    "signal_type":        "∇ out",
    "archetype":          "source",
    # default render trigger (`r draw`): a pure generator, it does not read inlet 0 (Matt, 2026-11-06)
    "pix_type":           "float32",

    "presentation_width":  196,
    "presentation_height": 160,

    "outlets": [
        {"comment": "vecfield"},
    ],

    # Optional modulation inlets — each adds an inlet with vs_inState + vs_black fallback
    # Label is the inlet hover text. These become outer inlets 1..N on the pix object.
    # Inside the gen subpatcher, they become in 2, in 3, ... (in 1 is the bang/render trigger)
    "mod_inlets": [
        {"label": "cx mod"},
        {"label": "cy mod"},
        {"label": "convergence mod"},
        {"label": "curl mod"},
    ],

    "params": [
        # Row 1: core field params
        {"name": "cx",          "type": "float", "widget": "numbox", "min": 0.0,  "max": 1.0,  "default": 0.5,  "label": "Cx",       "hint": "Fixed point X position"},
        {"name": "cy",          "type": "float", "widget": "numbox", "min": 0.0,  "max": 1.0,  "default": 0.5,  "label": "Cy",       "hint": "Fixed point Y position"},
        {"name": "convergence", "type": "float", "min": -1.0, "max": 1.0,  "default": 0.5,  "label": "Converge", "hint": "Inward pull. 0=none, >0=sink, <0=source"},
        {"name": "curl",        "type": "float", "min": -1.0, "max": 1.0,  "default": 0.0,  "label": "Curl",     "hint": "Rotation. 0=none, >0=CCW, <0=CW"},
        # Row 2: falloff + modulation amounts
        {"name": "falloff",          "type": "float", "widget": "numbox", "min": 0.0, "max": 10.0, "default": 2.0,  "label": "Falloff",   "hint": "Exponential falloff rate. 0=uniform field"},
        {"name": "cx_amt",           "type": "float", "widget": "numbox", "min": 0.0, "max": 1.0,  "default": 0.0,  "label": "Cx Amt",    "hint": "cx modulation depth (inlet 1)"},
        {"name": "cy_amt",           "type": "float", "widget": "numbox", "min": 0.0, "max": 1.0,  "default": 0.0,  "label": "Cy Amt",    "hint": "cy modulation depth (inlet 2)"},
        {"name": "convergence_amt",  "type": "float", "widget": "numbox", "min": 0.0, "max": 1.0,  "default": 0.0,  "label": "Conv Amt",  "hint": "convergence modulation depth (inlet 3)"},
        # Row 3: curl_amt + bypass
        {"name": "curl_amt",    "type": "float", "widget": "numbox", "min": 0.0, "max": 1.0,  "default": 0.0,  "label": "Curl Amt",  "hint": "curl modulation depth (inlet 4)"},
        {"name": "bypass",      "type": "bypass"},
    ],

    "codebox": """\
Param cx(0.5);
Param cy(0.5);
Param convergence(0.5);
Param curl(0.0);
Param falloff(2.0);
Param cx_amt(0.0);
Param cy_amt(0.0);
Param convergence_amt(0.0);
Param curl_amt(0.0);
Param bypass(0.0);

// modulation offsets (decode from 0-1 to signed, scale by amt)
cx_eff = cx + (sample(in2, norm).x - 0.5) * 2.0 * cx_amt;
cy_eff = cy + (sample(in3, norm).x - 0.5) * 2.0 * cy_amt;
conv_eff = convergence + (sample(in4, norm).x - 0.5) * 2.0 * convergence_amt;
curl_eff = curl + (sample(in5, norm).x - 0.5) * 2.0 * curl_amt;

// offset from center
dx = norm.x - cx_eff;
dy = norm.y - cy_eff;

// distance — guard div-by-zero
r = sqrt(dx*dx + dy*dy);
r_safe = max(r, 0.0001);

// unit radial (pointing away from center)
rx = dx / r_safe;
ry = dy / r_safe;

// unit tangential (90 deg CCW of radial)
tx = -ry;
ty = rx;

// field: convergence pulls toward center (negate radial), curl rotates
fx = conv_eff * (-rx) + curl_eff * tx;
fy = conv_eff * (-ry) + curl_eff * ty;

// exponential falloff — clamp to positive, no ring artifact
f_safe = max(falloff, 0.0);
strength = exp(-r * f_safe);
fx = fx * strength;
fy = fy * strength;

// encode signed [-1,1] to [0,1] range
R = clamp(fx * 0.5 + 0.5, 0.0, 1.0);
G = clamp(fy * 0.5 + 0.5, 0.0, 1.0);

field_out = vec(R, G, 0.5, 1.0);
out1 = mix(field_out, vec(0.5, 0.5, 0.5, 1.0), bypass);
""",
}

# BEGIN overrides (build/capture.py rewrites only this block)
patcher["overrides"] = {
    "convergence.ctl": {"presentation_rect": [4.0, 38.0, 27.0, 43.0]},
    "convergence.label": {"presentation_rect": [-7.5, 20.0, 50.0, 18.0]},
    "convergence_amt.ctl": {"presentation_rect": [4.0, 138.0, 34.0, 15.0]},
    "convergence_amt.label": {"presentation_rect": [-7.5, 120.0, 50.0, 18.0]},
    "curl.ctl": {"presentation_rect": [41.0, 38.0, 27.0, 43.0]},
    "curl.label": {"presentation_rect": [29.5, 20.0, 50.0, 18.0]},
    "curl_amt.ctl": {"presentation_rect": [41.0, 138.0, 34.0, 15.0]},
    "curl_amt.label": {"presentation_rect": [29.5, 120.0, 50.0, 18.0]},
    "cx.ctl": {"presentation_rect": [4.0, 100.0, 34.0, 15.0]},
    "cx.label": {"presentation_rect": [-7.5, 82.0, 50.0, 18.0]},
    "cx_amt.ctl": {"presentation_rect": [115.0, 100.0, 34.0, 15.0]},
    "cx_amt.label": {"presentation_rect": [103.5, 82.0, 50.0, 18.0]},
    "cy.ctl": {"presentation_rect": [41.0, 100.0, 34.0, 15.0]},
    "cy.label": {"presentation_rect": [29.5, 82.0, 50.0, 18.0]},
    "cy_amt.ctl": {"presentation_rect": [152.0, 100.0, 34.0, 15.0]},
    "cy_amt.label": {"presentation_rect": [140.5, 82.0, 50.0, 18.0]},
    "falloff.ctl": {"presentation_rect": [78.0, 100.0, 34.0, 15.0]},
    "falloff.label": {"presentation_rect": [66.5, 82.0, 50.0, 18.0]},
}
# END overrides
