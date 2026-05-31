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
			572.0,
			122.0,
			584.0,
			852.0
		],
		"openinpresentation": 1,
		"boxes": [
			{
				"box": {
					"id": "obj-18",
					"maxclass": "attrui",
					"attr": "m_gain",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						550.0000163912773,
						166.00000494718552,
						133.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-19",
					"maxclass": "attrui",
					"attr": "m_gamma",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						527.5000160932541,
						124.00000369548798,
						150.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-16",
					"maxclass": "attrui",
					"attr": "m_lift",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						540.0000160932541,
						88.66666930913925,
						122.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"activedialcolor": [
						0.8862745098039215,
						0.8941176470588236,
						0.9058823529411765,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Master gain",
					"id": "obj-15",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "jit.gl.pix_AA::m_gain",
					"parameter_enable": 1,
					"patching_rect": [
						433.33334624767303,
						186.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						116.0,
						115.5,
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
							"parameter_longname": "m_gain",
							"parameter_mmax": 1.0,
							"parameter_mmin": -1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "m_gain",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "m_gain"
				}
			},
			{
				"box": {
					"activedialcolor": [
						0.9490196078431372,
						0.9568627450980393,
						0.9647058823529412,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Master gamma",
					"id": "obj-14",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "jit.gl.pix_AA::m_gamma",
					"parameter_enable": 1,
					"patching_rect": [
						433.33334624767303,
						124.00000369548798,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						116.0,
						71.5,
						27.0,
						43.0
					],
					"saved_attribute_attributes": {
						"activedialcolor": {
							"expression": ""
						},
						"valueof": {
							"parameter_initial": [
								0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "m_gamma",
							"parameter_mmax": 1.0,
							"parameter_mmin": -1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "m_gamma",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "m_gamma"
				}
			},
			{
				"box": {
					"id": "obj-3",
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
						708.6666877865791,
						248.66667407751083,
						56.0,
						22.0
					],
					"restore": {
						"b_gain": [
							0.0
						],
						"b_gamma": [
							0.0
						],
						"b_lift": [
							0.0
						],
						"bypass": [
							0
						],
						"g_gain": [
							0.005025125628140614
						],
						"g_gamma": [
							0.005025125628140614
						],
						"g_lift": [
							0.005025125628140614
						],
						"m_gain": [
							0.0
						],
						"m_gamma": [
							0.0
						],
						"m_lift": [
							0.0
						],
						"r_gain": [
							0.005025125628140614
						],
						"r_gamma": [
							0.0
						],
						"r_lift": [
							0.0
						]
					},
					"text": "autopattr",
					"varname": "u905020188"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"id": "obj-17",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						142.0,
						322.0,
						146.0,
						21.0
					],
					"presentation": 1,
					"presentation_rect": [
						1.5,
						3.5,
						91.0,
						21.0
					],
					"text": "Channel Grader"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"id": "obj-10",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						54.0,
						119.0,
						28.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						1.5,
						119.0,
						28.0,
						18.0
					],
					"text": "Gain"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"id": "obj-9",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						33.5,
						69.0,
						44.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						3.0,
						74.0,
						29.0,
						18.0
					],
					"text": "Gam"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"id": "obj-7",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						62.5,
						34.0,
						24.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						5.5,
						29.0,
						24.0,
						18.0
					],
					"text": "Lift"
				}
			},
			{
				"box": {
					"filename": "bypass_toggle.js",
					"hint": "Bypass",
					"id": "obj-4",
					"maxclass": "jsui",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"param_connect": "jit.gl.pix_AA::bypass",
					"parameter_enable": 1,
					"patching_rect": [
						189.5,
						11.0,
						18.0,
						12.0
					],
					"presentation": 1,
					"presentation_rect": [
						129.0,
						7.0,
						18.0,
						12.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_invisible": 1,
							"parameter_longname": "bypass",
							"parameter_mmax": 1.0,
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
					"comment": "",
					"id": "obj-8",
					"index": 0,
					"maxclass": "outlet",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						509.0,
						493.0,
						30.0,
						30.0
					]
				}
			},
			{
				"box": {
					"id": "obj-74",
					"maxclass": "newobj",
					"numinlets": 14,
					"numoutlets": 14,
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
						""
					],
					"patching_rect": [
						558.0,
						365.0,
						580.0,
						22.0
					],
					"text": "route bypass r_lift r_gamma r_gain g_lift g_gamma g_gain b_lift b_gamma b_gain m_lift m_gamma m_gain"
				}
			},
			{
				"box": {
					"comment": "",
					"id": "obj-6",
					"index": 0,
					"maxclass": "inlet",
					"numinlets": 0,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						558.0000166296959,
						332.6666765809059,
						30.0,
						30.0
					]
				}
			},
			{
				"box": {
					"activedialcolor": [
						0.101960784313725,
						0.490196078431373,
						0.945098039215686,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Blue gain",
					"id": "obj-71",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "jit.gl.pix_AA::b_gain",
					"parameter_enable": 1,
					"patching_rect": [
						155.5,
						96.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						87.0,
						115.5,
						27.0,
						43.0
					],
					"saved_attribute_attributes": {
						"activedialcolor": {
							"expression": "themecolor.live_prelisten"
						},
						"valueof": {
							"parameter_initial": [
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "b_gain",
							"parameter_mmax": 1.0,
							"parameter_mmin": -1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "b_gain",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "b_gain"
				}
			},
			{
				"box": {
					"activedialcolor": [
						0.101960784313725,
						0.490196078431373,
						0.945098039215686,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Blue gamma",
					"id": "obj-72",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "jit.gl.pix_AA::b_gamma",
					"parameter_enable": 1,
					"patching_rect": [
						155.5,
						52.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						87.0,
						71.5,
						27.0,
						43.0
					],
					"saved_attribute_attributes": {
						"activedialcolor": {
							"expression": "themecolor.live_prelisten"
						},
						"valueof": {
							"parameter_initial": [
								0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "b_gamma",
							"parameter_mmax": 1.0,
							"parameter_mmin": -1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "b_gamma",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "b_gamma"
				}
			},
			{
				"box": {
					"activedialcolor": [
						0.101960784313725,
						0.490196078431373,
						0.945098039215686,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Blue lift",
					"id": "obj-73",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "jit.gl.pix_AA::b_lift",
					"parameter_enable": 1,
					"patching_rect": [
						155.5,
						11.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						87.0,
						25.5,
						27.0,
						43.0
					],
					"saved_attribute_attributes": {
						"activedialcolor": {
							"expression": "themecolor.live_prelisten"
						},
						"valueof": {
							"parameter_initial": [
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "b_lift",
							"parameter_mmax": 1.0,
							"parameter_mmin": -1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "b_lift",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopuplabel": 1,
					"varname": "b_lift"
				}
			},
			{
				"box": {
					"activedialcolor": [
						0.0,
						0.854901960784314,
						0.282352941176471,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Green gain",
					"id": "obj-67",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "jit.gl.pix_AA::g_gain",
					"parameter_enable": 1,
					"patching_rect": [
						124.5,
						96.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						58.0,
						115.5,
						27.0,
						43.0
					],
					"saved_attribute_attributes": {
						"activedialcolor": {
							"expression": "themecolor.live_macro_assignment"
						},
						"valueof": {
							"parameter_initial": [
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "g_gain",
							"parameter_mmax": 1.0,
							"parameter_mmin": -1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "g_gain",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "g_gain"
				}
			},
			{
				"box": {
					"activedialcolor": [
						0.0,
						0.854901960784314,
						0.282352941176471,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Green gamma",
					"id": "obj-68",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "jit.gl.pix_AA::g_gamma",
					"parameter_enable": 1,
					"patching_rect": [
						124.5,
						52.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						58.0,
						71.5,
						27.0,
						43.0
					],
					"saved_attribute_attributes": {
						"activedialcolor": {
							"expression": "themecolor.live_macro_assignment"
						},
						"valueof": {
							"parameter_initial": [
								0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "g_gamma",
							"parameter_mmax": 1.0,
							"parameter_mmin": -1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "g_gamma",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "g_gamma"
				}
			},
			{
				"box": {
					"activedialcolor": [
						0.0,
						0.854901960784314,
						0.282352941176471,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Green lift",
					"id": "obj-69",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "jit.gl.pix_AA::g_lift",
					"parameter_enable": 1,
					"patching_rect": [
						124.5,
						11.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						58.0,
						25.5,
						27.0,
						43.0
					],
					"saved_attribute_attributes": {
						"activedialcolor": {
							"expression": "themecolor.live_macro_assignment"
						},
						"valueof": {
							"parameter_initial": [
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "g_lift",
							"parameter_mmax": 1.0,
							"parameter_mmin": -1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "live.dial",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "g_lift"
				}
			},
			{
				"box": {
					"activedialcolor": [
						1.0,
						0.349019607843137,
						0.372549019607843,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "R gain",
					"id": "obj-59",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "jit.gl.pix_AA::r_gain",
					"parameter_enable": 1,
					"patching_rect": [
						94.5,
						96.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						28.5,
						115.5,
						27.0,
						43.0
					],
					"saved_attribute_attributes": {
						"activedialcolor": {
							"expression": "themecolor.live_record"
						},
						"valueof": {
							"parameter_initial": [
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "r_gain",
							"parameter_mmax": 1.0,
							"parameter_mmin": -1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "r_gain",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "r_gain"
				}
			},
			{
				"box": {
					"activedialcolor": [
						1.0,
						0.349019607843137,
						0.372549019607843,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Red gamma",
					"id": "obj-58",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "jit.gl.pix_AA::r_gamma",
					"parameter_enable": 1,
					"patching_rect": [
						94.5,
						52.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						28.5,
						71.5,
						27.0,
						43.0
					],
					"saved_attribute_attributes": {
						"activedialcolor": {
							"expression": "themecolor.live_record"
						},
						"valueof": {
							"parameter_initial": [
								0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "r_gamma",
							"parameter_mmax": 1.0,
							"parameter_mmin": -1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "r_gamma",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "r_gamma"
				}
			},
			{
				"box": {
					"activedialcolor": [
						1.0,
						0.349019607843137,
						0.372549019607843,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Red lift",
					"id": "obj-49",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "jit.gl.pix_AA::r_lift",
					"parameter_enable": 1,
					"patching_rect": [
						94.5,
						11.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						28.5,
						25.5,
						27.0,
						43.0
					],
					"saved_attribute_attributes": {
						"activedialcolor": {
							"expression": "themecolor.live_record"
						},
						"valueof": {
							"parameter_initial": [
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "r_lift",
							"parameter_mmax": 1.0,
							"parameter_mmin": -1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "r_lift",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "r_lift"
				}
			},
			{
				"box": {
					"id": "obj-38",
					"maxclass": "attrui",
					"attr": "b_gain",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						240.0,
						131.5,
						129.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-39",
					"maxclass": "attrui",
					"attr": "b_gamma",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						240.0,
						98.5,
						147.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-40",
					"maxclass": "attrui",
					"attr": "b_lift",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						239.0,
						67.5,
						119.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-37",
					"maxclass": "attrui",
					"attr": "g_gain",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						174.0,
						254.0,
						129.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-36",
					"maxclass": "attrui",
					"attr": "g_lift",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						174.0,
						186.0,
						119.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-35",
					"maxclass": "attrui",
					"attr": "r_gain",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						-26.0,
						231.5,
						127.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-34",
					"maxclass": "attrui",
					"attr": "r_gamma",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						-34.5,
						196.5,
						144.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-33",
					"maxclass": "attrui",
					"attr": "r_lift",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						-20.5,
						161.0,
						116.0,
						22.0
					],
					"style": ""
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
						488.0,
						33.5,
						131.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-21",
					"maxclass": "attrui",
					"attr": "g_gamma",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						170.0,
						221.0,
						147.0,
						22.0
					],
					"style": ""
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
							951.0,
							137.0,
							621.0,
							880.0
						],
						"boxes": [
							{
								"box": {
									"id": "obj-7",
									"maxclass": "newobj",
									"numinlets": 0,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										31.0,
										73.0,
										28.0,
										22.0
									],
									"text": "in 1"
								}
							},
							{
								"box": {
									"code": "Param r_lift(0.0);  Param r_gamma(0.0);  Param r_gain(0.0);\nParam g_lift(0.0);  Param g_gamma(0.0);  Param g_gain(0.0);\nParam b_lift(0.0);  Param b_gamma(0.0);  Param b_gain(0.0);\nParam m_lift(0.0);  Param m_gamma(0.0);  Param m_gain(0.0);\nParam bypass(0.0);\n\nuv = norm;\nsrc = sample(in1, uv);\nr = src.r; g = src.g; b = src.b;\n\n// per-channel grade\nrg = pow(2.0, r_gain) * pow(clamp(r + r_lift, 0.0, 1.0), 1.0 / max(pow(2.0, r_gamma), 0.001));\ngg = pow(2.0, g_gain) * pow(clamp(g + g_lift, 0.0, 1.0), 1.0 / max(pow(2.0, g_gamma), 0.001));\nbg = pow(2.0, b_gain) * pow(clamp(b + b_lift, 0.0, 1.0), 1.0 / max(pow(2.0, b_gamma), 0.001));\n\n// master grade \u2014 sequential on top of per-channel result\nmg = pow(2.0, m_gain);\nme = 1.0 / max(pow(2.0, m_gamma), 0.001);\nro = mg * pow(clamp(rg + m_lift, 0.0, 1.0), me);\ngo = mg * pow(clamp(gg + m_lift, 0.0, 1.0), me);\nbo = mg * pow(clamp(bg + m_lift, 0.0, 1.0), me);\n\neffective = 1.0 - bypass;\nout1 = vec(mix(r, ro, effective),\n           mix(g, go, effective),\n           mix(b, bo, effective),\n           src.a);",
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
										22.0,
										127.0,
										561.0,
										590.0
									]
								}
							},
							{
								"box": {
									"id": "obj-4",
									"maxclass": "newobj",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										27.5,
										758.0,
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
										"obj-4",
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
										"obj-5",
										0
									],
									"source": [
										"obj-7",
										0
									]
								}
							}
						]
					},
					"patching_rect": [
						514.0,
						438.0,
						222.0,
						22.0
					],
					"text": "jit.gl.pix @name cg_pix @drawto vsynth",
					"varname": "jit.gl.pix_AA"
				}
			},
			{
				"box": {
					"activedialcolor": [
						0.8862745098039215,
						0.8941176470588236,
						0.9058823529411765,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Master lift",
					"id": "obj-11",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "jit.gl.pix_AA::m_lift",
					"parameter_enable": 1,
					"patching_rect": [
						433.33334624767303,
						67.5,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						116.0,
						25.5,
						27.0,
						43.0
					],
					"saved_attribute_attributes": {
						"activedialcolor": {
							"expression": ""
						},
						"valueof": {
							"parameter_linknames": 1,
							"parameter_longname": "m_lift",
							"parameter_mmax": 1.0,
							"parameter_mmin": -1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "m_lift",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "m_lift"
				}
			},
			{
				"box": {
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
						0.03529411764705882,
						0.22745098039215686,
						1.0
					],
					"id": "obj-2",
					"maxclass": "panel",
					"mode": 0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						273.0,
						453.0,
						128.0,
						128.0
					],
					"presentation": 1,
					"presentation_rect": [
						2.0,
						2.0,
						150.0,
						165.0
					],
					"proportion": 0.5
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
					"id": "obj-79",
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
					"id": "obj-80",
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
					"id": "obj-81",
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
					"id": "obj-82",
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
					"id": "obj-83",
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
			},
			{
				"box": {
					"id": "obj-rp100",
					"maxclass": "newobj",
					"text": "routepass jit_gl_texture jit_matrix",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"jit_gl_texture",
						"jit_matrix",
						""
					],
					"patching_rect": [
						558.0000166296959,
						348.83333829045296,
						220.0,
						22.0
					]
				}
			}
		],
		"lines": [
			{
				"patchline": {
					"destination": [
						"obj-8",
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
						"obj-16",
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
						"obj-19",
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
						"obj-1",
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
						"obj-1",
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
						"obj-1",
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
						"obj-1",
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
						"obj-1",
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
						"obj-1",
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
						"obj-1",
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
						"obj-1",
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
						"obj-1",
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
						"obj-30",
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
						"obj-40",
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
						"obj-49",
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
						"obj-58",
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
						"obj-59",
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
						"obj-67",
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
						"obj-68",
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
						"obj-69",
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
						"obj-71",
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
						"obj-72",
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
						"obj-73",
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
						"obj-74",
						13
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
						"obj-74",
						10
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
						"obj-74",
						11
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
						"obj-74",
						12
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
						"obj-74",
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
						"obj-74",
						1
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
						"obj-74",
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
						"obj-74",
						3
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
						"obj-74",
						6
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
						"obj-74",
						5
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
						"obj-74",
						4
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
						"obj-74",
						9
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
						"obj-74",
						8
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
						"obj-74",
						7
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-75",
						0
					],
					"destination": [
						"obj-80",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-80",
						0
					],
					"destination": [
						"obj-81",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-81",
						0
					],
					"destination": [
						"obj-82",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-82",
						1
					],
					"destination": [
						"obj-83",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-83",
						0
					],
					"destination": [
						"obj-79",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-6",
						0
					],
					"destination": [
						"obj-rp100",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-rp100",
						0
					],
					"destination": [
						"obj-1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-rp100",
						2
					],
					"destination": [
						"obj-74",
						0
					]
				}
			}
		],
		"parameters": {
			"obj-11": [
				"m_lift",
				"m_lift",
				0
			],
			"obj-14": [
				"m_gamma",
				"m_gamma",
				0
			],
			"obj-15": [
				"m_gain",
				"m_gain",
				0
			],
			"obj-4": [
				"bypass",
				"bypass",
				0
			],
			"obj-49": [
				"r_lift",
				"r_lift",
				0
			],
			"obj-58": [
				"r_gamma",
				"r_gamma",
				0
			],
			"obj-59": [
				"r_gain",
				"r_gain",
				0
			],
			"obj-67": [
				"g_gain",
				"g_gain",
				0
			],
			"obj-68": [
				"g_gamma",
				"g_gamma",
				0
			],
			"obj-69": [
				"g_lift",
				"live.dial",
				0
			],
			"obj-71": [
				"b_gain",
				"b_gain",
				0
			],
			"obj-72": [
				"b_gamma",
				"b_gamma",
				0
			],
			"obj-73": [
				"b_lift",
				"b_lift",
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