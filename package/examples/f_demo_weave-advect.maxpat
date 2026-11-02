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
        "rect": [ 68.0, 141.0, 970.0, 876.0 ],
        "boxes": [
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
                    "name": "vs_wfg_polarizer.maxpat",
                    "numinlets": 2,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 661.0, 587.0, 220.0, 132.0 ],
                    "varname": "vs_wfg_polarizer[4]",
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
                    "name": "vs_wfg_polarizer.maxpat",
                    "numinlets": 2,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 661.0, 388.0, 220.0, 132.0 ],
                    "varname": "vs_wfg_polarizer[3]",
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
                    "patching_rect": [ 653.0, 231.0, 220.0, 132.0 ],
                    "varname": "vs_wfg_polarizer[2]",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "id": "obj-8",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 395.0, 234.0, 103.0, 22.0 ],
                    "text": "prepend irreg_tex"
                }
            },
            {
                "box": {
                    "id": "obj-7",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 422.0, 362.0, 113.0, 22.0 ],
                    "text": "prepend weight_tex"
                }
            },
            {
                "box": {
                    "id": "obj-4",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 440.0, 286.0, 121.0, 22.0 ],
                    "text": "prepend marklen_tex"
                }
            },
            {
                "box": {
                    "bgmode": 0,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-3",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_weave.maxpat",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 327.0, 412.0, 234.0, 185.0 ],
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
                    "id": "obj-6",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_wfg_polarizer.maxpat",
                    "numinlets": 2,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 475.0, 23.0, 220.0, 132.0 ],
                    "varname": "vs_wfg_polarizer[1]",
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
                    "name": "vs_wfg_polarizer.maxpat",
                    "numinlets": 2,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 229.0, 18.5, 220.0, 132.0 ],
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
                    "autorestore": "f_demo_weave-advect.json",
                    "hidden": 1,
                    "id": "obj-10",
                    "linecount": 2,
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 117.0, 575.5, 138.0, 35.0 ],
                    "priority": {
                        "vs_wfg_polarizer::pm_range": -1,
                        "vs_wfg_polarizer::lock_freq": -1,
                        "vs_wfg_polarizer[1]::pm_range": -1,
                        "vs_wfg_polarizer[1]::lock_freq": -1,
                        "vs_wfg_polarizer[2]::lock_freq": -1,
                        "vs_wfg_polarizer[2]::pm_range": -1,
                        "vs_wfg_polarizer[3]::lock_freq": -1,
                        "vs_wfg_polarizer[3]::pm_range": -1,
                        "vs_wfg_polarizer[4]::lock_freq": -1,
                        "vs_wfg_polarizer[4]::pm_range": -1
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
                    "id": "obj-17",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_output.maxpat",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "offset": [ 0.0, 0.0 ],
                    "patching_rect": [ 284.5, 774.0, 157.0, 22.0 ],
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
                    "patching_rect": [ 14.0, 330.0, 101.0, 430.0 ],
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
                    "destination": [ "obj-3", 0 ],
                    "source": [ "obj-11", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-3", 1 ],
                    "source": [ "obj-12", 0 ]
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
                    "destination": [ "obj-17", 0 ],
                    "source": [ "obj-3", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-3", 0 ],
                    "source": [ "obj-4", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-8", 0 ],
                    "source": [ "obj-5", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-4", 0 ],
                    "source": [ "obj-6", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-3", 0 ],
                    "source": [ "obj-7", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-3", 0 ],
                    "source": [ "obj-8", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-7", 0 ],
                    "source": [ "obj-9", 0 ]
                }
            }
        ],
        "parameters": {
            "obj-11::obj-10": [ "bias[3]", "Bias", 0 ],
            "obj-11::obj-14": [ "bm[3]", "BM", 0 ],
            "obj-11::obj-17": [ "live.menu[19]", "live.menu", 0 ],
            "obj-11::obj-22": [ "live.text[14]", "live.text", 0 ],
            "obj-11::obj-29": [ "freq[3]", "Freq", 0 ],
            "obj-11::obj-30": [ "angle[3]", "Angle", 0 ],
            "obj-11::obj-42": [ "live.toggle[4]", "live.toggle", 0 ],
            "obj-11::obj-47": [ "polarizer[3]", "Morph", 0 ],
            "obj-11::obj-51": [ "live.menu[18]", "live.menu", 0 ],
            "obj-11::obj-53": [ "speed[3]", "Speed", 0 ],
            "obj-11::obj-54": [ "morph[3]", "Morph", 0 ],
            "obj-11::obj-6": [ "pm[3]", "PM", 0 ],
            "obj-11::obj-65": [ "shape[4]", "Shape", 0 ],
            "obj-11::obj-71": [ "phase[6]", "Phase", 0 ],
            "obj-11::obj-72": [ "phase_time_switch[3]", "phase_time_switch", 0 ],
            "obj-12::obj-10": [ "bias[4]", "Bias", 0 ],
            "obj-12::obj-14": [ "bm[4]", "BM", 0 ],
            "obj-12::obj-17": [ "live.menu[20]", "live.menu", 0 ],
            "obj-12::obj-22": [ "live.text[15]", "live.text", 0 ],
            "obj-12::obj-29": [ "freq[4]", "Freq", 0 ],
            "obj-12::obj-30": [ "angle[5]", "Angle", 0 ],
            "obj-12::obj-42": [ "live.toggle[11]", "live.toggle", 0 ],
            "obj-12::obj-47": [ "polarizer[4]", "Morph", 0 ],
            "obj-12::obj-51": [ "live.menu[27]", "live.menu", 0 ],
            "obj-12::obj-53": [ "speed[4]", "Speed", 0 ],
            "obj-12::obj-54": [ "morph[4]", "Morph", 0 ],
            "obj-12::obj-6": [ "pm[4]", "PM", 0 ],
            "obj-12::obj-65": [ "shape[5]", "Shape", 0 ],
            "obj-12::obj-71": [ "phase[7]", "Phase", 0 ],
            "obj-12::obj-72": [ "phase_time_switch[4]", "phase_time_switch", 0 ],
            "obj-17::obj-1": [ "toggle[1]", "toggle[1]", 0 ],
            "obj-17::obj-10": [ "toggle[3]", "toggle[2]", 0 ],
            "obj-17::obj-36": [ "uppr_x", "uppr_x", 0 ],
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
            "obj-21::obj-40": [ "f_module_8_disp", "live.menu", 0 ],
            "obj-21::obj-41": [ "f_module_8_file", "live.menu", 0 ],
            "obj-21::obj-44": [ "f_module_9_disp", "live.menu", 0 ],
            "obj-21::obj-45": [ "f_module_9_file", "live.menu", 0 ],
            "obj-21::obj-8": [ "f_module_0_disp", "live.menu", 0 ],
            "obj-21::obj-9": [ "f_module_0_file", "live.menu", 0 ],
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
            "obj-3::obj-20": [ "density", "density", 0 ],
            "obj-3::obj-23": [ "angle[4]", "angle", 0 ],
            "obj-3::obj-26": [ "weight", "weight", 0 ],
            "obj-3::obj-29": [ "marklen", "marklen", 0 ],
            "obj-3::obj-32": [ "regularity", "offset", 0 ],
            "obj-3::obj-35": [ "phase[4]", "phase", 0 ],
            "obj-3::obj-38": [ "softness", "softness", 0 ],
            "obj-3::obj-41": [ "shape", "variant", 0 ],
            "obj-3::obj-44": [ "irreg", "irreg", 0 ],
            "obj-3::obj-47": [ "nscale", "nscale", 0 ],
            "obj-3::obj-50": [ "weight_m", "weight_m", 0 ],
            "obj-3::obj-53": [ "irreg_m", "irreg_m", 0 ],
            "obj-3::obj-56": [ "marklen_m", "marklen_m", 0 ],
            "obj-3::obj-59": [ "mmode", "mmode", 0 ],
            "obj-5::obj-10": [ "bias", "Bias", 0 ],
            "obj-5::obj-14": [ "bm", "BM", 0 ],
            "obj-5::obj-17": [ "live.menu[41]", "live.menu", 0 ],
            "obj-5::obj-22": [ "live.text[3]", "live.text", 0 ],
            "obj-5::obj-29": [ "freq", "Freq", 0 ],
            "obj-5::obj-30": [ "angle", "Angle", 0 ],
            "obj-5::obj-42": [ "live.toggle[2]", "live.toggle", 0 ],
            "obj-5::obj-47": [ "polarizer", "Morph", 0 ],
            "obj-5::obj-51": [ "live.menu[40]", "live.menu", 0 ],
            "obj-5::obj-53": [ "speed", "Speed", 0 ],
            "obj-5::obj-54": [ "morph", "Morph", 0 ],
            "obj-5::obj-6": [ "pm", "PM", 0 ],
            "obj-5::obj-65": [ "shape[1]", "Shape", 0 ],
            "obj-5::obj-71": [ "phase", "Phase", 0 ],
            "obj-5::obj-72": [ "phase_time_switch", "phase_time_switch", 0 ],
            "obj-6::obj-10": [ "bias[1]", "Bias", 0 ],
            "obj-6::obj-14": [ "bm[1]", "BM", 0 ],
            "obj-6::obj-17": [ "live.menu[43]", "live.menu", 0 ],
            "obj-6::obj-22": [ "live.text[12]", "live.text", 0 ],
            "obj-6::obj-29": [ "freq[1]", "Freq", 0 ],
            "obj-6::obj-30": [ "angle[1]", "Angle", 0 ],
            "obj-6::obj-42": [ "live.toggle[10]", "live.toggle", 0 ],
            "obj-6::obj-47": [ "polarizer[1]", "Morph", 0 ],
            "obj-6::obj-51": [ "live.menu[42]", "live.menu", 0 ],
            "obj-6::obj-53": [ "speed[1]", "Speed", 0 ],
            "obj-6::obj-54": [ "morph[1]", "Morph", 0 ],
            "obj-6::obj-6": [ "pm[1]", "PM", 0 ],
            "obj-6::obj-65": [ "shape[2]", "Shape", 0 ],
            "obj-6::obj-71": [ "phase[1]", "Phase", 0 ],
            "obj-6::obj-72": [ "phase_time_switch[1]", "phase_time_switch", 0 ],
            "obj-9::obj-10": [ "bias[2]", "Bias", 0 ],
            "obj-9::obj-14": [ "bm[2]", "BM", 0 ],
            "obj-9::obj-17": [ "live.menu[26]", "live.menu", 0 ],
            "obj-9::obj-22": [ "live.text[13]", "live.text", 0 ],
            "obj-9::obj-29": [ "freq[2]", "Freq", 0 ],
            "obj-9::obj-30": [ "angle[2]", "Angle", 0 ],
            "obj-9::obj-42": [ "live.toggle[3]", "live.toggle", 0 ],
            "obj-9::obj-47": [ "polarizer[2]", "Morph", 0 ],
            "obj-9::obj-51": [ "live.menu[25]", "live.menu", 0 ],
            "obj-9::obj-53": [ "speed[2]", "Speed", 0 ],
            "obj-9::obj-54": [ "morph[2]", "Morph", 0 ],
            "obj-9::obj-6": [ "pm[2]", "PM", 0 ],
            "obj-9::obj-65": [ "shape[3]", "Shape", 0 ],
            "obj-9::obj-71": [ "phase[5]", "Phase", 0 ],
            "obj-9::obj-72": [ "phase_time_switch[2]", "phase_time_switch", 0 ],
            "parameterbanks": {
                "0": {
                    "index": 0,
                    "name": "",
                    "parameters": [ "-", "-", "-", "-", "-", "-", "-", "-" ],
                    "buttons": [ "-", "-", "-", "-", "-", "-", "-", "-" ]
                }
            },
            "parameter_overrides": {
                "obj-11::obj-10": {
                    "parameter_longname": "bias[3]"
                },
                "obj-11::obj-14": {
                    "parameter_longname": "bm[3]"
                },
                "obj-11::obj-17": {
                    "parameter_longname": "live.menu[19]"
                },
                "obj-11::obj-22": {
                    "parameter_longname": "live.text[14]"
                },
                "obj-11::obj-29": {
                    "parameter_longname": "freq[3]"
                },
                "obj-11::obj-30": {
                    "parameter_longname": "angle[3]"
                },
                "obj-11::obj-42": {
                    "parameter_longname": "live.toggle[4]"
                },
                "obj-11::obj-47": {
                    "parameter_longname": "polarizer[3]"
                },
                "obj-11::obj-51": {
                    "parameter_longname": "live.menu[18]"
                },
                "obj-11::obj-53": {
                    "parameter_longname": "speed[3]"
                },
                "obj-11::obj-54": {
                    "parameter_longname": "morph[3]"
                },
                "obj-11::obj-6": {
                    "parameter_longname": "pm[3]",
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-11::obj-65": {
                    "parameter_longname": "shape[4]"
                },
                "obj-11::obj-71": {
                    "parameter_longname": "phase[6]"
                },
                "obj-11::obj-72": {
                    "parameter_longname": "phase_time_switch[3]"
                },
                "obj-12::obj-10": {
                    "parameter_longname": "bias[4]"
                },
                "obj-12::obj-14": {
                    "parameter_longname": "bm[4]"
                },
                "obj-12::obj-17": {
                    "parameter_longname": "live.menu[20]"
                },
                "obj-12::obj-22": {
                    "parameter_longname": "live.text[15]"
                },
                "obj-12::obj-29": {
                    "parameter_longname": "freq[4]"
                },
                "obj-12::obj-30": {
                    "parameter_longname": "angle[5]"
                },
                "obj-12::obj-42": {
                    "parameter_longname": "live.toggle[11]"
                },
                "obj-12::obj-47": {
                    "parameter_longname": "polarizer[4]"
                },
                "obj-12::obj-51": {
                    "parameter_longname": "live.menu[27]"
                },
                "obj-12::obj-53": {
                    "parameter_longname": "speed[4]"
                },
                "obj-12::obj-54": {
                    "parameter_longname": "morph[4]"
                },
                "obj-12::obj-6": {
                    "parameter_longname": "pm[4]",
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-12::obj-65": {
                    "parameter_longname": "shape[5]"
                },
                "obj-12::obj-71": {
                    "parameter_longname": "phase[7]"
                },
                "obj-12::obj-72": {
                    "parameter_longname": "phase_time_switch[4]"
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
                "obj-26::obj-32": {
                    "parameter_longname": "live.numbox[4]"
                },
                "obj-26::obj-45::obj-16": {
                    "parameter_longname": "live.menu[24]"
                },
                "obj-3::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-3::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_longname": "angle[4]",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-3::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-3::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-3::obj-32": {
                    "parameter_invisible": 0,
                    "parameter_longname": "regularity",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-3::obj-35": {
                    "parameter_invisible": 0,
                    "parameter_longname": "phase[4]",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-3::obj-38": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-3::obj-41": {
                    "parameter_invisible": 0,
                    "parameter_longname": "shape",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-3::obj-44": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-3::obj-47": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-3::obj-50": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-3::obj-53": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-3::obj-56": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-3::obj-59": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 0,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-5::obj-6": {
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-5::obj-65": {
                    "parameter_longname": "shape[1]"
                },
                "obj-6::obj-10": {
                    "parameter_longname": "bias[1]"
                },
                "obj-6::obj-14": {
                    "parameter_longname": "bm[1]"
                },
                "obj-6::obj-17": {
                    "parameter_longname": "live.menu[43]"
                },
                "obj-6::obj-22": {
                    "parameter_longname": "live.text[12]"
                },
                "obj-6::obj-29": {
                    "parameter_longname": "freq[1]"
                },
                "obj-6::obj-30": {
                    "parameter_longname": "angle[1]"
                },
                "obj-6::obj-42": {
                    "parameter_longname": "live.toggle[10]"
                },
                "obj-6::obj-47": {
                    "parameter_longname": "polarizer[1]"
                },
                "obj-6::obj-51": {
                    "parameter_longname": "live.menu[42]"
                },
                "obj-6::obj-53": {
                    "parameter_longname": "speed[1]"
                },
                "obj-6::obj-54": {
                    "parameter_longname": "morph[1]"
                },
                "obj-6::obj-6": {
                    "parameter_longname": "pm[1]",
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-6::obj-65": {
                    "parameter_longname": "shape[2]"
                },
                "obj-6::obj-71": {
                    "parameter_longname": "phase[1]"
                },
                "obj-6::obj-72": {
                    "parameter_longname": "phase_time_switch[1]"
                },
                "obj-9::obj-10": {
                    "parameter_longname": "bias[2]"
                },
                "obj-9::obj-14": {
                    "parameter_longname": "bm[2]"
                },
                "obj-9::obj-17": {
                    "parameter_longname": "live.menu[26]"
                },
                "obj-9::obj-22": {
                    "parameter_longname": "live.text[13]"
                },
                "obj-9::obj-29": {
                    "parameter_longname": "freq[2]"
                },
                "obj-9::obj-30": {
                    "parameter_longname": "angle[2]"
                },
                "obj-9::obj-42": {
                    "parameter_longname": "live.toggle[3]"
                },
                "obj-9::obj-47": {
                    "parameter_longname": "polarizer[2]"
                },
                "obj-9::obj-51": {
                    "parameter_longname": "live.menu[25]"
                },
                "obj-9::obj-53": {
                    "parameter_longname": "speed[2]"
                },
                "obj-9::obj-54": {
                    "parameter_longname": "morph[2]"
                },
                "obj-9::obj-6": {
                    "parameter_longname": "pm[2]",
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-9::obj-65": {
                    "parameter_longname": "shape[3]"
                },
                "obj-9::obj-71": {
                    "parameter_longname": "phase[5]"
                },
                "obj-9::obj-72": {
                    "parameter_longname": "phase_time_switch[2]"
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