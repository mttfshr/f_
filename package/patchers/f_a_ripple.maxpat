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
        "rect": [ 92.0, 95.0, 1150.0, 900.0 ],
        "default_fontname": "Ableton Sans Light",
        "boxes": [
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "format": 6,
                    "id": "obj-2",
                    "maxclass": "flonum",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "bang" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 480.0, 176.0, 70.0, 23.0 ]
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "format": 6,
                    "id": "obj-1",
                    "maxclass": "flonum",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "bang" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 20.0, 70.5, 70.0, 23.0 ]
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-101",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 20.0, 10.0, 900.0, 21.0 ],
                    "text": "f_a_ripple v1 -- production-DSP prototype: automatic per-stimulus timing + AM/PM + hearing correction + safety limiter"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-102",
                    "linecount": 12,
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 821.0, 570.0, 282.0, 143.0 ],
                    "text": "New vs. T5/T6: (1) fully self-timed -- t>=stim_dur triggers a new stimulus internally via noise()-drawn f0/q/p, no external button/counter needed, self-starts via History t's 1000.0 initial value. (2) raised-cosine on/off ramps from stim_dur*ramp_pct. (3) hearing-correction staircase (ADR-5) applied per-harmonic in both the wavetable render and the modulated loop. (4) band (1-7) maps to flo_mod/fhi_mod internally (ADR-4) instead of manual Hz entry. (5) pm_turns now a real Param (was hardcoded in T6). (6) tanh() safety ceiling on the final output, after output_level -- output can never exceed +-1 regardless of profile/depth/band (ADR-6). OUTPUT DEFAULTS SILENT (output_level=0) -- raise slowly."
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-110",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 20.0, 50.0, 90.0, 18.0 ],
                    "text": "band (1-7)"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-112",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 20.0, 105.0, 81.0, 23.0 ],
                    "text": "prepend band"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-120",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 100.0, 50.0, 90.0, 18.0 ],
                    "text": "mod_type"
                }
            },
            {
                "box": {
                    "id": "obj-121",
                    "maxclass": "toggle",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "int" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 100.0, 70.0, 24.0, 24.0 ]
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-122",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 100.0, 105.0, 108.0, 23.0 ],
                    "text": "prepend mod_type"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-130",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 180.0, 50.0, 90.0, 18.0 ],
                    "text": "depth (d)"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "format": 6,
                    "id": "obj-131",
                    "maxclass": "flonum",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "bang" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 180.0, 70.0, 70.0, 23.0 ]
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-132",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 180.0, 105.0, 90.0, 23.0 ],
                    "text": "prepend depth"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-140",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 280.0, 50.0, 90.0, 18.0 ],
                    "text": "tmr (w)"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "format": 6,
                    "id": "obj-141",
                    "maxclass": "flonum",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "bang" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 280.0, 70.0, 70.0, 23.0 ]
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-142",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 280.0, 105.0, 80.0, 23.0 ],
                    "text": "prepend tmr"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-150",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 380.0, 50.0, 90.0, 18.0 ],
                    "text": "smr_mean"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "format": 6,
                    "id": "obj-151",
                    "maxclass": "flonum",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "bang" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 380.0, 70.0, 70.0, 23.0 ]
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-152",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 380.0, 105.0, 110.0, 23.0 ],
                    "text": "prepend smr_mean"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-160",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 500.0, 50.0, 90.0, 18.0 ],
                    "text": "smr_range"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "format": 6,
                    "id": "obj-161",
                    "maxclass": "flonum",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "bang" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 500.0, 70.0, 70.0, 23.0 ]
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-162",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 500.0, 105.0, 111.0, 23.0 ],
                    "text": "prepend smr_range"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-170",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 620.0, 50.0, 90.0, 18.0 ],
                    "text": "smr_cycle"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "format": 6,
                    "id": "obj-171",
                    "maxclass": "flonum",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "bang" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 620.0, 70.0, 70.0, 23.0 ]
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-172",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 620.0, 105.0, 110.0, 23.0 ],
                    "text": "prepend smr_cycle"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-180",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 740.0, 50.0, 90.0, 18.0 ],
                    "text": "pm_turns"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "format": 6,
                    "id": "obj-181",
                    "maxclass": "flonum",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "bang" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 740.0, 70.0, 70.0, 23.0 ]
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-182",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 740.0, 105.0, 105.0, 23.0 ],
                    "text": "prepend pm_turns"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-190",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 20.0, 150.0, 90.0, 18.0 ],
                    "text": "f0_lo (Hz)"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "format": 6,
                    "id": "obj-191",
                    "maxclass": "flonum",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "bang" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 20.0, 170.0, 70.0, 23.0 ]
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-192",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 20.0, 205.0, 90.0, 23.0 ],
                    "text": "prepend f0_lo"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-200",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 130.0, 150.0, 90.0, 18.0 ],
                    "text": "f0_hi (Hz)"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "format": 6,
                    "id": "obj-201",
                    "maxclass": "flonum",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "bang" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 130.0, 170.0, 70.0, 23.0 ]
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-202",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 130.0, 205.0, 90.0, 23.0 ],
                    "text": "prepend f0_hi"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-210",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 240.0, 150.0, 90.0, 18.0 ],
                    "text": "stim_dur (s)"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "format": 6,
                    "id": "obj-211",
                    "maxclass": "flonum",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "bang" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 240.0, 170.0, 70.0, 23.0 ]
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-212",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 240.0, 205.0, 101.0, 23.0 ],
                    "text": "prepend stim_dur"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-220",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 360.0, 150.0, 90.0, 18.0 ],
                    "text": "ramp_pct (%)"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "format": 6,
                    "id": "obj-221",
                    "maxclass": "flonum",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "bang" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 360.0, 170.0, 70.0, 23.0 ]
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-222",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 360.0, 205.0, 106.0, 23.0 ],
                    "text": "prepend ramp_pct"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-230",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 470.0, 150.0, 110.0, 18.0 ],
                    "text": "hearing_profile (0-3)"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-232",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 470.0, 205.0, 140.0, 23.0 ],
                    "text": "prepend hearing_profile"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-240",
                    "linecount": 2,
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 620.0, 150.0, 200.0, 29.0 ],
                    "text": "output_level -- DEFAULTS 0 (silent). Raise slowly, e.g. 0.05-0.2."
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "format": 6,
                    "id": "obj-241",
                    "maxclass": "flonum",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "bang" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 620.0, 185.0, 70.0, 23.0 ]
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-242",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 620.0, 220.0, 120.0, 23.0 ],
                    "text": "prepend output_level"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-300",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "outlettype": [ "signal", "signal", "signal" ],
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
                        "rect": [ 900.0, 300.0, 820.0, 620.0 ],
                        "boxes": [
                            {
                                "box": {
                                    "id": "obj-1",
                                    "maxclass": "newobj",
                                    "numinlets": 0,
                                    "numoutlets": 1,
                                    "outlettype": [ "" ],
                                    "patching_rect": [ 40.0, 1.0, 28.0, 22.0 ],
                                    "text": "in 1"
                                }
                            },
                            {
                                "box": {
                                    "code": "// f_a_ripple v1 -- production DSP. Self-timed: t>=stim_dur triggers a\n// new stimulus internally (noise()-drawn f0/q/p), no external button.\n// History t's initial value (1000.0) forces an immediate first render on\n// load, so this self-starts with no loadbang wiring needed for that part.\n// Hearing-correction staircase (ADR-5) applied per-harmonic in both the\n// wavetable render and the modulated loop. band (1-7) maps to\n// flo_mod/fhi_mod internally (ADR-4). pm_turns is a real Param (T6 had\n// this hardcoded). Final tanh() ceiling guarantees output in [-1,1] by\n// construction regardless of profile/depth/band (ADR-6).\n\nParam band(6);\nParam mod_type(0);\nParam depth(1.0);\nParam tmr(1.0);\nParam smr_mean(4.5);\nParam smr_range(3.0);\nParam smr_cycle(8.0);\nParam pm_turns(0.5);\nParam f0_lo(96.0);\nParam f0_hi(256.0);\nParam stim_dur(4.0);\nParam ramp_pct(25.0);\nParam hearing_profile(0);\nParam output_level(0.0);\n\nData wtab(2048);\nHistory t(1000.0);\nHistory ph_prev(0.0);\nHistory f0_h(150.0);\nHistory q_h(0.0);\nHistory p_h(0.0);\nHistory geomean_mod(1000.0);\nHistory render_count(0);\n\nflo = 1000.0;\nfhi = 16000.0;\nflo_mod = 1000.0 * pow(2.0, (band - 1.0) * 0.5);\nfhi_mod = 1000.0 * pow(2.0, (band + 1.0) * 0.5);\n\nprofile_db = (hearing_profile == 0) ? 0.0\n           : (hearing_profile == 1) ? 15.0\n           : (hearing_profile == 2) ? 30.0\n           : 45.0;\n\nif (t >= stim_dur) {\n    f0_h = f0_lo + (noise() * 0.5 + 0.5) * (f0_hi - f0_lo);\n    q_h = (noise() * 0.5 + 0.5) * twopi;\n    p_h = (noise() * 0.5 + 0.5) * twopi;\n\n    for (i = 0; i < 2048; i += 1) {\n        phase_i = i / 2048;\n        s = 0.0;\n        c = 0.0;\n        for (n = 1; n <= 200; n += 1) {\n            freq = n * f0_h;\n            inband = (freq >= flo) && (freq < fhi);\n            modband = (freq >= flo_mod) && (freq < fhi_mod);\n            unmod = inband && (modband == 0);\n            half_oct = floor(log(max(freq, 1000.0) / 1000.0) / log(2.0) / 0.5);\n            half_oct = min(max(half_oct, 0.0), 7.0);\n            stair = (half_oct < 2.0) ? 0.0\n                  : (half_oct < 3.0) ? 0.125\n                  : (half_oct < 4.0) ? 0.375\n                  : (half_oct < 5.0) ? 0.625\n                  : (half_oct < 6.0) ? 0.875\n                  : 1.0;\n            corr = pow(10.0, (stair * profile_db) / 20.0);\n            s += unmod ? sin(twopi * n * phase_i) * corr : 0.0;\n            c += unmod ? 1.0 : 0.0;\n        }\n        wnorm = 1.0 / sqrt(max(c, 1.0));\n        poke(wtab, s * wnorm, i);\n    }\n\n    sumlog = 0.0;\n    cnt2 = 0.0;\n    for (n = 1; n <= 200; n += 1) {\n        freq = n * f0_h;\n        modband = (freq >= flo_mod) && (freq < fhi_mod);\n        sumlog += modband ? log(max(freq, 1.0)) : 0.0;\n        cnt2 += modband ? 1.0 : 0.0;\n    }\n    geomean_mod = exp(sumlog / max(cnt2, 1.0));\n\n    t = 0.0;\n    render_count = render_count + 1;\n}\n\ninc = f0_h / samplerate;\nph_acc = ph_prev + inc;\nwrapped = ph_acc >= 1.0;\nph_prev = ph_acc - wrapped;\n\nidx = ph_prev * 2048;\nidx_i0 = floor(idx);\nidx_i1 = mod(idx_i0 + 1, 2048);\nidx_frac = idx - idx_i0;\ntab_v0 = peek(wtab, idx_i0, 0);\ntab_v1 = peek(wtab, idx_i1, 0);\nwtab_out = tab_v0 + idx_frac * (tab_v1 - tab_v0);\n\ns_env = smr_mean + smr_range * sin(p_h + twopi * t / smr_cycle);\npm_depth_rad = pm_turns * pi;\n\nmodsum = 0.0;\nmodcnt = 0.0;\nfor (n = 1; n <= 200; n += 1) {\n    freq = n * f0_h;\n    modband = (freq >= flo_mod) && (freq < fhi_mod);\n    fn_i = log(max(freq, 1.0) / geomean_mod) / log(2.0);\n    m_i = sin(twopi * (q_h + tmr * t + fn_i * s_env));\n    half_oct2 = floor(log(max(freq, 1000.0) / 1000.0) / log(2.0) / 0.5);\n    half_oct2 = min(max(half_oct2, 0.0), 7.0);\n    stair2 = (half_oct2 < 2.0) ? 0.0\n           : (half_oct2 < 3.0) ? 0.125\n           : (half_oct2 < 4.0) ? 0.375\n           : (half_oct2 < 5.0) ? 0.625\n           : (half_oct2 < 6.0) ? 0.875\n           : 1.0;\n    corr2 = pow(10.0, (stair2 * profile_db) / 20.0);\n    base_phase = twopi * n * ph_prev;\n    am_val = (1.0 + depth * m_i) * sin(base_phase);\n    pm_val = sin(base_phase + pm_depth_rad * (1.0 + depth * m_i));\n    contrib = (mod_type != 0) ? pm_val : am_val;\n    modsum += modband ? contrib * corr2 : 0.0;\n    modcnt += modband ? 1.0 : 0.0;\n}\nmodnorm = 1.0 / sqrt(max(modcnt, 1.0));\n\nraw = wtab_out * 0.3 + modsum * modnorm * 0.3;\n\nramp_dur = stim_dur * (ramp_pct / 100.0);\nramp_dur_safe = max(ramp_dur, 0.0001);\nrise = 0.5 * (1.0 - cos(pi * min(t / ramp_dur_safe, 1.0)));\nt_from_end = stim_dur - t;\nfall = 0.5 * (1.0 - cos(pi * min(t_from_end / ramp_dur_safe, 1.0)));\nenv = min(rise, fall);\nenv = min(max(env, 0.0), 1.0);\n\nt = t + 1.0 / samplerate;\n\nout1 = tanh(raw * env * output_level);\nout2 = render_count;\nout3 = f0_h;",
                                    "fontface": 0,
                                    "fontname": "<Monospaced>",
                                    "fontsize": 11.0,
                                    "id": "obj-2",
                                    "maxclass": "codebox",
                                    "numinlets": 1,
                                    "numoutlets": 3,
                                    "outlettype": [ "", "", "" ],
                                    "patching_rect": [ 40.0, 40.0, 760.0, 560.0 ]
                                }
                            },
                            {
                                "box": {
                                    "id": "obj-3",
                                    "maxclass": "newobj",
                                    "numinlets": 1,
                                    "numoutlets": 0,
                                    "patching_rect": [ 40.0, 610.0, 40.0, 22.0 ],
                                    "text": "out 1"
                                }
                            },
                            {
                                "box": {
                                    "id": "obj-4",
                                    "maxclass": "newobj",
                                    "numinlets": 1,
                                    "numoutlets": 0,
                                    "patching_rect": [ 200.0, 610.0, 40.0, 22.0 ],
                                    "text": "out 2"
                                }
                            },
                            {
                                "box": {
                                    "id": "obj-5",
                                    "maxclass": "newobj",
                                    "numinlets": 1,
                                    "numoutlets": 0,
                                    "patching_rect": [ 360.0, 610.0, 40.0, 22.0 ],
                                    "text": "out 3"
                                }
                            }
                        ],
                        "lines": [
                            {
                                "patchline": {
                                    "destination": [ "obj-2", 0 ],
                                    "source": [ "obj-1", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "obj-3", 0 ],
                                    "source": [ "obj-2", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "obj-4", 0 ],
                                    "source": [ "obj-2", 1 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "obj-5", 0 ],
                                    "source": [ "obj-2", 2 ]
                                }
                            }
                        ]
                    },
                    "patching_rect": [ 20.0, 260.0, 900.0, 23.0 ],
                    "text": "gen~",
                    "varname": "gen~_AA"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-310",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 20.0, 300.0, 260.0, 18.0 ],
                    "text": "audio out (waveform)"
                }
            },
            {
                "box": {
                    "id": "obj-311",
                    "maxclass": "scope~",
                    "numinlets": 2,
                    "numoutlets": 0,
                    "patching_rect": [ 24.0, 321.5, 260.0, 130.0 ]
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-320",
                    "linecount": 2,
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 300.0, 300.0, 240.0, 29.0 ],
                    "text": "spectrogram -- Inspector: Sonogram mode, FFT >= 2048"
                }
            },
            {
                "box": {
                    "id": "obj-321",
                    "maxclass": "spectroscope~",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 300.0, 335.0, 300.0, 130.0 ]
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-330",
                    "linecount": 2,
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 620.0, 300.0, 260.0, 29.0 ],
                    "text": "render_count / current f0_h -- confirms auto-retrigger is happening"
                }
            },
            {
                "box": {
                    "id": "obj-331",
                    "maxclass": "toggle",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "int" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 620.0, 340.0, 24.0, 24.0 ]
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-332",
                    "maxclass": "newobj",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "bang" ],
                    "patching_rect": [ 660.0, 340.0, 63.0, 23.0 ],
                    "text": "metro 200"
                }
            },
            {
                "box": {
                    "id": "obj-333",
                    "maxclass": "newobj",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "float" ],
                    "patching_rect": [ 620.0, 375.0, 70.0, 23.0 ],
                    "text": "snapshot~"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "format": 6,
                    "id": "obj-334",
                    "maxclass": "flonum",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "bang" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 620.0, 410.0, 90.0, 23.0 ]
                }
            },
            {
                "box": {
                    "id": "obj-335",
                    "maxclass": "newobj",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "float" ],
                    "patching_rect": [ 720.0, 375.0, 70.0, 23.0 ],
                    "text": "snapshot~"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "format": 6,
                    "id": "obj-336",
                    "maxclass": "flonum",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "bang" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 720.0, 410.0, 90.0, 23.0 ]
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-337",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 620.0, 435.0, 90.0, 18.0 ],
                    "text": "render_count"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-338",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 720.0, 435.0, 90.0, 18.0 ],
                    "text": "f0_h (Hz)"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-344",
                    "maxclass": "newobj",
                    "numinlets": 2,
                    "numoutlets": 0,
                    "patching_rect": [ 60.0, 485.0, 70.0, 23.0 ],
                    "text": "dac~ 1 2"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-399",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 20.0, 520.0, 400.0, 18.0 ],
                    "text": "loadbang -- populates the controls above with sane defaults"
                }
            },
            {
                "box": {
                    "id": "obj-400",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "bang" ],
                    "patching_rect": [ 41.0, 534.0, 60.0, 23.0 ],
                    "text": "loadbang"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-401",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 20.0, 575.0, 30.0, 23.0 ],
                    "text": "6"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-402",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 100.0, 575.0, 30.0, 23.0 ],
                    "text": "0"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-403",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 180.0, 575.0, 30.0, 23.0 ],
                    "text": "1."
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-404",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 280.0, 575.0, 30.0, 23.0 ],
                    "text": "1."
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-405",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 380.0, 575.0, 40.0, 23.0 ],
                    "text": "4.5"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-406",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 500.0, 575.0, 30.0, 23.0 ],
                    "text": "3."
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-407",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 620.0, 575.0, 30.0, 23.0 ],
                    "text": "8."
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-408",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 740.0, 575.0, 40.0, 23.0 ],
                    "text": "0.5"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-409",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 20.0, 610.0, 40.0, 23.0 ],
                    "text": "96."
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-410",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 130.0, 610.0, 40.0, 23.0 ],
                    "text": "256."
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-411",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 240.0, 610.0, 30.0, 23.0 ],
                    "text": "4."
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-412",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 360.0, 610.0, 30.0, 23.0 ],
                    "text": "25."
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-413",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 470.0, 610.0, 30.0, 23.0 ],
                    "text": "0"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-414",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 620.0, 610.0, 30.0, 23.0 ],
                    "text": "0."
                }
            }
        ],
        "lines": [
            {
                "patchline": {
                    "destination": [ "obj-112", 0 ],
                    "source": [ "obj-1", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-300", 0 ],
                    "source": [ "obj-112", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-122", 0 ],
                    "source": [ "obj-121", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-300", 0 ],
                    "source": [ "obj-122", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-132", 0 ],
                    "source": [ "obj-131", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-300", 0 ],
                    "source": [ "obj-132", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-142", 0 ],
                    "source": [ "obj-141", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-300", 0 ],
                    "source": [ "obj-142", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-152", 0 ],
                    "source": [ "obj-151", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-300", 0 ],
                    "source": [ "obj-152", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-162", 0 ],
                    "source": [ "obj-161", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-300", 0 ],
                    "source": [ "obj-162", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-172", 0 ],
                    "source": [ "obj-171", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-300", 0 ],
                    "source": [ "obj-172", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-182", 0 ],
                    "source": [ "obj-181", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-300", 0 ],
                    "source": [ "obj-182", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-192", 0 ],
                    "source": [ "obj-191", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-300", 0 ],
                    "source": [ "obj-192", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-232", 0 ],
                    "source": [ "obj-2", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-202", 0 ],
                    "source": [ "obj-201", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-300", 0 ],
                    "source": [ "obj-202", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-212", 0 ],
                    "source": [ "obj-211", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-300", 0 ],
                    "source": [ "obj-212", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-222", 0 ],
                    "source": [ "obj-221", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-300", 0 ],
                    "source": [ "obj-222", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-300", 0 ],
                    "source": [ "obj-232", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-242", 0 ],
                    "source": [ "obj-241", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-300", 0 ],
                    "source": [ "obj-242", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-311", 0 ],
                    "order": 3,
                    "source": [ "obj-300", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-321", 0 ],
                    "order": 0,
                    "source": [ "obj-300", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-333", 0 ],
                    "source": [ "obj-300", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-335", 0 ],
                    "source": [ "obj-300", 2 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-344", 1 ],
                    "order": 1,
                    "source": [ "obj-300", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-344", 0 ],
                    "order": 2,
                    "source": [ "obj-300", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-332", 0 ],
                    "source": [ "obj-331", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-333", 0 ],
                    "order": 1,
                    "source": [ "obj-332", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-335", 0 ],
                    "order": 0,
                    "source": [ "obj-332", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-334", 0 ],
                    "source": [ "obj-333", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-336", 0 ],
                    "source": [ "obj-335", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-401", 0 ],
                    "order": 13,
                    "source": [ "obj-400", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-402", 0 ],
                    "order": 11,
                    "source": [ "obj-400", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-403", 0 ],
                    "order": 9,
                    "source": [ "obj-400", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-404", 0 ],
                    "order": 7,
                    "source": [ "obj-400", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-405", 0 ],
                    "order": 5,
                    "source": [ "obj-400", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-406", 0 ],
                    "order": 3,
                    "source": [ "obj-400", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-407", 0 ],
                    "order": 2,
                    "source": [ "obj-400", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-408", 0 ],
                    "order": 0,
                    "source": [ "obj-400", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-409", 0 ],
                    "order": 12,
                    "source": [ "obj-400", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-410", 0 ],
                    "order": 10,
                    "source": [ "obj-400", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-411", 0 ],
                    "order": 8,
                    "source": [ "obj-400", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-412", 0 ],
                    "order": 6,
                    "source": [ "obj-400", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-413", 0 ],
                    "order": 4,
                    "source": [ "obj-400", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-414", 0 ],
                    "order": 1,
                    "source": [ "obj-400", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-1", 0 ],
                    "source": [ "obj-401", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-121", 0 ],
                    "source": [ "obj-402", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-131", 0 ],
                    "source": [ "obj-403", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-141", 0 ],
                    "source": [ "obj-404", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-151", 0 ],
                    "source": [ "obj-405", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-161", 0 ],
                    "source": [ "obj-406", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-171", 0 ],
                    "source": [ "obj-407", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-181", 0 ],
                    "source": [ "obj-408", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-191", 0 ],
                    "source": [ "obj-409", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-201", 0 ],
                    "source": [ "obj-410", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-211", 0 ],
                    "source": [ "obj-411", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-221", 0 ],
                    "source": [ "obj-412", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-2", 0 ],
                    "source": [ "obj-413", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-241", 0 ],
                    "source": [ "obj-414", 0 ]
                }
            }
        ],
        "autosave": 0
    }
}