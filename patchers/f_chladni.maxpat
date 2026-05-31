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
			497.0,
			169.0,
			1197.0,
			831.0
		],
		"openinpresentation": 1,
		"boxes": [
			{
				"box": {
					"id": "obj-69",
					"maxclass": "newobj",
					"numinlets": 3,
					"numoutlets": 3,
					"outlettype": [
						"",
						"",
						""
					],
					"patching_rect": [
						11.0,
						83.0,
						215.0,
						22.0
					],
					"text": "routepass jit_gl_texture jit_matrix"
				}
			},
			{
				"box": {
					"id": "obj-15",
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
						986.0,
						665.0,
						56.0,
						22.0
					],
					"restore": {
						"bypass[1]": [
							0
						],
						"dishradius": [
							1.0
						],
						"globalscale": [
							1.0
						],
						"linesharpness": [
							10.0
						],
						"m0amp": [
							0.0
						],
						"m1amp": [
							0.0
						],
						"m2amp": [
							0.0
						],
						"m3amp": [
							0.0
						],
						"m4amp": [
							0.0
						],
						"m5amp": [
							0.0
						],
						"m6amp": [
							0.0
						],
						"m7amp": [
							0.0
						],
						"ph0": [
							0.0
						],
						"ph1": [
							0.0
						],
						"ph2": [
							0.0
						],
						"ph3": [
							0.0
						],
						"ph4": [
							0.0
						],
						"ph5": [
							0.0
						],
						"ph6": [
							0.0
						],
						"ph7": [
							0.0
						],
						"reflectamt": [
							0.0
						],
						"view_mode": [
							0.0
						],
						"z0": [
							2.4048
						],
						"z1": [
							3.8317
						],
						"z2": [
							5.1356
						],
						"z3": [
							6.3802
						],
						"z4": [
							7.5883
						],
						"z5": [
							8.7715
						],
						"z6": [
							9.9361
						],
						"z7": [
							11.0864
						]
					},
					"text": "autopattr",
					"varname": "u897000911"
				}
			},
			{
				"box": {
					"id": "obj-7",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						303.0,
						162.5,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						189.0,
						25.0,
						27.0,
						43.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "m5amp",
							"parameter_mmax": 1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "m5amp",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"varname": "m5amp"
				}
			},
			{
				"box": {
					"filename": "bypass_toggle.js",
					"hint": "Bypass",
					"id": "obj-1",
					"maxclass": "jsui",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"param_connect": "cyma_pix::bypass",
					"parameter_enable": 1,
					"patching_rect": [
						7.0,
						155.0,
						18.0,
						12.0
					],
					"presentation": 1,
					"presentation_rect": [
						271.0,
						4.0,
						18.0,
						12.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								0
							],
							"parameter_initial_enable": 1,
							"parameter_invisible": 1,
							"parameter_longname": "bypass",
							"parameter_modmode": 4,
							"parameter_shortname": "bypass",
							"parameter_type": 1,
							"parameter_unitstyle": 0
						}
					},
					"valuepopuplabel": 1,
					"varname": "bypass[1]"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"id": "obj-2",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						20.0,
						11.0,
						100.0,
						21.0
					],
					"presentation": 1,
					"presentation_rect": [
						-1.5,
						0.0,
						100.0,
						21.0
					],
					"text": "Chladni"
				}
			},
			{
				"box": {
					"comment": "control",
					"id": "obj-5",
					"index": 0,
					"maxclass": "inlet",
					"numinlets": 0,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						14.0,
						37.0,
						30.0,
						30.0
					]
				}
			},
			{
				"box": {
					"comment": "texture out",
					"id": "obj-6",
					"index": 0,
					"maxclass": "outlet",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						657.7666666666667,
						622.0,
						30.0,
						30.0
					]
				}
			},
			{
				"box": {
					"id": "obj-8",
					"maxclass": "newobj",
					"numinlets": 31,
					"numoutlets": 31,
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
						"",
						"",
						"",
						"",
						"",
						"",
						""
					],
					"patching_rect": [
						11.0,
						122.0,
						1530.0,
						22.0
					],
					"text": "route bypass m0amp m1amp m2amp m3amp m4amp m5amp m6amp m7amp z0 z1 z2 z3 z4 z5 z6 z7 ph0 ph1 ph2 ph3 ph4 ph5 ph6 ph7 dishradius reflectamt linesharpness globalscale view_mode"
				}
			},
			{
				"box": {
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Delta / m0 amplitude",
					"id": "obj-10",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "cyma_pix::m0amp",
					"parameter_enable": 1,
					"patching_rect": [
						57.366666666666674,
						149.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						4.0,
						22.0,
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
							"parameter_longname": "m0amp",
							"parameter_mmax": 1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "m0amp",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "m0amp"
				}
			},
			{
				"box": {
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Theta / m1 amplitude",
					"id": "obj-11",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "cyma_pix::m1amp",
					"parameter_enable": 1,
					"patching_rect": [
						100.0,
						149.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						41.0,
						22.0,
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
							"parameter_longname": "m1amp",
							"parameter_mmax": 1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "m1amp",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "m1amp"
				}
			},
			{
				"box": {
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Alpha / m2 amplitude",
					"id": "obj-12",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "cyma_pix::m2amp",
					"parameter_enable": 1,
					"patching_rect": [
						151.0,
						149.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						78.0,
						22.0,
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
							"parameter_longname": "m2amp",
							"parameter_mmax": 1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "m2amp",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "m2amp"
				}
			},
			{
				"box": {
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Beta-lo / m3 amplitude",
					"id": "obj-13",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "cyma_pix::m3amp",
					"parameter_enable": 1,
					"patching_rect": [
						208.46666666666667,
						155.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						115.0,
						22.0,
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
							"parameter_longname": "m3amp",
							"parameter_mmax": 1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "m3amp",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "m3amp"
				}
			},
			{
				"box": {
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Beta-hi / m4 amplitude",
					"id": "obj-14",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "cyma_pix::m4amp",
					"parameter_enable": 1,
					"patching_rect": [
						258.83333333333337,
						155.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						152.0,
						22.0,
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
							"parameter_longname": "m4amp",
							"parameter_mmax": 1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "m4amp",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "m4amp"
				}
			},
			{
				"box": {
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Gamma-hi / m6 amplitude",
					"id": "obj-16",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "cyma_pix::m6amp",
					"parameter_enable": 1,
					"patching_rect": [
						353.0,
						149.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						226.0,
						22.0,
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
							"parameter_longname": "m6amp",
							"parameter_mmax": 1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "m6amp",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "m6amp"
				}
			},
			{
				"box": {
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Spare / m7 amplitude",
					"id": "obj-17",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "cyma_pix::m7amp",
					"parameter_enable": 1,
					"patching_rect": [
						409.93333333333334,
						149.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						263.0,
						22.0,
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
							"parameter_longname": "m7amp",
							"parameter_mmax": 1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "m7amp",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "m7amp"
				}
			},
			{
				"box": {
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Bessel zero m0 (J0 first zero)",
					"id": "obj-18",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "cyma_pix::z0",
					"parameter_enable": 1,
					"patching_rect": [
						460.3,
						149.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						4.0,
						72.0,
						27.0,
						43.0
					],
					"saved_attribute_attributes": {
						"activedialcolor": {
							"expression": ""
						},
						"valueof": {
							"parameter_initial": [
								2.4048
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "z0",
							"parameter_mmax": 15.0,
							"parameter_mmin": 0.5,
							"parameter_modmode": 3,
							"parameter_shortname": "z0",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "z0"
				}
			},
			{
				"box": {
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Bessel zero m1 (J1 first zero)",
					"id": "obj-19",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "cyma_pix::z1",
					"parameter_enable": 1,
					"patching_rect": [
						510.66666666666674,
						149.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						41.0,
						72.0,
						27.0,
						43.0
					],
					"saved_attribute_attributes": {
						"activedialcolor": {
							"expression": ""
						},
						"valueof": {
							"parameter_initial": [
								3.8317
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "z1",
							"parameter_mmax": 15.0,
							"parameter_mmin": 0.5,
							"parameter_modmode": 3,
							"parameter_shortname": "z1",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "z1"
				}
			},
			{
				"box": {
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Bessel zero m2 (J2 first zero)",
					"id": "obj-20",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "cyma_pix::z2",
					"parameter_enable": 1,
					"patching_rect": [
						561.0333333333333,
						149.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						78.0,
						72.0,
						27.0,
						43.0
					],
					"saved_attribute_attributes": {
						"activedialcolor": {
							"expression": ""
						},
						"valueof": {
							"parameter_initial": [
								5.1356
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "z2",
							"parameter_mmax": 15.0,
							"parameter_mmin": 0.5,
							"parameter_modmode": 3,
							"parameter_shortname": "z2",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "z2"
				}
			},
			{
				"box": {
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Bessel zero m3 (J3 first zero)",
					"id": "obj-21",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "cyma_pix::z3",
					"parameter_enable": 1,
					"patching_rect": [
						611.4,
						159.5,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						115.0,
						72.0,
						27.0,
						43.0
					],
					"saved_attribute_attributes": {
						"activedialcolor": {
							"expression": ""
						},
						"valueof": {
							"parameter_initial": [
								6.3802
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "z3",
							"parameter_mmax": 15.0,
							"parameter_mmin": 0.5,
							"parameter_modmode": 3,
							"parameter_shortname": "z3",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "z3"
				}
			},
			{
				"box": {
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Bessel zero m4 (J4 first zero)",
					"id": "obj-22",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "cyma_pix::z4",
					"parameter_enable": 1,
					"patching_rect": [
						661.7666666666667,
						155.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						152.0,
						72.0,
						27.0,
						43.0
					],
					"saved_attribute_attributes": {
						"activedialcolor": {
							"expression": ""
						},
						"valueof": {
							"parameter_initial": [
								7.5883
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "z4",
							"parameter_mmax": 15.0,
							"parameter_mmin": 0.5,
							"parameter_modmode": 3,
							"parameter_shortname": "z4",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "z4"
				}
			},
			{
				"box": {
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Bessel zero m5 (J5 first zero)",
					"id": "obj-23",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "cyma_pix::z5",
					"parameter_enable": 1,
					"patching_rect": [
						707.0,
						155.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						189.0,
						72.0,
						27.0,
						43.0
					],
					"saved_attribute_attributes": {
						"activedialcolor": {
							"expression": ""
						},
						"valueof": {
							"parameter_initial": [
								8.7715
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "z5",
							"parameter_mmax": 15.0,
							"parameter_mmin": 0.5,
							"parameter_modmode": 3,
							"parameter_shortname": "z5",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "z5"
				}
			},
			{
				"box": {
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Bessel zero m6 (J6 first zero)",
					"id": "obj-24",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "cyma_pix::z6",
					"parameter_enable": 1,
					"patching_rect": [
						762.5,
						155.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						226.0,
						72.0,
						27.0,
						43.0
					],
					"saved_attribute_attributes": {
						"activedialcolor": {
							"expression": ""
						},
						"valueof": {
							"parameter_initial": [
								9.9361
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "z6",
							"parameter_mmax": 15.0,
							"parameter_mmin": 0.5,
							"parameter_modmode": 3,
							"parameter_shortname": "z6",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "z6"
				}
			},
			{
				"box": {
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Bessel zero m7 (J7 first zero)",
					"id": "obj-25",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "cyma_pix::z7",
					"parameter_enable": 1,
					"patching_rect": [
						809.0,
						155.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						263.0,
						72.0,
						27.0,
						43.0
					],
					"saved_attribute_attributes": {
						"activedialcolor": {
							"expression": ""
						},
						"valueof": {
							"parameter_initial": [
								11.0864
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "z7",
							"parameter_mmax": 15.0,
							"parameter_mmin": 0.5,
							"parameter_modmode": 3,
							"parameter_shortname": "z7",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "z7"
				}
			},
			{
				"box": {
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Phase m0",
					"id": "obj-26",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "cyma_pix::ph0",
					"parameter_enable": 1,
					"patching_rect": [
						859.0,
						149.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						4.0,
						122.0,
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
							"parameter_longname": "ph0",
							"parameter_mmax": 6.2832,
							"parameter_mmin": -6.2832,
							"parameter_modmode": 3,
							"parameter_shortname": "ph0",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "ph0"
				}
			},
			{
				"box": {
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Phase m1",
					"id": "obj-27",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "cyma_pix::ph1",
					"parameter_enable": 1,
					"patching_rect": [
						913.6,
						163.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						41.0,
						122.0,
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
							"parameter_longname": "ph1",
							"parameter_mmax": 6.2832,
							"parameter_mmin": -6.2832,
							"parameter_modmode": 3,
							"parameter_shortname": "ph1",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "ph1"
				}
			},
			{
				"box": {
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Phase m2",
					"id": "obj-28",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "cyma_pix::ph2",
					"parameter_enable": 1,
					"patching_rect": [
						963.9666666666667,
						149.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						78.0,
						122.0,
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
							"parameter_longname": "ph2",
							"parameter_mmax": 6.2832,
							"parameter_mmin": -6.2832,
							"parameter_modmode": 3,
							"parameter_shortname": "ph2",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "ph2"
				}
			},
			{
				"box": {
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Phase m3",
					"id": "obj-29",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "cyma_pix::ph3",
					"parameter_enable": 1,
					"patching_rect": [
						1011.0,
						163.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						115.0,
						122.0,
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
							"parameter_longname": "ph3",
							"parameter_mmax": 6.2832,
							"parameter_mmin": -6.2832,
							"parameter_modmode": 3,
							"parameter_shortname": "ph3",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "ph3"
				}
			},
			{
				"box": {
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Phase m4",
					"id": "obj-30",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "cyma_pix::ph4",
					"parameter_enable": 1,
					"patching_rect": [
						1055.0,
						170.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						152.0,
						122.0,
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
							"parameter_longname": "ph4",
							"parameter_mmax": 6.2832,
							"parameter_mmin": -6.2832,
							"parameter_modmode": 3,
							"parameter_shortname": "ph4",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "ph4"
				}
			},
			{
				"box": {
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Phase m5",
					"id": "obj-31",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "cyma_pix::ph5",
					"parameter_enable": 1,
					"patching_rect": [
						1094.0,
						163.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						189.0,
						122.0,
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
							"parameter_longname": "ph5",
							"parameter_mmax": 6.2832,
							"parameter_mmin": -6.2832,
							"parameter_modmode": 3,
							"parameter_shortname": "ph5",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "ph5"
				}
			},
			{
				"box": {
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Phase m6",
					"id": "obj-32",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "cyma_pix::ph6",
					"parameter_enable": 1,
					"patching_rect": [
						1154.0,
						179.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						226.0,
						122.0,
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
							"parameter_longname": "ph6",
							"parameter_mmax": 6.2832,
							"parameter_mmin": -6.2832,
							"parameter_modmode": 3,
							"parameter_shortname": "ph6",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "ph6"
				}
			},
			{
				"box": {
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Phase m7",
					"id": "obj-33",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "cyma_pix::ph7",
					"parameter_enable": 1,
					"patching_rect": [
						1215.8,
						179.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						263.0,
						122.0,
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
							"parameter_longname": "ph7",
							"parameter_mmax": 6.2832,
							"parameter_mmin": -6.2832,
							"parameter_modmode": 3,
							"parameter_shortname": "ph7",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "ph7"
				}
			},
			{
				"box": {
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Plate radius",
					"id": "obj-34",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "cyma_pix::dishradius",
					"parameter_enable": 1,
					"patching_rect": [
						1264.5,
						170.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						4.0,
						165.0,
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
							"parameter_longname": "dishradius",
							"parameter_mmax": 4.0,
							"parameter_mmin": 0.1,
							"parameter_modmode": 3,
							"parameter_shortname": "dishradius",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "dishradius"
				}
			},
			{
				"box": {
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Reflection amount",
					"id": "obj-35",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "cyma_pix::reflectamt",
					"parameter_enable": 1,
					"patching_rect": [
						1311.0,
						163.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						41.0,
						165.0,
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
							"parameter_longname": "reflectamt",
							"parameter_mmax": 1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "reflectamt",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "reflectamt"
				}
			},
			{
				"box": {
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Nodal line sharpness",
					"id": "obj-36",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "cyma_pix::linesharpness",
					"parameter_enable": 1,
					"patching_rect": [
						1360.0,
						170.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						78.0,
						165.0,
						27.0,
						43.0
					],
					"saved_attribute_attributes": {
						"activedialcolor": {
							"expression": ""
						},
						"valueof": {
							"parameter_initial": [
								10.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "linesharpness",
							"parameter_mmax": 100.0,
							"parameter_mmin": 0.1,
							"parameter_modmode": 3,
							"parameter_shortname": "linesharpness",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "linesharpness"
				}
			},
			{
				"box": {
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Global brightness scale",
					"id": "obj-37",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "cyma_pix::globalscale",
					"parameter_enable": 1,
					"patching_rect": [
						1411.0,
						170.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						115.0,
						165.0,
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
							"parameter_longname": "globalscale",
							"parameter_mmax": 2.0,
							"parameter_modmode": 3,
							"parameter_shortname": "globalscale",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "globalscale"
				}
			},
			{
				"box": {
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "0=circular  1=strip",
					"id": "obj-38",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "cyma_pix::view_mode",
					"parameter_enable": 1,
					"patching_rect": [
						1459.0,
						163.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						152.0,
						165.0,
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
							"parameter_longname": "view_mode",
							"parameter_mmax": 1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "view_mode",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "view_mode"
				}
			},
			{
				"box": {
					"id": "obj-39",
					"maxclass": "attrui",
					"attr": "bypass",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						7.0,
						200.0,
						131.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-40",
					"maxclass": "attrui",
					"attr": "m0amp",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						57.366666666666674,
						237.0,
						133.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-41",
					"maxclass": "attrui",
					"attr": "m1amp",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						111.0,
						271.0,
						133.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-42",
					"maxclass": "attrui",
					"attr": "m2amp",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						155.4666666666667,
						301.0,
						133.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-43",
					"maxclass": "attrui",
					"attr": "m3amp",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						211.0,
						333.0,
						133.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-44",
					"maxclass": "attrui",
					"attr": "m4amp",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						262.0,
						373.0,
						133.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-45",
					"maxclass": "attrui",
					"attr": "m5amp",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						309.2,
						408.0,
						133.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-46",
					"maxclass": "attrui",
					"attr": "m6amp",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						353.0,
						437.0,
						133.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-47",
					"maxclass": "attrui",
					"attr": "m7amp",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						414.0,
						474.0,
						133.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-48",
					"maxclass": "attrui",
					"attr": "z0",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						460.3,
						226.0,
						106.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-49",
					"maxclass": "attrui",
					"attr": "z1",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						500.0,
						253.0,
						106.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-50",
					"maxclass": "attrui",
					"attr": "z2",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						541.0,
						277.0,
						106.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-51",
					"maxclass": "attrui",
					"attr": "z3",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						591.0,
						312.0,
						106.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-52",
					"maxclass": "attrui",
					"attr": "z4",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						628.0,
						338.0,
						106.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-53",
					"maxclass": "attrui",
					"attr": "z5",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						672.0,
						368.0,
						106.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-54",
					"maxclass": "attrui",
					"attr": "z6",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						719.0,
						398.0,
						106.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-55",
					"maxclass": "attrui",
					"attr": "z7",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						737.0,
						430.0,
						106.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-56",
					"maxclass": "attrui",
					"attr": "ph0",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						850.0,
						226.0,
						113.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-57",
					"maxclass": "attrui",
					"attr": "ph1",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						891.0,
						253.0,
						113.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-58",
					"maxclass": "attrui",
					"attr": "ph2",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						934.0,
						286.0,
						113.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-59",
					"maxclass": "attrui",
					"attr": "ph3",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						969.0,
						312.0,
						113.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-60",
					"maxclass": "attrui",
					"attr": "ph4",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1012.0,
						338.0,
						113.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-61",
					"maxclass": "attrui",
					"attr": "ph5",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1051.0,
						368.0,
						113.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-62",
					"maxclass": "attrui",
					"attr": "ph6",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1094.0,
						404.0,
						113.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-63",
					"maxclass": "attrui",
					"attr": "ph7",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1119.0,
						437.0,
						113.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-64",
					"maxclass": "attrui",
					"attr": "dishradius",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1237.0,
						277.0,
						150.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-65",
					"maxclass": "attrui",
					"attr": "reflectamt",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1271.0,
						312.0,
						150.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-66",
					"maxclass": "attrui",
					"attr": "linesharpness",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1297.0,
						345.0,
						167.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-67",
					"maxclass": "attrui",
					"attr": "globalscale",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1319.0,
						378.0,
						153.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-68",
					"maxclass": "attrui",
					"attr": "view_mode",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1356.0,
						415.0,
						154.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-9",
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
							800.0,
							700.0
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
									"code": "Param m0amp(0.0);\nParam m1amp(0.0);\nParam m2amp(0.0);\nParam m3amp(0.0);\nParam m4amp(0.0);\nParam m5amp(0.0);\nParam m6amp(0.0);\nParam m7amp(0.0);\n\nParam z0(2.4048);\nParam z1(3.8317);\nParam z2(5.1356);\nParam z3(6.3802);\nParam z4(7.5883);\nParam z5(8.7715);\nParam z6(9.9361);\nParam z7(11.0864);\n\nParam ph0(0.0);\nParam ph1(0.0);\nParam ph2(0.0);\nParam ph3(0.0);\nParam ph4(0.0);\nParam ph5(0.0);\nParam ph6(0.0);\nParam ph7(0.0);\n\nParam dishradius(1.0);\nParam reflectamt(0.0);\nParam linesharpness(10.0);\nParam globalscale(1.0);\nParam view_mode(0.0);\nParam bypass(0.0);\n\nTWO_PI = 6.28318530718;\nPI     = 3.14159265359;\n\n// --- coordinate system ---\n// view_mode=0: circular plate  view_mode=1: unwrapped strip\ndx = norm.x - 0.5;\ndy = norm.y - 0.5;\n\nr_circ  = sqrt(dx*dx + dy*dy) * 2.0 * dishradius;\nth_circ = atan2(dy, dx);\nr_strip  = norm.y * dishradius;\nth_strip = norm.x * TWO_PI - PI;\n\nr  = mix(r_circ,  r_strip,  view_mode);\nth = mix(th_circ, th_strip, view_mode);\n\n// --- shared Bessel envelope and boundary mask ---\nr_s  = max(r, 0.001);\nenv  = sqrt(2.0 / (PI * r_s));\nmask = 1.0 - smoothstep(0.8, 1.0, r / max(dishradius, 0.001));\n\n// --- modal sum ---\ntotal = 0.0;\ntotal += m0amp * (env * cos(r_s - z0) + reflectamt * env * cos(dishradius - r_s - z0)) * cos(0.0*th + ph0) * mask;\ntotal += m1amp * (env * cos(r_s - z1) + reflectamt * env * cos(dishradius - r_s - z1)) * cos(1.0*th + ph1 + ph0) * mask;\ntotal += m2amp * (env * cos(r_s - z2) + reflectamt * env * cos(dishradius - r_s - z2)) * cos(2.0*th + ph2 + ph0) * mask;\ntotal += m3amp * (env * cos(r_s - z3) + reflectamt * env * cos(dishradius - r_s - z3)) * cos(3.0*th + ph3 + ph0) * mask;\ntotal += m4amp * (env * cos(r_s - z4) + reflectamt * env * cos(dishradius - r_s - z4)) * cos(4.0*th + ph4 + ph0) * mask;\ntotal += m5amp * (env * cos(r_s - z5) + reflectamt * env * cos(dishradius - r_s - z5)) * cos(5.0*th + ph5 + ph0) * mask;\ntotal += m6amp * (env * cos(r_s - z6) + reflectamt * env * cos(dishradius - r_s - z6)) * cos(6.0*th + ph6 + ph0) * mask;\ntotal += m7amp * (env * cos(r_s - z7) + reflectamt * env * cos(dishradius - r_s - z7)) * cos(7.0*th + ph7 + ph0) * mask;\n\n// --- Chladni line rendering ---\nline       = 1.0 - clip(sqrt(abs(total)) * linesharpness, 0.0, 1.0);\nbrightness = line * globalscale;\n\ncyma_out = vec(brightness, brightness, brightness, 1.0);\nout1 = mix(cyma_out, sample(in1, norm), bypass);",
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
										700.0,
										550.0
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
										660.0,
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
						661.7666666666667,
						574.0,
						195.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name chladni_pix",
					"varname": "cyma_pix"
				}
			},
			{
				"box": {
					"id": "obj-70",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"bang"
					],
					"patching_rect": [
						20.0,
						391.0,
						60.0,
						22.0
					],
					"text": "loadbang"
				}
			},
			{
				"box": {
					"id": "obj-71",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						20.0,
						421.0,
						180.0,
						22.0
					],
					"text": "getattr presentation_rect"
				}
			},
			{
				"box": {
					"id": "obj-72",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						20.0,
						451.0,
						80.0,
						22.0
					],
					"save": [
						"#N",
						"thispatcher",
						";",
						"#Q",
						"end",
						";"
					],
					"text": "thispatcher"
				}
			},
			{
				"box": {
					"id": "obj-73",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						20.0,
						481.0,
						60.0,
						22.0
					],
					"text": "zl slice 2"
				}
			},
			{
				"box": {
					"id": "obj-74",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						20.0,
						511.0,
						80.0,
						22.0
					],
					"text": "prepend tam"
				}
			},
			{
				"box": {
					"id": "obj-75",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						20.0,
						541.0,
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
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"id": "obj-label-0",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						20.0,
						500.0,
						27.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						4.0,
						17.0,
						27.0,
						18.0
					],
					"text": "0",
					"textjustification": 2
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"id": "obj-label-1",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						20.0,
						520.0,
						27.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						41.0,
						17.0,
						27.0,
						18.0
					],
					"text": "1",
					"textjustification": 2
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"id": "obj-label-2",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						20.0,
						540.0,
						27.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						78.0,
						17.0,
						27.0,
						18.0
					],
					"text": "2",
					"textjustification": 2
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"id": "obj-label-3",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						20.0,
						560.0,
						27.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						115.0,
						17.0,
						27.0,
						18.0
					],
					"text": "3",
					"textjustification": 2
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"id": "obj-label-4",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						20.0,
						580.0,
						27.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						152.0,
						17.0,
						27.0,
						18.0
					],
					"text": "4",
					"textjustification": 2
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"id": "obj-label-5",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						20.0,
						600.0,
						27.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						189.0,
						17.0,
						27.0,
						18.0
					],
					"text": "5",
					"textjustification": 2
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"id": "obj-label-6",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						20.0,
						620.0,
						27.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						226.0,
						17.0,
						27.0,
						18.0
					],
					"text": "6",
					"textjustification": 2
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"id": "obj-label-7",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						20.0,
						640.0,
						27.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						263.0,
						17.0,
						27.0,
						18.0
					],
					"text": "7",
					"textjustification": 2
				}
			},
			{
				"box": {
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
					"id": "obj-3",
					"maxclass": "panel",
					"mode": 0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						41.9666666666667,
						590.0,
						360.0,
						180.0
					],
					"presentation": 1,
					"presentation_rect": [
						-1.0,
						-15.0,
						299.0,
						234.0
					],
					"proportion": 0.5
				}
			},
			{
				"box": {
					"id": "obj-76",
					"maxclass": "inlet",
					"patching_rect": [
						54.0,
						37.0,
						30.0,
						30.0
					],
					"comment": "control in",
					"numinlets": 0,
					"numoutlets": 1
				}
			}
		],
		"lines": [
			{
				"patchline": {
					"destination": [
						"obj-39",
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
						"obj-40",
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
						"obj-41",
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
						"obj-42",
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
						"obj-43",
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
						"obj-44",
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
						"obj-46",
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
						"obj-47",
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
						"obj-48",
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
						"obj-49",
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
						"obj-50",
						0
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
						"obj-51",
						0
					],
					"source": [
						"obj-21",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-52",
						0
					],
					"source": [
						"obj-22",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-53",
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
						"obj-54",
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
						"obj-55",
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
						"obj-56",
						0
					],
					"source": [
						"obj-26",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-57",
						0
					],
					"source": [
						"obj-27",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-58",
						0
					],
					"source": [
						"obj-28",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-59",
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
						"obj-60",
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
						"obj-61",
						0
					],
					"source": [
						"obj-31",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-62",
						0
					],
					"source": [
						"obj-32",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-63",
						0
					],
					"source": [
						"obj-33",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-64",
						0
					],
					"source": [
						"obj-34",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-65",
						0
					],
					"source": [
						"obj-35",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-66",
						0
					],
					"source": [
						"obj-36",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-67",
						0
					],
					"source": [
						"obj-37",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-68",
						0
					],
					"source": [
						"obj-38",
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
						"obj-39",
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
						"obj-40",
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
						"obj-41",
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
						"obj-42",
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
						"obj-43",
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
						"obj-44",
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
						"obj-45",
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
						"obj-46",
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
						"obj-47",
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
						"obj-48",
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
						"obj-49",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-69",
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
						"obj-9",
						0
					],
					"source": [
						"obj-50",
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
						"obj-51",
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
						"obj-52",
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
						"obj-53",
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
						"obj-54",
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
						"obj-55",
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
						"obj-56",
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
						"obj-57",
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
						"obj-58",
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
						"obj-59",
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
						"obj-60",
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
						"obj-61",
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
						"obj-62",
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
						"obj-63",
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
						"obj-64",
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
						"obj-65",
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
						"obj-66",
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
						"obj-67",
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
						"obj-68",
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
					"source": [
						"obj-69",
						2
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
						"obj-69",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-45",
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
						"obj-71",
						0
					],
					"source": [
						"obj-70",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-72",
						0
					],
					"source": [
						"obj-71",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-73",
						0
					],
					"source": [
						"obj-72",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-74",
						0
					],
					"source": [
						"obj-73",
						1
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-75",
						0
					],
					"source": [
						"obj-74",
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
						"obj-10",
						0
					],
					"source": [
						"obj-8",
						1
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-11",
						0
					],
					"source": [
						"obj-8",
						2
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
						3
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
						"obj-8",
						4
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
						"obj-8",
						5
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
						"obj-8",
						7
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
						"obj-8",
						8
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
						"obj-8",
						9
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-19",
						0
					],
					"source": [
						"obj-8",
						10
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-20",
						0
					],
					"source": [
						"obj-8",
						11
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-21",
						0
					],
					"source": [
						"obj-8",
						12
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
						"obj-8",
						13
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-23",
						0
					],
					"source": [
						"obj-8",
						14
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
						"obj-8",
						15
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
						"obj-8",
						16
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
						"obj-8",
						17
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-27",
						0
					],
					"source": [
						"obj-8",
						18
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-28",
						0
					],
					"source": [
						"obj-8",
						19
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
						"obj-8",
						20
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
						"obj-8",
						21
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-31",
						0
					],
					"source": [
						"obj-8",
						22
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-32",
						0
					],
					"source": [
						"obj-8",
						23
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
						"obj-8",
						24
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-34",
						0
					],
					"source": [
						"obj-8",
						25
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-35",
						0
					],
					"source": [
						"obj-8",
						26
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-36",
						0
					],
					"source": [
						"obj-8",
						27
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-37",
						0
					],
					"source": [
						"obj-8",
						28
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-38",
						0
					],
					"source": [
						"obj-8",
						29
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-7",
						0
					],
					"source": [
						"obj-8",
						6
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
						"obj-9",
						0
					]
				}
			}
		],
		"parameters": {
			"obj-1": [
				"bypass",
				"bypass",
				0
			],
			"obj-10": [
				"m0amp",
				"m0amp",
				0
			],
			"obj-11": [
				"m1amp",
				"m1amp",
				0
			],
			"obj-12": [
				"m2amp",
				"m2amp",
				0
			],
			"obj-13": [
				"m3amp",
				"m3amp",
				0
			],
			"obj-14": [
				"m4amp",
				"m4amp",
				0
			],
			"obj-16": [
				"m6amp",
				"m6amp",
				0
			],
			"obj-17": [
				"m7amp",
				"m7amp",
				0
			],
			"obj-18": [
				"z0",
				"z0",
				0
			],
			"obj-19": [
				"z1",
				"z1",
				0
			],
			"obj-20": [
				"z2",
				"z2",
				0
			],
			"obj-21": [
				"z3",
				"z3",
				0
			],
			"obj-22": [
				"z4",
				"z4",
				0
			],
			"obj-23": [
				"z5",
				"z5",
				0
			],
			"obj-24": [
				"z6",
				"z6",
				0
			],
			"obj-25": [
				"z7",
				"z7",
				0
			],
			"obj-26": [
				"ph0",
				"ph0",
				0
			],
			"obj-27": [
				"ph1",
				"ph1",
				0
			],
			"obj-28": [
				"ph2",
				"ph2",
				0
			],
			"obj-29": [
				"ph3",
				"ph3",
				0
			],
			"obj-30": [
				"ph4",
				"ph4",
				0
			],
			"obj-31": [
				"ph5",
				"ph5",
				0
			],
			"obj-32": [
				"ph6",
				"ph6",
				0
			],
			"obj-33": [
				"ph7",
				"ph7",
				0
			],
			"obj-34": [
				"dishradius",
				"dishradius",
				0
			],
			"obj-35": [
				"reflectamt",
				"reflectamt",
				0
			],
			"obj-36": [
				"linesharpness",
				"linesharpness",
				0
			],
			"obj-37": [
				"globalscale",
				"globalscale",
				0
			],
			"obj-38": [
				"view_mode",
				"view_mode",
				0
			],
			"obj-7": [
				"m5amp",
				"m5amp",
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