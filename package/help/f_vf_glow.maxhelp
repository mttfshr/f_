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
			830.0
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
					"text": "Glow",
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
					"text": "Bloom that follows a vecfield instead of spreading evenly: halos, trails, feathered edges",
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
						156.0
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
					"text": "External Control Messages\n\nradius [0 \u2013 0.2]\nfalloff [0 \u2013 0.05]\ngain [0 \u2013 1.5]\nmix_pct [0 \u2013 100]\ncolor_mix [0 \u2013 1]\ndirection [0 \u2013 2]",
					"fontsize": 12.0,
					"linecount": 8
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
						336.0,
						270.0,
						170.0
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
					"text": "References\n\nSee docs/f-reference/f_vf_glow.md and\ndocs/f-reference/f_vecfield_type.md.\n\nThe field is read once, at the pixel: each\npixel sums along a straight line, not a\ncurved streamline.",
					"fontsize": 12.0,
					"linecount": 9
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
					"name": "f_vf_glow.maxpat",
					"numinlets": 3,
					"numoutlets": 2,
					"outlettype": [
						"jit_gl_texture",
						"jit_gl_texture"
					],
					"patching_rect": [
						338.0,
						328.0,
						208.0,
						130.0
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
					"varname": "f_vf_glow"
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
						466.0,
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
						556.0,
						328.0,
						205.0,
						98.0
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
					"text": "Source on inlet 0, a vecfield on\ninlet 1: with no field nothing\nspreads. Left outlet is the\ncomposite, right the glow alone,\na blurred copy of the source.",
					"fontsize": 12.0,
					"linecount": 5
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
					"id": "d-6",
					"maxclass": "bpatcher",
					"name": "f_vf_vortex.maxpat",
					"numinlets": 5,
					"numoutlets": 1,
					"outlettype": [
						"jit_gl_texture"
					],
					"patching_rect": [
						435.0,
						156.0,
						200.0,
						164.0
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
					"varname": "f_vf_vortex"
				}
			},
			{
				"box": {
					"id": "d-10",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						590.0,
						466.0,
						176.0,
						220.0
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
					"text": "Mix starts at 0, where the\ncomposite is just the source, so\nthis patch sets it to 50. The glow\nadds to the source, so the frame\nbrightens.\n\nVortex here gives radial streaks\nfrom the center. Raise Curl to\nswirl them; Dir 1 or 2 with a\nlonger Radius for one-way trails.\nFieldmap on the source as the\nfield feathers edges.",
					"fontsize": 12.0,
					"linecount": 12
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"id": "d-11",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"bang"
					],
					"patching_rect": [
						362.0,
						165.0,
						60.0,
						22.0
					],
					"text": "loadbang"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"id": "d-12",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"bang"
					],
					"patching_rect": [
						362.0,
						195.0,
						60.0,
						22.0
					],
					"text": "delay 300"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"id": "d-13",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						362.0,
						225.0,
						68.0,
						22.0
					],
					"text": "mix_pct 50"
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
			},
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
						"d-6",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"d-12",
						0
					],
					"source": [
						"d-11",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"d-13",
						0
					],
					"source": [
						"d-12",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"d-4",
						0
					],
					"source": [
						"d-13",
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