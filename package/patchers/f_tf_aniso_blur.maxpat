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
					"comment": "smoothed source",
					"index": 0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						30.0,
						452.0,
						30.0,
						30.0
					],
					"hint": "The source texture smoothed along the tensor field's structure axis (kernel shape and orientation from the decoded eigenvalues; isotropic blur wherever the field has no direction or the tensor is non-SPD/unconnected -- the SPD guard). Unbounded float32 passthrough of a weighted mean: values stay within the source's convex hull. Bypass = exact passthrough of the source."
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
						370.5,
						22.0
					],
					"text": "route strength_scale length width_gate floor_pct strength"
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
									"code": "// f_tf_aniso_blur -- single-stage coherence-enhancing smoother, tensor\n// family consumer #2. One pass: ADR-2 decode (glyph plan ADR-2 is the\n// family's canonical decode idiom; this module copies it with the citation\n// below and consumes the AXIS, not the angle) -> ADR-3 gates -> family (a)\n// kernel (fixed-tap straight-axis line integration with per-tap transverse\n// offset) -> weighted accumulation -> normalization. Mirrors\n// tests/test_tf_aniso_blur.py aniso_pass.\n// pix_type float32 required (stage output unbounded -- this is a smoother,\n// not a coder; the family hard rule).\n//\n// Kernel shape (plan ADR-2, family (a), RESOLVED PROVISIONAL 2026-10-17 by\n// the owner: the bench cost experiment cannot run in this build):\n//   GATE PROVISIONAL-OPEN -- kernel family (a) fixed-tap straight-axis line\n//   integration with per-tap transverse offset (the cf.directional audit\n//   shape, made tensor-driven), bounded loop, weights gated per tap\n//   (tensormap ADR-3); the deciding bench experiment: cost measurement\n//   (bc.measure, 1080p + 4K, M3 Max) of the shipped codebox vs the family\n//   (b) ellipse-grid variant at matched budget, then Matt's artifact call\n//   (family (a) shows cf.directional-style tap banding on smooth content;\n//   the NumPy artifact data recorded in tasks.md T010: family (a) mean abs\n//   0.0362 vs family (b) 0.0300 against the continuous area Gaussian at the\n//   default kernel). Curved-axis integration is OUT (plan ADR-4, straight\n//   axis in v1).\n//   Kernel geometry (T005): center tap + 8 stations per side at\n//   u = +-(k-0.5) px, along weight exp(-2u^2/L^2), each station three\n//   transverse taps (t = 0, +-D/2 px) at the discrete-Gaussian rule\n//   (1/4, 1/2, 1/4). 49 samples max = TAPS_MAX; cost scales with TAPS_MAX,\n//   not the dial (tensormap ADR-3 fact).\n//\n// in1 = f_tf_tensormap OUTLET 0 only (f_tensor_type.md contract):\n//   R = Jxx*strength (>=0), G = Jxy*strength*0.5 + 0.5 (0.5 = zero),\n//   B = Jyy*strength (>=0), A = 1. Feeding outlet 1 (angle-doubled packed)\n//   or a vecfield is a wiring error: documented, not sniffed (glyph ADR-3).\n// in2 = source texture, the content to smooth; unconnected reads black ->\n//   output black (spec acceptance).\n// Unconnected TENSOR (vs_black, all zeros): decodes Jxy*strength = -1 ->\n//   trace 0 with lambda1 = 1/strength phantom energy and lambda2 negative\n//   (non-SPD). This is an ENERGY-GATED consumer (W on lambda1), so the SPD\n//   test is the primary defense, not trace alone (f_tensor_type.md consumer\n//   rule 5; found jointly with the glyph triad 2026-10-17). A non-SPD or\n//   black tensor pixel behaves exactly as an isotropic pixel: the gates\n//   bypass the energy gate and take L = length, D = L (plain isotropic blur\n//   of the length budget). NOT provisional.\n// Bypass: bypass_mode \"param\" (NOT the native @bypass): exact passthrough\n//   of inlet 1 (family contract: this module has no encoding to neutralize).\n// Sample coordinates are CLAMPED to texel centers in-shader on every tap\n//   (tensormap ADR-5: the bench GPU WRAPS out-of-range reads).\n// All sample components read inline -- never store-then-slice. All floats\n// unclamped between stages of the math; only the guard (a route, not a\n// range clamp) and the sample-coordinate clamp exist.\nParam strength_scale(0.5);   // energy -> length gate gain (0-2) PROVISIONAL\nParam length(4.0);           // kernel semi-length in px (0-8: TAPS_MAX=49\n                             //   = 1 + 2*8 stations * 3 transverse taps)\n                             //   PROVISIONAL\nParam width_gate(0.5);       // coherence-response gate (0-1) PROVISIONAL\nParam floor_pct(0.25);       // width floor fraction (0-1) PROVISIONAL\n                             //   (`floor` collides with the GenExpr floor()\n                             //   operator: renamed per the glyph_scale\n                             //   precedent, wire name floor_pct)\nParam strength(100.0);       // tensormap's strength dial, for the G-decode\n                             // (the G-channel trap: the raw G carries\n                             // Jxy*strength*0.5+0.5 -- the decode needs\n                             // the value tensormap was dialed to; spec OQ3\n                             // option (a): document the pairing, tier 3\n                             // calibrates the two together)\nParam width(640.0);          // render size; `dim` reads 1 live (tensormap\nParam height(480.0);         //   T012 finding, texel Params precedent);\n                             //   these set the one-pixel tap step\nParam bypass_gate(0.0);\n\neps_trace = 0.000001;        // tensormap ADR-6 convention\neps_spd = 0.0001;            // SPD slack (float32 noise floor)\neps_root = 0.000001;         // axis-undefined floor (equal eigenvalues)\ntaps = 8;                    // compile-time station count per side;\n                             // TAPS_MAX = 1 + 2*taps*3 = 49\n\n// --- bypass: exact passthrough of inlet 1 (family contract) --------------\nbp = sample(in2, clamp(norm, vec(0.5/width, 0.5/height),\n                       vec(1.0 - 0.5/width, 1.0 - 0.5/height)));\n\n// --- ADR-2 decode idiom (copied from .specify/f_tf_glyph/plan.md ADR-2,\n//     cite-not-rederive; delivered-units form as the built glyph codebox\n//     carries it) ----------------------------------------------------------\nt_r = nearest(in1, norm).r;                 // inline access only\nt_g = nearest(in1, norm).g;\nt_b = nearest(in1, norm).b;\njxy_s = (t_g - 0.5) * 2.0 / strength;       // Jxy (signed; 0.5 = zero)\njxx_s = t_r / strength;\njyy_s = t_b / strength;\ntrace = jxx_s + jyy_s;\ndiff = jxx_s - jyy_s;\nroot = sqrt(max(diff*diff + 4.0*jxy_s*jxy_s, 0.0));\nlambda1 = 0.5*(trace + root);\nlambda2 = 0.5*(trace - root);\ncoh = clamp(root / max(trace, eps_trace), 0.0, 1.0);\n// CAVEAT (idiom ADR-2): no atan2 here at all. The doubled-angle vector is\n// (diff, 2*jxy_s)/root; the kernel needs the HALF-angle axis:\n//   cos(theta) = sqrt((1 + diff/root)/2)\n//   sin(theta) = sign(2*jxy_s) * sqrt((1 - diff/root)/2)\n// (the theta+180 caveat from the idiom is inert: the kernel is bilateral.)\n\n// --- ADR-3 gates + the SPD/trace guard (NOT provisional) ------------------\n// lambda2 < -eps_spd -> 1 (a < b forms kept step(edge, x) = x >= edge):\nspd_bad2 = 1.0 - step(-eps_spd, lambda2);\nguard = max(spd_bad2, 1.0 - step(eps_trace, trace));\n// axis-undefined pixels (root ~ 0, e.g. lambda1 == lambda2) take D = L too\ndir_undef = 1.0 - step(eps_root, root);\n\nw_en = min(1.0, lambda1 * strength_scale);           // energy -> length\nl_len = max(length * w_en, 0.0);                     // px semi-length\nl_f = mix(l_len, max(length, 0.0), max(guard, 0.0)); // guard bypasses W\nd_calc = max(l_f * max(floor_pct, 1.0 - width_gate * coh), 0.0);\nd_f = mix(max(d_calc, 0.0), l_f, max(max(guard, dir_undef), 0.0));\n\n// circularity snap: D >= L means the pixel is isotropic BY MEASUREMENT;\n// drop the axis (fixed frame) so the fallback equals the isotropic\n// reference EXACTLY (tests/test_tf_aniso_blur.py, circ convention).\ncirc = step(0.999999, min(d_f / max(l_f, 1e-6), 1.0));\n\ninv_root = 1.0 / max(root, eps_root);\naxis_x = sqrt(max(1.0 + diff * inv_root, 0.0) * 0.5);\n// sign(2*jxy_s) with sign(0) -> + : GenExpr sign() at 0 returns 0, so:\ns_sign = 2.0*step(0.0, 2.0*jxy_s) - 1.0;\naxis_y = s_sign * sqrt(max(1.0 - diff * inv_root, 0.0) * 0.5);\n// along-edge axis: the perpendicular\nv_x = mix(-axis_y, 1.0, circ);\nv_y = mix(axis_x, 0.0, circ);\na_x = mix(axis_x, 0.0, circ);\na_y = mix(axis_y, 1.0, circ);\n\ninv_ll2 = 2.0 / max(l_f*l_f, 1e-12);        // 2/L^2, the along gaussian\nsig_d = max(0.5*d_f, 1e-6);                 // transverse sigma = D/2 px\nux_lo = 0.5/width; ux_hi = 1.0 - 0.5/width;\nuy_lo = 0.5/height; uy_hi = 1.0 - 0.5/height;\n\n// --- kernel: bounded loop, compile-time taps, weight-gated (cost scales\n//     with TAPS_MAX, not the dial -- say so in the docs) ------------------\nacc_r = 0.0; acc_g = 0.0; acc_b = 0.0; acc_a = 0.0; wsum = 0.0;\n\n// center tap (u = 0, t = 0, weight 1)\ncu_c = clamp(norm.x, ux_lo, ux_hi);\ncv_c = clamp(norm.y, uy_lo, uy_hi);\n// 2026-10-17 refactor (glyph's live finding, family rule 6b): c_m/s_m read\n// at CELL-COHERENT coordinates \u2014 constant within a cell, teleporting by\n// width/length texels at cell-boundary pixels \u2014 which drops the hardware\n// sampler to nearest there (silent, dim-dependent luck). The four-tap\n// nearest() hand-bilinear idiom is exact everywhere; costs 3.7x per read\n// (still trivial: ~0.2 ms/pass class recorded in the bench).\nc_tx = cu_c * width - 0.5;\nc_ty = cv_c * height - 0.5;\nc_ix = floor(c_tx);\nc_iy = floor(c_ty);\nc_ax = c_tx - c_ix;\nc_ay = c_ty - c_iy;\nc_x0 = clamp(c_ix, 0.0, width - 1.0);\nc_y0 = clamp(c_iy, 0.0, height - 1.0);\nc_x1 = clamp(c_ix + 1.0, 0.0, width - 1.0);\nc_y1 = clamp(c_iy + 1.0, 0.0, height - 1.0);\nc00 = nearest(in2, vec((c_x0 + 0.5) / width, (c_y0 + 0.5) / height));\nc10 = nearest(in2, vec((c_x1 + 0.5) / width, (c_y0 + 0.5) / height));\nc01 = nearest(in2, vec((c_x0 + 0.5) / width, (c_y1 + 0.5) / height));\nc11 = nearest(in2, vec((c_x1 + 0.5) / width, (c_y1 + 0.5) / height));\nc_r = c00.r * (1.0 - c_ax) * (1.0 - c_ay) + c10.r * c_ax * (1.0 - c_ay)\n    + c01.r * (1.0 - c_ax) * c_ay + c11.r * c_ax * c_ay;\nc_g = c00.g * (1.0 - c_ax) * (1.0 - c_ay) + c10.g * c_ax * (1.0 - c_ay)\n    + c01.g * (1.0 - c_ax) * c_ay + c11.g * c_ax * c_ay;\nc_b = c00.b * (1.0 - c_ax) * (1.0 - c_ay) + c10.b * c_ax * (1.0 - c_ay)\n    + c01.b * (1.0 - c_ax) * c_ay + c11.b * c_ax * c_ay;\nc_a = c00.a * (1.0 - c_ax) * (1.0 - c_ay) + c10.a * c_ax * (1.0 - c_ay)\n    + c01.a * (1.0 - c_ax) * c_ay + c11.a * c_ax * c_ay;\nacc_r = c_r; acc_g = c_g; acc_b = c_b; acc_a = c_a;\nwsum = 1.0;\n\n// stations k = 1..8 per side at u = +-(k-0.5) px; three transverse taps\nfor (kk = 0; kk < 2.0 * taps; kk += 1.0) {\n    // k = 1..taps; su = +1 then -1\n    k = floor(kk * 0.5) + 1.0;\n    su = 1.0 - 2.0 * mod(kk, 2.0);\n    umag = k - 0.5;\n    g_u = exp(-(umag*umag) * inv_ll2) / 1.0;   // 1 px station mass\n    for (ts = 0; ts < 3.0; ts += 1.0) {\n        // t = 0, +sig_d, -sig_d; weights 0.5 / 0.25 / 0.25\n        tsign = ts - 1.0;\n        tr_off = tsign * sig_d;                    // renamed: t was shadowed by the four-tap's t_px family, and GenExpr hoists one namespace\n        wgt = g_u * mix(0.25, 0.5, step(0.5, 1.0 - abs(tsign)));\n        // tap offset in px -> normalized units (1 px = 1/width, 1/height)\n        ox_norm = (umag*su*v_x + tr_off*a_x) / width;\n        oy_norm = (umag*su*v_y + tr_off*a_y) / height;\n        tap_u = clamp(norm.x + ox_norm, ux_lo, ux_hi);\n        tap_v = clamp(norm.y + oy_norm, uy_lo, uy_hi);\n        // four-tap idiom per tap (see the center-tap note above): within a\n        // cell the tap slides smoothly (norm + fixed ox), and at the 1-px\n        // cell-boundary bands the hardware sampler would drop to nearest\n        // (dim-luck). This keeps the parity with the mirror exact at any dim.\n        t_px = tap_u * width - 0.5;\n        t_py = tap_v * height - 0.5;\n        t_ix = floor(t_px);\n        t_iy = floor(t_py);\n        t_ax = t_px - t_ix;\n        t_ay = t_py - t_iy;\n        t_x0 = clamp(t_ix, 0.0, width - 1.0);\n        t_y0 = clamp(t_iy, 0.0, height - 1.0);\n        t_x1 = clamp(t_ix + 1.0, 0.0, width - 1.0);\n        t_y1 = clamp(t_iy + 1.0, 0.0, height - 1.0);\n        w00 = sample(in2, vec((t_x0 + 0.5) / width, (t_y0 + 0.5) / height));\n        w10 = sample(in2, vec((t_x1 + 0.5) / width, (t_y0 + 0.5) / height));\n        w01 = sample(in2, vec((t_x0 + 0.5) / width, (t_y1 + 0.5) / height));\n        w11 = sample(in2, vec((t_x1 + 0.5) / width, (t_y1 + 0.5) / height));\n        s_m_r = w00.r * (1.0 - t_ax) * (1.0 - t_ay) + w10.r * t_ax * (1.0 - t_ay)\n              + w01.r * (1.0 - t_ax) * t_ay + w11.r * t_ax * t_ay;\n        s_m_g = w00.g * (1.0 - t_ax) * (1.0 - t_ay) + w10.g * t_ax * (1.0 - t_ay)\n              + w01.g * (1.0 - t_ax) * t_ay + w11.g * t_ax * t_ay;\n        s_m_b = w00.b * (1.0 - t_ax) * (1.0 - t_ay) + w10.b * t_ax * (1.0 - t_ay)\n              + w01.b * (1.0 - t_ax) * t_ay + w11.b * t_ax * t_ay;\n        s_m_a = w00.a * (1.0 - t_ax) * (1.0 - t_ay) + w10.a * t_ax * (1.0 - t_ay)\n              + w01.a * (1.0 - t_ax) * t_ay + w11.a * t_ax * t_ay;\n        acc_r += wgt * s_m_r;\n        acc_g += wgt * s_m_g;\n        acc_b += wgt * s_m_b;\n        acc_a += wgt * s_m_a;\n        wsum += wgt;\n    }\n}\n\ninv_sum = 1.0 / max(wsum, 1e-6);\nout_r = acc_r * inv_sum;\nout_g = acc_g * inv_sum;\nout_b = acc_b * inv_sum;\nout_a = acc_a * inv_sum;\n\n// no clamp on the output values (smoother, not a coder; family hard rule).\n// bypass is exact passthrough of inlet 1:\nout1 = vec(mix(out_r, bp.r, bypass_gate),\n           mix(out_g, bp.g, bypass_gate),\n           mix(out_b, bp.b, bypass_gate),\n           mix(out_a, bp.a, bypass_gate));",
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
						216.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_aniso_blur_pix @adapt 0 @dim 256 256",
					"varname": "#0_aniso_blur_pix"
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
					"varname": "aniso_blur_autopattr"
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
						90.0
					],
					"presentation": 1,
					"presentation_rect": [
						0.0,
						0.0,
						190.0,
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
						92.0,
						21.0
					],
					"text": "Aniso Blur"
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
					"comment": "source (the content to smooth)",
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
					"hint": "Energy-to-length gate: W = min(1, lambda1 * this). Must be calibrated TOGETHER with tensormap's `strength` (the G-channel trap: the raw tensor's G carries Jxy*strength*0.5+0.5 -- the decode `strength` param below must match the value tensormap was dialed to). PROVISIONAL default 0.5 -- the T010 coupling measurement shows W saturates (full length) at lambda1 >= 2, typical at strength 100 on noise.",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_aniso_blur_pix::strength_scale",
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
							"parameter_longname": "strength_scale",
							"parameter_mmax": 2.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "strength_scale",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "strength_scale"
				}
			},
			{
				"box": {
					"id": "obj-21",
					"maxclass": "attrui",
					"attr": "strength_scale",
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
					"text": "Strength",
					"textjustification": 1,
					"varname": "lbl_strength_scale"
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
					"hint": "Kernel semi-length in pixels along the structure axis. 0 = no blur at all (identity). Range top 8 = TAPS_MAX 49 (1 + 2*8 stations * 3 transverse taps); PROVISIONAL -- tier-3 pending. COST SCALES WITH TAPS_MAX (the compile-time loop), NOT this dial: turning it down saves no frame time.",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_aniso_blur_pix::length",
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
								4.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "length",
							"parameter_mmax": 8.0,
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
					"id": "obj-24",
					"maxclass": "attrui",
					"attr": "length",
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
					"text": "Length",
					"textjustification": 1,
					"varname": "lbl_length"
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
					"hint": "Anisotropy gate: how much coherence the kernel transverse width responds to (w = max(floor, 1 - coherence * this)). 0 = always circular (anisotropy off); 1 = full coherence response. PROVISIONAL (tier-3).",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_aniso_blur_pix::width_gate",
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
								0.5
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "width_gate",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "width_gate",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "width_gate"
				}
			},
			{
				"box": {
					"id": "obj-27",
					"maxclass": "attrui",
					"attr": "width_gate",
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
					"text": "Width Gate",
					"textjustification": 1,
					"varname": "lbl_width_gate"
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
					"hint": "Width floor: the kernel keeps at least this fraction of isotropic smoothing everywhere, even at coherence 0 (prevents a visible no-blur seam in flat regions). 1 = fully isotropic everywhere. 0 = no smoothing where there is no structure (the painterly look). Named floor_pct on the wire (the GenExpr floor() operator collision). PROVISIONAL 0.25 (tier-3).",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_aniso_blur_pix::floor_pct",
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
								0.25
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "floor_pct",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "floor_pct",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "floor_pct"
				}
			},
			{
				"box": {
					"id": "obj-30",
					"maxclass": "attrui",
					"attr": "floor_pct",
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
					"text": "Floor",
					"textjustification": 1,
					"varname": "lbl_floor_pct"
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
					"hint": "The value tensormap's own `strength` dial is set to: the raw tensor's G channel is 0.5-offset encoded with that gain, so the decode needs it. Mismatches scale the decoded tensor by strength_tm/strength_here and thus the kernel length (measured in tasks.md T010). PROVISIONAL: OQ3 option (a), documented pairing.",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_aniso_blur_pix::strength",
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
								100.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "strength",
							"parameter_mmax": 1000.0,
							"parameter_mmin": 1.0,
							"parameter_modmode": 3,
							"parameter_exponent": 4.0,
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
					"id": "obj-33",
					"maxclass": "attrui",
					"attr": "strength",
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
					"text": "T-Map Strength",
					"textjustification": 1,
					"varname": "lbl_strength"
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
					"id": "obj-36",
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
				"strength_scale",
				"strength_scale",
				0
			],
			"obj-23": [
				"length",
				"length",
				0
			],
			"obj-26": [
				"width_gate",
				"width_gate",
				0
			],
			"obj-29": [
				"floor_pct",
				"floor_pct",
				0
			],
			"obj-32": [
				"strength",
				"strength",
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