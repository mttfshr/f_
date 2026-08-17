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
        "rect": [ 34.0, 95.0, 940.0, 921.0 ],
        "boxes": [
            {
                "box": {
                    "bgmode": 1,
                    "border": 1,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-38",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vsc_presets.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "" ],
                    "patching_rect": [ 766.83203125, 635.64453125, 170.0, 144.5 ],
                    "varname": "vs_presets",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "autorestore": "lens.json",
                    "hidden": 1,
                    "id": "obj-10",
                    "linecount": 2,
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 766.83203125, 722.64453125, 138.0, 35.0 ],
                    "priority": {
                        "vs_wfg_polarizer[1]::pm_range": -1,
                        "vs_wfg_polarizer[1]::lock_freq": -1,
                        "vs_wfg_polarizer[2]::pm_range": -1,
                        "vs_wfg_polarizer[2]::lock_freq": -1,
                        "vs_wfg_polarizer[3]::pm_range": -1,
                        "vs_wfg_polarizer[3]::lock_freq": -1
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
                    "id": "obj-37",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_vf_repulse.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 549.0, 492.0, 165.0, 80.0 ],
                    "varname": "f_vf_repulse[1]",
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
                    "id": "obj-36",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_vf_prism.maxpat",
                    "numinlets": 4,
                    "numoutlets": 3,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 264.0, 551.0, 190.0, 160.0 ],
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
                    "id": "obj-35",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_vf_repulse.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 532.0, -107.0, 165.0, 80.0 ],
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
                    "id": "obj-33",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_caustic.maxpat",
                    "numinlets": 2,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 262.0, 9.0, 190.0, 100.0 ],
                    "varname": "f_caustic",
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
                    "id": "obj-32",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vz.bfgener8r.maxpat",
                    "numinlets": 12,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 246.0, -256.0, 268.0, 234.0 ],
                    "prototypename": "pixl",
                    "varname": "bfgener8r",
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
                    "id": "obj-29",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_lens.maxpat",
                    "numinlets": 5,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 269.0, 251.0, 233.0, 170.0 ],
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
                    "id": "obj-21",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_wfg_polarizer.maxpat",
                    "numinlets": 2,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 710.0, 277.0, 220.0, 132.0 ],
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
                    "id": "obj-20",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_wfg_polarizer.maxpat",
                    "numinlets": 2,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 755.0, 18.0, 220.0, 132.0 ],
                    "varname": "vs_wfg_polarizer[2]",
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
                    "id": "obj-19",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_wfg_polarizer.maxpat",
                    "numinlets": 2,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 525.0, 14.0, 220.0, 132.0 ],
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
                    "id": "obj-6",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_modules.maxpat",
                    "numinlets": 0,
                    "numoutlets": 0,
                    "offset": [ 0.0, 0.0 ],
                    "patching_rect": [ 25.0, 339.0, 104.0, 386.0 ],
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
                    "patching_rect": [ 234.0, 790.0, 157.0, 22.0 ],
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
                    "destination": [ "obj-29", 1 ],
                    "source": [ "obj-19", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-29", 2 ],
                    "source": [ "obj-20", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-29", 3 ],
                    "source": [ "obj-21", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-36", 0 ],
                    "source": [ "obj-29", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-33", 0 ],
                    "order": 2,
                    "source": [ "obj-32", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-35", 0 ],
                    "order": 1,
                    "source": [ "obj-32", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-37", 0 ],
                    "order": 0,
                    "source": [ "obj-32", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-29", 0 ],
                    "source": [ "obj-33", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-33", 1 ],
                    "source": [ "obj-35", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-4", 0 ],
                    "source": [ "obj-36", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-36", 1 ],
                    "source": [ "obj-37", 0 ]
                }
            },
            {
                "patchline": {
                    "color": [ 0.65, 0.65, 0.65, 0.0 ],
                    "destination": [ "obj-10", 0 ],
                    "hidden": 1,
                    "source": [ "obj-38", 0 ]
                }
            }
        ],
        "parameters": {
            "obj-19::obj-10": [ "bias[1]", "Bias", 0 ],
            "obj-19::obj-14": [ "bm[1]", "BM", 0 ],
            "obj-19::obj-17": [ "live.menu[19]", "live.menu", 0 ],
            "obj-19::obj-22": [ "live.text[12]", "live.text", 0 ],
            "obj-19::obj-29": [ "freq[1]", "Freq", 0 ],
            "obj-19::obj-30": [ "angle[1]", "Angle", 0 ],
            "obj-19::obj-42": [ "live.toggle[3]", "live.toggle", 0 ],
            "obj-19::obj-47": [ "polarizer[1]", "Morph", 0 ],
            "obj-19::obj-51": [ "live.menu[20]", "live.menu", 0 ],
            "obj-19::obj-53": [ "speed[1]", "Speed", 0 ],
            "obj-19::obj-54": [ "morph[1]", "Morph", 0 ],
            "obj-19::obj-6": [ "pm[1]", "PM", 0 ],
            "obj-19::obj-65": [ "shape[1]", "Shape", 0 ],
            "obj-19::obj-71": [ "phase[1]", "Phase", 0 ],
            "obj-19::obj-72": [ "phase_time_switch[1]", "phase_time_switch", 0 ],
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
            "obj-20::obj-10": [ "bias[2]", "Bias", 0 ],
            "obj-20::obj-14": [ "bm[2]", "BM", 0 ],
            "obj-20::obj-17": [ "live.menu[21]", "live.menu", 0 ],
            "obj-20::obj-22": [ "live.text[13]", "live.text", 0 ],
            "obj-20::obj-29": [ "freq[2]", "Freq", 0 ],
            "obj-20::obj-30": [ "angle[2]", "Angle", 0 ],
            "obj-20::obj-42": [ "live.toggle[4]", "live.toggle", 0 ],
            "obj-20::obj-47": [ "polarizer[2]", "Morph", 0 ],
            "obj-20::obj-51": [ "live.menu[18]", "live.menu", 0 ],
            "obj-20::obj-53": [ "speed[2]", "Speed", 0 ],
            "obj-20::obj-54": [ "morph[2]", "Morph", 0 ],
            "obj-20::obj-6": [ "pm[2]", "PM", 0 ],
            "obj-20::obj-65": [ "shape[2]", "Shape", 0 ],
            "obj-20::obj-71": [ "phase[2]", "Phase", 0 ],
            "obj-20::obj-72": [ "phase_time_switch[2]", "phase_time_switch", 0 ],
            "obj-21::obj-10": [ "bias[3]", "Bias", 0 ],
            "obj-21::obj-14": [ "bm[3]", "BM", 0 ],
            "obj-21::obj-17": [ "live.menu[23]", "live.menu", 0 ],
            "obj-21::obj-22": [ "live.text[14]", "live.text", 0 ],
            "obj-21::obj-29": [ "freq[3]", "Freq", 0 ],
            "obj-21::obj-30": [ "angle[3]", "Angle", 0 ],
            "obj-21::obj-42": [ "live.toggle[5]", "live.toggle", 0 ],
            "obj-21::obj-47": [ "polarizer[3]", "Morph", 0 ],
            "obj-21::obj-51": [ "live.menu[22]", "live.menu", 0 ],
            "obj-21::obj-53": [ "speed[3]", "Speed", 0 ],
            "obj-21::obj-54": [ "morph[3]", "Morph", 0 ],
            "obj-21::obj-6": [ "pm[3]", "PM", 0 ],
            "obj-21::obj-65": [ "shape[3]", "Shape", 0 ],
            "obj-21::obj-71": [ "phase[3]", "Phase", 0 ],
            "obj-21::obj-72": [ "phase_time_switch[3]", "phase_time_switch", 0 ],
            "obj-29::obj-19d": [ "panel_toggle", "panel_toggle", 0 ],
            "obj-29::obj-20": [ "aberration", "aberration", 0 ],
            "obj-29::obj-23": [ "distortion", "distortion", 0 ],
            "obj-29::obj-26": [ "transmission", "transmission", 0 ],
            "obj-29::obj-29": [ "aberration_mod", "aberration_mod", 0 ],
            "obj-29::obj-300": [ "range_aberration", "range_aberration", 0 ],
            "obj-29::obj-310": [ "range_distortion", "range_distortion", 0 ],
            "obj-29::obj-32": [ "distortion_mod", "distortion_mod", 0 ],
            "obj-29::obj-320": [ "range_transmission", "range_transmission", 0 ],
            "obj-29::obj-35": [ "transmission_mod", "transmission_mod", 0 ],
            "obj-29::obj-38": [ "surface_mod", "surface_mod", 0 ],
            "obj-29::obj-390": [ "range_ghost_spacing", "range_ghost_spacing", 0 ],
            "obj-29::obj-41": [ "ghost", "ghost", 0 ],
            "obj-29::obj-44": [ "ghost_count", "ghost_count", 0 ],
            "obj-29::obj-47": [ "ghost_spacing", "ghost_spacing", 0 ],
            "obj-29::obj-50": [ "halation", "halation", 0 ],
            "obj-29::obj-53": [ "halation_threshold", "halation_threshold", 0 ],
            "obj-32::obj-100": [ "Speed", "Speed", 1 ],
            "obj-32::obj-104": [ "pictctrl[148]", "pictctrl[1]", 0 ],
            "obj-32::obj-15": [ "pictctrl[34]", "pictctrl[1]", 0 ],
            "obj-32::obj-17": [ "pictctrl[31]", "pictctrl[1]", 0 ],
            "obj-32::obj-21": [ "Colorize", "Colorize", 0 ],
            "obj-32::obj-23": [ "pictctrl[33]", "pictctrl[1]", 0 ],
            "obj-32::obj-26": [ "pictctrl[32]", "pictctrl[1]", 0 ],
            "obj-32::obj-278": [ "textbutton[3]", "textbutton[1]", 0 ],
            "obj-32::obj-37": [ "pictctrl[28]", "pictctrl[1]", 0 ],
            "obj-32::obj-46": [ "pictctrl[27]", "pictctrl[1]", 0 ],
            "obj-32::obj-5": [ "Function", "Function", 0 ],
            "obj-32::obj-55": [ "Bcolorize", "Bcolorize", 0 ],
            "obj-32::obj-56": [ "Gcolorize", "Gcolorize", 0 ],
            "obj-32::obj-57": [ "Rcolorize", "Rcolorize", 0 ],
            "obj-32::obj-59": [ "pictctrl[106]", "pictctrl[1]", 0 ],
            "obj-32::obj-61": [ "Zoom hi", "Zoom", 1 ],
            "obj-32::obj-63": [ "Zoom range[2]", "Zoom range", 1 ],
            "obj-32::obj-76": [ "pictctrl[29]", "pictctrl[1]", 0 ],
            "obj-32::obj-78": [ "Zoom lo", "Zoom", 1 ],
            "obj-32::obj-8": [ "pictctrl[30]", "pictctrl[1]", 0 ],
            "obj-32::obj-85": [ "pictctrl[4]", "pictctrl[1]", 0 ],
            "obj-32::obj-91::obj-10::obj-11": [ "Jitter[2]", "Jitter", 0 ],
            "obj-32::obj-91::obj-10::obj-19": [ "Amount", "Amount", 0 ],
            "obj-32::obj-91::obj-11::obj-11": [ "Jitter[1]", "Jitter", 0 ],
            "obj-32::obj-91::obj-11::obj-18": [ "Smoothing", "Smoothing", 0 ],
            "obj-32::obj-91::obj-12::obj-23": [ "Gain[3]", "Gain", 0 ],
            "obj-32::obj-91::obj-12::obj-25": [ "Offset[3]", "Offset", 0 ],
            "obj-32::obj-91::obj-12::obj-27": [ "Lacunarity[3]", "Lacunarity", 0 ],
            "obj-32::obj-91::obj-12::obj-31": [ "H value[3]", "H value", 0 ],
            "obj-32::obj-91::obj-13::obj-11": [ "Jitter", "Jitter", 0 ],
            "obj-32::obj-91::obj-15::obj-11": [ "H value[4]", "H value", 0 ],
            "obj-32::obj-91::obj-15::obj-16": [ "Lacunarity[4]", "Lacunarity", 0 ],
            "obj-32::obj-91::obj-15::obj-18": [ "Offset[4]", "Offset", 0 ],
            "obj-32::obj-91::obj-15::obj-19": [ "Gain[4]", "Gain", 0 ],
            "obj-32::obj-91::obj-1::obj-24": [ "Gain", "Gain", 0 ],
            "obj-32::obj-91::obj-1::obj-26": [ "Offset", "Offset", 0 ],
            "obj-32::obj-91::obj-1::obj-28": [ "Lacunarity", "Lacunarity", 0 ],
            "obj-32::obj-91::obj-1::obj-32": [ "H value", "H value", 0 ],
            "obj-32::obj-91::obj-3::obj-11": [ "Distortion", "Distortion", 0 ],
            "obj-32::obj-91::obj-4::obj-24": [ "Gain[1]", "Gain", 0 ],
            "obj-32::obj-91::obj-4::obj-26": [ "Offset[1]", "Offset", 0 ],
            "obj-32::obj-91::obj-4::obj-28": [ "Lacunarity[1]", "Lacunarity", 0 ],
            "obj-32::obj-91::obj-4::obj-32": [ "H value[1]", "H value", 0 ],
            "obj-32::obj-91::obj-5::obj-23": [ "Gain[2]", "Gain", 0 ],
            "obj-32::obj-91::obj-5::obj-25": [ "Offset[2]", "Offset", 0 ],
            "obj-32::obj-91::obj-5::obj-27": [ "Lacunarity[2]", "Lacunarity", 0 ],
            "obj-32::obj-91::obj-5::obj-31": [ "H value[2]", "H value", 0 ],
            "obj-32::obj-91::obj-6::obj-11": [ "Jitter[4]", "Jitter", 0 ],
            "obj-32::obj-91::obj-6::obj-24": [ "X crackle", "X crackle", 0 ],
            "obj-32::obj-91::obj-6::obj-28": [ "Y crackle", "Y crackle", 0 ],
            "obj-32::obj-91::obj-6::obj-29": [ "Z crackle", "Z crackle", 0 ],
            "obj-32::obj-91::obj-9::obj-11": [ "Jitter[3]", "Jitter", 0 ],
            "obj-32::obj-91::obj-9::obj-16": [ "Shading", "Shading", 0 ],
            "obj-32::obj-96": [ "pictctrl[35]", "pictctrl[1]", 0 ],
            "obj-33::obj-20": [ "mix_pct", "mix_pct", 0 ],
            "obj-33::obj-23": [ "gain", "gain", 0 ],
            "obj-33::obj-26": [ "scale", "scale", 0 ],
            "obj-33::obj-29": [ "softness[2]", "softness", 0 ],
            "obj-33::obj-32": [ "color_shift", "color_shift", 0 ],
            "obj-35::obj-20": [ "gain[1]", "gain", 0 ],
            "obj-35::obj-23": [ "reach", "reach", 0 ],
            "obj-35::obj-26": [ "threshold[1]", "threshold", 0 ],
            "obj-35::obj-29": [ "mode[1]", "mode", 0 ],
            "obj-36::obj-20": [ "reach[1]", "reach", 0 ],
            "obj-36::obj-23": [ "spread", "spread", 0 ],
            "obj-36::obj-26": [ "threshold", "threshold", 0 ],
            "obj-36::obj-29": [ "threshold_width", "threshold_width", 0 ],
            "obj-36::obj-32": [ "feather", "feather", 0 ],
            "obj-36::obj-35": [ "gain[2]", "gain", 0 ],
            "obj-36::obj-38": [ "mix_pct[1]", "mix_pct", 0 ],
            "obj-37::obj-20": [ "gain[3]", "gain", 0 ],
            "obj-37::obj-23": [ "reach[2]", "reach", 0 ],
            "obj-37::obj-26": [ "threshold[2]", "threshold", 0 ],
            "obj-37::obj-29": [ "mode[2]", "mode", 0 ],
            "obj-38::obj-10": [ "textedit", "vs_preset_name", 0 ],
            "obj-38::obj-11": [ "live.text", "live.text", 0 ],
            "obj-38::obj-15": [ "live.tab", "live.tab", 0 ],
            "obj-38::obj-32": [ "live.numbox[4]", "live.numbox", 0 ],
            "obj-38::obj-44": [ "live.tab[3]", "live.tab", 0 ],
            "obj-38::obj-45::obj-16": [ "live.menu[24]", "live.menu[16]", 0 ],
            "obj-38::obj-45::obj-17": [ "live.button", "live.button", 0 ],
            "obj-38::obj-45::obj-19": [ "live.numbox[2]", "live.numbox[1]", 0 ],
            "obj-38::obj-45::obj-32": [ "live.numbox", "live.numbox", 0 ],
            "obj-38::obj-45::obj-9": [ "live.numbox[3]", "live.numbox", 0 ],
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
            "parameterbanks": {
                "0": {
                    "index": 0,
                    "name": "",
                    "parameters": [ "-", "-", "-", "-", "-", "-", "-", "-" ],
                    "buttons": [ "-", "-", "-", "-", "-", "-", "-", "-" ]
                }
            },
            "parameter_overrides": {
                "obj-19::obj-10": {
                    "parameter_longname": "bias[1]"
                },
                "obj-19::obj-14": {
                    "parameter_longname": "bm[1]"
                },
                "obj-19::obj-17": {
                    "parameter_longname": "live.menu[19]"
                },
                "obj-19::obj-22": {
                    "parameter_longname": "live.text[12]"
                },
                "obj-19::obj-29": {
                    "parameter_longname": "freq[1]"
                },
                "obj-19::obj-30": {
                    "parameter_longname": "angle[1]"
                },
                "obj-19::obj-42": {
                    "parameter_longname": "live.toggle[3]"
                },
                "obj-19::obj-47": {
                    "parameter_longname": "polarizer[1]"
                },
                "obj-19::obj-51": {
                    "parameter_longname": "live.menu[20]"
                },
                "obj-19::obj-53": {
                    "parameter_longname": "speed[1]"
                },
                "obj-19::obj-54": {
                    "parameter_longname": "morph[1]"
                },
                "obj-19::obj-6": {
                    "parameter_longname": "pm[1]",
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-19::obj-65": {
                    "parameter_longname": "shape[1]"
                },
                "obj-19::obj-71": {
                    "parameter_longname": "phase[1]"
                },
                "obj-19::obj-72": {
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
                "obj-20::obj-10": {
                    "parameter_longname": "bias[2]"
                },
                "obj-20::obj-14": {
                    "parameter_longname": "bm[2]"
                },
                "obj-20::obj-17": {
                    "parameter_longname": "live.menu[21]"
                },
                "obj-20::obj-22": {
                    "parameter_longname": "live.text[13]"
                },
                "obj-20::obj-29": {
                    "parameter_longname": "freq[2]"
                },
                "obj-20::obj-30": {
                    "parameter_longname": "angle[2]"
                },
                "obj-20::obj-42": {
                    "parameter_longname": "live.toggle[4]"
                },
                "obj-20::obj-47": {
                    "parameter_longname": "polarizer[2]"
                },
                "obj-20::obj-51": {
                    "parameter_longname": "live.menu[18]"
                },
                "obj-20::obj-53": {
                    "parameter_longname": "speed[2]"
                },
                "obj-20::obj-54": {
                    "parameter_longname": "morph[2]"
                },
                "obj-20::obj-6": {
                    "parameter_longname": "pm[2]",
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-20::obj-65": {
                    "parameter_longname": "shape[2]"
                },
                "obj-20::obj-71": {
                    "parameter_longname": "phase[2]"
                },
                "obj-20::obj-72": {
                    "parameter_longname": "phase_time_switch[2]"
                },
                "obj-21::obj-10": {
                    "parameter_longname": "bias[3]"
                },
                "obj-21::obj-14": {
                    "parameter_longname": "bm[3]"
                },
                "obj-21::obj-17": {
                    "parameter_longname": "live.menu[23]"
                },
                "obj-21::obj-22": {
                    "parameter_longname": "live.text[14]"
                },
                "obj-21::obj-29": {
                    "parameter_longname": "freq[3]"
                },
                "obj-21::obj-30": {
                    "parameter_longname": "angle[3]"
                },
                "obj-21::obj-42": {
                    "parameter_longname": "live.toggle[5]"
                },
                "obj-21::obj-47": {
                    "parameter_longname": "polarizer[3]"
                },
                "obj-21::obj-51": {
                    "parameter_longname": "live.menu[22]"
                },
                "obj-21::obj-53": {
                    "parameter_longname": "speed[3]"
                },
                "obj-21::obj-54": {
                    "parameter_longname": "morph[3]"
                },
                "obj-21::obj-6": {
                    "parameter_longname": "pm[3]",
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-21::obj-65": {
                    "parameter_longname": "shape[3]"
                },
                "obj-21::obj-71": {
                    "parameter_longname": "phase[3]"
                },
                "obj-21::obj-72": {
                    "parameter_longname": "phase_time_switch[3]"
                },
                "obj-29::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_range": [ -1.0, 1.0 ],
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-29::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_longname": "distortion",
                    "parameter_modmode": 3,
                    "parameter_range": [ -5.0, 5.0 ],
                    "parameter_shortname": "distortion",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-29::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_longname": "transmission",
                    "parameter_modmode": 3,
                    "parameter_range": [ -1.0, 1.0 ],
                    "parameter_shortname": "transmission",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-29::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-29::obj-32": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-29::obj-35": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-29::obj-38": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-29::obj-41": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-29::obj-44": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-29::obj-47": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_range": [ -1.0, 1.0 ],
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-32::obj-91::obj-10::obj-11": {
                    "parameter_longname": "Jitter[2]"
                },
                "obj-32::obj-91::obj-11::obj-11": {
                    "parameter_longname": "Jitter[1]"
                },
                "obj-32::obj-91::obj-12::obj-23": {
                    "parameter_longname": "Gain[3]"
                },
                "obj-32::obj-91::obj-12::obj-25": {
                    "parameter_longname": "Offset[3]"
                },
                "obj-32::obj-91::obj-12::obj-27": {
                    "parameter_longname": "Lacunarity[3]"
                },
                "obj-32::obj-91::obj-12::obj-31": {
                    "parameter_longname": "H value[3]"
                },
                "obj-32::obj-91::obj-15::obj-11": {
                    "parameter_longname": "H value[4]"
                },
                "obj-32::obj-91::obj-15::obj-16": {
                    "parameter_longname": "Lacunarity[4]"
                },
                "obj-32::obj-91::obj-15::obj-18": {
                    "parameter_longname": "Offset[4]"
                },
                "obj-32::obj-91::obj-15::obj-19": {
                    "parameter_longname": "Gain[4]"
                },
                "obj-32::obj-91::obj-4::obj-24": {
                    "parameter_longname": "Gain[1]"
                },
                "obj-32::obj-91::obj-4::obj-26": {
                    "parameter_longname": "Offset[1]"
                },
                "obj-32::obj-91::obj-4::obj-28": {
                    "parameter_longname": "Lacunarity[1]"
                },
                "obj-32::obj-91::obj-4::obj-32": {
                    "parameter_longname": "H value[1]"
                },
                "obj-32::obj-91::obj-5::obj-23": {
                    "parameter_longname": "Gain[2]"
                },
                "obj-32::obj-91::obj-5::obj-25": {
                    "parameter_longname": "Offset[2]"
                },
                "obj-32::obj-91::obj-5::obj-27": {
                    "parameter_longname": "Lacunarity[2]"
                },
                "obj-32::obj-91::obj-5::obj-31": {
                    "parameter_longname": "H value[2]"
                },
                "obj-32::obj-91::obj-6::obj-11": {
                    "parameter_longname": "Jitter[4]"
                },
                "obj-32::obj-91::obj-9::obj-11": {
                    "parameter_longname": "Jitter[3]"
                },
                "obj-33::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-33::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-33::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-33::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_longname": "softness[2]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "softness",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-33::obj-32": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-35::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_longname": "gain[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "gain",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-35::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-35::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_longname": "threshold[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "threshold",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-35::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_longname": "mode[1]",
                    "parameter_modmode": 0,
                    "parameter_shortname": "mode",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 9
                },
                "obj-36::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_longname": "reach[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "reach",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-36::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-36::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-36::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-36::obj-32": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-36::obj-35": {
                    "parameter_invisible": 0,
                    "parameter_longname": "gain[2]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "gain",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-36::obj-38": {
                    "parameter_invisible": 0,
                    "parameter_longname": "mix_pct[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "mix_pct",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-37::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_longname": "gain[3]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "gain",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-37::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_longname": "reach[2]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "reach",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-37::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_longname": "threshold[2]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "threshold",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-37::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_longname": "mode[2]",
                    "parameter_modmode": 0,
                    "parameter_shortname": "mode",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 9
                },
                "obj-38::obj-32": {
                    "parameter_longname": "live.numbox[4]"
                },
                "obj-38::obj-45::obj-16": {
                    "parameter_longname": "live.menu[24]"
                }
            },
            "inherited_shortname": 1
        },
        "autosave": 0,
        "boxgroups": [
            {
                "boxes": [ "obj-38", "obj-10" ]
            }
        ]
    }
}