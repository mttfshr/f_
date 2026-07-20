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
                    "text": "Masonry",
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
                    "text": "Parametric masonry texture -- courses, bond, mortar, drift, per-course color",
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
                    "text": "External Control Messages\n\ncourses [0.0 \u2013 100.0]\nbond [0.0 \u2013 100.0]\noffset [0.0 \u2013 1.0]\nangle [-360.0 \u2013 360.0]\nskip [0.0 \u2013 1.0]\nregularity [0.0 \u2013 1.0]\ndrift [0.0 \u2013 4.0]\nphase [0.0 \u2013 1.0]\nspeed_var [0.0 \u2013 10.0]\nmortar [0.0 \u2013 1.0]\nsoftness [0.0 \u2013 1.0]\nwidth [-2.0 \u2013 2.0]\nroundness [-2.0 \u2013 2.0]\ncourse_color [0.0 \u2013 1.0]\nbrick_color [0.0 \u2013 1.0]\ncourse_seed [0.0 \u2013 999.0]\nbrick_seed [0.0 \u2013 999.0]\nbypass [0 / 1]",
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
                    "text": "References\n\nSee docs/f-reference/f_masonry.md for the full ADR-7\ncandidate-search algorithm, the three modulation-inlet\ncontract, and known loose threads (incl. a dead\n`quantize` control left in the live .maxpat, unwired\nsince the 2026-07-05 redesign).",
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
                    "name": "f_masonry.maxpat",
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
                    "varname": "f_masonry"
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
                        69.0
                    ],
                    "text": "Pairs well downstream with:\nf_droste, f_mobius, or f_lens for\nspatial deformation.",
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
                "courses",
                "courses",
                0
            ],
            "d-4::obj-21": [
                "bond",
                "bond",
                0
            ],
            "d-4::obj-22": [
                "offset",
                "offset",
                0
            ],
            "d-4::obj-23": [
                "angle",
                "angle",
                0
            ],
            "d-4::obj-24": [
                "skip",
                "skip",
                0
            ],
            "d-4::obj-26": [
                "regularity",
                "regularity",
                0
            ],
            "d-4::obj-27": [
                "drift",
                "drift",
                0
            ],
            "d-4::obj-28": [
                "phase",
                "phase",
                0
            ],
            "d-4::obj-29": [
                "speed_var",
                "speed_var",
                0
            ],
            "d-4::obj-30": [
                "mortar",
                "mortar",
                0
            ],
            "d-4::obj-31": [
                "softness",
                "softness",
                0
            ],
            "d-4::obj-32": [
                "width",
                "width",
                0
            ],
            "d-4::obj-33": [
                "roundness",
                "roundness",
                0
            ],
            "d-4::obj-35": [
                "course_color",
                "course_color",
                0
            ],
            "d-4::obj-36": [
                "brick_color",
                "brick_color",
                0
            ],
            "d-4::obj-90": [
                "course_seed",
                "course_seed",
                0
            ],
            "d-4::obj-91": [
                "brick_seed",
                "brick_seed",
                0
            ],
            "inherited_shortname": 1
        },
        "autosave": 0
    }
}