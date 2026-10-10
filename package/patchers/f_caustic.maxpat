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
						452.0,
						30.0,
						30.0
					]
				}
			},
			{
				"box": {
					"id": "obj-201",
					"maxclass": "outlet",
					"comment": "caustic",
					"index": 0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						100.0,
						452.0,
						30.0,
						30.0
					],
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
					"numoutlets": 4,
					"outlettype": [
						"",
						"",
						"",
						""
					],
					"patching_rect": [
						56.5,
						204.0,
						295.0,
						22.0
					],
					"text": "route mix_pct gain scale expo"
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
									"code": "// f_caustic sheets mode: COMPOSITE stage (spec .specify/f_caustic_scatter/spec.md, \"Composite (sheets)\")\n//\n// in1 = light-source texture. The composite is built over it and this pix FOLLOWS ITS SIZE (@adapt 1, no fixed @dim)\n// in2 = the scatter node's float32 illuminance capture: square, fixed size (the `detail` step), HDR. Read with\n//       sample(in2, norm), which upscales it bilinearly to the output size\n// in3 = f_vecfield, read ONLY by the unconnected-field guard\n//\n// out1 = composite  mix(source, clamp(source + light, 0, 1), mix_pct / 100)\n// out2 = caustic layer, tone mapped and clamped (the same meaning as the soft path's out2)\n//\n// This is now the module's only stage (soft mode and the select stages were removed 2026-10-10), so bypass is\n// handled HERE: bypass_gate mixes both outlets to the source last (\"every outlet mixes to its passthrough\").\n//\n// Skill checklist (skills/jit-gen-codebox; the look-patch tone stage broke on the first two):\n//   - functions are defined BEFORE every statement, and a Param declaration is a statement\n//   - components (.x .y .z) are read INLINE on sample(), never on a stored variable\n//   - no Param is named after a built-in (mix, step, ...); no variable named cell/in/norm/snorm/dim\n//   - Param values are not visible inside a function body: pass them as arguments\n\ntm(v, ex) {\n\tt = v / (1.0 + v);\n\treturn pow(t, ex);\n}\n\nParam gain(0.5);\nParam mix_pct(0.0);\nParam expo(0.7);\nParam bypass_gate(0.0);\n\n// `gain` keeps its meaning from the soft-mode era; the sheets branch applies this constant (calibrated against the\n// old soft layer in task T034; 2.0 made the default gain 0.5 equal the look-patch's lev = 1).\nk_sheets = 2.0;\n// expo: the tone curve's exponent -- was a fixed internal constant (0.7, the look-patch default, spec Decisions\n// item 3) until 2026-10-10, now a user Param (lower = highlights compress harder, higher = more contrast).\n\nuv = norm;\n\n// Unconnected-vecfield guard (spec Decisions item 6; probe T008: an unconnected pix inlet reads a constant\n// (0, 0, 0, 1), black WITH alpha 1, so the test must use R and G only). Real vecfields encode zero as 0.5, so a\n// texture that is exactly 0 in R and G at four fixed points is \"no field\": zero the light, keep the source.\nfsum = sample(in3, vec(0.25, 0.25)).x + sample(in3, vec(0.25, 0.25)).y\n     + sample(in3, vec(0.75, 0.25)).x + sample(in3, vec(0.75, 0.25)).y\n     + sample(in3, vec(0.25, 0.75)).x + sample(in3, vec(0.25, 0.75)).y\n     + sample(in3, vec(0.75, 0.75)).x + sample(in3, vec(0.75, 0.75)).y;\npresent = fsum > 0.0;\n\ncaustic_r = tm(sample(in2, uv).x * gain * k_sheets, expo) * present;\ncaustic_g = tm(sample(in2, uv).y * gain * k_sheets, expo) * present;\ncaustic_b = tm(sample(in2, uv).z * gain * k_sheets, expo) * present;\n\ncaustic_out = vec(clamp(caustic_r, 0.0, 1.0),\n                  clamp(caustic_g, 0.0, 1.0),\n                  clamp(caustic_b, 0.0, 1.0),\n                  1.0);\n\nsrc_r = sample(in1, uv).x;\nsrc_g = sample(in1, uv).y;\nsrc_b = sample(in1, uv).z;\n\ncomposite = vec(clamp(src_r + caustic_r, 0.0, 1.0),\n                clamp(src_g + caustic_g, 0.0, 1.0),\n                clamp(src_b + caustic_b, 0.0, 1.0),\n                1.0);\n\nsource_pass = vec(src_r, src_g, src_b, 1.0);\n\nwet = mix(source_pass, composite, mix_pct / 100.0);\nout1 = mix(wet, source_pass, bypass_gate);\nout2 = mix(caustic_out, source_pass, bypass_gate);\n",
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
						30.0,
						380.0,
						216.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_caustic_sheets @type float32 @adapt 1",
					"varname": "#0_caustic_sheets"
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
					"varname": "caustic_autopattr"
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
						227.0,
						122.0
					],
					"presentation": 1,
					"presentation_rect": [
						0.0,
						0.0,
						227.0,
						122.0
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
						-1.5,
						0.0,
						80.0,
						21.0
					],
					"text": "Caustic"
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
						1070.0,
						200.0,
						60.0,
						21.0
					],
					"presentation": 1,
					"presentation_rect": [
						48.4,
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
					"id": "obj-20",
					"maxclass": "live.numbox",
					"fontname": "Ableton Sans Light",
					"hint": "Dry/wet crossfade toward the fully-composited (source+caustic) state. Renamed from strength 2026-07-12, range capped to true 0-100% (dropping the old 0-1.5 extrapolation zone). Internal Param named mix_pct to avoid colliding with the codebox's mix() operator.",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_caustic_sheets::mix_pct",
					"parameter_enable": 1,
					"patching_rect": [
						38.0,
						250.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						4.0,
						38.0,
						34.0,
						15.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								0.0
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
					"id": "obj-21",
					"maxclass": "attrui",
					"attr": "mix_pct",
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
					"text": "Mix",
					"textjustification": 1,
					"varname": "lbl_mix_pct"
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
					"hint": "Caustic brightness scale. Renamed from intensity 2026-07-12 to match the library-wide gain/mix naming convention. The scatter applies an internal constant (k_sheets) so this reads comparably to the old soft-mode gain. Range menu added 2026-10-08 (Matt).",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_caustic_sheets::gain",
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
					"text": "Gain",
					"textjustification": 1,
					"varname": "lbl_gain"
				}
			},
			{
				"box": {
					"id": "obj-310",
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
						532.0,
						100.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						63.5,
						21.5,
						16.0,
						15.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_enum": [
								"0.1",
								"1.0",
								"2.0"
							],
							"parameter_longname": "range_gain",
							"parameter_shortname": "range_gain",
							"parameter_type": 2
						}
					}
				}
			},
			{
				"box": {
					"id": "obj-311",
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
						567.0,
						60.0,
						22.0
					],
					"text": "sel 0 1 2"
				}
			},
			{
				"box": {
					"id": "obj-312",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						30.0,
						602.0,
						134.0,
						22.0
					],
					"text": "_parameter_range 0. 0.1"
				}
			},
			{
				"box": {
					"id": "obj-313",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						30.0,
						632.0,
						134.0,
						22.0
					],
					"text": "_parameter_range 0. 1."
				}
			},
			{
				"box": {
					"id": "obj-314",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						30.0,
						662.0,
						134.0,
						22.0
					],
					"text": "_parameter_range 0. 2."
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
					"hint": "The propagation distance of the scatter, in UV per unit field -- sheets fold over at larger values. Range menu added 2026-10-08 (Matt): default tier is the original 0-1, second tier opens 0-2.5; above 1.0 is less tested than the default range.",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_caustic_sheets::scale",
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
							"parameter_longname": "scale",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "scale",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "scale"
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
					"text": "Scale",
					"textjustification": 1,
					"varname": "lbl_scale"
				}
			},
			{
				"box": {
					"id": "obj-320",
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
						180.0,
						532.0,
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
								"1.0",
								"2.5"
							],
							"parameter_longname": "range_scale",
							"parameter_shortname": "range_scale",
							"parameter_type": 2
						}
					}
				}
			},
			{
				"box": {
					"id": "obj-321",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						180.0,
						567.0,
						60.0,
						22.0
					],
					"text": "sel 0 1"
				}
			},
			{
				"box": {
					"id": "obj-322",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						180.0,
						602.0,
						134.0,
						22.0
					],
					"text": "_parameter_range 0. 1."
				}
			},
			{
				"box": {
					"id": "obj-323",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						180.0,
						632.0,
						134.0,
						22.0
					],
					"text": "_parameter_range 0. 2.5"
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
					"hint": "Tone-curve exponent for the caustic layer's exposure curve, (v/(1+v))^expo -- lower compresses highlights harder, higher keeps more contrast. Was a fixed internal constant (0.7, the look-patch default) until 2026-10-10, now exposed.",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_caustic_sheets::expo",
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
								0.7
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "expo",
							"parameter_mmax": 1.5,
							"parameter_mmin": 0.3,
							"parameter_modmode": 3,
							"parameter_shortname": "expo",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "expo"
				}
			},
			{
				"box": {
					"id": "obj-30",
					"maxclass": "attrui",
					"attr": "expo",
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
					"text": "Expo",
					"textjustification": 1,
					"varname": "lbl_expo"
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
					"id": "obj-920",
					"maxclass": "newobj",
					"text": "route scale weight r n",
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
						30.0,
						784.0,
						300.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-901",
					"maxclass": "newobj",
					"text": "jit.gl.slab vsynth @inputs 1 @rectangle 0 @type float32",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"jit_gl_texture",
						""
					],
					"patching_rect": [
						30.0,
						844.0,
						330.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-902",
					"maxclass": "newobj",
					"text": "jit.gl.slab vsynth @inputs 1 @rectangle 0 @type float32",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"jit_gl_texture",
						""
					],
					"patching_rect": [
						410.0,
						844.0,
						330.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-903",
					"maxclass": "newobj",
					"text": "route out_name",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						30.0,
						884.0,
						100.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-904",
					"maxclass": "newobj",
					"text": "route out_name",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						410.0,
						884.0,
						100.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-905",
					"maxclass": "newobj",
					"text": "join",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						30.0,
						924.0,
						60.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-906",
					"maxclass": "newobj",
					"text": "prepend texture",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						30.0,
						964.0,
						110.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-907",
					"maxclass": "newobj",
					"text": "r draw",
					"numinlets": 0,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						190.0,
						814.0,
						50.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-908",
					"maxclass": "message",
					"text": "getout_name",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						190.0,
						844.0,
						90.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-909",
					"maxclass": "newobj",
					"text": "jit.gl.node vsynth @capture 1 @name #0.node @type float32 @adapt 0 @dim 1024 1024 @erase_color 0 0 0 0",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"jit_gl_texture",
						"",
						""
					],
					"patching_rect": [
						410.0,
						1024.0,
						400.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-910",
					"maxclass": "newobj",
					"text": "jit.gl.shader vsynth @name #0.sc @file f_caustic_sheets.jxs",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						30.0,
						1024.0,
						330.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-911",
					"maxclass": "newobj",
					"text": "jit.gl.gridshape vsynth @shape plane @dim 2 2 @matrixoutput 1 @automatic 0",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"jit_matrix",
						""
					],
					"patching_rect": [
						30.0,
						1124.0,
						400.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-912",
					"maxclass": "newobj",
					"text": "jit.gl.mesh #0.node @draw_mode points @shader #0.sc @blend_enable 1 @blend_mode 1 1 @depth_enable 0 @point_size 2 @color 1 1 1 1 @lighting_enable 0",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						30.0,
						1164.0,
						600.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-921",
					"maxclass": "newobj",
					"text": "prepend param scale",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						30.0,
						1074.0,
						130.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-922",
					"maxclass": "newobj",
					"text": "prepend param weight",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						170.0,
						1074.0,
						140.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-923",
					"maxclass": "newobj",
					"text": "prepend param res",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						320.0,
						1074.0,
						120.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-924",
					"maxclass": "message",
					"text": "dim $1 $1",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						450.0,
						1074.0,
						70.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-925",
					"maxclass": "message",
					"text": "dim $1 $1, bang",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						530.0,
						1074.0,
						110.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-935",
					"maxclass": "newobj",
					"text": "loadbang",
					"numinlets": 0,
					"numoutlets": 1,
					"outlettype": [
						"bang"
					],
					"patching_rect": [
						650.0,
						784.0,
						70.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-936",
					"maxclass": "message",
					"text": "r 1024, weight 0.2500, n 2048",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						650.0,
						824.0,
						330.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-947",
					"maxclass": "newobj",
					"text": "prepend scale",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						30.0,
						744.0,
						100.0,
						22.0
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
						"obj-5",
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
						"obj-901",
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
						"obj-5",
						2
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
						"obj-902",
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
						"obj-310",
						0
					],
					"destination": [
						"obj-311",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-311",
						0
					],
					"destination": [
						"obj-312",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-312",
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
						"obj-311",
						1
					],
					"destination": [
						"obj-313",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-313",
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
						"obj-311",
						2
					],
					"destination": [
						"obj-314",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-314",
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
						"obj-320",
						0
					],
					"destination": [
						"obj-321",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-321",
						0
					],
					"destination": [
						"obj-322",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-322",
						0
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
						"obj-321",
						1
					],
					"destination": [
						"obj-323",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-323",
						0
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
						"obj-901",
						1
					],
					"destination": [
						"obj-903",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-902",
						1
					],
					"destination": [
						"obj-904",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-903",
						0
					],
					"destination": [
						"obj-905",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-904",
						0
					],
					"destination": [
						"obj-905",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-905",
						0
					],
					"destination": [
						"obj-906",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-907",
						0
					],
					"destination": [
						"obj-908",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-908",
						0
					],
					"destination": [
						"obj-901",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-908",
						0
					],
					"destination": [
						"obj-902",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-911",
						0
					],
					"destination": [
						"obj-912",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-906",
						0
					],
					"destination": [
						"obj-912",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-920",
						0
					],
					"destination": [
						"obj-921",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-920",
						1
					],
					"destination": [
						"obj-922",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-920",
						2
					],
					"destination": [
						"obj-923",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-920",
						2
					],
					"destination": [
						"obj-924",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-920",
						3
					],
					"destination": [
						"obj-925",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-921",
						0
					],
					"destination": [
						"obj-910",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-922",
						0
					],
					"destination": [
						"obj-910",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-923",
						0
					],
					"destination": [
						"obj-910",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-924",
						0
					],
					"destination": [
						"obj-909",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-925",
						0
					],
					"destination": [
						"obj-911",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-935",
						0
					],
					"destination": [
						"obj-936",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-936",
						0
					],
					"destination": [
						"obj-920",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-909",
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
						"obj-26",
						0
					],
					"destination": [
						"obj-947",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-947",
						0
					],
					"destination": [
						"obj-920",
						0
					]
				}
			}
		],
		"parameters": {
			"obj-20": [
				"mix_pct",
				"mix_pct",
				0
			],
			"obj-23": [
				"gain",
				"gain",
				0
			],
			"obj-26": [
				"scale",
				"scale",
				0
			],
			"obj-29": [
				"expo",
				"expo",
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