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
					"comment": "audio in",
					"index": 0,
					"numinlets": 0,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						20.0,
						20.0,
						30.0,
						30.0
					]
				}
			},
			{
				"box": {
					"id": "obj-5",
					"maxclass": "inlet",
					"comment": "control messages (<param> <value>, bypass 0/1)",
					"index": 0,
					"numinlets": 0,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						90.0,
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
					"comment": "audio out (35 ms latency)",
					"index": 0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						20.0,
						480.0,
						30.0,
						30.0
					]
				}
			},
			{
				"box": {
					"id": "obj-4",
					"maxclass": "newobj",
					"text": "route bypass band mod_type depth tmr smr_mean smr_range smr_cycle q p mix gain",
					"numinlets": 1,
					"numoutlets": 12,
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
						""
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"patching_rect": [
						20.0,
						70.0,
						150.0,
						22.0
					]
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
						500.0,
						500.0,
						56.0,
						22.0
					],
					"text": "autopattr",
					"varname": "fad_autopattr"
				}
			},
			{
				"box": {
					"id": "obj-9",
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
						20.0,
						20.0,
						330.0,
						152.0
					],
					"presentation": 1,
					"presentation_rect": [
						0.0,
						0.0,
						330.0,
						152.0
					],
					"proportion": 0.5
				}
			},
			{
				"box": {
					"id": "obj-10",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						20.0,
						20.0,
						80.0,
						21.0
					],
					"presentation": 1,
					"presentation_rect": [
						10.5,
						0.0,
						92.0,
						21.0
					],
					"text": "f_a_decorrelate"
				}
			},
			{
				"box": {
					"id": "obj-20",
					"maxclass": "live.numbox",
					"fontname": "Ableton Sans Light",
					"hint": "Octave band that carries the modulation, 1 (1-2 kHz) to 7 (8-16 kHz)",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						20.0,
						60.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						4.0,
						38.0,
						34.0,
						15.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								6.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "band",
							"parameter_mmax": 7.0,
							"parameter_mmin": 1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "band",
							"parameter_type": 1,
							"parameter_unitstyle": 0
						}
					},
					"varname": "band"
				}
			},
			{
				"box": {
					"id": "obj-22",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						20.0,
						30.0,
						70.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						-7.5,
						20.0,
						50.0,
						18.0
					],
					"text": "Band",
					"textjustification": 1,
					"varname": "lbl_band"
				}
			},
			{
				"box": {
					"id": "obj-23",
					"maxclass": "live.menu",
					"fontname": "Ableton Sans Light",
					"hint": "Per-bin gain (AM) or per-bin phase rotation (PM)",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"",
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						110.0,
						60.0,
						60.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						46.0,
						52.0,
						45.0,
						15.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_enum": [
								"AM",
								"PM"
							],
							"parameter_initial": [
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "mod_type",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 0,
							"parameter_shortname": "mod_type",
							"parameter_type": 2,
							"parameter_unitstyle": 0
						}
					},
					"varname": "mod_type"
				}
			},
			{
				"box": {
					"id": "obj-25",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						110.0,
						30.0,
						70.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						38.5,
						20.0,
						50.0,
						18.0
					],
					"text": "Mod",
					"textjustification": 1,
					"varname": "lbl_mod_type"
				}
			},
			{
				"box": {
					"id": "obj-26",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Modulation depth; above 1 the bin gain goes negative (not offered)",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						200.0,
						60.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						96.0,
						38.0,
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
							"parameter_longname": "depth",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "depth",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "depth"
				}
			},
			{
				"box": {
					"id": "obj-28",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						200.0,
						30.0,
						70.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						84.5,
						20.0,
						50.0,
						18.0
					],
					"text": "Depth",
					"textjustification": 1,
					"varname": "lbl_depth"
				}
			},
			{
				"box": {
					"id": "obj-29",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Temporal modulation rate in Hz; above about 4 the 2048-sample window is the limit",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						290.0,
						60.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						142.0,
						38.0,
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
							"parameter_longname": "tmr",
							"parameter_mmax": 4.0,
							"parameter_mmin": 0.1,
							"parameter_modmode": 3,
							"parameter_shortname": "tmr",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "tmr"
				}
			},
			{
				"box": {
					"id": "obj-31",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						290.0,
						30.0,
						70.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						130.5,
						20.0,
						50.0,
						18.0
					],
					"text": "TMR",
					"textjustification": 1,
					"varname": "lbl_tmr"
				}
			},
			{
				"box": {
					"id": "obj-32",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Mean spectral modulation rate, cycles per octave",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						380.0,
						60.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						188.0,
						38.0,
						27.0,
						43.0
					],
					"saved_attribute_attributes": {
						"activedialcolor": {
							"expression": ""
						},
						"valueof": {
							"parameter_initial": [
								4.5
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "smr_mean",
							"parameter_mmax": 12.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "smr_mean",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "smr_mean"
				}
			},
			{
				"box": {
					"id": "obj-34",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						380.0,
						30.0,
						70.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						176.5,
						20.0,
						50.0,
						18.0
					],
					"text": "SMR Mean",
					"textjustification": 1,
					"varname": "lbl_smr_mean"
				}
			},
			{
				"box": {
					"id": "obj-35",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Range of the spectral modulation rate",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						470.0,
						60.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						234.0,
						38.0,
						27.0,
						43.0
					],
					"saved_attribute_attributes": {
						"activedialcolor": {
							"expression": ""
						},
						"valueof": {
							"parameter_initial": [
								3.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "smr_range",
							"parameter_mmax": 12.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "smr_range",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "smr_range"
				}
			},
			{
				"box": {
					"id": "obj-37",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						470.0,
						30.0,
						70.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						222.5,
						20.0,
						50.0,
						18.0
					],
					"text": "SMR Range",
					"textjustification": 1,
					"varname": "lbl_smr_range"
				}
			},
			{
				"box": {
					"id": "obj-38",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Seconds for one sweep of the spectral modulation rate",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						560.0,
						60.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						280.0,
						38.0,
						27.0,
						43.0
					],
					"saved_attribute_attributes": {
						"activedialcolor": {
							"expression": ""
						},
						"valueof": {
							"parameter_initial": [
								8.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "smr_cycle",
							"parameter_mmax": 60.0,
							"parameter_mmin": 1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "smr_cycle",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "smr_cycle"
				}
			},
			{
				"box": {
					"id": "obj-40",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						560.0,
						30.0,
						70.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						268.5,
						20.0,
						50.0,
						18.0
					],
					"text": "SMR Cycle",
					"textjustification": 1,
					"varname": "lbl_smr_cycle"
				}
			},
			{
				"box": {
					"id": "obj-41",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Starting phase of the temporal modulation, radians",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						650.0,
						60.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						4.0,
						100.0,
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
							"parameter_longname": "q",
							"parameter_mmax": 6.283185307,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "q",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "q"
				}
			},
			{
				"box": {
					"id": "obj-43",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						650.0,
						30.0,
						70.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						-7.5,
						82.0,
						50.0,
						18.0
					],
					"text": "Phase q",
					"textjustification": 1,
					"varname": "lbl_q"
				}
			},
			{
				"box": {
					"id": "obj-44",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Starting phase of the spectral modulation sweep, radians",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						740.0,
						60.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						50.0,
						100.0,
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
							"parameter_longname": "p",
							"parameter_mmax": 6.283185307,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "p",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "p"
				}
			},
			{
				"box": {
					"id": "obj-46",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						740.0,
						30.0,
						70.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						38.5,
						82.0,
						50.0,
						18.0
					],
					"text": "Phase p",
					"textjustification": 1,
					"varname": "lbl_p"
				}
			},
			{
				"box": {
					"id": "obj-47",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Wet / dry. The dry path is delayed to match the wet path",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						830.0,
						60.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						96.0,
						100.0,
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
							"parameter_longname": "mix",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "mix",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "mix"
				}
			},
			{
				"box": {
					"id": "obj-49",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						830.0,
						30.0,
						70.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						84.5,
						82.0,
						50.0,
						18.0
					],
					"text": "Mix",
					"textjustification": 1,
					"varname": "lbl_mix"
				}
			},
			{
				"box": {
					"id": "obj-50",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Output trim after the tanh safety ceiling",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						920.0,
						60.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						142.0,
						100.0,
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
							"parameter_longname": "gain",
							"parameter_mmax": 1.5,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "gain",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "gain"
				}
			},
			{
				"box": {
					"id": "obj-52",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						920.0,
						30.0,
						70.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						130.5,
						82.0,
						50.0,
						18.0
					],
					"text": "Gain",
					"textjustification": 1,
					"varname": "lbl_gain"
				}
			},
			{
				"box": {
					"id": "obj-53",
					"maxclass": "live.text",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"mode": 1,
					"hint": "Bypass: mutes the output (a generator's neutral is silence), slewed over about 5 ms",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"parameter_enable": 1,
					"patching_rect": [
						1010.0,
						60.0,
						40.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						286.0,
						2.0,
						40.0,
						15.0
					],
					"text": "Bypass",
					"texton": "Bypass",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_enum": [
								"Off",
								"On"
							],
							"parameter_initial": [
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "bypass",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 0,
							"parameter_shortname": "bypass",
							"parameter_type": 1,
							"parameter_unitstyle": 0
						}
					},
					"varname": "bypass"
				}
			},
			{
				"box": {
					"id": "obj-3",
					"maxclass": "newobj",
					"text": "pfft~ f_a_decorrelate_inner 2048 4 0 0 args ---",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"signal"
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"patching_rect": [
						20.0,
						290.0,
						230.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-100",
					"maxclass": "newobj",
					"text": "delay~ 1536 1536",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"signal"
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"patching_rect": [
						280.0,
						290.0,
						110.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-101",
					"maxclass": "newobj",
					"text": "*~",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"signal"
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"patching_rect": [
						20.0,
						330.0,
						40.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-102",
					"maxclass": "newobj",
					"text": "!-~ 1.",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"signal"
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"patching_rect": [
						100.0,
						330.0,
						50.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-103",
					"maxclass": "newobj",
					"text": "*~",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"signal"
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"patching_rect": [
						280.0,
						330.0,
						40.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-104",
					"maxclass": "newobj",
					"text": "+~",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"signal"
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"patching_rect": [
						20.0,
						360.0,
						40.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-105",
					"maxclass": "newobj",
					"text": "tanh~",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"signal"
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"patching_rect": [
						20.0,
						390.0,
						50.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-106",
					"maxclass": "newobj",
					"text": "*~",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"signal"
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"patching_rect": [
						20.0,
						420.0,
						40.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-107",
					"maxclass": "newobj",
					"text": "!-~ 1.",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"signal"
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"patching_rect": [
						100.0,
						420.0,
						50.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-108",
					"maxclass": "newobj",
					"text": "*~",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"signal"
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"patching_rect": [
						20.0,
						450.0,
						40.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-109",
					"maxclass": "newobj",
					"text": "*~",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"signal"
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"patching_rect": [
						280.0,
						450.0,
						40.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-110",
					"maxclass": "newobj",
					"text": "+~",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"signal"
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"patching_rect": [
						20.0,
						480.0,
						40.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-111",
					"maxclass": "newobj",
					"text": "line~",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"signal"
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"patching_rect": [
						100.0,
						380.0,
						50.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-112",
					"maxclass": "message",
					"text": "$1 20",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"patching_rect": [
						100.0,
						360.0,
						50.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-113",
					"maxclass": "newobj",
					"text": "line~",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"signal"
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"patching_rect": [
						160.0,
						380.0,
						50.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-114",
					"maxclass": "message",
					"text": "$1 20",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"patching_rect": [
						160.0,
						360.0,
						50.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-115",
					"maxclass": "newobj",
					"text": "line~",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"signal"
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"patching_rect": [
						220.0,
						380.0,
						50.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-116",
					"maxclass": "message",
					"text": "$1 5",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"patching_rect": [
						220.0,
						360.0,
						50.0,
						22.0
					]
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"id": "frag-lb",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"bang"
					],
					"patching_rect": [
						20.0,
						865.0,
						50,
						23
					],
					"text": "loadbang"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"id": "frag-c-band",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						20.0,
						1005.0,
						400,
						20.0
					],
					"text": "band lookup: edges + bin geomean per band (2048/44.1k, measured in the spike)"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"id": "frag-coll",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 4,
					"outlettype": [
						"anything",
						"float",
						"float",
						"float"
					],
					"patching_rect": [
						150.0,
						1025.0,
						120,
						23
					],
					"text": "coll bandtable 1"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"id": "frag-f-lo",
					"maxclass": "flonum",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"float",
						"float"
					],
					"patching_rect": [
						280.0,
						1025.0,
						60,
						23
					],
					"text": "flonum"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"id": "frag-f-hi",
					"maxclass": "flonum",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"float",
						"float"
					],
					"patching_rect": [
						350.0,
						1025.0,
						60,
						23
					],
					"text": "flonum"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"id": "frag-f-gm",
					"maxclass": "flonum",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"float",
						"float"
					],
					"patching_rect": [
						420.0,
						1025.0,
						60,
						23
					],
					"text": "flonum"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"id": "frag-mb1",
					"maxclass": "message",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						150.0,
						1075.0,
						160,
						23
					],
					"text": "store 1 1000 2000 1468.6"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"id": "frag-mb2",
					"maxclass": "message",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						150.0,
						1097.0,
						160,
						23
					],
					"text": "store 2 1400 2800 2070.6"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"id": "frag-mb3",
					"maxclass": "message",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						150.0,
						1119.0,
						160,
						23
					],
					"text": "store 3 2000 4000 2935.9"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"id": "frag-mb4",
					"maxclass": "message",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						150.0,
						1141.0,
						160,
						23
					],
					"text": "store 4 2800 5700 4169.1"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"id": "frag-mb5",
					"maxclass": "message",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						150.0,
						1163.0,
						160,
						23
					],
					"text": "store 5 4000 8000 5882.7"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"id": "frag-mb6",
					"maxclass": "message",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						150.0,
						1185.0,
						160,
						23
					],
					"text": "store 6 5700 11000 8200.8"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"id": "frag-mb7",
					"maxclass": "message",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						150.0,
						1207.0,
						160,
						23
					],
					"text": "store 7 8000 16000 11776.4"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"id": "frag-c-sweep",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						20.0,
						1405.0,
						480,
						20.0
					],
					"text": "gain/phase curve sweeps: uzi/expr/peek~ into buffers T7a-style; AM gain curve + PM phase curve, both written every 50 ms; mod_type selects inside the inner subpatch"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"id": "frag-buf-g",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 2,
					"outlettype": [
						"signal"
					],
					"patching_rect": [
						20.0,
						1435.0,
						130,
						23
					],
					"text": "buffer~ ---fad_gain 100"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"id": "frag-buf-p",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 2,
					"outlettype": [
						"signal"
					],
					"patching_rect": [
						160.0,
						1435.0,
						130,
						23
					],
					"text": "buffer~ ---fad_phase 100"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"id": "frag-metro",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"bang",
						"bang"
					],
					"patching_rect": [
						20.0,
						1465.0,
						60,
						23
					],
					"text": "metro 50 @active 1"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"id": "frag-t3",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 5,
					"outlettype": [
						"bang",
						"bang",
						"bang",
						"bang",
						"bang"
					],
					"patching_rect": [
						20.0,
						1490.0,
						70,
						23
					],
					"text": "t b b b b b"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"id": "frag-gen-ctrl",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"signal",
						"signal"
					],
					"patching_rect": [
						300.0,
						1465.0,
						400,
						23.0
					],
					"text": "gen~",
					"patcher": {
						"boxes": [
							{
								"box": {
									"fontname": "Ableton Sans Light",
									"fontsize": 12.0,
									"id": "gc-in",
									"maxclass": "newobj",
									"numinlets": 1,
									"numoutlets": 1,
									"outlettype": [
										"signal"
									],
									"patching_rect": [
										20,
										20,
										40,
										23.0
									],
									"text": "in 1"
								}
							},
							{
								"box": {
									"fontname": "Ableton Sans Light",
									"fontsize": 12.0,
									"id": "gc-cb",
									"maxclass": "codebox",
									"numinlets": 1,
									"numoutlets": 2,
									"outlettype": [
										"signal",
										"signal"
									],
									"patching_rect": [
										20,
										50,
										350,
										23.0
									],
									"text": "codebox",
									"code": "// control supplier (from T7a obj-600, always-run: a processor has no\n// stimulus reset cycle). Outputs phase_base = q + tmr*t, s_env = S(t).\nParam tmr(1.0);\nParam smr_mean(4.5);\nParam smr_range(3.0);\nParam smr_cycle(8.0);\nParam q(0.0);\nParam p(0.0);\n\nHistory t(0);\ns_env = smr_mean + smr_range * sin(p + twopi * t / smr_cycle);\nphase_base = q + tmr * t;\nt = t + 1.0 / samplerate;\n\nout1 = phase_base;\nout2 = s_env;\n"
								}
							},
							{
								"box": {
									"fontname": "Ableton Sans Light",
									"fontsize": 12.0,
									"id": "gc-o1",
									"maxclass": "newobj",
									"numinlets": 1,
									"numoutlets": 1,
									"outlettype": [
										"signal"
									],
									"patching_rect": [
										20,
										100,
										40,
										23.0
									],
									"text": "out 1"
								}
							},
							{
								"box": {
									"fontname": "Ableton Sans Light",
									"fontsize": 12.0,
									"id": "gc-o2",
									"maxclass": "newobj",
									"numinlets": 1,
									"numoutlets": 1,
									"outlettype": [
										"signal"
									],
									"patching_rect": [
										100,
										100,
										40,
										23.0
									],
									"text": "out 2"
								}
							}
						],
						"lines": [
							{
								"patchline": {
									"destination": [
										"gc-cb",
										0
									],
									"source": [
										"gc-in",
										0
									]
								}
							},
							{
								"patchline": {
									"destination": [
										"gc-o1",
										0
									],
									"source": [
										"gc-cb",
										0
									]
								}
							},
							{
								"patchline": {
									"destination": [
										"gc-o2",
										0
									],
									"source": [
										"gc-cb",
										1
									]
								}
							}
						]
					}
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"id": "frag-pre-tmr",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"anything"
					],
					"patching_rect": [
						300.0,
						1440.0,
						90,
						23
					],
					"text": "prepend tmr"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"id": "frag-pre-smr_mean",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"anything"
					],
					"patching_rect": [
						300.0,
						1440.0,
						90,
						23
					],
					"text": "prepend smr_mean"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"id": "frag-pre-smr_range",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"anything"
					],
					"patching_rect": [
						300.0,
						1440.0,
						90,
						23
					],
					"text": "prepend smr_range"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"id": "frag-pre-smr_cycle",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"anything"
					],
					"patching_rect": [
						300.0,
						1440.0,
						90,
						23
					],
					"text": "prepend smr_cycle"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"id": "frag-pre-q",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"anything"
					],
					"patching_rect": [
						300.0,
						1440.0,
						90,
						23
					],
					"text": "prepend q"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"id": "frag-pre-p",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"anything"
					],
					"patching_rect": [
						300.0,
						1440.0,
						90,
						23
					],
					"text": "prepend p"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"id": "frag-snap-pb",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"signal"
					],
					"patching_rect": [
						300.0,
						1525.0,
						60,
						23
					],
					"text": "snapshot~"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"id": "frag-snap-se",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"signal"
					],
					"patching_rect": [
						370.0,
						1525.0,
						60,
						23
					],
					"text": "snapshot~"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"id": "frag-uzi-g",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 3,
					"outlettype": [
						"bang",
						"bang",
						"int"
					],
					"patching_rect": [
						20.0,
						1555.0,
						70,
						23
					],
					"text": "uzi 1024 0"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"id": "frag-uzi-p",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 3,
					"outlettype": [
						"bang",
						"bang",
						"int"
					],
					"patching_rect": [
						160.0,
						1555.0,
						70,
						23
					],
					"text": "uzi 1024 0"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"id": "frag-expr-g",
					"maxclass": "newobj",
					"numinlets": 9,
					"numoutlets": 1,
					"outlettype": [
						"float"
					],
					"patching_rect": [
						20.0,
						1615.0,
						900,
						23
					],
					"text": "expr 1.+($f9==0)*(($f1*44100/2048>=$f6)*($f1*44100/2048<$f7))*$f5*sin(6.283185307*($f2+(ln(($f1*44100/2048)/$f4)/ln(2))*$f3))"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"id": "frag-expr-p",
					"maxclass": "newobj",
					"numinlets": 9,
					"numoutlets": 1,
					"outlettype": [
						"float"
					],
					"patching_rect": [
						20.0,
						1645.0,
						900,
						23
					],
					"text": "expr ($f9==1)*((($f1*44100/2048)>=$f6)*(($f1*44100/2048)<$f7))*1.5707963*(1.+$f5*sin(6.283185307*($f2+(ln(($f1*44100/2048)/$f4)/ln(2))*$f3)))"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"id": "frag-t-ii-g",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"int",
						"int"
					],
					"patching_rect": [
						20.0,
						1585.0,
						40,
						23
					],
					"text": "t i i"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"id": "frag-pack-g",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"list"
					],
					"patching_rect": [
						20.0,
						1675.0,
						60,
						23
					],
					"text": "pack 0. 0."
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"id": "frag-peek-g",
					"maxclass": "newobj",
					"numinlets": 3,
					"numoutlets": 1,
					"outlettype": [
						"signal"
					],
					"patching_rect": [
						20.0,
						1705.0,
						100,
						23
					],
					"text": "peek~ ---fad_gain"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"id": "frag-t-ii-p",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"int",
						"int"
					],
					"patching_rect": [
						160.0,
						1585.0,
						40,
						23
					],
					"text": "t i i"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"id": "frag-pack-p",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"list"
					],
					"patching_rect": [
						160.0,
						1675.0,
						60,
						23
					],
					"text": "pack 0. 0."
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"id": "frag-peek-p",
					"maxclass": "newobj",
					"numinlets": 3,
					"numoutlets": 1,
					"outlettype": [
						"signal"
					],
					"patching_rect": [
						160.0,
						1705.0,
						100,
						23
					],
					"text": "peek~ ---fad_phase"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"id": "frag-sr-expr-g",
					"maxclass": "message",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						700.0,
						1615.0,
						70,
						23
					],
					"text": "44100."
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"id": "frag-sr-expr-p",
					"maxclass": "message",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						700.0,
						1645.0,
						70,
						23
					],
					"text": "44100."
				}
			},
			{
				"box": {
					"id": "frag-defer",
					"maxclass": "newobj",
					"text": "deferlow",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						150.0,
						985.0,
						60,
						22.0
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0
				}
			},
			{
				"box": {
					"id": "frag-unpack",
					"maxclass": "newobj",
					"text": "unpack f f f",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"float",
						"float",
						"float"
					],
					"patching_rect": [
						150.0,
						1065.0,
						90,
						22.0
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0
				}
			}
		],
		"lines": [
			{
				"patchline": {
					"source": [
						"obj-5",
						0
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
						"frag-defer",
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
						"frag-expr-g",
						8
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
						"frag-expr-p",
						8
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
						"frag-expr-g",
						4
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
						"frag-expr-p",
						4
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-4",
						4
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
						"obj-29",
						0
					],
					"destination": [
						"frag-pre-tmr",
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
						"frag-pre-smr_mean",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-4",
						6
					],
					"destination": [
						"obj-35",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-35",
						0
					],
					"destination": [
						"frag-pre-smr_range",
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
						"obj-38",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-38",
						0
					],
					"destination": [
						"frag-pre-smr_cycle",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-4",
						8
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
						"frag-pre-q",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-4",
						9
					],
					"destination": [
						"obj-44",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-44",
						0
					],
					"destination": [
						"frag-pre-p",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-4",
						10
					],
					"destination": [
						"obj-47",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-47",
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
						"obj-4",
						11
					],
					"destination": [
						"obj-50",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-50",
						0
					],
					"destination": [
						"obj-114",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-53",
						0
					],
					"destination": [
						"obj-116",
						0
					]
				}
			},
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
						"obj-1",
						0
					],
					"destination": [
						"obj-100",
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
						"obj-101",
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
						"obj-101",
						1
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
						"obj-102",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-100",
						0
					],
					"destination": [
						"obj-103",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-102",
						0
					],
					"destination": [
						"obj-103",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-101",
						0
					],
					"destination": [
						"obj-104",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-103",
						0
					],
					"destination": [
						"obj-104",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-112",
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
						"obj-114",
						0
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
						"obj-116",
						0
					],
					"destination": [
						"obj-115",
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
						"obj-106",
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
						"obj-106",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-104",
						0
					],
					"destination": [
						"obj-105",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-115",
						0
					],
					"destination": [
						"obj-107",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-106",
						0
					],
					"destination": [
						"obj-108",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-107",
						0
					],
					"destination": [
						"obj-108",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-100",
						0
					],
					"destination": [
						"obj-109",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-115",
						0
					],
					"destination": [
						"obj-109",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-108",
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
						"obj-109",
						0
					],
					"destination": [
						"obj-110",
						1
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
						"obj-2",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-lb",
						0
					],
					"destination": [
						"frag-mb1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-mb1",
						0
					],
					"destination": [
						"frag-coll",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-lb",
						0
					],
					"destination": [
						"frag-mb2",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-mb2",
						0
					],
					"destination": [
						"frag-coll",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-lb",
						0
					],
					"destination": [
						"frag-mb3",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-mb3",
						0
					],
					"destination": [
						"frag-coll",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-lb",
						0
					],
					"destination": [
						"frag-mb4",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-mb4",
						0
					],
					"destination": [
						"frag-coll",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-lb",
						0
					],
					"destination": [
						"frag-mb5",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-mb5",
						0
					],
					"destination": [
						"frag-coll",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-lb",
						0
					],
					"destination": [
						"frag-mb6",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-mb6",
						0
					],
					"destination": [
						"frag-coll",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-lb",
						0
					],
					"destination": [
						"frag-mb7",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-mb7",
						0
					],
					"destination": [
						"frag-coll",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-metro",
						0
					],
					"destination": [
						"frag-t3",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-pre-tmr",
						0
					],
					"destination": [
						"frag-gen-ctrl",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-pre-smr_mean",
						0
					],
					"destination": [
						"frag-gen-ctrl",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-pre-smr_range",
						0
					],
					"destination": [
						"frag-gen-ctrl",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-pre-smr_cycle",
						0
					],
					"destination": [
						"frag-gen-ctrl",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-pre-q",
						0
					],
					"destination": [
						"frag-gen-ctrl",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-pre-p",
						0
					],
					"destination": [
						"frag-gen-ctrl",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-t3",
						4
					],
					"destination": [
						"frag-snap-pb",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-t3",
						3
					],
					"destination": [
						"frag-snap-se",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-gen-ctrl",
						0
					],
					"destination": [
						"frag-snap-pb",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-gen-ctrl",
						1
					],
					"destination": [
						"frag-snap-se",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-t3",
						2
					],
					"destination": [
						"frag-uzi-p",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-t3",
						1
					],
					"destination": [
						"frag-uzi-g",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-uzi-g",
						2
					],
					"destination": [
						"frag-t-ii-g",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-t-ii-g",
						1
					],
					"destination": [
						"frag-expr-g",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-t-ii-g",
						0
					],
					"destination": [
						"frag-pack-g",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-expr-g",
						0
					],
					"destination": [
						"frag-pack-g",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-pack-g",
						0
					],
					"destination": [
						"frag-peek-g",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-uzi-p",
						2
					],
					"destination": [
						"frag-t-ii-p",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-t-ii-p",
						1
					],
					"destination": [
						"frag-expr-p",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-t-ii-p",
						0
					],
					"destination": [
						"frag-pack-p",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-expr-p",
						0
					],
					"destination": [
						"frag-pack-p",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-pack-p",
						0
					],
					"destination": [
						"frag-peek-p",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-snap-pb",
						0
					],
					"destination": [
						"frag-expr-g",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-snap-se",
						0
					],
					"destination": [
						"frag-expr-g",
						2
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-f-gm",
						0
					],
					"destination": [
						"frag-expr-g",
						3
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-f-lo",
						0
					],
					"destination": [
						"frag-expr-g",
						5
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-f-hi",
						0
					],
					"destination": [
						"frag-expr-g",
						6
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-sr-expr-g",
						0
					],
					"destination": [
						"frag-expr-g",
						7
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-lb",
						0
					],
					"destination": [
						"frag-sr-expr-g",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-snap-pb",
						0
					],
					"destination": [
						"frag-expr-p",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-snap-se",
						0
					],
					"destination": [
						"frag-expr-p",
						2
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-f-gm",
						0
					],
					"destination": [
						"frag-expr-p",
						3
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-f-lo",
						0
					],
					"destination": [
						"frag-expr-p",
						5
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-f-hi",
						0
					],
					"destination": [
						"frag-expr-p",
						6
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-sr-expr-p",
						0
					],
					"destination": [
						"frag-expr-p",
						7
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-lb",
						0
					],
					"destination": [
						"frag-sr-expr-p",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-defer",
						0
					],
					"destination": [
						"frag-coll",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-coll",
						0
					],
					"destination": [
						"frag-unpack",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-unpack",
						0
					],
					"destination": [
						"frag-f-lo",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-unpack",
						1
					],
					"destination": [
						"frag-f-hi",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"frag-unpack",
						2
					],
					"destination": [
						"frag-f-gm",
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
						"obj-53",
						0
					]
				}
			}
		],
		"parameters": {
			"obj-20": [
				"band",
				"band",
				0
			],
			"obj-23": [
				"mod_type",
				"mod_type",
				0
			],
			"obj-26": [
				"depth",
				"depth",
				0
			],
			"obj-29": [
				"tmr",
				"tmr",
				0
			],
			"obj-32": [
				"smr_mean",
				"smr_mean",
				0
			],
			"obj-35": [
				"smr_range",
				"smr_range",
				0
			],
			"obj-38": [
				"smr_cycle",
				"smr_cycle",
				0
			],
			"obj-41": [
				"q",
				"q",
				0
			],
			"obj-44": [
				"p",
				"p",
				0
			],
			"obj-47": [
				"mix",
				"mix",
				0
			],
			"obj-50": [
				"gain",
				"gain",
				0
			],
			"obj-53": [
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