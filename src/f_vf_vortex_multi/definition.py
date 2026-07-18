patcher = {
    "name":               "f_vf_vortex_multi",
    "prefix":             "vf_vortex_multi",
    "object_name":        "vf_vortex_multi_pix",
    "title":              "Vortex Multi",
    "signal_type":        "vecfield",
    "archetype":          "source",
    "pix_type":           "float32",

    "presentation_width":  190,
    "presentation_height": 283,

    "outlets": [
        {"comment": "vecfield"},
    ],

    # Mod inlets
    # Site position inlets (post-build): injected at indices 5-7
    "mod_inlets": [
        {"label": "cx mod"},
        {"label": "cy mod"},
        {"label": "convergence mod"},
        {"label": "curl mod"},
    ],

    "params": [
        # Site 1
        {"name": "s1_cx",   "type": "float", "min": 0.0,  "max": 1.0,  "default": 0.3,  "label": "S1 Cx",   "hint": "Site 1 X position"},
        {"name": "s1_cy",   "type": "float", "min": 0.0,  "max": 1.0,  "default": 0.3,  "label": "S1 Cy",   "hint": "Site 1 Y position"},
        {"name": "s1_conv", "type": "float", "min": 0.0,  "max": 1.0,  "default": 0.5,  "label": "S1 Conv", "hint": "Site 1 convergence"},
        {"name": "s1_curl", "type": "float", "min": -1.0, "max": 1.0,  "default": 0.0,  "label": "S1 Curl", "hint": "Site 1 curl"},
        # Site 2
        {"name": "s2_cx",   "type": "float", "min": 0.0,  "max": 1.0,  "default": 0.5,  "label": "S2 Cx",   "hint": "Site 2 X position"},
        {"name": "s2_cy",   "type": "float", "min": 0.0,  "max": 1.0,  "default": 0.5,  "label": "S2 Cy",   "hint": "Site 2 Y position"},
        {"name": "s2_conv", "type": "float", "min": 0.0,  "max": 1.0,  "default": 0.5,  "label": "S2 Conv", "hint": "Site 2 convergence"},
        {"name": "s2_curl", "type": "float", "min": -1.0, "max": 1.0,  "default": 0.0,  "label": "S2 Curl", "hint": "Site 2 curl"},
        # Site 3
        {"name": "s3_cx",   "type": "float", "min": 0.0,  "max": 1.0,  "default": 0.7,  "label": "S3 Cx",   "hint": "Site 3 X position"},
        {"name": "s3_cy",   "type": "float", "min": 0.0,  "max": 1.0,  "default": 0.7,  "label": "S3 Cy",   "hint": "Site 3 Y position"},
        {"name": "s3_conv", "type": "float", "min": 0.0,  "max": 1.0,  "default": 0.5,  "label": "S3 Conv", "hint": "Site 3 convergence"},
        {"name": "s3_curl", "type": "float", "min": -1.0, "max": 1.0,  "default": 0.0,  "label": "S3 Curl", "hint": "Site 3 curl"},
        # Shared
        {"name": "falloff",   "type": "float", "min": 0.0,  "max": 10.0, "default": 2.0,  "label": "Falloff",  "hint": "Shared exponential falloff rate"},
        # Global mod amounts (inlets 1-4)
        {"name": "cx_amt",    "type": "float", "min": 0.0,  "max": 1.0,  "default": 0.0,  "label": "Cx Amt",   "hint": "cx modulation depth (inlet 1)"},
        {"name": "cy_amt",    "type": "float", "min": 0.0,  "max": 1.0,  "default": 0.0,  "label": "Cy Amt",   "hint": "cy modulation depth (inlet 2)"},
        {"name": "conv_amt",  "type": "float", "min": 0.0,  "max": 1.0,  "default": 0.0,  "label": "Conv Amt", "hint": "convergence modulation depth (inlet 3)"},
        {"name": "curl_amt",  "type": "float", "min": 0.0,  "max": 1.0,  "default": 0.0,  "label": "Curl Amt", "hint": "curl modulation depth (inlet 4)"},
        {"name": "bypass",    "type": "bypass"},
    ],

    "codebox": """\
Param s1_cx(0.3);
Param s1_cy(0.3);
Param s1_conv(0.5);
Param s1_curl(0.0);

Param s2_cx(0.5);
Param s2_cy(0.5);
Param s2_conv(0.5);
Param s2_curl(0.0);

Param s3_cx(0.7);
Param s3_cy(0.7);
Param s3_conv(0.5);
Param s3_curl(0.0);

Param falloff(2.0);
Param cx_amt(0.0);
Param cy_amt(0.0);
Param conv_amt(0.0);
Param curl_amt(0.0);
Param bypass(0.0);

uv = norm;

// --- global mod offsets (decode 0-1 texture to signed, scale by amt) ---
cx_mod   = (sample(in2, uv).x - 0.5) * 2.0 * cx_amt;
cy_mod   = (sample(in3, uv).x - 0.5) * 2.0 * cy_amt;
conv_mod = (sample(in4, uv).x - 0.5) * 2.0 * conv_amt;
curl_mod = (sample(in5, uv).x - 0.5) * 2.0 * curl_amt;

// --- site 1 ---
s1_dx = uv.x - (s1_cx + cx_mod);
s1_dy = uv.y - (s1_cy + cy_mod);
s1_r = sqrt(s1_dx*s1_dx + s1_dy*s1_dy);
s1_r_safe = max(s1_r, 0.0001);
s1_rx = s1_dx / s1_r_safe;
s1_ry = s1_dy / s1_r_safe;
s1_tx = -s1_ry;
s1_ty = s1_rx;
s1_fx = (s1_conv + conv_mod) * (-s1_rx) + (s1_curl + curl_mod) * s1_tx;
s1_fy = (s1_conv + conv_mod) * (-s1_ry) + (s1_curl + curl_mod) * s1_ty;
s1_strength = exp(-s1_r * max(falloff, 0.0));
s1_fx = s1_fx * s1_strength;
s1_fy = s1_fy * s1_strength;

// --- site 2 ---
s2_dx = uv.x - (s2_cx + cx_mod);
s2_dy = uv.y - (s2_cy + cy_mod);
s2_r = sqrt(s2_dx*s2_dx + s2_dy*s2_dy);
s2_r_safe = max(s2_r, 0.0001);
s2_rx = s2_dx / s2_r_safe;
s2_ry = s2_dy / s2_r_safe;
s2_tx = -s2_ry;
s2_ty = s2_rx;
s2_fx = (s2_conv + conv_mod) * (-s2_rx) + (s2_curl + curl_mod) * s2_tx;
s2_fy = (s2_conv + conv_mod) * (-s2_ry) + (s2_curl + curl_mod) * s2_ty;
s2_strength = exp(-s2_r * max(falloff, 0.0));
s2_fx = s2_fx * s2_strength;
s2_fy = s2_fy * s2_strength;

// --- site 3 ---
s3_dx = uv.x - (s3_cx + cx_mod);
s3_dy = uv.y - (s3_cy + cy_mod);
s3_r = sqrt(s3_dx*s3_dx + s3_dy*s3_dy);
s3_r_safe = max(s3_r, 0.0001);
s3_rx = s3_dx / s3_r_safe;
s3_ry = s3_dy / s3_r_safe;
s3_tx = -s3_ry;
s3_ty = s3_rx;
s3_fx = (s3_conv + conv_mod) * (-s3_rx) + (s3_curl + curl_mod) * s3_tx;
s3_fy = (s3_conv + conv_mod) * (-s3_ry) + (s3_curl + curl_mod) * s3_ty;
s3_strength = exp(-s3_r * max(falloff, 0.0));
s3_fx = s3_fx * s3_strength;
s3_fy = s3_fy * s3_strength;

// --- additive sum and encode ---
fx = s1_fx + s2_fx + s3_fx;
fy = s1_fy + s2_fy + s3_fy;

R = clamp(fx * 0.5 + 0.5, 0.0, 1.0);
G = clamp(fy * 0.5 + 0.5, 0.0, 1.0);

field_out = vec(R, G, 0.5, 1.0);
out1 = mix(field_out, vec(0.5, 0.5, 0.5, 1.0), bypass);
""",
}
