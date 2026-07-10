import json, glob

FILES = [
    "f_caustic", "f_vf_advect", "f_vf_chroma", "f_vf_fieldmap", "f_vf_flow",
    "f_vf_glow", "f_vf_potential", "f_vf_prism", "f_vf_repulse", "f_vf_seeds",
    "f_vf_split", "f_vf_streak", "f_vf_vortex", "f_vf_vortex_multi",
    "f_vf_vorticity", "f_vf_warp",
]

BASE = "/Users/matt/Github/f_/patchers/{}.maxpat"

def walk(obj, boxes):
    if isinstance(obj, dict):
        if "box" in obj and isinstance(obj["box"], dict):
            boxes.append(obj["box"])
        for v in obj.values():
            walk(v, boxes)
    elif isinstance(obj, list):
        for v in obj:
            walk(v, boxes)

for name in FILES:
    path = BASE.format(name)
    with open(path) as f:
        data = json.load(f)
    boxes = []
    walk(data, boxes)

    has_in = False
    has_out = False
    header_boxes = []
    for b in boxes:
        mc = b.get("maxclass")
        if mc == "inlet" and "vecfield" in str(b.get("comment", "")).lower():
            has_in = True
        elif mc == "outlet" and "vecfield" in str(b.get("comment", "")).lower():
            has_out = True
        elif mc == "comment" and str(b.get("text", "")).strip().lower() == "vecfield":
            header_boxes.append(b.get("id"))

    if has_in and has_out:
        label = "vecfield in/out"
    elif has_in:
        label = "vecfield in"
    elif has_out:
        label = "vecfield out"
    else:
        label = "vecfield ???"

    print(f"{name:25s} in={has_in!s:5} out={has_out!s:5} header_boxes={header_boxes}  -> {label}")
