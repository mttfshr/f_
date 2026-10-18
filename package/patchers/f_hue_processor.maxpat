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
					"comment": "",
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
						56.5,
						204.0,
						367.0,
						22.0
					],
					"text": "route bypass sat_amt lum_shift hue_shift edge_falloff"
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
									"code": "Param hue_center(120.0);   // degrees 0\u2013360\nParam hue_lower(36.0);     // degrees below center, flat top extent\nParam hue_upper(156.0);    // degrees above center, flat top extent (confirmed by Matt 2026-10-15, matching the shipped band's real asserted value)\nParam edge_falloff(10.0);  // degrees, 0 = hard edge\nParam sat_amt(0.0);        // -1.0 = full desaturate, 0 = unchanged, 1.0 = full boost\nParam lum_shift(0.0);      // -1.0 to 1.0, additive to V within band\nParam hue_shift(0.0);      // degrees -180\u2013180\nParam bypass(0.0);\n\nuv = norm;\nsrc = sample(in1, uv);\nrg = src.r; gg = src.g; bg = src.b;\n\n// RGB \u2192 HSV\ncmax = max(rg, max(gg, bg));\ncmin = min(rg, min(gg, bg));\ndelta = cmax - cmin;\nsafe_delta = max(delta, 0.001);\nsafe_cmax  = max(cmax, 0.001);\n\nhue_r = mod((gg - bg) / safe_delta, 6.0) / 6.0;\nhue_g = ((bg - rg) / safe_delta + 2.0) / 6.0;\nhue_b = ((rg - gg) / safe_delta + 4.0) / 6.0;\n\nr_is_max = step(gg, rg) * step(bg, rg);\ng_is_max = step(bg, gg) * (1.0 - r_is_max);\n\nhue = mix(mix(hue_b, hue_g, g_is_max), hue_r, r_is_max);\nhue = fract(hue + 1.0);\n\nS = delta / safe_cmax;   // true saturation \u2014 0 for neutrals, not clamped\nV = cmax;\n\n// Hue band mask\nhue_c   = hue_center / 360.0;\nlower_n = hue_lower  / 360.0;\nupper_n = hue_upper  / 360.0;\nfall_n  = max(edge_falloff / 360.0, 0.00001);\n\nsigned_dist = mod(hue - hue_c + 0.5, 1.0) - 0.5;\n\nupper_mask = 1.0 - smoothstep(upper_n, upper_n + fall_n, max( signed_dist, 0.0));\nlower_mask = 1.0 - smoothstep(lower_n, lower_n + fall_n, max(-signed_dist, 0.0));\n\n// Saturation gate: suppress mask for near-neutral pixels whose hue is undefined\nsat_gate = smoothstep(0.05, 0.15, S);\n\nhue_mask = upper_mask * lower_mask * sat_gate;\n\n// Blend HSV components with mask before reconstruction (Fix 2)\n// This keeps the interpolation in HSV space, not RGB space\nblended_H = fract(hue + (hue_shift / 360.0) * hue_mask);\nblended_S = clamp(S + sat_amt * hue_mask, 0.0, 1.0);\nblended_V = clamp(V + lum_shift * hue_mask, 0.0, 1.0);\n\n// HSV \u2192 RGB (branch-free)\nh6    = blended_H * 6.0;\nr_hsv = clamp(abs(h6 - 3.0) - 1.0, 0.0, 1.0);\ng_hsv = clamp(2.0 - abs(h6 - 2.0), 0.0, 1.0);\nb_hsv = clamp(2.0 - abs(h6 - 4.0), 0.0, 1.0);\n\nro = blended_V * mix(1.0, r_hsv, blended_S);\ngo = blended_V * mix(1.0, g_hsv, blended_S);\nbo = blended_V * mix(1.0, b_hsv, blended_S);\n\neffective = 1.0 - bypass;\n\nout1 = vec(mix(rg, ro, effective),\n           mix(gg, go, effective),\n           mix(bg, bo, effective),\n           src.a);",
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
						380.0,
						200.0,
						22.0
					],
					"text": "jit.gl.pix @name hp_pix @drawto vsynth @type char",
					"varname": "jit.gl.pix_AA"
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
					"varname": "u099020110"
				}
			},
			{
				"box": {
					"id": "obj-9",
					"maxclass": "panel",
					"angle": 270.0,
					"bgcolor": [
						0.058823529411764705,
						0.058823529411764705,
						0.058823529411764705,
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
						150.0,
						120.0
					],
					"presentation": 1,
					"presentation_rect": [
						0.0,
						0.0,
						150.0,
						120.0
					],
					"proportion": 0.5
				}
			},
			{
				"box": {
					"id": "obj-10",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"numinlets": 0,
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
						1.0000000298023224,
						98.8,
						21.0
					],
					"text": "Hue Processor",
					"suppressinlet": 1
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
						6.000000029802322,
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
						13.000000029802322,
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
					"id": "obj-20",
					"maxclass": "live.dial",
					"fontname": "Ableton Sans Light",
					"hint": "Saturation",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "jit.gl.pix_AA::sat_amt",
					"parameter_enable": 1,
					"patching_rect": [
						118.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						42.0,
						69.75,
						27.0,
						43.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "sat_amt",
							"parameter_mmax": 1.0,
							"parameter_mmin": -1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "sat_amt",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "sat_amt"
				}
			},
			{
				"box": {
					"id": "obj-21",
					"maxclass": "attrui",
					"attr": "sat_amt",
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
					"fontsize": 9.0,
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
						44.5,
						56.5,
						25.5,
						17.0
					],
					"text": "Sat",
					"varname": "lbl_sat_amt"
				}
			},
			{
				"box": {
					"id": "obj-23",
					"maxclass": "live.dial",
					"fontname": "Ableton Sans Light",
					"hint": "Luminosity",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "jit.gl.pix_AA::lum_shift",
					"parameter_enable": 1,
					"patching_rect": [
						190.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						79.75,
						70.0,
						27.0,
						43.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "lum_shift",
							"parameter_mmax": 1.0,
							"parameter_mmin": -1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "lum_shift",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "lum_shift"
				}
			},
			{
				"box": {
					"id": "obj-24",
					"maxclass": "attrui",
					"attr": "lum_shift",
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
					"fontsize": 9.0,
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
						81.25,
						56.5,
						27.0,
						17.0
					],
					"text": "Lum",
					"varname": "lbl_lum_shift"
				}
			},
			{
				"box": {
					"id": "obj-26",
					"maxclass": "live.dial",
					"fontname": "Ableton Sans Light",
					"hint": "Hue rotation",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "jit.gl.pix_AA::hue_shift",
					"parameter_enable": 1,
					"patching_rect": [
						262.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						116.25,
						70.0,
						27.0,
						43.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "hue_shift",
							"parameter_mmax": 180.0,
							"parameter_mmin": -180.0,
							"parameter_modmode": 3,
							"parameter_shortname": "hue_shift",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "hue_shift",
					"needlemode": 2
				}
			},
			{
				"box": {
					"id": "obj-27",
					"maxclass": "attrui",
					"attr": "hue_shift",
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
					"id": "obj-29",
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
						128.0,
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
					"id": "obj-30",
					"maxclass": "attrui",
					"attr": "bypass",
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
					"activebgcolor": [
						0.0784313725490196,
						0.0784313725490196,
						0.0784313725490196,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"id": "obj-901",
					"maxclass": "live.numbox",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						452.0,
						546.0,
						46.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						1.0,
						99.25,
						34.0,
						15.0
					],
					"saved_attribute_attributes": {
						"activebgcolor": {
							"expression": ""
						},
						"valueof": {
							"parameter_longname": "live.numbox[2]",
							"parameter_mmax": 360.0,
							"parameter_modmode": 3,
							"parameter_shortname": "live.numbox",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"varname": "live.numbox[2]"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 8.0,
					"id": "obj-902",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						72.0,
						883.0,
						111.0,
						16.0
					],
					"presentation": 1,
					"presentation_rect": [
						89.75,
						43.75,
						15.0,
						16.0
					],
					"text": "hi"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 8.0,
					"id": "obj-903",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						39.0,
						895.0,
						111.0,
						16.0
					],
					"presentation": 1,
					"presentation_rect": [
						42.375,
						43.625,
						22.166666626930237,
						16.0
					],
					"text": "low"
				}
			},
			{
				"box": {
					"id": "obj-904",
					"maxclass": "live.numbox",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "jit.gl.pix_AA::hue_upper",
					"parameter_enable": 1,
					"patching_rect": [
						299.0,
						983.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						103.75,
						44.125,
						44.0,
						15.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								156.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "hue_upper",
							"parameter_mmax": 360.0,
							"parameter_modmode": 3,
							"parameter_shortname": "hue_upper",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"varname": "hue_upper"
				}
			},
			{
				"box": {
					"id": "obj-905",
					"maxclass": "live.numbox",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "jit.gl.pix_AA::hue_lower",
					"parameter_enable": 1,
					"patching_rect": [
						97.0,
						988.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						1.0000000298023224,
						44.000001311302185,
						44.0,
						15.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								84.0
							],
							"parameter_linknames": 1,
							"parameter_longname": "hue_lower",
							"parameter_mmax": 360.0,
							"parameter_modmode": 3,
							"parameter_shortname": "hue_lower",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"varname": "hue_lower"
				}
			},
			{
				"box": {
					"appearance": 1,
					"fontname": "Ableton Sans Light",
					"hint": "Edge falloff",
					"id": "obj-906",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "jit.gl.pix_AA::edge_falloff",
					"parameter_enable": 1,
					"patching_rect": [
						428.0,
						542.0,
						25.0,
						23.0
					],
					"presentation": 1,
					"presentation_rect": [
						5.75,
						75.75,
						25.0,
						23.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "edge_falloff",
							"parameter_mmax": 180.0,
							"parameter_modmode": 3,
							"parameter_shortname": "edge_falloff",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"shownumber": 0,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "falloff"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0,
					"id": "obj-907",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						30.0,
						810.0,
						123.0,
						17.0
					],
					"presentation": 1,
					"presentation_rect": [
						1.75,
						56.75,
						34.0,
						17.0
					],
					"text": "Falloff",
					"varname": "lbl_edge_falloff"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0,
					"id": "obj-908",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						57.0,
						868.0,
						116.0,
						17.0
					],
					"presentation": 1,
					"presentation_rect": [
						118.75,
						56.5,
						25.0,
						17.0
					],
					"text": "Rot"
				}
			},
			{
				"box": {
					"border": 0,
					"filename": "hue_rslider.js",
					"hint": "Hue band selection",
					"id": "obj-909",
					"maxclass": "jsui",
					"numinlets": 3,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"parameter_enable": 0,
					"patching_rect": [
						68.0,
						1017.0,
						434.0,
						41.0
					],
					"presentation": 1,
					"presentation_rect": [
						3.0,
						24.0,
						142.2500004172325,
						19.5
					],
					"valuepopup": 1,
					"valuepopuplabel": 1
				}
			},
			{
				"box": {
					"id": "obj-910",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 3,
					"outlettype": [
						"",
						"",
						""
					],
					"patching_rect": [
						135.0,
						1099.0,
						372.0,
						22.0
					],
					"saved_object_attributes": {
						"filename": "hue_range.js",
						"parameter_enable": 0
					},
					"text": "js hue_range.js"
				}
			},
			{
				"box": {
					"attr": "edge_falloff",
					"id": "obj-911",
					"maxclass": "attrui",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"parameter_enable": 0,
					"patching_rect": [
						438.5,
						585.0,
						155.0,
						22.0
					]
				}
			},
			{
				"box": {
					"attr": "hue_upper",
					"id": "obj-912",
					"maxclass": "attrui",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"parameter_enable": 0,
					"patching_rect": [
						488.0,
						1154.0,
						151.0,
						22.0
					]
				}
			},
			{
				"box": {
					"attr": "hue_lower",
					"id": "obj-913",
					"maxclass": "attrui",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"parameter_enable": 0,
					"patching_rect": [
						304.0,
						1144.0,
						149.0,
						22.0
					]
				}
			},
			{
				"box": {
					"attr": "hue_center",
					"id": "obj-914",
					"maxclass": "attrui",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"parameter_enable": 0,
					"patching_rect": [
						130.5,
						1149.0,
						153.0,
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
						0
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
						"obj-5",
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
						"obj-911",
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
						"obj-904",
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
						"obj-910",
						1
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
						"obj-910",
						2
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-914",
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
						"obj-911",
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
						"obj-909",
						2
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
						"obj-901",
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
						"obj-904",
						0
					],
					"source": [
						"obj-909",
						1
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-910",
						1
					],
					"source": [
						"obj-909",
						1
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
						"obj-909",
						0
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
						4
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
						"obj-901",
						0
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
						"obj-905",
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
				"sat_amt",
				"sat_amt",
				0
			],
			"obj-23": [
				"lum_shift",
				"lum_shift",
				0
			],
			"obj-26": [
				"hue_shift",
				"hue_shift",
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
			"obj-904": [
				"hue_upper",
				"hue_upper",
				0
			],
			"obj-906": [
				"edge_falloff",
				"edge_falloff",
				0
			],
			"obj-901": [
				"live.numbox[2]",
				"live.numbox",
				0
			],
			"obj-905": [
				"hue_lower",
				"hue_lower",
				0
			]
		},
		"autosave": 0
	}
}