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
        "rect": [ 34.0, 376.0, 1058.0, 876.0 ],
        "openinpresentation": 1,
        "boxes": [
            {
                "box": {
                    "id": "obj-58",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 788.0, 460.0, 149.0, 22.0 ],
                    "text": "prepend param src_shape"
                }
            },
            {
                "box": {
                    "comment": "shape tex",
                    "id": "obj-7",
                    "index": 0,
                    "maxclass": "inlet",
                    "numinlets": 0,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 90.0, 359.0, 30.0, 30.0 ]
                }
            },
            {
                "box": {
                    "id": "obj-19",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "" ],
                    "patching_rect": [ 738.0, 405.0, 80.0, 22.0 ],
                    "text": "vs_inState"
                }
            },
            {
                "box": {
                    "comment": "texture / control",
                    "id": "obj-1",
                    "index": 0,
                    "maxclass": "inlet",
                    "numinlets": 0,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 30.0, 30.0, 30.0, 30.0 ]
                }
            },
            {
                "box": {
                    "comment": "composite out",
                    "id": "obj-2",
                    "index": 0,
                    "maxclass": "outlet",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 30.0, 721.0, 30.0, 30.0 ]
                }
            },
            {
                "box": {
                    "comment": "mark mask",
                    "id": "obj-201",
                    "index": 0,
                    "maxclass": "outlet",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 90.0, 721.0, 30.0, 30.0 ]
                }
            },
            {
                "box": {
                    "comment": "seed coord",
                    "id": "obj-202",
                    "index": 0,
                    "maxclass": "outlet",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 150.0, 721.0, 30.0, 30.0 ]
                }
            },
            {
                "box": {
                    "id": "obj-3",
                    "maxclass": "newobj",
                    "numinlets": 3,
                    "numoutlets": 3,
                    "outlettype": [ "", "", "" ],
                    "patching_rect": [ 300.0, 30.0, 215.0, 22.0 ],
                    "text": "routepass jit_gl_texture jit_matrix"
                }
            },
            {
                "box": {
                    "id": "obj-4",
                    "maxclass": "newobj",
                    "numinlets": 12,
                    "numoutlets": 12,
                    "outlettype": [ "", "", "", "", "", "", "", "", "", "", "", "" ],
                    "patching_rect": [ 332.0, 236.0, 693.0, 22.0 ],
                    "text": "route density jitter weight marklen softness stretch strength mag_weight phase weight_mod marklen_mod"
                }
            },
            {
                "box": {
                    "id": "obj-5",
                    "maxclass": "newobj",
                    "numinlets": 4,
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
                        "rect": [ 157.0, 335.0, 700.0, 600.0 ],
                        "boxes": [
                            {
                                "box": {
                                    "id": "obj-1",
                                    "maxclass": "newobj",
                                    "numinlets": 0,
                                    "numoutlets": 1,
                                    "outlettype": [ "" ],
                                    "patching_rect": [ 524.0, 30.0, 28.0, 22.0 ],
                                    "text": "in 4"
                                }
                            },
                            {
                                "box": {
                                    "id": "gen-obj-1",
                                    "maxclass": "newobj",
                                    "numinlets": 0,
                                    "numoutlets": 1,
                                    "outlettype": [ "" ],
                                    "patching_rect": [ 22.0, 30.0, 28.0, 22.0 ],
                                    "text": "in 1"
                                }
                            },
                            {
                                "box": {
                                    "id": "gen-obj-10",
                                    "maxclass": "newobj",
                                    "numinlets": 0,
                                    "numoutlets": 1,
                                    "outlettype": [ "" ],
                                    "patching_rect": [ 80.0, 30.0, 28.0, 22.0 ],
                                    "text": "in 2"
                                }
                            },
                            {
                                "box": {
                                    "id": "gen-obj-11",
                                    "maxclass": "newobj",
                                    "numinlets": 0,
                                    "numoutlets": 1,
                                    "outlettype": [ "" ],
                                    "patching_rect": [ 138.0, 30.0, 28.0, 22.0 ],
                                    "text": "in 3"
                                }
                            },
                            {
                                "box": {
                                    "code": "// f_vf_seeds — placement and orientation engine\n// in1: source  in2: shape tex  in3: vecfield  in4: mod tex\n\nParam density(0.5);\nParam jitter(0.5);\nParam weight(0.1);\nParam marklen(0.3);\nParam stretch(0.0);\nParam softness(0.0);\nParam phase(0.0);\nParam strength(1.0);\nParam mag_weight(0.0);\nParam weight_mod(0.0);\nParam marklen_mod(0.0);\nParam src_vecfield(0.0);\nParam src_mod(0.0);\nParam src_shape(0.0);\nParam bypass(0.0);\n\n// ── Grid density ──────────────────────────────────────────────────────────────\n\ndensity_scale = pow(2.0, density * 9.0 - 1.0);\naspect = dim.x / dim.y;\n\npx = norm.x * density_scale * aspect;\npy = norm.y * density_scale;\nicx = floor(px);\nicy = floor(py);\n\n// ── 3x3 neighbourhood seed search ────────────────────────────────────────────\n\nncx = icx-1.0; ncy = icy-1.0;\njxA = fract(sin(ncx*127.1 + ncy*311.7)*43758.5453) - 0.5;\njyA = fract(sin(ncx*269.5 + ncy*183.3)*43758.5453) - 0.5;\nsxA = (ncx + 0.5 + jxA*jitter) / (density_scale * aspect);\nsyA = (ncy + 0.5 + jyA*jitter) / density_scale;\ndxA = norm.x - sxA; dyA = norm.y - syA;\ndA = dxA*dxA + dyA*dyA;\n\nncx = icx; ncy = icy-1.0;\njxB = fract(sin(ncx*127.1 + ncy*311.7)*43758.5453) - 0.5;\njyB = fract(sin(ncx*269.5 + ncy*183.3)*43758.5453) - 0.5;\nsxB = (ncx + 0.5 + jxB*jitter) / (density_scale * aspect);\nsyB = (ncy + 0.5 + jyB*jitter) / density_scale;\ndxB = norm.x - sxB; dyB = norm.y - syB;\ndB = dxB*dxB + dyB*dyB;\n\nncx = icx+1.0; ncy = icy-1.0;\njxC = fract(sin(ncx*127.1 + ncy*311.7)*43758.5453) - 0.5;\njyC = fract(sin(ncx*269.5 + ncy*183.3)*43758.5453) - 0.5;\nsxC = (ncx + 0.5 + jxC*jitter) / (density_scale * aspect);\nsyC = (ncy + 0.5 + jyC*jitter) / density_scale;\ndxC = norm.x - sxC; dyC = norm.y - syC;\ndC = dxC*dxC + dyC*dyC;\n\nncx = icx-1.0; ncy = icy;\njxD = fract(sin(ncx*127.1 + ncy*311.7)*43758.5453) - 0.5;\njyD = fract(sin(ncx*269.5 + ncy*183.3)*43758.5453) - 0.5;\nsxD = (ncx + 0.5 + jxD*jitter) / (density_scale * aspect);\nsyD = (ncy + 0.5 + jyD*jitter) / density_scale;\ndxD = norm.x - sxD; dyD = norm.y - syD;\ndD = dxD*dxD + dyD*dyD;\n\nncx = icx; ncy = icy;\njxE = fract(sin(ncx*127.1 + ncy*311.7)*43758.5453) - 0.5;\njyE = fract(sin(ncx*269.5 + ncy*183.3)*43758.5453) - 0.5;\nsxE = (ncx + 0.5 + jxE*jitter) / (density_scale * aspect);\nsyE = (ncy + 0.5 + jyE*jitter) / density_scale;\ndxE = norm.x - sxE; dyE = norm.y - syE;\ndE = dxE*dxE + dyE*dyE;\n\nncx = icx+1.0; ncy = icy;\njxF = fract(sin(ncx*127.1 + ncy*311.7)*43758.5453) - 0.5;\njyF = fract(sin(ncx*269.5 + ncy*183.3)*43758.5453) - 0.5;\nsxF = (ncx + 0.5 + jxF*jitter) / (density_scale * aspect);\nsyF = (ncy + 0.5 + jyF*jitter) / density_scale;\ndxF = norm.x - sxF; dyF = norm.y - syF;\ndF = dxF*dxF + dyF*dyF;\n\nncx = icx-1.0; ncy = icy+1.0;\njxG = fract(sin(ncx*127.1 + ncy*311.7)*43758.5453) - 0.5;\njyG = fract(sin(ncx*269.5 + ncy*183.3)*43758.5453) - 0.5;\nsxG = (ncx + 0.5 + jxG*jitter) / (density_scale * aspect);\nsyG = (ncy + 0.5 + jyG*jitter) / density_scale;\ndxG = norm.x - sxG; dyG = norm.y - syG;\ndG = dxG*dxG + dyG*dyG;\n\nncx = icx; ncy = icy+1.0;\njxH = fract(sin(ncx*127.1 + ncy*311.7)*43758.5453) - 0.5;\njyH = fract(sin(ncx*269.5 + ncy*183.3)*43758.5453) - 0.5;\nsxH = (ncx + 0.5 + jxH*jitter) / (density_scale * aspect);\nsyH = (ncy + 0.5 + jyH*jitter) / density_scale;\ndxH = norm.x - sxH; dyH = norm.y - syH;\ndH = dxH*dxH + dyH*dyH;\n\nncx = icx+1.0; ncy = icy+1.0;\njxI = fract(sin(ncx*127.1 + ncy*311.7)*43758.5453) - 0.5;\njyI = fract(sin(ncx*269.5 + ncy*183.3)*43758.5453) - 0.5;\nsxI = (ncx + 0.5 + jxI*jitter) / (density_scale * aspect);\nsyI = (ncy + 0.5 + jyI*jitter) / density_scale;\ndxI = norm.x - sxI; dyI = norm.y - syI;\ndI = dxI*dxI + dyI*dyI;\n\n// ── Find nearest seed ─────────────────────────────────────────────────────────\n\nbest_d=dA; best_gx=sxA; best_gy=syA; best_dx=dxA; best_dy=dyA;\nt=step(dB,best_d); best_d=mix(best_d,dB,t); best_gx=mix(best_gx,sxB,t); best_gy=mix(best_gy,syB,t); best_dx=mix(best_dx,dxB,t); best_dy=mix(best_dy,dyB,t);\nt=step(dC,best_d); best_d=mix(best_d,dC,t); best_gx=mix(best_gx,sxC,t); best_gy=mix(best_gy,syC,t); best_dx=mix(best_dx,dxC,t); best_dy=mix(best_dy,dyC,t);\nt=step(dD,best_d); best_d=mix(best_d,dD,t); best_gx=mix(best_gx,sxD,t); best_gy=mix(best_gy,syD,t); best_dx=mix(best_dx,dxD,t); best_dy=mix(best_dy,dyD,t);\nt=step(dE,best_d); best_d=mix(best_d,dE,t); best_gx=mix(best_gx,sxE,t); best_gy=mix(best_gy,syE,t); best_dx=mix(best_dx,dxE,t); best_dy=mix(best_dy,dyE,t);\nt=step(dF,best_d); best_d=mix(best_d,dF,t); best_gx=mix(best_gx,sxF,t); best_gy=mix(best_gy,syF,t); best_dx=mix(best_dx,dxF,t); best_dy=mix(best_dy,dyF,t);\nt=step(dG,best_d); best_d=mix(best_d,dG,t); best_gx=mix(best_gx,sxG,t); best_gy=mix(best_gy,syG,t); best_dx=mix(best_dx,dxG,t); best_dy=mix(best_dy,dyG,t);\nt=step(dH,best_d); best_d=mix(best_d,dH,t); best_gx=mix(best_gx,sxH,t); best_gy=mix(best_gy,syH,t); best_dx=mix(best_dx,dxH,t); best_dy=mix(best_dy,dyH,t);\nt=step(dI,best_d); best_d=mix(best_d,dI,t); best_gx=mix(best_gx,sxI,t); best_gy=mix(best_gy,syI,t); best_dx=mix(best_dx,dxI,t); best_dy=mix(best_dy,dyI,t);\n\n// ── Sample vecfield at seed position ─────────────────────────────────────────\n\nvx = (sample(in3, vec(best_gx, best_gy)).x - 0.5) * 2.0;\nvy = (sample(in3, vec(best_gx, best_gy)).y - 0.5) * 2.0;\n\nfield_mag = sqrt(max(vx*vx + vy*vy, 0.0));\nmag = max(field_mag, 0.0001);\nfcs = vx / mag;\nfsn = vy / mag;\n\ncs = mix(1.0, fcs, strength);\nsn = mix(0.0, fsn, strength);\nmag2 = max(sqrt(cs*cs + sn*sn), 0.0001);\ncs = cs / mag2;\nsn = sn / mag2;\n\n// ── Project pixel offset into seed-local frame ────────────────────────────────\n\nodx = best_dx * aspect;\nody = best_dy;\nalong  =  odx * cs + ody * sn;\nacross = -odx * sn + ody * cs;\n\n// ── Mod tex modulation (sampled at seed UV) ───────────────────────────────────\n\nmod_sample = sample(in4, vec(best_gx, best_gy)).x * src_mod;\nweight_eff  = clamp(weight  + mod_sample * weight_mod  + field_mag * mag_weight, 0.001, 0.5);\nmarklen_eff = clamp(marklen + mod_sample * marklen_mod, 0.001, 0.5);\n\n// ── Construct seed-local UV ───────────────────────────────────────────────────\n// along axis: always normalized by marklen (with phase offset)\n// across axis: stretch=1 → normalized by weight (deform)\n//              stretch=0 → normalized by marklen (preserve aspect) + weight aperture clip\n\nalong_shifted = along - phase * marklen_eff;\n\nlocal_u = along_shifted / marklen_eff * 0.5 + 0.5;\nlocal_v_stretch = across / weight_eff * 0.5 + 0.5;\nlocal_v_uniform = across / marklen_eff * 0.5 + 0.5;\nlocal_v = mix(local_v_uniform, local_v_stretch, stretch);\n\n// ── Gate and softness ─────────────────────────────────────────────────────────\n// Softness feathers the boundary in UV space.\n// In uniform mode, also gate on weight aperture (across axis clip).\n\nsoft = max(softness, 0.0001);\nedge_u = smoothstep(1.0 + soft, 1.0, abs(local_u * 2.0 - 1.0));\nedge_v = smoothstep(1.0 + soft, 1.0, abs(local_v * 2.0 - 1.0));\n\n// weight aperture in uniform mode — hard gate on across distance\naperture = step(abs(across), weight_eff);\naperture_mixed = mix(aperture, 1.0, stretch);\n\ngate = edge_u * edge_v * aperture_mixed;\n\n// ── Sample shape tex, take luma ───────────────────────────────────────────────\n// Passthrough if no shape connected (src_shape=0 → gate zeroes out via mix)\n\nshape_r = sample(in2, vec(local_u, local_v)).x;\nshape_g = sample(in2, vec(local_u, local_v)).y;\nshape_b = sample(in2, vec(local_u, local_v)).z;\nshape_luma = (shape_r + shape_g + shape_b) / 3.0;\n\nmark = shape_luma * gate * src_shape;\n\n// ── Outputs ───────────────────────────────────────────────────────────────────\n\nsrc = sample(in1, norm);\ncomposite = vec(src.x + mark, src.y + mark, src.z + mark, 1.0);\nout1 = mix(composite, vec(0.0, 0.0, 0.0, 1.0), bypass);\nout2 = mix(vec(mark, mark, mark, 1.0), vec(0.0, 0.0, 0.0, 1.0), bypass);\nout3 = mix(vec(best_gx, best_gy, 0.0, 1.0), vec(0.0, 0.0, 0.0, 1.0), bypass);",
                                    "fontface": 0,
                                    "fontname": "<Monospaced>",
                                    "fontsize": 12.0,
                                    "id": "gen-obj-2",
                                    "maxclass": "codebox",
                                    "numinlets": 4,
                                    "numoutlets": 3,
                                    "outlettype": [ "", "", "" ],
                                    "patching_rect": [ 22.0, 80.0, 550.0, 380.0 ]
                                }
                            },
                            {
                                "box": {
                                    "id": "gen-obj-3",
                                    "maxclass": "newobj",
                                    "numinlets": 1,
                                    "numoutlets": 0,
                                    "patching_rect": [ 22.0, 490.0, 35.0, 22.0 ],
                                    "text": "out 1"
                                }
                            },
                            {
                                "box": {
                                    "id": "gen-obj-4",
                                    "maxclass": "newobj",
                                    "numinlets": 1,
                                    "numoutlets": 0,
                                    "patching_rect": [ 82.0, 490.0, 35.0, 22.0 ],
                                    "text": "out 2"
                                }
                            },
                            {
                                "box": {
                                    "id": "gen-obj-5",
                                    "maxclass": "newobj",
                                    "numinlets": 1,
                                    "numoutlets": 0,
                                    "patching_rect": [ 142.0, 490.0, 35.0, 22.0 ],
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
                                    "destination": [ "gen-obj-2", 1 ],
                                    "source": [ "gen-obj-10", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "gen-obj-2", 2 ],
                                    "source": [ "gen-obj-11", 0 ]
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
                            },
                            {
                                "patchline": {
                                    "destination": [ "gen-obj-2", 3 ],
                                    "source": [ "obj-1", 0 ]
                                }
                            }
                        ]
                    },
                    "patching_rect": [ 117.0, 592.0, 276.0, 22.0 ],
                    "text": "jit.gl.pix vsynth @name vfseeds_pix @type float32",
                    "varname": "vfseeds_pix"
                }
            },
            {
                "box": {
                    "id": "obj-6",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 4,
                    "outlettype": [ "", "", "", "" ],
                    "patching_rect": [ 500.0, 500.0, 56.0, 22.0 ],
                    "restore": {
                        "bypass": [ 0 ],
                        "density": [ 0.5 ],
                        "jitter": [ 0.5 ],
                        "mag_weight": [ 0.0 ],
                        "marklen": [ 0.3 ],
                        "marklen_mod": [ 0.0 ],
                        "phase": [ 0.0 ],
                        "softness": [ 0.0 ],
                        "strength": [ 1.0 ],
                        "stretch": [ 0.0 ],
                        "weight": [ 0.1 ],
                        "weight_mod": [ 0.0 ]
                    },
                    "text": "autopattr",
                    "varname": "vfseeds_autopattr"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-10",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 20.0, 20.0, 80.0, 21.0 ],
                    "presentation": 1,
                    "presentation_rect": [ -1.5, 0.0, 80.0, 21.0 ],
                    "text": "Seeds"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-8",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 20.0, 20.0, 60.0, 21.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 38.0, 2.5, 60.0, 21.0 ],
                    "text": "vecfield",
                    "textcolor": [ 0.302, 0.325, 0.463, 1.0 ]
                }
            },
            {
                "box": {
                    "id": "obj-11",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "bang" ],
                    "patching_rect": [ 600.0, 50.0, 60.0, 22.0 ],
                    "text": "loadbang"
                }
            },
            {
                "box": {
                    "id": "obj-12",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 600.0, 80.0, 180.0, 22.0 ],
                    "text": "getattr presentation_rect"
                }
            },
            {
                "box": {
                    "id": "obj-13",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "" ],
                    "patching_rect": [ 600.0, 110.0, 80.0, 22.0 ],
                    "save": [ "#N", "thispatcher", ";", "#Q", "end", ";" ],
                    "text": "thispatcher"
                }
            },
            {
                "box": {
                    "id": "obj-14",
                    "maxclass": "newobj",
                    "numinlets": 2,
                    "numoutlets": 2,
                    "outlettype": [ "", "" ],
                    "patching_rect": [ 600.0, 140.0, 60.0, 22.0 ],
                    "text": "zl slice 2"
                }
            },
            {
                "box": {
                    "id": "obj-15",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 600.0, 170.0, 80.0, 22.0 ],
                    "text": "prepend tam"
                }
            },
            {
                "box": {
                    "id": "obj-16",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 600.0, 200.0, 100.0, 22.0 ],
                    "saved_object_attributes": {
                        "filename": "moduleSize.js",
                        "parameter_enable": 0
                    },
                    "text": "js moduleSize.js"
                }
            },
            {
                "box": {
                    "comment": "vecfield",
                    "id": "obj-100",
                    "index": 0,
                    "maxclass": "inlet",
                    "numinlets": 0,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 150.0, 30.0, 30.0, 30.0 ]
                }
            },
            {
                "box": {
                    "id": "obj-101",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "" ],
                    "patching_rect": [ 35.0, 380.0, 80.0, 22.0 ],
                    "text": "vs_inState"
                }
            },
            {
                "box": {
                    "comment": "mod tex",
                    "id": "obj-103",
                    "index": 0,
                    "maxclass": "inlet",
                    "numinlets": 0,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 210.0, 414.0, 30.0, 30.0 ]
                }
            },
            {
                "box": {
                    "id": "obj-104",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "" ],
                    "patching_rect": [ 362.0, 460.0, 80.0, 22.0 ],
                    "text": "vs_inState"
                }
            },
            {
                "box": {
                    "id": "obj-102",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 45.0, 489.0, 160.0, 22.0 ],
                    "text": "prepend param src_vecfield"
                }
            },
            {
                "box": {
                    "id": "obj-105",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 494.25, 598.0, 139.0, 22.0 ],
                    "text": "prepend param src_mod"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "Seed spacing — log-mapped, higher = more seeds",
                    "id": "obj-20",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "vfseeds_pix::density",
                    "parameter_enable": 1,
                    "patching_rect": [ 50.0, 80.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 4.0, 38.0, 27.0, 43.0 ],
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
                    "attr": "density",
                    "id": "obj-21",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 50.0, 170.0, 129.0, 22.0 ]
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
                    "patching_rect": [ 50.0, 130.0, 50.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ -7.5, 20.0, 50.0, 18.0 ],
                    "text": "Density",
                    "textjustification": 1
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "Seed position randomness (0=regular grid, 1=fully stochastic)",
                    "id": "obj-23",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "vfseeds_pix::jitter",
                    "parameter_enable": 1,
                    "patching_rect": [ 100.0, 80.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 41.0, 38.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.5 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "jitter",
                            "parameter_mmax": 1.0,
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
                    "attr": "jitter",
                    "id": "obj-24",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 100.0, 200.0, 127.5, 22.0 ]
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-25",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 100.0, 130.0, 50.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 29.5, 20.0, 50.0, 18.0 ],
                    "text": "Jitter",
                    "textjustification": 1
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "Mark width (across-axis extent)",
                    "id": "obj-26",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "vfseeds_pix::weight",
                    "parameter_enable": 1,
                    "patching_rect": [ 150.0, 80.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 78.0, 38.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.1 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "weight",
                            "parameter_mmax": 0.5,
                            "parameter_modmode": 3,
                            "parameter_shortname": "weight",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "weight"
                }
            },
            {
                "box": {
                    "attr": "weight",
                    "id": "obj-27",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 150.0, 230.0, 127.5, 22.0 ]
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-28",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 150.0, 130.0, 50.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 66.5, 20.0, 50.0, 18.0 ],
                    "text": "Weight",
                    "textjustification": 1
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "Mark length (along-axis extent in field direction)",
                    "id": "obj-29",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "vfseeds_pix::marklen",
                    "parameter_enable": 1,
                    "patching_rect": [ 200.0, 80.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 115.0, 38.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.3 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "marklen",
                            "parameter_mmax": 0.5,
                            "parameter_modmode": 3,
                            "parameter_shortname": "marklen",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "marklen"
                }
            },
            {
                "box": {
                    "attr": "marklen",
                    "id": "obj-30",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 200.0, 260.0, 129.0, 22.0 ]
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-31",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 200.0, 130.0, 50.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 103.5, 20.0, 50.0, 18.0 ],
                    "text": "Marklen",
                    "textjustification": 1
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "Edge feather — expands falloff zone beyond mark boundary",
                    "id": "obj-32",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "vfseeds_pix::softness",
                    "parameter_enable": 1,
                    "patching_rect": [ 250.0, 80.0, 27.0, 43.0 ],
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
                            "parameter_longname": "softness",
                            "parameter_mmax": 2.0,
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
                    "attr": "softness",
                    "id": "obj-33",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 250.0, 290.0, 136.0, 22.0 ]
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
                    "patching_rect": [ 250.0, 130.0, 50.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 140.5, 20.0, 50.0, 18.0 ],
                    "text": "Softness",
                    "textjustification": 1
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "Vecfield influence on mark orientation (0=no bend, 1=full field)",
                    "id": "obj-41",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "vfseeds_pix::strength",
                    "parameter_enable": 1,
                    "patching_rect": [ 400.0, 80.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 78.0, 100.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 1.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "strength",
                            "parameter_mmax": 1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "strength",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "strength"
                }
            },
            {
                "box": {
                    "attr": "strength",
                    "id": "obj-42",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 400.0, 380.0, 136.0, 22.0 ]
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-43",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 400.0, 130.0, 50.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 66.5, 82.0, 50.0, 18.0 ],
                    "text": "Strength",
                    "textjustification": 1
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "Field magnitude → mark weight modulation depth",
                    "id": "obj-44",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "vfseeds_pix::mag_weight",
                    "parameter_enable": 1,
                    "patching_rect": [ 450.0, 80.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 115.0, 100.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "mag_weight",
                            "parameter_mmax": 1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "mag_weight",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "mag_weight"
                }
            },
            {
                "box": {
                    "attr": "mag_weight",
                    "id": "obj-45",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 450.0, 410.0, 150.0, 22.0 ]
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-46",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 450.0, 130.0, 50.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 103.5, 82.0, 50.0, 18.0 ],
                    "text": "Mag→Wt",
                    "textjustification": 1
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "Scroll marks along field direction (connect LFO for motion)",
                    "id": "obj-47",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "vfseeds_pix::phase",
                    "parameter_enable": 1,
                    "patching_rect": [ 500.0, 80.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 152.0, 100.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "phase",
                            "parameter_mmax": 1.0,
                            "parameter_mmin": -1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "phase",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "phase"
                }
            },
            {
                "box": {
                    "attr": "phase",
                    "id": "obj-48",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 500.0, 440.0, 127.5, 22.0 ]
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-49",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 500.0, 130.0, 50.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 140.5, 82.0, 50.0, 18.0 ],
                    "text": "Phase",
                    "textjustification": 1
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "Identity texture → weight modulation depth",
                    "id": "obj-50",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "vfseeds_pix::weight_mod",
                    "parameter_enable": 1,
                    "patching_rect": [ 550.0, 80.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 4.0, 162.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "weight_mod",
                            "parameter_mmax": 1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "weight_mod",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "weight_mod"
                }
            },
            {
                "box": {
                    "attr": "weight_mod",
                    "id": "obj-51",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 550.0, 470.0, 150.0, 22.0 ]
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-52",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 550.0, 130.0, 50.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ -7.5, 144.0, 50.0, 18.0 ],
                    "text": "Wt Mod",
                    "textjustification": 1
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "Identity texture → mark length modulation depth",
                    "id": "obj-53",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "vfseeds_pix::marklen_mod",
                    "parameter_enable": 1,
                    "patching_rect": [ 600.0, 80.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 41.0, 162.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "marklen_mod",
                            "parameter_mmax": 1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "marklen_mod",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "marklen_mod"
                }
            },
            {
                "box": {
                    "attr": "marklen_mod",
                    "id": "obj-54",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 600.0, 500.0, 157.0, 22.0 ]
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-55",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 600.0, 130.0, 50.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 29.5, 144.0, 50.0, 18.0 ],
                    "text": "Len Mod",
                    "textjustification": 1
                }
            },
            {
                "box": {
                    "filename": "bypass_toggle.js",
                    "hint": "Bypass",
                    "id": "obj-56",
                    "maxclass": "jsui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 168.0, 5.0, 18.0, 12.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 168.0, 5.0, 18.0, 12.0 ],
                    "valuepopuplabel": 1,
                    "varname": "bypass"
                }
            },
            {
                "box": {
                    "attr": "bypass",
                    "id": "obj-57",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 400.0, 60.0, 131.0, 22.0 ]
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "Shape mode: 0=uniform+aperture, 1=stretch to fit",
                    "id": "obj-300",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "vfseeds_pix::stretch",
                    "parameter_enable": 1,
                    "patching_rect": [ 300.0, 80.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 4.0, 100.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "stretch",
                            "parameter_mmax": 1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "stretch",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "stretch"
                }
            },
            {
                "box": {
                    "attr": "stretch",
                    "id": "obj-301",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 300.0, 320.0, 127.5, 22.0 ]
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-302",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 300.0, 130.0, 50.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ -7.5, 82.0, 50.0, 18.0 ],
                    "text": "Stretch",
                    "textjustification": 1
                }
            },
            {
                "box": {
                    "angle": 270.0,
                    "background": 1,
                    "bgcolor": [ 0.0, 0.0, 0.0, 1.0 ],
                    "border": 1,
                    "bordercolor": [ 0.0, 0.03529411765, 0.2274509804, 1.0 ],
                    "id": "obj-9",
                    "maxclass": "panel",
                    "mode": 0,
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 20.0, 20.0, 190.0, 175.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 0.0, 0.0, 190.0, 175.0 ],
                    "proportion": 0.5
                }
            }
        ],
        "lines": [
            {
                "patchline": {
                    "destination": [ "obj-3", 0 ],
                    "source": [ "obj-1", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-101", 0 ],
                    "source": [ "obj-100", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-102", 0 ],
                    "source": [ "obj-101", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 2 ],
                    "source": [ "obj-101", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 0 ],
                    "source": [ "obj-102", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-104", 0 ],
                    "source": [ "obj-103", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-105", 0 ],
                    "source": [ "obj-104", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 3 ],
                    "source": [ "obj-104", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 0 ],
                    "source": [ "obj-105", 0 ]
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
                    "destination": [ "obj-13", 0 ],
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
                    "destination": [ "obj-15", 0 ],
                    "source": [ "obj-14", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-16", 0 ],
                    "source": [ "obj-15", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 1 ],
                    "source": [ "obj-19", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-58", 0 ],
                    "source": [ "obj-19", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-21", 0 ],
                    "source": [ "obj-20", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 0 ],
                    "source": [ "obj-21", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-24", 0 ],
                    "source": [ "obj-23", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 0 ],
                    "source": [ "obj-24", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-27", 0 ],
                    "source": [ "obj-26", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 0 ],
                    "source": [ "obj-27", 0 ]
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
                    "destination": [ "obj-4", 0 ],
                    "source": [ "obj-3", 2 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 0 ],
                    "source": [ "obj-3", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 0 ],
                    "source": [ "obj-30", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-301", 0 ],
                    "source": [ "obj-300", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 0 ],
                    "source": [ "obj-301", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-33", 0 ],
                    "source": [ "obj-32", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 0 ],
                    "source": [ "obj-33", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-20", 0 ],
                    "source": [ "obj-4", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-23", 0 ],
                    "source": [ "obj-4", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-26", 0 ],
                    "source": [ "obj-4", 2 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-29", 0 ],
                    "source": [ "obj-4", 3 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-300", 0 ],
                    "source": [ "obj-4", 5 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-32", 0 ],
                    "source": [ "obj-4", 4 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-41", 0 ],
                    "source": [ "obj-4", 6 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-44", 0 ],
                    "source": [ "obj-4", 7 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-47", 0 ],
                    "source": [ "obj-4", 8 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-50", 0 ],
                    "source": [ "obj-4", 9 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-53", 0 ],
                    "source": [ "obj-4", 10 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-42", 0 ],
                    "source": [ "obj-41", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 0 ],
                    "source": [ "obj-42", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-45", 0 ],
                    "source": [ "obj-44", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 0 ],
                    "source": [ "obj-45", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-48", 0 ],
                    "source": [ "obj-47", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 0 ],
                    "source": [ "obj-48", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-2", 0 ],
                    "source": [ "obj-5", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-201", 0 ],
                    "source": [ "obj-5", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-202", 0 ],
                    "source": [ "obj-5", 2 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-51", 0 ],
                    "source": [ "obj-50", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 0 ],
                    "source": [ "obj-51", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-54", 0 ],
                    "source": [ "obj-53", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 0 ],
                    "source": [ "obj-54", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-57", 0 ],
                    "source": [ "obj-56", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 0 ],
                    "source": [ "obj-57", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 0 ],
                    "source": [ "obj-58", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-19", 0 ],
                    "source": [ "obj-7", 0 ]
                }
            }
        ],
        "parameters": {
            "obj-20": [ "density", "density", 0 ],
            "obj-23": [ "jitter", "jitter", 0 ],
            "obj-26": [ "weight", "weight", 0 ],
            "obj-29": [ "marklen", "marklen", 0 ],
            "obj-300": [ "stretch", "stretch", 0 ],
            "obj-32": [ "softness", "softness", 0 ],
            "obj-41": [ "strength", "strength", 0 ],
            "obj-44": [ "mag_weight", "mag_weight", 0 ],
            "obj-47": [ "phase", "phase", 0 ],
            "obj-50": [ "weight_mod", "weight_mod", 0 ],
            "obj-53": [ "marklen_mod", "marklen_mod", 0 ],
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