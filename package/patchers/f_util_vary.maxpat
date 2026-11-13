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
			760.0
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
						372,
						488
					],
					"presentation": 1,
					"presentation_rect": [
						0,
						0,
						372,
						488
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
						264,
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
					"id": "pt_amount",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"",
						"",
						""
					],
					"patching_rect": [
						20,
						230,
						100,
						22
					],
					"text": "pattr vary_amount"
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
						260,
						70,
						22
					],
					"text": "prepend amount"
				}
			},
			{
				"box": {
					"id": "s_amount",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						20,
						290,
						70,
						22
					],
					"text": "prepend set"
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
					"id": "pt_chance",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"",
						"",
						""
					],
					"patching_rect": [
						90,
						230,
						100,
						22
					],
					"text": "pattr vary_chance"
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
						260,
						70,
						22
					],
					"text": "prepend chance"
				}
			},
			{
				"box": {
					"id": "s_chance",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						90,
						290,
						70,
						22
					],
					"text": "prepend set"
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
					"id": "pt_wobble",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"",
						"",
						""
					],
					"patching_rect": [
						160,
						230,
						100,
						22
					],
					"text": "pattr vary_wobble"
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
						260,
						70,
						22
					],
					"text": "prepend wobble"
				}
			},
			{
				"box": {
					"id": "s_wobble",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						160,
						290,
						70,
						22
					],
					"text": "prepend set"
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
					"id": "pt_slew",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"",
						"",
						""
					],
					"patching_rect": [
						230,
						230,
						100,
						22
					],
					"text": "pattr vary_slew"
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
						260,
						70,
						22
					],
					"text": "prepend slew"
				}
			},
			{
				"box": {
					"id": "s_slew",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						230,
						290,
						70,
						22
					],
					"text": "prepend set"
				}
			},
			{
				"box": {
					"id": "rg",
					"maxclass": "newobj",
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
						20,
						380,
						120,
						22
					],
					"text": "route g1 g2 g3 g4"
				}
			},
			{
				"box": {
					"id": "pt_seed",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"",
						"",
						""
					],
					"patching_rect": [
						400,
						500,
						100,
						22
					],
					"text": "pattr vary_seed"
				}
			},
			{
				"box": {
					"id": "s_seed",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						510,
						500,
						70,
						22
					],
					"text": "prepend set"
				}
			},
			{
				"box": {
					"id": "d_g1",
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
							"parameter_longname": "g1",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "g1",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 1,
					"varname": "g1"
				}
			},
			{
				"box": {
					"id": "p_g1",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						20,
						340,
						100,
						22
					],
					"text": "prepend group g1"
				}
			},
			{
				"box": {
					"id": "s_g1",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						150,
						410,
						70,
						22
					],
					"text": "prepend set"
				}
			},
			{
				"box": {
					"id": "d_g2",
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
							"parameter_longname": "g2",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "g2",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 1,
					"varname": "g2"
				}
			},
			{
				"box": {
					"id": "p_g2",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						90,
						340,
						100,
						22
					],
					"text": "prepend group g2"
				}
			},
			{
				"box": {
					"id": "s_g2",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						220,
						410,
						70,
						22
					],
					"text": "prepend set"
				}
			},
			{
				"box": {
					"id": "d_g3",
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
							"parameter_longname": "g3",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "g3",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 1,
					"varname": "g3"
				}
			},
			{
				"box": {
					"id": "p_g3",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						160,
						340,
						100,
						22
					],
					"text": "prepend group g3"
				}
			},
			{
				"box": {
					"id": "s_g3",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						290,
						410,
						70,
						22
					],
					"text": "prepend set"
				}
			},
			{
				"box": {
					"id": "d_g4",
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
							"parameter_longname": "g4",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "g4",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 1,
					"varname": "g4"
				}
			},
			{
				"box": {
					"id": "p_g4",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						230,
						340,
						100,
						22
					],
					"text": "prepend group g4"
				}
			},
			{
				"box": {
					"id": "s_g4",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						360,
						410,
						70,
						22
					],
					"text": "prepend set"
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
						160,
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
						160,
						40
					]
				}
			},
			{
				"box": {
					"id": "h_out",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						402,
						400,
						40,
						16
					],
					"text": "out",
					"fontname": "Ableton Sans Light",
					"fontsize": 7.0,
					"textcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"presentation": 1,
					"presentation_rect": [
						2,
						170,
						40,
						14
					]
				}
			},
			{
				"box": {
					"id": "h_param",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						426,
						400,
						40,
						16
					],
					"text": "param",
					"fontname": "Ableton Sans Light",
					"fontsize": 7.0,
					"textcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"presentation": 1,
					"presentation_rect": [
						26,
						170,
						40,
						14
					]
				}
			},
			{
				"box": {
					"id": "h_lo",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						493,
						400,
						40,
						16
					],
					"text": "lo",
					"fontname": "Ableton Sans Light",
					"fontsize": 7.0,
					"textcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"presentation": 1,
					"presentation_rect": [
						93,
						170,
						40,
						14
					]
				}
			},
			{
				"box": {
					"id": "h_hi",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						533,
						400,
						40,
						16
					],
					"text": "hi",
					"fontname": "Ableton Sans Light",
					"fontsize": 7.0,
					"textcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"presentation": 1,
					"presentation_rect": [
						133,
						170,
						40,
						14
					]
				}
			},
			{
				"box": {
					"id": "h_amt",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						573,
						400,
						40,
						16
					],
					"text": "amt",
					"fontname": "Ableton Sans Light",
					"fontsize": 7.0,
					"textcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"presentation": 1,
					"presentation_rect": [
						173,
						170,
						40,
						14
					]
				}
			},
			{
				"box": {
					"id": "h_chn",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						595,
						400,
						40,
						16
					],
					"text": "chn",
					"fontname": "Ableton Sans Light",
					"fontsize": 7.0,
					"textcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"presentation": 1,
					"presentation_rect": [
						195,
						170,
						40,
						14
					]
				}
			},
			{
				"box": {
					"id": "h_wob",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						617,
						400,
						40,
						16
					],
					"text": "wob",
					"fontname": "Ableton Sans Light",
					"fontsize": 7.0,
					"textcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"presentation": 1,
					"presentation_rect": [
						217,
						170,
						40,
						14
					]
				}
			},
			{
				"box": {
					"id": "h_trim",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						639,
						400,
						40,
						16
					],
					"text": "trim",
					"fontname": "Ableton Sans Light",
					"fontsize": 7.0,
					"textcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"presentation": 1,
					"presentation_rect": [
						239,
						170,
						40,
						14
					]
				}
			},
			{
				"box": {
					"id": "h_mode",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						662,
						400,
						40,
						16
					],
					"text": "mode",
					"fontname": "Ableton Sans Light",
					"fontsize": 7.0,
					"textcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"presentation": 1,
					"presentation_rect": [
						262,
						170,
						40,
						14
					]
				}
			},
			{
				"box": {
					"id": "h_sign",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						679,
						400,
						40,
						16
					],
					"text": "sign",
					"fontname": "Ableton Sans Light",
					"fontsize": 7.0,
					"textcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"presentation": 1,
					"presentation_rect": [
						279,
						170,
						40,
						14
					]
				}
			},
			{
				"box": {
					"id": "h_grp",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						719,
						400,
						40,
						16
					],
					"text": "grp",
					"fontname": "Ableton Sans Light",
					"fontsize": 7.0,
					"textcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"presentation": 1,
					"presentation_rect": [
						319,
						170,
						40,
						14
					]
				}
			},
			{
				"box": {
					"id": "plus",
					"maxclass": "textbutton",
					"text": "+",
					"mode": 0,
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"",
						"",
						"int"
					],
					"patching_rect": [
						400,
						420,
						20,
						20
					],
					"presentation": 1,
					"presentation_rect": [
						343,
						168,
						16,
						16
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 11.0
				}
			},
			{
				"box": {
					"id": "addm",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						430,
						420,
						40,
						22
					],
					"text": "add",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "ld2",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"bang"
					],
					"patching_rect": [
						20,
						580,
						60,
						22
					],
					"text": "loadbang"
				}
			},
			{
				"box": {
					"id": "dly",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						90,
						580,
						60,
						22
					],
					"text": "delay 300"
				}
			},
			{
				"box": {
					"id": "rf",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						160,
						580,
						60,
						22
					],
					"text": "refresh",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "tp",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						260,
						580,
						80,
						22
					],
					"text": "thispatcher"
				}
			},
			{
				"box": {
					"id": "rcell",
					"maxclass": "newobj",
					"numinlets": 0,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						350,
						580,
						90,
						22
					],
					"text": "r #0_cell"
				}
			},
			{
				"box": {
					"id": "tokm",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						450,
						580,
						70,
						22
					],
					"text": "token #0",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "pt",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"",
						"",
						""
					],
					"patching_rect": [
						20,
						540,
						200,
						22
					],
					"text": "pattr vary_table"
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
					"numoutlets": 10,
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
						""
					],
					"patching_rect": [
						20,
						70,
						230,
						22
					],
					"text": "js f_util_vary.js",
					"varname": "eng"
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
						"pt_amount",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pt_amount",
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
						"pt_amount",
						0
					],
					"destination": [
						"s_amount",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"s_amount",
						0
					],
					"destination": [
						"d_amount",
						0
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
						"pt_chance",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pt_chance",
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
						"pt_chance",
						0
					],
					"destination": [
						"s_chance",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"s_chance",
						0
					],
					"destination": [
						"d_chance",
						0
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
						"pt_wobble",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pt_wobble",
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
						"pt_wobble",
						0
					],
					"destination": [
						"s_wobble",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"s_wobble",
						0
					],
					"destination": [
						"d_wobble",
						0
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
						"pt_slew",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pt_slew",
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
						"pt_slew",
						0
					],
					"destination": [
						"s_slew",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"s_slew",
						0
					],
					"destination": [
						"d_slew",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"js",
						9
					],
					"destination": [
						"rg",
						0
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
						"pt_seed",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pt_seed",
						0
					],
					"destination": [
						"s_seed",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"s_seed",
						0
					],
					"destination": [
						"seedn",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"d_g1",
						0
					],
					"destination": [
						"p_g1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"p_g1",
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
						"rg",
						0
					],
					"destination": [
						"s_g1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"s_g1",
						0
					],
					"destination": [
						"d_g1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"d_g2",
						0
					],
					"destination": [
						"p_g2",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"p_g2",
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
						"rg",
						1
					],
					"destination": [
						"s_g2",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"s_g2",
						0
					],
					"destination": [
						"d_g2",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"d_g3",
						0
					],
					"destination": [
						"p_g3",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"p_g3",
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
						"rg",
						2
					],
					"destination": [
						"s_g3",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"s_g3",
						0
					],
					"destination": [
						"d_g3",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"d_g4",
						0
					],
					"destination": [
						"p_g4",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"p_g4",
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
						"rg",
						3
					],
					"destination": [
						"s_g4",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"s_g4",
						0
					],
					"destination": [
						"d_g4",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"plus",
						0
					],
					"destination": [
						"addm",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"addm",
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
						"ld2",
						0
					],
					"destination": [
						"dly",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"dly",
						0
					],
					"destination": [
						"rf",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"rf",
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
						"rcell",
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
						"ld2",
						0
					],
					"destination": [
						"tokm",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tokm",
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
						6
					],
					"destination": [
						"pt",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pt",
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
						7
					],
					"destination": [
						"tp",
						0
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
						"pt_seed",
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
			}
		],
		"autosave": 0
	}
}