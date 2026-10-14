"""Build the js-driven export trial patcher (v2).

The JSON-only patcher lost 4 patchcords on load in Max 9.2 -- instead of
fighting the loader, this version is a single newobj `js export_trial.js`
plus a loadbang; the js builds and drives everything programmatically.
"""
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent

boxes = [
    {"box": {"id": "driver", "maxclass": "newobj", "text": "js export_trial.js",
             "numinlets": 1, "numoutlets": 1, "outlettype": [""],
             "patching_rect": [40.0, 40.0, 130.0, 22.0]}},
    {"box": {"id": "lb", "maxclass": "newobj", "text": "loadbang",
             "numinlets": 1, "numoutlets": 1, "outlettype": ["bang"],
             "patching_rect": [40.0, 10.0, 50.0, 22.0]}},
]
lines = [{"patchline": {"source": ["lb", 0], "destination": ["driver", 0]}}]

patcher = {
    "fileversion": 1,
    "appversion": {"major": 9, "minor": 2, "revision": 0, "architecture": "x64", "modernui": 1},
    "patcher": {"boxes": boxes, "lines": lines, "params": []},
}
(HERE / "split_export_js.maxpat").write_text(json.dumps(patcher, indent=1))
print("wrote split_export_js.maxpat")