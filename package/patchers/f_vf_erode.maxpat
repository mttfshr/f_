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
					"comment": "picture / control",
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
					"comment": "ink (composite over the background)",
					"index": 0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						30.0,
						652.0,
						30.0,
						30.0
					]
				}
			},
			{
				"box": {
					"id": "obj-201",
					"maxclass": "outlet",
					"comment": "thickness (pigment on the paper)",
					"index": 0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						100.0,
						652.0,
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
					"text": "route polar_sw flow push lift settle dry speed flood feed fade wet"
				}
			},
			{
				"box": {
					"id": "obj-52",
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
									"code": "// codebox_hold.gen -- f_vf_erode: the loop break and one-frame delay of the state atlas (the f_vf_lbm / f_ks hold idiom).\n// An identity pass over the atlas: W x 2H float32 at the render size, two RGBA planes stacked vertically (plan ADR-1).\n//   plane A (rows 0..H-1):   R water depth w, GBA pigment in suspension s\n//   plane B (rows H..2H-1):  RGB pigment on the paper p, A the load flag (see codebox_load.gen)\n// Inlets (outer order): first = the frame bang and the `dim W 2H` message (hot; unused in the code), second = the state from\n// the react stage (cold). The load stage is triggered by this stage's output, so the loop advances once per frame.\n// Not benched on its own (an identity); the live module bench covers it.\nout1 = nearest(in2, norm);\n",
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
						380.0,
						200.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_vferode_hold @adapt 0 @dim 256 512 @type float32",
					"varname": "#0_vferode_hold"
				}
			},
			{
				"box": {
					"id": "obj-53",
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
									"code": "// codebox_prep.gen -- f_vf_erode: the static part of the water's face velocities and of the lift/settle drive, from the terrain\n// and the vecfield. W x 2H float32 at the render size (the same atlas shape as the state; plan ADR-2, amended 2026-11-10).\n// Mirror: tests/modules/vf_erode/vf_erode_mirror.step(), the parts of vx, vy and (cx, cy) that do not depend on the water depth.\n//\n//   plane 0 (rows 0..H-1):   R = static velocity across the cell's LEFT face (x, positive = to the right), G = RIGHT face,\n//                            B = UP face (y, positive = down the rows), A = DOWN face\n//   plane 1 (rows H..2H-1):  R, G = (cx, cy) without the water slope: the field minus flow * the terrain gradient\n//   face velocity = speed * (-fe * (T_B - T_A) + 0.5 * (F_A + F_B)); A is the left/up cell, B the right/down cell. The water\n//   adds its own slope term (-speed * flow * (w_B - w_A)) in the transport stage. A face is stored by BOTH of its cells and the\n//   two are the same operands in the same order, so the water leaving one cell is exactly what arrives in the next.\n//   FRAME EDGE (T066, plan ADR-3): the cell beyond the frame has the terrain continued linearly (odd reflection) and the field\n//   replicated, so the static part of an edge face is the one-sided terrain slope plus the edge field.\n// Inlets (outer order): first = the frame bang and `dim W 2H` (hot), second = the terrain (cold), third = the vecfield (cold).\n// Unconnected inlets are known from the connected flags (src_terrain, src_field), never from the value (FR-109).\n// Terrain luma (0.2126, 0.7152, 0.0722) times RELIEF; the field is decoded (v - 0.5) * 2 and scaled by push * FIELD_SCALE.\n// RELIEF and FIELD_SCALE are INFERRED starting values, the mirror's (tuned live). Non-finite texels read as 0 (FR-110).\nhgt(xi, yi, W, H, on) {\n  uu = (clamp(xi, 0, W - 1) + 0.5) / W;\n  vv = (clamp(yi, 0, H - 1) + 0.5) / H;\n  rr = nearest(in2, vec(uu, vv)).x;\n  gg = nearest(in2, vec(uu, vv)).y;\n  bb = nearest(in2, vec(uu, vv)).z;\n  rr = switch(abs(rr) < 1e30, rr, 0);\n  gg = switch(abs(gg) < 1e30, gg, 0);\n  bb = switch(abs(bb) < 1e30, bb, 0);\n  return switch(on > 0.5, 6 * (0.2126 * rr + 0.7152 * gg + 0.0722 * bb), 0);\n}\nfdx(xi, yi, W, H, on, fs) {\n  uu = (clamp(xi, 0, W - 1) + 0.5) / W;\n  vv = (clamp(yi, 0, H - 1) + 0.5) / H;\n  ff = nearest(in3, vec(uu, vv)).x;\n  ff = switch(abs(ff) < 1e30, ff, 0.5);\n  return switch(on > 0.5, 2 * fs * (ff - 0.5), 0);\n}\nfdy(xi, yi, W, H, on, fs) {\n  uu = (clamp(xi, 0, W - 1) + 0.5) / W;\n  vv = (clamp(yi, 0, H - 1) + 0.5) / H;\n  ff = nearest(in3, vec(uu, vv)).y;\n  ff = switch(abs(ff) < 1e30, ff, 0.5);\n  return switch(on > 0.5, 2 * fs * (ff - 0.5), 0);\n}\n\nParam flow(0.4);\nParam push(1);\nParam speed(1);\nParam src_terrain(0);\nParam src_field(0);\nParam width(256);\nParam height(256);\n\nW = max(width, 3);\nH = max(height, 3);\npx = floor(norm.x * W);\nyt = floor(norm.y * 2 * H);\nkp = floor(yt / H);\npy = yt - kp * H;\n// RENDER-SIZE SCALING (T083, Matt chose cap-limited; mirror `scales()`): the constants are right at a render height of 1920 (the size Matt looked at).\n// kr = H / 1920; kc = min(kr, 1.25). The field's velocity scales by kc, and `flow` by kr * kc (the terrain slope per texel shrinks by 1 / kr).\nkr = H / 1920;\nkc = min(kr, 1.25);\nfe = flow * kr * kc;\nfs = push * 0.1 * kc;\n\ntc = hgt(px, py, W, H, src_terrain);\ntl = switch(px > 0.5, hgt(px - 1, py, W, H, src_terrain), 2 * tc - hgt(px + 1, py, W, H, src_terrain));\ntr = switch(px < W - 1.5, hgt(px + 1, py, W, H, src_terrain), 2 * tc - hgt(px - 1, py, W, H, src_terrain));\ntu = switch(py > 0.5, hgt(px, py - 1, W, H, src_terrain), 2 * tc - hgt(px, py + 1, W, H, src_terrain));\ntd = switch(py < H - 1.5, hgt(px, py + 1, W, H, src_terrain), 2 * tc - hgt(px, py - 1, W, H, src_terrain));\n\nfxc = fdx(px, py, W, H, src_field, fs);\nfxl = fdx(px - 1, py, W, H, src_field, fs);\nfxr = fdx(px + 1, py, W, H, src_field, fs);\nfyc = fdy(px, py, W, H, src_field, fs);\nfyu = fdy(px, py - 1, W, H, src_field, fs);\nfyd = fdy(px, py + 1, W, H, src_field, fs);\n\nvl = speed * (-fe * (tc - tl) + 0.5 * (fxl + fxc));\nvr = speed * (-fe * (tr - tc) + 0.5 * (fxc + fxr));\nvu = speed * (-fe * (tc - tu) + 0.5 * (fyu + fyc));\nvd = speed * (-fe * (td - tc) + 0.5 * (fyc + fyd));\n\n// terrain gradient (np.gradient: central inside, one-sided at the frame edge)\ngtx = switch(px < 0.5, tr - tc, switch(px > W - 1.5, tc - tl, 0.5 * (tr - tl)));\ngty = switch(py < 0.5, td - tc, switch(py > H - 1.5, tc - tu, 0.5 * (td - tu)));\nc0x = fxc - fe * gtx;\nc0y = fyc - fe * gty;\n\no0 = switch(kp < 0.5, vl, c0x);\no1 = switch(kp < 0.5, vr, c0y);\no2 = switch(kp < 0.5, vu, 0);\no3 = switch(kp < 0.5, vd, 1);\nout1 = vec(o0, o1, o2, o3);\n",
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
						380.0,
						200.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_vferode_prep @adapt 0 @dim 256 512 @type float32",
					"varname": "#0_vferode_prep"
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
									"code": "// codebox_load.gen -- f_vf_erode: the wetting (spec FR-107, plan ADR-2 and ADR-4). W x 2H float32 atlas in and out.\n// Mirror: tests/modules/vf_erode/vf_erode_mirror.load() and pigment_from_picture().\n//\n// On a wetting the picture becomes the pigment on the paper, the suspension is emptied and the frame is flooded (flood is ADDED to\n// the water already there, so a repeat wetting before the wash dries keeps its water and drops the old suspension: the plan's\n// build-time choice, to record). Otherwise the state passes unchanged, and a moving picture at the second inlet does nothing (T074).\n//   Polarity (polar_sw: 0 Darker, 1 Lighter; takes effect at the next wetting, T075): the picture is converted to linear light\n//   (display ^ 2.2, the mirror's GAMMA, INFERRED), then Darker stores the absorbance -log(clamp(lin, 0.001, 1)) and Lighter stores lin.\n// The wetting is the press edge of `wet_gate` (the Wet button holds it open for at least one frame): the load flag in the A channel\n// of plane B stores two bits, 2 * loaded + the gate as last seen, so a held press wets once. 0 = never loaded.\n//   (A texture that was never written reads (0, 0, 0, 1): flag 1 = not loaded, gate seen as 1, harmless.)\n// FEED (Param feed, 0..1): a continuous source, see the end of the code. 0 = wet once; above 0 the flag counts as loaded.\n// Inlets (outer order): first = the state from the hold stage (hot), second = the picture, in0 of the module (cold).\n// Non-finite picture and state texels read as 0 (FR-110).\nParam polar_sw(0);\nParam flood(1);\nParam feed(0);\nParam fade(0.02);\nParam wet_gate(0);\nParam width(256);\nParam height(256);\n\nW = max(width, 3);\nH = max(height, 3);\npx = floor(norm.x * W);\nyt = floor(norm.y * 2 * H);\nkp = floor(yt / H);\npy = yt - kp * H;\nuc = (px + 0.5) / W;\nva = (py + 0.5) / (2 * H);\nvb = (H + py + 0.5) / (2 * H);\nvp = (py + 0.5) / H;\n\nfg = nearest(in1, vec(uc, vb)).w;\nfg = switch(abs(fg) < 1e30, fg, 0);\nfg = clamp(floor(fg + 0.5), 0, 3);\nloaded = step(1.5, fg);\nprevg = fg - 2 * loaded;\ngate = step(0.5, wet_gate);\nwet = gate * (1 - prevg);\nfr = clamp(feed, 0, 1);\nfeedon = step(0.000001, fr);\nnewflag = 2 * max(max(loaded, wet), feedon) + gate;\n\n// the picture as linear light, then as pigment\nrr = nearest(in2, vec(uc, vp)).x;\ngg = nearest(in2, vec(uc, vp)).y;\nbb = nearest(in2, vec(uc, vp)).z;\nrr = switch(abs(rr) < 1e30, rr, 0);\ngg = switch(abs(gg) < 1e30, gg, 0);\nbb = switch(abs(bb) < 1e30, bb, 0);\nlr = pow(max(rr, 0), 2.2);\nlg = pow(max(gg, 0), 2.2);\nlb = pow(max(bb, 0), 2.2);\npr = switch(polar_sw < 0.5, -log(clamp(lr, 0.001, 1)), lr);\npg = switch(polar_sw < 0.5, -log(clamp(lg, 0.001, 1)), lg);\npb = switch(polar_sw < 0.5, -log(clamp(lb, 0.001, 1)), lb);\n\n// the held state\nwc = nearest(in1, vec(uc, va)).x;\nsr = nearest(in1, vec(uc, va)).y;\nsg = nearest(in1, vec(uc, va)).z;\nsb = nearest(in1, vec(uc, va)).w;\nqr = nearest(in1, vec(uc, vb)).x;\nqg = nearest(in1, vec(uc, vb)).y;\nqb = nearest(in1, vec(uc, vb)).z;\nwc = switch(abs(wc) < 1e30, wc, 0);\nsr = switch(abs(sr) < 1e30, sr, 0);\nsg = switch(abs(sg) < 1e30, sg, 0);\nsb = switch(abs(sb) < 1e30, sb, 0);\nqr = switch(abs(qr) < 1e30, qr, 0);\nqg = switch(abs(qg) < 1e30, qg, 0);\nqb = switch(abs(qb) < 1e30, qb, 0);\n\n// A state that was never loaded is not a state: a texture nothing has written reads (0, 0, 0, 1), so its suspension in the A channel of\n// plane A would be 1 (found by the module bench, 2026-11-10, with Feed and no press: a blue cast that stayed). Not loaded = no pigment.\nsr = sr * loaded;\nsg = sg * loaded;\nsb = sb * loaded;\nqr = qr * loaded;\nqg = qg * loaded;\nqb = qb * loaded;\na0 = switch(wet > 0.5, wc + flood, wc);\na1 = switch(wet > 0.5, 0, sr);\na2 = switch(wet > 0.5, 0, sg);\na3 = switch(wet > 0.5, 0, sb);\nb0 = switch(wet > 0.5, pr, qr);\nb1 = switch(wet > 0.5, pg, qg);\nb2 = switch(wet > 0.5, pb, qb);\n// FEED (US5, FR-115): after the wetting test, deposit the fraction `feed` of the shortfall between the picture's pigment and the paper's,\n// and relax the water toward `flood`. feed 0 changes nothing (fr * anything = 0), so the module is wet-once exactly.\n// Mirror: vf_erode_mirror.feed().\n// FADE: the excess, paper pigment above the picture's, returns toward the picture at `fade`, only while feeding (so a picture that gets\n// lighter is followed and the frame cannot saturate). Mirror: the `fade` term of vf_erode_mirror.feed().\nfd = clamp(fade, 0, 1) * feedon;\nb0 = b0 + fr * max(pr - b0, 0) - fd * max(b0 - pr, 0);\nb1 = b1 + fr * max(pg - b1, 0) - fd * max(b1 - pg, 0);\nb2 = b2 + fr * max(pb - b2, 0) - fd * max(b2 - pb, 0);\na0 = a0 + fr * max(flood - a0, 0);\nout1 = vec(switch(kp < 0.5, a0, b0), switch(kp < 0.5, a1, b1), switch(kp < 0.5, a2, b2), switch(kp < 0.5, a3, newflag));\n",
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
						430.0,
						200.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_vferode_load @adapt 0 @dim 256 512 @type float32",
					"varname": "#0_vferode_load"
				}
			},
			{
				"box": {
					"id": "obj-55",
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
									"code": "// codebox_transport.gen -- f_vf_erode: water and the suspended pigment move through the cell faces (plan ADR-3), then the water dries.\n// W x 2H float32 atlas in and out. Mirror: tests/modules/vf_erode/vf_erode_mirror.step(), the water, flux and dry parts.\n//\n// GATHER form: each cell computes the four faces it shares (left, right, up, down) from the same operands as its neighbour does, so\n// what leaves one cell arrives in the next. Per face between A (left/up) and B (right/down):\n//   v  = clamp(prep - speed * flow * (w_B - w_A), -vmax, vmax)      prep = the static velocity from codebox_prep.gen\n//   q  = v * min(w_up, wlim) * clamp(w_up / film, 0, 1)             w_up = the depth of the donor cell (A when v > 0, else B)\n//   sf = c_donor * q + mixk * min(min(w_A, w_B), 1) * (c_A - c_B)   per channel; c = s / max(w, 0.001); never mixed between channels\n// w_new = w + q_left - q_right + q_up - q_down, then w = max(w - dry * speed, 0) (a dried wash is exactly still, FR-106); s likewise.\n// FRAME EDGE (T066): for the slope term the cell beyond the frame has the edge cell's own depth (clamped read), as a DONOR it has\n// depth 0 and no pigment (so nothing comes back in, and no diffusion across the edge). wlim 0.5, film 0.15, mixk 0.04 and vmax 0.2\n// are the mirror's constants, chosen so no cell can give away more than it holds (SC-105); INFERRED, tuned live.\n// Plane B (the paper pigment and the load flag) passes unchanged. Inlets (outer order): first = the state from the load stage\n// (hot), second = the static velocities from the prep stage (cold). Non-finite state texels read as 0 (FR-110).\nvel(vs, wa, wb, kk, vmax) {\n  return clamp(vs - kk * (wb - wa), -vmax, vmax);\n}\nfq(v, wad, wbd, wlim, film) {\n  wup = switch(v > 0, wad, wbd);\n  return v * min(wup, wlim) * clamp(wup / film, 0, 1);\n}\nsfc(v, q, wad, wbd, sa, sb, mixk) {\n  ca = sa / max(wad, 0.001);\n  cb = sb / max(wbd, 0.001);\n  cd = switch(v > 0, ca, cb);\n  return cd * q + mixk * min(min(wad, wbd), 1) * (ca - cb);\n}\nrw(uu, vv) {\n  x = nearest(in1, vec(uu, vv)).x;\n  return switch(abs(x) < 1e30, max(x, 0), 0);\n}\nrsr(uu, vv, ok) {\n  x = nearest(in1, vec(uu, vv)).y;\n  return switch(ok > 0.5 && abs(x) < 1e30, x, 0);\n}\nrsg(uu, vv, ok) {\n  x = nearest(in1, vec(uu, vv)).z;\n  return switch(ok > 0.5 && abs(x) < 1e30, x, 0);\n}\nrsb(uu, vv, ok) {\n  x = nearest(in1, vec(uu, vv)).w;\n  return switch(ok > 0.5 && abs(x) < 1e30, x, 0);\n}\n\nParam flow(0.4);\nParam speed(1);\nParam dry(0.0016);\nParam width(256);\nParam height(256);\n\nW = max(width, 3);\nH = max(height, 3);\n// RENDER-SIZE SCALING (T083; mirror `scales()`): the constants below are right at a render height of 1920. kr = H / 1920, kc = min(kr, 1.25):\n// the velocity cap scales by kc, the slope coefficient by kr * kc, diffusion by kc * kc. Above the cap everything runs slower, never faster.\nkr = H / 1920;\nkc = min(kr, 1.25);\nwlim = 0.5;\nfilm = 0.15;\nmixk = 0.04 * kc * kc;\nvmax = 0.2 * kc;\nkk = speed * flow * kr * kc;\n\npx = floor(norm.x * W);\nyt = floor(norm.y * 2 * H);\nkp = floor(yt / H);\npy = yt - kp * H;\nuc = (px + 0.5) / W;\nul = (max(px - 1, 0) + 0.5) / W;\nur = (min(px + 1, W - 1) + 0.5) / W;\nva = (py + 0.5) / (2 * H);\nvu = (max(py - 1, 0) + 0.5) / (2 * H);\nvd = (min(py + 1, H - 1) + 0.5) / (2 * H);\nvb = (H + py + 0.5) / (2 * H);\nokl = step(0.5, px);\nokr = step(px, W - 1.5);\noku = step(0.5, py);\nokd = step(py, H - 1.5);\n\n// depths: the clamped read (the edge cell's own value) for the slope, and the donor depth, 0 beyond the frame\nwc = rw(uc, va);\nwl = rw(ul, va);\nwr = rw(ur, va);\nwu = rw(uc, vu);\nwd = rw(uc, vd);\nwld = wl * okl;\nwrd = wr * okr;\nwud = wu * oku;\nwdd = wd * okd;\n\n// the static velocities of this cell's four faces\npl = nearest(in2, vec(uc, va)).x;\npr = nearest(in2, vec(uc, va)).y;\npu = nearest(in2, vec(uc, va)).z;\npd = nearest(in2, vec(uc, va)).w;\nvlf = vel(pl, wl, wc, kk, vmax);\nvrf = vel(pr, wc, wr, kk, vmax);\nvuf = vel(pu, wu, wc, kk, vmax);\nvdf = vel(pd, wc, wd, kk, vmax);\n\nql = fq(vlf, wld, wc, wlim, film);\nqr = fq(vrf, wc, wrd, wlim, film);\nqu = fq(vuf, wud, wc, wlim, film);\nqd = fq(vdf, wc, wdd, wlim, film);\nwn = max(wc + ql - qr + qu - qd - dry * speed, 0);\n\n// pigment in suspension, per channel (a virtual cell beyond the frame holds none)\nrc = rsr(uc, va, 1);\nrl = rsr(ul, va, okl);\nrr = rsr(ur, va, okr);\nru = rsr(uc, vu, oku);\nrd = rsr(uc, vd, okd);\ngc = rsg(uc, va, 1);\ngl = rsg(ul, va, okl);\ngr = rsg(ur, va, okr);\ngu = rsg(uc, vu, oku);\ngd = rsg(uc, vd, okd);\nbc = rsb(uc, va, 1);\nbl = rsb(ul, va, okl);\nbr = rsb(ur, va, okr);\nbu = rsb(uc, vu, oku);\nbd = rsb(uc, vd, okd);\nrn = rc + sfc(vlf, ql, wld, wc, rl, rc, mixk) - sfc(vrf, qr, wc, wrd, rc, rr, mixk) + sfc(vuf, qu, wud, wc, ru, rc, mixk) - sfc(vdf, qd, wc, wdd, rc, rd, mixk);\ngn = gc + sfc(vlf, ql, wld, wc, gl, gc, mixk) - sfc(vrf, qr, wc, wrd, gc, gr, mixk) + sfc(vuf, qu, wud, wc, gu, gc, mixk) - sfc(vdf, qd, wc, wdd, gc, gd, mixk);\nbn = bc + sfc(vlf, ql, wld, wc, bl, bc, mixk) - sfc(vrf, qr, wc, wrd, bc, br, mixk) + sfc(vuf, qu, wud, wc, bu, bc, mixk) - sfc(vdf, qd, wc, wdd, bc, bd, mixk);\n\n// plane B passes\nq0 = nearest(in1, vec(uc, vb)).x;\nq1 = nearest(in1, vec(uc, vb)).y;\nq2 = nearest(in1, vec(uc, vb)).z;\nq3 = nearest(in1, vec(uc, vb)).w;\nout1 = vec(switch(kp < 0.5, wn, q0), switch(kp < 0.5, rn, q1), switch(kp < 0.5, gn, q2), switch(kp < 0.5, bn, q3));\n",
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
						480.0,
						240.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_vferode_transport @adapt 0 @dim 256 512 @type float32",
					"varname": "#0_vferode_transport"
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
									"code": "// codebox_react.gen -- f_vf_erode: pigment is lifted off the paper by running water and dropped by slow or shallow water (plan ADR-3).\n// W x 2H float32 atlas in and out. Mirror: tests/modules/vf_erode/vf_erode_mirror.step(), the lift and settle part.\n//\n// Cell-local. The drive is the speed of the water measured from its current surface: (cx, cy) = the prep stage's static part\n// minus flow * the gradient of the water depth (np.gradient: central inside, one-sided at the frame edge), and\n//   spd    = min(sqrt(cx^2 + cy^2) * speed, vmax) * clamp(w / film, 0, 1)\n//   lift   = p * clamp(lift * spd * min(w, 1), 0, 0.5)              paper -> suspension\n//   drop   = s * clamp(max(settlee * speed * clamp(1 - spd / sp0, 0, 1), clamp(1 - w / 0.08, 0, 1)), 0, 1)     suspension -> paper\n// so fast water takes pigment and slow or shallow water puts it down, and all of it where the water is gone. film 0.15, vmax 0.2,\n// sp0 0.1 and the 0.08 are the mirror's constants; the speed measure and these forms are INFERRED, checked only by the bowl and\n// field tests (direction), and by Matt's live look (does it read as ink).\n// This is the last stage of the loop: it writes the state atlas back to the hold stage, so it also sanitizes it (non-finite and\n// negative water, pigment and suspension read as 0). The load flag passes unchanged.\n// Inlets (outer order): first = the state from the transport stage (hot), second = the prep stage's atlas (cold).\nParam flow(0.4);\nParam speed(1);\nParam lift(0.7);\nParam settle(0.19);\nParam width(256);\nParam height(256);\n\nW = max(width, 3);\nH = max(height, 3);\n// RENDER-SIZE SCALING (T083; mirror `scales()`): constants right at a render height of 1920; kr = H / 1920, kc = min(kr, 1.25). The velocity cap and the\n// settle threshold scale by kc, `flow` by kr * kc, and the lift uses the speed in 1920-height texels (spd / kc) so its rate per step does not depend on the size.\nkr = H / 1920;\nkc = min(kr, 1.25);\nfilm = 0.15;\nvmax = 0.2 * kc;\nsp0 = 0.1 * kc;\n// The dials are curves (2026-11-10, Matt: some dials were too subtle; mirror lift_from_dial() and settle_from_dial()): Lift 0..1 maps to\n// 0.9 * (d / 0.7) ^ 2 (0.9 at the default 0.7, the old default), Settle 0..1 to 0.6 * d ^ 3 (0.004 at the default 0.19, the old default).\nlifte = 0.9 * (lift / 0.7) * (lift / 0.7);\nsettlee = 0.6 * settle * settle * settle;\n\npx = floor(norm.x * W);\nyt = floor(norm.y * 2 * H);\nkp = floor(yt / H);\npy = yt - kp * H;\nuc = (px + 0.5) / W;\nul = (max(px - 1, 0) + 0.5) / W;\nur = (min(px + 1, W - 1) + 0.5) / W;\nva = (py + 0.5) / (2 * H);\nvu = (max(py - 1, 0) + 0.5) / (2 * H);\nvd = (min(py + 1, H - 1) + 0.5) / (2 * H);\nvb = (H + py + 0.5) / (2 * H);\n\nwc = nearest(in1, vec(uc, va)).x;\nwl = nearest(in1, vec(ul, va)).x;\nwr = nearest(in1, vec(ur, va)).x;\nwu = nearest(in1, vec(uc, vu)).x;\nwd = nearest(in1, vec(uc, vd)).x;\nwc = switch(abs(wc) < 1e30, max(wc, 0), 0);\nwl = switch(abs(wl) < 1e30, max(wl, 0), 0);\nwr = switch(abs(wr) < 1e30, max(wr, 0), 0);\nwu = switch(abs(wu) < 1e30, max(wu, 0), 0);\nwd = switch(abs(wd) < 1e30, max(wd, 0), 0);\n\ngwx = switch(px < 0.5, wr - wc, switch(px > W - 1.5, wc - wl, 0.5 * (wr - wl)));\ngwy = switch(py < 0.5, wd - wc, switch(py > H - 1.5, wc - wu, 0.5 * (wd - wu)));\ncx = nearest(in2, vec(uc, vb)).x - flow * kr * kc * gwx;\ncy = nearest(in2, vec(uc, vb)).y - flow * kr * kc * gwy;\nspd = min(sqrt(cx * cx + cy * cy) * speed, vmax) * clamp(wc / film, 0, 1);\nkl = clamp(lifte * (spd / kc) * min(wc, 1), 0, 0.5);\nkd = clamp(max(settlee * speed * clamp(1 - spd / sp0, 0, 1), clamp(1 - wc / 0.08, 0, 1)), 0, 1);\n\npr = nearest(in1, vec(uc, vb)).x;\npg = nearest(in1, vec(uc, vb)).y;\npb = nearest(in1, vec(uc, vb)).z;\nfl = nearest(in1, vec(uc, vb)).w;\nsr = nearest(in1, vec(uc, va)).y;\nsg = nearest(in1, vec(uc, va)).z;\nsb = nearest(in1, vec(uc, va)).w;\npr = switch(abs(pr) < 1e30, max(pr, 0), 0);\npg = switch(abs(pg) < 1e30, max(pg, 0), 0);\npb = switch(abs(pb) < 1e30, max(pb, 0), 0);\nfl = switch(abs(fl) < 1e30, fl, 0);\nsr = switch(abs(sr) < 1e30, max(sr, 0), 0);\nsg = switch(abs(sg) < 1e30, max(sg, 0), 0);\nsb = switch(abs(sb) < 1e30, max(sb, 0), 0);\n\n// lift, then drop (the drop takes the suspension that includes what was just lifted)\ntr = sr + pr * kl;\ntg = sg + pg * kl;\ntb = sb + pb * kl;\nur_ = pr - pr * kl;\nug = pg - pg * kl;\nub = pb - pb * kl;\nnsr = tr - tr * kd;\nnsg = tg - tg * kd;\nnsb = tb - tb * kd;\nnpr = ur_ + tr * kd;\nnpg = ug + tg * kd;\nnpb = ub + tb * kd;\n\nout1 = vec(switch(kp < 0.5, wc, npr), switch(kp < 0.5, nsr, npg), switch(kp < 0.5, nsg, npb), switch(kp < 0.5, nsb, fl));\n",
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
						530.0,
						208.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_vferode_react @adapt 0 @dim 256 512 @type float32",
					"varname": "#0_vferode_react"
				}
			},
			{
				"box": {
					"id": "obj-5",
					"maxclass": "newobj",
					"numinlets": 4,
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
									"code": "// codebox_enc.gen -- f_vf_erode: the composite and the thickness at the render size, with the bypass gate (plan ADR-4, ADR-5, ADR-6).\n// Mirror: tests/modules/vf_erode/vf_erode_mirror.enc().\n//\n//   Darker:  linear = background * exp(-(p + s)), the background white when inlet 3 is unconnected\n//   Lighter: linear = background + p + s, the background black when unconnected (T075); then display = linear ^ (1 / 2.2)\n//   outlet 1: that composite, alpha from the picture. outlet 2: the thickness, the luma of the pigment ON THE PAPER (absorbance\n//   under Darker, light under Lighter); no water outlet (T069).\n//   BEFORE THE FIRST WETTING (the load flag in plane B's A channel is below 2, T076) the picture is shown as if loaded, so an\n//   unwetted module returns its input (US3.4); after the first wetting the picture no longer reaches the layers (T074).\n//   bypass_gate = 1 passes the picture (zapped) on both outlets; the loop keeps running underneath (FR-113). The Param is never named bypass.\n// The atlas is the render size, so it is read by normalized coordinates: plane A at v = norm.y / 2, plane B at 0.5 + norm.y / 2.\n// Inlets (outer order): first = the frame bang and `dim W H` (hot), second = the state atlas from the react stage, third = the picture\n// (in0 of the module), fourth = the background (in3 of the module, flag src_bg). Non-finite texels read as 0 (FR-110).\nlin(x) {\n  y = switch(abs(x) < 1e30, x, 0);\n  return pow(max(y, 0), 2.2);\n}\nParam polar_sw(0);\nParam src_bg(0);\nParam bypass_gate(0);\n\nva = norm.y * 0.5;\nvb = 0.5 + norm.y * 0.5;\nloaded = step(1.5, nearest(in2, vec(norm.x, vb)).w);\n\npic_r = nearest(in3, norm).x;\npic_g = nearest(in3, norm).y;\npic_b = nearest(in3, norm).z;\npic_a = nearest(in3, norm).w;\npic_r = switch(abs(pic_r) < 1e30, pic_r, 0);\npic_g = switch(abs(pic_g) < 1e30, pic_g, 0);\npic_b = switch(abs(pic_b) < 1e30, pic_b, 0);\npic_a = switch(abs(pic_a) < 1e30, pic_a, 0);\n\n// pigment on the paper: the state's, or the picture's before the first wetting\ndk = step(polar_sw, 0.5);\nmr = switch(dk > 0.5, -log(clamp(lin(pic_r), 0.001, 1)), lin(pic_r));\nmg = switch(dk > 0.5, -log(clamp(lin(pic_g), 0.001, 1)), lin(pic_g));\nmb = switch(dk > 0.5, -log(clamp(lin(pic_b), 0.001, 1)), lin(pic_b));\npr = switch(loaded > 0.5, nearest(in2, vec(norm.x, vb)).x, mr);\npg = switch(loaded > 0.5, nearest(in2, vec(norm.x, vb)).y, mg);\npb = switch(loaded > 0.5, nearest(in2, vec(norm.x, vb)).z, mb);\npr = switch(abs(pr) < 1e30, max(pr, 0), 0);\npg = switch(abs(pg) < 1e30, max(pg, 0), 0);\npb = switch(abs(pb) < 1e30, max(pb, 0), 0);\nsr = switch(loaded > 0.5, nearest(in2, vec(norm.x, va)).y, 0);\nsg = switch(loaded > 0.5, nearest(in2, vec(norm.x, va)).z, 0);\nsb = switch(loaded > 0.5, nearest(in2, vec(norm.x, va)).w, 0);\nsr = switch(abs(sr) < 1e30, max(sr, 0), 0);\nsg = switch(abs(sg) < 1e30, max(sg, 0), 0);\nsb = switch(abs(sb) < 1e30, max(sb, 0), 0);\n\n// NOTE: exp(-(a + b)) compiled as exp(-a + b) (bench, 2026-11-10: the GPU composite fitted p - s on three channels), so the sum is written exp(-a - b).\n// background: white (Darker) or black (Lighter) when unconnected\nbr = switch(src_bg > 0.5, lin(nearest(in4, norm).x), dk);\nbg = switch(src_bg > 0.5, lin(nearest(in4, norm).y), dk);\nbb = switch(src_bg > 0.5, lin(nearest(in4, norm).z), dk);\ncr = switch(dk > 0.5, br * exp(-pr - sr), br + pr + sr);\ncg = switch(dk > 0.5, bg * exp(-pg - sg), bg + pg + sg);\ncb = switch(dk > 0.5, bb * exp(-pb - sb), bb + pb + sb);\ndr = pow(max(switch(abs(cr) < 1e30, cr, 0), 0), 1 / 2.2);\ndg = pow(max(switch(abs(cg) < 1e30, cg, 0), 0), 1 / 2.2);\ndb = pow(max(switch(abs(cb) < 1e30, cb, 0), 0), 1 / 2.2);\nth = 0.2126 * pr + 0.7152 * pg + 0.0722 * pb;\n\nout1 = vec(mix(dr, pic_r, bypass_gate), mix(dg, pic_g, bypass_gate), mix(db, pic_b, bypass_gate), pic_a);\nout2 = vec(mix(th, pic_r, bypass_gate), mix(th, pic_g, bypass_gate), mix(th, pic_b, bypass_gate), pic_a);\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
									"id": "gen-obj-2",
									"maxclass": "codebox",
									"numinlets": 4,
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
							}
						]
					},
					"patching_rect": [
						30.0,
						580.0,
						200.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_vferode_enc @adapt 0 @dim 256 256 @type float32",
					"varname": "#0_vferode_enc"
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
					"varname": "vferode_autopattr"
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
						150.0
					],
					"presentation": 1,
					"presentation_rect": [
						0.0,
						0.0,
						190.0,
						150.0
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
						40.0,
						21.0
					],
					"text": "Erode"
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
					"id": "obj-20a",
					"maxclass": "newobj",
					"numinlets": 0,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						130.0,
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
					"comment": "terrain (luma = height; water runs downhill)",
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
					"id": "obj-103",
					"maxclass": "inlet",
					"comment": "vecfield (pushes the water)",
					"index": 0,
					"numinlets": 0,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						430.0,
						20.0,
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
						430.0,
						70.0,
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
					"comment": "background (the paper the pigment sits on)",
					"index": 0,
					"numinlets": 0,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						600.0,
						20.0,
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
						600.0,
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
					"text": "prepend param src_terrain"
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
						430.0,
						120.0,
						160.0,
						22.0
					],
					"text": "prepend param src_field"
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
						600.0,
						120.0,
						160.0,
						22.0
					],
					"text": "prepend param src_bg"
				}
			},
			{
				"box": {
					"id": "obj-20",
					"maxclass": "live.text",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"hint": "Darker: the pigment filters the background, white when inlet 3 is unconnected. Lighter: it adds to a black background. A change takes effect at the next wetting",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"param_connect": "#0_vferode_load::polar_sw",
					"parameter_enable": 1,
					"patching_rect": [
						33.0,
						250.0,
						53.5,
						17.0
					],
					"presentation": 1,
					"presentation_rect": [
						50.0,
						3.0,
						52.0,
						15.0
					],
					"text": "Darker",
					"texton": "Lighter",
					"saved_attribute_attributes": {
						"activebgcolor": {
							"expression": ""
						},
						"activebgoncolor": {
							"expression": ""
						},
						"activetextcolor": {
							"expression": ""
						},
						"activetextoncolor": {
							"expression": ""
						},
						"bgoncolor": {
							"expression": ""
						},
						"valueof": {
							"parameter_enum": [
								"Darker",
								"Lighter"
							],
							"parameter_initial": [
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "polar_sw",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 0,
							"parameter_shortname": "polar_sw",
							"parameter_type": 1,
							"parameter_unitstyle": 0
						}
					},
					"varname": "polar_sw"
				}
			},
			{
				"box": {
					"id": "obj-21",
					"maxclass": "attrui",
					"attr": "polar_sw",
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
					"attr": "polar_sw",
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
					"id": "obj-23",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "How strongly the water runs downhill on the terrain (inlet 1). PROVISIONAL",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_vferode_prep::flow",
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
								0.4
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "flow",
							"parameter_mmax": 2.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "flow",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "flow"
				}
			},
			{
				"box": {
					"id": "obj-24",
					"maxclass": "attrui",
					"attr": "flow",
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
					"id": "obj-701",
					"maxclass": "attrui",
					"attr": "flow",
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
					"id": "obj-702",
					"maxclass": "attrui",
					"attr": "flow",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						98.0,
						368.0,
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
					"text": "Flow",
					"textjustification": 1,
					"varname": "lbl_flow"
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
					"hint": "How strongly the vecfield (inlet 2) moves the water. 0 is the same as no vecfield. PROVISIONAL",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_vferode_prep::push",
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
							"parameter_longname": "push",
							"parameter_mmax": 4.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "push",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "push"
				}
			},
			{
				"box": {
					"id": "obj-27",
					"maxclass": "attrui",
					"attr": "push",
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
					"text": "Push",
					"textjustification": 1,
					"varname": "lbl_push"
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
					"hint": "How readily running water takes pigment off the paper. A curve: the bottom half is gentle, the top lifts almost everything at once. PROVISIONAL",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_vferode_react::lift",
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
								0.7
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "lift",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "lift",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "lift"
				}
			},
			{
				"box": {
					"id": "obj-30",
					"maxclass": "attrui",
					"attr": "lift",
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
					"text": "Lift",
					"textjustification": 1,
					"varname": "lbl_lift"
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
					"hint": "How readily slow water puts pigment back down; higher drops it sooner, so less is carried far. A cubic curve. Water that has gone puts all of it down regardless. PROVISIONAL",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_vferode_react::settle",
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
								0.19
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "settle",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "settle",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "settle"
				}
			},
			{
				"box": {
					"id": "obj-33",
					"maxclass": "attrui",
					"attr": "settle",
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
					"text": "Settle",
					"textjustification": 1,
					"varname": "lbl_settle"
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
					"hint": "How fast the water goes, per step. A dried wash is still. PROVISIONAL",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_vferode_transport::dry",
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
								0.0016
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "dry",
							"parameter_mmax": 0.02,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "dry",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "dry"
				}
			},
			{
				"box": {
					"id": "obj-36",
					"maxclass": "attrui",
					"attr": "dry",
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
					"text": "Dry",
					"textjustification": 1,
					"varname": "lbl_dry"
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
					"hint": "Step size of each solver step; limited inside the solver so the water stays stable. PROVISIONAL",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_vferode_prep::speed",
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
								1.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "speed",
							"parameter_mmax": 4.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "speed",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "speed"
				}
			},
			{
				"box": {
					"id": "obj-39",
					"maxclass": "attrui",
					"attr": "speed",
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
					"id": "obj-703",
					"maxclass": "attrui",
					"attr": "speed",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						458.0,
						344.0,
						68.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-704",
					"maxclass": "attrui",
					"attr": "speed",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						458.0,
						368.0,
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
					"text": "Speed",
					"textjustification": 1,
					"varname": "lbl_speed"
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
					"hint": "How much water a wetting adds. It is added to any water still on the paper. PROVISIONAL",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_vferode_load::flood",
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
								1.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "flood",
							"parameter_mmax": 4.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "flood",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "flood"
				}
			},
			{
				"box": {
					"id": "obj-42",
					"maxclass": "attrui",
					"attr": "flood",
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
					"text": "Flood",
					"textjustification": 1,
					"varname": "lbl_flood"
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
					"hint": "A continuous source for an animated or live picture: each step a fraction of what the picture holds beyond the paper is deposited, and the water relaxes toward Flood. 0 is wet once. A still picture on a flat frame converges to itself. PROVISIONAL",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_vferode_load::feed",
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
							"parameter_longname": "feed",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "feed",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "feed"
				}
			},
			{
				"box": {
					"id": "obj-45",
					"maxclass": "attrui",
					"attr": "feed",
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
					"text": "Feed",
					"textjustification": 1,
					"varname": "lbl_feed"
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
					"hint": "With Feed above 0: how fast ink above what the picture holds returns to the picture, so a picture that gets lighter is followed and the frame does not go black. Small = pooled ink lasts about 1 / Fade frames. 0 = it never fades. PROVISIONAL",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_vferode_load::fade",
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
								0.02
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "fade",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "fade",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "fade"
				}
			},
			{
				"box": {
					"id": "obj-48",
					"maxclass": "attrui",
					"attr": "fade",
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
					"text": "Fade",
					"textjustification": 1,
					"varname": "lbl_fade"
				}
			},
			{
				"box": {
					"id": "obj-50",
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
					"id": "obj-51",
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
						480.0,
						742.0,
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
						620.0,
						742.0,
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
						620.0,
						772.0,
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
						530.0,
						742.0,
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
						530.0,
						772.0,
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
						480.0,
						802.0,
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
						610.0,
						802.0,
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
			},
			{
				"box": {
					"id": "obj-rd-20",
					"maxclass": "newobj",
					"patching_rect": [
						830.0,
						922.0,
						80.0,
						22.0
					],
					"text": "expr $i1*2",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					]
				}
			},
			{
				"box": {
					"id": "obj-rd-21",
					"maxclass": "newobj",
					"patching_rect": [
						830.0,
						952.0,
						60.0,
						22.0
					],
					"text": "pack 0 0",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					]
				}
			},
			{
				"box": {
					"id": "obj-rd-22",
					"maxclass": "newobj",
					"patching_rect": [
						830.0,
						982.0,
						80.0,
						22.0
					],
					"text": "prepend dim",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					]
				}
			},
			{
				"box": {
					"id": "obj-gate-wet-face",
					"maxclass": "panel",
					"patching_rect": [
						30.0,
						742.0,
						24.0,
						24.0
					],
					"numinlets": 1,
					"numoutlets": 0,
					"background": 1,
					"ignoreclick": 1,
					"border": 2,
					"bordercolor": [
						0.55,
						0.55,
						0.55,
						1.0
					],
					"bgcolor": [
						0.2,
						0.2,
						0.2,
						1.0
					],
					"rounded": 14,
					"presentation": 1,
					"presentation_rect": [
						3.5,
						46.0,
						28.0,
						28.0
					],
					"varname": "wet_face"
				}
			},
			{
				"box": {
					"id": "obj-gate-wet-button",
					"maxclass": "ubutton",
					"patching_rect": [
						30.0,
						742.0,
						24.0,
						24.0
					],
					"numinlets": 1,
					"numoutlets": 4,
					"outlettype": [
						"bang",
						"bang",
						"",
						"int"
					],
					"hltcolor": [
						1.0,
						1.0,
						1.0,
						0.45
					],
					"presentation": 1,
					"presentation_rect": [
						3.5,
						46.0,
						28.0,
						28.0
					],
					"varname": "wet_button",
					"hint": "Wet once: the picture on inlet 0 becomes the pigment on the paper and the frame is flooded. Holding does not wet again"
				}
			},
			{
				"box": {
					"id": "obj-gate-wet-label",
					"maxclass": "comment",
					"patching_rect": [
						30.0,
						768.0,
						50.0,
						18.0
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"presentation": 1,
					"presentation_rect": [
						-7.5,
						20.0,
						50.0,
						18.0
					],
					"text": "Wet",
					"textjustification": 1,
					"varname": "lbl_wet"
				}
			},
			{
				"box": {
					"id": "obj-gate-wet-sel",
					"maxclass": "newobj",
					"patching_rect": [
						30.0,
						972.0,
						90.0,
						22.0
					],
					"text": "sel bang 1 0",
					"numinlets": 1,
					"numoutlets": 4,
					"outlettype": [
						"bang",
						"bang",
						"bang",
						""
					]
				}
			},
			{
				"box": {
					"id": "obj-gate-wet-tap",
					"maxclass": "newobj",
					"patching_rect": [
						30.0,
						1007.0,
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
					"id": "obj-gate-wet-press",
					"maxclass": "newobj",
					"patching_rect": [
						90.0,
						1042.0,
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
					"id": "obj-gate-wet-release",
					"maxclass": "message",
					"patching_rect": [
						30.0,
						1077.0,
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
					"id": "obj-gate-wet-on",
					"maxclass": "message",
					"patching_rect": [
						90.0,
						1077.0,
						120.0,
						22.0
					],
					"text": "param wet_gate 1",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					]
				}
			},
			{
				"box": {
					"id": "obj-gate-wet-arm",
					"maxclass": "message",
					"patching_rect": [
						230.0,
						1077.0,
						36.0,
						22.0
					],
					"text": "100",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					]
				}
			},
			{
				"box": {
					"id": "obj-gate-wet-count",
					"maxclass": "newobj",
					"patching_rect": [
						300.0,
						972.0,
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
					"id": "obj-gate-wet-add",
					"maxclass": "newobj",
					"patching_rect": [
						340.0,
						1002.0,
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
					"id": "obj-gate-wet-match",
					"maxclass": "newobj",
					"patching_rect": [
						300.0,
						1032.0,
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
					"id": "obj-gate-wet-off",
					"maxclass": "message",
					"patching_rect": [
						300.0,
						1062.0,
						120.0,
						22.0
					],
					"text": "param wet_gate 0",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					]
				}
			},
			{
				"box": {
					"id": "obj-gate-wet-draw",
					"maxclass": "newobj",
					"patching_rect": [
						300.0,
						942.0,
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
					"id": "obj-gate-wet-load",
					"maxclass": "newobj",
					"patching_rect": [
						230.0,
						1047.0,
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
						"obj-54",
						1
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
						2
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
						"obj-20a",
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
						"obj-53",
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
						"obj-53",
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
						"obj-53",
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
						"obj-53",
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
						"obj-52",
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
						"obj-52",
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
						"obj-55",
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
						"obj-56",
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
						"obj-54",
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
						"obj-56",
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
						"obj-55",
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
						"obj-53",
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
						"obj-54",
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
						"obj-55",
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
						"obj-56",
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
						"obj-703",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-703",
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
						"obj-38",
						0
					],
					"destination": [
						"obj-704",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-704",
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
						"obj-53",
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
						"obj-54",
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
						"obj-rd-4",
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
						"obj-rd-4",
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
						"obj-rd-2",
						1
					],
					"destination": [
						"obj-rd-20",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-rd-20",
						0
					],
					"destination": [
						"obj-rd-21",
						1
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
						"obj-rd-21",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-rd-21",
						0
					],
					"destination": [
						"obj-rd-22",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-rd-22",
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
						"obj-rd-22",
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
						"obj-rd-22",
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
						"obj-rd-22",
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
						"obj-rd-22",
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
						10
					],
					"destination": [
						"obj-gate-wet-sel",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-gate-wet-button",
						1
					],
					"destination": [
						"obj-gate-wet-press",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-gate-wet-button",
						0
					],
					"destination": [
						"obj-gate-wet-release",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-gate-wet-sel",
						0
					],
					"destination": [
						"obj-gate-wet-tap",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-gate-wet-sel",
						1
					],
					"destination": [
						"obj-gate-wet-press",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-gate-wet-sel",
						2
					],
					"destination": [
						"obj-gate-wet-release",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-gate-wet-tap",
						1
					],
					"destination": [
						"obj-gate-wet-press",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-gate-wet-tap",
						0
					],
					"destination": [
						"obj-gate-wet-release",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-gate-wet-press",
						1
					],
					"destination": [
						"obj-gate-wet-arm",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-gate-wet-arm",
						0
					],
					"destination": [
						"obj-gate-wet-count",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-gate-wet-press",
						0
					],
					"destination": [
						"obj-gate-wet-on",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-gate-wet-release",
						0
					],
					"destination": [
						"obj-gate-wet-count",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-gate-wet-draw",
						0
					],
					"destination": [
						"obj-gate-wet-count",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-gate-wet-count",
						0
					],
					"destination": [
						"obj-gate-wet-add",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-gate-wet-add",
						0
					],
					"destination": [
						"obj-gate-wet-count",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-gate-wet-count",
						0
					],
					"destination": [
						"obj-gate-wet-match",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-gate-wet-match",
						0
					],
					"destination": [
						"obj-gate-wet-off",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-gate-wet-load",
						0
					],
					"destination": [
						"obj-gate-wet-arm",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-gate-wet-on",
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
						"obj-gate-wet-off",
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
				"polar_sw",
				"polar_sw",
				0
			],
			"obj-23": [
				"flow",
				"flow",
				0
			],
			"obj-26": [
				"push",
				"push",
				0
			],
			"obj-29": [
				"lift",
				"lift",
				0
			],
			"obj-32": [
				"settle",
				"settle",
				0
			],
			"obj-35": [
				"dry",
				"dry",
				0
			],
			"obj-38": [
				"speed",
				"speed",
				0
			],
			"obj-41": [
				"flood",
				"flood",
				0
			],
			"obj-44": [
				"feed",
				"feed",
				0
			],
			"obj-47": [
				"fade",
				"fade",
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