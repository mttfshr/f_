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
			760.0,
			600.0
		],
		"openinpresentation": 1,
		"boxes": [
			{
				"box": {
					"id": "bg",
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
						400,
						20,
						340,
						200
					],
					"presentation": 1,
					"presentation_rect": [
						0,
						0,
						340,
						200
					],
					"proportion": 0.5
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
						400,
						255.0,
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
						400,
						262.0,
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
					"id": "title",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						400,
						20,
						100,
						21
					],
					"text": "f_util_vary",
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"presentation": 1,
					"presentation_rect": [
						10.5,
						0.0,
						92.0,
						21.0
					]
				}
			},
			{
				"box": {
					"id": "hint",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						400,
						40,
						300,
						20
					],
					"text": "bases in the left inlet, settings in the right; 4 outlets",
					"fontname": "Ableton Sans Light",
					"fontsize": 8.0,
					"textcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"presentation": 1,
					"presentation_rect": [
						104,
						3,
						232,
						16
					]
				}
			},
			{
				"box": {
					"id": "roll",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						20,
						120,
						40,
						22
					],
					"text": "roll",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0,
					"presentation": 1,
					"presentation_rect": [
						8,
						24,
						40,
						18
					]
				}
			},
			{
				"box": {
					"id": "seedn",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"bang"
					],
					"patching_rect": [
						70,
						120,
						50,
						22
					],
					"text": "number",
					"presentation": 1,
					"presentation_rect": [
						54,
						24,
						44,
						18
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "seedl",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						130,
						120,
						40,
						20
					],
					"text": "seed",
					"fontname": "Ableton Sans Light",
					"fontsize": 8.0,
					"textcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"presentation": 1,
					"presentation_rect": [
						100,
						25,
						34,
						16
					]
				}
			},
			{
				"box": {
					"id": "d_amount",
					"maxclass": "live.dial",
					"fontname": "Ableton Sans Light",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						20,
						160,
						50,
						60
					],
					"presentation": 1,
					"presentation_rect": [
						8,
						46,
						46,
						58
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								1.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "amount",
							"parameter_mmax": 2.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "amount",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 1,
					"varname": "amount"
				}
			},
			{
				"box": {
					"id": "p_amount",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						20,
						230,
						70,
						22
					],
					"text": "prepend amount"
				}
			},
			{
				"box": {
					"id": "d_chance",
					"maxclass": "live.dial",
					"fontname": "Ableton Sans Light",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						90,
						160,
						50,
						60
					],
					"presentation": 1,
					"presentation_rect": [
						58,
						46,
						46,
						58
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								1.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "chance",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "chance",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 1,
					"varname": "chance"
				}
			},
			{
				"box": {
					"id": "p_chance",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						90,
						230,
						70,
						22
					],
					"text": "prepend chance"
				}
			},
			{
				"box": {
					"id": "d_wobble",
					"maxclass": "live.dial",
					"fontname": "Ableton Sans Light",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						160,
						160,
						50,
						60
					],
					"presentation": 1,
					"presentation_rect": [
						108,
						46,
						46,
						58
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								1.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "wobble",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "wobble",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 1,
					"varname": "wobble"
				}
			},
			{
				"box": {
					"id": "p_wobble",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						160,
						230,
						70,
						22
					],
					"text": "prepend wobble"
				}
			},
			{
				"box": {
					"id": "d_slew",
					"maxclass": "live.dial",
					"fontname": "Ableton Sans Light",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						230,
						160,
						50,
						60
					],
					"presentation": 1,
					"presentation_rect": [
						158,
						46,
						46,
						58
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "slew",
							"parameter_mmax": 2000.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "slew",
							"parameter_type": 0,
							"parameter_unitstyle": 2
						}
					},
					"showname": 1,
					"varname": "slew"
				}
			},
			{
				"box": {
					"id": "p_slew",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						230,
						230,
						70,
						22
					],
					"text": "prepend slew"
				}
			},
			{
				"box": {
					"id": "d_k1",
					"maxclass": "live.dial",
					"fontname": "Ableton Sans Light",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						20,
						270,
						50,
						60
					],
					"presentation": 1,
					"presentation_rect": [
						8,
						108,
						46,
						58
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								0.5
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "k1",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "k1",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 1,
					"varname": "k1"
				}
			},
			{
				"box": {
					"id": "p_k1",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						20,
						340,
						80,
						22
					],
					"text": "prepend k 1"
				}
			},
			{
				"box": {
					"id": "d_k2",
					"maxclass": "live.dial",
					"fontname": "Ableton Sans Light",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						90,
						270,
						50,
						60
					],
					"presentation": 1,
					"presentation_rect": [
						58,
						108,
						46,
						58
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								0.5
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "k2",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "k2",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 1,
					"varname": "k2"
				}
			},
			{
				"box": {
					"id": "p_k2",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						90,
						340,
						80,
						22
					],
					"text": "prepend k 2"
				}
			},
			{
				"box": {
					"id": "d_k3",
					"maxclass": "live.dial",
					"fontname": "Ableton Sans Light",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						160,
						270,
						50,
						60
					],
					"presentation": 1,
					"presentation_rect": [
						108,
						108,
						46,
						58
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								0.5
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "k3",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "k3",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 1,
					"varname": "k3"
				}
			},
			{
				"box": {
					"id": "p_k3",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						160,
						340,
						80,
						22
					],
					"text": "prepend k 3"
				}
			},
			{
				"box": {
					"id": "d_k4",
					"maxclass": "live.dial",
					"fontname": "Ableton Sans Light",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						230,
						270,
						50,
						60
					],
					"presentation": 1,
					"presentation_rect": [
						158,
						108,
						46,
						58
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								0.5
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "k4",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "k4",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 1,
					"varname": "k4"
				}
			},
			{
				"box": {
					"id": "p_k4",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						230,
						340,
						80,
						22
					],
					"text": "prepend k 4"
				}
			},
			{
				"box": {
					"id": "mon",
					"maxclass": "multislider",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						400,
						80,
						124,
						100
					],
					"size": 16,
					"setminmax": [
						0.0,
						1.0
					],
					"ignoreclick": 1,
					"contdata": 1,
					"peakcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"slidercolor": [
						0.35,
						0.8,
						0.8,
						1.0
					],
					"bgcolor": [
						0.05,
						0.05,
						0.05,
						1.0
					],
					"presentation": 1,
					"presentation_rect": [
						208,
						24,
						124,
						100
					]
				}
			},
			{
				"box": {
					"id": "labels",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						400,
						190,
						124,
						40
					],
					"text": "(no rows)",
					"fontname": "Ableton Sans Light",
					"fontsize": 8.0,
					"textcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"presentation": 1,
					"presentation_rect": [
						208,
						126,
						124,
						40
					]
				}
			},
			{
				"box": {
					"id": "table",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						20,
						400,
						330,
						22
					],
					"text": "clear, refresh",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0,
					"presentation": 1,
					"presentation_rect": [
						8,
						172,
						324,
						22
					]
				}
			},
			{
				"box": {
					"id": "tablel",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						20,
						424,
						600,
						20
					],
					"text": "table (one message box: click to apply; edit it in an unlocked patch). Lines: param, group, row, knob; see the helpfile.",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0,
					"textcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					]
				}
			},
			{
				"box": {
					"id": "in0",
					"maxclass": "inlet",
					"numinlets": 0,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						20,
						20,
						30,
						30
					],
					"comment": "bases: <param> <value>"
				}
			},
			{
				"box": {
					"id": "in1",
					"maxclass": "inlet",
					"numinlets": 0,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						220,
						20,
						30,
						30
					],
					"comment": "settings and table lines"
				}
			},
			{
				"box": {
					"id": "js",
					"maxclass": "newobj",
					"numinlets": 2,
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
						20,
						70,
						230,
						22
					],
					"text": "js f_util_vary.js"
				}
			},
			{
				"box": {
					"id": "out1",
					"maxclass": "outlet",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						20,
						500,
						30,
						30
					],
					"comment": "destination 1"
				}
			},
			{
				"box": {
					"id": "out2",
					"maxclass": "outlet",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						80,
						500,
						30,
						30
					],
					"comment": "destination 2"
				}
			},
			{
				"box": {
					"id": "out3",
					"maxclass": "outlet",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						140,
						500,
						30,
						30
					],
					"comment": "destination 3"
				}
			},
			{
				"box": {
					"id": "out4",
					"maxclass": "outlet",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						200,
						500,
						30,
						30
					],
					"comment": "destination 4"
				}
			},
			{
				"box": {
					"id": "pseed",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						70,
						150,
						80,
						22
					],
					"text": "prepend seed"
				}
			},
			{
				"box": {
					"id": "draw",
					"maxclass": "newobj",
					"numinlets": 0,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						270,
						120,
						60,
						22
					],
					"text": "r draw"
				}
			},
			{
				"box": {
					"id": "tick",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						270,
						150,
						40,
						22
					],
					"text": "tick",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "ld",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"bang"
					],
					"patching_rect": [
						20,
						370,
						60,
						22
					],
					"text": "loadbang"
				}
			}
		],
		"lines": [
			{
				"patchline": {
					"source": [
						"d_amount",
						0
					],
					"destination": [
						"p_amount",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"p_amount",
						0
					],
					"destination": [
						"js",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"d_chance",
						0
					],
					"destination": [
						"p_chance",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"p_chance",
						0
					],
					"destination": [
						"js",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"d_wobble",
						0
					],
					"destination": [
						"p_wobble",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"p_wobble",
						0
					],
					"destination": [
						"js",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"d_slew",
						0
					],
					"destination": [
						"p_slew",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"p_slew",
						0
					],
					"destination": [
						"js",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"d_k1",
						0
					],
					"destination": [
						"p_k1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"p_k1",
						0
					],
					"destination": [
						"js",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"d_k2",
						0
					],
					"destination": [
						"p_k2",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"p_k2",
						0
					],
					"destination": [
						"js",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"d_k3",
						0
					],
					"destination": [
						"p_k3",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"p_k3",
						0
					],
					"destination": [
						"js",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"d_k4",
						0
					],
					"destination": [
						"p_k4",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"p_k4",
						0
					],
					"destination": [
						"js",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"in0",
						0
					],
					"destination": [
						"js",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"in1",
						0
					],
					"destination": [
						"js",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"js",
						0
					],
					"destination": [
						"out1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"js",
						1
					],
					"destination": [
						"out2",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"js",
						2
					],
					"destination": [
						"out3",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"js",
						3
					],
					"destination": [
						"out4",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"js",
						4
					],
					"destination": [
						"mon",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"js",
						5
					],
					"destination": [
						"labels",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"roll",
						0
					],
					"destination": [
						"js",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"seedn",
						0
					],
					"destination": [
						"pseed",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pseed",
						0
					],
					"destination": [
						"js",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"draw",
						0
					],
					"destination": [
						"tick",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tick",
						0
					],
					"destination": [
						"js",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"ld",
						0
					],
					"destination": [
						"table",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"table",
						0
					],
					"destination": [
						"js",
						1
					]
				}
			}
		],
		"autosave": 0
	}
}