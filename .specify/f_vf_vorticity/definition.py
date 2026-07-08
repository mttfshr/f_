patcher = {
    "name":               "f_vf_vorticity",
    "prefix":             "vfvorticity",
    "object_name":        "vfvorticity_pix",
    "title":              "Vorticity",
    "signal_type":        "vecfield",
    "archetype":          "processor",
    "pix_type":           "float32",

    "presentation_width":  100,
    "presentation_height": 80,

    "outlets": [
        {"comment": "vecfield"},
    ],

    # Single inlet: in1 IS the vecfield (not a scalar source), same
    # pattern as f_vf_fieldmap's in1 — no mod_inlets block needed.
    # Confirmed in scratch testing (2026-07-06): single codebox compiles
    # clean, no capture-ceiling split needed (resolves ADR-1).
    # Confinement's effective strength depends on the source field's
    # baseline curl (vortex/repulse/flow all read very differently at
    # the same confinement value) — range_tiers per Matt's call
    # (2026-07-06), same convenience mechanism as f_vf_seeds' field_gain.
    # Tier values are provisional pending Phase 3 chain testing
    # (f_vf_advect / f_caustic) — see plan.md ADR-5.
    "params": [
        {
            "name": "confinement", "type": "float",
            "min": 0.0, "max": 1.0, "default": 0.0,
            "hint": "Turbulence amount — vorticity confinement force strength. Effective range varies by source field; see range_tiers.",
            "label": "Confinement",
            "range_tiers": [0.1, 1.0, 10.0],
        },
        {"name": "bypass", "type": "bypass"},
    ],

    "codebox": """\
field_x(u, v) {
    return (sample(in1, vec(u, v)).x - 0.5) * 2.0;
}

field_y(u, v) {
    return (sample(in1, vec(u, v)).y - 0.5) * 2.0;
}

curl_at(u, v, sx, sy) {
    fy_r = field_y(u + sx, v);
    fy_l = field_y(u - sx, v);
    fx_t = field_x(u, v + sy);
    fx_b = field_x(u, v - sy);
    return (fy_r - fy_l) / (2.0 * sx) - (fx_t - fx_b) / (2.0 * sy);
}

Param confinement(0.0);
Param bypass(0.0);

sx = 1.0 / dim.x;
sy = 1.0 / dim.y;

u = norm.x;
v = norm.y;

w_c = curl_at(u, v, sx, sy);
w_r = curl_at(u + sx, v, sx, sy);
w_l = curl_at(u - sx, v, sx, sy);
w_t = curl_at(u, v + sy, sx, sy);
w_b = curl_at(u, v - sy, sx, sy);

dwdx = (w_r - w_l) / (2.0 * sx);
dwdy = (w_t - w_b) / (2.0 * sy);

grad_mag = max(sqrt(dwdx * dwdx + dwdy * dwdy), 0.00001);
nx = dwdx / grad_mag;
ny = dwdy / grad_mag;

force_x = confinement * ny * w_c;
force_y = confinement * (-nx) * w_c;

out_x = field_x(u, v) + force_x;
out_y = field_y(u, v) + force_y;

result = vec(out_x * 0.5 + 0.5, out_y * 0.5 + 0.5, 0.5, 1.0);

out1 = mix(result, sample(in1, norm), bypass);
""",
}
