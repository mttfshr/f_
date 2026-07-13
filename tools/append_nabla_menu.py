import json

PATH = "/Users/matt/Github/f_/package/patchers/f_modules.maxpat"

# filenames (as they appear in the *_file live.menu enums) that take or
# produce an f_vecfield -- per README's f_vf_ family list plus the
# non-vf_-prefixed consumers/producers (f_caustic, f_lens's field inlet,
# f_weave's optional vecfield inlet, f_chladni's out2 vecfield outlet)
VECFIELD_MODULES = {
    "weave",
    "vf_seeds",
    "lens",
    "vf_prism",
    "vf_vortex",
    "vf_vortex_multi",
    "caustic",
    "vf_fieldmap",
    "vf_flow",
    "vf_repulse",
    "vf_warp",
    "vf_streak",
    "vf_glow",
    "vf_advect",
    "vf_chroma",
    "vf_split",
    "vf_potential",
    "chladni",
}

NABLA = " \u2207"

with open(PATH) as f:
    data = json.load(f)

boxes = data["patcher"]["boxes"]

# collect disp/file live.menu boxes keyed by slot index
by_slot = {}
for b in boxes:
    box = b["box"]
    if box.get("maxclass") != "live.menu":
        continue
    valueof = box["saved_attribute_attributes"]["valueof"]
    longname = valueof["parameter_longname"]
    # f_module_{N}_disp / f_module_{N}_file
    prefix, kind = longname.rsplit("_", 1)
    slot = int(prefix.split("_")[-1])
    by_slot.setdefault(slot, {})[kind] = valueof

changed = []
for slot, pair in sorted(by_slot.items()):
    disp = pair["disp"]["parameter_enum"]
    file_ = pair["file"]["parameter_enum"]
    assert len(disp) == len(file_)
    for i, fname in enumerate(file_):
        if fname in VECFIELD_MODULES and not disp[i].endswith(NABLA):
            disp[i] = disp[i] + NABLA
            changed.append((slot, fname, disp[i]))

with open(PATH, "w") as f:
    json.dump(data, f, indent=4)

for c in changed:
    print(c)
print(f"{len(changed)} labels updated")
