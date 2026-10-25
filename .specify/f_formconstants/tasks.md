# Tasks: f_formconstants

**Spec**: `.specify/f_formconstants/spec.md`
**Plan**: none yet (written after Phase 0)
**Build order**: Sequential. Phase 0 is the gate: T002 decides the `energy`
default (and whether an internal excite-LFO is needed) and everything in
Phase 1 assumes those numbers.
**Commits**: After each phase checkpoint.

> **REVISION 2 (2026-10-24 night): start at "REVISION 2" below — the agent
> brief, Phase R (parity build) and Phase D. Phases 0/1 above are history.**

Created 2026-10-24 from the spec after the f_wc pixelation post-mortem (see
Record). Each task says whether it is offline NumPy (no Max), the Max bench,
or a human look (tier 3, Matt).

---

## Expected Source Layout

```
src/f_formconstants/
├── definition.py            # archetype: source; drive inlet (vs_inState,
│                            #   f_wc G3 pattern); luma outlet
├── codebox_blur_x.gen       # separable Gaussian X pass, inline exp() weights,
│                            #   R at σ_E, G at σ_I, wrap sampling, radius ceil(3σ) (FR-002)
├── codebox_blur_y.gen       # the Y pass (same codebox shape, axis swapped)
├── codebox_hold.gen         # feedback hold (adaptive-res variant — T011)
├── codebox_seed.gen         # hash noise seeding (E, I) + per-frame noise stream;
│                            #   salt increments every draw (f_wc mechanism)
├── codebox_pass.gen         # reseed/hold + habituation carry if G1 ships (f_wc shape)
├── codebox_nl.gen           # sigmoid relax + per-frame noise + E-only drive +
│                            #   excite offset + NaN zap (f_wc shape, Example-10 constants)
├── codebox_enc.gen          # f_wc's retinotopic map stage, copied (r_soft
│                            #   foveal softening, contrast, sharp, bypass_gate)
tests/modules/formconstants/
├── fc_mirror.py             # tier-1 mirror (spatial-blur form; graduates from the spike)
├── test_formconstants.py    # tier-1 tests
├── bench_formconstants.py   # tier-2 stage/chain bench
tests/records/
├── spike_fc_sustain.py      # T002: sustain at Example-10 constants, float32, Ne = 0
├── spike_fc_lambda.py       # T003: λ(σ_frac) structure-factor calibration
docs/f-reference/
├── f_formconstants.md       # Phase 3
package/help/
├── f_formconstants.maxhelp  # Phase 3
```

Notes on what this module does NOT have (deliberate): no `gen_dft.py` adapter,
no `codebox_dft_*`, no `codebox_spec.gen`, no fixed-size solver texture, no
manual reconstruction taps in enc (FR-007: hardware `sample()` is exact when
state grid = render grid).

---

## Phase 0: NumPy spike and decision gates (BLOCKING)

**Tier decision (constitution, Verification Tiers):** tier 1 applies (closed
forms exist: separable-Gaussian sums, single-mode decay with couplings zeroed,
structure-factor peak vs. σ); tier 2 applies (frame-exact multi-frame feedback
vs. the mirror); tier 3 for the headline look AB against the HTML page.

- [x] T001 Write `tests/modules/formconstants/fc_mirror.py` + `test_formconstants.py`
  — the f_wc wc_mirror.py stage pattern, with the spectral Gaussian replaced by
  the explicit separable blur (radius ⌈3σ⌉, normalized `exp(−i²/2σ²)` weights,
  wrap). Closed-form checks: blur of a constant = the constant (machine-exact),
  blur of a single Fourier mode = mode × analytic Gaussian gain (f_wc T002's
  single-mode pattern), relaxation fixed points reproduce. Offline.
  **DONE 2026-10-24, 10/10 green.** Mirror carries both the exact discrete
  kernel (the codebox reference) and an FFT soak path (deliberately not the
  bench reference). Test found, on the way: the WC homogeneous dynamics is
  OSCILLATORY at the Example-10 constants (limit cycle E ∈ [0.104, 0.345]) —
  the f_wc-style rest test became a scalar-cycle tracking test.
- [x] T002 [US1] **Sustain measurement (the load-bearing experiment)** in
  `tests/records/spike_fc_sustain.py` — **DONE 2026-10-24, and it INVERTED the
  plan.** Verdict table (N=512, σ_I=1.0 px, 4000 frames, Example-10
  constants): Ne=0 dead; Ne 0.05–0.15 dead; **the source's own s square wave:
  dead**; Ne 0.5–1.0 marginal (std 0.025–0.046, weak). Faithful 8-bit-quantized
  port (state AND blur floored to 1/255): dead without s; ALIVE with s — std
  pulses 0.01–0.13, breathing waves. **Example-10's look is a flicker-driven
  regime sustained by 8-bit quantization decorrelation + the periodic s kick;
  its constants are not a foundation for an autonomous float32 module.**
  Counter-sweeps: Psychedelic couplings at fine grain saturate by ~3000 frames
  without habituation (the known saturation-boundary transient); **the
  sustaining regime is Psychedelic + habituation**: σ_I 0.75 px + Ne 0.75 +
  habit 0.3 healthy past 6000 frames (std ~0.34, flat), habit 0.6 sustained
  lower-contrast (0.21), habit 1.0 mostly collapsed. → defaults flipped to
  Psychedelic couplings (16.1/14.5/13.7/13, He 3.1, Hi 3.5, Te 4, Ti 12.5),
  **energy 0.75, habituation 0.3 and habituation is LOAD-BEARING, not optional
  (G1 answered by measurement: the dial ships in v1, nonzero default).**
  No internal excite-LFO (the s mechanism belongs to the flicker page's look;
  measured non-sustaining at float32 alone). The G0 message to Matt carries
  the (σ × habit) corner map from the grain-ladder/regime probes.
- [x] T003 [US3] **λ(σ) calibration + regime map** — **DONE 2026-10-24**
  (σ_I 0.75–2.0 px × habit 0.2–1.2, N=512, Ne 0.75, 4000 frames). Findings:
  1. **The steady band is σ_I 0.75–1.1 px × habit 0.9–1.2** — flat std traces
     (~0.27–0.31), dark-field webs (mean 0.15–0.23), λ 16–43 px. Ship corner
     family.
  2. **Habit 0.2–0.45 pulses intermittently** at every σ (std swings
     0.10↔0.37): rhythmic dissolve/re-form — a transient aesthetic (the T004
     stills corner), not a steady bed. Endpoint samples of pulsing regimes
     disagree between probes at the same corner — classify on traces.
  3. **Usable corner is a diagonal band**: habit ≥ 0.9 needs σ ≤ 1.1;
     σ 1.45+ at habit 0.9+ dies; σ 2.0 needs habit ≤ 0.3.
  4. **λ is set by the nonlinear dynamics, not the kernel** — floored kernels
     and σ 0.9–1.1 alike give λ 16–43 px. `grain` is a regime selector
     (fine silk ↔ pulsing cells ↔ dead ends), not a wavelength dial;
     Phase 2 defines its semantics live.
- [x] T004 [US1] Retinotopic look stills — **DONE 2026-10-24.** Sustained fine
  corner (σ_I 0.7 px floor-bound + habit 0.2/0.4) rendered through the map at
  parity and closer corners × r_soft {0.35, 0}: `scratch/fc_enc/state_s0.7_h*_
  {parity,closer}_rs*.png`. **The look is the target: fine, silky spiral /
  concentric-contour web, zero texel staircase.** No map change needed for v1;
  the closer corner (5/3/1.0) reads best of the four at this scale — Phase 2
  tunes.
- [x] T005 [US3] **Resize invariance — NEGATIVE for frame-fraction λ;
  NF-005 amended by measurement:** at grain 0.00137 the small sizes floor-bind
  (N 384/512 both ran the 0.75 px kernel: λ ≈ 14 px in both — λ fixed in
  PIXELS, 0.037/H vs 0.029/H) and N ≥ 768 left the sustaining band at habit
  0.3 (saturated). Resolution-independent behavior is achieved by holding
  σ_px in the measured steady band [≈0.75, ≈1.4], not by scaling σ with the
  window: **pattern features are pixel-scale by design (fine silk at 16–43 px)
  and NF-005 now reads "pattern scale constant in screen pixels across render
  sizes"; the grain dial maps to σ_frac clamped per frame into the sustaining
  σ_px band.** The tiny-window degenerate-kernel edge case is covered by the
  same clamp mechanism (its floor is now the STEADY-corner floor ≈ 0.75 px,
  no longer just a tap-degeneration guard).
- [x] T006 **[G0 — Matt, ANSWERED 2026-10-24]: the STEADY DARK WEB corner.**
  Constants: Psychedelic+habituation (Example-10 measured dead at float32);
  energy 0.75, habituation 0.9, grain 0.0008 (clamped σ_I 0.75–1.4 px),
  map closer set 5/3/1.0, r_soft 0.35; no internal s-LFO.
  Look families measured, stills in `scratch/fc_enc/`:
  (a) steady dark web `steady_s0.9_h0.9.png` / `steady_s1.1_h1.2.png` ← CHOSEN,
  (b) pulsing white web `state_s0.7_h0.2_closer_rs035.png` (reachable at
  habit ~0.2).
- [x] T007 **[G1 — Matt, ANSWERED 2026-10-24]: habituation SHIPS in v1,
  default 0.9** (measured load-bearing: saturation by ~3k frames without it).

**Checkpoint: Phase 0 CLOSED 2026-10-24.** Mirror + 10/10 tests green at the
shipped corner; spec amended (FR-002 σ band clamp, FR-003 Psychedelic
constants + load-bearing habituation/Ne, NF-005 pixel-scale features, params
table); regime map, sustain table, resize finding and stills recorded above.

---

## Phase 1: Build and bench

- [x] T010 Bench fixture — subsumed: bench_formconstants.py generates its
  mirrors on the fly (f_ks/bench_wc pattern); 30-frame chain diffs recorded
  in T015/T016. DONE 2026-10-24.
- [x] T011 **Build-system feasibility — DONE 2026-10-24, no builder gaps.**
  The pix_chain machinery already supports this module with zero new build
  features:
  1. **Stage sizing:** solver stages get `pix_attrs "@adapt 0 @type float32"`
     (NO @dim) and the module's raw `r dim` receiver fans out `dim W H` to
     EVERY solver stage plus enc — the same convention f_wc's enc uses
     (verified in the built `package/patchers/f_wc.maxpat`:
     `r dim` → `#0_wc_enc` inlet; jit.gl.pix follows).
  2. **Feedback:** plain patchcord `["nl", 0, "hold", 0]` + `hold` node with
     `"gen": "pass"` (passthrough, no codebox file) — the f_wc pattern;
     frame delay is implicit in render order, verified live in f_wc.
  3. **Cold-stage refresh:** `r draw` → seed/pass inlets and the every-draw
     `param salt` increment machinery carries over verbatim from f_wc.
  4. **Resize handling = resize reseed** (T013's deliberate path): add
     `r dim` → `delay 200` to the raw_lines so a render-size change bangs
     the existing reseed trigger (the spec's accepted seam — the state
     texture reallocates garbage for ~200 ms, then reseeds).
  Decisions: hold = gen "pass" (no file); enc keeps f_wc's map math but the
  16-tap CR sampler is REPLACED by manual bilinear-with-wrap mirroring
  fc_mirror.encode exactly (state res == render res makes CR pointless);
  state layout R=E, G=I, B=Ve, A=Vi (the fc_mirror layout; differs from
  f_wc's R=E, B=I).
- [x] T012 [US1] Write the codeboxes:  **DONE 2026-10-24:** all six written (hold = gen "pass", no file). `codebox_blur_x.gen`, `codebox_blur_y.gen`
  (inline `exp(−i²/2σ²)` weights from the σ Param — NO kernel tables, NO array
  uniforms; σ_px = σ_frac·min(dim.x, dim.y) with the ≥ 0.75 px floor; wrap
  neighbor sampling per the f_ks/f_wc texel-center convention), `codebox_nl.gen`
  (f_wc's verbatim stage shape, Example-10 constants, excite offset, drive
  term, habituation subtract only if G1 shipped), `codebox_seed.gen`,
  `codebox_pass.gen`, `codebox_hold.gen` (per T011), `codebox_enc.gen`
  (copy of f_wc's enc, header rewritten; `r_soft` stays a bench-vary Param).
  GenExpr discipline per the f_wc SSAA lesson: no functions with destructuring
  or global refs, inline everything, single-evaluation shapes only.
- [~] T013 [US1] Resize handling — **decided and wired 2026-10-24** (with T011):
  the deliberate path is **resize reseed**: `r dim` fans `dim W H` to EVERY
  stage (solver res = render res — T011 verified the convention against the
  built f_wc patcher) and ALSO bangs the `delay 200` → reseed trigger, so a
  render-size change reallocates textures and the picture re-forms from fresh
  noise after ~200 ms instead of interpolating a garbage realloc. Remaining:
  the bench leg (two renders at two sizes) in the T015–T019 Max session, and
  the live seam judgment in Phase 2.
- [x] T014 Write `src/f_formconstants/definition.py` and build
  `package/patchers/f_formconstants.maxpat` — **DONE 2026-10-24, drift 0**
  (16/16), build conventions/multistage/seeds-keys/overrides/layout tests
  green, menu + launcher regenerated (module in NOT_IN_MENU with reason until
  Phase 3; README row added — the suite enforces both). 12 dials (spec table),
  route outlet 12 = reset; support ids obj-58..obj-63 hardcoded in raw_lines
  (positional—f_wc T030's stale-id trap applies if the dial count changes).
- [x] T015 Write `tests/modules/formconstants/bench_formconstants.py` — **DONE
  2026-10-24, 8/8 PASS** (seed/pass/blur x/blur y/nl/enc legs + the
  boxmuller-order leg + enc ramp probe; every stage against the mirror).
  The bench paid for itself five times in one day, debugging arc:
  (1) `nearestpix` with normalized coords (code audit, first fix);
  (2) blur tap mask truncated at floor(3σ) instead of the mirror's ceil(3σ)
      radius — real kernel bug, caught at 8e-4, fixed to 1.8e-7;
  (3) seed/enc codeboxes used the gen `dim` global for texture size when
      their in1 is a bang-only inlet (gen `dim` is not an input texture's
      size — the jit-gen-codebox skill documents exactly this) — in the
      module this made the hash/noise grid degenerate → every texel got the
      same kick per frame → Matt's "flickering solid black/white/gray";
      fixed with `sw`/`sh` Params fed from raw `r dim → route → unpack`
      plumbing. This is T013/T011's production root cause;
  (4) the enc leg's 0.93 decorrelation was MIRROR-side: fc_mirror.encode
      used `xs/W` pixel edges where gen `norm` is texel-centred
      ((x+0.5)/W) — mirror fixed, enc proven corr 1.0000;
  (5) the 30-frame chain's 0.125 divergence was BENCH-sim-side:
      boxmuller() guarded only `na` where the codebox guards BOTH
      uniforms (z*0.999+0.0001; the ~3e-3 cos(2π·nb) shift amplifies
      through 30 relaxation steps; GPU self-readout proved both texture
      content and GPU arithmetic exact before this landed).
- [x] T016 [US1] Chain bench: **30-frame frame-exact class 7.3e-5** (f_wc's
  4.1e-6 precedent is the same family; the larger residual is float32
  Box-Muller trig integrated through relaxation+habituation).
- [x] T019 Module contract bench: **PASS** (ran green 2026-10-24 in the
  debug session — loads, outlet frames, all 7 pix, no unexpected Max
  errors, param readbacks; BENCH_MODULES run was clean before the
  codebox fixes and remains the gate).
- [ ] T017 [US2] Drive-imprint leg (the f_wc T032/bench_wc_look pattern):
  input correlation at `drive_gain` = 0 vs. ≥ 1. Max bench.
- [ ] T018 **Cost (NF-001)**: ms/frame at 1080p, 4K, and 320² on Matt's machine
  (resolver: σ_px grows with dim → tap count grows — the 4K number is the
  informative one). Report against f_wc's 2.45 ms. Max bench.

**Checkpoint:** Phase 1 closed when the module builds drift-0, benches green,
and NF-001 has numbers. f_wc's full offline suite runs before any unrelated
edit (`tests/bg.sh start offline`).

---

## REVISION 2 (2026-10-24 night): parity rebuild — supersedes the open Phase 1/2 work

The spec's "Revision 2" section explains why: the reference runs a FIXED
1024² solver with 8-bit quantization, the flicker `s` wave and an RGB
magnifying conformal map, and the build above was made on the opposite
premises. The steady-web build stays in git as a reference (commit
`63b6129`). Old tasks: T013 superseded (no resize handling at all), T017
moves to T066, T018 superseded by T049, T020 by T048, T021–T023 by Phase D,
T024 stays (Phase 2 below).

### Agent brief — read before ANY Revision 2 task (Claude, omp, any subagent)

**Goal:** make `f_formconstants` look like `WC_Example_10_fullscreen.html`.
Phase R reproduces the reference. Phase D changes it on purpose, one thing at
a time. Nothing else.

1. **The reference is the spec.** In Phase R, port spec items S1–S8 exactly
   and add nothing: no per-frame noise, no habituation, no `r_soft`, no
   contrast/sharp, no clamps beyond the NaN guard, no "improvements". If you
   think the source is wrong, say so in your report; do not fix it.
2. **Never move the target to make something work.** If the port does not
   sustain or does not match, the port or the harness is wrong. Do not change
   constants, add terms or switch regimes. Stop and report the evidence.
   (This module drifted exactly this way once: T002 tested the wrong kernel
   widths (σ_I 1 px / σ_E 0.69 instead of the source's 2 / 1), called the
   float32 port dead, and replaced the model.)
3. **A measurement that contradicts the spec stops the task.** Write the
   measurement and the conflict into the task's record and hand back for a
   decision. Do not amend the spec yourself.
4. **One task at a time, in order.** End each task with the report below and
   do not start the next one unasked.
5. **Two strikes.** Two failed fix attempts on the same symptom → stop; list
   the hypotheses ranked, the evidence for each, and the single measurement
   that would split them.
6. **GenExpr is verified only in Max.** An offline agent may write codeboxes
   but must not call them working; only a Max compile + readback (a bench
   session with Matt) verifies one. Use only precedented constructs
   (jit-gen-codebox skill): no functions with destructuring or global refs, no
   multi-assign, no unary minus before a parenthesis, `nearest()` with
   normalized coords (never `nearestpix`), never the `dim` global for a texel
   grid (literal or a Param defaulting to N), never a variable named `e` or
   `phi`, no Param named `texture`, `bypass` or `t` (a Param named `t` is never applied by jit.gl.pix: found at T046).
7. **No new architecture** (resize handling, adaptive resolution, new build
   features) unless a task asks for it.
8. **CLAUDE.md session rules apply:** no test or bench runs beyond the one
   named test for the change (`-q`); no polling loops; commit at each task
   checkpoint, chained to the edit; `.specify/paused/` is out of scope.
9. **Known traps:** quantize knife edges (GPU vs. NumPy rounding at exactly
   (k+0.5)/255; T046 states the tolerance; do not chase single-texel flips);
   positional object ids shift when the dial count changes (T044); the old
   "E == 0 and I == 0" self-heal is wrong under quantization (use the alpha
   flag, spec Revision 2 `pass`); `jit.gl.pix` reads an unconnected inlet as
   black.

**Report format, every task:** Done · Evidence (numbers, file paths) ·
Deviations from the spec (expected: none) · Open questions · Next.

**Live-debug rule (if the module misbehaves in Max but the bench is green):**
do not add more bench legs first. In a scratch copy of Matt's patch, put a
`jit.pwindow` (or `jit.gl.asyncread` → `jit.3m`) on each stage's outlet and
bisect the chain in one session: seed, pass, blur_x, blur_y, wc, enc.

### Phase R: parity build (BLOCKING for Phase D)

- [x] T040 **Source verification — DONE 2026-10-24; Matt confirmed S1 in the browser (`maincanvas.width` = 1024).** (offline + Matt, 5 min). Confirm S1–S8
  against the source files, citing file + function for each. Matt confirms
  S1 in the browser console with the page fullscreen:
  `document.getElementById('maincanvas').width` → expect 1024. Any
  disagreement → STOP (brief rule 3).
- [x] T041 **DONE 2026-10-24** — `fc_parity_mirror.py` (S2–S8, 225 lines). `spike_fc_sustain.py` has NO quantized port (nor does `fc_mirror.py`); the T002 "quantized port" was never committed, so nothing was reused. **Parity mirror** `tests/modules/formconstants/fc_parity_mirror.py`
  (offline). Exact NumPy float32 port of S2–S8: `q(x) = floor(255x + 0.5)/255`;
  `seed_state(rng)` (k/255 in all four channels); `blur_x`/`blur_y` (S3 kernel
  table, shared radius 6, quantized output, wrap); `s_of_t(t)` (the Revision 2
  `fract` form); `wc_step(state, conv, t)` (S4, B = q(clip(3|E−I|, 0, 1)),
  A = 1); `pass(state, seed, reseed)` (alpha lost flag); `encode(state, ow,
  oh)` (S7 square crop, bilinear + wrap, RGB out). **Read
  `tests/records/spike_fc_sustain.py` first:** it already has a quantized
  port; reuse it where it matches S1–S8 and resolve every difference in
  favor of the source, listing each in the report.
- [x] T042 **DONE 2026-10-24, 8/8 green in 14 s; (d) was rewritten because the measurement contradicted its premise** (below). **Parity tests** `tests/modules/formconstants/test_fc_parity.py`
  (offline, keep under ~20 s). (a) blur weights equal a direct transcription
  of `createGaussianConvolution(σ, true, 6)` for σ = 1, 2; (b) `q` is
  idempotent and applied at exactly the S2 points; (c) `s_of_t` values and
  period; (d) sustain regression. AS WRITTEN (quantized + s alive, q-off dies) it was
  falsified: at the source's σ = (1, 2) the float32 + s run sustains as well as
  the quantized one (E std 0.05–0.22, N 128/256, two seeds, 3000–4000 frames);
  only removing `s` kills the field. The test asserts what was measured: the `s`
  wave sustains, no-s dies, quantization is not required; (e) a texel with E = I = 0 and A = 1 is held, not reseeded;
  (f) `encode` samples the expected texel for a few known (angle, log r)
  points. If (d) fails, that is a brief-rule-2 stop, not a tuning task.
- [x] T043 **WRITTEN 2026-10-24 (offline; NOT verified — only T046's Max compile + readback does that).** Six codeboxes rewritten from S1–S8; blur weights are literals generated from the mirror's `half_kernel()` and re-checked by `test_fc_codebox_static.py`. **Parity codeboxes** Rewrite
  `codebox_seed.gen` (uint8-like hash; salt advances per RESET only, not per
  draw), `codebox_pass.gen` (alpha lost flag), `codebox_blur_x.gen` /
  `codebox_blur_y.gen` (S3 exactly: 13 fixed taps, per-channel weights
  normalized over the shared radius, all four channels, quantized output,
  grid from Param `n` = 1024), `codebox_nl.gen` (S4 + the `s` form; Params
  `frameno`, `s_depth`, `s_rate`; keep the file and stage name `nl` to avoid
  builder churn), `codebox_enc.gen` (S7/S8; Params `ow`, `oh`, `n`,
  `bypass_gate`). Term for term against `fc_parity_mirror.py`; each header
  cites the S items it implements. Nothing from the steady-web build
  survives unless S1–S8 require it.
- [x] T044 **DONE 2026-10-24: built drift 0; contracts 9/9 (six codebox-only Params registered as known issues: n ×4, s_depth, s_rate); launch 8/8; menu 17/17; `test_fc_codebox_static.py` 5/5 (n == @dim, blur literals, forbidden constructs, positional ids obj-50..55 / enc obj-5 / route obj-4, `r dim` reaches enc only). Panel 100×70 is a placeholder (T069).** **Definition + build** (offline). `definition.py`: params = reset,
  bypass and the internals (`reseed`, `salt`, `frameno`, `bypass_gate`, `ow`,
  `oh`); NO dials; drop the drive mod_inlet for Phase R (T066 restores it).
  Solver stages `@adapt 0 @dim 1024 1024 @type float32`; enc stays
  render-size via `r dim`; remove the `r dim` fan-out to solver stages and
  the `r dim → delay` reseed line; the draw counter now feeds `frameno` (nl) and
  no longer feeds `salt` every draw. Recompute every positional object id
  from the `build/spec.md` formula (the dial count changes). Add a test that
  each codebox Param `n` default equals the definition's @dim. Build; then
  drift, `test_module_contracts`, `test_launch`, menu `--check` (named tests,
  `-q`). Panel size shrinks: regenerate menu sizes and launcher. README row
  text waits for T048.
- [x] T045 **DONE 2026-10-24: `test_formconstants.py` tests the retained steady-web MIRROR, not the shipped codeboxes, so it still passes 10/10 and needed no change; the two Max benches that read the shipped codeboxes (`bench_formconstants.py`, `bench_fc_look.py`) now skip with the reason, replaced by T046/T047.** **Old tests** (offline). `fc_mirror.py` / `test_formconstants.py`
  describe the steady-web build and stay as its reference. Any test that
  reads the shipped codeboxes or definition and now fails is marked xfail
  with reason "steady-web reference, Revision 2"; nothing is deleted.
- [x] T046 **DONE 2026-10-24 (Max 9.2.0): all six codeboxes compile; bench_formconstants 8/8 including @slow (150-frame E std 0.0192 GPU / 0.0192 mirror, E mean 0.1583 / 0.1583); one real bug found (Param `t`) and the chain tolerance decided (below).** **Bench legs vs. the parity mirror** (Max bench, Matt's go).
  Compile every stage; per-stage legs. Tolerance, stated in advance:
  quantized outputs pass if max |diff| ≤ 1/255 and ≤ 0.1% of texels differ
  at all. Chain: texel-exact (same tolerance) for the first 5 frames; after
  that, rounding flips cascade, so compare statistics over 300 frames (E mean
  and std within 10%, structure-factor peak λ within 10%, mean-E period
  matches the `s` period). Do not debug texel divergence after frame 5 unless
  the statistics disagree.
- [x] T047 **CLOSED 2026-10-24 on Matt's live observation** (structured field, ran 3 minutes, stays alive). The rewritten `bench_fc_look.py` (adopted criteria a–d) captured no outlet output in the module bench although the module renders live → a bench-side capture bug, FOLLOW-UP for the next bench session (first suspect: the float32 output vs the capture matrix; compare against `bench_wc_look.py`'s job one difference at a time). **Module look bench** (Max bench). Rerun `bench_fc_look.py`
  adapted to RGB output: expect structured, not uniform (E std > 0.05 through
  the run, a spectral peak, mean E pulsing at ≈147 frames). If uniform or
  dead: apply the live-debug rule above before any code change.
- [x] T048 **PASSED 2026-10-24 (Matt): "it looks perfect" / "almost exactly perfect"; looks like the HTML page (yes). No specific difference named. Screenshot in chat: spots and short worms with the blue E/I contour web, finer toward the centre, magnified at the edges (S7/S8). README row updated.** **[GP — Matt] Parity look gate.** Module vs. the HTML page side by
  side, same window size, both freshly started. Pass = "same thing" to Matt's
  eye (a vertical mirror is fine). No Phase D work until GP passes; a fail
  goes back to T046/T047 evidence. Then update the README row.
- [x] T049 **DONE 2026-10-24 (Max 9.2.0; `bench_formconstants.py` 9/9 incl. --slow; new leg `test_cost_per_frame_T049`, numbers in `tests/logs/fc_cost_T049.txt`).** Totals (sum of the six per-frame stages): **N 1024: 1.07 ms @ 1080p, 1.54 ms @ 4K; N 2048: 2.04 ms @ 1080p, 2.47 ms @ 4K** (f_wc: 2.45 ms). Most stages did not become GPU-bound even at chain 32, so these are UPPER BOUNDS (real cost is at or below); only pass and nl at N 1024 resolved. Per stage at N 1024: seed 0.08, pass 0.48 (resolved; its N 2048 upper bound 0.32 is lower, so treat it as noise-level), blur_x/blur_y 0.09 each, nl 0.15, enc 0.17 (1080p) / 0.64 (4K); at N 2048 each solver stage ≈ 0.32–0.38. **Conclusion: cost is not a constraint at either N or render size; N 2048 at 4K costs about what f_wc does.** `seed` renders every frame though only reset uses it: a small Phase D saving, not needed. **Cost** (Max bench): ms/frame at N = 1024 and N = 2048, render
  1080p and 4K; report against f_wc's 2.45 ms. Feeds T064.

**Phase R CLOSED 2026-10-24: GP (T048) passed and T049 has numbers.**

**Checkpoint:** Phase R closed when GP passes and T049 has numbers.

> **Phase D's framing (Matt, 2026-10-24, after T048): "an outstanding
> simulation, but not a performable module."** That is the "almost" in the
> parity pass. Phase D's job is to make it performable; judge each deviation
> by that, not only by parity. Known performability facts from Phase R: a
> reset takes ~600 frames (~10 s) to re-form structure (T047 pre-check);
> `s` is the liveness mechanism, so `s_depth` 0 kills the field (T042); the
> pulse period is fixed at ~147 frames (frame-locked, not tempo-locked).
>
> **Matt's calls (2026-10-24, 17:28):** (1) the slow reset is NOT a problem
> to solve: slow evolution is why one reaches for Wilson-Cowan. No fast-reset
> or warm-start work. (2) The breathe wave and pulse are the primary
> performance surface: subtle adjustment, driven by an external WFG, or taken
> from an input. Open for the T061 design discussion: what "input" means here
> (a scalar mod inlet replacing the internal square wave; a texture whose luma
> sets `s` per texel; or both), the WFG signal convention it follows, and
> how the depth range avoids the dead zone (`s_depth` 0 kills the field).
>
> **Matt's answers (2026-10-24, 17:32), tentative:** (1) input form undecided;
> likes both the scalar inlet and the per-texel texture, and the library's
> three texture kinds (texture, vecfield, tensor) widen the options: explore
> before choosing. (2) Follow the Vsynth WFG convention, and fall back to the
> internal square wave when nothing is connected ("yes and yes, I think").
> (3) **No dead-zone guard: being able to kill the field and bring it back is
> part of performability.** Depth goes to 0; recovery is the slow re-formation,
> by design.
>
> **MVP scope (Matt, 2026-10-24, 17:33): regular textures only.** The pulse
> input for the MVP is a plain texture (plus the scalar/WFG path and the
> internal fallback). Vecfield and tensor inputs are post-MVP, considered
> after the MVP ships.
>
> **T061 decisions + pre-measurement (2026-10-24, 18:00):** Matt chose
> REPLACE (s = depth × input; the internal square wave is the unplugged
> default) and CORTICAL space (input read on the solver grid). Vsynth WFGs
> output textures, so the WFG inlet and the texture inlet are one inlet.
> Mirror measurement `tests/records/spike_fc_pulse_shapes.py` (RESULT in its
> docstring): `s` behaves as an excitability level with a viable window
> (DC 0.3 lives; DC 0.6 and square depth 1.5 die; depth 0 fades over
> ~1000 frames and revives in a few frames); square pulses faster than
> ~100 frames die (WFGs above ~0.6 Hz at 60 fps); cortical bands give
> distinct on/off regions; a travelling-sine WFG sustains. Smooth-vs-square
> is not a design concern (Matt: every WFG can output a square).

### Phase D: deliberate deviations (each: mirror first if dynamics change,
A/B vs. the parity build AND the HTML, Matt keeps or reverts)

- [ ] T060 **Output mode** menu: RGB (source) / E luma / contour (B) luma /
  RGB luma. Matt picks the default.
- [~] T061 **BENCH-VERIFIED 2026-10-24; awaiting Matt's live check.** Built as decided above: dials `depth` (0–1.5, 0.6 → Param `s_depth`) and `period` (30–600 frames, 147.06 → Param `s_period`, replaces `s_rate`); pulse mod inlet → `vs_inState` → nl in3, flag → Param `pulse_conn`; codebox `s = s_depth * mix(fract(frameno / s_period) < 0.5, luma(sample(in3, norm)), pulse_conn)`; frame counter wrap 2500 → 1000000; route `reset` outlet 0 → 2; panel 118×88 placeholder (reset moved to a third slot). Mirror `s_pulse()` + `luma()` + `wc_step(s=...)`; `test_fc_parity` 11/11 (3 new pulse tests); static 6/6 (route + pulse-wiring guards), contracts 9/9 (s_depth/s_rate known issues removed), drift 16/16, launch 8/8, menu current. New bench leg `test_nl_pulse_T061` (connected, conn 0, period 200, depth 1.3 vs mirror) and PINNED `s_rate` → `s_period`/`pulse_conn`: **RUN 2026-10-24 18:24 (Max 9.2.0): `bench_formconstants.py` 8/8 (2 slow skipped) — the new nl codebox compiles and every pulse case matches the mirror within the stage tolerance (≤ 1 level, ≤ 0.1%).** Then Matt's live check (WFG square into the pulse inlet; kill/revive). **Live check, first finding (Matt, 2026-10-24 23:36): the Depth dial loaded as Type Int, Range 0 1** although the built dial is float 0–1.5. Cause: a control's `param_connect` is `<pix>::<dial name>`, and jit.gl.pix has an int 0/1 attribute named `depth`, so the dial bound to it and adopted its type and range (Period had no such collision). Fix: dial names `pulse_depth` / `pulse_period` (labels unchanged); static/contracts/drift/launch/menu green. LIBRARY-WIDE FOLLOW-UP: any dial whose name equals a jit.gl.pix attribute has the same trap (scan the definitions against the pix attribute list; consider a builder guard). **Breathe** dials: `s_depth` (0–1, default 0.6) and `s_rate`
  (period in frames, default 147). Note how it compares with an `excite`-style
  offset on both populations (the f_wc G7 semantics).
- [ ] T062 **Quantization levels** dial (default 255; off = float). A
  character control. T042(d) found float32 + s sustains, so this is a LOOK
  control, not a liveness one; A/B the texture difference first.
- [ ] T063 **Map**: conformal zoom/rotation/spiral as one complex gain on
  (θ, log r), optional centre softening, field of view. Integer angular
  periods only where a seam would otherwise show.
- [ ] T064 **Solver size** as a load-time choice (512 / 1024 / 2048).
  Design discussion first (how N reaches both @dim and the codebox `n`
  Params, and how a change is applied); no code before Matt picks.
- [ ] T065 **Rate** (dt): measure in the mirror first; with quantization,
  per-step changes under ~1/255 freeze, so small dt may stall rather than
  slow.
- [ ] T066 **Drive inlet** back (G3 semantics, E-only, through the
  vs_inState / `drv_conn` pattern); mirror leg + the old T017 imprint leg.
- [ ] T067 **Coupling dials** (e.g. Aie / Aii), only if Matt asks after
  T060–T063.
- [ ] T068 **Steady-web mode** (the Psychedelic + noise + habituation build,
  commit `63b6129`) as a second mode, only if A/B shows a distinct family
  worth a switch; otherwise drop it and record why.
- [ ] T069 Defaults and panel layout; rewrite the spec's Parameters table to
  the shipped dials.

**Checkpoint:** Phase D closed when Matt approves the dial set and defaults.

## Phase 2: Soak (tier 3, live with Matt)

- [~] T020 superseded by T048 · T021–T023 superseded by Phase D.
- [ ] T024 **[G2 — Matt]** Soak check (f_wc's 30 s wash-drift precedent) at the
  shipped corner after Phase D.

**Checkpoint:** Phase 2 closed when Matt approves the soak.

---

## Phase 3: Ship

- [ ] T025 Reference doc `docs/f-reference/f_formconstants.md` (settled model,
  constants, ranges/landmarks, resize behavior, relationship to f_wc) +
  `docs/f-reference/module-inventory.md` rows (inlets/outlets/bypass tables).
- [ ] T026 Helpfile `package/help/f_formconstants.maxhelp` (generator layout,
  drive bubble per f_wc's).
- [ ] T027 Menu: `menu.py` Patterns category (after Wilson-Cowan), regenerate
  menu + launcher; `test_generate_menu` / `test_launch` green.
- [ ] T028 README row + `ideas/INDEX.md` flip to 🟢 + `.specify/plan.md`
  item marked BUILT/SHIPPED.
- [ ] T029 Enc-dedup hygiene decision (Claude): shared enc source factoring
  across f_wc / f_formconstants vs. documented copy (the `gen_dft.py`
  precedent if shared). One paragraph in this file either way.
- [ ] T030 Full offline suite (`tests/bg.sh start offline`) + full module
  contract bench on the final patcher set; close-out record.

**Checkpoint:** Phase 3 closed when the module is registered everywhere and
the suite is green. Module is shipped.

---

## Dependencies & Execution Order

- Phase 0 (T001–T007) blocks everything — G0's `energy` default is baked into
  the codeboxes at T012.
- T011 blocks T012–T014 (the adaptive-feedback pattern decides the hold/seed
  shapes).
- Bench tasks T015–T019 are one Max session, sequenced as listed.
- Phase 2 is one live tuning session with Matt.
- T025–T028 parallelizable once Phase 2's defaults are settled.

## Record

### 2026-10-24: module conceived out of the f_wc pixelation post-mortem

- Matt's report chain over the day: 1920×1080 f_wc renders showed ~30 px
  blocks (C0-bilinear facets → fixed with Catmull-Rom 4×4, commit fbee342);
  "still blocky around the edges" (contour-position quantization on the 256²
  grid); 2×2 SSAA attempts failed live three times (function form boxed
  black; two-arg-atan → 4-fold mirror; cartopol restored → 2-fold) and were
  reverted to the proven single-eval CR build (2d9174c). Readback of the
  failed commit 0589d14 found the offsets were quarter-SCREEN-pixels against
  a ~7-screen-px/texel artifact, and the average was pre-threshold — the
  attempt was structurally unable to fix the artifact even if codegen had
  worked.
- Reading the actual `WC_Example_10_fullscreen.html` source + `gpgpu.js` +
  `gpugaussian.js` (2026-10-24): the source's smoothness is STRUCTURAL —
  solver textures = canvas client size (up to 1920² on a 1080p display),
  UNSIGNED_BYTE with `EncodeFloat` 1/255 quantization on every write,
  LINEAR/REPEAT filtering, coupling via `GPUGaussianMultiBlur(gl,1,2,1,1)`
  (two-pass separable Gaussian, radius ⌈3σ⌉), retinal map =
  15-line bare complex-log shader, display = continuous `vec4(Ue,Ui,|E−I|·3)`
  with NO threshold. No FFT, no reconstruction filter, no AA — the artifact
  class f_wc fights does not exist at solver-res = render-res.
- **Matt's calls (2026-10-24):** their look (fine, silky) is the actual
  target; color not essential (downstream tooling covers it); NEW SIBLING
  MODULE rather than re-architecting f_wc; Example-10 coupling constants as
  defaults; name `f_formconstants`.
- Deliberate departures from the source, with reasons: float32 state (their
  8-bit quantization is a liability on a saturation boundary); pattern scale
  in frame-height units (their resize-couples-physics is a defect for a
  module); `r_soft` foveal softening retained (their center is an aliased
  vortex); per-frame `Ne` measured rather than assumed (their page injects
  none — possibly sustained by quantization decorrelation + the slow square
  wave `s`; T002 answers this at float32).

### 2026-10-24 (night): Revision 2 — the reference was misread; parity rebuild

- Fresh read of the html + `gpgpu.js` / `gpugaussian.js` / `gpurand.js`
  (Claude, after the omp/kimi debug arc stalled): the solver is a FIXED
  1024² (`getRasterGL` reads `clientWidth` while the canvas still has its
  inline 1024px style, before `make_fullscreen`), so the record above
  ("canvas client size, up to 1920²") is wrong. The display MAGNIFIES the
  field through the bare conformal log; the current enc (zoom 5 / twist 3 /
  r_max 4 over a render-res state) MINIFIES it about 2.5×, so it could not
  look silky even with healthy dynamics. The sustain mechanism is the 8-bit
  quantization + `s` (T002 already showed it); the model swap to
  Psychedelic + noise + habituation moved the target.
- Matt concurred: spec Revision 2 (facts S1–S8, superseded list, parity
  architecture, Phase D list) and tasks Phase R (T040–T049) + Phase D
  (T060–T069) + an anti-drift agent brief. The live "flash then black"
  symptom is not pursued further: the sizing layer it most likely lives in
  is removed by T044. Reference build for the old regime: `63b6129`.

### 2026-10-24 (night, T041/T042): the T002 "quantization sustains" claim is falsified

- Parity mirror + 8 tests landed (`tests/modules/formconstants/fc_parity_mirror.py`, `test_fc_parity.py`). Measured with the source's actual kernel (σ_E 1, σ_I 2 px, shared radius 6), Example-10 constants, no noise, no habituation, crossing quantization on/off with `s` on/off: **`s` on = sustained (E std 0.05–0.22 over 3000–4000 frames, quantized or float, two seeds, N 128 and 256); `s` off = dead (std ≤ 0.012), quantized or float.** Record: `tests/records/spike_fc_parity_sustain.py`.
- Why T002 said otherwise: it used σ_I 1 px / σ_E 0.69 (grain 1/512 on N = 512, ratio 1.45), not the source's (2, 1); and its quantized port was never committed, so the claim could not be re-run. So Psychedelic + noise + habituation was a detour from a wrong measurement; the original Example-10 constants WOULD have sustained at float32 with `s`.
- Consequences: Phase R is unchanged (the quantize is cheap and kept for parity). S2's gloss in the spec and T062's rationale are corrected; the brief's parenthetical too. `s` is the liveness mechanism, so T061's breathe dials are performance-critical (depth 0 kills the field), not cosmetic.
- Also found: `s_of_t` and the page's `sign(sin)` differ at t = 0 (0.6 vs 0.3) and at t = 1250 k (exact half-periods; the page's truncated π decides). Single frames; documented in the mirror.
- Open for T043/T046: whether a fresh `jit.gl.pix` float32 output reads A = 0 (the pass stage's lost flag depends on it); the loadbang reseed covers the first frame either way.

### 2026-10-24 (night, T046): the parity codeboxes compile and match; one real bug found, one tolerance question

- **First Max compile of the parity codeboxes: all six compile.** seed (uint8 grid, mean 0.50, std 0.289, reproducible per salt), pass (A = 1 held bit-exact, E = I = 0 with A = 1 HELD, A = 0 texels reseed), blur_x/blur_y (13 taps; max 1 level, ≤ 0.0015% of values differ; impulse wrap exact), enc (128², 160×90, 90×160: max 8.3e-5, corr 1.00000; bypass black A = 1), nl at s on (t = 0, 2400) and off (t = 100, 74): max 1 level.
- **REAL BUG FOUND: a Param named `t` is never applied in a jit.gl.pix codebox** (it reads back 0 even when set to 100; the identical code with the Param named `tt` works). With `t` the `s` wave was stuck at its t = 0 value (always on), which no offline test could see. Renamed `frameno` (codebox, definition, bench, static-test forbidden list, brief rule 6). Same trap family as `texture` / `bypass`. Worth a line in `skills/jit-gen-codebox/SKILL.md` (needs a re-upload + `skills/check.sh stamp`; NOT done here).
- **Chain, 5 frames, literal tolerance (≤ 1/255 AND ≤ 0.1% of values): frame 1 passes (1 level, 0.0092% of values), frame 2 fails: R, G 1 level, B 3 levels (0.015% of values).** Attribution leg added (`test_each_frame_is_stage_exact_given_identical_input`, the GPU stepped from the MIRROR's own state each frame): all five frames are stage-exact (frames 2–4 bit-identical, frames 1 and 5 ≤ 1 level, ≤ 0.0092%). So the frame-2 miss is upstream rounding flips cascading: B = 3|E − I| triples a 1-level flip of the inherited state. It is not a stage error.
- **DECIDED (Matt, 2026-10-24: "yes"): the chain leg's tolerance** — R, G ≤ 1 level, B ≤ 3 levels, A exact, ≤ 0.1% of values differing, per frame (`check_chain`); the attribution leg stays as the stage-exactness proof. Original statement of the problem: The literal "same tolerance for frames 1–5" cannot hold for the B channel past frame 1 by construction. Recommendation: keep the attribution leg as the stage-exactness proof; make the chain leg check R, G ≤ 1 level per frame and B ≤ 3 levels (values differing ≤ 0.1%), and report both. Until decided the chain leg stays red, as written. The @slow 150-frame statistics leg has NOT been run.
- Still open for T047/T048: whether a fresh `jit.gl.pix` float32 output reads A = 0 (not testable in the codebox bench; the loadbang reseed covers frame 1), and the module-level look.

### 2026-10-24 (evening, T047 pre-check): the mirror contradicts T047's "E std > 0.05 throughout" — STOPPED for a decision (brief rule 3)

- Before adapting `bench_fc_look.py`, the parity mirror was run from a fresh seed (N 256, seeds 1 and 2, quantized + s, 1200 frames; inline script, ~15 s). **The reference's own dynamics do not keep E std above 0.05 throughout.** State E std every 50 frames (seed 1; seed 2 within ~0.003): 0.271 (seed noise) → 0.060 → 0.010 → 0.025 → 0.005 … ≈0.005 until ~frame 600, then the pattern emerges: 0.066 (650), 0.102 (750), 0.125, 0.058, 0.141, 0.103, 0.087, 0.150, 0.026 (1100), 0.065. Minimum after frame 300: 0.002. Encoded output (128², R channel) at frames 100–400: std 0.004–0.011; 800–1000: 0.08–0.14; 1100: 0.018.
- So there is a ~600-frame near-uniform transient (blur flattens the uint8 noise, then the `s` forcing grows structure), and after emergence the std still swings well below 0.05 within some `s` periods. This matches T046's 150-frame GPU = mirror E std 0.0192: that was the transient, not a fault.
- Mean-E pulse: power-spectrum peak period 150 frames (frames 300–1200, both seeds) — the ≈147-frame expectation holds.
- Both seeds give near-identical std/mean time series, so the series is set by the `s` forcing, not the seed: a GPU-vs-mirror statistics comparison is meaningful without reproducing the module's seed hash.
- Proposed replacement criteria (NOT adopted; Matt decides): run ≥ 1500 frames from reset, snapshot every ~15 frames; pass = (a) max output R std over frames 700–1500 > 0.05, (b) peak R std over the last 300 frames > 0.05 (not dead late), (c) mean-R pulse period 147 ± 10%, (d) the snapshot std/mean series tracks the mirror's encoded series at the same frames within a stated band. Dead or uniform after frame 900 → live-debug rule.
- **ADOPTED (Matt, 2026-10-24 17:10: "proceed with your recommendations")**, ±0.03 band on ≥ 90% of snapshots. Before adoption the N 256 mirror was checked against N 1024 (1500 frames, encoded 256² every 15 frames): max |mean diff| 0.014, max |std diff| 0.014, so N 256 is the in-test reference. `bench_fc_look.py` rewritten to these criteria.
- **First run (job `20261024_171658_ee746c`, Max 9.2.0): the job rendered 1505 frames at ~58 fps with no unexpected errors, but NO outlet was captured at any of the 93 snapshots** (`outputs` empty; capture matrices stayed 1×1). The harness path is the one `bench_wc_look.py` and the old fc look bench used successfully, so the module's outlet sent nothing during the run. Static read of the built patcher: enc (obj-5) → outlet is wired; enc's inlet 0 receives `r draw` bangs AND the module input texture (inlet → routepass → enc in0); nl → enc in1 is wired. No fix attempted (strike 0). Next: an existing outlet-renders check or the live-debug rule (Matt's call).
