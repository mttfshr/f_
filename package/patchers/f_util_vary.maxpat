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
			860.0,
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
						340,
						488
					],
					"presentation": 1,
					"presentation_rect": [
						0,
						0,
						340,
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
					"id": "tl",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						400,
						300,
						400,
						20
					],
					"text": "table: double-click a cell to edit; type a new row in the first empty line (needs out + param); clear out or param to delete",
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
						4,
						172,
						332,
						14
					]
				}
			},
			{
				"box": {
					"id": "cbr",
					"maxclass": "jit.cellblock",
					"numinlets": 2,
					"numoutlets": 3,
					"outlettype": [
						"list",
						"list",
						"list"
					],
					"patching_rect": [
						400,
						320,
						334,
						186
					],
					"rows": 13,
					"cols": 11,
					"colwidth": 30,
					"rowheight": 14,
					"selmode": 5,
					"rowhead": 1,
					"neverdirty": 1,
					"precision": 3,
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0,
					"presentation": 1,
					"presentation_rect": [
						4,
						188,
						334,
						186
					]
				}
			},
			{
				"box": {
					"id": "pc0",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						20,
						560,
						90,
						22
					],
					"text": "prepend cell 0"
				}
			},
			{
				"box": {
					"id": "hd0",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						20,
						600,
						640,
						22
					],
					"text": "set 0 0 out, set 1 0 param, set 2 0 lo, set 3 0 hi, set 4 0 amt%, set 5 0 chance, set 6 0 wob%, set 7 0 group, set 8 0 trim%, set 9 0 mode, set 10 0 sign",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "cbg",
					"maxclass": "jit.cellblock",
					"numinlets": 2,
					"numoutlets": 3,
					"outlettype": [
						"list",
						"list",
						"list"
					],
					"patching_rect": [
						410,
						320,
						108,
						102
					],
					"rows": 7,
					"cols": 2,
					"colwidth": 52,
					"rowheight": 14,
					"selmode": 5,
					"rowhead": 1,
					"neverdirty": 1,
					"precision": 3,
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0,
					"presentation": 1,
					"presentation_rect": [
						4,
						380,
						108,
						102
					]
				}
			},
			{
				"box": {
					"id": "pc1",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						120,
						560,
						90,
						22
					],
					"text": "prepend cell 1"
				}
			},
			{
				"box": {
					"id": "hd1",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						20,
						628,
						640,
						22
					],
					"text": "set 0 0 group, set 1 0 corr",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "cbk",
					"maxclass": "jit.cellblock",
					"numinlets": 2,
					"numoutlets": 3,
					"outlettype": [
						"list",
						"list",
						"list"
					],
					"patching_rect": [
						420,
						320,
						214,
						74
					],
					"rows": 5,
					"cols": 4,
					"colwidth": 52,
					"rowheight": 14,
					"selmode": 5,
					"rowhead": 1,
					"neverdirty": 1,
					"precision": 3,
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0,
					"presentation": 1,
					"presentation_rect": [
						124,
						380,
						214,
						74
					]
				}
			},
			{
				"box": {
					"id": "pc2",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						220,
						560,
						90,
						22
					],
					"text": "prepend cell 2"
				}
			},
			{
				"box": {
					"id": "hd2",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						20,
						656,
						640,
						22
					],
					"text": "set 0 0 row/group, set 1 0 out|group, set 2 0 param, set 3 0 field",
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
					"id": "rf",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						560,
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
					"text": "pattr vary_table @autorestore 1"
				}
			},
			{
				"box": {
					"id": "ap",
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
						240,
						540,
						70,
						22
					],
					"text": "autopattr"
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
						"cbr",
						0
					],
					"destination": [
						"pc0",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pc0",
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
						"cbr",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"hd0",
						0
					],
					"destination": [
						"cbr",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"cbg",
						0
					],
					"destination": [
						"pc1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pc1",
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
						8
					],
					"destination": [
						"cbg",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"hd1",
						0
					],
					"destination": [
						"cbg",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"cbk",
						0
					],
					"destination": [
						"pc2",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pc2",
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
						9
					],
					"destination": [
						"cbk",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"hd2",
						0
					],
					"destination": [
						"cbk",
						0
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
						"hd0",
						0
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
						"hd1",
						0
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
						"hd2",
						0
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
			}
		],
		"autosave": 0
	}
}