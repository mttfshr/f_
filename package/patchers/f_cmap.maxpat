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
					"comment": "image",
					"index": 0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						30.0,
						502.0,
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
					"numoutlets": 11,
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
						"",
						""
					],
					"patching_rect": [
						56.5,
						204.0,
						799.0,
						22.0
					],
					"text": "route decay inject radius sweep rate angle lscale pwr edge freeze_on reset"
				}
			},
			{
				"box": {
					"id": "obj-50",
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
									"code": "// codebox_cmap_pass.gen -- f_cmap feedback stage: the previous frame, NaN/Inf-guarded (NF-003).\n// in1 = the primary's out1 (one frame old by the time the primary reads it). Texel-centre read, so same-size\n// textures copy exactly. A zapped channel reads 0 (the f_wc pass guard: abs(x) < 1e30 is false for NaN and Inf;\n// selection by switch(), not mix(), which would keep a NaN).\nfbx = nearest(in1, norm).x;\nfbx = switch(abs(fbx) < 1e30, fbx, 0.0);\nfby = nearest(in1, norm).y;\nfby = switch(abs(fby) < 1e30, fby, 0.0);\nfbz = nearest(in1, norm).z;\nfbz = switch(abs(fbz) < 1e30, fbz, 0.0);\nfbw = nearest(in1, norm).w;\nfbw = switch(abs(fbw) < 1e30, fbw, 0.0);\nout1 = vec(fbx, fby, fbz, fbw);\n",
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
					"text": "jit.gl.pix vsynth @name #0_cmap_pass @type float32 @adapt 1",
					"varname": "#0_cmap_pass"
				}
			},
			{
				"box": {
					"id": "obj-5",
					"maxclass": "newobj",
					"numinlets": 2,
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
									"code": "// codebox_cmap.gen -- f_cmap primary stage: the iterated complex-map pull (spec FR-001..FR-011).\n// Mirror: tests/modules/cmap/cmap_mirror.py (frame(), pull_point(), offset()).\n// Inputs: in1 = the live source, in2 = the previous frame (the pass stage's guarded copy of out1).\n//\n// Per pixel (isometric, centred, frame-height units):\n//   q  = ((x - 0.5) * aspect, y - 0.5)          z = 2 L q          L = lscale (default 1.75)\n//   z' = z^pwr + w                              by repeated complex multiplication, pwr = 2..4\n//   p' = (z'.x / (2 L) / aspect + 0.5, z'.y / (2 L) + 0.5)\n//   hist = prev(p') when p' lies in the closed frame, else (edge) Source: the source here / Wrap: prev(fract(p'))\n//   out  = hist * decay * (1 - inject) + src * inject          alpha 1\n// w = radius + sweep cos(2 pi phase_clk), turned by 2 pi (angle + theta_clk): the two clocks are patcher\n// accumulators in turns (theta_clk at `rate`, phase_clk at sqrt(2) `rate`), so rate 0 freezes w exactly.\n//\n// FR-011: the history is read from hand-built nearest() taps at texel-centre coordinates (4-tap bilinear, gate G4):\n// a bare sample() is exactly nearest wherever the pull minifies (T006). The tap INDEX is clamped (Source) or wrapped\n// (Wrap) before the coordinate is formed, so no tap sits on a wrap seam. `dim` is the first inlet's size, so the\n// source must be render-sized (the bench gives it that size too).\n//\n// freeze_on holds the previous frame EXACTLY (it reads texel centres, never resamples); reseed >= 0.5 replaces the\n// history with the source (reset); bypass_gate = 1 passes the source (and the loop carries it).\n// The source is NaN/Inf-guarded here and the history in the pass stage, so everything out1 holds is finite (NF-003).\nParam decay(0.97);\nParam inject(0.05);\nParam radius(0.15);\nParam sweep(0.0);\nParam angle(0.0);\nParam pwr(2);\nParam edge(0);\nParam lscale(1.75);\nParam freeze_on(0);\nParam reseed(0);\nParam bypass_gate(0);\nParam theta_clk(0.0);\nParam phase_clk(0.0);\n\n// the source, finite, alpha 1\nsx = sample(in1, norm).x;\nsx = switch(abs(sx) < 1e30, sx, 0.0);\nsy = sample(in1, norm).y;\nsy = switch(abs(sy) < 1e30, sy, 0.0);\nsz = sample(in1, norm).z;\nsz = switch(abs(sz) < 1e30, sz, 0.0);\nsv = vec(sx, sy, sz, 1.0);\n\n// the offset w\nth = twopi * (angle + theta_clk);\nmag = radius + sweep * cos(twopi * phase_clk);\nwx = mag * cos(th);\nwy = mag * sin(th);\n\n// the pull\naspect = dim.x / dim.y;\ntwo_l = 2.0 * lscale;\nzx = (norm.x - 0.5) * aspect * two_l;\nzy = (norm.y - 0.5) * two_l;\nr2x = zx * zx - zy * zy;\nr2y = zx * zy + zy * zx;\nr3x = r2x * zx - r2y * zy;\nr3y = r2x * zy + r2y * zx;\nr4x = r3x * zx - r3y * zy;\nr4y = r3x * zy + r3y * zx;\nm3 = step(2.5, pwr);\nm4 = step(3.5, pwr);\nrx = mix(mix(r2x, r3x, m3), r4x, m4);\nry = mix(mix(r2y, r3y, m3), r4y, m4);\nppx = (rx + wx) / two_l / aspect + 0.5;\nppy = (ry + wy) / two_l + 0.5;\nins = step(0.0, ppx) * step(ppx, 1.0) * step(0.0, ppy) * step(ppy, 1.0);\nins = max(ins, edge);\n\n// the 4-tap bilinear read of the previous frame\nux = mix(clamp(ppx, 0.0, 1.0), fract(ppx), edge);\nuy = mix(clamp(ppy, 0.0, 1.0), fract(ppy), edge);\ntx = ux * dim.x - 0.5;\nty = uy * dim.y - 0.5;\nix = floor(tx);\niy = floor(ty);\nax = tx - ix;\nay = ty - iy;\njx0 = ix;\njx1 = ix + 1.0;\njy0 = iy;\njy1 = iy + 1.0;\nkx0 = mix(clamp(jx0, 0.0, dim.x - 1.0), jx0 - floor(jx0 / dim.x) * dim.x, edge);\nkx1 = mix(clamp(jx1, 0.0, dim.x - 1.0), jx1 - floor(jx1 / dim.x) * dim.x, edge);\nky0 = mix(clamp(jy0, 0.0, dim.y - 1.0), jy0 - floor(jy0 / dim.y) * dim.y, edge);\nky1 = mix(clamp(jy1, 0.0, dim.y - 1.0), jy1 - floor(jy1 / dim.y) * dim.y, edge);\ncx0 = (kx0 + 0.5) / dim.x;\ncx1 = (kx1 + 0.5) / dim.x;\ncy0 = (ky0 + 0.5) / dim.y;\ncy1 = (ky1 + 0.5) / dim.y;\nhv = (nearest(in2, vec(cx0, cy0)) * (1.0 - ax) + nearest(in2, vec(cx1, cy0)) * ax) * (1.0 - ay) + (nearest(in2, vec(cx0, cy1)) * (1.0 - ax) + nearest(in2, vec(cx1, cy1)) * ax) * ay;\n\n// the step: outside the frame the bounds rule supplies the history\nk1 = decay * (1.0 - inject);\nres = mix(sv, hv, ins) * k1 + sv * inject;\nres = res * vec(1.0, 1.0, 1.0, 0.0) + vec(0.0, 0.0, 0.0, 1.0);\n\n// freeze holds the previous frame exactly; reset / bypass take the source\nheld = mix(res, nearest(in2, norm), step(0.5, freeze_on));\nout1 = mix(held, sv, max(step(0.5, reseed), step(0.5, bypass_gate)));\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
									"id": "gen-obj-2",
									"maxclass": "codebox",
									"numinlets": 2,
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
						430.0,
						200.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_cmap_pix @type float32 @adapt 1",
					"varname": "#0_cmap_pix"
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
						1135.5,
						100.0,
						56.0,
						22.0
					],
					"text": "autopattr",
					"varname": "cmap_autopattr"
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
						915.5,
						260.0,
						190.0,
						195.0
					],
					"presentation": 1,
					"presentation_rect": [
						0.0,
						0.0,
						190.0,
						195.0
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
						1135.5,
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
					"text": "CMAP"
				}
			},
			{
				"box": {
					"id": "obj-8",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 11.0,
					"textcolor": [
						0.6,
						0.6,
						0.6,
						1.0
					],
					"textjustification": 2,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						1225.5,
						200.0,
						60.0,
						21.0
					],
					"presentation": 1,
					"presentation_rect": [
						23.0,
						0.9,
						70.0,
						21.0
					],
					"text": "in/out"
				}
			},
			{
				"box": {
					"id": "obj-19f",
					"maxclass": "panel",
					"background": 0,
					"bgcolor": [
						0.28,
						0.28,
						0.28,
						1.0
					],
					"border": 0,
					"mode": 0,
					"hint": "Takes: no vecfield or tensor",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						1135.5,
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
						0.28,
						0.28,
						0.28,
						1.0
					],
					"border": 0,
					"mode": 0,
					"hint": "Outputs: no vecfield or tensor",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						1155.5,
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
						915.5,
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
						915.5,
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
						915.5,
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
						915.5,
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
						915.5,
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
						915.5,
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
					"hint": "History gain per frame; 1 = no fade",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_cmap_pix::decay",
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
								0.97
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "decay",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.5,
							"parameter_modmode": 3,
							"parameter_shortname": "decay",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "decay"
				}
			},
			{
				"box": {
					"id": "obj-21",
					"maxclass": "attrui",
					"attr": "decay",
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
					"text": "Decay",
					"textjustification": 1,
					"varname": "lbl_decay"
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
					"hint": "Source weight per frame: 0 = the pure map evolution, 1 = the source; about 0.3 winds the live image through the basin",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_cmap_pix::inject",
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
								0.05
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "inject",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "inject",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "inject"
				}
			},
			{
				"box": {
					"id": "obj-24",
					"maxclass": "attrui",
					"attr": "inject",
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
					"text": "Inject",
					"textjustification": 1,
					"varname": "lbl_inject"
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
					"hint": "Size of the offset w (the Julia parameter)",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_cmap_pix::radius",
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
								0.15
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "radius",
							"parameter_mmax": 1.75,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "radius",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "radius"
				}
			},
			{
				"box": {
					"id": "obj-27",
					"maxclass": "attrui",
					"attr": "radius",
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
					"text": "Radius",
					"textjustification": 1,
					"varname": "lbl_radius"
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
					"hint": "How far the offset breathes in and out around Radius",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_cmap_pix::sweep",
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
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "sweep",
							"parameter_mmax": 1.75,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "sweep",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "sweep"
				}
			},
			{
				"box": {
					"id": "obj-30",
					"maxclass": "attrui",
					"attr": "sweep",
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
					"text": "Sweep",
					"textjustification": 1,
					"varname": "lbl_sweep"
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
					"hint": "Clock: turns per frame of the offset, either direction. 0 freezes the offset exactly",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_cmap_pix::rate",
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
								0.0016
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "rate",
							"parameter_mmax": 0.01,
							"parameter_mmin": -0.01,
							"parameter_modmode": 3,
							"parameter_shortname": "rate",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "rate"
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
					"text": "Rate",
					"textjustification": 1,
					"varname": "lbl_rate"
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
					"hint": "Direction of the offset, cyclic; the clock adds to this",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_cmap_pix::angle",
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
							"parameter_longname": "angle",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "angle",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "angle"
				}
			},
			{
				"box": {
					"id": "obj-36",
					"maxclass": "attrui",
					"attr": "angle",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						386.0,
						310.0,
						68.0,
						22.0
					],
					"style": ""
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
					"text": "Angle",
					"textjustification": 1,
					"varname": "lbl_angle"
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
					"hint": "How much of the complex plane the frame spans: larger = more of the map's folds",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_cmap_pix::lscale",
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
								1.75
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "lscale",
							"parameter_mmax": 3.0,
							"parameter_mmin": 0.5,
							"parameter_modmode": 3,
							"parameter_shortname": "lscale",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "lscale"
				}
			},
			{
				"box": {
					"id": "obj-39",
					"maxclass": "attrui",
					"attr": "lscale",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						458.0,
						310.0,
						68.0,
						22.0
					],
					"style": ""
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
					"text": "Scale",
					"textjustification": 1,
					"varname": "lbl_lscale"
				}
			},
			{
				"box": {
					"id": "obj-41",
					"maxclass": "live.numbox",
					"fontname": "Ableton Sans Light",
					"hint": "Exponent of the map (z squared, cubed or fourth)",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_cmap_pix::pwr",
					"parameter_enable": 1,
					"patching_rect": [
						542.0,
						250.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						78.0,
						100.0,
						34.0,
						15.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								2.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "pwr",
							"parameter_mmax": 4.0,
							"parameter_mmin": 2.0,
							"parameter_modmode": 3,
							"parameter_shortname": "pwr",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"varname": "pwr"
				}
			},
			{
				"box": {
					"id": "obj-42",
					"maxclass": "attrui",
					"attr": "pwr",
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
					"id": "obj-43",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						539.0,
						180.0,
						50.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						66.5,
						82.0,
						50.0,
						18.0
					],
					"text": "Power",
					"textjustification": 1,
					"varname": "lbl_pwr"
				}
			},
			{
				"box": {
					"id": "obj-44",
					"maxclass": "live.menu",
					"fontname": "Ableton Sans Light",
					"hint": "Where the pull leaves the frame: Source = the live image comes in; Wrap = the previous frame wraps",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"",
						"",
						"float"
					],
					"param_connect": "#0_cmap_pix::edge",
					"parameter_enable": 1,
					"patching_rect": [
						606.0,
						250.0,
						60.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						111.0,
						114.0,
						45.0,
						15.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_enum": [
								"Source",
								"Wrap"
							],
							"parameter_initial": [
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "edge",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 0,
							"parameter_shortname": "edge",
							"parameter_type": 2,
							"parameter_unitstyle": 0
						}
					},
					"varname": "edge"
				}
			},
			{
				"box": {
					"id": "obj-45",
					"maxclass": "attrui",
					"attr": "edge",
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
					"id": "obj-46",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						611.0,
						180.0,
						50.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						103.5,
						82.0,
						50.0,
						18.0
					],
					"text": "Bounds",
					"textjustification": 1,
					"varname": "lbl_edge"
				}
			},
			{
				"box": {
					"id": "obj-19a",
					"maxclass": "live.toggle",
					"fontname": "Ableton Sans Light",
					"hint": "Hold the picture exactly where it is; off resumes from it",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"param_connect": "#0_cmap_pix::freeze_on",
					"parameter_enable": 1,
					"patching_rect": [
						698.0,
						250.0,
						20.0,
						20.0
					],
					"presentation": 1,
					"presentation_rect": [
						140.0,
						1.0,
						20.0,
						20.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "freeze_on",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 0,
							"parameter_shortname": "freeze_on",
							"parameter_type": 1,
							"parameter_unitstyle": 0
						}
					},
					"varname": "freeze_on"
				}
			},
			{
				"box": {
					"id": "obj-19b",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						686.5,
						180.0,
						43.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						97.0,
						3.0,
						43.0,
						18.0
					],
					"text": "Freeze",
					"textjustification": 2
				}
			},
			{
				"box": {
					"id": "obj-19c",
					"maxclass": "attrui",
					"attr": "freeze_on",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						674.0,
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
						1135.5,
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
						1135.5,
						160.0,
						131.0,
						22.0
					],
					"text": "prepend param bypass_gate"
				}
			},
			{
				"box": {
					"id": "obj-raw-1",
					"maxclass": "newobj",
					"patching_rect": [
						440.0,
						592.0,
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
					"id": "obj-raw-2",
					"maxclass": "newobj",
					"patching_rect": [
						440.0,
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
					"id": "obj-raw-3",
					"maxclass": "newobj",
					"patching_rect": [
						440.0,
						672.0,
						40.0,
						22.0
					],
					"text": "+ 0.",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"float"
					]
				}
			},
			{
				"box": {
					"id": "obj-raw-4",
					"maxclass": "newobj",
					"patching_rect": [
						440.0,
						712.0,
						120.0,
						22.0
					],
					"text": "expr $f1 - floor($f1)",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"float"
					]
				}
			},
			{
				"box": {
					"id": "obj-raw-5",
					"maxclass": "newobj",
					"patching_rect": [
						440.0,
						752.0,
						130.0,
						22.0
					],
					"text": "prepend param theta_clk",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					]
				}
			},
			{
				"box": {
					"id": "obj-raw-6",
					"maxclass": "newobj",
					"patching_rect": [
						600.0,
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
					"id": "obj-raw-7",
					"maxclass": "newobj",
					"patching_rect": [
						600.0,
						672.0,
						40.0,
						22.0
					],
					"text": "+ 0.",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"float"
					]
				}
			},
			{
				"box": {
					"id": "obj-raw-8",
					"maxclass": "newobj",
					"patching_rect": [
						600.0,
						712.0,
						120.0,
						22.0
					],
					"text": "expr $f1 - floor($f1)",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"float"
					]
				}
			},
			{
				"box": {
					"id": "obj-raw-9",
					"maxclass": "newobj",
					"patching_rect": [
						600.0,
						752.0,
						130.0,
						22.0
					],
					"text": "prepend param phase_clk",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					]
				}
			},
			{
				"box": {
					"id": "obj-raw-10",
					"maxclass": "newobj",
					"patching_rect": [
						680.0,
						652.0,
						80.0,
						22.0
					],
					"text": "* 1.41421356",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"float"
					]
				}
			},
			{
				"box": {
					"id": "obj-raw-11",
					"maxclass": "button",
					"patching_rect": [
						30.0,
						592.0,
						24.0,
						24.0
					],
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"bang"
					],
					"presentation": 1,
					"presentation_rect": [
						8.0,
						160.0,
						28.0,
						28.0
					],
					"varname": "reset_button",
					"hint": "Re-seed the picture from the live image"
				}
			},
			{
				"box": {
					"id": "obj-raw-12",
					"maxclass": "comment",
					"patching_rect": [
						30.0,
						618.0,
						50.0,
						18.0
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"presentation": 1,
					"presentation_rect": [
						42.0,
						165.0,
						44.0,
						18.0
					],
					"text": "Reset",
					"textjustification": 0,
					"varname": "lbl_reset"
				}
			},
			{
				"box": {
					"id": "obj-raw-13",
					"maxclass": "newobj",
					"patching_rect": [
						140.0,
						602.0,
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
					"id": "obj-raw-14",
					"maxclass": "newobj",
					"patching_rect": [
						140.0,
						627.0,
						60.0,
						22.0
					],
					"text": "delay 200",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"bang"
					]
				}
			},
			{
				"box": {
					"id": "obj-raw-15",
					"maxclass": "newobj",
					"patching_rect": [
						30.0,
						652.0,
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
					"id": "obj-raw-16",
					"maxclass": "message",
					"patching_rect": [
						30.0,
						692.0,
						85.0,
						22.0
					],
					"text": "param reseed 1",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					]
				}
			},
			{
				"box": {
					"id": "obj-raw-17",
					"maxclass": "message",
					"patching_rect": [
						140.0,
						722.0,
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
					"id": "obj-raw-18",
					"maxclass": "newobj",
					"patching_rect": [
						200.0,
						722.0,
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
					"id": "obj-raw-19",
					"maxclass": "newobj",
					"patching_rect": [
						240.0,
						722.0,
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
					"id": "obj-raw-20",
					"maxclass": "newobj",
					"patching_rect": [
						280.0,
						722.0,
						60.0,
						22.0
					],
					"text": "% 1000000",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"int"
					]
				}
			},
			{
				"box": {
					"id": "obj-raw-21",
					"maxclass": "newobj",
					"patching_rect": [
						200.0,
						752.0,
						40.0,
						22.0
					],
					"text": "sel 3",
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
					"id": "obj-raw-22",
					"maxclass": "message",
					"patching_rect": [
						200.0,
						782.0,
						85.0,
						22.0
					],
					"text": "param reseed 0",
					"numinlets": 2,
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
						"obj-5",
						0
					],
					"destination": [
						"obj-50",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-50",
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
						"obj-35",
						0
					],
					"destination": [
						"obj-36",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-36",
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
						"obj-38",
						0
					],
					"destination": [
						"obj-39",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-39",
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
						"obj-4",
						9
					],
					"destination": [
						"obj-19a",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-19a",
						0
					],
					"destination": [
						"obj-19c",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-19c",
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
						"obj-raw-2",
						1
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
						"obj-5",
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
						"obj-raw-6",
						1
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
						"obj-raw-9",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-9",
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
						"obj-32",
						0
					],
					"destination": [
						"obj-raw-3",
						1
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
						"obj-raw-10",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-10",
						0
					],
					"destination": [
						"obj-raw-7",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-4",
						10
					],
					"destination": [
						"obj-raw-15",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-11",
						0
					],
					"destination": [
						"obj-raw-15",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-13",
						0
					],
					"destination": [
						"obj-raw-14",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-14",
						0
					],
					"destination": [
						"obj-raw-15",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-15",
						1
					],
					"destination": [
						"obj-raw-16",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-16",
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
						"obj-raw-15",
						0
					],
					"destination": [
						"obj-raw-17",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-17",
						0
					],
					"destination": [
						"obj-raw-18",
						1
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
						"obj-raw-18",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-18",
						0
					],
					"destination": [
						"obj-raw-19",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-19",
						0
					],
					"destination": [
						"obj-raw-20",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-20",
						0
					],
					"destination": [
						"obj-raw-18",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-18",
						0
					],
					"destination": [
						"obj-raw-21",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-21",
						0
					],
					"destination": [
						"obj-raw-22",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-22",
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
				"decay",
				"decay",
				0
			],
			"obj-23": [
				"inject",
				"inject",
				0
			],
			"obj-26": [
				"radius",
				"radius",
				0
			],
			"obj-29": [
				"sweep",
				"sweep",
				0
			],
			"obj-32": [
				"rate",
				"rate",
				0
			],
			"obj-35": [
				"angle",
				"angle",
				0
			],
			"obj-38": [
				"lscale",
				"lscale",
				0
			],
			"obj-41": [
				"pwr",
				"pwr",
				0
			],
			"obj-44": [
				"edge",
				"edge",
				0
			],
			"obj-19a": [
				"freeze_on",
				"freeze_on",
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