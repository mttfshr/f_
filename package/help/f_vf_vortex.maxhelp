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
                    "text": "Vortex",
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
                    "text": "Single fixed-point vortex field -- continuously variable sink/source/spiral topology",
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
                        183.0
                    ],
                    "text": "External Control Messages\n\ncx [0.0 \u2013 1.0]\ncy [0.0 \u2013 1.0]\nconvergence [-1.0 \u2013 1.0]\ncurl [-1.0 \u2013 1.0]\nfalloff [0.0 \u2013 10.0]\ncx_amt [0.0 \u2013 1.0]\ncy_amt [0.0 \u2013 1.0]\nconvergence_amt [0.0 \u2013 1.0]\ncurl_amt [0.0 \u2013 1.0]\nbypass [0 / 1]",
                    "linecount": 12,
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
                        373.0,
                        270.0,
                        120.0
                    ],
                    "text": "References\n\nSee docs/f-reference/f_vf_vortex.md and\ndocs/f-reference/f_vecfield_type.md for the full field\nencoding and type contract.",
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
                    "id": "d-4",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_vf_vortex.maxpat",
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
                        24.0,
                        154.0,
                        91.0
                    ],
                    "viewvisibility": 1,
                    "varname": "f_vf_vortex"
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
                        135.0,
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
                        155.0,
                        210.0,
                        51.0
                    ],
                    "text": "Feed into f_vf_warp, f_caustic, or\nf_vf_streak to visualize the field.",
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
                "cx",
                "cx",
                0
            ],
            "d-4::obj-23": [
                "cy",
                "cy",
                0
            ],
            "d-4::obj-26": [
                "convergence",
                "convergence",
                0
            ],
            "d-4::obj-29": [
                "curl",
                "curl",
                0
            ],
            "d-4::obj-32": [
                "falloff",
                "falloff",
                0
            ],
            "d-4::obj-35": [
                "cx_amt",
                "cx_amt",
                0
            ],
            "d-4::obj-38": [
                "cy_amt",
                "cy_amt",
                0
            ],
            "d-4::obj-41": [
                "convergence_amt",
                "convergence_amt",
                0
            ],
            "d-4::obj-44": [
                "curl_amt",
                "curl_amt",
                0
            ],
            "inherited_shortname": 1
        },
        "autosave": 0
    }
}