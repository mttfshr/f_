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

- [ ] T004 Sweep the curated coupling aggregates (spec, Parameters) over the Butler/Ermentrout-Cowan lineage ranges; classify each asymptotic cortical pattern by structure-factor analysis (rolls vs. hexagons; wavelength; traveling vs. standing). Record region extents, warm-up times, and seed-dependence (mode-selection variance over ≥5 seeds per region). Offline; `tests/records/spike_wc_regions.py`. **This task's output decides gate G1.**
- [ ] T005 From T004's map: pick the four category parameter sets (the `form` selector candidates), the `hallucinate` aggregate's threshold-crossing path, and the fixed internal constants (couplings, taus, refractory strengths, D_E). Recorded as a table in this file. Offline.

### Open Experiment 3 — retinotopic render

- [ ] T006 Apply the inverse log-polar map to T004's rolls/hexagons; verify funnel/spiral/lattice/cobweb emerge; render stills for Matt's look. Fix the map constants (eccentricity range, scale, foveal radius handling) and the polar-origin offset convention. Offline NumPy render; the look judgment is Matt's (tier 3, static images, no Max). `tests/records/spike_wc_map.py`.

### Open Experiment 4 — drive coupling

- [ ] T007 In the mirror, test drive coupling shapes (additive on E only vs. on both; luminance-gated vs. raw); verify Success Criterion 4 (output/input correlation high below threshold, low above) and pick the coupling equation + unconnected default. Offline.

### Open Experiment 6 — output encoding measurement

- [ ] T008 Measure the real dynamic range of the display quantity (E vs. E − I) across all T004 regions; compare hard clamp vs. soft compression vs. auto-range as numbers (fraction clipped, range per frame) plus image strips for Matt's tier-3 look (the f_ks T005 pattern). Offline; the choice itself is Phase 2 (gate G4).

### Decision gates (Matt)

- [ ] G1 **Form navigation shape** (spec, Clarifications): from T004's region widths — discrete 4-position selector with glyph previews (clean regions) or continuous knobs with landmark snaps (fuzzy continuum). The spec's FR-010 branches on this.
- [ ] G2 **Naming**: `f_wc` is a placeholder (spec header). Alternatives on record: `f_formconstants`. Decide before Phase 3's menu and README entries.
- [ ] G3 **Drive inlet semantics**: T007's coupling-shape recommendation; confirm or pick another.
- [ ] G4 **Output encoding**: T008's comparison; decide in Phase 2 with live context (same as f_ks T012).

**Checkpoint**: mirror + tests green; region map recorded; T006 stills seen by Matt; G1–G3 decided. Only then does Phase 1 start.

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
