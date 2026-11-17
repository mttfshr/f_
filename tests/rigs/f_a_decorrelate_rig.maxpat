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
			480.0
		],
		"default_fontname": "Ableton Sans Light",
		"boxes": [
			{
				"box": {
					"id": "obj-1",
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"maxclass": "comment",
					"text": "f_a_decorrelate standalone test rig (audio archetype Phase C, 2026-11-16). Not part of the module. DSP on, click ezdac~. noise~ is the carrier; the module output has 35 ms latency. A/B with Bypass and Mix. The module's pfft~ inner file ships beside it in package/patchers.",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						20.0,
						10.0,
						640.0,
						45.0
					]
				}
			},
			{
				"box": {
					"id": "obj-2",
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"maxclass": "newobj",
					"text": "noise~",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"signal"
					],
					"patching_rect": [
						20.0,
						70.0,
						60.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-3",
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"maxclass": "newobj",
					"text": "*~ 0.2",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"signal"
					],
					"patching_rect": [
						20.0,
						100.0,
						60.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-4",
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"maxclass": "bpatcher",
					"name": "f_a_decorrelate.maxpat",
					"embed": 0,
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"signal"
					],
					"args": [],
					"offset": [
						0.0,
						0.0
					],
					"patching_rect": [
						20.0,
						140.0,
						330.0,
						152.0
					]
				}
			},
			{
				"box": {
					"id": "obj-5",
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"maxclass": "ezdac~",
					"numinlets": 2,
					"numoutlets": 0,
					"patching_rect": [
						20.0,
						320.0,
						45.0,
						45.0
					]
				}
			},
			{
				"box": {
					"id": "obj-6",
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"maxclass": "spectroscope~",
					"numinlets": 2,
					"numoutlets": 0,
					"patching_rect": [
						90.0,
						310.0,
						300.0,
						130.0
					]
				}
			},
			{
				"box": {
					"id": "obj-7",
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"maxclass": "scope~",
					"numinlets": 2,
					"numoutlets": 0,
					"patching_rect": [
						410.0,
						310.0,
						260.0,
						130.0
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
						"obj-4",
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
						"obj-5",
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
						"obj-5",
						1
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
						"obj-6",
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
						"obj-7",
						0
					]
				}
			}
		],
		"autosave": 0
	}
}