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
			720.0,
			200.0
		],
		"gridsize": [
			15.0,
			15.0
		],
		"showrootpatcherontab": 0,
		"showontab": 0,
		"boxes": [
			{
				"box": {
					"id": "obj-1",
					"maxclass": "newobj",
					"numinlets": 0,
					"numoutlets": 0,
					"patching_rect": [
						30.0,
						40.0,
						150.0,
						22.0
					],
					"text": "p Generators",
					"varname": "tab_gen",
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
							0.0,
							26.0,
							720.0,
							140.0
						],
						"openinpresentation": 1,
						"gridsize": [
							15.0,
							15.0
						],
						"showontab": 1,
						"boxes": [
							{
								"box": {
									"id": "obj-1",
									"maxclass": "newobj",
									"numinlets": 1,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										420.0,
										20.0,
										60.0,
										22.0
									],
									"text": "pcontrol"
								}
							},
							{
								"box": {
									"id": "obj-2",
									"maxclass": "textbutton",
									"numinlets": 1,
									"numoutlets": 3,
									"outlettype": [
										"",
										"",
										"int"
									],
									"parameter_enable": 0,
									"fontsize": 12.0,
									"patching_rect": [
										20.0,
										20.0,
										150.0,
										22.0
									],
									"text": "f_masonry",
									"presentation": 1,
									"presentation_rect": [
										10.0,
										12.0,
										160.0,
										22.0
									]
								}
							},
							{
								"box": {
									"id": "obj-3",
									"maxclass": "message",
									"numinlets": 2,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										20.0,
										48.0,
										230.0,
										22.0
									],
									"text": "loadunique f_masonry.maxhelp"
								}
							},
							{
								"box": {
									"id": "obj-4",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										260.0,
										20.0,
										150.0,
										20.0
									],
									"text": "Parametric masonry texture -- courses, bond, mortar, drift, color",
									"textcolor": [
										0.1,
										0.1,
										0.1,
										1.0
									],
									"presentation": 1,
									"presentation_rect": [
										180.0,
										14.0,
										520.0,
										20.0
									]
								}
							},
							{
								"box": {
									"id": "obj-5",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										20.0,
										80.0,
										150.0,
										20.0
									],
									"text": "f_ngon",
									"textcolor": [
										0.55,
										0.55,
										0.55,
										1.0
									],
									"presentation": 1,
									"presentation_rect": [
										10.0,
										44.0,
										160.0,
										20.0
									]
								}
							},
							{
								"box": {
									"id": "obj-6",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										260.0,
										80.0,
										150.0,
										20.0
									],
									"text": "WARN Unfinished. Regular N-gon generator / mask (greyed: no helpfile)",
									"textcolor": [
										0.55,
										0.55,
										0.55,
										1.0
									],
									"presentation": 1,
									"presentation_rect": [
										180.0,
										44.0,
										520.0,
										20.0
									]
								}
							}
						],
						"lines": [
							{
								"patchline": {
									"source": [
										"obj-2",
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
										"obj-3",
										0
									],
									"destination": [
										"obj-1",
										0
									]
								}
							}
						]
					}
				}
			},
			{
				"box": {
					"id": "obj-2",
					"maxclass": "newobj",
					"numinlets": 0,
					"numoutlets": 0,
					"patching_rect": [
						200.0,
						40.0,
						150.0,
						22.0
					],
					"text": "p \"Generator / processor\"",
					"varname": "tab_genproc",
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
							0.0,
							26.0,
							720.0,
							140.0
						],
						"openinpresentation": 1,
						"gridsize": [
							15.0,
							15.0
						],
						"showontab": 1,
						"boxes": [
							{
								"box": {
									"id": "obj-1",
									"maxclass": "newobj",
									"numinlets": 1,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										420.0,
										20.0,
										60.0,
										22.0
									],
									"text": "pcontrol"
								}
							},
							{
								"box": {
									"id": "obj-2",
									"maxclass": "textbutton",
									"numinlets": 1,
									"numoutlets": 3,
									"outlettype": [
										"",
										"",
										"int"
									],
									"parameter_enable": 0,
									"fontsize": 12.0,
									"patching_rect": [
										20.0,
										20.0,
										150.0,
										22.0
									],
									"text": "f_grain",
									"presentation": 1,
									"presentation_rect": [
										10.0,
										12.0,
										160.0,
										22.0
									]
								}
							},
							{
								"box": {
									"id": "obj-3",
									"maxclass": "message",
									"numinlets": 2,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										20.0,
										48.0,
										230.0,
										22.0
									],
									"text": "loadunique f_grain.maxhelp"
								}
							},
							{
								"box": {
									"id": "obj-4",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										260.0,
										20.0,
										150.0,
										20.0
									],
									"text": "Stochastic grain field with per-grain displacement and luma gating",
									"textcolor": [
										0.1,
										0.1,
										0.1,
										1.0
									],
									"presentation": 1,
									"presentation_rect": [
										180.0,
										14.0,
										520.0,
										20.0
									]
								}
							}
						],
						"lines": [
							{
								"patchline": {
									"source": [
										"obj-2",
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
										"obj-3",
										0
									],
									"destination": [
										"obj-1",
										0
									]
								}
							}
						]
					}
				}
			},
			{
				"box": {
					"id": "obj-3",
					"maxclass": "newobj",
					"numinlets": 0,
					"numoutlets": 0,
					"patching_rect": [
						370.0,
						40.0,
						150.0,
						22.0
					],
					"text": "p Audio-domain",
					"varname": "tab_audio",
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
							0.0,
							26.0,
							720.0,
							140.0
						],
						"openinpresentation": 1,
						"gridsize": [
							15.0,
							15.0
						],
						"showontab": 1,
						"boxes": [
							{
								"box": {
									"id": "obj-1",
									"maxclass": "newobj",
									"numinlets": 1,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										420.0,
										20.0,
										60.0,
										22.0
									],
									"text": "pcontrol"
								}
							},
							{
								"box": {
									"id": "obj-2",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										20.0,
										20.0,
										150.0,
										20.0
									],
									"text": "f_a_ripple",
									"textcolor": [
										0.55,
										0.55,
										0.55,
										1.0
									],
									"presentation": 1,
									"presentation_rect": [
										10.0,
										14.0,
										160.0,
										20.0
									]
								}
							},
							{
								"box": {
									"id": "obj-3",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										260.0,
										20.0,
										150.0,
										20.0
									],
									"text": "WARN Unfinished. De-correlating ripple stimulus (greyed: no helpfile)",
									"textcolor": [
										0.55,
										0.55,
										0.55,
										1.0
									],
									"presentation": 1,
									"presentation_rect": [
										180.0,
										14.0,
										520.0,
										20.0
									]
								}
							}
						],
						"lines": []
					}
				}
			}
		],
		"lines": []
	}
}