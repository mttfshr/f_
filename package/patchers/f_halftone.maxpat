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
					"comment": "texture (the plates combined)",
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
					"id": "obj-201",
					"maxclass": "outlet",
					"comment": "plate R (Plates: plate 1), gray mask or color per Out",
					"index": 0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						100.0,
						452.0,
						30.0,
						30.0
					]
				}
			},
			{
				"box": {
					"id": "obj-202",
					"maxclass": "outlet",
					"comment": "plate G (Plates: plate 2), gray mask or color per Out",
					"index": 0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						170.0,
						452.0,
						30.0,
						30.0
					]
				}
			},
			{
				"box": {
					"id": "obj-203",
					"maxclass": "outlet",
					"comment": "plate B (Plates and Single: plate 3 / the one plate), gray mask or color per Out",
					"index": 0,
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						240.0,
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
					"numoutlets": 23,
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
						1663.0,
						22.0
					],
					"text": "route screen plate_mode pitch scale_r scale_g scale_b softness dot_shape jitter seed levels level bayer_cell angle_r angle_g angle_b phase_r_x phase_r_y phase_g_x phase_g_y phase_b_x phase_b_y plate_out"
				}
			},
			{
				"box": {
					"id": "obj-5",
					"maxclass": "newobj",
					"numinlets": 5,
					"numoutlets": 5,
					"outlettype": [
						"jit_gl_texture",
						"jit_gl_texture",
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
									"id": "gen-obj-12",
									"maxclass": "newobj",
									"numinlets": 0,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										196.0,
										30.0,
										28.0,
										22.0
									],
									"text": "in 4"
								}
							},
							{
								"box": {
									"id": "gen-obj-13",
									"maxclass": "newobj",
									"numinlets": 0,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										254.0,
										30.0,
										28.0,
										22.0
									],
									"text": "in 5"
								}
							},
							{
								"box": {
									"code": "// codebox_halftone.gen -- f_halftone: the one stage. Tone to marks on a fixed-angle lattice, one plate per color channel.\n// Stateless, per pixel. Float32. Mirror: tests/modules/halftone/halftone_mirror.halftone_stage() (the conventions in its\n// docstring are the ones followed here). T020: Dot and Line, soft edge, exact extremes, zap, bypass, alpha; the per-plate\n// phase (FR-016) is in because it is part of the lattice formula. 2026-11-14: shape (T023), jitter (T024), Threshold and\n// Bayer (T025), the Single plate mode (T016b).\n//\n// Lattice (plan ADR-1): p = ((u - .5) * aspect, v - .5) in frame heights; q = R(-angle) p / pitch - phase;\n//   lattice cell = floor(q + .5), local f = q - that, in [-.5, .5]^2.\n// Spot functions (ADR-2): Dot T = A(r), the area of the radius-r circle inside the unit cell; Line T = 2 |f_y|.\n//   dot_shape (T023, Dot only; a Param named `shape` never received its value on the bench, 2026-11-14) morphs round to square: T = mix(A(r), (2 max(|f_x|, |f_y|))^2, shape), the slope likewise.\n// Soft edge (ADR-3): coverage = clamp(.5 + (tone - T) / w, 0, 1), w = max(softness / 2, aa) * |dT/dd|,\n//   aa = 1 / (pitch in texels); then tone <= 0 gives exactly 0 and tone >= 1 exactly 1.\n// Tone (ADR-4): ONE nearest read per plate at a texel centre: Dot at the lattice cell's centre, Line at the pixel's own\n//   position along its centreline row. The reads are in the main body, the tone is passed to the functions (gate G8).\n// Jitter (ADR-5, Dot only): each cell centre moves by jitter * .5 * (hash - .5) cells (the sin hash, seeded); the nine cells\n//   around the pixel are tested and the largest coverage wins; the tone is read at each displaced centre. jitter 0 takes the\n//   one-cell path, so the regular lattice is exactly the T020 one. Each jittered mark is clipped to its own displaced unit\n//   square (fix A, Matt 2026-11-14), as the mirror does.\n// Threshold (ADR-6): smoothstep(level - w, level + w, tone), w = softness / 2 (a hard step at softness 0), per pixel.\n// Bayer: the 8 x 8 ordered matrix by texel, M = sum over bits b of 4^(2-b) (2 (x_b xor y_b) + y_b); lit where tone > (M + .5) / 64.\n//   The matrix repeats once per pitch (Matt, 2026-11-14): a cell is pitch / 8 frame heights, rounded to whole pixels, at\n//   least 1. bayer_cell 1 (default; Matt, 2026-11-14) reads one tone per cell at its centre pixel, a true ordered dither;\n//   0 reads it per pixel (a threshold at each cell's level). Identical at 1-pixel cells.\n// Per-plate pitch (T029b, Matt 2026-11-14, FR-022): a plate's pitch is pitch * scale_<plate>; every length above that says\n//   \"pitch\" means the plate's own pitch. Single uses scale_b. bay_cell returns four values (inferred to compile; the bench decides).\n// Single plate (T016b, plate_mode 1; spec \"Plates from f_separate\"): the whole texture is ONE plate at angle_b and phase_b.\n//   Its tone is the brightest channel, t = max(r, g, b), at the read texel; the colour is rgb / t there (black when t <= 0); the\n//   output is that colour times the coverage. The colour texel is the one the tone came from: the cell centre (displaced when\n//   jittered) for Dot, the centreline point for Line, the pixel's own for Threshold and Bayer.\n// Plates (T028, Matt 2026-11-14; spec US9, FR-017 to FR-021, plan ADR-8): plate_mode 2 screens the module's inlets 1 to 3\n//   (gen in2 to in4) each as Single, plate 1 at the R angle / phase / scale, 2 at G, 3 at B; summed and clamped to 0..1; alpha\n//   the largest of the connected plates' alphas. An unconnected plate is skipped by its connected flag (plate1_on etc., from\n//   vs_inState), never by its value: an unconnected inlet reads black with alpha 1, which would set alpha to 1. Inlet 0 is\n//   ignored except by bypass. Every mode runs plate_path 3 times (below); `src` picks the inlet (0 = in1 ... 3 = in4).\n// Blue and Random (T035, Matt 2026-11-14; spec US10, FR-023 to FR-026, plan ADR-10): screens 4 and 5, Bayer's grain cell\n//   and Read, the threshold from the void-and-cluster pattern (gen in5: package/media/f_bluenoise64.jxf through the builder's\n//   static mod inlet, 64 x 64, tiled, nearest) or the sin hash of the cell. The cell index is shifted by the plate's offset\n//   ((0, 0), (23, 41), (47, 13) for plates 0 / 1 / 2; Single is plate 2, Plates plate k is k - 1), by the phase in whole\n//   grain cells (8 per pitch, rounded), and for Blue by (61, 29) per seed step; Random hashes the shifted cell with the seed.\n//   All offsets preliminary (Claude, T033 spike); the mirror's dither_threshold is the reference. Inferred, for the bench: that\n//   the one-plane float texture reads its value in .x, and that its row 0 is the smallest norm.y.\n// Levels (T035, FR-027, ADR-11): Bayer, Blue and Random: q = tone (L - 1); out = (floor(q) + [fract(q) > threshold]) / (L - 1),\n//   clamped, tone <= 0 exactly 0, tone >= 1 exactly 1. At L = 2 it is the one-bit dither, bit for bit.\n// screen: 0 = Dot, 1 = Line, 2 = Threshold, 3 = Bayer, 4 = Blue, 5 = Random. Angles in degrees. bypass_gate = 1: the (zapped) source.\n// Non-finite input is zapped to 0: abs(x) < 1e30 with switch() (NaN == NaN is TRUE on this GPU).\n// The render size comes from the Params `width` and `height` (render_dim; the size global reads 1 inside a live Vsynth pix,\n// build/spec.md). A bench job must set both to the output's size.\nzap(xv) {\n    return switch(abs(xv) < 1e30, xv, 0);\n}\n\n// cos and sin of exact quarter turns come out as 1e-8, not 0: snap, so 0 and 90 degrees sit on the pixel grid (G6)\nsnap0(xv) {\n    return switch(abs(xv) < 0.000001, 0, xv);\n}\n\narea_round(rad) {\n    rc = min(rad, 0.70710678);\n    inner = pi * rc * rc;\n    ac = acos(clamp(1 / (2 * max(rc, 0.000001)), 0, 1));\n    seg = rc * rc * ac - 0.5 * sqrt(max(rc * rc - 0.25, 0));\n    area = switch(rc > 0.5, inner - 4 * seg, inner);\n    return switch(rad >= 0.70710678, 1, area);\n}\n\narea_slope(rad) {\n    rc = min(rad, 0.70710678);\n    ac = acos(clamp(1 / (2 * max(rc, 0.000001)), 0, 1));\n    slp = switch(rc <= 0.5, twopi * rc, rc * (twopi - 8 * ac));\n    return switch(rad >= 0.70710678, 0, slp);\n}\n\n// lattice coordinates of the position (px, py)\nlat_xy(px, py, cs, sn, pit, phx, phy) {\n    return (cs * px + sn * py) / pit - phx, (cs * py - sn * px) / pit - phy;\n}\n\n// where the plate's tone is read: normalized coordinates of a texel centre, clamped to the frame\nread_uv(qx, qy, is_line, cs, sn, pit, phx, phy, asp, wd, ht) {\n    xx = switch(is_line > 0.5, qx, floor(qx + 0.5)) + phx;\n    yy = floor(qy + 0.5) + phy;\n    ppx = (cs * xx - sn * yy) * pit;\n    ppy = (sn * xx + cs * yy) * pit;\n    ti = clamp(floor((ppx / asp + 0.5) * wd), 0, wd - 1);\n    tj = clamp(floor((ppy + 0.5) * ht), 0, ht - 1);\n    return (ti + 0.5) / wd, (tj + 0.5) / ht;\n}\n\n// coverage at local lattice coordinates (fx, fy) relative to a mark's centre\ncover_local(fx, fy, is_line, tone, soft, aa, shp) {\n    rad = sqrt(fx * fx + fy * fy);\n    sq = max(abs(fx), abs(fy));\n    thr_dot = mix(area_round(rad), 4 * sq * sq, shp);\n    slp_dot = mix(area_slope(rad), 8 * sq, shp);\n    thr = switch(is_line > 0.5, 2 * abs(fy), thr_dot);\n    slp = switch(is_line > 0.5, 2, slp_dot);\n    wid = max(soft * 0.5, aa) * max(abs(slp), 0.000001);\n    cov = clamp(0.5 + (tone - thr) / wid, 0, 1);\n    return switch(tone <= 0, 0, switch(tone >= 1, 1, cov));\n}\n\ncover(qx, qy, is_line, tone, soft, aa, shp) {\n    return cover_local(qx - floor(qx + 0.5), qy - floor(qy + 0.5), is_line, tone, soft, aa, shp);\n}\n\n// the zapped tone at a texel centre: ch 0 r, 1 g, 2 b, 3 the brightest of the three (Single); src the inlet (0 = in1 ... 3 = in4)\nrd(ru, rv, ch, src) {\n    tx = 0;\n    ty = 0;\n    tz = 0;\n    if (src < 0.5) {\n        tx = zap(nearest(in1, vec(ru, rv)).x);\n        ty = zap(nearest(in1, vec(ru, rv)).y);\n        tz = zap(nearest(in1, vec(ru, rv)).z);\n    } else if (src < 1.5) {\n        tx = zap(nearest(in2, vec(ru, rv)).x);\n        ty = zap(nearest(in2, vec(ru, rv)).y);\n        tz = zap(nearest(in2, vec(ru, rv)).z);\n    } else if (src < 2.5) {\n        tx = zap(nearest(in3, vec(ru, rv)).x);\n        ty = zap(nearest(in3, vec(ru, rv)).y);\n        tz = zap(nearest(in3, vec(ru, rv)).z);\n    } else {\n        tx = zap(nearest(in4, vec(ru, rv)).x);\n        ty = zap(nearest(in4, vec(ru, rv)).y);\n        tz = zap(nearest(in4, vec(ru, rv)).z);\n    }\n    return switch(ch < 0.5, tx, switch(ch < 1.5, ty, switch(ch < 2.5, tz, max(max(tx, ty), tz))));\n}\n\n// T016b: the read texel of the pixel's own cell centre, displaced by the jitter (the Single colour under jitter)\njit_uv(qx, qy, cs, sn, pit, phx, phy, asp, wd, ht, jit, sd) {\n    nx = floor(qx + 0.5);\n    ny = floor(qy + 0.5);\n    hx = fract(sin(nx * 127.1 + ny * 311.7 + sd * 74.7) * 43758.5453);\n    hy = fract(sin(nx * 269.5 + ny * 183.3 + sd * 246.1) * 43758.5453);\n    xx = nx + jit * 0.5 * (hx - 0.5) + phx;\n    yy = ny + jit * 0.5 * (hy - 0.5) + phy;\n    ppx = (cs * xx - sn * yy) * pit;\n    ppy = (sn * xx + cs * yy) * pit;\n    ti = clamp(floor((ppx / asp + 0.5) * wd), 0, wd - 1);\n    tj = clamp(floor((ppy + 0.5) * ht), 0, ht - 1);\n    return (ti + 0.5) / wd, (tj + 0.5) / ht;\n}\n\n// T024: the jittered Dot. ch picks the plate's channel (0 r, 1 g, 2 b, 3 the brightest: Single). Reads inside a function and a loop are exact (T010).\ndot_jit(qx, qy, ch, src, cs, sn, pit, phx, phy, asp, wd, ht, soft, aa, shp, jit, sd) {\n    cx = floor(qx + 0.5);\n    cy = floor(qy + 0.5);\n    best = 0;\n    for (j = 0; j < 3; j += 1) {\n        for (i = 0; i < 3; i += 1) {\n            nx = cx + i - 1;\n            ny = cy + j - 1;\n            hx = fract(sin(nx * 127.1 + ny * 311.7 + sd * 74.7) * 43758.5453);\n            hy = fract(sin(nx * 269.5 + ny * 183.3 + sd * 246.1) * 43758.5453);\n            gx = nx + jit * 0.5 * (hx - 0.5);\n            gy = ny + jit * 0.5 * (hy - 0.5);\n            xx = gx + phx;\n            yy = gy + phy;\n            ppx = (cs * xx - sn * yy) * pit;\n            ppy = (sn * xx + cs * yy) * pit;\n            ti = clamp(floor((ppx / asp + 0.5) * wd), 0, wd - 1);\n            tj = clamp(floor((ppy + 0.5) * ht), 0, ht - 1);\n            ru = (ti + 0.5) / wd;\n            rv = (tj + 0.5) / ht;\n            tone = rd(ru, rv, ch, src);\n            // fix A (Matt, 2026-11-14): a mark lives only in its own displaced unit square (unclipped, a full-tone\n            // neighbour inked the whole 3 x 3 block, since tone >= 1 gives full ink at any distance)\n            inside = step(max(abs(qx - gx), abs(qy - gy)), 0.5);\n            best = max(best, inside * cover_local(qx - gx, qy - gy, 0, tone, soft, aa, shp));\n        }\n    }\n    return best;\n}\n\n// T025: the Threshold and Bayer coverage of one per-pixel tone\nthresh(tone, lvl, soft) {\n    hw = soft * 0.5;\n    return switch(hw > 0, smoothstep(lvl - hw, lvl + hw, tone), switch(tone > lvl, 1, 0));\n}\n\n// T035: the dither screens. kind 0 Bayer, 1 Blue, 2 Random; plt the plate (0, 1, 2); lv the levels.\n// Written as if / else on purpose (bench, 2026-11-14): with the three thresholds computed side by side and picked by a switch,\n// the shader failed to compile in Max's GL3 transformer (\"lua: stack overflow (too many captures)\"), and every compile after it\n// in that bench session failed silently. Bisected: the failure came and went with what flowed into one final expression, not\n// with any one line; inferred, not confirmed: GenExpr inlines single-use values into one deeply nested GLSL expression, and the\n// transformer's Lua pattern has a capture limit. Branches force real variables (as rd() has) and skip the unused screens' work.\ndither(tone, ix, iy, kind, plt, sd, phx, phy, lv) {\n    thr = 0;\n    if (kind < 0.5) {\n        x0 = mod(ix, 2);\n        x1 = mod(floor(ix / 2), 2);\n        x2 = mod(floor(ix / 4), 2);\n        y0 = mod(iy, 2);\n        y1 = mod(floor(iy / 2), 2);\n        y2 = mod(floor(iy / 4), 2);\n        mm = 16 * (2 * abs(x0 - y0) + y0) + 4 * (2 * abs(x1 - y1) + y1) + (2 * abs(x2 - y2) + y2);\n        thr = (mm + 0.5) / 64;\n    } else {\n        // the plate offsets (0, 0), (23, 41), (47, 13), and the phase in whole grain cells (8 per pitch)\n        pk = max(plt - 1, 0);\n        gx = ix + 23 * plt + pk - floor(phx * 8 + 0.5);\n        gy = iy + 41 * plt - 69 * pk - floor(phy * 8 + 0.5);\n        if (kind < 1.5) {\n            bx = gx + 61 * sd;\n            by = gy + 29 * sd;\n            bx = bx - 64 * floor(bx / 64);\n            by = by - 64 * floor(by / 64);\n            thr = nearest(in5, vec((bx + 0.5) / 64, (by + 0.5) / 64)).x;\n        } else {\n            thr = fract(sin(gx * 127.1 + gy * 311.7 + sd * 74.7) * 43758.5453);\n        }\n    }\n    l1 = max(floor(lv + 0.5) - 1, 1);\n    q = tone * l1;\n    fq = floor(q);\n    o = clamp((fq + switch(q - fq > thr, 1, 0)) / l1, 0, 1);\n    return switch(tone <= 0, 0, switch(tone >= 1, 1, o));\n}\n\n// T029b (Matt, 2026-11-14; FR-022): Bayer's cell follows the plate's own pitch. Returns the read uv and the cell indices.\nbay_cell(pp, nx, ny, wd, ht, cellmode) {\n    bs = max(floor(pp * ht / 8 + 0.5), 1);\n    ix = floor(floor(nx * wd) / bs);\n    iy = floor(floor(ny * ht) / bs);\n    bx = min(ix * bs + floor(bs / 2), wd - 1);\n    by = min(iy * bs + floor(bs / 2), ht - 1);\n    return switch(cellmode > 0.5, (bx + 0.5) / wd, nx), switch(cellmode > 0.5, (by + 0.5) / ht, ny), ix, iy;\n}\n\n// T035 refactor (Matt, 2026-11-14): ONE plate function, called exactly 3 times in every mode. Before it the screening logic\n// was inlined 7 times (three Channels blocks in the main body, four single_path calls) and the shader stopped compiling\n// in Max's GL3 transformer (\"lua: [string DSL.Parser]:393: stack overflow (too many captures)\") once Blue / Random / Levels\n// were added; bisected offline: no one line was the cause, ANY ~12 more lines or one small function tipped it (a size\n// ceiling; the cause, total inlined size, is inferred). Returns the plate's r, g, b. src the inlet (0 = in1 ... 3 = in4);\n// ch what it reads (0 r, 1 g, 2 b: Channels, colour the unit vector of ch; 3 the brightest: Single and Plates, colour\n// rgb / brightest at the texel the tone came from). ang / pit / phx / phy are the settings row's. The dither plate is\n// derived: Plates src - 1, Channels ch, Single 2. nx, ny: the pixel's norm. 19 parameters (kept few on purpose).\nplate_path(src, ch, nx, ny, scr, ang, pit, phx, phy, asp, wd, ht, soft, shp, jit, sd, lvl, cellmode, lv) {\n    cs = snap0(cos(ang * pi / 180));\n    sn = snap0(sin(ang * pi / 180));\n    px = (nx - 0.5) * asp;\n    py = ny - 0.5;\n    aa = 1 / (pit * ht);\n    use_jit = switch(jit > 0, 1, 0) * switch(scr < 0.5, 1, 0);\n    is_line = switch(abs(scr - 1) < 0.5, 1, 0);\n    is_thr = switch(abs(scr - 2) < 0.5, 1, 0);\n    is_bay = switch(scr > 2.5, 1, 0);\n    dkind = clamp(floor(scr + 0.5) - 3, 0, 2);\n    qx, qy = lat_xy(px, py, cs, sn, pit, phx, phy);\n    ru, rv = read_uv(qx, qy, is_line, cs, sn, pit, phx, phy, asp, wd, ht);\n    cov = cover(qx, qy, is_line, rd(ru, rv, ch, src), soft, aa, shp);\n    cu = ru;\n    cv = rv;\n    if (use_jit > 0.5) {\n        cov = dot_jit(qx, qy, ch, src, cs, sn, pit, phx, phy, asp, wd, ht, soft, aa, shp, jit, sd);\n        cu, cv = jit_uv(qx, qy, cs, sn, pit, phx, phy, asp, wd, ht, jit, sd);\n    }\n    bu, bv, ix, iy = bay_cell(pit, nx, ny, wd, ht, cellmode);\n    plt = switch(src > 0.5, src - 1, min(ch, 2));\n    cov = switch(is_thr > 0.5, thresh(rd(nx, ny, ch, src), lvl, soft),\n                 switch(is_bay > 0.5, dither(rd(bu, bv, ch, src), ix, iy, dkind, plt, sd, phx, phy, lv), cov));\n    cu = switch(is_thr > 0.5, nx, switch(is_bay > 0.5, bu, cu));\n    cv = switch(is_thr > 0.5, ny, switch(is_bay > 0.5, bv, cv));\n    cr = switch(ch < 0.5, 1, 0);\n    cg = switch(abs(ch - 1) < 0.5, 1, 0);\n    cb = switch(abs(ch - 2) < 0.5, 1, 0);\n    nrm = cov;\n    if (ch > 2.5) {\n        cr = rd(cu, cv, 0, src);\n        cg = rd(cu, cv, 1, src);\n        cb = rd(cu, cv, 2, src);\n        ct = max(max(cr, cg), cb);\n        nrm = switch(ct > 0, 1 / max(ct, 0.000000000001), 0) * cov;\n    }\n    return cr * nrm, cg * nrm, cb * nrm;\n}\n\nParam screen(0);\nParam pitch(0.012);\nParam scale_r(1);\nParam scale_g(1);\nParam scale_b(1);\nParam angle_r(15);\nParam angle_g(75);\nParam angle_b(45);\nParam phase_r_x(0);\nParam phase_r_y(0);\nParam phase_g_x(0);\nParam phase_g_y(0);\nParam phase_b_x(0);\nParam phase_b_y(0);\nParam softness(0.1);\nParam dot_shape(0);\nParam jitter(0);\nParam seed(1);\nParam level(0.5);\nParam plate_mode(0);\nParam bayer_cell(1);\nParam levels(2);\nParam plate_out(0);\nParam bypass_gate(0);\nParam plate1_on(0);\nParam plate2_on(0);\nParam plate3_on(0);\nParam width(1920);\nParam height(1080);\n\nzr = zap(sample(in1, norm).x);\nzg = zap(sample(in1, norm).y);\nzb = zap(sample(in1, norm).z);\nza = zap(sample(in1, norm).w);\n\nwd = max(width, 1);\nht = max(height, 1);\nasp = wd / ht;\nsoft = clamp(softness, 0, 1);\nshp = clamp(dot_shape, 0, 1);\njit = clamp(jitter, 0, 1);\n// plate_mode 0 Channels, 1 Single, 2 Plates. Call k: source in(k + 2) in Plates, else in1; reads channel k in Channels, else\n// the brightest; settings row k in Channels and Plates, the B row (2) in Single; enabled always in Channels, only k = 2 in\n// Single, by the connected flag in Plates (never by value: an unconnected inlet reads black with alpha 1).\nis_ch = switch(plate_mode < 0.5, 1, 0);\nis_sg = switch(abs(plate_mode - 1) < 0.5, 1, 0);\nis_pl = switch(plate_mode > 1.5, 1, 0);\nrow0 = 2 * is_sg;\nrow1 = 1 + is_sg;\nen0 = max(is_ch, is_pl * step(0.5, plate1_on));\nen1 = max(is_ch, is_pl * step(0.5, plate2_on));\nen2 = max(max(is_ch, is_sg), is_pl * step(0.5, plate3_on));\n// T029b (FR-022): each plate's pitch is pitch * its scale. T032 (Matt, 2026-11-14): Dot and Line floor it at 0.009 frame\n// heights (about 10 texels at 1080p, where the area law holds within 2%); the dithers are exact at any pitch, so not floored.\npfl = switch(screen < 1.5, 0.009, 0.0001);\nang0 = switch(row0 > 1.5, angle_b, angle_r);\nang1 = switch(row1 > 1.5, angle_b, angle_g);\npit0 = max(pitch * switch(row0 > 1.5, scale_b, scale_r), pfl);\npit1 = max(pitch * switch(row1 > 1.5, scale_b, scale_g), pfl);\npit2 = max(pitch * scale_b, pfl);\nphx0 = switch(row0 > 1.5, phase_b_x, phase_r_x);\nphy0 = switch(row0 > 1.5, phase_b_y, phase_r_y);\nphx1 = switch(row1 > 1.5, phase_b_x, phase_g_x);\nphy1 = switch(row1 > 1.5, phase_b_y, phase_g_y);\n\nr0 = 0;\ng0 = 0;\nb0 = 0;\nif (en0 > 0.5) {\n    r0, g0, b0 = plate_path(is_pl, switch(is_ch > 0.5, 0, 3), norm.x, norm.y, screen, ang0, pit0, phx0, phy0,\n                            asp, wd, ht, soft, shp, jit, seed, level, bayer_cell, levels);\n}\nr1 = 0;\ng1 = 0;\nb1 = 0;\nif (en1 > 0.5) {\n    r1, g1, b1 = plate_path(2 * is_pl, switch(is_ch > 0.5, 1, 3), norm.x, norm.y, screen, ang1, pit1, phx1, phy1,\n                            asp, wd, ht, soft, shp, jit, seed, level, bayer_cell, levels);\n}\nr2 = 0;\ng2 = 0;\nb2 = 0;\nif (en2 > 0.5) {\n    r2, g2, b2 = plate_path(3 * is_pl, switch(is_ch > 0.5, 2, 3), norm.x, norm.y, screen, angle_b, pit2, phase_b_x, phase_b_y,\n                            asp, wd, ht, soft, shp, jit, seed, level, bayer_cell, levels);\n}\no_r = clamp(r0 + r1 + r2, 0, 1);\no_g = clamp(g0 + g1 + g2, 0, 1);\no_b = clamp(b0 + b1 + b2, 0, 1);\n\n// T028: Plates alpha, the largest connected plate's. T038 (US12, FR-030): each plate's alpha, the source's in Channels and\n// Single, its own input's in Plates; a plate that is off (Single's R and G rows, an unconnected plate) has alpha 0.\npv1 = nearest(in2, norm);\npv2 = nearest(in3, norm);\npv3 = nearest(in4, norm);\npa0 = switch(is_pl > 0.5, zap(pv1.w), za) * en0;\npa1 = switch(is_pl > 0.5, zap(pv2.w), za) * en1;\npa2 = switch(is_pl > 0.5, zap(pv3.w), za) * en2;\noa = switch(is_pl > 0.5, max(max(pa0, pa1), pa2), za);\n\nbyp = step(0.5, bypass_gate);\nout1 = mix(vec(o_r, o_g, o_b, oa), vec(zr, zg, zb, za), byp);\n\n// T038 (US12, FR-028, FR-029): outlets 2-4 carry plate k's term as summed above (Color, unclamped) or its brightest channel,\n// the coverage, as gray (Gray, plate_out 0). Bypass: the part of the source plate k would screen (Channels its channel,\n// Single the source on plate 3, Plates its input, not zapped). Written as plain arithmetic: per-component switch / zap calls\n// here pushed the GL3 transformer over its capture budget (bench probes 2026-11-14, as T035).\npc = step(0.5, plate_out);\nt0 = mix(vec(r0, g0, b0), vec(zr * is_ch, 0, 0) + vec(pv1.x, pv1.y, pv1.z) * is_pl * en0, byp);\nt1 = mix(vec(r1, g1, b1), vec(0, zg * is_ch, 0) + vec(pv2.x, pv2.y, pv2.z) * is_pl * en1, byp);\nt2 = mix(vec(r2, g2, b2), vec(zr * is_sg, zg * is_sg, zb * (1 - is_pl)) + vec(pv3.x, pv3.y, pv3.z) * is_pl * en2, byp);\nm0 = max(max(t0.x, t0.y), t0.z);\nm1 = max(max(t1.x, t1.y), t1.z);\nm2 = max(max(t2.x, t2.y), t2.z);\n// vec(vec3, scalar) does not build the four-component vector it reads as (bench 2026-11-14: zeros and a scrambled out4);\n// take the components one by one\ng0 = mix(vec(m0, m0, m0), t0, pc);\ng1 = mix(vec(m1, m1, m1), t1, pc);\ng2 = mix(vec(m2, m2, m2), t2, pc);\nout2 = vec(g0.x, g0.y, g0.z, pa0);\nout3 = vec(g1.x, g1.y, g1.z, pa1);\nout4 = vec(g2.x, g2.y, g2.z, pa2);\n",
									"fontface": 0,
									"fontname": "<Monospaced>",
									"fontsize": 12.0,
									"id": "gen-obj-2",
									"maxclass": "codebox",
									"numinlets": 5,
									"numoutlets": 4,
									"outlettype": [
										"",
										"",
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
							},
							{
								"box": {
									"id": "gen-obj-5",
									"maxclass": "newobj",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										142.0,
										490.0,
										35.0,
										22.0
									],
									"text": "out 3"
								}
							},
							{
								"box": {
									"id": "gen-obj-6",
									"maxclass": "newobj",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										202.0,
										490.0,
										35.0,
										22.0
									],
									"text": "out 4"
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
										"gen-obj-2",
										3
									],
									"source": [
										"gen-obj-12",
										0
									]
								}
							},
							{
								"patchline": {
									"destination": [
										"gen-obj-2",
										4
									],
									"source": [
										"gen-obj-13",
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
							},
							{
								"patchline": {
									"destination": [
										"gen-obj-5",
										0
									],
									"source": [
										"gen-obj-2",
										2
									]
								}
							},
							{
								"patchline": {
									"destination": [
										"gen-obj-6",
										0
									],
									"source": [
										"gen-obj-2",
										3
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
						1999.5,
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
						1779.5,
						260.0,
						290.0,
						164.0
					],
					"presentation": 1,
					"presentation_rect": [
						0.0,
						0.0,
						290.0,
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
						1999.5,
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
						2089.5,
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
						1999.5,
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
						2019.5,
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
						1779.5,
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
						1779.5,
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
						1779.5,
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
						1779.5,
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
						1779.5,
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
						1779.5,
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
					"id": "obj-100",
					"maxclass": "inlet",
					"comment": "plate 1 (Plates mode: screened at the R angle, phase and scale)",
					"index": 0,
					"numinlets": 0,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						260.0,
						20.0,
						30.0,
						30.0
					]
				}
			},
			{
				"box": {
					"id": "obj-101",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						260.0,
						70.0,
						80.0,
						22.0
					],
					"text": "vs_inState"
				}
			},
			{
				"box": {
					"id": "obj-103",
					"maxclass": "inlet",
					"comment": "plate 2 (Plates mode: screened at the G angle, phase and scale)",
					"index": 0,
					"numinlets": 0,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						430.0,
						20.0,
						30.0,
						30.0
					]
				}
			},
			{
				"box": {
					"id": "obj-104",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						430.0,
						70.0,
						80.0,
						22.0
					],
					"text": "vs_inState"
				}
			},
			{
				"box": {
					"id": "obj-106",
					"maxclass": "inlet",
					"comment": "plate 3 (Plates mode: screened at the B angle, phase and scale)",
					"index": 0,
					"numinlets": 0,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						600.0,
						20.0,
						30.0,
						30.0
					]
				}
			},
			{
				"box": {
					"id": "obj-107",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						600.0,
						70.0,
						80.0,
						22.0
					],
					"text": "vs_inState"
				}
			},
			{
				"box": {
					"id": "obj-static3-load",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"bang"
					],
					"patching_rect": [
						30.0,
						552.0,
						58.0,
						22.0
					],
					"text": "loadbang"
				}
			},
			{
				"box": {
					"id": "obj-static3-trig",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"bang",
						"bang"
					],
					"patching_rect": [
						30.0,
						582.0,
						40.0,
						22.0
					],
					"text": "t b b"
				}
			},
			{
				"box": {
					"id": "obj-static3-msg",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						60.0,
						612.0,
						160.0,
						22.0
					],
					"text": "read f_bluenoise64.jxf, bang"
				}
			},
			{
				"box": {
					"id": "obj-static3-matrix",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"jit_matrix",
						""
					],
					"patching_rect": [
						60.0,
						642.0,
						160.0,
						22.0
					],
					"text": "jit.matrix 1 float32 64 64"
				}
			},
			{
				"box": {
					"id": "obj-static3-tex",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"jit_gl_texture",
						""
					],
					"patching_rect": [
						30.0,
						672.0,
						240.0,
						22.0
					],
					"text": "jit.gl.texture vsynth @type float32 @adapt 1 @filter nearest"
				}
			},
			{
				"box": {
					"id": "obj-102",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						260.0,
						120.0,
						160.0,
						22.0
					],
					"text": "prepend param plate1_on"
				}
			},
			{
				"box": {
					"id": "obj-105",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						430.0,
						120.0,
						160.0,
						22.0
					],
					"text": "prepend param plate2_on"
				}
			},
			{
				"box": {
					"id": "obj-108",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						600.0,
						120.0,
						160.0,
						22.0
					],
					"text": "prepend param plate3_on"
				}
			},
			{
				"box": {
					"id": "obj-20",
					"maxclass": "live.menu",
					"fontname": "Ableton Sans Light",
					"hint": "Dot: a lattice of dots, each sized by the tone at its center. Line: parallel lines whose width follows the tone. Threshold: ink where the tone is above Level. Bayer: an ordered dither. Blue: an even, grainy dither with no visible grid. Random: a coarse, clumpy dither",
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
								"Bayer",
								"Blue",
								"Random"
							],
							"parameter_initial": [
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "screen",
							"parameter_mmax": 5.0,
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
					"hint": "Channels: red, green and blue are three plates, each at its own angle. Single: the texture is one spot-color plate, screened at the B row, in its own color. Plates: inlets 2-4 take f_separate's plates, screened at rows 1, 2, 3 and added (the main inlet is ignored)",
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
								"Single",
								"Plates"
							],
							"parameter_initial": [
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "plate_mode",
							"parameter_mmax": 2.0,
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
					"hint": "Lattice period in frame heights, for all three plates (each plate's Scale multiplies it). Below about 10 pixels the inked area stops tracking the tone. Bayer, Blue, Random: the grain cell is Pitch / 8, in whole pixels",
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
						8.5,
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
							"parameter_mmin": 0.009,
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
						3.0,
						20.0,
						38.0,
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
					"maxclass": "live.numbox",
					"fontname": "Ableton Sans Light",
					"hint": "Multiplies Pitch for the red plate alone, so the plates can run at different rulings (1 = Pitch)",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_halftone_pix::scale_r",
					"parameter_enable": 1,
					"patching_rect": [
						254.0,
						250.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						102.0,
						102.0,
						46.0,
						15.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								1.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "scale_r",
							"parameter_mmax": 4.0,
							"parameter_mmin": 0.25,
							"parameter_modmode": 3,
							"parameter_shortname": "scale_r",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"varname": "scale_r"
				}
			},
			{
				"box": {
					"id": "obj-30",
					"maxclass": "attrui",
					"attr": "scale_r",
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
					"text": "Scale R",
					"textjustification": 1,
					"varname": "lbl_scale_r",
					"hidden": 1
				}
			},
			{
				"box": {
					"id": "obj-32",
					"maxclass": "live.numbox",
					"fontname": "Ableton Sans Light",
					"hint": "Multiplies Pitch for the green plate alone (1 = Pitch)",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_halftone_pix::scale_g",
					"parameter_enable": 1,
					"patching_rect": [
						326.0,
						250.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						102.0,
						122.0,
						46.0,
						15.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								1.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "scale_g",
							"parameter_mmax": 4.0,
							"parameter_mmin": 0.25,
							"parameter_modmode": 3,
							"parameter_shortname": "scale_g",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"varname": "scale_g"
				}
			},
			{
				"box": {
					"id": "obj-33",
					"maxclass": "attrui",
					"attr": "scale_g",
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
					"text": "Scale G",
					"textjustification": 1,
					"varname": "lbl_scale_g",
					"hidden": 1
				}
			},
			{
				"box": {
					"id": "obj-35",
					"maxclass": "live.numbox",
					"fontname": "Ableton Sans Light",
					"hint": "Multiplies Pitch for the blue plate alone (1 = Pitch). Single uses this one",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_halftone_pix::scale_b",
					"parameter_enable": 1,
					"patching_rect": [
						398.0,
						250.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						102.0,
						142.0,
						46.0,
						15.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								1.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "scale_b",
							"parameter_mmax": 4.0,
							"parameter_mmin": 0.25,
							"parameter_modmode": 3,
							"parameter_shortname": "scale_b",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"varname": "scale_b"
				}
			},
			{
				"box": {
					"id": "obj-36",
					"maxclass": "attrui",
					"attr": "scale_b",
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
					"text": "Scale B",
					"textjustification": 1,
					"varname": "lbl_scale_b",
					"hidden": 1
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
						478.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						46.5,
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
					"id": "obj-39",
					"maxclass": "attrui",
					"attr": "softness",
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
						41.0,
						20.0,
						38.0,
						18.0
					],
					"text": "Soft",
					"textjustification": 1,
					"varname": "lbl_softness"
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
						550.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						84.5,
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
					"id": "obj-42",
					"maxclass": "attrui",
					"attr": "dot_shape",
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
						79.0,
						20.0,
						38.0,
						18.0
					],
					"text": "Shape",
					"textjustification": 1,
					"varname": "lbl_dot_shape"
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
						622.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						122.5,
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
					"id": "obj-45",
					"maxclass": "attrui",
					"attr": "jitter",
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
						117.0,
						20.0,
						38.0,
						18.0
					],
					"text": "Jitter",
					"textjustification": 1,
					"varname": "lbl_jitter"
				}
			},
			{
				"box": {
					"id": "obj-47",
					"maxclass": "live.numbox",
					"fontname": "Ableton Sans Light",
					"hint": "Which random pattern: the jitter, and the Blue and Random grain",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"int"
					],
					"param_connect": "#0_halftone_pix::seed",
					"parameter_enable": 1,
					"patching_rect": [
						686.0,
						250.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						197.0,
						36.0,
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
							"parameter_mmax": 256.0,
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
					"id": "obj-48",
					"maxclass": "attrui",
					"attr": "seed",
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
						195.0,
						20.0,
						38.0,
						18.0
					],
					"text": "Seed",
					"textjustification": 1,
					"varname": "lbl_seed"
				}
			},
			{
				"box": {
					"id": "obj-50",
					"maxclass": "live.numbox",
					"fontname": "Ableton Sans Light",
					"hint": "Bayer, Blue and Random: how many output values per channel. 2 is black and white; more steps between them, dithered",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"int"
					],
					"param_connect": "#0_halftone_pix::levels",
					"parameter_enable": 1,
					"patching_rect": [
						758.0,
						250.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						197.0,
						67.0,
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
							"parameter_longname": "levels",
							"parameter_mmax": 16.0,
							"parameter_mmin": 2.0,
							"parameter_modmode": 0,
							"parameter_shortname": "levels",
							"parameter_type": 1,
							"parameter_unitstyle": 0
						}
					},
					"varname": "levels"
				}
			},
			{
				"box": {
					"id": "obj-51",
					"maxclass": "attrui",
					"attr": "levels",
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
						195.0,
						51.0,
						38.0,
						16.0
					],
					"text": "Levels",
					"textjustification": 1,
					"varname": "lbl_levels"
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
						838.5,
						250.0,
						27.0,
						43.0
					],
					"presentation": 1,
					"presentation_rect": [
						160.5,
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
					"id": "obj-54",
					"maxclass": "attrui",
					"attr": "level",
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
						155.0,
						20.0,
						38.0,
						18.0
					],
					"text": "Level",
					"textjustification": 1,
					"varname": "lbl_level"
				}
			},
			{
				"box": {
					"id": "obj-56",
					"maxclass": "live.text",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"hint": "Bayer, Blue and Random. Cell: one tone per dither cell, so each cell is wholly lit or dark (an ordered dither). Pixel: the tone per pixel, so the image cuts through each cell. The same at 1-pixel cells",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"param_connect": "#0_halftone_pix::bayer_cell",
					"parameter_enable": 1,
					"patching_rect": [
						904.0,
						250.0,
						40.5,
						17.0
					],
					"presentation": 1,
					"presentation_rect": [
						238.0,
						51.0,
						40.0,
						17.0
					],
					"text": "Pixel",
					"texton": "Cell",
					"saved_attribute_attributes": {
						"activebgcolor": {
							"expression": ""
						},
						"activebgoncolor": {
							"expression": ""
						},
						"activetextcolor": {
							"expression": ""
						},
						"activetextoncolor": {
							"expression": ""
						},
						"bgoncolor": {
							"expression": ""
						},
						"valueof": {
							"parameter_enum": [
								"Pixel",
								"Cell"
							],
							"parameter_initial": [
								1.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "bayer_cell",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 0,
							"parameter_shortname": "bayer_cell",
							"parameter_type": 1,
							"parameter_unitstyle": 0
						}
					},
					"varname": "bayer_cell"
				}
			},
			{
				"box": {
					"id": "obj-57",
					"maxclass": "attrui",
					"attr": "bayer_cell",
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
					"id": "obj-59",
					"maxclass": "live.numbox",
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
						974.0,
						250.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						44.0,
						102.0,
						46.0,
						15.0
					],
					"saved_attribute_attributes": {
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
					"varname": "angle_r"
				}
			},
			{
				"box": {
					"id": "obj-60",
					"maxclass": "attrui",
					"attr": "angle_r",
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
						103.5,
						144.0,
						50.0,
						18.0
					],
					"text": "Angle R",
					"textjustification": 1,
					"varname": "lbl_angle_r",
					"hidden": 1
				}
			},
			{
				"box": {
					"id": "obj-62",
					"maxclass": "live.numbox",
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
						1046.0,
						250.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						44.0,
						122.0,
						46.0,
						15.0
					],
					"saved_attribute_attributes": {
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
					"varname": "angle_g"
				}
			},
			{
				"box": {
					"id": "obj-63",
					"maxclass": "attrui",
					"attr": "angle_g",
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
						140.5,
						144.0,
						50.0,
						18.0
					],
					"text": "Angle G",
					"textjustification": 1,
					"varname": "lbl_angle_g",
					"hidden": 1
				}
			},
			{
				"box": {
					"id": "obj-65",
					"maxclass": "live.numbox",
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
						1118.0,
						250.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						44.0,
						142.0,
						46.0,
						15.0
					],
					"saved_attribute_attributes": {
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
					"varname": "angle_b"
				}
			},
			{
				"box": {
					"id": "obj-66",
					"maxclass": "attrui",
					"attr": "angle_b",
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
						-7.5,
						206.0,
						50.0,
						18.0
					],
					"text": "Angle B",
					"textjustification": 1,
					"varname": "lbl_angle_b",
					"hidden": 1
				}
			},
			{
				"box": {
					"id": "obj-68",
					"maxclass": "live.numbox",
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
						1190.0,
						250.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						160.0,
						102.0,
						46.0,
						15.0
					],
					"saved_attribute_attributes": {
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
					"varname": "phase_r_x"
				}
			},
			{
				"box": {
					"id": "obj-69",
					"maxclass": "attrui",
					"attr": "phase_r_x",
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
						29.5,
						206.0,
						50.0,
						18.0
					],
					"text": "R x",
					"textjustification": 1,
					"varname": "lbl_phase_r_x",
					"hidden": 1
				}
			},
			{
				"box": {
					"id": "obj-71",
					"maxclass": "live.numbox",
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
						1262.0,
						250.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						218.0,
						102.0,
						46.0,
						15.0
					],
					"saved_attribute_attributes": {
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
					"varname": "phase_r_y"
				}
			},
			{
				"box": {
					"id": "obj-72",
					"maxclass": "attrui",
					"attr": "phase_r_y",
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
						66.5,
						206.0,
						50.0,
						18.0
					],
					"text": "R y",
					"textjustification": 1,
					"varname": "lbl_phase_r_y",
					"hidden": 1
				}
			},
			{
				"box": {
					"id": "obj-74",
					"maxclass": "live.numbox",
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
						1334.0,
						250.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						160.0,
						122.0,
						46.0,
						15.0
					],
					"saved_attribute_attributes": {
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
					"varname": "phase_g_x"
				}
			},
			{
				"box": {
					"id": "obj-75",
					"maxclass": "attrui",
					"attr": "phase_g_x",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1322.0,
						310.0,
						68.0,
						22.0
					],
					"style": ""
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
						1331.0,
						180.0,
						50.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						103.5,
						206.0,
						50.0,
						18.0
					],
					"text": "G x",
					"textjustification": 1,
					"varname": "lbl_phase_g_x",
					"hidden": 1
				}
			},
			{
				"box": {
					"id": "obj-77",
					"maxclass": "live.numbox",
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
						1406.0,
						250.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						218.0,
						122.0,
						46.0,
						15.0
					],
					"saved_attribute_attributes": {
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
					"varname": "phase_g_y"
				}
			},
			{
				"box": {
					"id": "obj-78",
					"maxclass": "attrui",
					"attr": "phase_g_y",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1394.0,
						310.0,
						68.0,
						22.0
					],
					"style": ""
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
						1403.0,
						180.0,
						50.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						140.5,
						206.0,
						50.0,
						18.0
					],
					"text": "G y",
					"textjustification": 1,
					"varname": "lbl_phase_g_y",
					"hidden": 1
				}
			},
			{
				"box": {
					"id": "obj-80",
					"maxclass": "live.numbox",
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
						1478.0,
						250.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						160.0,
						142.0,
						46.0,
						15.0
					],
					"saved_attribute_attributes": {
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
					"varname": "phase_b_x"
				}
			},
			{
				"box": {
					"id": "obj-81",
					"maxclass": "attrui",
					"attr": "phase_b_x",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1466.0,
						310.0,
						68.0,
						22.0
					],
					"style": ""
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
						1475.0,
						180.0,
						50.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						-7.5,
						268.0,
						50.0,
						18.0
					],
					"text": "B x",
					"textjustification": 1,
					"varname": "lbl_phase_b_x",
					"hidden": 1
				}
			},
			{
				"box": {
					"id": "obj-83",
					"maxclass": "live.numbox",
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
						1550.0,
						250.0,
						44.0,
						15.0
					],
					"presentation": 1,
					"presentation_rect": [
						218.0,
						142.0,
						46.0,
						15.0
					],
					"saved_attribute_attributes": {
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
					"varname": "phase_b_y"
				}
			},
			{
				"box": {
					"id": "obj-84",
					"maxclass": "attrui",
					"attr": "phase_b_y",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1538.0,
						310.0,
						68.0,
						22.0
					],
					"style": ""
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
						1547.0,
						180.0,
						50.0,
						18.0
					],
					"presentation": 1,
					"presentation_rect": [
						29.5,
						268.0,
						50.0,
						18.0
					],
					"text": "B y",
					"textjustification": 1,
					"varname": "lbl_phase_b_y",
					"hidden": 1
				}
			},
			{
				"box": {
					"id": "obj-86",
					"maxclass": "live.text",
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"hint": "What outlets 2-4 carry. Gray: each plate's coverage as a gray mask (for an effect such as f_vf_erode). Color: each plate in its color, as it enters outlet 1 (red, green, blue in Channels; the ink color in Single and Plates)",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"param_connect": "#0_halftone_pix::plate_out",
					"parameter_enable": 1,
					"patching_rect": [
						1624.0,
						250.0,
						40.5,
						17.0
					],
					"presentation": 1,
					"presentation_rect": [
						186.0,
						3.0,
						40.0,
						15.0
					],
					"text": "Gray",
					"texton": "Color",
					"saved_attribute_attributes": {
						"activebgcolor": {
							"expression": ""
						},
						"activebgoncolor": {
							"expression": ""
						},
						"activetextcolor": {
							"expression": ""
						},
						"activetextoncolor": {
							"expression": ""
						},
						"bgoncolor": {
							"expression": ""
						},
						"valueof": {
							"parameter_enum": [
								"Gray",
								"Color"
							],
							"parameter_initial": [
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "plate_out",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 0,
							"parameter_shortname": "plate_out",
							"parameter_type": 1,
							"parameter_unitstyle": 0
						}
					},
					"varname": "plate_out"
				}
			},
			{
				"box": {
					"id": "obj-87",
					"maxclass": "attrui",
					"attr": "plate_out",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1610.0,
						310.0,
						68.0,
						22.0
					],
					"style": ""
				}
			},
			{
				"box": {
					"id": "obj-89",
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
						1999.5,
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
					"id": "obj-90",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1999.5,
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
						240.0,
						842.0,
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
						380.0,
						842.0,
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
						380.0,
						872.0,
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
						290.0,
						842.0,
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
						290.0,
						872.0,
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
						240.0,
						902.0,
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
						370.0,
						902.0,
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
			},
			{
				"box": {
					"id": "obj-raw-head0",
					"maxclass": "comment",
					"text": "Angle",
					"patching_rect": [
						380.0,
						542.0,
						50.0,
						18.0
					],
					"presentation_rect": [
						42.0,
						86.0,
						50.0,
						16.0
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"textjustification": 1,
					"numinlets": 1,
					"numoutlets": 0,
					"outlettype": [],
					"presentation": 1
				}
			},
			{
				"box": {
					"id": "obj-raw-head1",
					"maxclass": "comment",
					"text": "Scale",
					"patching_rect": [
						380.0,
						564.0,
						50.0,
						18.0
					],
					"presentation_rect": [
						100.0,
						86.0,
						50.0,
						16.0
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"textjustification": 1,
					"numinlets": 1,
					"numoutlets": 0,
					"outlettype": [],
					"presentation": 1
				}
			},
			{
				"box": {
					"id": "obj-raw-head2",
					"maxclass": "comment",
					"text": "X",
					"patching_rect": [
						380.0,
						586.0,
						50.0,
						18.0
					],
					"presentation_rect": [
						158.0,
						86.0,
						50.0,
						16.0
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"textjustification": 1,
					"numinlets": 1,
					"numoutlets": 0,
					"outlettype": [],
					"presentation": 1
				}
			},
			{
				"box": {
					"id": "obj-raw-head3",
					"maxclass": "comment",
					"text": "Y",
					"patching_rect": [
						380.0,
						608.0,
						50.0,
						18.0
					],
					"presentation_rect": [
						216.0,
						86.0,
						50.0,
						16.0
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"textjustification": 1,
					"numinlets": 1,
					"numoutlets": 0,
					"outlettype": [],
					"presentation": 1
				}
			},
			{
				"box": {
					"id": "obj-raw-rowr",
					"maxclass": "comment",
					"text": "R",
					"varname": "lbl_plate_r",
					"patching_rect": [
						440.0,
						542.0,
						30.0,
						18.0
					],
					"presentation_rect": [
						10.0,
						101.0,
						24.0,
						16.0
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"textjustification": 1,
					"numinlets": 1,
					"numoutlets": 0,
					"outlettype": [],
					"presentation": 1
				}
			},
			{
				"box": {
					"id": "obj-raw-rowg",
					"maxclass": "comment",
					"text": "G",
					"varname": "lbl_plate_g",
					"patching_rect": [
						440.0,
						564.0,
						30.0,
						18.0
					],
					"presentation_rect": [
						10.0,
						121.0,
						24.0,
						16.0
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"textjustification": 1,
					"numinlets": 1,
					"numoutlets": 0,
					"outlettype": [],
					"presentation": 1
				}
			},
			{
				"box": {
					"id": "obj-raw-rowb",
					"maxclass": "comment",
					"text": "B",
					"varname": "lbl_plate_b",
					"patching_rect": [
						440.0,
						586.0,
						30.0,
						18.0
					],
					"presentation_rect": [
						10.0,
						141.0,
						24.0,
						16.0
					],
					"fontname": "Ableton Sans Light",
					"fontsize": 9.5,
					"textjustification": 1,
					"numinlets": 1,
					"numoutlets": 0,
					"outlettype": [],
					"presentation": 1
				}
			},
			{
				"box": {
					"id": "obj-raw-platesel",
					"maxclass": "newobj",
					"text": "sel 2",
					"numinlets": 2,
					"numoutlets": 2,
					"outlettype": [
						"bang",
						""
					],
					"patching_rect": [
						500.0,
						542.0,
						40.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-raw-setnumr",
					"maxclass": "message",
					"text": "set 1",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						500.0,
						572.0,
						50.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-raw-setletr",
					"maxclass": "message",
					"text": "set R",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						500.0,
						602.0,
						50.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-raw-setnumg",
					"maxclass": "message",
					"text": "set 2",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						560.0,
						572.0,
						50.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-raw-setletg",
					"maxclass": "message",
					"text": "set G",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						560.0,
						602.0,
						50.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-raw-setnumb",
					"maxclass": "message",
					"text": "set 3",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						620.0,
						572.0,
						50.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-raw-setletb",
					"maxclass": "message",
					"text": "set B",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						620.0,
						602.0,
						50.0,
						22.0
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
						"obj-5",
						2
					],
					"destination": [
						"obj-202",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-5",
						3
					],
					"destination": [
						"obj-203",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-100",
						0
					],
					"destination": [
						"obj-101",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-101",
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
						"obj-101",
						1
					],
					"destination": [
						"obj-102",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-102",
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
						"obj-103",
						0
					],
					"destination": [
						"obj-104",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-104",
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
						"obj-104",
						1
					],
					"destination": [
						"obj-105",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-105",
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
						"obj-106",
						0
					],
					"destination": [
						"obj-107",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-107",
						0
					],
					"destination": [
						"obj-5",
						3
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-107",
						1
					],
					"destination": [
						"obj-108",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-108",
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
						"obj-static3-load",
						0
					],
					"destination": [
						"obj-static3-trig",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-static3-trig",
						1
					],
					"destination": [
						"obj-static3-msg",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-static3-msg",
						0
					],
					"destination": [
						"obj-static3-matrix",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-static3-matrix",
						0
					],
					"destination": [
						"obj-static3-tex",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-static3-trig",
						0
					],
					"destination": [
						"obj-static3-tex",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-static3-tex",
						0
					],
					"destination": [
						"obj-5",
						4
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
						"obj-4",
						18
					],
					"destination": [
						"obj-74",
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
						"obj-4",
						19
					],
					"destination": [
						"obj-77",
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
						"obj-5",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-4",
						20
					],
					"destination": [
						"obj-80",
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
						"obj-5",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-4",
						21
					],
					"destination": [
						"obj-83",
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
						"obj-5",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-4",
						22
					],
					"destination": [
						"obj-86",
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
			},
			{
				"patchline": {
					"source": [
						"obj-23",
						0
					],
					"destination": [
						"obj-raw-platesel",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-platesel",
						0
					],
					"destination": [
						"obj-raw-setnumr",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-setnumr",
						0
					],
					"destination": [
						"obj-raw-rowr",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-platesel",
						1
					],
					"destination": [
						"obj-raw-setletr",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-setletr",
						0
					],
					"destination": [
						"obj-raw-rowr",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-platesel",
						0
					],
					"destination": [
						"obj-raw-setnumg",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-setnumg",
						0
					],
					"destination": [
						"obj-raw-rowg",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-platesel",
						1
					],
					"destination": [
						"obj-raw-setletg",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-setletg",
						0
					],
					"destination": [
						"obj-raw-rowg",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-platesel",
						0
					],
					"destination": [
						"obj-raw-setnumb",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-setnumb",
						0
					],
					"destination": [
						"obj-raw-rowb",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-platesel",
						1
					],
					"destination": [
						"obj-raw-setletb",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-raw-setletb",
						0
					],
					"destination": [
						"obj-raw-rowb",
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
				"scale_r",
				"scale_r",
				0
			],
			"obj-32": [
				"scale_g",
				"scale_g",
				0
			],
			"obj-35": [
				"scale_b",
				"scale_b",
				0
			],
			"obj-38": [
				"softness",
				"softness",
				0
			],
			"obj-41": [
				"dot_shape",
				"dot_shape",
				0
			],
			"obj-44": [
				"jitter",
				"jitter",
				0
			],
			"obj-47": [
				"seed",
				"seed",
				0
			],
			"obj-50": [
				"levels",
				"levels",
				0
			],
			"obj-53": [
				"level",
				"level",
				0
			],
			"obj-56": [
				"bayer_cell",
				"bayer_cell",
				0
			],
			"obj-59": [
				"angle_r",
				"angle_r",
				0
			],
			"obj-62": [
				"angle_g",
				"angle_g",
				0
			],
			"obj-65": [
				"angle_b",
				"angle_b",
				0
			],
			"obj-68": [
				"phase_r_x",
				"phase_r_x",
				0
			],
			"obj-71": [
				"phase_r_y",
				"phase_r_y",
				0
			],
			"obj-74": [
				"phase_g_x",
				"phase_g_x",
				0
			],
			"obj-77": [
				"phase_g_y",
				"phase_g_y",
				0
			],
			"obj-80": [
				"phase_b_x",
				"phase_b_x",
				0
			],
			"obj-83": [
				"phase_b_y",
				"phase_b_y",
				0
			],
			"obj-86": [
				"plate_out",
				"plate_out",
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