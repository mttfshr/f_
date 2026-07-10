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
            352.0,
            600.0
        ],
        "openinpresentation": 1,
        "boxes": [
            {
                "box": {
                    "comment": "texture / control",
                    "id": "obj-1",
                    "index": 0,
                    "maxclass": "inlet",
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
                    "comment": "vecfield out",
                    "id": "obj-2",
                    "index": 0,
                    "maxclass": "outlet",
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
                    "numinlets": 3,
                    "numoutlets": 3,
                    "outlettype": [
                        "",
                        "",
                        ""
                    ],
                    "patching_rect": [
                        200.0,
                        130.0,
                        150.0,
                        22.0
                    ],
                    "text": "route angle spread"
                }
            },
            {
                "box": {
                    "id": "obj-5",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [
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
                                    "code": "Param angle(0.0);\nParam spread(0.5);\nParam src_mode(0.0);\nParam bypass(0.0);\n\n// Base direction from angle param (0-1 maps to full circle)\ntheta = angle * twopi;\n\n// Texture perturbation: luminance of in1 offsets direction\nperturb = (sample(in1, norm).x - 0.5) * spread * twopi;\ntheta = theta + perturb * src_mode;\n\n// Encode as unit vecfield: cos/sin mapped from [-1,1] to [0,1]\nfx = cos(theta) * 0.5 + 0.5;\nfy = sin(theta) * 0.5 + 0.5;\n\nresult = vec(fx, fy, 0.5, 1.0);\nneutral = vec(0.5, 0.5, 0.5, 1.0);\nout1 = mix(result, neutral, bypass);\n",
                                    "fontface": 0,
                                    "fontname": "<Monospaced>",
                                    "fontsize": 12.0,
                                    "id": "gen-obj-2",
                                    "maxclass": "codebox",
                                    "numinlets": 1,
                                    "numoutlets": 1,
                                    "outlettype": [
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
                            }
                        ]
                    },
                    "patching_rect": [
                        200.0,
                        380.0,
                        265.0,
                        22.0
                    ],
                    "text": "jit.gl.pix vsynth @name vfflow_pix @type float32",
                    "varname": "vfflow_pix"
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
                    "restore": {
                        "angle": [
                            0.0
                        ],
                        "bypass": [
                            0
                        ],
                        "spread": [
                            0.5
                        ]
                    },
                    "text": "autopattr",
                    "varname": "vfflow_autopattr"
                }
            },
            {
                "box": {
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
                    "id": "obj-9",
                    "maxclass": "panel",
                    "mode": 0,
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [
                        20.0,
                        20.0,
                        150.0,
                        80.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        0.0,
                        0.0,
                        150.0,
                        80.0
                    ],
                    "proportion": 0.5
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-10",
                    "maxclass": "comment",
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
                    "text": "Flow"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-8",
                    "maxclass": "comment",
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
                        38.0,
                        2.5,
                        60.0,
                        21.0
                    ],
                    "text": "vecfield out",
                    "textcolor": [
                        0.302,
                        0.325,
                        0.463,
                        1.0
                    ]
                }
            },
            {
                "box": {
                    "id": "obj-11",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [
                        "bang"
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
                    "numoutlets": 2,
                    "outlettype": [
                        "",
                        ""
                    ],
                    "patching_rect": [
                        600.0,
                        110.0,
                        80.0,
                        22.0
                    ],
                    "save": [
                        "#N",
                        "thispatcher",
                        ";",
                        "#Q",
                        "end",
                        ";"
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
                    "id": "obj-17",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [
                        "",
                        ""
                    ],
                    "patching_rect": [
                        200.0,
                        60.0,
                        80.0,
                        22.0
                    ],
                    "text": "vs_inState"
                }
            },
            {
                "box": {
                    "id": "obj-18",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "patching_rect": [
                        350.0,
                        60.0,
                        146.0,
                        22.0
                    ],
                    "text": "prepend param src_mode"
                }
            },
            {
                "box": {
                    "activedialcolor": [
                        0.8,
                        0.8,
                        0.8,
                        1.0
                    ],
                    "fontname": "Ableton Sans Light",
                    "hint": "Base flow direction (0-1 = full circle)",
                    "id": "obj-20",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [
                        "",
                        "float"
                    ],
                    "param_connect": "vfflow_pix::angle",
                    "parameter_enable": 1,
                    "patching_rect": [
                        50.0,
                        80.0,
                        27.0,
                        43.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        4.0,
                        38.0,
                        27.0,
                        43.0
                    ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [
                                0.0
                            ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "angle",
                            "parameter_mmax": 1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "angle",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "angle"
                }
            },
            {
                "box": {
                    "attr": "angle",
                    "id": "obj-21",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "parameter_enable": 0,
                    "patching_rect": [
                        50.0,
                        170.0,
                        127.5,
                        22.0
                    ]
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-22",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [
                        50.0,
                        130.0,
                        50.0,
                        18.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        -7.5,
                        20.0,
                        50.0,
                        18.0
                    ],
                    "text": "Angle",
                    "textjustification": 1
                }
            },
            {
                "box": {
                    "activedialcolor": [
                        0.8,
                        0.8,
                        0.8,
                        1.0
                    ],
                    "fontname": "Ableton Sans Light",
                    "hint": "How much the texture perturbs direction (0=uniform, 1=full rotation)",
                    "id": "obj-23",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [
                        "",
                        "float"
                    ],
                    "param_connect": "vfflow_pix::spread",
                    "parameter_enable": 1,
                    "patching_rect": [
                        100.0,
                        80.0,
                        27.0,
                        43.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        41.0,
                        38.0,
                        27.0,
                        43.0
                    ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [
                                0.5
                            ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "spread",
                            "parameter_mmax": 1.0,
                            "parameter_mmin": -1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "spread",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "spread"
                }
            },
            {
                "box": {
                    "attr": "spread",
                    "id": "obj-24",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "parameter_enable": 0,
                    "patching_rect": [
                        100.0,
                        200.0,
                        127.5,
                        22.0
                    ]
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-25",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [
                        100.0,
                        130.0,
                        50.0,
                        18.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        29.5,
                        20.0,
                        50.0,
                        18.0
                    ],
                    "text": "Spread",
                    "textjustification": 1
                }
            },
            {
                "box": {
                    "filename": "bypass_toggle.js",
                    "hint": "Bypass",
                    "id": "obj-26",
                    "maxclass": "jsui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "parameter_enable": 0,
                    "patching_rect": [
                        128.0,
                        5.0,
                        18.0,
                        12.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        128.0,
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
                    "attr": "bypass",
                    "id": "obj-27",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "parameter_enable": 0,
                    "patching_rect": [
                        400.0,
                        60.0,
                        131.0,
                        22.0
                    ]
                }
            }
        ],
        "lines": [
            {
                "patchline": {
                    "destination": [
                        "obj-3",
                        0
                    ],
                    "source": [
                        "obj-1",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-12",
                        0
                    ],
                    "source": [
                        "obj-11",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-13",
                        0
                    ],
                    "source": [
                        "obj-12",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-14",
                        0
                    ],
                    "source": [
                        "obj-13",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-15",
                        0
                    ],
                    "source": [
                        "obj-14",
                        1
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-16",
                        0
                    ],
                    "source": [
                        "obj-15",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-18",
                        0
                    ],
                    "source": [
                        "obj-17",
                        1
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-5",
                        0
                    ],
                    "source": [
                        "obj-17",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-5",
                        0
                    ],
                    "source": [
                        "obj-18",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-21",
                        0
                    ],
                    "source": [
                        "obj-20",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-5",
                        0
                    ],
                    "source": [
                        "obj-21",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-24",
                        0
                    ],
                    "source": [
                        "obj-23",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-5",
                        0
                    ],
                    "source": [
                        "obj-24",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-27",
                        0
                    ],
                    "source": [
                        "obj-26",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-5",
                        0
                    ],
                    "source": [
                        "obj-27",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-17",
                        0
                    ],
                    "source": [
                        "obj-3",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-4",
                        0
                    ],
                    "source": [
                        "obj-3",
                        2
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-20",
                        0
                    ],
                    "source": [
                        "obj-4",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-23",
                        0
                    ],
                    "source": [
                        "obj-4",
                        1
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-2",
                        0
                    ],
                    "source": [
                        "obj-5",
                        0
                    ]
                }
            }
        ],
        "parameters": {
            "obj-20": [
                "angle",
                "angle",
                0
            ],
            "obj-23": [
                "spread",
                "spread",
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