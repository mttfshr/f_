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
					"comment": "texture",
					"index": 0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						30.0,
						452.0,
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
					"text": "route fold_mode p_sides q_vertex tile_scale cam_x cam_y rot"
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
									"code": "// codebox_poincare.gen -- f_poincare: a texture folded into a fundamental domain of the {p,q} tiling of the Poincare disk.\n// fold_mode 0 = mode A (whole tile, below), fold_mode 1 = mode B (sliver kaleidoscope, see 'Mode B').\n// Mirror: tests/modules/poincare/poincare_mirror.py (render, fold_step_k3, fold_a_k3, fold_b_k). Bench: tests/modules/poincare/bench_poincare.py.\n// Spec: .specify/stable/f_poincare/spec.md (Mode A, Rim policy, Texture mapping); decisions: tasks.md T004 (32 iterations, fade from 0.99),\n// T005 (live p by testing only the 3 nearest circles by angle: it matches the p-circle chain on every pixel both settle,\n// 56 pairs p, q in 3..10; lowest index wins among them, and that priority order is part of mode A's definition), T006 (crop,\n// not warp: the settled point is the sample coordinate, tile_scale sets the texture extent).\n//\n// Mode A: each pixel is a point z in the unit disk (the disk's radius is the shorter side). Every iteration: find the circle index\n// nearest to z by angle, test that circle and its two neighbours, invert once in the lowest-index one that contains z.\n// The p edge circles have centres (d sin(2 i th), d cos(2 i th)), th = pi / p, and radius sqrt(r2); d and r2 come from the\n// closed form (spec \"Geometry\"). The settled z samples the first inlet at z / (2 tile_scale) + 0.5, so the settled position\n// uses the same convention as the first inlet's norm. Black outside the unit disk, outside [0,1] of the texture, where the\n// loop has not settled, and faded to black from rim_fade to the rim.\n// Mode B (T020, spec 'Mode B'): each iteration folds the angle into [0, pi / p] about the origin (the angle is\n// (a + 2 pi) mod (2 pi / p), mirrored about the half sector), then inverts once in the single edge circle on the +x axis if the point\n// is inside it; one more fold after the loop. Settled = outside that circle. The (2, p, q) triangle is a strict fundamental domain, so\n// there is no priority order. Both modes are computed every pixel and fold_mode picks one with mix (branchless; cost is both).\n// Settled tests accept a final point within 1e-5 (squared distance) inside an edge circle: a pixel on a mirror line of the group lands\n// exactly on the circle, a knife-edge that float64 called unsettled and float32 settled (2026-11-06, mode B p = 4 on a square frame).\n// Camera: rot, cam_x, cam_y (see 'Camera' below the setup). Guard: p_sides is rounded and clamped to 3..10, q_vertex is rounded and raised to the smallest integer with 1/p + 1/q < 1/2.\n// width / height are the render size (the render_dim Params; `dim` is not used). bypass_gate = 1 passes the first inlet through\n// (scratch convention for this phase; the module's bypass behaviour is decided in T041).\n// Compile hazards avoided (skills/jit-gen-codebox): functions before Params and take Params as arguments, no unary minus before a\n// parenthesis, no variables named e / phi / pi / cell / active / inN, no one-letter Params, no step() with two literals, loop\n// state declared before the loop, no outlet names in comments, atan2 never sees (0, 0).\n\ninside_c(zx, zy, idx, d, th, r2) {\n    cdx = zx - d * sin(2.0 * idx * th);\n    cdy = zy - d * cos(2.0 * idx * th);\n    return 1.0 - step(r2, cdx * cdx + cdy * cdy);\n}\n\nfold_step(zx, zy, np, d, th, r2) {\n    i_near = floor(atan2(zx, zy + 0.0000001) / (2.0 * th) + 0.5);\n    ia = mod(2.0 * np + i_near, np);\n    ib = mod(2.0 * np + i_near - 1.0, np);\n    ic = mod(2.0 * np + i_near + 1.0, np);\n    fa = inside_c(zx, zy, ia, d, th, r2);\n    fb = inside_c(zx, zy, ib, d, th, r2);\n    fc = inside_c(zx, zy, ic, d, th, r2);\n    ka = ia + (1.0 - fa) * 1000.0;\n    kb = ib + (1.0 - fb) * 1000.0;\n    kc = ic + (1.0 - fc) * 1000.0;\n    wk = min(ka, min(kb, kc));\n    has = 1.0 - step(500.0, wk);\n    wcx = d * sin(2.0 * wk * th);\n    wcy = d * cos(2.0 * wk * th);\n    wdx = zx - wcx;\n    wdy = zy - wcy;\n    sc = r2 / max(wdx * wdx + wdy * wdy, 0.0001);\n    return zx + (wcx + wdx * sc - zx) * has, zy + (wcy + wdy * sc - zy) * has;\n}\n\nany_inside(zx, zy, np, d, th, r2) {\n    i_near = floor(atan2(zx, zy + 0.0000001) / (2.0 * th) + 0.5);\n    fa = inside_c(zx, zy, mod(2.0 * np + i_near, np), d, th, r2);\n    fb = inside_c(zx, zy, mod(2.0 * np + i_near - 1.0, np), d, th, r2);\n    fc = inside_c(zx, zy, mod(2.0 * np + i_near + 1.0, np), d, th, r2);\n    return max(fa, max(fb, fc));\n}\n\nwedge(zx, zy, np) {\n    sector = twopi / np;\n    wr = sqrt(zx * zx + zy * zy);\n    wa = mod(atan2(zy, zx + 0.0000001) + twopi, sector);\n    wm = min(wa, sector - wa);\n    return wr * cos(wm), wr * sin(wm);\n}\n\nfold_step_b(zx, zy, np, d, r2) {\n    fx, fy = wedge(zx, zy, np);\n    bdx = fx - d;\n    bd2 = bdx * bdx + fy * fy;\n    inb = 1.0 - step(r2, bd2);\n    bs = r2 / max(bd2, 0.0001);\n    return fx + (d + bdx * bs - fx) * inb, fy + (fy * bs - fy) * inb;\n}\n\nParam fold_mode(0);\nParam p_sides(4);\nParam q_vertex(5);\nParam tile_scale(0.26);\nParam iterations(32);\nParam rim_fade(0.99);\nParam width(640.0);\nParam height(480.0);\nParam cam_x(0);\nParam cam_y(0);\nParam rot(0);\nParam bypass_gate(0);\n\nnp_s = clamp(floor(p_sides + 0.5), 3.0, 10.0);\nq_min = floor(2.0 * np_s / (np_s - 2.0)) + 1.0;\nnq_s = max(floor(q_vertex + 0.5), q_min);\nth_s = pi / np_s;\ncosh_l = cos(pi / nq_s) / sin(th_s);\nt_half = sqrt((cosh_l - 1.0) / (cosh_l + 1.0));\nd_s = (t_half + 1.0 / t_half) * 0.5;\nrho_s = (1.0 / t_half - t_half) * 0.5;\nr2_s = rho_s * rho_s;\n\nasp_x = max(width / height, 1.0);\nasp_y = max(height / width, 1.0);\nzx0 = (norm.x * 2.0 - 1.0) * asp_x;\nzy0 = (norm.y * 2.0 - 1.0) * asp_y;\nrscr = sqrt(zx0 * zx0 + zy0 * zy0);\n\n// Camera (T030): rotate by rot (radians), then the disk translation (z - a) / (1 - conj(a) z), |a| clamped to 0.99.\n// Zero camera: cos 0 = 1, sin 0 = 0, a = 0 give den = 1, so z passes through unchanged. The point is first scaled into the disk\n// (a no-op, factor exactly 1, for rscr < 0.9999) so 1 - conj(a) z can never reach 0 on the corner pixels outside the disk.\n// rscr stays the SCREEN radius: the disk edge and the rim fade do not move with the camera.\ncam_len = sqrt(cam_x * cam_x + cam_y * cam_y);\ncam_k = min(1.0, 0.99 / max(cam_len, 0.000001));\ncax = cam_x * cam_k;\ncay = cam_y * cam_k;\n// Rim fade start (T032): float32 drifts from float64 sooner when the camera is near the rim, so the fade starts earlier as |a| grows,\n// by up to 0.04 at the clamp (measured offline, tasks.md T032). Zero camera subtracts exactly 0.\ncam_eff = cam_len * cam_k / 0.99;\nrim_eff = rim_fade - 0.04 * cam_eff * cam_eff;\ncin = min(1.0, 0.9999 / max(rscr, 0.0001));\ncrx = (zx0 * cos(rot) - zy0 * sin(rot)) * cin;\ncry = (zx0 * sin(rot) + zy0 * cos(rot)) * cin;\ncdre = 1.0 - (cax * crx + cay * cry);\ncdim = cax * cry - cay * crx;\ncden = max(cdre * cdre + cdim * cdim, 0.000001);\ncnx = crx - cax;\ncny = cry - cay;\nzx1 = (cnx * cdre - cny * cdim) / cden;\nzy1 = (cnx * cdim + cny * cdre) / cden;\n\nsax = zx1;\nsay = zy1;\nsbx = zx1;\nsby = zy1;\nfor (it = 0; it < iterations; it += 1) {\n    sax, say = fold_step(sax, say, np_s, d_s, th_s, r2_s);\n    sbx, sby = fold_step_b(sbx, sby, np_s, d_s, r2_s);\n}\nsbx, sby = wedge(sbx, sby, np_s);\nbfx = sbx - d_s;\nsettled_b = step(r2_s - 0.00001, bfx * bfx + sby * sby);\nsettled_a = 1.0 - any_inside(sax, say, np_s, d_s, th_s, r2_s - 0.00001);\nmode_b = step(0.5, fold_mode);\nsx = mix(sax, sbx, mode_b);\nsy = mix(say, sby, mode_b);\nsettled = mix(settled_a, settled_b, mode_b);\n\nus = sx / (2.0 * tile_scale) + 0.5;\nvs = sy / (2.0 * tile_scale) + 0.5;\nin_tex = step(0.0, us) * (1.0 - step(1.0, us)) * step(0.0, vs) * (1.0 - step(1.0, vs));\nin_disk = 1.0 - step(1.0, rscr);\nkeep = settled * in_tex * in_disk * (1.0 - smoothstep(rim_eff, 1.0, rscr));\n\nuc = clamp(us, 0.001, 0.999);\nvc = clamp(vs, 0.001, 0.999);\ntr = sample(in1, vec(uc, vc)).x;\ntg = sample(in1, vec(uc, vc)).y;\ntb = sample(in1, vec(uc, vc)).z;\nout1 = mix(vec(tr * keep, tg * keep, tb * keep, 1.0), sample(in1, norm), bypass_gate);\n",
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
					"text": "jit.gl.pix vsynth @name #0_poinc_pix @adapt 0 @dim 256 256 @type float32",
					"varname": "#0_poinc_pix"
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
					"varname": "poinc_autopattr"
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
						212.0,
						90.0
					],
					"presentation": 1,
					"presentation_rect": [
						0.0,
						0.0,
						212.0,
						90.0
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
						46.0,
						21.0
					],
					"text": "Poincare"
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
						114.0,
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
					"id": "obj-20",
					"maxclass": "live.text",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"hint": "Whole: each fold ends in the whole curved tile, the texture sits inside it. Sliver: the kaleidoscope, each fold ends in a thin wedge",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"param_connect": "#0_poinc_pix::fold_mode",
					"parameter_enable": 1,
					"patching_rect": [
						36.5,
						250.0,
						47.0,
						17.0
					],
					"presentation": 1,
					"presentation_rect": [
						62.0,
						2.0,
						52.0,
						17.0
					],
					"text": "Whole",
					"texton": "Sliver",
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
								"Whole",
								"Sliver"
							],
							"parameter_initial": [
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "fold_mode",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 0,
							"parameter_shortname": "fold_mode",
							"parameter_type": 1,
							"parameter_unitstyle": 0
						}
					},
					"varname": "fold_mode"
				}
			},
			{
				"box": {
					"id": "obj-21",
					"maxclass": "attrui",
					"attr": "fold_mode",
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
					"id": "obj-23",
					"maxclass": "live.numbox",
					"fontname": "Ableton Sans Light",
					"hint": "Sides of each tile. Whole and Sliver both take it live",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"int"
					],
					"param_connect": "#0_poinc_pix::p_sides",
					"parameter_enable": 1,
					"patching_rect": [
						110.0,
						250.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						22.0,
						41.0,
						34.0,
						15.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								4
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "p_sides",
							"parameter_mmax": 10,
							"parameter_mmin": 3,
							"parameter_modmode": 0,
							"parameter_shortname": "p_sides",
							"parameter_type": 1,
							"parameter_unitstyle": 0
						}
					},
					"varname": "p_sides"
				}
			},
			{
				"box": {
					"id": "obj-24",
					"maxclass": "attrui",
					"attr": "p_sides",
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
						4.0,
						41.0,
						16.0,
						15.0
					],
					"text": "p",
					"textjustification": 1,
					"varname": "lbl_p_sides"
				}
			},
			{
				"box": {
					"id": "obj-26",
					"maxclass": "live.numbox",
					"fontname": "Ableton Sans Light",
					"hint": "Tiles meeting at each vertex. Must satisfy 1/p + 1/q < 1/2; a smaller q is raised to the smallest that does",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"int"
					],
					"param_connect": "#0_poinc_pix::q_vertex",
					"parameter_enable": 1,
					"patching_rect": [
						182.0,
						250.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						22.0,
						63.0,
						34.0,
						15.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								5
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "q_vertex",
							"parameter_mmax": 10,
							"parameter_mmin": 3,
							"parameter_modmode": 0,
							"parameter_shortname": "q_vertex",
							"parameter_type": 1,
							"parameter_unitstyle": 0
						}
					},
					"varname": "q_vertex"
				}
			},
			{
				"box": {
					"id": "obj-27",
					"maxclass": "attrui",
					"attr": "q_vertex",
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
						4.0,
						63.0,
						16.0,
						15.0
					],
					"text": "q",
					"textjustification": 1,
					"varname": "lbl_q_vertex"
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
					"hint": "How much of the disk the texture covers. 0.26 shows the texture cleanly at p 4, q 5; the tile's vertex radius (0.4 at p 4, q 5) fills the gaps at its corners",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_poinc_pix::tile_scale",
					"parameter_enable": 1,
					"patching_rect": [
						262.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						64.0,
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
								0.26
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "tile_scale",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.05,
							"parameter_modmode": 3,
							"parameter_shortname": "tile_scale",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "tile_scale"
				}
			},
			{
				"box": {
					"id": "obj-30",
					"maxclass": "attrui",
					"attr": "tile_scale",
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
						52.5,
						20.0,
						50.0,
						18.0
					],
					"text": "Scale",
					"textjustification": 1,
					"varname": "lbl_tile_scale"
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
					"hint": "Travel through the tiling, sideways. A hyperbolic translation: steps look the same size at every depth",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_poinc_pix::cam_x",
					"parameter_enable": 1,
					"patching_rect": [
						334.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						101.0,
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
							"parameter_longname": "cam_x",
							"parameter_mmax": 0.99,
							"parameter_mmin": -0.99,
							"parameter_modmode": 3,
							"parameter_shortname": "cam_x",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "cam_x"
				}
			},
			{
				"box": {
					"id": "obj-33",
					"maxclass": "attrui",
					"attr": "cam_x",
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
						89.5,
						20.0,
						50.0,
						18.0
					],
					"text": "Cam x",
					"textjustification": 1,
					"varname": "lbl_cam_x"
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
					"hint": "Travel through the tiling, up and down. Past 0.99 in length the camera is held at 0.99",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_poinc_pix::cam_y",
					"parameter_enable": 1,
					"patching_rect": [
						406.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						138.0,
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
							"parameter_longname": "cam_y",
							"parameter_mmax": 0.99,
							"parameter_mmin": -0.99,
							"parameter_modmode": 3,
							"parameter_shortname": "cam_y",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "cam_y"
				}
			},
			{
				"box": {
					"id": "obj-36",
					"maxclass": "attrui",
					"attr": "cam_y",
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
						126.5,
						20.0,
						50.0,
						18.0
					],
					"text": "Cam y",
					"textjustification": 1,
					"varname": "lbl_cam_y"
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
					"hint": "Rotation of the view about the disk's centre, in radians, applied before the camera moves",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_poinc_pix::rot",
					"parameter_enable": 1,
					"patching_rect": [
						478.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						175.0,
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
							"parameter_longname": "rot",
							"parameter_mmax": 3.1416,
							"parameter_mmin": -3.1416,
							"parameter_modmode": 3,
							"parameter_shortname": "rot",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "rot"
				}
			},
			{
				"box": {
					"id": "obj-39",
					"maxclass": "attrui",
					"attr": "rot",
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
						163.5,
						20.0,
						50.0,
						18.0
					],
					"text": "Rot",
					"textjustification": 1,
					"varname": "lbl_rot"
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
						188.0,
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
					"id": "obj-rd-0",
					"maxclass": "newobj",
					"patching_rect": [
						30.0,
						542.0,
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
						542.0,
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
						572.0,
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
						542.0,
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
						572.0,
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
						602.0,
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
						602.0,
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
						"obj-5",
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
						"obj-5",
						0
					]
				}
			}
		],
		"parameters": {
			"obj-20": [
				"fold_mode",
				"fold_mode",
				0
			],
			"obj-23": [
				"p_sides",
				"p_sides",
				0
			],
			"obj-26": [
				"q_vertex",
				"q_vertex",
				0
			],
			"obj-29": [
				"tile_scale",
				"tile_scale",
				0
			],
			"obj-32": [
				"cam_x",
				"cam_x",
				0
			],
			"obj-35": [
				"cam_y",
				"cam_y",
				0
			],
			"obj-38": [
				"rot",
				"rot",
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