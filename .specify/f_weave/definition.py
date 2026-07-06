patcher = {
    "name":               "f_weave",
    "prefix":             "weave",
    "object_name":        "weave_pix",
    "title":              "Weave",
    "archetype":          "processor",
    "pix_type":           "char",

    "presentation_width":  220,
    "presentation_height": 160,

    "outlets": [
        {"comment": "texture out"},
    ],

    "mod_inlets": [
        {
            "label":       "scalar in",
            "vs_instate":  True,
            "state_param": "src_potential",
        },
    ],

    "params": [
        {"name": "density",    "type": "float", "min": 0.0,  "max": 1.0, "default": 0.5,  "hint": "Line spacing and mark frequency (log-mapped)."},
        {"name": "angle",      "type": "float", "min": 0.0,  "max": 1.0, "default": 0.0,  "hint": "Global line orientation (0-1 maps to 0-π)."},
        {"name": "weight",     "type": "float", "min": 0.0,  "max": 0.5, "default": 0.1,  "hint": "Line thickness — across-line mark extent."},
        {"name": "marklen",    "type": "float", "min": 0.0,  "max": 0.5, "default": 0.3,  "hint": "Mark length along line direction."},
        {"name": "regularity", "type": "float", "min": 0.0,  "max": 1.0, "default": 0.5,  "hint": "1=lines in phase (grid-like), 0=fully varied per-line offset."},
        {"name": "phase",      "type": "float", "min": -1.0, "max": 1.0, "default": 0.0,  "hint": "Animation phase — scrolls marks along line direction."},
        {"name": "src_potential", "type": "internal"},
        {"name": "bypass",        "type": "bypass"},
    ],

    "codebox": """\
Param density(0.5);
Param angle(0.0);
Param weight(0.1);
Param marklen(0.3);
Param regularity(0.5);
Param phase(0.0);
Param src_potential(0.0);
Param bypass(0.0);

// ─── Orientation ─────────────────────────────────────────────────────────────

vx = sample(in1, norm).x - 0.5;
vy = sample(in1, norm).y - 0.5;

base_cs = cos(angle * pi);
base_sn = sin(angle * pi);

cs = base_cs + (-vy);
sn = base_sn + vx;

mag = sqrt(cs * cs + sn * sn);
cs = cs / max(mag, 0.0001);
sn = sn / max(mag, 0.0001);

across_rot = norm.x * cs + norm.y * sn;
along      = norm.x * (-sn) + norm.y * cs;

// ─── Scalar potential override ────────────────────────────────────────────────

across_pot = sample(in2, norm).x;
across = mix(across_rot, across_pot, src_potential);

// ─── Density scale (log-mapped) ───────────────────────────────────────────────

density_scale = pow(2.0, density * 5.0 - 1.0);

// ─── Distance to nearest line ─────────────────────────────────────────────────

dist_to_line = abs(fract(across * density_scale) - 0.5);

// ─── Per-line phase offset ────────────────────────────────────────────────────

line_idx = floor(across * density_scale);
line_hash = fract(sin(line_idx * 127.1) * 43758.5453) * (1.0 - clamp(regularity, 0.0, 1.0));
pos = along * density_scale + phase + line_hash;
dist_to_mark = abs(fract(pos) - 0.5);

// ─── Mark ────────────────────────────────────────────────────────────────────

mark = smoothstep(weight, 0.0, dist_to_line) * smoothstep(marklen, 0.0, dist_to_mark);

// ─── Output ───────────────────────────────────────────────────────────────────

cr = mix(1.0, sample(in2, norm).x, src_potential);
cg = mix(1.0, sample(in2, norm).y, src_potential);
cb = mix(1.0, sample(in2, norm).z, src_potential);

out1 = mix(vec(cr * mark, cg * mark, cb * mark, 1.0), vec(0.0, 0.0, 0.0, 1.0), bypass);
""",
}
