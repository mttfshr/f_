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
        "rect": [ 681.0, 107.0, 941.0, 849.0 ],
        "boxes": [
            {
                "box": {
                    "bgmode": 1,
                    "border": 1,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-36",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_preview.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 547.0, 104.0, 112.0, 102.02620087336243 ],
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "format": 6,
                    "id": "obj-35",
                    "maxclass": "flonum",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "bang" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 877.0, 350.0, 50.0, 22.0 ]
                }
            },
            {
                "box": {
                    "id": "obj-33",
                    "linecount": 2,
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "float" ],
                    "patching_rect": [ 843.0, 291.0, 122.0, 35.0 ],
                    "text": "sigmund~ env @hop 4096"
                }
            },
            {
                "box": {
                    "id": "obj-32",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 572.0, 233.0, 49.0, 22.0 ],
                    "text": "note $1"
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
                    "name": "vs_preview.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 370.0, 840.0, 112.0, 102.02620087336243 ],
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
                    "id": "obj-28",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_caustic.maxpat",
                    "numinlets": 2,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 381.0, 684.0, 227.0, 122.0 ],
                    "varname": "f_caustic",
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
                    "name": "f_chladni.maxpat",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 293.0, 8.0, 233.0, 163.02620087336243 ],
                    "varname": "f_chladni",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "id": "obj-25",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 594.0, 294.0, 58.0, 22.0 ],
                    "text": "phase $1"
                }
            },
            {
                "box": {
                    "format": 6,
                    "id": "obj-23",
                    "maxclass": "flonum",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "bang" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 779.8552631735802, 367.0, 50.0, 22.0 ]
                }
            },
            {
                "box": {
                    "id": "obj-20",
                    "maxclass": "newobj",
                    "numinlets": 6,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 687.0, 294.0, 101.0, 22.0 ],
                    "text": "scale 1 127 -1. 1."
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
                    "name": "vs_wfg_3.maxpat",
                    "numinlets": 3,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 585.0, 367.0, 178.0, 132.0 ],
                    "varname": "vs_wfg_3",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "id": "obj-11",
                    "maxclass": "gain~",
                    "multichannelvariant": 0,
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "signal", "" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 812.0, 115.0, 22.0, 140.0 ]
                }
            },
            {
                "box": {
                    "id": "obj-6",
                    "maxclass": "ezadc~",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "signal", "signal" ],
                    "patching_rect": [ 800.5, 31.0, 45.0, 45.0 ]
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
                    "patching_rect": [ 733.0, 501.0, 96.85526317358028, 146.5 ],
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
                    "patching_rect": [ 136.0, 527.0, 112.0, 102.02620087336243 ],
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
                    "name": "vs_preview.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 547.0, 541.0, 112.0, 102.02620087336243 ],
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
                    "id": "obj-8",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_preview.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 676.0, 25.0, 112.0, 102.02620087336243 ],
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
                    "id": "obj-21",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_vf_advect.maxpat",
                    "numinlets": 2,
                    "numoutlets": 3,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 307.0, 499.25, 190.0, 150.0 ],
                    "varname": "f_vf_advect",
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
                    "name": "f_wave_field.maxpat",
                    "numinlets": 2,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 326.0, 217.0, 190.5, 232.0 ],
                    "varname": "f_wave_field",
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
                    "patching_rect": [ 92.0, 8.0, 96.0, 420.0 ],
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
                    "patching_rect": [ 815.0, 410.0, 170.0, 144.5 ],
                    "varname": "vs_presets",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "autorestore": "f_demo_wave_field.json",
                    "hidden": 1,
                    "id": "obj-10",
                    "linecount": 2,
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 815.0, 497.0, 138.0, 35.0 ],
                    "priority": {
                        "vs_wfg_polarizer[1]::pm_range": -1,
                        "vs_wfg_polarizer[1]::lock_freq": -1,
                        "vs_wfg_s::wfg_fm_range": -1,
                        "vs_wfg_s::wfg_freq_range": -1,
                        "vs_wfg_2::wfg2_freq_range": -1,
                        "vs_wfg_2::wfg2_pm_range": -1,
                        "vs_wfg_2::wfg2_fm_range": -1,
                        "vs_wfg_3::wfg3_fm_range": -1,
                        "vs_wfg_3::wfg3_freq_range": -1,
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
                    "id": "obj-3",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_output.maxpat",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "offset": [ 0.0, 0.0 ],
                    "patching_rect": [ 81.0, 777.0, 157.0, 22.0 ],
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
                    "patching_rect": [ 9.0, 8.0, 79.0, 316.0 ],
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
                    "destination": [ "obj-33", 0 ],
                    "source": [ "obj-11", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-21", 1 ],
                    "order": 1,
                    "source": [ "obj-12", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-28", 1 ],
                    "order": 0,
                    "source": [ "obj-12", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-9", 0 ],
                    "order": 2,
                    "source": [ "obj-12", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-12", 1 ],
                    "order": 0,
                    "source": [ "obj-19", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-27", 0 ],
                    "order": 1,
                    "source": [ "obj-19", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-23", 0 ],
                    "order": 0,
                    "source": [ "obj-20", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-25", 0 ],
                    "order": 1,
                    "source": [ "obj-20", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-28", 0 ],
                    "source": [ "obj-21", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-19", 0 ],
                    "source": [ "obj-25", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-12", 0 ],
                    "order": 0,
                    "source": [ "obj-27", 2 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-21", 0 ],
                    "order": 0,
                    "source": [ "obj-27", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-36", 0 ],
                    "order": 1,
                    "source": [ "obj-27", 2 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-8", 0 ],
                    "order": 1,
                    "source": [ "obj-27", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-29", 0 ],
                    "order": 1,
                    "source": [ "obj-28", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-3", 0 ],
                    "order": 0,
                    "source": [ "obj-28", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-27", 0 ],
                    "source": [ "obj-32", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-20", 0 ],
                    "order": 1,
                    "source": [ "obj-33", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-32", 0 ],
                    "order": 2,
                    "source": [ "obj-33", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-35", 0 ],
                    "order": 0,
                    "source": [ "obj-33", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-11", 0 ],
                    "source": [ "obj-6", 0 ]
                }
            }
        ],
        "parameters": {
            "obj-12::obj-20": [ "speed", "speed", 0 ],
            "obj-12::obj-23": [ "damping", "damping", 0 ],
            "obj-12::obj-26": [ "dispersion", "dispersion", 0 ],
            "obj-12::obj-29": [ "ring", "ring", 0 ],
            "obj-12::obj-32": [ "edge", "edge", 0 ],
            "obj-12::obj-35": [ "exc_x", "force", 0 ],
            "obj-12::obj-38": [ "exc_y", "strength", 0 ],
            "obj-12::obj-41": [ "frequency", "gain", 0 ],
            "obj-12::obj-44": [ "amplitude", "lmode", 0 ],
            "obj-19::obj-10": [ "wfg3_bias", "Bias", 0 ],
            "obj-19::obj-14": [ "wfg3_biasm", "BM", 0 ],
            "obj-19::obj-17": [ "live.menu[35]", "live.menu", 0 ],
            "obj-19::obj-22": [ "live.toggle[1]", "live.toggle[1]", 0 ],
            "obj-19::obj-24": [ "live.toggle", "live.toggle", 0 ],
            "obj-19::obj-25": [ "wfg3_curve", "curve", 0 ],
            "obj-19::obj-29": [ "wfg3_freq", "Freq", 0 ],
            "obj-19::obj-30": [ "wfg3_angle", "Angle", 0 ],
            "obj-19::obj-4": [ "wfg3_fm", "FM", 0 ],
            "obj-19::obj-42": [ "live.toggle[2]", "live.toggle", 0 ],
            "obj-19::obj-53": [ "wfg3_speed", "Speed", 0 ],
            "obj-19::obj-6": [ "wfg3_pm", "PM", 0 ],
            "obj-19::obj-63": [ "wfg3_phase", "Phase", 0 ],
            "obj-19::obj-65": [ "wfg3_shape", "Shape", 0 ],
            "obj-19::obj-72": [ "wfg3_phase_time_switch", "wfg2_phase_time_switch", 0 ],
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
            "obj-21::obj-20": [ "dt[1]", "dt", 0 ],
            "obj-21::obj-23": [ "decay", "decay", 0 ],
            "obj-21::obj-26": [ "injection", "injection", 0 ],
            "obj-21::obj-29": [ "freq", "gain", 0 ],
            "obj-21::obj-32": [ "mix_pct[1]", "mix_pct", 0 ],
            "obj-21::obj-35": [ "separate", "separate", 0 ],
            "obj-21::obj-38": [ "mode", "mode", 0 ],
            "obj-21::obj-41": [ "trail", "trail", 0 ],
            "obj-27::obj-20": [ "note", "note", 0 ],
            "obj-27::obj-23": [ "amp", "amp", 0 ],
            "obj-27::obj-26": [ "dishradius", "dishradius", 0 ],
            "obj-27::obj-29": [ "reflectamt", "reflectamt", 0 ],
            "obj-27::obj-32": [ "linesharpness", "linesharpness", 0 ],
            "obj-27::obj-35": [ "ph0", "ph0", 0 ],
            "obj-27::obj-38": [ "spread", "spread", 0 ],
            "obj-27::obj-41": [ "mode[1]", "mode", 0 ],
            "obj-27::obj-44": [ "view_mode", "view_mode", 0 ],
            "obj-27::obj-47": [ "gain", "gain", 0 ],
            "obj-28::obj-20": [ "mix_pct", "mix_pct", 0 ],
            "obj-28::obj-23": [ "gain[1]", "gain", 0 ],
            "obj-28::obj-26": [ "scale", "scale", 0 ],
            "obj-28::obj-29": [ "expo", "expo", 0 ],
            "obj-28::obj-310": [ "range_gain", "range_gain", 0 ],
            "obj-28::obj-32": [ "edge[1]", "edge", 0 ],
            "obj-28::obj-320": [ "range_scale", "range_scale", 0 ],
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
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-12::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-12::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-12::obj-35": {
                    "parameter_invisible": 0,
                    "parameter_longname": "exc_x",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-12::obj-38": {
                    "parameter_invisible": 0,
                    "parameter_longname": "exc_y",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-12::obj-41": {
                    "parameter_invisible": 0,
                    "parameter_longname": "frequency",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-12::obj-44": {
                    "parameter_invisible": 0,
                    "parameter_longname": "amplitude",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-19::obj-17": {
                    "parameter_longname": "live.menu[35]"
                },
                "obj-19::obj-29": {
                    "parameter_range": [ 0.0, 1020.0 ]
                },
                "obj-19::obj-4": {
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-19::obj-6": {
                    "parameter_range": [ -1.0, 1.0 ]
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
                "obj-21::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_longname": "dt[1]",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-21::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-21::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-21::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_longname": "freq",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-21::obj-32": {
                    "parameter_invisible": 0,
                    "parameter_longname": "mix_pct[1]",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-21::obj-35": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-21::obj-38": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 0,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 9
                },
                "obj-21::obj-41": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-27::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-27::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-27::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-27::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-27::obj-32": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-27::obj-35": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-27::obj-38": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-27::obj-41": {
                    "parameter_invisible": 0,
                    "parameter_longname": "mode[1]",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-27::obj-44": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-27::obj-47": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-28::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-28::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_longname": "gain[1]",
                    "parameter_modmode": 3,
                    "parameter_range": [ 0.0, 1.0 ],
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-28::obj-26": {
                    "parameter_range": [ 0.0, 1.0 ]
                },
                "obj-28::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-28::obj-32": {
                    "parameter_longname": "edge[1]"
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