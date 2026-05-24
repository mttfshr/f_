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
			34.0,
			56.0,
			300.0,
			250.0
		],
		"openinpresentation": 0,
		"boxes": [
			{
				"box": {
					"id": "obj-1",
					"maxclass": "live.menu",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"int",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						10.0,
						10.0,
						130.0,
						24.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "f_module",
							"parameter_shortname": "f_module",
							"parameter_type": 2,
							"parameter_enum": [
								"Channel Grader",
								"Droste",
								"Grain",
								"Hue Processor",
								"Luma Processor",
								"Tex Router",
								"Tone Curve"
							]
						}
					},
					"varname": "f_module"
				}
			},
			{
				"box": {
					"id": "obj-2",
					"maxclass": "live.menu",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"int",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						10.0,
						60.0,
						130.0,
						24.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "f_module_name",
							"parameter_shortname": "f_module_name",
							"parameter_type": 2,
							"parameter_enum": [
								"channel_grader",
								"droste",
								"grain",
								"hue_processor",
								"luma_processor",
								"texrouter",
								"tone_curve"
							]
						}
					},
					"varname": "f_module_name"
				}
			},
			{
				"box": {
					"id": "obj-3",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						10.0,
						110.0,
						90.0,
						22.0
					],
					"text": "prepend addmod"
				}
			},
			{
				"box": {
					"id": "obj-4",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						10.0,
						170.0,
						100.0,
						22.0
					],
					"saved_object_attributes": {
						"filename": "f_addmod.js",
						"parameter_enable": 0
					},
					"text": "js f_addmod.js"
				}
			},
			{
				"box": {
					"id": "obj-5",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						10.0,
						140.0,
						60.0,
						22.0
					],
					"text": "gate 1 0"
				}
			},
			{
				"box": {
					"id": "obj-6",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						100.0,
						110.0,
						60.0,
						22.0
					],
					"text": "pipe 250"
				}
			},
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
						100.0,
						80.0,
						70.0,
						22.0
					],
					"text": "loadmess 1"
				}
			}
		],
		"lines": [
			{
				"patchline": {
					"source": [
						"obj-1",
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
						"obj-2",
						1
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
						"obj-5",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-7",
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
						"obj-5",
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
						"obj-4",
						0
					]
				}
			}
		],
		"parameters": {
			"obj-1": [
				"f_module",
				"f_module",
				0
			],
			"obj-2": [
				"f_module_name",
				"f_module_name",
				0
			]
		},
		"autosave": 0
	}
}