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
					"comment": "force vecfield / control",
					"index": 0,
					"numinlets": 0,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						30.0,
						30.0,
						30.0,
						30.0
					]
				}
			},
			{
				"box": {
					"id": "obj-2",
					"maxclass": "outlet",
					"comment": "velocity vecfield",
					"index": 0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						30.0,
						500.0,
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
						200.0,
						90.0,
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
					"numoutlets": 6,
					"outlettype": [
						"",
						"",
						"",
						"",
						"",
						""
					],
					"patching_rect": [
						200.0,
						130.0,
						252.0,
						22.0
					],
					"text": "route force dt viscosity project drag gain"
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
						200.0,
						250.0,
						330.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_fluid_pass @adapt 0 @dim 256 256 @type float32",
					"varname": "#0_fluid_pass"
				}
			},
			{
				"box": {
					"id": "obj-51",
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
									"id": "gen-obj-2",
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
									"id": "gen-obj-3",
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
									"id": "gen-obj-4",
									"maxclass": "codebox",
									"code": "// codebox_adv.gen -- f_vf_fluid stage 1: self-advect the velocity state and add\n// the force. Mirror: tests/fluid_mirror.adv(). 256x256 float32.\n//\n// Inputs (jit.gl.pix inlets): in1 = `r draw` bang (unused; only triggers the\n// render every frame), in2 = force f_vecfield at render resolution (via\n// vs_inState), in3 = previous velocity state (R = u, B = v).\n// Output: vec(u, 0, v, 0) in decoded f_vecfield units.\n//\n// Carried findings (Phase 0, 2026-09-23):\n//   - the velocity is read with a manual 4-tap bilinear whose integer indices\n//     wrap with wrap(): the flow domain is periodic and hardware sample()\n//     clamps its neighbor tap (0.5 error at the seam)\n//   - hardware sample() is used ONLY for the force: a codebox cannot read an\n//     input texture's size, so manual taps are impossible there. It is exact at\n//     1:1 and when magnifying, nearest-like when minifying (E4, tier 3)\n//   - components are accessed inline on sample()/nearest(), never on a stored vec\n//   - never name a Param `bypass`; `force`, `dt` are fine\nParam dt(0.01);\nParam force(0.02);\nParam src_vecfield(0);\n\nN = 256;\nu = nearest(in3, norm).x;\nv = nearest(in3, norm).z;\n\n// departure point (continuous texel coordinates)\nfx = (norm.x - u * dt) * N - 0.5;\nfy = (norm.y - v * dt) * N - 0.5;\nx0 = floor(fx);\ny0 = floor(fy);\ntx = fx - x0;\nty = fy - y0;\nxa = wrap(x0, 0, N);\nxb = wrap(x0 + 1, 0, N);\nya = wrap(y0, 0, N);\nyb = wrap(y0 + 1, 0, N);\np00 = vec((xa + 0.5) / N, (ya + 0.5) / N);\np10 = vec((xb + 0.5) / N, (ya + 0.5) / N);\np01 = vec((xa + 0.5) / N, (yb + 0.5) / N);\np11 = vec((xb + 0.5) / N, (yb + 0.5) / N);\nau = mix(mix(nearest(in3, p00).x, nearest(in3, p10).x, tx), mix(nearest(in3, p01).x, nearest(in3, p11).x, tx), ty);\nav = mix(mix(nearest(in3, p00).z, nearest(in3, p10).z, tx), mix(nearest(in3, p01).z, nearest(in3, p11).z, tx), ty);\n\n// force: decoded (p - 0.5) * 2. Gated by src_vecfield (0 = inlet unconnected) AND by the\n// texture's own content: a real f_vecfield has B = 0.5 (contract), while vs_black is\n// all zeros (decoded -1!). vs_inState's connected flag lags at load/disconnect, and a\n// bogus -1 force leaves a phantom uniform velocity that decays only as fast as drag\n// allows, so the flag alone is not enough (bench, 2026-09-23).\ngate = switch(src_vecfield >= 0.5, 1, 0) * switch(abs(sample(in2, norm).z - 0.5) < 0.25, 1, 0);\nout1 = vec(au + force * (sample(in2, norm).x - 0.5) * 2 * gate, 0, av + force * (sample(in2, norm).y - 0.5) * 2 * gate, 0);\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
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
									"id": "gen-obj-5",
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
									"source": [
										"gen-obj-1",
										0
									],
									"destination": [
										"gen-obj-4",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"gen-obj-2",
										0
									],
									"destination": [
										"gen-obj-4",
										1
									]
								}
							},
							{
								"patchline": {
									"source": [
										"gen-obj-3",
										0
									],
									"destination": [
										"gen-obj-4",
										2
									]
								}
							},
							{
								"patchline": {
									"source": [
										"gen-obj-4",
										0
									],
									"destination": [
										"gen-obj-5",
										0
									]
								}
							}
						]
					},
					"patching_rect": [
						200.0,
						282.0,
						330.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_fluid_adv @adapt 0 @dim 256 256 @type float32",
					"varname": "#0_fluid_adv"
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
									"id": "gen-obj-2",
									"maxclass": "codebox",
									"code": "// codebox_dft_fx.gen -- f_vf_fluid stage 2: forward DFT along x.\n// GENERATED by gen_dft.py from one template -- edit the template, not this file.\n// Mirror: tests/test_fft_separable.pass_dft(axis=\"x\", inverse=0).\n//\n// Packing (float32 RGBA): R,G = Re,Im of u; B,A = Re,Im of v.\n// Carried findings (bench-verified 2026-09-22/23):\n//   - integer bin index is floor(norm * N), NOT `cell` (= norm*(dim-1) on jit.gl.pix)\n//   - nearest() at texel centers, twiddle index mod(k*n, N) before the angle\n//   - components accessed inline on nearest(), never on a stored vector\n//   - a NaN/Inf guard must use abs(x) < 1e30 (NaN == NaN is TRUE on this GPU)\n//   - no unary minus in front of a product/parenthesis: write `0 - ...` (GenExpr mis-parses it)\n\nN = 256;\nk = floor(norm.x * N);\n\nacc0 = 0;\nacc1 = 0;\nacc2 = 0;\nacc3 = 0;\n\nfor (n = 0; n < 256; n += 1) {\n\tuv = vec((n + 0.5) / N, norm.y);\n\tang = 0 - twopi * mod(k * n, N) / N;\n\tc = cos(ang);\n\ts = sin(ang);\n\tacc0 += nearest(in1, uv).x * c - nearest(in1, uv).y * s;\n\tacc1 += nearest(in1, uv).x * s + nearest(in1, uv).y * c;\n\tacc2 += nearest(in1, uv).z * c - nearest(in1, uv).w * s;\n\tacc3 += nearest(in1, uv).z * s + nearest(in1, uv).w * c;\n}\n\nout1 = vec(acc0, acc1, acc2, acc3);\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
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
									"source": [
										"gen-obj-1",
										0
									],
									"destination": [
										"gen-obj-2",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"gen-obj-2",
										0
									],
									"destination": [
										"gen-obj-3",
										0
									]
								}
							}
						]
					},
					"patching_rect": [
						200.0,
						314.0,
						330.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_fluid_fx @adapt 0 @dim 256 256 @type float32",
					"varname": "#0_fluid_fx"
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
									"id": "gen-obj-2",
									"maxclass": "codebox",
									"code": "// codebox_dft_fy.gen -- f_vf_fluid stage 3: forward DFT along y.\n// GENERATED by gen_dft.py from one template -- edit the template, not this file.\n// Mirror: tests/test_fft_separable.pass_dft(axis=\"y\", inverse=0).\n//\n// Packing (float32 RGBA): R,G = Re,Im of u; B,A = Re,Im of v.\n// Carried findings (bench-verified 2026-09-22/23):\n//   - integer bin index is floor(norm * N), NOT `cell` (= norm*(dim-1) on jit.gl.pix)\n//   - nearest() at texel centers, twiddle index mod(k*n, N) before the angle\n//   - components accessed inline on nearest(), never on a stored vector\n//   - a NaN/Inf guard must use abs(x) < 1e30 (NaN == NaN is TRUE on this GPU)\n//   - no unary minus in front of a product/parenthesis: write `0 - ...` (GenExpr mis-parses it)\n\nN = 256;\nk = floor(norm.y * N);\n\nacc0 = 0;\nacc1 = 0;\nacc2 = 0;\nacc3 = 0;\n\nfor (n = 0; n < 256; n += 1) {\n\tuv = vec(norm.x, (n + 0.5) / N);\n\tang = 0 - twopi * mod(k * n, N) / N;\n\tc = cos(ang);\n\ts = sin(ang);\n\tacc0 += nearest(in1, uv).x * c - nearest(in1, uv).y * s;\n\tacc1 += nearest(in1, uv).x * s + nearest(in1, uv).y * c;\n\tacc2 += nearest(in1, uv).z * c - nearest(in1, uv).w * s;\n\tacc3 += nearest(in1, uv).z * s + nearest(in1, uv).w * c;\n}\n\nout1 = vec(acc0, acc1, acc2, acc3);\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
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
									"source": [
										"gen-obj-1",
										0
									],
									"destination": [
										"gen-obj-2",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"gen-obj-2",
										0
									],
									"destination": [
										"gen-obj-3",
										0
									]
								}
							}
						]
					},
					"patching_rect": [
						200.0,
						346.0,
						330.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_fluid_fy @adapt 0 @dim 256 256 @type float32",
					"varname": "#0_fluid_fy"
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
									"id": "gen-obj-2",
									"maxclass": "codebox",
									"code": "// codebox_spec.gen -- f_vf_fluid stage 4: the spectral pass. Projection blend,\n// then exact viscous decay and linear drag, per Fourier bin.\n// Mirror: tests/fluid_mirror.spec(). 256x256 float32.\n//\n// Input in1 = spectral texture (R,G = Re,Im of u-hat; B,A = Re,Im of v-hat).\n// Wavevector k = 2*pi*signed_index (unit periodic domain).\n//   - projection uses OPERATOR wavenumbers that are zeroed at the Nyquist bin\n//     (odd functions of the index must vanish there or a real field gains an\n//     imaginary part; tests/test_fluid_mirror.py test_nyquist_keeps_field_real)\n//   - decay uses the full k^2: exp(-(viscosity*k^2 + drag)*dt); the k = 0 bin\n//     therefore only feels the drag\n//   - integer bin index is floor(norm * N), not `cell`\n//   - components accessed inline on nearest()\n//   - unary minus before a parenthesis mis-parses in GenExpr: `-(a + b) * c` is NOT\n//     -(a + b) * c (bench probe 2026-09-23); write `0 - (a + b) * c`\nParam viscosity(0);\nParam project(1);\nParam drag(0);\nParam dt(0.01);\n\nN = 256;\nbx = floor(norm.x * N);\nby = floor(norm.y * N);\nmx = switch(bx < N * 0.5, bx, bx - N);\nmy = switch(by < N * 0.5, by, by - N);\nkx = twopi * mx;\nky = twopi * my;\nk2 = kx * kx + ky * ky;\nkxo = switch(abs(mx) == N * 0.5, 0, kx);\nkyo = switch(abs(my) == N * 0.5, 0, ky);\nk2o = kxo * kxo + kyo * kyo;\nik2 = switch(k2o > 0, 1 / max(k2o, 1e-30), 0);\n\nur = nearest(in1, norm).x;\nui = nearest(in1, norm).y;\nvr = nearest(in1, norm).z;\nvi = nearest(in1, norm).w;\n\n// Helmholtz projection: remove the component parallel to k\ndr = (kxo * ur + kyo * vr) * ik2;\ndi = (kxo * ui + kyo * vi) * ik2;\npur = ur - kxo * dr;\npui = ui - kxo * di;\npvr = vr - kyo * dr;\npvi = vi - kyo * di;\n\ng = exp(0 - (viscosity * k2 + drag) * dt);\nout1 = vec(mix(ur, pur, project) * g, mix(ui, pui, project) * g, mix(vr, pvr, project) * g, mix(vi, pvi, project) * g);\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
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
									"source": [
										"gen-obj-1",
										0
									],
									"destination": [
										"gen-obj-2",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"gen-obj-2",
										0
									],
									"destination": [
										"gen-obj-3",
										0
									]
								}
							}
						]
					},
					"patching_rect": [
						200.0,
						378.0,
						330.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_fluid_spec @adapt 0 @dim 256 256 @type float32",
					"varname": "#0_fluid_spec"
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
									"id": "gen-obj-2",
									"maxclass": "codebox",
									"code": "// codebox_dft_iy.gen -- f_vf_fluid stage 5: inverse DFT along y.\n// GENERATED by gen_dft.py from one template -- edit the template, not this file.\n// Mirror: tests/test_fft_separable.pass_dft(axis=\"y\", inverse=1).\n//\n// Packing (float32 RGBA): R,G = Re,Im of u; B,A = Re,Im of v.\n// Carried findings (bench-verified 2026-09-22/23):\n//   - integer bin index is floor(norm * N), NOT `cell` (= norm*(dim-1) on jit.gl.pix)\n//   - nearest() at texel centers, twiddle index mod(k*n, N) before the angle\n//   - components accessed inline on nearest(), never on a stored vector\n//   - a NaN/Inf guard must use abs(x) < 1e30 (NaN == NaN is TRUE on this GPU)\n//   - no unary minus in front of a product/parenthesis: write `0 - ...` (GenExpr mis-parses it)\n\nN = 256;\nk = floor(norm.y * N);\n\nacc0 = 0;\nacc1 = 0;\nacc2 = 0;\nacc3 = 0;\n\nfor (n = 0; n < 256; n += 1) {\n\tuv = vec(norm.x, (n + 0.5) / N);\n\tang = twopi * mod(k * n, N) / N;\n\tc = cos(ang);\n\ts = sin(ang);\n\tacc0 += nearest(in1, uv).x * c - nearest(in1, uv).y * s;\n\tacc1 += nearest(in1, uv).x * s + nearest(in1, uv).y * c;\n\tacc2 += nearest(in1, uv).z * c - nearest(in1, uv).w * s;\n\tacc3 += nearest(in1, uv).z * s + nearest(in1, uv).w * c;\n}\n\nout1 = vec(acc0, acc1, acc2, acc3) / N;\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
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
									"source": [
										"gen-obj-1",
										0
									],
									"destination": [
										"gen-obj-2",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"gen-obj-2",
										0
									],
									"destination": [
										"gen-obj-3",
										0
									]
								}
							}
						]
					},
					"patching_rect": [
						200.0,
						410.0,
						330.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_fluid_iy @adapt 0 @dim 256 256 @type float32",
					"varname": "#0_fluid_iy"
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
									"id": "gen-obj-2",
									"maxclass": "codebox",
									"code": "// codebox_dft_ix.gen -- f_vf_fluid stage 6: inverse DFT along x, real part + NaN/Inf guard.\n// GENERATED by gen_dft.py from one template -- edit the template, not this file.\n// Mirror: tests/test_fft_separable.pass_dft(axis=\"x\", inverse=1).\n//\n// Packing (float32 RGBA): R,G = Re,Im of u; B,A = Re,Im of v.\n// Carried findings (bench-verified 2026-09-22/23):\n//   - integer bin index is floor(norm * N), NOT `cell` (= norm*(dim-1) on jit.gl.pix)\n//   - nearest() at texel centers, twiddle index mod(k*n, N) before the angle\n//   - components accessed inline on nearest(), never on a stored vector\n//   - a NaN/Inf guard must use abs(x) < 1e30 (NaN == NaN is TRUE on this GPU)\n//   - no unary minus in front of a product/parenthesis: write `0 - ...` (GenExpr mis-parses it)\n\nN = 256;\nk = floor(norm.x * N);\n\nacc0 = 0;\nacc1 = 0;\nacc2 = 0;\nacc3 = 0;\n\nfor (n = 0; n < 256; n += 1) {\n\tuv = vec((n + 0.5) / N, norm.y);\n\tang = twopi * mod(k * n, N) / N;\n\tc = cos(ang);\n\ts = sin(ang);\n\tacc0 += nearest(in1, uv).x * c - nearest(in1, uv).y * s;\n\tacc1 += nearest(in1, uv).x * s + nearest(in1, uv).y * c;\n\tacc2 += nearest(in1, uv).z * c - nearest(in1, uv).w * s;\n\tacc3 += nearest(in1, uv).z * s + nearest(in1, uv).w * c;\n}\n\n// inverse along x is the last transform: keep only the real parts (drops the\n// numerical imaginary residue every frame) and zap non-finite values, so a NaN\n// can never persist in the feedback loop.\nru = acc0 / N;\nrv = acc2 / N;\nru = switch(abs(ru) < 1e30, ru, 0);\nrv = switch(abs(rv) < 1e30, rv, 0);\nout1 = vec(ru, 0, rv, 0);\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
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
									"source": [
										"gen-obj-1",
										0
									],
									"destination": [
										"gen-obj-2",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"gen-obj-2",
										0
									],
									"destination": [
										"gen-obj-3",
										0
									]
								}
							}
						]
					},
					"patching_rect": [
						200.0,
						442.0,
						330.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_fluid_ix @adapt 0 @dim 256 256 @type float32",
					"varname": "#0_fluid_ix"
				}
			},
			{
				"box": {
					"id": "obj-5",
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
									"id": "gen-obj-2",
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
									"id": "gen-obj-3",
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
									"id": "gen-obj-4",
									"maxclass": "codebox",
									"code": "// codebox_enc.gen -- f_vf_fluid stage 7: upsample the 256x256 velocity to the\n// render size, apply gain, clamp, encode as an f_vecfield, and apply the\n// bypass gate. Runs at RENDER resolution. Mirror: tests/fluid_mirror.enc().\n//\n// Inputs: in1 = `r draw` bang (unused; triggers every frame and gives this\n// pix the render-context size even when the force inlet is unconnected),\n// in2 = force f_vecfield at render resolution (via vs_inState), in3 = velocity\n// (R = u, B = v, 256x256).\n//   - the velocity is read with a manual periodic 4-tap (works for any output\n//     size, including smaller than 256 where hardware sample() would snap)\n//   - bypass_gate = 1 outputs the force unchanged, or an exactly neutral field\n//     when src_vecfield = 0 (vs_black is all zeros = decoded -1, so passing it\n//     through would be wrong)\n//   - Param is bypass_gate, never `bypass` (native pix attribute)\nParam gain(1);\nParam bypass_gate(0);\nParam src_vecfield(0);\n\nN = 256;\nfx = norm.x * N - 0.5;\nfy = norm.y * N - 0.5;\nx0 = floor(fx);\ny0 = floor(fy);\ntx = fx - x0;\nty = fy - y0;\nxa = wrap(x0, 0, N);\nxb = wrap(x0 + 1, 0, N);\nya = wrap(y0, 0, N);\nyb = wrap(y0 + 1, 0, N);\np00 = vec((xa + 0.5) / N, (ya + 0.5) / N);\np10 = vec((xb + 0.5) / N, (ya + 0.5) / N);\np01 = vec((xa + 0.5) / N, (yb + 0.5) / N);\np11 = vec((xb + 0.5) / N, (yb + 0.5) / N);\nau = mix(mix(nearest(in3, p00).x, nearest(in3, p10).x, tx), mix(nearest(in3, p01).x, nearest(in3, p11).x, tx), ty);\nav = mix(mix(nearest(in3, p00).z, nearest(in3, p10).z, tx), mix(nearest(in3, p01).z, nearest(in3, p11).z, tx), ty);\n\nr = 0.5 + 0.5 * clamp(gain * au, -1, 1);\ng = 0.5 + 0.5 * clamp(gain * av, -1, 1);\n\n// same content check as codebox_adv.gen: only a texture with B = 0.5 counts as a vecfield\nuseforce = switch(src_vecfield >= 0.5, 1, 0) * switch(abs(sample(in2, norm).z - 0.5) < 0.25, 1, 0);\nfr = mix(0.5, sample(in2, norm).x, useforce);\nfg = mix(0.5, sample(in2, norm).y, useforce);\nfb = mix(0.5, sample(in2, norm).z, useforce);\nfa = mix(1, sample(in2, norm).w, useforce);\n\nout1 = vec(mix(r, fr, bypass_gate), mix(g, fg, bypass_gate), mix(0.5, fb, bypass_gate), mix(1, fa, bypass_gate));\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
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
									"id": "gen-obj-5",
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
									"source": [
										"gen-obj-1",
										0
									],
									"destination": [
										"gen-obj-4",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"gen-obj-2",
										0
									],
									"destination": [
										"gen-obj-4",
										1
									]
								}
							},
							{
								"patchline": {
									"source": [
										"gen-obj-3",
										0
									],
									"destination": [
										"gen-obj-4",
										2
									]
								}
							},
							{
								"patchline": {
									"source": [
										"gen-obj-4",
										0
									],
									"destination": [
										"gen-obj-5",
										0
									]
								}
							}
						]
					},
					"patching_rect": [
						520.0,
						300.0,
						330.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_fluid_enc @adapt 1 @type float32",
					"varname": "#0_fluid_enc"
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
						200.0,
						60.0,
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
						350.0,
						60.0,
						175.0,
						22.0
					],
					"text": "prepend param src_vecfield"
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
						560.0,
						30.0,
						50.0,
						22.0
					],
					"text": "r draw"
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
						500.0,
						500.0,
						56.0,
						22.0
					],
					"text": "autopattr",
					"varname": "vffluid_autopattr"
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
						20.0,
						20.0,
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
						20.0,
						20.0,
						80.0,
						21.0
					],
					"presentation": 1,
					"presentation_rect": [
						-1.5,
						0.0,
						80.0,
						21.0
					],
					"text": "Fluid"
				}
			},
			{
				"box": {
					"id": "obj-8",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"textcolor": [
						0.302,
						0.325,
						0.463,
						1.0
					],
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						20.0,
						20.0,
						60.0,
						21.0
					],
					"presentation": 1,
					"presentation_rect": [
						38.0,
						2.5,
						60.0,
						18.0
					],
					"text": "vecfield"
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
						600.0,
						50.0,
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
						600.0,
						80.0,
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
						600.0,
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
						600.0,
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
						600.0,
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
						600.0,
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
					"hint": "Velocity gained per frame from the force input at full scale",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_fluid_adv::force",
					"parameter_enable": 1,
					"patching_rect": [
						50.0,
						80.0,
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
								0.02
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "force",
							"parameter_mmax": 0.2,
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
					"id": "obj-21",
					"maxclass": "attrui",
					"attr": "force",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						50.0,
						170.0,
						115.0,
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
						50.0,
						130.0,
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
					"text": "Force",
					"textjustification": 1,
					"varname": "lbl_force"
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
					"hint": "Self-advection step and the time step of viscosity/drag",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_fluid_adv::dt",
					"parameter_enable": 1,
					"patching_rect": [
						100.0,
						80.0,
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
					"id": "obj-24",
					"maxclass": "attrui",
					"attr": "dt",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						100.0,
						200.0,
						100.0,
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
						100.0,
						130.0,
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
					"text": "dt",
					"textjustification": 1,
					"varname": "lbl_dt"
				}
			},
			{
				"box": {
					"id": "obj-60",
					"maxclass": "attrui",
					"attr": "dt",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						400.0,
						170.0,
						100.0,
						22.0
					],
					"style": ""
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
					"hint": "Kinematic viscosity: exact and stable at any value; high = honey, small scales die",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_fluid_spec::viscosity",
					"parameter_enable": 1,
					"patching_rect": [
						150.0,
						80.0,
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
								0.0001
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "viscosity",
							"parameter_mmax": 0.002,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "viscosity",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "viscosity"
				}
			},
			{
				"box": {
					"id": "obj-27",
					"maxclass": "attrui",
					"attr": "viscosity",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						150.0,
						230.0,
						143.0,
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
						150.0,
						130.0,
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
					"text": "Visc",
					"textjustification": 1,
					"varname": "lbl_viscosity"
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
					"hint": "0 = compressible (shock fronts), 1 = divergence-free swirl",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_fluid_spec::project",
					"parameter_enable": 1,
					"patching_rect": [
						200.0,
						80.0,
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
								1.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "project",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "project",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "project"
				}
			},
			{
				"box": {
					"id": "obj-30",
					"maxclass": "attrui",
					"attr": "project",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						200.0,
						260.0,
						129.0,
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
						200.0,
						130.0,
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
					"text": "Project",
					"textjustification": 1,
					"varname": "lbl_project"
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
					"hint": "Linear damping; keeps sustained or uniform force bounded",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_fluid_spec::drag",
					"parameter_enable": 1,
					"patching_rect": [
						250.0,
						80.0,
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
							"parameter_longname": "drag",
							"parameter_mmax": 5.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "drag",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "drag"
				}
			},
			{
				"box": {
					"id": "obj-33",
					"maxclass": "attrui",
					"attr": "drag",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						250.0,
						290.0,
						108.0,
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
						250.0,
						130.0,
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
					"text": "Drag",
					"textjustification": 1,
					"varname": "lbl_drag"
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
					"hint": "Output scale applied to the velocity before encoding (clamped to the vecfield range)",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_fluid_enc::gain",
					"parameter_enable": 1,
					"patching_rect": [
						300.0,
						80.0,
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
					"id": "obj-36",
					"maxclass": "attrui",
					"attr": "gain",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						300.0,
						320.0,
						108.0,
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
						300.0,
						130.0,
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
					"text": "Gain",
					"textjustification": 1,
					"varname": "lbl_gain"
				}
			},
			{
				"box": {
					"id": "obj-38",
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
						168.0,
						5.0,
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
					"id": "obj-39",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						400.0,
						60.0,
						160.0,
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
						"obj-17",
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
						"obj-17",
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
						"obj-17",
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
						"obj-51",
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
						"obj-50",
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
						"obj-5",
						2
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
						"obj-51",
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
						"obj-51",
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
						"obj-54",
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
						"obj-23",
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
						"obj-60",
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
				"force",
				"force",
				0
			],
			"obj-23": [
				"dt",
				"dt",
				0
			],
			"obj-26": [
				"viscosity",
				"viscosity",
				0
			],
			"obj-29": [
				"project",
				"project",
				0
			],
			"obj-32": [
				"drag",
				"drag",
				0
			],
			"obj-35": [
				"gain",
				"gain",
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