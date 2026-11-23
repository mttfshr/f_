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
					"comment": "control messages (<param> <value>, bypass 0/1)",
					"index": 0,
					"numinlets": 0,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						20.0,
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
					"comment": "audio out",
					"index": 0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						20.0,
						480.0,
						30.0,
						30.0
					]
				}
			},
			{
				"box": {
					"id": "obj-3",
					"maxclass": "newobj",
					"text": "gen~",
					"varname": "core",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"signal"
					],
					"patching_rect": [
						20.0,
						330.0,
						60.0,
						22.0
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
						"classnamespace": "dsp.gen",
						"rect": [
							900.0,
							300.0,
							820.0,
							620.0
						],
						"boxes": [
							{
								"box": {
									"id": "obj-1",
									"maxclass": "newobj",
									"numinlets": 0,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										40.0,
										1.0,
										28.0,
										22.0
									],
									"text": "in 1"
								}
							},
							{
								"box": {
									"code": "// f_a_ripple v1 -- production DSP. Self-timed: t>=stim_dur triggers a\n// new stimulus internally (noise()-drawn f0/q/p), no external button.\n// History t's initial value (1000.0) forces an immediate first render on\n// load, so this self-starts with no loadbang wiring needed for that part.\n// Hearing-correction staircase (ADR-5) applied per-harmonic in both the\n// wavetable render and the modulated loop. band (1-7) maps to\n// flo_mod/fhi_mod internally (ADR-4). pm_turns is a real Param (T6 had\n// this hardcoded). Final tanh() ceiling guarantees output in [-1,1] by\n// construction regardless of profile/depth/band (ADR-6).\n\nParam band(6);\nParam mod_type(0);\nParam depth(1.0);\nParam tmr(1.0);\nParam smr_mean(4.5);\nParam smr_range(3.0);\nParam smr_cycle(8.0);\nParam pm_turns(0.5);\nParam f0_lo(96.0);\nParam f0_hi(256.0);\nParam stim_dur(4.0);\nParam ramp_pct(25.0);\nParam hearing_profile(0);\nParam gain(0.1);\nParam bypass_gate(0.0);\n\nData wtab(2048);\nHistory t(1000.0);\nHistory ph_prev(0.0);\nHistory f0_h(150.0);\nHistory q_h(0.0);\nHistory p_h(0.0);\nHistory geomean_mod(1000.0);\nHistory render_count(0);\nHistory byp_s(0.0);\n\nflo = 1000.0;\nfhi = 16000.0;\nflo_mod = 1000.0 * pow(2.0, (band - 1.0) * 0.5);\nfhi_mod = 1000.0 * pow(2.0, (band + 1.0) * 0.5);\n\nprofile_db = (hearing_profile == 0) ? 0.0\n           : (hearing_profile == 1) ? 15.0\n           : (hearing_profile == 2) ? 30.0\n           : 45.0;\n\nif (t >= stim_dur) {\n    f0_h = f0_lo + (noise() * 0.5 + 0.5) * (f0_hi - f0_lo);\n    q_h = (noise() * 0.5 + 0.5) * twopi;\n    p_h = (noise() * 0.5 + 0.5) * twopi;\n\n    for (i = 0; i < 2048; i += 1) {\n        phase_i = i / 2048;\n        s = 0.0;\n        c = 0.0;\n        for (n = 1; n <= 200; n += 1) {\n            freq = n * f0_h;\n            inband = (freq >= flo) && (freq < fhi);\n            modband = (freq >= flo_mod) && (freq < fhi_mod);\n            unmod = inband && (modband == 0);\n            half_oct = floor(log(max(freq, 1000.0) / 1000.0) / log(2.0) / 0.5);\n            half_oct = min(max(half_oct, 0.0), 7.0);\n            stair = (half_oct < 2.0) ? 0.0\n                  : (half_oct < 3.0) ? 0.125\n                  : (half_oct < 4.0) ? 0.375\n                  : (half_oct < 5.0) ? 0.625\n                  : (half_oct < 6.0) ? 0.875\n                  : 1.0;\n            corr = pow(10.0, (stair * profile_db) / 20.0);\n            s += unmod ? sin(twopi * n * phase_i) * corr : 0.0;\n            c += unmod ? 1.0 : 0.0;\n        }\n        wnorm = 1.0 / sqrt(max(c, 1.0));\n        poke(wtab, s * wnorm, i);\n    }\n\n    sumlog = 0.0;\n    cnt2 = 0.0;\n    for (n = 1; n <= 200; n += 1) {\n        freq = n * f0_h;\n        modband = (freq >= flo_mod) && (freq < fhi_mod);\n        sumlog += modband ? log(max(freq, 1.0)) : 0.0;\n        cnt2 += modband ? 1.0 : 0.0;\n    }\n    geomean_mod = exp(sumlog / max(cnt2, 1.0));\n\n    t = 0.0;\n    render_count = render_count + 1;\n}\n\ninc = f0_h / samplerate;\nph_acc = ph_prev + inc;\nwrapped = ph_acc >= 1.0;\nph_prev = ph_acc - wrapped;\n\nidx = ph_prev * 2048;\nidx_i0 = floor(idx);\nidx_i1 = mod(idx_i0 + 1, 2048);\nidx_frac = idx - idx_i0;\ntab_v0 = peek(wtab, idx_i0, 0);\ntab_v1 = peek(wtab, idx_i1, 0);\nwtab_out = tab_v0 + idx_frac * (tab_v1 - tab_v0);\n\ns_env = smr_mean + smr_range * sin(p_h + twopi * t / smr_cycle);\npm_depth_rad = pm_turns * pi;\n\nmodsum = 0.0;\nmodcnt = 0.0;\nfor (n = 1; n <= 200; n += 1) {\n    freq = n * f0_h;\n    modband = (freq >= flo_mod) && (freq < fhi_mod);\n    fn_i = log(max(freq, 1.0) / geomean_mod) / log(2.0);\n    m_i = sin(twopi * (q_h + tmr * t + fn_i * s_env));\n    half_oct2 = floor(log(max(freq, 1000.0) / 1000.0) / log(2.0) / 0.5);\n    half_oct2 = min(max(half_oct2, 0.0), 7.0);\n    stair2 = (half_oct2 < 2.0) ? 0.0\n           : (half_oct2 < 3.0) ? 0.125\n           : (half_oct2 < 4.0) ? 0.375\n           : (half_oct2 < 5.0) ? 0.625\n           : (half_oct2 < 6.0) ? 0.875\n           : 1.0;\n    corr2 = pow(10.0, (stair2 * profile_db) / 20.0);\n    base_phase = twopi * n * ph_prev;\n    am_val = (1.0 + depth * m_i) * sin(base_phase);\n    pm_val = sin(base_phase + pm_depth_rad * (1.0 + depth * m_i));\n    contrib = (mod_type != 0) ? pm_val : am_val;\n    modsum += modband ? contrib * corr2 : 0.0;\n    modcnt += modband ? 1.0 : 0.0;\n}\nmodnorm = 1.0 / sqrt(max(modcnt, 1.0));\n\nraw = wtab_out * 0.3 + modsum * modnorm * 0.3;\n\nramp_dur = stim_dur * (ramp_pct / 100.0);\nramp_dur_safe = max(ramp_dur, 0.0001);\nrise = 0.5 * (1.0 - cos(pi * min(t / ramp_dur_safe, 1.0)));\nt_from_end = stim_dur - t;\nfall = 0.5 * (1.0 - cos(pi * min(t_from_end / ramp_dur_safe, 1.0)));\nenv = min(rise, fall);\nenv = min(max(env, 0.0), 1.0);\n\nt = t + 1.0 / samplerate;\n\n// Module edits (audio archetype Phase A, 2026-11-16): bypass is a ~5 ms slewed mute\n// (the generator's neutral is silence), gain replaces output_level, no diagnostic outlets.\nbyp_s = byp_s + (bypass_gate - byp_s) * (1.0 - exp(-1.0 / (0.005 * samplerate)));\nout1 = tanh(raw * env * gain) * (1.0 - byp_s);",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 11.0,
									"id": "obj-2",
									"maxclass": "codebox",
									"numinlets": 1,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										40.0,
										40.0,
										760.0,
										560.0
									]
								}
							},
							{
								"box": {
									"id": "obj-3",
									"maxclass": "newobj",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										40.0,
										610.0,
										40.0,
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
										"obj-2",
										0
									],
									"source": [
										"obj-1",
										0
									]
								}
							},
							{
								"patchline": {
									"destination": [
										"obj-3",
										0
									],
									"source": [
										"obj-2",
										0
									]
								}
							}
						]
					}
				}
			},
			{
				"box": {
					"id": "obj-4",
					"maxclass": "newobj",
					"text": "route bypass band mod_type depth tmr smr_mean smr_range smr_cycle pm_turns f0_lo f0_hi stim_dur ramp_pct hearing_profile gain",
					"numinlets": 1,
					"numoutlets": 15,
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
						"",
						"",
						"",
						"",
						""
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"patching_rect": [
						20.0,
						70.0,
						150.0,
						22.0
					]
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
					"varname": "far_autopattr"
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
						330.0,
						152.0
					],
					"presentation": 1,
					"presentation_rect": [
						0.0,
						0.0,
						330.0,
						152.0
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
						10.5,
						0.0,
						92.0,
						21.0
					],
					"text": "f_a_ripple"
				}
			},
			{
				"box": {
					"id": "obj-20",
					"maxclass": "live.numbox",
					"fontname": "Ableton Sans Light",
					"hint": "Octave band that carries the ripple, 1 (1-2 kHz) to 7 (8-16 kHz)",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						20.0,
						60.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						4.0,
						38.0,
						34.0,
						15.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								6.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "band",
							"parameter_mmax": 7.0,
							"parameter_mmin": 1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "band",
							"parameter_type": 1,
							"parameter_unitstyle": 0
						}
					},
					"varname": "band"
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
						20.0,
						30.0,
						70.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						-7.5,
						20.0,
						50.0,
						18.0
					],
					"text": "Band",
					"textjustification": 1,
					"varname": "lbl_band"
				}
			},
			{
				"box": {
					"id": "obj-21",
					"maxclass": "newobj",
					"text": "prepend band",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						20.0,
						110.0,
						104.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-23",
					"maxclass": "live.menu",
					"fontname": "Ableton Sans Light",
					"hint": "Amplitude or phase modulation of the band's partials",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"",
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						110.0,
						60.0,
						60.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						46.0,
						52.0,
						45.0,
						15.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_enum": [
								"AM",
								"PM"
							],
							"parameter_initial": [
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "mod_type",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 0,
							"parameter_shortname": "mod_type",
							"parameter_type": 2,
							"parameter_unitstyle": 0
						}
					},
					"varname": "mod_type"
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
						110.0,
						30.0,
						70.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						38.5,
						20.0,
						50.0,
						18.0
					],
					"text": "Mod",
					"textjustification": 1,
					"varname": "lbl_mod_type"
				}
			},
			{
				"box": {
					"id": "obj-24",
					"maxclass": "newobj",
					"text": "prepend mod_type",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						110.0,
						150.0,
						136.0,
						22.0
					]
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
					"hint": "",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						200.0,
						60.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						96.0,
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
							"parameter_longname": "depth",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "depth",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "depth"
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
						200.0,
						30.0,
						70.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						84.5,
						20.0,
						50.0,
						18.0
					],
					"text": "Depth",
					"textjustification": 1,
					"varname": "lbl_depth"
				}
			},
			{
				"box": {
					"id": "obj-27",
					"maxclass": "newobj",
					"text": "prepend depth",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						200.0,
						110.0,
						112.0,
						22.0
					]
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
					"hint": "Temporal modulation rate in Hz (untested above about 10 Hz)",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						290.0,
						60.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						142.0,
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
							"parameter_longname": "tmr",
							"parameter_mmax": 256.0,
							"parameter_mmin": 0.1,
							"parameter_modmode": 3,
							"parameter_exponent": 3.0,
							"parameter_shortname": "tmr",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "tmr"
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
						290.0,
						30.0,
						70.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						130.5,
						20.0,
						50.0,
						18.0
					],
					"text": "TMR",
					"textjustification": 1,
					"varname": "lbl_tmr"
				}
			},
			{
				"box": {
					"id": "obj-30",
					"maxclass": "newobj",
					"text": "prepend tmr",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						290.0,
						150.0,
						96.0,
						22.0
					]
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
					"hint": "Mean spectral modulation rate, cycles per octave",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						380.0,
						60.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						188.0,
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
								4.5
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "smr_mean",
							"parameter_mmax": 12.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "smr_mean",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "smr_mean"
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
						380.0,
						30.0,
						70.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						176.5,
						20.0,
						50.0,
						18.0
					],
					"text": "SMR Mean",
					"textjustification": 1,
					"varname": "lbl_smr_mean"
				}
			},
			{
				"box": {
					"id": "obj-33",
					"maxclass": "newobj",
					"text": "prepend smr_mean",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						380.0,
						110.0,
						136.0,
						22.0
					]
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
					"hint": "Range of the spectral modulation rate; above the mean it reverses the ripple slope",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						470.0,
						60.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						234.0,
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
								3.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "smr_range",
							"parameter_mmax": 12.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "smr_range",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "smr_range"
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
						470.0,
						30.0,
						70.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						222.5,
						20.0,
						50.0,
						18.0
					],
					"text": "SMR Range",
					"textjustification": 1,
					"varname": "lbl_smr_range"
				}
			},
			{
				"box": {
					"id": "obj-36",
					"maxclass": "newobj",
					"text": "prepend smr_range",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						470.0,
						150.0,
						144.0,
						22.0
					]
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
					"hint": "Seconds for one sweep of the spectral modulation rate",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						560.0,
						60.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						280.0,
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
								8.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "smr_cycle",
							"parameter_mmax": 60.0,
							"parameter_mmin": 1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "smr_cycle",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "smr_cycle"
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
						560.0,
						30.0,
						70.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						268.5,
						20.0,
						50.0,
						18.0
					],
					"text": "SMR Cycle",
					"textjustification": 1,
					"varname": "lbl_smr_cycle"
				}
			},
			{
				"box": {
					"id": "obj-39",
					"maxclass": "newobj",
					"text": "prepend smr_cycle",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						560.0,
						110.0,
						144.0,
						22.0
					]
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
					"hint": "PM depth in full turns; 0.5 is the trial's actual depth",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						650.0,
						60.0,
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
								0.5
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "pm_turns",
							"parameter_mmax": 8.0,
							"parameter_mmin": 0.5,
							"parameter_modmode": 3,
							"parameter_shortname": "pm_turns",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "pm_turns"
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
						650.0,
						30.0,
						70.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						-7.5,
						82.0,
						50.0,
						18.0
					],
					"text": "PM Turns",
					"textjustification": 1,
					"varname": "lbl_pm_turns"
				}
			},
			{
				"box": {
					"id": "obj-42",
					"maxclass": "newobj",
					"text": "prepend pm_turns",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						650.0,
						150.0,
						136.0,
						22.0
					]
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
					"hint": "Low end of the random fundamental, Hz",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						740.0,
						60.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						50.0,
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
								96.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "f0_lo",
							"parameter_mmax": 400.0,
							"parameter_mmin": 50.0,
							"parameter_modmode": 3,
							"parameter_shortname": "f0_lo",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "f0_lo"
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
						740.0,
						30.0,
						70.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						38.5,
						82.0,
						50.0,
						18.0
					],
					"text": "F0 Lo",
					"textjustification": 1,
					"varname": "lbl_f0_lo"
				}
			},
			{
				"box": {
					"id": "obj-45",
					"maxclass": "newobj",
					"text": "prepend f0_lo",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						740.0,
						110.0,
						112.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-47",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "High end of the random fundamental, Hz",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						830.0,
						60.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						96.0,
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
								256.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "f0_hi",
							"parameter_mmax": 400.0,
							"parameter_mmin": 50.0,
							"parameter_modmode": 3,
							"parameter_shortname": "f0_hi",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "f0_hi"
				}
			},
			{
				"box": {
					"id": "obj-49",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						830.0,
						30.0,
						70.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						84.5,
						82.0,
						50.0,
						18.0
					],
					"text": "F0 Hi",
					"textjustification": 1,
					"varname": "lbl_f0_hi"
				}
			},
			{
				"box": {
					"id": "obj-48",
					"maxclass": "newobj",
					"text": "prepend f0_hi",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						830.0,
						150.0,
						112.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-50",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Seconds per stimulus; a new fundamental is drawn at each",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						920.0,
						60.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						142.0,
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
								4.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "stim_dur",
							"parameter_mmax": 30.0,
							"parameter_mmin": 1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "stim_dur",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "stim_dur"
				}
			},
			{
				"box": {
					"id": "obj-52",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						920.0,
						30.0,
						70.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						130.5,
						82.0,
						50.0,
						18.0
					],
					"text": "Duration",
					"textjustification": 1,
					"varname": "lbl_stim_dur"
				}
			},
			{
				"box": {
					"id": "obj-51",
					"maxclass": "newobj",
					"text": "prepend stim_dur",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						920.0,
						110.0,
						136.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-53",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Raised-cosine ramp at each end, percent of the stimulus",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						1010.0,
						60.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						188.0,
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
								25.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "ramp_pct",
							"parameter_mmax": 50.0,
							"parameter_mmin": 5.0,
							"parameter_modmode": 3,
							"parameter_shortname": "ramp_pct",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "ramp_pct"
				}
			},
			{
				"box": {
					"id": "obj-55",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						1010.0,
						30.0,
						70.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						176.5,
						82.0,
						50.0,
						18.0
					],
					"text": "Ramp %",
					"textjustification": 1,
					"varname": "lbl_ramp_pct"
				}
			},
			{
				"box": {
					"id": "obj-54",
					"maxclass": "newobj",
					"text": "prepend ramp_pct",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1010.0,
						150.0,
						136.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-56",
					"maxclass": "live.menu",
					"fontname": "Ableton Sans Light",
					"hint": "Hearing-correction boost staircase (0, 15, 30, 45 dB)",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"",
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						1100.0,
						60.0,
						60.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						230.0,
						114.0,
						45.0,
						15.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_enum": [
								"NH",
								"Mild",
								"Mod",
								"Severe"
							],
							"parameter_initial": [
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "hearing_profile",
							"parameter_mmax": 3.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 0,
							"parameter_shortname": "hearing_profile",
							"parameter_type": 2,
							"parameter_unitstyle": 0
						}
					},
					"varname": "hearing_profile"
				}
			},
			{
				"box": {
					"id": "obj-58",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						1100.0,
						30.0,
						70.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						222.5,
						82.0,
						50.0,
						18.0
					],
					"text": "Hearing",
					"textjustification": 1,
					"varname": "lbl_hearing_profile"
				}
			},
			{
				"box": {
					"id": "obj-57",
					"maxclass": "newobj",
					"text": "prepend hearing_profile",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1100.0,
						110.0,
						192.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-59",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Output level before the tanh safety ceiling",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						1190.0,
						60.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						280.0,
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
								0.1
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "gain",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "gain",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "gain"
				}
			},
			{
				"box": {
					"id": "obj-61",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						1190.0,
						30.0,
						70.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						268.5,
						82.0,
						50.0,
						18.0
					],
					"text": "Gain",
					"textjustification": 1,
					"varname": "lbl_gain"
				}
			},
			{
				"box": {
					"id": "obj-60",
					"maxclass": "newobj",
					"text": "prepend gain",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1190.0,
						150.0,
						104.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-62",
					"maxclass": "live.text",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"mode": 1,
					"hint": "Bypass: mutes the output (a generator's neutral is silence), slewed over about 5 ms",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"parameter_enable": 1,
					"patching_rect": [
						1280.0,
						60.0,
						40.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						286.0,
						2.0,
						40.0,
						15.0
					],
					"text": "Bypass",
					"texton": "Bypass",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_enum": [
								"Off",
								"On"
							],
							"parameter_initial": [
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "bypass",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 0,
							"parameter_shortname": "bypass",
							"parameter_type": 1,
							"parameter_unitstyle": 0
						}
					},
					"varname": "bypass"
				}
			},
			{
				"box": {
					"id": "obj-63",
					"maxclass": "newobj",
					"text": "prepend bypass_gate",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1280.0,
						110.0,
						150.0,
						22.0
					]
				}
			}
		],
		"lines": [
			{
				"patchline": {
					"source": [
						"obj-3",
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
						"obj-1",
						0
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
						"obj-4",
						1
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
						"obj-3",
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
						"obj-3",
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
						"obj-3",
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
						"obj-3",
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
						"obj-3",
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
						"obj-3",
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
						"obj-3",
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
						"obj-3",
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
						"obj-3",
						0
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
						"obj-47",
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
						"obj-3",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-4",
						11
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
						"obj-51",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-51",
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
						"obj-4",
						12
					],
					"destination": [
						"obj-53",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-53",
						0
					],
					"destination": [
						"obj-54",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-54",
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
						"obj-4",
						13
					],
					"destination": [
						"obj-56",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-56",
						0
					],
					"destination": [
						"obj-57",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-57",
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
						"obj-4",
						14
					],
					"destination": [
						"obj-59",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-59",
						0
					],
					"destination": [
						"obj-60",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-60",
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
						"obj-62",
						0
					],
					"destination": [
						"obj-63",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-63",
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
						"obj-4",
						0
					],
					"destination": [
						"obj-62",
						0
					]
				}
			}
		],
		"parameters": {
			"obj-20": [
				"band",
				"band",
				0
			],
			"obj-23": [
				"mod_type",
				"mod_type",
				0
			],
			"obj-26": [
				"depth",
				"depth",
				0
			],
			"obj-29": [
				"tmr",
				"tmr",
				0
			],
			"obj-32": [
				"smr_mean",
				"smr_mean",
				0
			],
			"obj-35": [
				"smr_range",
				"smr_range",
				0
			],
			"obj-38": [
				"smr_cycle",
				"smr_cycle",
				0
			],
			"obj-41": [
				"pm_turns",
				"pm_turns",
				0
			],
			"obj-44": [
				"f0_lo",
				"f0_lo",
				0
			],
			"obj-47": [
				"f0_hi",
				"f0_hi",
				0
			],
			"obj-50": [
				"stim_dur",
				"stim_dur",
				0
			],
			"obj-53": [
				"ramp_pct",
				"ramp_pct",
				0
			],
			"obj-56": [
				"hearing_profile",
				"hearing_profile",
				0
			],
			"obj-59": [
				"gain",
				"gain",
				0
			],
			"obj-62": [
				"bypass",
				"bypass",
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