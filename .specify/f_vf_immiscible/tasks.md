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
- [ ] T004 [P] Stability sweep and constants: the stabiliser `a` (plan: about 1–2), the largest per-frame `Mdt` that keeps the energy non-increasing, the smallest usable `iface` on 256², the `coarsen` dial law constants, the φ clamp bound, the reset noise amplitude. Record the numbers and fix them as module-level names in the mirror. *Offline.*
- [ ] T005 Pre-register the experiment-1 thresholds before running it (spec SC6): peak interface gradient ratio, droplet count by connected components, mean-φ drift under advection, and the stirring recipe (which `fluid_mirror` force pattern, viscosity, 600 frames, seed). Writing them first prevents a post-hoc pass. *Offline; doc in Record.*
- [ ] T006 Experiment 1 `tests/records/spike_immiscible_stirring.py` (decides G7): advect a Cahn–Hilliard φ with the `fluid_mirror` velocity for a blob and for 1-, 3- and 8-cell filaments; compare against plain advected φ with no sharpening and with a simple pointwise sharpening (swept strength). Record the numbers against T005's thresholds, plus stills; from the same runs record the coarsening time (experiment 3: frames to double the region scale at default `coarsen`, and whether more than one phase step per frame is needed). *Offline.*
- [ ] T007 [P] Experiment 2 `tests/records/spike_immiscible_blend.py` (decides G2): two mirror Fluids with different `viscosity` and `project`, the same force, blended by a fixed half-and-half φ and by T006's advected φ; record the divergence of the plain blend relative to |u|, the distribution of the normal jump, and how much the interface-aware rule lowers the peak. *Offline.*
- [x] T008 (2026-10-27, see Record) [P] Experiment 5, the builder check: read `build/spec.md` and `build_patcher.py`, and dry-build a skeleton definition (no Max) with three input inlets, `vs_inState` gating on two of them, `r draw` chain heads and ids derived from the control count. Record what the builder can and cannot express; log any gap in `ideas/build_patcher_schema_gaps.md`. *Offline.*

### Decision gates (Matt)

- [ ] G1 Name: `f_vf_immiscible` chosen 2026-10-27; confirm at T033.
- [ ] G2 Blend rule: plain, interface-aware, or viscosity-weighted. After T007.
- [ ] G3 Initial state: `fill` default (proposal 0) and the reset noise. Judged live at T024.
- [ ] G4 φ outlet encoding: `w = (φ + 1)/2` grey, neutral mid grey (proposal). Confirm at T023.
- [ ] G5 Bypass: neutral outlets (the plan) or a passthrough of input A at the cost of a fourth pix input on `enc`. **Matt's call, wanted before T020.**
- [ ] G6 Solver size: 256² or 128². After T017.
- [ ] G7 Phase model: Cahn–Hilliard or the fallback. After T006. If the fallback wins, revise the plan (ADR-2) and T010–T017 before continuing.
- [ ] G8 Stage 2 delivery: existing force inlet plus `f_vf_mix`, or a native inlet on `f_vf_fluid`. Phase 4.

**Checkpoint**: tier-1 tests green and mutation-checked; G7 and G2 decided on numbers and stills; coarsening time recorded; builder check recorded.

---

## Phase 1: Codeboxes on the bench (after G7)

- [ ] T010 `src/f_vf_immiscible/gen_dft.py` adapter and the four generated `codebox_dft_*.gen` (code lines asserted identical to `f_vf_fluid`'s, as `f_ks`'s adapter does; only the packing comment changes). *Offline generation.*
- [ ] T011 [P] `src/f_vf_immiscible/codebox_inab.gen`: decode `(p − 0.5)·2`, content gate (`|B − 0.5| < 0.25`) and the `src_a` / `src_b` flags, `taps × taps` hardware tap grid per solver texel, pack uA and uB; invalid input gives zero. Three inputs (bang, A, B). *Written against the mirror.*
- [ ] T012 [P] `src/f_vf_immiscible/codebox_pass.gen`: hold, or reseed `fill + amp·(2h − 1)` with an arithmetic hash of texel and `salt` (no `sin()`); reseed only on `reseed` or non-finite, never on an exact uniform ±1 (FR-010). Two inputs.
- [ ] T013 `src/f_vf_immiscible/gen_blend.py`, `codebox_adv.gen` and `codebox_enc.gen`: one blend block (plain, plus the interface-aware rule if G2 keeps it) written into both; `adv` also advects φ (periodic four-tap `nearest()`), injects, clamps, packs φ and φ³, honours `freeze`; `enc` upsamples φ and both velocities, encodes out0 and out1, applies `bypass_gate` per G5. Three inputs each.
- [ ] T014 [P] `tests/modules/immiscible/test_immiscible_static.py`: every stage at most three inputs; no forbidden Param names (FR-012: `texture`, `t`, `depth`, `mix`, `bypass`, `dim`); the two blend copies identical; `N = 256` literal in the right places; no `sin(`, no `noise()`; the non-finite guard form. *Offline.*
- [ ] T015 `src/f_vf_immiscible/codebox_spec.gen`: the Cahn–Hilliard step with the T004 constants in one place, mirrored in `immiscible_mirror.py` (they change together); `freeze` gives factor 1.
- [ ] T016 `tests/modules/immiscible/bench_immiscible.py`: each real codebox on the GPU against the mirror (`inab` including the gates, `pass` reseed, hold and self-heal with a uniform ±1 left alone, `adv` including the periodic seam, injection and freeze, the four DFTs, `spec`, `enc` including the bypass gate), then a host-sequenced 100-frame run and the NaN guard. Give the first input the render size (HANDOFF 2026-10-26). Set tolerances from the first measured run, record them, then tighten. *Max bench; ask Matt to run it.*
- [ ] T017 Cost (experiment 4): per stage and total at 256², and input minification at `taps` 1, 2 and 8; record the module-alone number (NF-001) as a bound where under the bench floor. Decide G6. *Max bench.*

**Checkpoint**: spec success criteria 1–5 pass on the GPU path; cost recorded.

---

## Phase 2: Build the module and judge it live (stage 1)

- [ ] T020 [US6] `src/f_vf_immiscible/definition.py` and `package/patchers/f_vf_immiscible.maxpat`: three inlets, ten stages per plan ADR-1, params per spec, raw wiring for `r draw` and `vs_inState`, ids derived from the control count (the `f_wc` lesson). Drift 0 (`build/py.sh build/drift.py -v f_vf_immiscible`), offline contracts (register undriven bench-only Params as known). To keep `test_launch` and `test_generate_menu` green while unfinished: README Patches row marked ⚠ (110 characters, then `build/py.sh build/generate_launch.py`) and `NOT_IN_MENU` with the reason "menu entry is T032". Register `bench_immiscible*.py` in `tests/lib/benchdeps.py` with a unique ORDER.
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
  - G5 still open; recommendation is neutral outlets.
