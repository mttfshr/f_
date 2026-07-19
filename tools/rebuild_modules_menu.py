import json

PATH = "/Users/matt/Github/f_/package/patchers/f_modules.maxpat"

# (category label, [(display, filename), ...])
CATEGORIES = [
    ("Scope", [
        ("Chladni", "chladni"),
    ]),
    ("Discrete", [
        ("Masonry", "masonry"),
        ("Stipple", "stipple"),
        ("Grain", "grain"),
        ("Weave", "weave"),
        ("Seeds", "vf_seeds"),
    ]),
    ("Spatial", [
        ("Mobius", "mobius"),
        ("Stereo", "stereo"),
        ("SIRDS", "sirds"),
        ("Droste", "droste"),
    ]),
    ("Optical", [
        ("Lens", "lens"),
        ("Prism", "vf_prism"),
    ]),
    ("∇ Generators", [
        ("Vortex", "vf_vortex"),
        ("Vortex Multi", "vf_vortex_multi"),
    ]),
    ("∇ Processors", [
        ("Caustic", "caustic"),
        ("Fieldmap", "vf_fieldmap"),
        ("Flow", "vf_flow"),
        ("Repulse", "vf_repulse"),
        ("Warp", "vf_warp"),
        ("Streak", "vf_streak"),
        ("Glow", "vf_glow"),
        ("Advect", "vf_advect"),
        ("Chroma", "vf_chroma"),
        ("Optical Flow", "vf_optical_flow"),
    ]),
    ("Color / Tone", [
        ("Channel Grader", "channel_grader"),
        ("Hue Processor", "hue_processor"),
        ("Luma Processor", "luma_processor"),
        ("Tone Curve", "tone_curve"),
    ]),
    ("Utilities", [
        ("Tex Router", "texrouter"),
        ("Profile", "util_profile"),
        ("Split", "vf_split"),
        ("Potential", "vf_potential"),
        ("Matrix 2", "util_matrix_2"),
    ]),
]

with open(PATH) as f:
    data = json.load(f)

patcher = data["patcher"]
boxes = patcher["boxes"]

# Keep obj-1..obj-6 (the header panel/comment + addmod/gate/pipe/loadmess plumbing)
keep_ids = {f"obj-{i}" for i in range(1, 7)}
kept_boxes = [b for b in boxes if b["box"]["id"] in keep_ids]

new_boxes = []
new_lines = []
new_params = {}
menu_counter = 0
obj_id_num = 7

TEXTCOLOR = [0.45098039215686275, 0.47058823529411764, 0.5764705882352941, 1.0]

for slot_idx, (label, modules) in enumerate(CATEGORIES):
    comment_id = f"obj-{obj_id_num}"; obj_id_num += 1
    disp_id = f"obj-{obj_id_num}"; obj_id_num += 1
    file_id = f"obj-{obj_id_num}"; obj_id_num += 1
    prepend_id = f"obj-{obj_id_num}"; obj_id_num += 1

    comment_y = 25.0 + 43.0 * slot_idx
    disp_pres_y = comment_y + 21.0
    disp_patch_y = 600.0 + 100.0 * slot_idx
    file_patch_y = 1500.0 + 100.0 * slot_idx
    prepend_patch_y = 2500.0 + 100.0 * slot_idx

    disp_names = [m[0] for m in modules]
    file_names = [m[1] for m in modules]
    mmax = len(modules) - 1

    new_boxes.append({
        "box": {
            "fontface": 0,
            "fontname": "Ableton Sans Light",
            "fontsize": 12.0,
            "id": comment_id,
            "maxclass": "comment",
            "numinlets": 1,
            "numoutlets": 0,
            "patching_rect": [3.0, comment_y, 176.0, 21.0],
            "presentation": 1,
            "presentation_rect": [2.0, comment_y, 89.66666933894157, 21.0],
            "text": label,
            "textcolor": TEXTCOLOR,
        }
    })

    disp_varname = "live.menu" if menu_counter == 0 else f"live.menu[{menu_counter}]"
    menu_counter += 1
    new_boxes.append({
        "box": {
            "appearance": 1,
            "fontname": "Ableton Sans Light",
            "fontsize": 11.0,
            "id": disp_id,
            "lcdcolor": [0.8, 0.8, 0.8, 1.0],
            "maxclass": "live.menu",
            "numinlets": 1,
            "numoutlets": 3,
            "outlettype": ["", "", "float"],
            "parameter_enable": 1,
            "parameter_mappable": 0,
            "patching_rect": [3.0, disp_patch_y, 154.0, 17.0],
            "presentation": 1,
            "presentation_rect": [3.0, disp_pres_y, 89.66666933894157, 17.0],
            "saved_attribute_attributes": {
                "lcdcolor": {"expression": "themecolor.live_arranger_grid_tiles"},
                "valueof": {
                    "parameter_enum": disp_names,
                    "parameter_initial": [0.0],
                    "parameter_invisible": 2,
                    "parameter_longname": f"f_module_{slot_idx}_disp",
                    "parameter_mmax": mmax,
                    "parameter_modmode": 0,
                    "parameter_shortname": "live.menu",
                    "parameter_type": 2,
                },
            },
            "varname": disp_varname,
        }
    })

    file_varname = f"live.menu[{menu_counter}]"
    menu_counter += 1
    new_boxes.append({
        "box": {
            "id": file_id,
            "maxclass": "live.menu",
            "numinlets": 1,
            "numoutlets": 3,
            "outlettype": ["", "", "float"],
            "parameter_enable": 1,
            "parameter_mappable": 0,
            "patching_rect": [3.0, file_patch_y, 154.0, 15.0],
            "saved_attribute_attributes": {
                "valueof": {
                    "parameter_enum": file_names,
                    "parameter_initial": [0.0],
                    "parameter_invisible": 2,
                    "parameter_longname": f"f_module_{slot_idx}_file",
                    "parameter_mmax": mmax,
                    "parameter_modmode": 0,
                    "parameter_shortname": "live.menu",
                    "parameter_type": 2,
                },
            },
            "varname": file_varname,
        }
    })

    new_boxes.append({
        "box": {
            "id": prepend_id,
            "maxclass": "newobj",
            "numinlets": 1,
            "numoutlets": 1,
            "outlettype": [""],
            "patching_rect": [3.0, prepend_patch_y, 100.0, 22.0],
            "text": "prepend addmod",
        }
    })

    new_lines.append({"patchline": {"source": [disp_id, 0], "destination": [file_id, 0]}})
    new_lines.append({"patchline": {"source": [file_id, 1], "destination": [prepend_id, 0]}})
    new_lines.append({"patchline": {"source": [prepend_id, 0], "destination": ["obj-4", 1]}})

    new_params[disp_id] = [f"f_module_{slot_idx}_disp", "live.menu", 0]
    new_params[file_id] = [f"f_module_{slot_idx}_file", "live.menu", 0]

patcher["boxes"] = kept_boxes + new_boxes

head_lines = [
    {"patchline": {"source": ["obj-6", 0], "destination": ["obj-5", 0]}},
    {"patchline": {"source": ["obj-5", 0], "destination": ["obj-4", 0]}},
    {"patchline": {"source": ["obj-4", 0], "destination": ["obj-3", 0]}},
]
patcher["lines"] = head_lines + new_lines

old_params = patcher["parameters"]
patcher["parameters"] = {
    **new_params,
    "parameterbanks": old_params["parameterbanks"],
    "inherited_shortname": old_params["inherited_shortname"],
}

with open(PATH, "w") as f:
    json.dump(data, f, indent=4)

print("done. slots:", len(CATEGORIES), "total boxes:", len(patcher["boxes"]), "next obj id:", obj_id_num)
