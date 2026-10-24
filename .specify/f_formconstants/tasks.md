# Tasks: f_formconstants

**Spec**: `.specify/f_formconstants/spec.md`
**Plan**: none yet (written after Phase 0)
**Build order**: Sequential. Phase 0 is the gate: T002 decides the `energy`
default (and whether an internal excite-LFO is needed) and everything in
Phase 1 assumes those numbers.
**Commits**: After each phase checkpoint.

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

## Phase 2: Tuning (tier 3, live with Matt)

- [ ] T020 [US1] **Headline AB**: module vs. `WC_Example_10_fullscreen.html`
  side by side at the same window size, default dials, high and low `sharp`.
  Matt's call: the fine silky web read, with no texel staircase (Success 1).
- [ ] T021 [US3] `grain`/`aspect` ranges + landmark snap points live (the
  T003 table is the offline proposal); confirm the stripes↔labyrinth ordering
  axis reads at render-res physics. Record the final ranges in the spec table.
- [ ] T022 [US2] Drive-transition feel live (imprint legibility, release);
  `rate` range + ceiling (pattern-preservation bound, FR-005).
- [ ] T023 [US1] Map corner for the fine web (zoom/twist/fovea defaults; the
  parity set was tuned for the chunky field) + `r_soft` value at the fine
  scale; live resize check alongside (T013's seam visible/acceptable?).
- [ ] T024 **[G2 — Matt]** Soak check (f_wc's 30 s wash-drift precedent) at the
  shipped corner; pick the shipped `sharp`/`contrast` defaults from the soak.

**Checkpoint:** Phase 2 closed when Matt approves the default look and ranges.

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
