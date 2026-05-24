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
        "rect": [ 232.0, 294.0, 334.0, 532.0 ],
        "boxes": [
            {
                "box": {
                    "id": "obj-1",
                    "maxclass": "live.menu",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "outlettype": [ "", "", "float" ],
                    "parameter_enable": 1,
                    "patching_rect": [ 10.0, 10.0, 130.0, 15.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 10.0, 10.0, 130.0, 15.0 ],
                    "saved_attribute_attributes": {
                        "valueof": {
                            "parameter_enum": [ "Channel Grader", "Droste", "Grain", "Hue Processor", "Luma Processor", "Tex Router", "Tone Curve" ],
                            "parameter_longname": "f_module",
                            "parameter_mmax": 6,
                            "parameter_modmode": 0,
                            "parameter_shortname": "f_module",
                            "parameter_type": 2
                        }
                    },
                    "varname": "f_module"
                }
            },
            {
                "box": {
                    "id": "obj-2",
                    "maxclass": "live.menu",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "outlettype": [ "", "", "float" ],
                    "parameter_enable": 1,
                    "patching_rect": [ 10.0, 60.0, 130.0, 15.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 10.0, 60.0, 130.0, 15.0 ],
                    "saved_attribute_attributes": {
                        "valueof": {
                            "parameter_enum": [ "channel_grader", "droste", "grain", "hue_processor", "luma_processor", "texrouter", "tone_curve" ],
                            "parameter_longname": "f_module_name",
                            "parameter_mmax": 6,
                            "parameter_modmode": 0,
                            "parameter_shortname": "f_module_name",
                            "parameter_type": 2
                        }
                    },
                    "varname": "f_module_name"
                }
            },
            {
                "box": {
                    "id": "obj-3",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 10.0, 148.0, 99.0, 22.0 ],
                    "text": "prepend addmod"
                }
            },
            {
                "box": {
                    "id": "obj-4",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 100.0, 229.0, 100.0, 22.0 ],
                    "saved_object_attributes": {
                        "filename": "f_addmod.js",
                        "parameter_enable": 0
                    },
                    "text": "js f_addmod.js"
                }
            },
            {
                "box": {
                    "id": "obj-5",
                    "maxclass": "newobj",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 100.0, 199.0, 60.0, 22.0 ],
                    "text": "gate 1 0"
                }
            },
            {
                "box": {
                    "id": "obj-6",
                    "maxclass": "newobj",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 100.0, 124.0, 60.0, 22.0 ],
                    "text": "pipe 250"
                }
            },
            {
                "box": {
                    "id": "obj-7",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 100.0, 91.0, 70.0, 22.0 ],
                    "text": "loadmess 1"
                }
            }
        ],
        "lines": [
            {
                "patchline": {
                    "destination": [ "obj-2", 0 ],
                    "source": [ "obj-1", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-3", 0 ],
                    "source": [ "obj-2", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 1 ],
                    "source": [ "obj-3", 0 ]
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
                    "destination": [ "obj-6", 0 ],
                    "source": [ "obj-7", 0 ]
                }
            }
        ],
        "parameters": {
            "obj-1": [ "f_module", "f_module", 0 ],
            "obj-2": [ "f_module_name", "f_module_name", 0 ],
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