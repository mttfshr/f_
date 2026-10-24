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
					"text": "route rate grain drive_gain sharp reset"
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
					"text": "jit.gl.pix vsynth @name #0_wc_hold @adapt 0 @dim 256 256 @type float32",
					"varname": "#0_wc_hold"
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
									"code": "// codebox_seed.gen -- f_wc noise stage: hash noise, deterministic per texel per salt.\n// 256x256 float32. Mirror: tests/modules/wc/wc_mirror.seed_state() (the seed channels);\n// noise_tex() (the per-frame field -- the Box-Muller happens downstream in the nl stage).\n//\n// Inputs: the first inlet is the `r draw` bang (unused; it only triggers the render every\n// frame). Packing: R = seed-E hash, G = seed-I hash (the pass stage reads these ONLY on the\n// frame reseed is 1: uniform [0, 1) per field, independent channels, never zero), B, A = the\n// two raw uniforms the nl stage turns into the per-frame Box-Muller noise (the load-bearing\n// mechanism, tasks.md T005).\n//   - `salt` increments EVERY FRAME (the `r draw` counter in the raw wiring), NOT just on\n//     reset like f_ks: the per-frame drive is what sustains the labyrinth\n//   - no sin(): a Hoskins-style arithmetic hash (fract and multiply-add only), whose\n//     precision does not depend on the GPU's sin() range reduction\n//   - scalars only: components are never read from a stored vec\n//   - never name a variable e or phi (predefined constants)\n//   - functions are declared before Param declarations (GenExpr rule)\nhashf(x, y) {\n\tha = fract(x * 0.1031);\n\thb = fract(y * 0.1031);\n\thc = ha;\n\thd = ha * (hb + 33.33) + hb * (hc + 33.33) + hc * (ha + 33.33);\n\tha = ha + hd;\n\thb = hb + hd;\n\thc = hc + hd;\n\treturn fract((ha + hb) * hc);\n}\n\nParam salt(0);\n\npx = floor(norm.x * 256);\npy = floor(norm.y * 256);\n\nsa = salt * 61;\nsb = salt * 17;\nse = hashf(px + sa, py + sb);\nsi = hashf(px + sa + 113.7, py + sb + 57.3);\nna = hashf(px + sa + 271.9, py + sb + 181.3);\nnb = hashf(px + sa + 401.1, py + sb + 333.7);\n\nout1 = vec(se, si, na, nb);\n",
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
					"text": "jit.gl.pix vsynth @name #0_wc_seed @adapt 0 @dim 256 256 @type float32",
					"varname": "#0_wc_seed"
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
									"code": "// codebox_pass.gen -- f_wc stage 0: holds last frame's state (E, I), or reseeds it.\n// 256x256 float32. Mirror: tests/modules/wc/wc_mirror.seed_state() (seeding); identity otherwise.\n//\n// Inputs: the first inlet is the `r draw` bang (unused; it only triggers the render every\n// frame, and the feedback arrives on a cold inlet so it cannot retrigger the loop), the second\n// is the feedback state (R = E, B = I, from the nl stage through the hold stage), the third is\n// the noise texture (R = seed-E hash, G = seed-I hash, from the noise stage).\n// reseed = 1 replaces the state with uniform noise in [0, amp): E from R, I from G (two\n// independent hash channels), never zero and never uniform rest (it is a fixed point of the\n// whole update, FR-004). reseed fires on load and on the reset trigger (FR-009).\n//   - SELF-HEAL: a feedback texel that is exactly 0 in BOTH channels is reseeded from the\n//     noise too. A live WC field never holds an exact 0 (E, I stay inside (0, 1): relaxation\n//     toward a sigmoid output), so this fires only when the state was lost: a fresh module, a\n//     GL context rebuilt by a window mode change, or a non-finite texel the nl stage zapped\n//   - selection uses switch(), not mix(): mix(NaN, x, 1) is still NaN, so a poisoned feedback\n//     texel could survive a reseed through mix\n//   - the feedback is NaN/Inf-guarded: abs(x) < 1e30 (NaN == NaN is TRUE on this GPU)\n//   - packing: R = E, B = I, G = A = 0 (G, A are the imaginary parts in the DFT chain; they\n//     MUST stay 0 here)\nParam reseed(0);\nParam amp(1);\n\nfbe = nearest(in2, norm).x;\nfbe = switch(abs(fbe) < 1e30, fbe, 0);\nfbi = nearest(in2, norm).z;\nfbi = switch(abs(fbi) < 1e30, fbi, 0);\nze = nearest(in3, norm).x * amp;\nzi = nearest(in3, norm).y * amp;\nlost = (fbe == 0) * (fbi == 0);\nkept_e = switch(lost > 0.5, ze, fbe);\nkept_i = switch(lost > 0.5, zi, fbi);\nout1 = vec(switch(reseed >= 0.5, ze, kept_e), 0, switch(reseed >= 0.5, zi, kept_i), 0);\n",
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
					"text": "jit.gl.pix vsynth @name #0_wc_pass @adapt 0 @dim 256 256 @type float32",
					"varname": "#0_wc_pass"
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
									"code": "// codebox_dft_fx.gen -- f_wc stage 1: forward DFT along x.\n// GENERATED by src/f_wc/gen_dft.py from f_vf_fluid's DFT template -- edit the template, not this file.\n// Mirror: tests/math/test_fft_separable.pass_dft(axis=\"x\", inverse=0).\n//\n// Packing (float32 RGBA): R,G = Re,Im of the field E; B,A = Re,Im of the field I (two complex fields per pass, one chain for both).\n// Carried findings (bench-verified 2026-09-22/23):\n//   - integer bin index is floor(norm * N), NOT `cell` (= norm*(dim-1) on jit.gl.pix)\n//   - nearest() at texel centers, twiddle index mod(k*n, N) before the angle\n//   - components accessed inline on nearest(), never on a stored vector\n//   - a NaN/Inf guard must use abs(x) < 1e30 (NaN == NaN is TRUE on this GPU)\n//   - no unary minus in front of a product/parenthesis: write `0 - ...` (GenExpr mis-parses it)\n\nN = 256;\nk = floor(norm.x * N);\n\nacc0 = 0;\nacc1 = 0;\nacc2 = 0;\nacc3 = 0;\n\nfor (n = 0; n < 256; n += 1) {\n\tuv = vec((n + 0.5) / N, norm.y);\n\tang = 0 - twopi * mod(k * n, N) / N;\n\tc = cos(ang);\n\ts = sin(ang);\n\tacc0 += nearest(in1, uv).x * c - nearest(in1, uv).y * s;\n\tacc1 += nearest(in1, uv).x * s + nearest(in1, uv).y * c;\n\tacc2 += nearest(in1, uv).z * c - nearest(in1, uv).w * s;\n\tacc3 += nearest(in1, uv).z * s + nearest(in1, uv).w * c;\n}\n\nout1 = vec(acc0, acc1, acc2, acc3);\n",
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
					"text": "jit.gl.pix vsynth @name #0_wc_fx @adapt 0 @dim 256 256 @type float32",
					"varname": "#0_wc_fx"
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
									"code": "// codebox_dft_fy.gen -- f_wc stage 2: forward DFT along y.\n// GENERATED by src/f_wc/gen_dft.py from f_vf_fluid's DFT template -- edit the template, not this file.\n// Mirror: tests/math/test_fft_separable.pass_dft(axis=\"y\", inverse=0).\n//\n// Packing (float32 RGBA): R,G = Re,Im of the field E; B,A = Re,Im of the field I (two complex fields per pass, one chain for both).\n// Carried findings (bench-verified 2026-09-22/23):\n//   - integer bin index is floor(norm * N), NOT `cell` (= norm*(dim-1) on jit.gl.pix)\n//   - nearest() at texel centers, twiddle index mod(k*n, N) before the angle\n//   - components accessed inline on nearest(), never on a stored vector\n//   - a NaN/Inf guard must use abs(x) < 1e30 (NaN == NaN is TRUE on this GPU)\n//   - no unary minus in front of a product/parenthesis: write `0 - ...` (GenExpr mis-parses it)\n\nN = 256;\nk = floor(norm.y * N);\n\nacc0 = 0;\nacc1 = 0;\nacc2 = 0;\nacc3 = 0;\n\nfor (n = 0; n < 256; n += 1) {\n\tuv = vec(norm.x, (n + 0.5) / N);\n\tang = 0 - twopi * mod(k * n, N) / N;\n\tc = cos(ang);\n\ts = sin(ang);\n\tacc0 += nearest(in1, uv).x * c - nearest(in1, uv).y * s;\n\tacc1 += nearest(in1, uv).x * s + nearest(in1, uv).y * c;\n\tacc2 += nearest(in1, uv).z * c - nearest(in1, uv).w * s;\n\tacc3 += nearest(in1, uv).z * s + nearest(in1, uv).w * c;\n}\n\nout1 = vec(acc0, acc1, acc2, acc3);\n",
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
					"text": "jit.gl.pix vsynth @name #0_wc_fy @adapt 0 @dim 256 256 @type float32",
					"varname": "#0_wc_fy"
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
									"code": "// codebox_spec.gen -- f_wc stage 3: the spectral step. TWO real per-bin Gaussian kernel\n// gains, ONE pass for both fields: KE = exp(-sig_e^2 k^2 / 2) multiplies the E pair (R,G),\n// KI = exp(-sig_i^2 k^2 / 2) the I pair (B,A). 256x256 float32.\n// Mirror: tests/modules/wc/wc_mirror.spec_stage().\n//\n// Input in1 = spectral texture (R,G = Re,Im of E-hat; B,A = Re,Im of I-hat).\n//   - sigma is in PIXELS: the domain IS texels, so k = 2*pi*signed_bin/N (L = N; angular\n//     units are load-bearing -- a cycles-unit k2 under-smooths the kernels by (2*pi)^2)\n//   - sig_e = texture / 1.45 (the Psychedelic 2/2.9 aspect ratio, slaved; FR-010)\n//   - NO decay multiplier and NO k = 0 (DC) zeroing -- both are KS-specific; the\n//     dt-relaxation in the nl stage carries the decay (FR-002, settled model)\n//   - there is no dt in this stage at all: dt only relaxes in nl (FR-003)\n//   - signed bin index from floor(norm * N), not `cell` (bench-verified 2026-09-22)\n//   - sig_i IS the user-facing `texture` dial, renamed here to avoid colliding with the\n//     GLSL `texture()` builtin (unverified at codegen time); the definition maps\n//     `texture` -> this Param (T025)\nParam sig_i(1.4);\n\nN = 256;\nbx = floor(norm.x * N);\nby = floor(norm.y * N);\nmx = switch(bx < N * 0.5, bx, bx - N);\nmy = switch(by < N * 0.5, by, by - N);\nkx = twopi / N * mx;\nky = twopi / N * my;\nk2 = kx * kx + ky * ky;\nse = sig_i / 1.45;\nge = exp(0 - 0.5 * se * se * k2);\ngi = exp(0 - 0.5 * sig_i * sig_i * k2);\n\nout1 = vec(nearest(in1, norm).x * ge, nearest(in1, norm).y * ge,\n           nearest(in1, norm).z * gi, nearest(in1, norm).w * gi);\n",
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
					"text": "jit.gl.pix vsynth @name #0_wc_spec @adapt 0 @dim 256 256 @type float32",
					"varname": "#0_wc_spec"
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
									"code": "// codebox_dft_iy.gen -- f_wc stage 4: inverse DFT along y.\n// GENERATED by src/f_wc/gen_dft.py from f_vf_fluid's DFT template -- edit the template, not this file.\n// Mirror: tests/math/test_fft_separable.pass_dft(axis=\"y\", inverse=1).\n//\n// Packing (float32 RGBA): R,G = Re,Im of the field E; B,A = Re,Im of the field I (two complex fields per pass, one chain for both).\n// Carried findings (bench-verified 2026-09-22/23):\n//   - integer bin index is floor(norm * N), NOT `cell` (= norm*(dim-1) on jit.gl.pix)\n//   - nearest() at texel centers, twiddle index mod(k*n, N) before the angle\n//   - components accessed inline on nearest(), never on a stored vector\n//   - a NaN/Inf guard must use abs(x) < 1e30 (NaN == NaN is TRUE on this GPU)\n//   - no unary minus in front of a product/parenthesis: write `0 - ...` (GenExpr mis-parses it)\n\nN = 256;\nk = floor(norm.y * N);\n\nacc0 = 0;\nacc1 = 0;\nacc2 = 0;\nacc3 = 0;\n\nfor (n = 0; n < 256; n += 1) {\n\tuv = vec(norm.x, (n + 0.5) / N);\n\tang = twopi * mod(k * n, N) / N;\n\tc = cos(ang);\n\ts = sin(ang);\n\tacc0 += nearest(in1, uv).x * c - nearest(in1, uv).y * s;\n\tacc1 += nearest(in1, uv).x * s + nearest(in1, uv).y * c;\n\tacc2 += nearest(in1, uv).z * c - nearest(in1, uv).w * s;\n\tacc3 += nearest(in1, uv).z * s + nearest(in1, uv).w * c;\n}\n\nout1 = vec(acc0, acc1, acc2, acc3) / N;\n",
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
					"text": "jit.gl.pix vsynth @name #0_wc_iy @adapt 0 @dim 256 256 @type float32",
					"varname": "#0_wc_iy"
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
									"code": "// codebox_dft_ix.gen -- f_wc stage 5: inverse DFT along x, real part + NaN/Inf guard.\n// GENERATED by src/f_wc/gen_dft.py from f_vf_fluid's DFT template -- edit the template, not this file.\n// Mirror: tests/math/test_fft_separable.pass_dft(axis=\"x\", inverse=1).\n//\n// Packing (float32 RGBA): R,G = Re,Im of the field E; B,A = Re,Im of the field I (two complex fields per pass, one chain for both).\n// Carried findings (bench-verified 2026-09-22/23):\n//   - integer bin index is floor(norm * N), NOT `cell` (= norm*(dim-1) on jit.gl.pix)\n//   - nearest() at texel centers, twiddle index mod(k*n, N) before the angle\n//   - components accessed inline on nearest(), never on a stored vector\n//   - a NaN/Inf guard must use abs(x) < 1e30 (NaN == NaN is TRUE on this GPU)\n//   - no unary minus in front of a product/parenthesis: write `0 - ...` (GenExpr mis-parses it)\n\nN = 256;\nk = floor(norm.x * N);\n\nacc0 = 0;\nacc1 = 0;\nacc2 = 0;\nacc3 = 0;\n\nfor (n = 0; n < 256; n += 1) {\n\tuv = vec((n + 0.5) / N, norm.y);\n\tang = twopi * mod(k * n, N) / N;\n\tc = cos(ang);\n\ts = sin(ang);\n\tacc0 += nearest(in1, uv).x * c - nearest(in1, uv).y * s;\n\tacc1 += nearest(in1, uv).x * s + nearest(in1, uv).y * c;\n\tacc2 += nearest(in1, uv).z * c - nearest(in1, uv).w * s;\n\tacc3 += nearest(in1, uv).z * s + nearest(in1, uv).w * c;\n}\n\n// inverse along x is the last transform: keep only the real parts (drops the\n// numerical imaginary residue every frame) and zap non-finite values, so a NaN\n// can never persist in the feedback loop.\nru = acc0 / N;\nrv = acc2 / N;\nru = switch(abs(ru) < 1e30, ru, 0);\nrv = switch(abs(rv) < 1e30, rv, 0);\nout1 = vec(ru, 0, rv, 0);\n",
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
					"text": "jit.gl.pix vsynth @name #0_wc_ix @adapt 0 @dim 256 256 @type float32",
					"varname": "#0_wc_ix"
				}
			},
			{
				"box": {
					"id": "obj-58",
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
									"code": "// codebox_nl.gen -- f_wc stage 6: the heart (the settled model, tasks.md T005/T007).\n// Exact relaxation toward the logistic sigmoid of the coupled drive, per frame:\n//   E += (F(AEE*cE - AIE*cI - HE + ne*nx + drive_gain*(drv - 0.5)) - E) * dt / TE\n//   I += (F(AEI*cE - AII*cI - HI + ne*nx) - I) * dt / TI\n// 256x256 float32. Mirror: tests/modules/wc/wc_mirror.nonlinear_step().\n//\n// Inputs (4): in1 = the convolved fields (R = KE conv E, B = KI conv I, from the ix stage),\n// in2 = the raw state (R = E, B = I, from the pass stage -- an extra tap off the feedback so\n// the relaxation target and the state are the same frame), in3 = the noise texture\n// (B, A = the two raw uniforms; fresh every frame -- the per-frame drive is the load-bearing\n// mechanism), in4 = the drive inlet (R; through a vs_inState, so UNCONNECTED reads vs_black\n// (0,0,0,1) -- the patcher sets drv_conn = 0 then, and the codebox falls back to the neutral\n// mid-gray 0.5: zero net drive for free, G3).\n//   - drv = the inlet reading when connected, 0.5 when not; the drive term is\n//     drive_gain*(drv - 0.5), E-only (T007: adding to I is identical but unnecessary)\n//   - fresh Gaussian noise into BOTH sigmoid inputs, Box-Muller from the two uniforms,\n//     sqrt(dt)-scaled (so dt stays a pure relaxation step), same nx in E and I (the Rule form)\n//   - constants are baked (settled Psychedelic corner): AEE 16.1, AIE 14.5, AEI 13.7,\n//     AII 13.0, HE 3.1, HI 3.5, TE 4, TI 12.5\n//   - NaN/Inf zap per the f_ks containment precedent (abs(x) < 1e30, NaN == NaN is TRUE);\n//     zapped texels are self-healed from noise by the pass stage\n//   - no unary minus before a parenthesis (GenExpr mis-parses it): write `0 - ...`\nParam dt(1);\nParam ne(1);\nParam drive_gain(0);\nParam drv_conn(0);\n\nce = nearest(in1, norm).x;\nci = nearest(in1, norm).z;\nee = nearest(in2, norm).x;\nii = nearest(in2, norm).z;\nna = nearest(in3, norm).z * 0.999 + 0.0001;\nnb = nearest(in3, norm).w * 0.999 + 0.0001;\nnx = sqrt(0 - 2 * log(na)) * cos(twopi * nb) * sqrt(dt);\ndrv = mix(0.5, nearest(in4, norm).x, drv_conn);\n\nae = 1 / (1 + exp(0 - clamp(16.1 * ce - 14.5 * ci - 3.1 + ne * nx + drive_gain * (drv - 0.5), -60, 60)));\nai = 1 / (1 + exp(0 - clamp(13.7 * ce - 13 * ci - 3.5 + ne * nx, -60, 60)));\n\nen = ee + (ae - ee) * (dt * 0.25);\ninw = ii + (ai - ii) * (dt * 0.08);\nen = switch(abs(en) < 1e30, en, 0);\ninw = switch(abs(inw) < 1e30, inw, 0);\n\nout1 = vec(en, 0, inw, 0);\n",
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
					"text": "jit.gl.pix vsynth @name #0_wc_nl @adapt 0 @dim 256 256 @type float32",
					"varname": "#0_wc_nl"
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
									"code": "// codebox_enc.gen -- f_wc stage 7: the inverse retinotopic resample. Maps each RENDER-res\n// output pixel's visual-field polar coords (r, theta) to cortical (u, v) =\n// (k_ecc*log(1 + r/r0), k_ang*theta) and samples the E field there, periodic in both\n// cortical axes. Runs at RENDER resolution (@adapt 0; FR-007/FR-013).\n// Mirror: tests/modules/wc/wc_mirror.encode(); record: tests/records/wc_retinotopy.py.\n//\n// Inputs: in1 = the `r draw` bang (not referenced here; it triggers every frame and gives\n// this pix the render-context size), in2 = the convolved/current state (R = E, from the nl\n// stage).\n//   - the cortical sample is a manual periodic 4-tap (the f_ks enc shape): exact at any\n//     output size, including smaller than 256 where hardware sample() would snap; v wraps at\n//     the theta seam, u at the far log edge\n//   - cortical convention (the record): u (eccentricity) = ROWS, v (angle) = COLUMNS\n//   - map constants are PROVISIONAL (T006's working set; the foveal/edge handling and any\n//     user exposure is T033): r0 = 0.5, k_ecc = 8, k_ang = 5, r_max = 4\n//   - display mapping PLACEHOLDER until gate G4: E is already a 0..1 rate, soft = clamp(E);\n//     sharp (0..1) blends toward the f_ks crisp S-curve (verified behavior is the default\n//     sharp = 0)\n//   - non-finite E maps to 0 (abs(x) < 1e30 guard: NaN == NaN is TRUE on this GPU)\n//   - bypass_gate = 1 outputs black with alpha 1 (the f_chladni generator convention); the\n//     solver keeps running upstream. The Param is never named `bypass` (native pix attribute)\nParam bypass_gate(0);\nParam sharp(0);\n\npx = (norm.x * 2 - 1) * 4;\npy = (norm.y * 2 - 1) * 4;\nr, theta = cartopol(px, py);\nu = 8 * log(1 + r / 0.5);\nv = 5 * theta;\ncu = fract(u / twopi);\ncv = fract(v / twopi);\n\nN = 256;\nfx = cv * N - 0.5;\nfy = cu * N - 0.5;\nx0 = floor(fx);\ny0 = floor(fy);\ntx = fx - x0;\nty = fy - y0;\nxa = wrap(x0, 0, N);\nxb = wrap(x0 + 1, 0, N);\nya = wrap(y0, 0, N);\nyb = wrap(y0 + 1, 0, N);\np00 = vec((xa + 0.5) / N, (ya + 0.5) / N);\np10 = vec((xb + 0.5) / N, (ya + 0.5) / N);\np01 = vec((xa + 0.5) / N, (yb + 0.5) / N);\np11 = vec((xb + 0.5) / N, (yb + 0.5) / N);\nau = mix(mix(nearest(in2, p00).x, nearest(in2, p10).x, tx),\n         mix(nearest(in2, p01).x, nearest(in2, p11).x, tx), ty);\n\nau = switch(abs(au) < 1e30, au, 0);\nsoft = clamp(au, 0, 1);\ncrisp = smoothstep(0.46, 0.54, soft);\nlum = mix(soft, crisp, sharp);\nlum = lum * (1 - bypass_gate);\n\nout1 = vec(lum, lum, lum, 1);\n",
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
						780.0,
						200.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_wc_enc @adapt 0 @type float32",
					"varname": "#0_wc_enc"
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
					"varname": "wc_autopattr"
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
						210.0,
						110.0
					],
					"presentation": 1,
					"presentation_rect": [
						0.0,
						0.0,
						210.0,
						110.0
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
					"text": "Wilson-Cowan"
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
					"hint": "Time step per frame (1 = the validated labyrinth tempo). No stability ceiling; the top is aesthetic",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_wc_nl::rate",
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
					"hint": "Grain: the inhibition kernel width in pixels. Low = broken stripes, high = disordered labyrinth",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_wc_spec::grain",
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
								1.4
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "grain",
							"parameter_mmax": 4.0,
							"parameter_mmin": 1.0,
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
					"attr": "sig_i",
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
					"text": "Texture",
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
					"hint": "Scene strength: 0 = pure hallucination; high = the drive inlet imprints (normal vision)",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_wc_nl::drive_gain",
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
					"id": "obj-27",
					"maxclass": "attrui",
					"attr": "drive_gain",
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
					"text": "Drive",
					"textjustification": 1,
					"varname": "lbl_drive_gain"
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
					"hint": "Edge sharpness: 0 = soft gradients, 1 = hard-edged cells and ridges",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_wc_enc::sharp",
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
					"id": "obj-30",
					"maxclass": "attrui",
					"attr": "sharp",
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
					"text": "Sharp",
					"textjustification": 1,
					"varname": "lbl_sharp"
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
					"id": "obj-raw-15",
					"maxclass": "newobj",
					"patching_rect": [
						330.0,
						942.0,
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
						190.0,
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
						179.0,
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
					"id": "obj-raw-4",
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
					"id": "obj-raw-5",
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
					"id": "obj-raw-7",
					"maxclass": "message",
					"patching_rect": [
						90.0,
						1042.0,
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
					"id": "obj-raw-11",
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
					"id": "obj-raw-6",
					"maxclass": "message",
					"patching_rect": [
						200.0,
						1072.0,
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
					"id": "obj-raw-13",
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
					"id": "obj-raw-14",
					"maxclass": "message",
					"patching_rect": [
						260.0,
						1132.0,
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
						1102.0,
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
						"obj-58",
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
						"obj-58",
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
						"obj-52",
						0
					],
					"destination": [
						"obj-58",
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
						"obj-58",
						2
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
						"obj-50",
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
						"obj-58",
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
						"obj-58",
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
						"obj-51",
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
						"obj-52",
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
				"drive_gain",
				"drive_gain",
				0
			],
			"obj-29": [
				"sharp",
				"sharp",
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