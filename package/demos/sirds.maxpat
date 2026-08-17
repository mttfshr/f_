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
        "rect": [ 722.0, 111.0, 972.0, 745.0 ],
        "boxes": [
            {
                "box": {
                    "bgmode": 1,
                    "border": 1,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-23",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_displacement.maxpat",
                    "numinlets": 5,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 490.0, 515.0, 162.0, 119.0 ],
                    "varname": "vs_displacement",
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
                    "id": "obj-22",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_stereo.maxpat",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 624.0, 402.0, 160.0, 90.0 ],
                    "varname": "f_stereo",
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
                    "id": "obj-21",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_preview.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 604.0, 244.0, 112.0, 102.02620087336243 ],
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
                    "id": "obj-16",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_wfg_polarizer.maxpat",
                    "numinlets": 2,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 539.0, 46.0, 220.0, 132.0 ],
                    "varname": "depth_source[2]",
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
                    "patching_rect": [ 702.0, 560.0, 112.0, 102.02620087336243 ],
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
                    "id": "obj-13",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_grain.maxpat",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 207.0, 175.0, 227.0, 164.0 ],
                    "varname": "f_grain",
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
                    "id": "obj-12",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_sirds.maxpat",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 258.0, 375.0, 197.5, 130.0 ],
                    "varname": "f_sirds",
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
                    "id": "obj-9",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_wfg_polarizer.maxpat",
                    "numinlets": 2,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 258.0, 4.0, 220.0, 132.0 ],
                    "varname": "depth_source[1]",
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
                    "id": "obj-20",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_output.maxpat",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "offset": [ 0.0, 0.0 ],
                    "patching_rect": [ 258.0, 551.0, 157.0, 22.0 ],
                    "varname": "vs_output",
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
                    "id": "obj-6",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_modules.maxpat",
                    "numinlets": 0,
                    "numoutlets": 0,
                    "offset": [ 0.0, 0.0 ],
                    "patching_rect": [ 25.0, 339.0, 96.0, 249.0 ],
                    "varname": "f_modules_rack",
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
                    "patching_rect": [ 110.0, 14.0, 96.85526317358028, 146.5 ],
                    "varname": "vs_render",
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
                    "id": "obj-1",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_modules.maxpat",
                    "numinlets": 0,
                    "numoutlets": 0,
                    "offset": [ 0.0, 0.0 ],
                    "patching_rect": [ 25.0, 14.0, 79.0, 316.0 ],
                    "varname": "vs_modules",
                    "viewvisibility": 1
                }
            }
        ],
        "lines": [
            {
                "patchline": {
                    "destination": [ "obj-20", 0 ],
                    "source": [ "obj-12", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-12", 0 ],
                    "source": [ "obj-13", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-21", 0 ],
                    "order": 1,
                    "source": [ "obj-16", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-22", 0 ],
                    "order": 0,
                    "source": [ "obj-16", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-23", 0 ],
                    "source": [ "obj-22", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-12", 1 ],
                    "order": 0,
                    "source": [ "obj-23", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-15", 0 ],
                    "order": 1,
                    "source": [ "obj-23", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-13", 0 ],
                    "source": [ "obj-9", 0 ]
                }
            }
        ],
        "parameters": {
            "obj-12::obj-220": [ "depth_factor", "depth_factor", 0 ],
            "obj-13::obj-11": [ "density", "density", 0 ],
            "obj-13::obj-13": [ "amount", "amount", 0 ],
            "obj-13::obj-15": [ "persistence", "persistence", 0 ],
            "obj-13::obj-2": [ "fade", "fade", 0 ],
            "obj-13::obj-25": [ "size", "size", 0 ],
            "obj-13::obj-27": [ "size_var", "size_var", 0 ],
            "obj-13::obj-29": [ "shape[3]", "shape", 0 ],
            "obj-13::obj-31": [ "softness", "softness", 0 ],
            "obj-13::obj-37": [ "jitter", "jitter", 0 ],
            "obj-13::obj-40": [ "ch_diverge", "ch_diverge", 0 ],
            "obj-13::obj-43": [ "field", "field", 0 ],
            "obj-13::obj-60": [ "luma_gate", "luma_gate", 0 ],
            "obj-13::obj-63": [ "displace", "displace", 0 ],
            "obj-13::obj-71": [ "edge_mode_menu", "edge_mode_menu", 0 ],
            "obj-13::obj-82": [ "sv_seed", "sv_seed", 0 ],
            "obj-16::obj-10": [ "bias[2]", "Bias", 0 ],
            "obj-16::obj-14": [ "bm[2]", "BM", 0 ],
            "obj-16::obj-17": [ "live.menu[19]", "live.menu", 0 ],
            "obj-16::obj-22": [ "live.text[12]", "live.text", 0 ],
            "obj-16::obj-29": [ "freq", "Freq", 0 ],
            "obj-16::obj-30": [ "angle[3]", "Angle", 0 ],
            "obj-16::obj-42": [ "live.toggle[4]", "live.toggle", 0 ],
            "obj-16::obj-47": [ "polarizer[2]", "Morph", 0 ],
            "obj-16::obj-51": [ "live.menu[20]", "live.menu", 0 ],
            "obj-16::obj-53": [ "speed[2]", "Speed", 0 ],
            "obj-16::obj-54": [ "morph[2]", "Morph", 0 ],
            "obj-16::obj-6": [ "pm[2]", "PM", 0 ],
            "obj-16::obj-65": [ "shape[4]", "Shape", 0 ],
            "obj-16::obj-71": [ "phase[3]", "Phase", 0 ],
            "obj-16::obj-72": [ "phase_time_switch[2]", "phase_time_switch", 0 ],
            "obj-1::obj-14": [ "live.menu[1]", "live.menu", 0 ],
            "obj-1::obj-16": [ "live.menu[2]", "live.menu", 0 ],
            "obj-1::obj-18": [ "live.menu[16]", "live.menu", 0 ],
            "obj-1::obj-2": [ "live.menu", "live.menu", 0 ],
            "obj-1::obj-22": [ "live.menu[17]", "live.menu", 0 ],
            "obj-1::obj-24": [ "live.menu[9]", "live.menu", 0 ],
            "obj-1::obj-25": [ "live.menu[10]", "live.menu", 0 ],
            "obj-1::obj-26": [ "live.menu[11]", "live.menu", 0 ],
            "obj-1::obj-27": [ "live.menu[12]", "live.menu", 0 ],
            "obj-1::obj-29": [ "live.menu[13]", "live.menu", 0 ],
            "obj-1::obj-30": [ "live.menu[14]", "live.menu", 0 ],
            "obj-1::obj-33": [ "live.menu[15]", "live.menu", 0 ],
            "obj-1::obj-36": [ "live.menu[3]", "live.menu", 0 ],
            "obj-1::obj-52": [ "live.menu[4]", "live.menu", 0 ],
            "obj-1::obj-53": [ "live.menu[5]", "live.menu", 0 ],
            "obj-1::obj-56": [ "live.menu[6]", "live.menu", 0 ],
            "obj-20::obj-1": [ "toggle[1]", "toggle[1]", 0 ],
            "obj-20::obj-10": [ "toggle[3]", "toggle[2]", 0 ],
            "obj-20::obj-36": [ "uppr_x", "uppr_x", 0 ],
            "obj-22::obj-10": [ "lon", "lon", 0 ],
            "obj-22::obj-12": [ "lat", "lat", 0 ],
            "obj-22::obj-14": [ "spin", "spin", 0 ],
            "obj-22::obj-16": [ "proj", "proj", 0 ],
            "obj-22::obj-32": [ "circ", "circ", 0 ],
            "obj-23::obj-22::obj-19": [ "displacement_angle", "Angle", 0 ],
            "obj-23::obj-22::obj-29": [ "live.numbox", "live.numbox", 0 ],
            "obj-23::obj-22::obj-35": [ "displacement_zoom", "Zoom", 0 ],
            "obj-23::obj-22::obj-4": [ "disp_ang_range", "angle", 0 ],
            "obj-23::obj-22::obj-40": [ "displacement_y_m", "YM", 0 ],
            "obj-23::obj-22::obj-42": [ "displacement_x_m", "XM", 0 ],
            "obj-23::obj-22::obj-44": [ "displacement_zoom_m", "ZM", 0 ],
            "obj-23::obj-22::obj-47": [ "displacement_angle_m", "AGLM", 0 ],
            "obj-23::obj-22::obj-52": [ "MENU[1]", "angle", 0 ],
            "obj-23::obj-22::obj-55": [ "MENU[2]", "angle", 0 ],
            "obj-23::obj-22::obj-56": [ "MENU[3]", "angle", 0 ],
            "obj-23::obj-22::obj-57": [ "MENU[4]", "angle", 0 ],
            "obj-23::obj-22::obj-6": [ "offrot_x", "X", 0 ],
            "obj-23::obj-22::obj-67": [ "menu", "angle", 0 ],
            "obj-23::obj-22::obj-8": [ "displacement_y", "Y", 0 ],
            "obj-23::obj-33": [ "displacement_init_point", "live.text", 2 ],
            "obj-23::obj-49": [ "a_lock", "a_lock", 0 ],
            "obj-23::obj-8": [ "displacement_polar", "live.text", 2 ],
            "obj-23::obj-96": [ "displacement_boundmode", "live.menu", 0 ],
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
            "obj-6::obj-12": [ "f_module_1_disp", "live.menu", 0 ],
            "obj-6::obj-13": [ "f_module_1_file", "live.menu", 0 ],
            "obj-6::obj-16": [ "f_module_2_disp", "live.menu", 0 ],
            "obj-6::obj-17": [ "f_module_2_file", "live.menu", 0 ],
            "obj-6::obj-20": [ "f_module_3_disp", "live.menu", 0 ],
            "obj-6::obj-21": [ "f_module_3_file", "live.menu", 0 ],
            "obj-6::obj-24": [ "f_module_4_disp", "live.menu", 0 ],
            "obj-6::obj-25": [ "f_module_4_file", "live.menu", 0 ],
            "obj-6::obj-8": [ "f_module_0_disp", "live.menu", 0 ],
            "obj-6::obj-9": [ "f_module_0_file", "live.menu", 0 ],
            "obj-9::obj-10": [ "bias", "Bias", 0 ],
            "obj-9::obj-14": [ "bm", "BM", 0 ],
            "obj-9::obj-17": [ "live.menu[41]", "live.menu", 0 ],
            "obj-9::obj-22": [ "live.text[3]", "live.text", 0 ],
            "obj-9::obj-29": [ "freq[2]", "Freq", 0 ],
            "obj-9::obj-30": [ "angle[2]", "Angle", 0 ],
            "obj-9::obj-42": [ "live.toggle[2]", "live.toggle", 0 ],
            "obj-9::obj-47": [ "polarizer", "Morph", 0 ],
            "obj-9::obj-51": [ "live.menu[40]", "live.menu", 0 ],
            "obj-9::obj-53": [ "speed", "Speed", 0 ],
            "obj-9::obj-54": [ "morph", "Morph", 0 ],
            "obj-9::obj-6": [ "pm", "PM", 0 ],
            "obj-9::obj-65": [ "shape", "Shape", 0 ],
            "obj-9::obj-71": [ "phase", "Phase", 0 ],
            "obj-9::obj-72": [ "phase_time_switch", "phase_time_switch", 0 ],
            "parameterbanks": {
                "0": {
                    "index": 0,
                    "name": "",
                    "parameters": [ "-", "-", "-", "-", "-", "-", "-", "-" ],
                    "buttons": [ "-", "-", "-", "-", "-", "-", "-", "-" ]
                }
            },
            "parameter_overrides": {
                "obj-13::obj-11": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-13::obj-13": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-13::obj-2": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-13::obj-25": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-13::obj-27": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-13::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_longname": "shape[3]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "shape",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-13::obj-31": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-13::obj-37": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-13::obj-40": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-13::obj-43": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-13::obj-60": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-13::obj-63": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-13::obj-82": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-16::obj-10": {
                    "parameter_longname": "bias[2]"
                },
                "obj-16::obj-14": {
                    "parameter_longname": "bm[2]"
                },
                "obj-16::obj-17": {
                    "parameter_longname": "live.menu[19]"
                },
                "obj-16::obj-22": {
                    "parameter_longname": "live.text[12]"
                },
                "obj-16::obj-30": {
                    "parameter_longname": "angle[3]"
                },
                "obj-16::obj-42": {
                    "parameter_longname": "live.toggle[4]"
                },
                "obj-16::obj-47": {
                    "parameter_longname": "polarizer[2]"
                },
                "obj-16::obj-51": {
                    "parameter_longname": "live.menu[20]"
                },
                "obj-16::obj-53": {
                    "parameter_longname": "speed[2]"
                },
                "obj-16::obj-54": {
                    "parameter_longname": "morph[2]"
                },
                "obj-16::obj-6": {
                    "parameter_longname": "pm[2]",
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-16::obj-65": {
                    "parameter_longname": "shape[4]"
                },
                "obj-16::obj-71": {
                    "parameter_longname": "phase[3]"
                },
                "obj-16::obj-72": {
                    "parameter_longname": "phase_time_switch[2]"
                },
                "obj-1::obj-14": {
                    "parameter_longname": "live.menu[1]"
                },
                "obj-1::obj-16": {
                    "parameter_longname": "live.menu[2]"
                },
                "obj-1::obj-18": {
                    "parameter_longname": "live.menu[16]"
                },
                "obj-1::obj-22": {
                    "parameter_longname": "live.menu[17]"
                },
                "obj-22::obj-10": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-22::obj-12": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-22::obj-14": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-22::obj-16": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-23::obj-22::obj-19": {
                    "parameter_range": [ -180.0, 180.0 ]
                },
                "obj-23::obj-22::obj-40": {
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-23::obj-22::obj-42": {
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-23::obj-22::obj-47": {
                    "parameter_range": [ -6.28, 6.28 ]
                },
                "obj-23::obj-22::obj-6": {
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-23::obj-22::obj-8": {
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-9::obj-29": {
                    "parameter_longname": "freq[2]"
                },
                "obj-9::obj-30": {
                    "parameter_longname": "angle[2]"
                },
                "obj-9::obj-53": {
                    "parameter_longname": "speed"
                },
                "obj-9::obj-6": {
                    "parameter_range": [ -1.0, 1.0 ]
                }
            },
            "inherited_shortname": 1
        },
        "autosave": 0
    }
}