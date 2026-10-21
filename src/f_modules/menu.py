"""
src/f_modules/menu.py -- the data behind package/patchers/f_modules.maxpat (the module menu) and the
SIZES table in package/javascript/f_addmod.js.  Read by build/generate_menu.py; never hand-edit either
generated file, edit this and regenerate:

    build/py.sh build/generate_menu.py            # write both
    build/py.sh build/generate_menu.py --check    # exit 1 if either is stale or a check fails

(build_cleanup T020/T021, 2026-10-05.  Replaces tools/rebuild_modules_menu.py and
tools/append_nabla_menu.py, which hard-coded this table and edited the patcher in place.)

MARKS  {kind: suffix}
    The type marks.  A module's display label gets the suffix of every kind it carries, vecfield
    first: "Caustic \u2207", "Smooth T_", "Axis Flow \u2207 T_".  A category whose label starts with a
    mark (a nabla, or "T_") holds only modules that carry that kind.

CATEGORIES  [(label, [(display, module, kinds), ...]), ...]
    In menu order.  `module` is the name without the f_ prefix (the file is f_<module>.maxpat).
    `kinds` is a tuple of mark kinds the module takes or produces: V (an f_vecfield), T (an f_tensor,
    see docs/f-reference/f_tensor_type.md), VT (both: f_tf_axisflow reads a tensor and writes a
    vecfield), or N (neither).  The category labels and their membership must match the README
    Patches table (the same table build/generate_launch.py reads), in the same order.  The module
    order WITHIN a category is the menu's own (by visual character, newest last; the T_ category
    runs in pipeline order), not the README's alphabetical order.

SIZE_OVERRIDES  {module: ([w, h], reason)}
    f_addmod.js inserts a module as a bpatcher of this size.  The size is the module's presentation
    panel rect, rounded to whole pixels, unless listed here: these are modules whose content extends
    past their panel.  An override equal to the panel size is a stale override and fails the check.

NOT_IN_MENU  {module: reason}
    Every shipped patcher must be in a category or here, so a new module cannot be forgotten.
"""

MARKS = {"vec": " \u2207", "tensor": " T_"}

N = ()
V = ("vec",)
T = ("tensor",)
VT = ("vec", "tensor")

CATEGORIES = [
    ("Scope", [
        ("Chladni", "chladni", V),
    ]),
    ("Discrete", [
        ("Masonry", "masonry", N),
        ("Stipple", "stipple", N),
        ("Grain", "grain", N),
        ("Weave", "weave", V),
        ("Seeds", "vf_seeds", V),
        ("Kuramoto-Sivashinsky", "ks", N),
    ]),
    ("Spatial", [
        ("Mobius", "mobius", N),
        ("Stereo", "stereo", N),
        ("SIRDS", "sirds", N),
        ("Droste", "droste", N),
        ("Ngon", "ngon", N),
    ]),
    ("Optical", [
        ("Lens", "lens", N),
        ("Prism", "vf_prism", V),
    ]),
    ("Color / Tone", [
        ("Channel Grader", "channel_grader", N),
        ("Hue Processor", "hue_processor", N),
        ("Luma Processor", "luma_processor", N),
        ("Tone Curve", "tone_curve", N),
    ]),
    ("\u2207 Generators", [
        ("Vortex", "vf_vortex", V),
        ("Vortex Multi", "vf_vortex_multi", V),
    ]),
    ("\u2207 Processors", [
        ("Caustic", "caustic", V),
        ("Fieldmap", "vf_fieldmap", V),
        ("Flow", "vf_flow", V),
        ("Repulse", "vf_repulse", V),
        ("Warp", "vf_warp", V),
        ("Streak", "vf_streak", V),
        ("Glow", "vf_glow", V),
        ("Advect", "vf_advect", V),
        ("Chroma", "vf_chroma", V),
        ("Optical Flow", "vf_optical_flow", V),
        ("Fluid", "vf_fluid", V),
    ]),
    ("T_ Tensor", [
        ("Tensormap", "tf_tensormap", T),
        ("Smooth", "tf_smooth", T),
        ("Sharpen", "tf_sharpen", T),
        ("Aniso Blur", "tf_aniso_blur", T),
        ("Hatch", "tf_hatch", T),
        ("Glyph", "tf_glyph", T),
        ("Axis Flow", "tf_axisflow", VT),
    ]),
    ("Utilities", [
        ("Tex Router", "texrouter", N),
        ("Profile", "util_profile", N),
        ("Split", "vf_split", V),
        ("Potential", "vf_potential", V),
        ("Matrix 2", "util_matrix_2", N),
    ]),
]

SIZE_OVERRIDES = {
    "chladni":         ([299, 234], "its dials and plate view extend past the 227 x 164 panel"),
    "vf_vortex_multi": ([191, 284], "one pixel wider and taller than its 190 x 283 panel, as shipped"),
    "vf_seeds":        ([190, 205], "its bottom dials sit below the 160 px panel (HANDOFF, small items)"),
}

NOT_IN_MENU = {
    "f_modules":       "the menu itself",
    "f_a_ripple":      "audio (gen~) module, not a Vsynth bpatcher; unfinished (README marks it)",
    "f_a_decorrelate": "audio (pfft~) module, not a Vsynth bpatcher; DSP built, packaging pending (README marks it)",
    "f_chladni_audio": "audio companion of f_chladni, not a Vsynth bpatcher (README marks it)",
    "f_vf_vorticity":  "never completed; plan.md: do not register it in the menu until verified",
}
