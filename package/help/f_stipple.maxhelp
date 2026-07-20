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
                    "text": "Stipple",
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
                    "text": "2D hash field stipple -- dither/density or luma-driven displacement",
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
                    "text": "External Control Messages\n\nfreq [0.0 \u2013 20.0]\ncoarseness [1.0 \u2013 100.0]\nanisotropy [0.0 \u2013 4.0]\nangle [-360.0 \u2013 360.0]\nzoom [0.1 \u2013 4.0]\nthreshold [0.0 \u2013 2.0]\ncolorize [0.0 \u2013 1.0]\nalong_phase [-1.0 \u2013 1.0]\nacross_phase [-1.0 \u2013 1.0]\nsoftness [0.0 \u2013 2.0]\nbypass [0 / 1]",
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
                    "text": "References\n\nSee docs/f-reference/f_stipple.md for the full dual-mode\n(dither/displacement) algorithm and the source-mode\nversus processor-mode auto-detection via vs_inState.",
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
                    "name": "f_stipple.maxpat",
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
                    "varname": "f_stipple"
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
                    "text": "Works best with a textured/moving\nsource -- try f_grain or live camera.",
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
                "freq",
                "freq",
                0
            ],
            "d-4::obj-23": [
                "coarseness",
                "coarseness",
                0
            ],
            "d-4::obj-26": [
                "anisotropy",
                "anisotropy",
                0
            ],
            "d-4::obj-29": [
                "angle",
                "angle",
                0
            ],
            "d-4::obj-32": [
                "zoom",
                "zoom",
                0
            ],
            "d-4::obj-35": [
                "threshold",
                "threshold",
                0
            ],
            "d-4::obj-38": [
                "colorize",
                "colorize",
                0
            ],
            "d-4::obj-41": [
                "along_phase",
                "along_phase",
                0
            ],
            "d-4::obj-44": [
                "across_phase",
                "across_phase",
                0
            ],
            "d-4::obj-47": [
                "softness",
                "softness",
                0
            ],
            "inherited_shortname": 1
        },
        "autosave": 0
    }
}