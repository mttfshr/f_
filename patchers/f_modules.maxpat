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
        "rect": [ 246.0, 208.0, 892.0, 835.0 ],
        "openinpresentation": 1,
        "boxes": [
            {
                "box": {
                    "fontface": 2,
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.5,
                    "id": "obj-2",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 3.0, 4.0, 156.0, 21.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 3.0, 4.0, 89.66666933894157, 21.0 ],
                    "text": "f_",
                    "textcolor": [ 1.0, 1.0, 1.0, 1.0 ]
                }
            },
            {
                "box": {
                    "id": "obj-3",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 200.0, 300.0, 100.0, 22.0 ],
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
                    "outlettype": [ "" ],
                    "patching_rect": [ 200.0, 270.0, 55.0, 22.0 ],
                    "text": "gate 1 0"
                }
            },
            {
                "box": {
                    "id": "obj-5",
                    "maxclass": "newobj",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 130.0, 230.0, 60.0, 22.0 ],
                    "text": "pipe 250"
                }
            },
            {
                "box": {
                    "id": "obj-6",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 130.0, 200.0, 72.0, 22.0 ],
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
                    "patching_rect": [ 3.0, 25.0, 176.0, 21.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 2.0, 25.0, 89.66666933894157, 21.0 ],
                    "text": "Generators",
                    "textcolor": [ 0.45098039215686275, 0.47058823529411764, 0.5764705882352941, 1.0 ]
                }
            },
            {
                "box": {
                    "appearance": 1,
                    "fontname": "Ableton Sans Light",
                    "fontsize": 11.0,
                    "id": "obj-8",
                    "lcdcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "maxclass": "live.menu",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "outlettype": [ "", "", "float" ],
                    "parameter_enable": 1,
                    "parameter_mappable": 0,
                    "patching_rect": [ 3.0, 600.0, 154.0, 17.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 3.0, 46.0, 89.66666933894157, 17.0 ],
                    "saved_attribute_attributes": {
                        "lcdcolor": {
                            "expression": "themecolor.live_arranger_grid_tiles"
                        },
                        "valueof": {
                            "parameter_enum": [ "Masonry", "Chladni", "Stipple", "Grain" ],
                            "parameter_initial": [ 0.0 ],
                            "parameter_invisible": 2,
                            "parameter_longname": "f_module_0_disp",
                            "parameter_mmax": 3,
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
                    "outlettype": [ "", "", "float" ],
                    "parameter_enable": 1,
                    "parameter_mappable": 0,
                    "patching_rect": [ 3.0, 1200.0, 154.0, 15.0 ],
                    "saved_attribute_attributes": {
                        "valueof": {
                            "parameter_enum": [ "masonry", "chladni", "stipple", "grain" ],
                            "parameter_initial": [ 0.0 ],
                            "parameter_invisible": 2,
                            "parameter_longname": "f_module_0_file",
                            "parameter_mmax": 3,
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
                    "outlettype": [ "" ],
                    "patching_rect": [ 3.0, 1800.0, 100.0, 22.0 ],
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
                    "patching_rect": [ 3.0, 68.0, 176.0, 21.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 2.0, 68.0, 89.66666933894157, 21.0 ],
                    "text": "Processors",
                    "textcolor": [ 0.45098039215686275, 0.47058823529411764, 0.5764705882352941, 1.0 ]
                }
            },
            {
                "box": {
                    "appearance": 1,
                    "fontname": "Ableton Sans Light",
                    "fontsize": 11.0,
                    "id": "obj-12",
                    "lcdcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "maxclass": "live.menu",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "outlettype": [ "", "", "float" ],
                    "parameter_enable": 1,
                    "parameter_mappable": 0,
                    "patching_rect": [ 3.0, 700.0, 154.0, 17.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 3.0, 89.0, 89.66666933894157, 17.0 ],
                    "saved_attribute_attributes": {
                        "lcdcolor": {
                            "expression": "themecolor.live_arranger_grid_tiles"
                        },
                        "valueof": {
                            "parameter_enum": [ "Droste", "Mobius", "Stereo", "Lens", "Caustic ∇" ],
                            "parameter_initial": [ 0.0 ],
                            "parameter_invisible": 2,
                            "parameter_longname": "f_module_1_disp",
                            "parameter_mmax": 4,
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
                    "outlettype": [ "", "", "float" ],
                    "parameter_enable": 1,
                    "parameter_mappable": 0,
                    "patching_rect": [ 3.0, 1300.0, 154.0, 15.0 ],
                    "saved_attribute_attributes": {
                        "valueof": {
                            "parameter_enum": [ "droste", "mobius", "stereo", "lens", "caustic" ],
                            "parameter_initial": [ 0.0 ],
                            "parameter_invisible": 2,
                            "parameter_longname": "f_module_1_file",
                            "parameter_mmax": 4,
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
                    "outlettype": [ "" ],
                    "patching_rect": [ 3.0, 1900.0, 100.0, 22.0 ],
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
                    "patching_rect": [ 3.0, 111.0, 176.0, 21.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 3.0, 153.0, 89.66666933894157, 21.0 ],
                    "text": "Color / Tone",
                    "textcolor": [ 0.45098039215686275, 0.47058823529411764, 0.5764705882352941, 1.0 ]
                }
            },
            {
                "box": {
                    "appearance": 1,
                    "fontname": "Ableton Sans Light",
                    "fontsize": 11.0,
                    "id": "obj-16",
                    "lcdcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "maxclass": "live.menu",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "outlettype": [ "", "", "float" ],
                    "parameter_enable": 1,
                    "parameter_mappable": 0,
                    "patching_rect": [ 3.0, 800.0, 154.0, 17.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 3.0, 174.0, 89.66666933894157, 17.0 ],
                    "saved_attribute_attributes": {
                        "lcdcolor": {
                            "expression": "themecolor.live_arranger_grid_tiles"
                        },
                        "valueof": {
                            "parameter_enum": [ "Channel Grader", "Hue Processor", "Luma Processor", "Tone Curve" ],
                            "parameter_initial": [ 0.0 ],
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
                    "outlettype": [ "", "", "float" ],
                    "parameter_enable": 1,
                    "parameter_mappable": 0,
                    "patching_rect": [ 3.0, 1400.0, 154.0, 15.0 ],
                    "saved_attribute_attributes": {
                        "valueof": {
                            "parameter_enum": [ "channel_grader", "hue_processor", "luma_processor", "tone_curve" ],
                            "parameter_initial": [ 0.0 ],
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
                    "outlettype": [ "" ],
                    "patching_rect": [ 3.0, 2000.0, 100.0, 22.0 ],
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
                    "patching_rect": [ 3.0, 154.0, 176.0, 21.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 3.0, 196.0, 89.66666933894157, 21.0 ],
                    "text": "Utilities",
                    "textcolor": [ 0.45098039215686275, 0.47058823529411764, 0.5764705882352941, 1.0 ]
                }
            },
            {
                "box": {
                    "appearance": 1,
                    "fontname": "Ableton Sans Light",
                    "fontsize": 11.0,
                    "id": "obj-20",
                    "lcdcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "maxclass": "live.menu",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "outlettype": [ "", "", "float" ],
                    "parameter_enable": 1,
                    "parameter_mappable": 0,
                    "patching_rect": [ 3.0, 900.0, 154.0, 17.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 3.0, 217.0, 89.66666933894157, 17.0 ],
                    "saved_attribute_attributes": {
                        "lcdcolor": {
                            "expression": "themecolor.live_arranger_grid_tiles"
                        },
                        "valueof": {
                            "parameter_enum": [ "Tex Router", "Profile" ],
                            "parameter_initial": [ 0.0 ],
                            "parameter_invisible": 2,
                            "parameter_longname": "f_module_3_disp",
                            "parameter_mmax": 1,
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
                    "outlettype": [ "", "", "float" ],
                    "parameter_enable": 1,
                    "parameter_mappable": 0,
                    "patching_rect": [ 3.0, 1500.0, 154.0, 15.0 ],
                    "saved_attribute_attributes": {
                        "valueof": {
                            "parameter_enum": [ "texrouter", "util_profile" ],
                            "parameter_initial": [ 0.0 ],
                            "parameter_invisible": 2,
                            "parameter_longname": "f_module_3_file",
                            "parameter_mmax": 1,
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
                    "outlettype": [ "" ],
                    "patching_rect": [ 3.0, 2100.0, 100.0, 22.0 ],
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
                    "patching_rect": [ 3.0, 197.0, 176.0, 21.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 2.0, 112.0, 89.66666933894157, 21.0 ],
                    "text": "Vecfield ∇",
                    "textcolor": [ 0.45098039215686275, 0.47058823529411764, 0.5764705882352941, 1.0 ]
                }
            },
            {
                "box": {
                    "appearance": 1,
                    "fontname": "Ableton Sans Light",
                    "fontsize": 11.0,
                    "id": "obj-24",
                    "lcdcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "maxclass": "live.menu",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "outlettype": [ "", "", "float" ],
                    "parameter_enable": 1,
                    "parameter_mappable": 0,
                    "patching_rect": [ 3.0, 1000.0, 154.0, 17.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 3.0, 133.0, 89.66666933894157, 17.0 ],
                    "saved_attribute_attributes": {
                        "lcdcolor": {
                            "expression": "themecolor.live_arranger_grid_tiles"
                        },
                        "valueof": {
                            "parameter_enum": [ "Vortex ∇", "Vortex Multi ∇", "Fieldmap ∇", "Warp ∇" ],
                            "parameter_initial": [ 0.0 ],
                            "parameter_invisible": 2,
                            "parameter_longname": "f_module_4_disp",
                            "parameter_mmax": 3,
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
                    "outlettype": [ "", "", "float" ],
                    "parameter_enable": 1,
                    "parameter_mappable": 0,
                    "patching_rect": [ 3.0, 1600.0, 154.0, 15.0 ],
                    "saved_attribute_attributes": {
                        "valueof": {
                            "parameter_enum": [ "vf_vortex", "vf_vortex_multi", "vf_fieldmap", "vf_warp" ],
                            "parameter_initial": [ 0.0 ],
                            "parameter_invisible": 2,
                            "parameter_longname": "f_module_4_file",
                            "parameter_mmax": 3,
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
                    "outlettype": [ "" ],
                    "patching_rect": [ 3.0, 2200.0, 100.0, 22.0 ],
                    "text": "prepend addmod"
                }
            },
            {
                "box": {
                    "background": 1,
                    "bgcolor": [ 0.0, 0.0, 0.0, 1.0 ],
                    "border": 2,
                    "bordercolor": [ 0.0, 0.03529411765, 0.2274509804, 1.0 ],
                    "id": "obj-1",
                    "maxclass": "panel",
                    "mode": 0,
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 0.0, 0.0, 160.0, 209.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 0.0, 0.0, 96.0, 245.0 ],
                    "rounded": 6
                }
            }
        ],
        "lines": [
            {
                "patchline": {
                    "destination": [ "obj-4", 1 ],
                    "source": [ "obj-10", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-13", 0 ],
                    "source": [ "obj-12", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-14", 0 ],
                    "source": [ "obj-13", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-4", 1 ],
                    "source": [ "obj-14", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-17", 0 ],
                    "source": [ "obj-16", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-18", 0 ],
                    "source": [ "obj-17", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-4", 1 ],
                    "source": [ "obj-18", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-21", 0 ],
                    "source": [ "obj-20", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-22", 0 ],
                    "source": [ "obj-21", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-4", 1 ],
                    "source": [ "obj-22", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-25", 0 ],
                    "source": [ "obj-24", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-26", 0 ],
                    "source": [ "obj-25", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-4", 1 ],
                    "source": [ "obj-26", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-3", 0 ],
                    "source": [ "obj-4", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-4", 0 ],
                    "source": [ "obj-5", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 0 ],
                    "source": [ "obj-6", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-9", 0 ],
                    "source": [ "obj-8", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-10", 0 ],
                    "source": [ "obj-9", 1 ]
                }
            }
        ],
        "parameters": {
            "obj-12": [ "f_module_1_disp", "live.menu", 0 ],
            "obj-13": [ "f_module_1_file", "live.menu", 0 ],
            "obj-16": [ "f_module_2_disp", "live.menu", 0 ],
            "obj-17": [ "f_module_2_file", "live.menu", 0 ],
            "obj-20": [ "f_module_3_disp", "live.menu", 0 ],
            "obj-21": [ "f_module_3_file", "live.menu", 0 ],
            "obj-24": [ "f_module_4_disp", "live.menu", 0 ],
            "obj-25": [ "f_module_4_file", "live.menu", 0 ],
            "obj-8": [ "f_module_0_disp", "live.menu", 0 ],
            "obj-9": [ "f_module_0_file", "live.menu", 0 ],
            "parameterbanks": {
                "0": {
                    "index": 0,
                    "name": "",
                    "parameters": [ "-", "-", "-", "-", "-", "-", "-", "-" ],
                    "buttons": [ "-", "-", "-", "-", "-", "-", "-", "-" ]
                }
            },
            "inherited_shortname": 1
        },
        "autosave": 0
    }
}