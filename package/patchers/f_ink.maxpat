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
					"comment": "texture out",
					"index": 0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						30.0,
						802.0,
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
					"text": "route spread bias snap soften edge_pool pool_width mottle mottle_scale dropout tooth_scale seed"
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
									"code": "// f_ink -- stage 1 of 8: non-finite components to 0, before any blur (one NaN in a tap would poison a whole kernel).\n// Mirror: tests/modules/ink/ink_mirror.zap. Its output is also the source that bypass and alpha read in the last stage.\n// abs(x) < 1e30 with switch(): NaN == NaN is TRUE on this GPU, so an x == x test does nothing.\nzap_c(xv) {\n    return switch(abs(xv) < 1e30, xv, 0.0);\n}\n\nout1 = vec(zap_c(nearest(in1, norm).x), zap_c(nearest(in1, norm).y), zap_c(nearest(in1, norm).z), zap_c(nearest(in1, norm).w));\n",
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
						208.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_ink_stage_zap @adapt 0 @dim 256 256 @type float32",
					"varname": "#0_ink_stage_zap"
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
									"code": "// f_ink -- one separable blur pass (spec FR-004, plan ADR-2, T020). Mirror: tests/modules/ink/ink_mirror.blur_pass.\n// Used four times: spread H and V, pool H and V. definition.py renders this template per stage: the radius Param becomes\n// `spread` or `pool_width`, and the axis Param a constant, so every Param left in a shipped stage is driven.\n//   - 15 taps at the fixed offsets -7..7, one texel apart (Matt, 2026-11-08: a stride of 2 combs a 1-texel line).\n//   - The radius only sets the weights: a tent of half-width r + 1, normalized. r = 0 is one tap of weight 1, so a\n//     radius of 0 is exactly the input, and the weights move continuously with the dial.\n//   - The reach is capped at 7 texels (above 1080 it shrinks in frame heights, accepted with the cap).\n//   - Border: clamp-to-edge by integer index (T010, G7), never an out-of-range read.\n//   - nearest() at texel centers, no interpolation (T008 is still to measure). width and height come from render_dim:\n//     `dim` reads 1 in a live jit.gl.pix.\n// radius is in frame heights. axis: 0 horizontal, 1 vertical.\nParam width(1920.0);\nParam height(1080.0);\nParam spread(0.0);\naxis = 0.0;\nradius = spread * 7.0 / 1080.0;\n\nr_tx = clamp(radius * height, 0.0, 7.0);\nix = floor(norm.x * width);\niy = floor(norm.y * height);\nacc = vec(0.0, 0.0, 0.0, 0.0);\nwsum = 0.0;\nfor (k = 0; k < 15; k += 1) {\n    off = k - 7.0;\n    wt = max(0.0, 1.0 - abs(off) / (r_tx + 1.0));\n    tx = clamp(ix + off * (1.0 - axis), 0.0, width - 1.0);\n    ty = clamp(iy + off * axis, 0.0, height - 1.0);\n    acc = acc + nearest(in1, vec((tx + 0.5) / width, (ty + 0.5) / height)) * wt;\n    wsum = wsum + wt;\n}\n\nout1 = acc / wsum;\n",
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
						232.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_ink_stage_blur_h @adapt 0 @dim 256 256 @type float32",
					"varname": "#0_ink_stage_blur_h"
				}
			},
			{
				"box": {
					"id": "obj-56",
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
									"code": "// f_ink -- one separable blur pass (spec FR-004, plan ADR-2, T020). Mirror: tests/modules/ink/ink_mirror.blur_pass.\n// Used four times: spread H and V, pool H and V. definition.py renders this template per stage: the radius Param becomes\n// `spread` or `pool_width`, and the axis Param a constant, so every Param left in a shipped stage is driven.\n//   - 15 taps at the fixed offsets -7..7, one texel apart (Matt, 2026-11-08: a stride of 2 combs a 1-texel line).\n//   - The radius only sets the weights: a tent of half-width r + 1, normalized. r = 0 is one tap of weight 1, so a\n//     radius of 0 is exactly the input, and the weights move continuously with the dial.\n//   - The reach is capped at 7 texels (above 1080 it shrinks in frame heights, accepted with the cap).\n//   - Border: clamp-to-edge by integer index (T010, G7), never an out-of-range read.\n//   - nearest() at texel centers, no interpolation (T008 is still to measure). width and height come from render_dim:\n//     `dim` reads 1 in a live jit.gl.pix.\n// radius is in frame heights. axis: 0 horizontal, 1 vertical.\nParam width(1920.0);\nParam height(1080.0);\nParam spread(0.0);\naxis = 1.0;\nradius = spread * 7.0 / 1080.0;\n\nr_tx = clamp(radius * height, 0.0, 7.0);\nix = floor(norm.x * width);\niy = floor(norm.y * height);\nacc = vec(0.0, 0.0, 0.0, 0.0);\nwsum = 0.0;\nfor (k = 0; k < 15; k += 1) {\n    off = k - 7.0;\n    wt = max(0.0, 1.0 - abs(off) / (r_tx + 1.0));\n    tx = clamp(ix + off * (1.0 - axis), 0.0, width - 1.0);\n    ty = clamp(iy + off * axis, 0.0, height - 1.0);\n    acc = acc + nearest(in1, vec((tx + 0.5) / width, (ty + 0.5) / height)) * wt;\n    wsum = wsum + wt;\n}\n\nout1 = acc / wsum;\n",
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
						232.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_ink_stage_blur_v @adapt 0 @dim 256 256 @type float32",
					"varname": "#0_ink_stage_blur_v"
				}
			},
			{
				"box": {
					"id": "obj-57",
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
									"code": "// f_ink -- the re-threshold of spread (spec FR-004, plan ADR-2, T021). Mirror: tests/modules/ink/ink_mirror.threshold.\n// H = smoothstep(0.5 - w/2 - bias, 0.5 + w/2 - bias, B), then S = mix(B, H, snap * min(spread / 0.125, 1)).\n// snap 0 is a plain blur, which keeps continuous tone; snap 1 hardens the blur back into a mark (Matt, 2026-11-08).\n// At spread 0 the blend factor is exactly 0, so the input passes unchanged. Alpha is restored in the last stage.\n// 0.125 is SNAP_GATE (inferred, tuned at T032); 0.001 keeps smoothstep's edges apart at soften 0.\nhard_c(bc, lo_e, hi_e, amt) {\n    held = smoothstep(lo_e, hi_e, bc);\n    return bc * (1.0 - amt) + held * amt;\n}\n\nParam spread(0.0);\nParam snap(1.0);\nParam bias(0.0);\nParam soften(0.2);\n\nsoft_w = max(soften, 0.001);\nlo_edge = 0.5 - soft_w * 0.5 - bias;\nhi_edge = 0.5 + soft_w * 0.5 - bias;\nblend_amt = snap * min(spread / 0.125, 1.0);\n\nout1 = vec(hard_c(nearest(in1, norm).x, lo_edge, hi_edge, blend_amt), hard_c(nearest(in1, norm).y, lo_edge, hi_edge, blend_amt), hard_c(nearest(in1, norm).z, lo_edge, hi_edge, blend_amt), 1.0);\n",
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
						530.0,
						232.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_ink_stage_thresh @adapt 0 @dim 256 256 @type float32",
					"varname": "#0_ink_stage_thresh"
				}
			},
			{
				"box": {
					"id": "obj-58",
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
									"code": "// f_ink -- one separable blur pass (spec FR-004, plan ADR-2, T020). Mirror: tests/modules/ink/ink_mirror.blur_pass.\n// Used four times: spread H and V, pool H and V. definition.py renders this template per stage: the radius Param becomes\n// `spread` or `pool_width`, and the axis Param a constant, so every Param left in a shipped stage is driven.\n//   - 15 taps at the fixed offsets -7..7, one texel apart (Matt, 2026-11-08: a stride of 2 combs a 1-texel line).\n//   - The radius only sets the weights: a tent of half-width r + 1, normalized. r = 0 is one tap of weight 1, so a\n//     radius of 0 is exactly the input, and the weights move continuously with the dial.\n//   - The reach is capped at 7 texels (above 1080 it shrinks in frame heights, accepted with the cap).\n//   - Border: clamp-to-edge by integer index (T010, G7), never an out-of-range read.\n//   - nearest() at texel centers, no interpolation (T008 is still to measure). width and height come from render_dim:\n//     `dim` reads 1 in a live jit.gl.pix.\n// radius is in frame heights. axis: 0 horizontal, 1 vertical.\nParam width(1920.0);\nParam height(1080.0);\nParam pool_width(0.005);\naxis = 0.0;\nradius = pool_width;\n\nr_tx = clamp(radius * height, 0.0, 7.0);\nix = floor(norm.x * width);\niy = floor(norm.y * height);\nacc = vec(0.0, 0.0, 0.0, 0.0);\nwsum = 0.0;\nfor (k = 0; k < 15; k += 1) {\n    off = k - 7.0;\n    wt = max(0.0, 1.0 - abs(off) / (r_tx + 1.0));\n    tx = clamp(ix + off * (1.0 - axis), 0.0, width - 1.0);\n    ty = clamp(iy + off * axis, 0.0, height - 1.0);\n    acc = acc + nearest(in1, vec((tx + 0.5) / width, (ty + 0.5) / height)) * wt;\n    wsum = wsum + wt;\n}\n\nout1 = acc / wsum;\n",
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
						580.0,
						232.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_ink_stage_pool_h @adapt 0 @dim 256 256 @type float32",
					"varname": "#0_ink_stage_pool_h"
				}
			},
			{
				"box": {
					"id": "obj-59",
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
									"code": "// f_ink -- one separable blur pass (spec FR-004, plan ADR-2, T020). Mirror: tests/modules/ink/ink_mirror.blur_pass.\n// Used four times: spread H and V, pool H and V. definition.py renders this template per stage: the radius Param becomes\n// `spread` or `pool_width`, and the axis Param a constant, so every Param left in a shipped stage is driven.\n//   - 15 taps at the fixed offsets -7..7, one texel apart (Matt, 2026-11-08: a stride of 2 combs a 1-texel line).\n//   - The radius only sets the weights: a tent of half-width r + 1, normalized. r = 0 is one tap of weight 1, so a\n//     radius of 0 is exactly the input, and the weights move continuously with the dial.\n//   - The reach is capped at 7 texels (above 1080 it shrinks in frame heights, accepted with the cap).\n//   - Border: clamp-to-edge by integer index (T010, G7), never an out-of-range read.\n//   - nearest() at texel centers, no interpolation (T008 is still to measure). width and height come from render_dim:\n//     `dim` reads 1 in a live jit.gl.pix.\n// radius is in frame heights. axis: 0 horizontal, 1 vertical.\nParam width(1920.0);\nParam height(1080.0);\nParam pool_width(0.005);\naxis = 1.0;\nradius = pool_width;\n\nr_tx = clamp(radius * height, 0.0, 7.0);\nix = floor(norm.x * width);\niy = floor(norm.y * height);\nacc = vec(0.0, 0.0, 0.0, 0.0);\nwsum = 0.0;\nfor (k = 0; k < 15; k += 1) {\n    off = k - 7.0;\n    wt = max(0.0, 1.0 - abs(off) / (r_tx + 1.0));\n    tx = clamp(ix + off * (1.0 - axis), 0.0, width - 1.0);\n    ty = clamp(iy + off * axis, 0.0, height - 1.0);\n    acc = acc + nearest(in1, vec((tx + 0.5) / width, (ty + 0.5) / height)) * wt;\n    wsum = wsum + wt;\n}\n\nout1 = acc / wsum;\n",
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
						630.0,
						232.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_ink_stage_pool_v @adapt 0 @dim 256 256 @type float32",
					"varname": "#0_ink_stage_pool_v"
				}
			},
			{
				"box": {
					"id": "obj-60",
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
									"code": "// f_ink -- edge pooling (spec FR-007, plan ADR-3, T021). Mirror: tests/modules/ink/ink_mirror.pool.\n// P = S + edge_pool * S * 2 * max(S - Bp, 0). The band S - Bp is 0 on any flat field and 0.5 on a straight edge, and the\n// factor S keeps the rim on the ink side.\n// First input: Bp, the blur of S at pool_width. Second input: S. The blur arrives last and jit.gl.pix renders on its\n// left inlet, so the blur has to be the left one, or this stage would use last frame's rim.\npool_c(sc, bc, amt) {\n    return sc + amt * sc * 2.0 * max(sc - bc, 0.0);\n}\n\nParam edge_pool(0.0);\n\nout1 = vec(pool_c(nearest(in2, norm).x, nearest(in1, norm).x, edge_pool), pool_c(nearest(in2, norm).y, nearest(in1, norm).y, edge_pool), pool_c(nearest(in2, norm).z, nearest(in1, norm).z, edge_pool), 1.0);\n",
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
						30.0,
						680.0,
						216.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_ink_stage_pool @adapt 0 @dim 256 256 @type float32",
					"varname": "#0_ink_stage_pool"
				}
			},
			{
				"box": {
					"id": "obj-61",
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
									"code": "// f_ink -- the last stage: mottle, then dropout, then bypass and the source alpha (spec FR-005, FR-006, FR-013, plan ADR-4,\n// ADR-6, T022). Mirror: tests/modules/ink/ink_mirror.fx_b and the end of ink().\n// First input: the pooled image. Second input: the zapped source.\n// Coordinates are frame heights (x scaled by the aspect), fixed to the frame (Matt, Q3). The hash is sin (noise() is black\n// on this path); a GPU sin differs from NumPy's in the low bits, so the bench can compare statistics only, not texels.\n// Mottle is a gain centered on 1, so a coverage of 0 stays 0. Dropout compares max(c, 0), so a negative value is left\n// alone at dropout 0, and the comparison is strict, so dropout 0 removes nothing.\nhash_2d(ix, iy, sd) {\n    hv = sin(ix * 127.1 + iy * 311.7 + sd) * 43758.5453;\n    return hv - floor(hv);\n}\n\nvnoise(px, py, scl, sd) {\n    sz = max(scl, 0.00001);\n    gx = px / sz;\n    gy = py / sz;\n    ix = floor(gx);\n    iy = floor(gy);\n    fx = gx - ix;\n    fy = gy - iy;\n    ux = fx * fx * (3.0 - 2.0 * fx);\n    uy = fy * fy * (3.0 - 2.0 * fy);\n    ha = hash_2d(ix, iy, sd);\n    hb = hash_2d(ix + 1.0, iy, sd);\n    hc = hash_2d(ix, iy + 1.0, sd);\n    hd = hash_2d(ix + 1.0, iy + 1.0, sd);\n    near_row = ha + (hb - ha) * ux;\n    far_row = hc + (hd - hc) * ux;\n    return near_row + (far_row - near_row) * uy;\n}\n\nmottle_field(px, py, scl, sd) {\n    oct1 = vnoise(px, py, scl, sd);\n    oct2 = vnoise(px, py, scl * 0.5, sd + 17.0);\n    oct3 = vnoise(px, py, scl * 0.25, sd + 34.0);\n    return (oct1 + oct2 * 0.5 + oct3 * 0.25) / 1.75;\n}\n\nink_c(cv, gain_m, thresh_d) {\n    cm = cv * gain_m;\n    return switch(max(cm, 0.0) < thresh_d, 0.0, cm);\n}\n\nParam width(1920.0);\nParam height(1080.0);\nParam mottle(0.0);\nParam mottle_scale(0.15);\nParam dropout(0.0);\nParam tooth_scale(0.004);\nParam seed(1.0);\nParam bypass_gate(0.0);\n\naspect = width / max(height, 1.0);\nframe_x = norm.x * aspect;\nframe_y = norm.y;\n\ngain_m = 1.0 + mottle * (mottle_field(frame_x, frame_y, mottle_scale, seed) - 0.5) * 2.0;\nthresh_d = dropout * vnoise(frame_x, frame_y, tooth_scale, seed + 101.0);\n\nr_ink = ink_c(nearest(in1, norm).x, gain_m, thresh_d);\ng_ink = ink_c(nearest(in1, norm).y, gain_m, thresh_d);\nb_ink = ink_c(nearest(in1, norm).z, gain_m, thresh_d);\n\nout1 = vec(mix(r_ink, nearest(in2, norm).x, bypass_gate), mix(g_ink, nearest(in2, norm).y, bypass_gate), mix(b_ink, nearest(in2, norm).z, bypass_gate), nearest(in2, norm).w);\n",
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
						30.0,
						730.0,
						216.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_ink_stage_fx_b @adapt 0 @dim 256 256 @type float32",
					"varname": "#0_ink_stage_fx_b"
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
					"varname": "ink_autopattr"
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
						190.0,
						185.0
					],
					"presentation": 1,
					"presentation_rect": [
						0.0,
						0.0,
						190.0,
						185.0
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
					"text": "Ink"
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
						94.0,
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
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Ink gain: blurs each channel, then Snap hardens it back into a mark. 1 reaches 7 texels at 1080; the reach is capped there, so above 1080 it shrinks with the frame. PROVISIONAL",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_ink_stage_blur_h::spread",
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
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "spread",
							"parameter_mmax": 1.0,
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
					"id": "obj-21",
					"maxclass": "attrui",
					"attr": "spread",
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
					"id": "obj-700",
					"maxclass": "attrui",
					"attr": "spread",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						26.0,
						344.0,
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
					"attr": "spread",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						26.0,
						368.0,
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
					"text": "Spread",
					"textjustification": 1,
					"varname": "lbl_spread"
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
					"hint": "After the blur: positive fattens marks, negative thins them. Needs Spread and Snap above 0. PROVISIONAL",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_ink_stage_thresh::bias",
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
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "bias",
							"parameter_mmax": 1.0,
							"parameter_mmin": -1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "bias",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "bias"
				}
			},
			{
				"box": {
					"id": "obj-24",
					"maxclass": "attrui",
					"attr": "bias",
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
					"text": "Bias",
					"textjustification": 1,
					"varname": "lbl_bias"
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
					"hint": "How much the blur hardens back into a mark. 0 is a plain blur that keeps continuous tone; 1 posterizes continuous tone as Spread rises. PROVISIONAL",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_ink_stage_thresh::snap",
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
							"parameter_longname": "snap",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "snap",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "snap"
				}
			},
			{
				"box": {
					"id": "obj-27",
					"maxclass": "attrui",
					"attr": "snap",
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
					"text": "Snap",
					"textjustification": 1,
					"varname": "lbl_snap"
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
					"hint": "Edge softness of the hardened mark. PROVISIONAL",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_ink_stage_thresh::soften",
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
								0.2
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "soften",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "soften",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "soften"
				}
			},
			{
				"box": {
					"id": "obj-30",
					"maxclass": "attrui",
					"attr": "soften",
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
					"text": "Soften",
					"textjustification": 1,
					"varname": "lbl_soften"
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
					"hint": "Ink collects at the edges of marks: a denser rim, up to twice the mark's value at 1. Flat areas stay as they are. Output is not clamped",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_ink_stage_pool::edge_pool",
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
							"parameter_longname": "edge_pool",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "edge_pool",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "edge_pool"
				}
			},
			{
				"box": {
					"id": "obj-33",
					"maxclass": "attrui",
					"attr": "edge_pool",
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
					"text": "Edge Pool",
					"textjustification": 1,
					"varname": "lbl_edge_pool"
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
					"hint": "Width of the Edge Pool rim, in frame heights. It shares the 7-texel reach of the blur. PROVISIONAL",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_ink_stage_pool_h::pool_width",
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
								0.005
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "pool_width",
							"parameter_mmax": 0.013,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "pool_width",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "pool_width"
				}
			},
			{
				"box": {
					"id": "obj-36",
					"maxclass": "attrui",
					"attr": "pool_width",
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
					"id": "obj-702",
					"maxclass": "attrui",
					"attr": "pool_width",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						386.0,
						344.0,
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
					"text": "Pool W",
					"textjustification": 1,
					"varname": "lbl_pool_width"
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
					"hint": "Uneven density in blotches. It scales the ink that is there, so black stays black",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_ink_stage_fx_b::mottle",
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
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "mottle",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "mottle",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "mottle"
				}
			},
			{
				"box": {
					"id": "obj-39",
					"maxclass": "attrui",
					"attr": "mottle",
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
					"text": "Mottle",
					"textjustification": 1,
					"varname": "lbl_mottle"
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
					"hint": "Blotch size, in frame heights. PROVISIONAL",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_ink_stage_fx_b::mottle_scale",
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
								0.15
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "mottle_scale",
							"parameter_mmax": 0.5,
							"parameter_mmin": 0.01,
							"parameter_modmode": 3,
							"parameter_shortname": "mottle_scale",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "mottle_scale"
				}
			},
			{
				"box": {
					"id": "obj-42",
					"maxclass": "attrui",
					"attr": "mottle_scale",
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
					"text": "Mottle Sz",
					"textjustification": 1,
					"varname": "lbl_mottle_scale"
				}
			},
			{
				"box": {
					"id": "obj-44",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Ink fails to take on the paper's tooth: pinholes and skips, lighter values first, solids last",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_ink_stage_fx_b::dropout",
					"parameter_enable": 1,
					"patching_rect": [
						622.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						115.0,
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
							"parameter_longname": "dropout",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "dropout",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "dropout"
				}
			},
			{
				"box": {
					"id": "obj-45",
					"maxclass": "attrui",
					"attr": "dropout",
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
					"text": "Dropout",
					"textjustification": 1,
					"varname": "lbl_dropout"
				}
			},
			{
				"box": {
					"id": "obj-47",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Grain of the paper, in frame heights. PROVISIONAL",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_ink_stage_fx_b::tooth_scale",
					"parameter_enable": 1,
					"patching_rect": [
						694.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						152.0,
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
								0.004
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "tooth_scale",
							"parameter_mmax": 0.02,
							"parameter_mmin": 0.001,
							"parameter_modmode": 3,
							"parameter_shortname": "tooth_scale",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "tooth_scale"
				}
			},
			{
				"box": {
					"id": "obj-48",
					"maxclass": "attrui",
					"attr": "tooth_scale",
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
					"text": "Tooth Sz",
					"textjustification": 1,
					"varname": "lbl_tooth_scale"
				}
			},
			{
				"box": {
					"id": "obj-50",
					"maxclass": "live.numbox",
					"fontname": "Ableton Sans Light",
					"hint": "Picks the mottle and tooth patterns. They are fixed to the frame and do not move",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_ink_stage_fx_b::seed",
					"parameter_enable": 1,
					"patching_rect": [
						758.0,
						250.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						4.0,
						162.0,
						34.0,
						15.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								1.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "seed",
							"parameter_mmax": 999.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "seed",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"varname": "seed"
				}
			},
			{
				"box": {
					"id": "obj-51",
					"maxclass": "attrui",
					"attr": "seed",
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
					"text": "Seed",
					"textjustification": 1,
					"varname": "lbl_seed"
				}
			},
			{
				"box": {
					"id": "obj-53",
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
					"id": "obj-54",
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
						30.0,
						892.0,
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
						892.0,
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
						922.0,
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
					"id": "obj-rd-1",
					"maxclass": "newobj",
					"patching_rect": [
						80.0,
						892.0,
						60.0,
						22.0
					],
					"text": "route dim",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					]
				}
			},
			{
				"box": {
					"id": "obj-rd-2",
					"maxclass": "newobj",
					"patching_rect": [
						80.0,
						922.0,
						60.0,
						22.0
					],
					"text": "unpack i i",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"int",
						"int"
					]
				}
			},
			{
				"box": {
					"id": "obj-rd-3",
					"maxclass": "newobj",
					"patching_rect": [
						30.0,
						952.0,
						120.0,
						22.0
					],
					"text": "prepend param width",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					]
				}
			},
			{
				"box": {
					"id": "obj-rd-4",
					"maxclass": "newobj",
					"patching_rect": [
						160.0,
						952.0,
						120.0,
						22.0
					],
					"text": "prepend param height",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
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
						"obj-61",
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
						"obj-61",
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
						"obj-58",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-58",
						0
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
						"obj-57",
						0
					],
					"destination": [
						"obj-60",
						1
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
						"obj-61",
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
						"obj-61",
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
						"obj-55",
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
						"obj-57",
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
						"obj-57",
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
						"obj-57",
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
						"obj-60",
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
						"obj-58",
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
						"obj-61",
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
						"obj-61",
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
						"obj-61",
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
						"obj-61",
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
						"obj-61",
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
						"obj-56",
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
						"obj-57",
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
						"obj-59",
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
						"obj-rd-0",
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
						"obj-rd-0",
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
						"obj-rd-0",
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
						"obj-rd-0",
						0
					],
					"destination": [
						"obj-58",
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
						"obj-59",
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
						"obj-60",
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
						"obj-61",
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
						"obj-rd-1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-rd-1",
						0
					],
					"destination": [
						"obj-rd-2",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-rd-2",
						0
					],
					"destination": [
						"obj-rd-3",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-rd-2",
						1
					],
					"destination": [
						"obj-rd-4",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-rd-3",
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
						"obj-rd-3",
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
						"obj-rd-3",
						0
					],
					"destination": [
						"obj-58",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-rd-3",
						0
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
						"obj-rd-3",
						0
					],
					"destination": [
						"obj-61",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-rd-4",
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
						"obj-rd-4",
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
						"obj-rd-4",
						0
					],
					"destination": [
						"obj-58",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-rd-4",
						0
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
						"obj-rd-4",
						0
					],
					"destination": [
						"obj-61",
						0
					]
				}
			}
		],
		"parameters": {
			"obj-20": [
				"spread",
				"spread",
				0
			],
			"obj-23": [
				"bias",
				"bias",
				0
			],
			"obj-26": [
				"snap",
				"snap",
				0
			],
			"obj-29": [
				"soften",
				"soften",
				0
			],
			"obj-32": [
				"edge_pool",
				"edge_pool",
				0
			],
			"obj-35": [
				"pool_width",
				"pool_width",
				0
			],
			"obj-38": [
				"mottle",
				"mottle",
				0
			],
			"obj-41": [
				"mottle_scale",
				"mottle_scale",
				0
			],
			"obj-44": [
				"dropout",
				"dropout",
				0
			],
			"obj-47": [
				"tooth_scale",
				"tooth_scale",
				0
			],
			"obj-50": [
				"seed",
				"seed",
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