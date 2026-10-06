"""
src/f_modules/menu.py -- the data behind package/patchers/f_modules.maxpat (the module menu) and the
SIZES table in package/javascript/f_addmod.js.  Read by build/generate_menu.py; never hand-edit either
generated file, edit this and regenerate:

    build/py.sh build/generate_menu.py            # write both
    build/py.sh build/generate_menu.py --check    # exit 1 if either is stale or a check fails

(build_cleanup T020/T021, 2026-10-05.  Replaces tools/rebuild_modules_menu.py and
tools/append_nabla_menu.py, which hard-coded this table and edited the patcher in place.)

CATEGORIES  [(label, [(display, module, vecfield), ...]), ...]
    In menu order.  `module` is the name without the f_ prefix (the file is f_<module>.maxpat).
    `vecfield` True appends the nabla mark to the display label: the module takes or produces an
    f_vecfield.  The category labels and their membership must match the README Patches table
    (the same table build/generate_launch.py reads); a category whose label starts with a nabla
    holds vecfield modules only.  The module order WITHIN a category is the menu's own (by visual
    character, newest last), not the README's alphabetical order.

SIZE_OVERRIDES  {module: ([w, h], reason)}
    f_addmod.js inserts a module as a bpatcher of this size.  The size is the module's presentation
    panel rect, rounded to whole pixels, unless listed here: these are modules whose content extends
    past their panel.  An override equal to the panel size is a stale override and fails the check.

NOT_IN_MENU  {module: reason}
    Every shipped patcher must be in a category or here, so a new module cannot be forgotten.
"""

NABLA = " \u2207"

CATEGORIES = [
    ("Scope", [
        ("Chladni", "chladni", True),
    ]),
    ("Discrete", [
        ("Masonry", "masonry", False),
        ("Stipple", "stipple", False),
        ("Grain", "grain", False),
        ("Weave", "weave", True),
        ("Seeds", "vf_seeds", True),
    ]),
    ("Spatial", [
        ("Mobius", "mobius", False),
        ("Stereo", "stereo", False),
        ("SIRDS", "sirds", False),
        ("Droste", "droste", False),
        ("Ngon", "ngon", False),
    ]),
    ("Optical", [
        ("Lens", "lens", False),
        ("Prism", "vf_prism", True),
    ]),
    ("\u2207 Generators", [
        ("Vortex", "vf_vortex", True),
        ("Vortex Multi", "vf_vortex_multi", True),
    ]),
    ("\u2207 Processors", [
        ("Caustic", "caustic", True),
        ("Fieldmap", "vf_fieldmap", True),
        ("Flow", "vf_flow", True),
        ("Repulse", "vf_repulse", True),
        ("Warp", "vf_warp", True),
        ("Streak", "vf_streak", True),
        ("Glow", "vf_glow", True),
        ("Advect", "vf_advect", True),
        ("Chroma", "vf_chroma", True),
        ("Optical Flow", "vf_optical_flow", True),
        ("Fluid", "vf_fluid", True),
    ]),
    ("Color / Tone", [
        ("Channel Grader", "channel_grader", False),
        ("Hue Processor", "hue_processor", False),
        ("Luma Processor", "luma_processor", False),
        ("Tone Curve", "tone_curve", False),
    ]),
    ("Utilities", [
        ("Tex Router", "texrouter", False),
        ("Profile", "util_profile", False),
        ("Split", "vf_split", True),
        ("Potential", "vf_potential", True),
        ("Matrix 2", "util_matrix_2", False),
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
    "f_chladni_audio": "audio companion of f_chladni, not a Vsynth bpatcher (README marks it)",
    "f_vf_vorticity":  "never completed; plan.md: do not register it in the menu until verified",
}
