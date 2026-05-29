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
        "rect": [ 34.0, 100.0, 1200.0, 800.0 ],
        "openinpresentation": 1,
        "boxes": [
            {
                "box": {
                    "angle": 270.0,
                    "background": 1,
                    "bgcolor": [ 0, 0, 0, 1 ],
                    "border": 1,
                    "bordercolor": [ 0.0, 0.03529411765, 0.2274509804, 1.0 ],
                    "id": "obj-1",
                    "maxclass": "panel",
                    "mode": 0,
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 20.0, 20.0, 175.0, 155.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 0.0, 0.0, 175.0, 155.0 ],
                    "proportion": 0.5
                }
            },
            {
                "box": {
                    "filename": "bypass_toggle.js",
                    "hint": "Bypass",
                    "id": "obj-2",
                    "maxclass": "jsui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "param_connect": "lens_pix::bypass",
                    "parameter_enable": 1,
                    "patching_rect": [ 700.0, 30.0, 18.0, 12.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 155.0, 5.0, 18.0, 12.0 ],
                    "saved_attribute_attributes": {
                        "valueof": {
                            "parameter_invisible": 1,
                            "parameter_longname": "bypass",
                            "parameter_modmode": 4,
                            "parameter_shortname": "bypass",
                            "parameter_type": 1,
                            "parameter_unitstyle": 0
                        }
                    },
                    "valuepopuplabel": 1,
                    "varname": "bypass[1]"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-3",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 20.0, 20.0, 80.0, 21.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 2.0, 2.0, 50.0, 21.0 ],
                    "text": "Lens"
                }
            },
            {
                "box": {
                    "activebgcolor": [ 0.067, 0.063, 0.063, 1.0 ],
                    "activebgoncolor": [ 0.067, 0.063, 0.063, 1.0 ],
                    "activetextcolor": [ 0.757, 0.757, 0.757, 1.0 ],
                    "activetextoncolor": [ 0.659, 0.659, 0.659, 1.0 ],
                    "bordercolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "id": "obj-4",
                    "maxclass": "live.text",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "" ],
                    "parameter_enable": 1,
                    "patching_rect": [ 800.0, 30.0, 36.0, 14.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 117.0, 3.125, 36.0, 15.75 ],
                    "rounded": 4.0,
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
                        "bordercolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_enum": [ "val1", "val2" ],
                            "parameter_initial": [ 0.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "panel_toggle",
                            "parameter_mmax": 1,
                            "parameter_modmode": 0,
                            "parameter_shortname": "panel_toggle",
                            "parameter_speedlim": 0.0,
                            "parameter_type": 2
                        }
                    },
                    "text": "lens",
                    "texton": "field",
                    "varname": "panel_toggle"
                }
            },
            {
                "box": {
                    "comment": "texture + ctrl",
                    "id": "obj-5",
                    "index": 0,
                    "maxclass": "inlet",
                    "numinlets": 0,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 50.0, 30.0, 30.0, 30.0 ]
                }
            },
            {
                "box": {
                    "comment": "aberration mod",
                    "id": "obj-6",
                    "index": 0,
                    "maxclass": "inlet",
                    "numinlets": 0,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 200.0, 30.0, 30.0, 30.0 ]
                }
            },
            {
                "box": {
                    "comment": "distortion mod",
                    "id": "obj-7",
                    "index": 0,
                    "maxclass": "inlet",
                    "numinlets": 0,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 350.0, 30.0, 30.0, 30.0 ]
                }
            },
            {
                "box": {
                    "comment": "transmission mod",
                    "id": "obj-8",
                    "index": 0,
                    "maxclass": "inlet",
                    "numinlets": 0,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 500.0, 30.0, 30.0, 30.0 ]
                }
            },
            {
                "box": {
                    "comment": "surface mod",
                    "id": "obj-9",
                    "index": 0,
                    "maxclass": "inlet",
                    "numinlets": 0,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 650.0, 30.0, 30.0, 30.0 ]
                }
            },
            {
                "box": {
                    "comment": "texture out",
                    "id": "obj-10",
                    "index": 0,
                    "maxclass": "outlet",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 50.0, 650.0, 30.0, 30.0 ]
                }
            },
            {
                "box": {
                    "id": "obj-11",
                    "maxclass": "newobj",
                    "numinlets": 3,
                    "numoutlets": 3,
                    "outlettype": [ "", "", "" ],
                    "patching_rect": [ 50.0, 130.0, 252.0, 22.0 ],
                    "text": "routepass jit_gl_texture jit_matrix"
                }
            },
            {
                "box": {
                    "id": "obj-12",
                    "maxclass": "newobj",
                    "numinlets": 14,
                    "numoutlets": 14,
                    "outlettype": [ "", "", "", "", "", "", "", "", "", "", "", "", "", "" ],
                    "patching_rect": [ 350.0, 130.0, 1015.2, 22.0 ],
                    "text": "route bypass aberration distortion transmission tilt tilt_axis tilt_pos slope mode aberration_mod distortion_mod transmission_mod surface_mod"
                }
            },
            {
                "box": {
                    "id": "obj-13",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 4,
                    "outlettype": [ "", "", "", "" ],
                    "patching_rect": [ 950.0, 50.0, 237.6, 22.0 ],
                    "restore": {
                        "aberration": [ 0.0 ],
                        "aberration_mod": [ 0.0 ],
                        "bypass[1]": [ 0 ],
                        "distortion": [ 0.5 ],
                        "distortion_mod": [ 0.0 ],
                        "mode": [ 0.0 ],
                        "panel_toggle": [ 1.0 ],
                        "slope": [ 0.5 ],
                        "surface_mod": [ 0.0 ],
                        "tilt": [ 0.0 ],
                        "tilt_axis": [ 0.0 ],
                        "tilt_pos": [ 0.5 ],
                        "transmission": [ 0.0 ],
                        "transmission_mod": [ 0.0 ]
                    },
                    "text": "autopattr @varname lens_autopattr",
                    "varname": "u267006191"
                }
            },
            {
                "box": {
                    "id": "obj-14",
                    "maxclass": "newobj",
                    "numinlets": 5,
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
                        "rect": [ 117.0, 95.0, 650.0, 800.0 ],
                        "boxes": [
                            {
                                "box": {
                                    "id": "gen-1",
                                    "maxclass": "newobj",
                                    "numinlets": 0,
                                    "numoutlets": 1,
                                    "outlettype": [ "" ],
                                    "patching_rect": [ 50.0, 14.0, 28.0, 22.0 ],
                                    "text": "in 1"
                                }
                            },
                            {
                                "box": {
                                    "id": "gen-2",
                                    "maxclass": "newobj",
                                    "numinlets": 0,
                                    "numoutlets": 1,
                                    "outlettype": [ "" ],
                                    "patching_rect": [ 120.0, 14.0, 28.0, 22.0 ],
                                    "text": "in 2"
                                }
                            },
                            {
                                "box": {
                                    "id": "gen-3",
                                    "maxclass": "newobj",
                                    "numinlets": 0,
                                    "numoutlets": 1,
                                    "outlettype": [ "" ],
                                    "patching_rect": [ 190.0, 14.0, 28.0, 22.0 ],
                                    "text": "in 3"
                                }
                            },
                            {
                                "box": {
                                    "id": "gen-4",
                                    "maxclass": "newobj",
                                    "numinlets": 0,
                                    "numoutlets": 1,
                                    "outlettype": [ "" ],
                                    "patching_rect": [ 260.0, 14.0, 28.0, 22.0 ],
                                    "text": "in 4"
                                }
                            },
                            {
                                "box": {
                                    "id": "gen-5",
                                    "maxclass": "newobj",
                                    "numinlets": 0,
                                    "numoutlets": 1,
                                    "outlettype": [ "" ],
                                    "patching_rect": [ 330.0, 14.0, 28.0, 22.0 ],
                                    "text": "in 5"
                                }
                            },
                            {
                                "box": {
                                    "code": "Param aberration(0.0);\nParam distortion(0.5);\nParam transmission(0.0);\nParam aberration_mod(0.0);\nParam distortion_mod(0.0);\nParam transmission_mod(0.0);\nParam surface_mod(0.0);\nParam bypass(0.0);\n\n// --- UV setup ---\nuv = norm;\ncx = uv.x - 0.5;\ncy = uv.y - 0.5;\ndist = length(vec(cx, cy));\n\n// --- Sample mod textures (black = neutral for all) ---\naberr_tex = sample(in2, uv).x;\ndist_tex  = sample(in3, uv).x;\ntrans_tex = sample(in4, uv).x;\neps    = 0.002;\nsurf_c = sample(in5, uv).x;\nsurf_r = sample(in5, vec(uv.x + eps, uv.y)).x;\nsurf_u = sample(in5, vec(uv.x, uv.y + eps)).x;\n\n// --- Distortion (spatially modulated by in3) ---\nk = (distortion - 0.5) * 2.0;\nk = k * (1.0 + dist_tex * distortion_mod);\nr2 = cx*cx + cy*cy;\nwarp_cx = cx * (1.0 + k*r2);\nwarp_cy = cy * (1.0 + k*r2);\nwarp_uv = vec(0.5 + warp_cx, 0.5 + warp_cy);\n\n// --- Surface emboss (nudge warp_uv by in5 gradient) ---\nsurf_dx = (surf_r - surf_c) * surface_mod;\nsurf_dy = (surf_u - surf_c) * surface_mod;\nwarp_uv = vec(warp_uv.x + surf_dx, warp_uv.y + surf_dy);\nwarp_cx = warp_uv.x - 0.5;\nwarp_cy = warp_uv.y - 0.5;\n\n// --- Chromatic aberration (spatially modulated by in2) ---\nab = aberration * dist * (1.0 + aberr_tex * aberration_mod);\nr_uv = vec(0.5 + warp_cx * (1.0 + ab), 0.5 + warp_cy * (1.0 + ab));\nb_uv = vec(0.5 + warp_cx * (1.0 - ab), 0.5 + warp_cy * (1.0 - ab));\nr_val = sample(in1, r_uv).x;\ng_val = sample(in1, warp_uv).y;\nb_val = sample(in1, b_uv).z;\neffect_out = vec(r_val, g_val, b_val, 1.0);\n\n// --- Transmission vignette (spatially modulated by in4) ---\ndist_v = dist * (1.0 + trans_tex * transmission_mod);\nvignette = 1.0 - smoothstep(0.3, 0.7, dist_v);\nwarm_shift = vec(1.05, 1.0, 0.92, 1.0);\neffect_out = mix(effect_out * warm_shift * vignette, effect_out, 1.0 - transmission);\n\n// --- Bypass ---\nout1 = mix(effect_out, sample(in1, uv), bypass);",
                                    "fontface": 0,
                                    "fontname": "<Monospaced>",
                                    "fontsize": 12.0,
                                    "id": "gen-6",
                                    "maxclass": "codebox",
                                    "numinlets": 5,
                                    "numoutlets": 1,
                                    "outlettype": [ "" ],
                                    "patching_rect": [ 50.0, 60.0, 500.0, 620.0 ]
                                }
                            },
                            {
                                "box": {
                                    "id": "gen-7",
                                    "maxclass": "newobj",
                                    "numinlets": 1,
                                    "numoutlets": 0,
                                    "patching_rect": [ 50.0, 700.0, 35.0, 22.0 ],
                                    "text": "out 1"
                                }
                            }
                        ],
                        "lines": [
                            {
                                "patchline": {
                                    "destination": [ "gen-6", 0 ],
                                    "source": [ "gen-1", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "gen-6", 1 ],
                                    "source": [ "gen-2", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "gen-6", 2 ],
                                    "source": [ "gen-3", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "gen-6", 3 ],
                                    "source": [ "gen-4", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "gen-6", 4 ],
                                    "source": [ "gen-5", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "gen-7", 0 ],
                                    "source": [ "gen-6", 0 ]
                                }
                            }
                        ]
                    },
                    "patching_rect": [ 200.0, 450.0, 200.0, 22.0 ],
                    "text": "jit.gl.pix vsynth @name lens_pix",
                    "varname": "lens_pix"
                }
            },
            {
                "box": {
                    "embedstate": [
                        [ "adapt", 1 ],
                        [ "bypass", 0 ],
                        [ "enable", 1 ]
                    ],
                    "filename": "jit.fx.cf.tiltshift.js",
                    "id": "obj-15",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 200.0, 560.0, 160.0, 22.0 ],
                    "saved_object_attributes": {
                        "parameter_enable": 0
                    },
                    "text": "jit.fx.cf.tiltshift vsynth",
                    "textfile": {
                        "filename": "jit.fx.cf.tiltshift.js",
                        "flags": 0,
                        "embed": 0,
                        "autowatch": 1
                    },
                    "varname": "lens_tiltshift"
                }
            },
            {
                "box": {
                    "id": "obj-16",
                    "maxclass": "newobj",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 620.0, 320.0, 130.0, 22.0 ],
                    "saved_object_attributes": {
                        "filename": "lens_tiltcenter.js",
                        "parameter_enable": 0
                    },
                    "text": "js lens_tiltcenter.js"
                }
            },
            {
                "box": {
                    "id": "obj-17",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 800.0, 100.0, 120.0, 22.0 ],
                    "saved_object_attributes": {
                        "filename": "lens_toggle.js",
                        "parameter_enable": 0
                    },
                    "text": "js lens_toggle.js"
                }
            },
            {
                "box": {
                    "id": "obj-18",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "" ],
                    "patching_rect": [ 800.0, 160.0, 79.2, 22.0 ],
                    "save": [ "#N", "thispatcher", ";", "#Q", "end", ";" ],
                    "text": "thispatcher"
                }
            },
            {
                "box": {
                    "id": "obj-19",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 700.0, 220.0, 144.0, 22.0 ],
                    "text": "prepend param bypass"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hidden": 1,
                    "hint": "aberration",
                    "id": "obj-20",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "lens_pix::aberration",
                    "parameter_enable": 1,
                    "patching_rect": [ 100.0, 260.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 8.0, 36.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "aberration",
                            "parameter_mmax": 1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "aberration",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "aberration"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hidden": 1,
                    "hint": "distortion",
                    "id": "obj-21",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "lens_pix::distortion",
                    "parameter_enable": 1,
                    "patching_rect": [ 200.0, 260.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 52.0, 36.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.5 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "distortion",
                            "parameter_mmax": 1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "distortion",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "distortion"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hidden": 1,
                    "hint": "transmission",
                    "id": "obj-22",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "lens_pix::transmission",
                    "parameter_enable": 1,
                    "patching_rect": [ 300.0, 260.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 96.0, 36.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "transmission",
                            "parameter_mmax": 1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "transmission",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "transmission"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hidden": 1,
                    "hint": "tilt",
                    "id": "obj-23",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "parameter_enable": 1,
                    "patching_rect": [ 400.0, 260.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 140.0, 36.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "tilt",
                            "parameter_mmax": 1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "tilt",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "tilt"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hidden": 1,
                    "hint": "tilt_axis",
                    "id": "obj-24",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "parameter_enable": 1,
                    "patching_rect": [ 500.0, 260.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 8.0, 104.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "tilt_axis",
                            "parameter_mmax": 1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "tilt_axis",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "tilt_axis"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hidden": 1,
                    "hint": "tilt_pos",
                    "id": "obj-25",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "parameter_enable": 1,
                    "patching_rect": [ 600.0, 260.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 52.0, 104.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.5 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "tilt_pos",
                            "parameter_mmax": 1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "tilt_pos",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "tilt_pos"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hidden": 1,
                    "hint": "slope",
                    "id": "obj-26",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "parameter_enable": 1,
                    "patching_rect": [ 700.0, 260.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 96.0, 104.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.5 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "slope",
                            "parameter_mmax": 1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "slope",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "slope"
                }
            },
            {
                "box": {
                    "activebgcolor": [ 0.067, 0.063, 0.063, 1.0 ],
                    "activebgoncolor": [ 0.067, 0.063, 0.063, 1.0 ],
                    "activetextcolor": [ 0.757, 0.757, 0.757, 1.0 ],
                    "activetextoncolor": [ 0.659, 0.659, 0.659, 1.0 ],
                    "bordercolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hidden": 1,
                    "id": "obj-27",
                    "maxclass": "live.text",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "" ],
                    "parameter_enable": 1,
                    "patching_rect": [ 800.0, 260.0, 44.0, 16.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 79.5, 3.0, 35.5, 16.0 ],
                    "rounded": 4.0,
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
                        "bordercolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_enum": [ "val1", "val2" ],
                            "parameter_initial": [ 0.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "mode",
                            "parameter_mmax": 1,
                            "parameter_modmode": 0,
                            "parameter_shortname": "mode",
                            "parameter_speedlim": 0.0,
                            "parameter_type": 2
                        }
                    },
                    "text": "linear",
                    "texton": "radial",
                    "varname": "mode"
                }
            },
            {
                "box": {
                    "id": "obj-30",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 100.0, 370.0, 172.8, 22.0 ],
                    "text": "prepend param aberration"
                }
            },
            {
                "box": {
                    "id": "obj-31",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 200.0, 370.0, 172.8, 22.0 ],
                    "text": "prepend param distortion"
                }
            },
            {
                "box": {
                    "id": "obj-32",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 300.0, 370.0, 187.20000000000002, 22.0 ],
                    "text": "prepend param transmission"
                }
            },
            {
                "box": {
                    "id": "obj-33",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 400.0, 370.0, 136.8, 22.0 ],
                    "text": "prepend blur_amount"
                }
            },
            {
                "box": {
                    "id": "obj-34",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 500.0, 370.0, 165.6, 22.0 ],
                    "text": "prepend param tilt_axis"
                }
            },
            {
                "box": {
                    "id": "obj-35",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 600.0, 370.0, 158.4, 22.0 ],
                    "text": "prepend param tilt_pos"
                }
            },
            {
                "box": {
                    "id": "obj-36",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 700.0, 370.0, 93.60000000000001, 22.0 ],
                    "text": "prepend slope"
                }
            },
            {
                "box": {
                    "id": "obj-37",
                    "maxclass": "newobj",
                    "numinlets": 3,
                    "numoutlets": 3,
                    "outlettype": [ "bang", "bang", "" ],
                    "patching_rect": [ 800.0, 330.0, 60.0, 22.0 ],
                    "text": "sel 0 1"
                }
            },
            {
                "box": {
                    "id": "obj-38",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 780.0, 380.0, 79.2, 22.0 ],
                    "text": "mode linear"
                }
            },
            {
                "box": {
                    "id": "obj-39",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 880.0, 380.0, 79.2, 22.0 ],
                    "text": "mode radial"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "hidden": 1,
                    "id": "obj-50",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 20.0, 20.0, 44.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 5.0, 20.0, 44.0, 18.0 ],
                    "text": "Aberr",
                    "varname": "lbl_aberration"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "hidden": 1,
                    "id": "obj-51",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 20.0, 20.0, 44.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 47.0, 20.0, 44.0, 18.0 ],
                    "text": "Distort",
                    "varname": "lbl_distortion"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "hidden": 1,
                    "id": "obj-52",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 20.0, 20.0, 44.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 93.0, 20.0, 44.0, 18.0 ],
                    "text": "Trans",
                    "varname": "lbl_transmission"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "hidden": 1,
                    "id": "obj-53",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 20.0, 20.0, 44.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 144.0, 20.0, 35.0, 18.0 ],
                    "text": "Tilt",
                    "varname": "lbl_tilt"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "hidden": 1,
                    "id": "obj-54",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 20.0, 20.0, 44.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 8.0, 88.0, 44.0, 18.0 ],
                    "text": "Axis",
                    "varname": "lbl_tilt_axis"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "hidden": 1,
                    "id": "obj-55",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 20.0, 20.0, 44.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 52.0, 88.0, 44.0, 18.0 ],
                    "text": "Pos",
                    "varname": "lbl_tilt_pos"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "hidden": 1,
                    "id": "obj-56",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 20.0, 20.0, 44.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 96.0, 88.0, 44.0, 18.0 ],
                    "text": "Slope",
                    "varname": "lbl_slope"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "aberration_mod",
                    "id": "obj-60",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "lens_pix::aberration_mod",
                    "parameter_enable": 1,
                    "patching_rect": [ 100.0, 260.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 8.0, 36.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "aberration_mod",
                            "parameter_mmax": 1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "aberration_mod",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "aberration_mod"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "distortion_mod",
                    "id": "obj-61",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "lens_pix::distortion_mod",
                    "parameter_enable": 1,
                    "patching_rect": [ 200.0, 260.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 52.0, 36.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "distortion_mod",
                            "parameter_mmax": 1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "distortion_mod",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "distortion_mod"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "transmission_mod",
                    "id": "obj-62",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "lens_pix::transmission_mod",
                    "parameter_enable": 1,
                    "patching_rect": [ 300.0, 260.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 96.0, 36.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "transmission_mod",
                            "parameter_mmax": 1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "transmission_mod",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "transmission_mod"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "surface_mod",
                    "id": "obj-63",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "lens_pix::surface_mod",
                    "parameter_enable": 1,
                    "patching_rect": [ 400.0, 260.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 140.0, 36.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "surface_mod",
                            "parameter_mmax": 1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "surface_mod",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "surface_mod"
                }
            },
            {
                "box": {
                    "id": "obj-64",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 100.0, 370.0, 201.6, 22.0 ],
                    "text": "prepend param aberration_mod"
                }
            },
            {
                "box": {
                    "id": "obj-65",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 200.0, 370.0, 201.6, 22.0 ],
                    "text": "prepend param distortion_mod"
                }
            },
            {
                "box": {
                    "id": "obj-66",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 300.0, 370.0, 216.0, 22.0 ],
                    "text": "prepend param transmission_mod"
                }
            },
            {
                "box": {
                    "id": "obj-67",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 400.0, 370.0, 180.0, 22.0 ],
                    "text": "prepend param surface_mod"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-70",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 20.0, 20.0, 44.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 2.0, 20.0, 44.0, 18.0 ],
                    "text": "Aberr M",
                    "varname": "lbl_aberration_mod"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-71",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 20.0, 20.0, 44.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 48.0, 20.0, 44.0, 18.0 ],
                    "text": "Dist M",
                    "varname": "lbl_distortion_mod"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-72",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 20.0, 20.0, 44.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 92.0, 20.0, 44.0, 18.0 ],
                    "text": "Trans M",
                    "varname": "lbl_transmission_mod"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-73",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 20.0, 20.0, 44.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 135.0, 20.0, 44.0, 18.0 ],
                    "text": "Surf M",
                    "varname": "lbl_surface_mod"
                }
            },
            {
                "box": {
                    "id": "obj-80",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "bang" ],
                    "patching_rect": [ 1100.0, 50.0, 60.0, 22.0 ],
                    "text": "loadbang"
                }
            },
            {
                "box": {
                    "id": "obj-81",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 1100.0, 100.0, 180.0, 22.0 ],
                    "text": "getattr presentation_rect"
                }
            },
            {
                "box": {
                    "id": "obj-82",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "" ],
                    "patching_rect": [ 1100.0, 150.0, 79.2, 22.0 ],
                    "save": [ "#N", "thispatcher", ";", "#Q", "end", ";" ],
                    "text": "thispatcher"
                }
            },
            {
                "box": {
                    "id": "obj-83",
                    "maxclass": "newobj",
                    "numinlets": 2,
                    "numoutlets": 2,
                    "outlettype": [ "", "" ],
                    "patching_rect": [ 1100.0, 200.0, 72.0, 22.0 ],
                    "text": "zl slice 2"
                }
            },
            {
                "box": {
                    "id": "obj-84",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 1100.0, 250.0, 79.2, 22.0 ],
                    "text": "prepend tam"
                }
            },
            {
                "box": {
                    "id": "obj-85",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 1100.0, 300.0, 115.2, 22.0 ],
                    "saved_object_attributes": {
                        "filename": "moduleSize.js",
                        "parameter_enable": 0
                    },
                    "text": "js moduleSize.js"
                }
            }
        ],
        "lines": [
            {
                "patchline": {
                    "destination": [ "obj-12", 0 ],
                    "source": [ "obj-11", 2 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-14", 0 ],
                    "source": [ "obj-11", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-2", 0 ],
                    "source": [ "obj-12", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-20", 0 ],
                    "source": [ "obj-12", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-21", 0 ],
                    "source": [ "obj-12", 2 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-22", 0 ],
                    "source": [ "obj-12", 3 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-23", 0 ],
                    "source": [ "obj-12", 4 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-24", 0 ],
                    "source": [ "obj-12", 5 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-25", 0 ],
                    "source": [ "obj-12", 6 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-26", 0 ],
                    "source": [ "obj-12", 7 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-27", 0 ],
                    "source": [ "obj-12", 8 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-60", 0 ],
                    "source": [ "obj-12", 9 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-61", 0 ],
                    "source": [ "obj-12", 10 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-62", 0 ],
                    "source": [ "obj-12", 11 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-63", 0 ],
                    "source": [ "obj-12", 12 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-15", 0 ],
                    "source": [ "obj-14", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-10", 0 ],
                    "source": [ "obj-15", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-15", 0 ],
                    "source": [ "obj-16", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-18", 0 ],
                    "source": [ "obj-17", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-14", 0 ],
                    "source": [ "obj-19", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-19", 0 ],
                    "source": [ "obj-2", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-30", 0 ],
                    "source": [ "obj-20", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-31", 0 ],
                    "source": [ "obj-21", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-32", 0 ],
                    "source": [ "obj-22", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-33", 0 ],
                    "source": [ "obj-23", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-16", 1 ],
                    "source": [ "obj-24", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-16", 0 ],
                    "source": [ "obj-25", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-36", 0 ],
                    "source": [ "obj-26", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-37", 0 ],
                    "source": [ "obj-27", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-14", 0 ],
                    "source": [ "obj-30", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-14", 0 ],
                    "source": [ "obj-31", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-14", 0 ],
                    "source": [ "obj-32", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-15", 0 ],
                    "source": [ "obj-33", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-15", 0 ],
                    "source": [ "obj-36", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-38", 0 ],
                    "source": [ "obj-37", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-39", 0 ],
                    "source": [ "obj-37", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-15", 0 ],
                    "source": [ "obj-38", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-15", 0 ],
                    "source": [ "obj-39", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-17", 0 ],
                    "source": [ "obj-4", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-11", 0 ],
                    "source": [ "obj-5", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-14", 1 ],
                    "source": [ "obj-6", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-64", 0 ],
                    "source": [ "obj-60", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-65", 0 ],
                    "source": [ "obj-61", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-66", 0 ],
                    "source": [ "obj-62", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-67", 0 ],
                    "source": [ "obj-63", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-14", 0 ],
                    "source": [ "obj-64", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-14", 0 ],
                    "source": [ "obj-65", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-14", 0 ],
                    "source": [ "obj-66", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-14", 0 ],
                    "source": [ "obj-67", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-14", 2 ],
                    "source": [ "obj-7", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-14", 3 ],
                    "source": [ "obj-8", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-81", 0 ],
                    "source": [ "obj-80", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-82", 0 ],
                    "source": [ "obj-81", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-83", 0 ],
                    "source": [ "obj-82", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-84", 0 ],
                    "source": [ "obj-83", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-85", 0 ],
                    "source": [ "obj-84", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-14", 4 ],
                    "source": [ "obj-9", 0 ]
                }
            }
        ],
        "parameters": {
            "obj-2": [ "bypass", "bypass", 0 ],
            "obj-20": [ "aberration", "aberration", 0 ],
            "obj-21": [ "distortion", "distortion", 0 ],
            "obj-22": [ "transmission", "transmission", 0 ],
            "obj-23": [ "tilt", "tilt", 0 ],
            "obj-24": [ "tilt_axis", "tilt_axis", 0 ],
            "obj-25": [ "tilt_pos", "tilt_pos", 0 ],
            "obj-26": [ "slope", "slope", 0 ],
            "obj-27": [ "mode", "mode", 0 ],
            "obj-4": [ "panel_toggle", "panel_toggle", 0 ],
            "obj-60": [ "aberration_mod", "aberration_mod", 0 ],
            "obj-61": [ "distortion_mod", "distortion_mod", 0 ],
            "obj-62": [ "transmission_mod", "transmission_mod", 0 ],
            "obj-63": [ "surface_mod", "surface_mod", 0 ],
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