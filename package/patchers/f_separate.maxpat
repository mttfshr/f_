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
					"comment": "composite (the plates summed)",
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
					"comment": "plate 1",
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
					"comment": "plate 2",
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
					"comment": "plate 3",
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
					"numoutlets": 14,
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
						"",
						"",
						"",
						""
					],
					"patching_rect": [
						56.5,
						204.0,
						1015.0,
						22.0
					],
					"text": "route n_inks sep_mode ink1_h ink1_s ink1_l gain1 ink2_h ink2_s ink2_l gain2 ink3_h ink3_s ink3_l gain3"
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
									"code": "// codebox_separate.gen -- f_separate: the one stage. Splits a color image into up to three spot-color plates.\n// Stateless, per pixel. Float32. Mirror: tests/modules/separate/separate_mirror.separate_stage().\n//\n// Model (Matt, 2026-11-08): black background, inks are colors of light that ADD. pixel = sum_i c_i * k_i, k_i the\n// ink color (from Params inkN_h/s/l through hsl2rgb, 2026-11-14; before that inkN_r/g/b from swatches), c_i the coverage.\n//   - unmix: c = clamp(gain * (K^T K + lam I)^-1 K^T x, 0, 1), K = 3 x N (N = n_inks). The 3x3 inverse is by\n//     cofactors. Inks beyond n_inks have a zero column in K and a 1 on the diagonal, so they decouple and come out 0.\n//     lam = 1e-4 * trace(K^T K) / N + 1e-8 (relative ridge; an inferred choice, gate G3)\n//   - nearest (sep_mode 1): the nearest of the N inks and black (squared RGB distance; ties go to the lowest ink, black\n//     last) gets coverage 1, the others 0; then gain and the same clamp\n//   - project (sep_mode 2): each ink alone, c_i = clamp(gain_i * (k_i . x) / (k_i . k_i), 0, 1); a plate depends only on\n//     the source and its own ink (Matt, 2026-11-08: easier to reason about than the joint solve)\n//   - outlets (Matt, 2026-11-14, as f_halftone): 1 = the composite, the sum of the plates clamped to 0..1; 2 to 4 = the\n//     plates, coverage * ink color.\n//     Alpha is the source's on all four.\n//   - bypass_gate = 1: the (zapped) source on all four outlets\n//   - non-finite input components are zapped to 0 first: abs(x) < 1e30 with switch() (NaN == NaN is TRUE on this GPU)\n// Params are named so none equals a jit.gl.pix attribute (`mode` would bind to the attribute: sep_mode).\nzap(xv) {\n    return switch(abs(xv) < 1e30, xv, 0);\n}\n\nParam ink1_h(15);\nParam ink1_s(1);\nParam ink1_l(0.5);\nParam ink2_h(180);\nParam ink2_s(1);\nParam ink2_l(0.3);\nParam ink3_h(267);\nParam ink3_s(1);\nParam ink3_l(0.5);\nParam n_inks(3);\nParam sep_mode(0);\nParam gain1(1);\nParam gain2(1);\nParam gain3(1);\nParam bypass_gate(0);\n\nxr = zap(sample(in1, norm).x);\nxg = zap(sample(in1, norm).y);\nxb = zap(sample(in1, norm).z);\nxa = zap(sample(in1, norm).w);\n\nact1 = switch(n_inks >= 0.5, 1, 0);\nact2 = switch(n_inks >= 1.5, 1, 0);\nact3 = switch(n_inks >= 2.5, 1, 0);\n\n// ink colors from H (degrees), S, L (Matt, 2026-11-14); hsl2rgb takes hue in 0..1. One call per ink, components taken\n// separately (vec(vec3, scalar) does not build a vec4, skills/jit-gen-codebox)\nrgb1 = hsl2rgb(vec(wrap(ink1_h / 360, 0, 1), clamp(ink1_s, 0, 1), clamp(ink1_l, 0, 1), 1));\nrgb2 = hsl2rgb(vec(wrap(ink2_h / 360, 0, 1), clamp(ink2_s, 0, 1), clamp(ink2_l, 0, 1), 1));\nrgb3 = hsl2rgb(vec(wrap(ink3_h / 360, 0, 1), clamp(ink3_s, 0, 1), clamp(ink3_l, 0, 1), 1));\nk1r = clamp(rgb1.x, 0, 1) * act1;\nk1g = clamp(rgb1.y, 0, 1) * act1;\nk1b = clamp(rgb1.z, 0, 1) * act1;\nk2r = clamp(rgb2.x, 0, 1) * act2;\nk2g = clamp(rgb2.y, 0, 1) * act2;\nk2b = clamp(rgb2.z, 0, 1) * act2;\nk3r = clamp(rgb3.x, 0, 1) * act3;\nk3g = clamp(rgb3.y, 0, 1) * act3;\nk3b = clamp(rgb3.z, 0, 1) * act3;\n\n// K^T K (symmetric) and the ridge\nm11 = k1r * k1r + k1g * k1g + k1b * k1b;\nm12 = k1r * k2r + k1g * k2g + k1b * k2b;\nm13 = k1r * k3r + k1g * k3g + k1b * k3b;\nm22 = k2r * k2r + k2g * k2g + k2b * k2b;\nm23 = k2r * k3r + k2g * k3g + k2b * k3b;\nm33 = k3r * k3r + k3g * k3g + k3b * k3b;\nlam = 0.0001 * (m11 + m22 + m33) / max(act1 + act2 + act3, 1) + 0.00000001;\nma = m11 + switch(act1 > 0.5, lam, 1);\nme = m22 + switch(act2 > 0.5, lam, 1);\nmi = m33 + switch(act3 > 0.5, lam, 1);\n\n// cofactors and determinant of [[ma, m12, m13], [m12, me, m23], [m13, m23, mi]]\nc11 = me * mi - m23 * m23;\nc12 = m13 * m23 - m12 * mi;\nc13 = m12 * m23 - m13 * me;\nc22 = ma * mi - m13 * m13;\nc23 = m12 * m13 - ma * m23;\nc33 = ma * me - m12 * m12;\ndet = ma * c11 + m12 * c12 + m13 * c13;\nidet = 1 / det;\n\n// K^T x\nt1 = k1r * xr + k1g * xg + k1b * xb;\nt2 = k2r * xr + k2g * xg + k2b * xb;\nt3 = k3r * xr + k3g * xg + k3b * xb;\nraw1 = (c11 * t1 + c12 * t2 + c13 * t3) * idet;\nraw2 = (c12 * t1 + c22 * t2 + c23 * t3) * idet;\nraw3 = (c13 * t1 + c23 * t2 + c33 * t3) * idet;\n\n// nearest: squared distance to each active ink and to black (an inactive ink is out of the race)\nd0 = xr * xr + xg * xg + xb * xb;\nd1 = switch(act1 > 0.5, (xr - k1r) * (xr - k1r) + (xg - k1g) * (xg - k1g) + (xb - k1b) * (xb - k1b), 1000000000);\nd2 = switch(act2 > 0.5, (xr - k2r) * (xr - k2r) + (xg - k2g) * (xg - k2g) + (xb - k2b) * (xb - k2b), 1000000000);\nd3 = switch(act3 > 0.5, (xr - k3r) * (xr - k3r) + (xg - k3g) * (xg - k3g) + (xb - k3b) * (xb - k3b), 1000000000);\nw1 = switch(d1 <= d2 && d1 <= d3 && d1 <= d0, 1, 0) * act1;\nw2 = switch(d2 < d1 && d2 <= d3 && d2 <= d0, 1, 0) * act2;\nw3 = switch(d3 < d1 && d3 < d2 && d3 <= d0, 1, 0) * act3;\n\nnear_flag = switch(sep_mode >= 0.5 && sep_mode < 1.5, 1, 0);\nproj_flag = switch(sep_mode >= 1.5, 1, 0);\npj1 = t1 / max(m11, 0.00000001);\npj2 = t2 / max(m22, 0.00000001);\npj3 = t3 / max(m33, 0.00000001);\ncv1 = clamp(mix(mix(raw1, w1, near_flag), pj1, proj_flag) * gain1, 0, 1) * act1;\ncv2 = clamp(mix(mix(raw2, w2, near_flag), pj2, proj_flag) * gain2, 0, 1) * act2;\ncv3 = clamp(mix(mix(raw3, w3, near_flag), pj3, proj_flag) * gain3, 0, 1) * act3;\n\np1r = cv1 * k1r;\np1g = cv1 * k1g;\np1b = cv1 * k1b;\np2r = cv2 * k2r;\np2g = cv2 * k2g;\np2b = cv2 * k2b;\np3r = cv3 * k3r;\np3g = cv3 * k3g;\np3b = cv3 * k3b;\n\nsr = clamp(p1r + p2r + p3r, 0, 1);\nsg = clamp(p1g + p2g + p3g, 0, 1);\nsb = clamp(p1b + p2b + p3b, 0, 1);\n\nout1 = vec(mix(sr, xr, bypass_gate), mix(sg, xg, bypass_gate), mix(sb, xb, bypass_gate), xa);\nout2 = vec(mix(p1r, xr, bypass_gate), mix(p1g, xg, bypass_gate), mix(p1b, xb, bypass_gate), xa);\nout3 = vec(mix(p2r, xr, bypass_gate), mix(p2g, xg, bypass_gate), mix(p2b, xb, bypass_gate), xa);\nout4 = vec(mix(p3r, xr, bypass_gate), mix(p3g, xg, bypass_gate), mix(p3b, xb, bypass_gate), xa);\n",
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
					"text": "jit.gl.pix vsynth @name #0_separate_pix @adapt 0 @dim 256 256 @type float32",
					"varname": "#0_separate_pix"
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
						1351.5,
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
						1131.5,
						260.0,
						300.0,
						118.0
					],
					"presentation": 1,
					"presentation_rect": [
						0.0,
						0.0,
						300.0,
						118.0
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
						1351.5,
						200.0,
						80.0,
						21.0
					],
					"presentation": 1,
					"presentation_rect": [
						10.5,
						0.0,
						46.0,
						21.0
					],
					"text": "Separate"
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
					"hint": "Takes texture",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						20.0,
						20.0,
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
					"hint": "Outputs texture",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						20.0,
						20.0,
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
						1131.5,
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
						1131.5,
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
						1131.5,
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
						1131.5,
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
						1131.5,
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
						1131.5,
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
						"int"
					],
					"param_connect": "#0_separate_pix::n_inks",
					"parameter_enable": 1,
					"patching_rect": [
						38.0,
						250.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						142.0,
						3.0,
						26.0,
						15.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								3.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "n_inks",
							"parameter_mmax": 3.0,
							"parameter_mmin": 1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "n_inks",
							"parameter_type": 1,
							"parameter_unitstyle": 0
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
						114.0,
						1.5,
						28.0,
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
					"hint": "Unmix: the best-fit coverage of all the inks together (exact round trip, but plates depend on each other). Nearest: each pixel wholly to its nearest ink, or to none when black is nearest. Project: each ink on its own, so a plate never depends on the other inks (the composite can overshoot)",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"",
						"",
						"float"
					],
					"param_connect": "#0_separate_pix::sep_mode",
					"parameter_enable": 1,
					"patching_rect": [
						102.0,
						250.0,
						60.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						60.0,
						3.0,
						52.0,
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
					"varname": "lbl_sep_mode",
					"hidden": 1
				}
			},
			{
				"box": {
					"id": "obj-26",
					"maxclass": "live.numbox",
					"fontname": "Ableton Sans Light",
					"hint": "Ink 1 hue, in degrees (0 red, 120 green, 240 blue)",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_separate_pix::ink1_h",
					"parameter_enable": 1,
					"patching_rect": [
						182.0,
						250.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						43.0,
						44.0,
						44.0,
						15.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								15.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "ink1_h",
							"parameter_mmax": 360.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "ink1_h",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"varname": "ink1_h"
				}
			},
			{
				"box": {
					"id": "obj-27",
					"maxclass": "attrui",
					"attr": "ink1_h",
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
					"text": "H 1",
					"textjustification": 1,
					"varname": "lbl_ink1_h",
					"hidden": 1
				}
			},
			{
				"box": {
					"id": "obj-29",
					"maxclass": "live.numbox",
					"fontname": "Ableton Sans Light",
					"hint": "Ink 1 saturation (0 is a gray)",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_separate_pix::ink1_s",
					"parameter_enable": 1,
					"patching_rect": [
						254.0,
						250.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						91.0,
						44.0,
						44.0,
						15.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								1.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "ink1_s",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "ink1_s",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"varname": "ink1_s"
				}
			},
			{
				"box": {
					"id": "obj-30",
					"maxclass": "attrui",
					"attr": "ink1_s",
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
					"text": "S 1",
					"textjustification": 1,
					"varname": "lbl_ink1_s",
					"hidden": 1
				}
			},
			{
				"box": {
					"id": "obj-32",
					"maxclass": "live.numbox",
					"fontname": "Ableton Sans Light",
					"hint": "Ink 1 lightness (0 black, 0.5 the full color, 1 white)",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_separate_pix::ink1_l",
					"parameter_enable": 1,
					"patching_rect": [
						326.0,
						250.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						139.0,
						44.0,
						44.0,
						15.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								0.5
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "ink1_l",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "ink1_l",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"varname": "ink1_l"
				}
			},
			{
				"box": {
					"id": "obj-33",
					"maxclass": "attrui",
					"attr": "ink1_l",
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
					"text": "L 1",
					"textjustification": 1,
					"varname": "lbl_ink1_l",
					"hidden": 1
				}
			},
			{
				"box": {
					"id": "obj-35",
					"maxclass": "live.numbox",
					"fontname": "Ableton Sans Light",
					"hint": "Plate 1 coverage gain. Above 1 saturates faster but never exceeds the ink color",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_separate_pix::gain1",
					"parameter_enable": 1,
					"patching_rect": [
						398.0,
						250.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						187.0,
						44.0,
						44.0,
						15.0
					],
					"saved_attribute_attributes": {
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
					"varname": "gain1"
				}
			},
			{
				"box": {
					"id": "obj-36",
					"maxclass": "attrui",
					"attr": "gain1",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						386.0,
						310.0,
						68.0,
						22.0
					],
					"style": ""
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
					"text": "Gain 1",
					"textjustification": 1,
					"varname": "lbl_gain1",
					"hidden": 1
				}
			},
			{
				"box": {
					"id": "obj-38",
					"maxclass": "live.numbox",
					"fontname": "Ableton Sans Light",
					"hint": "Ink 2 hue, in degrees (0 red, 120 green, 240 blue)",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_separate_pix::ink2_h",
					"parameter_enable": 1,
					"patching_rect": [
						470.0,
						250.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						43.0,
						68.0,
						44.0,
						15.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								180.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "ink2_h",
							"parameter_mmax": 360.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "ink2_h",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"varname": "ink2_h"
				}
			},
			{
				"box": {
					"id": "obj-39",
					"maxclass": "attrui",
					"attr": "ink2_h",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						458.0,
						310.0,
						68.0,
						22.0
					],
					"style": ""
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
					"text": "H 2",
					"textjustification": 1,
					"varname": "lbl_ink2_h",
					"hidden": 1
				}
			},
			{
				"box": {
					"id": "obj-41",
					"maxclass": "live.numbox",
					"fontname": "Ableton Sans Light",
					"hint": "Ink 2 saturation (0 is a gray)",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_separate_pix::ink2_s",
					"parameter_enable": 1,
					"patching_rect": [
						542.0,
						250.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						91.0,
						68.0,
						44.0,
						15.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								1.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "ink2_s",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "ink2_s",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"varname": "ink2_s"
				}
			},
			{
				"box": {
					"id": "obj-42",
					"maxclass": "attrui",
					"attr": "ink2_s",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						530.0,
						310.0,
						68.0,
						22.0
					],
					"style": ""
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
					"text": "S 2",
					"textjustification": 1,
					"varname": "lbl_ink2_s",
					"hidden": 1
				}
			},
			{
				"box": {
					"id": "obj-44",
					"maxclass": "live.numbox",
					"fontname": "Ableton Sans Light",
					"hint": "Ink 2 lightness (0 black, 0.5 the full color, 1 white)",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_separate_pix::ink2_l",
					"parameter_enable": 1,
					"patching_rect": [
						614.0,
						250.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						139.0,
						68.0,
						44.0,
						15.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								0.3
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "ink2_l",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "ink2_l",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"varname": "ink2_l"
				}
			},
			{
				"box": {
					"id": "obj-45",
					"maxclass": "attrui",
					"attr": "ink2_l",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						602.0,
						310.0,
						68.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-46",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						611.0,
						180.0,
						50.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						103.5,
						82.0,
						50.0,
						18.0
					],
					"text": "L 2",
					"textjustification": 1,
					"varname": "lbl_ink2_l",
					"hidden": 1
				}
			},
			{
				"box": {
					"id": "obj-47",
					"maxclass": "live.numbox",
					"fontname": "Ableton Sans Light",
					"hint": "Plate 2 coverage gain. Above 1 saturates faster but never exceeds the ink color",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_separate_pix::gain2",
					"parameter_enable": 1,
					"patching_rect": [
						686.0,
						250.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						187.0,
						68.0,
						44.0,
						15.0
					],
					"saved_attribute_attributes": {
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
					"varname": "gain2"
				}
			},
			{
				"box": {
					"id": "obj-48",
					"maxclass": "attrui",
					"attr": "gain2",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						674.0,
						310.0,
						68.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-49",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						683.0,
						180.0,
						50.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						140.5,
						82.0,
						50.0,
						18.0
					],
					"text": "Gain 2",
					"textjustification": 1,
					"varname": "lbl_gain2",
					"hidden": 1
				}
			},
			{
				"box": {
					"id": "obj-50",
					"maxclass": "live.numbox",
					"fontname": "Ableton Sans Light",
					"hint": "Ink 3 hue, in degrees (0 red, 120 green, 240 blue)",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_separate_pix::ink3_h",
					"parameter_enable": 1,
					"patching_rect": [
						758.0,
						250.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						43.0,
						92.0,
						44.0,
						15.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								267.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "ink3_h",
							"parameter_mmax": 360.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "ink3_h",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"varname": "ink3_h"
				}
			},
			{
				"box": {
					"id": "obj-51",
					"maxclass": "attrui",
					"attr": "ink3_h",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						746.0,
						310.0,
						68.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-52",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						755.0,
						180.0,
						50.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						-7.5,
						144.0,
						50.0,
						18.0
					],
					"text": "H 3",
					"textjustification": 1,
					"varname": "lbl_ink3_h",
					"hidden": 1
				}
			},
			{
				"box": {
					"id": "obj-53",
					"maxclass": "live.numbox",
					"fontname": "Ableton Sans Light",
					"hint": "Ink 3 saturation (0 is a gray)",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_separate_pix::ink3_s",
					"parameter_enable": 1,
					"patching_rect": [
						830.0,
						250.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						91.0,
						92.0,
						44.0,
						15.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								1.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "ink3_s",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "ink3_s",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"varname": "ink3_s"
				}
			},
			{
				"box": {
					"id": "obj-54",
					"maxclass": "attrui",
					"attr": "ink3_s",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						818.0,
						310.0,
						68.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-55",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						827.0,
						180.0,
						50.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						29.5,
						144.0,
						50.0,
						18.0
					],
					"text": "S 3",
					"textjustification": 1,
					"varname": "lbl_ink3_s",
					"hidden": 1
				}
			},
			{
				"box": {
					"id": "obj-56",
					"maxclass": "live.numbox",
					"fontname": "Ableton Sans Light",
					"hint": "Ink 3 lightness (0 black, 0.5 the full color, 1 white)",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_separate_pix::ink3_l",
					"parameter_enable": 1,
					"patching_rect": [
						902.0,
						250.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						139.0,
						92.0,
						44.0,
						15.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								0.5
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "ink3_l",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "ink3_l",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"varname": "ink3_l"
				}
			},
			{
				"box": {
					"id": "obj-57",
					"maxclass": "attrui",
					"attr": "ink3_l",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						890.0,
						310.0,
						68.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-58",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						899.0,
						180.0,
						50.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						66.5,
						144.0,
						50.0,
						18.0
					],
					"text": "L 3",
					"textjustification": 1,
					"varname": "lbl_ink3_l",
					"hidden": 1
				}
			},
			{
				"box": {
					"id": "obj-59",
					"maxclass": "live.numbox",
					"fontname": "Ableton Sans Light",
					"hint": "Plate 3 coverage gain. Above 1 saturates faster but never exceeds the ink color",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_separate_pix::gain3",
					"parameter_enable": 1,
					"patching_rect": [
						974.0,
						250.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						187.0,
						92.0,
						44.0,
						15.0
					],
					"saved_attribute_attributes": {
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
					"varname": "gain3"
				}
			},
			{
				"box": {
					"id": "obj-60",
					"maxclass": "attrui",
					"attr": "gain3",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						962.0,
						310.0,
						68.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-61",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						971.0,
						180.0,
						50.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						103.5,
						144.0,
						50.0,
						18.0
					],
					"text": "Gain 3",
					"textjustification": 1,
					"varname": "lbl_gain3",
					"hidden": 1
				}
			},
			{
				"box": {
					"id": "obj-62",
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
						1351.5,
						130.0,
						18.0,
						12.0
					],
					"presentation_rect": [
						278.0,
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
					"id": "obj-63",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1351.5,
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
						30.0,
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
						170.0,
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
						170.0,
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
					"id": "obj-raw-head0",
					"maxclass": "comment",
					"text": "H",
					"patching_rect": [
						170.0,
						542.0,
						50.0,
						18.0
					],
					"presentation_rect": [
						41.0,
						26.0,
						48.0,
						16.0
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"textjustification": 1,
					"numinlets": 1,
					"numoutlets": 0,
					"outlettype": [],
					"presentation": 1
				}
			},
			{
				"box": {
					"id": "obj-raw-head1",
					"maxclass": "comment",
					"text": "S",
					"patching_rect": [
						170.0,
						564.0,
						50.0,
						18.0
					],
					"presentation_rect": [
						89.0,
						26.0,
						48.0,
						16.0
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"textjustification": 1,
					"numinlets": 1,
					"numoutlets": 0,
					"outlettype": [],
					"presentation": 1
				}
			},
			{
				"box": {
					"id": "obj-raw-head2",
					"maxclass": "comment",
					"text": "L",
					"patching_rect": [
						170.0,
						586.0,
						50.0,
						18.0
					],
					"presentation_rect": [
						137.0,
						26.0,
						48.0,
						16.0
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"textjustification": 1,
					"numinlets": 1,
					"numoutlets": 0,
					"outlettype": [],
					"presentation": 1
				}
			},
			{
				"box": {
					"id": "obj-raw-head3",
					"maxclass": "comment",
					"text": "Gain",
					"patching_rect": [
						170.0,
						608.0,
						50.0,
						18.0
					],
					"presentation_rect": [
						185.0,
						26.0,
						48.0,
						16.0
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"textjustification": 1,
					"numinlets": 1,
					"numoutlets": 0,
					"outlettype": [],
					"presentation": 1
				}
			},
			{
				"box": {
					"id": "obj-raw-head4",
					"maxclass": "comment",
					"text": "Color",
					"patching_rect": [
						170.0,
						630.0,
						50.0,
						18.0
					],
					"presentation_rect": [
						238.0,
						26.0,
						56.0,
						16.0
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"textjustification": 1,
					"numinlets": 1,
					"numoutlets": 0,
					"outlettype": [],
					"presentation": 1
				}
			},
			{
				"box": {
					"id": "obj-raw-row1",
					"maxclass": "comment",
					"text": "1",
					"varname": "lbl_ink1",
					"patching_rect": [
						230.0,
						542.0,
						30.0,
						18.0
					],
					"presentation_rect": [
						15.0,
						43.0,
						24.0,
						16.0
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"textjustification": 1,
					"numinlets": 1,
					"numoutlets": 0,
					"outlettype": [],
					"presentation": 1
				}
			},
			{
				"box": {
					"id": "obj-raw-row2",
					"maxclass": "comment",
					"text": "2",
					"varname": "lbl_ink2",
					"patching_rect": [
						230.0,
						564.0,
						30.0,
						18.0
					],
					"presentation_rect": [
						15.0,
						67.0,
						24.0,
						16.0
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"textjustification": 1,
					"numinlets": 1,
					"numoutlets": 0,
					"outlettype": [],
					"presentation": 1
				}
			},
			{
				"box": {
					"id": "obj-raw-row3",
					"maxclass": "comment",
					"text": "3",
					"varname": "lbl_ink3",
					"patching_rect": [
						230.0,
						586.0,
						30.0,
						18.0
					],
					"presentation_rect": [
						15.0,
						91.0,
						24.0,
						16.0
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"textjustification": 1,
					"numinlets": 1,
					"numoutlets": 0,
					"outlettype": [],
					"presentation": 1
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
						350.0,
						632.0,
						60.0,
						30.0
					],
					"presentation": 1,
					"presentation_rect": [
						238.0,
						42.0,
						56.0,
						19.0
					]
				}
			},
			{
				"box": {
					"id": "obj-raw-div1",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"float"
					],
					"patching_rect": [
						350.0,
						542.0,
						50.0,
						22.0
					],
					"text": "/ 360."
				}
			},
			{
				"box": {
					"id": "obj-raw-pak1",
					"maxclass": "newobj",
					"numinlets": 3,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						350.0,
						572.0,
						80.0,
						22.0
					],
					"text": "pak 0. 0. 0."
				}
			},
			{
				"box": {
					"id": "obj-raw-sethsl1",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						350.0,
						602.0,
						90.0,
						22.0
					],
					"text": "prepend sethsl"
				}
			},
			{
				"box": {
					"id": "obj-raw-ts1",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"float",
						"float"
					],
					"patching_rect": [
						450.0,
						542.0,
						40.0,
						22.0
					],
					"text": "t f f"
				}
			},
			{
				"box": {
					"id": "obj-raw-sat1",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						450.0,
						602.0,
						110.0,
						22.0
					],
					"text": "prepend saturation"
				}
			},
			{
				"box": {
					"id": "obj-raw-zl1",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						350.0,
						672.0,
						70.0,
						22.0
					],
					"text": "zl.slice 3"
				}
			},
			{
				"box": {
					"id": "obj-raw-tr1",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						350.0,
						702.0,
						50.0,
						22.0
					],
					"text": "t l l"
				}
			},
			{
				"box": {
					"id": "obj-raw-eh1",
					"maxclass": "newobj",
					"numinlets": 3,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						550.0,
						642.0,
						300.0,
						22.0
					],
					"text": "expr ((max(max($f1\\, $f2)\\, $f3) - min(min($f1\\, $f2)\\, $f3)) > 0.) * 60. * ((max(max($f1\\, $f2)\\, $f3) == $f1) * ((($f2 - $f3) / ((max(max($f1\\, $f2)\\, $f3) - min(min($f1\\, $f2)\\, $f3)) + ((max(max($f1\\, $f2)\\, $f3) - min(min($f1\\, $f2)\\, $f3)) == 0.))) + 6. * ((($f2 - $f3) / ((max(max($f1\\, $f2)\\, $f3) - min(min($f1\\, $f2)\\, $f3)) + ((max(max($f1\\, $f2)\\, $f3) - min(min($f1\\, $f2)\\, $f3)) == 0.))) < 0.)) + (1. - (max(max($f1\\, $f2)\\, $f3) == $f1)) * (max(max($f1\\, $f2)\\, $f3) == $f2) * (($f3 - $f1) / ((max(max($f1\\, $f2)\\, $f3) - min(min($f1\\, $f2)\\, $f3)) + ((max(max($f1\\, $f2)\\, $f3) - min(min($f1\\, $f2)\\, $f3)) == 0.)) + 2.) + (1. - (max(max($f1\\, $f2)\\, $f3) == $f1)) * (1. - (max(max($f1\\, $f2)\\, $f3) == $f2)) * (($f1 - $f2) / ((max(max($f1\\, $f2)\\, $f3) - min(min($f1\\, $f2)\\, $f3)) + ((max(max($f1\\, $f2)\\, $f3) - min(min($f1\\, $f2)\\, $f3)) == 0.)) + 4.)) - ((max(max($f1\\, $f2)\\, $f3) - min(min($f1\\, $f2)\\, $f3)) == 0.)"
				}
			},
			{
				"box": {
					"id": "obj-raw-split1",
					"maxclass": "newobj",
					"numinlets": 3,
					"numoutlets": 2,
					"outlettype": [
						"float",
						"float"
					],
					"patching_rect": [
						550.0,
						672.0,
						90.0,
						22.0
					],
					"text": "split 0. 360."
				}
			},
			{
				"box": {
					"id": "obj-raw-el1",
					"maxclass": "newobj",
					"numinlets": 3,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						550.0,
						732.0,
						300.0,
						22.0
					],
					"text": "expr (max(max($f1\\, $f2)\\, $f3) + min(min($f1\\, $f2)\\, $f3)) / 2."
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
						350.0,
						832.0,
						60.0,
						30.0
					],
					"presentation": 1,
					"presentation_rect": [
						238.0,
						66.0,
						56.0,
						19.0
					]
				}
			},
			{
				"box": {
					"id": "obj-raw-div2",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"float"
					],
					"patching_rect": [
						350.0,
						742.0,
						50.0,
						22.0
					],
					"text": "/ 360."
				}
			},
			{
				"box": {
					"id": "obj-raw-pak2",
					"maxclass": "newobj",
					"numinlets": 3,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						350.0,
						772.0,
						80.0,
						22.0
					],
					"text": "pak 0. 0. 0."
				}
			},
			{
				"box": {
					"id": "obj-raw-sethsl2",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						350.0,
						802.0,
						90.0,
						22.0
					],
					"text": "prepend sethsl"
				}
			},
			{
				"box": {
					"id": "obj-raw-ts2",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"float",
						"float"
					],
					"patching_rect": [
						450.0,
						742.0,
						40.0,
						22.0
					],
					"text": "t f f"
				}
			},
			{
				"box": {
					"id": "obj-raw-sat2",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						450.0,
						802.0,
						110.0,
						22.0
					],
					"text": "prepend saturation"
				}
			},
			{
				"box": {
					"id": "obj-raw-zl2",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						350.0,
						872.0,
						70.0,
						22.0
					],
					"text": "zl.slice 3"
				}
			},
			{
				"box": {
					"id": "obj-raw-tr2",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						350.0,
						902.0,
						50.0,
						22.0
					],
					"text": "t l l"
				}
			},
			{
				"box": {
					"id": "obj-raw-eh2",
					"maxclass": "newobj",
					"numinlets": 3,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						550.0,
						842.0,
						300.0,
						22.0
					],
					"text": "expr ((max(max($f1\\, $f2)\\, $f3) - min(min($f1\\, $f2)\\, $f3)) > 0.) * 60. * ((max(max($f1\\, $f2)\\, $f3) == $f1) * ((($f2 - $f3) / ((max(max($f1\\, $f2)\\, $f3) - min(min($f1\\, $f2)\\, $f3)) + ((max(max($f1\\, $f2)\\, $f3) - min(min($f1\\, $f2)\\, $f3)) == 0.))) + 6. * ((($f2 - $f3) / ((max(max($f1\\, $f2)\\, $f3) - min(min($f1\\, $f2)\\, $f3)) + ((max(max($f1\\, $f2)\\, $f3) - min(min($f1\\, $f2)\\, $f3)) == 0.))) < 0.)) + (1. - (max(max($f1\\, $f2)\\, $f3) == $f1)) * (max(max($f1\\, $f2)\\, $f3) == $f2) * (($f3 - $f1) / ((max(max($f1\\, $f2)\\, $f3) - min(min($f1\\, $f2)\\, $f3)) + ((max(max($f1\\, $f2)\\, $f3) - min(min($f1\\, $f2)\\, $f3)) == 0.)) + 2.) + (1. - (max(max($f1\\, $f2)\\, $f3) == $f1)) * (1. - (max(max($f1\\, $f2)\\, $f3) == $f2)) * (($f1 - $f2) / ((max(max($f1\\, $f2)\\, $f3) - min(min($f1\\, $f2)\\, $f3)) + ((max(max($f1\\, $f2)\\, $f3) - min(min($f1\\, $f2)\\, $f3)) == 0.)) + 4.)) - ((max(max($f1\\, $f2)\\, $f3) - min(min($f1\\, $f2)\\, $f3)) == 0.)"
				}
			},
			{
				"box": {
					"id": "obj-raw-split2",
					"maxclass": "newobj",
					"numinlets": 3,
					"numoutlets": 2,
					"outlettype": [
						"float",
						"float"
					],
					"patching_rect": [
						550.0,
						872.0,
						90.0,
						22.0
					],
					"text": "split 0. 360."
				}
			},
			{
				"box": {
					"id": "obj-raw-el2",
					"maxclass": "newobj",
					"numinlets": 3,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						550.0,
						932.0,
						300.0,
						22.0
					],
					"text": "expr (max(max($f1\\, $f2)\\, $f3) + min(min($f1\\, $f2)\\, $f3)) / 2."
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
						350.0,
						1032.0,
						60.0,
						30.0
					],
					"presentation": 1,
					"presentation_rect": [
						238.0,
						90.0,
						56.0,
						19.0
					]
				}
			},
			{
				"box": {
					"id": "obj-raw-div3",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"float"
					],
					"patching_rect": [
						350.0,
						942.0,
						50.0,
						22.0
					],
					"text": "/ 360."
				}
			},
			{
				"box": {
					"id": "obj-raw-pak3",
					"maxclass": "newobj",
					"numinlets": 3,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						350.0,
						972.0,
						80.0,
						22.0
					],
					"text": "pak 0. 0. 0."
				}
			},
			{
				"box": {
					"id": "obj-raw-sethsl3",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						350.0,
						1002.0,
						90.0,
						22.0
					],
					"text": "prepend sethsl"
				}
			},
			{
				"box": {
					"id": "obj-raw-ts3",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"float",
						"float"
					],
					"patching_rect": [
						450.0,
						942.0,
						40.0,
						22.0
					],
					"text": "t f f"
				}
			},
			{
				"box": {
					"id": "obj-raw-sat3",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						450.0,
						1002.0,
						110.0,
						22.0
					],
					"text": "prepend saturation"
				}
			},
			{
				"box": {
					"id": "obj-raw-zl3",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						350.0,
						1072.0,
						70.0,
						22.0
					],
					"text": "zl.slice 3"
				}
			},
			{
				"box": {
					"id": "obj-raw-tr3",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						350.0,
						1102.0,
						50.0,
						22.0
					],
					"text": "t l l"
				}
			},
			{
				"box": {
					"id": "obj-raw-eh3",
					"maxclass": "newobj",
					"numinlets": 3,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						550.0,
						1042.0,
						300.0,
						22.0
					],
					"text": "expr ((max(max($f1\\, $f2)\\, $f3) - min(min($f1\\, $f2)\\, $f3)) > 0.) * 60. * ((max(max($f1\\, $f2)\\, $f3) == $f1) * ((($f2 - $f3) / ((max(max($f1\\, $f2)\\, $f3) - min(min($f1\\, $f2)\\, $f3)) + ((max(max($f1\\, $f2)\\, $f3) - min(min($f1\\, $f2)\\, $f3)) == 0.))) + 6. * ((($f2 - $f3) / ((max(max($f1\\, $f2)\\, $f3) - min(min($f1\\, $f2)\\, $f3)) + ((max(max($f1\\, $f2)\\, $f3) - min(min($f1\\, $f2)\\, $f3)) == 0.))) < 0.)) + (1. - (max(max($f1\\, $f2)\\, $f3) == $f1)) * (max(max($f1\\, $f2)\\, $f3) == $f2) * (($f3 - $f1) / ((max(max($f1\\, $f2)\\, $f3) - min(min($f1\\, $f2)\\, $f3)) + ((max(max($f1\\, $f2)\\, $f3) - min(min($f1\\, $f2)\\, $f3)) == 0.)) + 2.) + (1. - (max(max($f1\\, $f2)\\, $f3) == $f1)) * (1. - (max(max($f1\\, $f2)\\, $f3) == $f2)) * (($f1 - $f2) / ((max(max($f1\\, $f2)\\, $f3) - min(min($f1\\, $f2)\\, $f3)) + ((max(max($f1\\, $f2)\\, $f3) - min(min($f1\\, $f2)\\, $f3)) == 0.)) + 4.)) - ((max(max($f1\\, $f2)\\, $f3) - min(min($f1\\, $f2)\\, $f3)) == 0.)"
				}
			},
			{
				"box": {
					"id": "obj-raw-split3",
					"maxclass": "newobj",
					"numinlets": 3,
					"numoutlets": 2,
					"outlettype": [
						"float",
						"float"
					],
					"patching_rect": [
						550.0,
						1072.0,
						90.0,
						22.0
					],
					"text": "split 0. 360."
				}
			},
			{
				"box": {
					"id": "obj-raw-el3",
					"maxclass": "newobj",
					"numinlets": 3,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						550.0,
						1132.0,
						300.0,
						22.0
					],
					"text": "expr (max(max($f1\\, $f2)\\, $f3) + min(min($f1\\, $f2)\\, $f3)) / 2."
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
						"obj-62",
						0
					],
					"destination": [
						"obj-63",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-63",
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
						"obj-35",
						0
					],
					"destination": [
						"obj-36",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-36",
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
						"obj-38",
						0
					],
					"destination": [
						"obj-39",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-39",
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
						"obj-41",
						0
					],
					"destination": [
						"obj-42",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-42",
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
						8
					],
					"destination": [
						"obj-44",
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
						"obj-4",
						9
					],
					"destination": [
						"obj-47",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-47",
						0
					],
					"destination": [
						"obj-48",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-48",
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
						10
					],
					"destination": [
						"obj-50",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-50",
						0
					],
					"destination": [
						"obj-51",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-51",
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
						11
					],
					"destination": [
						"obj-53",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-53",
						0
					],
					"destination": [
						"obj-54",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-54",
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
						12
					],
					"destination": [
						"obj-56",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-56",
						0
					],
					"destination": [
						"obj-57",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-57",
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
						13
					],
					"destination": [
						"obj-59",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-59",
						0
					],
					"destination": [
						"obj-60",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-60",
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
						"obj-26",
						0
					],
					"destination": [
						"obj-raw-div1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-div1",
						0
					],
					"destination": [
						"obj-raw-pak1",
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
						"obj-raw-ts1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-ts1",
						1
					],
					"destination": [
						"obj-raw-sat1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-sat1",
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
						"obj-raw-ts1",
						0
					],
					"destination": [
						"obj-raw-pak1",
						1
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
						"obj-raw-pak1",
						2
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-pak1",
						0
					],
					"destination": [
						"obj-raw-sethsl1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-sethsl1",
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
						"obj-raw-zl1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-zl1",
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
						"obj-raw-eh1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-eh1",
						0
					],
					"destination": [
						"obj-raw-split1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-split1",
						0
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
						"obj-raw-tr1",
						0
					],
					"destination": [
						"obj-raw-el1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-el1",
						0
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
						"obj-38",
						0
					],
					"destination": [
						"obj-raw-div2",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-div2",
						0
					],
					"destination": [
						"obj-raw-pak2",
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
						"obj-raw-ts2",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-ts2",
						1
					],
					"destination": [
						"obj-raw-sat2",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-sat2",
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
						"obj-raw-ts2",
						0
					],
					"destination": [
						"obj-raw-pak2",
						1
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
						"obj-raw-pak2",
						2
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-pak2",
						0
					],
					"destination": [
						"obj-raw-sethsl2",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-sethsl2",
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
						"obj-raw-zl2",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-zl2",
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
						"obj-raw-eh2",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-eh2",
						0
					],
					"destination": [
						"obj-raw-split2",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-split2",
						0
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
						"obj-raw-tr2",
						0
					],
					"destination": [
						"obj-raw-el2",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-el2",
						0
					],
					"destination": [
						"obj-44",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-50",
						0
					],
					"destination": [
						"obj-raw-div3",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-div3",
						0
					],
					"destination": [
						"obj-raw-pak3",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-53",
						0
					],
					"destination": [
						"obj-raw-ts3",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-ts3",
						1
					],
					"destination": [
						"obj-raw-sat3",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-sat3",
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
						"obj-raw-ts3",
						0
					],
					"destination": [
						"obj-raw-pak3",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-56",
						0
					],
					"destination": [
						"obj-raw-pak3",
						2
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-pak3",
						0
					],
					"destination": [
						"obj-raw-sethsl3",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-sethsl3",
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
						"obj-raw-zl3",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-zl3",
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
						"obj-raw-eh3",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-eh3",
						0
					],
					"destination": [
						"obj-raw-split3",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-split3",
						0
					],
					"destination": [
						"obj-50",
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
						"obj-raw-el3",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-el3",
						0
					],
					"destination": [
						"obj-56",
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
				"ink1_h",
				"ink1_h",
				0
			],
			"obj-29": [
				"ink1_s",
				"ink1_s",
				0
			],
			"obj-32": [
				"ink1_l",
				"ink1_l",
				0
			],
			"obj-35": [
				"gain1",
				"gain1",
				0
			],
			"obj-38": [
				"ink2_h",
				"ink2_h",
				0
			],
			"obj-41": [
				"ink2_s",
				"ink2_s",
				0
			],
			"obj-44": [
				"ink2_l",
				"ink2_l",
				0
			],
			"obj-47": [
				"gain2",
				"gain2",
				0
			],
			"obj-50": [
				"ink3_h",
				"ink3_h",
				0
			],
			"obj-53": [
				"ink3_s",
				"ink3_s",
				0
			],
			"obj-56": [
				"ink3_l",
				"ink3_l",
				0
			],
			"obj-59": [
				"gain3",
				"gain3",
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