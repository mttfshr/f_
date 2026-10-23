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
					"comment": "obstacle mask (white = obstacle)",
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
					"comment": "velocity vecfield",
					"index": 0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						30.0,
						702.0,
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
					"numoutlets": 5,
					"outlettype": [
						"",
						"",
						"",
						"",
						""
					],
					"patching_rect": [
						56.5,
						204.0,
						367.0,
						22.0
					],
					"text": "route omega inflow tilt gain speed"
				}
			},
			{
				"box": {
					"id": "obj-50",
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
									"code": "// codebox_hold.gen -- f_vf_lbm: the loop break and one-frame delay of the state atlas (the f_vf_fluid / f_ks\n// hold idiom). An identity pass over the 192x324 state atlas.\n//\n// Inlets (outer order): first = the frame gate's bang (hot; unused in the code, it only triggers the render on every\n// Nth frame), second = the state atlas from the stream stage (cold). The collide stage is triggered by this stage's\n// output, so the whole loop advances once per gated frame and the feedback never retriggers itself. Not benched on\n// its own (an identity); the live module bench covers it.\nout1 = nearest(in2, norm);\n",
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
						380.0,
						200.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_lbm_hold @adapt 0 @dim 192 324 @type float32",
					"varname": "#0_lbm_hold"
				}
			},
			{
				"box": {
					"id": "obj-51",
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
									"code": "// codebox_collide.gen -- f_vf_lbm stage 1: the fused local pass. ONE 192x324 float32 texture out (the state atlas).\n// Mirror: tests/modules/vf_lbm/vf_lbm_mirror.fuse_local() (same order, same formulas).\n//\n// STATE ATLAS (FR-001, revised 2026-10-21): the three RGBA state planes are stacked vertically in one texture,\n// 192 wide x 324 tall: rows 0..107 = plane 1 (populations 0..3 in RGBA), rows 108..215 = plane 2 (populations\n// 4..7), rows 216..323 = plane 3 (population 8 in R, the rest 0). Why one texture: a pix with several outlets\n// feeding one hot and several cold inlets depends on the ORDER its outlets fire, which Max does not document for\n// jit.gl.pix. A planes-in-three-textures chain that fired in the wrong order would step with planes from\n// different frames (a non-conservative scheme: noise in a perfectly uniform channel, found live 2026-10-21).\n// One texture has one hot inlet and nothing to order.\n// Each output texel recomputes the whole collision for its lattice cell (x, y) = (column, row mod 108) and\n// writes the four values its plane holds (3x the arithmetic, which is trivial at this size).\n// D2Q9 order: 0 rest; 1 (1,0); 2 (0,1); 3 (-1,0); 4 (0,-1); 5 (1,1); 6 (-1,1); 7 (-1,-1); 8 (1,-1).\n//\n// Inlets (outer order): first = the state atlas from the hold stage (hot: it triggers this render),\n// second = the obstacle mask at render resolution (cold, from the module inlet).\n// The write order below is the experiment's: pre-collision copy, outflow copy, macro, inflow, equilibrium,\n// right-population overwrite, BGK collision, bounce-back.\n//   - SEED / SELF-HEAL: a cell whose held populations are not all finite, whose density is outside (0.2, 5) or\n//     whose rest population is not above 0.05 (a fresh module, a rebuilt GL context, a poisoned or blown-up\n//     texel) restarts at equilibrium with rho = 1, u = inflow, plus a tiny sideways ripple\n//     (0.02 * inflow * sin(0.3 x)) that lets the wake break symmetry sooner. The rest-population test also\n//     rejects an empty inlet, which reads (0, 0, 0, 1). Selection uses switch(), never mix(): mix(NaN, x, 1) is\n//     still NaN.\n//   - PRE-COLLISION (FR-003): the bounce-back reads the cell's populations as held at the start of the frame,\n//     before the outflow copy and before collision (the experiment's f_prev).\n//   - OUTFLOW (last column): the three leftward populations copy from the column to the left (zero gradient).\n//   - INFLOW (first column): ux = inflow * cos(tilt) and uy = inflow * sin(tilt) (tilt in degrees, clamped to\n//     +-30, default 0 = straight wind) on the interior rows FIRST, then the Zou/He density\n//     rho = (rest + 2 * leftward) / (1 - ux); the rightward populations take the equilibrium (FR-005).\n//     y is periodic (decided 2026-10-21), so the top and bottom rows are ordinary rows.\n//   - MASK: luma (0.299 R + 0.587 G + 0.114 B) averaged over a 4 x 4 grid of nearest taps across the cell's\n//     footprint (exact at 1:1, a box filter when the mask is larger), obstacle where above 0.5. The first and last\n//     columns are never obstacle (T014 default: shield the edge columns). An unconnected mask reads black.\n//   - omega is clamped to [0.5, 1.98] and inflow to [0, 0.1]: the measured stability ceiling (FR-007)\n//   - components are read inline on nearest(), never from a stored vec\nfe(wt, lx, ly, r0, vx, vy) {\n  eu = lx * vx + ly * vy;\n  return wt * r0 * (1 + 3 * eu + 4.5 * eu * eu - 1.5 * (vx * vx + vy * vy));\n}\nfin(x) {\n  return switch(abs(x) < 1e30, 1, 0);\n}\nvv(j, y) {\n  return (j * 108 + y + 0.5) / 324;\n}\n\nParam omega(1.97);\nParam inflow(0.08);\nParam tilt(0);\n\nW = 192;\nH = 108;\npx = floor(norm.x * W);\nyt = floor(norm.y * 324);\nkp = floor(yt / 108);\npy = yt - kp * 108;\ncu = (px + 0.5) / W;\num = (px - 0.5) / W;\npc0 = vec(cu, vv(0, py));\npc1 = vec(cu, vv(1, py));\npc2 = vec(cu, vv(2, py));\npm0 = vec(um, vv(0, py));\npm1 = vec(um, vv(1, py));\n\nom = min(max(omega, 0.5), 1.98);\nu0 = min(max(inflow, 0), 0.1);\nth = min(max(tilt, -30), 30) * 0.0174532925199;\nis_in = switch(px < 0.5, 1, 0);\nis_out = switch(px > W - 1.5, 1, 0);\nis_row = switch(py > 0.5, 1, 0) * switch(py < H - 1.5, 1, 0);\n\n// the held state of this cell\nb0 = nearest(in1, pc0).x;\nb1 = nearest(in1, pc0).y;\nb2 = nearest(in1, pc0).z;\nb3 = nearest(in1, pc0).w;\nb4 = nearest(in1, pc1).x;\nb5 = nearest(in1, pc1).y;\nb6 = nearest(in1, pc1).z;\nb7 = nearest(in1, pc1).w;\nb8 = nearest(in1, pc2).x;\nallfin = fin(b0) * fin(b1) * fin(b2) * fin(b3) * fin(b4) * fin(b5) * fin(b6) * fin(b7) * fin(b8);\nrb = b0 + b1 + b2 + b3 + b4 + b5 + b6 + b7 + b8;\nvalid = allfin * switch(rb > 0.2, 1, 0) * switch(rb < 5, 1, 0) * switch(b0 > 0.05, 1, 0);\nuse_seed = switch(valid >= 0.5, 0, 1);\n\n// the pre-collision populations, seeded where the state is invalid\nripple = 0.02 * u0 * sin(0.3 * px);\na0 = switch(use_seed >= 0.5, fe(0.444444444444, 0, 0, 1, u0, ripple), b0);\na1 = switch(use_seed >= 0.5, fe(0.111111111111, 1, 0, 1, u0, ripple), b1);\na2 = switch(use_seed >= 0.5, fe(0.111111111111, 0, 1, 1, u0, ripple), b2);\na3 = switch(use_seed >= 0.5, fe(0.111111111111, 0 - 1, 0, 1, u0, ripple), b3);\na4 = switch(use_seed >= 0.5, fe(0.111111111111, 0, 0 - 1, 1, u0, ripple), b4);\na5 = switch(use_seed >= 0.5, fe(0.0277777777778, 1, 1, 1, u0, ripple), b5);\na6 = switch(use_seed >= 0.5, fe(0.0277777777778, 0 - 1, 1, 1, u0, ripple), b6);\na7 = switch(use_seed >= 0.5, fe(0.0277777777778, 0 - 1, 0 - 1, 1, u0, ripple), b7);\na8 = switch(use_seed >= 0.5, fe(0.0277777777778, 1, 0 - 1, 1, u0, ripple), b8);\n\n// outflow: the leftward populations of the last column copy from the column to its left\ncp = is_out * (1 - use_seed);\nf0 = a0;\nf1 = a1;\nf2 = a2;\nf3 = switch(cp >= 0.5, nearest(in1, pm0).w, a3);\nf4 = a4;\nf5 = a5;\nf6 = switch(cp >= 0.5, nearest(in1, pm1).z, a6);\nf7 = switch(cp >= 0.5, nearest(in1, pm1).w, a7);\nf8 = a8;\n\n// macro quantities\nrho = f0 + f1 + f2 + f3 + f4 + f5 + f6 + f7 + f8;\nux = (f1 - f3 + f5 - f6 - f7 + f8) / rho;\nuy = (f2 - f4 + f5 + f6 - f7 - f8) / rho;\n\n// inflow: prescribe the velocity on the interior rows, then the Zou/He density\nset_u = is_in * is_row;\nux2 = switch(set_u >= 0.5, u0 * cos(th), ux);\nuy2 = switch(set_u >= 0.5, u0 * sin(th), uy);\nrho_in = (f0 + f2 + f4 + 2 * (f3 + f6 + f7)) / (1 - ux2);\nrho2 = switch(is_in >= 0.5, rho_in, rho);\n\n// equilibrium\nq0 = fe(0.444444444444, 0, 0, rho2, ux2, uy2);\nq1 = fe(0.111111111111, 1, 0, rho2, ux2, uy2);\nq2 = fe(0.111111111111, 0, 1, rho2, ux2, uy2);\nq3 = fe(0.111111111111, 0 - 1, 0, rho2, ux2, uy2);\nq4 = fe(0.111111111111, 0, 0 - 1, rho2, ux2, uy2);\nq5 = fe(0.0277777777778, 1, 1, rho2, ux2, uy2);\nq6 = fe(0.0277777777778, 0 - 1, 1, rho2, ux2, uy2);\nq7 = fe(0.0277777777778, 0 - 1, 0 - 1, rho2, ux2, uy2);\nq8 = fe(0.0277777777778, 1, 0 - 1, rho2, ux2, uy2);\n\n// inflow column: the rightward populations take the equilibrium\ng1 = switch(is_in >= 0.5, q1, f1);\ng5 = switch(is_in >= 0.5, q5, f5);\ng8 = switch(is_in >= 0.5, q8, f8);\n\n// BGK collision\nc0 = f0 + om * (q0 - f0);\nc1 = g1 + om * (q1 - g1);\nc2 = f2 + om * (q2 - f2);\nc3 = f3 + om * (q3 - f3);\nc4 = f4 + om * (q4 - f4);\nc5 = g5 + om * (q5 - g5);\nc6 = f6 + om * (q6 - f6);\nc7 = f7 + om * (q7 - f7);\nc8 = g8 + om * (q8 - g8);\n\n// the obstacle mask, averaged over the cell's footprint; the edge columns are never obstacle\ncv = (py + 0.5) / H;\nmsum = 0;\nfor (ta = 0; ta < 4; ta += 1) {\n  ox = ((ta + 0.5) / 4 - 0.5) / W;\n  for (tb = 0; tb < 4; tb += 1) {\n    oy = ((tb + 0.5) / 4 - 0.5) / H;\n    msum += nearest(in2, vec(cu + ox, cv + oy)).x * 0.299 + nearest(in2, vec(cu + ox, cv + oy)).y * 0.587 + nearest(in2, vec(cu + ox, cv + oy)).z * 0.114;\n  }\n}\nm = switch(msum / 16 > 0.5, 1, 0) * (1 - is_in) * (1 - is_out);\n\n// bounce-back: inside the obstacle every population becomes the pre-collision opposite one\nn0 = switch(m >= 0.5, a0, c0);\nn1 = switch(m >= 0.5, a3, c1);\nn2 = switch(m >= 0.5, a4, c2);\nn3 = switch(m >= 0.5, a1, c3);\nn4 = switch(m >= 0.5, a2, c4);\nn5 = switch(m >= 0.5, a7, c5);\nn6 = switch(m >= 0.5, a8, c6);\nn7 = switch(m >= 0.5, a5, c7);\nn8 = switch(m >= 0.5, a6, c8);\n\n// write the plane this output texel belongs to (0: populations 0..3, 1: populations 4..7, 2: population 8)\no0 = switch(kp < 0.5, n0, switch(kp < 1.5, n4, n8));\no1 = switch(kp < 0.5, n1, switch(kp < 1.5, n5, 0));\no2 = switch(kp < 0.5, n2, switch(kp < 1.5, n6, 0));\no3 = switch(kp < 0.5, n3, switch(kp < 1.5, n7, 0));\nout1 = vec(o0, o1, o2, o3);\n",
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
					"text": "jit.gl.pix vsynth @name #0_lbm_collide @adapt 0 @dim 192 324 @type float32",
					"varname": "#0_lbm_collide"
				}
			},
			{
				"box": {
					"id": "obj-52",
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
									"code": "// codebox_stream.gen -- f_vf_lbm stage 2: the streaming gather. ONE 192x324 float32 state atlas in and out.\n// Mirror: tests/modules/vf_lbm/vf_lbm_mirror.stream() (new[x] = old[x - e_i], FR-004).\n//\n// The atlas stacks the three state planes vertically (see codebox_collide.gen): plane 1 = rows 0..107 (populations\n// 0..3 in RGBA), plane 2 = rows 108..215 (4..7), plane 3 = rows 216..323 (population 8 in R).\n// Population i of a cell is population i of the cell UPSTREAM, at x - e_i (the spike's trap #1: reading at\n// x + e_i would reverse the flow, invisible until an obstacle is present). The reads use explicit periodic\n// cell indices through wrap() and texel-centre nearest() taps, so they are exact and do not depend on how\n// sample() treats out-of-range coordinates (the periodic seam in x is overwritten by the boundary branches in\n// the collide stage, exactly as the mirror's np.roll-equivalent wrap is). Each output texel gathers all nine\n// populations for its cell and writes the four its plane holds.\n//   D2Q9: 0 rest; 1 (1,0); 2 (0,1); 3 (-1,0); 4 (0,-1); 5 (1,1); 6 (-1,1); 7 (-1,-1); 8 (1,-1)\nvv(j, y) {\n  return (j * 108 + y + 0.5) / 324;\n}\n\nW = 192;\nH = 108;\npx = floor(norm.x * W);\nyt = floor(norm.y * 324);\nkp = floor(yt / 108);\npy = yt - kp * 108;\ncxc = (px + 0.5) / W;\ncxm = (wrap(px - 1, 0, W) + 0.5) / W;\ncxp = (wrap(px + 1, 0, W) + 0.5) / W;\nym = wrap(py - 1, 0, H);\nyp = wrap(py + 1, 0, H);\n\nn0 = nearest(in1, vec(cxc, vv(0, py))).x;\nn1 = nearest(in1, vec(cxm, vv(0, py))).y;\nn2 = nearest(in1, vec(cxc, vv(0, ym))).z;\nn3 = nearest(in1, vec(cxp, vv(0, py))).w;\nn4 = nearest(in1, vec(cxc, vv(1, yp))).x;\nn5 = nearest(in1, vec(cxm, vv(1, ym))).y;\nn6 = nearest(in1, vec(cxp, vv(1, ym))).z;\nn7 = nearest(in1, vec(cxp, vv(1, yp))).w;\nn8 = nearest(in1, vec(cxm, vv(2, yp))).x;\n\no0 = switch(kp < 0.5, n0, switch(kp < 1.5, n4, n8));\no1 = switch(kp < 0.5, n1, switch(kp < 1.5, n5, 0));\no2 = switch(kp < 0.5, n2, switch(kp < 1.5, n6, 0));\no3 = switch(kp < 0.5, n3, switch(kp < 1.5, n7, 0));\nout1 = vec(o0, o1, o2, o3);\n",
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
						480.0,
						200.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_lbm_stream @adapt 0 @dim 192 324 @type float32",
					"varname": "#0_lbm_stream"
				}
			},
			{
				"box": {
					"id": "obj-53",
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
									"code": "// codebox_mac.gen -- f_vf_lbm: macro quantities from the streamed state atlas. Output 192x108 float32.\n// Mirror: the macro() step of vf_lbm_mirror.encode().\n//\n// Input: the 192x324 state atlas (three planes stacked vertically, see codebox_collide.gen); output: one texel per\n// lattice cell. R = ux, G = uy (lattice units), B = rho, A = 1. Non-finite values map to 0 (abs(x) < 1e30 guard:\n// NaN == NaN is TRUE on this GPU), and the density is floored at 1e-6 for the divide, so nothing non-finite\n// reaches the encode. Keeping this at the solver size means the render-resolution encode stage reads two values\n// per tap, not nine populations. rho is carried for later derived outputs (not used in v1).\nvv(j, y) {\n  return (j * 108 + y + 0.5) / 324;\n}\n\nW = 192;\nH = 108;\npx = floor(norm.x * W);\npy = floor(norm.y * H);\ncu = (px + 0.5) / W;\n\nf0 = nearest(in1, vec(cu, vv(0, py))).x;\nf1 = nearest(in1, vec(cu, vv(0, py))).y;\nf2 = nearest(in1, vec(cu, vv(0, py))).z;\nf3 = nearest(in1, vec(cu, vv(0, py))).w;\nf4 = nearest(in1, vec(cu, vv(1, py))).x;\nf5 = nearest(in1, vec(cu, vv(1, py))).y;\nf6 = nearest(in1, vec(cu, vv(1, py))).z;\nf7 = nearest(in1, vec(cu, vv(1, py))).w;\nf8 = nearest(in1, vec(cu, vv(2, py))).x;\n\nrho = f0 + f1 + f2 + f3 + f4 + f5 + f6 + f7 + f8;\nrs = max(rho, 0.000001);\nux = (f1 - f3 + f5 - f6 - f7 + f8) / rs;\nuy = (f2 - f4 + f5 + f6 - f7 - f8) / rs;\nux = switch(abs(ux) < 1e30, ux, 0);\nuy = switch(abs(uy) < 1e30, uy, 0);\nrho = switch(abs(rho) < 1e30, rho, 0);\nout1 = vec(ux, uy, rho, 1);\n",
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
						530.0,
						200.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_lbm_mac @adapt 0 @dim 192 108 @type float32",
					"varname": "#0_lbm_mac"
				}
			},
			{
				"box": {
					"id": "obj-54",
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
									"code": "// codebox_mprev.gen -- f_vf_lbm: the previous solver velocity, for the Speed blend. 192x108 float32.\n// An identity copy of the mac texture, triggered by the frame gate just BEFORE the solver steps (a trigger\n// fans out right to left), so it holds the velocity from the previous step while mac renders the new one.\n// Inlets: first = the gated bang (hot, unused in the code), second = the mac texture (cold).\nout1 = nearest(in2, norm);\n",
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
						580.0,
						200.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_lbm_mprev @adapt 0 @dim 192 108 @type float32",
					"varname": "#0_lbm_mprev"
				}
			},
			{
				"box": {
					"id": "obj-5",
					"maxclass": "newobj",
					"numinlets": 3,
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
									"code": "// codebox_enc.gen -- f_vf_lbm: upsample the 192x108 velocity to the render size, apply gain, clamp, encode as an\n// f_vecfield (RG = XY, 0.5 = zero, B = 0.5, A = 1) and apply the bypass gate. Runs at RENDER resolution.\n// Mirror: tests/modules/vf_lbm/vf_lbm_mirror.encode() (at the solver size this is exactly that function).\n//\n// Inlets: first = `r draw` bang (unused; it triggers every frame and gives this pix the render-context size),\n// second = the macro texture (R = ux, G = uy) from the mac stage, third = the previous step's macro texture\n// from the mprev stage.\n//   - SPEED BLEND: the velocity shown is mix(previous, current, phase / nsteps). The frame gate sends phase = 1..N\n//     (the frame within the current solver step) and nsteps = N, so at Speed 1/N the output moves smoothly\n//     between solver steps (about N frames behind). Defaults phase 1, nsteps 1: the current velocity only.\n//   - FR-008: R = clamp(0.5 + gain * ux, 0, 1), G likewise with uy. The velocity is in lattice units\n//     (inflow up to 0.1), so the default gain of 3 puts the free stream near 0.74 and keeps the faster flow\n//     around the obstacle inside the range (gain 1 would sit within 0.05 of the centre).\n//   - the upsample is a manual 4-tap bilinear on texel-centre nearest() taps: y periodic (the solver's y is\n//     periodic), x clamped to the end columns (the channel is not periodic in x). An edge feather (outer 3\n//     columns copied from the inner neighbour) was tried 2026-10-21 and REMOVED the same day: it smeared the\n//     noisy inner column into horizontal streak bands and did not contain the jitter, which reaches 7+ columns in\n//     from the left edge while Wind is swept down.\n//   - a non-finite sample encodes as zero velocity (abs(x) < 1e30 guard), so no NaN or Inf reaches the outlet\n//   - bypass_gate = 1 outputs an exactly neutral field (zero velocity). The solver keeps running upstream.\n//     The Param is never named `bypass` (native pix attribute).\nvxm(u, v, w) {\n  return mix(nearest(in3, vec(u, v)).x, nearest(in2, vec(u, v)).x, w);\n}\nvym(u, v, w) {\n  return mix(nearest(in3, vec(u, v)).y, nearest(in2, vec(u, v)).y, w);\n}\n\nParam gain(3);\nParam bypass_gate(0);\nParam phase(1);\nParam nsteps(1);\n\nW = 192;\nH = 108;\nbw = clamp(phase / max(nsteps, 1), 0, 1);\nfx = norm.x * W - 0.5;\nfy = norm.y * H - 0.5;\nx0 = floor(fx);\ny0 = floor(fy);\ntx = fx - x0;\nty = fy - y0;\nxa = (min(max(x0, 0), W - 1) + 0.5) / W;\nxb = (min(max(x0 + 1, 0), W - 1) + 0.5) / W;\nya = (wrap(y0, 0, H) + 0.5) / H;\nyb = (wrap(y0 + 1, 0, H) + 0.5) / H;\nau = mix(mix(vxm(xa, ya, bw), vxm(xb, ya, bw), tx), mix(vxm(xa, yb, bw), vxm(xb, yb, bw), tx), ty);\nav = mix(mix(vym(xa, ya, bw), vym(xb, ya, bw), tx), mix(vym(xa, yb, bw), vym(xb, yb, bw), tx), ty);\nau = switch(abs(au) < 1e30, au, 0);\nav = switch(abs(av) < 1e30, av, 0);\n\nr = clamp(0.5 + gain * au, 0, 1);\ng = clamp(0.5 + gain * av, 0, 1);\nout1 = vec(mix(r, 0.5, bypass_gate), mix(g, 0.5, bypass_gate), 0.5, 1);\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
									"id": "gen-obj-2",
									"maxclass": "codebox",
									"numinlets": 3,
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
							}
						]
					},
					"patching_rect": [
						30.0,
						630.0,
						200.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_lbm_enc @adapt 1 @type float32",
					"varname": "#0_lbm_enc"
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
					"varname": "vflbm_autopattr"
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
						197.0,
						110.0
					],
					"presentation": 1,
					"presentation_rect": [
						0.0,
						0.0,
						197.0,
						110.0
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
						10.5,
						0.0,
						110.0,
						21.0
					],
					"text": "Lattice Boltzmann"
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
						1070.0,
						200.0,
						60.0,
						21.0
					],
					"presentation": 1,
					"presentation_rect": [
						101.0,
						0.9,
						70.0,
						21.0
					],
					"text": "\u2207 out"
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
						980.0,
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
						1000.0,
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
					"id": "obj-20",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "BGK relaxation rate: low = thick and smooth, high = thin and turbulent. The top of the range is the stability limit",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_lbm_collide::omega",
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
								1.97
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "omega",
							"parameter_mmax": 1.98,
							"parameter_mmin": 1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "omega",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "omega"
				}
			},
			{
				"box": {
					"id": "obj-21",
					"maxclass": "attrui",
					"attr": "omega",
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
					"text": "Omega",
					"textjustification": 1,
					"varname": "lbl_omega"
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
					"hint": "Inflow speed in lattice units. Shedding is clean from about 0.06 up and needs a few thousand frames to start. Wind 0 stops the inflow but not the flow already moving (lower Omega to calm it). The top of the range (0.1) with Omega near 1.98 pushes local speeds past Mach 0.3",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_lbm_collide::inflow",
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
								0.08
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "inflow",
							"parameter_mmax": 0.1,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "inflow",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "inflow"
				}
			},
			{
				"box": {
					"id": "obj-24",
					"maxclass": "attrui",
					"attr": "inflow",
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
					"text": "Wind",
					"textjustification": 1,
					"varname": "lbl_inflow"
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
					"hint": "Wind direction in degrees: 0 = straight left to right, positive = the wind blows toward the top. The speed stays Wind (it is split into x and y parts); the flow still enters through the left edge and wraps top to bottom. Large angles are less accurate",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_lbm_collide::tilt",
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
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "tilt",
							"parameter_mmax": 30.0,
							"parameter_mmin": -30.0,
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
					"id": "obj-27",
					"maxclass": "attrui",
					"attr": "tilt",
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
					"text": "Tilt",
					"textjustification": 1,
					"varname": "lbl_tilt"
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
					"hint": "Output scale applied to the velocity before encoding (clamped to the vecfield range)",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_lbm_enc::gain",
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
							"parameter_longname": "gain",
							"parameter_mmax": 10.0,
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
					"id": "obj-30",
					"maxclass": "attrui",
					"attr": "gain",
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
					"text": "Gain",
					"textjustification": 1,
					"varname": "lbl_gain"
				}
			},
			{
				"box": {
					"id": "obj-32",
					"maxclass": "live.menu",
					"fontname": "Ableton Sans Light",
					"hint": "How fast the flow evolves: the solver advances on every frame (Full), every 2nd, 3rd or 4th. Slower = the same wake in slow motion. The output holds its last state in between",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"",
						"",
						"float"
					],
					"param_connect": "#0_lbm_enc::speed",
					"parameter_enable": 1,
					"patching_rect": [
						318.0,
						250.0,
						60.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						148.0,
						52.0,
						45.0,
						15.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_enum": [
								"Full",
								"1/2",
								"1/3",
								"1/4"
							],
							"parameter_initial": [
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "speed",
							"parameter_mmax": 3.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 0,
							"parameter_shortname": "speed",
							"parameter_type": 2,
							"parameter_unitstyle": 0
						}
					},
					"varname": "speed"
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
					"text": "Speed",
					"textjustification": 1,
					"varname": "lbl_speed"
				}
			},
			{
				"box": {
					"id": "obj-35",
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
						175.0,
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
					"id": "obj-36",
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
			},
			{
				"box": {
					"id": "obj-raw-1",
					"maxclass": "newobj",
					"patching_rect": [
						30.0,
						792.0,
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
						30.0,
						822.0,
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
					"id": "obj-raw-3",
					"maxclass": "newobj",
					"patching_rect": [
						80.0,
						852.0,
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
					"id": "obj-raw-4",
					"maxclass": "newobj",
					"patching_rect": [
						130.0,
						882.0,
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
					"id": "obj-raw-5",
					"maxclass": "newobj",
					"patching_rect": [
						130.0,
						912.0,
						30.0,
						22.0
					],
					"text": "% 1",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"int"
					]
				}
			},
			{
				"box": {
					"id": "obj-raw-6",
					"maxclass": "newobj",
					"patching_rect": [
						80.0,
						882.0,
						40.0,
						22.0
					],
					"text": "sel 0",
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
					"id": "obj-raw-7",
					"maxclass": "newobj",
					"patching_rect": [
						80.0,
						912.0,
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
					"id": "obj-raw-8",
					"maxclass": "newobj",
					"patching_rect": [
						200.0,
						882.0,
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
					"id": "obj-raw-9",
					"maxclass": "newobj",
					"patching_rect": [
						130.0,
						942.0,
						130.0,
						22.0
					],
					"text": "prepend param phase",
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
						200.0,
						912.0,
						140.0,
						22.0
					],
					"text": "prepend param nsteps",
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
						"obj-51",
						1
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
						"obj-52",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-52",
						0
					],
					"destination": [
						"obj-50",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-52",
						0
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
						"obj-5",
						1
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
						1
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
						"obj-5",
						2
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
						1
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
						"obj-raw-2",
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
						"obj-raw-3",
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
						"obj-raw-3",
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
						1
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
						"obj-raw-7",
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
						"obj-32",
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
						"obj-raw-5",
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
						"obj-5",
						0
					]
				}
			}
		],
		"parameters": {
			"obj-20": [
				"omega",
				"omega",
				0
			],
			"obj-23": [
				"inflow",
				"inflow",
				0
			],
			"obj-26": [
				"tilt",
				"tilt",
				0
			],
			"obj-29": [
				"gain",
				"gain",
				0
			],
			"obj-32": [
				"speed",
				"speed",
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