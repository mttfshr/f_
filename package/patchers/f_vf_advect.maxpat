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
                    "comment": "texture / control",
                    "id": "obj-1",
                    "index": 0,
                    "maxclass": "inlet",
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
                    "comment": "composite",
                    "id": "obj-2",
                    "index": 0,
                    "maxclass": "outlet",
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
                    "comment": "advected",
                    "id": "obj-2b",
                    "index": 0,
                    "maxclass": "outlet",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [
                        100.0,
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
                    "numinlets": 8,
                    "numoutlets": 8,
                    "outlettype": [
                        "",
                        "",
                        "",
                        "",
                        "",
                        "",
                        "",
                        ""
                    ],
                    "patching_rect": [
                        200.0,
                        130.0,
                        280.0,
                        22.0
                    ],
                    "text": "route dt decay injection gain mix separate mode"
                }
            },
            {
                "box": {
                    "id": "obj-5",
                    "maxclass": "newobj",
                    "numinlets": 3,
                    "numoutlets": 4,
                    "outlettype": [
                        "jit_gl_texture",
                        "jit_gl_texture",
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
                                    "id": "gen-obj-2",
                                    "maxclass": "newobj",
                                    "numinlets": 0,
                                    "numoutlets": 1,
                                    "outlettype": [
                                        ""
                                    ],
                                    "patching_rect": [
                                        80.0,
                                        30.0,
                                        28.0,
                                        22.0
                                    ],
                                    "text": "in 2"
                                }
                            },
                            {
                                "box": {
                                    "id": "gen-obj-3",
                                    "maxclass": "newobj",
                                    "numinlets": 0,
                                    "numoutlets": 1,
                                    "outlettype": [
                                        ""
                                    ],
                                    "patching_rect": [
                                        138.0,
                                        30.0,
                                        28.0,
                                        22.0
                                    ],
                                    "text": "in 3"
                                }
                            },
                            {
                                "box": {
                                    "code": "Param dt(0.02);\nParam decay(0.95);\nParam injection(0.05);\nParam gain(1.0);\nParam mix_pct(100.0);\nParam bypass(0.0);\nParam src_vecfield(0.0);\n\nuv = norm;\n\n// Vecfield: sample inline (no stored variable component access)\nfx = (sample(in2, uv).x - 0.5) * 2.0;\nfy = (sample(in2, uv).y - 0.5) * 2.0;\n\n// Suppress displacement when vecfield unconnected (src_vecfield = 0)\nconnected = step(0.5, src_vecfield);\nfx = fx * connected;\nfy = fy * connected;\n\n// Backward-displaced UV, clamped to edge\nsrc_uv = vec(clamp(uv.x - fx * dt, 0.0, 1.0), clamp(uv.y - fy * dt, 0.0, 1.0));\n\n// Advect previous frame, add source injection\nadvected = sample(in3, src_uv) * decay;\nresult = clamp(advected + sample(in1, uv) * injection, 0.0, 1.0);\n\n// Wet/dry, then bypass\ndriven = clamp(result * gain, 0.0, 1.0);\nmixed = mix(sample(in1, uv), driven, mix_pct / 100.0);\nout1 = mix(mixed, sample(in1, uv), bypass);\nout2 = result;\n\n// --- 3rd outlet: gradient of accumulated flow (luma-reduced central\n// difference on the feedback texture in3, per ADR 6 / spec.md's\n// 2026-07-11 reframe -- result itself is a per-pixel value, not a\n// resamplable texture within this pass, so in3 (the previous frame's\n// accumulation, the same signal result derives from) stands in as the\n// best available proxy for \"shape of the accumulated flow\" ) ---\ngrad_scale = 0.004;\ngrad_gain  = 4.0;\n\nL_right = sample(in3, vec(uv.x + grad_scale, uv.y)).x * 0.299 + sample(in3, vec(uv.x + grad_scale, uv.y)).y * 0.587 + sample(in3, vec(uv.x + grad_scale, uv.y)).z * 0.114;\nL_left  = sample(in3, vec(uv.x - grad_scale, uv.y)).x * 0.299 + sample(in3, vec(uv.x - grad_scale, uv.y)).y * 0.587 + sample(in3, vec(uv.x - grad_scale, uv.y)).z * 0.114;\nL_down  = sample(in3, vec(uv.x, uv.y + grad_scale)).x * 0.299 + sample(in3, vec(uv.x, uv.y + grad_scale)).y * 0.587 + sample(in3, vec(uv.x, uv.y + grad_scale)).z * 0.114;\nL_up    = sample(in3, vec(uv.x, uv.y - grad_scale)).x * 0.299 + sample(in3, vec(uv.x, uv.y - grad_scale)).y * 0.587 + sample(in3, vec(uv.x, uv.y - grad_scale)).z * 0.114;\n\ngx = (L_right - L_left) * grad_gain;\ngy = (L_down  - L_up)   * grad_gain;\n\nfield   = vec(clamp(gx * 0.5 + 0.5, 0.0, 1.0), clamp(gy * 0.5 + 0.5, 0.0, 1.0), 0.5, 1.0);\n\nout3 = field;  // always live -- feedback loop keeps running during bypass, out3 shouldn't flatten\n",
                                    "fontface": 0,
                                    "fontname": "<Monospaced>",
                                    "fontsize": 12.0,
                                    "id": "gen-obj-4",
                                    "maxclass": "codebox",
                                    "numinlets": 3,
                                    "numoutlets": 3,
                                    "outlettype": [
                                        "",
                                        "",
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
                                    "id": "gen-obj-5",
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
                            },
                            {
                                "box": {
                                    "id": "gen-obj-6",
                                    "maxclass": "newobj",
                                    "numinlets": 1,
                                    "numoutlets": 0,
                                    "patching_rect": [
                                        80.0,
                                        490.0,
                                        35.0,
                                        22.0
                                    ],
                                    "text": "out 2"
                                }
                            },
                            {
                                "box": {
                                    "id": "gen-obj-7",
                                    "maxclass": "newobj",
                                    "numinlets": 1,
                                    "numoutlets": 0,
                                    "patching_rect": [
                                        142.0,
                                        490.0,
                                        35.0,
                                        22.0
                                    ],
                                    "text": "out 3"
                                }
                            }
                        ],
                        "lines": [
                            {
                                "patchline": {
                                    "destination": [
                                        "gen-obj-4",
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
                                        "gen-obj-4",
                                        1
                                    ],
                                    "source": [
                                        "gen-obj-2",
                                        0
                                    ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [
                                        "gen-obj-4",
                                        2
                                    ],
                                    "source": [
                                        "gen-obj-3",
                                        0
                                    ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [
                                        "gen-obj-5",
                                        0
                                    ],
                                    "source": [
                                        "gen-obj-4",
                                        0
                                    ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [
                                        "gen-obj-6",
                                        0
                                    ],
                                    "source": [
                                        "gen-obj-4",
                                        1
                                    ]
                                }
                            },
                            {
                                "patchline": {
                                    "source": [
                                        "gen-obj-4",
                                        2
                                    ],
                                    "destination": [
                                        "gen-obj-7",
                                        0
                                    ]
                                }
                            }
                        ]
                    },
                    "patching_rect": [
                        200.0,
                        380.0,
                        346.0,
                        22.0
                    ],
                    "text": "jit.gl.pix vsynth @name #0_advect_pix @type float32 @adapt 1",
                    "varname": "#0_advect_pix"
                }
            },
            {
                "box": {
                    "id": "obj-50",
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
                                    "code": "// codebox_advect_pass.gen \u2014 feedback-loop \"separate\" stage for f_vf_advect\n// CANDIDATE / UNVERIFIED (2026-07-07). Three modes on one intensity knob.\n// separate = 0 is EXACT identity in every mode (backward-compat invariant).\n//\n// mode: 0 = Ride  multiplicative chroma expansion; scale-invariant, so the\n//               marble lives on the decay x injection x separate surface\n//               and CAN fry to primaries.\n//       1 = Hold  attractor pulling chroma toward Thold; self-stabilizing,\n//               decoupled from loop rates, CANNOT fry.\n//       2 = Snap  quantize hue to Nsnap sectors; hard immiscible bands.\n//\n// CEILING WARNING: all three inline in one codebox is the config most\n// likely to trip the GL2->GL3 capture-group ceiling. If params gray out\n// or the pix goes invalid, CHECK THE MAX CONSOLE FIRST \u2014 the fix is to\n// move Snap to its own pix stage, not to debug the math.\n\nParam separate(0.0);\nParam mode(0.0);\n\nThold = 0.7;   // Hold target chroma magnitude   (bake-to-expose candidate)\nNsnap = 6.0;   // Snap hue sector count           (bake-to-expose candidate)\n\nuv = norm;\nc  = sample(in1, uv);\n\n// luma (Rec.709) + per-channel chroma deviation\nl  = c.x * 0.2126 + c.y * 0.7152 + c.z * 0.0722;\ndx = c.x - l;\ndy = c.y - l;\ndz = c.z - l;\n\n// --- mode 0: Ride ------------------------------------------------------\nsride  = 1.0 + separate;\nride_r = l + dx * sride;\nride_g = l + dy * sride;\nride_b = l + dz * sride;\n\n// --- mode 1: Hold ------------------------------------------------------\ncmag   = sqrt(dx*dx + dy*dy + dz*dz);\nhscale = mix(1.0, Thold / max(cmag, 0.0001), separate);\nhscale = clamp(hscale, 0.0, 4.0);\nhold_r = l + dx * hscale;\nhold_g = l + dy * hscale;\nhold_b = l + dz * hscale;\n\n// --- mode 2: Snap ------------------------------------------------------\ncmag2, cang = cartopol(dx, dz);               // (Cr,Cb) -> magnitude, angle\nsa     = 6.28318530718 / Nsnap;\nqang   = floor(cang / sa + 0.5) * sa;         // nearest hue sector\ntdx    = mix(dx, cmag2 * cos(qang), separate);\ntdz    = mix(dz, cmag2 * sin(qang), separate);\nsnap_r = l + tdx;\nsnap_b = l + tdz;\nsnap_g = (l - 0.2126 * snap_r - 0.0722 * snap_b) / 0.7152;  // luma-locked\n\n// --- branchless mode select --------------------------------------------\nm1 = step(0.5, mode);\nm2 = step(1.5, mode);\nw0 = 1.0 - m1;\nw1 = m1 - m2;\nw2 = m2;\n\nout_r = ride_r*w0 + hold_r*w1 + snap_r*w2;\nout_g = ride_g*w0 + hold_g*w1 + snap_g*w2;\nout_b = ride_b*w0 + hold_b*w1 + snap_b*w2;\n\nout1 = vec(\n\tclamp(out_r, 0.0, 1.0),\n\tclamp(out_g, 0.0, 1.0),\n\tclamp(out_b, 0.0, 1.0),\n\tc.w\n);\n",
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
                        440.0,
                        356.0,
                        22.0
                    ],
                    "text": "jit.gl.pix vsynth @name #0_advect_pass @type float32 @adapt 1",
                    "varname": "#0_advect_pass"
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
                    "restore": {
                        "bypass": [
                            0
                        ],
                        "decay": [
                            0.97
                        ],
                        "dt": [
                            0.01
                        ],
                        "injection": [
                            0.02
                        ],
                        "mix_amt": [
                            1.0
                        ],
                        "mode": [
                            0.0
                        ],
                        "separate": [
                            0.0
                        ]
                    },
                    "text": "autopattr",
                    "varname": "vfadvect_autopattr"
                }
            },
            {
                "box": {
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
                    "id": "obj-9",
                    "maxclass": "panel",
                    "mode": 0,
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [
                        20.0,
                        20.0,
                        190.0,
                        150.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        0.0,
                        0.0,
                        190.0,
                        150.0
                    ],
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
                    "text": "Advect"
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
                    "patching_rect": [
                        20.0,
                        20.0,
                        60.0,
                        18.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        41.2,
                        2.5,
                        60.0,
                        18.0
                    ],
                    "text": "vecfield in",
                    "textcolor": [
                        0.35,
                        0.75,
                        0.95,
                        1.0
                    ]
                }
            },
            {
                "box": {
                    "comment": "vecfield",
                    "id": "obj-51",
                    "index": 0,
                    "maxclass": "inlet",
                    "numinlets": 0,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "patching_rect": [
                        90.0,
                        30.0,
                        30.0,
                        30.0
                    ]
                }
            },
            {
                "box": {
                    "id": "obj-52",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [
                        "",
                        ""
                    ],
                    "patching_rect": [
                        90.0,
                        80.0,
                        80.0,
                        22.0
                    ],
                    "text": "vs_inState"
                }
            },
            {
                "box": {
                    "id": "obj-53",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "patching_rect": [
                        90.0,
                        130.0,
                        180.0,
                        22.0
                    ],
                    "text": "prepend param src_vecfield"
                }
            },
            {
                "box": {
                    "id": "obj-11",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [
                        "bang"
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
                    "numoutlets": 2,
                    "outlettype": [
                        "",
                        ""
                    ],
                    "patching_rect": [
                        600.0,
                        110.0,
                        80.0,
                        22.0
                    ],
                    "save": [
                        "#N",
                        "thispatcher",
                        ";",
                        "#Q",
                        "end",
                        ";"
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
                    "activedialcolor": [
                        0.8,
                        0.8,
                        0.8,
                        1.0
                    ],
                    "fontname": "Ableton Sans Light",
                    "id": "obj-20",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [
                        "",
                        "float"
                    ],
                    "param_connect": "#0_advect_pix::dt",
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
                                0.01
                            ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "dt",
                            "parameter_mmax": 0.05,
                            "parameter_modmode": 3,
                            "parameter_shortname": "dt",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "dt"
                }
            },
            {
                "box": {
                    "attr": "dt",
                    "id": "obj-21",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "parameter_enable": 0,
                    "patching_rect": [
                        50.0,
                        170.0,
                        127.5,
                        22.0
                    ]
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
                    "text": "dt",
                    "textjustification": 1
                }
            },
            {
                "box": {
                    "activedialcolor": [
                        0.8,
                        0.8,
                        0.8,
                        1.0
                    ],
                    "fontname": "Ableton Sans Light",
                    "id": "obj-23",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [
                        "",
                        "float"
                    ],
                    "param_connect": "#0_advect_pix::decay",
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
                                0.97
                            ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "decay",
                            "parameter_mmax": 1.5,
                            "parameter_mmin": 0.8,
                            "parameter_modmode": 3,
                            "parameter_shortname": "decay",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "decay"
                }
            },
            {
                "box": {
                    "attr": "decay",
                    "id": "obj-24",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "parameter_enable": 0,
                    "patching_rect": [
                        100.0,
                        200.0,
                        127.5,
                        22.0
                    ]
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
                    "text": "Decay",
                    "textjustification": 1
                }
            },
            {
                "box": {
                    "activedialcolor": [
                        0.8,
                        0.8,
                        0.8,
                        1.0
                    ],
                    "fontname": "Ableton Sans Light",
                    "id": "obj-26",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [
                        "",
                        "float"
                    ],
                    "param_connect": "#0_advect_pix::injection",
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
                                0.02
                            ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "injection",
                            "parameter_mmax": 0.2,
                            "parameter_modmode": 3,
                            "parameter_shortname": "injection",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "injection"
                }
            },
            {
                "box": {
                    "attr": "injection",
                    "id": "obj-27",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "parameter_enable": 0,
                    "patching_rect": [
                        150.0,
                        230.0,
                        143.0,
                        22.0
                    ]
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
                    "text": "Inject",
                    "textjustification": 1
                }
            },
            {
                "box": {
                    "activedialcolor": [
                        0.8,
                        0.8,
                        0.8,
                        1.0
                    ],
                    "fontname": "Ableton Sans Light",
                    "id": "obj-29",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [
                        "",
                        "float"
                    ],
                    "param_connect": "#0_advect_pix::gain",
                    "parameter_enable": 1,
                    "patching_rect": [
                        200.0,
                        80.0,
                        27.0,
                        43.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        115.0,
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
                                1.0
                            ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "gain",
                            "parameter_mmax": 4.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "gain",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1,
                            "parameter_mmin": 0.0
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
                    "attr": "gain",
                    "id": "obj-30",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "parameter_enable": 0,
                    "patching_rect": [
                        200.0,
                        260.0,
                        129.0,
                        22.0
                    ]
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
                    "text": "Gain",
                    "textjustification": 1
                }
            },
            {
                "box": {
                    "activedialcolor": [
                        0.8,
                        0.8,
                        0.8,
                        1.0
                    ],
                    "fontname": "Ableton Sans Light",
                    "id": "obj-32",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [
                        "",
                        "float"
                    ],
                    "param_connect": "#0_advect_pass::separate",
                    "parameter_enable": 1,
                    "patching_rect": [
                        300.0,
                        80.0,
                        27.0,
                        43.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        4.0,
                        100.0,
                        27.0,
                        43.0
                    ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [
                                0.0
                            ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "separate",
                            "parameter_mmax": 2.0,
                            "parameter_mmin": -2.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "separate",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "separate"
                }
            },
            {
                "box": {
                    "attr": "separate",
                    "id": "obj-33",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "parameter_enable": 0,
                    "patching_rect": [
                        300.0,
                        290.0,
                        136.0,
                        22.0
                    ]
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
                    "patching_rect": [
                        300.0,
                        130.0,
                        50.0,
                        18.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        -7.5,
                        82.0,
                        50.0,
                        18.0
                    ],
                    "text": "Separate",
                    "textjustification": 1
                }
            },
            {
                "box": {
                    "id": "obj-35",
                    "maxclass": "live.menu",
                    "fontname": "Ableton Sans Light",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "outlettype": [
                        "",
                        "",
                        "float"
                    ],
                    "param_connect": "#0_advect_pass::mode",
                    "parameter_enable": 1,
                    "patching_rect": [
                        350.0,
                        80.0,
                        60.0,
                        15.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        37.0,
                        114.0,
                        45.0,
                        15.0
                    ],
                    "saved_attribute_attributes": {
                        "valueof": {
                            "parameter_enum": [
                                "Ride",
                                "Hold",
                                "Snap"
                            ],
                            "parameter_longname": "mode",
                            "parameter_shortname": "mode",
                            "parameter_mmax": 2.0,
                            "parameter_mmin": 0.0,
                            "parameter_initial": [
                                0.0
                            ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_modmode": 0,
                            "parameter_type": 2,
                            "parameter_unitstyle": 0
                        }
                    },
                    "varname": "mode"
                }
            },
            {
                "box": {
                    "attr": "mode",
                    "id": "obj-36",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "parameter_enable": 0,
                    "patching_rect": [
                        350.0,
                        320.0,
                        127.5,
                        22.0
                    ]
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-37",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [
                        350.0,
                        130.0,
                        50.0,
                        18.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        29.5,
                        82.0,
                        50.0,
                        18.0
                    ],
                    "text": "Mode",
                    "textjustification": 1
                }
            },
            {
                "box": {
                    "filename": "bypass_toggle.js",
                    "hint": "Bypass",
                    "id": "obj-38",
                    "maxclass": "jsui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "parameter_enable": 0,
                    "patching_rect": [
                        168.0,
                        5.0,
                        18.0,
                        12.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        168.0,
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
                    "attr": "bypass",
                    "id": "obj-39",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "parameter_enable": 0,
                    "patching_rect": [
                        400.0,
                        60.0,
                        131.0,
                        22.0
                    ]
                }
            },
            {
                "box": {
                    "id": "obj-90",
                    "maxclass": "live.numbox",
                    "fontname": "Ableton Sans Light",
                    "hint": "Wet/dry crossfade -- 0=source only, 100=fully advected",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [
                        "",
                        "float"
                    ],
                    "param_connect": "#0_advect_pix::mix_pct",
                    "parameter_enable": 1,
                    "patching_rect": [
                        250.0,
                        80.0,
                        44.0,
                        15.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        152.0,
                        38.0,
                        34.0,
                        15.0
                    ],
                    "saved_attribute_attributes": {
                        "valueof": {
                            "parameter_longname": "mix_pct",
                            "parameter_shortname": "mix_pct",
                            "parameter_mmin": 0.0,
                            "parameter_mmax": 100.0,
                            "parameter_initial": [
                                100.0
                            ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_modmode": 3,
                            "parameter_type": 0,
                            "parameter_unitstyle": 0
                        }
                    },
                    "varname": "mix_pct"
                }
            },
            {
                "box": {
                    "id": "obj-91",
                    "maxclass": "attrui",
                    "attr": "mix_pct",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "parameter_enable": 0,
                    "patching_rect": [
                        250.0,
                        260.0,
                        129.0,
                        22.0
                    ]
                }
            },
            {
                "box": {
                    "id": "obj-92",
                    "maxclass": "comment",
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [
                        250.0,
                        130.0,
                        50.0,
                        18.0
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        140.5,
                        20.0,
                        50.0,
                        18.0
                    ],
                    "text": "Mix",
                    "textjustification": 1
                }
            },
            {
                "box": {
                    "comment": "vecfield",
                    "id": "obj-2c",
                    "index": 2,
                    "maxclass": "outlet",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [
                        170.0,
                        500.0,
                        30.0,
                        30.0
                    ]
                }
            }
        ],
        "lines": [
            {
                "patchline": {
                    "destination": [
                        "obj-3",
                        0
                    ],
                    "source": [
                        "obj-1",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-12",
                        0
                    ],
                    "source": [
                        "obj-11",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-13",
                        0
                    ],
                    "source": [
                        "obj-12",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-14",
                        0
                    ],
                    "source": [
                        "obj-13",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-15",
                        0
                    ],
                    "source": [
                        "obj-14",
                        1
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-16",
                        0
                    ],
                    "source": [
                        "obj-15",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-21",
                        0
                    ],
                    "source": [
                        "obj-20",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-5",
                        0
                    ],
                    "source": [
                        "obj-21",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-24",
                        0
                    ],
                    "source": [
                        "obj-23",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-5",
                        0
                    ],
                    "source": [
                        "obj-24",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-27",
                        0
                    ],
                    "source": [
                        "obj-26",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-5",
                        0
                    ],
                    "source": [
                        "obj-27",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-30",
                        0
                    ],
                    "source": [
                        "obj-29",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-4",
                        0
                    ],
                    "source": [
                        "obj-3",
                        2
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-5",
                        0
                    ],
                    "source": [
                        "obj-3",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-5",
                        0
                    ],
                    "source": [
                        "obj-30",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-33",
                        0
                    ],
                    "source": [
                        "obj-32",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-50",
                        0
                    ],
                    "source": [
                        "obj-33",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-36",
                        0
                    ],
                    "source": [
                        "obj-35",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-50",
                        0
                    ],
                    "source": [
                        "obj-36",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-39",
                        0
                    ],
                    "source": [
                        "obj-38",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-5",
                        0
                    ],
                    "source": [
                        "obj-39",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-20",
                        0
                    ],
                    "source": [
                        "obj-4",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-23",
                        0
                    ],
                    "source": [
                        "obj-4",
                        1
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-26",
                        0
                    ],
                    "source": [
                        "obj-4",
                        2
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-29",
                        0
                    ],
                    "source": [
                        "obj-4",
                        3
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-32",
                        0
                    ],
                    "source": [
                        "obj-4",
                        5
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-35",
                        0
                    ],
                    "source": [
                        "obj-4",
                        6
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-2",
                        0
                    ],
                    "order": 1,
                    "source": [
                        "obj-5",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-2b",
                        0
                    ],
                    "source": [
                        "obj-5",
                        1
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-50",
                        0
                    ],
                    "order": 0,
                    "source": [
                        "obj-5",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-5",
                        2
                    ],
                    "source": [
                        "obj-50",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-52",
                        0
                    ],
                    "source": [
                        "obj-51",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-5",
                        1
                    ],
                    "source": [
                        "obj-52",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-53",
                        0
                    ],
                    "source": [
                        "obj-52",
                        1
                    ]
                }
            },
            {
                "patchline": {
                    "destination": [
                        "obj-5",
                        0
                    ],
                    "source": [
                        "obj-53",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-4",
                        4
                    ],
                    "destination": [
                        "obj-90",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-90",
                        0
                    ],
                    "destination": [
                        "obj-91",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-91",
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
                        "obj-5",
                        2
                    ],
                    "destination": [
                        "obj-2c",
                        0
                    ]
                }
            }
        ],
        "parameters": {
            "obj-20": [
                "dt",
                "dt",
                0
            ],
            "obj-23": [
                "decay",
                "decay",
                0
            ],
            "obj-26": [
                "injection",
                "injection",
                0
            ],
            "obj-29": [
                "mix_amt",
                "mix_amt",
                0
            ],
            "obj-32": [
                "separate",
                "separate",
                0
            ],
            "obj-35": [
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