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
			99.0,
			871.0,
			780.0
		],
		"gridonopen": 2,
		"toolbarvisible": 0,
		"helpsidebarclosed": 1,
		"boxes": [
			{
				"box": {
					"id": "h-1",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						15.0,
						15.0,
						270.0,
						50.0
					],
					"fontface": 0,
					"fontname": "Ableton Sans Medium",
					"bgcolor": [
						0.2,
						0.2,
						0.2,
						0.0
					],
					"saved_attribute_attributes": {
						"textcolor": {
							"expression": "themecolor.live_control_fg"
						}
					},
					"text": "N-gon",
					"fontsize": 36.0,
					"varname": "autohelp_top_digest[4]"
				}
			},
			{
				"box": {
					"id": "h-2",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						15.0,
						75.0,
						270.0,
						40.0
					],
					"fontface": 0,
					"fontname": "Ableton Sans Light",
					"bgcolor": [
						0.2,
						0.2,
						0.2,
						0.0
					],
					"saved_attribute_attributes": {
						"textcolor": {
							"expression": "themecolor.live_control_fg"
						}
					},
					"text": "Regular N-gon generator / mask, live-modulatable vertex count (UNFINISHED -- not yet confirmed)",
					"fontsize": 14.0,
					"linecount": 2,
					"varname": "autohelp_top_digest[3]"
				}
			},
			{
				"box": {
					"id": "d-8",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						15.0,
						150.0,
						270.0,
						102.0
					],
					"fontface": 0,
					"fontname": "Ableton Sans Light",
					"bgcolor": [
						0.2,
						0.2,
						0.2,
						0.0
					],
					"saved_attribute_attributes": {
						"textcolor": {
							"expression": "themecolor.live_control_fg"
						}
					},
					"text": "External Control Messages\n\nn_mirrors [2 \u2013 18]\nrotation [0 \u2013 6.28319]\nscale [0 \u2013 2]\nbypass [0 / 1]",
					"fontsize": 12.0,
					"linecount": 6
				}
			},
			{
				"box": {
					"id": "r-1",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						15.0,
						272.0,
						270.0,
						120.0
					],
					"fontface": 0,
					"fontname": "Ableton Sans Light",
					"bgcolor": [
						0.2,
						0.2,
						0.2,
						0.0
					],
					"saved_attribute_attributes": {
						"textcolor": {
							"expression": "themecolor.live_control_fg"
						}
					},
					"text": "References\n\nSee ideas/f_ngon.md (the pre-spec questions)\nand docs/f-reference/f_ngon.md if present.\nREADME marks this module Unfinished.",
					"fontsize": 12.0,
					"linecount": 5
				}
			},
			{
				"box": {
					"id": "obj-1",
					"maxclass": "panel",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						0.0,
						-2.0,
						303.0,
						765.0
					]
				}
			},
			{
				"box": {
					"id": "d-4",
					"maxclass": "bpatcher",
					"name": "f_ngon.maxpat",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"jit_gl_texture"
					],
					"patching_rect": [
						338.0,
						24.0,
						171.5,
						101.0
					],
					"bgmode": 1,
					"border": 1,
					"clickthrough": 0,
					"enablehscroll": 0,
					"enablevscroll": 0,
					"lockeddragscroll": 0,
					"lockedsize": 0,
					"offset": [
						0.0,
						0.0
					],
					"viewvisibility": 1,
					"varname": "f_ngon"
				}
			},
			{
				"box": {
					"id": "d-5",
					"maxclass": "bpatcher",
					"name": "vs_preview.maxpat",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"jit_gl_texture"
					],
					"patching_rect": [
						338.0,
						145.0,
						236.0,
						249.0
					],
					"bgmode": 1,
					"border": 1,
					"clickthrough": 0,
					"enablehscroll": 0,
					"enablevscroll": 0,
					"lockeddragscroll": 0,
					"lockedsize": 0,
					"offset": [
						0.0,
						0.0
					],
					"viewvisibility": 1
				}
			},
			{
				"box": {
					"id": "d-9",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						500.0,
						410.0,
						210.0,
						51.0
					],
					"fontface": 0,
					"fontname": "Ableton Sans Light",
					"bgcolor": [
						0.0,
						0.0,
						0.0,
						0.0
					],
					"bubble": 1,
					"text": "Pure generator; try n_mirrors sweeps\nfor kaleidoscope masks.",
					"fontsize": 12.0,
					"linecount": 2
				}
			}
		],
		"lines": [
			{
				"patchline": {
					"destination": [
						"d-5",
						0
					],
					"source": [
						"d-4",
						0
					]
				}
			}
		],
		"parameters": {
			"inherited_shortname": 1
		},
		"autosave": 0
	}
}