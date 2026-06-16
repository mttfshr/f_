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
        "rect": [ 55.0, 65.0, 871.0, 780.0 ],
        "gridonopen": 2,
        "toolbarvisible": 0,
        "helpsidebarclosed": 1,
        "boxes": [
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
                    "name": "vs_preview.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 609.0, 190.0, 236.0, 249.0 ],
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
                    "name": "vs_preview.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 576.0, 464.0, 236.0, 249.0 ],
                    "viewvisibility": 1
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
                    "text": "Grain",
                    "varname": "autohelp_top_digest[4]"
                }
            },
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
                    "saved_attribute_attributes": {
                        "textcolor": {
                            "expression": "themecolor.live_control_fg"
                        }
                    },
                    "text": "Stochastic voronoi grain field with displacement and luma gating",
                    "varname": "autohelp_top_digest[3]"
                }
            },
            {
                "box": {
                    "bgcolor": [ 0.2, 0.2, 0.2, 0.0 ],
                    "fontface": 0,
                    "fontname": "Ableton Sans Light",
                    "id": "d-8",
                    "linecount": 17,
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 15.0, 150.0, 270.0, 251.0 ],
                    "saved_attribute_attributes": {
                        "textcolor": {
                            "expression": "themecolor.live_control_fg"
                        }
                    },
                    "text": "External Control Messages\n\nsize [0.0 -- 1.0]\nsize_var [0.0 -- 1.0]\nshape [0.0 -- 1.0]\njitter [0.0 -- 2.0]\nfade [0.0 -- 4.0]\npersistence [0.0 -- 1.0]\nsv_seed [0.0 -- 5.0]\nfield [0.0 -- 5.0]\namount [0.0 -- 2.0]\ndensity [0.0 -- 1.0]\nch_diverge [0.0 -- 1.0]\nluma_gate [-1.0 -- 1.0]\ndisplace [0.0 -- 0.5]\nedge_mode [Clear / Clamp / Wrap / Mirror]\nbypass [0 / 1]"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "r-1",
                    "linecount": 10,
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 15.0, 440.0, 270.0, 151.0 ],
                    "text": "References\n\nVoronoi noise: Worley (1996)\n\"A Cellular Texture Basis Function\"\nSIGGRAPH Proceedings\n\nEra-based temporal grain:\noriginal derivation -- not from external source.\nGrain identity pinned to fixed 4096-unit grid;\npersistence driven by era_clock accumulator."
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
                    "name": "f_grain.maxpat",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 338.0, 178.0, 232.0, 171.0 ],
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
                    "id": "d-5",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_preview.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 338.0, 464.0, 236.0, 249.0 ],
                    "viewvisibility": 1
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
                    "destination": [ "obj-2", 0 ],
                    "source": [ "d-4", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-3", 0 ],
                    "source": [ "d-4", 2 ]
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
            "d-3::obj-24::obj-8": [ "sync_invert[2]", "sync_inv", 0 ],
            "d-3::obj-4::obj-1": [ "live.text", "sync_inv", 0 ],
            "d-3::obj-4::obj-10": [ "wfg_pw[1]", "PW", 0 ],
            "d-3::obj-4::obj-137": [ "wfg_wf[1]", "waveform", 0 ],
            "d-3::obj-4::obj-139": [ "sync_pos", "position", 0 ],
            "d-3::obj-4::obj-29": [ "wfg_freq[1]", "Freq", 0 ],
            "d-3::obj-4::obj-3": [ "sync_time", "Time", 0 ],
            "d-3::obj-4::obj-4": [ "wfg_freq[2]", "Phase", 0 ],
            "d-3::obj-4::obj-60": [ "clrizer_color[1]", "color", 0 ],
            "d-3::obj-9::obj-13": [ "myGrads", "live.menu", 0 ],
            "d-3::obj-9::obj-17": [ "live.numbox", "live.numbox", 0 ],
            "d-3::obj-9::obj-22": [ "clpick", "live.text", 0 ],
            "d-3::obj-9::obj-34": [ "live.tab", "live.tab", 0 ],
            "d-4::obj-11": [ "density", "density", 0 ],
            "d-4::obj-13": [ "amount", "amount", 0 ],
            "d-4::obj-15": [ "persistence", "persistence", 0 ],
            "d-4::obj-2": [ "fade", "fade", 0 ],
            "d-4::obj-25": [ "size", "size", 0 ],
            "d-4::obj-27": [ "size_var", "size_var", 0 ],
            "d-4::obj-29": [ "shape", "shape", 0 ],
            "d-4::obj-31": [ "softness", "softness", 0 ],
            "d-4::obj-37": [ "jitter", "jitter", 0 ],
            "d-4::obj-40": [ "ch_diverge", "ch_diverge", 0 ],
            "d-4::obj-43": [ "field", "field", 0 ],
            "d-4::obj-60": [ "luma_gate", "luma_gate", 0 ],
            "d-4::obj-63": [ "displace", "displace", 0 ],
            "d-4::obj-71": [ "edge_mode_menu", "edge_mode_menu", 0 ],
            "d-4::obj-82": [ "sv_seed", "sv_seed", 0 ],
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
                    "parameter_longname": "sync_invert[2]"
                },
                "d-3::obj-4::obj-10": {
                    "parameter_longname": "wfg_pw[1]"
                },
                "d-3::obj-4::obj-137": {
                    "parameter_longname": "wfg_wf[1]"
                },
                "d-3::obj-4::obj-29": {
                    "parameter_longname": "wfg_freq[1]"
                },
                "d-3::obj-4::obj-4": {
                    "parameter_longname": "wfg_freq[2]"
                }
            },
            "inherited_shortname": 1
        },
        "autosave": 0
    }
}