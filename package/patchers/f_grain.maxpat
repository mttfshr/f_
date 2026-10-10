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
					"comment": "",
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
					"comment": "composite",
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
						0.9529411764705882,
						0.6901960784313725,
						0.6196078431372549,
						1.0
					]
				}
			},
			{
				"box": {
					"id": "obj-201",
					"maxclass": "outlet",
					"comment": "grain mask",
					"index": 0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						100.0,
						552.0,
						30.0,
						30.0
					],
					"hint": "Raw",
					"tricolor": [
						0.6196078431372549,
						0.9529411764705882,
						0.6588235294117647,
						1.0
					]
				}
			},
			{
				"box": {
					"id": "obj-202",
					"maxclass": "outlet",
					"comment": "displaced",
					"index": 0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						170.0,
						552.0,
						30.0,
						30.0
					],
					"tricolor": [
						0.9490196078431372,
						0.6196078431372549,
						0.9529411764705882,
						1.0
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
						360.0,
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
					"numoutlets": 18,
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
						1231.0,
						22.0
					],
					"text": "route bypass density gain persistence fade size size_var shape softness jitter ch_diverge luma_gate displace mix_pct edge_mode_menu field sv_seed"
				}
			},
			{
				"box": {
					"id": "obj-5",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 4,
					"outlettype": [
						"jit_gl_texture",
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
									"code": "Param src_mode(0.0);\nParam density(0.5);\nParam gain(0.5);\nParam mix_pct(100.0);\nParam era_clock(0.0);\r\nParam bypass_gate(0.0);\nParam size(0.0);\nParam size_var(0.0);\nParam shape(0.5);\nParam softness(0.0);\nParam jitter(0.0);\r\nParam fade(0.0);\nParam ch_diverge(0.0);\r\nParam luma_gate(0.0);\nParam displace(0.0);\nParam edge_mode(2.0);\nParam field(0.0);\nParam sv_seed(0.0);\n\nuv = norm;\nsrc = mix(vec(0.5, 0.5, 0.5, 1.0), sample(in1, uv), src_mode);\n\n// cell identities pinned to fixed_res \u2014 never change regardless of size\nfixed_res = 4096.0;\n// size controls viewport zoom into the fixed grid\nsize_scale = pow(2.0, mix(0.0, 12.0, size));\naspect = dim.x / dim.y;\naspect_sq = aspect * aspect;\n\n// pixel position in grid space\npx = uv.x * fixed_res * aspect / size_scale;\npy = uv.y * fixed_res / size_scale;\nicx = floor(px);\nicy = floor(py);\n\n// VORONOI JITTER: single field param navigates topology space smoothly via 1D interpolation\nf0 = floor(field); f1 = f0 + 1.0; bf = fract(field);\n\nncx = icx-1.0; ncy = icy-1.0;\njxA = mix(fract(sin((ncx+f0)*17543.2+(ncy+f0)*8976.5)*43758.5453)-0.5, fract(sin((ncx+f1)*17543.2+(ncy+f1)*8976.5)*43758.5453)-0.5, bf);\njyA = mix(fract(sin((ncx+f0)*5432.1+(ncy+f0)*13579.8)*43758.5453)-0.5, fract(sin((ncx+f1)*5432.1+(ncy+f1)*13579.8)*43758.5453)-0.5, bf);\ndxA = px-(ncx+0.5+jxA*jitter); dyA = py-(ncy+0.5+jyA*jitter);\ndA = dxA*dxA+dyA*dyA; gxA = (ncx+0.5)/fixed_res; gyA = (ncy+0.5)/fixed_res;\n\nncx = icx; ncy = icy-1.0;\njxB = mix(fract(sin((ncx+f0)*17543.2+(ncy+f0)*8976.5)*43758.5453)-0.5, fract(sin((ncx+f1)*17543.2+(ncy+f1)*8976.5)*43758.5453)-0.5, bf);\njyB = mix(fract(sin((ncx+f0)*5432.1+(ncy+f0)*13579.8)*43758.5453)-0.5, fract(sin((ncx+f1)*5432.1+(ncy+f1)*13579.8)*43758.5453)-0.5, bf);\ndxB = px-(ncx+0.5+jxB*jitter); dyB = py-(ncy+0.5+jyB*jitter);\ndB = dxB*dxB+dyB*dyB; gxB = (ncx+0.5)/fixed_res; gyB = (ncy+0.5)/fixed_res;\n\nncx = icx+1.0; ncy = icy-1.0;\njxC = mix(fract(sin((ncx+f0)*17543.2+(ncy+f0)*8976.5)*43758.5453)-0.5, fract(sin((ncx+f1)*17543.2+(ncy+f1)*8976.5)*43758.5453)-0.5, bf);\njyC = mix(fract(sin((ncx+f0)*5432.1+(ncy+f0)*13579.8)*43758.5453)-0.5, fract(sin((ncx+f1)*5432.1+(ncy+f1)*13579.8)*43758.5453)-0.5, bf);\ndxC = px-(ncx+0.5+jxC*jitter); dyC = py-(ncy+0.5+jyC*jitter);\ndC = dxC*dxC+dyC*dyC; gxC = (ncx+0.5)/fixed_res; gyC = (ncy+0.5)/fixed_res;\n\nncx = icx-1.0; ncy = icy;\njxD = mix(fract(sin((ncx+f0)*17543.2+(ncy+f0)*8976.5)*43758.5453)-0.5, fract(sin((ncx+f1)*17543.2+(ncy+f1)*8976.5)*43758.5453)-0.5, bf);\njyD = mix(fract(sin((ncx+f0)*5432.1+(ncy+f0)*13579.8)*43758.5453)-0.5, fract(sin((ncx+f1)*5432.1+(ncy+f1)*13579.8)*43758.5453)-0.5, bf);\ndxD = px-(ncx+0.5+jxD*jitter); dyD = py-(ncy+0.5+jyD*jitter);\ndD = dxD*dxD+dyD*dyD; gxD = (ncx+0.5)/fixed_res; gyD = (ncy+0.5)/fixed_res;\n\nncx = icx; ncy = icy;\njxE = mix(fract(sin((ncx+f0)*17543.2+(ncy+f0)*8976.5)*43758.5453)-0.5, fract(sin((ncx+f1)*17543.2+(ncy+f1)*8976.5)*43758.5453)-0.5, bf);\njyE = mix(fract(sin((ncx+f0)*5432.1+(ncy+f0)*13579.8)*43758.5453)-0.5, fract(sin((ncx+f1)*5432.1+(ncy+f1)*13579.8)*43758.5453)-0.5, bf);\ndxE = px-(ncx+0.5+jxE*jitter); dyE = py-(ncy+0.5+jyE*jitter);\ndE = dxE*dxE+dyE*dyE; gxE = (ncx+0.5)/fixed_res; gyE = (ncy+0.5)/fixed_res;\n\nncx = icx+1.0; ncy = icy;\njxF = mix(fract(sin((ncx+f0)*17543.2+(ncy+f0)*8976.5)*43758.5453)-0.5, fract(sin((ncx+f1)*17543.2+(ncy+f1)*8976.5)*43758.5453)-0.5, bf);\njyF = mix(fract(sin((ncx+f0)*5432.1+(ncy+f0)*13579.8)*43758.5453)-0.5, fract(sin((ncx+f1)*5432.1+(ncy+f1)*13579.8)*43758.5453)-0.5, bf);\ndxF = px-(ncx+0.5+jxF*jitter); dyF = py-(ncy+0.5+jyF*jitter);\ndF = dxF*dxF+dyF*dyF; gxF = (ncx+0.5)/fixed_res; gyF = (ncy+0.5)/fixed_res;\n\nncx = icx-1.0; ncy = icy+1.0;\njxG = mix(fract(sin((ncx+f0)*17543.2+(ncy+f0)*8976.5)*43758.5453)-0.5, fract(sin((ncx+f1)*17543.2+(ncy+f1)*8976.5)*43758.5453)-0.5, bf);\njyG = mix(fract(sin((ncx+f0)*5432.1+(ncy+f0)*13579.8)*43758.5453)-0.5, fract(sin((ncx+f1)*5432.1+(ncy+f1)*13579.8)*43758.5453)-0.5, bf);\ndxG = px-(ncx+0.5+jxG*jitter); dyG = py-(ncy+0.5+jyG*jitter);\ndG = dxG*dxG+dyG*dyG; gxG = (ncx+0.5)/fixed_res; gyG = (ncy+0.5)/fixed_res;\n\nncx = icx; ncy = icy+1.0;\njxH = mix(fract(sin((ncx+f0)*17543.2+(ncy+f0)*8976.5)*43758.5453)-0.5, fract(sin((ncx+f1)*17543.2+(ncy+f1)*8976.5)*43758.5453)-0.5, bf);\njyH = mix(fract(sin((ncx+f0)*5432.1+(ncy+f0)*13579.8)*43758.5453)-0.5, fract(sin((ncx+f1)*5432.1+(ncy+f1)*13579.8)*43758.5453)-0.5, bf);\ndxH = px-(ncx+0.5+jxH*jitter); dyH = py-(ncy+0.5+jyH*jitter);\ndH = dxH*dxH+dyH*dyH; gxH = (ncx+0.5)/fixed_res; gyH = (ncy+0.5)/fixed_res;\n\nncx = icx+1.0; ncy = icy+1.0;\njxI = mix(fract(sin((ncx+f0)*17543.2+(ncy+f0)*8976.5)*43758.5453)-0.5, fract(sin((ncx+f1)*17543.2+(ncy+f1)*8976.5)*43758.5453)-0.5, bf);\njyI = mix(fract(sin((ncx+f0)*5432.1+(ncy+f0)*13579.8)*43758.5453)-0.5, fract(sin((ncx+f1)*5432.1+(ncy+f1)*13579.8)*43758.5453)-0.5, bf);\ndxI = px-(ncx+0.5+jxI*jitter); dyI = py-(ncy+0.5+jyI*jitter);\ndI = dxI*dxI+dyI*dyI; gxI = (ncx+0.5)/fixed_res; gyI = (ncy+0.5)/fixed_res;\n\n// find nearest and second-nearest center\nbest_d = dA; second_best_d = 9999.0; best_gx = gxA; best_gy = gyA;\nt = step(dB,best_d); second_best_d=mix(min(second_best_d,dB),best_d,t); best_d=mix(best_d,dB,t); best_gx=mix(best_gx,gxB,t); best_gy=mix(best_gy,gyB,t);\nt = step(dC,best_d); second_best_d=mix(min(second_best_d,dC),best_d,t); best_d=mix(best_d,dC,t); best_gx=mix(best_gx,gxC,t); best_gy=mix(best_gy,gyC,t);\nt = step(dD,best_d); second_best_d=mix(min(second_best_d,dD),best_d,t); best_d=mix(best_d,dD,t); best_gx=mix(best_gx,gxD,t); best_gy=mix(best_gy,gyD,t);\nt = step(dE,best_d); second_best_d=mix(min(second_best_d,dE),best_d,t); best_d=mix(best_d,dE,t); best_gx=mix(best_gx,gxE,t); best_gy=mix(best_gy,gyE,t);\nt = step(dF,best_d); second_best_d=mix(min(second_best_d,dF),best_d,t); best_d=mix(best_d,dF,t); best_gx=mix(best_gx,gxF,t); best_gy=mix(best_gy,gyF,t);\nt = step(dG,best_d); second_best_d=mix(min(second_best_d,dG),best_d,t); best_d=mix(best_d,dG,t); best_gx=mix(best_gx,gxG,t); best_gy=mix(best_gy,gyG,t);\nt = step(dH,best_d); second_best_d=mix(min(second_best_d,dH),best_d,t); best_d=mix(best_d,dH,t); best_gx=mix(best_gx,gxH,t); best_gy=mix(best_gy,gyH,t);\nt = step(dI,best_d); second_best_d=mix(min(second_best_d,dI),best_d,t); best_d=mix(best_d,dI,t); best_gx=mix(best_gx,gxI,t); best_gy=mix(best_gy,gyI,t);\n\n// distances to nearest and second-nearest centers\nnearest_dist = sqrt(best_d);\nsecond_nearest_dist = sqrt(second_best_d);\n\n// per-grain displacement: each cell gets a unique random XY offset\ndisp_x = (fract(sin(best_gx * 127.1 + best_gy * 311.7) * 43758.5453) - 0.5) * displace;\ndisp_y = (fract(sin(best_gx * 269.5 + best_gy * 183.3) * 43758.5453) - 0.5) * displace;\nuv_d_raw_x = uv.x + disp_x;\nuv_d_raw_y = uv.y + disp_y;\nin_bounds = step(0.0, uv_d_raw_x) * step(uv_d_raw_x, 1.0) * step(0.0, uv_d_raw_y) * step(uv_d_raw_y, 1.0);\nuv_d = uv;\ndisp_mask = 1.0;\nif (edge_mode < 0.5) {\n    uv_d = vec(clamp(uv_d_raw_x, 0.0, 1.0), clamp(uv_d_raw_y, 0.0, 1.0));\n    disp_mask = in_bounds;\n} else if (edge_mode < 1.5) {\n    uv_d = vec(clamp(uv_d_raw_x, 0.0, 1.0), clamp(uv_d_raw_y, 0.0, 1.0));\n} else if (edge_mode < 2.5) {\n    uv_d = vec(fract(uv_d_raw_x), fract(uv_d_raw_y));\n} else {\n    uv_d = vec(1.0 - abs(fract(uv_d_raw_x * 0.5) * 2.0 - 1.0), 1.0 - abs(fract(uv_d_raw_y * 0.5) * 2.0 - 1.0));\n}\n\n// grain identity from winning Voronoi center\np1 = fract(sin(best_gx * 127.1 + best_gy * 311.7) * 43758.5453);\np2 = fract(sin(p1 * 263.77) * 43758.5453);\nera_raw = era_clock + p2;\nera = floor(era_raw);\nera_phase = fract(era_raw);\n\n// grain value \u2014 stable per era, intensity envelope handles temporal evolution\ngrain_a = fract(sin(era * 127.1 + p1 * 311.7) * 43758.5453);\ngrain_mono = grain_a;\n\n// per-channel color offset \u2014 stable per cell, not per era\ncol_g = fract(sin(best_gx * 91.3 + best_gy * 57.2) * 43758.5453) - 0.5;\ncol_b = fract(sin(best_gx * 43.1 + best_gy * 123.7) * 43758.5453) - 0.5;\n\n// blend monochrome grain toward chromatically diverged grain\ngrain_r = grain_mono;\ngrain_g = grain_mono + col_g * ch_diverge;\ngrain_b = grain_mono + col_b * ch_diverge;\n\n// polarity: era-based, stable per era\nsign_a = fract(sin(era * 263.7 + p1 * 419.2) * 43758.5453) * 2.0 - 1.0;\ngrain_sign = sign_a;\n\n// fade envelope: intensity ramps in at era start, holds, ramps out at era end\nramp = min(fade * 0.125, 0.5);\nsafe_ramp = max(ramp, 0.001);\nfade_in = smoothstep(0.0, safe_ramp, era_phase);\nfade_out = 1.0 - smoothstep(1.0 - safe_ramp, 1.0, era_phase);\ngrain_intensity = min(fade_in, fade_out);\n\n// shape: blend between circular (shape=1) and Voronoi-conforming (shape=0)\nvoronoi_boundary_dist = (nearest_dist + second_nearest_dist) * 0.5;\nt_circ = nearest_dist / 0.5;\nt_voro = nearest_dist / max(voronoi_boundary_dist, 0.001);\nshape_t = mix(t_voro, t_circ, shape);\n\n// per-cell size variation with smooth seed interpolation\nsv0 = floor(sv_seed); sv1 = sv0 + 1.0; svf = fract(sv_seed);\ncell_size_a = fract(sin((best_gx + sv0) * 213.7 + (best_gy + sv0) * 157.3) * 43758.5453);\ncell_size_b = fract(sin((best_gx + sv1) * 213.7 + (best_gy + sv1) * 157.3) * 43758.5453);\ncell_size = mix(1.0, mix(cell_size_a, cell_size_b, svf), size_var);\nshape_t = shape_t / max(cell_size, 0.001);\n\n// softness: feathered falloff in shape-blended coordinate\nfeather = mix(0.02, 0.5, softness);\nsoft_falloff = 1.0 - smoothstep(1.0 - feather, 1.0, shape_t);\n\n// density gate\nvisible = step(1.0 - density, grain_r);\n\n// displacement gated to grain shape only\nsrc_displaced = mix(src, sample(in1, uv_d), visible * soft_falloff * grain_intensity * disp_mask);\n\n// apply grain_sign (stable polarity per cell) scaled by ch_diverge for color, and gain\n// (unbounded intensity -- renamed from amount 2026-10-09, T003, gain/mix convention)\ngr = grain_sign * visible * soft_falloff * grain_intensity * gain;\ngg = (grain_sign + col_g * ch_diverge) * visible * soft_falloff * grain_intensity * gain;\ngb = (grain_sign + col_b * ch_diverge) * visible * soft_falloff * grain_intensity * gain;\n\n// luma gate: bipolar (-1=shadows +1=highlights 0=uniform)\nluma = 0.299*src.r + 0.587*src.g + 0.114*src.b;\nluma_weight = mix(1.0 - luma, luma, luma_gate * 0.5 + 0.5);\nluma_weight = pow(luma_weight, mix(1.0, 3.0, abs(luma_gate)));\nluma_mod = mix(1.0, luma_weight, clamp(abs(luma_gate) * 2.0, 0.0, 1.0));\ngr *= luma_mod;\ngg *= luma_mod;\ngb *= luma_mod;\n\n// gain/mix convention (T003): driven = the complete composited state (source included),\n// mix_pct a plain crossfade toward it -- NOT a bare effect layer (vsynth-bpatcher skill,\n// \"Canonical naming: gain vs mix\" -- a sparse layer double-images under a uniform crossfade).\ndriven_r = clamp(src_displaced.r + gr, 0.0, 1.0);\ndriven_g = clamp(src_displaced.g + gg, 0.0, 1.0);\ndriven_b = clamp(src_displaced.b + gb, 0.0, 1.0);\ncomposited = vec(mix(src_displaced.r, driven_r, mix_pct / 100.0),\n                  mix(src_displaced.g, driven_g, mix_pct / 100.0),\n                  mix(src_displaced.b, driven_b, mix_pct / 100.0),\n                  src_displaced.a);\nraw = vec(grain_sign * visible * soft_falloff * grain_intensity, grain_sign * visible * soft_falloff * grain_intensity, grain_sign * visible * soft_falloff * grain_intensity, 1.0);\n\n// bypass (bypass_mode \"param\"): passthrough on every outlet (Matt, 2026-10-05).\n// The source when it is connected, black when it is not (src_mode): the dual-module convention.\nbypass_px = mix(vec(0.0, 0.0, 0.0, 1.0), sample(in1, uv), src_mode);\nout1 = mix(composited, bypass_px, bypass_gate);\nout2 = mix(raw, bypass_px, bypass_gate);\nout3 = mix(src_displaced, bypass_px, bypass_gate);",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
									"id": "gen-obj-2",
									"maxclass": "codebox",
									"numinlets": 1,
									"numoutlets": 3,
									"outlettype": [
										"",
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
							},
							{
								"box": {
									"id": "gen-obj-5",
									"maxclass": "newobj",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										142.0,
										490.0,
										35.0,
										22.0
									],
									"text": "out 3"
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
							},
							{
								"patchline": {
									"destination": [
										"gen-obj-5",
										0
									],
									"source": [
										"gen-obj-2",
										2
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
					"text": "jit.gl.pix vsynth @name grain_pix @type char",
					"varname": "grain_pix"
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
						1567.5,
						100.0,
						56.0,
						22.0
					],
					"text": "autopattr",
					"varname": "grain_autopattr"
				}
			},
			{
				"box": {
					"id": "obj-9",
					"maxclass": "panel",
					"angle": 270.0,
					"background": 1,
					"bgcolor": [
						0.058823529411764705,
						0.058823529411764705,
						0.058823529411764705,
						1.0
					],
					"border": 1,
					"bordercolor": [
						0.0,
						0.03529411764705882,
						0.22745098039215686,
						1.0
					],
					"mode": 0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						1347.5,
						260.0,
						227.0,
						164.0
					],
					"presentation": 1,
					"presentation_rect": [
						2.0,
						2.0,
						227.0,
						164.0
					],
					"proportion": 0.5
				}
			},
			{
				"box": {
					"id": "obj-10",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						1567.5,
						200.0,
						80.0,
						21.0
					],
					"presentation": 1,
					"presentation_rect": [
						4.0,
						0.5,
						60.0,
						21.0
					],
					"text": "Grain"
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
						1347.5,
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
						1347.5,
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
						1347.5,
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
						1347.5,
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
						1347.5,
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
						1347.5,
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
						410.0,
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
						440.0,
						145.0,
						22.0
					],
					"text": "prepend param src_mode"
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
					"hint": "Grain density",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "grain_pix::density",
					"parameter_enable": 1,
					"patching_rect": [
						118.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						42.00000011920929,
						115.0,
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
					"id": "obj-21",
					"maxclass": "attrui",
					"attr": "density",
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
					"id": "obj-22",
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
						42.00000125169754,
						99.00000295042992,
						35.0,
						18.0
					],
					"text": "Dens",
					"varname": "lbl_density"
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
					"hint": "Grain intensity (unbounded). Renamed from amount 2026-10-09 (T003) to match the library-wide gain/mix convention.",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "grain_pix::gain",
					"parameter_enable": 1,
					"patching_rect": [
						190.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						6.0,
						115.0,
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
							"parameter_mmax": 2.0,
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
					"id": "obj-24",
					"maxclass": "attrui",
					"attr": "gain",
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
					"id": "obj-25",
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
						8.0,
						99.0,
						30.0,
						18.0
					],
					"text": "Gain",
					"varname": "lbl_gain"
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
					"hint": "Temporal persistence (0=boil 1=frozen)",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "grain_pix::persistence",
					"parameter_enable": 1,
					"patching_rect": [
						262.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						188.0,
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
							"parameter_longname": "persistence",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "persistence",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "persistence"
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
						251.0,
						180.0,
						50.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						184.0,
						22.0,
						37.5,
						18.0
					],
					"text": "Freeze",
					"varname": "lbl_persistence",
					"linecount": 2
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
					"hint": "Temporal persistence (0=boil 1=frozen)",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "grain_pix::fade",
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
							"parameter_longname": "fade",
							"parameter_mmax": 4.0,
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
					"id": "obj-30",
					"maxclass": "attrui",
					"attr": "fade",
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
					"id": "obj-31",
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
						153.0,
						22.0,
						30.0,
						18.0
					],
					"text": "Fade",
					"varname": "lbl_fade"
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
					"hint": "Grain size",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "grain_pix::size",
					"parameter_enable": 1,
					"patching_rect": [
						406.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						6.0,
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
							"parameter_longname": "size",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "size",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "size"
				}
			},
			{
				"box": {
					"id": "obj-33",
					"maxclass": "attrui",
					"attr": "size",
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
					"id": "obj-34",
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
						5.0,
						22.0,
						30.0,
						18.0
					],
					"text": "Size",
					"varname": "lbl_size"
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
					"hint": "Grain size variation",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "grain_pix::size_var",
					"parameter_enable": 1,
					"patching_rect": [
						478.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						42.00000011920929,
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
							"parameter_longname": "size_var",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "size_var",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "size_var"
				}
			},
			{
				"box": {
					"id": "obj-36",
					"maxclass": "attrui",
					"attr": "size_var",
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
					"id": "obj-37",
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
						41.00000011920929,
						22.0,
						32.0,
						18.0
					],
					"text": "S.var",
					"varname": "lbl_size_var"
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
					"hint": "Grain aspect ratio (-1=portrait 0=square 1=landscape)",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "grain_pix::shape",
					"parameter_enable": 1,
					"patching_rect": [
						550.5,
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
							"parameter_longname": "shape",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "shape",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "shape"
				}
			},
			{
				"box": {
					"id": "obj-39",
					"maxclass": "attrui",
					"attr": "shape",
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
					"id": "obj-40",
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
						112.0,
						22.0,
						35.0,
						18.0
					],
					"text": "Shape",
					"varname": "lbl_shape"
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
					"hint": "Grain edge softness",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "grain_pix::softness",
					"parameter_enable": 1,
					"patching_rect": [
						622.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						116.0,
						115.0,
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
					"id": "obj-42",
					"maxclass": "attrui",
					"attr": "softness",
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
					"id": "obj-43",
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
						116.0,
						99.0,
						28.0,
						18.0
					],
					"text": "Soft",
					"varname": "lbl_softness"
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
					"hint": "Grain position jitter (0=grid 1=scattered)",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "grain_pix::jitter",
					"parameter_enable": 1,
					"patching_rect": [
						694.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						79.0,
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
							"parameter_longname": "jitter",
							"parameter_mmax": 2.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "jitter",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "jitter"
				}
			},
			{
				"box": {
					"id": "obj-45",
					"maxclass": "attrui",
					"attr": "jitter",
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
					"id": "obj-46",
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
						77.0,
						22.0,
						31.0,
						18.0
					],
					"text": "Jitter",
					"varname": "lbl_jitter",
					"linecount": 2
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
					"hint": "Temporal persistence (0=boil 1=frozen)",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "grain_pix::ch_diverge",
					"parameter_enable": 1,
					"patching_rect": [
						766.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						79.0,
						115.0,
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
							"parameter_longname": "ch_diverge",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "ch_diverge",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "ch_diverge"
				}
			},
			{
				"box": {
					"id": "obj-48",
					"maxclass": "attrui",
					"attr": "ch_diverge",
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
					"id": "obj-49",
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
						79.00000235438347,
						99.00000295042992,
						34.0,
						18.0
					],
					"text": "Color",
					"varname": "lbl_ch_diverge"
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
					"hint": "Luma gate: bipolar (-1=shadows 0=uniform +1=highlights)",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "grain_pix::luma_gate",
					"parameter_enable": 1,
					"patching_rect": [
						838.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						152.0,
						115.0,
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
							"parameter_longname": "luma_gate",
							"parameter_mmax": 1.0,
							"parameter_mmin": -1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "luma_gate",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "luma_gate"
				}
			},
			{
				"box": {
					"id": "obj-51",
					"maxclass": "attrui",
					"attr": "luma_gate",
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
					"id": "obj-52",
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
						151.0,
						99.0,
						35.333334386348724,
						18.0
					],
					"text": "L.gate",
					"varname": "lbl_luma_gate",
					"linecount": 2
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
					"hint": "Per-grain displacement amount",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "grain_pix::displace",
					"parameter_enable": 1,
					"patching_rect": [
						910.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						188.0,
						115.0,
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
							"parameter_longname": "displace",
							"parameter_mmax": 0.5,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "displace",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "displace"
				}
			},
			{
				"box": {
					"id": "obj-54",
					"maxclass": "attrui",
					"attr": "displace",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						890.0,
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
						899.0,
						180.0,
						50.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						187.0,
						99.0,
						34.0,
						18.0
					],
					"text": "Displ",
					"varname": "lbl_displace"
				}
			},
			{
				"box": {
					"id": "obj-56",
					"maxclass": "live.numbox",
					"fontname": "Ableton Sans Light",
					"hint": "Dry/wet crossfade toward the fully-composited (displaced-source + grain) state. New 2026-10-09 (T003); default 100 keeps the module's prior look unchanged. Internal Param named mix_pct to avoid colliding with the codebox's mix() operator.",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "grain_pix::mix_pct",
					"parameter_enable": 1,
					"patching_rect": [
						974.0,
						250.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						78.0,
						162.0,
						34.0,
						15.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								100.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "mix_pct",
							"parameter_mmax": 100.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "mix_pct",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"varname": "mix_pct"
				}
			},
			{
				"box": {
					"id": "obj-57",
					"maxclass": "attrui",
					"attr": "mix_pct",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						962.0,
						310.0,
						68.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-58",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						971.0,
						180.0,
						50.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						66.5,
						144.0,
						50.0,
						18.0
					],
					"text": "Mix",
					"textjustification": 1,
					"varname": "lbl_mix_pct"
				}
			},
			{
				"box": {
					"id": "obj-59",
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
						51.0,
						250.0,
						18.0,
						12.0
					],
					"presentation_rect": [
						208.00000309944153,
						5.600000083446503,
						18.0,
						12.0
					],
					"varname": "bypass"
				}
			},
			{
				"box": {
					"id": "obj-60",
					"maxclass": "newobj",
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
					"text": "prepend param bypass_gate"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"id": "obj-901",
					"maxclass": "live.numbox",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "grain_pix::field",
					"parameter_enable": 1,
					"patching_rect": [
						971.0,
						646.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						77.0,
						80.0,
						31.0,
						15.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "field",
							"parameter_mmax": 5.0,
							"parameter_modmode": 3,
							"parameter_shortname": "field",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"varname": "field_1"
				}
			},
			{
				"box": {
					"id": "obj-902",
					"maxclass": "newobj",
					"numinlets": 3,
					"numoutlets": 3,
					"outlettype": [
						"",
						"",
						""
					],
					"patching_rect": [
						953.0,
						767.5,
						120.0,
						22.0
					],
					"text": "route field sv_seed"
				}
			},
			{
				"box": {
					"id": "obj-903",
					"maxclass": "newobj",
					"numinlets": 0,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						30.0,
						1045.5,
						50.0,
						22.0
					],
					"text": "r draw"
				}
			},
			{
				"box": {
					"id": "obj-904",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"float"
					],
					"patching_rect": [
						62.0,
						1086.5,
						28.0,
						22.0
					],
					"text": "f"
				}
			},
			{
				"box": {
					"attr": "era_clock",
					"id": "obj-905",
					"maxclass": "attrui",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"parameter_enable": 0,
					"patching_rect": [
						93.0,
						1169.5,
						160.0,
						22.0
					]
				}
			},
			{
				"box": {
					"bgcolor": [
						0.0196078431372549,
						0.0196078431372549,
						0.0196078431372549,
						0.0
					],
					"bgfillcolor_angle": 270.0,
					"bgfillcolor_autogradient": 0.0,
					"bgfillcolor_color": [
						0.0196078431372549,
						0.0196078431372549,
						0.0196078431372549,
						0.0
					],
					"bgfillcolor_color1": [
						0.058823529411764705,
						0.058823529411764705,
						0.058823529411764705,
						1.0
					],
					"bgfillcolor_color2": [
						0.158640689195807,
						0.158640642399981,
						0.158640654628478,
						1.0
					],
					"bgfillcolor_proportion": 0.5,
					"bgfillcolor_type": "color",
					"fontname": "Ableton Sans Light",
					"id": "obj-906",
					"items": [
						"Clear",
						",",
						"Clamp",
						",",
						"Wrap",
						",",
						"Mirror"
					],
					"maxclass": "umenu",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"int",
						"",
						""
					],
					"parameter_enable": 1,
					"patching_rect": [
						890.5,
						642.0,
						115.0,
						23.0
					],
					"presentation": 1,
					"presentation_rect": [
						210.0,
						97.0,
						23.5,
						23.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								2
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "edge_mode_menu",
							"parameter_mmax": 3.0,
							"parameter_modmode": 0,
							"parameter_shortname": "edge_mode_menu",
							"parameter_type": 1,
							"parameter_unitstyle": 0
						}
					},
					"varname": "edge_mode_menu"
				}
			},
			{
				"box": {
					"attr": "edge_mode",
					"id": "obj-907",
					"maxclass": "attrui",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"parameter_enable": 0,
					"patching_rect": [
						897.0,
						711.5,
						157.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-908",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						83.0,
						1045.5,
						180.0,
						22.0
					],
					"text": "expr pow(1.0 - $f1\\, 2.0)"
				}
			},
			{
				"box": {
					"id": "obj-909",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"float"
					],
					"patching_rect": [
						69.5,
						1128.5,
						32.0,
						22.0
					],
					"text": "+ 0."
				}
			},
			{
				"box": {
					"id": "obj-910",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"float",
						"float"
					],
					"patching_rect": [
						109.0,
						1090.5,
						42.0,
						22.0
					],
					"text": "t f f"
				}
			},
			{
				"box": {
					"attr": "field",
					"id": "obj-911",
					"maxclass": "attrui",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"parameter_enable": 0,
					"patching_rect": [
						985.0,
						802.5,
						140.0,
						22.0
					]
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"id": "obj-912",
					"maxclass": "live.numbox",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "grain_pix::sv_seed",
					"parameter_enable": 1,
					"patching_rect": [
						1039.5,
						646.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						38.00000011920929,
						80.0,
						34.0,
						15.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_longname": "sv_seed",
							"parameter_mmax": 5.0,
							"parameter_modmode": 3,
							"parameter_shortname": "sv_seed",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"varname": "sv_seed"
				}
			},
			{
				"box": {
					"attr": "sv_seed",
					"id": "obj-913",
					"maxclass": "attrui",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"parameter_enable": 0,
					"patching_rect": [
						1033.0,
						840.5,
						152.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-914",
					"maxclass": "newobj",
					"numinlets": 0,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						257.0,
						1217.0,
						48.0,
						22.0
					],
					"text": "r draw"
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
						"obj-4",
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
						"obj-5",
						0
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
						"obj-5",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-4",
						17
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
						"obj-5",
						2
					],
					"destination": [
						"obj-202",
						0
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
						"obj-5",
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
						"obj-59",
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
						1
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
						2
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
						3
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
						"obj-4",
						4
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
						5
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
						6
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
						7
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
						8
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
						9
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
						10
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
						11
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
						12
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
						"obj-4",
						13
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
						"obj-5",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-5",
						0
					],
					"source": [
						"obj-905",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-908",
						0
					],
					"source": [
						"obj-26",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-911",
						0
					],
					"source": [
						"obj-901",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-907",
						0
					],
					"source": [
						"obj-906",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-5",
						0
					],
					"source": [
						"obj-907",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-904",
						1
					],
					"source": [
						"obj-908",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-910",
						0
					],
					"source": [
						"obj-909",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-905",
						0
					],
					"source": [
						"obj-910",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-909",
						1
					],
					"source": [
						"obj-910",
						1
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-904",
						0
					],
					"source": [
						"obj-903",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-5",
						0
					],
					"source": [
						"obj-911",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-913",
						0
					],
					"source": [
						"obj-912",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-5",
						0
					],
					"source": [
						"obj-913",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-902",
						0
					],
					"source": [
						"obj-3",
						1
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-901",
						0
					],
					"source": [
						"obj-902",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-912",
						0
					],
					"source": [
						"obj-902",
						1
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-901",
						0
					],
					"source": [
						"obj-4",
						15
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-906",
						0
					],
					"source": [
						"obj-4",
						14
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-912",
						0
					],
					"source": [
						"obj-4",
						16
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-909",
						0
					],
					"source": [
						"obj-904",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-5",
						0
					],
					"source": [
						"obj-914",
						0
					]
				}
			}
		],
		"parameters": {
			"obj-20": [
				"density",
				"density",
				0
			],
			"obj-23": [
				"gain",
				"gain",
				0
			],
			"obj-26": [
				"persistence",
				"persistence",
				0
			],
			"obj-29": [
				"fade",
				"fade",
				0
			],
			"obj-32": [
				"size",
				"size",
				0
			],
			"obj-35": [
				"size_var",
				"size_var",
				0
			],
			"obj-38": [
				"shape",
				"shape",
				0
			],
			"obj-41": [
				"softness",
				"softness",
				0
			],
			"obj-44": [
				"jitter",
				"jitter",
				0
			],
			"obj-47": [
				"ch_diverge",
				"ch_diverge",
				0
			],
			"obj-50": [
				"luma_gate",
				"luma_gate",
				0
			],
			"obj-53": [
				"displace",
				"displace",
				0
			],
			"obj-56": [
				"mix_pct",
				"mix_pct",
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
			"inherited_shortname": 1,
			"obj-901": [
				"field",
				"field",
				0
			],
			"obj-906": [
				"edge_mode_menu",
				"edge_mode_menu",
				0
			],
			"obj-912": [
				"sv_seed",
				"sv_seed",
				0
			]
		},
		"autosave": 0
	}
}