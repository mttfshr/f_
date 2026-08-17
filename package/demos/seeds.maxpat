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
        "rect": [ 61.0, 95.0, 1001.0, 851.0 ],
        "boxes": [
            {
                "box": {
                    "bgmode": 1,
                    "border": 1,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-14",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vsc_presets.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "" ],
                    "patching_rect": [ 779.91015625, 555.1484375, 170.0, 144.5 ],
                    "varname": "vs_presets",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "autorestore": "seeds.json",
                    "hidden": 1,
                    "id": "obj-10",
                    "linecount": 2,
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 779.91015625, 642.1484375, 138.0, 35.0 ],
                    "presentation_linecount": 2,
                    "priority": {
                        "vs_wfg_polarizer::pm_range": -1,
                        "vs_wfg_polarizer::lock_freq": -1,
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
                    "varname": "seeds"
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
                    "patching_rect": [ 447.0, 14.0, 220.0, 132.0 ],
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
                    "id": "obj-12",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_blendmode_mixer.maxpat",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 234.0, 605.0, 115.0, 94.0 ],
                    "varname": "vs_blendmode_mixer",
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
                    "name": "f_vf_fieldmap.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 261.0, 180.0, 154.0, 99.0 ],
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
                    "id": "obj-5",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_preview.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 437.0, 577.0, 230.0, 206.0 ],
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
                    "id": "obj-25",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_wfg_polarizer.maxpat",
                    "numinlets": 2,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 219.0, 14.0, 220.0, 132.0 ],
                    "varname": "vs_wfg_polarizer",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "annotation": "## A Basis Function-based video generator ##",
                    "bgmode": 1,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-20",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vz.bfgener8r.maxpat",
                    "numinlets": 12,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 685.0, 40.0, 268.0, 234.0 ],
                    "prototypename": "pixl",
                    "varname": "bfgener8r",
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
                    "id": "obj-24",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_preview.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 697.0, 287.0, 112.0, 102.02620087336243 ],
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
                    "name": "f_vf_seeds.maxpat",
                    "numinlets": 4,
                    "numoutlets": 3,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 228.0, 356.0, 195.0, 211.0 ],
                    "varname": "f_vf_seeds",
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
                    "patching_rect": [ 25.0, 339.0, 103.0, 389.0 ],
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
                    "patching_rect": [ 158.0, 806.0, 157.0, 22.0 ],
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
                    "destination": [ "obj-4", 0 ],
                    "source": [ "obj-12", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-25", 0 ],
                    "source": [ "obj-13", 0 ]
                }
            },
            {
                "patchline": {
                    "color": [ 0.65, 0.65, 0.65, 0.0 ],
                    "destination": [ "obj-10", 0 ],
                    "hidden": 1,
                    "source": [ "obj-14", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-12", 0 ],
                    "source": [ "obj-18", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 0 ],
                    "source": [ "obj-18", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-12", 1 ],
                    "order": 2,
                    "source": [ "obj-20", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-18", 3 ],
                    "order": 0,
                    "source": [ "obj-20", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-18", 2 ],
                    "order": 1,
                    "source": [ "obj-20", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-24", 0 ],
                    "order": 4,
                    "source": [ "obj-20", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-9", 0 ],
                    "order": 3,
                    "source": [ "obj-20", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-18", 0 ],
                    "source": [ "obj-25", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-18", 1 ],
                    "source": [ "obj-9", 0 ]
                }
            }
        ],
        "parameters": {
            "obj-12::obj-1": [ "bm_master", "Master", 0 ],
            "obj-12::obj-26": [ "live.arrows", "live.arrows", 0 ],
            "obj-12::obj-27": [ "bm_mode", "live.menu", 0 ],
            "obj-12::obj-94": [ "bm_ch1", "In 1", 0 ],
            "obj-12::obj-98": [ "bm_ch2", "In 2", 0 ],
            "obj-13::obj-10": [ "bias[1]", "Bias", 0 ],
            "obj-13::obj-14": [ "bm[1]", "BM", 0 ],
            "obj-13::obj-17": [ "live.menu[18]", "live.menu", 0 ],
            "obj-13::obj-22": [ "live.text[12]", "live.text", 0 ],
            "obj-13::obj-29": [ "freq[1]", "Freq", 0 ],
            "obj-13::obj-30": [ "angle[1]", "Angle", 0 ],
            "obj-13::obj-42": [ "live.toggle[3]", "live.toggle", 0 ],
            "obj-13::obj-47": [ "polarizer[1]", "Morph", 0 ],
            "obj-13::obj-51": [ "live.menu[19]", "live.menu", 0 ],
            "obj-13::obj-53": [ "speed[1]", "Speed", 0 ],
            "obj-13::obj-54": [ "morph[1]", "Morph", 0 ],
            "obj-13::obj-6": [ "pm[1]", "PM", 0 ],
            "obj-13::obj-65": [ "shape[1]", "Shape", 0 ],
            "obj-13::obj-71": [ "phase[2]", "Phase", 0 ],
            "obj-13::obj-72": [ "phase_time_switch[1]", "phase_time_switch", 0 ],
            "obj-14::obj-10": [ "textedit", "vs_preset_name", 0 ],
            "obj-14::obj-11": [ "live.text", "live.text", 0 ],
            "obj-14::obj-15": [ "live.tab", "live.tab", 0 ],
            "obj-14::obj-32": [ "live.numbox[4]", "live.numbox", 0 ],
            "obj-14::obj-44": [ "live.tab[3]", "live.tab", 0 ],
            "obj-14::obj-45::obj-16": [ "live.menu[42]", "live.menu[16]", 0 ],
            "obj-14::obj-45::obj-17": [ "live.button", "live.button", 0 ],
            "obj-14::obj-45::obj-19": [ "live.numbox[2]", "live.numbox[1]", 0 ],
            "obj-14::obj-45::obj-32": [ "live.numbox", "live.numbox", 0 ],
            "obj-14::obj-45::obj-9": [ "live.numbox[3]", "live.numbox", 0 ],
            "obj-18::obj-200": [ "density", "density", 0 ],
            "obj-18::obj-203": [ "jitter", "jitter", 0 ],
            "obj-18::obj-206": [ "size", "size", 0 ],
            "obj-18::obj-209": [ "stretch", "stretch", 0 ],
            "obj-18::obj-212": [ "strength", "strength", 0 ],
            "obj-18::obj-215": [ "mag_weight", "mag_weight", 0 ],
            "obj-18::obj-218": [ "field_priority", "field_priority", 0 ],
            "obj-18::obj-221": [ "field_gain", "field_gain", 0 ],
            "obj-18::obj-224": [ "bomb", "bomb", 0 ],
            "obj-18::obj-227": [ "phase", "phase", 0 ],
            "obj-18::obj-230": [ "size_mod", "size_mod", 0 ],
            "obj-18::obj-233": [ "stretch_mod", "stretch_mod", 0 ],
            "obj-18::obj-236": [ "hue_a", "hue_a", 0 ],
            "obj-18::obj-470": [ "range_field_gain", "range_field_gain", 0 ],
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
            "obj-20::obj-100": [ "Speed", "Speed", 1 ],
            "obj-20::obj-104": [ "pictctrl[148]", "pictctrl[1]", 0 ],
            "obj-20::obj-15": [ "pictctrl[34]", "pictctrl[1]", 0 ],
            "obj-20::obj-17": [ "pictctrl[31]", "pictctrl[1]", 0 ],
            "obj-20::obj-21": [ "Colorize", "Colorize", 0 ],
            "obj-20::obj-23": [ "pictctrl[33]", "pictctrl[1]", 0 ],
            "obj-20::obj-26": [ "pictctrl[32]", "pictctrl[1]", 0 ],
            "obj-20::obj-278": [ "textbutton[3]", "textbutton[1]", 0 ],
            "obj-20::obj-37": [ "pictctrl[28]", "pictctrl[1]", 0 ],
            "obj-20::obj-46": [ "pictctrl[27]", "pictctrl[1]", 0 ],
            "obj-20::obj-5": [ "Function", "Function", 0 ],
            "obj-20::obj-55": [ "Bcolorize", "Bcolorize", 0 ],
            "obj-20::obj-56": [ "Gcolorize", "Gcolorize", 0 ],
            "obj-20::obj-57": [ "Rcolorize", "Rcolorize", 0 ],
            "obj-20::obj-59": [ "pictctrl[106]", "pictctrl[1]", 0 ],
            "obj-20::obj-61": [ "Zoom hi", "Zoom", 1 ],
            "obj-20::obj-63": [ "Zoom range[2]", "Zoom range", 1 ],
            "obj-20::obj-76": [ "pictctrl[29]", "pictctrl[1]", 0 ],
            "obj-20::obj-78": [ "Zoom lo", "Zoom", 1 ],
            "obj-20::obj-8": [ "pictctrl[30]", "pictctrl[1]", 0 ],
            "obj-20::obj-85": [ "pictctrl[4]", "pictctrl[1]", 0 ],
            "obj-20::obj-91::obj-10::obj-11": [ "Jitter[2]", "Jitter", 0 ],
            "obj-20::obj-91::obj-10::obj-19": [ "Amount", "Amount", 0 ],
            "obj-20::obj-91::obj-11::obj-11": [ "Jitter[1]", "Jitter", 0 ],
            "obj-20::obj-91::obj-11::obj-18": [ "Smoothing", "Smoothing", 0 ],
            "obj-20::obj-91::obj-12::obj-23": [ "Gain[3]", "Gain", 0 ],
            "obj-20::obj-91::obj-12::obj-25": [ "Offset[3]", "Offset", 0 ],
            "obj-20::obj-91::obj-12::obj-27": [ "Lacunarity[3]", "Lacunarity", 0 ],
            "obj-20::obj-91::obj-12::obj-31": [ "H value[3]", "H value", 0 ],
            "obj-20::obj-91::obj-13::obj-11": [ "Jitter", "Jitter", 0 ],
            "obj-20::obj-91::obj-15::obj-11": [ "H value[4]", "H value", 0 ],
            "obj-20::obj-91::obj-15::obj-16": [ "Lacunarity[4]", "Lacunarity", 0 ],
            "obj-20::obj-91::obj-15::obj-18": [ "Offset[4]", "Offset", 0 ],
            "obj-20::obj-91::obj-15::obj-19": [ "Gain[4]", "Gain", 0 ],
            "obj-20::obj-91::obj-1::obj-24": [ "Gain", "Gain", 0 ],
            "obj-20::obj-91::obj-1::obj-26": [ "Offset", "Offset", 0 ],
            "obj-20::obj-91::obj-1::obj-28": [ "Lacunarity", "Lacunarity", 0 ],
            "obj-20::obj-91::obj-1::obj-32": [ "H value", "H value", 0 ],
            "obj-20::obj-91::obj-3::obj-11": [ "Distortion", "Distortion", 0 ],
            "obj-20::obj-91::obj-4::obj-24": [ "Gain[1]", "Gain", 0 ],
            "obj-20::obj-91::obj-4::obj-26": [ "Offset[1]", "Offset", 0 ],
            "obj-20::obj-91::obj-4::obj-28": [ "Lacunarity[1]", "Lacunarity", 0 ],
            "obj-20::obj-91::obj-4::obj-32": [ "H value[1]", "H value", 0 ],
            "obj-20::obj-91::obj-5::obj-23": [ "Gain[2]", "Gain", 0 ],
            "obj-20::obj-91::obj-5::obj-25": [ "Offset[2]", "Offset", 0 ],
            "obj-20::obj-91::obj-5::obj-27": [ "Lacunarity[2]", "Lacunarity", 0 ],
            "obj-20::obj-91::obj-5::obj-31": [ "H value[2]", "H value", 0 ],
            "obj-20::obj-91::obj-6::obj-11": [ "Jitter[4]", "Jitter", 0 ],
            "obj-20::obj-91::obj-6::obj-24": [ "X crackle", "X crackle", 0 ],
            "obj-20::obj-91::obj-6::obj-28": [ "Y crackle", "Y crackle", 0 ],
            "obj-20::obj-91::obj-6::obj-29": [ "Z crackle", "Z crackle", 0 ],
            "obj-20::obj-91::obj-9::obj-11": [ "Jitter[3]", "Jitter", 0 ],
            "obj-20::obj-91::obj-9::obj-16": [ "Shading", "Shading", 0 ],
            "obj-20::obj-96": [ "pictctrl[35]", "pictctrl[1]", 0 ],
            "obj-25::obj-10": [ "bias", "Bias", 0 ],
            "obj-25::obj-14": [ "bm", "BM", 0 ],
            "obj-25::obj-17": [ "live.menu[41]", "live.menu", 0 ],
            "obj-25::obj-22": [ "live.text[3]", "live.text", 0 ],
            "obj-25::obj-29": [ "freq", "Freq", 0 ],
            "obj-25::obj-30": [ "angle", "Angle", 0 ],
            "obj-25::obj-42": [ "live.toggle[2]", "live.toggle", 0 ],
            "obj-25::obj-47": [ "polarizer", "Morph", 0 ],
            "obj-25::obj-51": [ "live.menu[40]", "live.menu", 0 ],
            "obj-25::obj-53": [ "speed", "Speed", 0 ],
            "obj-25::obj-54": [ "morph", "Morph", 0 ],
            "obj-25::obj-6": [ "pm", "PM", 0 ],
            "obj-25::obj-65": [ "shape", "Shape", 0 ],
            "obj-25::obj-71": [ "phase[1]", "Phase", 0 ],
            "obj-25::obj-72": [ "phase_time_switch", "phase_time_switch", 0 ],
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
            "obj-9::obj-20": [ "gain", "gain", 0 ],
            "obj-9::obj-23": [ "scale", "scale", 0 ],
            "obj-9::obj-28": [ "rotate", "rotate", 0 ],
            "obj-9::obj-31": [ "thresh", "thresh", 0 ],
            "parameterbanks": {
                "0": {
                    "index": 0,
                    "name": "",
                    "parameters": [ "-", "-", "-", "-", "-", "-", "-", "-" ],
                    "buttons": [ "-", "-", "-", "-", "-", "-", "-", "-" ]
                }
            },
            "parameter_overrides": {
                "obj-13::obj-10": {
                    "parameter_longname": "bias[1]"
                },
                "obj-13::obj-14": {
                    "parameter_longname": "bm[1]"
                },
                "obj-13::obj-17": {
                    "parameter_longname": "live.menu[18]"
                },
                "obj-13::obj-22": {
                    "parameter_longname": "live.text[12]"
                },
                "obj-13::obj-29": {
                    "parameter_longname": "freq[1]"
                },
                "obj-13::obj-30": {
                    "parameter_longname": "angle[1]"
                },
                "obj-13::obj-42": {
                    "parameter_longname": "live.toggle[3]"
                },
                "obj-13::obj-47": {
                    "parameter_longname": "polarizer[1]"
                },
                "obj-13::obj-51": {
                    "parameter_longname": "live.menu[19]"
                },
                "obj-13::obj-53": {
                    "parameter_longname": "speed[1]"
                },
                "obj-13::obj-54": {
                    "parameter_longname": "morph[1]"
                },
                "obj-13::obj-6": {
                    "parameter_longname": "pm[1]",
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-13::obj-65": {
                    "parameter_longname": "shape[1]"
                },
                "obj-13::obj-71": {
                    "parameter_longname": "phase[2]"
                },
                "obj-13::obj-72": {
                    "parameter_longname": "phase_time_switch[1]"
                },
                "obj-14::obj-32": {
                    "parameter_longname": "live.numbox[4]"
                },
                "obj-14::obj-45::obj-16": {
                    "parameter_longname": "live.menu[42]"
                },
                "obj-18::obj-221": {
                    "parameter_range": [ 0.0, 0.8 ]
                },
                "obj-18::obj-236": {
                    "parameter_longname": "hue_a",
                    "parameter_shortname": "hue_a"
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
                "obj-20::obj-91::obj-10::obj-11": {
                    "parameter_longname": "Jitter[2]"
                },
                "obj-20::obj-91::obj-11::obj-11": {
                    "parameter_longname": "Jitter[1]"
                },
                "obj-20::obj-91::obj-12::obj-23": {
                    "parameter_longname": "Gain[3]"
                },
                "obj-20::obj-91::obj-12::obj-25": {
                    "parameter_longname": "Offset[3]"
                },
                "obj-20::obj-91::obj-12::obj-27": {
                    "parameter_longname": "Lacunarity[3]"
                },
                "obj-20::obj-91::obj-12::obj-31": {
                    "parameter_longname": "H value[3]"
                },
                "obj-20::obj-91::obj-15::obj-11": {
                    "parameter_longname": "H value[4]"
                },
                "obj-20::obj-91::obj-15::obj-16": {
                    "parameter_longname": "Lacunarity[4]"
                },
                "obj-20::obj-91::obj-15::obj-18": {
                    "parameter_longname": "Offset[4]"
                },
                "obj-20::obj-91::obj-15::obj-19": {
                    "parameter_longname": "Gain[4]"
                },
                "obj-20::obj-91::obj-4::obj-24": {
                    "parameter_longname": "Gain[1]"
                },
                "obj-20::obj-91::obj-4::obj-26": {
                    "parameter_longname": "Offset[1]"
                },
                "obj-20::obj-91::obj-4::obj-28": {
                    "parameter_longname": "Lacunarity[1]"
                },
                "obj-20::obj-91::obj-4::obj-32": {
                    "parameter_longname": "H value[1]"
                },
                "obj-20::obj-91::obj-5::obj-23": {
                    "parameter_longname": "Gain[2]"
                },
                "obj-20::obj-91::obj-5::obj-25": {
                    "parameter_longname": "Offset[2]"
                },
                "obj-20::obj-91::obj-5::obj-27": {
                    "parameter_longname": "Lacunarity[2]"
                },
                "obj-20::obj-91::obj-5::obj-31": {
                    "parameter_longname": "H value[2]"
                },
                "obj-20::obj-91::obj-6::obj-11": {
                    "parameter_longname": "Jitter[4]"
                },
                "obj-20::obj-91::obj-9::obj-11": {
                    "parameter_longname": "Jitter[3]"
                },
                "obj-25::obj-6": {
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-25::obj-71": {
                    "parameter_longname": "phase[1]"
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
                "obj-9::obj-28": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-9::obj-31": {
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
                "boxes": [ "obj-14", "obj-10" ]
            }
        ]
    }
}