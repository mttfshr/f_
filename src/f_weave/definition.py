patcher = {
    "name":               "f_weave",
    "prefix":             "weave",
    "object_name":        "weave_pix",
    "title":              "Weave",
    # Two optional inlets (Matt, 2026-11-01; the vecfield inlet 2 was retired the same day): 0 = across scalar, 1 = along
    # scalar. Both optional: with nothing connected weave draws straight lines at `angle`. driving_inlet makes
    # mod_inlets[0] share outer inlet 0 (texture + control); each inlet has its own vs_inState and connected flag.
    # Three more mod_inlets entries are TAGGED modulation textures (mod_inlets "tag", build/spec.md): they arrive on
    # inlet 0 as `<tag> jit_gl_texture <name>` (`prepend weight_tex` etc. upstream), have no inlet of their own, and
    # modulate weight, irreg and marklen (ideas/named_mod_textures.md, G-weave-scope Q10).
    "archetype":          "processor",
    "driving_inlet":      True,

    # Output follows the render size (render_dim, size_stages only; the codebox reads `norm`, not `dim`). Without
    # `@adapt 0` an unconnected pix adapts to vs_black, a 1x1 texture (inferred; seen on f_stipple). pix_attrs replaces
    # pix_type, so the old `@type char` is written out here.
    "pix_attrs":          "@adapt 0 @dim 256 256 @type char",
    "render_dim":         {"size_stages": ["primary"]},

    "presentation_width":  232,
    "presentation_height": 180,

    "outlets": [
        {"comment": "texture out"},
    ],

    "mod_inlets": [
        {"label": "across in",   "vs_instate": True, "state_param": "src_potential"},   # in1: replaces across; tints
        {"label": "along in",    "vs_instate": True, "state_param": "src_along"},       # in2: replaces along
        # tagged modulation textures: pix inlets in3..in5, each with its vs_inState and connected flag, no outer inlet
        {"label": "weight tex",  "tag": "weight_tex",  "vs_instate": True, "state_param": "src_weight"},    # in3
        {"label": "irreg tex",   "tag": "irreg_tex",   "vs_instate": True, "state_param": "src_irreg"},     # in4
        {"label": "marklen tex", "tag": "marklen_tex", "vs_instate": True, "state_param": "src_marklen"},   # in5
    ],

    "params": [
        {"name": "density",    "type": "float", "min": 0.0,  "max": 1.0, "default": 0.5,  "hint": "Line spacing and mark frequency (log-mapped; up to 64 cells across, 2026-11-01)."},
        {"name": "angle",      "type": "float", "min": 0.0,  "max": 1.0, "default": 0.0,  "hint": "Global line orientation (0-1 maps to 0-π)."},
        {"name": "weight",     "type": "float", "min": 0.0,  "max": 1.0, "default": 0.1,  "hint": "Line thickness — across-line mark extent (1.0 = fills the cell, edges at half level)."},
        {"name": "marklen",    "type": "float", "min": 0.0,  "max": 1.0, "default": 0.3,  "hint": "Mark length along line direction (1.0 = fills the cell, edges at half level)."},
        {"name": "offset",     "type": "float", "min": 0.0,  "max": 1.0, "default": 0.5,  "hint": "Per-line offset along the line: 0 = marks line up across lines (grid-like), 1 = each line fully offset (the old `regularity`, inverted)."},
        {"name": "phase",      "type": "float", "min": -1.0, "max": 1.0, "default": 0.0,  "hint": "Animation phase — scrolls marks along line direction."},
        {"name": "softness",   "type": "float", "min": 0.0,  "max": 2.0, "default": 0.0,  "label": "Soft", "hint": "Edge softness — 0=crisp edge at weight/marklen, 1=feather from the line centre out to 2x weight/marklen, >1 feathers further out."},
        {"name": "variant",    "type": "menu", "options": ["Off", "Wobble", "Smooth", "Hashed", "Both"], "default": 0, "label": "Variant",
         "hint": "Irregularity. Off = none. Wobble = smooth noise nudges the line position. Smooth = continuous noise along each line modulates weight and marklen. Hashed = one random value per mark (grid-leaning). Both = wobble + smooth. Irreg sets the depth, Noise the frequency."},
        {"name": "irreg",      "type": "float", "min": 0.0,  "max": 1.0, "default": 0.5,  "hint": "Irregularity depth for the chosen variant (and the base the irreg_tex texture adds to)."},
        {"name": "nscale",     "type": "float", "min": 0.0,  "max": 1.0, "default": 0.5,  "label": "Noise", "hint": "Noise frequency along the line / across the field, log-mapped from one change per 8 cells (0) to 4 per cell (1). Around 0.6 is roughly one change per mark."},
        {"name": "weight_m",   "type": "float", "min": 0.0,  "max": 1.0, "default": 0.0,  "widget": "numbox", "label": "weight_tex", "hint": "Depth of the texture tagged weight_tex on inlet 0 (`prepend weight_tex` upstream); 0 = ignored. weight_eff = weight + depth * texture, read raw or bipolar per Tex mode."},
        {"name": "irreg_m",    "type": "float", "min": 0.0,  "max": 1.0, "default": 0.0,  "widget": "numbox", "label": "irreg_tex", "hint": "Depth of the texture tagged irreg_tex on inlet 0 (`prepend irreg_tex` upstream); 0 = ignored. Adds to Irreg."},
        {"name": "marklen_m",  "type": "float", "min": 0.0,  "max": 1.0, "default": 0.0,  "widget": "numbox", "label": "marklen_tex", "hint": "Depth of the texture tagged marklen_tex on inlet 0 (`prepend marklen_tex` upstream); 0 = ignored. Adds to Marklen."},
        {"name": "mmode",      "type": "text_button", "options": ["Tex uni", "Tex bi"], "default": 0, "label": "Mod mode",
         "hint": "How the tagged modulation textures are read. Tex uni = raw 0..1 (can only add). Tex bi = rescaled to -1..1 (mid-gray = no change, dark subtracts). Modelled on vs_displacement's mode switch."},
        {"name": "src_potential", "type": "internal"},
        {"name": "src_along",     "type": "internal"},
        {"name": "src_weight",    "type": "internal"},
        {"name": "src_irreg",     "type": "internal"},
        {"name": "src_marklen",   "type": "internal"},
        {"name": "bypass",        "type": "bypass"},
    ],

    "codebox": """\
// Helpers (declared before Params; Param values are not visible inside, so everything is passed in).
hash21(a, b) {
    return fract(sin(a * 127.1 + b * 311.7) * 43758.5453);
}
vnoise(a, b) {
    ia = floor(a);
    ib = floor(b);
    fa = a - ia;
    fb = b - ib;
    sa = fa * fa * (3.0 - 2.0 * fa);
    sb = fb * fb * (3.0 - 2.0 * fb);
    h00 = hash21(ia, ib);
    h10 = hash21(ia + 1.0, ib);
    h01 = hash21(ia, ib + 1.0);
    h11 = hash21(ia + 1.0, ib + 1.0);
    return mix(mix(h00, h10, sa), mix(h01, h11, sa), sb);
}

Param variant(0.0);
Param irreg(0.5);
Param nscale(0.5);
Param weight_m(0.0);
Param irreg_m(0.0);
Param marklen_m(0.0);
Param mmode(0.0);
Param src_weight(0.0);
Param src_irreg(0.0);
Param src_marklen(0.0);
Param density(0.5);
Param angle(0.0);
Param weight(0.1);
Param marklen(0.3);
Param offset(0.5);
Param phase(0.0);
Param softness(0.0);
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

// Along scalar (in2) replaces the along coordinate when connected; phase and offset still apply on top.
along = mix(along_rot, sample(in2, norm).x, src_along);

// ─── Density scale (log-mapped) ───────────────────────────────────────────────

// 2026-11-01 (Matt): top end extended from 16 to 64 cells across so the frame can be packed. Below density 0.5 the
// curve is unchanged (exponent 5d-1, 0.5..2.8 cells; default 0.5 untouched); above 0.5 it steepens (9 per unit) to
// reach exponent 6 (64) at density 1.0. Saved density values above 0.5 now read denser than before.
density_scale = pow(2.0, density * 5.0 - 1.0 + 4.0 * max(density - 0.5, 0.0));

// ─── Variant weights (variant 0 = no irregularity: the plain mark pattern) ─
// 1 wobble, 2 smooth modulation, 3 hashed per-mark jitter, 4 wobble + smooth modulation.

vi = floor(variant + 0.5);
w_wob    = (vi == 1) + (vi == 4);
w_smooth = (vi == 2) + (vi == 4);
w_hash   = (vi == 3);
k = 0.125 * pow(2.0, nscale * 5.0);

// ─── Named modulation textures (in3 weight_tex, in4 irreg_tex, in5 marklen_tex) ─
// effective = global + depth * tex, as vs_displacement does for x/xm etc. mmode 0 reads the texture raw (0..1), mmode 1
// rescales it to -1..1 (mid-gray = no change). DEVIATION from vs_displacement: the term is also multiplied by the
// target's connected flag (src_weight / src_irreg / src_marklen, from its vs_inState), so a target nothing was tagged
// for leaves the dial untouched whatever fallback texture vs_inState substitutes (same pattern as src_potential).

tw = mix(sample(in3, norm).x, sample(in3, norm).x * 2.0 - 1.0, mmode);
ti = mix(sample(in4, norm).x, sample(in4, norm).x * 2.0 - 1.0, mmode);
tl = mix(sample(in5, norm).x, sample(in5, norm).x * 2.0 - 1.0, mmode);
weight_g  = clamp(weight  + src_weight  * weight_m  * tw, 0.0, 1.0);
irreg_g   = clamp(irreg   + src_irreg   * irreg_m   * ti, 0.0, 1.0);
marklen_g = clamp(marklen + src_marklen * marklen_m * tl, 0.0, 1.0);

// ─── Line wobble (variants 1, 4) ──────────────────────────────────────────────
// Smooth 2D noise of the undisplaced cell coordinates (u0, v0) nudges the line position across, up to +-0.4 cell.
// The index below is taken from the DISPLACED coordinate, so it always agrees with fract() and a line never changes
// identity mid-length (the spec's curl failure was a per-pixel angle; this is a smooth displacement of one axis).
// The noise ignores line_hash, so neighbouring lines wobble together (flowing, not independent).

u0 = across * density_scale;
v0 = along * density_scale + phase;
wob = (vnoise(u0 * k, v0 * k) - 0.5) * 2.0;
u = u0 + wob * irreg_g * 0.4 * w_wob;

// ─── Distance to nearest line ─────────────────────────────────────────────────

dist_to_line = abs(fract(u) - 0.5);

// ─── Per-line phase offset ────────────────────────────────────────────────────

line_idx = floor(u);
line_hash = fract(sin(line_idx * 127.1) * 43758.5453) * clamp(offset, 0.0, 1.0);
pos = along * density_scale + phase + line_hash;
dist_to_mark = abs(fract(pos) - 0.5);

// ─── Mark irregularity (variants 2, 3, 4) ─────────────────────────────────────
// Smooth (2, 4): 1D value noise along the line, its own stream per line (seeded by line_idx), frequency k. No slot
// index, so marks vary continuously across what would be mark boundaries (low nscale = pressure drift, ~0.6 = a
// change per mark). Hashed (3): the control, one random value per mark from floor(pos); it steps at mark boundaries
// and is visible as a seam once a mark is longer than half a cell.

lseed = hash21(line_idx, 3.0) * 97.0;
sm_w = (vnoise(pos * k, lseed) - 0.5) * 2.0;
sm_l = (vnoise(pos * k + 41.0, lseed + 13.0) - 0.5) * 2.0;
mark_idx = floor(pos);
hs_w = (hash21(mark_idx, line_idx) - 0.5) * 2.0;
hs_l = (hash21(mark_idx + 17.0, line_idx + 5.0) - 0.5) * 2.0;
mod_w = sm_w * w_smooth + hs_w * w_hash;
mod_l = sm_l * w_smooth + hs_l * w_hash;
weight_e  = clamp(weight_g  * (1.0 + irreg_g * mod_w), 0.0, 1.0);
marklen_e = clamp(marklen_g * (1.0 + irreg_g * mod_l), 0.0, 1.0);

// ─── Edge falloff ─────────────────────────────────────────────────────────────
// 2026-11-01 (Matt): softness 0 = crisp, 1 = soft. The feather runs from inner = w*max(1-softness,0) to
// outer = w*(1+softness): softness >= 1 is the old behaviour exactly (inner 0, outer w*(1+softness)); softness -> 0
// closes the band onto the hard edge at w. `aa` keeps a minimum band (cell units) so the crisp edge stays
// anti-aliased and smoothstep never sees equal edges. Applied to both axes (weight across, marklen along).

aa = 0.01;
outer_across = weight_e + softness * weight_e;
inner_across = min(weight_e * max(1.0 - softness, 0.0), outer_across - aa);
outer_along  = marklen_e + softness * marklen_e;
inner_along  = min(marklen_e * max(1.0 - softness, 0.0), outer_along - aa);
edge_across = smoothstep(outer_across, inner_across, dist_to_line);
edge_along  = smoothstep(outer_along,  inner_along,  dist_to_mark);

// ─── Mark ────────────────────────────────────────────────────────────────────

mark = edge_across * edge_along;

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


# ─── Presentation layout (2026-11-01, Matt: compact; mod amounts under the dial they modulate, as in f_grain) ─────────
# Row 1: density angle offset phase softness. Row 2: marklen weight irreg noise. (`shape` removed, Matt 2026-11-01.) The Variant menu and the
# Tex uni/bi toggle sit in the title bar (Matt, 2026-11-01), which is why the title is just "Weave". The three texture-depth numboxes sit directly under the dial they modulate (weight,
# marklen, irreg), 34 x 15 px, centred, with no label of their own: the dial's label names them and the hint gives the tag
# (`<dial>_tex`, prepended on inlet 0). The menu is 44 px wide, centred on its slot, so it clears the neighbouring dials
# (their boxes end 10 px before / start 37 px after the slot). The builder's grid is only a default; overrides replace it.

_PITCH = 37.0
_X0 = 6.0
_TEX_BG = [0.07, 0.13, 0.26, 1.0]   # dark blue (the header glyph colour family): marks the texture-depth numboxes
_ROW1_Y, _ROW2_Y = 38.0, 117.0     # dial tops; a label sits 18 px above, a numbox 42 px below (f_grain's 80 under 38)


def _col(i):
    return _X0 + i * _PITCH


def _centre(i):
    return _col(i) + 13.5          # centre of a 27 px dial in column i


def _dial(name, i, y):
    return {f"{name}.ctl":   {"presentation_rect": [_col(i), y, 27.0, 43.0]},
            f"{name}.label": {"presentation_rect": [_col(i) - 11.5, y - 18.0, 50.0, 18.0]}}


def _depth(name, i, y):
    """The depth numbox under the dial in column i; its own label is hidden."""
    return {f"{name}.ctl":   {"presentation_rect": [_col(i) - 3.5, y + 42.0, 34.0, 15.0],
                              "activebgcolor": _TEX_BG},
            f"{name}.label": {"hidden": 1}}


_ov = {"bypass_jsui": {"presentation_rect": [208.0, 5.0, 18.0, 12.0]},
       "title":        {"presentation_rect": [10.5, 0.0, 44.0, 21.0]},
       # the two mode controls live in the title bar: [Variant menu] [Tex uni/bi toggle]; the menu has no label there
       "variant.label": {"hidden": 1},
       "variant.ctl":   {"presentation_rect": [58.0, 3.0, 44.0, 15.0]},
       "mmode.ctl":     {"presentation_rect": [106.0, 2.0, 54.0, 17.0]}}
for _i, _n in enumerate(["density", "angle", "offset", "phase", "softness"]):      # row 1
    _ov.update(_dial(_n, _i, _ROW1_Y))
for _i, _n in enumerate(["marklen", "weight", "irreg", "nscale"]):                          # row 2
    _ov.update(_dial(_n, _i, _ROW2_Y))
_ov.update(_depth("marklen_m", 0, _ROW2_Y))                                                 # depth numboxes: under their dials
_ov.update(_depth("weight_m",  1, _ROW2_Y))
_ov.update(_depth("irreg_m",   2, _ROW2_Y))
patcher["overrides"] = _ov
