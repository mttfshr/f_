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
        "rect": [ 553.0, 95.0, 715.0, 893.0 ],
        "openinpresentation": 1,
        "boxes": [
            {
                "box": {
                    "filename": "bypass_toggle.js",
                    "hint": "Bypass",
                    "id": "obj-17",
                    "maxclass": "jsui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "param_connect": "grain_pix::bypass",
                    "parameter_enable": 1,
                    "patching_rect": [ 164.4375, 108.0, 18.0, 12.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 208.00000309944153, 5.600000083446503, 18.0, 12.0 ],
                    "saved_attribute_attributes": {
                        "valueof": {
                            "parameter_invisible": 1,
                            "parameter_longname": "bypass",
                            "parameter_mmax": 1.0,
                            "parameter_modmode": 4,
                            "parameter_shortname": "bypass",
                            "parameter_type": 1,
                            "parameter_unitstyle": 0
                        }
                    },
                    "valuepopuplabel": 1,
                    "varname": "bypass"
                }
            },
            {
                "box": {
                    "angle": 270.0,
                    "bgcolor": [ 0.158640689195807, 0.158640642399981, 0.158640654628478, 0.0 ],
                    "border": 1,
                    "bordercolor": [ 0.16862745098039217, 0.20392156862745098, 0.25882352941176473, 1.0 ],
                    "id": "obj-46",
                    "maxclass": "panel",
                    "mode": 0,
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 88.9375, 312.0, 128.0, 128.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 183.0, 97.0, 45.5, 69.0 ],
                    "proportion": 0.5,
                    "rounded": 4
                }
            },
            {
                "box": {
                    "angle": 270.0,
                    "bgcolor": [ 0.158640689195807, 0.158640642399981, 0.158640654628478, 0.0 ],
                    "border": 1,
                    "bordercolor": [ 0.24313725490196078, 0.29411764705882354, 0.3764705882352941, 1.0 ],
                    "id": "obj-45",
                    "maxclass": "panel",
                    "mode": 0,
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 372.0, 291.0, 128.0, 128.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 4.0, 97.0, 109.0, 69.0 ],
                    "proportion": 0.5,
                    "rounded": 4
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "id": "obj-43",
                    "maxclass": "live.numbox",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "grain_pix::field",
                    "parameter_enable": 1,
                    "patching_rect": [ 615.0, 445.0, 44.0, 15.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 114.0, 82.0, 31.0, 15.0 ],
                    "saved_attribute_attributes": {
                        "valueof": {
                            "parameter_longname": "field",
                            "parameter_mmax": 5.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "field",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "varname": "field_1"
                }
            },
            {
                "box": {
                    "id": "obj-42",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 178.5, 769.0, 152.0, 22.0 ],
                    "text": "prepend param ch_diverge",
                    "varname": "param[11]"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "Temporal persistence (0=boil 1=frozen)",
                    "id": "obj-40",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "grain_pix::ch_diverge",
                    "parameter_enable": 1,
                    "patching_rect": [ 145.5, 753.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 43.0, 115.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "ch_diverge",
                            "parameter_mmax": 1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "ch_diverge",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "ch_diverge"
                }
            },
            {
                "box": {
                    "id": "obj-4",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 176.5, 365.0, 117.0, 22.0 ],
                    "text": "prepend param fade",
                    "varname": "param[10]"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "Temporal persistence (0=boil 1=frozen)",
                    "id": "obj-2",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "grain_pix::fade",
                    "parameter_enable": 1,
                    "patching_rect": [ 132.0, 348.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 152.0, 38.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "fade",
                            "parameter_mmax": 4.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "fade",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "fade"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-3",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 15.0, 457.0, 30.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 153.0, 23.0, 30.0, 18.0 ],
                    "text": "Fade"
                }
            },
            {
                "box": {
                    "id": "obj-1",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 4,
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture", "jit_gl_texture", "" ],
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
                        "rect": [ 1074.0, 116.0, 620.0, 720.0 ],
                        "boxes": [
                            {
                                "box": {
                                    "id": "gen-obj-1",
                                    "maxclass": "newobj",
                                    "numinlets": 0,
                                    "numoutlets": 1,
                                    "outlettype": [ "" ],
                                    "patching_rect": [ 22.0, 40.0, 28.0, 22.0 ],
                                    "text": "in 1"
                                }
                            },
                            {
                                "box": {
                                    "code": "Param density(0.5);\nParam amount(0.5);\nParam era_clock(0.0);\nParam bypass(0.0);\nParam size(0.0);\nParam size_var(0.0);\nParam shape(0.5);\nParam softness(0.0);\nParam jitter(0.0);\r\nParam fade(0.0);\nParam ch_diverge(0.0);\r\nParam luma_gate(0.0);\nParam displace(0.0);\nParam edge_mode(2.0);\nParam field(0.0);\nParam sv_seed(0.0);\n\nuv = norm;\nsrc = sample(in1, uv);\n\n// cell identities pinned to fixed_res — never change regardless of size\nfixed_res = 4096.0;\n// size controls viewport zoom into the fixed grid\nsize_scale = pow(2.0, mix(0.0, 12.0, size));\naspect = dim.x / dim.y;\naspect_sq = aspect * aspect;\n\n// pixel position in grid space\npx = uv.x * fixed_res * aspect / size_scale;\npy = uv.y * fixed_res / size_scale;\nicx = floor(px);\nicy = floor(py);\n\n// VORONOI JITTER: single field param navigates topology space smoothly via 1D interpolation\nf0 = floor(field); f1 = f0 + 1.0; bf = fract(field);\n\nncx = icx-1.0; ncy = icy-1.0;\njxA = mix(fract(sin((ncx+f0)*17543.2+(ncy+f0)*8976.5)*43758.5453)-0.5, fract(sin((ncx+f1)*17543.2+(ncy+f1)*8976.5)*43758.5453)-0.5, bf);\njyA = mix(fract(sin((ncx+f0)*5432.1+(ncy+f0)*13579.8)*43758.5453)-0.5, fract(sin((ncx+f1)*5432.1+(ncy+f1)*13579.8)*43758.5453)-0.5, bf);\ndxA = px-(ncx+0.5+jxA*jitter); dyA = py-(ncy+0.5+jyA*jitter);\ndA = dxA*dxA+dyA*dyA; gxA = (ncx+0.5)/fixed_res; gyA = (ncy+0.5)/fixed_res;\n\nncx = icx; ncy = icy-1.0;\njxB = mix(fract(sin((ncx+f0)*17543.2+(ncy+f0)*8976.5)*43758.5453)-0.5, fract(sin((ncx+f1)*17543.2+(ncy+f1)*8976.5)*43758.5453)-0.5, bf);\njyB = mix(fract(sin((ncx+f0)*5432.1+(ncy+f0)*13579.8)*43758.5453)-0.5, fract(sin((ncx+f1)*5432.1+(ncy+f1)*13579.8)*43758.5453)-0.5, bf);\ndxB = px-(ncx+0.5+jxB*jitter); dyB = py-(ncy+0.5+jyB*jitter);\ndB = dxB*dxB+dyB*dyB; gxB = (ncx+0.5)/fixed_res; gyB = (ncy+0.5)/fixed_res;\n\nncx = icx+1.0; ncy = icy-1.0;\njxC = mix(fract(sin((ncx+f0)*17543.2+(ncy+f0)*8976.5)*43758.5453)-0.5, fract(sin((ncx+f1)*17543.2+(ncy+f1)*8976.5)*43758.5453)-0.5, bf);\njyC = mix(fract(sin((ncx+f0)*5432.1+(ncy+f0)*13579.8)*43758.5453)-0.5, fract(sin((ncx+f1)*5432.1+(ncy+f1)*13579.8)*43758.5453)-0.5, bf);\ndxC = px-(ncx+0.5+jxC*jitter); dyC = py-(ncy+0.5+jyC*jitter);\ndC = dxC*dxC+dyC*dyC; gxC = (ncx+0.5)/fixed_res; gyC = (ncy+0.5)/fixed_res;\n\nncx = icx-1.0; ncy = icy;\njxD = mix(fract(sin((ncx+f0)*17543.2+(ncy+f0)*8976.5)*43758.5453)-0.5, fract(sin((ncx+f1)*17543.2+(ncy+f1)*8976.5)*43758.5453)-0.5, bf);\njyD = mix(fract(sin((ncx+f0)*5432.1+(ncy+f0)*13579.8)*43758.5453)-0.5, fract(sin((ncx+f1)*5432.1+(ncy+f1)*13579.8)*43758.5453)-0.5, bf);\ndxD = px-(ncx+0.5+jxD*jitter); dyD = py-(ncy+0.5+jyD*jitter);\ndD = dxD*dxD+dyD*dyD; gxD = (ncx+0.5)/fixed_res; gyD = (ncy+0.5)/fixed_res;\n\nncx = icx; ncy = icy;\njxE = mix(fract(sin((ncx+f0)*17543.2+(ncy+f0)*8976.5)*43758.5453)-0.5, fract(sin((ncx+f1)*17543.2+(ncy+f1)*8976.5)*43758.5453)-0.5, bf);\njyE = mix(fract(sin((ncx+f0)*5432.1+(ncy+f0)*13579.8)*43758.5453)-0.5, fract(sin((ncx+f1)*5432.1+(ncy+f1)*13579.8)*43758.5453)-0.5, bf);\ndxE = px-(ncx+0.5+jxE*jitter); dyE = py-(ncy+0.5+jyE*jitter);\ndE = dxE*dxE+dyE*dyE; gxE = (ncx+0.5)/fixed_res; gyE = (ncy+0.5)/fixed_res;\n\nncx = icx+1.0; ncy = icy;\njxF = mix(fract(sin((ncx+f0)*17543.2+(ncy+f0)*8976.5)*43758.5453)-0.5, fract(sin((ncx+f1)*17543.2+(ncy+f1)*8976.5)*43758.5453)-0.5, bf);\njyF = mix(fract(sin((ncx+f0)*5432.1+(ncy+f0)*13579.8)*43758.5453)-0.5, fract(sin((ncx+f1)*5432.1+(ncy+f1)*13579.8)*43758.5453)-0.5, bf);\ndxF = px-(ncx+0.5+jxF*jitter); dyF = py-(ncy+0.5+jyF*jitter);\ndF = dxF*dxF+dyF*dyF; gxF = (ncx+0.5)/fixed_res; gyF = (ncy+0.5)/fixed_res;\n\nncx = icx-1.0; ncy = icy+1.0;\njxG = mix(fract(sin((ncx+f0)*17543.2+(ncy+f0)*8976.5)*43758.5453)-0.5, fract(sin((ncx+f1)*17543.2+(ncy+f1)*8976.5)*43758.5453)-0.5, bf);\njyG = mix(fract(sin((ncx+f0)*5432.1+(ncy+f0)*13579.8)*43758.5453)-0.5, fract(sin((ncx+f1)*5432.1+(ncy+f1)*13579.8)*43758.5453)-0.5, bf);\ndxG = px-(ncx+0.5+jxG*jitter); dyG = py-(ncy+0.5+jyG*jitter);\ndG = dxG*dxG+dyG*dyG; gxG = (ncx+0.5)/fixed_res; gyG = (ncy+0.5)/fixed_res;\n\nncx = icx; ncy = icy+1.0;\njxH = mix(fract(sin((ncx+f0)*17543.2+(ncy+f0)*8976.5)*43758.5453)-0.5, fract(sin((ncx+f1)*17543.2+(ncy+f1)*8976.5)*43758.5453)-0.5, bf);\njyH = mix(fract(sin((ncx+f0)*5432.1+(ncy+f0)*13579.8)*43758.5453)-0.5, fract(sin((ncx+f1)*5432.1+(ncy+f1)*13579.8)*43758.5453)-0.5, bf);\ndxH = px-(ncx+0.5+jxH*jitter); dyH = py-(ncy+0.5+jyH*jitter);\ndH = dxH*dxH+dyH*dyH; gxH = (ncx+0.5)/fixed_res; gyH = (ncy+0.5)/fixed_res;\n\nncx = icx+1.0; ncy = icy+1.0;\njxI = mix(fract(sin((ncx+f0)*17543.2+(ncy+f0)*8976.5)*43758.5453)-0.5, fract(sin((ncx+f1)*17543.2+(ncy+f1)*8976.5)*43758.5453)-0.5, bf);\njyI = mix(fract(sin((ncx+f0)*5432.1+(ncy+f0)*13579.8)*43758.5453)-0.5, fract(sin((ncx+f1)*5432.1+(ncy+f1)*13579.8)*43758.5453)-0.5, bf);\ndxI = px-(ncx+0.5+jxI*jitter); dyI = py-(ncy+0.5+jyI*jitter);\ndI = dxI*dxI+dyI*dyI; gxI = (ncx+0.5)/fixed_res; gyI = (ncy+0.5)/fixed_res;\n\n// find nearest and second-nearest center\nbest_d = dA; second_best_d = 9999.0; best_gx = gxA; best_gy = gyA;\nt = step(dB,best_d); second_best_d=mix(min(second_best_d,dB),best_d,t); best_d=mix(best_d,dB,t); best_gx=mix(best_gx,gxB,t); best_gy=mix(best_gy,gyB,t);\nt = step(dC,best_d); second_best_d=mix(min(second_best_d,dC),best_d,t); best_d=mix(best_d,dC,t); best_gx=mix(best_gx,gxC,t); best_gy=mix(best_gy,gyC,t);\nt = step(dD,best_d); second_best_d=mix(min(second_best_d,dD),best_d,t); best_d=mix(best_d,dD,t); best_gx=mix(best_gx,gxD,t); best_gy=mix(best_gy,gyD,t);\nt = step(dE,best_d); second_best_d=mix(min(second_best_d,dE),best_d,t); best_d=mix(best_d,dE,t); best_gx=mix(best_gx,gxE,t); best_gy=mix(best_gy,gyE,t);\nt = step(dF,best_d); second_best_d=mix(min(second_best_d,dF),best_d,t); best_d=mix(best_d,dF,t); best_gx=mix(best_gx,gxF,t); best_gy=mix(best_gy,gyF,t);\nt = step(dG,best_d); second_best_d=mix(min(second_best_d,dG),best_d,t); best_d=mix(best_d,dG,t); best_gx=mix(best_gx,gxG,t); best_gy=mix(best_gy,gyG,t);\nt = step(dH,best_d); second_best_d=mix(min(second_best_d,dH),best_d,t); best_d=mix(best_d,dH,t); best_gx=mix(best_gx,gxH,t); best_gy=mix(best_gy,gyH,t);\nt = step(dI,best_d); second_best_d=mix(min(second_best_d,dI),best_d,t); best_d=mix(best_d,dI,t); best_gx=mix(best_gx,gxI,t); best_gy=mix(best_gy,gyI,t);\n\n// distances to nearest and second-nearest centers\nnearest_dist = sqrt(best_d);\nsecond_nearest_dist = sqrt(second_best_d);\n\n// per-grain displacement: each cell gets a unique random XY offset\ndisp_x = (fract(sin(best_gx * 127.1 + best_gy * 311.7) * 43758.5453) - 0.5) * displace;\ndisp_y = (fract(sin(best_gx * 269.5 + best_gy * 183.3) * 43758.5453) - 0.5) * displace;\nuv_d_raw_x = uv.x + disp_x;\nuv_d_raw_y = uv.y + disp_y;\nin_bounds = step(0.0, uv_d_raw_x) * step(uv_d_raw_x, 1.0) * step(0.0, uv_d_raw_y) * step(uv_d_raw_y, 1.0);\nuv_d = uv;\ndisp_mask = 1.0;\nif (edge_mode < 0.5) {\n    uv_d = vec(clamp(uv_d_raw_x, 0.0, 1.0), clamp(uv_d_raw_y, 0.0, 1.0));\n    disp_mask = in_bounds;\n} else if (edge_mode < 1.5) {\n    uv_d = vec(clamp(uv_d_raw_x, 0.0, 1.0), clamp(uv_d_raw_y, 0.0, 1.0));\n} else if (edge_mode < 2.5) {\n    uv_d = vec(fract(uv_d_raw_x), fract(uv_d_raw_y));\n} else {\n    uv_d = vec(1.0 - abs(fract(uv_d_raw_x * 0.5) * 2.0 - 1.0), 1.0 - abs(fract(uv_d_raw_y * 0.5) * 2.0 - 1.0));\n}\n\n// grain identity from winning Voronoi center\np1 = fract(sin(best_gx * 127.1 + best_gy * 311.7) * 43758.5453);\np2 = fract(sin(p1 * 263.77) * 43758.5453);\nera_raw = era_clock + p2;\nera = floor(era_raw);\nera_phase = fract(era_raw);\n\n// grain value — stable per era, intensity envelope handles temporal evolution\ngrain_a = fract(sin(era * 127.1 + p1 * 311.7) * 43758.5453);\ngrain_mono = grain_a;\n\n// per-channel color offset — stable per cell, not per era\ncol_g = fract(sin(best_gx * 91.3 + best_gy * 57.2) * 43758.5453) - 0.5;\ncol_b = fract(sin(best_gx * 43.1 + best_gy * 123.7) * 43758.5453) - 0.5;\n\n// blend monochrome grain toward chromatically diverged grain\ngrain_r = grain_mono;\ngrain_g = grain_mono + col_g * ch_diverge;\ngrain_b = grain_mono + col_b * ch_diverge;\n\n// polarity: era-based, stable per era\nsign_a = fract(sin(era * 263.7 + p1 * 419.2) * 43758.5453) * 2.0 - 1.0;\ngrain_sign = sign_a;\n\n// fade envelope: intensity ramps in at era start, holds, ramps out at era end\nramp = min(fade * 0.125, 0.5);\nsafe_ramp = max(ramp, 0.001);\nfade_in = smoothstep(0.0, safe_ramp, era_phase);\nfade_out = 1.0 - smoothstep(1.0 - safe_ramp, 1.0, era_phase);\ngrain_intensity = min(fade_in, fade_out);\n\n// shape: blend between circular (shape=1) and Voronoi-conforming (shape=0)\nvoronoi_boundary_dist = (nearest_dist + second_nearest_dist) * 0.5;\nt_circ = nearest_dist / 0.5;\nt_voro = nearest_dist / max(voronoi_boundary_dist, 0.001);\nshape_t = mix(t_voro, t_circ, shape);\n\n// per-cell size variation with smooth seed interpolation\nsv0 = floor(sv_seed); sv1 = sv0 + 1.0; svf = fract(sv_seed);\ncell_size_a = fract(sin((best_gx + sv0) * 213.7 + (best_gy + sv0) * 157.3) * 43758.5453);\ncell_size_b = fract(sin((best_gx + sv1) * 213.7 + (best_gy + sv1) * 157.3) * 43758.5453);\ncell_size = mix(1.0, mix(cell_size_a, cell_size_b, svf), size_var);\nshape_t = shape_t / max(cell_size, 0.001);\n\n// softness: feathered falloff in shape-blended coordinate\nfeather = mix(0.02, 0.5, softness);\nsoft_falloff = 1.0 - smoothstep(1.0 - feather, 1.0, shape_t);\n\n// density gate\nvisible = step(1.0 - density, grain_r);\n\n// displacement gated to grain shape only\nsrc_displaced = mix(src, sample(in1, uv_d), visible * soft_falloff * grain_intensity * disp_mask);\n\n// apply grain_sign (stable polarity per cell) scaled by ch_diverge for color\ngr = grain_sign * visible * soft_falloff * grain_intensity * amount;\ngg = (grain_sign + col_g * ch_diverge) * visible * soft_falloff * grain_intensity * amount;\ngb = (grain_sign + col_b * ch_diverge) * visible * soft_falloff * grain_intensity * amount;\n\n// luma gate: bipolar (-1=shadows +1=highlights 0=uniform)\nluma = 0.299*src.r + 0.587*src.g + 0.114*src.b;\nluma_weight = mix(1.0 - luma, luma, luma_gate * 0.5 + 0.5);\nluma_weight = pow(luma_weight, mix(1.0, 3.0, abs(luma_gate)));\nluma_mod = mix(1.0, luma_weight, clamp(abs(luma_gate) * 2.0, 0.0, 1.0));\ngr *= luma_mod;\ngg *= luma_mod;\ngb *= luma_mod;\ncomposited = vec(src_displaced.r + gr, src_displaced.g + gg, src_displaced.b + gb, src_displaced.a);\nraw = vec(grain_sign * visible * soft_falloff * grain_intensity, grain_sign * visible * soft_falloff * grain_intensity, grain_sign * visible * soft_falloff * grain_intensity, 1.0);\n\n// bypass\neffective_bp = 1.0 - bypass;\nout1 = mix(src, composited, effective_bp);\nout2 = raw;\nout3 = mix(src, src_displaced, effective_bp);",
                                    "fontface": 0,
                                    "fontname": "<Monospaced>",
                                    "fontsize": 12.0,
                                    "id": "gen-obj-2",
                                    "maxclass": "codebox",
                                    "numinlets": 1,
                                    "numoutlets": 3,
                                    "outlettype": [ "", "", "" ],
                                    "patching_rect": [ 22.0, 100.0, 560.0, 520.0 ]
                                }
                            },
                            {
                                "box": {
                                    "id": "gen-obj-3",
                                    "maxclass": "newobj",
                                    "numinlets": 1,
                                    "numoutlets": 0,
                                    "patching_rect": [ 22.0, 650.0, 35.0, 22.0 ],
                                    "text": "out 1"
                                }
                            },
                            {
                                "box": {
                                    "id": "gen-obj-4",
                                    "maxclass": "newobj",
                                    "numinlets": 1,
                                    "numoutlets": 0,
                                    "patching_rect": [ 100.0, 650.0, 35.0, 22.0 ],
                                    "text": "out 2"
                                }
                            },
                            {
                                "box": {
                                    "id": "gen-obj-5",
                                    "maxclass": "newobj",
                                    "numinlets": 1,
                                    "numoutlets": 0,
                                    "patching_rect": [ 180.0, 650.0, 35.0, 22.0 ],
                                    "text": "out 3"
                                }
                            }
                        ],
                        "lines": [
                            {
                                "patchline": {
                                    "destination": [ "gen-obj-2", 0 ],
                                    "source": [ "gen-obj-1", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "gen-obj-3", 0 ],
                                    "source": [ "gen-obj-2", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "gen-obj-4", 0 ],
                                    "source": [ "gen-obj-2", 1 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "gen-obj-5", 0 ],
                                    "source": [ "gen-obj-2", 2 ]
                                }
                            }
                        ]
                    },
                    "patching_rect": [ 578.5, 670.0, 184.0, 22.0 ],
                    "text": "jit.gl.pix vsynth @name grain_pix",
                    "varname": "grain_pix"
                }
            },
            {
                "box": {
                    "id": "obj-86",
                    "maxclass": "newobj",
                    "numinlets": 17,
                    "numoutlets": 17,
                    "outlettype": [ "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "" ],
                    "patching_rect": [ 164.4375, 64.0, 902.0, 22.0 ],
                    "text": "route bypass density amount persistence fade size size_var shape softness jitter ch_diverge luma_gate displace edge_mode_menu field sv_seed"
                }
            },
            {
                "box": {
                    "comment": "",
                    "id": "obj-5",
                    "index": 0,
                    "maxclass": "inlet",
                    "numinlets": 0,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 186.9375, 17.0, 30.0, 30.0 ]
                }
            },
            {
                "box": {
                    "id": "obj-84",
                    "maxclass": "newobj",
                    "numinlets": 3,
                    "numoutlets": 3,
                    "outlettype": [ "", "", "" ],
                    "patching_rect": [ 923.0, 334.0, 215.0, 22.0 ],
                    "text": "routepass jit_gl_texture jit_matrix"
                }
            },
            {
                "box": {
                    "id": "obj-85",
                    "maxclass": "newobj",
                    "numinlets": 3,
                    "numoutlets": 3,
                    "outlettype": [ "", "", "" ],
                    "patching_rect": [ 610.5, 401.0, 120.0, 22.0 ],
                    "text": "route field sv_seed"
                }
            },
            {
                "box": {
                    "comment": "",
                    "id": "obj-6",
                    "index": 0,
                    "maxclass": "outlet",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 560.0, 773.0, 30.0, 30.0 ],
                    "tricolor": [ 0.9529411764705882, 0.6901960784313725, 0.6196078431372549, 1.0 ]
                }
            },
            {
                "box": {
                    "comment": "",
                    "hint": "Raw",
                    "id": "obj-7",
                    "index": 0,
                    "maxclass": "outlet",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 650.0, 795.0, 30.0, 30.0 ],
                    "tricolor": [ 0.6196078431372549, 0.9529411764705882, 0.6588235294117647, 1.0 ]
                }
            },
            {
                "box": {
                    "comment": "",
                    "id": "obj-70",
                    "index": 0,
                    "maxclass": "outlet",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 732.5, 773.0, 30.0, 30.0 ],
                    "tricolor": [ 0.9490196078431372, 0.6196078431372549, 0.9529411764705882, 1.0 ]
                }
            },
            {
                "box": {
                    "id": "obj-8",
                    "maxclass": "newobj",
                    "numinlets": 0,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 516.0, 103.0, 50.0, 22.0 ],
                    "text": "r draw"
                }
            },
            {
                "box": {
                    "id": "obj-9",
                    "maxclass": "newobj",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "float" ],
                    "patching_rect": [ 498.0, 193.0, 28.0, 22.0 ],
                    "text": "f"
                }
            },
            {
                "box": {
                    "id": "obj-10",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 638.0, 280.0, 160.0, 22.0 ],
                    "text": "prepend param era_clock"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "Grain density",
                    "id": "obj-11",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "grain_pix::density",
                    "parameter_enable": 1,
                    "patching_rect": [ 219.0, 106.5, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 42.0, 38.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.5 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "density",
                            "parameter_mmax": 1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "density",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "density"
                }
            },
            {
                "box": {
                    "id": "obj-12",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 160.0, 193.0, 131.0, 22.0 ],
                    "text": "prepend param density",
                    "varname": "param[1]"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "Grain amount (blend weight)",
                    "id": "obj-13",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "grain_pix::amount",
                    "parameter_enable": 1,
                    "patching_rect": [ 274.8125, 106.5, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 6.0, 115.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 1.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "amount",
                            "parameter_mmax": 2.0,
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
                    "id": "obj-14",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 166.0, 151.5, 133.0, 22.0 ],
                    "text": "prepend param amount",
                    "varname": "param[2]"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "Temporal persistence (0=boil 1=frozen)",
                    "id": "obj-15",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "grain_pix::persistence",
                    "parameter_enable": 1,
                    "patching_rect": [ 330.0, 106.5, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 188.0, 38.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "persistence",
                            "parameter_mmax": 1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "persistence",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "persistence"
                }
            },
            {
                "box": {
                    "id": "obj-16",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 162.0, 318.0, 155.0, 22.0 ],
                    "text": "prepend param persistence",
                    "varname": "param[3]"
                }
            },
            {
                "box": {
                    "id": "obj-18",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 115.0, 157.0, 131.0, 22.0 ],
                    "text": "prepend param bypass",
                    "varname": "param[4]"
                }
            },
            {
                "box": {
                    "id": "obj-19",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 4,
                    "outlettype": [ "", "", "", "" ],
                    "patching_rect": [ 6.0, 502.0, 56.0, 22.0 ],
                    "restore": {
                        "amount": [ 0.5 ],
                        "bypass": [ 0 ],
                        "ch_diverge": [ 0.0 ],
                        "density": [ 0.5 ],
                        "displace": [ 0.0 ],
                        "edge_mode_menu": [ 2 ],
                        "fade": [ 0.0 ],
                        "field_1": [ 3.188976377952752 ],
                        "jitter": [ 0.0 ],
                        "luma_gate": [ 0.0 ],
                        "persistence": [ 0.25196850393700776 ],
                        "shape": [ 0.5 ],
                        "size": [ 1.0 ],
                        "size_var": [ 0.0 ],
                        "softness": [ 0.0 ],
                        "sv_seed": [ 0.0 ]
                    },
                    "text": "autopattr",
                    "varname": "grain_autopattr"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "id": "obj-20",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 10.5, 218.0, 60.0, 21.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 4.0, 0.5, 60.0, 21.0 ],
                    "text": "Grain"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-21",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 10.0, 148.0, 35.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 40.0, 22.0, 35.0, 18.0 ],
                    "text": "Dens"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-22",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 12.5, 168.0, 30.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 8.0, 99.0, 30.0, 18.0 ],
                    "text": "Amt"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-23",
                    "linecount": 2,
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 6.0, 417.0, 30.0, 29.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 184.0, 22.0, 34.5, 18.0 ],
                    "text": "Speed"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "Grain size",
                    "id": "obj-25",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "grain_pix::size",
                    "parameter_enable": 1,
                    "patching_rect": [ 127.5, 604.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 6.0, 38.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "size",
                            "parameter_mmax": 1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "size",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "size"
                }
            },
            {
                "box": {
                    "id": "obj-26",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 178.5, 623.0, 115.0, 22.0 ],
                    "text": "prepend param size",
                    "varname": "param[5]"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "Grain size variation",
                    "id": "obj-27",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "grain_pix::size_var",
                    "parameter_enable": 1,
                    "patching_rect": [ 127.5, 557.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 79.0, 38.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "size_var",
                            "parameter_mmax": 1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "size_var",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "size_var"
                }
            },
            {
                "box": {
                    "id": "obj-28",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 178.5, 578.0, 138.0, 22.0 ],
                    "text": "prepend param size_var",
                    "varname": "param[6]"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "Grain aspect ratio (-1=portrait 0=square 1=landscape)",
                    "id": "obj-29",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "grain_pix::shape",
                    "parameter_enable": 1,
                    "patching_rect": [ 127.5, 502.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 115.0, 38.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.5 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "shape",
                            "parameter_mmax": 1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "shape",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "shape"
                }
            },
            {
                "box": {
                    "id": "obj-30",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 176.5, 528.0, 126.0, 22.0 ],
                    "text": "prepend param shape",
                    "varname": "param[7]"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "Grain edge softness",
                    "id": "obj-31",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "grain_pix::softness",
                    "parameter_enable": 1,
                    "patching_rect": [ 122.5, 453.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 152.0, 115.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "softness",
                            "parameter_mmax": 5.0,
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
                    "id": "obj-32",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 170.5, 468.5, 138.0, 22.0 ],
                    "text": "prepend param softness",
                    "varname": "param[8]"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-33",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 12.5, 250.0, 30.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 5.0, 22.0, 30.0, 18.0 ],
                    "text": "Size"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-34",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 5.0, 276.0, 32.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 78.0, 22.0, 32.0, 18.0 ],
                    "text": "S.var"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-35",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 10.0, 301.0, 34.5, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 112.0, 22.0, 35.0, 18.0 ],
                    "text": "Shape"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-36",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 9.5, 325.0, 28.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 152.0, 99.0, 28.0, 18.0 ],
                    "text": "Soft"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "Grain position jitter (0=grid 1=scattered)",
                    "id": "obj-37",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "grain_pix::jitter",
                    "parameter_enable": 1,
                    "patching_rect": [ 132.0, 401.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 119.0, 112.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "jitter",
                            "parameter_mmax": 2.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "jitter",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "jitter"
                }
            },
            {
                "box": {
                    "id": "obj-38",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 173.0, 417.0, 124.0, 22.0 ],
                    "text": "prepend param jitter",
                    "varname": "param[9]"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-39",
                    "linecount": 2,
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 16.25, 345.0, 22.0, 29.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 117.0, 98.0, 31.0, 18.0 ],
                    "text": "Jitter"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-53",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 10.0, 119.0, 40.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 41.0, 99.0, 34.0, 18.0 ],
                    "text": "Color"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "Luma gate: bipolar (-1=shadows 0=uniform +1=highlights)",
                    "id": "obj-60",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "grain_pix::luma_gate",
                    "parameter_enable": 1,
                    "patching_rect": [ 113.0, 263.5, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 79.0, 115.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "luma_gate",
                            "parameter_mmax": 1.0,
                            "parameter_mmin": -1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "luma_gate",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "luma_gate"
                }
            },
            {
                "box": {
                    "id": "obj-61",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 155.0, 280.0, 155.0, 22.0 ],
                    "text": "prepend param luma_gate",
                    "varname": "param[12]"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-62",
                    "linecount": 2,
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 8.5, 385.0, 30.0, 29.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 76.0, 99.0, 35.333334386348724, 18.0 ],
                    "text": "L.gate"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "Per-grain displacement amount",
                    "id": "obj-63",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "grain_pix::displace",
                    "parameter_enable": 1,
                    "patching_rect": [ 145.5, 700.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 188.0, 115.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "displace",
                            "parameter_mmax": 0.5,
                            "parameter_modmode": 3,
                            "parameter_shortname": "displace",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "displace"
                }
            },
            {
                "box": {
                    "id": "obj-64",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 182.5, 715.0, 145.0, 22.0 ],
                    "text": "prepend param displace",
                    "varname": "param[13]"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-66",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 10.5, 195.0, 34.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 188.0, 99.0, 34.0, 18.0 ],
                    "text": "Displ"
                }
            },
            {
                "box": {
                    "bgcolor": [ 0.0196078431372549, 0.0196078431372549, 0.0196078431372549, 0.0 ],
                    "bgfillcolor_angle": 270.0,
                    "bgfillcolor_autogradient": 0.0,
                    "bgfillcolor_color": [ 0.0196078431372549, 0.0196078431372549, 0.0196078431372549, 0.0 ],
                    "bgfillcolor_color1": [ 0.058823529411764705, 0.058823529411764705, 0.058823529411764705, 1.0 ],
                    "bgfillcolor_color2": [ 0.158640689195807, 0.158640642399981, 0.158640654628478, 1.0 ],
                    "bgfillcolor_proportion": 0.5,
                    "bgfillcolor_type": "color",
                    "fontname": "Ableton Sans Light",
                    "id": "obj-71",
                    "items": [ "Clear", ",", "Clamp", ",", "Wrap", ",", "Mirror" ],
                    "maxclass": "umenu",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "outlettype": [ "int", "", "" ],
                    "parameter_enable": 1,
                    "patching_rect": [ 49.5, 659.0, 115.0, 23.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 210.0, 97.0, 23.5, 23.0 ],
                    "saved_attribute_attributes": {
                        "valueof": {
                            "parameter_initial": [ 2 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "edge_mode_menu",
                            "parameter_mmax": 3.0,
                            "parameter_modmode": 0,
                            "parameter_shortname": "edge_mode_menu",
                            "parameter_type": 1,
                            "parameter_unitstyle": 0
                        }
                    },
                    "varname": "edge_mode_menu"
                }
            },
            {
                "box": {
                    "id": "obj-72",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 182.5, 660.0, 157.0, 22.0 ],
                    "text": "prepend param edge_mode",
                    "varname": "param[14]"
                }
            },
            {
                "box": {
                    "id": "obj-74",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 525.4375, 157.0, 180.0, 22.0 ],
                    "text": "expr pow(1.0 - $f1\\, 2.0)"
                }
            },
            {
                "box": {
                    "id": "obj-75",
                    "maxclass": "newobj",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "float" ],
                    "patching_rect": [ 496.0, 228.0, 32.0, 22.0 ],
                    "text": "+ 0."
                }
            },
            {
                "box": {
                    "id": "obj-76",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "float", "float" ],
                    "patching_rect": [ 638.0, 239.0, 42.0, 22.0 ],
                    "text": "t f f"
                }
            },
            {
                "box": {
                    "id": "obj-81",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 615.0, 468.5, 140.0, 22.0 ],
                    "text": "prepend param field",
                    "varname": "param[16]"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "id": "obj-82",
                    "maxclass": "live.numbox",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "grain_pix::sv_seed",
                    "parameter_enable": 1,
                    "patching_rect": [ 774.0, 438.0, 44.0, 15.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 75.0, 82.0, 34.0, 15.0 ],
                    "saved_attribute_attributes": {
                        "valueof": {
                            "parameter_initial": [ 0.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_longname": "sv_seed",
                            "parameter_mmax": 5.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "sv_seed",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "varname": "sv_seed"
                }
            },
            {
                "box": {
                    "id": "obj-83",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 765.0, 468.5, 152.0, 22.0 ],
                    "text": "prepend param sv_seed"
                }
            },
            {
                "box": {
                    "angle": 270.0,
                    "background": 1,
                    "bgcolor": [ 0.058823529411764705, 0.058823529411764705, 0.058823529411764705, 1.0 ],
                    "border": 1,
                    "bordercolor": [ 0.0, 0.03529411764705882, 0.22745098039215686, 1.0 ],
                    "id": "obj-24",
                    "maxclass": "panel",
                    "mode": 0,
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 0.0, 0.0, 150.0, 100.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 2.0, 2.0, 227.0, 164.0 ],
                    "proportion": 0.5
                }
            }
        ],
        "lines": [
            {
                "patchline": {
                    "destination": [ "obj-6", 0 ],
                    "source": [ "obj-1", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-7", 0 ],
                    "source": [ "obj-1", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-70", 0 ],
                    "source": [ "obj-1", 2 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-1", 0 ],
                    "source": [ "obj-10", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-12", 0 ],
                    "source": [ "obj-11", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-1", 0 ],
                    "source": [ "obj-12", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-14", 0 ],
                    "source": [ "obj-13", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-1", 0 ],
                    "source": [ "obj-14", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-16", 0 ],
                    "order": 1,
                    "source": [ "obj-15", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-74", 0 ],
                    "order": 0,
                    "source": [ "obj-15", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-1", 0 ],
                    "source": [ "obj-16", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-18", 0 ],
                    "source": [ "obj-17", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-1", 0 ],
                    "source": [ "obj-18", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-4", 0 ],
                    "source": [ "obj-2", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-26", 0 ],
                    "source": [ "obj-25", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-1", 0 ],
                    "source": [ "obj-26", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-28", 0 ],
                    "source": [ "obj-27", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-1", 0 ],
                    "source": [ "obj-28", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-30", 0 ],
                    "source": [ "obj-29", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-1", 0 ],
                    "source": [ "obj-30", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-32", 0 ],
                    "source": [ "obj-31", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-1", 0 ],
                    "source": [ "obj-32", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-38", 0 ],
                    "source": [ "obj-37", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-1", 0 ],
                    "source": [ "obj-38", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-1", 0 ],
                    "source": [ "obj-4", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-42", 0 ],
                    "source": [ "obj-40", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-1", 0 ],
                    "source": [ "obj-42", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-81", 0 ],
                    "source": [ "obj-43", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-86", 0 ],
                    "source": [ "obj-5", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-61", 0 ],
                    "source": [ "obj-60", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-1", 0 ],
                    "source": [ "obj-61", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-64", 0 ],
                    "source": [ "obj-63", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-1", 0 ],
                    "source": [ "obj-64", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-72", 0 ],
                    "source": [ "obj-71", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-1", 0 ],
                    "source": [ "obj-72", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-9", 1 ],
                    "source": [ "obj-74", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-76", 0 ],
                    "source": [ "obj-75", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-10", 0 ],
                    "source": [ "obj-76", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-75", 1 ],
                    "source": [ "obj-76", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-9", 0 ],
                    "source": [ "obj-8", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-1", 0 ],
                    "source": [ "obj-81", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-83", 0 ],
                    "source": [ "obj-82", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-1", 0 ],
                    "source": [ "obj-83", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-1", 0 ],
                    "source": [ "obj-84", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-85", 0 ],
                    "source": [ "obj-84", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-43", 0 ],
                    "source": [ "obj-85", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-82", 0 ],
                    "source": [ "obj-85", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-11", 0 ],
                    "source": [ "obj-86", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-13", 0 ],
                    "source": [ "obj-86", 2 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-15", 0 ],
                    "source": [ "obj-86", 3 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-17", 0 ],
                    "source": [ "obj-86", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-2", 0 ],
                    "source": [ "obj-86", 4 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-25", 0 ],
                    "source": [ "obj-86", 5 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-27", 0 ],
                    "source": [ "obj-86", 6 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-29", 0 ],
                    "source": [ "obj-86", 7 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-31", 0 ],
                    "source": [ "obj-86", 8 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-37", 0 ],
                    "source": [ "obj-86", 9 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-40", 0 ],
                    "source": [ "obj-86", 10 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-43", 0 ],
                    "source": [ "obj-86", 14 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-60", 0 ],
                    "source": [ "obj-86", 11 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-63", 0 ],
                    "source": [ "obj-86", 12 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-71", 0 ],
                    "source": [ "obj-86", 13 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-82", 0 ],
                    "source": [ "obj-86", 15 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-84", 0 ],
                    "source": [ "obj-86", 16 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-75", 0 ],
                    "source": [ "obj-9", 0 ]
                }
            }
        ],
        "parameters": {
            "obj-11": [ "density", "density", 0 ],
            "obj-13": [ "amount", "amount", 0 ],
            "obj-15": [ "persistence", "persistence", 0 ],
            "obj-17": [ "bypass", "bypass", 0 ],
            "obj-2": [ "fade", "fade", 0 ],
            "obj-25": [ "size", "size", 0 ],
            "obj-27": [ "size_var", "size_var", 0 ],
            "obj-29": [ "shape", "shape", 0 ],
            "obj-31": [ "softness", "softness", 0 ],
            "obj-37": [ "jitter", "jitter", 0 ],
            "obj-40": [ "ch_diverge", "ch_diverge", 0 ],
            "obj-43": [ "field", "field", 0 ],
            "obj-60": [ "luma_gate", "luma_gate", 0 ],
            "obj-63": [ "displace", "displace", 0 ],
            "obj-71": [ "edge_mode_menu", "edge_mode_menu", 0 ],
            "obj-82": [ "sv_seed", "sv_seed", 0 ],
            "parameterbanks": {
                "0": {
                    "index": 0,
                    "name": "",
                    "parameters": [ "-", "-", "-", "-", "-", "-", "-", "-" ],
                    "buttons": [ "-", "-", "-", "-", "-", "-", "-", "-" ]
                }
            },
            "inherited_shortname": 1
        },
        "autosave": 0
    }
}