patcher = {
    "name":               "f_vf_repulse",
    "prefix":             "repulse",
    "object_name":        "repulse_pix",
    "title":              "Repulse",
    "signal_type":        "vecfield",
    "archetype":          "processor",
    "pix_type":           "float32",

    "presentation_width":  165,
    "presentation_height": 80,

    "outlets": [
        {"comment": "vecfield"},
    ],

    "params": [
        {"name": "gain",      "type": "float", "min": -10.0, "max": 10.0,  "default": 4.0,  "label": "Gain",     "hint": "Field magnitude. Negative = attraction."},
        {"name": "reach",     "type": "float", "min": -0.5,  "max": 0.5,   "default": 0.1,  "label": "Reach",    "hint": "Ring sample radius (normalized UV). Negative samples inside shapes."},
        {"name": "threshold", "type": "float", "min": -1.0,  "max": 1.0,   "default": 0.3,  "label": "Thresh",   "hint": "Luma threshold for repulsion. Negative = repulse from dark regions."},
        {"name": "mode",      "type": "menu",  "options": ["Cancel", "Max", "Abs Add", "Turbulent"], "default": 0, "label": "Mode", "hint": "Accumulation mode: Cancel, Max, Abs Add, Turbulent."},
        {"name": "bypass",    "type": "bypass"},
    ],

    "codebox": """\
Param gain(4.0);
Param reach(0.1);
Param threshold(0.3);
Param mode(0.0);
Param bypass(0.0);

uv = norm;

// Precomputed unit vectors — 16 evenly spaced directions
dx0  =  1.0000; dy0  =  0.0000;
dx1  =  0.9239; dy1  =  0.3827;
dx2  =  0.7071; dy2  =  0.7071;
dx3  =  0.3827; dy3  =  0.9239;
dx4  =  0.0000; dy4  =  1.0000;
dx5  = -0.3827; dy5  =  0.9239;
dx6  = -0.7071; dy6  =  0.7071;
dx7  = -0.9239; dy7  =  0.3827;
dx8  = -1.0000; dy8  =  0.0000;
dx9  = -0.9239; dy9  = -0.3827;
dx10 = -0.7071; dy10 = -0.7071;
dx11 = -0.3827; dy11 = -0.9239;
dx12 =  0.0000; dy12 = -1.0000;
dx13 =  0.3827; dy13 = -0.9239;
dx14 =  0.7071; dy14 = -0.7071;
dx15 =  0.9239; dy15 = -0.3827;

// Sample luma at each ring position (Rec. 601)
luma0  = sample(in1, vec(uv.x + dx0  * reach, uv.y + dy0  * reach)).x * 0.299 + sample(in1, vec(uv.x + dx0  * reach, uv.y + dy0  * reach)).y * 0.587 + sample(in1, vec(uv.x + dx0  * reach, uv.y + dy0  * reach)).z * 0.114;
luma1  = sample(in1, vec(uv.x + dx1  * reach, uv.y + dy1  * reach)).x * 0.299 + sample(in1, vec(uv.x + dx1  * reach, uv.y + dy1  * reach)).y * 0.587 + sample(in1, vec(uv.x + dx1  * reach, uv.y + dy1  * reach)).z * 0.114;
luma2  = sample(in1, vec(uv.x + dx2  * reach, uv.y + dy2  * reach)).x * 0.299 + sample(in1, vec(uv.x + dx2  * reach, uv.y + dy2  * reach)).y * 0.587 + sample(in1, vec(uv.x + dx2  * reach, uv.y + dy2  * reach)).z * 0.114;
luma3  = sample(in1, vec(uv.x + dx3  * reach, uv.y + dy3  * reach)).x * 0.299 + sample(in1, vec(uv.x + dx3  * reach, uv.y + dy3  * reach)).y * 0.587 + sample(in1, vec(uv.x + dx3  * reach, uv.y + dy3  * reach)).z * 0.114;
luma4  = sample(in1, vec(uv.x + dx4  * reach, uv.y + dy4  * reach)).x * 0.299 + sample(in1, vec(uv.x + dx4  * reach, uv.y + dy4  * reach)).y * 0.587 + sample(in1, vec(uv.x + dx4  * reach, uv.y + dy4  * reach)).z * 0.114;
luma5  = sample(in1, vec(uv.x + dx5  * reach, uv.y + dy5  * reach)).x * 0.299 + sample(in1, vec(uv.x + dx5  * reach, uv.y + dy5  * reach)).y * 0.587 + sample(in1, vec(uv.x + dx5  * reach, uv.y + dy5  * reach)).z * 0.114;
luma6  = sample(in1, vec(uv.x + dx6  * reach, uv.y + dy6  * reach)).x * 0.299 + sample(in1, vec(uv.x + dx6  * reach, uv.y + dy6  * reach)).y * 0.587 + sample(in1, vec(uv.x + dx6  * reach, uv.y + dy6  * reach)).z * 0.114;
luma7  = sample(in1, vec(uv.x + dx7  * reach, uv.y + dy7  * reach)).x * 0.299 + sample(in1, vec(uv.x + dx7  * reach, uv.y + dy7  * reach)).y * 0.587 + sample(in1, vec(uv.x + dx7  * reach, uv.y + dy7  * reach)).z * 0.114;
luma8  = sample(in1, vec(uv.x + dx8  * reach, uv.y + dy8  * reach)).x * 0.299 + sample(in1, vec(uv.x + dx8  * reach, uv.y + dy8  * reach)).y * 0.587 + sample(in1, vec(uv.x + dx8  * reach, uv.y + dy8  * reach)).z * 0.114;
luma9  = sample(in1, vec(uv.x + dx9  * reach, uv.y + dy9  * reach)).x * 0.299 + sample(in1, vec(uv.x + dx9  * reach, uv.y + dy9  * reach)).y * 0.587 + sample(in1, vec(uv.x + dx9  * reach, uv.y + dy9  * reach)).z * 0.114;
luma10 = sample(in1, vec(uv.x + dx10 * reach, uv.y + dy10 * reach)).x * 0.299 + sample(in1, vec(uv.x + dx10 * reach, uv.y + dy10 * reach)).y * 0.587 + sample(in1, vec(uv.x + dx10 * reach, uv.y + dy10 * reach)).z * 0.114;
luma11 = sample(in1, vec(uv.x + dx11 * reach, uv.y + dy11 * reach)).x * 0.299 + sample(in1, vec(uv.x + dx11 * reach, uv.y + dy11 * reach)).y * 0.587 + sample(in1, vec(uv.x + dx11 * reach, uv.y + dy11 * reach)).z * 0.114;
luma12 = sample(in1, vec(uv.x + dx12 * reach, uv.y + dy12 * reach)).x * 0.299 + sample(in1, vec(uv.x + dx12 * reach, uv.y + dy12 * reach)).y * 0.587 + sample(in1, vec(uv.x + dx12 * reach, uv.y + dy12 * reach)).z * 0.114;
luma13 = sample(in1, vec(uv.x + dx13 * reach, uv.y + dy13 * reach)).x * 0.299 + sample(in1, vec(uv.x + dx13 * reach, uv.y + dy13 * reach)).y * 0.587 + sample(in1, vec(uv.x + dx13 * reach, uv.y + dy13 * reach)).z * 0.114;
luma14 = sample(in1, vec(uv.x + dx14 * reach, uv.y + dy14 * reach)).x * 0.299 + sample(in1, vec(uv.x + dx14 * reach, uv.y + dy14 * reach)).y * 0.587 + sample(in1, vec(uv.x + dx14 * reach, uv.y + dy14 * reach)).z * 0.114;
luma15 = sample(in1, vec(uv.x + dx15 * reach, uv.y + dy15 * reach)).x * 0.299 + sample(in1, vec(uv.x + dx15 * reach, uv.y + dy15 * reach)).y * 0.587 + sample(in1, vec(uv.x + dx15 * reach, uv.y + dy15 * reach)).z * 0.114;

// Thresholded weights
w0  = max(luma0  - threshold, 0.0);
w1  = max(luma1  - threshold, 0.0);
w2  = max(luma2  - threshold, 0.0);
w3  = max(luma3  - threshold, 0.0);
w4  = max(luma4  - threshold, 0.0);
w5  = max(luma5  - threshold, 0.0);
w6  = max(luma6  - threshold, 0.0);
w7  = max(luma7  - threshold, 0.0);
w8  = max(luma8  - threshold, 0.0);
w9  = max(luma9  - threshold, 0.0);
w10 = max(luma10 - threshold, 0.0);
w11 = max(luma11 - threshold, 0.0);
w12 = max(luma12 - threshold, 0.0);
w13 = max(luma13 - threshold, 0.0);
w14 = max(luma14 - threshold, 0.0);
w15 = max(luma15 - threshold, 0.0);

fx = 0.0;
fy = 0.0;

mode_i = floor(mode);

if (mode_i < 0.5) {
    // Mode 0: Cancel — straight accumulation, opposing vectors neutralize
    fx = -dx0*w0 + -dx1*w1 + -dx2*w2 + -dx3*w3 + -dx4*w4 + -dx5*w5 + -dx6*w6 + -dx7*w7 + -dx8*w8 + -dx9*w9 + -dx10*w10 + -dx11*w11 + -dx12*w12 + -dx13*w13 + -dx14*w14 + -dx15*w15;
    fy = -dy0*w0 + -dy1*w1 + -dy2*w2 + -dy3*w3 + -dy4*w4 + -dy5*w5 + -dy6*w6 + -dy7*w7 + -dy8*w8 + -dy9*w9 + -dy10*w10 + -dy11*w11 + -dy12*w12 + -dy13*w13 + -dy14*w14 + -dy15*w15;

} else if (mode_i < 1.5) {
    // Mode 1: Max — strongest single sample wins, no cancellation
    bx = 0.0; by = 0.0; bw = 0.0;
    t = step(bw, w0);  bx = mix(bx, -dx0,  t); by = mix(by, -dy0,  t); bw = mix(bw, w0,  t);
    t = step(bw, w1);  bx = mix(bx, -dx1,  t); by = mix(by, -dy1,  t); bw = mix(bw, w1,  t);
    t = step(bw, w2);  bx = mix(bx, -dx2,  t); by = mix(by, -dy2,  t); bw = mix(bw, w2,  t);
    t = step(bw, w3);  bx = mix(bx, -dx3,  t); by = mix(by, -dy3,  t); bw = mix(bw, w3,  t);
    t = step(bw, w4);  bx = mix(bx, -dx4,  t); by = mix(by, -dy4,  t); bw = mix(bw, w4,  t);
    t = step(bw, w5);  bx = mix(bx, -dx5,  t); by = mix(by, -dy5,  t); bw = mix(bw, w5,  t);
    t = step(bw, w6);  bx = mix(bx, -dx6,  t); by = mix(by, -dy6,  t); bw = mix(bw, w6,  t);
    t = step(bw, w7);  bx = mix(bx, -dx7,  t); by = mix(by, -dy7,  t); bw = mix(bw, w7,  t);
    t = step(bw, w8);  bx = mix(bx, -dx8,  t); by = mix(by, -dy8,  t); bw = mix(bw, w8,  t);
    t = step(bw, w9);  bx = mix(bx, -dx9,  t); by = mix(by, -dy9,  t); bw = mix(bw, w9,  t);
    t = step(bw, w10); bx = mix(bx, -dx10, t); by = mix(by, -dy10, t); bw = mix(bw, w10, t);
    t = step(bw, w11); bx = mix(bx, -dx11, t); by = mix(by, -dy11, t); bw = mix(bw, w11, t);
    t = step(bw, w12); bx = mix(bx, -dx12, t); by = mix(by, -dy12, t); bw = mix(bw, w12, t);
    t = step(bw, w13); bx = mix(bx, -dx13, t); by = mix(by, -dy13, t); bw = mix(bw, w13, t);
    t = step(bw, w14); bx = mix(bx, -dx14, t); by = mix(by, -dy14, t); bw = mix(bw, w14, t);
    t = step(bw, w15); bx = mix(bx, -dx15, t); by = mix(by, -dy15, t); bw = mix(bw, w15, t);
    fx = bx * bw;
    fy = by * bw;

} else if (mode_i < 2.5) {
    // Mode 2: Abs Add — accumulate magnitudes, normalize to cancel direction
    cancel_x = -dx0*w0 + -dx1*w1 + -dx2*w2 + -dx3*w3 + -dx4*w4 + -dx5*w5 + -dx6*w6 + -dx7*w7 + -dx8*w8 + -dx9*w9 + -dx10*w10 + -dx11*w11 + -dx12*w12 + -dx13*w13 + -dx14*w14 + -dx15*w15;
    cancel_y = -dy0*w0 + -dy1*w1 + -dy2*w2 + -dy3*w3 + -dy4*w4 + -dy5*w5 + -dy6*w6 + -dy7*w7 + -dy8*w8 + -dy9*w9 + -dy10*w10 + -dy11*w11 + -dy12*w12 + -dy13*w13 + -dy14*w14 + -dy15*w15;
    abs_mag = w0 + w1 + w2 + w3 + w4 + w5 + w6 + w7 + w8 + w9 + w10 + w11 + w12 + w13 + w14 + w15;
    cancel_mag = max(sqrt(max(cancel_x * cancel_x + cancel_y * cancel_y, 0.0)), 0.0001);
    fx = (cancel_x / cancel_mag) * abs_mag;
    fy = (cancel_y / cancel_mag) * abs_mag;

} else {
    // Mode 3: Turbulent — cancel + curl injection in cancellation zones
    cancel_x = -dx0*w0 + -dx1*w1 + -dx2*w2 + -dx3*w3 + -dx4*w4 + -dx5*w5 + -dx6*w6 + -dx7*w7 + -dx8*w8 + -dx9*w9 + -dx10*w10 + -dx11*w11 + -dx12*w12 + -dx13*w13 + -dx14*w14 + -dx15*w15;
    cancel_y = -dy0*w0 + -dy1*w1 + -dy2*w2 + -dy3*w3 + -dy4*w4 + -dy5*w5 + -dy6*w6 + -dy7*w7 + -dy8*w8 + -dy9*w9 + -dy10*w10 + -dy11*w11 + -dy12*w12 + -dy13*w13 + -dy14*w14 + -dy15*w15;
    cancel_mag = sqrt(max(cancel_x * cancel_x + cancel_y * cancel_y, 0.0));
    abs_mag = w0 + w1 + w2 + w3 + w4 + w5 + w6 + w7 + w8 + w9 + w10 + w11 + w12 + w13 + w14 + w15;
    curl_x = -cancel_y;
    curl_y =  cancel_x;
    cancel_ratio = abs_mag / max(cancel_mag, 0.0001);
    turb_amt = clamp((cancel_ratio - 1.0) * 0.2, 0.0, 1.0);
    fx = cancel_x + curl_x * turb_amt;
    fy = cancel_y + curl_y * turb_amt;
}

field_x = clamp(fx * gain * 0.5 + 0.5, 0.0, 1.0);
field_y = clamp(fy * gain * 0.5 + 0.5, 0.0, 1.0);

out1 = mix(vec(field_x, field_y, 0.5, 1.0), sample(in1, uv), bypass);
""",
}
