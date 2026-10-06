# f_vf_warp.  Since 2026-10-05 (build_cleanup T017) this definition reproduces the shipped
# patcher exactly: `bypass_mode: "param"` writes the hand-made bypass wiring
# (jsui -> `prepend param bypass_gate` -> pix, driving the codebox Param below) instead of the
# native jsui -> attrui @attr bypass.  Native jit.gl.pix bypass skips the shader and passes
# secondary outlets through vertically flipped, so out2 could never respect bypass that way.
# plan.md still lists the module as never-regenerate until Matt takes it off; nothing needs
# regenerating, because the patcher already equals what this builds.
# strength default 0.1, vecfield label/comment styling: in the definition and `overrides`.
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
    "signal_type":        "vecfield in",
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
        {"name": "strength", "type": "float", "min": 0.0, "max": 1.5,
         "default": 0.0, "label": "Strength", "hint": "Warp depth — 0=none, 1=±1 UV offset"},
        {"name": "src_vecfield", "type": "internal"},
        {"name": "bypass", "type": "bypass"},
    ],

    "codebox": """\
Param strength(0.1);
Param src_vecfield(0.0);
Param bypass_gate(0.0);

uv = norm;

// Sample field channels inline — never store vec and access component
field_x = sample(in2, uv).x;
field_y = sample(in2, uv).y;

// Remap [0,1] → [-1,1], scale by strength
offset_x = (field_x - 0.5) * 2.0 * strength;
offset_y = (field_y - 0.5) * 2.0 * strength;

// Suppress offset when vecfield inlet is unconnected (vs_black → field=0 → offset=-strength without this)
offset_x = mix(0.0, offset_x, step(0.5, src_vecfield));
offset_y = mix(0.0, offset_y, step(0.5, src_vecfield));

// Displace UV and clamp to edge
warped_x = clamp(uv.x + offset_x, 0.0, 1.0);
warped_y = clamp(uv.y + offset_y, 0.0, 1.0);
warped_uv = vec(warped_x, warped_y);

// Output — sample inline, no stored vec component access
warped_sample = sample(in1, warped_uv);
out1 = mix(warped_sample, sample(in1, uv), bypass_gate);
out2 = mix(warped_sample, sample(in1, uv), bypass_gate);
""",
}

# BEGIN overrides (build/capture.py rewrites only this block)
patcher["overrides"] = {
    "signal_type": {"fontsize": 9.5, "textcolor": [0.35, 0.75, 0.95, 1.0]},
    "strength.ctl": {"appearance": 1, "presentation_rect": [4.0, 38.0, 25.0, 23.0]},
}
# END overrides
