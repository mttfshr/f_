# f_stereo patcher definition.
#
# Written 2026-10-05 (build_cleanup/T007) from the shipped, hand-built patcher, which had
# no definition.  The codebox is the shipped one, including the 2026-10-04 `PI` -> `pi_val`
# rename (Max 9.2.0 refuses to compile an assignment to a predefined constant; see
# skills/jit-gen-codebox).  The layout and a few widgets of the shipped patch predate the
# schema, so `build/drift.py f_stereo -v` still reports differences; closing them is
# build_cleanup Phase 3.
from pathlib import Path

patcher = {
    "name":               "f_stereo",
    "prefix":             "stereo",
    "object_name":        "stereo_pix",
    "title":              "Stereo Projection",
    "signal_type":        "texture",
    "archetype":          "processor",
    "pix_type":           "char",

    "presentation_width":  160,
    "presentation_height": 90,

    "outlets": [
        {"comment": "texture"},
    ],

    "params": [
        {"name": "lon",    "type": "float", "min": 0.0,  "max": 1.0, "default": 0.5, "label": "Lon",  "hint": "lon"},
        {"name": "lat",    "type": "float", "min": -1.0, "max": 1.0, "default": 0.5, "label": "Lat",  "hint": "lat"},
        {"name": "spin",   "type": "float", "min": 0.0,  "max": 1.0, "default": 0.0, "label": "Spin", "hint": "spin"},
        {"name": "proj",   "type": "float", "min": -2.0, "max": 2.0, "default": 0.0, "label": "Proj", "hint": "proj"},
        {"name": "circ",   "type": "text_button", "options": ["full", "mask"], "default": 1, "label": "Circ", "hint": "circ"},
        {"name": "bypass", "type": "bypass"},
    ],

    "codebox": (Path(__file__).parent / "codebox_v1.gen").read_text(),
}
