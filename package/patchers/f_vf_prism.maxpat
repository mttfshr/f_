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
					"comment": "composite",
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
					"comment": "prism",
					"index": 1,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						100.0,
						500.0,
						30.0,
						30.0
					],
					"tricolor": [
						0.6196078431372549,
						0.9529411764705882,
						0.6588235294117647,
						1.0
					]
				}
			},
			{
				"box": {
					"id": "obj-202",
					"maxclass": "outlet",
					"comment": "vecfield",
					"index": 2,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						170.0,
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
					"numoutlets": 7,
					"outlettype": [
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
						413.0,
						22.0
					],
					"text": "route reach spread threshold threshold_width feather gain mix_pct"
				}
			},
			{
				"box": {
					"id": "obj-5",
					"maxclass": "newobj",
					"numinlets": 4,
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
									"id": "gen-obj-11",
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
									"id": "gen-obj-12",
									"maxclass": "newobj",
									"numinlets": 0,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										196.0,
										30.0,
										28.0,
										22.0
									],
									"text": "in 4"
								}
							},
							{
								"box": {
									"code": "// f_vf_prism codebox v17 \u2014 v15 baseline + out3 gate-weighted dispersion\n// direction (ADR1). `strength` renamed to `gain` 2026-07-12 to match\n// the library-wide gain/mix naming convention (vsynth-bpatcher skill) --\n// no change to the underlying math, name only.\n// in1 = source texture (char)\n// in2 = f_vecfield (float32, RG=XY, 0.5=zero vector)\n// in3 = reach mod\n// in4 = spread mod\n\n// helper: displaced R channel\ndisplaced_r(tux, tuy, fx, fy, cx, sx, reach) {\n    dux = clamp(tux - (fx*cx - fy*sx)*reach, 0., 1.);\n    duy = clamp(tuy - (fx*sx + fy*cx)*reach, 0., 1.);\n    return sample(in1, vec(dux, duy)).x;\n}\n\n// helper: displaced G channel\ndisplaced_g(tux, tuy, fx, fy, cx, sx, reach) {\n    dux = clamp(tux - (fx*cx - fy*sx)*reach, 0., 1.);\n    duy = clamp(tuy - (fx*sx + fy*cx)*reach, 0., 1.);\n    return sample(in1, vec(dux, duy)).y;\n}\n\n// helper: displaced B channel\ndisplaced_b(tux, tuy, fx, fy, cx, sx, reach) {\n    dux = clamp(tux - (fx*cx - fy*sx)*reach, 0., 1.);\n    duy = clamp(tuy - (fx*sx + fy*cx)*reach, 0., 1.);\n    return sample(in1, vec(dux, duy)).z;\n}\n\n// gate value for R channel at one tap position\nchannel_gate_r(tux, tuy, fx, fy, cx, sx, reach, thresh, twidth) {\n    val = displaced_r(tux, tuy, fx, fy, cx, sx, reach);\n    return smoothstep(thresh, thresh + twidth, val);\n}\n\n// gate value for G channel at one tap position\nchannel_gate_g(tux, tuy, fx, fy, cx, sx, reach, thresh, twidth) {\n    val = displaced_g(tux, tuy, fx, fy, cx, sx, reach);\n    return smoothstep(thresh, thresh + twidth, val);\n}\n\n// gate value for B channel at one tap position\nchannel_gate_b(tux, tuy, fx, fy, cx, sx, reach, thresh, twidth) {\n    val = displaced_b(tux, tuy, fx, fy, cx, sx, reach);\n    return smoothstep(thresh, thresh + twidth, val);\n}\n\nParam reach(0.05);\nParam spread(0.1);\nParam threshold(0.7);\nParam threshold_width(0.1);\nParam feather(0.1);\nParam gain(1.0);\nParam mix_pct(100.0);\nParam src_vecfield(0.0);\nParam src_length_mod(0.0);\nParam src_width_mod(0.0);\nParam bypass(0.0);\n\nuv = norm;\n\n// source pixel\nsrc_r = sample(in1, uv).x;\nsrc_g = sample(in1, uv).y;\nsrc_b = sample(in1, uv).z;\nsrc_a = sample(in1, uv).w;\n\n// field vector\nconnected = step(0.5, src_vecfield);\nraw_x = sample(in2, uv).x;\nraw_y = sample(in2, uv).y;\nfield_suppress = step(0.02, raw_x + raw_y);\nfx = (raw_x - 0.5) * 2.0 * connected * field_suppress;\nfy = (raw_y - 0.5) * 2.0 * connected * field_suppress;\n\n// mod inlets\nreach_eff  = clamp(reach  + (sample(in3, uv).x - 0.5) * src_length_mod, 0.0, 0.3);\nspread_eff = clamp(spread + (sample(in4, uv).x - 0.5) * src_width_mod,  0.0, 0.5);\n\n// per-channel rotation scalars\ncos_r = cos(spread_eff);  sin_r = sin(spread_eff);\ncos_b = cos(-spread_eff); sin_b = sin(-spread_eff);\ncos_g = 1.0; sin_g = 0.0;\n\n// perpendicular direction (normalized)\nfield_mag = max(sqrt(fx * fx + fy * fy), 0.0001);\npx = -fy / field_mag;\npy =  fx / field_mag;\n\n// feather step size\nseparation = sin(spread_eff) * reach_eff * field_mag;\nstep_size = feather * separation;\n\n// 11-tap gaussian weights (symmetric, sum=1)\nw0 = 0.0093;\nw1 = 0.0280;\nw2 = 0.0660;\nw3 = 0.1220;\nw4 = 0.1747;\nw5 = 0.2000;\n\n// tap UVs\nt5x = uv.x + px * (-5.0) * step_size; t5y = uv.y + py * (-5.0) * step_size;\nt4x = uv.x + px * (-4.0) * step_size; t4y = uv.y + py * (-4.0) * step_size;\nt3x = uv.x + px * (-3.0) * step_size; t3y = uv.y + py * (-3.0) * step_size;\nt2x = uv.x + px * (-2.0) * step_size; t2y = uv.y + py * (-2.0) * step_size;\nt1x = uv.x + px * (-1.0) * step_size; t1y = uv.y + py * (-1.0) * step_size;\nt0x = uv.x;                            t0y = uv.y;\np1x = uv.x + px *   1.0  * step_size; p1y = uv.y + py *   1.0  * step_size;\np2x = uv.x + px *   2.0  * step_size; p2y = uv.y + py *   2.0  * step_size;\np3x = uv.x + px *   3.0  * step_size; p3y = uv.y + py *   3.0  * step_size;\np4x = uv.x + px *   4.0  * step_size; p4y = uv.y + py *   4.0  * step_size;\np5x = uv.x + px *   5.0  * step_size; p5y = uv.y + py *   5.0  * step_size;\n\n// R channel gates (samples .x)\ngr_t5 = channel_gate_r(t5x, t5y, fx, fy, cos_r, sin_r, reach_eff, threshold, threshold_width);\ngr_t4 = channel_gate_r(t4x, t4y, fx, fy, cos_r, sin_r, reach_eff, threshold, threshold_width);\ngr_t3 = channel_gate_r(t3x, t3y, fx, fy, cos_r, sin_r, reach_eff, threshold, threshold_width);\ngr_t2 = channel_gate_r(t2x, t2y, fx, fy, cos_r, sin_r, reach_eff, threshold, threshold_width);\ngr_t1 = channel_gate_r(t1x, t1y, fx, fy, cos_r, sin_r, reach_eff, threshold, threshold_width);\ngr_t0 = channel_gate_r(t0x, t0y, fx, fy, cos_r, sin_r, reach_eff, threshold, threshold_width);\ngr_p1 = channel_gate_r(p1x, p1y, fx, fy, cos_r, sin_r, reach_eff, threshold, threshold_width);\ngr_p2 = channel_gate_r(p2x, p2y, fx, fy, cos_r, sin_r, reach_eff, threshold, threshold_width);\ngr_p3 = channel_gate_r(p3x, p3y, fx, fy, cos_r, sin_r, reach_eff, threshold, threshold_width);\ngr_p4 = channel_gate_r(p4x, p4y, fx, fy, cos_r, sin_r, reach_eff, threshold, threshold_width);\ngr_p5 = channel_gate_r(p5x, p5y, fx, fy, cos_r, sin_r, reach_eff, threshold, threshold_width);\n\n// G channel gates (samples .y)\ngg_t5 = channel_gate_g(t5x, t5y, fx, fy, cos_g, sin_g, reach_eff, threshold, threshold_width);\ngg_t4 = channel_gate_g(t4x, t4y, fx, fy, cos_g, sin_g, reach_eff, threshold, threshold_width);\ngg_t3 = channel_gate_g(t3x, t3y, fx, fy, cos_g, sin_g, reach_eff, threshold, threshold_width);\ngg_t2 = channel_gate_g(t2x, t2y, fx, fy, cos_g, sin_g, reach_eff, threshold, threshold_width);\ngg_t1 = channel_gate_g(t1x, t1y, fx, fy, cos_g, sin_g, reach_eff, threshold, threshold_width);\ngg_t0 = channel_gate_g(t0x, t0y, fx, fy, cos_g, sin_g, reach_eff, threshold, threshold_width);\ngg_p1 = channel_gate_g(p1x, p1y, fx, fy, cos_g, sin_g, reach_eff, threshold, threshold_width);\ngg_p2 = channel_gate_g(p2x, p2y, fx, fy, cos_g, sin_g, reach_eff, threshold, threshold_width);\ngg_p3 = channel_gate_g(p3x, p3y, fx, fy, cos_g, sin_g, reach_eff, threshold, threshold_width);\ngg_p4 = channel_gate_g(p4x, p4y, fx, fy, cos_g, sin_g, reach_eff, threshold, threshold_width);\ngg_p5 = channel_gate_g(p5x, p5y, fx, fy, cos_g, sin_g, reach_eff, threshold, threshold_width);\n\n// B channel gates (samples .z)\ngb_t5 = channel_gate_b(t5x, t5y, fx, fy, cos_b, sin_b, reach_eff, threshold, threshold_width);\ngb_t4 = channel_gate_b(t4x, t4y, fx, fy, cos_b, sin_b, reach_eff, threshold, threshold_width);\ngb_t3 = channel_gate_b(t3x, t3y, fx, fy, cos_b, sin_b, reach_eff, threshold, threshold_width);\ngb_t2 = channel_gate_b(t2x, t2y, fx, fy, cos_b, sin_b, reach_eff, threshold, threshold_width);\ngb_t1 = channel_gate_b(t1x, t1y, fx, fy, cos_b, sin_b, reach_eff, threshold, threshold_width);\ngb_t0 = channel_gate_b(t0x, t0y, fx, fy, cos_b, sin_b, reach_eff, threshold, threshold_width);\ngb_p1 = channel_gate_b(p1x, p1y, fx, fy, cos_b, sin_b, reach_eff, threshold, threshold_width);\ngb_p2 = channel_gate_b(p2x, p2y, fx, fy, cos_b, sin_b, reach_eff, threshold, threshold_width);\ngb_p3 = channel_gate_b(p3x, p3y, fx, fy, cos_b, sin_b, reach_eff, threshold, threshold_width);\ngb_p4 = channel_gate_b(p4x, p4y, fx, fy, cos_b, sin_b, reach_eff, threshold, threshold_width);\ngb_p5 = channel_gate_b(p5x, p5y, fx, fy, cos_b, sin_b, reach_eff, threshold, threshold_width);\n\n// weighted sum\nprism_r = gr_t5*w0 + gr_t4*w1 + gr_t3*w2 + gr_t2*w3 + gr_t1*w4 + gr_t0*w5;\nprism_r = prism_r + gr_p1*w4 + gr_p2*w3 + gr_p3*w2 + gr_p4*w1 + gr_p5*w0;\n\nprism_g = gg_t5*w0 + gg_t4*w1 + gg_t3*w2 + gg_t2*w3 + gg_t1*w4 + gg_t0*w5;\nprism_g = prism_g + gg_p1*w4 + gg_p2*w3 + gg_p3*w2 + gg_p4*w1 + gg_p5*w0;\n\nprism_b = gb_t5*w0 + gb_t4*w1 + gb_t3*w2 + gb_t2*w3 + gb_t1*w4 + gb_t0*w5;\nprism_b = prism_b + gb_p1*w4 + gb_p2*w3 + gb_p3*w2 + gb_p4*w1 + gb_p5*w0;\n\n// composite: driven = pure effect standing alone at \"what it would be\n// at 100%\" (strength-scaled); mix is a plain continuous blend ratio\n// toward that state -- NOT spatial masking, NOT coverage/opacity. At\n// mix=30%, every pixel is exactly 30% of the way from source toward\n// that same pixel's 100%-effect value. Matt: \"an effect applied 30%\n// isn't the same as an effect applied to 30% of a masked shape... it\n// bends 30% of the way toward what it would be at 100%.\"\ndriven_r = clamp(src_r + prism_r * gain, 0.0, 1.0);\ndriven_g = clamp(src_g + prism_g * gain, 0.0, 1.0);\ndriven_b = clamp(src_b + prism_b * gain, 0.0, 1.0);\ncomp_r = mix(src_r, driven_r, mix_pct / 100.0);\ncomp_g = mix(src_g, driven_g, mix_pct / 100.0);\ncomp_b = mix(src_b, driven_b, mix_pct / 100.0);\n\nout1 = mix(vec(comp_r, comp_g, comp_b, src_a), vec(src_r, src_g, src_b, src_a), bypass);\nout2 = mix(vec(prism_r, prism_g, prism_b, 1.0), vec(0.0, 0.0, 0.0, 1.0), bypass);\n\n// --- out3: gate-weighted dispersion direction (ADR1) ---\n// Each channel's own displacement vector (the rotation of the field\n// actually used to compute its sample position), weighted by that\n// channel's own post-blur gate strength (prism_r/g/b, already computed\n// above for out1/out2 -- reused, no new sampling passes). Where gates\n// agree the three (nearly-aligned) vectors reinforce; where they\n// disagree the result leans toward whichever channel is actually gated\n// \"on\" -- information the input field alone doesn't carry.\nrvx = (fx*cos_r - fy*sin_r) * reach_eff;  rvy = (fx*sin_r + fy*cos_r) * reach_eff;\ngvx = fx * reach_eff;                      gvy = fy * reach_eff;\nbvx = (fx*cos_b - fy*sin_b) * reach_eff;  bvy = (fx*sin_b + fy*cos_b) * reach_eff;\n\ncombined_x = prism_r*rvx + prism_g*gvx + prism_b*bvx;\ncombined_y = prism_r*rvy + prism_g*gvy + prism_b*bvy;\n\n// internal scale constant (not a user param, per spec -- tune empirically\n// like f_vf_advect's grad_gain; starting guess, watch in Max)\nout3_scale = 8.0;\n\nout3_x = clamp(combined_x * out3_scale * 0.5 + 0.5, 0.0, 1.0);\nout3_y = clamp(combined_y * out3_scale * 0.5 + 0.5, 0.0, 1.0);\n\nout3 = mix(vec(out3_x, out3_y, 0.5, 1.0), vec(0.5, 0.5, 0.5, 1.0), bypass);\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
									"id": "gen-obj-2",
									"maxclass": "codebox",
									"numinlets": 4,
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
										"gen-obj-2",
										2
									],
									"source": [
										"gen-obj-11",
										0
									]
								}
							},
							{
								"patchline": {
									"destination": [
										"gen-obj-2",
										3
									],
									"source": [
										"gen-obj-12",
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
					"text": "jit.gl.pix vsynth @name vfprism_pix @type char",
					"varname": "vfprism_pix"
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
					"varname": "vfprism_autopattr"
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
						160.0
					],
					"presentation": 1,
					"presentation_rect": [
						0.0,
						0.0,
						190.0,
						160.0
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
					"text": "Prism"
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
						38.0,
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
					"id": "obj-100",
					"maxclass": "inlet",
					"comment": "vecfield",
					"index": 1,
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
					"id": "obj-101",
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
					"id": "obj-103",
					"maxclass": "inlet",
					"comment": "reach mod",
					"index": 2,
					"numinlets": 0,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						150.0,
						30.0,
						30.0,
						30.0
					]
				}
			},
			{
				"box": {
					"id": "obj-104",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						150.0,
						80.0,
						80.0,
						22.0
					],
					"text": "vs_inState"
				}
			},
			{
				"box": {
					"id": "obj-106",
					"maxclass": "inlet",
					"comment": "spread mod",
					"index": 3,
					"numinlets": 0,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						210.0,
						30.0,
						30.0,
						30.0
					]
				}
			},
			{
				"box": {
					"id": "obj-107",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						210.0,
						80.0,
						80.0,
						22.0
					],
					"text": "vs_inState"
				}
			},
			{
				"box": {
					"id": "obj-102",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						90.0,
						130.0,
						160.0,
						22.0
					],
					"text": "prepend param src_vecfield"
				}
			},
			{
				"box": {
					"id": "obj-105",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						150.0,
						130.0,
						160.0,
						22.0
					],
					"text": "prepend param src_length_mod"
				}
			},
			{
				"box": {
					"id": "obj-108",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						210.0,
						130.0,
						160.0,
						22.0
					],
					"text": "prepend param src_width_mod"
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
					"hint": "Displacement distance along field \u2014 how far the prism effect reaches",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "vfprism_pix::reach",
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
								0.05
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "reach",
							"parameter_mmax": 0.3,
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
					"id": "obj-21",
					"maxclass": "attrui",
					"attr": "reach",
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
					"text": "Reach",
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
					"hint": "Angular spread between R/G/B channels \u2014 chromatic separation distance",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "vfprism_pix::spread",
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
							"parameter_longname": "spread",
							"parameter_mmax": 0.5,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "spread",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "spread"
				}
			},
			{
				"box": {
					"id": "obj-24",
					"maxclass": "attrui",
					"attr": "spread",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						100.0,
						200.0,
						122.0,
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
					"text": "Spread",
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
					"hint": "Luma gate \u2014 only bright pixels at sample position cast prism color",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "vfprism_pix::threshold",
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
								0.7
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "threshold",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
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
					"text": "Threshold",
					"textjustification": 1
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
					"hint": "Softness of the luma gate \u2014 blob boundary edge",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "vfprism_pix::threshold_width",
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
								0.1
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "threshold_width",
							"parameter_mmax": 0.5,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "threshold_width",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "threshold_width"
				}
			},
			{
				"box": {
					"id": "obj-30",
					"maxclass": "attrui",
					"attr": "threshold_width",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						200.0,
						260.0,
						185.0,
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
					"text": "Gate Width",
					"textjustification": 1
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
					"hint": "Inter-channel blend \u2014 0=hard RGB separation, high=smooth spectral gradient",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "vfprism_pix::feather",
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
								0.1
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "feather",
							"parameter_mmax": 0.5,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "feather",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "feather"
				}
			},
			{
				"box": {
					"id": "obj-33",
					"maxclass": "attrui",
					"attr": "feather",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						250.0,
						290.0,
						129.0,
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
					"text": "Feather",
					"textjustification": 1
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
					"hint": "Prism intensity \u2014 additive over source, before mix",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "vfprism_pix::gain",
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
								1.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "gain",
							"parameter_mmax": 2.0,
							"parameter_mmin": 0.0,
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
					"id": "obj-36",
					"maxclass": "attrui",
					"attr": "gain",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						300.0,
						320.0,
						108.0,
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
					"text": "Gain",
					"textjustification": 1
				}
			},
			{
				"box": {
					"id": "obj-38",
					"maxclass": "live.numbox",
					"fontname": "Ableton Sans Light",
					"hint": "% strength toward the fully-composited (source+effect) state \u2014 a continuous blend, not spatial masking. mix=30 means every pixel is 30% of the way from source toward its own 100%-effect value. (internal Param named mix_pct to avoid colliding with the codebox's mix() operator \u2014 see jit-gen-codebox skill)",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "vfprism_pix::mix_pct",
					"parameter_enable": 1,
					"patching_rect": [
						350.0,
						80.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						41.0,
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
					"id": "obj-39",
					"maxclass": "attrui",
					"attr": "mix_pct",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						350.0,
						350.0,
						129.0,
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
					"text": "Mix",
					"textjustification": 1
				}
			},
			{
				"box": {
					"id": "obj-41",
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
					"id": "obj-42",
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
						"obj-100",
						0
					],
					"destination": [
						"obj-101",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-101",
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
						"obj-101",
						1
					],
					"destination": [
						"obj-102",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-102",
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
						"obj-103",
						0
					],
					"destination": [
						"obj-104",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-104",
						0
					],
					"destination": [
						"obj-5",
						2
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-104",
						1
					],
					"destination": [
						"obj-105",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-105",
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
						"obj-106",
						0
					],
					"destination": [
						"obj-107",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-107",
						0
					],
					"destination": [
						"obj-5",
						3
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-107",
						1
					],
					"destination": [
						"obj-108",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-108",
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
			}
		],
		"parameters": {
			"obj-20": [
				"reach",
				"reach",
				0
			],
			"obj-23": [
				"spread",
				"spread",
				0
			],
			"obj-26": [
				"threshold",
				"threshold",
				0
			],
			"obj-29": [
				"threshold_width",
				"threshold_width",
				0
			],
			"obj-32": [
				"feather",
				"feather",
				0
			],
			"obj-35": [
				"gain",
				"gain",
				0
			],
			"obj-38": [
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