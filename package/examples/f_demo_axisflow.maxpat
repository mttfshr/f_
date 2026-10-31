{
	"patcher": {
		"fileversion": 1,
		"appversion": {
			"major": 9,
			"minor": 2,
			"revision": 0,
			"architecture": "x64",
			"modernui": 1
		},
		"classnamespace": "box",
		"rect": [
			72.0,
			115.0,
			1151.0,
			882.0
		],
		"boxes": [
			{
				"box": {
					"bgmode": 0,
					"border": 0,
					"clickthrough": 0,
					"enablehscroll": 0,
					"enablevscroll": 0,
					"id": "obj-4",
					"lockeddragscroll": 0,
					"lockedsize": 0,
					"maxclass": "bpatcher",
					"name": "f_modules.maxpat",
					"numinlets": 0,
					"numoutlets": 0,
					"offset": [
						0.0,
						0.0
					],
					"patching_rect": [
						105.0,
						11.0,
						96.0,
						420.0
					],
					"viewvisibility": 1
				}
			},
			{
				"box": {
					"bgmode": 1,
					"border": 1,
					"clickthrough": 0,
					"enablehscroll": 0,
					"enablevscroll": 0,
					"id": "obj-5",
					"lockeddragscroll": 0,
					"lockedsize": 0,
					"maxclass": "bpatcher",
					"name": "vs_modules.maxpat",
					"numinlets": 0,
					"numoutlets": 0,
					"offset": [
						0.0,
						0.0
					],
					"patching_rect": [
						15.0,
						6.0,
						79.0,
						316.0
					],
					"viewvisibility": 1
				}
			},
			{
				"box": {
					"bgmode": 1,
					"border": 1,
					"clickthrough": 0,
					"enablehscroll": 0,
					"enablevscroll": 0,
					"id": "obj-1",
					"lockeddragscroll": 0,
					"lockedsize": 0,
					"maxclass": "bpatcher",
					"name": "vsc_presets.maxpat",
					"numinlets": 1,
					"numoutlets": 1,
					"offset": [
						0.0,
						0.0
					],
					"outlettype": [
						""
					],
					"patching_rect": [
						829.0,
						619.0,
						170.0,
						144.5
					],
					"varname": "vs_presets",
					"viewvisibility": 1
				}
			},
			{
				"box": {
					"autorestore": "f_demo_aniso_blur.json",
					"hidden": 1,
					"id": "obj-10",
					"linecount": 2,
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						829.0,
						706.0,
						138.0,
						35.0
					],
					"saved_object_attributes": {
						"client_rect": [
							854,
							172,
							1208,
							300
						],
						"parameter_enable": 0,
						"parameter_mappable": 0,
						"storage_rect": [
							766,
							44,
							1220,
							302
						]
					},
					"text": "pattrstorage @greedy 1 @changemode 1",
					"varname": "Vsynth"
				}
			},
			{
				"box": {
					"bgmode": 1,
					"border": 1,
					"clickthrough": 0,
					"enablehscroll": 0,
					"enablevscroll": 0,
					"id": "obj-2",
					"lockeddragscroll": 0,
					"lockedsize": 0,
					"maxclass": "bpatcher",
					"name": "vs_render.maxpat",
					"numinlets": 1,
					"numoutlets": 1,
					"offset": [
						0.0,
						0.0
					],
					"outlettype": [
						""
					],
					"patching_rect": [
						728.0,
						618.0,
						96.85526317358028,
						146.5
					],
					"varname": "vs_render",
					"viewvisibility": 1
				}
			},
			{
				"box": {
					"bgmode": 1,
					"border": 1,
					"clickthrough": 0,
					"enablehscroll": 0,
					"enablevscroll": 0,
					"id": "obj-3",
					"lockeddragscroll": 0,
					"lockedsize": 0,
					"maxclass": "bpatcher",
					"name": "vs_output.maxpat",
					"numinlets": 1,
					"numoutlets": 0,
					"offset": [
						0.0,
						0.0
					],
					"patching_rect": [
						810.0,
						585.0,
						157.0,
						22.0
					],
					"varname": "vs_output[1]",
					"viewvisibility": 1
				}
			},
			{
				"box": {
					"bgmode": 1,
					"border": 1,
					"clickthrough": 0,
					"enablehscroll": 0,
					"enablevscroll": 0,
					"id": "obj-8",
					"lockeddragscroll": 0,
					"lockedsize": 0,
					"maxclass": "bpatcher",
					"name": "vs_camera_s.maxpat",
					"numinlets": 1,
					"numoutlets": 1,
					"offset": [
						0.0,
						0.0
					],
					"outlettype": [
						"jit_gl_texture"
					],
					"patching_rect": [
						221.0,
						181.0,
						140.0,
						48.0
					],
					"varname": "vs_camera_s",
					"viewvisibility": 1
				}
			},
			{
				"box": {
					"bgmode": 1,
					"border": 0,
					"clickthrough": 0,
					"enablehscroll": 0,
					"enablevscroll": 0,
					"id": "obj-7",
					"lockeddragscroll": 0,
					"lockedsize": 0,
					"maxclass": "bpatcher",
					"name": "f_tf_tensormap.maxpat",
					"numinlets": 1,
					"numoutlets": 2,
					"offset": [
						0.0,
						0.0
					],
					"outlettype": [
						"jit_gl_texture",
						"jit_gl_texture"
					],
					"patching_rect": [
						234.0,
						327.0,
						154.0,
						84.0
					],
					"varname": "f_tf_tensormap",
					"viewvisibility": 1
				}
			},
			{
				"box": {
					"bgmode": 1,
					"border": 0,
					"clickthrough": 0,
					"enablehscroll": 0,
					"enablevscroll": 0,
					"id": "obj-50",
					"lockeddragscroll": 0,
					"lockedsize": 0,
					"maxclass": "bpatcher",
					"name": "f_tf_axisflow.maxpat",
					"numinlets": 2,
					"numoutlets": 1,
					"offset": [
						0.0,
						0.0
					],
					"outlettype": [
						"jit_gl_texture"
					],
					"patching_rect": [
						420.0,
						110.0,
						154.0,
						90.0
					],
					"varname": "f_tf_axisflow",
					"viewvisibility": 1
				}
			},
			{
				"box": {
					"bgmode": 1,
					"border": 0,
					"clickthrough": 0,
					"enablehscroll": 0,
					"enablevscroll": 0,
					"id": "obj-53",
					"lockeddragscroll": 0,
					"lockedsize": 0,
					"maxclass": "bpatcher",
					"name": "f_vf_advect.maxpat",
					"numinlets": 2,
					"numoutlets": 3,
					"offset": [
						0.0,
						0.0
					],
					"outlettype": [
						"jit_gl_texture",
						"jit_gl_texture",
						"jit_gl_texture"
					],
					"patching_rect": [
						585.0,
						60.0,
						190.0,
						150.0
					],
					"varname": "f_vf_advect",
					"viewvisibility": 1
				}
			},
			{
				"box": {
					"bgmode": 1,
					"border": 1,
					"clickthrough": 0,
					"enablehscroll": 0,
					"enablevscroll": 0,
					"id": "obj-57",
					"lockeddragscroll": 0,
					"lockedsize": 0,
					"maxclass": "bpatcher",
					"name": "vs_preview.maxpat",
					"numinlets": 1,
					"numoutlets": 1,
					"offset": [
						0.0,
						0.0
					],
					"outlettype": [
						"jit_gl_texture"
					],
					"patching_rect": [
						790.0,
						20.0,
						300.0,
						170.0
					],
					"viewvisibility": 1
				}
			},
			{
				"box": {
					"bgmode": 1,
					"border": 0,
					"clickthrough": 0,
					"enablehscroll": 0,
					"enablevscroll": 0,
					"id": "obj-51",
					"lockeddragscroll": 0,
					"lockedsize": 0,
					"maxclass": "bpatcher",
					"name": "f_tf_axisflow.maxpat",
					"numinlets": 2,
					"numoutlets": 1,
					"offset": [
						0.0,
						0.0
					],
					"outlettype": [
						"jit_gl_texture"
					],
					"patching_rect": [
						420.0,
						300.0,
						154.0,
						90.0
					],
					"varname": "f_tf_axisflow[1]",
					"viewvisibility": 1
				}
			},
			{
				"box": {
					"bgmode": 1,
					"border": 0,
					"clickthrough": 0,
					"enablehscroll": 0,
					"enablevscroll": 0,
					"id": "obj-54",
					"lockeddragscroll": 0,
					"lockedsize": 0,
					"maxclass": "bpatcher",
					"name": "f_vf_advect.maxpat",
					"numinlets": 2,
					"numoutlets": 3,
					"offset": [
						0.0,
						0.0
					],
					"outlettype": [
						"jit_gl_texture",
						"jit_gl_texture",
						"jit_gl_texture"
					],
					"patching_rect": [
						585.0,
						250.0,
						190.0,
						150.0
					],
					"varname": "f_vf_advect[1]",
					"viewvisibility": 1
				}
			},
			{
				"box": {
					"bgmode": 1,
					"border": 1,
					"clickthrough": 0,
					"enablehscroll": 0,
					"enablevscroll": 0,
					"id": "obj-58",
					"lockeddragscroll": 0,
					"lockedsize": 0,
					"maxclass": "bpatcher",
					"name": "vs_preview.maxpat",
					"numinlets": 1,
					"numoutlets": 1,
					"offset": [
						0.0,
						0.0
					],
					"outlettype": [
						"jit_gl_texture"
					],
					"patching_rect": [
						790.0,
						200.0,
						300.0,
						170.0
					],
					"viewvisibility": 1
				}
			},
			{
				"box": {
					"bgmode": 1,
					"border": 0,
					"clickthrough": 0,
					"enablehscroll": 0,
					"enablevscroll": 0,
					"id": "obj-52",
					"lockeddragscroll": 0,
					"lockedsize": 0,
					"maxclass": "bpatcher",
					"name": "f_tf_axisflow.maxpat",
					"numinlets": 2,
					"numoutlets": 1,
					"offset": [
						0.0,
						0.0
					],
					"outlettype": [
						"jit_gl_texture"
					],
					"patching_rect": [
						420.0,
						480.0,
						154.0,
						90.0
					],
					"varname": "f_tf_axisflow[2]",
					"viewvisibility": 1
				}
			},
			{
				"box": {
					"bgmode": 1,
					"border": 0,
					"clickthrough": 0,
					"enablehscroll": 0,
					"enablevscroll": 0,
					"id": "obj-55",
					"lockeddragscroll": 0,
					"lockedsize": 0,
					"maxclass": "bpatcher",
					"name": "f_vf_advect.maxpat",
					"numinlets": 2,
					"numoutlets": 3,
					"offset": [
						0.0,
						0.0
					],
					"outlettype": [
						"jit_gl_texture",
						"jit_gl_texture",
						"jit_gl_texture"
					],
					"patching_rect": [
						585.0,
						440.0,
						190.0,
						150.0
					],
					"varname": "f_vf_advect[2]",
					"viewvisibility": 1
				}
			},
			{
				"box": {
					"bgmode": 1,
					"border": 1,
					"clickthrough": 0,
					"enablehscroll": 0,
					"enablevscroll": 0,
					"id": "obj-59",
					"lockeddragscroll": 0,
					"lockedsize": 0,
					"maxclass": "bpatcher",
					"name": "vs_preview.maxpat",
					"numinlets": 1,
					"numoutlets": 1,
					"offset": [
						0.0,
						0.0
					],
					"outlettype": [
						"jit_gl_texture"
					],
					"patching_rect": [
						790.0,
						380.0,
						300.0,
						170.0
					],
					"viewvisibility": 1
				}
			},
			{
				"box": {
					"bgmode": 1,
					"border": 0,
					"clickthrough": 0,
					"enablehscroll": 0,
					"enablevscroll": 0,
					"id": "obj-56",
					"lockeddragscroll": 0,
					"lockedsize": 0,
					"maxclass": "bpatcher",
					"name": "f_vf_vortex.maxpat",
					"numinlets": 5,
					"numoutlets": 1,
					"offset": [
						0.0,
						0.0
					],
					"outlettype": [
						"jit_gl_texture"
					],
					"patching_rect": [
						215.0,
						480.0,
						196.0,
						160.0
					],
					"varname": "f_vf_vortex",
					"viewvisibility": 1
				}
			},
			{
				"box": {
					"fontsize": 12.0,
					"id": "obj-60",
					"linecount": 1,
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						221.0,
						8.0,
						360.0,
						22.0
					],
					"text": "f_tf_axisflow: image structure becomes a flow field"
				}
			},
			{
				"box": {
					"fontsize": 12.0,
					"id": "obj-61",
					"linecount": 5,
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						221.0,
						36.0,
						195.0,
						100.0
					],
					"text": "camera -> tensormap\n-> OUTLET 1 (packed)\n-> Axis Flow -> Advect\n(vecfield in); camera also\n-> Advect (texture in)."
				}
			},
			{
				"box": {
					"fontsize": 12.0,
					"id": "obj-62",
					"linecount": 1,
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						420.0,
						88.0,
						160.0,
						20.0
					],
					"text": "A: Along (flow follows edges)"
				}
			},
			{
				"box": {
					"fontsize": 12.0,
					"id": "obj-63",
					"linecount": 1,
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						420.0,
						278.0,
						160.0,
						20.0
					],
					"text": "B: Across (flow crosses edges)"
				}
			},
			{
				"box": {
					"fontsize": 12.0,
					"id": "obj-64",
					"linecount": 1,
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						420.0,
						458.0,
						160.0,
						20.0
					],
					"text": "C: Along, steered by a vortex"
				}
			},
			{
				"box": {
					"fontsize": 12.0,
					"id": "obj-65",
					"linecount": 1,
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						215.0,
						458.0,
						195.0,
						20.0
					],
					"text": "reference vecfield (C only)"
				}
			},
			{
				"box": {
					"fontsize": 12.0,
					"id": "obj-66",
					"linecount": 5,
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						215.0,
						655.0,
						505.0,
						100.0
					],
					"text": "TOP preview / output = A. Middle = B. Bottom = C.\nA and B differ only in Mode: the same edges, the picture is dragged along them (A) or pushed through them (B).\nC feeds f_vf_vortex into Axis Flow inlet 2, so the flow follows edges but is weighted and steered by the vortex\n(flow scales with the reference length: strongest near the vortex, fading away from it).\nAxis Flow takes tensormap OUTLET 1 (packed), not outlet 0."
				}
			},
			{
				"box": {
					"fontsize": 12.0,
					"id": "obj-67",
					"linecount": 6,
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						215.0,
						760.0,
						505.0,
						100.0
					],
					"text": "Settings (preset slot 1; recall it if the dials did not load):\ntensormap: Radius 6, Strength 100.\nAxis Flow: Angle 45, Gain 1, Gate 1 (Mode Along A / Across B / Along C).\nAdvect: dt 0.003, Decay 0.97, Inject 0.1, Mode Ride, Trail 0.\nVortex: Curl 0.8, Converge 0, Falloff 0.6.\nStarting values, not tuned. Sweep Angle (edges parallel to it flow most), then Gain / dt."
				}
			}
		],
		"lines": [
			{
				"patchline": {
					"destination": [
						"obj-10",
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
						"obj-7",
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
						"obj-50",
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
						"obj-53",
						1
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
						"obj-53",
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
						"obj-57",
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
						"obj-51",
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
						"obj-54",
						1
					],
					"source": [
						"obj-51",
						0
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
						"obj-8",
						0
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
						"obj-54",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-52",
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
						"obj-55",
						1
					],
					"source": [
						"obj-52",
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
						"obj-8",
						0
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
						"obj-55",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-52",
						1
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
						"obj-3",
						0
					],
					"source": [
						"obj-53",
						0
					]
				}
			}
		],
		"parameters": {
			"obj-1::obj-10": [
				"vs_preset_name",
				"vs_preset_name",
				0
			],
			"obj-1::obj-11": [
				"live.text[5]",
				"live.text",
				0
			],
			"obj-1::obj-15": [
				"live.tab",
				"live.tab",
				0
			],
			"obj-1::obj-32": [
				"live.numbox[4]",
				"live.numbox",
				0
			],
			"obj-1::obj-44": [
				"live.tab[3]",
				"live.tab",
				0
			],
			"obj-1::obj-45::obj-16": [
				"live.menu[16]",
				"live.menu[16]",
				0
			],
			"obj-1::obj-45::obj-17": [
				"live.button",
				"live.button",
				0
			],
			"obj-1::obj-45::obj-19": [
				"live.numbox[2]",
				"live.numbox[1]",
				0
			],
			"obj-1::obj-45::obj-32": [
				"live.numbox",
				"live.numbox",
				0
			],
			"obj-1::obj-45::obj-9": [
				"live.numbox[3]",
				"live.numbox",
				0
			],
			"obj-2::obj-19": [
				"dim_x",
				"dim_x",
				0
			],
			"obj-2::obj-23": [
				"dim_y",
				"dim_y",
				0
			],
			"obj-2::obj-36": [
				"live.text",
				"live.text",
				0
			],
			"obj-2::obj-40": [
				"live.text[1]",
				"live.text",
				0
			],
			"obj-2::obj-41": [
				"dim_y[1]",
				"dim_y",
				0
			],
			"obj-2::obj-42": [
				"dim_x[1]",
				"dim_x",
				0
			],
			"obj-2::obj-45": [
				"live.text[2]",
				"live.text",
				0
			],
			"obj-2::obj-48": [
				"live.text[4]",
				"live.text",
				0
			],
			"obj-2::obj-5": [
				"live.text[3]",
				"live.text",
				0
			],
			"obj-2::obj-6": [
				"live.text[16]",
				"live.text",
				0
			],
			"obj-3::obj-1": [
				"toggle[3]",
				"toggle[1]",
				0
			],
			"obj-3::obj-10": [
				"toggle[4]",
				"toggle[2]",
				0
			],
			"obj-3::obj-36": [
				"uppr_x[1]",
				"uppr_x",
				0
			],
			"obj-4::obj-12": [
				"f_module_1_disp",
				"live.menu",
				0
			],
			"obj-4::obj-13": [
				"f_module_1_file",
				"live.menu",
				0
			],
			"obj-4::obj-16": [
				"f_module_2_disp",
				"live.menu",
				0
			],
			"obj-4::obj-17": [
				"f_module_2_file",
				"live.menu",
				0
			],
			"obj-4::obj-20": [
				"f_module_3_disp",
				"live.menu",
				0
			],
			"obj-4::obj-21": [
				"f_module_3_file",
				"live.menu",
				0
			],
			"obj-4::obj-24": [
				"f_module_4_disp",
				"live.menu",
				0
			],
			"obj-4::obj-25": [
				"f_module_4_file",
				"live.menu",
				0
			],
			"obj-4::obj-28": [
				"f_module_5_disp",
				"live.menu",
				0
			],
			"obj-4::obj-29": [
				"f_module_5_file",
				"live.menu",
				0
			],
			"obj-4::obj-32": [
				"f_module_6_disp",
				"live.menu",
				0
			],
			"obj-4::obj-33": [
				"f_module_6_file",
				"live.menu",
				0
			],
			"obj-4::obj-36": [
				"f_module_7_disp",
				"live.menu",
				0
			],
			"obj-4::obj-37": [
				"f_module_7_file",
				"live.menu",
				0
			],
			"obj-4::obj-40": [
				"f_module_8_disp",
				"live.menu",
				0
			],
			"obj-4::obj-41": [
				"f_module_8_file",
				"live.menu",
				0
			],
			"obj-4::obj-44": [
				"f_module_9_disp",
				"live.menu",
				0
			],
			"obj-4::obj-45": [
				"f_module_9_file",
				"live.menu",
				0
			],
			"obj-4::obj-8": [
				"f_module_0_disp",
				"live.menu",
				0
			],
			"obj-4::obj-9": [
				"f_module_0_file",
				"live.menu",
				0
			],
			"obj-5::obj-14": [
				"live.menu[18]",
				"live.menu",
				0
			],
			"obj-5::obj-16": [
				"live.menu[29]",
				"live.menu",
				0
			],
			"obj-5::obj-18": [
				"live.menu[33]",
				"live.menu",
				0
			],
			"obj-5::obj-2": [
				"live.menu[23]",
				"live.menu",
				0
			],
			"obj-5::obj-22": [
				"live.menu[26]",
				"live.menu",
				0
			],
			"obj-5::obj-24": [
				"live.menu[31]",
				"live.menu",
				0
			],
			"obj-5::obj-25": [
				"live.menu[27]",
				"live.menu",
				0
			],
			"obj-5::obj-26": [
				"live.menu[30]",
				"live.menu",
				0
			],
			"obj-5::obj-27": [
				"live.menu[28]",
				"live.menu",
				0
			],
			"obj-5::obj-29": [
				"live.menu[24]",
				"live.menu",
				0
			],
			"obj-5::obj-30": [
				"live.menu[19]",
				"live.menu",
				0
			],
			"obj-5::obj-33": [
				"live.menu[32]",
				"live.menu",
				0
			],
			"obj-5::obj-36": [
				"live.menu[20]",
				"live.menu",
				0
			],
			"obj-5::obj-52": [
				"live.menu[21]",
				"live.menu",
				0
			],
			"obj-5::obj-53": [
				"live.menu[22]",
				"live.menu",
				0
			],
			"obj-5::obj-56": [
				"live.menu[25]",
				"live.menu",
				0
			],
			"obj-7::obj-20": [
				"strength[2]",
				"strength",
				0
			],
			"obj-7::obj-23": [
				"radius",
				"radius",
				0
			],
			"obj-8::obj-20": [
				"cam_invx",
				"flip_x",
				0
			],
			"obj-8::obj-3": [
				"what",
				"live.text",
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
			"parameter_overrides": {
				"obj-1::obj-11": {
					"parameter_longname": "live.text[5]"
				},
				"obj-1::obj-15": {
					"parameter_longname": "live.tab"
				},
				"obj-1::obj-32": {
					"parameter_longname": "live.numbox[4]"
				},
				"obj-2::obj-19": {
					"parameter_longname": "dim_x"
				},
				"obj-2::obj-23": {
					"parameter_longname": "dim_y",
					"parameter_shortname": "dim_y"
				},
				"obj-2::obj-36": {
					"parameter_longname": "live.text"
				},
				"obj-2::obj-40": {
					"parameter_longname": "live.text[1]"
				},
				"obj-2::obj-41": {
					"parameter_longname": "dim_y[1]"
				},
				"obj-2::obj-42": {
					"parameter_longname": "dim_x[1]"
				},
				"obj-2::obj-45": {
					"parameter_longname": "live.text[2]"
				},
				"obj-2::obj-48": {
					"parameter_longname": "live.text[4]"
				},
				"obj-2::obj-5": {
					"parameter_longname": "live.text[3]"
				},
				"obj-2::obj-6": {
					"parameter_longname": "live.text[16]"
				},
				"obj-5::obj-14": {
					"parameter_longname": "live.menu[18]"
				},
				"obj-5::obj-16": {
					"parameter_longname": "live.menu[29]"
				},
				"obj-5::obj-18": {
					"parameter_longname": "live.menu[33]"
				},
				"obj-5::obj-2": {
					"parameter_longname": "live.menu[23]"
				},
				"obj-5::obj-22": {
					"parameter_longname": "live.menu[26]"
				},
				"obj-5::obj-24": {
					"parameter_longname": "live.menu[31]"
				},
				"obj-5::obj-25": {
					"parameter_longname": "live.menu[27]"
				},
				"obj-5::obj-26": {
					"parameter_longname": "live.menu[30]"
				},
				"obj-5::obj-27": {
					"parameter_longname": "live.menu[28]"
				},
				"obj-5::obj-29": {
					"parameter_longname": "live.menu[24]"
				},
				"obj-5::obj-30": {
					"parameter_longname": "live.menu[19]"
				},
				"obj-5::obj-33": {
					"parameter_longname": "live.menu[32]"
				},
				"obj-5::obj-36": {
					"parameter_longname": "live.menu[20]"
				},
				"obj-5::obj-52": {
					"parameter_longname": "live.menu[21]"
				},
				"obj-5::obj-53": {
					"parameter_longname": "live.menu[22]"
				},
				"obj-5::obj-56": {
					"parameter_longname": "live.menu[25]"
				},
				"obj-7::obj-20": {
					"parameter_invisible": 0,
					"parameter_longname": "strength[2]",
					"parameter_modmode": 3,
					"parameter_steps": 0,
					"parameter_type": 0,
					"parameter_unitstyle": 1
				},
				"obj-7::obj-23": {
					"parameter_invisible": 0,
					"parameter_modmode": 3,
					"parameter_steps": 0,
					"parameter_type": 0,
					"parameter_unitstyle": 1
				}
			},
			"inherited_shortname": 1
		},
		"autosave": 0,
		"boxgroups": [
			{
				"boxes": [
					"obj-1",
					"obj-10"
				]
			}
		]
	}
}