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
					"comment": "pattern (luma)",
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
					"numoutlets": 13,
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
						""
					],
					"patching_rect": [
						56.5,
						204.0,
						943.0,
						22.0
					],
					"text": "route rate grain aspect drive_gain energy habituation sharp excite zoom twist fovea contrast reset"
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
					"text": "jit.gl.pix vsynth @name #0_fc_hold @adapt 0 @type float32",
					"varname": "#0_fc_hold"
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
									"code": "// codebox_seed.gen -- f_formconstants noise stage: hash noise, deterministic\n// per texel per salt. Render-resolution float32 (@adapt 0, `r dim` resize).\n// Mirror: tests/modules/formconstants/fc_mirror.seed_state() (the seed\n// channels); the per-frame field (the Box-Muller happens downstream in the\n// nl stage). Same mechanism as f_wc's codebox_seed.gen, dim-generalized.\n//\n// Inputs: the first inlet is the `r draw` bang (unused; it only triggers the\n// render every frame). Packing: R = seed-E hash, G = seed-I hash (the pass\n// stage reads these ONLY on the frame reseed is 1: uniform [0, 1) per field,\n// independent channels, never zero), B, A = the two raw uniforms the nl stage\n// turns into the per-frame Box-Muller noise (the load-bearing mechanism,\n// tasks.md T002).\n//   - `salt` increments EVERY FRAME (the `r draw` counter in the raw wiring):\n//     the per-frame drive is what sustains the web (T002)\n//   - no sin(): a Hoskins-style arithmetic hash (fract and multiply-add only)\n//   - scalars only: components are never read from a stored vec\n//   - never name a variable e or phi (predefined constants)\n//   - functions are declared before Param declarations (GenExpr rule)\nhashf(x, y) {\n\tha = fract(x * 0.1031);\n\thb = fract(y * 0.1031);\n\thc = ha;\n\thd = ha * (hb + 33.33) + hb * (hc + 33.33) + hc * (ha + 33.33);\n\tha = ha + hd;\n\thb = hb + hd;\n\thc = hc + hd;\n\treturn fract((ha + hb) * hc);\n}\n\nParam salt(0);\nParam sw(128);\nParam sh(128);\n\npx = floor(norm.x * sw);\npy = floor(norm.y * sh);\n\nsa = salt * 61;\nsb = salt * 17;\nse = hashf(px + sa, py + sb);\nsi = hashf(px + sa + 113.7, py + sb + 57.3);\nna = hashf(px + sa + 271.9, py + sb + 181.3);\nnb = hashf(px + sa + 401.1, py + sb + 333.7);\n\nout1 = vec(se, si, na, nb);\n",
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
					"text": "jit.gl.pix vsynth @name #0_fc_seed @adapt 0 @type float32",
					"varname": "#0_fc_seed"
				}
			},
			{
				"box": {
					"id": "obj-60",
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
									"code": "// codebox_pass.gen -- f_formconstants stage 0: holds last frame's state\n// (E, I, Ve, Vi), or reseeds it. Render-resolution float32 (@adapt 0,\n// `r dim` resize). Mirror: fc_mirror.seed_state() (seeding), identity otherwise.\n// Same mechanism as f_wc's codebox_pass.gen, fc channel layout.\n//\n// Inputs: the first inlet is the `r draw` bang (unused; it only triggers the\n// render every frame, and the feedback arrives on a cold inlet so it cannot\n// retrigger the loop), the second is the feedback state (R = E, G = I, B = Ve,\n// A = Vi, from the nl stage through the hold stage), the third is the noise\n// texture (R = seed-E hash, G = seed-I hash, from the seed stage).\n// reseed = 1 replaces the state with uniform noise in [0, amp): E from R, I\n// from G (two independent hash channels), never zero and never uniform rest\n// (it is a fixed point of the whole update, FR-004). reseed fires on load, on\n// the reset trigger (FR-009), and on a render-size change (T013: `r dim`\n// -> delay -> the reseed trigger -- the deliberate resize seam).\n//   - SELF-HEAL: a feedback texel that is exactly 0 in BOTH of R, G is\n//     reseeded from the noise too. A live WC field never holds an exact 0\n//     (E, I stay inside (0, 1): relaxation toward a sigmoid output), so this\n//     fires only when the state was lost: a fresh module, a GL context rebuilt\n//     by a window mode change, or a non-finite texel the nl stage zapped\n//   - selection uses switch(), not mix(): mix(NaN, x, 1) is still NaN, so a\n//     poisoned feedback texel could survive a reseed through mix\n//   - the feedback is NaN/Inf-guarded: abs(x) < 1e30 (NaN == NaN is TRUE on\n//     this GPU)\n//   - packing: R = E, G = I, B = Ve, A = Vi (the fc state layout, shared by\n//     pass, blur_x, blur_y, nl, enc -- Ve/Vi ride the spare channels THROUGH\n//     the blur stages untouched). Ve/Vi reset to 0 on reseed and on self-heal:\n//     the adaptation memory restarts with the new pattern. With habit = 0 the\n//     nl stage writes 0 in B, A, so B, A stay exactly 0 (T002's free-run\n//     dynamics are untouched).\nParam reseed(0);\nParam amp(1);\n\nfbe = nearest(in2, norm).x;\nfbe = switch(abs(fbe) < 1e30, fbe, 0);\nfbi = nearest(in2, norm).y;\nfbi = switch(abs(fbi) < 1e30, fbi, 0);\nfbv = nearest(in2, norm).z;\nfbv = switch(abs(fbv) < 1e30, fbv, 0);\nfbw = nearest(in2, norm).w;\nfbw = switch(abs(fbw) < 1e30, fbw, 0);\nze = nearest(in3, norm).x * amp;\nzi = nearest(in3, norm).y * amp;\nlost = (fbe == 0) * (fbi == 0);\nkept_e = switch(lost > 0.5, ze, fbe);\nkept_i = switch(lost > 0.5, zi, fbi);\nkept_ve = switch(lost > 0.5, 0, fbv);\nkept_vi = switch(lost > 0.5, 0, fbw);\nout1 = vec(switch(reseed >= 0.5, ze, kept_e), switch(reseed >= 0.5, zi, kept_i),\n           switch(reseed >= 0.5, 0, kept_ve), switch(reseed >= 0.5, 0, kept_vi));\n",
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
					"text": "jit.gl.pix vsynth @name #0_fc_pass @adapt 0 @type float32",
					"varname": "#0_fc_pass"
				}
			},
			{
				"box": {
					"id": "obj-61",
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
									"code": "// codebox_blur_x.gen -- f_formconstants blur stage (X pass): the real-space\n// separable Gaussian coupling (FR-002). R (E) blurred at sigma_E, G (I) at\n// sigma_I, in ONE read pass (per-channel weights, shared texels); B/A pass\n// through. Runs at render resolution (@adapt 0, `r dim` resize).\n// Mirror: tests/modules/formconstants/fc_mirror.gauss_taps() / blur_axis() --\n// the EXACT discrete kernel the mirror asserts: radius ceil(3*sigma),\n// normalized exp(-i^2/2 sigma^2) weights, wrap boundary.\n//\n// sigma is derived per frame (T011): si = clamp(grain * min(dim.x, dim.y),\n// 0.75, 1.4) -- the measured sustaining band, T003; se = si / sig_ratio.\n//   - 11 taps cover radius ceil(3*1.4) = 5; taps past ceil(3*sigma) are\n//     masked to 0 (the mirror's truncation, not a full Gaussian)\n//   - texel-centre reads (ix + 0.5)/dim.x with explicit wrap -- np.roll parity\n//   - weights computed inline from the Params (NO kernel tables; jit.gl.pix\n//     Params are scalars, GPUGaussianMultiBlur's vec4-weights trick does not\n//     apply inside a codebox)\n//   - GenExpr discipline (the f_wc 2026-10-24 lesson): no functions with\n//     destructuring or global refs; everything inlined with suffixed names\nParam grain(0.0008);\nParam sig_ratio(1.45);\n\nsi = clamp(grain * min(dim.x, dim.y), 0.75, 1.4);\nse = si / sig_ratio;\n\nqe = ceil(3 * se);                    // tap radius = ceil(3 sigma) -- the mirror's\nqi = ceil(3 * si);                    //   gauss_taps() exactly (a (3s)^2 mask cuts a tap early)\nre = 0 - 0.5 / (se * se);           // exponent scale, no unary minus\nri = 0 - 0.5 / (si * si);\n\nix = floor(norm.x * dim.x);\niy = floor(norm.y * dim.y);\n\n// center tap\nxw0 = ix - dim.x * floor(ix / dim.x);\nyw0 = iy - dim.y * floor(iy / dim.y);\nt0 = nearest(in1, vec((xw0 + 0.5) / dim.x, (yw0 + 0.5) / dim.y));\nwse = 1; wsi = 1;\nace = t0.x; aci = t0.y;\n\n// taps 1..5, symmetric pairs (weights written fully inline)\nwe1 = switch(1 <= qe, exp(1 * re), 0);\nwi1 = switch(1 <= qi, exp(1 * ri), 0);\nxwp1 = (ix + 1) - dim.x * floor((ix + 1) / dim.x);\nxwn1 = (ix - 1) - dim.x * floor((ix - 1) / dim.x);\ntp1 = nearest(in1, vec((xwp1 + 0.5) / dim.x, (yw0 + 0.5) / dim.y));\ntn1 = nearest(in1, vec((xwn1 + 0.5) / dim.x, (yw0 + 0.5) / dim.y));\nwse = wse + 2 * we1; wsi = wsi + 2 * wi1;\nace = ace + we1 * (tp1.x + tn1.x); aci = aci + wi1 * (tp1.y + tn1.y);\n\nwe2 = switch(2 <= qe, exp(4 * re), 0);\nwi2 = switch(2 <= qi, exp(4 * ri), 0);\nxwp2 = (ix + 2) - dim.x * floor((ix + 2) / dim.x);\nxwn2 = (ix - 2) - dim.x * floor((ix - 2) / dim.x);\ntp2 = nearest(in1, vec((xwp2 + 0.5) / dim.x, (yw0 + 0.5) / dim.y));\ntn2 = nearest(in1, vec((xwn2 + 0.5) / dim.x, (yw0 + 0.5) / dim.y));\nwse = wse + 2 * we2; wsi = wsi + 2 * wi2;\nace = ace + we2 * (tp2.x + tn2.x); aci = aci + wi2 * (tp2.y + tn2.y);\n\nwe3 = switch(3 <= qe, exp(9 * re), 0);\nwi3 = switch(3 <= qi, exp(9 * ri), 0);\nxwp3 = (ix + 3) - dim.x * floor((ix + 3) / dim.x);\nxwn3 = (ix - 3) - dim.x * floor((ix - 3) / dim.x);\ntp3 = nearest(in1, vec((xwp3 + 0.5) / dim.x, (yw0 + 0.5) / dim.y));\ntn3 = nearest(in1, vec((xwn3 + 0.5) / dim.x, (yw0 + 0.5) / dim.y));\nwse = wse + 2 * we3; wsi = wsi + 2 * wi3;\nace = ace + we3 * (tp3.x + tn3.x); aci = aci + wi3 * (tp3.y + tn3.y);\n\nwe4 = switch(4 <= qe, exp(16 * re), 0);\nwi4 = switch(4 <= qi, exp(16 * ri), 0);\nxwp4 = (ix + 4) - dim.x * floor((ix + 4) / dim.x);\nxwn4 = (ix - 4) - dim.x * floor((ix - 4) / dim.x);\ntp4 = nearest(in1, vec((xwp4 + 0.5) / dim.x, (yw0 + 0.5) / dim.y));\ntn4 = nearest(in1, vec((xwn4 + 0.5) / dim.x, (yw0 + 0.5) / dim.y));\nwse = wse + 2 * we4; wsi = wsi + 2 * wi4;\nace = ace + we4 * (tp4.x + tn4.x); aci = aci + wi4 * (tp4.y + tn4.y);\n\nwe5 = switch(5 <= qe, exp(25 * re), 0);\nwi5 = switch(5 <= qi, exp(25 * ri), 0);\nxwp5 = (ix + 5) - dim.x * floor((ix + 5) / dim.x);\nxwn5 = (ix - 5) - dim.x * floor((ix - 5) / dim.x);\ntp5 = nearest(in1, vec((xwp5 + 0.5) / dim.x, (yw0 + 0.5) / dim.y));\ntn5 = nearest(in1, vec((xwn5 + 0.5) / dim.x, (yw0 + 0.5) / dim.y));\nwse = wse + 2 * we5; wsi = wsi + 2 * wi5;\nace = ace + we5 * (tp5.x + tn5.x); aci = aci + wi5 * (tp5.y + tn5.y);\n\nout1 = vec(ace / wse, aci / wsi, t0.z, t0.w);\n",
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
					"text": "jit.gl.pix vsynth @name #0_fc_blurx @adapt 0 @type float32",
					"varname": "#0_fc_blurx"
				}
			},
			{
				"box": {
					"id": "obj-62",
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
									"code": "// codebox_blur_y.gen -- f_formconstants blur stage (Y pass): the second half\n// of the separable Gaussian coupling (FR-002). Identical math to\n// codebox_blur_x.gen with the taps running along Y; see that file for the\n// kernel contract (exact discrete kernel: radius ceil(3*sigma), normalized\n// exp(-i^2/2 sigma^2) weights, wrap; mirror: fc_mirror.gauss_taps/blur_axis).\nParam grain(0.0008);\nParam sig_ratio(1.45);\n\nsi = clamp(grain * min(dim.x, dim.y), 0.75, 1.4);\nse = si / sig_ratio;\n\nqe = ceil(3 * se);\nqi = ceil(3 * si);\nre = 0 - 0.5 / (se * se);\nri = 0 - 0.5 / (si * si);\n\nix = floor(norm.x * dim.x);\niy = floor(norm.y * dim.y);\n\nxw0 = ix - dim.x * floor(ix / dim.x);\nyw0 = iy - dim.y * floor(iy / dim.y);\nt0 = nearest(in1, vec((xw0 + 0.5) / dim.x, (yw0 + 0.5) / dim.y));\nwse = 1; wsi = 1;\nace = t0.x; aci = t0.y;\n\nwe1 = switch(1 <= qe, exp(1 * re), 0);\nwi1 = switch(1 <= qi, exp(1 * ri), 0);\nywp1 = (iy + 1) - dim.y * floor((iy + 1) / dim.y);\nywn1 = (iy - 1) - dim.y * floor((iy - 1) / dim.y);\ntp1 = nearest(in1, vec((xw0 + 0.5) / dim.x, (ywp1 + 0.5) / dim.y));\ntn1 = nearest(in1, vec((xw0 + 0.5) / dim.x, (ywn1 + 0.5) / dim.y));\nwse = wse + 2 * we1; wsi = wsi + 2 * wi1;\nace = ace + we1 * (tp1.x + tn1.x); aci = aci + wi1 * (tp1.y + tn1.y);\n\nwe2 = switch(2 <= qe, exp(4 * re), 0);\nwi2 = switch(2 <= qi, exp(4 * ri), 0);\nywp2 = (iy + 2) - dim.y * floor((iy + 2) / dim.y);\nywn2 = (iy - 2) - dim.y * floor((iy - 2) / dim.y);\ntp2 = nearest(in1, vec((xw0 + 0.5) / dim.x, (ywp2 + 0.5) / dim.y));\ntn2 = nearest(in1, vec((xw0 + 0.5) / dim.x, (ywn2 + 0.5) / dim.y));\nwse = wse + 2 * we2; wsi = wsi + 2 * wi2;\nace = ace + we2 * (tp2.x + tn2.x); aci = aci + wi2 * (tp2.y + tn2.y);\n\nwe3 = switch(3 <= qe, exp(9 * re), 0);\nwi3 = switch(3 <= qi, exp(9 * ri), 0);\nywp3 = (iy + 3) - dim.y * floor((iy + 3) / dim.y);\nywn3 = (iy - 3) - dim.y * floor((iy - 3) / dim.y);\ntp3 = nearest(in1, vec((xw0 + 0.5) / dim.x, (ywp3 + 0.5) / dim.y));\ntn3 = nearest(in1, vec((xw0 + 0.5) / dim.x, (ywn3 + 0.5) / dim.y));\nwse = wse + 2 * we3; wsi = wsi + 2 * wi3;\nace = ace + we3 * (tp3.x + tn3.x); aci = aci + wi3 * (tp3.y + tn3.y);\n\nwe4 = switch(4 <= qe, exp(16 * re), 0);\nwi4 = switch(4 <= qi, exp(16 * ri), 0);\nywp4 = (iy + 4) - dim.y * floor((iy + 4) / dim.y);\nywn4 = (iy - 4) - dim.y * floor((iy - 4) / dim.y);\ntp4 = nearest(in1, vec((xw0 + 0.5) / dim.x, (ywp4 + 0.5) / dim.y));\ntn4 = nearest(in1, vec((xw0 + 0.5) / dim.x, (ywn4 + 0.5) / dim.y));\nwse = wse + 2 * we4; wsi = wsi + 2 * wi4;\nace = ace + we4 * (tp4.x + tn4.x); aci = aci + wi4 * (tp4.y + tn4.y);\n\nwe5 = switch(5 <= qe, exp(25 * re), 0);\nwi5 = switch(5 <= qi, exp(25 * ri), 0);\nywp5 = (iy + 5) - dim.y * floor((iy + 5) / dim.y);\nywn5 = (iy - 5) - dim.y * floor((iy - 5) / dim.y);\ntp5 = nearest(in1, vec((xw0 + 0.5) / dim.x, (ywp5 + 0.5) / dim.y));\ntn5 = nearest(in1, vec((xw0 + 0.5) / dim.x, (ywn5 + 0.5) / dim.y));\nwse = wse + 2 * we5; wsi = wsi + 2 * wi5;\nace = ace + we5 * (tp5.x + tn5.x); aci = aci + wi5 * (tp5.y + tn5.y);\n\nout1 = vec(ace / wse, aci / wsi, t0.z, t0.w);\n",
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
					"text": "jit.gl.pix vsynth @name #0_fc_blury @adapt 0 @type float32",
					"varname": "#0_fc_blury"
				}
			},
			{
				"box": {
					"id": "obj-63",
					"maxclass": "newobj",
					"numinlets": 4,
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
									"code": "// codebox_nl.gen -- f_formconstants heart (the Phase-0 settled model):\n// exact relaxation toward the logistic sigmoid of the coupled drive, per frame:\n//   E += (F(AEE*cE - AIE*cI - HE + ne*nx + drive_gain*(drv-0.5) + excite - habit*Ve) - E) * dt/TE\n//   I += (F(AEI*cE - AII*cI - HI + ne*nx + excite - habit*Vi) - I) * dt/TI\n//   Ve += (E - Ve)*dt/50   Vi += (I - Vi)*dt/100\n// Render-resolution float32 (@adapt 0, `r dim` resize).\n// Mirror: tests/modules/formconstants/fc_mirror.nonlinear_step().\n//\n// Inputs (4): in1 = the convolved fields (R = blur_E E, G = blur_I I, from\n// blur_y), in2 = the raw state (R = E, G = I, B = Ve, A = Vi, from the pass\n// stage -- the relaxation target and the carry are the same frame), in3 = the\n// noise texture (B, A = the two raw uniforms; fresh every frame), in4 = the\n// drive inlet (R; through a vs_inState, so UNCONNECTED reads vs_black and the\n// patcher sets drv_conn = 0: the codebox falls back to neutral 0.5, G3).\n//   - fresh Gaussian noise into BOTH sigmoid inputs, Box-Muller from the two\n//     uniforms, sqrt(dt)-scaled, same nx in E and I (the Rule form; the\n//     per-frame drive is load-bearing -- T002)\n//   - constants are the measured sustaining corner (T002/G0): AEE 16.1,\n//     AIE 14.5 (dial), AEI 13.7, AII 13.0 (dial), HE 3.1, HI 3.5, TE 4,\n//     TI 12.5; energy default 0.75; HABITUATION default 0.9 and load-bearing\n//     (without it the field saturates by ~3k frames; G1/ships in v1).\n//     The Example-10 constants (10.5/8.5/12/3, He 2) measured DEAD at\n//     float32 -- T002 record.\n//   - EXCITE (f_wc G7): one shared positive offset inside both sigmoid inputs\n//   - NaN/Inf zap per the f_ks containment precedent (abs(x) < 1e30, NaN ==\n//     NaN is TRUE on this GPU); zapped texels are self-healed by the pass stage\n//   - with habit == 0 the B, A outputs are exactly 0 (the bit-preserving rule)\n//   - no unary minus before a parenthesis (GenExpr mis-parses it)\nParam dt(1);\nParam ne(0.75);\nParam drive_gain(0);\nParam drv_conn(0);\nParam habit(0.9);\nParam excite(0);\nParam aie(14.5);\nParam aii(13.0);\n\nce = nearest(in1, norm).x;\nci = nearest(in1, norm).y;\nee = nearest(in2, norm).x;\nii = nearest(in2, norm).y;\nve = nearest(in2, norm).z;\nvi = nearest(in2, norm).w;\nna = nearest(in3, norm).z * 0.999 + 0.0001;\nnb = nearest(in3, norm).w * 0.999 + 0.0001;\nnx = sqrt(0 - 2 * log(na)) * cos(twopi * nb) * sqrt(dt);\ndrv = mix(0.5, nearest(in4, norm).x, drv_conn);\n\nae = 1 / (1 + exp(0 - clamp(16.1 * ce - aie * ci - 3.1 + excite - habit * ve + ne * nx + drive_gain * (drv - 0.5), -60, 60)));\nai = 1 / (1 + exp(0 - clamp(13.7 * ce - aii * ci - 3.5 + excite - habit * vi + ne * nx, -60, 60)));\n\nen = ee + (ae - ee) * (dt * 0.25);\ninw = ii + (ai - ii) * (dt * 0.08);\nen = switch(abs(en) < 1e30, en, 0);\ninw = switch(abs(inw) < 1e30, inw, 0);\nven = ve + (en - ve) * (dt * 0.02);\nvin = vi + (inw - vi) * (dt * 0.01);\nven = switch(abs(ven) < 1e30, ven, 0);\nvin = switch(abs(vin) < 1e30, vin, 0);\nveo = switch(habit != 0, ven, 0);\nvio = switch(habit != 0, vin, 0);\n\nout1 = vec(en, inw, veo, vio);\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
									"id": "gen-obj-2",
									"maxclass": "codebox",
									"numinlets": 4,
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
							}
						]
					},
					"patching_rect": [
						30.0,
						580.0,
						200.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_fc_nl @adapt 0 @type float32",
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
									"code": "// codebox_enc.gen -- f_formconstants render stage: the inverse retinotopic\n// resample. Maps each output pixel's visual-field polar coords (r, theta) to\n// cortical (u, v) = (k_ecc*log(1 + sqrt(r^2 + r_soft^2)/r0), k_ang*theta) and\n// samples the E field there, periodic in both cortical axes.\n// Runs at render resolution AND SO DOES THE STATE (FR-001: solver res ==\n// render res; `r dim` resizes every stage) -- no reconstruction filter is\n// needed or wanted: hardware-exact manual bilinear WITH WRAP, mirroring\n// tests/modules/formconstants/fc_mirror.encode() term for term (the f_wc\n// 16-tap Catmull-Rom exists to hide 256^2-quantized contours, the artifact\n// class this module does not have -- tasks.md record 2026-10-24).\n// Mirror: tests/modules/formconstants/fc_mirror.encode().\n//\n// Inputs: in1 = the `r draw` bang (not referenced here), in2 = the state\n// (R = E, from the nl stage).\n//   - the cortical sample: fx = cv*sw - 0.5, fy = cu*sh - 0.5, floor +\n//     fractions, 4 nearest texel-centre reads wrapped per axis, lerp. The\n//     state size comes from the sw/sh PARAMS (raw `r dim` -> route/unpack ->\n//     prepend param), NOT the `dim` global: `dim` is not an input texture's\n//     size (jit-gen-codebox skill: manual taps need the size as a literal or\n//     a Param; the 2026-10-24 solid-flicker debug found enc/seed's in1\n//     bound-texture dims degenerate)\n//   - the cortical axes: u (eccentricity) = ROWS, v (angle) = COLUMNS (the\n//     f_wc mirror convention, retained so the map records/render scripts\n//     compare directly)\n//   - map constants are dials (defaults from G0's stills: zoom 5, twist 3,\n//     fovea 1.0 -- the CLOSER set, the best read at the fine web scale;\n//     retune Phase 2); r_max 4 stays baked (the f_wc field of view)\n//   - FOVEAL SOFTENING (f_wc 2026-10-24, retained): u flattens for\n//     r << r_soft so the log-singularity vortex becomes a calm disc;\n//     r_soft is a bench-vary Param\n//   - display mapping (f_wc G4): E is already a 0..1 rate; contrast stretch\n//     about mid-gray, then sharp blends toward the crisp S-curve; default\n//     0.5 (f_wc's soak finding)\n//   - non-finite E maps to 0 (abs(x) < 1e30 guard: NaN == NaN is TRUE here)\n//   - bypass_gate = 1 outputs black with alpha 1 (the f_chladni generator\n//     convention); the solver keeps running upstream. The Param is never\n//     named `bypass` (native pix attribute, f_wc FR-010's lesson)\nParam bypass_gate(0);\nParam sharp(0.5);\nParam contrast(1.0);\nParam k_ecc(5.0);\nParam k_ang(3);\nParam r0(1.0);\nParam r_soft(0.35);\nParam sw(128);\nParam sh(128);\n\npx = (norm.x * 2 - 1) * 4;\npy = (norm.y * 2 - 1) * 4;\nr, theta = cartopol(px, py);\nu = k_ecc * log(1 + sqrt(r * r + r_soft * r_soft) / r0);\nv = k_ang * theta;\ncu = fract(u / twopi);\ncv = fract(v / twopi);\n\nfx = cv * sw - 0.5;\nfy = cu * sh - 0.5;\nx0 = floor(fx);\ny0 = floor(fy);\ntx = fx - x0;\nty = fy - y0;\nxa0 = x0 - sw * floor(x0 / sw);\nxb0 = (x0 + 1) - sw * floor((x0 + 1) / sw);\nya0 = y0 - sh * floor(y0 / sh);\nyb0 = (y0 + 1) - sh * floor((y0 + 1) / sh);\ncxa = (xa0 + 0.5) / sw;\ncxb = (xb0 + 0.5) / sw;\ncya = (ya0 + 0.5) / sh;\ncyb = (yb0 + 0.5) / sh;\ne00 = nearest(in2, vec(cxa, cya)).x;\ne10 = nearest(in2, vec(cxb, cya)).x;\ne01 = nearest(in2, vec(cxa, cyb)).x;\ne11 = nearest(in2, vec(cxb, cyb)).x;\nau = (1 - ty) * ((1 - tx) * e00 + tx * e10) + ty * ((1 - tx) * e01 + tx * e11);\n\nau = switch(abs(au) < 1e30, au, 0);\nsoft = clamp((clamp(au, 0, 1) - 0.5) * contrast + 0.5, 0, 1);\ncrisp = smoothstep(0.46, 0.54, soft);\nlum = mix(soft, crisp, sharp);\nlum = lum * (1 - bypass_gate);\n\nout1 = vec(lum, lum, lum, 1);\n",
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
					"text": "jit.gl.pix vsynth @name #0_fc_enc @adapt 0 @type float32",
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
						1279.5,
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
						1059.5,
						260.0,
						247.0,
						212.0
					],
					"presentation": 1,
					"presentation_rect": [
						0.0,
						0.0,
						247.0,
						212.0
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
						1279.5,
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
						1369.5,
						200.0,
						60.0,
						21.0
					],
					"presentation": 1,
					"presentation_rect": [
						151.0,
						0.9,
						70.0,
						21.0
					],
					"text": "luma out"
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
						1279.5,
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
						1299.5,
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
						1059.5,
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
						1059.5,
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
						1059.5,
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
						1059.5,
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
						1059.5,
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
						1059.5,
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
					"comment": "drive in (scene; unconnected = free hallucination)",
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
					"text": "prepend param drv_conn"
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
					"hint": "Time step per frame (1 = the validated tempo). No stability ceiling; the top is aesthetic",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_fc_nl::rate",
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
								1.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "rate",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "rate",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "rate"
				}
			},
			{
				"box": {
					"id": "obj-21",
					"maxclass": "attrui",
					"attr": "dt",
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
					"text": "Rate",
					"textjustification": 1,
					"varname": "lbl_rate"
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
					"hint": "Texture scale: sigma as a fraction of frame height, clamped to the sustaining band 0.75-1.4 screen px (T003). Low = fine silk; high ends pulse and die",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_fc_blurx::grain",
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
								0.0008
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "grain",
							"parameter_mmax": 0.003,
							"parameter_mmin": 0.0003,
							"parameter_modmode": 3,
							"parameter_shortname": "grain",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "grain"
				}
			},
			{
				"box": {
					"id": "obj-24",
					"maxclass": "attrui",
					"attr": "grain",
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
					"attr": "grain",
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
					"text": "Grain",
					"textjustification": 1,
					"varname": "lbl_grain"
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
					"hint": "Inhibition-to-excitation kernel ratio (f_wc G6 semantics): steers ordering. 1.45 default",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_fc_blurx::aspect",
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
								1.45
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "aspect",
							"parameter_mmax": 2.2,
							"parameter_mmin": 1.2,
							"parameter_modmode": 3,
							"parameter_shortname": "aspect",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "aspect"
				}
			},
			{
				"box": {
					"id": "obj-27",
					"maxclass": "attrui",
					"attr": "sig_ratio",
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
					"attr": "sig_ratio",
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
					"text": "Aspect",
					"textjustification": 1,
					"varname": "lbl_aspect"
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
					"hint": "Scene strength: 0 = pure hallucination; ~1.5 = the drive inlet imprints (normal vision)",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_fc_nl::drive_gain",
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
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "drive_gain",
							"parameter_mmax": 2.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "drive_gain",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "drive_gain"
				}
			},
			{
				"box": {
					"id": "obj-30",
					"maxclass": "attrui",
					"attr": "drive_gain",
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
					"text": "Drive",
					"textjustification": 1,
					"varname": "lbl_drive_gain"
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
					"hint": "Per-frame noise energy (Ne, load-bearing: T002). 0.75 default; the sustain axis with Habituation",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_fc_nl::energy",
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
								0.75
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "energy",
							"parameter_mmax": 2.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "energy",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "energy"
				}
			},
			{
				"box": {
					"id": "obj-33",
					"maxclass": "attrui",
					"attr": "ne",
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
					"text": "Energy",
					"textjustification": 1,
					"varname": "lbl_energy"
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
					"hint": "Fatigue: slow negative feedback (load-bearing at fine grain: without it the field saturates by ~3k frames). 0.9 default = steady web; ~0.2 = pulsing family",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_fc_nl::habituation",
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
								0.9
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "habituation",
							"parameter_mmax": 2.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "habituation",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "habituation"
				}
			},
			{
				"box": {
					"id": "obj-36",
					"maxclass": "attrui",
					"attr": "habit",
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
					"text": "Habituation",
					"textjustification": 1,
					"varname": "lbl_habituation"
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
					"hint": "Edge sharpness: 0 = soft gradients, 1 = hard-edged cells. The web stays silky at any setting -- the state is render-resolution",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_fc_enc::sharp",
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
								0.5
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "sharp",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "sharp",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "sharp"
				}
			},
			{
				"box": {
					"id": "obj-39",
					"maxclass": "attrui",
					"attr": "sharp",
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
					"text": "Sharp",
					"textjustification": 1,
					"varname": "lbl_sharp"
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
					"hint": "Excitability: firing thresholds, E and I together (f_wc G7). + = hotter; - = toward blackout; breathes the web (the source page's square wave, as a gesture)",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_fc_nl::excite",
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
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "excite",
							"parameter_mmax": 0.8,
							"parameter_mmin": -0.3,
							"parameter_modmode": 3,
							"parameter_shortname": "excite",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "excite"
				}
			},
			{
				"box": {
					"id": "obj-42",
					"maxclass": "attrui",
					"attr": "excite",
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
					"text": "Excite",
					"textjustification": 1,
					"varname": "lbl_excite"
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
					"hint": "Eccentricity gain of the retinotopic map (log-radius zoom). 5 = the close corner from the stills; 1 = the webgpgpu bare-log corner",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_fc_enc::zoom",
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
								5.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "zoom",
							"parameter_mmax": 16.0,
							"parameter_mmin": 1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "zoom",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "zoom"
				}
			},
			{
				"box": {
					"id": "obj-45",
					"maxclass": "attrui",
					"attr": "k_ecc",
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
					"text": "Zoom",
					"textjustification": 1,
					"varname": "lbl_zoom"
				}
			},
			{
				"box": {
					"id": "obj-47",
					"maxclass": "live.numbox",
					"fontname": "Ableton Sans Light",
					"hint": "Angular gain of the map (spoke fold); integer only -- fractional seams the field. 3 = default",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_fc_enc::twist",
					"parameter_enable": 1,
					"patching_rect": [
						686.0,
						250.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						152.0,
						100.0,
						34.0,
						15.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								3.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "twist",
							"parameter_mmax": 8.0,
							"parameter_mmin": 1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "twist",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"varname": "twist"
				}
			},
			{
				"box": {
					"id": "obj-48",
					"maxclass": "attrui",
					"attr": "k_ang",
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
					"text": "Twist",
					"textjustification": 1,
					"varname": "lbl_twist"
				}
			},
			{
				"box": {
					"id": "obj-50",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Foveal radius of the map: smaller = more center magnification. 1.0 = the close corner (the bare-log 0.003 vortex is an alias at this scale)",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_fc_enc::fovea",
					"parameter_enable": 1,
					"patching_rect": [
						766.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						4.0,
						162.0,
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
							"parameter_longname": "fovea",
							"parameter_mmax": 5.0,
							"parameter_mmin": 0.001,
							"parameter_modmode": 3,
							"parameter_shortname": "fovea",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "fovea"
				}
			},
			{
				"box": {
					"id": "obj-51",
					"maxclass": "attrui",
					"attr": "r0",
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
					"text": "Fovea",
					"textjustification": 1,
					"varname": "lbl_fovea"
				}
			},
			{
				"box": {
					"id": "obj-53",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Display stretch about mid-gray, before the Sharp curve (f_wc G8a). 1 = neutral",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_fc_enc::contrast",
					"parameter_enable": 1,
					"patching_rect": [
						838.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						41.0,
						162.0,
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
							"parameter_longname": "contrast",
							"parameter_mmax": 8.0,
							"parameter_mmin": 0.5,
							"parameter_modmode": 3,
							"parameter_shortname": "contrast",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "contrast"
				}
			},
			{
				"box": {
					"id": "obj-54",
					"maxclass": "attrui",
					"attr": "contrast",
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
					"text": "Contrast",
					"textjustification": 1,
					"varname": "lbl_contrast"
				}
			},
			{
				"box": {
					"id": "obj-56",
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
						1279.5,
						130.0,
						18.0,
						12.0
					],
					"presentation_rect": [
						225.0,
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
					"id": "obj-57",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1279.5,
						160.0,
						131.0,
						22.0
					],
					"text": "prepend param bypass_gate"
				}
			},
			{
				"box": {
					"id": "obj-raw-15",
					"maxclass": "newobj",
					"patching_rect": [
						330.0,
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
						227.0,
						46.0,
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
						216.0,
						24.0,
						50.0,
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
						40.0,
						22.0
					],
					"text": "t b b",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
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
					"id": "obj-raw-7",
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
					"id": "obj-raw-10",
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
					"id": "obj-raw-11",
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
					"id": "obj-raw-6",
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
					"id": "obj-raw-12",
					"maxclass": "newobj",
					"patching_rect": [
						300.0,
						952.0,
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
					"id": "obj-raw-13",
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
					"id": "obj-raw-14",
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
					"id": "obj-raw-9",
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
					"id": "obj-raw-16",
					"maxclass": "newobj",
					"patching_rect": [
						380.0,
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
					"id": "obj-raw-17",
					"maxclass": "newobj",
					"patching_rect": [
						380.0,
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
					"id": "obj-raw-18",
					"maxclass": "newobj",
					"patching_rect": [
						330.0,
						852.0,
						105.0,
						22.0
					],
					"text": "prepend param sw",
					"numinlets": 1,
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
						440.0,
						852.0,
						105.0,
						22.0
					],
					"text": "prepend param sh",
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
						"obj-59",
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
						"obj-60",
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
						"obj-63",
						3
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
						"obj-63",
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
						"obj-58",
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
						"obj-59",
						0
					],
					"destination": [
						"obj-60",
						2
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
						"obj-61",
						0
					],
					"destination": [
						"obj-62",
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
						"obj-60",
						0
					],
					"destination": [
						"obj-63",
						1
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
						"obj-63",
						2
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
						"obj-58",
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
						"obj-63",
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
						"obj-61",
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
						"obj-61",
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
						"obj-63",
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
						"obj-63",
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
						"obj-63",
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
						"obj-63",
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
						"obj-62",
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
						"obj-62",
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
						"obj-5",
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
						"obj-58",
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
						"obj-59",
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
						"obj-60",
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
						"obj-61",
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
						"obj-62",
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
						"obj-63",
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
						"obj-raw-5",
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
						0
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
						"obj-60",
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
						"obj-raw-11",
						1
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
						"obj-raw-11",
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
						"obj-raw-18",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-17",
						1
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
						"obj-raw-18",
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
						"obj-raw-19",
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
						"obj-raw-19",
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
						"obj-raw-11",
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
						"obj-59",
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
						"obj-60",
						0
					]
				}
			}
		],
		"parameters": {
			"obj-20": [
				"rate",
				"rate",
				0
			],
			"obj-23": [
				"grain",
				"grain",
				0
			],
			"obj-26": [
				"aspect",
				"aspect",
				0
			],
			"obj-29": [
				"drive_gain",
				"drive_gain",
				0
			],
			"obj-32": [
				"energy",
				"energy",
				0
			],
			"obj-35": [
				"habituation",
				"habituation",
				0
			],
			"obj-38": [
				"sharp",
				"sharp",
				0
			],
			"obj-41": [
				"excite",
				"excite",
				0
			],
			"obj-44": [
				"zoom",
				"zoom",
				0
			],
			"obj-47": [
				"twist",
				"twist",
				0
			],
			"obj-50": [
				"fovea",
				"fovea",
				0
			],
			"obj-53": [
				"contrast",
				"contrast",
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