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
                    "comment": "glow",
                    "id": "obj-201",
                    "index": 0,
                    "maxclass": "outlet",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 100.0, 500.0, 30.0, 30.0 ],
                    "tricolor": [ 0.6196078431372549, 0.9529411764705882, 0.6588235294117647, 1.0 ]
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
                    "numinlets": 6,
                    "numoutlets": 6,
                    "outlettype": [ "", "", "", "", "", "" ],
                    "patching_rect": [ 200.0, 130.0, 301.0, 22.0 ],
                    "text": "route radius falloff strength color_mix direction"
                }
            },
            {
                "box": {
                    "id": "obj-5",
                    "maxclass": "newobj",
                    "numinlets": 3,
                    "numoutlets": 3,
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture", "" ],
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
                                    "code": "// f_vf_glow codebox — 48-step field-aligned accumulation with jitter\n// in1 = source texture, in2 = vecfield (float32 RG, 0.5=zero), in3 = radius mod\nParam radius(0.01);\nParam falloff(0.002);\nParam strength(0.8);\nParam color_mix(0.0);\nParam direction(0.0);\nParam bypass(0.0);\nuv = norm;\n// sample source at current pixel\nsrc_r = sample(in1, uv).x;\nsrc_g = sample(in1, uv).y;\nsrc_b = sample(in1, uv).z;\nsrc_a = sample(in1, uv).w;\n// read raw vecfield — check for vs_black before remapping\nraw_x = sample(in2, uv).x;\nraw_y = sample(in2, uv).y;\nfield_suppress = step(0.02, raw_x + raw_y);\n// remap field from [0,1] to [-1,1]\nfx = (raw_x - 0.5) * 2.0 * field_suppress;\nfy = (raw_y - 0.5) * 2.0 * field_suppress;\n// radius modulation — additive, scaled by base radius\nmod_val = sample(in3, uv).x;\nradius_eff = clamp(radius + mod_val * radius, 0.0, 0.3);\n// step delta per iteration\ndx = fx * radius_eff;\ndy = fy * radius_eff;\n// direction weights (branchless)\n// dir=0 (bi): fwd=1, bwd=1 | dir=1 (fwd): fwd=1, bwd=0 | dir=2 (bwd): fwd=0, bwd=1\nfwd_weight = 1.0 - step(1.5, direction);\nbwd_weight = 1.0 - step(0.5, direction) + step(1.5, direction);\n// 48-step accumulation with per-step jitter\naccum_r = 0.0; accum_g = 0.0; accum_b = 0.0; accum_w = 0.0;\nfor (i = 1.0; i <= 48.0; i += 1.0) {\n  w = exp(-i * i * falloff);\n  jitter = fract(sin(uv.x * 127.1 + uv.y * 311.7 + i * 43.7) * 43758.5453) - 0.5;\n  stepped = i + jitter * 0.1;\n  fwd_uv = vec(clamp(uv.x + dx * stepped, 0.0, 1.0), clamp(uv.y + dy * stepped, 0.0, 1.0));\n  bwd_uv = vec(clamp(uv.x - dx * stepped, 0.0, 1.0), clamp(uv.y - dy * stepped, 0.0, 1.0));\n  accum_r = accum_r + sample(in1, fwd_uv).x * w * fwd_weight;\n  accum_g = accum_g + sample(in1, fwd_uv).y * w * fwd_weight;\n  accum_b = accum_b + sample(in1, fwd_uv).z * w * fwd_weight;\n  accum_r = accum_r + sample(in1, bwd_uv).x * w * bwd_weight;\n  accum_g = accum_g + sample(in1, bwd_uv).y * w * bwd_weight;\n  accum_b = accum_b + sample(in1, bwd_uv).z * w * bwd_weight;\n  accum_w = accum_w + w * fwd_weight + w * bwd_weight;\n}\n// normalize accumulation\nnorm_r = accum_r / max(accum_w, 0.0001);\nnorm_g = accum_g / max(accum_w, 0.0001);\nnorm_b = accum_b / max(accum_w, 0.0001);\n// color_mix: blend toward luma\nluma = norm_r * 0.2126 + norm_g * 0.7152 + norm_b * 0.0722;\nglow_r = mix(norm_r, luma, color_mix);\nglow_g = mix(norm_g, luma, color_mix);\nglow_b = mix(norm_b, luma, color_mix);\n// composite: source + glow\ncomp_r = clamp(src_r + glow_r * strength, 0.0, 1.0);\ncomp_g = clamp(src_g + glow_g * strength, 0.0, 1.0);\ncomp_b = clamp(src_b + glow_b * strength, 0.0, 1.0);\n// bypass\nout1 = mix(vec(comp_r, comp_g, comp_b, src_a), vec(src_r, src_g, src_b, src_a), bypass);\n// isolated glow outlet (zeroed on bypass)\nglow_out = mix(vec(glow_r, glow_g, glow_b, 1.0), vec(0.0, 0.0, 0.0, 1.0), bypass);\nout2 = glow_out;\n",
                                    "fontface": 0,
                                    "fontname": "<Monospaced>",
                                    "fontsize": 12.0,
                                    "id": "gen-obj-2",
                                    "maxclass": "codebox",
                                    "numinlets": 3,
                                    "numoutlets": 2,
                                    "outlettype": [ "", "" ],
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
                            },
                            {
                                "box": {
                                    "id": "gen-obj-4",
                                    "maxclass": "newobj",
                                    "numinlets": 1,
                                    "numoutlets": 0,
                                    "patching_rect": [ 82.0, 490.0, 35.0, 22.0 ],
                                    "text": "out 2"
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
                                    "destination": [ "gen-obj-3", 0 ],
                                    "source": [ "gen-obj-2", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "gen-obj-4", 0 ],
                                    "source": [ "gen-obj-2", 1 ]
                                }
                            }
                        ]
                    },
                    "patching_rect": [ 200.0, 380.0, 256.0, 22.0 ],
                    "text": "jit.gl.pix vsynth @name vfglow_pix @type char",
                    "varname": "vfglow_pix"
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
                        "bypass": [ 0 ],
                        "color_mix": [ 0.0 ],
                        "direction": [ 0.0 ],
                        "falloff": [ 0.002 ],
                        "radius": [ 0.01 ],
                        "strength": [ 0.8 ]
                    },
                    "text": "autopattr",
                    "varname": "vfglow_autopattr"
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
                    "patching_rect": [ 20.0, 20.0, 190.0, 120.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 0.0, 0.0, 190.0, 120.0 ],
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
                    "text": "Glow"
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
                    "patching_rect": [ 20.0, 20.0, 60.0, 21.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 38.0, 2.5, 60.0, 21.0 ],
                    "text": "vecfield",
                    "textcolor": [ 0.302, 0.325, 0.463, 1.0 ]
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
                    "comment": "vecfield",
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
                    "comment": "radius mod",
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
                    "id": "obj-102",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 90.0, 130.0, 160.0, 22.0 ],
                    "text": "prepend param src_vecfield"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "",
                    "id": "obj-20",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "vfglow_pix::radius",
                    "parameter_enable": 1,
                    "patching_rect": [ 50.0, 80.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 4.0, 38.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.01 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "radius",
                            "parameter_mmax": 0.2,
                            "parameter_modmode": 3,
                            "parameter_shortname": "radius",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "radius"
                }
            },
            {
                "box": {
                    "attr": "radius",
                    "id": "obj-21",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 50.0, 170.0, 127.5, 22.0 ]
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
                    "text": "Radius",
                    "textjustification": 1
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "",
                    "id": "obj-23",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "vfglow_pix::falloff",
                    "parameter_enable": 1,
                    "patching_rect": [ 100.0, 80.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 41.0, 38.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.002 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "falloff",
                            "parameter_mmax": 0.05,
                            "parameter_modmode": 3,
                            "parameter_shortname": "falloff",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "falloff"
                }
            },
            {
                "box": {
                    "attr": "falloff",
                    "id": "obj-24",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 100.0, 200.0, 129.0, 22.0 ]
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
                    "text": "Falloff",
                    "textjustification": 1
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "",
                    "id": "obj-26",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "vfglow_pix::strength",
                    "parameter_enable": 1,
                    "patching_rect": [ 150.0, 80.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 78.0, 38.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.8 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "strength",
                            "parameter_mmax": 1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "strength",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "strength"
                }
            },
            {
                "box": {
                    "attr": "strength",
                    "id": "obj-27",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 150.0, 230.0, 136.0, 22.0 ]
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
                    "presentation_rect": [ 66.5, 20.0, 50.0, 18.0 ],
                    "text": "Strength",
                    "textjustification": 1
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "",
                    "id": "obj-29",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "vfglow_pix::color_mix",
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
                            "parameter_longname": "color_mix",
                            "parameter_mmax": 1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "color_mix",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "color_mix"
                }
            },
            {
                "box": {
                    "attr": "color_mix",
                    "id": "obj-30",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 200.0, 260.0, 143.0, 22.0 ]
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-31",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 200.0, 130.0, 50.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 103.5, 20.0, 50.0, 18.0 ],
                    "text": "Color",
                    "textjustification": 1
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "hint": "",
                    "id": "obj-32",
                    "maxclass": "live.numbox",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "vfglow_pix::direction",
                    "parameter_enable": 1,
                    "patching_rect": [ 250.0, 80.0, 44.0, 15.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 152.0, 38.0, 34.0, 15.0 ],
                    "saved_attribute_attributes": {
                        "valueof": {
                            "parameter_initial": [ 0.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "direction",
                            "parameter_mmax": 2.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "direction",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "varname": "direction"
                }
            },
            {
                "box": {
                    "attr": "direction",
                    "id": "obj-33",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 250.0, 290.0, 143.0, 22.0 ]
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-34",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 250.0, 130.0, 50.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 140.5, 20.0, 50.0, 18.0 ],
                    "text": "Dir",
                    "textjustification": 1
                }
            },
            {
                "box": {
                    "filename": "bypass_toggle.js",
                    "hint": "Bypass",
                    "id": "obj-35",
                    "maxclass": "jsui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 168.0, 5.0, 18.0, 12.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 168.0, 5.0, 18.0, 12.0 ],
                    "valuepopuplabel": 1,
                    "varname": "bypass"
                }
            },
            {
                "box": {
                    "attr": "bypass",
                    "id": "obj-36",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 400.0, 60.0, 131.0, 22.0 ]
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
                    "destination": [ "obj-102", 0 ],
                    "source": [ "obj-101", 1 ]
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
                    "destination": [ "obj-5", 0 ],
                    "source": [ "obj-102", 0 ]
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
                    "destination": [ "obj-12", 0 ],
                    "source": [ "obj-11", 0 ]
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
                    "destination": [ "obj-33", 0 ],
                    "source": [ "obj-32", 0 ]
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
                    "destination": [ "obj-2", 0 ],
                    "source": [ "obj-5", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-201", 0 ],
                    "source": [ "obj-5", 1 ]
                }
            }
        ],
        "parameters": {
            "obj-20": [ "radius", "radius", 0 ],
            "obj-23": [ "falloff", "falloff", 0 ],
            "obj-26": [ "strength", "strength", 0 ],
            "obj-29": [ "color_mix", "color_mix", 0 ],
            "obj-32": [ "direction", "direction", 0 ],
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