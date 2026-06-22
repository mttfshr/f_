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
            100.0,
            100.0,
            800.0,
            600.0
        ],
        "openinpresentation": 1,
        "boxes": [
            {
                "box": {
                    "id": "obj-1",
                    "maxclass": "inlet",
                    "comment": "texture / control",
                    "index": 0,
                    "numinlets": 0,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "patching_rect": [
                        30.0,
                        30.0,
                        30.0,
                        30.0
                    ]
                }
            },
            {
                "box": {
                    "id": "obj-2",
                    "maxclass": "outlet",
                    "comment": "vecfield",
                    "index": 0,
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [
                        30.0,
                        500.0,
                        30.0,
                        30.0
                    ]
                }
            },
            {
                "box": {
                    "id": "obj-3",
                    "maxclass": "newobj",
                    "numinlets": 3,
                    "numoutlets": 3,
                    "outlettype": [
                        "",
                        "",
                        ""
                    ],
                    "patching_rect": [
                        200.0,
                        90.0,
                        215.0,
                        22.0
                    ],
                    "text": "routepass jit_gl_texture jit_matrix"
                }
            },
            {
                "box": {
                    "id": "obj-4",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 4,
                    "outlettype": [
                        "",
                        "",
                        "",
                        ""
                    ],
                    "patching_rect": [
                        200.0,
                        130.0,
                        203.0,
                        22.0
                    ],
                    "text": "route gain reach threshold mode"
                }
            },
            {
                "box": {
                    "id": "obj-5",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [
                        "jit_gl_texture",
                        ""
                    ],
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
                        "rect": [
                            100.0,
                            100.0,
                            700.0,
                            600.0
                        ],
                        "boxes": [
                            {
                                "box": {
                                    "id": "gen-obj-1",
                                    "maxclass": "newobj",
                                    "numinlets": 0,
                                    "numoutlets": 1,
                                    "outlettype": [
                                        ""
                                    ],
                                    "patching_rect": [
                                        22.0,
                                        30.0,
                                        28.0,
                                        22.0
                                    ],
                                    "text": "in 1"
                                }
                            },
                            {
                                "box": {
                                    "code": "Param gain(4.0);\nParam reach(0.1);\nParam threshold(0.3);\nParam mode(0.0);\nParam bypass(0.0);\n\n// Remap norm into [reach, 1-reach] so ring samples never go OOB\n// This zooms the sampled region to fill the full output texture\nzu = norm.x * (1.0 - 2.0 * reach) + reach;\nzv = norm.y * (1.0 - 2.0 * reach) + reach;\n\n// Precomputed unit vectors \u2014 16 evenly spaced directions\ndx0  =  1.0000; dy0  =  0.0000;\ndx1  =  0.9239; dy1  =  0.3827;\ndx2  =  0.7071; dy2  =  0.7071;\ndx3  =  0.3827; dy3  =  0.9239;\ndx4  =  0.0000; dy4  =  1.0000;\ndx5  = -0.3827; dy5  =  0.9239;\ndx6  = -0.7071; dy6  =  0.7071;\ndx7  = -0.9239; dy7  =  0.3827;\ndx8  = -1.0000; dy8  =  0.0000;\ndx9  = -0.9239; dy9  = -0.3827;\ndx10 = -0.7071; dy10 = -0.7071;\ndx11 = -0.3827; dy11 = -0.9239;\ndx12 =  0.0000; dy12 = -1.0000;\ndx13 =  0.3827; dy13 = -0.9239;\ndx14 =  0.7071; dy14 = -0.7071;\ndx15 =  0.9239; dy15 = -0.3827;\n\n// Sample luma at each ring position (Rec. 601)\n// Named UVs for OOB gate \u2014 clear semantics, no clamp artifact at edges\nsu0  = zu + dx0  * reach; sv0  = zv + dy0  * reach;\nsu1  = zu + dx1  * reach; sv1  = zv + dy1  * reach;\nsu2  = zu + dx2  * reach; sv2  = zv + dy2  * reach;\nsu3  = zu + dx3  * reach; sv3  = zv + dy3  * reach;\nsu4  = zu + dx4  * reach; sv4  = zv + dy4  * reach;\nsu5  = zu + dx5  * reach; sv5  = zv + dy5  * reach;\nsu6  = zu + dx6  * reach; sv6  = zv + dy6  * reach;\nsu7  = zu + dx7  * reach; sv7  = zv + dy7  * reach;\nsu8  = zu + dx8  * reach; sv8  = zv + dy8  * reach;\nsu9  = zu + dx9  * reach; sv9  = zv + dy9  * reach;\nsu10 = zu + dx10 * reach; sv10 = zv + dy10 * reach;\nsu11 = zu + dx11 * reach; sv11 = zv + dy11 * reach;\nsu12 = zu + dx12 * reach; sv12 = zv + dy12 * reach;\nsu13 = zu + dx13 * reach; sv13 = zv + dy13 * reach;\nsu14 = zu + dx14 * reach; sv14 = zv + dy14 * reach;\nsu15 = zu + dx15 * reach; sv15 = zv + dy15 * reach;\n\nluma0  = sample(in1, vec(su0,  sv0 )).x * 0.299 + sample(in1, vec(su0,  sv0 )).y * 0.587 + sample(in1, vec(su0,  sv0 )).z * 0.114;\nluma1  = sample(in1, vec(su1,  sv1 )).x * 0.299 + sample(in1, vec(su1,  sv1 )).y * 0.587 + sample(in1, vec(su1,  sv1 )).z * 0.114;\nluma2  = sample(in1, vec(su2,  sv2 )).x * 0.299 + sample(in1, vec(su2,  sv2 )).y * 0.587 + sample(in1, vec(su2,  sv2 )).z * 0.114;\nluma3  = sample(in1, vec(su3,  sv3 )).x * 0.299 + sample(in1, vec(su3,  sv3 )).y * 0.587 + sample(in1, vec(su3,  sv3 )).z * 0.114;\nluma4  = sample(in1, vec(su4,  sv4 )).x * 0.299 + sample(in1, vec(su4,  sv4 )).y * 0.587 + sample(in1, vec(su4,  sv4 )).z * 0.114;\nluma5  = sample(in1, vec(su5,  sv5 )).x * 0.299 + sample(in1, vec(su5,  sv5 )).y * 0.587 + sample(in1, vec(su5,  sv5 )).z * 0.114;\nluma6  = sample(in1, vec(su6,  sv6 )).x * 0.299 + sample(in1, vec(su6,  sv6 )).y * 0.587 + sample(in1, vec(su6,  sv6 )).z * 0.114;\nluma7  = sample(in1, vec(su7,  sv7 )).x * 0.299 + sample(in1, vec(su7,  sv7 )).y * 0.587 + sample(in1, vec(su7,  sv7 )).z * 0.114;\nluma8  = sample(in1, vec(su8,  sv8 )).x * 0.299 + sample(in1, vec(su8,  sv8 )).y * 0.587 + sample(in1, vec(su8,  sv8 )).z * 0.114;\nluma9  = sample(in1, vec(su9,  sv9 )).x * 0.299 + sample(in1, vec(su9,  sv9 )).y * 0.587 + sample(in1, vec(su9,  sv9 )).z * 0.114;\nluma10 = sample(in1, vec(su10, sv10)).x * 0.299 + sample(in1, vec(su10, sv10)).y * 0.587 + sample(in1, vec(su10, sv10)).z * 0.114;\nluma11 = sample(in1, vec(su11, sv11)).x * 0.299 + sample(in1, vec(su11, sv11)).y * 0.587 + sample(in1, vec(su11, sv11)).z * 0.114;\nluma12 = sample(in1, vec(su12, sv12)).x * 0.299 + sample(in1, vec(su12, sv12)).y * 0.587 + sample(in1, vec(su12, sv12)).z * 0.114;\nluma13 = sample(in1, vec(su13, sv13)).x * 0.299 + sample(in1, vec(su13, sv13)).y * 0.587 + sample(in1, vec(su13, sv13)).z * 0.114;\nluma14 = sample(in1, vec(su14, sv14)).x * 0.299 + sample(in1, vec(su14, sv14)).y * 0.587 + sample(in1, vec(su14, sv14)).z * 0.114;\nluma15 = sample(in1, vec(su15, sv15)).x * 0.299 + sample(in1, vec(su15, sv15)).y * 0.587 + sample(in1, vec(su15, sv15)).z * 0.114;\n\n// Thresholded weights with OOB gate (clear: out-of-frame positions contribute zero)\nw0  = max(luma0  - threshold, 0.0) * step(0., su0 ) * step(su0,  1.) * step(0., sv0 ) * step(sv0,  1.);\nw1  = max(luma1  - threshold, 0.0) * step(0., su1 ) * step(su1,  1.) * step(0., sv1 ) * step(sv1,  1.);\nw2  = max(luma2  - threshold, 0.0) * step(0., su2 ) * step(su2,  1.) * step(0., sv2 ) * step(sv2,  1.);\nw3  = max(luma3  - threshold, 0.0) * step(0., su3 ) * step(su3,  1.) * step(0., sv3 ) * step(sv3,  1.);\nw4  = max(luma4  - threshold, 0.0) * step(0., su4 ) * step(su4,  1.) * step(0., sv4 ) * step(sv4,  1.);\nw5  = max(luma5  - threshold, 0.0) * step(0., su5 ) * step(su5,  1.) * step(0., sv5 ) * step(sv5,  1.);\nw6  = max(luma6  - threshold, 0.0) * step(0., su6 ) * step(su6,  1.) * step(0., sv6 ) * step(sv6,  1.);\nw7  = max(luma7  - threshold, 0.0) * step(0., su7 ) * step(su7,  1.) * step(0., sv7 ) * step(sv7,  1.);\nw8  = max(luma8  - threshold, 0.0) * step(0., su8 ) * step(su8,  1.) * step(0., sv8 ) * step(sv8,  1.);\nw9  = max(luma9  - threshold, 0.0) * step(0., su9 ) * step(su9,  1.) * step(0., sv9 ) * step(sv9,  1.);\nw10 = max(luma10 - threshold, 0.0) * step(0., su10) * step(su10, 1.) * step(0., sv10) * step(sv10, 1.);\nw11 = max(luma11 - threshold, 0.0) * step(0., su11) * step(su11, 1.) * step(0., sv11) * step(sv11, 1.);\nw12 = max(luma12 - threshold, 0.0) * step(0., su12) * step(su12, 1.) * step(0., sv12) * step(sv12, 1.);\nw13 = max(luma13 - threshold, 0.0) * step(0., su13) * step(su13, 1.) * step(0., sv13) * step(sv13, 1.);\nw14 = max(luma14 - threshold, 0.0) * step(0., su14) * step(su14, 1.) * step(0., sv14) * step(sv14, 1.);\nw15 = max(luma15 - threshold, 0.0) * step(0., su15) * step(su15, 1.) * step(0., sv15) * step(sv15, 1.);\n\nfx = 0.0;\nfy = 0.0;\n\nmode_i = floor(mode);\n\nif (mode_i < 0.5) {\n    // Mode 0: Cancel \u2014 straight accumulation, opposing vectors neutralize\n    fx = -dx0*w0 + -dx1*w1 + -dx2*w2 + -dx3*w3 + -dx4*w4 + -dx5*w5 + -dx6*w6 + -dx7*w7 + -dx8*w8 + -dx9*w9 + -dx10*w10 + -dx11*w11 + -dx12*w12 + -dx13*w13 + -dx14*w14 + -dx15*w15;\n    fy = -dy0*w0 + -dy1*w1 + -dy2*w2 + -dy3*w3 + -dy4*w4 + -dy5*w5 + -dy6*w6 + -dy7*w7 + -dy8*w8 + -dy9*w9 + -dy10*w10 + -dy11*w11 + -dy12*w12 + -dy13*w13 + -dy14*w14 + -dy15*w15;\n\n} else if (mode_i < 1.5) {\n    // Mode 1: Max \u2014 strongest single sample wins, no cancellation\n    bx = 0.0; by = 0.0; bw = 0.0;\n    t = step(bw, w0);  bx = mix(bx, -dx0,  t); by = mix(by, -dy0,  t); bw = mix(bw, w0,  t);\n    t = step(bw, w1);  bx = mix(bx, -dx1,  t); by = mix(by, -dy1,  t); bw = mix(bw, w1,  t);\n    t = step(bw, w2);  bx = mix(bx, -dx2,  t); by = mix(by, -dy2,  t); bw = mix(bw, w2,  t);\n    t = step(bw, w3);  bx = mix(bx, -dx3,  t); by = mix(by, -dy3,  t); bw = mix(bw, w3,  t);\n    t = step(bw, w4);  bx = mix(bx, -dx4,  t); by = mix(by, -dy4,  t); bw = mix(bw, w4,  t);\n    t = step(bw, w5);  bx = mix(bx, -dx5,  t); by = mix(by, -dy5,  t); bw = mix(bw, w5,  t);\n    t = step(bw, w6);  bx = mix(bx, -dx6,  t); by = mix(by, -dy6,  t); bw = mix(bw, w6,  t);\n    t = step(bw, w7);  bx = mix(bx, -dx7,  t); by = mix(by, -dy7,  t); bw = mix(bw, w7,  t);\n    t = step(bw, w8);  bx = mix(bx, -dx8,  t); by = mix(by, -dy8,  t); bw = mix(bw, w8,  t);\n    t = step(bw, w9);  bx = mix(bx, -dx9,  t); by = mix(by, -dy9,  t); bw = mix(bw, w9,  t);\n    t = step(bw, w10); bx = mix(bx, -dx10, t); by = mix(by, -dy10, t); bw = mix(bw, w10, t);\n    t = step(bw, w11); bx = mix(bx, -dx11, t); by = mix(by, -dy11, t); bw = mix(bw, w11, t);\n    t = step(bw, w12); bx = mix(bx, -dx12, t); by = mix(by, -dy12, t); bw = mix(bw, w12, t);\n    t = step(bw, w13); bx = mix(bx, -dx13, t); by = mix(by, -dy13, t); bw = mix(bw, w13, t);\n    t = step(bw, w14); bx = mix(bx, -dx14, t); by = mix(by, -dy14, t); bw = mix(bw, w14, t);\n    t = step(bw, w15); bx = mix(bx, -dx15, t); by = mix(by, -dy15, t); bw = mix(bw, w15, t);\n    fx = bx * bw;\n    fy = by * bw;\n\n} else if (mode_i < 2.5) {\n    // Mode 2: Abs Add \u2014 accumulate magnitudes, normalize to cancel direction\n    cancel_x = -dx0*w0 + -dx1*w1 + -dx2*w2 + -dx3*w3 + -dx4*w4 + -dx5*w5 + -dx6*w6 + -dx7*w7 + -dx8*w8 + -dx9*w9 + -dx10*w10 + -dx11*w11 + -dx12*w12 + -dx13*w13 + -dx14*w14 + -dx15*w15;\n    cancel_y = -dy0*w0 + -dy1*w1 + -dy2*w2 + -dy3*w3 + -dy4*w4 + -dy5*w5 + -dy6*w6 + -dy7*w7 + -dy8*w8 + -dy9*w9 + -dy10*w10 + -dy11*w11 + -dy12*w12 + -dy13*w13 + -dy14*w14 + -dy15*w15;\n    abs_mag = w0 + w1 + w2 + w3 + w4 + w5 + w6 + w7 + w8 + w9 + w10 + w11 + w12 + w13 + w14 + w15;\n    cancel_mag = max(sqrt(max(cancel_x * cancel_x + cancel_y * cancel_y, 0.0)), 0.0001);\n    fx = (cancel_x / cancel_mag) * abs_mag;\n    fy = (cancel_y / cancel_mag) * abs_mag;\n\n} else {\n    // Mode 3: Turbulent \u2014 cancel + curl injection in cancellation zones\n    cancel_x = -dx0*w0 + -dx1*w1 + -dx2*w2 + -dx3*w3 + -dx4*w4 + -dx5*w5 + -dx6*w6 + -dx7*w7 + -dx8*w8 + -dx9*w9 + -dx10*w10 + -dx11*w11 + -dx12*w12 + -dx13*w13 + -dx14*w14 + -dx15*w15;\n    cancel_y = -dy0*w0 + -dy1*w1 + -dy2*w2 + -dy3*w3 + -dy4*w4 + -dy5*w5 + -dy6*w6 + -dy7*w7 + -dy8*w8 + -dy9*w9 + -dy10*w10 + -dy11*w11 + -dy12*w12 + -dy13*w13 + -dy14*w14 + -dy15*w15;\n    cancel_mag = sqrt(max(cancel_x * cancel_x + cancel_y * cancel_y, 0.0));\n    abs_mag = w0 + w1 + w2 + w3 + w4 + w5 + w6 + w7 + w8 + w9 + w10 + w11 + w12 + w13 + w14 + w15;\n    curl_x = -cancel_y;\n    curl_y =  cancel_x;\n    cancel_ratio = abs_mag / max(cancel_mag, 0.0001);\n    turb_amt = clamp((cancel_ratio - 1.0) * 0.2, 0.0, 1.0);\n    fx = cancel_x + curl_x * turb_amt;\n    fy = cancel_y + curl_y * turb_amt;\n}\n\nfield_x = clamp(fx * gain * 0.5 + 0.5, 0.0, 1.0);\nfield_y = clamp(fy * gain * 0.5 + 0.5, 0.0, 1.0);\n\nout1 = mix(vec(field_x, field_y, 0.5, 1.0), vec(0.5, 0.5, 0.5, 1.0), bypass);\n",
                                    "fontface": 0,
                                    "fontname": "<Monospaced>",
                                    "fontsize": 12.0,
                                    "id": "gen-obj-2",
                                    "maxclass": "codebox",
                                    "numinlets": 1,
                                    "numoutlets": 1,
                                    "outlettype": [
                                        ""
                                    ],
                                    "patching_rect": [
                                        22.0,
                                        80.0,
                                        550.0,
                                        380.0
                                    ]
                                }
                            },
                            {
                                "box": {
                                    "id": "gen-obj-3",
                                    "maxclass": "newobj",
                                    "numinlets": 1,
                                    "numoutlets": 0,
                                    "patching_rect": [
                                        22.0,
                                        490.0,
                                        35.0,
                                        22.0
                                    ],
                                    "text": "out 1"
                                }
                            }
                        ],
                        "lines": [
                            {
                                "patchline": {
                                    "destination": [
                                        "gen-obj-2",
                                        0
                                    ],
                                    "source": [
                                        "gen-obj-1",
                                        0
                                    ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [
                                        "gen-obj-3",
                                        0
                                    ],
                                    "source": [
                                        "gen-obj-2",
                                        0
                                    ]
                                }
                            }
                        ]
                    },
                    "patching_rect": [
                        200.0,
                        380.0,
                        200.0,
                        22.0
                    ],
                    "text": "jit.gl.pix vsynth @name repulse_pix @type float32",
                    "varname": "repulse_pix"
                }
            },
            {
                "box": {
                    "id": "obj-6",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 4,
                    "outlettype": [
                        "",
                        "",
                        "",
                        ""
                    ],
                    "patching_rect": [
                        500.0,
                        500.0,
                        56.0,
                        22.0
                    ],
                    "text": "autopattr",
                    "varname": "repulse_autopattr"
                }
            },
            {
                "box": {
                    "id": "obj-9",
                    "maxclass": "panel",
                    "angle": 270.0,
                    "background": 1,
                    "bgcolor": [
                        0.0,
                        0.0,
                        0.0,
                        1.0
                    ],
                    "border": 1,
                    "bordercolor": [
                        0.0,
                        0.03529411765,
                        0.2274509804,
                        1.0
                    ],
                    "mode": 0,
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [
                        20.0,
                        20.0,
                        165.0,
                        80.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        0.0,
                        0.0,
                        165.0,
                        80.0
                    ],
                    "proportion": 0.5
                }
            },
            {
                "box": {
                    "id": "obj-10",
                    "maxclass": "comment",
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [
                        20.0,
                        20.0,
                        80.0,
                        21.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        -1.5,
                        0.0,
                        80.0,
                        21.0
                    ],
                    "text": "Repulse"
                }
            },
            {
                "box": {
                    "id": "obj-8",
                    "maxclass": "comment",
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "textcolor": [
                        0.302,
                        0.325,
                        0.463,
                        1.0
                    ],
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [
                        20.0,
                        20.0,
                        60.0,
                        21.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        48.4,
                        2.5,
                        60.0,
                        18.0
                    ],
                    "text": "vecfield"
                }
            },
            {
                "box": {
                    "id": "obj-11",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "patching_rect": [
                        600.0,
                        50.0,
                        60.0,
                        22.0
                    ],
                    "text": "loadbang"
                }
            },
            {
                "box": {
                    "id": "obj-12",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "patching_rect": [
                        600.0,
                        80.0,
                        180.0,
                        22.0
                    ],
                    "text": "getattr presentation_rect"
                }
            },
            {
                "box": {
                    "id": "obj-13",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 4,
                    "outlettype": [
                        "",
                        "",
                        "",
                        ""
                    ],
                    "patching_rect": [
                        600.0,
                        110.0,
                        80.0,
                        22.0
                    ],
                    "text": "thispatcher"
                }
            },
            {
                "box": {
                    "id": "obj-14",
                    "maxclass": "newobj",
                    "numinlets": 2,
                    "numoutlets": 2,
                    "outlettype": [
                        "",
                        ""
                    ],
                    "patching_rect": [
                        600.0,
                        140.0,
                        60.0,
                        22.0
                    ],
                    "text": "zl slice 2"
                }
            },
            {
                "box": {
                    "id": "obj-15",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "patching_rect": [
                        600.0,
                        170.0,
                        80.0,
                        22.0
                    ],
                    "text": "prepend tam"
                }
            },
            {
                "box": {
                    "id": "obj-16",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "patching_rect": [
                        600.0,
                        200.0,
                        100.0,
                        22.0
                    ],
                    "saved_object_attributes": {
                        "filename": "moduleSize.js",
                        "parameter_enable": 0
                    },
                    "text": "js moduleSize.js"
                }
            },
            {
                "box": {
                    "id": "obj-20",
                    "maxclass": "live.dial",
                    "activedialcolor": [
                        0.8,
                        0.8,
                        0.8,
                        1.0
                    ],
                    "fontname": "Ableton Sans Light",
                    "hint": "Field magnitude. Negative = attraction.",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [
                        "",
                        "float"
                    ],
                    "param_connect": "repulse_pix::gain",
                    "parameter_enable": 1,
                    "patching_rect": [
                        50.0,
                        80.0,
                        27.0,
                        43.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        4.0,
                        38.0,
                        27.0,
                        43.0
                    ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [
                                4.0
                            ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "gain",
                            "parameter_mmax": 10.0,
                            "parameter_mmin": -10.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "gain",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "gain"
                }
            },
            {
                "box": {
                    "id": "obj-21",
                    "maxclass": "attrui",
                    "attr": "strength",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "patching_rect": [
                        50.0,
                        170.0,
                        136.0,
                        22.0
                    ],
                    "style": ""
                }
            },
            {
                "box": {
                    "id": "obj-22",
                    "maxclass": "comment",
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [
                        50.0,
                        130.0,
                        50.0,
                        18.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        -7.5,
                        20.0,
                        50.0,
                        18.0
                    ],
                    "text": "Strength",
                    "textjustification": 1
                }
            },
            {
                "box": {
                    "id": "obj-23",
                    "maxclass": "live.dial",
                    "activedialcolor": [
                        0.8,
                        0.8,
                        0.8,
                        1.0
                    ],
                    "fontname": "Ableton Sans Light",
                    "hint": "Ring sample radius (normalized UV). Negative samples inside shapes.",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [
                        "",
                        "float"
                    ],
                    "param_connect": "repulse_pix::reach",
                    "parameter_enable": 1,
                    "patching_rect": [
                        100.0,
                        80.0,
                        27.0,
                        43.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        41.0,
                        38.0,
                        27.0,
                        43.0
                    ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [
                                0.1
                            ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "reach",
                            "parameter_mmax": 0.5,
                            "parameter_mmin": -0.5,
                            "parameter_modmode": 3,
                            "parameter_shortname": "reach",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "reach"
                }
            },
            {
                "box": {
                    "id": "obj-24",
                    "maxclass": "attrui",
                    "attr": "reach",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "patching_rect": [
                        100.0,
                        200.0,
                        115.0,
                        22.0
                    ],
                    "style": ""
                }
            },
            {
                "box": {
                    "id": "obj-25",
                    "maxclass": "comment",
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [
                        100.0,
                        130.0,
                        50.0,
                        18.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        29.5,
                        20.0,
                        50.0,
                        18.0
                    ],
                    "text": "Reach",
                    "textjustification": 1
                }
            },
            {
                "box": {
                    "id": "obj-26",
                    "maxclass": "live.dial",
                    "activedialcolor": [
                        0.8,
                        0.8,
                        0.8,
                        1.0
                    ],
                    "fontname": "Ableton Sans Light",
                    "hint": "Luma threshold for repulsion. Negative = repulse from dark regions.",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [
                        "",
                        "float"
                    ],
                    "param_connect": "repulse_pix::threshold",
                    "parameter_enable": 1,
                    "patching_rect": [
                        150.0,
                        80.0,
                        27.0,
                        43.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        78.0,
                        38.0,
                        27.0,
                        43.0
                    ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [
                                0.3
                            ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "threshold",
                            "parameter_mmax": 1.0,
                            "parameter_mmin": -1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "threshold",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "threshold"
                }
            },
            {
                "box": {
                    "id": "obj-27",
                    "maxclass": "attrui",
                    "attr": "threshold",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "patching_rect": [
                        150.0,
                        230.0,
                        143.0,
                        22.0
                    ],
                    "style": ""
                }
            },
            {
                "box": {
                    "id": "obj-28",
                    "maxclass": "comment",
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [
                        150.0,
                        130.0,
                        50.0,
                        18.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        66.5,
                        20.0,
                        50.0,
                        18.0
                    ],
                    "text": "Thresh",
                    "textjustification": 1
                }
            },
            {
                "box": {
                    "id": "obj-29",
                    "maxclass": "live.menu",
                    "fontname": "Ableton Sans Light",
                    "hint": "Accumulation mode: Cancel, Max, Abs Add, Turbulent.",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "outlettype": [
                        "",
                        "",
                        "float"
                    ],
                    "param_connect": "repulse_pix::mode",
                    "parameter_enable": 1,
                    "patching_rect": [
                        200.0,
                        80.0,
                        60.0,
                        15.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        111.0,
                        52.0,
                        45.0,
                        15.0
                    ],
                    "saved_attribute_attributes": {
                        "valueof": {
                            "parameter_enum": [
                                "Cancel",
                                "Max",
                                "Abs Add",
                                "Turbulent"
                            ],
                            "parameter_initial": [
                                0.0
                            ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "mode",
                            "parameter_mmax": 3.0,
                            "parameter_mmin": 0.0,
                            "parameter_modmode": 0,
                            "parameter_shortname": "mode",
                            "parameter_type": 2,
                            "parameter_unitstyle": 0
                        }
                    },
                    "varname": "mode"
                }
            },
            {
                "box": {
                    "id": "obj-30",
                    "maxclass": "attrui",
                    "attr": "mode",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "patching_rect": [
                        200.0,
                        260.0,
                        108.0,
                        22.0
                    ],
                    "style": ""
                }
            },
            {
                "box": {
                    "id": "obj-31",
                    "maxclass": "comment",
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [
                        200.0,
                        130.0,
                        50.0,
                        18.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        103.5,
                        20.0,
                        50.0,
                        18.0
                    ],
                    "text": "Mode",
                    "textjustification": 1
                }
            },
            {
                "box": {
                    "id": "obj-32",
                    "maxclass": "jsui",
                    "filename": "bypass_toggle.js",
                    "hint": "Bypass",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "presentation": 1,
                    "patching_rect": [
                        143.0,
                        5.0,
                        18.0,
                        12.0
                    ],
                    "presentation_rect": [
                        143.0,
                        5.0,
                        18.0,
                        12.0
                    ],
                    "valuepopuplabel": 1,
                    "varname": "bypass"
                }
            },
            {
                "box": {
                    "id": "obj-33",
                    "maxclass": "attrui",
                    "attr": "bypass",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "patching_rect": [
                        400.0,
                        60.0,
                        131.0,
                        22.0
                    ],
                    "style": ""
                }
            }
        ],
        "lines": [
            {
                "patchline": {
                    "source": [
                        "obj-1",
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
                        "obj-3",
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
                        "obj-3",
                        2
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
                        "obj-5",
                        0
                    ],
                    "destination": [
                        "obj-2",
                        0
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
                        "obj-11",
                        0
                    ],
                    "destination": [
                        "obj-12",
                        0
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
                        0
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
                        1
                    ],
                    "destination": [
                        "obj-15",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-15",
                        0
                    ],
                    "destination": [
                        "obj-16",
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
                        "obj-20",
                        0
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
                        "obj-4",
                        1
                    ],
                    "destination": [
                        "obj-23",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-23",
                        0
                    ],
                    "destination": [
                        "obj-24",
                        0
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
                        "obj-5",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-4",
                        2
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
                        "obj-27",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-27",
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
                        "obj-4",
                        3
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
                        0
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
                        "obj-5",
                        0
                    ]
                }
            }
        ],
        "parameters": {
            "obj-20": [
                "strength",
                "strength",
                0
            ],
            "obj-23": [
                "reach",
                "reach",
                0
            ],
            "obj-26": [
                "threshold",
                "threshold",
                0
            ],
            "obj-29": [
                "mode",
                "mode",
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