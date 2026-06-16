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
        "rect": [ 162.0, 137.0, 871.0, 780.0 ],
        "gridonopen": 2,
        "toolbarvisible": 0,
        "helpsidebarclosed": 1,
        "boxes": [
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
                    "name": "f_vf_vortex.maxpat",
                    "numinlets": 5,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 580.0, 184.0, 196.0, 160.0 ],
                    "varname": "f_vf_vortex",
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
                    "patching_rect": [ 586.0, 482.0, 236.0, 249.0 ],
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
                    "text": "Streak",
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
                    "text": "Directional smear along vecfield streamlines",
                    "varname": "autohelp_top_digest[3]"
                }
            },
            {
                "box": {
                    "bgcolor": [ 0.2, 0.2, 0.2, 0.0 ],
                    "fontface": 0,
                    "fontname": "Ableton Sans Light",
                    "id": "d-8",
                    "linecount": 9,
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 15.0, 150.0, 132.0, 136.0 ],
                    "saved_attribute_attributes": {
                        "textcolor": {
                            "expression": "themecolor.live_control_fg"
                        }
                    },
                    "text": "External Control Messages\n\nstrength [0.0 -- 1.0]\nlength [0.0 -- 20.0]\nfalloff [0.0 -- 2.5]\ncolor_shift [0.0 -- 20.0]\nbypass [0 / 1]"
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
                    "patching_rect": [ 15.0, 330.0, 270.0, 208.0 ],
                    "text": "References\n\nStreamline integration: 8-step backward walk\nalong vecfield in UV space.\n\nfalloff > 1 extrapolates to negative tail weights\n-- contrast-boosted leading edge; expressive\nat high values.\n\ncolor_shift offsets R and B in opposite directions\nalong the streak X axis -- chromatic aberration\nfollows field geometry.\n\nOriginal derivation -- not from external source."
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
                    "name": "f_vf_streak.maxpat",
                    "numinlets": 2,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 338.0, 293.75, 154.0, 91.0 ],
                    "varname": "f_vf_streak",
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
                    "patching_rect": [ 338.0, 482.0, 236.0, 249.0 ],
                    "viewvisibility": 1
                }
            }
        ],
        "lines": [
            {
                "patchline": {
                    "destination": [ "d-4", 0 ],
                    "order": 1,
                    "source": [ "d-3", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-18", 0 ],
                    "order": 0,
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
                    "destination": [ "d-4", 1 ],
                    "source": [ "obj-18", 0 ]
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
            "d-4::obj-20": [ "strength", "strength", 0 ],
            "d-4::obj-23": [ "length", "length", 0 ],
            "d-4::obj-26": [ "falloff", "falloff", 0 ],
            "d-4::obj-29": [ "color_shift", "color_shift", 0 ],
            "obj-18::obj-20": [ "cx", "cx", 0 ],
            "obj-18::obj-23": [ "cy", "cy", 0 ],
            "obj-18::obj-26": [ "convergence", "convergence", 0 ],
            "obj-18::obj-29": [ "curl", "curl", 0 ],
            "obj-18::obj-32": [ "falloff[1]", "falloff", 0 ],
            "obj-18::obj-35": [ "cx_amt", "cx_amt", 0 ],
            "obj-18::obj-38": [ "cy_amt", "cy_amt", 0 ],
            "obj-18::obj-41": [ "convergence_amt", "convergence_amt", 0 ],
            "obj-18::obj-44": [ "curl_amt", "curl_amt", 0 ],
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
                },
                "obj-18::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-18::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-18::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-18::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-18::obj-32": {
                    "parameter_invisible": 0,
                    "parameter_longname": "falloff[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "falloff",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-18::obj-35": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-18::obj-38": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-18::obj-41": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-18::obj-44": {
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