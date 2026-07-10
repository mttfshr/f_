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
            100.0,
            800.0,
            600.0
        ],
        "openinpresentation": 1,
        "boxes": [
            {
                "box": {
                    "id": "obj-1",
                    "maxclass": "inlet",
                    "comment": "texture / control",
                    "index": 0,
                    "numinlets": 0,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "patching_rect": [
                        30.0,
                        30.0,
                        30.0,
                        30.0
                    ]
                }
            },
            {
                "box": {
                    "id": "obj-2",
                    "maxclass": "outlet",
                    "comment": "X channel (R)",
                    "index": 0,
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [
                        30.0,
                        500.0,
                        30.0,
                        30.0
                    ]
                }
            },
            {
                "box": {
                    "id": "obj-201",
                    "maxclass": "outlet",
                    "comment": "Y channel (G)",
                    "index": 1,
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [
                        100.0,
                        500.0,
                        30.0,
                        30.0
                    ]
                }
            },
            {
                "box": {
                    "id": "obj-3",
                    "maxclass": "newobj",
                    "numinlets": 3,
                    "numoutlets": 3,
                    "outlettype": [
                        "",
                        "",
                        ""
                    ],
                    "patching_rect": [
                        200.0,
                        90.0,
                        215.0,
                        22.0
                    ],
                    "text": "routepass jit_gl_texture jit_matrix"
                }
            },
            {
                "box": {
                    "id": "obj-4",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "patching_rect": [
                        200.0,
                        130.0,
                        150.0,
                        22.0
                    ],
                    "text": "route bipolar"
                }
            },
            {
                "box": {
                    "id": "obj-5",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "outlettype": [
                        "jit_gl_texture",
                        "jit_gl_texture",
                        ""
                    ],
                    "patcher": {
                        "fileversion": 1,
                        "appversion": {
                            "major": 9,
                            "minor": 1,
                            "revision": 4,
                            "architecture": "x64",
                            "modernui": 1
                        },
                        "classnamespace": "jit.gen",
                        "rect": [
                            100.0,
                            100.0,
                            700.0,
                            600.0
                        ],
                        "boxes": [
                            {
                                "box": {
                                    "id": "gen-obj-1",
                                    "maxclass": "newobj",
                                    "numinlets": 0,
                                    "numoutlets": 1,
                                    "outlettype": [
                                        ""
                                    ],
                                    "patching_rect": [
                                        22.0,
                                        30.0,
                                        28.0,
                                        22.0
                                    ],
                                    "text": "in 1"
                                }
                            },
                            {
                                "box": {
                                    "code": "Param bipolar(0.0);\nParam bypass(0.0);\n\nr = sample(in1, norm).x;\ng = sample(in1, norm).y;\n\nr_out = mix(r, r * 2.0 - 1.0, bipolar);\ng_out = mix(g, g * 2.0 - 1.0, bipolar);\n\nx_ch = vec(r_out, r_out, r_out, 1.0);\ny_ch = vec(g_out, g_out, g_out, 1.0);\n\nout1 = mix(x_ch, sample(in1, norm), bypass);\nout2 = mix(y_ch, sample(in1, norm), bypass);\n",
                                    "fontface": 0,
                                    "fontname": "<Monospaced>",
                                    "fontsize": 12.0,
                                    "id": "gen-obj-2",
                                    "maxclass": "codebox",
                                    "numinlets": 1,
                                    "numoutlets": 2,
                                    "outlettype": [
                                        "",
                                        ""
                                    ],
                                    "patching_rect": [
                                        22.0,
                                        80.0,
                                        550.0,
                                        380.0
                                    ]
                                }
                            },
                            {
                                "box": {
                                    "id": "gen-obj-3",
                                    "maxclass": "newobj",
                                    "numinlets": 1,
                                    "numoutlets": 0,
                                    "patching_rect": [
                                        22.0,
                                        490.0,
                                        35.0,
                                        22.0
                                    ],
                                    "text": "out 1"
                                }
                            },
                            {
                                "box": {
                                    "id": "gen-obj-4",
                                    "maxclass": "newobj",
                                    "numinlets": 1,
                                    "numoutlets": 0,
                                    "patching_rect": [
                                        82.0,
                                        490.0,
                                        35.0,
                                        22.0
                                    ],
                                    "text": "out 2"
                                }
                            }
                        ],
                        "lines": [
                            {
                                "patchline": {
                                    "destination": [
                                        "gen-obj-2",
                                        0
                                    ],
                                    "source": [
                                        "gen-obj-1",
                                        0
                                    ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [
                                        "gen-obj-3",
                                        0
                                    ],
                                    "source": [
                                        "gen-obj-2",
                                        0
                                    ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [
                                        "gen-obj-4",
                                        0
                                    ],
                                    "source": [
                                        "gen-obj-2",
                                        1
                                    ]
                                }
                            }
                        ]
                    },
                    "patching_rect": [
                        200.0,
                        380.0,
                        200.0,
                        22.0
                    ],
                    "text": "jit.gl.pix vsynth @name split_pix @type float32",
                    "varname": "split_pix"
                }
            },
            {
                "box": {
                    "id": "obj-6",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 4,
                    "outlettype": [
                        "",
                        "",
                        "",
                        ""
                    ],
                    "patching_rect": [
                        500.0,
                        500.0,
                        56.0,
                        22.0
                    ],
                    "text": "autopattr",
                    "varname": "split_autopattr"
                }
            },
            {
                "box": {
                    "id": "obj-9",
                    "maxclass": "panel",
                    "angle": 270.0,
                    "background": 1,
                    "bgcolor": [
                        0.0,
                        0.0,
                        0.0,
                        1.0
                    ],
                    "border": 1,
                    "bordercolor": [
                        0.0,
                        0.03529411765,
                        0.2274509804,
                        1.0
                    ],
                    "mode": 0,
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [
                        20.0,
                        20.0,
                        80.0,
                        80.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        0.0,
                        0.0,
                        80.0,
                        80.0
                    ],
                    "proportion": 0.5
                }
            },
            {
                "box": {
                    "id": "obj-10",
                    "maxclass": "comment",
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [
                        20.0,
                        20.0,
                        80.0,
                        21.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        -1.5,
                        0.0,
                        80.0,
                        21.0
                    ],
                    "text": "VF Split"
                }
            },
            {
                "box": {
                    "id": "obj-8",
                    "maxclass": "comment",
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "textcolor": [
                        0.302,
                        0.325,
                        0.463,
                        1.0
                    ],
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [
                        20.0,
                        20.0,
                        60.0,
                        21.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        55.6,
                        2.5,
                        60.0,
                        18.0
                    ],
                    "text": "vecfield in"
                }
            },
            {
                "box": {
                    "id": "obj-11",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "patching_rect": [
                        600.0,
                        50.0,
                        60.0,
                        22.0
                    ],
                    "text": "loadbang"
                }
            },
            {
                "box": {
                    "id": "obj-12",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "patching_rect": [
                        600.0,
                        80.0,
                        180.0,
                        22.0
                    ],
                    "text": "getattr presentation_rect"
                }
            },
            {
                "box": {
                    "id": "obj-13",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 4,
                    "outlettype": [
                        "",
                        "",
                        "",
                        ""
                    ],
                    "patching_rect": [
                        600.0,
                        110.0,
                        80.0,
                        22.0
                    ],
                    "text": "thispatcher"
                }
            },
            {
                "box": {
                    "id": "obj-14",
                    "maxclass": "newobj",
                    "numinlets": 2,
                    "numoutlets": 2,
                    "outlettype": [
                        "",
                        ""
                    ],
                    "patching_rect": [
                        600.0,
                        140.0,
                        60.0,
                        22.0
                    ],
                    "text": "zl slice 2"
                }
            },
            {
                "box": {
                    "id": "obj-15",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "patching_rect": [
                        600.0,
                        170.0,
                        80.0,
                        22.0
                    ],
                    "text": "prepend tam"
                }
            },
            {
                "box": {
                    "id": "obj-16",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "patching_rect": [
                        600.0,
                        200.0,
                        100.0,
                        22.0
                    ],
                    "saved_object_attributes": {
                        "filename": "moduleSize.js",
                        "parameter_enable": 0
                    },
                    "text": "js moduleSize.js"
                }
            },
            {
                "box": {
                    "id": "obj-20",
                    "maxclass": "live.text",
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "hint": "Unipolar: passthrough 0-1; Bipolar: remap to -1 to 1",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [
                        "",
                        ""
                    ],
                    "param_connect": "split_pix::bipolar",
                    "parameter_enable": 1,
                    "patching_rect": [
                        50.0,
                        80.0,
                        60.0,
                        17.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        0.0,
                        52.0,
                        60.0,
                        17.0
                    ],
                    "text": "Unipolar",
                    "texton": "Bipolar",
                    "saved_attribute_attributes": {
                        "activebgcolor": {
                            "expression": ""
                        },
                        "activebgoncolor": {
                            "expression": ""
                        },
                        "activetextcolor": {
                            "expression": ""
                        },
                        "activetextoncolor": {
                            "expression": ""
                        },
                        "bgoncolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_enum": [
                                "Unipolar",
                                "Bipolar"
                            ],
                            "parameter_initial": [
                                0.0
                            ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "bipolar",
                            "parameter_mmax": 1.0,
                            "parameter_mmin": 0.0,
                            "parameter_modmode": 0,
                            "parameter_shortname": "bipolar",
                            "parameter_type": 1,
                            "parameter_unitstyle": 0
                        }
                    },
                    "varname": "bipolar"
                }
            },
            {
                "box": {
                    "id": "obj-21",
                    "maxclass": "attrui",
                    "attr": "bipolar",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "patching_rect": [
                        50.0,
                        170.0,
                        129.0,
                        22.0
                    ],
                    "style": ""
                }
            },
            {
                "box": {
                    "id": "obj-23",
                    "maxclass": "jsui",
                    "filename": "bypass_toggle.js",
                    "hint": "Bypass",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "presentation": 1,
                    "patching_rect": [
                        58.0,
                        5.0,
                        18.0,
                        12.0
                    ],
                    "presentation_rect": [
                        58.0,
                        5.0,
                        18.0,
                        12.0
                    ],
                    "valuepopuplabel": 1,
                    "varname": "bypass"
                }
            },
            {
                "box": {
                    "id": "obj-24",
                    "maxclass": "attrui",
                    "attr": "bypass",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "patching_rect": [
                        400.0,
                        60.0,
                        131.0,
                        22.0
                    ],
                    "style": ""
                }
            }
        ],
        "lines": [
            {
                "patchline": {
                    "source": [
                        "obj-1",
                        0
                    ],
                    "destination": [
                        "obj-3",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-3",
                        0
                    ],
                    "destination": [
                        "obj-5",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-3",
                        2
                    ],
                    "destination": [
                        "obj-4",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-5",
                        0
                    ],
                    "destination": [
                        "obj-2",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-5",
                        1
                    ],
                    "destination": [
                        "obj-201",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-23",
                        0
                    ],
                    "destination": [
                        "obj-24",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-24",
                        0
                    ],
                    "destination": [
                        "obj-5",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-11",
                        0
                    ],
                    "destination": [
                        "obj-12",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-12",
                        0
                    ],
                    "destination": [
                        "obj-13",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-13",
                        0
                    ],
                    "destination": [
                        "obj-14",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-14",
                        1
                    ],
                    "destination": [
                        "obj-15",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-15",
                        0
                    ],
                    "destination": [
                        "obj-16",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-4",
                        0
                    ],
                    "destination": [
                        "obj-20",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-20",
                        0
                    ],
                    "destination": [
                        "obj-21",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-21",
                        0
                    ],
                    "destination": [
                        "obj-5",
                        0
                    ]
                }
            }
        ],
        "parameters": {
            "obj-20": [
                "bipolar",
                "bipolar",
                0
            ],
            "parameterbanks": {
                "0": {
                    "index": 0,
                    "name": "",
                    "parameters": [
                        "-",
                        "-",
                        "-",
                        "-",
                        "-",
                        "-",
                        "-",
                        "-"
                    ],
                    "buttons": [
                        "-",
                        "-",
                        "-",
                        "-",
                        "-",
                        "-",
                        "-",
                        "-"
                    ]
                }
            },
            "inherited_shortname": 1
        },
        "autosave": 0
    }
}