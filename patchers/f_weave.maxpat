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
        "rect": [ 34.0, 100.0, 1039.0, 800.0 ],
        "openinpresentation": 1,
        "boxes": [
            {
                "box": {
                    "filename": "bypass_toggle.js",
                    "hint": "Bypass",
                    "id": "obj-8",
                    "maxclass": "jsui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "param_connect": "weave_pix::bypass",
                    "parameter_enable": 1,
                    "patching_rect": [ 584.333351, 46.000001, 18.0, 12.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 193.0, 3.5, 18.0, 12.0 ],
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
                    "varname": "bypass"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-2",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 20.0, 20.0, 80.0, 21.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 8.0, 5.0, 80.0, 21.0 ],
                    "text": "f_weave"
                }
            },
            {
                "box": {
                    "comment": "texture + ctrl",
                    "id": "obj-3",
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
                    "comment": "texture out",
                    "id": "obj-4",
                    "index": 0,
                    "maxclass": "outlet",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 50.0, 700.0, 30.0, 30.0 ]
                }
            },
            {
                "box": {
                    "id": "obj-5",
                    "maxclass": "newobj",
                    "numinlets": 3,
                    "numoutlets": 3,
                    "outlettype": [ "", "", "" ],
                    "patching_rect": [ 50.0, 90.0, 252.0, 22.0 ],
                    "text": "routepass jit_gl_texture jit_matrix"
                }
            },
            {
                "box": {
                    "id": "obj-5b",
                    "maxclass": "newobj",
                    "numinlets": 18,
                    "numoutlets": 18,
                    "outlettype": [ "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "" ],
                    "patching_rect": [ 50.0, 130.0, 1022.4, 22.0 ],
                    "text": "route courses bond offset angle skip quantize regularity drift phase speed_var mortar softness width roundness bypass course_color brick_color"
                }
            },
            {
                "box": {
                    "id": "obj-6",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 4,
                    "outlettype": [ "", "", "", "" ],
                    "patching_rect": [ 950.0, 50.0, 244.8, 22.0 ],
                    "restore": {
                        "angle": [ 0.0 ],
                        "bond": [ 8.0 ],
                        "brick_color": [ 0.0 ],
                        "bypass": [ 0 ],
                        "course_color": [ 0.0 ],
                        "courses": [ 8.0 ],
                        "drift": [ 0.0 ],
                        "mortar": [ 0.5 ],
                        "offset": [ 0.0 ],
                        "phase": [ 0.0 ],
                        "quantize": [ 0.0 ],
                        "regularity": [ 1.0 ],
                        "roundness": [ 0.0 ],
                        "skip": [ 1.0 ],
                        "softness": [ 0.2 ],
                        "speed_var": [ 0.0 ],
                        "width": [ 0.5 ]
                    },
                    "text": "autopattr @varname weave_autopattr",
                    "varname": "u945001373"
                }
            },
            {
                "box": {
                    "id": "obj-7",
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
                        "rect": [ 117.0, 95.0, 650.0, 950.0 ],
                        "boxes": [
                            {
                                "box": {
                                    "id": "gen-1",
                                    "maxclass": "newobj",
                                    "numinlets": 0,
                                    "numoutlets": 1,
                                    "outlettype": [ "" ],
                                    "patching_rect": [ 50.0, 14.0, 35.0, 22.0 ],
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
                                    "patching_rect": [ 130.0, 14.0, 35.0, 22.0 ],
                                    "text": "r dim"
                                }
                            },
                            {
                                "box": {
                                    "code": "// f_weave codebox — Phase 4 final\n// 2026-05-29\n// Changes from Phase 3:\n//   - Added: width (mark aspect ratio, independent of weight)\n//   - Added: roundness (rect/round blend, normalized by 1/sqrt(2))\n//   - Added: quantize (crossfade swing between slot-quantized and continuous hash)\n//   - Added: band_diverge (per-band background color, full RGB hash)\n//   - Added: mark_diverge (per-mark color, full RGB hash, tints mark from white)\n//   - Added: aspect correction via dim.x/dim.y (requires r dim → pix @dim in patcher)\n//   - mark_slot: mark identity from mark center, not pixel slot — color stays with mark\n//   - Removed: size_var, thickness_var\n//\n// Known behaviors (not bugs):\n//   - quantize>0 with swing>0: pixel noise in continuous swing hash\n//   - quantize=0 with swing>0: seam/cut artifact at slot boundaries in motion\n//   - params beyond 0-1 produce undefined behavior\n//   - band_diverge/mark_diverge above 1.0 over-saturates (expressive)\n//\n// Build script notes:\n//   - r dim → pix object needed so dim.x/dim.y is populated for aspect correction\n//   - 17 float params, all live.dial, no integer params\n//   - control inlet only (no texture inlet), use route not routepass\n\nParam angle(0.0);\nParam density(0.5);\nParam freq(0.5);\nParam offset(0.0);\nParam weight(0.5);\nParam softness(0.2);\nParam regularity(1.0);\nParam swing(0.0);\nParam phase(0.0);\nParam speed_var(0.0);\nParam continuity(1.0);\nParam bypass(0.0);\nParam width(0.5);\nParam roundness(0.0);\nParam quantize(0.0);\nParam band_diverge(0.0);\nParam mark_diverge(0.0);\n\ntheta  = angle * PI;\ncosT   = cos(theta);\nsinT   = sin(theta);\n\naspect = dim.x / dim.y;\npx     = norm.x * aspect;\npy     = norm.y;\nalong  =  px * cosT + py * sinT;\nacross = -px * sinT + py * cosT;\n\ndensity_scale = pow(2.0, mix(1.0, 6.0, density));\nfreq_scale    = pow(2.0, mix(1.0, 6.0, freq));\nband_idx      = floor(across * density_scale);\n\n// per-band speed hash\nh3         = band_idx * 419.2;\nh3         = sin(h3) * 43758.5;\nband_hash  = h3 - floor(h3);\nband_speed = 1.0 + (band_hash - 0.5) * speed_var * 2.0;\nband_phase = phase * band_speed;\n\nslot       = floor(along * freq_scale + band_idx * offset);\nalong_cont = along * freq_scale + band_idx * offset;\n\n// presence hash — always slot-quantized (continuous hash produces pixel noise)\nh1        = slot * 127.1 + band_idx * 311.7;\nh1        = sin(h1) * 43758.5;\nslot_hash = h1 - floor(h1);\n\n// swing hash — slot-quantized\nh2      = slot * 269.5 + band_idx * 183.3;\nh2      = sin(h2) * 43758.5;\nswing_q = (h2 - floor(h2) - 0.5) * swing;\n\n// swing hash — continuous (quantize=1: fluid drift, quantize=0: slot seams)\nh2c     = along_cont * 269.5 + band_idx * 183.3;\nh2c     = sin(h2c) * 43758.5;\nswing_c = (h2c - floor(h2c) - 0.5) * swing;\n\nswing_offset = mix(swing_q, swing_c, quantize);\n\nalong_phase = wrap(along_cont + swing_offset + band_phase, 0.0, 1.0);\n\n// regular mark distance\nmark_dist_reg = abs(along_phase - 0.5) * 2.0;\n\n// random mark distance\nmark_dist_rnd = mix(along_phase, 1.0 - along_phase, step(0.5, slot_hash));\nmark_dist_rnd = mark_dist_rnd * 2.0;\n\n// blend\nmark_dist = mix(mark_dist_rnd, mark_dist_reg, regularity);\n\n// continuity — per-band hash gate\nh4        = band_idx * 591.3;\nh4        = sin(h4) * 43758.5;\nband_cont = h4 - floor(h4);\ncont      = step(1.0 - continuity, band_cont);\n\n// across-band distance, scaled by width for aspect ratio control\nacross_phase = wrap(across * density_scale, 0.0, 1.0);\nacross_dist  = abs(across_phase - 0.5) * 2.0;\nacross_d     = across_dist / max(width, 0.01);\n\n// along distance\nalong_d = mark_dist;\n\n// rect/round blend — normalized so mark size is consistent across roundness sweep\nrect_dist  = max(along_d, across_d);\nround_dist = sqrt(along_d * along_d + across_d * across_d) * 0.7071;\nfinal_dist = mix(rect_dist, round_dist, roundness);\n\n// mark identity — from mark center, not pixel slot, so color tracks the mark\nmark_center = along_cont + swing_offset + band_phase - along_phase + 0.5;\nmark_slot   = floor(mark_center);\n\n// per-band color — full RGB hash [0,1]\nband_col_r = (sin(band_idx * 127.1) * 43758.5453 - floor(sin(band_idx * 127.1) * 43758.5453));\nband_col_g = (sin(band_idx * 91.3)  * 43758.5453 - floor(sin(band_idx * 91.3)  * 43758.5453));\nband_col_b = (sin(band_idx * 43.1)  * 43758.5453 - floor(sin(band_idx * 43.1)  * 43758.5453));\n\n// per-mark color — full RGB hash [0,1], seeded from mark_slot + band_idx\nmark_col_r = (sin(mark_slot * 127.1 + band_idx * 311.7) * 43758.5453 - floor(sin(mark_slot * 127.1 + band_idx * 311.7) * 43758.5453));\nmark_col_g = (sin(mark_slot * 57.2  + band_idx * 91.3)  * 43758.5453 - floor(sin(mark_slot * 57.2  + band_idx * 91.3)  * 43758.5453));\nmark_col_b = (sin(mark_slot * 123.7 + band_idx * 43.1)  * 43758.5453 - floor(sin(mark_slot * 123.7 + band_idx * 43.1)  * 43758.5453));\n\nmark_size = 1.0 - weight;\nmark_out  = smoothstep(mark_size + softness, mark_size - softness, final_dist) * cont;\n\n// marks: tint from white toward random color via mark_diverge\nmark_r = mark_out * mix(1.0, mark_col_r, mark_diverge);\nmark_g = mark_out * mix(1.0, mark_col_g, mark_diverge);\nmark_b = mark_out * mix(1.0, mark_col_b, mark_diverge);\n\n// band backgrounds: black toward random band color via band_diverge\nbg_r = mix(0.0, band_col_r, band_diverge);\nbg_g = mix(0.0, band_col_g, band_diverge);\nbg_b = mix(0.0, band_col_b, band_diverge);\n\n// composite: background in gaps, marks on top\nout_r = mix(bg_r, mark_r, mark_out);\nout_g = mix(bg_g, mark_g, mark_out);\nout_b = mix(bg_b, mark_b, mark_out);\n\nout1 = mix(vec(out_r, out_g, out_b, 1.0), vec(0.0, 0.0, 0.0, 0.0), bypass);\n\n// --- jit.gen operator notes ---\n// noise()/snoise()/cycle() not available — use arithmetic hash: sin(x*prime)*43758.5\n// frac() not available — use x - floor(x) or wrap(x, 0.0, 1.0)\n// vec2/float2 not available — expand manually: sqrt(a*a + b*b)\n// select() not available — use mix(a, b, step(threshold, val))\n// smooth is a GLSL reserved word — avoid as param name\n// vec(r,g,b,a) is the correct 4-component constructor\n// dim.x/dim.y available only when patcher wires r dim → pix @dim\n",
                                    "fontface": 0,
                                    "fontname": "<Monospaced>",
                                    "fontsize": 12.0,
                                    "id": "gen-3",
                                    "maxclass": "codebox",
                                    "numinlets": 1,
                                    "numoutlets": 1,
                                    "outlettype": [ "" ],
                                    "patching_rect": [ 50.0, 60.0, 500.0, 800.0 ]
                                }
                            },
                            {
                                "box": {
                                    "id": "gen-4",
                                    "maxclass": "newobj",
                                    "numinlets": 1,
                                    "numoutlets": 0,
                                    "patching_rect": [ 50.0, 880.0, 35.0, 22.0 ],
                                    "text": "out 1"
                                }
                            }
                        ],
                        "lines": [
                            {
                                "patchline": {
                                    "destination": [ "gen-3", 0 ],
                                    "source": [ "gen-1", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "gen-4", 0 ],
                                    "source": [ "gen-3", 0 ]
                                }
                            }
                        ]
                    },
                    "patching_rect": [ 200.0, 450.0, 200.0, 22.0 ],
                    "text": "jit.gl.pix vsynth @name weave_pix",
                    "varname": "weave_pix"
                }
            },
            {
                "box": {
                    "id": "obj-10",
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
                    "id": "obj-11",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 1100.0, 100.0, 237.6, 22.0 ],
                    "text": "prepend getattr presentation_rect"
                }
            },
            {
                "box": {
                    "id": "obj-12",
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
                    "id": "obj-13",
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
                    "id": "obj-14",
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
                    "id": "obj-15",
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
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "courses",
                    "id": "obj-20",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "weave_pix::courses",
                    "parameter_enable": 1,
                    "patching_rect": [ 100.0, 260.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 8.0, 36.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 8.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "courses",
                            "parameter_mmax": 1000.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "courses",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "courses"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "lbl-obj-20",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 20.0, 20.0, 44.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 8.0, 20.0, 44.0, 18.0 ],
                    "text": "courses"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "bond",
                    "id": "obj-21",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "weave_pix::bond",
                    "parameter_enable": 1,
                    "patching_rect": [ 160.0, 260.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 50.0, 36.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 8.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "bond",
                            "parameter_mmax": 1000.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "bond",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "bond"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "lbl-obj-21",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 20.0, 20.0, 44.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 50.0, 20.0, 44.0, 18.0 ],
                    "text": "bond"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "offset",
                    "id": "obj-22",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "weave_pix::offset",
                    "parameter_enable": 1,
                    "patching_rect": [ 220.0, 260.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 92.0, 36.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "offset",
                            "parameter_mmax": 1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "offset",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "offset"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "lbl-obj-22",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 20.0, 20.0, 44.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 92.0, 20.0, 44.0, 18.0 ],
                    "text": "offset"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "angle",
                    "id": "obj-23",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "weave_pix::angle",
                    "parameter_enable": 1,
                    "patching_rect": [ 280.0, 260.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 134.0, 36.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "angle",
                            "parameter_mmax": 360.0,
                            "parameter_mmin": -360.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "angle",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "angle"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "lbl-obj-23",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 20.0, 20.0, 44.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 134.0, 20.0, 44.0, 18.0 ],
                    "text": "angle"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "skip",
                    "id": "obj-24",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "weave_pix::skip",
                    "parameter_enable": 1,
                    "patching_rect": [ 340.0, 260.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 176.0, 36.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 1.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "skip",
                            "parameter_mmax": 1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "skip",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "skip"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "lbl-obj-24",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 20.0, 20.0, 44.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 176.0, 20.0, 44.0, 18.0 ],
                    "text": "skip"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "quantize",
                    "id": "obj-25",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "weave_pix::quantize",
                    "parameter_enable": 1,
                    "patching_rect": [ 100.0, 320.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 8.0, 93.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "quantize",
                            "parameter_mmax": 1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "quantize",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "quantize"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "lbl-obj-25",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 20.0, 20.0, 44.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 8.0, 77.0, 44.0, 18.0 ],
                    "text": "quantize"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "regularity",
                    "id": "obj-26",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "weave_pix::regularity",
                    "parameter_enable": 1,
                    "patching_rect": [ 160.0, 320.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 50.0, 93.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 1.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "regularity",
                            "parameter_mmax": 1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "regularity",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "regularity"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "lbl-obj-26",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 20.0, 20.0, 44.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 50.0, 77.0, 44.0, 18.0 ],
                    "text": "regular"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "drift",
                    "id": "obj-27",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "weave_pix::drift",
                    "parameter_enable": 1,
                    "patching_rect": [ 220.0, 320.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 92.0, 93.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "drift",
                            "parameter_mmax": 1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "drift",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "drift"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "lbl-obj-27",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 20.0, 20.0, 44.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 92.0, 77.0, 44.0, 18.0 ],
                    "text": "drift"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "phase",
                    "id": "obj-28",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "weave_pix::phase",
                    "parameter_enable": 1,
                    "patching_rect": [ 280.0, 320.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 134.0, 93.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "phase",
                            "parameter_mmax": 1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "phase",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "phase"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "lbl-obj-28",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 20.0, 20.0, 44.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 134.0, 77.0, 44.0, 18.0 ],
                    "text": "phase"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "speed_var",
                    "id": "obj-29",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "weave_pix::speed_var",
                    "parameter_enable": 1,
                    "patching_rect": [ 340.0, 320.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 176.0, 93.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "speed_var",
                            "parameter_mmax": 1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "speed_var",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "speed_var"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "lbl-obj-29",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 20.0, 20.0, 44.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 176.0, 77.0, 44.0, 18.0 ],
                    "text": "spd.var"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "mortar",
                    "id": "obj-30",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "weave_pix::mortar",
                    "parameter_enable": 1,
                    "patching_rect": [ 100.0, 380.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 8.0, 150.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.5 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "mortar",
                            "parameter_mmax": 1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "mortar",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "mortar"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "lbl-obj-30",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 20.0, 20.0, 44.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 8.0, 134.0, 44.0, 18.0 ],
                    "text": "mortar"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "softness",
                    "id": "obj-31",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "weave_pix::softness",
                    "parameter_enable": 1,
                    "patching_rect": [ 160.0, 380.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 50.0, 150.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.2 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "softness",
                            "parameter_mmax": 1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "softness",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "softness"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "lbl-obj-31",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 20.0, 20.0, 44.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 50.0, 134.0, 44.0, 18.0 ],
                    "text": "soft"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "width",
                    "id": "obj-32",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "weave_pix::width",
                    "parameter_enable": 1,
                    "patching_rect": [ 220.0, 380.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 92.0, 150.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.5 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "width",
                            "parameter_mmax": 1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "width",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "width"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "lbl-obj-32",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 20.0, 20.0, 44.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 92.0, 134.0, 44.0, 18.0 ],
                    "text": "width"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "roundness",
                    "id": "obj-33",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "weave_pix::roundness",
                    "parameter_enable": 1,
                    "patching_rect": [ 280.0, 380.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 134.0, 150.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "roundness",
                            "parameter_mmax": 1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "roundness",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "roundness"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "lbl-obj-33",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 20.0, 20.0, 44.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 134.0, 134.0, 44.0, 18.0 ],
                    "text": "round"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "course_color",
                    "id": "obj-35",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "weave_pix::course_color",
                    "parameter_enable": 1,
                    "patching_rect": [ 100.0, 440.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 8.0, 207.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "course_color",
                            "parameter_mmax": 1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "course_color",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "course_color"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "lbl-obj-35",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 20.0, 20.0, 44.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 8.0, 191.0, 44.0, 18.0 ],
                    "text": "crs.col"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "brick_color",
                    "id": "obj-36",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "weave_pix::brick_color",
                    "parameter_enable": 1,
                    "patching_rect": [ 160.0, 440.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 50.0, 207.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "brick_color",
                            "parameter_mmax": 1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "brick_color",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "brick_color"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "lbl-obj-36",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 20.0, 20.0, 44.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 50.0, 191.0, 44.0, 18.0 ],
                    "text": "brk.col"
                }
            },
            {
                "box": {
                    "id": "obj-70",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 100.0, 520.0, 151.20000000000002, 22.0 ],
                    "text": "prepend param courses"
                }
            },
            {
                "box": {
                    "id": "obj-71",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 180.0, 520.0, 129.6, 22.0 ],
                    "text": "prepend param bond"
                }
            },
            {
                "box": {
                    "id": "obj-72",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 260.0, 520.0, 144.0, 22.0 ],
                    "text": "prepend param offset"
                }
            },
            {
                "box": {
                    "id": "obj-73",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 340.0, 520.0, 136.8, 22.0 ],
                    "text": "prepend param angle"
                }
            },
            {
                "box": {
                    "id": "obj-74",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 420.0, 520.0, 129.6, 22.0 ],
                    "text": "prepend param skip"
                }
            },
            {
                "box": {
                    "id": "obj-75",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 500.0, 520.0, 158.4, 22.0 ],
                    "text": "prepend param quantize"
                }
            },
            {
                "box": {
                    "id": "obj-76",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 580.0, 520.0, 172.8, 22.0 ],
                    "text": "prepend param regularity"
                }
            },
            {
                "box": {
                    "id": "obj-77",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 660.0, 520.0, 136.8, 22.0 ],
                    "text": "prepend param drift"
                }
            },
            {
                "box": {
                    "id": "obj-78",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 740.0, 520.0, 136.8, 22.0 ],
                    "text": "prepend param phase"
                }
            },
            {
                "box": {
                    "id": "obj-79",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 820.0, 520.0, 165.6, 22.0 ],
                    "text": "prepend param speed_var"
                }
            },
            {
                "box": {
                    "id": "obj-80",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 900.0, 520.0, 144.0, 22.0 ],
                    "text": "prepend param mortar"
                }
            },
            {
                "box": {
                    "id": "obj-81",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 980.0, 520.0, 158.4, 22.0 ],
                    "text": "prepend param softness"
                }
            },
            {
                "box": {
                    "id": "obj-82",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 1060.0, 520.0, 136.8, 22.0 ],
                    "text": "prepend param width"
                }
            },
            {
                "box": {
                    "id": "obj-83",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 1140.0, 520.0, 165.6, 22.0 ],
                    "text": "prepend param roundness"
                }
            },
            {
                "box": {
                    "id": "obj-84",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 792.8000118136406, 291.20000433921814, 144.0, 22.0 ],
                    "text": "prepend param bypass"
                }
            },
            {
                "box": {
                    "id": "obj-85",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 1300.0, 520.0, 187.20000000000002, 22.0 ],
                    "text": "prepend param course_color"
                }
            },
            {
                "box": {
                    "id": "obj-86",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 1380.0, 520.0, 180.0, 22.0 ],
                    "text": "prepend param brick_color"
                }
            },
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
                    "patching_rect": [ 20.0, 20.0, 215.0, 225.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 0.0, 0.0, 215.0000064074993, 253.66667422652245 ],
                    "proportion": 0.5
                }
            }
        ],
        "lines": [
            {
                "patchline": {
                    "destination": [ "obj-11", 0 ],
                    "source": [ "obj-10", 0 ]
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
                    "source": [ "obj-14", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-70", 0 ],
                    "source": [ "obj-20", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-71", 0 ],
                    "source": [ "obj-21", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-72", 0 ],
                    "source": [ "obj-22", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-73", 0 ],
                    "source": [ "obj-23", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-74", 0 ],
                    "source": [ "obj-24", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-75", 0 ],
                    "source": [ "obj-25", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-76", 0 ],
                    "source": [ "obj-26", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-77", 0 ],
                    "source": [ "obj-27", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-78", 0 ],
                    "source": [ "obj-28", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-79", 0 ],
                    "source": [ "obj-29", 0 ]
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
                    "destination": [ "obj-80", 0 ],
                    "source": [ "obj-30", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-81", 0 ],
                    "source": [ "obj-31", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-82", 0 ],
                    "source": [ "obj-32", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-83", 0 ],
                    "source": [ "obj-33", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-85", 0 ],
                    "source": [ "obj-35", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-86", 0 ],
                    "source": [ "obj-36", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5b", 0 ],
                    "source": [ "obj-5", 2 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-7", 0 ],
                    "source": [ "obj-5", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-20", 0 ],
                    "source": [ "obj-5b", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-21", 0 ],
                    "source": [ "obj-5b", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-22", 0 ],
                    "source": [ "obj-5b", 2 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-23", 0 ],
                    "source": [ "obj-5b", 3 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-24", 0 ],
                    "source": [ "obj-5b", 4 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-25", 0 ],
                    "source": [ "obj-5b", 5 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-26", 0 ],
                    "source": [ "obj-5b", 6 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-27", 0 ],
                    "source": [ "obj-5b", 7 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-28", 0 ],
                    "source": [ "obj-5b", 8 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-29", 0 ],
                    "source": [ "obj-5b", 9 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-30", 0 ],
                    "source": [ "obj-5b", 10 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-31", 0 ],
                    "source": [ "obj-5b", 11 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-32", 0 ],
                    "source": [ "obj-5b", 12 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-33", 0 ],
                    "source": [ "obj-5b", 13 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-35", 0 ],
                    "source": [ "obj-5b", 15 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-36", 0 ],
                    "source": [ "obj-5b", 16 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-8", 0 ],
                    "source": [ "obj-5b", 14 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-4", 0 ],
                    "source": [ "obj-7", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-7", 0 ],
                    "source": [ "obj-70", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-7", 0 ],
                    "source": [ "obj-71", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-7", 0 ],
                    "source": [ "obj-72", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-7", 0 ],
                    "source": [ "obj-73", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-7", 0 ],
                    "source": [ "obj-74", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-7", 0 ],
                    "source": [ "obj-75", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-7", 0 ],
                    "source": [ "obj-76", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-7", 0 ],
                    "source": [ "obj-77", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-7", 0 ],
                    "source": [ "obj-78", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-7", 0 ],
                    "source": [ "obj-79", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-84", 0 ],
                    "source": [ "obj-8", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-7", 0 ],
                    "source": [ "obj-80", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-7", 0 ],
                    "source": [ "obj-81", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-7", 0 ],
                    "source": [ "obj-82", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-7", 0 ],
                    "source": [ "obj-83", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-7", 0 ],
                    "source": [ "obj-84", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-7", 0 ],
                    "source": [ "obj-85", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-7", 0 ],
                    "source": [ "obj-86", 0 ]
                }
            }
        ],
        "parameters": {
            "obj-20": [ "courses", "courses", 0 ],
            "obj-21": [ "bond", "bond", 0 ],
            "obj-22": [ "offset", "offset", 0 ],
            "obj-23": [ "angle", "angle", 0 ],
            "obj-24": [ "skip", "skip", 0 ],
            "obj-25": [ "quantize", "quantize", 0 ],
            "obj-26": [ "regularity", "regularity", 0 ],
            "obj-27": [ "drift", "drift", 0 ],
            "obj-28": [ "phase", "phase", 0 ],
            "obj-29": [ "speed_var", "speed_var", 0 ],
            "obj-30": [ "mortar", "mortar", 0 ],
            "obj-31": [ "softness", "softness", 0 ],
            "obj-32": [ "width", "width", 0 ],
            "obj-33": [ "roundness", "roundness", 0 ],
            "obj-35": [ "course_color", "course_color", 0 ],
            "obj-36": [ "brick_color", "brick_color", 0 ],
            "obj-8": [ "bypass", "bypass", 0 ],
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