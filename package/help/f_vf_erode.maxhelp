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
					"text": "Erode",
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
						60.0
					],
					"text": "Water and pigment solver -- ink pools in the low places of a terrain",
					"saved_attribute_attributes": {
						"textcolor": {
							"expression": "themecolor.live_control_fg"
						}
					},
					"fontsize": 14.0,
					"linecount": 3,
					"varname": "autohelp_top_digest[3]"
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
						222.0
					],
					"text": "External Control Messages\n\npolar_sw [0 Darker / 1 Lighter]\nflow [0.0 \u2013 2.0]\npush [0.0 \u2013 4.0]\nlift [0.0 \u2013 2.0]\nsettle [0.0 \u2013 0.05]\ndry [0.0 \u2013 0.02]\nspeed [0.0 \u2013 4.0]\nflood [0.0 \u2013 4.0]\nfeed [0.0 \u2013 1.0]\nfade [0.0 \u2013 1.0]\nwet [bang / 1 / 0]",
					"saved_attribute_attributes": {
						"textcolor": {
							"expression": "themecolor.live_control_fg"
						}
					},
					"linecount": 13
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
						388.0,
						270.0,
						205.0
					],
					"text": "How it runs\n\nIn 0 picture, 1 terrain (luma is height), 2 vecfield push, 3 paper. All but 0 are optional.\nPress Wet once: the picture becomes ink, water floods and runs downhill, ink pools low, and it dries still in about ten seconds.\nFeed above 0 follows a moving picture; Fade stops it going black.\nOut 0 ink, out 1 thickness.",
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
					"id": "r-1",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						15.0,
						608.0,
						270.0,
						130.0
					],
					"text": "References\n\nDesigned in development -- no outside source.\nWater: conservative face fluxes (standard finite volume).\nDarker: out = bg * exp(-(p + s)).\nLighter: out = bg + p + s.\n\nSee docs/f-reference/f_vf_erode.md",
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
						0.2,
						0.2,
						0.2,
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
					"text": "picture (inlet 0)",
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
					"id": "d-3b",
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
						190.0,
						296.4,
						125.5
					],
					"viewvisibility": 1
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
					"id": "d-10",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						352.0,
						322.0,
						200.0,
						26.0
					],
					"text": "terrain (inlet 1)",
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
					"name": "f_vf_erode.maxpat",
					"numinlets": 4,
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
						650.0,
						24.0,
						190.0,
						150.0
					],
					"viewvisibility": 1,
					"varname": "f_vf_erode"
				}
			},
			{
				"box": {
					"bgmode": 1,
					"border": 1,
					"clickthrough": 0,
					"enablehscroll": 0,
					"enablevscroll": 0,
					"id": "d-5a",
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
						370.0,
						236.0,
						249.0
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
					"id": "d-5b",
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
						584.0,
						370.0,
						236.0,
						249.0
					],
					"viewvisibility": 1
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
					"id": "l-1",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						338.0,
						622.0,
						236.0,
						22.0
					],
					"text": "Ink (out 0)",
					"saved_attribute_attributes": {
						"textcolor": {
							"expression": "themecolor.live_control_fg"
						}
					}
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
					"id": "l-2",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						584.0,
						622.0,
						236.0,
						22.0
					],
					"text": "Thickness (out 1)",
					"saved_attribute_attributes": {
						"textcolor": {
							"expression": "themecolor.live_control_fg"
						}
					}
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
						"d-4",
						1
					],
					"source": [
						"d-3b",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"d-5a",
						0
					],
					"source": [
						"d-4",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"d-5b",
						0
					],
					"source": [
						"d-4",
						1
					]
				}
			}
		],
		"autosave": 0
	}
}