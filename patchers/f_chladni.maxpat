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
						30.0,
						30.0,
						30.0
					]
				}
			},
			{
				"box": {
					"id": "obj-2",
					"maxclass": "outlet",
					"comment": "luma",
					"index": 0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						30.0,
						500.0,
						30.0,
						30.0
					]
				}
			},
			{
				"box": {
					"id": "obj-201",
					"maxclass": "outlet",
					"comment": "vecfield",
					"index": 1,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						100.0,
						500.0,
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
						200.0,
						90.0,
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
					"numoutlets": 9,
					"outlettype": [
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
						200.0,
						130.0,
						490.0,
						22.0
					],
					"text": "route note amp dishradius reflectamt linesharpness ph0 spread mode view_mode"
				}
			},
			{
				"box": {
					"id": "obj-5",
					"maxclass": "newobj",
					"numinlets": 1,
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
									"code": "// --- Helper: Mode A total at arbitrary UV ---\nmodal_A(ux, uy, zp, radius, reflect, phase) {\n    ddx = ux - 0.5;\n    ddy = uy - 0.5;\n    rs  = max(sqrt(ddx*ddx + ddy*ddy) * 2.0 * radius, 0.001);\n    th  = atan2(ddy, ddx);\n    ev  = sqrt(2.0 / (pi * rs));\n    msk = 1.0 - smoothstep(0.8, 1.0, rs / max(radius, 0.001));\n\n    z0 = 2.4048; z1 = 3.8317; z2 = 5.1356; z3 = 6.3802;\n    z4 = 7.5883; z5 = 8.7715; z6 = 9.9361; z7 = 11.0864;\n\n    s0 = step(z0, zp) * step(zp, z1);\n    s1 = step(z1, zp) * step(zp, z2);\n    s2 = step(z2, zp) * step(zp, z3);\n    s3 = step(z3, zp) * step(zp, z4);\n    s4 = step(z4, zp) * step(zp, z5);\n    s5 = step(z5, zp) * step(zp, z6);\n    s6 = step(z6, zp) * step(zp, z7);\n\n    c0lo = (ev*cos(rs-z0) + reflect*ev*cos(radius-rs-z0)) * cos(0.0*th + phase) * msk;\n    c0hi = (ev*cos(rs-z1) + reflect*ev*cos(radius-rs-z1)) * cos(1.0*th + phase) * msk;\n    c1lo = (ev*cos(rs-z1) + reflect*ev*cos(radius-rs-z1)) * cos(1.0*th + phase) * msk;\n    c1hi = (ev*cos(rs-z2) + reflect*ev*cos(radius-rs-z2)) * cos(2.0*th + phase) * msk;\n    c2lo = (ev*cos(rs-z2) + reflect*ev*cos(radius-rs-z2)) * cos(2.0*th + phase) * msk;\n    c2hi = (ev*cos(rs-z3) + reflect*ev*cos(radius-rs-z3)) * cos(3.0*th + phase) * msk;\n    c3lo = (ev*cos(rs-z3) + reflect*ev*cos(radius-rs-z3)) * cos(3.0*th + phase) * msk;\n    c3hi = (ev*cos(rs-z4) + reflect*ev*cos(radius-rs-z4)) * cos(4.0*th + phase) * msk;\n    c4lo = (ev*cos(rs-z4) + reflect*ev*cos(radius-rs-z4)) * cos(4.0*th + phase) * msk;\n    c4hi = (ev*cos(rs-z5) + reflect*ev*cos(radius-rs-z5)) * cos(5.0*th + phase) * msk;\n    c5lo = (ev*cos(rs-z5) + reflect*ev*cos(radius-rs-z5)) * cos(5.0*th + phase) * msk;\n    c5hi = (ev*cos(rs-z6) + reflect*ev*cos(radius-rs-z6)) * cos(6.0*th + phase) * msk;\n    c6lo = (ev*cos(rs-z6) + reflect*ev*cos(radius-rs-z6)) * cos(6.0*th + phase) * msk;\n    c6hi = (ev*cos(rs-z7) + reflect*ev*cos(radius-rs-z7)) * cos(7.0*th + phase) * msk;\n\n    return mix(c0lo, c0hi, (zp-z0)/(z1-z0)) * s0\n         + mix(c1lo, c1hi, (zp-z1)/(z2-z1)) * s1\n         + mix(c2lo, c2hi, (zp-z2)/(z3-z2)) * s2\n         + mix(c3lo, c3hi, (zp-z3)/(z4-z3)) * s3\n         + mix(c4lo, c4hi, (zp-z4)/(z5-z4)) * s4\n         + mix(c5lo, c5hi, (zp-z5)/(z6-z5)) * s5\n         + mix(c6lo, c6hi, (zp-z6)/(z7-z6)) * s6;\n}\n\n// --- Helper: Mode B total at arbitrary UV ---\nmodal_B(ux, uy, zp, radius, reflect, phase, sprd) {\n    ddx = ux - 0.5;\n    ddy = uy - 0.5;\n    rs  = max(sqrt(ddx*ddx + ddy*ddy) * 2.0 * radius, 0.001);\n    th  = atan2(ddy, ddx);\n    ev  = sqrt(2.0 / (pi * rs));\n    msk = 1.0 - smoothstep(0.8, 1.0, rs / max(radius, 0.001));\n\n    z0 = 2.4048; z1 = 3.8317; z2 = 5.1356; z3 = 6.3802;\n    z4 = 7.5883; z5 = 8.7715; z6 = 9.9361; z7 = 11.0864;\n\n    sp2 = max(sprd * sprd * 2.0, 0.0001);\n    w0 = exp(-((zp-z0)*(zp-z0)) / sp2);\n    w1 = exp(-((zp-z1)*(zp-z1)) / sp2);\n    w2 = exp(-((zp-z2)*(zp-z2)) / sp2);\n    w3 = exp(-((zp-z3)*(zp-z3)) / sp2);\n    w4 = exp(-((zp-z4)*(zp-z4)) / sp2);\n    w5 = exp(-((zp-z5)*(zp-z5)) / sp2);\n    w6 = exp(-((zp-z6)*(zp-z6)) / sp2);\n    w7 = exp(-((zp-z7)*(zp-z7)) / sp2);\n    ws = max(w0+w1+w2+w3+w4+w5+w6+w7, 0.0001);\n\n    m0 = (ev*cos(rs-z0) + reflect*ev*cos(radius-rs-z0)) * cos(0.0*th + phase) * msk;\n    m1 = (ev*cos(rs-z1) + reflect*ev*cos(radius-rs-z1)) * cos(1.0*th + phase) * msk;\n    m2 = (ev*cos(rs-z2) + reflect*ev*cos(radius-rs-z2)) * cos(2.0*th + phase) * msk;\n    m3 = (ev*cos(rs-z3) + reflect*ev*cos(radius-rs-z3)) * cos(3.0*th + phase) * msk;\n    m4 = (ev*cos(rs-z4) + reflect*ev*cos(radius-rs-z4)) * cos(4.0*th + phase) * msk;\n    m5 = (ev*cos(rs-z5) + reflect*ev*cos(radius-rs-z5)) * cos(5.0*th + phase) * msk;\n    m6 = (ev*cos(rs-z6) + reflect*ev*cos(radius-rs-z6)) * cos(6.0*th + phase) * msk;\n    m7 = (ev*cos(rs-z7) + reflect*ev*cos(radius-rs-z7)) * cos(7.0*th + phase) * msk;\n\n    return (w0*m0 + w1*m1 + w2*m2 + w3*m3 + w4*m4 + w5*m5 + w6*m6 + w7*m7) / ws;\n}\n\n// --- Params ---\nParam note(60.0);\nParam amp(1.0);\nParam dishradius(1.0);\nParam reflectamt(0.0);\nParam linesharpness(10.0);\nParam ph0(0.0);\nParam spread(0.3);\nParam mode(0.0);\nParam view_mode(0.0);\nParam bypass(0.0);\n\n// --- Bessel zeros ---\nz0 = 2.4048; z1 = 3.8317; z2 = 5.1356; z3 = 6.3802;\nz4 = 7.5883; z5 = 8.7715; z6 = 9.9361; z7 = 11.0864;\n\n// --- Map note 0-127 to Bessel zero span ---\nz_pos = z0 + (note / 127.0) * (z7 - z0);\n\n// --- Coordinate system (circular / strip blend) ---\ndx = norm.x - 0.5;\ndy = norm.y - 0.5;\nr_circ  = sqrt(dx*dx + dy*dy) * 2.0 * dishradius;\nth_circ = atan2(dy, dx);\nr_strip  = norm.y * dishradius;\nth_strip = norm.x * twopi - pi;\nr  = mix(r_circ,  r_strip,  view_mode);\nth = mix(th_circ, th_strip, view_mode);\n\nr_s  = max(r, 0.001);\nenv  = sqrt(2.0 / (pi * r_s));\nmask = 1.0 - smoothstep(0.8, 1.0, r / max(dishradius, 0.001));\n\n// --- Mode A: linear blend (via function at center UV) ---\ntotal_A = modal_A(norm.x, norm.y, z_pos, dishradius, reflectamt, ph0);\n\n// --- Mode B: Gaussian resonance snap ---\n// expressive spread range: 0.1-0.5 (below 0.1 produces white artifacts between modes)\nspread2 = max(spread * spread * 2.0, 0.0001);\nw0 = exp(-((z_pos-z0)*(z_pos-z0)) / spread2);\nw1 = exp(-((z_pos-z1)*(z_pos-z1)) / spread2);\nw2 = exp(-((z_pos-z2)*(z_pos-z2)) / spread2);\nw3 = exp(-((z_pos-z3)*(z_pos-z3)) / spread2);\nw4 = exp(-((z_pos-z4)*(z_pos-z4)) / spread2);\nw5 = exp(-((z_pos-z5)*(z_pos-z5)) / spread2);\nw6 = exp(-((z_pos-z6)*(z_pos-z6)) / spread2);\nw7 = exp(-((z_pos-z7)*(z_pos-z7)) / spread2);\nwsum = max(w0+w1+w2+w3+w4+w5+w6+w7, 0.0001);\n\nm0 = (env*cos(r_s-z0) + reflectamt*env*cos(dishradius-r_s-z0)) * cos(0.0*th + ph0) * mask;\nm1 = (env*cos(r_s-z1) + reflectamt*env*cos(dishradius-r_s-z1)) * cos(1.0*th + ph0) * mask;\nm2 = (env*cos(r_s-z2) + reflectamt*env*cos(dishradius-r_s-z2)) * cos(2.0*th + ph0) * mask;\nm3 = (env*cos(r_s-z3) + reflectamt*env*cos(dishradius-r_s-z3)) * cos(3.0*th + ph0) * mask;\nm4 = (env*cos(r_s-z4) + reflectamt*env*cos(dishradius-r_s-z4)) * cos(4.0*th + ph0) * mask;\nm5 = (env*cos(r_s-z5) + reflectamt*env*cos(dishradius-r_s-z5)) * cos(5.0*th + ph0) * mask;\nm6 = (env*cos(r_s-z6) + reflectamt*env*cos(dishradius-r_s-z6)) * cos(6.0*th + ph0) * mask;\nm7 = (env*cos(r_s-z7) + reflectamt*env*cos(dishradius-r_s-z7)) * cos(7.0*th + ph0) * mask;\ntotal_B = (w0*m0 + w1*m1 + w2*m2 + w3*m3 + w4*m4 + w5*m5 + w6*m6 + w7*m7) / wsum;\n\n// --- Select mode and scale ---\ntotal = mix(total_A, total_B, step(0.5, mode)) * amp;\n\n// --- Luma output ---\nline     = 1.0 - clamp(sqrt(abs(total)) * linesharpness, 0.0, 1.0);\nluma_out = vec(line, line, line, 1.0);\n\n// --- Vecfield: central difference gradient, mode-aware ---\neps  = 0.004;\nmd   = step(0.5, mode);\nt_xp = mix(modal_A(norm.x+eps, norm.y,     z_pos, dishradius, reflectamt, ph0),\n           modal_B(norm.x+eps, norm.y,     z_pos, dishradius, reflectamt, ph0, spread), md);\nt_xn = mix(modal_A(norm.x-eps, norm.y,     z_pos, dishradius, reflectamt, ph0),\n           modal_B(norm.x-eps, norm.y,     z_pos, dishradius, reflectamt, ph0, spread), md);\nt_yp = mix(modal_A(norm.x,     norm.y+eps, z_pos, dishradius, reflectamt, ph0),\n           modal_B(norm.x,     norm.y+eps, z_pos, dishradius, reflectamt, ph0, spread), md);\nt_yn = mix(modal_A(norm.x,     norm.y-eps, z_pos, dishradius, reflectamt, ph0),\n           modal_B(norm.x,     norm.y-eps, z_pos, dishradius, reflectamt, ph0, spread), md);\n\ngx = (t_xp - t_xn) / (2.0 * eps);\ngy = (t_yp - t_yn) / (2.0 * eps);\ngmag = max(sqrt(gx*gx + gy*gy), 0.0001);\nvf_out = vec(gx/gmag * 0.5 + 0.5, gy/gmag * 0.5 + 0.5, 0.0, 1.0);\n\n// --- Outputs ---\nout1 = mix(luma_out, vec(0.0, 0.0, 0.0, 1.0), bypass);\nout2 = mix(vf_out,   vec(0.5, 0.5, 0.0, 1.0), bypass);\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
									"id": "gen-obj-2",
									"maxclass": "codebox",
									"numinlets": 1,
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
						200.0,
						380.0,
						200.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name chladni_pix @type float32",
					"varname": "chladni_pix"
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
						500.0,
						500.0,
						56.0,
						22.0
					],
					"text": "autopattr",
					"varname": "chladni_autopattr"
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
						20.0,
						20.0,
						227.0,
						164.0
					],
					"presentation": 1,
					"presentation_rect": [
						0.0,
						0.0,
						227.0,
						164.0
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
						20.0,
						20.0,
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
					"text": "Chladni"
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
						600.0,
						50.0,
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
						600.0,
						80.0,
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
						600.0,
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
						600.0,
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
						600.0,
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
						600.0,
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
					"hint": "MIDI note (0-127) \u2014 selects Bessel mode via linear mapping",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "chladni_pix::note",
					"parameter_enable": 1,
					"patching_rect": [
						50.0,
						80.0,
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
								60.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "note",
							"parameter_mmax": 127.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "note",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "note"
				}
			},
			{
				"box": {
					"id": "obj-21",
					"maxclass": "attrui",
					"attr": "note",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						50.0,
						170.0,
						108.0,
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
						50.0,
						130.0,
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
					"text": "note",
					"textjustification": 1
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
					"hint": "Amplitude envelope \u2014 scales output brightness",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "chladni_pix::amp",
					"parameter_enable": 1,
					"patching_rect": [
						100.0,
						80.0,
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
								1.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "amp",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "amp",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "amp"
				}
			},
			{
				"box": {
					"id": "obj-24",
					"maxclass": "attrui",
					"attr": "amp",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						100.0,
						200.0,
						101.0,
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
						100.0,
						130.0,
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
					"text": "amp",
					"textjustification": 1
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
					"hint": "Plate radius \u2014 scales field in both view modes",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "chladni_pix::dishradius",
					"parameter_enable": 1,
					"patching_rect": [
						150.0,
						80.0,
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
							"parameter_longname": "dishradius",
							"parameter_mmax": 4.0,
							"parameter_mmin": 0.1,
							"parameter_modmode": 3,
							"parameter_shortname": "dishradius",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "dishradius"
				}
			},
			{
				"box": {
					"id": "obj-27",
					"maxclass": "attrui",
					"attr": "dishradius",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						150.0,
						230.0,
						150.0,
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
						150.0,
						130.0,
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
					"text": "radius",
					"textjustification": 1
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
					"hint": "Boundary reflection amount \u2014 adds reflected wave",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "chladni_pix::reflectamt",
					"parameter_enable": 1,
					"patching_rect": [
						200.0,
						80.0,
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
							"parameter_longname": "reflectamt",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "reflectamt",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "reflectamt"
				}
			},
			{
				"box": {
					"id": "obj-30",
					"maxclass": "attrui",
					"attr": "reflectamt",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						200.0,
						260.0,
						150.0,
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
						200.0,
						130.0,
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
					"text": "reflect",
					"textjustification": 1
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
					"hint": "Nodal line sharpness \u2014 higher = thinner lines",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "chladni_pix::linesharpness",
					"parameter_enable": 1,
					"patching_rect": [
						250.0,
						80.0,
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
								10.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "linesharpness",
							"parameter_mmax": 100.0,
							"parameter_mmin": 0.1,
							"parameter_modmode": 3,
							"parameter_shortname": "linesharpness",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "linesharpness"
				}
			},
			{
				"box": {
					"id": "obj-33",
					"maxclass": "attrui",
					"attr": "linesharpness",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						250.0,
						290.0,
						171.0,
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
						250.0,
						130.0,
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
					"text": "sharp",
					"textjustification": 1
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
					"hint": "Global phase offset \u2014 rotates nodal pattern",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "chladni_pix::ph0",
					"parameter_enable": 1,
					"patching_rect": [
						300.0,
						80.0,
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
							"parameter_longname": "ph0",
							"parameter_mmax": 6.2832,
							"parameter_mmin": -6.2832,
							"parameter_modmode": 3,
							"parameter_shortname": "ph0",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "ph0"
				}
			},
			{
				"box": {
					"id": "obj-36",
					"maxclass": "attrui",
					"attr": "ph0",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						300.0,
						320.0,
						101.0,
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
						300.0,
						130.0,
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
					"text": "phase",
					"textjustification": 1
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
					"hint": "Mode B falloff width \u2014 0.1=snap 0.5=broad (Mode B only)",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "chladni_pix::spread",
					"parameter_enable": 1,
					"patching_rect": [
						350.0,
						80.0,
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
								0.3
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "spread",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.1,
							"parameter_modmode": 3,
							"parameter_shortname": "spread",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "spread"
				}
			},
			{
				"box": {
					"id": "obj-39",
					"maxclass": "attrui",
					"attr": "spread",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						350.0,
						350.0,
						122.0,
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
						350.0,
						130.0,
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
					"text": "spread",
					"textjustification": 1
				}
			},
			{
				"box": {
					"id": "obj-41",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "0=linear interp between modes  1=Gaussian resonance snap",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "chladni_pix::mode",
					"parameter_enable": 1,
					"patching_rect": [
						400.0,
						80.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						78.0,
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
							"parameter_longname": "mode",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "mode",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "mode"
				}
			},
			{
				"box": {
					"id": "obj-42",
					"maxclass": "attrui",
					"attr": "mode",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						400.0,
						380.0,
						108.0,
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
						400.0,
						130.0,
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
					"text": "mode",
					"textjustification": 1
				}
			},
			{
				"box": {
					"id": "obj-44",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "0=circular plate  1=unwrapped strip",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "chladni_pix::view_mode",
					"parameter_enable": 1,
					"patching_rect": [
						450.0,
						80.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						115.0,
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
							"parameter_longname": "view_mode",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "view_mode",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "view_mode"
				}
			},
			{
				"box": {
					"id": "obj-45",
					"maxclass": "attrui",
					"attr": "view_mode",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						450.0,
						410.0,
						143.0,
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
						450.0,
						130.0,
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
					"text": "view",
					"textjustification": 1
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
						205.0,
						5.0,
						18.0,
						12.0
					],
					"presentation_rect": [
						205.0,
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
					"maxclass": "attrui",
					"attr": "bypass",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						400.0,
						60.0,
						131.0,
						22.0
					],
					"style": ""
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
			}
		],
		"parameters": {
			"obj-20": [
				"note",
				"note",
				0
			],
			"obj-23": [
				"amp",
				"amp",
				0
			],
			"obj-26": [
				"dishradius",
				"dishradius",
				0
			],
			"obj-29": [
				"reflectamt",
				"reflectamt",
				0
			],
			"obj-32": [
				"linesharpness",
				"linesharpness",
				0
			],
			"obj-35": [
				"ph0",
				"ph0",
				0
			],
			"obj-38": [
				"spread",
				"spread",
				0
			],
			"obj-41": [
				"mode",
				"mode",
				0
			],
			"obj-44": [
				"view_mode",
				"view_mode",
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