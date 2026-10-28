# Tasks: f_vf_immiscible

**Spec**: `.specify/f_vf_immiscible/spec.md`
**Plan**: `.specify/f_vf_immiscible/plan.md`
**Build order**: Sequential. Phase 0 is the gate: its two experiments decide G7 (does Cahn–Hilliard hold the interface) and G2 (the blend rule). If G7 says it does not, stop and re-plan around the fallback before any codebox is written.
**Commits**: After each phase checkpoint. Session rules in `CLAUDE.md` apply: one phase or coherent group per turn, no test or bench runs without asking, always `-q`.

Created 2026-10-27 from the spec's Open Experiments and the plan's blocks. Each task says whether it is offline NumPy (no Max), the Max bench, or a human look (tier 3, Matt). Python with NumPy: `uv run --no-project --with numpy python3`; offline tests `tests/run.sh -q <file>`; bench `tests/bench.sh -q <file>`. After the mirror (T002) exists, T005–T007 suit an omp fan-out if wanted; they need no GPU.

---

## Expected Source Layout

```
src/f_vf_immiscible/
├── definition.py                 # params, three inlets, raw wiring (as f_ks / f_wc)
├── gen_dft.py                    # adapter over src/f_vf_fluid/gen_dft.py; packing R,G = φ̂, B,A = (φ³)^
├── gen_blend.py                  # writes ONE blend block into codebox_adv.gen and codebox_enc.gen
├── codebox_inab.gen              # decode, gate, minify A and B, pack (256²)
├── codebox_pass.gen              # hold or reseed (hash inline); non-finite self-heal
├── codebox_adv.gen               # blend, advect φ, inject, clamp, pack φ and φ³ (256²)
├── codebox_dft_{fx,fy,iy,ix}.gen # generated
├── codebox_spec.gen              # per-bin Cahn–Hilliard step
├── codebox_enc.gen               # render size: out0 φ, out1 blended velocity, bypass gate
tests/modules/immiscible/
├── immiscible_mirror.py          # tier-1 mirror (float32, stage-decomposed)
├── test_immiscible.py            # tier-1 tests
├── test_immiscible_static.py     # static codebox checks (no Max)
├── bench_immiscible.py           # tier-2 stage / host-sequenced bench
├── bench_immiscible_module.py    # tier-2 built-patcher bench
tests/records/
├── spike_immiscible_stirring.py  # experiment 1 (stills to tests/logs/immiscible/, gitignored)
├── spike_immiscible_blend.py     # experiment 2
```

---

## Phase 0: NumPy mirror, experiments and decision gates (BLOCKING)

- [x] T001 (2026-10-27, see Record) Record the verification-tier decision in this file's Record (constitution, Verification Tiers). Proposed: tier 1 applies (closed forms exist: mean conservation, spinodal rate, `tanh` profile, free energy, blend identities); tier 2 applies (frame-exact host-sequenced run against the mirror, plus cost); tier 3 for the look and the cost in a real patch. No tier skipped. *Doc only.*
- [x] T002 (2026-10-27, see Record) Float32 stage-decomposed mirror `tests/modules/immiscible/immiscible_mirror.py` of one frame: `inab` (decode, content gate, `taps` minify, pack), `pass`, `adv` (plain blend, periodic backward advect, inject, clamp, pack φ and φ³), `spec` (the stabilised Cahn–Hilliard step, plan ADR-2), `ix` cleanup, `enc`; a `Params` dataclass and a `step()`. Imports `grid`, `interp`, `tap_weights`, `force_taps` from `tests/modules/fluid/fluid_mirror.py` and the FFT mirrors from `dft_mirror`. *Offline.*
- [x] T003 (2026-10-27, 14/14, see Record) [P] Tier-1 tests `tests/modules/immiscible/test_immiscible.py`, each against independent truth: mean of φ conserved exactly with no flow and no injection (SC1); single small-amplitude mode growth or decay rate against the analytic linear rate within 2% (SC3); a flat 1-D interface relaxes to the `tanh` profile the width predicts within 10% (SC4); free energy non-increasing with no flow (SC2); blend identities: φ = ∓1 gives A or B exactly, convex combination, swap symmetry (FR-004); the plain blend's divergence equals `∇w · d` to 1e-5; the divergence integrated across a straight interface equals the normal jump for every rule (SC5); freeze round-trip drift measured; determinism (FR-014); no NaN over 10⁴ frames at parameter extremes (NF-003). Mutation-checked, as the fluid and quasi mirrors are. *Offline.*
- [x] T004 (2026-10-27, see Record) [P] Stability sweep and constants: the stabiliser `a` (plan: about 1–2), the largest per-frame `Mdt` that keeps the energy non-increasing, the smallest usable `iface` on 256², the `coarsen` dial law constants, the φ clamp bound, the reset noise amplitude. Record the numbers and fix them as module-level names in the mirror. *Offline.*
- [x] T005 (2026-10-27, see Record; written BEFORE T006 was run) Pre-register the experiment-1 thresholds before running it (spec SC6): peak interface gradient ratio, droplet count by connected components, mean-φ drift under advection, and the stirring recipe (which `fluid_mirror` force pattern, viscosity, 600 frames, seed). Writing them first prevents a post-hoc pass. *Offline; doc in Record.*
- [x] T006 (2026-10-27, see Record; pre-registered result: Cahn–Hilliard FAILS 2 of 3 gating cases, diagnosed, G7 is Matt's call) Experiment 1 `tests/records/spike_immiscible_stirring.py` (decides G7): advect a Cahn–Hilliard φ with the `fluid_mirror` velocity for a blob and for 1-, 3- and 8-cell filaments; compare against plain advected φ with no sharpening and with a simple pointwise sharpening (swept strength). Record the numbers against T005's thresholds, plus stills; from the same runs record the coarsening time (experiment 3: frames to double the region scale at default `coarsen`, and whether more than one phase step per frame is needed). *Offline.*
- [x] T007 (2026-10-27, see Record) [P] Experiment 2 `tests/records/spike_immiscible_blend.py` (decides G2): two mirror Fluids with different `viscosity` and `project`, the same force, blended by a fixed half-and-half φ and by T006's advected φ; record the divergence of the plain blend relative to |u|, the distribution of the normal jump, and how much the interface-aware rule lowers the peak. *Offline.*
- [x] T008 (2026-10-27, see Record) [P] Experiment 5, the builder check: read `build/spec.md` and `build_patcher.py`, and dry-build a skeleton definition (no Max) with three input inlets, `vs_inState` gating on two of them, `r draw` chain heads and ids derived from the control count. Record what the builder can and cannot express; log any gap in `ideas/build_patcher_schema_gaps.md`. *Offline.*

### Decision gates (Matt)

- [ ] G1 Name: `f_vf_immiscible` chosen 2026-10-27; confirm at T033.
- [x] G2 Blend rule: plain. Decided by Matt 2026-10-27 on T007's numbers (interface-aware raised the peak divergence in every band tried; viscosity-weighted untested). T013 carries the plain blend only; `blend` dial and the interface-aware branch are dropped from the module.
- [ ] G3 Initial state: `fill` default (proposal 0) and the reset noise. Judged live at T024.
- [ ] G4 φ outlet encoding: `w = (φ + 1)/2` grey, neutral mid grey (proposal). Confirm at T023.
- [x] G5 Bypass: neutral outlets (the plan). Decided by Matt 2026-10-27 (took the recommendation); no fourth pix input on `enc`.
- [ ] G6 Solver size: 256² or 128². Numbers in the T017 Record. Matt 2026-10-27: keep 256² for now, decide after the live look (T023).
- [x] G7 Phase model: Cahn–Hilliard. Decided by Matt 2026-10-27 on T006/T006b (option 1: close now, accept the 0.0264 stripes drift against the 0.02 pre-registered limit, check long-run drift in T017's offline run). The fallback is dead (T006). If the fallback wins, revise the plan (ADR-2) and T010–T017 before continuing.
- [ ] G8 Stage 2 delivery: existing force inlet plus `f_vf_mix`, or a native inlet on `f_vf_fluid`. Phase 4.

**Checkpoint**: tier-1 tests green and mutation-checked; G7 and G2 decided on numbers and stills; coarsening time recorded; builder check recorded.

---

## Phase 1: Codeboxes on the bench (after G7)

- [x] T010 (2026-10-27, offline; see Record) `src/f_vf_immiscible/gen_dft.py` adapter and the four generated `codebox_dft_*.gen` (code lines asserted identical to `f_vf_fluid`'s, as `f_ks`'s adapter does; only the packing comment changes). *Offline generation.*
- [x] T011 (2026-10-27, offline; see Record) [P] `src/f_vf_immiscible/codebox_inab.gen`: decode `(p − 0.5)·2`, content gate (`|B − 0.5| < 0.25`) and the `src_a` / `src_b` flags, `taps × taps` hardware tap grid per solver texel, pack uA and uB; invalid input gives zero. Three inputs (bang, A, B). *Written against the mirror.*
- [x] T012 (2026-10-27, offline; see Record) [P] `src/f_vf_immiscible/codebox_pass.gen`: hold, or reseed `fill + amp·(2h − 1)` with an arithmetic hash of texel and `salt` (no `sin()`); reseed only on `reseed` or non-finite, never on an exact uniform ±1 (FR-010). Two inputs.
- [x] T013 (2026-10-27, offline; see Record) `src/f_vf_immiscible/gen_blend.py`, `codebox_adv.gen` and `codebox_enc.gen`: one blend block (plain, plus the interface-aware rule if G2 keeps it) written into both; `adv` also advects φ (periodic four-tap `nearest()`), injects, clamps, packs φ and φ³, honours `freeze`; `enc` upsamples φ and both velocities, encodes out0 and out1, applies `bypass_gate` per G5. Three inputs each.
- [x] T014 (2026-10-27, offline; see Record) [P] `tests/modules/immiscible/test_immiscible_static.py`: every stage at most three inputs; no forbidden Param names (FR-012: `texture`, `t`, `depth`, `mix`, `bypass`, `dim`); the two blend copies identical; `N = 256` literal in the right places; no `sin(`, no `noise()`; the non-finite guard form. *Offline.*
- [x] T015 (2026-10-27, offline; see Record) `src/f_vf_immiscible/codebox_spec.gen`: the Cahn–Hilliard step with the T004 constants in one place, mirrored in `immiscible_mirror.py` (they change together); `freeze` gives factor 1.
- [x] T016 (2026-10-27, 13/13 on the second run, see Record) `tests/modules/immiscible/bench_immiscible.py`: each real codebox on the GPU against the mirror (`inab` including the gates, `pass` reseed, hold and self-heal with a uniform ±1 left alone, `adv` including the periodic seam, injection and freeze, the four DFTs, `spec`, `enc` including the bypass gate), then a host-sequenced 100-frame run and the NaN guard. Give the first input the render size (HANDOFF 2026-10-26). Set tolerances from the first measured run, record them, then tighten. *Max bench; ask Matt to run it.*
- [x] T017 (2026-10-27, see Record; G6 is Matt's call on these numbers) Cost (experiment 4) AND long-run mean drift (G7 condition, 2026-10-27): offline mirror run of 3000+ frames under the T005 stirring recipe, mean phi against frame count for stripes, drops and noise; if it keeps climbing, add the k = 0 pull toward `fill` in `spec` and re-test. per stage and total at 256², and input minification at `taps` 1, 2 and 8; record the module-alone number (NF-001) as a bound where under the bench floor. Decide G6. *Max bench.*

**Checkpoint**: spec success criteria 1–5 pass on the GPU path; cost recorded.

---

## Phase 2: Build the module and judge it live (stage 1)

- [x] T020 [US6] `src/f_vf_immiscible/definition.py` and `package/patchers/f_vf_immiscible.maxpat`: three inlets, ten stages per plan ADR-1, params per spec, raw wiring for `r draw` and `vs_inState`, ids derived from the control count (the `f_wc` lesson). Drift 0 (`build/py.sh build/drift.py -v f_vf_immiscible`), offline contracts (register undriven bench-only Params as known). To keep `test_launch` and `test_generate_menu` green while unfinished: README Patches row marked ⚠ (110 characters, then `build/py.sh build/generate_launch.py`) and `NOT_IN_MENU` with the reason "menu entry is T032". Register `bench_immiscible*.py` in `tests/lib/benchdeps.py` with a unique ORDER.
- [ ] T021 [US3] Reset and load behaviour in the patcher: `reset` once on load after 200 ms, `reseed` held three draw bangs, `salt` counter per reset, `freeze`.
- [ ] T022 [US6] `tests/modules/immiscible/bench_immiscible_module.py` and the live module contract bench (`tests/contracts/bench_modules.py`): params arrive, every outlet renders, bypass outlets neutral per G5, "advances exactly once per frame", two instances independent (FR-013). *Max bench; ask Matt.*
- [ ] T023 [US1] First live look (tier 3, Matt): two real `f_vf_fluid` modules at clearly different `viscosity` (for example 0.05 and 0.6), the same stirring force into both, blended out1 into `f_vf_advect`. Record what is seen against SC8; confirm G4. A recipe for the patch goes in the Record.
- [ ] T024 [US2] Interface look: `iface` and `coarsen` ranges and defaults, whether droplets bead and coalesce, `fill` default (G3), how fast it resolves.
- [ ] T025 [US3] Injection look: `inject` range with a bright disc and with `f_grain` upstream; `f_splat` if it exists by then.
- [ ] T026 [US4] Blend rule look: A/B the rules left by G2 on the live pair.
- [ ] T027 Write every tuning change back into the codebox files and `definition.py` and re-run tiers 1–2 (constitution). Decide `taps` default.

**Checkpoint**: spec success criteria 7–9 judged; stage 1 closed.

---

## Phase 3: Docs and registration

- [ ] T030 `docs/f-reference/f_vf_immiscible.md`: as-built reference (settled model, gates and their outcomes, the divergence finding, the one-frame latency, the 256² detail limit).
- [ ] T031 `package/help/f_vf_immiscible.maxhelp`: written in a Claude session from the `build/generate_helpfiles.py` prompt, never by an API call from a script; must show the two-Fluid setup.
- [ ] T032 Menu entry in `src/f_modules/menu.py` (∇ marked; Processors, near `f_vf_fluid`), then `build/py.sh build/generate_menu.py`; remove `NOT_IN_MENU`; README row finalised (⚠ off if live-checked) and `generate_launch.py`; `docs/f-reference/module-inventory.md` row.
- [ ] T033 Confirm the name (G1); update `ideas/f_vf_immiscible.md`, `ideas/INDEX.md` (🟢) and `.specify/plan.md` item 14.
- [ ] T034 `module-preflight` checklist; when it passes, Matt moves `.specify/f_vf_immiscible` to `.specify/stable/`.

---

## Phase 4: Stage 2, momentum across the interface (gated, not scheduled)

Only after Phase 2 is judged worth extending.

- [ ] T040 Experiment 6: a scratch Max test (the constitution's tier-3 exception: investigating something that is not a module yet): two trivial modules feeding each other through a one-frame `hold` delay (`f_vf_lbm`'s idiom). Does a cross-module cycle behave?
- [ ] T041 Decide G8 from T040: existing force inlet plus `f_vf_mix` additive, or a native "pull toward this field" inlet on `f_vf_fluid`.
- [ ] T042 If the force inlet: spec and build `f_vf_mix` (`ideas/f_vf_mix.md`, additive first).
- [ ] T043 Amend the spec for FR-016: nudge and force outlets for each Fluid, band weighting, strength dials; tier-1 test that the nudge removes the normal jump (the measure Phase 0 left).
- [ ] T044 Buoyancy (`∝ φ · g`) and surface tension (`∝ −φ ∇μ`) with a clamp and conservative defaults (plan risks: explicit capillary force stability).

---

## Dependencies & Execution Order

- **Phase 0 blocks everything.** T002 first; T003, T004, T008 are parallel once T002 exists (T008 needs nothing and can start now). T005 before T006. T006 and T007 are parallel. G7 and G2 close Phase 0.
- **Phase 1** needs G7. T010 first; T011, T012, T014 parallel; T013 needs G2 (which rules it carries); T015 needs T004; T016 needs T011–T015; T017 after T016.
- **Phase 2** needs Phase 1 and T008. T020 needs G5. T021, T022 follow T020; T023–T026 are Matt's live looks and need T022; T027 closes.
- **Phase 3** needs Phase 2. **Phase 4** is independent and gated.

## Implementation Strategy

- **MVP first:** Phase 0 only. It costs no Max time and decides whether the idea stands (G7) and whether the blend needs more than the plain rule (G2). Stop and review with Matt at its checkpoint.
- **Then** Phase 1 and the stage-1 module with the plain blend, judged live (T023). Everything after that depends on whether that look is worth about 8 ms.
- **Parallel:** T006 and T007 can run as an omp fan-out once T002 exists; T008 can start immediately.

## Notes

- [P] = different files, no dependencies. [US#] = maps the task to a spec story; Phase 0 and Phase 1 tasks serve all stories.
- Mark a task done with the date and a pointer to its record, as `f_wave_field/tasks.md` does.
- Anything derived from the Cahn–Hilliard scheme is unverified until T003–T006 (spec and plan mark these [inference]).

---

## Record

- 2026-10-27: spec, plan and tasks created. Direction (separate module, two required upstream velocity vecfields, name `f_vf_immiscible`) settled with Matt the same day. While writing the spec the earlier claim that a normal/tangential split removes the blend's divergence was found wrong (the divergence integral across the interface equals the normal jump for any output-side rule); the idea file was corrected and G2 and T007 are framed to measure how large the jump is in practice. G5 (bypass) is open and wanted before T020. Nothing has been run.

- 2026-10-27 (T001): verification tiers: tier 1 applies (closed forms: mean conservation, linear mode rate, `tanh` profile, free energy, blend identities); tier 2 applies (frame-exact host-sequenced run against the mirror, plus cost); tier 3 for the look and the cost in a real patch. No tier skipped.
- 2026-10-27 (T002, T003): `tests/modules/immiscible/immiscible_mirror.py` and `test_immiscible.py` written, 14/14 passing. Mutation checks all caught: cubic term dropped, κ sign flipped, k=0 factor scaled, blend weight inverted, weight squared, periodic wrap off. Fixed in one test: plain-blend divergence check fell to float32 noise at high k (1.24e-5 vs 1e-5), so the spectral derivative is low-passed at mode 8 (fields are band-limited to mode 3); tolerance kept at 1e-5. Constants in the mirror are PROVISIONAL until T004: A_STAB=1.5, MDT_MAX=2e-4, MDT_EXP=3, PHI_CLAMP=2.0, RESEED_AMP=0.05, S_LO=0.05, S_HI=0.35. Early G2 datum (not a result): for uniform opposing flows the interface-aware rule gave peak |div| 12.87 vs 8.89 for plain. T007 must measure this properly.
- 2026-10-27 (T008): the builder expresses the whole skeleton (scratch dry build, 62 boxes / 66 lines, gitignored in `scratch/imm_dry/`): three outer inlets (control + φ source texture; A; B) with A and B gated by `vs_inState` via `state_nodes`/`state_param`; `fanout` to chosen stage inlets; ten-stage chain (inab, hold, pass, adv, fx, fy, spec, iy, ix, enc) with 3-input stages; both outer outlets from `enc`; `bypass_mode:"param"`. Gap: freeze across two stages needs a menu with a list `pix_target` (`header_toggle` is single-target only), not a gap in the schema, a different widget.
  - HAZARD found, proposed amendment (needs Matt's OK, touches plan ADR-1, T011, T013): `adv` input order. If `adv` in0 is the packed velocity (cold, from `inab`) and in1 the state (hot, from `pass`), a draw that reaches `inab` before `pass` makes even and odd frames evolve interleaved. Proposed: adv in0 = `pass` state (hot), in1 = packed u (cold), in2 = φ source texture (inlet fanout to adv inlet 2). The mirror's `adv(state, uab, src, p)` already takes them in this order.
  - 2026-10-27 decisions (Matt): `adv` input-order amendment approved (applied to plan ADR-1 diagram; T011/T013 must follow it, adv in0 = pass state, in1 = packed u, in2 = φ source). G5 closed: neutral outlets.

- 2026-10-27 (T004): `tests/records/spike_immiscible_constants.py` (offline, 256², spectral stage only, no flow; table in `tests/logs/immiscible_constants*.txt`, gitignored). Constants now fixed in the mirror; 14/14 still green.
  - Stabiliser: a = 0.5 diverges (energy rises, NaN/1e25) at mdt >= 1.3e-2; a = 1.0, 1.5, 2.0 never raised the energy (worst rise 0, 150 frames, iface 2/4/8, mdt 2.7e-3 .. 51, plus a noise-0.9 start). Overshoot past ±1: a=1.0 up to 1.096, a=1.5 up to 1.028, a=2.0 up to 1.022. **A_STAB = 1.5.** No upper bound on mdt was found for a >= 1.
  - Mobility: the provisional MDT_MAX = 2e-4 was about 500x too slow (separation 2200 frames at the top of the dial). The stabiliser saturates the domain-scale rate, so more mdt stops helping beyond about 1e-2, but the early growth stays proportional. **MDT_MAX = 0.1, MDT_EXP = 3.** Default coarsen 0.3 (mdt 2.7e-3): std > 0.5 in 22 frames, std > 0.9 at 270, coarsened by 300 frames later. coarsen 1.0: std > 0.9 at 60 frames, coarsened within ~500. coarsen 0.1: std > 0.9 at 3650 frames, creeping (about a minute of motion).
  - Coarsening is box-limited: domain size (1/mean|∇φ|) goes 0.12 -> 0.20 (stripes) or 0.25, then stops. "Frames to double" is not measurable on 256² at iface 4; only c = 0.3 reached 2x (360 frames, final 0.25). Experiment 3's measure should be "frames to reach 1.5x" or be taken under stirring (T006). The structure-factor first moment was tried first and is dominated by the interface tail.
  - Interface: stripe relaxed to steady state against tanh(x/(√2 iface)): max error 1.5e-3 at iface 1, below 5e-5 for 1.5–4, 0.002 at 8 where φ peaks at 0.986 (interfaces closer than the tails). **IFACE_MIN = 1.5** on the spectral side. Whether bilinear advection holds an interface this thin is T006's question, not answered here.
  - Clamp: **PHI_CLAMP = 1.25** (observed max 1.03 at a = 1.5; the clamp is a safety net, bilinear advection and the bounded inject cannot overshoot).
  - Reset noise: onset (std > 0.5) 29/27/22/19/16 frames for amp 0.005/0.01/0.05/0.1/0.3 at fill 0; fill 0.3 about 10 frames later. Not critical. **RESEED_AMP = 0.05.** Side effect: the hash noise has a mean bias, so the field starts about 1.2e-4 below `fill` at amp 0.05 (mean is then conserved exactly). Harmless; T012 should not try to cancel it.
- 2026-10-27 (T005): experiment-1 pre-registration, fixed BEFORE `spike_immiscible_stirring.py` exists or runs.
  - Velocity: one stirred `fluid_mirror` Fluid, N = 256, seed 1, `Params(viscosity=0.3, project=1.0)` otherwise defaults, forced by a drifting cell pattern, f = 0.6·(sin(2π(2y) + 0.03t), sin(2π(3x) − 0.02t)) encoded as an f_vecfield (B = 0.5, A = 1), 200 warm-up frames before φ starts, 600 frames after. The same velocity is fed to A and B, so the blend is neutral and only advection plus the phase step is tested. Before running, check rms |u| (decoded) lies in 0.2–1.0; if not, rescale the force amplitude and record the change here BEFORE looking at any φ number.
  - φ arms (all advect with the same u, dt = 0.01, inject 0): (1) Cahn–Hilliard (iface 4, coarsen 0.3, default constants); (2) plain advection only; (3) plain advection plus pointwise sharpening φ += s·φ(1−φ²) with s swept over {0.001, 0.003, 0.01, 0.03} per frame.
  - Starts (φ = ±1 with the tanh profile of iface 4): a blob of radius 0.12 at the centre; filaments (straight strips) 1, 3 and 8 texels wide; a pair of blobs of radius 0.08 whose centres are 0.2 apart (coalescence case).
  - Measures every 25 frames: **G** = p99 of |∇φ| (central differences, per texel) divided by its frame-0 value; droplet count = 4-connected components of φ > 0, periodic, area >= 16 texels; mean φ drift = |mean(t) − mean(0)|; max |φ|; finite or not.
  - **Pass for Cahn–Hilliard (needed for G7):** on the blob and the 8-texel filament: min over frames 300–600 of G >= 0.5 (the spec's proposal); mean φ drift <= 0.02 at frame 600; always finite; max |φ| <= 1.25 at every measured frame. On the 8-texel filament and the blob the component count at 600 is <= 4 (no shattering). Coalescence case: component count at 600 <= count at 0 (the pair merges or at least does not fragment).
  - Reported but not gating: 1- and 3-texel filaments (thinner than or near the interface width, so dissolving is correct behaviour); all numbers for arms 2 and 3 side by side, with stills of frames 0, 150, 300, 600.
  - **G7 rule:** Cahn–Hilliard wins if it passes and its G at frames 300–600 beats the plain arm's. The fallback wins only if CH fails and some sharpening strength passes the same G, drift, finite and component tests. If both fail, the idea does not hold under stirring: stop and tell Matt.

- 2026-10-27 (T006, experiment 1): `tests/records/spike_immiscible_stirring.py run` (165 s; log `tests/logs/immiscible_stirring.txt`, stills `tests/logs/immiscible/stirring_{blob,fil8,pair,fil3}.png`, rows ch / plain / sh0.001 / .003 / .01 / .03, columns frames 0 150 300 600; all gitignored). Velocity check first, as pre-registered: force amp 0.6 gave rms|u| 0.307 (0.79 texels per frame), inside 0.2–1.0, no rescale.
  - **Pre-registered result: Cahn–Hilliard PASSES the blob and FAILS the 8-texel filament and the coalescence pair.**
    - blob: min G[300–600] 0.789 (>= 0.5), mean drift 0.0008, 1 component, max |phi| 1.0045: PASS. Plain advection 0.262 (fail, drift 0.003); every sharpening strength fails and collapses the blob (components 1->0, drift up to 0.093: the pointwise term is not conservative).
    - fil8: CH G = 0 from frame 50 (component 1->0); pair: CH G falls to 0 at frame ~300 (2->0). Plain keeps a smeared remnant (G 0.21 / 0.27) so it "survives" without a defined interface.
    - 1- and 3-texel filaments (info only): CH dissolves them within 50 frames, plain smears to G ~0.12–0.13.
    - drift <= 0.002 for CH in every case; max |phi| 1.0045 blob, 0.93–0.97 elsewhere; always finite.
  - **Diagnosis (checked with NO flow, 1200 frames, spectral stage alone):** fil8 dissolves to uniform -0.928 within 50 frames; the pair merges into one droplet and then dissolves by frame 1200; the blob survives. So the two failures are not caused by stirring: with iface 4 and the phase-B area at only 3.1% (fil8), 4.0% (pair), the feature is below the size Cahn–Hilliard can hold (Gibbs–Thomson: a small droplet in a nearly pure background has a higher internal chemical potential and dissolves; a stripe 8 wide is thinner than twice the interface thickness). The blob (4.6%, radius 31) is just supercritical. The pre-registered geometry is therefore not a fair test of the solver under stirring; it measures the critical size. I have NOT changed the thresholds or re-scored.
  - Rule from T005, applied literally: CH fails, no sharpening strength passes, so "stop and tell Matt". Proposed follow-up (needs Matt's OK, to be pre-registered before running): T006b with supercritical starts at mean phi near 0 (a half-filled stripe pair, several droplets of radius >= 0.1 at 25–30% area, and the noise start) so the question becomes whether stirring tears the interface, and with the interface sharpness (G against the flat-interface value) measured on the noise start.
  - Experiment 3 (coarsening under stirring, noise start, L = 1/mean|grad phi|): coarsen 0.3: L 23 -> 33 over 600 frames; coarsen 1.0: 30 -> 37; max |phi| 1.014 / 1.007, no sign that more than one phase step per frame is needed at these settings. Interface sharpness on these runs was not measured (T006b).
- 2026-10-27 (T007, experiment 2): `tests/records/spike_immiscible_blend.py` (logs `tests/logs/immiscible_blend*.txt`). Two Fluids, same force; phi advected by the plain blend and evolved by the CH step from noise (coarsen 1.0), samples at frames 400–500; also a fixed half-and-half phi. Divergence is central differences, normalised by the sources' own rms |grad u| (g).
  - Contrast A visc 0.0 | B visc 0.7: B almost stalls (rms|u| 0.07 vs 0.82), project 0.3 changes nothing measurable. Contrast A 0.0 | B 0.3 (B moves: 0.26) is the more representative:
    - plain blend: rms(div)/g 1.12 (stirred phi) / 0.55 (half-and-half); p99 4.9 / 2.7; max 10.0 / 4.2.
    - interface-aware, S 0.05–0.35: 1.43 / 0.68, p99 7.0 / 3.7, max 14.7 / 6.4. Band 0.02–0.15: 1.61 / 0.73, p99 8.1 / 3.9, max 18.5 / 7.9. Band 0.10–0.60: 1.26 / 0.62, p99 5.8 / 3.2, max 12.6 / 5.5.
    - The 0.7 contrast gives the same ordering (plain max 13.5 vs aware 16.7–24.4).
  - Normal jump |(uB − uA)·n| at interface texels over rms|u|: median ~1.0, p90 2.9–3.1, p99 4.1–4.6 (stirred); the interface covers 16–23% of the area.
  - **Reading for G2:** the interface-aware rule does NOT lower the peak divergence; it raises it in every band tried (wider bands are less bad but still above plain), as the early datum suggested. The plain blend's divergence is large in absolute terms (its rms exceeds the sources' own velocity-gradient scale), so a downstream consumer sees real compression at the interface, and stage 2 (nudging the Fluids) is what could address it. Recommendation: **plain blend** for G2 (simplest shader, lowest divergence). Not tested: the viscosity-weighted option. Matt's gate.

- 2026-10-27 (T006b pre-registration, Matt approved the follow-up and accepted G2 = plain). Written BEFORE `spike_immiscible_stirring_b.py` exists or runs. Same velocity recipe as T005 (force amp 0.6, viscosity 0.3, 200 warm-up, 600 frames, A = B = u), iface 4, coarsen 0.3 unless stated. Arms: ch and plain (the sharpening arms already failed in T006 and are dropped).
  - Starts: **stripes** (phase B for |x − 128| < 64, mean 0, two straight interfaces); **drops** (four droplets of radius 0.14 at (64,64), (192,64), (64,192), (192,192), phase-B area about 25%, mean about −0.5); **noise** (fill 0, amp 0.05, CH only, coarsen 0.3 and 1.0).
  - Measures every 25 frames: G = p99 |grad phi| / its frame-0 value (stripes, drops); S = p99 |grad phi| / 0.1768 (the flat-interface slope 1/(√2·iface) per texel) for the noise start; component count (drops, area >= 16 texels); mean drift; max |phi|; finite.
  - **Pass for Cahn–Hilliard (closes G7 as Cahn–Hilliard):** stripes and drops: min G over frames 300–600 >= 0.5; mean drift <= 0.02; always finite; max |phi| <= 1.25; drops: component count at 600 between 1 and 6; CH's min G over 300–600 beats plain's on both starts. Noise: S >= 0.5 at every measured frame from 300 to 600, for both coarsen values; max |phi| <= 1.25; finite.
  - If any of these fails: do not rescue by changing thresholds; report to Matt. No fallback is viable (sharpening failed in T006).

- 2026-10-27 (T006b result): `tests/records/spike_immiscible_stirring_b.py` (about 55 s; logs `tests/logs/immiscible_stirring_b*.txt`, stills `tests/logs/immiscible/stirring_b_{stripes,drops,noise}.png`, gitignored). **Pre-registered verdict: FAIL, on exactly one criterion.**
  - Passing: stripes CH min G[300–600] 0.994 (plain 0.961); drops CH 0.984 (plain 0.527; plain loses all four droplets, components 4->0, CH keeps them, 4->6 after small satellites); noise start sharpness S = p99|grad phi|/0.1768 stays 0.98–1.00 from frame 50 to 600 at coarsen 0.3 and 1.0 (min over 300–600: 0.982 both); max |phi| 1.024 / 1.034 / 1.014 / 1.007; always finite.
  - **Failing: stripes mean drift at frame 600 = 0.0264 against the 0.02 limit** (drops 0.0179, noise 0.0218 at coarsen 0.3 and 0.0078 at 1.0; plain advection drifts more: stripes 0.0387, monotonic). The threshold was NOT changed and the run was not re-scored.
  - Drift diagnosis (mean phi every 100 frames, stripes CH): +0.013, +0.018, +0.026, +0.023, +0.018, +0.026: fluctuating, not clearly monotonic over 600 frames; noise@0.3: -0.0005 ... +0.0218, still creeping at the end. Cause: the semi-Lagrangian advection of phi is not conservative (the CH step conserves the mean exactly, so all the drift enters in `adv`); the plain arm shows the same effect twice as large. A 0.03 shift in the mean changes the phase-B area by about 1.5%, but over minutes it could accumulate and one phase would eat the other.
  - Candidate mitigation if it matters (not built): pull the k = 0 bin in `spec` toward `fill` at a slow rate (a "mean restore" dial or fixed constant); costs nothing in the chain. Alternative: accept as a known property. A long-run check (3000+ frames, drift against frame count) belongs in the T017 offline run either way.
  - **G7 is Matt's call:** Cahn–Hilliard holds the interface under stirring far better than any alternative tried (the fallback is dead), but its pre-registered mean-drift criterion failed by 0.006.

- 2026-10-27: Phase 0 closed. Gates decided: G2 plain blend, G5 neutral outlets, G7 Cahn–Hilliard (with the drift check moved to T017). Still open: G1 (T033), G3 (T024), G4 (T023), G6 (after T017), G8 (Phase 4). `blend` dial and the interface-aware branch are out of the module; the mirror keeps them for the record. Next: Phase 1, T010 first.

- 2026-10-27 (T010–T015, codeboxes written offline, NOT yet run on the GPU): `src/f_vf_immiscible/` now holds `gen_dft.py` + four generated `codebox_dft_*.gen` (code lines asserted identical to f_vf_fluid's), `codebox_inab.gen`, `codebox_pass.gen`, `codebox_spec.gen` (T004 constants literal: a 1.5 and a+1 = 2.5, mdt = 0.1·coarsen³), and `gen_blend.py` generating `codebox_adv.gen` and `codebox_enc.gen` from ONE plain-blend block (G2). `tests/modules/immiscible/test_immiscible_static.py` 9/9, mutation-checked (a constant changed in spec, a forbidden Param `mix` added, the blend swapped in one copy, a zero-heal added to pass, a 4th input, a flipped DFT sign, unary minus before a parenthesis: all caught).
  - Params per stage: inab taps src_a src_b; pass reseed salt fill; adv dt inject taps freeze src_phi; spec iface coarsen freeze; enc bypass_gate. Stage inputs: inab (bang, A, B); pass (bang, hold); adv (state HOT, packed u, source); spec/DFT in1; enc (bang, packed u, phi). adv and enc are GENERATED: edit gen_blend.py, never the .gen. enc writes out1 (phi grey) and out2 (blended velocity), so the primary pix needs two outlets.
  - Open for T016 to confirm on the GPU: `max()`/`clamp()`/`switch()` behaviour in the pass selection (`use` is a 0/1 float via max), `wrap()` on float indices in adv, out2 on the primary pix at render size, and the hash bit-match to the mirror (pass reseed).

- 2026-10-27 (T016): `tests/modules/immiscible/bench_immiscible.py` (ORDER 65, registered in `tests/lib/benchdeps.py`; Max 9.2.0). First run 11/13, second run **13/13** after two honest corrections to MY tests, no codebox changed. Every stage matches the mirror on the first measurement, errors in the 1e-7..1e-6 range: inab 1.3e-6 (1:1 taps 8), 2.4e-7 (magnified, minified); adv 1.1e-6 blend+advect, 8.6e-7 inject at 256, 8.3e-7 at 128, clamp/freeze/seam exact; spec 1.8e-7..1.7e-7 relative at iface 1.5–8, coarsen 0–2, k = 0 bin exact, B/A zero; DFT 3.6e-7 relative, round trip 2.8e-6, guard exact; enc both outlets 7.7e-7 / 4.8e-7, bypass exactly neutral on both, f_vecfield contract exact. All tolerances above stay at the provisional bench_fluid values; the measured numbers are 100–1000x inside them, so they can be tightened to about 10x the measurement (inab/adv/enc 1e-5, spec 1e-6) in a later pass.
  - Correction 1, the reseed hash: the first run failed my "bit-match the mirror" check (7.5% of texels off by > 1e-4). Probe (`scratch/imm_hash_probe.py`, gitignored): the GPU output is deterministic, uniform (mean +/-0.002, std 0.5765–0.5787 vs 0.5774), salts decorrelate (98% of texels differ between salt 3 and 7), median error vs the mirror 4e-9, p99 2.9e-4, and a full 2·amp = 0.1 wrap-flip on 0.02–0.05% of texels. Cause: `fract((hx + hy)·hz)` is taken at magnitude about 2e3 where float32 resolves about 2e-4, so bit-matching is not attainable. The test now checks determinism, uniformity, decorrelation, wrap-flip fraction <= 2e-3 and p99 <= 5e-4; the mirror's comment no longer promises a bit match.
  - Correction 2, the 100-frame chain: pointwise GPU vs mirror drift is 3.8e-5 (frame 20), 1.5e-4 (40), 3.8e-4 (60), 7.8e-4 (80), 1.3e-3 (100): float32 rounding carried through the nonlinear dynamics, smooth, with stage errors at 1e-6. Tolerance now 3e-3 with the mechanism in the comment, and a new invariant check, the free energy at frame 100: GPU 0.05557 vs mirror 0.05557, relative 5.6e-6.
  - Spec success criteria on the GPU path: SC1 mean drift 8.8e-7 over 60 frames (tol 1e-5); SC2 free energy never rose; SC3 growth rate 0.29814 vs analytic 0.29815 (7.5e-6 relative); SC4 stripe vs tanh 1.4e-6 max error. 30 frames with injection: 1.9e-5, mean agrees to 6e-8. NaN/Inf texels in the state: reseeded by pass, 10 frames stay finite.
  - Not covered here, by design (module level, T022): the hot/cold ordering of `inab` and `pass` at `adv`, the second outlet wiring, vs_inState behaviour at connect/disconnect. Bench time: the 100-frame chain took 71 s (600 jobs, bench overhead; this is not a cost figure, T017 measures cost).

- 2026-10-27 (T017, cost, NF-001): `test_T017_cost_per_stage_and_total` in `bench_immiscible.py` (@slow; `IMM_ONLY=test_T017_cost_per_stage_and_total tests/bench.sh --slow tests/modules/immiscible/bench_immiscible.py` runs just it; 94 s; Max 9.2.0, the M3 Max; M1 not measured). ms per pass, every job pins its Params; "UB" = bench-floor upper bound (not resolved):
  - 256² solver: fx 0.526, fy 0.519, iy 0.506, ix 0.507 (GPU bound, **2.06 ms for the four-stage DFT chain, 56% of the total**); spec 0.407 UB; adv 0.29–0.42 UB without a source, 0.275 / 0.319 / 0.368 with a 1080p source at taps 1 / 2 / 8.
  - inab with two 1080p inputs: 0.336 UB (taps 1), 0.253 UB (taps 2), **0.851 resolved (taps 8)**, so taps 8 is about 3x taps 1–2; 4K x2 at taps 2: 0.329 UB.
  - enc at render size: 0.675 UB at 1080p; **2.755 UB at 4K**.
  - **Total this module alone at taps 2: 3.71 ms/frame at 1920x1080** (first run 3.64), **5.93 ms at 3840x2160**, dominated at 4K by enc. Seven of the eleven 1080p rows are floor upper bounds, so the real total is somewhat lower. Against the rough NF-001 budget "about 3 ms for this module", 1080p is over by about 0.7 ms (upper bound). The two-Fluid chain total (about 8 ms rough) was not measured here.
  - Where the time is: the DFT chain (O(N) taps per texel, so about N³ for the chain). Not measured, estimated: 128² would cut it roughly 8x (about 0.26 ms), giving a 1080p total near 2 ms, at the price of the look at half the solver resolution. That is G6.
- 2026-10-27 (T017, drift condition for G7): `tests/records/spike_immiscible_drift.py`, mirror, T006b recipe, 3600 frames (about 9 min; log `tests/logs/immiscible_drift.txt`). mean(phi) − mean(0) every 300 frames, CH arm:
  - stripes: +0.026, +0.026, +0.017, +0.014, +0.017, +0.023, +0.028, +0.032, +0.034, +0.035, +0.035, +0.035: wanders and levels at +0.035.
  - drops: −0.003 ... −0.060 (frame 1500) ... −0.077 (2700), −0.081, −0.081, −0.081: monotonic for about 2400 frames, **flat from about 3000**, final −0.081 (the phase-B area falls from 24.7% to 20.6%, a 16% relative loss of droplet phase; plain advection only −0.019).
  - noise coarsen 0.3: +0.015 ... bounded, wandering within +0.010 to +0.022; coarsen 1.0: −0.0077 and constant from frame 600. All finite.
  - **Verdict against Matt's condition ("if it keeps climbing, add the k = 0 pull"): it does NOT keep climbing, every arm levels off within the run, so no mean-restore term was added.** Caveat for the live look (T023): the droplet case loses about a sixth of its droplet phase over a minute of stirring. The pull is a small change in the spec stage (k = 0 factor toward `fill`), available if that reads badly.
- 2026-10-27 (T020): `src/f_vf_immiscible/definition.py` and `package/patchers/f_vf_immiscible.maxpat` built, drift 0. Ten stages per amended ADR-1 (pass->adv in0 hot, inab->adv in1 cold, phi source fanout->adv in2, inab->enc in1, ix->enc in2 and ->hold); mod inlets A/B gated by vs_inState (src_a, src_b -> inab); `r draw` -> inab, pass, enc. Dials: dt 0-0.05 (0.01), iface 1.5-12 (4), coarsen 0-1 (0.3), inject 0-1 (0.2), fill -0.6..0.6 (0), freeze menu (adv+spec), hidden taps int 1-16 (2; inab+adv). No `blend` menu (G2 plain). Ranges are provisional until the live looks (T024). Reset logic (raw boxes, as f_ks, salt -> pass, ids from the control count) is in the definition already, so T021 reduces to checking it live. README row marked unfinished (110-char limit), `NOT_IN_MENU` reason added, `generate_launch` run; test_launch and test_generate_menu pass. Not yet checked: that the chain loads in Max, and the draw order (T022).
