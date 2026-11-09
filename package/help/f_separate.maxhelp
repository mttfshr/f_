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
			1430.0,
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
					"text": "Separate",
					"fontsize": 36.0,
					"varname": "autohelp_top_digest[4]",
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
					"text": "First stage of a print look: pulls a color image apart into up to three inks, so each can be treated on its own.",
					"fontsize": 14.0,
					"varname": "autohelp_top_digest[3]",
					"linecount": 3,
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
					"id": "d-8",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						15.0,
						150.0,
						270.0,
						140.0
					],
					"text": "External Control Messages\n\nn_inks [1 – 3]\nsep_mode [0 Unmix / 1 Nearest / 2 Project]\ngain1 gain2 gain3 [0.0 – 2.0]\nsat1 sat2 sat3 [0.0 – 1.0]\nink1 ink2 ink3 [r g b, each 0.0 – 1.0]",
					"linecount": 7,
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
					"id": "d-9",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						15.0,
						310.0,
						270.0,
						225.0
					],
					"text": "Modes\n\nUnmix: the best fit of all the inks together. Plates depend on each other.\n\nNearest: each pixel wholly to its nearest ink, or to none when black is nearest.\n\nProject: each ink alone, so moving one ink never changes another plate. The preview can overshoot.",
					"linecount": 12,
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
					"id": "r-1",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						15.0,
						550.0,
						270.0,
						175.0
					],
					"text": "References\n\nInks are colors of light on black, and add:\npixel = sum of coverage * ink color.\n\nUnmix: least squares by the normal equations,\nc = (K^T K + lam I)^-1 K^T x, with a small ridge.\n\nThe ink model and the Nearest and Project\nmodes are original. See docs/f-reference.",
					"fontsize": 12.0,
					"linecount": 10,
					"saved_attribute_attributes": {
						"textcolor": {
							"expression": "themecolor.live_control_fg"
						}
					}
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
					"bgmode": 1,
					"border": 1,
					"clickthrough": 0,
					"enablehscroll": 0,
					"enablevscroll": 0,
					"id": "d-4",
					"lockeddragscroll": 0,
					"lockedsize": 0,
					"maxclass": "bpatcher",
					"name": "f_separate.maxpat",
					"numinlets": 1,
					"numoutlets": 4,
					"offset": [
						0.0,
						0.0
					],
					"outlettype": [
						"jit_gl_texture",
						"jit_gl_texture",
						"jit_gl_texture",
						"jit_gl_texture"
					],
					"patching_rect": [
						338.0,
						175.0,
						191.0,
						200.0
					],
					"viewvisibility": 1,
					"varname": "f_separate"
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
						400.0,
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
						400.0,
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
					"id": "d-5c",
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
						830.0,
						400.0,
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
					"id": "d-5d",
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
						1076.0,
						400.0,
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
						652.0,
						236.0,
						22.0
					],
					"text": "Plate 1",
					"linecount": 1,
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
						652.0,
						236.0,
						22.0
					],
					"text": "Plate 2",
					"linecount": 1,
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
					"id": "l-3",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						830.0,
						652.0,
						236.0,
						22.0
					],
					"text": "Plate 3",
					"linecount": 1,
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
					"id": "l-4",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						1076.0,
						652.0,
						236.0,
						22.0
					],
					"text": "Preview (plates summed)",
					"linecount": 1,
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
			},
			{
				"patchline": {
					"destination": [
						"d-5c",
						0
					],
					"source": [
						"d-4",
						2
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"d-5d",
						0
					],
					"source": [
						"d-4",
						3
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