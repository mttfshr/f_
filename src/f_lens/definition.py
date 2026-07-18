# f_lens patcher definition
# Input to build/build_patcher.py
# Last updated: 2026-07-15 (v2 in progress — ghost images added; tilt-shift
# now correctly represented via raw_ui + raw_boxes/raw_lines, replacing
# the previous inaccurate "internal" placeholder declarations)
#
# Tilt-shift (tilt/tilt_axis/tilt_pos/slope/mode) has real UI and route
# dispatch, but targets a secondary object (jit.fx.cf.tiltshift) via
# bespoke per-param transform logic (lens_tiltcenter.js combining
# tilt_axis+tilt_pos; a sel-based dispatch for mode) that doesn't fit a
# generic schema -- declared here as "raw_ui" params (reserve a route
# outlet, no generated UI) plus verbatim raw_boxes/raw_lines/raw_parameters
# extracted from the working live patcher, ID-remapped to the obj-raw-N
# namespace to avoid colliding with anything the schema generates. See
# ideas/build_patcher_schema_gaps.md for the full background, and
# raw_tiltshift.json (sibling file) for the extracted content itself.
#
# Slated for full removal once f_focus ships (see .specify/f_focus/) --
# at that point this whole raw_ui/raw_boxes block should be deleted
# outright, not "fixed further."

import json
from pathlib import Path

_raw = json.loads((Path(__file__).parent / "raw_tiltshift.json").read_text())
_raw_halation = json.loads((Path(__file__).parent / "raw_halation.json").read_text())
_raw["raw_boxes"] = _raw["raw_boxes"] + _raw_halation["raw_boxes"]
_raw["raw_lines"] = _raw["raw_lines"] + _raw_halation["raw_lines"]

CODEBOX = """\
Param aberration(0.0);
Param distortion(0.0);
Param transmission(0.0);
Param aberration_mod(0.0);
Param distortion_mod(0.0);
Param transmission_mod(0.0);
Param surface_mod(0.0);
Param ghost(0.0);
Param ghost_count(3.0);
Param ghost_spacing(0.3);
Param bypass(0.0);

uv = norm;
cx = uv.x - 0.5;
cy = uv.y - 0.5;
dist = length(vec(cx, cy));

aberr_tex = sample(in2, uv).x;
dist_tex  = sample(in3, uv).x;
trans_tex = sample(in4, uv).x;
eps    = 0.002;
surf_c = sample(in5, uv).x;
surf_r = sample(in5, vec(uv.x + eps, uv.y)).x;
surf_u = sample(in5, vec(uv.x, uv.y + eps)).x;

k = distortion;
k = k * (1.0 + dist_tex * distortion_mod);
r2 = cx*cx + cy*cy;
warp_cx = cx * (1.0 + k*r2);
warp_cy = cy * (1.0 + k*r2);
warp_uv = vec(0.5 + warp_cx, 0.5 + warp_cy);

surf_dx = (surf_r - surf_c) * surface_mod;
surf_dy = (surf_u - surf_c) * surface_mod;
warp_uv = vec(warp_uv.x + surf_dx, warp_uv.y + surf_dy);
warp_cx = warp_uv.x - 0.5;
warp_cy = warp_uv.y - 0.5;

ab = aberration * dist * (1.0 + aberr_tex * aberration_mod);
r_uv = vec(0.5 + warp_cx * (1.0 + ab), 0.5 + warp_cy * (1.0 + ab));
b_uv = vec(0.5 + warp_cx * (1.0 - ab), 0.5 + warp_cy * (1.0 - ab));
r_val = sample(in1, r_uv).x;
g_val = sample(in1, warp_uv).y;
b_val = sample(in1, b_uv).z;
effect_out = vec(r_val, g_val, b_val, 1.0);

dist_v = dist * (1.0 + trans_tex * transmission_mod);
vignette = 1.0 - smoothstep(0.3, 0.7, dist_v);
warm_shift = vec(1.05, 1.0, 0.92, 1.0);
effect_out = mix(effect_out * warm_shift * vignette, effect_out, 1.0 - transmission);

gc = floor(ghost_count + 0.5);
gate2 = step(2.0, gc);
gate3 = step(3.0, gc);
gate4 = step(4.0, gc);

atten1 = 1.0;
atten2 = 0.6 * gate2;
atten3 = 0.36 * gate3;
atten4 = 0.22 * gate4;
w_sum = atten1 + atten2 + atten3 + atten4;

os1 = 1.0 + ghost_spacing;
os2 = 1.0 + ghost_spacing*2.0;
os3 = 1.0 + ghost_spacing*3.0;
os4 = 1.0 + ghost_spacing*4.0;

g1_r_uv = vec(0.5 + warp_cx*os1*(1.0+ab), 0.5 + warp_cy*os1*(1.0+ab));
g1_g_uv = vec(0.5 + warp_cx*os1,          0.5 + warp_cy*os1);
g1_b_uv = vec(0.5 + warp_cx*os1*(1.0-ab), 0.5 + warp_cy*os1*(1.0-ab));

g2_r_uv = vec(0.5 + warp_cx*os2*(1.0+ab), 0.5 + warp_cy*os2*(1.0+ab));
g2_g_uv = vec(0.5 + warp_cx*os2,          0.5 + warp_cy*os2);
g2_b_uv = vec(0.5 + warp_cx*os2*(1.0-ab), 0.5 + warp_cy*os2*(1.0-ab));

g3_r_uv = vec(0.5 + warp_cx*os3*(1.0+ab), 0.5 + warp_cy*os3*(1.0+ab));
g3_g_uv = vec(0.5 + warp_cx*os3,          0.5 + warp_cy*os3);
g3_b_uv = vec(0.5 + warp_cx*os3*(1.0-ab), 0.5 + warp_cy*os3*(1.0-ab));

g4_r_uv = vec(0.5 + warp_cx*os4*(1.0+ab), 0.5 + warp_cy*os4*(1.0+ab));
g4_g_uv = vec(0.5 + warp_cx*os4,          0.5 + warp_cy*os4);
g4_b_uv = vec(0.5 + warp_cx*os4*(1.0-ab), 0.5 + warp_cy*os4*(1.0-ab));

ghost_r = (sample(in1, g1_r_uv).x*atten1 + sample(in1, g2_r_uv).x*atten2 + sample(in1, g3_r_uv).x*atten3 + sample(in1, g4_r_uv).x*atten4) / w_sum;
ghost_g = (sample(in1, g1_g_uv).y*atten1 + sample(in1, g2_g_uv).y*atten2 + sample(in1, g3_g_uv).y*atten3 + sample(in1, g4_g_uv).y*atten4) / w_sum;
ghost_b = (sample(in1, g1_b_uv).z*atten1 + sample(in1, g2_b_uv).z*atten2 + sample(in1, g3_b_uv).z*atten3 + sample(in1, g4_b_uv).z*atten4) / w_sum;

ghost_vec = vec(ghost_r, ghost_g, ghost_b, 0.0);
effect_out = effect_out + ghost_vec * ghost;

out1 = mix(effect_out, sample(in1, uv), bypass);
"""

patcher = {
    "name":        "f_lens",
    "prefix":      "lens",
    "object_name": "lens_pix",
    "title":       "Lens",
    "archetype":   "processor",
    "pix_type":    "char",

    "presentation_width":  227,
    "presentation_height": 164,

    "params": [
        {"name": "aberration",      "type": "float", "min": -1.0, "max": 1.0,  "default": 0.0, "label": "Aberr",      "hint": "Chromatic aberration -- RGB channel separation scaled by radius. Negative flips lead/lag side.",
         "range_tiers": [(-1.0, 1.0), (-2.0, 2.0), (-10.0, 10.0)]},
        {"name": "distortion",      "type": "float", "min": -1.0, "max": 1.0,  "default": 0.0, "label": "Distort",    "hint": "Barrel/pincushion distortion -- 0=none, negative=barrel, positive=pincushion.",
         "range_tiers": [(-1.0, 1.0), (-5.0, 5.0)]},
        {"name": "transmission",    "type": "float", "min": -1.0, "max": 1.0,  "default": 0.0, "label": "Trans",      "hint": "Vignette / transmission falloff -- warm-shifted toward edges. Negative overshoots into reverse-vignette (brighter edges).",
         "range_tiers": [(-1.0, 1.0), (-2.0, 2.0)]},
        {"name": "aberration_mod",  "type": "float", "min": 0.0, "max": 1.0,  "default": 0.0, "label": "Aberr Mod",  "hint": "Aberration modulation depth (inlet 2 texture)"},
        {"name": "distortion_mod",  "type": "float", "min": 0.0, "max": 1.0,  "default": 0.0, "label": "Dist Mod",   "hint": "Distortion modulation depth (inlet 3 texture)"},
        {"name": "transmission_mod","type": "float", "min": 0.0, "max": 1.0,  "default": 0.0, "label": "Trans Mod",  "hint": "Transmission modulation depth (inlet 4 texture)"},
        {"name": "surface_mod",     "type": "float", "min": 0.0, "max": 5.0,  "default": 0.0, "label": "Surf Mod",   "hint": "Surface emboss displacement depth (inlet 5 gradient texture)"},
        {"name": "ghost",           "type": "float", "min": -1.0, "max": 1.0, "default": 0.0, "label": "Ghost",      "hint": "Inter-reflection ghost intensity -- additive, color-coupled to aberration. Negative subtracts (dark ghosts)."},
        {"name": "ghost_count",     "type": "float", "min": 1.0, "max": 4.0,  "default": 3.0, "label": "Ghost Ct",   "hint": "Number of ghost taps (1-4), floor()'d in codebox", "widget": "numbox"},
        {"name": "ghost_spacing",   "type": "float", "min": -1.0, "max": 1.0, "default": 0.3, "label": "Ghost Sp",   "hint": "Offset scale between ghost taps. Negative mirrors ghosts inward through center.",
         "range_tiers": [(-1.0, 1.0), (-5.0, 5.0)]},
        {"name": "halation",           "type": "float", "min": 0.0, "max": 1.0, "default": 0.0, "label": "Halation",  "hint": "Halation glow intensity -- additive, warm-tinted, luma-gated. 0 = no glow.",
         "pix_target": "obj-raw-17"},
        {"name": "halation_threshold", "type": "float", "min": 0.0, "max": 1.0, "default": 0.7, "label": "Hal Thresh", "hint": "Luma gate point -- regions above this bloom.",
         "pix_target": "obj-raw-17"},
        # raw_ui: real UI + route dispatch, but targets jit.fx.cf.tiltshift
        # (a secondary object) via raw_boxes/raw_lines below, not the
        # primary pix. See module docstring above.
        {"name": "tilt",            "type": "raw_ui"},
        {"name": "tilt_axis",       "type": "raw_ui"},
        {"name": "tilt_pos",        "type": "raw_ui"},
        {"name": "slope",           "type": "raw_ui"},
        {"name": "mode",            "type": "raw_ui"},
        {"name": "bypass",          "type": "bypass"},
    ],

    "outlets": [{"comment": "composite"}],

    # Four mod-texture inlets (bpatcher in1-in4, feeding lens_pix in2-in5).
    # No state_param suppression needed -- the codebox's own
    # `tex * mod_amount` pattern already self-neutralizes on a black/
    # unconnected vs_black texture.
    "mod_inlets": [
        {"label": "aberration mod"},
        {"label": "distortion mod"},
        {"label": "transmission mod"},
        {"label": "surface mod"},
    ],

    # Front/back panel split -- matches the original hand-built
    # panel_toggle/lens_toggle.js exactly (front="lens": core optical
    # params + tilt-shift; back="field": the four *_mod textures).
    # Per Phase 0 T005, all v2 ghost params join the front panel rather
    # than reorganizing the split -- provisional pending a separate,
    # broader UI density refactor.
    "panel_toggle": {
        "front": ["aberration", "distortion", "transmission",
                  "tilt", "tilt_axis", "tilt_pos", "slope", "mode",
                  "ghost", "ghost_count", "ghost_spacing",
                  "halation", "halation_threshold"],
        "back": ["aberration_mod", "distortion_mod", "transmission_mod", "surface_mod"],
        "front_label": "lens",
        "back_label": "field",
    },

    # Skip the schema's automatic primary-pix -> outlet0 wire for outlet 0 --
    # the chain is lens_pix -> halation -> tiltshift -> outlet0 (halation
    # inserted 2026-07-15). All three hops are supplied explicitly via
    # raw_lines (see raw_tiltshift.json + raw_halation.json).
    "outlet_source_override": {0: "tiltshift"},

    "raw_boxes":      _raw["raw_boxes"],
    "raw_lines":      _raw["raw_lines"],
    "raw_parameters": _raw["raw_parameters"],

    "codebox": CODEBOX,
}
