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
			254.0,
			95.0,
			935.0,
			922.0
		],
		"openinpresentation": 1,
		"description": "4x4 texture routing matrix for Vsynth",
		"boxes": [
			{
				"box": {
					"filename": "bypass_toggle.js",
					"hint": "Bypass",
					"id": "obj-45",
					"maxclass": "jsui",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"parameter_enable": 1,
					"patching_rect": [
						880.0,
						46.0,
						18.0,
						12.0
					],
					"presentation": 1,
					"presentation_rect": [
						191.00000569224358,
						4.33333346247673,
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
					"comment": "in0 \u2014 texture + control",
					"id": "obj-1",
					"index": 0,
					"maxclass": "inlet",
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
					"comment": "in1 \u2014 texture + control",
					"id": "obj-2",
					"index": 0,
					"maxclass": "inlet",
					"numinlets": 0,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						190.0,
						30.0,
						30.0,
						30.0
					]
				}
			},
			{
				"box": {
					"comment": "in2 \u2014 texture + control",
					"id": "obj-3",
					"index": 0,
					"maxclass": "inlet",
					"numinlets": 0,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						350.0,
						30.0,
						30.0,
						30.0
					]
				}
			},
			{
				"box": {
					"comment": "in3 \u2014 texture + control",
					"id": "obj-4",
					"index": 0,
					"maxclass": "inlet",
					"numinlets": 0,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						510.0,
						30.0,
						30.0,
						30.0
					]
				}
			},
			{
				"box": {
					"comment": "out0",
					"id": "obj-5",
					"index": 0,
					"maxclass": "outlet",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						30.0,
						510.0,
						30.0,
						30.0
					]
				}
			},
			{
				"box": {
					"comment": "out1",
					"id": "obj-6",
					"index": 0,
					"maxclass": "outlet",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						85.0,
						510.0,
						30.0,
						30.0
					]
				}
			},
			{
				"box": {
					"comment": "out2",
					"id": "obj-7",
					"index": 0,
					"maxclass": "outlet",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						140.0,
						510.0,
						30.0,
						30.0
					]
				}
			},
			{
				"box": {
					"comment": "out3",
					"id": "obj-8",
					"index": 0,
					"maxclass": "outlet",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						195.0,
						510.0,
						30.0,
						30.0
					]
				}
			},
			{
				"box": {
					"id": "obj-9",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						-10.0,
						80.0,
						165.0,
						22.0
					],
					"text": "routepass jit_gl_texture"
				}
			},
			{
				"box": {
					"id": "obj-10",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						174.0,
						67.0,
						165.0,
						22.0
					],
					"text": "routepass jit_gl_texture"
				}
			},
			{
				"box": {
					"id": "obj-11",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						350.0,
						67.0,
						165.0,
						22.0
					],
					"text": "routepass jit_gl_texture"
				}
			},
			{
				"box": {
					"id": "obj-12",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						550.0,
						67.0,
						165.0,
						22.0
					],
					"text": "routepass jit_gl_texture"
				}
			},
			{
				"box": {
					"id": "obj-13",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						30.0,
						150.0,
						42.0,
						22.0
					],
					"text": "gate 1"
				}
			},
			{
				"box": {
					"id": "obj-14",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						85.0,
						150.0,
						42.0,
						22.0
					],
					"text": "gate 1"
				}
			},
			{
				"box": {
					"id": "obj-15",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						140.0,
						150.0,
						42.0,
						22.0
					],
					"text": "gate 1"
				}
			},
			{
				"box": {
					"id": "obj-16",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						195.0,
						150.0,
						42.0,
						22.0
					],
					"text": "gate 1"
				}
			},
			{
				"box": {
					"id": "obj-17",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						30.0,
						195.0,
						42.0,
						22.0
					],
					"text": "gate 1"
				}
			},
			{
				"box": {
					"id": "obj-18",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						85.0,
						195.0,
						42.0,
						22.0
					],
					"text": "gate 1"
				}
			},
			{
				"box": {
					"id": "obj-19",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						140.0,
						195.0,
						42.0,
						22.0
					],
					"text": "gate 1"
				}
			},
			{
				"box": {
					"id": "obj-20",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						195.0,
						195.0,
						42.0,
						22.0
					],
					"text": "gate 1"
				}
			},
			{
				"box": {
					"id": "obj-21",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						30.0,
						240.0,
						42.0,
						22.0
					],
					"text": "gate 1"
				}
			},
			{
				"box": {
					"id": "obj-22",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						85.0,
						240.0,
						42.0,
						22.0
					],
					"text": "gate 1"
				}
			},
			{
				"box": {
					"id": "obj-23",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						140.0,
						240.0,
						42.0,
						22.0
					],
					"text": "gate 1"
				}
			},
			{
				"box": {
					"id": "obj-24",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						195.0,
						240.0,
						42.0,
						22.0
					],
					"text": "gate 1"
				}
			},
			{
				"box": {
					"id": "obj-25",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						30.0,
						285.0,
						42.0,
						22.0
					],
					"text": "gate 1"
				}
			},
			{
				"box": {
					"id": "obj-26",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						85.0,
						285.0,
						42.0,
						22.0
					],
					"text": "gate 1"
				}
			},
			{
				"box": {
					"id": "obj-27",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						140.0,
						285.0,
						42.0,
						22.0
					],
					"text": "gate 1"
				}
			},
			{
				"box": {
					"id": "obj-28",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						195.0,
						285.0,
						42.0,
						22.0
					],
					"text": "gate 1"
				}
			},
			{
				"box": {
					"id": "obj-29",
					"maxclass": "live.toggle",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"parameter_enable": 1,
					"patching_rect": [
						700.0,
						150.0,
						20.0,
						20.0
					],
					"presentation": 1,
					"presentation_rect": [
						28.000000834465027,
						28.000000834465027,
						20.0,
						20.0
					],
					"rounded": 20.0,
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_enum": [
								"off",
								"on"
							],
							"parameter_initial": [
								1
							],
							"parameter_initial_enable": 1,
							"parameter_longname": "tog_00",
							"parameter_mmax": 1,
							"parameter_modmode": 0,
							"parameter_shortname": "tog_00",
							"parameter_type": 2
						}
					},
					"varname": "tog_00"
				}
			},
			{
				"box": {
					"id": "obj-30",
					"maxclass": "live.toggle",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"parameter_enable": 1,
					"patching_rect": [
						750.0,
						150.0,
						20.0,
						20.0
					],
					"presentation": 1,
					"presentation_rect": [
						58.0000017285347,
						28.000000834465027,
						20.0,
						20.0
					],
					"rounded": 20.0,
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_enum": [
								"off",
								"on"
							],
							"parameter_initial": [
								0
							],
							"parameter_initial_enable": 1,
							"parameter_longname": "tog_01",
							"parameter_mmax": 1,
							"parameter_modmode": 0,
							"parameter_shortname": "tog_01",
							"parameter_type": 2
						}
					},
					"varname": "tog_01"
				}
			},
			{
				"box": {
					"id": "obj-31",
					"maxclass": "live.toggle",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"parameter_enable": 1,
					"patching_rect": [
						800.0,
						150.0,
						20.0,
						20.0
					],
					"presentation": 1,
					"presentation_rect": [
						90.00000268220901,
						28.000000834465027,
						20.0,
						20.0
					],
					"rounded": 20.0,
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_enum": [
								"off",
								"on"
							],
							"parameter_initial": [
								0
							],
							"parameter_initial_enable": 1,
							"parameter_longname": "tog_02",
							"parameter_mmax": 1,
							"parameter_modmode": 0,
							"parameter_shortname": "tog_02",
							"parameter_type": 2
						}
					},
					"varname": "tog_02"
				}
			},
			{
				"box": {
					"id": "obj-32",
					"maxclass": "live.toggle",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"parameter_enable": 1,
					"patching_rect": [
						850.0,
						150.0,
						20.0,
						20.0
					],
					"presentation": 1,
					"presentation_rect": [
						122.00000363588333,
						28.000000834465027,
						20.0,
						20.0
					],
					"rounded": 20.0,
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_enum": [
								"off",
								"on"
							],
							"parameter_initial": [
								0
							],
							"parameter_initial_enable": 1,
							"parameter_longname": "tog_03",
							"parameter_mmax": 1,
							"parameter_modmode": 0,
							"parameter_shortname": "tog_03",
							"parameter_type": 2
						}
					},
					"varname": "tog_03"
				}
			},
			{
				"box": {
					"id": "obj-33",
					"maxclass": "live.toggle",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"parameter_enable": 1,
					"patching_rect": [
						700.0,
						195.0,
						20.0,
						20.0
					],
					"presentation": 1,
					"presentation_rect": [
						28.000000834465027,
						53.00000157952309,
						20.0,
						20.0
					],
					"rounded": 20.0,
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_enum": [
								"off",
								"on"
							],
							"parameter_initial": [
								0
							],
							"parameter_initial_enable": 1,
							"parameter_longname": "tog_10",
							"parameter_mmax": 1,
							"parameter_modmode": 0,
							"parameter_shortname": "tog_10",
							"parameter_type": 2
						}
					},
					"varname": "tog_10"
				}
			},
			{
				"box": {
					"id": "obj-34",
					"maxclass": "live.toggle",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"parameter_enable": 1,
					"patching_rect": [
						750.0,
						195.0,
						20.0,
						20.0
					],
					"presentation": 1,
					"presentation_rect": [
						58.0000017285347,
						53.00000157952309,
						20.0,
						20.0
					],
					"rounded": 20.0,
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_enum": [
								"off",
								"on"
							],
							"parameter_initial": [
								1
							],
							"parameter_initial_enable": 1,
							"parameter_longname": "tog_11",
							"parameter_mmax": 1,
							"parameter_modmode": 0,
							"parameter_shortname": "tog_11",
							"parameter_type": 2
						}
					},
					"varname": "tog_11"
				}
			},
			{
				"box": {
					"id": "obj-35",
					"maxclass": "live.toggle",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"parameter_enable": 1,
					"patching_rect": [
						800.0,
						195.0,
						20.0,
						20.0
					],
					"presentation": 1,
					"presentation_rect": [
						90.00000268220901,
						53.00000157952309,
						20.0,
						20.0
					],
					"rounded": 20.0,
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_enum": [
								"off",
								"on"
							],
							"parameter_initial": [
								0
							],
							"parameter_initial_enable": 1,
							"parameter_longname": "tog_12",
							"parameter_mmax": 1,
							"parameter_modmode": 0,
							"parameter_shortname": "tog_12",
							"parameter_type": 2
						}
					},
					"varname": "tog_12"
				}
			},
			{
				"box": {
					"id": "obj-36",
					"maxclass": "live.toggle",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"parameter_enable": 1,
					"patching_rect": [
						850.0,
						195.0,
						20.0,
						20.0
					],
					"presentation": 1,
					"presentation_rect": [
						122.00000363588333,
						53.00000157952309,
						20.0,
						20.0
					],
					"rounded": 20.0,
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_enum": [
								"off",
								"on"
							],
							"parameter_initial": [
								0
							],
							"parameter_initial_enable": 1,
							"parameter_longname": "tog_13",
							"parameter_mmax": 1,
							"parameter_modmode": 0,
							"parameter_shortname": "tog_13",
							"parameter_type": 2
						}
					},
					"varname": "tog_13"
				}
			},
			{
				"box": {
					"id": "obj-37",
					"maxclass": "live.toggle",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"parameter_enable": 1,
					"patching_rect": [
						700.0,
						240.0,
						20.0,
						20.0
					],
					"presentation": 1,
					"presentation_rect": [
						28.000000834465027,
						78.00000232458115,
						20.0,
						20.0
					],
					"rounded": 20.0,
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_enum": [
								"off",
								"on"
							],
							"parameter_initial": [
								0
							],
							"parameter_initial_enable": 1,
							"parameter_longname": "tog_20",
							"parameter_mmax": 1,
							"parameter_modmode": 0,
							"parameter_shortname": "tog_20",
							"parameter_type": 2
						}
					},
					"varname": "tog_20"
				}
			},
			{
				"box": {
					"id": "obj-38",
					"maxclass": "live.toggle",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"parameter_enable": 1,
					"patching_rect": [
						750.0,
						240.0,
						20.0,
						20.0
					],
					"presentation": 1,
					"presentation_rect": [
						58.0000017285347,
						78.00000232458115,
						20.0,
						20.0
					],
					"rounded": 20.0,
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_enum": [
								"off",
								"on"
							],
							"parameter_initial": [
								0
							],
							"parameter_initial_enable": 1,
							"parameter_longname": "tog_21",
							"parameter_mmax": 1,
							"parameter_modmode": 0,
							"parameter_shortname": "tog_21",
							"parameter_type": 2
						}
					},
					"varname": "tog_21"
				}
			},
			{
				"box": {
					"id": "obj-39",
					"maxclass": "live.toggle",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"parameter_enable": 1,
					"patching_rect": [
						800.0,
						240.0,
						20.0,
						20.0
					],
					"presentation": 1,
					"presentation_rect": [
						90.00000268220901,
						78.00000232458115,
						20.0,
						20.0
					],
					"rounded": 20.0,
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_enum": [
								"off",
								"on"
							],
							"parameter_initial": [
								1
							],
							"parameter_initial_enable": 1,
							"parameter_longname": "tog_22",
							"parameter_mmax": 1,
							"parameter_modmode": 0,
							"parameter_shortname": "tog_22",
							"parameter_type": 2
						}
					},
					"varname": "tog_22"
				}
			},
			{
				"box": {
					"id": "obj-40",
					"maxclass": "live.toggle",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"parameter_enable": 1,
					"patching_rect": [
						850.0,
						240.0,
						20.0,
						20.0
					],
					"presentation": 1,
					"presentation_rect": [
						122.00000363588333,
						78.00000232458115,
						20.0,
						20.0
					],
					"rounded": 20.0,
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_enum": [
								"off",
								"on"
							],
							"parameter_initial": [
								0
							],
							"parameter_initial_enable": 1,
							"parameter_longname": "tog_23",
							"parameter_mmax": 1,
							"parameter_modmode": 0,
							"parameter_shortname": "tog_23",
							"parameter_type": 2
						}
					},
					"varname": "tog_23"
				}
			},
			{
				"box": {
					"id": "obj-41",
					"maxclass": "live.toggle",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"parameter_enable": 1,
					"patching_rect": [
						700.0,
						285.0,
						20.0,
						20.0
					],
					"presentation": 1,
					"presentation_rect": [
						28.000000834465027,
						103.0000030696392,
						20.0,
						20.0
					],
					"rounded": 20.0,
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_enum": [
								"off",
								"on"
							],
							"parameter_initial": [
								0
							],
							"parameter_initial_enable": 1,
							"parameter_longname": "tog_30",
							"parameter_mmax": 1,
							"parameter_modmode": 0,
							"parameter_shortname": "tog_30",
							"parameter_type": 2
						}
					},
					"varname": "tog_30"
				}
			},
			{
				"box": {
					"id": "obj-42",
					"maxclass": "live.toggle",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"parameter_enable": 1,
					"patching_rect": [
						750.0,
						285.0,
						20.0,
						20.0
					],
					"presentation": 1,
					"presentation_rect": [
						58.0000017285347,
						103.0000030696392,
						20.0,
						20.0
					],
					"rounded": 20.0,
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_enum": [
								"off",
								"on"
							],
							"parameter_initial": [
								0
							],
							"parameter_initial_enable": 1,
							"parameter_longname": "tog_31",
							"parameter_mmax": 1,
							"parameter_modmode": 0,
							"parameter_shortname": "tog_31",
							"parameter_type": 2
						}
					},
					"varname": "tog_31"
				}
			},
			{
				"box": {
					"id": "obj-43",
					"maxclass": "live.toggle",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"parameter_enable": 1,
					"patching_rect": [
						800.0,
						285.0,
						20.0,
						20.0
					],
					"presentation": 1,
					"presentation_rect": [
						90.00000268220901,
						103.0000030696392,
						20.0,
						20.0
					],
					"rounded": 20.0,
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_enum": [
								"off",
								"on"
							],
							"parameter_initial": [
								0
							],
							"parameter_initial_enable": 1,
							"parameter_longname": "tog_32",
							"parameter_mmax": 1,
							"parameter_modmode": 0,
							"parameter_shortname": "tog_32",
							"parameter_type": 2
						}
					},
					"varname": "tog_32"
				}
			},
			{
				"box": {
					"id": "obj-44",
					"maxclass": "live.toggle",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"parameter_enable": 1,
					"patching_rect": [
						850.0,
						285.0,
						20.0,
						20.0
					],
					"presentation": 1,
					"presentation_rect": [
						122.00000363588333,
						103.0000030696392,
						20.0,
						20.0
					],
					"rounded": 20.0,
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_enum": [
								"off",
								"on"
							],
							"parameter_initial": [
								1
							],
							"parameter_initial_enable": 1,
							"parameter_longname": "tog_33",
							"parameter_mmax": 1,
							"parameter_modmode": 0,
							"parameter_shortname": "tog_33",
							"parameter_type": 2
						}
					},
					"varname": "tog_33"
				}
			},
			{
				"box": {
					"id": "obj-46",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"int"
					],
					"patching_rect": [
						960.0,
						120.0,
						42.0,
						22.0
					],
					"text": "!- 1"
				}
			},
			{
				"box": {
					"id": "obj-47",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						960.0,
						160.0,
						42.0,
						22.0
					],
					"text": "gate 1"
				}
			},
			{
				"box": {
					"id": "obj-48",
					"maxclass": "newobj",
					"numinlets": 5,
					"numoutlets": 5,
					"outlettype": [
						"",
						"",
						"",
						"",
						""
					],
					"patching_rect": [
						960.0,
						210.0,
						210.0,
						22.0
					],
					"text": "routepass preset clear reset cell"
				}
			},
			{
				"box": {
					"id": "obj-49",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						960.0,
						255.0,
						80.0,
						22.0
					],
					"text": "route bang"
				}
			},
			{
				"box": {
					"id": "obj-50",
					"maxclass": "preset",
					"numinlets": 1,
					"numoutlets": 5,
					"outlettype": [
						"preset",
						"int",
						"preset",
						"int",
						""
					],
					"patching_rect": [
						1110.0,
						300.0,
						100.0,
						40.0
					],
					"presentation": 1,
					"presentation_rect": [
						156.0000046491623,
						25.66666743159294,
						52.000001549720764,
						100.66666966676712
					]
				}
			},
			{
				"box": {
					"id": "obj-51",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1110.0,
						360.0,
						234.0,
						22.0
					],
					"saved_object_attributes": {
						"client_rect": [
							0,
							100,
							412,
							440
						],
						"parameter_enable": 0,
						"parameter_mappable": 0,
						"storage_rect": [
							0,
							100,
							592,
							464
						]
					},
					"text": "pattrstorage router_presets @savemode 1",
					"varname": "router_presets"
				}
			},
			{
				"box": {
					"id": "obj-52",
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
						1110.0,
						405.0,
						120.0,
						22.0
					],
					"restore": {
						"jsui": [
							0
						],
						"tog_00": [
							1.0
						],
						"tog_01": [
							0.0
						],
						"tog_02": [
							0.0
						],
						"tog_03": [
							0.0
						],
						"tog_10": [
							0.0
						],
						"tog_11": [
							1.0
						],
						"tog_12": [
							0.0
						],
						"tog_13": [
							0.0
						],
						"tog_20": [
							0.0
						],
						"tog_21": [
							0.0
						],
						"tog_22": [
							1.0
						],
						"tog_23": [
							0.0
						],
						"tog_30": [
							0.0
						],
						"tog_31": [
							0.0
						],
						"tog_32": [
							0.0
						],
						"tog_33": [
							1.0
						]
					},
					"text": "autopattr @save 1",
					"varname": "router_autopattr"
				}
			},
			{
				"box": {
					"id": "obj-53",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						960.0,
						300.0,
						82.0,
						22.0
					],
					"text": "prepend next"
				}
			},
			{
				"box": {
					"id": "obj-54",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						810.0,
						255.0,
						92.0,
						22.0
					],
					"text": "prepend store"
				}
			},
			{
				"box": {
					"id": "obj-55",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						810.0,
						305.0,
						248.0,
						22.0
					],
					"text": "0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0"
				}
			},
			{
				"box": {
					"id": "obj-56",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						810.0,
						340.0,
						248.0,
						22.0
					],
					"text": "1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1"
				}
			},
			{
				"box": {
					"id": "obj-57",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 16,
					"outlettype": [
						"int",
						"int",
						"int",
						"int",
						"int",
						"int",
						"int",
						"int",
						"int",
						"int",
						"int",
						"int",
						"int",
						"int",
						"int",
						"int"
					],
					"patching_rect": [
						700.0,
						395.0,
						318.0,
						22.0
					],
					"text": "unpack i i i i i i i i i i i i i i i i"
				}
			},
			{
				"box": {
					"id": "obj-58",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"bang"
					],
					"patching_rect": [
						660.0,
						30.0,
						65.0,
						22.0
					],
					"text": "loadbang"
				}
			},
			{
				"box": {
					"id": "obj-59",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"int",
						"int",
						"int"
					],
					"patching_rect": [
						1360.0,
						255.0,
						80.0,
						22.0
					],
					"text": "unpack i i i"
				}
			},
			{
				"box": {
					"id": "obj-60",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1460.0,
						295.0,
						138.0,
						22.0
					],
					"text": "expr ($i1 * 4) + $i2"
				}
			},
			{
				"box": {
					"id": "obj-61",
					"maxclass": "newobj",
					"numinlets": 17,
					"numoutlets": 17,
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
						""
					],
					"patching_rect": [
						1360.0,
						340.0,
						318.0,
						22.0
					],
					"text": "route 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15"
				}
			},
			{
				"box": {
					"id": "obj-62",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"bang"
					],
					"patching_rect": [
						1360.0,
						380.0,
						30.0,
						22.0
					],
					"text": "t b"
				}
			},
			{
				"box": {
					"id": "obj-63",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"int"
					],
					"patching_rect": [
						1360.0,
						475.0,
						30.0,
						22.0
					],
					"text": "int"
				}
			},
			{
				"box": {
					"id": "obj-64",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"bang"
					],
					"patching_rect": [
						1412.0,
						380.0,
						30.0,
						22.0
					],
					"text": "t b"
				}
			},
			{
				"box": {
					"id": "obj-65",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"int"
					],
					"patching_rect": [
						1412.0,
						475.0,
						30.0,
						22.0
					],
					"text": "int"
				}
			},
			{
				"box": {
					"id": "obj-66",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"bang"
					],
					"patching_rect": [
						1464.0,
						380.0,
						30.0,
						22.0
					],
					"text": "t b"
				}
			},
			{
				"box": {
					"id": "obj-67",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"int"
					],
					"patching_rect": [
						1464.0,
						475.0,
						30.0,
						22.0
					],
					"text": "int"
				}
			},
			{
				"box": {
					"id": "obj-68",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"bang"
					],
					"patching_rect": [
						1516.0,
						380.0,
						30.0,
						22.0
					],
					"text": "t b"
				}
			},
			{
				"box": {
					"id": "obj-69",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"int"
					],
					"patching_rect": [
						1516.0,
						475.0,
						30.0,
						22.0
					],
					"text": "int"
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
						1360.0,
						410.0,
						30.0,
						22.0
					],
					"text": "t b"
				}
			},
			{
				"box": {
					"id": "obj-71",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"int"
					],
					"patching_rect": [
						1360.0,
						505.0,
						30.0,
						22.0
					],
					"text": "int"
				}
			},
			{
				"box": {
					"id": "obj-72",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"bang"
					],
					"patching_rect": [
						1412.0,
						410.0,
						30.0,
						22.0
					],
					"text": "t b"
				}
			},
			{
				"box": {
					"id": "obj-73",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"int"
					],
					"patching_rect": [
						1412.0,
						505.0,
						30.0,
						22.0
					],
					"text": "int"
				}
			},
			{
				"box": {
					"id": "obj-74",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"bang"
					],
					"patching_rect": [
						1464.0,
						410.0,
						30.0,
						22.0
					],
					"text": "t b"
				}
			},
			{
				"box": {
					"id": "obj-75",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"int"
					],
					"patching_rect": [
						1464.0,
						505.0,
						30.0,
						22.0
					],
					"text": "int"
				}
			},
			{
				"box": {
					"id": "obj-76",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"bang"
					],
					"patching_rect": [
						1516.0,
						410.0,
						30.0,
						22.0
					],
					"text": "t b"
				}
			},
			{
				"box": {
					"id": "obj-77",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"int"
					],
					"patching_rect": [
						1516.0,
						505.0,
						30.0,
						22.0
					],
					"text": "int"
				}
			},
			{
				"box": {
					"id": "obj-78",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"bang"
					],
					"patching_rect": [
						1360.0,
						440.0,
						30.0,
						22.0
					],
					"text": "t b"
				}
			},
			{
				"box": {
					"id": "obj-79",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"int"
					],
					"patching_rect": [
						1360.0,
						535.0,
						30.0,
						22.0
					],
					"text": "int"
				}
			},
			{
				"box": {
					"id": "obj-80",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"bang"
					],
					"patching_rect": [
						1412.0,
						440.0,
						30.0,
						22.0
					],
					"text": "t b"
				}
			},
			{
				"box": {
					"id": "obj-81",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"int"
					],
					"patching_rect": [
						1412.0,
						535.0,
						30.0,
						22.0
					],
					"text": "int"
				}
			},
			{
				"box": {
					"id": "obj-82",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"bang"
					],
					"patching_rect": [
						1464.0,
						440.0,
						30.0,
						22.0
					],
					"text": "t b"
				}
			},
			{
				"box": {
					"id": "obj-83",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"int"
					],
					"patching_rect": [
						1464.0,
						535.0,
						30.0,
						22.0
					],
					"text": "int"
				}
			},
			{
				"box": {
					"id": "obj-84",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"bang"
					],
					"patching_rect": [
						1516.0,
						440.0,
						30.0,
						22.0
					],
					"text": "t b"
				}
			},
			{
				"box": {
					"id": "obj-85",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"int"
					],
					"patching_rect": [
						1516.0,
						535.0,
						30.0,
						22.0
					],
					"text": "int"
				}
			},
			{
				"box": {
					"id": "obj-86",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"bang"
					],
					"patching_rect": [
						1360.0,
						470.0,
						30.0,
						22.0
					],
					"text": "t b"
				}
			},
			{
				"box": {
					"id": "obj-87",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"int"
					],
					"patching_rect": [
						1360.0,
						565.0,
						30.0,
						22.0
					],
					"text": "int"
				}
			},
			{
				"box": {
					"id": "obj-88",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"bang"
					],
					"patching_rect": [
						1412.0,
						470.0,
						30.0,
						22.0
					],
					"text": "t b"
				}
			},
			{
				"box": {
					"id": "obj-89",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"int"
					],
					"patching_rect": [
						1412.0,
						565.0,
						30.0,
						22.0
					],
					"text": "int"
				}
			},
			{
				"box": {
					"id": "obj-90",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"bang"
					],
					"patching_rect": [
						1464.0,
						470.0,
						30.0,
						22.0
					],
					"text": "t b"
				}
			},
			{
				"box": {
					"id": "obj-91",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"int"
					],
					"patching_rect": [
						1464.0,
						565.0,
						30.0,
						22.0
					],
					"text": "int"
				}
			},
			{
				"box": {
					"id": "obj-92",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"bang"
					],
					"patching_rect": [
						1516.0,
						470.0,
						30.0,
						22.0
					],
					"text": "t b"
				}
			},
			{
				"box": {
					"id": "obj-93",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"int"
					],
					"patching_rect": [
						1516.0,
						565.0,
						30.0,
						22.0
					],
					"text": "int"
				}
			},
			{
				"box": {
					"fontface": 0,
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"id": "obj-95",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						1750.0,
						50.0,
						110.0,
						21.0
					],
					"presentation": 1,
					"presentation_rect": [
						-0.5,
						-1.5,
						96.0,
						21.0
					],
					"text": "Texture router",
					"textcolor": [
						0.9,
						0.9,
						0.9,
						1.0
					]
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0,
					"id": "obj-97",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						1750.0,
						90.0,
						104.0,
						17.0
					],
					"presentation": 1,
					"presentation_rect": [
						26.000000774860382,
						13.000000387430191,
						27.666667491197586,
						17.0
					],
					"text": "out0",
					"textcolor": [
						0.65,
						0.65,
						0.65,
						1.0
					]
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0,
					"id": "obj-98",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						1750.0,
						110.0,
						104.0,
						17.0
					],
					"presentation": 1,
					"presentation_rect": [
						56.000001668930054,
						13.000000387430191,
						27.0,
						17.0
					],
					"text": "out1",
					"textcolor": [
						0.65,
						0.65,
						0.65,
						1.0
					]
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0,
					"id": "obj-99",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						1750.0,
						130.0,
						104.0,
						17.0
					],
					"presentation": 1,
					"presentation_rect": [
						88.00000262260437,
						13.000000387430191,
						27.0,
						17.0
					],
					"text": "out2",
					"textcolor": [
						0.65,
						0.65,
						0.65,
						1.0
					]
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0,
					"id": "obj-100",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						1750.0,
						150.0,
						104.0,
						17.0
					],
					"presentation": 1,
					"presentation_rect": [
						120.00000357627869,
						13.000000387430191,
						30.00000089406967,
						17.0
					],
					"text": "out3",
					"textcolor": [
						0.65,
						0.65,
						0.65,
						1.0
					]
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0,
					"id": "obj-101",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						1750.0,
						170.0,
						100.0,
						17.0
					],
					"presentation": 1,
					"presentation_rect": [
						5.0,
						31.0,
						32.0,
						17.0
					],
					"text": "in0",
					"textcolor": [
						0.65,
						0.65,
						0.65,
						1.0
					]
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0,
					"id": "obj-102",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						1750.0,
						190.0,
						100.0,
						17.0
					],
					"presentation": 1,
					"presentation_rect": [
						5.0,
						56.0,
						32.0,
						17.0
					],
					"text": "in1",
					"textcolor": [
						0.65,
						0.65,
						0.65,
						1.0
					]
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0,
					"id": "obj-103",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						1750.0,
						210.0,
						100.0,
						17.0
					],
					"presentation": 1,
					"presentation_rect": [
						5.0,
						81.0,
						32.0,
						17.0
					],
					"text": "in2",
					"textcolor": [
						0.65,
						0.65,
						0.65,
						1.0
					]
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0,
					"id": "obj-104",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						1750.0,
						230.0,
						100.0,
						17.0
					],
					"presentation": 1,
					"presentation_rect": [
						5.0,
						106.0,
						32.0,
						17.0
					],
					"text": "in3",
					"textcolor": [
						0.65,
						0.65,
						0.65,
						1.0
					]
				}
			},
			{
				"box": {
					"angle": 270.0,
					"bgcolor": [
						0.054901960784313725,
						0.054901960784313725,
						0.054901960784313725,
						1.0
					],
					"border": 1,
					"bordercolor": [
						0.0,
						0.03529411765,
						0.2274509804,
						1.0
					],
					"id": "obj-94",
					"maxclass": "panel",
					"mode": 0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						1750.0,
						30.0,
						20.0,
						20.0
					],
					"presentation": 1,
					"presentation_rect": [
						0.0,
						0.0,
						212.66667300462723,
						129.66667053103447
					],
					"proportion": 0.5
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
					"id": "obj-109",
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
			},
			{
				"box": {
					"id": "obj-110",
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
					"id": "obj-111",
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
					"id": "obj-112",
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
					"id": "obj-113",
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
			}
		],
		"lines": [
			{
				"patchline": {
					"destination": [
						"obj-9",
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
						"obj-17",
						1
					],
					"order": 3,
					"source": [
						"obj-10",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-18",
						1
					],
					"order": 2,
					"source": [
						"obj-10",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-19",
						1
					],
					"order": 1,
					"source": [
						"obj-10",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-20",
						1
					],
					"order": 0,
					"source": [
						"obj-10",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-47",
						1
					],
					"source": [
						"obj-10",
						1
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-21",
						1
					],
					"order": 3,
					"source": [
						"obj-11",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-22",
						1
					],
					"order": 2,
					"source": [
						"obj-11",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-23",
						1
					],
					"order": 1,
					"source": [
						"obj-11",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-24",
						1
					],
					"order": 0,
					"source": [
						"obj-11",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-47",
						1
					],
					"source": [
						"obj-11",
						1
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-25",
						1
					],
					"order": 3,
					"source": [
						"obj-12",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-26",
						1
					],
					"order": 2,
					"source": [
						"obj-12",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-27",
						1
					],
					"order": 1,
					"source": [
						"obj-12",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-28",
						1
					],
					"order": 0,
					"source": [
						"obj-12",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-47",
						1
					],
					"source": [
						"obj-12",
						1
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
						"obj-13",
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
						"obj-14",
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
					"source": [
						"obj-15",
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
						"obj-16",
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
						"obj-17",
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
						"obj-18",
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
					"source": [
						"obj-19",
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
						"obj-2",
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
						"obj-20",
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
						"obj-21",
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
						"obj-22",
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
					"source": [
						"obj-23",
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
						"obj-24",
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
						"obj-25",
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
						"obj-26",
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
					"source": [
						"obj-27",
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
						"obj-28",
						0
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
						"obj-29",
						0
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
						"obj-3",
						0
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
						0
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
						"obj-31",
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
						"obj-32",
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
						"obj-33",
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
						"obj-34",
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
					"source": [
						"obj-35",
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
					"source": [
						"obj-36",
						0
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
						"obj-37",
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
						"obj-38",
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
					"source": [
						"obj-39",
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
						"obj-4",
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
					"source": [
						"obj-40",
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
					"source": [
						"obj-41",
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
						"obj-42",
						0
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
						"obj-43",
						0
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
						"obj-44",
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
						"obj-45",
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
						"obj-46",
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
						"obj-47",
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
						"obj-48",
						4
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
						"obj-48",
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
						"obj-48",
						1
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
						"obj-48",
						2
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
						"obj-48",
						3
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
						"obj-49",
						1
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
						"obj-49",
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
						"obj-50",
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
						"obj-53",
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
						"obj-54",
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
						"obj-55",
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
						"obj-56",
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
						"obj-57",
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
						"obj-57",
						1
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
						"obj-57",
						2
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
						"obj-57",
						3
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
						"obj-57",
						4
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
						"obj-57",
						5
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
						"obj-57",
						6
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
						"obj-57",
						7
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
						"obj-57",
						8
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
						"obj-57",
						9
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
						"obj-57",
						10
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
						"obj-57",
						11
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
						"obj-57",
						12
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
						"obj-57",
						13
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
						"obj-57",
						14
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
						"obj-57",
						15
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
						"obj-58",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-60",
						1
					],
					"source": [
						"obj-59",
						1
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
						"obj-59",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-63",
						1
					],
					"order": 15,
					"source": [
						"obj-59",
						2
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-65",
						1
					],
					"order": 11,
					"source": [
						"obj-59",
						2
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-67",
						1
					],
					"order": 7,
					"source": [
						"obj-59",
						2
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-69",
						1
					],
					"order": 3,
					"source": [
						"obj-59",
						2
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-71",
						1
					],
					"order": 14,
					"source": [
						"obj-59",
						2
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-73",
						1
					],
					"order": 10,
					"source": [
						"obj-59",
						2
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-75",
						1
					],
					"order": 6,
					"source": [
						"obj-59",
						2
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-77",
						1
					],
					"order": 2,
					"source": [
						"obj-59",
						2
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-79",
						1
					],
					"order": 13,
					"source": [
						"obj-59",
						2
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-81",
						1
					],
					"order": 9,
					"source": [
						"obj-59",
						2
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-83",
						1
					],
					"order": 5,
					"source": [
						"obj-59",
						2
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-85",
						1
					],
					"order": 1,
					"source": [
						"obj-59",
						2
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-87",
						1
					],
					"order": 12,
					"source": [
						"obj-59",
						2
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-89",
						1
					],
					"order": 8,
					"source": [
						"obj-59",
						2
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-91",
						1
					],
					"order": 4,
					"source": [
						"obj-59",
						2
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-93",
						1
					],
					"order": 0,
					"source": [
						"obj-59",
						2
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
						"obj-60",
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
						"obj-61",
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
						"obj-61",
						1
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
						"obj-61",
						2
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
						"obj-61",
						3
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-70",
						0
					],
					"source": [
						"obj-61",
						4
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
						"obj-61",
						5
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
						"obj-61",
						6
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-76",
						0
					],
					"source": [
						"obj-61",
						7
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-78",
						0
					],
					"source": [
						"obj-61",
						8
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-80",
						0
					],
					"source": [
						"obj-61",
						9
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-82",
						0
					],
					"source": [
						"obj-61",
						10
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-84",
						0
					],
					"source": [
						"obj-61",
						11
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-86",
						0
					],
					"source": [
						"obj-61",
						12
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-88",
						0
					],
					"source": [
						"obj-61",
						13
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-90",
						0
					],
					"source": [
						"obj-61",
						14
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-92",
						0
					],
					"source": [
						"obj-61",
						15
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
						"obj-62",
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
						"obj-63",
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
						"obj-64",
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
						"obj-65",
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
						"obj-66",
						0
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
						"obj-67",
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
						"obj-68",
						0
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
						"obj-69",
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
						"obj-33",
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
						"obj-34",
						0
					],
					"source": [
						"obj-73",
						0
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
						"obj-35",
						0
					],
					"source": [
						"obj-75",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-77",
						0
					],
					"source": [
						"obj-76",
						0
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
						"obj-77",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-79",
						0
					],
					"source": [
						"obj-78",
						0
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
						"obj-79",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-81",
						0
					],
					"source": [
						"obj-80",
						0
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
						"obj-81",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-83",
						0
					],
					"source": [
						"obj-82",
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
						"obj-83",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-85",
						0
					],
					"source": [
						"obj-84",
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
						"obj-85",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-87",
						0
					],
					"source": [
						"obj-86",
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
						"obj-87",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-89",
						0
					],
					"source": [
						"obj-88",
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
						"obj-89",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-13",
						1
					],
					"order": 3,
					"source": [
						"obj-9",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-14",
						1
					],
					"order": 2,
					"source": [
						"obj-9",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-15",
						1
					],
					"order": 1,
					"source": [
						"obj-9",
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
					"order": 0,
					"source": [
						"obj-9",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-47",
						1
					],
					"source": [
						"obj-9",
						1
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-91",
						0
					],
					"source": [
						"obj-90",
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
						"obj-91",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-93",
						0
					],
					"source": [
						"obj-92",
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
						"obj-93",
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
						"obj-110",
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
						"obj-112",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-112",
						1
					],
					"destination": [
						"obj-113",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-113",
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
			"obj-29": [
				"tog_00",
				"tog_00",
				0
			],
			"obj-30": [
				"tog_01",
				"tog_01",
				0
			],
			"obj-31": [
				"tog_02",
				"tog_02",
				0
			],
			"obj-32": [
				"tog_03",
				"tog_03",
				0
			],
			"obj-33": [
				"tog_10",
				"tog_10",
				0
			],
			"obj-34": [
				"tog_11",
				"tog_11",
				0
			],
			"obj-35": [
				"tog_12",
				"tog_12",
				0
			],
			"obj-36": [
				"tog_13",
				"tog_13",
				0
			],
			"obj-37": [
				"tog_20",
				"tog_20",
				0
			],
			"obj-38": [
				"tog_21",
				"tog_21",
				0
			],
			"obj-39": [
				"tog_22",
				"tog_22",
				0
			],
			"obj-40": [
				"tog_23",
				"tog_23",
				0
			],
			"obj-41": [
				"tog_30",
				"tog_30",
				0
			],
			"obj-42": [
				"tog_31",
				"tog_31",
				0
			],
			"obj-43": [
				"tog_32",
				"tog_32",
				0
			],
			"obj-44": [
				"tog_33",
				"tog_33",
				0
			],
			"obj-45": [
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