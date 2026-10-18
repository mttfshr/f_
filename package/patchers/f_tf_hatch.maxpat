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
					"comment": "hatch output",
					"index": 0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						30.0,
						552.0,
						30.0,
						30.0
					],
					"tricolor": [
						0.55,
						0.55,
						0.55,
						1.0
					],
					"hint": "Hatch marks, luma on black (color is downstream's job, the f_weave convention). Commit-weighted: coherently-line-structured regions render strokes, near-gate regions fade toward nothing; aspect rounds to dots as coherence falls (plan ADR-9). @type float32."
				}
			},
			{
				"box": {
					"id": "obj-201",
					"maxclass": "outlet",
					"comment": "mark mask",
					"index": 0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						100.0,
						552.0,
						30.0,
						30.0
					],
					"tricolor": [
						0.55,
						0.55,
						0.55,
						1.0
					],
					"hint": "Mark mask without the encode mix (same luma, the discrete-family convention, f_vf_seeds out1): for downstream compositing/gating. NOT a tensor and not a vecfield."
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
						56.5,
						204.0,
						655.0,
						22.0
					],
					"text": "route density weight softness elongation strength coherence_gate angle_offset phase regularity"
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
									"code": "// Stage E1 (f_tf_hatch): eigen decode + commit + guard. in1 = the TENSOR\n// (f_tf_tensormap outlet 0, raw float32; f_tensor_type.md encoding).\n// Mirrors tests/test_tf_hatch.py stage_e1. Intermediate texture, NEVER an\n// outlet; unbounded float32 (plan ADR-4 -- no clamp, no 0.5-offset here).\n//\n// out1 = (ca, sa, commit, iso):\n//   (ca, sa)     cos/sin of the commit-frame axis:\n//                axis = theta + pi/2 + angle_offset*pi/2\n//   commit       the commit curve (smoothstep in the normalized eigengap;\n//                PROVISIONAL knees C_LO/C_HI -- OQ3 open, tier-3 confirms)\n//   iso          1 = direction-undefined/zero tensor (eps_trace guard,\n//                tensormap ADR-6/T019 value cited): axis UNSET (ca=sa=0),\n//                commit 0 -- never an atan2 artifact (plan ADR-5)\n//\n// DECODE IDIOM: copied VERBATIM from .specify/f_tf_glyph/plan.md ADR-2\n// (the canonical block; do not re-derive):\n//   in: t = sample(tensor_tex, clamp(cell_uv_to_texel))  // tensormap ADR-5 clamp\n//   encoding: f_tensor_type.md outlet 0 - R>=0 G:0.5=zero B>=0 A=1 (all x strength)\n//   Jxx = t.r / strength; Jxy = (t.g - 0.5)*2.0/strength; Jyy = t.b/strength;\n//   trace = Jxx + Jyy; diff = Jxx - Jyy; root = sqrt(diff*diff + 4.0*Jxy*Jxy);\n//   lambda1 = 0.5*(trace + root); lambda2 = 0.5*(trace - root);\n//   theta = 0.5*atan2(2.0*Jxy, diff);      // GRADIENT axis; along = theta + pi/2\n//   ... 0.5*atan2 confines theta to (-pi/2, pi/2]; safe ONLY for consumers\n//   symmetric to theta+180 deg (hatch IS: an unoriented line pattern).\n// Coherence normalization is TENSormap's (its plan ADR-2, not glyph's):\n//   coherence = (lambda1-lambda2)/(lambda1+lambda2) -- gain-free.\n// Sample coordinate: the read is AT norm (texel centred, always in-bounds);\n// the clamp is kept for the in-shader rule (tensormap T012 finding).\n//\n// NOTE: this stage reads strength and angle_offset; commit knees C_LO/C_HI\n// are constants here (OQ3 provisional) -- coherence_gate rides C_LO.\n\nParam strength(100.0);\nParam angle_offset(0.0);\nParam coherence_gate(0.25);\n\neps_trace = 0.000001;\nC_HI = 1.0;    // commit saturates at coherence 1 (C_LO is coherence_gate, a live Param above)\n\nuv = vec(clamp(norm.x, 0.0, 1.0), clamp(norm.y, 0.0, 1.0));\nt = sample(in1, uv);\n\n// --- decode (glyph ADR-2 verbatim) ---\njxx = t.r / strength;\njxy = (t.g - 0.5) * 2.0 / strength;\njyy = t.b / strength;\ntrace = jxx + jyy;\ndiff = jxx - jyy;\nroot = sqrt(diff*diff + 4.0*jxy*jxy);\ntheta = 0.5 * atan2(2.0*jxy, diff);   // gradient axis (across the edge)\n\niso = 1.0 - step(eps_trace, trace);   // 1 = zero/undefined tensor\n// the -1-Jxy artifact of an all-zeros read (f_tensor_type.md rule 5) also\n// has trace 0: the SAME guard catches it (root 2/strength, phantom axis --\n// never written: ca/sa stay (0, 0) below).\n\n// coherence, gain-free (tensormap plan ADR-2):\ncoh = clamp(root / max(trace, eps_trace), 0.0, 1.0);\n\n// commit curve (PROVISIONAL smoothstep in the normalized eigengap, OQ3):\n// coherence_gate is the performer's commit floor: coherence at/below it\n// renders nothing (spec: the gate rides the knee, not a separate AND-mask,\n// so crossing the floor is continuous -- the no-seam guarantee).\nx = (coh - max(coherence_gate, 0.0)) / max(C_HI - max(coherence_gate, 0.0), 0.000001);\nx = clamp(x, 0.0, 1.0);\ncommit = x*x*(3.0 - 2.0*x) * (1.0 - iso);\n\n// commit-frame axis: along-structure + the performer rotation. The axis is\n// an UNORIENTED line (theta+180 is the same line): the offset wraps cleanly\n// (mod pi), the acceptance criterion's no-seam property.\neff = theta + halfpi + angle_offset * halfpi * 2.0 * 0.5;  // = +offset*pi/2\nca = cos(eff) * (1.0 - iso);\nsa = sin(eff) * (1.0 - iso);\n\nout1 = vec(ca, sa, commit, iso);",
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
						216.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_hatch_stage_e1 @type float32",
					"varname": "#0_hatch_stage_e1"
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
									"code": "// Stage E2 (f_tf_hatch): mark layout -- branch T (tileable distance-field\n// pattern, f_weave mechanics in the per-pixel local frame; chosen at the\n// T001 cost-shape gate, plan ADR-1 amendment). in1 = stage E1's aux.\n// Mirrors tests/test_tf_hatch.py stage_e2. Intermediate texture, NEVER an\n// outlet; unbounded float32 (plan ADR-4).\n//\n// out1 = (u, v, commit, iso):\n//   (u, v)   the pixel rotated into its local (across, along) frame --\n//            across = -sa*norm.x + ca*norm.y, along = ca*norm.x + sa*norm.y\n//            (the frame is E1's commit-frame axis, angle_offset applied)\n//   commit, iso   passthrough (E3 renders the profile against them)\n//\n// All coordinates are norm reads (sample at the pixel itself: no taps; the\n// per-pixel frame lives in the aux texture). Closed form, no loop. The\n// GATE PROVISIONAL-OPEN points recorded here:\n//   - dash PHASE continuity under hairpin curvature: the dist_to_mark field\n//     is built per-pixel from (u, v) straight-ray coordinates, so dash phase\n//     resets where the axis turns fast relative to the along-frame. The\n//     spike MEASURED this (ridge-err trend 24.9 -> 64.0 deg over ring\n//     spacing 8 -> 64); tier-3 judges the look; mitigations (elongation/\n//     weight tuning now; a phase-scan pass later) are recorded in ADR-1.\n//   - regularity's hash is computed IN E3 (per-line, weave's published\n//     form) -- E2 carries no hash state.\n\n// (no params on this stage: density/weight/softness/elongation/phase/\n// regularity are E3's; commit/gate/offset/strength are E1's)\n\nca2 = nearest(in1, norm).x;\nsa2 = nearest(in1, norm).y;\ncommit = nearest(in1, norm).z;\niso = nearest(in1, norm).w;\n\n// texel-centre clamp rule (tensormap T012): the coordinate is exactly norm,\n// which is always in-bounds on the render grid -- the clamp is a no-op kept\n// for the rule.\nu = (-sa2 * norm.x + ca2 * norm.y);\nv = ( ca2 * norm.x + sa2 * norm.y);\n\nout1 = vec(u, v, commit, iso);",
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
						430.0,
						216.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_hatch_stage_e2 @type float32",
					"varname": "#0_hatch_stage_e2"
				}
			},
			{
				"box": {
					"id": "obj-51",
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
									"code": "// Stage E3 (f_tf_hatch): mark render + compose + encode (the ONLY stage\n// that clamps/encodes -- hard rule, plan ADR-4). in1 = stage E2's aux2.\n// Mirrors tests/test_tf_hatch.py stage_e3.\n//\n// The f_weave algorithm (docs/f-reference/f_weave.md; its definition.py is\n// the shipped form) adapted to the per-pixel axis and the commit-driven\n// aspect. Cited verbatim where reused:\n//   density log map    density_scale = pow(2, density*5 - 1)\n//   line hash          line_hash = fract(sin(line_idx*127.1)*43758.5453)\n//                                  * (1 - regularity)\n//   edge form          outer = weight*(1 + softness); edge =\n//                      smoothstep(outer, 0.0, dist)   [softness EXPANDS the\n//                      outer edge multiplicatively; inner edge at 0; no\n//                      zero-denominator case at softness 0]\n//   softness clamp     softness <= 0.49 (weave's ceiling)\n//\n// Aspect -- plan ADR-9 (pitch units, capped at dash saturation):\n//   aspect  = 1 + elongation*commit           [commit 0 -> dot, commit 1 ->\n//                                              elongation+1 until saturation]\n//   aw      = weight / sqrt(aspect)           [across half-width, u units]\n//   al      = min(weight*density_scale*sqrt(aspect), 0.5)\n//                                             [along half-length, pos units;\n//                                              the 0.5 cap = dashes merge;\n//                                              aspect_max = (0.5/(w*ds))^2]\n//\n// Commit-weighted intensity: commit 0 -> NO marks (not full-brightness\n// dots) -- the no-seam-at-the-gate requirement (spike finding; the dot\n// character lives above the gate via the aspect squeeze, OQ3's\n// 'dots persist vs blank' resolved as fade-in, tier-3 confirms).\n//\n// out1 = module OUTLET 0: hatch output (luma marks on black, A=1); color is\n// downstream's job (weave convention). out2 = module OUTLET 1: mark mask\n// (same luma, no encode mix -- the discrete-family convention).\n// Bypass (bypass_mode \"param\"): black on both outlets (plan ADR-5; bypass\n// lives here, the last stage, like tensormap's).\n//\n// Tone (OQ2): OUT of v1 -- no tone inlet, no density-band layering (plan\n// ADR-6's T002 record); the v2 pointer is inlet-1-luma.\n\nParam density(0.5);\nParam weight(0.1);\nParam softness(0.05);\nParam elongation(3.0);\nParam phase(0.0);\nParam regularity(0.5);\nParam bypass_gate(0.0);\n\nsoft = min(softness, 0.49);\n\nu = nearest(in1, norm).x;\nv = nearest(in1, norm).y;\ncommit = nearest(in1, norm).z;\niso = nearest(in1, norm).w;\n\ndensity_scale = pow(2.0, density * 5.0 - 1.0);\n\naspect = 1.0 + elongation * commit;\nsqrt_aspect = sqrt(max(aspect, 1.0));\naw = weight / sqrt_aspect;\nal = min(weight * density_scale * sqrt_aspect, 0.5);\n\n// across-line distance field (in the local frame)\ndist_to_line = abs(fract(u * density_scale) - 0.5);\n\n// per-line phase offset (weave's hash, cited; iso pixels never render)\nline_idx = floor(u * density_scale);\nline_hash = fract(sin(line_idx * 127.1) * 43758.5453) * (1.0 - clamp(regularity, 0.0, 1.0));\npos = v * density_scale + phase + line_hash;\ndist_to_mark = abs(fract(pos) - 0.5);\n\n// edge falloff (cited: outer expands, inner at 0)\nouter_across = aw * (1.0 + soft);\nouter_along  = al * (1.0 + soft);\nedge_across = smoothstep(outer_across, 0.0, dist_to_line);\nedge_along  = smoothstep(outer_along,  0.0, dist_to_mark);\n\n// the mark: weave's product, commit-weighted intensity, iso-gated\nmark = edge_across * edge_along * (1.0 - iso) * commit;\n\n// compose + encode: luma marks on black (color downstream's job), the only\n// clamp in the module; bypass -> black on both outlets\n// out1 = module OUTLET 0: hatch output (luma marks on black, A=1); color is\n// the tint; the bypass = the module neutral (black) with the outlet contract's\n// alpha 1 preserved (2026-10-17: the first draft multiplied the whole vec by\n// (1-bypass), dropping alpha to 0 under bypass \u2014 against f_tensor_type.md's\n// outlets-are-A=1 rule and the BYPASS_EXPECT row).\nout1 = vec(mix(mark, 0.0, bypass_gate), mix(mark, 0.0, bypass_gate),\n           mix(mark, 0.0, bypass_gate), 1.0);\nout2 = out1;",
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
						30.0,
						480.0,
						216.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_hatch_stage_e3 @type float32",
					"varname": "#0_hatch_stage_e3"
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
						991.5,
						100.0,
						56.0,
						22.0
					],
					"text": "autopattr",
					"varname": "hatch_autopattr"
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
						771.5,
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
						991.5,
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
					"text": "Hatch"
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
						1081.5,
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
						771.5,
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
						771.5,
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
						771.5,
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
						771.5,
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
						771.5,
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
						771.5,
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
					"hint": "Line/cell spacing, log-mapped: pitch = pow(2, density*5-1) (the family formula, f_weave's published span). PROVISIONAL default/lock pending tier-3 (spec OQ6).",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_hatch_stage_e3::density",
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
								0.5
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "density",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
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
					"id": "obj-21",
					"maxclass": "attrui",
					"attr": "density",
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
					"text": "Density",
					"textjustification": 1,
					"varname": "lbl_density"
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
					"hint": "Mark thickness (across-axis half-extent, u units). PROVISIONAL (weave default). Note: the dash-length cap (ADR-9) un-caps as weight falls.",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_hatch_stage_e3::weight",
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
							"parameter_longname": "weight",
							"parameter_mmax": 0.5,
							"parameter_mmin": 0.0,
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
					"id": "obj-24",
					"maxclass": "attrui",
					"attr": "weight",
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
					"text": "Weight",
					"textjustification": 1,
					"varname": "lbl_weight"
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
					"hint": "Edge feather, both axes: expands the multiplicative outer edge (weave's cited form). Clamped at 0.49. PROVISIONAL.",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_hatch_stage_e3::softness",
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
								0.05
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "softness",
							"parameter_mmax": 0.49,
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
					"id": "obj-27",
					"maxclass": "attrui",
					"attr": "softness",
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
					"text": "Softness",
					"textjustification": 1,
					"varname": "lbl_softness"
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
					"hint": "Response-magnitude dial: max aspect of a mark at commit 1 (NOT the shape data -- that is per-pixel commit). Commit 0 = dot (aspect 1) regardless. Pitch-unit aspect caps where dashes merge: at weight 0.1/density 0.5 that is ~elongation 2.1 (ADR-9). PROVISIONAL.",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_hatch_stage_e3::elongation",
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
								3.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "elongation",
							"parameter_mmax": 8.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "elongation",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "elongation"
				}
			},
			{
				"box": {
					"id": "obj-30",
					"maxclass": "attrui",
					"attr": "elongation",
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
					"text": "Elongation",
					"textjustification": 1,
					"varname": "lbl_elongation"
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
					"hint": "Gain the producing tensormap applied to trace and the raw tensor (f_tensor_type.md decode). Match it to the tensormap feeding this module: the decode divides it back out. Log dial like tensormap's.",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_hatch_stage_e1::strength",
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
								100.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "strength",
							"parameter_mmax": 1000.0,
							"parameter_mmin": 1.0,
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
					"id": "obj-33",
					"maxclass": "attrui",
					"attr": "strength",
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
					"text": "Strength",
					"textjustification": 1,
					"varname": "lbl_strength"
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
					"hint": "Commit floor: coherence at/below this renders nothing (the eps_trace guard is separate, below it). PROVISIONAL -- OQ3's gate-floor fallback (dots persist vs fade-in) is shipped as fade-in, tier-3 confirms.",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_hatch_stage_e1::coherence_gate",
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
								0.25
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "coherence_gate",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "coherence_gate",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "coherence_gate"
				}
			},
			{
				"box": {
					"id": "obj-36",
					"maxclass": "attrui",
					"attr": "coherence_gate",
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
					"text": "Gate",
					"textjustification": 1,
					"varname": "lbl_coherence_gate"
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
					"hint": "Rotates the pattern relative to the decoded axis: +-1 = +-90 deg (the axis is an unoriented line, so +-90 spans the distinct layouts). Zero keeps strokes along structure.",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_hatch_stage_e1::angle_offset",
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
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "angle_offset",
							"parameter_mmax": 1.0,
							"parameter_mmin": -1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "angle_offset",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "angle_offset"
				}
			},
			{
				"box": {
					"id": "obj-39",
					"maxclass": "attrui",
					"attr": "angle_offset",
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
					"text": "Offset",
					"textjustification": 1,
					"varname": "lbl_angle_offset"
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
					"hint": "Scrolls marks along the stroke axis (phase 1.0 = one full dash pitch; connect an LFO for motion). Family-standard animation entry.",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_hatch_stage_e3::phase",
					"parameter_enable": 1,
					"patching_rect": [
						550.5,
						250.0,
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
					"id": "obj-42",
					"maxclass": "attrui",
					"attr": "phase",
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
					"text": "Phase",
					"textjustification": 1,
					"varname": "lbl_phase"
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
					"hint": "Per-line dash stagger (weave's hash form): 1 = all lines in phase (grid-like), 0 = fully staggered, hash-stable across frames. PROVISIONAL.",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_hatch_stage_e3::regularity",
					"parameter_enable": 1,
					"patching_rect": [
						622.5,
						250.0,
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
								0.5
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "regularity",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "regularity",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "regularity"
				}
			},
			{
				"box": {
					"id": "obj-45",
					"maxclass": "attrui",
					"attr": "regularity",
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
					"text": "Regularity",
					"textjustification": 1,
					"varname": "lbl_regularity"
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
						991.5,
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
					"id": "obj-48",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						991.5,
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
						"obj-51",
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
						"obj-51",
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
						"obj-51",
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
						"obj-51",
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
						"obj-51",
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
						"obj-51",
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
						"obj-51",
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
						"obj-51",
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
						"obj-51",
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
						"obj-51",
						0
					]
				}
			}
		],
		"parameters": {
			"obj-20": [
				"density",
				"density",
				0
			],
			"obj-23": [
				"weight",
				"weight",
				0
			],
			"obj-26": [
				"softness",
				"softness",
				0
			],
			"obj-29": [
				"elongation",
				"elongation",
				0
			],
			"obj-32": [
				"strength",
				"strength",
				0
			],
			"obj-35": [
				"coherence_gate",
				"coherence_gate",
				0
			],
			"obj-38": [
				"angle_offset",
				"angle_offset",
				0
			],
			"obj-41": [
				"phase",
				"phase",
				0
			],
			"obj-44": [
				"regularity",
				"regularity",
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