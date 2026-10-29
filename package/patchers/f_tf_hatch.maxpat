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
					"comment": "streaks",
					"index": 0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						30.0,
						552.0,
						30.0,
						30.0
					],
					"tricolor": [
						0.55,
						0.55,
						0.55,
						1.0
					],
					"hint": "Hatch strokes, luma on black (color is downstream's job): strokes follow the tensor's structure axis and lengthen where coherence is high; grain where it is low; nothing below the structure floor. @type float32."
				}
			},
			{
				"box": {
					"id": "obj-201",
					"maxclass": "outlet",
					"comment": "streak field",
					"index": 0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						100.0,
						552.0,
						30.0,
						30.0
					],
					"tricolor": [
						0.55,
						0.55,
						0.55,
						1.0
					],
					"hint": "The same field without the Line style (soft strokes), for downstream styling or gating. NOT a tensor and not a vecfield."
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
					"numoutlets": 8,
					"outlettype": [
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
						583.0,
						22.0
					],
					"text": "route reach grain density contrast line_hard strength structure_floor angle_offset"
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
									"code": "// Stage E1 (f_tf_hatch v2): tensor decode + presence. in1 = the TENSOR\n// (f_tf_tensormap outlet 0, raw float32; f_tensor_type.md encoding).\n// Mirrors tests/modules/tf_hatch/tf_hatch_mirror.py stage_e1 (aux_mode\n// \"unsigned_nearest\", spec OQ2 decided 2026-10-28). Intermediate texture,\n// NEVER an outlet; unbounded float32 (no clamp, no 0.5 offset).\n//\n// out1 = (ca, sa, coh, pres):\n//   (ca, sa)  cos/sin of the ALONG-structure axis + angle_offset*pi/2. The\n//             axis is an unoriented line; E2 recovers sign continuity itself\n//             (dot-product alignment), so this pair is read with `nearest`\n//             only (interpolating it would flip sign at the horizontal cut).\n//   coh       coherence (lambda1-lambda2)/(lambda1+lambda2), gain-free\n//             (tensormap plan ADR-2). Enters E2 ONLY as direction persistence.\n//   pres      PRESENCE: smooth ramp on the tensormap-encoded trace (R + B)\n//             against structure_floor^2. Brightness gate only (E3 applies it).\n//   Where trace <= eps_trace (zero / direction-undefined tensor): axis UNSET\n//   (0, 0), coh 0, pres 0 -- never an atan2(0,0) artifact.\n//\n// DECODE IDIOM: verbatim from .specify/f_tf_glyph/plan.md ADR-2:\n//   Jxx = R/strength; Jxy = (G-0.5)*2/strength; Jyy = B/strength\n//   theta = 0.5*atan2(2*Jxy, Jxx-Jyy)  (GRADIENT axis; along = theta + pi/2)\n// The read is AT norm (texel centred, always in-bounds).\n\nParam strength(100.0);\nParam angle_offset(0.0);\nParam structure_floor(0.1);\n\neps_trace = 0.000001;\n\n// (component access INLINE on sample(): on a stored variable it silently fails)\njxx = sample(in1, norm).r / strength;\njxy = (sample(in1, norm).g - 0.5) * 2.0 / strength;\njyy = sample(in1, norm).b / strength;\ntrace = jxx + jyy;\ndiff = jxx - jyy;\nroot = sqrt(diff*diff + 4.0*jxy*jxy);\ntheta = 0.5 * atan2(2.0*jxy, diff);\n\niso = 1.0 - step(eps_trace, trace);   // 1 = zero/undefined tensor\ncoh = clamp(root / max(trace, eps_trace), 0.0, 1.0);\n\neff = theta + halfpi + angle_offset * halfpi;\nca = cos(eff) * (1.0 - iso);\nsa = sin(eff) * (1.0 - iso);\n\n// presence: enc_trace = R + B = trace * the producing tensormap's strength.\n// thr = floor^2 (finer at the low end); ramp 0.5*thr -> 1.5*thr (+ a hair, so\n// floor 0 is a step at the iso guard).\nenc_trace = sample(in1, norm).r + sample(in1, norm).b;\nthr = structure_floor * structure_floor;\npres = smoothstep(0.5 * thr, 1.5 * thr + 0.000001, enc_trace) * (1.0 - iso);\n\nout1 = vec(ca, sa, coh * (1.0 - iso), pres);\n",
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
						216.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_hatch_stage_e1 @type float32",
					"varname": "#0_hatch_stage_e1"
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
									"code": "// Stage E2 (f_tf_hatch v2): the streamline march. in1 = E1's aux (ca, sa, coh,\n// pres), render-sized (so `dim` is the render's). Mirrors\n// tests/modules/tf_hatch/tf_hatch_mirror.py stage_e2 (sparse mode).\n//\n// Per pixel: march N = 16 steps each way along the local axis, accumulating\n// sparse impulse noise. All geometry is in PIXEL units (steps are uniform in\n// pixels, so a non-square frame still gets round streaks).\n//   - sign continuity: the axis has no sign; each step flips it to agree with\n//     the previous direction (dot product), so there is no branch cut.\n//   - coherence enters ONLY as persistence (spec OQ1): d = normalize(w*a +\n//     (1-w)*r), w = coh^0.5, r = a per-pixel/per-step hashed unit vector.\n//     Coherent regions march ballistically (streaks), incoherent ones random-\n//     walk (grain). Never shape, never brightness.\n//   - noise lives in WORLD coordinates (hash of the lattice cell the position\n//     falls in, cell size from `grain`); a cell is lit when its hash < fill.\n//   - brightness = lit CELLS crossed (acc * step / cell_px), so one impulse's\n//     stroke has brightness ~1 whatever reach and grain are.\n//   - a path that leaves the frame stops contributing (`alive` latch).\n//   - the step must not exceed the cell size (step <= cell_px) or cells can be\n//     skipped; at N = 16 this bounds reach against grain.\n//\n// Coordinates: `norm` = (i + 0.5)/dim (texel centres; tests/lib/gpu_sim.py,\n// jxf.py), so the pixel's own texel centre is norm*dim = i + 0.5. (`cell`\n// would be norm*(dim-1): not used.) Reads: `nearest` at (pos/dim).\n//\n// Params (names avoid GenExpr operators: `length` is one, hence `reach`):\n//   reach    0..1  half-length of the march = reach * 0.25 * frame height\n//   grain    0..1  noise cell size, log: cells per frame height =\n//                  2^((1-grain)*6+3)\n//   density  0..1  lit-cell probability fill = 0.0025 * 2^(5*density)\n// out1 = (raw lit-cells-crossed, pres, 0, 1)\n\nlit_noise(cx, cy, cell_sz, fl) {\n    ix = floor(cx / cell_sz);\n    iy = floor(cy / cell_sz);\n    hv = fract(sin(ix * 127.1 + iy * 311.7) * 43758.5453);\n    return 1.0 - step(fl, hv);\n}\n\nParam reach(0.5);\nParam grain(0.5);\nParam density(0.7);\n\nwpx = dim.x;\nhpx = dim.y;\nx0 = norm.x * wpx;\ny0 = norm.y * hpx;\n\nhalf_len = reach * 0.25 * hpx;\nh_step = half_len / 16.0;\ncell_px = hpx / pow(2.0, (1.0 - grain) * 6.0 + 3.0);\nfill_frac = 0.0025 * pow(2.0, 5.0 * density);\npersist_pow = 0.5;\n\nca0 = nearest(in1, norm).x;\nsa0 = nearest(in1, norm).y;\npres0 = nearest(in1, norm).w;\n// unset axis (0, 0) -> a fixed fallback axis (E3 multiplies by presence 0 there)\nm0 = sqrt(ca0 * ca0 + sa0 * sa0);\nok0 = step(0.000001, m0);\nca0 = mix(1.0, ca0 / max(m0, 0.000001), ok0);\nsa0 = mix(0.0, sa0 / max(m0, 0.000001), ok0);\n\nacc = lit_noise(x0, y0, cell_px, fill_frac);\nidxp = floor(y0) * wpx + floor(x0);\npx = x0;\npy = y0;\ndx = 0.0;\ndy = 0.0;\nalive = 1.0;\nsgn = 1.0;\nfor (side = 0; side < 2; side += 1) {\n    px = x0;\n    py = y0;\n    alive = 1.0;\n    sgn = 1.0 - 2.0 * side;\n    dx = sgn * ca0;\n    dy = sgn * sa0;\n    for (k = 1; k <= 16; k += 1) {\n        ux = px / wpx;      // px is clamped to [0.5, W-0.5]: strictly inside (0, 1)\n        uy = py / hpx;\n        ax = nearest(in1, vec(ux, uy)).x;\n        ay = nearest(in1, vec(ux, uy)).y;\n        coh = nearest(in1, vec(ux, uy)).z;\n        am = sqrt(ax * ax + ay * ay);\n        oka = step(0.000001, am);\n        ax = mix(1.0, ax / max(am, 0.000001), oka);\n        ay = mix(0.0, ay / max(am, 0.000001), oka);\n        dp = ax * dx + ay * dy;\n        flipv = 2.0 * step(0.0, dp) - 1.0;\n        ax = ax * flipv;\n        ay = ay * flipv;\n        wgt = pow(clamp(coh, 0.0, 1.0), persist_pow);\n        ang = twopi * fract(sin(idxp * 12.9898 + k * 78.233 + sgn * 37.719) * 43758.5453);\n        mx = wgt * ax + (1.0 - wgt) * cos(ang);\n        my = wgt * ay + (1.0 - wgt) * sin(ang);\n        mm = sqrt(mx * mx + my * my);\n        okm = step(0.000001, mm);\n        ax = mix(ax, mx / max(mm, 0.000001), okm);\n        ay = mix(ay, my / max(mm, 0.000001), okm);\n        nx = px + h_step * ax;\n        ny = py + h_step * ay;\n        alive = alive * step(0.0, nx) * step(nx, wpx) * step(0.0, ny) * step(ny, hpx);\n        px = clamp(nx, 0.5, wpx - 0.5);\n        py = clamp(ny, 0.5, hpx - 0.5);\n        dx = ax;\n        dy = ay;\n        acc = acc + alive * lit_noise(px, py, cell_px, fill_frac);\n    }\n}\nraw = acc * h_step / cell_px;\nout1 = vec(raw, pres0, 0.0, 1.0);\n",
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
						216.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_hatch_stage_e2 @type float32",
					"varname": "#0_hatch_stage_e2"
				}
			},
			{
				"box": {
					"id": "obj-51",
					"maxclass": "newobj",
					"numinlets": 1,
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
									"code": "// Stage E3 (f_tf_hatch v2): style + presence + encode. in1 = E2's aux2\n// (raw lit-cells-crossed, pres, 0, 1). Mirrors tests/modules/tf_hatch/\n// tf_hatch_mirror.py stage_e3 (sparse mode). The ONLY stage that clamps.\n//\n//   contrast  0..1  gain on the raw lit-cells-crossed value, 0.6 -> 2.0\n//                   (PROVISIONAL, tier-3 confirms)\n//   line_hard 0..1  0 = smooth field, 1 = hard engraved strokes (threshold at\n//                   0.5 with a soft edge of half-width 0.5 -> 0.03)\n//   presence multiplies the styled field (structure floor)\n//   bypass_gate     black on both outlets, alpha 1 (outlet contract)\n//\n// out1 = module OUTLET 0: styled strokes, luma on black, A = 1 (color is\n// downstream's job). out2 = module OUTLET 1: the unstyled normalized field\n// (same luma without `line_hard`), A = 1 (spec OQ4).\n\nParam contrast(0.5);\nParam line_hard(0.0);\nParam bypass_gate(0.0);\n\nraw = nearest(in1, norm).x;\npres = nearest(in1, norm).y;\n\nv = clamp(raw * (0.6 + contrast * 1.4), 0.0, 1.0);\nw = 0.5 + (0.03 - 0.5) * line_hard;\nhard = smoothstep(0.5 - w, 0.5 + w, v);\nstyled = v + (hard - v) * line_hard;\n\no0 = mix(styled * pres, 0.0, bypass_gate);\no1 = mix(v * pres, 0.0, bypass_gate);\nout1 = vec(o0, o0, o0, 1.0);\nout2 = vec(o1, o1, o1, 1.0);\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
									"id": "gen-obj-2",
									"maxclass": "codebox",
									"numinlets": 1,
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
						480.0,
						216.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_hatch_stage_e3 @type float32",
					"varname": "#0_hatch_stage_e3"
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
					"varname": "hatch_autopattr"
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
					"text": "Hatch"
				}
			},
			{
				"box": {
					"id": "obj-8",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 11.0,
					"textcolor": [
						0.85,
						0.55,
						0.2,
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
						94.0,
						0.9,
						70.0,
						21.0
					],
					"text": "T_ in"
				}
			},
			{
				"box": {
					"id": "obj-19f",
					"maxclass": "panel",
					"background": 0,
					"bgcolor": [
						0.85,
						0.55,
						0.2,
						1.0
					],
					"border": 0,
					"mode": 0,
					"hint": "Takes: tensor",
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
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Stroke length: half-length of the march, 0 to a quarter of the frame height on each side. Strokes only get this long where coherence is high; 0 draws nothing. With very fine Grain at full Length the march can skip noise cells and strokes get gaps. PROVISIONAL.",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_hatch_stage_e2::reach",
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
								0.5
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "reach",
							"parameter_mmax": 1.0,
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
					"text": "Length",
					"textjustification": 1,
					"varname": "lbl_reach"
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
					"hint": "Feature scale of the noise the strokes are drawn from, log-mapped: low = coarse, thick strokes; high = fine, thin strokes. PROVISIONAL.",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_hatch_stage_e2::grain",
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
							"parameter_longname": "grain",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
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
					"hint": "How many strokes: the fraction of noise cells that are lit (0.25% at 0 to 8% at 1). PROVISIONAL.",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_hatch_stage_e2::density",
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
								0.7
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "density",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "density",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "density"
				}
			},
			{
				"box": {
					"id": "obj-27",
					"maxclass": "attrui",
					"attr": "density",
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
					"text": "Density",
					"textjustification": 1,
					"varname": "lbl_density"
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
					"hint": "Stroke brightness gain (0.6x at 0 to 2x at 1). PROVISIONAL.",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_hatch_stage_e3::contrast",
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
								0.5
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "contrast",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
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
					"id": "obj-30",
					"maxclass": "attrui",
					"attr": "contrast",
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
					"text": "Contrast",
					"textjustification": 1,
					"varname": "lbl_contrast"
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
					"hint": "Stroke style: 0 = soft, 1 = hard engraved lines (thresholded with a soft edge). Outlet 1 stays soft.",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_hatch_stage_e3::line_hard",
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
							"parameter_longname": "line_hard",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "line_hard",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "line_hard"
				}
			},
			{
				"box": {
					"id": "obj-33",
					"maxclass": "attrui",
					"attr": "line_hard",
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
					"text": "Line",
					"textjustification": 1,
					"varname": "lbl_line_hard"
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
					"hint": "Gain the producing tensormap applied to trace and the raw tensor (f_tensor_type.md decode). Match it to the tensormap feeding this module: the decode divides it back out. Log dial like tensormap's.",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_hatch_stage_e1::strength",
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
								100.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "strength",
							"parameter_mmax": 1000.0,
							"parameter_mmin": 1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "strength",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "strength"
				}
			},
			{
				"box": {
					"id": "obj-36",
					"maxclass": "attrui",
					"attr": "strength",
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
					"text": "Strength",
					"textjustification": 1,
					"varname": "lbl_strength"
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
					"hint": "Structure floor: where there is too little structure to mark, draw nothing. Reads the tensormap's trace scale (trace x its Strength; strong structure is ~1), squared for finer control at the low end. 0 = marks wherever any structure exists. Not strength-invariant: calibrate with the tensormap's Strength. PROVISIONAL default.",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_hatch_stage_e1::structure_floor",
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
								0.1
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "structure_floor",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "structure_floor",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "structure_floor"
				}
			},
			{
				"box": {
					"id": "obj-39",
					"maxclass": "attrui",
					"attr": "structure_floor",
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
					"text": "Floor",
					"textjustification": 1,
					"varname": "lbl_structure_floor"
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
					"hint": "Rotates the streaks relative to the structure axis: +-1 = +-90 deg (the axis is an unoriented line, so +-90 spans the distinct layouts). Zero keeps strokes along structure.",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_hatch_stage_e1::angle_offset",
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
							"parameter_longname": "angle_offset",
							"parameter_mmax": 1.0,
							"parameter_mmin": -1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "angle_offset",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "angle_offset"
				}
			},
			{
				"box": {
					"id": "obj-42",
					"maxclass": "attrui",
					"attr": "angle_offset",
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
					"text": "Offset",
					"textjustification": 1,
					"varname": "lbl_angle_offset"
				}
			},
			{
				"box": {
					"id": "obj-44",
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
					"id": "obj-45",
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
						"obj-51",
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
						"obj-51",
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
						"obj-50",
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
						"obj-51",
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
						"obj-51",
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
				"grain",
				"grain",
				0
			],
			"obj-26": [
				"density",
				"density",
				0
			],
			"obj-29": [
				"contrast",
				"contrast",
				0
			],
			"obj-32": [
				"line_hard",
				"line_hard",
				0
			],
			"obj-35": [
				"strength",
				"strength",
				0
			],
			"obj-38": [
				"structure_floor",
				"structure_floor",
				0
			],
			"obj-41": [
				"angle_offset",
				"angle_offset",
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