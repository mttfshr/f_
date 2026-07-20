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
        "rect": [
            100.0,
            99.0,
            871.0,
            780.0
        ],
        "gridonopen": 2,
        "toolbarvisible": 0,
        "helpsidebarclosed": 1,
        "boxes": [
            {
                "box": {
                    "bgcolor": [
                        0.2,
                        0.2,
                        0.2,
                        0.0
                    ],
                    "fontface": 0,
                    "fontname": "Ableton Sans Medium",
                    "id": "h-1",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [
                        15.0,
                        15.0,
                        270.0,
                        50.0
                    ],
                    "text": "Lens",
                    "fontsize": 36.0,
                    "varname": "autohelp_top_digest[4]",
                    "saved_attribute_attributes": {
                        "textcolor": {
                            "expression": "themecolor.live_control_fg"
                        }
                    }
                }
            },
            {
                "box": {
                    "bgcolor": [
                        0.2,
                        0.2,
                        0.2,
                        0.0
                    ],
                    "fontface": 0,
                    "fontname": "Ableton Sans Light",
                    "id": "h-2",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [
                        15.0,
                        75.0,
                        270.0,
                        40.0
                    ],
                    "text": "Filmic lens processor -- aberration, distortion, transmission, ghosting, halation, tilt-shift",
                    "fontsize": 14.0,
                    "varname": "autohelp_top_digest[3]",
                    "linecount": 2,
                    "saved_attribute_attributes": {
                        "textcolor": {
                            "expression": "themecolor.live_control_fg"
                        }
                    }
                }
            },
            {
                "box": {
                    "bgcolor": [
                        0.2,
                        0.2,
                        0.2,
                        0.0
                    ],
                    "fontface": 0,
                    "fontname": "Ableton Sans Light",
                    "id": "d-8",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [
                        15.0,
                        150.0,
                        270.0,
                        305.0
                    ],
                    "text": "External Control Messages\n\naberration [-1.0 \u2013 1.0]\ndistortion [-1.0 \u2013 1.0]\ntransmission [-1.0 \u2013 1.0]\naberration_mod [0.0 \u2013 1.0]\ndistortion_mod [0.0 \u2013 1.0]\ntransmission_mod [0.0 \u2013 1.0]\nsurface_mod [0.0 \u2013 5.0]\nghost [-1.0 \u2013 1.0]\nghost_count [1 \u2013 4]\nghost_spacing [-1.0 \u2013 1.0]\nhalation [0.0 \u2013 1.0]\nhalation_threshold [0.0 \u2013 1.0]\ntilt [0.0 \u2013 1.0]\ntilt_axis [0.0 \u2013 1.0]\ntilt_pos [0.0 \u2013 1.0]\nslope [0.0 \u2013 1.0]\nmode [linear / radial]\nbypass [0 / 1]",
                    "linecount": 20,
                    "saved_attribute_attributes": {
                        "textcolor": {
                            "expression": "themecolor.live_control_fg"
                        }
                    }
                }
            },
            {
                "box": {
                    "bgcolor": [
                        0.2,
                        0.2,
                        0.2,
                        0.0
                    ],
                    "fontface": 0,
                    "fontname": "Ableton Sans Light",
                    "id": "r-1",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [
                        15.0,
                        495.0,
                        270.0,
                        120.0
                    ],
                    "text": "References\n\nSee docs/f-reference/f_lens.md for the full algorithm,\nsignal chain, and a known bug (bypass gates lens_pix\nonly -- halation and tilt-shift stay live regardless).\nTilt-shift is slated for extraction to f_focus once that\nmodule ships.",
                    "fontsize": 12.0,
                    "linecount": 7,
                    "saved_attribute_attributes": {
                        "textcolor": {
                            "expression": "themecolor.live_control_fg"
                        }
                    }
                }
            },
            {
                "box": {
                    "id": "obj-1",
                    "maxclass": "panel",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [
                        0.0,
                        -2.0,
                        303.0,
                        765.0
                    ]
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
                    "offset": [
                        0.0,
                        0.0
                    ],
                    "outlettype": [
                        "jit_gl_texture"
                    ],
                    "patching_rect": [
                        338.0,
                        23.75,
                        296.4,
                        125.5
                    ],
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
                    "name": "f_lens.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [
                        0.0,
                        0.0
                    ],
                    "outlettype": [
                        "jit_gl_texture"
                    ],
                    "patching_rect": [
                        338.0,
                        190.0,
                        154.0,
                        91.0
                    ],
                    "viewvisibility": 1,
                    "varname": "f_lens"
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
                    "offset": [
                        0.0,
                        0.0
                    ],
                    "outlettype": [
                        "jit_gl_texture"
                    ],
                    "patching_rect": [
                        338.0,
                        301.0,
                        236.0,
                        249.0
                    ],
                    "viewvisibility": 1
                }
            }
        ],
        "lines": [
            {
                "patchline": {
                    "destination": [
                        "d-4",
                        0
                    ],
                    "source": [
                        "d-3",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "d-5",
                        0
                    ],
                    "source": [
                        "d-4",
                        0
                    ]
                }
            }
        ],
        "parameters": {
            "d-4::obj-20": [
                "aberration",
                "aberration",
                0
            ],
            "d-4::obj-23": [
                "distortion",
                "distortion",
                0
            ],
            "d-4::obj-26": [
                "transmission",
                "transmission",
                0
            ],
            "d-4::obj-29": [
                "aberration_mod",
                "aberration_mod",
                0
            ],
            "d-4::obj-32": [
                "distortion_mod",
                "distortion_mod",
                0
            ],
            "d-4::obj-35": [
                "transmission_mod",
                "transmission_mod",
                0
            ],
            "d-4::obj-38": [
                "surface_mod",
                "surface_mod",
                0
            ],
            "d-4::obj-41": [
                "ghost",
                "ghost",
                0
            ],
            "d-4::obj-44": [
                "ghost_count",
                "ghost_count",
                0
            ],
            "d-4::obj-47": [
                "ghost_spacing",
                "ghost_spacing",
                0
            ],
            "d-4::obj-50": [
                "halation",
                "halation",
                0
            ],
            "d-4::obj-53": [
                "halation_threshold",
                "halation_threshold",
                0
            ],
            "d-4::obj-raw-3": [
                "tilt",
                "tilt",
                0
            ],
            "d-4::obj-raw-4": [
                "tilt_axis",
                "tilt_axis",
                0
            ],
            "d-4::obj-raw-5": [
                "tilt_pos",
                "tilt_pos",
                0
            ],
            "d-4::obj-raw-6": [
                "slope",
                "slope",
                0
            ],
            "d-4::obj-raw-7": [
                "mode",
                "mode",
                0
            ],
            "inherited_shortname": 1
        },
        "autosave": 0
    }
}