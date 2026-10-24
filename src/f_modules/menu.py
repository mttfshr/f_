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
    order WITHIN a category is alphabetical by display name (T_ Fields runs in pipeline order: map, smooth, sharpen);
    the README table is alphabetical by patch name.  Regrouped 2026-10-22 (.specify/f_modules_menu/).

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
    ("Patterns", [
        ("Chladni", "chladni", V),
        ("Grain", "grain", N),
        ("Kuramoto-Sivashinsky", "ks", N),
        ("Masonry", "masonry", N),
        ("Seeds", "vf_seeds", V),
        ("Stipple", "stipple", N),
        ("Weave", "weave", V),
        ("Wilson-Cowan", "wc", N),
    ]),
    ("Space & Optics", [
        ("Droste", "droste", N),
        ("Lens", "lens", N),
        ("Mobius", "mobius", N),
        ("Ngon", "ngon", N),
        ("SIRDS", "sirds", N),
        ("Stereo", "stereo", N),
    ]),
    ("Color / Tone", [
        ("Channel Grader", "channel_grader", N),
        ("Hue Processor", "hue_processor", N),
        ("Luma Processor", "luma_processor", N),
        ("Tone Curve", "tone_curve", N),
    ]),
    ("\u2207 Fields", [
        ("Flow", "vf_flow", V),
        ("Fluid", "vf_fluid", V),
        ("Lattice Boltzmann", "vf_lbm", V),
        ("Optical Flow", "vf_optical_flow", V),
        ("Repulse", "vf_repulse", V),
        ("Vortex", "vf_vortex", V),
        ("Vortex Multi", "vf_vortex_multi", V),
        ("Vorticity", "vf_vorticity", V),
    ]),
    ("\u2207 Effects", [
        ("Advect", "vf_advect", V),
        ("Caustic", "caustic", V),
        ("Chroma", "vf_chroma", V),
        ("Glow", "vf_glow", V),
        ("Prism", "vf_prism", V),
        ("Streak", "vf_streak", V),
        ("Warp", "vf_warp", V),
    ]),
    ("T_ Fields", [
        ("Tensormap", "tf_tensormap", T),
        ("Smooth", "tf_smooth", T),
        ("Sharpen", "tf_sharpen", T),
    ]),
    ("T_ Effects", [
        ("Aniso Blur", "tf_aniso_blur", T),
        ("Glyph", "tf_glyph", T),
        ("Hatch", "tf_hatch", T),
    ]),
    ("Adapters", [
        ("Axis Flow", "tf_axisflow", VT),
        ("Fieldmap", "vf_fieldmap", V),
        ("Potential", "vf_potential", V),
        ("Split", "vf_split", V),
    ]),
    ("Routing / Mod", [
        ("Matrix 2", "util_matrix_2", N),
        ("Profile", "util_profile", N),
        ("Tex Router", "texrouter", N),
    ]),
]

# Recipes: a tenth dropdown that places a row of modules, left to right in signal order (nothing is wired;
# build/generate_menu.py, addrecipe in package/javascript/f_addmod.js).  (display, [modules]); every module
# must be one of the menu modules above and a recipe needs at least two.  Most come from the module sets in
# package/examples/f_demo_*.maxpat (ordered along the signal path from docs/f-reference/module-inventory.md);
# "Tensor Advect" is not from a demo.  Added 2026-10-22; prune or reorder freely.
RECIPES = [
    ("Fieldmap Seeds", ["vf_fieldmap", "vf_seeds"]),                              # f_demo_seeds
    ("Fieldmap Streak", ["vf_fieldmap", "vf_streak"]),                            # f_demo_streak
    ("Fluid Caustic", ["ngon", "vf_fieldmap", "vf_fluid", "caustic"]),            # f_demo_caustic2
    ("Chladni Glow", ["chladni", "vf_fieldmap", "vf_glow"]),                      # f_demo_chladni
    ("Grain Warp", ["grain", "vf_fieldmap", "vf_warp"]),                          # f_demo_warp
    ("Masonry Repulse", ["masonry", "vf_repulse", "vf_advect"]),                  # f_demo_repulse
    ("Motion Prism", ["masonry", "vf_optical_flow", "vf_prism"]),                 # f_demo_prism-masonry
    ("Ngon Flow", ["ngon", "vf_flow", "vf_advect"]),                              # f_demo_ngon
    ("Repulse Caustic", ["vf_repulse", "caustic", "lens"]),                       # f_demo_lens
    ("SIRDS", ["grain", "sirds", "stereo"]),                                      # f_demo_sirds
    ("Tensor Advect", ["tf_tensormap", "tf_axisflow", "vf_advect"]),              # no demo
    ("Vorticity Fluid", ["vf_fieldmap", "vf_fluid", "vf_vorticity"]),             # f_demo_vorticity
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
    "f_formconstants": "in build: Phase 1 built 2026-10-24, bench + tuning pending; enters the menu at Phase 3",
}
