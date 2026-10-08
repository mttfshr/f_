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
			960.0,
			390.0
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
						170.0,
						22.0
					],
					"text": "p Scope",
					"varname": "tab_scope",
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
							960.0,
							364.0
						],
						"openinpresentation": 1,
						"gridsize": [
							15.0,
							15.0
						],
						"enablevscroll": 1,
						"enablehscroll": 0,
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
									"text": "f_chladni",
									"presentation": 1,
									"presentation_rect": [
										10.0,
										12.0,
										210.0,
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
									"text": "loadunique f_chladni.maxhelp"
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
									"text": "Chladni plate modal synthesis visualizer (Bessel modes); audio companion patch included",
									"presentation": 1,
									"presentation_rect": [
										230.0,
										14.0,
										720.0,
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
						220.0,
						40.0,
						170.0,
						22.0
					],
					"text": "p Discrete",
					"varname": "tab_discrete",
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
							960.0,
							364.0
						],
						"openinpresentation": 1,
						"gridsize": [
							15.0,
							15.0
						],
						"enablevscroll": 1,
						"enablehscroll": 0,
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
										210.0,
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
									"presentation": 1,
									"presentation_rect": [
										230.0,
										14.0,
										720.0,
										20.0
									]
								}
							},
							{
								"box": {
									"id": "obj-5",
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
										80.0,
										150.0,
										22.0
									],
									"text": "f_masonry",
									"presentation": 1,
									"presentation_rect": [
										10.0,
										40.0,
										210.0,
										22.0
									]
								}
							},
							{
								"box": {
									"id": "obj-6",
									"maxclass": "message",
									"numinlets": 2,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										20.0,
										108.0,
										230.0,
										22.0
									],
									"text": "loadunique f_masonry.maxhelp"
								}
							},
							{
								"box": {
									"id": "obj-7",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										260.0,
										80.0,
										150.0,
										20.0
									],
									"text": "Parametric masonry texture -- courses, bond, mortar, drift, color",
									"presentation": 1,
									"presentation_rect": [
										230.0,
										42.0,
										720.0,
										20.0
									]
								}
							},
							{
								"box": {
									"id": "obj-8",
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
										140.0,
										150.0,
										22.0
									],
									"text": "f_stipple",
									"presentation": 1,
									"presentation_rect": [
										10.0,
										68.0,
										210.0,
										22.0
									]
								}
							},
							{
								"box": {
									"id": "obj-9",
									"maxclass": "message",
									"numinlets": 2,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										20.0,
										168.0,
										230.0,
										22.0
									],
									"text": "loadunique f_stipple.maxhelp"
								}
							},
							{
								"box": {
									"id": "obj-10",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										260.0,
										140.0,
										150.0,
										20.0
									],
									"text": "2D hash field stipple texture",
									"presentation": 1,
									"presentation_rect": [
										230.0,
										70.0,
										720.0,
										20.0
									]
								}
							},
							{
								"box": {
									"id": "obj-11",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										20.0,
										200.0,
										150.0,
										20.0
									],
									"text": "f_vf_seeds",
									"textcolor": [
										0.55,
										0.55,
										0.55,
										1.0
									],
									"presentation": 1,
									"presentation_rect": [
										10.0,
										98.0,
										210.0,
										20.0
									]
								}
							},
							{
								"box": {
									"id": "obj-12",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										260.0,
										200.0,
										150.0,
										20.0
									],
									"text": "Discrete mark placement and orientation from a vecfield and shape tex -- Voronoi-style seeds with overlap",
									"presentation": 1,
									"presentation_rect": [
										230.0,
										98.0,
										720.0,
										20.0
									],
									"textcolor": [
										0.55,
										0.55,
										0.55,
										1.0
									]
								}
							},
							{
								"box": {
									"id": "obj-13",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										20.0,
										260.0,
										150.0,
										20.0
									],
									"text": "f_weave",
									"textcolor": [
										0.55,
										0.55,
										0.55,
										1.0
									],
									"presentation": 1,
									"presentation_rect": [
										10.0,
										126.0,
										210.0,
										20.0
									]
								}
							},
							{
								"box": {
									"id": "obj-14",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										260.0,
										260.0,
										150.0,
										20.0
									],
									"text": "Parametric distance-field line texture with per-line phase variation; optional vecfield + scalar inlets",
									"presentation": 1,
									"presentation_rect": [
										230.0,
										126.0,
										720.0,
										20.0
									],
									"textcolor": [
										0.55,
										0.55,
										0.55,
										1.0
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
							},
							{
								"patchline": {
									"source": [
										"obj-5",
										0
									],
									"destination": [
										"obj-6",
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
										"obj-1",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"obj-8",
										0
									],
									"destination": [
										"obj-9",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"obj-9",
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
						410.0,
						40.0,
						170.0,
						22.0
					],
					"text": "p Spatial",
					"varname": "tab_spatial",
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
							960.0,
							364.0
						],
						"openinpresentation": 1,
						"gridsize": [
							15.0,
							15.0
						],
						"enablevscroll": 1,
						"enablehscroll": 0,
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
									"text": "f_droste",
									"presentation": 1,
									"presentation_rect": [
										10.0,
										12.0,
										210.0,
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
									"text": "loadunique f_droste.maxhelp"
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
									"text": "Log-polar spiral transform -- Droste / Escher-style recursive zoom",
									"presentation": 1,
									"presentation_rect": [
										230.0,
										14.0,
										720.0,
										20.0
									]
								}
							},
							{
								"box": {
									"id": "obj-5",
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
										80.0,
										150.0,
										22.0
									],
									"text": "f_mobius",
									"presentation": 1,
									"presentation_rect": [
										10.0,
										40.0,
										210.0,
										22.0
									]
								}
							},
							{
								"box": {
									"id": "obj-6",
									"maxclass": "message",
									"numinlets": 2,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										20.0,
										108.0,
										230.0,
										22.0
									],
									"text": "loadunique f_mobius.maxhelp"
								}
							},
							{
								"box": {
									"id": "obj-7",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										260.0,
										80.0,
										150.0,
										20.0
									],
									"text": "Mobius transformation UV-space processor",
									"presentation": 1,
									"presentation_rect": [
										230.0,
										42.0,
										720.0,
										20.0
									]
								}
							},
							{
								"box": {
									"id": "obj-8",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										20.0,
										140.0,
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
										70.0,
										210.0,
										20.0
									]
								}
							},
							{
								"box": {
									"id": "obj-9",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										260.0,
										140.0,
										150.0,
										20.0
									],
									"text": "⚠ Unfinished. Regular N-gon generator / mask, live-modulatable vertex count; not yet confirmed or documented",
									"presentation": 1,
									"presentation_rect": [
										230.0,
										70.0,
										720.0,
										20.0
									],
									"textcolor": [
										0.55,
										0.55,
										0.55,
										1.0
									]
								}
							},
							{
								"box": {
									"id": "obj-10",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										20.0,
										200.0,
										150.0,
										20.0
									],
									"text": "f_sirds",
									"textcolor": [
										0.55,
										0.55,
										0.55,
										1.0
									],
									"presentation": 1,
									"presentation_rect": [
										10.0,
										98.0,
										210.0,
										20.0
									]
								}
							},
							{
								"box": {
									"id": "obj-11",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										260.0,
										200.0,
										150.0,
										20.0
									],
									"text": "Single Image Random Dot Stereogram -- real-time strips; a depth texture displaces a repeating pattern",
									"presentation": 1,
									"presentation_rect": [
										230.0,
										98.0,
										720.0,
										20.0
									],
									"textcolor": [
										0.55,
										0.55,
										0.55,
										1.0
									]
								}
							},
							{
								"box": {
									"id": "obj-12",
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
										260.0,
										150.0,
										22.0
									],
									"text": "f_stereo",
									"presentation": 1,
									"presentation_rect": [
										10.0,
										124.0,
										210.0,
										22.0
									]
								}
							},
							{
								"box": {
									"id": "obj-13",
									"maxclass": "message",
									"numinlets": 2,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										20.0,
										288.0,
										230.0,
										22.0
									],
									"text": "loadunique f_stereo.maxhelp"
								}
							},
							{
								"box": {
									"id": "obj-14",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										260.0,
										260.0,
										150.0,
										20.0
									],
									"text": "Stereographic projection display layer",
									"presentation": 1,
									"presentation_rect": [
										230.0,
										126.0,
										720.0,
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
							},
							{
								"patchline": {
									"source": [
										"obj-5",
										0
									],
									"destination": [
										"obj-6",
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
										"obj-1",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"obj-12",
										0
									],
									"destination": [
										"obj-13",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"obj-13",
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
					"id": "obj-4",
					"maxclass": "newobj",
					"numinlets": 0,
					"numoutlets": 0,
					"patching_rect": [
						600.0,
						40.0,
						170.0,
						22.0
					],
					"text": "p Optical",
					"varname": "tab_optical",
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
							960.0,
							364.0
						],
						"openinpresentation": 1,
						"gridsize": [
							15.0,
							15.0
						],
						"enablevscroll": 1,
						"enablehscroll": 0,
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
									"text": "f_lens",
									"presentation": 1,
									"presentation_rect": [
										10.0,
										12.0,
										210.0,
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
									"text": "loadunique f_lens.maxhelp"
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
									"text": "Filmic lens -- aberration, distortion, transmission, tilt-shift, ghost images, halation, spatial modulation",
									"presentation": 1,
									"presentation_rect": [
										230.0,
										14.0,
										720.0,
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
									"text": "f_vf_prism",
									"textcolor": [
										0.55,
										0.55,
										0.55,
										1.0
									],
									"presentation": 1,
									"presentation_rect": [
										10.0,
										42.0,
										210.0,
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
									"text": "Vecfield-driven prism separation -- luma-gated RGB displacement along the field; composite / isolated outlets",
									"presentation": 1,
									"presentation_rect": [
										230.0,
										42.0,
										720.0,
										20.0
									],
									"textcolor": [
										0.55,
										0.55,
										0.55,
										1.0
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
					"id": "obj-5",
					"maxclass": "newobj",
					"numinlets": 0,
					"numoutlets": 0,
					"patching_rect": [
						790.0,
						40.0,
						170.0,
						22.0
					],
					"text": "p \"∇ Generators\"",
					"varname": "tab_generators",
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
							960.0,
							364.0
						],
						"openinpresentation": 1,
						"gridsize": [
							15.0,
							15.0
						],
						"enablevscroll": 1,
						"enablehscroll": 0,
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
									"text": "f_vf_vortex",
									"presentation": 1,
									"presentation_rect": [
										10.0,
										12.0,
										210.0,
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
									"text": "loadunique f_vf_vortex.maxhelp"
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
									"text": "Single fixed-point vortex field -- convergence, curl, position, 4 mod inlets",
									"presentation": 1,
									"presentation_rect": [
										230.0,
										14.0,
										720.0,
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
									"text": "f_vf_vortex_multi",
									"textcolor": [
										0.55,
										0.55,
										0.55,
										1.0
									],
									"presentation": 1,
									"presentation_rect": [
										10.0,
										42.0,
										210.0,
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
									"text": "Three-site additive vortex field -- per-site position/conv/curl, 4 global mod inlets",
									"presentation": 1,
									"presentation_rect": [
										230.0,
										42.0,
										720.0,
										20.0
									],
									"textcolor": [
										0.55,
										0.55,
										0.55,
										1.0
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
					"id": "obj-6",
					"maxclass": "newobj",
					"numinlets": 0,
					"numoutlets": 0,
					"patching_rect": [
						980.0,
						40.0,
						170.0,
						22.0
					],
					"text": "p \"∇ Processors\"",
					"varname": "tab_processors",
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
							960.0,
							364.0
						],
						"openinpresentation": 1,
						"gridsize": [
							15.0,
							15.0
						],
						"enablevscroll": 1,
						"enablehscroll": 0,
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
									"text": "f_caustic",
									"presentation": 1,
									"presentation_rect": [
										10.0,
										12.0,
										210.0,
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
									"text": "loadunique f_caustic.maxhelp"
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
									"text": "Optical caustic -- Soft (streamlines) or Sheets (GPU scatter, folded sheets); composited / isolated outlets",
									"presentation": 1,
									"presentation_rect": [
										230.0,
										14.0,
										720.0,
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
									"text": "f_vf_advect",
									"textcolor": [
										0.55,
										0.55,
										0.55,
										1.0
									],
									"presentation": 1,
									"presentation_rect": [
										10.0,
										42.0,
										210.0,
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
									"text": "Temporal fluid advection via f_vecfield -- accumulates flow across frames; decay >1.0 is excitable",
									"presentation": 1,
									"presentation_rect": [
										230.0,
										42.0,
										720.0,
										20.0
									],
									"textcolor": [
										0.55,
										0.55,
										0.55,
										1.0
									]
								}
							},
							{
								"box": {
									"id": "obj-7",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										20.0,
										140.0,
										150.0,
										20.0
									],
									"text": "f_vf_chroma",
									"textcolor": [
										0.55,
										0.55,
										0.55,
										1.0
									],
									"presentation": 1,
									"presentation_rect": [
										10.0,
										70.0,
										210.0,
										20.0
									]
								}
							},
							{
								"box": {
									"id": "obj-8",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										260.0,
										140.0,
										150.0,
										20.0
									],
									"text": "Vecfield-driven chromatic aberration -- rainbow streak along field direction; composite / isolated outlets",
									"presentation": 1,
									"presentation_rect": [
										230.0,
										70.0,
										720.0,
										20.0
									],
									"textcolor": [
										0.55,
										0.55,
										0.55,
										1.0
									]
								}
							},
							{
								"box": {
									"id": "obj-9",
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
										200.0,
										150.0,
										22.0
									],
									"text": "f_vf_fieldmap",
									"presentation": 1,
									"presentation_rect": [
										10.0,
										96.0,
										210.0,
										22.0
									]
								}
							},
							{
								"box": {
									"id": "obj-10",
									"maxclass": "message",
									"numinlets": 2,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										20.0,
										228.0,
										230.0,
										22.0
									],
									"text": "loadunique f_vf_fieldmap.maxhelp"
								}
							},
							{
								"box": {
									"id": "obj-11",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										260.0,
										200.0,
										150.0,
										20.0
									],
									"text": "Scalar texture to vecfield via central difference gradient -- primary source: jit.gl.bfg",
									"presentation": 1,
									"presentation_rect": [
										230.0,
										98.0,
										720.0,
										20.0
									]
								}
							},
							{
								"box": {
									"id": "obj-12",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										20.0,
										260.0,
										150.0,
										20.0
									],
									"text": "f_vf_flow",
									"textcolor": [
										0.55,
										0.55,
										0.55,
										1.0
									],
									"presentation": 1,
									"presentation_rect": [
										10.0,
										126.0,
										210.0,
										20.0
									]
								}
							},
							{
								"box": {
									"id": "obj-13",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										260.0,
										260.0,
										150.0,
										20.0
									],
									"text": "Dual-mode uniform/texture-perturbed direction field -- designed to feed f_weave's vecfield inlet",
									"presentation": 1,
									"presentation_rect": [
										230.0,
										126.0,
										720.0,
										20.0
									],
									"textcolor": [
										0.55,
										0.55,
										0.55,
										1.0
									]
								}
							},
							{
								"box": {
									"id": "obj-14",
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
										320.0,
										150.0,
										22.0
									],
									"text": "f_vf_fluid",
									"presentation": 1,
									"presentation_rect": [
										10.0,
										152.0,
										210.0,
										22.0
									]
								}
							},
							{
								"box": {
									"id": "obj-15",
									"maxclass": "message",
									"numinlets": 2,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										20.0,
										348.0,
										230.0,
										22.0
									],
									"text": "loadunique f_vf_fluid.maxhelp"
								}
							},
							{
								"box": {
									"id": "obj-16",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										260.0,
										320.0,
										150.0,
										20.0
									],
									"text": "Incompressible-flow solver -- force vecfield in, evolving velocity field out; feed it to advect / warp / glow",
									"presentation": 1,
									"presentation_rect": [
										230.0,
										154.0,
										720.0,
										20.0
									]
								}
							},
							{
								"box": {
									"id": "obj-17",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										20.0,
										380.0,
										150.0,
										20.0
									],
									"text": "f_vf_glow",
									"textcolor": [
										0.55,
										0.55,
										0.55,
										1.0
									],
									"presentation": 1,
									"presentation_rect": [
										10.0,
										182.0,
										210.0,
										20.0
									]
								}
							},
							{
								"box": {
									"id": "obj-18",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										260.0,
										380.0,
										150.0,
										20.0
									],
									"text": "Field-aligned directional blur via f_vecfield -- accumulates along streamlines; composite / glow-layer outlets",
									"presentation": 1,
									"presentation_rect": [
										230.0,
										182.0,
										720.0,
										20.0
									],
									"textcolor": [
										0.55,
										0.55,
										0.55,
										1.0
									]
								}
							},
							{
								"box": {
									"id": "obj-19",
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
										440.0,
										150.0,
										22.0
									],
									"text": "f_vf_optical_flow",
									"presentation": 1,
									"presentation_rect": [
										10.0,
										208.0,
										210.0,
										22.0
									]
								}
							},
							{
								"box": {
									"id": "obj-20",
									"maxclass": "message",
									"numinlets": 2,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										20.0,
										468.0,
										230.0,
										22.0
									],
									"text": "loadunique f_vf_optical_flow.maxhelp"
								}
							},
							{
								"box": {
									"id": "obj-21",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										260.0,
										440.0,
										150.0,
										20.0
									],
									"text": "Lucas-Kanade optical flow from source motion -- confidence-gated, with aperture-problem fill; two outlets",
									"presentation": 1,
									"presentation_rect": [
										230.0,
										210.0,
										720.0,
										20.0
									]
								}
							},
							{
								"box": {
									"id": "obj-22",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										20.0,
										500.0,
										150.0,
										20.0
									],
									"text": "f_vf_repulse",
									"textcolor": [
										0.55,
										0.55,
										0.55,
										1.0
									],
									"presentation": 1,
									"presentation_rect": [
										10.0,
										238.0,
										210.0,
										20.0
									]
								}
							},
							{
								"box": {
									"id": "obj-23",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										260.0,
										500.0,
										150.0,
										20.0
									],
									"text": "Texture-driven repulsion vecfield -- 16-sample ring accumulation, luma threshold, four accumulation modes",
									"presentation": 1,
									"presentation_rect": [
										230.0,
										238.0,
										720.0,
										20.0
									],
									"textcolor": [
										0.55,
										0.55,
										0.55,
										1.0
									]
								}
							},
							{
								"box": {
									"id": "obj-24",
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
										560.0,
										150.0,
										22.0
									],
									"text": "f_vf_streak",
									"presentation": 1,
									"presentation_rect": [
										10.0,
										264.0,
										210.0,
										22.0
									]
								}
							},
							{
								"box": {
									"id": "obj-25",
									"maxclass": "message",
									"numinlets": 2,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										20.0,
										588.0,
										230.0,
										22.0
									],
									"text": "loadunique f_vf_streak.maxhelp"
								}
							},
							{
								"box": {
									"id": "obj-26",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										260.0,
										560.0,
										150.0,
										20.0
									],
									"text": "Directional blur via f_vecfield -- accumulates along streamlines; composite / isolated streak outlets",
									"presentation": 1,
									"presentation_rect": [
										230.0,
										266.0,
										720.0,
										20.0
									]
								}
							},
							{
								"box": {
									"id": "obj-27",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										20.0,
										620.0,
										150.0,
										20.0
									],
									"text": "f_vf_vorticity",
									"textcolor": [
										0.55,
										0.55,
										0.55,
										1.0
									],
									"presentation": 1,
									"presentation_rect": [
										10.0,
										294.0,
										210.0,
										20.0
									]
								}
							},
							{
								"box": {
									"id": "obj-28",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										260.0,
										620.0,
										150.0,
										20.0
									],
									"text": "⚠ Unverified. Vorticity-confinement (\"curl amp\") processor. Do not treat as working",
									"presentation": 1,
									"presentation_rect": [
										230.0,
										294.0,
										720.0,
										20.0
									],
									"textcolor": [
										0.55,
										0.55,
										0.55,
										1.0
									]
								}
							},
							{
								"box": {
									"id": "obj-29",
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
										680.0,
										150.0,
										22.0
									],
									"text": "f_vf_warp",
									"presentation": 1,
									"presentation_rect": [
										10.0,
										320.0,
										210.0,
										22.0
									]
								}
							},
							{
								"box": {
									"id": "obj-30",
									"maxclass": "message",
									"numinlets": 2,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										20.0,
										708.0,
										230.0,
										22.0
									],
									"text": "loadunique f_vf_warp.maxhelp"
								}
							},
							{
								"box": {
									"id": "obj-31",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										260.0,
										680.0,
										150.0,
										20.0
									],
									"text": "UV warp via f_vecfield -- displaces source texture along field streamlines",
									"presentation": 1,
									"presentation_rect": [
										230.0,
										322.0,
										720.0,
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
							},
							{
								"patchline": {
									"source": [
										"obj-9",
										0
									],
									"destination": [
										"obj-10",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"obj-10",
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
										"obj-14",
										0
									],
									"destination": [
										"obj-15",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"obj-15",
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
										"obj-19",
										0
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
										"obj-1",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"obj-24",
										0
									],
									"destination": [
										"obj-25",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"obj-25",
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
										"obj-29",
										0
									],
									"destination": [
										"obj-30",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"obj-30",
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
					"id": "obj-7",
					"maxclass": "newobj",
					"numinlets": 0,
					"numoutlets": 0,
					"patching_rect": [
						1170.0,
						40.0,
						170.0,
						22.0
					],
					"text": "p \"Color / Tone\"",
					"varname": "tab_color_tone",
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
							960.0,
							364.0
						],
						"openinpresentation": 1,
						"gridsize": [
							15.0,
							15.0
						],
						"enablevscroll": 1,
						"enablehscroll": 0,
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
									"text": "f_channel_grader",
									"presentation": 1,
									"presentation_rect": [
										10.0,
										12.0,
										210.0,
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
									"text": "loadunique f_channel_grader.maxhelp"
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
									"text": "Per-channel color grading",
									"presentation": 1,
									"presentation_rect": [
										230.0,
										14.0,
										720.0,
										20.0
									]
								}
							},
							{
								"box": {
									"id": "obj-5",
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
										80.0,
										150.0,
										22.0
									],
									"text": "f_hue_processor",
									"presentation": 1,
									"presentation_rect": [
										10.0,
										40.0,
										210.0,
										22.0
									]
								}
							},
							{
								"box": {
									"id": "obj-6",
									"maxclass": "message",
									"numinlets": 2,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										20.0,
										108.0,
										230.0,
										22.0
									],
									"text": "loadunique f_hue_processor.maxhelp"
								}
							},
							{
								"box": {
									"id": "obj-7",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										260.0,
										80.0,
										150.0,
										20.0
									],
									"text": "Hue-selective processing",
									"presentation": 1,
									"presentation_rect": [
										230.0,
										42.0,
										720.0,
										20.0
									]
								}
							},
							{
								"box": {
									"id": "obj-8",
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
										140.0,
										150.0,
										22.0
									],
									"text": "f_luma_processor",
									"presentation": 1,
									"presentation_rect": [
										10.0,
										68.0,
										210.0,
										22.0
									]
								}
							},
							{
								"box": {
									"id": "obj-9",
									"maxclass": "message",
									"numinlets": 2,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										20.0,
										168.0,
										230.0,
										22.0
									],
									"text": "loadunique f_luma_processor.maxhelp"
								}
							},
							{
								"box": {
									"id": "obj-10",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										260.0,
										140.0,
										150.0,
										20.0
									],
									"text": "Luminance-selective processing",
									"presentation": 1,
									"presentation_rect": [
										230.0,
										70.0,
										720.0,
										20.0
									]
								}
							},
							{
								"box": {
									"id": "obj-11",
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
										200.0,
										150.0,
										22.0
									],
									"text": "f_tone_curve",
									"presentation": 1,
									"presentation_rect": [
										10.0,
										96.0,
										210.0,
										22.0
									]
								}
							},
							{
								"box": {
									"id": "obj-12",
									"maxclass": "message",
									"numinlets": 2,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										20.0,
										228.0,
										230.0,
										22.0
									],
									"text": "loadunique f_tone_curve.maxhelp"
								}
							},
							{
								"box": {
									"id": "obj-13",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										260.0,
										200.0,
										150.0,
										20.0
									],
									"text": "Tone curve adjustment",
									"presentation": 1,
									"presentation_rect": [
										230.0,
										98.0,
										720.0,
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
							},
							{
								"patchline": {
									"source": [
										"obj-5",
										0
									],
									"destination": [
										"obj-6",
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
										"obj-1",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"obj-8",
										0
									],
									"destination": [
										"obj-9",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"obj-9",
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
										"obj-11",
										0
									],
									"destination": [
										"obj-12",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"obj-12",
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
					"id": "obj-8",
					"maxclass": "newobj",
					"numinlets": 0,
					"numoutlets": 0,
					"patching_rect": [
						1360.0,
						40.0,
						170.0,
						22.0
					],
					"text": "p Utilities",
					"varname": "tab_utilities",
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
							960.0,
							364.0
						],
						"openinpresentation": 1,
						"gridsize": [
							15.0,
							15.0
						],
						"enablevscroll": 1,
						"enablehscroll": 0,
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
									"text": "f_modules",
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
										210.0,
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
									"text": "Module menu -- pick a module to add it to the patch as a bpatcher; categories marked ∇ hold vecfield modules",
									"presentation": 1,
									"presentation_rect": [
										230.0,
										14.0,
										720.0,
										20.0
									],
									"textcolor": [
										0.55,
										0.55,
										0.55,
										1.0
									]
								}
							},
							{
								"box": {
									"id": "obj-4",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										20.0,
										80.0,
										150.0,
										20.0
									],
									"text": "f_texrouter",
									"textcolor": [
										0.55,
										0.55,
										0.55,
										1.0
									],
									"presentation": 1,
									"presentation_rect": [
										10.0,
										42.0,
										210.0,
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
										260.0,
										80.0,
										150.0,
										20.0
									],
									"text": "4x4 texture routing matrix with preset system",
									"presentation": 1,
									"presentation_rect": [
										230.0,
										42.0,
										720.0,
										20.0
									],
									"textcolor": [
										0.55,
										0.55,
										0.55,
										1.0
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
										20.0,
										140.0,
										150.0,
										20.0
									],
									"text": "f_util_matrix_2",
									"textcolor": [
										0.55,
										0.55,
										0.55,
										1.0
									],
									"presentation": 1,
									"presentation_rect": [
										10.0,
										70.0,
										210.0,
										20.0
									]
								}
							},
							{
								"box": {
									"id": "obj-7",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										260.0,
										140.0,
										150.0,
										20.0
									],
									"text": "Modulation routing matrix (2-source MVP) -- textures in, scalar per-param routing messages out; draft status",
									"presentation": 1,
									"presentation_rect": [
										230.0,
										70.0,
										720.0,
										20.0
									],
									"textcolor": [
										0.55,
										0.55,
										0.55,
										1.0
									]
								}
							},
							{
								"box": {
									"id": "obj-8",
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
										200.0,
										150.0,
										22.0
									],
									"text": "f_util_profile",
									"presentation": 1,
									"presentation_rect": [
										10.0,
										96.0,
										210.0,
										22.0
									]
								}
							},
							{
								"box": {
									"id": "obj-9",
									"maxclass": "message",
									"numinlets": 2,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										20.0,
										228.0,
										230.0,
										22.0
									],
									"text": "loadunique f_util_profile.maxhelp"
								}
							},
							{
								"box": {
									"id": "obj-10",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										260.0,
										200.0,
										150.0,
										20.0
									],
									"text": "CPU-side dual-axis luminance profiler -- outputs row/column profile textures for modulation",
									"presentation": 1,
									"presentation_rect": [
										230.0,
										98.0,
										720.0,
										20.0
									]
								}
							},
							{
								"box": {
									"id": "obj-11",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										20.0,
										260.0,
										150.0,
										20.0
									],
									"text": "f_vf_potential",
									"textcolor": [
										0.55,
										0.55,
										0.55,
										1.0
									],
									"presentation": 1,
									"presentation_rect": [
										10.0,
										126.0,
										210.0,
										20.0
									]
								}
							},
							{
								"box": {
									"id": "obj-12",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										260.0,
										260.0,
										150.0,
										20.0
									],
									"text": "Scalar potential-field integrator -- accumulates vecfield magnitude over time; feeds f_weave's scalar inlet",
									"presentation": 1,
									"presentation_rect": [
										230.0,
										126.0,
										720.0,
										20.0
									],
									"textcolor": [
										0.55,
										0.55,
										0.55,
										1.0
									]
								}
							},
							{
								"box": {
									"id": "obj-13",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										20.0,
										320.0,
										150.0,
										20.0
									],
									"text": "f_vf_split",
									"textcolor": [
										0.55,
										0.55,
										0.55,
										1.0
									],
									"presentation": 1,
									"presentation_rect": [
										10.0,
										154.0,
										210.0,
										20.0
									]
								}
							},
							{
								"box": {
									"id": "obj-14",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										260.0,
										320.0,
										150.0,
										20.0
									],
									"text": "Splits an f_vecfield's X/Y channels to two separate greyscale outlets, unipolar or bipolar",
									"presentation": 1,
									"presentation_rect": [
										230.0,
										154.0,
										720.0,
										20.0
									],
									"textcolor": [
										0.55,
										0.55,
										0.55,
										1.0
									]
								}
							}
						],
						"lines": [
							{
								"patchline": {
									"source": [
										"obj-8",
										0
									],
									"destination": [
										"obj-9",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"obj-9",
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
					"id": "obj-9",
					"maxclass": "newobj",
					"numinlets": 0,
					"numoutlets": 0,
					"patching_rect": [
						1550.0,
						40.0,
						170.0,
						22.0
					],
					"text": "p Audio",
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
							960.0,
							364.0
						],
						"openinpresentation": 1,
						"gridsize": [
							15.0,
							15.0
						],
						"enablevscroll": 1,
						"enablehscroll": 0,
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
										210.0,
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
									"text": "⚠ Unfinished. De-correlating ripple stimulus (Yukhnovich et al. 2025); DSP done, UI and docs pending",
									"presentation": 1,
									"presentation_rect": [
										230.0,
										14.0,
										720.0,
										20.0
									],
									"textcolor": [
										0.55,
										0.55,
										0.55,
										1.0
									]
								}
							},
							{
								"box": {
									"id": "obj-4",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										20.0,
										80.0,
										150.0,
										20.0
									],
									"text": "f_chladni_audio",
									"textcolor": [
										0.55,
										0.55,
										0.55,
										1.0
									],
									"presentation": 1,
									"presentation_rect": [
										10.0,
										42.0,
										210.0,
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
										260.0,
										80.0,
										150.0,
										20.0
									],
									"text": "⚠ Unverified. Audio-input companion for f_chladni: pitch drives note, amplitude amp. No reference doc",
									"presentation": 1,
									"presentation_rect": [
										230.0,
										42.0,
										720.0,
										20.0
									],
									"textcolor": [
										0.55,
										0.55,
										0.55,
										1.0
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
