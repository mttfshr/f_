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
        "rect": [ 60.0, 102.0, 1190.0, 798.0 ],
        "boxes": [
            {
                "box": {
                    "bgmode": 1,
                    "border": 1,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-32",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_wfg_3.maxpat",
                    "numinlets": 3,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 1014.5832946300507, 65.6249977350235, 178.0, 132.0 ],
                    "varname": "vs_wfg_3",
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
                    "id": "obj-30",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vsc_presets.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "" ],
                    "patching_rect": [ 796.8749696016312, 59.3749977350235, 170.0, 144.5 ],
                    "varname": "vs_presets",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "autorestore": "repulse-scratch.json",
                    "hidden": 1,
                    "id": "obj-10",
                    "linecount": 2,
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 796.8749696016312, 146.8749943971634, 138.0, 35.0 ],
                    "priority": {
                        "vs_lfo::lfo_freq_range": -1,
                        "vs_wfg_3::wfg3_freq_range": -1,
                        "vs_wfg_3::wfg3_fm_range": -1,
                        "vs_wfg_3::wfg3_pm_range": -1
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
                    "id": "obj-29",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_lfo.maxpat",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "float" ],
                    "patching_rect": [ 629.166642665863, 16.66666603088379, 75.0, 73.5 ],
                    "varname": "vs_lfo",
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
                    "id": "obj-27",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_preview.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 444.7916496992111, 467.70831549167633, 385.4166519641876, 266.6666564941406 ],
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
                    "id": "obj-26",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_vf_repulse.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 482.0, 313.0, 169.7916601896286, 91.66666316986084 ],
                    "varname": "f_vf_repulse",
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
                    "name": "f_vf_advect.maxpat",
                    "numinlets": 2,
                    "numoutlets": 3,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 210.41665863990784, 332.29165399074554, 190.0, 130.0 ],
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
                    "id": "obj-5",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_masonry.maxpat",
                    "numinlets": 4,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 332.29165399074554, 29.041656136512756, 309.0, 245.0 ],
                    "varname": "f_masonry",
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
                    "name": "vs_output.maxpat",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "offset": [ 0.0, 0.0 ],
                    "patching_rect": [ 220.8333249092102, 519.5, 157.0, 22.0 ],
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
                    "patching_rect": [ 104.0, 13.0, 96.85526317358028, 146.5 ],
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
                    "id": "obj-2",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_modules.maxpat",
                    "numinlets": 0,
                    "numoutlets": 0,
                    "offset": [ 0.0, 0.0 ],
                    "patching_rect": [ 19.0, 352.0, 96.0, 249.0 ],
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
                    "patching_rect": [ 19.0, 13.0, 79.0, 316.0 ],
                    "viewvisibility": 1
                }
            }
        ],
        "lines": [
            {
                "patchline": {
                    "destination": [ "obj-4", 0 ],
                    "source": [ "obj-16", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-16", 1 ],
                    "order": 0,
                    "source": [ "obj-26", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-27", 0 ],
                    "order": 1,
                    "source": [ "obj-26", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 1 ],
                    "source": [ "obj-29", 0 ]
                }
            },
            {
                "patchline": {
                    "color": [ 0.65, 0.65, 0.65, 0.0 ],
                    "destination": [ "obj-10", 0 ],
                    "hidden": 1,
                    "source": [ "obj-30", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 0 ],
                    "source": [ "obj-32", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-16", 0 ],
                    "order": 1,
                    "source": [ "obj-5", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-26", 0 ],
                    "order": 0,
                    "source": [ "obj-5", 0 ]
                }
            }
        ],
        "parameters": {
            "obj-16::obj-20": [ "dt", "dt", 0 ],
            "obj-16::obj-23": [ "decay", "decay", 0 ],
            "obj-16::obj-26": [ "injection", "injection", 0 ],
            "obj-16::obj-29": [ "mix_amt", "gain", 0 ],
            "obj-16::obj-32": [ "separate", "separate", 0 ],
            "obj-16::obj-35": [ "mode", "mode", 0 ],
            "obj-16::obj-90": [ "mix_pct", "mix_pct", 0 ],
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
            "obj-26::obj-20": [ "strength", "gain", 0 ],
            "obj-26::obj-23": [ "reach", "reach", 0 ],
            "obj-26::obj-26": [ "threshold", "threshold", 0 ],
            "obj-26::obj-29": [ "mode[1]", "mode", 0 ],
            "obj-29::obj-34": [ "live.dial[3]", "Freq", 0 ],
            "obj-29::obj-35": [ "live.dial[2]", "Freq", 0 ],
            "obj-29::obj-4": [ "lfo_freq__range", "live.text", 0 ],
            "obj-29::obj-82": [ "lfo_wave", "lfo_wave", 0 ],
            "obj-29::obj-9": [ "lfo_freq", "Freq", 0 ],
            "obj-29::obj-97": [ "lfo_pw", "lfo_pw", 0 ],
            "obj-2::obj-12": [ "f_module_1_disp", "live.menu", 0 ],
            "obj-2::obj-13": [ "f_module_1_file", "live.menu", 0 ],
            "obj-2::obj-16": [ "f_module_2_disp", "live.menu", 0 ],
            "obj-2::obj-17": [ "f_module_2_file", "live.menu", 0 ],
            "obj-2::obj-20": [ "f_module_3_disp", "live.menu", 0 ],
            "obj-2::obj-21": [ "f_module_3_file", "live.menu", 0 ],
            "obj-2::obj-24": [ "live.menu[39]", "live.menu", 0 ],
            "obj-2::obj-25": [ "live.menu[47]", "live.menu", 0 ],
            "obj-2::obj-28": [ "f_module_5_disp", "live.menu", 0 ],
            "obj-2::obj-29": [ "f_module_5_file", "live.menu", 0 ],
            "obj-2::obj-32": [ "f_module_6_disp", "live.menu", 0 ],
            "obj-2::obj-33": [ "f_module_6_file", "live.menu", 0 ],
            "obj-2::obj-36": [ "f_module_7_disp", "live.menu", 0 ],
            "obj-2::obj-37": [ "f_module_7_file", "live.menu", 0 ],
            "obj-2::obj-8": [ "f_module_0_disp", "live.menu", 0 ],
            "obj-2::obj-9": [ "f_module_0_file", "live.menu", 0 ],
            "obj-30::obj-10": [ "textedit", "vs_preset_name", 0 ],
            "obj-30::obj-11": [ "live.text", "live.text", 0 ],
            "obj-30::obj-15": [ "live.tab", "live.tab", 0 ],
            "obj-30::obj-32": [ "live.numbox[4]", "live.numbox", 0 ],
            "obj-30::obj-44": [ "live.tab[3]", "live.tab", 0 ],
            "obj-30::obj-45::obj-16": [ "live.menu[18]", "live.menu[16]", 0 ],
            "obj-30::obj-45::obj-17": [ "live.button", "live.button", 0 ],
            "obj-30::obj-45::obj-19": [ "live.numbox[2]", "live.numbox[1]", 0 ],
            "obj-30::obj-45::obj-32": [ "live.numbox", "live.numbox", 0 ],
            "obj-30::obj-45::obj-9": [ "live.numbox[3]", "live.numbox", 0 ],
            "obj-32::obj-10": [ "wfg3_bias", "Bias", 0 ],
            "obj-32::obj-14": [ "wfg3_biasm", "BM", 0 ],
            "obj-32::obj-17": [ "live.menu[19]", "live.menu", 0 ],
            "obj-32::obj-22": [ "live.toggle[1]", "live.toggle[1]", 0 ],
            "obj-32::obj-24": [ "live.toggle", "live.toggle", 0 ],
            "obj-32::obj-25": [ "wfg3_curve", "curve", 0 ],
            "obj-32::obj-29": [ "wfg3_freq", "Freq", 0 ],
            "obj-32::obj-30": [ "wfg3_angle", "Angle", 0 ],
            "obj-32::obj-4": [ "wfg3_fm", "FM", 0 ],
            "obj-32::obj-42": [ "live.toggle[2]", "live.toggle", 0 ],
            "obj-32::obj-53": [ "wfg3_speed", "Speed", 0 ],
            "obj-32::obj-6": [ "wfg3_pm", "PM", 0 ],
            "obj-32::obj-63": [ "wfg3_phase", "Phase", 0 ],
            "obj-32::obj-65": [ "wfg3_shape", "Shape", 0 ],
            "obj-32::obj-72": [ "wfg3_phase_time_switch", "wfg2_phase_time_switch", 0 ],
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
            "obj-4::obj-1": [ "toggle[1]", "toggle[1]", 0 ],
            "obj-4::obj-10": [ "toggle[3]", "toggle[2]", 0 ],
            "obj-4::obj-36": [ "uppr_x", "uppr_x", 0 ],
            "obj-5::obj-125": [ "panel_toggle", "panel_toggle", 0 ],
            "obj-5::obj-20": [ "courses", "courses", 0 ],
            "obj-5::obj-21": [ "bond", "bond", 0 ],
            "obj-5::obj-22": [ "offset", "offset", 0 ],
            "obj-5::obj-23": [ "angle", "angle", 0 ],
            "obj-5::obj-24": [ "skip", "skip", 0 ],
            "obj-5::obj-25": [ "quantize", "quantize", 0 ],
            "obj-5::obj-26": [ "regularity", "regularity", 0 ],
            "obj-5::obj-27": [ "drift", "drift", 0 ],
            "obj-5::obj-28": [ "phase", "phase", 0 ],
            "obj-5::obj-29": [ "speed_var", "speed_var", 0 ],
            "obj-5::obj-30": [ "mortar", "mortar", 0 ],
            "obj-5::obj-31": [ "softness", "softness", 0 ],
            "obj-5::obj-32": [ "width", "width", 0 ],
            "obj-5::obj-33": [ "roundness", "roundness", 0 ],
            "obj-5::obj-35": [ "course_color", "course_color", 0 ],
            "obj-5::obj-36": [ "brick_color", "brick_color", 0 ],
            "obj-5::obj-90": [ "course_seed", "course_seed", 0 ],
            "obj-5::obj-91": [ "brick_seed", "brick_seed", 0 ],
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
                    "parameter_modmode": 3,
                    "parameter_range": [ 0.0, 0.05 ],
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
                    "parameter_range": [ 0.0, 0.5 ],
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-16::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_longname": "mix_amt",
                    "parameter_modmode": 3,
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
                "obj-26::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_longname": "strength",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-26::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-26::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-26::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_longname": "mode[1]",
                    "parameter_modmode": 0,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 9
                },
                "obj-2::obj-24": {
                    "parameter_longname": "live.menu[39]"
                },
                "obj-2::obj-25": {
                    "parameter_longname": "live.menu[47]"
                },
                "obj-30::obj-32": {
                    "parameter_longname": "live.numbox[4]"
                },
                "obj-30::obj-45::obj-16": {
                    "parameter_longname": "live.menu[18]"
                },
                "obj-32::obj-29": {
                    "parameter_range": [ 0.0, 1020.0 ]
                },
                "obj-32::obj-4": {
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-32::obj-6": {
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-5::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-5::obj-21": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-5::obj-22": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-5::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-5::obj-24": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-5::obj-25": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-5::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-5::obj-27": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-5::obj-28": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-5::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-5::obj-30": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-5::obj-31": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-5::obj-32": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-5::obj-33": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-5::obj-35": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-5::obj-36": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-5::obj-90": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-5::obj-91": {
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
                "boxes": [ "obj-30", "obj-10" ]
            }
        ]
    }
}