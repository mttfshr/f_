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
                    "text": "Wilson-Cowan",
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
                    "text": "Noise-sustained hallucination generator -- a living labyrinth; the drive inlet makes it see",
                    "fontsize": 14.0,
                    "varname": "autohelp_top_digest[3]",
                    "linecount": 3,
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
                    "text": "External Control Messages\n\nrate [0.0 \u2013 1.0]\ngrain [1.0 \u2013 4.0]\naspect [1.2 \u2013 2.2]\ndrive_gain [0.0 \u2013 2.0]\nenergy [0.0 \u2013 2.0]\nhabituation [0.0 \u2013 1.5]\nsharp [0.0 \u2013 1.0]\nexcite [-0.3 \u2013 0.8]\nzoom [2 \u2013 16]\ntwist [2 \u2013 8, int]\nfovea [0.1 \u2013 2.0]\nbypass [0 / 1]",
                    "linecount": 14,
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
                        336.5,
                        270.0,
                        160.0
                    ],
                    "text": "References\n\nWilson & Cowan (1972). Excitatory and inhibitory\ninteractions in localized populations of model neurons.\nBiophys. J. 12:1-24.\n\nErmentrout & Cowan (1979). A mathematical theory of\nvisual hallucination patterns. Biol. Cybern. 34:137-150.\n(the log-polar retinotopic map and the form taxonomy).\n\nSettled noise-sustained model after Michael Rule's\nwebgpgpu Wilson-Cowan demo. Full algorithm, gate\ndecisions and verification: docs/f-reference/f_wc.md",
                    "fontsize": 12.0,
                    "linecount": 11,
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
                    "name": "f_wc.maxpat",
                    "numinlets": 2,
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
                        247.0,
                        212.0
                    ],
                    "viewvisibility": 1,
                    "varname": "f_wc"
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
                        155.0,
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
                        560.0,
                        38.0,
                        230.0,
                        69.0
                    ],
                    "text": "Second inlet is the drive (optional). Feed a\nstructured scene texture there and turn Drive up ~1.5\nto make the hallucination see it; at 0 it runs free.",
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
                "rate",
                "rate",
                0
            ],
            "d-4::obj-23": [
                "grain",
                "grain",
                0
            ],
            "d-4::obj-26": [
                "drive_gain",
                "drive_gain",
                0
            ],
            "d-4::obj-29": [
                "sharp",
                "sharp",
                0
            ],
            "inherited_shortname": 1
        },
        "autosave": 0
    }
}
