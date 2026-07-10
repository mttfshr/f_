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
                    "text": "Channel Grader",
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
                    "text": "Per-channel lift / gamma / gain color grading",
                    "varname": "autohelp_top_digest[3]"
                }
            },
            {
                "box": {
                    "bgcolor": [ 0.2, 0.2, 0.2, 0.0 ],
                    "fontface": 0,
                    "fontname": "Ableton Sans Light",
                    "id": "d-8",
                    "linecount": 15,
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 15.0, 150.0, 270.0, 223.0 ],
                    "saved_attribute_attributes": {
                        "textcolor": {
                            "expression": "themecolor.live_control_fg"
                        }
                    },
                    "text": "External Control Messages\n\nr_lift [-1.0 -- 1.0]\nr_gamma [-1.0 -- 1.0]\nr_gain [-1.0 -- 1.0]\ng_lift [-1.0 -- 1.0]\ng_gamma [-1.0 -- 1.0]\ng_gain [-1.0 -- 1.0]\nb_lift [-1.0 -- 1.0]\nb_gamma [-1.0 -- 1.0]\nb_gain [-1.0 -- 1.0]\nm_lift [-1.0 -- 1.0]\nm_gamma [-1.0 -- 1.0]\nm_gain [-1.0 -- 1.0]\nbypass [0 / 1]"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "r-1",
                    "linecount": 12,
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 15.0, 460.0, 270.0, 179.0 ],
                    "text": "References\n\nFilm-style lift/gamma/gain grading model.\nlift = black point offset\ngamma = midtone power (via pow(x, 1/2^gamma))\ngain = white point scale (via 2^gain)\n\nMaster grade applied sequentially after\nper-channel grade.\n\nOriginal derivation -- not from external source."
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
                    "name": "f_channel_grader.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 338.0, 190.0, 156.0, 170.0 ],
                    "varname": "f_channel_grader",
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
                    "patching_rect": [ 338.0, 384.0, 236.0, 249.0 ],
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
            "d-3::obj-24::obj-11": [ "sync_invert[2]", "sync_inv", 0 ],
            "d-3::obj-24::obj-19": [ "noise2_dim_x[1]", "dim_x", 0 ],
            "d-3::obj-24::obj-2": [ "noise2_dim_x", "dim_x", 0 ],
            "d-3::obj-24::obj-35": [ "live.dial", "Speed", 0 ],
            "d-3::obj-24::obj-43": [ "temp_freq", "Slide", 0 ],
            "d-3::obj-24::obj-8": [ "sync_invert[3]", "sync_inv", 0 ],
            "d-3::obj-4::obj-1": [ "live.text", "sync_inv", 0 ],
            "d-3::obj-4::obj-10": [ "wfg_pw[1]", "PW", 0 ],
            "d-3::obj-4::obj-137": [ "wfg_wf[1]", "waveform", 0 ],
            "d-3::obj-4::obj-139": [ "sync_pos", "position", 0 ],
            "d-3::obj-4::obj-29": [ "wfg_freq[2]", "Freq", 0 ],
            "d-3::obj-4::obj-3": [ "sync_time", "Time", 0 ],
            "d-3::obj-4::obj-4": [ "wfg_freq[1]", "Phase", 0 ],
            "d-3::obj-4::obj-60": [ "clrizer_color[1]", "color", 0 ],
            "d-3::obj-9::obj-13": [ "myGrads", "live.menu", 0 ],
            "d-3::obj-9::obj-17": [ "live.numbox", "live.numbox", 0 ],
            "d-3::obj-9::obj-22": [ "clpick", "live.text", 0 ],
            "d-3::obj-9::obj-34": [ "live.tab", "live.tab", 0 ],
            "d-4::obj-11": [ "m_lift", "m_lift", 0 ],
            "d-4::obj-14": [ "m_gamma", "m_gamma", 0 ],
            "d-4::obj-15": [ "m_gain", "m_gain", 0 ],
            "d-4::obj-49": [ "r_lift", "r_lift", 0 ],
            "d-4::obj-58": [ "r_gamma", "r_gamma", 0 ],
            "d-4::obj-59": [ "r_gain", "r_gain", 0 ],
            "d-4::obj-67": [ "g_gain", "g_gain", 0 ],
            "d-4::obj-68": [ "g_gamma", "g_gamma", 0 ],
            "d-4::obj-69": [ "g_lift", "live.dial", 0 ],
            "d-4::obj-71": [ "b_gain", "b_gain", 0 ],
            "d-4::obj-72": [ "b_gamma", "b_gamma", 0 ],
            "d-4::obj-73": [ "b_lift", "b_lift", 0 ],
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
                    "parameter_longname": "sync_invert[2]"
                },
                "d-3::obj-24::obj-8": {
                    "parameter_longname": "sync_invert[3]"
                },
                "d-3::obj-4::obj-10": {
                    "parameter_longname": "wfg_pw[1]"
                },
                "d-3::obj-4::obj-137": {
                    "parameter_longname": "wfg_wf[1]"
                },
                "d-3::obj-4::obj-29": {
                    "parameter_longname": "wfg_freq[2]"
                }
            },
            "inherited_shortname": 1
        },
        "autosave": 0
    }
}