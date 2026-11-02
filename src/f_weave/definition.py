patcher = {
    "name":               "f_weave",
    "prefix":             "weave",
    "object_name":        "weave_pix",
    "title":              "Weave",
    "signal_type":        "\u2207 in",
    # Two optional inlets (Matt, 2026-11-01; the vecfield inlet 2 was retired the same day): 0 = across scalar, 1 = along
    # scalar. Both optional: with nothing connected weave draws straight lines at `angle`. driving_inlet makes
    # mod_inlets[0] share outer inlet 0 (texture + control); each inlet has its own vs_inState and connected flag.
    "archetype":          "processor",
    "driving_inlet":      True,

    # Output follows the render size (render_dim, size_stages only; the codebox reads `norm`, not `dim`). Without
    # `@adapt 0` an unconnected pix adapts to vs_black, a 1x1 texture (inferred; seen on f_stipple). pix_attrs replaces
    # pix_type, so the old `@type char` is written out here.
    "pix_attrs":          "@adapt 0 @dim 256 256 @type char",
    "render_dim":         {"size_stages": ["primary"]},

    "presentation_width":  220,
    "presentation_height": 219,

    "outlets": [
        {"comment": "texture out"},
    ],

    "mod_inlets": [
        {"label": "across in",   "vs_instate": True, "state_param": "src_potential"},   # in1: replaces across; tints
        {"label": "along in",    "vs_instate": True, "state_param": "src_along"},       # in2: replaces along
    ],

    "params": [
        {"name": "density",    "type": "float", "min": 0.0,  "max": 1.0, "default": 0.5,  "hint": "Line spacing and mark frequency (log-mapped; up to 64 cells across, 2026-11-01)."},
        {"name": "angle",      "type": "float", "min": 0.0,  "max": 1.0, "default": 0.0,  "hint": "Global line orientation (0-1 maps to 0-π)."},
        {"name": "weight",     "type": "float", "min": 0.0,  "max": 1.0, "default": 0.1,  "hint": "Line thickness — across-line mark extent (1.0 = fills the cell, edges at half level)."},
        {"name": "marklen",    "type": "float", "min": 0.0,  "max": 1.0, "default": 0.3,  "hint": "Mark length along line direction (1.0 = fills the cell, edges at half level)."},
        {"name": "regularity", "type": "float", "min": 0.0,  "max": 1.0, "default": 0.5,  "hint": "1=lines in phase (grid-like), 0=fully varied per-line offset."},
        {"name": "phase",      "type": "float", "min": -1.0, "max": 1.0, "default": 0.0,  "hint": "Animation phase — scrolls marks along line direction."},
        {"name": "softness",   "type": "float", "min": 0.0,  "max": 2.0, "default": 0.0,  "hint": "Edge softness — 0=crisp edge at weight/marklen, 1=feather from the line centre out to 2x weight/marklen, >1 feathers further out."},
        {"name": "shape",      "type": "float", "min": 0.0,  "max": 1.0, "default": 0.0,  "hint": "Mark profile — 0=flat-top rectangle, 1=raised cosine (calligraphic)."},
        {"name": "src_potential", "type": "internal"},
        {"name": "src_along",     "type": "internal"},
        {"name": "bypass",        "type": "bypass"},
    ],

    "codebox": """\
Param density(0.5);
Param angle(0.0);
Param weight(0.1);
Param marklen(0.3);
Param regularity(0.5);
Param phase(0.0);
Param softness(0.0);
Param shape(0.0);
Param src_potential(0.0);
Param src_along(0.0);
Param bypass(0.0);

// ─── Orientation ──────────────────────────────────────────────────────────────
// 2026-11-01 (Matt): the vecfield inlet (in3, field_amount, fix_blend, src_field) is retired; a field warp is f_vf_warp
// downstream. Orientation is the global `angle` only. History: ideas/f_weave_orientation_blend.md.

base_angle = angle * pi;
cs = cos(base_angle);
sn = sin(base_angle);

across_rot = norm.x * cs + norm.y * sn;
along_rot  = norm.x * (-sn) + norm.y * cs;

// ─── Scalar potential override ────────────────────────────────────────────────

across_pot = sample(in1, norm).x;
across = mix(across_rot, across_pot, src_potential);

// Along scalar (in2) replaces the along coordinate when connected; phase and regularity still apply on top.
along = mix(along_rot, sample(in2, norm).x, src_along);

// ─── Density scale (log-mapped) ───────────────────────────────────────────────

// 2026-11-01 (Matt): top end extended from 16 to 64 cells across so the frame can be packed. Below density 0.5 the
// curve is unchanged (exponent 5d-1, 0.5..2.8 cells; default 0.5 untouched); above 0.5 it steepens (9 per unit) to
// reach exponent 6 (64) at density 1.0. Saved density values above 0.5 now read denser than before.
density_scale = pow(2.0, density * 5.0 - 1.0 + 4.0 * max(density - 0.5, 0.0));

// ─── Distance to nearest line ─────────────────────────────────────────────────

dist_to_line = abs(fract(across * density_scale) - 0.5);

// ─── Per-line phase offset ────────────────────────────────────────────────────

line_idx = floor(across * density_scale);
line_hash = fract(sin(line_idx * 127.1) * 43758.5453) * (1.0 - clamp(regularity, 0.0, 1.0));
pos = along * density_scale + phase + line_hash;
dist_to_mark = abs(fract(pos) - 0.5);

// ─── Edge falloff ─────────────────────────────────────────────────────────────
// 2026-11-01 (Matt): softness 0 = crisp, 1 = soft. The feather runs from inner = w*max(1-softness,0) to
// outer = w*(1+softness): softness >= 1 is the old behaviour exactly (inner 0, outer w*(1+softness)); softness -> 0
// closes the band onto the hard edge at w. `aa` keeps a minimum band (cell units) so the crisp edge stays
// anti-aliased and smoothstep never sees equal edges. Applied to both axes (weight across, marklen along).

aa = 0.01;
outer_across = weight + softness * weight;
inner_across = min(weight * max(1.0 - softness, 0.0), outer_across - aa);
outer_along  = marklen + softness * marklen;
inner_along  = min(marklen * max(1.0 - softness, 0.0), outer_along - aa);
edge_across = smoothstep(outer_across, inner_across, dist_to_line);
edge_along  = smoothstep(outer_along,  inner_along,  dist_to_mark);

// ─── Shape profile (flat-top → raised cosine) ─────────────────────────────────

profile = mix(1.0, cos(clamp(dist_to_line / max(weight, 0.0001), 0.0, 1.0) * pi * 0.5), shape);

// ─── Mark ────────────────────────────────────────────────────────────────────

mark = edge_across * edge_along * profile;

// ─── Output ───────────────────────────────────────────────────────────────────

cr = mix(1.0, sample(in1, norm).x, src_potential);
cg = mix(1.0, sample(in1, norm).y, src_potential);
cb = mix(1.0, sample(in1, norm).z, src_potential);

out1 = mix(vec(cr * mark, cg * mark, cb * mark, 1.0), vec(0.0, 0.0, 0.0, 1.0), bypass);
""",
}


# Gated source-mode trigger (same pattern as f_stipple, 2026-11-01): with nothing on inlet 0, vs_inState does not make
# the pix render, so a gated `r draw` does. Connected, the gate is closed and the module renders once per frame as before.
_PIX = "obj-5"
_INSTATE = "obj-101"


def _obj(i, text, nin, nout, rect):
    return {"box": {"id": f"obj-raw-{i}", "maxclass": "newobj", "patching_rect": rect, "text": text,
                    "numinlets": nin, "numoutlets": nout, "outlettype": [""] * nout}}


def _line(src, so, dst, di):
    ref = lambda o: o if isinstance(o, str) else f"obj-raw-{o}"      # int = a raw box, str = a full id
    return {"patchline": {"source": [ref(src), so], "destination": [ref(dst), di]}}


patcher["raw_boxes"] = [
    _obj(1, "r draw",    0, 1, [1220.0, 120.0, 50.0, 22.0]),
    _obj(2, "gate 1 1",  2, 1, [1220.0, 220.0, 55.0, 22.0]),    # open at load; control inlet 0, data inlet 1
    _obj(3, "== 0",      2, 1, [1290.0, 170.0, 40.0, 22.0]),    # connected flag -> 1 when NOTHING is connected
]
patcher["raw_lines"] = [
    _line(_INSTATE, 1, 3, 0),
    _line(3, 0, 2, 0),
    _line(1, 0, 2, 1),
    _line(2, 0, _PIX, 0),
]
