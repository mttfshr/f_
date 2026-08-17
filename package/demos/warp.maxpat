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
        "rect": [ 69.0, 95.0, 1329.0, 922.0 ],
        "boxes": [
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
                    "name": "vsc_presets.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "" ],
                    "patching_rect": [ 889.99609375, 580.515625, 170.0, 144.5 ],
                    "varname": "vs_presets",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "autorestore": "warp.json",
                    "hidden": 1,
                    "id": "obj-10",
                    "linecount": 2,
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 889.99609375, 667.515625, 138.0, 35.0 ],
                    "presentation_linecount": 2,
                    "priority": {
                        "vs_wfg_polarizer[1]::pm_range": -1,
                        "vs_wfg_polarizer[1]::lock_freq": -1
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
                    "id": "obj-35",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_wfg_av.maxpat",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "signal" ],
                    "patching_rect": [ 345.0, 3.0, 184.0, 98.0 ],
                    "varname": "vs_wfg_av",
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
                    "id": "obj-27",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_lens.maxpat",
                    "numinlets": 5,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 275.0, 333.0, 175.0, 155.0 ],
                    "varname": "f_lens[1]",
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
                    "name": "vs_filter_temp.maxpat",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 516.0, 278.0, 79.0, 71.0 ],
                    "varname": "vs_filter_temp",
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
                    "id": "obj-25",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_vf_warp.maxpat",
                    "numinlets": 2,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 125.0, 451.0, 119.0, 90.0 ],
                    "varname": "f_vf_warp",
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
                    "name": "f_grain.maxpat",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 209.0, 144.0, 227.0, 164.0 ],
                    "varname": "f_grain[1]",
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
                    "name": "f_grain.maxpat",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 676.0, 216.0, 227.0, 164.0 ],
                    "varname": "f_grain",
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
                    "patching_rect": [ 574.0, 51.0, 220.0, 132.0 ],
                    "varname": "vs_wfg_polarizer[1]",
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
                    "id": "obj-17",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_vf_fieldmap.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 495.0, 390.0, 126.0, 92.0 ],
                    "varname": "f_vf_fieldmap[1]",
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
                    "name": "f_lens.maxpat",
                    "numinlets": 5,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 119.0, 597.0, 175.0, 155.0 ],
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
                    "id": "obj-5",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_preview.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 398.0, 577.0, 262.0, 272.0 ],
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 0,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 1,
                    "enablevscroll": 0,
                    "id": "obj-8",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_modules.maxpat",
                    "numinlets": 0,
                    "numoutlets": 0,
                    "offset": [ 0.0, 0.0 ],
                    "patching_rect": [ 9.0, 367.0, 99.0, 250.0 ],
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
                    "patching_rect": [ 155.0, 762.0, 157.0, 22.0 ],
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
                    "id": "obj-2",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_render.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "" ],
                    "patching_rect": [ 100.0, 12.0, 96.85526317358028, 146.5 ],
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
                    "patching_rect": [ 15.0, 12.0, 79.0, 316.0 ],
                    "viewvisibility": 1
                }
            }
        ],
        "lines": [
            {
                "patchline": {
                    "destination": [ "obj-3", 0 ],
                    "source": [ "obj-16", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-27", 0 ],
                    "source": [ "obj-17", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-22", 0 ],
                    "source": [ "obj-18", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-16", 4 ],
                    "source": [ "obj-22", 2 ]
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
                    "destination": [ "obj-26", 0 ],
                    "source": [ "obj-23", 2 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-16", 0 ],
                    "source": [ "obj-25", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-17", 0 ],
                    "source": [ "obj-26", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-25", 1 ],
                    "source": [ "obj-27", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-23", 0 ],
                    "source": [ "obj-35", 0 ]
                }
            },
            {
                "patchline": {
                    "color": [ 0.65, 0.65, 0.65, 0.0 ],
                    "destination": [ "obj-10", 0 ],
                    "hidden": 1,
                    "source": [ "obj-4", 0 ]
                }
            }
        ],
        "parameters": {
            "obj-16::obj-19d": [ "panel_toggle", "panel_toggle", 0 ],
            "obj-16::obj-20": [ "aberration", "aberration", 0 ],
            "obj-16::obj-23": [ "tilt", "distortion", 0 ],
            "obj-16::obj-26": [ "slope", "transmission", 0 ],
            "obj-16::obj-29": [ "aberration_mod", "aberration_mod", 0 ],
            "obj-16::obj-300": [ "range_aberration", "range_aberration", 0 ],
            "obj-16::obj-310": [ "range_distortion", "range_distortion", 0 ],
            "obj-16::obj-32": [ "distortion_mod", "distortion_mod", 0 ],
            "obj-16::obj-320": [ "range_transmission", "range_transmission", 0 ],
            "obj-16::obj-35": [ "transmission_mod", "transmission_mod", 0 ],
            "obj-16::obj-38": [ "surface_mod", "surface_mod", 0 ],
            "obj-16::obj-390": [ "range_ghost_spacing", "range_ghost_spacing", 0 ],
            "obj-16::obj-41": [ "ghost", "ghost", 0 ],
            "obj-16::obj-44": [ "ghost_count", "ghost_count", 0 ],
            "obj-16::obj-47": [ "ghost_spacing", "ghost_spacing", 0 ],
            "obj-16::obj-50": [ "halation", "halation", 0 ],
            "obj-16::obj-53": [ "halation_threshold", "halation_threshold", 0 ],
            "obj-17::obj-20": [ "strength[2]", "strength", 0 ],
            "obj-17::obj-23": [ "scale", "scale", 0 ],
            "obj-17::obj-28": [ "rotate", "rotate", 0 ],
            "obj-17::obj-31": [ "thresh", "thresh", 0 ],
            "obj-18::obj-10": [ "bias[1]", "Bias", 0 ],
            "obj-18::obj-14": [ "bm[1]", "BM", 0 ],
            "obj-18::obj-17": [ "live.menu[42]", "live.menu", 0 ],
            "obj-18::obj-22": [ "live.text[12]", "live.text", 0 ],
            "obj-18::obj-29": [ "freq[1]", "Freq", 0 ],
            "obj-18::obj-30": [ "angle[2]", "Angle", 0 ],
            "obj-18::obj-42": [ "live.toggle[2]", "live.toggle", 0 ],
            "obj-18::obj-47": [ "polarizer[1]", "Morph", 0 ],
            "obj-18::obj-51": [ "live.menu[19]", "live.menu", 0 ],
            "obj-18::obj-53": [ "speed[1]", "Speed", 0 ],
            "obj-18::obj-54": [ "morph[1]", "Morph", 0 ],
            "obj-18::obj-6": [ "pm[1]", "PM", 0 ],
            "obj-18::obj-65": [ "shape[1]", "Shape", 0 ],
            "obj-18::obj-71": [ "phase[2]", "Phase", 0 ],
            "obj-18::obj-72": [ "phase_time_switch[1]", "phase_time_switch", 0 ],
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
            "obj-22::obj-11": [ "density", "density", 0 ],
            "obj-22::obj-13": [ "amount", "amount", 0 ],
            "obj-22::obj-15": [ "persistence", "persistence", 0 ],
            "obj-22::obj-2": [ "fade", "fade", 0 ],
            "obj-22::obj-25": [ "size", "size", 0 ],
            "obj-22::obj-27": [ "size_var", "size_var", 0 ],
            "obj-22::obj-29": [ "shape[3]", "shape", 0 ],
            "obj-22::obj-31": [ "softness", "softness", 0 ],
            "obj-22::obj-37": [ "jitter", "jitter", 0 ],
            "obj-22::obj-40": [ "ch_diverge", "ch_diverge", 0 ],
            "obj-22::obj-43": [ "field", "field", 0 ],
            "obj-22::obj-60": [ "luma_gate", "luma_gate", 0 ],
            "obj-22::obj-63": [ "displace", "displace", 0 ],
            "obj-22::obj-71": [ "edge_mode_menu", "edge_mode_menu", 0 ],
            "obj-22::obj-82": [ "sv_seed", "sv_seed", 0 ],
            "obj-23::obj-11": [ "density[1]", "density", 0 ],
            "obj-23::obj-13": [ "amount[1]", "amount", 0 ],
            "obj-23::obj-15": [ "persistence[1]", "persistence", 0 ],
            "obj-23::obj-2": [ "fade[1]", "fade", 0 ],
            "obj-23::obj-25": [ "size[1]", "size", 0 ],
            "obj-23::obj-27": [ "size_var[1]", "size_var", 0 ],
            "obj-23::obj-29": [ "shape[4]", "shape", 0 ],
            "obj-23::obj-31": [ "softness[2]", "softness", 0 ],
            "obj-23::obj-37": [ "jitter[1]", "jitter", 0 ],
            "obj-23::obj-40": [ "ch_diverge[1]", "ch_diverge", 0 ],
            "obj-23::obj-43": [ "field[1]", "field", 0 ],
            "obj-23::obj-60": [ "luma_gate[1]", "luma_gate", 0 ],
            "obj-23::obj-63": [ "displace[1]", "displace", 0 ],
            "obj-23::obj-71": [ "edge_mode_menu[1]", "edge_mode_menu", 0 ],
            "obj-23::obj-82": [ "sv_seed[1]", "sv_seed", 0 ],
            "obj-25::obj-20": [ "strength", "strength", 0 ],
            "obj-26::obj-43": [ "temp_freq", "Cutoff", 0 ],
            "obj-27::obj-19d": [ "panel_toggle[1]", "panel_toggle", 0 ],
            "obj-27::obj-20": [ "aberration[1]", "aberration", 0 ],
            "obj-27::obj-23": [ "tilt[1]", "distortion", 0 ],
            "obj-27::obj-26": [ "slope[1]", "transmission", 0 ],
            "obj-27::obj-29": [ "aberration_mod[1]", "aberration_mod", 0 ],
            "obj-27::obj-300": [ "range_aberration[1]", "range_aberration", 0 ],
            "obj-27::obj-310": [ "range_distortion[1]", "range_distortion", 0 ],
            "obj-27::obj-32": [ "distortion_mod[1]", "distortion_mod", 0 ],
            "obj-27::obj-320": [ "range_transmission[1]", "range_transmission", 0 ],
            "obj-27::obj-35": [ "transmission_mod[1]", "transmission_mod", 0 ],
            "obj-27::obj-38": [ "surface_mod[1]", "surface_mod", 0 ],
            "obj-27::obj-390": [ "range_ghost_spacing[1]", "range_ghost_spacing", 0 ],
            "obj-27::obj-41": [ "ghost[1]", "ghost", 0 ],
            "obj-27::obj-44": [ "ghost_count[1]", "ghost_count", 0 ],
            "obj-27::obj-47": [ "ghost_spacing[1]", "ghost_spacing", 0 ],
            "obj-27::obj-50": [ "halation[1]", "halation", 0 ],
            "obj-27::obj-53": [ "halation_threshold[1]", "halation_threshold", 0 ],
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
            "obj-35::obj-11": [ "vs_audio_wfg_pw", "PW", 0 ],
            "obj-35::obj-137": [ "vs_audio_wfg_wf", "waveform", 0 ],
            "obj-35::obj-40": [ "vs_audio_wfg_depth", "Depth", 0 ],
            "obj-35::obj-41": [ "vs_audio_wfg_gain", "Gain", 0 ],
            "obj-35::obj-42": [ "vs_audio_wfg_ratio", "Ratio", 0 ],
            "obj-35::obj-9": [ "vs_audio_wfg_freq", "Freq", 0 ],
            "obj-3::obj-1": [ "toggle[1]", "toggle[1]", 0 ],
            "obj-3::obj-10": [ "toggle[3]", "toggle[2]", 0 ],
            "obj-3::obj-36": [ "uppr_x", "uppr_x", 0 ],
            "obj-4::obj-10": [ "textedit", "vs_preset_name", 0 ],
            "obj-4::obj-11": [ "live.text", "live.text", 0 ],
            "obj-4::obj-15": [ "live.tab", "live.tab", 0 ],
            "obj-4::obj-32": [ "live.numbox[4]", "live.numbox", 0 ],
            "obj-4::obj-44": [ "live.tab[3]", "live.tab", 0 ],
            "obj-4::obj-45::obj-16": [ "live.menu[18]", "live.menu[16]", 0 ],
            "obj-4::obj-45::obj-17": [ "live.button", "live.button", 0 ],
            "obj-4::obj-45::obj-19": [ "live.numbox[2]", "live.numbox[1]", 0 ],
            "obj-4::obj-45::obj-32": [ "live.numbox", "live.numbox", 0 ],
            "obj-4::obj-45::obj-9": [ "live.numbox[3]", "live.numbox", 0 ],
            "obj-8::obj-12": [ "f_module_1_disp", "live.menu", 0 ],
            "obj-8::obj-13": [ "f_module_1_file", "live.menu", 0 ],
            "obj-8::obj-16": [ "f_module_2_disp", "live.menu", 0 ],
            "obj-8::obj-17": [ "f_module_2_file", "live.menu", 0 ],
            "obj-8::obj-20": [ "f_module_3_disp", "live.menu", 0 ],
            "obj-8::obj-21": [ "f_module_3_file", "live.menu", 0 ],
            "obj-8::obj-24": [ "f_module_4_disp", "live.menu", 0 ],
            "obj-8::obj-25": [ "f_module_4_file", "live.menu", 0 ],
            "obj-8::obj-28": [ "f_module_5_disp", "live.menu", 0 ],
            "obj-8::obj-29": [ "f_module_5_file", "live.menu", 0 ],
            "obj-8::obj-32": [ "f_module_6_disp", "live.menu", 0 ],
            "obj-8::obj-33": [ "f_module_6_file", "live.menu", 0 ],
            "obj-8::obj-36": [ "f_module_7_disp", "live.menu", 0 ],
            "obj-8::obj-37": [ "f_module_7_file", "live.menu", 0 ],
            "obj-8::obj-8": [ "f_module_0_disp", "live.menu", 0 ],
            "obj-8::obj-9": [ "f_module_0_file", "live.menu", 0 ],
            "parameter_overrides": {
                "obj-16::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_range": [ -1.0, 1.0 ],
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-16::obj-23": {
                    "parameter_longname": "tilt",
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-16::obj-26": {
                    "parameter_longname": "slope",
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-16::obj-47": {
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-17::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_longname": "strength[2]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "strength",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-17::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_longname": "scale",
                    "parameter_modmode": 3,
                    "parameter_shortname": "scale",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-18::obj-10": {
                    "parameter_longname": "bias[1]"
                },
                "obj-18::obj-14": {
                    "parameter_longname": "bm[1]"
                },
                "obj-18::obj-17": {
                    "parameter_longname": "live.menu[42]"
                },
                "obj-18::obj-22": {
                    "parameter_longname": "live.text[12]"
                },
                "obj-18::obj-29": {
                    "parameter_longname": "freq[1]"
                },
                "obj-18::obj-30": {
                    "parameter_longname": "angle[2]"
                },
                "obj-18::obj-47": {
                    "parameter_longname": "polarizer[1]"
                },
                "obj-18::obj-51": {
                    "parameter_longname": "live.menu[19]"
                },
                "obj-18::obj-53": {
                    "parameter_longname": "speed[1]"
                },
                "obj-18::obj-54": {
                    "parameter_longname": "morph[1]"
                },
                "obj-18::obj-6": {
                    "parameter_longname": "pm[1]",
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-18::obj-65": {
                    "parameter_longname": "shape[1]"
                },
                "obj-18::obj-71": {
                    "parameter_longname": "phase[2]"
                },
                "obj-18::obj-72": {
                    "parameter_longname": "phase_time_switch[1]"
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
                "obj-22::obj-11": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-22::obj-13": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-22::obj-15": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-22::obj-2": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-22::obj-25": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-22::obj-27": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-22::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_longname": "shape[3]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "shape",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-22::obj-31": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-22::obj-37": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-22::obj-40": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-22::obj-43": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-22::obj-60": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-22::obj-63": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-22::obj-82": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-23::obj-11": {
                    "parameter_invisible": 0,
                    "parameter_longname": "density[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "density",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-23::obj-13": {
                    "parameter_invisible": 0,
                    "parameter_longname": "amount[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "amount",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-23::obj-15": {
                    "parameter_invisible": 0,
                    "parameter_longname": "persistence[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "persistence",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-23::obj-2": {
                    "parameter_invisible": 0,
                    "parameter_longname": "fade[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "fade",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-23::obj-25": {
                    "parameter_invisible": 0,
                    "parameter_longname": "size[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "size",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-23::obj-27": {
                    "parameter_invisible": 0,
                    "parameter_longname": "size_var[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "size_var",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-23::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_longname": "shape[4]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "shape",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-23::obj-31": {
                    "parameter_invisible": 0,
                    "parameter_longname": "softness[2]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "softness",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-23::obj-37": {
                    "parameter_invisible": 0,
                    "parameter_longname": "jitter[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "jitter",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-23::obj-40": {
                    "parameter_invisible": 0,
                    "parameter_longname": "ch_diverge[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "ch_diverge",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-23::obj-43": {
                    "parameter_invisible": 0,
                    "parameter_longname": "field[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "field",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-23::obj-60": {
                    "parameter_invisible": 0,
                    "parameter_longname": "luma_gate[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "luma_gate",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-23::obj-63": {
                    "parameter_invisible": 0,
                    "parameter_longname": "displace[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "displace",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-23::obj-82": {
                    "parameter_invisible": 0,
                    "parameter_longname": "sv_seed[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "sv_seed",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-25::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-27::obj-19d": {
                    "parameter_longname": "panel_toggle[1]"
                },
                "obj-27::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_longname": "aberration[1]",
                    "parameter_modmode": 3,
                    "parameter_range": [ -1.0, 1.0 ],
                    "parameter_shortname": "aberration",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-27::obj-23": {
                    "parameter_longname": "tilt[1]",
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-27::obj-26": {
                    "parameter_longname": "slope[1]",
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-27::obj-29": {
                    "parameter_longname": "aberration_mod[1]"
                },
                "obj-27::obj-300": {
                    "parameter_longname": "range_aberration[1]"
                },
                "obj-27::obj-310": {
                    "parameter_longname": "range_distortion[1]"
                },
                "obj-27::obj-32": {
                    "parameter_longname": "distortion_mod[1]"
                },
                "obj-27::obj-320": {
                    "parameter_longname": "range_transmission[1]"
                },
                "obj-27::obj-35": {
                    "parameter_longname": "transmission_mod[1]"
                },
                "obj-27::obj-38": {
                    "parameter_longname": "surface_mod[1]"
                },
                "obj-27::obj-390": {
                    "parameter_longname": "range_ghost_spacing[1]"
                },
                "obj-27::obj-41": {
                    "parameter_longname": "ghost[1]"
                },
                "obj-27::obj-44": {
                    "parameter_longname": "ghost_count[1]"
                },
                "obj-27::obj-47": {
                    "parameter_longname": "ghost_spacing[1]",
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-27::obj-50": {
                    "parameter_longname": "halation[1]"
                },
                "obj-27::obj-53": {
                    "parameter_longname": "halation_threshold[1]"
                },
                "obj-4::obj-32": {
                    "parameter_longname": "live.numbox[4]"
                },
                "obj-4::obj-45::obj-16": {
                    "parameter_longname": "live.menu[18]"
                }
            },
            "inherited_shortname": 1
        },
        "autosave": 0,
        "boxgroups": [
            {
                "boxes": [ "obj-4", "obj-10" ]
            }
        ]
    }
}