# f_vf_optical_flow patcher definition
# Input to build/build_patcher.py
# Last updated: 2026-07-18

#
# ARCHITECTURE NOTE -- primary node vs. real output node (T019 finding)
#
# build_patcher.py's schema always wires the module's incoming source
# texture into whichever pix_chain node is marked "primary" (via
# routepass -> primary_obj_id), and always wires the module's declared
# outlets FROM that same primary node (primary_obj_id -> outletN),
# unless overridden. Those two automatic behaviors can't both point at
# the node we actually want in this module: the source needs to reach
# stage_a (where gradients are computed), while the real outlets
# (vecfield + confidence) come from stage_c (the solve), three stages
# downstream.
#
# Resolution -- no build_patcher.py change needed, same mechanism
# f_lens already uses for its own downstream-of-primary outlet
# (tiltshift, via outlet_source_override + raw_lines):
#   - stage_a is marked primary, so it correctly receives the module's
#     source automatically.
#   - Both outlets are redirected to stage_c via outlet_source_override
#     (suppresses the automatic primary->outlet wire) + raw_lines
#     (supplies the real stage_c->outlet wire explicitly).
#   - bypass has the identical mismatch (auto-wires to primary/stage_a,
#     but "bypass" should mean "output neutral field", which only makes
#     sense at stage_c) -- fixed the same way: Param bypass declared in
#     both codeboxes (harmless/unused in stage_a, meaningful in
#     stage_c), fanned out to both via one extra raw_lines wire.
#
# stage_c's resolved object id is hardcoded below as "obj-53", derived
# by hand from build_patcher.py's chain_pix_obj_id() formula (support
# nodes get "obj-{50 + support_index}", support_index counted in
# pix_chain list order, skipping the primary). With this module's chain
# order [pass, stage_a(primary), stage_b_h, stage_b_v, stage_c,
# stage_e, stage_d_pass, stage_d]: pass=support_index 0 -> obj-50,
# stage_b_h=1 -> obj-51, stage_b_v=2 -> obj-52, stage_c=3 -> obj-53,
# stage_e=4 -> obj-54, stage_d_pass=5 -> obj-55, stage_d=6 -> obj-56.
# If the pix_chain list order below ever changes, these hardcoded ids
# must be recomputed by hand the same way -- they are NOT automatically
# kept in sync.
#
# T036 (2026-07-18): stage_e inserted between stage_c and stage_d
# (C->E->D, per Matt's decision) -- confidence-gated directional
# propagation along T035's ambiguous-axis signal, filling axis-aligned
# aperture-problem regions BEFORE temporal accumulation rather than
# after, so stage_d's decay/injection accumulates an already-filled
# signal instead of repeatedly decaying/re-injecting from neutral in
# gap regions every frame. Inserting a node mid-chain shifted every
# downstream hardcoded obj id (stage_d_pass: 54->55, stage_d: 55->56)
# and the dynamically-computed bypass id (n_ui_params 7->9 after adding
# `reach`/`mix_pct`, bypass_pre_id: obj-42->obj-48) -- see
# codebox_stage_e.gen for the stage's own internal design rationale.

CODEBOX_DIR = ""  # gen paths below are relative to this definition.py's own directory

patcher = {
    "name":        "f_vf_optical_flow",
    "prefix":      "opticalflow",
    "title":       "Optical Flow",
    "signal_type": "vecfield",
    "archetype":   "processor",

    "presentation_width":  190,
    "presentation_height": 130,

    "pix_chain": [
        {
            "id":        "pass",
            "name":      "#0_of_pass",
            "gen":       "pass",
            "n_inlets":  1,
            "n_outlets": 1,
            "primary":   False,
        },
        {
            "id":        "a",
            "name":      "#0_of_stage_a",
            "gen":       "codebox_stage_a.gen",
            "n_inlets":  2,
            "n_outlets": 3,
            "primary":   True,
        },
        {
            "id":        "bh",
            "name":      "#0_of_stage_b_h",
            "gen":       "codebox_stage_b_h.gen",
            "n_inlets":  2,
            "n_outlets": 2,
            "pix_type":  "float32",
            "primary":   False,
        },
        {
            "id":        "bv",
            "name":      "#0_of_stage_b_v",
            "gen":       "codebox_stage_b_v.gen",
            "n_inlets":  2,
            "n_outlets": 2,
            "pix_type":  "float32",
            "primary":   False,
        },
        {
            "id":        "c",
            "name":      "#0_of_stage_c",
            "gen":       "codebox_stage_c.gen",
            "n_inlets":  2,
            "n_outlets": 2,
            "pix_type":  "float32",
            "primary":   False,
        },
        {
            "id":        "e",
            "name":      "#0_of_stage_e",
            "gen":       "codebox_stage_e.gen",
            "n_inlets":  2,
            "n_outlets": 1,
            "pix_type":  "float32",
            "primary":   False,
        },
        {
            "id":        "passd",
            "name":      "#0_of_stage_d_pass",
            "gen":       "pass",
            "n_inlets":  1,
            "n_outlets": 1,
            "primary":   False,
        },
        {
            "id":        "d",
            "name":      "#0_of_stage_d",
            "gen":       "codebox_stage_d.gen",
            "n_inlets":  2,
            "n_outlets": 1,
            "primary":   False,
        },
    ],

    # Cross-pix feedback + forward wiring
    # [src_id, src_outlet, dst_id, dst_inlet]
    "pix_wires": [
        ["a",  2, "pass", 0],   # stage_a cur-passthrough -> pass (feedback loop)
        ["pass", 0, "a",  1],   # pass -> stage_a in2 (previous frame)
        ["a",  0, "bh",   0],   # stage_a Ix/Iy -> stage_b_h in1
        ["a",  1, "bh",   1],   # stage_a It    -> stage_b_h in2
        ["bh", 0, "bv",   0],
        ["bh", 1, "bv",   1],
        ["bv", 0, "c",    0],
        ["bv", 1, "c",    1],
        ["c",  0, "e",    0],       # stage_c masked instantaneous field -> stage_e in1 (T036, 2026-07-18: spatial fill now happens BEFORE temporal accumulation, C->E->D)
        ["c",  1, "e",    1],       # stage_c confidence+axis (det, T035's cos2t/sin2t) -> stage_e in2
        ["e",  0, "d",    0],       # stage_e filled field -> stage_d in1 (injection)
        ["d",  0, "passd",0],       # stage_d -> pass_d (feedback loop)
        ["passd", 0, "d", 1],       # pass_d -> stage_d in2 (previous accumulated field)
    ],

    "outlets": [
        {"comment": "vecfield (u,v)"},
        {"comment": "confidence"},
    ],

    # Suppress the automatic primary(stage_a)->outlet wiring -- see
    # architecture note above. Values are informational only (build()
    # only checks dict membership to decide whether to skip the
    # automatic wire; the real wiring is supplied via raw_lines below).
    # outlet0 (vecfield) now comes from stage_d (temporal accumulation,
    # added 2026-07-18), NOT stage_c directly -- stage_c's instantaneous
    # solve is only an intermediate injection signal now. outlet1
    # (confidence) is unchanged, still direct from stage_c.
    "outlet_source_override": {0: "d", 1: "c"},

    "raw_lines": [
        {"patchline": {"source": ["obj-56", 0], "destination": ["obj-2",   0]}},  # stage_d out (accumulated vecfield) -> outlet0
        {"patchline": {"source": ["obj-53", 1], "destination": ["obj-201", 0]}},  # stage_c out2 (confidence)          -> outlet1
        # bypass fan-out: the automatic wire already targets primary
        # (stage_a, obj-5) via bypass_pre_id(9)=obj-48 -> primary_obj_id
        # (n_ui_params=9: scale, gain, mask_lo, mask_hi, decay, injection,
        # step, reach, mix -- bypass_pre_id(n) = obj-{20 + n*3 + 1}, per
        # build_patcher.py's UI_PARAM_BASE=20 formula. Recomputed
        # 2026-07-18 when `reach`/`mix` were added for Stage E -- this
        # shifts whenever ui_params count changes, must be hand-updated,
        # not automatic). This adds the two other semantically-real
        # destinations (stage_c, stage_d). Stage E itself doesn't need
        # a bypass wire -- see codebox_stage_e.gen's header for why
        # stage_c's + stage_d's own bypass already make it safe.
        {"patchline": {"source": ["obj-48", 0], "destination": ["obj-53", 0]}},
        {"patchline": {"source": ["obj-48", 0], "destination": ["obj-56", 0]}},
        # `step` param fan-out: pix_target="bh" above wires the automatic
        # param_pre_id(6)=obj-39 -> bh (obj-51) already; this adds the
        # second real destination, bv (obj-52), so both Stage B passes
        # share the same live tap-spacing value. param_pre_id(n) =
        # obj-{20 + n*3 + 1}; step is ui_params index 6 (7th param,
        # 0-indexed) -> obj-{20+18+1} = obj-39.
        {"patchline": {"source": ["obj-39", 0], "destination": ["obj-52", 0]}},
        # `mask_lo`/`mask_hi` fan-out to stage_e (T036, 2026-07-18):
        # these already auto-wire to stage_c via pix_target="c"; Stage E
        # reuses the SAME two dials (not a second near-duplicate pair)
        # to judge its own pixel's confidence and each sampled tap's
        # confidence. param_pre_id(2)=obj-27 (mask_lo), param_pre_id(3)=
        # obj-30 (mask_hi); stage_e's obj id is obj-54.
        {"patchline": {"source": ["obj-27", 0], "destination": ["obj-54", 0]}},
        {"patchline": {"source": ["obj-30", 0], "destination": ["obj-54", 0]}},
    ],

    "params": [
        {
            "name": "scale", "type": "float",
            "min": -0.05, "max": 0.05, "default": 0.004,
            "hint": "Central difference step size for Ix/Iy gradients (normalized UV). Negative inverts gradient axis.",
            "label": "Scale",
            # No pix_target -- stage_a is the pix_chain's primary node,
            # so the default param wiring (-> primary_obj_id) is already
            # correct here.
        },
        {
            "name": "gain", "type": "float",
            "min": -10.0, "max": 10.0, "default": 1.0,
            "hint": "Output vecfield magnitude scale. Negative inverts flow direction.",
            "label": "Gain",
            "pix_target": "c",
        },
        {
            "name": "mask_lo", "type": "float",
            "min": 0.0, "max": 20.0, "default": 0.0,
            "hint": "Confidence-gate low threshold -- det values at or below this read as no-flow (neutral). Raise to suppress noise in low-texture/edge-only regions (the aperture problem). Added 2026-07-18 after real testing showed unmasked noise amplifying along real edges, not just in flat regions.",
            "label": "Mask Lo",
            "pix_target": "c",
        },
        {
            "name": "mask_hi", "type": "float",
            "min": 0.0, "max": 20.0, "default": 1.0,
            "hint": "Confidence-gate high threshold -- det values at or above this pass through at full strength. Widen the Lo/Hi gap for a softer transition, narrow it for a harder cutoff. det's real range was never precisely measured (T017) -- use this dial while watching the vecfield preview to find it empirically.",
            "label": "Mask Hi",
            "pix_target": "c",
        },
        {
            "name": "decay", "type": "float",
            "min": 0.0, "max": 1.5, "default": 0.9,
            "hint": "Per-frame persistence of the accumulated flow field. Above 1.0 allows a self-reinforcing/excitable regime (same convention as f_vf_advect's own decay param), rather than only ever fading. Added 2026-07-18 -- the raw per-frame LK solve, even correctly masked, felt too transitory to read as coherent flow direction.",
            "label": "Decay",
            "pix_target": "d",
        },
        {
            "name": "injection", "type": "float",
            "min": 0.0, "max": 2.0, "default": 0.3,
            "hint": "How strongly this frame's fresh solve blends into the accumulated field each frame.",
            "label": "Inject",
            "pix_target": "d",
        },
        {
            "name": "step", "type": "float",
            "min": -0.1, "max": 0.1, "default": 0.0015,
            "hint": "Stage B 5-tap window spacing (normalized UV), both horizontal and vertical passes. Bipolar range lets negative values invert tap direction if useful.",
            "label": "Step",
            "pix_target": "bh",
        },
        {
            "name": "reach", "type": "float",
            "min": 0.0, "max": 0.1, "default": 0.01,
            "hint": "Stage E directional-fill tap spacing (normalized UV) along the locally-ambiguous axis (T035). Same naming/role as f_vf_prism's own Reach dial.",
            "label": "Reach",
            "pix_target": "e",
        },
        {
            "name": "mix_pct", "type": "float",
            "min": 0.0, "max": 100.0, "default": 100.0,
            "widget": "numbox",
            "hint": "Stage E directional-fill dry/wet, 0-100%. Global control independent of per-pixel confidence -- lets the fill effect be dialed down or off entirely as a live performance control.",
            "label": "Mix",
            "pix_target": "e",
        },
        {"name": "bypass", "type": "bypass"},
    ],
}
