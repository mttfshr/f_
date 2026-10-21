# f_vf_warp.  Since 2026-10-05 (build_cleanup T017) this definition reproduces the shipped
# patcher exactly: `bypass_mode: "param"` writes the hand-made bypass wiring
# (jsui -> `prepend param bypass_gate` -> pix, driving the codebox Param below) instead of the
# native jsui -> attrui @attr bypass.  Native jit.gl.pix bypass skips the shader and passes
# secondary outlets through vertically flipped, so out2 could never respect bypass that way.
# Taken off the never-regenerate list 2026-10-19; nothing needs regenerating, because the
# patcher already equals what this builds.
# 2026-10-19 (T052): `strength` split into `gain` (warp depth, default 0.0 as before) and `mix_pct`
# (dry/wet on the composite outlet, default 100 = prior behavior), as f_grain's T003.  The older
# comment here claimed a saved default of 0.1; the shipped patcher, this definition and the codebox
# all had 0.0.  Vecfield label/comment styling: in the definition and `overrides`.
patcher = {
    "name":               "f_vf_warp",

    # REVISIT (2026-07-03, via GPU Gems 2 Ch. 19 "Generic Refraction
    # Simulation" read): confirmed this module's core mechanism —
    # (sample vecfield -> remap [-1,1] -> scale by strength -> add to
    # UV -> sample source) — is exactly Sousa's refraction technique
    # (Listing 19-1), independently arrived at. One thing the chapter has
    # that this module doesn't: a "refraction mask" (S:19.2), a spatial
    # gate limiting *where* the offset applies (e.g. confined to a glass
    # object's silhouette) rather than uniformly across the frame.
    # Currently offset_x/offset_y apply everywhere the vecfield is
    # nonzero, all-or-nothing via the src_vecfield connected-gate only.
    # A mask inlet multiplying the offset before it's applied — same
    # idiom as the mod-texture inlets already used in f_lens/f_vf_prism —
    # would add this cheaply if wanted. Not yet decided whether this is
    # worth adding; discuss architecture before touching CODEBOX below.
    # See ideas/gpu_gems_research.md's Ch 19 entry for the full note.
    "prefix":             "vfwarp",
    "object_name":        "vfwarp_pix",
    "title":              "Warp",
    "signal_type":        "∇ in",
    "archetype":          "processor",
    "pix_type":           "char",

    # Bypass drives the codebox Param `bypass_gate` (jsui -> `prepend param bypass_gate` -> pix),
    # not the native @bypass: native bypass skips the shader and flips secondary outlets.  Both
    # outlets mix to the input texture, so a bypassed module is a passthrough (Matt, 2026-10-05).
    "bypass_mode":        "param",

    "presentation_width":  78,
    "presentation_height": 90,

    "outlets": [
        {"comment": "composite"},
        {"comment": "warped"},
    ],

    # vecfield inlet: in1 on pix (in2 in codebox), via vs_inState
    # state_param wires vs_inState out1 → prepend param src_vecfield → pix in0
    "mod_inlets": [
        {"label": "vecfield", "state_param": "src_vecfield"},
    ],

    "params": [
        {"name": "gain", "type": "float", "min": 0.0, "max": 1.5,
         "default": 0.0, "label": "Gain",
         "hint": "Warp depth — 0=none, 1=±1 UV offset. Renamed from strength 2026-10-19 (T052) to match the library-wide gain/mix naming convention."},
        {"name": "mix_pct", "type": "float", "min": 0.0, "max": 100.0, "default": 100.0,
         "label": "Mix", "widget": "numbox",
         "hint": "Dry/wet crossfade on the composite outlet, source to fully warped. New 2026-10-19 (T052); default 100 keeps the module's prior behavior unchanged. Internal Param named mix_pct to avoid colliding with the codebox's mix() operator."},
        {"name": "src_vecfield", "type": "internal"},
        {"name": "bypass", "type": "bypass"},
    ],

    "codebox": """\
Param gain(0.0);
Param mix_pct(100.0);
Param src_vecfield(0.0);
Param bypass_gate(0.0);

uv = norm;

// Sample field channels inline — never store vec and access component
field_x = sample(in2, uv).x;
field_y = sample(in2, uv).y;

// Remap [0,1] → [-1,1], scale by gain
offset_x = (field_x - 0.5) * 2.0 * gain;
offset_y = (field_y - 0.5) * 2.0 * gain;

// Suppress offset when vecfield inlet is unconnected (vs_black → field=0 → offset=-gain without this)
offset_x = mix(0.0, offset_x, step(0.5, src_vecfield));
offset_y = mix(0.0, offset_y, step(0.5, src_vecfield));

// Displace UV and clamp to edge. Bounds are 0.001 / 0.999, NOT 0 / 1: on the GPU a coordinate
// of exactly 1.0 (x) or 0.0 (y) sits on the wrap seam and reads the OPPOSITE edge (probe P9,
// 2026-10-20). A bound strictly inside the edge texel keeps the read on the intended edge.
warped_x = clamp(uv.x + offset_x, 0.001, 0.999);
warped_y = clamp(uv.y + offset_y, 0.001, 0.999);
warped_uv = vec(warped_x, warped_y);

// Output — sample inline, no stored vec component access
warped_sample = sample(in1, warped_uv);
src_sample = sample(in1, uv);

// gain/mix convention (T052): the warped sample is the complete composited state, mix_pct a
// plain crossfade toward it (source at 0, fully warped at 100). out2 is the warped layer
// itself, unmixed. Bypass (bypass_mode "param"): passthrough on every outlet.
composite = mix(src_sample, warped_sample, mix_pct / 100.0);
out1 = mix(composite, src_sample, bypass_gate);
out2 = mix(warped_sample, src_sample, bypass_gate);
""",
}

# BEGIN overrides (build/capture.py rewrites only this block)
patcher["overrides"] = {
    "gain.ctl": {"appearance": 1, "presentation_rect": [4.0, 38.0, 25.0, 23.0]},
}
# END overrides
