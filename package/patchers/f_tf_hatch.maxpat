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
					"comment": "streaks",
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
					"hint": "Hatch strokes, luma on black (color is downstream's job): strokes follow the tensor's structure axis and lengthen where coherence is high; grain where it is low; nothing below the structure floor. @type float32."
				}
			},
			{
				"box": {
					"id": "obj-201",
					"maxclass": "outlet",
					"comment": "streak field",
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
					"hint": "The same field without the Line style (soft strokes), for downstream styling or gating. NOT a tensor and not a vecfield."
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
					"numoutlets": 8,
					"outlettype": [
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
						583.0,
						22.0
					],
					"text": "route reach grain density contrast line_hard structure_floor angle_offset coh_floor"
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
									"code": "// Stage E1 (f_tf_hatch v2): tensor decode + presence. in1 = the TENSOR\n// (f_tf_tensormap outlet 0, raw float32; f_tensor_type.md encoding).\n// Mirrors tests/modules/tf_hatch/tf_hatch_mirror.py stage_e1 (aux_mode\n// \"unsigned_nearest\", spec OQ2 decided 2026-10-28). Intermediate texture,\n// NEVER an outlet; unbounded float32 (no clamp, no 0.5 offset).\n//\n// out1 = (ca, sa, coh, pres):\n//   (ca, sa)  cos/sin of the ALONG-structure axis + angle_offset*pi/2. The\n//             axis is an unoriented line; E2 recovers sign continuity itself\n//             (dot-product alignment), so this pair is read with `nearest`\n//             only (interpolating it would flip sign at the horizontal cut).\n//   coh       coherence (lambda1-lambda2)/(lambda1+lambda2), gain-free\n//             (tensormap plan ADR-2). Enters E2 ONLY as direction persistence.\n//   pres      PRESENCE: smooth ramp on the tensormap-encoded trace (R + B)\n//             against structure_floor^2. Brightness gate only (E3 applies it).\n//   Where trace <= eps_trace (zero / direction-undefined tensor): axis UNSET\n//   (0, 0), coh 0, pres 0 -- never an atan2(0,0) artifact.\n//\n// DECODE IDIOM: .specify/f_tf_glyph/plan.md ADR-2 WITHOUT the gain divide (the Strength\n// dial was removed 2026-10-29: axis and coherence are ratios and presence reads the\n// encoded trace, so dividing the tensormap's gain back out changed nothing but the\n// zero guard). Everything below is in ENCODED units (J * the tensormap's strength):\n//   Jxx = R; Jxy = (G-0.5)*2; Jyy = B\n//   theta = 0.5*atan2(2*Jxy, Jxx-Jyy)  (GRADIENT axis; along = theta + pi/2)\n// The read is AT norm (texel centred, always in-bounds).\n\nParam angle_offset(0.0);\nParam structure_floor(0.1);\n\n// zero-tensor guard on the ENCODED trace (was 1e-6 in J units = 1e-4 at strength 100)\neps_trace = 0.0001;\n\n// (component access INLINE on sample(): on a stored variable it silently fails)\njxx = sample(in1, norm).r;\njxy = (sample(in1, norm).g - 0.5) * 2.0;\njyy = sample(in1, norm).b;\ntrace = jxx + jyy;\ndiff = jxx - jyy;\nroot = sqrt(diff*diff + 4.0*jxy*jxy);\ntheta = 0.5 * atan2(2.0*jxy, diff);\n\niso = 1.0 - step(eps_trace, trace);   // 1 = zero/undefined tensor\ncoh = clamp(root / max(trace, eps_trace), 0.0, 1.0);\n\neff = theta + halfpi + angle_offset * halfpi;\nca = cos(eff) * (1.0 - iso);\nsa = sin(eff) * (1.0 - iso);\n\n// presence: enc_trace = R + B = trace * the producing tensormap's strength.\n// thr = floor^2 (finer at the low end); ramp 0.5*thr -> 1.5*thr (+ a hair, so\n// floor 0 is a step at the iso guard).\nenc_trace = sample(in1, norm).r + sample(in1, norm).b;\nthr = structure_floor * structure_floor;\npres = smoothstep(0.5 * thr, 1.5 * thr + 0.000001, enc_trace) * (1.0 - iso);\n\nout1 = vec(ca, sa, coh * (1.0 - iso), pres);\n",
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
					"text": "jit.gl.pix vsynth @name #0_hatch_stage_e1 @adapt 0 @dim 256 256 @type float32",
					"varname": "#0_hatch_stage_e1"
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
									"code": "// Stage E2 (f_tf_hatch v2): the streamline march. in1 = E1's aux (ca, sa, coh,\n// pres), render-sized (Width / Height Params = its size). Mirrors\n// tests/modules/tf_hatch/tf_hatch_mirror.py stage_e2 (sparse mode).\n//\n// Per pixel: march N = 16 steps each way along the local axis, accumulating\n// sparse impulse noise. All geometry is in PIXEL units (steps are uniform in\n// pixels, so a non-square frame still gets round streaks).\n//   - sign continuity: the axis has no sign; each step flips it to agree with\n//     the previous direction (dot product), so there is no branch cut.\n//   - coherence enters ONLY as persistence (spec OQ1): d = normalize(w*a +\n//     (1-w)*r), w = coh^0.5, r = a per-pixel/per-step hashed unit vector.\n//     Coherent regions march ballistically (streaks), incoherent ones random-\n//     walk (grain). Never shape, never brightness.\n//   - noise lives in WORLD coordinates: round BLOB impulses from rotated value\n//     noise (blob_noise below; lattice scale from `grain`), thresholded so their\n//     coverage equals the lit probability set by `density`.\n//   - brightness = blob coverage crossed (acc * step / cell_px), so one\n//     impulse's stroke has brightness ~1 whatever reach and grain are (a low-\n//     density blob peaks below 1: same expected coverage, dimmer peak).\n//   - a path that leaves the frame stops contributing (`alive` latch).\n//   - the step must not exceed the cell size (step <= cell_px) or cells can be\n//     skipped; at N = 16 this bounds reach against grain.\n//\n// Coordinates: `norm` = (i + 0.5)/size (texel centres; tests/lib/gpu_sim.py,\n// jxf.py), so the pixel's own texel centre is norm*size = i + 0.5. (`cell`\n// would be norm*(size-1): not used.) Reads: `nearest` at (pos/size). size = the\n// Width / Height Params (never `dim`: see below).\n//\n// Params (names avoid GenExpr operators: `length` is one, hence `reach`):\n//   reach    0..1  half-length of the march = reach * 0.25 * frame height\n//   grain    0..1  noise cell size, log: cells per frame height =\n//                  2^((1-grain)*6+3)\n//   density  0..1  impulse coverage = 0.0025 * 2^(5*density), via the\n//                  closed-form blob threshold\n//   coh_floor   0..1  stroke termination (below): 0 = off\n//   src_stroke  internal: 1 when the optional stroke-texture inlet (in2) is connected\n// out1 = (raw blob-coverage-crossed, pres, 0, 1)   (texture connected: raw = the mean impulse along the path)\n//\n// COHERENCE FLOOR (2026-10-29; mirror: coh_floor; Matt's choice, \"Terminate\", from the Clouds / Dark / Terminate\n// sheet; this supersedes spec OQ1's \"coherence only as persistence\" for coh_floor > 0). Each step's contribution is\n// scaled by smoothstep(coh_floor - 0.2, coh_floor, coherence at the step's start): strokes end where direction is\n// lost, and the pixel's own presence (what E3 multiplies by) is scaled by the same ramp on its OWN coherence, so an\n// undirected region goes BLACK (Matt, 2026-10-29: keeping the pixel's own mark read as bright dots, not black). At 0\n// both factors are exactly 1, so the default is today's look bit for bit. One smoothstep and one multiply per step.\n//\n// STROKE TEXTURE (2026-10-29; mirror: texture_coord / texture_impulse): with in2 connected the impulse is\n// the texture's Rec.709 luma, soft-thresholded, instead of a blob; the marks are then the texture streaked\n// along the contours. Grain = ZOOM: the texture is tiled 2^((1-grain)*6) times across the frame (grain 1 =\n// once, 64 tiles at grain 0; same six octaves as the blob cell). Density = the soft threshold on the luma:\n// smoothstep(thr - 0.1, thr + 0.1, luma), thr = 1.1 - 1.2 * density. Sampled by `nearest` at the\n// frame-normalized march position. Brightness = acc / wsum, the plain LIC mean (not blob coverage crossed).\n// COST (bench, 1080p, E2 alone; the module adds ~1.5 ms for E1 + E3): blobs 3.0 ms. Texture mode is memory-bound, not\n// arithmetic-bound (a 4x4 texture costs 2.7): the texture's size times the tiling stride. A float32 1080p texture\n// costs 13 ms at Grain 0.5 and 12.5 at Grain 0 but 5.0 at Grain 1 (read once, sequential); 256x256 4.8, 512x512 5.1,\n// 1024x1024 6.9 at Grain 0.5. Fetch count and the if/else cost nothing (probes 1 and 2). Accepted 2026-10-29 as a\n// heavy OPTIONAL mode: feed it a small texture, or keep Grain near 1.\n\n// Hashes WITHOUT sin (Hoskins' \"hash without sine\"): sin(ix*127.1+iy*311.7)*43758\n// loses all precision on the GPU once the argument reaches ~1e4-1e5 (1080p\n// lattices), which can make the lit-cell pattern clump and flip with tiny\n// `grain` changes. Every intermediate here stays below ~1e3.\nhash12(ha, hb) {\n    hx = fract(ha * 0.1031);\n    hy = fract(hb * 0.1031);\n    hz = hx;\n    hd = hx * (hy + 33.33) + hy * (hz + 33.33) + hz * (hx + 33.33);\n    hx = hx + hd;\n    hy = hy + hd;\n    hz = hz + hd;\n    return fract((hx + hy) * hz);\n}\n\nhash13(ha, hb, hc) {\n    hx = fract(ha * 0.1031);\n    hy = fract(hb * 0.1031);\n    hz = fract(hc * 0.1031);\n    hd = hx * (hz + 31.32) + hy * (hy + 31.32) + hz * (hx + 31.32);\n    hx = hx + hd;\n    hy = hy + hd;\n    hz = hz + hd;\n    return fract((hx + hy) * hz);\n}\n\n// Band-limited blob impulse (2026-10-29; mirror: blob_noise / value_noise). Quintic value\n// noise on a lattice ROTATED 22.5 deg (cos 0.9238795, sin 0.3826834: the pixel's axis and\n// diagonal directions see the same noise), thresholded with a soft ramp. Replaces the lit\n// lattice cells, whose squares painted axis-aligned rectangles. bext = (W + H)/cell keeps\n// the lattice index positive after the rotation. Four hash12 taps per sample.\nblob_noise(cx, cy, cell_sz, bthr, bwid, bext) {\n    bu = (0.9238795 * cx - 0.3826834 * cy) / cell_sz + bext;\n    bv = (0.3826834 * cx + 0.9238795 * cy) / cell_sz + bext;\n    bi = floor(bu);\n    bj = floor(bv);\n    bfu = bu - bi;\n    bfv = bv - bj;\n    bfu = bfu * bfu * bfu * (bfu * (bfu * 6.0 - 15.0) + 10.0);\n    bfv = bfv * bfv * bfv * (bfv * (bfv * 6.0 - 15.0) + 10.0);\n    bh00 = hash12(bi, bj);\n    bh10 = hash12(bi + 1.0, bj);\n    bh01 = hash12(bi, bj + 1.0);\n    bh11 = hash12(bi + 1.0, bj + 1.0);\n    bn = (bh00 * (1.0 - bfu) + bh10 * bfu) * (1.0 - bfv) + (bh01 * (1.0 - bfu) + bh11 * bfu) * bfv;\n    return smoothstep(bthr - bwid, bthr + bwid, bn);\n}\n\nParam reach(0.5);\nParam grain(0.5);\nParam density(0.7);\nParam src_stroke(0.0);    // 1 when the stroke-texture inlet is connected (vs_inState)\nParam coh_floor(0.0);     // 0..1: a stroke ends where the coherence along its path drops (0 = off)\n// Render size. NOT `dim`: live jit.gl.pix cannot read its own size (`dim` reads ~1 x 1 in a\n// Vsynth chain, found 2026-10-29: with dim ~ 1 the position clamp [0.5, dim - 0.5] pins every\n// march step to the frame centre, so nothing follows the tensor). Vsynth drives these two Params\n// (definition `render_dim`: `r dim` -> `prepend param width/height`); nobody sets them by hand.\nParam width(1920.0);\nParam height(1080.0);\n\nwpx = width;\nhpx = height;\nx0 = norm.x * wpx;\ny0 = norm.y * hpx;\n\nhalf_len = reach * 0.25 * hpx;\nh_step = half_len / 16.0;\ncell_px = hpx / pow(2.0, (1.0 - grain) * 6.0 + 3.0);\n// blob threshold: a closed-form cubic in density, fit so the soft-ramped coverage equals the\n// lit probability 0.0025 * 2^(5 density) (mirror BLOB_THR; blob_fit.py; worst error 3.2%)\nblob_thr = 0.999341 + density * (-0.092880 + density * (0.011592 + density * -0.084665));\nblob_wid = 0.079065;                  // 0.35 * 0.2259 (BLOB_SOFT * BLOB_STD)\nblob_ext = (wpx + hpx) / cell_px;\npersist_pow = 0.5;\ntex_on = step(0.5, src_stroke);\ntiles = pow(2.0, (1.0 - grain) * 6.0);\ntex_thr = 1.1 - 1.2 * density;\n\nca0 = nearest(in1, norm).x;\nsa0 = nearest(in1, norm).y;\npres0 = nearest(in1, norm).w;\ncoh0 = nearest(in1, norm).z;     // this pixel's own coherence (the Coh Floor black-out)\n// unset axis (0, 0) -> a fixed fallback axis (E3 multiplies by presence 0 there)\nm0 = sqrt(ca0 * ca0 + sa0 * sa0);\nok0 = step(0.000001, m0);\nca0 = mix(1.0, ca0 / max(m0, 0.000001), ok0);\nsa0 = mix(0.0, sa0 / max(m0, 0.000001), ok0);\n\nimp = 0.0;\nif (tex_on > 0.5) {\n    tu = fract(tiles * x0 / wpx);\n    tv = fract(tiles * y0 / hpx);\n    tl = 0.2126 * nearest(in2, vec(tu, tv)).x + 0.7152 * nearest(in2, vec(tu, tv)).y + 0.0722 * nearest(in2, vec(tu, tv)).z;\n    imp = smoothstep(tex_thr - 0.1, tex_thr + 0.1, tl);\n} else {\n    imp = blob_noise(x0, y0, cell_px, blob_thr, blob_wid, blob_ext);\n}\nacc = imp;\nwsum = 1.0;\npx = x0;\npy = y0;\ndx = 0.0;\ndy = 0.0;\nalive = 1.0;\nsgn = 1.0;\nfor (side = 0; side < 2; side += 1) {\n    px = x0;\n    py = y0;\n    alive = 1.0;\n    sgn = 1.0 - 2.0 * side;\n    dx = sgn * ca0;\n    dy = sgn * sa0;\n    for (k = 1; k <= 16; k += 1) {\n        ux = px / wpx;      // px is clamped to [0.5, W-0.5]: strictly inside (0, 1)\n        uy = py / hpx;\n        ax = nearest(in1, vec(ux, uy)).x;\n        ay = nearest(in1, vec(ux, uy)).y;\n        coh = nearest(in1, vec(ux, uy)).z;\n        am = sqrt(ax * ax + ay * ay);\n        oka = step(0.000001, am);\n        ax = mix(1.0, ax / max(am, 0.000001), oka);\n        ay = mix(0.0, ay / max(am, 0.000001), oka);\n        dp = ax * dx + ay * dy;\n        flipv = 2.0 * step(0.0, dp) - 1.0;\n        ax = ax * flipv;\n        ay = ay * flipv;\n        wgt = pow(clamp(coh, 0.0, 1.0), persist_pow);\n        ang = twopi * hash13(floor(x0), floor(y0), k + 32.0 * side);\n        mx = wgt * ax + (1.0 - wgt) * cos(ang);\n        my = wgt * ay + (1.0 - wgt) * sin(ang);\n        mm = sqrt(mx * mx + my * my);\n        okm = step(0.000001, mm);\n        ax = mix(ax, mx / max(mm, 0.000001), okm);\n        ay = mix(ay, my / max(mm, 0.000001), okm);\n        nx = px + h_step * ax;\n        ny = py + h_step * ay;\n        alive = alive * step(0.0, nx) * step(nx, wpx) * step(0.0, ny) * step(ny, hpx);\n        alive = alive * smoothstep(coh_floor - 0.2, coh_floor, coh);   // 1 exactly at coh_floor 0\n        px = clamp(nx, 0.5, wpx - 0.5);\n        py = clamp(ny, 0.5, hpx - 0.5);\n        dx = ax;\n        dy = ay;\n        if (tex_on > 0.5) {\n            tu = fract(tiles * px / wpx);\n            tv = fract(tiles * py / hpx);\n            tl = 0.2126 * nearest(in2, vec(tu, tv)).x + 0.7152 * nearest(in2, vec(tu, tv)).y + 0.0722 * nearest(in2, vec(tu, tv)).z;\n            imp = smoothstep(tex_thr - 0.1, tex_thr + 0.1, tl);\n        } else {\n            imp = blob_noise(px, py, cell_px, blob_thr, blob_wid, blob_ext);\n        }\n        acc = acc + alive * imp;\n        wsum = wsum + alive;\n    }\n}\nraw = mix(acc * h_step / cell_px, acc / wsum, tex_on);\nout1 = vec(raw, pres0 * smoothstep(coh_floor - 0.2, coh_floor, coh0), 0.0, 1.0);   // 1 exactly at coh_floor 0\n",
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
						216.0,
						22.0
					],
					"text": "jit.gl.pix vsynth @name #0_hatch_stage_e2 @adapt 0 @dim 256 256 @type float32",
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
									"code": "// Stage E3 (f_tf_hatch v2): style + presence + encode. in1 = E2's aux2\n// (raw lit-cells-crossed, pres, 0, 1). Mirrors tests/modules/tf_hatch/\n// tf_hatch_mirror.py stage_e3 (sparse mode). The ONLY stage that clamps.\n//\n//   contrast  0..1  gain on the raw lit-cells-crossed value, 0.6 -> 2.0\n//                   (PROVISIONAL, tier-3 confirms)\n//   line_hard 0..1  0 = smooth field, 1 = hard engraved strokes (threshold at\n//                   0.5 with a soft edge of half-width 0.5 -> 0.03)\n//   presence multiplies the styled field (structure floor)\n//   bypass_gate     black on both outlets, alpha 1 (outlet contract)\n//\n// out1 = module OUTLET 0: styled strokes, luma on black, A = 1 (color is\n// downstream's job). out2 = module OUTLET 1: the unstyled normalized field\n// (same luma without `line_hard`), A = 1 (spec OQ4).\n\nParam contrast(0.5);\nParam line_hard(0.0);\nParam bypass_gate(0.0);\n\nraw = nearest(in1, norm).x;\npres = nearest(in1, norm).y;\n\nv = clamp(raw * (0.6 + contrast * 1.4), 0.0, 1.0);\nw = 0.5 + (0.03 - 0.5) * line_hard;\nhard = smoothstep(0.5 - w, 0.5 + w, v);\nstyled = v + (hard - v) * line_hard;\n\no0 = mix(styled * pres, 0.0, bypass_gate);\no1 = mix(v * pres, 0.0, bypass_gate);\nout1 = vec(o0, o0, o0, 1.0);\nout2 = vec(o1, o1, o1, 1.0);\n",
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
					"text": "jit.gl.pix vsynth @name #0_hatch_stage_e3 @adapt 0 @dim 256 256 @type float32",
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
						980.0,
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
						760.0,
						260.0,
						190.0,
						150.0
					],
					"presentation": 1,
					"presentation_rect": [
						0.0,
						0.0,
						190.0,
						150.0
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
						92.0,
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
					"fontsize": 11.0,
					"textcolor": [
						0.85,
						0.55,
						0.2,
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
						94.0,
						0.9,
						70.0,
						21.0
					],
					"text": "T_ in"
				}
			},
			{
				"box": {
					"id": "obj-19f",
					"maxclass": "panel",
					"background": 0,
					"bgcolor": [
						0.85,
						0.55,
						0.2,
						1.0
					],
					"border": 0,
					"mode": 0,
					"hint": "Takes: tensor",
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
					"id": "obj-100",
					"maxclass": "inlet",
					"comment": "stroke texture (optional): the marks streaked along the contours; unconnected = the built-in blobs. HEAVY at 1080p: a full-size float32 texture at a low Grain makes E2 take 12-13 ms (blobs 3); a texture of 1024x1024 or less, or Grain near 1, keeps it at 5-7 ms",
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
					"text": "prepend param src_stroke"
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
					"hint": "Stroke length: half-length of the march, 0 to a quarter of the frame height on each side. Strokes only get this long where coherence is high; 0 draws nothing. With very fine Grain at full Length the march can skip noise cells and strokes get gaps. PROVISIONAL.",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_hatch_stage_e2::reach",
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
							"parameter_longname": "reach",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "reach",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "reach"
				}
			},
			{
				"box": {
					"id": "obj-21",
					"maxclass": "attrui",
					"attr": "reach",
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
					"text": "Length",
					"textjustification": 1,
					"varname": "lbl_reach"
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
					"hint": "Feature scale of the noise the strokes are drawn from, log-mapped: low = fine, thin strokes; high = coarse, thick strokes (and fewer of them). PROVISIONAL.",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_hatch_stage_e2::grain",
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
								0.5
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "grain",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "grain",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "grain"
				}
			},
			{
				"box": {
					"id": "obj-24",
					"maxclass": "attrui",
					"attr": "grain",
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
					"text": "Grain",
					"textjustification": 1,
					"varname": "lbl_grain"
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
					"hint": "How many strokes: how much of the frame the noise blobs the strokes are drawn from cover (0.25% at 0 to 8% at 1). PROVISIONAL.",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_hatch_stage_e2::density",
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
								0.7
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
					"id": "obj-27",
					"maxclass": "attrui",
					"attr": "density",
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
					"text": "Density",
					"textjustification": 1,
					"varname": "lbl_density"
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
					"hint": "Stroke brightness gain (0.6x at 0 to 2x at 1). PROVISIONAL.",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_hatch_stage_e3::contrast",
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
								0.5
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "contrast",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "contrast",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "contrast"
				}
			},
			{
				"box": {
					"id": "obj-30",
					"maxclass": "attrui",
					"attr": "contrast",
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
					"text": "Contrast",
					"textjustification": 1,
					"varname": "lbl_contrast"
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
					"hint": "Stroke style: 0 = soft, 1 = hard engraved lines (thresholded with a soft edge). Outlet 1 stays soft.",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_hatch_stage_e3::line_hard",
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
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "line_hard",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "line_hard",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "line_hard"
				}
			},
			{
				"box": {
					"id": "obj-33",
					"maxclass": "attrui",
					"attr": "line_hard",
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
					"text": "Line",
					"textjustification": 1,
					"varname": "lbl_line_hard"
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
					"hint": "Structure floor: where there is too little structure to mark, draw nothing. Reads the tensormap's trace scale (trace x its Strength; strong structure is ~1), squared for finer control at the low end. 0 = marks wherever any structure exists. Not strength-invariant: calibrate with the tensormap's Strength. PROVISIONAL default.",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_hatch_stage_e1::structure_floor",
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
								0.1
							],
							"parameter_initial_enable": 1,
							"parameter_linknames": 1,
							"parameter_longname": "structure_floor",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "structure_floor",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "structure_floor"
				}
			},
			{
				"box": {
					"id": "obj-36",
					"maxclass": "attrui",
					"attr": "structure_floor",
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
					"text": "Floor",
					"textjustification": 1,
					"varname": "lbl_structure_floor"
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
					"hint": "Rotates the streaks relative to the structure axis: +-1 = +-90 deg (the axis is an unoriented line, so +-90 spans the distinct layouts). Zero keeps strokes along structure.",
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
					"hint": "Where the tensor loses its direction (low coherence) the output goes black and strokes end, instead of smearing into clouds: below this coherence a path stops contributing and the pixel fades to black (ramped over the 0.2 below it). Floor gates by structure STRENGTH; this gates by DIRECTION. 0 = off (the plain look).",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"param_connect": "#0_hatch_stage_e2::coh_floor",
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
							"parameter_longname": "coh_floor",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_modmode": 3,
							"parameter_shortname": "coh_floor",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					},
					"showname": 0,
					"triangle": 1,
					"valuepopup": 1,
					"valuepopuplabel": 1,
					"varname": "coh_floor"
				}
			},
			{
				"box": {
					"id": "obj-42",
					"maxclass": "attrui",
					"attr": "coh_floor",
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
					"text": "Coh Floor",
					"textjustification": 1,
					"varname": "lbl_coh_floor"
				}
			},
			{
				"box": {
					"id": "obj-44",
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
						168.0,
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
					"id": "obj-45",
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
					"id": "obj-rd-0",
					"maxclass": "newobj",
					"patching_rect": [
						30.0,
						642.0,
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
						642.0,
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
						672.0,
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
						642.0,
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
						672.0,
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
						702.0,
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
						702.0,
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
						"obj-50",
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
						"obj-50",
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
						"obj-50",
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
						"obj-50",
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
						"obj-50",
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
						"obj-51",
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
						"obj-50",
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
						"obj-50",
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
						"obj-51",
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
						"obj-50",
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
						"obj-50",
						0
					]
				}
			}
		],
		"parameters": {
			"obj-20": [
				"reach",
				"reach",
				0
			],
			"obj-23": [
				"grain",
				"grain",
				0
			],
			"obj-26": [
				"density",
				"density",
				0
			],
			"obj-29": [
				"contrast",
				"contrast",
				0
			],
			"obj-32": [
				"line_hard",
				"line_hard",
				0
			],
			"obj-35": [
				"structure_floor",
				"structure_floor",
				0
			],
			"obj-38": [
				"angle_offset",
				"angle_offset",
				0
			],
			"obj-41": [
				"coh_floor",
				"coh_floor",
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