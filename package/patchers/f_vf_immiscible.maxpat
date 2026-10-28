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
					"comment": "control / phi source texture",
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
					"comment": "phi (grey scalar)",
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
					"comment": "blended velocity vecfield",
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
					"text": "route dt iface coarsen inject fill freeze taps reset"
				}
			},
			{
				"box": {
					"id": "obj-50",
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
									"code": "// codebox_inab.gen -- f_vf_immiscible stage 0: decode, content-gate and minify BOTH upstream velocity\n// vecfields onto the 256x256 solver grid, packed into one texture. Mirror: immiscible_mirror.inab().\n//\n// Inputs (jit.gl.pix inlets): in1 = `r draw` bang (unused; it only triggers the render every frame),\n// in2 = velocity vecfield A at render resolution (via vs_inState), in3 = velocity vecfield B (same).\n// Output: R,G = uA.x,uA.y   B,A = uB.x,uB.y   in decoded f_vecfield units (p - 0.5) * 2.\n// An unconnected or invalid input reads as ZERO velocity.\n//   - gate per input = (src flag >= 0.5) * (|B - 0.5| < 0.25 at the single centre tap). A real\n//     f_vecfield has B = 0.5 (contract); vs_black is all zeros, which would decode as -1. vs_inState's\n//     connected flag lags at load/disconnect, so the content check is needed as well (f_vf_fluid, 2026-09-23)\n//   - TAP GRID: each input is averaged over a taps x taps grid of hardware sample() taps spread across the\n//     solver texel's footprint, offsets in NORMALIZED coordinates (a codebox cannot read a texture's size).\n//     Same scheme and findings as f_vf_fluid's force taps (T038a). Cost ~ 4 taps^2 fetches per texel\n//   - components are accessed inline on sample(), never on a stored vec\n//   - never name a Param `bypass`; src_a / src_b are the vs_inState flags\nParam taps(2);\nParam src_a(0);\nParam src_b(0);\n\nN = 256;\ngate_a = switch(src_a >= 0.5, 1, 0) * switch(abs(sample(in2, norm).z - 0.5) < 0.25, 1, 0);\ngate_b = switch(src_b >= 0.5, 1, 0) * switch(abs(sample(in3, norm).z - 0.5) < 0.25, 1, 0);\n\ntn = max(1, floor(taps));\nsax = 0;\nsay = 0;\nsbx = 0;\nsby = 0;\nfor (a = 0; a < tn; a += 1) {\n  ox = ((a + 0.5) / tn - 0.5) / N;\n  for (b = 0; b < tn; b += 1) {\n    oy = ((b + 0.5) / tn - 0.5) / N;\n    sax += sample(in2, vec(norm.x + ox, norm.y + oy)).x;\n    say += sample(in2, vec(norm.x + ox, norm.y + oy)).y;\n    sbx += sample(in3, vec(norm.x + ox, norm.y + oy)).x;\n    sby += sample(in3, vec(norm.x + ox, norm.y + oy)).y;\n  }\n}\nnt = tn * tn;\nout1 = vec((sax / nt - 0.5) * 2 * gate_a, (say / nt - 0.5) * 2 * gate_a, (sbx / nt - 0.5) * 2 * gate_b, (sby / nt - 0.5) * 2 * gate_b);\n",
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
						380.0,
						200.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_imm_inab @adapt 0 @dim 256 256 @type float32",
					"varname": "#0_imm_inab"
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
						730.0,
						200.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_imm_hold @adapt 0 @dim 256 256 @type float32",
					"varname": "#0_imm_hold"
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
									"code": "// codebox_pass.gen -- f_vf_immiscible stage 2: holds last frame's phi, or reseeds it. 256x256 float32.\n// Mirror: immiscible_mirror.pass_stage() and hash01().\n//\n// Inputs: in1 = `r draw` bang (unused; it only triggers the render every frame and rides the HOT inlet,\n// the feedback arrives on a cold inlet so it cannot retrigger the loop), in2 = the held state from the\n// `hold` stage (R = phi).\n// Output: R = phi; G, B, A = 0.\n// reseed = 1 replaces phi with fill + amp * (2h - 1), h an arithmetic hash of the texel index and `salt`\n// (no sin(): fract and multiply-add only, so precision does not depend on the GPU's sin range reduction).\n//   - phi is reseeded ONLY on `reseed` or on a non-finite texel. A uniform phi = +1 or -1 is a legitimate\n//     stable state (FR-010): there is NO zero-heal as in f_ks, whose u = 0 is a fixed point of a different kind\n//   - selection uses switch(), not mix(): mix(NaN, x, 1) is still NaN\n//   - the feedback is NaN/Inf-guarded with abs(x) < 1e30 (NaN == NaN is TRUE on this GPU)\n//   - amp = 0.05 is RESEED_AMP of the mirror (T004: onset is 16-29 frames for amp 0.005-0.3, not critical).\n//     The hash is the mirror's hash01(); change both together\n//   - never name a variable e or phi (predefined constants)\nParam reseed(0);\nParam salt(0);\nParam fill(0);\n\nN = 256;\namp = 0.05;\ncx = floor(norm.x * N);\ncy = floor(norm.y * N);\nhx = fract((cx + salt * 37) * 0.1031);\nhy = fract((cy + salt * 17) * 0.1030);\nhz = fract((cx + cy + salt * 5) * 0.0973);\nhd = hx * (hy + 33.33) + hy * (hz + 33.33) + hz * (hx + 33.33);\nhx = hx + hd;\nhy = hy + hd;\nhz = hz + hd;\nhn = fract((hx + hy) * hz);\n\nfb = nearest(in2, norm).x;\ngood = switch(abs(fb) < 1e30, 1, 0);\nseeded = fill + amp * (2 * hn - 1);\nuse = max(1 - good, switch(reseed >= 0.5, 1, 0));\nout1 = vec(switch(use >= 0.5, seeded, fb), 0, 0, 0);\n",
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
					"text": "jit.gl.pix vsynth @name #0_imm_pass @adapt 0 @dim 256 256 @type float32",
					"varname": "#0_imm_pass"
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
									"code": "// codebox_adv.gen -- f_vf_immiscible stage 3: blend the two velocities by phi, backward-advect phi by the\n// blend, inject, clamp, pack phi and phi^3 for the DFT chain. 256x256 float32.\n// GENERATED by src/f_vf_immiscible/gen_blend.py -- edit the generator, not this file.\n// Mirror: tests/modules/immiscible/immiscible_mirror.adv().\n//\n// Inputs: in1 = phi state from `pass` (R = phi; the HOT inlet, plan ADR-1 amended 2026-10-27 so the\n// cold packed velocities have always landed when `pass` fires this stage), in2 = packed velocities from\n// `inab` (R,G = uA, B,A = uB, decoded), in3 = phi source texture at render resolution (via vs_inState).\n// Output: R = phi, B = phi^3 (G, A = 0 are the imaginary parts for the DFT chain).\n//   - phi is read with a manual 4-tap bilinear whose integer indices wrap with wrap(): the domain is\n//     periodic and hardware sample() clamps its neighbour tap (f_vf_fluid carried finding)\n//   - injection: phi += inject * luma(source) * (1 - phi): bounded, phase B only, no effect at phi = 1.\n//     The source is averaged over a taps x taps grid of hardware taps in normalized offsets, like inab.\n//     src_phi = 0 (inlet unconnected) disables it\n//   - the clamp bound 1.25 is PHI_CLAMP of the mirror (T004: observed |phi| <= 1.03); a safety net only\n//   - freeze = 1 passes phi through unchanged (no advection, no injection, no clamp), still packed\n//   - components are accessed inline on nearest()/sample(), never on a stored vec\nParam dt(0.01);\nParam inject(0.2);\nParam taps(2);\nParam freeze(0);\nParam src_phi(0);\n\nN = 256;\nph = nearest(in1, norm).x;\nuax = nearest(in2, norm).x;\nuay = nearest(in2, norm).y;\nubx = nearest(in2, norm).z;\nuby = nearest(in2, norm).w;\n// ---- blend begin (plain convex, G2; identical in codebox_adv.gen and codebox_enc.gen) ----\nbw = clamp((ph + 1) * 0.5, 0, 1);\nux = mix(uax, ubx, bw);\nuy = mix(uay, uby, bw);\n// ---- blend end ----\n// departure point (continuous texel coordinates), periodic bilinear read of phi\nfx = (norm.x - ux * dt) * N - 0.5;\nfy = (norm.y - uy * dt) * N - 0.5;\nx0 = floor(fx);\ny0 = floor(fy);\ntx = fx - x0;\nty = fy - y0;\nxa = wrap(x0, 0, N);\nxb = wrap(x0 + 1, 0, N);\nya = wrap(y0, 0, N);\nyb = wrap(y0 + 1, 0, N);\np00 = vec((xa + 0.5) / N, (ya + 0.5) / N);\np10 = vec((xb + 0.5) / N, (ya + 0.5) / N);\np01 = vec((xa + 0.5) / N, (yb + 0.5) / N);\np11 = vec((xb + 0.5) / N, (yb + 0.5) / N);\nap = mix(mix(nearest(in1, p00).x, nearest(in1, p10).x, tx), mix(nearest(in1, p01).x, nearest(in1, p11).x, tx), ty);\n\n// injection: luma of the source through the tap grid\ngate = switch(src_phi >= 0.5, 1, 0);\ntn = switch(gate >= 0.5, max(1, floor(taps)), 1);\nsr = 0;\nsg = 0;\nsb = 0;\nfor (a = 0; a < tn; a += 1) {\n  ox = ((a + 0.5) / tn - 0.5) / N;\n  for (b = 0; b < tn; b += 1) {\n    oy = ((b + 0.5) / tn - 0.5) / N;\n    sr += sample(in3, vec(norm.x + ox, norm.y + oy)).x;\n    sg += sample(in3, vec(norm.x + ox, norm.y + oy)).y;\n    sb += sample(in3, vec(norm.x + ox, norm.y + oy)).z;\n  }\n}\nluma = (0.2126 * sr + 0.7152 * sg + 0.0722 * sb) / (tn * tn);\nnewp = ap + inject * luma * (1 - ap) * gate;\nnewp = clamp(newp, -1.25, 1.25);\nnewp = switch(freeze >= 0.5, ph, newp);\nout1 = vec(newp, 0, newp * newp * newp, 0);\n",
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
					"text": "jit.gl.pix vsynth @name #0_imm_adv @adapt 0 @dim 256 256 @type float32",
					"varname": "#0_imm_adv"
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
									"code": "// codebox_dft_fx.gen -- f_vf_immiscible stage 4: forward DFT along x.\n// GENERATED by src/f_vf_immiscible/gen_dft.py from f_vf_fluid's DFT template -- edit the template, not this file.\n// Mirror: tests/math/test_fft_separable.pass_dft(axis=\"x\", inverse=0).\n//\n// Packing (float32 RGBA): R,G = Re,Im of phi; B,A = Re,Im of phi^3 (forward input R = phi, B = phi^3).\n// Carried findings (bench-verified 2026-09-22/23):\n//   - integer bin index is floor(norm * N), NOT `cell` (= norm*(dim-1) on jit.gl.pix)\n//   - nearest() at texel centers, twiddle index mod(k*n, N) before the angle\n//   - components accessed inline on nearest(), never on a stored vector\n//   - a NaN/Inf guard must use abs(x) < 1e30 (NaN == NaN is TRUE on this GPU)\n//   - no unary minus in front of a product/parenthesis: write `0 - ...` (GenExpr mis-parses it)\n\nN = 256;\nk = floor(norm.x * N);\n\nacc0 = 0;\nacc1 = 0;\nacc2 = 0;\nacc3 = 0;\n\nfor (n = 0; n < 256; n += 1) {\n\tuv = vec((n + 0.5) / N, norm.y);\n\tang = 0 - twopi * mod(k * n, N) / N;\n\tc = cos(ang);\n\ts = sin(ang);\n\tacc0 += nearest(in1, uv).x * c - nearest(in1, uv).y * s;\n\tacc1 += nearest(in1, uv).x * s + nearest(in1, uv).y * c;\n\tacc2 += nearest(in1, uv).z * c - nearest(in1, uv).w * s;\n\tacc3 += nearest(in1, uv).z * s + nearest(in1, uv).w * c;\n}\n\nout1 = vec(acc0, acc1, acc2, acc3);\n",
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
					"text": "jit.gl.pix vsynth @name #0_imm_fx @adapt 0 @dim 256 256 @type float32",
					"varname": "#0_imm_fx"
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
									"code": "// codebox_dft_fy.gen -- f_vf_immiscible stage 5: forward DFT along y.\n// GENERATED by src/f_vf_immiscible/gen_dft.py from f_vf_fluid's DFT template -- edit the template, not this file.\n// Mirror: tests/math/test_fft_separable.pass_dft(axis=\"y\", inverse=0).\n//\n// Packing (float32 RGBA): R,G = Re,Im of phi; B,A = Re,Im of phi^3 (forward input R = phi, B = phi^3).\n// Carried findings (bench-verified 2026-09-22/23):\n//   - integer bin index is floor(norm * N), NOT `cell` (= norm*(dim-1) on jit.gl.pix)\n//   - nearest() at texel centers, twiddle index mod(k*n, N) before the angle\n//   - components accessed inline on nearest(), never on a stored vector\n//   - a NaN/Inf guard must use abs(x) < 1e30 (NaN == NaN is TRUE on this GPU)\n//   - no unary minus in front of a product/parenthesis: write `0 - ...` (GenExpr mis-parses it)\n\nN = 256;\nk = floor(norm.y * N);\n\nacc0 = 0;\nacc1 = 0;\nacc2 = 0;\nacc3 = 0;\n\nfor (n = 0; n < 256; n += 1) {\n\tuv = vec(norm.x, (n + 0.5) / N);\n\tang = 0 - twopi * mod(k * n, N) / N;\n\tc = cos(ang);\n\ts = sin(ang);\n\tacc0 += nearest(in1, uv).x * c - nearest(in1, uv).y * s;\n\tacc1 += nearest(in1, uv).x * s + nearest(in1, uv).y * c;\n\tacc2 += nearest(in1, uv).z * c - nearest(in1, uv).w * s;\n\tacc3 += nearest(in1, uv).z * s + nearest(in1, uv).w * c;\n}\n\nout1 = vec(acc0, acc1, acc2, acc3);\n",
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
					"text": "jit.gl.pix vsynth @name #0_imm_fy @adapt 0 @dim 256 256 @type float32",
					"varname": "#0_imm_fy"
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
									"code": "// codebox_spec.gen -- f_vf_immiscible stage 6: the stabilised semi-implicit Cahn-Hilliard step,\n// per Fourier bin. 256x256 float32. Mirror: tests/modules/immiscible/immiscible_mirror.spec().\n//\n// Input in1 = spectral texture (R,G = Re,Im of phi-hat; B,A = Re,Im of (phi^3)^).\n// Output R,G = Re,Im of phi-hat'; B,A = 0.\n//     phi-hat' = fa * phi-hat + fn * (phi^3)^\n//     fa = (1 + x (a + 1)) / (1 + x (a + kappa k^2)),   fn = -x / (1 + x (a + kappa k^2))\n//     x = mdt * k^2,  kappa = (iface / N)^2,  k = 2*pi*signed_index (unit periodic domain)\n//   - the k = 0 bin has x = 0: fa = 1, fn = 0, so the mean of phi is conserved exactly\n//   - the fixed point is the exact Cahn-Hilliard steady state; a >= 1 never raised the energy\n//     (T004: a = 0.5 diverges at mdt >= 1e-2)\n//   - CONSTANTS FIXED BY T004 (2026-10-27), mirrored in immiscible_mirror.py -- change both together:\n//       a = 1.5 (A_STAB), mdt = 0.1 * coarsen^3 (MDT_MAX, MDT_EXP)\n//   - `coarsen` and `iface` are not clamped here; the patcher's dial ranges do that (the mirror\n//     does not clamp either). `iface` is in texels of THIS 256 grid\n//   - freeze = 1 gives mdt = 0, i.e. factor exactly 1 (phi untouched)\n//   - integer bin index is floor(norm * N), not `cell`; components are read inline on nearest()\n//   - unary minus before a parenthesis mis-parses in GenExpr; `0 - x` is used\nParam iface(4);\nParam coarsen(0.3);\nParam freeze(0);\n\nN = 256;\nbx = floor(norm.x * N);\nby = floor(norm.y * N);\nmx = switch(bx < N * 0.5, bx, bx - N);\nmy = switch(by < N * 0.5, by, by - N);\nkx = twopi * mx;\nky = twopi * my;\nk2 = kx * kx + ky * ky;\n\nkappa = (iface / N) * (iface / N);\nmdt = 0.1 * coarsen * coarsen * coarsen * (1 - step(0.5, freeze));\nx = mdt * k2;\nden = 1 + x * (1.5 + kappa * k2);\nfa = (1 + x * 2.5) / den;\nfn = (0 - x) / den;\n\nout1 = vec(fa * nearest(in1, norm).x + fn * nearest(in1, norm).z, fa * nearest(in1, norm).y + fn * nearest(in1, norm).w, 0, 0);\n",
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
					"text": "jit.gl.pix vsynth @name #0_imm_spec @adapt 0 @dim 256 256 @type float32",
					"varname": "#0_imm_spec"
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
									"code": "// codebox_dft_iy.gen -- f_vf_immiscible stage 7: inverse DFT along y.\n// GENERATED by src/f_vf_immiscible/gen_dft.py from f_vf_fluid's DFT template -- edit the template, not this file.\n// Mirror: tests/math/test_fft_separable.pass_dft(axis=\"y\", inverse=1).\n//\n// Packing (float32 RGBA): R,G = Re,Im of phi; B,A = Re,Im of phi^3 (forward input R = phi, B = phi^3).\n// Carried findings (bench-verified 2026-09-22/23):\n//   - integer bin index is floor(norm * N), NOT `cell` (= norm*(dim-1) on jit.gl.pix)\n//   - nearest() at texel centers, twiddle index mod(k*n, N) before the angle\n//   - components accessed inline on nearest(), never on a stored vector\n//   - a NaN/Inf guard must use abs(x) < 1e30 (NaN == NaN is TRUE on this GPU)\n//   - no unary minus in front of a product/parenthesis: write `0 - ...` (GenExpr mis-parses it)\n\nN = 256;\nk = floor(norm.y * N);\n\nacc0 = 0;\nacc1 = 0;\nacc2 = 0;\nacc3 = 0;\n\nfor (n = 0; n < 256; n += 1) {\n\tuv = vec(norm.x, (n + 0.5) / N);\n\tang = twopi * mod(k * n, N) / N;\n\tc = cos(ang);\n\ts = sin(ang);\n\tacc0 += nearest(in1, uv).x * c - nearest(in1, uv).y * s;\n\tacc1 += nearest(in1, uv).x * s + nearest(in1, uv).y * c;\n\tacc2 += nearest(in1, uv).z * c - nearest(in1, uv).w * s;\n\tacc3 += nearest(in1, uv).z * s + nearest(in1, uv).w * c;\n}\n\nout1 = vec(acc0, acc1, acc2, acc3) / N;\n",
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
					"text": "jit.gl.pix vsynth @name #0_imm_iy @adapt 0 @dim 256 256 @type float32",
					"varname": "#0_imm_iy"
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
									"code": "// codebox_dft_ix.gen -- f_vf_immiscible stage 8: inverse DFT along x, real part + NaN/Inf guard.\n// GENERATED by src/f_vf_immiscible/gen_dft.py from f_vf_fluid's DFT template -- edit the template, not this file.\n// Mirror: tests/math/test_fft_separable.pass_dft(axis=\"x\", inverse=1).\n//\n// Packing (float32 RGBA): R,G = Re,Im of phi; B,A = Re,Im of phi^3 (forward input R = phi, B = phi^3).\n// Carried findings (bench-verified 2026-09-22/23):\n//   - integer bin index is floor(norm * N), NOT `cell` (= norm*(dim-1) on jit.gl.pix)\n//   - nearest() at texel centers, twiddle index mod(k*n, N) before the angle\n//   - components accessed inline on nearest(), never on a stored vector\n//   - a NaN/Inf guard must use abs(x) < 1e30 (NaN == NaN is TRUE on this GPU)\n//   - no unary minus in front of a product/parenthesis: write `0 - ...` (GenExpr mis-parses it)\n\nN = 256;\nk = floor(norm.x * N);\n\nacc0 = 0;\nacc1 = 0;\nacc2 = 0;\nacc3 = 0;\n\nfor (n = 0; n < 256; n += 1) {\n\tuv = vec((n + 0.5) / N, norm.y);\n\tang = twopi * mod(k * n, N) / N;\n\tc = cos(ang);\n\ts = sin(ang);\n\tacc0 += nearest(in1, uv).x * c - nearest(in1, uv).y * s;\n\tacc1 += nearest(in1, uv).x * s + nearest(in1, uv).y * c;\n\tacc2 += nearest(in1, uv).z * c - nearest(in1, uv).w * s;\n\tacc3 += nearest(in1, uv).z * s + nearest(in1, uv).w * c;\n}\n\n// inverse along x is the last transform: keep only the real parts (drops the\n// numerical imaginary residue every frame) and zap non-finite values, so a NaN\n// can never persist in the feedback loop.\nru = acc0 / N;\nrv = acc2 / N;\nru = switch(abs(ru) < 1e30, ru, 0);\nrv = switch(abs(rv) < 1e30, rv, 0);\nout1 = vec(ru, 0, rv, 0);\n",
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
					"text": "jit.gl.pix vsynth @name #0_imm_ix @adapt 0 @dim 256 256 @type float32",
					"varname": "#0_imm_ix"
				}
			},
			{
				"box": {
					"id": "obj-5",
					"maxclass": "newobj",
					"numinlets": 3,
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
									"code": "// codebox_enc.gen -- f_vf_immiscible stage 9: upsample phi and both velocities to the render size, blend,\n// encode both outlets, apply the bypass gate. Runs at RENDER resolution.\n// GENERATED by src/f_vf_immiscible/gen_blend.py -- edit the generator, not this file.\n// Mirror: tests/modules/immiscible/immiscible_mirror.enc().\n//\n// Inputs: in1 = `r draw` bang (unused; triggers every frame and gives this pix the render-context size),\n// in2 = packed velocities from `inab` (256x256, cold), in3 = phi state from `ix` (R = phi, 256x256).\n// Outputs: out1 = phi as a grey scalar texture w = (phi + 1) / 2 in R, G, B with A = 1 (G4);\n//          out2 = the blended velocity as an f_vecfield: R,G = 0.5 + 0.5 * clamp(u, -1, 1), B = 0.5, A = 1.\n//   - everything is read with a manual periodic 4-tap (works for any output size, including smaller than\n//     256 where hardware sample() would snap)\n//   - bypass_gate = 1 mixes BOTH outlets to their own-kind neutral (0.5, 0.5, 0.5, 1): out1 mid grey,\n//     out2 the neutral vecfield (G5, decided 2026-10-27; the solver keeps running)\n//   - Param is bypass_gate, never `bypass` (native pix attribute)\nParam bypass_gate(0);\n\nN = 256;\nfx = norm.x * N - 0.5;\nfy = norm.y * N - 0.5;\nx0 = floor(fx);\ny0 = floor(fy);\ntx = fx - x0;\nty = fy - y0;\nxa = wrap(x0, 0, N);\nxb = wrap(x0 + 1, 0, N);\nya = wrap(y0, 0, N);\nyb = wrap(y0 + 1, 0, N);\np00 = vec((xa + 0.5) / N, (ya + 0.5) / N);\np10 = vec((xb + 0.5) / N, (ya + 0.5) / N);\np01 = vec((xa + 0.5) / N, (yb + 0.5) / N);\np11 = vec((xb + 0.5) / N, (yb + 0.5) / N);\nph = mix(mix(nearest(in3, p00).x, nearest(in3, p10).x, tx), mix(nearest(in3, p01).x, nearest(in3, p11).x, tx), ty);\nuax = mix(mix(nearest(in2, p00).x, nearest(in2, p10).x, tx), mix(nearest(in2, p01).x, nearest(in2, p11).x, tx), ty);\nuay = mix(mix(nearest(in2, p00).y, nearest(in2, p10).y, tx), mix(nearest(in2, p01).y, nearest(in2, p11).y, tx), ty);\nubx = mix(mix(nearest(in2, p00).z, nearest(in2, p10).z, tx), mix(nearest(in2, p01).z, nearest(in2, p11).z, tx), ty);\nuby = mix(mix(nearest(in2, p00).w, nearest(in2, p10).w, tx), mix(nearest(in2, p01).w, nearest(in2, p11).w, tx), ty);\n// ---- blend begin (plain convex, G2; identical in codebox_adv.gen and codebox_enc.gen) ----\nbw = clamp((ph + 1) * 0.5, 0, 1);\nux = mix(uax, ubx, bw);\nuy = mix(uay, uby, bw);\n// ---- blend end ----\nr = 0.5 + 0.5 * clamp(ux, -1, 1);\ng = 0.5 + 0.5 * clamp(uy, -1, 1);\nout1 = vec(mix(bw, 0.5, bypass_gate), mix(bw, 0.5, bypass_gate), mix(bw, 0.5, bypass_gate), 1);\nout2 = vec(mix(r, 0.5, bypass_gate), mix(g, 0.5, bypass_gate), 0.5, 1);\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
									"id": "gen-obj-2",
									"maxclass": "codebox",
									"numinlets": 3,
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
						250.0,
						730.0,
						200.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_imm_enc @adapt 1 @type float32",
					"varname": "#0_imm_enc"
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
					"varname": "vfimm_autopattr"
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
					"text": "Immiscible"
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
					"text": "\u2207 in/out"
				}
			},
			{
				"box": {
					"id": "obj-19f",
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
					"hint": "Takes: vecfield",
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
						138.6,
						22.0
					],
					"text": "prepend param src_phi"
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
					"comment": "velocity A (phase A)",
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
					"comment": "velocity B (phase B)",
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
					"text": "prepend param src_a"
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
					"text": "prepend param src_b"
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
					"hint": "Advection step: how far the blend pattern is carried by the flow each frame",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_imm_adv::dt",
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
								0.01
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "dt",
							"parameter_mmax": 0.05,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "dt",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "dt"
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
					"text": "dt",
					"textjustification": 1,
					"varname": "lbl_dt"
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
					"hint": "Interface width in solver texels: small = crisp edge between the two flows, large = soft blend zone",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_imm_spec::iface",
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
							"parameter_longname": "iface",
							"parameter_mmax": 12.0,
							"parameter_mmin": 1.5,
							"parameter_modmode": 3,
							"parameter_shortname": "iface",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "iface"
				}
			},
			{
				"box": {
					"id": "obj-24",
					"maxclass": "attrui",
					"attr": "iface",
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
					"text": "Iface",
					"textjustification": 1,
					"varname": "lbl_iface"
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
					"hint": "How fast the two phases pull together into bigger blobs; 0 = the pattern is only carried, never re-forms",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_imm_spec::coarsen",
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
								0.3
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "coarsen",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "coarsen",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "coarsen"
				}
			},
			{
				"box": {
					"id": "obj-27",
					"maxclass": "attrui",
					"attr": "coarsen",
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
					"text": "Coarsen",
					"textjustification": 1,
					"varname": "lbl_coarsen"
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
					"hint": "How strongly the brightness of the texture on input 0 deposits phase B (velocity B)",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_imm_adv::inject",
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
							"parameter_longname": "inject",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "inject",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "inject"
				}
			},
			{
				"box": {
					"id": "obj-30",
					"maxclass": "attrui",
					"attr": "inject",
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
					"text": "Inject",
					"textjustification": 1,
					"varname": "lbl_inject"
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
					"hint": "Mean mix at reset: negative = mostly A, positive = mostly B",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_imm_pass::fill",
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
							"parameter_longname": "fill",
							"parameter_mmax": 0.6,
							"parameter_mmin": -0.6,
							"parameter_modmode": 3,
							"parameter_shortname": "fill",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "fill"
				}
			},
			{
				"box": {
					"id": "obj-33",
					"maxclass": "attrui",
					"attr": "fill",
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
					"text": "Fill",
					"textjustification": 1,
					"varname": "lbl_fill"
				}
			},
			{
				"box": {
					"id": "obj-35",
					"maxclass": "live.menu",
					"fontname": "Ableton Sans Light",
					"hint": "Hold the pattern still while the blend keeps running on it",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"",
						"",
						"float"
					],
					"param_connect": "#0_imm_adv::freeze",
					"parameter_enable": 1,
					"patching_rect": [
						390.0,
						250.0,
						60.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						0.0,
						114.0,
						45.0,
						15.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_enum": [
								"Off",
								"Freeze"
							],
							"parameter_initial": [
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "freeze",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 0,
							"parameter_shortname": "freeze",
							"parameter_type": 2,
							"parameter_unitstyle": 0
						}
					},
					"varname": "freeze"
				}
			},
			{
				"box": {
					"id": "obj-36",
					"maxclass": "attrui",
					"attr": "freeze",
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
					"id": "obj-700",
					"maxclass": "attrui",
					"attr": "freeze",
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
					"text": "Freeze",
					"textjustification": 1,
					"varname": "lbl_freeze"
				}
			},
			{
				"box": {
					"id": "obj-39",
					"maxclass": "attrui",
					"attr": "taps",
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
					"style": "",
					"varname": "taps"
				}
			},
			{
				"box": {
					"id": "obj-701",
					"maxclass": "attrui",
					"attr": "taps",
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
						118.0,
						46.0,
						28.0,
						28.0
					],
					"varname": "reset_button",
					"hint": "Reseed the pattern: mean mix = Fill, plus a little noise"
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
						107.0,
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
						52.0,
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
					"id": "obj-raw-6",
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
					"id": "obj-raw-8",
					"maxclass": "newobj",
					"patching_rect": [
						30.0,
						1042.0,
						50.0,
						22.0
					],
					"text": "counter",
					"numinlets": 5,
					"numoutlets": 4,
					"outlettype": [
						"int",
						"",
						"",
						"int"
					]
				}
			},
			{
				"box": {
					"id": "obj-raw-9",
					"maxclass": "newobj",
					"patching_rect": [
						30.0,
						1072.0,
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
						"obj-53",
						2
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
						"obj-50",
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
						"obj-50",
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
						"obj-50",
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
						"obj-50",
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
						"obj-50",
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
						"obj-51",
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
						"obj-50",
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
						"obj-58",
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
						"obj-50",
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
						"obj-58",
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
						"obj-53",
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
						"obj-56",
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
						"obj-56",
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
						"obj-53",
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
						"obj-52",
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
						"obj-53",
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
						"obj-50",
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
						"obj-4",
						6
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
						"obj-raw-11",
						1
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
						"obj-52",
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
						"obj-52",
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
				"dt",
				"dt",
				0
			],
			"obj-23": [
				"iface",
				"iface",
				0
			],
			"obj-26": [
				"coarsen",
				"coarsen",
				0
			],
			"obj-29": [
				"inject",
				"inject",
				0
			],
			"obj-32": [
				"fill",
				"fill",
				0
			],
			"obj-35": [
				"freeze",
				"freeze",
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