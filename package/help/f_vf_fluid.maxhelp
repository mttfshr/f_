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
		"autosave": 0,
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
					"fontsize": 36.0,
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
					"saved_attribute_attributes": {
						"textcolor": {
							"expression": "themecolor.live_control_fg"
						}
					},
					"text": "Fluid",
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
					"fontsize": 14.0,
					"id": "h-2",
					"linecount": 2,
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						15.0,
						75.0,
						270.0,
						40.0
					],
					"saved_attribute_attributes": {
						"textcolor": {
							"expression": "themecolor.live_control_fg"
						}
					},
					"text": "Spectral incompressible-flow solver -- force field in, persistent swirling velocity field out",
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
					"linecount": 12,
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						15.0,
						150.0,
						270.0,
						154.0
					],
					"saved_attribute_attributes": {
						"textcolor": {
							"expression": "themecolor.live_control_fg"
						}
					},
					"text": "External Control Messages\n\nforce [0.0 – 0.2]\ndt [0.0 – 0.05]\nviscosity [0.0 – 1.0]\nproject [0.0 – 1.0]\ndrag [0.0 – 5.0]\ngain [0.0 – 10.0]\ntaps [1 – 16]\nbypass [0 / 1]"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"id": "r-1",
					"linecount": 15,
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						15.0,
						344.0,
						270.0,
						300.0
					],
					"text": "References\n\nMethod: Fourier-domain incompressible\nflow on a periodic domain -- Helmholtz\nprojection and exact viscous/drag decay\nper Fourier bin; semi-Lagrangian\nself-advection. Implemented from the\nequations in development; no source\nimplementation is cited.\n\nVerification: Taylor-Green vortex decay\nTaylor, G.I. & Green, A.E. (1937)\n\"Mechanism of the Production of Small\nEddies from Large Ones\"\nProc. R. Soc. A 158\n\nForce tap grid, viscosity dial law and the\ncontent gate on the force input:\nderived in development -- not from any\nexternal source."
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
					"id": "d-6",
					"lockeddragscroll": 0,
					"lockedsize": 0,
					"maxclass": "bpatcher",
					"name": "f_vf_optical_flow.maxpat",
					"numinlets": 1,
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
						190.0,
						190.0,
						130.0
					],
					"varname": "f_vf_optical_flow",
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
					"name": "f_vf_fluid.maxpat",
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
						548.0,
						190.0,
						190.0,
						150.0
					],
					"varname": "f_vf_fluid",
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
						380.0,
						236.0,
						249.0
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
						590.0,
						380.0,
						175.0,
						84.0
					],
					"text": "Try feeding into: f_vf_advect (Fluid to its vecfield inlet), or f_vf_warp / f_vf_glow",
					"fontsize": 13.0,
					"bubble": 1
				}
			}
		],
		"lines": [
			{
				"patchline": {
					"destination": [
						"d-6",
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
						0
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
						"d-5",
						0
					],
					"source": [
						"d-4",
						0
					]
				}
			}
		]
	}
}