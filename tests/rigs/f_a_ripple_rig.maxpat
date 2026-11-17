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
			400.0
		],
		"default_fontname": "Ableton Sans Light",
		"boxes": [
			{
				"box": {
					"id": "obj-1",
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"maxclass": "comment",
					"text": "f_a_ripple standalone test rig (audio archetype Phase A, 2026-11-16). Not part of the module. Turn DSP on, click the toggle for dac~, raise Gain. Scope, spectrogram and level meter are the rigs removed from the v1 prototype.",
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
					"maxclass": "bpatcher",
					"name": "f_a_ripple.maxpat",
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
						70.0,
						330.0,
						152.0
					],
					"presentation": 1,
					"presentation_rect": [
						20.0,
						70.0,
						330.0,
						152.0
					]
				}
			},
			{
				"box": {
					"id": "obj-3",
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"maxclass": "ezdac~",
					"numinlets": 2,
					"numoutlets": 0,
					"patching_rect": [
						20.0,
						250.0,
						45.0,
						45.0
					],
					"presentation": 0
				}
			},
			{
				"box": {
					"id": "obj-4",
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"maxclass": "scope~",
					"numinlets": 2,
					"numoutlets": 0,
					"patching_rect": [
						90.0,
						240.0,
						260.0,
						130.0
					]
				}
			},
			{
				"box": {
					"id": "obj-5",
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"maxclass": "spectroscope~",
					"numinlets": 2,
					"numoutlets": 0,
					"patching_rect": [
						370.0,
						240.0,
						300.0,
						130.0
					]
				}
			},
			{
				"box": {
					"id": "obj-6",
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"maxclass": "newobj",
					"text": "peakamp~ 100",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						20.0,
						310.0,
						90.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-7",
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"maxclass": "flonum",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"bang"
					],
					"patching_rect": [
						20.0,
						345.0,
						70.0,
						22.0
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
						"obj-2",
						0
					],
					"destination": [
						"obj-3",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-2",
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
						"obj-2",
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
						"obj-2",
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
						"obj-7",
						0
					]
				}
			}
		],
		"autosave": 0
	}
}