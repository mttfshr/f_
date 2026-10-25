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
					"comment": "control",
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
					"comment": "pattern (RGB: E, I, contour)",
					"index": 0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						30.0,
						702.0,
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
					"numoutlets": 5,
					"outlettype": [
						"",
						"",
						"",
						"",
						""
					],
					"patching_rect": [
						56.5,
						204.0,
						367.0,
						22.0
					],
					"text": "route pulse_depth pulse_period out_mode q_levels reset"
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
						30.0,
						380.0,
						200.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_fc_hold @adapt 0 @dim 1024 1024 @type float32",
					"varname": "#0_fc_hold"
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
									"code": "// codebox_seed.gen -- f_formconstants PARITY seed stage (spec Revision 2, S6).\n// One-time uniform \"uint8\" random in all four channels, k/255 (the page's GPUNoise.randomize\n// writes uniform bytes into R, G, B, A). Hash noise, deterministic per texel per salt.\n// Mirror: fc_parity_mirror.seed_state() (the distribution; the hash is not bit-matched to numpy's rng).\n//   - salt advances once per RESET (the raw wiring), NOT per frame: the page has no per-frame noise\n//   - grid size: Param n (default 1024 = the definition's @dim) -- never the gen `dim` global\n//   - no sin(): a Hoskins-style arithmetic hash; functions are declared before Params (GenExpr rule)\n//   - uint8-like: min(floor(h * 256), 255) / 255 on every channel\nhashf(x, y) {\n\tha = fract(x * 0.1031);\n\thb = fract(y * 0.1031);\n\thc = ha;\n\thd = ha * (hb + 33.33) + hb * (hc + 33.33) + hc * (ha + 33.33);\n\tha = ha + hd;\n\thb = hb + hd;\n\thc = hc + hd;\n\treturn fract((ha + hb) * hc);\n}\n\nParam salt(0);\nParam n(1024);\n\npx = floor(norm.x * n);\npy = floor(norm.y * n);\n\nsa = salt * 61;\nsb = salt * 17;\nh0 = hashf(px + sa, py + sb);\nh1 = hashf(px + sa + 113.7, py + sb + 57.3);\nh2 = hashf(px + sa + 271.9, py + sb + 181.3);\nh3 = hashf(px + sa + 401.1, py + sb + 333.7);\n\nout1 = vec(min(floor(h0 * 256), 255) / 255, min(floor(h1 * 256), 255) / 255,\n           min(floor(h2 * 256), 255) / 255, min(floor(h3 * 256), 255) / 255);\n",
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
						250.0,
						380.0,
						200.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_fc_seed @adapt 0 @dim 1024 1024 @type float32",
					"varname": "#0_fc_seed"
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
									"code": "// codebox_pass.gen -- f_formconstants PARITY hold/reseed stage (spec Revision 2, S6).\n// Mirror: fc_parity_mirror.pass_stage().\n// Inputs: in1 = the `r draw` bang (unused; it only triggers the render each frame), in2 = the\n// feedback state (R = E, G = I, B = contour, A = 1 flag, from nl through hold), in3 = the seed\n// stage (all four channels).\n//   - reseed >= 0.5 replaces the whole state with the seed (load, reset)\n//   - LOST FLAG = alpha: nl always writes A = 1, a fresh or reallocated texture reads A = 0 (to be\n//     confirmed at T046). NOT \"E == 0 and I == 0\": E = I = 0 is a legitimate state under 8-bit\n//     quantization, and that old self-heal would inject noise into a live field\n//   - the feedback is NaN/Inf-guarded: abs(x) < 1e30 (NaN == NaN is TRUE on this GPU); a zapped\n//     channel reads 0 and the texel is held (its alpha is kept)\n//   - selection uses switch(), not mix() (mix(NaN, x, 1) is still NaN)\nParam reseed(0);\n\nfbe = nearest(in2, norm).x;\nfbe = switch(abs(fbe) < 1e30, fbe, 0);\nfbi = nearest(in2, norm).y;\nfbi = switch(abs(fbi) < 1e30, fbi, 0);\nfbb = nearest(in2, norm).z;\nfbb = switch(abs(fbb) < 1e30, fbb, 0);\nfba = nearest(in2, norm).w;\nfba = switch(abs(fba) < 1e30, fba, 0);\nsd = nearest(in3, norm);\ntake = switch(reseed >= 0.5, 1, switch(fba == 0, 1, 0));\nout1 = vec(switch(take > 0.5, sd.x, fbe), switch(take > 0.5, sd.y, fbi),\n           switch(take > 0.5, sd.z, fbb), switch(take > 0.5, sd.w, fba));\n",
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
					"text": "jit.gl.pix vsynth @name #0_fc_pass @adapt 0 @dim 1024 1024 @type float32",
					"varname": "#0_fc_pass"
				}
			},
			{
				"box": {
					"id": "obj-53",
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
									"code": "// codebox_blur_x.gen -- f_formconstants PARITY blur stage, X pass (spec Revision 2, S2 + S3).\n// Port of lib/gpugaussian.js GPUGaussianMultiBlur(gl, 1, 2, 1, 1): per-channel sigma\n// R = 1 (E), G = 2 (I), B = 1, A = 1; ONE shared radius ceil(3 * 2) = 6, so the sigma = 1\n// kernel is also 13 taps; weights exp(-0.5 (i/sigma)^2) normalized over [-6, 6]; taps at exact\n// integer texel offsets, wrap (REPEAT); the result divided by w0 + 2*sum(w_i) (the page does) and\n// quantized floor(255 c + 0.5)/255 on all four channels (S2).\n// Weights are LITERALS generated from tests/modules/formconstants/fc_parity_mirror.half_kernel()\n// (test_fc_codebox_static.py re-parses this file and compares them). Mirror: fc_parity_mirror.blur_pass.\n// Grid size: Param n (default 1024 = the definition's @dim, S1) -- NEVER the gen `dim` global.\n// Wrap is explicit modulo on the texel index (the verified f_wc / f_formconstants pattern); reads are\n// nearest() at texel centres, normalized coordinates. GenExpr discipline: no functions, everything\n// inlined with suffixed names.\n// Phase D T062 (Matt, 2026-10-25): Param q_levels from the Quant menu -- 0 = 255 levels (the source,\n// S2), 1 = 1023, 2 = float (no quantization). Every level >= 255 lives; below 255 the field freezes\n// (tests/records/spike_fc_quant_levels.py), so the menu offers only the living span.\nParam n(1024);\nParam q_levels(0);\n\nix = floor(norm.x * n);\niy = floor(norm.y * n);\nyw0 = iy - n * floor(iy / n);\nt0 = nearest(in1, vec((ix + 0.5) / n, (yw0 + 0.5) / n));\nar = t0.x * 0.398942292; ag = t0.y * 0.199675635; ab = t0.z * 0.398942292; aa = t0.w * 0.398942292;\nwp1 = (ix + 1) - n * floor((ix + 1) / n);\nwn1 = (ix - 1) - n * floor((ix - 1) / n);\ntp1 = nearest(in1, vec((wp1 + 0.5) / n, (yw0 + 0.5) / n));\ntn1 = nearest(in1, vec((wn1 + 0.5) / n, (yw0 + 0.5) / n));\nar = ar + (tp1.x + tn1.x) * 0.241970718; ag = ag + (tp1.y + tn1.y) * 0.176213115; ab = ab + (tp1.z + tn1.z) * 0.241970718; aa = aa + (tp1.w + tn1.w) * 0.241970718;\nwp2 = (ix + 2) - n * floor((ix + 2) / n);\nwn2 = (ix - 2) - n * floor((ix - 2) / n);\ntp2 = nearest(in1, vec((wp2 + 0.5) / n, (yw0 + 0.5) / n));\ntn2 = nearest(in1, vec((wn2 + 0.5) / n, (yw0 + 0.5) / n));\nar = ar + (tp2.x + tn2.x) * 0.0539909676; ag = ag + (tp2.y + tn2.y) * 0.121109389; ab = ab + (tp2.z + tn2.z) * 0.0539909676; aa = aa + (tp2.w + tn2.w) * 0.0539909676;\nwp3 = (ix + 3) - n * floor((ix + 3) / n);\nwn3 = (ix - 3) - n * floor((ix - 3) / n);\ntp3 = nearest(in1, vec((wp3 + 0.5) / n, (yw0 + 0.5) / n));\ntn3 = nearest(in1, vec((wn3 + 0.5) / n, (yw0 + 0.5) / n));\nar = ar + (tp3.x + tn3.x) * 0.00443184841; ag = ag + (tp3.y + tn3.y) * 0.0648251846; ab = ab + (tp3.z + tn3.z) * 0.00443184841; aa = aa + (tp3.w + tn3.w) * 0.00443184841;\nwp4 = (ix + 4) - n * floor((ix + 4) / n);\nwn4 = (ix - 4) - n * floor((ix - 4) / n);\ntp4 = nearest(in1, vec((wp4 + 0.5) / n, (yw0 + 0.5) / n));\ntn4 = nearest(in1, vec((wn4 + 0.5) / n, (yw0 + 0.5) / n));\nar = ar + (tp4.x + tn4.x) * 0.000133830225; ag = ag + (tp4.y + tn4.y) * 0.0270231571; ab = ab + (tp4.z + tn4.z) * 0.000133830225; aa = aa + (tp4.w + tn4.w) * 0.000133830225;\nwp5 = (ix + 5) - n * floor((ix + 5) / n);\nwn5 = (ix - 5) - n * floor((ix - 5) / n);\ntp5 = nearest(in1, vec((wp5 + 0.5) / n, (yw0 + 0.5) / n));\ntn5 = nearest(in1, vec((wn5 + 0.5) / n, (yw0 + 0.5) / n));\nar = ar + (tp5.x + tn5.x) * 1.4867195e-06; ag = ag + (tp5.y + tn5.y) * 0.00877313502; ab = ab + (tp5.z + tn5.z) * 1.4867195e-06; aa = aa + (tp5.w + tn5.w) * 1.4867195e-06;\nwp6 = (ix + 6) - n * floor((ix + 6) / n);\nwn6 = (ix - 6) - n * floor((ix - 6) / n);\ntp6 = nearest(in1, vec((wp6 + 0.5) / n, (yw0 + 0.5) / n));\ntn6 = nearest(in1, vec((wn6 + 0.5) / n, (yw0 + 0.5) / n));\nar = ar + (tp6.x + tn6.x) * 6.07588291e-09; ag = ag + (tp6.y + tn6.y) * 0.00221819594; ab = ab + (tp6.z + tn6.z) * 6.07588291e-09; aa = aa + (tp6.w + tn6.w) * 6.07588291e-09;\nlv = 255 + 768 * (q_levels > 0.5);\nqon = q_levels < 1.5;\nqr = mix(ar, floor(lv * ar + 0.5) / lv, qon);\nqg = mix(ag, floor(lv * ag + 0.5) / lv, qon);\nqb = mix(ab, floor(lv * ab + 0.5) / lv, qon);\nqa = mix(aa, floor(lv * aa + 0.5) / lv, qon);\nout1 = vec(qr, qg, qb, qa);\n",
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
					"text": "jit.gl.pix vsynth @name #0_fc_blurx @adapt 0 @dim 1024 1024 @type float32",
					"varname": "#0_fc_blurx"
				}
			},
			{
				"box": {
					"id": "obj-54",
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
									"code": "// codebox_blur_y.gen -- f_formconstants PARITY blur stage, Y pass (spec Revision 2, S2 + S3).\n// Port of lib/gpugaussian.js GPUGaussianMultiBlur(gl, 1, 2, 1, 1): per-channel sigma\n// R = 1 (E), G = 2 (I), B = 1, A = 1; ONE shared radius ceil(3 * 2) = 6, so the sigma = 1\n// kernel is also 13 taps; weights exp(-0.5 (i/sigma)^2) normalized over [-6, 6]; taps at exact\n// integer texel offsets, wrap (REPEAT); the result divided by w0 + 2*sum(w_i) (the page does) and\n// quantized floor(255 c + 0.5)/255 on all four channels (S2).\n// Weights are LITERALS generated from tests/modules/formconstants/fc_parity_mirror.half_kernel()\n// (test_fc_codebox_static.py re-parses this file and compares them). Mirror: fc_parity_mirror.blur_pass.\n// Grid size: Param n (default 1024 = the definition's @dim, S1) -- NEVER the gen `dim` global.\n// Wrap is explicit modulo on the texel index (the verified f_wc / f_formconstants pattern); reads are\n// nearest() at texel centres, normalized coordinates. GenExpr discipline: no functions, everything\n// inlined with suffixed names.\n// Phase D T062 (Matt, 2026-10-25): Param q_levels from the Quant menu -- 0 = 255 levels (the source,\n// S2), 1 = 1023, 2 = float (no quantization). Every level >= 255 lives; below 255 the field freezes\n// (tests/records/spike_fc_quant_levels.py), so the menu offers only the living span.\nParam n(1024);\nParam q_levels(0);\n\nix = floor(norm.x * n);\niy = floor(norm.y * n);\nxw0 = ix - n * floor(ix / n);\nt0 = nearest(in1, vec((xw0 + 0.5) / n, (iy + 0.5) / n));\nar = t0.x * 0.398942292; ag = t0.y * 0.199675635; ab = t0.z * 0.398942292; aa = t0.w * 0.398942292;\nwp1 = (iy + 1) - n * floor((iy + 1) / n);\nwn1 = (iy - 1) - n * floor((iy - 1) / n);\ntp1 = nearest(in1, vec((xw0 + 0.5) / n, (wp1 + 0.5) / n));\ntn1 = nearest(in1, vec((xw0 + 0.5) / n, (wn1 + 0.5) / n));\nar = ar + (tp1.x + tn1.x) * 0.241970718; ag = ag + (tp1.y + tn1.y) * 0.176213115; ab = ab + (tp1.z + tn1.z) * 0.241970718; aa = aa + (tp1.w + tn1.w) * 0.241970718;\nwp2 = (iy + 2) - n * floor((iy + 2) / n);\nwn2 = (iy - 2) - n * floor((iy - 2) / n);\ntp2 = nearest(in1, vec((xw0 + 0.5) / n, (wp2 + 0.5) / n));\ntn2 = nearest(in1, vec((xw0 + 0.5) / n, (wn2 + 0.5) / n));\nar = ar + (tp2.x + tn2.x) * 0.0539909676; ag = ag + (tp2.y + tn2.y) * 0.121109389; ab = ab + (tp2.z + tn2.z) * 0.0539909676; aa = aa + (tp2.w + tn2.w) * 0.0539909676;\nwp3 = (iy + 3) - n * floor((iy + 3) / n);\nwn3 = (iy - 3) - n * floor((iy - 3) / n);\ntp3 = nearest(in1, vec((xw0 + 0.5) / n, (wp3 + 0.5) / n));\ntn3 = nearest(in1, vec((xw0 + 0.5) / n, (wn3 + 0.5) / n));\nar = ar + (tp3.x + tn3.x) * 0.00443184841; ag = ag + (tp3.y + tn3.y) * 0.0648251846; ab = ab + (tp3.z + tn3.z) * 0.00443184841; aa = aa + (tp3.w + tn3.w) * 0.00443184841;\nwp4 = (iy + 4) - n * floor((iy + 4) / n);\nwn4 = (iy - 4) - n * floor((iy - 4) / n);\ntp4 = nearest(in1, vec((xw0 + 0.5) / n, (wp4 + 0.5) / n));\ntn4 = nearest(in1, vec((xw0 + 0.5) / n, (wn4 + 0.5) / n));\nar = ar + (tp4.x + tn4.x) * 0.000133830225; ag = ag + (tp4.y + tn4.y) * 0.0270231571; ab = ab + (tp4.z + tn4.z) * 0.000133830225; aa = aa + (tp4.w + tn4.w) * 0.000133830225;\nwp5 = (iy + 5) - n * floor((iy + 5) / n);\nwn5 = (iy - 5) - n * floor((iy - 5) / n);\ntp5 = nearest(in1, vec((xw0 + 0.5) / n, (wp5 + 0.5) / n));\ntn5 = nearest(in1, vec((xw0 + 0.5) / n, (wn5 + 0.5) / n));\nar = ar + (tp5.x + tn5.x) * 1.4867195e-06; ag = ag + (tp5.y + tn5.y) * 0.00877313502; ab = ab + (tp5.z + tn5.z) * 1.4867195e-06; aa = aa + (tp5.w + tn5.w) * 1.4867195e-06;\nwp6 = (iy + 6) - n * floor((iy + 6) / n);\nwn6 = (iy - 6) - n * floor((iy - 6) / n);\ntp6 = nearest(in1, vec((xw0 + 0.5) / n, (wp6 + 0.5) / n));\ntn6 = nearest(in1, vec((xw0 + 0.5) / n, (wn6 + 0.5) / n));\nar = ar + (tp6.x + tn6.x) * 6.07588291e-09; ag = ag + (tp6.y + tn6.y) * 0.00221819594; ab = ab + (tp6.z + tn6.z) * 6.07588291e-09; aa = aa + (tp6.w + tn6.w) * 6.07588291e-09;\nlv = 255 + 768 * (q_levels > 0.5);\nqon = q_levels < 1.5;\nqr = mix(ar, floor(lv * ar + 0.5) / lv, qon);\nqg = mix(ag, floor(lv * ag + 0.5) / lv, qon);\nqb = mix(ab, floor(lv * ab + 0.5) / lv, qon);\nqa = mix(aa, floor(lv * aa + 0.5) / lv, qon);\nout1 = vec(qr, qg, qb, qa);\n",
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
						200.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_fc_blury @adapt 0 @dim 1024 1024 @type float32",
					"varname": "#0_fc_blury"
				}
			},
			{
				"box": {
					"id": "obj-55",
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
									"code": "// codebox_nl.gen -- f_formconstants PARITY wc stage (spec Revision 2, S2 + S4 + S5).\n// Port of the page's `wc` shader, Example-10 constants, dt = 1:\n//   Ve = F(10.5 cE - 8.5 cI - 2.0 + s)      Vi = F(12 cE - 3 cI - 3.5)\n//   E += (Ve - E) * dt/10                    I += (Vi - I) * dt/20\n//   out = (q(E), q(I), q8(3 |E - I|), 1)     q(x) = floor(255 x + 0.5)/255\n// B is built from the UNquantized updated E, I and stored through an 8-bit target (clamp, round).\n// Mirror: fc_parity_mirror.wc_step().\n// Inputs: in1 = the convolved fields (R = blur(E), G = blur(I), from blur_y), in2 = the raw state\n// (R = E, G = I, from pass -- the relaxation target is the same frame as the convolved input).\n//   - s = s_depth * mix(square, luma(pulse), pulse_conn), E sigmoid input only (Phase D T061, Matt\n//     2026-10-24: REPLACE semantics, CORTICAL space). square = (fract(frameno / s_period) < 0.5): the\n//     page's wave at the defaults (depth 0.6, period 500/3.4 ~ 147 frames). in3 = the pulse inlet\n//     (through a vs_inState: UNCONNECTED reads vs_black and the patcher sets pulse_conn = 0, so the\n//     internal wave runs), Rec. 709 luma, bilinear `sample` with normalized coords (any input size).\n//     frameno = the frame counter (patcher; wraps at 1000000, ~4.6 h at 60 fps -- one phase jump then;\n//     NOT named `t`: a Param called t is never applied by jit.gl.pix, probed 2026-10-24).\n//     s acts as an excitability level (tests/records/spike_fc_pulse_shapes.py): depth 0 fades the\n//     field out over ~1000 frames, depth ~1.5 or a steady 0.6 kills it, periods under ~100 die --\n//     all reachable on purpose (kill and revive is a performance gesture).\n//   - no noise, no habituation, no clamps (the page has none); the NaN guard lives in pass\n//   - Phase D T062 (Matt, 2026-10-25): Param q_levels from the Quant menu -- 0 = 255 levels (the source,\n//     S2), 1 = 1023, 2 = float (no quantization). Every level >= 255 lives; below 255 the field freezes\n//     (tests/records/spike_fc_quant_levels.py), so the menu offers only the living span.\n//   - constants are literals (the page's `parameters`); frameno / s_depth / s_period / pulse_conn\n//     are the only Params. Mirror: fc_parity_mirror.wc_step(..., s=s_pulse(...)).\n//   - no unary minus before a parenthesis (GenExpr mis-parses it)\nParam frameno(0);\nParam s_depth(0.6);\nParam s_period(147.0588);\nParam pulse_conn(0);\nParam q_levels(0);\n\nce = nearest(in1, norm).x;\nci = nearest(in1, norm).y;\nee = nearest(in2, norm).x;\nii = nearest(in2, norm).y;\npl = sample(in3, norm);\nlum = 0.2126 * pl.x + 0.7152 * pl.y + 0.0722 * pl.z;\nsq = fract(frameno / s_period) < 0.5;\ns = s_depth * mix(sq, lum, pulse_conn);\n\nve = 1 / (1 + exp(0 - (10.5 * ce - 8.5 * ci - 2.0 + s)));\nvi = 1 / (1 + exp(0 - (12.0 * ce - 3.0 * ci - 3.5)));\nen = ee + (ve - ee) * 0.1;\ninw = ii + (vi - ii) * 0.05;\nbb = clamp(abs(en - inw) * 3.0, 0, 1);\n\nlv = 255 + 768 * (q_levels > 0.5);\nqon = q_levels < 1.5;\nqe = mix(en, floor(lv * en + 0.5) / lv, qon);\nqi = mix(inw, floor(lv * inw + 0.5) / lv, qon);\nqbb = mix(bb, floor(lv * bb + 0.5) / lv, qon);\n\nout1 = vec(qe, qi, qbb, 1);\n",
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
						580.0,
						200.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_fc_nl @adapt 0 @dim 1024 1024 @type float32",
					"varname": "#0_fc_nl"
				}
			},
			{
				"box": {
					"id": "obj-5",
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
									"code": "// codebox_enc.gen -- f_formconstants PARITY render stage (spec Revision 2, S7 + S8).\n// Port of the page's `retinalmap` shader on the module's output size: z = canvas coordinate in\n// [-1, 1]^2 of the SQUARE canvas (the page's CSS stretch crops the long axis), then the state is\n// sampled at (atan2(z.y, z.x), ln |z|) / 2 pi with LINEAR filtering and REPEAT wrap. The bare\n// complex log: conformal, one texture width per revolution; over most of the screen it MAGNIFIES\n// the 1024^2 field (the silky read). No foveal softening, contrast or sharp in the parity build.\n// Display (S8): the sampled state's E, I and contour channels, alpha 1 -- then the output mode\n// (Phase D T060, Param out_mode from the Output menu): 0 RGB = (E, I, contour) as the page; 1 E,\n// 2 contour, 3 Rec. 709 luma of that RGB, each as a gray (v, v, v, 1). Branch-free selection.\n// Mirror: fc_parity_mirror.encode_mode() (encode() for mode 0).\n// Inputs: in1 = the `r draw` bang (unused), in2 = the state (from nl).\n//   - output size: Params ow, oh (raw `r dim` -> route -> unpack -> prepend param); NOT the gen `dim`\n//     global (it is not an input texture's size). State grid size: Param n (default 1024 = @dim)\n//   - L = max(ow, oh); zx = (2x - 1) ow/L, zy = (2y - 1) oh/L with texel-centred norm\n//   - manual bilinear with explicit wrap on the texel index (the verified pattern); cortical axes:\n//     texture x = angle, texture y = log radius (the mirror's convention)\n//   - r floored at 1e-6 (ln 0): the page leaves the exact centre undefined\n//   - bypass_gate = 1 outputs black with alpha 1; the solver keeps running upstream. Never a Param\n//     named `bypass` (native pix attribute)\n//   - the cartopol multi-assign is the construct the verified f_formconstants enc bench (8/8) used\nParam bypass_gate(0);\nParam ow(1024);\nParam oh(1024);\nParam n(1024);\nParam out_mode(1);\n\nlng = max(ow, oh);\nzx = (norm.x * 2 - 1) * ow / lng;\nzy = (norm.y * 2 - 1) * oh / lng;\nr, theta = cartopol(zx, zy);\nrr = max(r, 0.000001);\nu = theta / twopi;\nv = log(rr) / twopi;\n\nfx = u * n - 0.5;\nfy = v * n - 0.5;\nx0 = floor(fx);\ny0 = floor(fy);\ntx = fx - x0;\nty = fy - y0;\nxa0 = x0 - n * floor(x0 / n);\nxb0 = (x0 + 1) - n * floor((x0 + 1) / n);\nya0 = y0 - n * floor(y0 / n);\nyb0 = (y0 + 1) - n * floor((y0 + 1) / n);\ncxa = (xa0 + 0.5) / n;\ncxb = (xb0 + 0.5) / n;\ncya = (ya0 + 0.5) / n;\ncyb = (yb0 + 0.5) / n;\nt00 = nearest(in2, vec(cxa, cya));\nt10 = nearest(in2, vec(cxb, cya));\nt01 = nearest(in2, vec(cxa, cyb));\nt11 = nearest(in2, vec(cxb, cyb));\nle = (1 - ty) * ((1 - tx) * t00.x + tx * t10.x) + ty * ((1 - tx) * t01.x + tx * t11.x);\nli = (1 - ty) * ((1 - tx) * t00.y + tx * t10.y) + ty * ((1 - tx) * t01.y + tx * t11.y);\nlb = (1 - ty) * ((1 - tx) * t00.z + tx * t10.z) + ty * ((1 - tx) * t01.z + tx * t11.z);\nk = 1 - bypass_gate;\n\nlum = 0.2126 * le + 0.7152 * li + 0.0722 * lb;\nm1 = abs(out_mode - 1) < 0.5;\nm2 = abs(out_mode - 2) < 0.5;\nm3 = out_mode > 2.5;\ngv = m1 * le + m2 * lb + m3 * lum;\ngsel = out_mode > 0.5;\noc0 = mix(le, gv, gsel);\noc1 = mix(li, gv, gsel);\noc2 = mix(lb, gv, gsel);\n\nout1 = vec(oc0 * k, oc1 * k, oc2 * k, 1);\n",
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
						630.0,
						200.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_fc_enc @adapt 0 @dim 256 256 @type float32",
					"varname": "#0_fc_enc"
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
					"varname": "fc_autopattr"
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
						192.0,
						88.0
					],
					"presentation": 1,
					"presentation_rect": [
						0.0,
						0.0,
						192.0,
						88.0
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
					"text": "Form Constants"
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
						1070.0,
						200.0,
						60.0,
						21.0
					],
					"presentation": 1,
					"presentation_rect": [
						96.0,
						0.9,
						70.0,
						21.0
					],
					"text": "rgb out"
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
					"id": "obj-20a",
					"maxclass": "newobj",
					"numinlets": 0,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						30.0,
						120.0,
						50.0,
						22.0
					],
					"text": "r draw"
				}
			},
			{
				"box": {
					"id": "obj-100",
					"maxclass": "inlet",
					"comment": "pulse in (luma = the pulse; unconnected = internal square wave)",
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
					"id": "obj-101",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						260.0,
						70.0,
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
						260.0,
						120.0,
						160.0,
						22.0
					],
					"text": "prepend param pulse_conn"
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
					"hint": "Pulse depth (excitability). 0.6 = the source; 0 fades the field out slowly; ~1.5 kills it fast",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_fc_nl::pulse_depth",
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
								0.6
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "pulse_depth",
							"parameter_mmax": 1.5,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "pulse_depth",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "pulse_depth"
				}
			},
			{
				"box": {
					"id": "obj-21",
					"maxclass": "attrui",
					"attr": "s_depth",
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
					"text": "Depth",
					"textjustification": 1,
					"varname": "lbl_pulse_depth"
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
					"hint": "Internal pulse period in frames (used when the pulse inlet is unplugged). 147 = the source; under ~100 the field dies",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_fc_nl::pulse_period",
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
								147.0588
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "pulse_period",
							"parameter_mmax": 600.0,
							"parameter_mmin": 30.0,
							"parameter_modmode": 3,
							"parameter_shortname": "pulse_period",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "pulse_period"
				}
			},
			{
				"box": {
					"id": "obj-24",
					"maxclass": "attrui",
					"attr": "s_period",
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
					"text": "Period",
					"textjustification": 1,
					"varname": "lbl_pulse_period"
				}
			},
			{
				"box": {
					"id": "obj-26",
					"maxclass": "live.menu",
					"fontname": "Ableton Sans Light",
					"hint": "RGB = the source look (E, I, contour). E = the activity (spots). Contour = the boundary web. Luma = all three as gray",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"",
						"",
						"float"
					],
					"param_connect": "#0_fc_enc::out_mode",
					"parameter_enable": 1,
					"patching_rect": [
						174.0,
						250.0,
						60.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						74.0,
						52.0,
						45.0,
						15.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_enum": [
								"RGB",
								"E",
								"Contour",
								"Luma"
							],
							"parameter_initial": [
								1.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "out_mode",
							"parameter_mmax": 3.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 0,
							"parameter_shortname": "out_mode",
							"parameter_type": 2,
							"parameter_unitstyle": 0
						}
					},
					"varname": "out_mode"
				}
			},
			{
				"box": {
					"id": "obj-27",
					"maxclass": "attrui",
					"attr": "out_mode",
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
					"text": "Output",
					"textjustification": 1,
					"varname": "lbl_out_mode"
				}
			},
			{
				"box": {
					"id": "obj-29",
					"maxclass": "live.menu",
					"fontname": "Ableton Sans Light",
					"hint": "Quantization: 255 = the source (crisp spots, lattice); 1023 in between; Float = softer, larger domains, slower to form",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"",
						"",
						"float"
					],
					"param_connect": "#0_fc_nl::q_levels",
					"parameter_enable": 1,
					"patching_rect": [
						246.0,
						250.0,
						60.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						111.0,
						52.0,
						45.0,
						15.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_enum": [
								"255",
								"1023",
								"Float"
							],
							"parameter_initial": [
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "q_levels",
							"parameter_mmax": 2.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 0,
							"parameter_shortname": "q_levels",
							"parameter_type": 2,
							"parameter_unitstyle": 0
						}
					},
					"varname": "q_levels"
				}
			},
			{
				"box": {
					"id": "obj-30",
					"maxclass": "attrui",
					"attr": "q_levels",
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
					"id": "obj-700",
					"maxclass": "attrui",
					"attr": "q_levels",
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
					"id": "obj-701",
					"maxclass": "attrui",
					"attr": "q_levels",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						242.0,
						368.0,
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
					"text": "Quant",
					"textjustification": 1,
					"varname": "lbl_q_levels"
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
						170.0,
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
			},
			{
				"box": {
					"id": "obj-raw-1",
					"maxclass": "button",
					"patching_rect": [
						90.0,
						792.0,
						24.0,
						24.0
					],
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"bang"
					],
					"presentation": 1,
					"presentation_rect": [
						156.0,
						44.0,
						28.0,
						28.0
					],
					"varname": "reset_button",
					"hint": "Reseed the fields from fresh noise"
				}
			},
			{
				"box": {
					"id": "obj-raw-2",
					"maxclass": "comment",
					"patching_rect": [
						90.0,
						818.0,
						50.0,
						18.0
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"presentation": 1,
					"presentation_rect": [
						148.0,
						20.0,
						44.0,
						18.0
					],
					"text": "Reset",
					"textjustification": 1,
					"varname": "lbl_reset"
				}
			},
			{
				"box": {
					"id": "obj-raw-3",
					"maxclass": "newobj",
					"patching_rect": [
						90.0,
						852.0,
						50.0,
						22.0
					],
					"text": "t b b b",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"bang",
						"bang",
						"bang"
					]
				}
			},
			{
				"box": {
					"id": "obj-raw-4",
					"maxclass": "newobj",
					"patching_rect": [
						200.0,
						802.0,
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
					"id": "obj-raw-5",
					"maxclass": "newobj",
					"patching_rect": [
						200.0,
						827.0,
						60.0,
						22.0
					],
					"text": "delay 200",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"bang"
					]
				}
			},
			{
				"box": {
					"id": "obj-raw-6",
					"maxclass": "message",
					"patching_rect": [
						90.0,
						892.0,
						80.0,
						22.0
					],
					"text": "param reseed 1",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					]
				}
			},
			{
				"box": {
					"id": "obj-raw-7",
					"maxclass": "message",
					"patching_rect": [
						200.0,
						922.0,
						30.0,
						22.0
					],
					"text": "0",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					]
				}
			},
			{
				"box": {
					"id": "obj-raw-8",
					"maxclass": "newobj",
					"patching_rect": [
						260.0,
						892.0,
						50.0,
						22.0
					],
					"text": "r draw",
					"numinlets": 0,
					"numoutlets": 1,
					"outlettype": [
						""
					]
				}
			},
			{
				"box": {
					"id": "obj-raw-9",
					"maxclass": "newobj",
					"patching_rect": [
						260.0,
						922.0,
						30.0,
						22.0
					],
					"text": "i",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"int"
					]
				}
			},
			{
				"box": {
					"id": "obj-raw-10",
					"maxclass": "newobj",
					"patching_rect": [
						300.0,
						922.0,
						30.0,
						22.0
					],
					"text": "+ 1",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"int"
					]
				}
			},
			{
				"box": {
					"id": "obj-raw-11",
					"maxclass": "newobj",
					"patching_rect": [
						340.0,
						922.0,
						50.0,
						22.0
					],
					"text": "% 1000000",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"int"
					]
				}
			},
			{
				"box": {
					"id": "obj-raw-12",
					"maxclass": "newobj",
					"patching_rect": [
						260.0,
						952.0,
						40.0,
						22.0
					],
					"text": "sel 2",
					"numinlets": 2,
					"numoutlets": 2,
					"outlettype": [
						"bang",
						""
					]
				}
			},
			{
				"box": {
					"id": "obj-raw-13",
					"maxclass": "message",
					"patching_rect": [
						260.0,
						982.0,
						85.0,
						22.0
					],
					"text": "param reseed 0",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					]
				}
			},
			{
				"box": {
					"id": "obj-raw-14",
					"maxclass": "newobj",
					"patching_rect": [
						350.0,
						952.0,
						100.0,
						22.0
					],
					"text": "prepend param frameno",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					]
				}
			},
			{
				"box": {
					"id": "obj-raw-15",
					"maxclass": "newobj",
					"patching_rect": [
						30.0,
						922.0,
						30.0,
						22.0
					],
					"text": "i",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"int"
					]
				}
			},
			{
				"box": {
					"id": "obj-raw-16",
					"maxclass": "newobj",
					"patching_rect": [
						70.0,
						922.0,
						30.0,
						22.0
					],
					"text": "+ 1",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"int"
					]
				}
			},
			{
				"box": {
					"id": "obj-raw-17",
					"maxclass": "newobj",
					"patching_rect": [
						30.0,
						952.0,
						110.0,
						22.0
					],
					"text": "prepend param salt",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					]
				}
			},
			{
				"box": {
					"id": "obj-raw-18",
					"maxclass": "newobj",
					"patching_rect": [
						480.0,
						792.0,
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
					"id": "obj-raw-19",
					"maxclass": "newobj",
					"patching_rect": [
						530.0,
						792.0,
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
					"id": "obj-raw-20",
					"maxclass": "newobj",
					"patching_rect": [
						530.0,
						822.0,
						50.0,
						22.0
					],
					"text": "unpack",
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
					"id": "obj-raw-21",
					"maxclass": "newobj",
					"patching_rect": [
						480.0,
						852.0,
						105.0,
						22.0
					],
					"text": "prepend param ow",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					]
				}
			},
			{
				"box": {
					"id": "obj-raw-22",
					"maxclass": "newobj",
					"patching_rect": [
						590.0,
						852.0,
						105.0,
						22.0
					],
					"text": "prepend param oh",
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
						"obj-20a",
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
						"obj-20a",
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
						"obj-20a",
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
						"obj-55",
						2
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
						"obj-55",
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
						"obj-50",
						0
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
						"obj-51",
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
						"obj-55",
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
						"obj-55",
						1
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
						"obj-50",
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
						"obj-5",
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
						"obj-55",
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
						"obj-55",
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
						"obj-53",
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
						"obj-54",
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
						"obj-raw-3",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-1",
						0
					],
					"destination": [
						"obj-raw-3",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-4",
						0
					],
					"destination": [
						"obj-raw-5",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-5",
						0
					],
					"destination": [
						"obj-raw-3",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-3",
						2
					],
					"destination": [
						"obj-raw-6",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-6",
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
						"obj-raw-3",
						1
					],
					"destination": [
						"obj-raw-7",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-7",
						0
					],
					"destination": [
						"obj-raw-9",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-3",
						0
					],
					"destination": [
						"obj-raw-15",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-8",
						0
					],
					"destination": [
						"obj-raw-9",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-9",
						0
					],
					"destination": [
						"obj-raw-10",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-10",
						0
					],
					"destination": [
						"obj-raw-11",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-11",
						0
					],
					"destination": [
						"obj-raw-9",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-9",
						0
					],
					"destination": [
						"obj-raw-14",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-14",
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
						"obj-raw-9",
						0
					],
					"destination": [
						"obj-raw-12",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-12",
						0
					],
					"destination": [
						"obj-raw-13",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-13",
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
						"obj-raw-15",
						0
					],
					"destination": [
						"obj-raw-16",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-16",
						0
					],
					"destination": [
						"obj-raw-15",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-15",
						0
					],
					"destination": [
						"obj-raw-17",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-17",
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
						"obj-raw-18",
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
						"obj-raw-18",
						0
					],
					"destination": [
						"obj-raw-19",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-19",
						0
					],
					"destination": [
						"obj-raw-20",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-20",
						0
					],
					"destination": [
						"obj-raw-21",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-20",
						1
					],
					"destination": [
						"obj-raw-22",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-21",
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
						"obj-raw-22",
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
				"pulse_depth",
				"pulse_depth",
				0
			],
			"obj-23": [
				"pulse_period",
				"pulse_period",
				0
			],
			"obj-26": [
				"out_mode",
				"out_mode",
				0
			],
			"obj-29": [
				"q_levels",
				"q_levels",
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