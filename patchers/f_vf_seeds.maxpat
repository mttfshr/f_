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
					"comment": "mark color",
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
					"comment": "mark mask",
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
					"comment": "seed coord",
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
						700.0,
						22.0
					],
					"text": "route density jitter size stretch strength mag_weight field_priority field_gain phase size_mod stretch_mod"
				}
			},
			{
				"box": {
					"id": "obj-5",
					"maxclass": "newobj",
					"numinlets": 3,
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
									"text": "in 3"
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
										120.0,
										30.0,
										40.0,
										22.0
									],
									"text": "r draw"
								}
							},
							{
								"box": {
									"code": "// f_vf_seeds \u2014 placement and orientation engine\n// in1: shape tex  in2: vecfield  in3: mod tex\n//\n// Priority-generalized selection (2026-07-04): seed selection blends from\n// pure nearest-distance toward field-magnitude-driven priority via\n// `field_priority` (0=distance-only, matches pre-2026-07-04 behavior\n// exactly; 1=field-magnitude-only, a degenerate boundary \u2014 see spec.md's\n// Character Space table). `field_gain` is the live scale on the field\n// term; ships with range_tiers [0.2, 0.8, 1.5] in definition.py (per-field\n// empirically-tested windows: Flow/Repulse/Vortex respectively) as a pure\n// UI menu convenience, same mechanism as f_vf_advect's dt/injection \u2014 no\n// codebox-side range logic. Full history: .specify/f_vf_seeds/spec.md,\n// plan.md. Source: GPU Gems Ch. 20 (\"Texture Bombing\") \u2014 Voronoi mode and\n// texture-bombing mode are the same reduction loop, differing only in\n// what feeds `priority`.\n//\n// Vecfield is now sampled at EACH of the 9 candidates (before selection),\n// not once at the winner afterward \u2014 required to compute per-candidate\n// priority. The winning candidate's vx/vy is carried through the same\n// reduction chain as best_gx/best_gy, so no separate post-selection\n// vecfield sample is needed. Total cost: 9 samples (measured: negligible\n// at 1920x1080 60+fps and 3840x2160 58-60fps).\n\nParam density(0.5);\nParam jitter(0.5);\nParam size(0.2);\nParam stretch(0.0);\nParam phase(0.0);\nParam strength(1.0);\nParam mag_weight(0.0);\nParam size_mod(0.0);\nParam stretch_mod(0.0);\nParam src_vecfield(0.0);\nParam src_mod(0.0);\nParam src_shape(0.0);\nParam bypass(0.0);\nParam field_priority(0.0);\nParam field_gain(0.0);\n\n// \u2500\u2500 Grid density \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n\ndensity_scale = pow(2.0, density * 9.0 - 1.0);\naspect = dim.x / dim.y;\n\npx = norm.x * density_scale * aspect;\npy = norm.y * density_scale;\nicx = floor(px);\nicy = floor(py);\n\n// \u2500\u2500 3x3 neighbourhood candidate search \u2014 with per-candidate field sample \u2500\u2500\u2500\u2500\u2500\n\nncx = icx-1.0; ncy = icy-1.0;\njxA = fract(sin(ncx*127.1 + ncy*311.7)*43758.5453) - 0.5;\njyA = fract(sin(ncx*269.5 + ncy*183.3)*43758.5453) - 0.5;\nsxA = (ncx + 0.5 + jxA*jitter) / (density_scale * aspect);\nsyA = (ncy + 0.5 + jyA*jitter) / density_scale;\ndxA = norm.x - sxA; dyA = norm.y - syA;\ndA = dxA*dxA + dyA*dyA;\nvxA = (sample(in2, vec(sxA, syA)).x - 0.5) * 2.0;\nvyA = (sample(in2, vec(sxA, syA)).y - 0.5) * 2.0;\nfmA = sqrt(max(vxA*vxA + vyA*vyA, 0.0));\npriA = mix(dA, -fmA * field_gain, field_priority);\n\nncx = icx; ncy = icy-1.0;\njxB = fract(sin(ncx*127.1 + ncy*311.7)*43758.5453) - 0.5;\njyB = fract(sin(ncx*269.5 + ncy*183.3)*43758.5453) - 0.5;\nsxB = (ncx + 0.5 + jxB*jitter) / (density_scale * aspect);\nsyB = (ncy + 0.5 + jyB*jitter) / density_scale;\ndxB = norm.x - sxB; dyB = norm.y - syB;\ndB = dxB*dxB + dyB*dyB;\nvxB = (sample(in2, vec(sxB, syB)).x - 0.5) * 2.0;\nvyB = (sample(in2, vec(sxB, syB)).y - 0.5) * 2.0;\nfmB = sqrt(max(vxB*vxB + vyB*vyB, 0.0));\npriB = mix(dB, -fmB * field_gain, field_priority);\n\nncx = icx+1.0; ncy = icy-1.0;\njxC = fract(sin(ncx*127.1 + ncy*311.7)*43758.5453) - 0.5;\njyC = fract(sin(ncx*269.5 + ncy*183.3)*43758.5453) - 0.5;\nsxC = (ncx + 0.5 + jxC*jitter) / (density_scale * aspect);\nsyC = (ncy + 0.5 + jyC*jitter) / density_scale;\ndxC = norm.x - sxC; dyC = norm.y - syC;\ndC = dxC*dxC + dyC*dyC;\nvxC = (sample(in2, vec(sxC, syC)).x - 0.5) * 2.0;\nvyC = (sample(in2, vec(sxC, syC)).y - 0.5) * 2.0;\nfmC = sqrt(max(vxC*vxC + vyC*vyC, 0.0));\npriC = mix(dC, -fmC * field_gain, field_priority);\n\nncx = icx-1.0; ncy = icy;\njxD = fract(sin(ncx*127.1 + ncy*311.7)*43758.5453) - 0.5;\njyD = fract(sin(ncx*269.5 + ncy*183.3)*43758.5453) - 0.5;\nsxD = (ncx + 0.5 + jxD*jitter) / (density_scale * aspect);\nsyD = (ncy + 0.5 + jyD*jitter) / density_scale;\ndxD = norm.x - sxD; dyD = norm.y - syD;\ndD = dxD*dxD + dyD*dyD;\nvxD = (sample(in2, vec(sxD, syD)).x - 0.5) * 2.0;\nvyD = (sample(in2, vec(sxD, syD)).y - 0.5) * 2.0;\nfmD = sqrt(max(vxD*vxD + vyD*vyD, 0.0));\npriD = mix(dD, -fmD * field_gain, field_priority);\n\nncx = icx; ncy = icy;\njxE = fract(sin(ncx*127.1 + ncy*311.7)*43758.5453) - 0.5;\njyE = fract(sin(ncx*269.5 + ncy*183.3)*43758.5453) - 0.5;\nsxE = (ncx + 0.5 + jxE*jitter) / (density_scale * aspect);\nsyE = (ncy + 0.5 + jyE*jitter) / density_scale;\ndxE = norm.x - sxE; dyE = norm.y - syE;\ndE = dxE*dxE + dyE*dyE;\nvxE = (sample(in2, vec(sxE, syE)).x - 0.5) * 2.0;\nvyE = (sample(in2, vec(sxE, syE)).y - 0.5) * 2.0;\nfmE = sqrt(max(vxE*vxE + vyE*vyE, 0.0));\npriE = mix(dE, -fmE * field_gain, field_priority);\n\nncx = icx+1.0; ncy = icy;\njxF = fract(sin(ncx*127.1 + ncy*311.7)*43758.5453) - 0.5;\njyF = fract(sin(ncx*269.5 + ncy*183.3)*43758.5453) - 0.5;\nsxF = (ncx + 0.5 + jxF*jitter) / (density_scale * aspect);\nsyF = (ncy + 0.5 + jyF*jitter) / density_scale;\ndxF = norm.x - sxF; dyF = norm.y - syF;\ndF = dxF*dxF + dyF*dyF;\nvxF = (sample(in2, vec(sxF, syF)).x - 0.5) * 2.0;\nvyF = (sample(in2, vec(sxF, syF)).y - 0.5) * 2.0;\nfmF = sqrt(max(vxF*vxF + vyF*vyF, 0.0));\npriF = mix(dF, -fmF * field_gain, field_priority);\n\nncx = icx-1.0; ncy = icy+1.0;\njxG = fract(sin(ncx*127.1 + ncy*311.7)*43758.5453) - 0.5;\njyG = fract(sin(ncx*269.5 + ncy*183.3)*43758.5453) - 0.5;\nsxG = (ncx + 0.5 + jxG*jitter) / (density_scale * aspect);\nsyG = (ncy + 0.5 + jyG*jitter) / density_scale;\ndxG = norm.x - sxG; dyG = norm.y - syG;\ndG = dxG*dxG + dyG*dyG;\nvxG = (sample(in2, vec(sxG, syG)).x - 0.5) * 2.0;\nvyG = (sample(in2, vec(sxG, syG)).y - 0.5) * 2.0;\nfmG = sqrt(max(vxG*vxG + vyG*vyG, 0.0));\npriG = mix(dG, -fmG * field_gain, field_priority);\n\nncx = icx; ncy = icy+1.0;\njxH = fract(sin(ncx*127.1 + ncy*311.7)*43758.5453) - 0.5;\njyH = fract(sin(ncx*269.5 + ncy*183.3)*43758.5453) - 0.5;\nsxH = (ncx + 0.5 + jxH*jitter) / (density_scale * aspect);\nsyH = (ncy + 0.5 + jyH*jitter) / density_scale;\ndxH = norm.x - sxH; dyH = norm.y - syH;\ndH = dxH*dxH + dyH*dyH;\nvxH = (sample(in2, vec(sxH, syH)).x - 0.5) * 2.0;\nvyH = (sample(in2, vec(sxH, syH)).y - 0.5) * 2.0;\nfmH = sqrt(max(vxH*vxH + vyH*vyH, 0.0));\npriH = mix(dH, -fmH * field_gain, field_priority);\n\nncx = icx+1.0; ncy = icy+1.0;\njxI = fract(sin(ncx*127.1 + ncy*311.7)*43758.5453) - 0.5;\njyI = fract(sin(ncx*269.5 + ncy*183.3)*43758.5453) - 0.5;\nsxI = (ncx + 0.5 + jxI*jitter) / (density_scale * aspect);\nsyI = (ncy + 0.5 + jyI*jitter) / density_scale;\ndxI = norm.x - sxI; dyI = norm.y - syI;\ndI = dxI*dxI + dyI*dyI;\nvxI = (sample(in2, vec(sxI, syI)).x - 0.5) * 2.0;\nvyI = (sample(in2, vec(sxI, syI)).y - 0.5) * 2.0;\nfmI = sqrt(max(vxI*vxI + vyI*vyI, 0.0));\npriI = mix(dI, -fmI * field_gain, field_priority);\n\n// \u2500\u2500 Select winner by priority (lower wins) \u2014 carries vx/vy through too \u2500\u2500\u2500\u2500\u2500\u2500\u2500\n\nbest_pri=priA; best_gx=sxA; best_gy=syA; best_dx=dxA; best_dy=dyA; best_vx=vxA; best_vy=vyA;\nt=step(priB,best_pri); best_pri=mix(best_pri,priB,t); best_gx=mix(best_gx,sxB,t); best_gy=mix(best_gy,syB,t); best_dx=mix(best_dx,dxB,t); best_dy=mix(best_dy,dyB,t); best_vx=mix(best_vx,vxB,t); best_vy=mix(best_vy,vyB,t);\nt=step(priC,best_pri); best_pri=mix(best_pri,priC,t); best_gx=mix(best_gx,sxC,t); best_gy=mix(best_gy,syC,t); best_dx=mix(best_dx,dxC,t); best_dy=mix(best_dy,dyC,t); best_vx=mix(best_vx,vxC,t); best_vy=mix(best_vy,vyC,t);\nt=step(priD,best_pri); best_pri=mix(best_pri,priD,t); best_gx=mix(best_gx,sxD,t); best_gy=mix(best_gy,syD,t); best_dx=mix(best_dx,dxD,t); best_dy=mix(best_dy,dyD,t); best_vx=mix(best_vx,vxD,t); best_vy=mix(best_vy,vyD,t);\nt=step(priE,best_pri); best_pri=mix(best_pri,priE,t); best_gx=mix(best_gx,sxE,t); best_gy=mix(best_gy,syE,t); best_dx=mix(best_dx,dxE,t); best_dy=mix(best_dy,dyE,t); best_vx=mix(best_vx,vxE,t); best_vy=mix(best_vy,vyE,t);\nt=step(priF,best_pri); best_pri=mix(best_pri,priF,t); best_gx=mix(best_gx,sxF,t); best_gy=mix(best_gy,syF,t); best_dx=mix(best_dx,dxF,t); best_dy=mix(best_dy,dyF,t); best_vx=mix(best_vx,vxF,t); best_vy=mix(best_vy,vyF,t);\nt=step(priG,best_pri); best_pri=mix(best_pri,priG,t); best_gx=mix(best_gx,sxG,t); best_gy=mix(best_gy,syG,t); best_dx=mix(best_dx,dxG,t); best_dy=mix(best_dy,dyG,t); best_vx=mix(best_vx,vxG,t); best_vy=mix(best_vy,vyG,t);\nt=step(priH,best_pri); best_pri=mix(best_pri,priH,t); best_gx=mix(best_gx,sxH,t); best_gy=mix(best_gy,syH,t); best_dx=mix(best_dx,dxH,t); best_dy=mix(best_dy,dyH,t); best_vx=mix(best_vx,vxH,t); best_vy=mix(best_vy,vyH,t);\nt=step(priI,best_pri); best_pri=mix(best_pri,priI,t); best_gx=mix(best_gx,sxI,t); best_gy=mix(best_gy,syI,t); best_dx=mix(best_dx,dxI,t); best_dy=mix(best_dy,dyI,t); best_vx=mix(best_vx,vxI,t); best_vy=mix(best_vy,vyI,t);\n\n// \u2500\u2500 Orientation \u2014 from carried best_vx/best_vy, no extra sample needed \u2500\u2500\u2500\u2500\u2500\u2500\u2500\n\nfield_mag = sqrt(max(best_vx*best_vx + best_vy*best_vy, 0.0));\nmag = max(field_mag, 0.0001);\nfcs = best_vx / mag;\nfsn = best_vy / mag;\n\ncs = mix(1.0, fcs, strength);\nsn = mix(0.0, fsn, strength);\nmag2 = max(sqrt(cs*cs + sn*sn), 0.0001);\ncs = cs / mag2;\nsn = sn / mag2;\n\n// \u2500\u2500 Project pixel offset into seed-local frame \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n\nodx = best_dx * aspect;\nody = best_dy;\nalong  =  odx * cs + ody * sn;\nacross = -odx * sn + ody * cs;\n\n// \u2500\u2500 Mod tex modulation (sampled at seed UV) \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n\nmod_sample = sample(in3, vec(best_gx, best_gy)).x * src_mod;\nsize_eff = clamp(size + mod_sample * size_mod + field_mag * mag_weight, 0.001, 0.5);\nstretch_eff = stretch + mod_sample * stretch_mod;\n\nstretch_factor = 1.0 + stretch_eff;\nmarklen_eff = size_eff * stretch_factor;\nweight_eff = size_eff / max(stretch_factor, 0.0001);\n\n// \u2500\u2500 Construct seed-local UV \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n\nalong_shifted = along - phase * marklen_eff;\n\nlocal_u = along_shifted / marklen_eff * 0.5 + 0.5;\nlocal_v = across / weight_eff * 0.5 + 0.5;\n\n// \u2500\u2500 Gate \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n\ngate = step(abs(along_shifted), marklen_eff) * step(abs(across), weight_eff);\n\n// \u2500\u2500 Sample shape tex \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n\nshape_r = sample(in1, vec(local_u, local_v)).x;\nshape_g = sample(in1, vec(local_u, local_v)).y;\nshape_b = sample(in1, vec(local_u, local_v)).z;\nshape_luma = (shape_r + shape_g + shape_b) / 3.0;\n\nmark_r = shape_r * gate * src_shape;\nmark_g = shape_g * gate * src_shape;\nmark_b = shape_b * gate * src_shape;\nmark_luma = shape_luma * gate * src_shape;\n\n// \u2500\u2500 Outputs \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n\nout1 = mix(vec(mark_r, mark_g, mark_b, 1.0), vec(0.0, 0.0, 0.0, 1.0), bypass);\nout2 = mix(vec(mark_luma, mark_luma, mark_luma, 1.0), vec(0.0, 0.0, 0.0, 1.0), bypass);\nout3 = mix(vec(best_gx, best_gy, 0.0, 1.0), vec(0.0, 0.0, 0.0, 1.0), bypass);\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
									"id": "gen-obj-3",
									"maxclass": "codebox",
									"numinlets": 3,
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
									"id": "gen-obj-4",
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
									"id": "gen-obj-5",
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
									"id": "gen-obj-6",
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
										"gen-obj-3",
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
										"gen-obj-3",
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
										2
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
										"gen-obj-4",
										0
									],
									"source": [
										"gen-obj-3",
										0
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
										"gen-obj-3",
										1
									]
								}
							},
							{
								"patchline": {
									"destination": [
										"gen-obj-6",
										0
									],
									"source": [
										"gen-obj-3",
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
					"text": "jit.gl.pix vsynth @name vfseeds_pix @type float32",
					"varname": "vfseeds_pix"
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
					"varname": "vfseeds_autopattr"
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
						160.0
					],
					"presentation": 1,
					"presentation_rect": [
						0.0,
						0.0,
						190.0,
						160.0
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
					"text": "Seeds"
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
					"id": "obj-20a",
					"maxclass": "newobj",
					"numinlets": 0,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						400.0,
						30.0,
						50.0,
						22.0
					],
					"text": "r draw"
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
						90.0,
						80.0,
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
					"comment": "vecfield",
					"index": 1,
					"numinlets": 0,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						90.0,
						30.0,
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
						150.0,
						80.0,
						80.0,
						22.0
					],
					"text": "vs_inState"
				}
			},
			{
				"box": {
					"id": "obj-106",
					"maxclass": "inlet",
					"comment": "mod tex",
					"index": 2,
					"numinlets": 0,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						150.0,
						30.0,
						30.0,
						30.0
					]
				}
			},
			{
				"box": {
					"id": "obj-107",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						210.0,
						80.0,
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
						90.0,
						130.0,
						160.0,
						22.0
					],
					"text": "prepend param src_shape"
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
						150.0,
						130.0,
						160.0,
						22.0
					],
					"text": "prepend param src_vecfield"
				}
			},
			{
				"box": {
					"id": "obj-108",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						210.0,
						130.0,
						160.0,
						22.0
					],
					"text": "prepend param src_mod"
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
					"hint": "Seed spacing \u2014 log-mapped, higher = more seeds",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "vfseeds_pix::density",
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
						50.0,
						170.0,
						129.0,
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
					"text": "Density",
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
					"hint": "Seed position randomness (0=regular grid, 1=fully stochastic)",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "vfseeds_pix::jitter",
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
								0.5
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "jitter",
							"parameter_mmax": 1.0,
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
					"id": "obj-24",
					"maxclass": "attrui",
					"attr": "jitter",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						100.0,
						200.0,
						122.0,
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
					"text": "Jitter",
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
					"hint": "Mark size \u2014 overall scale",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "vfseeds_pix::size",
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
								0.2
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "size",
							"parameter_mmax": 0.5,
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
					"id": "obj-27",
					"maxclass": "attrui",
					"attr": "size",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						150.0,
						230.0,
						108.0,
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
					"text": "Size",
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
					"hint": "Aspect ratio \u2014 0=circular/square, increasing elongates along field direction",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "vfseeds_pix::stretch",
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
							"parameter_longname": "stretch",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "stretch",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "stretch"
				}
			},
			{
				"box": {
					"id": "obj-30",
					"maxclass": "attrui",
					"attr": "stretch",
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
					"text": "Stretch",
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
					"hint": "Vecfield influence on mark orientation (0=rightward, 1=full field)",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "vfseeds_pix::strength",
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
					"id": "obj-33",
					"maxclass": "attrui",
					"attr": "strength",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						250.0,
						290.0,
						136.0,
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
					"text": "Strength",
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
					"hint": "Field magnitude \u2192 mark weight modulation depth",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "vfseeds_pix::mag_weight",
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
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "mag_weight",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "mag_weight",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "mag_weight"
				}
			},
			{
				"box": {
					"id": "obj-36",
					"maxclass": "attrui",
					"attr": "mag_weight",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						300.0,
						320.0,
						150.0,
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
					"text": "Mag\u2192Wt",
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
					"hint": "Seed selection: 0=nearest-distance (Voronoi, original behavior), 1=field-magnitude-only (degenerate at exactly 1.0 \u2014 see docs)",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "vfseeds_pix::field_priority",
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
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "field_priority",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "field_priority",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "field_priority"
				}
			},
			{
				"box": {
					"id": "obj-39",
					"maxclass": "attrui",
					"attr": "field_priority",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						350.0,
						350.0,
						178.0,
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
					"text": "Field Pri",
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
					"hint": "Field-priority scale \u2014 live value used directly, no separate range param. Useful window varies by vecfield source (Flow ~0.2, Repulse ~0.8, Vortex ~1.5) \u2014 see range_tiers.",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "vfseeds_pix::field_gain",
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
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "field_gain",
							"parameter_mmax": 1.5,
							"parameter_mmin": -1.5,
							"parameter_modmode": 3,
							"parameter_shortname": "field_gain",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "field_gain"
				}
			},
			{
				"box": {
					"id": "obj-42",
					"maxclass": "attrui",
					"attr": "field_gain",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						400.0,
						380.0,
						150.0,
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
					"text": "Field Gain",
					"textjustification": 1
				}
			},
			{
				"box": {
					"id": "obj-370",
					"maxclass": "live.menu",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0,
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"",
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						1340.0,
						200.0,
						100.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						100.5,
						21.5,
						16.0,
						15.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_enum": [
								"0.2",
								"0.8",
								"1.5"
							],
							"parameter_longname": "range_field_gain",
							"parameter_shortname": "range_field_gain",
							"parameter_type": 2
						}
					}
				}
			},
			{
				"box": {
					"id": "obj-371",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"",
						"",
						""
					],
					"patching_rect": [
						1340.0,
						240.0,
						60.0,
						22.0
					],
					"text": "sel 0 1 2"
				}
			},
			{
				"box": {
					"id": "obj-372",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1340.0,
						280.0,
						134.0,
						22.0
					],
					"text": "_parameter_range 0. 0.2"
				}
			},
			{
				"box": {
					"id": "obj-373",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1490.0,
						310.0,
						134.0,
						22.0
					],
					"text": "_parameter_range 0. 0.8"
				}
			},
			{
				"box": {
					"id": "obj-374",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1640.0,
						340.0,
						134.0,
						22.0
					],
					"text": "_parameter_range 0. 1.5"
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
					"hint": "Scroll marks along field direction (connect LFO for motion)",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "vfseeds_pix::phase",
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
							"parameter_longname": "phase",
							"parameter_mmax": 1.0,
							"parameter_mmin": -1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "phase",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "phase"
				}
			},
			{
				"box": {
					"id": "obj-45",
					"maxclass": "attrui",
					"attr": "phase",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						450.0,
						410.0,
						115.0,
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
					"text": "Phase",
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
					"hint": "Mod tex \u2192 size modulation depth (bipolar)",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "vfseeds_pix::size_mod",
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
							"parameter_longname": "size_mod",
							"parameter_mmax": 1.0,
							"parameter_mmin": -1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "size_mod",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "size_mod"
				}
			},
			{
				"box": {
					"id": "obj-48",
					"maxclass": "attrui",
					"attr": "size_mod",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						500.0,
						440.0,
						136.0,
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
					"text": "Size Mod",
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
					"hint": "Mod tex \u2192 stretch modulation depth (bipolar)",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "vfseeds_pix::stretch_mod",
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
							"parameter_longname": "stretch_mod",
							"parameter_mmax": 1.0,
							"parameter_mmin": -1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "stretch_mod",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "stretch_mod"
				}
			},
			{
				"box": {
					"id": "obj-51",
					"maxclass": "attrui",
					"attr": "stretch_mod",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						550.0,
						470.0,
						157.0,
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
					"text": "Str Mod",
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
						"obj-5",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-106",
						0
					],
					"destination": [
						"obj-107",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-107",
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
						"obj-107",
						1
					],
					"destination": [
						"obj-108",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-108",
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
						"obj-370",
						0
					],
					"destination": [
						"obj-371",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-371",
						0
					],
					"destination": [
						"obj-372",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-372",
						0
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
						"obj-371",
						1
					],
					"destination": [
						"obj-373",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-373",
						0
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
						"obj-371",
						2
					],
					"destination": [
						"obj-374",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-374",
						0
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
				"density",
				"density",
				0
			],
			"obj-23": [
				"jitter",
				"jitter",
				0
			],
			"obj-26": [
				"size",
				"size",
				0
			],
			"obj-29": [
				"stretch",
				"stretch",
				0
			],
			"obj-32": [
				"strength",
				"strength",
				0
			],
			"obj-35": [
				"mag_weight",
				"mag_weight",
				0
			],
			"obj-38": [
				"field_priority",
				"field_priority",
				0
			],
			"obj-41": [
				"field_gain",
				"field_gain",
				0
			],
			"obj-44": [
				"phase",
				"phase",
				0
			],
			"obj-47": [
				"size_mod",
				"size_mod",
				0
			],
			"obj-50": [
				"stretch_mod",
				"stretch_mod",
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