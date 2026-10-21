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
					"comment": "texture",
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
						511.0,
						22.0
					],
					"text": "route bypass sat_amt lum_shift hue_shift edge_falloff low_mid mid_high"
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
									"code": "Param low_mid(0.33);\nParam mid_high(0.66);\nParam edge_falloff(0.1);\nParam sat_amt(0.0);\nParam lum_shift(0.0);\nParam hue_shift(0.0);\nParam bypass(0.0);\n\nuv = norm;\nsrc = sample(in1, uv);\nr = src.r; g = src.g; b = src.b;\n\n// RGB -> HSV\ncmax = max(max(r, g), b);\ncmin = min(min(r, g), b);\ndelta = cmax - cmin;\n\n// hue\nhue = 0.0;\ns1 = step(0.00001, delta);\nhr = (g - b) / max(delta, 0.00001);\nhg = 2.0 + (b - r) / max(delta, 0.00001);\nhb = 4.0 + (r - g) / max(delta, 0.00001);\nhue = step(cmax, r + 0.00001) * hr\n    + (1.0 - step(cmax, r + 0.00001)) * step(cmax, g + 0.00001) * hg\n    + (1.0 - step(cmax, r + 0.00001)) * (1.0 - step(cmax, g + 0.00001)) * hb;\nhue = (hue / 6.0 + 1.0) - floor(hue / 6.0 + 1.0);\n\n// sat, val\nsat = s1 * delta / max(cmax, 0.00001);\nval = cmax;\n\n// luma for mask (pre-op, on raw pixel)\nlum = 0.299 * r + 0.587 * g + 0.114 * b;\n\n// flat-top luma mask \u2014 same smoothstep pattern as tone_curve\nlm = min(low_mid, mid_high);\nmh = max(low_mid, mid_high);\nef = edge_falloff;\nmask = smoothstep(lm - ef, lm + ef, lum) * (1.0 - smoothstep(mh - ef, mh + ef, lum));\n\n// HSV operations\nsat_out = clamp(sat + sat_amt * mask, 0.0, 1.0);\nval_out = clamp(val + lum_shift * mask, 0.0, 1.0);\nhue_out = hue + (hue_shift / 360.0) * mask;\nhue_out = hue_out - floor(hue_out);\n\n// HSV -> RGB (branch-free)\nh6 = hue_out * 6.0;\nkr = abs(h6 - 3.0) - 1.0;\nkg = 2.0 - abs(h6 - 2.0);\nkb = 2.0 - abs(h6 - 4.0);\nro = val_out * mix(1.0, clamp(kr, 0.0, 1.0), sat_out);\ngo = val_out * mix(1.0, clamp(kg, 0.0, 1.0), sat_out);\nbo = val_out * mix(1.0, clamp(kb, 0.0, 1.0), sat_out);\n\neffective = 1.0 - bypass;\nout1 = vec(mix(r, ro, effective),\n           mix(g, go, effective),\n           mix(b, bo, effective),\n           src.a);",
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
					"text": "jit.gl.pix @name luma_pix @drawto vsynth @type char",
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
						107.8,
						21.0
					],
					"text": "Luma Processor",
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
						43.00000128149986,
						69.66666874289513,
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
						44.66666799783707,
						56.666668355464935,
						27.0,
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
						80.66666907072067,
						70.00000208616257,
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
						82.33333578705788,
						56.666668355464935,
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
						116.33333680033684,
						70.00000208616257,
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
						129.0,
						4.0,
						18.0,
						12.0
					],
					"valuepopuplabel": 1,
					"varname": "bypass",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_invisible": 1,
							"parameter_longname": "bypass",
							"parameter_modmode": 4,
							"parameter_shortname": "bypass",
							"parameter_type": 1,
							"parameter_unitstyle": 0
						}
					}
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
						166.0,
						772.5,
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
							"parameter_mmax": 1.0,
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
						248.0,
						572.0,
						111.0,
						16.0
					],
					"presentation": 1,
					"presentation_rect": [
						89.66666933894157,
						43.666667968034744,
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
						233.0,
						557.0,
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
					"param_connect": "jit.gl.pix_AA::mid_high",
					"parameter_enable": 1,
					"patching_rect": [
						259.0,
						1005.5,
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
								0.66
							],
							"parameter_linknames": 1,
							"parameter_longname": "mid_high",
							"parameter_mmax": 1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "mid_high",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"varname": "mid_high"
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
					"param_connect": "jit.gl.pix_AA::low_mid",
					"parameter_enable": 1,
					"patching_rect": [
						30.0,
						1011.5,
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
								0.3299999999999983
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "low_mid",
							"parameter_mmax": 1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "low_mid",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"varname": "low_mid"
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
						175.0,
						721.5,
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
							"parameter_mmax": 1.0,
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
						218.0,
						542.0,
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
						233.0,
						557.0,
						116.0,
						17.0
					],
					"presentation": 1,
					"presentation_rect": [
						118.66667020320892,
						56.666668355464935,
						25.0,
						17.0
					],
					"text": "Rot"
				}
			},
			{
				"box": {
					"border": 0,
					"filename": "luma_rslider.js",
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
						55.0,
						953.5,
						212.00000315904617,
						33.600000500679016
					],
					"presentation": 1,
					"presentation_rect": [
						3.000000089406967,
						24.000000715255737,
						142.33333757519722,
						19.333333909511566
					],
					"valuepopup": 1,
					"valuepopuplabel": 1
				}
			},
			{
				"box": {
					"id": "obj-910",
					"maxclass": "attrui",
					"attr": "edge_falloff",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						259.0,
						893.0,
						155.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-911",
					"maxclass": "attrui",
					"attr": "mid_high",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						256.5,
						1095.0,
						142.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-912",
					"maxclass": "attrui",
					"attr": "low_mid",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						91.5,
						1080.0,
						137.0,
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
						"obj-4",
						7
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
						"obj-5",
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
						2
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
						"obj-910",
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
						"obj-912",
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
						"obj-911",
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
						"obj-904",
						0
					],
					"source": [
						"obj-4",
						6
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
						"obj-905",
						0
					],
					"source": [
						"obj-4",
						5
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
				"mid_high",
				"mid_high",
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
				"low_mid",
				"low_mid",
				0
			]
		},
		"autosave": 0
	}
}