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
			900.0,
			800.0
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
					"text": "Immiscible",
					"saved_attribute_attributes": {
						"textcolor": {
							"expression": "themecolor.live_control_fg"
						}
					},
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
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						15.0,
						75.0,
						270.0,
						40.0
					],
					"text": "Two velocity fields that will not mix -- a phase field decides where each one shows",
					"saved_attribute_attributes": {
						"textcolor": {
							"expression": "themecolor.live_control_fg"
						}
					},
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
					"fontsize": 13.0,
					"id": "d-8",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						15.0,
						150.0,
						270.0,
						202.0
					],
					"text": "External Control Messages\n\ndt [0.0 – 0.05]\niface [1.5 – 12.0]\ncoarsen [0.0 – 1.0]\ninject [0.0 – 1.0]\nthresh [0.0 – 0.9]\npull [0.0 – 1.0]\nfill [-0.6 – 0.6]\nmix_pct [0 – 100]\ntaps [1 – 16]\nreset [bang]\nbypass [0 / 1]",
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
					"fontsize": 12.0,
					"id": "r-1",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						15.0,
						392.0,
						270.0,
						380.0
					],
					"text": "References\n\nPhase model: the Cahn-Hilliard\nequation, stepped in Fourier space\nwith a stabilised semi-implicit\nsplit.\nCahn & Hilliard (1958)\n\"Free Energy of a Nonuniform System. I.\"\nJ. Chem. Phys. 28, 258\nEyre (1998) MRS Symp. Proc. 529\n\nBlend, Mix bias, pull and injection\nramp: derived in development --\nnot from any external source.\nConstants are tuned from this\nmodule's own experiments.\n\nNeeds two f_vecfield inputs (in 1\nand in 2); a texture on in 0 is\noptional. Full notes:\ndocs/f-reference/f_vf_immiscible.md",
					"saved_attribute_attributes": {
						"textcolor": {
							"expression": "themecolor.live_control_fg"
						}
					},
					"linecount": 22
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
						845.0
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
						170.0,
						190.0,
						130.0
					],
					"viewvisibility": 1,
					"varname": "f_vf_optical_flow"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"id": "d-10",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"bang"
					],
					"patching_rect": [
						550.0,
						176.0,
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
					"id": "d-11",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"bang"
					],
					"patching_rect": [
						550.0,
						206.0,
						70.0,
						22.0
					],
					"text": "delay 300"
				}
			},
			{
				"box": {
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"id": "d-12",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						338.0,
						322.0,
						110.0,
						22.0
					],
					"text": "viscosity 0.05"
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
						548.0,
						322.0,
						110.0,
						22.0
					],
					"text": "viscosity 0.6"
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
						338.0,
						354.0,
						190.0,
						150.0
					],
					"viewvisibility": 1,
					"varname": "f_vf_fluid_a"
				}
			},
			{
				"box": {
					"bgmode": 1,
					"border": 1,
					"clickthrough": 0,
					"enablehscroll": 0,
					"enablevscroll": 0,
					"id": "d-14",
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
						354.0,
						190.0,
						150.0
					],
					"viewvisibility": 1,
					"varname": "f_vf_fluid_b"
				}
			},
			{
				"box": {
					"bgmode": 1,
					"border": 1,
					"clickthrough": 0,
					"enablehscroll": 0,
					"enablevscroll": 0,
					"id": "d-7",
					"lockeddragscroll": 0,
					"lockedsize": 0,
					"maxclass": "bpatcher",
					"name": "f_vf_immiscible.maxpat",
					"numinlets": 3,
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
						540.0,
						190.0,
						150.0
					],
					"viewvisibility": 1,
					"varname": "f_vf_immiscible"
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
						548.0,
						524.0,
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
					"fontsize": 13.0,
					"id": "d-9",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						750.0,
						354.0,
						140.0,
						150.0
					],
					"text": "Same force into both Fluids, but one is thin (viscosity 0.05) and one thick (0.6). Where the pattern is A you get the thin flow, where it is B the thick one.",
					"bubble": 1,
					"bubbleside": 1
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
					"fontsize": 13.0,
					"id": "d-15",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						338.0,
						700.0,
						190.0,
						80.0
					],
					"text": "Out 1 is the blended velocity: send it to f_vf_advect's vecfield inlet. Out 0 (shown at right) is the pattern itself.",
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
						"d-7",
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
						"d-14",
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
						"d-7",
						1
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
						"d-7",
						2
					],
					"source": [
						"d-14",
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
						"d-7",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"d-11",
						0
					],
					"source": [
						"d-10",
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
						"d-11",
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
						"d-12",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"d-14",
						0
					],
					"source": [
						"d-13",
						0
					]
				}
			}
		]
	}
}
