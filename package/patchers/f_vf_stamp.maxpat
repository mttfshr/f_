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
					"comment": "stamp texture / control",
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
					"comment": "ink",
					"index": 0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						30.0,
						452.0,
						30.0,
						30.0
					]
				}
			},
			{
				"box": {
					"id": "obj-201",
					"maxclass": "outlet",
					"comment": "impulse (vecfield)",
					"index": 0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						100.0,
						452.0,
						30.0,
						30.0
					]
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
					"numoutlets": 10,
					"outlettype": [
						"",
						"",
						"",
						"",
						"",
						"",
						"",
						"",
						"",
						""
					],
					"patching_rect": [
						56.5,
						204.0,
						727.0,
						22.0
					],
					"text": "route threshold softness amount force rim attack release invert impulse stamp"
				}
			},
			{
				"box": {
					"id": "obj-5",
					"maxclass": "newobj",
					"numinlets": 3,
					"numoutlets": 3,
					"outlettype": [
						"jit_gl_texture",
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
									"id": "gen-obj-10",
									"maxclass": "newobj",
									"numinlets": 0,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										80.0,
										30.0,
										28.0,
										22.0
									],
									"text": "in 2"
								}
							},
							{
								"box": {
									"id": "gen-obj-11",
									"maxclass": "newobj",
									"numinlets": 0,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										138.0,
										30.0,
										28.0,
										22.0
									],
									"text": "in 3"
								}
							},
							{
								"box": {
									"code": "// codebox_stamp.gen -- f_vf_stamp: the one stage. Coverage from the stamp's luma, the ink, the impulse vecfield.\n// Stateless: a pure function of the two textures, the Params and the render size. Float32, render resolution.\n// Mirror: tests/modules/vf_stamp/vf_stamp_mirror.stamp_stage() (the mirror's two textures are the second and third\n// inputs here).\n//\n// Inputs (plan ADR-9): first = the `r draw` bang (not referenced; it triggers one render per draw, connected or not),\n// second = the stamp texture (cold), third = the vecfield (cold).\n// Outlets: the first is the ink, the second is the impulse vecfield.\n//   - coverage (FR-003): smoothstep of Rec.709 luma from max(threshold - softness / 2, 0) to threshold + softness / 2,\n//     by hand with a width floor (softness 0 must not divide by zero), flipped by `invert`. The clamp means black\n//     never stamps. src_stamp = 0 (nothing on the module's main inlet) forces it to 0: `invert` would otherwise read\n//     an empty inlet as full coverage (FR-001)\n//   - ink (G2): rgb * cov * amount * env, alpha 1\n//   - impulse, vecfield connected (FR-005): (field - 0.5) * 2 * cov * env * force. The flag src_vec decides, never the\n//     value: an unconnected inlet is black, which decodes to a full -1 vector\n//   - impulse, nothing connected (FR-006, plan ADR-4): the plain wide central difference of cov, negated, no divide;\n//     reach = max(1, round(rim * width)) texels on both axes. `impulse` 1 rotates it: (x, y) -> (-y, x)\n//   - encode: v * 0.5 + 0.5 clamped to 0..1, B = 0.5, A = 1 (f_vecfield_type); exact neutral when cov * env = 0\n//   - neighbours (FR-010): integer texel index with wrap(), read at the texel centre, so never an out-of-range sample\n//   - render size: Params width and height from render_dim (`dim` reads 1 live)\n//   - bypass_gate = 1 (G5; never the native @bypass): the first outlet passes the stamp, the second passes the vecfield\n//     when connected, else neutral. The zap below stays active\n//   - non-finite texels (FR-011): zapped on read, stamp to 0 (alpha 1), vecfield to 0.5, by abs(x) < 1e30 with switch():\n//     NaN == NaN is TRUE on this GPU, and mix() would carry a NaN through\n// Functions come before the Params and do not see them, so the Params are arguments.\nzap(xv, alt) {\n    return switch(abs(xv) < 1e30, xv, alt);\n}\n\ncov_at(xi, yi, w, h, low, high, inv, stp) {\n    su = (xi + 0.5) / w;\n    sv = (yi + 0.5) / h;\n    cr = zap(sample(in2, vec(su, sv)).x, 0);\n    cg = zap(sample(in2, vec(su, sv)).y, 0);\n    cb = zap(sample(in2, vec(su, sv)).z, 0);\n    lum = cr * 0.2126 + cg * 0.7152 + cb * 0.0722;\n    tt = clamp((lum - low) / max(high - low, 0.00001), 0, 1);\n    cc = tt * tt * (3 - 2 * tt);\n    return mix(cc, 1 - cc, inv) * stp;\n}\n\nParam threshold(0.05);\nParam softness(0.1);\nParam invert(0);\nParam amount(1);\nParam force(1);\nParam impulse(0);\nParam rim(0.015);\nParam env(0);\nParam src_stamp(0);\nParam src_vec(0);\nParam bypass_gate(0);\nParam width(480);\nParam height(480);\n\nix = floor(norm.x * width);\niy = floor(norm.y * height);\nlo = max(threshold - softness / 2, 0);\nhi = threshold + softness / 2;\nstamped = switch(src_stamp >= 0.5, 1, 0);\nconn = switch(src_vec >= 0.5, 1, 0);\nswirl = switch(impulse >= 0.5, 1, 0);\n\nc0 = cov_at(ix, iy, width, height, lo, hi, invert, stamped);\n\nsr = zap(sample(in2, norm).x, 0);\nsg = zap(sample(in2, norm).y, 0);\nsb = zap(sample(in2, norm).z, 0);\nsa = zap(sample(in2, norm).w, 1);\n\nink = c0 * amount * env;\n\nfr = zap(sample(in3, norm).x, 0.5);\nfg = zap(sample(in3, norm).y, 0.5);\n\ngain_pat = c0 * env * force;\npat_x = (fr - 0.5) * 2 * gain_pat;\npat_y = (fg - 0.5) * 2 * gain_pat;\n\nreach = max(1, floor(rim * width + 0.5));\nxp = cov_at(wrap(ix + reach, 0, width), iy, width, height, lo, hi, invert, stamped);\nxm = cov_at(wrap(ix - reach, 0, width), iy, width, height, lo, hi, invert, stamped);\nyp = cov_at(ix, wrap(iy + reach, 0, height), width, height, lo, hi, invert, stamped);\nym = cov_at(ix, wrap(iy - reach, 0, height), width, height, lo, hi, invert, stamped);\nrad_x = xm - xp;\nrad_y = ym - yp;\nfld_x = mix(rad_x, 0 - rad_y, swirl) * env * force;\nfld_y = mix(rad_y, rad_x, swirl) * env * force;\n\nvx = mix(fld_x, pat_x, conn);\nvy = mix(fld_y, pat_y, conn);\nox = clamp(vx * 0.5 + 0.5, 0, 1);\noy = clamp(vy * 0.5 + 0.5, 0, 1);\n\nout1 = vec(mix(sr * ink, sr, bypass_gate), mix(sg * ink, sg, bypass_gate), mix(sb * ink, sb, bypass_gate), mix(1, sa, bypass_gate));\nout2 = vec(mix(ox, mix(0.5, fr, conn), bypass_gate), mix(oy, mix(0.5, fg, conn), bypass_gate), 0.5, 1);\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
									"id": "gen-obj-2",
									"maxclass": "codebox",
									"numinlets": 3,
									"numoutlets": 2,
									"outlettype": [
										"",
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
							},
							{
								"box": {
									"id": "gen-obj-4",
									"maxclass": "newobj",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										82.0,
										490.0,
										35.0,
										22.0
									],
									"text": "out 2"
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
										"gen-obj-2",
										1
									],
									"source": [
										"gen-obj-10",
										0
									]
								}
							},
							{
								"patchline": {
									"destination": [
										"gen-obj-2",
										2
									],
									"source": [
										"gen-obj-11",
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
							},
							{
								"patchline": {
									"destination": [
										"gen-obj-4",
										0
									],
									"source": [
										"gen-obj-2",
										1
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
					"text": "jit.gl.pix vsynth @name #0_vfstamp_pix @adapt 0 @dim 256 256 @type float32",
					"varname": "#0_vfstamp_pix"
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
						1063.5,
						100.0,
						56.0,
						22.0
					],
					"text": "autopattr",
					"varname": "vfstamp_autopattr"
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
						843.5,
						260.0,
						190.0,
						232.0
					],
					"presentation": 1,
					"presentation_rect": [
						0.0,
						0.0,
						190.0,
						232.0
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
						1063.5,
						200.0,
						80.0,
						21.0
					],
					"presentation": 1,
					"presentation_rect": [
						10.5,
						0.0,
						92.0,
						21.0
					],
					"text": "Stamp"
				}
			},
			{
				"box": {
					"id": "obj-8",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 11.0,
					"textcolor": [
						0.35,
						0.75,
						0.95,
						1.0
					],
					"textjustification": 2,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						1153.5,
						200.0,
						60.0,
						21.0
					],
					"presentation": 1,
					"presentation_rect": [
						94.0,
						0.9,
						70.0,
						21.0
					],
					"text": "\u2207 in/out"
				}
			},
			{
				"box": {
					"id": "obj-19f",
					"maxclass": "panel",
					"background": 0,
					"bgcolor": [
						0.35,
						0.75,
						0.95,
						1.0
					],
					"border": 0,
					"mode": 0,
					"hint": "Takes: vecfield",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						1063.5,
						232.0,
						5.0,
						5.0
					],
					"presentation": 1,
					"presentation_rect": [
						4.0,
						5.0,
						5.0,
						5.0
					],
					"rounded": 6
				}
			},
			{
				"box": {
					"id": "obj-19g",
					"maxclass": "panel",
					"background": 0,
					"bgcolor": [
						0.35,
						0.75,
						0.95,
						1.0
					],
					"border": 0,
					"mode": 0,
					"hint": "Outputs: vecfield",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						1083.5,
						232.0,
						5.0,
						5.0
					],
					"presentation": 1,
					"presentation_rect": [
						4.0,
						12.0,
						5.0,
						5.0
					],
					"rounded": 6
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
						843.5,
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
						843.5,
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
						843.5,
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
						843.5,
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
						843.5,
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
						843.5,
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
					"id": "obj-17",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						30.0,
						120.0,
						80.0,
						22.0
					],
					"text": "vs_inState"
				}
			},
			{
				"box": {
					"id": "obj-18",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						30.0,
						150.0,
						151.79999999999998,
						22.0
					],
					"text": "prepend param src_stamp"
				}
			},
			{
				"box": {
					"id": "obj-20a",
					"maxclass": "newobj",
					"numinlets": 0,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						130.0,
						120.0,
						50.0,
						22.0
					],
					"text": "r draw"
				}
			},
			{
				"box": {
					"id": "obj-100",
					"maxclass": "inlet",
					"comment": "vecfield",
					"index": 0,
					"numinlets": 0,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						260.0,
						20.0,
						30.0,
						30.0
					]
				}
			},
			{
				"box": {
					"id": "obj-101",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						260.0,
						70.0,
						80.0,
						22.0
					],
					"text": "vs_inState"
				}
			},
			{
				"box": {
					"id": "obj-102",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						260.0,
						120.0,
						160.0,
						22.0
					],
					"text": "prepend param src_vec"
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
					"hint": "Luma above which the stamp covers. Low by default so saturated reds and blues stamp too",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_vfstamp_pix::threshold",
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
								0.05
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "threshold",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "threshold",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "threshold"
				}
			},
			{
				"box": {
					"id": "obj-21",
					"maxclass": "attrui",
					"attr": "threshold",
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
						-7.5,
						20.0,
						50.0,
						18.0
					],
					"text": "Thresh",
					"textjustification": 1,
					"varname": "lbl_threshold"
				}
			},
			{
				"box": {
					"id": "obj-23",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Width of the mask's edge, in luma. It softens a soft stamp; a hard-edged stamp stays hard, whatever this says",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_vfstamp_pix::softness",
					"parameter_enable": 1,
					"patching_rect": [
						118.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						41.0,
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
								0.1
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "softness",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "softness",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "softness"
				}
			},
			{
				"box": {
					"id": "obj-24",
					"maxclass": "attrui",
					"attr": "softness",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						98.0,
						310.0,
						68.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-25",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						107.0,
						180.0,
						50.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						29.5,
						20.0,
						50.0,
						18.0
					],
					"text": "Soft",
					"textjustification": 1,
					"varname": "lbl_softness"
				}
			},
			{
				"box": {
					"id": "obj-26",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Ink strength. Above 1 lifts a short tap",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_vfstamp_pix::amount",
					"parameter_enable": 1,
					"patching_rect": [
						190.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						78.0,
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
							"parameter_longname": "amount",
							"parameter_mmax": 4.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "amount",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "amount"
				}
			},
			{
				"box": {
					"id": "obj-27",
					"maxclass": "attrui",
					"attr": "amount",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						170.0,
						310.0,
						68.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-28",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						179.0,
						180.0,
						50.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						66.5,
						20.0,
						50.0,
						18.0
					],
					"text": "Amount",
					"textjustification": 1,
					"varname": "lbl_amount"
				}
			},
			{
				"box": {
					"id": "obj-29",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Impulse strength, for the field on inlet 1 and for the stamp's own push alike",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_vfstamp_pix::force",
					"parameter_enable": 1,
					"patching_rect": [
						262.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						115.0,
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
							"parameter_longname": "force",
							"parameter_mmax": 2.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "force",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "force"
				}
			},
			{
				"box": {
					"id": "obj-30",
					"maxclass": "attrui",
					"attr": "force",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						242.0,
						310.0,
						68.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-31",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						251.0,
						180.0,
						50.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						103.5,
						20.0,
						50.0,
						18.0
					],
					"text": "Force",
					"textjustification": 1,
					"varname": "lbl_force"
				}
			},
			{
				"box": {
					"id": "obj-32",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Width of the push around the stamp's edge, in frame widths. Does nothing with a field on inlet 1",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_vfstamp_pix::rim",
					"parameter_enable": 1,
					"patching_rect": [
						334.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						152.0,
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
								0.015
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "rim",
							"parameter_mmax": 0.05,
							"parameter_mmin": 0.005,
							"parameter_modmode": 3,
							"parameter_shortname": "rim",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "rim"
				}
			},
			{
				"box": {
					"id": "obj-33",
					"maxclass": "attrui",
					"attr": "rim",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						314.0,
						310.0,
						68.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-34",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						323.0,
						180.0,
						50.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						140.5,
						20.0,
						50.0,
						18.0
					],
					"text": "Rim",
					"textjustification": 1,
					"varname": "lbl_rim"
				}
			},
			{
				"box": {
					"id": "obj-35",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "How fast the stamp comes on after a press, in frames. 0 = at once",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_vfstamp_pix::attack",
					"parameter_enable": 1,
					"patching_rect": [
						406.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						4.0,
						100.0,
						27.0,
						43.0
					],
					"saved_attribute_attributes": {
						"activedialcolor": {
							"expression": ""
						},
						"valueof": {
							"parameter_initial": [
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "attack",
							"parameter_mmax": 60.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "attack",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "attack"
				}
			},
			{
				"box": {
					"id": "obj-37",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						395.0,
						180.0,
						50.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						-7.5,
						82.0,
						50.0,
						18.0
					],
					"text": "Attack",
					"textjustification": 1,
					"varname": "lbl_attack"
				}
			},
			{
				"box": {
					"id": "obj-38",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "How fast the stamp fades after a release, in frames. 0 = at once",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_vfstamp_pix::release",
					"parameter_enable": 1,
					"patching_rect": [
						478.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						41.0,
						100.0,
						27.0,
						43.0
					],
					"saved_attribute_attributes": {
						"activedialcolor": {
							"expression": ""
						},
						"valueof": {
							"parameter_initial": [
								8.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "release",
							"parameter_mmax": 120.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "release",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "release"
				}
			},
			{
				"box": {
					"id": "obj-40",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						467.0,
						180.0,
						50.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						29.5,
						82.0,
						50.0,
						18.0
					],
					"text": "Release",
					"textjustification": 1,
					"varname": "lbl_release"
				}
			},
			{
				"box": {
					"id": "obj-41",
					"maxclass": "live.text",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"hint": "Inv stamps where the texture is dark instead of where it is bright",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"param_connect": "#0_vfstamp_pix::invert",
					"parameter_enable": 1,
					"patching_rect": [
						546.5,
						250.0,
						35.0,
						17.0
					],
					"presentation": 1,
					"presentation_rect": [
						74.0,
						114.0,
						35.0,
						17.0
					],
					"text": "Norm",
					"texton": "Inv",
					"saved_attribute_attributes": {
						"activebgcolor": {
							"expression": ""
						},
						"activebgoncolor": {
							"expression": ""
						},
						"activetextcolor": {
							"expression": ""
						},
						"activetextoncolor": {
							"expression": ""
						},
						"bgoncolor": {
							"expression": ""
						},
						"valueof": {
							"parameter_enum": [
								"Norm",
								"Inv"
							],
							"parameter_initial": [
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "invert",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 0,
							"parameter_shortname": "invert",
							"parameter_type": 1,
							"parameter_unitstyle": 0
						}
					},
					"varname": "invert"
				}
			},
			{
				"box": {
					"id": "obj-42",
					"maxclass": "attrui",
					"attr": "invert",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						530.0,
						310.0,
						68.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-44",
					"maxclass": "live.text",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"hint": "The push with nothing on inlet 1. Radial pushes out from the stamp's edge, Swirl turns around it. f_vf_fluid's Project removes Radial and keeps Swirl",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"param_connect": "#0_vfstamp_pix::impulse",
					"parameter_enable": 1,
					"patching_rect": [
						612.5,
						250.0,
						47.0,
						17.0
					],
					"presentation": 1,
					"presentation_rect": [
						111.0,
						114.0,
						47.0,
						17.0
					],
					"text": "Radial",
					"texton": "Swirl",
					"saved_attribute_attributes": {
						"activebgcolor": {
							"expression": ""
						},
						"activebgoncolor": {
							"expression": ""
						},
						"activetextcolor": {
							"expression": ""
						},
						"activetextoncolor": {
							"expression": ""
						},
						"bgoncolor": {
							"expression": ""
						},
						"valueof": {
							"parameter_enum": [
								"Radial",
								"Swirl"
							],
							"parameter_initial": [
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "impulse",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 0,
							"parameter_shortname": "impulse",
							"parameter_type": 1,
							"parameter_unitstyle": 0
						}
					},
					"varname": "impulse"
				}
			},
			{
				"box": {
					"id": "obj-45",
					"maxclass": "attrui",
					"attr": "impulse",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						602.0,
						310.0,
						68.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-47",
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
						1063.5,
						130.0,
						18.0,
						12.0
					],
					"presentation_rect": [
						168.0,
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
					"id": "obj-48",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1063.5,
						160.0,
						131.0,
						22.0
					],
					"text": "prepend param bypass_gate"
				}
			},
			{
				"box": {
					"id": "obj-rd-0",
					"maxclass": "newobj",
					"patching_rect": [
						480.0,
						552.0,
						40.0,
						22.0
					],
					"text": "r dim",
					"numinlets": 0,
					"numoutlets": 1,
					"outlettype": [
						""
					]
				}
			},
			{
				"box": {
					"id": "obj-rd-5",
					"maxclass": "newobj",
					"patching_rect": [
						620.0,
						552.0,
						60.0,
						22.0
					],
					"text": "loadbang",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"bang"
					]
				}
			},
			{
				"box": {
					"id": "obj-rd-6",
					"maxclass": "newobj",
					"patching_rect": [
						620.0,
						582.0,
						70.0,
						22.0
					],
					"text": "s trig_res",
					"numinlets": 1,
					"numoutlets": 0,
					"outlettype": []
				}
			},
			{
				"box": {
					"id": "obj-rd-1",
					"maxclass": "newobj",
					"patching_rect": [
						530.0,
						552.0,
						60.0,
						22.0
					],
					"text": "route dim",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					]
				}
			},
			{
				"box": {
					"id": "obj-rd-2",
					"maxclass": "newobj",
					"patching_rect": [
						530.0,
						582.0,
						60.0,
						22.0
					],
					"text": "unpack i i",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"int",
						"int"
					]
				}
			},
			{
				"box": {
					"id": "obj-rd-3",
					"maxclass": "newobj",
					"patching_rect": [
						480.0,
						612.0,
						120.0,
						22.0
					],
					"text": "prepend param width",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					]
				}
			},
			{
				"box": {
					"id": "obj-rd-4",
					"maxclass": "newobj",
					"patching_rect": [
						610.0,
						612.0,
						120.0,
						22.0
					],
					"text": "prepend param height",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					]
				}
			},
			{
				"box": {
					"id": "obj-gate-stamp-face",
					"maxclass": "panel",
					"patching_rect": [
						30.0,
						552.0,
						24.0,
						24.0
					],
					"numinlets": 1,
					"numoutlets": 0,
					"background": 1,
					"ignoreclick": 1,
					"border": 2,
					"bordercolor": [
						0.55,
						0.55,
						0.55,
						1.0
					],
					"bgcolor": [
						0.2,
						0.2,
						0.2,
						1.0
					],
					"rounded": 14,
					"presentation": 1,
					"presentation_rect": [
						78.0,
						186.0,
						28.0,
						28.0
					],
					"varname": "stamp_face"
				}
			},
			{
				"box": {
					"id": "obj-gate-stamp-button",
					"maxclass": "ubutton",
					"patching_rect": [
						30.0,
						552.0,
						24.0,
						24.0
					],
					"numinlets": 1,
					"numoutlets": 4,
					"outlettype": [
						"bang",
						"bang",
						"",
						"int"
					],
					"hltcolor": [
						1.0,
						1.0,
						1.0,
						0.45
					],
					"presentation": 1,
					"presentation_rect": [
						78.0,
						186.0,
						28.0,
						28.0
					],
					"varname": "stamp_button",
					"hint": "Hold to stamp: the ink and the impulse flow while held. A tap is a kick, a hold is a pour"
				}
			},
			{
				"box": {
					"id": "obj-gate-stamp-label",
					"maxclass": "comment",
					"patching_rect": [
						30.0,
						578.0,
						50.0,
						18.0
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"presentation": 1,
					"presentation_rect": [
						67.0,
						164.0,
						50.0,
						18.0
					],
					"text": "Stamp",
					"textjustification": 1,
					"varname": "lbl_stamp"
				}
			},
			{
				"box": {
					"id": "obj-gate-stamp-sel",
					"maxclass": "newobj",
					"patching_rect": [
						30.0,
						782.0,
						90.0,
						22.0
					],
					"text": "sel bang 1 0",
					"numinlets": 1,
					"numoutlets": 4,
					"outlettype": [
						"bang",
						"bang",
						"bang",
						""
					]
				}
			},
			{
				"box": {
					"id": "obj-gate-stamp-tap",
					"maxclass": "newobj",
					"patching_rect": [
						30.0,
						817.0,
						40.0,
						22.0
					],
					"text": "t b b",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"bang",
						"bang"
					]
				}
			},
			{
				"box": {
					"id": "obj-gate-stamp-press",
					"maxclass": "newobj",
					"patching_rect": [
						90.0,
						852.0,
						40.0,
						22.0
					],
					"text": "t b b",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"bang",
						"bang"
					]
				}
			},
			{
				"box": {
					"id": "obj-gate-stamp-release",
					"maxclass": "message",
					"patching_rect": [
						30.0,
						887.0,
						30.0,
						22.0
					],
					"text": "0",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					]
				}
			},
			{
				"box": {
					"id": "obj-gate-stamp-on",
					"maxclass": "message",
					"patching_rect": [
						90.0,
						887.0,
						120.0,
						22.0
					],
					"text": "param stamp_gate 1",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					]
				}
			},
			{
				"box": {
					"id": "obj-gate-stamp-arm",
					"maxclass": "message",
					"patching_rect": [
						230.0,
						887.0,
						36.0,
						22.0
					],
					"text": "100",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					]
				}
			},
			{
				"box": {
					"id": "obj-gate-stamp-count",
					"maxclass": "newobj",
					"patching_rect": [
						300.0,
						782.0,
						30.0,
						22.0
					],
					"text": "i",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"int"
					]
				}
			},
			{
				"box": {
					"id": "obj-gate-stamp-add",
					"maxclass": "newobj",
					"patching_rect": [
						340.0,
						812.0,
						30.0,
						22.0
					],
					"text": "+ 1",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"int"
					]
				}
			},
			{
				"box": {
					"id": "obj-gate-stamp-match",
					"maxclass": "newobj",
					"patching_rect": [
						300.0,
						842.0,
						40.0,
						22.0
					],
					"text": "sel 2",
					"numinlets": 2,
					"numoutlets": 2,
					"outlettype": [
						"bang",
						""
					]
				}
			},
			{
				"box": {
					"id": "obj-gate-stamp-off",
					"maxclass": "message",
					"patching_rect": [
						300.0,
						872.0,
						120.0,
						22.0
					],
					"text": "param stamp_gate 0",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					]
				}
			},
			{
				"box": {
					"id": "obj-gate-stamp-draw",
					"maxclass": "newobj",
					"patching_rect": [
						300.0,
						752.0,
						50.0,
						22.0
					],
					"text": "r draw",
					"numinlets": 0,
					"numoutlets": 1,
					"outlettype": [
						""
					]
				}
			},
			{
				"box": {
					"id": "obj-gate-stamp-load",
					"maxclass": "newobj",
					"patching_rect": [
						230.0,
						857.0,
						60.0,
						22.0
					],
					"text": "loadbang",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"bang"
					]
				}
			},
			{
				"box": {
					"id": "obj-raw-1",
					"maxclass": "newobj",
					"patching_rect": [
						460.0,
						552.0,
						70.0,
						22.0
					],
					"text": "route param",
					"numinlets": 2,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					]
				}
			},
			{
				"box": {
					"id": "obj-raw-2",
					"maxclass": "newobj",
					"patching_rect": [
						460.0,
						582.0,
						100.0,
						22.0
					],
					"text": "route stamp_gate",
					"numinlets": 2,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					]
				}
			},
			{
				"box": {
					"id": "obj-raw-3",
					"maxclass": "newobj",
					"patching_rect": [
						580.0,
						552.0,
						280.0,
						22.0
					],
					"text": "expr ($f1 <= 0.) + ($f1 > 0.) * (1. - exp(-1. / max($f1\\, 0.001)))",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					]
				}
			},
			{
				"box": {
					"id": "obj-raw-4",
					"maxclass": "newobj",
					"patching_rect": [
						580.0,
						582.0,
						280.0,
						22.0
					],
					"text": "expr ($f1 <= 0.) + ($f1 > 0.) * (1. - exp(-1. / max($f1\\, 0.001)))",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					]
				}
			},
			{
				"box": {
					"id": "obj-raw-5",
					"maxclass": "newobj",
					"patching_rect": [
						460.0,
						632.0,
						30.0,
						22.0
					],
					"text": "f",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"float"
					]
				}
			},
			{
				"box": {
					"id": "obj-raw-6",
					"maxclass": "newobj",
					"patching_rect": [
						460.0,
						662.0,
						360.0,
						22.0
					],
					"text": "expr $f1 + ($f2 - $f1) * (($f2 > $f1) * $f3 + ($f2 <= $f1) * $f4)",
					"numinlets": 4,
					"numoutlets": 1,
					"outlettype": [
						""
					]
				}
			},
			{
				"box": {
					"id": "obj-raw-7",
					"maxclass": "newobj",
					"patching_rect": [
						460.0,
						692.0,
						150.0,
						22.0
					],
					"text": "expr ($f1 >= 0.001) * $f1",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					]
				}
			},
			{
				"box": {
					"id": "obj-raw-8",
					"maxclass": "newobj",
					"patching_rect": [
						460.0,
						722.0,
						110.0,
						22.0
					],
					"text": "prepend param env",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					]
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
						"obj-17",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-17",
						0
					],
					"destination": [
						"obj-5",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-17",
						1
					],
					"destination": [
						"obj-18",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-18",
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
						"obj-20a",
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
						"obj-5",
						1
					],
					"destination": [
						"obj-201",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-100",
						0
					],
					"destination": [
						"obj-101",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-101",
						0
					],
					"destination": [
						"obj-5",
						2
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-101",
						1
					],
					"destination": [
						"obj-102",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-102",
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
						"obj-47",
						0
					],
					"destination": [
						"obj-48",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-48",
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
			},
			{
				"patchline": {
					"source": [
						"obj-4",
						1
					],
					"destination": [
						"obj-23",
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
						"obj-4",
						2
					],
					"destination": [
						"obj-26",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-26",
						0
					],
					"destination": [
						"obj-27",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-27",
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
						"obj-4",
						3
					],
					"destination": [
						"obj-29",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-29",
						0
					],
					"destination": [
						"obj-30",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-30",
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
						"obj-4",
						4
					],
					"destination": [
						"obj-32",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-32",
						0
					],
					"destination": [
						"obj-33",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-33",
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
						"obj-4",
						5
					],
					"destination": [
						"obj-35",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-4",
						6
					],
					"destination": [
						"obj-38",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-4",
						7
					],
					"destination": [
						"obj-41",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-41",
						0
					],
					"destination": [
						"obj-42",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-42",
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
						"obj-4",
						8
					],
					"destination": [
						"obj-44",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-44",
						0
					],
					"destination": [
						"obj-45",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-45",
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
						"obj-rd-5",
						0
					],
					"destination": [
						"obj-rd-6",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-rd-0",
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
						"obj-rd-0",
						0
					],
					"destination": [
						"obj-rd-1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-rd-1",
						0
					],
					"destination": [
						"obj-rd-2",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-rd-2",
						0
					],
					"destination": [
						"obj-rd-3",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-rd-2",
						1
					],
					"destination": [
						"obj-rd-4",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-rd-3",
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
						"obj-rd-4",
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
						"obj-4",
						9
					],
					"destination": [
						"obj-gate-stamp-sel",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-gate-stamp-button",
						1
					],
					"destination": [
						"obj-gate-stamp-press",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-gate-stamp-button",
						0
					],
					"destination": [
						"obj-gate-stamp-release",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-gate-stamp-sel",
						0
					],
					"destination": [
						"obj-gate-stamp-tap",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-gate-stamp-sel",
						1
					],
					"destination": [
						"obj-gate-stamp-press",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-gate-stamp-sel",
						2
					],
					"destination": [
						"obj-gate-stamp-release",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-gate-stamp-tap",
						1
					],
					"destination": [
						"obj-gate-stamp-press",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-gate-stamp-tap",
						0
					],
					"destination": [
						"obj-gate-stamp-release",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-gate-stamp-press",
						1
					],
					"destination": [
						"obj-gate-stamp-arm",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-gate-stamp-arm",
						0
					],
					"destination": [
						"obj-gate-stamp-count",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-gate-stamp-press",
						0
					],
					"destination": [
						"obj-gate-stamp-on",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-gate-stamp-release",
						0
					],
					"destination": [
						"obj-gate-stamp-count",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-gate-stamp-draw",
						0
					],
					"destination": [
						"obj-gate-stamp-count",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-gate-stamp-count",
						0
					],
					"destination": [
						"obj-gate-stamp-add",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-gate-stamp-add",
						0
					],
					"destination": [
						"obj-gate-stamp-count",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-gate-stamp-count",
						0
					],
					"destination": [
						"obj-gate-stamp-match",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-gate-stamp-match",
						0
					],
					"destination": [
						"obj-gate-stamp-off",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-gate-stamp-load",
						0
					],
					"destination": [
						"obj-gate-stamp-arm",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-gate-stamp-on",
						0
					],
					"destination": [
						"obj-raw-1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-gate-stamp-off",
						0
					],
					"destination": [
						"obj-raw-1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-1",
						0
					],
					"destination": [
						"obj-raw-2",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-2",
						0
					],
					"destination": [
						"obj-raw-6",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-35",
						0
					],
					"destination": [
						"obj-raw-3",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-3",
						0
					],
					"destination": [
						"obj-raw-6",
						2
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-38",
						0
					],
					"destination": [
						"obj-raw-4",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-4",
						0
					],
					"destination": [
						"obj-raw-6",
						3
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-gate-stamp-load",
						0
					],
					"destination": [
						"obj-35",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-gate-stamp-load",
						0
					],
					"destination": [
						"obj-38",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-gate-stamp-draw",
						0
					],
					"destination": [
						"obj-raw-5",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-5",
						0
					],
					"destination": [
						"obj-raw-6",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-6",
						0
					],
					"destination": [
						"obj-raw-7",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-7",
						0
					],
					"destination": [
						"obj-raw-5",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-7",
						0
					],
					"destination": [
						"obj-raw-8",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-8",
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
				"threshold",
				"threshold",
				0
			],
			"obj-23": [
				"softness",
				"softness",
				0
			],
			"obj-26": [
				"amount",
				"amount",
				0
			],
			"obj-29": [
				"force",
				"force",
				0
			],
			"obj-32": [
				"rim",
				"rim",
				0
			],
			"obj-35": [
				"attack",
				"attack",
				0
			],
			"obj-38": [
				"release",
				"release",
				0
			],
			"obj-41": [
				"invert",
				"invert",
				0
			],
			"obj-44": [
				"impulse",
				"impulse",
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