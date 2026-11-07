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
					"text": "Poincare",
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
						40.0
					],
					"text": "Folds a texture into a hyperbolic {p,q} tiling of the Poincare disk -- Escher Circle Limit look",
					"fontsize": 14.0,
					"varname": "autohelp_top_digest[3]",
					"linecount": 2,
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
						160.0
					],
					"text": "External Control Messages\n\nfold_mode [0 / 1]\np_sides [3 – 10]\nq_vertex [3 – 10]\ntile_scale [0.05 – 1.0]\ncam_x [-0.99 – 0.99]\ncam_y [-0.99 – 0.99]\nrot [-3.1416 – 3.1416]",
					"linecount": 8,
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
						350.0,
						270.0,
						250.0
					],
					"text": "References\n\nTiling geometry: the standard right-triangle\nconstruction for regular {p,q} tilings;\ncosh(l) = cos(pi/q) / sin(pi/p),\nvalid when 1/p + 1/q < 1/2.\n\nCamera: the Moebius disk map\nz -> (z - a) / (1 - conj(a) z).\n\nKopczynski et al., \"Conformal Models of the\nHyperbolic Plane\" (HyperRogue) --\nprecision near the disk boundary.\nroguetemple.com/z/hyper/papers/conformal.pdf\n\nThe 3-nearest-circle selection and the\nrim fade are original. See docs/f-reference.",
					"fontsize": 12.0,
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
					"name": "f_poincare.maxpat",
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
						200.0,
						212.0,
						90.0
					],
					"viewvisibility": 1,
					"varname": "f_poincare"
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
						320.0,
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
		"parameters": {
			"inherited_shortname": 1
		},
		"autosave": 0
	}
}