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
        "rect": [ 694.0, 129.0, 1000.0, 780.0 ],
        "boxes": [
            {
                "box": {
                    "bgmode": 1,
                    "border": 1,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-9",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vsc_presets.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "" ],
                    "patching_rect": [ 678.03125, 269.015625, 170.0, 144.5 ],
                    "varname": "vs_presets",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "autorestore": "stipple.json",
                    "hidden": 1,
                    "id": "obj-10",
                    "linecount": 2,
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 678.03125, 356.015625, 138.0, 35.0 ],
                    "presentation_linecount": 2,
                    "priority": {
                        "vs_wfg_polarizer::pm_range": -1,
                        "vs_wfg_polarizer::lock_freq": -1
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
                    "bgmode": 1,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-8",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_lens.maxpat",
                    "numinlets": 5,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 422.5, 495.0, 175.0, 155.0 ],
                    "varname": "f_lens",
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
                    "id": "obj-4",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_modules.maxpat",
                    "numinlets": 0,
                    "numoutlets": 0,
                    "offset": [ 0.0, 0.0 ],
                    "patching_rect": [ 176.0, 379.0, 96.0, 380.0 ],
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
                    "id": "obj-1",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_stipple.maxpat",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 412.0, 328.0, 196.0, 160.0 ],
                    "varname": "f_stipple",
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
                    "id": "obj-18",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_wfg_polarizer.maxpat",
                    "numinlets": 2,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 304.0, 67.0, 220.0, 132.0 ],
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
                    "id": "obj-5",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_output.maxpat",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "offset": [ 0.0, 0.0 ],
                    "patching_rect": [ 653.0, 643.0, 157.0, 22.0 ],
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
                    "id": "obj-3",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_render.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "" ],
                    "patching_rect": [ 125.0, 67.0, 96.85526317358028, 146.5 ],
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
                    "id": "obj-2",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_modules.maxpat",
                    "numinlets": 0,
                    "numoutlets": 0,
                    "offset": [ 0.0, 0.0 ],
                    "patching_rect": [ 40.0, 67.0, 79.0, 316.0 ],
                    "viewvisibility": 1
                }
            }
        ],
        "lines": [
            {
                "patchline": {
                    "destination": [ "obj-8", 0 ],
                    "source": [ "obj-1", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-1", 0 ],
                    "source": [ "obj-18", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 0 ],
                    "source": [ "obj-8", 0 ]
                }
            },
            {
                "patchline": {
                    "color": [ 0.65, 0.65, 0.65, 0.0 ],
                    "destination": [ "obj-10", 0 ],
                    "hidden": 1,
                    "source": [ "obj-9", 0 ]
                }
            }
        ],
        "parameters": {
            "obj-18::obj-10": [ "bias", "Bias", 0 ],
            "obj-18::obj-14": [ "bm", "BM", 0 ],
            "obj-18::obj-17": [ "live.menu[41]", "live.menu", 0 ],
            "obj-18::obj-22": [ "live.text[3]", "live.text", 0 ],
            "obj-18::obj-29": [ "freq", "Freq", 0 ],
            "obj-18::obj-30": [ "angle", "Angle", 0 ],
            "obj-18::obj-42": [ "live.toggle[2]", "live.toggle", 0 ],
            "obj-18::obj-47": [ "polarizer", "Morph", 0 ],
            "obj-18::obj-51": [ "live.menu[40]", "live.menu", 0 ],
            "obj-18::obj-53": [ "speed", "Speed", 0 ],
            "obj-18::obj-54": [ "morph", "Morph", 0 ],
            "obj-18::obj-6": [ "pm", "PM", 0 ],
            "obj-18::obj-65": [ "shape", "Shape", 0 ],
            "obj-18::obj-71": [ "phase", "Phase", 0 ],
            "obj-18::obj-72": [ "phase_time_switch", "phase_time_switch", 0 ],
            "obj-1::obj-20": [ "freq[1]", "freq", 0 ],
            "obj-1::obj-23": [ "coarseness", "coarseness", 0 ],
            "obj-1::obj-26": [ "anisotropy", "anisotropy", 0 ],
            "obj-1::obj-29": [ "angle[1]", "angle", 0 ],
            "obj-1::obj-32": [ "zoom", "zoom", 0 ],
            "obj-1::obj-35": [ "threshold", "threshold", 0 ],
            "obj-1::obj-38": [ "colorize", "colorize", 0 ],
            "obj-1::obj-41": [ "along_phase", "along_phase", 0 ],
            "obj-1::obj-44": [ "across_phase", "across_phase", 0 ],
            "obj-1::obj-47": [ "softness", "softness", 0 ],
            "obj-2::obj-14": [ "live.menu[30]", "live.menu", 0 ],
            "obj-2::obj-16": [ "live.menu[31]", "live.menu", 0 ],
            "obj-2::obj-18": [ "live.menu[32]", "live.menu", 0 ],
            "obj-2::obj-2": [ "live.menu", "live.menu", 0 ],
            "obj-2::obj-22": [ "live.menu[33]", "live.menu", 0 ],
            "obj-2::obj-24": [ "live.menu[9]", "live.menu", 0 ],
            "obj-2::obj-25": [ "live.menu[10]", "live.menu", 0 ],
            "obj-2::obj-26": [ "live.menu[11]", "live.menu", 0 ],
            "obj-2::obj-27": [ "live.menu[12]", "live.menu", 0 ],
            "obj-2::obj-29": [ "live.menu[13]", "live.menu", 0 ],
            "obj-2::obj-30": [ "live.menu[14]", "live.menu", 0 ],
            "obj-2::obj-33": [ "live.menu[15]", "live.menu", 0 ],
            "obj-2::obj-36": [ "live.menu[3]", "live.menu", 0 ],
            "obj-2::obj-52": [ "live.menu[4]", "live.menu", 0 ],
            "obj-2::obj-53": [ "live.menu[5]", "live.menu", 0 ],
            "obj-2::obj-56": [ "live.menu[6]", "live.menu", 0 ],
            "obj-3::obj-19": [ "dim_x[2]", "dim_x", 0 ],
            "obj-3::obj-23": [ "pwm[1]", "pwm", 0 ],
            "obj-3::obj-36": [ "live.text[11]", "live.text", 0 ],
            "obj-3::obj-40": [ "live.text[6]", "live.text", 0 ],
            "obj-3::obj-41": [ "dim_y[2]", "dim_y", 0 ],
            "obj-3::obj-42": [ "dim_x[3]", "dim_x", 0 ],
            "obj-3::obj-45": [ "live.text[10]", "live.text", 0 ],
            "obj-3::obj-48": [ "live.text[7]", "live.text", 0 ],
            "obj-3::obj-5": [ "live.text[9]", "live.text", 0 ],
            "obj-3::obj-6": [ "live.text[8]", "live.text", 0 ],
            "obj-4::obj-12": [ "f_module_1_disp", "live.menu", 0 ],
            "obj-4::obj-13": [ "f_module_1_file", "live.menu", 0 ],
            "obj-4::obj-16": [ "f_module_2_disp", "live.menu", 0 ],
            "obj-4::obj-17": [ "f_module_2_file", "live.menu", 0 ],
            "obj-4::obj-20": [ "f_module_3_disp", "live.menu", 0 ],
            "obj-4::obj-21": [ "f_module_3_file", "live.menu", 0 ],
            "obj-4::obj-24": [ "f_module_4_disp", "live.menu", 0 ],
            "obj-4::obj-25": [ "f_module_4_file", "live.menu", 0 ],
            "obj-4::obj-28": [ "f_module_5_disp", "live.menu", 0 ],
            "obj-4::obj-29": [ "f_module_5_file", "live.menu", 0 ],
            "obj-4::obj-32": [ "f_module_6_disp", "live.menu", 0 ],
            "obj-4::obj-33": [ "f_module_6_file", "live.menu", 0 ],
            "obj-4::obj-36": [ "f_module_7_disp", "live.menu", 0 ],
            "obj-4::obj-37": [ "f_module_7_file", "live.menu", 0 ],
            "obj-4::obj-8": [ "f_module_0_disp", "live.menu", 0 ],
            "obj-4::obj-9": [ "f_module_0_file", "live.menu", 0 ],
            "obj-5::obj-1": [ "toggle[1]", "toggle[1]", 0 ],
            "obj-5::obj-10": [ "toggle[3]", "toggle[2]", 0 ],
            "obj-5::obj-36": [ "uppr_x", "uppr_x", 0 ],
            "obj-8::obj-19d": [ "panel_toggle", "panel_toggle", 0 ],
            "obj-8::obj-20": [ "aberration", "aberration", 0 ],
            "obj-8::obj-23": [ "distortion", "distortion", 0 ],
            "obj-8::obj-26": [ "transmission", "transmission", 0 ],
            "obj-8::obj-29": [ "aberration_mod", "aberration_mod", 0 ],
            "obj-8::obj-300": [ "range_aberration", "range_aberration", 0 ],
            "obj-8::obj-310": [ "range_distortion", "range_distortion", 0 ],
            "obj-8::obj-32": [ "distortion_mod", "distortion_mod", 0 ],
            "obj-8::obj-320": [ "range_transmission", "range_transmission", 0 ],
            "obj-8::obj-35": [ "transmission_mod", "transmission_mod", 0 ],
            "obj-8::obj-38": [ "surface_mod", "surface_mod", 0 ],
            "obj-8::obj-390": [ "range_ghost_spacing", "range_ghost_spacing", 0 ],
            "obj-8::obj-41": [ "ghost", "ghost", 0 ],
            "obj-8::obj-44": [ "ghost_count", "ghost_count", 0 ],
            "obj-8::obj-47": [ "ghost_spacing", "ghost_spacing", 0 ],
            "obj-8::obj-50": [ "halation", "halation", 0 ],
            "obj-8::obj-53": [ "halation_threshold", "halation_threshold", 0 ],
            "obj-9::obj-10": [ "textedit", "vs_preset_name", 0 ],
            "obj-9::obj-11": [ "live.text", "live.text", 0 ],
            "obj-9::obj-15": [ "live.tab", "live.tab", 0 ],
            "obj-9::obj-32": [ "live.numbox[4]", "live.numbox", 0 ],
            "obj-9::obj-44": [ "live.tab[3]", "live.tab", 0 ],
            "obj-9::obj-45::obj-16": [ "live.menu[16]", "live.menu[16]", 0 ],
            "obj-9::obj-45::obj-17": [ "live.button", "live.button", 0 ],
            "obj-9::obj-45::obj-19": [ "live.numbox[2]", "live.numbox[1]", 0 ],
            "obj-9::obj-45::obj-32": [ "live.numbox", "live.numbox", 0 ],
            "obj-9::obj-45::obj-9": [ "live.numbox[3]", "live.numbox", 0 ],
            "parameterbanks": {
                "0": {
                    "index": 0,
                    "name": "",
                    "parameters": [ "-", "-", "-", "-", "-", "-", "-", "-" ],
                    "buttons": [ "-", "-", "-", "-", "-", "-", "-", "-" ]
                }
            },
            "parameter_overrides": {
                "obj-18::obj-6": {
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-1::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_longname": "freq[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "freq",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-1::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_longname": "coarseness",
                    "parameter_modmode": 3,
                    "parameter_shortname": "coarseness",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-1::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-1::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_longname": "angle[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "angle",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-1::obj-32": {
                    "parameter_invisible": 0,
                    "parameter_longname": "zoom",
                    "parameter_modmode": 3,
                    "parameter_shortname": "zoom",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-1::obj-35": {
                    "parameter_invisible": 0,
                    "parameter_longname": "threshold",
                    "parameter_modmode": 3,
                    "parameter_shortname": "threshold",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-1::obj-38": {
                    "parameter_invisible": 0,
                    "parameter_longname": "colorize",
                    "parameter_modmode": 3,
                    "parameter_shortname": "colorize",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-1::obj-41": {
                    "parameter_invisible": 0,
                    "parameter_longname": "along_phase",
                    "parameter_modmode": 3,
                    "parameter_shortname": "along_phase",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-1::obj-44": {
                    "parameter_invisible": 0,
                    "parameter_longname": "across_phase",
                    "parameter_modmode": 3,
                    "parameter_shortname": "across_phase",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-1::obj-47": {
                    "parameter_invisible": 0,
                    "parameter_longname": "softness",
                    "parameter_modmode": 3,
                    "parameter_shortname": "softness",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-8::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_range": [ -1.0, 1.0 ],
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-8::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_range": [ -1.0, 1.0 ],
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-8::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_range": [ -1.0, 1.0 ],
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-8::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-8::obj-32": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-8::obj-35": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-8::obj-38": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-8::obj-41": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-8::obj-44": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-8::obj-47": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_range": [ -1.0, 1.0 ],
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-9::obj-32": {
                    "parameter_longname": "live.numbox[4]"
                }
            },
            "inherited_shortname": 1
        },
        "autosave": 0,
        "boxgroups": [
            {
                "boxes": [ "obj-9", "obj-10" ]
            }
        ]
    }
}