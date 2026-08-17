{
    "patcher": {
        "fileversion": 1,
        "appversion": {
            "major": 9,
            "minor": 1,
            "revision": 4,
            "architecture": "x64",
            "modernui": 1
        },
        "classnamespace": "box",
        "rect": [ 62.0, 179.0, 1000.0, 780.0 ],
        "boxes": [
            {
                "box": {
                    "bgmode": 1,
                    "border": 1,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-1",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vsc_presets.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "" ],
                    "patching_rect": [ 854.0, 164.0, 170.0, 144.5 ],
                    "varname": "vs_presets",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "autorestore": "chladni-scratch.json",
                    "hidden": 1,
                    "id": "obj-40",
                    "linecount": 2,
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 854.0, 251.0, 138.0, 35.0 ],
                    "priority": {
                        "vs_wfg_polarizer::pm_range": -1,
                        "vs_wfg_polarizer::lock_freq": -1,
                        "vs_offset+rot::offrot_anglemenu": -1,
                        "vs_offset+rot::offrot_x_range": -1,
                        "vs_offset+rot::offrot_y_range": -1
                    },
                    "saved_object_attributes": {
                        "client_rect": [ 854, 172, 1208, 300 ],
                        "parameter_enable": 0,
                        "parameter_mappable": 0,
                        "storage_rect": [ 766, 44, 1220, 302 ]
                    },
                    "text": "pattrstorage @greedy 1 @changemode 1",
                    "varname": "Vsynth"
                }
            },
            {
                "box": {
                    "id": "obj-39",
                    "maxclass": "newobj",
                    "numinlets": 3,
                    "numoutlets": 1,
                    "outlettype": [ "float" ],
                    "patching_rect": [ 656.0, 404.0, 67.0, 22.0 ],
                    "text": "slide 20 20"
                }
            },
            {
                "box": {
                    "id": "obj-38",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "float" ],
                    "patching_rect": [ 741.0, 329.0, 84.0, 22.0 ],
                    "text": "sigmund~ env"
                }
            },
            {
                "box": {
                    "bgmode": 1,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-37",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_vf_fieldmap.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 514.0, 579.0, 152.0, 86.0 ],
                    "varname": "f_vf_fieldmap",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 1,
                    "border": 1,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-36",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_offset+rot.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 101.0, 671.0, 178.0, 71.0 ],
                    "varname": "vs_offset+rot",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "id": "obj-35",
                    "linecount": 2,
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 813.0, 479.0, 50.0, 35.0 ],
                    "text": "54.371519"
                }
            },
            {
                "box": {
                    "id": "obj-29",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 579.0, 452.5, 49.0, 22.0 ],
                    "text": "note $1"
                }
            },
            {
                "box": {
                    "id": "obj-25",
                    "maxclass": "gain~",
                    "multichannelvariant": 0,
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "signal", "" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 787.0, 115.0, 22.0, 140.0 ]
                }
            },
            {
                "box": {
                    "id": "obj-23",
                    "maxclass": "ezadc~",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "signal", "signal" ],
                    "patching_rect": [ 831.5, 42.0, 45.0, 45.0 ]
                }
            },
            {
                "box": {
                    "bgmode": 1,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-22",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_lens.maxpat",
                    "numinlets": 5,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 270.0, 212.0, 175.0, 155.0 ],
                    "varname": "f_lens",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 1,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-19",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_vf_advect.maxpat",
                    "numinlets": 2,
                    "numoutlets": 3,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 281.0, 558.0, 193.0, 152.0 ],
                    "varname": "f_vf_advect",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 1,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-18",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_vf_glow.maxpat",
                    "numinlets": 3,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 276.0, 413.0, 190.0, 120.0 ],
                    "varname": "f_vf_glow",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 0,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-17",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_modules.maxpat",
                    "numinlets": 0,
                    "numoutlets": 0,
                    "offset": [ 0.0, 0.0 ],
                    "patching_rect": [ 543.0, 21.0, 104.0, 387.0 ],
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 0,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-16",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_chladni.maxpat",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 270.0, 12.25, 234.5, 164.0 ],
                    "varname": "f_chladni",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 1,
                    "border": 1,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-15",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_preview.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 731.5, 539.0, 245.0, 183.0 ],
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 1,
                    "border": 1,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-13",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_wfg_polarizer.maxpat",
                    "numinlets": 2,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 13.0, 375.0, 220.0, 132.0 ],
                    "varname": "vs_wfg_polarizer",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 1,
                    "border": 1,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-12",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_output.maxpat",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "offset": [ 0.0, 0.0 ],
                    "patching_rect": [ 128.0, 744.0, 157.0, 22.0 ],
                    "varname": "vs_output",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 1,
                    "border": 1,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-11",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_render.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "" ],
                    "patching_rect": [ 110.0, 21.0, 96.85526317358028, 146.5 ],
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 1,
                    "border": 1,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-10",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_modules.maxpat",
                    "numinlets": 0,
                    "numoutlets": 0,
                    "offset": [ 0.0, 0.0 ],
                    "patching_rect": [ 25.0, 21.0, 79.0, 316.0 ],
                    "viewvisibility": 1
                }
            }
        ],
        "lines": [
            {
                "patchline": {
                    "color": [ 0.65, 0.65, 0.65, 0.0 ],
                    "destination": [ "obj-40", 0 ],
                    "hidden": 1,
                    "source": [ "obj-1", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-16", 0 ],
                    "source": [ "obj-13", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-15", 0 ],
                    "order": 1,
                    "source": [ "obj-16", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-19", 1 ],
                    "order": 0,
                    "source": [ "obj-16", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-22", 0 ],
                    "source": [ "obj-16", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-19", 0 ],
                    "source": [ "obj-18", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-36", 0 ],
                    "source": [ "obj-19", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-37", 0 ],
                    "source": [ "obj-19", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-18", 0 ],
                    "source": [ "obj-22", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-25", 0 ],
                    "source": [ "obj-23", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-38", 0 ],
                    "source": [ "obj-25", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-16", 0 ],
                    "source": [ "obj-29", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-12", 0 ],
                    "source": [ "obj-36", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-18", 1 ],
                    "source": [ "obj-37", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-35", 1 ],
                    "order": 0,
                    "source": [ "obj-38", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-39", 0 ],
                    "order": 1,
                    "source": [ "obj-38", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-29", 0 ],
                    "source": [ "obj-39", 0 ]
                }
            }
        ],
        "parameters": {
            "obj-10::obj-14": [ "live.menu[30]", "live.menu", 0 ],
            "obj-10::obj-16": [ "live.menu[31]", "live.menu", 0 ],
            "obj-10::obj-18": [ "live.menu[32]", "live.menu", 0 ],
            "obj-10::obj-2": [ "live.menu", "live.menu", 0 ],
            "obj-10::obj-22": [ "live.menu[33]", "live.menu", 0 ],
            "obj-10::obj-24": [ "live.menu[9]", "live.menu", 0 ],
            "obj-10::obj-25": [ "live.menu[10]", "live.menu", 0 ],
            "obj-10::obj-26": [ "live.menu[11]", "live.menu", 0 ],
            "obj-10::obj-27": [ "live.menu[12]", "live.menu", 0 ],
            "obj-10::obj-29": [ "live.menu[13]", "live.menu", 0 ],
            "obj-10::obj-30": [ "live.menu[14]", "live.menu", 0 ],
            "obj-10::obj-33": [ "live.menu[15]", "live.menu", 0 ],
            "obj-10::obj-36": [ "live.menu[3]", "live.menu", 0 ],
            "obj-10::obj-52": [ "live.menu[4]", "live.menu", 0 ],
            "obj-10::obj-53": [ "live.menu[5]", "live.menu", 0 ],
            "obj-10::obj-56": [ "live.menu[6]", "live.menu", 0 ],
            "obj-11::obj-19": [ "dim_x[2]", "dim_x", 0 ],
            "obj-11::obj-23": [ "pwm[1]", "pwm", 0 ],
            "obj-11::obj-36": [ "live.text[11]", "live.text", 0 ],
            "obj-11::obj-40": [ "live.text[6]", "live.text", 0 ],
            "obj-11::obj-41": [ "dim_y[2]", "dim_y", 0 ],
            "obj-11::obj-42": [ "dim_x[3]", "dim_x", 0 ],
            "obj-11::obj-45": [ "live.text[10]", "live.text", 0 ],
            "obj-11::obj-48": [ "live.text[7]", "live.text", 0 ],
            "obj-11::obj-5": [ "live.text[9]", "live.text", 0 ],
            "obj-11::obj-6": [ "live.text[8]", "live.text", 0 ],
            "obj-12::obj-1": [ "toggle[1]", "toggle[1]", 0 ],
            "obj-12::obj-10": [ "toggle[3]", "toggle[2]", 0 ],
            "obj-12::obj-36": [ "uppr_x", "uppr_x", 0 ],
            "obj-13::obj-10": [ "bias", "Bias", 0 ],
            "obj-13::obj-14": [ "bm", "BM", 0 ],
            "obj-13::obj-17": [ "live.menu[41]", "live.menu", 0 ],
            "obj-13::obj-22": [ "live.text[3]", "live.text", 0 ],
            "obj-13::obj-29": [ "freq", "Freq", 0 ],
            "obj-13::obj-30": [ "angle", "Angle", 0 ],
            "obj-13::obj-42": [ "live.toggle[2]", "live.toggle", 0 ],
            "obj-13::obj-47": [ "polarizer", "Morph", 0 ],
            "obj-13::obj-51": [ "live.menu[40]", "live.menu", 0 ],
            "obj-13::obj-53": [ "speed", "Speed", 0 ],
            "obj-13::obj-54": [ "morph", "Morph", 0 ],
            "obj-13::obj-6": [ "pm", "PM", 0 ],
            "obj-13::obj-65": [ "shape", "Shape", 0 ],
            "obj-13::obj-71": [ "phase", "Phase", 0 ],
            "obj-13::obj-72": [ "phase_time_switch", "phase_time_switch", 0 ],
            "obj-16::obj-20": [ "note", "note", 0 ],
            "obj-16::obj-23": [ "amp", "amp", 0 ],
            "obj-16::obj-26": [ "dishradius", "dishradius", 0 ],
            "obj-16::obj-29": [ "reflectamt", "reflectamt", 0 ],
            "obj-16::obj-32": [ "linesharpness", "linesharpness", 0 ],
            "obj-16::obj-35": [ "ph0", "ph0", 0 ],
            "obj-16::obj-38": [ "spread", "spread", 0 ],
            "obj-16::obj-41": [ "mode", "mode", 0 ],
            "obj-16::obj-44": [ "view_mode", "view_mode", 0 ],
            "obj-16::obj-47": [ "gain", "gain", 0 ],
            "obj-17::obj-12": [ "f_module_1_disp", "live.menu", 0 ],
            "obj-17::obj-13": [ "f_module_1_file", "live.menu", 0 ],
            "obj-17::obj-16": [ "f_module_2_disp", "live.menu", 0 ],
            "obj-17::obj-17": [ "f_module_2_file", "live.menu", 0 ],
            "obj-17::obj-20": [ "f_module_3_disp", "live.menu", 0 ],
            "obj-17::obj-21": [ "f_module_3_file", "live.menu", 0 ],
            "obj-17::obj-24": [ "f_module_4_disp", "live.menu", 0 ],
            "obj-17::obj-25": [ "f_module_4_file", "live.menu", 0 ],
            "obj-17::obj-28": [ "f_module_5_disp", "live.menu", 0 ],
            "obj-17::obj-29": [ "f_module_5_file", "live.menu", 0 ],
            "obj-17::obj-32": [ "f_module_6_disp", "live.menu", 0 ],
            "obj-17::obj-33": [ "f_module_6_file", "live.menu", 0 ],
            "obj-17::obj-36": [ "f_module_7_disp", "live.menu", 0 ],
            "obj-17::obj-37": [ "f_module_7_file", "live.menu", 0 ],
            "obj-17::obj-8": [ "f_module_0_disp", "live.menu", 0 ],
            "obj-17::obj-9": [ "f_module_0_file", "live.menu", 0 ],
            "obj-18::obj-20": [ "radius", "radius", 0 ],
            "obj-18::obj-23": [ "falloff", "falloff", 0 ],
            "obj-18::obj-26": [ "strength", "gain", 0 ],
            "obj-18::obj-29": [ "color_mix", "mix_pct", 0 ],
            "obj-18::obj-32": [ "direction", "color_mix", 0 ],
            "obj-18::obj-35": [ "direction[1]", "direction", 0 ],
            "obj-19::obj-20": [ "dt", "dt", 0 ],
            "obj-19::obj-23": [ "decay", "decay", 0 ],
            "obj-19::obj-26": [ "injection", "injection", 0 ],
            "obj-19::obj-29": [ "mix_amt", "gain", 0 ],
            "obj-19::obj-32": [ "separate", "separate", 0 ],
            "obj-19::obj-35": [ "mode[1]", "mode", 0 ],
            "obj-19::obj-90": [ "mix_pct", "mix_pct", 0 ],
            "obj-1::obj-10": [ "vs_preset_name", "vs_preset_name", 0 ],
            "obj-1::obj-11": [ "live.text", "live.text", 0 ],
            "obj-1::obj-15": [ "live.tab", "live.tab", 0 ],
            "obj-1::obj-32": [ "live.numbox[4]", "live.numbox", 0 ],
            "obj-1::obj-44": [ "live.tab[3]", "live.tab", 0 ],
            "obj-1::obj-45::obj-16": [ "live.menu[16]", "live.menu[16]", 0 ],
            "obj-1::obj-45::obj-17": [ "live.button", "live.button", 0 ],
            "obj-1::obj-45::obj-19": [ "live.numbox[2]", "live.numbox[1]", 0 ],
            "obj-1::obj-45::obj-32": [ "live.numbox", "live.numbox", 0 ],
            "obj-1::obj-45::obj-9": [ "live.numbox[3]", "live.numbox", 0 ],
            "obj-22::obj-19d": [ "panel_toggle", "panel_toggle", 0 ],
            "obj-22::obj-20": [ "aberration", "aberration", 0 ],
            "obj-22::obj-23": [ "tilt", "distortion", 0 ],
            "obj-22::obj-26": [ "slope", "transmission", 0 ],
            "obj-22::obj-29": [ "aberration_mod", "aberration_mod", 0 ],
            "obj-22::obj-300": [ "range_aberration", "range_aberration", 0 ],
            "obj-22::obj-310": [ "range_distortion", "range_distortion", 0 ],
            "obj-22::obj-32": [ "distortion_mod", "distortion_mod", 0 ],
            "obj-22::obj-320": [ "range_transmission", "range_transmission", 0 ],
            "obj-22::obj-35": [ "transmission_mod", "transmission_mod", 0 ],
            "obj-22::obj-38": [ "surface_mod", "surface_mod", 0 ],
            "obj-22::obj-390": [ "range_ghost_spacing", "range_ghost_spacing", 0 ],
            "obj-22::obj-41": [ "ghost", "ghost", 0 ],
            "obj-22::obj-44": [ "ghost_count", "ghost_count", 0 ],
            "obj-22::obj-47": [ "ghost_spacing", "ghost_spacing", 0 ],
            "obj-22::obj-50": [ "halation", "halation", 0 ],
            "obj-22::obj-53": [ "halation_threshold", "halation_threshold", 0 ],
            "obj-36::obj-19": [ "offrot_angle[1]", "Angle", 0 ],
            "obj-36::obj-35": [ "offrot_zoom[1]", "Zoom", 0 ],
            "obj-36::obj-4": [ "MENU[1]", "angle", 0 ],
            "obj-36::obj-40": [ "a_lock", "a_lock", 0 ],
            "obj-36::obj-6": [ "offrot_x[1]", "X", 0 ],
            "obj-36::obj-67": [ "MENU", "angle", 0 ],
            "obj-36::obj-8": [ "offrot_y", "Y", 0 ],
            "obj-36::obj-9": [ "MENU[2]", "angle", 0 ],
            "obj-36::obj-96": [ "offrot_boundmode", "live.menu", 0 ],
            "obj-37::obj-20": [ "strength[1]", "strength", 0 ],
            "obj-37::obj-23": [ "scale", "scale", 0 ],
            "obj-37::obj-28": [ "rotate", "rotate", 0 ],
            "obj-37::obj-31": [ "thresh", "thresh", 0 ],
            "parameterbanks": {
                "0": {
                    "index": 0,
                    "name": "",
                    "parameters": [ "-", "-", "-", "-", "-", "-", "-", "-" ],
                    "buttons": [ "-", "-", "-", "-", "-", "-", "-", "-" ]
                }
            },
            "parameter_overrides": {
                "obj-13::obj-6": {
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-16::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-16::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-16::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-16::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-16::obj-32": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-16::obj-35": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-16::obj-38": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-16::obj-41": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-16::obj-44": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-18::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-18::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-18::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_longname": "strength",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-18::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_longname": "color_mix",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-18::obj-32": {
                    "parameter_invisible": 0,
                    "parameter_longname": "direction",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-18::obj-35": {
                    "parameter_longname": "direction[1]"
                },
                "obj-19::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_range": [ 0.0, 0.05 ],
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-19::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-19::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_range": [ 0.0, 0.5 ],
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-19::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_longname": "mix_amt",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-19::obj-35": {
                    "parameter_longname": "mode[1]"
                },
                "obj-1::obj-15": {
                    "parameter_longname": "live.tab"
                },
                "obj-1::obj-32": {
                    "parameter_longname": "live.numbox[4]"
                },
                "obj-22::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_range": [ -1.0, 1.0 ],
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-22::obj-23": {
                    "parameter_longname": "tilt",
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-22::obj-26": {
                    "parameter_longname": "slope",
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-22::obj-47": {
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-36::obj-19": {
                    "parameter_range": [ -360.0, 360.0 ]
                },
                "obj-36::obj-6": {
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-36::obj-8": {
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-37::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_longname": "strength[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "strength",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-37::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                }
            },
            "inherited_shortname": 1
        },
        "autosave": 0,
        "boxgroups": [
            {
                "boxes": [ "obj-1", "obj-40" ]
            }
        ]
    }
}