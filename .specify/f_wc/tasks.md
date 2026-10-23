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
├── gen_dft.py               # reuses f_ks's DFT template (factor to a shared
│                            #   location at build time — third use, per FR-002)
├── codebox_seed.gen         # hash noise seeding (E and I)
├── codebox_pass.gen         # feedback hold / reseed
├── codebox_dft_{fx,fy,iy,ix}.gen   # generated, shared with f_ks
├── codebox_spec.gen         # per-bin linear step: exp((-1 - D k^2) dt / tau)
│                            #   (two instances: E chain, I chain)
├── codebox_nl.gen           # sigmoid coupling + refractory + drive (both fields)
├── codebox_enc.gen          # retinotopic (log-polar → Cartesian) resample,
│                            #   output map, bypass_gate
tests/records/
├── spike_wc_solver.py       # Phase 0 mirror + stability (Open Experiment 1)
├── spike_wc_regions.py      # Phase 0 parameter region map (Open Experiment 2)
├── spike_wc_map.py          # Phase 0 retinotopic render (Open Experiment 3)
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

- [ ] T007 In the mirror, test drive coupling shapes (additive on E only vs. on both; luminance-gated vs. raw); verify Success Criterion 4 (output/input correlation high below threshold, low above) and pick the coupling equation + unconnected default. Offline.

### Open Experiment 6 — output encoding measurement

- [ ] T008 Measure the real dynamic range of the display quantity (E vs. E − I) across all T004 regions; compare hard clamp vs. soft compression vs. auto-range as numbers (fraction clipped, range per frame) plus image strips for Matt's tier-3 look (the f_ks T005 pattern). Offline; the choice itself is Phase 2 (gate G4).

### Decision gates (Matt)

- [x] G1 **Form navigation shape — DECIDED 2026-10-23 (Matt, option A).** The noise-driven region map found no separable four-form attractor regions (see T005 record): the pattern is a noise-driven labyrinth/stripe-glass transient. **Ship the labyrinth generator: no four-form selector.** FR-010/US-3/SC-2,3,8 revised in the spec (a `texture` dial = kernel width σ_I steers the grain; Phase-0 stripe/labyrinth landmarks as snaps). US-1/US-3/SC revised; parameter table `form`→`texture`.
- [ ] G2 **Naming**: `f_wc` is a placeholder (spec header). Alternatives on record: `f_formconstants`. Decide before Phase 3's menu and README entries.
- [ ] G3 **Drive inlet semantics**: T007's coupling-shape recommendation; confirm or pick another.
- [ ] G4 **Output encoding**: T008's comparison; decide in Phase 2 with live context (same as f_ks T012).

**Checkpoint**: mirror + tests green; region map recorded; G1 decided (2026-10-23). Remaining before Phase 1: T006 stills seen by Matt (retinotopic render of real labyrinth, for the tier-3 look — the map mechanism is already validated), T007 (drive coupling shape → G3), T008 (encoding measurement → G4, Phase 2). G2 (naming) is a Phase 3 blocker, not a Phase 1 blocker.

---

## Phase 1: Solver stages and bpatcher (after Phase 0 gates)

- [ ] T020 Factor the DFT chain: `src/f_ks/gen_dft.py` is already a two-use template; a third use (f_wc) triggers the shared-location decision (FR-002). Either a shared generator both modules import, or a second copy with the same code-line assertion. Record the choice here.
- [ ] T021 [P] Codeboxes for the E/I solver stages in `src/f_wc/` (seed, pass, spec ×2 instances, nl with NaN/Inf zap per the f_ks containment precedent), verified on the bench against the mirror stage by stage. Max bench; codeboxes written by hand against T001's stages.
- [ ] T022 [P] `codebox_enc.gen`: the retinotopic resample (T006's constants and foveal handling), output map (placeholder until G4), `bypass_gate` → black alpha 1 (f_ks precedent), `@adapt 0` render-size sampling. Max bench.
- [ ] T023 Frame-exact multi-frame feedback run of the full GPU chain against the mirror (`run_temporal`, the f_ks T007 pattern: short-horizon pixel comparison, then statistical comparison — WC traveling-wave regions are chaotic-adjacent, so set horizons from the mirror's divergence rate). Max bench.
- [ ] T024 GPU cost check in a real Vsynth context: the two-field chain (~2× f_ks's 2.39 ms/frame) plus the render-res enc resample; decide 256² vs. 128² (spec NF-001, Clarifications). Max bench.
- [ ] T025 `definition.py` (archetype source; params per the spec's table, with `form` per G1), `package/patchers/f_wc.maxpat` built; drift 0; offline contracts green; live module contract bench green (bypass expectation: black A=1).

**Checkpoint**: the shipped patcher on the bench seeds on load, forms patterns in each G1-selected region, responds to the drive inlet per G3, and holds NF-003 over the bench's long soak.

---

## Phase 2: Tuning (tier 3, Matt)

- [ ] T030 Output mapping choice (G4) and `rate`/`scale` ranges and defaults, judged live.
- [ ] T031 Form navigation feel: the G1 selector (or landmark snaps) — do the four categories land reliably from a cold state and reorganize cleanly on a switch (spec US-3). If the selector ships: the glyph previews (WFG-style visual aid, from T006's stills).
- [ ] T032 Drive-transition feel: `hallucinate` + `drive_gain` over real input — is the below/above-threshold transition one legible gesture (spec US-2).
- [ ] T033 Retinotopic look: map constants, foveal region handling, whether any map parameter becomes user-facing (spec Clarifications).

**Checkpoint**: Matt confirms the taxonomy reads (Success Criterion 3, 8).

---

## Phase 3: Docs and registration

- [ ] T040 Reference doc `docs/f-reference/f_wc.md`.
- [ ] T041 Helpfile (the `f-helpfile` skill).
- [ ] T042 `f_modules` menu placement (`src/f_modules/menu.py` + `build/generate_menu.py`; category: Patterns, alongside f_ks) and launcher regeneration if the Patches table changes.
- [ ] T043 README row, ideas INDEX flip to 🟢, `.specify/plan.md` item 8 resolved, final naming (G2) applied everywhere.

---

## Dependencies & Execution Order

- T001 → T002 → T004 → T005 → {G1, G2, G3}; T003 closes after T004's regions; T006 needs T004's patterns; T007 needs T005's constants; T008 needs T004.
- Phase 1: T020 → T021/T022 [P] → T023 → T024 → T025.
- Phase 2 and 3 are sequential after Phase 1.
- Parallel opportunities within Phase 0: T001 and the T006 map-rendering scaffolding; T003's soak can run while T006/T007 are analyzed.

## Implementation Strategy

Phase 0 is the MVP gate: it produces no shippable module but resolves every open Clarification in the spec with measurements. Phase 1's bpatcher with US-1 (autonomous generator) + US-2 (drive inlet) + US-3 (navigation) is the first demo-able state; US-4 (rate/scale/reset) rides along in T025 since the controls are one definition block. Stop-and-validate points are the phase checkpoints above.

---

## Record

- 2026-10-22: spec written (one pass, no prior spike); tasks created from its Open Experiments and phasing. All Phase 0 tasks are offline NumPy except T006's look judgment (Matt, stills).
- 2026-10-22: **T001–T003 done** (`tests/records/spike_wc_solver.py`, 5 tests green). Findings that change the spec:
  1. **Solver is kernel-coupled, not naive diffusion.** The spec's "diffuse each field, then couple the diffused fields" (FR-002/FR-003) produces long-wavelength mush, not rolls/hexagons. The working form is Ermentrout-Cowan: each coupling term `w * (K ⊗ field)` with `K` a Gaussian (spectrally `exp(-sigma^2 k^2/2)`), inhibition kernels wider than excitation. The linear step reduces to per-field decay `exp(-dt/tau)` (k-independent); ALL spatial structure comes from the coupling kernels. Spec FR-002/FR-003 must be rewritten to this form. This does NOT change the stage architecture (still: exact linear step + explicit nonlinear coupling, both spectral/real-space split) — only what the linear stage and the `nl` stage each compute.
  2. **No NaN ceiling exists** (exact decay + bounded sigmoid). The `rate` dial's ceiling is pattern-preservation, region-dependent → T004. NF-003's "no NaN after 10,000 frames" is trivially satisfied; the real constraint is aesthetic.
  3. **Thresholds + seed amplitude are load-bearing** (see T003 note).
  4. **Morphology at the default constants is not yet the target taxonomy** — the accessible strong regimes give sparse dots / dense blobs, not clean rolls/hexagons. T004's region sweep must find the rolls/hexagon/traveling-wave regions (and map kernel-scale vs. drive), or re-scope the aesthetic target. This is the open risk Phase 0 exists to close.

  Remaining Phase 0: T004 (region map — the load-bearing one), T005 (parameter sets from it), T006 (retinotopic render + look), T007 (drive coupling), T008 (encoding measurement), then gates G1–G3.

- 2026-10-22: **T004 done (fanned out, 4 parallel slices), T006 scaffolding done.** The load-bearing result is a **negative finding that redirects the work**: the default strong-coupling constants never produce clean rolls/hexagons — the field saturates into isolated spots or disordered blobs. The weakly-nonlinear Turing regime (weak couplings, mid-slope rest point) is where the coherent extended structure lives, and a probe there shows the right kind of labyrinthine/wavy pattern. The retinotopic map is validated on synthetic patterns (rolls→spiral, hexagons→lattice). **The path forward (T005) is a second region sweep in the weak-coupling regime, plus a contrast-aware classifier** (the current one mislabels low-contrast coherent patterns as uniform). Gates G1 (form selector) and the T005 parameter table stay open pending that sweep.
