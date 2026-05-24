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
        "rect": [ 100.0, 100.0, 800.0, 600.0 ],
        "openinpresentation": 1,
        "boxes": [
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-20",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 65.0, 133.0, 51.0, 21.0 ],
                    "presentation": 1,
                    "presentation_rect": [ -1.5, 0.0, 54.0, 21.0 ],
                    "text": "Droste"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "Scale ratio — layer density",
                    "id": "obj-2",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "droste_pix::zoom",
                    "parameter_enable": 1,
                    "patching_rect": [ 50.0, 80.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 12.0, 27.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 2.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "zoom",
                            "parameter_mmax": 8.0,
                            "parameter_mmin": 1.1,
                            "parameter_modmode": 3,
                            "parameter_shortname": "zoom",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "zoom"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "Spiral arm count",
                    "id": "obj-3",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "droste_pix::n_arms",
                    "parameter_enable": 1,
                    "patching_rect": [ 100.0, 80.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 52.0, 27.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 1.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "n_arms",
                            "parameter_mmax": 8.0,
                            "parameter_mmin": -8.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "n_arms",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "n_arms"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "0=rings  1=Escher spiral",
                    "id": "obj-4",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "droste_pix::twist",
                    "parameter_enable": 1,
                    "patching_rect": [ 150.0, 80.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 92.0, 27.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "twist",
                            "parameter_mmax": 8.0,
                            "parameter_mmin": -8.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "twist",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "twist"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "Angular offset",
                    "id": "obj-5",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "droste_pix::rotation",
                    "parameter_enable": 1,
                    "patching_rect": [ 200.0, 80.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 132.0, 27.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "rotation",
                            "parameter_mmax": 1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "rotation",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "rotation"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-6",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 50.0, 140.0, 35.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 10.0, 74.0, 35.0, 18.0 ],
                    "text": "zoom"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-7",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 100.0, 140.0, 35.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 50.0, 74.0, 35.0, 18.0 ],
                    "text": "arms"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-8",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 150.0, 140.0, 35.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 90.0, 74.0, 35.0, 18.0 ],
                    "text": "twist"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-9",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 200.0, 140.0, 30.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 133.0, 74.0, 30.0, 18.0 ],
                    "text": "rot"
                }
            },
            {
                "box": {
                    "comment": "texture in",
                    "id": "obj-10",
                    "index": 0,
                    "maxclass": "inlet",
                    "numinlets": 0,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 300.0, 30.0, 30.0, 30.0 ]
                }
            },
            {
                "box": {
                    "comment": "time_s",
                    "id": "obj-11",
                    "index": 0,
                    "maxclass": "inlet",
                    "numinlets": 0,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 523.0, 34.0, 30.0, 30.0 ]
                }
            },
            {
                "box": {
                    "comment": "texture out",
                    "id": "obj-12",
                    "index": 0,
                    "maxclass": "outlet",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 300.0, 500.0, 30.0, 30.0 ]
                }
            },
            {
                "box": {
                    "id": "obj-13",
                    "maxclass": "newobj",
                    "numinlets": 3,
                    "numoutlets": 3,
                    "outlettype": [ "", "", "" ],
                    "patching_rect": [ 300.0, 96.0, 215.0, 22.0 ],
                    "text": "routepass jit_gl_texture jit_matrix"
                }
            },
            {
                "box": {
                    "id": "obj-14",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 50.0, 171.0, 123.0, 22.0 ],
                    "text": "prepend param zoom"
                }
            },
            {
                "box": {
                    "id": "obj-15",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 101.0, 204.0, 133.0, 22.0 ],
                    "text": "prepend param n_arms"
                }
            },
            {
                "box": {
                    "id": "obj-16",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 150.0, 248.0, 117.0, 22.0 ],
                    "text": "prepend param twist"
                }
            },
            {
                "box": {
                    "id": "obj-17",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 200.0, 292.0, 133.0, 22.0 ],
                    "text": "prepend param rotation"
                }
            },
            {
                "box": {
                    "id": "obj-18",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 523.0, 101.0, 129.0, 22.0 ],
                    "text": "prepend param time_s"
                }
            },
            {
                "box": {
                    "id": "obj-19",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "jit_gl_texture", "" ],
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
                        "rect": [ 100.0, 100.0, 700.0, 600.0 ],
                        "boxes": [
                            {
                                "box": {
                                    "id": "gen-obj-1",
                                    "maxclass": "newobj",
                                    "numinlets": 0,
                                    "numoutlets": 1,
                                    "outlettype": [ "" ],
                                    "patching_rect": [ 22.0, 30.0, 28.0, 22.0 ],
                                    "text": "in 1"
                                }
                            },
                            {
                                "box": {
                                    "code": "Param zoom(2.0);\nParam n_arms(1.0);\nParam time_s(0.0);\nParam twist(0.0);\nParam rotation(0.0);\n\nTWO_PI = 6.28318530717959;\n\ndx = norm.x - 0.5;\ndy = norm.y - 0.5;\n\nr = sqrt(dx*dx + dy*dy);\ntheta = atan2(dy, dx);\n\nlog_zoom = log(max(zoom, 1.001));\ns = log(max(r, 0.00001)) / log_zoom;\nt = (theta / TWO_PI) + rotation;\n\ns = s + time_s;\n\n// symmetric shear in log-polar space\n// twist=0: rings + radial spokes\n// twist=1: Escher coupling — both families spiral, one revolution = one zoom level\ns_sp = s - t * twist;\nt_sp = t + s * twist;\n\nout1 = sample(in1, vec(fract(t_sp / n_arms), fract(s_sp), 0));",
                                    "fontface": 0,
                                    "fontname": "<Monospaced>",
                                    "fontsize": 12.0,
                                    "id": "gen-obj-2",
                                    "maxclass": "codebox",
                                    "numinlets": 1,
                                    "numoutlets": 1,
                                    "outlettype": [ "" ],
                                    "patching_rect": [ 22.0, 80.0, 550.0, 380.0 ]
                                }
                            },
                            {
                                "box": {
                                    "id": "gen-obj-3",
                                    "maxclass": "newobj",
                                    "numinlets": 1,
                                    "numoutlets": 0,
                                    "patching_rect": [ 22.0, 490.0, 35.0, 22.0 ],
                                    "text": "out 1"
                                }
                            }
                        ],
                        "lines": [
                            {
                                "patchline": {
                                    "destination": [ "gen-obj-2", 0 ],
                                    "source": [ "gen-obj-1", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "gen-obj-3", 0 ],
                                    "source": [ "gen-obj-2", 0 ]
                                }
                            }
                        ]
                    },
                    "patching_rect": [ 300.0, 380.0, 230.0, 22.0 ],
                    "text": "jit.gl.pix vsynth @name droste_pix",
                    "varname": "droste_pix"
                }
            },
            {
                "box": {
                    "angle": 270.0,
                    "background": 1,
                    "bgcolor": [ 0.0, 0.0, 0.0, 1.0 ],
                    "border": 1,
                    "bordercolor": [ 0.0, 0.03529411765, 0.2274509804, 1.0 ],
                    "id": "obj-1",
                    "maxclass": "panel",
                    "mode": 0,
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 20.0, 20.0, 175.0, 85.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 0.0, 0.0, 175.0, 97.0 ],
                    "proportion": 0.5
                }
            }
        ],
        "lines": [
            {
                "patchline": {
                    "destination": [ "obj-13", 0 ],
                    "source": [ "obj-10", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-18", 0 ],
                    "source": [ "obj-11", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-19", 0 ],
                    "source": [ "obj-13", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-19", 0 ],
                    "source": [ "obj-14", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-19", 0 ],
                    "source": [ "obj-15", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-19", 0 ],
                    "source": [ "obj-16", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-19", 0 ],
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
                    "destination": [ "obj-12", 0 ],
                    "source": [ "obj-19", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-14", 0 ],
                    "source": [ "obj-2", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-15", 0 ],
                    "source": [ "obj-3", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-16", 0 ],
                    "source": [ "obj-4", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-17", 0 ],
                    "source": [ "obj-5", 0 ]
                }
            }
        ],
        "parameters": {
            "obj-2": [ "zoom", "zoom", 0 ],
            "obj-3": [ "n_arms", "n_arms", 0 ],
            "obj-4": [ "twist", "twist", 0 ],
            "obj-5": [ "rotation", "rotation", 0 ],
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