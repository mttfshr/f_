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
			900.0,
			900.0
		],
		"openinpresentation": 1,
		"boxes": [
			{
				"box": {
					"id": "obj-1",
					"maxclass": "inlet",
					"comment": "shape tex / control",
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
					"id": "obj-3",
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
					"id": "obj-4",
					"maxclass": "outlet",
					"comment": "mark color",
					"index": 0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						30.0,
						780.0,
						30.0,
						30.0
					]
				}
			},
			{
				"box": {
					"id": "obj-5",
					"maxclass": "outlet",
					"comment": "mark mask",
					"index": 1,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						90.0,
						780.0,
						30.0,
						30.0
					]
				}
			},
			{
				"box": {
					"id": "obj-6",
					"maxclass": "outlet",
					"comment": "seed coord",
					"index": 2,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						150.0,
						780.0,
						30.0,
						30.0
					]
				}
			},
			{
				"box": {
					"id": "obj-10",
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
					"id": "obj-11",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 12,
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
						""
					],
					"patching_rect": [
						200.0,
						130.0,
						735.0,
						22.0
					],
					"text": "route density jitter size stretch strength mag_weight field_priority field_gain bomb phase size_mod stretch_mod"
				}
			},
			{
				"box": {
					"id": "obj-12",
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
					"id": "obj-13",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						350.0,
						60.0,
						160.0,
						22.0
					],
					"text": "prepend param src_shape"
				}
			},
			{
				"box": {
					"id": "obj-14",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						200.0,
						30.0,
						80.0,
						22.0
					],
					"text": "vs_inState"
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
						350.0,
						30.0,
						170.0,
						22.0
					],
					"text": "prepend param src_vecfield"
				}
			},
			{
				"box": {
					"id": "obj-16",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						200.0,
						0.0,
						80.0,
						22.0
					],
					"text": "vs_inState"
				}
			},
			{
				"box": {
					"id": "obj-17",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						350.0,
						0.0,
						150.0,
						22.0
					],
					"text": "prepend param src_mod"
				}
			},
			{
				"box": {
					"id": "obj-20",
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
							59.0,
							114.0,
							600.0,
							450.0
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
										50.0,
										14.0,
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
									"code": "// f_vf_seeds \u2014 Stage 1a/1b: Search Half\n// in1: vecfield\n//\n// Same codebox instanced TWICE \u2014 once per 9-candidate group. Salts are\n// baked as literal constants via {salt1}-{salt4} template placeholders\n// (not live Params) \u2014 they're fixed identity constants distinguishing the\n// two halves; a live dial here would break the decorrelation the split\n// depends on. active_blend/sentinel ARE live Params in both instances,\n// but only Stage 1b's active_blend is ever wired to anything (to `bomb`,\n// renamed at the outer module boundary) \u2014 Stage 1a's sits unused at its\n// default (1.0) permanently. This asymmetry is intentional: keeping both\n// instances textually identical (true DRY) outweighs the minor unused-\n// attribute cost on Stage 1a.\n//\n// Confirmed empirically (2026-07-04): active_blend/bomb behaves as an\n// on/off toggle, not a graded fader \u2014 real priority magnitude scales\n// with density/jitter/field_gain/field_priority, so no fixed `sentinel`\n// constant stays correctly scaled across settings. See spec.md's\n// Evolution 2 \"bomb\" param note and plan.md's toggle-behavior addendum.\n// No code fix applied \u2014 this is documented behavior, not a bug.\n//\n// Density-compensation (sqrt(2) cell-growth) was tried and REMOVED \u2014\n// it made `bomb` read as a zoom/density control instead of a clustering\n// control (cell pitch and jitter rescaled together, mechanically\n// identical to the density param itself). Accepted trade-off: point\n// count now genuinely rises with bomb (density/irregularity coupling,\n// already flagged in ideas/seed_distribution_beyond_grid.md).\n//\n// This is the same search+top-2 shape confirmed compiling clean in\n// isolation (T003) \u2014 Stage 1 as a single 18-candidate codebox hit Max's\n// GL2\u2192GL3 shader transformer's Lua DSL.Parser capture-group ceiling;\n// splitting into two 9-candidate halves + a small merge stage (1c)\n// resolved it. Full history: plan.md ADR 7/8 and its addenda.\n//\n// out1 = rank1_coord (best_gx, best_gy, best_dx, best_dy) \u2014 this half's winner\n// out2 = rank2_coord (second_gx, second_gy, second_dx, second_dy) \u2014 this half's runner-up\n// out3 = pri_pair (best_pri, second_pri, 0, 1) \u2014 needed by Stage 1c to merge two halves\n\nParam density(0.5);\nParam jitter(0.5);\nParam field_priority(0.0);\nParam field_gain(0.0);\nParam active_blend(1.0);\nParam sentinel(5.0);\n\ndensity_scale = pow(2.0, density * 9.0 - 1.0);\ndensity_scale_eff = density_scale;\naspect = dim.x / dim.y;\n\npx = norm.x * density_scale_eff * aspect;\npy = norm.y * density_scale_eff;\nicx = floor(px);\nicy = floor(py);\n\nncx = icx-1.0; ncy = icy-1.0;\njxA = fract(sin(ncx*127.1 + ncy*311.7)*43758.5453) - 0.5;\njyA = fract(sin(ncx*269.5 + ncy*183.3)*43758.5453) - 0.5;\nsxA = (ncx + 0.5 + jxA*jitter) / (density_scale_eff * aspect);\nsyA = (ncy + 0.5 + jyA*jitter) / density_scale_eff;\ndxA = norm.x - sxA; dyA = norm.y - syA;\ndA = dxA*dxA + dyA*dyA;\nvxA = (sample(in1, vec(sxA, syA)).x - 0.5) * 2.0;\nvyA = (sample(in1, vec(sxA, syA)).y - 0.5) * 2.0;\nfmA = sqrt(max(vxA*vxA + vyA*vyA, 0.0));\npriAr = mix(dA, -fmA * field_gain, field_priority);\npriA = mix(sentinel, priAr, active_blend);\n\nncx = icx; ncy = icy-1.0;\njxB = fract(sin(ncx*127.1 + ncy*311.7)*43758.5453) - 0.5;\njyB = fract(sin(ncx*269.5 + ncy*183.3)*43758.5453) - 0.5;\nsxB = (ncx + 0.5 + jxB*jitter) / (density_scale_eff * aspect);\nsyB = (ncy + 0.5 + jyB*jitter) / density_scale_eff;\ndxB = norm.x - sxB; dyB = norm.y - syB;\ndB = dxB*dxB + dyB*dyB;\nvxB = (sample(in1, vec(sxB, syB)).x - 0.5) * 2.0;\nvyB = (sample(in1, vec(sxB, syB)).y - 0.5) * 2.0;\nfmB = sqrt(max(vxB*vxB + vyB*vyB, 0.0));\npriBr = mix(dB, -fmB * field_gain, field_priority);\npriB = mix(sentinel, priBr, active_blend);\n\nncx = icx+1.0; ncy = icy-1.0;\njxC = fract(sin(ncx*127.1 + ncy*311.7)*43758.5453) - 0.5;\njyC = fract(sin(ncx*269.5 + ncy*183.3)*43758.5453) - 0.5;\nsxC = (ncx + 0.5 + jxC*jitter) / (density_scale_eff * aspect);\nsyC = (ncy + 0.5 + jyC*jitter) / density_scale_eff;\ndxC = norm.x - sxC; dyC = norm.y - syC;\ndC = dxC*dxC + dyC*dyC;\nvxC = (sample(in1, vec(sxC, syC)).x - 0.5) * 2.0;\nvyC = (sample(in1, vec(sxC, syC)).y - 0.5) * 2.0;\nfmC = sqrt(max(vxC*vxC + vyC*vyC, 0.0));\npriCr = mix(dC, -fmC * field_gain, field_priority);\npriC = mix(sentinel, priCr, active_blend);\n\nncx = icx-1.0; ncy = icy;\njxD = fract(sin(ncx*127.1 + ncy*311.7)*43758.5453) - 0.5;\njyD = fract(sin(ncx*269.5 + ncy*183.3)*43758.5453) - 0.5;\nsxD = (ncx + 0.5 + jxD*jitter) / (density_scale_eff * aspect);\nsyD = (ncy + 0.5 + jyD*jitter) / density_scale_eff;\ndxD = norm.x - sxD; dyD = norm.y - syD;\ndD = dxD*dxD + dyD*dyD;\nvxD = (sample(in1, vec(sxD, syD)).x - 0.5) * 2.0;\nvyD = (sample(in1, vec(sxD, syD)).y - 0.5) * 2.0;\nfmD = sqrt(max(vxD*vxD + vyD*vyD, 0.0));\npriDr = mix(dD, -fmD * field_gain, field_priority);\npriD = mix(sentinel, priDr, active_blend);\n\nncx = icx; ncy = icy;\njxE = fract(sin(ncx*127.1 + ncy*311.7)*43758.5453) - 0.5;\njyE = fract(sin(ncx*269.5 + ncy*183.3)*43758.5453) - 0.5;\nsxE = (ncx + 0.5 + jxE*jitter) / (density_scale_eff * aspect);\nsyE = (ncy + 0.5 + jyE*jitter) / density_scale_eff;\ndxE = norm.x - sxE; dyE = norm.y - syE;\ndE = dxE*dxE + dyE*dyE;\nvxE = (sample(in1, vec(sxE, syE)).x - 0.5) * 2.0;\nvyE = (sample(in1, vec(sxE, syE)).y - 0.5) * 2.0;\nfmE = sqrt(max(vxE*vxE + vyE*vyE, 0.0));\npriEr = mix(dE, -fmE * field_gain, field_priority);\npriE = mix(sentinel, priEr, active_blend);\n\nncx = icx+1.0; ncy = icy;\njxF = fract(sin(ncx*127.1 + ncy*311.7)*43758.5453) - 0.5;\njyF = fract(sin(ncx*269.5 + ncy*183.3)*43758.5453) - 0.5;\nsxF = (ncx + 0.5 + jxF*jitter) / (density_scale_eff * aspect);\nsyF = (ncy + 0.5 + jyF*jitter) / density_scale_eff;\ndxF = norm.x - sxF; dyF = norm.y - syF;\ndF = dxF*dxF + dyF*dyF;\nvxF = (sample(in1, vec(sxF, syF)).x - 0.5) * 2.0;\nvyF = (sample(in1, vec(sxF, syF)).y - 0.5) * 2.0;\nfmF = sqrt(max(vxF*vxF + vyF*vyF, 0.0));\npriFr = mix(dF, -fmF * field_gain, field_priority);\npriF = mix(sentinel, priFr, active_blend);\n\nncx = icx-1.0; ncy = icy+1.0;\njxG = fract(sin(ncx*127.1 + ncy*311.7)*43758.5453) - 0.5;\njyG = fract(sin(ncx*269.5 + ncy*183.3)*43758.5453) - 0.5;\nsxG = (ncx + 0.5 + jxG*jitter) / (density_scale_eff * aspect);\nsyG = (ncy + 0.5 + jyG*jitter) / density_scale_eff;\ndxG = norm.x - sxG; dyG = norm.y - syG;\ndG = dxG*dxG + dyG*dyG;\nvxG = (sample(in1, vec(sxG, syG)).x - 0.5) * 2.0;\nvyG = (sample(in1, vec(sxG, syG)).y - 0.5) * 2.0;\nfmG = sqrt(max(vxG*vxG + vyG*vyG, 0.0));\npriGr = mix(dG, -fmG * field_gain, field_priority);\npriG = mix(sentinel, priGr, active_blend);\n\nncx = icx; ncy = icy+1.0;\njxH = fract(sin(ncx*127.1 + ncy*311.7)*43758.5453) - 0.5;\njyH = fract(sin(ncx*269.5 + ncy*183.3)*43758.5453) - 0.5;\nsxH = (ncx + 0.5 + jxH*jitter) / (density_scale_eff * aspect);\nsyH = (ncy + 0.5 + jyH*jitter) / density_scale_eff;\ndxH = norm.x - sxH; dyH = norm.y - syH;\ndH = dxH*dxH + dyH*dyH;\nvxH = (sample(in1, vec(sxH, syH)).x - 0.5) * 2.0;\nvyH = (sample(in1, vec(sxH, syH)).y - 0.5) * 2.0;\nfmH = sqrt(max(vxH*vxH + vyH*vyH, 0.0));\npriHr = mix(dH, -fmH * field_gain, field_priority);\npriH = mix(sentinel, priHr, active_blend);\n\nncx = icx+1.0; ncy = icy+1.0;\njxI = fract(sin(ncx*127.1 + ncy*311.7)*43758.5453) - 0.5;\njyI = fract(sin(ncx*269.5 + ncy*183.3)*43758.5453) - 0.5;\nsxI = (ncx + 0.5 + jxI*jitter) / (density_scale_eff * aspect);\nsyI = (ncy + 0.5 + jyI*jitter) / density_scale_eff;\ndxI = norm.x - sxI; dyI = norm.y - syI;\ndI = dxI*dxI + dyI*dyI;\nvxI = (sample(in1, vec(sxI, syI)).x - 0.5) * 2.0;\nvyI = (sample(in1, vec(sxI, syI)).y - 0.5) * 2.0;\nfmI = sqrt(max(vxI*vxI + vyI*vyI, 0.0));\npriIr = mix(dI, -fmI * field_gain, field_priority);\npriI = mix(sentinel, priIr, active_blend);\n\nt0=step(priB,priA);\nbest_pri=mix(priA,priB,t0); best_gx=mix(sxA,sxB,t0); best_gy=mix(syA,syB,t0); best_dx=mix(dxA,dxB,t0); best_dy=mix(dyA,dyB,t0);\nsecond_pri=mix(priB,priA,t0); second_gx=mix(sxB,sxA,t0); second_gy=mix(syB,syA,t0); second_dx=mix(dxB,dxA,t0); second_dy=mix(dyB,dyA,t0);\n\nt=step(priC,best_pri);\ndemoted_pri=mix(priC,best_pri,t); demoted_gx=mix(sxC,best_gx,t); demoted_gy=mix(syC,best_gy,t); demoted_dx=mix(dxC,best_dx,t); demoted_dy=mix(dyC,best_dy,t);\nbest_pri=mix(best_pri,priC,t); best_gx=mix(best_gx,sxC,t); best_gy=mix(best_gy,syC,t); best_dx=mix(best_dx,dxC,t); best_dy=mix(best_dy,dyC,t);\nt2=step(demoted_pri,second_pri);\nsecond_pri=mix(second_pri,demoted_pri,t2); second_gx=mix(second_gx,demoted_gx,t2); second_gy=mix(second_gy,demoted_gy,t2); second_dx=mix(second_dx,demoted_dx,t2); second_dy=mix(second_dy,demoted_dy,t2);\n\nt=step(priD,best_pri);\ndemoted_pri=mix(priD,best_pri,t); demoted_gx=mix(sxD,best_gx,t); demoted_gy=mix(syD,best_gy,t); demoted_dx=mix(dxD,best_dx,t); demoted_dy=mix(dyD,best_dy,t);\nbest_pri=mix(best_pri,priD,t); best_gx=mix(best_gx,sxD,t); best_gy=mix(best_gy,syD,t); best_dx=mix(best_dx,dxD,t); best_dy=mix(best_dy,dyD,t);\nt2=step(demoted_pri,second_pri);\nsecond_pri=mix(second_pri,demoted_pri,t2); second_gx=mix(second_gx,demoted_gx,t2); second_gy=mix(second_gy,demoted_gy,t2); second_dx=mix(second_dx,demoted_dx,t2); second_dy=mix(second_dy,demoted_dy,t2);\n\nt=step(priE,best_pri);\ndemoted_pri=mix(priE,best_pri,t); demoted_gx=mix(sxE,best_gx,t); demoted_gy=mix(syE,best_gy,t); demoted_dx=mix(dxE,best_dx,t); demoted_dy=mix(dyE,best_dy,t);\nbest_pri=mix(best_pri,priE,t); best_gx=mix(best_gx,sxE,t); best_gy=mix(best_gy,syE,t); best_dx=mix(best_dx,dxE,t); best_dy=mix(best_dy,dyE,t);\nt2=step(demoted_pri,second_pri);\nsecond_pri=mix(second_pri,demoted_pri,t2); second_gx=mix(second_gx,demoted_gx,t2); second_gy=mix(second_gy,demoted_gy,t2); second_dx=mix(second_dx,demoted_dx,t2); second_dy=mix(second_dy,demoted_dy,t2);\n\nt=step(priF,best_pri);\ndemoted_pri=mix(priF,best_pri,t); demoted_gx=mix(sxF,best_gx,t); demoted_gy=mix(syF,best_gy,t); demoted_dx=mix(dxF,best_dx,t); demoted_dy=mix(dyF,best_dy,t);\nbest_pri=mix(best_pri,priF,t); best_gx=mix(best_gx,sxF,t); best_gy=mix(best_gy,syF,t); best_dx=mix(best_dx,dxF,t); best_dy=mix(best_dy,dyF,t);\nt2=step(demoted_pri,second_pri);\nsecond_pri=mix(second_pri,demoted_pri,t2); second_gx=mix(second_gx,demoted_gx,t2); second_gy=mix(second_gy,demoted_gy,t2); second_dx=mix(second_dx,demoted_dx,t2); second_dy=mix(second_dy,demoted_dy,t2);\n\nt=step(priG,best_pri);\ndemoted_pri=mix(priG,best_pri,t); demoted_gx=mix(sxG,best_gx,t); demoted_gy=mix(syG,best_gy,t); demoted_dx=mix(dxG,best_dx,t); demoted_dy=mix(dyG,best_dy,t);\nbest_pri=mix(best_pri,priG,t); best_gx=mix(best_gx,sxG,t); best_gy=mix(best_gy,syG,t); best_dx=mix(best_dx,dxG,t); best_dy=mix(best_dy,dyG,t);\nt2=step(demoted_pri,second_pri);\nsecond_pri=mix(second_pri,demoted_pri,t2); second_gx=mix(second_gx,demoted_gx,t2); second_gy=mix(second_gy,demoted_gy,t2); second_dx=mix(second_dx,demoted_dx,t2); second_dy=mix(second_dy,demoted_dy,t2);\n\nt=step(priH,best_pri);\ndemoted_pri=mix(priH,best_pri,t); demoted_gx=mix(sxH,best_gx,t); demoted_gy=mix(syH,best_gy,t); demoted_dx=mix(dxH,best_dx,t); demoted_dy=mix(dyH,best_dy,t);\nbest_pri=mix(best_pri,priH,t); best_gx=mix(best_gx,sxH,t); best_gy=mix(best_gy,syH,t); best_dx=mix(best_dx,dxH,t); best_dy=mix(best_dy,dyH,t);\nt2=step(demoted_pri,second_pri);\nsecond_pri=mix(second_pri,demoted_pri,t2); second_gx=mix(second_gx,demoted_gx,t2); second_gy=mix(second_gy,demoted_gy,t2); second_dx=mix(second_dx,demoted_dx,t2); second_dy=mix(second_dy,demoted_dy,t2);\n\nt=step(priI,best_pri);\ndemoted_pri=mix(priI,best_pri,t); demoted_gx=mix(sxI,best_gx,t); demoted_gy=mix(syI,best_gy,t); demoted_dx=mix(dxI,best_dx,t); demoted_dy=mix(dyI,best_dy,t);\nbest_pri=mix(best_pri,priI,t); best_gx=mix(best_gx,sxI,t); best_gy=mix(best_gy,syI,t); best_dx=mix(best_dx,dxI,t); best_dy=mix(best_dy,dyI,t);\nt2=step(demoted_pri,second_pri);\nsecond_pri=mix(second_pri,demoted_pri,t2); second_gx=mix(second_gx,demoted_gx,t2); second_gy=mix(second_gy,demoted_gy,t2); second_dx=mix(second_dx,demoted_dx,t2); second_dy=mix(second_dy,demoted_dy,t2);\n\nout1 = vec(best_gx, best_gy, best_dx, best_dy);\nout2 = vec(second_gx, second_gy, second_dx, second_dy);\nout3 = vec(best_pri, second_pri, 0.0, 1.0);\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
									"numinlets": 1,
									"numoutlets": 3,
									"outlettype": [
										"",
										"",
										""
									],
									"patching_rect": [
										29.0,
										56.0,
										487.0,
										293.0
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
										176.0,
										418.0,
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
										360.0,
										396.0,
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
										481.0,
										414.0,
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
							},
							{
								"patchline": {
									"source": [
										"gen-obj-2",
										1
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
										2
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
						300.0,
						140.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name vfseeds_search_a @type float32",
					"varname": "vfseeds_search_a"
				}
			},
			{
				"box": {
					"id": "obj-21",
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
							59.0,
							114.0,
							600.0,
							450.0
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
										50.0,
										14.0,
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
									"code": "// f_vf_seeds \u2014 Stage 1a/1b: Search Half\n// in1: vecfield\n//\n// Same codebox instanced TWICE \u2014 once per 9-candidate group. Salts are\n// baked as literal constants via {salt1}-{salt4} template placeholders\n// (not live Params) \u2014 they're fixed identity constants distinguishing the\n// two halves; a live dial here would break the decorrelation the split\n// depends on. active_blend/sentinel ARE live Params in both instances,\n// but only Stage 1b's active_blend is ever wired to anything (to `bomb`,\n// renamed at the outer module boundary) \u2014 Stage 1a's sits unused at its\n// default (1.0) permanently. This asymmetry is intentional: keeping both\n// instances textually identical (true DRY) outweighs the minor unused-\n// attribute cost on Stage 1a.\n//\n// Confirmed empirically (2026-07-04): active_blend/bomb behaves as an\n// on/off toggle, not a graded fader \u2014 real priority magnitude scales\n// with density/jitter/field_gain/field_priority, so no fixed `sentinel`\n// constant stays correctly scaled across settings. See spec.md's\n// Evolution 2 \"bomb\" param note and plan.md's toggle-behavior addendum.\n// No code fix applied \u2014 this is documented behavior, not a bug.\n//\n// Density-compensation (sqrt(2) cell-growth) was tried and REMOVED \u2014\n// it made `bomb` read as a zoom/density control instead of a clustering\n// control (cell pitch and jitter rescaled together, mechanically\n// identical to the density param itself). Accepted trade-off: point\n// count now genuinely rises with bomb (density/irregularity coupling,\n// already flagged in ideas/seed_distribution_beyond_grid.md).\n//\n// This is the same search+top-2 shape confirmed compiling clean in\n// isolation (T003) \u2014 Stage 1 as a single 18-candidate codebox hit Max's\n// GL2\u2192GL3 shader transformer's Lua DSL.Parser capture-group ceiling;\n// splitting into two 9-candidate halves + a small merge stage (1c)\n// resolved it. Full history: plan.md ADR 7/8 and its addenda.\n//\n// out1 = rank1_coord (best_gx, best_gy, best_dx, best_dy) \u2014 this half's winner\n// out2 = rank2_coord (second_gx, second_gy, second_dx, second_dy) \u2014 this half's runner-up\n// out3 = pri_pair (best_pri, second_pri, 0, 1) \u2014 needed by Stage 1c to merge two halves\n\nParam density(0.5);\nParam jitter(0.5);\nParam field_priority(0.0);\nParam field_gain(0.0);\nParam active_blend(1.0);\nParam sentinel(5.0);\n\ndensity_scale = pow(2.0, density * 9.0 - 1.0);\ndensity_scale_eff = density_scale;\naspect = dim.x / dim.y;\n\npx = norm.x * density_scale_eff * aspect;\npy = norm.y * density_scale_eff;\nicx = floor(px);\nicy = floor(py);\n\nncx = icx-1.0; ncy = icy-1.0;\njxA = fract(sin(ncx*419.2 + ncy*371.9)*43758.5453) - 0.5;\njyA = fract(sin(ncx*133.7 + ncy*197.3)*43758.5453) - 0.5;\nsxA = (ncx + 0.5 + jxA*jitter) / (density_scale_eff * aspect);\nsyA = (ncy + 0.5 + jyA*jitter) / density_scale_eff;\ndxA = norm.x - sxA; dyA = norm.y - syA;\ndA = dxA*dxA + dyA*dyA;\nvxA = (sample(in1, vec(sxA, syA)).x - 0.5) * 2.0;\nvyA = (sample(in1, vec(sxA, syA)).y - 0.5) * 2.0;\nfmA = sqrt(max(vxA*vxA + vyA*vyA, 0.0));\npriAr = mix(dA, -fmA * field_gain, field_priority);\npriA = mix(sentinel, priAr, active_blend);\n\nncx = icx; ncy = icy-1.0;\njxB = fract(sin(ncx*419.2 + ncy*371.9)*43758.5453) - 0.5;\njyB = fract(sin(ncx*133.7 + ncy*197.3)*43758.5453) - 0.5;\nsxB = (ncx + 0.5 + jxB*jitter) / (density_scale_eff * aspect);\nsyB = (ncy + 0.5 + jyB*jitter) / density_scale_eff;\ndxB = norm.x - sxB; dyB = norm.y - syB;\ndB = dxB*dxB + dyB*dyB;\nvxB = (sample(in1, vec(sxB, syB)).x - 0.5) * 2.0;\nvyB = (sample(in1, vec(sxB, syB)).y - 0.5) * 2.0;\nfmB = sqrt(max(vxB*vxB + vyB*vyB, 0.0));\npriBr = mix(dB, -fmB * field_gain, field_priority);\npriB = mix(sentinel, priBr, active_blend);\n\nncx = icx+1.0; ncy = icy-1.0;\njxC = fract(sin(ncx*419.2 + ncy*371.9)*43758.5453) - 0.5;\njyC = fract(sin(ncx*133.7 + ncy*197.3)*43758.5453) - 0.5;\nsxC = (ncx + 0.5 + jxC*jitter) / (density_scale_eff * aspect);\nsyC = (ncy + 0.5 + jyC*jitter) / density_scale_eff;\ndxC = norm.x - sxC; dyC = norm.y - syC;\ndC = dxC*dxC + dyC*dyC;\nvxC = (sample(in1, vec(sxC, syC)).x - 0.5) * 2.0;\nvyC = (sample(in1, vec(sxC, syC)).y - 0.5) * 2.0;\nfmC = sqrt(max(vxC*vxC + vyC*vyC, 0.0));\npriCr = mix(dC, -fmC * field_gain, field_priority);\npriC = mix(sentinel, priCr, active_blend);\n\nncx = icx-1.0; ncy = icy;\njxD = fract(sin(ncx*419.2 + ncy*371.9)*43758.5453) - 0.5;\njyD = fract(sin(ncx*133.7 + ncy*197.3)*43758.5453) - 0.5;\nsxD = (ncx + 0.5 + jxD*jitter) / (density_scale_eff * aspect);\nsyD = (ncy + 0.5 + jyD*jitter) / density_scale_eff;\ndxD = norm.x - sxD; dyD = norm.y - syD;\ndD = dxD*dxD + dyD*dyD;\nvxD = (sample(in1, vec(sxD, syD)).x - 0.5) * 2.0;\nvyD = (sample(in1, vec(sxD, syD)).y - 0.5) * 2.0;\nfmD = sqrt(max(vxD*vxD + vyD*vyD, 0.0));\npriDr = mix(dD, -fmD * field_gain, field_priority);\npriD = mix(sentinel, priDr, active_blend);\n\nncx = icx; ncy = icy;\njxE = fract(sin(ncx*419.2 + ncy*371.9)*43758.5453) - 0.5;\njyE = fract(sin(ncx*133.7 + ncy*197.3)*43758.5453) - 0.5;\nsxE = (ncx + 0.5 + jxE*jitter) / (density_scale_eff * aspect);\nsyE = (ncy + 0.5 + jyE*jitter) / density_scale_eff;\ndxE = norm.x - sxE; dyE = norm.y - syE;\ndE = dxE*dxE + dyE*dyE;\nvxE = (sample(in1, vec(sxE, syE)).x - 0.5) * 2.0;\nvyE = (sample(in1, vec(sxE, syE)).y - 0.5) * 2.0;\nfmE = sqrt(max(vxE*vxE + vyE*vyE, 0.0));\npriEr = mix(dE, -fmE * field_gain, field_priority);\npriE = mix(sentinel, priEr, active_blend);\n\nncx = icx+1.0; ncy = icy;\njxF = fract(sin(ncx*419.2 + ncy*371.9)*43758.5453) - 0.5;\njyF = fract(sin(ncx*133.7 + ncy*197.3)*43758.5453) - 0.5;\nsxF = (ncx + 0.5 + jxF*jitter) / (density_scale_eff * aspect);\nsyF = (ncy + 0.5 + jyF*jitter) / density_scale_eff;\ndxF = norm.x - sxF; dyF = norm.y - syF;\ndF = dxF*dxF + dyF*dyF;\nvxF = (sample(in1, vec(sxF, syF)).x - 0.5) * 2.0;\nvyF = (sample(in1, vec(sxF, syF)).y - 0.5) * 2.0;\nfmF = sqrt(max(vxF*vxF + vyF*vyF, 0.0));\npriFr = mix(dF, -fmF * field_gain, field_priority);\npriF = mix(sentinel, priFr, active_blend);\n\nncx = icx-1.0; ncy = icy+1.0;\njxG = fract(sin(ncx*419.2 + ncy*371.9)*43758.5453) - 0.5;\njyG = fract(sin(ncx*133.7 + ncy*197.3)*43758.5453) - 0.5;\nsxG = (ncx + 0.5 + jxG*jitter) / (density_scale_eff * aspect);\nsyG = (ncy + 0.5 + jyG*jitter) / density_scale_eff;\ndxG = norm.x - sxG; dyG = norm.y - syG;\ndG = dxG*dxG + dyG*dyG;\nvxG = (sample(in1, vec(sxG, syG)).x - 0.5) * 2.0;\nvyG = (sample(in1, vec(sxG, syG)).y - 0.5) * 2.0;\nfmG = sqrt(max(vxG*vxG + vyG*vyG, 0.0));\npriGr = mix(dG, -fmG * field_gain, field_priority);\npriG = mix(sentinel, priGr, active_blend);\n\nncx = icx; ncy = icy+1.0;\njxH = fract(sin(ncx*419.2 + ncy*371.9)*43758.5453) - 0.5;\njyH = fract(sin(ncx*133.7 + ncy*197.3)*43758.5453) - 0.5;\nsxH = (ncx + 0.5 + jxH*jitter) / (density_scale_eff * aspect);\nsyH = (ncy + 0.5 + jyH*jitter) / density_scale_eff;\ndxH = norm.x - sxH; dyH = norm.y - syH;\ndH = dxH*dxH + dyH*dyH;\nvxH = (sample(in1, vec(sxH, syH)).x - 0.5) * 2.0;\nvyH = (sample(in1, vec(sxH, syH)).y - 0.5) * 2.0;\nfmH = sqrt(max(vxH*vxH + vyH*vyH, 0.0));\npriHr = mix(dH, -fmH * field_gain, field_priority);\npriH = mix(sentinel, priHr, active_blend);\n\nncx = icx+1.0; ncy = icy+1.0;\njxI = fract(sin(ncx*419.2 + ncy*371.9)*43758.5453) - 0.5;\njyI = fract(sin(ncx*133.7 + ncy*197.3)*43758.5453) - 0.5;\nsxI = (ncx + 0.5 + jxI*jitter) / (density_scale_eff * aspect);\nsyI = (ncy + 0.5 + jyI*jitter) / density_scale_eff;\ndxI = norm.x - sxI; dyI = norm.y - syI;\ndI = dxI*dxI + dyI*dyI;\nvxI = (sample(in1, vec(sxI, syI)).x - 0.5) * 2.0;\nvyI = (sample(in1, vec(sxI, syI)).y - 0.5) * 2.0;\nfmI = sqrt(max(vxI*vxI + vyI*vyI, 0.0));\npriIr = mix(dI, -fmI * field_gain, field_priority);\npriI = mix(sentinel, priIr, active_blend);\n\nt0=step(priB,priA);\nbest_pri=mix(priA,priB,t0); best_gx=mix(sxA,sxB,t0); best_gy=mix(syA,syB,t0); best_dx=mix(dxA,dxB,t0); best_dy=mix(dyA,dyB,t0);\nsecond_pri=mix(priB,priA,t0); second_gx=mix(sxB,sxA,t0); second_gy=mix(syB,syA,t0); second_dx=mix(dxB,dxA,t0); second_dy=mix(dyB,dyA,t0);\n\nt=step(priC,best_pri);\ndemoted_pri=mix(priC,best_pri,t); demoted_gx=mix(sxC,best_gx,t); demoted_gy=mix(syC,best_gy,t); demoted_dx=mix(dxC,best_dx,t); demoted_dy=mix(dyC,best_dy,t);\nbest_pri=mix(best_pri,priC,t); best_gx=mix(best_gx,sxC,t); best_gy=mix(best_gy,syC,t); best_dx=mix(best_dx,dxC,t); best_dy=mix(best_dy,dyC,t);\nt2=step(demoted_pri,second_pri);\nsecond_pri=mix(second_pri,demoted_pri,t2); second_gx=mix(second_gx,demoted_gx,t2); second_gy=mix(second_gy,demoted_gy,t2); second_dx=mix(second_dx,demoted_dx,t2); second_dy=mix(second_dy,demoted_dy,t2);\n\nt=step(priD,best_pri);\ndemoted_pri=mix(priD,best_pri,t); demoted_gx=mix(sxD,best_gx,t); demoted_gy=mix(syD,best_gy,t); demoted_dx=mix(dxD,best_dx,t); demoted_dy=mix(dyD,best_dy,t);\nbest_pri=mix(best_pri,priD,t); best_gx=mix(best_gx,sxD,t); best_gy=mix(best_gy,syD,t); best_dx=mix(best_dx,dxD,t); best_dy=mix(best_dy,dyD,t);\nt2=step(demoted_pri,second_pri);\nsecond_pri=mix(second_pri,demoted_pri,t2); second_gx=mix(second_gx,demoted_gx,t2); second_gy=mix(second_gy,demoted_gy,t2); second_dx=mix(second_dx,demoted_dx,t2); second_dy=mix(second_dy,demoted_dy,t2);\n\nt=step(priE,best_pri);\ndemoted_pri=mix(priE,best_pri,t); demoted_gx=mix(sxE,best_gx,t); demoted_gy=mix(syE,best_gy,t); demoted_dx=mix(dxE,best_dx,t); demoted_dy=mix(dyE,best_dy,t);\nbest_pri=mix(best_pri,priE,t); best_gx=mix(best_gx,sxE,t); best_gy=mix(best_gy,syE,t); best_dx=mix(best_dx,dxE,t); best_dy=mix(best_dy,dyE,t);\nt2=step(demoted_pri,second_pri);\nsecond_pri=mix(second_pri,demoted_pri,t2); second_gx=mix(second_gx,demoted_gx,t2); second_gy=mix(second_gy,demoted_gy,t2); second_dx=mix(second_dx,demoted_dx,t2); second_dy=mix(second_dy,demoted_dy,t2);\n\nt=step(priF,best_pri);\ndemoted_pri=mix(priF,best_pri,t); demoted_gx=mix(sxF,best_gx,t); demoted_gy=mix(syF,best_gy,t); demoted_dx=mix(dxF,best_dx,t); demoted_dy=mix(dyF,best_dy,t);\nbest_pri=mix(best_pri,priF,t); best_gx=mix(best_gx,sxF,t); best_gy=mix(best_gy,syF,t); best_dx=mix(best_dx,dxF,t); best_dy=mix(best_dy,dyF,t);\nt2=step(demoted_pri,second_pri);\nsecond_pri=mix(second_pri,demoted_pri,t2); second_gx=mix(second_gx,demoted_gx,t2); second_gy=mix(second_gy,demoted_gy,t2); second_dx=mix(second_dx,demoted_dx,t2); second_dy=mix(second_dy,demoted_dy,t2);\n\nt=step(priG,best_pri);\ndemoted_pri=mix(priG,best_pri,t); demoted_gx=mix(sxG,best_gx,t); demoted_gy=mix(syG,best_gy,t); demoted_dx=mix(dxG,best_dx,t); demoted_dy=mix(dyG,best_dy,t);\nbest_pri=mix(best_pri,priG,t); best_gx=mix(best_gx,sxG,t); best_gy=mix(best_gy,syG,t); best_dx=mix(best_dx,dxG,t); best_dy=mix(best_dy,dyG,t);\nt2=step(demoted_pri,second_pri);\nsecond_pri=mix(second_pri,demoted_pri,t2); second_gx=mix(second_gx,demoted_gx,t2); second_gy=mix(second_gy,demoted_gy,t2); second_dx=mix(second_dx,demoted_dx,t2); second_dy=mix(second_dy,demoted_dy,t2);\n\nt=step(priH,best_pri);\ndemoted_pri=mix(priH,best_pri,t); demoted_gx=mix(sxH,best_gx,t); demoted_gy=mix(syH,best_gy,t); demoted_dx=mix(dxH,best_dx,t); demoted_dy=mix(dyH,best_dy,t);\nbest_pri=mix(best_pri,priH,t); best_gx=mix(best_gx,sxH,t); best_gy=mix(best_gy,syH,t); best_dx=mix(best_dx,dxH,t); best_dy=mix(best_dy,dyH,t);\nt2=step(demoted_pri,second_pri);\nsecond_pri=mix(second_pri,demoted_pri,t2); second_gx=mix(second_gx,demoted_gx,t2); second_gy=mix(second_gy,demoted_gy,t2); second_dx=mix(second_dx,demoted_dx,t2); second_dy=mix(second_dy,demoted_dy,t2);\n\nt=step(priI,best_pri);\ndemoted_pri=mix(priI,best_pri,t); demoted_gx=mix(sxI,best_gx,t); demoted_gy=mix(syI,best_gy,t); demoted_dx=mix(dxI,best_dx,t); demoted_dy=mix(dyI,best_dy,t);\nbest_pri=mix(best_pri,priI,t); best_gx=mix(best_gx,sxI,t); best_gy=mix(best_gy,syI,t); best_dx=mix(best_dx,dxI,t); best_dy=mix(best_dy,dyI,t);\nt2=step(demoted_pri,second_pri);\nsecond_pri=mix(second_pri,demoted_pri,t2); second_gx=mix(second_gx,demoted_gx,t2); second_gy=mix(second_gy,demoted_gy,t2); second_dx=mix(second_dx,demoted_dx,t2); second_dy=mix(second_dy,demoted_dy,t2);\n\nout1 = vec(best_gx, best_gy, best_dx, best_dy);\nout2 = vec(second_gx, second_gy, second_dx, second_dy);\nout3 = vec(best_pri, second_pri, 0.0, 1.0);\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
									"numinlets": 1,
									"numoutlets": 3,
									"outlettype": [
										"",
										"",
										""
									],
									"patching_rect": [
										29.0,
										56.0,
										487.0,
										293.0
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
										176.0,
										418.0,
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
										360.0,
										396.0,
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
										481.0,
										414.0,
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
							},
							{
								"patchline": {
									"source": [
										"gen-obj-2",
										1
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
										2
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
						400.0,
						300.0,
						140.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name vfseeds_search_b @type float32",
					"varname": "vfseeds_search_b"
				}
			},
			{
				"box": {
					"id": "obj-22",
					"maxclass": "newobj",
					"numinlets": 6,
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
							59.0,
							114.0,
							600.0,
							450.0
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
										50.0,
										14.0,
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
										305.0,
										14.0,
										28.0,
										22.0
									],
									"text": "in 2"
								}
							},
							{
								"box": {
									"id": "gen-obj-6",
									"maxclass": "newobj",
									"numinlets": 0,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										335.0,
										44.0,
										28.0,
										22.0
									],
									"text": "in 3"
								}
							},
							{
								"box": {
									"id": "gen-obj-7",
									"maxclass": "newobj",
									"numinlets": 0,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										371.0,
										91.0,
										28.0,
										22.0
									],
									"text": "in 4"
								}
							},
							{
								"box": {
									"id": "gen-obj-8",
									"maxclass": "newobj",
									"numinlets": 0,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										423.0,
										97.0,
										28.0,
										22.0
									],
									"text": "in 5"
								}
							},
							{
								"box": {
									"id": "gen-obj-9",
									"maxclass": "newobj",
									"numinlets": 0,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										480.0,
										97.0,
										28.0,
										22.0
									],
									"text": "in 6"
								}
							},
							{
								"box": {
									"id": "gen-obj-3",
									"maxclass": "codebox",
									"code": "// f_vf_seeds \u2014 Stage 1c: Merge\n// in1: rank1A_coord  in2: rank2A_coord  in3: priA_pair\n// in4: rank1B_coord  in5: rank2B_coord  in6: priB_pair\n//\n// Small top-2 insertion across the 4 candidates surviving Stage 1a/1b\n// (each half already reduced its own 9 down to 2). Confirmed compiling\n// and correctly wired via direct scratch testing (2026-07-04) \u2014 full\n// history in plan.md ADR 7/8.\n//\n// out3 = seed coord, matching the ORIGINAL single-codebox contract\n// exactly (gx, gy, 0.0, 1.0) \u2014 not the dx/dy-carrying internal format\n// out1/out2 use for Stage 2/3's consumption. This outlet bypasses Stage 4\n// entirely (wired directly to the outer module's outlet), so it needs\n// its own bypass gating here rather than relying on Stage 4's.\n\nParam bypass(0.0);\n\ngxA1=sample(in1,vec(norm.x,norm.y)).x; gyA1=sample(in1,vec(norm.x,norm.y)).y;\ndxA1=sample(in1,vec(norm.x,norm.y)).z; dyA1=sample(in1,vec(norm.x,norm.y)).w;\ngxA2=sample(in2,vec(norm.x,norm.y)).x; gyA2=sample(in2,vec(norm.x,norm.y)).y;\ndxA2=sample(in2,vec(norm.x,norm.y)).z; dyA2=sample(in2,vec(norm.x,norm.y)).w;\npriA1=sample(in3,vec(norm.x,norm.y)).x;\npriA2=sample(in3,vec(norm.x,norm.y)).y;\n\ngxB1=sample(in4,vec(norm.x,norm.y)).x; gyB1=sample(in4,vec(norm.x,norm.y)).y;\ndxB1=sample(in4,vec(norm.x,norm.y)).z; dyB1=sample(in4,vec(norm.x,norm.y)).w;\ngxB2=sample(in5,vec(norm.x,norm.y)).x; gyB2=sample(in5,vec(norm.x,norm.y)).y;\ndxB2=sample(in5,vec(norm.x,norm.y)).z; dyB2=sample(in5,vec(norm.x,norm.y)).w;\npriB1=sample(in6,vec(norm.x,norm.y)).x;\npriB2=sample(in6,vec(norm.x,norm.y)).y;\n\nt0=step(priA2,priA1);\nbest_pri=mix(priA1,priA2,t0); best_gx=mix(gxA1,gxA2,t0); best_gy=mix(gyA1,gyA2,t0); best_dx=mix(dxA1,dxA2,t0); best_dy=mix(dyA1,dyA2,t0);\nsecond_pri=mix(priA2,priA1,t0); second_gx=mix(gxA2,gxA1,t0); second_gy=mix(gyA2,gyA1,t0); second_dx=mix(dxA2,dxA1,t0); second_dy=mix(dyA2,dyA1,t0);\n\nt=step(priB1,best_pri);\ndemoted_pri=mix(priB1,best_pri,t); demoted_gx=mix(gxB1,best_gx,t); demoted_gy=mix(gyB1,best_gy,t); demoted_dx=mix(dxB1,best_dx,t); demoted_dy=mix(dyB1,best_dy,t);\nbest_pri=mix(best_pri,priB1,t); best_gx=mix(best_gx,gxB1,t); best_gy=mix(best_gy,gyB1,t); best_dx=mix(best_dx,dxB1,t); best_dy=mix(best_dy,dyB1,t);\nt2=step(demoted_pri,second_pri);\nsecond_pri=mix(second_pri,demoted_pri,t2); second_gx=mix(second_gx,demoted_gx,t2); second_gy=mix(second_gy,demoted_gy,t2); second_dx=mix(second_dx,demoted_dx,t2); second_dy=mix(second_dy,demoted_dy,t2);\n\nt=step(priB2,best_pri);\ndemoted_pri=mix(priB2,best_pri,t); demoted_gx=mix(gxB2,best_gx,t); demoted_gy=mix(gyB2,best_gy,t); demoted_dx=mix(dxB2,best_dx,t); demoted_dy=mix(dyB2,best_dy,t);\nbest_pri=mix(best_pri,priB2,t); best_gx=mix(best_gx,gxB2,t); best_gy=mix(best_gy,gyB2,t); best_dx=mix(best_dx,dxB2,t); best_dy=mix(best_dy,dyB2,t);\nt2=step(demoted_pri,second_pri);\nsecond_pri=mix(second_pri,demoted_pri,t2); second_gx=mix(second_gx,demoted_gx,t2); second_gy=mix(second_gy,demoted_gy,t2); second_dx=mix(second_dx,demoted_dx,t2); second_dy=mix(second_dy,demoted_dy,t2);\n\nout1 = vec(best_gx, best_gy, best_dx, best_dy);\nout2 = vec(second_gx, second_gy, second_dx, second_dy);\nout3 = mix(vec(best_gx, best_gy, 0.0, 1.0), vec(0.0, 0.0, 0.0, 1.0), bypass);\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
									"numinlets": 6,
									"numoutlets": 3,
									"outlettype": [
										"",
										"",
										""
									],
									"patching_rect": [
										176.0,
										149.0,
										340.0,
										220.0
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
										176.0,
										418.0,
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
										360.0,
										396.0,
										35.0,
										22.0
									],
									"text": "out 2"
								}
							},
							{
								"box": {
									"id": "gen-obj-10",
									"maxclass": "newobj",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										481.0,
										414.0,
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
									"source": [
										"gen-obj-1",
										0
									],
									"destination": [
										"gen-obj-3",
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
										1
									]
								}
							},
							{
								"patchline": {
									"source": [
										"gen-obj-6",
										0
									],
									"destination": [
										"gen-obj-3",
										2
									]
								}
							},
							{
								"patchline": {
									"source": [
										"gen-obj-7",
										0
									],
									"destination": [
										"gen-obj-3",
										3
									]
								}
							},
							{
								"patchline": {
									"source": [
										"gen-obj-8",
										0
									],
									"destination": [
										"gen-obj-3",
										4
									]
								}
							},
							{
								"patchline": {
									"source": [
										"gen-obj-9",
										0
									],
									"destination": [
										"gen-obj-3",
										5
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
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"gen-obj-3",
										1
									],
									"destination": [
										"gen-obj-5",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"gen-obj-3",
										2
									],
									"destination": [
										"gen-obj-10",
										0
									]
								}
							}
						]
					},
					"patching_rect": [
						300.0,
						360.0,
						140.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name vfseeds_merge @type float32",
					"varname": "vfseeds_merge"
				}
			},
			{
				"box": {
					"id": "obj-23",
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
							59.0,
							114.0,
							600.0,
							450.0
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
										50.0,
										14.0,
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
										173.0,
										8.0,
										28.0,
										22.0
									],
									"text": "in 2"
								}
							},
							{
								"box": {
									"id": "gen-obj-5",
									"maxclass": "newobj",
									"numinlets": 0,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										285.0,
										23.0,
										28.0,
										22.0
									],
									"text": "in 3"
								}
							},
							{
								"box": {
									"id": "gen-obj-6",
									"maxclass": "newobj",
									"numinlets": 0,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										443.0,
										14.0,
										28.0,
										22.0
									],
									"text": "in 4"
								}
							},
							{
								"box": {
									"id": "gen-obj-3",
									"maxclass": "codebox",
									"code": "// f_vf_seeds \u2014 Stage 2/3: Render\n// Rank-agnostic \u2014 same codebox instanced twice, once per rank_coord input.\n// in1: rank_coord (gx, gy, dx, dy from Stage 1c merge)\n// in2: shape tex\n// in3: vecfield\n// in4: mod tex\n//\n// Reproduces Evolution 1.5's exact per-winner downstream block (orientation\n// projection, mod-tex sample, gate, shape sample, luma alpha) but consumes\n// dx/dy from Stage 1c rather than recomputing them. No bypass here \u2014 per\n// plan.md ADR 8, bypass is applied only at Stage 4 (composite).\n\nParam strength(1.0);\nParam mag_weight(0.0);\nParam size(0.2);\nParam stretch(0.0);\nParam phase(0.0);\nParam size_mod(0.0);\nParam stretch_mod(0.0);\nParam src_shape(1.0);\nParam src_mod(0.0);\n\naspect = dim.x / dim.y;\n\n// \u2500\u2500 Consume Stage 1c's coord (pixel-for-pixel passthrough, same context) \u2500\u2500\u2500\u2500\n\ngx = sample(in1, vec(norm.x, norm.y)).x;\ngy = sample(in1, vec(norm.x, norm.y)).y;\ndx = sample(in1, vec(norm.x, norm.y)).z;\ndy = sample(in1, vec(norm.x, norm.y)).w;\n\n// \u2500\u2500 Vecfield sampled at this rank's seed position \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n\nvx = (sample(in3, vec(gx, gy)).x - 0.5) * 2.0;\nvy = (sample(in3, vec(gx, gy)).y - 0.5) * 2.0;\nfield_mag = sqrt(max(vx*vx + vy*vy, 0.0));\n\n// \u2500\u2500 Orientation \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n\nmag = max(field_mag, 0.0001);\nfcs = vx / mag;\nfsn = vy / mag;\ncs = mix(1.0, fcs, strength);\nsn = mix(0.0, fsn, strength);\nmag2 = max(sqrt(cs*cs + sn*sn), 0.0001);\ncs = cs / mag2;\nsn = sn / mag2;\n\n// \u2500\u2500 Project pixel offset into seed-local frame \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n\nodx = dx * aspect;\nody = dy;\nalong  =  odx * cs + ody * sn;\nacross = -odx * sn + ody * cs;\n\n// \u2500\u2500 Mod tex modulation \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n\nmod_sample = sample(in4, vec(gx, gy)).x * src_mod;\nsize_eff = clamp(size + mod_sample * size_mod + field_mag * mag_weight, 0.001, 0.5);\nstretch_eff = stretch + mod_sample * stretch_mod;\nstretch_factor = 1.0 + stretch_eff;\nmarklen_eff = size_eff * stretch_factor;\nweight_eff = size_eff / max(stretch_factor, 0.0001);\n\n// \u2500\u2500 Construct seed-local UV \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n\nalong_shifted = along - phase * marklen_eff;\nlocal_u = along_shifted / marklen_eff * 0.5 + 0.5;\nlocal_v = across / weight_eff * 0.5 + 0.5;\n\n// \u2500\u2500 Gate \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n\ngate = step(abs(along_shifted), marklen_eff) * step(abs(across), weight_eff);\n\n// \u2500\u2500 Sample shape tex \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n\nshape_r = sample(in2, vec(local_u, local_v)).x;\nshape_g = sample(in2, vec(local_u, local_v)).y;\nshape_b = sample(in2, vec(local_u, local_v)).z;\nshape_luma = (shape_r + shape_g + shape_b) / 3.0;\n\nmark_r = shape_r * gate * src_shape;\nmark_g = shape_g * gate * src_shape;\nmark_b = shape_b * gate * src_shape;\nmark_a = shape_luma * gate * src_shape;\n\n// \u2500\u2500 Output \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n\nout1 = vec(mark_r, mark_g, mark_b, mark_a);\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
									"numinlets": 4,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										29.0,
										56.0,
										539.0,
										685.0
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
										176.0,
										418.0,
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
										"gen-obj-3",
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
										1
									]
								}
							},
							{
								"patchline": {
									"source": [
										"gen-obj-5",
										0
									],
									"destination": [
										"gen-obj-3",
										2
									]
								}
							},
							{
								"patchline": {
									"source": [
										"gen-obj-6",
										0
									],
									"destination": [
										"gen-obj-3",
										3
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
										0
									]
								}
							}
						]
					},
					"patching_rect": [
						200.0,
						420.0,
						140.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name vfseeds_render_1",
					"varname": "vfseeds_render_1"
				}
			},
			{
				"box": {
					"id": "obj-24",
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
							59.0,
							114.0,
							600.0,
							450.0
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
										50.0,
										14.0,
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
										173.0,
										8.0,
										28.0,
										22.0
									],
									"text": "in 2"
								}
							},
							{
								"box": {
									"id": "gen-obj-5",
									"maxclass": "newobj",
									"numinlets": 0,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										285.0,
										23.0,
										28.0,
										22.0
									],
									"text": "in 3"
								}
							},
							{
								"box": {
									"id": "gen-obj-6",
									"maxclass": "newobj",
									"numinlets": 0,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										443.0,
										14.0,
										28.0,
										22.0
									],
									"text": "in 4"
								}
							},
							{
								"box": {
									"id": "gen-obj-3",
									"maxclass": "codebox",
									"code": "// f_vf_seeds \u2014 Stage 2/3: Render\n// Rank-agnostic \u2014 same codebox instanced twice, once per rank_coord input.\n// in1: rank_coord (gx, gy, dx, dy from Stage 1c merge)\n// in2: shape tex\n// in3: vecfield\n// in4: mod tex\n//\n// Reproduces Evolution 1.5's exact per-winner downstream block (orientation\n// projection, mod-tex sample, gate, shape sample, luma alpha) but consumes\n// dx/dy from Stage 1c rather than recomputing them. No bypass here \u2014 per\n// plan.md ADR 8, bypass is applied only at Stage 4 (composite).\n\nParam strength(1.0);\nParam mag_weight(0.0);\nParam size(0.2);\nParam stretch(0.0);\nParam phase(0.0);\nParam size_mod(0.0);\nParam stretch_mod(0.0);\nParam src_shape(1.0);\nParam src_mod(0.0);\n\naspect = dim.x / dim.y;\n\n// \u2500\u2500 Consume Stage 1c's coord (pixel-for-pixel passthrough, same context) \u2500\u2500\u2500\u2500\n\ngx = sample(in1, vec(norm.x, norm.y)).x;\ngy = sample(in1, vec(norm.x, norm.y)).y;\ndx = sample(in1, vec(norm.x, norm.y)).z;\ndy = sample(in1, vec(norm.x, norm.y)).w;\n\n// \u2500\u2500 Vecfield sampled at this rank's seed position \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n\nvx = (sample(in3, vec(gx, gy)).x - 0.5) * 2.0;\nvy = (sample(in3, vec(gx, gy)).y - 0.5) * 2.0;\nfield_mag = sqrt(max(vx*vx + vy*vy, 0.0));\n\n// \u2500\u2500 Orientation \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n\nmag = max(field_mag, 0.0001);\nfcs = vx / mag;\nfsn = vy / mag;\ncs = mix(1.0, fcs, strength);\nsn = mix(0.0, fsn, strength);\nmag2 = max(sqrt(cs*cs + sn*sn), 0.0001);\ncs = cs / mag2;\nsn = sn / mag2;\n\n// \u2500\u2500 Project pixel offset into seed-local frame \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n\nodx = dx * aspect;\nody = dy;\nalong  =  odx * cs + ody * sn;\nacross = -odx * sn + ody * cs;\n\n// \u2500\u2500 Mod tex modulation \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n\nmod_sample = sample(in4, vec(gx, gy)).x * src_mod;\nsize_eff = clamp(size + mod_sample * size_mod + field_mag * mag_weight, 0.001, 0.5);\nstretch_eff = stretch + mod_sample * stretch_mod;\nstretch_factor = 1.0 + stretch_eff;\nmarklen_eff = size_eff * stretch_factor;\nweight_eff = size_eff / max(stretch_factor, 0.0001);\n\n// \u2500\u2500 Construct seed-local UV \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n\nalong_shifted = along - phase * marklen_eff;\nlocal_u = along_shifted / marklen_eff * 0.5 + 0.5;\nlocal_v = across / weight_eff * 0.5 + 0.5;\n\n// \u2500\u2500 Gate \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n\ngate = step(abs(along_shifted), marklen_eff) * step(abs(across), weight_eff);\n\n// \u2500\u2500 Sample shape tex \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n\nshape_r = sample(in2, vec(local_u, local_v)).x;\nshape_g = sample(in2, vec(local_u, local_v)).y;\nshape_b = sample(in2, vec(local_u, local_v)).z;\nshape_luma = (shape_r + shape_g + shape_b) / 3.0;\n\nmark_r = shape_r * gate * src_shape;\nmark_g = shape_g * gate * src_shape;\nmark_b = shape_b * gate * src_shape;\nmark_a = shape_luma * gate * src_shape;\n\n// \u2500\u2500 Output \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n\nout1 = vec(mark_r, mark_g, mark_b, mark_a);\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
									"numinlets": 4,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										29.0,
										56.0,
										539.0,
										685.0
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
										176.0,
										418.0,
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
										"gen-obj-3",
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
										1
									]
								}
							},
							{
								"patchline": {
									"source": [
										"gen-obj-5",
										0
									],
									"destination": [
										"gen-obj-3",
										2
									]
								}
							},
							{
								"patchline": {
									"source": [
										"gen-obj-6",
										0
									],
									"destination": [
										"gen-obj-3",
										3
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
										0
									]
								}
							}
						]
					},
					"patching_rect": [
						400.0,
						420.0,
						140.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name vfseeds_render_2",
					"varname": "vfseeds_render_2"
				}
			},
			{
				"box": {
					"id": "obj-25",
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
							59.0,
							114.0,
							597.0,
							662.0
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
										50.0,
										14.0,
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
										305.0,
										14.0,
										28.0,
										22.0
									],
									"text": "in 2"
								}
							},
							{
								"box": {
									"id": "gen-obj-3",
									"maxclass": "codebox",
									"code": "// f_vf_seeds \u2014 Stage 4: Composite\n// in1: rank1 render (mark_r, mark_g, mark_b, mark_a)\n// in2: rank2 render (mark_r, mark_g, mark_b, mark_a)\n//\n// Rank-1-over-rank-2 alpha composite, using rank1's own alpha (luma-keyed,\n// per Evolution 1.5) as the blend factor. bypass lives here for out1 \u2014\n// Stage 2/3's output is discarded either way once composited, so no\n// bypass gating needed upstream for the mark-color path (plan.md ADR 8).\n//\n// out2 = mark mask (comp_a as greyscale, matching the ORIGINAL\n// single-codebox contract's separate mask outlet).\n\nParam bypass(0.0);\n\nr1 = sample(in1, vec(norm.x, norm.y)).x;\ng1 = sample(in1, vec(norm.x, norm.y)).y;\nb1 = sample(in1, vec(norm.x, norm.y)).z;\na1 = sample(in1, vec(norm.x, norm.y)).w;\n\nr2 = sample(in2, vec(norm.x, norm.y)).x;\ng2 = sample(in2, vec(norm.x, norm.y)).y;\nb2 = sample(in2, vec(norm.x, norm.y)).z;\na2 = sample(in2, vec(norm.x, norm.y)).w;\n\ncomp_r = mix(r2, r1, a1);\ncomp_g = mix(g2, g1, a1);\ncomp_b = mix(b2, b1, a1);\ncomp_a = a1 + a2 * (1.0 - a1);\n\nout1 = mix(vec(comp_r, comp_g, comp_b, comp_a), vec(0.0, 0.0, 0.0, 0.0), bypass);\nout2 = mix(vec(comp_a, comp_a, comp_a, 1.0), vec(0.0, 0.0, 0.0, 1.0), bypass);\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
									"numinlets": 2,
									"numoutlets": 2,
									"outlettype": [
										"",
										""
									],
									"patching_rect": [
										28.0,
										78.0,
										536.0,
										524.0
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
										11.0,
										630.0,
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
										200.0,
										630.0,
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
									"source": [
										"gen-obj-1",
										0
									],
									"destination": [
										"gen-obj-3",
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
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"gen-obj-3",
										1
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
						300.0,
						480.0,
						140.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name vfseeds_composite",
					"varname": "vfseeds_composite"
				}
			},
			{
				"box": {
					"id": "obj-200",
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
					"id": "obj-201",
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
					"id": "obj-202",
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
					"id": "obj-203",
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
					"id": "obj-204",
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
					"id": "obj-205",
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
					"id": "obj-206",
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
					"id": "obj-207",
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
					"id": "obj-208",
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
					"id": "obj-209",
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
					"id": "obj-210",
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
					"id": "obj-211",
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
					"id": "obj-212",
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
					"id": "obj-213",
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
					"id": "obj-214",
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
					"id": "obj-215",
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
					"id": "obj-216",
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
					"id": "obj-217",
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
					"id": "obj-218",
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
					"id": "obj-219",
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
					"id": "obj-220",
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
					"id": "obj-221",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Field-priority scale \u2014 useful window varies by vecfield source (Flow ~0.2, Repulse ~0.8, Vortex ~1.5).",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
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
					"id": "obj-222",
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
					"id": "obj-223",
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
					"id": "obj-470",
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
					"id": "obj-471",
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
					"id": "obj-472",
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
					"id": "obj-473",
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
					"id": "obj-474",
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
					"id": "obj-224",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Second-sample-per-cell toggle \u2014 behaves as on/off, not a graded fader (see spec.md Evolution 2). Its attrui is bound directly to active_blend on Stage 1b \u2014 the dial itself keeps showing \"Bomb\".",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
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
							"parameter_longname": "bomb",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "bomb",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "bomb"
				}
			},
			{
				"box": {
					"id": "obj-225",
					"maxclass": "attrui",
					"attr": "active_blend",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						450.0,
						410.0,
						164.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-226",
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
					"text": "Bomb",
					"textjustification": 1
				}
			},
			{
				"box": {
					"id": "obj-227",
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
					"id": "obj-228",
					"maxclass": "attrui",
					"attr": "phase",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						500.0,
						440.0,
						115.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-229",
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
					"text": "Phase",
					"textjustification": 1
				}
			},
			{
				"box": {
					"id": "obj-230",
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
					"id": "obj-231",
					"maxclass": "attrui",
					"attr": "size_mod",
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
					"id": "obj-232",
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
					"text": "Size Mod",
					"textjustification": 1
				}
			},
			{
				"box": {
					"id": "obj-233",
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
					"parameter_enable": 1,
					"patching_rect": [
						600.0,
						80.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						41.0,
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
					"id": "obj-234",
					"maxclass": "attrui",
					"attr": "stretch_mod",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						600.0,
						500.0,
						157.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-235",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						600.0,
						130.0,
						50.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						29.5,
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
					"id": "obj-110",
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
					"id": "obj-111",
					"maxclass": "attrui",
					"attr": "bypass",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						600.0,
						60.0,
						131.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-100",
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
						780.0,
						56.0,
						22.0
					],
					"text": "autopattr",
					"varname": "vfseeds_autopattr"
				}
			},
			{
				"box": {
					"id": "obj-101",
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
					"id": "obj-102",
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
					"id": "obj-103",
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
					"id": "obj-104",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						700.0,
						50.0,
						60.0,
						22.0
					],
					"text": "loadbang"
				}
			},
			{
				"box": {
					"id": "obj-105",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						700.0,
						80.0,
						180.0,
						22.0
					],
					"text": "getattr presentation_rect"
				}
			},
			{
				"box": {
					"id": "obj-106",
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
						700.0,
						110.0,
						80.0,
						22.0
					],
					"text": "thispatcher"
				}
			},
			{
				"box": {
					"id": "obj-107",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						700.0,
						140.0,
						60.0,
						22.0
					],
					"text": "zl slice 2"
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
						700.0,
						170.0,
						80.0,
						22.0
					],
					"text": "prepend tam"
				}
			},
			{
				"box": {
					"id": "obj-109",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						700.0,
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
						"obj-10",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-10",
						2
					],
					"destination": [
						"obj-11",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-10",
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
						1
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
						"obj-2",
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
						"obj-3",
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
						"obj-16",
						1
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
						"obj-14",
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
						"obj-14",
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
						"obj-14",
						0
					],
					"destination": [
						"obj-23",
						2
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-14",
						0
					],
					"destination": [
						"obj-24",
						2
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
						"obj-23",
						1
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
						"obj-24",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-16",
						0
					],
					"destination": [
						"obj-23",
						3
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-16",
						0
					],
					"destination": [
						"obj-24",
						3
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
						"obj-23",
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
						"obj-24",
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
						"obj-23",
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
						"obj-24",
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
						"obj-22",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-20",
						1
					],
					"destination": [
						"obj-22",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-20",
						2
					],
					"destination": [
						"obj-22",
						2
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
						"obj-22",
						3
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-21",
						1
					],
					"destination": [
						"obj-22",
						4
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-21",
						2
					],
					"destination": [
						"obj-22",
						5
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-22",
						0
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
						"obj-22",
						1
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
						"obj-22",
						2
					],
					"destination": [
						"obj-6",
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
						"obj-25",
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
						"obj-25",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-25",
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
						"obj-25",
						1
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
						"obj-200",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-200",
						0
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
						"obj-201",
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
						"obj-201",
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
						"obj-11",
						1
					],
					"destination": [
						"obj-203",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-203",
						0
					],
					"destination": [
						"obj-204",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-204",
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
						"obj-204",
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
						"obj-11",
						2
					],
					"destination": [
						"obj-206",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-206",
						0
					],
					"destination": [
						"obj-207",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-207",
						0
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
						"obj-207",
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
						"obj-11",
						3
					],
					"destination": [
						"obj-209",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-209",
						0
					],
					"destination": [
						"obj-210",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-210",
						0
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
						"obj-210",
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
						"obj-11",
						4
					],
					"destination": [
						"obj-212",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-212",
						0
					],
					"destination": [
						"obj-213",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-213",
						0
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
						"obj-213",
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
						"obj-11",
						5
					],
					"destination": [
						"obj-215",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-215",
						0
					],
					"destination": [
						"obj-216",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-216",
						0
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
						"obj-216",
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
						"obj-11",
						6
					],
					"destination": [
						"obj-218",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-218",
						0
					],
					"destination": [
						"obj-219",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-219",
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
						"obj-219",
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
						"obj-471",
						0
					],
					"destination": [
						"obj-472",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-472",
						0
					],
					"destination": [
						"obj-221",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-471",
						1
					],
					"destination": [
						"obj-473",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-473",
						0
					],
					"destination": [
						"obj-221",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-471",
						2
					],
					"destination": [
						"obj-474",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-474",
						0
					],
					"destination": [
						"obj-221",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-470",
						2
					],
					"destination": [
						"obj-471",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-11",
						7
					],
					"destination": [
						"obj-221",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-221",
						0
					],
					"destination": [
						"obj-222",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-222",
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
						"obj-222",
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
						"obj-11",
						8
					],
					"destination": [
						"obj-224",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-224",
						0
					],
					"destination": [
						"obj-225",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-225",
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
						"obj-11",
						9
					],
					"destination": [
						"obj-227",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-227",
						0
					],
					"destination": [
						"obj-228",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-228",
						0
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
						"obj-228",
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
						"obj-11",
						10
					],
					"destination": [
						"obj-230",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-230",
						0
					],
					"destination": [
						"obj-231",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-231",
						0
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
						"obj-231",
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
						"obj-11",
						11
					],
					"destination": [
						"obj-233",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-233",
						0
					],
					"destination": [
						"obj-234",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-234",
						0
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
						"obj-234",
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
						"obj-110",
						0
					],
					"destination": [
						"obj-111",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-111",
						0
					],
					"destination": [
						"obj-22",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-111",
						0
					],
					"destination": [
						"obj-25",
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
						"obj-106",
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
						"obj-109",
						0
					]
				}
			}
		],
		"parameters": {
			"obj-200": [
				"density",
				"density",
				0
			],
			"obj-203": [
				"jitter",
				"jitter",
				0
			],
			"obj-206": [
				"size",
				"size",
				0
			],
			"obj-209": [
				"stretch",
				"stretch",
				0
			],
			"obj-212": [
				"strength",
				"strength",
				0
			],
			"obj-215": [
				"mag_weight",
				"mag_weight",
				0
			],
			"obj-218": [
				"field_priority",
				"field_priority",
				0
			],
			"obj-221": [
				"field_gain",
				"field_gain",
				0
			],
			"obj-224": [
				"bomb",
				"bomb",
				0
			],
			"obj-227": [
				"phase",
				"phase",
				0
			],
			"obj-230": [
				"size_mod",
				"size_mod",
				0
			],
			"obj-233": [
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