# f_grain patcher definition
# Input to tools/build_patcher.py
# Last updated: 2026-06-05

CODEBOX = """\
Param src_mode(0.0);
Param density(0.5);
Param amount(0.5);
Param era_clock(0.0);
Param bypass(0.0);
Param size(0.0);
Param size_var(0.0);
Param shape(0.5);
Param softness(0.0);
Param jitter(0.0);
Param fade(0.0);
Param ch_diverge(0.0);
Param luma_gate(0.0);
Param displace(0.0);
Param edge_mode(2.0);
Param field(0.0);
Param sv_seed(0.0);

uv = norm;
src = mix(vec(0.5, 0.5, 0.5, 1.0), sample(in1, uv), src_mode);

// cell identities pinned to fixed_res
fixed_res = 4096.0;
size_scale = pow(2.0, mix(0.0, 12.0, size));
aspect = dim.x / dim.y;
aspect_sq = aspect * aspect;

px = uv.x * fixed_res * aspect / size_scale;
py = uv.y * fixed_res / size_scale;
icx = floor(px);
icy = floor(py);

f0 = floor(field); f1 = f0 + 1.0; bf = fract(field);

ncx = icx-1.0; ncy = icy-1.0;
jxA = mix(fract(sin((ncx+f0)*17543.2+(ncy+f0)*8976.5)*43758.5453)-0.5, fract(sin((ncx+f1)*17543.2+(ncy+f1)*8976.5)*43758.5453)-0.5, bf);
jyA = mix(fract(sin((ncx+f0)*5432.1+(ncy+f0)*13579.8)*43758.5453)-0.5, fract(sin((ncx+f1)*5432.1+(ncy+f1)*13579.8)*43758.5453)-0.5, bf);
dxA = px-(ncx+0.5+jxA*jitter); dyA = py-(ncy+0.5+jyA*jitter);
dA = dxA*dxA+dyA*dyA; gxA = (ncx+0.5)/fixed_res; gyA = (ncy+0.5)/fixed_res;

ncx = icx; ncy = icy-1.0;
jxB = mix(fract(sin((ncx+f0)*17543.2+(ncy+f0)*8976.5)*43758.5453)-0.5, fract(sin((ncx+f1)*17543.2+(ncy+f1)*8976.5)*43758.5453)-0.5, bf);
jyB = mix(fract(sin((ncx+f0)*5432.1+(ncy+f0)*13579.8)*43758.5453)-0.5, fract(sin((ncx+f1)*5432.1+(ncy+f1)*13579.8)*43758.5453)-0.5, bf);
dxB = px-(ncx+0.5+jxB*jitter); dyB = py-(ncy+0.5+jyB*jitter);
dB = dxB*dxB+dyB*dyB; gxB = (ncx+0.5)/fixed_res; gyB = (ncy+0.5)/fixed_res;

ncx = icx+1.0; ncy = icy-1.0;
jxC = mix(fract(sin((ncx+f0)*17543.2+(ncy+f0)*8976.5)*43758.5453)-0.5, fract(sin((ncx+f1)*17543.2+(ncy+f1)*8976.5)*43758.5453)-0.5, bf);
jyC = mix(fract(sin((ncx+f0)*5432.1+(ncy+f0)*13579.8)*43758.5453)-0.5, fract(sin((ncx+f1)*5432.1+(ncy+f1)*13579.8)*43758.5453)-0.5, bf);
dxC = px-(ncx+0.5+jxC*jitter); dyC = py-(ncy+0.5+jyC*jitter);
dC = dxC*dxC+dyC*dyC; gxC = (ncx+0.5)/fixed_res; gyC = (ncy+0.5)/fixed_res;

ncx = icx-1.0; ncy = icy;
jxD = mix(fract(sin((ncx+f0)*17543.2+(ncy+f0)*8976.5)*43758.5453)-0.5, fract(sin((ncx+f1)*17543.2+(ncy+f1)*8976.5)*43758.5453)-0.5, bf);
jyD = mix(fract(sin((ncx+f0)*5432.1+(ncy+f0)*13579.8)*43758.5453)-0.5, fract(sin((ncx+f1)*5432.1+(ncy+f1)*13579.8)*43758.5453)-0.5, bf);
dxD = px-(ncx+0.5+jxD*jitter); dyD = py-(ncy+0.5+jyD*jitter);
dD = dxD*dxD+dyD*dyD; gxD = (ncx+0.5)/fixed_res; gyD = (ncy+0.5)/fixed_res;

ncx = icx; ncy = icy;
jxE = mix(fract(sin((ncx+f0)*17543.2+(ncy+f0)*8976.5)*43758.5453)-0.5, fract(sin((ncx+f1)*17543.2+(ncy+f1)*8976.5)*43758.5453)-0.5, bf);
jyE = mix(fract(sin((ncx+f0)*5432.1+(ncy+f0)*13579.8)*43758.5453)-0.5, fract(sin((ncx+f1)*5432.1+(ncy+f1)*13579.8)*43758.5453)-0.5, bf);
dxE = px-(ncx+0.5+jxE*jitter); dyE = py-(ncy+0.5+jyE*jitter);
dE = dxE*dxE+dyE*dyE; gxE = (ncx+0.5)/fixed_res; gyE = (ncy+0.5)/fixed_res;

ncx = icx+1.0; ncy = icy;
jxF = mix(fract(sin((ncx+f0)*17543.2+(ncy+f0)*8976.5)*43758.5453)-0.5, fract(sin((ncx+f1)*17543.2+(ncy+f1)*8976.5)*43758.5453)-0.5, bf);
jyF = mix(fract(sin((ncx+f0)*5432.1+(ncy+f0)*13579.8)*43758.5453)-0.5, fract(sin((ncx+f1)*5432.1+(ncy+f1)*13579.8)*43758.5453)-0.5, bf);
dxF = px-(ncx+0.5+jxF*jitter); dyF = py-(ncy+0.5+jyF*jitter);
dF = dxF*dxF+dyF*dyF; gxF = (ncx+0.5)/fixed_res; gyF = (ncy+0.5)/fixed_res;

ncx = icx-1.0; ncy = icy+1.0;
jxG = mix(fract(sin((ncx+f0)*17543.2+(ncy+f0)*8976.5)*43758.5453)-0.5, fract(sin((ncx+f1)*17543.2+(ncy+f1)*8976.5)*43758.5453)-0.5, bf);
jyG = mix(fract(sin((ncx+f0)*5432.1+(ncy+f0)*13579.8)*43758.5453)-0.5, fract(sin((ncx+f1)*5432.1+(ncy+f1)*13579.8)*43758.5453)-0.5, bf);
dxG = px-(ncx+0.5+jxG*jitter); dyG = py-(ncy+0.5+jyG*jitter);
dG = dxG*dxG+dyG*dyG; gxG = (ncx+0.5)/fixed_res; gyG = (ncy+0.5)/fixed_res;

ncx = icx; ncy = icy+1.0;
jxH = mix(fract(sin((ncx+f0)*17543.2+(ncy+f0)*8976.5)*43758.5453)-0.5, fract(sin((ncx+f1)*17543.2+(ncy+f1)*8976.5)*43758.5453)-0.5, bf);
jyH = mix(fract(sin((ncx+f0)*5432.1+(ncy+f0)*13579.8)*43758.5453)-0.5, fract(sin((ncx+f1)*5432.1+(ncy+f1)*13579.8)*43758.5453)-0.5, bf);
dxH = px-(ncx+0.5+jxH*jitter); dyH = py-(ncy+0.5+jyH*jitter);
dH = dxH*dxH+dyH*dyH; gxH = (ncx+0.5)/fixed_res; gyH = (ncy+0.5)/fixed_res;

ncx = icx+1.0; ncy = icy+1.0;
jxI = mix(fract(sin((ncx+f0)*17543.2+(ncy+f0)*8976.5)*43758.5453)-0.5, fract(sin((ncx+f1)*17543.2+(ncy+f1)*8976.5)*43758.5453)-0.5, bf);
jyI = mix(fract(sin((ncx+f0)*5432.1+(ncy+f0)*13579.8)*43758.5453)-0.5, fract(sin((ncx+f1)*5432.1+(ncy+f1)*13579.8)*43758.5453)-0.5, bf);
dxI = px-(ncx+0.5+jxI*jitter); dyI = py-(ncy+0.5+jyI*jitter);
dI = dxI*dxI+dyI*dyI; gxI = (ncx+0.5)/fixed_res; gyI = (ncy+0.5)/fixed_res;

best_d = dA; second_best_d = 9999.0; best_gx = gxA; best_gy = gyA;
t = step(dB,best_d); second_best_d=mix(min(second_best_d,dB),best_d,t); best_d=mix(best_d,dB,t); best_gx=mix(best_gx,gxB,t); best_gy=mix(best_gy,gyB,t);
t = step(dC,best_d); second_best_d=mix(min(second_best_d,dC),best_d,t); best_d=mix(best_d,dC,t); best_gx=mix(best_gx,gxC,t); best_gy=mix(best_gy,gyC,t);
t = step(dD,best_d); second_best_d=mix(min(second_best_d,dD),best_d,t); best_d=mix(best_d,dD,t); best_gx=mix(best_gx,gxD,t); best_gy=mix(best_gy,gyD,t);
t = step(dE,best_d); second_best_d=mix(min(second_best_d,dE),best_d,t); best_d=mix(best_d,dE,t); best_gx=mix(best_gx,gxE,t); best_gy=mix(best_gy,gyE,t);
t = step(dF,best_d); second_best_d=mix(min(second_best_d,dF),best_d,t); best_d=mix(best_d,dF,t); best_gx=mix(best_gx,gxF,t); best_gy=mix(best_gy,gyF,t);
t = step(dG,best_d); second_best_d=mix(min(second_best_d,dG),best_d,t); best_d=mix(best_d,dG,t); best_gx=mix(best_gx,gxG,t); best_gy=mix(best_gy,gyG,t);
t = step(dH,best_d); second_best_d=mix(min(second_best_d,dH),best_d,t); best_d=mix(best_d,dH,t); best_gx=mix(best_gx,gxH,t); best_gy=mix(best_gy,gyH,t);
t = step(dI,best_d); second_best_d=mix(min(second_best_d,dI),best_d,t); best_d=mix(best_d,dI,t); best_gx=mix(best_gx,gxI,t); best_gy=mix(best_gy,gyI,t);

nearest_dist = sqrt(best_d);
second_nearest_dist = sqrt(second_best_d);

disp_x = (fract(sin(best_gx * 127.1 + best_gy * 311.7) * 43758.5453) - 0.5) * displace;
disp_y = (fract(sin(best_gx * 269.5 + best_gy * 183.3) * 43758.5453) - 0.5) * displace;
uv_d_raw_x = uv.x + disp_x;
uv_d_raw_y = uv.y + disp_y;
in_bounds = step(0.0, uv_d_raw_x) * step(uv_d_raw_x, 1.0) * step(0.0, uv_d_raw_y) * step(uv_d_raw_y, 1.0);
uv_d = uv;
disp_mask = 1.0;
if (edge_mode < 0.5) {
    uv_d = vec(clamp(uv_d_raw_x, 0.0, 1.0), clamp(uv_d_raw_y, 0.0, 1.0));
    disp_mask = in_bounds;
} else if (edge_mode < 1.5) {
    uv_d = vec(clamp(uv_d_raw_x, 0.0, 1.0), clamp(uv_d_raw_y, 0.0, 1.0));
} else if (edge_mode < 2.5) {
    uv_d = vec(fract(uv_d_raw_x), fract(uv_d_raw_y));
} else {
    uv_d = vec(1.0 - abs(fract(uv_d_raw_x * 0.5) * 2.0 - 1.0), 1.0 - abs(fract(uv_d_raw_y * 0.5) * 2.0 - 1.0));
}

p1 = fract(sin(best_gx * 127.1 + best_gy * 311.7) * 43758.5453);
p2 = fract(sin(p1 * 263.77) * 43758.5453);
era_raw = era_clock + p2;
era = floor(era_raw);
era_phase = fract(era_raw);

grain_a = fract(sin(era * 127.1 + p1 * 311.7) * 43758.5453);
grain_mono = grain_a;

col_g = fract(sin(best_gx * 91.3 + best_gy * 57.2) * 43758.5453) - 0.5;
col_b = fract(sin(best_gx * 43.1 + best_gy * 123.7) * 43758.5453) - 0.5;

grain_r = grain_mono;
grain_g = grain_mono + col_g * ch_diverge;
grain_b = grain_mono + col_b * ch_diverge;

sign_a = fract(sin(era * 263.7 + p1 * 419.2) * 43758.5453) * 2.0 - 1.0;
grain_sign = sign_a;

ramp = min(fade * 0.125, 0.5);
safe_ramp = max(ramp, 0.001);
fade_in = smoothstep(0.0, safe_ramp, era_phase);
fade_out = 1.0 - smoothstep(1.0 - safe_ramp, 1.0, era_phase);
grain_intensity = min(fade_in, fade_out);

voronoi_boundary_dist = (nearest_dist + second_nearest_dist) * 0.5;
t_circ = nearest_dist / 0.5;
t_voro = nearest_dist / max(voronoi_boundary_dist, 0.001);
shape_t = mix(t_voro, t_circ, shape);

sv0 = floor(sv_seed); sv1 = sv0 + 1.0; svf = fract(sv_seed);
cell_size_a = fract(sin((best_gx + sv0) * 213.7 + (best_gy + sv0) * 157.3) * 43758.5453);
cell_size_b = fract(sin((best_gx + sv1) * 213.7 + (best_gy + sv1) * 157.3) * 43758.5453);
cell_size = mix(1.0, mix(cell_size_a, cell_size_b, svf), size_var);
shape_t = shape_t / max(cell_size, 0.001);

feather = mix(0.02, 0.5, softness);
soft_falloff = 1.0 - smoothstep(1.0 - feather, 1.0, shape_t);

visible = step(1.0 - density, grain_r);

src_displaced = mix(src, sample(in1, uv_d), visible * soft_falloff * grain_intensity * disp_mask);

gr = grain_sign * visible * soft_falloff * grain_intensity * amount;
gg = (grain_sign + col_g * ch_diverge) * visible * soft_falloff * grain_intensity * amount;
gb = (grain_sign + col_b * ch_diverge) * visible * soft_falloff * grain_intensity * amount;

luma = 0.299*src.r + 0.587*src.g + 0.114*src.b;
luma_weight = mix(1.0 - luma, luma, luma_gate * 0.5 + 0.5);
luma_weight = pow(luma_weight, mix(1.0, 3.0, abs(luma_gate)));
luma_mod = mix(1.0, luma_weight, clamp(abs(luma_gate) * 2.0, 0.0, 1.0));
gr *= luma_mod;
gg *= luma_mod;
gb *= luma_mod;
composited = vec(src_displaced.r + gr, src_displaced.g + gg, src_displaced.b + gb, src_displaced.a);
raw = vec(grain_sign * visible * soft_falloff * grain_intensity, grain_sign * visible * soft_falloff * grain_intensity, grain_sign * visible * soft_falloff * grain_intensity, 1.0);

effective_bp = 1.0 - bypass;
out1 = mix(src, composited, effective_bp);
out2 = raw;
out3 = mix(src, src_displaced, effective_bp);
"""

patcher = {
    # Identity
    "name":                "f_grain",
    "prefix":              "grain",
    "object_name":         "grain_pix",
    "title":               "Grain",

    # Archetype
    "archetype":           "dual",

    # Presentation panel size (from panel obj-24 presentation_rect)
    "presentation_width":  227,
    "presentation_height": 164,

    # Params — ordered as they appear in presentation layout
    # Row 1 (pres y~38): Size, S.var, Shape, Jitter, Fade, Freeze
    # Row 2 (pres y~80): sv_seed numbox, field numbox
    # Row 3 (pres y~115): Amt, Dens, Color, L.gate, Displ, edge_mode umenu
    "params": [
        {"name": "size",        "type": "float",  "min": 0.0,  "max": 1.0,  "default": 0.0,  "label": "Size",   "hint": "Grain size — exponential zoom into fixed voronoi grid"},
        {"name": "size_var",    "type": "float",  "min": 0.0,  "max": 1.0,  "default": 0.0,  "label": "S.var",  "hint": "Per-cell size variation amount"},
        {"name": "shape",       "type": "float",  "min": 0.0,  "max": 1.0,  "default": 0.5,  "label": "Shape",  "hint": "0=voronoi-conforming  1=circular"},
        {"name": "softness",    "type": "float",  "min": 0.0,  "max": 5.0,  "default": 0.0,  "label": "Soft",   "hint": "Grain edge softness -- feather = mix(0.02, 0.5, softness) in codebox, so values beyond ~1.0 just keep extrapolating past full feather with no new visual effect. Live dial's mmax=5.0 appears to be an untuned Max default (shape/jitter both got custom ranges, this one didn't) -- recorded as-is since this module predates build_patcher.py and this file is a record of the real .maxpat, not its source of truth."},
        {"name": "jitter",      "type": "float",  "min": 0.0,  "max": 2.0,  "default": 0.0,  "label": "Jitter", "hint": "Voronoi center displacement (0=grid 1=scattered)"},
        {"name": "fade",        "type": "float",  "min": 0.0,  "max": 4.0,  "default": 0.0,  "label": "Fade",   "hint": "Grain crossfade duration at era boundaries"},
        {"name": "persistence", "type": "float",  "min": 0.0,  "max": 1.0,  "default": 1.0,  "label": "Freeze", "hint": "Temporal persistence (0=boil 1=frozen) — scales era_clock in parent patch"},
        {"name": "sv_seed",     "type": "numbox", "min": 0.0,  "max": 5.0,  "default": 0.0,  "label": None,     "hint": "Size variation seed — interpolates between hash fields"},
        {"name": "field",       "type": "numbox", "min": 0.0,  "max": 5.0,  "default": 0.0,  "label": None,     "hint": "Voronoi topology seed — interpolates between hash fields"},
        {"name": "amount",      "type": "float",  "min": 0.0,  "max": 2.0,  "default": 1.0,  "label": "Amt",    "hint": "Grain blend weight"},
        {"name": "density",     "type": "float",  "min": 0.0,  "max": 1.0,  "default": 0.5,  "label": "Dens",   "hint": "Fraction of cells that are visible"},
        {"name": "ch_diverge",  "type": "float",  "min": 0.0,  "max": 1.0,  "default": 0.0,  "label": "Color",  "hint": "Per-cell chromatic divergence (0=monochrome)"},
        {"name": "luma_gate",   "type": "float",  "min": -1.0, "max": 1.0,  "default": 0.0,  "label": "L.gate", "hint": "Luma gate: -1=shadows only  0=uniform  +1=highlights only"},
        {"name": "displace",    "type": "float",  "min": 0.0,  "max": 0.5,  "default": 0.0,  "label": "Displ",  "hint": "Per-grain UV displacement amount"},
        {"name": "edge_mode",   "type": "umenu",  "items": ["Clear", "Clamp", "Wrap", "Mirror"], "default": 2, "hint": "Displacement edge handling mode"},
        {"name": "era_clock",   "type": "internal"},  # driven by persistence chain in parent patch
        {"name": "src_mode",    "type": "internal"},  # driven by vs_inState
        {"name": "bypass",      "type": "bypass"},
    ],

    # Outlets: out1=composite, out2=grain mask, out3=displaced source only
    "outlets": [
        {"comment": "composite"},
        {"comment": "grain mask"},
        {"comment": "displaced"},
    ],

    "codebox": CODEBOX,
}
