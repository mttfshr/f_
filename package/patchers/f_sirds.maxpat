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
			700.0
		],
		"openinpresentation": 1,
		"boxes": [
			{
				"box": {
					"id": "obj-1",
					"maxclass": "inlet",
					"comment": "pattern texture / control",
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
					"comment": "sirds",
					"index": 0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						30.0,
						600.0,
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
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						200.0,
						130.0,
						200.0,
						22.0
					],
					"text": "route depth_factor"
				}
			},
			{
				"box": {
					"id": "obj-210",
					"maxclass": "inlet",
					"comment": "depth",
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
					"id": "obj-211",
					"maxclass": "newobj",
					"text": "vs_inState",
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
					]
				}
			},
			{
				"box": {
					"id": "obj-5",
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
							500.0,
							400.0
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
									"code": "uv = norm;\nlocal_x = mod(uv.x, 0.07692307692307693) / 0.07692307692307693;\nresult = sample(in1, vec(local_x, uv.y));\n\nout1 = result;\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
									"numinlets": 1,
									"numoutlets": 1,
									"patching_rect": [
										22.0,
										80.0,
										450.0,
										200.0
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
										300.0,
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
						400.0,
						100.0,
						320.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_sirds_stage0 @adapt 1",
					"varname": "#0_sirds_stage0"
				}
			},
			{
				"box": {
					"id": "obj-6",
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
							600.0,
							500.0
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
									"maxclass": "codebox",
									"code": "Param depth_factor(0.0);\nParam bypass(0.0);\n\nuv = norm;\nstrip_lo = 1.0 * 0.07692307692307693;\nstrip_hi = strip_lo + 0.07692307692307693;\n\nin_strip = step(strip_lo, uv.x) * step(uv.x, strip_hi) * (1.0 - bypass);\n\ndepth_uv = vec((uv.x - 0.07692307692307693) / (1.0 - 0.07692307692307693), uv.y);\ndepth_val = sample(in2, depth_uv).x * 0.299 + sample(in2, depth_uv).y * 0.587 + sample(in2, depth_uv).z * 0.114;\nshift_x = uv.x - 0.07692307692307693 + depth_val * depth_factor * 0.07692307692307693;\n\ncomputed = sample(in1, vec(shift_x, uv.y));\npassthrough = sample(in1, uv);\n\nout1 = mix(passthrough, computed, in_strip);\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
									"numinlets": 2,
									"numoutlets": 1,
									"patching_rect": [
										22.0,
										80.0,
										550.0,
										320.0
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
										420.0,
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
						130.0,
						320.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_sirds_stage1 @adapt 1",
					"varname": "#0_sirds_stage1"
				}
			},
			{
				"box": {
					"id": "obj-7",
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
							600.0,
							500.0
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
									"maxclass": "codebox",
									"code": "Param depth_factor(0.0);\nParam bypass(0.0);\n\nuv = norm;\nstrip_lo = 2.0 * 0.07692307692307693;\nstrip_hi = strip_lo + 0.07692307692307693;\n\nin_strip = step(strip_lo, uv.x) * step(uv.x, strip_hi) * (1.0 - bypass);\n\ndepth_uv = vec((uv.x - 0.07692307692307693) / (1.0 - 0.07692307692307693), uv.y);\ndepth_val = sample(in2, depth_uv).x * 0.299 + sample(in2, depth_uv).y * 0.587 + sample(in2, depth_uv).z * 0.114;\nshift_x = uv.x - 0.07692307692307693 + depth_val * depth_factor * 0.07692307692307693;\n\ncomputed = sample(in1, vec(shift_x, uv.y));\npassthrough = sample(in1, uv);\n\nout1 = mix(passthrough, computed, in_strip);\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
									"numinlets": 2,
									"numoutlets": 1,
									"patching_rect": [
										22.0,
										80.0,
										550.0,
										320.0
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
										420.0,
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
						160.0,
						320.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_sirds_stage2 @adapt 1",
					"varname": "#0_sirds_stage2"
				}
			},
			{
				"box": {
					"id": "obj-8",
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
							600.0,
							500.0
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
									"maxclass": "codebox",
									"code": "Param depth_factor(0.0);\nParam bypass(0.0);\n\nuv = norm;\nstrip_lo = 3.0 * 0.07692307692307693;\nstrip_hi = strip_lo + 0.07692307692307693;\n\nin_strip = step(strip_lo, uv.x) * step(uv.x, strip_hi) * (1.0 - bypass);\n\ndepth_uv = vec((uv.x - 0.07692307692307693) / (1.0 - 0.07692307692307693), uv.y);\ndepth_val = sample(in2, depth_uv).x * 0.299 + sample(in2, depth_uv).y * 0.587 + sample(in2, depth_uv).z * 0.114;\nshift_x = uv.x - 0.07692307692307693 + depth_val * depth_factor * 0.07692307692307693;\n\ncomputed = sample(in1, vec(shift_x, uv.y));\npassthrough = sample(in1, uv);\n\nout1 = mix(passthrough, computed, in_strip);\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
									"numinlets": 2,
									"numoutlets": 1,
									"patching_rect": [
										22.0,
										80.0,
										550.0,
										320.0
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
										420.0,
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
						190.0,
						320.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_sirds_stage3 @adapt 1",
					"varname": "#0_sirds_stage3"
				}
			},
			{
				"box": {
					"id": "obj-9",
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
							600.0,
							500.0
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
									"maxclass": "codebox",
									"code": "Param depth_factor(0.0);\nParam bypass(0.0);\n\nuv = norm;\nstrip_lo = 4.0 * 0.07692307692307693;\nstrip_hi = strip_lo + 0.07692307692307693;\n\nin_strip = step(strip_lo, uv.x) * step(uv.x, strip_hi) * (1.0 - bypass);\n\ndepth_uv = vec((uv.x - 0.07692307692307693) / (1.0 - 0.07692307692307693), uv.y);\ndepth_val = sample(in2, depth_uv).x * 0.299 + sample(in2, depth_uv).y * 0.587 + sample(in2, depth_uv).z * 0.114;\nshift_x = uv.x - 0.07692307692307693 + depth_val * depth_factor * 0.07692307692307693;\n\ncomputed = sample(in1, vec(shift_x, uv.y));\npassthrough = sample(in1, uv);\n\nout1 = mix(passthrough, computed, in_strip);\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
									"numinlets": 2,
									"numoutlets": 1,
									"patching_rect": [
										22.0,
										80.0,
										550.0,
										320.0
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
										420.0,
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
						220.0,
						320.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_sirds_stage4 @adapt 1",
					"varname": "#0_sirds_stage4"
				}
			},
			{
				"box": {
					"id": "obj-10",
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
							600.0,
							500.0
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
									"maxclass": "codebox",
									"code": "Param depth_factor(0.0);\nParam bypass(0.0);\n\nuv = norm;\nstrip_lo = 5.0 * 0.07692307692307693;\nstrip_hi = strip_lo + 0.07692307692307693;\n\nin_strip = step(strip_lo, uv.x) * step(uv.x, strip_hi) * (1.0 - bypass);\n\ndepth_uv = vec((uv.x - 0.07692307692307693) / (1.0 - 0.07692307692307693), uv.y);\ndepth_val = sample(in2, depth_uv).x * 0.299 + sample(in2, depth_uv).y * 0.587 + sample(in2, depth_uv).z * 0.114;\nshift_x = uv.x - 0.07692307692307693 + depth_val * depth_factor * 0.07692307692307693;\n\ncomputed = sample(in1, vec(shift_x, uv.y));\npassthrough = sample(in1, uv);\n\nout1 = mix(passthrough, computed, in_strip);\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
									"numinlets": 2,
									"numoutlets": 1,
									"patching_rect": [
										22.0,
										80.0,
										550.0,
										320.0
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
										420.0,
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
						250.0,
						320.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_sirds_stage5 @adapt 1",
					"varname": "#0_sirds_stage5"
				}
			},
			{
				"box": {
					"id": "obj-11",
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
							600.0,
							500.0
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
									"maxclass": "codebox",
									"code": "Param depth_factor(0.0);\nParam bypass(0.0);\n\nuv = norm;\nstrip_lo = 6.0 * 0.07692307692307693;\nstrip_hi = strip_lo + 0.07692307692307693;\n\nin_strip = step(strip_lo, uv.x) * step(uv.x, strip_hi) * (1.0 - bypass);\n\ndepth_uv = vec((uv.x - 0.07692307692307693) / (1.0 - 0.07692307692307693), uv.y);\ndepth_val = sample(in2, depth_uv).x * 0.299 + sample(in2, depth_uv).y * 0.587 + sample(in2, depth_uv).z * 0.114;\nshift_x = uv.x - 0.07692307692307693 + depth_val * depth_factor * 0.07692307692307693;\n\ncomputed = sample(in1, vec(shift_x, uv.y));\npassthrough = sample(in1, uv);\n\nout1 = mix(passthrough, computed, in_strip);\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
									"numinlets": 2,
									"numoutlets": 1,
									"patching_rect": [
										22.0,
										80.0,
										550.0,
										320.0
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
										420.0,
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
						280.0,
						320.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_sirds_stage6 @adapt 1",
					"varname": "#0_sirds_stage6"
				}
			},
			{
				"box": {
					"id": "obj-12",
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
							600.0,
							500.0
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
									"maxclass": "codebox",
									"code": "Param depth_factor(0.0);\nParam bypass(0.0);\n\nuv = norm;\nstrip_lo = 7.0 * 0.07692307692307693;\nstrip_hi = strip_lo + 0.07692307692307693;\n\nin_strip = step(strip_lo, uv.x) * step(uv.x, strip_hi) * (1.0 - bypass);\n\ndepth_uv = vec((uv.x - 0.07692307692307693) / (1.0 - 0.07692307692307693), uv.y);\ndepth_val = sample(in2, depth_uv).x * 0.299 + sample(in2, depth_uv).y * 0.587 + sample(in2, depth_uv).z * 0.114;\nshift_x = uv.x - 0.07692307692307693 + depth_val * depth_factor * 0.07692307692307693;\n\ncomputed = sample(in1, vec(shift_x, uv.y));\npassthrough = sample(in1, uv);\n\nout1 = mix(passthrough, computed, in_strip);\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
									"numinlets": 2,
									"numoutlets": 1,
									"patching_rect": [
										22.0,
										80.0,
										550.0,
										320.0
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
										420.0,
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
						310.0,
						320.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_sirds_stage7 @adapt 1",
					"varname": "#0_sirds_stage7"
				}
			},
			{
				"box": {
					"id": "obj-13",
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
							600.0,
							500.0
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
									"maxclass": "codebox",
									"code": "Param depth_factor(0.0);\nParam bypass(0.0);\n\nuv = norm;\nstrip_lo = 8.0 * 0.07692307692307693;\nstrip_hi = strip_lo + 0.07692307692307693;\n\nin_strip = step(strip_lo, uv.x) * step(uv.x, strip_hi) * (1.0 - bypass);\n\ndepth_uv = vec((uv.x - 0.07692307692307693) / (1.0 - 0.07692307692307693), uv.y);\ndepth_val = sample(in2, depth_uv).x * 0.299 + sample(in2, depth_uv).y * 0.587 + sample(in2, depth_uv).z * 0.114;\nshift_x = uv.x - 0.07692307692307693 + depth_val * depth_factor * 0.07692307692307693;\n\ncomputed = sample(in1, vec(shift_x, uv.y));\npassthrough = sample(in1, uv);\n\nout1 = mix(passthrough, computed, in_strip);\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
									"numinlets": 2,
									"numoutlets": 1,
									"patching_rect": [
										22.0,
										80.0,
										550.0,
										320.0
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
										420.0,
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
						340.0,
						320.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_sirds_stage8 @adapt 1",
					"varname": "#0_sirds_stage8"
				}
			},
			{
				"box": {
					"id": "obj-14",
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
							600.0,
							500.0
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
									"maxclass": "codebox",
									"code": "Param depth_factor(0.0);\nParam bypass(0.0);\n\nuv = norm;\nstrip_lo = 9.0 * 0.07692307692307693;\nstrip_hi = strip_lo + 0.07692307692307693;\n\nin_strip = step(strip_lo, uv.x) * step(uv.x, strip_hi) * (1.0 - bypass);\n\ndepth_uv = vec((uv.x - 0.07692307692307693) / (1.0 - 0.07692307692307693), uv.y);\ndepth_val = sample(in2, depth_uv).x * 0.299 + sample(in2, depth_uv).y * 0.587 + sample(in2, depth_uv).z * 0.114;\nshift_x = uv.x - 0.07692307692307693 + depth_val * depth_factor * 0.07692307692307693;\n\ncomputed = sample(in1, vec(shift_x, uv.y));\npassthrough = sample(in1, uv);\n\nout1 = mix(passthrough, computed, in_strip);\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
									"numinlets": 2,
									"numoutlets": 1,
									"patching_rect": [
										22.0,
										80.0,
										550.0,
										320.0
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
										420.0,
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
						370.0,
						320.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_sirds_stage9 @adapt 1",
					"varname": "#0_sirds_stage9"
				}
			},
			{
				"box": {
					"id": "obj-15",
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
							600.0,
							500.0
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
									"maxclass": "codebox",
									"code": "Param depth_factor(0.0);\nParam bypass(0.0);\n\nuv = norm;\nstrip_lo = 10.0 * 0.07692307692307693;\nstrip_hi = strip_lo + 0.07692307692307693;\n\nin_strip = step(strip_lo, uv.x) * step(uv.x, strip_hi) * (1.0 - bypass);\n\ndepth_uv = vec((uv.x - 0.07692307692307693) / (1.0 - 0.07692307692307693), uv.y);\ndepth_val = sample(in2, depth_uv).x * 0.299 + sample(in2, depth_uv).y * 0.587 + sample(in2, depth_uv).z * 0.114;\nshift_x = uv.x - 0.07692307692307693 + depth_val * depth_factor * 0.07692307692307693;\n\ncomputed = sample(in1, vec(shift_x, uv.y));\npassthrough = sample(in1, uv);\n\nout1 = mix(passthrough, computed, in_strip);\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
									"numinlets": 2,
									"numoutlets": 1,
									"patching_rect": [
										22.0,
										80.0,
										550.0,
										320.0
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
										420.0,
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
						400.0,
						320.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_sirds_stage10 @adapt 1",
					"varname": "#0_sirds_stage10"
				}
			},
			{
				"box": {
					"id": "obj-16",
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
							600.0,
							500.0
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
									"maxclass": "codebox",
									"code": "Param depth_factor(0.0);\nParam bypass(0.0);\n\nuv = norm;\nstrip_lo = 11.0 * 0.07692307692307693;\nstrip_hi = strip_lo + 0.07692307692307693;\n\nin_strip = step(strip_lo, uv.x) * step(uv.x, strip_hi) * (1.0 - bypass);\n\ndepth_uv = vec((uv.x - 0.07692307692307693) / (1.0 - 0.07692307692307693), uv.y);\ndepth_val = sample(in2, depth_uv).x * 0.299 + sample(in2, depth_uv).y * 0.587 + sample(in2, depth_uv).z * 0.114;\nshift_x = uv.x - 0.07692307692307693 + depth_val * depth_factor * 0.07692307692307693;\n\ncomputed = sample(in1, vec(shift_x, uv.y));\npassthrough = sample(in1, uv);\n\nout1 = mix(passthrough, computed, in_strip);\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
									"numinlets": 2,
									"numoutlets": 1,
									"patching_rect": [
										22.0,
										80.0,
										550.0,
										320.0
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
										420.0,
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
						430.0,
						320.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_sirds_stage11 @adapt 1",
					"varname": "#0_sirds_stage11"
				}
			},
			{
				"box": {
					"id": "obj-17",
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
							600.0,
							500.0
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
									"maxclass": "codebox",
									"code": "Param depth_factor(0.0);\nParam bypass(0.0);\n\nuv = norm;\nstrip_lo = 12.0 * 0.07692307692307693;\nstrip_hi = strip_lo + 0.07692307692307693;\n\nin_strip = step(strip_lo, uv.x) * step(uv.x, strip_hi) * (1.0 - bypass);\n\ndepth_uv = vec((uv.x - 0.07692307692307693) / (1.0 - 0.07692307692307693), uv.y);\ndepth_val = sample(in2, depth_uv).x * 0.299 + sample(in2, depth_uv).y * 0.587 + sample(in2, depth_uv).z * 0.114;\nshift_x = uv.x - 0.07692307692307693 + depth_val * depth_factor * 0.07692307692307693;\n\ncomputed = sample(in1, vec(shift_x, uv.y));\npassthrough = sample(in1, uv);\n\nout1 = mix(passthrough, computed, in_strip);\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
									"numinlets": 2,
									"numoutlets": 1,
									"patching_rect": [
										22.0,
										80.0,
										550.0,
										320.0
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
										420.0,
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
						460.0,
						320.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_sirds_stage12 @adapt 1",
					"varname": "#0_sirds_stage12"
				}
			},
			{
				"box": {
					"id": "obj-200",
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
						600.0,
						56.0,
						22.0
					],
					"text": "autopattr",
					"varname": "sirds_autopattr"
				}
			},
			{
				"box": {
					"id": "obj-201",
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
						130.0
					],
					"presentation": 1,
					"presentation_rect": [
						0.0,
						0.0,
						190.0,
						130.0
					],
					"proportion": 0.5
				}
			},
			{
				"box": {
					"id": "obj-202",
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
					"text": "SIRDS"
				}
			},
			{
				"box": {
					"id": "obj-203",
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
					"id": "obj-204",
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
					"id": "obj-205",
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
					"id": "obj-206",
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
					"id": "obj-207",
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
					"id": "obj-208",
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
			},
			{
				"box": {
					"id": "obj-220",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
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
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "depth_factor",
							"parameter_mmax": 0.3,
							"parameter_mmin": -0.3,
							"parameter_modmode": 3,
							"parameter_shortname": "depth_factor",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "depth_factor"
				}
			},
			{
				"box": {
					"id": "obj-221",
					"maxclass": "attrui",
					"attr": "depth_factor",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						50.0,
						170.0,
						164.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-222",
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
					"text": "depth",
					"textjustification": 1
				}
			},
			{
				"box": {
					"id": "obj-230",
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
					"id": "obj-231",
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
						"obj-210",
						0
					],
					"destination": [
						"obj-211",
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
						"obj-220",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-220",
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
						"obj-5",
						0
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
						"obj-6",
						0
					],
					"destination": [
						"obj-7",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-7",
						0
					],
					"destination": [
						"obj-8",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-8",
						0
					],
					"destination": [
						"obj-9",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-9",
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
						0
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
						0
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
						"obj-16",
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
						"obj-2",
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
						"obj-6",
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
						"obj-6",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-211",
						0
					],
					"destination": [
						"obj-6",
						1
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
						"obj-7",
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
						"obj-7",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-211",
						0
					],
					"destination": [
						"obj-7",
						1
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
						"obj-8",
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
						"obj-8",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-211",
						0
					],
					"destination": [
						"obj-8",
						1
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
						"obj-9",
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
						"obj-9",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-211",
						0
					],
					"destination": [
						"obj-9",
						1
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
						"obj-10",
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
						"obj-10",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-211",
						0
					],
					"destination": [
						"obj-10",
						1
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
						"obj-11",
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
						"obj-11",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-211",
						0
					],
					"destination": [
						"obj-11",
						1
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
						"obj-12",
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
						"obj-12",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-211",
						0
					],
					"destination": [
						"obj-12",
						1
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
						"obj-13",
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
						"obj-13",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-211",
						0
					],
					"destination": [
						"obj-13",
						1
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
						"obj-14",
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
						"obj-14",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-211",
						0
					],
					"destination": [
						"obj-14",
						1
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
						"obj-15",
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
						"obj-15",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-211",
						0
					],
					"destination": [
						"obj-15",
						1
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
						"obj-16",
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
						"obj-16",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-211",
						0
					],
					"destination": [
						"obj-16",
						1
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
						"obj-17",
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
						"obj-17",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-211",
						0
					],
					"destination": [
						"obj-17",
						1
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
						"obj-205",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-205",
						0
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
						1
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
						"obj-208",
						0
					]
				}
			}
		],
		"parameters": {
			"obj-220": [
				"depth_factor",
				"depth_factor",
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