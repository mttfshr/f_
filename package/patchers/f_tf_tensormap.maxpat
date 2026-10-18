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
					"comment": "tensor (raw Jxx, Jxy, Jyy)",
					"index": 0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						30.0,
						602.0,
						30.0,
						30.0
					],
					"tricolor": [
						0.85,
						0.55,
						0.2,
						1.0
					],
					"hint": "Raw structure tensor: R = Jxx*strength, G = Jxy*strength*0.5 + 0.5, B = Jyy*strength, A = 1. Sign-safe: no angle doubling. Neutral (zero tensor) = (0, 0.5, 0, 1)."
				}
			},
			{
				"box": {
					"id": "obj-201",
					"maxclass": "outlet",
					"comment": "tensor packed (cos2t, sin2t, trace, coherence)",
					"index": 0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						100.0,
						602.0,
						30.0,
						30.0
					],
					"tricolor": [
						0.85,
						0.35,
						0.55,
						1.0
					],
					"hint": "Convenience outlet: R = cos(2 theta)*0.5+0.5, G = sin(2 theta)*0.5+0.5, B = clamp(trace*strength), A = coherence (0-1, gain-free). Angle-DOUBLED: do not feed R/G to sign-sensitive consumers (warp, advect, caustic, fluid, potential, seeds); decode theta = 0.5*atan2 first. Neutral = (0.5, 0.5, 0, 0)."
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
					"numoutlets": 4,
					"outlettype": [
						"",
						"",
						"",
						""
					],
					"patching_rect": [
						56.5,
						204.0,
						295.0,
						22.0
					],
					"text": "route strength radius width height"
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
									"code": "// Stage A (f_tf_tensormap): Rec.601 luma -> 3x3 Sobel -> per-pixel\n// gradient products. in1 = source. Mirrors tests/test_tf_tensormap.py\n// stage_a (nearest taps at one-texel offsets, clamp-to-edge). Sobel kernel\n// from .specify/stable/f_vf_sobel/spec.md.\n//\n// Outputs are RAW, unbounded float32 (pix_type float32 required on this\n// node): out1 = (gx*gx, gx*gy, gy*gy, 1). gx*gy is signed -- no offset.\n//\n// The module bypass is a Param on stage_c only (bypass_gate); stages A and B\n// keep running under bypass by design (nothing downstream reads them).\n// All sample components are read inline -- never store-then-slice.\n\n// Frame size in pixels as Params: `dim` reads 1 inside live Vsynth\n// jit.gl.pix objects (probe patch tf_probe.maxpat, 2026-10-16), so 1/dim.x\n// gave a zero offset and a zero gradient. Set width/height to the render\n// size so one tap step is exactly one square pixel.\nParam width(640.0);\nParam height(480.0);\ndx = 1.0 / width;\ndy = 1.0 / height;\n// Explicit edge clamp: the bench GPU WRAPS out-of-range coordinates\n// (tf_tensormap diag 2026-10-16), so clamp-to-edge is done here, in the\n// shader, to the first/last texel center -- independent of texture wrap.\nxl = clamp(norm.x - dx, 0.5*dx, 1.0 - 0.5*dx);\nxr = clamp(norm.x + dx, 0.5*dx, 1.0 - 0.5*dx);\nyt = clamp(norm.y - dy, 0.5*dy, 1.0 - 0.5*dy);\nyb = clamp(norm.y + dy, 0.5*dy, 1.0 - 0.5*dy);\n\nl_tl = nearest(in1, vec(xl, yt)).x*0.299 + nearest(in1, vec(xl, yt)).y*0.587 + nearest(in1, vec(xl, yt)).z*0.114;\nl_tc = nearest(in1, vec(norm.x, yt)).x*0.299 + nearest(in1, vec(norm.x, yt)).y*0.587 + nearest(in1, vec(norm.x, yt)).z*0.114;\nl_tr = nearest(in1, vec(xr, yt)).x*0.299 + nearest(in1, vec(xr, yt)).y*0.587 + nearest(in1, vec(xr, yt)).z*0.114;\nl_ml = nearest(in1, vec(xl, norm.y)).x*0.299      + nearest(in1, vec(xl, norm.y)).y*0.587      + nearest(in1, vec(xl, norm.y)).z*0.114;\nl_mr = nearest(in1, vec(xr, norm.y)).x*0.299      + nearest(in1, vec(xr, norm.y)).y*0.587      + nearest(in1, vec(xr, norm.y)).z*0.114;\nl_bl = nearest(in1, vec(xl, yb)).x*0.299 + nearest(in1, vec(xl, yb)).y*0.587 + nearest(in1, vec(xl, yb)).z*0.114;\nl_bc = nearest(in1, vec(norm.x, yb)).x*0.299 + nearest(in1, vec(norm.x, yb)).y*0.587 + nearest(in1, vec(norm.x, yb)).z*0.114;\nl_br = nearest(in1, vec(xr, yb)).x*0.299 + nearest(in1, vec(xr, yb)).y*0.587 + nearest(in1, vec(xr, yb)).z*0.114;\n\ngx = (l_tr - l_tl) + 2.0*(l_mr - l_ml) + (l_br - l_bl);\ngy = (l_bl + 2.0*l_bc + l_br) - (l_tl + 2.0*l_tc + l_tr);\n\nout1 = vec(gx*gx, gx*gy, gy*gy, 1.0);\n",
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
						30.0,
						380.0,
						200.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_tm_stage_a @type float32",
					"varname": "#0_tm_stage_a"
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
									"code": "// Stage B_h (f_tf_tensormap): horizontal bounded-loop box smooth of the\n// three gradient products. in1 = stage A out1 (raw float32).\n// Loop runs to the compile-time R_MAX (16, provisional -- T016/T017 pick\n// the real value); tap i contributes only if |i| <= radius, via\n// step(abs(i), radius). Result is divided by the ACTUAL tap count, so\n// radius 0 is an identity pass. Cost scales with R_MAX, not live radius.\n// Mirrors tests/test_tf_tensormap.py stage_b (axis 0). Edge taps are clamped in-shader (bench GPU wraps by default).\n// Accumulators are scalar and pre-declared above the loop (GenExpr scope).\nParam radius(3.0);\nParam width(640.0);   // frame width in pixels; `dim` reads 1 live, so it is a Param\n\ndx = 1.0 / width;\nacc_xx = 0.0;\nacc_xy = 0.0;\nacc_yy = 0.0;\ncnt = 0.0;\nfor (i = -16; i <= 16; i += 1) {\n    wt = step(abs(i), radius);\n    px = clamp(norm.x + i*dx, 0.5*dx, 1.0 - 0.5*dx);\n    acc_xx = acc_xx + wt * nearest(in1, vec(px, norm.y)).x;\n    acc_xy = acc_xy + wt * nearest(in1, vec(px, norm.y)).y;\n    acc_yy = acc_yy + wt * nearest(in1, vec(px, norm.y)).z;\n    cnt = cnt + wt;\n}\ninv = 1.0 / max(cnt, 1.0);\n\nout1 = vec(acc_xx*inv, acc_xy*inv, acc_yy*inv, 1.0);\n",
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
						30.0,
						430.0,
						200.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_tm_stage_b_h @type float32",
					"varname": "#0_tm_stage_b_h"
				}
			},
			{
				"box": {
					"id": "obj-51",
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
									"code": "// Stage B_v (f_tf_tensormap): vertical bounded-loop box smooth. in1 =\n// stage B_h out1. Same structure as stage_b_h; see its header. Mirrors\n// tests/test_tf_tensormap.py stage_b (axis 1). Output is the smoothed\n// structure tensor (Jxx, Jxy, Jyy), raw float32.\nParam radius(3.0);\nParam height(480.0);  // frame height in pixels; `dim` reads 1 live, so it is a Param\n\ndy = 1.0 / height;\nacc_xx = 0.0;\nacc_xy = 0.0;\nacc_yy = 0.0;\ncnt = 0.0;\nfor (i = -16; i <= 16; i += 1) {\n    wt = step(abs(i), radius);\n    py = clamp(norm.y + i*dy, 0.5*dy, 1.0 - 0.5*dy);\n    acc_xx = acc_xx + wt * nearest(in1, vec(norm.x, py)).x;\n    acc_xy = acc_xy + wt * nearest(in1, vec(norm.x, py)).y;\n    acc_yy = acc_yy + wt * nearest(in1, vec(norm.x, py)).z;\n    cnt = cnt + wt;\n}\ninv = 1.0 / max(cnt, 1.0);\n\nout1 = vec(acc_xx*inv, acc_xy*inv, acc_yy*inv, 1.0);\n",
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
						30.0,
						480.0,
						200.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_tm_stage_b_v @type float32",
					"varname": "#0_tm_stage_b_v"
				}
			},
			{
				"box": {
					"id": "obj-52",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
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
									"code": "// Stage C (f_tf_tensormap): closed-form 2x2 eigen of the smoothed tensor\n// and both outlet encodings. in1 = stage B_v out1 (Jxx, Jxy, Jyy raw).\n// Mirrors tests/test_tf_tensormap.py stage_c.\n//\n//   out1 (module outlet 0, raw tensor):\n//        (Jxx*strength, Jxy*strength*0.5 + 0.5, Jyy*strength, 1)\n//   out2 (module outlet 1, packed convenience):\n//        (cos2t*0.5+0.5, sin2t*0.5+0.5, clamp(trace*strength), coherence)\n//        coherence = sqrt((Jxx-Jyy)^2 + 4 Jxy^2) / trace, in [0,1], no gain\n//   Isotropic pixels (trace < eps_trace): out2 = (0.5, 0.5, 0, 0).\n//   Direction-undefined pixels (root < eps_trace): R=G=0.5, B and A real.\n//   bypass_gate (module bypass, bypass_mode \"param\"; NOT the native @bypass,\n//   which would skip the shader and flip secondary outlets): both outlets\n//   forced to the zero-tensor neutral values.\n// eps_trace is provisional (T019 sets it from the measured noise floor).\n// pix_type float32 required. Outlet wiring + bypass supplied via\n// definition.py raw_lines (f_vf_optical_flow stage_c precedent).\nParam strength(100.0);\nParam bypass_gate(0.0);\n\neps_trace = 0.000001;\n\njxx = nearest(in1, norm).x;\njxy = nearest(in1, norm).y;\njyy = nearest(in1, norm).z;\n\ntrace = jxx + jyy;\ndiff = jxx - jyy;\nroot = sqrt(diff*diff + 4.0*jxy*jxy);\ntheta = 0.5 * atan2(2.0*jxy, diff);\niso = 1.0 - step(eps_trace, trace);\n// Direction is also undefined where root ~ 0 (equal eigenvalues, e.g.\n// Jxx=Jyy, Jxy=0): GPU atan2(0,0) != NumPy's 0 (bench 2026-10-16), so\n// force R=G=0.5 there too; B and A keep their real values.\niso_dir = max(iso, 1.0 - step(eps_trace, root));\n\ncoh = clamp(root / max(trace, eps_trace), 0.0, 1.0);\nc2 = cos(2.0*theta) * 0.5 + 0.5;\ns2 = sin(2.0*theta) * 0.5 + 0.5;\ntr = clamp(trace * strength, 0.0, 1.0);\n\nn_r = mix(c2, 0.5, iso_dir);\nn_g = mix(s2, 0.5, iso_dir);\nn_b = mix(tr, 0.0, iso);\nn_a = mix(coh, 0.0, iso);\n\nout1 = vec(mix(jxx*strength, 0.0, bypass_gate),\n           mix(jxy*strength*0.5 + 0.5, 0.5, bypass_gate),\n           mix(jyy*strength, 0.0, bypass_gate),\n           1.0);\nout2 = vec(mix(n_r, 0.5, bypass_gate),\n           mix(n_g, 0.5, bypass_gate),\n           mix(n_b, 0.0, bypass_gate),\n           mix(n_a, 0.0, bypass_gate));\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
									"id": "gen-obj-2",
									"maxclass": "codebox",
									"numinlets": 1,
									"numoutlets": 2,
									"outlettype": [
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
							}
						]
					},
					"patching_rect": [
						30.0,
						530.0,
						200.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_tm_stage_c @type float32",
					"varname": "#0_tm_stage_c"
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
						980.0,
						100.0,
						56.0,
						22.0
					],
					"text": "autopattr",
					"varname": "tensormap_autopattr"
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
						760.0,
						260.0,
						154.0,
						84.0
					],
					"presentation": 1,
					"presentation_rect": [
						0.0,
						0.0,
						154.0,
						84.0
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
						980.0,
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
					"text": "Map"
				}
			},
			{
				"box": {
					"id": "obj-8",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 11.0,
					"textcolor": [
						0.85,
						0.55,
						0.2,
						1.0
					],
					"textjustification": 2,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						1070.0,
						200.0,
						60.0,
						21.0
					],
					"presentation": 1,
					"presentation_rect": [
						55.0,
						0.9,
						70.0,
						21.0
					],
					"text": "T_ out"
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
						980.0,
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
						0.85,
						0.55,
						0.2,
						1.0
					],
					"border": 0,
					"mode": 0,
					"hint": "Outputs: tensor",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						1000.0,
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
						760.0,
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
						760.0,
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
						760.0,
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
						760.0,
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
						760.0,
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
						760.0,
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
					"hint": "Gain on trace and the raw tensor terms before clamping (not on coherence). Trace is gradient squared, so the useful gain scales with feature size squared: roughly 35 for fine detail, 150 medium, 900 coarse/smooth content (at radius 3, 640x480). Log-style dial.",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_tm_stage_c::strength",
					"parameter_enable": 1,
					"patching_rect": [
						46.5,
						250.0,
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
								100.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "strength",
							"parameter_mmax": 1000.0,
							"parameter_mmin": 1.0,
							"parameter_modmode": 3,
							"parameter_exponent": 4.0,
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
					"id": "obj-21",
					"maxclass": "attrui",
					"attr": "strength",
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
					"text": "Strength",
					"textjustification": 1,
					"varname": "lbl_strength"
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
					"hint": "Smoothing radius in pixels (box, 0-16). 0 = no smoothing. Cost depends on the fixed maximum (16), not this value. Pixels only if width/height match the render size.",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_tm_stage_b_h::radius",
					"parameter_enable": 1,
					"patching_rect": [
						118.5,
						250.0,
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
								3.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "radius",
							"parameter_mmax": 16.0,
							"parameter_mmin": 0.0,
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
					"id": "obj-24",
					"maxclass": "attrui",
					"attr": "radius",
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
					"id": "obj-700",
					"maxclass": "attrui",
					"attr": "radius",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						98.0,
						344.0,
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
					"text": "Radius",
					"textjustification": 1,
					"varname": "lbl_radius"
				}
			},
			{
				"box": {
					"id": "obj-26",
					"maxclass": "live.numbox",
					"fontname": "Ableton Sans Light",
					"hint": "Render width in pixels. Set to the real frame width: it sets the one-pixel tap step. (Live jit.gl.pix cannot read its own size, so this is exposed for now.)",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_tm_stage_a::width",
					"parameter_enable": 1,
					"patching_rect": [
						182.0,
						250.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						78.0,
						38.0,
						34.0,
						15.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								640.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "width",
							"parameter_mmax": 8192.0,
							"parameter_mmin": 64.0,
							"parameter_modmode": 3,
							"parameter_shortname": "width",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"varname": "width"
				}
			},
			{
				"box": {
					"id": "obj-27",
					"maxclass": "attrui",
					"attr": "width",
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
					"id": "obj-701",
					"maxclass": "attrui",
					"attr": "width",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						170.0,
						344.0,
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
					"text": "Width",
					"textjustification": 1,
					"varname": "lbl_width"
				}
			},
			{
				"box": {
					"id": "obj-29",
					"maxclass": "live.numbox",
					"fontname": "Ableton Sans Light",
					"hint": "Render height in pixels. Set to the real frame height: it sets the vertical tap step.",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_tm_stage_a::height",
					"parameter_enable": 1,
					"patching_rect": [
						254.0,
						250.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						115.0,
						38.0,
						34.0,
						15.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								480.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "height",
							"parameter_mmax": 8192.0,
							"parameter_mmin": 64.0,
							"parameter_modmode": 3,
							"parameter_shortname": "height",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"varname": "height"
				}
			},
			{
				"box": {
					"id": "obj-30",
					"maxclass": "attrui",
					"attr": "height",
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
					"id": "obj-702",
					"maxclass": "attrui",
					"attr": "height",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						242.0,
						344.0,
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
					"text": "Height",
					"textjustification": 1,
					"varname": "lbl_height"
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
						980.0,
						130.0,
						18.0,
						12.0
					],
					"presentation_rect": [
						129.0,
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
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						980.0,
						160.0,
						131.0,
						22.0
					],
					"text": "prepend param bypass_gate"
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
						"obj-52",
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
						"obj-52",
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
						"obj-52",
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
						"obj-50",
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
						"obj-23",
						0
					],
					"destination": [
						"obj-700",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-700",
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
						"obj-26",
						0
					],
					"destination": [
						"obj-701",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-701",
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
						"obj-29",
						0
					],
					"destination": [
						"obj-702",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-702",
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
						"obj-52",
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
						"obj-52",
						1
					],
					"destination": [
						"obj-201",
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
				"radius",
				"radius",
				0
			],
			"obj-26": [
				"width",
				"width",
				0
			],
			"obj-29": [
				"height",
				"height",
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