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
                    "text": "Grain",
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
                    "text": "Stochastic grain field with per-grain displacement and luma gating",
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
                        274.5
                    ],
                    "text": "External Control Messages\n\ndensity [0.0 \u2013 1.0]\namount [0.0 \u2013 2.0]\npersistence [0.0 \u2013 1.0]\nfade [0.0 \u2013 4.0]\nsize [0.0 \u2013 1.0]\nsize_var [0.0 \u2013 1.0]\nshape [0.0 \u2013 1.0]\nsoftness [0.0 \u2013 5.0]\njitter [0.0 \u2013 2.0]\nch_diverge [0.0 \u2013 1.0]\nluma_gate [-1.0 \u2013 1.0]\ndisplace [0.0 \u2013 0.5]\nedge_mode [Clear/Clamp/Wrap/Mirror]\nfield [0.0 \u2013 5.0]\nsv_seed [0.0 \u2013 5.0]\nbypass [0 / 1]",
                    "linecount": 18,
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
                        464.5,
                        270.0,
                        130.0
                    ],
                    "text": "References\n\nSee docs/f-reference/f_grain.md for the full parameter\nreference. Note: this module predates build_patcher.py\n(patcher added 2026-05-23, build system 2026-05-30) --\nsrc/f_grain/definition.py is a record of the real\n.maxpat, not a generator for it; never regenerate f_grain\nvia build_patcher.py.",
                    "fontsize": 12.0,
                    "linecount": 8,
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
                    "name": "f_grain.maxpat",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "offset": [
                        0.0,
                        0.0
                    ],
                    "outlettype": [
                        "jit_gl_texture",
                        "jit_gl_texture"
                    ],
                    "patching_rect": [
                        338.0,
                        190.0,
                        154.0,
                        91.0
                    ],
                    "viewvisibility": 1,
                    "varname": "f_grain"
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
            "d-4::obj-11": [
                "density",
                "density",
                0
            ],
            "d-4::obj-13": [
                "amount",
                "amount",
                0
            ],
            "d-4::obj-15": [
                "persistence",
                "persistence",
                0
            ],
            "d-4::obj-2": [
                "fade",
                "fade",
                0
            ],
            "d-4::obj-25": [
                "size",
                "size",
                0
            ],
            "d-4::obj-27": [
                "size_var",
                "size_var",
                0
            ],
            "d-4::obj-29": [
                "shape",
                "shape",
                0
            ],
            "d-4::obj-31": [
                "softness",
                "softness",
                0
            ],
            "d-4::obj-37": [
                "jitter",
                "jitter",
                0
            ],
            "d-4::obj-40": [
                "ch_diverge",
                "ch_diverge",
                0
            ],
            "d-4::obj-60": [
                "luma_gate",
                "luma_gate",
                0
            ],
            "d-4::obj-63": [
                "displace",
                "displace",
                0
            ],
            "d-4::obj-71": [
                "edge_mode",
                "edge_mode",
                0
            ],
            "d-4::obj-43": [
                "field",
                "field",
                0
            ],
            "d-4::obj-82": [
                "sv_seed",
                "sv_seed",
                0
            ],
            "inherited_shortname": 1
        },
        "autosave": 0
    }
}