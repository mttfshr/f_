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
			475.0,
			112.0,
			908.0,
			937.0
		],
		"openinpresentation": 1,
		"boxes": [
			{
				"box": {
					"filename": "bypass_toggle.js",
					"hint": "Bypass",
					"id": "obj-17",
					"maxclass": "jsui",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"param_connect": "jit.gl.pix_AA::bypass",
					"parameter_enable": 1,
					"patching_rect": [
						133.0,
						219.0,
						18.0,
						12.0
					],
					"presentation": 1,
					"presentation_rect": [
						126.25,
						6.5,
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
					"activebgcolor": [
						0.0,
						0.0,
						0.0,
						0.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Edge falloff",
					"id": "obj-29",
					"maxclass": "live.numbox",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						512.0,
						384.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						4.5,
						103.375,
						30.0,
						15.0
					],
					"saved_attribute_attributes": {
						"activebgcolor": {
							"expression": "themecolor.live_input_curve_outline_color"
						},
						"valueof": {
							"parameter_longname": "live.numbox",
							"parameter_mmax": 1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "live.numbox",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"valuepopuplabel": 1,
					"varname": "live.numbox"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0,
					"id": "obj-28",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						124.10714167356491,
						57.14285659790039,
						114.0,
						17.0
					],
					"presentation": 1,
					"presentation_rect": [
						2.5,
						59.375,
						35.0,
						17.0
					],
					"text": "Falloff"
				}
			},
			{
				"box": {
					"id": "obj-23",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						466.0,
						425.0,
						155.0,
						22.0
					],
					"text": "prepend param edge_falloff"
				}
			},
			{
				"box": {
					"appearance": 1,
					"fontname": "Ableton Sans Light",
					"hint": "Edge falloff",
					"id": "obj-22",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						466.0,
						380.0,
						25.0,
						23.0
					],
					"presentation": 1,
					"presentation_rect": [
						6.5,
						79.375,
						25.0,
						23.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
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
					"varname": "edge_falloff"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 8.0,
					"id": "obj-27",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						168.7499983906746,
						102.67857044935226,
						106.0,
						16.0
					],
					"presentation": 1,
					"presentation_rect": [
						97.66666957736015,
						44.000001311302185,
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
					"id": "obj-26",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						153.5714271068573,
						87.49999916553497,
						106.0,
						16.0
					],
					"presentation": 1,
					"presentation_rect": [
						35.0,
						44.125,
						21.0,
						16.0
					],
					"text": "low"
				}
			},
			{
				"box": {
					"id": "obj-25",
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
						633.0,
						474.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						110.00000190734863,
						44.625,
						34.00000238418579,
						15.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								0.67
							],
							"parameter_initial_enable": 1,
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
					"id": "obj-24",
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
						470.0,
						483.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						3.25,
						44.625,
						34.41666683554649,
						15.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								0.33
							],
							"parameter_initial_enable": 1,
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
					"id": "obj-12",
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
						531.0,
						48.0,
						56.0,
						22.0
					],
					"restore": {
						"bypass": [
							0
						],
						"edge_falloff": [
							0.0
						],
						"highlights": [
							0.0
						],
						"live.numbox": [
							0.0
						],
						"low_mid": [
							0.3490566037735849
						],
						"mid_high": [
							0.7169811320754716
						],
						"midtones": [
							0.0
						],
						"shadows": [
							0.0
						]
					},
					"text": "autopattr",
					"varname": "u288002127"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"id": "obj-21",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						153.5714271068573,
						87.49999916553497,
						153.0,
						21.0
					],
					"presentation": 1,
					"presentation_rect": [
						2.0000000596046448,
						2.6666667461395264,
						94.0,
						21.0
					],
					"text": "Tone Curve"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0,
					"id": "obj-20",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						138.39285582304,
						72.32142788171768,
						114.0,
						17.0
					],
					"presentation": 1,
					"presentation_rect": [
						114.00000339746475,
						59.33333510160446,
						30.0,
						17.0
					],
					"text": "Highs"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0,
					"id": "obj-19",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						124.10714167356491,
						57.14285659790039,
						120.0,
						17.0
					],
					"presentation": 1,
					"presentation_rect": [
						77.6666689813137,
						59.33333510160446,
						28.0,
						17.0
					],
					"text": "Mids"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0,
					"id": "obj-18",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						108.92857038974762,
						41.9642853140831,
						114.0,
						17.0
					],
					"presentation": 1,
					"presentation_rect": [
						40.66666787862778,
						59.33333510160446,
						35.0,
						17.0
					],
					"text": "Shdws"
				}
			},
			{
				"box": {
					"filename": "tone_rslider.js",
					"hint": "Midtone bounds",
					"id": "obj-16",
					"maxclass": "jsui",
					"numinlets": 3,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"parameter_enable": 0,
					"patching_rect": [
						519.0,
						516.0,
						225.0,
						24.0
					],
					"presentation": 1,
					"presentation_rect": [
						21.33333396911621,
						24.000000715255737,
						122.66667032241821,
						20.000000596046448
					],
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "jsui"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"hint": "Highlights",
					"id": "obj-15",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "jit.gl.pix_AA::highlights",
					"parameter_enable": 1,
					"patching_rect": [
						409.57142857142856,
						322.5,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						116.0000034570694,
						73.33333551883698,
						27.0,
						43.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_longname": "highlights",
							"parameter_mmax": 1.0,
							"parameter_mmin": -1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "highlights",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "highlights"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"hint": "Midtones",
					"id": "obj-14",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "jit.gl.pix_AA::midtones",
					"parameter_enable": 1,
					"patching_rect": [
						351.7142857142857,
						260.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						79.00000235438347,
						73.33333551883698,
						27.0,
						43.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_longname": "midtones",
							"parameter_mmax": 1.0,
							"parameter_mmin": -1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "midtones",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "midtones"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"hint": "Shadows",
					"id": "obj-13",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "jit.gl.pix_AA::shadows",
					"parameter_enable": 1,
					"patching_rect": [
						289.0,
						219.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						42.66666793823242,
						73.33333551883698,
						27.0,
						43.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_longname": "shadows",
							"parameter_mmax": 1.0,
							"parameter_mmin": -1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "shadows",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "shadows"
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
						133.0,
						267.0,
						131.0,
						22.0
					],
					"text": "prepend param bypass"
				}
			},
			{
				"box": {
					"id": "obj-8",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						702.0,
						595.0,
						142.0,
						22.0
					],
					"text": "prepend param mid_high"
				}
			},
			{
				"box": {
					"id": "obj-7",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						465.5,
						586.0,
						137.0,
						22.0
					],
					"text": "prepend param low_mid"
				}
			},
			{
				"box": {
					"id": "obj-6",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						446.5,
						337.5,
						144.0,
						22.0
					],
					"text": "prepend param highlights"
				}
			},
			{
				"box": {
					"id": "obj-5",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						385.0,
						274.0,
						142.0,
						22.0
					],
					"text": "prepend param midtones"
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
						322.0,
						229.5,
						141.0,
						22.0
					],
					"text": "prepend param shadows"
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
						153.5714271068573,
						553.0,
						30.0,
						30.0
					]
				}
			},
			{
				"box": {
					"id": "obj-30",
					"maxclass": "newobj",
					"numinlets": 8,
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
						236.0,
						189.0,
						424.0,
						22.0
					],
					"text": "route bypass shadows midtones highlights edge_falloff low_mid mid_high"
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
						259.0,
						141.0,
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
							334.0,
							95.0,
							776.0,
							862.0
						],
						"boxes": [
							{
								"box": {
									"code": "Param shadows(0.0);\nParam midtones(0.0);\nParam highlights(0.0);\nParam low_mid(0.33);\nParam mid_high(0.66);\nParam bypass(0.0);\r\nParam edge_falloff(0.1);\n\nuv = norm;\nsrc = sample(in1, uv);\nr = src.r; g = src.g; b = src.b;\n\n// guard against handle inversion\nlm = min(low_mid, mid_high);\nmh = max(low_mid, mid_high);\n\n// luminance for band weighting\nlum = 0.299 * r + 0.587 * g + 0.114 * b;\n\n// band weights \u2014 sum to 1.0\nsw = 1.0 - smoothstep(lm - edge_falloff, lm + edge_falloff, lum);\nhw = smoothstep(mh - edge_falloff, mh + edge_falloff, lum);\nmw = max(1.0 - sw - hw, 0.0);\n\n// additive lift weighted by band\nlift_amt = shadows * sw + midtones * mw + highlights * hw;\n\nro = clamp(r + lift_amt, 0.0, 1.0);\ngo = clamp(g + lift_amt, 0.0, 1.0);\nbo = clamp(b + lift_amt, 0.0, 1.0);\n\neffective = 1.0 - bypass;\nout1 = vec(mix(r, ro, effective),\n           mix(g, go, effective),\n           mix(b, bo, effective),\n           src.a);",
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
										132.0,
										87.0,
										626.0,
										622.0
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
										132.0,
										754.0,
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
						153.5714271068573,
						501.0,
						250.0,
						22.0
					],
					"text": "jit.gl.pix @name tone_curve @drawto vsynth",
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
					"id": "obj-10",
					"maxclass": "panel",
					"mode": 0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						633.0,
						16.821427881717682,
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
					"id": "obj-31",
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
					"id": "obj-32",
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
					"id": "obj-33",
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
					"id": "obj-34",
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
					"id": "obj-35",
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
						"obj-4",
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
						"obj-5",
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
						"obj-6",
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
						"obj-24",
						0
					],
					"order": 0,
					"source": [
						"obj-16",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-25",
						0
					],
					"order": 1,
					"source": [
						"obj-16",
						1
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
						"obj-16",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-8",
						0
					],
					"order": 0,
					"source": [
						"obj-16",
						1
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
						"obj-17",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-30",
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
						"obj-16",
						2
					],
					"order": 0,
					"source": [
						"obj-22",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-23",
						0
					],
					"order": 1,
					"source": [
						"obj-22",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-29",
						0
					],
					"source": [
						"obj-22",
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
						"obj-23",
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
						"obj-24",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-16",
						1
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
						"obj-22",
						0
					],
					"source": [
						"obj-29",
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
						"obj-30",
						7
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
						"obj-30",
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
						"obj-30",
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
						"obj-30",
						3
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
						"obj-30",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-22",
						0
					],
					"source": [
						"obj-30",
						4
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-24",
						0
					],
					"source": [
						"obj-30",
						5
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-25",
						0
					],
					"source": [
						"obj-30",
						6
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
						"obj-4",
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
						"obj-5",
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
						"obj-6",
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
						"obj-7",
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
						"obj-31",
						0
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
						"obj-34",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-34",
						0
					],
					"destination": [
						"obj-35",
						0
					]
				}
			}
		],
		"parameters": {
			"obj-13": [
				"shadows",
				"shadows",
				0
			],
			"obj-14": [
				"midtones",
				"midtones",
				0
			],
			"obj-15": [
				"highlights",
				"highlights",
				0
			],
			"obj-17": [
				"bypass",
				"bypass",
				0
			],
			"obj-22": [
				"edge_falloff",
				"edge_falloff",
				0
			],
			"obj-24": [
				"low_mid",
				"low_mid",
				0
			],
			"obj-25": [
				"mid_high",
				"mid_high",
				0
			],
			"obj-29": [
				"live.numbox",
				"live.numbox",
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