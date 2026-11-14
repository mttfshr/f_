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
					"comment": "texture",
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
					"numoutlets": 18,
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
						"",
						"",
						"",
						""
					],
					"patching_rect": [
						56.5,
						204.0,
						1303.0,
						22.0
					],
					"text": "route screen plate_mode pitch softness dot_shape jitter seed level bayer_scale angle_r angle_g angle_b phase_r_x phase_r_y phase_g_x phase_g_y phase_b_x phase_b_y"
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
									"code": "// codebox_halftone.gen -- f_halftone: the one stage. Tone to marks on a fixed-angle lattice, one plate per color channel.\n// Stateless, per pixel. Float32. Mirror: tests/modules/halftone/halftone_mirror.halftone_stage() (the conventions in its\n// docstring are the ones followed here). T020: Dot and Line, soft edge, exact extremes, zap, bypass, alpha; the per-plate\n// phase (FR-016) is in because it is part of the lattice formula. 2026-11-14: shape (T023), jitter (T024), Threshold and\n// Bayer (T025), the Single plate mode (T016b).\n//\n// Lattice (plan ADR-1): p = ((u - .5) * aspect, v - .5) in frame heights; q = R(-angle) p / pitch - phase;\n//   lattice cell = floor(q + .5), local f = q - that, in [-.5, .5]^2.\n// Spot functions (ADR-2): Dot T = A(r), the area of the radius-r circle inside the unit cell; Line T = 2 |f_y|.\n//   dot_shape (T023, Dot only; a Param named `shape` never received its value on the bench, 2026-11-14) morphs round to square: T = mix(A(r), (2 max(|f_x|, |f_y|))^2, shape), the slope likewise.\n// Soft edge (ADR-3): coverage = clamp(.5 + (tone - T) / w, 0, 1), w = max(softness / 2, aa) * |dT/dd|,\n//   aa = 1 / (pitch in texels); then tone <= 0 gives exactly 0 and tone >= 1 exactly 1.\n// Tone (ADR-4): ONE nearest read per plate at a texel centre: Dot at the lattice cell's centre, Line at the pixel's own\n//   position along its centreline row. The reads are in the main body, the tone is passed to the functions (gate G8).\n// Jitter (ADR-5, Dot only): each cell centre moves by jitter * .5 * (hash - .5) cells (the sin hash, seeded); the nine cells\n//   around the pixel are tested and the largest coverage wins; the tone is read at each displaced centre. jitter 0 takes the\n//   one-cell path, so the regular lattice is exactly the T020 one.\n// Threshold (ADR-6): smoothstep(level - w, level + w, tone), w = softness / 2 (a hard step at softness 0), per pixel.\n// Bayer: the 8 x 8 ordered matrix by texel, M = sum over bits b of 4^(2-b) (2 (x_b xor y_b) + y_b); lit where tone > (M + .5) / 64.\n//   bayer_scale (Matt, 2026-11-14): whole pixels per matrix cell, rounded, at least 1; the tone stays per pixel.\n// Single plate (T016b, plate_mode 1; spec \"Plates from f_separate\"): the whole texture is ONE plate at angle_b and phase_b.\n//   Its tone is the brightest channel, t = max(r, g, b), at the read texel; the colour is rgb / t there (black when t <= 0); the\n//   output is that colour times the coverage. The colour texel is the one the tone came from: the cell centre (displaced when\n//   jittered) for Dot, the centreline point for Line, the pixel's own for Threshold and Bayer.\n// screen: 0 = Dot, 1 = Line, 2 = Threshold, 3 = Bayer. Angles in degrees. bypass_gate = 1: the (zapped) source.\n// Non-finite input is zapped to 0: abs(x) < 1e30 with switch() (NaN == NaN is TRUE on this GPU).\n// The render size comes from the Params `width` and `height` (render_dim; the size global reads 1 inside a live Vsynth pix,\n// build/spec.md). A bench job must set both to the output's size.\nzap(xv) {\n    return switch(abs(xv) < 1e30, xv, 0);\n}\n\n// cos and sin of exact quarter turns come out as 1e-8, not 0: snap, so 0 and 90 degrees sit on the pixel grid (G6)\nsnap0(xv) {\n    return switch(abs(xv) < 0.000001, 0, xv);\n}\n\narea_round(rad) {\n    rc = min(rad, 0.70710678);\n    inner = pi * rc * rc;\n    ac = acos(clamp(1 / (2 * max(rc, 0.000001)), 0, 1));\n    seg = rc * rc * ac - 0.5 * sqrt(max(rc * rc - 0.25, 0));\n    area = switch(rc > 0.5, inner - 4 * seg, inner);\n    return switch(rad >= 0.70710678, 1, area);\n}\n\narea_slope(rad) {\n    rc = min(rad, 0.70710678);\n    ac = acos(clamp(1 / (2 * max(rc, 0.000001)), 0, 1));\n    slp = switch(rc <= 0.5, twopi * rc, rc * (twopi - 8 * ac));\n    return switch(rad >= 0.70710678, 0, slp);\n}\n\n// lattice coordinates of the position (px, py)\nlat_xy(px, py, cs, sn, pit, phx, phy) {\n    return (cs * px + sn * py) / pit - phx, (cs * py - sn * px) / pit - phy;\n}\n\n// where the plate's tone is read: normalized coordinates of a texel centre, clamped to the frame\nread_uv(qx, qy, is_line, cs, sn, pit, phx, phy, asp, wd, ht) {\n    xx = switch(is_line > 0.5, qx, floor(qx + 0.5)) + phx;\n    yy = floor(qy + 0.5) + phy;\n    ppx = (cs * xx - sn * yy) * pit;\n    ppy = (sn * xx + cs * yy) * pit;\n    ti = clamp(floor((ppx / asp + 0.5) * wd), 0, wd - 1);\n    tj = clamp(floor((ppy + 0.5) * ht), 0, ht - 1);\n    return (ti + 0.5) / wd, (tj + 0.5) / ht;\n}\n\n// coverage at local lattice coordinates (fx, fy) relative to a mark's centre\ncover_local(fx, fy, is_line, tone, soft, aa, shp) {\n    rad = sqrt(fx * fx + fy * fy);\n    sq = max(abs(fx), abs(fy));\n    thr_dot = mix(area_round(rad), 4 * sq * sq, shp);\n    slp_dot = mix(area_slope(rad), 8 * sq, shp);\n    thr = switch(is_line > 0.5, 2 * abs(fy), thr_dot);\n    slp = switch(is_line > 0.5, 2, slp_dot);\n    wid = max(soft * 0.5, aa) * max(abs(slp), 0.000001);\n    cov = clamp(0.5 + (tone - thr) / wid, 0, 1);\n    return switch(tone <= 0, 0, switch(tone >= 1, 1, cov));\n}\n\ncover(qx, qy, is_line, tone, soft, aa, shp) {\n    return cover_local(qx - floor(qx + 0.5), qy - floor(qy + 0.5), is_line, tone, soft, aa, shp);\n}\n\n// the zapped tone at a texel centre: ch 0 r, 1 g, 2 b, 3 the brightest of the three (Single)\nrd(ru, rv, ch) {\n    tx = zap(nearest(in1, vec(ru, rv)).x);\n    ty = zap(nearest(in1, vec(ru, rv)).y);\n    tz = zap(nearest(in1, vec(ru, rv)).z);\n    return switch(ch < 0.5, tx, switch(ch < 1.5, ty, switch(ch < 2.5, tz, max(max(tx, ty), tz))));\n}\n\n// T016b: the read texel of the pixel's own cell centre, displaced by the jitter (the Single colour under jitter)\njit_uv(qx, qy, cs, sn, pit, phx, phy, asp, wd, ht, jit, sd) {\n    nx = floor(qx + 0.5);\n    ny = floor(qy + 0.5);\n    hx = fract(sin(nx * 127.1 + ny * 311.7 + sd * 74.7) * 43758.5453);\n    hy = fract(sin(nx * 269.5 + ny * 183.3 + sd * 246.1) * 43758.5453);\n    xx = nx + jit * 0.5 * (hx - 0.5) + phx;\n    yy = ny + jit * 0.5 * (hy - 0.5) + phy;\n    ppx = (cs * xx - sn * yy) * pit;\n    ppy = (sn * xx + cs * yy) * pit;\n    ti = clamp(floor((ppx / asp + 0.5) * wd), 0, wd - 1);\n    tj = clamp(floor((ppy + 0.5) * ht), 0, ht - 1);\n    return (ti + 0.5) / wd, (tj + 0.5) / ht;\n}\n\n// T024: the jittered Dot. ch picks the plate's channel (0 r, 1 g, 2 b, 3 the brightest: Single). Reads inside a function and a loop are exact (T010).\ndot_jit(qx, qy, ch, cs, sn, pit, phx, phy, asp, wd, ht, soft, aa, shp, jit, sd) {\n    cx = floor(qx + 0.5);\n    cy = floor(qy + 0.5);\n    best = 0;\n    for (j = 0; j < 3; j += 1) {\n        for (i = 0; i < 3; i += 1) {\n            nx = cx + i - 1;\n            ny = cy + j - 1;\n            hx = fract(sin(nx * 127.1 + ny * 311.7 + sd * 74.7) * 43758.5453);\n            hy = fract(sin(nx * 269.5 + ny * 183.3 + sd * 246.1) * 43758.5453);\n            gx = nx + jit * 0.5 * (hx - 0.5);\n            gy = ny + jit * 0.5 * (hy - 0.5);\n            xx = gx + phx;\n            yy = gy + phy;\n            ppx = (cs * xx - sn * yy) * pit;\n            ppy = (sn * xx + cs * yy) * pit;\n            ti = clamp(floor((ppx / asp + 0.5) * wd), 0, wd - 1);\n            tj = clamp(floor((ppy + 0.5) * ht), 0, ht - 1);\n            ru = (ti + 0.5) / wd;\n            rv = (tj + 0.5) / ht;\n            tone = rd(ru, rv, ch);\n            best = max(best, cover_local(qx - gx, qy - gy, 0, tone, soft, aa, shp));\n        }\n    }\n    return best;\n}\n\n// T025: the Threshold and Bayer coverage of one per-pixel tone\nthresh(tone, lvl, soft) {\n    hw = soft * 0.5;\n    return switch(hw > 0, smoothstep(lvl - hw, lvl + hw, tone), switch(tone > lvl, 1, 0));\n}\n\nbayer(tone, ix, iy) {\n    x0 = mod(ix, 2);\n    x1 = mod(floor(ix / 2), 2);\n    x2 = mod(floor(ix / 4), 2);\n    y0 = mod(iy, 2);\n    y1 = mod(floor(iy / 2), 2);\n    y2 = mod(floor(iy / 4), 2);\n    mm = 16 * (2 * abs(x0 - y0) + y0) + 4 * (2 * abs(x1 - y1) + y1) + (2 * abs(x2 - y2) + y2);\n    return switch(tone > (mm + 0.5) / 64, 1, 0);\n}\n\nParam screen(0);\nParam pitch(0.012);\nParam angle_r(15);\nParam angle_g(75);\nParam angle_b(45);\nParam phase_r_x(0);\nParam phase_r_y(0);\nParam phase_g_x(0);\nParam phase_g_y(0);\nParam phase_b_x(0);\nParam phase_b_y(0);\nParam softness(0.1);\nParam dot_shape(0);\nParam jitter(0);\nParam seed(1);\nParam level(0.5);\nParam plate_mode(0);\nParam bayer_scale(1);\nParam bypass_gate(0);\nParam width(1920);\nParam height(1080);\n\nzr = zap(sample(in1, norm).x);\nzg = zap(sample(in1, norm).y);\nzb = zap(sample(in1, norm).z);\nza = zap(sample(in1, norm).w);\n\nwd = max(width, 1);\nht = max(height, 1);\nasp = wd / ht;\npx = (norm.x - 0.5) * asp;\npy = norm.y - 0.5;\npit = max(pitch, 0.0001);\naa = 1 / (pit * ht);\nsoft = clamp(softness, 0, 1);\nshp = clamp(dot_shape, 0, 1);\nis_line = switch(abs(screen - 1) < 0.5, 1, 0);\nis_thr = switch(abs(screen - 2) < 0.5, 1, 0);\nis_bay = switch(abs(screen - 3) < 0.5, 1, 0);\njit = clamp(jitter, 0, 1);\nuse_jit = switch(jit > 0, 1, 0) * switch(screen < 0.5, 1, 0);\nd2r = pi / 180;\n\n// red plate\ncsr = snap0(cos(angle_r * d2r));\nsnr = snap0(sin(angle_r * d2r));\nqxr, qyr = lat_xy(px, py, csr, snr, pit, phase_r_x, phase_r_y);\nur, vr = read_uv(qxr, qyr, is_line, csr, snr, pit, phase_r_x, phase_r_y, asp, wd, ht);\ntone_r = zap(nearest(in1, vec(ur, vr)).x);\ncov_r = cover(qxr, qyr, is_line, tone_r, soft, aa, shp);\nif (use_jit > 0.5) {\n    cov_r = dot_jit(qxr, qyr, 0, csr, snr, pit, phase_r_x, phase_r_y, asp, wd, ht, soft, aa, shp, jit, seed);\n}\n\n// green plate\ncsg = snap0(cos(angle_g * d2r));\nsng = snap0(sin(angle_g * d2r));\nqxg, qyg = lat_xy(px, py, csg, sng, pit, phase_g_x, phase_g_y);\nug, vg = read_uv(qxg, qyg, is_line, csg, sng, pit, phase_g_x, phase_g_y, asp, wd, ht);\ntone_g = zap(nearest(in1, vec(ug, vg)).y);\ncov_g = cover(qxg, qyg, is_line, tone_g, soft, aa, shp);\nif (use_jit > 0.5) {\n    cov_g = dot_jit(qxg, qyg, 1, csg, sng, pit, phase_g_x, phase_g_y, asp, wd, ht, soft, aa, shp, jit, seed);\n}\n\n// blue plate\ncsb = snap0(cos(angle_b * d2r));\nsnb = snap0(sin(angle_b * d2r));\nqxb, qyb = lat_xy(px, py, csb, snb, pit, phase_b_x, phase_b_y);\nub, vb = read_uv(qxb, qyb, is_line, csb, snb, pit, phase_b_x, phase_b_y, asp, wd, ht);\ntone_b = zap(nearest(in1, vec(ub, vb)).z);\ncov_b = cover(qxb, qyb, is_line, tone_b, soft, aa, shp);\nif (use_jit > 0.5) {\n    cov_b = dot_jit(qxb, qyb, 2, csb, snb, pit, phase_b_x, phase_b_y, asp, wd, ht, soft, aa, shp, jit, seed);\n}\n\n// T025: Threshold and Bayer replace the lattice, per pixel\nbsc = max(floor(bayer_scale + 0.5), 1);\nixb = floor(floor(norm.x * wd) / bsc);\niyb = floor(floor(norm.y * ht) / bsc);\ncov_r = switch(is_thr > 0.5, thresh(zr, level, soft), switch(is_bay > 0.5, bayer(zr, ixb, iyb), cov_r));\ncov_g = switch(is_thr > 0.5, thresh(zg, level, soft), switch(is_bay > 0.5, bayer(zg, ixb, iyb), cov_g));\ncov_b = switch(is_thr > 0.5, thresh(zb, level, soft), switch(is_bay > 0.5, bayer(zb, ixb, iyb), cov_b));\n\n// T016b: Single, one plate at the blue plate's angle and phase\nis_single = switch(plate_mode > 0.5, 1, 0);\ntone_s = rd(ub, vb, 3);\ncov_s = cover(qxb, qyb, is_line, tone_s, soft, aa, shp);\ncu = ub;\ncv = vb;\nif (use_jit > 0.5) {\n    cov_s = dot_jit(qxb, qyb, 3, csb, snb, pit, phase_b_x, phase_b_y, asp, wd, ht, soft, aa, shp, jit, seed);\n    cu, cv = jit_uv(qxb, qyb, csb, snb, pit, phase_b_x, phase_b_y, asp, wd, ht, jit, seed);\n}\ntone_p = max(max(zr, zg), zb);\ncov_s = switch(is_thr > 0.5, thresh(tone_p, level, soft), switch(is_bay > 0.5, bayer(tone_p, ixb, iyb), cov_s));\ncu = switch(is_thr + is_bay > 0.5, norm.x, cu);\ncv = switch(is_thr + is_bay > 0.5, norm.y, cv);\ncr = zap(nearest(in1, vec(cu, cv)).x);\ncg = zap(nearest(in1, vec(cu, cv)).y);\ncb = zap(nearest(in1, vec(cu, cv)).z);\nct = max(max(cr, cg), cb);\nsr = switch(ct > 0, cr / max(ct, 0.000000000001), 0) * cov_s;\nsg = switch(ct > 0, cg / max(ct, 0.000000000001), 0) * cov_s;\nsb = switch(ct > 0, cb / max(ct, 0.000000000001), 0) * cov_s;\no_r = mix(cov_r, sr, is_single);\no_g = mix(cov_g, sg, is_single);\no_b = mix(cov_b, sb, is_single);\n\nout1 = mix(vec(o_r, o_g, o_b, za), vec(zr, zg, zb, za), step(0.5, bypass_gate));\n",
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
					"text": "jit.gl.pix vsynth @name #0_halftone_pix @adapt 0 @dim 256 256 @type float32",
					"varname": "#0_halftone_pix"
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
						1639.5,
						100.0,
						56.0,
						22.0
					],
					"text": "autopattr",
					"varname": "halftone_autopattr"
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
						1419.5,
						260.0,
						290.0,
						212.0
					],
					"presentation": 1,
					"presentation_rect": [
						0.0,
						0.0,
						290.0,
						212.0
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
						1639.5,
						200.0,
						80.0,
						21.0
					],
					"presentation": 1,
					"presentation_rect": [
						10.5,
						0.0,
						50.0,
						21.0
					],
					"text": "Halftone"
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
						1729.5,
						200.0,
						60.0,
						21.0
					],
					"presentation": 1,
					"presentation_rect": [
						194.0,
						0.9,
						70.0,
						21.0
					],
					"text": "tex in/out"
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
						1639.5,
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
						1659.5,
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
						1419.5,
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
						1419.5,
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
						1419.5,
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
						1419.5,
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
						1419.5,
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
						1419.5,
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
					"maxclass": "live.menu",
					"fontname": "Ableton Sans Light",
					"hint": "Dot: a lattice of dots, each sized by the tone at its center. Line: parallel lines whose width follows the tone. Threshold: ink where the tone is above Level. Bayer: an ordered dither, one pixel per mark",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"",
						"",
						"float"
					],
					"param_connect": "#0_halftone_pix::screen",
					"parameter_enable": 1,
					"patching_rect": [
						30.0,
						250.0,
						60.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						64.0,
						3.0,
						52.0,
						15.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_enum": [
								"Dot",
								"Line",
								"Threshold",
								"Bayer"
							],
							"parameter_initial": [
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "screen",
							"parameter_mmax": 3.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 0,
							"parameter_shortname": "screen",
							"parameter_type": 2,
							"parameter_unitstyle": 0
						}
					},
					"varname": "screen"
				}
			},
			{
				"box": {
					"id": "obj-21",
					"maxclass": "attrui",
					"attr": "screen",
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
					"text": "Screen",
					"textjustification": 1,
					"varname": "lbl_screen",
					"hidden": 1
				}
			},
			{
				"box": {
					"id": "obj-23",
					"maxclass": "live.menu",
					"fontname": "Ableton Sans Light",
					"hint": "Channels: red, green and blue are three plates, each at its own angle. Single: the texture is one spot-color plate, screened once at the B angle and phase, in its own color (for f_separate's plates)",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"",
						"",
						"float"
					],
					"param_connect": "#0_halftone_pix::plate_mode",
					"parameter_enable": 1,
					"patching_rect": [
						102.0,
						250.0,
						60.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						120.0,
						3.0,
						60.0,
						15.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_enum": [
								"Channels",
								"Single"
							],
							"parameter_initial": [
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "plate_mode",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 0,
							"parameter_shortname": "plate_mode",
							"parameter_type": 2,
							"parameter_unitstyle": 0
						}
					},
					"varname": "plate_mode"
				}
			},
			{
				"box": {
					"id": "obj-24",
					"maxclass": "attrui",
					"attr": "plate_mode",
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
					"text": "Plate",
					"textjustification": 1,
					"varname": "lbl_plate_mode",
					"hidden": 1
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
					"hint": "Lattice period in frame heights. Below about 10 pixels the inked area stops tracking the tone",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_halftone_pix::pitch",
					"parameter_enable": 1,
					"patching_rect": [
						190.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						10.5,
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
								0.012
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "pitch",
							"parameter_mmax": 0.2,
							"parameter_mmin": 0.003,
							"parameter_modmode": 3,
							"parameter_shortname": "pitch",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "pitch"
				}
			},
			{
				"box": {
					"id": "obj-27",
					"maxclass": "attrui",
					"attr": "pitch",
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
						-1.0,
						20.0,
						50.0,
						18.0
					],
					"text": "Pitch",
					"textjustification": 1,
					"varname": "lbl_pitch"
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
					"hint": "Width of the edge between ink and no ink. 0 is as sharp as one pixel allows",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_halftone_pix::softness",
					"parameter_enable": 1,
					"patching_rect": [
						262.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						10.5,
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
					"id": "obj-30",
					"maxclass": "attrui",
					"attr": "softness",
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
						-1.0,
						82.0,
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
					"id": "obj-32",
					"maxclass": "live.dial",
					"activedialcolor": [
						0.8,
						0.8,
						0.8,
						1.0
					],
					"fontname": "Ableton Sans Light",
					"hint": "Dot only: round at 0, square at 1, the same inked area at every setting",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_halftone_pix::dot_shape",
					"parameter_enable": 1,
					"patching_rect": [
						334.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						10.5,
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
							"parameter_longname": "dot_shape",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "dot_shape",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "dot_shape"
				}
			},
			{
				"box": {
					"id": "obj-33",
					"maxclass": "attrui",
					"attr": "dot_shape",
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
						-1.0,
						144.0,
						50.0,
						18.0
					],
					"text": "Shape",
					"textjustification": 1,
					"varname": "lbl_dot_shape"
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
					"hint": "Dot only: moves each dot off the lattice, from a regular screen at 0 toward a random one at 1. Above mid-tone it loses a little ink",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_halftone_pix::jitter",
					"parameter_enable": 1,
					"patching_rect": [
						406.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						56.5,
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
							"parameter_longname": "jitter",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
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
					"id": "obj-36",
					"maxclass": "attrui",
					"attr": "jitter",
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
						45.0,
						144.0,
						50.0,
						18.0
					],
					"text": "Jitter",
					"textjustification": 1,
					"varname": "lbl_jitter"
				}
			},
			{
				"box": {
					"id": "obj-38",
					"maxclass": "live.numbox",
					"fontname": "Ableton Sans Light",
					"hint": "Which random jitter pattern",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"int"
					],
					"param_connect": "#0_halftone_pix::seed",
					"parameter_enable": 1,
					"patching_rect": [
						470.0,
						250.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						90.0,
						176.0,
						34.0,
						15.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								1.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "seed",
							"parameter_mmax": 999.0,
							"parameter_mmin": 1.0,
							"parameter_modmode": 0,
							"parameter_shortname": "seed",
							"parameter_type": 1,
							"parameter_unitstyle": 0
						}
					},
					"varname": "seed"
				}
			},
			{
				"box": {
					"id": "obj-39",
					"maxclass": "attrui",
					"attr": "seed",
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
						82.0,
						158.0,
						50.0,
						18.0
					],
					"text": "Seed",
					"textjustification": 1,
					"varname": "lbl_seed"
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
					"hint": "Threshold only: the tone above which there is ink. Soft widens the cut",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_halftone_pix::level",
					"parameter_enable": 1,
					"patching_rect": [
						550.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						137.5,
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
								0.5
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "level",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "level",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "level"
				}
			},
			{
				"box": {
					"id": "obj-42",
					"maxclass": "attrui",
					"attr": "level",
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
						126.0,
						144.0,
						50.0,
						18.0
					],
					"text": "Level",
					"textjustification": 1,
					"varname": "lbl_level"
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
					"hint": "Bayer only: pixels per dither cell, in whole pixels. 1 is the finest; larger gives a blocky, low-resolution dither",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_halftone_pix::bayer_scale",
					"parameter_enable": 1,
					"patching_rect": [
						622.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						174.5,
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
								1.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "bayer_scale",
							"parameter_mmax": 16.0,
							"parameter_mmin": 1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "bayer_scale",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "bayer_scale"
				}
			},
			{
				"box": {
					"id": "obj-45",
					"maxclass": "attrui",
					"attr": "bayer_scale",
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
						163.0,
						144.0,
						50.0,
						18.0
					],
					"text": "Bayer",
					"textjustification": 1,
					"varname": "lbl_bayer_scale"
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
					"hint": "Screen angle of the red plate, in degrees",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_halftone_pix::angle_r",
					"parameter_enable": 1,
					"patching_rect": [
						694.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						75.0,
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
								15.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "angle_r",
							"parameter_mmax": 180.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "angle_r",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "angle_r"
				}
			},
			{
				"box": {
					"id": "obj-48",
					"maxclass": "attrui",
					"attr": "angle_r",
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
					"id": "obj-49",
					"maxclass": "comment",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						683.0,
						180.0,
						50.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						63.5,
						20.0,
						50.0,
						18.0
					],
					"text": "Angle R",
					"textjustification": 1,
					"varname": "lbl_angle_r"
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
					"hint": "Screen angle of the green plate, in degrees",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_halftone_pix::angle_g",
					"parameter_enable": 1,
					"patching_rect": [
						766.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						156.0,
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
								75.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "angle_g",
							"parameter_mmax": 180.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "angle_g",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "angle_g"
				}
			},
			{
				"box": {
					"id": "obj-51",
					"maxclass": "attrui",
					"attr": "angle_g",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						746.0,
						310.0,
						68.0,
						22.0
					],
					"style": ""
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
						755.0,
						180.0,
						50.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						144.5,
						20.0,
						50.0,
						18.0
					],
					"text": "Angle G",
					"textjustification": 1,
					"varname": "lbl_angle_g"
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
					"hint": "Screen angle of the blue plate, in degrees",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_halftone_pix::angle_b",
					"parameter_enable": 1,
					"patching_rect": [
						838.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						237.0,
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
								45.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "angle_b",
							"parameter_mmax": 180.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "angle_b",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "angle_b"
				}
			},
			{
				"box": {
					"id": "obj-54",
					"maxclass": "attrui",
					"attr": "angle_b",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						818.0,
						310.0,
						68.0,
						22.0
					],
					"style": ""
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
						827.0,
						180.0,
						50.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						225.5,
						20.0,
						50.0,
						18.0
					],
					"text": "Angle B",
					"textjustification": 1,
					"varname": "lbl_angle_b"
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
					"hint": "Shifts the red plate's lattice along its own x, in pitches. The marks stay whole and sharp",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_halftone_pix::phase_r_x",
					"parameter_enable": 1,
					"patching_rect": [
						910.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						56.5,
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
							"parameter_longname": "phase_r_x",
							"parameter_mmax": 1.0,
							"parameter_mmin": -1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "phase_r_x",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "phase_r_x"
				}
			},
			{
				"box": {
					"id": "obj-57",
					"maxclass": "attrui",
					"attr": "phase_r_x",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						890.0,
						310.0,
						68.0,
						22.0
					],
					"style": ""
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
						899.0,
						180.0,
						50.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						45.0,
						82.0,
						50.0,
						18.0
					],
					"text": "R x",
					"textjustification": 1,
					"varname": "lbl_phase_r_x"
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
					"hint": "Shifts the red plate's lattice along its own y, in pitches",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_halftone_pix::phase_r_y",
					"parameter_enable": 1,
					"patching_rect": [
						982.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						93.5,
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
							"parameter_longname": "phase_r_y",
							"parameter_mmax": 1.0,
							"parameter_mmin": -1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "phase_r_y",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "phase_r_y"
				}
			},
			{
				"box": {
					"id": "obj-60",
					"maxclass": "attrui",
					"attr": "phase_r_y",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						962.0,
						310.0,
						68.0,
						22.0
					],
					"style": ""
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
						971.0,
						180.0,
						50.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						82.0,
						82.0,
						50.0,
						18.0
					],
					"text": "R y",
					"textjustification": 1,
					"varname": "lbl_phase_r_y"
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
					"hint": "Shifts the green plate's lattice along its own x, in pitches",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_halftone_pix::phase_g_x",
					"parameter_enable": 1,
					"patching_rect": [
						1054.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						137.5,
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
							"parameter_longname": "phase_g_x",
							"parameter_mmax": 1.0,
							"parameter_mmin": -1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "phase_g_x",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "phase_g_x"
				}
			},
			{
				"box": {
					"id": "obj-63",
					"maxclass": "attrui",
					"attr": "phase_g_x",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1034.0,
						310.0,
						68.0,
						22.0
					],
					"style": ""
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
						1043.0,
						180.0,
						50.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						126.0,
						82.0,
						50.0,
						18.0
					],
					"text": "G x",
					"textjustification": 1,
					"varname": "lbl_phase_g_x"
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
					"hint": "Shifts the green plate's lattice along its own y, in pitches",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_halftone_pix::phase_g_y",
					"parameter_enable": 1,
					"patching_rect": [
						1126.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						174.5,
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
							"parameter_longname": "phase_g_y",
							"parameter_mmax": 1.0,
							"parameter_mmin": -1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "phase_g_y",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "phase_g_y"
				}
			},
			{
				"box": {
					"id": "obj-66",
					"maxclass": "attrui",
					"attr": "phase_g_y",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1106.0,
						310.0,
						68.0,
						22.0
					],
					"style": ""
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
						1115.0,
						180.0,
						50.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						163.0,
						82.0,
						50.0,
						18.0
					],
					"text": "G y",
					"textjustification": 1,
					"varname": "lbl_phase_g_y"
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
					"hint": "Shifts the blue plate's lattice along its own x, in pitches",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_halftone_pix::phase_b_x",
					"parameter_enable": 1,
					"patching_rect": [
						1198.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						218.5,
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
							"parameter_longname": "phase_b_x",
							"parameter_mmax": 1.0,
							"parameter_mmin": -1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "phase_b_x",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "phase_b_x"
				}
			},
			{
				"box": {
					"id": "obj-69",
					"maxclass": "attrui",
					"attr": "phase_b_x",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1178.0,
						310.0,
						68.0,
						22.0
					],
					"style": ""
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
						1187.0,
						180.0,
						50.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						207.0,
						82.0,
						50.0,
						18.0
					],
					"text": "B x",
					"textjustification": 1,
					"varname": "lbl_phase_b_x"
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
					"hint": "Shifts the blue plate's lattice along its own y, in pitches",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_halftone_pix::phase_b_y",
					"parameter_enable": 1,
					"patching_rect": [
						1270.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						255.5,
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
							"parameter_longname": "phase_b_y",
							"parameter_mmax": 1.0,
							"parameter_mmin": -1.0,
							"parameter_modmode": 3,
							"parameter_shortname": "phase_b_y",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "phase_b_y"
				}
			},
			{
				"box": {
					"id": "obj-72",
					"maxclass": "attrui",
					"attr": "phase_b_y",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1250.0,
						310.0,
						68.0,
						22.0
					],
					"style": ""
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
						1259.0,
						180.0,
						50.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						244.0,
						82.0,
						50.0,
						18.0
					],
					"text": "B y",
					"textjustification": 1,
					"varname": "lbl_phase_b_y"
				}
			},
			{
				"box": {
					"id": "obj-74",
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
						1639.5,
						130.0,
						18.0,
						12.0
					],
					"presentation_rect": [
						268.0,
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
					"id": "obj-75",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1639.5,
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
						30.0,
						542.0,
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
						170.0,
						542.0,
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
						170.0,
						572.0,
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
						80.0,
						542.0,
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
						80.0,
						572.0,
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
						30.0,
						602.0,
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
						160.0,
						602.0,
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
			},
			{
				"patchline": {
					"source": [
						"obj-4",
						9
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
						"obj-5",
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
						"obj-5",
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
						"obj-5",
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
						"obj-5",
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
						"obj-5",
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
						"obj-62",
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
						"obj-5",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-4",
						15
					],
					"destination": [
						"obj-65",
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
						"obj-5",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-4",
						16
					],
					"destination": [
						"obj-68",
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
						"obj-5",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-4",
						17
					],
					"destination": [
						"obj-71",
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
			}
		],
		"parameters": {
			"obj-20": [
				"screen",
				"screen",
				0
			],
			"obj-23": [
				"plate_mode",
				"plate_mode",
				0
			],
			"obj-26": [
				"pitch",
				"pitch",
				0
			],
			"obj-29": [
				"softness",
				"softness",
				0
			],
			"obj-32": [
				"dot_shape",
				"dot_shape",
				0
			],
			"obj-35": [
				"jitter",
				"jitter",
				0
			],
			"obj-38": [
				"seed",
				"seed",
				0
			],
			"obj-41": [
				"level",
				"level",
				0
			],
			"obj-44": [
				"bayer_scale",
				"bayer_scale",
				0
			],
			"obj-47": [
				"angle_r",
				"angle_r",
				0
			],
			"obj-50": [
				"angle_g",
				"angle_g",
				0
			],
			"obj-53": [
				"angle_b",
				"angle_b",
				0
			],
			"obj-56": [
				"phase_r_x",
				"phase_r_x",
				0
			],
			"obj-59": [
				"phase_r_y",
				"phase_r_y",
				0
			],
			"obj-62": [
				"phase_g_x",
				"phase_g_x",
				0
			],
			"obj-65": [
				"phase_g_y",
				"phase_g_y",
				0
			],
			"obj-68": [
				"phase_b_x",
				"phase_b_x",
				0
			],
			"obj-71": [
				"phase_b_y",
				"phase_b_y",
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