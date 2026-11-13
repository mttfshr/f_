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
			700.0,
			460.0
		],
		"openinpresentation": 1,
		"bgcolor": [
			0.0,
			0.0,
			0.0,
			1.0
		],
		"boxes": [
			{
				"box": {
					"id": "c_out",
					"maxclass": "number",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"bang"
					],
					"patching_rect": [
						2,
						120,
						22,
						16
					],
					"presentation": 1,
					"presentation_rect": [
						2,
						2,
						22,
						16
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0,
					"minimum": 1,
					"maximum": 4
				}
			},
			{
				"box": {
					"id": "c_param",
					"maxclass": "umenu",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"int",
						"",
						""
					],
					"patching_rect": [
						26,
						120,
						64,
						16
					],
					"presentation": 1,
					"presentation_rect": [
						26,
						2,
						64,
						16
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0,
					"items": [],
					"arrow": 0
				}
			},
			{
				"box": {
					"id": "c_lo",
					"maxclass": "flonum",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"bang"
					],
					"patching_rect": [
						93,
						120,
						38,
						16
					],
					"presentation": 1,
					"presentation_rect": [
						93,
						2,
						38,
						16
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "c_hi",
					"maxclass": "flonum",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"bang"
					],
					"patching_rect": [
						133,
						120,
						38,
						16
					],
					"presentation": 1,
					"presentation_rect": [
						133,
						2,
						38,
						16
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "c_amt",
					"maxclass": "dial",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"float"
					],
					"patching_rect": [
						173,
						120,
						20,
						20
					],
					"presentation": 1,
					"presentation_rect": [
						173,
						0,
						20,
						20
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0,
					"floatoutput": 1,
					"min": 0.0,
					"size": 100.0
				}
			},
			{
				"box": {
					"id": "c_chance",
					"maxclass": "dial",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"float"
					],
					"patching_rect": [
						195,
						120,
						20,
						20
					],
					"presentation": 1,
					"presentation_rect": [
						195,
						0,
						20,
						20
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0,
					"floatoutput": 1,
					"min": 0.0,
					"size": 100.0
				}
			},
			{
				"box": {
					"id": "c_wob",
					"maxclass": "dial",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"float"
					],
					"patching_rect": [
						217,
						120,
						20,
						20
					],
					"presentation": 1,
					"presentation_rect": [
						217,
						0,
						20,
						20
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0,
					"floatoutput": 1,
					"min": 0.0,
					"size": 100.0
				}
			},
			{
				"box": {
					"id": "c_trim",
					"maxclass": "dial",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"float"
					],
					"patching_rect": [
						239,
						120,
						20,
						20
					],
					"presentation": 1,
					"presentation_rect": [
						239,
						0,
						20,
						20
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0,
					"floatoutput": 1,
					"min": -100.0,
					"size": 200.0
				}
			},
			{
				"box": {
					"id": "c_mode",
					"maxclass": "toggle",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"int"
					],
					"patching_rect": [
						262,
						120,
						14,
						14
					],
					"presentation": 1,
					"presentation_rect": [
						262,
						3,
						14,
						14
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "c_sign",
					"maxclass": "umenu",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"int",
						"",
						""
					],
					"patching_rect": [
						279,
						120,
						38,
						16
					],
					"presentation": 1,
					"presentation_rect": [
						279,
						2,
						38,
						16
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0,
					"items": [
						"bi",
						",",
						"up",
						",",
						"down"
					],
					"arrow": 0
				}
			},
			{
				"box": {
					"id": "c_grp",
					"maxclass": "number",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"bang"
					],
					"patching_rect": [
						319,
						120,
						22,
						16
					],
					"presentation": 1,
					"presentation_rect": [
						319,
						2,
						22,
						16
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0,
					"minimum": 0,
					"maximum": 4
				}
			},
			{
				"box": {
					"id": "c_del",
					"maxclass": "textbutton",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"",
						"",
						"int"
					],
					"patching_rect": [
						343,
						120,
						16,
						16
					],
					"presentation": 1,
					"presentation_rect": [
						343,
						2,
						16,
						16
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0,
					"text": "-",
					"mode": 0
				}
			},
			{
				"box": {
					"id": "in",
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
					"comment": "<i> <field> <value>"
				}
			},
			{
				"box": {
					"id": "outl",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 0,
					"outlettype": [],
					"patching_rect": [
						20,
						440,
						90,
						22
					],
					"text": "s #2_cell",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "r1",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						20,
						60,
						60,
						22
					],
					"text": "route #1",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "r2",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 13,
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
						""
					],
					"patching_rect": [
						20,
						90,
						520,
						22
					],
					"text": "route out param_idx names lo hi amt chance wob trim group mode sign",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "ps_out",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						20,
						150,
						70,
						22
					],
					"text": "prepend set",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "ps_param_idx",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						90,
						150,
						70,
						22
					],
					"text": "prepend set",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "ps_lo",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						230,
						150,
						70,
						22
					],
					"text": "prepend set",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "ps_hi",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						300,
						150,
						70,
						22
					],
					"text": "prepend set",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "ps_amt",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						370,
						150,
						70,
						22
					],
					"text": "prepend set",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "ps_chance",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						440,
						150,
						70,
						22
					],
					"text": "prepend set",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "ps_wob",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						510,
						150,
						70,
						22
					],
					"text": "prepend set",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "ps_trim",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						580,
						150,
						70,
						22
					],
					"text": "prepend set",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "ps_group",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						650,
						150,
						70,
						22
					],
					"text": "prepend set",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "nt",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						20,
						200,
						50,
						22
					],
					"text": "t l b",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "nclr",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						20,
						230,
						40,
						22
					],
					"text": "clear",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "nit",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						80,
						230,
						60,
						22
					],
					"text": "zl iter 1",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "nap",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						80,
						260,
						90,
						22
					],
					"text": "prepend append",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "sm",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"",
						"",
						""
					],
					"patching_rect": [
						200,
						200,
						60,
						22
					],
					"text": "sel u d",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "sm0",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						200,
						230,
						40,
						22
					],
					"text": "set 0",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "sm1",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						250,
						230,
						40,
						22
					],
					"text": "set 1",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "ss",
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
						320,
						200,
						90,
						22
					],
					"text": "sel bi up down",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "ss0",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						320,
						230,
						40,
						22
					],
					"text": "set 0",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "ss1",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						365,
						230,
						40,
						22
					],
					"text": "set 1",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "ss2",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						410,
						230,
						40,
						22
					],
					"text": "set 2",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "pc_out",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						100,
						330,
						120,
						22
					],
					"text": "prepend cell #1 out",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "pc_param",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						180,
						330,
						120,
						22
					],
					"text": "prepend cell #1 param",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "pc_lo",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						260,
						330,
						120,
						22
					],
					"text": "prepend cell #1 lo",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "pc_hi",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						340,
						330,
						120,
						22
					],
					"text": "prepend cell #1 hi",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "pc_amt",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						20,
						330,
						120,
						22
					],
					"text": "prepend cell #1 amt",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "pc_chance",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						100,
						330,
						120,
						22
					],
					"text": "prepend cell #1 chance",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "pc_wob",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						180,
						330,
						120,
						22
					],
					"text": "prepend cell #1 wob",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "pc_trim",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						260,
						330,
						120,
						22
					],
					"text": "prepend cell #1 trim",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "pc_sign",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						340,
						330,
						120,
						22
					],
					"text": "prepend cell #1 sign",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "pc_group",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						20,
						330,
						120,
						22
					],
					"text": "prepend cell #1 group",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "tm",
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
						360,
						60,
						22
					],
					"text": "sel 0 1",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "tm0",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						20,
						390,
						100,
						22
					],
					"text": "cell #1 mode u",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "tm1",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						130,
						390,
						100,
						22
					],
					"text": "cell #1 mode d",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "dl",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						240,
						390,
						100,
						22
					],
					"text": "cell #1 del 1",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.0
				}
			}
		],
		"lines": [
			{
				"patchline": {
					"source": [
						"in",
						0
					],
					"destination": [
						"r1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"r1",
						0
					],
					"destination": [
						"r2",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"r2",
						0
					],
					"destination": [
						"ps_out",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"ps_out",
						0
					],
					"destination": [
						"c_out",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"r2",
						1
					],
					"destination": [
						"ps_param_idx",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"ps_param_idx",
						0
					],
					"destination": [
						"c_param",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"r2",
						3
					],
					"destination": [
						"ps_lo",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"ps_lo",
						0
					],
					"destination": [
						"c_lo",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"r2",
						4
					],
					"destination": [
						"ps_hi",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"ps_hi",
						0
					],
					"destination": [
						"c_hi",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"r2",
						5
					],
					"destination": [
						"ps_amt",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"ps_amt",
						0
					],
					"destination": [
						"c_amt",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"r2",
						6
					],
					"destination": [
						"ps_chance",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"ps_chance",
						0
					],
					"destination": [
						"c_chance",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"r2",
						7
					],
					"destination": [
						"ps_wob",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"ps_wob",
						0
					],
					"destination": [
						"c_wob",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"r2",
						8
					],
					"destination": [
						"ps_trim",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"ps_trim",
						0
					],
					"destination": [
						"c_trim",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"r2",
						9
					],
					"destination": [
						"ps_group",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"ps_group",
						0
					],
					"destination": [
						"c_grp",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"r2",
						2
					],
					"destination": [
						"nt",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"nt",
						1
					],
					"destination": [
						"nclr",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"nclr",
						0
					],
					"destination": [
						"c_param",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"nt",
						0
					],
					"destination": [
						"nit",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"nit",
						0
					],
					"destination": [
						"nap",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"nap",
						0
					],
					"destination": [
						"c_param",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"r2",
						10
					],
					"destination": [
						"sm",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"sm",
						0
					],
					"destination": [
						"sm0",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"sm",
						1
					],
					"destination": [
						"sm1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"sm0",
						0
					],
					"destination": [
						"c_mode",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"sm1",
						0
					],
					"destination": [
						"c_mode",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"ss",
						0
					],
					"destination": [
						"ss0",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"ss0",
						0
					],
					"destination": [
						"c_sign",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"ss",
						1
					],
					"destination": [
						"ss1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"ss1",
						0
					],
					"destination": [
						"c_sign",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"ss",
						2
					],
					"destination": [
						"ss2",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"ss2",
						0
					],
					"destination": [
						"c_sign",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"r2",
						11
					],
					"destination": [
						"ss",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"c_out",
						0
					],
					"destination": [
						"pc_out",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pc_out",
						0
					],
					"destination": [
						"outl",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"c_param",
						1
					],
					"destination": [
						"pc_param",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pc_param",
						0
					],
					"destination": [
						"outl",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"c_lo",
						0
					],
					"destination": [
						"pc_lo",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pc_lo",
						0
					],
					"destination": [
						"outl",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"c_hi",
						0
					],
					"destination": [
						"pc_hi",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pc_hi",
						0
					],
					"destination": [
						"outl",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"c_amt",
						0
					],
					"destination": [
						"pc_amt",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pc_amt",
						0
					],
					"destination": [
						"outl",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"c_chance",
						0
					],
					"destination": [
						"pc_chance",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pc_chance",
						0
					],
					"destination": [
						"outl",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"c_wob",
						0
					],
					"destination": [
						"pc_wob",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pc_wob",
						0
					],
					"destination": [
						"outl",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"c_trim",
						0
					],
					"destination": [
						"pc_trim",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pc_trim",
						0
					],
					"destination": [
						"outl",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"c_sign",
						1
					],
					"destination": [
						"pc_sign",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pc_sign",
						0
					],
					"destination": [
						"outl",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"c_grp",
						0
					],
					"destination": [
						"pc_group",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pc_group",
						0
					],
					"destination": [
						"outl",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"c_mode",
						0
					],
					"destination": [
						"tm",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tm",
						0
					],
					"destination": [
						"tm0",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tm",
						1
					],
					"destination": [
						"tm1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tm0",
						0
					],
					"destination": [
						"outl",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tm1",
						0
					],
					"destination": [
						"outl",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"c_del",
						0
					],
					"destination": [
						"dl",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"dl",
						0
					],
					"destination": [
						"outl",
						0
					]
				}
			}
		],
		"autosave": 0
	}
}