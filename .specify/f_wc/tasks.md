# Tasks: f_wc

**Spec**: `.specify/f_wc/spec.md`
**Plan**: none yet (written after Phase 0)
**Build order**: Sequential. Phase 0 is the gate — the spike resolves every open Clarification in the spec, and nothing in Phase 1 starts until its decision gates are closed.
**Commits**: After each phase checkpoint.

Created 2026-10-22 from the spec's "Open Experiments" and phasing. Each task says whether it is offline NumPy (no Max), the Max bench, or a human look (tier 3, Matt).

---

## Expected Source Layout

```
src/f_wc/
├── definition.py            # module definition (archetype: source, luma out)
├── gen_dft.py               # third adapter on f_vf_fluid's shared DFT
│                            #   template (T020 decision: code-line-asserted)
├── codebox_seed.gen         # hash noise seeding (E and I) + per-frame noise
│                            #   salt increments EVERY draw (the mechanism)
├── codebox_pass.gen         # feedback hold / reseed (3 inlets: noise source)
├── codebox_dft_{fx,fy,iy,ix}.gen   # generated; ONE chain, two-complex-field
│                            #   packing (R,G = E-hat; B,A = I-hat) carries BOTH
│                            #   fields — the f_vf_fluid packing; no split
├── codebox_spec.gen         # per-bin kernel gains: exp(-sigma^2 k^2 / 2),
│                            #   ONE instance (sigma_E on the E pair, sigma_I
│                            #   on the I pair; NOT the spec's old two-chain
│                            #   decay+diffusion — Phase-0 record T001)
├── codebox_nl.gen           # sigmoid coupling + per-frame noise + E-only drive,
│                            #   dt/TE|TI relaxation (4 inlets; FR-003 settled form)
├── codebox_enc.gen          # retinotopic (log-polar → Cartesian) resample,
│                            #   output map, bypass_gate
tests/records/
├── spike_wc_solver.py       # Phase 0 record (superseded pre-noise form)
├── spike_wc_regions.py      # Phase 0 record (pre-noise region map)
├── spike_wc_noise_regions.py # Phase 0 record (settled noise-driven region map)
├── spike_wc_pinto.py        # Phase 0 record (rejected activator-recovery fork)
├── wc_retinotopy.py         # Phase 0 retinotopic render (T006, validated)
tests/modules/wc/
├── wc_mirror.py             # tier-1 mirror (graduates from the spike)
├── test_wc.py               # tier-1 tests
├── bench_wc.py              # tier-2 stage/chain bench
├── bench_wc_module.py       # tier-2 shipped-patcher bench
```

## Phase 0: NumPy spike and decision gates (BLOCKING)

**Tier decision (constitution, Verification Tiers):** tier 1 applies (closed forms exist: single-mode diffusion decay rates, sigmoid fixed points, structure-factor peak at the predicted wavelength); tier 2 applies (multi-frame frame-exact feedback against the mirror, the f_ks pattern); tier 3 for form quality, the retinotopic look, the drive-transition feel, and output mapping.

### Open Experiment 1 — solver mirror and stability

- [x] T001 Stage-decomposed float32 NumPy mirror of the one-frame update. **Landing place: `tests/records/spike_wc_solver.py` (5 tests green, 2026-10-22).** The mirror's solver shape CHANGED from the spec's "diffuse each field then couple" to **kernel-coupled** (Ermentrout-Cowan form): each coupling term convolves its field with a Gaussian kernel (spectrally `exp(-sigma^2 k^2/2)`), inhibition kernels wider than excitation. The naive diffusion form was measured 2026-10-22 to NOT produce clean rolls/hexagons (long-wavelength mush). Spec FR-002/FR-003 need updating to the kernel form (see Record).
- [x] T002 Single-mode verification: with couplings zeroed, E and I decay at exactly `exp(-dt/tau)` (k-independent decay; spatial structure enters only through the coupling kernels) — machine-exact (rel err 3e-15). Sigmoid fixed points reproduce. Offline, in `spike_wc_solver.py`.
- [x] T003 Stability: **reframed.** The solver NEVER goes NaN/Inf at any dt (verified to dt=10 at N=128/256): exact linear decay + bounded sigmoid output make overflow structurally impossible, so there is no NaN ceiling. The rate-dial ceiling is a *pattern-preservation* ceiling (at high dt the pattern collapses to uniform), which is region-dependent and therefore a T004 deliverable, not a property of the default constants. Two seeding findings that matter for the module: (a) sigmoid thresholds are load-bearing — without them the rest state saturates and no drive patterns; (b) seed noise amplitude must clear the thresholds (0..0.05 noise decays to rest, 0..0.3 nucleates pattern).

### Open Experiment 2 — parameter region map (the load-bearing experiment)

- [x] T004 Sweep the curated coupling aggregates; classify asymptotic morphology. **Done 2026-10-22** (`tests/records/spike_wc_regions.py`, `wc_classify.py`, 80 cells: P ∈ [0.6,2.0] × sscale ∈ [0.3,0.7] × seed ∈ {0.3,0.6}, N=256, L=80, dt=0.05, 1200 frames). **Result: at the default strong-coupling constants (W_EE=16 etc.), NO clean rolls/hexagons anywhere** — the field saturates into isolated firing spots (dots, 19 cells) or disordered blobs (chaos, 43 cells), with 12 uniform collapses and only 6 weak borderline "rolls". The default sigmoid is too steep / couplings too strong for the weakly-nonlinear Turing regime. Follow-up probe (weaken all couplings ~0.3–0.5×, lower thresholds so the rest point sits mid-slope) DID produce extended coherent wavy/labyrinthine structure — the right regime — but low contrast. **Conclusion: the four-form taxonomy requires the weak-coupling near-threshold regime, not the literature's strong-coupling default.**
- [ ] T005 Locate the finite-amplitude Turing regime. **Progress 2026-10-22:** linear dispersion analysis over (wscale, P) located a genuine finite-k instability band: **wscale ≈ 0.4, P ∈ [0.4, 0.6], k ≈ 1.45, λ ≈ 4.3 cortical units, rest mid-slope (E≈0.3)**. So the Turing window EXISTS analytically. BUT the nonlinear simulation does not grow it from noise seed within 2000 frames — weak-coupling runs collapse to uniform (std ~ 1e-12), strong-coupling runs make saturated spots/blobs. The gap between "dispersion predicts instability" and "simulation grows finite pattern" is the exact open question. **Resolved the discrepancy 2026-10-22 (it is NOT a discretization problem):** at the candidate Turing point (ws=0.4, P=0.55, th=(1.0,0.9)) the rest state the solver actually converges to is E≈0.046 (sigmoid saturated low), where BOTH continuous eigenvalues are negative (−0.80, −1.04) and both discrete-map eigenvalues are 0.967 < 1 — the point is genuinely stable, so decay is correct behavior. The earlier dispersion scan that reported growth at k≈1.45 used a *different, inconsistent rest state* (the fixed-point iterator converged to a different root, or thresholds differed between the scan and the solver). **Root cause: multi-stability / rest-state selection.** The Wilson-Cowan system has multiple fixed points; whether a finite-k instability exists depends on which fixed point the dispersion is computed about, and my scan and solver were not computing the same one. dt reduction (0.02, 0.05) does not change this — both collapse. **Next session must do the fixed-point analysis carefully: find ALL fixed points as a function of (P, wscale, thresholds), compute the finite-k dispersion about the PHYSICAL (stable, low) branch specifically, and confirm a band exists there before any more simulation. This determines whether the module's forms exist at all. This task's output decides gate G1 and is the go/no-go for the whole module.**

**2026-10-23 — Wikipedia (Wilson–Cowan model) resolves the direction; three concrete takeaways:**

1. **Bistability is the documented mechanism, and my sweep confirmed it.** The article's key finding is exactly what defeated the sweep: "the existence of multiple stable states, and hysteresis, in the population response." The epilepsy section (Shusterman & Troy 2008, Pinto-Ermentrout) makes it precise: pattern/oscillation arises when a **stable rest state COEXISTS with a stable spatially-extended active state**, and the transition between them is a threshold-crossing (finite perturbation), not an infinitesimal instability. So my "seed from small noise and hope it grows" approach was wrong for this model — **the forms need finite-amplitude nucleation, not spontaneous Turing growth from noise.** This reframes seeding entirely: nucleation is the design, not a detail.

2. **The pattern-forming spatially-extended variant uses a recovery variable and a step firing function, not my sigmoid+threshold.** The Pinto-Ermentrout form the article gives for spiral waves is a *two-variable activator-recovery* system (`du/dt = u − v + ∫ω·H(u−θ)`, `dv/dt = ε(βu − v)`) with `H` a Heaviside, `v` a slow recovery. That's structurally different from my two-field E/I sigmoid system: the recovery variable (not the inhibitory population) is what creates the excitable, wave-propagating medium. **Decision for next session: the E/I-with-sigmoid form may be the wrong model for spatial forms; the activator-recovery (Pinto-Ermentrout) form is the one with documented spiral/wave solutions.** This may mean re-scoping the solver — keep the spectral kernel machinery, change the local dynamics.

3. **Connection kernel form confirmed:** `ω(x,y) = A·exp(−λ·r)` (exponential, not my Gaussian) with (A, λ) = (2.1, 1) in Ref[7]. Exponential kernels are still diagonal in Fourier space (`(1 + (k/λ)²)^(-3/2)` in 2D), so the spectral approach carries over directly. Worth using the literature's kernel, not my Gaussian guess.

**Net: the article moves T005 from "find the right fixed point" to "reconsider whether the E/I-sigmoid local dynamics should be activator-recovery (Pinto-Ermentrout) with finite-amplitude nucleation." This is a design fork Matt should weigh in on before more simulation — it changes the model class, not just parameters.**

**2026-10-23 — Matt picked the fork: spike the Pinto-Ermentrout activator-recovery form. Result (tests/records/spike_wc_pinto.py + ~6 parameter scans): ALSO a negative finding, and it locates the real obstruction.** The u/v Heaviside system with the literature's exponential kernel `w(r)=A·exp(−λr)` (A=2.1, λ=1) is cleanly bistable in its *homogeneous* fixed points across most of (β, θ, a) (rest u=P/(1+β) < θ, active u=(a+P)/(1+β) > θ — confirmed analytically). BUT the *spatial* medium has a razor-thin — in these scans, empty — excitable window between "a finite blob fails to nucleate" and "a finite blob ignites the whole periodic domain": at every (P, eps, β, a, seed-radius) probed the broken-wave/blob seed either collapses to rest or spreads to saturate the entire field (active-fraction 1.0, std→0). No localized pulse, target wave, or spiral survives. Adding lateral inhibition (Mexican-hat, difference of exponentials) makes it WORSE (kills nucleation entirely). **Root-cause read [INFERENCE]:** with a pure-positive bump kernel normalized to integral `a`, once a region fires the coupling `a` outweighs the recovery `βu` (max `β·u_sat = β(a+P)/(1+β) < a` for the active state to exist — i.e. bistability of the homogeneous states and the front-stalling condition PULL OPPOSITE WAYS in this normalization). The documented Pinto-Ermentrout spirals live in a parameter/normalization regime my spectral-kernel setup is not hitting, OR the spatially-extended excitable regime needs a genuinely different kernel (e.g. the article's Ref[7] is a *rate* model, and the spiral result is for a different connectivity). **This is a real dead-ends-eliminated result, not a tuning gap: two model classes (E/I sigmoid Turing, u/v Heaviside excitable) both fail to produce the target spatial forms in the regimes I can reach.** See the Record for the decision this forces.

**2026-10-23 (later) — CORRECTED, and the correction UN-BLOCKS the module.** Matt pointed to Michael Rule's webgpgpu Wilson-Cowan pages (`crawlingrobotfortress.blogspot.com/2016/07/wilson-cowan-neural-fields-in-webgl.html`, `github.com/michaelerule/webgpgpu/blob/master/wilson_cowan/wilson_cowan_gpu.html`) — a WORKING two-field WC with retinotopy. I ran the actual page headless (512², Psychedelic preset, 1600 frames) and read back the cortical U texture: **std 95/255, range 2–249, clean labyrinthine/stripe structure** — exactly the Ermentrout-Cowan hallucination texture. Then reproduced it in NumPy. **The negative results above were MY error, not the model's.** Ablation isolates the single load-bearing ingredient my earlier solvers lacked:

| per-frame noise | 8-bit quantize | result |
|---|---|---|
| yes (Ne=0.75) | on or off | **PATTERN** (std ~0.36) |
| none | either | dead / uniform |

**The mechanism is NOISE-SUSTAINED pattern formation, NOT bistable finite-nucleation (the Wikipedia framing was a red herring for this model) and NOT noiseless Turing growth.** Every prior failure — the T004 region map, the T005 E/I rest-state collapse, the Pinto-Ermentrout spike — seeded once and let the field decay; none had continuous stochastic drive, so all collapsed. Resolution (256 vs 512), 8-bit quantization, Box-Muller vs plain Gaussian noise, and the exact couplings are all secondary: with per-frame noise the pattern appears; without it, nothing does. **The working two-field system (Rule's Psychedelic):** `Ue += (F(Aee·(Ke⊗E) − Aie·(Ki⊗I) − He − be·Ve + Ne·noise) − Ue)·dt/Te`, same for I, plus slow adaptation `Ve += (E−Ve)·dt/ae`; Gaussian kernels σe=2px, σi=2.9px (E narrower than I = the classic lateral-inhibition shape); Aee=16.1 Aie=14.5 Aei=13.7 Aii=13, He=3.1 Hi=3.5, Te=4 Ti=12.5, dt=1, Ne=0.75, be=bi=0. This is a small delta from my original `spike_wc_solver.py` (kernel-coupled sigmoid E/I) — **the module's original model class was right all along; it just needs a persistent noise/drive term.** The `drive` inlet and the autonomous-generator story both map onto this directly. **f_wc is GO.** T005 reframed: the regime to map is (noise level × drive), not (coupling × threshold). Next: re-run the region map with per-frame noise to find the rolls/hexagon/spiral sub-regions within the labyrinth, then T006 render on the REAL solver output.

**2026-10-23 — Region map with per-frame noise DONE (`tests/records/spike_wc_noise_regions.py`, 96 cells: Ne ∈ [0.1,1.5] × sig_i ∈ [1.5,6] × Aee ∈ [14,20], N=256, 1500 frames) — and it refines the mechanism further:** the "living labyrinth" is a **noise-driven TRANSIENT, not a steady state.** Three findings:

1. **Drive threshold at Ne ≈ 0.75 is sharp.** Below it (Ne ≤ 0.5) the field decays to float-noise (std ≤ 0.02); at/above it the pattern has real contrast (std 0.24–0.36). Per-frame noise must clear the sigmoid threshold each frame or the pattern dies.
2. **The Psychedelic constants sit on a saturation boundary.** The demo's elaborate labyrinth (Ne=0.75, sig_i=2.9) is a LONG-LIVED transient: run longer and high-Ne cells saturate all-ones (frac 1.0, std 0.05) while low-Ne cells die to zero. My earlier "uniform" port results were correct asymptotic behavior; Rule's live pattern is the transient. The narrow usable band is **Ne ≈ 0.7–0.85**, where the transient is long-lived AND high-contrast. This explains everything: the same constants give labyrinth or uniform depending on how long they run — not a resolution or quantization difference.
3. **Kernel width selects geometry; the labyrinth is a "stripe glass."** At sig_i=1.5 the texture is coherent broken stripes (f2 anisotropy 0.48, the closest to clean rolls); at sig_i=2.9–6.0 it's disordered labyrinth/chaos. No clean hexagon region appeared at reachable amplitude (hex tendency f6 0.21–0.25 only at near-zero amplitude, Ne≤0.3). The `frac_high`-based "dots" label in `wc_classify` MISFIRES on intermediate-std labyrinth (labels 91/96 cells "dots"); classify on f2/f6, not the label.

**Consequence for the module (reopens gate G1):** the aesthetic target is a noise-driven *living labyrinth / stripe-glass*, sustained at a tuned drive near Ne≈0.75 with the kernel width as the geometry dial — NOT a discrete rolls/hexagon/spiral/funnel selector. The four-form taxonomy may not exist as separable stable regions in this model. **This is a tier-3 / spec-scope question for Matt:** is the module "an autonomous hallucination-labyrinth generator with a drive inlet and a texture dial" (which the model demonstrably delivers), or must it have the discrete form constants from the spec? The retinotopic map (`wc_retinotopy.py`) is validated and model-agnostic — it renders the labyrinth fine (cortex std 0.19 → retinal std 0.21, organic texture preserved).

### Open Experiment 3 — retinotopic render

- [x] T006 Retinotopic map validated **on synthetic cortical patterns** 2026-10-22 (`tests/records/wc_retinotopy.py`): cortical diagonal-rolls → **spiral**, cortical v-axis-rolls → **spokes/cobweb**, cortical hexagons → **honeycomb lattice**. The map mechanism works and the taxonomy transforms as the theory says. Open sub-findings: (a) `k_t` (angular gain) must divide the cortical v-wavelength cleanly or a seam shows at the origin wrap; (b) foveal regularization (`r0`) is in place. **Still owed originally: render the SOLVER's actual output. DONE 2026-10-23:** rendered the real noise-driven labyrinth (T005's settled model) through the map at the three texture-dial settings; stills in `.specify/f_wc/t006_stills/` (`retinal_{stripes,labyrinth,blob}.png` + cortical). **Result: the form constants DO appear retinotopically** — stripes → concentric ring/vortex foci + rosette (tunnel/funnel + lattice), labyrinth → swirl/tunnel + spokes, blob → dense churn — exactly as the settled scope predicted (they're the labyrinth's vocabulary, not addressable presets). AWAITING Matt's tier-3 look at the stills (the checkpoint item). **NEW FINDING that refines the `texture` dial (FR-010): the working band is a (σ_I, Ne) CORNER, not a 1-D dial** — fine σ (1.2–1.5) sustains pattern at Ne≈0.8, coarse σ needs Ne≈1.1; at fixed Psychedelic Ne=0.75 only σ_I≤1.5 stays alive, σ_I≥1.8 saturates. The texture and drive controls are coupled; the FR-010 dial range + default drive must be picked inside this corner (Phase 1 constant-setting task). Map constants (k_t seam, center detail) stay provisional until Matt's live look.

### Open Experiment 4 — drive coupling

- [x] T007 DONE 2026-10-23. Coupling shapes tested in the mirror (structured scene: gaussian-blurred noise, 0..1). Findings and the G3 recommendation:
  - **Additive coupling on E only vs on both: IDENTICAL** (the E and I sigmoid inputs are driven by the same convolved fields; adding to I changes nothing measurable). Ship **E-only** (simpler, cheaper).
  - **Luminance-gated drive KILLS the pattern** (corr 0.63 but std collapses to ~0.03 at low drive): masking the drive to bright regions starves the noise-sustained mechanism. Ship **raw additive drive**.
  - **`hallucinate` semantics fixed after three rejected variants.** Scaling all couplings (G) is backwards: it locks the scene's imprint harder as G rises (the sharpened nonlinearity tracks the drive, corr rises 0.5→0.74 for dg=0.75, and the amplitude collapses to zero outside a narrow window). Scaling the noise only (G3 candidate 2) also just locks the scene (corr ~0.7, no transition). **The clean crossover is `drive_gain` (scene strength) itself, at fixed Psychedelic couplings:** with σ_I=1.4, Ne=1.0, std stays high (~0.35) across the whole sweep while corr tracks drive_gain — dg=0.2 → corr 0.17 (HALLUCINATING, spontaneous), dg=0.5 → corr 0.56, dg≥1.0 → corr 0.77–0.84 (SCENE, normal vision). **Success Criterion 4 verified: high amplitude throughout, correlation low below threshold, high above; crossover near drive_gain ≈ 0.3–0.5.**
  - **Recommended G3:** drive inlet = raw additive on E only, term `drive_gain·(scene − 0.5)` added to the E sigmoid input; `hallucinate` and `drive_gain` are the SAME knob seen from the two ends (the module's gestural core is scene-strength, with weak drive = hallucinate, strong drive = see). Unconnected default: `drive_gain·(0.5 − 0.5) = 0` (a black/unconnected inlet is mid-0.5 → zero net drive → pure US-1 labyrinth). This makes the unconnected default free: **no special-casing, the constant 0.5 neutral point is the neutral.** Maps onto the gain/mix library convention (drive_gain is a `gain`-role dial).

### Open Experiment 6 — output encoding measurement

- [ ] T008 Measure the real dynamic range of the display quantity (E vs. E − I) across all T004 regions; compare hard clamp vs. soft compression vs. auto-range as numbers (fraction clipped, range per frame) plus image strips for Matt's tier-3 look (the f_ks T005 pattern). Offline; the choice itself is Phase 2 (gate G4).

### Decision gates (Matt)

- [x] G1 **Form navigation shape — DECIDED 2026-10-23 (Matt, option A).** The noise-driven region map found no separable four-form attractor regions (see T005 record): the pattern is a noise-driven labyrinth/stripe-glass transient. **Ship the labyrinth generator: no four-form selector.** FR-010/US-3/SC-2,3,8 revised in the spec (a `texture` dial = kernel width σ_I steers the grain; Phase-0 stripe/labyrinth landmarks as snaps). US-1/US-3/SC revised; parameter table `form`→`texture`. **Build-time (T025): the dial's route token is `grain`** — `texture` collides with jit.gl.pix's native @texture attribute in the param_connect binding.
- [x] G2 **Naming — DECIDED 2026-10-23 (Matt):** the module ships as **`f_wc` /
  "Wilson-Cowan"** — the working name is final (no `f_formconstants` rename).
- [x] G3 **Drive inlet semantics — DECIDED 2026-10-23 (Matt, per T007 recommendation).** Drive inlet = raw additive on E only: `drive_gain·(scene − 0.5)` into the E sigmoid input. Weak drive = hallucinate, strong drive = see (one knob, both ends). Unconnected inlet reads mid-0.5 → zero net drive for free (pure US-1 labyrinth, no special-casing). `drive_gain` is a `gain`-role dial in the library convention. **Build-time correction (T025):** an unconnected pix inlet reads BLACK (0,0,0,1), not 0.5 — the neutral is supplied by a vs_inState connection flag → `drv_conn`, and the nl codebox substitutes 0.5 (spec FR-006).
- [x] G4 **Output encoding — DECIDED 2026-10-23 (Matt, Phase 2).** Plain-E display
  with the `sharp` dial's S-curve blend, SHIPPED DEFAULT sharp = 0.5 (the Phase-2 soak
  showed the soft map drifts toward white over ~30 s; the half-crisp blend keeps the
  free labyrinth readable). T008's hard-clamp/soft-compress/auto-range comparison is
  overtaken: no special encoding ships.

**Checkpoint — PHASE 0 CLOSED 2026-10-23 (Matt approved G3, the last Phase-0 gate).** Mirror + tests green; region map recorded; G1 decided; T006 stills approved by Matt ("the stills are great"); T007 done and G3 approved per its recommendation. **Phase 1 (bpatcher build) may start.** T008 (encoding measurement → G4) slips to Phase 2; G2 (naming) is a Phase 3 blocker.

---

## Phase 1: Solver stages and bpatcher (after Phase 0 gates)

- [x] T020 **DONE 2026-10-23.** Factor the DFT chain — decision: **`src/f_vf_fluid/gen_dft.py` IS
  the shared generator**; f_wc got a third adapter `src/f_wc/gen_dft.py` in the
  exact shape of `src/f_ks/gen_dft.py`, importing the fluid template and
  asserting byte-identical code lines (only the header comment changes: module
  name, stage number, packing note). No third copy, no template move — the
  single template stays put and all three consumers cannot drift apart
  (FR-002). f_wc packing: `R,G = Re,Im of E-hat; B,A = Re,Im of I-hat` — the
  fluid two-complex-field packing, so ONE chain carries BOTH WC fields; no
  Hermitian split, no duplicated chain. Stage numbers: pass 0, fx 1, fy 2,
  spec 3, iy 4, ix 5, nl 6, enc 7. Four codeboxes generated.
- [x] T021 [P] **DONE 2026-10-23 (bench legs green on Max, 10/10 incl slow).** `src/f_wc/`
  `codebox_seed.gen` (Hoskins hash ×4 channels: R/G = seed-E/I reseed channels, B/A = the
  per-frame Box-Muller uniforms; `salt` increments EVERY DRAW — the load-bearing mechanism,
  not per-reset like f_ks), `codebox_pass.gen` (3-inlet hold/reseed, self-heal on BOTH-zero
  texels, G = A = 0 packing), `codebox_spec.gen` (ONE stage, two real gains; codebox Param
  named `sig_i` — `texture` collides with the GLSL builtin; the `grain` dial maps to it),
  `codebox_nl.gen` (4 inlets, Box-Muller * sqrt(dt) from in3.B/A into BOTH sigmoid inputs,
  E-only drive term, settled constants baked, NaN/Inf zap). Bench: `tests/modules/wc/bench_wc.py`
  GROUP regression ORDER 56 — seed statistics (independent R/G channels), 4-field DFT chain vs
  np.fft (1e-5 of peak), pass reseed/hold/self-heal exactness, spec gains vs mirror (1e-4),
  nl vs mirror (1.2e-7), containment. **Bench catch 1:** the bench wires at most 3 inputs per
  codebox job (`benchclient.run_pass` truncates `inputs[:3]`), so the nl drive test runs at the
  black-inlet operating point (drv = 0 with drv_conn = 1); the connected-scene case is covered
  by the module contract bench. Mirror grew `hash_noise_tex` / `seed_from_hash` /
  `nx_from_hash_tex` (exact float32 Hash port for the frame-exact chain test).
- [x] T022 [P] **DONE 2026-10-23 (bench leg green).** `codebox_enc.gen`: retinotopic resample
  (cortical u = ROWS / v = COLUMNS per `wc_retinotopy.py`), constants r0 = 0.5, k_ecc = 8,
  k_ang = 5, r_max = 4 baked (T033 decides exposure), periodic 4-tap in (cv, cu), display-E
  soft map + `sharp` crisp blend (default sharp = 0), `bypass_gate` → black A=1, non-finite →
  0, rectangular renders verified. **Bench catch 2:** the mirror's 4-tap sat half a texel off
  the codebox's texel-center convention (`fx = cv*N − 0.5`) — GPU-vs-mirror diffs to 3.2e-2;
  fixed in `wc_mirror.encode`, 256² now 5.2e-6 (sharp tolerance 1.5e-4 = the smoothstep
  midpoint slope 18.75 × the soft error).
- [x] T023 **DONE 2026-10-23.** Frame-exact chain: 30 host-sequenced GPU frames vs the mirror
  (same reseed via the real pass stage, same per-frame hash noise stream): max |GPU − mirror|
  = 4.1e-6 at frame 30 (flat over frames 1–30, NOT growing fast). @slow 100 frames: pixel diff
  5.8e-5, E contrast GPU 0.2258 vs mirror 0.2258, no saturation. The noise stream reproduction
  works — the hash port diffs stay inside the Box-Muller/transform rounding floor.
- [x] T024 **DONE 2026-10-23 (live bench measurement, `bench_wc.test_cost_per_stage`).** Stage
  costs at 256² solver + 1280x720 enc: seed 0.134, pass 0.138, fx 0.545, fy 0.133, spec 0.107,
  iy 0.263, ix 0.526, nl + enc UPPER-BOUND (not GPU-resolved) — total **2.45 ms/frame** against
  the 4 ms budget (f_ks's ~2.4 ms class, as the ONE-shared-chain architecture predicted).
  Decision: **256² solver** (the 128² fallback is unnecessary).


- [x] T025 **DONE 2026-10-23 (offline half + live contract bench, 2/2).** `definition.py` built
  (archetype source, luma out), drift 0, offline + live contracts green, `test_launch` /
  `test_generate_menu` green.
  Param set per the settled gates: `rate` (dt → nl; no ceiling), `grain` (σ_I → spec's `sig_i`,
  the FR-010 "texture dial" — RENAMED at build: the builder's `param_connect=<pix>::texture`
  binds to jit.gl.pix's NATIVE @texture attribute, which rejects the numeric value and snaps
  the control back to min; `texture` is not a valid control-name token on a pix-targeted
  param), `drive_gain` (→ nl; gain-role), `sharp` (→ enc), `reset`, bypass; internals
  `reseed`/`salt`/`drv_conn`/`bypass_gate`. Ne BAKED at 1.0 (no dial — not in the spec's
  param table; revisit at T030 if Matt wants the noise amount exposed). The drive inlet is
  the library's first TEXTURE inlet on a source archetype (`mod_inlets` `fanout` → nl in4 +
  vs_inState flag → `prepend param drv_conn` → nl; codebox substitutes neutral 0.5 when
  unconnected — unconnected reads BLACK, the FR-006/G3 correction). Salt increments EVERY
  DRAW from the [r draw] frame counter. Registered `NOT_IN_MENU` (menu entry is T042, Phase 3);
  README row at ⚠ + launcher regenerated (50 modules). Panel 210×110 provisional (T030/capture
  confirms).
  **Live contract bench:** param routing readbacks exact (dt / grain→sig_i / drive_gain /
  sharp), bypass → black A=1, 10 pix objects, no unexpected issues.

**Checkpoint (2026-10-23, all legs green):** the shipped patcher on the bench seeds on load, reseeds on reset, runs the exact settled chain frame-for-frame (30-frame diff 4.1e-6, 100-frame contrast matches the mirror), sweeps grain at spec'd cost (2.45 ms/frame at 256²), holds the drive neutral unconnected, bypasses to black A=1. Remaining Phase-1 gate: Matt's tier-2 bench sign-off on this run.

---

## Phase 2: Tuning (tier 3, Matt)

- [~] **Phase-2 measurement session DONE on the bench 2026-10-23** (instrument:
  `tests/modules/wc/bench_wc_look.py` + the `segments` timeline branch added to
  `tests/bench/bench_module.js`; job `tests/jobs/20261023_203051_0cb119`; contact
  sheets `tests/logs/wc_look/{soak,grain,drive}_20261023-203239.png`). Measured on the
  SHIPPED module at the bench's 512² render:
  - **Soak (rate 1, grain 1.4, drive off):** displayed contrast 0.059 → 0.091 → 0.122
    over 30 s; saturation 0.000 throughout (NF-003 holds live). BUT the E-mean drifts:
    4 s = dark field + bright knots, 12 s = cobweb mid-contrast, 30 s = BRIGHT field +
    dark knots. The plain display of E washes toward one extreme over time → **G4
    candidate to try live: mean/contrast normalization or a raised default `sharp`.**
  - **Grain sweep 1.1 / 1.4 / 1.9 / 2.6 / 3.5:** displayed contrast 0.120 / 0.081 /
    0.053 / 0.038 / 0.030 — fine grains read as fine central speckle (periphery
    sub-resolved under the provisional retinotopy), coarse grains wash out (no visible
    labyrinth at 2.6+). Whether that's physics or the display is a G4/T033 call; check
    the raw cortical E live.
  - **Drive imprint (scene fed from start, drive_gain 0 → 1.5 → 0):** corr of the
    display vs the scene warped through the retinotopic map: pre −0.00 (hallucinating),
    **+0.25 s 0.83**, +1 s 0.64, +4 s 0.71 (sustained), off +1 s 0.01 (released).
    Display std jumps to 0.37 while imprinted (a strong structural imprint in ~15
    frames). T032 mechanics proven; dial range/labels remain (range is 0–2 today).
- [x] T030 **DONE 2026-10-23 (Matt).** Ranges approved at the start of the Phase-2 session:
  `rate` 0–1 (default 1.0), `drive_gain` 0–2 (default 0). At the G4 call: output map = plain
  E + the `sharp` S-curve blend with DEFAULT 0.5 (codebox literal and definition dial updated;
  rebuild reproduces exactly, contracts green). Grain dial stays 1.0–4.0 (default 1.4).
- [x] T031 **DONE 2026-10-23 (Matt).** Landmark snaps at σ_I **1.1 / 1.4 / 1.9** (broken
  stripes / labyrinth default / coarse), documented in the `grain` dial hint and to be carried
  into T040's reference doc; the dial stays continuous (no quantization). No four-form
  selector ships; the glyph previews idea is dropped.
- [x] T032 **DONE 2026-10-23 (Matt).** Mechanics proven in the session (imprint corr 0.83 at
  +0.25 s at drive_gain 1.5, sustained 0.64/0.71, released to 0.01 at +1 s after off) and the
  "see" level ≈ 1.5 is documented in the drive hint; 0–2 range approved.
- [x] T033 **DONE 2026-10-23 (Matt).** Provisional retinotopy constants ACCEPTED as final
  (r0 = 0.5, k_ecc = 8, k_ang = 5, r_max = 4, baked in `codebox_enc.gen`); no foveal
  special-casing; no map parameter exposed to the user.

**Checkpoint**: Matt confirms the taxonomy reads (Success Criterion 3, 8).

---

## Phase 3: Docs and registration — DONE 2026-10-23 (gate G2: names stayed `f_wc` / "Wilson-Cowan")

- [x] T040 Reference doc `docs/f-reference/f_wc.md`.
- [x] T041 Helpfile `package/help/f_wc.maxhelp` (generator layout per the `f-helpfile` skill:
  4 externally-addressable dials + reset/bypass, drive-inlet bubble, references match the doc).
- [x] T042 `f_modules` menu placement: "Wilson-Cowan" in Patterns after Weave (`src/f_modules/menu.py`,
  removed from NOT_IN_MENU); `build/generate_menu.py` and `build/generate_launch.py` run,
  `test_generate_menu`/`test_launch` green.
- [x] T043 README row finalized (no ⚠: "Wilson-Cowan generator: noise-sustained living
  labyrinth; the drive inlet makes it see"), `ideas/INDEX.md` f_vf_wilson_cowan flipped to 🟢,
  `.specify/plan.md` item 8 marked BUILT and SHIPPED, naming (G2) applied.

---

## Dependencies & Execution Order

- T001 → T002 → T004 → T005 → {G1, G2, G3}; T003 closes after T004's regions; T006 needs T004's patterns; T007 needs T005's constants; T008 needs T004.
- Phase 1: T020 → T021/T022 [P] → T023 → T024 → T025.
- Phase 2 and 3 are sequential after Phase 1.
- Parallel opportunities within Phase 0: T001 and the T006 map-rendering scaffolding; T003's soak can run while T006/T007 are analyzed.

## Implementation Strategy

Phase 0 is the MVP gate: it produces no shippable module but resolves every open Clarification in the spec with measurements. Phase 1's bpatcher with US-1 (autonomous generator) + US-2 (drive inlet) + US-3 (navigation) is the first demo-able state; US-4 (rate/scale/reset) rides along in T025 since the controls are one definition block. Stop-and-validate points are the phase checkpoints above.

---

## Phase 4: Habituation spike and tier-1 hygiene (after Phase 3; G5 is Matt)

Promoted 2026-10-23 from `ideas/f_wc_from_webgpgpu.md` (Matt approved the discussion
proposal). Two hygiene items close open tier-1 cautions; the substantive item is the
habituation spike. Parked (not tasks): the Rule-page known-answer stats fixture (the
mirror already derives from the settled model that the page validated; a seed-averaged
stats test only earns its cost if the noise stage or nl is retouched later) and a
shared `f_rng` / retinotopy module (no second consumer; per-frame solver noise cannot
come from an upstream module — it must be fresh per 256² solver texel inside the loop).

- [x] T050 **DONE 2026-10-23.** Tier-1 hygiene: noise-stream tests in `test_wc.py`:
  histogram (4 channels, chi2 8-14 on 15 dof = textbook uniform on the real 256² grid),
  horizontal lag-1 corr ≤ 6.1e-3, frame-to-frame (salt 100 → 101) corr ≤ 2.7e-3 in all
  channels, Box-Muller at dt = 1 has mean 0 / std 1.00 / kurtosis 3.03. The salt-
  incremented Hoskins-style hash stream is clean; the T023-era caution is closed.
- [x] T051 **DONE 2026-10-23.** Tier-1 hygiene: retinotopy round trip in `test_wc.py`
  (`test_encode_round_trip_identity`): map → inverse identity on a smooth periodic
  cortical field holds at mean |err| 6.5e-3 / p95 2.0e-2 inside the eccentricity band
  r ∈ [0.6, 3.5] (100% of the sheet covered by at least one u-wrap copy; below 0.6 the
  render starves angularly — that is a map property, not an error source).
- [x] T052 **DONE 2026-10-23 (mirror sweep `tests/records/spike_wc_habituation.py`,
  CSV in `tests/logs/spike_wc_habituation_*.log`).** Mirror extended: `Params` gains
  `be/bi` depth (0 shipped) + `ae/ai` time constants (50/100, Rule Example 11); Ve/Vi
  ride state G/A ONLY when depth is nonzero (the shipped pass stage forces G,A → 0, so
  the zero-depth mirror stays bit-tied to the shipped GPU chain — chain-diff benches
  unaffected). Sweep: be = bi ∈ {0, 0.2, 0.5, 1.0} × Ne ∈ {0.6, 0.8, 1.0, 1.2}, 128²,
  1200 frames, one seed per cell (transient caveat: indicative, not definitive).
  **Findings for G5:**
  1. **The doom case did not show.** The shipped corner Ne = 1.0 stays inside the
     band at every depth tested (band shifts UP and narrows at the low end as depth
     grows: be 0 → band ≈ 0.6–1.2; be 0.5 → 0.8–1.2; be 1.0 → ≈1.0–1.2). Exposure as
     a dial with default 0 is safe for the shipped default.
  2. **Adaptation dampens the mean drift where drift exists** (Ne 1.2: drift +0.064
     plain → +0.001 at be 1.0) — exactly the anti-washout feedback the soak's
     E-mean drift called for — at the cost of killing the low-Ne cells (all adapted
     cells at Ne 0.6 are dead/faint by frame 1200; they sag below threshold without
     enough noise to re-light).
  3. **Moderate depth IMPROVES contrast at the shifted band** (best late std 0.304 at
     be 0.5 / Ne 0.8 vs 0.248 plain; be 1.0 / Ne 1.0: 0.293) — the fatigue-recovery
     cycle regenerates structure instead of letting it freeze.
- [x] **G5 DONE 2026-10-23 (Matt approved depth dial).** Shipped: `habituation` dial
  (0.0–1.0, default 0, between Drive and Sharp; token `habituation` with `pix_attr habit`,
  panel widened 210 → 247, menu/launcher regenerated → `"wc": [247, 110]`).
  `codebox_nl.gen` reads Ve/Vi from state G/A, relaxes toward the rates at ae = 50,
  ai = 100 (baked literals), subtracts `-habit*Ve/-habit*Vi` in the sigmoid inputs, and
  pins G/A to 0 when habit = 0 — the pre-G5 dynamics are bit-preserved. `codebox_pass.gen`
  carries G/A with the same NaN guard and restarts them at 0 on reseed/self-heal. Spec
  FR-003 + Parameters amended, `docs/f-reference/f_wc.md` updated (status, table, flow,
  algorithm), helpfile control list + bpatcher embed updated. Green: drift 16/16,
  module contracts 9/9 (route outlet fix — the raw `reset` wire moved 4 → 5 when the dial
  was inserted), launch 8/8, menu 17/17, test_wc 10/10. **Owed to Max:** one bench
  session leg — live `habit` sweep (expect: steadier mean, tighter contrast; band shifts
  up at the low end per T052) and a habit > 0 chain-vs-mirror run (`m_step` gains
  `be=bi=habit`; zero-depth legs untouched). The full offline suite has NOT been run
  since the rebuild — run `tests/bg.sh start offline` before the next unrelated edit.

---

## Record

- 2026-10-23 (night 10): **G5 approved (Matt) and shipped — `habituation` depth dial.**
  Ve/Vi ride state G/A: nl relaxes (50/100-frame constants, baked) and subtracts at
  depth `habit` (0 = bit-identical pre-G5 dynamics, G/A pinned 0); pass carries them
  with self-heal/reseed to 0. Panel 210 → 247; menu/launcher/helpfile/reference/spec
  updated. Offline suite green for the touched files. Owed to Max: habit sweep look +
  habit > 0 chain-vs-mirror bench leg.
- 2026-10-23 (later): **Phase 4 T050–T052 executed; only gate G5 remains.** T050/T051
  tier-1 hygiene landed in `test_wc.py` (10/10): the shipped hash stream is textbook
  uniform (chi2 8–14 on 15 dof, ≤ 6e-3 lag-1 spatial corr, ≤ 2.7e-3 frame-to-frame
  corr, Box-Muller kurtosis 3.03); the retinotopy round trip is identity at mean
  6.5e-3 / p95 2.0e-2 in the supported eccentricity band. T052: `wc_mirror` carries
  Ve/Vi in state G/A when depth ≠ 0 (zero depth = bit-tied to the shipped chain);
  the (be/bi × Ne) sweep found adaptation SURVIVABLE at the shipped corner (Ne 1.0
  inside the band at all depths 0–1.0), drift-damping at high Ne, contrast-boosting
  at moderate depth, band-shift-up at the low end. Decision staged for Matt as G5:
  depth dial 0–1 default 0, or drop. Detail in the T052 record.
- 2026-10-23: **Phase 4 written** (T050–T052 + gate G5) from `ideas/f_wc_from_webgpgpu.md`
  after the discussion with Matt: habituation (Ve/Vi) is the only promoted candidate —
  structural fit verified against the shipped codeboxes (state G/A free; pass forces them
  0 and needs a carry-through; nl.in2 taps raw state). T050/T051 are offline tier-1
  hygiene. The Rule-page stats fixture and a shared `f_rng`/retinotopy module were
  parked with reasons in the Phase 4 section.
- 2026-10-22: spec written (one pass, no prior spike); tasks created from its Open Experiments and phasing. All Phase 0 tasks are offline NumPy except T006's look judgment (Matt, stills).
- 2026-10-22: **T001–T003 done** (`tests/records/spike_wc_solver.py`, 5 tests green). Findings that change the spec:
  1. **Solver is kernel-coupled, not naive diffusion.** The spec's "diffuse each field, then couple the diffused fields" (FR-002/FR-003) produces long-wavelength mush, not rolls/hexagons. The working form is Ermentrout-Cowan: each coupling term `w * (K ⊗ field)` with `K` a Gaussian (spectrally `exp(-sigma^2 k^2/2)`), inhibition kernels wider than excitation. The linear step reduces to per-field decay `exp(-dt/tau)` (k-independent); ALL spatial structure comes from the coupling kernels. Spec FR-002/FR-003 must be rewritten to this form. This does NOT change the stage architecture (still: exact linear step + explicit nonlinear coupling, both spectral/real-space split) — only what the linear stage and the `nl` stage each compute.
  2. **No NaN ceiling exists** (exact decay + bounded sigmoid). The `rate` dial's ceiling is pattern-preservation, region-dependent → T004. NF-003's "no NaN after 10,000 frames" is trivially satisfied; the real constraint is aesthetic.
  3. **Thresholds + seed amplitude are load-bearing** (see T003 note).
  4. **Morphology at the default constants is not yet the target taxonomy** — the accessible strong regimes give sparse dots / dense blobs, not clean rolls/hexagons. T004's region sweep must find the rolls/hexagon/traveling-wave regions (and map kernel-scale vs. drive), or re-scope the aesthetic target. This is the open risk Phase 0 exists to close.

  Remaining Phase 0: T004 (region map — the load-bearing one), T005 (parameter sets from it), T006 (retinotopic render + look), T007 (drive coupling), T008 (encoding measurement), then gates G1–G3.

- 2026-10-22: **T004 done (fanned out, 4 parallel slices), T006 scaffolding done.** The load-bearing result is a **negative finding that redirects the work**: the default strong-coupling constants never produce clean rolls/hexagons — the field saturates into isolated spots or disordered blobs. The weakly-nonlinear Turing regime (weak couplings, mid-slope rest point) is where the coherent extended structure lives, and a probe there shows the right kind of labyrinthine/wavy pattern. The retinotopic map is validated on synthetic patterns (rolls→spiral, hexagons→lattice). **The path forward (T005) is a second region sweep in the weak-coupling regime, plus a contrast-aware classifier** (the current one mislabels low-contrast coherent patterns as uniform). Gates G1 (form selector) and the T005 parameter table stay open pending that sweep.
