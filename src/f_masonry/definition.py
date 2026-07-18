# f_masonry patcher definition
# Input to tools/build_patcher.py
# Last updated: 2026-07-05 (ADR 7 candidate-search redesign, quantize removed)
#
# Note: the codebox contains many _mod_amt_ params for modulation inlets
# (A/B/C texture inputs). These are codebox-internal and not in the route --
# they are set via vs_inState and the mod inlet system, not via named messages.
# Only the 18 params in the route object are externally addressable.

CODEBOX = """\
hash1d(x) {
    h = sin(x) * 43758.5453;
    return h - floor(h);
}

Param src_mode(0.0);
Param angle(0.0);
Param courses(8.0);
Param bond(8.0);
Param offset(0.0);
Param mortar(0.2);
Param softness(0.0);
Param regularity(1.0);
Param drift(0.0);
Param phase(0.0);
Param speed_var(0.0);
Param skip(1.0);
Param bypass(0.0);
Param width(0.9);
Param roundness(0.0);
Param course_color(0.0);
Param brick_color(0.0);
Param course_seed(0.0);
Param brick_seed(0.0);
Param aspect(1.0);

// Structural A-mod (drift/regularity/phase/skip/speed_var) DEFERRED —
// would require the search's own inputs to depend on A-sampling, which
// depends on the search's winner. Circular. Nothing currently wired to
// these targets. Declared for patcher/route compatibility, unused below.
Param drift_mod_amt_a(0.0);
Param offset_mod_amt_a(0.0);
Param speed_var_mod_amt_a(0.0);
Param regularity_mod_amt_a(0.0);
Param phase_mod_amt_a(0.0);
Param skip_mod_amt_a(0.0);
Param mortar_mod_amt_a(0.0);
Param softness_mod_amt_a(0.0);
Param width_mod_amt_a(0.0);
Param roundness_mod_amt_a(0.0);
Param course_color_mod_amt_a(0.0);
Param brick_color_mod_amt_a(0.0);

Param mortar_mod_amt_b(0.0);
Param softness_mod_amt_b(0.0);
Param width_mod_amt_b(0.0);
Param roundness_mod_amt_b(0.0);
Param course_color_mod_amt_b(0.0);
Param brick_color_mod_amt_b(0.0);

Param mortar_mod_amt_c(0.0);
Param softness_mod_amt_c(0.0);
Param width_mod_amt_c(0.0);
Param roundness_mod_amt_c(0.0);
Param course_color_mod_amt_c(0.0);
Param brick_color_mod_amt_c(0.0);

theta  = angle * (pi / 180.0);
cosT   = cos(theta);
sinT   = sin(theta);

px     = norm.x * aspect;
py     = norm.y;
along  =  px * cosT + py * sinT;
across = -px * sinT + py * cosT;

course_scale = max(courses, 0.001);
bond_scale   = max(bond, 0.001);
band_idx     = floor(across * course_scale);

cs = floor(course_seed);
bs = floor(brick_seed);

// offset special case — unaffected by candidate-search redesign, keys
// off band_idx only, no circularity with slot identity
brick_uv_offset = vec(0.5, wrap(band_idx / course_scale, 0.0, 1.0));
offset_shift = sample(in2, brick_uv_offset).r * offset_mod_amt_a;

along_shifted = along + offset_shift / bond_scale;
along_cont    = along_shifted * bond_scale + band_idx * offset;

// per-course phase/speed — raw params (structural A-mod deferred).
// phase now shifts base_along BEFORE the search (real migration while
// scrolling) instead of wrapping locally after the fact.
h3         = (band_idx + cs) * 419.2;
h3         = sin(h3) * 43758.5;
band_hash  = h3 - floor(h3);
band_speed = 1.0 + (band_hash - 0.5) * speed_var * 2.0;
band_phase = phase * band_speed;

base_along = along_cont + band_phase;
base_slot  = floor(base_along);

// Candidate search — 3 candidates, winner-take-all (ADR 7, 2026-07-05).
// Fixes the "sliced barcode" bug: slot ownership used to be a single
// floor() lookup, so drift could only reshuffle phase within a fixed,
// never-moving slot boundary. regularity is now a priority bias in the
// search itself (same shape as f_vf_seeds' field_priority) rather than
// edge-hugging within a fixed slot — breaks "same average density" at
// regularity=0 by design, confirmed in Max to read as genuinely wider
// bricks, not bricks with extra mortar. quantize REMOVED — as it
// existed, it was a pure linear scalar on drift, not an independent
// axis. Per-candidate math is inlined (not a user-defined function) —
// a user-defined multi-value return caused a silent compile failure
// (grayed-out attrui, no console-visible symptom otherwise); inlining
// uses only the confirmed-working hash1d single-return pattern.
drift_scale = drift * 0.5;
pri_scale   = (1.0 - regularity) * 0.6; // empirical starting constant — tune in Max

s_m1 = base_slot - 1.0;
s_0  = base_slot;
s_p1 = base_slot + 1.0;

drift_raw_m1 = hash1d((s_m1 + bs) * 269.5 + band_idx * 183.3) - 0.5;
pri_raw_m1   = hash1d((s_m1 + bs) * 91.7  + band_idx * 233.1) - 0.5;
cand_center_m1 = s_m1 + 0.5 + drift_raw_m1 * drift_scale;
rd_m1 = abs(base_along - cand_center_m1);
bd_m1 = rd_m1 - pri_raw_m1 * pri_scale;

drift_raw_0 = hash1d((s_0 + bs) * 269.5 + band_idx * 183.3) - 0.5;
pri_raw_0   = hash1d((s_0 + bs) * 91.7  + band_idx * 233.1) - 0.5;
cand_center_0 = s_0 + 0.5 + drift_raw_0 * drift_scale;
rd_0 = abs(base_along - cand_center_0);
bd_0 = rd_0 - pri_raw_0 * pri_scale;

drift_raw_p1 = hash1d((s_p1 + bs) * 269.5 + band_idx * 183.3) - 0.5;
pri_raw_p1   = hash1d((s_p1 + bs) * 91.7  + band_idx * 233.1) - 0.5;
cand_center_p1 = s_p1 + 0.5 + drift_raw_p1 * drift_scale;
rd_p1 = abs(base_along - cand_center_p1);
bd_p1 = rd_p1 - pri_raw_p1 * pri_scale;

is0   = step(bd_0, bd_m1);
slotA = mix(s_m1, s_0, is0);
bdA   = mix(bd_m1, bd_0, is0);
rdA   = mix(rd_m1, rd_0, is0);

isP1     = step(bd_p1, bdA);
win_slot = mix(slotA, s_p1, isP1);
win_rd   = mix(rdA, rd_p1, isP1);

mark_dist = win_rd * 2.0;

h4        = (band_idx + cs) * 591.3;
h4        = sin(h4) * 43758.5;
band_cont = h4 - floor(h4);
cont      = step(1.0 - skip, band_cont);

across_phase = wrap(across * course_scale, 0.0, 1.0);
across_dist  = abs(across_phase - 0.5) * 2.0;

// A sampling — NOW keyed to the WINNER's slot identity (search must
// run before A-sampling, reversing the pre-ADR-7 order)
brick_uv = vec(wrap(win_slot / bond_scale, 0.0, 1.0), wrap(band_idx / course_scale, 0.0, 1.0));
a_sample = sample(in2, brick_uv).r;

// B sampling — intra-brick space, position within the WINNING
// candidate's territory (not the pixel's native cell)
along_frac = wrap(base_along - win_slot, 0.0, 1.0);
b_sample = sample(in3, vec(along_frac, across_phase)).r;
c_sample = sample(in4, norm).r;

mortar_eff       = clamp(mortar       + a_sample * mortar_mod_amt_a       + b_sample * mortar_mod_amt_b       + c_sample * mortar_mod_amt_c,       0.0, 1.0);
softness_eff     = clamp(softness     + a_sample * softness_mod_amt_a     + b_sample * softness_mod_amt_b     + c_sample * softness_mod_amt_c,     0.0, 1.0);
width_eff        = clamp(width        + a_sample * width_mod_amt_a        + b_sample * width_mod_amt_b        + c_sample * width_mod_amt_c,        0.0, 2.0);
roundness_eff    = clamp(roundness    + a_sample * roundness_mod_amt_a    + b_sample * roundness_mod_amt_b    + c_sample * roundness_mod_amt_c,    0.0, 1.0);
course_color_eff = clamp(course_color + a_sample * course_color_mod_amt_a + b_sample * course_color_mod_amt_b + c_sample * course_color_mod_amt_c, 0.0, 1.0);
brick_color_eff  = clamp(brick_color  + a_sample * brick_color_mod_amt_a  + b_sample * brick_color_mod_amt_b  + c_sample * brick_color_mod_amt_c,  0.0, 1.0);

across_d   = across_dist / max(width_eff, 0.01);
along_d    = mark_dist;
rect_dist  = max(along_d, across_d);
round_dist = pow(along_d * along_d + across_d * across_d, 0.5) * 0.7071;
final_dist = mix(rect_dist, round_dist, roundness_eff);

// mark identity for color — winner slot directly, no recovery dance needed
mark_slot = win_slot;

band_col_r = hash1d((band_idx + cs) * 127.1);
band_col_g = hash1d((band_idx + cs) * 91.3);
band_col_b = hash1d((band_idx + cs) * 43.1);

mark_col_r = hash1d((mark_slot + bs) * 127.1 + (band_idx + cs) * 311.7);
mark_col_g = hash1d((mark_slot + bs) * 57.2  + (band_idx + cs) * 91.3);
mark_col_b = hash1d((mark_slot + bs) * 123.7 + (band_idx + cs) * 43.1);

mark_size = 1.0 - mortar_eff;

// Screen-space derivative AA — unchanged, doesn't depend on slot/search
px_norm = 1.0 / dim.x;
d_across_dx = -sinT * px_norm * aspect;
d_across_dy =  cosT * px_norm;
d_across_per_px = pow(d_across_dx*d_across_dx + d_across_dy*d_across_dy, 0.5) * course_scale / max(width_eff, 0.01);
d_along_dx = cosT * px_norm * aspect;
d_along_dy = sinT * px_norm;
d_along_per_px = pow(d_along_dx*d_along_dx + d_along_dy*d_along_dy, 0.5) * bond_scale;
aa_width = max(d_across_per_px, d_along_per_px);
soft_final = max(softness_eff, aa_width);

mark_out = smoothstep(mark_size + soft_final, mark_size - soft_final, final_dist) * cont;

mark_r = mark_out * mix(1.0, mark_col_r, brick_color_eff);
mark_g = mark_out * mix(1.0, mark_col_g, brick_color_eff);
mark_b = mark_out * mix(1.0, mark_col_b, brick_color_eff);

bg_r = mix(0.0, band_col_r, course_color_eff);
bg_g = mix(0.0, band_col_g, course_color_eff);
bg_b = mix(0.0, band_col_b, course_color_eff);

out_r = mix(bg_r, mark_r, mark_out);
out_g = mix(bg_g, mark_g, mark_out);
out_b = mix(bg_b, mark_b, mark_out);

out2 = vec(mark_out, mark_out, mark_out, 1.0);
out1 = mix(vec(out_r, out_g, out_b, 1.0), vec(0.0, 0.0, 0.0, 0.0), bypass);
"""

patcher = {
    "name":        "f_masonry",
    "prefix":      "masonry",
    "object_name": "masonry_pix",
    "title":       "Masonry",
    "archetype":   "processor",

    "presentation_width":  227,
    "presentation_height": 164,

    "params": [
        {"name": "courses",      "type": "float", "min": 0.0,    "max": 100.0, "default": 8.0,  "label": "Courses",   "hint": "Number of horizontal bands (rows of bricks)"},
        {"name": "bond",         "type": "float", "min": 0.0,    "max": 100.0, "default": 8.0,  "label": "Bond",      "hint": "Number of bricks per course (columns)"},
        {"name": "offset",       "type": "float", "min": 0.0,    "max": 1.0,   "default": 0.0,  "label": "Offset",    "hint": "Per-course stagger -- 0.5=half-brick running bond"},
        {"name": "angle",        "type": "float", "min": -360.0, "max": 360.0, "default": 0.0,  "label": "Angle",     "hint": "Field rotation in degrees"},
        {"name": "skip",         "type": "float", "min": 0.0,    "max": 1.0,   "default": 1.0,  "label": "Skip",      "hint": "Fraction of courses that are visible"},
        {"name": "regularity",   "type": "float", "min": 0.0,    "max": 1.0,   "default": 1.0,  "label": "Regular",   "hint": "1=nearest-wins even grid  0=priority bias, contested territory (uneven spacing, density not preserved)"},
        {"name": "drift",        "type": "float", "min": 0.0,    "max": 4.0,   "default": 0.0,  "label": "Drift",     "hint": "Per-course along-axis drift amount"},
        {"name": "phase",        "type": "float", "min": 0.0,    "max": 1.0,   "default": 0.0,  "label": "Phase",     "hint": "Per-course phase offset -- primary animation target"},
        {"name": "speed_var",    "type": "float", "min": 0.0,    "max": 10.0,  "default": 0.0,  "label": "Speed Var", "hint": "Per-course speed variation when animated"},
        {"name": "mortar",       "type": "float", "min": 0.0,    "max": 1.0,   "default": 0.2,  "label": "Mortar",    "hint": "Gap width between bricks"},
        {"name": "softness",     "type": "float", "min": 0.0,    "max": 1.0,   "default": 0.0,  "label": "Softness",  "hint": "Edge feathering -- 0=hard  >0=smooth"},
        {"name": "width",        "type": "float", "min": -2.0,   "max": 2.0,   "default": 0.9,  "label": "Width",     "hint": "Brick aspect ratio scale in across-axis"},
        {"name": "roundness",    "type": "float", "min": -2.0,   "max": 2.0,   "default": 0.0,  "label": "Round",     "hint": "0=rectangular  1=circular/oval bricks"},
        {"name": "course_color", "type": "float", "min": 0.0,    "max": 1.0,   "default": 0.0,  "label": "C.Color",   "hint": "Per-course color randomization amount"},
        {"name": "brick_color",  "type": "float", "min": 0.0,    "max": 1.0,   "default": 0.0,  "label": "B.Color",   "hint": "Per-brick color randomization amount"},
        {"name": "course_seed",  "type": "float", "min": 0.0,    "max": 999.0, "default": 0.0,  "label": "C.Seed",    "hint": "Course hash seed -- changes color/speed/skip pattern"},
        {"name": "brick_seed",   "type": "float", "min": 0.0,    "max": 999.0, "default": 0.0,  "label": "B.Seed",    "hint": "Brick hash seed -- changes presence/drift pattern"},
        {"name": "src_mode",     "type": "internal"},  # driven by vs_inState
        {"name": "bypass",       "type": "bypass"},
    ],

    "outlets": [
        {"comment": "composite"},
        {"comment": "mask"},
    ],

    # Three modulation texture inlets — slot space (in2), intra-brick
    # space (in3), screen/pixel space (in4). Codebox already references
    # in2/in3/in4 and wires directly to pix (no vs_inState — these are
    # plain texture inputs, no control messages to merge). This key was
    # MISSING from definition.py despite the codebox depending on it —
    # discovered 2026-07-05 when rebuilding from definition.py silently
    # dropped these three inlets that were live in production (hand-
    # wired directly into the .maxpat at some point, never captured
    # back here). Restores numinlets to 4 (1 texture/control + 3 mod).
    "mod_inlets": [
        {"label": "slot mod",  "vs_instate": False},
        {"label": "brick mod", "vs_instate": False},
        {"label": "pixel mod", "vs_instate": False},
    ],

    "codebox": CODEBOX,
}
