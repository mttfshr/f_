# f_util_profile patcher definition
# Input to tools/build_patcher.py
# Last updated: 2026-06-01

# No codebox — processing is CPU-side in profile_rows.js and profile_cols.js.
# The build script generates the outer shell only (inlet, outlets, routepass,
# route, autopattr, moduleSize chain, UI, parameters block).
# Internal processing chain (jit.gl.asyncread → two jit.dimop → two gates →
# two js → two jit.gl.texture) is hand-wired in Max after generation.

patcher = {
    # Identity
    "name":                "f_util_profile",
    "prefix":              "profile",
    "title":               "f_util_profile",

    # Archetype: "util" — no pix/codebox/gen; CPU-side processing.
    # Build script generates outer shell only. Internal chain hand-wired.
    "archetype":           "util",

    # Outlet count — two: outlet 0 = row profile (128×1), outlet 1 = col profile (1×128)
    "num_outlets":         2,

    # Presentation panel size — wider to accommodate three params
    "presentation_width":  200,
    "presentation_height": 75,

    # Params — ordered left to right in UI
    # bypass handled by jsui → == 0 → both gates (not → attrui → pix)
    # res_rows and res_cols wire to JS directly (not through attrui)
    # util archetype: no pix, so no attrui wiring in generated output
    "params": [
        {"name": "res_rows", "type": "int", "min": 1,  "max": 128, "default": 64, "label": "Rows", "hint": "Row analysis slabs (1=coarse, 128=fine)"},
        {"name": "res_cols", "type": "int", "min": 1,  "max": 128, "default": 64, "label": "Cols", "hint": "Column analysis slabs (1=coarse, 128=fine)"},
        {"name": "freq",     "type": "int", "min": 1,  "max": 64,  "default": 8,  "label": "Freq", "hint": "Upstream generator band count — sync target only, not used internally"},
        {"name": "bypass",   "type": "bypass"},
    ],

    # No codebox — util archetype
    "codebox": None,
}
