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
					"text": "Chroma",
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
					"text": "Vecfield-driven chromatic streak -- synthesized rainbow march gated by luma (v10, paused retool)",
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
						204.0
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
					"text": "External Control Messages\n\nradius [0 \u2013 0.3]\nhue [0 \u2013 1]\ndispersion [0 \u2013 1]\nsaturation [0 \u2013 1]\nfalloff [0 \u2013 0.01]\nthreshold [0 \u2013 1]\nthreshold_width [0 \u2013 0.5]\nstrength [0 \u2013 2]\ndirection [Fwd/Bwd/Bi]\nbypass [0 / 1]",
					"fontsize": 12.0,
					"linecount": 12
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
						374.0,
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
					"text": "References\n\nSee docs/f-reference/f_vf_chroma.md. Note: mid-retool --\nthe shipped v10 washes the rainbow out at high\ndispersion (accumulation averages hues); the\nclosest-emitter redesign is specced in\n.specify/paused/f_vf_chroma/. direction=Bi is\nunreachable from the UI (build bug).",
					"fontsize": 12.0,
					"linecount": 8
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
					"name": "f_vf_chroma.maxpat",
					"numinlets": 2,
					"numoutlets": 2,
					"outlettype": [
						"jit_gl_texture",
						"jit_gl_texture"
					],
					"patching_rect": [
						338.0,
						24.0,
						208.0,
						190.0
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
					"varname": "f_vf_chroma"
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
						234.0,
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
						499.0,
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
					"text": "Feed a vecfield into in2; bright\nsource areas emit the streak.",
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