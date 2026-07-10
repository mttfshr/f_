import json

BASE = "/Users/matt/Github/f_/patchers/{}.maxpat"

LABELS = {
    "f_caustic": "vecfield in",
    "f_vf_advect": "vecfield in",
    "f_vf_chroma": "vecfield in",
    "f_vf_fieldmap": "vecfield out",
    "f_vf_flow": "vecfield out",
    "f_vf_glow": "vecfield in",
    "f_vf_potential": "vecfield in",
    "f_vf_prism": "vecfield in",
    "f_vf_repulse": "vecfield out",
    "f_vf_seeds": "vecfield in",
    "f_vf_split": "vecfield in",
    "f_vf_streak": "vecfield in",
    "f_vf_vortex": "vecfield out",
    "f_vf_vortex_multi": "vecfield out",
    "f_vf_vorticity": "vecfield in/out",
    "f_vf_warp": "vecfield in",
}

def walk(obj, boxes):
    if isinstance(obj, dict):
        if "box" in obj and isinstance(obj["box"], dict):
            boxes.append(obj["box"])
        for v in obj.values():
            walk(v, boxes)
    elif isinstance(obj, list):
        for v in obj:
            walk(v, boxes)

for name, label in LABELS.items():
    path = BASE.format(name)
    with open(path) as f:
        data = json.load(f)
    boxes = []
    walk(data, boxes)

    updated = 0
    for b in boxes:
        if b.get("maxclass") == "comment" and str(b.get("text", "")).strip().lower() == "vecfield":
            b["text"] = label
            updated += 1

    if updated != 1:
        print(f"WARNING: {name} updated {updated} header comments (expected 1)")
        continue

    with open(path, "w") as f:
        json.dump(data, f, indent=4)
    print(f"{name}: -> \"{label}\"")
