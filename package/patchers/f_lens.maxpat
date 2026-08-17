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
        "rect": [ 100.0, 100.0, 1441.0, 875.0 ],
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
                    "outlettype": [ "" ],
                    "patching_rect": [ 30.0, 30.0, 30.0, 30.0 ]
                }
            },
            {
                "box": {
                    "comment": "composite",
                    "id": "obj-2",
                    "index": 0,
                    "maxclass": "outlet",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 30.0, 500.0, 30.0, 30.0 ]
                }
            },
            {
                "box": {
                    "id": "obj-3",
                    "maxclass": "newobj",
                    "numinlets": 3,
                    "numoutlets": 3,
                    "outlettype": [ "", "", "" ],
                    "patching_rect": [ 200.0, 90.0, 215.0, 22.0 ],
                    "text": "routepass jit_gl_texture jit_matrix"
                }
            },
            {
                "box": {
                    "id": "obj-4",
                    "maxclass": "newobj",
                    "numinlets": 13,
                    "numoutlets": 13,
                    "outlettype": [ "", "", "", "", "", "", "", "", "", "", "", "", "" ],
                    "patching_rect": [ 311.0, 6.0, 888.0, 22.0 ],
                    "text": "route aberration distortion transmission aberration_mod distortion_mod transmission_mod surface_mod ghost ghost_count ghost_spacing halation halation_threshold"
                }
            },
            {
                "box": {
                    "id": "obj-5",
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
                                    "id": "gen-obj-10",
                                    "maxclass": "newobj",
                                    "numinlets": 0,
                                    "numoutlets": 1,
                                    "outlettype": [ "" ],
                                    "patching_rect": [ 80.0, 30.0, 28.0, 22.0 ],
                                    "text": "in 2"
                                }
                            },
                            {
                                "box": {
                                    "id": "gen-obj-11",
                                    "maxclass": "newobj",
                                    "numinlets": 0,
                                    "numoutlets": 1,
                                    "outlettype": [ "" ],
                                    "patching_rect": [ 138.0, 30.0, 28.0, 22.0 ],
                                    "text": "in 3"
                                }
                            },
                            {
                                "box": {
                                    "id": "gen-obj-12",
                                    "maxclass": "newobj",
                                    "numinlets": 0,
                                    "numoutlets": 1,
                                    "outlettype": [ "" ],
                                    "patching_rect": [ 196.0, 30.0, 28.0, 22.0 ],
                                    "text": "in 4"
                                }
                            },
                            {
                                "box": {
                                    "id": "gen-obj-13",
                                    "maxclass": "newobj",
                                    "numinlets": 0,
                                    "numoutlets": 1,
                                    "outlettype": [ "" ],
                                    "patching_rect": [ 254.0, 30.0, 28.0, 22.0 ],
                                    "text": "in 5"
                                }
                            },
                            {
                                "box": {
                                    "code": "Param aberration(0.0);\nParam distortion(0.0);\nParam transmission(0.0);\nParam aberration_mod(0.0);\nParam distortion_mod(0.0);\nParam transmission_mod(0.0);\nParam surface_mod(0.0);\nParam ghost(0.0);\nParam ghost_count(3.0);\nParam ghost_spacing(0.3);\nParam bypass(0.0);\n\nuv = norm;\ncx = uv.x - 0.5;\ncy = uv.y - 0.5;\ndist = length(vec(cx, cy));\n\naberr_tex = sample(in2, uv).x;\ndist_tex  = sample(in3, uv).x;\ntrans_tex = sample(in4, uv).x;\neps    = 0.002;\nsurf_c = sample(in5, uv).x;\nsurf_r = sample(in5, vec(uv.x + eps, uv.y)).x;\nsurf_u = sample(in5, vec(uv.x, uv.y + eps)).x;\n\nk = distortion;\nk = k * (1.0 + dist_tex * distortion_mod);\nr2 = cx*cx + cy*cy;\nwarp_cx = cx * (1.0 + k*r2);\nwarp_cy = cy * (1.0 + k*r2);\nwarp_uv = vec(0.5 + warp_cx, 0.5 + warp_cy);\n\nsurf_dx = (surf_r - surf_c) * surface_mod;\nsurf_dy = (surf_u - surf_c) * surface_mod;\nwarp_uv = vec(warp_uv.x + surf_dx, warp_uv.y + surf_dy);\nwarp_cx = warp_uv.x - 0.5;\nwarp_cy = warp_uv.y - 0.5;\n\nab = aberration * dist * (1.0 + aberr_tex * aberration_mod);\nr_uv = vec(0.5 + warp_cx * (1.0 + ab), 0.5 + warp_cy * (1.0 + ab));\nb_uv = vec(0.5 + warp_cx * (1.0 - ab), 0.5 + warp_cy * (1.0 - ab));\nr_val = sample(in1, r_uv).x;\ng_val = sample(in1, warp_uv).y;\nb_val = sample(in1, b_uv).z;\neffect_out = vec(r_val, g_val, b_val, 1.0);\n\ndist_v = dist * (1.0 + trans_tex * transmission_mod);\nvignette = 1.0 - smoothstep(0.3, 0.7, dist_v);\nwarm_shift = vec(1.05, 1.0, 0.92, 1.0);\neffect_out = mix(effect_out * warm_shift * vignette, effect_out, 1.0 - transmission);\n\ngc = floor(ghost_count + 0.5);\ngate2 = step(2.0, gc);\ngate3 = step(3.0, gc);\ngate4 = step(4.0, gc);\n\natten1 = 1.0;\natten2 = 0.6 * gate2;\natten3 = 0.36 * gate3;\natten4 = 0.22 * gate4;\nw_sum = atten1 + atten2 + atten3 + atten4;\n\nos1 = 1.0 + ghost_spacing;\nos2 = 1.0 + ghost_spacing*2.0;\nos3 = 1.0 + ghost_spacing*3.0;\nos4 = 1.0 + ghost_spacing*4.0;\n\ng1_r_uv = vec(0.5 + warp_cx*os1*(1.0+ab), 0.5 + warp_cy*os1*(1.0+ab));\ng1_g_uv = vec(0.5 + warp_cx*os1,          0.5 + warp_cy*os1);\ng1_b_uv = vec(0.5 + warp_cx*os1*(1.0-ab), 0.5 + warp_cy*os1*(1.0-ab));\n\ng2_r_uv = vec(0.5 + warp_cx*os2*(1.0+ab), 0.5 + warp_cy*os2*(1.0+ab));\ng2_g_uv = vec(0.5 + warp_cx*os2,          0.5 + warp_cy*os2);\ng2_b_uv = vec(0.5 + warp_cx*os2*(1.0-ab), 0.5 + warp_cy*os2*(1.0-ab));\n\ng3_r_uv = vec(0.5 + warp_cx*os3*(1.0+ab), 0.5 + warp_cy*os3*(1.0+ab));\ng3_g_uv = vec(0.5 + warp_cx*os3,          0.5 + warp_cy*os3);\ng3_b_uv = vec(0.5 + warp_cx*os3*(1.0-ab), 0.5 + warp_cy*os3*(1.0-ab));\n\ng4_r_uv = vec(0.5 + warp_cx*os4*(1.0+ab), 0.5 + warp_cy*os4*(1.0+ab));\ng4_g_uv = vec(0.5 + warp_cx*os4,          0.5 + warp_cy*os4);\ng4_b_uv = vec(0.5 + warp_cx*os4*(1.0-ab), 0.5 + warp_cy*os4*(1.0-ab));\n\nghost_r = (sample(in1, g1_r_uv).x*atten1 + sample(in1, g2_r_uv).x*atten2 + sample(in1, g3_r_uv).x*atten3 + sample(in1, g4_r_uv).x*atten4) / w_sum;\nghost_g = (sample(in1, g1_g_uv).y*atten1 + sample(in1, g2_g_uv).y*atten2 + sample(in1, g3_g_uv).y*atten3 + sample(in1, g4_g_uv).y*atten4) / w_sum;\nghost_b = (sample(in1, g1_b_uv).z*atten1 + sample(in1, g2_b_uv).z*atten2 + sample(in1, g3_b_uv).z*atten3 + sample(in1, g4_b_uv).z*atten4) / w_sum;\n\nghost_vec = vec(ghost_r, ghost_g, ghost_b, 0.0);\neffect_out = effect_out + ghost_vec * ghost;\n\nout1 = mix(effect_out, sample(in1, uv), bypass);\n",
                                    "fontface": 0,
                                    "fontname": "<Monospaced>",
                                    "fontsize": 12.0,
                                    "id": "gen-obj-2",
                                    "maxclass": "codebox",
                                    "numinlets": 5,
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
                                    "destination": [ "gen-obj-2", 1 ],
                                    "source": [ "gen-obj-10", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "gen-obj-2", 2 ],
                                    "source": [ "gen-obj-11", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "gen-obj-2", 3 ],
                                    "source": [ "gen-obj-12", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "gen-obj-2", 4 ],
                                    "source": [ "gen-obj-13", 0 ]
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
                    "patching_rect": [ 200.0, 380.0, 244.0, 22.0 ],
                    "text": "jit.gl.pix vsynth @name lens_pix @type char",
                    "varname": "lens_pix"
                }
            },
            {
                "box": {
                    "id": "obj-6",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 4,
                    "outlettype": [ "", "", "", "" ],
                    "patching_rect": [ 500.0, 500.0, 56.0, 22.0 ],
                    "restore": {
                        "aberration": [ 0.0 ],
                        "aberration_mod": [ 0.0 ],
                        "bypass": [ 0 ],
                        "distortion": [ 0.0 ],
                        "distortion_mod": [ 0.0 ],
                        "ghost": [ 0.0 ],
                        "ghost_count": [ 3.0 ],
                        "ghost_spacing": [ 0.3 ],
                        "halation": [ 0.0 ],
                        "halation_threshold": [ 0.7 ],
                        "live.menu": [ 0.0 ],
                        "live.menu[1]": [ 0.0 ],
                        "live.menu[2]": [ 0.0 ],
                        "live.menu[3]": [ 0.0 ],
                        "panel_toggle": [ 0.0 ],
                        "surface_mod": [ 0.0 ],
                        "transmission": [ 0.0 ],
                        "transmission_mod": [ 0.0 ]
                    },
                    "text": "autopattr",
                    "varname": "lens_autopattr"
                }
            },
            {
                "box": {
                    "angle": 270.0,
                    "background": 1,
                    "bgcolor": [ 0.0, 0.0, 0.0, 1.0 ],
                    "border": 1,
                    "bordercolor": [ 0.0, 0.03529411765, 0.2274509804, 1.0 ],
                    "id": "obj-9",
                    "maxclass": "panel",
                    "mode": 0,
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 20.0, 20.0, 227.0, 164.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 0.0, 0.0, 231.0, 156.0 ],
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
                    "patching_rect": [ 20.0, 20.0, 80.0, 21.0 ],
                    "presentation": 1,
                    "presentation_rect": [ -1.5, 0.0, 80.0, 21.0 ],
                    "text": "Lens"
                }
            },
            {
                "box": {
                    "id": "obj-11",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "bang" ],
                    "patching_rect": [ 600.0, 50.0, 60.0, 22.0 ],
                    "text": "loadbang"
                }
            },
            {
                "box": {
                    "id": "obj-12",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 600.0, 80.0, 180.0, 22.0 ],
                    "text": "getattr presentation_rect"
                }
            },
            {
                "box": {
                    "id": "obj-13",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "" ],
                    "patching_rect": [ 600.0, 110.0, 80.0, 22.0 ],
                    "save": [ "#N", "thispatcher", ";", "#Q", "end", ";" ],
                    "text": "thispatcher"
                }
            },
            {
                "box": {
                    "id": "obj-14",
                    "maxclass": "newobj",
                    "numinlets": 2,
                    "numoutlets": 2,
                    "outlettype": [ "", "" ],
                    "patching_rect": [ 600.0, 140.0, 60.0, 22.0 ],
                    "text": "zl slice 2"
                }
            },
            {
                "box": {
                    "id": "obj-15",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 600.0, 170.0, 80.0, 22.0 ],
                    "text": "prepend tam"
                }
            },
            {
                "box": {
                    "id": "obj-16",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 600.0, 200.0, 100.0, 22.0 ],
                    "saved_object_attributes": {
                        "filename": "moduleSize.js",
                        "parameter_enable": 0
                    },
                    "text": "js moduleSize.js"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "id": "obj-19d",
                    "maxclass": "live.text",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "" ],
                    "parameter_enable": 1,
                    "patching_rect": [ 700.0, 30.0, 36.0, 14.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 169.0, 3.125, 36.0, 15.75 ],
                    "rounded": 4.0,
                    "saved_attribute_attributes": {
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
                    "id": "obj-19e",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 700.0, 62.0, 130.0, 22.0 ],
                    "saved_object_attributes": {
                        "filename": "lens_toggle.js",
                        "parameter_enable": 0
                    },
                    "text": "js lens_toggle.js"
                }
            },
            {
                "box": {
                    "comment": "aberration mod",
                    "id": "obj-100",
                    "index": 0,
                    "maxclass": "inlet",
                    "numinlets": 0,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 90.0, 30.0, 30.0, 30.0 ]
                }
            },
            {
                "box": {
                    "id": "obj-101",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "" ],
                    "patching_rect": [ 90.0, 80.0, 80.0, 22.0 ],
                    "text": "vs_inState"
                }
            },
            {
                "box": {
                    "comment": "distortion mod",
                    "id": "obj-103",
                    "index": 0,
                    "maxclass": "inlet",
                    "numinlets": 0,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 150.0, 30.0, 30.0, 30.0 ]
                }
            },
            {
                "box": {
                    "id": "obj-104",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "" ],
                    "patching_rect": [ 150.0, 80.0, 80.0, 22.0 ],
                    "text": "vs_inState"
                }
            },
            {
                "box": {
                    "comment": "transmission mod",
                    "id": "obj-106",
                    "index": 0,
                    "maxclass": "inlet",
                    "numinlets": 0,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 210.0, 30.0, 30.0, 30.0 ]
                }
            },
            {
                "box": {
                    "id": "obj-107",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "" ],
                    "patching_rect": [ 210.0, 80.0, 80.0, 22.0 ],
                    "text": "vs_inState"
                }
            },
            {
                "box": {
                    "comment": "surface mod",
                    "id": "obj-109",
                    "index": 0,
                    "maxclass": "inlet",
                    "numinlets": 0,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 270.0, 30.0, 30.0, 30.0 ]
                }
            },
            {
                "box": {
                    "id": "obj-110",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "" ],
                    "patching_rect": [ 270.0, 80.0, 80.0, 22.0 ],
                    "text": "vs_inState"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "Chromatic aberration -- RGB channel separation scaled by radius. Negative flips lead/lag side.",
                    "id": "obj-20",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "lens_pix::aberration",
                    "parameter_enable": 1,
                    "patching_rect": [ 50.0, 80.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 4.0, 38.0, 27.0, 43.0 ],
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
                            "parameter_mmin": -1.0,
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
                    "attr": "aberration",
                    "id": "obj-21",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 50.0, 170.0, 150.0, 22.0 ]
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
                    "patching_rect": [ 50.0, 130.0, 50.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ -7.5, 20.0, 50.0, 18.0 ],
                    "text": "Aberr",
                    "textjustification": 1,
                    "varname": "lbl_aberration"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.0,
                    "id": "obj-300",
                    "maxclass": "live.menu",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "outlettype": [ "", "", "float" ],
                    "parameter_enable": 1,
                    "patching_rect": [ 480.0, 203.5, 100.0, 15.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 26.5, 21.5, 16.0, 15.0 ],
                    "saved_attribute_attributes": {
                        "valueof": {
                            "parameter_enum": [ "-1.0..1.0", "-2.0..2.0", "-10.0..10.0" ],
                            "parameter_longname": "range_aberration",
                            "parameter_mmax": 2,
                            "parameter_modmode": 0,
                            "parameter_shortname": "range_aberration",
                            "parameter_type": 2
                        }
                    },
                    "varname": "live.menu"
                }
            },
            {
                "box": {
                    "id": "obj-301",
                    "maxclass": "newobj",
                    "numinlets": 4,
                    "numoutlets": 4,
                    "outlettype": [ "bang", "bang", "bang", "" ],
                    "patching_rect": [ 500.0, 240.0, 60.0, 22.0 ],
                    "text": "sel 0 1 2"
                }
            },
            {
                "box": {
                    "id": "obj-302",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 500.0, 280.0, 138.0, 22.0 ],
                    "text": "_parameter_range -1. 1."
                }
            },
            {
                "box": {
                    "id": "obj-303",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 650.0, 310.0, 138.0, 22.0 ],
                    "text": "_parameter_range -2. 2."
                }
            },
            {
                "box": {
                    "id": "obj-304",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 800.0, 340.0, 151.0, 22.0 ],
                    "text": "_parameter_range -10. 10."
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "Barrel/pincushion distortion -- 0=none, negative=barrel, positive=pincushion.",
                    "id": "obj-23",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "lens_pix::distortion",
                    "parameter_enable": 1,
                    "patching_rect": [ 100.0, 80.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 41.0, 38.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "distortion",
                            "parameter_mmax": 1.0,
                            "parameter_mmin": -1.0,
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
                    "attr": "distortion",
                    "id": "obj-24",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 100.0, 200.0, 150.0, 22.0 ]
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
                    "patching_rect": [ 100.0, 130.0, 50.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 29.5, 20.0, 50.0, 18.0 ],
                    "text": "Distort",
                    "textjustification": 1,
                    "varname": "lbl_distortion"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.0,
                    "id": "obj-310",
                    "maxclass": "live.menu",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "outlettype": [ "", "", "float" ],
                    "parameter_enable": 1,
                    "patching_rect": [ 620.0, 200.0, 100.0, 15.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 63.5, 21.5, 16.0, 15.0 ],
                    "saved_attribute_attributes": {
                        "valueof": {
                            "parameter_enum": [ "-1.0..1.0", "-5.0..5.0" ],
                            "parameter_longname": "range_distortion",
                            "parameter_mmax": 1,
                            "parameter_modmode": 0,
                            "parameter_shortname": "range_distortion",
                            "parameter_type": 2
                        }
                    },
                    "varname": "live.menu[1]"
                }
            },
            {
                "box": {
                    "id": "obj-311",
                    "maxclass": "newobj",
                    "numinlets": 3,
                    "numoutlets": 3,
                    "outlettype": [ "bang", "bang", "" ],
                    "patching_rect": [ 620.0, 240.0, 60.0, 22.0 ],
                    "text": "sel 0 1"
                }
            },
            {
                "box": {
                    "id": "obj-312",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 620.0, 280.0, 138.0, 22.0 ],
                    "text": "_parameter_range -1. 1."
                }
            },
            {
                "box": {
                    "id": "obj-313",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 770.0, 310.0, 138.0, 22.0 ],
                    "text": "_parameter_range -5. 5."
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "Vignette / transmission falloff -- warm-shifted toward edges. Negative overshoots into reverse-vignette (brighter edges).",
                    "id": "obj-26",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "lens_pix::transmission",
                    "parameter_enable": 1,
                    "patching_rect": [ 150.0, 80.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 148.0, 100.0, 27.0, 43.0 ],
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
                            "parameter_mmin": -1.0,
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
                    "attr": "transmission",
                    "id": "obj-27",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 150.0, 230.0, 164.0, 22.0 ]
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-28",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 150.0, 130.0, 50.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 136.0, 82.0, 50.0, 18.0 ],
                    "text": "Trans",
                    "textjustification": 1,
                    "varname": "lbl_transmission"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.0,
                    "id": "obj-320",
                    "maxclass": "live.menu",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "outlettype": [ "", "", "float" ],
                    "parameter_enable": 1,
                    "patching_rect": [ 740.0, 200.0, 100.0, 15.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 191.0, 82.0, 16.0, 15.0 ],
                    "saved_attribute_attributes": {
                        "valueof": {
                            "parameter_enum": [ "-1.0..1.0", "-2.0..2.0" ],
                            "parameter_longname": "range_transmission",
                            "parameter_mmax": 1,
                            "parameter_modmode": 0,
                            "parameter_shortname": "range_transmission",
                            "parameter_type": 2
                        }
                    },
                    "varname": "live.menu[2]"
                }
            },
            {
                "box": {
                    "id": "obj-321",
                    "maxclass": "newobj",
                    "numinlets": 3,
                    "numoutlets": 3,
                    "outlettype": [ "bang", "bang", "" ],
                    "patching_rect": [ 890.0, 226.0, 60.0, 22.0 ],
                    "text": "sel 0 1"
                }
            },
            {
                "box": {
                    "id": "obj-322",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 770.0, 250.0, 138.0, 22.0 ],
                    "text": "_parameter_range -1. 1."
                }
            },
            {
                "box": {
                    "id": "obj-323",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 910.5, 275.0, 138.0, 22.0 ],
                    "text": "_parameter_range -2. 2."
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hidden": 1,
                    "hint": "Aberration modulation depth (inlet 2 texture)",
                    "id": "obj-29",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "lens_pix::aberration_mod",
                    "parameter_enable": 1,
                    "patching_rect": [ 200.0, 80.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 115.0, 38.0, 27.0, 43.0 ],
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
                    "attr": "aberration_mod",
                    "id": "obj-30",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 200.0, 260.0, 178.0, 22.0 ]
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "hidden": 1,
                    "id": "obj-31",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 200.0, 130.0, 53.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 103.5, 20.0, 53.0, 18.0 ],
                    "text": "Aberr Mod",
                    "textjustification": 1,
                    "varname": "lbl_aberration_mod"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hidden": 1,
                    "hint": "Distortion modulation depth (inlet 3 texture)",
                    "id": "obj-32",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "lens_pix::distortion_mod",
                    "parameter_enable": 1,
                    "patching_rect": [ 250.0, 80.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 152.0, 38.0, 27.0, 43.0 ],
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
                    "attr": "distortion_mod",
                    "id": "obj-33",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 250.0, 290.0, 178.0, 22.0 ]
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "hidden": 1,
                    "id": "obj-34",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 250.0, 130.0, 50.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 152.0, 20.0, 50.0, 18.0 ],
                    "text": "Dist Mod",
                    "textjustification": 1,
                    "varname": "lbl_distortion_mod"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hidden": 1,
                    "hint": "Transmission modulation depth (inlet 4 texture)",
                    "id": "obj-35",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "lens_pix::transmission_mod",
                    "parameter_enable": 1,
                    "patching_rect": [ 300.0, 80.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 4.0, 100.0, 27.0, 43.0 ],
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
                    "attr": "transmission_mod",
                    "id": "obj-36",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 300.0, 320.0, 192.0, 22.0 ]
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "hidden": 1,
                    "id": "obj-37",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 300.0, 130.0, 52.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 0.0, 82.0, 52.0, 18.0 ],
                    "text": "Trans Mod",
                    "textjustification": 1,
                    "varname": "lbl_transmission_mod"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hidden": 1,
                    "hint": "Surface emboss displacement depth (inlet 5 gradient texture)",
                    "id": "obj-38",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "lens_pix::surface_mod",
                    "parameter_enable": 1,
                    "patching_rect": [ 350.0, 80.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 41.0, 100.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "surface_mod",
                            "parameter_mmax": 5.0,
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
                    "attr": "surface_mod",
                    "id": "obj-39",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 350.0, 350.0, 157.0, 22.0 ]
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "hidden": 1,
                    "id": "obj-40",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 350.0, 130.0, 50.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 33.0, 82.0, 50.0, 18.0 ],
                    "text": "Surf Mod",
                    "textjustification": 1,
                    "varname": "lbl_surface_mod"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "Inter-reflection ghost intensity -- additive, color-coupled to aberration. Negative subtracts (dark ghosts).",
                    "id": "obj-41",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "lens_pix::ghost",
                    "parameter_enable": 1,
                    "patching_rect": [ 400.0, 80.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 3.0, 100.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "ghost",
                            "parameter_mmax": 1.0,
                            "parameter_mmin": -1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "ghost",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "ghost"
                }
            },
            {
                "box": {
                    "attr": "ghost",
                    "id": "obj-42",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 400.0, 380.0, 127.5, 22.0 ]
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-43",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 400.0, 130.0, 50.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ -11.0, 82.0, 50.0, 18.0 ],
                    "text": "Ghost",
                    "textjustification": 1,
                    "varname": "lbl_ghost"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "hint": "Number of ghost taps (1-4), floor()'d in codebox",
                    "id": "obj-44",
                    "maxclass": "live.numbox",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "lens_pix::ghost_count",
                    "parameter_enable": 1,
                    "patching_rect": [ 450.0, 80.0, 44.0, 15.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 93.0, 106.0, 34.0, 15.0 ],
                    "saved_attribute_attributes": {
                        "valueof": {
                            "parameter_initial": [ 3.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "ghost_count",
                            "parameter_mmax": 4.0,
                            "parameter_mmin": 1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "ghost_count",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "varname": "ghost_count"
                }
            },
            {
                "box": {
                    "attr": "ghost_count",
                    "id": "obj-45",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 450.0, 410.0, 157.0, 22.0 ]
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-46",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 450.0, 130.0, 50.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 85.0, 84.0, 50.0, 18.0 ],
                    "text": "Ghost Ct",
                    "textjustification": 1,
                    "varname": "lbl_ghost_count"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "Offset scale between ghost taps. Negative mirrors ghosts inward through center.",
                    "id": "obj-47",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "lens_pix::ghost_spacing",
                    "parameter_enable": 1,
                    "patching_rect": [ 500.0, 80.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 47.0, 100.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.3 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "ghost_spacing",
                            "parameter_mmax": 1.0,
                            "parameter_mmin": -1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "ghost_spacing",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "ghost_spacing"
                }
            },
            {
                "box": {
                    "attr": "ghost_spacing",
                    "id": "obj-48",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 500.0, 440.0, 171.0, 22.0 ]
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-49",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 500.0, 130.0, 50.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 36.0, 82.0, 50.0, 18.0 ],
                    "text": "Ghost Sp",
                    "textjustification": 1,
                    "varname": "lbl_ghost_spacing"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.0,
                    "id": "obj-390",
                    "maxclass": "live.menu",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "outlettype": [ "", "", "float" ],
                    "parameter_enable": 1,
                    "patching_rect": [ 1580.0, 200.0, 100.0, 15.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 174.5, 21.5, 16.0, 15.0 ],
                    "saved_attribute_attributes": {
                        "valueof": {
                            "parameter_enum": [ "-1.0..1.0", "-5.0..5.0" ],
                            "parameter_longname": "range_ghost_spacing",
                            "parameter_mmax": 1,
                            "parameter_modmode": 0,
                            "parameter_shortname": "range_ghost_spacing",
                            "parameter_type": 2
                        }
                    },
                    "varname": "live.menu[3]"
                }
            },
            {
                "box": {
                    "id": "obj-391",
                    "maxclass": "newobj",
                    "numinlets": 3,
                    "numoutlets": 3,
                    "outlettype": [ "bang", "bang", "" ],
                    "patching_rect": [ 1580.0, 240.0, 60.0, 22.0 ],
                    "text": "sel 0 1"
                }
            },
            {
                "box": {
                    "id": "obj-392",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 1580.0, 280.0, 138.0, 22.0 ],
                    "text": "_parameter_range -1. 1."
                }
            },
            {
                "box": {
                    "id": "obj-393",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 1730.0, 310.0, 138.0, 22.0 ],
                    "text": "_parameter_range -5. 5."
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "Halation glow intensity -- additive, warm-tinted, luma-gated. 0 = no glow.",
                    "id": "obj-50",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "lens_pix::halation",
                    "parameter_enable": 1,
                    "patching_rect": [ 550.0, 80.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 86.0, 38.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "halation",
                            "parameter_mmax": 1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "halation",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "halation"
                }
            },
            {
                "box": {
                    "attr": "halation",
                    "id": "obj-51",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 550.0, 470.0, 136.0, 22.0 ]
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-52",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 550.0, 130.0, 50.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 75.0, 20.0, 50.0, 18.0 ],
                    "text": "Halation",
                    "textjustification": 1,
                    "varname": "lbl_halation"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "Luma gate point -- regions above this bloom.",
                    "id": "obj-53",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "lens_pix::halation_threshold",
                    "parameter_enable": 1,
                    "patching_rect": [ 600.0, 80.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 123.0, 38.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.7 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "halation_threshold",
                            "parameter_mmax": 1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "halation_threshold",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "halation_threshold"
                }
            },
            {
                "box": {
                    "attr": "halation_threshold",
                    "id": "obj-54",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 600.0, 500.0, 206.0, 22.0 ]
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-55",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 600.0, 130.0, 52.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 112.0, 20.0, 52.0, 18.0 ],
                    "text": "Hal Thresh",
                    "textjustification": 1,
                    "varname": "lbl_halation_threshold"
                }
            },
            {
                "box": {
                    "filename": "bypass_toggle.js",
                    "hint": "Bypass",
                    "id": "obj-56",
                    "maxclass": "jsui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 205.0, 5.0, 18.0, 12.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 205.0, 5.0, 18.0, 12.0 ],
                    "valuepopuplabel": 1,
                    "varname": "bypass"
                }
            },
            {
                "box": {
                    "attr": "bypass",
                    "id": "obj-57",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 400.0, 60.0, 131.0, 22.0 ]
                }
            },
            {
                "box": {
                    "id": "obj-raw-17",
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
                                    "code": "Param halation(0.0);\nParam halation_threshold(0.7);\nParam bypass(0.0);\n\nuv = norm;\nsrc_r = sample(in1, uv).x;\nsrc_g = sample(in1, uv).y;\nsrc_b = sample(in1, uv).z;\nsrc_a = sample(in1, uv).w;\n\nradius1 = 0.015;\nradius2 = 0.03;\nw1 = 1.0;\nw2 = 0.5;\n\nd0x = 1.0;      d0y = 0.0;\nd1x = 0.7071;   d1y = 0.7071;\nd2x = 0.0;      d2y = 1.0;\nd3x = -0.7071;  d3y = 0.7071;\nd4x = -1.0;     d4y = 0.0;\nd5x = -0.7071;  d5y = -0.7071;\nd6x = 0.0;      d6y = -1.0;\nd7x = 0.7071;   d7y = -0.7071;\n\n// ring 1 (inner)\nuv0a = vec(uv.x + d0x*radius1, uv.y + d0y*radius1);\nuv1a = vec(uv.x + d1x*radius1, uv.y + d1y*radius1);\nuv2a = vec(uv.x + d2x*radius1, uv.y + d2y*radius1);\nuv3a = vec(uv.x + d3x*radius1, uv.y + d3y*radius1);\nuv4a = vec(uv.x + d4x*radius1, uv.y + d4y*radius1);\nuv5a = vec(uv.x + d5x*radius1, uv.y + d5y*radius1);\nuv6a = vec(uv.x + d6x*radius1, uv.y + d6y*radius1);\nuv7a = vec(uv.x + d7x*radius1, uv.y + d7y*radius1);\n\n// ring 2 (outer)\nuv0b = vec(uv.x + d0x*radius2, uv.y + d0y*radius2);\nuv1b = vec(uv.x + d1x*radius2, uv.y + d1y*radius2);\nuv2b = vec(uv.x + d2x*radius2, uv.y + d2y*radius2);\nuv3b = vec(uv.x + d3x*radius2, uv.y + d3y*radius2);\nuv4b = vec(uv.x + d4x*radius2, uv.y + d4y*radius2);\nuv5b = vec(uv.x + d5x*radius2, uv.y + d5y*radius2);\nuv6b = vec(uv.x + d6x*radius2, uv.y + d6y*radius2);\nuv7b = vec(uv.x + d7x*radius2, uv.y + d7y*radius2);\n\nr0a=sample(in1,uv0a).x; g0a=sample(in1,uv0a).y; b0a=sample(in1,uv0a).z;\nr1a=sample(in1,uv1a).x; g1a=sample(in1,uv1a).y; b1a=sample(in1,uv1a).z;\nr2a=sample(in1,uv2a).x; g2a=sample(in1,uv2a).y; b2a=sample(in1,uv2a).z;\nr3a=sample(in1,uv3a).x; g3a=sample(in1,uv3a).y; b3a=sample(in1,uv3a).z;\nr4a=sample(in1,uv4a).x; g4a=sample(in1,uv4a).y; b4a=sample(in1,uv4a).z;\nr5a=sample(in1,uv5a).x; g5a=sample(in1,uv5a).y; b5a=sample(in1,uv5a).z;\nr6a=sample(in1,uv6a).x; g6a=sample(in1,uv6a).y; b6a=sample(in1,uv6a).z;\nr7a=sample(in1,uv7a).x; g7a=sample(in1,uv7a).y; b7a=sample(in1,uv7a).z;\n\nr0b=sample(in1,uv0b).x; g0b=sample(in1,uv0b).y; b0b=sample(in1,uv0b).z;\nr1b=sample(in1,uv1b).x; g1b=sample(in1,uv1b).y; b1b=sample(in1,uv1b).z;\nr2b=sample(in1,uv2b).x; g2b=sample(in1,uv2b).y; b2b=sample(in1,uv2b).z;\nr3b=sample(in1,uv3b).x; g3b=sample(in1,uv3b).y; b3b=sample(in1,uv3b).z;\nr4b=sample(in1,uv4b).x; g4b=sample(in1,uv4b).y; b4b=sample(in1,uv4b).z;\nr5b=sample(in1,uv5b).x; g5b=sample(in1,uv5b).y; b5b=sample(in1,uv5b).z;\nr6b=sample(in1,uv6b).x; g6b=sample(in1,uv6b).y; b6b=sample(in1,uv6b).z;\nr7b=sample(in1,uv7b).x; g7b=sample(in1,uv7b).y; b7b=sample(in1,uv7b).z;\n\nlm0a = r0a*0.2126+g0a*0.7152+b0a*0.0722; lm0b = r0b*0.2126+g0b*0.7152+b0b*0.0722;\nlm1a = r1a*0.2126+g1a*0.7152+b1a*0.0722; lm1b = r1b*0.2126+g1b*0.7152+b1b*0.0722;\nlm2a = r2a*0.2126+g2a*0.7152+b2a*0.0722; lm2b = r2b*0.2126+g2b*0.7152+b2b*0.0722;\nlm3a = r3a*0.2126+g3a*0.7152+b3a*0.0722; lm3b = r3b*0.2126+g3b*0.7152+b3b*0.0722;\nlm4a = r4a*0.2126+g4a*0.7152+b4a*0.0722; lm4b = r4b*0.2126+g4b*0.7152+b4b*0.0722;\nlm5a = r5a*0.2126+g5a*0.7152+b5a*0.0722; lm5b = r5b*0.2126+g5b*0.7152+b5b*0.0722;\nlm6a = r6a*0.2126+g6a*0.7152+b6a*0.0722; lm6b = r6b*0.2126+g6b*0.7152+b6b*0.0722;\nlm7a = r7a*0.2126+g7a*0.7152+b7a*0.0722; lm7b = r7b*0.2126+g7b*0.7152+b7b*0.0722;\n\ndenom = max(1.0 - halation_threshold, 0.0001);\nbr0a = clamp((lm0a-halation_threshold)/denom, 0.0, 1.0); br0b = clamp((lm0b-halation_threshold)/denom, 0.0, 1.0);\nbr1a = clamp((lm1a-halation_threshold)/denom, 0.0, 1.0); br1b = clamp((lm1b-halation_threshold)/denom, 0.0, 1.0);\nbr2a = clamp((lm2a-halation_threshold)/denom, 0.0, 1.0); br2b = clamp((lm2b-halation_threshold)/denom, 0.0, 1.0);\nbr3a = clamp((lm3a-halation_threshold)/denom, 0.0, 1.0); br3b = clamp((lm3b-halation_threshold)/denom, 0.0, 1.0);\nbr4a = clamp((lm4a-halation_threshold)/denom, 0.0, 1.0); br4b = clamp((lm4b-halation_threshold)/denom, 0.0, 1.0);\nbr5a = clamp((lm5a-halation_threshold)/denom, 0.0, 1.0); br5b = clamp((lm5b-halation_threshold)/denom, 0.0, 1.0);\nbr6a = clamp((lm6a-halation_threshold)/denom, 0.0, 1.0); br6b = clamp((lm6b-halation_threshold)/denom, 0.0, 1.0);\nbr7a = clamp((lm7a-halation_threshold)/denom, 0.0, 1.0); br7b = clamp((lm7b-halation_threshold)/denom, 0.0, 1.0);\n\nwsum = (w1 + w2) * 8.0;\n\nglow_r = (r0a*br0a*w1 + r1a*br1a*w1 + r2a*br2a*w1 + r3a*br3a*w1 + r4a*br4a*w1 + r5a*br5a*w1 + r6a*br6a*w1 + r7a*br7a*w1\n        + r0b*br0b*w2 + r1b*br1b*w2 + r2b*br2b*w2 + r3b*br3b*w2 + r4b*br4b*w2 + r5b*br5b*w2 + r6b*br6b*w2 + r7b*br7b*w2) / wsum;\nglow_g = (g0a*br0a*w1 + g1a*br1a*w1 + g2a*br2a*w1 + g3a*br3a*w1 + g4a*br4a*w1 + g5a*br5a*w1 + g6a*br6a*w1 + g7a*br7a*w1\n        + g0b*br0b*w2 + g1b*br1b*w2 + g2b*br2b*w2 + g3b*br3b*w2 + g4b*br4b*w2 + g5b*br5b*w2 + g6b*br6b*w2 + g7b*br7b*w2) / wsum;\nglow_b = (b0a*br0a*w1 + b1a*br1a*w1 + b2a*br2a*w1 + b3a*br3a*w1 + b4a*br4a*w1 + b5a*br5a*w1 + b6a*br6a*w1 + b7a*br7a*w1\n        + b0b*br0b*w2 + b1b*br1b*w2 + b2b*br2b*w2 + b3b*br3b*w2 + b4b*br4b*w2 + b5b*br5b*w2 + b6b*br6b*w2 + b7b*br7b*w2) / wsum;\n\nwarm_r = 1.1; warm_g = 1.0; warm_b = 0.85;\n\ncomp_r = clamp(src_r + glow_r * warm_r * halation, 0.0, 1.0);\ncomp_g = clamp(src_g + glow_g * warm_g * halation, 0.0, 1.0);\ncomp_b = clamp(src_b + glow_b * warm_b * halation, 0.0, 1.0);\n\nout1 = mix(vec(comp_r, comp_g, comp_b, src_a), vec(src_r, src_g, src_b, src_a), bypass);\n",
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
                    "patching_rect": [ 200.0, 320.0, 271.0, 22.0 ],
                    "text": "jit.gl.pix vsynth @name lens_halation @type char",
                    "varname": "lens_halation"
                }
            }
        ],
        "lines": [
            {
                "patchline": {
                    "destination": [ "obj-3", 0 ],
                    "source": [ "obj-1", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-101", 0 ],
                    "source": [ "obj-100", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 1 ],
                    "source": [ "obj-101", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-104", 0 ],
                    "source": [ "obj-103", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 2 ],
                    "source": [ "obj-104", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-107", 0 ],
                    "source": [ "obj-106", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 3 ],
                    "source": [ "obj-107", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-110", 0 ],
                    "source": [ "obj-109", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-12", 0 ],
                    "source": [ "obj-11", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 4 ],
                    "source": [ "obj-110", 0 ]
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
                    "source": [ "obj-13", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-15", 0 ],
                    "source": [ "obj-14", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-16", 0 ],
                    "source": [ "obj-15", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-19e", 0 ],
                    "source": [ "obj-19d", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-13", 0 ],
                    "source": [ "obj-19e", 0 ]
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
                    "destination": [ "obj-5", 0 ],
                    "source": [ "obj-21", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-24", 0 ],
                    "source": [ "obj-23", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 0 ],
                    "source": [ "obj-24", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-27", 0 ],
                    "source": [ "obj-26", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 0 ],
                    "source": [ "obj-27", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-30", 0 ],
                    "source": [ "obj-29", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-4", 0 ],
                    "source": [ "obj-3", 2 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 0 ],
                    "source": [ "obj-3", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 0 ],
                    "source": [ "obj-30", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-301", 0 ],
                    "source": [ "obj-300", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-302", 0 ],
                    "source": [ "obj-301", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-303", 0 ],
                    "source": [ "obj-301", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-304", 0 ],
                    "source": [ "obj-301", 2 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-20", 0 ],
                    "source": [ "obj-302", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-20", 0 ],
                    "source": [ "obj-303", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-20", 0 ],
                    "source": [ "obj-304", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-311", 0 ],
                    "source": [ "obj-310", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-312", 0 ],
                    "source": [ "obj-311", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-313", 0 ],
                    "source": [ "obj-311", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-23", 0 ],
                    "source": [ "obj-312", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-23", 0 ],
                    "source": [ "obj-313", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-33", 0 ],
                    "source": [ "obj-32", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-321", 0 ],
                    "source": [ "obj-320", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-322", 0 ],
                    "source": [ "obj-321", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-323", 0 ],
                    "source": [ "obj-321", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-26", 0 ],
                    "source": [ "obj-322", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-26", 0 ],
                    "source": [ "obj-323", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 0 ],
                    "source": [ "obj-33", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-36", 0 ],
                    "source": [ "obj-35", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 0 ],
                    "source": [ "obj-36", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-39", 0 ],
                    "source": [ "obj-38", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 0 ],
                    "source": [ "obj-39", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-391", 0 ],
                    "source": [ "obj-390", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-392", 0 ],
                    "source": [ "obj-391", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-393", 0 ],
                    "source": [ "obj-391", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-47", 0 ],
                    "source": [ "obj-392", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-47", 0 ],
                    "source": [ "obj-393", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-20", 0 ],
                    "source": [ "obj-4", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-23", 0 ],
                    "source": [ "obj-4", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-26", 0 ],
                    "source": [ "obj-4", 2 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-29", 0 ],
                    "source": [ "obj-4", 3 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-32", 0 ],
                    "source": [ "obj-4", 4 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-35", 0 ],
                    "source": [ "obj-4", 5 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-38", 0 ],
                    "source": [ "obj-4", 6 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-41", 0 ],
                    "source": [ "obj-4", 7 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-44", 0 ],
                    "source": [ "obj-4", 8 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-47", 0 ],
                    "source": [ "obj-4", 9 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-50", 0 ],
                    "source": [ "obj-4", 10 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-53", 0 ],
                    "source": [ "obj-4", 11 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-42", 0 ],
                    "source": [ "obj-41", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 0 ],
                    "source": [ "obj-42", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-45", 0 ],
                    "source": [ "obj-44", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 0 ],
                    "source": [ "obj-45", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-48", 0 ],
                    "source": [ "obj-47", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 0 ],
                    "source": [ "obj-48", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-raw-17", 0 ],
                    "source": [ "obj-5", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-51", 0 ],
                    "source": [ "obj-50", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-raw-17", 0 ],
                    "source": [ "obj-51", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-54", 0 ],
                    "source": [ "obj-53", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-raw-17", 0 ],
                    "source": [ "obj-54", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-57", 0 ],
                    "source": [ "obj-56", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 0 ],
                    "source": [ "obj-57", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-2", 0 ],
                    "source": [ "obj-raw-17", 0 ]
                }
            }
        ],
        "parameters": {
            "obj-19d": [ "panel_toggle", "panel_toggle", 0 ],
            "obj-20": [ "aberration", "aberration", 0 ],
            "obj-23": [ "distortion", "distortion", 0 ],
            "obj-26": [ "transmission", "transmission", 0 ],
            "obj-29": [ "aberration_mod", "aberration_mod", 0 ],
            "obj-300": [ "range_aberration", "range_aberration", 0 ],
            "obj-310": [ "range_distortion", "range_distortion", 0 ],
            "obj-32": [ "distortion_mod", "distortion_mod", 0 ],
            "obj-320": [ "range_transmission", "range_transmission", 0 ],
            "obj-35": [ "transmission_mod", "transmission_mod", 0 ],
            "obj-38": [ "surface_mod", "surface_mod", 0 ],
            "obj-390": [ "range_ghost_spacing", "range_ghost_spacing", 0 ],
            "obj-41": [ "ghost", "ghost", 0 ],
            "obj-44": [ "ghost_count", "ghost_count", 0 ],
            "obj-47": [ "ghost_spacing", "ghost_spacing", 0 ],
            "obj-50": [ "halation", "halation", 0 ],
            "obj-53": [ "halation_threshold", "halation_threshold", 0 ],
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