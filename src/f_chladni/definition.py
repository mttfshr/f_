# f_chladni patcher definition
# Input to tools/build_patcher.py
# Last updated: 2026-06-17
#
# Reframed 2026-06-17: single-resonance transducer with MIDI note + amp interface.
# Dual outlet: luma (nodal lines) + float32 vecfield (gradient of modal field).
# Mode A: linear interpolation between adjacent Bessel modes.
# Mode B: Gaussian resonance snap across all 8 modes (spread param controls falloff width).
# Gradient computed via central difference using user-defined function (GPU-confirmed working).

CODEBOX = """\
// --- Helper: Mode A total at arbitrary UV ---
modal_A(ux, uy, zp, radius, reflect, phase) {
    ddx = ux - 0.5;
    ddy = uy - 0.5;
    rs  = max(sqrt(ddx*ddx + ddy*ddy) * 2.0 * radius, 0.001);
    th  = atan2(ddy, ddx);
    ev  = sqrt(2.0 / (pi * rs));
    msk = 1.0 - smoothstep(0.8, 1.0, rs / max(radius, 0.001));

    z0 = 2.4048; z1 = 3.8317; z2 = 5.1356; z3 = 6.3802;
    z4 = 7.5883; z5 = 8.7715; z6 = 9.9361; z7 = 11.0864;

    s0 = step(z0, zp) * step(zp, z1);
    s1 = step(z1, zp) * step(zp, z2);
    s2 = step(z2, zp) * step(zp, z3);
    s3 = step(z3, zp) * step(zp, z4);
    s4 = step(z4, zp) * step(zp, z5);
    s5 = step(z5, zp) * step(zp, z6);
    s6 = step(z6, zp) * step(zp, z7);

    c0lo = (ev*cos(rs-z0) + reflect*ev*cos(radius-rs-z0)) * cos(0.0*th + phase) * msk;
    c0hi = (ev*cos(rs-z1) + reflect*ev*cos(radius-rs-z1)) * cos(1.0*th + phase) * msk;
    c1lo = (ev*cos(rs-z1) + reflect*ev*cos(radius-rs-z1)) * cos(1.0*th + phase) * msk;
    c1hi = (ev*cos(rs-z2) + reflect*ev*cos(radius-rs-z2)) * cos(2.0*th + phase) * msk;
    c2lo = (ev*cos(rs-z2) + reflect*ev*cos(radius-rs-z2)) * cos(2.0*th + phase) * msk;
    c2hi = (ev*cos(rs-z3) + reflect*ev*cos(radius-rs-z3)) * cos(3.0*th + phase) * msk;
    c3lo = (ev*cos(rs-z3) + reflect*ev*cos(radius-rs-z3)) * cos(3.0*th + phase) * msk;
    c3hi = (ev*cos(rs-z4) + reflect*ev*cos(radius-rs-z4)) * cos(4.0*th + phase) * msk;
    c4lo = (ev*cos(rs-z4) + reflect*ev*cos(radius-rs-z4)) * cos(4.0*th + phase) * msk;
    c4hi = (ev*cos(rs-z5) + reflect*ev*cos(radius-rs-z5)) * cos(5.0*th + phase) * msk;
    c5lo = (ev*cos(rs-z5) + reflect*ev*cos(radius-rs-z5)) * cos(5.0*th + phase) * msk;
    c5hi = (ev*cos(rs-z6) + reflect*ev*cos(radius-rs-z6)) * cos(6.0*th + phase) * msk;
    c6lo = (ev*cos(rs-z6) + reflect*ev*cos(radius-rs-z6)) * cos(6.0*th + phase) * msk;
    c6hi = (ev*cos(rs-z7) + reflect*ev*cos(radius-rs-z7)) * cos(7.0*th + phase) * msk;

    return mix(c0lo, c0hi, (zp-z0)/(z1-z0)) * s0
         + mix(c1lo, c1hi, (zp-z1)/(z2-z1)) * s1
         + mix(c2lo, c2hi, (zp-z2)/(z3-z2)) * s2
         + mix(c3lo, c3hi, (zp-z3)/(z4-z3)) * s3
         + mix(c4lo, c4hi, (zp-z4)/(z5-z4)) * s4
         + mix(c5lo, c5hi, (zp-z5)/(z6-z5)) * s5
         + mix(c6lo, c6hi, (zp-z6)/(z7-z6)) * s6;
}

// --- Helper: Mode B total at arbitrary UV ---
modal_B(ux, uy, zp, radius, reflect, phase, sprd) {
    ddx = ux - 0.5;
    ddy = uy - 0.5;
    rs  = max(sqrt(ddx*ddx + ddy*ddy) * 2.0 * radius, 0.001);
    th  = atan2(ddy, ddx);
    ev  = sqrt(2.0 / (pi * rs));
    msk = 1.0 - smoothstep(0.8, 1.0, rs / max(radius, 0.001));

    z0 = 2.4048; z1 = 3.8317; z2 = 5.1356; z3 = 6.3802;
    z4 = 7.5883; z5 = 8.7715; z6 = 9.9361; z7 = 11.0864;

    sp2 = max(sprd * sprd * 2.0, 0.0001);
    w0 = exp(-((zp-z0)*(zp-z0)) / sp2);
    w1 = exp(-((zp-z1)*(zp-z1)) / sp2);
    w2 = exp(-((zp-z2)*(zp-z2)) / sp2);
    w3 = exp(-((zp-z3)*(zp-z3)) / sp2);
    w4 = exp(-((zp-z4)*(zp-z4)) / sp2);
    w5 = exp(-((zp-z5)*(zp-z5)) / sp2);
    w6 = exp(-((zp-z6)*(zp-z6)) / sp2);
    w7 = exp(-((zp-z7)*(zp-z7)) / sp2);
    ws = max(w0+w1+w2+w3+w4+w5+w6+w7, 0.0001);

    m0 = (ev*cos(rs-z0) + reflect*ev*cos(radius-rs-z0)) * cos(0.0*th + phase) * msk;
    m1 = (ev*cos(rs-z1) + reflect*ev*cos(radius-rs-z1)) * cos(1.0*th + phase) * msk;
    m2 = (ev*cos(rs-z2) + reflect*ev*cos(radius-rs-z2)) * cos(2.0*th + phase) * msk;
    m3 = (ev*cos(rs-z3) + reflect*ev*cos(radius-rs-z3)) * cos(3.0*th + phase) * msk;
    m4 = (ev*cos(rs-z4) + reflect*ev*cos(radius-rs-z4)) * cos(4.0*th + phase) * msk;
    m5 = (ev*cos(rs-z5) + reflect*ev*cos(radius-rs-z5)) * cos(5.0*th + phase) * msk;
    m6 = (ev*cos(rs-z6) + reflect*ev*cos(radius-rs-z6)) * cos(6.0*th + phase) * msk;
    m7 = (ev*cos(rs-z7) + reflect*ev*cos(radius-rs-z7)) * cos(7.0*th + phase) * msk;

    return (w0*m0 + w1*m1 + w2*m2 + w3*m3 + w4*m4 + w5*m5 + w6*m6 + w7*m7) / ws;
}

// --- Params ---
Param note(60.0);
Param amp(1.0);
Param dishradius(1.0);
Param reflectamt(0.0);
Param linesharpness(10.0);
Param ph0(0.0);
Param spread(0.3);
Param mode(0.0);
Param view_mode(0.0);
Param gain(1.0);
Param bypass(0.0);

// --- Bessel zeros ---
z0 = 2.4048; z1 = 3.8317; z2 = 5.1356; z3 = 6.3802;
z4 = 7.5883; z5 = 8.7715; z6 = 9.9361; z7 = 11.0864;

// --- Map note 0-127 to Bessel zero span ---
z_pos = z0 + (note / 127.0) * (z7 - z0);

// --- Coordinate system (circular / strip blend) ---
dx = norm.x - 0.5;
dy = norm.y - 0.5;
r_circ  = sqrt(dx*dx + dy*dy) * 2.0 * dishradius;
th_circ = atan2(dy, dx);
r_strip  = norm.y * dishradius;
th_strip = norm.x * twopi - pi;
r  = mix(r_circ,  r_strip,  view_mode);
th = mix(th_circ, th_strip, view_mode);

r_s  = max(r, 0.001);
env  = sqrt(2.0 / (pi * r_s));
mask = 1.0 - smoothstep(0.8, 1.0, r / max(dishradius, 0.001));

// --- Mode A: linear blend (via function at center UV) ---
total_A = modal_A(norm.x, norm.y, z_pos, dishradius, reflectamt, ph0);

// --- Mode B: Gaussian resonance snap ---
// expressive spread range: 0.1-0.5 (below 0.1 produces white artifacts between modes)
spread2 = max(spread * spread * 2.0, 0.0001);
w0 = exp(-((z_pos-z0)*(z_pos-z0)) / spread2);
w1 = exp(-((z_pos-z1)*(z_pos-z1)) / spread2);
w2 = exp(-((z_pos-z2)*(z_pos-z2)) / spread2);
w3 = exp(-((z_pos-z3)*(z_pos-z3)) / spread2);
w4 = exp(-((z_pos-z4)*(z_pos-z4)) / spread2);
w5 = exp(-((z_pos-z5)*(z_pos-z5)) / spread2);
w6 = exp(-((z_pos-z6)*(z_pos-z6)) / spread2);
w7 = exp(-((z_pos-z7)*(z_pos-z7)) / spread2);
wsum = max(w0+w1+w2+w3+w4+w5+w6+w7, 0.0001);

m0 = (env*cos(r_s-z0) + reflectamt*env*cos(dishradius-r_s-z0)) * cos(0.0*th + ph0) * mask;
m1 = (env*cos(r_s-z1) + reflectamt*env*cos(dishradius-r_s-z1)) * cos(1.0*th + ph0) * mask;
m2 = (env*cos(r_s-z2) + reflectamt*env*cos(dishradius-r_s-z2)) * cos(2.0*th + ph0) * mask;
m3 = (env*cos(r_s-z3) + reflectamt*env*cos(dishradius-r_s-z3)) * cos(3.0*th + ph0) * mask;
m4 = (env*cos(r_s-z4) + reflectamt*env*cos(dishradius-r_s-z4)) * cos(4.0*th + ph0) * mask;
m5 = (env*cos(r_s-z5) + reflectamt*env*cos(dishradius-r_s-z5)) * cos(5.0*th + ph0) * mask;
m6 = (env*cos(r_s-z6) + reflectamt*env*cos(dishradius-r_s-z6)) * cos(6.0*th + ph0) * mask;
m7 = (env*cos(r_s-z7) + reflectamt*env*cos(dishradius-r_s-z7)) * cos(7.0*th + ph0) * mask;
total_B = (w0*m0 + w1*m1 + w2*m2 + w3*m3 + w4*m4 + w5*m5 + w6*m6 + w7*m7) / wsum;

// --- Select mode and scale ---
total = mix(total_A, total_B, step(0.5, mode)) * amp;

// --- Luma output ---
line     = 1.0 - clamp(sqrt(abs(total)) * linesharpness, 0.0, 1.0);
luma_out = vec(line, line, line, 1.0);

// --- Vecfield: central difference gradient, mode-aware ---
eps  = 0.004;
md   = step(0.5, mode);
t_xp = mix(modal_A(norm.x+eps, norm.y,     z_pos, dishradius, reflectamt, ph0),
           modal_B(norm.x+eps, norm.y,     z_pos, dishradius, reflectamt, ph0, spread), md);
t_xn = mix(modal_A(norm.x-eps, norm.y,     z_pos, dishradius, reflectamt, ph0),
           modal_B(norm.x-eps, norm.y,     z_pos, dishradius, reflectamt, ph0, spread), md);
t_yp = mix(modal_A(norm.x,     norm.y+eps, z_pos, dishradius, reflectamt, ph0),
           modal_B(norm.x,     norm.y+eps, z_pos, dishradius, reflectamt, ph0, spread), md);
t_yn = mix(modal_A(norm.x,     norm.y-eps, z_pos, dishradius, reflectamt, ph0),
           modal_B(norm.x,     norm.y-eps, z_pos, dishradius, reflectamt, ph0, spread), md);

gx = (t_xp - t_xn) / (2.0 * eps);
gy = (t_yp - t_yn) / (2.0 * eps);
gmag = max(sqrt(gx*gx + gy*gy), 0.0001);
vf_out = vec(gx/gmag * 0.5 + 0.5, gy/gmag * 0.5 + 0.5, 0.0, 1.0);

// --- Out 3: unsigned magnitude of raw modal interference ---
mag_out = clamp(abs(total) * gain, 0.0, 1.0);

// --- Outputs ---
out1 = mix(luma_out, vec(0.0, 0.0, 0.0, 1.0), bypass);
out2 = mix(vf_out,   vec(0.5, 0.5, 0.0, 1.0), bypass);
out3 = mix(vec(mag_out, mag_out, mag_out, 1.0), vec(0.0, 0.0, 0.0, 1.0), bypass);
"""

patcher = {
    "name":        "f_chladni",
    "prefix":      "chladni",
    "object_name": "chladni_pix",
    "title":       "Chladni",
    "archetype":   "generator",
    "signal_type": "vecfield out",

    "pix_type":           "float32",

    "presentation_width":  227,
    "presentation_height": 164,

    "params": [
        {"name": "note",          "type": "float", "min": 0.0,     "max": 127.0,  "default": 60.0,  "label": "note",    "hint": "MIDI note (0-127) — selects Bessel mode via linear mapping"},
        {"name": "amp",           "type": "float", "min": 0.0,     "max": 1.0,    "default": 1.0,   "label": "amp",     "hint": "Amplitude envelope — scales output brightness"},
        {"name": "dishradius",    "type": "float", "min": 0.1,     "max": 4.0,    "default": 1.0,   "label": "radius",  "hint": "Plate radius — scales field in both view modes"},
        {"name": "reflectamt",    "type": "float", "min": 0.0,     "max": 1.0,    "default": 0.0,   "label": "reflect", "hint": "Boundary reflection amount — adds reflected wave"},
        {"name": "linesharpness", "type": "float", "min": 0.1,     "max": 100.0,  "default": 10.0,  "label": "sharp",   "hint": "Nodal line sharpness — higher = thinner lines"},
        {"name": "ph0",           "type": "float", "min": -6.2832, "max": 6.2832, "default": 0.0,   "label": "phase",   "hint": "Global phase offset — rotates nodal pattern"},
        {"name": "spread",        "type": "float", "min": 0.1,     "max": 1.0,    "default": 0.3,   "label": "spread",  "hint": "Mode B falloff width — 0.1=snap 0.5=broad (Mode B only)"},
        {"name": "mode",          "type": "float", "min": 0.0,     "max": 1.0,    "default": 0.0,   "label": "mode",    "hint": "0=linear interp between modes  1=Gaussian resonance snap"},
        {"name": "view_mode",     "type": "float", "min": 0.0,     "max": 1.0,    "default": 0.0,   "label": "view",    "hint": "0=circular plate  1=unwrapped strip"},
        {"name": "gain",          "type": "float", "min": 0.0,     "max": 20.0,   "default": 1.0,   "label": "gain",    "hint": "Scales out3 (raw modal magnitude) — no hard ceiling on effective range"},
        {"name": "bypass",        "type": "bypass"},
    ],

    "outlets": [
        {"comment": "luma"},
        {"comment": "vecfield", "signal_type": "float32"},
        {"comment": "magnitude"},
    ],

    "codebox": CODEBOX,
}
