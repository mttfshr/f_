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
			30.0,
			788.0,
			900.0,
			700.0
		],
		"openinpresentation": 1,
		"boxes": [
			{
				"box": {
					"angle": 270.0,
					"background": 1,
					"bgcolor": [
						0,
						0,
						0,
						1
					],
					"border": 1,
					"bordercolor": [
						0.0,
						0.03529411765,
						0.2274509804,
						1.0
					],
					"id": "obj-1",
					"maxclass": "panel",
					"mode": 0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						20.0,
						20.0,
						185.0,
						90.0
					],
					"presentation": 1,
					"presentation_rect": [
						0.0,
						0.0,
						185.0,
						90.0
					],
					"proportion": 0.5
				}
			},
			{
				"box": {
					"filename": "bypass_toggle.js",
					"hint": "Bypass",
					"id": "obj-2",
					"maxclass": "jsui",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"param_connect": "mob_pix::bypass",
					"parameter_enable": 1,
					"patching_rect": [
						700.0,
						30.0,
						18.0,
						12.0
					],
					"presentation": 1,
					"presentation_rect": [
						167.0,
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
					"varname": "bypass[1]"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"id": "obj-3",
					"maxclass": "comment",
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
						8.0,
						5.0,
						80.0,
						21.0
					],
					"text": "m\u00f6bius"
				}
			},
			{
				"box": {
					"comment": "texture in",
					"id": "obj-4",
					"index": 0,
					"maxclass": "inlet",
					"numinlets": 0,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						50.0,
						30.0,
						30.0,
						30.0
					]
				}
			},
			{
				"box": {
					"comment": "control in",
					"id": "obj-5",
					"index": 0,
					"maxclass": "inlet",
					"numinlets": 0,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						200.0,
						30.0,
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
						50.0,
						600.0,
						30.0,
						30.0
					]
				}
			},
			{
				"box": {
					"id": "obj-7",
					"maxclass": "newobj",
					"numinlets": 3,
					"numoutlets": 3,
					"outlettype": [
						"",
						"",
						""
					],
					"patching_rect": [
						50.0,
						100.0,
						230.0,
						22.0
					],
					"text": "routepass jit_gl_texture jit_matrix"
				}
			},
			{
				"box": {
					"id": "obj-8",
					"maxclass": "newobj",
					"numinlets": 7,
					"numoutlets": 7,
					"outlettype": [
						"",
						"",
						"",
						"",
						"",
						"",
						""
					],
					"patching_rect": [
						200.0,
						100.0,
						290.0,
						22.0
					],
					"text": "route bypass cx cy rotate zoom invert"
				}
			},
			{
				"box": {
					"id": "obj-9",
					"maxclass": "attrui",
					"attr": "bypass",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						700.0,
						80.0,
						150.0,
						22.0
					],
					"style": ""
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
					"hint": "cx",
					"id": "obj-10",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "mob_pix::cx",
					"parameter_enable": 1,
					"patching_rect": [
						408.0,
						320.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						8.0,
						20.0,
						27.0,
						43.0
					],
					"saved_attribute_attributes": {
						"activedialcolor": {
							"expression": ""
						},
						"valueof": {
							"parameter_initial": [
								0.5
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "cx",
							"parameter_mmax": 1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "cx",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "cx"
				}
			},
			{
				"box": {
					"id": "obj-11",
					"maxclass": "attrui",
					"attr": "cx",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						408.0,
						420.0,
						150.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"id": "obj-28",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						408.0,
						364.0,
						36.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						8.0,
						64.0,
						36.0,
						18.0
					],
					"text": "cx"
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
					"hint": "cy",
					"id": "obj-12",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "mob_pix::cy",
					"parameter_enable": 1,
					"patching_rect": [
						443.0,
						320.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						43.0,
						20.0,
						27.0,
						43.0
					],
					"saved_attribute_attributes": {
						"activedialcolor": {
							"expression": ""
						},
						"valueof": {
							"parameter_initial": [
								0.5
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "cy",
							"parameter_mmax": 1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "cy",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "cy"
				}
			},
			{
				"box": {
					"id": "obj-13",
					"maxclass": "attrui",
					"attr": "cy",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						443.0,
						420.0,
						150.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"id": "obj-29",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						443.0,
						364.0,
						36.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						43.0,
						64.0,
						36.0,
						18.0
					],
					"text": "cy"
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
					"hint": "rotate",
					"id": "obj-14",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "mob_pix::rotate",
					"parameter_enable": 1,
					"patching_rect": [
						478.0,
						320.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						78.0,
						20.0,
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
							"parameter_longname": "rotate",
							"parameter_mmax": 1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "rotate",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "rotate"
				}
			},
			{
				"box": {
					"id": "obj-15",
					"maxclass": "attrui",
					"attr": "rotate",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						478.0,
						420.0,
						150.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"id": "obj-30",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						478.0,
						364.0,
						36.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						78.0,
						64.0,
						36.0,
						18.0
					],
					"text": "rot"
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
					"hint": "zoom",
					"id": "obj-16",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "mob_pix::zoom",
					"parameter_enable": 1,
					"patching_rect": [
						513.0,
						320.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						113.0,
						20.0,
						27.0,
						43.0
					],
					"saved_attribute_attributes": {
						"activedialcolor": {
							"expression": ""
						},
						"valueof": {
							"parameter_initial": [
								0.5
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "zoom",
							"parameter_mmax": 1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "zoom",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "zoom"
				}
			},
			{
				"box": {
					"id": "obj-17",
					"maxclass": "attrui",
					"attr": "zoom",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						513.0,
						420.0,
						150.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"id": "obj-31",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						513.0,
						364.0,
						36.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						113.0,
						64.0,
						36.0,
						18.0
					],
					"text": "zoom"
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
					"hint": "invert",
					"id": "obj-18",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "mob_pix::invert",
					"parameter_enable": 1,
					"patching_rect": [
						548.0,
						320.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						148.0,
						20.0,
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
							"parameter_longname": "invert",
							"parameter_mmax": 1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "invert",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "invert"
				}
			},
			{
				"box": {
					"id": "obj-19",
					"maxclass": "attrui",
					"attr": "invert",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						548.0,
						420.0,
						150.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"id": "obj-32",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						548.0,
						364.0,
						36.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						148.0,
						64.0,
						36.0,
						18.0
					],
					"text": "inv"
				}
			},
			{
				"box": {
					"id": "obj-20",
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
							733.0,
							318.0,
							339.0,
							600.0
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
									"code": "Param cx(0.5);\nParam cy(0.5);\nParam rotate(0.0);\nParam zoom(0.5);\nParam invert(0.0);\nParam bypass(0.0);\n\nTWO_PI = 6.28318530717959;\n\n// offset to transformation center\nzx = norm.x - cx;\nzy = norm.y - cy;\n\n// identity path: rotate + zoom\nangle = rotate * TWO_PI;\nscale = pow(10.0, (zoom - 0.5) * 5.0);\ncos_a = cos(angle);\nsin_a = sin(angle);\nrot_x = (cos_a * zx - sin_a * zy) * scale;\nrot_y = (sin_a * zx + cos_a * zy) * scale;\n\n// inversion path: 1/z = conjugate(z) / |z|^2, singularity guarded\nmag_sq = max(zx*zx + zy*zy, 0.0001);\ninv_x = zx / mag_sq;\ninv_y = -zy / mag_sq;\n\n// blend\nout_x = mix(rot_x, inv_x, invert);\nout_y = mix(rot_y, inv_y, invert);\n\n// offset back + repeat wrap\nuv_x = fract(out_x + cx);\nuv_y = fract(out_y + cy);\n\n// sample + bypass\neffect_out = sample(in1, vec(uv_x, uv_y, 0));\nout1 = mix(effect_out, sample(in1, norm), bypass);",
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
										600.0,
										440.0
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
										550.0,
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
						50.0,
						500.0,
						270.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name mob_pix",
					"varname": "mob_pix"
				}
			},
			{
				"box": {
					"id": "obj-21",
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
						30.0,
						210.0,
						22.0
					],
					"restore": {
						"bypass[1]": [
							0
						],
						"cx": [
							0.5
						],
						"cy": [
							0.5
						],
						"invert": [
							0.0
						],
						"rotate": [
							0.0
						],
						"zoom": [
							0.5
						]
					},
					"text": "autopattr @varname mob_autopattr",
					"varname": "u373010471"
				}
			},
			{
				"box": {
					"id": "obj-22",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"bang"
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
					"id": "obj-23",
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
					"id": "obj-24",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						600.0,
						110.0,
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
					"id": "obj-25",
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
					"id": "obj-26",
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
					"id": "obj-27",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						600.0,
						200.0,
						120.0,
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
						"obj-11",
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
						"obj-20",
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
						"obj-13",
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
						"obj-20",
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
						"obj-15",
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
						"obj-20",
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
						"obj-17",
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
						"obj-20",
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
						"obj-19",
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
						"obj-20",
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
						"obj-9",
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
						"obj-6",
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
						"obj-23",
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
						"obj-24",
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
						"obj-25",
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
						"obj-26",
						0
					],
					"source": [
						"obj-25",
						1
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
						"obj-4",
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
						"obj-5",
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
						"obj-7",
						1
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
						"obj-7",
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
						"obj-7",
						2
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
						"obj-12",
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
						"obj-14",
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
						"obj-16",
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
						"obj-18",
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
						"obj-2",
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
						"obj-20",
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
			"obj-10": [
				"cx",
				"cx",
				0
			],
			"obj-12": [
				"cy",
				"cy",
				0
			],
			"obj-14": [
				"rotate",
				"rotate",
				0
			],
			"obj-16": [
				"zoom",
				"zoom",
				0
			],
			"obj-18": [
				"invert",
				"invert",
				0
			],
			"obj-2": [
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