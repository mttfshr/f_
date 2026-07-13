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
					"comment": "streak",
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
					"numoutlets": 5,
					"outlettype": [
						"",
						"",
						"",
						"",
						""
					],
					"patching_rect": [
						200.0,
						130.0,
						273.0,
						22.0
					],
					"text": "route gain mix_pct length falloff color_shift"
				}
			},
			{
				"box": {
					"id": "obj-5",
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
									"code": "// f_vf_streak codebox v1 \u2014 scratch validation\n// Directional blur: accumulate source texture samples along vecfield streamlines\n// in1 = source texture (char)\n// in2 = f_vecfield (float32, RG=XY, 0.5=zero vector)\n// `strength` renamed to `gain`; `mix` (numbox, 0-100%, internal Param\n// mix_pct) added 2026-07-12 per the library-wide gain/mix naming\n// convention (vsynth-bpatcher skill) -- composite rewritten to the\n// two-stage driven/mix crossfade confirmed correct on f_vf_prism.\n\nParam gain(0.3);\nParam mix_pct(0.0);\nParam length(0.15);\nParam falloff(0.0);\nParam color_shift(0.0);\nParam src_vecfield(0.0);\nParam bypass(0.0);\n\nuv = norm;\n\n// step size in UV space\nstep_size = length / 8.0;\ncs = color_shift * step_size;\n\n// suppress field when inlet unconnected \u2014 vs_black \u2192 -1.0 offset without this\nconnected = step(0.5, src_vecfield);\n\n// falloff weights \u2014 wN = mix(1.0, 1.0 - (n/7.0), falloff)\n// step 0: always 1.0 regardless of falloff\n// step 7: mix(1.0, 0.0, falloff)\nw0 = 1.0;\nw1 = mix(1.0, 1.0 - (1.0/7.0), falloff);\nw2 = mix(1.0, 1.0 - (2.0/7.0), falloff);\nw3 = mix(1.0, 1.0 - (3.0/7.0), falloff);\nw4 = mix(1.0, 1.0 - (4.0/7.0), falloff);\nw5 = mix(1.0, 1.0 - (5.0/7.0), falloff);\nw6 = mix(1.0, 1.0 - (6.0/7.0), falloff);\nw7 = mix(1.0, 0.0, falloff);\n\nw_sum = w0 + w1 + w2 + w3 + w4 + w5 + w6 + w7;\n\n// --- step 0: current pixel ---\npos0x = uv.x;\npos0y = uv.y;\n\nf0x = (sample(in2, vec(pos0x, pos0y)).x - 0.5) * 2.0 * connected;\nf0y = (sample(in2, vec(pos0x, pos0y)).y - 0.5) * 2.0 * connected;\n\nsrc0r = sample(in1, vec(pos0x + f0x * cs, pos0y)).x;\nsrc0g = sample(in1, vec(pos0x,            pos0y)).y;\nsrc0b = sample(in1, vec(pos0x - f0x * cs, pos0y)).z;\n\n// --- step 1 ---\npos1x = pos0x - f0x * step_size;\npos1y = pos0y - f0y * step_size;\n\nf1x = (sample(in2, vec(pos1x, pos1y)).x - 0.5) * 2.0 * connected;\nf1y = (sample(in2, vec(pos1x, pos1y)).y - 0.5) * 2.0 * connected;\n\nsrc1r = sample(in1, vec(pos1x + f1x * cs, pos1y)).x;\nsrc1g = sample(in1, vec(pos1x,            pos1y)).y;\nsrc1b = sample(in1, vec(pos1x - f1x * cs, pos1y)).z;\n\n// --- step 2 ---\npos2x = pos1x - f1x * step_size;\npos2y = pos1y - f1y * step_size;\n\nf2x = (sample(in2, vec(pos2x, pos2y)).x - 0.5) * 2.0 * connected;\nf2y = (sample(in2, vec(pos2x, pos2y)).y - 0.5) * 2.0 * connected;\n\nsrc2r = sample(in1, vec(pos2x + f2x * cs, pos2y)).x;\nsrc2g = sample(in1, vec(pos2x,            pos2y)).y;\nsrc2b = sample(in1, vec(pos2x - f2x * cs, pos2y)).z;\n\n// --- step 3 ---\npos3x = pos2x - f2x * step_size;\npos3y = pos2y - f2y * step_size;\n\nf3x = (sample(in2, vec(pos3x, pos3y)).x - 0.5) * 2.0 * connected;\nf3y = (sample(in2, vec(pos3x, pos3y)).y - 0.5) * 2.0 * connected;\n\nsrc3r = sample(in1, vec(pos3x + f3x * cs, pos3y)).x;\nsrc3g = sample(in1, vec(pos3x,            pos3y)).y;\nsrc3b = sample(in1, vec(pos3x - f3x * cs, pos3y)).z;\n\n// --- step 4 ---\npos4x = pos3x - f3x * step_size;\npos4y = pos3y - f3y * step_size;\n\nf4x = (sample(in2, vec(pos4x, pos4y)).x - 0.5) * 2.0 * connected;\nf4y = (sample(in2, vec(pos4x, pos4y)).y - 0.5) * 2.0 * connected;\n\nsrc4r = sample(in1, vec(pos4x + f4x * cs, pos4y)).x;\nsrc4g = sample(in1, vec(pos4x,            pos4y)).y;\nsrc4b = sample(in1, vec(pos4x - f4x * cs, pos4y)).z;\n\n// --- step 5 ---\npos5x = pos4x - f4x * step_size;\npos5y = pos4y - f4y * step_size;\n\nf5x = (sample(in2, vec(pos5x, pos5y)).x - 0.5) * 2.0 * connected;\nf5y = (sample(in2, vec(pos5x, pos5y)).y - 0.5) * 2.0 * connected;\n\nsrc5r = sample(in1, vec(pos5x + f5x * cs, pos5y)).x;\nsrc5g = sample(in1, vec(pos5x,            pos5y)).y;\nsrc5b = sample(in1, vec(pos5x - f5x * cs, pos5y)).z;\n\n// --- step 6 ---\npos6x = pos5x - f5x * step_size;\npos6y = pos5y - f5y * step_size;\n\nf6x = (sample(in2, vec(pos6x, pos6y)).x - 0.5) * 2.0 * connected;\nf6y = (sample(in2, vec(pos6x, pos6y)).y - 0.5) * 2.0 * connected;\n\nsrc6r = sample(in1, vec(pos6x + f6x * cs, pos6y)).x;\nsrc6g = sample(in1, vec(pos6x,            pos6y)).y;\nsrc6b = sample(in1, vec(pos6x - f6x * cs, pos6y)).z;\n\n// --- step 7 ---\npos7x = pos6x - f6x * step_size;\npos7y = pos6y - f6y * step_size;\n\nf7x = (sample(in2, vec(pos7x, pos7y)).x - 0.5) * 2.0 * connected;\nf7y = (sample(in2, vec(pos7x, pos7y)).y - 0.5) * 2.0 * connected;\n\nsrc7r = sample(in1, vec(pos7x + f7x * cs, pos7y)).x;\nsrc7g = sample(in1, vec(pos7x,            pos7y)).y;\nsrc7b = sample(in1, vec(pos7x - f7x * cs, pos7y)).z;\n\n// --- weighted accumulation and normalization ---\nstreak_r = (w0*src0r + w1*src1r + w2*src2r + w3*src3r + w4*src4r + w5*src5r + w6*src6r + w7*src7r) / w_sum;\nstreak_g = (w0*src0g + w1*src1g + w2*src2g + w3*src3g + w4*src4g + w5*src5g + w6*src6g + w7*src7g) / w_sum;\nstreak_b = (w0*src0b + w1*src1b + w2*src2b + w3*src3b + w4*src4b + w5*src5b + w6*src6b + w7*src7b) / w_sum;\n\nstreak_layer = vec(clamp(streak_r, 0.0, 1.0),\n                   clamp(streak_g, 0.0, 1.0),\n                   clamp(streak_b, 0.0, 1.0),\n                   1.0);\n\n// source pixel for composite and bypass\nsrc_r = sample(in1, uv).x;\nsrc_g = sample(in1, uv).y;\nsrc_b = sample(in1, uv).z;\nsrc_px = vec(src_r, src_g, src_b, 1.0);\n\n// out2: isolated streak layer \u2014 black on bypass\nout2 = mix(streak_layer, vec(0.0, 0.0, 0.0, 1.0), bypass);\n\n// out1: driven = complete effect-applied state (source + streak*gain);\n// mix is a plain continuous blend toward that state, not spatial\n// masking -- same shape confirmed correct on f_vf_prism.\ndriven_r = clamp(src_r + streak_r * gain, 0.0, 1.0);\ndriven_g = clamp(src_g + streak_g * gain, 0.0, 1.0);\ndriven_b = clamp(src_b + streak_b * gain, 0.0, 1.0);\ncomposite = vec(mix(src_r, driven_r, mix_pct / 100.0),\n                mix(src_g, driven_g, mix_pct / 100.0),\n                mix(src_b, driven_b, mix_pct / 100.0),\n                1.0);\nout1 = mix(composite, src_px, bypass);\n",
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
						380.0,
						200.0,
						22.0
					],
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
					"varname": "vfstreak_autopattr"
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
						100.0
					],
					"presentation": 1,
					"presentation_rect": [
						0.0,
						0.0,
						190.0,
						100.0
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
					"text": "Streak"
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
						41.2,
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
					"id": "obj-20",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Streak intensity. Renamed from strength 2026-07-12 to match the library-wide gain/mix naming convention.",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "vfstreak_pix::gain",
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
								0.3
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "gain",
							"parameter_mmax": 1.5,
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
					"id": "obj-21",
					"maxclass": "attrui",
					"attr": "gain",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						50.0,
						170.0,
						108.0,
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
					"text": "Gain",
					"textjustification": 1
				}
			},
			{
				"box": {
					"id": "obj-23",
					"maxclass": "live.numbox",
					"fontname": "Ableton Sans Light",
					"hint": "Dry/wet crossfade toward the fully-composited (source+streak) state. Internal Param named mix_pct to avoid colliding with the codebox's mix() operator. Default 0 (off by default, matching this module's original load behavior).",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "vfstreak_pix::mix_pct",
					"parameter_enable": 1,
					"patching_rect": [
						100.0,
						80.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						41.0,
						38.0,
						34.0,
						15.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								0.0
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
					"id": "obj-24",
					"maxclass": "attrui",
					"attr": "mix_pct",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						100.0,
						200.0,
						129.0,
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
					"text": "Mix",
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
					"hint": "",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "vfstreak_pix::length",
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
								0.15
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "length",
							"parameter_mmax": 20.0,
							"parameter_mmin": 0.0,
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
					"id": "obj-27",
					"maxclass": "attrui",
					"attr": "length",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						150.0,
						230.0,
						122.0,
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
					"text": "Length",
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
					"hint": "",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "vfstreak_pix::falloff",
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
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "falloff",
							"parameter_mmax": 2.5,
							"parameter_mmin": 0.0,
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
					"id": "obj-30",
					"maxclass": "attrui",
					"attr": "falloff",
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
					"text": "Falloff",
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
					"hint": "",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "vfstreak_pix::color_shift",
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
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "color_shift",
							"parameter_mmax": 20.0,
							"parameter_mmin": 0.0,
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
					"id": "obj-33",
					"maxclass": "attrui",
					"attr": "color_shift",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						250.0,
						290.0,
						157.0,
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
					"text": "Color",
					"textjustification": 1
				}
			},
			{
				"box": {
					"id": "obj-35",
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
					"id": "obj-36",
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
			}
		],
		"parameters": {
			"obj-20": [
				"gain",
				"gain",
				0
			],
			"obj-23": [
				"mix_pct",
				"mix_pct",
				0
			],
			"obj-26": [
				"length",
				"length",
				0
			],
			"obj-29": [
				"falloff",
				"falloff",
				0
			],
			"obj-32": [
				"color_shift",
				"color_shift",
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