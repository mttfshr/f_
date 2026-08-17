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
        "rect": [ 108.0, 95.0, 1293.0, 879.0 ],
        "boxes": [
            {
                "box": {
                    "id": "obj-15",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 491.0, 185.0, 65.0, 22.0 ],
                    "text": "rotation $1"
                }
            },
            {
                "box": {
                    "bgmode": 0,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-13",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_ngon.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 334.0, 221.0, 161.5, 91.0 ],
                    "varname": "f_ngon",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "id": "obj-12",
                    "maxclass": "newobj",
                    "numinlets": 6,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 671.0, 79.0, 103.0, 22.0 ],
                    "text": "scale 0. 1. 0. 6.28"
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
                    "name": "vs_lfo.maxpat",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "float" ],
                    "patching_rect": [ 663.0, -11.0, 75.0, 73.5 ],
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
                    "patching_rect": [ 657.0, 583.0, 233.0, 177.0 ],
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
                    "name": "vs_wfg_shapes.maxpat",
                    "numinlets": 2,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 657.0, 339.0, 321.0, 100.0 ],
                    "varname": "vs_wfg_shapes",
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
                    "id": "obj-23",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_vf_advect.maxpat",
                    "numinlets": 2,
                    "numoutlets": 3,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 164.0, 634.0, 203.0, 154.0 ],
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
                    "id": "obj-22",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_vf_flow.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 436.0, 354.0, 150.0, 80.0 ],
                    "varname": "f_vf_flow",
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
                    "name": "vs_preview.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 413.0, 583.0, 233.0, 177.0 ],
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
                    "name": "f_vf_prism.maxpat",
                    "numinlets": 4,
                    "numoutlets": 3,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 215.0, 349.0, 190.0, 160.0 ],
                    "varname": "f_vf_prism",
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
                    "patching_rect": [ 25.0, 339.0, 96.0, 384.0 ],
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
                    "patching_rect": [ 189.0, 818.0, 157.0, 22.0 ],
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
                    "patching_rect": [ 110.0, 14.0, 96.85526317358028, 146.5 ],
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
                    "name": "vs_wfg_3.maxpat",
                    "numinlets": 3,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 253.0, 14.0, 178.0, 132.0 ],
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
                    "id": "obj-1",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_modules.maxpat",
                    "numinlets": 0,
                    "numoutlets": 0,
                    "offset": [ 0.0, 0.0 ],
                    "patching_rect": [ 25.0, 14.0, 79.0, 316.0 ],
                    "viewvisibility": 1
                }
            }
        ],
        "lines": [
            {
                "patchline": {
                    "destination": [ "obj-12", 0 ],
                    "source": [ "obj-10", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-15", 0 ],
                    "source": [ "obj-12", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-22", 0 ],
                    "order": 0,
                    "source": [ "obj-13", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-9", 0 ],
                    "order": 1,
                    "source": [ "obj-13", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-13", 0 ],
                    "source": [ "obj-15", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-26", 0 ],
                    "source": [ "obj-2", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-23", 1 ],
                    "order": 0,
                    "source": [ "obj-22", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-9", 1 ],
                    "order": 1,
                    "source": [ "obj-22", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-4", 0 ],
                    "source": [ "obj-23", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-13", 0 ],
                    "source": [ "obj-26", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-11", 0 ],
                    "order": 1,
                    "source": [ "obj-9", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-23", 0 ],
                    "order": 0,
                    "source": [ "obj-9", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-27", 0 ],
                    "source": [ "obj-9", 2 ]
                }
            }
        ],
        "parameters": {
            "obj-10::obj-34": [ "live.dial[3]", "Freq", 0 ],
            "obj-10::obj-35": [ "live.dial[2]", "Freq", 0 ],
            "obj-10::obj-4": [ "lfo_freq__range", "live.text", 0 ],
            "obj-10::obj-82": [ "lfo_wave", "lfo_wave", 0 ],
            "obj-10::obj-9": [ "lfo_freq", "Freq", 0 ],
            "obj-10::obj-97": [ "lfo_pw", "lfo_pw", 0 ],
            "obj-13::obj-20": [ "n_mirrors", "n_mirrors", 0 ],
            "obj-13::obj-23": [ "rotation", "rotation", 0 ],
            "obj-13::obj-26": [ "scale", "scale", 0 ],
            "obj-1::obj-14": [ "live.menu[30]", "live.menu", 0 ],
            "obj-1::obj-16": [ "live.menu[31]", "live.menu", 0 ],
            "obj-1::obj-18": [ "live.menu[32]", "live.menu", 0 ],
            "obj-1::obj-2": [ "live.menu", "live.menu", 0 ],
            "obj-1::obj-22": [ "live.menu[33]", "live.menu", 0 ],
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
            "obj-22::obj-20": [ "angle", "angle", 0 ],
            "obj-22::obj-23": [ "spread[1]", "spread", 0 ],
            "obj-23::obj-20": [ "dt", "dt", 0 ],
            "obj-23::obj-23": [ "decay", "decay", 0 ],
            "obj-23::obj-26": [ "injection", "injection", 0 ],
            "obj-23::obj-29": [ "gain[1]", "gain", 0 ],
            "obj-23::obj-32": [ "separate", "separate", 0 ],
            "obj-23::obj-35": [ "mode", "mode", 0 ],
            "obj-23::obj-90": [ "mix_pct[1]", "mix_pct", 0 ],
            "obj-26::obj-13": [ "shapewfg_dir", "inevrt", 0 ],
            "obj-26::obj-130": [ "shapewfg_time", "Time", 0 ],
            "obj-26::obj-137": [ "shapewfg_shape", "shape", 0 ],
            "obj-26::obj-26": [ "shapewfg_pwm", "PWM", 0 ],
            "obj-26::obj-27": [ "shapewfg_pw", "PW", 0 ],
            "obj-26::obj-30": [ "shapewfg_fm", "PM", 0 ],
            "obj-26::obj-32": [ "shapewfg_fm_range", "scale_freq_fm", 0 ],
            "obj-26::obj-35": [ "shapewfg_freq_range", "scale_freq", 0 ],
            "obj-26::obj-36": [ "shapewfg_freq", "Freq", 0 ],
            "obj-26::obj-37": [ "shapewfg_wf", "waveform", 0 ],
            "obj-26::obj-45": [ "shapewfg_polygons", "Vertex", 0 ],
            "obj-2::obj-10": [ "wfg3_bias", "Bias", 0 ],
            "obj-2::obj-14": [ "wfg3_biasm", "BM", 0 ],
            "obj-2::obj-17": [ "live.menu[19]", "live.menu", 0 ],
            "obj-2::obj-22": [ "live.toggle[1]", "live.toggle[1]", 0 ],
            "obj-2::obj-24": [ "live.toggle", "live.toggle", 0 ],
            "obj-2::obj-25": [ "wfg3_curve", "curve", 0 ],
            "obj-2::obj-29": [ "wfg3_freq", "Freq", 0 ],
            "obj-2::obj-30": [ "wfg3_angle", "Angle", 0 ],
            "obj-2::obj-4": [ "wfg3_fm", "FM", 0 ],
            "obj-2::obj-42": [ "live.toggle[2]", "live.toggle", 0 ],
            "obj-2::obj-53": [ "wfg3_speed", "Speed", 0 ],
            "obj-2::obj-6": [ "wfg3_pm", "PM", 0 ],
            "obj-2::obj-63": [ "wfg3_phase", "Phase", 0 ],
            "obj-2::obj-65": [ "wfg3_shape", "Shape", 0 ],
            "obj-2::obj-72": [ "wfg3_phase_time_switch", "wfg2_phase_time_switch", 0 ],
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
            "obj-6::obj-12": [ "f_module_1_disp", "live.menu", 0 ],
            "obj-6::obj-13": [ "f_module_1_file", "live.menu", 0 ],
            "obj-6::obj-16": [ "f_module_2_disp", "live.menu", 0 ],
            "obj-6::obj-17": [ "f_module_2_file", "live.menu", 0 ],
            "obj-6::obj-20": [ "f_module_3_disp", "live.menu", 0 ],
            "obj-6::obj-21": [ "f_module_3_file", "live.menu", 0 ],
            "obj-6::obj-24": [ "f_module_4_disp", "live.menu", 0 ],
            "obj-6::obj-25": [ "f_module_4_file", "live.menu", 0 ],
            "obj-6::obj-28": [ "f_module_5_disp", "live.menu", 0 ],
            "obj-6::obj-29": [ "f_module_5_file", "live.menu", 0 ],
            "obj-6::obj-32": [ "f_module_6_disp", "live.menu", 0 ],
            "obj-6::obj-33": [ "f_module_6_file", "live.menu", 0 ],
            "obj-6::obj-36": [ "f_module_7_disp", "live.menu", 0 ],
            "obj-6::obj-37": [ "f_module_7_file", "live.menu", 0 ],
            "obj-6::obj-8": [ "f_module_0_disp", "live.menu", 0 ],
            "obj-6::obj-9": [ "f_module_0_file", "live.menu", 0 ],
            "obj-9::obj-20": [ "reach", "reach", 0 ],
            "obj-9::obj-23": [ "spread", "spread", 0 ],
            "obj-9::obj-26": [ "threshold", "threshold", 0 ],
            "obj-9::obj-29": [ "threshold_width", "threshold_width", 0 ],
            "obj-9::obj-32": [ "feather", "feather", 0 ],
            "obj-9::obj-35": [ "gain", "gain", 0 ],
            "obj-9::obj-38": [ "mix_pct", "mix_pct", 0 ],
            "parameterbanks": {
                "0": {
                    "index": 0,
                    "name": "",
                    "parameters": [ "-", "-", "-", "-", "-", "-", "-", "-" ],
                    "buttons": [ "-", "-", "-", "-", "-", "-", "-", "-" ]
                }
            },
            "parameter_overrides": {
                "obj-13::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-13::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-13::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-22::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-22::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_longname": "spread[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "spread",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-23::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-23::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-23::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-23::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_longname": "gain[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "gain",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-23::obj-32": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-23::obj-35": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 0,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 9
                },
                "obj-23::obj-90": {
                    "parameter_invisible": 0,
                    "parameter_longname": "mix_pct[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "mix_pct",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-26::obj-30": {
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-26::obj-36": {
                    "parameter_range": [ 0.0, 1020.0 ]
                },
                "obj-2::obj-29": {
                    "parameter_range": [ 0.0, 1020.0 ]
                },
                "obj-2::obj-4": {
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-2::obj-6": {
                    "parameter_range": [ -1.0, 1.0 ]
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
                    "parameter_longname": "gain",
                    "parameter_modmode": 3,
                    "parameter_shortname": "gain",
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
                }
            },
            "inherited_shortname": 1
        },
        "autosave": 0
    }
}