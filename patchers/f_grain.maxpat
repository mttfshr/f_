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
					"comment": "composite",
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
					"id": "obj-201",
					"maxclass": "outlet",
					"comment": "grain mask",
					"index": 1,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						100.0,
						500.0,
						30.0,
						30.0
					]
				}
			},
			{
				"box": {
					"id": "obj-202",
					"maxclass": "outlet",
					"comment": "displaced",
					"index": 2,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						170.0,
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
						200.0,
						130.0,
						616.0,
						22.0
					],
					"text": "route size size_var shape jitter fade persistence amount density ch_diverge luma_gate displace"
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
									"code": "Param src_mode(0.0);\nParam density(0.5);\nParam amount(0.5);\nParam era_clock(0.0);\nParam bypass(0.0);\nParam size(0.0);\nParam size_var(0.0);\nParam shape(0.5);\nParam softness(0.0);\nParam jitter(0.0);\nParam fade(0.0);\nParam ch_diverge(0.0);\nParam luma_gate(0.0);\nParam displace(0.0);\nParam edge_mode(2.0);\nParam field(0.0);\nParam sv_seed(0.0);\n\nuv = norm;\nsrc = mix(vec(0.5, 0.5, 0.5, 1.0), sample(in1, uv), src_mode);\n\n// cell identities pinned to fixed_res\nfixed_res = 4096.0;\nsize_scale = pow(2.0, mix(0.0, 12.0, size));\naspect = dim.x / dim.y;\naspect_sq = aspect * aspect;\n\npx = uv.x * fixed_res * aspect / size_scale;\npy = uv.y * fixed_res / size_scale;\nicx = floor(px);\nicy = floor(py);\n\nf0 = floor(field); f1 = f0 + 1.0; bf = fract(field);\n\nncx = icx-1.0; ncy = icy-1.0;\njxA = mix(fract(sin((ncx+f0)*17543.2+(ncy+f0)*8976.5)*43758.5453)-0.5, fract(sin((ncx+f1)*17543.2+(ncy+f1)*8976.5)*43758.5453)-0.5, bf);\njyA = mix(fract(sin((ncx+f0)*5432.1+(ncy+f0)*13579.8)*43758.5453)-0.5, fract(sin((ncx+f1)*5432.1+(ncy+f1)*13579.8)*43758.5453)-0.5, bf);\ndxA = px-(ncx+0.5+jxA*jitter); dyA = py-(ncy+0.5+jyA*jitter);\ndA = dxA*dxA+dyA*dyA; gxA = (ncx+0.5)/fixed_res; gyA = (ncy+0.5)/fixed_res;\n\nncx = icx; ncy = icy-1.0;\njxB = mix(fract(sin((ncx+f0)*17543.2+(ncy+f0)*8976.5)*43758.5453)-0.5, fract(sin((ncx+f1)*17543.2+(ncy+f1)*8976.5)*43758.5453)-0.5, bf);\njyB = mix(fract(sin((ncx+f0)*5432.1+(ncy+f0)*13579.8)*43758.5453)-0.5, fract(sin((ncx+f1)*5432.1+(ncy+f1)*13579.8)*43758.5453)-0.5, bf);\ndxB = px-(ncx+0.5+jxB*jitter); dyB = py-(ncy+0.5+jyB*jitter);\ndB = dxB*dxB+dyB*dyB; gxB = (ncx+0.5)/fixed_res; gyB = (ncy+0.5)/fixed_res;\n\nncx = icx+1.0; ncy = icy-1.0;\njxC = mix(fract(sin((ncx+f0)*17543.2+(ncy+f0)*8976.5)*43758.5453)-0.5, fract(sin((ncx+f1)*17543.2+(ncy+f1)*8976.5)*43758.5453)-0.5, bf);\njyC = mix(fract(sin((ncx+f0)*5432.1+(ncy+f0)*13579.8)*43758.5453)-0.5, fract(sin((ncx+f1)*5432.1+(ncy+f1)*13579.8)*43758.5453)-0.5, bf);\ndxC = px-(ncx+0.5+jxC*jitter); dyC = py-(ncy+0.5+jyC*jitter);\ndC = dxC*dxC+dyC*dyC; gxC = (ncx+0.5)/fixed_res; gyC = (ncy+0.5)/fixed_res;\n\nncx = icx-1.0; ncy = icy;\njxD = mix(fract(sin((ncx+f0)*17543.2+(ncy+f0)*8976.5)*43758.5453)-0.5, fract(sin((ncx+f1)*17543.2+(ncy+f1)*8976.5)*43758.5453)-0.5, bf);\njyD = mix(fract(sin((ncx+f0)*5432.1+(ncy+f0)*13579.8)*43758.5453)-0.5, fract(sin((ncx+f1)*5432.1+(ncy+f1)*13579.8)*43758.5453)-0.5, bf);\ndxD = px-(ncx+0.5+jxD*jitter); dyD = py-(ncy+0.5+jyD*jitter);\ndD = dxD*dxD+dyD*dyD; gxD = (ncx+0.5)/fixed_res; gyD = (ncy+0.5)/fixed_res;\n\nncx = icx; ncy = icy;\njxE = mix(fract(sin((ncx+f0)*17543.2+(ncy+f0)*8976.5)*43758.5453)-0.5, fract(sin((ncx+f1)*17543.2+(ncy+f1)*8976.5)*43758.5453)-0.5, bf);\njyE = mix(fract(sin((ncx+f0)*5432.1+(ncy+f0)*13579.8)*43758.5453)-0.5, fract(sin((ncx+f1)*5432.1+(ncy+f1)*13579.8)*43758.5453)-0.5, bf);\ndxE = px-(ncx+0.5+jxE*jitter); dyE = py-(ncy+0.5+jyE*jitter);\ndE = dxE*dxE+dyE*dyE; gxE = (ncx+0.5)/fixed_res; gyE = (ncy+0.5)/fixed_res;\n\nncx = icx+1.0; ncy = icy;\njxF = mix(fract(sin((ncx+f0)*17543.2+(ncy+f0)*8976.5)*43758.5453)-0.5, fract(sin((ncx+f1)*17543.2+(ncy+f1)*8976.5)*43758.5453)-0.5, bf);\njyF = mix(fract(sin((ncx+f0)*5432.1+(ncy+f0)*13579.8)*43758.5453)-0.5, fract(sin((ncx+f1)*5432.1+(ncy+f1)*13579.8)*43758.5453)-0.5, bf);\ndxF = px-(ncx+0.5+jxF*jitter); dyF = py-(ncy+0.5+jyF*jitter);\ndF = dxF*dxF+dyF*dyF; gxF = (ncx+0.5)/fixed_res; gyF = (ncy+0.5)/fixed_res;\n\nncx = icx-1.0; ncy = icy+1.0;\njxG = mix(fract(sin((ncx+f0)*17543.2+(ncy+f0)*8976.5)*43758.5453)-0.5, fract(sin((ncx+f1)*17543.2+(ncy+f1)*8976.5)*43758.5453)-0.5, bf);\njyG = mix(fract(sin((ncx+f0)*5432.1+(ncy+f0)*13579.8)*43758.5453)-0.5, fract(sin((ncx+f1)*5432.1+(ncy+f1)*13579.8)*43758.5453)-0.5, bf);\ndxG = px-(ncx+0.5+jxG*jitter); dyG = py-(ncy+0.5+jyG*jitter);\ndG = dxG*dxG+dyG*dyG; gxG = (ncx+0.5)/fixed_res; gyG = (ncy+0.5)/fixed_res;\n\nncx = icx; ncy = icy+1.0;\njxH = mix(fract(sin((ncx+f0)*17543.2+(ncy+f0)*8976.5)*43758.5453)-0.5, fract(sin((ncx+f1)*17543.2+(ncy+f1)*8976.5)*43758.5453)-0.5, bf);\njyH = mix(fract(sin((ncx+f0)*5432.1+(ncy+f0)*13579.8)*43758.5453)-0.5, fract(sin((ncx+f1)*5432.1+(ncy+f1)*13579.8)*43758.5453)-0.5, bf);\ndxH = px-(ncx+0.5+jxH*jitter); dyH = py-(ncy+0.5+jyH*jitter);\ndH = dxH*dxH+dyH*dyH; gxH = (ncx+0.5)/fixed_res; gyH = (ncy+0.5)/fixed_res;\n\nncx = icx+1.0; ncy = icy+1.0;\njxI = mix(fract(sin((ncx+f0)*17543.2+(ncy+f0)*8976.5)*43758.5453)-0.5, fract(sin((ncx+f1)*17543.2+(ncy+f1)*8976.5)*43758.5453)-0.5, bf);\njyI = mix(fract(sin((ncx+f0)*5432.1+(ncy+f0)*13579.8)*43758.5453)-0.5, fract(sin((ncx+f1)*5432.1+(ncy+f1)*13579.8)*43758.5453)-0.5, bf);\ndxI = px-(ncx+0.5+jxI*jitter); dyI = py-(ncy+0.5+jyI*jitter);\ndI = dxI*dxI+dyI*dyI; gxI = (ncx+0.5)/fixed_res; gyI = (ncy+0.5)/fixed_res;\n\nbest_d = dA; second_best_d = 9999.0; best_gx = gxA; best_gy = gyA;\nt = step(dB,best_d); second_best_d=mix(min(second_best_d,dB),best_d,t); best_d=mix(best_d,dB,t); best_gx=mix(best_gx,gxB,t); best_gy=mix(best_gy,gyB,t);\nt = step(dC,best_d); second_best_d=mix(min(second_best_d,dC),best_d,t); best_d=mix(best_d,dC,t); best_gx=mix(best_gx,gxC,t); best_gy=mix(best_gy,gyC,t);\nt = step(dD,best_d); second_best_d=mix(min(second_best_d,dD),best_d,t); best_d=mix(best_d,dD,t); best_gx=mix(best_gx,gxD,t); best_gy=mix(best_gy,gyD,t);\nt = step(dE,best_d); second_best_d=mix(min(second_best_d,dE),best_d,t); best_d=mix(best_d,dE,t); best_gx=mix(best_gx,gxE,t); best_gy=mix(best_gy,gyE,t);\nt = step(dF,best_d); second_best_d=mix(min(second_best_d,dF),best_d,t); best_d=mix(best_d,dF,t); best_gx=mix(best_gx,gxF,t); best_gy=mix(best_gy,gyF,t);\nt = step(dG,best_d); second_best_d=mix(min(second_best_d,dG),best_d,t); best_d=mix(best_d,dG,t); best_gx=mix(best_gx,gxG,t); best_gy=mix(best_gy,gyG,t);\nt = step(dH,best_d); second_best_d=mix(min(second_best_d,dH),best_d,t); best_d=mix(best_d,dH,t); best_gx=mix(best_gx,gxH,t); best_gy=mix(best_gy,gyH,t);\nt = step(dI,best_d); second_best_d=mix(min(second_best_d,dI),best_d,t); best_d=mix(best_d,dI,t); best_gx=mix(best_gx,gxI,t); best_gy=mix(best_gy,gyI,t);\n\nnearest_dist = sqrt(best_d);\nsecond_nearest_dist = sqrt(second_best_d);\n\ndisp_x = (fract(sin(best_gx * 127.1 + best_gy * 311.7) * 43758.5453) - 0.5) * displace;\ndisp_y = (fract(sin(best_gx * 269.5 + best_gy * 183.3) * 43758.5453) - 0.5) * displace;\nuv_d_raw_x = uv.x + disp_x;\nuv_d_raw_y = uv.y + disp_y;\nin_bounds = step(0.0, uv_d_raw_x) * step(uv_d_raw_x, 1.0) * step(0.0, uv_d_raw_y) * step(uv_d_raw_y, 1.0);\nuv_d = uv;\ndisp_mask = 1.0;\nif (edge_mode < 0.5) {\n    uv_d = vec(clamp(uv_d_raw_x, 0.0, 1.0), clamp(uv_d_raw_y, 0.0, 1.0));\n    disp_mask = in_bounds;\n} else if (edge_mode < 1.5) {\n    uv_d = vec(clamp(uv_d_raw_x, 0.0, 1.0), clamp(uv_d_raw_y, 0.0, 1.0));\n} else if (edge_mode < 2.5) {\n    uv_d = vec(fract(uv_d_raw_x), fract(uv_d_raw_y));\n} else {\n    uv_d = vec(1.0 - abs(fract(uv_d_raw_x * 0.5) * 2.0 - 1.0), 1.0 - abs(fract(uv_d_raw_y * 0.5) * 2.0 - 1.0));\n}\n\np1 = fract(sin(best_gx * 127.1 + best_gy * 311.7) * 43758.5453);\np2 = fract(sin(p1 * 263.77) * 43758.5453);\nera_raw = era_clock + p2;\nera = floor(era_raw);\nera_phase = fract(era_raw);\n\ngrain_a = fract(sin(era * 127.1 + p1 * 311.7) * 43758.5453);\ngrain_mono = grain_a;\n\ncol_g = fract(sin(best_gx * 91.3 + best_gy * 57.2) * 43758.5453) - 0.5;\ncol_b = fract(sin(best_gx * 43.1 + best_gy * 123.7) * 43758.5453) - 0.5;\n\ngrain_r = grain_mono;\ngrain_g = grain_mono + col_g * ch_diverge;\ngrain_b = grain_mono + col_b * ch_diverge;\n\nsign_a = fract(sin(era * 263.7 + p1 * 419.2) * 43758.5453) * 2.0 - 1.0;\ngrain_sign = sign_a;\n\nramp = min(fade * 0.125, 0.5);\nsafe_ramp = max(ramp, 0.001);\nfade_in = smoothstep(0.0, safe_ramp, era_phase);\nfade_out = 1.0 - smoothstep(1.0 - safe_ramp, 1.0, era_phase);\ngrain_intensity = min(fade_in, fade_out);\n\nvoronoi_boundary_dist = (nearest_dist + second_nearest_dist) * 0.5;\nt_circ = nearest_dist / 0.5;\nt_voro = nearest_dist / max(voronoi_boundary_dist, 0.001);\nshape_t = mix(t_voro, t_circ, shape);\n\nsv0 = floor(sv_seed); sv1 = sv0 + 1.0; svf = fract(sv_seed);\ncell_size_a = fract(sin((best_gx + sv0) * 213.7 + (best_gy + sv0) * 157.3) * 43758.5453);\ncell_size_b = fract(sin((best_gx + sv1) * 213.7 + (best_gy + sv1) * 157.3) * 43758.5453);\ncell_size = mix(1.0, mix(cell_size_a, cell_size_b, svf), size_var);\nshape_t = shape_t / max(cell_size, 0.001);\n\nfeather = mix(0.02, 0.5, softness);\nsoft_falloff = 1.0 - smoothstep(1.0 - feather, 1.0, shape_t);\n\nvisible = step(1.0 - density, grain_r);\n\nsrc_displaced = mix(src, sample(in1, uv_d), visible * soft_falloff * grain_intensity * disp_mask);\n\ngr = grain_sign * visible * soft_falloff * grain_intensity * amount;\ngg = (grain_sign + col_g * ch_diverge) * visible * soft_falloff * grain_intensity * amount;\ngb = (grain_sign + col_b * ch_diverge) * visible * soft_falloff * grain_intensity * amount;\n\nluma = 0.299*src.r + 0.587*src.g + 0.114*src.b;\nluma_weight = mix(1.0 - luma, luma, luma_gate * 0.5 + 0.5);\nluma_weight = pow(luma_weight, mix(1.0, 3.0, abs(luma_gate)));\nluma_mod = mix(1.0, luma_weight, clamp(abs(luma_gate) * 2.0, 0.0, 1.0));\ngr *= luma_mod;\ngg *= luma_mod;\ngb *= luma_mod;\ncomposited = vec(src_displaced.r + gr, src_displaced.g + gg, src_displaced.b + gb, src_displaced.a);\nraw = vec(grain_sign * visible * soft_falloff * grain_intensity, grain_sign * visible * soft_falloff * grain_intensity, grain_sign * visible * soft_falloff * grain_intensity, 1.0);\n\neffective_bp = 1.0 - bypass;\nout1 = mix(src, composited, effective_bp);\nout2 = raw;\nout3 = mix(src, src_displaced, effective_bp);\n",
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
						200.0,
						380.0,
						200.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name grain_pix",
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
						500.0,
						500.0,
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
						227.0,
						164.0
					],
					"presentation": 1,
					"presentation_rect": [
						0.0,
						0.0,
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
					"hint": "Grain size \u2014 exponential zoom into fixed voronoi grid",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "grain_pix::size",
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
					"id": "obj-21",
					"maxclass": "attrui",
					"attr": "size",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						50.0,
						170.0,
						108.0,
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
					"text": "Size",
					"textjustification": 1
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
					"hint": "Per-cell size variation amount",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "grain_pix::size_var",
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
					"id": "obj-24",
					"maxclass": "attrui",
					"attr": "size_var",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						100.0,
						200.0,
						136.0,
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
					"text": "S.var",
					"textjustification": 1
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
					"hint": "0=voronoi-conforming  1=circular",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "grain_pix::shape",
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
					"id": "obj-27",
					"maxclass": "attrui",
					"attr": "shape",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						150.0,
						230.0,
						115.0,
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
					"text": "Shape",
					"textjustification": 1
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
					"hint": "Voronoi center displacement (0=grid 1=scattered)",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "grain_pix::jitter",
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
					"id": "obj-30",
					"maxclass": "attrui",
					"attr": "jitter",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						200.0,
						260.0,
						122.0,
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
					"text": "Jitter",
					"textjustification": 1
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
					"hint": "Grain crossfade duration at era boundaries",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "grain_pix::fade",
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
					"id": "obj-33",
					"maxclass": "attrui",
					"attr": "fade",
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
					"text": "Fade",
					"textjustification": 1
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
					"hint": "Temporal persistence (0=boil 1=frozen) \u2014 scales era_clock in parent patch",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "grain_pix::persistence",
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
					"id": "obj-36",
					"maxclass": "attrui",
					"attr": "persistence",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						300.0,
						320.0,
						157.0,
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
					"text": "Freeze",
					"textjustification": 1
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
					"hint": "Grain blend weight",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "grain_pix::amount",
					"parameter_enable": 1,
					"patching_rect": [
						350.0,
						80.0,
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
							"parameter_longname": "amount",
							"parameter_mmax": 2.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "amount",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "amount"
				}
			},
			{
				"box": {
					"id": "obj-39",
					"maxclass": "attrui",
					"attr": "amount",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						350.0,
						350.0,
						122.0,
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
						350.0,
						130.0,
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
					"text": "Amt",
					"textjustification": 1
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
					"hint": "Fraction of cells that are visible",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "grain_pix::density",
					"parameter_enable": 1,
					"patching_rect": [
						400.0,
						80.0,
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
					"id": "obj-42",
					"maxclass": "attrui",
					"attr": "density",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						400.0,
						380.0,
						129.0,
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
						400.0,
						130.0,
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
					"text": "Dens",
					"textjustification": 1
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
					"hint": "Per-cell chromatic divergence (0=monochrome)",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "grain_pix::ch_diverge",
					"parameter_enable": 1,
					"patching_rect": [
						450.0,
						80.0,
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
					"id": "obj-45",
					"maxclass": "attrui",
					"attr": "ch_diverge",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						450.0,
						410.0,
						150.0,
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
						450.0,
						130.0,
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
					"text": "Color",
					"textjustification": 1
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
					"hint": "Luma gate: -1=shadows only  0=uniform  +1=highlights only",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "grain_pix::luma_gate",
					"parameter_enable": 1,
					"patching_rect": [
						500.0,
						80.0,
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
					"id": "obj-48",
					"maxclass": "attrui",
					"attr": "luma_gate",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						500.0,
						440.0,
						143.0,
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
						500.0,
						130.0,
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
					"text": "L.gate",
					"textjustification": 1
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
					"hint": "Per-grain UV displacement amount",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "grain_pix::displace",
					"parameter_enable": 1,
					"patching_rect": [
						550.0,
						80.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						4.0,
						162.0,
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
					"id": "obj-51",
					"maxclass": "attrui",
					"attr": "displace",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						550.0,
						470.0,
						136.0,
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
						550.0,
						130.0,
						50.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						-7.5,
						144.0,
						50.0,
						18.0
					],
					"text": "Displ",
					"textjustification": 1
				}
			},
			{
				"box": {
					"id": "obj-53",
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
						205.0,
						5.0,
						18.0,
						12.0
					],
					"presentation_rect": [
						205.0,
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
					"id": "obj-54",
					"maxclass": "attrui",
					"attr": "bypass",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						400.0,
						60.0,
						131.0,
						22.0
					],
					"style": ""
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
						10
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
			}
		],
		"parameters": {
			"obj-20": [
				"size",
				"size",
				0
			],
			"obj-23": [
				"size_var",
				"size_var",
				0
			],
			"obj-26": [
				"shape",
				"shape",
				0
			],
			"obj-29": [
				"jitter",
				"jitter",
				0
			],
			"obj-32": [
				"fade",
				"fade",
				0
			],
			"obj-35": [
				"persistence",
				"persistence",
				0
			],
			"obj-38": [
				"amount",
				"amount",
				0
			],
			"obj-41": [
				"density",
				"density",
				0
			],
			"obj-44": [
				"ch_diverge",
				"ch_diverge",
				0
			],
			"obj-47": [
				"luma_gate",
				"luma_gate",
				0
			],
			"obj-50": [
				"displace",
				"displace",
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