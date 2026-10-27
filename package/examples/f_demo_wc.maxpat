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
        "rect": [ 148.0, 95.0, 983.0, 869.0 ],
        "boxes": [
            {
                "box": {
                    "bgmode": 1,
                    "border": 1,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-59",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_huemod_2.maxpat",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 584.0, 580.0, 144.0, 75.0 ],
                    "varname": "vs_huemod_2",
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
                    "id": "obj-47",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_preview.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 59.0, 732.0, 112.0, 102.02620087336243 ],
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
                    "id": "obj-42",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_cos_palettes.maxpat",
                    "numinlets": 2,
                    "numoutlets": 3,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 507.0, 524.0, 113.0, 44.13157894736841 ],
                    "varname": "vs_cos_palettes",
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
                    "id": "obj-41",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_filter_temp.maxpat",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 752.0, 599.0, 79.0, 71.0 ],
                    "varname": "vs_filter_temp",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "id": "obj-35",
                    "maxclass": "newobj",
                    "numinlets": 6,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 507.0, 302.0, 97.0, 22.0 ],
                    "text": "scale 0 127 0. 1."
                }
            },
            {
                "box": {
                    "id": "obj-34",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 249.0, 302.0, 49.0, 22.0 ],
                    "text": "amp $1"
                }
            },
            {
                "box": {
                    "bgmode": 0,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-33",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "upshot_pitchdetection.maxpat",
                    "numinlets": 2,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "", "bang" ],
                    "patching_rect": [ 668.265625, 230.546875, 118.0, 86.0 ],
                    "varname": "upshot_pitch_detection",
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
                    "id": "obj-32",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "upshot_amplitudefollower.maxpat",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "" ],
                    "patching_rect": [ 473.0, 186.5, 119.0, 96.0 ],
                    "varname": "upshot_envelopefollower",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "id": "obj-28",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 316.0, 302.0, 49.0, 22.0 ],
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
                    "patching_rect": [ 403.0, 126.0, 22.0, 140.0 ]
                }
            },
            {
                "box": {
                    "id": "obj-24",
                    "maxclass": "ezadc~",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "signal", "signal" ],
                    "patching_rect": [ 384.0, 36.0, 45.0, 45.0 ]
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
                    "name": "f_chladni.maxpat",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 265.0, 366.0, 231.0, 171.0 ],
                    "varname": "f_chladni",
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
                    "id": "obj-12",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_caustic.maxpat",
                    "numinlets": 2,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 535.0, 690.0, 227.0, 122.0 ],
                    "varname": "f_caustic",
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
                    "patching_rect": [ 233.0, 44.0, 96.85526317358028, 146.5 ],
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
                    "name": "f_wave_field.maxpat",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 215.0, 580.0, 190.5, 232.0 ],
                    "varname": "f_wave_field",
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
                    "patching_rect": [ 491.0, 15.0, 220.0, 132.0 ],
                    "varname": "vs_wfg_polarizer[1]",
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
                    "patching_rect": [ 113.0, 22.0, 101.0, 425.0 ],
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
                    "patching_rect": [ 26.0, 465.0, 170.0, 144.5 ],
                    "varname": "vs_presets",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "autorestore": "f_demo_wc.json",
                    "hidden": 1,
                    "id": "obj-10",
                    "linecount": 2,
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 26.0, 552.0, 138.0, 35.0 ],
                    "priority": {
                        "vs_wfg_polarizer[1]::pm_range": -1,
                        "vs_wfg_polarizer[1]::lock_freq": -1,
                        "vs_camera_fm::cam2_scale_freq_x": -1,
                        "vs_camera_fm::can2_scale_freq_y": -1,
                        "vs_lfo::lfo_freq_range": -1,
                        "vs_huemod_2::hm2_sat_range": -1,
                        "vs_huemod_2::hm2_range": -1
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
                    "id": "obj-3",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_output.maxpat",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "offset": [ 0.0, 0.0 ],
                    "patching_rect": [ 681.0, 828.0, 157.0, 22.0 ],
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
                    "patching_rect": [ 26.0, 22.0, 79.0, 316.0 ],
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
                    "destination": [ "obj-3", 0 ],
                    "source": [ "obj-12", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-42", 0 ],
                    "order": 0,
                    "source": [ "obj-23", 2 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-7", 0 ],
                    "order": 1,
                    "source": [ "obj-23", 2 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-25", 0 ],
                    "source": [ "obj-24", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-25", 0 ],
                    "source": [ "obj-24", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-32", 0 ],
                    "order": 1,
                    "source": [ "obj-25", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-33", 0 ],
                    "order": 0,
                    "source": [ "obj-25", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-23", 0 ],
                    "source": [ "obj-28", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-35", 0 ],
                    "source": [ "obj-32", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-28", 0 ],
                    "source": [ "obj-33", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-23", 0 ],
                    "source": [ "obj-34", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-34", 0 ],
                    "source": [ "obj-35", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-12", 0 ],
                    "source": [ "obj-41", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-59", 0 ],
                    "source": [ "obj-42", 2 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-41", 0 ],
                    "source": [ "obj-59", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-23", 0 ],
                    "source": [ "obj-6", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-12", 1 ],
                    "order": 0,
                    "source": [ "obj-7", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-47", 0 ],
                    "order": 1,
                    "source": [ "obj-7", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-59", 1 ],
                    "source": [ "obj-7", 0 ]
                }
            }
        ],
        "parameters": {
            "obj-12::obj-20": [ "mix_pct", "mix_pct", 0 ],
            "obj-12::obj-23": [ "gain[1]", "gain", 0 ],
            "obj-12::obj-26": [ "scale[1]", "scale", 0 ],
            "obj-12::obj-29": [ "expo", "expo", 0 ],
            "obj-12::obj-310": [ "range_gain", "range_gain", 0 ],
            "obj-12::obj-32": [ "edge[1]", "edge", 0 ],
            "obj-12::obj-320": [ "range_scale", "range_scale", 0 ],
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
            "obj-23::obj-20": [ "note", "note", 0 ],
            "obj-23::obj-23": [ "amp", "amp", 0 ],
            "obj-23::obj-26": [ "dishradius", "dishradius", 0 ],
            "obj-23::obj-29": [ "reflectamt", "reflectamt", 0 ],
            "obj-23::obj-32": [ "linesharpness", "linesharpness", 0 ],
            "obj-23::obj-35": [ "ph0", "ph0", 0 ],
            "obj-23::obj-38": [ "spread", "spread", 0 ],
            "obj-23::obj-41": [ "mode[1]", "mode", 0 ],
            "obj-23::obj-44": [ "view_mode", "view_mode", 0 ],
            "obj-23::obj-47": [ "gain[4]", "gain", 0 ],
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
            "obj-32::obj-542": [ "input volume", "vol", 0 ],
            "obj-32::obj-74": [ "envelope output", "output", 0 ],
            "obj-32::obj-8": [ "smoothing", "smooth", 0 ],
            "obj-33::obj-34": [ "live.text[8]", "live.text", 0 ],
            "obj-3::obj-1": [ "toggle[3]", "toggle[1]", 0 ],
            "obj-3::obj-10": [ "toggle[4]", "toggle[2]", 0 ],
            "obj-3::obj-36": [ "uppr_x[1]", "uppr_x", 0 ],
            "obj-41::obj-43": [ "temp_freq", "Cutoff", 0 ],
            "obj-42::obj-13": [ "vs_cp_menu", "live.menu", 0 ],
            "obj-42::obj-26": [ "live.arrows[1]", "live.arrows", 0 ],
            "obj-42::obj-8": [ "vs_cp_mode", "Mode", 0 ],
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
            "obj-4::obj-40": [ "f_module_8_disp", "live.menu", 0 ],
            "obj-4::obj-41": [ "f_module_8_file", "live.menu", 0 ],
            "obj-4::obj-44": [ "f_module_9_disp", "live.menu", 0 ],
            "obj-4::obj-45": [ "f_module_9_file", "live.menu", 0 ],
            "obj-4::obj-8": [ "f_module_0_disp", "live.menu", 0 ],
            "obj-4::obj-9": [ "f_module_0_file", "live.menu", 0 ],
            "obj-59::obj-23": [ "live.menu[45]", "live.menu", 0 ],
            "obj-59::obj-39": [ "hm2_hm", "HM", 0 ],
            "obj-59::obj-46": [ "hm2_hue", "Hue", 0 ],
            "obj-59::obj-48": [ "hm2_sat", "Sat", 0 ],
            "obj-59::obj-5": [ "live.menu[44]", "live.menu", 0 ],
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
            "obj-6::obj-10": [ "bias[1]", "Bias", 0 ],
            "obj-6::obj-14": [ "bm[1]", "BM", 0 ],
            "obj-6::obj-17": [ "live.menu[42]", "live.menu", 0 ],
            "obj-6::obj-22": [ "live.text[7]", "live.text", 0 ],
            "obj-6::obj-29": [ "freq[1]", "Freq", 0 ],
            "obj-6::obj-30": [ "angle[1]", "Angle", 0 ],
            "obj-6::obj-42": [ "live.toggle[3]", "live.toggle", 0 ],
            "obj-6::obj-47": [ "polarizer[1]", "Morph", 0 ],
            "obj-6::obj-51": [ "live.menu[43]", "live.menu", 0 ],
            "obj-6::obj-53": [ "speed", "Speed", 0 ],
            "obj-6::obj-54": [ "morph[1]", "Morph", 0 ],
            "obj-6::obj-6": [ "pm[1]", "PM", 0 ],
            "obj-6::obj-65": [ "shape[1]", "Shape", 0 ],
            "obj-6::obj-71": [ "phase[1]", "Phase", 0 ],
            "obj-6::obj-72": [ "phase_time_switch[1]", "phase_time_switch", 0 ],
            "obj-7::obj-20": [ "speed[1]", "speed", 0 ],
            "obj-7::obj-23": [ "damping", "damping", 0 ],
            "obj-7::obj-26": [ "dispersion", "dispersion", 0 ],
            "obj-7::obj-29": [ "ring", "ring", 0 ],
            "obj-7::obj-32": [ "edge", "edge", 0 ],
            "obj-7::obj-35": [ "exc_x", "exc_x", 0 ],
            "obj-7::obj-38": [ "exc_y", "exc_y", 0 ],
            "obj-7::obj-41": [ "frequency", "frequency", 0 ],
            "obj-7::obj-44": [ "amplitude", "amplitude", 0 ],
            "obj-7::obj-47": [ "force", "force", 0 ],
            "obj-7::obj-50": [ "gain", "gain", 0 ],
            "parameterbanks": {
                "0": {
                    "index": 0,
                    "name": "",
                    "parameters": [ "-", "-", "-", "-", "-", "-", "-", "-" ],
                    "buttons": [ "-", "-", "-", "-", "-", "-", "-", "-" ]
                }
            },
            "parameter_overrides": {
                "obj-12::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-12::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_longname": "gain[1]",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-12::obj-26": {
                    "parameter_longname": "scale[1]",
                    "parameter_range": [ 0.0, 1.0 ]
                },
                "obj-12::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-12::obj-32": {
                    "parameter_longname": "edge[1]"
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
                    "parameter_modmode": 3,
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
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-23::obj-38": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-23::obj-41": {
                    "parameter_invisible": 0,
                    "parameter_longname": "mode[1]",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-23::obj-44": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-23::obj-47": {
                    "parameter_invisible": 0,
                    "parameter_longname": "gain[4]",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
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
                "obj-33::obj-34": {
                    "parameter_longname": "live.text[8]"
                },
                "obj-59::obj-23": {
                    "parameter_longname": "live.menu[45]"
                },
                "obj-59::obj-39": {
                    "parameter_range": [ -3.0, 3.0 ]
                },
                "obj-59::obj-48": {
                    "parameter_range": [ -2.0, 2.0 ]
                },
                "obj-59::obj-5": {
                    "parameter_longname": "live.menu[44]"
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
                "obj-6::obj-10": {
                    "parameter_longname": "bias[1]"
                },
                "obj-6::obj-14": {
                    "parameter_longname": "bm[1]"
                },
                "obj-6::obj-17": {
                    "parameter_longname": "live.menu[42]"
                },
                "obj-6::obj-22": {
                    "parameter_longname": "live.text[7]"
                },
                "obj-6::obj-29": {
                    "parameter_longname": "freq[1]"
                },
                "obj-6::obj-30": {
                    "parameter_longname": "angle[1]"
                },
                "obj-6::obj-42": {
                    "parameter_longname": "live.toggle[3]"
                },
                "obj-6::obj-47": {
                    "parameter_longname": "polarizer[1]"
                },
                "obj-6::obj-51": {
                    "parameter_longname": "live.menu[43]"
                },
                "obj-6::obj-54": {
                    "parameter_longname": "morph[1]"
                },
                "obj-6::obj-6": {
                    "parameter_longname": "pm[1]",
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-6::obj-65": {
                    "parameter_longname": "shape[1]"
                },
                "obj-6::obj-71": {
                    "parameter_longname": "phase[1]"
                },
                "obj-6::obj-72": {
                    "parameter_longname": "phase_time_switch[1]"
                },
                "obj-7::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_longname": "speed[1]",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-7::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-7::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-7::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-7::obj-35": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-7::obj-38": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-7::obj-41": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-7::obj-44": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-7::obj-47": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-7::obj-50": {
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