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
					"comment": "composite",
					"index": 0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						30.0,
						502.0,
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
					"index": 0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						100.0,
						502.0,
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
						56.5,
						204.0,
						511.0,
						22.0
					],
					"text": "route mix_pct gain scale softness color_shift mode detail"
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
									"code": "// f_caustic codebox v2 \u2014 separate source and vecfield inlets\n// in1 = light source texture\n// in2 = f_vecfield (RG encoded: 0.5 = zero, 0=neg, 1=pos)\n// `intensity` renamed to `gain`, `strength` renamed to `mix_pct` (UI:\n// `mix`, 0-100% numbox) 2026-07-12 to match the library-wide gain/mix\n// naming convention (vsynth-bpatcher skill). Range for the crossfade\n// capped to true 0-100% (dropping the old 1.0-1.5 extrapolation zone\n// `strength` used to allow) -- math for gain unchanged, mix default\n// kept at 0 (off by default, matching this module's original load\n// behavior; not 100 like f_vf_prism/f_vf_advect's convention, Matt's\n// explicit call 2026-07-12).\n\nParam gain(0.5);\nParam scale(0.3);\nParam softness(0.3);\nParam color_shift(0.0);\nParam mix_pct(0.0);\nParam bypass_gate(0.0);\n\nuv = norm;\n\nh = 1.0 / 512.0;\nstep_size = scale / 8.0;\ncs = color_shift * step_size;\n\n// --- step 0 ---\npos0x = uv.x;\npos0y = uv.y;\n\nf0x = (sample(in2, vec(pos0x, pos0y)).x - 0.5) * 2.0;\nf0y = (sample(in2, vec(pos0x, pos0y)).y - 0.5) * 2.0;\n\ndiv0 = ((sample(in2, vec(pos0x + h, pos0y)).x - sample(in2, vec(pos0x - h, pos0y)).x) * 2.0 / (2.0 * h))\n      + ((sample(in2, vec(pos0x, pos0y + h)).y - sample(in2, vec(pos0x, pos0y - h)).y) * 2.0 / (2.0 * h));\n\nw0 = max(-div0, 0.0);\n\nsrc0r = sample(in1, vec(pos0x + f0x * cs, pos0y + f0y * cs)).x;\nsrc0g = sample(in1, vec(pos0x, pos0y)).y;\nsrc0b = sample(in1, vec(pos0x - f0x * cs, pos0y - f0y * cs)).z;\n\n// --- step 1 ---\npos1x = pos0x - f0x * step_size;\npos1y = pos0y - f0y * step_size;\n\nf1x = (sample(in2, vec(pos1x, pos1y)).x - 0.5) * 2.0;\nf1y = (sample(in2, vec(pos1x, pos1y)).y - 0.5) * 2.0;\n\ndiv1 = ((sample(in2, vec(pos1x + h, pos1y)).x - sample(in2, vec(pos1x - h, pos1y)).x) * 2.0 / (2.0 * h))\n      + ((sample(in2, vec(pos1x, pos1y + h)).y - sample(in2, vec(pos1x, pos1y - h)).y) * 2.0 / (2.0 * h));\n\nw1 = max(-div1, 0.0);\n\nsrc1r = sample(in1, vec(pos1x + f1x * cs, pos1y + f1y * cs)).x;\nsrc1g = sample(in1, vec(pos1x, pos1y)).y;\nsrc1b = sample(in1, vec(pos1x - f1x * cs, pos1y - f1y * cs)).z;\n\n// --- step 2 ---\npos2x = pos1x - f1x * step_size;\npos2y = pos1y - f1y * step_size;\n\nf2x = (sample(in2, vec(pos2x, pos2y)).x - 0.5) * 2.0;\nf2y = (sample(in2, vec(pos2x, pos2y)).y - 0.5) * 2.0;\n\ndiv2 = ((sample(in2, vec(pos2x + h, pos2y)).x - sample(in2, vec(pos2x - h, pos2y)).x) * 2.0 / (2.0 * h))\n      + ((sample(in2, vec(pos2x, pos2y + h)).y - sample(in2, vec(pos2x, pos2y - h)).y) * 2.0 / (2.0 * h));\n\nw2 = max(-div2, 0.0);\n\nsrc2r = sample(in1, vec(pos2x + f2x * cs, pos2y + f2y * cs)).x;\nsrc2g = sample(in1, vec(pos2x, pos2y)).y;\nsrc2b = sample(in1, vec(pos2x - f2x * cs, pos2y - f2y * cs)).z;\n\n// --- step 3 ---\npos3x = pos2x - f2x * step_size;\npos3y = pos2y - f2y * step_size;\n\nf3x = (sample(in2, vec(pos3x, pos3y)).x - 0.5) * 2.0;\nf3y = (sample(in2, vec(pos3x, pos3y)).y - 0.5) * 2.0;\n\ndiv3 = ((sample(in2, vec(pos3x + h, pos3y)).x - sample(in2, vec(pos3x - h, pos3y)).x) * 2.0 / (2.0 * h))\n      + ((sample(in2, vec(pos3x, pos3y + h)).y - sample(in2, vec(pos3x, pos3y - h)).y) * 2.0 / (2.0 * h));\n\nw3 = max(-div3, 0.0);\n\nsrc3r = sample(in1, vec(pos3x + f3x * cs, pos3y + f3y * cs)).x;\nsrc3g = sample(in1, vec(pos3x, pos3y)).y;\nsrc3b = sample(in1, vec(pos3x - f3x * cs, pos3y - f3y * cs)).z;\n\n// --- step 4 ---\npos4x = pos3x - f3x * step_size;\npos4y = pos3y - f3y * step_size;\n\nf4x = (sample(in2, vec(pos4x, pos4y)).x - 0.5) * 2.0;\nf4y = (sample(in2, vec(pos4x, pos4y)).y - 0.5) * 2.0;\n\ndiv4 = ((sample(in2, vec(pos4x + h, pos4y)).x - sample(in2, vec(pos4x - h, pos4y)).x) * 2.0 / (2.0 * h))\n      + ((sample(in2, vec(pos4x, pos4y + h)).y - sample(in2, vec(pos4x, pos4y - h)).y) * 2.0 / (2.0 * h));\n\nw4 = max(-div4, 0.0);\n\nsrc4r = sample(in1, vec(pos4x + f4x * cs, pos4y + f4y * cs)).x;\nsrc4g = sample(in1, vec(pos4x, pos4y)).y;\nsrc4b = sample(in1, vec(pos4x - f4x * cs, pos4y - f4y * cs)).z;\n\n// --- step 5 ---\npos5x = pos4x - f4x * step_size;\npos5y = pos4y - f4y * step_size;\n\nf5x = (sample(in2, vec(pos5x, pos5y)).x - 0.5) * 2.0;\nf5y = (sample(in2, vec(pos5x, pos5y)).y - 0.5) * 2.0;\n\ndiv5 = ((sample(in2, vec(pos5x + h, pos5y)).x - sample(in2, vec(pos5x - h, pos5y)).x) * 2.0 / (2.0 * h))\n      + ((sample(in2, vec(pos5x, pos5y + h)).y - sample(in2, vec(pos5x, pos5y - h)).y) * 2.0 / (2.0 * h));\n\nw5 = max(-div5, 0.0);\n\nsrc5r = sample(in1, vec(pos5x + f5x * cs, pos5y + f5y * cs)).x;\nsrc5g = sample(in1, vec(pos5x, pos5y)).y;\nsrc5b = sample(in1, vec(pos5x - f5x * cs, pos5y - f5y * cs)).z;\n\n// --- step 6 ---\npos6x = pos5x - f5x * step_size;\npos6y = pos5y - f5y * step_size;\n\nf6x = (sample(in2, vec(pos6x, pos6y)).x - 0.5) * 2.0;\nf6y = (sample(in2, vec(pos6x, pos6y)).y - 0.5) * 2.0;\n\ndiv6 = ((sample(in2, vec(pos6x + h, pos6y)).x - sample(in2, vec(pos6x - h, pos6y)).x) * 2.0 / (2.0 * h))\n      + ((sample(in2, vec(pos6x, pos6y + h)).y - sample(in2, vec(pos6x, pos6y - h)).y) * 2.0 / (2.0 * h));\n\nw6 = max(-div6, 0.0);\n\nsrc6r = sample(in1, vec(pos6x + f6x * cs, pos6y + f6y * cs)).x;\nsrc6g = sample(in1, vec(pos6x, pos6y)).y;\nsrc6b = sample(in1, vec(pos6x - f6x * cs, pos6y - f6y * cs)).z;\n\n// --- step 7 ---\npos7x = pos6x - f6x * step_size;\npos7y = pos6y - f6y * step_size;\n\nf7x = (sample(in2, vec(pos7x, pos7y)).x - 0.5) * 2.0;\nf7y = (sample(in2, vec(pos7x, pos7y)).y - 0.5) * 2.0;\n\ndiv7 = ((sample(in2, vec(pos7x + h, pos7y)).x - sample(in2, vec(pos7x - h, pos7y)).x) * 2.0 / (2.0 * h))\n      + ((sample(in2, vec(pos7x, pos7y + h)).y - sample(in2, vec(pos7x, pos7y - h)).y) * 2.0 / (2.0 * h));\n\nw7 = max(-div7, 0.0);\n\nsrc7r = sample(in1, vec(pos7x + f7x * cs, pos7y + f7y * cs)).x;\nsrc7g = sample(in1, vec(pos7x, pos7y)).y;\nsrc7b = sample(in1, vec(pos7x - f7x * cs, pos7y - f7y * cs)).z;\n\n// --- weighted accumulation ---\naccum_r = (w0 * src0r + w1 * src1r + w2 * src2r + w3 * src3r\n         + w4 * src4r + w5 * src5r + w6 * src6r + w7 * src7r);\naccum_g = (w0 * src0g + w1 * src1g + w2 * src2g + w3 * src3g\n         + w4 * src4g + w5 * src5g + w6 * src6g + w7 * src7g);\naccum_b = (w0 * src0b + w1 * src1b + w2 * src2b + w3 * src3b\n         + w4 * src4b + w5 * src5b + w6 * src6b + w7 * src7b);\n\nnorm_factor = 1.0 / 8.0;\ncaustic_r = accum_r * norm_factor * gain;\ncaustic_g = accum_g * norm_factor * gain;\ncaustic_b = accum_b * norm_factor * gain;\n\nluma = caustic_r * 0.299 + caustic_g * 0.587 + caustic_b * 0.114;\nsoft_mask = smoothstep(0.0, softness + 0.001, luma);\ncaustic_r = caustic_r * soft_mask;\ncaustic_g = caustic_g * soft_mask;\ncaustic_b = caustic_b * soft_mask;\n\ncaustic_out = vec(clamp(caustic_r, 0.0, 1.0),\n                  clamp(caustic_g, 0.0, 1.0),\n                  clamp(caustic_b, 0.0, 1.0),\n                  1.0);\n\nsrc_r = sample(in1, uv).x;\nsrc_g = sample(in1, uv).y;\nsrc_b = sample(in1, uv).z;\n\ncomposite = vec(clamp(src_r + caustic_r, 0.0, 1.0),\n                clamp(src_g + caustic_g, 0.0, 1.0),\n                clamp(src_b + caustic_b, 0.0, 1.0),\n                1.0);\n\nsource_pass = vec(src_r, src_g, src_b, 1.0);\n\ncomposited = mix(source_pass, composite, mix_pct / 100.0);\n// bypass (bypass_mode \"param\"): passthrough on every outlet (Matt, 2026-10-05).\nout1 = mix(composited, source_pass, bypass_gate);\nout2 = mix(caustic_out, source_pass, bypass_gate);\n",
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
						30.0,
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
					"id": "obj-50",
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
									"code": "// f_caustic sheets mode: COMPOSITE stage (spec .specify/f_caustic_scatter/spec.md, \"Composite (sheets)\")\n//\n// in1 = light-source texture. The composite is built over it and this pix FOLLOWS ITS SIZE (@adapt 1, no fixed @dim)\n// in2 = the scatter node's float32 illuminance capture: square, fixed size (the `detail` step), HDR. Read with\n//       sample(in2, norm), which upscales it bilinearly to the output size\n// in3 = f_vecfield, read ONLY by the unconnected-field guard\n//\n// out1 = composite  mix(source, clamp(source + light, 0, 1), mix_pct / 100)\n// out2 = caustic layer, tone mapped and clamped (the same meaning as the soft path's out2)\n//\n// Bypass is NOT handled here: the select stage applies it last (plan ADR-4), so this stage has no bypass_gate.\n//\n// Skill checklist (skills/jit-gen-codebox; the look-patch tone stage broke on the first two):\n//   - functions are defined BEFORE every statement, and a Param declaration is a statement\n//   - components (.x .y .z) are read INLINE on sample(), never on a stored variable\n//   - no Param is named after a built-in (mix, step, ...); no variable named cell/in/norm/snorm/dim\n//   - Param values are not visible inside a function body: pass them as arguments\n\ntm(v, ex) {\n\tt = v / (1.0 + v);\n\treturn pow(t, ex);\n}\n\nParam gain(0.5);\nParam mix_pct(0.0);\n\n// One brightness slider across both modes: `gain` keeps its meaning and the sheets branch applies this constant\n// (calibrated against the soft layer in task T034; 2.0 makes the default gain 0.5 equal the look-patch's lev = 1).\nk_sheets = 2.0;\nexpo = 0.7;          // the tone curve's exponent (Matt's look-patch default, spec Decisions item 3; not exposed)\n\nuv = norm;\n\n// Unconnected-vecfield guard (spec Decisions item 6; probe T008: an unconnected pix inlet reads a constant\n// (0, 0, 0, 1), black WITH alpha 1, so the test must use R and G only). Real vecfields encode zero as 0.5, so a\n// texture that is exactly 0 in R and G at four fixed points is \"no field\": zero the light, keep the source.\nfsum = sample(in3, vec(0.25, 0.25)).x + sample(in3, vec(0.25, 0.25)).y\n     + sample(in3, vec(0.75, 0.25)).x + sample(in3, vec(0.75, 0.25)).y\n     + sample(in3, vec(0.25, 0.75)).x + sample(in3, vec(0.25, 0.75)).y\n     + sample(in3, vec(0.75, 0.75)).x + sample(in3, vec(0.75, 0.75)).y;\npresent = fsum > 0.0;\n\ncaustic_r = tm(sample(in2, uv).x * gain * k_sheets, expo) * present;\ncaustic_g = tm(sample(in2, uv).y * gain * k_sheets, expo) * present;\ncaustic_b = tm(sample(in2, uv).z * gain * k_sheets, expo) * present;\n\ncaustic_out = vec(clamp(caustic_r, 0.0, 1.0),\n                  clamp(caustic_g, 0.0, 1.0),\n                  clamp(caustic_b, 0.0, 1.0),\n                  1.0);\n\nsrc_r = sample(in1, uv).x;\nsrc_g = sample(in1, uv).y;\nsrc_b = sample(in1, uv).z;\n\ncomposite = vec(clamp(src_r + caustic_r, 0.0, 1.0),\n                clamp(src_g + caustic_g, 0.0, 1.0),\n                clamp(src_b + caustic_b, 0.0, 1.0),\n                1.0);\n\nsource_pass = vec(src_r, src_g, src_b, 1.0);\n\nout1 = mix(source_pass, composite, mix_pct / 100.0);\nout2 = caustic_out;\n",
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
						250.0,
						380.0,
						216.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_caustic_sheets @type float32 @adapt 1 @enable 0",
					"varname": "#0_caustic_sheets"
				}
			},
			{
				"box": {
					"id": "obj-51",
					"maxclass": "newobj",
					"numinlets": 3,
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
									"code": "// f_caustic: SELECT stage for the composite (spec .specify/f_caustic_scatter/spec.md, plan ADR-3 / ADR-4)\n//\n// in1 = the SOFT branch's composite (the first outlet of caustic_pix)\n// in2 = the SHEETS branch's composite (the first outlet of sheets_pix)\n// in3 = the light source (for bypass)\n//\n// sheets_gate 0 returns in1 EXACTLY, 1 returns in2 (mix(a, b, 0) = a in float32, so soft mode is bit-identical to the\n// module before the sheets mode existed). bypass_gate then mixes to the source: a bypassed module is a passthrough on\n// every outlet (\"every outlet mixes to its passthrough\", Matt 2026-10-05), in either mode.\n// This stage is split in two (one per outlet) so each fits the codebox bench's three inputs (constitution 2).\n// NOTE: keep the text o-u-t-<digit> out of comments in this file: the bench counts it to size the codebox.\n//\n// Skill checklist: no functions here; components read INLINE on sample(); no Param named after a built-in.\n\nParam sheets_gate(0.0);\nParam bypass_gate(0.0);\n\nuv = norm;\npicked = mix(sample(in1, uv), sample(in2, uv), sheets_gate);\nsource_pass = vec(sample(in3, uv).x, sample(in3, uv).y, sample(in3, uv).z, 1.0);\nout1 = mix(picked, source_pass, bypass_gate);\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
									"id": "gen-obj-2",
									"maxclass": "codebox",
									"numinlets": 3,
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
							}
						]
					},
					"patching_rect": [
						30.0,
						430.0,
						200.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_caustic_selc @type float32 @adapt 1",
					"varname": "#0_caustic_selc"
				}
			},
			{
				"box": {
					"id": "obj-52",
					"maxclass": "newobj",
					"numinlets": 3,
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
									"code": "// f_caustic: SELECT stage for the caustic layer (spec .specify/f_caustic_scatter/spec.md, plan ADR-3 / ADR-4)\n//\n// in1 = the SOFT branch's caustic layer (the second outlet of caustic_pix)\n// in2 = the SHEETS branch's caustic layer (the second outlet of sheets_pix)\n// in3 = the light source (for bypass)\n//\n// sheets_gate 0 returns in1 EXACTLY, 1 returns in2 (mix(a, b, 0) = a in float32, so soft mode is bit-identical to the\n// module before the sheets mode existed). bypass_gate then mixes to the source: a bypassed module is a passthrough on\n// every outlet (\"every outlet mixes to its passthrough\", Matt 2026-10-05), in either mode.\n// This stage is split in two (one per outlet) so each fits the codebox bench's three inputs (constitution 2).\n// NOTE: keep the text o-u-t-<digit> out of comments in this file: the bench counts it to size the codebox.\n//\n// Skill checklist: no functions here; components read INLINE on sample(); no Param named after a built-in.\n\nParam sheets_gate(0.0);\nParam bypass_gate(0.0);\n\nuv = norm;\npicked = mix(sample(in1, uv), sample(in2, uv), sheets_gate);\nsource_pass = vec(sample(in3, uv).x, sample(in3, uv).y, sample(in3, uv).z, 1.0);\nout1 = mix(picked, source_pass, bypass_gate);\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
									"id": "gen-obj-2",
									"maxclass": "codebox",
									"numinlets": 3,
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
							}
						]
					},
					"patching_rect": [
						250.0,
						430.0,
						200.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_caustic_sell @type float32 @adapt 1",
					"varname": "#0_caustic_sell"
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
						760.0,
						260.0,
						227.0,
						122.0
					],
					"presentation": 1,
					"presentation_rect": [
						0.0,
						0.0,
						227.0,
						122.0
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
						1070.0,
						200.0,
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
					"id": "obj-17",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						30.0,
						120.0,
						80.0,
						22.0
					],
					"text": "vs_inState"
				}
			},
			{
				"box": {
					"id": "obj-100",
					"maxclass": "inlet",
					"comment": "vecfield",
					"index": 0,
					"numinlets": 0,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						260.0,
						20.0,
						30.0,
						30.0
					]
				}
			},
			{
				"box": {
					"id": "obj-20",
					"maxclass": "live.numbox",
					"fontname": "Ableton Sans Light",
					"hint": "Dry/wet crossfade toward the fully-composited (source+caustic) state. Renamed from strength 2026-07-12, range capped to true 0-100% (dropping the old 0-1.5 extrapolation zone). Internal Param named mix_pct to avoid colliding with the codebox's mix() operator.",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "caustic_pix::mix_pct",
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
							"parameter_unitstyle": 1
						}
					},
					"varname": "mix_pct"
				}
			},
			{
				"box": {
					"id": "obj-21",
					"maxclass": "attrui",
					"attr": "mix_pct",
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
					"text": "Mix",
					"textjustification": 1,
					"varname": "lbl_mix_pct"
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
					"hint": "Caustic brightness scale. Renamed from intensity 2026-07-12 to match the library-wide gain/mix naming convention. Both modes (the sheets mode applies an internal constant so the same value reads comparably).",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "caustic_pix::gain",
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
								0.5
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
					"id": "obj-24",
					"maxclass": "attrui",
					"attr": "gain",
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
					"hint": "Soft mode: the streamline trace distance. Sheets mode: the propagation distance of the scatter, in UV per unit field (sheets fold over at larger values).",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "caustic_pix::scale",
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
					"id": "obj-27",
					"maxclass": "attrui",
					"attr": "scale",
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
					"text": "Scale",
					"textjustification": 1,
					"varname": "lbl_scale"
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
					"hint": "Soft mode only (ignored in sheets mode).",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "caustic_pix::softness",
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
					"id": "obj-30",
					"maxclass": "attrui",
					"attr": "softness",
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
					"text": "Soft",
					"textjustification": 1,
					"varname": "lbl_softness"
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
					"hint": "Soft mode only (ignored in sheets mode).",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "caustic_pix::color_shift",
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
					"id": "obj-33",
					"maxclass": "attrui",
					"attr": "color_shift",
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
					"text": "Color",
					"textjustification": 1,
					"varname": "lbl_color_shift"
				}
			},
			{
				"box": {
					"id": "obj-35",
					"maxclass": "live.menu",
					"fontname": "Ableton Sans Light",
					"hint": "Soft: the 8-tap gather (thin bright lines). Sheets: a GPU forward scatter that forms overlapping folded sheets at larger Scale.",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"",
						"",
						"float"
					],
					"param_connect": "caustic_pix::mode",
					"parameter_enable": 1,
					"patching_rect": [
						390.0,
						250.0,
						60.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						4.0,
						101.0,
						80.0,
						15.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_enum": [
								"Soft",
								"Sheets"
							],
							"parameter_initial": [
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "mode",
							"parameter_mmax": 1.0,
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
						2.0,
						84.0,
						40.0,
						18.0
					],
					"text": "Mode",
					"textjustification": 1,
					"varname": "lbl_mode"
				}
			},
			{
				"box": {
					"id": "obj-38",
					"maxclass": "live.menu",
					"fontname": "Ableton Sans Light",
					"hint": "Sheets mode: capture size and points per pixel (a quality / cost ladder; the output size does not change the cost). Changing it rebuilds the lattice: set it up, do not automate it.",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"",
						"",
						"float"
					],
					"param_connect": "caustic_pix::detail",
					"parameter_enable": 1,
					"patching_rect": [
						462.0,
						250.0,
						60.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						94.0,
						101.0,
						126.0,
						15.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_enum": [
								"1: 256 sq 2/px",
								"2: 512 sq 2/px",
								"3: 768 sq 2/px",
								"4: 1024 sq 2/px",
								"5: 1024 sq 4/px"
							],
							"parameter_initial": [
								4.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "detail",
							"parameter_mmax": 4.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 0,
							"parameter_shortname": "detail",
							"parameter_type": 2,
							"parameter_unitstyle": 0
						}
					},
					"varname": "detail"
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
						92.0,
						84.0,
						50.0,
						18.0
					],
					"text": "Detail",
					"textjustification": 1,
					"varname": "lbl_detail"
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
						980.0,
						130.0,
						18.0,
						12.0
					],
					"presentation_rect": [
						205.0,
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
			},
			{
				"box": {
					"id": "obj-920",
					"maxclass": "newobj",
					"text": "route scale weight r n detail",
					"numinlets": 1,
					"numoutlets": 6,
					"outlettype": [
						"",
						"",
						"",
						"",
						"",
						""
					],
					"patching_rect": [
						30.0,
						632.0,
						360.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-901",
					"maxclass": "newobj",
					"text": "jit.gl.slab vsynth @inputs 1 @rectangle 0 @type float32",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"jit_gl_texture",
						""
					],
					"patching_rect": [
						30.0,
						692.0,
						330.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-902",
					"maxclass": "newobj",
					"text": "jit.gl.slab vsynth @inputs 1 @rectangle 0 @type float32",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"jit_gl_texture",
						""
					],
					"patching_rect": [
						410.0,
						692.0,
						330.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-903",
					"maxclass": "newobj",
					"text": "route out_name",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						30.0,
						732.0,
						100.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-904",
					"maxclass": "newobj",
					"text": "route out_name",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						410.0,
						732.0,
						100.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-905",
					"maxclass": "newobj",
					"text": "join",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						30.0,
						772.0,
						60.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-906",
					"maxclass": "newobj",
					"text": "prepend texture",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						30.0,
						812.0,
						110.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-907",
					"maxclass": "newobj",
					"text": "r draw",
					"numinlets": 0,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						190.0,
						662.0,
						50.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-908",
					"maxclass": "message",
					"text": "getout_name",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						190.0,
						692.0,
						90.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-909",
					"maxclass": "newobj",
					"text": "jit.gl.node vsynth @capture 1 @name #0.node @type float32 @adapt 0 @dim 1024 1024 @erase_color 0 0 0 0 @enable 0",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"jit_gl_texture",
						"",
						""
					],
					"patching_rect": [
						410.0,
						872.0,
						400.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-910",
					"maxclass": "newobj",
					"text": "jit.gl.shader vsynth @name #0.sc @file f_caustic_sheets.jxs",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						30.0,
						872.0,
						330.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-911",
					"maxclass": "newobj",
					"text": "jit.gl.gridshape vsynth @shape plane @dim 2 2 @matrixoutput 1 @automatic 0",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"jit_matrix",
						""
					],
					"patching_rect": [
						30.0,
						972.0,
						400.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-912",
					"maxclass": "newobj",
					"text": "jit.gl.mesh #0.node @draw_mode points @shader #0.sc @blend_enable 1 @blend_mode 1 1 @depth_enable 0 @point_size 2 @color 1 1 1 1 @lighting_enable 0 @enable 0",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						30.0,
						1012.0,
						600.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-921",
					"maxclass": "newobj",
					"text": "prepend param scale",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						30.0,
						922.0,
						130.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-922",
					"maxclass": "newobj",
					"text": "prepend param weight",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						170.0,
						922.0,
						140.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-923",
					"maxclass": "newobj",
					"text": "prepend param res",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						320.0,
						922.0,
						120.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-924",
					"maxclass": "message",
					"text": "dim $1 $1",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						450.0,
						922.0,
						70.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-925",
					"maxclass": "message",
					"text": "dim $1 $1, bang",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						530.0,
						922.0,
						110.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-930",
					"maxclass": "newobj",
					"text": "select 1 2 3 4 5",
					"numinlets": 1,
					"numoutlets": 6,
					"outlettype": [
						"bang",
						"bang",
						"bang",
						"bang",
						"bang",
						""
					],
					"patching_rect": [
						650.0,
						632.0,
						130.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-931",
					"maxclass": "message",
					"text": "r 256, weight 0.5001, n 362",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						650.0,
						672.0,
						330.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-932",
					"maxclass": "message",
					"text": "r 512, weight 0.5001, n 724",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						650.0,
						702.0,
						330.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-933",
					"maxclass": "message",
					"text": "r 768, weight 0.5001, n 1086",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						650.0,
						732.0,
						330.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-934",
					"maxclass": "message",
					"text": "r 1024, weight 0.5001, n 1448",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						650.0,
						762.0,
						330.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-935",
					"maxclass": "message",
					"text": "r 1024, weight 0.2500, n 2048",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						650.0,
						792.0,
						330.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-947",
					"maxclass": "newobj",
					"text": "prepend scale",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						30.0,
						592.0,
						100.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-942",
					"maxclass": "newobj",
					"text": "+ 1",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"int"
					],
					"patching_rect": [
						810.0,
						622.0,
						40.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-943",
					"maxclass": "newobj",
					"text": "t i i",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"int",
						"int"
					],
					"patching_rect": [
						810.0,
						652.0,
						50.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-944",
					"maxclass": "newobj",
					"text": "i 5",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"int"
					],
					"patching_rect": [
						890.0,
						682.0,
						50.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-945",
					"maxclass": "newobj",
					"text": "gate 1 0",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						810.0,
						712.0,
						70.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-946",
					"maxclass": "newobj",
					"text": "prepend detail",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						810.0,
						742.0,
						100.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-950",
					"maxclass": "newobj",
					"text": "t i i i i",
					"numinlets": 1,
					"numoutlets": 4,
					"outlettype": [
						"int",
						"int",
						"int",
						"int"
					],
					"patching_rect": [
						710.0,
						632.0,
						90.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-951",
					"maxclass": "newobj",
					"text": "prepend param sheets_gate",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						710.0,
						772.0,
						170.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-952",
					"maxclass": "message",
					"text": "enable $1",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						710.0,
						812.0,
						70.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-955",
					"maxclass": "newobj",
					"text": "select 1",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"bang",
						""
					],
					"patching_rect": [
						710.0,
						912.0,
						60.0,
						22.0
					]
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
						"obj-17",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-17",
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
						"obj-17",
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
						"obj-17",
						0
					],
					"destination": [
						"obj-51",
						2
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-17",
						0
					],
					"destination": [
						"obj-52",
						2
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-17",
						0
					],
					"destination": [
						"obj-901",
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
						"obj-51",
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
						0
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
						"obj-5",
						1
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
						"obj-50",
						2
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
						"obj-902",
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
						"obj-42",
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
						"obj-42",
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
						"obj-52",
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
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-50",
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
						"obj-21",
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
						"obj-901",
						1
					],
					"destination": [
						"obj-903",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-902",
						1
					],
					"destination": [
						"obj-904",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-903",
						0
					],
					"destination": [
						"obj-905",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-904",
						0
					],
					"destination": [
						"obj-905",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-905",
						0
					],
					"destination": [
						"obj-906",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-907",
						0
					],
					"destination": [
						"obj-908",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-908",
						0
					],
					"destination": [
						"obj-901",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-908",
						0
					],
					"destination": [
						"obj-902",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-911",
						0
					],
					"destination": [
						"obj-912",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-906",
						0
					],
					"destination": [
						"obj-912",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-920",
						0
					],
					"destination": [
						"obj-921",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-920",
						1
					],
					"destination": [
						"obj-922",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-920",
						2
					],
					"destination": [
						"obj-923",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-920",
						2
					],
					"destination": [
						"obj-924",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-920",
						3
					],
					"destination": [
						"obj-925",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-921",
						0
					],
					"destination": [
						"obj-910",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-922",
						0
					],
					"destination": [
						"obj-910",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-923",
						0
					],
					"destination": [
						"obj-910",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-924",
						0
					],
					"destination": [
						"obj-909",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-925",
						0
					],
					"destination": [
						"obj-911",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-920",
						4
					],
					"destination": [
						"obj-930",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-930",
						0
					],
					"destination": [
						"obj-931",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-931",
						0
					],
					"destination": [
						"obj-920",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-930",
						1
					],
					"destination": [
						"obj-932",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-932",
						0
					],
					"destination": [
						"obj-920",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-930",
						2
					],
					"destination": [
						"obj-933",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-933",
						0
					],
					"destination": [
						"obj-920",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-930",
						3
					],
					"destination": [
						"obj-934",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-934",
						0
					],
					"destination": [
						"obj-920",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-930",
						4
					],
					"destination": [
						"obj-935",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-935",
						0
					],
					"destination": [
						"obj-920",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-909",
						0
					],
					"destination": [
						"obj-50",
						1
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
						"obj-947",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-947",
						0
					],
					"destination": [
						"obj-920",
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
						"obj-942",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-942",
						0
					],
					"destination": [
						"obj-943",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-943",
						1
					],
					"destination": [
						"obj-944",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-943",
						0
					],
					"destination": [
						"obj-945",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-945",
						0
					],
					"destination": [
						"obj-946",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-944",
						0
					],
					"destination": [
						"obj-946",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-946",
						0
					],
					"destination": [
						"obj-920",
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
						"obj-950",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-950",
						3
					],
					"destination": [
						"obj-945",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-950",
						3
					],
					"destination": [
						"obj-951",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-951",
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
						"obj-951",
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
						"obj-950",
						2
					],
					"destination": [
						"obj-952",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-952",
						0
					],
					"destination": [
						"obj-909",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-952",
						0
					],
					"destination": [
						"obj-912",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-952",
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
						"obj-950",
						0
					],
					"destination": [
						"obj-955",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-955",
						0
					],
					"destination": [
						"obj-944",
						0
					]
				}
			}
		],
		"parameters": {
			"obj-20": [
				"mix_pct",
				"mix_pct",
				0
			],
			"obj-23": [
				"gain",
				"gain",
				0
			],
			"obj-26": [
				"scale",
				"scale",
				0
			],
			"obj-29": [
				"softness",
				"softness",
				0
			],
			"obj-32": [
				"color_shift",
				"color_shift",
				0
			],
			"obj-35": [
				"mode",
				"mode",
				0
			],
			"obj-38": [
				"detail",
				"detail",
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