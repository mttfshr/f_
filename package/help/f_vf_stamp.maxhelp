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
					"bgcolor": [
						0.2,
						0.2,
						0.2,
						0.0
					],
					"fontface": 0,
					"fontname": "Ableton Sans Medium",
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
					"text": "Stamp",
					"saved_attribute_attributes": {
						"textcolor": {
							"expression": "themecolor.live_control_fg"
						}
					},
					"fontsize": 36.0,
					"varname": "autohelp_top_digest[4]"
				}
			},
			{
				"box": {
					"bgcolor": [
						0.2,
						0.2,
						0.2,
						0.0
					],
					"fontface": 0,
					"fontname": "Ableton Sans Light",
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
					"text": "Gated stamp -- ink and an impulse vecfield on a held press",
					"saved_attribute_attributes": {
						"textcolor": {
							"expression": "themecolor.live_control_fg"
						}
					},
					"fontsize": 14.0,
					"varname": "autohelp_top_digest[3]",
					"linecount": 2
				}
			},
			{
				"box": {
					"bgcolor": [
						0.2,
						0.2,
						0.2,
						0.0
					],
					"fontface": 0,
					"fontname": "Ableton Sans Light",
					"id": "d-8",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						15.0,
						150.0,
						270.0,
						198.0
					],
					"text": "External Control Messages\n\nthreshold [0.0 \u2013 1.0]\nsoftness [0.0 \u2013 1.0]\namount [0.0 \u2013 4.0]\nforce [0.0 \u2013 2.0]\nrim [0.005 \u2013 0.05]\nattack [0.0 \u2013 60.0]\nrelease [0.0 \u2013 120.0]\ninvert [0 / 1]\nimpulse [0 / 1]\nstamp [bang / 1 / 0]",
					"saved_attribute_attributes": {
						"textcolor": {
							"expression": "themecolor.live_control_fg"
						}
					},
					"linecount": 12
				}
			},
			{
				"box": {
					"bgcolor": [
						0.2,
						0.2,
						0.2,
						0.0
					],
					"fontface": 0,
					"fontname": "Ableton Sans Light",
					"id": "i-1",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						15.0,
						362.0,
						270.0,
						165.0
					],
					"text": "Inlets and outlets\n\nIn 0: the stamp. Its luma is the mask, its RGB the ink.\nIn 1 (optional): a vecfield, masked by the stamp. Empty: the push comes from the stamp's edge, Radial or Swirl.\nHold Stamp to pour, tap it for a kick.\nOut 0: ink, for f_vf_advect. Out 1: impulse, for f_vf_fluid's force inlet. Project there removes Radial and keeps Swirl.",
					"saved_attribute_attributes": {
						"textcolor": {
							"expression": "themecolor.live_control_fg"
						}
					},
					"linecount": 10
				}
			},
			{
				"box": {
					"bgcolor": [
						0.2,
						0.2,
						0.2,
						0.0
					],
					"fontface": 0,
					"fontname": "Ableton Sans Light",
					"id": "r-1",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						15.0,
						540.0,
						270.0,
						170.0
					],
					"text": "References\n\nDesigned in development -- no outside source.\nCoverage: smoothstep of Rec.709 luma.\nRadial: the central difference of the mask, negated.\nSwirl: the same field turned 90 degrees.\nEnvelope: a one-pole per draw, in frames.\n\nSee docs/f-reference/f_vf_stamp.md",
					"saved_attribute_attributes": {
						"textcolor": {
							"expression": "themecolor.live_control_fg"
						}
					},
					"fontsize": 12.0
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
					"bgmode": 1,
					"border": 1,
					"clickthrough": 0,
					"enablehscroll": 0,
					"enablevscroll": 0,
					"id": "d-3",
					"lockeddragscroll": 0,
					"lockedsize": 0,
					"maxclass": "bpatcher",
					"name": "vs_sources_main.maxpat",
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
						338.0,
						23.75,
						296.4,
						125.5
					],
					"viewvisibility": 1
				}
			},
			{
				"box": {
					"bgcolor": [
						0.0,
						0.0,
						0.0,
						0.0
					],
					"fontface": 0,
					"fontname": "Ableton Sans Light",
					"id": "d-9",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						352.0,
						156.0,
						200.0,
						26.0
					],
					"text": "stamp texture (where)",
					"saved_attribute_attributes": {
						"textcolor": {
							"expression": "themecolor.live_control_fg"
						}
					},
					"bubble": 1,
					"bubbleside": 1
				}
			},
			{
				"box": {
					"bgmode": 1,
					"border": 1,
					"clickthrough": 0,
					"enablehscroll": 0,
					"enablevscroll": 0,
					"id": "d-4",
					"lockeddragscroll": 0,
					"lockedsize": 0,
					"maxclass": "bpatcher",
					"name": "f_vf_stamp.maxpat",
					"numinlets": 2,
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
						338.0,
						200.0,
						190.0,
						232.0
					],
					"viewvisibility": 1,
					"varname": "f_vf_stamp"
				}
			},
			{
				"box": {
					"bgmode": 1,
					"border": 1,
					"clickthrough": 0,
					"enablehscroll": 0,
					"enablevscroll": 0,
					"id": "d-5",
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
						338.0,
						450.0,
						236.0,
						249.0
					],
					"viewvisibility": 1
				}
			}
		],
		"lines": [
			{
				"patchline": {
					"destination": [
						"d-4",
						0
					],
					"source": [
						"d-3",
						0
					]
				}
			},
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
		"autosave": 0
	}
}