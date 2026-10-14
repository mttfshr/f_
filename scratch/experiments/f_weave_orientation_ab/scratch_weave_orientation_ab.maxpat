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
			80.0,
			80.0,
			640.0,
			950.0
		],
		"gridonopen": 2,
		"toolbarvisible": 1,
		"helpsidebarclosed": 1,
		"boxes": [
			{
				"box": {
					"id": "h-1",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						20.0,
						15.0,
						600.0,
						30.0
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
					"text": "f_weave orientation A/B -- scratch (ideas/f_weave_orientation_blend.md)",
					"fontsize": 16.0
				}
			},
			{
				"box": {
					"id": "h-2",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						20.0,
						45.0,
						600.0,
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
					"text": "field_amount=1.0, fix_blend=0.0 on the left should match the right exactly. Then explore: fix_blend toward 1 = true angular blend (Fix B); field_amount alone with fix_blend=0 = exposed-depth vector-add (Fix A).",
					"fontsize": 12.0,
					"linecount": 2
				}
			},
			{
				"box": {
					"id": "src-label",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						20.0,
						100.0,
						300.0,
						20.0
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
					"text": "Source",
					"fontsize": 12.0
				}
			},
			{
				"box": {
					"id": "src",
					"maxclass": "bpatcher",
					"name": "vs_sources_main.maxpat",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"jit_gl_texture"
					],
					"patching_rect": [
						20.0,
						125.0,
						296.0,
						125.5
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
					"varname": "src"
				}
			},
			{
				"box": {
					"id": "flow-label",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						20.0,
						265.0,
						300.0,
						20.0
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
					"text": "Optical flow (real footage/camera in Source)",
					"fontsize": 12.0
				}
			},
			{
				"box": {
					"id": "flow",
					"maxclass": "bpatcher",
					"name": "f_vf_optical_flow.maxpat",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"jit_gl_texture",
						"jit_gl_texture"
					],
					"patching_rect": [
						20.0,
						290.0,
						154.0,
						91.0
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
					"varname": "flow"
				}
			},
			{
				"box": {
					"id": "oab-label",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						20.0,
						400.0,
						260.0,
						20.0
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
					"text": "SCRATCH -- f_weave_oab (field_amount / fix_blend dials)",
					"fontsize": 12.0
				}
			},
			{
				"box": {
					"id": "oab",
					"maxclass": "bpatcher",
					"name": "f_weave_oab.maxpat",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"jit_gl_texture"
					],
					"patching_rect": [
						20.0,
						425.0,
						220.0,
						219.0
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
					"varname": "oab"
				}
			},
			{
				"box": {
					"id": "prev-oab",
					"maxclass": "bpatcher",
					"name": "vs_preview.maxpat",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"jit_gl_texture"
					],
					"patching_rect": [
						20.0,
						660.0,
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
					"viewvisibility": 1,
					"varname": "prev_oab"
				}
			},
			{
				"box": {
					"id": "ref-label",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						360.0,
						400.0,
						260.0,
						20.0
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
					"text": "REFERENCE -- shipped f_weave (unmodified)",
					"fontsize": 12.0
				}
			},
			{
				"box": {
					"id": "ref",
					"maxclass": "bpatcher",
					"name": "f_weave.maxpat",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"jit_gl_texture"
					],
					"patching_rect": [
						360.0,
						425.0,
						220.0,
						159.0
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
					"varname": "ref"
				}
			},
			{
				"box": {
					"id": "prev-ref",
					"maxclass": "bpatcher",
					"name": "vs_preview.maxpat",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"jit_gl_texture"
					],
					"patching_rect": [
						360.0,
						600.0,
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
					"viewvisibility": 1,
					"varname": "prev_ref"
				}
			}
		],
		"lines": [
			{
				"patchline": {
					"source": [
						"src",
						0
					],
					"destination": [
						"flow",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"flow",
						0
					],
					"destination": [
						"oab",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"flow",
						0
					],
					"destination": [
						"ref",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"oab",
						0
					],
					"destination": [
						"prev-oab",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"ref",
						0
					],
					"destination": [
						"prev-ref",
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