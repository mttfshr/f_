# f_tf_hatch patcher definition
# Input to build/build_patcher.py
# Spec: .specify/f_tf_hatch/{spec,plan,tasks}.md   Created: 2026-10-17
#
# ARCHITECTURE NOTE -- primary node vs. real output node
#
# Same shape as f_tf_tensormap (see its definition.py): the tensor texture
# must reach stage_e1 (the primary), but the real outlets come from stage_e3,
# the last node. Both outlets are redirected to e3 via `outlet_source`
# (the validated form; tensormap's outlet_source_override + raw_lines does
# the same job -- this module needs no raw_lines because no external object
# sits mid-chain). bypass_mode "param" with bypass_target "e3": the toggle
# drives `Param bypass_gate` in stage e3 only (never the native @bypass,
# which would skip the shader and flip secondary outlets); stages e1/e2 keep
# running under bypass by design (nothing reads their outputs then).
#
# Hardcoded object ids below are derived by hand from build_patcher.py's id
# formulas, NOT kept in sync automatically. Chain order [e1(primary), e2, e3]:
#   9 UI params (density, weight, softness, elongation, coherence_gate,
#   angle_offset, phase, regularity, width, height = 10) -> chain_id_base 50
#   support nodes: e2 = obj-50, e3 = obj-51
#   outlet ids: outlet 0 = obj-2, outlet 1 = obj-201
# If the param count or chain order changes, recompute these.
#
# Params reach non-primary stages via `pix_target` (the tensormap precedent:
# radius fans to two stages there; here density/weight/softness/elongation/
# phase/regularity target e3, strength/coherence_gate/angle_offset target
# e1). width/height are NOT used by this module (no measured tap step is
# needed: every texture read is at `norm`) -- see the params table note.
#
# The bench GPU wraps out-of-range reads; this module samples ONLY at `norm`
# (never offset taps), so the clamping rule is carried as the explicit
# clamp in stage e1 (codebox_stage_e1.gen).

CODEBOX_DIR = ""  # gen paths below are relative to this definition.py's own directory

patcher = {
    "name":        "f_tf_hatch",
    "prefix":      "hatch",
    "object_name": "#0_hatch_pix",
    "title":       "Hatch",
    # Header signal_type: the tensor-family amber "tensor" colour (tensormap
    # T030 added the colour; build_patcher.py SIGNAL_TYPE_COLORS). The
    # OUTLETS themselves are ordinary luma/texture renders (marks, not field
    # data): not tensor-typed -- plan ADR-7's note; per-outlet comments carry
    # the encoding hint so they are never wired as tensor/vecfield.
    "signal_type": "tensor out",
    "archetype":   "processor",
    "bypass_mode": "param",
    "bypass_target": "e3",

    "presentation_width":  154,
    "presentation_height": 84,

    "pix_chain": [
        {
            "id":        "e1",
            "name":      "#0_hatch_stage_e1",
            "gen":       "codebox_stage_e1.gen",
            "n_inlets":  1,
            "n_outlets": 1,
            "pix_type":  "float32",
            "primary":   True,
        },
        {
            "id":        "e2",
            "name":      "#0_hatch_stage_e2",
            "gen":       "codebox_stage_e2_T.gen",
            "n_inlets":  1,
            "n_outlets": 1,
            "pix_type":  "float32",
            "primary":   False,
        },
        {
            "id":        "e3",
            "name":      "#0_hatch_stage_e3",
            "gen":       "codebox_stage_e3.gen",
            "n_inlets":  1,
            "n_outlets": 2,
            "pix_type":  "float32",
            "primary":   False,
        },
    ],

    # [src_id, src_outlet, dst_id, dst_inlet]
    "pix_wires": [
        ["e1", 0, "e2", 0],   # (ca, sa, commit, iso) -> local-frame pass
        ["e2", 0, "e3", 0],   # (u, v, commit, iso)   -> profile + encode
    ],

    "outlets": [
        {"comment": "hatch output",
         "color": [0.55, 0.55, 0.55, 1.0],
         "hint": "Hatch marks, luma on black (color is downstream's job, the f_weave convention). Commit-weighted: coherently-line-structured regions render strokes, near-gate regions fade toward nothing; aspect rounds to dots as coherence falls (plan ADR-9). @type float32."},
        {"comment": "mark mask",
         "color": [0.55, 0.55, 0.55, 1.0],
         "hint": "Mark mask without the encode mix (same luma, the discrete-family convention, f_vf_seeds out1): for downstream compositing/gating. NOT a tensor and not a vecfield."},
    ],

    # Both outlets come from stage e3 (the encode stage), not the primary.
    "outlet_source": {0: ["e3", 0], 1: ["e3", 1]},

    "params": [
        {
            "name": "density", "type": "float",
            "min": 0.0, "max": 1.0, "default": 0.5,
            "hint": "Line/cell spacing, log-mapped: pitch = pow(2, density*5-1) (the family formula, f_weave's published span). PROVISIONAL default/lock pending tier-3 (spec OQ6).",
            "label": "Density",
            "pix_target": "e3",
        },
        {
            "name": "weight", "type": "float",
            "min": 0.0, "max": 0.5, "default": 0.1,
            "hint": "Mark thickness (across-axis half-extent, u units). PROVISIONAL (weave default). Note: the dash-length cap (ADR-9) un-caps as weight falls.",
            "label": "Weight",
            "pix_target": "e3",
        },
        {
            "name": "softness", "type": "float",
            "min": 0.0, "max": 0.49, "default": 0.05,
            "hint": "Edge feather, both axes: expands the multiplicative outer edge (weave's cited form). Clamped at 0.49. PROVISIONAL.",
            "label": "Softness",
            "pix_target": "e3",
        },
        {
            "name": "elongation", "type": "float",
            "min": 0.0, "max": 8.0, "default": 3.0,
            "hint": "Response-magnitude dial: max aspect of a mark at commit 1 (NOT the shape data -- that is per-pixel commit). Commit 0 = dot (aspect 1) regardless. Pitch-unit aspect caps where dashes merge: at weight 0.1/density 0.5 that is ~elongation 2.1 (ADR-9). PROVISIONAL.",
            "label": "Elongation",
            "pix_target": "e3",
        },
        {
            "name": "strength", "type": "float",
            "min": 1.0, "max": 1000.0, "default": 100.0,
            "hint": "Gain the producing tensormap applied to trace and the raw tensor "
                    "(f_tensor_type.md decode). Match it to the tensormap feeding this "
                    "module: the decode divides it back out. Log dial like tensormap's.",
            "label": "Strength",
            "pix_target": "e1",
        },
        {
            "name": "coherence_gate", "type": "float",
            "min": 0.0, "max": 1.0, "default": 0.25,
            "hint": "Commit floor: coherence at/below this renders nothing (the eps_trace guard is separate, below it). PROVISIONAL -- OQ3's gate-floor fallback (dots persist vs fade-in) is shipped as fade-in, tier-3 confirms.",
            "label": "Gate",
            "pix_target": "e1",
        },
        {
            "name": "angle_offset", "type": "float",
            "min": -1.0, "max": 1.0, "default": 0.0,
            "hint": "Rotates the pattern relative to the decoded axis: +-1 = +-90 deg (the axis is an unoriented line, so +-90 spans the distinct layouts). Zero keeps strokes along structure.",
            "label": "Offset",
            "pix_target": "e1",
        },
        {
            "name": "phase", "type": "float",
            "min": -1.0, "max": 1.0, "default": 0.0,
            "hint": "Scrolls marks along the stroke axis (phase 1.0 = one full dash pitch; connect an LFO for motion). Family-standard animation entry.",
            "label": "Phase",
            "pix_target": "e3",
        },
        {
            "name": "regularity", "type": "float",
            "min": 0.0, "max": 1.0, "default": 0.5,
            "hint": "Per-line dash stagger (weave's hash form): 1 = all lines in phase (grid-like), 0 = fully staggered, hash-stable across frames. PROVISIONAL.",
            "label": "Regularity",
            "pix_target": "e3",
        },
        {"name": "bypass", "type": "bypass"},
    ],
}

# Layout (mirrors the tensormap panel: 154x84, controls run to x ~ 150).
patcher["overrides"] = {
    "bypass_jsui": {"presentation_rect": [129.0, 5.0, 18.0, 12.0]},
    "signal_type": {"fontsize": 9.5, "presentation_rect": [62.0, 3.0, 60.0, 18.0]},
}
# END overrides