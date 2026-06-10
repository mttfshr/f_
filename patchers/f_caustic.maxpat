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
					"comment": "caustic",
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
						252.0,
						22.0
					],
					"text": "route intensity scale softness color_shift"
				}
			},
			{
				"box": {
					"id": "obj-5",
					"maxclass": "newobj",
					"numinlets": 3,
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
									"code": "// f_caustic codebox v1 \u2014 scratch validation\n// Additive streamline accumulation weighted by local convergence (negative divergence)\n// in2 = light source texture\n// in3 = f_vecfield (f_vortex RG output, encoded: 0.5 = zero, 0=neg, 1=pos)\n\nParam intensity(0.5);\nParam scale(0.3);\nParam softness(0.3);\nParam color_shift(0.0);\nParam bypass(0.0);\n\nuv = norm;\n\n// finite difference offset for divergence estimation\nh = 1.0 / 512.0;\n\n// step size in UV space \u2014 scale drives trace distance\nstep_size = scale / 8.0;\ncs = color_shift * step_size;\n\n// --- accumulation loop (8 steps, unrolled) ---\n// at each step: walk backward along field, sample source, weight by convergence\n\n// helper: decode field channel from [0,1] to [-1,1]\n// NOTE: always decoded inline on sample() \u2014 never stored then accessed\n\n// --- step 0: at current pixel ---\npos0x = uv.x;\npos0y = uv.y;\n\n// decode field at pos0\nf0x = (sample(in3, vec(pos0x, pos0y)).x - 0.5) * 2.0;\nf0y = (sample(in3, vec(pos0x, pos0y)).y - 0.5) * 2.0;\n\n// divergence at pos0 via finite differences on field\ndiv0 = ((sample(in3, vec(pos0x + h, pos0y)).x - sample(in3, vec(pos0x - h, pos0y)).x) * 2.0 / (2.0 * h))\n      + ((sample(in3, vec(pos0x, pos0y + h)).y - sample(in3, vec(pos0x, pos0y - h)).y) * 2.0 / (2.0 * h));\n\n// convergence weight: accumulate only where div < 0 (converging zones)\nw0 = max(-div0, 0.0);\n\n// source sample at pos0 (R channel for now, extend to RGB below)\nsrc0r = sample(in2, vec(pos0x + f0x * cs, pos0y + f0y * cs)).x;\nsrc0g = sample(in2, vec(pos0x, pos0y)).y;\nsrc0b = sample(in2, vec(pos0x - f0x * cs, pos0y - f0y * cs)).z;\n\n// --- step 1: walk backward one step ---\npos1x = pos0x - f0x * step_size;\npos1y = pos0y - f0y * step_size;\n\nf1x = (sample(in3, vec(pos1x, pos1y)).x - 0.5) * 2.0;\nf1y = (sample(in3, vec(pos1x, pos1y)).y - 0.5) * 2.0;\n\ndiv1 = ((sample(in3, vec(pos1x + h, pos1y)).x - sample(in3, vec(pos1x - h, pos1y)).x) * 2.0 / (2.0 * h))\n      + ((sample(in3, vec(pos1x, pos1y + h)).y - sample(in3, vec(pos1x, pos1y - h)).y) * 2.0 / (2.0 * h));\n\nw1 = max(-div1, 0.0);\n\nsrc1r = sample(in2, vec(pos1x + f1x * cs, pos1y + f1y * cs)).x;\nsrc1g = sample(in2, vec(pos1x, pos1y)).y;\nsrc1b = sample(in2, vec(pos1x - f1x * cs, pos1y - f1y * cs)).z;\n\n// --- step 2 ---\npos2x = pos1x - f1x * step_size;\npos2y = pos1y - f1y * step_size;\n\nf2x = (sample(in3, vec(pos2x, pos2y)).x - 0.5) * 2.0;\nf2y = (sample(in3, vec(pos2x, pos2y)).y - 0.5) * 2.0;\n\ndiv2 = ((sample(in3, vec(pos2x + h, pos2y)).x - sample(in3, vec(pos2x - h, pos2y)).x) * 2.0 / (2.0 * h))\n      + ((sample(in3, vec(pos2x, pos2y + h)).y - sample(in3, vec(pos2x, pos2y - h)).y) * 2.0 / (2.0 * h));\n\nw2 = max(-div2, 0.0);\n\nsrc2r = sample(in2, vec(pos2x + f2x * cs, pos2y + f2y * cs)).x;\nsrc2g = sample(in2, vec(pos2x, pos2y)).y;\nsrc2b = sample(in2, vec(pos2x - f2x * cs, pos2y - f2y * cs)).z;\n\n// --- step 3 ---\npos3x = pos2x - f2x * step_size;\npos3y = pos2y - f2y * step_size;\n\nf3x = (sample(in3, vec(pos3x, pos3y)).x - 0.5) * 2.0;\nf3y = (sample(in3, vec(pos3x, pos3y)).y - 0.5) * 2.0;\n\ndiv3 = ((sample(in3, vec(pos3x + h, pos3y)).x - sample(in3, vec(pos3x - h, pos3y)).x) * 2.0 / (2.0 * h))\n      + ((sample(in3, vec(pos3x, pos3y + h)).y - sample(in3, vec(pos3x, pos3y - h)).y) * 2.0 / (2.0 * h));\n\nw3 = max(-div3, 0.0);\n\nsrc3r = sample(in2, vec(pos3x + f3x * cs, pos3y + f3y * cs)).x;\nsrc3g = sample(in2, vec(pos3x, pos3y)).y;\nsrc3b = sample(in2, vec(pos3x - f3x * cs, pos3y - f3y * cs)).z;\n\n// --- step 4 ---\npos4x = pos3x - f3x * step_size;\npos4y = pos3y - f3y * step_size;\n\nf4x = (sample(in3, vec(pos4x, pos4y)).x - 0.5) * 2.0;\nf4y = (sample(in3, vec(pos4x, pos4y)).y - 0.5) * 2.0;\n\ndiv4 = ((sample(in3, vec(pos4x + h, pos4y)).x - sample(in3, vec(pos4x - h, pos4y)).x) * 2.0 / (2.0 * h))\n      + ((sample(in3, vec(pos4x, pos4y + h)).y - sample(in3, vec(pos4x, pos4y - h)).y) * 2.0 / (2.0 * h));\n\nw4 = max(-div4, 0.0);\n\nsrc4r = sample(in2, vec(pos4x + f4x * cs, pos4y + f4y * cs)).x;\nsrc4g = sample(in2, vec(pos4x, pos4y)).y;\nsrc4b = sample(in2, vec(pos4x - f4x * cs, pos4y - f4y * cs)).z;\n\n// --- step 5 ---\npos5x = pos4x - f4x * step_size;\npos5y = pos4y - f4y * step_size;\n\nf5x = (sample(in3, vec(pos5x, pos5y)).x - 0.5) * 2.0;\nf5y = (sample(in3, vec(pos5x, pos5y)).y - 0.5) * 2.0;\n\ndiv5 = ((sample(in3, vec(pos5x + h, pos5y)).x - sample(in3, vec(pos5x - h, pos5y)).x) * 2.0 / (2.0 * h))\n      + ((sample(in3, vec(pos5x, pos5y + h)).y - sample(in3, vec(pos5x, pos5y - h)).y) * 2.0 / (2.0 * h));\n\nw5 = max(-div5, 0.0);\n\nsrc5r = sample(in2, vec(pos5x + f5x * cs, pos5y + f5y * cs)).x;\nsrc5g = sample(in2, vec(pos5x, pos5y)).y;\nsrc5b = sample(in2, vec(pos5x - f5x * cs, pos5y - f5y * cs)).z;\n\n// --- step 6 ---\npos6x = pos5x - f5x * step_size;\npos6y = pos5y - f5y * step_size;\n\nf6x = (sample(in3, vec(pos6x, pos6y)).x - 0.5) * 2.0;\nf6y = (sample(in3, vec(pos6x, pos6y)).y - 0.5) * 2.0;\n\ndiv6 = ((sample(in3, vec(pos6x + h, pos6y)).x - sample(in3, vec(pos6x - h, pos6y)).x) * 2.0 / (2.0 * h))\n      + ((sample(in3, vec(pos6x, pos6y + h)).y - sample(in3, vec(pos6x, pos6y - h)).y) * 2.0 / (2.0 * h));\n\nw6 = max(-div6, 0.0);\n\nsrc6r = sample(in2, vec(pos6x + f6x * cs, pos6y + f6y * cs)).x;\nsrc6g = sample(in2, vec(pos6x, pos6y)).y;\nsrc6b = sample(in2, vec(pos6x - f6x * cs, pos6y - f6y * cs)).z;\n\n// --- step 7 ---\npos7x = pos6x - f6x * step_size;\npos7y = pos6y - f6y * step_size;\n\nf7x = (sample(in3, vec(pos7x, pos7y)).x - 0.5) * 2.0;\nf7y = (sample(in3, vec(pos7x, pos7y)).y - 0.5) * 2.0;\n\ndiv7 = ((sample(in3, vec(pos7x + h, pos7y)).x - sample(in3, vec(pos7x - h, pos7y)).x) * 2.0 / (2.0 * h))\n      + ((sample(in3, vec(pos7x, pos7y + h)).y - sample(in3, vec(pos7x, pos7y - h)).y) * 2.0 / (2.0 * h));\n\nw7 = max(-div7, 0.0);\n\nsrc7r = sample(in2, vec(pos7x + f7x * cs, pos7y + f7y * cs)).x;\nsrc7g = sample(in2, vec(pos7x, pos7y)).y;\nsrc7b = sample(in2, vec(pos7x - f7x * cs, pos7y - f7y * cs)).z;\n\n// --- weighted accumulation ---\n// accumulate weighted sums per channel\naccum_r = (w0 * src0r + w1 * src1r + w2 * src2r + w3 * src3r\n         + w4 * src4r + w5 * src5r + w6 * src6r + w7 * src7r);\naccum_g = (w0 * src0g + w1 * src1g + w2 * src2g + w3 * src3g\n         + w4 * src4g + w5 * src5g + w6 * src6g + w7 * src7g);\naccum_b = (w0 * src0b + w1 * src1b + w2 * src2b + w3 * src3b\n         + w4 * src4b + w5 * src5b + w6 * src6b + w7 * src7b);\n\n// normalize by step count and apply intensity\nnorm_factor = 1.0 / 8.0;\ncaustic_r = accum_r * norm_factor * intensity;\ncaustic_g = accum_g * norm_factor * intensity;\ncaustic_b = accum_b * norm_factor * intensity;\n\n// softness: smoothstep on caustic luma to soften/harden bands\nluma = caustic_r * 0.299 + caustic_g * 0.587 + caustic_b * 0.114;\nsoft_mask = smoothstep(0.0, softness + 0.001, luma);\ncaustic_r = caustic_r * soft_mask;\ncaustic_g = caustic_g * soft_mask;\ncaustic_b = caustic_b * soft_mask;\n\n// out2: isolated caustic layer\ncaustic_out = vec(clamp(caustic_r, 0.0, 1.0),\n                  clamp(caustic_g, 0.0, 1.0),\n                  clamp(caustic_b, 0.0, 1.0),\n                  1.0);\n\n// out1: additive composite over source\nsrc_r = sample(in2, uv).x;\nsrc_g = sample(in2, uv).y;\nsrc_b = sample(in2, uv).z;\n\ncomposite = vec(clamp(src_r + caustic_r, 0.0, 1.0),\n                clamp(src_g + caustic_g, 0.0, 1.0),\n                clamp(src_b + caustic_b, 0.0, 1.0),\n                1.0);\n\n// bypass: out1 passes source, out2 goes black\nsource_pass = vec(src_r, src_g, src_b, 1.0);\nblack = vec(0.0, 0.0, 0.0, 1.0);\n\nout1 = mix(composite, source_pass, bypass);\nout2 = mix(caustic_out, black, bypass);\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
									"id": "gen-obj-2",
									"maxclass": "codebox",
									"numinlets": 3,
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
					"text": "jit.gl.pix vsynth @name caustic_pix @type float32",
					"varname": "caustic_pix"
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
					"varname": "caustic_autopattr"
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
					"text": "Caustic"
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
					"comment": "texture",
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
					"comment": "vecfield",
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
					"id": "obj-20",
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
					"param_connect": "caustic_pix::intensity",
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
								0.5
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "intensity",
							"parameter_mmax": 2.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "intensity",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "intensity"
				}
			},
			{
				"box": {
					"id": "obj-21",
					"maxclass": "attrui",
					"attr": "intensity",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						50.0,
						170.0,
						143.0,
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
					"text": "Intens",
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
					"hint": "",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "caustic_pix::scale",
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
								0.3
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "scale",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
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
					"id": "obj-24",
					"maxclass": "attrui",
					"attr": "scale",
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
					"text": "Scale",
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
					"param_connect": "caustic_pix::softness",
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
							"parameter_longname": "softness",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
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
					"id": "obj-27",
					"maxclass": "attrui",
					"attr": "softness",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						150.0,
						230.0,
						136.0,
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
					"text": "Soft",
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
					"param_connect": "caustic_pix::color_shift",
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
							"parameter_longname": "color_shift",
							"parameter_mmax": 1.0,
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
					"id": "obj-30",
					"maxclass": "attrui",
					"attr": "color_shift",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						200.0,
						260.0,
						157.0,
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
					"text": "Color",
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
						"obj-103",
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
				"intensity",
				"intensity",
				0
			],
			"obj-23": [
				"scale",
				"scale",
				0
			],
			"obj-26": [
				"softness",
				"softness",
				0
			],
			"obj-29": [
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