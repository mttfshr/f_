# f_stipple patcher definition
# Input to tools/build_patcher.py
# Last updated: 2026-06-09
# Three outlets: composite, stipple mask, displaced source
# proc_mode header toggle removed — displacement is always available on out3

CODEBOX = """\
Param freq(5.0);
Param angle(0.0);
Param anisotropy(0.5);
Param threshold(0.5);
Param softness(0.1);
Param along_phase(0.0);
Param across_phase(0.0);
Param zoom(1.0);
Param colorize(0.0);
Param coarseness(1.0);
Param src_mode(0.0);
Param bypass(0.0);

// Coordinate frame
theta = angle * (3.14159265 / 180.0);
cx = cos(theta);
sx = sin(theta);
along = norm.x * cx + norm.y * sx;
across = -norm.x * sx + norm.y * cx;

// Phase offset
along_d = along + along_phase;
across_d = across + across_phase;

// Zoom applied to base coords only
zoomed_along = along_d / max(zoom, 0.001);
zoomed_across = across_d / max(zoom, 0.001);

// Input sample
input_luma = sample(in1, norm).r;
src_col = sample(in1, norm);

// Displacement: warp zoomed coords by input luma (always computed)
warp = input_luma * threshold;
along_disp = zoomed_along + warp;
across_disp = zoomed_across + warp * 0.5;

// Coarseness: scales down the large prime to increase grain period
prime_scale = 43758.5 / max(coarseness, 1.0);

// Parallel (sin-based) hash — uses base (non-displaced) coords
h_par_raw = sin(zoomed_along * freq * prime_scale);
h_parallel = h_par_raw - floor(h_par_raw);

// Isotropic (arithmetic) hash — uses base coords
h_iso_raw = sin((zoomed_along * 127.1 + zoomed_across * 311.7) * prime_scale);
h_iso = h_iso_raw - floor(h_iso_raw);

// Anisotropy blend
hash_field = mix(h_iso, h_parallel, anisotropy);

// Source mode: threshold against hash field directly
lo = threshold - softness * 0.5;
hi = threshold + softness * 0.5;
source_stipple = smoothstep(lo, hi, hash_field);

// Processor/dither: input luma compared against hash field
dither_stipple = smoothstep(hash_field - softness * 0.5, hash_field + softness * 0.5, input_luma + threshold - 0.5);

// Select stipple by src_mode
stipple = mix(source_stipple, dither_stipple, src_mode);

// Output color (composite)
mono_out = vec(stipple, stipple, stipple, 1.0);
color_out = vec(src_col.r * stipple, src_col.g * stipple, src_col.b * stipple, 1.0);
result = mix(mono_out, color_out, colorize * src_mode);

// Stipple mask (raw scalar)
mask_out = vec(stipple, stipple, stipple, 1.0);

// Displaced source: source sampled at displacement-warped UV
disp_uv = vec(along_disp / max(zoom, 0.001), across_disp / max(zoom, 0.001));
// Reconstruct screen UV from rotated displaced coords
disp_x = disp_uv.x * cx - disp_uv.y * sx;
disp_y = disp_uv.x * sx + disp_uv.y * cx;
disp_screen = vec(clamp(disp_x, 0.0, 1.0), clamp(disp_y, 0.0, 1.0));
displaced_out = sample(in1, disp_screen);

// Bypass
source_bp = vec(0.0, 0.0, 0.0, 1.0);
proc_bp = src_col;
bypass_out = mix(source_bp, proc_bp, src_mode);

out1 = mix(result, bypass_out, bypass);
out2 = mix(mask_out, bypass_out, bypass);
out3 = mix(displaced_out, bypass_out, bypass);
"""

patcher = {
    # Identity
    "name":                "f_stipple",
    "prefix":              "stipple",
    "object_name":         "stipple_pix",
    "title":               "Stipple",

    # Archetype: "source", "processor", or "dual"
    "archetype":           "dual",

    # Presentation panel size
    "presentation_width":  191,
    "presentation_height": 157,

    "outlets": [
        {"comment": "composite"},
        {"comment": "stipple mask"},
        {"comment": "displaced"},
    ],

    # Params — ordered left to right in UI
    # bypass is always last and handled specially (jsui)
    # internal params generate no UI objects
    "params": [
        {"name": "freq",         "type": "float", "min": 0.0,   "max": 20.0,  "default": 2.0,  "label": "Freq",     "hint": "Hash field spatial frequency"},
        {"name": "coarseness",   "type": "float", "min": 1.0,   "max": 100.0, "default": 20.0, "label": "Coarse.",  "hint": "Grain period scale — higher = chunkier grains"},
        {"name": "anisotropy",   "type": "float", "min": 0.0,   "max": 4.0,   "default": 0.5,  "label": "Aniso.",   "hint": "0=isotropic grain  1=parallel lines  >1=expressive aliasing"},
        {"name": "angle",        "type": "float", "min": -360.0,"max": 360.0, "default": 0.0,  "label": "Angle",    "hint": "Orientation of along/across coordinate frame"},
        {"name": "zoom",         "type": "float", "min": 0.1,   "max": 4.0,   "default": 1.0,  "label": "Zoom",     "hint": "Scales viewport into hash field — same character, bigger or smaller"},
        {"name": "threshold",    "type": "float", "min": 0.0,   "max": 2.0,   "default": 0.5,  "label": "Thresh.",  "hint": "Dither bias / displacement amount"},
        {"name": "colorize",     "type": "float", "min": 0.0,   "max": 1.0,   "default": 0.0,  "label": "Colorize", "hint": "0=monochrome dither output  1=inherit input color"},
        {"name": "along_phase",  "type": "float", "min": -1.0,  "max": 1.0,   "default": 0.0,  "label": "Along",    "hint": "Hash field offset along angle axis; drive externally for drift"},
        {"name": "across_phase", "type": "float", "min": -1.0,  "max": 1.0,   "default": 0.0,  "label": "Across",   "hint": "Hash field offset perpendicular to angle axis; drive externally for drift"},
        {"name": "softness",     "type": "float", "min": 0.0,   "max": 2.0,   "default": 0.1,  "label": "Soft.",    "hint": "Smoothstep width at comparison boundary"},
        {"name": "src_mode",     "type": "internal"},  # driven by vs_inState, not user-facing
        {"name": "bypass",       "type": "bypass"},    # always last; rendered as bypass_toggle.js jsui
    ],

    "codebox": CODEBOX,
}
