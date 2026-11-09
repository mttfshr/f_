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
						20.0,
						30.0,
						30.0
					]
				}
			},
			{
				"box": {
					"id": "obj-2",
					"maxclass": "outlet",
					"comment": "plate 1",
					"index": 0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						30.0,
						452.0,
						30.0,
						30.0
					]
				}
			},
			{
				"box": {
					"id": "obj-201",
					"maxclass": "outlet",
					"comment": "plate 2",
					"index": 0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						100.0,
						452.0,
						30.0,
						30.0
					]
				}
			},
			{
				"box": {
					"id": "obj-202",
					"maxclass": "outlet",
					"comment": "plate 3",
					"index": 0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						170.0,
						452.0,
						30.0,
						30.0
					]
				}
			},
			{
				"box": {
					"id": "obj-203",
					"maxclass": "outlet",
					"comment": "preview (plates summed)",
					"index": 0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						240.0,
						452.0,
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
						30.0,
						70.0,
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
					"numoutlets": 11,
					"outlettype": [
						"",
						"",
						"",
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
						56.5,
						204.0,
						799.0,
						22.0
					],
					"text": "route n_inks sep_mode gain1 gain2 gain3 sat1 sat2 sat3 ink1 ink2 ink3"
				}
			},
			{
				"box": {
					"id": "obj-5",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 5,
					"outlettype": [
						"jit_gl_texture",
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
									"code": "// codebox_separate.gen -- f_separate: the one stage. Splits a colour image into up to three spot-colour plates.\n// Stateless, per pixel. Float32. Mirror: tests/modules/separate/separate_mirror.separate_stage().\n//\n// Model (Matt, 2026-11-08): black background, inks are colours of light that ADD. pixel = sum_i c_i * k_i, k_i the\n// ink colour (Params inkN_r/g/b), c_i the coverage in 0..1.\n//   - unmix: c = clamp(gain * (K^T K + lam I)^-1 K^T x, 0, 1), K = 3 x N (N = n_inks). The 3x3 inverse is by\n//     cofactors. Inks beyond n_inks have a zero column in K and a 1 on the diagonal, so they decouple and come out 0.\n//     lam = 1e-4 * trace(K^T K) / N + 1e-8 (relative ridge; an inferred choice, gate G3)\n//   - nearest (sep_mode 1): the nearest of the N inks and black (squared RGB distance; ties go to the lowest ink, black\n//     last) gets coverage 1, the others 0; then gain and the same clamp\n//   - project (sep_mode 2): each ink alone, c_i = clamp(gain_i * (k_i . x) / (k_i . k_i), 0, 1); a plate depends only on\n//     the source and its own ink (Matt, 2026-11-08: easier to reason about than the joint solve)\n//   - outlets: 1 to 3 = the plates, coverage * ink colour; 4 = the preview, the sum of the plates clamped to 0..1.\n//     Alpha is the source's on all four.\n//   - bypass_gate = 1: the (zapped) source on all four outlets\n//   - non-finite input components are zapped to 0 first: abs(x) < 1e30 with switch() (NaN == NaN is TRUE on this GPU)\n// Params are named so none equals a jit.gl.pix attribute (`mode` would bind to the attribute: sep_mode).\nzap(xv) {\n    return switch(abs(xv) < 1e30, xv, 0);\n}\n\nParam ink1_r(1.0);\nParam ink1_g(0.25);\nParam ink1_b(0.0);\nParam ink2_r(0.0);\nParam ink2_g(0.6);\nParam ink2_b(0.6);\nParam ink3_r(0.45);\nParam ink3_g(0.0);\nParam ink3_b(1.0);\nParam n_inks(2);\nParam sep_mode(0);\nParam gain1(1);\nParam gain2(1);\nParam gain3(1);\nParam bypass_gate(0);\n\nxr = zap(sample(in1, norm).x);\nxg = zap(sample(in1, norm).y);\nxb = zap(sample(in1, norm).z);\nxa = zap(sample(in1, norm).w);\n\nact1 = switch(n_inks >= 0.5, 1, 0);\nact2 = switch(n_inks >= 1.5, 1, 0);\nact3 = switch(n_inks >= 2.5, 1, 0);\n\nk1r = clamp(ink1_r, 0, 1) * act1;\nk1g = clamp(ink1_g, 0, 1) * act1;\nk1b = clamp(ink1_b, 0, 1) * act1;\nk2r = clamp(ink2_r, 0, 1) * act2;\nk2g = clamp(ink2_g, 0, 1) * act2;\nk2b = clamp(ink2_b, 0, 1) * act2;\nk3r = clamp(ink3_r, 0, 1) * act3;\nk3g = clamp(ink3_g, 0, 1) * act3;\nk3b = clamp(ink3_b, 0, 1) * act3;\n\n// K^T K (symmetric) and the ridge\nm11 = k1r * k1r + k1g * k1g + k1b * k1b;\nm12 = k1r * k2r + k1g * k2g + k1b * k2b;\nm13 = k1r * k3r + k1g * k3g + k1b * k3b;\nm22 = k2r * k2r + k2g * k2g + k2b * k2b;\nm23 = k2r * k3r + k2g * k3g + k2b * k3b;\nm33 = k3r * k3r + k3g * k3g + k3b * k3b;\nlam = 0.0001 * (m11 + m22 + m33) / max(act1 + act2 + act3, 1) + 0.00000001;\nma = m11 + switch(act1 > 0.5, lam, 1);\nme = m22 + switch(act2 > 0.5, lam, 1);\nmi = m33 + switch(act3 > 0.5, lam, 1);\n\n// cofactors and determinant of [[ma, m12, m13], [m12, me, m23], [m13, m23, mi]]\nc11 = me * mi - m23 * m23;\nc12 = m13 * m23 - m12 * mi;\nc13 = m12 * m23 - m13 * me;\nc22 = ma * mi - m13 * m13;\nc23 = m12 * m13 - ma * m23;\nc33 = ma * me - m12 * m12;\ndet = ma * c11 + m12 * c12 + m13 * c13;\nidet = 1 / det;\n\n// K^T x\nt1 = k1r * xr + k1g * xg + k1b * xb;\nt2 = k2r * xr + k2g * xg + k2b * xb;\nt3 = k3r * xr + k3g * xg + k3b * xb;\nraw1 = (c11 * t1 + c12 * t2 + c13 * t3) * idet;\nraw2 = (c12 * t1 + c22 * t2 + c23 * t3) * idet;\nraw3 = (c13 * t1 + c23 * t2 + c33 * t3) * idet;\n\n// nearest: squared distance to each active ink and to black (an inactive ink is out of the race)\nd0 = xr * xr + xg * xg + xb * xb;\nd1 = switch(act1 > 0.5, (xr - k1r) * (xr - k1r) + (xg - k1g) * (xg - k1g) + (xb - k1b) * (xb - k1b), 1000000000);\nd2 = switch(act2 > 0.5, (xr - k2r) * (xr - k2r) + (xg - k2g) * (xg - k2g) + (xb - k2b) * (xb - k2b), 1000000000);\nd3 = switch(act3 > 0.5, (xr - k3r) * (xr - k3r) + (xg - k3g) * (xg - k3g) + (xb - k3b) * (xb - k3b), 1000000000);\nw1 = switch(d1 <= d2 && d1 <= d3 && d1 <= d0, 1, 0) * act1;\nw2 = switch(d2 < d1 && d2 <= d3 && d2 <= d0, 1, 0) * act2;\nw3 = switch(d3 < d1 && d3 < d2 && d3 <= d0, 1, 0) * act3;\n\nnear_flag = switch(sep_mode >= 0.5 && sep_mode < 1.5, 1, 0);\nproj_flag = switch(sep_mode >= 1.5, 1, 0);\npj1 = t1 / max(m11, 0.00000001);\npj2 = t2 / max(m22, 0.00000001);\npj3 = t3 / max(m33, 0.00000001);\ncv1 = clamp(mix(mix(raw1, w1, near_flag), pj1, proj_flag) * gain1, 0, 1) * act1;\ncv2 = clamp(mix(mix(raw2, w2, near_flag), pj2, proj_flag) * gain2, 0, 1) * act2;\ncv3 = clamp(mix(mix(raw3, w3, near_flag), pj3, proj_flag) * gain3, 0, 1) * act3;\n\np1r = cv1 * k1r;\np1g = cv1 * k1g;\np1b = cv1 * k1b;\np2r = cv2 * k2r;\np2g = cv2 * k2g;\np2b = cv2 * k2b;\np3r = cv3 * k3r;\np3g = cv3 * k3g;\np3b = cv3 * k3b;\n\nsr = clamp(p1r + p2r + p3r, 0, 1);\nsg = clamp(p1g + p2g + p3g, 0, 1);\nsb = clamp(p1b + p2b + p3b, 0, 1);\n\nout1 = vec(mix(p1r, xr, bypass_gate), mix(p1g, xg, bypass_gate), mix(p1b, xb, bypass_gate), xa);\nout2 = vec(mix(p2r, xr, bypass_gate), mix(p2g, xg, bypass_gate), mix(p2b, xb, bypass_gate), xa);\nout3 = vec(mix(p3r, xr, bypass_gate), mix(p3g, xg, bypass_gate), mix(p3b, xb, bypass_gate), xa);\nout4 = vec(mix(sr, xr, bypass_gate), mix(sg, xg, bypass_gate), mix(sb, xb, bypass_gate), xa);\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
									"id": "gen-obj-2",
									"maxclass": "codebox",
									"numinlets": 1,
									"numoutlets": 4,
									"outlettype": [
										"",
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
							},
							{
								"box": {
									"id": "gen-obj-4",
									"maxclass": "newobj",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										82.0,
										490.0,
										35.0,
										22.0
									],
									"text": "out 2"
								}
							},
							{
								"box": {
									"id": "gen-obj-5",
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
							},
							{
								"box": {
									"id": "gen-obj-6",
									"maxclass": "newobj",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										202.0,
										490.0,
										35.0,
										22.0
									],
									"text": "out 4"
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
							},
							{
								"patchline": {
									"destination": [
										"gen-obj-4",
										0
									],
									"source": [
										"gen-obj-2",
										1
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
										"gen-obj-2",
										2
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
										"gen-obj-2",
										3
									]
								}
							}
						]
					},
					"patching_rect": [
						30.0,
						380.0,
						200.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name separate_pix @adapt 0 @dim 256 256 @type float32",
					"varname": "separate_pix"
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
						1135.5,
						100.0,
						56.0,
						22.0
					],
					"text": "autopattr",
					"varname": "separate_autopattr"
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
						915.5,
						260.0,
						191.0,
						200.0
					],
					"presentation": 1,
					"presentation_rect": [
						0.0,
						0.0,
						191.0,
						200.0
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
						1135.5,
						200.0,
						80.0,
						21.0
					],
					"presentation": 1,
					"presentation_rect": [
						10.5,
						0.0,
						92.0,
						21.0
					],
					"text": "Separate"
				}
			},
			{
				"box": {
					"id": "obj-8",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 11.0,
					"textcolor": [
						0.6,
						0.6,
						0.6,
						1.0
					],
					"textjustification": 2,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						1225.5,
						200.0,
						60.0,
						21.0
					],
					"presentation": 1,
					"presentation_rect": [
						95.0,
						0.9,
						70.0,
						21.0
					],
					"text": "tex in/out"
				}
			},
			{
				"box": {
					"id": "obj-19f",
					"maxclass": "panel",
					"background": 0,
					"bgcolor": [
						0.28,
						0.28,
						0.28,
						1.0
					],
					"border": 0,
					"mode": 0,
					"hint": "Takes: no vecfield or tensor",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						1135.5,
						232.0,
						5.0,
						5.0
					],
					"presentation": 1,
					"presentation_rect": [
						4.0,
						5.0,
						5.0,
						5.0
					],
					"rounded": 6
				}
			},
			{
				"box": {
					"id": "obj-19g",
					"maxclass": "panel",
					"background": 0,
					"bgcolor": [
						0.28,
						0.28,
						0.28,
						1.0
					],
					"border": 0,
					"mode": 0,
					"hint": "Outputs: no vecfield or tensor",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						1155.5,
						232.0,
						5.0,
						5.0
					],
					"presentation": 1,
					"presentation_rect": [
						4.0,
						12.0,
						5.0,
						5.0
					],
					"rounded": 6
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
						915.5,
						20.0,
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
						915.5,
						50.0,
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
						915.5,
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
						915.5,
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
						915.5,
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
						915.5,
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
					"maxclass": "live.numbox",
					"fontname": "Ableton Sans Light",
					"hint": "How many inks are active. Unused plates are black",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "separate_pix::n_inks",
					"parameter_enable": 1,
					"patching_rect": [
						38.0,
						250.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						4.0,
						38.0,
						34.0,
						15.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								2.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "n_inks",
							"parameter_mmax": 3.0,
							"parameter_mmin": 1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "n_inks",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"varname": "n_inks"
				}
			},
			{
				"box": {
					"id": "obj-21",
					"maxclass": "attrui",
					"attr": "n_inks",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						26.0,
						310.0,
						68.0,
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
						35.0,
						180.0,
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
					"text": "Inks",
					"textjustification": 1,
					"varname": "lbl_n_inks"
				}
			},
			{
				"box": {
					"id": "obj-23",
					"maxclass": "live.menu",
					"fontname": "Ableton Sans Light",
					"hint": "Unmix: the best-fit coverage of all the inks together (exact round trip, but plates depend on each other). Nearest: each pixel wholly to its nearest ink, or to none when black is nearest. Project: each ink on its own, so a plate never depends on the other inks (the preview can overshoot)",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"",
						"",
						"float"
					],
					"param_connect": "separate_pix::sep_mode",
					"parameter_enable": 1,
					"patching_rect": [
						102.0,
						250.0,
						60.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						37.0,
						52.0,
						45.0,
						15.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_enum": [
								"Unmix",
								"Nearest",
								"Project"
							],
							"parameter_initial": [
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "sep_mode",
							"parameter_mmax": 2.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 0,
							"parameter_shortname": "sep_mode",
							"parameter_type": 2,
							"parameter_unitstyle": 0
						}
					},
					"varname": "sep_mode"
				}
			},
			{
				"box": {
					"id": "obj-24",
					"maxclass": "attrui",
					"attr": "sep_mode",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						98.0,
						310.0,
						68.0,
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
						107.0,
						180.0,
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
					"text": "Mode",
					"textjustification": 1,
					"varname": "lbl_sep_mode"
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
					"hint": "Plate 1 coverage gain. Above 1 saturates faster but never exceeds the ink colour",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "separate_pix::gain1",
					"parameter_enable": 1,
					"patching_rect": [
						190.5,
						250.0,
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
								1.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "gain1",
							"parameter_mmax": 2.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "gain1",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "gain1"
				}
			},
			{
				"box": {
					"id": "obj-27",
					"maxclass": "attrui",
					"attr": "gain1",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						170.0,
						310.0,
						68.0,
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
						179.0,
						180.0,
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
					"text": "Gain 1",
					"textjustification": 1,
					"varname": "lbl_gain1"
				}
			},
			{
				"box": {
					"id": "obj-29",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Plate 2 coverage gain",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "separate_pix::gain2",
					"parameter_enable": 1,
					"patching_rect": [
						262.5,
						250.0,
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
							"parameter_longname": "gain2",
							"parameter_mmax": 2.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "gain2",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "gain2"
				}
			},
			{
				"box": {
					"id": "obj-30",
					"maxclass": "attrui",
					"attr": "gain2",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						242.0,
						310.0,
						68.0,
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
						251.0,
						180.0,
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
					"text": "Gain 2",
					"textjustification": 1,
					"varname": "lbl_gain2"
				}
			},
			{
				"box": {
					"id": "obj-32",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Plate 3 coverage gain",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "separate_pix::gain3",
					"parameter_enable": 1,
					"patching_rect": [
						334.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						152.0,
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
							"parameter_longname": "gain3",
							"parameter_mmax": 2.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "gain3",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "gain3"
				}
			},
			{
				"box": {
					"id": "obj-33",
					"maxclass": "attrui",
					"attr": "gain3",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						314.0,
						310.0,
						68.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-34",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						323.0,
						180.0,
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
					"text": "Gain 3",
					"textjustification": 1,
					"varname": "lbl_gain3"
				}
			},
			{
				"box": {
					"id": "obj-35",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Saturation of swatch 1's colour plane (lower for pastels and greys)",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "separate_pix::sat1",
					"parameter_enable": 1,
					"patching_rect": [
						406.5,
						250.0,
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
								1.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "sat1",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "sat1",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "sat1"
				}
			},
			{
				"box": {
					"id": "obj-37",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						395.0,
						180.0,
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
					"text": "Sat 1",
					"textjustification": 1,
					"varname": "lbl_sat1"
				}
			},
			{
				"box": {
					"id": "obj-38",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Saturation of swatch 2's colour plane",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "separate_pix::sat2",
					"parameter_enable": 1,
					"patching_rect": [
						478.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						41.0,
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
								1.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "sat2",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "sat2",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "sat2"
				}
			},
			{
				"box": {
					"id": "obj-40",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						467.0,
						180.0,
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
					"text": "Sat 2",
					"textjustification": 1,
					"varname": "lbl_sat2"
				}
			},
			{
				"box": {
					"id": "obj-41",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Saturation of swatch 3's colour plane",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "separate_pix::sat3",
					"parameter_enable": 1,
					"patching_rect": [
						550.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						78.0,
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
								1.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "sat3",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "sat3",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "sat3"
				}
			},
			{
				"box": {
					"id": "obj-43",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						539.0,
						180.0,
						50.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						66.5,
						82.0,
						50.0,
						18.0
					],
					"text": "Sat 3",
					"textjustification": 1,
					"varname": "lbl_sat3"
				}
			},
			{
				"box": {
					"id": "obj-44",
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
						1135.5,
						130.0,
						18.0,
						12.0
					],
					"presentation_rect": [
						169.0,
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
					"id": "obj-45",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1135.5,
						160.0,
						131.0,
						22.0
					],
					"text": "prepend param bypass_gate"
				}
			},
			{
				"box": {
					"id": "obj-rd-0",
					"maxclass": "newobj",
					"patching_rect": [
						210.0,
						842.0,
						40.0,
						22.0
					],
					"text": "r dim",
					"numinlets": 0,
					"numoutlets": 1,
					"outlettype": [
						""
					]
				}
			},
			{
				"box": {
					"id": "obj-rd-5",
					"maxclass": "newobj",
					"patching_rect": [
						350.0,
						842.0,
						60.0,
						22.0
					],
					"text": "loadbang",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"bang"
					]
				}
			},
			{
				"box": {
					"id": "obj-rd-6",
					"maxclass": "newobj",
					"patching_rect": [
						350.0,
						872.0,
						70.0,
						22.0
					],
					"text": "s trig_res",
					"numinlets": 1,
					"numoutlets": 0,
					"outlettype": []
				}
			},
			{
				"box": {
					"id": "obj-raw-load",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						290.0,
						542.0,
						60.0,
						22.0
					],
					"text": "loadbang"
				}
			},
			{
				"box": {
					"id": "obj-raw-def",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						290.0,
						572.0,
						60.0,
						22.0
					],
					"text": "deferlow"
				}
			},
			{
				"box": {
					"id": "obj-raw-draw",
					"maxclass": "newobj",
					"numinlets": 0,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						370.0,
						542.0,
						50.0,
						22.0
					],
					"text": "r draw"
				}
			},
			{
				"box": {
					"id": "obj-raw-once",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 2,
					"outlettype": [
						"bang",
						"bang"
					],
					"patching_rect": [
						370.0,
						572.0,
						70.0,
						22.0
					],
					"text": "onebang 1"
				}
			},
			{
				"box": {
					"id": "obj-raw-wait",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"bang"
					],
					"patching_rect": [
						370.0,
						602.0,
						70.0,
						22.0
					],
					"text": "delay 100"
				}
			},
			{
				"box": {
					"id": "obj-raw-sw1",
					"maxclass": "swatch",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"patching_rect": [
						30.0,
						822.0,
						60.0,
						30.0
					],
					"presentation": 1,
					"presentation_rect": [
						4.0,
						160.0,
						56.0,
						36.0
					],
					"varname": "ink1_swatch"
				}
			},
			{
				"box": {
					"id": "obj-raw-lbl1",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"outlettype": [],
					"patching_rect": [
						110.0,
						802.0,
						50.0,
						18.0
					],
					"text": "Ink 1",
					"presentation": 1,
					"presentation_rect": [
						-2.0,
						144.0,
						50.0,
						18.0
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"textjustification": 1,
					"varname": "lbl_ink1"
				}
			},
			{
				"box": {
					"id": "obj-raw-set1",
					"maxclass": "message",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						110.0,
						822.0,
						120.0,
						22.0
					],
					"text": "set 1.0 0.25 0.0 1."
				}
			},
			{
				"box": {
					"id": "obj-raw-un1",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 4,
					"outlettype": [
						"float",
						"float",
						"float",
						"float"
					],
					"patching_rect": [
						30.0,
						862.0,
						100.0,
						22.0
					],
					"text": "unpack 0. 0. 0. 0."
				}
			},
			{
				"box": {
					"id": "obj-raw-pp1r",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						30.0,
						892.0,
						120.0,
						22.0
					],
					"text": "prepend param ink1_r"
				}
			},
			{
				"box": {
					"id": "obj-raw-pp1g",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						160.0,
						892.0,
						120.0,
						22.0
					],
					"text": "prepend param ink1_g"
				}
			},
			{
				"box": {
					"id": "obj-raw-pp1b",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						290.0,
						892.0,
						120.0,
						22.0
					],
					"text": "prepend param ink1_b"
				}
			},
			{
				"box": {
					"id": "obj-raw-ex1",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						250.0,
						822.0,
						100.0,
						22.0
					],
					"text": "expr $f1 * 255."
				}
			},
			{
				"box": {
					"id": "obj-raw-tr1",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"bang",
						"float"
					],
					"patching_rect": [
						250.0,
						852.0,
						50.0,
						22.0
					],
					"text": "t b f"
				}
			},
			{
				"box": {
					"id": "obj-raw-ps1",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						250.0,
						882.0,
						120.0,
						22.0
					],
					"text": "prepend saturation"
				}
			},
			{
				"box": {
					"id": "obj-raw-sw2",
					"maxclass": "swatch",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"patching_rect": [
						30.0,
						952.0,
						60.0,
						30.0
					],
					"presentation": 1,
					"presentation_rect": [
						68.0,
						160.0,
						56.0,
						36.0
					],
					"varname": "ink2_swatch"
				}
			},
			{
				"box": {
					"id": "obj-raw-lbl2",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"outlettype": [],
					"patching_rect": [
						110.0,
						932.0,
						50.0,
						18.0
					],
					"text": "Ink 2",
					"presentation": 1,
					"presentation_rect": [
						62.0,
						144.0,
						50.0,
						18.0
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"textjustification": 1,
					"varname": "lbl_ink2"
				}
			},
			{
				"box": {
					"id": "obj-raw-set2",
					"maxclass": "message",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						110.0,
						952.0,
						120.0,
						22.0
					],
					"text": "set 0.0 0.6 0.6 1."
				}
			},
			{
				"box": {
					"id": "obj-raw-un2",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 4,
					"outlettype": [
						"float",
						"float",
						"float",
						"float"
					],
					"patching_rect": [
						30.0,
						992.0,
						100.0,
						22.0
					],
					"text": "unpack 0. 0. 0. 0."
				}
			},
			{
				"box": {
					"id": "obj-raw-pp2r",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						30.0,
						1022.0,
						120.0,
						22.0
					],
					"text": "prepend param ink2_r"
				}
			},
			{
				"box": {
					"id": "obj-raw-pp2g",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						160.0,
						1022.0,
						120.0,
						22.0
					],
					"text": "prepend param ink2_g"
				}
			},
			{
				"box": {
					"id": "obj-raw-pp2b",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						290.0,
						1022.0,
						120.0,
						22.0
					],
					"text": "prepend param ink2_b"
				}
			},
			{
				"box": {
					"id": "obj-raw-ex2",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						250.0,
						952.0,
						100.0,
						22.0
					],
					"text": "expr $f1 * 255."
				}
			},
			{
				"box": {
					"id": "obj-raw-tr2",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"bang",
						"float"
					],
					"patching_rect": [
						250.0,
						982.0,
						50.0,
						22.0
					],
					"text": "t b f"
				}
			},
			{
				"box": {
					"id": "obj-raw-ps2",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						250.0,
						1012.0,
						120.0,
						22.0
					],
					"text": "prepend saturation"
				}
			},
			{
				"box": {
					"id": "obj-raw-sw3",
					"maxclass": "swatch",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"patching_rect": [
						30.0,
						1082.0,
						60.0,
						30.0
					],
					"presentation": 1,
					"presentation_rect": [
						132.0,
						160.0,
						56.0,
						36.0
					],
					"varname": "ink3_swatch"
				}
			},
			{
				"box": {
					"id": "obj-raw-lbl3",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"outlettype": [],
					"patching_rect": [
						110.0,
						1062.0,
						50.0,
						18.0
					],
					"text": "Ink 3",
					"presentation": 1,
					"presentation_rect": [
						126.0,
						144.0,
						50.0,
						18.0
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"textjustification": 1,
					"varname": "lbl_ink3"
				}
			},
			{
				"box": {
					"id": "obj-raw-set3",
					"maxclass": "message",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						110.0,
						1082.0,
						120.0,
						22.0
					],
					"text": "set 0.45 0.0 1.0 1."
				}
			},
			{
				"box": {
					"id": "obj-raw-un3",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 4,
					"outlettype": [
						"float",
						"float",
						"float",
						"float"
					],
					"patching_rect": [
						30.0,
						1122.0,
						100.0,
						22.0
					],
					"text": "unpack 0. 0. 0. 0."
				}
			},
			{
				"box": {
					"id": "obj-raw-pp3r",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						30.0,
						1152.0,
						120.0,
						22.0
					],
					"text": "prepend param ink3_r"
				}
			},
			{
				"box": {
					"id": "obj-raw-pp3g",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						160.0,
						1152.0,
						120.0,
						22.0
					],
					"text": "prepend param ink3_g"
				}
			},
			{
				"box": {
					"id": "obj-raw-pp3b",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						290.0,
						1152.0,
						120.0,
						22.0
					],
					"text": "prepend param ink3_b"
				}
			},
			{
				"box": {
					"id": "obj-raw-ex3",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						250.0,
						1082.0,
						100.0,
						22.0
					],
					"text": "expr $f1 * 255."
				}
			},
			{
				"box": {
					"id": "obj-raw-tr3",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"bang",
						"float"
					],
					"patching_rect": [
						250.0,
						1112.0,
						50.0,
						22.0
					],
					"text": "t b f"
				}
			},
			{
				"box": {
					"id": "obj-raw-ps3",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						250.0,
						1142.0,
						120.0,
						22.0
					],
					"text": "prepend saturation"
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
						"obj-5",
						1
					],
					"destination": [
						"obj-201",
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
						"obj-202",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-5",
						3
					],
					"destination": [
						"obj-203",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-44",
						0
					],
					"destination": [
						"obj-45",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-45",
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
			},
			{
				"patchline": {
					"source": [
						"obj-4",
						4
					],
					"destination": [
						"obj-32",
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
						"obj-4",
						5
					],
					"destination": [
						"obj-35",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-4",
						6
					],
					"destination": [
						"obj-38",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-4",
						7
					],
					"destination": [
						"obj-41",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-rd-5",
						0
					],
					"destination": [
						"obj-rd-6",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-rd-0",
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
						"obj-raw-load",
						0
					],
					"destination": [
						"obj-raw-def",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-draw",
						0
					],
					"destination": [
						"obj-raw-once",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-once",
						0
					],
					"destination": [
						"obj-raw-wait",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-4",
						8
					],
					"destination": [
						"obj-raw-sw1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-def",
						0
					],
					"destination": [
						"obj-raw-set1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-set1",
						0
					],
					"destination": [
						"obj-raw-sw1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-wait",
						0
					],
					"destination": [
						"obj-raw-sw1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-sw1",
						0
					],
					"destination": [
						"obj-raw-un1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-un1",
						0
					],
					"destination": [
						"obj-raw-pp1r",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-pp1r",
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
						"obj-raw-un1",
						1
					],
					"destination": [
						"obj-raw-pp1g",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-pp1g",
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
						"obj-raw-un1",
						2
					],
					"destination": [
						"obj-raw-pp1b",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-pp1b",
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
						"obj-35",
						0
					],
					"destination": [
						"obj-raw-ex1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-ex1",
						0
					],
					"destination": [
						"obj-raw-tr1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-tr1",
						1
					],
					"destination": [
						"obj-raw-ps1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-ps1",
						0
					],
					"destination": [
						"obj-raw-sw1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-tr1",
						0
					],
					"destination": [
						"obj-raw-sw1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-4",
						9
					],
					"destination": [
						"obj-raw-sw2",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-def",
						0
					],
					"destination": [
						"obj-raw-set2",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-set2",
						0
					],
					"destination": [
						"obj-raw-sw2",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-wait",
						0
					],
					"destination": [
						"obj-raw-sw2",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-sw2",
						0
					],
					"destination": [
						"obj-raw-un2",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-un2",
						0
					],
					"destination": [
						"obj-raw-pp2r",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-pp2r",
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
						"obj-raw-un2",
						1
					],
					"destination": [
						"obj-raw-pp2g",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-pp2g",
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
						"obj-raw-un2",
						2
					],
					"destination": [
						"obj-raw-pp2b",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-pp2b",
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
						"obj-38",
						0
					],
					"destination": [
						"obj-raw-ex2",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-ex2",
						0
					],
					"destination": [
						"obj-raw-tr2",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-tr2",
						1
					],
					"destination": [
						"obj-raw-ps2",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-ps2",
						0
					],
					"destination": [
						"obj-raw-sw2",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-tr2",
						0
					],
					"destination": [
						"obj-raw-sw2",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-4",
						10
					],
					"destination": [
						"obj-raw-sw3",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-def",
						0
					],
					"destination": [
						"obj-raw-set3",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-set3",
						0
					],
					"destination": [
						"obj-raw-sw3",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-wait",
						0
					],
					"destination": [
						"obj-raw-sw3",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-sw3",
						0
					],
					"destination": [
						"obj-raw-un3",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-un3",
						0
					],
					"destination": [
						"obj-raw-pp3r",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-pp3r",
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
						"obj-raw-un3",
						1
					],
					"destination": [
						"obj-raw-pp3g",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-pp3g",
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
						"obj-raw-un3",
						2
					],
					"destination": [
						"obj-raw-pp3b",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-pp3b",
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
						"obj-41",
						0
					],
					"destination": [
						"obj-raw-ex3",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-ex3",
						0
					],
					"destination": [
						"obj-raw-tr3",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-tr3",
						1
					],
					"destination": [
						"obj-raw-ps3",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-ps3",
						0
					],
					"destination": [
						"obj-raw-sw3",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-tr3",
						0
					],
					"destination": [
						"obj-raw-sw3",
						0
					]
				}
			}
		],
		"parameters": {
			"obj-20": [
				"n_inks",
				"n_inks",
				0
			],
			"obj-23": [
				"sep_mode",
				"sep_mode",
				0
			],
			"obj-26": [
				"gain1",
				"gain1",
				0
			],
			"obj-29": [
				"gain2",
				"gain2",
				0
			],
			"obj-32": [
				"gain3",
				"gain3",
				0
			],
			"obj-35": [
				"sat1",
				"sat1",
				0
			],
			"obj-38": [
				"sat2",
				"sat2",
				0
			],
			"obj-41": [
				"sat3",
				"sat3",
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