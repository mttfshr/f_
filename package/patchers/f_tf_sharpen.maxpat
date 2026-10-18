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
			100.0,
			800.0,
			600.0
		],
		"openinpresentation": 1,
		"boxes": [
			{
				"box": {
					"id": "obj-1",
					"maxclass": "inlet",
					"comment": "texture / control",
					"index": 0,
					"numinlets": 0,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						30.0,
						20.0,
						30.0,
						30.0
					]
				}
			},
			{
				"box": {
					"id": "obj-2",
					"maxclass": "outlet",
					"comment": "tensor (raw Jxx, Jxy, Jyy)",
					"index": 0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						30.0,
						452.0,
						30.0,
						30.0
					],
					"tricolor": [
						0.85,
						0.55,
						0.2,
						1.0
					],
					"hint": "Raw structure tensor, gap-scaled: R = Jxx'*strength, G = Jxy'*strength*0.5 + 0.5, B = Jyy'*strength, A = 1. Gap = 1 is exact passthrough; relax (<1) eases toward isotropy, exaggerate (>1) commits edges. Axis never changes; trace preserved inside the linear range. Neutral (zero tensor) = (0, 0.5, 0, 1)."
				}
			},
			{
				"box": {
					"id": "obj-3",
					"maxclass": "newobj",
					"numinlets": 3,
					"numoutlets": 3,
					"outlettype": [
						"",
						"",
						""
					],
					"patching_rect": [
						30.0,
						70.0,
						215.0,
						22.0
					],
					"text": "routepass jit_gl_texture jit_matrix"
				}
			},
			{
				"box": {
					"id": "obj-4",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						56.5,
						204.0,
						84.5,
						22.0
					],
					"text": "route sharpen"
				}
			},
			{
				"box": {
					"id": "obj-5",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"jit_gl_texture",
						""
					],
					"patcher": {
						"fileversion": 1,
						"appversion": {
							"major": 9,
							"minor": 1,
							"revision": 4,
							"architecture": "x64",
							"modernui": 1
						},
						"classnamespace": "jit.gen",
						"rect": [
							100.0,
							100.0,
							700.0,
							600.0
						],
						"boxes": [
							{
								"box": {
									"id": "gen-obj-1",
									"maxclass": "newobj",
									"numinlets": 0,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										22.0,
										30.0,
										28.0,
										22.0
									],
									"text": "in 1"
								}
							},
							{
								"box": {
									"code": "// f_tf_sharpen: eigengap exaggerator/relaxer on the raw f_tensor outlet-0\n// encoding. in1 = tensormap out0 (R>=0, G:0.5=zero, B>=0, A=1, all * strength).\n// Per pixel: decode to components, scale the eigengap by g = max(gamma, 0)\n// around the isotropic trace/2 ball while holding trace fixed, re-encode.\n// Mirrors tests/test_tf_sharpen.py sharpen().\n//\n//   J' = g*J + (1 - g) * (trace/2) * I        (plan ADR-2, no eigenvalue swap:\n//    lambda1' = trace/2 + g*(lambda1 - trace/2)\n//    lambda2' = trace/2 + g*(lambda2 - trace/2)   PLUS sign for both --\n//      NOTE the spec prose's MINUS form for lambda2' is a sign slip; the\n//      trace-preserving form is the plus sign, mirror T003/T005 confirm)\n//    Jxy' = g*Jxy\n//\n// gamma = 1 is the bit-exact identity (the mix collapses away); gamma > 1\n// exaggerates anisotropy, gamma < 1 relaxes toward isotropy; gamma = 0 is the\n// exact isotropic tensor with trace preserved. The axis rides through in\n// component space -- NO atan2 anywhere (glyph plan ADR-2 decode idiom, copied\n// verbatim below; gradient-axis/across convention rides unused since we never\n// reconstruct an angle).\n//\n// GATE PROVISIONAL-OPEN (spec OQ1): dial mapping one-sided 0-4 default 1.0\n// shipped here; a bipolar remap in definition.py would need this comment\n// updated. GATE PROVISIONAL-OPEN (spec OQ4): name f_tf_sharpen; a rename is\n// one find-replace across this file/definition.py/docs before live shipping.\n//\n// STRENGTH/FLOOR CAVEAT (plan ADR-3/ADR-4, T008): eps_trace = 1e-6 is an\n// absolute threshold in ENCODED units (post-strength), so the effective\n// pre-gain floor is eps/strength -- floor depth depends on the producing\n// tensormap's strength dial. Below the floor, output == input exactly (a\n// fixed point: vs_black and tensormap's zero-tensor neutral both qualify).\n// \"Flat regions pass through unchanged by design.\"\n//\n// Encode contract: final stage clamps R/B to [0,1] (diagonals unipolar) and G\n// to [0,1] around its 0.5 zero. Beyond the linear range (gamma*coherence > 1\n// can drive lambda2' below 0 / lambda1' above 1) the clamp saturates and trace\n// is no longer preserved there -- recorded in tests/test_tf_sharpen.py\n// (test_encode_clamp_beyond_linear_range); tier-3 judgement decides whether\n// extreme-gamma users care. bypass_gate (module bypass, bypass_mode \"param\";\n// NOT the native @bypass): exact passthrough.\n// pix_type float32 required (tensormap ADR-2 convention).\nParam sharpen(1.0);\nParam bypass_gate(0.0);\n\n// --- decode: glyph plan ADR-2 idiom, copied verbatim (citation, not\n// re-derivation). In-place on the sampled components; the idiom's strength\n// division is dropped because sharpen consumes the STRENGTH-SCALED form\n// directly and its operator is positively homogeneous in the components\n// (plan ADR-4: gamma scales components; a global strength factor commutes,\n// proven at T007 in encoded units).\n//   t = sample(tensor_tex, clamp(cell_uv_to_texel))   // tensormap ADR-5 clamp\n//   // encoding: f_tensor_type.md outlet 0 -- R>=0 G:0.5=zero B>=0 A=1 (all x strength)\nt = nearest(in1, norm);\nJxx = t.x;\nJxy = (t.y - 0.5) * 2.0;\nJyy = t.z;\n//   Gain-free identities (strength is a common factor on R, G-0.5, B):\n//     tan(2*theta) = 2*(t.g-0.5)/(t.r - t.b);   aspect = (trace+root)/(trace-root)\n//   CAVEAT: 0.5*atan2 confines theta to (-pi/2, pi/2]; a near-vertical axis\n//   decodes sign-flipped. Safe ONLY for consumers symmetric to theta+180 deg\n//   (glyphs, blur, hatch, sharpen, coherence). Sign-sensitive consumers must\n//   route through f_tf_axisflow (f_tensor_type.md consumer rule 2).\n\n// --- gap scale in component space (identical algebra, no eigen solve) ---\ntrace = Jxx + Jyy;\niso_part = (1.0 - sharpen) * 0.5 * trace;   // sharpen < 0 never occurs (max below)\ng = max(sharpen, 0.0);                       // relax branch: identity-mix, never a\n                                             // negative gap (spec OQ2; drop this max\n                                             // and gamma < 0 swaps the eigenvalues --\n                                             // caught by mirror T006/T009a)\nox = g * Jxx + iso_part;                     // == trace/2 + g*(Jxx - trace/2)\noy = g * Jxy * 0.5 + 0.5;                    // cross term scales with the gap\noz = g * Jyy + iso_part;                     // == trace/2 + g*(Jyy - trace/2)\n\n// --- floor gate (fixed internal eps, plan ADR-3; NOT a param) ---\neps_trace = 0.000001;\nbelow_floor = 1.0 - step(eps_trace, trace);  // 1 where trace < eps\nox = mix(ox, Jxx, below_floor);              // exact passthrough below the floor\noy = mix(oy, t.y, below_floor);\noz = mix(oz, Jyy, below_floor);\n\n// --- re-encode: outlet-0 contract; ONLY the final stage clamps ---\nout1 = mix(vec(clamp(ox, 0.0, 1.0), clamp(oy, 0.0, 1.0), clamp(oz, 0.0, 1.0), 1.0),\n           in1,                              // bypass: exact passthrough\n           bypass_gate);",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
									"id": "gen-obj-2",
									"maxclass": "codebox",
									"numinlets": 1,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										22.0,
										80.0,
										550.0,
										380.0
									]
								}
							},
							{
								"box": {
									"id": "gen-obj-3",
									"maxclass": "newobj",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										22.0,
										490.0,
										35.0,
										22.0
									],
									"text": "out 1"
								}
							}
						],
						"lines": [
							{
								"patchline": {
									"destination": [
										"gen-obj-2",
										0
									],
									"source": [
										"gen-obj-1",
										0
									]
								}
							},
							{
								"patchline": {
									"destination": [
										"gen-obj-3",
										0
									],
									"source": [
										"gen-obj-2",
										0
									]
								}
							}
						]
					},
					"patching_rect": [
						30.0,
						380.0,
						200.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_sharpen_pix @type float32",
					"varname": "#0_sharpen_pix"
				}
			},
			{
				"box": {
					"id": "obj-6",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 4,
					"outlettype": [
						"",
						"",
						"",
						""
					],
					"patching_rect": [
						980.0,
						100.0,
						56.0,
						22.0
					],
					"text": "autopattr",
					"varname": "sharpen_autopattr"
				}
			},
			{
				"box": {
					"id": "obj-9",
					"maxclass": "panel",
					"angle": 270.0,
					"background": 1,
					"bgcolor": [
						0.0,
						0.0,
						0.0,
						1.0
					],
					"border": 1,
					"bordercolor": [
						0.0,
						0.03529411765,
						0.2274509804,
						1.0
					],
					"mode": 0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						760.0,
						260.0,
						154.0,
						84.0
					],
					"presentation": 1,
					"presentation_rect": [
						0.0,
						0.0,
						154.0,
						84.0
					],
					"proportion": 0.5
				}
			},
			{
				"box": {
					"id": "obj-10",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						980.0,
						200.0,
						80.0,
						21.0
					],
					"presentation": 1,
					"presentation_rect": [
						-1.5,
						0.0,
						80.0,
						21.0
					],
					"text": "Tensor Sharpen"
				}
			},
			{
				"box": {
					"id": "obj-8",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"textcolor": [
						0.85,
						0.55,
						0.2,
						1.0
					],
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						1070.0,
						200.0,
						60.0,
						21.0
					],
					"presentation": 1,
					"presentation_rect": [
						62.0,
						3.0,
						60.0,
						18.0
					],
					"text": "tensor out"
				}
			},
			{
				"box": {
					"id": "obj-11",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						760.0,
						20.0,
						60.0,
						22.0
					],
					"text": "loadbang"
				}
			},
			{
				"box": {
					"id": "obj-12",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						760.0,
						50.0,
						180.0,
						22.0
					],
					"text": "getattr presentation_rect"
				}
			},
			{
				"box": {
					"id": "obj-13",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 4,
					"outlettype": [
						"",
						"",
						"",
						""
					],
					"patching_rect": [
						760.0,
						110.0,
						80.0,
						22.0
					],
					"text": "thispatcher"
				}
			},
			{
				"box": {
					"id": "obj-14",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						760.0,
						140.0,
						60.0,
						22.0
					],
					"text": "zl slice 2"
				}
			},
			{
				"box": {
					"id": "obj-15",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						760.0,
						170.0,
						80.0,
						22.0
					],
					"text": "prepend tam"
				}
			},
			{
				"box": {
					"id": "obj-16",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						760.0,
						200.0,
						100.0,
						22.0
					],
					"saved_object_attributes": {
						"filename": "moduleSize.js",
						"parameter_enable": 0
					},
					"text": "js moduleSize.js"
				}
			},
			{
				"box": {
					"id": "obj-20",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Eigengap multiplier: 1 = neutral, below 1 relaxes the field toward isotropy, above 1 exaggerates anisotropy (commit edges). Linear, one-sided 0-4 (provisional; gate open).",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_sharpen_pix::sharpen",
					"parameter_enable": 1,
					"patching_rect": [
						46.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						4.0,
						38.0,
						27.0,
						43.0
					],
					"saved_attribute_attributes": {
						"activedialcolor": {
							"expression": ""
						},
						"valueof": {
							"parameter_initial": [
								1.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "sharpen",
							"parameter_mmax": 4.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "sharpen",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "sharpen"
				}
			},
			{
				"box": {
					"id": "obj-21",
					"maxclass": "attrui",
					"attr": "sharpen",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						26.0,
						310.0,
						68.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-22",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						35.0,
						180.0,
						50.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						-8.0,
						20.0,
						50.0,
						18.0
					],
					"text": "Sharpen",
					"textjustification": 1,
					"varname": "lbl_sharpen"
				}
			},
			{
				"box": {
					"id": "obj-23",
					"maxclass": "jsui",
					"filename": "bypass_toggle.js",
					"hint": "Bypass",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"presentation": 1,
					"patching_rect": [
						980.0,
						130.0,
						18.0,
						12.0
					],
					"presentation_rect": [
						129.0,
						5.0,
						18.0,
						12.0
					],
					"valuepopuplabel": 1,
					"varname": "bypass"
				}
			},
			{
				"box": {
					"id": "obj-24",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						980.0,
						160.0,
						131.0,
						22.0
					],
					"text": "prepend param bypass_gate"
				}
			}
		],
		"lines": [
			{
				"patchline": {
					"source": [
						"obj-1",
						0
					],
					"destination": [
						"obj-3",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-3",
						0
					],
					"destination": [
						"obj-5",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-3",
						2
					],
					"destination": [
						"obj-4",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-5",
						0
					],
					"destination": [
						"obj-2",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-23",
						0
					],
					"destination": [
						"obj-24",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-24",
						0
					],
					"destination": [
						"obj-5",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-11",
						0
					],
					"destination": [
						"obj-12",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-12",
						0
					],
					"destination": [
						"obj-13",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-13",
						0
					],
					"destination": [
						"obj-14",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-14",
						1
					],
					"destination": [
						"obj-15",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-15",
						0
					],
					"destination": [
						"obj-16",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-4",
						0
					],
					"destination": [
						"obj-20",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-20",
						0
					],
					"destination": [
						"obj-21",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-21",
						0
					],
					"destination": [
						"obj-5",
						0
					]
				}
			}
		],
		"parameters": {
			"obj-20": [
				"sharpen",
				"sharpen",
				0
			],
			"parameterbanks": {
				"0": {
					"index": 0,
					"name": "",
					"parameters": [
						"-",
						"-",
						"-",
						"-",
						"-",
						"-",
						"-",
						"-"
					],
					"buttons": [
						"-",
						"-",
						"-",
						"-",
						"-",
						"-",
						"-",
						"-"
					]
				}
			},
			"inherited_shortname": 1
		},
		"autosave": 0
	}
}