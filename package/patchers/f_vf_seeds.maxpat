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
					"comment": "shape tex / control",
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
					"comment": "mark color",
					"index": 0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						30.0,
						602.0,
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
					"index": 0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						100.0,
						602.0,
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
					"index": 0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						170.0,
						602.0,
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
					"numoutlets": 13,
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
						""
					],
					"patching_rect": [
						56.5,
						204.0,
						943.0,
						22.0
					],
					"text": "route density jitter size stretch strength mag_weight field_priority field_gain bomb phase size_mod stretch_mod color_mode"
				}
			},
			{
				"box": {
					"id": "obj-61",
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
									"code": "// f_vf_seeds \u2014 Stage 1a/1b: Search Half\n// in1: vecfield\n//\n// Same codebox instanced TWICE \u2014 once per 9-candidate group. Salts are\n// baked as literal constants via {salt1}-{salt4} template placeholders\n// (not live Params) \u2014 they're fixed identity constants distinguishing the\n// two halves; a live dial here would break the decorrelation the split\n// depends on. active_blend/sentinel ARE live Params in both instances,\n// but only Stage 1b's active_blend is ever wired to anything (to `bomb`,\n// renamed at the outer module boundary) \u2014 Stage 1a's sits unused at its\n// default (1.0) permanently. This asymmetry is intentional: keeping both\n// instances textually identical (true DRY) outweighs the minor unused-\n// attribute cost on Stage 1a.\n//\n// Confirmed empirically (2026-07-04): active_blend/bomb behaves as an\n// on/off toggle, not a graded fader \u2014 real priority magnitude scales\n// with density/jitter/field_gain/field_priority, so no fixed `sentinel`\n// constant stays correctly scaled across settings. See spec.md's\n// Evolution 2 \"bomb\" param note and plan.md's toggle-behavior addendum.\n// No code fix applied \u2014 this is documented behavior, not a bug.\n//\n// Density-compensation (sqrt(2) cell-growth) was tried and REMOVED \u2014\n// it made `bomb` read as a zoom/density control instead of a clustering\n// control (cell pitch and jitter rescaled together, mechanically\n// identical to the density param itself). Accepted trade-off: point\n// count now genuinely rises with bomb (density/irregularity coupling,\n// already flagged in ideas/seed_distribution_beyond_grid.md).\n//\n// This is the same search+top-2 shape confirmed compiling clean in\n// isolation (T003) \u2014 Stage 1 as a single 18-candidate codebox hit Max's\n// GL2\u2192GL3 shader transformer's Lua DSL.Parser capture-group ceiling;\n// splitting into two 9-candidate halves + a small merge stage (1c)\n// resolved it. Full history: plan.md ADR 7/8 and its addenda.\n//\n// out1 = rank1_coord (best_gx, best_gy, best_dx, best_dy) \u2014 this half's winner\n// out2 = rank2_coord (second_gx, second_gy, second_dx, second_dy) \u2014 this half's runner-up\n// out3 = pri_pair (best_pri, second_pri, 0, 1) \u2014 needed by Stage 1c to merge two halves\n\nParam density(0.5);\nParam jitter(0.5);\nParam field_priority(0.0);\nParam field_gain(0.0);\nParam active_blend(1.0);\nParam sentinel(5.0);\n\ndensity_scale = pow(2.0, density * 9.0 - 1.0);\ndensity_scale_eff = density_scale;\naspect = dim.x / dim.y;\n\npx = norm.x * density_scale_eff * aspect;\npy = norm.y * density_scale_eff;\nicx = floor(px);\nicy = floor(py);\n\nncx = icx-1.0; ncy = icy-1.0;\njxA = fract(sin(ncx*127.1 + ncy*311.7)*43758.5453) - 0.5;\njyA = fract(sin(ncx*269.5 + ncy*183.3)*43758.5453) - 0.5;\nsxA = (ncx + 0.5 + jxA*jitter) / (density_scale_eff * aspect);\nsyA = (ncy + 0.5 + jyA*jitter) / density_scale_eff;\ndxA = norm.x - sxA; dyA = norm.y - syA;\ndA = dxA*dxA + dyA*dyA;\nvxA = (sample(in1, vec(sxA, syA)).x - 0.5) * 2.0;\nvyA = (sample(in1, vec(sxA, syA)).y - 0.5) * 2.0;\nfmA = sqrt(max(vxA*vxA + vyA*vyA, 0.0));\npriAr = mix(dA, -fmA * field_gain, field_priority);\npriA = mix(sentinel, priAr, active_blend);\n\nncx = icx; ncy = icy-1.0;\njxB = fract(sin(ncx*127.1 + ncy*311.7)*43758.5453) - 0.5;\njyB = fract(sin(ncx*269.5 + ncy*183.3)*43758.5453) - 0.5;\nsxB = (ncx + 0.5 + jxB*jitter) / (density_scale_eff * aspect);\nsyB = (ncy + 0.5 + jyB*jitter) / density_scale_eff;\ndxB = norm.x - sxB; dyB = norm.y - syB;\ndB = dxB*dxB + dyB*dyB;\nvxB = (sample(in1, vec(sxB, syB)).x - 0.5) * 2.0;\nvyB = (sample(in1, vec(sxB, syB)).y - 0.5) * 2.0;\nfmB = sqrt(max(vxB*vxB + vyB*vyB, 0.0));\npriBr = mix(dB, -fmB * field_gain, field_priority);\npriB = mix(sentinel, priBr, active_blend);\n\nncx = icx+1.0; ncy = icy-1.0;\njxC = fract(sin(ncx*127.1 + ncy*311.7)*43758.5453) - 0.5;\njyC = fract(sin(ncx*269.5 + ncy*183.3)*43758.5453) - 0.5;\nsxC = (ncx + 0.5 + jxC*jitter) / (density_scale_eff * aspect);\nsyC = (ncy + 0.5 + jyC*jitter) / density_scale_eff;\ndxC = norm.x - sxC; dyC = norm.y - syC;\ndC = dxC*dxC + dyC*dyC;\nvxC = (sample(in1, vec(sxC, syC)).x - 0.5) * 2.0;\nvyC = (sample(in1, vec(sxC, syC)).y - 0.5) * 2.0;\nfmC = sqrt(max(vxC*vxC + vyC*vyC, 0.0));\npriCr = mix(dC, -fmC * field_gain, field_priority);\npriC = mix(sentinel, priCr, active_blend);\n\nncx = icx-1.0; ncy = icy;\njxD = fract(sin(ncx*127.1 + ncy*311.7)*43758.5453) - 0.5;\njyD = fract(sin(ncx*269.5 + ncy*183.3)*43758.5453) - 0.5;\nsxD = (ncx + 0.5 + jxD*jitter) / (density_scale_eff * aspect);\nsyD = (ncy + 0.5 + jyD*jitter) / density_scale_eff;\ndxD = norm.x - sxD; dyD = norm.y - syD;\ndD = dxD*dxD + dyD*dyD;\nvxD = (sample(in1, vec(sxD, syD)).x - 0.5) * 2.0;\nvyD = (sample(in1, vec(sxD, syD)).y - 0.5) * 2.0;\nfmD = sqrt(max(vxD*vxD + vyD*vyD, 0.0));\npriDr = mix(dD, -fmD * field_gain, field_priority);\npriD = mix(sentinel, priDr, active_blend);\n\nncx = icx; ncy = icy;\njxE = fract(sin(ncx*127.1 + ncy*311.7)*43758.5453) - 0.5;\njyE = fract(sin(ncx*269.5 + ncy*183.3)*43758.5453) - 0.5;\nsxE = (ncx + 0.5 + jxE*jitter) / (density_scale_eff * aspect);\nsyE = (ncy + 0.5 + jyE*jitter) / density_scale_eff;\ndxE = norm.x - sxE; dyE = norm.y - syE;\ndE = dxE*dxE + dyE*dyE;\nvxE = (sample(in1, vec(sxE, syE)).x - 0.5) * 2.0;\nvyE = (sample(in1, vec(sxE, syE)).y - 0.5) * 2.0;\nfmE = sqrt(max(vxE*vxE + vyE*vyE, 0.0));\npriEr = mix(dE, -fmE * field_gain, field_priority);\npriE = mix(sentinel, priEr, active_blend);\n\nncx = icx+1.0; ncy = icy;\njxF = fract(sin(ncx*127.1 + ncy*311.7)*43758.5453) - 0.5;\njyF = fract(sin(ncx*269.5 + ncy*183.3)*43758.5453) - 0.5;\nsxF = (ncx + 0.5 + jxF*jitter) / (density_scale_eff * aspect);\nsyF = (ncy + 0.5 + jyF*jitter) / density_scale_eff;\ndxF = norm.x - sxF; dyF = norm.y - syF;\ndF = dxF*dxF + dyF*dyF;\nvxF = (sample(in1, vec(sxF, syF)).x - 0.5) * 2.0;\nvyF = (sample(in1, vec(sxF, syF)).y - 0.5) * 2.0;\nfmF = sqrt(max(vxF*vxF + vyF*vyF, 0.0));\npriFr = mix(dF, -fmF * field_gain, field_priority);\npriF = mix(sentinel, priFr, active_blend);\n\nncx = icx-1.0; ncy = icy+1.0;\njxG = fract(sin(ncx*127.1 + ncy*311.7)*43758.5453) - 0.5;\njyG = fract(sin(ncx*269.5 + ncy*183.3)*43758.5453) - 0.5;\nsxG = (ncx + 0.5 + jxG*jitter) / (density_scale_eff * aspect);\nsyG = (ncy + 0.5 + jyG*jitter) / density_scale_eff;\ndxG = norm.x - sxG; dyG = norm.y - syG;\ndG = dxG*dxG + dyG*dyG;\nvxG = (sample(in1, vec(sxG, syG)).x - 0.5) * 2.0;\nvyG = (sample(in1, vec(sxG, syG)).y - 0.5) * 2.0;\nfmG = sqrt(max(vxG*vxG + vyG*vyG, 0.0));\npriGr = mix(dG, -fmG * field_gain, field_priority);\npriG = mix(sentinel, priGr, active_blend);\n\nncx = icx; ncy = icy+1.0;\njxH = fract(sin(ncx*127.1 + ncy*311.7)*43758.5453) - 0.5;\njyH = fract(sin(ncx*269.5 + ncy*183.3)*43758.5453) - 0.5;\nsxH = (ncx + 0.5 + jxH*jitter) / (density_scale_eff * aspect);\nsyH = (ncy + 0.5 + jyH*jitter) / density_scale_eff;\ndxH = norm.x - sxH; dyH = norm.y - syH;\ndH = dxH*dxH + dyH*dyH;\nvxH = (sample(in1, vec(sxH, syH)).x - 0.5) * 2.0;\nvyH = (sample(in1, vec(sxH, syH)).y - 0.5) * 2.0;\nfmH = sqrt(max(vxH*vxH + vyH*vyH, 0.0));\npriHr = mix(dH, -fmH * field_gain, field_priority);\npriH = mix(sentinel, priHr, active_blend);\n\nncx = icx+1.0; ncy = icy+1.0;\njxI = fract(sin(ncx*127.1 + ncy*311.7)*43758.5453) - 0.5;\njyI = fract(sin(ncx*269.5 + ncy*183.3)*43758.5453) - 0.5;\nsxI = (ncx + 0.5 + jxI*jitter) / (density_scale_eff * aspect);\nsyI = (ncy + 0.5 + jyI*jitter) / density_scale_eff;\ndxI = norm.x - sxI; dyI = norm.y - syI;\ndI = dxI*dxI + dyI*dyI;\nvxI = (sample(in1, vec(sxI, syI)).x - 0.5) * 2.0;\nvyI = (sample(in1, vec(sxI, syI)).y - 0.5) * 2.0;\nfmI = sqrt(max(vxI*vxI + vyI*vyI, 0.0));\npriIr = mix(dI, -fmI * field_gain, field_priority);\npriI = mix(sentinel, priIr, active_blend);\n\nt0=step(priB,priA);\nbest_pri=mix(priA,priB,t0); best_gx=mix(sxA,sxB,t0); best_gy=mix(syA,syB,t0); best_dx=mix(dxA,dxB,t0); best_dy=mix(dyA,dyB,t0);\nsecond_pri=mix(priB,priA,t0); second_gx=mix(sxB,sxA,t0); second_gy=mix(syB,syA,t0); second_dx=mix(dxB,dxA,t0); second_dy=mix(dyB,dyA,t0);\n\nt=step(priC,best_pri);\ndemoted_pri=mix(priC,best_pri,t); demoted_gx=mix(sxC,best_gx,t); demoted_gy=mix(syC,best_gy,t); demoted_dx=mix(dxC,best_dx,t); demoted_dy=mix(dyC,best_dy,t);\nbest_pri=mix(best_pri,priC,t); best_gx=mix(best_gx,sxC,t); best_gy=mix(best_gy,syC,t); best_dx=mix(best_dx,dxC,t); best_dy=mix(best_dy,dyC,t);\nt2=step(demoted_pri,second_pri);\nsecond_pri=mix(second_pri,demoted_pri,t2); second_gx=mix(second_gx,demoted_gx,t2); second_gy=mix(second_gy,demoted_gy,t2); second_dx=mix(second_dx,demoted_dx,t2); second_dy=mix(second_dy,demoted_dy,t2);\n\nt=step(priD,best_pri);\ndemoted_pri=mix(priD,best_pri,t); demoted_gx=mix(sxD,best_gx,t); demoted_gy=mix(syD,best_gy,t); demoted_dx=mix(dxD,best_dx,t); demoted_dy=mix(dyD,best_dy,t);\nbest_pri=mix(best_pri,priD,t); best_gx=mix(best_gx,sxD,t); best_gy=mix(best_gy,syD,t); best_dx=mix(best_dx,dxD,t); best_dy=mix(best_dy,dyD,t);\nt2=step(demoted_pri,second_pri);\nsecond_pri=mix(second_pri,demoted_pri,t2); second_gx=mix(second_gx,demoted_gx,t2); second_gy=mix(second_gy,demoted_gy,t2); second_dx=mix(second_dx,demoted_dx,t2); second_dy=mix(second_dy,demoted_dy,t2);\n\nt=step(priE,best_pri);\ndemoted_pri=mix(priE,best_pri,t); demoted_gx=mix(sxE,best_gx,t); demoted_gy=mix(syE,best_gy,t); demoted_dx=mix(dxE,best_dx,t); demoted_dy=mix(dyE,best_dy,t);\nbest_pri=mix(best_pri,priE,t); best_gx=mix(best_gx,sxE,t); best_gy=mix(best_gy,syE,t); best_dx=mix(best_dx,dxE,t); best_dy=mix(best_dy,dyE,t);\nt2=step(demoted_pri,second_pri);\nsecond_pri=mix(second_pri,demoted_pri,t2); second_gx=mix(second_gx,demoted_gx,t2); second_gy=mix(second_gy,demoted_gy,t2); second_dx=mix(second_dx,demoted_dx,t2); second_dy=mix(second_dy,demoted_dy,t2);\n\nt=step(priF,best_pri);\ndemoted_pri=mix(priF,best_pri,t); demoted_gx=mix(sxF,best_gx,t); demoted_gy=mix(syF,best_gy,t); demoted_dx=mix(dxF,best_dx,t); demoted_dy=mix(dyF,best_dy,t);\nbest_pri=mix(best_pri,priF,t); best_gx=mix(best_gx,sxF,t); best_gy=mix(best_gy,syF,t); best_dx=mix(best_dx,dxF,t); best_dy=mix(best_dy,dyF,t);\nt2=step(demoted_pri,second_pri);\nsecond_pri=mix(second_pri,demoted_pri,t2); second_gx=mix(second_gx,demoted_gx,t2); second_gy=mix(second_gy,demoted_gy,t2); second_dx=mix(second_dx,demoted_dx,t2); second_dy=mix(second_dy,demoted_dy,t2);\n\nt=step(priG,best_pri);\ndemoted_pri=mix(priG,best_pri,t); demoted_gx=mix(sxG,best_gx,t); demoted_gy=mix(syG,best_gy,t); demoted_dx=mix(dxG,best_dx,t); demoted_dy=mix(dyG,best_dy,t);\nbest_pri=mix(best_pri,priG,t); best_gx=mix(best_gx,sxG,t); best_gy=mix(best_gy,syG,t); best_dx=mix(best_dx,dxG,t); best_dy=mix(best_dy,dyG,t);\nt2=step(demoted_pri,second_pri);\nsecond_pri=mix(second_pri,demoted_pri,t2); second_gx=mix(second_gx,demoted_gx,t2); second_gy=mix(second_gy,demoted_gy,t2); second_dx=mix(second_dx,demoted_dx,t2); second_dy=mix(second_dy,demoted_dy,t2);\n\nt=step(priH,best_pri);\ndemoted_pri=mix(priH,best_pri,t); demoted_gx=mix(sxH,best_gx,t); demoted_gy=mix(syH,best_gy,t); demoted_dx=mix(dxH,best_dx,t); demoted_dy=mix(dyH,best_dy,t);\nbest_pri=mix(best_pri,priH,t); best_gx=mix(best_gx,sxH,t); best_gy=mix(best_gy,syH,t); best_dx=mix(best_dx,dxH,t); best_dy=mix(best_dy,dyH,t);\nt2=step(demoted_pri,second_pri);\nsecond_pri=mix(second_pri,demoted_pri,t2); second_gx=mix(second_gx,demoted_gx,t2); second_gy=mix(second_gy,demoted_gy,t2); second_dx=mix(second_dx,demoted_dx,t2); second_dy=mix(second_dy,demoted_dy,t2);\n\nt=step(priI,best_pri);\ndemoted_pri=mix(priI,best_pri,t); demoted_gx=mix(sxI,best_gx,t); demoted_gy=mix(syI,best_gy,t); demoted_dx=mix(dxI,best_dx,t); demoted_dy=mix(dyI,best_dy,t);\nbest_pri=mix(best_pri,priI,t); best_gx=mix(best_gx,sxI,t); best_gy=mix(best_gy,syI,t); best_dx=mix(best_dx,dxI,t); best_dy=mix(best_dy,dyI,t);\nt2=step(demoted_pri,second_pri);\nsecond_pri=mix(second_pri,demoted_pri,t2); second_gx=mix(second_gx,demoted_gx,t2); second_gy=mix(second_gy,demoted_gy,t2); second_dx=mix(second_dx,demoted_dx,t2); second_dy=mix(second_dy,demoted_dy,t2);\n\nout1 = vec(best_gx, best_gy, best_dx, best_dy);\nout2 = vec(second_gx, second_gy, second_dx, second_dy);\nout3 = vec(best_pri, second_pri, 0.0, 1.0);\n",
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
						380.0,
						208.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name vfseeds_search_a @type float32",
					"varname": "vfseeds_search_a"
				}
			},
			{
				"box": {
					"id": "obj-62",
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
									"code": "// f_vf_seeds \u2014 Stage 1a/1b: Search Half\n// in1: vecfield\n//\n// Same codebox instanced TWICE \u2014 once per 9-candidate group. Salts are\n// baked as literal constants via {salt1}-{salt4} template placeholders\n// (not live Params) \u2014 they're fixed identity constants distinguishing the\n// two halves; a live dial here would break the decorrelation the split\n// depends on. active_blend/sentinel ARE live Params in both instances,\n// but only Stage 1b's active_blend is ever wired to anything (to `bomb`,\n// renamed at the outer module boundary) \u2014 Stage 1a's sits unused at its\n// default (1.0) permanently. This asymmetry is intentional: keeping both\n// instances textually identical (true DRY) outweighs the minor unused-\n// attribute cost on Stage 1a.\n//\n// Confirmed empirically (2026-07-04): active_blend/bomb behaves as an\n// on/off toggle, not a graded fader \u2014 real priority magnitude scales\n// with density/jitter/field_gain/field_priority, so no fixed `sentinel`\n// constant stays correctly scaled across settings. See spec.md's\n// Evolution 2 \"bomb\" param note and plan.md's toggle-behavior addendum.\n// No code fix applied \u2014 this is documented behavior, not a bug.\n//\n// Density-compensation (sqrt(2) cell-growth) was tried and REMOVED \u2014\n// it made `bomb` read as a zoom/density control instead of a clustering\n// control (cell pitch and jitter rescaled together, mechanically\n// identical to the density param itself). Accepted trade-off: point\n// count now genuinely rises with bomb (density/irregularity coupling,\n// already flagged in ideas/seed_distribution_beyond_grid.md).\n//\n// This is the same search+top-2 shape confirmed compiling clean in\n// isolation (T003) \u2014 Stage 1 as a single 18-candidate codebox hit Max's\n// GL2\u2192GL3 shader transformer's Lua DSL.Parser capture-group ceiling;\n// splitting into two 9-candidate halves + a small merge stage (1c)\n// resolved it. Full history: plan.md ADR 7/8 and its addenda.\n//\n// out1 = rank1_coord (best_gx, best_gy, best_dx, best_dy) \u2014 this half's winner\n// out2 = rank2_coord (second_gx, second_gy, second_dx, second_dy) \u2014 this half's runner-up\n// out3 = pri_pair (best_pri, second_pri, 0, 1) \u2014 needed by Stage 1c to merge two halves\n\nParam density(0.5);\nParam jitter(0.5);\nParam field_priority(0.0);\nParam field_gain(0.0);\nParam active_blend(1.0);\nParam sentinel(5.0);\n\ndensity_scale = pow(2.0, density * 9.0 - 1.0);\ndensity_scale_eff = density_scale;\naspect = dim.x / dim.y;\n\npx = norm.x * density_scale_eff * aspect;\npy = norm.y * density_scale_eff;\nicx = floor(px);\nicy = floor(py);\n\nncx = icx-1.0; ncy = icy-1.0;\njxA = fract(sin(ncx*419.2 + ncy*371.9)*43758.5453) - 0.5;\njyA = fract(sin(ncx*133.7 + ncy*197.3)*43758.5453) - 0.5;\nsxA = (ncx + 0.5 + jxA*jitter) / (density_scale_eff * aspect);\nsyA = (ncy + 0.5 + jyA*jitter) / density_scale_eff;\ndxA = norm.x - sxA; dyA = norm.y - syA;\ndA = dxA*dxA + dyA*dyA;\nvxA = (sample(in1, vec(sxA, syA)).x - 0.5) * 2.0;\nvyA = (sample(in1, vec(sxA, syA)).y - 0.5) * 2.0;\nfmA = sqrt(max(vxA*vxA + vyA*vyA, 0.0));\npriAr = mix(dA, -fmA * field_gain, field_priority);\npriA = mix(sentinel, priAr, active_blend);\n\nncx = icx; ncy = icy-1.0;\njxB = fract(sin(ncx*419.2 + ncy*371.9)*43758.5453) - 0.5;\njyB = fract(sin(ncx*133.7 + ncy*197.3)*43758.5453) - 0.5;\nsxB = (ncx + 0.5 + jxB*jitter) / (density_scale_eff * aspect);\nsyB = (ncy + 0.5 + jyB*jitter) / density_scale_eff;\ndxB = norm.x - sxB; dyB = norm.y - syB;\ndB = dxB*dxB + dyB*dyB;\nvxB = (sample(in1, vec(sxB, syB)).x - 0.5) * 2.0;\nvyB = (sample(in1, vec(sxB, syB)).y - 0.5) * 2.0;\nfmB = sqrt(max(vxB*vxB + vyB*vyB, 0.0));\npriBr = mix(dB, -fmB * field_gain, field_priority);\npriB = mix(sentinel, priBr, active_blend);\n\nncx = icx+1.0; ncy = icy-1.0;\njxC = fract(sin(ncx*419.2 + ncy*371.9)*43758.5453) - 0.5;\njyC = fract(sin(ncx*133.7 + ncy*197.3)*43758.5453) - 0.5;\nsxC = (ncx + 0.5 + jxC*jitter) / (density_scale_eff * aspect);\nsyC = (ncy + 0.5 + jyC*jitter) / density_scale_eff;\ndxC = norm.x - sxC; dyC = norm.y - syC;\ndC = dxC*dxC + dyC*dyC;\nvxC = (sample(in1, vec(sxC, syC)).x - 0.5) * 2.0;\nvyC = (sample(in1, vec(sxC, syC)).y - 0.5) * 2.0;\nfmC = sqrt(max(vxC*vxC + vyC*vyC, 0.0));\npriCr = mix(dC, -fmC * field_gain, field_priority);\npriC = mix(sentinel, priCr, active_blend);\n\nncx = icx-1.0; ncy = icy;\njxD = fract(sin(ncx*419.2 + ncy*371.9)*43758.5453) - 0.5;\njyD = fract(sin(ncx*133.7 + ncy*197.3)*43758.5453) - 0.5;\nsxD = (ncx + 0.5 + jxD*jitter) / (density_scale_eff * aspect);\nsyD = (ncy + 0.5 + jyD*jitter) / density_scale_eff;\ndxD = norm.x - sxD; dyD = norm.y - syD;\ndD = dxD*dxD + dyD*dyD;\nvxD = (sample(in1, vec(sxD, syD)).x - 0.5) * 2.0;\nvyD = (sample(in1, vec(sxD, syD)).y - 0.5) * 2.0;\nfmD = sqrt(max(vxD*vxD + vyD*vyD, 0.0));\npriDr = mix(dD, -fmD * field_gain, field_priority);\npriD = mix(sentinel, priDr, active_blend);\n\nncx = icx; ncy = icy;\njxE = fract(sin(ncx*419.2 + ncy*371.9)*43758.5453) - 0.5;\njyE = fract(sin(ncx*133.7 + ncy*197.3)*43758.5453) - 0.5;\nsxE = (ncx + 0.5 + jxE*jitter) / (density_scale_eff * aspect);\nsyE = (ncy + 0.5 + jyE*jitter) / density_scale_eff;\ndxE = norm.x - sxE; dyE = norm.y - syE;\ndE = dxE*dxE + dyE*dyE;\nvxE = (sample(in1, vec(sxE, syE)).x - 0.5) * 2.0;\nvyE = (sample(in1, vec(sxE, syE)).y - 0.5) * 2.0;\nfmE = sqrt(max(vxE*vxE + vyE*vyE, 0.0));\npriEr = mix(dE, -fmE * field_gain, field_priority);\npriE = mix(sentinel, priEr, active_blend);\n\nncx = icx+1.0; ncy = icy;\njxF = fract(sin(ncx*419.2 + ncy*371.9)*43758.5453) - 0.5;\njyF = fract(sin(ncx*133.7 + ncy*197.3)*43758.5453) - 0.5;\nsxF = (ncx + 0.5 + jxF*jitter) / (density_scale_eff * aspect);\nsyF = (ncy + 0.5 + jyF*jitter) / density_scale_eff;\ndxF = norm.x - sxF; dyF = norm.y - syF;\ndF = dxF*dxF + dyF*dyF;\nvxF = (sample(in1, vec(sxF, syF)).x - 0.5) * 2.0;\nvyF = (sample(in1, vec(sxF, syF)).y - 0.5) * 2.0;\nfmF = sqrt(max(vxF*vxF + vyF*vyF, 0.0));\npriFr = mix(dF, -fmF * field_gain, field_priority);\npriF = mix(sentinel, priFr, active_blend);\n\nncx = icx-1.0; ncy = icy+1.0;\njxG = fract(sin(ncx*419.2 + ncy*371.9)*43758.5453) - 0.5;\njyG = fract(sin(ncx*133.7 + ncy*197.3)*43758.5453) - 0.5;\nsxG = (ncx + 0.5 + jxG*jitter) / (density_scale_eff * aspect);\nsyG = (ncy + 0.5 + jyG*jitter) / density_scale_eff;\ndxG = norm.x - sxG; dyG = norm.y - syG;\ndG = dxG*dxG + dyG*dyG;\nvxG = (sample(in1, vec(sxG, syG)).x - 0.5) * 2.0;\nvyG = (sample(in1, vec(sxG, syG)).y - 0.5) * 2.0;\nfmG = sqrt(max(vxG*vxG + vyG*vyG, 0.0));\npriGr = mix(dG, -fmG * field_gain, field_priority);\npriG = mix(sentinel, priGr, active_blend);\n\nncx = icx; ncy = icy+1.0;\njxH = fract(sin(ncx*419.2 + ncy*371.9)*43758.5453) - 0.5;\njyH = fract(sin(ncx*133.7 + ncy*197.3)*43758.5453) - 0.5;\nsxH = (ncx + 0.5 + jxH*jitter) / (density_scale_eff * aspect);\nsyH = (ncy + 0.5 + jyH*jitter) / density_scale_eff;\ndxH = norm.x - sxH; dyH = norm.y - syH;\ndH = dxH*dxH + dyH*dyH;\nvxH = (sample(in1, vec(sxH, syH)).x - 0.5) * 2.0;\nvyH = (sample(in1, vec(sxH, syH)).y - 0.5) * 2.0;\nfmH = sqrt(max(vxH*vxH + vyH*vyH, 0.0));\npriHr = mix(dH, -fmH * field_gain, field_priority);\npriH = mix(sentinel, priHr, active_blend);\n\nncx = icx+1.0; ncy = icy+1.0;\njxI = fract(sin(ncx*419.2 + ncy*371.9)*43758.5453) - 0.5;\njyI = fract(sin(ncx*133.7 + ncy*197.3)*43758.5453) - 0.5;\nsxI = (ncx + 0.5 + jxI*jitter) / (density_scale_eff * aspect);\nsyI = (ncy + 0.5 + jyI*jitter) / density_scale_eff;\ndxI = norm.x - sxI; dyI = norm.y - syI;\ndI = dxI*dxI + dyI*dyI;\nvxI = (sample(in1, vec(sxI, syI)).x - 0.5) * 2.0;\nvyI = (sample(in1, vec(sxI, syI)).y - 0.5) * 2.0;\nfmI = sqrt(max(vxI*vxI + vyI*vyI, 0.0));\npriIr = mix(dI, -fmI * field_gain, field_priority);\npriI = mix(sentinel, priIr, active_blend);\n\nt0=step(priB,priA);\nbest_pri=mix(priA,priB,t0); best_gx=mix(sxA,sxB,t0); best_gy=mix(syA,syB,t0); best_dx=mix(dxA,dxB,t0); best_dy=mix(dyA,dyB,t0);\nsecond_pri=mix(priB,priA,t0); second_gx=mix(sxB,sxA,t0); second_gy=mix(syB,syA,t0); second_dx=mix(dxB,dxA,t0); second_dy=mix(dyB,dyA,t0);\n\nt=step(priC,best_pri);\ndemoted_pri=mix(priC,best_pri,t); demoted_gx=mix(sxC,best_gx,t); demoted_gy=mix(syC,best_gy,t); demoted_dx=mix(dxC,best_dx,t); demoted_dy=mix(dyC,best_dy,t);\nbest_pri=mix(best_pri,priC,t); best_gx=mix(best_gx,sxC,t); best_gy=mix(best_gy,syC,t); best_dx=mix(best_dx,dxC,t); best_dy=mix(best_dy,dyC,t);\nt2=step(demoted_pri,second_pri);\nsecond_pri=mix(second_pri,demoted_pri,t2); second_gx=mix(second_gx,demoted_gx,t2); second_gy=mix(second_gy,demoted_gy,t2); second_dx=mix(second_dx,demoted_dx,t2); second_dy=mix(second_dy,demoted_dy,t2);\n\nt=step(priD,best_pri);\ndemoted_pri=mix(priD,best_pri,t); demoted_gx=mix(sxD,best_gx,t); demoted_gy=mix(syD,best_gy,t); demoted_dx=mix(dxD,best_dx,t); demoted_dy=mix(dyD,best_dy,t);\nbest_pri=mix(best_pri,priD,t); best_gx=mix(best_gx,sxD,t); best_gy=mix(best_gy,syD,t); best_dx=mix(best_dx,dxD,t); best_dy=mix(best_dy,dyD,t);\nt2=step(demoted_pri,second_pri);\nsecond_pri=mix(second_pri,demoted_pri,t2); second_gx=mix(second_gx,demoted_gx,t2); second_gy=mix(second_gy,demoted_gy,t2); second_dx=mix(second_dx,demoted_dx,t2); second_dy=mix(second_dy,demoted_dy,t2);\n\nt=step(priE,best_pri);\ndemoted_pri=mix(priE,best_pri,t); demoted_gx=mix(sxE,best_gx,t); demoted_gy=mix(syE,best_gy,t); demoted_dx=mix(dxE,best_dx,t); demoted_dy=mix(dyE,best_dy,t);\nbest_pri=mix(best_pri,priE,t); best_gx=mix(best_gx,sxE,t); best_gy=mix(best_gy,syE,t); best_dx=mix(best_dx,dxE,t); best_dy=mix(best_dy,dyE,t);\nt2=step(demoted_pri,second_pri);\nsecond_pri=mix(second_pri,demoted_pri,t2); second_gx=mix(second_gx,demoted_gx,t2); second_gy=mix(second_gy,demoted_gy,t2); second_dx=mix(second_dx,demoted_dx,t2); second_dy=mix(second_dy,demoted_dy,t2);\n\nt=step(priF,best_pri);\ndemoted_pri=mix(priF,best_pri,t); demoted_gx=mix(sxF,best_gx,t); demoted_gy=mix(syF,best_gy,t); demoted_dx=mix(dxF,best_dx,t); demoted_dy=mix(dyF,best_dy,t);\nbest_pri=mix(best_pri,priF,t); best_gx=mix(best_gx,sxF,t); best_gy=mix(best_gy,syF,t); best_dx=mix(best_dx,dxF,t); best_dy=mix(best_dy,dyF,t);\nt2=step(demoted_pri,second_pri);\nsecond_pri=mix(second_pri,demoted_pri,t2); second_gx=mix(second_gx,demoted_gx,t2); second_gy=mix(second_gy,demoted_gy,t2); second_dx=mix(second_dx,demoted_dx,t2); second_dy=mix(second_dy,demoted_dy,t2);\n\nt=step(priG,best_pri);\ndemoted_pri=mix(priG,best_pri,t); demoted_gx=mix(sxG,best_gx,t); demoted_gy=mix(syG,best_gy,t); demoted_dx=mix(dxG,best_dx,t); demoted_dy=mix(dyG,best_dy,t);\nbest_pri=mix(best_pri,priG,t); best_gx=mix(best_gx,sxG,t); best_gy=mix(best_gy,syG,t); best_dx=mix(best_dx,dxG,t); best_dy=mix(best_dy,dyG,t);\nt2=step(demoted_pri,second_pri);\nsecond_pri=mix(second_pri,demoted_pri,t2); second_gx=mix(second_gx,demoted_gx,t2); second_gy=mix(second_gy,demoted_gy,t2); second_dx=mix(second_dx,demoted_dx,t2); second_dy=mix(second_dy,demoted_dy,t2);\n\nt=step(priH,best_pri);\ndemoted_pri=mix(priH,best_pri,t); demoted_gx=mix(sxH,best_gx,t); demoted_gy=mix(syH,best_gy,t); demoted_dx=mix(dxH,best_dx,t); demoted_dy=mix(dyH,best_dy,t);\nbest_pri=mix(best_pri,priH,t); best_gx=mix(best_gx,sxH,t); best_gy=mix(best_gy,syH,t); best_dx=mix(best_dx,dxH,t); best_dy=mix(best_dy,dyH,t);\nt2=step(demoted_pri,second_pri);\nsecond_pri=mix(second_pri,demoted_pri,t2); second_gx=mix(second_gx,demoted_gx,t2); second_gy=mix(second_gy,demoted_gy,t2); second_dx=mix(second_dx,demoted_dx,t2); second_dy=mix(second_dy,demoted_dy,t2);\n\nt=step(priI,best_pri);\ndemoted_pri=mix(priI,best_pri,t); demoted_gx=mix(sxI,best_gx,t); demoted_gy=mix(syI,best_gy,t); demoted_dx=mix(dxI,best_dx,t); demoted_dy=mix(dyI,best_dy,t);\nbest_pri=mix(best_pri,priI,t); best_gx=mix(best_gx,sxI,t); best_gy=mix(best_gy,syI,t); best_dx=mix(best_dx,dxI,t); best_dy=mix(best_dy,dyI,t);\nt2=step(demoted_pri,second_pri);\nsecond_pri=mix(second_pri,demoted_pri,t2); second_gx=mix(second_gx,demoted_gx,t2); second_gy=mix(second_gy,demoted_gy,t2); second_dx=mix(second_dx,demoted_dx,t2); second_dy=mix(second_dy,demoted_dy,t2);\n\nout1 = vec(best_gx, best_gy, best_dx, best_dy);\nout2 = vec(second_gx, second_gy, second_dx, second_dy);\nout3 = vec(best_pri, second_pri, 0.0, 1.0);\n",
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
						258.0,
						380.0,
						208.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name vfseeds_search_b @type float32",
					"varname": "vfseeds_search_b"
				}
			},
			{
				"box": {
					"id": "obj-63",
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
									"id": "gen-obj-13",
									"maxclass": "newobj",
									"numinlets": 0,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										254.0,
										30.0,
										28.0,
										22.0
									],
									"text": "in 5"
								}
							},
							{
								"box": {
									"id": "gen-obj-14",
									"maxclass": "newobj",
									"numinlets": 0,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										312.0,
										30.0,
										28.0,
										22.0
									],
									"text": "in 6"
								}
							},
							{
								"box": {
									"code": "// f_vf_seeds \u2014 Stage 1c: Merge\n// in1: rank1A_coord  in2: rank2A_coord  in3: priA_pair\n// in4: rank1B_coord  in5: rank2B_coord  in6: priB_pair\n//\n// Small top-2 insertion across the 4 candidates surviving Stage 1a/1b\n// (each half already reduced its own 9 down to 2). Confirmed compiling\n// and correctly wired via direct scratch testing (2026-07-04) \u2014 full\n// history in plan.md ADR 7/8.\n//\n// out3 = seed coord, matching the ORIGINAL single-codebox contract\n// exactly (gx, gy, 0.0, 1.0) \u2014 not the dx/dy-carrying internal format\n// out1/out2 use for Stage 2/3's consumption. This outlet bypasses Stage 4\n// entirely (wired directly to the outer module's outlet), so it needs\n// its own bypass gating here rather than relying on Stage 4's.\n\nParam bypass(0.0);\n\ngxA1=sample(in1,vec(norm.x,norm.y)).x; gyA1=sample(in1,vec(norm.x,norm.y)).y;\ndxA1=sample(in1,vec(norm.x,norm.y)).z; dyA1=sample(in1,vec(norm.x,norm.y)).w;\ngxA2=sample(in2,vec(norm.x,norm.y)).x; gyA2=sample(in2,vec(norm.x,norm.y)).y;\ndxA2=sample(in2,vec(norm.x,norm.y)).z; dyA2=sample(in2,vec(norm.x,norm.y)).w;\npriA1=sample(in3,vec(norm.x,norm.y)).x;\npriA2=sample(in3,vec(norm.x,norm.y)).y;\n\ngxB1=sample(in4,vec(norm.x,norm.y)).x; gyB1=sample(in4,vec(norm.x,norm.y)).y;\ndxB1=sample(in4,vec(norm.x,norm.y)).z; dyB1=sample(in4,vec(norm.x,norm.y)).w;\ngxB2=sample(in5,vec(norm.x,norm.y)).x; gyB2=sample(in5,vec(norm.x,norm.y)).y;\ndxB2=sample(in5,vec(norm.x,norm.y)).z; dyB2=sample(in5,vec(norm.x,norm.y)).w;\npriB1=sample(in6,vec(norm.x,norm.y)).x;\npriB2=sample(in6,vec(norm.x,norm.y)).y;\n\nt0=step(priA2,priA1);\nbest_pri=mix(priA1,priA2,t0); best_gx=mix(gxA1,gxA2,t0); best_gy=mix(gyA1,gyA2,t0); best_dx=mix(dxA1,dxA2,t0); best_dy=mix(dyA1,dyA2,t0);\nsecond_pri=mix(priA2,priA1,t0); second_gx=mix(gxA2,gxA1,t0); second_gy=mix(gyA2,gyA1,t0); second_dx=mix(dxA2,dxA1,t0); second_dy=mix(dyA2,dyA1,t0);\n\nt=step(priB1,best_pri);\ndemoted_pri=mix(priB1,best_pri,t); demoted_gx=mix(gxB1,best_gx,t); demoted_gy=mix(gyB1,best_gy,t); demoted_dx=mix(dxB1,best_dx,t); demoted_dy=mix(dyB1,best_dy,t);\nbest_pri=mix(best_pri,priB1,t); best_gx=mix(best_gx,gxB1,t); best_gy=mix(best_gy,gyB1,t); best_dx=mix(best_dx,dxB1,t); best_dy=mix(best_dy,dyB1,t);\nt2=step(demoted_pri,second_pri);\nsecond_pri=mix(second_pri,demoted_pri,t2); second_gx=mix(second_gx,demoted_gx,t2); second_gy=mix(second_gy,demoted_gy,t2); second_dx=mix(second_dx,demoted_dx,t2); second_dy=mix(second_dy,demoted_dy,t2);\n\nt=step(priB2,best_pri);\ndemoted_pri=mix(priB2,best_pri,t); demoted_gx=mix(gxB2,best_gx,t); demoted_gy=mix(gyB2,best_gy,t); demoted_dx=mix(dxB2,best_dx,t); demoted_dy=mix(dyB2,best_dy,t);\nbest_pri=mix(best_pri,priB2,t); best_gx=mix(best_gx,gxB2,t); best_gy=mix(best_gy,gyB2,t); best_dx=mix(best_dx,dxB2,t); best_dy=mix(best_dy,dyB2,t);\nt2=step(demoted_pri,second_pri);\nsecond_pri=mix(second_pri,demoted_pri,t2); second_gx=mix(second_gx,demoted_gx,t2); second_gy=mix(second_gy,demoted_gy,t2); second_dx=mix(second_dx,demoted_dx,t2); second_dy=mix(second_dy,demoted_dy,t2);\n\nout1 = vec(best_gx, best_gy, best_dx, best_dy);\nout2 = vec(second_gx, second_gy, second_dx, second_dy);\nout3 = mix(vec(best_gx, best_gy, 0.0, 1.0), vec(0.0, 0.0, 0.0, 1.0), bypass);\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
									"id": "gen-obj-2",
									"maxclass": "codebox",
									"numinlets": 6,
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
										"gen-obj-2",
										4
									],
									"source": [
										"gen-obj-13",
										0
									]
								}
							},
							{
								"patchline": {
									"destination": [
										"gen-obj-2",
										5
									],
									"source": [
										"gen-obj-14",
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
						430.0,
						200.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name vfseeds_merge @type float32",
					"varname": "vfseeds_merge"
				}
			},
			{
				"box": {
					"id": "obj-64",
					"maxclass": "newobj",
					"numinlets": 5,
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
									"id": "gen-obj-13",
									"maxclass": "newobj",
									"numinlets": 0,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										254.0,
										30.0,
										28.0,
										22.0
									],
									"text": "in 5"
								}
							},
							{
								"box": {
									"code": "// f_vf_seeds \u2014 Stage 2/3: Render\n// Rank-agnostic \u2014 same codebox instanced twice, once per rank_coord input.\n// in1: rank_coord (gx, gy, dx, dy from Stage 1c merge)\n// in2: shape tex\n// in3: vecfield\n// in4: mod tex\n// in5: color driving texture (Evolution 3 \u2014 seed-sampled color blend)\n//\n// Reproduces Evolution 1.5's exact per-winner downstream block (orientation\n// projection, mod-tex sample, gate, shape sample, luma alpha) but consumes\n// dx/dy from Stage 1c rather than recomputing them. No bypass here \u2014 per\n// plan.md ADR 8, bypass is applied only at Stage 4 (composite).\n\nParam strength(1.0);\nParam mag_weight(0.0);\nParam size(0.2);\nParam stretch(0.0);\nParam phase(0.0);\nParam size_mod(0.0);\nParam stretch_mod(0.0);\nParam src_shape(1.0);\nParam src_mod(0.0);\n\n// \u2500\u2500 Evolution 3: seed-sampled color, blended in via color_mode \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\nParam color_mode(0.0);\nParam src_color_drive(0.0);\n\naspect = dim.x / dim.y;\n\n// \u2500\u2500 Consume Stage 1c's coord (pixel-for-pixel passthrough, same context) \u2500\u2500\u2500\u2500\n\ngx = sample(in1, vec(norm.x, norm.y)).x;\ngy = sample(in1, vec(norm.x, norm.y)).y;\ndx = sample(in1, vec(norm.x, norm.y)).z;\ndy = sample(in1, vec(norm.x, norm.y)).w;\n\n// \u2500\u2500 Vecfield sampled at this rank's seed position \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n\nvx = (sample(in3, vec(gx, gy)).x - 0.5) * 2.0;\nvy = (sample(in3, vec(gx, gy)).y - 0.5) * 2.0;\nfield_mag = sqrt(max(vx*vx + vy*vy, 0.0));\n\n// \u2500\u2500 Orientation \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n\nmag = max(field_mag, 0.0001);\nfcs = vx / mag;\nfsn = vy / mag;\ncs = mix(1.0, fcs, strength);\nsn = mix(0.0, fsn, strength);\nmag2 = max(sqrt(cs*cs + sn*sn), 0.0001);\ncs = cs / mag2;\nsn = sn / mag2;\n\n// \u2500\u2500 Project pixel offset into seed-local frame \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n\nodx = dx * aspect;\nody = dy;\nalong  =  odx * cs + ody * sn;\nacross = -odx * sn + ody * cs;\n\n// \u2500\u2500 Mod tex modulation \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n\nmod_sample = sample(in4, vec(gx, gy)).x * src_mod;\nsize_eff = clamp(size + mod_sample * size_mod + field_mag * mag_weight, 0.001, 0.5);\nstretch_eff = stretch + mod_sample * stretch_mod;\nstretch_factor = 1.0 + stretch_eff;\nmarklen_eff = size_eff * stretch_factor;\nweight_eff = size_eff / max(stretch_factor, 0.0001);\n\n// \u2500\u2500 Construct seed-local UV \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n\nalong_shifted = along - phase * marklen_eff;\nlocal_u = along_shifted / marklen_eff * 0.5 + 0.5;\nlocal_v = across / weight_eff * 0.5 + 0.5;\n\n// \u2500\u2500 Gate \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n\ngate = step(abs(along_shifted), marklen_eff) * step(abs(across), weight_eff);\n\n// \u2500\u2500 Sample shape tex \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n\nshape_r = sample(in2, vec(local_u, local_v)).x;\nshape_g = sample(in2, vec(local_u, local_v)).y;\nshape_b = sample(in2, vec(local_u, local_v)).z;\nshape_luma = (shape_r + shape_g + shape_b) / 3.0;\n\n// \u2500\u2500 Evolution 3: color drive tex, sampled once per seed at (gx, gy) \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n// Same coordinate already used for vecfield/mod-tex sampling, so a bombed\n// (jittered) second seed automatically samples under its own jittered\n// position \u2014 no extra wiring needed for that to fall out correctly.\n\ndrive_r = sample(in5, vec(gx, gy)).x;\ndrive_g = sample(in5, vec(gx, gy)).y;\ndrive_b = sample(in5, vec(gx, gy)).z;\n\n// \u2500\u2500 Blend shape color with seed-sampled color (T036) \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n// color_mode=0: shape tex's own color (regression, unchanged).\n// color_mode=1: fully replaced by the color driving texture's sample.\n// Gated by src_color_drive so an unconnected inlet can't blend toward black.\n//\n// Weighted by shape_luma, NOT just gate: gate is only a rectangular bounding\n// box (sized by `size`), not the shape's actual silhouette \u2014 most of that\n// box is normally black because the shape tex itself is black there. Since\n// drive_r/g/b is a single constant color per seed (sampled once at gx,gy,\n// not varying across local_u/local_v), blending it in across the whole gate\n// box would flood that mostly-black background with flat color \u2014 visible\n// as a full Voronoi cell fill with hard box edges once seed spacing gets\n// close to `size`. Weighting by shape_luma confines the color swap to\n// wherever the shape is actually drawn.\n\nblend = color_mode * src_color_drive * shape_luma;\nfinal_r = mix(shape_r, drive_r, blend);\nfinal_g = mix(shape_g, drive_g, blend);\nfinal_b = mix(shape_b, drive_b, blend);\n\nmark_r = final_r * gate * src_shape;\nmark_g = final_g * gate * src_shape;\nmark_b = final_b * gate * src_shape;\nmark_a = shape_luma * gate * src_shape;\n\n// \u2500\u2500 Output \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n\nout1 = vec(mark_r, mark_g, mark_b, mark_a);\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
									"id": "gen-obj-2",
									"maxclass": "codebox",
									"numinlets": 5,
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
										"gen-obj-2",
										4
									],
									"source": [
										"gen-obj-13",
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
						208.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name vfseeds_render_1",
					"varname": "vfseeds_render_1"
				}
			},
			{
				"box": {
					"id": "obj-65",
					"maxclass": "newobj",
					"numinlets": 5,
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
									"id": "gen-obj-13",
									"maxclass": "newobj",
									"numinlets": 0,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										254.0,
										30.0,
										28.0,
										22.0
									],
									"text": "in 5"
								}
							},
							{
								"box": {
									"code": "// f_vf_seeds \u2014 Stage 2/3: Render\n// Rank-agnostic \u2014 same codebox instanced twice, once per rank_coord input.\n// in1: rank_coord (gx, gy, dx, dy from Stage 1c merge)\n// in2: shape tex\n// in3: vecfield\n// in4: mod tex\n// in5: color driving texture (Evolution 3 \u2014 seed-sampled color blend)\n//\n// Reproduces Evolution 1.5's exact per-winner downstream block (orientation\n// projection, mod-tex sample, gate, shape sample, luma alpha) but consumes\n// dx/dy from Stage 1c rather than recomputing them. No bypass here \u2014 per\n// plan.md ADR 8, bypass is applied only at Stage 4 (composite).\n\nParam strength(1.0);\nParam mag_weight(0.0);\nParam size(0.2);\nParam stretch(0.0);\nParam phase(0.0);\nParam size_mod(0.0);\nParam stretch_mod(0.0);\nParam src_shape(1.0);\nParam src_mod(0.0);\n\n// \u2500\u2500 Evolution 3: seed-sampled color, blended in via color_mode \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\nParam color_mode(0.0);\nParam src_color_drive(0.0);\n\naspect = dim.x / dim.y;\n\n// \u2500\u2500 Consume Stage 1c's coord (pixel-for-pixel passthrough, same context) \u2500\u2500\u2500\u2500\n\ngx = sample(in1, vec(norm.x, norm.y)).x;\ngy = sample(in1, vec(norm.x, norm.y)).y;\ndx = sample(in1, vec(norm.x, norm.y)).z;\ndy = sample(in1, vec(norm.x, norm.y)).w;\n\n// \u2500\u2500 Vecfield sampled at this rank's seed position \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n\nvx = (sample(in3, vec(gx, gy)).x - 0.5) * 2.0;\nvy = (sample(in3, vec(gx, gy)).y - 0.5) * 2.0;\nfield_mag = sqrt(max(vx*vx + vy*vy, 0.0));\n\n// \u2500\u2500 Orientation \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n\nmag = max(field_mag, 0.0001);\nfcs = vx / mag;\nfsn = vy / mag;\ncs = mix(1.0, fcs, strength);\nsn = mix(0.0, fsn, strength);\nmag2 = max(sqrt(cs*cs + sn*sn), 0.0001);\ncs = cs / mag2;\nsn = sn / mag2;\n\n// \u2500\u2500 Project pixel offset into seed-local frame \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n\nodx = dx * aspect;\nody = dy;\nalong  =  odx * cs + ody * sn;\nacross = -odx * sn + ody * cs;\n\n// \u2500\u2500 Mod tex modulation \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n\nmod_sample = sample(in4, vec(gx, gy)).x * src_mod;\nsize_eff = clamp(size + mod_sample * size_mod + field_mag * mag_weight, 0.001, 0.5);\nstretch_eff = stretch + mod_sample * stretch_mod;\nstretch_factor = 1.0 + stretch_eff;\nmarklen_eff = size_eff * stretch_factor;\nweight_eff = size_eff / max(stretch_factor, 0.0001);\n\n// \u2500\u2500 Construct seed-local UV \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n\nalong_shifted = along - phase * marklen_eff;\nlocal_u = along_shifted / marklen_eff * 0.5 + 0.5;\nlocal_v = across / weight_eff * 0.5 + 0.5;\n\n// \u2500\u2500 Gate \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n\ngate = step(abs(along_shifted), marklen_eff) * step(abs(across), weight_eff);\n\n// \u2500\u2500 Sample shape tex \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n\nshape_r = sample(in2, vec(local_u, local_v)).x;\nshape_g = sample(in2, vec(local_u, local_v)).y;\nshape_b = sample(in2, vec(local_u, local_v)).z;\nshape_luma = (shape_r + shape_g + shape_b) / 3.0;\n\n// \u2500\u2500 Evolution 3: color drive tex, sampled once per seed at (gx, gy) \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n// Same coordinate already used for vecfield/mod-tex sampling, so a bombed\n// (jittered) second seed automatically samples under its own jittered\n// position \u2014 no extra wiring needed for that to fall out correctly.\n\ndrive_r = sample(in5, vec(gx, gy)).x;\ndrive_g = sample(in5, vec(gx, gy)).y;\ndrive_b = sample(in5, vec(gx, gy)).z;\n\n// \u2500\u2500 Blend shape color with seed-sampled color (T036) \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n// color_mode=0: shape tex's own color (regression, unchanged).\n// color_mode=1: fully replaced by the color driving texture's sample.\n// Gated by src_color_drive so an unconnected inlet can't blend toward black.\n//\n// Weighted by shape_luma, NOT just gate: gate is only a rectangular bounding\n// box (sized by `size`), not the shape's actual silhouette \u2014 most of that\n// box is normally black because the shape tex itself is black there. Since\n// drive_r/g/b is a single constant color per seed (sampled once at gx,gy,\n// not varying across local_u/local_v), blending it in across the whole gate\n// box would flood that mostly-black background with flat color \u2014 visible\n// as a full Voronoi cell fill with hard box edges once seed spacing gets\n// close to `size`. Weighting by shape_luma confines the color swap to\n// wherever the shape is actually drawn.\n\nblend = color_mode * src_color_drive * shape_luma;\nfinal_r = mix(shape_r, drive_r, blend);\nfinal_g = mix(shape_g, drive_g, blend);\nfinal_b = mix(shape_b, drive_b, blend);\n\nmark_r = final_r * gate * src_shape;\nmark_g = final_g * gate * src_shape;\nmark_b = final_b * gate * src_shape;\nmark_a = shape_luma * gate * src_shape;\n\n// \u2500\u2500 Output \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n\nout1 = vec(mark_r, mark_g, mark_b, mark_a);\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
									"id": "gen-obj-2",
									"maxclass": "codebox",
									"numinlets": 5,
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
										"gen-obj-2",
										4
									],
									"source": [
										"gen-obj-13",
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
						258.0,
						480.0,
						208.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name vfseeds_render_2",
					"varname": "vfseeds_render_2"
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
									"code": "// f_vf_seeds \u2014 Stage 4: Composite\n// in1: rank1 render (mark_r, mark_g, mark_b, mark_a)\n// in2: rank2 render (mark_r, mark_g, mark_b, mark_a)\n//\n// Rank-1-over-rank-2 alpha composite, using rank1's own alpha (luma-keyed,\n// per Evolution 1.5) as the blend factor. bypass lives here for out1 \u2014\n// Stage 2/3's output is discarded either way once composited, so no\n// bypass gating needed upstream for the mark-color path (plan.md ADR 8).\n//\n// out2 = mark mask (comp_a as grayscale, matching the ORIGINAL\n// single-codebox contract's separate mask outlet).\n\nParam bypass(0.0);\n\nr1 = sample(in1, vec(norm.x, norm.y)).x;\ng1 = sample(in1, vec(norm.x, norm.y)).y;\nb1 = sample(in1, vec(norm.x, norm.y)).z;\na1 = sample(in1, vec(norm.x, norm.y)).w;\n\nr2 = sample(in2, vec(norm.x, norm.y)).x;\ng2 = sample(in2, vec(norm.x, norm.y)).y;\nb2 = sample(in2, vec(norm.x, norm.y)).z;\na2 = sample(in2, vec(norm.x, norm.y)).w;\n\ncomp_r = mix(r2, r1, a1);\ncomp_g = mix(g2, g1, a1);\ncomp_b = mix(b2, b1, a1);\ncomp_a = a1 + a2 * (1.0 - a1);\n\nout1 = mix(vec(comp_r, comp_g, comp_b, comp_a), vec(0.0, 0.0, 0.0, 0.0), bypass);\nout2 = mix(vec(comp_a, comp_a, comp_a, 1.0), vec(0.0, 0.0, 0.0, 1.0), bypass);\n",
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
						530.0,
						216.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name vfseeds_composite",
					"varname": "vfseeds_composite"
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
						1279.5,
						100.0,
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
						1059.5,
						260.0,
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
						1279.5,
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
					"text": "Seeds"
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
						1369.5,
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
					"text": "\u2207 in"
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
						1279.5,
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
						1299.5,
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
						1059.5,
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
						1059.5,
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
						1059.5,
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
						1059.5,
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
						1059.5,
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
						1059.5,
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
					"text": "prepend param src_shape"
				}
			},
			{
				"box": {
					"id": "obj-100",
					"maxclass": "inlet",
					"comment": "vecfield",
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
					"comment": "mod tex",
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
					"id": "obj-106",
					"maxclass": "inlet",
					"comment": "color drive tex",
					"index": 0,
					"numinlets": 0,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						600.0,
						20.0,
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
						600.0,
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
					"text": "prepend param src_vecfield"
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
					"text": "prepend param src_mod"
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
						600.0,
						120.0,
						160.0,
						22.0
					],
					"text": "prepend param src_color_drive"
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
					"hint": "Field-priority scale \u2014 useful window varies by vecfield source (Flow ~0.2, Repulse ~0.8, Vortex ~1.5).",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
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
						30.0,
						682.0,
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
						30.0,
						717.0,
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
						30.0,
						752.0,
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
						30.0,
						782.0,
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
						30.0,
						812.0,
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
					"hint": "Second-sample-per-cell toggle \u2014 behaves as on/off, not a graded fader (see spec.md Evolution 2). Its attrui is bound directly to active_blend on Stage 1b \u2014 the dial itself keeps showing \"Bomb\".",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						622.5,
						250.0,
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
					"id": "obj-45",
					"maxclass": "attrui",
					"attr": "active_blend",
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
					"id": "obj-46",
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
					"id": "obj-47",
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
						694.5,
						250.0,
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
					"id": "obj-48",
					"maxclass": "attrui",
					"attr": "phase",
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
					"id": "obj-49",
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
					"id": "obj-50",
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
						766.5,
						250.0,
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
					"id": "obj-51",
					"maxclass": "attrui",
					"attr": "size_mod",
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
					"id": "obj-52",
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
					"id": "obj-53",
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
						838.5,
						250.0,
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
					"id": "obj-54",
					"maxclass": "attrui",
					"attr": "stretch_mod",
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
					"id": "obj-55",
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
					"id": "obj-56",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Blend between shape tex's own color (0) and the color driving texture sampled at each seed's position (1).",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						910.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						78.0,
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
							"parameter_longname": "color_mode",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "color_mode",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "color_mode"
				}
			},
			{
				"box": {
					"id": "obj-57",
					"maxclass": "attrui",
					"attr": "color_mode",
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
					"id": "obj-58",
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
						66.5,
						144.0,
						50.0,
						18.0
					],
					"text": "Color Mode",
					"textjustification": 1
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
						1279.5,
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
					"id": "obj-60",
					"maxclass": "attrui",
					"attr": "bypass",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1279.5,
						160.0,
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
						"obj-64",
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
						"obj-65",
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
						"obj-64",
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
						"obj-65",
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
						"obj-63",
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
						"obj-61",
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
						"obj-62",
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
						"obj-64",
						2
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
						"obj-65",
						2
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
						"obj-64",
						3
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
						"obj-65",
						3
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
						"obj-64",
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
						"obj-65",
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
						"obj-64",
						4
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
						"obj-65",
						4
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
						"obj-64",
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
						"obj-65",
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
						"obj-63",
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
						"obj-61",
						0
					],
					"destination": [
						"obj-63",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-61",
						1
					],
					"destination": [
						"obj-63",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-61",
						2
					],
					"destination": [
						"obj-63",
						2
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-62",
						0
					],
					"destination": [
						"obj-63",
						3
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-62",
						1
					],
					"destination": [
						"obj-63",
						4
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-62",
						2
					],
					"destination": [
						"obj-63",
						5
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-63",
						0
					],
					"destination": [
						"obj-64",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-63",
						1
					],
					"destination": [
						"obj-65",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-64",
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
						"obj-65",
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
						"obj-61",
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
						"obj-62",
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
						"obj-61",
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
						"obj-62",
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
						"obj-64",
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
						"obj-65",
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
						"obj-64",
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
						"obj-65",
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
						"obj-64",
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
						"obj-65",
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
						"obj-64",
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
						"obj-65",
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
						"obj-61",
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
						"obj-62",
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
						"obj-61",
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
						"obj-62",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-370",
						2
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
						"obj-62",
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
						"obj-64",
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
						"obj-65",
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
						"obj-64",
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
						"obj-65",
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
						"obj-64",
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
						"obj-65",
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
						"obj-64",
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
						"obj-65",
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
				"bomb",
				"bomb",
				0
			],
			"obj-47": [
				"phase",
				"phase",
				0
			],
			"obj-50": [
				"size_mod",
				"size_mod",
				0
			],
			"obj-53": [
				"stretch_mod",
				"stretch_mod",
				0
			],
			"obj-56": [
				"color_mode",
				"color_mode",
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