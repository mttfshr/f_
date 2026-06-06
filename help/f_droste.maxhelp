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
        "rect": [ 100.0, 99.0, 871.0, 780.0 ],
        "gridonopen": 2,
        "toolbarvisible": 0,
        "helpsidebarclosed": 1,
        "boxes": [
            {
                "box": {
                    "bgcolor": [ 0.2, 0.2, 0.2, 0.0 ],
                    "fontface": 0,
                    "fontname": "Ableton Sans Light",
                    "fontsize": 14.0,
                    "id": "h-2",
                    "linecount": 2,
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 15.0, 75.0, 270.0, 40.0 ],
                    "presentation_linecount": 2,
                    "saved_attribute_attributes": {
                        "textcolor": {
                            "expression": "themecolor.live_control_fg"
                        }
                    },
                    "text": "Log-polar spiral transform — Droste / Escher-style recursive zoom",
                    "varname": "autohelp_top_digest[3]"
                }
            },
            {
                "box": {
                    "bgcolor": [ 0.2, 0.2, 0.2, 0.0 ],
                    "fontface": 0,
                    "fontname": "Ableton Sans Medium",
                    "fontsize": 36.0,
                    "id": "h-1",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 15.0, 15.0, 270.0, 50.0 ],
                    "saved_attribute_attributes": {
                        "textcolor": {
                            "expression": "themecolor.live_control_fg"
                        }
                    },
                    "text": "Droste",
                    "varname": "autohelp_top_digest[4]"
                }
            },
            {
                "box": {
                    "bgmode": 1,
                    "border": 1,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "d-3",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_sources_main.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 338.0, 23.75, 296.4, 125.5 ],
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
                    "id": "d-4",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_droste.maxpat",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 338.0, 293.75, 154.0, 91.0 ],
                    "varname": "f_droste",
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
                    "id": "d-5",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_preview.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 338.0, 404.75, 236.0, 249.0 ],
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
                    "id": "d-6",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_lfo.maxpat",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "float" ],
                    "patching_rect": [ 417.0, 195.75, 75.0, 73.5 ],
                    "varname": "vs_lfo",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgcolor": [ 0.0, 0.0, 0.0, 0.0 ],
                    "bubble": 1,
                    "fontface": 0,
                    "fontname": "Ableton Sans Light",
                    "fontsize": 13.0,
                    "id": "d-7",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 500.0, 220.75, 64.0, 26.0 ],
                    "text": "time_s"
                }
            },
            {
                "box": {
                    "bgcolor": [ 0.2, 0.2, 0.2, 0.0 ],
                    "fontface": 0,
                    "fontname": "Ableton Sans Light",
                    "id": "d-8",
                    "linecount": 8,
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 15.0, 150.0, 270.0, 122.0 ],
                    "saved_attribute_attributes": {
                        "textcolor": {
                            "expression": "themecolor.live_control_fg"
                        }
                    },
                    "text": "External Control Messages\n\nbypass [0 / 1]\nzoom [1.1 – 100.0]\nn_arms [1 – 16]\ntwist [-8.0 – 8.0]\nrotation [0.0 – 1.0]\ntime_s [continuous]",
                    "textjustification": 0
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "r-1",
                    "linecount": 14,
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 15.0, 315.0, 270.0, 208.0 ],
                    "text": "References\n\nLog-polar mapping: classical complex analysis\nlog(z) = log|z| + i * arg(z)\n\nLenstra & de Smit (2003)\n\"Solving Escher's Problem\"\nhttps://www.math.leidenuniv.nl/~smit/escher/\n\nSymmetric shear formulation (twist parameter):\nderived in development -- not from any external source.\nAt twist=1, one revolution = one zoom level (Escher coupling)."
                }
            },
            {
                "box": {
                    "id": "obj-1",
                    "maxclass": "panel",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 0.0, -2.0, 303.0, 765.0 ]
                }
            }
        ],
        "lines": [
            {
                "patchline": {
                    "destination": [ "d-4", 0 ],
                    "source": [ "d-3", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "d-5", 0 ],
                    "source": [ "d-4", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "d-4", 1 ],
                    "source": [ "d-6", 1 ]
                }
            }
        ],
        "parameters": {
            "d-3::obj-14::obj-12": [ "flip_x[1]", "flip_x", 0 ],
            "d-3::obj-14::obj-21": [ "flip_y[1]", "flip_x", 0 ],
            "d-3::obj-14::obj-22": [ "swap[1]", "flip_x", 0 ],
            "d-3::obj-14::obj-3": [ "sync_invert[1]", "sync_inv", 0 ],
            "d-3::obj-14::obj-4": [ "live.text[12]", "live.text", 0 ],
            "d-3::obj-15::obj-16": [ "live.arrows", "live.arrows", 0 ],
            "d-3::obj-15::obj-28": [ "sync_invert", "sync_inv", 0 ],
            "d-3::obj-15::obj-42": [ "number", "number", 0 ],
            "d-3::obj-24::obj-11": [ "sync_invert[3]", "sync_inv", 0 ],
            "d-3::obj-24::obj-19": [ "noise2_dim_x[1]", "dim_x", 0 ],
            "d-3::obj-24::obj-2": [ "noise2_dim_x", "dim_x", 0 ],
            "d-3::obj-24::obj-35": [ "live.dial", "Speed", 0 ],
            "d-3::obj-24::obj-43": [ "temp_freq", "Slide", 0 ],
            "d-3::obj-24::obj-8": [ "sync_invert[4]", "sync_inv", 0 ],
            "d-3::obj-4::obj-1": [ "live.text", "sync_inv", 0 ],
            "d-3::obj-4::obj-10": [ "wfg_pw", "PW", 0 ],
            "d-3::obj-4::obj-137": [ "wfg_wf", "waveform", 0 ],
            "d-3::obj-4::obj-139": [ "sync_pos", "position", 0 ],
            "d-3::obj-4::obj-29": [ "wfg_freq", "Freq", 0 ],
            "d-3::obj-4::obj-3": [ "sync_time", "Time", 0 ],
            "d-3::obj-4::obj-4": [ "wfg_freq[1]", "Phase", 0 ],
            "d-3::obj-4::obj-60": [ "clrizer_color[1]", "color", 0 ],
            "d-3::obj-9::obj-13": [ "myGrads", "live.menu", 0 ],
            "d-3::obj-9::obj-17": [ "live.numbox", "live.numbox", 0 ],
            "d-3::obj-9::obj-22": [ "clpick", "live.text", 0 ],
            "d-3::obj-9::obj-34": [ "live.tab", "live.tab", 0 ],
            "d-4::obj-2": [ "zoom", "zoom", 0 ],
            "d-4::obj-3": [ "n_arms", "n_arms", 0 ],
            "d-4::obj-4": [ "twist", "twist", 0 ],
            "d-4::obj-5": [ "rotation", "rotation", 0 ],
            "d-6::obj-34": [ "live.dial[3]", "Freq", 0 ],
            "d-6::obj-35": [ "live.dial[2]", "Freq", 0 ],
            "d-6::obj-4": [ "lfo_freq__range", "live.text", 0 ],
            "d-6::obj-82": [ "lfo_wave", "lfo_wave", 0 ],
            "d-6::obj-9": [ "lfo_freq", "Freq", 0 ],
            "d-6::obj-97": [ "lfo_pw", "lfo_pw", 0 ],
            "parameterbanks": {
                "0": {
                    "index": 0,
                    "name": "",
                    "parameters": [ "-", "-", "-", "-", "-", "-", "-", "-" ],
                    "buttons": [ "-", "-", "-", "-", "-", "-", "-", "-" ]
                }
            },
            "parameter_overrides": {
                "d-3::obj-24::obj-11": {
                    "parameter_longname": "sync_invert[3]"
                },
                "d-3::obj-24::obj-8": {
                    "parameter_longname": "sync_invert[4]"
                },
                "d-4::obj-2": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "d-4::obj-3": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 0,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "d-4::obj-4": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "d-4::obj-5": {
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