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
        "rect": [ 34.0, 95.0, 1660.0, 922.0 ],
        "boxes": [
            {
                "box": {
                    "bgmode": 1,
                    "border": 1,
                    "clickthrough": 0,
                    "embed": 1,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-5",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_syphon_server.maxpat",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "offset": [ 0.0, 0.0 ],
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
                        "rect": [ 34.0, 100.0, 886.0, 811.0 ],
                        "openinpresentation": 1,
                        "gridonopen": 2,
                        "righttoolbarpinned": 2,
                        "bottomtoolbarpinned": 2,
                        "toolbars_unpinned_last_save": 12,
                        "style": "minimal",
                        "subpatcher_template": "kk_sp_empty",
                        "boxes": [
                            {
                                "box": {
                                    "fontface": 0,
                                    "id": "obj-22",
                                    "maxclass": "newobj",
                                    "numinlets": 1,
                                    "numoutlets": 1,
                                    "outlettype": [ "" ],
                                    "patching_rect": [ 141.6000016927719, 497.0, 57.0, 22.0 ],
                                    "text": "tosymbol"
                                }
                            },
                            {
                                "box": {
                                    "id": "obj-25",
                                    "maxclass": "button",
                                    "numinlets": 1,
                                    "numoutlets": 1,
                                    "outlettype": [ "bang" ],
                                    "parameter_enable": 0,
                                    "patching_rect": [ 336.0, 497.0, 24.0, 24.0 ]
                                }
                            },
                            {
                                "box": {
                                    "id": "obj-19",
                                    "maxclass": "newobj",
                                    "numinlets": 1,
                                    "numoutlets": 0,
                                    "patching_rect": [ 336.0, 534.4000076055527, 112.0, 22.0 ],
                                    "text": "s vs_serverRefresh"
                                }
                            },
                            {
                                "box": {
                                    "id": "obj-3",
                                    "maxclass": "newobj",
                                    "numinlets": 1,
                                    "numoutlets": 4,
                                    "outlettype": [ "", "", "", "" ],
                                    "patching_rect": [ 38.0, 62.0, 56.0, 22.0 ],
                                    "text": "autopattr",
                                    "varname": "u055011202"
                                }
                            },
                            {
                                "box": {
                                    "id": "obj-23",
                                    "linecount": 3,
                                    "maxclass": "comment",
                                    "numinlets": 1,
                                    "numoutlets": 0,
                                    "patching_rect": [ 706.0, 150.0, 150.0, 47.0 ],
                                    "text": "< Embedded patcher to override server name with user input."
                                }
                            },
                            {
                                "box": {
                                    "id": "obj-20",
                                    "linecount": 2,
                                    "maxclass": "comment",
                                    "numinlets": 1,
                                    "numoutlets": 0,
                                    "patching_rect": [ 180.0, 124.00000184774399, 150.0, 33.0 ],
                                    "text": "< it has to init as vsynth to do the incremental with #0"
                                }
                            },
                            {
                                "box": {
                                    "fontface": 0,
                                    "id": "obj-21",
                                    "maxclass": "newobj",
                                    "numinlets": 1,
                                    "numoutlets": 1,
                                    "outlettype": [ "" ],
                                    "patching_rect": [ 256.8000038266182, 534.4000076055527, 72.0, 22.0 ],
                                    "text": "prepend set"
                                }
                            },
                            {
                                "box": {
                                    "fontface": 0,
                                    "id": "obj-8",
                                    "maxclass": "newobj",
                                    "numinlets": 2,
                                    "numoutlets": 2,
                                    "outlettype": [ "", "" ],
                                    "patching_rect": [ 256.8000038266182, 453.6000067591667, 59.0, 22.0 ],
                                    "text": "route text"
                                }
                            },
                            {
                                "box": {
                                    "fontface": 0,
                                    "id": "obj-13",
                                    "maxclass": "newobj",
                                    "numinlets": 1,
                                    "numoutlets": 1,
                                    "outlettype": [ "" ],
                                    "patching_rect": [ 174.4000025987625, 337.600005030632, 72.0, 22.0 ],
                                    "text": "prepend set"
                                }
                            },
                            {
                                "box": {
                                    "autoscroll": 0,
                                    "bgcolor": [ 0.352941176470588, 0.831372549019608, 0.784313725490196, 0.0 ],
                                    "border": 1.0,
                                    "bordercolor": [ 0.32549, 0.345098, 0.372549, 0.0 ],
                                    "fontface": 3,
                                    "fontsize": 10.0,
                                    "id": "obj-10",
                                    "keymode": 1,
                                    "maxclass": "textedit",
                                    "numinlets": 1,
                                    "numoutlets": 4,
                                    "outlettype": [ "", "int", "", "" ],
                                    "parameter_enable": 1,
                                    "parameter_mappable": 0,
                                    "patching_rect": [ 256.8000038266182, 412.80000615119934, 69.0, 22.0 ],
                                    "presentation": 1,
                                    "presentation_rect": [ 96.0, 1.0, 70.25, 18.0 ],
                                    "rounded": 0.0,
                                    "saved_attribute_attributes": {
                                        "valueof": {
                                            "parameter_invisible": 1,
                                            "parameter_longname": "textedit[2]",
                                            "parameter_modmode": 0,
                                            "parameter_shortname": "textedit[1]",
                                            "parameter_type": 3
                                        }
                                    },
                                    "tabmode": 0,
                                    "text": "5080_vsynth",
                                    "valuemode": 1,
                                    "varname": "textedit[1]",
                                    "wordwrap": 0
                                }
                            },
                            {
                                "box": {
                                    "fontface": 0,
                                    "id": "obj-6",
                                    "maxclass": "message",
                                    "numinlets": 2,
                                    "numoutlets": 1,
                                    "outlettype": [ "" ],
                                    "patching_rect": [ 113.60000169277191, 276.0000041127205, 77.0, 22.0 ],
                                    "text": "#0_vsynth"
                                }
                            },
                            {
                                "box": {
                                    "fontface": 0,
                                    "id": "obj-5",
                                    "maxclass": "newobj",
                                    "numinlets": 3,
                                    "numoutlets": 3,
                                    "outlettype": [ "bang", "bang", "" ],
                                    "patching_rect": [ 113.60000169277191, 230.40000343322754, 305.0, 22.0 ],
                                    "text": "sel 1 0"
                                }
                            },
                            {
                                "box": {
                                    "fontface": 0,
                                    "id": "obj-9",
                                    "maxclass": "newobj",
                                    "numinlets": 2,
                                    "numoutlets": 2,
                                    "outlettype": [ "", "" ],
                                    "patching_rect": [ 113.60000169277191, 154.4000023007393, 59.0, 22.0 ],
                                    "text": "route text"
                                }
                            },
                            {
                                "box": {
                                    "autoscroll": 0,
                                    "bgcolor": [ 0.352941176470588, 0.831372549019608, 0.784313725490196, 1.0 ],
                                    "border": 1.0,
                                    "fontface": 3,
                                    "fontsize": 10.0,
                                    "id": "obj-2",
                                    "keymode": 1,
                                    "maxclass": "textedit",
                                    "numinlets": 1,
                                    "numoutlets": 4,
                                    "outlettype": [ "", "int", "", "" ],
                                    "parameter_enable": 1,
                                    "parameter_mappable": 0,
                                    "patching_rect": [ 113.60000169277191, 124.00000184774399, 60.0, 20.0 ],
                                    "rounded": 0.0,
                                    "saved_attribute_attributes": {
                                        "valueof": {
                                            "parameter_invisible": 1,
                                            "parameter_longname": "textedit[1]",
                                            "parameter_modmode": 0,
                                            "parameter_shortname": "textedit",
                                            "parameter_type": 3
                                        }
                                    },
                                    "tabmode": 0,
                                    "text": "vsynth",
                                    "valuemode": 1,
                                    "varname": "textedit",
                                    "wordwrap": 0
                                }
                            },
                            {
                                "box": {
                                    "fontface": 0,
                                    "fontname": "Arial",
                                    "fontsize": 13.0,
                                    "id": "obj-178",
                                    "maxclass": "newobj",
                                    "numinlets": 2,
                                    "numoutlets": 2,
                                    "outlettype": [ "", "" ],
                                    "patching_rect": [ 113.60000169277191, 191.20000284910202, 113.0, 23.0 ],
                                    "text": "zl.compare vsynth"
                                }
                            },
                            {
                                "box": {
                                    "fontface": 0,
                                    "id": "obj-16",
                                    "maxclass": "newobj",
                                    "numinlets": 1,
                                    "numoutlets": 1,
                                    "outlettype": [ "" ],
                                    "patching_rect": [ 113.60000169277191, 534.4000076055527, 119.0, 22.0 ],
                                    "text": "prepend servername"
                                }
                            },
                            {
                                "box": {
                                    "fontface": 0,
                                    "id": "obj-11",
                                    "maxclass": "newobj",
                                    "numinlets": 2,
                                    "numoutlets": 1,
                                    "outlettype": [ "" ],
                                    "patching_rect": [ 84.00000125169754, 595.2000088691711, 105.0, 22.0 ],
                                    "text": "jit.gl.syphonserver"
                                }
                            },
                            {
                                "box": {
                                    "comment": "Texture In",
                                    "id": "obj-18",
                                    "index": 1,
                                    "maxclass": "inlet",
                                    "numinlets": 0,
                                    "numoutlets": 1,
                                    "outlettype": [ "jit_gl_texture" ],
                                    "patching_rect": [ 45.60000067949295, 516.0000076889992, 30.0, 30.0 ]
                                }
                            },
                            {
                                "box": {
                                    "fontface": 0,
                                    "id": "obj-4",
                                    "maxclass": "newobj",
                                    "numinlets": 1,
                                    "numoutlets": 1,
                                    "outlettype": [ "emb" ],
                                    "patching_rect": [ 663.0, 150.0, 39.0, 22.0 ],
                                    "text": "t emb"
                                }
                            },
                            {
                                "box": {
                                    "bgcolor": [ 0.352941176470588, 0.831372549019608, 0.784313725490196, 1.0 ],
                                    "border": 1.0,
                                    "fontface": 3,
                                    "fontsize": 10.0,
                                    "id": "obj-7",
                                    "maxclass": "textedit",
                                    "numinlets": 1,
                                    "numoutlets": 4,
                                    "outlettype": [ "", "int", "", "" ],
                                    "parameter_enable": 0,
                                    "parameter_mappable": 0,
                                    "patching_rect": [ 11.200000166893005, 18.400000274181366, 145.60000216960907, 17.600000262260437 ],
                                    "presentation": 1,
                                    "presentation_rect": [ 0.0, 1.0, 168.0, 18.0 ],
                                    "readonly": 1,
                                    "rounded": 0.0,
                                    "text": "SYPHON SERVER :",
                                    "valuemode": 1
                                }
                            },
                            {
                                "box": {
                                    "angle": 270.0,
                                    "bgcolor": [ 0.65098, 0.65098, 0.65098, 0.43 ],
                                    "border": 1,
                                    "id": "obj-14",
                                    "maxclass": "panel",
                                    "mode": 0,
                                    "numinlets": 1,
                                    "numoutlets": 0,
                                    "patching_rect": [ 550.0, 110.0, 97.0, 25.0 ],
                                    "presentation": 1,
                                    "presentation_rect": [ 0.0, 21.0, 165.0, 17.0 ],
                                    "proportion": 0.5,
                                    "rounded": 0
                                }
                            },
                            {
                                "box": {
                                    "fontface": 0,
                                    "id": "obj-17",
                                    "maxclass": "newobj",
                                    "numinlets": 1,
                                    "numoutlets": 1,
                                    "outlettype": [ "" ],
                                    "patching_rect": [ 499.0, 150.0, 76.0, 22.0 ],
                                    "text": "prepend tam"
                                }
                            },
                            {
                                "box": {
                                    "fontface": 0,
                                    "id": "obj-34",
                                    "maxclass": "newobj",
                                    "numinlets": 2,
                                    "numoutlets": 2,
                                    "outlettype": [ "", "" ],
                                    "patching_rect": [ 463.0, 110.0, 55.0, 22.0 ],
                                    "text": "zl slice 2"
                                }
                            },
                            {
                                "box": {
                                    "fontface": 0,
                                    "id": "obj-15",
                                    "maxclass": "newobj",
                                    "numinlets": 1,
                                    "numoutlets": 3,
                                    "outlettype": [ "", "", "" ],
                                    "patching_rect": [ 463.0, 78.0, 192.0, 22.0 ],
                                    "text": "getattr presentation_rect @listen 0"
                                }
                            },
                            {
                                "box": {
                                    "fontface": 0,
                                    "id": "obj-12",
                                    "maxclass": "newobj",
                                    "numinlets": 1,
                                    "numoutlets": 1,
                                    "outlettype": [ "" ],
                                    "patching_rect": [ 499.0, 192.0, 95.0, 22.0 ],
                                    "saved_object_attributes": {
                                        "filename": "moduleSize.js",
                                        "parameter_enable": 0
                                    },
                                    "text": "js moduleSize.js"
                                }
                            },
                            {
                                "box": {
                                    "fontface": 0,
                                    "id": "obj-1",
                                    "maxclass": "newobj",
                                    "numinlets": 1,
                                    "numoutlets": 1,
                                    "outlettype": [ "bang" ],
                                    "patching_rect": [ 463.0, 23.0, 58.0, 22.0 ],
                                    "text": "loadbang"
                                }
                            }
                        ],
                        "lines": [
                            {
                                "patchline": {
                                    "destination": [ "obj-15", 0 ],
                                    "order": 1,
                                    "source": [ "obj-1", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "obj-2", 0 ],
                                    "order": 2,
                                    "source": [ "obj-1", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "obj-4", 0 ],
                                    "midpoints": [ 472.5, 63.0, 672.5, 63.0 ],
                                    "order": 0,
                                    "source": [ "obj-1", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "obj-8", 0 ],
                                    "source": [ "obj-10", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "obj-10", 0 ],
                                    "source": [ "obj-13", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "obj-14", 0 ],
                                    "source": [ "obj-15", 1 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "obj-34", 0 ],
                                    "source": [ "obj-15", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "obj-11", 0 ],
                                    "source": [ "obj-16", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "obj-12", 0 ],
                                    "source": [ "obj-17", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "obj-5", 0 ],
                                    "source": [ "obj-178", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "obj-11", 0 ],
                                    "source": [ "obj-18", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "obj-9", 0 ],
                                    "source": [ "obj-2", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "obj-2", 0 ],
                                    "midpoints": [ 266.3000038266182, 576.9999997019768, 100.20000123977661, 576.9999997019768, 100.20000123977661, 120.19999933242798, 123.10000169277191, 120.19999933242798 ],
                                    "source": [ "obj-21", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "obj-16", 0 ],
                                    "source": [ "obj-22", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "obj-19", 0 ],
                                    "source": [ "obj-25", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "obj-10", 0 ],
                                    "midpoints": [ 59.833333333333336, 399.0, 266.3000038266182, 399.0 ],
                                    "order": 0,
                                    "source": [ "obj-3", 1 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "obj-2", 0 ],
                                    "midpoints": [ 59.833333333333336, 111.0, 123.10000169277191, 111.0 ],
                                    "order": 1,
                                    "source": [ "obj-3", 1 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "obj-17", 0 ],
                                    "source": [ "obj-34", 1 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "obj-12", 0 ],
                                    "midpoints": [ 672.5, 183.0, 508.5, 183.0 ],
                                    "source": [ "obj-4", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "obj-10", 0 ],
                                    "source": [ "obj-5", 1 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "obj-6", 0 ],
                                    "source": [ "obj-5", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "obj-13", 0 ],
                                    "order": 0,
                                    "source": [ "obj-6", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "obj-16", 0 ],
                                    "order": 1,
                                    "source": [ "obj-6", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "obj-21", 0 ],
                                    "order": 1,
                                    "source": [ "obj-8", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "obj-22", 0 ],
                                    "order": 2,
                                    "source": [ "obj-8", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "obj-25", 0 ],
                                    "order": 0,
                                    "source": [ "obj-8", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "obj-178", 0 ],
                                    "source": [ "obj-9", 0 ]
                                }
                            }
                        ],
                        "styles": [
                            {
                                "name": "minimal",
                                "default": {
                                    "accentcolor": [ 0.32549, 0.345098, 0.372549, 1.0 ],
                                    "bgcolor": [ 0.878431, 0.878431, 0.858824, 1.0 ],
                                    "bgfillcolor": {
                                        "angle": 270.0,
                                        "autogradient": 0,
                                        "color": [ 0.65098, 0.65098, 0.65098, 1.0 ],
                                        "color1": [ 0.878431, 0.878431, 0.858824, 1.0 ],
                                        "color2": [ 0.290196, 0.309804, 0.301961, 1.0 ],
                                        "proportion": 0.99,
                                        "type": "color"
                                    },
                                    "color": [ 0.345098, 0.513725, 0.572549, 0.78 ],
                                    "elementcolor": [ 0.32549, 0.345098, 0.372549, 0.44 ],
                                    "patchlinecolor": [ 0.65, 0.65, 0.65, 0.9 ],
                                    "selectioncolor": [ 0.862745, 0.741176, 0.137255, 0.7 ],
                                    "textcolor_inverse": [ 0.0, 0.0, 0.0, 1.0 ]
                                },
                                "parentstyle": "",
                                "multi": 0
                            }
                        ],
                        "toolbaradditions": [ "browsegenjit", "browsegendsp" ],
                        "toolbarexclusions": [ "browsecollections", "browser_plugin", "packagemanager", "calendar", "other", "number", "toggle", "comment" ],
                        "default_bgcolor": [ 0.878431, 0.878431, 0.858824, 1.0 ],
                        "color": [ 0.345098, 0.513725, 0.572549, 0.78 ],
                        "elementcolor": [ 0.32549, 0.345098, 0.372549, 0.44 ],
                        "accentcolor": [ 0.32549, 0.345098, 0.372549, 1.0 ],
                        "selectioncolor": [ 0.862745, 0.741176, 0.137255, 0.7 ],
                        "textcolor_inverse": [ 0.0, 0.0, 0.0, 1.0 ],
                        "bgfillcolor_type": "color",
                        "bgfillcolor_color1": [ 0.878431, 0.878431, 0.858824, 1.0 ],
                        "bgfillcolor_color2": [ 0.290196, 0.309804, 0.301961, 1.0 ],
                        "bgfillcolor_color": [ 0.65098, 0.65098, 0.65098, 1.0 ]
                    },
                    "patching_rect": [ 425.0, 870.0, 165.0, 17.0 ],
                    "varname": "vs_syphon_server",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "id": "obj-28",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 1102.0, 545.0, 35.0, 22.0 ],
                    "text": "ease"
                }
            },
            {
                "box": {
                    "id": "obj-26",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 1028.0, 680.0, 58.0, 22.0 ],
                    "text": "phase $1"
                }
            },
            {
                "box": {
                    "id": "obj-22",
                    "maxclass": "newobj",
                    "numinlets": 6,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 1047.0, 623.0, 107.0, 22.0 ],
                    "text": "scale 1. 127. -1. 1."
                }
            },
            {
                "box": {
                    "format": 6,
                    "id": "obj-21",
                    "maxclass": "flonum",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "bang" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 1187.0, 643.0, 50.0, 22.0 ]
                }
            },
            {
                "box": {
                    "id": "obj-19",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "float" ],
                    "patching_rect": [ 1133.0, 463.0, 94.0, 22.0 ],
                    "text": "sigmund~ notes"
                }
            },
            {
                "box": {
                    "id": "obj-18",
                    "maxclass": "gain~",
                    "multichannelvariant": 0,
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "signal", "" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 1144.5, 282.0, 22.0, 140.0 ]
                }
            },
            {
                "box": {
                    "id": "obj-13",
                    "maxclass": "ezadc~",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "signal", "signal" ],
                    "patching_rect": [ 1133.0, 189.0, 45.0, 45.0 ]
                }
            },
            {
                "box": {
                    "appearance": 3,
                    "id": "obj-38",
                    "maxclass": "live.numbox",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "parameter_enable": 1,
                    "patching_rect": [ 413.0, 905.0, 108.0, 15.0 ],
                    "saved_attribute_attributes": {
                        "valueof": {
                            "parameter_longname": "live.numbox[5]",
                            "parameter_mmax": 100.0,
                            "parameter_mmin": -100.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "live.numbox[5]",
                            "parameter_type": 0,
                            "parameter_unitstyle": 5
                        }
                    },
                    "varname": "live.numbox"
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
                    "name": "f_vf_prism.maxpat",
                    "numinlets": 4,
                    "numoutlets": 3,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 188.0, 760.0, 190.0, 160.0 ],
                    "varname": "f_vf_prism[1]",
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
                    "id": "obj-16",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_stipple.maxpat",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 503.0, 193.0, 191.0, 157.0 ],
                    "varname": "f_stipple",
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
                    "id": "obj-10",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vsc_presets.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "" ],
                    "patching_rect": [ 680.0, 463.0, 174.0, 393.0 ],
                    "varname": "vs_presets",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "autorestore": "advect.json",
                    "hidden": 1,
                    "id": "obj-11",
                    "linecount": 2,
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 680.0, 655.0, 138.0, 35.0 ],
                    "priority": {
                        "vs_wfg_polarizer[1]::pm_range": -1,
                        "vs_wfg_polarizer[1]::lock_freq": -1,
                        "vs_wfg_polarizer[2]::pm_range": -1,
                        "vs_wfg_polarizer[2]::lock_freq": -1
                    },
                    "saved_object_attributes": {
                        "client_rect": [ 854, 172, 1208, 300 ],
                        "parameter_enable": 0,
                        "parameter_mappable": 0,
                        "storage_rect": [ 766, 44, 1220, 302 ]
                    },
                    "text": "pattrstorage @greedy 1 @changemode 1",
                    "varname": "Vsynth"
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
                    "name": "f_vf_prism.maxpat",
                    "numinlets": 4,
                    "numoutlets": 3,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 180.5, 378.0, 190.0, 160.0 ],
                    "varname": "f_vf_prism",
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
                    "id": "obj-15",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_wfg_polarizer.maxpat",
                    "numinlets": 2,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 746.0, 55.0, 220.0, 132.0 ],
                    "varname": "vs_wfg_polarizer[2]",
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
                    "name": "f_vf_fieldmap.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 444.0, 354.0, 153.0, 93.0 ],
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
                    "id": "obj-8",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_grain.maxpat",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 480.0, 5.0, 227.0, 164.0 ],
                    "varname": "f_grain",
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
                    "id": "obj-7",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_lens.maxpat",
                    "numinlets": 5,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 188.0, 183.5, 175.0, 155.0 ],
                    "varname": "f_lens",
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
                    "name": "vs_preview.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 512.5, 669.0, 162.0, 178.0 ],
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
                    "id": "obj-29",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_preview.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 546.0, 509.0, 112.0, 102.02620087336243 ],
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
                    "id": "obj-25",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_wfg_polarizer.maxpat",
                    "numinlets": 2,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 214.0, 2.0, 220.0, 132.0 ],
                    "varname": "vs_wfg_polarizer[1]",
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
                    "id": "obj-24",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_vf_advect.maxpat",
                    "numinlets": 2,
                    "numoutlets": 3,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 188.0, 556.0, 191.0, 146.0 ],
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
                    "id": "obj-6",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_modules.maxpat",
                    "numinlets": 0,
                    "numoutlets": 0,
                    "offset": [ 0.0, 0.0 ],
                    "patching_rect": [ 25.0, 339.0, 100.0, 375.0 ],
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
                    "id": "obj-4",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_output.maxpat",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "offset": [ 0.0, 0.0 ],
                    "patching_rect": [ 955.0, 901.5, 157.0, 22.0 ],
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
                    "id": "obj-3",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_render.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "" ],
                    "patching_rect": [ 110.0, 14.0, 96.85526317358028, 146.5 ],
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
                    "patching_rect": [ 25.0, 14.0, 79.0, 316.0 ],
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "attr": "function",
                    "id": "obj-30",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 1219.0, 527.0, 273.0, 22.0 ]
                }
            }
        ],
        "lines": [
            {
                "patchline": {
                    "color": [ 0.65, 0.65, 0.65, 0.0 ],
                    "destination": [ "obj-11", 0 ],
                    "hidden": 1,
                    "source": [ "obj-10", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-18", 0 ],
                    "source": [ "obj-13", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-18", 0 ],
                    "source": [ "obj-13", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-17", 1 ],
                    "order": 2,
                    "source": [ "obj-14", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-24", 1 ],
                    "order": 0,
                    "source": [ "obj-14", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-29", 0 ],
                    "order": 3,
                    "source": [ "obj-14", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-9", 1 ],
                    "order": 1,
                    "source": [ "obj-14", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-16", 0 ],
                    "order": 1,
                    "source": [ "obj-15", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-8", 0 ],
                    "order": 0,
                    "source": [ "obj-15", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-7", 4 ],
                    "source": [ "obj-16", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-4", 0 ],
                    "order": 1,
                    "source": [ "obj-17", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 0 ],
                    "order": 0,
                    "source": [ "obj-17", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-19", 0 ],
                    "source": [ "obj-18", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-28", 0 ],
                    "source": [ "obj-19", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-21", 0 ],
                    "order": 0,
                    "source": [ "obj-22", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-26", 0 ],
                    "order": 1,
                    "source": [ "obj-22", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-17", 0 ],
                    "source": [ "obj-24", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-2", 0 ],
                    "source": [ "obj-24", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-7", 0 ],
                    "order": 1,
                    "source": [ "obj-25", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-9", 2 ],
                    "order": 0,
                    "source": [ "obj-25", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-25", 0 ],
                    "source": [ "obj-26", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-22", 0 ],
                    "source": [ "obj-28", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-28", 0 ],
                    "source": [ "obj-30", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-9", 0 ],
                    "source": [ "obj-7", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-14", 0 ],
                    "source": [ "obj-8", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-24", 0 ],
                    "source": [ "obj-9", 1 ]
                }
            }
        ],
        "parameters": {
            "obj-10::obj-10": [ "textedit", "vs_preset_name", 0 ],
            "obj-10::obj-11": [ "live.text", "live.text", 0 ],
            "obj-10::obj-15": [ "live.tab", "live.tab", 0 ],
            "obj-10::obj-32": [ "live.numbox[4]", "live.numbox", 0 ],
            "obj-10::obj-44": [ "live.tab[3]", "live.tab", 0 ],
            "obj-10::obj-45::obj-16": [ "live.menu[20]", "live.menu[16]", 0 ],
            "obj-10::obj-45::obj-17": [ "live.button", "live.button", 0 ],
            "obj-10::obj-45::obj-19": [ "live.numbox[2]", "live.numbox[1]", 0 ],
            "obj-10::obj-45::obj-32": [ "live.numbox", "live.numbox", 0 ],
            "obj-10::obj-45::obj-9": [ "live.numbox[3]", "live.numbox", 0 ],
            "obj-14::obj-20": [ "gain", "gain", 0 ],
            "obj-14::obj-23": [ "scale", "scale", 0 ],
            "obj-14::obj-28": [ "rotate", "rotate", 0 ],
            "obj-14::obj-31": [ "thresh", "thresh", 0 ],
            "obj-15::obj-10": [ "bias", "Bias", 0 ],
            "obj-15::obj-14": [ "bm", "BM", 0 ],
            "obj-15::obj-17": [ "live.menu[41]", "live.menu", 0 ],
            "obj-15::obj-22": [ "live.text[3]", "live.text", 0 ],
            "obj-15::obj-29": [ "freq", "Freq", 0 ],
            "obj-15::obj-30": [ "angle[2]", "Angle", 0 ],
            "obj-15::obj-42": [ "live.toggle[2]", "live.toggle", 0 ],
            "obj-15::obj-47": [ "polarizer", "Morph", 0 ],
            "obj-15::obj-51": [ "live.menu[40]", "live.menu", 0 ],
            "obj-15::obj-53": [ "speed", "Speed", 0 ],
            "obj-15::obj-54": [ "morph", "Morph", 0 ],
            "obj-15::obj-6": [ "pm", "PM", 0 ],
            "obj-15::obj-65": [ "shape[2]", "Shape", 0 ],
            "obj-15::obj-71": [ "phase", "Phase", 0 ],
            "obj-15::obj-72": [ "phase_time_switch", "phase_time_switch", 0 ],
            "obj-16::obj-20": [ "freq[3]", "freq", 0 ],
            "obj-16::obj-23": [ "coarseness", "coarseness", 0 ],
            "obj-16::obj-26": [ "anisotropy", "anisotropy", 0 ],
            "obj-16::obj-29": [ "angle[4]", "angle", 0 ],
            "obj-16::obj-32": [ "zoom", "zoom", 0 ],
            "obj-16::obj-35": [ "threshold[1]", "threshold", 0 ],
            "obj-16::obj-38": [ "colorize", "colorize", 0 ],
            "obj-16::obj-41": [ "along_phase", "along_phase", 0 ],
            "obj-16::obj-44": [ "across_phase", "across_phase", 0 ],
            "obj-16::obj-47": [ "softness[1]", "softness", 0 ],
            "obj-17::obj-20": [ "reach[1]", "reach", 0 ],
            "obj-17::obj-23": [ "spread[1]", "spread", 0 ],
            "obj-17::obj-26": [ "threshold[2]", "threshold", 0 ],
            "obj-17::obj-29": [ "threshold_width[1]", "threshold_width", 0 ],
            "obj-17::obj-32": [ "feather[1]", "feather", 0 ],
            "obj-17::obj-35": [ "strength[1]", "strength", 0 ],
            "obj-17::obj-38": [ "mix_pct[2]", "mix_pct", 0 ],
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
            "obj-24::obj-20": [ "dt", "dt", 0 ],
            "obj-24::obj-23": [ "decay", "decay", 0 ],
            "obj-24::obj-26": [ "injection", "injection", 0 ],
            "obj-24::obj-29": [ "gain[2]", "gain", 0 ],
            "obj-24::obj-32": [ "separate", "separate", 0 ],
            "obj-24::obj-35": [ "mode", "mode", 0 ],
            "obj-24::obj-90": [ "mix_pct", "mix_pct", 0 ],
            "obj-25::obj-10": [ "bias[1]", "Bias", 0 ],
            "obj-25::obj-14": [ "bm[1]", "BM", 0 ],
            "obj-25::obj-17": [ "live.menu[18]", "live.menu", 0 ],
            "obj-25::obj-22": [ "live.text[12]", "live.text", 0 ],
            "obj-25::obj-29": [ "freq[1]", "Freq", 0 ],
            "obj-25::obj-30": [ "angle", "Angle", 0 ],
            "obj-25::obj-42": [ "live.toggle[3]", "live.toggle", 0 ],
            "obj-25::obj-47": [ "polarizer[1]", "Morph", 0 ],
            "obj-25::obj-51": [ "live.menu[19]", "live.menu", 0 ],
            "obj-25::obj-53": [ "speed[1]", "Speed", 0 ],
            "obj-25::obj-54": [ "morph[1]", "Morph", 0 ],
            "obj-25::obj-6": [ "pm[1]", "PM", 0 ],
            "obj-25::obj-65": [ "shape[1]", "Shape", 0 ],
            "obj-25::obj-71": [ "phase[1]", "Phase", 0 ],
            "obj-25::obj-72": [ "phase_time_switch[1]", "phase_time_switch", 0 ],
            "obj-38": [ "live.numbox[5]", "live.numbox[5]", 0 ],
            "obj-3::obj-19": [ "dim_x[2]", "dim_x", 0 ],
            "obj-3::obj-23": [ "pwm[1]", "pwm", 0 ],
            "obj-3::obj-36": [ "live.text[11]", "live.text", 0 ],
            "obj-3::obj-40": [ "live.text[6]", "live.text", 0 ],
            "obj-3::obj-41": [ "dim_y[2]", "dim_y", 0 ],
            "obj-3::obj-42": [ "dim_x[3]", "dim_x", 0 ],
            "obj-3::obj-45": [ "live.text[10]", "live.text", 0 ],
            "obj-3::obj-48": [ "live.text[7]", "live.text", 0 ],
            "obj-3::obj-5": [ "live.text[9]", "live.text", 0 ],
            "obj-3::obj-6": [ "live.text[8]", "live.text", 0 ],
            "obj-4::obj-1": [ "toggle[1]", "toggle[1]", 0 ],
            "obj-4::obj-10": [ "toggle[3]", "toggle[2]", 0 ],
            "obj-4::obj-36": [ "uppr_x", "uppr_x", 0 ],
            "obj-5::obj-10": [ "textedit[2]", "textedit[1]", 0 ],
            "obj-5::obj-2": [ "textedit[1]", "textedit", 0 ],
            "obj-6::obj-12": [ "f_module_1_disp", "live.menu", 0 ],
            "obj-6::obj-13": [ "f_module_1_file", "live.menu", 0 ],
            "obj-6::obj-16": [ "f_module_2_disp", "live.menu", 0 ],
            "obj-6::obj-17": [ "f_module_2_file", "live.menu", 0 ],
            "obj-6::obj-20": [ "f_module_3_disp", "live.menu", 0 ],
            "obj-6::obj-21": [ "f_module_3_file", "live.menu", 0 ],
            "obj-6::obj-24": [ "f_module_4_disp", "live.menu", 0 ],
            "obj-6::obj-25": [ "f_module_4_file", "live.menu", 0 ],
            "obj-6::obj-28": [ "f_module_5_disp", "live.menu", 0 ],
            "obj-6::obj-29": [ "f_module_5_file", "live.menu", 0 ],
            "obj-6::obj-32": [ "f_module_6_disp", "live.menu", 0 ],
            "obj-6::obj-33": [ "f_module_6_file", "live.menu", 0 ],
            "obj-6::obj-36": [ "f_module_7_disp", "live.menu", 0 ],
            "obj-6::obj-37": [ "f_module_7_file", "live.menu", 0 ],
            "obj-6::obj-8": [ "f_module_0_disp", "live.menu", 0 ],
            "obj-6::obj-9": [ "f_module_0_file", "live.menu", 0 ],
            "obj-7::obj-19d": [ "panel_toggle", "panel_toggle", 0 ],
            "obj-7::obj-20": [ "aberration", "aberration", 0 ],
            "obj-7::obj-23": [ "tilt", "distortion", 0 ],
            "obj-7::obj-26": [ "slope", "transmission", 0 ],
            "obj-7::obj-29": [ "aberration_mod", "aberration_mod", 0 ],
            "obj-7::obj-300": [ "range_aberration", "range_aberration", 0 ],
            "obj-7::obj-310": [ "range_distortion", "range_distortion", 0 ],
            "obj-7::obj-32": [ "distortion_mod", "distortion_mod", 0 ],
            "obj-7::obj-320": [ "range_transmission", "range_transmission", 0 ],
            "obj-7::obj-35": [ "transmission_mod", "transmission_mod", 0 ],
            "obj-7::obj-38": [ "surface_mod", "surface_mod", 0 ],
            "obj-7::obj-390": [ "range_ghost_spacing", "range_ghost_spacing", 0 ],
            "obj-7::obj-41": [ "ghost", "ghost", 0 ],
            "obj-7::obj-44": [ "ghost_count", "ghost_count", 0 ],
            "obj-7::obj-47": [ "ghost_spacing", "ghost_spacing", 0 ],
            "obj-7::obj-50": [ "halation", "halation", 0 ],
            "obj-7::obj-53": [ "halation_threshold", "halation_threshold", 0 ],
            "obj-8::obj-11": [ "density", "density", 0 ],
            "obj-8::obj-13": [ "amount", "amount", 0 ],
            "obj-8::obj-15": [ "persistence", "persistence", 0 ],
            "obj-8::obj-2": [ "fade", "fade", 0 ],
            "obj-8::obj-25": [ "size", "size", 0 ],
            "obj-8::obj-27": [ "size_var", "size_var", 0 ],
            "obj-8::obj-29": [ "shape", "shape", 0 ],
            "obj-8::obj-31": [ "softness", "softness", 0 ],
            "obj-8::obj-37": [ "jitter", "jitter", 0 ],
            "obj-8::obj-40": [ "ch_diverge", "ch_diverge", 0 ],
            "obj-8::obj-43": [ "field", "field", 0 ],
            "obj-8::obj-60": [ "luma_gate", "luma_gate", 0 ],
            "obj-8::obj-63": [ "displace", "displace", 0 ],
            "obj-8::obj-71": [ "edge_mode_menu", "edge_mode_menu", 0 ],
            "obj-8::obj-82": [ "sv_seed", "sv_seed", 0 ],
            "obj-9::obj-20": [ "reach", "reach", 0 ],
            "obj-9::obj-23": [ "spread", "spread", 0 ],
            "obj-9::obj-26": [ "threshold", "threshold", 0 ],
            "obj-9::obj-29": [ "threshold_width", "threshold_width", 0 ],
            "obj-9::obj-32": [ "feather", "feather", 0 ],
            "obj-9::obj-35": [ "strength", "gain", 0 ],
            "obj-9::obj-38": [ "mix_pct[1]", "mix_pct", 0 ],
            "parameterbanks": {
                "0": {
                    "index": 0,
                    "name": "",
                    "parameters": [ "-", "-", "-", "-", "-", "-", "-", "-" ],
                    "buttons": [ "-", "-", "-", "-", "-", "-", "-", "-" ]
                }
            },
            "parameter_overrides": {
                "obj-10::obj-32": {
                    "parameter_longname": "live.numbox[4]"
                },
                "obj-10::obj-45::obj-16": {
                    "parameter_longname": "live.menu[20]"
                },
                "obj-14::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-14::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-14::obj-28": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-14::obj-31": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-15::obj-30": {
                    "parameter_longname": "angle[2]"
                },
                "obj-15::obj-6": {
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-15::obj-65": {
                    "parameter_longname": "shape[2]"
                },
                "obj-16::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_longname": "freq[3]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "freq",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-16::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-16::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-16::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_longname": "angle[4]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "angle",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-16::obj-32": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-16::obj-35": {
                    "parameter_invisible": 0,
                    "parameter_longname": "threshold[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "threshold",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-16::obj-38": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-16::obj-41": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-16::obj-44": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-16::obj-47": {
                    "parameter_invisible": 0,
                    "parameter_longname": "softness[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "softness",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-17::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_longname": "reach[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "reach",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-17::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_longname": "spread[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "spread",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-17::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_longname": "threshold[2]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "threshold",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-17::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_longname": "threshold_width[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "threshold_width",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-17::obj-32": {
                    "parameter_invisible": 0,
                    "parameter_longname": "feather[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "feather",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-17::obj-35": {
                    "parameter_invisible": 0,
                    "parameter_longname": "strength[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "strength",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-17::obj-38": {
                    "parameter_longname": "mix_pct[2]"
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
                "obj-24::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_range": [ 0.0, 0.05 ],
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
                    "parameter_range": [ 0.0, 0.5 ],
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-24::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_longname": "gain[2]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "gain",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-24::obj-32": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-24::obj-35": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-24::obj-90": {
                    "parameter_invisible": 0,
                    "parameter_longname": "mix_pct",
                    "parameter_modmode": 3,
                    "parameter_shortname": "mix_pct",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-25::obj-10": {
                    "parameter_longname": "bias[1]"
                },
                "obj-25::obj-14": {
                    "parameter_longname": "bm[1]"
                },
                "obj-25::obj-17": {
                    "parameter_longname": "live.menu[18]"
                },
                "obj-25::obj-22": {
                    "parameter_longname": "live.text[12]"
                },
                "obj-25::obj-29": {
                    "parameter_longname": "freq[1]"
                },
                "obj-25::obj-42": {
                    "parameter_longname": "live.toggle[3]"
                },
                "obj-25::obj-47": {
                    "parameter_longname": "polarizer[1]"
                },
                "obj-25::obj-51": {
                    "parameter_longname": "live.menu[19]"
                },
                "obj-25::obj-53": {
                    "parameter_longname": "speed[1]"
                },
                "obj-25::obj-54": {
                    "parameter_longname": "morph[1]"
                },
                "obj-25::obj-6": {
                    "parameter_longname": "pm[1]",
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-25::obj-65": {
                    "parameter_longname": "shape[1]"
                },
                "obj-25::obj-71": {
                    "parameter_longname": "phase[1]"
                },
                "obj-25::obj-72": {
                    "parameter_longname": "phase_time_switch[1]"
                },
                "obj-7::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_range": [ -1.0, 1.0 ],
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-7::obj-23": {
                    "parameter_longname": "tilt",
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-7::obj-26": {
                    "parameter_longname": "slope",
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-7::obj-47": {
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-8::obj-11": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-8::obj-13": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-8::obj-2": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-8::obj-25": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-8::obj-27": {
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
                "obj-8::obj-31": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-8::obj-37": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-8::obj-40": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-8::obj-43": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-8::obj-60": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-8::obj-63": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-8::obj-82": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-9::obj-20": {
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
                "obj-9::obj-26": {
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
                "obj-9::obj-32": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-9::obj-35": {
                    "parameter_invisible": 0,
                    "parameter_longname": "strength",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-9::obj-38": {
                    "parameter_longname": "mix_pct[1]"
                }
            },
            "inherited_shortname": 1
        },
        "autosave": 0,
        "boxgroups": [
            {
                "boxes": [ "obj-10", "obj-11" ]
            }
        ]
    }
}