"""
f_sirds — definition.py

Single Image Random Dot Stereogram (SIRDS) generator. Strip-based real-time
construction per Policarpo, "Real-Time Stereograms," GPU Gems Ch. 41 (2004).

NOT built via tools/build_patcher.py directly -- pix_chain as currently
specced only wires live params (depth_factor, bypass) to the "primary"
node, but this module needs every depth-driven stage to receive both.
Built via the dedicated .specify/f_sirds/build_sirds.py instead, following
the f_vf_advect precedent (custom builder script, definition.py stays the
documented source of truth). See docs/f-reference/f_sirds.md for the full
research writeup this build is based on.

Architecture: num_strips is a FIXED BUILD-TIME CONSTANT (12, proven working
in scratch testing), not a live param -- decided explicitly in session,
see HANDOFF. strip_width = 1/(num_strips+1), baked as a literal into every
stage's codebox at generation time, not a runtime Param.

13 total jit.gl.pix nodes:
  - stage0 (reference/seed): tiles pattern periodically, no depth, no mask.
  - stage1..stage12 (depth-driven): each reads the previous stage's output,
    displaced by depth in its own strip; passes through elsewhere.
    Byte-identical codebox apart from the baked stage_index constant.
  - stage12 is primary -- its output is the module's outlet.

bypass is broadcast to every depth-driven stage (not just primary) and
folded into each stage's own in_strip gate (`* (1.0 - bypass)`). This makes
the whole chain self-neutralize back to stage0's clean tiled output when
bypassed -- no separate raw-pattern wire into the primary node needed.
"""

NUM_STRIPS = 12
STRIP_WIDTH = 1.0 / (NUM_STRIPS + 1)

patcher = {
    # Identity
    "name":               "f_sirds",
    "prefix":             "sirds",
    "title":              "SIRDS",

    # Presentation
    "presentation_width":  190,
    "presentation_height": 130,

    # Archetype -- processor: pattern texture on in0
    "archetype": "processor",

    # Depth texture -- broadcast mod_inlet (every depth-driven stage reads it,
    # not just primary -- see build_sirds.py, this is the documented intent,
    # not literally consumed by build_patcher.py's default single-target wiring)
    "mod_inlets": [
        {
            "label":       "depth",
            "vs_instate":  True,
            "state_param": None,  # no src_mode gating needed -- vs_black
                                  # depth (all-zero) already means "no
                                  # displacement," a graceful default
        },
    ],

    "outlets": [
        {"comment": "sirds"},
    ],

    "params": [
        {
            "name": "depth_factor", "type": "float",
            "min": -0.3, "max": 0.3, "default": 0.0,
            "hint": "Depth -> horizontal displacement scaling. Range "
                    "tightened from the theoretical -1..1 to the practical "
                    "-0.3..0.3 -- values beyond that mostly just distort "
                    "rather than adding usable depth (confirmed empirically "
                    "in session). Sign flips displacement direction "
                    "(differs from GPU Gems' abs()+invert convention -- "
                    "not yet reconciled, see docs/f-reference/f_sirds.md "
                    "Open Questions).",
            "label": "depth",
        },
        {
            "name": "bypass", "type": "bypass",
        },
    ],

    # Multi-pix chain -- documented here for reference; build_sirds.py
    # generates this same structure programmatically (stage_index and
    # strip_width baked as literals via .format(), not read from this list).
    "pix_chain": [
        {
            "id": "stage0", "name": "#0_sirds_stage0",
            "gen": "codebox_stage0.gen",
            "n_inlets": 1, "n_outlets": 1,
            "primary": False,
        },
    ] + [
        {
            "id": f"stage{i}", "name": f"#0_sirds_stage{i}",
            "gen": "codebox_stage_n.gen",
            "n_inlets": 2, "n_outlets": 1,
            "primary": (i == NUM_STRIPS),
        }
        for i in range(1, NUM_STRIPS + 1)
    ],

    # Cross-pix wiring -- documented here; build_sirds.py generates the
    # equivalent chain programmatically, plus the depth_factor/bypass/depth
    # broadcast to every depth-driven stage that this schema can't express.
    "pix_wires": (
        [["stage0", 0, "stage1", 0]] +
        [[f"stage{i}", 0, f"stage{i+1}", 0] for i in range(1, NUM_STRIPS)]
    ),
}
