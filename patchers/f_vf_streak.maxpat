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
        "rect": [ 100.0, 100.0, 435.0, 600.0 ],
        "openinpresentation": 1,
        "boxes": [
            {
                "box": {
                    "comment": "texture in",
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
                    "comment": "vecfield",
                    "id": "obj-50",
                    "index": 0,
                    "maxclass": "inlet",
                    "numinlets": 0,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 100.0, 30.0, 30.0, 30.0 ]
                }
            },
            {
                "box": {
                    "comment": "out",
                    "id": "obj-2",
                    "index": 0,
                    "maxclass": "outlet",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 30.0, 560.0, 30.0, 30.0 ],
                    "tricolor": [ 0.9529411764705882, 0.6901960784313725, 0.6196078431372549, 1.0 ]
                }
            },
            {
                "box": {
                    "comment": "streak",
                    "id": "obj-52",
                    "index": 0,
                    "maxclass": "outlet",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 100.0, 560.0, 30.0, 30.0 ],
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
                    "numinlets": 5,
                    "numoutlets": 5,
                    "outlettype": [ "", "", "", "", "" ],
                    "patching_rect": [ 200.0, 130.0, 245.0, 22.0 ],
                    "text": "route strength length falloff color_shift"
                }
            },
            {
                "box": {
                    "id": "obj-5",
                    "maxclass": "newobj",
                    "numinlets": 2,
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
                        "rect": [ 100.0, 100.0, 700.0, 700.0 ],
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
                                    "id": "gen-obj-2",
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
                                    "code": "// f_vf_streak codebox v1 — scratch validation\n// Directional blur: accumulate source texture samples along vecfield streamlines\n// in1 = source texture (char)\n// in2 = f_vecfield (float32, RG=XY, 0.5=zero vector)\n\nParam strength(0.3);\nParam length(0.15);\nParam falloff(0.0);\nParam color_shift(0.0);\nParam src_vecfield(0.0);\nParam bypass(0.0);\n\nuv = norm;\n\n// step size in UV space\nstep_size = length / 8.0;\ncs = color_shift * step_size;\n\n// suppress field when inlet unconnected — vs_black → -1.0 offset without this\nconnected = step(0.5, src_vecfield);\n\n// falloff weights — wN = mix(1.0, 1.0 - (n/7.0), falloff)\n// step 0: always 1.0 regardless of falloff\n// step 7: mix(1.0, 0.0, falloff)\nw0 = 1.0;\nw1 = mix(1.0, 1.0 - (1.0/7.0), falloff);\nw2 = mix(1.0, 1.0 - (2.0/7.0), falloff);\nw3 = mix(1.0, 1.0 - (3.0/7.0), falloff);\nw4 = mix(1.0, 1.0 - (4.0/7.0), falloff);\nw5 = mix(1.0, 1.0 - (5.0/7.0), falloff);\nw6 = mix(1.0, 1.0 - (6.0/7.0), falloff);\nw7 = mix(1.0, 0.0, falloff);\n\nw_sum = w0 + w1 + w2 + w3 + w4 + w5 + w6 + w7;\n\n// --- step 0: current pixel ---\npos0x = uv.x;\npos0y = uv.y;\n\nf0x = (sample(in2, vec(pos0x, pos0y)).x - 0.5) * 2.0 * connected;\nf0y = (sample(in2, vec(pos0x, pos0y)).y - 0.5) * 2.0 * connected;\n\nsrc0r = sample(in1, vec(pos0x + f0x * cs, pos0y)).x;\nsrc0g = sample(in1, vec(pos0x,            pos0y)).y;\nsrc0b = sample(in1, vec(pos0x - f0x * cs, pos0y)).z;\n\n// --- step 1 ---\npos1x = pos0x - f0x * step_size;\npos1y = pos0y - f0y * step_size;\n\nf1x = (sample(in2, vec(pos1x, pos1y)).x - 0.5) * 2.0 * connected;\nf1y = (sample(in2, vec(pos1x, pos1y)).y - 0.5) * 2.0 * connected;\n\nsrc1r = sample(in1, vec(pos1x + f1x * cs, pos1y)).x;\nsrc1g = sample(in1, vec(pos1x,            pos1y)).y;\nsrc1b = sample(in1, vec(pos1x - f1x * cs, pos1y)).z;\n\n// --- step 2 ---\npos2x = pos1x - f1x * step_size;\npos2y = pos1y - f1y * step_size;\n\nf2x = (sample(in2, vec(pos2x, pos2y)).x - 0.5) * 2.0 * connected;\nf2y = (sample(in2, vec(pos2x, pos2y)).y - 0.5) * 2.0 * connected;\n\nsrc2r = sample(in1, vec(pos2x + f2x * cs, pos2y)).x;\nsrc2g = sample(in1, vec(pos2x,            pos2y)).y;\nsrc2b = sample(in1, vec(pos2x - f2x * cs, pos2y)).z;\n\n// --- step 3 ---\npos3x = pos2x - f2x * step_size;\npos3y = pos2y - f2y * step_size;\n\nf3x = (sample(in2, vec(pos3x, pos3y)).x - 0.5) * 2.0 * connected;\nf3y = (sample(in2, vec(pos3x, pos3y)).y - 0.5) * 2.0 * connected;\n\nsrc3r = sample(in1, vec(pos3x + f3x * cs, pos3y)).x;\nsrc3g = sample(in1, vec(pos3x,            pos3y)).y;\nsrc3b = sample(in1, vec(pos3x - f3x * cs, pos3y)).z;\n\n// --- step 4 ---\npos4x = pos3x - f3x * step_size;\npos4y = pos3y - f3y * step_size;\n\nf4x = (sample(in2, vec(pos4x, pos4y)).x - 0.5) * 2.0 * connected;\nf4y = (sample(in2, vec(pos4x, pos4y)).y - 0.5) * 2.0 * connected;\n\nsrc4r = sample(in1, vec(pos4x + f4x * cs, pos4y)).x;\nsrc4g = sample(in1, vec(pos4x,            pos4y)).y;\nsrc4b = sample(in1, vec(pos4x - f4x * cs, pos4y)).z;\n\n// --- step 5 ---\npos5x = pos4x - f4x * step_size;\npos5y = pos4y - f4y * step_size;\n\nf5x = (sample(in2, vec(pos5x, pos5y)).x - 0.5) * 2.0 * connected;\nf5y = (sample(in2, vec(pos5x, pos5y)).y - 0.5) * 2.0 * connected;\n\nsrc5r = sample(in1, vec(pos5x + f5x * cs, pos5y)).x;\nsrc5g = sample(in1, vec(pos5x,            pos5y)).y;\nsrc5b = sample(in1, vec(pos5x - f5x * cs, pos5y)).z;\n\n// --- step 6 ---\npos6x = pos5x - f5x * step_size;\npos6y = pos5y - f5y * step_size;\n\nf6x = (sample(in2, vec(pos6x, pos6y)).x - 0.5) * 2.0 * connected;\nf6y = (sample(in2, vec(pos6x, pos6y)).y - 0.5) * 2.0 * connected;\n\nsrc6r = sample(in1, vec(pos6x + f6x * cs, pos6y)).x;\nsrc6g = sample(in1, vec(pos6x,            pos6y)).y;\nsrc6b = sample(in1, vec(pos6x - f6x * cs, pos6y)).z;\n\n// --- step 7 ---\npos7x = pos6x - f6x * step_size;\npos7y = pos6y - f6y * step_size;\n\nf7x = (sample(in2, vec(pos7x, pos7y)).x - 0.5) * 2.0 * connected;\nf7y = (sample(in2, vec(pos7x, pos7y)).y - 0.5) * 2.0 * connected;\n\nsrc7r = sample(in1, vec(pos7x + f7x * cs, pos7y)).x;\nsrc7g = sample(in1, vec(pos7x,            pos7y)).y;\nsrc7b = sample(in1, vec(pos7x - f7x * cs, pos7y)).z;\n\n// --- weighted accumulation and normalization ---\nstreak_r = (w0*src0r + w1*src1r + w2*src2r + w3*src3r + w4*src4r + w5*src5r + w6*src6r + w7*src7r) / w_sum;\nstreak_g = (w0*src0g + w1*src1g + w2*src2g + w3*src3g + w4*src4g + w5*src5g + w6*src6g + w7*src7g) / w_sum;\nstreak_b = (w0*src0b + w1*src1b + w2*src2b + w3*src3b + w4*src4b + w5*src5b + w6*src6b + w7*src7b) / w_sum;\n\nstreak_layer = vec(clamp(streak_r, 0.0, 1.0),\n                   clamp(streak_g, 0.0, 1.0),\n                   clamp(streak_b, 0.0, 1.0),\n                   1.0);\n\n// source pixel for composite and bypass\nsrc_r = sample(in1, uv).x;\nsrc_g = sample(in1, uv).y;\nsrc_b = sample(in1, uv).z;\nsrc_px = vec(src_r, src_g, src_b, 1.0);\n\n// out2: isolated streak layer — black on bypass\nout2 = mix(streak_layer, vec(0.0, 0.0, 0.0, 1.0), bypass);\n\n// out1: additive composite — streak adds light over source, scaled by strength\ncomposite = vec(clamp(src_r + streak_r * strength, 0.0, 1.0),\n                clamp(src_g + streak_g * strength, 0.0, 1.0),\n                clamp(src_b + streak_b * strength, 0.0, 1.0),\n                1.0);\nout1 = mix(composite, src_px, bypass);\n",
                                    "fontface": 0,
                                    "fontname": "<Monospaced>",
                                    "fontsize": 12.0,
                                    "id": "gen-obj-3",
                                    "maxclass": "codebox",
                                    "numinlets": 2,
                                    "numoutlets": 2,
                                    "outlettype": [ "", "" ],
                                    "patching_rect": [ 22.0, 80.0, 580.0, 540.0 ]
                                }
                            },
                            {
                                "box": {
                                    "id": "gen-obj-4",
                                    "maxclass": "newobj",
                                    "numinlets": 1,
                                    "numoutlets": 0,
                                    "patching_rect": [ 22.0, 640.0, 35.0, 22.0 ],
                                    "text": "out 1"
                                }
                            },
                            {
                                "box": {
                                    "id": "gen-obj-5",
                                    "maxclass": "newobj",
                                    "numinlets": 1,
                                    "numoutlets": 0,
                                    "patching_rect": [ 100.0, 640.0, 35.0, 22.0 ],
                                    "text": "out 2"
                                }
                            }
                        ],
                        "lines": [
                            {
                                "patchline": {
                                    "destination": [ "gen-obj-3", 0 ],
                                    "source": [ "gen-obj-1", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "gen-obj-3", 1 ],
                                    "source": [ "gen-obj-2", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "gen-obj-4", 0 ],
                                    "source": [ "gen-obj-3", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "gen-obj-5", 0 ],
                                    "source": [ "gen-obj-3", 1 ]
                                }
                            }
                        ]
                    },
                    "patching_rect": [ 200.0, 380.0, 320.0, 22.0 ],
                    "text": "jit.gl.pix vsynth @name vfstreak_pix @type char",
                    "varname": "vfstreak_pix"
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
                        "color_shift": [ 0.0 ],
                        "falloff": [ 0.0 ],
                        "length": [ 0.15 ],
                        "strength": [ 0.3 ]
                    },
                    "text": "autopattr",
                    "varname": "vfstreak_autopattr"
                }
            },
            {
                "box": {
                    "id": "obj-53",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "" ],
                    "patching_rect": [ 100.0, 80.0, 80.0, 22.0 ],
                    "text": "vs_inState"
                }
            },
            {
                "box": {
                    "id": "obj-54",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 100.0, 130.0, 175.0, 22.0 ],
                    "text": "prepend param src_vecfield"
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
                    "patching_rect": [ 20.0, 20.0, 190.0, 100.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 0.0, 0.0, 190.0, 100.0 ],
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
                    "text": "Streak"
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
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "",
                    "id": "obj-20",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "vfstreak_pix::strength",
                    "parameter_enable": 1,
                    "patching_rect": [ 50.0, 80.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 4.0, 38.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.3 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "strength",
                            "parameter_mmax": 20.0,
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
                    "id": "obj-21",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 50.0, 170.0, 140.0, 22.0 ]
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
                    "text": "Strength",
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
                    "param_connect": "vfstreak_pix::length",
                    "parameter_enable": 1,
                    "patching_rect": [ 100.0, 80.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 41.0, 38.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.15 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "length",
                            "parameter_mmax": 20.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "length",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "length"
                }
            },
            {
                "box": {
                    "attr": "length",
                    "id": "obj-24",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 100.0, 170.0, 140.0, 22.0 ]
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
                    "text": "Length",
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
                    "param_connect": "vfstreak_pix::falloff",
                    "parameter_enable": 1,
                    "patching_rect": [ 150.0, 80.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 78.0, 38.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "falloff",
                            "parameter_mmax": 2.5,
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
                    "id": "obj-27",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 150.0, 170.0, 140.0, 22.0 ]
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
                    "text": "Falloff",
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
                    "param_connect": "vfstreak_pix::color_shift",
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
                            "parameter_longname": "color_shift",
                            "parameter_mmax": 20.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "color_shift",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "color_shift"
                }
            },
            {
                "box": {
                    "attr": "color_shift",
                    "id": "obj-30",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 200.0, 170.0, 140.0, 22.0 ]
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
                    "filename": "bypass_toggle.js",
                    "hint": "Bypass",
                    "id": "obj-32",
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
                    "id": "obj-33",
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
                    "destination": [ "obj-2", 0 ],
                    "source": [ "obj-5", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-52", 0 ],
                    "source": [ "obj-5", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-53", 0 ],
                    "source": [ "obj-50", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 1 ],
                    "source": [ "obj-53", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-54", 0 ],
                    "source": [ "obj-53", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 0 ],
                    "source": [ "obj-54", 0 ]
                }
            }
        ],
        "parameters": {
            "obj-20": [ "strength", "strength", 0 ],
            "obj-23": [ "length", "length", 0 ],
            "obj-26": [ "falloff", "falloff", 0 ],
            "obj-29": [ "color_shift", "color_shift", 0 ],
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