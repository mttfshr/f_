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
                    "text": "Warp",
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
                    "text": "UV warp via f_vecfield -- displaces a source texture along field streamlines",
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
                        122.0
                    ],
                    "text": "External Control Messages\n\nstrength [0.0 \u2013 1.5]\nbypass [0 / 1]",
                    "linecount": 4,
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
                        312.0,
                        270.0,
                        120.0
                    ],
                    "text": "References\n\nSee docs/f-reference/f_vf_warp.md for the full\nalgorithm and a known bug (bypass does not gate\nthe out1 outlet -- see doc's Known Bug section).",
                    "fontsize": 12.0,
                    "linecount": 5,
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
                    "name": "f_vf_warp.maxpat",
                    "numinlets": 2,
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
                    "varname": "f_vf_warp"
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
            },
            {
                "box": {
                    "bgcolor": [
                        0.0,
                        0.0,
                        0.0,
                        0.0
                    ],
                    "fontface": 0,
                    "fontname": "Ableton Sans Light",
                    "id": "d-9",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [
                        500.0,
                        321.0,
                        210.0,
                        51.0
                    ],
                    "text": "Feed a vecfield into inlet 1 from:\nf_vf_vortex or f_vf_fieldmap.",
                    "fontsize": 12.0,
                    "linecount": 2,
                    "bubble": 1
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
                "strength",
                "strength",
                0
            ],
            "inherited_shortname": 1
        },
        "autosave": 0
    }
}