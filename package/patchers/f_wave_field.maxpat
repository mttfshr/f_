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
					"comment": "force texture (where) / control",
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
					"comment": "field (luma)",
					"index": 0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						30.0,
						852.0,
						30.0,
						30.0
					]
				}
			},
			{
				"box": {
					"id": "obj-201",
					"maxclass": "outlet",
					"comment": "gradient (vecfield)",
					"index": 0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						100.0,
						852.0,
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
					"text": "route speed damping dispersion ring edge force strength gain lmode strike reset"
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
					"text": "jit.gl.pix vsynth @name #0_wf_hold @adapt 0 @dim 256 256 @type float32",
					"varname": "#0_wf_hold"
				}
			},
			{
				"box": {
					"id": "obj-51",
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
									"code": "// codebox_pass.gen -- f_wave_field stage 0: holds last frame's state for the DFT chain, or clears it.\n// 256x256 float32. Mirror: tests/modules/wave_field/wave_field_mirror.wave_frame() (the texture handed to the\n// forward DFT: R = u, B = v, G = A = 0); reset is new_state().\n//\n// Inputs: the first inlet is the `r draw` bang (not referenced; it only triggers the render every frame, and the\n// feedback arrives on a cold inlet so it cannot retrigger the loop), the second is the feedback state from the\n// hold stage (R = u, B = v, G = strike counter, A = 1 + exciter phase; the real stage owns G and A).\n// reset_gate = 1 replaces the field with zeros (FR-009). The reset logic holds it for a few draws, and a cleared\n// field is a fixed point, so being applied on several frames does no harm.\n//   - the output has G = A = 0: the DFT template reads (R,G) and (B,A) as two complex fields, and the strike\n//     counter and phase riding in G and A must not enter it\n//   - the feedback is NaN/Inf-guarded: abs(x) < 1e30 (NaN == NaN is TRUE on this GPU), and selection uses\n//     switch(), not mix(): mix(NaN, x, 1) is still NaN\nParam reset_gate(0);\n\nfbu = nearest(in2, norm).x;\nfbv = nearest(in2, norm).z;\nfbu = switch(abs(fbu) < 1e30, fbu, 0);\nfbv = switch(abs(fbv) < 1e30, fbv, 0);\nkeep = switch(reset_gate >= 0.5, 0, 1);\nout1 = vec(fbu * keep, 0, fbv * keep, 0);\n",
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
					"text": "jit.gl.pix vsynth @name #0_wf_pass @adapt 0 @dim 256 256 @type float32",
					"varname": "#0_wf_pass"
				}
			},
			{
				"box": {
					"id": "obj-52",
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
									"code": "// codebox_dft_fx.gen -- f_wave_field stage 1: forward DFT along x.\n// GENERATED by src/f_wave_field/gen_dft.py from f_vf_fluid's DFT template -- edit the template, not this file.\n// Mirror: tests/math/test_fft_separable.pass_dft(axis=\"x\", inverse=0).\n//\n// Packing (float32 RGBA): R,G = Re,Im of u; B,A = Re,Im of v.\n// Carried findings (bench-verified 2026-09-22/23):\n//   - integer bin index is floor(norm * N), NOT `cell` (= norm*(dim-1) on jit.gl.pix)\n//   - nearest() at texel centers, twiddle index mod(k*n, N) before the angle\n//   - components accessed inline on nearest(), never on a stored vector\n//   - a NaN/Inf guard must use abs(x) < 1e30 (NaN == NaN is TRUE on this GPU)\n//   - no unary minus in front of a product/parenthesis: write `0 - ...` (GenExpr mis-parses it)\n\nN = 256;\nk = floor(norm.x * N);\n\nacc0 = 0;\nacc1 = 0;\nacc2 = 0;\nacc3 = 0;\n\nfor (n = 0; n < 256; n += 1) {\n\tuv = vec((n + 0.5) / N, norm.y);\n\tang = 0 - twopi * mod(k * n, N) / N;\n\tc = cos(ang);\n\ts = sin(ang);\n\tacc0 += nearest(in1, uv).x * c - nearest(in1, uv).y * s;\n\tacc1 += nearest(in1, uv).x * s + nearest(in1, uv).y * c;\n\tacc2 += nearest(in1, uv).z * c - nearest(in1, uv).w * s;\n\tacc3 += nearest(in1, uv).z * s + nearest(in1, uv).w * c;\n}\n\nout1 = vec(acc0, acc1, acc2, acc3);\n",
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
					"text": "jit.gl.pix vsynth @name #0_wf_fx @adapt 0 @dim 256 256 @type float32",
					"varname": "#0_wf_fx"
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
									"code": "// codebox_dft_fy.gen -- f_wave_field stage 2: forward DFT along y.\n// GENERATED by src/f_wave_field/gen_dft.py from f_vf_fluid's DFT template -- edit the template, not this file.\n// Mirror: tests/math/test_fft_separable.pass_dft(axis=\"y\", inverse=0).\n//\n// Packing (float32 RGBA): R,G = Re,Im of u; B,A = Re,Im of v.\n// Carried findings (bench-verified 2026-09-22/23):\n//   - integer bin index is floor(norm * N), NOT `cell` (= norm*(dim-1) on jit.gl.pix)\n//   - nearest() at texel centers, twiddle index mod(k*n, N) before the angle\n//   - components accessed inline on nearest(), never on a stored vector\n//   - a NaN/Inf guard must use abs(x) < 1e30 (NaN == NaN is TRUE on this GPU)\n//   - no unary minus in front of a product/parenthesis: write `0 - ...` (GenExpr mis-parses it)\n\nN = 256;\nk = floor(norm.y * N);\n\nacc0 = 0;\nacc1 = 0;\nacc2 = 0;\nacc3 = 0;\n\nfor (n = 0; n < 256; n += 1) {\n\tuv = vec(norm.x, (n + 0.5) / N);\n\tang = 0 - twopi * mod(k * n, N) / N;\n\tc = cos(ang);\n\ts = sin(ang);\n\tacc0 += nearest(in1, uv).x * c - nearest(in1, uv).y * s;\n\tacc1 += nearest(in1, uv).x * s + nearest(in1, uv).y * c;\n\tacc2 += nearest(in1, uv).z * c - nearest(in1, uv).w * s;\n\tacc3 += nearest(in1, uv).z * s + nearest(in1, uv).w * c;\n}\n\nout1 = vec(acc0, acc1, acc2, acc3);\n",
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
					"text": "jit.gl.pix vsynth @name #0_wf_fy @adapt 0 @dim 256 256 @type float32",
					"varname": "#0_wf_fy"
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
									"code": "// codebox_spec.gen -- f_wave_field stage 3: the exact per-bin step of  u_tt + 2 beta u_t + omega^2 u = 0.\n// 256x256 float32. Mirror: tests/modules/wave_field/wave_field_mirror.step_coeffs() and spec_stage().\n//\n// Input = spectral texture (R,G = Re,Im of u-hat; B,A = Re,Im of v-hat). Output: the same packing.\n//   omega^2 = ring^2 + (speed * kref * (|k| / kref)^dispersion)^2     beta = damping + nu |k|^2\n//   wd^2 = omega^2 - beta^2     x = wd^2 dt^2     E = exp(-beta dt)\n//   u' = Cc u + Cs (v + beta u)       v' = Cc v - Cs (omega^2 u + beta v)\n// Cc and Cs are E cos(a), E sin(a)/wd (x > T, underdamped, a = sqrt(x)); the cosh / sinh forms with E folded\n// into exp(a - beta dt) and exp(-beta dt - a) (x < -T, overdamped: float32 never forms cosh of a large\n// argument); and the Taylor series (|x| <= T, critical: no 0/0). The three are selected by switch() with SAFE\n// arguments in the unused branches (sqrt of 1, never of a negative), so no lane computes NaN.\n//   - constants (mirror names): kref = 2 pi 8, nu = 1e-5 (NU), T = 1e-4 (TAYLOR_X). dt is the per-frame step\n//     (gate G3: one draw = 1/60 model second); L = 1 frame width, k = 2 pi m for the signed bin index m\n//   - signed bin index from floor(norm * N), not `cell`; the upper half maps to index - N\n//   - the k = 0 (DC) bin of both fields is zeroed every frame (FR-005), by a 0/1 mask. The pow() base is\n//     floored at 1e-6 so the DC bin never computes pow(0, y); every other bin has |k| >= 2 pi\n//   - `damping` arrives already at or above its floor (the dial's minimum is the floor, T003: 1e-3)\n//   - unary minus before a parenthesis mis-parses in GenExpr: none is used here (\"0 - ...\" instead)\nParam speed(0.25);\nParam damping(0.2);\nParam dispersion(1);\nParam ring(0);\nParam dt(0.016666667);\n\nN = 256;\nbx = floor(norm.x * N);\nby = floor(norm.y * N);\nmx = switch(bx < N * 0.5, bx, bx - N);\nmy = switch(by < N * 0.5, by, by - N);\nkx = twopi * mx;\nky = twopi * my;\nkk = sqrt(kx * kx + ky * ky);\nkref = 50.265482;\ncph = speed * kref * pow(max(kk / kref, 0.000001), dispersion);\nom2 = ring * ring + cph * cph;\nbeta = damping + 0.00001 * kk * kk;\nwd2 = om2 - beta * beta;\nx = wd2 * dt * dt;\nbdt = beta * dt;\n\na_u = sqrt(switch(x > 0.0001, x, 1));\na_o = sqrt(switch(x < -0.0001, 0 - x, 1));\nee = exp(0 - bdt);\ncc_u = ee * cos(a_u);\ncs_u = ee * dt * sin(a_u) / a_u;\nem = exp(a_o - bdt);\nep = exp(0 - bdt - a_o);\ncc_o = 0.5 * (em + ep);\ncs_o = dt * 0.5 * (em - ep) / a_o;\ncc_c = ee * (1 - x * 0.5 + x * x * 0.041666667);\ncs_c = ee * dt * (1 - x * 0.16666667 + x * x * 0.0083333333);\ncc = switch(x > 0.0001, cc_u, switch(x < -0.0001, cc_o, cc_c));\ncs = switch(x > 0.0001, cs_u, switch(x < -0.0001, cs_o, cs_c));\n\ndcmask = switch(bx + by < 0.5, 0, 1);\n\nur = nearest(in1, norm).x;\nui = nearest(in1, norm).y;\nvr = nearest(in1, norm).z;\nvi = nearest(in1, norm).w;\n\nout1 = vec((cc * ur + cs * (vr + beta * ur)) * dcmask,\n           (cc * ui + cs * (vi + beta * ui)) * dcmask,\n           (cc * vr - cs * (om2 * ur + beta * vr)) * dcmask,\n           (cc * vi - cs * (om2 * ui + beta * vi)) * dcmask);\n",
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
						200.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_wf_spec @adapt 0 @dim 256 256 @type float32",
					"varname": "#0_wf_spec"
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
									"code": "// codebox_dft_iy.gen -- f_wave_field stage 4: inverse DFT along y.\n// GENERATED by src/f_wave_field/gen_dft.py from f_vf_fluid's DFT template -- edit the template, not this file.\n// Mirror: tests/math/test_fft_separable.pass_dft(axis=\"y\", inverse=1).\n//\n// Packing (float32 RGBA): R,G = Re,Im of u; B,A = Re,Im of v.\n// Carried findings (bench-verified 2026-09-22/23):\n//   - integer bin index is floor(norm * N), NOT `cell` (= norm*(dim-1) on jit.gl.pix)\n//   - nearest() at texel centers, twiddle index mod(k*n, N) before the angle\n//   - components accessed inline on nearest(), never on a stored vector\n//   - a NaN/Inf guard must use abs(x) < 1e30 (NaN == NaN is TRUE on this GPU)\n//   - no unary minus in front of a product/parenthesis: write `0 - ...` (GenExpr mis-parses it)\n\nN = 256;\nk = floor(norm.y * N);\n\nacc0 = 0;\nacc1 = 0;\nacc2 = 0;\nacc3 = 0;\n\nfor (n = 0; n < 256; n += 1) {\n\tuv = vec(norm.x, (n + 0.5) / N);\n\tang = twopi * mod(k * n, N) / N;\n\tc = cos(ang);\n\ts = sin(ang);\n\tacc0 += nearest(in1, uv).x * c - nearest(in1, uv).y * s;\n\tacc1 += nearest(in1, uv).x * s + nearest(in1, uv).y * c;\n\tacc2 += nearest(in1, uv).z * c - nearest(in1, uv).w * s;\n\tacc3 += nearest(in1, uv).z * s + nearest(in1, uv).w * c;\n}\n\nout1 = vec(acc0, acc1, acc2, acc3) / N;\n",
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
						200.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_wf_iy @adapt 0 @dim 256 256 @type float32",
					"varname": "#0_wf_iy"
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
									"code": "// codebox_dft_ix.gen -- f_wave_field stage 5: inverse DFT along x, real part + NaN/Inf guard.\n// GENERATED by src/f_wave_field/gen_dft.py from f_vf_fluid's DFT template -- edit the template, not this file.\n// Mirror: tests/math/test_fft_separable.pass_dft(axis=\"x\", inverse=1).\n//\n// Packing (float32 RGBA): R,G = Re,Im of u; B,A = Re,Im of v.\n// Carried findings (bench-verified 2026-09-22/23):\n//   - integer bin index is floor(norm * N), NOT `cell` (= norm*(dim-1) on jit.gl.pix)\n//   - nearest() at texel centers, twiddle index mod(k*n, N) before the angle\n//   - components accessed inline on nearest(), never on a stored vector\n//   - a NaN/Inf guard must use abs(x) < 1e30 (NaN == NaN is TRUE on this GPU)\n//   - no unary minus in front of a product/parenthesis: write `0 - ...` (GenExpr mis-parses it)\n\nN = 256;\nk = floor(norm.x * N);\n\nacc0 = 0;\nacc1 = 0;\nacc2 = 0;\nacc3 = 0;\n\nfor (n = 0; n < 256; n += 1) {\n\tuv = vec((n + 0.5) / N, norm.y);\n\tang = twopi * mod(k * n, N) / N;\n\tc = cos(ang);\n\ts = sin(ang);\n\tacc0 += nearest(in1, uv).x * c - nearest(in1, uv).y * s;\n\tacc1 += nearest(in1, uv).x * s + nearest(in1, uv).y * c;\n\tacc2 += nearest(in1, uv).z * c - nearest(in1, uv).w * s;\n\tacc3 += nearest(in1, uv).z * s + nearest(in1, uv).w * c;\n}\n\n// inverse along x is the last transform: keep only the real parts (drops the\n// numerical imaginary residue every frame) and zap non-finite values, so a NaN\n// can never persist in the feedback loop.\nru = acc0 / N;\nrv = acc2 / N;\nru = switch(abs(ru) < 1e30, ru, 0);\nrv = switch(abs(rv) < 1e30, rv, 0);\nout1 = vec(ru, 0, rv, 0);\n",
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
						680.0,
						200.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_wf_ix @adapt 0 @dim 256 256 @type float32",
					"varname": "#0_wf_ix"
				}
			},
			{
				"box": {
					"id": "obj-57",
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
									"code": "// codebox_real.gen -- f_wave_field stage 6: the real-space stage on the inverse-DFT result.\n// 256x256 float32. Mirror: tests/modules/wave_field/wave_field_mirror.real_stage().\n//\n// Inputs: first = the inverse DFT (R = u, B = v), second = the force texture (cold; the module's inlet 0 through\n// vs_inState: WHERE), third = last frame's state from the hold stage (cold), fourth = the LFO texture (cold; the\n// module's inlet 1 through its own vs_inState: WHEN). Output = the new solver state and the feedback edge:\n//   R = u, G = the hold texture's G carried through unchanged (unused), B = v, A = 1 (A held the exciter phase until the exciter was\n//   removed, 2026-11-04, D7)\n//   - connected flags (from vs_inState, via `prepend param`): src_force (inlet 0) and src_lfo (inlet 1). An unconnected\n//     inlet is vs_black = 0, which would decode to a full -1 force, so every read is gated on its flag. The gates use\n//     switch(), not multiplication, so a NaN in the unused branch cannot leak (0 * NaN). The flags lag ~180 ms at load\n//   - T (the LFO time function, T035) = the LFO's R channel per pixel, raw 0..1 (lmode 0, uni) or 2 x - 1 (lmode 1, bi,\n//     mid-grey neutral), and 1 when no LFO is connected. A uniform and a spatial LFO both work\n//   - force (FR-007): v += force * 2 (tex - 0.5) * T * dt, only with inlet 0 connected (mid-grey does nothing). With\n//     nothing on inlet 0 there is no push, whatever the LFO does. A uniform force only feeds the DC bin, which the spec\n//     stage removes\n//   - strike (FR-009; D11 / D12, T042): a held PRESS, not an impulse. While strike_gate is 1 (and reset_gate is 0) u is\n//     PINNED toward target = strength * amp * T with weight pw: u += pw (target - u), and v is killed where pinned,\n//     v *= 1 - pw. pw and amp are the OUTLINE mask of inlet 0 and 1 (OUTLINE_AMP) when it is connected, else the\n//     gaussian at the frame centre (0.5, 0.5; sigma 0.02, wrapped distance) and 4 (STRIKE_AMP). The pin REPLACES u at\n//     the pinned texels (a press on a ringing field does not add there; Matt, 2026-11-04) and is idempotent, so the old\n//     counter and the G memory are gone: a tap is a gate the patcher holds for a few draws. No gain constant: the\n//     amplitude is in field units. The outline mask is |I(x+1) - I(x-1), I(y+1) - I(y-1)| of the R channel of inlet 0,\n//     one solver texel either side, the neighbour's texel index clamped to 0..255 and read at its texel centre (never\n//     at a coordinate on or past the seam: out-of-range reads wrap, and nearest() there is unmeasured,\n//     tests/lib/gpu_sim.py; this equals the mirror's edge padding), result clamped to 0..1. Read with nearest() at the\n//     inlet's own resolution, so an inlet smaller than 256 gives a band about two solver texels wide at each of ITS\n//     texel boundaries (checked live in T034, not in the mirror). While reset_gate is on the pin waits. Param named\n//     strike_gate, not gate: `gate` is a Gen operator name (the same clash as `edge`). The hold texture is still read\n//     (in3) and its G written back, so the inlet count and wiring stay put; nothing uses that G. in3 is now dead weight:\n//     it is the reason this stage has FOUR inputs, which the codebox bench (three inputs at most) cannot drive\n//   - sponge (FR-010): exp(-rate dt) on u and v, rate = edge_amt * 20 (SPONGE_RATE) * smoothstep profile over the\n//     border band of width 0.12 (SPONGE_WIDTH). edge 0 leaves the periodic wrap\n//   - containment: non-finite / huge values zapped to 0 (abs(x) < 1e30), then clamped to +-100 (U_CAP)\n//   - Param names: never a one-letter name (`t` was silently never applied); `edge_amt` (`edge` is\n//     a Gen operator name; the dial and the message keep the plain word `edge`)\nParam dt(0.016666667);\nParam force(1);\nParam strength(1);\nParam lmode(0);\nParam src_force(0);\nParam src_lfo(0);\nParam edge_amt(0);\nParam strike_gate(0);\nParam reset_gate(0);\n\ndx = norm.x - 0.5;\ndy = norm.y - 0.5;\ndx = dx - floor(dx + 0.5);\ndy = dy - floor(dy + 0.5);\nprof = exp(0 - (dx * dx + dy * dy) / 0.0008);\n\nholdg = nearest(in3, norm).y;\nholdg = switch(abs(holdg) < 1e30, holdg, 0);\n\nuu = nearest(in1, norm).x;\nvv = nearest(in1, norm).z;\n\nconn = switch(src_force > 0.5, 1, 0);\nlraw = nearest(in4, norm).x;\ntt = switch(src_lfo > 0.5, mix(lraw, lraw * 2 - 1, lmode), 1);\n\nff = switch(conn > 0.5, force * 2 * (nearest(in2, norm).x - 0.5) * tt, 0);\nvv = vv + ff * dt;\n\ncxi = floor(norm.x * 256);\ncyi = floor(norm.y * 256);\nxr = (min(cxi + 1, 255) + 0.5) / 256;\nxl = (max(cxi - 1, 0) + 0.5) / 256;\nyu = (min(cyi + 1, 255) + 0.5) / 256;\nyd = (max(cyi - 1, 0) + 0.5) / 256;\ngx = nearest(in2, vec(xr, norm.y)).x - nearest(in2, vec(xl, norm.y)).x;\ngy = nearest(in2, vec(norm.x, yu)).x - nearest(in2, vec(norm.x, yd)).x;\nomask = clamp(sqrt(gx * gx + gy * gy), 0, 1);\n\npinon = switch(strike_gate > 0.5, 1, 0) * switch(reset_gate < 0.5, 1, 0);\npw = pinon * switch(conn > 0.5, omask, prof);\nptarget = strength * switch(conn > 0.5, 1, 4) * tt;\nuu = uu + pw * (ptarget - uu);\nvv = vv * (1 - pw);\n\nedist = min(min(norm.x, 1 - norm.x), min(norm.y, 1 - norm.y));\nsp = clamp(1 - edist / 0.12, 0, 1);\nsprate = edge_amt * 20 * sp * sp * (3 - 2 * sp);\ngs = exp(0 - sprate * dt);\nuu = uu * gs;\nvv = vv * gs;\n\nuu = switch(abs(uu) < 1e30, uu, 0);\nvv = switch(abs(vv) < 1e30, vv, 0);\nuu = clamp(uu, -100, 100);\nvv = clamp(vv, -100, 100);\n\nout1 = vec(uu, holdg, vv, 1);\n",
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
						730.0,
						200.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_wf_real @adapt 0 @dim 256 256 @type float32",
					"varname": "#0_wf_real"
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
									"code": "// codebox_enc.gen -- f_wave_field stage 7: encode the 256x256 state at the RENDER resolution, two outlets.\n// Mirror: tests/modules/wave_field/wave_field_mirror.encode_luma() / encode_vec() at the solver resolution, then\n// a periodic bilinear upsample (exact at 1:1).\n//\n// Inputs: first = the `r draw` bang (not referenced; it triggers every frame and gives this pix the render\n// size), second = the state (R = u, from the real stage; cold).\n// Outlets: the first is the luma map, the second is the gradient vecfield.\n//   - G2 (Matt, 2026-10-25): tanh compression, no clamp. luma = 0.5 + 0.5 tanh(gain * 0.5 * u) (LUMA_SCALE 0.5);\n//     vecfield R,G = 0.5 + 0.5 tanh(gain * 0.05 * grad u) (GRAD_SCALE 0.05), B = 0.5, A = 1 (f_vecfield_type)\n//   - grad u = central difference over one texel either side with integer wrap, times N / 2 (L = 1 frame\n//     width); the mapped values at the four surrounding solver texels are blended bilinearly (a manual periodic\n//     4-tap on nearest(): hardware sample() would snap when the output is smaller than 256)\n//   - bypass_gate = 1 (module bypass, never the native @bypass): the first outlet is black with alpha 1, the\n//     second is the neutral vecfield 0.5 / 0.5 / 0.5 / 1; the solver keeps running upstream\n//   - non-finite u maps to 0 (abs(x) < 1e30 guard: NaN == NaN is TRUE on this GPU)\n// Functions come before the Params and do not see them: gain is an argument.\nlum_at(xi, yi, g) {\n    uv = nearest(in2, vec((xi + 0.5) / 256, (yi + 0.5) / 256)).x;\n    uv = switch(abs(uv) < 1e30, uv, 0);\n    return 0.5 + 0.5 * tanh(g * 0.5 * uv);\n}\n\nvx_at(xi, yi, g) {\n    xp = (wrap(xi + 1, 0, 256) + 0.5) / 256;\n    xm = (wrap(xi - 1, 0, 256) + 0.5) / 256;\n    yc = (yi + 0.5) / 256;\n    ga = (nearest(in2, vec(xp, yc)).x - nearest(in2, vec(xm, yc)).x) * 128;\n    ga = switch(abs(ga) < 1e30, ga, 0);\n    return 0.5 + 0.5 * tanh(g * 0.05 * ga);\n}\n\nvy_at(xi, yi, g) {\n    yp = (wrap(yi + 1, 0, 256) + 0.5) / 256;\n    ym = (wrap(yi - 1, 0, 256) + 0.5) / 256;\n    xc = (xi + 0.5) / 256;\n    gb = (nearest(in2, vec(xc, yp)).x - nearest(in2, vec(xc, ym)).x) * 128;\n    gb = switch(abs(gb) < 1e30, gb, 0);\n    return 0.5 + 0.5 * tanh(g * 0.05 * gb);\n}\n\nParam gain(1);\nParam bypass_gate(0);\n\nfx = norm.x * 256 - 0.5;\nfy = norm.y * 256 - 0.5;\nx0 = floor(fx);\ny0 = floor(fy);\ntx = fx - x0;\nty = fy - y0;\nxa = wrap(x0, 0, 256);\nxb = wrap(x0 + 1, 0, 256);\nya = wrap(y0, 0, 256);\nyb = wrap(y0 + 1, 0, 256);\n\nlum = mix(mix(lum_at(xa, ya, gain), lum_at(xb, ya, gain), tx), mix(lum_at(xa, yb, gain), lum_at(xb, yb, gain), tx), ty);\nvxo = mix(mix(vx_at(xa, ya, gain), vx_at(xb, ya, gain), tx), mix(vx_at(xa, yb, gain), vx_at(xb, yb, gain), tx), ty);\nvyo = mix(mix(vy_at(xa, ya, gain), vy_at(xb, ya, gain), tx), mix(vy_at(xa, yb, gain), vy_at(xb, yb, gain), tx), ty);\n\nkeep = 1 - bypass_gate;\nout1 = vec(lum * keep, lum * keep, lum * keep, 1);\nout2 = vec(mix(vxo, 0.5, bypass_gate), mix(vyo, 0.5, bypass_gate), 0.5, 1);\n",
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
						780.0,
						200.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_wf_enc @adapt 1 @type float32",
					"varname": "#0_wf_enc"
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
					"varname": "wf_autopattr"
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
						232.0
					],
					"presentation": 1,
					"presentation_rect": [
						0.0,
						0.0,
						190.0,
						232.0
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
					"text": "Wave Field"
				}
			},
			{
				"box": {
					"id": "obj-8",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 11.0,
					"textcolor": [
						0.35,
						0.75,
						0.95,
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
					"text": "\u2207 out"
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
						0.35,
						0.75,
						0.95,
						1.0
					],
					"border": 0,
					"mode": 0,
					"hint": "Outputs: vecfield",
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
					"id": "obj-18",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						30.0,
						150.0,
						151.79999999999998,
						22.0
					],
					"text": "prepend param src_force"
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
					"comment": "LFO texture (when)",
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
					"text": "prepend param src_lfo"
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
					"hint": "Wave speed: how fast ripples cross the frame (frame widths per second at the middle scale). 0 with Ring makes a field of independent resonators",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_wf_spec::speed",
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
								0.25
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "speed",
							"parameter_mmax": 0.5,
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
					"id": "obj-21",
					"maxclass": "attrui",
					"attr": "speed",
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
					"text": "Speed",
					"textjustification": 1,
					"varname": "lbl_speed"
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
					"hint": "How fast waves die out. The bottom of the range is a tiny floor, so the field always settles eventually; high values go thick and syrupy",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_wf_spec::damping",
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
								0.2
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "damping",
							"parameter_mmax": 5.0,
							"parameter_mmin": 0.001,
							"parameter_modmode": 3,
							"parameter_shortname": "damping",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "damping"
				}
			},
			{
				"box": {
					"id": "obj-24",
					"maxclass": "attrui",
					"attr": "damping",
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
					"text": "Damp",
					"textjustification": 1,
					"varname": "lbl_damping"
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
					"hint": "How wavelength sets speed: 1 = ordinary waves (a clean ring), 2 = a plate (short ripples run ahead of long ones), 0.5 = long swells outrun short ripples",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_wf_spec::dispersion",
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
							"parameter_longname": "dispersion",
							"parameter_mmax": 2.0,
							"parameter_mmin": 0.5,
							"parameter_modmode": 3,
							"parameter_shortname": "dispersion",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "dispersion"
				}
			},
			{
				"box": {
					"id": "obj-27",
					"maxclass": "attrui",
					"attr": "dispersion",
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
					"text": "Disp",
					"textjustification": 1,
					"varname": "lbl_dispersion"
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
					"hint": "A tone every point rings at on its own, whatever the wavelength. With Speed 0 the sheet becomes independent resonators",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_wf_spec::ring",
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
							"parameter_longname": "ring",
							"parameter_mmax": 50.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "ring",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "ring"
				}
			},
			{
				"box": {
					"id": "obj-30",
					"maxclass": "attrui",
					"attr": "ring",
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
					"text": "Ring",
					"textjustification": 1,
					"varname": "lbl_ring"
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
					"hint": "Absorbing borders: 0 = waves wrap around to the opposite side, higher = they die at the edge without reflecting",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_wf_real::edge",
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
								0.5
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "edge",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "edge",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "edge"
				}
			},
			{
				"box": {
					"id": "obj-33",
					"maxclass": "attrui",
					"attr": "edge_amt",
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
					"text": "Edge",
					"textjustification": 1,
					"varname": "lbl_edge"
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
					"hint": "How hard the texture on inlet 0 pushes the field: mid-grey does nothing, brighter pushes up, darker pushes down. Past 1 it boosts a dim texture. An LFO on inlet 1 makes the push pulse",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_wf_real::force",
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
								1.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "force",
							"parameter_mmax": 1.5,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "force",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "force"
				}
			},
			{
				"box": {
					"id": "obj-36",
					"maxclass": "attrui",
					"attr": "force",
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
					"text": "Force",
					"textjustification": 1,
					"varname": "lbl_force"
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
					"hint": "How hard Strike hits: on the outlines of the texture on inlet 0, or at the frame centre with nothing connected. 0 = no strike. An LFO on inlet 1 shapes the pulse",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_wf_real::strength",
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
							"parameter_longname": "strength",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
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
					"id": "obj-39",
					"maxclass": "attrui",
					"attr": "strength",
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
					"text": "Strength",
					"textjustification": 1,
					"varname": "lbl_strength"
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
					"hint": "Output strength before the soft tanh limiter: raise it to see quiet waves, lower it for big ones",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_wf_enc::gain",
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
							"parameter_longname": "gain",
							"parameter_mmax": 10.0,
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
					"id": "obj-42",
					"maxclass": "attrui",
					"attr": "gain",
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
					"text": "Gain",
					"textjustification": 1,
					"varname": "lbl_gain"
				}
			},
			{
				"box": {
					"id": "obj-44",
					"maxclass": "live.text",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"hint": "How the LFO on inlet 1 is read. LFO uni = raw 0..1 (can only add). LFO bi = rescaled to -1..1 (mid-grey = nothing, dark pulls the other way). Modelled on f_weave's Mod mode",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"param_connect": "#0_wf_real::lmode",
					"parameter_enable": 1,
					"patching_rect": [
						609.0,
						250.0,
						53.5,
						17.0
					],
					"presentation": 1,
					"presentation_rect": [
						111.0,
						114.0,
						53.5,
						17.0
					],
					"text": "LFO uni",
					"texton": "LFO bi",
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
								"LFO uni",
								"LFO bi"
							],
							"parameter_initial": [
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "lmode",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 0,
							"parameter_shortname": "lmode",
							"parameter_type": 1,
							"parameter_unitstyle": 0
						}
					},
					"varname": "lmode"
				}
			},
			{
				"box": {
					"id": "obj-45",
					"maxclass": "attrui",
					"attr": "lmode",
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
					"id": "obj-47",
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
					"id": "obj-48",
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
					"id": "obj-raw-1",
					"maxclass": "button",
					"patching_rect": [
						90.0,
						942.0,
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
						115.0,
						186.0,
						28.0,
						28.0
					],
					"varname": "reset_button",
					"hint": "Clear the field"
				}
			},
			{
				"box": {
					"id": "obj-raw-2",
					"maxclass": "comment",
					"patching_rect": [
						90.0,
						968.0,
						50.0,
						18.0
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"presentation": 1,
					"presentation_rect": [
						104.0,
						164.0,
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
					"id": "obj-raw-18",
					"maxclass": "panel",
					"patching_rect": [
						30.0,
						942.0,
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
						78.0,
						186.0,
						28.0,
						28.0
					],
					"varname": "strike_face"
				}
			},
			{
				"box": {
					"id": "obj-raw-3",
					"maxclass": "ubutton",
					"patching_rect": [
						30.0,
						942.0,
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
						78.0,
						186.0,
						28.0,
						28.0
					],
					"varname": "strike_button",
					"hint": "Hold to strike: pins the outlines of the inlet texture (or the frame centre with nothing connected) while held; release lets the waves ring out"
				}
			},
			{
				"box": {
					"id": "obj-raw-4",
					"maxclass": "comment",
					"patching_rect": [
						30.0,
						968.0,
						50.0,
						18.0
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"presentation": 1,
					"presentation_rect": [
						67.0,
						164.0,
						50.0,
						18.0
					],
					"text": "Strike",
					"textjustification": 1,
					"varname": "lbl_strike"
				}
			},
			{
				"box": {
					"id": "obj-raw-5",
					"maxclass": "newobj",
					"patching_rect": [
						90.0,
						1002.0,
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
					"id": "obj-raw-6",
					"maxclass": "newobj",
					"patching_rect": [
						200.0,
						952.0,
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
					"id": "obj-raw-7",
					"maxclass": "newobj",
					"patching_rect": [
						200.0,
						977.0,
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
					"id": "obj-raw-8",
					"maxclass": "message",
					"patching_rect": [
						150.0,
						1042.0,
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
					"id": "obj-raw-9",
					"maxclass": "message",
					"patching_rect": [
						90.0,
						1042.0,
						100.0,
						22.0
					],
					"text": "param reset_gate 1",
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
						260.0,
						1042.0,
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
					"id": "obj-raw-13",
					"maxclass": "newobj",
					"patching_rect": [
						260.0,
						1072.0,
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
					"id": "obj-raw-14",
					"maxclass": "newobj",
					"patching_rect": [
						300.0,
						1102.0,
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
					"id": "obj-raw-15",
					"maxclass": "newobj",
					"patching_rect": [
						260.0,
						1102.0,
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
					"id": "obj-raw-16",
					"maxclass": "message",
					"patching_rect": [
						260.0,
						1132.0,
						100.0,
						22.0
					],
					"text": "param reset_gate 0",
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
						30.0,
						1172.0,
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
					"id": "obj-raw-24",
					"maxclass": "newobj",
					"patching_rect": [
						30.0,
						1207.0,
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
					"id": "obj-raw-19",
					"maxclass": "newobj",
					"patching_rect": [
						90.0,
						1242.0,
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
					"id": "obj-raw-22",
					"maxclass": "message",
					"patching_rect": [
						30.0,
						1277.0,
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
					"id": "obj-raw-21",
					"maxclass": "message",
					"patching_rect": [
						90.0,
						1277.0,
						120.0,
						22.0
					],
					"text": "param strike_gate 1",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					]
				}
			},
			{
				"box": {
					"id": "obj-raw-20",
					"maxclass": "message",
					"patching_rect": [
						230.0,
						1277.0,
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
					"id": "obj-raw-25",
					"maxclass": "newobj",
					"patching_rect": [
						300.0,
						1172.0,
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
					"id": "obj-raw-26",
					"maxclass": "newobj",
					"patching_rect": [
						340.0,
						1202.0,
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
					"id": "obj-raw-27",
					"maxclass": "newobj",
					"patching_rect": [
						300.0,
						1232.0,
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
					"id": "obj-raw-23",
					"maxclass": "message",
					"patching_rect": [
						300.0,
						1262.0,
						120.0,
						22.0
					],
					"text": "param strike_gate 0",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					]
				}
			},
			{
				"box": {
					"id": "obj-raw-31",
					"maxclass": "message",
					"patching_rect": [
						380.0,
						1002.0,
						30.0,
						22.0
					],
					"text": "1",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					]
				}
			},
			{
				"box": {
					"id": "obj-raw-28",
					"maxclass": "newobj",
					"patching_rect": [
						380.0,
						1042.0,
						50.0,
						22.0
					],
					"text": "spigot",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					]
				}
			},
			{
				"box": {
					"id": "obj-raw-29",
					"maxclass": "newobj",
					"patching_rect": [
						380.0,
						1072.0,
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
					"id": "obj-raw-30",
					"maxclass": "message",
					"patching_rect": [
						420.0,
						1102.0,
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
						"obj-57",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-17",
						1
					],
					"destination": [
						"obj-18",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-18",
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
						"obj-57",
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
						"obj-57",
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
						0
					],
					"destination": [
						"obj-57",
						2
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
						"obj-50",
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
						"obj-54",
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
						"obj-54",
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
						"obj-57",
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
						"obj-57",
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
						"obj-57",
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
						"obj-57",
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
						"obj-raw-10",
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
						"obj-raw-5",
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
						"obj-raw-5",
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
						"obj-raw-19",
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
						"obj-raw-22",
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
						"obj-raw-24",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-10",
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
						"obj-raw-10",
						2
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
						"obj-raw-24",
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
						"obj-raw-24",
						0
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
						"obj-raw-19",
						1
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
						"obj-raw-25",
						1
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
						"obj-raw-21",
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
						"obj-57",
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
						"obj-raw-25",
						1
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
						"obj-raw-25",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-25",
						0
					],
					"destination": [
						"obj-raw-26",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-26",
						0
					],
					"destination": [
						"obj-raw-25",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-25",
						0
					],
					"destination": [
						"obj-raw-27",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-27",
						0
					],
					"destination": [
						"obj-raw-23",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-23",
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
						"obj-raw-6",
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
						"obj-raw-6",
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
						"obj-raw-5",
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
						"obj-raw-19",
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
						"obj-raw-31",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-31",
						0
					],
					"destination": [
						"obj-raw-28",
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
						"obj-raw-28",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-28",
						0
					],
					"destination": [
						"obj-raw-29",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-29",
						1
					],
					"destination": [
						"obj-raw-30",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-30",
						0
					],
					"destination": [
						"obj-raw-28",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-29",
						0
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
						"obj-raw-5",
						1
					],
					"destination": [
						"obj-raw-8",
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
						"obj-raw-13",
						1
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
						"obj-51",
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
						"obj-57",
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
						"obj-raw-13",
						1
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
						"obj-raw-15",
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
						"obj-51",
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
						"obj-57",
						0
					]
				}
			}
		],
		"parameters": {
			"obj-20": [
				"speed",
				"speed",
				0
			],
			"obj-23": [
				"damping",
				"damping",
				0
			],
			"obj-26": [
				"dispersion",
				"dispersion",
				0
			],
			"obj-29": [
				"ring",
				"ring",
				0
			],
			"obj-32": [
				"edge",
				"edge",
				0
			],
			"obj-35": [
				"force",
				"force",
				0
			],
			"obj-38": [
				"strength",
				"strength",
				0
			],
			"obj-41": [
				"gain",
				"gain",
				0
			],
			"obj-44": [
				"lmode",
				"lmode",
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