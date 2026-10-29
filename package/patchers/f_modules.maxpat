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
            467.0,
            158.0,
            892.0,
            966.0
        ],
        "openinpresentation": 1,
        "boxes": [
            {
                "box": {
                    "background": 1,
                    "bgcolor": [
                        0.0,
                        0.0,
                        0.0,
                        1.0
                    ],
                    "border": 2,
                    "bordercolor": [
                        0.0,
                        0.03529411765,
                        0.2274509804,
                        1.0
                    ],
                    "id": "obj-1",
                    "maxclass": "panel",
                    "mode": 0,
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [
                        0.0,
                        0.0,
                        160.0,
                        340.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        0.0,
                        0.0,
                        96.0,
                        420.0
                    ],
                    "rounded": 6
                }
            },
            {
                "box": {
                    "fontface": 2,
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.5,
                    "id": "obj-2",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [
                        3.0,
                        4.0,
                        156.0,
                        21.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        3.0,
                        4.0,
                        89.66666933894157,
                        21.0
                    ],
                    "text": "f_",
                    "textcolor": [
                        1.0,
                        1.0,
                        1.0,
                        1.0
                    ]
                }
            },
            {
                "box": {
                    "id": "obj-3",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "patching_rect": [
                        200.0,
                        300.0,
                        100.0,
                        22.0
                    ],
                    "saved_object_attributes": {
                        "filename": "f_addmod.js",
                        "parameter_enable": 0
                    },
                    "text": "js f_addmod.js"
                }
            },
            {
                "box": {
                    "id": "obj-4",
                    "maxclass": "newobj",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "patching_rect": [
                        200.0,
                        270.0,
                        55.0,
                        22.0
                    ],
                    "text": "gate 1 0"
                }
            },
            {
                "box": {
                    "id": "obj-5",
                    "maxclass": "newobj",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "patching_rect": [
                        130.0,
                        230.0,
                        60.0,
                        22.0
                    ],
                    "text": "pipe 250"
                }
            },
            {
                "box": {
                    "id": "obj-6",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "patching_rect": [
                        130.0,
                        200.0,
                        72.0,
                        22.0
                    ],
                    "text": "loadmess 1"
                }
            },
            {
                "box": {
                    "fontface": 0,
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-7",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [
                        3.0,
                        25.0,
                        176.0,
                        21.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        2.0,
                        25.0,
                        89.66666933894157,
                        21.0
                    ],
                    "text": "Patterns",
                    "textcolor": [
                        0.45098039215686275,
                        0.47058823529411764,
                        0.5764705882352941,
                        1.0
                    ]
                }
            },
            {
                "box": {
                    "appearance": 1,
                    "fontname": "Ableton Sans Light",
                    "fontsize": 11.0,
                    "id": "obj-8",
                    "lcdcolor": [
                        0.8,
                        0.8,
                        0.8,
                        1.0
                    ],
                    "maxclass": "live.menu",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "outlettype": [
                        "",
                        "",
                        "float"
                    ],
                    "parameter_enable": 1,
                    "parameter_mappable": 0,
                    "patching_rect": [
                        3.0,
                        600.0,
                        154.0,
                        17.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        3.0,
                        46.0,
                        89.66666933894157,
                        17.0
                    ],
                    "saved_attribute_attributes": {
                        "lcdcolor": {
                            "expression": "themecolor.live_arranger_grid_tiles"
                        },
                        "valueof": {
                            "parameter_enum": [
                                "Chladni \u2207",
                                "Grain",
                                "Kuramoto-Sivashinsky",
                                "Masonry",
                                "Quasi \u2207",
                                "Seeds \u2207",
                                "Stipple",
                                "Weave \u2207",
                                "Wilson-Cowan"
                            ],
                            "parameter_initial": [
                                0.0
                            ],
                            "parameter_invisible": 2,
                            "parameter_longname": "f_module_0_disp",
                            "parameter_mmax": 8,
                            "parameter_modmode": 0,
                            "parameter_shortname": "live.menu",
                            "parameter_type": 2
                        }
                    },
                    "varname": "live.menu"
                }
            },
            {
                "box": {
                    "id": "obj-9",
                    "maxclass": "live.menu",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "outlettype": [
                        "",
                        "",
                        "float"
                    ],
                    "parameter_enable": 1,
                    "parameter_mappable": 0,
                    "patching_rect": [
                        3.0,
                        1500.0,
                        154.0,
                        15.0
                    ],
                    "saved_attribute_attributes": {
                        "valueof": {
                            "parameter_enum": [
                                "chladni",
                                "grain",
                                "ks",
                                "masonry",
                                "quasi",
                                "vf_seeds",
                                "stipple",
                                "weave",
                                "wc"
                            ],
                            "parameter_initial": [
                                0.0
                            ],
                            "parameter_invisible": 2,
                            "parameter_longname": "f_module_0_file",
                            "parameter_mmax": 8,
                            "parameter_modmode": 0,
                            "parameter_shortname": "live.menu",
                            "parameter_type": 2
                        }
                    },
                    "varname": "live.menu[1]"
                }
            },
            {
                "box": {
                    "id": "obj-10",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "patching_rect": [
                        3.0,
                        2500.0,
                        100.0,
                        22.0
                    ],
                    "text": "prepend addmod"
                }
            },
            {
                "box": {
                    "fontface": 0,
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-11",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [
                        3.0,
                        64.0,
                        176.0,
                        21.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        2.0,
                        64.0,
                        89.66666933894157,
                        21.0
                    ],
                    "text": "Space & Optics",
                    "textcolor": [
                        0.45098039215686275,
                        0.47058823529411764,
                        0.5764705882352941,
                        1.0
                    ]
                }
            },
            {
                "box": {
                    "appearance": 1,
                    "fontname": "Ableton Sans Light",
                    "fontsize": 11.0,
                    "id": "obj-12",
                    "lcdcolor": [
                        0.8,
                        0.8,
                        0.8,
                        1.0
                    ],
                    "maxclass": "live.menu",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "outlettype": [
                        "",
                        "",
                        "float"
                    ],
                    "parameter_enable": 1,
                    "parameter_mappable": 0,
                    "patching_rect": [
                        3.0,
                        700.0,
                        154.0,
                        17.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        3.0,
                        85.0,
                        89.66666933894157,
                        17.0
                    ],
                    "saved_attribute_attributes": {
                        "lcdcolor": {
                            "expression": "themecolor.live_arranger_grid_tiles"
                        },
                        "valueof": {
                            "parameter_enum": [
                                "Droste",
                                "Lens",
                                "Mobius",
                                "Ngon",
                                "SIRDS",
                                "Stereo"
                            ],
                            "parameter_initial": [
                                0.0
                            ],
                            "parameter_invisible": 2,
                            "parameter_longname": "f_module_1_disp",
                            "parameter_mmax": 5,
                            "parameter_modmode": 0,
                            "parameter_shortname": "live.menu",
                            "parameter_type": 2
                        }
                    },
                    "varname": "live.menu[2]"
                }
            },
            {
                "box": {
                    "id": "obj-13",
                    "maxclass": "live.menu",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "outlettype": [
                        "",
                        "",
                        "float"
                    ],
                    "parameter_enable": 1,
                    "parameter_mappable": 0,
                    "patching_rect": [
                        3.0,
                        1600.0,
                        154.0,
                        15.0
                    ],
                    "saved_attribute_attributes": {
                        "valueof": {
                            "parameter_enum": [
                                "droste",
                                "lens",
                                "mobius",
                                "ngon",
                                "sirds",
                                "stereo"
                            ],
                            "parameter_initial": [
                                0.0
                            ],
                            "parameter_invisible": 2,
                            "parameter_longname": "f_module_1_file",
                            "parameter_mmax": 5,
                            "parameter_modmode": 0,
                            "parameter_shortname": "live.menu",
                            "parameter_type": 2
                        }
                    },
                    "varname": "live.menu[3]"
                }
            },
            {
                "box": {
                    "id": "obj-14",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "patching_rect": [
                        3.0,
                        2600.0,
                        100.0,
                        22.0
                    ],
                    "text": "prepend addmod"
                }
            },
            {
                "box": {
                    "fontface": 0,
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-15",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [
                        3.0,
                        103.0,
                        176.0,
                        21.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        2.0,
                        103.0,
                        89.66666933894157,
                        21.0
                    ],
                    "text": "Color / Tone",
                    "textcolor": [
                        0.45098039215686275,
                        0.47058823529411764,
                        0.5764705882352941,
                        1.0
                    ]
                }
            },
            {
                "box": {
                    "appearance": 1,
                    "fontname": "Ableton Sans Light",
                    "fontsize": 11.0,
                    "id": "obj-16",
                    "lcdcolor": [
                        0.8,
                        0.8,
                        0.8,
                        1.0
                    ],
                    "maxclass": "live.menu",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "outlettype": [
                        "",
                        "",
                        "float"
                    ],
                    "parameter_enable": 1,
                    "parameter_mappable": 0,
                    "patching_rect": [
                        3.0,
                        800.0,
                        154.0,
                        17.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        3.0,
                        124.0,
                        89.66666933894157,
                        17.0
                    ],
                    "saved_attribute_attributes": {
                        "lcdcolor": {
                            "expression": "themecolor.live_arranger_grid_tiles"
                        },
                        "valueof": {
                            "parameter_enum": [
                                "Channel Grader",
                                "Hue Processor",
                                "Luma Processor",
                                "Tone Curve"
                            ],
                            "parameter_initial": [
                                0.0
                            ],
                            "parameter_invisible": 2,
                            "parameter_longname": "f_module_2_disp",
                            "parameter_mmax": 3,
                            "parameter_modmode": 0,
                            "parameter_shortname": "live.menu",
                            "parameter_type": 2
                        }
                    },
                    "varname": "live.menu[4]"
                }
            },
            {
                "box": {
                    "id": "obj-17",
                    "maxclass": "live.menu",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "outlettype": [
                        "",
                        "",
                        "float"
                    ],
                    "parameter_enable": 1,
                    "parameter_mappable": 0,
                    "patching_rect": [
                        3.0,
                        1700.0,
                        154.0,
                        15.0
                    ],
                    "saved_attribute_attributes": {
                        "valueof": {
                            "parameter_enum": [
                                "channel_grader",
                                "hue_processor",
                                "luma_processor",
                                "tone_curve"
                            ],
                            "parameter_initial": [
                                0.0
                            ],
                            "parameter_invisible": 2,
                            "parameter_longname": "f_module_2_file",
                            "parameter_mmax": 3,
                            "parameter_modmode": 0,
                            "parameter_shortname": "live.menu",
                            "parameter_type": 2
                        }
                    },
                    "varname": "live.menu[5]"
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
                        3.0,
                        2700.0,
                        100.0,
                        22.0
                    ],
                    "text": "prepend addmod"
                }
            },
            {
                "box": {
                    "fontface": 0,
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-19",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [
                        3.0,
                        142.0,
                        176.0,
                        21.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        2.0,
                        142.0,
                        89.66666933894157,
                        21.0
                    ],
                    "text": "\u2207 Fields",
                    "textcolor": [
                        0.35,
                        0.75,
                        0.95,
                        1.0
                    ]
                }
            },
            {
                "box": {
                    "appearance": 1,
                    "fontname": "Ableton Sans Light",
                    "fontsize": 11.0,
                    "id": "obj-20",
                    "lcdcolor": [
                        0.8,
                        0.8,
                        0.8,
                        1.0
                    ],
                    "maxclass": "live.menu",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "outlettype": [
                        "",
                        "",
                        "float"
                    ],
                    "parameter_enable": 1,
                    "parameter_mappable": 0,
                    "patching_rect": [
                        3.0,
                        900.0,
                        154.0,
                        17.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        3.0,
                        163.0,
                        89.66666933894157,
                        17.0
                    ],
                    "saved_attribute_attributes": {
                        "lcdcolor": {
                            "expression": "themecolor.live_arranger_grid_tiles"
                        },
                        "valueof": {
                            "parameter_enum": [
                                "Flow \u2207",
                                "Fluid \u2207",
                                "Immiscible \u2207",
                                "Lattice Boltzmann \u2207",
                                "Optical Flow \u2207",
                                "Repulse \u2207",
                                "Vortex \u2207",
                                "Vortex Multi \u2207",
                                "Vorticity \u2207"
                            ],
                            "parameter_initial": [
                                0.0
                            ],
                            "parameter_invisible": 2,
                            "parameter_longname": "f_module_3_disp",
                            "parameter_mmax": 8,
                            "parameter_modmode": 0,
                            "parameter_shortname": "live.menu",
                            "parameter_type": 2
                        }
                    },
                    "varname": "live.menu[6]"
                }
            },
            {
                "box": {
                    "id": "obj-21",
                    "maxclass": "live.menu",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "outlettype": [
                        "",
                        "",
                        "float"
                    ],
                    "parameter_enable": 1,
                    "parameter_mappable": 0,
                    "patching_rect": [
                        3.0,
                        1800.0,
                        154.0,
                        15.0
                    ],
                    "saved_attribute_attributes": {
                        "valueof": {
                            "parameter_enum": [
                                "vf_flow",
                                "vf_fluid",
                                "vf_immiscible",
                                "vf_lbm",
                                "vf_optical_flow",
                                "vf_repulse",
                                "vf_vortex",
                                "vf_vortex_multi",
                                "vf_vorticity"
                            ],
                            "parameter_initial": [
                                0.0
                            ],
                            "parameter_invisible": 2,
                            "parameter_longname": "f_module_3_file",
                            "parameter_mmax": 8,
                            "parameter_modmode": 0,
                            "parameter_shortname": "live.menu",
                            "parameter_type": 2
                        }
                    },
                    "varname": "live.menu[7]"
                }
            },
            {
                "box": {
                    "id": "obj-22",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "patching_rect": [
                        3.0,
                        2800.0,
                        100.0,
                        22.0
                    ],
                    "text": "prepend addmod"
                }
            },
            {
                "box": {
                    "fontface": 0,
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-23",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [
                        3.0,
                        181.0,
                        176.0,
                        21.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        2.0,
                        181.0,
                        89.66666933894157,
                        21.0
                    ],
                    "text": "\u2207 Effects",
                    "textcolor": [
                        0.35,
                        0.75,
                        0.95,
                        1.0
                    ]
                }
            },
            {
                "box": {
                    "appearance": 1,
                    "fontname": "Ableton Sans Light",
                    "fontsize": 11.0,
                    "id": "obj-24",
                    "lcdcolor": [
                        0.8,
                        0.8,
                        0.8,
                        1.0
                    ],
                    "maxclass": "live.menu",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "outlettype": [
                        "",
                        "",
                        "float"
                    ],
                    "parameter_enable": 1,
                    "parameter_mappable": 0,
                    "patching_rect": [
                        3.0,
                        1000.0,
                        154.0,
                        17.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        3.0,
                        202.0,
                        89.66666933894157,
                        17.0
                    ],
                    "saved_attribute_attributes": {
                        "lcdcolor": {
                            "expression": "themecolor.live_arranger_grid_tiles"
                        },
                        "valueof": {
                            "parameter_enum": [
                                "Advect \u2207",
                                "Caustic \u2207",
                                "Chroma \u2207",
                                "Glow \u2207",
                                "Prism \u2207",
                                "Streak \u2207",
                                "Warp \u2207"
                            ],
                            "parameter_initial": [
                                0.0
                            ],
                            "parameter_invisible": 2,
                            "parameter_longname": "f_module_4_disp",
                            "parameter_mmax": 6,
                            "parameter_modmode": 0,
                            "parameter_shortname": "live.menu",
                            "parameter_type": 2
                        }
                    },
                    "varname": "live.menu[8]"
                }
            },
            {
                "box": {
                    "id": "obj-25",
                    "maxclass": "live.menu",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "outlettype": [
                        "",
                        "",
                        "float"
                    ],
                    "parameter_enable": 1,
                    "parameter_mappable": 0,
                    "patching_rect": [
                        3.0,
                        1900.0,
                        154.0,
                        15.0
                    ],
                    "saved_attribute_attributes": {
                        "valueof": {
                            "parameter_enum": [
                                "vf_advect",
                                "caustic",
                                "vf_chroma",
                                "vf_glow",
                                "vf_prism",
                                "vf_streak",
                                "vf_warp"
                            ],
                            "parameter_initial": [
                                0.0
                            ],
                            "parameter_invisible": 2,
                            "parameter_longname": "f_module_4_file",
                            "parameter_mmax": 6,
                            "parameter_modmode": 0,
                            "parameter_shortname": "live.menu",
                            "parameter_type": 2
                        }
                    },
                    "varname": "live.menu[9]"
                }
            },
            {
                "box": {
                    "id": "obj-26",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "patching_rect": [
                        3.0,
                        2900.0,
                        100.0,
                        22.0
                    ],
                    "text": "prepend addmod"
                }
            },
            {
                "box": {
                    "fontface": 0,
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-27",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [
                        3.0,
                        220.0,
                        176.0,
                        21.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        2.0,
                        220.0,
                        89.66666933894157,
                        21.0
                    ],
                    "text": "T_ Fields",
                    "textcolor": [
                        0.85,
                        0.55,
                        0.2,
                        1.0
                    ]
                }
            },
            {
                "box": {
                    "appearance": 1,
                    "fontname": "Ableton Sans Light",
                    "fontsize": 11.0,
                    "id": "obj-28",
                    "lcdcolor": [
                        0.8,
                        0.8,
                        0.8,
                        1.0
                    ],
                    "maxclass": "live.menu",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "outlettype": [
                        "",
                        "",
                        "float"
                    ],
                    "parameter_enable": 1,
                    "parameter_mappable": 0,
                    "patching_rect": [
                        3.0,
                        1100.0,
                        154.0,
                        17.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        3.0,
                        241.0,
                        89.66666933894157,
                        17.0
                    ],
                    "saved_attribute_attributes": {
                        "lcdcolor": {
                            "expression": "themecolor.live_arranger_grid_tiles"
                        },
                        "valueof": {
                            "parameter_enum": [
                                "Tensormap T_",
                                "Smooth T_",
                                "Sharpen T_"
                            ],
                            "parameter_initial": [
                                0.0
                            ],
                            "parameter_invisible": 2,
                            "parameter_longname": "f_module_5_disp",
                            "parameter_mmax": 2,
                            "parameter_modmode": 0,
                            "parameter_shortname": "live.menu",
                            "parameter_type": 2
                        }
                    },
                    "varname": "live.menu[10]"
                }
            },
            {
                "box": {
                    "id": "obj-29",
                    "maxclass": "live.menu",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "outlettype": [
                        "",
                        "",
                        "float"
                    ],
                    "parameter_enable": 1,
                    "parameter_mappable": 0,
                    "patching_rect": [
                        3.0,
                        2000.0,
                        154.0,
                        15.0
                    ],
                    "saved_attribute_attributes": {
                        "valueof": {
                            "parameter_enum": [
                                "tf_tensormap",
                                "tf_smooth",
                                "tf_sharpen"
                            ],
                            "parameter_initial": [
                                0.0
                            ],
                            "parameter_invisible": 2,
                            "parameter_longname": "f_module_5_file",
                            "parameter_mmax": 2,
                            "parameter_modmode": 0,
                            "parameter_shortname": "live.menu",
                            "parameter_type": 2
                        }
                    },
                    "varname": "live.menu[11]"
                }
            },
            {
                "box": {
                    "id": "obj-30",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "patching_rect": [
                        3.0,
                        3000.0,
                        100.0,
                        22.0
                    ],
                    "text": "prepend addmod"
                }
            },
            {
                "box": {
                    "fontface": 0,
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-31",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [
                        3.0,
                        259.0,
                        176.0,
                        21.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        2.0,
                        259.0,
                        89.66666933894157,
                        21.0
                    ],
                    "text": "T_ Effects",
                    "textcolor": [
                        0.85,
                        0.55,
                        0.2,
                        1.0
                    ]
                }
            },
            {
                "box": {
                    "appearance": 1,
                    "fontname": "Ableton Sans Light",
                    "fontsize": 11.0,
                    "id": "obj-32",
                    "lcdcolor": [
                        0.8,
                        0.8,
                        0.8,
                        1.0
                    ],
                    "maxclass": "live.menu",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "outlettype": [
                        "",
                        "",
                        "float"
                    ],
                    "parameter_enable": 1,
                    "parameter_mappable": 0,
                    "patching_rect": [
                        3.0,
                        1200.0,
                        154.0,
                        17.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        3.0,
                        280.0,
                        89.66666933894157,
                        17.0
                    ],
                    "saved_attribute_attributes": {
                        "lcdcolor": {
                            "expression": "themecolor.live_arranger_grid_tiles"
                        },
                        "valueof": {
                            "parameter_enum": [
                                "Aniso Blur T_",
                                "Glyph T_",
                                "Hatch T_"
                            ],
                            "parameter_initial": [
                                0.0
                            ],
                            "parameter_invisible": 2,
                            "parameter_longname": "f_module_6_disp",
                            "parameter_mmax": 2,
                            "parameter_modmode": 0,
                            "parameter_shortname": "live.menu",
                            "parameter_type": 2
                        }
                    },
                    "varname": "live.menu[12]"
                }
            },
            {
                "box": {
                    "id": "obj-33",
                    "maxclass": "live.menu",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "outlettype": [
                        "",
                        "",
                        "float"
                    ],
                    "parameter_enable": 1,
                    "parameter_mappable": 0,
                    "patching_rect": [
                        3.0,
                        2100.0,
                        154.0,
                        15.0
                    ],
                    "saved_attribute_attributes": {
                        "valueof": {
                            "parameter_enum": [
                                "tf_aniso_blur",
                                "tf_glyph",
                                "tf_hatch"
                            ],
                            "parameter_initial": [
                                0.0
                            ],
                            "parameter_invisible": 2,
                            "parameter_longname": "f_module_6_file",
                            "parameter_mmax": 2,
                            "parameter_modmode": 0,
                            "parameter_shortname": "live.menu",
                            "parameter_type": 2
                        }
                    },
                    "varname": "live.menu[13]"
                }
            },
            {
                "box": {
                    "id": "obj-34",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "patching_rect": [
                        3.0,
                        3100.0,
                        100.0,
                        22.0
                    ],
                    "text": "prepend addmod"
                }
            },
            {
                "box": {
                    "fontface": 0,
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-35",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [
                        3.0,
                        298.0,
                        176.0,
                        21.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        2.0,
                        298.0,
                        89.66666933894157,
                        21.0
                    ],
                    "text": "Adapters",
                    "textcolor": [
                        0.45098039215686275,
                        0.47058823529411764,
                        0.5764705882352941,
                        1.0
                    ]
                }
            },
            {
                "box": {
                    "appearance": 1,
                    "fontname": "Ableton Sans Light",
                    "fontsize": 11.0,
                    "id": "obj-36",
                    "lcdcolor": [
                        0.8,
                        0.8,
                        0.8,
                        1.0
                    ],
                    "maxclass": "live.menu",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "outlettype": [
                        "",
                        "",
                        "float"
                    ],
                    "parameter_enable": 1,
                    "parameter_mappable": 0,
                    "patching_rect": [
                        3.0,
                        1300.0,
                        154.0,
                        17.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        3.0,
                        319.0,
                        89.66666933894157,
                        17.0
                    ],
                    "saved_attribute_attributes": {
                        "lcdcolor": {
                            "expression": "themecolor.live_arranger_grid_tiles"
                        },
                        "valueof": {
                            "parameter_enum": [
                                "Axis Flow \u2207 T_",
                                "Fieldmap \u2207",
                                "Potential \u2207",
                                "Split \u2207"
                            ],
                            "parameter_initial": [
                                0.0
                            ],
                            "parameter_invisible": 2,
                            "parameter_longname": "f_module_7_disp",
                            "parameter_mmax": 3,
                            "parameter_modmode": 0,
                            "parameter_shortname": "live.menu",
                            "parameter_type": 2
                        }
                    },
                    "varname": "live.menu[14]"
                }
            },
            {
                "box": {
                    "id": "obj-37",
                    "maxclass": "live.menu",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "outlettype": [
                        "",
                        "",
                        "float"
                    ],
                    "parameter_enable": 1,
                    "parameter_mappable": 0,
                    "patching_rect": [
                        3.0,
                        2200.0,
                        154.0,
                        15.0
                    ],
                    "saved_attribute_attributes": {
                        "valueof": {
                            "parameter_enum": [
                                "tf_axisflow",
                                "vf_fieldmap",
                                "vf_potential",
                                "vf_split"
                            ],
                            "parameter_initial": [
                                0.0
                            ],
                            "parameter_invisible": 2,
                            "parameter_longname": "f_module_7_file",
                            "parameter_mmax": 3,
                            "parameter_modmode": 0,
                            "parameter_shortname": "live.menu",
                            "parameter_type": 2
                        }
                    },
                    "varname": "live.menu[15]"
                }
            },
            {
                "box": {
                    "id": "obj-38",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "patching_rect": [
                        3.0,
                        3200.0,
                        100.0,
                        22.0
                    ],
                    "text": "prepend addmod"
                }
            },
            {
                "box": {
                    "fontface": 0,
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-39",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [
                        3.0,
                        337.0,
                        176.0,
                        21.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        2.0,
                        337.0,
                        89.66666933894157,
                        21.0
                    ],
                    "text": "Routing / Mod",
                    "textcolor": [
                        0.45098039215686275,
                        0.47058823529411764,
                        0.5764705882352941,
                        1.0
                    ]
                }
            },
            {
                "box": {
                    "appearance": 1,
                    "fontname": "Ableton Sans Light",
                    "fontsize": 11.0,
                    "id": "obj-40",
                    "lcdcolor": [
                        0.8,
                        0.8,
                        0.8,
                        1.0
                    ],
                    "maxclass": "live.menu",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "outlettype": [
                        "",
                        "",
                        "float"
                    ],
                    "parameter_enable": 1,
                    "parameter_mappable": 0,
                    "patching_rect": [
                        3.0,
                        1400.0,
                        154.0,
                        17.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        3.0,
                        358.0,
                        89.66666933894157,
                        17.0
                    ],
                    "saved_attribute_attributes": {
                        "lcdcolor": {
                            "expression": "themecolor.live_arranger_grid_tiles"
                        },
                        "valueof": {
                            "parameter_enum": [
                                "Matrix 2",
                                "Profile",
                                "Tex Router"
                            ],
                            "parameter_initial": [
                                0.0
                            ],
                            "parameter_invisible": 2,
                            "parameter_longname": "f_module_8_disp",
                            "parameter_mmax": 2,
                            "parameter_modmode": 0,
                            "parameter_shortname": "live.menu",
                            "parameter_type": 2
                        }
                    },
                    "varname": "live.menu[16]"
                }
            },
            {
                "box": {
                    "id": "obj-41",
                    "maxclass": "live.menu",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "outlettype": [
                        "",
                        "",
                        "float"
                    ],
                    "parameter_enable": 1,
                    "parameter_mappable": 0,
                    "patching_rect": [
                        3.0,
                        2300.0,
                        154.0,
                        15.0
                    ],
                    "saved_attribute_attributes": {
                        "valueof": {
                            "parameter_enum": [
                                "util_matrix_2",
                                "util_profile",
                                "texrouter"
                            ],
                            "parameter_initial": [
                                0.0
                            ],
                            "parameter_invisible": 2,
                            "parameter_longname": "f_module_8_file",
                            "parameter_mmax": 2,
                            "parameter_modmode": 0,
                            "parameter_shortname": "live.menu",
                            "parameter_type": 2
                        }
                    },
                    "varname": "live.menu[17]"
                }
            },
            {
                "box": {
                    "id": "obj-42",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "patching_rect": [
                        3.0,
                        3300.0,
                        100.0,
                        22.0
                    ],
                    "text": "prepend addmod"
                }
            },
            {
                "box": {
                    "fontface": 0,
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-43",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [
                        3.0,
                        376.0,
                        176.0,
                        21.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        2.0,
                        376.0,
                        89.66666933894157,
                        21.0
                    ],
                    "text": "Recipes",
                    "textcolor": [
                        0.45098039215686275,
                        0.47058823529411764,
                        0.5764705882352941,
                        1.0
                    ]
                }
            },
            {
                "box": {
                    "appearance": 1,
                    "fontname": "Ableton Sans Light",
                    "fontsize": 11.0,
                    "id": "obj-44",
                    "lcdcolor": [
                        0.8,
                        0.8,
                        0.8,
                        1.0
                    ],
                    "maxclass": "live.menu",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "outlettype": [
                        "",
                        "",
                        "float"
                    ],
                    "parameter_enable": 1,
                    "parameter_mappable": 0,
                    "patching_rect": [
                        3.0,
                        1500.0,
                        154.0,
                        17.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        3.0,
                        397.0,
                        89.66666933894157,
                        17.0
                    ],
                    "saved_attribute_attributes": {
                        "lcdcolor": {
                            "expression": "themecolor.live_arranger_grid_tiles"
                        },
                        "valueof": {
                            "parameter_enum": [
                                "Fieldmap Seeds",
                                "Fieldmap Streak",
                                "Fluid Caustic",
                                "Chladni Glow",
                                "Grain Warp",
                                "Masonry Repulse",
                                "Motion Prism",
                                "Ngon Flow",
                                "Repulse Caustic",
                                "SIRDS",
                                "Tensor Advect",
                                "Vorticity Fluid"
                            ],
                            "parameter_initial": [
                                0.0
                            ],
                            "parameter_invisible": 2,
                            "parameter_longname": "f_module_9_disp",
                            "parameter_mmax": 11,
                            "parameter_modmode": 0,
                            "parameter_shortname": "live.menu",
                            "parameter_type": 2
                        }
                    },
                    "varname": "live.menu[18]"
                }
            },
            {
                "box": {
                    "id": "obj-45",
                    "maxclass": "live.menu",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "outlettype": [
                        "",
                        "",
                        "float"
                    ],
                    "parameter_enable": 1,
                    "parameter_mappable": 0,
                    "patching_rect": [
                        3.0,
                        2400.0,
                        154.0,
                        15.0
                    ],
                    "saved_attribute_attributes": {
                        "valueof": {
                            "parameter_enum": [
                                "fieldmap_seeds",
                                "fieldmap_streak",
                                "fluid_caustic",
                                "chladni_glow",
                                "grain_warp",
                                "masonry_repulse",
                                "motion_prism",
                                "ngon_flow",
                                "repulse_caustic",
                                "sirds",
                                "tensor_advect",
                                "vorticity_fluid"
                            ],
                            "parameter_initial": [
                                0.0
                            ],
                            "parameter_invisible": 2,
                            "parameter_longname": "f_module_9_file",
                            "parameter_mmax": 11,
                            "parameter_modmode": 0,
                            "parameter_shortname": "live.menu",
                            "parameter_type": 2
                        }
                    },
                    "varname": "live.menu[19]"
                }
            },
            {
                "box": {
                    "id": "obj-46",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "patching_rect": [
                        3.0,
                        3400.0,
                        100.0,
                        22.0
                    ],
                    "text": "prepend addrecipe"
                }
            }
        ],
        "lines": [
            {
                "patchline": {
                    "source": [
                        "obj-6",
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
                        "obj-5",
                        0
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
                        "obj-4",
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
                        "obj-8",
                        0
                    ],
                    "destination": [
                        "obj-9",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-9",
                        1
                    ],
                    "destination": [
                        "obj-10",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-10",
                        0
                    ],
                    "destination": [
                        "obj-4",
                        1
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
                        1
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
                        0
                    ],
                    "destination": [
                        "obj-4",
                        1
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-16",
                        0
                    ],
                    "destination": [
                        "obj-17",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-17",
                        1
                    ],
                    "destination": [
                        "obj-18",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-18",
                        0
                    ],
                    "destination": [
                        "obj-4",
                        1
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
                        1
                    ],
                    "destination": [
                        "obj-22",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-22",
                        0
                    ],
                    "destination": [
                        "obj-4",
                        1
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
                        "obj-25",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-25",
                        1
                    ],
                    "destination": [
                        "obj-26",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-26",
                        0
                    ],
                    "destination": [
                        "obj-4",
                        1
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-28",
                        0
                    ],
                    "destination": [
                        "obj-29",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-29",
                        1
                    ],
                    "destination": [
                        "obj-30",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-30",
                        0
                    ],
                    "destination": [
                        "obj-4",
                        1
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-32",
                        0
                    ],
                    "destination": [
                        "obj-33",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-33",
                        1
                    ],
                    "destination": [
                        "obj-34",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-34",
                        0
                    ],
                    "destination": [
                        "obj-4",
                        1
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-36",
                        0
                    ],
                    "destination": [
                        "obj-37",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-37",
                        1
                    ],
                    "destination": [
                        "obj-38",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-38",
                        0
                    ],
                    "destination": [
                        "obj-4",
                        1
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-40",
                        0
                    ],
                    "destination": [
                        "obj-41",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-41",
                        1
                    ],
                    "destination": [
                        "obj-42",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-42",
                        0
                    ],
                    "destination": [
                        "obj-4",
                        1
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-44",
                        0
                    ],
                    "destination": [
                        "obj-45",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-45",
                        1
                    ],
                    "destination": [
                        "obj-46",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-46",
                        0
                    ],
                    "destination": [
                        "obj-4",
                        1
                    ]
                }
            }
        ],
        "parameters": {
            "obj-8": [
                "f_module_0_disp",
                "live.menu",
                0
            ],
            "obj-9": [
                "f_module_0_file",
                "live.menu",
                0
            ],
            "obj-12": [
                "f_module_1_disp",
                "live.menu",
                0
            ],
            "obj-13": [
                "f_module_1_file",
                "live.menu",
                0
            ],
            "obj-16": [
                "f_module_2_disp",
                "live.menu",
                0
            ],
            "obj-17": [
                "f_module_2_file",
                "live.menu",
                0
            ],
            "obj-20": [
                "f_module_3_disp",
                "live.menu",
                0
            ],
            "obj-21": [
                "f_module_3_file",
                "live.menu",
                0
            ],
            "obj-24": [
                "f_module_4_disp",
                "live.menu",
                0
            ],
            "obj-25": [
                "f_module_4_file",
                "live.menu",
                0
            ],
            "obj-28": [
                "f_module_5_disp",
                "live.menu",
                0
            ],
            "obj-29": [
                "f_module_5_file",
                "live.menu",
                0
            ],
            "obj-32": [
                "f_module_6_disp",
                "live.menu",
                0
            ],
            "obj-33": [
                "f_module_6_file",
                "live.menu",
                0
            ],
            "obj-36": [
                "f_module_7_disp",
                "live.menu",
                0
            ],
            "obj-37": [
                "f_module_7_file",
                "live.menu",
                0
            ],
            "obj-40": [
                "f_module_8_disp",
                "live.menu",
                0
            ],
            "obj-41": [
                "f_module_8_file",
                "live.menu",
                0
            ],
            "obj-44": [
                "f_module_9_disp",
                "live.menu",
                0
            ],
            "obj-45": [
                "f_module_9_file",
                "live.menu",
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