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
                    "text": "Vary",
                    "saved_attribute_attributes": {
                        "textcolor": {
                            "expression": "themecolor.live_control_fg"
                        }
                    },
                    "fontsize": 36.0,
                    "varname": "autohelp_top_digest[4]"
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
                    "text": "Control-side variation: a transparent wire that adds chance, wobble and trim to chosen parameters",
                    "saved_attribute_attributes": {
                        "textcolor": {
                            "expression": "themecolor.live_control_fg"
                        }
                    },
                    "fontsize": 14.0,
                    "varname": "autohelp_top_digest[3]"
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
                        200.0
                    ],
                    "text": "External Control Messages\n\n(send these to inlet 1)\nroll\nseed [any number]\namount [0.0 – 4.0]\nchance [0.0 – 1.0]\nwobble [0.0 – 1.0]\nslew [0 – 2000] ms\nadd (a blank row)\nclear\ndump, debug [0 / 1]",
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
                    "id": "i-1",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [
                        15.0,
                        360.0,
                        270.0,
                        330.0
                    ],
                    "text": "Inlets, outlets and rows\n\nIn 0: bases, any <param> <value> message. Every base goes out of EVERY outlet, so with no rows vary is a plain wire.\nIn 1: vary's own messages (above).\nOut 1-4: destinations. Wire each to a module's left inlet.\n\nPress + to add a row. A row varies one param on one outlet: out, param (a menu of the names seen on In 0), lo and hi (blank = no clamp, amount is then a share of the base), amt and chn (amount and chance in percent), wob (slow drift), trim (a fixed offset), mode (off: new draw each roll, on: drunk walk), sign (both ways, up only, down only), grp (0 none, 1-4 share a draw; the g dials set how much). Roll draws; seed N recalls a draw.\n\nSave: the rows, dials and seed are stored by the patch's pattrstorage (the Vsynth presets module): store a preset, then recall it. A plain patch save keeps nothing.",
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
                        700.0,
                        270.0,
                        56.0
                    ],
                    "text": "References\n\nDesigned in development -- no outside sources. Per-row random streams are derived from one seed, so a draw can be recalled.",
                    "saved_attribute_attributes": {
                        "textcolor": {
                            "expression": "themecolor.live_control_fg"
                        }
                    },
                    "fontsize": 12.0
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
                    "bgcolor": [
                        0.0,
                        0.0,
                        0.0,
                        0.0
                    ],
                    "fontface": 0,
                    "fontname": "Ableton Sans Light",
                    "id": "d-c1",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [
                        338.0,
                        12.0,
                        380.0,
                        22.0
                    ],
                    "text": "bases in (try x, then add a row: out 1, param x, press roll)",
                    "saved_attribute_attributes": {
                        "textcolor": {
                            "expression": "themecolor.live_control_fg"
                        }
                    },
                    "bubble": 1,
                    "bubbleside": 1
                }
            },
            {
                "box": {
                    "id": "d-m1",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "patching_rect": [
                        338.0,
                        40.0,
                        52.0,
                        24.0
                    ],
                    "text": "x 0.5",
                    "fontname": "Ableton Sans Light",
                    "fontsize": 13.0
                }
            },
            {
                "box": {
                    "id": "d-m2",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "patching_rect": [
                        398.0,
                        40.0,
                        52.0,
                        24.0
                    ],
                    "text": "x 0.8",
                    "fontname": "Ableton Sans Light",
                    "fontsize": 13.0
                }
            },
            {
                "box": {
                    "id": "d-m3",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "patching_rect": [
                        458.0,
                        40.0,
                        64.0,
                        24.0
                    ],
                    "text": "hue 0.3",
                    "fontname": "Ableton Sans Light",
                    "fontsize": 13.0
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
                    "id": "d-c2",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [
                        540.0,
                        12.0,
                        180.0,
                        22.0
                    ],
                    "text": "metro for wobble and slew:",
                    "saved_attribute_attributes": {
                        "textcolor": {
                            "expression": "themecolor.live_control_fg"
                        }
                    },
                    "bubble": 1,
                    "bubbleside": 1
                }
            },
            {
                "box": {
                    "id": "d-t",
                    "maxclass": "toggle",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [
                        "int"
                    ],
                    "parameter_enable": 0,
                    "patching_rect": [
                        540.0,
                        42.0,
                        22.0,
                        22.0
                    ]
                }
            },
            {
                "box": {
                    "id": "d-me",
                    "maxclass": "newobj",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "patching_rect": [
                        572.0,
                        42.0,
                        70.0,
                        22.0
                    ],
                    "text": "qmetro 33",
                    "fontname": "Ableton Sans Light",
                    "fontsize": 13.0
                }
            },
            {
                "box": {
                    "id": "d-s",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "outlettype": [],
                    "patching_rect": [
                        650.0,
                        42.0,
                        52.0,
                        22.0
                    ],
                    "text": "s draw",
                    "fontname": "Ableton Sans Light",
                    "fontsize": 13.0
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
                    "name": "f_util_vary.maxpat",
                    "numinlets": 2,
                    "numoutlets": 4,
                    "offset": [
                        0.0,
                        0.0
                    ],
                    "outlettype": [
                        "",
                        "",
                        "",
                        ""
                    ],
                    "patching_rect": [
                        338.0,
                        90.0,
                        372.0,
                        488.0
                    ],
                    "viewvisibility": 1,
                    "varname": "f_util_vary"
                }
            },
            {
                "box": {
                    "id": "d-o0",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "patching_rect": [
                        338.0,
                        590.0,
                        86.0,
                        24.0
                    ],
                    "text": "(out 1)",
                    "fontname": "Ableton Sans Light",
                    "fontsize": 13.0
                }
            },
            {
                "box": {
                    "id": "d-o1",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "patching_rect": [
                        431.0,
                        590.0,
                        86.0,
                        24.0
                    ],
                    "text": "(out 2)",
                    "fontname": "Ableton Sans Light",
                    "fontsize": 13.0
                }
            },
            {
                "box": {
                    "id": "d-o2",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "patching_rect": [
                        524.0,
                        590.0,
                        86.0,
                        24.0
                    ],
                    "text": "(out 3)",
                    "fontname": "Ableton Sans Light",
                    "fontsize": 13.0
                }
            },
            {
                "box": {
                    "id": "d-o3",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "patching_rect": [
                        617.0,
                        590.0,
                        86.0,
                        24.0
                    ],
                    "text": "(out 4)",
                    "fontname": "Ableton Sans Light",
                    "fontsize": 13.0
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
                    "id": "d-c3",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [
                        338.0,
                        622.0,
                        380.0,
                        22.0
                    ],
                    "text": "outlets 1-4: the base plus each row's variation",
                    "saved_attribute_attributes": {
                        "textcolor": {
                            "expression": "themecolor.live_control_fg"
                        }
                    },
                    "bubble": 1,
                    "bubbleside": 1
                }
            }
        ],
        "lines": [
            {
                "patchline": {
                    "source": [
                        "d-m1",
                        0
                    ],
                    "destination": [
                        "d-4",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "d-m2",
                        0
                    ],
                    "destination": [
                        "d-4",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "d-m3",
                        0
                    ],
                    "destination": [
                        "d-4",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "d-t",
                        0
                    ],
                    "destination": [
                        "d-me",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "d-me",
                        0
                    ],
                    "destination": [
                        "d-s",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "d-4",
                        0
                    ],
                    "destination": [
                        "d-o0",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "d-4",
                        1
                    ],
                    "destination": [
                        "d-o1",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "d-4",
                        2
                    ],
                    "destination": [
                        "d-o2",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "d-4",
                        3
                    ],
                    "destination": [
                        "d-o3",
                        0
                    ]
                }
            }
        ],
        "autosave": 0
    }
}