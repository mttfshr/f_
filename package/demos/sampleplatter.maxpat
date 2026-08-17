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
        "rect": [ 139.0, 95.0, 1516.0, 922.0 ],
        "boxes": [
            {
                "box": {
                    "bgmode": 1,
                    "border": 1,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-4",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_wfg_3.maxpat",
                    "numinlets": 3,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 410.5, -115.0, 178.0, 132.0 ],
                    "varname": "vs_wfg_3",
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
                    "id": "obj-2",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_render.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "" ],
                    "patching_rect": [ 3.0, 637.5, 96.85526317358028, 146.5 ],
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 0,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-95",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_vf_vortex_multi_version.maxpat",
                    "numinlets": 5,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 115.0, 546.0, 146.0, 139.0 ],
                    "varname": "f_vf_vortex_multi_version",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 8.0,
                    "id": "obj-90",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 581.5000010728836, 494.3333480656147, 27.0, 16.0 ],
                    "text": "Mod",
                    "textcolor": [ 0.5686274509803921, 0.6980392156862745, 0.9019607843137255, 1.0 ]
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-91",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 581.5000010728836, 476.3333475291729, 39.0, 18.0 ],
                    "text": "Param"
                }
            },
            {
                "box": {
                    "id": "obj-92",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "parameter_enable": 1,
                    "patching_rect": [ 545.5, 476.3333475291729, 27.0, 34.0 ],
                    "saved_attribute_attributes": {
                        "valueof": {
                            "parameter_longname": "live.dial[5]",
                            "parameter_mmax": 1.0,
                            "parameter_mmin": -1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "live.dial",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "shownumber": 0,
                    "triangle": 1,
                    "varname": "live.dial[3]"
                }
            },
            {
                "box": {
                    "activeslidercolor": [ 0.248147342932382, 0.389555476390115, 0.57502990756344, 1.0 ],
                    "appearance": 3,
                    "bordercolor": [ 0.09019607843137255, 0.09019607843137255, 0.09019607843137255, 0.0 ],
                    "fontname": "Ableton Sans Light",
                    "id": "obj-93",
                    "lcdbgcolor": [ 0.06666666666666667, 0.06274509803921569, 0.06274509803921569, 1.0 ],
                    "lcdcolor": [ 0.30196078431372547, 0.3254901960784314, 0.4627450980392157, 1.0 ],
                    "maxclass": "live.numbox",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "parameter_enable": 1,
                    "patching_rect": [ 611.5000019669533, 495.333348095417, 38.0, 15.0 ],
                    "saved_attribute_attributes": {
                        "activeslidercolor": {
                            "expression": "themecolor.live_selection"
                        },
                        "bordercolor": {
                            "expression": ""
                        },
                        "lcdbgcolor": {
                            "expression": ""
                        },
                        "lcdcolor": {
                            "expression": ""
                        },
                        "textcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_longname": "live.numbox[13]",
                            "parameter_mmax": 1.0,
                            "parameter_mmin": -1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "live.numbox[4]",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "textcolor": [ 0.5686274509803921, 0.6980392156862745, 0.9019607843137255, 1.0 ],
                    "textjustification": 0,
                    "varname": "live.numbox[5]"
                }
            },
            {
                "box": {
                    "appearance": 3,
                    "bordercolor": [ 0.09019607843137255, 0.09019607843137255, 0.09019607843137255, 0.0 ],
                    "fontname": "Ableton Sans Light",
                    "id": "obj-94",
                    "lcdbgcolor": [ 0.06666666666666667, 0.06274509803921569, 0.06274509803921569, 1.0 ],
                    "lcdcolor": [ 0.30196078431372547, 0.3254901960784314, 0.4627450980392157, 1.0 ],
                    "maxclass": "live.numbox",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "parameter_enable": 1,
                    "patching_rect": [ 615.5000020861626, 476.3333475291729, 34.0, 15.0 ],
                    "saved_attribute_attributes": {
                        "bordercolor": {
                            "expression": ""
                        },
                        "lcdbgcolor": {
                            "expression": ""
                        },
                        "lcdcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_longname": "live.numbox[14]",
                            "parameter_mmax": 1.0,
                            "parameter_mmin": -1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "live.numbox[4]",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "textjustification": 0,
                    "varname": "live.numbox[6]"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 8.0,
                    "id": "obj-85",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 581.5000010728836, 455.66668024659157, 27.0, 16.0 ],
                    "text": "Mod",
                    "textcolor": [ 0.5686274509803921, 0.6980392156862745, 0.9019607843137255, 1.0 ]
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-86",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 581.5000010728836, 437.66667971014977, 39.0, 18.0 ],
                    "text": "Param"
                }
            },
            {
                "box": {
                    "id": "obj-87",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "parameter_enable": 1,
                    "patching_rect": [ 545.5, 437.66667971014977, 27.0, 34.0 ],
                    "saved_attribute_attributes": {
                        "valueof": {
                            "parameter_longname": "live.dial[4]",
                            "parameter_mmax": 1.0,
                            "parameter_mmin": -1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "live.dial",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "shownumber": 0,
                    "triangle": 1,
                    "varname": "live.dial[2]"
                }
            },
            {
                "box": {
                    "activeslidercolor": [ 0.248147342932382, 0.389555476390115, 0.57502990756344, 1.0 ],
                    "appearance": 3,
                    "bordercolor": [ 0.09019607843137255, 0.09019607843137255, 0.09019607843137255, 0.0 ],
                    "fontname": "Ableton Sans Light",
                    "id": "obj-88",
                    "lcdbgcolor": [ 0.06666666666666667, 0.06274509803921569, 0.06274509803921569, 1.0 ],
                    "lcdcolor": [ 0.30196078431372547, 0.3254901960784314, 0.4627450980392157, 1.0 ],
                    "maxclass": "live.numbox",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "parameter_enable": 1,
                    "patching_rect": [ 611.5000019669533, 456.6666802763939, 38.0, 15.0 ],
                    "saved_attribute_attributes": {
                        "activeslidercolor": {
                            "expression": "themecolor.live_selection"
                        },
                        "bordercolor": {
                            "expression": ""
                        },
                        "lcdbgcolor": {
                            "expression": ""
                        },
                        "lcdcolor": {
                            "expression": ""
                        },
                        "textcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_longname": "live.numbox[8]",
                            "parameter_mmax": 1.0,
                            "parameter_mmin": -1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "live.numbox[4]",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "textcolor": [ 0.5686274509803921, 0.6980392156862745, 0.9019607843137255, 1.0 ],
                    "textjustification": 0,
                    "varname": "live.numbox[1]"
                }
            },
            {
                "box": {
                    "appearance": 3,
                    "bordercolor": [ 0.09019607843137255, 0.09019607843137255, 0.09019607843137255, 0.0 ],
                    "fontname": "Ableton Sans Light",
                    "id": "obj-89",
                    "lcdbgcolor": [ 0.06666666666666667, 0.06274509803921569, 0.06274509803921569, 1.0 ],
                    "lcdcolor": [ 0.30196078431372547, 0.3254901960784314, 0.4627450980392157, 1.0 ],
                    "maxclass": "live.numbox",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "parameter_enable": 1,
                    "patching_rect": [ 615.5000020861626, 437.66667971014977, 34.0, 15.0 ],
                    "saved_attribute_attributes": {
                        "bordercolor": {
                            "expression": ""
                        },
                        "lcdbgcolor": {
                            "expression": ""
                        },
                        "lcdcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_longname": "live.numbox[12]",
                            "parameter_mmax": 1.0,
                            "parameter_mmin": -1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "live.numbox[4]",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "textjustification": 0,
                    "varname": "live.numbox[4]"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 8.0,
                    "id": "obj-64",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 581.5, 417.5, 27.0, 16.0 ],
                    "text": "Mod",
                    "textcolor": [ 0.5686274509803921, 0.6980392156862745, 0.9019607843137255, 1.0 ]
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-63",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 581.5, 399.5, 39.0, 18.0 ],
                    "text": "Param"
                }
            },
            {
                "box": {
                    "id": "obj-59",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "parameter_enable": 1,
                    "patching_rect": [ 545.5, 399.5, 27.0, 34.0 ],
                    "saved_attribute_attributes": {
                        "valueof": {
                            "parameter_longname": "live.dial[1]",
                            "parameter_mmax": 1.0,
                            "parameter_mmin": -1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "live.dial",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "shownumber": 0,
                    "triangle": 1,
                    "varname": "live.dial[1]"
                }
            },
            {
                "box": {
                    "activeslidercolor": [ 0.248147342932382, 0.389555476390115, 0.57502990756344, 1.0 ],
                    "appearance": 3,
                    "bordercolor": [ 0.09019607843137255, 0.09019607843137255, 0.09019607843137255, 0.0 ],
                    "fontname": "Ableton Sans Light",
                    "id": "obj-60",
                    "lcdbgcolor": [ 0.06666666666666667, 0.06274509803921569, 0.06274509803921569, 1.0 ],
                    "lcdcolor": [ 0.30196078431372547, 0.3254901960784314, 0.4627450980392157, 1.0 ],
                    "maxclass": "live.numbox",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "parameter_enable": 1,
                    "patching_rect": [ 611.5, 418.5, 38.0, 15.0 ],
                    "saved_attribute_attributes": {
                        "activeslidercolor": {
                            "expression": "themecolor.live_selection"
                        },
                        "bordercolor": {
                            "expression": ""
                        },
                        "lcdbgcolor": {
                            "expression": ""
                        },
                        "lcdcolor": {
                            "expression": ""
                        },
                        "textcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_longname": "live.numbox[6]",
                            "parameter_mmax": 1.0,
                            "parameter_mmin": -1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "live.numbox[4]",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "textcolor": [ 0.5686274509803921, 0.6980392156862745, 0.9019607843137255, 1.0 ],
                    "textjustification": 0,
                    "varname": "live.numbox[2]"
                }
            },
            {
                "box": {
                    "appearance": 3,
                    "bordercolor": [ 0.09019607843137255, 0.09019607843137255, 0.09019607843137255, 0.0 ],
                    "fontname": "Ableton Sans Light",
                    "id": "obj-61",
                    "lcdbgcolor": [ 0.06666666666666667, 0.06274509803921569, 0.06274509803921569, 1.0 ],
                    "lcdcolor": [ 0.30196078431372547, 0.3254901960784314, 0.4627450980392157, 1.0 ],
                    "maxclass": "live.numbox",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "parameter_enable": 1,
                    "patching_rect": [ 615.5, 399.5, 34.0, 15.0 ],
                    "saved_attribute_attributes": {
                        "bordercolor": {
                            "expression": ""
                        },
                        "lcdbgcolor": {
                            "expression": ""
                        },
                        "lcdcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_longname": "live.numbox[7]",
                            "parameter_mmax": 1.0,
                            "parameter_mmin": -1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "live.numbox[4]",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "textjustification": 0,
                    "varname": "live.numbox[3]"
                }
            },
            {
                "box": {
                    "bgmode": 1,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-31",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_vf_streak.maxpat",
                    "numinlets": 2,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 486.0, 652.0, 194.0, 102.0 ],
                    "varname": "f_vf_streak",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 1,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-30",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_vf_warp.maxpat",
                    "numinlets": 2,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 337.0, 396.0, 107.0, 90.0 ],
                    "varname": "f_vf_warp",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 1,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-26",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_vf_vortex.maxpat",
                    "numinlets": 5,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 703.0, 646.0, 199.0, 164.0 ],
                    "varname": "f_vf_vortex",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 1,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-23",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_util_profile.maxpat",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 933.0, 710.0, 200.0, 120.0 ],
                    "varname": "f_util_profile",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 1,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-22",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_texrouter.maxpat",
                    "numinlets": 4,
                    "numoutlets": 4,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "", "", "", "" ],
                    "patching_rect": [ 920.0, 539.0, 213.0, 130.0 ],
                    "varname": "f_texrouter",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 1,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-21",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_tone_curve.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 1163.0, 664.0, 150.0, 120.0 ],
                    "varname": "f_tone_curve",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 1,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-20",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_luma_processor.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 1163.0, 532.0, 150.0, 120.0 ],
                    "varname": "f_luma_processor",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 1,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-19",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_hue_processor.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 1155.0, 401.0, 150.0, 120.0 ],
                    "varname": "f_hue_processor",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 1,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-18",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_channel_grader.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 972.0, 352.5, 150.0, 165.0 ],
                    "varname": "f_channel_grader",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 1,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-17",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_caustic.maxpat",
                    "numinlets": 2,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 552.0, 538.5, 195.0, 107.0 ],
                    "varname": "f_caustic",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 1,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-14",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_stereo.maxpat",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 352.0, 253.0, 161.0, 94.0 ],
                    "varname": "f_stereo",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 1,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-13",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_mobius.maxpat",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 110.0, 249.0, 189.0, 94.0 ],
                    "varname": "f_mobius",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 1,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-12",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_droste.maxpat",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 515.0, 287.0, 154.0, 93.0 ],
                    "varname": "f_droste",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 1,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-11",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_stipple.maxpat",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 402.0, 48.0, 195.0, 161.0 ],
                    "varname": "f_stipple",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 1,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-10",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_chladni.maxpat",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 635.0, 42.0, 301.0, 221.0 ],
                    "varname": "f_chladni",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 1,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-9",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_masonry.maxpat",
                    "numinlets": 4,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 994.0, 71.0, 311.0, 248.0 ],
                    "varname": "f_masonry",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 1,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-8",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_vf_vortex_multi.maxpat",
                    "numinlets": 5,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 268.0, 519.0, 191.0, 284.0 ],
                    "varname": "f_vf_vortex_multi",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 1,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-5",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_lens.maxpat",
                    "numinlets": 5,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 766.0, 355.0, 180.0, 160.0 ],
                    "varname": "f_lens",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 1,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-28",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_vf_fieldmap.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 148.5, 370.0, 130.0, 93.0 ],
                    "varname": "f_vf_fieldmap",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 1,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-27",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_grain.maxpat",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 110.0, 16.0, 245.0, 174.0 ],
                    "varname": "f_grain",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 0,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-24",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_vf_advect.maxpat",
                    "numinlets": 2,
                    "numoutlets": 3,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 503.0, 779.0, 198.0, 137.0 ],
                    "varname": "f_vf_advect",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 0,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-7",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_modules.maxpat",
                    "numinlets": 0,
                    "numoutlets": 0,
                    "offset": [ 0.0, 0.0 ],
                    "patching_rect": [ 17.0, 339.16668024659157, 96.0, 249.0 ],
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
                    "id": "obj-3",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_output.maxpat",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "offset": [ 0.0, 0.0 ],
                    "patching_rect": [ 176.0, 232.0, 157.0, 22.0 ],
                    "varname": "vs_output",
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
                    "id": "obj-1",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_modules.maxpat",
                    "numinlets": 0,
                    "numoutlets": 0,
                    "offset": [ 0.0, 0.0 ],
                    "patching_rect": [ 3.0, 7.0, 79.0, 316.0 ],
                    "viewvisibility": 1
                }
            }
        ],
        "lines": [
            {
                "patchline": {
                    "destination": [ "obj-3", 0 ],
                    "source": [ "obj-27", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-24", 0 ],
                    "source": [ "obj-31", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-11", 0 ],
                    "source": [ "obj-4", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-24", 1 ],
                    "order": 0,
                    "source": [ "obj-8", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-31", 1 ],
                    "order": 1,
                    "source": [ "obj-8", 0 ]
                }
            }
        ],
        "parameters": {
            "obj-10::obj-20": [ "z2", "note", 0 ],
            "obj-10::obj-23": [ "z5", "amp", 0 ],
            "obj-10::obj-26": [ "ph0", "dishradius", 0 ],
            "obj-10::obj-29": [ "ph3", "reflectamt", 0 ],
            "obj-10::obj-32": [ "ph6", "linesharpness", 0 ],
            "obj-10::obj-35": [ "reflectamt", "ph0", 0 ],
            "obj-10::obj-38": [ "view_mode", "spread", 0 ],
            "obj-10::obj-41": [ "mode[1]", "mode", 0 ],
            "obj-10::obj-44": [ "view_mode[1]", "view_mode", 0 ],
            "obj-10::obj-47": [ "gain", "gain", 0 ],
            "obj-11::obj-20": [ "freq", "freq", 0 ],
            "obj-11::obj-23": [ "coarseness", "coarseness", 0 ],
            "obj-11::obj-26": [ "anisotropy", "anisotropy", 0 ],
            "obj-11::obj-29": [ "angle[1]", "angle", 0 ],
            "obj-11::obj-32": [ "zoom", "zoom", 0 ],
            "obj-11::obj-35": [ "threshold", "threshold", 0 ],
            "obj-11::obj-38": [ "colorize", "colorize", 0 ],
            "obj-11::obj-41": [ "along_phase", "along_phase", 0 ],
            "obj-11::obj-44": [ "across_phase", "across_phase", 0 ],
            "obj-11::obj-47": [ "softness[3]", "softness", 0 ],
            "obj-12::obj-2": [ "zoom[3]", "zoom", 0 ],
            "obj-12::obj-3": [ "n_arms", "n_arms", 0 ],
            "obj-12::obj-4": [ "twist", "twist", 0 ],
            "obj-12::obj-5": [ "rotation", "rotation", 0 ],
            "obj-13::obj-10": [ "cx[3]", "cx", 0 ],
            "obj-13::obj-12": [ "cy", "cy", 0 ],
            "obj-13::obj-14": [ "rotate[1]", "rotate", 0 ],
            "obj-13::obj-16": [ "zoom[2]", "zoom", 0 ],
            "obj-13::obj-18": [ "invert", "invert", 0 ],
            "obj-14::obj-10": [ "lon", "lon", 0 ],
            "obj-14::obj-12": [ "lat", "lat", 0 ],
            "obj-14::obj-14": [ "spin", "spin", 0 ],
            "obj-14::obj-16": [ "proj", "proj", 0 ],
            "obj-14::obj-32": [ "circ", "circ", 0 ],
            "obj-17::obj-20": [ "intensity", "mix_pct", 0 ],
            "obj-17::obj-23": [ "scale[1]", "scale", 0 ],
            "obj-17::obj-26": [ "softness[2]", "softness", 0 ],
            "obj-17::obj-29": [ "color_shift[1]", "softness", 0 ],
            "obj-17::obj-32": [ "color_shift", "color_shift", 0 ],
            "obj-18::obj-11": [ "m_lift", "m_lift", 0 ],
            "obj-18::obj-14": [ "m_gamma", "m_gamma", 0 ],
            "obj-18::obj-15": [ "m_gain", "m_gain", 0 ],
            "obj-18::obj-49": [ "r_lift", "r_lift", 0 ],
            "obj-18::obj-58": [ "r_gamma", "r_gamma", 0 ],
            "obj-18::obj-59": [ "r_gain", "r_gain", 0 ],
            "obj-18::obj-67": [ "g_gain", "g_gain", 0 ],
            "obj-18::obj-68": [ "g_gamma", "g_gamma", 0 ],
            "obj-18::obj-69": [ "g_lift", "live.dial", 0 ],
            "obj-18::obj-71": [ "b_gain", "b_gain", 0 ],
            "obj-18::obj-72": [ "b_gamma", "b_gamma", 0 ],
            "obj-18::obj-73": [ "b_lift", "b_lift", 0 ],
            "obj-19::obj-13": [ "sat_amt", "sat_amt", 0 ],
            "obj-19::obj-14": [ "lum_shift", "lum_shift", 0 ],
            "obj-19::obj-15": [ "hue_shift", "hue_shift", 0 ],
            "obj-19::obj-20": [ "hue_upper", "hue_upper", 0 ],
            "obj-19::obj-26": [ "edge_falloff", "edge_falloff", 0 ],
            "obj-19::obj-5": [ "live.numbox[2]", "live.numbox", 0 ],
            "obj-19::obj-7": [ "hue_lower", "hue_lower", 0 ],
            "obj-1::obj-14": [ "live.menu[1]", "live.menu", 0 ],
            "obj-1::obj-16": [ "live.menu[2]", "live.menu", 0 ],
            "obj-1::obj-18": [ "live.menu[16]", "live.menu", 0 ],
            "obj-1::obj-2": [ "live.menu", "live.menu", 0 ],
            "obj-1::obj-22": [ "live.menu[17]", "live.menu", 0 ],
            "obj-1::obj-24": [ "live.menu[9]", "live.menu", 0 ],
            "obj-1::obj-25": [ "live.menu[10]", "live.menu", 0 ],
            "obj-1::obj-26": [ "live.menu[11]", "live.menu", 0 ],
            "obj-1::obj-27": [ "live.menu[12]", "live.menu", 0 ],
            "obj-1::obj-29": [ "live.menu[13]", "live.menu", 0 ],
            "obj-1::obj-30": [ "live.menu[14]", "live.menu", 0 ],
            "obj-1::obj-33": [ "live.menu[15]", "live.menu", 0 ],
            "obj-1::obj-36": [ "live.menu[3]", "live.menu", 0 ],
            "obj-1::obj-52": [ "live.menu[4]", "live.menu", 0 ],
            "obj-1::obj-53": [ "live.menu[5]", "live.menu", 0 ],
            "obj-1::obj-56": [ "live.menu[6]", "live.menu", 0 ],
            "obj-20::obj-13": [ "sat_amt[1]", "sat_amt", 0 ],
            "obj-20::obj-14": [ "lum_shift[1]", "lum_shift", 0 ],
            "obj-20::obj-15": [ "hue_shift[1]", "hue_shift", 0 ],
            "obj-20::obj-20": [ "mid_high", "mid_high", 0 ],
            "obj-20::obj-26": [ "edge_falloff[3]", "edge_falloff", 0 ],
            "obj-20::obj-5": [ "live.numbox[3]", "live.numbox", 0 ],
            "obj-20::obj-7": [ "low_mid", "low_mid", 0 ],
            "obj-21::obj-13": [ "shadows", "shadows", 0 ],
            "obj-21::obj-14": [ "midtones", "midtones", 0 ],
            "obj-21::obj-15": [ "highlights", "highlights", 0 ],
            "obj-21::obj-22": [ "edge_falloff[2]", "edge_falloff", 0 ],
            "obj-21::obj-24": [ "low_mid[1]", "low_mid", 0 ],
            "obj-21::obj-25": [ "mid_high[1]", "mid_high", 0 ],
            "obj-21::obj-29": [ "live.numbox", "live.numbox", 0 ],
            "obj-22::obj-29": [ "tog_00", "tog_00", 0 ],
            "obj-22::obj-30": [ "tog_01", "tog_01", 0 ],
            "obj-22::obj-31": [ "tog_02", "tog_02", 0 ],
            "obj-22::obj-32": [ "tog_03", "tog_03", 0 ],
            "obj-22::obj-33": [ "tog_10", "tog_10", 0 ],
            "obj-22::obj-34": [ "tog_11", "tog_11", 0 ],
            "obj-22::obj-35": [ "tog_12", "tog_12", 0 ],
            "obj-22::obj-36": [ "tog_13", "tog_13", 0 ],
            "obj-22::obj-37": [ "tog_20", "tog_20", 0 ],
            "obj-22::obj-38": [ "tog_21", "tog_21", 0 ],
            "obj-22::obj-39": [ "tog_22", "tog_22", 0 ],
            "obj-22::obj-40": [ "tog_23", "tog_23", 0 ],
            "obj-22::obj-41": [ "tog_30", "tog_30", 0 ],
            "obj-22::obj-42": [ "tog_31", "tog_31", 0 ],
            "obj-22::obj-43": [ "tog_32", "tog_32", 0 ],
            "obj-22::obj-44": [ "tog_33", "tog_33", 0 ],
            "obj-22::obj-45": [ "bypass[1]", "bypass", 0 ],
            "obj-23::obj-20": [ "res_rows", "res_rows", 0 ],
            "obj-23::obj-23": [ "res_cols", "res_cols", 0 ],
            "obj-23::obj-26": [ "freq[1]", "freq", 0 ],
            "obj-23::obj-70": [ "row_op", "row_op", 0 ],
            "obj-23::obj-80": [ "col_op", "col_op", 0 ],
            "obj-24::obj-20": [ "dt", "dt", 0 ],
            "obj-24::obj-23": [ "decay", "decay", 0 ],
            "obj-24::obj-26": [ "injection", "injection", 0 ],
            "obj-24::obj-29": [ "mix_amt", "gain", 0 ],
            "obj-24::obj-32": [ "separate", "separate", 0 ],
            "obj-24::obj-35": [ "mode", "mode", 0 ],
            "obj-24::obj-90": [ "mix_pct", "mix_pct", 0 ],
            "obj-26::obj-20": [ "cx[2]", "cx", 0 ],
            "obj-26::obj-23": [ "cy[1]", "cy", 0 ],
            "obj-26::obj-26": [ "convergence", "convergence", 0 ],
            "obj-26::obj-29": [ "curl", "curl", 0 ],
            "obj-26::obj-32": [ "falloff[3]", "falloff", 0 ],
            "obj-26::obj-35": [ "cx_amt[1]", "cx_amt", 0 ],
            "obj-26::obj-38": [ "cy_amt[1]", "cy_amt", 0 ],
            "obj-26::obj-41": [ "convergence_amt", "convergence_amt", 0 ],
            "obj-26::obj-44": [ "curl_amt[1]", "curl_amt", 0 ],
            "obj-27::obj-11": [ "density", "density", 0 ],
            "obj-27::obj-13": [ "amount", "amount", 0 ],
            "obj-27::obj-15": [ "persistence", "persistence", 0 ],
            "obj-27::obj-2": [ "fade", "fade", 0 ],
            "obj-27::obj-25": [ "size", "size", 0 ],
            "obj-27::obj-27": [ "size_var", "size_var", 0 ],
            "obj-27::obj-29": [ "shape", "shape", 0 ],
            "obj-27::obj-31": [ "softness", "softness", 0 ],
            "obj-27::obj-37": [ "jitter", "jitter", 0 ],
            "obj-27::obj-40": [ "ch_diverge", "ch_diverge", 0 ],
            "obj-27::obj-43": [ "field", "field", 0 ],
            "obj-27::obj-60": [ "luma_gate", "luma_gate", 0 ],
            "obj-27::obj-63": [ "displace", "displace", 0 ],
            "obj-27::obj-71": [ "edge_mode_menu", "edge_mode_menu", 0 ],
            "obj-27::obj-82": [ "sv_seed", "sv_seed", 0 ],
            "obj-28::obj-20": [ "strength", "gain", 0 ],
            "obj-28::obj-23": [ "scale", "scale", 0 ],
            "obj-28::obj-28": [ "rotate", "rotate", 0 ],
            "obj-28::obj-31": [ "thresh", "thresh", 0 ],
            "obj-2::obj-19": [ "dim_x[2]", "dim_x", 0 ],
            "obj-2::obj-23": [ "pwm[1]", "pwm", 0 ],
            "obj-2::obj-36": [ "live.text[11]", "live.text", 0 ],
            "obj-2::obj-40": [ "live.text[6]", "live.text", 0 ],
            "obj-2::obj-41": [ "dim_y[2]", "dim_y", 0 ],
            "obj-2::obj-42": [ "dim_x[3]", "dim_x", 0 ],
            "obj-2::obj-45": [ "live.text[10]", "live.text", 0 ],
            "obj-2::obj-48": [ "live.text[7]", "live.text", 0 ],
            "obj-2::obj-5": [ "live.text[9]", "live.text", 0 ],
            "obj-2::obj-6": [ "live.text[8]", "live.text", 0 ],
            "obj-30::obj-20": [ "strength[3]", "strength", 0 ],
            "obj-31::obj-20": [ "strength[2]", "strength", 0 ],
            "obj-31::obj-23": [ "length", "mix_pct", 0 ],
            "obj-31::obj-26": [ "falloff[2]", "falloff", 0 ],
            "obj-31::obj-29": [ "color_shift[3]", "color_shift", 0 ],
            "obj-31::obj-32": [ "color_shift[2]", "color_shift", 0 ],
            "obj-3::obj-1": [ "toggle[1]", "toggle[1]", 0 ],
            "obj-3::obj-10": [ "toggle[3]", "toggle[2]", 0 ],
            "obj-3::obj-36": [ "uppr_x", "uppr_x", 0 ],
            "obj-4::obj-10": [ "wfg3_bias", "Bias", 0 ],
            "obj-4::obj-14": [ "wfg3_biasm", "BM", 0 ],
            "obj-4::obj-17": [ "live.menu[19]", "live.menu", 0 ],
            "obj-4::obj-22": [ "live.toggle[1]", "live.toggle[1]", 0 ],
            "obj-4::obj-24": [ "live.toggle", "live.toggle", 0 ],
            "obj-4::obj-25": [ "wfg3_curve", "curve", 0 ],
            "obj-4::obj-29": [ "wfg3_freq", "Freq", 0 ],
            "obj-4::obj-30": [ "wfg3_angle", "Angle", 0 ],
            "obj-4::obj-4": [ "wfg3_fm", "FM", 0 ],
            "obj-4::obj-42": [ "live.toggle[2]", "live.toggle", 0 ],
            "obj-4::obj-53": [ "wfg3_speed", "Speed", 0 ],
            "obj-4::obj-6": [ "wfg3_pm", "PM", 0 ],
            "obj-4::obj-63": [ "wfg3_phase", "Phase", 0 ],
            "obj-4::obj-65": [ "wfg3_shape", "Shape", 0 ],
            "obj-4::obj-72": [ "wfg3_phase_time_switch", "wfg2_phase_time_switch", 0 ],
            "obj-59": [ "live.dial[1]", "live.dial", 0 ],
            "obj-5::obj-19d": [ "panel_toggle", "panel_toggle", 0 ],
            "obj-5::obj-20": [ "aberration", "aberration", 0 ],
            "obj-5::obj-23": [ "tilt", "distortion", 0 ],
            "obj-5::obj-26": [ "slope", "transmission", 0 ],
            "obj-5::obj-29": [ "aberration_mod", "aberration_mod", 0 ],
            "obj-5::obj-300": [ "range_aberration", "range_aberration", 0 ],
            "obj-5::obj-310": [ "range_distortion", "range_distortion", 0 ],
            "obj-5::obj-32": [ "distortion_mod", "distortion_mod", 0 ],
            "obj-5::obj-320": [ "range_transmission", "range_transmission", 0 ],
            "obj-5::obj-35": [ "transmission_mod", "transmission_mod", 0 ],
            "obj-5::obj-38": [ "surface_mod", "surface_mod", 0 ],
            "obj-5::obj-390": [ "range_ghost_spacing", "range_ghost_spacing", 0 ],
            "obj-5::obj-41": [ "ghost", "ghost", 0 ],
            "obj-5::obj-44": [ "ghost_count", "ghost_count", 0 ],
            "obj-5::obj-47": [ "ghost_spacing", "ghost_spacing", 0 ],
            "obj-5::obj-50": [ "halation", "halation", 0 ],
            "obj-5::obj-53": [ "halation_threshold", "halation_threshold", 0 ],
            "obj-60": [ "live.numbox[6]", "live.numbox[4]", 0 ],
            "obj-61": [ "live.numbox[7]", "live.numbox[4]", 0 ],
            "obj-7::obj-12": [ "f_module_1_disp", "live.menu", 0 ],
            "obj-7::obj-13": [ "f_module_1_file", "live.menu", 0 ],
            "obj-7::obj-16": [ "f_module_2_disp", "live.menu", 0 ],
            "obj-7::obj-17": [ "f_module_2_file", "live.menu", 0 ],
            "obj-7::obj-20": [ "cx", "live.menu", 0 ],
            "obj-7::obj-21": [ "f_module_3_file", "live.menu", 0 ],
            "obj-7::obj-24": [ "f_module_4_disp", "live.menu", 0 ],
            "obj-7::obj-25": [ "f_module_4_file", "live.menu", 0 ],
            "obj-7::obj-28": [ "f_module_5_disp", "live.menu", 0 ],
            "obj-7::obj-29": [ "f_module_5_file", "live.menu", 0 ],
            "obj-7::obj-32": [ "f_module_6_disp", "live.menu", 0 ],
            "obj-7::obj-33": [ "f_module_6_file", "live.menu", 0 ],
            "obj-7::obj-36": [ "f_module_7_disp", "live.menu", 0 ],
            "obj-7::obj-37": [ "f_module_7_file", "live.menu", 0 ],
            "obj-7::obj-8": [ "f_module_0_disp", "live.menu", 0 ],
            "obj-7::obj-9": [ "f_module_0_file", "live.menu", 0 ],
            "obj-87": [ "live.dial[4]", "live.dial", 0 ],
            "obj-88": [ "live.numbox[8]", "live.numbox[4]", 0 ],
            "obj-89": [ "live.numbox[12]", "live.numbox[4]", 0 ],
            "obj-8::obj-19::obj-2": [ "vs_phase_ctrl", "vs_phase_ctrl", 0 ],
            "obj-8::obj-20": [ "s1_cx", "s1_cx", 0 ],
            "obj-8::obj-23": [ "s1_cy", "s1_cy", 0 ],
            "obj-8::obj-26": [ "s1_conv", "s1_conv", 0 ],
            "obj-8::obj-29": [ "s1_curl", "s1_curl", 0 ],
            "obj-8::obj-32": [ "s2_cx", "s2_cx", 0 ],
            "obj-8::obj-35": [ "s2_cy", "s2_cy", 0 ],
            "obj-8::obj-38": [ "s2_conv", "s2_conv", 0 ],
            "obj-8::obj-41": [ "s2_curl", "s2_curl", 0 ],
            "obj-8::obj-44": [ "s3_cx", "s3_cx", 0 ],
            "obj-8::obj-47": [ "s3_cy", "s3_cy", 0 ],
            "obj-8::obj-50": [ "s3_conv", "s3_conv", 0 ],
            "obj-8::obj-53": [ "s3_curl", "s3_curl", 0 ],
            "obj-8::obj-56": [ "falloff", "falloff", 0 ],
            "obj-8::obj-59": [ "cx_amt", "cx_amt", 0 ],
            "obj-8::obj-62": [ "cy_amt", "cy_amt", 0 ],
            "obj-8::obj-65": [ "conv_amt", "conv_amt", 0 ],
            "obj-8::obj-68": [ "curl_amt", "curl_amt", 0 ],
            "obj-8::obj-76": [ "nodes", "nodes", 0 ],
            "obj-92": [ "live.dial[5]", "live.dial", 0 ],
            "obj-93": [ "live.numbox[13]", "live.numbox[4]", 0 ],
            "obj-94": [ "live.numbox[14]", "live.numbox[4]", 0 ],
            "obj-95::obj-102": [ "live.numbox[17]", "live.numbox", 0 ],
            "obj-95::obj-105": [ "live.numbox[16]", "live.numbox", 0 ],
            "obj-95::obj-20": [ "s1_cx[1]", "s1_cx", 0 ],
            "obj-95::obj-23": [ "s1_cy[1]", "s1_cy", 0 ],
            "obj-95::obj-26": [ "s1_conv[1]", "s1_conv", 0 ],
            "obj-95::obj-29": [ "s1_curl[1]", "s1_curl", 0 ],
            "obj-95::obj-32": [ "s2_cx[1]", "s2_cx", 0 ],
            "obj-95::obj-35": [ "s2_cy[1]", "s2_cy", 0 ],
            "obj-95::obj-38": [ "s2_conv[1]", "s2_conv", 0 ],
            "obj-95::obj-41": [ "s2_curl[1]", "s2_curl", 0 ],
            "obj-95::obj-44": [ "s3_cx[1]", "s3_cx", 0 ],
            "obj-95::obj-47": [ "s3_cy[1]", "s3_cy", 0 ],
            "obj-95::obj-50": [ "s3_conv[1]", "s3_conv", 0 ],
            "obj-95::obj-53": [ "s3_curl[1]", "s3_curl", 0 ],
            "obj-95::obj-56": [ "falloff[4]", "falloff", 0 ],
            "obj-95::obj-59": [ "cx_amt[2]", "cx_amt", 0 ],
            "obj-95::obj-62": [ "cy_amt[2]", "cy_amt", 0 ],
            "obj-95::obj-65": [ "conv_amt[1]", "conv_amt", 0 ],
            "obj-95::obj-68": [ "curl_amt[2]", "curl_amt", 0 ],
            "obj-95::obj-76": [ "nodes[1]", "nodes", 0 ],
            "obj-95::obj-81": [ "live.numbox[15]", "live.numbox", 0 ],
            "obj-95::obj-83": [ "live.numbox[1]", "live.numbox", 0 ],
            "obj-95::obj-84": [ "live.numbox[18]", "live.numbox", 0 ],
            "obj-95::obj-99": [ "live.numbox[4]", "live.numbox", 0 ],
            "obj-9::obj-125": [ "panel_toggle[1]", "panel_toggle", 0 ],
            "obj-9::obj-20": [ "courses", "courses", 0 ],
            "obj-9::obj-21": [ "bond", "bond", 0 ],
            "obj-9::obj-22": [ "offset", "offset", 0 ],
            "obj-9::obj-23": [ "angle", "angle", 0 ],
            "obj-9::obj-24": [ "skip", "skip", 0 ],
            "obj-9::obj-25": [ "quantize", "quantize", 0 ],
            "obj-9::obj-26": [ "regularity", "regularity", 0 ],
            "obj-9::obj-27": [ "drift", "drift", 0 ],
            "obj-9::obj-28": [ "phase", "phase", 0 ],
            "obj-9::obj-29": [ "speed_var", "speed_var", 0 ],
            "obj-9::obj-30": [ "mortar", "mortar", 0 ],
            "obj-9::obj-31": [ "softness[1]", "softness", 0 ],
            "obj-9::obj-32": [ "width", "width", 0 ],
            "obj-9::obj-33": [ "roundness", "roundness", 0 ],
            "obj-9::obj-35": [ "course_color", "course_color", 0 ],
            "obj-9::obj-36": [ "brick_color", "brick_color", 0 ],
            "obj-9::obj-90": [ "course_seed", "course_seed", 0 ],
            "obj-9::obj-91": [ "brick_seed", "brick_seed", 0 ],
            "parameterbanks": {
                "0": {
                    "index": 0,
                    "name": "",
                    "parameters": [ "-", "-", "-", "-", "-", "-", "-", "-" ],
                    "buttons": [ "-", "-", "-", "-", "-", "-", "-", "-" ]
                }
            },
            "parameter_overrides": {
                "obj-10::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_longname": "z2",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-10::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_longname": "z5",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-10::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_longname": "ph0",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-10::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_longname": "ph3",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-10::obj-32": {
                    "parameter_invisible": 0,
                    "parameter_longname": "ph6",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-10::obj-35": {
                    "parameter_invisible": 0,
                    "parameter_longname": "reflectamt",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-10::obj-38": {
                    "parameter_invisible": 0,
                    "parameter_longname": "view_mode",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-10::obj-41": {
                    "parameter_longname": "mode[1]"
                },
                "obj-10::obj-44": {
                    "parameter_longname": "view_mode[1]"
                },
                "obj-11::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-11::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-11::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-11::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_longname": "angle[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "angle",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-11::obj-32": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-11::obj-35": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-11::obj-38": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-11::obj-41": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-11::obj-44": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-11::obj-47": {
                    "parameter_invisible": 0,
                    "parameter_longname": "softness[3]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "softness",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-12::obj-2": {
                    "parameter_invisible": 0,
                    "parameter_longname": "zoom[3]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "zoom",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-12::obj-3": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 0,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-12::obj-4": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-12::obj-5": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-13::obj-10": {
                    "parameter_invisible": 0,
                    "parameter_longname": "cx[3]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "cx",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-13::obj-12": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-13::obj-14": {
                    "parameter_invisible": 0,
                    "parameter_longname": "rotate[1]",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-13::obj-16": {
                    "parameter_invisible": 0,
                    "parameter_longname": "zoom[2]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "zoom",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-13::obj-18": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-14::obj-10": {
                    "parameter_invisible": 0,
                    "parameter_longname": "lon",
                    "parameter_modmode": 3,
                    "parameter_shortname": "lon",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-14::obj-12": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-14::obj-14": {
                    "parameter_invisible": 0,
                    "parameter_longname": "spin",
                    "parameter_modmode": 3,
                    "parameter_shortname": "spin",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-14::obj-16": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-17::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_longname": "intensity",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-17::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_longname": "scale[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "scale",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-17::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_longname": "softness[2]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "softness",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-17::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_longname": "color_shift[1]",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-18::obj-11": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-18::obj-14": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-18::obj-15": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-18::obj-49": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-18::obj-58": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-18::obj-59": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-18::obj-67": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-18::obj-68": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-18::obj-69": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-18::obj-71": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-18::obj-72": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-18::obj-73": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-19::obj-13": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-19::obj-14": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-19::obj-15": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-19::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-19::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-19::obj-7": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-1::obj-14": {
                    "parameter_longname": "live.menu[1]"
                },
                "obj-1::obj-16": {
                    "parameter_longname": "live.menu[2]"
                },
                "obj-1::obj-18": {
                    "parameter_longname": "live.menu[16]"
                },
                "obj-1::obj-22": {
                    "parameter_longname": "live.menu[17]"
                },
                "obj-20::obj-13": {
                    "parameter_invisible": 0,
                    "parameter_longname": "sat_amt[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "sat_amt",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-20::obj-14": {
                    "parameter_invisible": 0,
                    "parameter_longname": "lum_shift[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "lum_shift",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-20::obj-15": {
                    "parameter_invisible": 0,
                    "parameter_longname": "hue_shift[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "hue_shift",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-20::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-20::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_longname": "edge_falloff[3]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "edge_falloff",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-20::obj-5": {
                    "parameter_longname": "live.numbox[3]"
                },
                "obj-20::obj-7": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-21::obj-13": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-21::obj-14": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-21::obj-15": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-21::obj-22": {
                    "parameter_longname": "edge_falloff[2]"
                },
                "obj-21::obj-24": {
                    "parameter_invisible": 0,
                    "parameter_longname": "low_mid[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "low_mid",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-21::obj-25": {
                    "parameter_invisible": 0,
                    "parameter_longname": "mid_high[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "mid_high",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-23::obj-26": {
                    "parameter_longname": "freq[1]"
                },
                "obj-24::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-24::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-24::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-24::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_longname": "mix_amt",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-26::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_longname": "cx[2]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "cx",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-26::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_longname": "cy[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "cy",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-26::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-26::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-26::obj-32": {
                    "parameter_invisible": 0,
                    "parameter_longname": "falloff[3]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "falloff",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-26::obj-35": {
                    "parameter_invisible": 0,
                    "parameter_longname": "cx_amt[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "cx_amt",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-26::obj-38": {
                    "parameter_invisible": 0,
                    "parameter_longname": "cy_amt[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "cy_amt",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-26::obj-41": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-26::obj-44": {
                    "parameter_invisible": 0,
                    "parameter_longname": "curl_amt[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "curl_amt",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-27::obj-11": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-27::obj-13": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-27::obj-2": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-27::obj-25": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-27::obj-27": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-27::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_longname": "shape",
                    "parameter_modmode": 3,
                    "parameter_shortname": "shape",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-27::obj-31": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-27::obj-37": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-27::obj-40": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-27::obj-43": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-27::obj-60": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-27::obj-63": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-27::obj-82": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-28::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_longname": "strength",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-28::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-30::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_longname": "strength[3]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "strength",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-31::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_longname": "strength[2]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "strength",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-31::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_longname": "length",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-31::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_longname": "falloff[2]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "falloff",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-31::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_longname": "color_shift[3]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "color_shift",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-31::obj-32": {
                    "parameter_longname": "color_shift[2]"
                },
                "obj-4::obj-29": {
                    "parameter_range": [ 0.0, 1020.0 ]
                },
                "obj-4::obj-4": {
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-4::obj-6": {
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-5::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_range": [ -1.0, 1.0 ],
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-5::obj-23": {
                    "parameter_longname": "tilt",
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-5::obj-26": {
                    "parameter_longname": "slope",
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-5::obj-47": {
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-7::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_longname": "cx",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-8::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-8::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-8::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-8::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-8::obj-32": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-8::obj-35": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-8::obj-38": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-8::obj-41": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-8::obj-44": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-8::obj-47": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-8::obj-50": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-8::obj-53": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-8::obj-56": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-8::obj-59": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-8::obj-62": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-8::obj-65": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-8::obj-68": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-95::obj-102": {
                    "parameter_longname": "live.numbox[17]"
                },
                "obj-95::obj-105": {
                    "parameter_longname": "live.numbox[16]"
                },
                "obj-95::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_longname": "s1_cx[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "s1_cx",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-95::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_longname": "s1_cy[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "s1_cy",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-95::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_longname": "s1_conv[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "s1_conv",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-95::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_longname": "s1_curl[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "s1_curl",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-95::obj-32": {
                    "parameter_invisible": 0,
                    "parameter_longname": "s2_cx[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "s2_cx",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-95::obj-35": {
                    "parameter_invisible": 0,
                    "parameter_longname": "s2_cy[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "s2_cy",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-95::obj-38": {
                    "parameter_invisible": 0,
                    "parameter_longname": "s2_conv[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "s2_conv",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-95::obj-41": {
                    "parameter_invisible": 0,
                    "parameter_longname": "s2_curl[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "s2_curl",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-95::obj-44": {
                    "parameter_invisible": 0,
                    "parameter_longname": "s3_cx[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "s3_cx",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-95::obj-47": {
                    "parameter_invisible": 0,
                    "parameter_longname": "s3_cy[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "s3_cy",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-95::obj-50": {
                    "parameter_invisible": 0,
                    "parameter_longname": "s3_conv[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "s3_conv",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-95::obj-53": {
                    "parameter_invisible": 0,
                    "parameter_longname": "s3_curl[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "s3_curl",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-95::obj-56": {
                    "parameter_invisible": 0,
                    "parameter_longname": "falloff[4]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "falloff",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-95::obj-59": {
                    "parameter_invisible": 0,
                    "parameter_longname": "cx_amt[2]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "cx_amt",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-95::obj-62": {
                    "parameter_invisible": 0,
                    "parameter_longname": "cy_amt[2]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "cy_amt",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-95::obj-65": {
                    "parameter_invisible": 0,
                    "parameter_longname": "conv_amt[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "conv_amt",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-95::obj-68": {
                    "parameter_invisible": 0,
                    "parameter_longname": "curl_amt[2]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "curl_amt",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-95::obj-81": {
                    "parameter_longname": "live.numbox[15]"
                },
                "obj-95::obj-84": {
                    "parameter_longname": "live.numbox[18]"
                },
                "obj-9::obj-125": {
                    "parameter_longname": "panel_toggle[1]"
                },
                "obj-9::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-9::obj-21": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-9::obj-22": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-9::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-9::obj-24": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-9::obj-25": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-9::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-9::obj-27": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-9::obj-28": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-9::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-9::obj-30": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-9::obj-31": {
                    "parameter_invisible": 0,
                    "parameter_longname": "softness[1]",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-9::obj-32": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-9::obj-33": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-9::obj-35": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-9::obj-36": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-9::obj-90": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-9::obj-91": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                }
            },
            "inherited_shortname": 1
        },
        "autosave": 0
    }
}