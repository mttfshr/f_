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
        "rect": [ 34.0, 95.0, 970.0, 876.0 ],
        "boxes": [
            {
                "box": {
                    "bgmode": 1,
                    "border": 1,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-22",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_preview.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 807.0, 431.0, 112.0, 102.02620087336243 ],
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
                    "name": "vs_fish_eye.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 169.0, 799.0, 62.0, 38.0 ],
                    "varname": "vs_fish_eye",
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
                    "name": "f_lens.maxpat",
                    "numinlets": 5,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 593.0, 511.0, 175.0, 155.0 ],
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
                    "id": "obj-16",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_vf_prism.maxpat",
                    "numinlets": 4,
                    "numoutlets": 3,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 578.0, 294.0, 190.0, 160.0 ],
                    "varname": "f_vf_prism",
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
                    "name": "f_stereo.maxpat",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 139.0, 694.0, 160.0, 90.0 ],
                    "varname": "f_stereo",
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
                    "name": "f_vf_advect.maxpat",
                    "numinlets": 2,
                    "numoutlets": 3,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 345.0, 479.25, 196.0, 163.0 ],
                    "varname": "f_vf_advect",
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
                    "id": "obj-26",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vsc_presets.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "" ],
                    "patching_rect": [ 117.0, 488.5, 170.0, 144.5 ],
                    "varname": "vs_presets",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "autorestore": "seeds2.json",
                    "hidden": 1,
                    "id": "obj-10",
                    "linecount": 2,
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 117.0, 575.5, 138.0, 35.0 ],
                    "priority": {
                        "vs_wfg_3::wfg3_freq_range": -1,
                        "vs_wfg_3::wfg3_fm_range": -1,
                        "vs_wfg_3::wfg3_pm_range": -1,
                        "vs_wfg_3[1]::wfg3_freq_range": -1,
                        "vs_wfg_3[1]::wfg3_fm_range": -1,
                        "vs_wfg_3[1]::wfg3_pm_range": -1,
                        "vs_wfg_3[2]::wfg3_freq_range": -1,
                        "vs_wfg_3[2]::wfg3_fm_range": -1,
                        "vs_wfg_3[2]::wfg3_pm_range": -1
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
                    "id": "obj-24",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_vf_repulse.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 294.0, 294.0, 165.0, 80.0 ],
                    "varname": "f_vf_repulse",
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
                    "id": "obj-23",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_wfg_3.maxpat",
                    "numinlets": 3,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 374.0, -20.0, 178.0, 132.0 ],
                    "varname": "vs_wfg_3[2]",
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
                    "name": "f_weave.maxpat",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 482.0, 114.0, 225.0, 150.0 ],
                    "varname": "f_weave",
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
                    "patching_rect": [ 744.0, 127.0, 122.0, 137.0 ],
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
                    "id": "obj-4",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_preview.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 163.0, 314.0, 112.0, 102.02620087336243 ],
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
                    "id": "obj-17",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_output.maxpat",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "offset": [ 0.0, 0.0 ],
                    "patching_rect": [ 206.0, 848.0, 157.0, 22.0 ],
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
                    "id": "obj-21",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_modules.maxpat",
                    "numinlets": 0,
                    "numoutlets": 0,
                    "offset": [ 0.0, 0.0 ],
                    "patching_rect": [ 14.0, 330.0, 101.0, 383.0 ],
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
                    "name": "vs_render.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "" ],
                    "patching_rect": [ 99.0, 4.0, 96.85526317358028, 146.5 ],
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
                    "patching_rect": [ 14.0, 4.0, 79.0, 316.0 ],
                    "viewvisibility": 1
                }
            }
        ],
        "lines": [
            {
                "patchline": {
                    "destination": [ "obj-19", 0 ],
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
                    "destination": [ "obj-13", 0 ],
                    "order": 2,
                    "source": [ "obj-18", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-16", 0 ],
                    "order": 0,
                    "source": [ "obj-18", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-24", 0 ],
                    "order": 1,
                    "source": [ "obj-18", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-8", 0 ],
                    "source": [ "obj-19", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-17", 0 ],
                    "source": [ "obj-20", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-18", 0 ],
                    "source": [ "obj-23", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-4", 0 ],
                    "order": 1,
                    "source": [ "obj-24", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-8", 1 ],
                    "order": 0,
                    "source": [ "obj-24", 0 ]
                }
            },
            {
                "patchline": {
                    "color": [ 0.65, 0.65, 0.65, 0.0 ],
                    "destination": [ "obj-10", 0 ],
                    "hidden": 1,
                    "source": [ "obj-26", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-9", 0 ],
                    "source": [ "obj-8", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-20", 0 ],
                    "source": [ "obj-9", 0 ]
                }
            }
        ],
        "parameters": {
            "obj-16::obj-20": [ "reach[2]", "reach", 0 ],
            "obj-16::obj-23": [ "spread", "spread", 0 ],
            "obj-16::obj-26": [ "threshold[1]", "threshold", 0 ],
            "obj-16::obj-29": [ "threshold_width", "threshold_width", 0 ],
            "obj-16::obj-32": [ "feather", "feather", 0 ],
            "obj-16::obj-35": [ "gain[3]", "gain", 0 ],
            "obj-16::obj-38": [ "mix_pct", "mix_pct", 0 ],
            "obj-17::obj-1": [ "toggle[1]", "toggle[1]", 0 ],
            "obj-17::obj-10": [ "toggle[3]", "toggle[2]", 0 ],
            "obj-17::obj-36": [ "uppr_x", "uppr_x", 0 ],
            "obj-18::obj-20": [ "density[1]", "density", 0 ],
            "obj-18::obj-23": [ "angle[4]", "angle", 0 ],
            "obj-18::obj-26": [ "weight", "weight", 0 ],
            "obj-18::obj-29": [ "marklen", "marklen", 0 ],
            "obj-18::obj-32": [ "regularity", "regularity", 0 ],
            "obj-18::obj-35": [ "phase[4]", "phase", 0 ],
            "obj-18::obj-50": [ "softness", "softness", 0 ],
            "obj-18::obj-53": [ "shape[3]", "shape", 0 ],
            "obj-19::obj-19d": [ "panel_toggle", "panel_toggle", 0 ],
            "obj-19::obj-20": [ "aberration", "aberration", 0 ],
            "obj-19::obj-23": [ "distortion", "distortion", 0 ],
            "obj-19::obj-26": [ "transmission", "transmission", 0 ],
            "obj-19::obj-29": [ "aberration_mod", "aberration_mod", 0 ],
            "obj-19::obj-300": [ "range_aberration", "range_aberration", 0 ],
            "obj-19::obj-310": [ "range_distortion", "range_distortion", 0 ],
            "obj-19::obj-32": [ "distortion_mod", "distortion_mod", 0 ],
            "obj-19::obj-320": [ "range_transmission", "range_transmission", 0 ],
            "obj-19::obj-35": [ "transmission_mod", "transmission_mod", 0 ],
            "obj-19::obj-38": [ "surface_mod", "surface_mod", 0 ],
            "obj-19::obj-390": [ "range_ghost_spacing", "range_ghost_spacing", 0 ],
            "obj-19::obj-41": [ "ghost", "ghost", 0 ],
            "obj-19::obj-44": [ "ghost_count", "ghost_count", 0 ],
            "obj-19::obj-47": [ "ghost_spacing", "ghost_spacing", 0 ],
            "obj-19::obj-50": [ "halation", "halation", 0 ],
            "obj-19::obj-53": [ "halation_threshold", "halation_threshold", 0 ],
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
            "obj-20::obj-11": [ "pixelador_dim", "pixelador_dim", 0 ],
            "obj-21::obj-12": [ "f_module_1_disp", "live.menu", 0 ],
            "obj-21::obj-13": [ "f_module_1_file", "live.menu", 0 ],
            "obj-21::obj-16": [ "f_module_2_disp", "live.menu", 0 ],
            "obj-21::obj-17": [ "f_module_2_file", "live.menu", 0 ],
            "obj-21::obj-20": [ "f_module_3_disp", "live.menu", 0 ],
            "obj-21::obj-21": [ "f_module_3_file", "live.menu", 0 ],
            "obj-21::obj-24": [ "f_module_4_disp", "live.menu", 0 ],
            "obj-21::obj-25": [ "f_module_4_file", "live.menu", 0 ],
            "obj-21::obj-28": [ "f_module_5_disp", "live.menu", 0 ],
            "obj-21::obj-29": [ "f_module_5_file", "live.menu", 0 ],
            "obj-21::obj-32": [ "f_module_6_disp", "live.menu", 0 ],
            "obj-21::obj-33": [ "f_module_6_file", "live.menu", 0 ],
            "obj-21::obj-36": [ "f_module_7_disp", "live.menu", 0 ],
            "obj-21::obj-37": [ "f_module_7_file", "live.menu", 0 ],
            "obj-21::obj-8": [ "f_module_0_disp", "live.menu", 0 ],
            "obj-21::obj-9": [ "f_module_0_file", "live.menu", 0 ],
            "obj-23::obj-10": [ "wfg3_bias[2]", "Bias", 0 ],
            "obj-23::obj-14": [ "wfg3_biasm[2]", "BM", 0 ],
            "obj-23::obj-17": [ "live.menu[23]", "live.menu", 0 ],
            "obj-23::obj-22": [ "live.toggle[9]", "live.toggle[1]", 0 ],
            "obj-23::obj-24": [ "live.toggle[10]", "live.toggle", 0 ],
            "obj-23::obj-25": [ "wfg3_curve[2]", "curve", 0 ],
            "obj-23::obj-29": [ "wfg3_freq[2]", "Freq", 0 ],
            "obj-23::obj-30": [ "wfg3_angle[2]", "Angle", 0 ],
            "obj-23::obj-4": [ "wfg3_fm[2]", "FM", 0 ],
            "obj-23::obj-42": [ "live.toggle[8]", "live.toggle", 0 ],
            "obj-23::obj-53": [ "wfg3_speed[2]", "Speed", 0 ],
            "obj-23::obj-6": [ "wfg3_pm[2]", "PM", 0 ],
            "obj-23::obj-63": [ "wfg3_phase[2]", "Phase", 0 ],
            "obj-23::obj-65": [ "wfg3_shape[2]", "Shape", 0 ],
            "obj-23::obj-72": [ "wfg3_phase_time_switch[2]", "wfg2_phase_time_switch", 0 ],
            "obj-24::obj-20": [ "gain", "gain", 0 ],
            "obj-24::obj-23": [ "reach", "reach", 0 ],
            "obj-24::obj-26": [ "threshold", "threshold", 0 ],
            "obj-24::obj-29": [ "mode", "mode", 0 ],
            "obj-26::obj-10": [ "textedit", "vs_preset_name", 0 ],
            "obj-26::obj-11": [ "live.text", "live.text", 0 ],
            "obj-26::obj-15": [ "live.tab", "live.tab", 0 ],
            "obj-26::obj-32": [ "live.numbox[4]", "live.numbox", 0 ],
            "obj-26::obj-44": [ "live.tab[3]", "live.tab", 0 ],
            "obj-26::obj-45::obj-16": [ "live.menu[24]", "live.menu[16]", 0 ],
            "obj-26::obj-45::obj-17": [ "live.button", "live.button", 0 ],
            "obj-26::obj-45::obj-19": [ "live.numbox[2]", "live.numbox[1]", 0 ],
            "obj-26::obj-45::obj-32": [ "live.numbox", "live.numbox", 0 ],
            "obj-26::obj-45::obj-9": [ "live.numbox[3]", "live.numbox", 0 ],
            "obj-2::obj-19": [ "dim_x[2]", "dim_x", 0 ],
            "obj-2::obj-23": [ "pwm[1]", "pwm", 0 ],
            "obj-2::obj-36": [ "live.text[11]", "live.text", 0 ],
            "obj-2::obj-40": [ "live.text[6]", "live.text", 0 ],
            "obj-2::obj-41": [ "dim_y[2]", "dim_y", 0 ],
            "obj-2::obj-42": [ "dim_x[3]", "dim_x", 0 ],
            "obj-2::obj-45": [ "live.text[10]", "live.text", 0 ],
            "obj-2::obj-48": [ "live.text[7]", "live.text", 0 ],
            "obj-2::obj-5": [ "live.text[9]", "live.text", 0 ],
            "obj-2::obj-6": [ "live.text[8]", "live.text", 0 ],
            "obj-8::obj-20": [ "dt", "dt", 0 ],
            "obj-8::obj-23": [ "decay[1]", "decay", 0 ],
            "obj-8::obj-26": [ "injection[1]", "injection", 0 ],
            "obj-8::obj-29": [ "gain[2]", "gain", 0 ],
            "obj-8::obj-32": [ "separate", "separate", 0 ],
            "obj-8::obj-35": [ "mode[1]", "mode", 0 ],
            "obj-8::obj-90": [ "mix_pct[1]", "mix_pct", 0 ],
            "obj-9::obj-10": [ "lon", "lon", 0 ],
            "obj-9::obj-12": [ "lat", "lat", 0 ],
            "obj-9::obj-14": [ "spin", "spin", 0 ],
            "obj-9::obj-16": [ "proj", "proj", 0 ],
            "obj-9::obj-32": [ "circ", "circ", 0 ],
            "parameterbanks": {
                "0": {
                    "index": 0,
                    "name": "",
                    "parameters": [ "-", "-", "-", "-", "-", "-", "-", "-" ],
                    "buttons": [ "-", "-", "-", "-", "-", "-", "-", "-" ]
                }
            },
            "parameter_overrides": {
                "obj-16::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_longname": "reach[2]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "reach",
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
                    "parameter_longname": "threshold[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "threshold",
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
                    "parameter_longname": "gain[3]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "gain",
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
                "obj-18::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_longname": "density[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "density",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-18::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_longname": "angle[4]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "angle",
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
                    "parameter_longname": "phase[4]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "phase",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-18::obj-50": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-18::obj-53": {
                    "parameter_invisible": 0,
                    "parameter_longname": "shape[3]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "shape",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-19::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_range": [ -1.0, 1.0 ],
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-19::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_range": [ -1.0, 1.0 ],
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-19::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_range": [ -1.0, 1.0 ],
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-19::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-19::obj-32": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-19::obj-35": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-19::obj-38": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-19::obj-41": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-19::obj-44": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-19::obj-47": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_range": [ -1.0, 1.0 ],
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
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
                "obj-23::obj-10": {
                    "parameter_longname": "wfg3_bias[2]"
                },
                "obj-23::obj-14": {
                    "parameter_longname": "wfg3_biasm[2]"
                },
                "obj-23::obj-17": {
                    "parameter_longname": "live.menu[23]"
                },
                "obj-23::obj-22": {
                    "parameter_longname": "live.toggle[9]"
                },
                "obj-23::obj-24": {
                    "parameter_longname": "live.toggle[10]"
                },
                "obj-23::obj-25": {
                    "parameter_longname": "wfg3_curve[2]"
                },
                "obj-23::obj-29": {
                    "parameter_longname": "wfg3_freq[2]",
                    "parameter_range": [ 0.0, 1020.0 ]
                },
                "obj-23::obj-30": {
                    "parameter_longname": "wfg3_angle[2]"
                },
                "obj-23::obj-4": {
                    "parameter_longname": "wfg3_fm[2]",
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-23::obj-42": {
                    "parameter_longname": "live.toggle[8]"
                },
                "obj-23::obj-53": {
                    "parameter_longname": "wfg3_speed[2]"
                },
                "obj-23::obj-6": {
                    "parameter_longname": "wfg3_pm[2]",
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-23::obj-63": {
                    "parameter_longname": "wfg3_phase[2]"
                },
                "obj-23::obj-65": {
                    "parameter_longname": "wfg3_shape[2]"
                },
                "obj-23::obj-72": {
                    "parameter_longname": "wfg3_phase_time_switch[2]"
                },
                "obj-24::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-24::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-24::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-24::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 0,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 9
                },
                "obj-26::obj-32": {
                    "parameter_longname": "live.numbox[4]"
                },
                "obj-26::obj-45::obj-16": {
                    "parameter_longname": "live.menu[24]"
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
                    "parameter_longname": "decay[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "decay",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-8::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_longname": "injection[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "injection",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-8::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_longname": "gain[2]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "gain",
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
                    "parameter_longname": "mode[1]",
                    "parameter_modmode": 0,
                    "parameter_shortname": "mode",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 9
                },
                "obj-8::obj-90": {
                    "parameter_invisible": 0,
                    "parameter_longname": "mix_pct[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "mix_pct",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-9::obj-10": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-9::obj-12": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-9::obj-14": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-9::obj-16": {
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
                "boxes": [ "obj-26", "obj-10" ]
            }
        ]
    }
}