# f_texrouter patcher definition
# Input to tools/build_patcher.py
# Last updated: 2026-06-15
#
# Note: f_texrouter is a routing utility -- no gen codebox.
# Implemented with live.toggle matrix, pattrstorage, and js routing logic.

CODEBOX = None

patcher = {
    "name":        "f_texrouter",
    "prefix":      "texrouter",
    "object_name": "texrouter",
    "title":       "Tex Router",
    "archetype":   "utility",  # not a gen processor

    "presentation_width":  227,
    "presentation_height": 164,

    # Externally addressable messages on in0
    # Matrix cells 0-15 set routing; bang triggers preset recall
    "params": [
        {"name": "bang",    "type": "internal"},  # trigger -- not a continuous param
        # cells 0-15 are matrix routing values, not dials
        # document as a group rather than 16 individual params
    ],

    "outlets": [
        {"comment": "out0"},
        {"comment": "out1"},
        {"comment": "out2"},
        {"comment": "out3"},
    ],

    "codebox": CODEBOX,

    "notes": (
        "4x4 texture routing matrix. "
        "Send integer cell index + value to route textures: e.g. '0 1' routes in0 to out0. "
        "Matrix cells 0-15 address the 4x4 grid row-major. "
        "bypass = freeze (hold last frame), not pass-through. "
        "Preset system: pattrstorage stores/recalls named routing configurations."
    ),
}
