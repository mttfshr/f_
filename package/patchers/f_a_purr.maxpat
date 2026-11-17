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
					"maxclass": "newobj",
					"text": "inlet~",
					"numinlets": 0,
					"numoutlets": 1,
					"outlettype": [
						"signal"
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"comment": "breath phase in (0-1)",
					"patching_rect": [
						20.0,
						240.0,
						50.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-2",
					"maxclass": "newobj",
					"text": "outlet~",
					"numinlets": 1,
					"numoutlets": 0,
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"comment": "purr",
					"patching_rect": [
						20.0,
						420.0,
						55.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-201",
					"maxclass": "newobj",
					"text": "outlet~",
					"numinlets": 1,
					"numoutlets": 0,
					"fontname": "Ableton Sans Light",
					"fontsize": 12.0,
					"comment": "breath phase (0-1)",
					"patching_rect": [
						90.0,
						420.0,
						55.0,
						22.0
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
					"numoutlets": 2,
					"outlettype": [
						"signal",
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
									"code": "Param rate_hz(25);\nParam rate_jit(0.05);\nParam amp_jit(0.05);\nParam decay_ms(3.7);\nParam decay_jit(0.6);\nParam tilt(0.5);\nParam res_hz(215.5);\nParam res_q(0.9919);\nParam breath_hz(0.32);\nParam breath_skew(0.79);\nParam breath_depth(0.3);\nParam breath_rate_mod(0.464);\nParam breath_noise(0.15);\nParam breath_src(0);\nParam breath_src_ms(50);\nParam breath_shape(0);\nParam breath_jit(0);\nParam jit_tau(0);\nParam ph_gain(0);\nParam ph_tilt(0);\nParam ph_res(0);\nParam ph_rate(0);\nParam run_prob(0);\nParam run_oct(0.6);\nParam gain(0.3);\nParam bypass_gate(0.0);\n\nHistory ph_prev(0);\nHistory rate_h(25);\nHistory dec_h(5);\nHistory env_prev(0);\nHistory lp_prev(0);\nHistory y1(0);\nHistory y2(0);\nHistory bph_prev(0);\nHistory bn_prev(0);\nHistory bsrc_prev(0);\nHistory bjm_h(1);\nHistory jr_h(0);\nHistory ja_h(0);\nHistory jd_h(0);\nHistory rl_h(0);\nHistory rm_h(1);\nHistory byp_s(0);\n\n// ---- clamp all params: message path is unprotected by dial ranges ----\nc_rate = min(200, max(1, rate_hz));\nc_rjit = min(0.5, max(0, rate_jit));\nc_ajit = min(0.9, max(0, amp_jit));\nc_dec = min(200, max(0.2, decay_ms));\nc_djit = min(0.9, max(0, decay_jit));\nc_tilt = min(1, max(0.02, tilt));\nc_res = min(samplerate * 0.25, max(20, res_hz));\nq = min(0.999, max(0.5, res_q));\nc_bhz = min(2, max(0.05, breath_hz));\nc_bskew = min(1, max(-1, breath_skew));   // -1..1: negative = inhale longer than exhale\nc_bdepth = min(1, max(0, breath_depth));\nc_brmod = min(0.5, max(-0.5, breath_rate_mod));\nc_bnoise = min(1, max(0, breath_noise));\nc_bsrc = min(1, max(0, breath_src));\nc_bsms = min(2000, max(1, breath_src_ms));\nc_bshape = min(1, max(0, breath_shape));\nc_bjit = min(0.3, max(0, breath_jit));\nc_jtau = min(10, max(0, jit_tau));\nc_phgain = min(1, max(-1, ph_gain));\nc_phtilt = min(1, max(-1, ph_tilt));\nc_phres = min(1, max(-1, ph_res));\nc_phrate = min(1, max(-1, ph_rate));\nc_runp = min(1, max(0, run_prob));\nc_runoct = min(1.5, max(0, run_oct));\n\n// ---- read held values before writing ----\nr_held = rate_h;\nd_held = dec_h;\nbjm_held = bjm_h;\njr_held = jr_h;\nja_held = ja_h;\njd_held = jd_h;\nrl_held = rl_h;\nrm_held = rm_h;\n\n// ---- layer 2: breath oscillator, free-running, independent of click cycle ----\nbph_acc = bph_prev + c_bhz * bjm_held * rm_held / samplerate;\nbwrap = bph_acc >= 1;\nbph_prev = bph_acc - bwrap;\n// per-breath period jitter: SD of the rate multiplier = c_bjit (noise() is uniform, SD 1/sqrt(3), hence 1.732)\nbjm_h = bwrap ? max(0.3, 1 + c_bjit * 1.732 * noise()) : bjm_held;\n// ---- clustered tempo excursions: with probability run_prob per breath, a run of 2-4 breaths at a different\n// breath tempo (log-uniform within +-run_oct octaves), then back to normal; run_prob 0 = off ----\nru1 = 0.5 + 0.5 * noise();\nru2 = 0.5 + 0.5 * noise();\nru3 = 0.5 + 0.5 * noise();\nr_len = 2 + (ru2 > 0.3333) + (ru2 > 0.6667);\nr_cont = rl_held > 1;\nr_start = (rl_held <= 1) * (ru1 < c_runp);\nrl_h = bwrap ? (r_cont ? rl_held - 1 : (r_start ? r_len : 0)) : rl_held;\nrm_h = bwrap ? (r_cont ? rm_held : (r_start ? exp(0.6931472 * c_runoct * (2 * ru3 - 1)) : 1)) : rm_held;\n\nfi = 0.5 - 0.4 * c_bskew;\nb_int = bph_prev < fi ? 0.5 * bph_prev / fi : 0.5 + 0.5 * (bph_prev - fi) / (1 - fi);\n// ---- breath source: internal oscillator <-> external phase on in1, crossfaded on the phase ----\n// fade runs along the shortest circular arc so b_curve, the rate fold and out2 stay consistent;\n// external value used only if 0 <= in1 <= 1 (NaN fails both tests -> falls back to internal)\nbsrc_p = bsrc_prev;\nbsrc_s = bsrc_p + (1 - exp(-1 / (c_bsms * 0.001 * samplerate))) * (c_bsrc - bsrc_p);\nbsrc_prev = bsrc_s;\next_ok = (in1 >= 0) * (in1 <= 1);\nb_ext = ext_ok ? in1 : b_int;\nb_d = b_ext - b_int;\nb_dw = b_d - (b_d >= 0.5) + (b_d < -0.5);\nb_mix = b_int + bsrc_s * b_dw;\nb_phase = b_mix - (b_mix >= 1) + (b_mix < 0);\n// shape 0 = one hump per breath (peak at the 0.5 crossover); shape 1 = two humps (mid-inhale, mid-exhale,\n// dips at both flow reversals); breath_depth sets how deep the dips go\nb_c1 = 0.5 - 0.5 * cos(twopi * b_phase);\nb_c2 = 0.5 - 0.5 * cos(2 * twopi * b_phase);\nb_curve = b_c1 + c_bshape * (b_c2 - b_c1);\n\n// ---- inhale/exhale contrast: s_ph = +1 mid-inhale, -1 mid-exhale, 0 at both flow reversals (smooth) ----\n// all four ph_ params are bipolar, default 0 = no contrast; positive = the inhale gets more of it\ns_ph = cos(twopi * (b_phase - 0.25));\ngph = exp(0.6931472 * c_phgain * s_ph);                                              // level: +-6 dB at full scale\nc_tilt_e = min(1, max(0.02, c_tilt * exp(c_phtilt * s_ph)));                         // tilt: positive = inhale brighter\nc_res_e = min(samplerate * 0.25, max(20, c_res * exp(0.3465736 * c_phres * s_ph)));  // resonator: +-6 semitones at full scale\n\n// ---- accumulator ----\nph_acc = ph_prev + r_held / samplerate;\ntrig = ph_acc >= 1;\nph_prev = ph_acc - trig;\n\n// ---- correlated per-cycle jitter: AR(1) across click cycles; jit_tau = correlation time in seconds, 0 = white (old behaviour) ----\nrho = c_jtau > 0 ? exp(-1 / max(0.001, c_jtau * r_held)) : 0;\ns_rho = sqrt(1 - rho * rho);\njr_new = min(3, max(-3, rho * jr_held + s_rho * noise()));\nja_new = min(3, max(-3, rho * ja_held + s_rho * noise()));\njd_new = min(3, max(-3, rho * jd_held + s_rho * noise()));\n\n// ---- per-cycle latch (breath rate offset folded in per ADR-3 / idea-file Q5) ----\nrate_target = max(1, c_rate * (1 + c_brmod * b_curve) * (1 + c_rjit * jr_new) * (1 + 0.15 * c_phrate * s_ph));\namp_target = max(0.05, 1 + c_ajit * ja_new);\ndec_target = max(0.2, c_dec * (1 + c_djit * jd_new));\n\nrate_h = trig ? rate_target : r_held;\ndec_h = trig ? dec_target : d_held;\njr_h = trig ? jr_new : jr_held;\nja_h = trig ? ja_new : ja_held;\njd_h = trig ? jd_new : jd_held;\n\n// ---- click envelope ----\ncoeff = exp(-1 / (d_held * 0.001 * samplerate));\nenv = trig ? amp_target : env_prev * coeff;\nenv_prev = env;\n\n// ---- noise + tilt ----\nlp = lp_prev + c_tilt_e * (noise() - lp_prev);\nlp_prev = lp;\n\nclick = lp * env;\n\n// ---- resonator: two-pole, hand-rolled, clamped stable ----\np1 = y1;\np2 = y2;\nw = twopi * c_res_e / samplerate;\na = 2 * q * cos(w);\nb = q * q;\ny = click * (1 - q) + a * p1 - b * p2;\ny1 = y;\ny2 = p1;\n\n// ---- layer 2 gain: breath modulates output amplitude ----\nb_gain = (1 - c_bdepth) + c_bdepth * b_curve;\n\n// ---- layer 4: breath noise, fixed-color lowpass, gated by breath envelope ----\nbn_raw = noise();\nbn_lp = bn_prev + 0.05 * (bn_raw - bn_prev);\nbn_prev = bn_lp;\nbreath_noise_out = bn_lp * c_bnoise * b_curve;\n\n// Module edits (audio archetype Phase B, 2026-11-16): gain, a tanh ceiling, and a ~5 ms slewed mute.\n// out2 (breath phase) is not gained or muted.\nbyp_s = byp_s + (bypass_gate - byp_s) * (1 - exp(-1 / (0.005 * samplerate)));\nout1 = tanh((y * b_gain + breath_noise_out) * gph * gain) * (1 - byp_s);\nout2 = b_phase;",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 11.0,
									"id": "obj-2",
									"maxclass": "codebox",
									"numinlets": 1,
									"numoutlets": 2,
									"outlettype": [
										"",
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
							},
							{
								"box": {
									"id": "obj-4",
									"maxclass": "newobj",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										200.0,
										610.0,
										40.0,
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
							},
							{
								"patchline": {
									"destination": [
										"obj-4",
										0
									],
									"source": [
										"obj-2",
										1
									]
								}
							}
						]
					}
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
					"varname": "fap_autopattr"
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
						276.0
					],
					"presentation": 1,
					"presentation_rect": [
						0.0,
						0.0,
						330.0,
						276.0
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
					"text": "f_a_purr"
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
					"hint": "Click (purr) rate, Hz",
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
								25.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "rate_hz",
							"parameter_mmax": 200.0,
							"parameter_mmin": 1.0,
							"parameter_modmode": 3,
							"parameter_exponent": 2.0,
							"parameter_shortname": "rate_hz",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "rate_hz"
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
					"text": "Rate Hz",
					"textjustification": 1,
					"varname": "lbl_rate_hz"
				}
			},
			{
				"box": {
					"id": "obj-21",
					"maxclass": "newobj",
					"text": "prepend rate_hz",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						20.0,
						110.0,
						128.0,
						22.0
					]
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
					"hint": "Per-cycle jitter of the click rate",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						110.0,
						60.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						50.0,
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
							"parameter_longname": "rate_jit",
							"parameter_mmax": 0.2,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "rate_jit",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "rate_jit"
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
					"text": "Rate Jit",
					"textjustification": 1,
					"varname": "lbl_rate_jit"
				}
			},
			{
				"box": {
					"id": "obj-24",
					"maxclass": "newobj",
					"text": "prepend rate_jit",
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
					"hint": "Per-cycle jitter of the click amplitude",
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
								0.05
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "amp_jit",
							"parameter_mmax": 0.2,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "amp_jit",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "amp_jit"
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
					"text": "Amp Jit",
					"textjustification": 1,
					"varname": "lbl_amp_jit"
				}
			},
			{
				"box": {
					"id": "obj-27",
					"maxclass": "newobj",
					"text": "prepend amp_jit",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						200.0,
						110.0,
						128.0,
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
					"hint": "Correlation time (s) of the three click jitters; 0 = independent each cycle",
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
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "jit_tau",
							"parameter_mmax": 10.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "jit_tau",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "jit_tau"
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
					"text": "Jit Tau",
					"textjustification": 1,
					"varname": "lbl_jit_tau"
				}
			},
			{
				"box": {
					"id": "obj-30",
					"maxclass": "newobj",
					"text": "prepend jit_tau",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						290.0,
						150.0,
						128.0,
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
					"hint": "Click decay time, ms",
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
								3.7
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "decay_ms",
							"parameter_mmax": 200.0,
							"parameter_mmin": 0.2,
							"parameter_modmode": 3,
							"parameter_exponent": 3.0,
							"parameter_shortname": "decay_ms",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "decay_ms"
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
					"text": "Decay ms",
					"textjustification": 1,
					"varname": "lbl_decay_ms"
				}
			},
			{
				"box": {
					"id": "obj-33",
					"maxclass": "newobj",
					"text": "prepend decay_ms",
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
					"hint": "Per-cycle jitter of the click decay",
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
								0.6
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "decay_jit",
							"parameter_mmax": 0.9,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "decay_jit",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "decay_jit"
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
					"text": "Decay Jit",
					"textjustification": 1,
					"varname": "lbl_decay_jit"
				}
			},
			{
				"box": {
					"id": "obj-36",
					"maxclass": "newobj",
					"text": "prepend decay_jit",
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
					"hint": "Click spectral tilt (low = duller)",
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
								0.5
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "tilt",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.02,
							"parameter_modmode": 3,
							"parameter_shortname": "tilt",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "tilt"
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
					"text": "Tilt",
					"textjustification": 1,
					"varname": "lbl_tilt"
				}
			},
			{
				"box": {
					"id": "obj-39",
					"maxclass": "newobj",
					"text": "prepend tilt",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						560.0,
						110.0,
						104.0,
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
					"hint": "Resonator frequency, Hz",
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
								215.5
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "res_hz",
							"parameter_mmax": 400.0,
							"parameter_mmin": 20.0,
							"parameter_modmode": 3,
							"parameter_exponent": 2.0,
							"parameter_shortname": "res_hz",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "res_hz"
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
					"text": "Res Hz",
					"textjustification": 1,
					"varname": "lbl_res_hz"
				}
			},
			{
				"box": {
					"id": "obj-42",
					"maxclass": "newobj",
					"text": "prepend res_hz",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						650.0,
						150.0,
						120.0,
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
					"hint": "Resonator pole radius (higher rings longer)",
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
								0.9919
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "res_q",
							"parameter_mmax": 0.999,
							"parameter_mmin": 0.5,
							"parameter_modmode": 3,
							"parameter_shortname": "res_q",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "res_q"
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
					"text": "Res Q",
					"textjustification": 1,
					"varname": "lbl_res_q"
				}
			},
			{
				"box": {
					"id": "obj-45",
					"maxclass": "newobj",
					"text": "prepend res_q",
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
					"hint": "Breath rate, Hz",
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
								0.32
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "breath_hz",
							"parameter_mmax": 2.0,
							"parameter_mmin": 0.05,
							"parameter_modmode": 3,
							"parameter_shortname": "breath_hz",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "breath_hz"
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
					"text": "Breath Hz",
					"textjustification": 1,
					"varname": "lbl_breath_hz"
				}
			},
			{
				"box": {
					"id": "obj-48",
					"maxclass": "newobj",
					"text": "prepend breath_hz",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						830.0,
						150.0,
						144.0,
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
					"hint": "Inhale/exhale split; negative makes inhale the longer phase",
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
								0.79
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "breath_skew",
							"parameter_mmax": 1.0,
							"parameter_mmin": -1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "breath_skew",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "breath_skew"
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
					"text": "Skew",
					"textjustification": 1,
					"varname": "lbl_breath_skew"
				}
			},
			{
				"box": {
					"id": "obj-51",
					"maxclass": "newobj",
					"text": "prepend breath_skew",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						920.0,
						110.0,
						160.0,
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
					"hint": "How far the breath modulates the level",
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
								0.3
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "breath_depth",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "breath_depth",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "breath_depth"
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
					"text": "Depth",
					"textjustification": 1,
					"varname": "lbl_breath_depth"
				}
			},
			{
				"box": {
					"id": "obj-54",
					"maxclass": "newobj",
					"text": "prepend breath_depth",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1010.0,
						150.0,
						168.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-56",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "How far the breath modulates the click rate",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						1100.0,
						60.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						234.0,
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
								0.464
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "breath_rate_mod",
							"parameter_mmax": 0.5,
							"parameter_mmin": -0.5,
							"parameter_modmode": 3,
							"parameter_shortname": "breath_rate_mod",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "breath_rate_mod"
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
					"text": "Rate Mod",
					"textjustification": 1,
					"varname": "lbl_breath_rate_mod"
				}
			},
			{
				"box": {
					"id": "obj-57",
					"maxclass": "newobj",
					"text": "prepend breath_rate_mod",
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
					"hint": "0 = one level hump per breath, 1 = two (dips at both flow reversals)",
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
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "breath_shape",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "breath_shape",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "breath_shape"
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
					"text": "Shape",
					"textjustification": 1,
					"varname": "lbl_breath_shape"
				}
			},
			{
				"box": {
					"id": "obj-60",
					"maxclass": "newobj",
					"text": "prepend breath_shape",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1190.0,
						150.0,
						168.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-62",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Per-breath rate variation (standard deviation)",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						1280.0,
						60.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						4.0,
						162.0,
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
							"parameter_longname": "breath_jit",
							"parameter_mmax": 0.3,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "breath_jit",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "breath_jit"
				}
			},
			{
				"box": {
					"id": "obj-64",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						1280.0,
						30.0,
						70.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						-7.5,
						144.0,
						50.0,
						18.0
					],
					"text": "Breath Jit",
					"textjustification": 1,
					"varname": "lbl_breath_jit"
				}
			},
			{
				"box": {
					"id": "obj-63",
					"maxclass": "newobj",
					"text": "prepend breath_jit",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1280.0,
						110.0,
						152.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-65",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Chance per breath of starting a run of 2-4 breaths at another tempo",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						1370.0,
						60.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						50.0,
						162.0,
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
							"parameter_longname": "run_prob",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "run_prob",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "run_prob"
				}
			},
			{
				"box": {
					"id": "obj-67",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						1370.0,
						30.0,
						70.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						38.5,
						144.0,
						50.0,
						18.0
					],
					"text": "Run Prob",
					"textjustification": 1,
					"varname": "lbl_run_prob"
				}
			},
			{
				"box": {
					"id": "obj-66",
					"maxclass": "newobj",
					"text": "prepend run_prob",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1370.0,
						150.0,
						136.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-68",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Size of a run's tempo change, in octaves",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						1460.0,
						60.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						96.0,
						162.0,
						27.0,
						43.0
					],
					"saved_attribute_attributes": {
						"activedialcolor": {
							"expression": ""
						},
						"valueof": {
							"parameter_initial": [
								0.6
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "run_oct",
							"parameter_mmax": 1.5,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "run_oct",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "run_oct"
				}
			},
			{
				"box": {
					"id": "obj-70",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						1460.0,
						30.0,
						70.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						84.5,
						144.0,
						50.0,
						18.0
					],
					"text": "Run Oct",
					"textjustification": 1,
					"varname": "lbl_run_oct"
				}
			},
			{
				"box": {
					"id": "obj-69",
					"maxclass": "newobj",
					"text": "prepend run_oct",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1460.0,
						110.0,
						128.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-71",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Breath noise, gated by the breath",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						1550.0,
						60.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						142.0,
						162.0,
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
							"parameter_longname": "breath_noise",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "breath_noise",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "breath_noise"
				}
			},
			{
				"box": {
					"id": "obj-73",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						1550.0,
						30.0,
						70.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						130.5,
						144.0,
						50.0,
						18.0
					],
					"text": "Noise",
					"textjustification": 1,
					"varname": "lbl_breath_noise"
				}
			},
			{
				"box": {
					"id": "obj-72",
					"maxclass": "newobj",
					"text": "prepend breath_noise",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1550.0,
						150.0,
						168.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-74",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "0 = internal breath oscillator, 1 = the external phase on the inlet",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						1640.0,
						60.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						188.0,
						162.0,
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
							"parameter_longname": "breath_src",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "breath_src",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "breath_src"
				}
			},
			{
				"box": {
					"id": "obj-76",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						1640.0,
						30.0,
						70.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						176.5,
						144.0,
						50.0,
						18.0
					],
					"text": "Src",
					"textjustification": 1,
					"varname": "lbl_breath_src"
				}
			},
			{
				"box": {
					"id": "obj-75",
					"maxclass": "newobj",
					"text": "prepend breath_src",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1640.0,
						110.0,
						152.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-77",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Crossfade time between the two breath sources, ms",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						1730.0,
						60.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						234.0,
						162.0,
						27.0,
						43.0
					],
					"saved_attribute_attributes": {
						"activedialcolor": {
							"expression": ""
						},
						"valueof": {
							"parameter_initial": [
								50.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "breath_src_ms",
							"parameter_mmax": 2000.0,
							"parameter_mmin": 1.0,
							"parameter_modmode": 3,
							"parameter_exponent": 3.0,
							"parameter_shortname": "breath_src_ms",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "breath_src_ms"
				}
			},
			{
				"box": {
					"id": "obj-79",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						1730.0,
						30.0,
						70.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						222.5,
						144.0,
						50.0,
						18.0
					],
					"text": "Src ms",
					"textjustification": 1,
					"varname": "lbl_breath_src_ms"
				}
			},
			{
				"box": {
					"id": "obj-78",
					"maxclass": "newobj",
					"text": "prepend breath_src_ms",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1730.0,
						150.0,
						176.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-80",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Inhale/exhale level balance (positive = inhale louder, +-6 dB)",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						1820.0,
						60.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						280.0,
						162.0,
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
							"parameter_longname": "ph_gain",
							"parameter_mmax": 1.0,
							"parameter_mmin": -1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "ph_gain",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "ph_gain"
				}
			},
			{
				"box": {
					"id": "obj-82",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						1820.0,
						30.0,
						70.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						268.5,
						144.0,
						50.0,
						18.0
					],
					"text": "Ph Gain",
					"textjustification": 1,
					"varname": "lbl_ph_gain"
				}
			},
			{
				"box": {
					"id": "obj-81",
					"maxclass": "newobj",
					"text": "prepend ph_gain",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1820.0,
						110.0,
						128.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-83",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Inhale/exhale brightness (positive = inhale brighter)",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						1910.0,
						60.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						4.0,
						224.0,
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
							"parameter_longname": "ph_tilt",
							"parameter_mmax": 1.0,
							"parameter_mmin": -1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "ph_tilt",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "ph_tilt"
				}
			},
			{
				"box": {
					"id": "obj-85",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						1910.0,
						30.0,
						70.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						-7.5,
						206.0,
						50.0,
						18.0
					],
					"text": "Ph Tilt",
					"textjustification": 1,
					"varname": "lbl_ph_tilt"
				}
			},
			{
				"box": {
					"id": "obj-84",
					"maxclass": "newobj",
					"text": "prepend ph_tilt",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1910.0,
						150.0,
						128.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-86",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Inhale/exhale resonator offset (+-6 semitones)",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						2000.0,
						60.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						50.0,
						224.0,
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
							"parameter_longname": "ph_res",
							"parameter_mmax": 1.0,
							"parameter_mmin": -1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "ph_res",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "ph_res"
				}
			},
			{
				"box": {
					"id": "obj-88",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						2000.0,
						30.0,
						70.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						38.5,
						206.0,
						50.0,
						18.0
					],
					"text": "Ph Res",
					"textjustification": 1,
					"varname": "lbl_ph_res"
				}
			},
			{
				"box": {
					"id": "obj-87",
					"maxclass": "newobj",
					"text": "prepend ph_res",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						2000.0,
						110.0,
						120.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-89",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Inhale/exhale click-rate offset (+-15%)",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						2090.0,
						60.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						96.0,
						224.0,
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
							"parameter_longname": "ph_rate",
							"parameter_mmax": 1.0,
							"parameter_mmin": -1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "ph_rate",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "ph_rate"
				}
			},
			{
				"box": {
					"id": "obj-91",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						2090.0,
						30.0,
						70.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						84.5,
						206.0,
						50.0,
						18.0
					],
					"text": "Ph Rate",
					"textjustification": 1,
					"varname": "lbl_ph_rate"
				}
			},
			{
				"box": {
					"id": "obj-90",
					"maxclass": "newobj",
					"text": "prepend ph_rate",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						2090.0,
						150.0,
						128.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-92",
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
						2180.0,
						60.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						142.0,
						224.0,
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
					"id": "obj-94",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						2180.0,
						30.0,
						70.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						130.5,
						206.0,
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
					"id": "obj-93",
					"maxclass": "newobj",
					"text": "prepend gain",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						2180.0,
						110.0,
						104.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-95",
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
						2270.0,
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
					"id": "obj-96",
					"maxclass": "newobj",
					"text": "prepend bypass_gate",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						2270.0,
						150.0,
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
						"obj-3",
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
						"obj-65",
						0
					],
					"destination": [
						"obj-66",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-66",
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
						"obj-68",
						0
					],
					"destination": [
						"obj-69",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-69",
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
						"obj-71",
						0
					],
					"destination": [
						"obj-72",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-72",
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
						"obj-74",
						0
					],
					"destination": [
						"obj-75",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-75",
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
						"obj-77",
						0
					],
					"destination": [
						"obj-78",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-78",
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
						"obj-80",
						0
					],
					"destination": [
						"obj-81",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-81",
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
						"obj-83",
						0
					],
					"destination": [
						"obj-84",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-84",
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
						"obj-86",
						0
					],
					"destination": [
						"obj-87",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-87",
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
						"obj-89",
						0
					],
					"destination": [
						"obj-90",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-90",
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
						"obj-92",
						0
					],
					"destination": [
						"obj-93",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-93",
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
						"obj-95",
						0
					],
					"destination": [
						"obj-96",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-96",
						0
					],
					"destination": [
						"obj-3",
						0
					]
				}
			}
		],
		"parameters": {
			"obj-20": [
				"rate_hz",
				"rate_hz",
				0
			],
			"obj-23": [
				"rate_jit",
				"rate_jit",
				0
			],
			"obj-26": [
				"amp_jit",
				"amp_jit",
				0
			],
			"obj-29": [
				"jit_tau",
				"jit_tau",
				0
			],
			"obj-32": [
				"decay_ms",
				"decay_ms",
				0
			],
			"obj-35": [
				"decay_jit",
				"decay_jit",
				0
			],
			"obj-38": [
				"tilt",
				"tilt",
				0
			],
			"obj-41": [
				"res_hz",
				"res_hz",
				0
			],
			"obj-44": [
				"res_q",
				"res_q",
				0
			],
			"obj-47": [
				"breath_hz",
				"breath_hz",
				0
			],
			"obj-50": [
				"breath_skew",
				"breath_skew",
				0
			],
			"obj-53": [
				"breath_depth",
				"breath_depth",
				0
			],
			"obj-56": [
				"breath_rate_mod",
				"breath_rate_mod",
				0
			],
			"obj-59": [
				"breath_shape",
				"breath_shape",
				0
			],
			"obj-62": [
				"breath_jit",
				"breath_jit",
				0
			],
			"obj-65": [
				"run_prob",
				"run_prob",
				0
			],
			"obj-68": [
				"run_oct",
				"run_oct",
				0
			],
			"obj-71": [
				"breath_noise",
				"breath_noise",
				0
			],
			"obj-74": [
				"breath_src",
				"breath_src",
				0
			],
			"obj-77": [
				"breath_src_ms",
				"breath_src_ms",
				0
			],
			"obj-80": [
				"ph_gain",
				"ph_gain",
				0
			],
			"obj-83": [
				"ph_tilt",
				"ph_tilt",
				0
			],
			"obj-86": [
				"ph_res",
				"ph_res",
				0
			],
			"obj-89": [
				"ph_rate",
				"ph_rate",
				0
			],
			"obj-92": [
				"gain",
				"gain",
				0
			],
			"obj-95": [
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