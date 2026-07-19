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
					"comment": "vecfield (u,v)",
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
					"id": "obj-201",
					"maxclass": "outlet",
					"comment": "confidence",
					"index": 1,
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
					"numinlets": 1,
					"numoutlets": 9,
					"outlettype": [
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
						200.0,
						130.0,
						427.0,
						22.0
					],
					"text": "route scale gain mask_lo mask_hi decay injection step reach mix_pct"
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
							400.0,
							300.0
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
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										22.0,
										100.0,
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
									"source": [
										"gen-obj-1",
										0
									],
									"destination": [
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
					"text": "jit.gl.pix vsynth @name #0_of_pass",
					"varname": "#0_of_pass"
				}
			},
			{
				"box": {
					"id": "obj-5",
					"maxclass": "newobj",
					"numinlets": 2,
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
									"id": "gen-obj-10",
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
									"code": "// Stage A: Ix/Iy spatial gradients (central diff, current-frame-only\n// per T003 decision) + It signed temporal diff. in1=current, in2=previous.\n// Param bypass declared here but unused -- this node is the module's\n// primary (for automatic source-inlet wiring), so it receives the\n// automatic bypass fan-out message too; the real bypass behavior (mix\n// to neutral field + zero confidence) lives in stage_c, wired via\n// raw_lines. See definition.py's architecture note.\nParam scale(0.004);\nParam bypass(0.0);\n\nLc_r = sample(in1, vec(norm.x + scale, norm.y)).x*0.2126 + sample(in1, vec(norm.x + scale, norm.y)).y*0.7152 + sample(in1, vec(norm.x + scale, norm.y)).z*0.0722;\nLc_l = sample(in1, vec(norm.x - scale, norm.y)).x*0.2126 + sample(in1, vec(norm.x - scale, norm.y)).y*0.7152 + sample(in1, vec(norm.x - scale, norm.y)).z*0.0722;\nLc_d = sample(in1, vec(norm.x, norm.y + scale)).x*0.2126 + sample(in1, vec(norm.x, norm.y + scale)).y*0.7152 + sample(in1, vec(norm.x, norm.y + scale)).z*0.0722;\nLc_u = sample(in1, vec(norm.x, norm.y - scale)).x*0.2126 + sample(in1, vec(norm.x, norm.y - scale)).y*0.7152 + sample(in1, vec(norm.x, norm.y - scale)).z*0.0722;\n\nix = (Lc_r - Lc_l);\niy = (Lc_d - Lc_u);\n\n// Edge banding fix (2026-07-18): sample() always clamps at texture\n// boundaries on this GPU path (boundmode args are silently ignored, per\n// jit-gen-codebox skill) -- so near any frame edge, one of the two\n// central-difference taps above collapses onto the center sample\n// instead of a genuinely-offset one, producing a biased/asymmetric\n// derivative in a band `scale` pixels wide from every border (not\n// noise -- a real, systematic artifact whose width scales directly\n// with |scale|). Rather than build a separate masking mechanism, zero\n// ix/iy explicitly within that margin -- Stage B's windowed sums\n// (Sxx/Sxy/Syy) then naturally shrink toward zero wherever the window\n// touches this zeroed border, so Stage C's existing mask_lo/mask_hi\n// confidence gate already treats it as \"no data\" with no new\n// machinery needed (mask_lo must be above 0 for this to actually gate\n// anything -- a mask_lo of exactly 0.00 won't catch the now-legitimately-\n// low det near edges).\nedge_dist = min(min(norm.x, 1.0 - norm.x), min(norm.y, 1.0 - norm.y));\nedge_mask = step(abs(scale), edge_dist);\nix = ix * edge_mask;\niy = iy * edge_mask;\n\nlcur  = sample(in1, norm).x*0.2126  + sample(in1, norm).y*0.7152  + sample(in1, norm).z*0.0722;\nlprev = sample(in2, norm).x*0.2126 + sample(in2, norm).y*0.7152 + sample(in2, norm).z*0.0722;\nit = lcur - lprev;\n\n// out1: Ix/Iy packed as vecfield (0.5-centered RG), matches f_vf_fieldmap encoding\nout1 = vec(clamp(ix*0.5 + 0.5, 0.0, 1.0), clamp(iy*0.5 + 0.5, 0.0, 1.0), 0.5, 1.0);\n\n// out2: It, 0.5-centered grayscale for direct preview\nout2 = vec(clamp(it*0.5 + 0.5, 0.0, 1.0), clamp(it*0.5 + 0.5, 0.0, 1.0), clamp(it*0.5 + 0.5, 0.0, 1.0), 1.0);\n\n// out3: cur passthrough -- closes the feedback loop with pass_pix so in2\n// (previous frame) is genuinely delayed one frame, not resampling the\n// current frame every tick (same shape as f_vf_advect's state/pass loop)\nout3 = sample(in1, norm);\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
									"id": "gen-obj-2",
									"maxclass": "codebox",
									"numinlets": 2,
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
										"gen-obj-2",
										1
									],
									"source": [
										"gen-obj-10",
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
							}
						]
					},
					"patching_rect": [
						200.0,
						380.0,
						200.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_of_stage_a",
					"varname": "#0_of_stage_a"
				}
			},
			{
				"box": {
					"id": "obj-51",
					"maxclass": "newobj",
					"numinlets": 2,
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
									"id": "gen-obj-10",
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
									"code": "// Stage B (pass 1/2): horizontal 5-tap box sum of Ix^2, Iy^2, IxIy,\n// IxIt, IyIt. Separable box filter -- avoids naive 25-tap 2D sum\n// (GL2->GL3 capture-group ceiling risk per jit-gen-codebox skill).\n// Vertical pass (stage_b_v) completes the 5x5 window.\n// in1 = Stage A out1 (Ix/Iy vecfield-encoded), in2 = Stage A out2\n// (It vecfield-encoded, grayscale). All component access inline on\n// sample() -- never store-then-slice (silent black-output failure).\n// step is a live Param (bipolar -0.1..0.1, default 0.0015), driving\n// window tap spacing on both Stage B passes. RESOLVED 2026-07-18: an\n// open question carried since scratch-test days asked whether naming\n// a Param \"step\" collides with GenExpr's built-in step() operator\n// (cell/in/norm/snorm/dim/inN/active class of silent-failure hazard,\n// per jit-gen-codebox skill). Tested directly in the built module --\n// confirmed working correctly (dial visibly changes window spacing,\n// no collision). Kept as a permanent live control.\nParam step(0.0015);\n\nix_m2 = (sample(in1, vec(norm.x - step*2.0, norm.y)).x - 0.5) * 2.0;\niy_m2 = (sample(in1, vec(norm.x - step*2.0, norm.y)).y - 0.5) * 2.0;\nit_m2 = (sample(in2, vec(norm.x - step*2.0, norm.y)).x - 0.5) * 2.0;\n\nix_m1 = (sample(in1, vec(norm.x - step, norm.y)).x - 0.5) * 2.0;\niy_m1 = (sample(in1, vec(norm.x - step, norm.y)).y - 0.5) * 2.0;\nit_m1 = (sample(in2, vec(norm.x - step, norm.y)).x - 0.5) * 2.0;\n\nix_0 = (sample(in1, norm).x - 0.5) * 2.0;\niy_0 = (sample(in1, norm).y - 0.5) * 2.0;\nit_0 = (sample(in2, norm).x - 0.5) * 2.0;\n\nix_p1 = (sample(in1, vec(norm.x + step, norm.y)).x - 0.5) * 2.0;\niy_p1 = (sample(in1, vec(norm.x + step, norm.y)).y - 0.5) * 2.0;\nit_p1 = (sample(in2, vec(norm.x + step, norm.y)).x - 0.5) * 2.0;\n\nix_p2 = (sample(in1, vec(norm.x + step*2.0, norm.y)).x - 0.5) * 2.0;\niy_p2 = (sample(in1, vec(norm.x + step*2.0, norm.y)).y - 0.5) * 2.0;\nit_p2 = (sample(in2, vec(norm.x + step*2.0, norm.y)).x - 0.5) * 2.0;\n\nh_ix2  = ix_m2*ix_m2 + ix_m1*ix_m1 + ix_0*ix_0 + ix_p1*ix_p1 + ix_p2*ix_p2;\nh_iy2  = iy_m2*iy_m2 + iy_m1*iy_m1 + iy_0*iy_0 + iy_p1*iy_p1 + iy_p2*iy_p2;\nh_ixiy = ix_m2*iy_m2 + ix_m1*iy_m1 + ix_0*iy_0 + ix_p1*iy_p1 + ix_p2*iy_p2;\nh_ixit = ix_m2*it_m2 + ix_m1*it_m1 + ix_0*it_0 + ix_p1*it_p1 + ix_p2*it_p2;\nh_iyit = iy_m2*it_m2 + iy_m1*it_m1 + iy_0*it_0 + iy_p1*it_p1 + iy_p2*it_p2;\n\n// raw, unbounded, unencoded partial sums -- pix_type float32 required\nout1 = vec(h_ix2, h_iy2, h_ixiy, 1.0);\nout2 = vec(h_ixit, h_iyit, 0.0, 1.0);\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
									"id": "gen-obj-2",
									"maxclass": "codebox",
									"numinlets": 2,
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
										"gen-obj-2",
										1
									],
									"source": [
										"gen-obj-10",
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
						200.0,
						440.0,
						200.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_of_stage_b_h @type float32",
					"varname": "#0_of_stage_b_h"
				}
			},
			{
				"box": {
					"id": "obj-52",
					"maxclass": "newobj",
					"numinlets": 2,
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
									"id": "gen-obj-10",
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
									"code": "// Stage B (pass 2/2): vertical 5-tap sum, completing the 5x5\n// separable box filter over the horizontal partial sums from\n// stage_b_h. in1 = (h_ix2, h_iy2, h_ixiy), in2 = (h_ixit, h_iyit).\n// These are raw unbounded sums -- no vecfield decode needed here\n// (unlike stage_a's 0.5-centered outputs); all access inline on\n// sample(), never store-then-slice.\n// step is a live Param (bipolar -0.1..0.1, default 0.0015), driving\n// window tap spacing on both Stage B passes. RESOLVED 2026-07-18: an\n// open question carried since scratch-test days asked whether naming\n// a Param \"step\" collides with GenExpr's built-in step() operator\n// (cell/in/norm/snorm/dim/inN/active class of silent-failure hazard,\n// per jit-gen-codebox skill). Tested directly in the built module --\n// confirmed working correctly (dial visibly changes window spacing,\n// no collision). Kept as a permanent live control.\nParam step(0.0015);\n\nsum_ix2  = sample(in1, vec(norm.x, norm.y - step*2.0)).x + sample(in1, vec(norm.x, norm.y - step)).x + sample(in1, norm).x + sample(in1, vec(norm.x, norm.y + step)).x + sample(in1, vec(norm.x, norm.y + step*2.0)).x;\nsum_iy2  = sample(in1, vec(norm.x, norm.y - step*2.0)).y + sample(in1, vec(norm.x, norm.y - step)).y + sample(in1, norm).y + sample(in1, vec(norm.x, norm.y + step)).y + sample(in1, vec(norm.x, norm.y + step*2.0)).y;\nsum_ixiy = sample(in1, vec(norm.x, norm.y - step*2.0)).z + sample(in1, vec(norm.x, norm.y - step)).z + sample(in1, norm).z + sample(in1, vec(norm.x, norm.y + step)).z + sample(in1, vec(norm.x, norm.y + step*2.0)).z;\nsum_ixit = sample(in2, vec(norm.x, norm.y - step*2.0)).x + sample(in2, vec(norm.x, norm.y - step)).x + sample(in2, norm).x + sample(in2, vec(norm.x, norm.y + step)).x + sample(in2, vec(norm.x, norm.y + step*2.0)).x;\nsum_iyit = sample(in2, vec(norm.x, norm.y - step*2.0)).y + sample(in2, vec(norm.x, norm.y - step)).y + sample(in2, norm).y + sample(in2, vec(norm.x, norm.y + step)).y + sample(in2, vec(norm.x, norm.y + step*2.0)).y;\n\n// final 5x5 windowed sums -- ready for Stage C's 2x2 solve.\n// out1 = A-matrix terms (Ix^2, Iy^2, IxIy), out2 = b-vector terms (IxIt, IyIt)\nout1 = vec(sum_ix2, sum_iy2, sum_ixiy, 1.0);\nout2 = vec(sum_ixit, sum_iyit, 0.0, 1.0);\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
									"id": "gen-obj-2",
									"maxclass": "codebox",
									"numinlets": 2,
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
										"gen-obj-2",
										1
									],
									"source": [
										"gen-obj-10",
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
						200.0,
						500.0,
						200.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_of_stage_b_v @type float32",
					"varname": "#0_of_stage_b_v"
				}
			},
			{
				"box": {
					"id": "obj-53",
					"maxclass": "newobj",
					"numinlets": 2,
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
									"id": "gen-obj-10",
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
									"code": "// Stage C: closed-form 2x2 Lucas-Kanade solve (Cramer's rule) for\n// (u,v) from Stage B's five windowed sums, plus the matrix\n// determinant as a separate confidence outlet (ADR-2). in1 = Stage B\n// out1 (Sxx, Syy, Sxy), in2 = Stage B out2 (Sxt, Syt). Raw, unbounded\n// inputs -- no vecfield decode needed (same convention as Stage B).\n//\n// This node produces the module's real outlets (u,v vecfield +\n// confidence) even though it is NOT the pix_chain's \"primary\" node\n// (stage_a is primary, so it gets the automatic module-source wiring).\n// Outlet wiring and bypass are both supplied via definition.py's\n// raw_lines, mirroring f_lens's outlet_source_override precedent --\n// see definition.py's architecture note for the full explanation.\nParam gain(1.0);\nParam mask_lo(0.0);\nParam mask_hi(1.0);\nParam bypass(0.0);\n\nsxx = sample(in1, norm).x;\nsyy = sample(in1, norm).y;\nsxy = sample(in1, norm).z;\nsxt = sample(in2, norm).x;\nsyt = sample(in2, norm).y;\n\ndet = sxx*syy - sxy*sxy;\n// det is mathematically >= 0 for this covariance-like matrix\n// (Cauchy-Schwarz: (SIxIy)^2 <= SIx^2 * SIy^2) -- guard only against\n// the near-singular/aperture-problem case, no sign handling needed.\n// Empirically confirmed 2026-07-18: det reads flat ~0 against a pure\n// synthetic edge (test_edge_pix), correctly reflecting the aperture\n// problem, and visibly nonzero on real corner/texture content.\ndet_safe = max(det, 0.0001);\n\n// T035 (2026-07-18): the locally-ambiguous axis, for Stage E's future\n// confidence-gated directional fill (Phase 5). Standard structure-\n// tensor double-angle result: cos(2*theta)=(Sxx-Syy)/mag,\n// sin(2*theta)=2*Sxy/mag gives the dominant-gradient (well-\n// constrained, larger-eigenvalue, \"across the edge\") direction theta.\n// The ambiguous axis (smaller eigenvalue, \"along the edge\" -- what\n// Stage E actually needs to propagate along) is perpendicular, i.e.\n// theta+halfpi -- but a 90-degree rotation is a 180-degree rotation in\n// this doubled-angle space, so it's the SAME (cos2t,sin2t) pair; Stage\n// E adds the perpendicular offset itself when reconstructing a\n// direction vector, no extra math needed here. Stored as double-angle\n// rather than a plain angle specifically to avoid a wraparound\n// discontinuity: an axis (undirected line, not a vector) repeats every\n// 180 degrees, so a naive single-angle encoding would jump/wrap\n// somewhere in the frame, and neighboring pixels straddling that wrap\n// would blend garbage under Stage E's own bilinear sampling. Doubling\n// the angle first makes the stored signal continuous everywhere.\nmag = sqrt((sxx-syy)*(sxx-syy) + (2.0*sxy)*(2.0*sxy));\nmag_safe = max(mag, 0.0001);\ncos2t = (sxx-syy) / mag_safe;\nsin2t = (2.0*sxy) / mag_safe;\n// mag_safe's floor makes cos2t/sin2t arbitrary-but-harmless in\n// isotropic regions (both eigenvalues equal -- no preferred axis to\n// speak of, e.g. corners) and in genuinely flat/textureless regions\n// (no gradient at all) -- Stage E only consults this signal when\n// searching FROM a low-confidence pixel, and both of those cases are\n// degenerate starting points where any search direction is a\n// reasonable fallback, not a correctness problem.\n\nu = (-sxt*syy + sxy*syt) / det_safe;\nv = (-sxx*syt + sxy*sxt) / det_safe;\n\n// encode (u,v) as a standard f_vecfield -- 0.5 = zero vector, same\n// convention as f_vf_fieldmap -- loads into f_vf_warp/f_vf_fieldmap-\n// family consumers with no adapter (T015)\nfield = vec(clamp(u*gain*0.5 + 0.5, 0.0, 1.0), clamp(v*gain*0.5 + 0.5, 0.0, 1.0), 0.5, 1.0);\nneutral = vec(0.5, 0.5, 0.5, 1.0);\n\n// Confidence-gated masking -- ADR-2 originally deferred this (raw\n// confidence signal only, no masking), but real testing 2026-07-18\n// showed WHY it's needed: det_safe's divide-by-zero floor means any\n// tiny per-frame sensor noise in low-det (aperture-problem) regions\n// gets amplified into large erratic (u,v) values -- worst exactly\n// along real 1D edges (window blinds, silhouette outlines), which is\n// the opposite of where you'd want noise. Confirmed via a static\n// scene: vecfield should read flat/neutral with zero real motion, but\n// showed sharp edge-tracking noise instead -- the same aperture-\n// problem geometry as the synthetic test_edge_pix result, just on\n// real edges instead of a synthetic one. mask_lo/mask_hi are live\n// dials rather than hardcoded, since det's real numeric range was\n// never pinned down empirically (T017) -- turning them while watching\n// the vecfield preview IS the empirical range-finding.\nmask = smoothstep(mask_lo, mask_hi, det);\nfield_masked = mix(neutral, field, mask);\n\n// out2: raw determinant in x (unclamped -- range not yet known\n// empirically beyond qualitative behavior, T017), T035's ambiguous-\n// axis signal in y/z (cos2t/sin2t, remapped to [0,1] for texture\n// storage since this outlet is not clamped/normalized to a display\n// range the way out1 is). This means out2 no longer previews as clean\n// grayscale (y/z used to duplicate x purely for preview convenience,\n// now carry real directional information instead) -- no current\n// consumer reads out2 (T023's f_vf_warp wiring uses out1 only), so\n// this is a real but currently-harmless behavior change. Bypass zeroes\n// it, since a bypassed module shouldn't claim any confidence or axis\n// data for flow it isn't actually producing.\nout1 = mix(field_masked, neutral, bypass);\nout2 = mix(vec(det, cos2t*0.5+0.5, sin2t*0.5+0.5, 1.0), vec(0.0, 0.5, 0.5, 1.0), bypass);\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
									"id": "gen-obj-2",
									"maxclass": "codebox",
									"numinlets": 2,
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
										"gen-obj-2",
										1
									],
									"source": [
										"gen-obj-10",
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
						200.0,
						560.0,
						200.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_of_stage_c @type float32",
					"varname": "#0_of_stage_c"
				}
			},
			{
				"box": {
					"id": "obj-54",
					"maxclass": "newobj",
					"numinlets": 2,
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
									"id": "gen-obj-10",
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
									"code": "// Stage E: confidence-gated directional propagation (T036, 2026-07-18)\n// Fills in low-confidence (aperture-problem) pixels by pulling from\n// higher-confidence neighbors specifically along the locally-ambiguous\n// axis derived in Stage C (T035) -- NOT an isotropic blur, since only\n// the axis-aligned direction actually carries information a straight\n// edge's own geometry could plausibly share (a rigid edge's true\n// motion is constant along its own length, so sampling further along\n// that same line is where a real answer might exist; sampling\n// perpendicular to it would just blend in unrelated content).\n//\n// in1 = stage_c's masked instantaneous field (already neutral where\n// stage_c's own mask_lo/mask_hi gated it out). in2 = stage_c's\n// confidence+axis signal: x=raw det (unmasked, independent of in1's\n// own masking), y/z=cos2t/sin2t (T035's double-angle-encoded ambiguous\n// axis -- see codebox_stage_c.gen for the full derivation and\n// wraparound rationale).\n//\n// Sits between Stage C and Stage D (C -> E -> D, decided 2026-07-18):\n// spatial fill happens per-frame BEFORE temporal accumulation, so\n// Stage D's decay/injection accumulates an already-filled signal\n// instead of repeatedly decaying/re-injecting from neutral in gap\n// regions every frame.\n//\n// mask_lo/mask_hi are the SAME dials as Stage C's (fanned out via\n// definition.py raw_lines, not a second near-duplicate pair) -- one\n// set of confidence controls in the UI, reused here to judge both the\n// center pixel's own confidence and each sampled tap's confidence.\n//\n// No bypass Param needed here: Stage D's own bypass already forces the\n// module's final output to neutral regardless of what this stage\n// computes, and Stage C's bypass already zeroes both in1 (neutral\n// field) and in2 (det=0), which naturally drives this stage's own\n// output to neutral too (own_mask and every tap weight fall to 0,\n// triggering the neutral fallback below) -- no explicit propagation\n// of the bypass flag required.\nParam mask_lo(0.0);\nParam mask_hi(1.0);\nParam reach(0.01);\nParam mix_pct(100.0);\n\nown_field = sample(in1, norm);\nown_det   = sample(in2, norm).x;\nown_mask  = smoothstep(mask_lo, mask_hi, own_det);\n\n// T035's double-angle decode -- see codebox_stage_c.gen for why this\n// is stored as (cos2t,sin2t) rather than a plain angle (avoids a\n// wraparound discontinuity that would blend garbage under this very\n// stage's own bilinear sampling)\ncos2t = sample(in2, norm).y * 2.0 - 1.0;\nsin2t = sample(in2, norm).z * 2.0 - 1.0;\ntheta = atan2(sin2t, cos2t) * 0.5;\ndx = -sin(theta);\ndy = cos(theta);\n\n// four taps along the ambiguous axis, both directions -- same\n// two-steps-either-side shape as Stage B's own window, just spatial\n// instead of a fixed small offset\nt1 = vec(norm.x + dx*reach,       norm.y + dy*reach);\nt2 = vec(norm.x + dx*reach*2.0,   norm.y + dy*reach*2.0);\nt3 = vec(norm.x - dx*reach,       norm.y - dy*reach);\nt4 = vec(norm.x - dx*reach*2.0,   norm.y - dy*reach*2.0);\n\n// component access must happen on the SAME line as each sample() call\n// (storing a full vec then slicing it later is a documented silent-\n// failure hazard on this GPU path) -- every .x/.y/.z below is inlined\n// against its own sample() call, not extracted from a stored variable\nw1 = smoothstep(mask_lo, mask_hi, sample(in2, t1).x);\nw2 = smoothstep(mask_lo, mask_hi, sample(in2, t2).x);\nw3 = smoothstep(mask_lo, mask_hi, sample(in2, t3).x);\nw4 = smoothstep(mask_lo, mask_hi, sample(in2, t4).x);\n\nsum_w = w1 + w2 + w3 + w4;\nsum_x = sample(in1, t1).x*w1 + sample(in1, t2).x*w2 + sample(in1, t3).x*w3 + sample(in1, t4).x*w4;\nsum_y = sample(in1, t1).y*w1 + sample(in1, t2).y*w2 + sample(in1, t3).y*w3 + sample(in1, t4).y*w4;\n\n// neutral fallback when no confident tap exists within reach (rather\n// than a spurious near-zero encoded value from dividing by the\n// epsilon floor with nothing real in the numerator either)\nhave_data  = step(0.01, sum_w);\nsum_w_safe = max(sum_w, 0.0001);\nfilled_x = mix(0.5, sum_x/sum_w_safe, have_data);\nfilled_y = mix(0.5, sum_y/sum_w_safe, have_data);\nfilled_field = vec(filled_x, filled_y, 0.5, 1.0);\n\n// near-identity where own confidence is already high; full directional\n// fill where it isn't\nstage_result = mix(filled_field, own_field, own_mask);\n\n// global dry/wet -- a live performance control to dial the fill effect\n// down or off entirely, independent of per-pixel confidence. mix_pct\n// convention: 0-100% live.numbox, internal Param named mix_pct (never\n// bare \"mix\" -- collides with the codebox's built-in mix() operator).\nmix_frac = mix_pct / 100.0;\nout1 = mix(own_field, stage_result, mix_frac);\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
									"id": "gen-obj-2",
									"maxclass": "codebox",
									"numinlets": 2,
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
										"gen-obj-2",
										1
									],
									"source": [
										"gen-obj-10",
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
						620.0,
						200.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_of_stage_e @type float32",
					"varname": "#0_of_stage_e"
				}
			},
			{
				"box": {
					"id": "obj-55",
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
							400.0,
							300.0
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
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										22.0,
										100.0,
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
									"source": [
										"gen-obj-1",
										0
									],
									"destination": [
										"gen-obj-2",
										0
									]
								}
							}
						]
					},
					"patching_rect": [
						200.0,
						680.0,
						224.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_of_stage_d_pass",
					"varname": "#0_of_stage_d_pass"
				}
			},
			{
				"box": {
					"id": "obj-56",
					"maxclass": "newobj",
					"numinlets": 2,
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
									"id": "gen-obj-10",
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
									"code": "// Stage D: temporal accumulation with decay/injection (mirrors\n// f_vf_advect's proven state/pass feedback pattern), giving the\n// instantaneous per-frame LK solve some persistence/momentum rather\n// than reading as a pure frame-to-frame noise field. Added 2026-07-18\n// after real testing showed the raw solve, even correctly masked, felt\n// too transitory to read as coherent flow direction.\n//\n// in1 = stage_c's masked instantaneous vecfield (this frame's fresh\n// solve), in2 = previous accumulated field (via pass_d feedback loop,\n// same one-frame-delay mechanism as stage_a's own pass_pix loop).\nParam decay(0.9);\nParam injection(0.3);\nParam bypass(0.0);\n\nraw_u  = (sample(in1, norm).x - 0.5) * 2.0;\nraw_v  = (sample(in1, norm).y - 0.5) * 2.0;\nprev_u = (sample(in2, norm).x - 0.5) * 2.0;\nprev_v = (sample(in2, norm).y - 0.5) * 2.0;\n\n// decay above 1.0 allows a self-reinforcing/excitable regime -- same\n// convention as f_vf_advect's own decay param (range 0.8-1.5 there)\naccum_u = prev_u * decay + raw_u * injection;\naccum_v = prev_v * decay + raw_v * injection;\n\n// encode back to standard f_vecfield (0.5-centered) -- this becomes\n// both the module's real (u,v) outlet and next frame's \"previous\"\n// via the pass_d feedback loop\nfield = vec(clamp(accum_u*0.5 + 0.5, 0.0, 1.0), clamp(accum_v*0.5 + 0.5, 0.0, 1.0), 0.5, 1.0);\nneutral = vec(0.5, 0.5, 0.5, 1.0);\n\nout1 = mix(field, neutral, bypass);\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
									"id": "gen-obj-2",
									"maxclass": "codebox",
									"numinlets": 2,
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
										"gen-obj-2",
										1
									],
									"source": [
										"gen-obj-10",
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
						740.0,
						200.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_of_stage_d",
					"varname": "#0_of_stage_d"
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
					"varname": "opticalflow_autopattr"
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
						190.0,
						130.0
					],
					"presentation": 1,
					"presentation_rect": [
						0.0,
						0.0,
						190.0,
						130.0
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
					"text": "Optical Flow"
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
						84.4,
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
					"hint": "Central difference step size for Ix/Iy gradients (normalized UV). Negative inverts gradient axis.",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_of_stage_a::scale",
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
								0.004
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "scale",
							"parameter_mmax": 0.05,
							"parameter_mmin": -0.05,
							"parameter_modmode": 3,
							"parameter_shortname": "scale",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "scale"
				}
			},
			{
				"box": {
					"id": "obj-21",
					"maxclass": "attrui",
					"attr": "scale",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						50.0,
						170.0,
						115.0,
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
					"text": "Scale",
					"textjustification": 1,
					"varname": "lbl_scale"
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
					"hint": "Output vecfield magnitude scale. Negative inverts flow direction.",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_of_stage_a::gain",
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
								1.0
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
					"id": "obj-24",
					"maxclass": "attrui",
					"attr": "gain",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						100.0,
						200.0,
						108.0,
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
					"text": "Gain",
					"textjustification": 1,
					"varname": "lbl_gain"
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
					"hint": "Confidence-gate low threshold -- det values at or below this read as no-flow (neutral). Raise to suppress noise in low-texture/edge-only regions (the aperture problem). Added 2026-07-18 after real testing showed unmasked noise amplifying along real edges, not just in flat regions.",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_of_stage_a::mask_lo",
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
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "mask_lo",
							"parameter_mmax": 20.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "mask_lo",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "mask_lo"
				}
			},
			{
				"box": {
					"id": "obj-27",
					"maxclass": "attrui",
					"attr": "mask_lo",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						150.0,
						230.0,
						129.0,
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
					"text": "Mask Lo",
					"textjustification": 1,
					"varname": "lbl_mask_lo"
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
					"hint": "Confidence-gate high threshold -- det values at or above this pass through at full strength. Widen the Lo/Hi gap for a softer transition, narrow it for a harder cutoff. det's real range was never precisely measured (T017) -- use this dial while watching the vecfield preview to find it empirically.",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_of_stage_a::mask_hi",
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
							"parameter_longname": "mask_hi",
							"parameter_mmax": 20.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "mask_hi",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "mask_hi"
				}
			},
			{
				"box": {
					"id": "obj-30",
					"maxclass": "attrui",
					"attr": "mask_hi",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						200.0,
						260.0,
						129.0,
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
					"text": "Mask Hi",
					"textjustification": 1,
					"varname": "lbl_mask_hi"
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
					"hint": "Per-frame persistence of the accumulated flow field. Above 1.0 allows a self-reinforcing/excitable regime (same convention as f_vf_advect's own decay param), rather than only ever fading. Added 2026-07-18 -- the raw per-frame LK solve, even correctly masked, felt too transitory to read as coherent flow direction.",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_of_stage_a::decay",
					"parameter_enable": 1,
					"patching_rect": [
						250.0,
						80.0,
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
								0.9
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "decay",
							"parameter_mmax": 1.5,
							"parameter_mmin": 0.0,
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
					"id": "obj-33",
					"maxclass": "attrui",
					"attr": "decay",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						250.0,
						290.0,
						115.0,
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
					"text": "Decay",
					"textjustification": 1,
					"varname": "lbl_decay"
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
					"hint": "How strongly this frame's fresh solve blends into the accumulated field each frame.",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_of_stage_a::injection",
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
								0.3
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "injection",
							"parameter_mmax": 2.0,
							"parameter_mmin": 0.0,
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
					"id": "obj-36",
					"maxclass": "attrui",
					"attr": "injection",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						300.0,
						320.0,
						143.0,
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
					"text": "Inject",
					"textjustification": 1,
					"varname": "lbl_injection"
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
					"hint": "Stage B 5-tap window spacing (normalized UV), both horizontal and vertical passes. Bipolar range lets negative values invert tap direction if useful.",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_of_stage_a::step",
					"parameter_enable": 1,
					"patching_rect": [
						350.0,
						80.0,
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
								0.0015
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "step",
							"parameter_mmax": 0.1,
							"parameter_mmin": -0.1,
							"parameter_modmode": 3,
							"parameter_shortname": "step",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "step"
				}
			},
			{
				"box": {
					"id": "obj-39",
					"maxclass": "attrui",
					"attr": "step",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						350.0,
						350.0,
						108.0,
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
					"text": "Step",
					"textjustification": 1,
					"varname": "lbl_step"
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
					"hint": "Stage E directional-fill tap spacing (normalized UV) along the locally-ambiguous axis (T035). Same naming/role as f_vf_prism's own Reach dial.",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_of_stage_a::reach",
					"parameter_enable": 1,
					"patching_rect": [
						400.0,
						80.0,
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
								0.01
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "reach",
							"parameter_mmax": 0.1,
							"parameter_mmin": 0.0,
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
					"id": "obj-42",
					"maxclass": "attrui",
					"attr": "reach",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						400.0,
						380.0,
						115.0,
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
						400.0,
						130.0,
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
					"text": "Reach",
					"textjustification": 1,
					"varname": "lbl_reach"
				}
			},
			{
				"box": {
					"id": "obj-44",
					"maxclass": "live.numbox",
					"fontname": "Ableton Sans Light",
					"hint": "Stage E directional-fill dry/wet, 0-100%. Global control independent of per-pixel confidence -- lets the fill effect be dialed down or off entirely as a live performance control.",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_of_stage_a::mix_pct",
					"parameter_enable": 1,
					"patching_rect": [
						450.0,
						80.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						115.0,
						100.0,
						34.0,
						15.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								100.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "mix_pct",
							"parameter_mmax": 100.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "mix_pct",
							"parameter_type": 0,
							"parameter_unitstyle": 0
						}
					},
					"varname": "mix_pct"
				}
			},
			{
				"box": {
					"id": "obj-45",
					"maxclass": "attrui",
					"attr": "mix_pct",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						450.0,
						410.0,
						129.0,
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
						450.0,
						130.0,
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
					"text": "Mix",
					"textjustification": 1,
					"varname": "lbl_mix_pct"
				}
			},
			{
				"box": {
					"id": "obj-47",
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
						168.0,
						5.0,
						18.0,
						12.0
					],
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
					"id": "obj-48",
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
						"obj-5",
						2
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
						"obj-5",
						1
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
						"obj-51",
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
						"obj-51",
						1
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
						"obj-51",
						1
					],
					"destination": [
						"obj-52",
						1
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
						"obj-53",
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
						"obj-53",
						1
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
						"obj-53",
						1
					],
					"destination": [
						"obj-54",
						1
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
						"obj-55",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-55",
						0
					],
					"destination": [
						"obj-56",
						1
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
						"obj-53",
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
						"obj-53",
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
						"obj-56",
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
						"obj-56",
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
						"obj-51",
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
						"obj-54",
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
						"obj-54",
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
						"obj-2",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-53",
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
						"obj-48",
						0
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
						"obj-48",
						0
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
						"obj-39",
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
						"obj-27",
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
						"obj-30",
						0
					],
					"destination": [
						"obj-54",
						0
					]
				}
			}
		],
		"parameters": {
			"obj-20": [
				"scale",
				"scale",
				0
			],
			"obj-23": [
				"gain",
				"gain",
				0
			],
			"obj-26": [
				"mask_lo",
				"mask_lo",
				0
			],
			"obj-29": [
				"mask_hi",
				"mask_hi",
				0
			],
			"obj-32": [
				"decay",
				"decay",
				0
			],
			"obj-35": [
				"injection",
				"injection",
				0
			],
			"obj-38": [
				"step",
				"step",
				0
			],
			"obj-41": [
				"reach",
				"reach",
				0
			],
			"obj-44": [
				"mix_pct",
				"mix_pct",
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