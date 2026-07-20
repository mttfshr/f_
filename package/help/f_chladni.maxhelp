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
                    "text": "Chladni",
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
                    "text": "Single-resonance Chladni plate modal synthesis -- audio-to-vecfield transducer",
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
                        198.25
                    ],
                    "text": "External Control Messages\n\nnote [0.0 \u2013 127.0]\namp [0.0 \u2013 1.0]\ndishradius [0.1 \u2013 4.0]\nreflectamt [0.0 \u2013 1.0]\nlinesharpness [0.1 \u2013 100.0]\nph0 [-6.2832 \u2013 6.2832]\nspread [0.1 \u2013 1.0]\nmode [0.0 \u2013 1.0]\nview_mode [0.0 \u2013 1.0]\ngain [0.0 \u2013 20.0]\nbypass [0 / 1]",
                    "linecount": 13,
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
                        388.25,
                        270.0,
                        120.0
                    ],
                    "text": "References\n\nBessel-function large-x asymptotic approximation of\ncircular membrane modes -- standard physics, not from a\nspecific source. See docs/f-reference/f_chladni.md for\nthe full algorithm, outlet contract, and companion-patch\nnotes.",
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
                    "id": "d-4",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_chladni.maxpat",
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
                    "varname": "f_chladni"
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
                        69.0
                    ],
                    "text": "Feed out2 (vecfield) into f_caustic or\nf_vf_warp -- or out3 (magnitude) into\nf_weave's scalar inlet.",
                    "fontsize": 12.0,
                    "linecount": 3,
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
                "note",
                "note",
                0
            ],
            "d-4::obj-23": [
                "amp",
                "amp",
                0
            ],
            "d-4::obj-26": [
                "dishradius",
                "dishradius",
                0
            ],
            "d-4::obj-29": [
                "reflectamt",
                "reflectamt",
                0
            ],
            "d-4::obj-32": [
                "linesharpness",
                "linesharpness",
                0
            ],
            "d-4::obj-35": [
                "ph0",
                "ph0",
                0
            ],
            "d-4::obj-38": [
                "spread",
                "spread",
                0
            ],
            "d-4::obj-41": [
                "mode",
                "mode",
                0
            ],
            "d-4::obj-44": [
                "view_mode",
                "view_mode",
                0
            ],
            "d-4::obj-47": [
                "gain",
                "gain",
                0
            ],
            "inherited_shortname": 1
        },
        "autosave": 0
    }
}