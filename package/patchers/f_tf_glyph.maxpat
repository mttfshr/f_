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
					"comment": "glyph composite",
					"index": 0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						30.0,
						452.0,
						30.0,
						30.0
					],
					"hint": "One closed-form ellipse glyph per grid cell over the raw tensor: orientation from the decoded axis (along the edge), aspect from the eigenvalue ratio, drawn only where trace >= gate. Tinted by the source luma at the cell centre. Gain-free: sweeping tensormap's strength changes nothing here. Bypass = source passthrough."
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
					"text": "route grid glyph_scale thickness softness gate max_aspect width height"
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
									"text": "in 1"
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
									"text": "in 2"
								}
							},
							{
								"box": {
									"code": "// f_tf_glyph -- single-stage glyph renderer, tensor family consumer #1.\n// Mirrors tests/test_tf_glyph.py glyph(). One pass: ADR-4 cell lookup ->\n// ADR-2 decode (plan ADR-2 is the family's canonical decode idiom; sharpen,\n// aniso_blur and hatch copy THIS block verbatim with a citation comment) ->\n// ADR-6 gate -> closed-form ellipse ring draw, ADR-5 aspect/radius.\n// pix_type float32 required. tint: ADR-7 provisional (TG019 pending).\n//\n// in1 = f_tf_tensormap OUTLET 0 only (f_tensor_type.md contract):\n//   R = Jxx*strength (>=0), G = Jxy*strength*0.5 + 0.5 (0.5 = zero), B = Jyy*strength (>=0), A = 1.\n//   Feeding outlet 1 (angle-doubled packed) decodes a visibly wrong double-spread\n//   glyph field -- a wiring error, documented, not a runtime sniff (plan ADR-3).\n// in2 = source texture, tint only; unconnected reads (0,0,0,1) (bench-verified\n//   2026-10-07) -> tap luma 0 -> ink stays the neutral white. Geometry never\n//   reads in2 (plan ADR-7).\n//\n// Gain-free: aspect and axis use ratios of R, G-0.5, B (common strength factor\n// cancels); the glyph RADIUS comes from `scale`, never from absolute lambdas\n// (ADR-5): sweeping tensormap's strength changes NOTHING here.\n// All-zeros unconnected tensor decodes to Jxy*strength = -1 -> phantom lambda1,\n//   lambda2 = -1 -- incidentally safe here because the TRACE is still exactly 0\n//   and the eps_trace floor keeps the gate closed (TG007; energy-gated consumers\n//   need an SPD guard instead -- see f_tensor_type.md consumer rule 5).\n// CAVEAT (plan ADR-2, required by the idiom): 0.5*atan2 confines theta to\n//   (-pi/2, pi/2]; an unoriented line at theta and theta+180deg renders\n//   identically here, so the caveat is inert -- but any sign-sensitive consumer\n//   copying this block must route through f_tf_axisflow instead.\n// Cell sampling is clamped to texel centres (tensormap ADR-5: the bench GPU\n//   WRAPS out-of-range reads).\n// ADR-8: ellipse-only v1. Cross/tick are scratch-only one-constant swaps\n//   (tier, gate PROVISIONAL-OPEN, TG016); no debug-tint modes (gate open,\n//   TG018) -- the v1 resolution is recorded, both stay scratch variants.\n// bypass_gate (module bypass, bypass_mode \"param\"; NOT the native @bypass):\n//   passthrough of the source at the current pixel.\n// GATE PROVISIONAL-OPEN (bench decides, TG020): the six defaults below\n//   (grid 24, scale 0.8, thickness 0.15, softness 0.1, gate 0.05,\n//   max_aspect 8) are the spec's provisional values. Resolving experiment:\n//   bench cost model vs the tensormap floor (~0.9 ms/pass, 1080p, R_MAX 16)\n//   -- expected trivially cheap (two taps, closed form) -- then tier-3 live\n//   judgement; the dial ranges stay per spec spec.md Parameters.\nParam grid(24.0);          // cells across (2-256)\nParam glyph_scale(0.8);    // glyph radius relative to the cell (0-2)\nParam thickness(0.15);     // stroke fraction of radius (0-1)\nParam softness(0.1);       // edge falloff (0-1)\nParam gate(0.05);          // delivered-trace draw threshold (0-1)\nParam max_aspect(8.0);     // aspect clamp (1-32)\nParam width(640.0);        // render size; `dim` reads 1 live (tensormap ADR-5\nParam height(480.0);       //   finding, texel Params precedent)\nParam bypass_gate(0.0);\n\neps_trace = 0.000001;      // tensormap ADR-6 convention (eps_trace, T019 there)\n\n// --- bypass: passthrough (glyph = passthrough per the family contract) ------\nsrc_here_r = sample(in2, norm).r;\nsrc_here_g = sample(in2, norm).g;\nsrc_here_b = sample(in2, norm).b;\nbp_r = clamp(src_here_r, 0.0, 1.0);\nbp_g = clamp(src_here_g, 0.0, 1.0);\nbp_b = clamp(src_here_b, 0.0, 1.0);\n\n// --- ADR-4: uniform lattice cell centre, clamped to texel centres -----------\ngx_idx = floor(norm.x * grid);\ngy_idx = floor(norm.y * grid);\ncu = (gx_idx + 0.5) / grid;\ncv = (gy_idx + 0.5) / grid;\ntu = clamp(cu, 0.5 / width, 1.0 - 0.5 / width);\ntv = clamp(cv, 0.5 / height, 1.0 - 0.5 / height);\n\n// --- ADR-2: canonical decode idiom (copied verbatim; plan ADR-2 owns it) ----\n// CELL-SAMPLE READ (2026-10-17, live finding): the tensor read's coordinate is\n// DATA-DEPENDENT and JUMPS more than a texel per pixel at the cell boundaries\n// (tu teleports by 1/grid every cell step, crossing >1 texel whenever\n// texel-per-cell < 1 texel/pixel), so hardware sample() falls back to its\n// NEAREST minification filter here (skills/jit-gen-codebox: \"sample() is NOT\n// bilinear when its coordinate is data-dependent and jumps between\n// neighbouring pixels\"). Fix per that doc: interpolate by hand from four\n// exact nearest() taps. Size 1:1 (tex = pix dim here), so this is exact.\n// (The family-canonical ADR-2 TEXT above stays as-is for the IDIOM \u2014 the\n// canonical block's `sample(tensor_tex, clamp(cell_uv_to_texel))` line gains\n// this four-tap note at the next idiom review; per-consumer decode math is\n// unchanged.)\ntx = tu * width - 0.5;\nty = tv * height - 0.5;\nix = floor(tx);\niy = floor(ty);\nax = tx - ix;\nay = ty - iy;\n// nearest() takes NORMALIZED coords (like sample): tap at each neighbour's\n// texel centre. (2026-10-17 correction: the first draft passed raw texel\n// indices + 0.5, which the sampler reads as uv ~72 \u2014 clamped to the last\n// texel, so every interior tap read the frame border.)\nux0 = clamp(ix, 0.0, width - 1.0);\nuy0 = clamp(iy, 0.0, height - 1.0);\nux1 = clamp(ix + 1.0, 0.0, width - 1.0);\nuy1 = clamp(iy + 1.0, 0.0, height - 1.0);\nt00 = nearest(in1, vec((ux0 + 0.5) / width, (uy0 + 0.5) / height));\nt10 = nearest(in1, vec((ux1 + 0.5) / width, (uy0 + 0.5) / height));\nt01 = nearest(in1, vec((ux0 + 0.5) / width, (uy1 + 0.5) / height));\nt11 = nearest(in1, vec((ux1 + 0.5) / width, (uy1 + 0.5) / height));\nt_r = t00.r * (1.0 - ax) * (1.0 - ay) + t10.r * ax * (1.0 - ay)\n    + t01.r * (1.0 - ax) * ay + t11.r * ax * ay;\nt_g = t00.g * (1.0 - ax) * (1.0 - ay) + t10.g * ax * (1.0 - ay)\n    + t01.g * (1.0 - ax) * ay + t11.g * ax * ay;\nt_b = t00.b * (1.0 - ax) * (1.0 - ay) + t10.b * ax * (1.0 - ay)\n    + t01.b * (1.0 - ax) * ay + t11.b * ax * ay;\njxy2_s = (t_g - 0.5) * 4.0;                // 2*Jxy*strength (gain-free below)\ndiff_s = t_r - t_b;                        // (Jxx - Jyy)*strength\nroot_s = sqrt(max(diff_s*diff_s + jxy2_s*jxy2_s, 0.0));\ntrace_s = t_r + t_b;                       // trace * strength (gate units)\n// atan2 NaN guard (live finding 2026-10-17): RUNTIME atan2(0,0) on this AMD\n// GPU returns NaN (compile-time literals fold to 0; runtime (0,0) does NOT \u2014\n// probe: bisect read theta=NaN at jxy2_s=0, diff_s=0, every dim). A mix()-\n// based guard CANNOT clear it (NaN*0 = NaN arithmetic), and GenExpr has no\n// isnan(). Fix at the source: a tiny positive bias on the denominator arg\n// means (0,0) never reaches atan2. Where |diff_s| >> 1e-7 the bias is\n// invisible; where |diff_s| ~ 0 the tensor is near-isotropic (aspect ~ 1),\n// the ring is rotation-invariant, and the swung angle renders identically.\n// (Tensormap's flat-pixel mix() neutral passes its bench the same way this\n// would NOT have caught it: its live content had no exact-degenerate pixels \u2014\n// this codebox gets constants in the probe path, so the fix goes here.)\ntheta = 0.5 * atan2(jxy2_s, diff_s + 1e-7);  // GRADIENT axis; along = theta + pi/2\n// Gain-free identities (strength is a common factor on R, G-0.5, B):\n//   tan(2*theta) = 2*(t_g-0.5)/(t_r - t_b);   aspect = (trace+root)/(trace-root)\n// CAVEAT: 0.5*atan2 confines theta to (-pi/2, pi/2]; a near-vertical axis\n// decodes sign-flipped. Safe ONLY for consumers symmetric to theta+180deg\n// (glyphs, blur, hatch, sharpen, coherence). Sign-sensitive consumers must\n// route through f_tf_axisflow (f_tensor_type.md consumer rule 2).\n\n// --- ADR-5: aspect from the ratio (gain-free), radius from scale ------------\nlam2_s = max(trace_s - root_s, eps_trace);\nratio = max((trace_s + root_s) / lam2_s, 1.0);\naspect = clamp(sqrt(ratio), 1.0, max_aspect);\n// GATE PROVISIONAL-OPEN (spec OQ3, tier-3 confirms): gain-free radius.\n// Fallback design if tier 3 says size-meaning matters: radius from lam1 with\n// an explicit strength echo param -- recorded in plan ADR-5, not built.\n\n// --- ADR-6: gate (draw threshold in delivered units, eps floor) -------------\nvisible = step(max(gate, eps_trace), trace_s);\n\n// --- draw: closed-form ellipse ring in the rotated local frame (no loops) ---\nalong_ang = theta + halfpi;\nca = cos(along_ang);\nsa = sin(along_ang);\ndxp = norm.x - cu;\ndyp = norm.y - cv;\nalong = dxp * ca + dyp * sa;\nacross = -dxp * sa + dyp * ca;\ncellsize = 1.0 / grid;\nrmaj = glyph_scale * cellsize * 0.5;       // semi-major axis\nbmin = rmaj / max(aspect, 0.000001);       // semi-minor\ndd = sqrt(max((along / rmaj) * (along / rmaj) + (across / bmin) * (across / bmin), 0.0));\nd = (dd - 1.0) * bmin;                     // approx SDF of the ring\nhw = thickness * rmaj * 0.5;\nsoft = max(softness * rmaj, 0.000001);\ncover = 1.0 - smoothstep(hw, hw + soft, abs(d));\n\n// --- tint: ADR-7 provisional, source luma modulates a white ink -------------\n// tint at the cell centre: same data-dependent-jump situation as the tensor\n// read above \u2014 same four-tap nearest() fix (normalized tap coords).\nu0x = clamp(ix, 0.0, width - 1.0);\nu0y = clamp(iy, 0.0, height - 1.0);\nu1x = clamp(ix + 1.0, 0.0, width - 1.0);\nu1y = clamp(iy + 1.0, 0.0, height - 1.0);\ns00 = nearest(in2, vec((u0x + 0.5) / width, (u0y + 0.5) / height));\ns10 = nearest(in2, vec((u1x + 0.5) / width, (u0y + 0.5) / height));\ns01 = nearest(in2, vec((u0x + 0.5) / width, (u1y + 0.5) / height));\ns11 = nearest(in2, vec((u1x + 0.5) / width, (u1y + 0.5) / height));\nsrc_l_r = s00.r * (1.0 - ax) * (1.0 - ay) + s10.r * ax * (1.0 - ay)\n        + s01.r * (1.0 - ax) * ay + s11.r * ax * ay;\nsrc_l_g = s00.g * (1.0 - ax) * (1.0 - ay) + s10.g * ax * (1.0 - ay)\n        + s01.g * (1.0 - ax) * ay + s11.g * ax * ay;\nsrc_l_b = s00.b * (1.0 - ax) * (1.0 - ay) + s10.b * ax * (1.0 - ay)\n        + s01.b * (1.0 - ax) * ay + s11.b * ax * ay;\nsrc_luma = src_l_r * 0.299 + src_l_g * 0.587 + src_l_b * 0.114;\nink_r = 1.0 + (src_l_r - 1.0) * src_luma;\nink_g = 1.0 + (src_l_g - 1.0) * src_luma;\nink_b = 1.0 + (src_l_b - 1.0) * src_luma;\n\ncv_mask = cover * visible;\nout_r = ink_r * cv_mask;\nout_g = ink_g * cv_mask;\nout_b = ink_b * cv_mask;\n\n// final stage: clamp/encode here only (family hard rule; no upstream stages)\nout1 = vec(mix(clamp(out_r, 0.0, 1.0), bp_r, bypass_gate),\n           mix(clamp(out_g, 0.0, 1.0), bp_g, bypass_gate),\n           mix(clamp(out_b, 0.0, 1.0), bp_b, bypass_gate),\n           1.0);",
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
										"gen-obj-10",
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
						380.0,
						200.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_glyph_pix",
					"varname": "#0_glyph_pix"
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
					"varname": "glyph_autopattr"
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
					"text": "Glyph"
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
					"comment": "source (tint)",
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
					"id": "obj-20",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Cells across (the glyph lattice is grid x grid). The real control: 24 = coarse debug read, 64+ = dense texture. PROVISIONAL default -- live judgement pending (tasks TG020).",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_glyph_pix::grid",
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
								24.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "grid",
							"parameter_mmax": 256.0,
							"parameter_mmin": 2.0,
							"parameter_modmode": 3,
							"parameter_shortname": "grid",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "grid"
				}
			},
			{
				"box": {
					"id": "obj-21",
					"maxclass": "attrui",
					"attr": "grid",
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
					"text": "Grid",
					"textjustification": 1,
					"varname": "lbl_grid"
				}
			},
			{
				"box": {
					"id": "obj-23",
					"maxclass": "live.numbox",
					"fontname": "Ableton Sans Light",
					"hint": "Glyph radius relative to the cell: 1.0 = glyphs touch. PROVISIONAL (TG020).",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_glyph_pix::glyph_scale",
					"parameter_enable": 1,
					"patching_rect": [
						110.0,
						250.0,
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
								0.8
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "glyph_scale",
							"parameter_mmax": 2.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "glyph_scale",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"varname": "glyph_scale"
				}
			},
			{
				"box": {
					"id": "obj-24",
					"maxclass": "attrui",
					"attr": "glyph_scale",
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
					"text": "Scale",
					"textjustification": 1,
					"varname": "lbl_glyph_scale"
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
					"hint": "Stroke weight of the ellipse ring, as a fraction of the radius. PROVISIONAL (TG020).",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_glyph_pix::thickness",
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
								0.15
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "thickness",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "thickness",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "thickness"
				}
			},
			{
				"box": {
					"id": "obj-27",
					"maxclass": "attrui",
					"attr": "thickness",
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
					"text": "Thickness",
					"textjustification": 1,
					"varname": "lbl_thickness"
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
					"hint": "Edge falloff, independent of thickness (f_weave convention). PROVISIONAL (TG020).",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_glyph_pix::softness",
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
								0.1
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
					"text": "Softness",
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
					"hint": "Draw threshold on the delivered trace: cells below it stay empty (inherits tensormap's eps_trace convention; zero and unconnected tensors render empty). PROVISIONAL (TG020).",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_glyph_pix::gate",
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
								0.05
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "gate",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "gate",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "gate"
				}
			},
			{
				"box": {
					"id": "obj-33",
					"maxclass": "attrui",
					"attr": "gate",
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
					"text": "Gate",
					"textjustification": 1,
					"varname": "lbl_gate"
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
					"hint": "Clamp on the ellipse aspect so near-degenerate tensors do not draw infinitely thin spikes. PROVISIONAL (TG020).",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_glyph_pix::max_aspect",
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
								8.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "max_aspect",
							"parameter_mmax": 32.0,
							"parameter_mmin": 1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "max_aspect",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "max_aspect"
				}
			},
			{
				"box": {
					"id": "obj-36",
					"maxclass": "attrui",
					"attr": "max_aspect",
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
					"text": "Max Aspect",
					"textjustification": 1,
					"varname": "lbl_max_aspect"
				}
			},
			{
				"box": {
					"id": "obj-38",
					"maxclass": "live.numbox",
					"fontname": "Ableton Sans Light",
					"hint": "Render width in pixels. Set to the real frame width: it sets the clamped-tap texel step. (Live jit.gl.pix cannot read its own size, so this is exposed for now.)",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_glyph_pix::width",
					"parameter_enable": 1,
					"patching_rect": [
						470.0,
						250.0,
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
								640.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "width",
							"parameter_mmax": 8192.0,
							"parameter_mmin": 64.0,
							"parameter_modmode": 3,
							"parameter_shortname": "width",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"varname": "width"
				}
			},
			{
				"box": {
					"id": "obj-39",
					"maxclass": "attrui",
					"attr": "width",
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
					"text": "Width",
					"textjustification": 1,
					"varname": "lbl_width"
				}
			},
			{
				"box": {
					"id": "obj-41",
					"maxclass": "live.numbox",
					"fontname": "Ableton Sans Light",
					"hint": "Render height in pixels. Set to the real frame height.",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_glyph_pix::height",
					"parameter_enable": 1,
					"patching_rect": [
						542.0,
						250.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						78.0,
						100.0,
						34.0,
						15.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								480.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "height",
							"parameter_mmax": 8192.0,
							"parameter_mmin": 64.0,
							"parameter_modmode": 3,
							"parameter_shortname": "height",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"varname": "height"
				}
			},
			{
				"box": {
					"id": "obj-42",
					"maxclass": "attrui",
					"attr": "height",
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
					"text": "Height",
					"textjustification": 1,
					"varname": "lbl_height"
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
						"obj-3",
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
						1
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
				"grid",
				"grid",
				0
			],
			"obj-23": [
				"glyph_scale",
				"glyph_scale",
				0
			],
			"obj-26": [
				"thickness",
				"thickness",
				0
			],
			"obj-29": [
				"softness",
				"softness",
				0
			],
			"obj-32": [
				"gate",
				"gate",
				0
			],
			"obj-35": [
				"max_aspect",
				"max_aspect",
				0
			],
			"obj-38": [
				"width",
				"width",
				0
			],
			"obj-41": [
				"height",
				"height",
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