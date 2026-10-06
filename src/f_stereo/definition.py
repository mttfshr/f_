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
    "archetype":          "processor",
    "pix_type":           "char",
    "route_bypass":       True,   # the oldest modules route a `bypass 0/1` message to the toggle

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
        {"name": "circ",   "type": "text_button", "options": ["full", "mask"], "default": 1, "label": "Circ", "hint": None},
        {"name": "bypass", "type": "bypass"},
    ],

    "codebox": (Path(__file__).parent / "codebox_v1.gen").read_text(),
}

# BEGIN overrides (build/capture.py rewrites only this block)
patcher["overrides"] = {
    "circ.ctl": {"activebgcolor": [0.06666666666666667, 0.06274509803921569, 0.06274509803921569, 1.0], "activebgoncolor": [0.06666666666666667, 0.06274509803921569, 0.06274509803921569, 1.0], "activetextcolor": [0.7568627450980392, 0.7568627450980392, 0.7568627450980392, 1.0], "activetextoncolor": [0.6588235294117647, 0.6588235294117647, 0.6588235294117647, 1.0], "bordercolor": [0.8, 0.8, 0.8, 1.0], "presentation_rect": [102.5, 4.5, 32.5, 14.0], "rounded": 4.0},
    "lat.ctl": {"presentation_rect": [45.333333333333336, 40.0, 27.0, 43.0]},
    "lat.label": {"presentation_rect": [49.0, 24.0, 36.0, 18.0], "textjustification": None},
    "lon.ctl": {"presentation_rect": [8.0, 40.0, 27.0, 43.0]},
    "lon.label": {"presentation_rect": [10.0, 24.0, 36.0, 18.0], "textjustification": None},
    "panel": {"presentation_rect": [0.0, 0.0, 159.5, 90.0]},
    "proj.ctl": {"presentation_rect": [120.0, 40.0, 27.0, 43.0]},
    "proj.label": {"presentation_rect": [120.0, 24.0, 36.0, 18.0], "textjustification": None},
    "spin.ctl": {"presentation_rect": [82.66666666666667, 40.0, 27.0, 43.0]},
    "spin.label": {"presentation_rect": [82.0, 24.0, 36.0, 18.0], "textjustification": None},
    "title": {"linecount": 2, "presentation_rect": [0.0, 1.0, 101.5, 21.0]},
}
# END overrides
