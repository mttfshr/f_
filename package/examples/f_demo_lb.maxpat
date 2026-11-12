{
    "patcher": {
        "fileversion": 1,
        "appversion": {
            "major": 9,
            "minor": 2,
            "revision": 0,
            "architecture": "x64",
            "modernui": 1
        },
        "classnamespace": "box",
        "rect": [ -13.0, 100.0, 1000.0, 780.0 ],
        "boxes": [
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
                    "name": "vs_displacement.maxpat",
                    "numinlets": 5,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 96.0, 571.0, 162.0, 119.0 ],
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
                    "id": "obj-19",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_ks.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 287.0, 49.0, 190.0, 110.0 ],
                    "varname": "f_ks",
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
                    "name": "f_vf_advect.maxpat",
                    "numinlets": 2,
                    "numoutlets": 3,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 298.0, 418.0, 190.0, 150.0 ],
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
                    "id": "obj-14",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_lens.maxpat",
                    "numinlets": 5,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 270.0, 245.0, 231.0, 156.0 ],
                    "varname": "f_lens",
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
                    "name": "vs_preview.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 718.0, 280.0, 186.0, 203.0 ],
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
                    "id": "obj-11",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_ink.maxpat",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 303.5, 607.73046875, 190.0, 95.0 ],
                    "varname": "f_ink",
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
                    "id": "obj-9",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_stipple.maxpat",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 665.0, 39.0, 191.0, 157.0 ],
                    "varname": "f_stipple",
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
                    "id": "obj-8",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_vf_lbm.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 519.0, 259.0, 197.0, 110.0 ],
                    "varname": "f_vf_lbm",
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
                    "id": "obj-7",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_modules.maxpat",
                    "numinlets": 0,
                    "numoutlets": 0,
                    "offset": [ 0.0, 0.0 ],
                    "patching_rect": [ 135.0, 56.0, 96.0, 420.0 ],
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
                    "name": "vsc_presets.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "" ],
                    "patching_rect": [ 770.98828125, 520.73046875, 170.0, 144.5 ],
                    "varname": "vs_presets",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "hidden": 1,
                    "id": "obj-10",
                    "linecount": 2,
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 770.98828125, 607.73046875, 138.0, 35.0 ],
                    "presentation_linecount": 2,
                    "priority": {
                        "vs_wfg_polarizer::pm_range": -1,
                        "vs_wfg_polarizer::lock_freq": -1,
                        "vs_displacement::displacement_gui::displacement_y_range": -1,
                        "vs_displacement::displacement_gui::displacement_anglemenu": -1,
                        "vs_displacement::displacement_gui::displacement_scale_ym": -1,
                        "vs_displacement::displacement_gui::displacement_x_range": -1,
                        "vs_displacement::displacement_gui::displacement_angle_range": -1,
                        "vs_displacement::displacement_gui::displacement_scale_xm": -1
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
                    "border": 1,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-2",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_render.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "" ],
                    "patching_rect": [ 669.98828125, 519.48046875, 96.85526317358028, 146.5 ],
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
                    "id": "obj-3",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_output.maxpat",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "offset": [ 0.0, 0.0 ],
                    "patching_rect": [ 320.0, 736.0, 157.0, 22.0 ],
                    "varname": "vs_output[1]",
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
                    "name": "vs_modules.maxpat",
                    "numinlets": 0,
                    "numoutlets": 0,
                    "offset": [ 0.0, 0.0 ],
                    "patching_rect": [ 27.98828125, 35.73046875, 79.0, 316.0 ],
                    "viewvisibility": 1
                }
            }
        ],
        "lines": [
            {
                "patchline": {
                    "color": [ 0.65, 0.65, 0.65, 0.0 ],
                    "destination": [ "obj-10", 0 ],
                    "hidden": 1,
                    "source": [ "obj-1", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-20", 0 ],
                    "source": [ "obj-11", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-18", 0 ],
                    "order": 0,
                    "source": [ "obj-14", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-9", 0 ],
                    "order": 1,
                    "source": [ "obj-14", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-11", 0 ],
                    "source": [ "obj-18", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-14", 0 ],
                    "source": [ "obj-19", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-3", 0 ],
                    "source": [ "obj-20", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-11", 1 ],
                    "order": 0,
                    "source": [ "obj-8", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-13", 0 ],
                    "order": 2,
                    "source": [ "obj-8", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-18", 1 ],
                    "order": 1,
                    "source": [ "obj-8", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-8", 0 ],
                    "source": [ "obj-9", 0 ]
                }
            }
        ],
        "parameters": {
            "obj-11::obj-20": [ "extent", "extent", 0 ],
            "obj-11::obj-23": [ "bulge", "bulge", 0 ],
            "obj-11::obj-26": [ "travel", "travel", 0 ],
            "obj-14::obj-19d": [ "panel_toggle", "panel_toggle", 0 ],
            "obj-14::obj-20": [ "aberration", "aberration", 0 ],
            "obj-14::obj-23": [ "distortion", "distortion", 0 ],
            "obj-14::obj-26": [ "transmission", "transmission", 0 ],
            "obj-14::obj-29": [ "aberration_mod", "aberration_mod", 0 ],
            "obj-14::obj-300": [ "range_aberration", "range_aberration", 0 ],
            "obj-14::obj-310": [ "range_distortion", "range_distortion", 0 ],
            "obj-14::obj-32": [ "distortion_mod", "distortion_mod", 0 ],
            "obj-14::obj-320": [ "range_transmission", "range_transmission", 0 ],
            "obj-14::obj-35": [ "transmission_mod", "transmission_mod", 0 ],
            "obj-14::obj-38": [ "surface_mod", "surface_mod", 0 ],
            "obj-14::obj-390": [ "range_ghost_spacing", "range_ghost_spacing", 0 ],
            "obj-14::obj-41": [ "ghost", "ghost", 0 ],
            "obj-14::obj-44": [ "ghost_count", "ghost_count", 0 ],
            "obj-14::obj-47": [ "ghost_spacing", "ghost_spacing", 0 ],
            "obj-14::obj-50": [ "halation", "halation", 0 ],
            "obj-14::obj-53": [ "halation_threshold", "halation_threshold", 0 ],
            "obj-18::obj-20": [ "dt", "dt", 0 ],
            "obj-18::obj-23": [ "decay", "decay", 0 ],
            "obj-18::obj-26": [ "injection", "injection", 0 ],
            "obj-18::obj-29": [ "gain[1]", "gain", 0 ],
            "obj-18::obj-32": [ "mix_pct", "mix_pct", 0 ],
            "obj-18::obj-35": [ "separate", "separate", 0 ],
            "obj-18::obj-38": [ "mode", "mode", 0 ],
            "obj-18::obj-41": [ "trail", "trail", 0 ],
            "obj-19::obj-20": [ "rate", "rate", 0 ],
            "obj-19::obj-23": [ "scale", "scale", 0 ],
            "obj-19::obj-26": [ "sharp", "sharp", 0 ],
            "obj-1::obj-10": [ "vs_preset_name", "vs_preset_name", 0 ],
            "obj-1::obj-11": [ "live.text[5]", "live.text", 0 ],
            "obj-1::obj-15": [ "live.tab", "live.tab", 0 ],
            "obj-1::obj-32": [ "live.numbox[4]", "live.numbox", 0 ],
            "obj-1::obj-44": [ "live.tab[3]", "live.tab", 0 ],
            "obj-1::obj-45::obj-16": [ "live.menu[16]", "live.menu[16]", 0 ],
            "obj-1::obj-45::obj-17": [ "live.button", "live.button", 0 ],
            "obj-1::obj-45::obj-19": [ "live.numbox[2]", "live.numbox[1]", 0 ],
            "obj-1::obj-45::obj-32": [ "live.numbox", "live.numbox", 0 ],
            "obj-1::obj-45::obj-9": [ "live.numbox[3]", "live.numbox", 0 ],
            "obj-20::obj-22::obj-19": [ "displacement_angle", "Angle", 0 ],
            "obj-20::obj-22::obj-29": [ "live.numbox[5]", "live.numbox", 0 ],
            "obj-20::obj-22::obj-35": [ "displacement_zoom", "Zoom", 0 ],
            "obj-20::obj-22::obj-4": [ "disp_ang_range", "angle", 0 ],
            "obj-20::obj-22::obj-40": [ "displacement_y_m", "YM", 0 ],
            "obj-20::obj-22::obj-42": [ "displacement_x_m", "XM", 0 ],
            "obj-20::obj-22::obj-44": [ "displacement_zoom_m", "ZM", 0 ],
            "obj-20::obj-22::obj-47": [ "displacement_angle_m", "AGLM", 0 ],
            "obj-20::obj-22::obj-52": [ "MENU[1]", "angle", 0 ],
            "obj-20::obj-22::obj-55": [ "MENU[2]", "angle", 0 ],
            "obj-20::obj-22::obj-56": [ "MENU[3]", "angle", 0 ],
            "obj-20::obj-22::obj-57": [ "MENU[4]", "angle", 0 ],
            "obj-20::obj-22::obj-6": [ "offrot_x", "X", 0 ],
            "obj-20::obj-22::obj-67": [ "menu", "angle", 0 ],
            "obj-20::obj-22::obj-8": [ "displacement_y", "Y", 0 ],
            "obj-20::obj-33": [ "displacement_init_point", "live.text", 2 ],
            "obj-20::obj-49": [ "a_lock", "a_lock", 0 ],
            "obj-20::obj-8": [ "displacement_polar", "live.text", 2 ],
            "obj-20::obj-96": [ "displacement_boundmode", "live.menu", 0 ],
            "obj-2::obj-19": [ "dim_x", "dim_x", 0 ],
            "obj-2::obj-23": [ "dim_y", "dim_y", 0 ],
            "obj-2::obj-36": [ "live.text", "live.text", 0 ],
            "obj-2::obj-40": [ "live.text[1]", "live.text", 0 ],
            "obj-2::obj-41": [ "dim_y[1]", "dim_y", 0 ],
            "obj-2::obj-42": [ "dim_x[1]", "dim_x", 0 ],
            "obj-2::obj-45": [ "live.text[2]", "live.text", 0 ],
            "obj-2::obj-48": [ "live.text[4]", "live.text", 0 ],
            "obj-2::obj-5": [ "live.text[3]", "live.text", 0 ],
            "obj-2::obj-6": [ "live.text[16]", "live.text", 0 ],
            "obj-3::obj-1": [ "toggle[3]", "toggle[1]", 0 ],
            "obj-3::obj-10": [ "toggle[4]", "toggle[2]", 0 ],
            "obj-3::obj-36": [ "uppr_x[1]", "uppr_x", 0 ],
            "obj-5::obj-14": [ "live.menu[18]", "live.menu", 0 ],
            "obj-5::obj-16": [ "live.menu[29]", "live.menu", 0 ],
            "obj-5::obj-18": [ "live.menu[33]", "live.menu", 0 ],
            "obj-5::obj-2": [ "live.menu[23]", "live.menu", 0 ],
            "obj-5::obj-22": [ "live.menu[26]", "live.menu", 0 ],
            "obj-5::obj-24": [ "live.menu[31]", "live.menu", 0 ],
            "obj-5::obj-25": [ "live.menu[27]", "live.menu", 0 ],
            "obj-5::obj-26": [ "live.menu[30]", "live.menu", 0 ],
            "obj-5::obj-27": [ "live.menu[28]", "live.menu", 0 ],
            "obj-5::obj-29": [ "live.menu[24]", "live.menu", 0 ],
            "obj-5::obj-30": [ "live.menu[19]", "live.menu", 0 ],
            "obj-5::obj-33": [ "live.menu[32]", "live.menu", 0 ],
            "obj-5::obj-36": [ "live.menu[20]", "live.menu", 0 ],
            "obj-5::obj-52": [ "live.menu[21]", "live.menu", 0 ],
            "obj-5::obj-53": [ "live.menu[22]", "live.menu", 0 ],
            "obj-5::obj-56": [ "live.menu[25]", "live.menu", 0 ],
            "obj-7::obj-12": [ "f_module_1_disp", "live.menu", 0 ],
            "obj-7::obj-13": [ "f_module_1_file", "live.menu", 0 ],
            "obj-7::obj-16": [ "f_module_2_disp", "live.menu", 0 ],
            "obj-7::obj-17": [ "f_module_2_file", "live.menu", 0 ],
            "obj-7::obj-20": [ "f_module_3_disp", "live.menu", 0 ],
            "obj-7::obj-21": [ "f_module_3_file", "live.menu", 0 ],
            "obj-7::obj-24": [ "f_module_4_disp", "live.menu", 0 ],
            "obj-7::obj-25": [ "f_module_4_file", "live.menu", 0 ],
            "obj-7::obj-28": [ "f_module_5_disp", "live.menu", 0 ],
            "obj-7::obj-29": [ "f_module_5_file", "live.menu", 0 ],
            "obj-7::obj-32": [ "f_module_6_disp", "live.menu", 0 ],
            "obj-7::obj-33": [ "f_module_6_file", "live.menu", 0 ],
            "obj-7::obj-36": [ "f_module_7_disp", "live.menu", 0 ],
            "obj-7::obj-37": [ "f_module_7_file", "live.menu", 0 ],
            "obj-7::obj-40": [ "f_module_8_disp", "live.menu", 0 ],
            "obj-7::obj-41": [ "f_module_8_file", "live.menu", 0 ],
            "obj-7::obj-44": [ "f_module_9_disp", "live.menu", 0 ],
            "obj-7::obj-45": [ "f_module_9_file", "live.menu", 0 ],
            "obj-7::obj-8": [ "f_module_0_disp", "live.menu", 0 ],
            "obj-7::obj-9": [ "f_module_0_file", "live.menu", 0 ],
            "obj-8::obj-20": [ "omega", "omega", 0 ],
            "obj-8::obj-23": [ "inflow", "inflow", 0 ],
            "obj-8::obj-26": [ "tilt", "tilt", 0 ],
            "obj-8::obj-29": [ "gain", "gain", 0 ],
            "obj-8::obj-32": [ "speed", "speed", 0 ],
            "obj-9::obj-20": [ "freq", "freq", 0 ],
            "obj-9::obj-23": [ "coarseness", "coarseness", 0 ],
            "obj-9::obj-26": [ "anisotropy", "anisotropy", 0 ],
            "obj-9::obj-29": [ "angle", "angle", 0 ],
            "obj-9::obj-32": [ "zoom", "zoom", 0 ],
            "obj-9::obj-35": [ "threshold", "threshold", 0 ],
            "obj-9::obj-38": [ "colorize", "colorize", 0 ],
            "obj-9::obj-41": [ "along_phase", "along_phase", 0 ],
            "obj-9::obj-44": [ "across_phase", "across_phase", 0 ],
            "obj-9::obj-47": [ "softness", "softness", 0 ],
            "parameter_overrides": {
                "obj-11::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-11::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-11::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-14::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_range": [ -1.0, 1.0 ],
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-14::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_range": [ -1.0, 1.0 ],
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-14::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_range": [ -1.0, 1.0 ],
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-14::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-14::obj-32": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-14::obj-35": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-14::obj-38": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-14::obj-41": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-14::obj-44": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-14::obj-47": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_range": [ -1.0, 1.0 ],
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
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-18::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_longname": "gain[1]",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-18::obj-32": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-18::obj-35": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-18::obj-38": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 0,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 9
                },
                "obj-18::obj-41": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-19::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-1::obj-11": {
                    "parameter_longname": "live.text[5]"
                },
                "obj-1::obj-15": {
                    "parameter_longname": "live.tab"
                },
                "obj-1::obj-32": {
                    "parameter_longname": "live.numbox[4]"
                },
                "obj-20::obj-22::obj-19": {
                    "parameter_range": [ -180.0, 180.0 ]
                },
                "obj-20::obj-22::obj-29": {
                    "parameter_longname": "live.numbox[5]"
                },
                "obj-20::obj-22::obj-40": {
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-20::obj-22::obj-42": {
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-20::obj-22::obj-47": {
                    "parameter_range": [ -6.28, 6.28 ]
                },
                "obj-20::obj-22::obj-6": {
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-20::obj-22::obj-8": {
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-2::obj-19": {
                    "parameter_longname": "dim_x"
                },
                "obj-2::obj-23": {
                    "parameter_longname": "dim_y",
                    "parameter_shortname": "dim_y"
                },
                "obj-2::obj-36": {
                    "parameter_longname": "live.text"
                },
                "obj-2::obj-40": {
                    "parameter_longname": "live.text[1]"
                },
                "obj-2::obj-41": {
                    "parameter_longname": "dim_y[1]"
                },
                "obj-2::obj-42": {
                    "parameter_longname": "dim_x[1]"
                },
                "obj-2::obj-45": {
                    "parameter_longname": "live.text[2]"
                },
                "obj-2::obj-48": {
                    "parameter_longname": "live.text[4]"
                },
                "obj-2::obj-5": {
                    "parameter_longname": "live.text[3]"
                },
                "obj-2::obj-6": {
                    "parameter_longname": "live.text[16]"
                },
                "obj-5::obj-14": {
                    "parameter_longname": "live.menu[18]"
                },
                "obj-5::obj-16": {
                    "parameter_longname": "live.menu[29]"
                },
                "obj-5::obj-18": {
                    "parameter_longname": "live.menu[33]"
                },
                "obj-5::obj-2": {
                    "parameter_longname": "live.menu[23]"
                },
                "obj-5::obj-22": {
                    "parameter_longname": "live.menu[26]"
                },
                "obj-5::obj-24": {
                    "parameter_longname": "live.menu[31]"
                },
                "obj-5::obj-25": {
                    "parameter_longname": "live.menu[27]"
                },
                "obj-5::obj-26": {
                    "parameter_longname": "live.menu[30]"
                },
                "obj-5::obj-27": {
                    "parameter_longname": "live.menu[28]"
                },
                "obj-5::obj-29": {
                    "parameter_longname": "live.menu[24]"
                },
                "obj-5::obj-30": {
                    "parameter_longname": "live.menu[19]"
                },
                "obj-5::obj-33": {
                    "parameter_longname": "live.menu[32]"
                },
                "obj-5::obj-36": {
                    "parameter_longname": "live.menu[20]"
                },
                "obj-5::obj-52": {
                    "parameter_longname": "live.menu[21]"
                },
                "obj-5::obj-53": {
                    "parameter_longname": "live.menu[22]"
                },
                "obj-5::obj-56": {
                    "parameter_longname": "live.menu[25]"
                },
                "obj-8::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-8::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-8::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
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
                "obj-9::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-9::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-9::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-9::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-9::obj-32": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-9::obj-35": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-9::obj-38": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-9::obj-41": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-9::obj-44": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-9::obj-47": {
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
                "boxes": [ "obj-1", "obj-10" ]
            }
        ]
    }
}