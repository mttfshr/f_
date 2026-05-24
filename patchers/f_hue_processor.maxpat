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
			610.0,
			61.0,
			698.0,
			824.0
		],
		"openinpresentation": 1,
		"toolbars_unpinned_last_save": 2,
		"boxes": [
			{
				"box": {
					"id": "obj-24",
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
						513.3333486318588,
						314.00000935792923,
						56.0,
						22.0
					],
					"restore": {
						"bypass": [
							0
						],
						"falloff": [
							0.0
						],
						"hue_lower": [
							1.0
						],
						"hue_shift": [
							0.0
						],
						"hue_upper": [
							166.39370078740143
						],
						"live.numbox[2]": [
							0.0
						],
						"lum_shift": [
							0.0
						],
						"sat_amt": [
							0.0
						]
					},
					"text": "autopattr",
					"varname": "u099020110"
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
					"id": "obj-5",
					"maxclass": "live.numbox",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						158.75,
						366.0,
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
					"id": "obj-22",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						241.0,
						165.5,
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
					"id": "obj-21",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						226.0,
						150.5,
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
					"id": "obj-20",
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
						252.0,
						599.0,
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
					"id": "obj-7",
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
						23.0,
						605.0,
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
					"fontname": "Ableton Sans Light",
					"id": "obj-6",
					"maxclass": "comment",
					"numinlets": 0,
					"numoutlets": 0,
					"patching_rect": [
						169.00000503659248,
						141.3333375453949,
						146.0,
						21.0
					],
					"presentation": 1,
					"presentation_rect": [
						-0.3333333432674408,
						1.0000000298023224,
						88.0,
						21.0
					],
					"suppressinlet": 1,
					"text": "Hue Processor"
				}
			},
			{
				"box": {
					"appearance": 1,
					"fontname": "Ableton Sans Light",
					"hint": "Edge falloff",
					"id": "obj-26",
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
						168.25,
						315.20000475645065,
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
					"id": "obj-4",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						211.0,
						135.5,
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
					"text": "Falloff"
				}
			},
			{
				"box": {
					"filename": "bypass_toggle.js",
					"hint": "Bypass",
					"id": "obj-8",
					"maxclass": "jsui",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"param_connect": "jit.gl.pix_AA::bypass",
					"parameter_enable": 1,
					"patching_rect": [
						79.20000118017197,
						158.40000236034393,
						18.0,
						12.0
					],
					"presentation": 1,
					"presentation_rect": [
						131.25,
						5.0,
						18.0,
						12.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_invisible": 1,
							"parameter_longname": "bypass",
							"parameter_modmode": 4,
							"parameter_shortname": "bypass",
							"parameter_type": 1,
							"parameter_unitstyle": 0
						}
					},
					"valuepopuplabel": 1,
					"varname": "bypass"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"hint": "Saturation",
					"id": "obj-13",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "jit.gl.pix_AA::sat_amt",
					"parameter_enable": 1,
					"patching_rect": [
						226.0,
						132.00000196695328,
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
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0,
					"id": "obj-38",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						226.0,
						150.5,
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
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0,
					"id": "obj-37",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						211.0,
						135.5,
						121.0,
						17.0
					],
					"presentation": 1,
					"presentation_rect": [
						81.25,
						56.5,
						27.0,
						17.0
					],
					"text": "Lum"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0,
					"id": "obj-36",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						196.0,
						120.5,
						117.0,
						17.0
					],
					"presentation": 1,
					"presentation_rect": [
						44.5,
						56.5,
						25.5,
						17.0
					],
					"text": "Sat"
				}
			},
			{
				"box": {
					"border": 0,
					"filename": "hue_rslider.js",
					"hint": "Hue band selection",
					"id": "obj-33",
					"maxclass": "jsui",
					"numinlets": 3,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"parameter_enable": 0,
					"patching_rect": [
						48.00000071525574,
						547.2000081539154,
						212.00000315904617,
						33.600000500679016
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
					"id": "obj-25",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 3,
					"outlettype": [
						"",
						"",
						""
					],
					"patching_rect": [
						106.5,
						643.0,
						90.0,
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
					"id": "obj-19",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						252.00000375509262,
						486.4000072479248,
						155.0,
						22.0
					],
					"text": "prepend param edge_falloff"
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
						334.4000049829483,
						726.4000108242035,
						151.0,
						22.0
					],
					"text": "prepend param hue_upper"
				}
			},
			{
				"box": {
					"id": "obj-10",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						299.20000445842743,
						700.8000104427338,
						149.0,
						22.0
					],
					"text": "prepend param hue_lower"
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
						535.5,
						193.6000028848648,
						142.0,
						22.0
					],
					"text": "prepend param hue_shift"
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
						370.4000055193901,
						196.80000293254852,
						141.0,
						22.0
					],
					"text": "prepend param lum_shift"
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
						226.0,
						193.6000028848648,
						136.0,
						22.0
					],
					"text": "prepend param sat_amt"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"hint": "Hue rotation",
					"id": "obj-15",
					"maxclass": "live.dial",
					"needlemode": 2,
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "jit.gl.pix_AA::hue_shift",
					"parameter_enable": 1,
					"patching_rect": [
						535.5,
						135.00000196695328,
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
					"varname": "hue_shift"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"hint": "Luminosity",
					"id": "obj-14",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "jit.gl.pix_AA::lum_shift",
					"parameter_enable": 1,
					"patching_rect": [
						370.4000055193901,
						137.60000205039978,
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
					"id": "obj-12",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						79.20000118017197,
						193.6000028848648,
						131.0,
						22.0
					],
					"text": "prepend param bypass"
				}
			},
			{
				"box": {
					"id": "obj-9",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						264.00000393390656,
						673.6000100374222,
						153.0,
						22.0
					],
					"text": "prepend param hue_center"
				}
			},
			{
				"box": {
					"comment": "",
					"id": "obj-3",
					"index": 0,
					"maxclass": "outlet",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						450.5,
						459.5,
						30.0,
						30.0
					]
				}
			},
			{
				"box": {
					"id": "obj-39",
					"maxclass": "newobj",
					"numinlets": 6,
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
						332.0,
						370.0,
						295.0,
						22.0
					],
					"text": "route bypass sat_amt lum_shift hue_shift edge_falloff"
				}
			},
			{
				"box": {
					"comment": "",
					"id": "obj-2",
					"index": 0,
					"maxclass": "inlet",
					"numinlets": 0,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						332.0,
						339.0,
						30.0,
						30.0
					]
				}
			},
			{
				"box": {
					"id": "obj-1",
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
							303.0,
							95.0,
							593.0,
							699.0
						],
						"boxes": [
							{
								"box": {
									"code": "Param hue_center(120.0);   // degrees 0\u2013360\nParam hue_lower(36.0);     // degrees below center, flat top extent\nParam hue_upper(36.0);     // degrees above center, flat top extent\nParam edge_falloff(10.0);  // degrees, 0 = hard edge\nParam sat_amt(0.0);        // -1.0 = full desaturate, 0 = unchanged, 1.0 = full boost\nParam lum_shift(0.0);      // -1.0 to 1.0, additive to V within band\nParam hue_shift(0.0);      // degrees -180\u2013180\nParam bypass(0.0);\n\nuv = norm;\nsrc = sample(in1, uv);\nrg = src.r; gg = src.g; bg = src.b;\n\n// RGB \u2192 HSV\ncmax = max(rg, max(gg, bg));\ncmin = min(rg, min(gg, bg));\ndelta = cmax - cmin;\nsafe_delta = max(delta, 0.001);\nsafe_cmax  = max(cmax, 0.001);\n\nhue_r = mod((gg - bg) / safe_delta, 6.0) / 6.0;\nhue_g = ((bg - rg) / safe_delta + 2.0) / 6.0;\nhue_b = ((rg - gg) / safe_delta + 4.0) / 6.0;\n\nr_is_max = step(gg, rg) * step(bg, rg);\ng_is_max = step(bg, gg) * (1.0 - r_is_max);\n\nhue = mix(mix(hue_b, hue_g, g_is_max), hue_r, r_is_max);\nhue = fract(hue + 1.0);\n\nS = delta / safe_cmax;   // true saturation \u2014 0 for neutrals, not clamped\nV = cmax;\n\n// Hue band mask\nhue_c   = hue_center / 360.0;\nlower_n = hue_lower  / 360.0;\nupper_n = hue_upper  / 360.0;\nfall_n  = max(edge_falloff / 360.0, 0.00001);\n\nsigned_dist = mod(hue - hue_c + 0.5, 1.0) - 0.5;\n\nupper_mask = 1.0 - smoothstep(upper_n, upper_n + fall_n, max( signed_dist, 0.0));\nlower_mask = 1.0 - smoothstep(lower_n, lower_n + fall_n, max(-signed_dist, 0.0));\n\n// Saturation gate: suppress mask for near-neutral pixels whose hue is undefined\nsat_gate = smoothstep(0.05, 0.15, S);\n\nhue_mask = upper_mask * lower_mask * sat_gate;\n\n// Blend HSV components with mask before reconstruction (Fix 2)\n// This keeps the interpolation in HSV space, not RGB space\nblended_H = fract(hue + (hue_shift / 360.0) * hue_mask);\nblended_S = clamp(S + sat_amt * hue_mask, 0.0, 1.0);\nblended_V = clamp(V + lum_shift * hue_mask, 0.0, 1.0);\n\n// HSV \u2192 RGB (branch-free)\nh6    = blended_H * 6.0;\nr_hsv = clamp(abs(h6 - 3.0) - 1.0, 0.0, 1.0);\ng_hsv = clamp(2.0 - abs(h6 - 2.0), 0.0, 1.0);\nb_hsv = clamp(2.0 - abs(h6 - 4.0), 0.0, 1.0);\n\nro = blended_V * mix(1.0, r_hsv, blended_S);\ngo = blended_V * mix(1.0, g_hsv, blended_S);\nbo = blended_V * mix(1.0, b_hsv, blended_S);\n\neffective = 1.0 - bypass;\n\nout1 = vec(mix(rg, ro, effective),\n           mix(gg, go, effective),\n           mix(bg, bo, effective),\n           src.a);",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
									"id": "obj-5",
									"maxclass": "codebox",
									"numinlets": 1,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										50.0,
										49.0,
										431.0,
										549.0
									]
								}
							},
							{
								"box": {
									"id": "obj-1",
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
									"id": "obj-4",
									"maxclass": "newobj",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										60.0,
										659.0,
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
										"obj-5",
										0
									],
									"source": [
										"obj-1",
										0
									]
								}
							},
							{
								"patchline": {
									"destination": [
										"obj-4",
										0
									],
									"source": [
										"obj-5",
										0
									]
								}
							}
						]
					},
					"patching_rect": [
						432.0,
						405.0,
						222.0,
						22.0
					],
					"text": "jit.gl.pix @name hp_pix @drawto vsynth",
					"varname": "jit.gl.pix_AA"
				}
			},
			{
				"box": {
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
					"id": "obj-23",
					"maxclass": "panel",
					"mode": 0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						129.0000038444996,
						166.6666716337204,
						128.0,
						128.0
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
					"id": "obj-40",
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
					"id": "obj-41",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						600.0,
						80.0,
						200.0,
						22.0
					],
					"text": "getattr presentation_rect @listen 0"
				}
			},
			{
				"box": {
					"id": "obj-42",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						600.0,
						110.0,
						60.0,
						22.0
					],
					"text": "zl slice 2"
				}
			},
			{
				"box": {
					"id": "obj-43",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						600.0,
						140.0,
						70.0,
						22.0
					],
					"text": "prepend tam"
				}
			},
			{
				"box": {
					"id": "obj-44",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						600.0,
						170.0,
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
					"destination": [
						"obj-3",
						0
					],
					"source": [
						"obj-1",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-1",
						0
					],
					"source": [
						"obj-10",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-1",
						0
					],
					"source": [
						"obj-11",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-1",
						0
					],
					"source": [
						"obj-12",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-16",
						0
					],
					"source": [
						"obj-13",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-17",
						0
					],
					"source": [
						"obj-14",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-18",
						0
					],
					"source": [
						"obj-15",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-1",
						0
					],
					"source": [
						"obj-16",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-1",
						0
					],
					"source": [
						"obj-17",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-1",
						0
					],
					"source": [
						"obj-18",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-1",
						0
					],
					"source": [
						"obj-19",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-39",
						0
					],
					"source": [
						"obj-2",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-33",
						2
					],
					"source": [
						"obj-20",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-9",
						0
					],
					"source": [
						"obj-25",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-19",
						0
					],
					"order": 0,
					"source": [
						"obj-26",
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
					"order": 1,
					"source": [
						"obj-26",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-20",
						0
					],
					"order": 1,
					"source": [
						"obj-33",
						1
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-25",
						0
					],
					"order": 0,
					"source": [
						"obj-33",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-7",
						0
					],
					"order": 1,
					"source": [
						"obj-33",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-9",
						0
					],
					"order": 0,
					"source": [
						"obj-33",
						1
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-1",
						0
					],
					"source": [
						"obj-39",
						5
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-13",
						0
					],
					"source": [
						"obj-39",
						1
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-14",
						0
					],
					"source": [
						"obj-39",
						2
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-15",
						0
					],
					"source": [
						"obj-39",
						3
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-26",
						0
					],
					"source": [
						"obj-39",
						4
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-8",
						0
					],
					"source": [
						"obj-39",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-26",
						0
					],
					"source": [
						"obj-5",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-33",
						0
					],
					"source": [
						"obj-7",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-12",
						0
					],
					"source": [
						"obj-8",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-1",
						0
					],
					"source": [
						"obj-9",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-40",
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
						"obj-43",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-43",
						0
					],
					"destination": [
						"obj-44",
						0
					]
				}
			}
		],
		"parameters": {
			"obj-13": [
				"sat_amt",
				"sat_amt",
				0
			],
			"obj-14": [
				"lum_shift",
				"lum_shift",
				0
			],
			"obj-15": [
				"hue_shift",
				"hue_shift",
				0
			],
			"obj-20": [
				"hue_upper",
				"hue_upper",
				0
			],
			"obj-26": [
				"edge_falloff",
				"edge_falloff",
				0
			],
			"obj-5": [
				"live.numbox[2]",
				"live.numbox",
				0
			],
			"obj-7": [
				"hue_lower",
				"hue_lower",
				0
			],
			"obj-8": [
				"bypass",
				"bypass",
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